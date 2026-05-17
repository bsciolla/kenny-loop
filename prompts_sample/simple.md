# Simple loop prompt

## Context

Below is the existing list of tasks with a checkbox `[ ]`.

## Status

Each task has a status:

- `[ ]` — TODO
- `[-]` — attempt in progress
- `[A]` — aborted
- `[X]` — done

## What to do if no task remains

If all tasks are `[X]` or `[A]`, then write a flag termination file called `DONE.flag`.

## Action if any task remains

1. Take the next `[ ]` (TODO) task and mark it `[-]` (in progress) immediately.
2. Do the task.
3. On success, mark the task `[X]` then stop.
4. If something is off, or you need extra information, mark the item aborted `[A]`, write a report in `{X_failed_report.md}`, and stop.


## Common instructions for every task

These instructions are generally valid for each task

## List of tasks

- [ ] - task 1
- [ ] - task 2
- ...
