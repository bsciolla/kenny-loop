# kenny-loop — plugin internals

Implementation notes for the kenny-loop Claude Code plugin. For overview, motivation, and user-facing usage, see the [top-level README](../../README.md).

## Install (local marketplace)

```
/plugin marketplace add kenny-loop\plugins
/plugin install kenny-loop@kenny-local
```

Once installed, the marketplace entry (`plugins/.claude-plugin/marketplace.json`) registers `kenny-loop` under the local marketplace `kenny-local`. The plugin manifest (`.claude-plugin/plugin.json`) declares the package; Claude Code auto-discovers the `commands/` directory for slash commands and `hooks/hooks.json` for hook registrations.

## Package layout

```
kenny-loop/
├── .claude-plugin/plugin.json    ← plugin manifest (name, version, author, license)
├── commands/
│   ├── kenny-loop.md             ← /kenny-loop  — start a loop
│   ├── kenny-loop-stop.md        ← /kenny-loop-stop  — create flag to end a loop
│   └── kenny-loop-resume.md      ← /kenny-loop-resume — re-arm in a new session
├── hooks/hooks.json              ← Stop hook registration
├── scripts/loop_hook.ps1         ← the Stop hook itself
├── LICENSE                       ← MIT
└── README.md                     ← this file
```

## State file

One JSON file per active loop, in `%LOCALAPPDATA%\kenny-loop\`:

```
.loop-<flag-basename>-<cwd-hash>.json
```

- `<flag-basename>` — `[IO.Path]::GetFileName($flag)`. Allows the user to pass either `DONE.flag` or `subdir\DONE.flag` without colliding.
- `<cwd-hash>` — first 8 hex chars of `SHA1(lowercase(resolved-CWD))`. Project-scopes the state so the same flag name in two different repos doesn't clobber.

Schema:

```json
{
  "session_id":   "<UUID or 'PENDING'>",
  "flag_file":    "<absolute path>",
  "prompt":       "<verbatim user prompt>",
  "original_cwd": "<absolute path>",
  "created_at":   "<ISO-8601>",
  "resumed_at":   "<ISO-8601, only if resumed>"
}
```

Lifecycle:

1. `/kenny-loop` writes the file with the current `${CLAUDE_SESSION_ID}` substituted by the harness.
2. The Stop hook compares `session_id` against the firing session's id (from stdin payload).
3. When the flag file appears, the Stop hook deletes both the state JSON and the flag file.

### Why `%LOCALAPPDATA%` and not the project CWD

Earlier iterations stored `.loop-*.json` in the project root. Two problems:

- Claude Code's permission model prompts on every write outside an allowed root, and the project CWD doesn't always match.
- A `Set-Location` mid-loop would hide the state file from the hook on the next Stop.

`%LOCALAPPDATA%\kenny-loop\` is stable, writable without prompts, and outside any `.claude` config dir (so it survives plugin uninstall/reinstall). The CWD hash keeps the project-scoping that the old CWD-relative layout gave us for free.

## Stop hook (`scripts/loop_hook.ps1`)

Registered in `hooks/hooks.json` against the `Stop` event with an empty matcher (fires on every assistant stop):

```json
{
  "hooks": {
    "Stop": [
      { "matcher": "",
        "hooks": [
          { "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"${CLAUDE_PLUGIN_ROOT}/scripts/loop_hook.ps1\"" }
        ] }
    ]
  }
}
```

The hook reads a JSON payload from stdin (`session_id`, `stop_hook_active`, etc.) and:

1. Enumerates `%LOCALAPPDATA%\kenny-loop\.loop-*.json`.
2. For each file: parse → if `session_id` mismatches the firing session, **skip** (this is how stale state from killed sessions is ignored).
3. If `flag_file` exists on disk → delete both files, continue.
4. Otherwise → emit `{decision: "block", reason: "<prompt>"}` to stdout and exit. The single emit means: replay the stored prompt as the next turn.

### Why `stop_hook_active` is intentionally ignored

Claude Code sets `stop_hook_active: true` on every Stop after the first hook-driven continuation in a session. Honouring it would cap the loop at one iteration. The flag file is our termination signal, not `stop_hook_active`.

### Multi-loop behaviour

Multiple `.json` files for the same session can coexist (different flag names). The first matching, unfinished one wins per Stop: it emits its block-reason and the hook exits. The next Stop visits the directory afresh, so once that loop's flag fires and its state is cleaned up, the next-matching loop takes over.

## Commands

All three commands live as Markdown files with YAML frontmatter (`description`, `argument-hint`). The body is prompt content — instructions to the assistant on what PowerShell to run.

### `/kenny-loop <flag> <prompt>`

1. Base64-encode the prompt to dodge PowerShell quoting hell.
2. Compute the CWD hash.
3. Sweep any prior state file or flag file with the same identity.
4. Write a fresh JSON state file with `session_id = ${CLAUDE_SESSION_ID}`.
5. Hand the prompt to the assistant as the actual task.

The harness substitutes `${CLAUDE_SESSION_ID}` into the command body **before** the assistant reads it, so the literal UUID lands in the state file. The command instructions explicitly warn not to wrap or re-substitute the placeholder.

### `/kenny-loop-stop <flag>`

Looks up the state file by `(flag-basename, cwd-hash)`. If found, creates the flag at the absolute path recorded in state (so a `cd` mid-task doesn't break the signal). If no state, falls back to creating the flag relative to CWD. Cleanup happens on the next Stop hook fire, not here.

### `/kenny-loop-resume <flag>`

Recovery path when the session that started a loop dies (crash, manual exit). Looks up the state file the same way, then:

- Errors if no state exists (`ERROR_NO_STATE`).
- Errors if the flag is already set (`ERROR_FLAG_SET` — previous loop completed).
- Otherwise re-stamps `session_id` to the literal string `"PENDING"`, adds `resumed_at`, and prints the stored prompt for the assistant to execute as if it were a fresh user turn.

The Stop hook adopts a `PENDING` state file on its first fire by comparing — wait, no. The hook only fires for an *exact* session_id match. Resume works because the resumed session re-runs `/kenny-loop` semantics for the *prompt*, but the state file's `session_id` stays `PENDING` until the next start would overwrite it. **Caveat:** in the current implementation, a resumed loop's state is only adopted when the assistant in the new session hits its own Stop and the hook sees `session_id != current` and skips it — meaning resume re-arms the loop in the prompt sense, but a future, more robust version should rewrite `session_id` to the resuming session's id. (TODO.)

## PowerShell-only

All commands and the hook are written in PowerShell. Bash inside Git Bash on Windows handles `C:\` paths and dotted glob patterns (`.loop-*.json`) inconsistently. `Get-ChildItem -Filter` is reliable. The command Markdown files explicitly tell the assistant to use the PowerShell tool, not Bash.

## State file encoding

The JSON state file is written with `Set-Content -Encoding UTF8` from PowerShell, **not** the Claude Code `Write` tool. The Write tool's encoding has caused parsing failures (BOM / UTF-16 surprises on Windows PowerShell 5.1) when the hook reads the file back.

## License

MIT. Copyright (c) 2026 Bruno. See [LICENSE](LICENSE).
