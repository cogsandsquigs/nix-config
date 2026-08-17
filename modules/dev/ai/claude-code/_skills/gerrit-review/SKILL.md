---
name: gerrit-review
description:
    'Review somebody else''s Gerrit change and publish the review through the Gerrit MCP server.
    Fetches the patchset if it is not already local, reads the change against its stated intent,
    finds the defects that matter, presents them for approval, then posts them as inline comments
    with a cover message and, on explicit approval, a Code-Review vote. Trigger on any request to
    review, look at, critique, sanity-check, sign off on, approve, +2, -1, or give feedback on a
    Gerrit change, CL, patchset, Change-Id, refs/changes ref, or a commit somebody sent for review.
    This includes bare phrasings such as "review 35206", "can you look at Priya''s CL", "am I OK to
    +2 this", or "review my teammate''s change before I sign off". Also trigger when asked to
    re-review after a new patchset, to check whether earlier review comments were addressed, or to
    resume a review plan. Do not use it to address comments left on the owner''s own change — that
    is gerrit-review-fix — and do not use it to audit a whole codebase, which is goodreview.'
argument-hint: "[draft|post|full] [change|commit|plan-path]"
arguments: mode target
---

# gerrit-review

Review a change somebody else wrote, then publish the review.

The value of a review is the defect the author could not see, found before it ships. Everything else
— the style notes, the naming preferences, the observations that something is interesting — is
overhead the author pays for in reading time. A review of fourteen comments that misses the race
condition is worse than a review of two comments that finds it, because the author trusts the first
one.

So the bar for a comment is not "is this true?" It is "would the author want to know?" Hold that bar
and a short review is a good outcome.

This skill never edits the change. The code belongs to somebody else; the only artifacts it produces
are comments, a cover message, and a proposed vote.

## Arguments

`$mode` holds `draft`, `post`, or `full`. `$target` holds a change number, a Change-Id, a Gerrit
URL, a commit sha, or a path to a plan file. An argument the owner did not pass arrives empty.

- `$mode` empty: read the mode from the request. See the mode table.
- `$target` empty: ask. Unlike the sibling skill, there is no safe guess here — the local checkout
  says nothing about which of somebody else's changes to review, and reviewing the wrong CL wastes a
  colleague's attention.
- `$target` ends in `.md`: treat it as a plan file and use mode `post`.

## Modes

| Mode  | Phases | When                                                                        |
| ----- | ------ | --------------------------------------------------------------------------- |
| draft | 0–6    | Analyse and report. Ends with a plan file. Nothing posted to Gerrit         |
| post  | 6b–8   | A plan file exists, or the owner says post, send, publish, or continue      |
| full  | 0–8    | One session. Report in chat, **no plan file**. Stop at Phase 6 for approval |

Defaults:

- A question ("is this change OK?", "anything wrong with 35206?") means `draft`.
- An instruction ("review 35206 and send it") means `full`.
- In `full`, print the report in chat and stop. Do not write a plan file, because the owner reads
  the report in the same turn. Continue past Phase 6 in the same turn only when the owner said to
  post immediately, or said something equal to it.

A `draft` run that ends at a plan file is a complete job, not an abandoned one. Reviewing a large
change costs a lot of context, and wording the comments well needs room.

## Tools

This skill drives the official Gerrit MCP server. Read the parameter schema of each tool at call
time, because the local install can lag the upstream server. What this skill uses, and the limits
that shape the process:

- `get_change_details` — owner, project, branch, current patchset, status, existing label votes.
- `get_commit_message`, `get_bugs_from_cl` — the change's stated intent. Phase 1 reads these first.
- `changes_submitted_together` — the relation chain. A stacked change needs a different base.
- `list_change_files`, `get_file_diff` — **the latest patchset only.** Neither takes a patchset
  argument, so reviewing an older patchset, or diffing patchset 4 against patchset 5, has to happen
  against local refs. That is why Phase 0b fetches.
- `list_change_comments` — what the bot and the other reviewers already said. Phase 2 reads this so
  the review does not repeat it.
- `post_draft_comment` — one inline comment, private until published. Takes `line_number`, optional
  `start_line`/`end_line` for a range, `unresolved`, and `suggestion` for a one-click edit.
  **`unresolved` defaults to `true`**, so a nit or a note left at the default blocks the author's
  resolve-everything pass. Pass `false` deliberately for anything that is not a request.
- `list_draft_comments`, `delete_draft_comment` — read the staged set back, drop one the owner cuts.
- `publish_drafts` — sends every draft as one review, and carries the cover `message` and the
  `labels` vote with it. This is the "Send" button, and it is the only write in the whole skill that
  the author sees.
