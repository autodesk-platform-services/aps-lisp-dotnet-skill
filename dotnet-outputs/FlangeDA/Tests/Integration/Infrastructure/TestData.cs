namespace FlangeDA.IntegrationTests.Infrastructure;

// Written by FlangeDASetupTest command (AutoCAD command context — holds doc lock automatically).
// Read-only by NUnit test threads — no database access from test threads.
public static class TestData
{
    public static bool Initialized { get; set; }

    // draw_pattern (flat, FlangeTangentAngleDegrees == 0): NumberOfHoles hole circles + 1 pcd circle.
    public static int FlatCircleCount { get; set; }

    // draw_pattern centreline marks: one Line per hole.
    public static int FlatLineCount { get; set; }

    // draw_angpattern (angled): NumberOfHoles hole ellipses + 1 pcd ellipse.
    public static int AngledEllipseCount { get; set; }

    // draw_angpattern centreline marks: one Line per hole.
    public static int AngledLineCount { get; set; }
}
