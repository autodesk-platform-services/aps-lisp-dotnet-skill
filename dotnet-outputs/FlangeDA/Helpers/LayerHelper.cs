using Autodesk.AutoCAD.Colors;
using Autodesk.AutoCAD.DatabaseServices;

namespace FlangeDA.Helpers;

/// <summary>
/// Mirrors the original LISP's repeated
/// (command "layer" "m" "centre" "c" "green" "" "l" "center" "" "")
/// — make-or-set the "centre" layer to green / CENTER linetype. The migrated
/// commands set LayerId on each created entity directly instead of mutating
/// the drawing's current layer (CLAYER), which is safer under DA — no shared
/// current-layer state to restore afterward.
/// </summary>
internal static class LayerHelper
{
    internal static ObjectId EnsureCentreLayer(Database db, Transaction tr)
    {
        const string layerName = "centre";
        const string linetypeName = "CENTER";

        var lt = (LinetypeTable)tr.GetObject(db.LinetypeTableId, OpenMode.ForRead);
        if (!lt.Has(linetypeName))
        {
            db.LoadLineTypeFile(linetypeName, "acad.lin");
        }
        ObjectId linetypeId = lt.Has(linetypeName) ? lt[linetypeName] : db.ContinuousLinetype;

        var layers = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForRead);
        if (layers.Has(layerName))
        {
            return layers[layerName];
        }

        layers.UpgradeOpen();
        var ltr = new LayerTableRecord
        {
            Name = layerName,
            Color = Color.FromColorIndex(ColorMethod.ByAci, 3), // green
            LinetypeObjectId = linetypeId,
        };
        ObjectId layerId = layers.Add(ltr);
        tr.AddNewlyCreatedDBObject(ltr, true);
        return layerId;
    }
}
