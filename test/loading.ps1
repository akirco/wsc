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
    $frameCount = $symbols.Count
    $frameInterval = 1

    Write-Host $Begin
    if ($Begin) { $Begin.Invoke() }

    $i = 0
  }

  PROCESS {
    while ($i -lt $frameCount) {
      $symbol = $symbols[$i % $frameCount]
      Write-Host -NoNewLine "`r$symbol $Activity" -ForegroundColor Green
      Start-Sleep -Milliseconds $frameInterval
      $i = $i + 1
    }
    $result += & $Process $InputObject
  }

  END {
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
  Start-Sleep -Seconds 3 # 模拟一个长时间任务
  return "Task completed"
}

$result = 1 | Write-TerminalProgress -Process { ExampleTask } -Activity "Processing..." -ReturnFullOutput
Write-Output $result
