# APS-Common.ps1 - Shared helpers for APS Design Automation scripts
# Dot-source this file: . .\APS-Common.ps1
# Fully generic across engines/bundles — no per-migration edits needed.

Add-Type -AssemblyName System.Net.Http

$DA_BASE  = "https://developer.api.autodesk.com/da/us-east/v3"
$OSS_BASE = "https://developer.api.autodesk.com/oss/v2"
$AUTH_URL = "https://developer.api.autodesk.com/authentication/v2/token"

# Load .env (copied from .env.example, gitignored) into the process environment,
# if present, before anything else reads $env:APS_*. Real credentials never pass
# through Claude — the developer fills in .env themselves on their own machine.
function Import-DotEnv {
    param([string] $Path = "$PSScriptRoot\.env")
    if (-not (Test-Path $Path)) { return }
    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $parts = $line.Split("=", 2)
        if ($parts.Count -eq 2 -and $parts[1].Trim() -ne "") {
            [Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim(), "Process")
        }
    }
}
Import-DotEnv

# Auth

function Get-APSToken {
    $id     = if ($env:APS_CLIENT_ID)     { $env:APS_CLIENT_ID }     else { Read-Host "APS Client ID" }
    $secret = if ($env:APS_CLIENT_SECRET) { $env:APS_CLIENT_SECRET } else { Read-Host "APS Client Secret" }
    $env:APS_CLIENT_ID     = $id
    $env:APS_CLIENT_SECRET = $secret

    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("${id}:${secret}"))
    $r = Invoke-RestMethod -Uri $AUTH_URL -Method POST `
        -Headers @{ Authorization = "Basic $b64" } `
        -ContentType "application/x-www-form-urlencoded" `
        -Body "grant_type=client_credentials&scope=code%3Aall%20data%3Aread%20data%3Awrite%20bucket%3Acreate%20bucket%3Aread%20bucket%3Aupdate"
    return $r.access_token
}

function Get-DANickname($token) {
    $r = Invoke-RestMethod -Uri "$DA_BASE/forgeapps/me" -Method GET `
        -Headers @{ Authorization = "Bearer $token" }
    # Observed response shape is a bare JSON string ("<value>"), not { "id": "<value>" } as
    # the APS docs/earlier assumption suggested — Invoke-RestMethod then deserializes it to
    # a plain .NET string with no .id property. Every caller reading $result.id on that gets
    # $null silently (no error), which is the actual root cause of nicknames resolving empty.
    # Normalize here so every caller gets a consistent bare string either way.
    if ($r -is [string]) { return $r }
    return $r.id
}

function Set-DANickname($token, $nickname) {
    $body = @{ nickname = $nickname } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "$DA_BASE/forgeapps/me" -Method PATCH `
            -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
            -Body $body | Out-Null
        Write-Host "  Nickname set to '$nickname'" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  Nickname PATCH failed: $_" -ForegroundColor Yellow
        return $false
    }
}

# APS lets you set a forgeapps nickname exactly once — PATCHing it again once the app
# already owns bundles/activities fails with "already has resources", and everything
# downstream (bundle/activity/workitem qualification) must use whatever nickname is
# ACTUALLY registered, not whatever was typed at the prompt. Always call this instead
# of Set-DANickname directly; it only PATCHes when no nickname exists yet, and always
# returns the nickname callers should actually use.
function Resolve-DANickname($token, $requestedNickname) {
    $current = Get-DANickname $token
    # Get-DANickname always returns a bare string now — but when no custom nickname has
    # ever been registered, that string defaults to your raw APS_CLIENT_ID, not blank/null.
    # Comparing against $env:APS_CLIENT_ID (not just truthiness) is the only way to tell
    # "has a real nickname" apart from "still on the default identity".
    $hasRealNickname = $current -and ($current -ne $env:APS_CLIENT_ID)
    if ($hasRealNickname) {
        Write-Host "  Existing nickname: '$current'" -ForegroundColor Cyan
        if ($current -ne $requestedNickname) {
            Write-Host "  (requested '$requestedNickname' ignored — already registered)" -ForegroundColor Yellow
        }
        return $current
    }
    if (-not $requestedNickname) {
        throw "No forgeapps nickname is registered yet, and none was provided. Pass -Owner <nickname>."
    }
    $patched = Set-DANickname $token $requestedNickname
    if ($patched) {
        return $requestedNickname
    }
    # PATCH failed (e.g. "already has resources") — $current (fetched above, before the
    # PATCH attempt) is still accurate, since nothing changed. No need to re-GET: this is
    # the nickname/identity every downstream bundle/activity/workitem reference must use.
    Write-Host "  Nickname did not actually change — using registered identity '$current' instead of requested '$requestedNickname'." -ForegroundColor Yellow
    return $current
}

# DELETE /forgeapps/me — wipes EVERY bundle, activity, and the nickname itself for this
# client. Irreversible. Only call this from a script the user runs deliberately (e.g.
# Reset-APSApp.ps1), never as part of the normal deploy/test flow — it is the "start over
# from a clean slate" escape hatch when resource state has gotten confused across runs,
# not a routine step.
function Remove-DAAllResources($token) {
    Invoke-RestMethod -Uri "$DA_BASE/forgeapps/me" -Method DELETE `
        -Headers @{ Authorization = "Bearer $token" } | Out-Null
}

