using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using FlangeDA.Helpers;
using FlangeDA.Models;

namespace FlangeDA.IntegrationTests.Infrastructure;

// Runs in AutoCAD command context — document lock held automatically.
// This is the ONLY place that writes to the database. NUnit threads never write.
// Drives HolePatternDrawer directly (not the FLANGE command) so this doesn't
// depend on a params.json file existing next to accoreconsole's CWD.
public class TestSetupCommands
{
    [CommandMethod("FlangeDASetupTest")]
    public static void SetupTestData()
    {
        var db = HostApplicationServices.WorkingDatabase;
        using var tr = db.TransactionManager.StartTransaction();

        var flatInput = new HolePatternInput
        {
            Offset = true,
            FlangeTangentAngleDegrees = 0.0,
            PatternDiameter = 180.0,
            NumberOfHoles = 6,
            HoleDiameter = 18.0,
            CenterX = 0.0,
            CenterY = 0.0,
        };
        HolePatternDrawer.DrawFlatPattern(db, tr, flatInput);

        TestData.FlatCircleCount = CountEntities<Circle>(tr, db.CurrentSpaceId);
        TestData.FlatLineCount = CountEntities<Line>(tr, db.CurrentSpaceId);

        var angledInput = new HolePatternInput
        {
            Offset = true,
            FlangeTangentAngleDegrees = 30.0,
            PatternDiameter = 180.0,
            NumberOfHoles = 6,
            HoleDiameter = 18.0,
            CenterX = 300.0,
            CenterY = 0.0,
            RotationAngleDegrees = 15.0,
        };
        HolePatternDrawer.DrawAngledPattern(db, tr, angledInput);

        TestData.AngledEllipseCount = CountEntities<Ellipse>(tr, db.CurrentSpaceId);
        TestData.AngledLineCount = CountEntities<Line>(tr, db.CurrentSpaceId) - TestData.FlatLineCount;

        TestData.Initialized = true;
        tr.Commit();
    }

    private static int CountEntities<T>(Transaction tr, ObjectId spaceId) where T : Entity
    {
        var space = (BlockTableRecord)tr.GetObject(spaceId, OpenMode.ForRead);
        int count = 0;
        foreach (ObjectId id in space)
        {
            if (tr.GetObject(id, OpenMode.ForRead) is T)
            {
                count++;
            }
        }
        return count;
    }
}
