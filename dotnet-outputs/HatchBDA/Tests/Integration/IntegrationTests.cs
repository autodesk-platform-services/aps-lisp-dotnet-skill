using HatchBDA.IntegrationTests.Infrastructure;
using NUnit.Framework;

namespace HatchBDA.IntegrationTests;

// Exercises the migrated HATCHB command (via HatchBDASetupTest) against a real Hatch
// entity created in accoreconsole — a single 10 x 5 rectangular boundary loop with no
// islands, so the recreated boundary and its area should both be well-defined.
[TestFixture]
public class HatchBoundaryIntegrationTests : DrawingTestBase
{
    [OneTimeSetUp]
    public void CheckSetup() =>
        Assert.That(TestData.Initialized, Is.True,
            "HatchBDASetupTest command did not run — check the generated .scr file.");

    // vla-addLightweightPolyline -> typed Polyline: exactly one boundary recreated for the
    // hatch's single loop.
    [Test]
    public void RecreatedPolylineCount_IsExactlyOne() =>
        Assert.That(TestData.RecreatedPolylineCount, Is.EqualTo(1));

    // (if (= ic 1) (vla-put-closed obj T)) -> Polyline.Closed
    [Test]
    public void Boundary_IsClosed() =>
        Assert.That(TestData.BoundaryIsClosed, Is.True);

    [Test]
    public void Boundary_HasFourVertices() =>
        Assert.That(TestData.BoundaryVertexCount, Is.EqualTo(4));

    // vlax-curve-getArea / vl-catch-all-apply -> Curve.Area / try-catch: 10 x 5 rectangle.
    [Test]
    public void Boundary_AreaMatchesRectangle() =>
        Assert.That(TestData.BoundaryArea, Is.EqualTo(50.0).Within(0.001));

    // HB/HATCHB (hl = nil): (if hl (vla-put-layer obj layer)) must NOT fire — the recreated
    // boundary stays on the current layer ("0"), not the source hatch's layer.
    [Test]
    public void Boundary_DoesNotCopyHatchLayer_WhenHlIsFalse()
    {
        Assert.That(TestData.BoundaryLayer, Is.EqualTo("0"));
        Assert.That(TestData.BoundaryLayer, Is.Not.EqualTo(TestData.SourceHatchLayer));
    }
}
