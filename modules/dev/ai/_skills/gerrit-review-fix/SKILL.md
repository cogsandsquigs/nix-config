---
name: gerrit-review-fix
description:
    'Fix, triage, or explain the review comments on a Gerrit change through the Gerrit MCP server --
    from human reviewers, from reviewbot, or both. Lists every unresolved comment with a proposed
    fix or reply, applies the approved ones, amends, pushes a new patchset, answers the reviewers,
    and dismisses bot false positives with /aino. Trigger on any request to fix, address, clear,
    resolve, triage, answer, or summarise Gerrit review comments, reviewer feedback, unresolved
    threads, nits, a Code-Review -1 vote, or reviewbot, review bot, robot, lint bot, AI review, or
    CI findings. This includes bare phrasings such as "fix the gerrit comments", "address my review
    feedback", "what does Bob want on my CL", or "reviewbot" on its own, with no change number
    given. The skill finds the change itself, so a missing CL number is never a reason to skip it.
    Also trigger on Gerrit, CL, Change-Id, refs/for, patchset, /aireview, /aino, a question about
    whether a reviewer is wrong, and a request to resume a fix plan. Do not use it to write a fresh
    review of somebody else''s change.'
argument-hint: "[audit|fix|full] [change|plan-path]"
arguments: mode target
---

# gerrit-review-fix

Turn the review comments on a Gerrit change into a short list of verified fixes and replies, then
apply them.

A comment is a claim, not a fact. Some claims are stale, some point at generated files, and some ask
for a change that the code style forbids. Check every claim against the code before you propose a
fix. A declined comment with a reason is a good outcome.

Bot and human comments both get that check. They differ in what happens when the claim does not
hold: a bot is a rule engine and gets told it is wrong, a reviewer is a colleague who gates
submission and gets an explanation plus the last word. Keep both in scope. A change usually cannot
merge until both are answered, and the owner should not have to run two passes over one review.

## Arguments

The skill takes two optional arguments. `$mode` holds `audit`, `fix`, or `full`. `$target` holds a
change number, a Change-Id, a Gerrit URL, or a path to a plan file. An argument that the owner did
not pass arrives empty.

- `$mode` empty: read the mode from the request. See the mode table.
- `$target` empty: resolve the change at Phase 0.
- `$target` ends in `.md`: treat it as a plan file and use mode `fix`.

Narrow the author scope only when the request does: "just the bot comments" or "what did Priya ask
for" limits who you act on. Say in the report which authors you scoped out, because an unanswered
thread still blocks the merge.

## Modes

| Mode  | Phases | When                                                                        |
| ----- | ------ | --------------------------------------------------------------------------- |
| audit | 0–5    | The owner asks a question. Ends with a plan file. No edits, no push         |
| fix   | 5b–8   | A plan file exists, or the owner says apply, continue, or resume            |
| full  | 0–8    | One session. Report in chat, **no plan file**. Stop at Phase 5 for approval |

Defaults:

- A question ("what does the bot want?", "what is Bob asking for?") means `audit`.
- An instruction ("address the review comments") means `full`.
- In `full`, print the report in chat and stop. Do not write a plan file, because the owner reads
  the report in the same turn. Continue past Phase 5 in the same turn only when the owner said to
  fix immediately, or said something equal to it.

## Tools

This skill drives the official Gerrit MCP server. Read the parameter schema of each tool at call
time, because the local install can lag the upstream server. The tools this skill uses:

- `get_most_recent_cl`, `query_changes` — find the change. `get_most_recent_cl` needs the owner
  email. Read it from `git config user.email`. Do not hardcode it here.
- `get_change_details` — project, branch, current patchset, status, labels. The comments are **not**
  here. The label votes name who sits at `Code-Review -1`, which is who currently blocks the merge.
- `get_commit_message` — the Change-Id trailer and the commit-message policy checks.
- `list_change_comments` — every comment on the change, from every author. This is the main input.
- `list_change_files`, `get_file_diff` — the reviewed content of one file.
- `post_draft_comment`, `list_draft_comments`, `publish_drafts`, `delete_draft_comment` — stage the
  replies, then publish them as one batch. Phase 8 only, after owner approval.
- `post_review_comment` — a single immediate reply, and the patchset-level `/aireview` trigger.

The server has no tool that marks a comment resolved. Gerrit resolves a thread when a human replies
to it, so the report names every comment that still needs a reply.

`git` does the local work: read the checkout, amend, push. The MCP server never writes code.

## Process

### Phase 0 — Resolve the change

