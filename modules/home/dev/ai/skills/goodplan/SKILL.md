---
name: goodplan
description: >-
  Produces a thorough, red-teamed implementation plan for a codebase change before any code is
  written: files edited, files created, tech choices, and steps ordered by surface area, plus the
  open decisions and the risks found while attacking the draft. Use whenever the user asks for a
  plan, enters plan mode, or asks "how should I build X" or "how should I approach X", especially
  for large, multi-step, or cross-cutting changes. This skill plans only. It never edits the
  codebase.
argument-hint: "<goal to plan>"
---

# goodplan

Plan a codebase change end to end, attack the draft, then hand over the result. This skill produces
a plan and makes no edits. Plan mode is expected and fine.

Prefer the smallest correct change that meets the goal. Reach for the standard library and existing
patterns before new dependencies or abstractions, and do not plan extension points that have no
second caller in sight. Where the change defines data, design types so illegal states are
unrepresentable instead of planning runtime guards to catch them later. Correctness by construction
is cheaper to plan in than to retrofit.

## Operating rules

- Plan only what the goal requires. A plan that quietly widens scope costs the user more than one
  that asks.
- Keep the plan as long as the change needs and no longer. Every section must carry information the
  implementer does not already have.

## Repository orientation

Shallow directory map, falling back to `find` when `tree` is absent:

```!
tree -L 2 -d --gitignore 2>/dev/null || find . -maxdepth 2 -type d -not -path '*/.*'
```

Use this only to orient. If the map above is empty, or reports that shell execution was disabled by
policy, run that command yourself before you start. Read the specific files the change touches
during step 0, and do not infer structure from the map alone.

## Workflow

Copy this checklist and tick items as you go:

```
Plan progress:
- [ ] Step 0: Gather — read the files the goal actually touches
- [ ] Step 1: Formulate — draft the plan
- [ ] Step 2: Red-team — attack the draft and list every issue
- [ ] Step 3: Fold in — revise, and re-attack only if the revision was structural
- [ ] Step 4: Present — hand the user the plan
```

### Step 0 — Gather

Read the code the goal touches: the files that will change, their callers, the types and interfaces
at the boundary, and any existing pattern the change should match. Never plan against a file you
have not opened.

### Step 1 — Formulate

Draft a plan covering:

- **Files edited** — each file, and the nature of the edit.
- **Files created** — each new file, and its responsibility.
- **Tech choices** — libraries, data shapes, key types and signatures, the error model.
- **Steps** — ordered by surface area, one coherent slice per step, each independently reviewable.

Stop and ask the user before committing to a **high-leverage** decision, meaning one that needs
understanding of the codebase and is expensive to reverse:

- Architecture: module boundaries, data flow, error model, public API shape.
- Core logic: the algorithm behind a central component, as opposed to a routine caller of it.
- Cross-cutting changes that span two or more parts of the system.
- Genuine trade-offs. Present the options, recommend one, and say why.

Decide the rest yourself: filling registries, tables, and enums, copying an existing shape, constant
and ID lookups, boilerplate, mechanical refactors, test scaffolding. One meaty decision surfaced to
the user beats a pile of trivial ones. Do not hand back data entry.

### Step 2 — Red-team

Read the draft cold and adversarially, as if a different engineer wrote it and your job is to find
what they missed. You cannot erase your own context, so compensate by attacking the plan rather than
re-confirming it. Look for:

- Steps that will not work against the actual code: a wrong assumption about an interface, a
  dependency that is not there, an edit that breaks a caller the plan never mentions.
- Ordering hazards: a step that needs something a later step produces.
- Illegal states or unhandled failures the design leaves open.
- Odd choices a reader would question, and hidden constraints that block the ideal approach.

List every issue found. This is one pass, not a loop.

### Step 3 — Fold in

Fold the step 2 findings into the plan. Run step 2 a second time only if the revision changed
something structural — the approach, a boundary, or the ordering — because a structural change can
invalidate steps the first pass approved. A wording fix or an added risk note does not earn a second
pass. Stop at two passes. Anything still unresolved goes into "Risks and mitigations" as an accepted
risk, not into a third sweep.

Keep the record of what each pass found and how it was resolved. The user sees these in the final
plan and judges the reasoning, not only the outcome.

### Step 4 — Present

Present the plan in the template below, readable by both a technical human and an agent that will
implement it. If the user accepts it, follow their instructions for implementation. This skill's job
ends at the accepted plan.

## Plan template

```markdown
# Plan: [goal]

## Goal

[1–2 sentences: what changes, and why.]

## Approach

[The chosen design in a short paragraph. Name the key types and interfaces, and the error model.]

## Changes

**New files**

- `path` — [responsibility]

**Edited files**

- `path` — [what changes, and why]

## Steps

1. [Surface-area slice] — [what, and how to verify it]
2. ...

## Decisions for you

- [Open high-leverage choice, the options, and a recommendation with its rationale. Omit if none.]

## Risks & mitigations

- [Issue found in red-team → how the plan handles it, or why it is accepted.]

## Out of scope

- [What this plan deliberately does not do.]
```
