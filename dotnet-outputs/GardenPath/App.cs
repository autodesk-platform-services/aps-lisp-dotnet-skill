using System.Runtime.CompilerServices;
using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(GardenPath.App))]
[assembly: CommandClass(typeof(GardenPath.Commands))]
[assembly: InternalsVisibleTo("GardenPath.IntegrationTests")]

namespace GardenPath;

public class App : IExtensionApplication
{
    // (princ "\nType GPATH to draw a garden path.")
    public void Initialize() =>
        Autodesk.AutoCAD.ApplicationServices.Application
            .DocumentManager.MdiActiveDocument?
            .Editor.WriteMessage("\nType GPATH to draw a garden path.");

    public void Terminate() { }
}
