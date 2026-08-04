namespace HatchBDA.IntegrationTests.Infrastructure;

// Written by HatchBDASetupTest command (AutoCAD command context — holds doc lock automatically).
// Read-only by NUnit test threads — no database access from test threads.
// Value types only (never ObjectId/DBObject) — see SKILL.md's Tier 2 rule.
public static class TestData
{
    public static bool Initialized { get; set; }

    // Number of Polyline entities present in Model Space after HATCHB ran — the rectangular
    // test hatch has exactly one polyline-type boundary loop, so exactly one Polyline should
    // have been recreated (vla-addLightweightPolyline -> typed Polyline).
    public static int RecreatedPolylineCount { get; set; }

    public static bool BoundaryIsClosed { get; set; }
    public static int BoundaryVertexCount { get; set; }

    // Area of the 10 x 5 rectangular boundary — exercises the
    // vlax-curve-getArea / vl-catch-all-apply -> Curve.Area / try-catch mapping.
    public static double BoundaryArea { get; set; }

    // HATCHB (hl = nil) must NOT copy the hatch's own layer onto the recreated boundary —
    // it should stay on the current layer ("0"), while the source hatch is deliberately put
    // on a different layer so this is a meaningful assertion.
    public static string BoundaryLayer { get; set; } = string.Empty;
    public static string SourceHatchLayer { get; set; } = string.Empty;
}
