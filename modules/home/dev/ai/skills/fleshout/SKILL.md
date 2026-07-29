---
name: fleshout
description: >-
  Turns rough material — a code sample, a git diff, scratch-pad notes, half-formed guidance — into
  a complete, production-quality feature written in the codebase's own style. Use when the user
  hands over a stub, a TODO-riddled diff, or a "here's roughly what I'm thinking" note, even when
  they never say "flesh this out". Trigger signals: a match/switch handles one case and the rest
  fall through, a diff introduces a partial abstraction that is not carried through the codebase,
  notes describe a workflow larger than the code shown, or guidance gestures at a feature while
  supplying only fragments. Also triggers on "turn this into a feature", "make this a real
  implementation", "flesh this out", "build this out properly". Does not apply to small
  self-contained requests — a single bug fix, a one-off script, "add a null check here" — where no
  larger feature is lurking. Do those directly.
argument-hint: "<sketch, diff, or notes to build out>"
---

# Flesh out a feature

Turn rough material into a complete, well-designed feature in the project's existing style. The work
is not mechanical expansion. Read what the user is actually building, confirm the parts that are
ambiguous, then build it properly.

Sketches are compressed. They show _an_ example of the shape, not the whole shape. A stub with one
match arm means the author knows more arms are coming. "Also need to handle retries somehow" is a
requirement wearing a hedge.

## The two failure modes

**Under-building** — implementing only what the sketch literally shows and leaving `TODO` for the
rest.

**Over-building** — inventing scope nobody asked for: an abstraction layer with one caller, a config
knob with no second use, a refactor of surrounding code that was not part of the request, defensive
handling for states the domain cannot produce.

Over-building is the likelier failure here, because this skill's premise is "there is more than what
is shown". Step 4 is the brake. Use it instead of guessing outward.

## Operating rules

- Hand back complete code. No stubs, no placeholders, no `TODO` for a case you decided was in scope.
- Narrate briefly: one sentence before starting, a note when a finding changes the plan, and an
  outcome-first summary at the end.
- The scope is what step 2 establishes and step 4 confirms. Nothing wider.

## Process

### 1. Gather the material

Collect before writing anything:

- The code sample or diff (`git diff`, `git diff --staged`, or a pasted snippet).
- Scratch notes, TODOs, and comments. These usually carry the real intent.
- The user's guidance, however informal.
- The surrounding code, if this is an existing project. New code should look like the same person
  wrote it. Read `references/convention-detection.md` for the order to check things in — linter
  config, a representative existing feature, the error-handling idiom, module layout, naming, test
  style — rather than generalizing from whichever file happens to be open.

If something needed is missing, ask for it instead of guessing: "do you have a `git diff` for this,
or should I read the working tree directly?"

### 2. Find the real shape

From the gathered material, work out:

- Which states and cases this needs to handle, not just the one shown.
- The data model, and the invariants it must hold.
- What is explicitly out of scope, as opposed to merely unwritten.

`references/scope-signals.md` has the calibration checklist and worked examples for telling "this
sketch implies more than it shows" apart from "this really is a small fix".

### 3. Design by parsing, not validating

Prefer types and structure that make invalid states unrepresentable over runtime checks scattered
through the logic:

- Convert data into a well-typed shape _once_, at the boundary. Downstream code trusts the shape and
  never re-checks the same invariant.
- Use sum types, tagged unions, or enums for "one of several known cases" instead of optional fields
  plus booleans that are only valid in certain combinations.
- Use newtype-style wrappers for values with invariants — a validated email, a non-empty list, a
  positive quantity — so the type carries the guarantee.
- Prefer exhaustive matching over `if`/`else` chains with a fallback. Exhaustiveness checking
  catches a missing case at compile time instead of at 2am.

`references/parse-dont-validate.md` has concrete patterns in TypeScript, Go, Rust, and Haskell. Pull
the one matching the diff's language, or use a neighboring one to translate the idea.

### 4. Checkpoint at real decision points

Stop and ask before proceeding whenever the next step is not purely mechanical:

- **Architecture** — how a new concept fits the existing module or type structure, which layer owns
  a new responsibility, whether to add a type or extend an existing one.
- **Ambiguous scope** — a note hints at behavior without pinning it down. "Handle retries somehow":
  how many, what backoff, which errors are retryable?
- **Trade-offs with no obviously correct answer** — performance against simplicity, breaking an API
  against adding a parallel one, sync against async.
- **Anything expensive to unwind** — a schema shape, a public API surface, a persistence format.

Do not ask about mechanical steps. Wiring up a function, matching a naming convention, and writing
obvious plumbing are yours to do. Checkpoints protect the user's real decisions; spending them on
non-decisions teaches the user to skim past the ones that matter.

Ask concretely: two or three real options with their trade-offs, and your lean. The user is often
mid-thought, and a sharp menu is easier to answer than a blank page.
`references/checkpoint-examples.md` shows the shape.

While waiting for an answer, do not build speculatively down one branch.

### 5. Implement

- Match existing project conventions exactly: formatting, error-handling idiom, module layout, test
  structure.
- Keep the code plain. A future reader should follow it without re-deriving your reasoning.
- Cover every case identified in step 2, not only the case the sketch showed.
- Extend the existing tests to cover the new cases. If the project has no tests, ask before
  introducing a test framework.

The diff is done when it satisfies the design from steps 2 and 3: every state has a home, every
invariant has a type behind it, and no leftover validation is doing a job a type should do.

## Language

This process is language-agnostic, the code is not. Write in the language of the input and match its
idioms — Rust enums with exhaustive `match`, TypeScript discriminated unions, Go interfaces with
explicit error returns, Haskell ADTs — rather than porting another language's style.
