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
make: give the exact path, the exact symbol, the exact signature or literal text of the edit, the
exact insertion point, and the exact check command with the result that means "passed". Two
implementers who follow the step must produce the same diff.

Ban these from a step: "update accordingly", "as needed", "handle errors", "adjust the callers",
"refactor X", "similar to Y", "etc.". Each one hides a decision. Name the callers. Name the error
and what happens to it. Write the shape you mean. If a detail is genuinely not yet decidable, that
is a step 1 question for the user or a "Decisions for you" entry, not a gap in a step.

## Repository orientation

Shallow directory map, falling back to `find` when `tree` is absent:

```!
tree -L 2 -d --gitignore 2>/dev/null || find . -maxdepth 2 -type d -not -path '*/.*'
```

Use this only to orient. If the map is empty or reports that shell execution was disabled, run the
command yourself. Structure comes from the files you read in step 0, not from the map.

## Workflow

Copy this checklist and tick items as you go:

```text
Plan progress:
- [ ] Step 0: Gather -- read the files the goal actually touches
- [ ] Step 1: Formulate -- draft the plan
- [ ] Step 2: Red-team -- attack the draft and list every issue
- [ ] Step 3: Fold in -- revise, and re-attack only if the revision was structural
- [ ] Step 4: Present -- hand the user the plan
```

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
  an unstated insertion point, a check with no pass condition, or a banned phrase from above.
- Illegal states or unhandled failures the design leaves open.

List every issue. This is one pass, not a loop.

### Step 3 -- Fold in

Revise. Run step 2 again only if the revision changed the approach, a boundary, or the ordering,
because a structural change can invalidate steps the first pass approved. Stop at two passes.
Anything still open becomes an accepted risk. Keep the record of what each pass found and how it was
resolved: the user judges the reasoning, not only the outcome.

### Step 4 -- Present

Fill `resources/plan-template.md` and present it. It reads for both a technical human and the agent
that will implement it. If the user accepts the plan, follow their instructions. This skill's job
ends at the accepted plan.
