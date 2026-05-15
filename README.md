# kenny-loop

A small Claude Code plugin and a handful of prompt samples for running long, structured tasks under a session loop on Windows.

```
kenny-loop/
├── plugins/kenny-loop/       ← the plugin (slash commands + Stop hook)
└── prompts_sample/           ← prompt material you can paste into /kenny-loop
    ├── simple.md
    └── superplan/
```

## What's kenny-loop

kenny-loop is a variant of the **Ralph loop** — a pattern popularised by Geoff Huntley in 2024 for getting long-running work out of an LLM agent. The original Ralph loop is a tiny shell script: invoke `claude` with a prompt, check a stop condition, repeat. The agent does one bounded chunk of work per invocation, exits when the call returns, and a fresh invocation picks up by re-reading the project state.

kenny-loop keeps the spirit but moves the machinery inside Claude Code. You give it a prompt and a flag file name; the assistant keeps working on the prompt, and every time it would normally stop, the Stop hook kicks it back into action — until the flag file appears on disk. At that point the loop ends.

The flag file is the stop criterion, and that's deliberately the only stop criterion. Some agent has to create the file; the loop sees it; the loop ends. Timeouts or iteratfion counts are not supported.

The loop is robust across sessions: if the Claude Code session that started the loop crashes or is closed, the state isn't lost. You open a new session, run `/kenny-loop-resume`, and the loop picks up where it left off. Conversely, a loop only ever runs in the session it was started in (or explicitly resumed from) — a dead session's state never auto-fires in some unrelated future session.

Multiple loops can run concurrently — one per project directory, one per flag name — without colliding.

### How it differs from the original Ralph loop

- Windows / PowerShell first, not a port of the bash version.
- Lives as a Claude Code plugin, not an external shell script.
- Project-scoped: two repos can both have a `DONE.flag` loop running and they won't interfere.
- Stop condition is a real file you can `ls` and `rm`, not a magic string in a state file.
- A killed session never auto-resumes. Resume is an explicit decision.

For install instructions, hook internals, state file format, and other implementation details, see [`plugins/kenny-loop/README.md`](plugins/kenny-loop/README.md).

### Commands

- **`/kenny-loop <flag-file> <prompt>`** — start a loop. The assistant works on `<prompt>`, replaying every turn until `<flag-file>` exists.
- **`/kenny-loop-stop <flag-file>`** — end a running loop by creating its flag file. You can also just `New-Item DONE.flag` from your shell.
- **`/kenny-loop-resume <flag-file>`** — pick up a loop in a new session after the original session ended. Replays the stored prompt; refuses if the flag is already set or no loop state exists.


## Prompt samples

### `prompts_sample/simple.md` — a script for repetitive tasks

Launch with
```
/kenny-loop DONE.flag execute the task described in [your-version-of-simple.md]
```

A flat checklist. Each item is a `[ ]` TODO; the loop walks the list, marking items `[-]` (in progress), `[X]` (done), or `[A]` (aborted with a report). When all items are `[X]` or `[A]`, it writes the flag file and stops.

Use when:
- the work is a known, ordered list of small steps
- each step is roughly the same "size" of effort
- you don't need per-step instructions beyond the task title

### `prompts_sample/superplan/` — a bundle for work that requires complex coordination

Launch with
```
/kenny-loop DONE.flag execute the plan described in [your-version-of-superplan.md]
```

The root file `superplan.md` is the task description for every spawned agent. This file holds the overarching goal and a checklist of tasks. Each agent has to pick the next task and attempt to do it.
Each task carries a **task kind** — `<project-manage>`, `<design>`, `<implement>`, `<test>`, `<report>` — and each kind points to its own instruction file.

```
superplan/
├── superplan.md              ← entry point: contains the plan and the progress
├── project-manage-task.md    ← task kind instructions
├── design-task.md            ← task kind instructions
├── implement-task.md
├── test-task.md
└── report-task.md
```


#### Remark - context window

- at each new loop, the new agent can do the task even when it starts without prior context. This design allows the execution of tasks that require memory way beyond the memory window.
- encourage planning/design agents to write instructions in subfiles. If the superplan.md carries the specification, the structure can be lost and/or the context window can be exhausted. 
- (comfort) make your <report> agent clean up superplan.md

#### Remark - subagents

- the task kinds emulate the notion of "specialized subagents" in a more flexible way
- you should craft yourself the choice of relevant agents (the plan, design, implement, etc. are just examples) and their instructions

#### Remark - meta

- the higher level <project-manage> agent should write the list of tasks itself! However it needs some help figuring out how. A skeleton is often enough to start.

```
List of tasks
-------------

[ ] - <project-manage> - investigate where code changes are necessary
[ ] - <design> - prepare full dev plan
[ ] - <implement> - ...
[ ] - <test> - ...
[ ] - <report> - ...

```

- (optional) suggest your <project-manage> agent to edit task-kind files to solve problems encountered

#### Remark - interactivity

- you can give feedback or edit the superplan (adding tasks) while the loop is running

#### Remark - safety

- infinite loops can happen, but the aborted status [A] serves as a panic escape
- Claude Opus is good at narrowing down the actions to what is useful and reasonable

## License

MIT. See [`plugins/kenny-loop/LICENSE`](plugins/kenny-loop/LICENSE).