- `post_review_comment` — a single immediate comment that skips the draft stage. Avoid it: it mails
  the author per call, and it also carries `labels`, so a stray call can vote by accident.

`git` does the local work: fetch the patchset, read the code, run the build. Nothing writes to the
change.

## Process

### Phase 0 — Resolve the target and check it is reviewable

1. A number, a URL, or `.../c/project/+/12345/4` yields the change number, and a trailing segment
   yields the patchset.
2. A `Change-Id` (the `I`-prefixed hash) works directly as `change_id`.
3. A commit sha: search Gerrit for it with `query_changes`. Do not assume the local commit of that
   sha is what Gerrit holds — a local cherry-pick has a different sha and the same Change-Id.

Call `get_change_details`. Record owner, project, target branch, current patchset, status, and the
existing votes with the account behind each.

Then three checks, because each one makes the rest of the work pointless:

- **Merged or abandoned.** Say so and stop. A review on a merged change reaches nobody who can act.
- **The owner is you.** Compare the change owner against `git config user.email`. Reviewing your own
  change is not a review; if the request was really "check my change before I send it", say so and
  offer that instead.
- **You already voted.** Your account in the label list means this is a re-review, not a first pass.
  Go to Phase 2 expecting your own earlier comments, and treat "were they addressed?" as the first
  question of the review.

### Phase 0b — Get the code somewhere it can be read without disturbing anything

The reviewer's checkout is their own workspace, holding their own work. A review must not check
anything out over it, must not stash, and must not leave them on a detached head they did not ask
for. Fetch, then read from the fetched ref.

**Remote.** The remote whose URL holds the Gerrit host, from `git remote -v` — often `gerrit`, not
`origin`. One remote only: use it. Several and no match: ask.

**Fetch the patchset.** The ref is
`refs/changes/<last two digits of the change number>/<change number>/<patchset>`.

```bash
git fetch <remote> refs/changes/06/35206/4
```

`FETCH_HEAD` now holds the patchset. Fetch a second patchset the same way when the review is
incremental, and tag each sha as you go, because the next fetch overwrites `FETCH_HEAD`.

**Base for the diff.** Use the patchset's own first parent, `<sha>^`, not a merge-base against the
target branch. Gerrit diffs a change against its parent, and for a stacked change the parent is the
CL below it in the chain. Diff against the branch instead and the whole parent CL shows up as this
author's work — the fastest way to write a review full of comments on code they never touched. Call
`changes_submitted_together` when the parent looks unfamiliar, and say in the report which changes
sit below this one.

**Reading the change.** No checkout is needed for reading:

```bash
git diff <sha>^ <sha>                  # the whole change
git diff <old-sha> <sha>               # patchset 3 to patchset 4, for a re-review
git show <sha>:path/to/file.ts         # one full file as this patchset has it
git log --oneline <sha>^..<sha>        # the commits, if the patchset holds several
```

Read whole files, not only the diff. A diff hides the thing the change broke: the caller two hundred
lines up that assumed the old behavior, the invariant established in the constructor. Most defects
worth finding live in code the change did not touch.

**Building or testing it.** Only this needs a working tree, and it gets its own:

```bash
git worktree add /tmp/review-35206-p4 <sha>
```

A worktree leaves the reviewer's branch, index, and working tree untouched. Phase 8 removes it.
Never run the author's tests inside the reviewer's own tree.

### Phase 1 — Read the intent before the code

A change is only correct relative to what it set out to do, so read the claim first. Judging the
code before knowing the intent produces comments that argue with the design instead of the
implementation.

1. `get_commit_message` — what the author says this does, and how they say they verified it.
2. `get_bugs_from_cl`, and the bug itself when the tracker is reachable — the problem being solved.
   A change that fixes something other than what the bug describes is a finding, and a common one.
3. The files list and the diffstat — the shape and size of the change.
4. The surrounding code's own conventions: the README, `CLAUDE.md` or `AGENTS.md`, the neighbouring
   files. Review against the standards of the repo being changed, never against your own taste. A
   comment that asks for a pattern the repo does not use anywhere is noise, however good the
   pattern.

Write down, in one sentence each, what the change claims to do and what it actually does. When those
two sentences differ, that gap is usually the most valuable finding in the review, and it belongs in
the cover message rather than on a line.

### Phase 2 — Read what has already been said

Call `list_change_comments` before forming any finding of your own.

