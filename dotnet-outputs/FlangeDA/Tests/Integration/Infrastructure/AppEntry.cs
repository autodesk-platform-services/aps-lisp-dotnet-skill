using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(FlangeDA.IntegrationTests.Infrastructure.AppEntry))]
[assembly: CommandClass(typeof(FlangeDA.IntegrationTests.Infrastructure.RunTestsCommand))]
[assembly: CommandClass(typeof(FlangeDA.IntegrationTests.Infrastructure.TestSetupCommands))]

namespace FlangeDA.IntegrationTests.Infrastructure;

public class AppEntry : IExtensionApplication
{
    public void Initialize() { }
    public void Terminate() { }
}
