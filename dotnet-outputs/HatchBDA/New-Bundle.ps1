#Requires -Version 7
# Creates the HatchBDA.bundle folder structure per the Autodesk Autoloader spec.
# This is the same bundle folder Deploy-And-Test-DA.ps1 (in da/) zips and uploads
# as the APS AppBundle — running this script is a prerequisite for DA deployment,
# not a separate desktop-only step.
#   HatchBDA.bundle/
#     PackageContents.xml
#     Contents/Win64/
#       HatchBDA.dll
#       HatchBDA.pdb
#
# Usage:
#   ./New-Bundle.ps1
#   ./New-Bundle.ps1 -Config Release -Deploy   # also local desktop sanity-check load
param(
    [string] $Config     = "Debug",
    [string] $Tfm        = "net10.0-windows",
    [string] $BundleRoot = "$PSScriptRoot\HatchBDA.bundle",
    [switch] $Deploy     # copy bundle to %APPDATA%\Autodesk\ApplicationPlugins for a
                         # local NETLOAD sanity check — confirms the assembly loads and
                         # runs cleanly before submitting a real DA WorkItem; not itself
                         # the DA deployment path (see da/Deploy-And-Test-DA.ps1)
)

$ErrorActionPreference = "Stop"

$projectDir  = $PSScriptRoot
$csproj      = Join-Path $projectDir "HatchBDA.csproj"
$binDir      = Join-Path $projectDir "bin\$Config\$Tfm"
$contentsDir = Join-Path $BundleRoot "Contents\Win64"
$pkgXml      = Join-Path $projectDir "PackageContents.xml"

# --- Validate ---
if (-not (Test-Path $csproj))  { Write-Error "Project not found: $csproj";        exit 1 }
if (-not (Test-Path $pkgXml))  { Write-Error "PackageContents.xml not found: $pkgXml"; exit 1 }

# --- Build ---
Write-Host "Building $Config / $Tfm ..."
dotnet build $csproj -c $Config -f $Tfm --nologo -v q
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$dll = Join-Path $binDir "HatchBDA.dll"
if (-not (Test-Path $dll)) { Write-Error "DLL not found after build: $dll"; exit 1 }

# --- Create bundle structure ---
Write-Host "Creating bundle: $BundleRoot"
New-Item -ItemType Directory -Force $contentsDir | Out-Null

# PackageContents.xml at bundle root
Copy-Item $pkgXml (Join-Path $BundleRoot "PackageContents.xml") -Force

# Plugin DLL + PDB into Contents\Win64\
Copy-Item $dll (Join-Path $contentsDir "HatchBDA.dll") -Force
$pdb = Join-Path $binDir "HatchBDA.pdb"
if (Test-Path $pdb) { Copy-Item $pdb (Join-Path $contentsDir "HatchBDA.pdb") -Force }

Write-Host "Bundle ready: $BundleRoot"
Write-Host "Contents:"
Get-ChildItem $BundleRoot -Recurse | ForEach-Object {
    "  $($_.FullName.Replace($BundleRoot, '.'))"
}

# --- Optional: deploy to ApplicationPlugins ---
if ($Deploy) {
    $appPlugins = Join-Path $env:APPDATA "Autodesk\ApplicationPlugins"
    $dest       = Join-Path $appPlugins "HatchBDA.bundle"
    New-Item -ItemType Directory -Force $appPlugins | Out-Null
    if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
    Copy-Item $BundleRoot $dest -Recurse -Force
    Write-Host ""
    Write-Host "Deployed to: $dest"
    Write-Host "Restart AutoCAD to load the plugin."
}
