---
name: goodreview
description:
    "Audit a codebase and fix it. Finds dead code, cruft, scope creep, weak types, leaky boundaries,
    and shortcuts that evade a stated design. Use this skill when the user asks to clean up, audit,
    tidy, de-cruft, harden, or pay down debt in a project. Use it when they ask what is dead or what
    to delete. Use it for a review of architecture, module boundaries, or type modeling. Use it for
    vibe-coded or agent-written code that grew without a plan. Use it when they mention primitive
    obsession, boolean blindness, illegal states, defensive checks, shotgun validation, sentinel
    values, or stringly-typed data. Use it for an escape hatch such as `any`, `@ts-ignore`,
    `unwrap()`, `//nolint`, or a disabled warning. Use it when they ask whether the code still
    matches its spec. Use it also for a pre-refactor audit. Use it to carry out or resume a cleanup
    plan from an earlier run. Do not use it for a single bug fix, for performance work, or for a new
    project with nothing to clean."
argument-hint: "[audit|fix|full] [plan-path]"
arguments: mode plan
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/scan.sh *)
---

# goodreview

Cleanup answers three questions, in this order.

1. **Should this code exist?** If not, delete it.
2. **Should this state be representable?** If not, move the rule into the type and delete the checks
   that guarded it.
3. **Does this code evade a stated constraint?** If yes, restore the constraint.

Question 1 removes code. Question 2 moves work from run time to compile time. Question 3 undoes a
shortcut. All three end with fewer ways for the code to be wrong.

## The metric

Line count is not the metric. The metric is **reachable states and unguarded assumptions**.

A change that adds 12 lines of type and deletes 40 lines of scattered checks is a win. A change that
adds a type and deletes nothing is a guess. Reject it.

Every finding for Question 2 or Question 3 must name three things:

1. The invariant. The rule the code assumes today.
2. The sites that re-check the rule, or the code that breaks it.
3. The one place that will prove the rule.

If you cannot name all three, the finding is not ready. Drop it.

## Modes

The work splits at one point. Phases 0 to 5 find the problems. Phases 6 and 7 fix them.

| Mode      | Phases           | Use it when                                                                       |
| --------- | ---------------- | --------------------------------------------------------------------------------- |
| **audit** | 0 to 5           | The owner wants to know what is wrong. The run ends with a plan file and no edits |
| **fix**   | 5b, then 6 and 7 | A plan file exists already, from an earlier audit run                             |
| **full**  | 0 to 7           | The owner wants both in one session, and approves the scope at Phase 5            |

Default to **audit** when the request is a question, such as what is wrong or what should go.
Default to **full** when the request is an instruction to clean the project, and stop at Phase 5 for
approval.

Choose **fix** when the owner supplies a plan file, names an earlier audit, or says to continue or
resume. Go to Phase 5b. Do not rerun the scan first.

The skill takes two optional arguments. `$mode` holds `audit`, `fix`, or `full`. `$plan` holds a
path to a plan file. An argument that the owner did not pass arrives empty. Pick the mode from the
request when `$mode` is empty. Treat a path in `$plan` as mode `fix`, and read that file at Phase
5b.

An audit run is useful on its own. A large audit costs a lot of context, and the fix work needs
room. Ending at Phase 5 is a normal outcome, not an unfinished job.

## Progress checklist

Copy this list into your reply and mark each item as you finish it. The list is the record of where
the run stands. This matters because the phases span several turns.

```
goodreview progress
- [ ] Phase 0: baseline recorded
- [ ] Phase 1: intent and plan record read
- [ ] Phase 2: scan counted
- [ ] Phase 3: findings judged against the metric test
- [ ] Phase 4: findings classified into tiers
- [ ] Phase 5: plan file written, owner asked
- [ ] Owner approved a scope
- [ ] Phase 5b: plan verified against the code (resumed runs only)
- [ ] Phase 6: findings executed, one commit each
- [ ] Phase 7: each fix turned into a check the machine runs
- [ ] Metrics printed before and after
```

