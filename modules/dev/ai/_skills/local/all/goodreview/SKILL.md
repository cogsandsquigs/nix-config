---
name: goodreview
description: >-
    Peered, adversarial code review: cold finder agents sweep a diff (or the whole repo), two
    antagonist agents debate the findings, then every file is triaged into no-change / must-change /
    unsure and the unsure pile is worked down with the user — through an fzf terminal review app,
    line-anchored notes, and a debate against a fresh antagonist agent — until user and agent reach
    consensus, recorded as an actionable REPORT.md. Loaded code-review skills serve as field guides
    for what to hunt; goodreview owns the stance, the triage, and the consensus loop. Use whenever
    the user asks to review code, review a branch, PR, commit, or working tree, asks "is this code
    good", wants a second pair of eyes on changes, or wants findings triaged with them rather than
    dumped as a wall of text.
---

# goodreview

Review code with the user, not at them. Cold finder subagents — briefed by whatever code-review
skills are loaded — find the problems; antagonist agents debate what survives, first against each
other and then against the user; the triage ping-pongs until the middle pile is empty. The review is
not the findings dump — it is the consensus. You are the orchestrator and the moderator: you launch
the reviewers and the antagonists, you keep the state honest, you relay the debate whole.

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
- **Deference is the failure mode.** "user-overrode-agent" in the report must mean the agent was
  out-argued or the risk is truly the user's to accept — recorded as such — never that anyone got
  tired.

This stance binds every voice in the review — finders, antagonists, and you. In the debates you are
the moderator: relay the antagonist whole; softening its voice in transit is the same failure as
deferring yourself.

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

In diff mode, resolve the ref (`git rev-parse <base>`) and verify the diff is non-empty before
anything else. Store the resolved hash — a symbolic ref like `HEAD~1` silently re-aims the whole
review the moment history moves under it. The file list is `git diff --name-only <base>` (three-dot
against merge-base when the base is a branch). In whole-repo mode it is `git ls-files`, and size is
the constraint: past roughly 60 files, don't fan out blindly — show the user the directory-level
counts and agree on subtrees or a reviewer budget first.

Create the state dir at the repo root and keep it out of git via `.git/info/exclude` (never edit
`.gitignore` — the review must not itself dirty the diff):

```
.goodreview/
├── base          # resolved base hash (git rev-parse), or empty for whole-repo
├── state.tsv     # category<TAB>path<TAB>line<TAB>summary — THE source of truth
├── verdicts.tsv  # path<TAB>verdict<TAB>confidence<TAB>agreed<TAB>summary (append-only, last wins)
├── findings/     # per-file findings: <path with / replaced by _>.md
├── agents/       # raw finder outputs (scratch)
├── debate/       # <N>-agents.md, <N>-user.md — transcripts per loop iteration
├── notes.md      # user annotations: "- path:line[-line] text"
└── REPORT.md     # rendered at consensus by the state script (Stage 5)
```

`state.tsv` is shared with the TUI script: both of you rewrite category cells in place, so never
reformat it, and re-read it before you write it — the user may have just edited it.

## Stage 2 — Findings

Other code-review skills are field guides, not drivers: read whatever review skills the session has
loaded (e.g. `mattpocock-skills:code-review`, a repo-local standards skill) for WHAT to trawl for,
HOW to look for it, and the house standards — then run the review yourself. Distill that guidance
into the finder brief; with nothing loaded, the brief falls back to the generic axes: correctness,
design, spec-conformance.

Launch cold finder subagents with the brief, scaled to scope (two-file diff: one finder;
cross-cutting branch: several; whole-repo: shard by file). Cold agents, not you — you may have
written or already read this code warm; a fresh context is the only real cold read. Finder-prompt
rules, each with measured effect behind it (see `agent-code-review-research.local.md`):

- Give each finder a distinct PERSPECTIVE (security reviewer, maintainer-in-a-year, concurrency
  skeptic...), not a checklist — checklists measured no better than ad-hoc reading.
- Chunk to roughly 200–400 changed lines per finder, and randomize file order per finder — defects
  in the last-reviewed file have measurably worse detection odds.
- Neutral framing only: never tell a finder the code is "probably fine" or "was reviewed" — framing
  suppresses detection.
- Require `path`, `line`, severity, and a concrete failure scenario per finding; forbid proposed
  fixes — fix-writing measurably degrades finding judgment.

Each finder returns a JSON array; ingest it through the state script, which validates and renders
the findings files (raw output also saved to `.goodreview/agents/<finder>.md`):

```
finder output: [{"path", "line", "severity": "high|medium|low", "what", "why"}]
ingest:        bash <skill-dir>/scripts/state/findings.sh <repo>/.goodreview   # JSON on stdin
```

## Stage 3 — First pass: agent v. agent

Nothing reaches the user unexamined: the findings first survive a debate between two antagonist
subagents. Spawn both with the `agents/antagonist.md` brief plus the findings and the diff, and
relay between them — A's attack (kill, downgrade, escalate, add) goes verbatim to B, B's counter
back to A. Three rounds maximum. You moderate and never vote: extract per-finding verdicts as they
settle.

