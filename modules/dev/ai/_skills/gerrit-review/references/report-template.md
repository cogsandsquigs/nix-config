# Report template

Use this shape for the Phase 6 report, in chat (`full`) or in `gerrit-review-<number>-plan.md`
(`draft`).

```markdown
# gerrit-review plan — change <number>

## Provenance

- Change: <number> · <subject>
- Author: <name> · Project: <project> · Target branch: <target>
- Patchset reviewed: <n> of <current n> · Revision: <sha>
- Base for diff: <sha>^ (parent) | <parent CL number> (stacked below this one)
- Stack: <none, or the changes below and above this one>
- Fetched: `refs/changes/<xx>/<number>/<n>` · Worktree: <path or none>
- Existing votes: <account> +1 · <account> Code-Review -1
- Prior review by you: <none | patchset n, m comments>
- Generated: <date>

## What this change does

- Claims: <the commit message's intent, one sentence>
- Actually does: <what the code does, one sentence>
- Gap: <none, or the difference — this is often the most valuable finding>
- Bug: <id and whether the change matches it>

## Coverage

- Files: <n> changed, <+n/-n> lines
- Read in full: <paths>
- Skimmed: <paths and why — generated, vendored, lockfile>
- Not reviewed: <paths, or "none">
- Dimensions covered: correctness · security · contracts · concurrency · errors · tests · scope ·
  design · performance · style
- Dimensions not reached: <none, or which and why>

## Already said (not repeating)

- Bot: <n> findings on <paths> — <what they cover>
- <reviewer>: <what they already raised>
- Threads the author already answered: <n>

## Re-review: prior comments

Only for a change you reviewed before.

| Prior comment   | Status           | Note                                   |
| --------------- | ---------------- | -------------------------------------- |
| `sweeper.go:88` | addressed        | Now wrapped in the transaction         |
| `store.go:140`  | partly addressed | Guard added, error path still swallows |
| `api.go:22`     | not addressed    | No reply either                        |

## Findings

### F1 — <one-line title>

- Severity: blocking · Dimension: concurrency
- Site: `sweeper.go:88` (range 88–94)
- Defect: <what is wrong, one sentence>
- Failure: <the concrete input or interleaving, and what goes wrong>
- Confirmed: <what you read to ground it — the function, the callers, the lock scheme>
- Comment: "blocking: the read of `last_seen` and the delete aren't in one transaction, so a session
  touched between them is dropped — a user active during the sweep gets logged out."
- Suggestion: <none, or the mechanical edit to attach>
- unresolved: true
- Status: proposed

### F2 — <one-line title>

- Severity: nit · Dimension: style
- Site: `store.go:12`
- Defect: <what is wrong>
- Comment: "nit: `usr` reads as a typo for `user`."
- unresolved: false
- Status: proposed

### F3 — <one-line title>

- Severity: question · Dimension: correctness
- Site: `api.go:22`
- Defect: cannot judge without knowing whether `id` is parsed upstream.
- Comment: "question: is `id` validated before this? If it can arrive unparsed the query below
  interpolates it directly."
- unresolved: true
- Status: proposed

## Cut findings

Say what you dropped and why. The owner may want one back, and it is the evidence the bar was
applied.

| Candidate                   | Why cut                                              |
| --------------------------- | ---------------------------------------------------- |
| Slice-to-map in `lookup()`  | O(n²) at n=12. No scale where it matters             |
| Missing test for the getter | Behavior is a field read; a test would assert itself |
| `parseWindow` naming        | Preference only, repo uses this form elsewhere       |

## Cover message

The exact text to send with the batch.

> <the message — what it does, what matters, what you skipped, the vote>

## Proposed vote

- Vote: <-1 | 0 | +1 | +2>
- Rests on: <the findings that justify it, by id>
- If <F1> is resolved: <what the vote would become>

Needs explicit approval, separately from the comments.

## Cleanup

- Worktree to remove: <path or none>
```

## Rules for the report

- One finding per defect, not one per line. A rule broken in nine places is one finding naming the
  other eight sites.
- Every finding carries the exact comment text. The owner approves words, not intentions, and Phase
  7 posts what is written here.
- Every finding carries its `unresolved` value, because the default is `true` and a nit left at the
  default manufactures an obligation.
- Order the findings by severity, blocking first. The owner reads top-down and should hit what
  matters before what does not.
- A finding with no concrete failure line is not ready. Drop it to `question` or cut it.
- The coverage section is not optional. A review that does not say what it skipped implies it read
  everything, which is what makes a `+2` a false claim.
- Never write `Status: posted` before Phase 7 runs.
- Keep the vote separate from the comment list, and never pre-approve it.