Drop the phases that the chosen mode does not cover.

## Process

Do not skip a phase. Do not edit a file before Phase 6.

### Phase 0: Baseline

Run the checks the project already has. Record the numbers.

Start with the bundled script. It counts the mechanical metrics and prints the table for you.

```bash
${CLAUDE_SKILL_DIR}/scripts/scan.sh .
```

The script reads only. It skips a tool that the machine does not have, and prints `n/a` for that
row. Then add the three rows it cannot know.

1. Build the project. Record the warning count.
2. Run the tests. Record the pass, fail, and skip counts.
3. Run the linter and the type checker. Record the error and warning counts.
4. Fill in the metrics table in `references/scans.md`.

A project that fails its own checks has a foundation problem. That is the first finding. If the
build is broken, stop and report. Do not clean on top of a broken build.

### Phase 1: Intent

Read the documents before the code. Read them in this order.

1. README, and CLAUDE.md or AGENTS.md.
2. Specs, design documents, architecture decision records, and plan files.
3. The recent git log and the recent pull-request text.
4. The dependency manifest.

Collect two things.

- **The stated shape.** What the project claims to be, and which rules it claims to hold.
- **The plan record.** Any type, name, or boundary that a document specifies. Phase 3 compares the
  code against this record.

A feature that exists in code but in no document is a removal candidate. A rule that a document
states and the code breaks is a Question 3 finding.

### Phase 2: Scan

Scan the whole repository with grep and glob. Do not read files one at a time. Count what you find.
Counts drive decisions. Impressions do not.

Read `references/scans.md` for the recipes, the tool per language, and the metrics table.

### Phase 3: Judge

First, ask the existence questions about each module and each feature.

1. Does it serve the stated purpose?
2. Is it reachable from an entry point? Trace the call path.
3. Could it ship as a separate project? If yes, consider removal.
4. Is it finished? Unfinished work goes away unless the owner wants to complete it.

Then judge the code that survives. Read the reference file that matches what the scan found.

| The scan found                                                                                                                                                                                                  | Read                               |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| Escape hatches, stringly-typed data, the same check in many places, booleans that select behavior, optional fields that are only valid together, sentinel values                                                | `references/type-modeling.md`      |
| Long functions that mix decisions with input and output, hidden mutation, exceptions used for expected outcomes, a switch with a catch-all case, a class that holds no state                                    | `references/purity-and-effects.md` |
| Import cycles, god modules, folders that overlap, a layer that only forwards, an interface with one implementer, drift from the documented structure                                                            | `references/architecture.md`       |
| A suppressed warning, a type that is weaker than the plan, an existing variant or field reused for a new meaning, a flat union with no-op cases, the words "simplest approach" in a comment or a commit message | `references/constraint-evasion.md` |

Never open a finding with "refactor this to be better". Apply the metric test to every design
finding.

The four reference files sit one level below this file, and they cite each other. Read whichever the
table names. Read a second one when a finding needs it. Do not chase a citation before you need it.

### Phase 4: Classify

| Tier                       | What it is                                                                                                                                | Examples                                                                                                                                                        | Effort  |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| **T1: Safe deletes**       | Unreachable code, unused files and assets, unused dependencies, abandoned experiments, indirection with one caller and one implementation | An orphaned image, `app_v2` beside `app`, a wrapper that only forwards                                                                                          | Minutes |
| **T2: Local fixes**        | One file changes. No caller changes                                                                                                       | Remove a stale marker comment, fix a lint warning, replace one cast with a real type, handle a swallowed error                                                  | Hours   |
| **T3: Focused remodeling** | One invariant or one boundary at a time. Callers change                                                                                   | Add a parse boundary and delete the checks behind it, split a god module, break a cycle, replace two booleans with one union, restore a type the plan asked for | Days    |
| **T4: Structural change**  | Many modules change shape                                                                                                                 | Invert a dependency direction, extract a pure core, redesign a boundary                                                                                         | Weeks   |

