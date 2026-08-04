using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;

namespace HatchBDA.IntegrationTests.Infrastructure;

// Runs in AutoCAD command context — document lock held automatically.
// This is the ONLY place that writes to the database. NUnit threads never write.
public class TestSetupCommands
{
    [CommandMethod("HatchBDASetupTest")]
    public static void SetupTestData()
    {
        var db = HostApplicationServices.WorkingDatabase;
        using var tr = db.TransactionManager.StartTransaction();

        // Put the source hatch on its own layer, distinct from "0", so BoundaryLayer vs.
        // SourceHatchLayer is a meaningful comparison (HATCHB/HB must NOT copy it; HBL would).
        var lt = (LayerTable)tr.GetObject(db.LayerTableId, OpenMode.ForWrite);
        const string hatchLayerName = "HatchBDA_SourceLayer";
        if (!lt.Has(hatchLayerName))
        {
            var ltr = new LayerTableRecord { Name = hatchLayerName };
            lt.Add(ltr);
            tr.AddNewlyCreatedDBObject(ltr, true);
        }

        var bt = (BlockTable)tr.GetObject(db.BlockTableId, OpenMode.ForRead);
        var modelSpace = (BlockTableRecord)tr.GetObject(bt[BlockTableRecord.ModelSpace], OpenMode.ForWrite);

        // A single rectangular (10 x 5) polyline-type boundary loop — no islands, no
        // unsupported edges, so the area computation is expected to be reliable.
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
        hatch.Layer = hatchLayerName;
        hatch.AppendLoop(HatchLoopTypes.Default, loopPoints, bulges);
        hatch.EvaluateHatch(true);

        // Call the migrated HATCHB command (hl = nil -> does not copy the hatch's layer)
        // directly. No params.json is present in accoreconsole's working directory, so
        // HatchBoundaryInput falls back to its default (ProcessAllHatches = true) and picks
        // up the hatch just created above.
        var commands = new Commands();
        commands.Hatchb();

        // Inspect what the command created. Model Space entity enumeration reflects the
        // command's own (already-committed) nested transaction even though the outer
        // transaction here is still open.
        int polylineCount = 0;
        Autodesk.AutoCAD.DatabaseServices.Polyline? boundary = null;
        foreach (ObjectId id in modelSpace)
        {
            if (tr.GetObject(id, OpenMode.ForRead) is Autodesk.AutoCAD.DatabaseServices.Polyline pline)
            {
                polylineCount++;
                boundary = pline;
            }
        }

        TestData.RecreatedPolylineCount = polylineCount;
        TestData.SourceHatchLayer = hatchLayerName;

        if (boundary is not null)
        {
            TestData.BoundaryIsClosed = boundary.Closed;
            TestData.BoundaryVertexCount = boundary.NumberOfVertices;
            TestData.BoundaryArea = boundary.Area;
            TestData.BoundaryLayer = boundary.Layer;
        }

        TestData.Initialized = true;
        tr.Commit();
    }
}
