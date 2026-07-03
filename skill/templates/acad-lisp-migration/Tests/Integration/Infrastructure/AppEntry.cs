using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(MyPlugin.IntegrationTests.Infrastructure.AppEntry))]
[assembly: CommandClass(typeof(MyPlugin.IntegrationTests.Infrastructure.RunTestsCommand))]
[assembly: CommandClass(typeof(MyPlugin.IntegrationTests.Infrastructure.TestSetupCommands))]

namespace MyPlugin.IntegrationTests.Infrastructure;

public class AppEntry : IExtensionApplication
{
    public void Initialize() { }
    public void Terminate() { }
}
