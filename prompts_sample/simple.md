
Context
-------

Below the existing list of tasks with a checkbox [ ].

Status
-------

Each task has a status
  [ ] = TODO
  [-] = attempt in progress
  [A] = aborted
  [X] = done


What to do if no task remains
----------------------

If all tasks are [X] or [A], then write a flag termination file called DONE.

Action if any task remains
----------------------

Step 1. Take the next [ ] (TODO) task and mark it [-] (in progress) immediately.
Step 2. Do the task
Step 3.a. When succeeded mark the task [X] then stop.
Step 3.b. If something is off, or need extra information, mark the item aborted [A]. Write a report in an {X_failed_report.md} and stop.

List of tasks
-------------

[ ] - task 1
[ ] - task 2
...

