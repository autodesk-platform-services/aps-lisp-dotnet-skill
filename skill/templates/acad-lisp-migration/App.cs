using System.Runtime.CompilerServices;
using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(MyPlugin.App))]
[assembly: CommandClass(typeof(MyPlugin.Commands))]
[assembly: InternalsVisibleTo("MyPlugin.IntegrationTests")]

namespace MyPlugin;

public class App : IExtensionApplication
{
    // AutoCAD.NET.Core (AcCoreMgd.dll) does not carry the desktop
    // Autodesk.AutoCAD.ApplicationServices.Application type (that lives in the
    // AcMgd.dll desktop package this project never references — see the Design
    // Automation Guardrail in SKILL.md). The headless/DA equivalent is
    // Autodesk.AutoCAD.ApplicationServices.Core.Application.
    public void Initialize() =>
        Autodesk.AutoCAD.ApplicationServices.Core.Application
            .DocumentManager.MdiActiveDocument?
            .Editor.WriteMessage("\nMyPlugin loaded.\n");

    public void Terminate() { }
}
