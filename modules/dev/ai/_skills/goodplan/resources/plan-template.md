# Plan: [goal]

## Goal

[1-2 sentences: what changes, and why.]

Done when: `[the acceptance check -- one command or observation, and the result that means the
goal is met. The final step runs it.]`

Fails now: `[the same command run against the tree before any step, and what it prints. A check
that already passes is measuring something other than the goal.]`

## Approach

[The design in a short paragraph. Name the key types, interfaces, and the error model, and say why
this is the smallest edit that meets the goal.]

## Changes

**New files**

- `path` -- [responsibility]

**Edited files**

- `path` -- [what changes, and the sentence of the goal it serves]

## Steps

One atomic edit per step, specified so that two implementers produce the same diff. Flat plan:
every step ends in a commit, made only once its check passes. Phased plan: group the steps under
phases as below -- steps within a phase are mutually independent with disjoint edit sites, run in
parallel, and the phase makes the one commit once every step and the phase check are green.

```
Dependencies (input to scripts/phase_sort.py):
S1:            # [label]
S2: S1         # [label]
...
Partition (its output, verbatim):
P1: S1
P2: S2, ...

Phase 1: [name -- what the tree can do after this phase that it cannot do now]
- Phase check: `[command]` -- [the result that means the phase landed]
- Commit: `[message]` -- one for the phase.
- Steps: [as numbered below, each still carrying its own edit and check; the per-step Commit
  line is omitted, since the phase commits]
```

Checks below were run with: [interpreter and version, the dependencies that matter, anything that
was missing. Stated once here, not repeated per step.]

1. **[what this step does]**
    - Edit: `path:symbol` -- [the exact change: literal before and after text, and the quoted line
      it lands next to when the symbol holds more than one edit site]
    - Edit, for anything new: `path: between <symbol A> and <symbol B>` -- [the literal text to
      insert, and the convention that fixes its position if the file has one]
    - Check: `[command]` -- [the result that means it passed, with the baseline number if the result
      is a comparison. Say "not run: [why]" if the environment could not run it.]
    - Commit: `[message in this repo's own format]` -- after the check above passes, not before.

2. **[the same mechanical edit, repeated across sites]**
    - Edit, written once: [the literal before and after text]
    - Sites: `path:symbol` -- [quoted anchor line]; `path:symbol` -- [quoted anchor line]; ...
    - Check, one per site: `[command]` -- [the result that means it passed]
    - Commit: `[message]` -- one commit for the whole bundle; it is one step.

3. ...

N. **Acceptance check** -- run the "Done when" command against the finished tree; [the result that
   means the goal is met]. No commit; nothing changes in this step.

## Decisions for you

- [Open high-leverage choice, the options, and a recommendation with its rationale. Say which steps
  rest on the recommendation. Omit the section if there are none.]

## Risks & mitigations

- [Red-team finding, from either pass -> the step that now handles it, or why it is accepted.]

## Out of scope

- [What this plan deliberately does not do, and anything worth fixing that was noticed while
  reading -- dead code, a bad name, a neighbouring bug -- one sentence each, ready to promote to
  its own task.]
