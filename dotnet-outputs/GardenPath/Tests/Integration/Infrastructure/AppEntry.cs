using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(GardenPath.IntegrationTests.Infrastructure.AppEntry))]
[assembly: CommandClass(typeof(GardenPath.IntegrationTests.Infrastructure.RunTestsCommand))]
[assembly: CommandClass(typeof(GardenPath.IntegrationTests.Infrastructure.TestSetupCommands))]

namespace GardenPath.IntegrationTests.Infrastructure;

public class AppEntry : IExtensionApplication
{
    public void Initialize() { }
    public void Terminate() { }
}
