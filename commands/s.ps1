. "$PSScriptRoot\..\lib\helper.ps1"

$scipt = "$PSScriptRoot\..\lib\scoop.ps1"
$TEMP_APP_LIST = "$env:USERPROFILE\.config\scoop\APP_LIST.json"


if (-not ($args -contains '-s' -or $args -contains '--skip')) {
  Loading -script $scipt -Label "Checking scoop status..."
}

if (Test-Path $TEMP_APP_LIST) {
  $app_list = Get-Content $TEMP_APP_LIST | ConvertFrom-Json
  $selectedItems = $app_list | ForEach-Object {
    $bucket = "`e[33m$($_.Source)`e[0m"   # 黄色
    $app = "`e[32m$($_.Name)`e[0m"        # 绿色
    $version = "`e[36m$($_.Version)`e[0m" # 青色
    $installed = if ($_.Installed) { "[installed]" } else { "" }
    "$bucket $app $version $installed"
  } | fzf.exe --ansi --height 100% --reverse --multi --pointer='▓' --prompt='~' --border=sharp  --preview "scoop info {2}"

  $selectedItems -split "`n" | ForEach-Object {
    $selectedBucket = ($_ -replace "`e\[\d+m", "").Split(" ")[0]
    $selectedAppName = ($_ -replace "`e\[\d+m", "").Split(" ")[1]
    scoop install "$selectedBucket/$selectedAppName"
  }
}


