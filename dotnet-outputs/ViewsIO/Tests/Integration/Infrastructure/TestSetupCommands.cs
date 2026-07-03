using System.Text.Json;
using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;

namespace ViewsIO.IntegrationTests.Infrastructure;

// Runs in AutoCAD command context — document lock held automatically.
// This is the ONLY place that writes to the database. NUnit threads never write.
public class TestSetupCommands
{
    [CommandMethod("ViewsIOSetupTest")]
    public static void SetupTestData()
    {
        var db = HostApplicationServices.WorkingDatabase;
        using var tr = db.TransactionManager.StartTransaction();

        // Count views before export
        var vt = (ViewTable)tr.GetObject(db.ViewTableId, OpenMode.ForRead);
        TestData.InitialViewCount = vt.Cast<ObjectId>().Count();

        // Export to temp file
        var tempFile = Path.Combine(Path.GetTempPath(), "ViewsIOTest.json");
        ViewTableHelper.ExportViews(tempFile, db, tr);
        TestData.ExportedFilePath = tempFile;
        TestData.ExportFileExists = File.Exists(tempFile);

        // Count records in exported JSON
        if (TestData.ExportFileExists)
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(tempFile));
            TestData.ExportedViewCount = doc.RootElement.GetArrayLength();
        }

        // Import back — skip-existing logic should leave count unchanged
        ViewTableHelper.ImportViews(tempFile, db, tr);
        var vtAfter = (ViewTable)tr.GetObject(db.ViewTableId, OpenMode.ForRead);
        TestData.ViewCountAfterImport = vtAfter.Cast<ObjectId>().Count();

        TestData.Initialized = true;
        tr.Commit();
    }
}
