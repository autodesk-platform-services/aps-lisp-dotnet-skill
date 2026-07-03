using AventStack.ExtentReports;
using AventStack.ExtentReports.Reporter;

namespace GardenPath.IntegrationTests.Infrastructure;

// Singleton HTML reporter. RunTestsCommand calls Flush() after AutoRun finishes.
// DrawingTestBase.AfterEach() calls CreateTest() per test using TestContext.
public static class TestReport
{
    private static readonly ExtentReports _extent;
    public  static readonly string        HtmlPath;

    static TestReport()
    {
        var outDir = Path.GetDirectoryName(typeof(TestReport).Assembly.Location)!;
        HtmlPath   = Path.Combine(outDir, "TestReport.html");

        var spark = new ExtentSparkReporter(HtmlPath)
        {
            Config = { DocumentTitle = "GardenPath Integration Tests", ReportName = "GardenPath" }
        };
        _extent = new ExtentReports();
        _extent.AttachReporter(spark);
    }

    public static ExtentTest CreateTest(string name) => _extent.CreateTest(name);

    public static void Flush() => _extent.Flush();
}
