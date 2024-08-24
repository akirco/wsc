function Write-TerminalProgress {
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory, ValueFromPipeline)]$InputObject,
    [ScriptBlock]$Begin,
    [ScriptBlock]$Process,
    [ScriptBlock]$End,
    [String]$Activity,
    [switch]$ReturnFullOutput
  )

  BEGIN {
    $result = @()
    $symbols = @("⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏")
    # $i = 0
    $frameCount = $symbols.Count
    $frameInterval = 100

    if ($Begin) { $Begin.Invoke() }

    $progressJob = Start-Job -ScriptBlock {
      param($symbols, $frameInterval, $frameCount, $Activity)
      $j = 0
      while ($true) {
        $symbol = $symbols[$j % $frameCount]
        Write-Host -NoNewLine "`r$symbol $Activity" -ForegroundColor Green
        Start-Sleep -Milliseconds $frameInterval
        $j = ($j + 1) % $frameCount
      }
    } -ArgumentList $symbols, $frameInterval, $frameCount, $Activity
  }

  PROCESS {
    $result += & $Process $InputObject
  }

  END {
    Stop-Job -Job $progressJob
    Remove-Job -Job $progressJob

    Write-Host -NoNewLine "`r"

    if ($End) { $End.Invoke() }

    # 返回结果
    if ($ReturnFullOutput) {
      return $result
    }
  }
}

# 示例用法
function ExampleTask {
  Start-Sleep -Seconds 1  # 模拟一个长时间任务
  return "Task completed"
}

$result = 1 | Write-TerminalProgress -Process { ExampleTask } -Activity "Processing..." -ReturnFullOutput
Write-Output $result
