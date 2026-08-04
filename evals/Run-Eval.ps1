#Requires -Version 7
<#
.SYNOPSIS
  Manual-eval harness for the lisp-to-dotnet skill. Run this AFTER you've had
  Claude migrate one of evals/files/*.lsp in a normal interactive session —
  this script only verifies the resulting artifacts on disk against the
  assertions recorded in evals.json. It does not invoke Claude or the Skill
  tool itself.

.PARAMETER EvalId
  1 = gpmain.lsp, 2 = HATCHB.lsp, 3 = mstxt.lsp (DCL refusal — no ProjectDir expected)

.PARAMETER ProjectDir
  Root of the generated project (folder containing the main .csproj). Omit
  for EvalId 3 — the pass condition there is that no project was scaffolded.

.PARAMETER ReportPath
  Where to write the JSON report. Defaults to evals/results/eval-<id>-report.json

.EXAMPLE
  ./Run-Eval.ps1 -EvalId 1 -ProjectDir D:\ToDelete\eval-run\GardenPathDA
.EXAMPLE
  ./Run-Eval.ps1 -EvalId 3
#>
param(
    [Parameter(Mandatory)][ValidateSet(1, 2, 3)][int] $EvalId,
    [string] $ProjectDir,
    [string] $ReportPath,
    [switch] $SkipBuild,
    [switch] $SkipTests
)

$ErrorActionPreference = "Stop"

if (-not $ReportPath) {
    $resultsDir = Join-Path $PSScriptRoot "results"
    New-Item -ItemType Directory -Force -Path $resultsDir | Out-Null
    $ReportPath = Join-Path $resultsDir "eval-$EvalId-report.json"
}

function New-Check {
    param([string] $Name, [bool] $Passed, [string] $Evidence, [bool] $ManualReview = $false)
    [PSCustomObject]@{ Name = $Name; Passed = $Passed; Evidence = $Evidence; ManualReview = $ManualReview }
}

function Get-CsFiles {
    param([string] $Root)
    if (-not (Test-Path $Root)) { return @() }
    Get-ChildItem -Path $Root -Recurse -Filter *.cs -File | Where-Object { $_.FullName -notmatch '\\(bin|obj)\\' }
}

function Get-CsProjFiles {
    param([string] $Root)
    if (-not (Test-Path $Root)) { return @() }
    Get-ChildItem -Path $Root -Recurse -Filter *.csproj -File
}

$checks = @()

# ---------------------------------------------------------------------------
# EvalId 3: DCL refusal — the only filesystem-checkable artifact is that NO
# project was scaffolded. Wording of the refusal itself is conversational
# and must be eyeballed — flagged ManualReview below.
# ---------------------------------------------------------------------------
if ($EvalId -eq 3) {
    $noScaffold = -not $ProjectDir -or -not (Test-Path $ProjectDir)
    $checks += New-Check "No project scaffolded (mstxt.lsp has real DCL — dotnet new should never have been run)" `
        $noScaffold `
        $(if ($noScaffold) { "No ProjectDir given, or path does not exist." } else { "ProjectDir exists at $ProjectDir — scaffold should NOT have happened." })
    $checks += New-Check "Response identified load_dialog/new_dialog before generating code" `
        $false "MANUAL: re-read the transcript — confirm DCL was flagged before any code/scaffold step." $true
    $checks += New-Check "Response stated DCL is out-of-scope v1 and offered a path forward" `
        $false "MANUAL: re-read the transcript — confirm out-of-scope statement + path-forward offer (non-dialog code only, or wait for v2)." $true

    $report = [PSCustomObject]@{
        EvalId  = $EvalId
        Checks  = $checks
        Summary = @{
            Passed = ($checks | Where-Object { $_.Passed }).Count
            Total  = $checks.Count
            ManualReviewNeeded = ($checks | Where-Object { $_.ManualReview }).Count
        }
    }
    $report | ConvertTo-Json -Depth 6 | Out-File -Encoding utf8 $ReportPath
    $report.Checks | Format-Table Name, Passed, ManualReview -AutoSize
    Write-Host "`nReport written to $ReportPath" -ForegroundColor Cyan
    return
}

if (-not $ProjectDir -or -not (Test-Path $ProjectDir)) {
    Write-Error "ProjectDir is required and must exist for EvalId $EvalId."
    exit 1
}

$csFiles   = Get-CsFiles $ProjectDir
$csprojs   = Get-CsProjFiles $ProjectDir
$allCsText = $csFiles | Get-Content -Raw

# ---------------------------------------------------------------------------
# Common checks (both EvalId 1 and 2)
# ---------------------------------------------------------------------------

# No bare AutoCAD.NET package reference (only AutoCAD.NET.Core / AutoCAD.NET.Model allowed)
$bareRefs = $csprojs | ForEach-Object {
    Select-String -Path $_.FullName -Pattern 'Include="AutoCAD\.NET"'
}
$checks += New-Check "No bare AutoCAD.NET package reference (Core/Model only)" `
    ($bareRefs.Count -eq 0) `
    $(if ($bareRefs.Count -eq 0) { "$($csprojs.Count) .csproj file(s) checked, no bare AutoCAD.NET reference." } else { ($bareRefs | ForEach-Object { "$($_.Path):$($_.LineNumber)" }) -join "; " })

# No interactive input calls anywhere in generated C#
$interactivePattern = 'Editor\.Get(Point|Distance|String|Keyword|Angle|Corner|Entity)\s*\(|GetFileNameFor(Open|Save)|ShowDialog\s*\(|ShowAlertDialog'
$interactiveHits = $csFiles | Select-String -Pattern $interactivePattern
$checks += New-Check "No interactive ed.Get*/dialog calls in generated C#" `
    ($interactiveHits.Count -eq 0) `
    $(if ($interactiveHits.Count -eq 0) { "$($csFiles.Count) .cs file(s) checked, zero interactive calls." } else { ($interactiveHits | ForEach-Object { "$($_.Filename):$($_.LineNumber): $($_.Line.Trim())" }) -join " | " })

# A Models/*Input.cs record exists
$modelsInput = $csFiles | Where-Object { $_.FullName -match '\\Models\\.*Input\.cs$' }
$checks += New-Check "Models/*Input.cs record exists for parameterized input" `
    ($modelsInput.Count -gt 0) `
    $(if ($modelsInput.Count -gt 0) { ($modelsInput | ForEach-Object { $_.Name }) -join ", " } else { "No file matching Models\*Input.cs found." })

if ($EvalId -eq 2) {
    # All 5 vla-Add* mapped to typed entity creation
    $entityMap = @{
        'vla-AddLine → Line'                 = 'new\s+Line\s*\('
        'vla-AddCircle → Circle'              = 'new\s+Circle\s*\('
        'vla-AddArc → Arc'                    = 'new\s+Arc\s*\('
        'vla-AddEllipse → Ellipse'            = 'new\s+Ellipse\s*\('
        'vla-addLightweightPolyline → Polyline' = 'new\s+Polyline\s*\('
    }
    foreach ($label in $entityMap.Keys) {
        $hit = $csFiles | Select-String -Pattern $entityMap[$label] | Select-Object -First 1
        $checks += New-Check "$label typed creation present" ($null -ne $hit) `
            $(if ($hit) { "$($hit.Filename):$($hit.LineNumber): $($hit.Line.Trim())" } else { "No match for pattern $($entityMap[$label])" })
    }

    # pedit/ucs/undo command macros flagged as TODO, not silently translated
    $peditRaw = $csFiles | Select-String -Pattern '"\._?(pedit|ucs|UNDO)"' -CaseSensitive:$false
    $peditTodo = $csFiles | Select-String -Pattern '(?i)TODO.*(pedit|ucs|undo)'
    $checks += New-Check "pedit/ucs/UNDO sequences flagged as TODO, not silently translated to command macros" `
        ($peditTodo.Count -gt 0 -and $peditRaw.Count -eq 0) `
        "TODO mentions: $($peditTodo.Count) | raw command-macro string literals found: $($peditRaw.Count)" `
        $true

    # Area computation via typed try/catch, not raw COM
    $areaTry = $csFiles | Select-String -Pattern '(?s)catch[^}]*\{[^}]*Area'
    $rawComArea = $csFiles | Select-String -Pattern 'vlax|vl-catch-all'
    $checks += New-Check "Area computation uses typed try/catch, not raw COM/vlax" `
        ($rawComArea.Count -eq 0) `
        "vlax/vl-catch-all string leakage into C#: $($rawComArea.Count) (should be 0 — those are LISP-only identifiers)."
}

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
if (-not $SkipBuild) {
    Push-Location $ProjectDir
    try {
        $buildOut = & dotnet build 2>&1 | Out-String
        $buildOk = $LASTEXITCODE -eq 0
        $errMatch = [regex]::Match($buildOut, '(\d+)\s+Error\(s\)')
        $warnMatch = [regex]::Match($buildOut, '(\d+)\s+Warning\(s\)')
        $checks += New-Check "dotnet build succeeds with 0 errors" $buildOk `
            "Exit code $LASTEXITCODE. Errors: $($errMatch.Groups[1].Value), Warnings: $($warnMatch.Groups[1].Value)."
    } finally { Pop-Location }
} else {
    $checks += New-Check "dotnet build succeeds with 0 errors" $false "SKIPPED (-SkipBuild passed)." $true
}