1. Use `$target` when the owner passed one. A URL or `.../c/project/+/12345` yields the number.
2. No `$target`: read the local `Change-Id` trailer from `git log -1 --format=%B`, then find that
   change.
3. Still nothing: call `get_most_recent_cl` with the email from `git config user.email`, then
   confirm the subject with the owner.

Never reuse a change number from earlier in the session, and never infer one from the branch name.
One session touches several changes, and the last number you saw is usually the wrong one.

Call `get_change_details`. Record project, target branch, current patchset number, current revision
sha, status, and the label votes with the account behind each one. Stop and say so when the change
is merged or abandoned.

### Phase 0b — Locate the branch, the remote, and the commit

Never assume `master`, never assume `origin`, and never assume `HEAD`. A Gerrit checkout sits on a
local topic branch, on a release branch, or on a detached head. The local branch name carries no
information about the target branch. Resolve all three from data.

**Target branch.** The `branch` field from `get_change_details` is the only authority. The local
branch name and the local upstream can both disagree with it, and that is normal. Record it as
`<target>`.

**Remote.** In order:

1. `git config --get branch.$(git branch --show-current).remote`
2. The remote whose URL holds the Gerrit host: `git remote -v`. The name is often `gerrit`, not
   `origin`.
3. One remote only: use it. Several and no match: ask.

Record it as `<remote>`. Then `git fetch <remote> <target>` so the base ref exists locally.

**Base for diffs and tests.** Use `git merge-base HEAD <remote>/<target>`. Never diff against
`master` and never against the local branch upstream. A change on a release branch shows hundreds of
false hits when you diff against the wrong base.

**The commit to amend.** The change commit is not always `HEAD`:

1. Search the last 50 commits for the `Change-Id`:
   `git log -n 50 --format='%H %s' --grep='<change-id>'`.
2. The commit is `HEAD`: continue.
3. The commit is behind `HEAD`: the change sits under later local commits. An amend needs an
   interactive rebase, which this skill never runs. Report the position and stop.
4. The commit is absent: fetch the patchset instead of guessing. The ref is
   `refs/changes/<last two digits of the change number>/<change number>/<patchset>`. Run
   `git fetch <remote> <ref>`, then `git checkout -b gerrit-<number>-p<patchset> FETCH_HEAD`.
5. A detached head is fine. Gerrit workflows check out `FETCH_HEAD` on purpose. Record the sha and
   say the head is detached, because the push command needs `HEAD:`, not a branch name.

**Revision match.** Compare the local commit sha with the current revision sha from
`get_change_details`. A mismatch means somebody pushed a newer patchset, so the local code is old.
Offer the fetch in step 4 above and do not fix the old code.

**Tree state.** Run `git status --porcelain`. Report a dirty tree at Phase 5 and never amend over
unrelated staged work.

### Phase 1 — Collect the comments and rebuild the threads

`list_change_comments` is the only source of comments. Call it with the change number from Phase 0.
Also call `get_commit_message`, because commit-message policy bots and reviewers who object to the
wording both put their comments on the `/COMMIT_MSG` pseudo-file.

Keep these fields per comment: the `id=` hash, file path, line, patch set, author, message, resolved
state, and in-reply-to. The `id=` hash is the key for dedupe and for the Phase 8 reply, so never
drop it.

**Follow `in_reply_to` to group the comments into threads, then act on the last message in each one,
not the first.** A human review is a conversation: the reviewer asks, the owner answers, the
reviewer accepts or presses again. Read only the opening comment and you end up fixing something the
reviewer already withdrew, or re-answering what the owner already answered. Note the threads where
the owner's own account spoke last — those wait on the reviewer, not on you.

### Phase 2 — Classify and reduce

**Sort every author into `bot` or `human`.** The reply mechanism and the deference both follow from
this, so it is the first thing to get right. This install exposes no `tag` field, so the author name
is all you get. The reviewbot posts under a service account name; people post under personal names,
and `git config user.name` gives you the owner's. Read the author names once, group by account, and
say which accounts you treated as bots. Ask the owner when an account does not resolve, because
guessing wrong turns a colleague's request into an `/aino`. Use the `tag` field as well when a later
server version starts to send it.

**UNRESOLVED is the real filter.** A resolved thread is settled, whoever settled it. Bot control
chatter — the review-started note, the `/aireview` echo — arrives resolved for the same reason.

**Most findings have a location,** and every one that does carries a file path, a line, and an `id=`
hash. A bot comment on `/PATCHSET_LEVEL` is chatter. A human's patchset-level comment is not: it is
where the broad requests live ("please split this into two changes", "this needs a test plan"). Read
it, and carry it as a finding with no site when it asks for something. Keep `/COMMIT_MSG` comments,
because those are real.

