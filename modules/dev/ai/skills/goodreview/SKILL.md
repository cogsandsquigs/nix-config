---
name: goodreview
description: >-
  Reviews code the way a careful senior engineer does -- correctness, edge cases, error handling,
  security, simplicity, readability -- and then goes deeper with a type-safety drilldown that
  judges how much of that correctness the types already PROVE, rather than deferring to runtime
  checks. Use whenever the user asks for a code review, design review, PR review, API review, or
  type review, or for feedback on a diff, a function, a data model, or a schema. Strong triggers:
  "review this", "is this good?", "what's wrong with this", "how would you model this", or any
  mention of type safety, illegal states, exhaustiveness, invariants, `any` or casts, edge cases,
  or correctness. Prefer this over an ad-hoc review whenever the goal is to catch bugs before they
  ship and make correctness hold by construction. Reach for it even when the user never says "code
  review" but is clearly asking for judgment on code they shared.
argument-hint: "<user guidance>"
---

# goodreview

Review code in two passes. First make sure it is _correct and sane_: it does what it claims, handles
the inputs it will actually see, fails safely, and a teammate can maintain it. Then go deeper than
most reviewers by asking how much of that correctness the _types already prove_. An ordinary review
catches the bug that is there. The type-level drilldown deletes the class of bug so it cannot come
back.

This skill is language-agnostic. Translate every concept into the target language's real mechanism --
Rust enums, TypeScript discriminated unions, Haskell ADTs, Go errors, Kotlin sealed classes -- rather
than assuming one language's features exist in another.

## Operating rules

- **Report every real finding.** Do not suppress by severity, and do not decide on the user's behalf
  that something is too minor to mention. Label the severity and let the reader filter.
- **The only filter is truth.** A finding must name a concrete input or state that produces the
  wrong outcome, the illegal state, or the unsafe path. If you cannot name one, it is speculation.
  Drop it. A review that manufactures findings is noise.
- **Two passes, then write.** Sanity, then proof, then the report. Do not run a third sweep.
- **Spend the budget where it pays.** Depth is not the same as suppression: give a three-line helper
  a sentence and a data model, a public API, or a security-relevant path full scrutiny. Report what
  you find at every depth.
- **Keep the report tight.** Let code carry the argument. Findings, not essays.

## Pass 1 -- Sanity

Work through the checklist below. Skip what does not apply to the diff rather than padding the
report.

### Correctness

Does the code do what its name, comment, or PR text says? Off-by-one, inverted condition, wrong
operator, wrong variable, copy-paste that was not fully edited, `==` against `===` or `.equals`,
mutation of a shared or aliased value, incorrect async ordering -- a missing `await`, an unhandled
promise, a race between two writes.

### Edge cases and inputs

Empty collection, single element, zero, negative, very large, `null` / `undefined` / `None`, empty
string, unicode, duplicate keys, concurrent access. What does the code do at each boundary?

### Error handling and failure

Are errors handled or swallowed? Is a caught exception logged and ignored where it should propagate?
Are resources released on the error path -- files, locks, connections, cleanup? Does a partial
failure leave state half-written? Are external calls to network, disk, or database treated as things
that _will_ fail, not things that might?

### Security and trust boundaries

Untrusted input reaching a query, command, path, or HTML sink without parameterization or escaping:
injection, path traversal, XSS. Secrets in code or logs. Auth and authz checks that can be skipped.
Unsafe deserialization. Overly broad permissions. Flag these as Critical when the data is genuinely
attacker-controlled, and name the source and the sink rather than hand-waving.

### Simplicity

Speculative generality: an abstraction, config knob, or extension point with one caller and no
second use in sight. Dead code, unused parameters, a layer that only forwards. Prefer the smallest
correct change.

### Readability and maintainability

Would a teammate understand this in six months? Misleading names -- a `getX` that mutates, a `count`
that is a bool. A function doing five things. Deeply nested conditionals that a guard clause or
early return would flatten. Magic numbers. A comment that contradicts the code. Comments should
explain _why_, not restate _what_.

### Tests

If tests are present: do they test behavior, or restate the implementation? Do they cover the edges
above, or only the happy path? Are they deterministic? If a bug you found has no test, note the
missing test. Do not demand tests for trivial code.

## Pass 2 -- Proof

This is where goodreview goes deeper than a normal review. The stance: the types are the theorem,
the implementation is the proof, and **every runtime check is an admission that the proof was
incomplete.** For each type, signature, and module, ask what it promises and what it still leaves up
to hope. Then close that gap.

Push hardest on three things:

1. **Make illegal states unrepresentable.** If a value can be constructed that the domain forbids,
   the design already failed, and every downstream guard is damage control.
