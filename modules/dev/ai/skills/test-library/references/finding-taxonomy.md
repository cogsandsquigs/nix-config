# Finding taxonomy

Use these categories and severities. The findings then stay comparable across runs and across subjects.

## Contents

- Categories (MISCONCEPTION, TYPE-SAFETY, BEHAVIOR, EDGE-CASE, ERGONOMICS, COMPREHENSION, DIAGNOSTIC, DISCOVERABILITY, DIVERGENCE)
- Severity (CRITICAL, HIGH, MEDIUM, LOW)
- Attribution (subject defect, agent artifact, infra artifact)
- Dimension ratings and their anchors from 1 to 5
- Finding format

## Categories

**MISCONCEPTION.** The explorer formed a wrong mental model and the subject did nothing to correct it. Examples: a wrong idea about what a function does, when it runs, what it owns, whether it changes its input, or what a name means. The fix is usually a name or a doc. Sometimes the concept itself needs a new design.

**TYPE-SAFETY.** The type system failed in one of two directions. In an untyped language, read the boundary validation in its place.

- *Permissive.* Invalid usage compiled. In the worst case it also ran without a complaint.
- *Obstructive.* Valid usage did not compile, or compiled only behind a cast. Every escape hatch in the code of the explorer is a candidate here.

A language without static types shows the same two directions at run time. Permissive means that the subject accepted invalid input and carried it deep before the failure. Obstructive means that validation rejected legitimate input. A stack trace through the internals of the subject is a permissive failure. It is not a diagnostic failure.

**BEHAVIOR.** The subject did something that the explorer could not predict from the public surface. Examples: a silent failure, a swallowed error, or a surprising default. Also hidden global state, a side effect at import time, or a change to data that the caller owns.

**EDGE-CASE.** The subject breaks or changes behavior at a boundary that the docs never state. Examples: empty input, null or undefined, zero and negative values, integer limits, unicode, very large collections, reentrancy, and concurrent use.

**ERGONOMICS.** The work succeeded, but it cost too much. Examples: boilerplate with no intent, or a required option that could have a default. Also awkward composition, and repetition that the API could absorb. Also imports spread across many entry points.

Order dependence belongs here. Write it as ERGONOMICS, order dependence. A required call order that nothing states costs the newcomer time, and the types could carry the rule instead. Raise it out of ERGONOMICS when the wrong order gives a wrong result without an error. That case is BEHAVIOR, silent, and it is HIGH at the least.

**COMPREHENSION.** The explorer could not tell what something does from the available material. Examples: an undocumented public member, or a doc comment that repeats the signature. Also a missing unit or range, and unstated throw or async behavior. Also no sign of which function to pick among several similar ones.

**DIAGNOSTIC.** An error message failed to lead to the fix. Examples: an error at the wrong call site, a wall of expanded conditional types, and a "not assignable to" message with no named property.

**DISCOVERABILITY.** The right API exists, but the explorer never found it, or found it late. Phantom APIs belong here. A phantom API is a name that the explorer reached for and that does not exist. Those names show what users expect the thing to be called.

**DIVERGENCE.** Module mode only. The explorer used the module in a way that the repository does not. The gap says that the idiom lives in the call sites and not in the surface. A rule that the call sites carry in a comment is the clearest case. Move that rule into the types, or into the doc comments of the module. This category feeds the divergence table of the report.

## Severity

**CRITICAL.** The fault gives wrong results in silence, loses data, or opens a security problem, and the user gets no signal. This level also covers a subject that nobody can use for a stated core case without a read of the source.

**HIGH.** The fault costs a newcomer a lot of time, or leads to code that is wrong and that the newcomer will ship. A reasonable first approach that compiles and then misbehaves in silence is HIGH at the least.

**MEDIUM.** Real friction, with a workaround that the explorer found alone. Confusing, but recoverable.

**LOW.** Polish. A name to improve, a doc comment that could say more, or minor boilerplate.

Judge severity from the position of the newcomer, not from the position of the maintainer. The statement "nobody would do that" lowers the level only when the API made that path clearly wrong.

## Attribution

For each finding, decide whether a competent person would hit the same problem.

- **Subject defect.** A reasonable mistake, given the names, the types, and the docs on offer. The subject owns it, even when a careful reader could avoid it.
- **Agent artifact.** The explorer misread something plain, or invented it. This is not a defect of the subject. Note it apart if it has interest. Otherwise drop it.
- **Infra artifact.** A dead service, a wrong resource configuration, or missing seed data blocked the explorer. This is yours, not the subject's. Fix the setup and run that milestone again, or leave it out.
- **Uncertain.** Mark it and give the reason. This is better than a guess.

One check helps. Look for the same mistake twice in the journal, or a mistake made after a correction. Either pattern points to the subject.

## Dimension ratings

Rate each dimension from 1 to 5. Add one line of reason. Use these anchors.

**Discoverability.** Could the explorer find the right API?

- 1: the explorer needed the source to find core functionality
- 3: the explorer found it in the end, through completions or trial and error
- 5: the intended path was the first thing that the explorer reached for

**Type guidance.** Did the types, or the boundary validation, lead to correct usage? Use N/A only when the subject has neither.

- 1: wrong code compiled with no complaint
- 3: the types caught mistakes but did not point to the fix
- 5: the types made the wrong thing hard to write and the right thing plain

**Diagnostics.** Did the errors lead to fixes?

- 1: the errors pointed somewhere else, or were unreadable walls of types
- 3: readable, but the reader had to interpret them
- 5: the message named the fault and implied the correction

**Documentation.** Was the shipped doc surface enough?

- 1: public members have no docs, or the docs repeat the signature
- 3: the docs cover the happy path and say nothing about edges and errors
- 5: units, defaults, throw behavior, and cross-references are all present

**Ergonomics.** Was the effort in proportion to the task?

- 1: heavy ceremony, order rituals, repetition
- 3: reasonable, with some boilerplate to remove
- 5: short, composes well, good defaults

**Escape hatches.** How often did the explorer fight the abstraction?

- 1: a cast or access to the internals was needed to finish a milestone
- 3: one or two suppressions on legitimate goals
- 5: none needed

Report each rating apart from the others. Do not average them into one number. An aggregate hides the information that the author needs.

Mark a dimension N/A when the language or the shape of the subject makes it inapplicable. Add a one-line reason. Do not give a low score in that case. A low score says that the subject did badly at something it attempted. N/A says that the question does not apply. A mix of the two makes untyped libraries look worse than they are. It also makes the ratings incomparable across runs.

## Finding format

```
### F3 — [TYPE-SAFETY / permissive] HIGH — attribute filter accepts unmodeled keys
Evidence:  journal.md L84-91 — explorer wrote `.where({ emial: "x" })`, expected a type error, got none
Ground truth: src/query.ts:212 — `where` takes `Partial<Record<string, unknown>>`, so key typos pass and match nothing at run time
Impact:    the query returns empty. Nothing points to the typo
Fix:       constrain the key parameter to `keyof InferAttrs<S>`. Typos then fail at compile time
Confidence: high — the explorer hit this twice, the second time after it saw the empty result
```
