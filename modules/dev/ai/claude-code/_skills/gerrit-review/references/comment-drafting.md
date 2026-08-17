# Drafting the review

Two artifacts: the inline comments, and the cover message that goes out with them. They do different
jobs, and the commonest wording failure is putting one's content in the other.

## Inline comments

An inline comment lands on a line the author is looking at, so it should say the smallest thing that
lets them act: what is wrong, why it matters, and what would fix it. Three sentences at most. The
author has fourteen other things to read.

**Label the severity, so the author can triage.** A prefix does this in one word, and it is the
cheapest kindness in a review — without it every comment reads as a demand.

```text
nit: `usr` reads as a typo for `user` here.
question: is `ctx` already cancelled by the time this runs?
blocking: this drops the error from `parseConfig`, so a bad config starts the server with defaults.
```

Match the prefix to the `unresolved` flag: `nit` and praise go out with `unresolved: false`, so an
optional remark does not land in the author's must-answer list.

**Lead with the consequence, not the observation.** The author decides what to do based on what
breaks.

```text
Good  This returns before `conn.Close()`, so a malformed request leaks a connection — the pool
      exhausts under a scanner hitting the endpoint.
Bad   Missing Close() on the error path.
```

Both are true. The first tells them why it is worth their next ten minutes.

**Give the failing case, not an adjective.**

```text
Good  With `items` empty, `items[len(items)-1]` panics — the digest job hits this on a day with no
      events.
Bad   This looks unsafe for empty input.
```

**Ask, when you are asking.** A question phrased as an instruction wastes a round when the answer
was "the caller guarantees it".

```text
Good  question: is `id` validated before this? If it can arrive unparsed, the query below
      interpolates it directly.
Bad   Validate `id` before using it in the query.
```

**Suggest rather than dictate on anything with a judgement in it.** You may be missing the
constraint that produced the code.

```text
Good  Would a `map[string]struct{}` work here? The slice makes this O(n²) at the 10k configs we see
      in prod, unless order matters somewhere I've missed.
Bad   Use a map instead of a slice.
```

**Never comment on the person.** The code is the subject, always. This is not politeness for its own
sake: "you forgot" invites a defence, "this misses" invites a fix.

```text
Good  This misses the nil case when `cfg` comes from the flag path.
Bad   You forgot to handle nil here again.
```

**Say it once.** A rule broken in nine places is one comment on the first site naming the other
eight, not nine comments. Nine identical comments read as an audit rather than a review.

**Praise is a real comment, and rationed.** One or two per review, and only for something
non-obvious — a subtle case handled, a nasty piece of prior art untangled. Praise for ordinary
competence reads as padding, and it teaches the author to skim.

```text
Good  Nice — the retry keying on the idempotency token rather than the request id is what makes the
      duplicate-webhook case safe.
Bad   Great work on this file!
```

### Using `suggestion`

`post_draft_comment` takes a `suggestion`, which Gerrit renders as a one-click edit. Attach one only
when the fix is mechanical and there is exactly one right answer: a typo, a missing `await`, an
off-by-one, a wrong constant.

Never attach one to a design point. A one-click apply invites the author to take the change without
the thought behind it, and if your suggestion is subtly wrong you have handed them a defect that now
carries a reviewer's endorsement.

## The cover message

The cover message is the review's summary, and it is the only part the author reads before deciding
how to feel about the whole thing. It carries what does not belong on any single line:

- What the change does, in your words. This is how the author learns whether you understood it — and
  when you did not, that is the most useful signal in the review.
- The one or two things that matter most, named, so triage is possible before reading line by line.
- Anything about the change as a whole: scope, size, splitting, a design question, a pre-existing
  defect you noticed but are not asking them to fix.
- What you did not review. Skimmed files, generated content, a dimension you ran out of budget for.
  Silence here implies a completeness you did not deliver, and it is what makes a `+1` misleading.
- The vote, and what it rests on.

Shape it like this — four short paragraphs at most:

```text
Reviewed patchset 4. This moves session expiry from the request path into the background sweeper,
and adds the `last_seen` column to back it.

Two things worth a look before this lands. The sweeper deletes on `last_seen < now - ttl` without
a transaction around the read, so a session touched mid-sweep can be dropped (comment on
sweeper.go:88). And the migration adds the column without a default, which the running deploy's
old writers will fail on — worth confirming the rollout order.

I skimmed the generated client and did not review the vendored protobufs. Nothing on style; the
linter has that covered.

Voting -1 on the sweeper race only — happy to +2 once that one's settled.
```

That message works because it does four things in order: proves it was read, names the blockers,
marks its own gaps, and ties the vote to a specific finding the author can go and fix.

## Rules for the whole review

- Review the change, not the change you would have written. A different reasonable approach is not a
  finding.
- Review against the repo's conventions, not your own. A pattern the codebase uses nowhere is not
  something to introduce through somebody else's change.
- Never claim the code does something without having read it. A wrong comment stated confidently
  costs more trust than five good ones earn, and the author remembers it on the next review.
- Never let the count stand in for the work. Fourteen comments on a change with an unfound race
  condition is a failed review, however busy it looks.
- Never bury the important finding in the middle. If one thing matters, it goes in the cover message
  and it goes first.
- Tie the vote to named findings. "-1" with no finding attached is unactionable, and a `+2` with
  unreviewed parts is a claim you cannot support.
- Name a change by its number or its `Change-Id`, never by a commit sha. A rebase or a cherry-pick
  gives the change a new sha and keeps the `Change-Id`, so a sha in a comment stops resolving. Use a
  patchset number when you do mean one specific revision — that is the only case a revision belongs
  in the text at all.
