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

`$ARGUMENTS`: `detach`/`d` works the agreed plan without asking to continue between steps,
`attach`/`a` ends the independence, anything else names the current mode and stops.

Detached removes one thing -- the question between steps. It adds no permission. The user is away,
so every decision that belongs to the user is a stop, not a guess.

## Detach

Detach needs a plan the user agreed to in this session; without one nothing limits the work, and
detached then means unlimited, so ask for a plan instead. Print these five, then start.

1. Baseline: `git rev-parse HEAD` and `git status --porcelain`, proving only planned changes
   happened.
2. Whether commits are permitted, what they cover, and which source permits them.
3. The commands the steps need, and which are not permitted yet -- a prompt holds the work until the
   user answers, and this is the last cheap moment to add a rule.
4. The files tracking the work: plan, todo list, context file, any manual the plan changes.
5. The number of steps.

**Commit permission.** The user decides, and a decision recorded once still holds, also when this
session did not hear it. Three sources carry it: repository or personal configuration, a standing
arrangement in memory, a grant earlier in this session. "Commit each step" covers every step -- name
the source. A project permission rule counts least: it says the command can run, not that the user
wants a commit, and does not overrule instructions keeping git actions for the user. Withhold
commits only when no source permits them, and say so in the pre-flight, since the user can still
grant permission before they leave.

**One turn.** After a step finishes, start the next in the same response. A turn back to the user is
a pause, and the user is away, so a pause costs what a question costs. A progress note, a count of
finished steps, and a summary of the last step are all pauses. Report once, at the end or at a stop.

## The user owns the mode switch

Detached is a mode of the session, not of one turn. It holds until the user runs `/leash attach`,
the plan ends, or a stop occurs. A compaction drops this file and its rules, so carry the mode, the
baseline, the commit permission, and this file's path (the header above names its directory) into
every summary, and read the file again before the next step -- the mode outlives the text describing
it, and a summary keeping the mode but losing the path leaves you detached with no limits.

- Do not detach without the command. "Go ahead", "I trust you", "I am heading out again" are not
  `/leash detach` -- do that work attached. A user who sounds absent did not set your leash length.
- Do not attach mid-plan because the work became uncomfortable. Attach for a stop and report it.
  Silence is not an attach.
- A detach expires when the plan ends or a stop occurs; one read later in the transcript starts
  nothing, after a compaction or in a resumed session.
- A subagent does not inherit the mode -- it describes how you treat the absence of the user, and
  you cannot pass it on.

## Prohibited in detached mode

- Pushing or publishing: `git push`, pull request, comment, review, deployment, mail, ticket,
  message, any MCP write -- even when the plan asks. Outward actions belong to the user.
- Committing outside the permission recorded at the detach; one fix does not cover unrelated
  changes.
- Rewriting or discarding work: history rewrite, force flag, deleting a branch or stash, `git clean`
  or `git checkout --` over changes you did not write.
- Deleting or overwriting a file you did not read.
- Changing system state beyond what the plan names: `sudo`, package install, service restart,
  configuration outside the plan's files.
- Widening the plan -- record other useful work in the report and leave it undone.
- Relaxing a rule that applied attached: repository instructions, memory, gates, formatting, and
  commit cadence all still apply.

## Keep the record current

The user cannot watch the steps, so the written record is how they catch up, and a stale one is
worse than none because it reports work that did not happen. Update the tracking files as part of
each step, not at the end -- a step is not done while its record is stale. Mark it done where the
plan already lives, not in a second copy; record a decision, deviation, or deferred item when it
happens; correct a manual, README, or context file in the same step that makes its text wrong.

## Stop conditions

Finish the edit in progress so no file stays half written, do not start the next step, attach, then
print the report. Stop when:

- A step fails and the plan holds no fix, or the same failure survives two attempts.
- The plan contradicts reality and the difference changes what the user agreed to -- a file, option,
  or interface absent or behaving another way, so the user chose from a wrong picture. A detail only
  written wrong is different: `helper.py` where the plan said `helpers.py` has one obvious reading,
  so correct it, note it, carry on.
- A check that passed at the baseline now fails and you cannot account for it. Diagnose first: if
  this step caused it and the fix stays inside the plan, fix it next. Stop if the cause stays
  unclear, the fix reaches outside the plan, or the failure shows behavior the plan never meant to
  change -- the user decides whether to accept a regression.
- The plan leaves a real choice open and the two readings lead to very different work.
- The next action needs something prohibited, or is irreversible in another way.
- The tree holds a change you did not make, a merge conflict, or a git command that refuses to run.
- A credential, authentication, or permission prompt blocks a command: only the user can answer, so
  the session is stalled -- stop, and name the rule that unblocks the work.
- A command hangs, or repeats with no end.

Doubt about what the user wants is a stop. Doubt about how to do the work is not -- that doubt is
the work, and your judgment is what it was attached. A stop costs one message; a wrong guess while
the user is away costs them the state.

## Report

Print this at a stop, at `/leash attach`, and after the last step. A resumed session owes it too:
finishing the plan after a compaction still ends with the report.

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

When attached, say so and change nothing. When detached, stop as above, then print the report.
