---
name: leash
description: >-
    Runs a plan that the user already agreed to, with no confirmation question between steps. Hard
    limits apply: never push, never commit without permission given first, never widen the plan, and
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

Detached mode removes one thing: the question between steps. It gives no permission that attached
mode did not give already. The user is away. Every decision that belongs to the user is a stop, not
a guess.

## Detach

Detach needs a plan that the user agreed to in this session. Without a plan, nothing limits the
work, and detached then means unlimited. If there is no plan, ask for one instead of detaching.

With a plan, do three things before the first step.

1. Record the baseline. Run `git rev-parse HEAD` and `git status --porcelain`. The baseline is the
   proof that only the planned changes happened.
2. State whether the user permitted commits, and for which changes. If the user did not say, commits
   are not permitted.
3. List the files that track the work. This covers the plan file, the todo list, the context file,
   and any manual that the plan changes.
4. State the number of steps, then start. Report again only at a stop or after the last step.

Detached is a mode of the session, not a mode of one turn. It holds in every response until one of
three things happens. The user runs `/leash attach`, the plan ends, or a stop condition occurs. If
the context is compacted, carry the mode, the baseline, and the commit permission into the summary.

## Prohibited in detached mode

- Do not push or publish. This covers `git push`, a pull request, a posted comment or review, mail,
  a ticket, a message, a deployment, and any MCP write tool. This holds even if the plan asks for
  it. Outward actions belong to the user.
- Do not commit unless the user gave permission before the detach. Permission for one commit is not
  permission for every commit. Keep to the permitted scope.
- Do not rewrite or discard work. This covers a history rewrite, a force flag, and deletion of a
  branch or a stash. It also covers `git clean` and `git checkout --` over changes that you did not
  write.
- Do not delete or overwrite a file that you did not read.
- Do not change system state beyond what the plan names. This covers `sudo`, a package install, a
  service restart, and configuration outside the files of the plan.
- Do not widen the plan. If you find other useful work, record it in the report and leave it undone.
- Do not relax a rule that applied in attached mode. Repository instructions, memory, gates,
  formatting, and commit cadence all still apply.

## Keep the record current

The user cannot watch the steps. The written record is how the user catches up later. A stale record
is worse than no record, because it reports work that did not happen.

Update the tracking files that you listed at the detach. Do this as part of each step, not at the
end. A step is not done while its record is stale.

- Mark the step done in the todo list, the plan file, or the todo tool that holds it. Use the same
  place that held the plan before the detach. Do not start a second copy.
- Record a decision, a deviation, or a deferred item at the moment it happens.
- Correct a manual, a README, or a context file in the same step that makes its text wrong.

## Stop conditions

Stop at the boundary between steps. Complete the edit in progress, so that no file stays half
written. Then attach and report. Do not start the next step.

Stop for any of these conditions.

- A step fails, and the plan does not contain the fix. Also stop if the same failure survives two
  attempts.
- The plan contradicts reality. A file, an option, or an interface that the plan assumed is absent,
  or behaves in another way.
- A check that passed at the baseline now fails, and you cannot account for the failure. A failed
  check is a question, not an automatic stop. Diagnose the failure first. If the current step
  clearly caused the failure, and the fix is inside the scope of the plan, then the fix is the next
  action. Stop if the cause stays unclear. Stop if the fix reaches outside the plan. Stop if the
  failure shows behavior that the plan was never intended to change. That is a regression, and the
  user decides whether to accept it.
- The plan leaves a real choice open, and the two readings lead to very different work.
- The next action needs something in the prohibited list, or is irreversible in another way.
- The tree holds a change that you did not make, a merge conflict, or a git command that refuses to
  run.
- A credential, an authentication prompt, or a secret is necessary.
- A command hangs, or repeats with no end.

Doubt is also a stop condition. A stop in the middle of the plan costs the user one message. A wrong
guess while the user is away costs the user the state.

## Report

Print this report at a stop, at `/leash attach`, and after the last step.

```
## leash report
Mode:     attached (finished | stopped | requested)
Progress: <n>/<m> steps
Stopped:  <step> -- <one line why>          [omit if finished]
Changed:  <files>; <commits, or "no commits">
Tree:     <clean | dirty: ...> against baseline <sha>
Gates:    <what ran, result>
Deferred: <found but not done>              [omit if none]
Needs you: <the decision or fix that unblocks the rest>   [omit if none]
```

## Attach

If the mode is already attached, say so and change nothing. If the mode is detached, stop as
described above, then print the report.
