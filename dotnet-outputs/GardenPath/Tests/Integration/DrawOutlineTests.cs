using GardenPath.IntegrationTests.Infrastructure;
using NUnit.Framework;
using NUnit.Framework.Interfaces;

namespace GardenPath.IntegrationTests;

// Asserts against data captured by GPathSetupTest (AutoCAD command, runs before RunCADtests).
// No DB access from test thread — pure value-type assertions on TestData statics.
//
// Expected outline for horizontal path (0,0)→(10,0), halfWidth=1:
//   v0=(0,-1)  v1=(10,-1)  v2=(10,1)  v3=(0,1)
[TestFixture, Apartment(ApartmentState.STA), Category("DrawOutline")]
public class DrawOutlineTests
{
    [OneTimeSetUp]
    public void CheckSetup() =>
        Assert.That(TestData.Initialized, Is.True,
            "GPathSetupTest must run before RunCADtests — check the script.");

    [TearDown]
    public void AfterEach()
    {
        var ctx   = TestContext.CurrentContext;
        var entry = TestReport.CreateTest(ctx.Test.Name);
        if (ctx.Result.Outcome.Status == TestStatus.Passed)
            entry.Pass("passed");
        else
            entry.Fail(ctx.Result.Message ?? "failed");
    }

    [Test]
    public void DrawOutline_Produces4Vertices() =>
        Assert.That(TestData.VertexCount, Is.EqualTo(4));

    [Test]
    public void DrawOutline_PolylineIsClosed() =>
        Assert.That(TestData.Closed, Is.True);

    [Test]
    public void DrawOutline_Vertex0_BottomLeft()
    {
        Assert.That(TestData.V0.X, Is.EqualTo(0.0).Within(1e-8));
        Assert.That(TestData.V0.Y, Is.EqualTo(-1.0).Within(1e-8));
    }

    [Test]
    public void DrawOutline_Vertex1_BottomRight()
    {
        Assert.That(TestData.V1.X, Is.EqualTo(10.0).Within(1e-8));
        Assert.That(TestData.V1.Y, Is.EqualTo(-1.0).Within(1e-8));
    }

    [Test]
    public void DrawOutline_Vertex2_TopRight()
    {
        Assert.That(TestData.V2.X, Is.EqualTo(10.0).Within(1e-8));
        Assert.That(TestData.V2.Y, Is.EqualTo(1.0).Within(1e-8));
    }

    [Test]
    public void DrawOutline_Vertex3_TopLeft()
    {
        Assert.That(TestData.V3.X, Is.EqualTo(0.0).Within(1e-8));
        Assert.That(TestData.V3.Y, Is.EqualTo(1.0).Within(1e-8));
    }
}
