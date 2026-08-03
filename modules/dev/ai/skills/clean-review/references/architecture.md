# Architecture

The question is how much you must understand to change one thing. If a small change forces edits in five modules, the boundaries are wrong. If a module cannot be read without reading its callers, it has no boundary.

Most architecture findings in a cleanup are deletions. A layer that forwards. An interface with one implementer. A folder that duplicates another. Prefer those. Structural change with no deletion is a rewrite, and a rewrite is T4.

## Contents

- The documented shape against the real shape
- Dependency direction
- Cycles
- God modules
- Premature abstraction
- Folder and naming drift
- Boundaries that leak types
- Configuration sprawl
- Language notes
- Before you propose a structural change

## The documented shape against the real shape

Print the tree. Read the architecture section of the README, or of CLAUDE.md. Compare them.

Findings:

- A layer in the document that does not exist in the tree.
- A directory in the tree that no document mentions.
- Two names for one thing. The document says adapters, the code says clients.
- A rule stated in the document and broken in the code, such as a domain module that must not touch storage.

Report drift even when the code works. A wrong map costs every later reader. A broken stated rule also belongs in `constraint-evasion.md`, because somebody chose the shortcut once.

## Dependency direction

Draw the imports between top-level directories. One arrow per direction, with a count.

Rules that hold in most stacks:

- Business rules do not import transport, storage, or the framework.
- An inner layer does not import an outer layer.
- Two sibling features do not import each other. They meet in a parent.
- A type that two features share lives in a module both import, not in whichever feature declared it first.

Signals:

- A domain module that imports a network client, a database library, or a logger.
- A shared module that imports a feature module.
- A test utility imported by product code.
- A relative import that climbs three levels or more.

Fix, cheapest first. Move the file. Then invert the dependency with a plain function parameter. Define an interface only when two real implementers exist.

## Cycles

Find cycles with the tool listed in `scans.md`. A cycle means two modules are one module, split in the wrong place.

Common causes:

- A re-export file that gathers everything in a directory.
- A type declared in the module that uses it, rather than in a module both can import.
- A utility that grew a dependency on a feature.

Fix, in order of preference:

1. Move the shared type or function to a leaf module that both import.
2. Delete the re-export file and import directly.
3. Pass the dependency as an argument instead of importing it.

Report each cycle with the two files and the import that closes it.

## God modules

Signals:

- A file over 500 lines with more than one reason to change.
- A module that most files in the repository import.
- A module that imports more than 15 others.
- A name that describes no domain, such as utilities, helpers, common, library, or miscellaneous.
- Many callers that use one exported name from the module and nothing else.

Fix: split by consumer, not by kind. Group what changes together. Ten functions with nothing in common belong beside the code that calls them.

Check first whether half of the module is dead. A god module often carries several T1 deletes.

## Premature abstraction

Cleanup deletes indirection more often than it adds indirection.

Each signal below is a T1 or T2 delete:

- An interface, a protocol, or an abstract class with one implementer.
- A factory that constructs one type.
- A wrapper whose every method forwards to the same method of one field.
- A type parameter that is the same type at every call site.
- A config option with one value in the whole repository.
- A plugin or strategy mechanism with one plugin.
- A layer added for a second provider that never arrived.

Fix: inline it. Delete the abstraction, the tests for the abstraction, and the wiring.

An interface that exists only to allow a fake object is not a reason to keep the interface. Extract the pure decision and test that instead. See `purity-and-effects.md`.

## Folder and naming drift

Signals:

- Two folders with overlapping duties, such as services beside managers.
- One concept under three names across layers, such as account, user, and profile.
- A layout that mixes grouping by kind with grouping by feature. Pick one.
- Test files in two places under two conventions.
- Dead entries in the workspace, path-alias, or module configuration.

Naming is cheap to fix and pays at every search. Use one name for one thing.

## Boundaries that leak types

A boundary that passes its internal shapes outward is not a boundary.

Signals:

- A database row type used in an external response.
- A framework request object passed into a business rule.
- A generated client type used as the domain type.
- An internal set of cases serialized straight into an external contract, so an internal rename breaks a consumer.

Fix: declare the type the boundary owns, and parse into it. This connects to `type-modeling.md`. The parse is the boundary.

## Configuration sprawl

- Environment variables read in many files. Read them once at startup, parse them into one config value, and pass it down.
- One default value written in three places.
- Config files for tools the project removed.
- Two sources of truth for one setting, such as an environment variable and a file.

## Language notes

- **Package-oriented languages**, such as Go, Java, or Rust: the compiler already forbids or warns on cycles between packages or crates. Use it. A cycle inside one package still hides, so check file-level imports too.
- **TypeScript and JavaScript**: re-export files hide cycles and defeat dead-code removal in the bundler. Deleting them often resolves several findings at once. Path aliases drift, so check that each alias still points somewhere.
- **Python**: an import at module scope runs code. A cycle then shows up as a partly initialized module at run time, not as a build error. Move shared types to a leaf module rather than deferring imports into function bodies.
- **Haskell and other module-per-file languages**: the compiler forbids cycles outright, so the drift moves into one very large module. Watch file size and the export list. A module that exports everything has no interface.
- **Monorepos in any language**: check the dependency graph between packages as well as between directories. A package that everything depends on is a god module with a version number.

## Before you propose a structural change

Answer all five questions.

1. Which change is hard today, and which files does it touch?
2. What is the target shape, in one sentence?
3. What does the move delete?
4. Which test protects the behavior during the move? If none exists, that is the first task.
5. Can the move run in slices that each build and pass? If not, the item is T4 and needs its own branch.

If the answer to question 3 is nothing, do not propose the change. Record the observation and move on.
