#Requires -Version 7
# Builds GardenPath.IntegrationTests and runs it in accoreconsole.
# All paths are explicit parameters — nothing is inferred at runtime.
#
# Usage:
#   ./RunIntegrationTests.ps1
#   ./RunIntegrationTests.ps1 -Config Release
#   ./RunIntegrationTests.ps1 -Accore "D:\ACAD\AutoCAD 2027\accoreconsole.exe" -OpenReport
param(
    [string] $Config     = "Debug",
    [string] $Accore     = "D:\ACAD\AutoCAD 2027\accoreconsole.exe",
    [string] $Tfm        = "net10.0-windows",
    [switch] $OpenReport          # open TestReport.html in VS Code after run
)

$ErrorActionPreference = "Stop"

# --- Resolved paths (no inference) ---
$scriptDir  = $PSScriptRoot
$csproj     = Join-Path $scriptDir "GardenPath.IntegrationTests.csproj"
$outDir     = Join-Path $scriptDir "bin\$Config\$Tfm"
$testDll    = Join-Path $outDir    "GardenPath.IntegrationTests.dll"
$xmlResult  = Join-Path $outDir    "TestResults.xml"
$htmlReport = Join-Path $outDir    "TestReport.html"
$scr        = Join-Path $scriptDir "RunCADtests_generated.scr"

# --- Validate prerequisites ---
if (-not (Test-Path $Accore)) { Write-Error "accoreconsole not found: $Accore"; exit 1 }
if (-not (Test-Path $csproj))  { Write-Error "Project not found: $csproj";      exit 1 }

# --- Build ---
Write-Host "Building $Config / $Tfm ..."
dotnet build $csproj -c $Config -f $Tfm --nologo -v q
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if (-not (Test-Path $testDll)) { Write-Error "DLL not found after build: $testDll"; exit 1 }

# --- Generate accoreconsole script ---
# GPathSetupTest runs in command context (document lock held) and writes test data.
# RunCADtests runs NUnit — tests only read from static TestData, no DB writes.
Set-Content -Path $scr -Encoding UTF8 -Value @"
SECURELOAD
0
NETLOAD
$testDll
GPathSetupTest
RunCADtests
QUIT
Y
"@

# --- Run ---
Write-Host "Running: $Accore /product ACAD /s $scr"
& $Accore /product ACAD /s $scr
$acoreExit = $LASTEXITCODE

# --- Parse and print NUnit XML summary ---
if (Test-Path $xmlResult) {
    [xml]$results = Get-Content $xmlResult
    $run = $results.'test-run'
    Write-Host ""
    Write-Host "===== NUnit Results ====="
    Write-Host "Result  : $($run.result)"
    Write-Host "Total   : $($run.total)   Passed: $($run.passed)   Failed: $($run.failed)   Duration: $($run.duration)s"
    $results.SelectNodes("//test-case") | ForEach-Object {
        $icon = if ($_.result -eq "Passed") { "PASS" } else { "FAIL" }
        Write-Host "  [$icon] $($_.name)"
        if ($_.result -ne "Passed") {
            Write-Host "         $($_.SelectSingleNode('failure/message').'#text')"
        }
    }
} else {
    Write-Warning "TestResults.xml not found — check accoreconsole output above."
}

# --- ExtentReports HTML ---
if (Test-Path $htmlReport) {
    Write-Host ""
    Write-Host "ExtentReport : $htmlReport"
    if ($OpenReport) {
        Start-Process $htmlReport
    } else {
        Write-Host "Run with -OpenReport to open it."
    }
}

if ((Test-Path $xmlResult) -and ($results.'test-run'.result -ne "Passed")) { exit 1 }
exit $acoreExit
