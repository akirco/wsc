. "$PSScriptRoot\lib\scoop.ps1"

function Invoke-JobWithSpinner {
  param (
    [string]$LoadingText = "Processing", # Text to display while loading
    [scriptblock]$ScriptBlock, # ScriptBlock to run as a background job
    [int]$SpinnerInterval = 200             # Interval for spinner update in milliseconds
  )

  # Start the background job
  $job = Start-Job -ScriptBlock $ScriptBlock

  # Define the loading spinner characters
  $spinner = "|/-\"
  $i = 0

  # Loop until the job is completed
  while ($job.State -eq 'Running') {
    # Display the spinner with loading text
    Write-Host -NoNewline ("`r$LoadingText " + $spinner[$i])
    $i = ($i + 1) % $spinner.Length

    # Sleep for the defined interval
    Start-Sleep -Milliseconds $SpinnerInterval
  }

  # Clear the spinner once the job is done
  Write-Host "`r$LoadingText... Done.        "

  # Retrieve and return the job result
  $jobResult = Receive-Job -Job $job

  # Clean up the job
  Remove-Job -Job $job

  return $jobResult
}

# Example usage:
$scriptBlock = {
  # Simulate some work by sleeping for 5 seconds
  Start-Sleep -Seconds 5
  return "Job completed successfully!"
}

$result = Invoke-JobWithSpinner -LoadingText "Running your task" -ScriptBlock $scriptBlock

Write-Host "Result: $result"