Keep the tiers apart. Do not present a T1 delete and a T4 redesign together.

A type finding and an architecture finding are never T1. They change behavior at the edges. They
need tests and owner agreement.

### Phase 5: Report and negotiate

Report before you plan and before you edit.

Write the report to a file, not only to the chat. A later session, or another agent, reads that file
to do the fix work. Put it at `goodreview-plan.md` in the repository root, unless the owner names
another path. Show a short summary in the chat and give the path.

Use this template. Keep the field names, because Phase 5b reads them.

```markdown
# goodreview audit: <project>

## Provenance

Date: <ISO date>. Commit: <short SHA>. Branch: <name>. Scope audited: <paths or "whole repository">.
Excluded: <paths>. Status: proposed

## Baseline

Build: <result, N warnings>. Tests: <P pass, F fail, S skip>. Lint: <N errors, M warnings>. Escape
hatches: <N>. Files: <N>. Largest file: <path, N lines>.

## Sound already

<What you checked and found correct. Give the counts.>

## Findings

Each finding carries a status: proposed, approved, rejected, done, or stale.

### T1 safe deletes (N)

- **<id>** `<path>` — <what> — evidence: <count or call trace> — deletes <N> lines.

### T2 local fixes (N)

- **<id>** `<path>:<line>` — <what> — evidence: <count> — risk: <low|medium>.

### T3 focused remodeling (N)

- **<id>** <name>
    - Invariant: <the rule the code assumes today>
    - Re-checked or broken at: <N sites, list the paths>
    - Single proof point: <where the type or the parse will live>
    - Deletes: <what goes away>
    - Risk: <what can break, and which test covers it>

### T4 structural (N)

- **<id>** <name> — the problem, the target shape, the blast radius, and why it earns weeks.

### Evaded constraints (N)

- **<id>** <name> — the document says <X>. The code does <Y>. `<path>:<line>`. Verdict needed from
  you.

## Recommended order

<T1 ids>, then <T2 ids>, then one T3 at a time.

## Questions for you

<Scope questions. What stays. What is out of scope.>
```

Ask the owner three things. Which features stay. Whether the T1 deletes can run now. Which T3 and T4
items matter. Never assume what the owner values. A doubtful feature may be the part they like most.

An evaded constraint always goes to the owner. The code chose the easy path once already. A second
agent should not ratify that choice alone.

**Stop here.** Wait for the owner. Do not start Phase 6 in the same turn as the report. Say that the
plan file is ready, and that the fix work can run now or in a later session.

Mark each answer in the plan file as the owner gives it. Set the status of each finding to approved
or rejected. Set the document status to approved when the owner agrees a scope.

### Phase 5b: Resume from a plan

Enter here when a plan file already exists. The plan may come from an earlier session, from another
agent, or from a different machine. Do not trust it. Check it against the code first.

1. Read the plan file. If the owner named no file, look for `goodreview-plan.md`, then for any file
   whose first line names a goodreview audit.
2. Read the provenance block. Compare the recorded commit with the current commit. Run
   `git diff --stat <recorded SHA>..HEAD` to see what moved.
3. Run Phase 0 again. Record the numbers beside the numbers in the plan. A different baseline means
   the plan is partly out of date.
4. Verify each approved finding against the code. Confirm the path exists, the line still holds the
   pattern, and the count still matches. Mark a finding stale when the code no longer matches.
5. Report the drift in one short list: N findings confirmed, N stale, N already done by somebody
   else. Ask the owner to confirm the order before you edit.
6. Go to Phase 6 with the confirmed findings only.

Rules for a resumed run:

