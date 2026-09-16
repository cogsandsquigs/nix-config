# Comment classes

Each class gives the usual fix and the usual failure mode. The failure-mode column is the reason
Phase 3 exists: the author is often right about the principle and wrong about this line.

- [Bot comments](#bot-comments) — formatter, lint, commit message, coverage, headers, spelling,
  security, merge conflict
- [Human comments](#human-comments) — nit, naming, design objection, question, missing test, scope,
  correctness, "did you mean"
- [Ordering](#ordering) — which class to fix first when several fire on one file

## Bot comments

A bot finding that is wrong gets `/aino` with the evidence. See `reply-drafting.md`.

### Formatter and style

Examples: gofmt, clang-format, prettier, black, ktlint.

- Fix: run the repo formatter on the touched files only. Do not format the whole tree.
- False positive: the file is generated, vendored, or excluded by a config the bot ignores.
- Note: a formatter finding is mechanical. Apply it, do not argue with it.

### Static analysis and lint

Examples: eslint, golangci-lint, pylint, SpotBugs, clang-tidy, Coverity.

- Fix: change the code so the rule passes. Keep behavior identical.
- False positive: the analyzer cannot see a guarantee the code holds. A nullness warning after a
  checked branch is the common case.
- When the finding is a true positive but the fix is large, mark it `blocked` and say what the real
  fix costs. Do not paper over it with a cast.

### Commit message policy

The comment sits on `/COMMIT_MSG`. Examples: subject too long, missing bug reference, missing
sign-off, wrong prefix, body line over 72 columns.

- Fix: `git commit --amend` on the message. Keep the `Change-Id` trailer byte for byte.
- False positive: a bot that wants a bug ID for a change that has no bug. Ask the owner.

### Coverage

Examples: a bot that reports uncovered new lines.

- Fix: add a test for the uncovered branch. A test that only touches the line to raise the number is
  waste. Write the test that would catch a real fault.
- False positive: coverage on generated code, on a type-only file, or on a branch the test harness
  cannot reach. Say which.

### Header, licence, and metadata

Examples: missing licence header, wrong year, missing owner file entry.

- Fix: copy the header from a sibling file in the same directory. Never invent the text.
- False positive: a file type the policy does not cover.

### Spelling and prose

Examples: codespell, a docs linter.

- Fix: correct the word.
- False positive: a domain term, an identifier inside prose, or a deliberate abbreviation. Add it to
  the repo dictionary file when the repo has one. Do not silence the whole rule.

### Security and dependency scans

Examples: a secret scanner, a dependency CVE bot, a licence scanner.

- A secret finding is different from every other class. Stop the fix flow and tell the owner first.
  A committed secret needs rotation, not a delete. Removing the line leaves the secret in the
  history and in every clone.
- A CVE finding usually needs a version bump plus a lockfile update. That is a separate change more
  often than not. Mark it `blocked` and say so.

### Merge conflict and rebase bots

Examples: a bot that reports the change no longer merges cleanly.

- This is not a code comment. It needs a rebase, and this skill never rebases.
- Report it and stop. The owner rebases.

## Human comments

A person comments about intent, and the words rarely say which class it is. `nit: this name is odd`,
`why not use the existing helper?`, and `this will break for empty input` all look alike in the JSON
and need three different responses. Read what they want done, not the surface form.

### Nit and preference

Markers: `nit`, `nitpick`, `optional`, `non-blocking`, `feel free to ignore`, `super minor`.

- Fix: apply it if it is cheap and local. It costs nothing and the reviewer asked.
- Failure mode: treating a nit as a mandate. A nit never justifies a risky edit, never blocks the
  push, and never gets escalated to the owner as a decision. If it conflicts with a real finding,
  the real finding wins and the reply says so.

### Naming, wording, and comments

Examples: rename a symbol, reword a doc comment, drop a stale comment.

- Fix: rename via the language's rename, not a text substitution — a partial rename still compiles
  in a dynamic language and breaks at runtime.
- Failure mode: the reviewer's name collides with an existing symbol, or the name is fixed by an
  external interface. Reply with the constraint rather than half-renaming.

### Design objection

Examples: "this belongs in the service layer", "why not compose instead of subclass", "this
duplicates `FooBuilder`".

- Fix: only when the reshape stays inside the change's existing scope. Otherwise `blocked` — this is
  the class most likely to hide a day's work behind one sentence.
- Failure mode: doing the redesign silently. A reviewer asking a design question expects a
  conversation, and a surprise rewrite makes their next review much larger. Reply first when the fix
  is more than local.

### Question

Examples: "what happens if this is called twice?", "is `ctx` cancelled anywhere?", "did we decide
against the cache?".

- Fix: none. Read the code, answer the question, done. State `question`.
- Failure mode: answering with a code change. An edit made to close a question the reviewer only
  asked is unreviewed work, and it usually widens the diff.
- When the answer turns out to be "it breaks": that is now a `live` correctness finding. Say so
  plainly, since the reviewer found a bug by asking.

### Missing test or missing case

Examples: "no test for the error path", "what about an empty list?".

- Fix: add the test. Assert the behavior the reviewer worried about, not just that the line
  executes.
- Failure mode: the case is genuinely unreachable. Reply with why, and prefer an assertion or a type
  that makes it unreachable by construction over a comment claiming it is.

### Scope and change splitting

Examples: "split the refactor out", "this rename doesn't belong here", "needs a test plan in the
message".

- Fix: message and metadata requests are cheap — do them in the amend. A genuine split is not a fix:
  it is a second change, and this skill never rebases or reorders commits. Mark it `blocked` and
  hand it to the owner.
- Failure mode: reverting hunks to satisfy a split request. That leaves a broken intermediate state.

### Correctness and behavior

Examples: "this races with the writer", "off by one on the last page", "this swallows the error".

- Fix: this is the highest-value class. Ground it hard — reproduce it in a test where you can — then
  fix it, and add the test alongside.
- Failure mode: the reviewer is describing a real hazard in a path this change does not take. Reply
  with the path, and say whether the hazard exists elsewhere. A true bug outside the change is a
  follow-up, not silence.

### "Did you mean" and suggested edits

Examples: a Gerrit suggested edit, or a comment quoting replacement code.

- Fix: apply the suggestion only after checking it compiles and reads correctly in context. A
  suggestion is written in the review UI without a type checker.
- Failure mode: pasting a suggestion that references a symbol that does not exist, or that drops an
  edge case the original handled. Fix the intent, not the literal text, and say so in the reply.

## Ordering

When several classes fire on the same file:

1. Human correctness findings, because a `-1` on a real bug is what actually holds the change.
2. Human design and scope answers, because the reply may change what the rest of the work is.
3. Bot static analysis, because these change code.
4. Coverage and new tests, because tests follow the final code.
5. Nits and renames, because they are cheap and should not reshuffle anything above.
6. Formatter, because formatting comes last and touches everything.
7. Commit message, because the amend happens once at the end.
