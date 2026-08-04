# Review dimensions

Work down this list. It runs from what breaks in production to what only offends, so an unfinished
pass still covers the things worth finding. When the budget runs out, say which dimensions you did
not reach rather than implying the change is clean.

Each dimension gives what to look for and **the bar** — the test for whether a finding is worth the
author's reading time. The bar is the point of this file. Finding things is easy; the discipline is
saying only the ones that pay.

- [1. Correctness](#1-correctness) · [2. Security and data safety](#2-security-and-data-safety)
- [3. Contracts and compatibility](#3-contracts-and-compatibility) ·
  [4. Concurrency and lifetime](#4-concurrency-and-lifetime)
- [5. Error handling](#5-error-handling) · [6. Tests](#6-tests)
- [7. Scope and intent](#7-scope-and-intent) · [8. Design](#8-design-borrow-goodreviews-lenses)
- [9. Performance](#9-performance) · [10. Readability and style](#10-readability-and-style)

## 1. Correctness

Does the code do what the commit message says, for every input that reaches it?

- Boundaries: empty, one, many. First and last iteration. Zero, negative, maximum.
- Off-by-one in slices, ranges, and pagination. The last page is where these live.
- Null, absent, and default conflated. A missing value treated as a zero value changes behavior.
- The branch nobody ran: the `else` with no test, the error path, the retry.
- State that must be reset between calls, and is not.
- Copy-paste asymmetry: four near-identical blocks where the third differs. Usually a bug, not
  style.

**Bar:** you can name the input or the sequence that produces the wrong result. "This looks fragile"
is not a correctness finding. If you cannot construct the failing case, drop to `question` and ask.

## 2. Security and data safety

- Input from outside the process reaching a query, a path, a command, or a template without being
  parsed into something that cannot be misread.
- Authorisation checked in the caller but not in the thing being called, when the callee is
  reachable another way.
- Secrets in code, in logs, in error messages, or in a test fixture.
- A permission or visibility default that widens: a bucket, a file mode, a CORS entry, a new
  endpoint without the check its neighbours have.
- Data leaving the system it was collected for. A new log line carrying a user identifier is a
  finding.

**Bar:** name the untrusted source and the sink it reaches. A secret in the diff is always
`blocking`, and say plainly that a rotation is needed — deleting the line leaves it in the history
and in every clone.

## 3. Contracts and compatibility

Whatever this change touches, somebody else already depends on.

- A signature, a field, or an error code that changed meaning while keeping its name. Renames are
  caught by the compiler; a meaning change is not.
- Serialised shapes: an API response, a database column, a queue message, a config key. Old readers
  and new writers overlap during a deploy.
- A migration that assumes an ordering with the deploy, or that cannot be rolled back.
- A default value change. It applies to every existing caller who never chose it.

**Bar:** name who breaks and when — the old client during the rollout, the queued message written
before the deploy. A contract finding with a named victim is usually `blocking`; without one it is a
`question`.

## 4. Concurrency and lifetime

- Read-then-write without atomicity, where two callers can interleave.
- A lock covering one field of an invariant that spans two.
- `await` or a yield point between a check and the use of what was checked.
- Resources not released on the error path: files, connections, locks, subscriptions.
- Cancellation and timeouts ignored, so the work outlives the request that wanted it.
- Something assumed single-threaded because it is today, with nothing enforcing it.

**Bar:** name the two actors and the interleaving. This dimension has the highest ratio of
plausible-sounding wrong findings, so read the whole locking scheme before commenting — a lock two
functions up invalidates most first guesses.

## 5. Error handling

- Swallowed: caught and logged, execution continues as if it succeeded.
- Flattened: a specific failure widened to a generic one, so callers cannot distinguish retryable
  from fatal.
- Leaked: an internal message, path, or stack reaching a user or a log at the wrong level.
- Partial failure leaving inconsistent state — two writes where the first landed.
- A retry with no backoff, no cap, or wrapping a non-idempotent operation.

**Bar:** say what the caller can no longer do. "Errors should be handled better" is not a finding;
"the caller cannot tell a timeout from a 404, so the retry loop above spins on a permanent failure"
is.

## 6. Tests

- New behavior with no test, and specifically the error path and the boundary.
- Tests that assert the implementation rather than the behavior — they pass through a refactor that
  breaks the feature, and fail on a refactor that does not.
- A test that cannot fail: no assertion, a tautology, a mock asserting itself.
- The bug fix with no regression test. This is the most reliably worthwhile test comment there is,
  because the fix is proof the case was reachable.

**Bar:** name the case that would go unnoticed. Asking for coverage as a number is not a finding.

## 7. Scope and intent

Compare what the change claims against what it does.

- Unrelated work folded in: a rename, a reformat, a dependency bump alongside a fix. It makes the
  change harder to review and harder to revert.
- The stated fix not actually fixing the stated bug, or fixing a symptom of it.
- Dead code arriving: a flag never read, a branch never reachable, a helper never called.
- A `TODO`, a commented-out block, or a debug print left in.

**Bar:** scope findings go in the **cover message**, not on a line. They are about the change as a
whole, and one clear sentence there lands better than three inline comments circling it. Past
roughly 400 changed lines, "this wants splitting" is itself the most useful thing you can say, and
saying it early costs the author less than saying it after thirty comments.

## 8. Design — borrow goodreview's lenses

The sibling `goodreview` skill already holds the deep lenses for design defects, so read them rather
than reinventing them. They live at:

```text
~/.claude/skills/goodreview/references/type-modeling.md
~/.claude/skills/goodreview/references/purity-and-effects.md
~/.claude/skills/goodreview/references/architecture.md
~/.claude/skills/goodreview/references/constraint-evasion.md
```

Read the one that matches what the change shows. Skip this dimension entirely if none of it applies
— most changes are too small for a design finding to be worth making.

| The change shows                                                                                                                  | Read                    |
| --------------------------------------------------------------------------------------------------------------------------------- | ----------------------- |
| Stringly-typed data, the same check repeated, a boolean selecting behavior, a sentinel value, optional fields only valid together | `type-modeling.md`      |
| A function mixing decisions with I/O, hidden mutation, exceptions for expected outcomes                                           | `purity-and-effects.md` |
| A new import cycle, a layer that only forwards, an interface with one implementer, drift from the documented structure            | `architecture.md`       |
| A new `any`, `@ts-ignore`, `unwrap()`, `//nolint`, a disabled warning, a type weaker than the design says                         | `constraint-evasion.md` |

Those files are missing if `goodreview` is not installed on this machine. That is not a blocker —
review the dimension from first principles and say you did.

**The bar, borrowed from goodreview's metric test.** A design finding must name three things:

1. **The invariant** — the rule the code assumes today.
2. **The sites** that re-check that rule, or the code that breaks it.
3. **The one place** that would prove the rule instead.

Name all three and you have a finding the author can act on in one step. Name fewer and you have
taste, which is not worth a colleague's time. This test is what separates a useful design comment
from "consider refactoring this", and it is the reason this dimension sits at 8 rather than 2.

**The tier guardrail, and it matters more here than in goodreview.** That skill classifies work into
T1 safe deletes, T2 local fixes, T3 focused remodeling (days), and T4 structural change (weeks).
Those tiers were written for a codebase its owner chose to clean, on their own schedule. This is
somebody else's change, already in flight:

| Tier      | On a change under review                                                    |
| --------- | --------------------------------------------------------------------------- |
| T1 and T2 | Fine as an inline comment. Local, cheap, and the author can act now         |
| T3        | Cover message, framed as a question or a follow-up. Never `blocking`        |
| T4        | Do not put it on the change at all. Raise it with the owner, outside Gerrit |

A T3 or T4 comment on an in-flight change asks the author to absorb days of work to land a fix,
which is how a review stalls a change for a week and sours the next one. The exception is narrow:
when the change itself _creates_ the structural problem, and it is cheaper to say so now than after
it ships. Then say exactly that, and say it as the cost comparison it is.

## 9. Performance

- Work inside a loop that belongs outside it, especially I/O and queries.
- A query per row where one query would do.
- A structure whose cost is wrong for its access pattern at real sizes.
- Unbounded growth: a cache with no eviction, a list that only ever appends, an unpaginated fetch.

**Bar:** name the scale at which it hurts, with the real data volume. Micro-optimisation of code
that runs once is noise, and a performance comment with no number attached is usually taste in
disguise. Unbounded growth is the exception — that one is a defect at any scale.

## 10. Readability and style

Last, and shortest, on purpose.

- A name that states the wrong thing. Worth fixing; a name that is merely not your preference is
  not.
- A comment that contradicts the code. One of them is wrong and the reader cannot tell which.
- Complexity with no reason: nesting that inverts cleanly, a clever line that reads slower than
  three plain ones.
- Whatever the repo's own formatter and linter enforce: not your comment to make. The tooling says
  it without costing anyone anything.

**Bar:** the reader is misled, not merely inconvenienced. Everything else is a `nit`, gets labelled
one, and gets posted with `unresolved: false`. Three style nits on a change with a real defect
buries the defect — cut them.
