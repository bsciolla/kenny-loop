$ErrorActionPreference = 'Stop'

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    $payload = $raw | ConvertFrom-Json
} catch {
    exit 0
}

$sessionId = [string]$payload.session_id

# State files live in a CWD-independent dir so `cd` mid-session can't hide them.
# Filenames are project-scoped via a CWD hash (see kenny-loop.md).
$loopDir = Join-Path $env:LOCALAPPDATA 'kenny-loop'
if (-not (Test-Path -LiteralPath $loopDir)) { exit 0 }

# NOTE: intentionally NOT checking $payload.stop_hook_active. That flag is true on
# every stop after the first hook-driven continuation in a session, which would cap
# us at one iteration. Our loop terminator is the flag file, not stop_hook_active.

$stateFiles = Get-ChildItem -LiteralPath $loopDir -Filter '.loop-*.json' -File -ErrorAction SilentlyContinue
if (-not $stateFiles) { exit 0 }

foreach ($file in $stateFiles) {
    try {
        $state = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        continue
    }

    if ($state.session_id -ne $sessionId) { continue }   # not ours: another session's loop

    if ($state.flag_file -and (Test-Path -LiteralPath $state.flag_file)) {
        Remove-Item -LiteralPath $file.FullName       -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $state.flag_file     -Force -ErrorAction SilentlyContinue
        continue
    }

    $reason = "kenny-loop active. The stopping condition on flag file '$($state.flag_file)' is not yet met, so continue the task."

    @{ decision = 'block'; reason = $reason } | ConvertTo-Json -Compress
    exit 0
}

exit 0
