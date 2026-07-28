---
name: fleshout
description: >-
    Turn a code sample, git diff, scratch-pad notes, or half-formed guidance into a fully-fledged
    feature or program. Use this whenever the user hands over a rough sketch, stub, TODO-riddled
    diff, or "here's roughly what I'm thinking" note and wants it turned into real,
    production-quality code — even if they don't say "flesh this out" explicitly. Strong signals to
    trigger even without an explicit ask - the sketch implies more states/cases than it currently
    handles, a diff introduces a partial abstraction that isn't carried through the codebase,
    scratch notes describe a workflow bigger than the code shown, or the user's guidance clearly
    gestures at a feature while providing only fragments. Also trigger on explicit requests like
    "turn this into a feature," "make this a real implementation," "flesh this out," or "build this
    out properly." Do NOT trigger for small, self-contained requests (a single bug fix, a one-off
    script, "add a null check here") where there's no larger feature lurking — just do those
    directly.
---

# Flesh Out Feature

Turn rough material — a code sample, a `git diff`, scratch-pad notes, a verbal sketch — into a
complete, well-designed feature or program. The point isn't to mechanically expand what's there;
it's to figure out what the user is actually building and build it properly, in their style.

## Why this matters

Sketches and diffs are compressed. They show _an_ example of the shape, not the whole shape. A stub
function with one match arm handled usually means the author knows there are more arms coming but
hasn't written them yet. A scratch note like "also need to handle retries somehow" is a real
requirement wearing a hedge. Treating the input literally — implementing only what's shown, leaving
the rest as `TODO` — under-delivers. Treating it as license to invent whatever seems plausible
over-delivers in the wrong direction. The job is to read the shape correctly and ask when it's
ambiguous.

## Process

### 1. Gather everything available

Before writing anything, collect:

- The code sample / diff itself (`git diff`, `git diff --staged`, or a pasted snippet)
- Scratch-pad notes, TODOs, comments — these often contain the real intent
- The user's stated guidance, however informal
- If inside an existing project: read surrounding code to learn its conventions — naming, error
  handling style, module layout, how similar features are already structured. A new feature should
  look like it was written by the same person who wrote the rest of the codebase, not bolted on. See
  `references/convention-detection.md` for what to check and in what order (linter config, a
  representative existing feature, error handling idiom, module layout, naming, test style) rather
  than generalizing from whichever file happens to be open.

If any of this is missing and needed, ask for it rather than guessing blind (e.g. "do you have a
`git diff` for this, or should I look at the working tree directly?").

### 2. Identify the real shape of the feature

From the gathered material, work out:

- What states/cases does this actually need to handle? (Not just the one shown.)
- What's the data model? What invariants does it need to hold?
- What's explicitly out of scope, vs. just unwritten?

See `references/scope-signals.md` for a checklist and worked examples distinguishing "this sketch
implies more than shown" from "this really is just a small fix" — the calibration this step depends
on.

### 3. Design: parse, don't validate

Prefer types and structure that make invalid states unrepresentable over runtime checks scattered
through the logic. Concretely:

- Convert data into a well-typed shape _once_, at the boundary, and let the rest of the code trust
  that shape — don't re-check the same invariant deeper in the call stack.
- Use sum types / tagged unions / enums to represent "one of several known cases" instead of
  optional fields plus booleans that are only valid in certain combinations.
- Use newtype-style wrappers for values with invariants (a validated email, a non-empty list, a
  positive quantity) so the type itself carries the guarantee.
- Prefer exhaustive matching over `if/else` chains with a fallback — exhaustiveness checking catches
  missing cases at compile time instead of at 2am.

See `references/parse-dont-validate.md` for concrete patterns in TypeScript, Go, Rust, and Haskell —
pull the one matching the diff's language, or use it to translate the idea into whatever language is
in play.

### 4. Checkpoint at real decision points — always defer to the user

Stop and ask before proceeding whenever you hit something that isn't purely mechanical:

- **Architectural choices**: how a new concept fits into the existing module/type structure, which
  abstraction layer owns a new responsibility, whether to introduce a new type/trait/interface vs.
  extend an existing one.
- **Ambiguous scope**: a note or comment hints at behavior but doesn't pin it down (e.g. "handle
  retries somehow" — how many, backoff strategy, which errors are retryable?).
- **Trade-offs with no obviously-correct answer**: performance vs. simplicity, breaking an existing
  API vs. adding a parallel one, sync vs. async.
- **Anything that would be expensive to unwind** if guessed wrong — a schema shape, a public API
  surface, a persistence format.

Don't ask about mechanical steps (wiring up a function, matching existing naming conventions,
writing the obvious plumbing) — just do those. The point of asking is to protect the user's actual
decisions, not to offload every choice back to them.

When you do ask, be concrete: propose 2-3 real options with their trade-offs rather than an
open-ended "what do you want?" — the user is often mid-thought and a sharp menu is easier to answer
than a blank page. See `references/checkpoint-examples.md` for good vs. bad examples of how to
phrase these.

### 5. Implement

- Match existing project conventions exactly where they exist (formatting, error handling idioms,
  module layout, test structure).
- Keep the code plain and readable — no cleverness that doesn't earn its keep. A future reader
  (including the user) should be able to follow it without re-deriving your reasoning.
- Cover the cases identified in step 2, not just the one shown in the original sample.
- If tests exist in the project, extend them to cover the new cases. If none exist, don't invent a
  test framework unprompted — ask if the user wants tests added.

### 6. Review before handing back

Reread the diff against the design from step 2-3: does every state have a home, does every invariant
have a type backing it, is there dead-end validation logic that should have been a type instead? Fix
before presenting, don't ship a first draft.

## Language-agnostic, but grounded

This process applies across languages. When the input includes code, write all examples and
implementation in that language and match its idioms (Rust's `enum` + exhaustive `match`,
TypeScript's discriminated unions, Go's interfaces + explicit error returns, Haskell's ADTs, etc.)
rather than porting patterns from a different language's style.
