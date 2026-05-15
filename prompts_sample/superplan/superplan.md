
Context
-------

This is a "superplan", that contains a list of tasks with a checkbox [ ] to accomplish an "overarching goal".

Status
-------

Each task has a status
  [ ] = TODO
  [-] = attempt in progress
  [A] = aborted
  [X] = done

Flavours
-------

Each task has a "flavour"
  <plan> - instructions in [plan-task.md]
  <design> - instructions in [design-task.md]
  <implement> - instructions in [implement-task.md]
  <test> - instructions in [test-task.md]
  <report> - instructions in [report-task.md]

What to do if no task remains
----------------------

If all tasks are [X] or [A], then write a flag termination file called DONE.

Action if any task remains
----------------------

Step 1. Take the next [ ] (TODO) task and mark it [-] (in progress) immediately.
Step 2. Do the task
Step 3.a. When succeeded mark the task [X] then stop.
Step 3.b. If something is off, or need extra information, mark the item aborted [A]. Write a report in an [task-slug-incident.md] and stop.

Project "overarching goal"
--------------

Make a new page in the online shop with the history of sales


List of tasks
-------------

[ ] - <plan> - investigate where code changes are necessary
[ ] - <design> - prepare full dev plan
[ ] - <implement> - ...
[ ] - <test> - ...
[ ] - <report> - ...
