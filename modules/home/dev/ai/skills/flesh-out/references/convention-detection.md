# Detecting Project Conventions

"Match existing conventions" is easy to say and easy to do badly — most agents either skim one
nearby file and generalize too far, or ignore convention entirely and write in a generic house
style. This is a concrete pass to run before writing new code into an existing project.

## What to look at, in order

1. **Formatter/linter config** — the fastest, most authoritative signal, because it's enforced
   mechanically rather than just habitual.
   - Rust: `rustfmt.toml`, `.rustfmt.toml`, `clippy.toml` — check for `edition`, `max_width`, denied
     lints (`#![deny(...)]` in `lib.rs`/`main.rs` is also worth reading directly).
   - TypeScript/JS: `.eslintrc*`, `.prettierrc*`, `tsconfig.json` (`strict`, `noImplicitAny` tell
     you how loose/tight the typing culture is).
   - Go: `.golangci.yml` — Go's own `gofmt` removes most style variance, so linter config is where
     the remaining opinions live.
   - Haskell: `.hlint.yaml`, `stylish-haskell.yaml`, or format hints in `*.cabal`/`package.yaml`
     (`ghc-options` extensions list, e.g. whether `OverloadedStrings` or `LambdaCase` are on by
     default).

2. **A representative existing feature, not just the nearest file.** Pick something structurally
   similar to what you're adding (another handler, another parser, another CLI subcommand) rather
   than whatever file happens to be open. The nearest file might be an outlier.

3. **Error handling idiom** — this varies more than almost anything else and is highly visible if
   mismatched:
   - Rust: `Result<T, E>` with `?` and a custom error enum (often via `thiserror`) vs.
     `anyhow::Error` for application code vs. `panic!`/`.unwrap()` used only in tests or
     genuinely-impossible branches. Check which the codebase already picked.
   - Go: sentinel errors (`errors.Is`), wrapped errors (`fmt.Errorf("...: %w", err)`), or a custom
     error type — Go codebases are inconsistent about this across the ecosystem, so check locally
     rather than assuming.
   - TypeScript: exceptions vs. `Result`-style return types
     (`{ ok: true, value } | { ok: false, error }`) — increasingly common in TS codebases that value
     explicitness, but far from universal.
   - Haskell: `Either e a` vs. `ExceptT` monad transformer stacks vs. exceptions via `throwIO` —
     tells you a lot about how "pure" the codebase's error philosophy is.

4. **Module/file layout** — does the project group by layer (`handlers/`, `models/`, `services/`) or
   by feature (`orders/`, `users/`, each containing its own handler+model+service)? New code should
   follow whichever the project already committed to, even if the other style is arguably better in
   the abstract.

5. **Naming**: check case conventions per identifier kind (not just "camelCase vs snake_case"
   globally — some codebases use different conventions for constants vs. functions vs. types), and
   whether the project prefers verbose or terse names (`fetch_user_by_id` vs `get_user`).

6. **Test style**, if tests exist: table-driven (common in Go), one `#[test]` per case (common in
   Rust), `describe`/`it` blocks (common in JS/TS), property-based tests via a library like
   `proptest`/`QuickCheck`/`fast-check` if already in use elsewhere. Match the existing shape rather
   than introducing a second test style into the same project.

## Fast heuristics when time-constrained

- Read the CI config (`.github/workflows/*.yml`, `.gitlab-ci.yml`) — it tells you exactly which
  lint/format/test commands are enforced, which is a strong signal of what actually matters to the
  maintainers versus what's merely aspirational in a CONTRIBUTING.md.
- Read `CONTRIBUTING.md` / `CLAUDE.md` / `AGENTS.md` / `.cursorrules` if present — projects
  increasingly document conventions explicitly for exactly this reason.
- If the project has a dependency-injection or plugin pattern already established, extend it rather
  than introducing a second way of wiring things together, even if your new piece would be simpler
  to write standalone.

## When conventions conflict with what you'd otherwise recommend

Existing convention wins by default — consistency has value independent of whether the original
choice was optimal. If you think the existing convention is actively harmful (not just
non-preferred), say so and let the user decide rather than silently overriding it or silently
complying against your judgment.
