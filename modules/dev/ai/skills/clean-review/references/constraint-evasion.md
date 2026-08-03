# Constraint evasion

Some code does not fail. It surrenders. A rule was in place, the rule was hard to satisfy, and the code found a way around the rule instead of through it.

This lens finds that code. It applies to code from an agent and to code from a tired human. The pattern is the same. The author met resistance and chose the cheap path.

Source of the categories below: Justin Le, "LLMs Will Cheese Your Types" (2026).

## Contents

- The verdict rule
- Signal words
- Suppression to reach a green build
- A type weaker than the plan
- Variant abuse
- Field abuse and sentinel values
- Resistance to a new type
- Defensive checks in place of a model
- Test evasion
- The unchanged-code hunt
- Language notes

## The verdict rule

Each pattern below is legal in the language. Each one is correct sometimes. That is what makes the lens necessary and what makes it dangerous.

Report every instance. Do not fix an instance on your own judgment. The default verdict is **not legitimate**, and the owner decides.

The reason is a base rate. The author reached for the pattern because it was cheap, not because the domain demanded it. A rare instance is justified. Most are not. You cannot tell the two apart from inside the same shortcut.

Write each finding as three lines.

1. The rule: what the document, the type, or the lint config asked for.
2. The evasion: what the code does instead, with the path and the line.
3. The cost: which invariant no longer holds.

## Signal words

Grep comments, commit messages, pull-request text, and any recorded agent transcript for these.

```bash
rg -ni 'simplest (approach|solution|way)|for now|to keep (it|things) simple|good enough|temporary|workaround|for expedience|too (invasive|risky|large) a change|avoid(s|ing)? (a )?breaking change'
```

A comment that explains why a rule was skipped is a confession. Treat it as a finding, not as documentation.

## Suppression to reach a green build

The author silenced the check rather than satisfied it.

Signals:

- A file-level or line-level suppression comment near a real error.
- A compiler warning turned off for one file, or a strict flag turned off in a config.
- A lint rule disabled repository-wide with no recorded reason.
- A test marked skip, or a build step marked continue-on-error.
- A dependency pinned back to dodge a stricter version.

Read the code the suppression covers. Ask which check the author could not pass. That answer is the real finding. The suppression is only the marker.

A suppression inside a type-level test is different. A test that proves the compiler rejects bad input needs the marker to pass. Leave it.

Fix, in order of preference:

1. Satisfy the check. Delete the suppression.
2. Narrow the type so the check no longer applies.
3. Keep the suppression, add one comment with the reason, and confine it to one adapter module.

## A type weaker than the plan

The plan record from Phase 1 named a type. The code uses a looser one.

Common trades:

| The plan asked for | The code uses | The lost rule |
|---|---|---|
| A non-empty collection | A plain list, plus an empty check | The collection cannot be empty |
| An unsigned or bounded number | A signed machine integer | The value cannot go below zero |
| A new variant in an existing union | A free string | The set of cases is closed |
| A structured record | A generic map, or a JSON blob | The field set is known |
| A domain type | The primitive inside it | Two unrelated values cannot be swapped |
| A narrow interface or constraint | A wider one that the type already met | The caller cannot do more than it needs |
| A separate type per state | One type with optional fields | Two states cannot mix |

The trade often follows a call. A callee returns a loose type, so the caller widens its own type to match. The loose type then spreads outward one function at a time. Trace it back to the first widening and fix it there.

Report the plan text and the code side by side. A change of plan is fine. An undiscussed change of plan is the finding.

## Variant abuse

A union or an enum gained a case in the domain but not in the code. The author packed the new case into an old one.

```ts
// The domain gained "invalid group". The error union did not.
return { kind: "unknownUser", message: `Invalid group: ${group}` };
```

Signals:

- An error or a result variant whose payload text describes a different case.
- A prefix or a tag inside a string that a consumer parses back out.
- A numeric code outside the documented range, such as a negative identifier.
- A generic variant such as `Other`, `Unknown`, or `Internal` that carries several distinct cases.
- A structured payload built to hold a value the variant does not mean.
- Two separate concepts that share one variant, told apart by string matching downstream.

Fix: add the variant the domain needs. Then follow the compiler to every consumer.

Prevention, and a fix worth proposing: remove the abusable field. A variant that holds a free string invites the next author to stuff it. A variant that holds a domain type does not.

## Field abuse and sentinel values

A record gained a meaning but not a field.

Signals:

- A list field with extra entries appended that mean something else, such as affiliations after author names.
- One field reused for a second purpose because it was free at the time.
- A field whose meaning depends on which code path wrote it.
- A magic value used in place of absence: minus one, zero, the epoch, an empty string, a maximum integer.
- Two callers that disagree about what a field holds.

