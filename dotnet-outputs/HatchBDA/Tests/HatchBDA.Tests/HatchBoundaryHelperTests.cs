using HatchBDA.Helpers;
using Xunit;

namespace HatchBDA.Tests;

// Pure logic pulled out of Helpers/HatchBoundaryHelper.cs — no AutoCAD types (Point3d,
// ObjectId, CircularArc2d, etc.), so these run under plain `dotnet test`, no AutoCAD host.
public class HatchBoundaryHelperTests
{
    // (equal ang1 0 0.00001) (equal ang2 6.28319 0.00001) — the original's full-circle check.
    [Theory]
    [InlineData(0.0, 6.283185307179586, true)]      // exact 0 .. 2*pi
    [InlineData(0.00001, 6.283185307179586, true)]  // within the original's 0.00001 tolerance
    [InlineData(0.0, 3.141592653589793, false)]     // a half-circle arc, not a full sweep
    [InlineData(0.1, 6.283185307179586, false)]     // outside tolerance on the start angle
    public void IsFullSweep_MatchesOriginalTolerance(double startAngle, double endAngle, bool expected) =>
        Assert.Equal(expected, HatchBoundaryHelper.IsFullSweep(startAngle, endAngle));

    // (if (and (= noarea nil) (= loops1 1)) (setq area (+ area ...)) (setq bMoreLoops T))
    [Theory]
    [InlineData(1, false, false)] // single loop, fully supported -> area is trustworthy
    [InlineData(2, false, true)]  // islands present -> can't tell which loops to add/subtract
    [InlineData(1, true, true)]   // single loop but an edge (e.g. spline) wasn't recreated
    [InlineData(0, false, true)]  // no loops at all is not the "exactly one loop" case either
    public void IsAreaUnreliable_MatchesOriginalBMoreLoopsGate(int loopCount, bool hasUnsupportedEdge, bool expected) =>
        Assert.Equal(expected, HatchBoundaryHelper.IsAreaUnreliable(loopCount, hasUnsupportedEdge));
}