Then reduce:

- Collapse repeats. One bot rule firing on 40 lines is one finding with 40 sites. Two reviewers
  raising the same point is also one finding, credited to both.
- Drop bot comments on generated or vendored paths and say which paths you dropped. A human comment
  on a generated file is not noise — they usually mean the generator input, so keep it and read it
  that way.
- Mark a human comment carrying `nit`, `optional`, `non-blocking`, or `feel free to ignore` as a
  nit. Nits are cheap and worth doing, but a nit never blocks a push and never earns a risky edit.
- Keep comments from an older patchset. Phase 3 decides whether they are stale.

**Check that the bot reviewed the current code.** Compare the highest patch set among the bot
comments with the current patch set from Phase 0. When the bot has not commented on the current
patch set, an empty bot finding list means "not reviewed yet", not "clean". These two look identical
and mean opposite things, so say which one you found, and offer the `/aireview` trigger. Humans need
no equivalent check — a reviewer who has not looked yet leaves no comment and no vote, and no
trigger makes them look.

Read `references/comment-classes.md` when a comment class is unfamiliar, or when you need the known
false-positive patterns for a class.

### Phase 3 — Ground every comment in the code

For each finding, open the real file at the real line in the local checkout. Never fix from the
comment text alone.

Line numbers belong to the patchset the comment was written on. They drift on every later edit. Use
the line as a starting point, then confirm the match by the code itself. A finding whose code is not
near the stated line is a candidate for **stale**, not a reason to edit that line.

Assign one state:

- **live** — the code still has the problem the comment describes.
- **stale** — a later patchset already handled it.
- **wrong** — the comment misreads the code.
- **blocked** — the fix needs a decision only the owner can make: a behavior change, a public
  signature, a redesign, or work that belongs in a separate change.
- **question** — the comment asks for information, not a change. Human threads, almost always.

Use `get_file_diff` when the local file and the comment disagree, to see what the author actually
read.

### Phase 4 — Propose the fix, the reply, or both

The state says what is true about the code. The author class says what to do about it:

| State    | Bot comment                          | Human comment                                      |
| -------- | ------------------------------------ | -------------------------------------------------- |
| live     | Fix. The new patchset answers it     | Fix, and reply saying what changed                 |
| stale    | Nothing. The new patchset answers it | Reply naming the patchset that handled it          |
| wrong    | `/aino` with the evidence            | Reply with the evidence, then leave it to them     |
| blocked  | Owner decides                        | Reply with the cost, offer a follow-up change, ask |
| question | Rare. Treat as `wrong`, or ignore    | Reply with the answer. No edit                     |

Two asymmetries drive that table, and they are worth holding onto rather than memorising cells.

A bot re-reads the code on every patchset, so a silent fix is a complete answer. A person does not:
they see a new patchset and a thread they raised, with no way to tell which of their six points you
took. So every human thread gets a reply, even when the fix is obvious and already pushed. The reply
is part of the deliverable, not a courtesy.

A bot has no standing to disagree with, so `/aino` closes the matter. A reviewer votes on the
change, so a disagreement is theirs to settle. Reply with the code that disproves the claim and stop
there — never resolve their thread for them, never argue a second round, and never treat your own
reading as the verdict.

For each **live** finding, write the fix as a concrete edit: file, line, and what changes. Prefer
the smallest correct change. A comment is not a licence to refactor.

Rank each fix `low`, `medium`, or `high` risk. High risk means the fix changes behavior, touches a
public signature, or edits a file the change did not otherwise touch. A suppression comment
(`eslint-disable`, `// nolint`, `@ts-ignore`) is a last resort. It hides the next failure too, so it
always needs a reason and owner approval — and when a person asked for the fix, the reply says you
suppressed rather than fixed, or the next reviewer inherits a lie.

Draft every reply and every `/aino` here, so the owner approves real text rather than an intention.
Read `references/reply-drafting.md` for the shape of each.

### Phase 5 — Report

Use the template in `references/report-template.md`.

Mode `audit`: write the report to `gerrit-review-fix-plan.md` in the repo root. Put a one-screen
summary and the path in chat.

Mode `full`: put the report in chat. Do not write a file.

Both modes: **stop here.** Ask which fixes to apply and which replies to post. Findings marked high
risk, blocked, or suppression need an explicit yes, and so does every reply and every `/aino` draft.
Record the answers as `approved` or `rejected`.

### Phase 5b — Resume from a plan

The plan is a proposal. The code is the truth.

1. Read the plan file.
2. Re-read the current comments with `list_change_comments`. A newer patchset brings new bot
   findings, and a reviewer may have replied since the plan was written.
