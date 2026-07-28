# Checkpointing Well

Step 4 of SKILL.md says to stop and ask at real decision points. The quality of _how_ you ask
matters as much as knowing _when_ — a vague question wastes the user's time re-deriving context they
already have; a sharp one lets them answer in one line. Examples below.

## Bad: open-ended, makes the user do the design work you were asked to do

```
I've hit a point where I need to decide how retries should work. What would
you like me to do?
```

This dumps the problem back on the user without narrowing it. They now have to think through the
whole design space from scratch — which is the work they handed off in the first place.

## Good: concrete menu, trade-offs stated, opinion offered

```
The scratch note says "handle retries somehow" for the payment webhook.
Three reasonable options:

1. Fixed retry count (3x) with exponential backoff — simplest, matches what
   `internal/queue/worker.go` already does elsewhere in this repo.
2. Retry with jitter + a dead-letter queue after N failures — more robust,
   but needs a new table/topic for the DLQ.
3. No automatic retry, surface the failure and let the caller decide — least
   code, but pushes the problem to whoever calls this.

Given this repo already has a DLQ pattern in `internal/queue/`, I'd lean (2)
for consistency — but it's more moving parts than (1). Which do you want?
```

Concrete, references what's actually in the codebase, gives an opinion without deciding
unilaterally, and can be answered with one word.

## Bad: asking about something mechanical (wastes a checkpoint on non-decisions)

```
I'm about to add a new match arm for the Deleted case. Should the function
be named handle_deleted or handleDeleted?
```

This isn't a decision — it's answered by convention-detection.md, step 5. Asking here trains the
user to stop trusting that checkpoints are reserved for things that matter, and they'll start
skimming (or ignoring) real ones.

## Bad: burying the actual question in a wall of narration

```
So I looked at the diff and there's a TODO for handling the Archived event,
and I also noticed that the Updated event isn't fully wired up either, and
I was thinking about how the codebase handles similar things elsewhere and
I found that in the orders module there's a pattern for soft deletes, and
I'm wondering if we should follow that pattern here or do something else,
also I noticed the tests don't cover this case yet...
```

By the time the actual question shows up, it's lost in a stream of narration the user has to parse
to find. State findings briefly, then ask directly — see the "Good" example above for the shape: 1-2
lines of context, then a short concrete menu.

## Good: checkpoint that surfaces a genuine architectural fork early, before wasted work

```
Before I build this out: the diff adds a `RetentionPolicy` concept, but I
see the codebase already has an `ExpiryPolicy` type doing something similar
in `internal/storage/expiry.go`. Do you want `RetentionPolicy` to replace
`ExpiryPolicy` (I'd migrate call sites), extend it, or is this deliberately
a separate concept? This changes where I put the new code, so worth
confirming before I go further.
```

Catches a structural fork _before_ investing in one direction — cheaper to ask now than to redo work
after building the wrong shape.

## General shape to aim for

1. One or two sentences of context — just enough that the question makes sense without the user
   re-reading the diff.
2. The concrete options (2-3, rarely more — more than that usually means the question itself needs
   to be narrowed first).
3. Your lean, if you have one, and why — briefly.
4. Stop. Don't keep implementing speculatively down one branch while waiting for an answer; that
   risks throwing away work.