A review that repeats the bot costs the author the work of reading it twice and answering it twice.
Worse, it makes them read every comment defensively. So:

- Drop anything the bot already flagged. The bot's finding is already on the line.
- Drop anything another reviewer already raised, unless you can add evidence they did not have. Then
  reply in their thread rather than opening a parallel one.
- Read the threads the author already answered. An answered point is settled; reopening it needs a
  reason you can state.
- Re-review: check every comment you left last time against the current patchset. Addressed, partly
  addressed, or ignored — say which, per comment. This is the part of a re-review the author cannot
  do for themselves.

### Phase 3 — Map the change and choose a reading order

Do not review files in the order the diff lists them. Read for understanding first, in dependency
order:

1. The data shapes and types the change adds or alters.
2. The core logic that operates on them.
3. The callers and the wiring.
4. The tests.
5. Configuration, generated files, and lockfiles last — usually skim only.

Note the size honestly. Past roughly 400 changed lines, review quality falls off, and the useful
thing to tell the author is that the change wants splitting — say so early rather than after writing
thirty comments. Say what you skimmed rather than implying you read everything.

Generated files, vendored trees, and lockfiles get checked for one thing: that they match their
source. Do not comment on their contents.

### Phase 4 — Find the defects

Work through the dimensions in `references/review-dimensions.md`, in the order that file gives,
which runs from what breaks in production down to what only offends. Stop descending when the budget
runs out — an unfinished pass over correctness beats a complete pass over formatting.

For design defects that file hands off to the `goodreview` skill's lenses rather than restating
them, along with the one thing that keeps a design comment useful on a change already in flight: its
tiers of work were written for a codebase whose owner chose to clean it, and days-of-work findings
do not belong on somebody else's open change. The dimensions file gives the mapping.

For each candidate finding, write down what it is, where it is, and what goes wrong. If you cannot
state what goes wrong in one concrete sentence, you have an impression rather than a finding, and
Phase 5 will cut it anyway.

Assign a severity, because it decides both the wording and the vote:

| Severity | Means                                                 | `unresolved` | Vote it implies       |
| -------- | ----------------------------------------------------- | ------------ | --------------------- |
| blocking | Ships a defect, a vulnerability, or a broken contract | true         | -1                    |
| major    | Should be fixed now; cheaper here than in a follow-up | true         | -1 or 0, owner's call |
| minor    | Worth doing, would not hold the change                | true         | 0                     |
| nit      | Preference. Explicitly optional, and labelled as such | **false**    | 0                     |
| question | You cannot judge the code without an answer           | true         | 0                     |
| praise   | A non-obvious thing done well, worth naming once      | **false**    | —                     |

`unresolved: true` puts the comment in the author's must-answer list. A nit or a praise note left at
the tool's default `true` makes work out of something you said was optional, so set it `false`
deliberately.

Two severities carry a warning of their own. A **question** is the honest severity when the code
might be fine and you cannot tell; reaching for `blocking` to be safe pushes your uncertainty onto
the author as an obligation. And **praise** earns at most one or two comments per review — past that
it reads as padding and dilutes the findings.

### Phase 5 — Ground every finding, then cut

This phase exists because the characteristic failure of a machine-written review is the
confident-sounding comment that is simply wrong about the code. One of those costs more trust than
five good comments earn.

For every finding, in the actual file at the actual line:

1. **Confirm the code says what you think it says.** Read the whole function, not the diff hunk.
   Read the callers when the claim is about how it is called.
2. **State the failure concretely.** Which input, which order of events, which config reaches the
   bad state. A finding you cannot make concrete is a guess — cut it or drop it to `question`.
3. **Check it is not already handled** somewhere the diff does not show: a guard in the caller, a
   validation layer, a type that makes the state unreachable, an existing test.
4. **Check the finding is about this change.** A defect the change merely moved, or that was already
   there, is not this author's to fix. Mention it in the cover message if it matters; never make it
   a blocking comment on their line.

Then cut. For each surviving finding ask what the author does with it. If the answer is "reads it,
agrees, changes nothing", it is overhead — drop it or fold it into the cover message. Say in the
report how many you cut and why: it is evidence the bar was applied, and the owner may want one
back.

### Phase 6 — Report and propose a vote

Use the template in `references/report-template.md`. Draft the exact comment text here, so the owner
approves words rather than intentions. Read `references/comment-drafting.md` for the wording.

Mode `draft`: write the report to `gerrit-review-<number>-plan.md` in the repo root. A reviewer
holds several changes at once, so the number belongs in the filename. Put a one-screen summary and
the path in chat.

