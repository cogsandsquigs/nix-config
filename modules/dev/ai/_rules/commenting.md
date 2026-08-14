# Commenting

- Comment only behaviour the code doesn't already show. When in doubt, don't comment
- A comment may only answer "why", never "what". Prefer fixing the name or structure instead of
  commenting, comment only when the "why" isn't reasonably inferable from the code and its context
- Code is a self-contained snapshot: describe only current behaviour, as if the code had always been
  that way

Before and during commenting, consider:

- **Renaming before commenting**: method summaries, return-contract restatements, interface/field
  descriptions, and absent-means-default notes are all "what" comments — delete them and improve the
  name instead
- **Why-comments clear a high bar**: only for intent a reader cannot reconstruct — an external
  constraint, a non-obvious index space, a deliberate choice that would otherwise read as
  accidental, or when the ideal or obvious way to do something can't be done. Keep it simple, 1-2
  lines

Never comment these:

- **Never narrate the diff**: no comments that describe an edit ("changed to..."), or restate
  framework/language conventions
- **Never reference former state**: "replaces the old X", "previously did Y" are banned even as
  context
- **No development-context references**: never "the reported grid" — describe the thing by its
  properties, not its origin. Name test fixtures by structure ("a grid whose top row holds only
  branches"), never by the session that produced them
- **Nothing about code that doesn't exist**: never mention future work, hypothetical callers, or
  not-yet-written layers, except for TODOs
- **No inferable design narration**: don't caption why a type or shape was chosen when the use sites
  make it clear
- **No line numbers in persisted references**: cite file path plus class/method name — line numbers
  drift
