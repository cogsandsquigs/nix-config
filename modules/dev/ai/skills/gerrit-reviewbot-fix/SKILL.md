---
name: gerrit-reviewbot-fix
description: "Fix, triage, or explain reviewbot comments on a Gerrit change through the Gerrit MCP server. Lists each bot finding with a proposed fix, applies the approved fixes, amends, pushes a new patchset, and dismisses false positives with /aino. Trigger on any request to fix, address, clear, resolve, triage, or answer reviewbot, review bot, robot, lint bot, AI review, or CI comments. This includes bare phrasings such as \"fix reviewbot\", \"fix reviewbot on gerrit\", \"fix the gerrit comments\", or \"reviewbot\" on its own, with no change number given. The skill finds the change itself, so a missing CL number is never a reason to skip it. Also trigger on Gerrit, CL, Change-Id, refs/for, patchset, /aireview, /aino, a Code-Review -1 vote, a question about what the bot flagged or whether the bot is wrong, and a request to resume a fix plan. Do not use it to write a fresh review of somebody else's change."
argument-hint: "[audit|fix|full] [change|plan-path]"
arguments: mode target
---

# gerrit-reviewbot-fix

Turn reviewbot comments on a Gerrit change into a short list of verified fixes, then apply them.

A bot comment is a claim, not a fact. Some claims are stale, some point at generated
files, and some ask for a change that the code style forbids. Check every claim against
the code before you propose a fix. A declined comment with a reason is a good outcome.

## Arguments

The skill takes two optional arguments. `$mode` holds `audit`, `fix`, or `full`. `$target`
holds a change number, a Change-Id, a Gerrit URL, or a path to a plan file. An argument
that the owner did not pass arrives empty.

- `$mode` empty: read the mode from the request. See the mode table.
- `$target` empty: resolve the change at Phase 0.
- `$target` ends in `.md`: treat it as a plan file and use mode `fix`.

## Modes

| Mode | Phases | When |
|---|---|---|
| audit | 0–5 | The owner asks a question. Ends with a plan file. No edits, no push |
| fix | 5b–8 | A plan file exists, or the owner says apply, continue, or resume |
| full | 0–8 | One session. Report in chat, **no plan file**. Stop at Phase 5 for approval |

Defaults:

- A question ("what does the bot want?") means `audit`.
- An instruction ("address the bot comments") means `full`.
- In `full`, print the report in chat and stop. Do not write a plan file, because the
  owner reads the report in the same turn. Continue past Phase 5 in the same turn only
  when the owner said to fix immediately, or said something equal to it.

## Tools

This skill drives the official Gerrit MCP server. Read the parameter schema of each tool
at call time, because the local install can lag the upstream server. The tools this skill
uses:

- `get_most_recent_cl`, `query_changes` — find the change. `get_most_recent_cl` needs the
  owner email. Read it from `git config user.email`. Do not hardcode it here.
- `get_change_details` — project, branch, current patchset, status, labels. The findings are
  **not** here. A `Code-Review -1` from the bot is a quick signal that findings exist.
- `get_commit_message` — the Change-Id trailer and the commit-message policy checks.
- `list_change_comments` — every comment on the change. This is the main input.
- `list_change_files`, `get_file_diff` — the reviewed content of one file.
- `post_review_comment` — reply to a comment. Phase 8 only, after owner approval.

The server has no tool that marks a comment resolved. Gerrit resolves a comment when a
human replies to it, so the report names every comment that still needs a reply.

`git` does the local work: read the checkout, amend, push. The MCP server never writes code.

## Process

### Phase 0 — Resolve the change

1. Use `$target` when the owner passed one. A URL or `.../c/project/+/12345` yields the number.
2. No `$target`: read the local `Change-Id` trailer from `git log -1 --format=%B`, then
   find that change.
3. Still nothing: call `get_most_recent_cl` with the email from `git config user.email`,
   then confirm the subject with the owner.

Never reuse a change number from earlier in the session, and never infer one from the branch
name. One session touches several changes, and the last number you saw is usually the wrong one.

Call `get_change_details`. Record project, target branch, current patchset number, current
revision sha, and status. Stop and say so when the change is merged or abandoned.

### Phase 0b — Locate the branch, the remote, and the commit

Never assume `master`, never assume `origin`, and never assume `HEAD`. A Gerrit checkout sits on a
local topic branch, on a release branch, or on a detached head. The local branch name
carries no information about the target branch. Resolve all three from data.

**Target branch.** The `branch` field from `get_change_details` is the only authority. The
local branch name and the local upstream can both disagree with it, and that is normal.
Record it as `<target>`.

**Remote.** In order:

1. `git config --get branch.$(git branch --show-current).remote`
2. The remote whose URL holds the Gerrit host: `git remote -v`. The name is often `gerrit`,
   not `origin`.
3. One remote only: use it. Several and no match: ask.

Record it as `<remote>`. Then `git fetch <remote> <target>` so the base ref exists locally.

