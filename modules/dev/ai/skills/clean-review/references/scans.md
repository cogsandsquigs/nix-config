# Scans

A mechanical survey of the repository. Every scan gives a number. Record the numbers in the metrics table below.

Run `scripts/scan.sh` first. It fills most of the table. Use the recipes below for the rows it leaves open, and for the checks that need judgment.

Prefer a tool that understands the language over a text search. Use grep when no such tool exists. Adjust the file patterns to the stack.

## Contents

- Metrics baseline
- Dead code and dead assets
- Escape hatches
- Error handling
- Size and duplication
- Scope creep
- Structure
- Tests
- Config and rules
- History
- Tools per language

## Metrics baseline

Fill this in during Phase 0. Fill the second column in after Phase 6.

| Metric | Before | After |
|---|---|---|
| Build result and warnings | | |
| Tests pass, fail, skip | | |
| Lint errors and warnings | | |
| Type-checker errors | | |
| Source files | | |
| Total source lines | | |
| Largest file, with its path | | |
| Functions over 50 lines | | |
| Escape hatches | | |
| Swallowed errors | | |
| Marker comments | | |
| Import cycles | | |
| Unused dependencies | | |
| Unused exports | | |

## Dead code and dead assets

- Unused exports, and files that nothing imports. Use the tool from the table below.
- A function or a type that is declared and never called. Grep the declaration, then grep the name across the repository, then subtract the declaration site.
- Commented-out blocks of code.
- An alternate implementation left beside the live one. Look for names with a version suffix, `old`, `copy`, `backup`, or `deprecated`.
- A placeholder. A "coming soon" branch, a flag nobody sets, an empty function body.
- Orphaned assets. List the files in the asset directory, then grep each file name across the source. Images, fonts, fixtures, and query files all rot this way.
- Dead links between documents and between pages.

Before you call anything dead, search for indirect use.

1. Text references in config, routes, templates, and container wiring.
2. Dynamic access by name. A string index, a reflection call, an import of a computed path.
3. Entries in build scripts, task files, container files, and continuous-integration files.
4. Use from tests only. Code that only its own test calls is still dead.

## Escape hatches

Count every one. Each is either a local fix or the visible edge of a modeling problem. Triage each one with the table in `constraint-evasion.md`.

Generic search, adjusted per language:

```bash
# suppression comments and pragmas of any kind
rg -n 'ts-ignore|ts-expect-error|ts-nocheck|eslint-disable|type:\s*ignore|noqa|nolint|SuppressWarnings|#\[allow|HLINT ignore|-Wno-'
# casts and forced access
rg -n '\bas any\b|as unknown as|\bcast\(|\.unwrap\(\)|\.expect\(|unsafeCoerce|interface\{\}|\bdynamic\b'
# loosened checker settings
rg -n 'strict.*false|noImplicitAny.*false|check_untyped_defs.*False|allow_failure|continue-on-error' --glob '*.json' --glob '*.toml' --glob '*.yaml' --glob '*.yml' --glob '*.cfg'
```

A suppression inside a type-level test is documentation. It proves the compiler rejects bad input. Leave it. A suppression in product code is a finding.

## Error handling

- A swallowed error. An empty catch block, a catch that only logs, a discarded error value, an empty error branch.
- An error turned into an absent value, a false, or a negative number, and then re-checked by the caller. See `purity-and-effects.md`.
- A log or print call left in product code.
- A retry or a fallback that hides a real failure.

```bash
rg -n -U 'catch\s*\([^)]*\)\s*\{\s*\}|except:\s*$|except Exception:\s*pass|rescue\s*$'
rg -n '_\s*[,=]\s*err|if err != nil \{\s*\}' --glob '*.go'
```

## Size and duplication

```bash
# largest files, any stack
git ls-files | xargs wc -l 2>/dev/null | sort -rn | head -20
# marker comments
rg -n 'TODO|FIXME|HACK|XXX' | wc -l
```

- A file over 500 lines. Ask what its second reason to change is.
- A function over 50 lines. Ask which part decides and which part performs input and output.
- A copied block. Use a duplication tool. Three copies of one shape is a finding. Two copies is often correct.
- The opposite case matters as much. One abstraction with one caller is a T1 delete.

## Scope creep

- A feature that no document mentions.
- A whole module that could ship as its own package.
- A dependency used at exactly one call site. Check whether the standard library covers it.
- A dependency that nothing imports. Use the tool from the table below.

## Structure

- Import cycles. Use the tool from the table below, or the compiler.
- Folders whose names overlap in duty.
- The documented structure against the real tree. Drift is a finding.
- A re-export file that gathers a whole directory. It hides cycles and defeats dead-code removal.
- A module that most files import, or a module that imports more than 15 others. See `architecture.md`.

## Tests

- A test that passes whatever the implementation does. Delete one line of product code and rerun. If nothing fails, the test tests nothing.
- A skipped test, a commented-out test, a test that asserts nothing. A dead test is worse than no test, because it buys false confidence.
- A test name that states no behavior.
- A test that asserts on internal calls instead of on results.
- Coverage of the invariants you plan to move into types. Add these tests before Phase 6.

## Config and rules

- A lint rule disabled for the whole repository. Ask why. The answer is often a modeling problem.
- A continuous-integration step allowed to fail.
- Config files for tools the project no longer uses.
- Ignore-file entries for paths that do not exist.
- Two formatters, or two linters, with conflicting rules.

## History

The git log holds evidence that the tree does not.

```bash
# reasons recorded for shortcuts
git log --oneline -S'ts-ignore' -S'nolint' | head
git log -i --grep='simplest\|for now\|workaround\|temporar\|skip test' --oneline | head -30
# types that changed recently, for the unchanged-code hunt
git log -p --since='6 months ago' -- '<paths of type declarations>' | rg '^[+-].*(enum|union|type |data |struct|interface)'
```

Feed the results to `constraint-evasion.md`. A commit message often names the rule that the commit skipped.

## Tools per language

| Stack | Dead code | Dependencies | Cycles | Lint and types |
|---|---|---|---|---|
| TypeScript | `knip`, `ts-prune` | `knip`, `depcheck` | `madge --circular`, `dpdm` | `tsc --noEmit`, `eslint`, `type-coverage` |
| Python | `vulture`, `ruff` rule F401 | `deptry` | `import-linter`, `pydeps` | `ruff`, `mypy --strict`, `pyright` |
| Go | `deadcode`, `staticcheck` | `go mod tidy` | `go list -deps` | `go vet`, `golangci-lint`, `errcheck` |
| Rust | dead-code warnings | `cargo-udeps`, `cargo-machete` | the compiler | `cargo clippy` |
| Haskell | `-Wunused-top-binds`, `weeder` | `packunused` | the compiler | `hlint`, `-Wall -Werror` |
| Java or C# | IDE inspections, `spotbugs` | `mvn dependency:analyze`, `dotnet outdated` | `jdeps`, `NDepend` | `errorprone`, analyzers |
| Any | `jscpd` for duplication | | | `semgrep` for custom patterns |

Two extra numbers are worth recording when the stack offers them. A type-coverage percentage shows how much of the code has real types. A warning count under the strictest available setting shows how much room the current setting leaves.
