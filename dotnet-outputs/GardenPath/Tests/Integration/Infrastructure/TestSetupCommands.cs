using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Geometry;
using Autodesk.AutoCAD.Runtime;

namespace GardenPath.IntegrationTests.Infrastructure;

// Runs in AutoCAD command context — document lock is held automatically.
// This is the ONLY place that writes to the database. NUnit threads never write.
public class TestSetupCommands
{
    private static readonly PathData HorizontalPath = new(
        StartPoint: new Point3d(0, 0, 0),
        EndPoint:   new Point3d(10, 0, 0),
        Width:      2.0,
        Length:     10.0,
        PathAngle:  0.0);

    [CommandMethod("GPathSetupTest")]
    public static void SetupTestData()
    {
        var db = HostApplicationServices.WorkingDatabase;
        using var tr = db.TransactionManager.StartTransaction();
        var pline = Commands.DrawOutline(tr, db, HorizontalPath);

        TestData.VertexCount = pline.NumberOfVertices;
        TestData.Closed      = pline.Closed;
        TestData.V0          = pline.GetPoint2dAt(0);
        TestData.V1          = pline.GetPoint2dAt(1);
        TestData.V2          = pline.GetPoint2dAt(2);
        TestData.V3          = pline.GetPoint2dAt(3);
        TestData.Initialized = true;

        tr.Commit();
    }
}