2. **Push runtime checks to compile time.** Each `if (x == null) throw`, each assertion, each
   defensive guard is a proof obligation a type could discharge for free.
3. **Total correctness.** Functions should be total (defined on every input the type admits),
   exhaustive (compiler-enforced), and honest (no `any`, no unchecked casts, no lies).

Also ask which Pass 1 findings a type change would have prevented. Those are the highest-leverage
fixes in the report.

### Tells to hunt for

- **Primitive obsession** -- a `string` that is really an email, a `number` that is really a positive
  integer or a user ID. No proof attached. Recommend a branded, nominal, or newtype whose only
  constructor validates. The rest of the program then gets the invariant for free.
- **Boolean and flag soup** -- `isLoading`, `error?`, `data?` forming impossible combinations:
  loading _and_ data, or neither. The canonical illegal-states-representable smell. Recommend a
  tagged union, sum type, or sealed class with one variant per real state.
- **Correlated optionality** -- several fields that are all present or all absent, modeled as
  independent nullables. Lift the correlation into the type, as one nullable object or a variant, so
  the type states what the code already assumes.
- **Validate, don't parse** -- code that validates and then passes the _same untyped value_ on,
  forcing everyone downstream to re-trust it. A validator returns `bool`. A parser returns a more
  precise type that carries the proof forward. Push the boundary to return evidence.
- **Non-exhaustive dispatch** -- a `switch` or `match` with a silent `default`, or `if`/`else` over a
  closed set with no compiler check. Use the language's exhaustiveness mechanism so adding a case
  _forces every site to be revisited_. This is what makes types a refactoring tool.
- **Escape hatches and dishonest signatures** -- `any`, unchecked casts, `!`, `@ts-ignore`,
  stringly-typed dispatch. Each suspends the proof. Name the invariant being assumed without
  evidence, and show how to recover it. A signature returning `User` that can return `undefined` is
  lying, and the lie is believed until it crashes.
- **Partial functions** -- throws for some accepted inputs, assumes non-empty, indexes without a
  bounds proof, assumes a key exists. Either narrow the input type so the bad input cannot arrive,
  or make failure explicit in the return type with `Option` or `Result`.
- **Convention-only invariants** -- "callers must `init()` first", "keep these two fields in sync".
  Any invariant a comment asks a human to remember, a type could enforce: type-state, private
  constructor plus smart factory, immutability.

Do not invent type problems where none exist. If a design is already tight, say so and name the
pattern so the user can reuse it.

## Report

Lead with whatever is highest-leverage, which is often a Pass 2 structural fix that eliminates
several Pass 1 findings at once. Order findings by severity, then by how many bugs each kills per
unit of effort.

ALWAYS use this structure:

```markdown
# Code Review: [subject]

## Verdict

[2-4 sentences. Is it correct and safe to ship? What is the single highest-leverage change? Give an
overall read -- for example "logic sound, but boundaries leak untyped data" -- not a score.]

## Findings

### [F1] [Short title] -- [Critical | Major | Minor]

**Category:** [correctness | edge case | error handling | security | simplicity | readability |
tests | type-safety] **Where:** [location / symbol] **Issue:** [what is wrong, or what the type
permits that it should not] **Why it matters:** [the bug it causes, or the illegal state left to
hope] **Fix:** [the change, with a short before/after snippet where that clarifies]

[repeat per finding, ordered by severity then leverage]

## What's already sound

[Correct-by-construction designs and solid choices. Name the pattern so it is reusable. Omit only if
there is genuinely nothing worth reinforcing.]

## If you change one thing

[The single edit with the best bugs-eliminated-per-effort ratio, and why.]
```

**Severity guide.** **Critical** -- a bug reachable now that corrupts data, crashes, or opens a
security hole: attacker-controlled input reaching an unsafe sink, an illegal state reachable on a
money or auth path, an unhandled failure that loses data. **Major** -- a whole class of bugs left to
runtime that types could prevent: primitive obsession on a core type, non-exhaustive dispatch, an
unhandled edge case on a real input. **Minor** -- a local tightening: one avoidable cast, a missing
guard clause, a naming fix.

## Before/after example

Show fixes as concrete diffs, and always tie the snippet back to the bug or illegal state it
eliminates. TypeScript here is illustrative -- translate to the target language.

**Before** -- flags form impossible states, and consumers guess:

```ts
type Req = { loading: boolean; error?: string; data?: Payload };
// loading && data, error && data, none-of-them: all constructible, none valid
```

**After** -- one variant per real state, impossible states deleted:

```ts
type Req =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "error"; error: string }
  | { status: "success"; data: Payload };
// consumers switch on status with exhaustiveness; no guard can drift out of sync
```
