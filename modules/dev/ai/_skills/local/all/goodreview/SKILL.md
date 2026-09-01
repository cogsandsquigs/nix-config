---
name: goodreview
description: >-
    Peered, interactive code review: multi-agent cold review of a diff (or the whole repo), then
    every file is triaged into no-change / must-change / unsure, and the unsure pile is worked down
    with the user — through an fzf terminal review app, editor jumps, and line-anchored notes —
    until agent and user reach consensus, recorded as an actionable REPORT.md. Use whenever the user
    asks to review code, review a branch, PR, commit, or working tree, asks "is this code good",
    wants a second pair of eyes on changes, or wants findings triaged with them rather than dumped
    as a wall of text.
---

# goodreview

Review code with the user, not at them. Cold subagents find the problems; you and the user then
triage every file in scope into three piles and ping-pong until the middle pile is empty. The review
is not the findings dump — it is the consensus. You are the orchestrator: you launch the reviewers,
you keep the state honest, you talk.

The three piles, file-granular:

- **no-change** — fine as-is. One-line reason.
- **must-change** — has a significant issue. Annotated with what must change and why.
- **unsure** — the work queue. Files you want the user's eyes on, or whose quality you cannot vouch
  for. Everything starts here in spirit; the review is done when this pile is empty and the user
  agrees with must-change.

`unsure` is not a confession of weakness — it is the mechanism. A reviewer who marks everything
no-change or must-change has decided alone; the whole point of a peered review is that borderline
calls get a human. Put a file in unsure whenever you would want to say "look at this one".

## Environment

Your terminal-integration decisions (how to open the review window, whether fzf fallback mode is
needed, which editor to name) hang off this probe, taken at activation:

```!
echo "TERM=${TERM:-} TERM_PROGRAM=${TERM_PROGRAM:-}"
[ -n "${TMUX:-}" ] && echo "mux=tmux"; [ -n "${ZELLIJ:-}" ] && echo "mux=zellij"
echo "EDITOR=${EDITOR:-unset} VISUAL=${VISUAL:-unset}"
command -v fzf >/dev/null && echo "fzf=yes" || echo "fzf=no"
git rev-parse --show-toplevel 2>/dev/null || echo "not-a-git-repo"
```

The `docs/` directory in this skill is internal — maintenance notes for editing the skill itself. Do
not read it during a review run.

## Stage 1 — Scope and setup

