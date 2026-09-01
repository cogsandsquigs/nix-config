# goodreview internals

**INTERNAL DOC. Do not read during skill activation.** Read only when editing, updating, debugging,
or extending the goodreview skill itself. SKILL.md is self-sufficient at run time.

## Design decisions

- **Peered review**: the primary agent stays the orchestrator/interlocutor; fresh subagents do the
  cold reads (same rationale as goodplan: you cannot cold-read what you wrote or watched). Consensus
  is reached by ping-pong — the agent proposes categories, the user pushes back via TUI/notes/chat,
  repeat until `unsure` is empty.
- **Three categories, file-granular**: `no-change` / `must-change` / `unsure`. `unsure` is the work
  queue of the conversation: it holds files the agent wants human eyes on. The review is done when
  `unsure` is empty and the user agrees with `must-change`.
- **Scope**: user chooses diff-since-ref or whole-repo per run; default is the latest commit
  (`HEAD~1`). Diff mode reviews only files in `git diff --name-only <base>`; whole-repo mode reviews
  all tracked files (subject to the size guard in SKILL.md).
- **State dir**: `.goodreview/` at repo root, excluded via `.git/info/exclude` (never `.gitignore` —
  no repo pollution). Chosen over /tmp (editor jumps + persistence) and XDG cache (discoverability).
- **Deliverable**: `.goodreview/REPORT.md`, actionable items only, written at consensus. The state
  dir is scratch; the report is the output.
- **TUI**: bash-driven guided walk, one file per screen, single-key verdicts, unsure pile first. A
  free-roaming fzf picker over all files was tried first and rejected by the owner as disorienting;
  the picker survives only as the `l` jump list. fzf is kept for line selection when commenting
  (changed lines marked `▎`) and degrades to typed line numbers without it. Browser UI was
  explicitly last-resort and turned out unnecessary.
- **Env probe**: SKILL.md carries a ```! block echoing $TERM, $TERM_PROGRAM, multiplexer, $EDITOR,
  fzf presence — so the agent knows, at activation, how to open the user-side review and whether
  fallback mode is needed.

## File contract (shared by SKILL.md, both scripts, and the agent)

```
.goodreview/
├── base          # git ref reviewed against, single line; empty in whole-repo mode
├── state.tsv     # category<TAB>path<TAB>line<TAB>summary  (one row per file)
├── findings/     # <path with / replaced by _>.md — full agent findings per file
├── agents/       # raw subagent outputs, one file per reviewer (scratch)
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
- Exits via a "press any key" prompt; zellij is launched `--close-on-exit`, otherwise the dead pane
  lingers until the user closes it by hand.
- `open_terminal.sh` order: zellij split pane (below, per owner preference) → tmux `split-window -v`
  → $TERM_PROGRAM match (kitty remote, wezterm cli, ghostty, iTerm2/Terminal via osascript) → first
  installed known terminal → print command and exit 3. Exit 3 means "hand the command to the user";
  the agent must catch this and paste the command in chat instead of failing.

## Known limitations / future work

- kitty remote control (`kitty @`) needs `allow_remote_control yes`; the fallback plain-launch opens
  a fresh instance instead.
- No per-hunk categories; granularity is the file. Notes carry line-level nuance.
- Whole-repo mode on large repos: SKILL.md caps reviewer fan-out and tells the agent to propose a
  subtree instead. Tune there, not here.
