using Autodesk.AutoCAD.ApplicationServices;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.EditorInput;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;

namespace GardenPath;

public class Commands
{
    // (defun C:GPath ...)
    [CommandMethod("GPATH")]
    public void GPath()
    {
        var doc = Application.DocumentManager.MdiActiveDocument;
        var ed  = doc.Editor;
        var db  = doc.Database;

        if (!GetPointInput(ed, out var pathData))
        {
            ed.WriteMessage("\nIncomplete information to draw a boundary.");
            return;
        }

        // gp:getDialogInput — stub (Lesson 3 just shows an alert)
        // TODO v2: replace with WPF dialog for tile size, spacing, border type
        Application.ShowAlertDialog(
            "Function gp:getDialogInput will get user choices via a dialog");

        using var tr = db.TransactionManager.StartTransaction();
        var pline = DrawOutline(tr, db, pathData);
        tr.Commit();

        ed.WriteMessage($"\nThe DrawOutline function returned <{pline.Handle}>");
        Application.ShowAlertDialog("Congratulations - your program is complete!");
    }

    // (defun gp:getPointInput ...) — asks for start point, endpoint, half-width
    // Returns PathData or sets data=null and returns false on cancellation
    private static bool GetPointInput(Editor ed, out PathData data)
    {
        data = null!;

        var startRes = ed.GetPoint("\nStart point of path: ");
        if (startRes.Status != PromptStatus.OK) return false;
        var startPt = startRes.Value;

        var endOpts = new PromptPointOptions("\nEndpoint of path: ")
        {
            UseBasePoint = true,
            BasePoint    = startPt
        };
        var endRes = ed.GetPoint(endOpts);
        if (endRes.Status != PromptStatus.OK) return false;
        var endPt = endRes.Value;

        var distOpts = new PromptDistanceOptions("\nHalf width of path: ")
        {
            UseBasePoint = true,
            BasePoint    = endPt
        };
        var distRes = ed.GetDistance(distOpts);
        if (distRes.Status != PromptStatus.OK) return false;
        var halfWidth = distRes.Value;

        var vec = endPt - startPt;
        data = new PathData(
            StartPoint: startPt,
            EndPoint:   endPt,
            Width:      halfWidth * 2.0,
            Length:     startPt.DistanceTo(endPt),
            PathAngle:  Math.Atan2(vec.Y, vec.X)   // (angle StartPt EndPt)
        );
        return true;
    }

    // (defun gp:drawOutline (BoundaryData) ...)
    // Visual LISP vla-addLightweightPolyline + vlax-make-safearray replaced by
    // typed Polyline API — removes COM dependency, enabling Design Automation.
    internal static Polyline DrawOutline(Transaction tr, Database db, PathData d)
    {
        var halfWidth = d.Width / 2.0;
        var angP90    = d.PathAngle + GeometryHelper.DegreesToRadians(90);
        var angM90    = d.PathAngle - GeometryHelper.DegreesToRadians(90);

        // (polar StartPt angm90 HalfWidth) etc.
        var p1 = GeometryHelper.Polar(d.StartPoint, angM90,    halfWidth);
        var p2 = GeometryHelper.Polar(p1,           d.PathAngle, d.Length);
        var p3 = GeometryHelper.Polar(p2,           angP90,    d.Width);
        var p4 = GeometryHelper.Polar(p3,           d.PathAngle + GeometryHelper.DegreesToRadians(180), d.Length);

        var pline = new Polyline();
        pline.AddVertexAt(0, GeometryHelper.Point3dTo2d(p1), 0, 0, 0);
        pline.AddVertexAt(1, GeometryHelper.Point3dTo2d(p2), 0, 0, 0);
        pline.AddVertexAt(2, GeometryHelper.Point3dTo2d(p3), 0, 0, 0);
        pline.AddVertexAt(3, GeometryHelper.Point3dTo2d(p4), 0, 0, 0);
        pline.Closed = true;   // (vla-put-closed pline T)

        var btr = (BlockTableRecord)tr.GetObject(db.CurrentSpaceId, OpenMode.ForWrite);
        btr.AppendEntity(pline);
        tr.AddNewlyCreatedDBObject(pline, true);

        return pline;
    }
}
