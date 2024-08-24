$config_path = Join-Path $env:USERPROFILE ".config\scoop\config.json"

if (!(Test-Path $config_path)) {
  Write-Host "Please notice: $env:USERPROFILE\.config\scoop\config.json is available!" -ForegroundColor DarkYellow
  return
}

$SCOOP_CONFIG_JSON = Get-Content -Path $config_path | ConvertFrom-Json

$Global:root_path = $SCOOP_CONFIG_JSON.root_path

$Global:global_path = $SCOOP_CONFIG_JSON.global_path

$Global:LocalApps = $null