**Base for diffs and tests.** Use `git merge-base HEAD <remote>/<target>`. Never diff
against `master` and never against the local branch upstream. A change on a release branch
shows hundreds of false hits when you diff against the wrong base.

**The commit to amend.** The change commit is not always `HEAD`:

1. Search the last 50 commits for the `Change-Id`:
   `git log -n 50 --format='%H %s' --grep='<change-id>'`.
2. The commit is `HEAD`: continue.
3. The commit is behind `HEAD`: the change sits under later local commits. An amend needs an
   interactive rebase, which this skill never runs. Report the position and stop.
4. The commit is absent: fetch the patchset instead of guessing. The ref is
   `refs/changes/<last two digits of the change number>/<change number>/<patchset>`.
   Run `git fetch <remote> <ref>`, then `git checkout -b gerrit-<number>-p<patchset> FETCH_HEAD`.
5. A detached head is fine. Gerrit workflows check out `FETCH_HEAD` on purpose. Record the
   sha and say the head is detached, because the push command needs `HEAD:`, not a branch name.

**Revision match.** Compare the local commit sha with the current revision sha from
`get_change_details`. A mismatch means somebody pushed a newer patchset, so the local code
is old. Offer the fetch in step 4 above and do not fix the old code.

**Tree state.** Run `git status --porcelain`. Report a dirty tree at Phase 5 and never amend
over unrelated staged work.

### Phase 1 — Collect comments

`list_change_comments` is the only source of findings. Call it with the change number from
Phase 0. Also call `get_commit_message`, because commit-message policy bots put their
comments on the `/COMMIT_MSG` pseudo-file.

Keep these fields per comment: the `id=` hash, file path, line, patch set, author, message,
resolved state, and in-reply-to. The `id=` hash is the key for dedupe and for the Phase 8
reply, so never drop it.

### Phase 2 — Classify and reduce

**The author name is the discriminator.** This install exposes no `tag` field, so the author
is all you get. The reviewbot posts under a service account name. The owner posts under a
personal name, which `git config user.name` gives you. Read the author names once, group the
comments by author, and say which name you treated as the bot. Ask the owner when an account
does not resolve. Use the `tag` field as well when a later server version starts to send it.

**UNRESOLVED is the real filter.** A resolved bot comment is control chatter, not a finding.
The review-started note and the `/aireview` trigger both arrive resolved.

**A finding has a location.** Every real finding carries a file path, a line number, and an
`id=` hash. A comment on `/PATCHSET_LEVEL` carries none of these and is never a finding.
Keep `/COMMIT_MSG` comments, because those are real.

Then reduce the bot set:

- Collapse repeats. One rule that fires on 40 lines is one finding with 40 sites.
- Drop comments on generated or vendored paths and say which paths you dropped.
- Keep comments from an older patchset. Phase 3 decides whether they are stale.
- Count the human comments and say the count. They are out of scope.

**Check that the bot reviewed the current code.** Compare the highest patch set among the bot
comments with the current patch set from Phase 0. When the bot has not commented on the current
patch set, an empty finding list means "not reviewed yet", not "clean". These two look identical
and mean opposite things, so say which one you found. Offer the `/aireview` trigger and stop.

Read `references/bot-comments.md` when a comment class is unfamiliar, or when you need
the known false-positive patterns for a class.

### Phase 3 — Ground every comment in the code

For each finding, open the real file at the real line in the local checkout. Never fix
from the comment text alone.

Line numbers belong to the patchset that the bot read. They drift on every later edit. Use
the line as a starting point, then confirm the match by the code itself. A finding whose code
is not near the stated line is a candidate for **stale**, not a reason to edit that line.

Assign one state:

- **live** — the code still has the problem the bot describes.
- **stale** — a later patchset already fixed it. No work. The new patchset speaks for itself.
- **wrong** — the bot misread the code. No work. This one qualifies for an `/aino` reply.
- **blocked** — the fix needs a decision that only the owner can make.

Use `get_file_diff` when the local file and the comment disagree, to see what the bot
actually read.

### Phase 4 — Propose the smallest fix

For each **live** finding, write the fix as a concrete edit: file, line, and what changes.
Prefer the smallest correct change. A bot complaint is not a licence to refactor.

Rank each fix `low`, `medium`, or `high` risk. High risk means the fix changes behavior,
touches a public signature, or edits a file that the change did not otherwise touch.
A suppression comment (`eslint-disable`, `// nolint`, `@ts-ignore`) is a last resort. It
hides the next failure too, so it always needs a reason and owner approval.

For each **wrong** finding, draft an `/aino` reply instead of a fix. See the `/aino` section.

### Phase 5 — Report

Use the template in `references/report-template.md`.

Mode `audit`: write the report to `gerrit-reviewbot-fix-plan.md` in the repo root. Put a one-screen
summary and the path in chat.

Mode `full`: put the report in chat. Do not write a file.

Both modes: **stop here.** Ask which fixes to apply and which `/aino` drafts to post.
Findings marked high risk, blocked, or suppression need an explicit yes, and so does every
`/aino` draft. Record the answers as `approved` or `rejected`.