- Never execute a finding with status proposed or rejected. Only approved findings run.
- Never execute a stale finding on a guess. Reaudit that one finding, or drop it.
- If the plan has no provenance block, treat every finding as unverified. Run step 4 for all of
  them.
- If more than half the findings are stale, stop. Say the plan is out of date, and offer a fresh
  audit.
- Keep the plan file open as the record. Update the status of each finding to done as you commit it.

A plan file is a proposal, not an instruction. The code is the truth.

### Phase 6: Execute

Order the work T1, then T2, then T3, then T4. Put T4 on its own branch.

After **each** finding, not at the end:

1. Build the project. It must pass.
2. Run the tests. They must pass.
3. Check for new warnings. There must be none.
4. Commit the working state. One finding per commit.

If a step fails, revert that finding and investigate. Do not stack a change on a broken tree.

For a T3 finding, add the test that pins the invariant **before** you change the type. The test
proves the behavior survived.

An upstream type change forces mechanical edits in every consumer. That work is the point, not a
reason to stop. Do the edits. Do not weaken the type to avoid them.

### Phase 7: Ratchet

A fix that only lives in the audit report decays. Turn each fix into a check the machine runs.

1. Turn on the warning that the fix now satisfies. Promote it to an error.
2. Add the lint rule that forbids the pattern you removed.
3. Record the Phase 0 metrics in the build or in the pull-request check.
4. If the project uses agent hooks, add a hook that blocks a new suppression.

Prefer a compiler setting over a note in a document. The compiler reads every commit. Nobody rereads
the note.

## Close the loop

Print the Phase 0 metrics beside the new numbers. Report the deltas: lines removed, escape hatches
removed, check sites removed, cycles removed, warnings removed, rules now enforced.

Write the same numbers into the plan file, in the After column. Set the status of each finished
finding to done. A finding left at approved is work still open, so the next session can pick it up.

## Do not add

Cleanup removes reasons for code to be wrong. It does not add machinery. During cleanup, do not
introduce:

- an event bus, a registry, a plugin system, or a dependency-injection container
- a base class, or an interface with one implementer
- a wrapper, adapter, or facade that only forwards
- a config option that no caller sets
- a new file, unless it holds a type or a parse function that lets you delete code elsewhere

## Common mistakes

| Mistake                                                | Do this instead                                                   |
| ------------------------------------------------------ | ----------------------------------------------------------------- |
| You refactor code that belongs in the bin              | Ask "should this exist" first                                     |
| You add an abstraction to fix a mess of abstractions   | Delete a layer instead                                            |
| You propose a new type that deletes nothing            | Apply the metric test. Drop the finding                           |
| You treat a cast as a formatting problem               | Ask which type is missing. A cast marks a modeling gap            |
| You silence a rule to reach a green build              | Fix the cause. A suppression is a finding, not a fix              |
| You reuse an existing variant to carry a new meaning   | Add the variant the domain needs                                  |
| You call code dead without a usage search              | Grep every use first, including dynamic access and config strings |
| You mix quick wins with multi-week work                | Use the tiers. T1 before T2 before T3                             |
| You write a five-phase plan with no owner input        | Report first. Agree the scope. Then plan                          |
| You start fixing in the turn that reports the findings | Stop at Phase 5. Wait for the owner                               |
| You run a plan file as written                         | Check each finding against the code first. See Phase 5b           |
| You read files one at a time                           | Scan the repository with grep and glob                            |
| You verify once at the end                             | Build, test, and commit after every finding                       |

## Red flags

Stop and reread this skill when any of these is true.

- You write code faster than you remove reasons for bugs.
- You created a file that no deletion depends on.
- You proposed a design pattern during a dead-code pass.
- Your plan spans weeks and starts at T3.
- You have not asked the owner what to keep.
- You have not run the build.
- You changed a type and the checks it replaced are still there.
- You silenced an error to reach a green build.
- You wrote, or read, the words "the simplest approach" as the reason for a design choice.
