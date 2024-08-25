$config_path = Join-Path $env:USERPROFILE ".config\scoop\config.json"

if (!(Test-Path $config_path)) {
  Write-Host "Please notice: $env:USERPROFILE\.config\scoop\config.json is available!" -ForegroundColor DarkYellow
  return
}

$SCOOP_CONFIG_JSON = Get-Content -Path $config_path | ConvertFrom-Json

$Global:root_path = $SCOOP_CONFIG_JSON.root_path

$Global:global_path = $SCOOP_CONFIG_JSON.global_path

$Global:LocalApps = $null

$SOOP_LIB_PATH = Join-Path $(scoop prefix scoop) "lib"
. $(Join-Path $SOOP_LIB_PATH "core.ps1")
. $(Join-Path $SOOP_LIB_PATH "buckets.ps1")
. $(Join-Path $SOOP_LIB_PATH "manifest.ps1")
. $(Join-Path $SOOP_LIB_PATH "versions.ps1")

$TEMP_APP_LIST = "$env:USERPROFILE\.config\scoop\APP_LIST.json"


function Get-ScoopBucketsFullPath() {
  param(
    [string]$scoop_root
  )
  try {
    $bucketsPattern = Join-Path $scoop_root "\buckets\*\bucket"

    $bucketsDirs = Get-ChildItem -Path $bucketsPattern -Directory | Select-Object -ExpandProperty FullName

    return $bucketsDirs
  }
  catch {
    Write-Error "Failed to retrieve Scoop buckets. $_"
    return $null
  }
}

function Get-ScoopInstalledAppInfo {
  param (
    [string]$path
  )
  try {
    Get-ChildItem -Path $path -Directory | ForEach-Object {
      $appDir = $_.FullName
      $appName = $_.Name
      $manifestPath = Join-Path $appDir "current\manifest.json"
      $sourceJson = Join-Path $appDir "current\install.json"
      if (Test-Path $manifestPath) {
        $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
        $source = Get-Content -Path $sourceJson -Raw | ConvertFrom-Json
        [PSCustomObject]@{
          Name    = $appName
          Version = $manifest.version
          Source  = $source.bucket
        }
      }
    }
  }
  catch {
    Write-Error "Failed to retrieve Scoop app info. $_"
    return $null
  }
}

function Get-ScoopInstalledApps {
  $localAppsPath = Join-Path $Global:root_path "apps"
  $globalAppsPath = Join-Path $Global:global_path "apps"
  $localApps = Get-ScoopInstalledAppInfo -path $localAppsPath
  $globalApps = Get-ScoopInstalledAppInfo -path $globalAppsPath
  $apps = @($localApps) + @($globalApps)
  return $apps
}

function Get-DynamicThrottleLimit {
  param(
    [int]$MemoryPerThreadMB = 256
  )

  $memoryStatus = Get-CimInstance -ClassName Win32_OperatingSystem
  $availableMemoryMB = [math]::Round($memoryStatus.FreePhysicalMemory / 1024)
  $maxThreads = [math]::Floor($availableMemoryMB / $MemoryPerThreadMB)

  if ($maxThreads -lt 1) {
    $maxThreads = 1
  }

  return $maxThreads
}

function Get-ScoopLocalApp {
  param(
    [string]$searchTarget
  )
  $installedApps = Get-ScoopInstalledApps

  $searchResult = Get-ScoopBucketsFullPath $Global:root_path | ForEach-Object {
    $bucketPath = $_
    $manifestFiles = if ([string]::IsNullOrEmpty($searchTarget)) {
      Get-ChildItem -Path $bucketPath -Recurse -Filter *.json
    }
    else {
      Get-ChildItem -Path $bucketPath -Recurse -Include *$searchTarget*.json
    }

    $ThrottleCount = Get-DynamicThrottleLimit
    $manifestFiles | ForEach-Object -Parallel {
      $currentFile = $_
      try {
        $packageJson = Get-Content $currentFile.FullName -Raw | ConvertFrom-Json
        $appName = $currentFile.Name.Split(".")[0]
        $appVersion = $packageJson.version
        $appBucketName = (Split-Path $currentFile.Directory -Parent).Substring((Split-Path $currentFile.Directory -Parent).LastIndexOf("\") + 1)

        [PSCustomObject]@{
          Name      = $appName
          Version   = $appVersion
          Source    = $appBucketName
          Installed = $false
        }
      }
      catch {
        Write-Error "Error processing $($currentFile.FullName): $_"
      }
    }  -ThrottleLimit $ThrottleCount
  }

  $searchResult | ForEach-Object {
    $app = $_
    $matchingApp = $installedApps | Where-Object {
      $_.Name -eq $app.Name -and $_.Source -eq $app.Source
    }
    if ($matchingApp) {
      $app.Installed = $true
    }
  }
  return $searchResult #| Sort-Object -Property Installed -Descending
}

function CheckScoopStatus {

  $currentdir = versiondir 'scoop' 'current'
  $needs_update = $false
  $bucket_needs_update = $false
  $script:network_failure = $false
  $no_remotes = $args[0] -eq '-l' -or $args[0] -eq '--local'
  if (!(Get-Command git -ErrorAction SilentlyContinue)) { $no_remotes = $true }


  function Test-UpdateStatus($repopath) {
    if (Test-Path "$repopath\.git") {
      Invoke-Git -Path $repopath -ArgumentList @('fetch', '-q', 'origin')
      $script:network_failure = 128 -eq $LASTEXITCODE
      $branch = Invoke-Git -Path $repopath -ArgumentList @('branch', '--show-current')
      $commits = Invoke-Git -Path $repopath -ArgumentList @('log', "HEAD..origin/$branch", '--oneline')
      if ($commits) { return $true }
      else { return $false }
    }
    else {
      return $true
    }
  }

  if (!$no_remotes) {
    $needs_update = Test-UpdateStatus $currentdir
    foreach ($bucket in Get-LocalBucket) {
      if (Test-UpdateStatus (Find-BucketDirectory $bucket -Root)) {
        $bucket_needs_update = $true
        break
      }
    }
  }

  if ($needs_update) {
    Write-Host "`nScoop out of date. Run 'wsc su' to get the latest changes." -ForegroundColor DarkYellow
    Remove-Item $TEMP_APP_LIST -Force -ErrorAction SilentlyContinue
    exit
  }
  elseif ($bucket_needs_update) {
    Write-Host "`nScoop bucket(s) out of date. Run 'wsc su' to get the latest changes." -ForegroundColor DarkYellow
    Remove-Item $TEMP_APP_LIST -Force -ErrorAction SilentlyContinue
    exit
  }
  elseif (!$script:network_failure -and !$no_remotes) {
    break
  }

}

CheckScoopStatus