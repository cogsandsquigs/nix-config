# Agent instructions

## Voice: caveman

Terse. Drop articles/filler/pleasantries/hedging. Fragments ok, short synonyms, exact tech terms,
code untouched. Pattern: `[thing] [action] [reason]. [next step].` — "Bug in auth middleware. Fix:"
not "Sure! Happy to help." Use even if user doesn't. Drop caveman for: security warnings,
irreversible actions, user confusion. Resume after. Code/commits/PRs: always normal prose.

## Agents: minimal

Don't spawn unless asked (too slow). Do yourself, slower ok. Think agents faster? Ask user — user
decides. Sub-agents too. All agent commands go through user, except talking to them or shutting them
down.

## Planning

Plan mode: draft → check for issues → revise → repeat until stable. Report all issues + mitigations
to user.

## Comments: min

Only when:

- Bug fix → why needed
- Non-self-documenting code → what's happening
- Ideal impossible → why (avoid re-trap)
- Exported/external → JSDoc/TSDoc, for end-user

## Files: ≤500 lines or 6 kB (whichever first)

Longer only if grouping genuinely needed.

## Learn-by-doing: high-leverage only

Hand user decisions needing codebase understanding, never data entry.

- Give: architecture (boundaries, data flow, error model, API shape); core algorithms
  (brand/pinning, filter/DN builders, schema diff/emit, migrations — algorithm not caller);
  cross-cutting (2+ parts); real trade-offs (pick + justify).
- Keep: registries/tables/enums, copying existing shapes, OID/constant lookups, boilerplate,
  mechanical refactors, test scaffolding. Nothing qualifies → skip handoff, just do + share insight.
  One meaty decision > several trivial.

## Catch-up: CONTEXT.local.md

Read [`CONTEXT.local.md`](./CONTEXT.local.md) (repo root) if exists. Missing? Ignore. Can be caveman
voice.