Pin the scope first. If the user gave a base ref, use it. If they said "repo" or named a path,
review those tracked files. Given nothing, default to the latest commit: base `HEAD~1`. Confirm the
scope in one line before spending agent tokens on it ("Reviewing diff HEAD~1..HEAD, 7 files — say
the word if you meant a branch or the whole repo"), then proceed without waiting unless they object;
AskUserQuestion only when the situation is genuinely ambiguous (e.g. dirty working tree on top of
the named ref — working tree included or not?).

In diff mode, verify the ref resolves (`git rev-parse <base>`) and the diff is non-empty before
anything else. The file list is `git diff --name-only <base>` (three-dot against merge-base when the
base is a branch). In whole-repo mode it is `git ls-files`, and size is the constraint: past roughly
60 files, don't fan out blindly — show the user the directory-level counts and agree on subtrees or
a reviewer budget first.

Create the state dir at the repo root and keep it out of git via `.git/info/exclude` (never edit
`.gitignore` — the review must not itself dirty the diff):

```
.goodreview/
├── base          # the ref, or empty for whole-repo
├── state.tsv     # category<TAB>path<TAB>line<TAB>summary — THE source of truth
├── findings/     # per-file findings: <path with / replaced by _>.md
├── agents/       # raw reviewer outputs (scratch)
├── notes.md      # user annotations: "- path:line text"
└── REPORT.md     # written at consensus (Stage 4)
```

`state.tsv` is shared with the TUI script: both of you rewrite category cells in place, so never
reformat it, and re-read it before you write it — the user may have just edited it.

## Stage 2 — Cold review

If a dedicated code-review skill is available in the session (e.g. `mattpocock-skills:code-review`),
invoke it now and let it drive the reviewing — its axes and subagents replace the fan-out below.
Capture whatever it reports into `.goodreview/agents/` and carry on at Stage 3. The reason for
deferring: a repo-tuned review skill knows the house standards; goodreview's value is the triage and
the consensus loop, not owning the checklist.

Otherwise, launch parallel reviewer subagents, one axis each, in the same turn: **correctness**
(bugs, edge cases, error handling, concurrency), **design** (naming, duplication, module shape,
speculative generality), and — when a spec/issue/CONTRIBUTING or standards doc exists — **spec/
standards** conformance. Each reviewer gets the file list, the diff command, and the brief: per
file, report findings as `path:line — what — why it matters`, severity-tagged, or state "clean" —
under 400 words. Cold agents, not you, because you may have written or already read this code warm;
a fresh context is the only real cold read. Save each raw report to `.goodreview/agents/<axis>.md`.

Scale the fan-out to the scope: a two-file diff gets one reviewer, a cross-cutting branch gets all
three. Whole-repo mode shards the file list across reviewers instead of axes if that fits the budget
better.

## Stage 3 — Triage and ping-pong

Compile the reviewers' findings into the triage:

- Write each file's merged findings to `findings/<path with / replaced by _>.md`.
- Write `state.tsv`: your proposed category per file, the primary finding's line (0 if none), a
  summary under ~80 chars. must-change requires a finding worth acting on; no-change requires you
  actually vouch for the file; everything you'd hedge on is unsure. Reviewer disagreement on a file
  is automatically unsure.

Then hand the user their side of the review. Run (execute, no need to read them):

```
bash <skill-dir>/scripts/open_terminal.sh bash <skill-dir>/scripts/goodreview_tui.sh <repo>/.goodreview
```

`open_terminal.sh` opens a new zellij floating pane / tmux window / GUI terminal window running the
review app; exit code 3 means it couldn't, and then you paste the inner command for the user to run
themselves — never treat 3 as failure of the review. The app is an fzf picker over `state.tsv`
(plain-menu fallback without fzf): preview shows findings + the file's diff; enter jumps to the
finding in `$EDITOR`; ctrl-g/o/u recategorizes; ctrl-a appends a line-anchored note/question to
`notes.md`; ctrl-d ends the pass and writes `tui.done`.

While the user reviews, prepare draft fix descriptions for must-change files — but edit nothing;
this skill reviews, it does not fix.

When the user says they're done (or `tui.done` appears), reconcile:

1. Re-read `state.tsv` — their recategorizations are theirs; do not silently revert one, argue in
   chat if you disagree.
2. Answer every `notes.md` entry: it is a question or objection anchored to `path:line`. Open the
   location, answer concretely, and record the upshot in that file's findings entry.
3. Work the remaining `unsure` pile with AskUserQuestion, a few files per round, concrete options
   per file ("promote to must-change: <reason>" / "accept as-is" / "let me look — reopen the TUI"),
   never a raw findings dump.
4. Anything either side moved or contested gets its findings file updated so the record matches the
   conversation.

Repeat — TUI pass, notes, questions — until `unsure` is empty. That empty pile _is_ the consensus;
don't declare done while it holds a file, and don't empty it yourself by fiat.

## Stage 4 — Report

Write `.goodreview/REPORT.md`, actionable items only:

```
# goodreview — <repo> @ <scope>, <date>
## Must change
- <path> — <what> — <why> (<path:line>; agreed: user|both|user-overrode-agent)
## Accepted as-is (notable)
- <path> — <the concern> — <why accepted>
## Tally
N files: X no-change, Y must-change (0 unsure)
```

"Accepted as-is (notable)" holds only files where a real concern was discussed and waved through —
the record of the judgment calls, which is what a future reader of the report cannot reconstruct.
Show the user the report in chat. Offer, in one line, to hand the must-change list to a planning/
implementation skill (e.g. goodplan) — the report's items are shaped to be its input. Leave
`.goodreview/` in place; it is excluded from git and the user may want another pass.