# ---------------------------------------------------------------------------
# Tests (xUnit project(s) only — accoreconsole/NUnit integration run is manual,
# it needs a real AutoCAD install and is out of scope for this quick script)
# ---------------------------------------------------------------------------
if (-not $SkipTests) {
    $testProjects = $csprojs | Where-Object { (Get-Content $_.FullName -Raw) -match 'xunit' }
    if ($testProjects.Count -eq 0) {
        $checks += New-Check "xUnit tests pass" $false "No xUnit test project found under $ProjectDir." $true
    } else {
        foreach ($tp in $testProjects) {
            $testOut = & dotnet test $tp.FullName 2>&1 | Out-String
            $testOk = $LASTEXITCODE -eq 0
            $summary = ([regex]::Matches($testOut, 'Passed!\s*-\s*Failed:\s*(\d+),\s*Passed:\s*(\d+)') | Select-Object -Last 1)
            $checks += New-Check "xUnit tests pass ($($tp.Name))" $testOk `
                $(if ($summary.Success) { "Failed: $($summary.Groups[1].Value), Passed: $($summary.Groups[2].Value)" } else { "Exit code $LASTEXITCODE — see full output for detail." })
        }
    }
} else {
    $checks += New-Check "xUnit tests pass" $false "SKIPPED (-SkipTests passed)." $true
}

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
$report = [PSCustomObject]@{
    EvalId  = $EvalId
    ProjectDir = $ProjectDir
    Checks  = $checks
    Summary = @{
        Passed = ($checks | Where-Object { $_.Passed }).Count
        Total  = $checks.Count
        ManualReviewNeeded = ($checks | Where-Object { $_.ManualReview }).Count
    }
}
$report | ConvertTo-Json -Depth 6 | Out-File -Encoding utf8 $ReportPath
$report.Checks | Format-Table Name, Passed, ManualReview -AutoSize
Write-Host "`n$($report.Summary.Passed)/$($report.Summary.Total) passed, $($report.Summary.ManualReviewNeeded) need manual review." -ForegroundColor Cyan
Write-Host "Report written to $ReportPath" -ForegroundColor Cyan
