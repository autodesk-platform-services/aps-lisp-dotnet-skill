using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(ViewsIO.IntegrationTests.Infrastructure.AppEntry))]
[assembly: CommandClass(typeof(ViewsIO.IntegrationTests.Infrastructure.RunTestsCommand))]
[assembly: CommandClass(typeof(ViewsIO.IntegrationTests.Infrastructure.TestSetupCommands))]

namespace ViewsIO.IntegrationTests.Infrastructure;

public class AppEntry : IExtensionApplication
{
    public void Initialize() { }
    public void Terminate() { }
}
