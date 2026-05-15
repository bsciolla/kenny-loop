---
description: Resume an existing kenny-loop in this session
argument-hint: <flag-file>
---

Resume the loop identified by $ARGUMENTS in the current session. Use the **PowerShell tool** for every shell command.

`<flag-file>` is the only argument. Resume is project-scoped: it locates the state file by hashing the current CWD, so run `/kenny-loop-resume` from the same directory you started the loop in.

### Step 1 — verify and re-stamp (one PowerShell call)

```powershell
$flag = '<FLAG>'
$base = [IO.Path]::GetFileName($flag)

$cwd = (Get-Location).Path
$sha1 = [Security.Cryptography.SHA1]::Create()
$bytes = [Text.Encoding]::UTF8.GetBytes($cwd.ToLowerInvariant())
$cwdHash = ([BitConverter]::ToString($sha1.ComputeHash($bytes)) -replace '-','').Substring(0,8).ToLowerInvariant()

$loopDir = Join-Path $env:LOCALAPPDATA 'kenny-loop'
$stateFile = Join-Path $loopDir (".loop-$base-$cwdHash.json")

if (-not (Test-Path -LiteralPath $stateFile)) {
  Write-Output "ERROR_NO_STATE: $stateFile not found"
  return
}

$state = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json

if ($state.flag_file -and (Test-Path -LiteralPath $state.flag_file)) {
  Write-Output "ERROR_FLAG_SET: $($state.flag_file) already exists; previous loop completed"
  return
}

$state.session_id = 'PENDING'
$state | Add-Member -NotePropertyName resumed_at -NotePropertyValue ((Get-Date).ToString('o')) -Force
$state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $stateFile -Encoding UTF8

Write-Output "OK"
Write-Output "PROMPT:"
Write-Output $state.prompt
```

### Step 2 — branch on the output

- If you see `ERROR_NO_STATE`: tell the user "No loop state found for `<flag>` in this project. Either run `/kenny-loop-resume` from the original project directory, or use `/kenny-loop` to start a new loop." Stop.
- If you see `ERROR_FLAG_SET`: tell the user "Flag is set — previous loop completed. Delete the flag manually if you really want to resume, or use `/kenny-loop` to start fresh." Stop.
- If you see `OK`: briefly acknowledge "Resumed loop `<flag>`." Then immediately execute the printed prompt as if the user had just sent it.

### Notes

- Always write `session_id: "PENDING"`. Never guess the real id; the Stop hook adopts on first fire.
- Do not modify `flag_file`, `prompt`, or `original_cwd` — resume is identity-preserving.
- Do not use the Write tool for the state file.
