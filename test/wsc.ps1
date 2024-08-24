# $config_path = Join-Path $env:USERPROFILE ".config\scoop\config.json"

# if (!(Test-Path $config_path)) {
#   Write-Host "Please notice: $env:USERPROFILE\.config\scoop\config.json is available!" -ForegroundColor DarkYellow
#   return
# }

# $SCOOP_CONFIG_JSON = Get-Content -Path $config_path | ConvertFrom-Json

# $root_path = $SCOOP_CONFIG_JSON.root_path
# $global_root_path = $SCOOP_CONFIG_JSON.global_path

. "$PSScriptRoot\lib\config.ps1"


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
  $localAppsPath = Join-Path $root_path "apps"
  $globalAppsPath = Join-Path $global_path "apps"
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

  $searchResult = Get-ScoopBucketsFullPath $root_path | ForEach-Object {
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

Get-ScoopLocalApp -searchTarget "chrome"



function scoopSearch {
  param(
    [string]$searchTerm
  )
  $installedApps = Get-ScoopInstalledApps


  $searchResult = Get-ScoopBucketsFullPath $root_path | ForEach-Object {
    $bucketPath = $_
    $manifestFiles = Get-ChildItem -Path $bucketPath -Recurse -Include *$searchTerm*.json
    $manifestFiles | ForEach-Object -Parallel {
      $currentFile = $_
      $packageJson = Get-Content $currentFile.FullName -Raw | ConvertFrom-Json
      $appName = $currentFile.Name.Split(".")[0]
      $appVersion = $packageJson.version
      $appBucketName = (Split-Path $currentFile.Directory -Parent).Substring((Split-Path $currentFile.Directory -Parent).LastIndexOf("\") + 1)

      [PSCustomObject]@{
        Name      = $appName
        Version   = $appVersion
        Bucket    = $appBucketName
        Installed = $false
      }
    }
  }
  $searchResult | ForEach-Object {
    $app = $_
    $matchingApp = $installedApps | Where-Object {
      $_.Name -eq $app.Name -and $_.Bucket -eq $app.Bucket
    }
    if ($matchingApp) {
      $app.Installed = $true
    }
  }

  $searchResult = $searchResult | Sort-Object -Property Installed -Descending
  $selectedItems = $searchResult | ForEach-Object {
    $bucket = "`e[33m$($_.Bucket)`e[0m"  # 黄色
    $app = "`e[32m$($_.Name)`e[0m"        # 绿色
    $version = "`e[36m$($_.Version)`e[0m" # 青色
    $installed = if ($_.Installed) { "[installed]" } else { "" }
    "$bucket $app $version $installed"
  } | fzf.exe -q $searchTerm --ansi --border --height 100% --reverse --multi --preview "scoop info {2}"

  $selectedItems -split "`n" | ForEach-Object {
    $selectedAppName = ($_ -replace "`e\[\d+m", "").Split(" ")[1]

    $appIsInstalled = $installedApps | Where-Object { $_.Name -eq $selectedAppName }

    if ($appIsInstalled) {
      Write-Host "$selectedAppName installed..."
    }
    else {
      Write-Host "installing : $selectedAppName..."
      scoop install $selectedAppName
    }
  }
}




function searchRemote {
  param(
    [Parameter(Mandatory = $false, Position = 0)][string]$searchTerm,
    [Parameter(Mandatory = $false, Position = 1)][int]$searchCount = 30
  )
  $APP_URL = "https://scoopsearch.search.windows.net/indexes/apps/docs/search?api-version=2020-06-30";
  $APP_KEY = "DC6D2BBE65FC7313F2C52BBD2B0286ED";
  $request = [System.Net.WebRequest]::Create($APP_URL)

  $request.Method = "POST"
  $request.ContentType = "application/json"
  $request.Headers.Add("api-key", $APP_KEY)
  $request.Headers.Add("origin", "https://scoop.sh")

  $data = @{
    count            = $true
    searchMode       = "all"
    filter           = ""
    skip             = 0
    search           = $searchTerm
    top              = $searchCount
    orderby          = @(
      "search.score() desc",
      "Metadata/OfficialRepositoryNumber desc",
      "NameSortable asc"
    ) -join ","
    select           = @(
      "Id",
      "Name",
      "NamePartial",
      "NameSuffix",
      "Description",
      "Homepage",
      "License",
      "Version",
      "Metadata/Repository",
      "Metadata/FilePath",
      "Metadata/OfficialRepository",
      "Metadata/RepositoryStars",
      "Metadata/Committed",
      "Metadata/Sha"
    ) -join ","
    highlight        = @(
      "Name",
      "NamePartial",
      "NameSuffix",
      "Description",
      "Version",
      "License",
      "Metadata/Repository"
    ) -join ","
    highlightPreTag  = "<mark>"
    highlightPostTag = "</mark>"
  }


  $body = ConvertTo-Json $data


  $requestStream = $request.GetRequestStream()
  $writer = New-Object System.IO.StreamWriter($requestStream)
  $writer.Write($body)
  $writer.Flush()

  $response = $request.GetResponse()

  $stream = $response.GetResponseStream()
  $reader = New-Object System.IO.StreamReader($stream)
  $content = $reader.ReadToEnd()

  $object = ConvertFrom-Json $content

  $response.Close()

  return $object
}

function scoopAdd {
  param(
    [Parameter(Mandatory = $false, Position = 0)][Object]$addAPP,
    [Parameter(Mandatory = $false, Position = 1)][Object]$searchResult
  )
  $bucketPath = Join-Path $root_path "buckets" "remote"

  $remotePath = Join-Path $bucketPath "bucket"


  if (!(Test-Path $remotePath)) {
    Write-Host "Creating remote bucket...$remotePath" -ForegroundColor DarkYellow

    New-Item -ItemType Directory -Path $remotePath
  }


  $bucket = $addAPP.Split("/")[0]
  $app = $addAPP.Split("/")[1]

  $Repository = $searchResult.value.Metadata.Repository
  $FilePath = $searchResult.value.Metadata.FilePath

  $filteredBucket = $Repository | Where-Object {
    $RepositoryUrl = $_
    $remoteBucket = $RepositoryUrl.Substring($RepositoryUrl.LastIndexOf("/") + 1)
    $remoteBucket -eq $bucket
  } | Select-Object -First 1
  $filteredApp = $FilePath | Where-Object {
    $appPath = $_
    $remoteApp = $appPath.Substring($appPath.LastIndexOf("/") + 1).Split(".")[0]
    $remoteApp -eq $app
  } | Select-Object -First 1

  $remoteManifestFile = $filteredBucket.replace("github.com", "raw.githubusercontent.com") + "/master" + "/" + $filteredApp

  $outFile = Join-Path $bucketPath $filteredApp

  Write-Host "Remote app ManifestFile is downloading..." -ForegroundColor Cyan
  Write-Host "Url:" $remoteManifestFile -ForegroundColor Green

  Write-Host "Downloading...$outFile" -ForegroundColor Cyan


  Invoke-WebRequest -Uri $remoteManifestFile -OutFile $outFile

  if (Test-Path $outFile) {
    Write-Host "Remote app ManifestFile is add successful...`nType 'scoop install remote/$app' to install app" -ForegroundColor Magenta
  }
}

function scoopDir {
  param(
    [Parameter(Mandatory = $false, Position = 0)][string]$inputParam
  )
  if ($inputParam.Length -eq 0) {
    Start-Process $root_path
  }
  else {
    Start-Process $(scoop prefix $inputParam)
  }
}



$Global:searchResult = $null

function scoop {
  param(
    [Parameter(Mandatory = $false, Position = 0)][string]$Command,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Args
  )

  $shims = Join-Path $root_path "shims\scoop.ps1"


  switch ($Command) {
    "search" {
      # Call our custom search function instead
      if ($Args -eq $null) {
        Invoke-Expression "$shims search"
      }
      else {

        scoopSearch -searchTerm $Args
        # $Global:searchResult = searchRemote $Args
        # $searchResult.value | Format-Table @{Label = "Remote Repository"; Expression = { $_.Metadata.Repository + ".git" } }, @{Label = "App"; Expression = { $_.Name } }, Version -AutoSize
      }
    }
    "add" {
      # Add the remote package to local
      if ($null -ne $Global:searchResult) {
        scoopAdd $Args $Global:searchResult
      }
      else {
        Write-Host "Please execute 'scoop search' command first to get the remote package list." -ForegroundColor Magenta
      }

    }
    "dir" {
      scoopDir -inputParam $Args
    }
    "install" {
      foreach ($item in $Args) {
        $commandLine = "$shims $Command $item"
        Invoke-Expression $commandLine
      }
    }
    default {
      # Execute the Scoop command with the given arguments

      $commandLine = "$shims $Command $($Args -join ' ')"

      Invoke-Expression $commandLine
    }
  }
}
