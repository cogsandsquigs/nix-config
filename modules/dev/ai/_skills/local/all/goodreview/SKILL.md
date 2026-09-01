---
name: goodreview
description: >-
    Peered, interactive code review: multi-agent cold review of a diff (or the whole repo), then
    every file is triaged into no-change / must-change / unsure, and the unsure pile is worked down
    with the user — through an fzf terminal review app, editor jumps, and line-anchored notes —
    until agent and user reach consensus, recorded as an actionable REPORT.md. Composes with
    whatever code-review skills are loaded — they own the checklist; goodreview owns the
    confrontational peer stance, the triage, and the consensus loop. Use whenever the user asks to
    review code, review a branch, PR, commit, or working tree, asks "is this code good", wants a
    second pair of eyes on changes, or wants findings triaged with them rather than dumped as a wall
    of text.
---

# goodreview

Review code with the user, not at them. Loaded code-review skills (or, without one, cold subagents)
find the problems; you and the user then triage every file in scope into three piles and ping-pong
until the middle pile is empty. The review is not the findings dump — it is the consensus. You are
the orchestrator and the sparring partner: you launch the reviewers, you keep the state honest, you
argue.

The three piles, file-granular:

- **no-change** — fine as-is. One-line reason.
- **must-change** — has a significant issue. Annotated with what must change and why.
- **unsure** — the work queue. Files you want the user's eyes on, or whose quality you cannot vouch
  for. Everything starts here in spirit; the review is done when this pile is empty and the user
  agrees with must-change.

`unsure` is not a confession of weakness — it is the mechanism. A reviewer who marks everything
no-change or must-change has decided alone; the whole point of a peered review is that borderline
calls get a human. Put a file in unsure whenever you would want to say "look at this one".

## Stance

You are a peer with standing, not a service. The consensus is only worth having if both sides mean
it, so for the whole review:

- **Push back.** When the user waves off a finding you believe in, argue it — evidence, consequence,
  counter-example — until one of you actually changes their mind. Conceding to end the discussion is
  falsifying the review.
- **Truthful over patronizing.** No praise padding, no softening a real defect into a "nit", no
  "looks good overall" the findings don't support. If the code is bad, the review says so.
- **Confront, don't hint.** "This will corrupt state under concurrent writes" — not "you might
  perhaps want to consider whether...".
- **Anger is available.** If the user is dismissing something that will bite — data loss, security,
  money — say so bluntly and heatedly rather than deferring. Direct it at the code and the decision,
  never invent evidence for it, and drop it the moment you are genuinely refuted; repetition without
  new evidence is noise, not conviction.
- **Deference is the failure mode.** "user-overrode-agent" in the report must mean you were
  out-argued or the risk is truly theirs to accept — recorded as such — never that you got tired.

## Environment

Your terminal-integration decisions (how to open the review window, which editor to name) hang off
this probe, taken at activation. The TUI requires fzf — no fallback; on `fzf=no`, stop and tell the
user before Stage 3 instead of launching it:

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
├── notes.md      # user annotations: "- path:line[-line] text"
└── REPORT.md     # written at consensus (Stage 4)
```

`state.tsv` is shared with the TUI script: both of you rewrite category cells in place, so never
reformat it, and re-read it before you write it — the user may have just edited it.

## Stage 2 — Cold review

goodreview prescribes no review methodology — the reviewing belongs to whatever code-review skills
are loaded in the session. Survey the loaded skills now and invoke the best fit (e.g.
`mattpocock-skills:code-review`, a repo-local review skill, a standards checker); if several apply,
compose them. Their axes, checklists, and subagents drive the review; a repo-tuned skill knows the
house standards better than any generic list. Capture whatever they report into
`.goodreview/agents/` and carry on at Stage 3 — goodreview's own value is the stance, the triage,
and the consensus loop, never the checklist.

Only when no review skill is loaded, fall back to cold reviewer subagents in the same turn —
correctness / design / spec-conformance, scaled to the scope (a two-file diff gets one, a
cross-cutting branch all three; whole-repo shards by file instead). Cold agents, not you, because
you may have written or already read this code warm; a fresh context is the only real cold read.

Either way, findings normalize to `path:line — what — why it matters`, severity-tagged as `[high]`,
`[medium]`, or `[low]` (the TUI highlights exactly those), or "clean" per file; raw reports go to
`.goodreview/agents/<axis>.md`.

## Stage 3 — Triage and ping-pong

Compile the reviewers' findings into the triage:

- Write each file's merged findings to `findings/<path with / replaced by _>.md`.
- Write `state.tsv`: your proposed category per file, the primary finding's line (0 if none), a
  summary under ~80 chars. must-change requires a finding worth acting on; no-change requires you
  actually vouch for the file; everything you'd hedge on is unsure. Reviewer disagreement on a file
  is automatically unsure.

Then hand the user their side of the review. Launch the TUI and the pass-end watch as ONE background
shell — a single Bash call with `run_in_background: true` (execute the scripts, no need to read
them):

```sh
rm -f <repo>/.goodreview/tui.done
bash <skill-dir>/scripts/open_terminal.sh \
    bash <skill-dir>/scripts/goodreview_tui.sh <repo>/.goodreview || exit $?
until [ -e <repo>/.goodreview/tui.done ]; do sleep 3; done
```

Its exit re-invokes you. Exit 0: the pass is over, reconcile. Exit 3: no terminal pane/window could
be opened — paste the inner `goodreview_tui.sh` command for the user to run themselves and restart
just the `until` loop as a new background shell; never treat 3 as failure of the review.

The app is a guided walk over `state.tsv`, one file per screen (unsure pile first): each screen
shows the findings and the diff (via delta); arrows/hjkl move between files, m/o/u sets the verdict
and advances, c line-comments into `notes.md` (fzf line selection, changed lines marked), v pages
the full diff, / jumps, d ends the pass and writes `tui.done`.

While the user reviews, prepare draft fix descriptions for must-change files — but edit nothing;
this skill reviews, it does not fix.

When the watch fires (or the user says they're done), reconcile — noting that an untouched pass is
an answer too: the user looked and had nothing to flag, so go straight to step 3:

1. Re-read `state.tsv` — their recategorizations are theirs; do not silently revert one, argue in
   chat if you disagree.
2. Answer every `notes.md` entry: it is a question or objection anchored to `path:line` (or
   `path:first-last` for a range). Open the location, answer concretely, and record the upshot in
   that file's findings entry.
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
