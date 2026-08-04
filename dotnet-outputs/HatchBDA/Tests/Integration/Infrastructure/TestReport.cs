using AventStack.ExtentReports;
using AventStack.ExtentReports.Reporter;

namespace HatchBDA.IntegrationTests.Infrastructure;

public static class TestReport
{
    private static readonly ExtentReports _extent;
    public  static readonly string        HtmlPath;

    static TestReport()
    {
        var outDir = Path.GetDirectoryName(typeof(TestReport).Assembly.Location)!;
        HtmlPath   = Path.Combine(outDir, "TestReport.html");
        var spark  = new ExtentSparkReporter(HtmlPath)
        {
            Config = { DocumentTitle = "HatchBDA Integration Tests" }
        };
        _extent = new ExtentReports();
        _extent.AttachReporter(spark);
    }

    public static ExtentTest CreateTest(string name) => _extent.CreateTest(name);
    public static void Flush() => _extent.Flush();
}
