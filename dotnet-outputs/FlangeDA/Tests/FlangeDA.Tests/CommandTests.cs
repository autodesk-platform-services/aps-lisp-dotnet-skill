using FlangeDA.Helpers;
using FlangeDA.Models;
using Xunit;

namespace FlangeDA.Tests;

// Pure logic — no AutoCAD runtime needed. Covers the two hole-pattern helpers
// that don't touch a Database: GeometryHelper (mirrors Degrees->Radians) and
// PatternValidator (mirrors the (info) validation function).
public class CommandTests
{
    [Theory]
    [InlineData(0.0, 0.0)]
    [InlineData(180.0, Math.PI)]
    [InlineData(90.0, Math.PI / 2)]
    public void DegreesToRadians_ConvertsCorrectly(double degrees, double expectedRadians) =>
        Assert.Equal(expectedRadians, GeometryHelper.DegreesToRadians(degrees), precision: 10);

    [Fact]
    public void Validate_ZeroPatternDiameter_Throws()
    {
        var input = new HolePatternInput { PatternDiameter = 0, NumberOfHoles = 6, HoleDiameter = 10 };
        Assert.Throws<ArgumentException>(() => PatternValidator.Validate(input));
    }

    [Fact]
    public void Validate_ZeroNumberOfHoles_Throws()
    {
        var input = new HolePatternInput { PatternDiameter = 100, NumberOfHoles = 0, HoleDiameter = 10 };
        Assert.Throws<ArgumentException>(() => PatternValidator.Validate(input));
    }

    [Fact]
    public void Validate_ZeroHoleDiameter_Throws()
    {
        var input = new HolePatternInput { PatternDiameter = 100, NumberOfHoles = 6, HoleDiameter = 0 };
        Assert.Throws<ArgumentException>(() => PatternValidator.Validate(input));
    }

    [Fact]
    public void Validate_ReasonablePattern_NoWarnings()
    {
        var input = new HolePatternInput { PatternDiameter = 180, NumberOfHoles = 8, HoleDiameter = 18 };
        Assert.Empty(PatternValidator.Validate(input));
    }

    [Fact]
    public void Validate_TooManyHoles_WarnsButDoesNotThrow()
    {
        // num * holeDiameter >= pcd * pi
        var input = new HolePatternInput { PatternDiameter = 10, NumberOfHoles = 20, HoleDiameter = 10 };
        var warnings = PatternValidator.Validate(input);
        Assert.Contains("Too many holes??", warnings);
    }
}
