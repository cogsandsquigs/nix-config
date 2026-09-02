# goodreview internals

**INTERNAL DOC. Do not read during skill activation.** Read only when editing, updating, debugging,
or extending the goodreview skill itself. SKILL.md is self-sufficient at run time.

## Design decisions

- **Peered review**: the primary agent stays the orchestrator/interlocutor; fresh subagents do the
  cold reads (same rationale as goodplan: you cannot cold-read what you wrote or watched). Consensus
  is reached by ping-pong — the agent proposes categories, the user pushes back via TUI/notes/chat,
  repeat until `unsure` is empty.
- **Compositional, by owner decision**: goodreview owns stance, triage, and the consensus loop ONLY.
  Loaded code-review skills are FIELD GUIDES — mined for what to trawl for and how, never handed the
  review to drive; the generic axes are the no-skill fallback brief.
- **Stance, by owner decision**: confrontational peer, not deferential assistant — push back,
  truthful over patronizing, anger available when a real defect is being waved off. Bounded by
  evidence: never invented, dropped when refuted.
- **Adversarial passes, by owner decision**: findings must survive two debates — agent v. agent (two
  antagonists briefed by `agents/antagonist.md`, three rounds max), then user v. a FRESH antagonist
  — and the two stages LOOP: remaining unsure plus user-commented/contested files re-enter the
  agent-v-agent debate with the notes and transcripts as new evidence, until unsure is empty.
  Settlement is evidence-only with asymmetric burden (kill needs impossibility, keep needs a
  concrete failure scenario) and confidence-gated (`certain`/`strong`/`weak`/`uncertain`,
  operationally defined in the brief; weak and uncertain settle nothing, certain requires a citation
  — the anti-drift enforcement is the moderator downgrading uncited certains). The primary agent
  moderates and relays verbatim and BLIND — stripping attribution is the only transformation
  permitted; tone, emotion, diction, and content pass untouched (sycophancy guard that still lets
  heat through) — and never votes. Relay chosen over letting the subagent drive the TUI: the TUI is
  a keyboard surface over state.tsv, not a chat, and a subagent cannot block on user input.
  Transcripts land in `.goodreview/debate/`.
- **Three categories, file-granular**: `no-change` / `must-change` / `unsure`. `unsure` is the work
  queue of the conversation: it holds files the agent wants human eyes on. The review is done when
  `unsure` is empty and the user agrees with `must-change`.
- **Scope**: user chooses diff-since-ref or whole-repo per run; default is the latest commit
  (`HEAD~1`). Diff mode reviews only files in `git diff --name-only <base>`; whole-repo mode reviews
  all tracked files (subject to the size guard in SKILL.md).
- **State dir**: `.goodreview/` at repo root, excluded via `.git/info/exclude` (never `.gitignore` —
  no repo pollution). Chosen over /tmp (editor jumps + persistence) and XDG cache (discoverability).
- **Deliverable**: `.goodreview/REPORT.md`, actionable items only, RENDERED at consensus by
  `scripts/state/report.sh` from state.tsv + verdicts.tsv — by owner decision, structure comes from
  scripts, not agent prose; sibling state scripts validate and append verdict rows and category
  flips. The state dir is scratch; the report is the output.
- **TUI**: bash-driven guided walk, one file per screen, single-key verdicts, unsure pile first. A
  free-roaming fzf picker over all files was tried first and rejected by the owner as disorienting;
  the picker survives only as the `/` jump list. fzf does line selection when commenting (changed
  lines marked `▎`) and is REQUIRED — no fallback, by owner decision: this is a personal tool and
  `dev.ai` guarantees fzf. Diffs render through delta (chosen over bat for word-level diff
  highlighting; survey in `tui-utils-research.local.md` at repo root, gitignored); findings markdown
  renders through bat. Browser UI was explicitly last-resort and turned out unnecessary.
