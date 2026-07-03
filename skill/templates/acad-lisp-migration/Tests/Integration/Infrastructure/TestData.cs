namespace MyPlugin.IntegrationTests.Infrastructure;

// Written by MyPluginSetupTest command (AutoCAD command context — holds doc lock automatically).
// Read-only by NUnit test threads — no database access from test threads.
// TODO: add value-type properties (Point2d, double, int, bool — never ObjectId/DBObject refs).
public static class TestData
{
    public static bool Initialized { get; set; }
}
