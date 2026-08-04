using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(HatchBDA.IntegrationTests.Infrastructure.AppEntry))]
[assembly: CommandClass(typeof(HatchBDA.IntegrationTests.Infrastructure.RunTestsCommand))]
[assembly: CommandClass(typeof(HatchBDA.IntegrationTests.Infrastructure.TestSetupCommands))]

namespace HatchBDA.IntegrationTests.Infrastructure;

public class AppEntry : IExtensionApplication
{
    public void Initialize() { }
    public void Terminate() { }
}