3. Re-check each `approved` finding against the code. Mark a finding `stale` when the code moved,
   and say so instead of applying a dead fix. Drop a drafted reply whose thread the reviewer has
   since closed.
4. Report the delta in one short list, then continue to Phase 6.

### Phase 6 — Apply

Apply the approved fixes, grouped by file. Take the blocking human findings first: a reviewer's `-1`
is what holds the change, so if the session runs short, that is the work that mattered. Nits go
last.

Keep each edit inside the scope of its finding. Do not reformat untouched lines. Do not rename
anything the findings did not name.

Every edit shifts the lines below it. Re-read the file before the next fix in that file and find the
site by its code, not by the line number in the report.

Update the plan file status to `done` after each fix when a plan file exists, and note what its
reply must now say — "fixed in patchset 4" needs the patchset number the push is about to produce.

### Phase 7 — Verify and push

1. Run the checks the repo itself defines. Read the scripts in `package.json`, the `Makefile`, or
   the CI config. Run the build, the type check, the lint, and the tests that cover the touched
   files.
2. A failing check stops the push. Report the failure and the fix that caused it.
3. `git add` the touched files. Run `git commit --amend --no-edit`.
4. Confirm the `Change-Id` trailer survived: `git log -1 --format=%B | grep Change-Id`. A lost
   trailer creates a second change on push, so stop when it is gone.
5. **Ask before the push.** A push publishes a patchset to every reviewer and sends mail. Show the
   command and wait.
6. `git push <remote> HEAD:refs/for/<target>`, with both values from Phase 0b. Add `%topic=<topic>`
   only when the change already carries a topic. `HEAD:` works from a detached head and from a topic
   branch with any name, so use it either way.
7. Report the new patchset URL, then continue to Phase 8.

### Phase 8 — Answer the reviewers

Post only what the owner approved at Phase 5. Run this after the push, so each thread reads in
order: the claim, the new code, the answer.

1. Stage each reply with `post_draft_comment` on the same file and line as the comment it answers,
   with `in_reply_to` set to that comment id. The thread carries across patchsets, so the reply
   lands in the right place even though the line moved.
2. Read the staged set back with `list_draft_comments`, **show the exact text, and ask once.** Every
   reply is public and sends mail. A batch of six gets one confirmation, not six.
3. `publish_drafts` once, so the reviewers get a single notification for the whole set instead of
   one per thread. Use `delete_draft_comment` to pull a draft the owner rejects at this point.
4. Set the status to `posted` in the plan file when a plan file exists.
5. Bot findings only: ask whether to re-run the bot. The trigger is `/aireview` as a patchset-level
   comment. Post it, then stop. Do not wait, do not sleep, and do not poll for the reply. The
   turnaround is minutes on a good day and much longer on a bad one, and sometimes the bot never
   answers. Never quote a time to the owner. Tell them to re-run this skill on the new patchset once
   they see the reply, and offer to check on request.
6. Close with: fixes applied, fixes rejected, bot findings dismissed, replies posted, threads now
   waiting on a reviewer, findings that still need the owner (`blocked`), and the patchset URL.

## Guardrails

- Never rebase, reset, force-push, or push to `refs/heads/*`. Amend and push to `refs/for`.
- Never hardcode `master`, `main`, or `origin`. Take the target branch from Gerrit and the remote
  from git config. The local branch name proves nothing.
- Never amend a commit that is not the local head. Report the position and stop.
- Never drop or edit the `Change-Id` trailer.
- Never amend when the tree holds unrelated changes. Report the dirty files and stop.
- Never post to Gerrit without owner approval. Reading is free, writing is not.
- Never `/aino` a person, and never `/aino` a bot finding on your own judgement. The owner approves
  every one.
- Never fix or dismiss a comment you could not ground in Phase 3.
- Never leave a human thread unanswered without saying so. Silence reads as agreement that was never
  given.
- Never vote on the change, resolve a reviewer's thread on their behalf, or set it ready for review.
  Those belong to the owner and the reviewer.

## Report status vocabulary

`proposed` → `approved` | `rejected` → `done` | `posted` | `dismissed`. Plus `live`, `stale`,
`wrong`, `blocked`, and `question` from Phase 3.

## Files

- `references/comment-classes.md` — the common bot and human comment classes, the fix pattern for
  each, and the known false positives. Read it at Phase 2 or Phase 3.
- `references/reply-drafting.md` — the shape of an `/aino` and of a reply to a person, with worked
  examples. Read it at Phase 4.
- `references/report-template.md` — the Phase 5 output shape. Read it at Phase 5.
