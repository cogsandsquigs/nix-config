# Detecting project conventions

"Match existing conventions" is easy to say and easy to do badly. The usual failures are skimming
one nearby file and generalizing too far, or ignoring convention and writing in a generic house
style. This is the pass to run before writing new code into an existing project.

## Contents

- What to look at, in order
- Fast heuristics when time-constrained
- When convention conflicts with your judgment

## What to look at, in order

1. **Formatter and linter config.** The fastest and most authoritative signal, because it is
   enforced mechanically rather than remembered.
   - Rust: `rustfmt.toml`, `.rustfmt.toml`, `clippy.toml` -- check `edition`, `max_width`, and denied
     lints. `#![deny(...)]` in `lib.rs` or `main.rs` is worth reading directly.
   - TypeScript and JavaScript: `.eslintrc*`, `.prettierrc*`, `tsconfig.json`. `strict` and
     `noImplicitAny` tell you how tight the typing culture is.
   - Go: `.golangci.yml`. `gofmt` removes most style variance, so the remaining opinions live in the
     linter config.
   - Haskell: `.hlint.yaml`, `stylish-haskell.yaml`, or format hints in `*.cabal` / `package.yaml`
     (the `ghc-options` extension list tells you whether `OverloadedStrings` or `LambdaCase` are on
     by default).

2. **A representative existing feature, not the nearest file.** Pick something structurally similar
   to what you are adding -- another handler, another parser, another CLI subcommand. The nearest
   file may be an outlier.

3. **The error-handling idiom.** This varies more than almost anything else and is highly visible
   when mismatched.
   - Rust: `Result<T, E>` with `?` and a custom error enum (often `thiserror`), against
     `anyhow::Error` for application code. `panic!` and `.unwrap()` usually appear only in tests and
     genuinely impossible branches. Check which the codebase picked.
   - Go: sentinel errors with `errors.Is`, wrapped errors via `fmt.Errorf("...: %w", err)`, or a
     custom error type. Go codebases are inconsistent across the ecosystem, so check locally.
   - TypeScript: exceptions, against `Result`-style returns
     (`{ ok: true, value } | { ok: false, error }`). Common in codebases that value explicitness,
     far from universal.
   - Haskell: `Either e a`, `ExceptT` stacks, or exceptions via `throwIO`. This tells you how pure
     the codebase's error philosophy is.

4. **Module and file layout.** Does the project group by layer (`handlers/`, `models/`, `services/`)
   or by feature (`orders/`, `users/`, each holding its own handler, model, and service)? Follow
   whichever the project committed to, even when the other style is arguably better in the abstract.

5. **Naming.** Check case conventions per identifier kind, not globally -- some codebases use
   different conventions for constants, functions, and types. Check whether the project prefers
   verbose or terse names (`fetch_user_by_id` against `get_user`).

6. **Test style**, if tests exist: table-driven (common in Go), one `#[test]` per case (common in
   Rust), `describe`/`it` blocks (common in TypeScript), or property-based tests through `proptest`,
   `QuickCheck`, or `fast-check` where one is already in use. Match the existing shape rather than
   introducing a second test style into the same project.

## Fast heuristics when time-constrained

- Read the CI config (`.github/workflows/*.yml`, `.gitlab-ci.yml`). It names the exact lint, format,
  and test commands that are enforced, which separates what maintainers actually require from what a
  CONTRIBUTING.md merely aspires to.
- Read `CONTRIBUTING.md`, `CLAUDE.md`, `AGENTS.md`, or `.cursorrules` if present. Projects
  increasingly document conventions explicitly for exactly this reason.
- If a dependency-injection or plugin pattern is already established, extend it. Do not introduce a
  second way of wiring things together, even when the new piece would be simpler standalone.

## When convention conflicts with your judgment

Existing convention wins by default. Consistency has value independent of whether the original
choice was optimal. If a convention is actively harmful rather than merely not your preference, say
so in a sentence and let the user decide. Do not override it silently, and do not comply silently
against your own judgment.
