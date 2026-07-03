using Autodesk.AutoCAD.Geometry;

namespace GardenPath.IntegrationTests.Infrastructure;

// Written by GPathSetupTest command (AutoCAD command context — holds document lock).
// Read-only by NUnit tests — no DB access needed from test threads.
public static class TestData
{
    public static bool    Initialized { get; set; }
    public static int     VertexCount { get; set; }
    public static bool    Closed      { get; set; }
    public static Point2d V0          { get; set; }
    public static Point2d V1          { get; set; }
    public static Point2d V2          { get; set; }
    public static Point2d V3          { get; set; }
}
