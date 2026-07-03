using System.Runtime.CompilerServices;
using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(MyPlugin.App))]
[assembly: CommandClass(typeof(MyPlugin.Commands))]
[assembly: InternalsVisibleTo("MyPlugin.IntegrationTests")]

namespace MyPlugin;

public class App : IExtensionApplication
{
    public void Initialize() =>
        Autodesk.AutoCAD.ApplicationServices.Application
            .DocumentManager.MdiActiveDocument?
            .Editor.WriteMessage("\nMyPlugin loaded.\n");

    public void Terminate() { }
}
