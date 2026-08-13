using System.Text.Json;
using Autodesk.AutoCAD.ApplicationServices.Core;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Runtime;
using FlangeDA.Helpers;
using FlangeDA.Models;

namespace FlangeDA;

// Migrated from Flange.lsp's C:Flange, restricted to the user-defined hole-pattern
// branch (select = "pat") per this migration's scope. draw_front/draw_anglefront
// (standard-size flange holes via the flange.lst lookup) and the flat/raised flange
// outline branches are out of scope for this pass.
//
// TODO v2: the original DialogBox()/input_pattern() DCL dialogs (Flange.dcl) that
// gathered these values interactively are stubbed out entirely — every field they
// collected now arrives as HolePatternInput from params.json. See SKILL.md's DCL
// Guardrail.
public class Commands
{
    [CommandMethod("FLANGE")]
    public void Flange()
    {
        Editor ed = Application.DocumentManager.MdiActiveDocument.Editor;
        var db = HostApplicationServices.WorkingDatabase;

        string paramsPath = Path.Combine(Environment.CurrentDirectory, "params.json");
        var input = JsonSerializer.Deserialize<HolePatternInput>(File.ReadAllText(paramsPath))
            ?? throw new InvalidOperationException($"Failed to parse {paramsPath}");

        foreach (string warning in PatternValidator.Validate(input))
        {
            ed.WriteMessage($"\n{warning}");
        }

        using var tr = db.TransactionManager.StartTransaction();
        try
        {
            if (input.FlangeTangentAngleDegrees == 0.0)
            {
                HolePatternDrawer.DrawFlatPattern(db, tr, input);
            }
            else
            {
                HolePatternDrawer.DrawAngledPattern(db, tr, input);
            }
            tr.Commit();
        }
        catch (System.Exception)
        {
            tr.Abort();
            throw; // let the DA WorkItem report the failure — no interactive session to recover into
        }

        ed.WriteMessage("\nFLANGE hole pattern drawn.\n");
    }
}
