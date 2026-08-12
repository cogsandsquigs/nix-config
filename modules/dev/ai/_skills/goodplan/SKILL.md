---
name: goodplan
description: >-
    Produces a thorough, red-teamed implementation plan for a codebase change before any code is
    written: files edited, files created, tech choices, and the smallest ordered steps that get
    there, plus the open decisions and the risks found while attacking the draft. Use whenever the
    user asks for a plan, enters plan mode, or asks "how should I build X" or "how should I approach
    X", especially for large, multi-step, or cross-cutting changes. This skill plans only. It never
    edits the codebase.
argument-hint: "<goal to plan>"
---

# goodplan

Plan a codebase change, attack the draft, hand over the result. This skill makes no edits. Plan mode
is expected and fine.

## Two constraints

**The whole plan is the smallest edit that meets the goal.** Stop at the first option that works:
nothing to do, existing code in this repo, the standard library, an installed dependency, one line,
then new code. No new file where an edit to an existing one serves. No extension point without a
second caller in sight, and no config for a value that never changes. Where the change defines data,
design types so illegal states cannot be represented, instead of runtime guards that catch them
later.

**Each step is the smallest change with its own check.** Split a step until its description needs no
"and" and its check is one command or one observation. A step that cannot stand alone belongs merged
into its neighbor, not padded out.

**Each step is fully specified.** Small is not vague. The implementer must have no decision left to
make: give the exact location, the exact literal text of the edit, and the exact check command with
the result that means "passed". Two implementers who follow the step must produce the same diff.

Address a location as `path:symbol` -- the function, class, or named block the edit lands in, plus
the surrounding line quoted verbatim when the symbol holds more than one edit site. Line numbers
look precise and are not: step 2 shifts every number step 3 relies on, and the implementer is then
choosing between the number and the text. A symbol survives its own plan.

Ban these from a step: "update accordingly", "as needed", "handle errors", "adjust the callers",
"refactor X", "similar to Y", "etc.". Each one hides a decision. Name the callers. Name the error
and what happens to it. Write the shape you mean. If a detail is genuinely not yet decidable, that
is a step 1 question for the user or a "Decisions for you" entry, not a gap in a step.

**A check the implementer cannot run is not a check.** Run the checks you write, in this repo, as
you write them. If the environment cannot run them -- missing dependency, no database, no network --
say so in the plan and make the setup the first step, because a plan whose every check is
hypothetical is fiction with good posture. A check that compares against a baseline ("no new
failures") carries the baseline number you measured, not the phrase.

## Workflow

### Step 0 -- Gather

Read the files that change, their callers, the types at the boundary, and the existing pattern the
change should match. Never plan against a file you have not opened.

### Step 1 -- Formulate

Draft the files edited, the files created, the tech choices (data shapes, key signatures, the error
model), and the steps. Write each step from the file open in front of you, quoting the identifiers
and the surrounding lines it edits. A step written from memory of the codebase is where the wiggle
room gets in.

Stop and ask the user before a **high-leverage** decision, meaning one that needs understanding of
the codebase and is expensive to reverse: module boundaries, data flow, the error model, public API
shape, the algorithm behind a central component, a change that spans two or more parts of the
system, or a genuine trade-off. Give the options, recommend one, say why.

When there is no one to ask -- you are a subagent, a batch run, or the user is away -- do not stall
and do not silently pick. Write the question, the options and your recommendation into "Decisions
for you", then plan on your recommendation and say in the step that it rests on that answer. The
user reverses one section instead of re-reading the whole plan.

Decide the rest yourself: registries, tables, enums, constant and ID lookups, copying an existing
shape, boilerplate, mechanical refactors, test scaffolding. Do not hand back data entry.

### Step 2 -- Red-team

Read the draft cold and adversarially, as if another engineer wrote it and your job is to find what
they missed. Look for:

- Steps that will not work against the actual code: a wrong assumption about an interface, a missing
  dependency, an edit that breaks a caller the plan never mentions.
- Ordering hazards: a step that needs what a later step produces.
- Steps that are two steps, and lines the goal does not require.
- Any step where an implementer must decide something: an unnamed caller, an unspecified signature,
  an unstated location, a check with no pass condition, or a banned phrase from above.
- Illegal states or unhandled failures the design leaves open.

Then attack the plan against **itself**, which is the failure the first list misses. Take each
step's literal text and hold it against every other step that touches the same symbol: a test that
asserts what an earlier step's code cannot do, an import one step adds and another step's assertion
needs bound differently, a signature that drifts between the step that writes it and the step that
calls it. Each step can be perfectly specified and the set still contradict itself, and the
implementer then has to invent the tiebreak you were supposed to make.

List every issue. This is one pass, not a loop.

### Step 3 -- Fold in

Revise. Run step 2 again if the revision changed the approach, a boundary, the ordering, or the text
of a step another step depends on, because those invalidate steps the first pass approved. A
reworded risk note or a renamed variable does not. Stop at two passes. Anything still open becomes
an accepted risk.

"Risks & mitigations" is the record of both passes: each finding, and either the step that now
handles it or the reason it is accepted. The user judges the reasoning, not only the outcome.

### Step 4 -- Present

Fill `resources/plan-template.md` and present it. It reads for both a technical human and the agent
that will implement it. If the user accepts the plan, follow their instructions. This skill's job
ends at the accepted plan.
