using Autodesk.AutoCAD.Runtime;
using NUnitLite;

namespace GardenPath.IntegrationTests.Infrastructure;

public class RunTestsCommand
{
    [CommandMethod("RunCADtests", CommandFlags.Session)]
    public static void RunCADTests()
    {
        var dll    = typeof(RunTestsCommand).Assembly.Location;
        var outDir = Path.GetDirectoryName(dll)!;
        var xml    = Path.Combine(outDir, "TestResults.xml");

        string[] args = ["--trace=Off", $"--result={xml}"];
        new AutoRun(typeof(RunTestsCommand).Assembly).Execute(args);

        TestReport.Flush();
    }
}