Fix: add the field, or make absence explicit in the type. Then delete the checks that tested for the magic value.

A sentinel is worse than a wrong type, because every reader must remember it. An explicit absent case makes the compiler remind them.

## Resistance to a new type

The author widened a type instead of nesting one.

```haskell
-- Flat: every consumer must now ignore the cases it does not handle.
data Region = Canada | Mexico | Alaska | Arizona
```

```haskell
-- Nested: each function takes the exact set it handles.
data Region = Canada | Mexico | USState State
data State  = Alaska | Arizona
```

Signals:

- A union that grew cases from a second domain, flat, with no grouping.
- A function that accepts the wide type and returns a no-op for the cases outside its job.
- A dummy branch: an empty return, a `pass`, a zero, a log line, a `TODO`.
- A catch-all branch that forwards the value to another function which repeats the same match.
- A pattern match whose covered set grew rather than shrank as the value moved inward.

The rule: each function inward should cover **less**, not the same. A match that hands the whole wide type onward has moved no work.

Fix: group the new cases behind one variant. Give each function the narrow type it handles. Delete the no-op branches.

## Defensive checks in place of a model

The author added a check where a type or a data structure would have removed the question.

Signals:

- An absence check on a value that the caller already proved present.
- A predicate that asks about the shape of a value, then a cast, instead of one match.
- A duplicate filter over a list, where a set would hold the rule.
- A sort applied at every read because the order is not part of the type.
- A precondition assertion in a function body that repeats what the signature could state.
- A cast right after a check, in the same function.

Fix belongs to `type-modeling.md`. Parse once at the boundary. Pick the data structure that holds the rule. Then delete the checks.

## Test evasion

Signals:

- A test disabled, deleted, or marked skip in the same commit that changed the code it covered.
- Fixture data changed to match a new wrong output.
- An assertion loosened from an exact value to a type check, a truthiness check, or a range.
- Product code that inspects the environment and behaves differently under test.
- A test that asserts nothing, or asserts only that the call did not throw.
- A snapshot updated with no review of the diff.

Check the git log for these. The commit that weakened the test usually states the reason.

## The unchanged-code hunt

Evasion hides in code that did **not** change. A diff view highlights new lines. It cannot highlight a consumer that should have gained a case and did not.

Run this hunt whenever a union, an enum, or a record changed in recent history.

1. List the types that changed. Use `git log -p` over the type definitions.
2. For each type, grep the whole repository for consumers. Include tests, serializers, and generated code.
3. For each consumer, check whether it handles the new case. A catch-all branch hides the gap. So does a default value.
4. Report each consumer that ignores the new case.
5. Turn on the exhaustiveness check for that type, so the compiler runs this hunt next time.

Step 5 is the durable fix. See Phase 7 in SKILL.md.

## Language notes

The categories above apply to every stack. The mechanics differ.

| Stack | Suppression to look for | Exhaustiveness control | Common abusable field |
|---|---|---|---|
| TypeScript | `@ts-ignore`, `@ts-expect-error`, `as any`, `as unknown as`, a postfix `!`, `eslint-disable`, `strict: false` | A `never` assertion in the default branch, or the `switch-exhaustiveness-check` rule | `string`, `Record<string, unknown>`, `any` |
| Python | `# type: ignore`, `# noqa`, `cast(`, `Any` | `assert_never` in the final branch, with a strict checker | `dict`, `str`, `None` as a sentinel |
| Go | `//nolint`, a blank error assignment, `interface{}` | No language support. Use an exhaustive-switch linter | `interface{}`, `string`, a zero value |
| Rust | `unwrap`, `expect`, `#[allow(...)]`, `unsafe` | `match` is exhaustive already. Watch for a `_` arm | `String`, `Option` used as a flag |
| Haskell | `-Wno-incomplete-patterns`, a lint ignore pragma, `error`, `unsafeCoerce` | `-Werror=incomplete-patterns` | `String`, a JSON value, `Int`, an exception type |
| Java or C# | `@SuppressWarnings`, a raw cast, `dynamic`, a null-forgiving operator | A sealed hierarchy with a switch expression | `Object`, `String`, `Map` |

Two notes on Rust and Haskell. Exhaustive matching is the default, so the evasion moves into the wildcard arm and into the abusable payload. Grep for `_ =>` and `_ ->` beside a union that recently gained a case.

One note on Go and dynamic Python. Without exhaustiveness support, the compiler cannot run the unchanged-code hunt for you. Add a linter for it, or accept that the hunt is manual and record it in the project checklist.
