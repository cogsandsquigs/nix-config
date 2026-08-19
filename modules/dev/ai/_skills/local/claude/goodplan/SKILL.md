---
name: goodplan
description: >-
    Plans a codebase change as the smallest diff that meets the goal, then, after the user accepts
    the plan, implements and verifies it through agents: a cold agent red-teams the draft plan, one
    agent per step applies each edit (in parallel within a phase, for phased plans), and a cold
    verifier checks the finished diff against the plan's literal text. Use whenever the user asks
    for a plan, enters plan mode, or asks "how should I build X" or "how should I approach X",
    especially for large, multi-step, or cross-cutting changes. Nothing is edited before the user
    accepts the plan.
argument-hint: "<goal to plan>"
---

# goodplan

Plan a codebase change, have a cold agent attack the draft, get the user's acceptance, then drive
implementation through one agent per step and a cold verifier at the end. You are the orchestrator:
you own the plan, you talk to the user, and you launch the agents. Agents do the reading you would
be biased about, the edits you would be tempted to batch, and the checking you would be tempted to
wave through. Nothing touches the tree before the user accepts the plan; plan mode until then is
expected and fine.

The division of labour follows one rule: a fresh context is the only real cold read. You wrote the
draft, so you cannot red-team it -- you will read what you meant, not what you wrote. You watched
the implementation, so you cannot verify it -- you will check that the work you saw happen happened.
The red-team agent and the verifier agent exist to be the reader who was not in the room.
Implementers get one step each for the same reason in reverse: an agent holding the whole plan
drifts toward "while I'm here"; an agent holding one fully-specified step has nothing to drift to.

