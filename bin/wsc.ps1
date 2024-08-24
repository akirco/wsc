Set-StrictMode -Off

$subCommand = $Args[0]

function command_path {
  param (
    [string]$cmd
  )
  "$PSScriptRoot\..\commands\$cmd.ps1"
}

function exec($cmd, $arguments) {
  $cmd_path = command_path $cmd
  & $cmd_path @arguments
}

function commands {
  $(Get-ChildItem ".\commands").BaseName
}
function Show-VersionInfo {
  Write-Host "v0.1" -f DarkBlue
}


switch ($subCommand) {

    ({ $subCommand -in @($null, '-h', '--help', 'help', '/?') }) {
    exec 'help'
  }
    ({ $subCommand -in @('-v', '--version') }) {
    Show-VersionInfo
  }
    ({ $subCommand -in (commands) }) {
    [string[]]$arguments = $Args | Select-Object -Skip 1
    if ($null -ne $arguments -and $arguments[0] -in @('-h', '--help', '/?')) {
      exec 'help' @($subCommand)
    }
    else {
      exec $subCommand $arguments
    }
  }
  default {
    Write-Host "Command '$subCommand' is not recognized. See 'help'." -f darkyellow
    exit 1
  }
}
