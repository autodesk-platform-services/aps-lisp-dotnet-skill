namespace ViewsIO.IntegrationTests.Infrastructure;

// Written by ViewsIOSetupTest (AutoCAD command context — doc lock held automatically).
// Read-only by NUnit test threads — no database access from test threads.
public static class TestData
{
    public static bool   Initialized      { get; set; }
    public static int    InitialViewCount  { get; set; }  // named views before export
    public static string ExportedFilePath  { get; set; } = "";
    public static bool   ExportFileExists  { get; set; }
    public static int    ExportedViewCount { get; set; }  // records in exported JSON
    public static int    ViewCountAfterImport { get; set; } // should equal InitialViewCount (skip-existing)
}
