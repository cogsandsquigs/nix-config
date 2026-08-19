---
name: checkin
description: >-
    Stop-the-world status check for long-running work: hold everything including sub-agents, audit
    it against the original goal, report, and wait for continue or adjust.
disable-model-invocation: true
---

# checkin

The user wants proof that a long-running effort is still healthy and still pointed at the original
target. Freeze everything, account for all of it, report, and wait. The user's answer is what
restarts the work.

Each file under `resources/` is used whole: fill in each `[bracketed]` slot, drop a line whose slot
does not apply, and keep the rest exactly as written.

Copy this checklist and check off each step as you complete it:

```
Check-in progress:
- [ ] Step 1: Freeze and list
- [ ] Step 2: Hold sub-agents and collect their reports
- [ ] Step 3: Investigate anything off
- [ ] Step 4: Write the report
- [ ] Step 5: Wait for the user
```

## Step 1: Freeze and list

From this point on, only observe: list, read, question. List what is running: TaskList for
background tasks, ListAgents for live sub-agents. The step is done when every running task and
sub-agent is on the list.

## Step 2: Hold sub-agents and collect their reports

Send each running sub-agent the content of [resources/hold-prompt.md](resources/hold-prompt.md) as
the message. A stable prompt keeps replies comparable across sub-agents and across check-ins.

Wait a bounded time for replies. The step is done when every sub-agent on the list has a reply or a
noted state: "status unknown, hold requested" for a silent one, "cannot be messaged" for an
unreachable one.

## Step 3: Investigate anything off

Status replies are claims. Check each claim against the plan, the task list, the original request,
and what the sub-agent has produced. Suspicion triggers:

- output that does not match the assignment
- files touched outside the sub-agent's scope
- work the plan never defined
- a sub-agent silent or spinning far longer than its task warrants
- a report that is vague where the plan is specific

Investigate each suspicion now. Read the sub-agent's output and transcript, inspect the files it
changed, question it directly. The investigation is read-only: fixes, reverts, and redirects belong
to the user, who orders them from the report.

Look backward and inward too. Retrospective: walk the work since the goal was set, yours and each
sub-agent's. Find where decisions diverged from the plan and where the task got quietly
reinterpreted. Introspective: apply the same suspicion to yourself -- assumptions made without
evidence, shortcuts taken under pressure, instructions softened or dropped. The hold prompt asks
each sub-agent for the same self-review, so read those sections of the replies with care.

The step is done when each suspicion is stated in two lines: what actually happened, and why.

## Step 4: Write the report

Write the report as [resources/report-template.md](resources/report-template.md), filled in. Keep it
small: a pulse check, not a retrospective.

The alignment line is the point of the skill. Compare against the original request, not the latest
paraphrase of it. Drift reported here is cheap. Drift the user discovers later is expensive.

## Step 5: Wait for the user

End the turn with a question shaped by what the check-in found. When the report carries flagged
items or risks, be direct about them: name each issue, propose a remedy, and ask whether to address
it now, defer it, or accept it. When the report is clean, ask only: continue as-is, or adjust? Use
AskUserQuestion when available, plain text otherwise.

The user's answer is the only thing that resumes the work. On "continue", release the holds and pick
up where the report said up next. On an adjustment or an approved remedy, apply it -- update the
plan, redirect or stop sub-agents -- then confirm the new direction in one line and resume.
