using Autodesk.AutoCAD.Runtime;
using NUnitLite;

namespace ViewsIO.IntegrationTests.Infrastructure;

public class RunTestsCommand
{
    [CommandMethod("RunCADtests", CommandFlags.Session)]
    public static void RunCADTests()
    {
        var outDir = Path.GetDirectoryName(typeof(RunTestsCommand).Assembly.Location)!;
        var xml    = Path.Combine(outDir, "TestResults.xml");
        string[] args = ["--trace=Off", $"--result={xml}"];
        new AutoRun(typeof(RunTestsCommand).Assembly).Execute(args);
        TestReport.Flush();
    }
}
