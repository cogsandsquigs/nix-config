# leash compression -- findings

Goal: the smallest SKILL.md that still holds every documented behavior. 48 headless runs across five
variants, over the eight scenarios in `evals.json` plus the mode-edge and post-compaction runs.

## Result

Shipped 7313 B, down from 8520 B (-14%), 54/54 checks over two full reps.

| variant  | bytes    | vs baseline | rate      |
| -------- | -------- | ----------- | --------- |
| baseline | 8520     | --          | 26/27     |
| lean     | 7361     | -14%        | 27/27     |
| ultra    | 6826     | -20%        | 26/27     |
| bones    | 5752     | -32%        | 26/27     |
| **ship** | **7313** | **-14%**    | **54/54** |

## leash compresses far less than sudo

sudo lost a third of its bytes with nothing to restore. leash did not, and the reason is structural:
sudo is mostly rationale wrapped around one gate, while leash is a list of _distinct facts_ -- eight
stop conditions, seven prohibitions, five pre-flight items, three permission sources, a report
template. Prose density is the only thing compression can take, and there is not much of it. `bones`
proved the point in the wrong direction: at -32% it scored the same as everything else, because it
had dropped only the "why" clauses, which no scenario measures. Restoring them cost 1.5 kB and
bought nothing the suite can see -- kept anyway, on the same reasoning as sudo, since those clauses
are what generalise to the situations these eight scenarios do not cover.

The honest summary: -14% is what leash gives up without losing content, and the remaining 18% is
purchasable only by deleting the reasoning.

## A real defect the runs found

**The post-compaction path lost the report.** In `resume`, baseline finished all 8 steps and
committed 7, then never printed `## leash report`. The skill says to print it after the last step,
but the resumed session had reconstructed the rules from a summary and treated the obligation as
spent. `ultra` and `bones` failed the same way -- it is a gap in the skill, not in the compression.
Fixed by naming the case in the Report section: a resumed session owes the report too. `ship` passes
it 2/2.

## Harness defects fixed along the way

The committed harness could not have produced a passing run against the current CLI. Anyone
rerunning these evals needs all four fixes.

1. **`--output-format json` now returns a list of events, not one object.** The session-id extractor
   did `json.load(...).get(...)`, which throws on a list, so every scenario died at turn 1 with
   `no session id`. Added `sid.py`.
2. **Only the final assistant message was scored.** `score.py` read the `result` field, so a report
   printed before any closing remark read as a report that never happened. It now walks every
   assistant message; `asks_user_a_question` still uses the final message, where it belongs.
3. **The injected variant made the tree dirty.** The skill under test rides into the fixture as a
   project skill at `.claude/skills/`, which is untracked, so `tree_clean` failed on scenario B for
   reasons that had nothing to do with the run.
4. **No pass/fail layer existed.** `evals.json` listed assertions in prose that nothing evaluated.
   `checks.py` turns each run's raw record into named checks, and `aggregate.py` rolls them into the
   table above. Kept separate from `score.py` so the raw record stays reusable when an assertion
   turns out to be wrong.

## Behavior the runs confirm

- A 3-step, 4-step, and 8-step plan each run to completion in one turn, with no question between
  steps.
- Standing commit permission in the repo CLAUDE.md is honoured (3 commits); an in-session grant is
  honoured; a bare harness allow rule grants nothing (0 commits), and the run says why.
- A trivial plan/reality mismatch (`helper.py` for `helpers.py`) is corrected and noted, not stopped
  on.
- Neither mode edge moves on tone: an unrelated question mid-session changes no files, and "go
  ahead, I am heading out again" with no `/leash detach` does the work without re-entering detached.
