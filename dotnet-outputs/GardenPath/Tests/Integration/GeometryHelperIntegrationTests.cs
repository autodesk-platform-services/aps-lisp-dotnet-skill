using Autodesk.AutoCAD.Geometry;
using GardenPath.IntegrationTests.Infrastructure;
using NUnit.Framework;

namespace GardenPath.IntegrationTests;

// Tests that need Point3d/Point2d — require AutoCAD host, run via accoreconsole.
// Pure math equivalents are in Tests/GeometryHelperTests.cs (xUnit, no host).
// Inherits DrawingTestBase: testDb + trans (read-only), ExtentReports AfterEach logging.
[TestFixture, Apartment(ApartmentState.STA), Category("Geometry")]
public class GeometryHelperIntegrationTests : DrawingTestBase
{
    [Test]
    public void Polar_East_MovesAlongPositiveX()
    {
        var result = GeometryHelper.Polar(new Point3d(0, 0, 0), 0.0, 10.0);
        Assert.That(result.X, Is.EqualTo(10.0).Within(1e-10));
        Assert.That(result.Y, Is.EqualTo(0.0).Within(1e-10));
        Assert.That(result.Z, Is.EqualTo(0.0).Within(1e-10));
    }

    [Test]
    public void Polar_North_MovesAlongPositiveY()
    {
        var result = GeometryHelper.Polar(new Point3d(0, 0, 0), Math.PI / 2, 10.0);
        Assert.That(result.X, Is.EqualTo(0.0).Within(1e-10));
        Assert.That(result.Y, Is.EqualTo(10.0).Within(1e-10));
    }

    [Test]
    public void Polar_PreservesBasePointZ()
    {
        var result = GeometryHelper.Polar(new Point3d(1, 2, 5), 0.0, 3.0);
        Assert.That(result.Z, Is.EqualTo(5.0).Within(1e-10));
    }

    [Test]
    public void Point3dTo2d_DropsZComponent()
    {
        var result = GeometryHelper.Point3dTo2d(new Point3d(3.0, 4.0, 99.0));
        Assert.That(result.X, Is.EqualTo(3.0).Within(1e-10));
        Assert.That(result.Y, Is.EqualTo(4.0).Within(1e-10));
    }
}
