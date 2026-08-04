using System.Runtime.CompilerServices;
using Autodesk.AutoCAD.Runtime;

[assembly: ExtensionApplication(typeof(HatchBDA.App))]
[assembly: CommandClass(typeof(HatchBDA.Commands))]
[assembly: InternalsVisibleTo("HatchBDA.IntegrationTests")]

namespace HatchBDA;

public class App : IExtensionApplication
{
    // TODO: verify — corrected from the template default. In AutoCAD.NET.Core
    // (AcCoreMgd.dll only, no AcMgd.dll desktop layer), Application lives in
    // Autodesk.AutoCAD.ApplicationServices.Core, not Autodesk.AutoCAD.ApplicationServices —
    // the bare "ApplicationServices.Application" the scaffold stub used does not exist in
    // this package and fails CS0234. Confirmed against AcCoreMgd.xml for this SDK version.
    public void Initialize() =>
        Autodesk.AutoCAD.ApplicationServices.Core.Application
            .DocumentManager.MdiActiveDocument?
            .Editor.WriteMessage("\nHatchBDA loaded.\n");

    public void Terminate() { }
}
