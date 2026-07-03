using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using NUnit.Framework;
using NUnit.Framework.Interfaces;

namespace GardenPath.IntegrationTests.Infrastructure;

// Adapted from https://github.com/ADN-DevTech/coreconsolerunner (Madhu Moogala).
// Rule: tests only READ. Writes happen in [CommandMethod] setup commands
// (GPathSetupTest etc.) which run on the AutoCAD command thread with the
// document lock held automatically — no LockDocument() or OpenCloseTransaction needed.
[TestFixture]
public abstract class DrawingTestBase
{
    protected Database    testDb = null!;
    protected Transaction trans  = null!;

    [OneTimeSetUp]
    public void Init()
    {
        testDb = HostApplicationServices.WorkingDatabase;
        Assert.That(testDb, Is.Not.Null, "No working database — accoreconsole not initialised?");
    }

    [SetUp]
    public void BeforeEach() =>
        trans = testDb.TransactionManager.StartTransaction();

    [TearDown]
    public void AfterEach()
    {
        var ctx   = TestContext.CurrentContext;
        var entry = TestReport.CreateTest(ctx.Test.Name);
        if (ctx.Result.Outcome.Status == TestStatus.Passed)
            entry.Pass("passed");
        else
            entry.Fail(ctx.Result.Message ?? "failed");

        trans?.Dispose();
        trans = null!;
    }
}
