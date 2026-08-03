# Bot comment classes

Each class gives the usual fix and the usual false positive. The false-positive column is the reason
Phase 3 exists: the bot is often right about the rule and wrong about this line.

## Formatter and style

Examples: gofmt, clang-format, prettier, black, ktlint.

- Fix: run the repo formatter on the touched files only. Do not format the whole tree.
- False positive: the file is generated, vendored, or excluded by a config the bot ignores.
- Note: a formatter finding is mechanical. Apply it, do not argue with it.

## Static analysis and lint

Examples: eslint, golangci-lint, pylint, SpotBugs, clang-tidy, Coverity.

- Fix: change the code so the rule passes. Keep behavior identical.
- False positive: the analyzer cannot see a guarantee that the code holds. A nullness warning after
  a checked branch is the common case.
- When the finding is a true positive but the fix is large, mark it `blocked` and say what the real
  fix costs. Do not paper over it with a cast.

## Commit message policy

The comment sits on `/COMMIT_MSG`. Examples: subject too long, missing bug reference, missing
sign-off, wrong prefix, body line over 72 columns.

- Fix: `git commit --amend` on the message. Keep the `Change-Id` trailer byte for byte.
- False positive: a bot that wants a bug ID for a change that has no bug. Ask the owner.

## Coverage

Examples: a bot that reports uncovered new lines.

- Fix: add a test for the uncovered branch. A test that only touches the line to raise the number is
  waste. Write the test that would catch a real fault.
- False positive: coverage on generated code, on a type-only file, or on a branch that the test
  harness cannot reach. Say which.

## Header, licence, and metadata

Examples: missing licence header, wrong year, missing owner file entry.

- Fix: copy the header from a sibling file in the same directory. Never invent the text.
- False positive: a file type the policy does not cover.

## Spelling and prose

Examples: codespell, a docs linter.

- Fix: correct the word.
- False positive: a domain term, an identifier inside prose, or a deliberate abbreviation. Add it to
  the repo dictionary file when the repo has one. Do not silence the whole rule.

## Security and dependency scans

Examples: a secret scanner, a dependency CVE bot, a licence scanner.

- A secret finding is different from every other class. Stop the fix flow and tell the owner first.
  A committed secret needs rotation, not a delete. Removing the line leaves the secret in the
  history and in every clone.
- A CVE finding usually needs a version bump plus a lockfile update. That is a separate change more
  often than not. Mark it `blocked` and say so.

## Merge conflict and rebase bots

Examples: a bot that reports the change no longer merges cleanly.

- This is not a code comment. It needs a rebase, and this skill never rebases.
- Report it and stop. The owner rebases.

## Ordering

Fix in this order when several classes fire on the same file:

1. Static analysis, because these change code.
2. Coverage, because new tests follow the final code.
3. Formatter, because formatting comes last and touches everything.
4. Commit message, because the amend happens once at the end.
