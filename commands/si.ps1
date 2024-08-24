. "$PSScriptRoot\..\lib\config.ps1"
. "$PSScriptRoot\..\lib\helper.ps1"

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

function GetScoopLocalApp {
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
  return $searchResult | Sort-Object -Property Installed -Descending
}


$functionScriptBlock = {

  $using:GetScoopLocalApp
}


$app_list = Loading -function $functionScriptBlock -Label "Searching..."


Write-Output $app_list



# $systeminfo | ForEach-Object {
#   $bucket = "`e[33m$($_.Source)`e[0m"  # 黄色
#   $app = "`e[32m$($_.Name)`e[0m"        # 绿色
#   $version = "`e[36m$($_.Version)`e[0m" # 青色
#   $installed = if ($_.Installed) { "[installed]" } else { "" }
#   "$bucket $app $version $installed"
# } | fzf.exe --ansi --border --height 100% --reverse --multi --preview "scoop info {2}"