- **Env probe**: SKILL.md carries a ```! block echoing $TERM, $TERM_PROGRAM, multiplexer, $EDITOR,
  fzf presence — so the agent knows, at activation, how to open the user-side review and whether
  fallback mode is needed.
- **Debate transport is the primary, explicitly**: subagent peers cannot message each other, and a
  headless eval (skill-creator, 2026-09-02) showed both debate runs deadlocking on "waiting for the
  other antagonist's reply" until nudged. SKILL.md now names the primary as the only transport
  (resume the receiver with the turn quoted, or spawn the next round fresh with the transcript). The
  same eval caught `base` holding a literal `HEAD~1`, hence the resolved-hash rule.

## File contract (shared by SKILL.md, both scripts, and the agent)

```
.goodreview/
├── base          # resolved base hash (git rev-parse), single line; empty in whole-repo mode
├── state.tsv     # category<TAB>path<TAB>line<TAB>summary  (one row per file)
├── verdicts.tsv  # path<TAB>verdict<TAB>confidence<TAB>agreed<TAB>summary (append-only, last wins)
├── findings/     # <path with / replaced by _>.md — full agent findings per file
├── agents/       # raw finder outputs, one file per reviewer (scratch)
├── debate/       # <N>-agents.md, <N>-user.md — transcripts per loop iteration
├── notes.md      # user annotations: "- path:line[-line] text" (quickfix-ish)
├── tui.done      # unix timestamp; TUI writes on exit
└── REPORT.md     # final actionable report
```

`state.tsv` is the single source of truth for categories. Both the TUI and the agent rewrite rows in
place (awk column-1 rewrite keyed on path). `line` is the first/primary finding location, `0` if
none.

## Script notes

- `goodreview_tui.sh` `cd`s to the state dir's parent (the repo root) at startup: `state.tsv` paths
  are repo-relative and spawned panes inherit an arbitrary cwd.
- Reads user input from `/dev/tty` so it works when stdin is odd (spawned windows, tmux panes).
- `scripts/state/` is the write API for agents — one script per operation, isolated on purpose
  (owner decision: small scripts over one big one), sharing `_lib.sh` (arg-1-is-state-dir contract,
  `die`): `set.sh` (category, validated), `verdicts.sh` (JSON array on stdin, validated vocabulary,
  appended to verdicts.tsv), `findings.sh` (JSON array on stdin → rendered findings/*.md), `json.sh`
  (state + last verdicts as one JSON object, for structured subagent input), `report.sh` (renders
  REPORT.md; last verdict per path wins, `agreed` defaults to `both`, killed/downgraded findings
  surface in an FYI section instead of vanishing). JSON scripts need jq. The TUI keeps its own
  set_cat — same awk — to stay dependency-free from these.
- `d` exits immediately and the pane/window closes with it; zellij needs `--close-on-exit` for that,
  or the dead pane lingers until closed by hand.
- `open_terminal.sh` order: zellij/tmux split pane below the focused one (owner preference) → a NEW
  terminal window that blocks until close ($TERM_PROGRAM's terminal preferred, then first installed
  known one; gnome-terminal needs `--wait` to block) → macOS osascript (cannot block; the tui.done
  watch covers it) → print command and exit 3. Exit 3 means "hand the command to the user"; the
  agent must catch this and paste the command in chat instead of failing.

Finder-prompt rules and the anti-sycophancy measures (pre-commitment, blind relay, reason-before-
verdict, killed-findings FYI section) come from the survey in `agent-code-review-research.local.md`
(repo root, gitignored) — the measured effects are cited there.

## Known limitations / future work

- No per-hunk categories; granularity is the file. Notes carry line-level nuance.
- Persist user-pushback verdicts as project-local learnings across runs (a false positive should die
  once, not per review). Research doc suggests it; no mechanism chosen yet.
- Whole-repo mode on large repos: SKILL.md caps reviewer fan-out and tells the agent to propose a
  subtree instead. Tune there, not here.
