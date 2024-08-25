
function Write-Color {
  param (
    [string]$Text,
    [string]$ForegroundColor = "white", # 默认白色
    [string]$BackgroundColor = "",
    [switch]$Bold
  )

  # ANSI颜色代码映射
  $colorMap = @{
    "black"   = "30"
    "red"     = "31"
    "green"   = "32"
    "yellow"  = "33"
    "blue"    = "34"
    "magenta" = "35"
    "cyan"    = "36"
    "white"   = "37"
  }

  # 获取ANSI颜色代码
  $fgCode = $colorMap[$ForegroundColor.ToLower()]
  $bgCode = if ($BackgroundColor) { $colorMap[$BackgroundColor.ToLower()] + 10 } else { "" }

  $ansiSequence = "`e["

  if ($Bold) {
    $ansiSequence += "1;"
  }

  if ($bgCode) {
    $ansiSequence += "$bgCode;"
  }

  $ansiSequence += "${fgCode}m"

  $resetSequence = "`e[0m"

  Write-Host "$ansiSequence$Text$resetSequence"
}

# 示例用法：
# Write-Color "This is red text" -ForegroundColor "red"
# Write-Color "This is green text on yellow background" -ForegroundColor "green" -BackgroundColor "yellow"
# Write-Color "This is bold blue text" -ForegroundColor "blue" -Bold





function Loading {
  param(
    [string]$script,
    [string]$Label
  )
  $job = Start-Job -FilePath $script
  $symbols = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
  $i = 0;

  while ($job.State -eq "Running") {
    $symbol = $symbols[$i]
    Write-Host -NoNewLine "`r$symbol $Label" -ForegroundColor Green
    Start-Sleep -Milliseconds 100
    $job = Get-Job -Id $job.Id
    $i = $i + 1
    if ($i -eq $symbols.Count) {
      $i = 0;
    }
  }

  $result = Receive-Job -Job $job

  Remove-Job -Job $job

  Write-Host -NoNewLine "`r"

  return $result
}