Mode `full`: put the report in chat. Do not write a file.

Propose a vote and say what it rests on:

| Vote | Means                                                                            |
| ---- | -------------------------------------------------------------------------------- |
| -1   | A blocking or major finding stands. Name the finding                             |
| 0    | Comments only. The right default when unsure, and when a question is outstanding |
| +1   | Looks right to you, without the authority or certainty to approve                |
| +2   | Approved. Only when you understood the whole change and would own it             |

Then **stop.** A vote is a statement about a colleague's work, `-1` blocks it, and `+2` may let it
submit — so the owner approves the vote explicitly and separately from the comments. Omitting
`labels` posts the comments with no vote at all, which is the honest option whenever the owner has
not said otherwise. Never infer a vote from the finding counts on your own.

Ask which comments to post, which to cut, and which vote. Record each as `approved` or `cut`.

### Phase 6b — Resume from a plan

The plan is a proposal. The change may have moved.

1. Read the plan file.
2. Call `get_change_details`. A new patchset since the plan means the line numbers in it are stale
   and some findings may be fixed already.
3. Re-fetch and re-check each approved finding against the current patchset. Drop the ones the
   author already fixed, and say so — posting a comment on a defect that is gone reads as not having
   looked.
4. Call `list_change_comments` again. Another reviewer may have said it in the meantime.
5. Report the delta in one short list, then continue to Phase 7.

### Phase 7 — Publish

1. Stage each approved comment with `post_draft_comment`: the file path and the line from the
   patchset under review, `unresolved` per the severity table, and `start_line`/`end_line` when the
   finding covers a range rather than one line.
2. Attach a `suggestion` only for a mechanical, unambiguous edit — a rename, a missing `await`, an
   off-by-one. It renders as a one-click apply, which is a gift on a typo and a trap on a design
   point, where it invites the author to take the change without the thought.
3. Reply in an existing thread with `in_reply_to` instead of opening a parallel one, when the point
   belongs to a conversation already under way.
4. Read the staged set back with `list_draft_comments`, **show the exact text and the vote, and ask
   once.** Everything about to be sent is public and permanent, and drafts are still private at this
   moment — this is the last point where anything can be pulled. Use `delete_draft_comment` for what
   the owner cuts here.
5. `publish_drafts` once, carrying the cover `message` and the approved `labels`. One call, one
   notification. Publishing per comment mails the author once per comment and scatters the review.
6. Report what went out: comment count by severity, the vote, and the change URL.

### Phase 8 — Clean up

Remove the worktree if Phase 0b made one:

```bash
git worktree remove /tmp/review-35206-p4
```

Confirm the reviewer's own branch, index, and working tree are as they were —
`git status --porcelain` and `git branch --show-current`. A review that leaves the workspace dirty
costs more than it gave.

Close with: comments posted by severity, comments cut and why, the vote, anything you did not review
(skimmed files, an unfinished dimension), and the change URL.

## Guardrails

- Never edit, amend, rebase, or push the change under review. It belongs to somebody else. A request
  to fix it is either gerrit-review-fix on the author's side or a follow-up change.
- Never check the patchset out over the reviewer's working tree, and never stash their work. Fetch
  and read from the ref; use a worktree when a build is needed.
- Never vote without explicit approval of that specific vote, and never treat approval of the
  comments as approval of the vote. Omit `labels` when in doubt.
- Never `+2` a change you did not read in full, and say which parts you skimmed.
- Never post a finding you did not confirm in the file at Phase 5.
- Never repeat what the bot or another reviewer already said.
- Never comment on generated, vendored, or lockfile content beyond whether it matches its source.
- Never diff against the target branch when the change is stacked. The parent CL is not this
  author's work.
- Never leave a nit or a praise note `unresolved`. It manufactures obligations out of optional
  remarks.
- Never publish per comment when a batch will do. One review, one notification.

## Report status vocabulary

`proposed` → `approved` | `cut` → `posted`. Severity from Phase 4: `blocking`, `major`, `minor`,
`nit`, `question`, `praise`.

## Files

- `references/review-dimensions.md` — what to look for, in priority order, with the bar for
  commenting on each. Read it at Phase 4. Its design dimension reads the `goodreview` skill's lens
  files (`~/.claude/skills/goodreview/references/`) rather than duplicating them, and adds the rule
  for what depth of design finding an in-flight change can carry.
- `references/comment-drafting.md` — how to word an inline comment and a cover message, with worked
  examples. Read it at Phase 6.
- `references/report-template.md` — the Phase 6 output shape. Read it at Phase 6.
