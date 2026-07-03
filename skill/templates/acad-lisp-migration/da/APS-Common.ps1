# APS-Common.ps1 - Shared helpers for APS Design Automation scripts
# Dot-source this file: . .\APS-Common.ps1
# Fully generic across engines/bundles — no per-migration edits needed.

Add-Type -AssemblyName System.Net.Http

$DA_BASE  = "https://developer.api.autodesk.com/da/us-east/v3"
$OSS_BASE = "https://developer.api.autodesk.com/oss/v2"
$AUTH_URL = "https://developer.api.autodesk.com/authentication/v2/token"

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
    return $r
}

function Set-DANickname($token, $nickname) {
    $body = @{ nickname = $nickname } | ConvertTo-Json
    try {
        Invoke-RestMethod -Uri "$DA_BASE/forgeapps/me" -Method PATCH `
            -Headers @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" } `
            -Body $body | Out-Null
        Write-Host "  Nickname set to '$nickname'" -ForegroundColor Green
    } catch {
        Write-Host "  Nickname PATCH failed: $_" -ForegroundColor Yellow
    }
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

    Write-Host "  Uploaded '$objectKey' ($([math]::Round($fileSize/1KB)) KB)" -ForegroundColor Green
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
    Write-Host "  Downloaded -> $destPath ($([math]::Round((Get-Item $destPath).Length/1KB)) KB)" -ForegroundColor Green
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
    return $r
}
