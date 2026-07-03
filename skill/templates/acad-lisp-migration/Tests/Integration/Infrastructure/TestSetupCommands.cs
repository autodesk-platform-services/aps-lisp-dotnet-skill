using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;

namespace MyPlugin.IntegrationTests.Infrastructure;

// Runs in AutoCAD command context — document lock held automatically.
// This is the ONLY place that writes to the database. NUnit threads never write.
public class TestSetupCommands
{
    [CommandMethod("MyPluginSetupTest")]
    public static void SetupTestData()
    {
        var db = HostApplicationServices.WorkingDatabase;
        using var tr = db.TransactionManager.StartTransaction();

        // TODO: call your Commands methods, capture value-type results into TestData.
        // Example:
        //   var entity = Commands.CreateSomething(tr, db, ...);
        //   TestData.SomeProperty = entity.SomeValue;

        TestData.Initialized = true;
        tr.Commit();
    }
}
