---
name: leash
description: >-
    Runs a plan that the user already agreed to, with no confirmation question between steps. Hard
    limits hold: never push, never commit without permission given first, never widen the plan, and
    stop and report as soon as something is unexpected. Use `/leash detach` or `/leash d` to start
    detached operation. Use `/leash attach` or `/leash a` to take control back.
disable-model-invocation: true
argument-hint: "detach | d | attach | a"
---

# leash

`$ARGUMENTS` selects the mode.

- `detach` or `d` -- work through the agreed plan. Do not ask to continue between steps.
- `attach` or `a` -- return to normal operation. The independence ends.
- Any other value, and no value -- name the current mode and stop.

Detached mode removes one thing: the question between steps. It adds no permission. The user is away.
Every decision that belongs to the user is a stop, not a guess.

## Detach

Detach needs a plan that the user agreed to in this session. Without a plan, nothing limits the work,
and detached then means unlimited. If there is no plan, ask for one and do not detach.

Print these five things before the first step.

1. Record the baseline. Run `git rev-parse HEAD` and `git status --porcelain`. The baseline proves
   that only the planned changes happened.
2. State whether commits are permitted, which changes they cover, and which source permits them.
3. Name the commands that the steps need, and say which of them are not permitted yet. A prompt holds
   the work until the user answers it. This is the last cheap moment to add a rule.
4. List the files that track the work. These are the plan file, the todo list, the context file, and
   any manual that the plan changes.
5. State the number of steps, then start.

### Commit permission

The user decides whether you commit. A decision they recorded once still holds, also when this session
did not hear it. Three sources carry it: instructions in the repository or in personal configuration,
a standing arrangement in memory, and a grant earlier in this session. "Commit each step" covers every
step of the plan. Name the source you used.

A project permission rule counts least. It says that the command can run, not that the user wants a
commit. It does not overrule instructions that keep git actions for the user. Withhold commits only
when no source permits them, and say so in the pre-flight. The user can still grant permission in the
second before they leave.

### Work the plan in one turn

The plan is one stretch of work. After a step finishes, start the next step in the same response.

A turn that goes back to the user is a pause. The user is away, so a pause costs what a question
costs. The rest of the plan waits. A progress note, a count of finished steps, and a summary of the
last step are all pauses. Report once, at the end or at a stop.

## The user owns the mode switch

Detached is a mode of the session, not a mode of one turn. It holds in every response until one of
three things happens. The user runs `/leash attach`, the plan ends, or a stop condition occurs.

A compaction drops this file from the context, and the rules go with it. The header above names the
directory that holds the file. Carry four things into every summary: the mode, the baseline, the
commit permission, and the path of this file. After a compaction, read the file again before the next
step. The mode outlives the text that describes it, so a summary that keeps the mode and loses the
path leaves you detached with no limits.

Neither edge of the mode moves unless the user moves it.

- Do not detach without the command. "Go ahead", "I trust you", and "I am heading out again" are not
  `/leash detach`. Do that work in attached mode. A user who sounds absent did not set your leash
  length.
- Do not attach in the middle of the plan because the work became uncomfortable. Attach for a stop
  condition, and report that stop. Silence is not an attach.
- A detach expires when the plan ends or when a stop occurs. A detach that you read later in the
  transcript starts nothing, after a compaction or in a resumed session.
- A subagent does not inherit the mode. The mode describes how you treat the absence of the user, and
  you cannot pass it on.

## Prohibited in detached mode

- Do not push and do not publish. This covers `git push`, a pull request, a comment, a review, and a
  deployment. It also covers mail, a ticket, a message, and any MCP write tool. This holds even when
  the plan asks for it. Outward actions belong to the user.
- Do not commit outside the permission that you recorded at the detach. Permission for one fix does
  not cover unrelated changes.
- Do not rewrite work and do not discard work. This covers a history rewrite, a force flag, and
  deletion of a branch or a stash. It also covers `git clean` and `git checkout --` over changes that
  you did not write.
- Do not delete or overwrite a file that you did not read.
- Do not change system state beyond what the plan names. This covers `sudo`, a package install, a
  service restart, and configuration outside the files of the plan.
- Do not widen the plan. Record other useful work in the report and leave it undone.
- Do not relax a rule that applied in attached mode. Repository instructions, memory, gates,
  formatting, and commit cadence all still apply.

## Keep the record current

The user cannot watch the steps, so the written record is how the user catches up. A stale record is
worse than no record, because it reports work that did not happen. Update the tracking files as part
of each step, not at the end. A step is not done while its record is stale.

- Mark the step done where the plan already lives. Use that file, that list, or that tool. Do not
  start a second copy.
- Record a decision, a deviation, or a deferred item when it happens.
- Correct a manual, a README, or a context file in the same step that makes its text wrong.

## Stop conditions

When a stop condition appears, finish the edit in progress, so that no file stays half written. Do
not start the next step. Attach, then print the report.

Stop for any of these conditions.

- A step fails and the plan does not contain the fix. Also stop when the same failure survives two
  attempts.
- The plan contradicts reality, and the difference changes what the user agreed to. A file, an
  option, or an interface is absent, or it behaves in another way. The user then chose from a wrong
  picture. A detail that is only written wrong is different. `helper.py` where the plan said
  `helpers.py` has one obvious reading. Correct it, note the correction, and carry on.
- A check that passed at the baseline now fails, and you cannot account for the failure. Diagnose the
  failure first. When this step caused it, and the fix stays inside the plan, make the fix the next
  action. Stop when the cause stays unclear. Stop when the fix reaches outside the plan. Stop when
  the failure shows behavior that the plan never meant to change. The user decides whether to accept
  a regression.
- The plan leaves a real choice open, and the two readings lead to very different work.
- The next action needs something prohibited, or is irreversible in another way.
- The tree holds a change that you did not make, a merge conflict, or a git command that refuses to
  run.
- A credential prompt, an authentication prompt, or a permission prompt blocks a command. Only the
  user can answer it, so the session is stalled. Stop, and name the rule that unblocks the work.
- A command hangs, or repeats with no end.

Doubt about what the user wants is a stop condition. Doubt about how to do the work is not. That
doubt is the work, and your judgment is what it was in attached mode. A stop costs the user one
message. A wrong guess while the user is away costs the user the state.

## Report

Print this report at a stop, at `/leash attach`, and after the last step.

```
## leash report
Mode:     attached (finished | stopped | requested)
Progress: <n>/<m> steps
Stopped:  <step> -- <one line why>          [omit if finished]
Changed:  <files>; <commits, or "no commits" and why not>
Tree:     <clean | dirty: ...> against baseline <sha>
Gates:    <what ran, result>
Deferred: <found but not done>              [omit if none]
Needs you: <the decision or fix that unblocks the rest>   [omit if none]
```

## Attach

When the mode is attached, say so and change nothing. When the mode is detached, stop as described
above, then print the report.