### Phase 5b — Resume from a plan

The plan is a proposal. The code is the truth.

1. Read the plan file.
2. Re-read the current comments with `list_change_comments`. Newer patchsets bring new bots.
3. Re-check each `approved` finding against the code. Mark a finding `stale` when the code
   moved, and say so instead of applying a dead fix.
4. Report the delta in one short list, then continue to Phase 6.

### Phase 6 — Apply

Apply the approved fixes, grouped by file. Keep each edit inside the scope of its finding.
Do not reformat untouched lines. Do not rename anything the findings did not name.

Every edit shifts the lines below it. Re-read the file before the next fix in that file and
find the site by its code, not by the line number in the report.

Update the plan file status to `done` after each fix when a plan file exists.

### Phase 7 — Verify and push

1. Run the checks the repo itself defines. Read the scripts in `package.json`, the
   `Makefile`, or the CI config. Run the build, the type check, the lint, and the tests
   that cover the touched files.
2. A failing check stops the push. Report the failure and the fix that caused it.
3. `git add` the touched files. Run `git commit --amend --no-edit`.
4. Confirm the `Change-Id` trailer survived: `git log -1 --format=%B | grep Change-Id`.
   A lost trailer creates a second change on push, so stop when it is gone.
5. **Ask before the push.** A push publishes a patchset to every reviewer and sends mail.
   Show the command and wait.
6. `git push <remote> HEAD:refs/for/<target>`, with both values from Phase 0b. Add
   `%topic=<topic>` only when the change already carries a topic. `HEAD:` works from a
   detached head and from a topic branch with any name, so use it either way.
7. Report the new patchset URL, then continue to Phase 8.

### Phase 8 — Dismiss the false positives with `/aino`

Post only the drafts the owner approved at Phase 5. Run this after the push, so the thread
reads in order: the bot claim, the new code, the dismissal.

1. For each approved draft, call `post_review_comment` on the same file and line as the
   original bot comment, with `in_reply_to` set to that comment id. The thread carries
   across patchsets, so the reply lands in the right place.
2. **Show the exact text and ask once** before the first post. Every reply is public and
   sends mail. A batch of five replies gets one confirmation, not five.
3. Set the status to `dismissed` in the plan file when a plan file exists.
4. Ask whether to re-run the bot. The trigger is `/aireview` as a patchset-level comment.
   Post it, then stop. Do not wait, do not sleep, and do not poll for the reply. The turnaround
   is minutes on a good day and much longer on a bad one, and sometimes the bot never answers.
   Never quote a time to the owner. Tell them to re-run this skill on the new patchset once
   they see the bot reply, and offer to check on request.
5. Close with: fixes applied, fixes rejected, findings dismissed, findings that still need
   the owner (`blocked`), and the patchset URL.

## The `/aino` reply

`/aino` tells the reviewbot that the finding does not apply. It is a public statement that
the bot is wrong, so the bar is a grounded reason, not an opinion.

Text shape: `/aino ` plus one or two sentences. Name the code that disproves the claim.

- Good: `/aino The guard on line 41 returns early when `cfg` is null, so line 44 cannot
  dereference null.`
- Good: `/aino `src/gen/api.ts` is generated by `pnpm codegen` and is listed in
  `.prettierignore`.`
- Bad: `/aino False positive.`
- Bad: `/aino Not relevant to this change.`

Use `/aino` only for state **wrong**, which includes a misread of the code, a rule that
does not cover this file type, and a hit inside generated or vendored code.

Never use `/aino` for:

- A **stale** finding. The code did change, so the new patchset answers it. A dismissal
  there is a false claim.
- A **blocked** finding. The bot is right and the fix is expensive. That needs the owner,
  not a dismissal.
- Any security or secret finding. Escalate to the owner instead.
- A finding you could not ground in Phase 3. No evidence means no dismissal.

## Guardrails

- Never rebase, reset, force-push, or push to `refs/heads/*`. Amend and push to `refs/for`.
- Never hardcode `master`, `main`, or `origin`. Take the target branch from Gerrit and the
  remote from git config. The local branch name proves nothing.
- Never amend a commit that is not the local head. Report the position and stop.
- Never drop or edit the `Change-Id` trailer.
- Never amend when the tree holds unrelated changes. Report the dirty files and stop.
- Never post to Gerrit without owner approval. Reading is free, writing is not.
- Never dismiss a finding with `/aino` on your own judgement. The owner approves every one.
- Never fix or dismiss a comment you could not ground in Phase 3.
- Human comments are out of scope. Count them, name them, leave them.

## Report status vocabulary

`proposed` → `approved` | `rejected` → `done` | `dismissed`. Plus `stale`, `wrong`, and
`blocked` from Phase 3.

## Files

- `references/bot-comments.md` — common bot comment classes, the fix pattern for each,
  and the known false positives. Read it at Phase 2 or Phase 3.
- `references/report-template.md` — the Phase 5 output shape. Read it at Phase 5.
