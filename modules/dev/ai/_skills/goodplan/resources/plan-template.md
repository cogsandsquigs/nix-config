# Plan: [goal]

## Goal

[1-2 sentences: what changes, and why.]

## Approach

[The design in a short paragraph. Name the key types, interfaces, and the error model, and say why
this is the smallest edit that meets the goal.]

## Changes

**New files**

- `path` -- [responsibility]

**Edited files**

- `path` -- [what changes, and why]

## Steps

One atomic edit per step, specified so that two implementers produce the same diff.

Checks below were run with: [interpreter and version, the dependencies that matter, anything that
was missing. Stated once here, not repeated per step.]

1. **[what this step does]**
    - Edit: `path:symbol` -- [the exact change: literal before and after text, and the quoted line
      it lands next to when the symbol holds more than one edit site]
    - Edit, for anything new: `path: between <symbol A> and <symbol B>` -- [the literal text to
      insert, and the convention that fixes its position if the file has one]
    - Check: `[command]` -- [the result that means it passed, with the baseline number if the result
      is a comparison. Say "not run: [why]" if the environment could not run it.]

2. **[the same mechanical edit, repeated across sites]**
    - Edit, written once: [the literal before and after text]
    - Sites: `path:symbol` -- [quoted anchor line]; `path:symbol` -- [quoted anchor line]; ...
    - Check, one per site: `[command]` -- [the result that means it passed]

3. ...

## Decisions for you

- [Open high-leverage choice, the options, and a recommendation with its rationale. Say which steps
  rest on the recommendation. Omit the section if there are none.]

## Risks & mitigations

- [Red-team finding, from either pass -> the step that now handles it, or why it is accepted.]

## Out of scope

- [What this plan deliberately does not do.]
