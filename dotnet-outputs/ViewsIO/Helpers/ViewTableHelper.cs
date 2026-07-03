using System.Text.Json;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;

namespace ViewsIO;

internal static class ViewTableHelper
{
    private static readonly JsonSerializerOptions _json = new() { WriteIndented = true };

    // (defun ExportViews fn ...) — serializes all named views to JSON.
    // entget (tblobjname "view" name) → ViewTableRecord properties.
    // assoc 348 → vtr.VisualStyleId → look up name in ACAD_VISUALSTYLE dict.
    internal static void ExportViews(string filePath, Database db, Transaction tr)
    {
        var vt      = (ViewTable)tr.GetObject(db.ViewTableId, OpenMode.ForRead);
        var nod     = (DBDictionary)tr.GetObject(db.NamedObjectsDictionaryId, OpenMode.ForRead);
        DBDictionary? vsDict = nod.Contains("ACAD_VISUALSTYLE")
            ? (DBDictionary)tr.GetObject(nod.GetAt("ACAD_VISUALSTYLE"), OpenMode.ForRead)
            : null;

        var records = new List<ViewRecord>();
        foreach (ObjectId id in vt)
        {
            var vtr    = (ViewTableRecord)tr.GetObject(id, OpenMode.ForRead);
            string? vsName = ResolveVisualStyleName(vtr.VisualStyleId, vsDict);

            records.Add(new ViewRecord
            {
                Name            = vtr.Name,
                TargetX         = vtr.Target.X,
                TargetY         = vtr.Target.Y,
                TargetZ         = vtr.Target.Z,
                ViewDirX        = vtr.ViewDirection.X,
                ViewDirY        = vtr.ViewDirection.Y,
                ViewDirZ        = vtr.ViewDirection.Z,
                Height          = vtr.Height,
                Width           = vtr.Width,
                TwistAngle      = vtr.ViewTwist,
                VisualStyleName = vsName,
            });
        }

        File.WriteAllText(filePath, JsonSerializer.Serialize(records, _json));
    }

    // (defun ImportViews fn ...) — restores named views from JSON.
    // entmake VIEW → new ViewTableRecord + vt.Add + tr.AddNewlyCreatedDBObject.
    // assoc 348 / entmod → vtr.VisualStyleId = vsDict.GetAt(name) if present.
    internal static void ImportViews(string filePath, Database db, Transaction tr)
    {
        var records = JsonSerializer.Deserialize<ViewRecord[]>(File.ReadAllText(filePath)) ?? [];

        var vt  = (ViewTable)tr.GetObject(db.ViewTableId, OpenMode.ForWrite);
        var nod = (DBDictionary)tr.GetObject(db.NamedObjectsDictionaryId, OpenMode.ForRead);
        DBDictionary? vsDict = nod.Contains("ACAD_VISUALSTYLE")
            ? (DBDictionary)tr.GetObject(nod.GetAt("ACAD_VISUALSTYLE"), OpenMode.ForRead)
            : null;

        foreach (var rec in records)
        {
            if (vt.Has(rec.Name)) continue; // skip existing — matches LISP entmake behavior

            var vtr = new ViewTableRecord
            {
                Name          = rec.Name,
                Target        = new Point3d(rec.TargetX, rec.TargetY, rec.TargetZ),
                ViewDirection = new Vector3d(rec.ViewDirX, rec.ViewDirY, rec.ViewDirZ),
                Height        = rec.Height,
                Width         = rec.Width,
                ViewTwist     = rec.TwistAngle,
            };

            // entmod: set visual style if it exists in this drawing (name lookup)
            if (rec.VisualStyleName is not null && vsDict is not null
                && vsDict.Contains(rec.VisualStyleName))
                vtr.VisualStyleId = vsDict.GetAt(rec.VisualStyleName);

            vt.Add(vtr);
            tr.AddNewlyCreatedDBObject(vtr, true);
        }
    }

    private static string? ResolveVisualStyleName(ObjectId vsId, DBDictionary? vsDict)
    {
        if (vsId.IsNull || vsDict is null) return null;
        foreach (var entry in vsDict)
            if (entry.Value == vsId) return entry.Key;
        return null;
    }
}
