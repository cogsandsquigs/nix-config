---
name: context-local
description:
    Read and maintain CONTEXT.local.md, a gitignored per-project scratchpad holding the current
    goal, active tasks, decisions with dates, environment gotchas, and open questions. Use this
    skill whenever CONTEXT.local.md is read, created, or edited, and whenever there is project-local
    state worth persisting past the current session — the user states or changes a goal, a design or
    tooling decision gets made, a task starts or finishes, a build/test/env quirk is discovered, or
    a question is left unresolved. Also use it at the start of substantial work in an unfamiliar
    repo to pick up prior context, and when the user says things like "remember this", "note that
    for later", "what were we doing", "where did we leave off", "save the plan", or "write this
    down". Prefer it over inventing an ad-hoc notes file or dumping session state into CLAUDE.md.
---

# CONTEXT.local.md

Agents lose everything between sessions. `CONTEXT.local.md` is the cheapest fix: one short,
gitignored file per project holding what the _next_ agent (or the same human, on Monday) needs to
not repeat work — the goal being pursued, what's in flight, decisions already settled, and the traps
discovered the hard way.

Two failure modes to steer between. An empty or stale file is useless. A file that grows into a
transcript is worse than useless, because nobody reads it and the reader can't tell which parts are
still true. Aim for something a person reads in under a minute and trusts completely.

