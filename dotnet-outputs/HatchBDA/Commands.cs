using System.Text.Json;
using Autodesk.AutoCAD.ApplicationServices.Core;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;
using HatchBDA.Helpers;
using HatchBDA.Models;

namespace HatchBDA;

// Migrated from HATCHB.LSP (Jimmy Bergmark / JTB World) — recreates a HATCH entity's
// boundary as ordinary drawing entities (line/arc/circle/ellipse/polyline).
//
// Design Automation only — no interactive prompts, no dialogs, ever. Hatch selection
// and the hl (copy-hatch-layer) behavior are both parameterized; see
// Models/HatchBoundaryInput.cs and the Design Automation Guardrail in SKILL.md.
//
// (defun errexit (s) ...) and (defun undox () ...) in the original exist purely to
// undo the drawing back to before the command ran and restore the UCS/*error* handler
// on failure — both built entirely out of (command ...) macro calls:
//   (defun undox () (command "._ucs" "_p") (command "._undo" "_E") (setvar "cmdecho" oldcmdecho) ...)
// TODO v2: (command "._ucs" "_p"/"_w") and (command "._UNDO" "_BE"/"_E") bookkeeping is a
// (command ...) macro sequence — out of scope for v1 (see SKILL.md Scope Boundaries).
// The Transaction.Abort()/tr.Commit() pattern below is the DA-appropriate equivalent:
// a failed command rolls back the whole transaction atomically, and DA has no UCS/undo
// stack or *error* handler to restore in the first place.
public class Commands
{
    // (defun c:hb () (hatchb nil)) — this line can be commented out if there is an
    // existing command called hb
    [CommandMethod("HB")]
    public void Hb() => RunHatchBoundary(copyHatchLayer: false);

    // (defun c:hbl () (hatchb T)) — this line can be commented out if there is an
    // existing command called hbl
    [CommandMethod("HBL")]
    public void Hbl() => RunHatchBoundary(copyHatchLayer: true);

    // (defun c:hatchb () (hatchb nil))
    [CommandMethod("HATCHB")]
    public void Hatchb() => RunHatchBoundary(copyHatchLayer: false);

    // Dev/test-only helper — NOT part of the migrated LISP. Creates a single 10x5
    // rectangular HATCH entity with no islands and no unsupported edges, so you have
    // something for HB/HBL/HATCHB (or a real DA WorkItem) to act on. Run via
    // accoreconsole, then QSAVE/SAVEAS the result as your seed .dwg — see
    // Tests/Integration/RunIntegrationTests.ps1 for the NETLOAD/script pattern this
    // borrows from.
    [CommandMethod("HBSEED")]
    public void HbSeed()
    {
        var db = HostApplicationServices.WorkingDatabase;
        using var tr = db.TransactionManager.StartTransaction();

        var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
        var modelSpace = (BlockTableRecord)tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite);

        var loopPoints = new Point2dCollection
        {
            new Point2d(0, 0),
            new Point2d(10, 0),
            new Point2d(10, 5),
            new Point2d(0, 5),
        };
        var bulges = new DoubleCollection { 0.0, 0.0, 0.0, 0.0 };

        var hatch = new Hatch();
        modelSpace.AppendEntity(hatch);
        tr.AddNewlyCreatedDBObject(hatch, true);
        hatch.SetDatabaseDefaults();
        hatch.SetHatchPattern(HatchPatternType.PreDefined, "ANSI31");
        hatch.AppendLoop(HatchLoopTypes.Default, loopPoints, bulges);
        hatch.EvaluateHatch(true);

        tr.Commit();
        Application.DocumentManager.MdiActiveDocument.Editor.WriteMessage(
            "\nHBSEED: created a 10x5 rectangular HATCH in model space.\n");
    }

    // (defun hatchb (hl / ...) ...) — the shared body all three commands above call.
    private void RunHatchBoundary(bool copyHatchLayer)
    {
        var db = HostApplicationServices.WorkingDatabase;

        string paramsPath = Path.Combine(Environment.CurrentDirectory, "params.json");
        var input = File.Exists(paramsPath)
            ? JsonSerializer.Deserialize<HatchBoundaryInput>(File.ReadAllText(paramsPath))
                ?? throw new InvalidOperationException($"Failed to parse {paramsPath}")
            : new HatchBoundaryInput(); // no params.json supplied — default to "process every hatch"

        using var tr = db.TransactionManager.StartTransaction();
        try
        {
            // (if (/= (setq ss2 (ssget '((0 . "HATCH")))) nil) ...) — replaced by a
            // parameterized selection (see HatchBoundaryHelper.ResolveHatchIds); never an
            // interactive ssget.
            var hatchIds = HatchBoundaryHelper.ResolveHatchIds(tr, db, input).ToList();

            int processed = 0;
            double area = 0.0;
            bool areaIsReliable = true; // (setq area 0) (setq bMoreLoops nil)

            foreach (var hatchId in hatchIds)
            {
                var hatch = (Hatch)tr.GetObject(hatchId, OpenMode.ForRead);

                // *ModelSpace*/*PaperSpace* + (if (= (strcase (cdr (assoc 410 ed1))) "MODEL") ...)
                // → the hatch's own OwnerId. Simpler and more correct than the original's
                // Model/Paper binary check: it places the recreated boundary on whichever
                // layout the hatch actually lives on, regardless of which layout is "current".
                var space = (BlockTableRecord)tr.GetObject(hatch.OwnerId, OpenMode.ForWrite);

                var outcome = HatchBoundaryHelper.RecreateBoundary(tr, space, hatch, copyHatchLayer);
                processed++;

                // (if (and (= noarea nil) (= loops1 1)) (setq area (+ area (areaOfObject (entlast))))
                //     (setq bMoreLoops T))
                if (!outcome.HasMultipleLoopsOrUnsupportedEdge && outcome.LastCreated is Curve boundaryCurve)
                {
                    area += HatchBoundaryHelper.SafeGetArea(boundaryCurve);
                }
                else
                {
                    areaIsReliable = false;
                }
            }

            // (if (and area (not bMoreLoops)) (progn (princ "\nTotal Area = ") (princ area)))
            var result = new HatchBoundaryResult(processed, areaIsReliable ? area : null, areaIsReliable);
            Application.DocumentManager.MdiActiveDocument.Editor.WriteMessage(
                $"\nHatchBDA: processed {result.HatchesProcessed} hatch(es)." +
                (result.AreaIsReliable
                    ? $" Total area = {result.TotalArea}\n"
                    : " Total area not reported (multiple loops or an unsupported edge in at least one hatch).\n"));

            tr.Commit();
        }
        catch (System.Exception)
        {
            tr.Abort();
            throw; // let the DA WorkItem report the failure — there's no interactive session to recover into
        }
    }
}
