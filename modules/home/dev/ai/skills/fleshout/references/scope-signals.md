# Reading scope from a sketch

The hardest call this skill makes is not implementation. It is deciding _how much_ the user wants
built. Undershoot and you hand back a transcription of the stub. Overshoot and you have invented a
feature nobody asked for. This is the calibration checklist, with worked examples.

## Contents

- Signals that scope is bigger than what is shown
- Signals that the request really is small
- Signals that you are about to over-build
- Worked examples
- When genuinely unsure

## Signals that scope is bigger than what is shown

- **A `match` or `switch` handles one case and the rest fall through** to `todo!()`,
  `panic("unimplemented")`, a bare `default:`, or `// handle other cases`. The author already knows
  more cases exist. The sketch is a proof of concept, not the whole thing.
- **A new type or interface is introduced but used in one place**, while the codebase has other
  places doing the same job the old way. That is the start of a migration, not a one-off.
- **Scratch notes contain a verb with no object**: "also need to handle retries somehow", "should
  probably validate this", "figure out concurrency later". These are real requirements the user has
  not finished thinking through, not work to leave undone.
- **A diff touches a schema, config shape, or public signature** without touching the call sites
  that must change to stay consistent. Either the diff is deliberately partial (ask) or the rest was
  not gathered yet (go find it).
- **The user's guidance describes a workflow** — "when a user submits an order, we should…" — while
  the code shown implements one step of it.

## Signals that the request really is small

- A single function with a narrow bug and a one-line fix.
- A one-off script whose whole purpose is in the prompt, plugging into no larger system.
- The user scoped it down explicitly: "just this part", "don't worry about the rest", "quick patch".
- The diff is already internally consistent: every case handled, every call site updated, tests
  included. There is no loose thread to pull.

## Signals that you are about to over-build

Check these before writing. Each one is scope you invented rather than read:

- The design adds an abstraction, interface, or config knob with exactly one caller and no second
  use in sight.
- The plan touches files the sketch never mentioned, for reasons the user never raised.
- You are adding error handling for a state the type system already rules out.
- You are refactoring surrounding code because it is nearby, not because the feature needs it.
- You cannot point at a line in the sketch, the notes, or the user's words that asked for a given
  piece of work.

Anything that fails these is either cut or turned into a checkpoint question. It is not built
silently.

## Worked examples

**Small — build it directly, no checkpoint:**

```
User: "This function throws on empty input instead of returning an error, can you fix it?"
```

Self-contained bug, no hidden scope. Fix it.

**Bigger than it looks — flesh out, checkpoint on the ambiguous part:**

```rust
fn handle_event(e: Event) {
    match e {
        Event::Created(id) => save(id),
        _ => {} // TODO
    }
}
```

The `_ => {}` plus an `Event` enum that on inspection has `Updated`, `Deleted`, and `Archived`
variants is a strong signal: all four need handling. But _how_ `Deleted` should behave — soft
delete, hard delete, cascade — is not inferable from the code. That is the checkpoint.

**Ambiguous — use the checklist, do not guess:**

```
Scratch note: "auth stuff — probably JWT, need refresh somehow"
```

"Probably" and "somehow" are the tell. This is a real feature wearing the shape of an offhand
comment. Refresh-token rotation against sliding expiration is an architecture decision. Checkpoint
on it per SKILL.md step 4.

## When genuinely unsure

Mixed signals cost one question, and one question beats both under- and over-building: "This TODO on
the `Deleted` case — do you want full handling for all four event types, or is `Created` the only
one that matters right now?"
