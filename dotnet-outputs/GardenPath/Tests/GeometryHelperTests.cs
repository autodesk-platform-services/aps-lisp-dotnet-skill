using Xunit;

namespace GardenPath.Tests;

// Pure math tests — run without AutoCAD host
public class GeometryHelperTests
{
    [Fact]
    public void DegreesToRadians_Zero() =>
        Assert.Equal(0.0, GeometryHelper.DegreesToRadians(0));

    [Theory]
    [InlineData(90,  Math.PI / 2)]
    [InlineData(180, Math.PI)]
    [InlineData(360, Math.PI * 2)]
    public void DegreesToRadians_KnownAngles(double degrees, double expected) =>
        Assert.Equal(expected, GeometryHelper.DegreesToRadians(degrees), precision: 10);

    [Theory]
    [InlineData(0.0,        10.0, 10.0, 0.0)]   // east
    [InlineData(Math.PI/2,  10.0, 0.0,  10.0)]  // north
    [InlineData(Math.PI,    10.0, -10.0, 0.0)]  // west
    public void Polar_RawMath(double angle, double dist, double expectedDx, double expectedDy)
    {
        double dx = dist * Math.Cos(angle);
        double dy = dist * Math.Sin(angle);
        Assert.Equal(expectedDx, dx, precision: 8);
        Assert.Equal(expectedDy, dy, precision: 8);
    }
}

// Geometry tests (Point3d / Polar / Point3dTo2d / DrawOutline vertex count) require AutoCAD host.
// Use coreconsolerunner: https://github.com/ADN-DevTech/coreconsolerunner
// NUnit + NUnitLite self-hosted — inherit DrawingTestBase, run via accoreconsole /al GardenPath.bundle