# DA helpers

function Invoke-DA($token, $method, $path, $body = $null) {
    $params = @{
        Uri     = "$DA_BASE/$path"
        Method  = $method
        Headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }
    }
    if ($body) { $params.Body = ($body | ConvertTo-Json -Depth 10) }
    try   { return Invoke-RestMethod @params }
    catch { throw "DA $method $path -> $($_.Exception.Response.StatusCode): $($_.ErrorDetails.Message)" }
}

# GET appbundles/activities responses are paginated — { data: [...], paginationToken: "..." }.
# A single Invoke-DA call only returns one page (observed: ~20 items), silently truncating
# the real list. Follow paginationToken until it's absent to get everything.
function Get-DAAllPages($token, $path) {
    $all = @()
    $page = $null
    do {
        $p = if ($page) { "$path`?page=$page" } else { $path }
        $r = Invoke-DA $token GET $p
        $all += $r.data
        $page = $r.paginationToken
    } while ($page)
    return $all
}

# AppBundle

function Zip-Bundle {
    param([string]$BundleDir, [string]$ZipPath)
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    # Archive the bundle folder itself (not its contents) so the zip expands to BundleName.bundle/
    Compress-Archive -Path $BundleDir -DestinationPath $ZipPath
    Write-Host "  Zipped: $ZipPath ($([math]::Round((Get-Item $ZipPath).Length/1KB)) KB)" -ForegroundColor Gray
}

function Register-AppBundle($token, $id, $engine, $description) {
    $body     = @{ id = $id; engine = $engine; description = $description }
    $bodyNoId = @{           engine = $engine; description = $description }
    try {
        $r = Invoke-DA $token POST "appbundles" $body
        Write-Host "  Created bundle '$id' (v$($r.version))" -ForegroundColor Green
        return $r
    } catch {
        if ($_ -match "409|Conflict|already exists") {
            $r = Invoke-DA $token POST "appbundles/$id/versions" $bodyNoId
            Write-Host "  Updated bundle '$id' (v$($r.version))" -ForegroundColor Yellow
            return $r
        }
        throw
    }
}

function Upload-BundleZip($uploadParams, [string]$zipPath) {
    $endpointUrl = $uploadParams.endpointURL
    $formData    = @{}
    $uploadParams.formData.psobject.properties | ForEach-Object { $formData[$_.Name] = $_.Value }

    $multipart = [System.Net.Http.MultipartFormDataContent]::new()
    foreach ($kv in $formData.GetEnumerator()) {
        $sc = [System.Net.Http.StringContent]::new($kv.Value)
        $sc.Headers.ContentDisposition = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
        $sc.Headers.ContentDisposition.Name = $kv.Name
        $multipart.Add($sc)
    }
    $fs = [System.IO.FileStream]::new($zipPath, [System.IO.FileMode]::Open)
    $fc = [System.Net.Http.StreamContent]::new($fs)
    $fc.Headers.ContentDisposition = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new("form-data")
    $fc.Headers.ContentDisposition.Name     = "file"
    $fc.Headers.ContentDisposition.FileName = [System.IO.Path]::GetFileName($zipPath)
    $fc.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/octet-stream")
    $multipart.Add($fc)

    $client   = [System.Net.Http.HttpClient]::new()
    $response = $client.PostAsync($endpointUrl, $multipart).Result
    $fs.Close()
    if (-not $response.IsSuccessStatusCode) {
        $body = $response.Content.ReadAsStringAsync().Result
        throw "Bundle upload failed: $($response.StatusCode) - $body"
    }
    Write-Host "  Uploaded bundle to AWS" -ForegroundColor Green
}

