using Autodesk.AutoCAD.DatabaseServices;
using Autodesk.AutoCAD.Runtime;
using NUnit.Framework;
using NUnit.Framework.Interfaces;

namespace HatchBDA.IntegrationTests.Infrastructure;

// Pattern: tests only READ. Writes happen in [CommandMethod] setup commands.
// Command thread holds document lock automatically — no LockDocument needed.
[TestFixture]
public abstract class DrawingTestBase
{
    protected Database    testDb = null!;
    protected Transaction trans  = null!;

    [OneTimeSetUp]
    public void Init()
    {
        testDb = HostApplicationServices.WorkingDatabase;
        Assert.That(testDb, Is.Not.Null, "No working database.");
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
