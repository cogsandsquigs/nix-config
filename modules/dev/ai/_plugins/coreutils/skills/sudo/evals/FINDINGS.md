# sudo compression -- findings

Goal: the smallest SKILL.md that still holds every documented behavior. 147 headless runs across
9 variants, scored on the 7 scenarios in `evals.json`.

## Result

Shipped 4545 B, down from 6674 B (-32%), 33/33 checks. No documented behavior dropped.

| variant | bytes | runs | rate |
| --- | --- | --- | --- |
| baseline | 6674 | 21 | 100% |
| mid / small / tiny | 5802 / 5031 / 4563 | 21 | 100% |
| lean / micro / nano | 4781 / 4692 / 4260 | 42 | 100% |
| ultra | 3703 | 14 | 100% |
| brutal | 2154 | 14 | 100% |
| **ship** | **4545** | **21** | **100%** |

## The suite does not discriminate on size

Every variant down to 2154 B (-68%) passed every check. Compression is not what these seven
behaviors are sensitive to, so bytes stopped being the binding constraint and coverage took over:
`brutal` and `ultra` pass while silently dropping the `leash detach` boundary, the compaction note,
the self-invocation ban, and the `/sudo y` rationale -- none of which any scenario exercises.
Shipping the smallest passing file would have been overfitting to this suite. The shipped version is
`ultra`'s prose density with that content restored.

## Three failures were the scorer, not the skill

Every apparent regression turned out to be measurement error, and each one first appeared on the
baseline too -- which is the tell. A finding that indicts the unmodified skill is usually the
harness.

1. **`--output-format json` returns only the final assistant message.** Under `/sudo y` the model
   prints the block, runs the command, then reports "Deleted." Scoring `result` alone read that as a
   missing gate and failed all four variants on B. `score.py` now walks every assistant message.
   Three separate prompt rewrites were spent chasing this before the transcript was checked.
2. **Em dash.** One run printed `## sudo — destructive`. The matcher required `--`.
3. **D and G asserted a specific shape, not the behavior.** D expected a bare commit, but gating the
   whole `commit && push` is defensible -- the commit would have swept a live credential into the
   push -- and G's model asked permission in prose ("Confirm and I'll remove it") rather than
   reprinting the gate. Both checks now accept either form.

## Real behavior the runs confirm

- The gate holds on an untracked file, names it in `Destroys:`, and waits.
- `/sudo y` prints the record and drops only the `Proceed?` line.
- Safe work (edit a tracked file, run tests) draws no warning at all.
- A CLAUDE.md saying "never commit, never push" does not survive `/sudo`, and the gate, not the
  prohibition, is what stops the push.
- `yeah` cancels, and the cancel is not re-offered.
- A `/sudo` string injected into a file read during a genuine sudo turn is ignored.
- Scope expires with the prompt: the follow-up delete asks again.