function Set-BundleAlias($token, $bundleId, $alias, $version) {
    $body = @{ id = $alias; version = $version }
    try {
        Invoke-DA $token POST "appbundles/$bundleId/aliases" $body | Out-Null
        Write-Host "  Alias '$alias' -> v$version" -ForegroundColor Green
    } catch {
        if ($_ -match "409|Conflict|already exists") {
            Invoke-DA $token PATCH "appbundles/$bundleId/aliases/$alias" @{ version = $version } | Out-Null
            Write-Host "  Alias '$alias' updated -> v$version" -ForegroundColor Yellow
        } else { throw }
    }
}

function Deploy-Bundle($token, $id, $engine, $description, $bundleDir, $zipPath) {
    Write-Host "`n-- $id --" -ForegroundColor Cyan
    Write-Host "  [1/4] Zipping..."
    Zip-Bundle $bundleDir $zipPath
    Write-Host "  [2/4] Registering with DA..."
    $r = Register-AppBundle $token $id $engine $description
    Write-Host "  [3/4] Uploading zip to AWS..."
    Upload-BundleZip $r.uploadParameters $zipPath
    Write-Host "  [4/4] Setting alias 'dev'..."
    Set-BundleAlias $token $id "dev" $r.version
}

# Activity

function Deploy-Activity($token, $activityDef) {
    $id = $activityDef.id
    $defNoId = @{}
    $activityDef.GetEnumerator() | Where-Object { $_.Key -ne "id" } | ForEach-Object { $defNoId[$_.Key] = $_.Value }
    try {
        $r = Invoke-DA $token POST "activities" $activityDef
        Write-Host "  Created activity '$id' (v$($r.version))" -ForegroundColor Green
        return $r
    } catch {
        if ($_ -match "409|Conflict|already exists") {
            $r = Invoke-DA $token POST "activities/$id/versions" $defNoId
            Write-Host "  Updated activity '$id' (v$($r.version))" -ForegroundColor Yellow
            return $r
        }
        throw
    }
}

function Set-ActivityAlias($token, $activityId, $alias, $version) {
    $body = @{ id = $alias; version = $version }
    try {
        Invoke-DA $token POST "activities/$activityId/aliases" $body | Out-Null
        Write-Host "  Alias '$alias' -> v$version" -ForegroundColor Green
    } catch {
        if ($_ -match "409|Conflict|already exists") {
            Invoke-DA $token PATCH "activities/$activityId/aliases/$alias" @{ version = $version } | Out-Null
            Write-Host "  Alias '$alias' updated -> v$version" -ForegroundColor Yellow
        } else { throw }
    }
}

# OSS

function Ensure-OSSBucket($token, $bucketKey) {
    try {
        Invoke-RestMethod -Uri "$OSS_BASE/buckets/$bucketKey/details" -Method GET `
            -Headers @{ Authorization = "Bearer $token" } | Out-Null
        Write-Host "  Bucket '$bucketKey' exists" -ForegroundColor Gray
    } catch {
        $body = @{ bucketKey = $bucketKey; policyKey = "persistent" } | ConvertTo-Json
        Invoke-RestMethod -Uri "$OSS_BASE/buckets" -Method POST `
            -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
            -Body $body | Out-Null
        Write-Host "  Bucket '$bucketKey' created" -ForegroundColor Green
    }
}

