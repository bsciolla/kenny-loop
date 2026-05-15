---
description: Stop a kenny-loop by creating its flag file
argument-hint: <flag-file>
---

Stop the loop identified by $ARGUMENTS. Use the **PowerShell tool**.

Stop is project-scoped: it looks up the state file by hashing the current CWD, then creates the flag at the absolute path recorded in state. Run from the same directory you started the loop in.

```powershell
$flag = '<FLAG>'
$base = [IO.Path]::GetFileName($flag)

$cwd = (Get-Location).Path
$sha1 = [Security.Cryptography.SHA1]::Create()
$bytes = [Text.Encoding]::UTF8.GetBytes($cwd.ToLowerInvariant())
$cwdHash = ([BitConverter]::ToString($sha1.ComputeHash($bytes)) -replace '-','').Substring(0,8).ToLowerInvariant()

$loopDir = Join-Path $env:LOCALAPPDATA 'kenny-loop'
$stateFile = Join-Path $loopDir (".loop-$base-$cwdHash.json")

if (Test-Path -LiteralPath $stateFile) {
  $state = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
  $flagPath = $state.flag_file
} else {
  # No state for this (flag, project) — fall back to creating the flag relative to CWD
  $flagPath = $flag
}

New-Item -ItemType File -Path $flagPath -Force | Out-Null
Write-Output "Loop stopped: flag '$flagPath' created. Cleanup will happen on the next Stop."
```

The Stop hook is the single place that cleans up both the `.json` state file and the flag file, so this command only has to create the flag.

Then briefly confirm to the user. Do NOT continue the original loop's task.
