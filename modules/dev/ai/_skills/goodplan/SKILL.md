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

## Constraints

**The whole plan is the smallest edit that meets the goal.** Stop at the first option that works:
nothing to do, existing code in this repo, the standard library, an installed dependency, one line,
then new code. No new file where an edit serves, no extension point without a second caller in
sight, no config for a value that never changes. Where the change defines data, design types so
illegal states cannot be represented, instead of runtime guards that catch them later.

**Each step is the smallest change with its own check.** Split until the description needs no "and"
and the check is one command or one observation. A step that cannot stand alone merges into its
neighbour rather than being padded out.

Repetition is where small and easy-to-follow fight, and there small loses. The same mechanical edit
across many sites is one step: state the edit once, name every site, check it. Prefer the single
check covering every site -- one command asserting all thirty-two commands carry the flag beats
thirty-two near-identical commands, and it catches the site you edited that was never on the list.
The moment one site takes a different edit it becomes its own step, because an exception buried in a
bundle costs the reader more than two plain steps ever would.

**Each step is fully specified.** Small is not vague. Give the exact location, the exact literal
text of the edit, and the exact check with the result that means "passed". Two implementers who
follow the step produce the same diff.

Address a location as `path:symbol`, the function, class or block the edit lands in. Line numbers
look precise and are not: step 2 shifts every number step 3 relies on, leaving the implementer to
choose between the number and the text. Where a symbol holds more than one edit site, and a long
function usually does, the anchor that matters is the surrounding line quoted verbatim; the symbol
only says which neighbourhood to search.

Something being added has no symbol to sit in yet, so address it by the neighbours it lands between:
`path: between <symbol A> and <symbol B>`. That is the form for a new function, class, method or
test, and equally for a declaration -- an import, a constant, an enum member, a route, a config key,
a table entry -- where position carries meaning the code does not state. Where the file has a
convention, name it and let the convention place the edit: alphabetical within the import block,
appended to the enum, grouped with the sibling it belongs to. Where it has none, say so and pick,
because "add a constant" leaves two implementers choosing differently.

Specification is proportional to the diff, not to the effort of finding it. When the change
collapses to a few lines because the repo already did the work, the plan collapses with it: name
what collapsed it and cut the rest. Quote a new file's body verbatim when it is short enough to read
in one sitting, such as a test module or a small config; when it is longer, give the exact public
surface -- every name, signature, and the assertions each part must satisfy -- and say that you did,
so the implementer knows the wording is theirs and the surface is not.

Ban from a step: "update accordingly", "as needed", "handle errors", "adjust the callers", "refactor
X", "similar to Y", "etc.". Each hides a decision. Name the callers, name the error and what happens
to it, write the shape you mean. A detail that is genuinely not decidable yet is a question for the
user or a "Decisions for you" entry, not a gap in a step.

**A check the implementer cannot run is not a check.** Run the checks you write, as you write them.
This skill still edits nothing: build the change in a scratch copy, run the checks there, record the
real output, discard the copy. That costs a planning run about what an implementation run costs, and
it is what separates a plan from a plausible document -- prototyping finds the defect reading
cannot, such as a test that cannot observe what the code it tests actually does. A baseline
comparison ("no new failures") carries the number you measured, the environment that produced it,
and how to enter that environment, since a bare `pytest` assumes a path the implementer may not
have. Write each check as they must type it, in the shell they use: `cmd; echo $?` is a syntax error
in fish. If a check cannot run at all, say so rather than dressing up a guess, and make setup the
first step when setup is the blocker.

## Workflow

### Step 0 -- Gather

Read the files that change, their callers, the types at the boundary, and the pattern the change
should match. Never plan against a file you have not opened. Hunt here for the capability the repo
already has, because that is where a plan collapses to one slice: the feature you were about to
build turns out to be one call to something already sitting there.

### Step 1 -- Formulate

Draft the files edited, the files created, the tech choices (data shapes, key signatures, the error
model), and the steps. Write each step from the file open in front of you, quoting the identifiers
and the surrounding lines it edits. A step written from memory of the codebase is where the wiggle
room gets in.

Stop and ask before a **high-leverage** decision, one that needs understanding of the codebase and
is expensive to reverse: module boundaries, data flow, the error model, public API shape, the
algorithm behind a central component, a change spanning two or more parts of the system, a genuine
trade-off. Give the options, recommend one, say why.

With no one to ask -- you are a subagent, a batch run, or the user is away -- do not stall and do
not silently pick. Put the question, the options and your recommendation in "Decisions for you",
plan on the recommendation, and say in the step that it rests on that answer. The user then reverses
one section instead of re-reading the whole plan.

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
  an unstated location, a check with no pass condition, or a banned phrase.
- Illegal states or unhandled failures the design leaves open.

Then attack the plan against **itself**, the failure the list above misses. Hold each step's literal
text against every other step that touches the same symbol: a test asserting what an earlier step's
code cannot do, an import bound one way and asserted another, a signature that drifts between the
step writing it and the step calling it. Every step can be perfectly specified and the set still
contradict itself, and the implementer then invents the tiebreak you owed them.

List every issue. One pass, not a loop.

### Step 3 -- Fold in

Revise. Run step 2 again if the revision changed the approach, a boundary, the ordering, or the text
of a step another step depends on, since those invalidate steps the first pass approved; a reworded
risk note does not. Stop at two passes. Anything still open becomes an accepted risk.

"Risks & mitigations" is the record of both passes: each finding, and either the step that now
handles it or the reason it is accepted. The user judges the reasoning, not only the outcome.

### Step 4 -- Present

Fill `resources/plan-template.md` and present it. It reads for both a technical human and the agent
that will implement it. If the user accepts the plan, follow their instructions. This skill's job
ends at the accepted plan.
