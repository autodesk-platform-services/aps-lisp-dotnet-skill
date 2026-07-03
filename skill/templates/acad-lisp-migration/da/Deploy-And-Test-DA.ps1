#Requires -Version 7
# Deploys the MyPlugin AppBundle + Activity to APS Design Automation, submits
# a test WorkItem against the parameterized DA entry point, and downloads the
# result. Requires $env:APS_CLIENT_ID / $env:APS_CLIENT_SECRET (or you'll be
# prompted). This script is generic — reads bundle/activity/parameter shape
# from da/activity.json and da/params.example.json, which are authored per
# migration (they contain the actual DA command name and parameter fields).
#
# Usage:
#   ./Deploy-And-Test-DA.ps1 -InputDwg path\to\seed.dwg
param(
    [string] $BundleDir   = "$PSScriptRoot\..\MyPlugin.bundle",
    [string] $ActivityDef = "$PSScriptRoot\activity.json",
    [string] $ParamsJson  = "$PSScriptRoot\params.example.json",
    [string] $InputDwg,
    [string] $Owner       = $env:APS_NICKNAME,
    [string] $Alias       = "dev",
    [string] $OutDir      = "$PSScriptRoot\workitem-results"
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\APS-Common.ps1"

if (-not $Owner)    { $Owner    = Read-Host "APS app nickname (forgeapps owner prefix)" }
if (-not $InputDwg) { Write-Error "Pass -InputDwg <seed drawing>."; exit 1 }
if (-not (Test-Path $ActivityDef)) { Write-Error "Activity definition not found: $ActivityDef"; exit 1 }
if (-not (Test-Path $BundleDir))   { Write-Error "Bundle not found: $BundleDir — run New-Bundle.ps1 first."; exit 1 }

$activity   = Get-Content $ActivityDef -Raw | ConvertFrom-Json
$bundleName = (Split-Path $BundleDir -Leaf) -replace '\.bundle$', ''
$zipPath    = "$PSScriptRoot\$bundleName.zip"

Write-Host "== APS Design Automation: deploy + test $bundleName ==" -ForegroundColor Cyan
$token = Get-APSToken
Set-DANickname $token $Owner

Write-Host "`n-- AppBundle --"
Deploy-Bundle $token $bundleName $activity.engine "Migrated via /lisp-to-dotnet" $BundleDir $zipPath

Write-Host "`n-- Activity --"
$activityBody = @{
    id          = $activity.id
    commandLine = $activity.commandLine
    parameters  = $activity.parameters
    settings    = $activity.settings
    engine      = $activity.engine
    appbundles  = @("$Owner.$bundleName+$Alias")
    description = $activity.description
}
$activityResult = Deploy-Activity $token $activityBody
Set-ActivityAlias $token $activity.id $Alias $activityResult.version

Write-Host "`n-- WorkItem --"
$bucketKey = "$($Owner.ToLower())-lisp-to-dotnet-test"
Ensure-OSSBucket $token $bucketKey

Upload-ToOSS $token $bucketKey "input.dwg" $InputDwg | Out-Null
$inputUrl = Get-OSSSignedUrl $token $bucketKey "input.dwg" "read"

$arguments = @{
    inputFile  = @{ url = $inputUrl }
    outputFile = @{ url = (Get-OSSSignedUrl $token $bucketKey "result.dwg" "write") }
}
if (Test-Path $ParamsJson) {
    Upload-ToOSS $token $bucketKey "params.json" $ParamsJson | Out-Null
    $arguments["params"] = @{ url = Get-OSSSignedUrl $token $bucketKey "params.json" "read" }
}

$workItemId = Submit-WorkItem $token $activity.id $Alias $arguments
$result     = Wait-WorkItem $token $workItemId

New-Item -ItemType Directory -Force $OutDir | Out-Null
if ($result.status -eq "success") {
    $downloadUrl = Get-OSSSignedUrl $token $bucketKey "result.dwg" "read"
    Download-FromUrl $downloadUrl "$OutDir\result.dwg"
    Write-Host "`nSUCCESS — result.dwg downloaded to $OutDir" -ForegroundColor Green
} else {
    Write-Host "`nFAILED — status: $($result.status)" -ForegroundColor Red
    if ($result.reportUrl) {
        Download-FromUrl $result.reportUrl "$OutDir\report.txt"
        Write-Host "`n--- Report ---"
        Get-Content "$OutDir\report.txt"
    }
    exit 1
}
