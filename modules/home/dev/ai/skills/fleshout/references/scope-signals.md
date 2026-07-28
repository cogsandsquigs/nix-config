# Reading Scope From a Sketch

The hardest call this skill makes isn't implementation — it's deciding _how much_ the user actually
wants built. Undershoot and you hand back a literal transcription of the stub. Overshoot and you've
invented a feature nobody asked for. This doc is a checklist for calibrating that call, with
side-by-side examples.

## Signals that scope is bigger than what's shown

- **A `match`/`switch` handles one case and the rest fall through to `todo!()`,
  `panic("unimplemented")`, a bare `default:`, or a comment like `// handle other cases`.** The
  author already knows there are more cases — the sketch is proof of concept, not the whole thing.
- **A new type/interface is introduced but only used in one place**, while the codebase clearly has
  other places doing the same job the old way. That's usually the start of a migration, not a
  one-off.
- **Scratch notes contain a verb without an object**: "also need to handle retries somehow," "should
  probably validate this," "figure out concurrency later." These are real requirements the user
  hasn't finished thinking through — not things to leave undone.
- **A diff touches a schema, config shape, or public function signature** but doesn't touch every
  call site that would need to change to stay consistent. Either the diff is incomplete on purpose
  (ask) or the rest was simply not gathered yet (go find it).
- **The user's guidance describes a _workflow_** ("when a user submits an order, we should...")
  while the code shown implements only a _step_ of it.

## Signals that the request really is small

- A single function with a clear, narrow bug and a one-line fix.
- A one-off script whose whole purpose is described in the prompt with no larger system it plugs
  into.
- The user explicitly scopes it down: "just this part," "don't worry about the rest," "quick patch."
- The diff is already internally consistent — every case handled, every call site updated, tests
  included. There's no loose thread to pull.

## Worked examples

**Small — build it directly, no checkpoint:**

```
User: "This function throws on empty input instead of returning an error, can you fix it?"
```

Single, self-contained bug. No hidden scope. Just fix it.

**Bigger than it looks — flesh out, checkpoint on the ambiguous part:**

```rust
fn handle_event(e: Event) {
    match e {
        Event::Created(id) => save(id),
        _ => {} // TODO
    }
}
```

The `_ => {}` plus an `Event` enum that (on inspection) has `Updated`, `Deleted`, `Archived`
variants is a strong signal: this needs all four handled, not just `Created`. But _how_ `Deleted`
should behave (soft delete? hard delete? cascade?) isn't inferable from the code — that's the
checkpoint.

**Ambiguous — lean into the checklist, don't guess:**

```
Scratch note: "auth stuff — probably JWT, need refresh somehow"
```

"Probably" and "somehow" are the tell. This is a real feature (auth) wearing the shape of an offhand
comment. Don't silently pick refresh-token rotation vs. sliding expiration — that's an architecture
decision, checkpoint on it per SKILL.md step 4.

## When genuinely unsure

If the signals are mixed, it's cheap to ask directly rather than guess either direction: "This TODO
on the `Deleted` case — want me to build out full handling for all four event types, or is `Created`
the only one that matters right now?" One clarifying question beats both under- and over-building.
