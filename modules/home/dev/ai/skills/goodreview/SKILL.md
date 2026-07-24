---
name: goodreview
description: >-
    A high-level code review that combines ordinary engineering sanity-checking (correctness, edge
    cases, error handling, security, simplicity, readability) with a deep drilldown on type safety —
    judging how well the code's types PROVE its correctness rather than deferring to runtime checks.
    Use this whenever the user asks for a code review, a design review, a PR review, an API review,
    a type review, or feedback on a diff, a function, a data model, or a schema — and especially
    when they say "review this," "is this good?," "what's wrong with this," "how would you model
    this," or mention type safety, illegal states, exhaustiveness, invariants, `any`/casts, edge
    cases, or correctness. Prefer this over an ad-hoc review whenever the goal is to catch bugs
    before they ship and make correctness hold by construction. Reach for it even when the user
    doesn't say the words "code review" but is clearly asking for judgment on code they've shared.
argument-hint: "<user guidance>"
---

# goodreview

Review code the way a careful senior engineer does: first make sure it is _correct and sane_ — it
does what it claims, handles the inputs it will actually see, fails safely, and a teammate can
maintain it — and then go deeper than most reviewers by asking how much of that correctness the
_types already prove_. Ordinary review catches the bug that's there. The type-level drilldown
deletes the whole class of bug so it can't come back.

This skill is language-agnostic. Translate every concept to the target language's real mechanism
(Rust enums, TS discriminated unions, Haskell ADTs, Go errors, Kotlin sealed classes) rather than
assuming one language's features exist in another. Match effort to the code: a three-line helper
gets a sentence; a data model, a public API, or a security-relevant path is where scrutiny pays off,
so spend the budget there.

## How to run a review

Do two passes over the code, in this order.

**Pass 1 — Sanity.** Does it work and is it safe? (See "General review checklist.") **Pass 2 —
Proof.** Could the type system have prevented the problems Pass 1 found, and what other latent bugs
do the types still leave to hope? (See "Type-level drilldown.")

Then write the report. Lead with whatever is highest-leverage — often a Pass-2 structural fix that
eliminates several Pass-1 findings at once. Order findings by severity, then by how many bugs each
one kills per unit of effort.

## General review checklist

Work through these. Not every item applies to every diff — skip what's irrelevant rather than
padding the report.

### Correctness

Does the code do what its name/comment/PR says? Off-by-one, inverted conditions, wrong operator,
wrong variable, copy-paste that wasn't fully edited, `==` vs `===`/`.equals`, mutation of a
shared/aliased value, incorrect async ordering (missing `await`, unhandled promise, race between two
writes).

### Edge cases and inputs

Empty collection, single element, zero, negative, very large, `null`/`undefined`/`None`, empty
string, unicode, duplicate keys, concurrent access. What does the code do at each boundary?

### Error handling and failure

Are errors handled or swallowed? Is a caught exception logged-and-ignored where it should propagate?
Are resources released on the error path (files, locks, connections, cleanup)? Does a partial
failure leave state half-written? Are external calls (network, disk, DB) treated as things that
_will_ fail, not things that might?

### Security and trust boundaries

Untrusted input reaching a query/command/path/HTML without parameterization or escaping (injection,
path traversal, XSS). Secrets in code or logs. Auth/authz checks that can be skipped. Unsafe
deserialization. Overly broad permissions. Flag these as Critical when the data is genuinely
attacker-controlled — don't hand-wave, name the sink and the source.

### Simplicity (YAGNI)

Is there speculative generality — an abstraction, config knob, or extension point with one caller
and no second use in sight? Prefer the smallest correct change. Dead code, unused params, a layer
that only forwards.

### Readability and maintainability

