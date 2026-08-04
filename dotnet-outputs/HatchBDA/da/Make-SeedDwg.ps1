#Requires -Version 7
# Builds a seed .dwg with a single 10x5 rectangular HATCH entity, for feeding into
# Deploy-And-Test-DA.ps1 -InputDwg. Uses accoreconsole's default blank drawing (no
# starting .dwg needed) + the dev-only HBSEED command in Commands.cs — no AutoCAD
# desktop session required.
#
# Usage:
#   ./Make-SeedDwg.ps1
#   ./Make-SeedDwg.ps1 -Accore "C:\Program Files\Autodesk\AutoCAD 2027\accoreconsole.exe"
param(
    [string] $Accore  = "C:\Program Files\Autodesk\AutoCAD 2027\accoreconsole.exe",
    [string] $Config  = "Debug",
    [string] $Tfm      = "net10.0-windows",
    [string] $OutDwg  = "$PSScriptRoot\seed.dwg"
)

$ErrorActionPreference = "Stop"

$pluginDll = "$PSScriptRoot\..\bin\$Config\$Tfm\HatchBDA.dll"
$scr       = "$PSScriptRoot\Make-SeedDwg_generated.scr"

if (-not (Test-Path $Accore))   { Write-Error "accoreconsole not found: $Accore"; exit 1 }
if (-not (Test-Path $pluginDll)) { Write-Error "Plugin DLL not found: $pluginDll — run 'dotnet build' in the project root first."; exit 1 }
if (Test-Path $OutDwg) { Remove-Item $OutDwg }

# FILEDIA 0 -> QSAVE on a never-before-saved drawing prompts for a filename on the
# command line instead of popping a (nonexistent, in headless mode) Save dialog.
Set-Content -Path $scr -Encoding UTF8 -Value @"
FILEDIA
0
SECURELOAD
0
NETLOAD
$pluginDll
HBSEED
QSAVE
$OutDwg
QUIT
Y
"@

Write-Host "Running: $Accore /product ACAD /s $scr"
& $Accore /product ACAD /s $scr

if (Test-Path $OutDwg) {
    Write-Host "`nSeed drawing created: $OutDwg" -ForegroundColor Green
    Write-Host "Feed it to the real DA test with:"
    Write-Host "  .\Deploy-And-Test-DA.ps1 -InputDwg `"$OutDwg`""
} else {
    Write-Error "seed.dwg was not created — check accoreconsole output above."
    exit 1
}
