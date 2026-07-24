---
name: goodplan
description: >-
    Produces a thorough, stabilized implementation plan for a codebase change before any code is
    written — files touched, new files, edits, tech choices, and steps ordered by surface area, plus
    open decisions and risks. Use whenever the user asks for a plan, enters plan mode, or asks "how
    should I build/approach X" — especially for large, multi-step, or cross-cutting changes. This
    skill plans only; it never edits the codebase.
argument-hint: "<goal to plan>"
---

# goodplan

Plan a codebase change end-to-end, then stress-test the plan until it stops changing. This skill
only produces a plan — it makes no edits. Plan mode is expected and fine.

Prefer the smallest correct change that meets the goal (YAGNI): reach for the standard library and
existing patterns before new dependencies or abstractions, and don't plan extension points with no
second caller in sight. Where the change defines data, design types so illegal states are
unrepresentable rather than planning runtime guards to catch them later — correctness by
construction is cheaper to plan in than to retrofit.

## Repository orientation

Shallow directory map (falls back to `find` if `tree` is absent):

!`tree -L 2 -d --gitignore 2>/dev/null || find . -maxdepth 2 -type d -not -path '*/.*'`

Use this only to orient. Read the specific files a change touches in Step 0; don't assume structure
from the map alone.

## Workflow

Copy this checklist and tick items as you go:

```
Plan progress:
- [ ] Step 0: Gather — read the files the goal actually touches
- [ ] Step 1: Formulate — draft the plan
- [ ] Step 2: Red-team — find errors, hard spots, odd choices
- [ ] Step 3: Stabilize — revise; repeat 0–3 until no changes
- [ ] Step 4: Present — hand the user the plan
```

### Step 0 — Gather

Read the code relevant to the goal: the files that will change, their callers, the types and
interfaces at the boundary, and any existing pattern the change should match. Do not spawn agents to
do this unless the user explicitly asks — read the files directly.

### Step 1 — Formulate

Draft a plan covering:

- **Files edited** — each file and the nature of the edit
- **Files created** — each new file and its responsibility
- **Tech choices** — libraries, data shapes, key types/signatures, error model
- **Steps** — ordered by surface area (one coherent slice per step), each independently reviewable

Stop and ask the user before committing to a **high-leverage** decision — one that needs
understanding of the codebase and is expensive to reverse:

- Architecture: module boundaries, data flow, error model, public API shape
- Core logic: the algorithm behind a central component (not a routine caller of it)
- Cross-cutting changes spanning two or more parts of the system
- Genuine trade-offs: present the options, recommend one, and say why

Decide the rest yourself: filling registries/tables/enums, copying an existing shape, constant/ID
lookups, boilerplate, mechanical refactors, test scaffolding. One meaty decision surfaced to the
user beats a pile of trivial ones — don't hand over data entry.

### Step 2 — Red-team

Re-read the plan cold, adversarially, as if a different engineer wrote it and you must find what
they missed. You cannot literally erase your own context, so compensate by actively attacking the
plan rather than re-confirming it. Look for:

- Steps that won't work against the actual code (wrong assumption about an interface, a dependency
  that isn't there, an edit that breaks a caller not in the plan)
- Ordering hazards: a step that needs something a later step produces
- Illegal states or unhandled failures the design leaves open
- Odd choices that a reader would question, and hidden constraints that block the ideal approach

List every issue found. If you genuinely cannot get critical distance from your own plan, ask the
user whether to spawn a fresh sub-agent for an independent pass — do not spawn one on your own.

### Step 3 — Stabilize

Fold the Step 2 findings back into the plan, then run Step 2 again. Repeat Steps 0–3 until a full
pass produces no changes. Keep a record of the issues found and how each was resolved or mitigated —
the user sees these in the final plan, so they can judge the reasoning, not just the outcome.

### Step 4 — Present

Present the stabilized plan in the template below — readable by both a technical human and an agent
that will implement it. If the user accepts, follow their instructions for implementation (this
skill's job ends at the accepted plan).

## Plan template

```markdown
# Plan: [goal]

## Goal

[1–2 sentences: what changes and why.]

## Approach

[The chosen design in a short paragraph. Name the key types/interfaces and the error model.]

## Changes

**New files**

- `path` — [responsibility]

**Edited files**

- `path` — [what changes and why]

## Steps

1. [Surface-area slice] — [what, and how to verify it]
2. ...

## Decisions for you

- [Open high-leverage choice, options, recommendation + rationale. Omit if none.]

## Risks & mitigations

- [Issue surfaced in red-team → how the plan handles or accepts it.]

## Out of scope

- [What this plan deliberately does not do.]
```