Would a teammate understand this in six months? Misleading names (a `getX` that mutates, a `count`
that's a bool), a function doing five things, deeply nested conditionals that a guard clause or
early return would flatten, magic numbers, a comment that contradicts the code. Comments should
explain _why_, not restate _what_.

### Tests

If tests are present: do they test behavior or just restate the implementation? Do they cover the
edges from above, or only the happy path? Are they deterministic? If a bug you found has no test,
note the missing test. Don't demand tests for trivial code.

## Type-level drilldown

This is where goodreview goes deeper than a normal review. The stance: the types are the theorem,
the implementation is the proof, and **every runtime check is an admission the proof was
incomplete.** For each type, signature, and module ask: _what does this promise, and what does it
still leave up to hope?_ Close that gap. The three things to push hardest:

1. **Make illegal states unrepresentable.** If a value can be constructed that the domain forbids,
   the design already failed and every downstream guard is damage control.
2. **Push runtime checks to compile time.** Each `if (x == null) throw`, each assertion, each
   defensive guard is a proof obligation a type could discharge for free.
3. **Total correctness.** Functions total (defined on every input the type admits), exhaustive
   (compiler-enforced), and honest (no `any`, no unchecked casts, no lies).

### Tells to hunt for

- **Primitive obsession** — a `string` that's really an email, a `number` that's really a positive
  int or a user ID. No proof attached. Recommend a branded/nominal/newtype whose only constructor
  validates; the rest of the program then gets the invariant for free.
- **Boolean/flag soup** — `isLoading`, `error?`, `data?` that form impossible combinations (loading
  _and_ data, neither). The canonical illegal-states-representable smell. Recommend a tagged union /
  sum type / sealed class: one variant per real state.
- **Correlated optionality** — several fields all-present-or-all-absent, modeled as independent
  nullables. Lift the correlation into the type (one nullable object, or a variant) so the type
  states what the code assumes.
- **Validate, don't parse** — code that validates then passes the _same untyped value_ on, forcing
  everyone downstream to re-trust it. A validator returns `bool`; a parser returns a _more precise
  type_ that carries the proof forward. Push the boundary to return evidence.
- **Non-exhaustive dispatch** — `switch`/`match` with a silent `default`, `if/else` over a closed
  set with no compiler check. Use the language's exhaustiveness mechanism so adding a case _forces
  every site to be revisited_. This is what makes types a refactoring tool.
- **Escape hatches / dishonest signatures** — `any`, unchecked casts, `!`, `@ts-ignore`,
  stringly-typed dispatch. Each suspends the proof. Name the invariant being assumed without
  evidence and show how to recover it. A signature returning `User` that can return `undefined` is
  lying; the lie is believed until it crashes.
- **Partial functions** — throws for some accepted inputs, assumes non-empty, indexes without bounds
  proof, assumes a key exists. Either narrow the input type so the bad input can't arrive, or make
  failure explicit in the return type (`Option`/`Result`).
- **Convention-only invariants** — "callers must `init()` first," "keep these two fields in sync."
  Any invariant a comment asks a human to remember, a type could enforce (type-state pattern,
  private constructor + smart factory, immutability).

Don't invent type problems where none exist. If a design is already tight, say so and name the
pattern so the user can reuse it. A review that manufactures findings is noise.

## Report structure

ALWAYS output in this exact structure. Keep prose tight; let code carry the argument.

```markdown
# Code Review: [subject]

## Verdict

[2-4 sentences. Is it correct and safe to ship? What's the single highest-leverage change? Give an
overall read — e.g. "logic sound, but boundaries leak untyped data" — not a score.]

## Findings

### [F1] [Short title] — [Critical | Major | Minor]

**Category:** [correctness | edge case | error handling | security | simplicity | readability |
tests | type-safety] **Where:** [location / symbol] **Issue:** [what's wrong or what the type
permits that it shouldn't] **Why it matters:** [the bug it causes, or the illegal state / partial
case left to hope] **Fix:** [the change; include a short before/after snippet where it clarifies]

[repeat per finding, ordered by severity then leverage]

## What's already sound

[Call out correct-by-construction designs and solid choices; name the pattern so it's reusable. Omit
only if there's genuinely nothing worth reinforcing.]

## If you change one thing

[The single edit with the best bugs-eliminated-per-effort ratio, and why.]
```

Severity guide: **Critical** = a bug reachable now that corrupts data, crashes, or opens a security
hole (attacker-controlled input to an unsafe sink; illegal state reachable on a money/auth path;
unhandled failure that loses data). **Major** = a whole class of bugs left to runtime that could be
prevented (primitive obsession on a core type, non-exhaustive dispatch, unhandled edge case on a
real input). **Minor** = a local tightening (one avoidable cast, a missing guard clause, a naming
fix).

## Before/after example

Show fixes as concrete diffs. Illustrative (TypeScript) — translate to the target language, and
always tie the snippet back to which bug or illegal state the change eliminates:

**Before** — flags form impossible states; consumers guess:

```ts
type Req = { loading: boolean; error?: string; data?: Payload };
// loading && data, error && data, none-of-them: all constructible, none valid
```

**After** — one variant per real state; impossible states deleted:

```ts
type Req =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "error"; error: string }
  | { status: "success"; data: Payload };
// consumers switch on status with exhaustiveness; no guard can drift out of sync
```
