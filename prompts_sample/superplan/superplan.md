# Superplan

## Context

This is a "superplan" that contains a list of tasks with a checkbox `[ ]` to accomplish an "overarching goal".

## Status

Each task has a status:

- `[ ]` — TODO
- `[-]` — attempt in progress
- `[A]` — aborted
- `[X]` — done

## Task kind

Each task has a "kind":

- `<project-manage>` — instructions in [project-manage-task.md](project-manage-task.md)
- `<design>` — instructions in [design-task.md](design-task.md)
- `<implement>` — instructions in [implement-task.md](implement-task.md)
- `<test>` — instructions in [test-task.md](test-task.md)
- `<report>` — instructions in [report-task.md](report-task.md)

## What to do if no task remains

If all tasks are `[X]` or `[A]`, then write a flag termination file called `DONE.flag`.

## Action if any task remains

1. Take the next `[ ]` (TODO) task and mark it `[-]` (in progress) immediately.
2. Do the task.
3. On success, mark the task `[X]` then stop.
4. If something is off, or you need extra information, mark the item aborted `[A]`, write a report in `[task-slug-incident.md]`, and stop.

## Project "overarching goal"

Make a new page in the online shop with the history of sales.

## List of tasks

- [ ] `<project-manage>` — investigate where code changes are necessary
- [ ] `<design>` — prepare full dev plan
- [ ] `<implement>` — ...
- [ ] `<test>` — ...
- [ ] `<report>` — ...
