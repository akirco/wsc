. "$PSScriptRoot\..\lib\scoop.ps1"
$TEMP_APP_LIST = "$env:USERPROFILE\.config\scoop\APP_LIST.json"

scoop.ps1 update *

Get-ScoopLocalApp | ConvertTo-Json | Out-File $TEMP_APP_LIST