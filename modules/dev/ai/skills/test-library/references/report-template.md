# Report template

Write `findings.md` in this shape. Adapt it as you need. Keep the evidence rule. Every finding cites
the journal and the source.

---

# `<subject>` — blind usability audit

**Setup**

- Subject and version:
- Mode: `library` or `module`
- Source commit:
- Audit workspace:
- Information tier: `strict`, `general`, or `lenient`
- Consumed as: path dependency, packed tarball, workspace alias, or link
- External resources: what you provisioned, and the command that proved it answers
- Resource fidelity: real service, the harness of the subject, or a fake. Name the finding
  categories that a fake removes
- Language server available: yes or no. If no, state that `strict` became `general`
- Blind constraint held: fill in after the contamination gate

## Headline

Two or three sentences. Name the findings that change the first hour of a newcomer the most. No
introduction.

## Milestone results

| #   | Task | Outcome                     | Time to first working code | Notes |
| --- | ---- | --------------------------- | -------------------------- | ----- |
| M1  |      | reached, partial, or failed |                            |       |
| M2  |      |                             |                            |       |
| M3  |      |                             |                            |       |

Mark any milestone that failed for infrastructure reasons as infra-failed. Leave it out of the
dimension ratings. A dead container says nothing about the subject.

## Mental model of the explorer against reality

Quote the description that the explorer gave of the subject. Then state where the description is
wrong. This is the fastest read on whether the public surface states the design.

## Findings

Sort by severity. Use the format in `references/finding-taxonomy.md`.

### F1 — [CATEGORY] SEVERITY — one-line title

Evidence: Ground truth: Impact: Fix: Confidence:

## Phantom APIs

Names that the explorer reached for and that do not exist, with the behavior that it expected. This
is direct evidence of what users expect. It is worth a read even if you change nothing.

| Reached for | Expected behavior | Actual name, if any |
| ----------- | ----------------- | ------------------- |

## Escape hatches used

Every cast, suppression, or access to the internals, with the legitimate goal behind it.

| Location | Suppression | The goal |
| -------- | ----------- | -------- |

## Divergence from real call sites (module mode only)

How the explorer used the module, against how the repository uses it. Each difference is one of two
things. Either the idiom is hard to find, or the knowledge belongs in the types and the docs of the
module.

| The explorer did | The repository does | The reason for the gap | Fix |
| ---------------- | ------------------- | ---------------------- | --- |

Include anything that the explorer built again although the module already provides it. That is how
duplicate helpers start.

## Dimension ratings

Use N/A, not a low score, for anything that the language or the shape of the subject makes
inapplicable.

| Dimension                 | Score | Reason |
| ------------------------- | ----- | ------ |
| Discoverability           | /5    |        |
| Type or boundary guidance | /5    |        |
| Diagnostics               | /5    |        |
| Documentation             | /5    |        |
| Ergonomics                | /5    |        |
| Escape hatches            | /5    |        |

## What worked

Design choices that paid off. Name them, so that they survive later changes.

## Recommended next steps

Sort by impact against effort, not by severity. State which findings each step resolves.