`CONTEXT.local.md` is not `CLAUDE.md`. `CLAUDE.md` holds durable instructions ("run tests with
`just test`", "never touch generated/"). `CONTEXT.local.md` holds _current state_ — things that will
be false in a month. If a line would still be true and useful in six months, it belongs in
`CLAUDE.md` or the repo's docs instead.

## Locating the file

Work from the project root, which is not necessarily the repo root — monorepos have many projects.
Walk up from the current working directory and stop at the first directory containing a package
manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`,
`Gemfile`, `composer.json`, `*.csproj`, `mix.exs`, `deno.json`). If none is found before reaching
the repo root or the filesystem root, use the repo root (`git rev-parse --show-toplevel`) or the
cwd.

```bash
# nearest manifest at or above cwd
d=$PWD; while [ "$d" != / ]; do
  ls "$d"/package.json "$d"/pyproject.toml "$d"/Cargo.toml "$d"/go.mod "$d"/pom.xml \
     "$d"/build.gradle* "$d"/Gemfile "$d"/composer.json "$d"/*.csproj "$d"/mix.exs \
     "$d"/deno.json 2>/dev/null | head -1 | grep -q . && break
  d=$(dirname "$d")
done; echo "$d"
```

When work spans two projects in a monorepo, write to the one being changed, and cross-reference by
relative path rather than duplicating content. When genuinely ambiguous, ask.

If the file exists, **read it before writing** — you are editing a document that a human or another
agent may have touched since you last saw it, and blind overwrites destroy their notes.

## Keeping it out of git

The file is personal and local; committing it creates merge conflicts over notes nobody else needs.
Before the first write, check whether it is already ignored and only act if it isn't:

```bash
git check-ignore -q CONTEXT.local.md || echo 'CONTEXT.local.md' >> .gitignore
```

Append to the `.gitignore` next to the file (create it if absent). If `.gitignore` is itself awkward
to touch — the user has said not to modify tracked files, or the repo is shared and strict — use
`.git/info/exclude` instead, which is local-only, and say which you chose. Outside a git repo, skip
this entirely rather than running `git init`.

## Structure

Use these five sections, in this order, always. The fixed shape is what makes the file skimmable and
lets any agent find its place without re-reading everything. Omit nothing; an empty section carries
information ("no open questions") and stops the next writer from inventing a new layout.

```markdown
# CONTEXT.local.md — <project name>

Local working context. Not committed. Updated: YYYY-MM-DD

## Goal

<1-3 sentences: what we are trying to achieve right now, and the definition of done.>

## Active tasks

- [ ] <task> — <status/next step if non-obvious>
- [x] <recently finished task, kept only while its result still matters>

## Decisions

- YYYY-MM-DD — <decision> — <why, in one clause>. <alternative rejected, if interesting.>

## Gotchas

- <trap and the workaround. Environment quirks, flaky tests, undocumented deps, sharp edges.>

## Open questions

- <question> — <who or what would answer it>
```

Notes on the sections that get misused:

- **Goal** is singular and current. Replace it when the goal changes; don't stack goals. Past goals
  are not history worth keeping — the decisions log carries anything durable.
- **Active tasks** mirrors reality, not aspiration. Tick items as they land, then delete ticked
  items once the follow-on work is done. A list of forty tasks means the file stopped being read.
- **Decisions** is append-mostly and always dated, because a decision's value is knowing it was
  already argued out. When a decision is reversed, add the new dated line and mark the old one
  `(superseded YYYY-MM-DD)` rather than deleting it — the reversal is often the useful part.
- **Gotchas** is where the file earns its keep. Anything that cost more than a few minutes to figure
  out and isn't written down anywhere else goes here.
- **Open questions** should be answerable. Delete them when answered — promote to Decisions if the
  answer settled something.

Get today's date from `date +%F` rather than guessing; a wrong date makes the whole log
untrustworthy.

## When to write

Write at milestones, not on every turn. Constant rewriting produces noisy diffs, burns tokens, and
teaches readers the file is churn. The moments that earn a write:

- The goal is set or changes.
- A decision is made — library chosen, approach settled, scope cut.
- A task starts, finishes, or gets blocked.
- A gotcha is discovered: a failing command, a version pin, a non-obvious setup step.
- Work stops mid-stream — the highest-value write there is, because it's what a resumed session
  reads first. Leave the next concrete step in Active tasks.

Not worth a write: routine file reads, intermediate reasoning, anything recoverable from `git log`,
and anything already in `CLAUDE.md` or the README.

Never put secrets, tokens, credentials, or customer data in this file. It's untracked, not secure —
and untracked files get pasted into chats.

Edit surgically: change the lines that changed and the `Updated:` date. Rewriting the whole file
each time loses the human's edits and inflates the diff.

## Reading it back

When picking up work in a project that has this file, read it fully before planning — it is usually
cheaper than re-deriving the same context from the code, and it may explain why the obvious approach
was already rejected. Treat it as a colleague's notes: informative, possibly stale. If a line
contradicts what the code plainly says now, the code wins; fix or delete the line and say so.

## Example

Before, mid-session, the agent has just discovered that the integration tests need a local Postgres
and has settled on a queue library:

```markdown
# CONTEXT.local.md — billing-service

Local working context. Not committed. Updated: 2026-08-25

## Goal

Move invoice generation off the request path so checkout stops timing out. Done when invoices are
produced by a background worker and p99 checkout is under 400ms.

## Active tasks

- [x] Reproduce the timeout locally with 500-line invoices
- [ ] Add `invoice_jobs` table + migration
- [ ] Wire worker into docker-compose — next: copy the pattern from `services/mailer`

## Decisions

- 2026-08-25 — Use `arq` for the job queue, not Celery — already have Redis, and Celery's broker
  config was the main source of prod incidents last quarter.
- 2026-08-24 — Keep invoice PDFs in S3, not in Postgres — rows were hitting 8MB.

## Gotchas

- Integration tests need a real Postgres; `pytest -m integration` silently skips without
  `DATABASE_URL` set, so a green run can mean nothing ran. Use `just test-int`.
- `arq` needs Redis ≥ 6.2 for `XAUTOCLAIM`; the compose file pinned 6.0.

## Open questions

- Do finance need invoices numbered strictly sequentially? Affects whether workers can run
  concurrently — ask Priya.
```

Each line there answers a question a resumed session would otherwise spend tool calls on. That's the
bar: if a line wouldn't save the next reader any work, leave it out.