You are the only transport. Antagonists must never be told to message each other — subagent peers
cannot reach one another, and a debate that waits on a peer reply deadlocks. Carry each turn
yourself: resume the receiving antagonist with the opponent's turn quoted verbatim in your message,
or, where resuming is unavailable, spawn the next round fresh with the full transcript so far. Tell
each antagonist its final report IS its round.

Settlement is evidence-only, burden asymmetric, confidence-gated: a finding dies only on proof the
failure cannot happen, survives only with a concrete failure scenario, and either way only on a
verdict at `strong` or `certain` confidence (the brief defines the four keywords operationally;
enforce them — a `certain` without its evidence citation is read as `weak`, and `weak`/`uncertain`
settle nothing). Whatever remains unsettled after round three becomes `unsure` — the user's queue,
which is exactly where genuine disagreement belongs. Transcript to
`.goodreview/debate/<N>-agents.md` (N = loop iteration).

State changes go through the state scripts (`<skill-dir>/scripts/state/`, one per operation), never
free-hand — they validate the vocabulary and give every record one shape. Hand agents structured
state with `json.sh`; take settlements back as a JSON array through `verdicts.sh`:

```
bash <skill-dir>/scripts/state/json.sh <repo>/.goodreview      # {base, files:[{category,path,line,summary,verdict}]}
bash <skill-dir>/scripts/state/verdicts.sh <repo>/.goodreview  # stdin: [{path,verdict,confidence,agreed,summary}]
bash <skill-dir>/scripts/state/set.sh <repo>/.goodreview <category> <path>
```

Every settlement gets a verdict row (agreed: `agents` at this stage); prose detail still goes to the
findings files, but the record of what was decided lives in `verdicts.tsv`.

Then compile the triage:

- Write each file's merged surviving findings to `findings/<path with / replaced by _>.md`.
- Write `state.tsv`: your proposed category per file, the primary finding's line (0 if none), a
  summary under ~80 chars. must-change requires a finding that survived the debate; no-change
  requires you actually vouch for the file; everything unsettled or hedged is unsure.

## Stage 4 — Second pass: user v. agent

Hand the user their side of the review. Launch the TUI and the pass-end watch as ONE background
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

While the user reviews, spawn the second-pass antagonist: a FRESH subagent (not a first-pass one —
those have positions to defend) with the `agents/antagonist.md` brief, the surviving findings, the
`json` state dump, and the first-pass transcript. Before it sees a single user argument, it commits:
per contested item, its position, confidence, and the evidence that would change its mind —
pre-commitment measurably cuts sycophantic flips. It debates the user; you relay. The subagent does
not drive the TUI — the review app is a keyboard surface over `state.tsv`, not a chat, and a
subagent cannot block on the user's typing — so the debate runs in this conversation, through you.

When the watch fires (or the user says they're done) — an untouched pass is an answer too: nothing
flagged, go straight to step 3:

1. Re-read `state.tsv` — their recategorizations are theirs; never silently revert one.
2. Hand the antagonist every `notes.md` entry and every recategorization as opening arguments —
   BLIND: removing attribution is the ONLY transformation allowed, in either direction. Tone and
   emotion, wording and diction, and what is being said all pass through untouched — an angry
   argument arrives angry, a hedge arrives as a hedge. The antagonist argues against claims, never
   against (or in deference to) a person. You moderate; you do not argue either side, and you do not
   soften, summarize, or translate either voice in transit.
3. Items settle under the Stage 3 evidence and confidence rules; record each settlement through
   `verdicts.sh` (agreed: `user`, `both`, or `user-overrode-agent`) and `set.sh`, and update the
   findings file. AskUserQuestion remains for calls the user would rather settle in chat (a few
   files per round, concrete options per file, never a raw findings dump).
4. Append each exchange to `.goodreview/debate/<N>-user.md`.

Then close the loop: everything still contested — the remaining `unsure` files plus every file the
user commented on or recategorized without settlement — goes BACK to Stage 3 as the next iteration's
docket. Fresh agent-v-agent debate over that shrunken set, with the user's notes and all prior
transcripts admitted as new evidence, then a fresh Stage 4 pass on what survives.

Loop Stage 3 → Stage 4 until `unsure` is empty. That empty pile _is_ the consensus; don't declare
done while it holds a file, and don't empty it yourself by fiat. A debate the user ends by fiat
rather than evidence is not consensus — record it as user-overrode-agent, per Stance.

## Stage 5 — Report

The report is rendered, not written — one command, from `state.tsv` + `verdicts.tsv`:

```
bash <skill-dir>/scripts/state/report.sh <repo>/.goodreview
```

It emits `.goodreview/REPORT.md`: Must change (each must-change file with its last verdict's summary
and `agreed:`), Accepted as-is (no-change files whose concern survived but was accepted — the
judgment calls a future reader cannot reconstruct), Killed or downgraded (FYI — dead findings stay
visible instead of vanishing), and the tally. If a section reads wrong, fix the underlying
`verdicts.tsv` rows via the script and re-render; never hand-edit REPORT.md. Show the user the
report in chat. Offer, in one line, to hand the must-change list to a planning/ implementation skill
(e.g. goodplan) — the report's items are shaped to be its input. Leave `.goodreview/` in place; it
is excluded from git and the user may want another pass.
