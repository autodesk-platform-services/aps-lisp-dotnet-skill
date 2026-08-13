using System.Runtime.CompilerServices;
using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(FlangeDA.App))]
[assembly: CommandClass(typeof(FlangeDA.Commands))]
[assembly: InternalsVisibleTo("FlangeDA.IntegrationTests")]
[assembly: InternalsVisibleTo("FlangeDA.Tests")]

namespace FlangeDA;

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
            .Editor.WriteMessage("\nFlangeDA loaded.\n");

    public void Terminate() { }
}
