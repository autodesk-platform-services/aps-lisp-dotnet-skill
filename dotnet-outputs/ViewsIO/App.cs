using System.Runtime.CompilerServices;
using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(ViewsIO.App))]
[assembly: CommandClass(typeof(ViewsIO.Commands))]
[assembly: InternalsVisibleTo("ViewsIO.IntegrationTests")]

namespace ViewsIO;

public class App : IExtensionApplication
{
    public void Initialize() =>
        Autodesk.AutoCAD.ApplicationServices.Application
            .DocumentManager.MdiActiveDocument?
            .Editor.WriteMessage(
                "\nViewsIO loaded. Commands: EXPORTVIEWS, IMPORTVIEWS, -EXPORTVIEWS, -IMPORTVIEWS\n");

    public void Terminate() { }
}