Every agent is bound by the Constraints below, but agents do not load this skill. Each role's
standing contract lives in `agents/` -- `red-team.md`, `implementer.md`, `verifier.md` -- written as
Claude Code agent definitions. Installed (copied into the project's `.claude/agents/`), they become
launchable agent types whose frontmatter enforces their tool limits: the verifier and red-team
genuinely cannot edit. Not installed, each file's body is the prompt: launch a general-purpose agent
with the body followed by the run-specific inputs the file names, and pass the `model` the file's
frontmatter declares as the launch option, since an uninstalled definition enforces nothing by
itself. The models are deliberately uneven: red-team inherits the session's model because attacking
a plan is the hardest reasoning in the pipeline, while implementer and verifier run on `sonnet`
because a fully-specified step and a literal-text audit are fidelity work, not judgment -- the
specification carries the intelligence.

Isolation is uneven for a reason too. The implementer and the red-team declare
`isolation: worktree`: the implementer because parallel siblings would otherwise fight over one
tree, and the red-team because its sharpest probe is applying the plan's code and building it, which
needs a tree it may wreck. The verifier deliberately has none. It audits the tree the user will
actually get, stray untracked files and build droppings included, and a pristine copy would hide
exactly the class of problem it exists to catch. The cost of a worktree is a cold build cache per
agent; where the build is expensive enough that this dominates, say so to the user rather than
quietly dropping the isolation.

Either way, never improvise a role's prompt -- the contract is the file. If no Agent tool exists at
all, play the roles yourself, inline and in order, and say so in the final report, since an inline
red-team and verify are warm reads and worth less.

## Constraints

**The whole plan is the smallest edit that meets the goal.** Stop at the first option that works:
nothing to do, existing code in this repo, the standard library, an installed dependency, one line,
then new code. No new file where an edit serves, no extension point without a second caller in
sight, no config for a value that never changes. Where the change introduces new data, design its
types so illegal states cannot be represented, instead of runtime guards that catch them later --
but restructuring types that already exist is its own decision, and usually its own plan.

**Touch nothing the goal does not name.** Reading the codebase surfaces things worth fixing -- dead
code, a bad name, a lint warning, a bug in a neighbouring function. None of it enters a step. Each
goes to "Out of scope" as one sentence, where the user can promote it to its own task. A cleanup
riding inside a feature plan doubles the review surface and, when something breaks, hides which
change broke it. The test for every step and every edited file: name the sentence of the goal it
serves. No sentence, no step.

**Each step is the smallest change with its own check, and ends in its own commit.** Split until the
description needs no "and" and the check is one command or one observation. A step that cannot stand
alone merges into its neighbour rather than being padded out.

Commit a step once its check passes, and never before. A green step is then a fixed point: a later
step that goes wrong reverts to a known-good tree, instead of leaving a half-applied mixture of two
steps to unpick by hand. A step whose check fails is not committed -- fix it or revert it, then
re-run the check. Take the message format from the repo's own history rather than inventing one, and
stop at the commit, since pushing is the user's call and not the plan's. (In a phased plan the
committing unit is the phase, not the step -- see below -- and this rule then governs each
implementer's isolated worktree instead of the shared tree.)

Repetition is where small and easy-to-follow fight, and there small loses. The same mechanical edit
across many sites is one step: state the edit once, name every site, check it. Prefer the single
check covering every site -- one command asserting all thirty-two commands carry the flag beats
thirty-two near-identical commands, and it catches the site you edited that was never on the list.
The moment one site takes a different edit it becomes its own step, because an exception buried in a
bundle costs the reader more than two plain steps ever would.

**A large plan is phased; a small plan stays flat.** A phase is an ordered group of steps holding
four invariants. Within a phase, every step is independent of every other and their edit sites are
disjoint -- no shared file region, no step needing what a sibling produces -- so any subset lands in
any order without conflict. Across phases, each phase depends on the one before it. Every phase ends
with the tree green and measurably closer to the goal: a phase has its own check, named in the plan,
and "compiles half-refactored" is not a phase boundary. The committing unit is the phase, one commit
each, so the known-good fixed points are phase boundaries.

Derive phases rather than invent them. Write the steps' dependencies as one line per step --
`S2: S3   # short label` -- into a file next to the plan, and run
`python scripts/phase_sort.py <deps-file>` (execute it; there is no need to read it). It emits the
partition, one `P<n>:` line per phase, or rejects the graph with the reason: a cycle, an undeclared
step, a self-loop, or a dependency list whose members depend on each other, which means the listed
edge is redundant and the graph is not transitively reduced. Fix the declarations and re-run until
it emits; the partition it prints is the plan's, not one you eyeball. What the script cannot see is
the tree: two steps in one emitted phase whose edits touch the same file region are not disjoint --
give one a dependency on the other, re-run, and let it sink a phase. Paste both the declarations and
the emitted partition into the plan, so the red-team and the verifier can re-run the same
derivation.

Phase only when the partition earns it, and the bar is higher than one multi-step phase. Read the
emitted partition and ask what the edges are made of. An edge you added because two steps touch the
same region of one file is not a dependency -- it is the work being concentrated, and concentrated
work does not parallelise however the graph is drawn. When most phases hold a single step, or most
edges are file-collision rather than logic, the partition is telling you the change lives in two or
three files: go flat, one commit per step, and take the bisect granularity instead. Phasing pays
when the work spreads wide -- a migration across forty call sites, a change touching a dozen modules
-- because that is when a phase holds enough independent steps for parallel implementers to be worth
the assembly. The price of phasing is that granularity: a failing phase names a group, not a step.
What buys it back is that every step still carries its own check, run in isolation before the phase
ever assembles.

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

A step that meets this bar, whole:

> **3. Reject zero-quantity order lines at parse time**
>
> - Edit: `src/orders/parse.py:parse_line` -- after the line `qty = int(fields[2])`, insert:
>   `if qty == 0: raise OrderError(f"zero quantity in line {line_no}")`
> - Check: `pytest tests/test_parse.py -k zero_quantity` -- 1 passed (test added in step 2)
> - Commit: `orders: reject zero-quantity lines at parse`

Every question an implementer could ask is pre-answered: where, what text, which check, what
"passed" prints, what to commit. "Validate quantities properly in the parser" is the same step with
all five answers missing.

**A check the implementer cannot run is not a check.** Run things, as you write them. Reading tells
you what the code says; only running tells you what it does, and the gap between those two is where
plans quietly become fiction -- a test that cannot observe what the code it tests actually does, a
library helper that under-reports, a validator that accepts what the parser then rejects.

Probe the claim, not the change, and prefer the cheapest thing that could prove you wrong: a few
lines in a scratch script, one invocation of the real command, a grep for the name you assume is
free. Most assumptions are about code that already exists, so most probes need no copy of anything.
Take a baseline number by running the existing suite where it stands, and check the tree afterwards,
since a test run drops caches the repo may not ignore. Build the change in a scratch copy only when
the claim is genuinely about the whole tree -- the suite count afterwards, the type checker, the
formatter -- and nothing smaller can settle it, then discard the copy. The repository itself stays
untouched either way.

A baseline comparison ("no new failures") carries the number you measured, the environment that
produced it, and how to enter that environment, since a bare `pytest` assumes a path the implementer
may not have. Write each check as they must type it, in the shell they use: `cmd; echo $?` is a
syntax error in fish. If a check cannot run at all, say so rather than dressing up a guess, and make
setup the first step when setup is the blocker.

**The plan's last step is the acceptance check**: one command or observation, run against the
finished tree, whose passing means the goal is met. Per-step checks prove each edit landed; only
this proves the set of steps is sufficient. It is also the yardstick for cutting: a step whose
removal would still leave the acceptance check passing was never needed. Write it before writing the
steps, since knowing what "done" looks like is what keeps the steps from wandering past it.

Then **run it against the tree as it stands today, where it must fail**, and put that failure in the
plan next to the expected pass. An acceptance check that already passes is measuring something other
than the goal, and you would not find out until the whole plan had been implemented against it. This
is also what stops the easy fraud of a suite-count check: "the tests pass" passes with the feature
stubbed out, so the number has to move for a reason only the goal can supply, and seeing it fail
first is the proof that it does.

**A check that cannot fail is not a check either.** Before writing a check down, name what would
have to be wrong for it to go red, and satisfy yourself that the step could actually produce that.
The common counterfeit is a check that watches the wrong thing: a compile that would succeed with
one of three call sites missed, a test asserting a function returns `Ok` when the interesting part
is _what_ it returned, a grep for a string the previous step already added. Where the honest answer
is that nothing cheap can fail here, say so in the step rather than dressing up a command that
always goes green.

## Workflow

Copy this checklist and keep it current through the run; it is the record of where the run stands
when a stage goes sideways:

```
Run progress:
- [ ] 1 Gather: files opened, existing capability hunted
- [ ] 2 Formulate: acceptance check written AND seen to fail on today's tree; draft in temp file
- [ ] 3 Red-team: cold agent findings returned and checked against the code
- [ ] 4 Fold in: revisions done (fresh cold pass if structure changed; max 2)
- [ ] 5 Gate: plan presented, USER ACCEPTED (hard stop until then)
- [ ] 6 Apply: base ref recorded, baseline re-measured; flat: steps 1..N green, one commit each /
      phased: each phase assembled conflict-free, phase check green, one commit each
- [ ] 7 Verify: cold verifier CLEAN, acceptance check green, report sent
```

### Stage 1 -- Gather

If not already in plan mode, enter it now (EnterPlanMode) so nothing gets edited while planning.

Read the files that change, their callers, the types at the boundary, and the pattern the change
should match. Never plan against a file you have not opened. Hunt here for the capability the repo
already has, because that is where a plan collapses to one slice: the feature you were about to
build turns out to be one call to something already sitting there.

When the goal is wide, launch Explore agents in parallel to map callers, conventions, and prior art.
Their maps tell you where to read; they do not replace reading. The steps you write quote literal
lines, and only your own open file supplies those.

### Stage 2 -- Formulate

Write the acceptance check first, and run it now, against the untouched tree, to watch it fail. Then
draft the files edited, the files created, the tech choices (data shapes, key signatures, the error
model), and the steps that reach it. Write each step from the file open in front of you, quoting the
identifiers and the surrounding lines it edits. A step written from memory of the codebase is where
the wiggle room gets in.

Stop and ask before a **high-leverage** decision, one that needs understanding of the codebase and
is expensive to reverse: module boundaries, data flow, the error model, public API shape, the
algorithm behind a central component, a change spanning two or more parts of the system, a genuine
trade-off. Give the options, recommend one, say why.

With no one to ask -- you are an agent yourself, a batch run, or the user is away -- do not stall
and do not silently pick. Put the question, the options and your recommendation in "Decisions for
you", plan on the recommendation, and say in the step that it rests on that answer. The user then
reverses one section instead of re-reading the whole plan.

Decide the rest yourself: registries, tables, enums, constant and ID lookups, copying an existing
shape, boilerplate, mechanical refactors, test scaffolding. Do not hand back data entry.

Finish by filling `resources/plan-template.md` and writing the draft to a file **outside the
repository** (a temp path), so agents can read it by path and no probe or check ever sees an
untracked plan file in the tree.

### Stage 3 -- Red-team

Launch one red-team agent (`agents/red-team.md`) with the plan path and the goal. It reads the draft
cold, holds each claim against the actual code, and returns numbered findings. You wrote the draft,
so this read is the one you cannot do: you would see what you meant. For a cross-cutting change,
launch a second red-team agent in the same turn with its focus narrowed to scope -- steps the
acceptance check does not need, files no sentence of the goal names.

Scale the review to the change, not to the ceremony. A cold pass costs real tokens -- it reads the
files, applies the plan, and builds it -- so a two-step plan against one file gets one agent, and a
plan that reshapes a module boundary gets the scope agent alongside. What never scales down is
having _someone else_ read it: the cheapest useful review is still a fresh context, and reviewing
your own draft to save an agent is the one economy that buys nothing.

Findings come back as claims, not verdicts. Before folding one in, check it against the file it
cites; a red-team agent can be wrong, and a fix for a phantom finding is scope creep with an alibi.

### Stage 4 -- Fold in

Revise. Launch a fresh red-team agent if the revision changed the approach, a boundary, the
ordering, or the text of a step another step depends on, since those invalidate steps the first pass
approved; a reworded risk note does not. Fresh agent, not the same one continued: the second pass
should be as cold as the first. Stop at two passes. Anything still open becomes an accepted risk.

A pass that cuts or adds a step leaves the plan renumbered: close the gap, put the steps back in
ascending order in the document, redraw the dependency declarations, and re-run `phase_sort.py`. A
hole at step 6 makes an implementer stop and wonder which step they were not given, and a plan that
prints step 8 after step 9 invites reading them in that order. Cutting a step also frees its
dependents, so the partition after a cut is rarely the partition before it.

"Risks & mitigations" is the record of both passes: each finding, and either the step that now
handles it or the reason it is accepted. The user judges the reasoning, not only the outcome.

### Stage 5 -- Present and gate

Present the plan (ExitPlanMode where it exists). It reads for both a technical human and the agents
that will implement it. **Nothing is implemented until the user accepts.** This gate is the whole
reason "Decisions for you" exists; skipping it decides those questions by default. If the user edits
the plan, fold the edits in, and a structural edit -- a boundary, the ordering, a step's literal
text -- earns one more cold red-team pass before implementation.

If the user accepts the plan but not the implementation, stop here: the accepted plan is a complete
deliverable on its own.

### Stage 6 -- Apply

Record the base ref first: `git rev-parse HEAD`. The verifier needs the before-tree, and so do you
if the run goes wrong.

Then re-run the plan's baseline measurement and the acceptance check before any agent starts. The
baseline was taken at Stage 2 and the user may have sat on the plan for a day; if the number has
moved, every "no new failures" in the plan is comparing against a tree that no longer exists, and
the acceptance check may even pass already because someone else did the work. A moved baseline is
not a blocker -- it is a number to refresh in the plan, and a question about whether the goal still
stands, which is the user's to answer if the move is large.

Every implementer works in its own worktree and commits there, so both modes below are the same loop
-- launch, collect, bring the branch home -- and differ only in how many run at once and what
carries the commit. Each launch carries only: the step's literal text, the repo path, the commit
message, and the plan's environment line. Not the whole plan. An agent holding one step has nothing
to drift to; an agent holding the plan starts helping. The plan's final acceptance step gets no
implementer -- it edits nothing and belongs to the verifier.

**Flat plan.** One implementer per step, **sequentially and in plan order**: each step's check
assumes the tree its predecessors committed, so there is no parallelism the plan has not declared.
Its worktree branches from the current HEAD, so when it reports green its branch is one commit ahead
and merges home as a fast-forward, carrying the implementer's own commit and message intact.
Fast-forward, then launch the next step.

**Phased plan.** Take the phases strictly in order; within a phase, launch all of its implementers
at once, one per step. Each follows its normal contract inside its worktree: edit, check, commit on
green on its own branch. Because they all branched from the same base, none of them fast-forwards;
when every step in the phase reports green, assemble with `git merge --squash` per branch in plan
order, expecting **zero conflicts** -- the plan claimed the steps disjoint, so a conflict is not a
merge problem but a falsified plan; stop, drop the phase's merges, and re-plan the phase, which is a
structural change and earns a cold red-team pass. After all branches assemble, run the phase's check
against the combined tree, and on green make the phase's one commit. A red step does not block its
siblings -- their worktrees are untouched; fix the one step's text, relaunch just it, and assemble
when all are green.

An implementer that reports failure has already restored its tree to the commit it started from.
Diagnose from its report: if the step was wrong, fix the step's text, re-check any step that depends
on that text, and relaunch fresh. A step that fails twice goes to the user with both reports. Never
patch the tree yourself between steps -- every edit goes through a step and an implementer, so the
history the verifier reads stays plan-shaped.

Collect each report's "noticed, not touched" list; it lands in Out of scope.

### Stage 7 -- Verify

Launch one verifier agent (`agents/verifier.md`) with the plan path and the base ref. It is cold and
edit-less for the same reason the red-team was: you watched the implementation, so you would verify
your memory of it. It checks the commit sequence against the plan's committing units -- steps in a
flat plan, phases in a phased one -- each commit's diff against the literal text of the step or
phase it claims, hunts for hunks no step names, and runs the acceptance check.

A reported deviation is handled like a failed step: revert the offending commit, tighten the step
text that left the wiggle room, relaunch an implementer, and verify again with a fresh verifier. A
deviation is accepted only by the user, never by you. Done means: verifier clean, acceptance check
green. Report to the user: the diff stat, the commit list, the verifier's verdict, and the Out of
scope list -- including anything implementers noticed but did not touch.
