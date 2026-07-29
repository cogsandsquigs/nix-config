# Checkpointing well

SKILL.md step 4 says to stop and ask at real decision points. _How_ you ask matters as much as
knowing when. A sharp question is answerable in one line. A vague one makes the user re-derive
context they already hold.

## Contents

- The shape to aim for
- Good: concrete menu with a lean
- Good: structural fork surfaced early
- Failure modes to recognize

## The shape to aim for

1. One or two sentences of context — enough that the question makes sense without re-reading the
   diff.
2. Two or three concrete options. More than three usually means the question needs narrowing first.
3. Your lean and the reason for it, briefly.
4. Stop. Do not keep building down one branch while waiting.

## Good: concrete menu with a lean

```
The scratch note says "handle retries somehow" for the payment webhook.
Three reasonable options:

1. Fixed retry count (3x) with exponential backoff — simplest, matches what
   `internal/queue/worker.go` already does in this repo.
2. Retry with jitter plus a dead-letter queue after N failures — more robust,
   needs a new table/topic for the DLQ.
3. No automatic retry; surface the failure and let the caller decide — least
   code, pushes the problem to the caller.

This repo already has a DLQ pattern in `internal/queue/`, so I lean (2) for
consistency, though it is more moving parts than (1). Which do you want?
```

It is concrete, it cites what is actually in the codebase, it offers an opinion without deciding
unilaterally, and it can be answered with one word.

## Good: structural fork surfaced early

```
Before I build this out: the diff adds a `RetentionPolicy` concept, but the
codebase already has an `ExpiryPolicy` doing something similar in
`internal/storage/expiry.go`. Should `RetentionPolicy` replace `ExpiryPolicy`
(I would migrate the call sites), extend it, or is it deliberately separate?
This decides where the new code lives, so it is worth confirming first.
```

It catches the fork _before_ investing in one direction. Asking now is cheaper than redoing work
after building the wrong shape.

## Failure modes to recognize

**Open-ended.** "I need to decide how retries should work. What would you like me to do?" This hands
back the design work the user delegated. Narrow it into a menu first.

**Mechanical.** "Should the function be named `handle_deleted` or `handleDeleted`?" That is answered
by `convention-detection.md`, step 5. Spending a checkpoint on a non-decision teaches the user to
skim past the real ones.

**Buried.** A paragraph of narration about the diff, the TODO, the tests, and a pattern in the
orders module, with the actual question somewhere in the middle. State the finding in a line or two,
then ask.
