---
description: Run the conversation in a loop until a flag file appears
argument-hint: <flag-file> <prompt...>
---

Start a session loop. Arguments: $ARGUMENTS

The first whitespace-delimited token of $ARGUMENTS is `<flag-file>`. Everything after the first space is the `<prompt>`. Execute the steps below in order, using the **PowerShell tool** (not Bash) for every shell command — this is Windows.

### Step 1 — sanitize and resolve

Compute these values mentally before running anything:
- `$Flag`     — `<flag-file>` exactly as given (e.g. `UNITTEST`, `DONE.flag`).
- `$Prompt`   — the rest of $ARGUMENTS, verbatim.
- `$Basename` — the file name part of `$Flag` (no directory).

The state file lives in `$env:LOCALAPPDATA\kenny-loop\` (CWD-independent so `cd` mid-session can't hide it; outside `.claude` to avoid permission prompts). Filename is project-scoped: `.loop-<basename>-<cwdhash>.json` where `<cwdhash>` is the first 8 hex chars of SHA1 of the resolved CWD path (lowercased).

### Step 2 — fresh-start sweep + state write (one PowerShell call)

Run this single PowerShell command, substituting `<FLAG>` and `<PROMPT_BASE64>` (base64-encode the prompt yourself to dodge quoting hell — `[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($prompt))`):

```powershell
$flag = '<FLAG>'
$prompt = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('<PROMPT_BASE64>'))
$base = [IO.Path]::GetFileName($flag)

# Project-scoped key from resolved CWD
$cwd = (Get-Location).Path
$sha1 = [Security.Cryptography.SHA1]::Create()
$bytes = [Text.Encoding]::UTF8.GetBytes($cwd.ToLowerInvariant())
$cwdHash = ([BitConverter]::ToString($sha1.ComputeHash($bytes)) -replace '-','').Substring(0,8).ToLowerInvariant()

$loopDir = Join-Path $env:LOCALAPPDATA 'kenny-loop'
if (-not (Test-Path -LiteralPath $loopDir)) { New-Item -ItemType Directory -Path $loopDir -Force | Out-Null }

$stateFile = Join-Path $loopDir (".loop-$base-$cwdHash.json")

# Sweep prior state for this same (flag, project)
if (Test-Path -LiteralPath $stateFile) { Remove-Item -LiteralPath $stateFile -Force }

# Make sure flag from a previous run is gone (relative to CWD)
if (Test-Path -LiteralPath $flag) { Remove-Item -LiteralPath $flag -Force }

# Resolve absolute path of the (not-yet-existing) flag file
$flagAbs = Join-Path $cwd $flag

$state = [ordered]@{
  session_id   = '${CLAUDE_SESSION_ID}'
  flag_file    = $flagAbs
  prompt       = $prompt
  original_cwd = $cwd
  created_at   = (Get-Date).ToString('o')
}
$state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $stateFile -Encoding UTF8
Get-Content -LiteralPath $stateFile -Raw
```

The trailing `Get-Content` is a sanity print so you can verify the file contents.

### Step 3 — execute the prompt

Now treat `<PROMPT>` as the user's actual request and start working on it. Do NOT mention the loop machinery further. The Stop hook will replay the prompt automatically until the flag file exists.

### Step 4 — when (and only when) the success criterion is met

Create the flag file at the absolute path stored in state (so `cd` mid-task doesn't break the signal):
```powershell
New-Item -ItemType File -Path '<FLAG_ABS>' -Force | Out-Null
```
Do NOT create it speculatively. The hook ends the loop the moment this file exists.

### Notes

- Always **PowerShell**, never Bash. `ls .loop-*.json` from Bash inside `C:\...` paths via Git Bash works inconsistently; PowerShell `Get-ChildItem -Filter '.loop-*.json'` is reliable.
- Do not use the Write tool for the JSON state file — encoding has bitten this project before.
- The harness substitutes `${CLAUDE_SESSION_ID}` into the command body before you read it, so the literal UUID lands in the state file. Do NOT replace the placeholder yourself or wrap it in extra quoting.
- If `/kenny-loop-stop <flag>` is invoked, just acknowledge — do not continue the original task.
- Avoid `Set-Location` mid-loop. The state lookup is now CWD-independent, but flag-file creation, resume, and stop still resolve relative paths from the CWD they were started in.