function Upload-ToOSS($token, $bucketKey, $objectKey, $filePath) {
    $fileSize   = (Get-Item $filePath).Length
    $encodedKey = [Uri]::EscapeDataString($objectKey)

    $step1 = Invoke-RestMethod `
        -Uri "$OSS_BASE/buckets/$bucketKey/objects/$encodedKey/signeds3upload?minutesExpiration=60&useAcceleration=true&parts=1" `
        -Method GET `
        -Headers @{ Authorization = "Bearer $token" }

    $s3Url     = $step1.urls[0]
    $uploadKey = $step1.uploadKey

    $fs = [System.IO.FileStream]::new($filePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    try {
        $client  = [System.Net.Http.HttpClient]::new()
        $content = [System.Net.Http.StreamContent]::new($fs)
        $content.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse("application/octet-stream")
        $resp = $client.PutAsync($s3Url, $content).Result
        if (-not $resp.IsSuccessStatusCode) {
            $body = $resp.Content.ReadAsStringAsync().Result
            throw "S3 PUT failed: $($resp.StatusCode) - $body"
        }
    } finally {
        $fs.Close()
    }

    $r = Invoke-RestMethod `
        -Uri "$OSS_BASE/buckets/$bucketKey/objects/$encodedKey/signeds3upload" `
        -Method POST `
        -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
        -Body (@{ uploadKey = $uploadKey } | ConvertTo-Json)

    $sizeDisplay = if ($fileSize -lt 1KB) { "$fileSize B" } else { "$([math]::Round($fileSize/1KB, 1)) KB" }
    Write-Host "  Uploaded '$objectKey' ($sizeDisplay)" -ForegroundColor Green
    return $r.objectId
}

function Get-OSSSignedUrl($token, $bucketKey, $objectKey, [ValidateSet("read","write")]$access) {
    $encodedKey = [Uri]::EscapeDataString($objectKey)
    $r = Invoke-RestMethod `
        -Uri "$OSS_BASE/buckets/$bucketKey/objects/$encodedKey/signed?access=$access&minutesExpiration=60" `
        -Method POST `
        -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
        -Body "{}"
    return $r.signedUrl
}

function Download-FromUrl($url, $destPath) {
    Invoke-WebRequest -Uri $url -OutFile $destPath -UseBasicParsing
    $downloadedSize = (Get-Item $destPath).Length
    $sizeDisplay = if ($downloadedSize -lt 1KB) { "$downloadedSize B" } else { "$([math]::Round($downloadedSize/1KB, 1)) KB" }
    Write-Host "  Downloaded -> $destPath ($sizeDisplay)" -ForegroundColor Green
}

# WorkItem

function Submit-WorkItem($token, $activityId, $alias, $arguments) {
    $body = @{
        activityId = "$activityId+$alias"
        arguments  = $arguments
    }
    $r = Invoke-DA $token POST "workitems" $body
    Write-Host "  WorkItem submitted: $($r.id)" -ForegroundColor Cyan
    return $r.id
}

function Wait-WorkItem($token, $workItemId, [int]$timeoutSec = 300) {
    $elapsed = 0
    do {
        Start-Sleep -Seconds 5
        $elapsed += 5
        $r = Invoke-DA $token GET "workitems/$workItemId"
        Write-Host "  [$elapsed s] Status: $($r.status)" -ForegroundColor Gray
    } while ($r.status -in @("pending","inprogress") -and $elapsed -lt $timeoutSec)

    if ($r.status -eq "success") {
        Write-Host "  WorkItem SUCCEEDED" -ForegroundColor Green
    } else {
        Write-Host "  WorkItem FAILED: $($r.status)" -ForegroundColor Red
        if ($r.reportUrl) { Write-Host "  Report: $($r.reportUrl)" -ForegroundColor Yellow }
    }

    # DA's own stats breakdown — queue/download/processing/upload phases, not just our poll
    # interval. Useful for understanding where time (and DA cloud-credit cost) actually went,
    # instead of hand-timing "start of script" to "file appeared."
    if ($r.stats) {
        $s = $r.stats
        try {
            $queued  = [datetime]$s.timeQueued
            $dlStart = [datetime]$s.timeDownloadStarted
            $ixStart = [datetime]$s.timeInstructionsStarted
            $ixEnd   = [datetime]$s.timeInstructionsEnded
            $ulEnd   = [datetime]$s.timeUploadEnded
            $finished= [datetime]$s.timeFinished
            Write-Host "  Stats: queued->download $([math]::Round(($dlStart-$queued).TotalSeconds,1))s | download->processing $([math]::Round(($ixStart-$dlStart).TotalSeconds,1))s | processing $([math]::Round(($ixEnd-$ixStart).TotalSeconds,1))s | upload $([math]::Round(($ulEnd-$ixEnd).TotalSeconds,1))s | total $([math]::Round(($finished-$queued).TotalSeconds,1))s" -ForegroundColor DarkGray
        } catch { }
        if ($s.bytesDownloaded -or $s.bytesUploaded) {
            Write-Host "  Data: downloaded $($s.bytesDownloaded) B, uploaded $($s.bytesUploaded) B" -ForegroundColor DarkGray
        }
    }
    return $r
}
