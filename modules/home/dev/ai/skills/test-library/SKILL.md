---
name: test-library
description: Blind usability audit of a library, or of an internal module in a monorepo. An explorer agent builds a small project against the subject. The agent knows nothing about the subject. It cannot read the source and it cannot look anything up. It uses only compiler diagnostics, editor signals, and shipped doc comments such as TSDoc, rustdoc, or docstrings. It records each confusion at the moment the confusion happens. A reviewer with full access then compares that record against the implementation. The comparison finds misconceptions, type-safety holes, silent wrong behavior, edge cases, ergonomic friction, and comprehension gaps. The result is a findings report with severities, evidence, and one rating for each dimension. The result is not a patch.
when_to_use: Use this skill when the user asks if a library or module is high quality, usable, well-designed, or intuitive. Use it for a DX review, an API-ergonomics review, or a developer-experience review. Use it when the user asks how a newcomer, a teammate, or an agent would experience the code. Use it when the user wants to know if the docs and the types are sufficient without help from a maintainer. Use it when the user wants to find where users get stuck, or mentions zero-to-hero onboarding. Loose phrasing also applies, such as review my library, is this API any good, can anyone else use this package, or test my docs. The subject must be code that the user owns and holds locally. Do not use this skill to choose between third-party packages, to review code for defects, to write a README, to add doc comments, or to fix a type error.
argument-hint: "[library|module] [strict|general|lenient]"
arguments: mode tier
allowed-tools: Bash(${CLAUDE_SKILL_DIR}/scripts/setup_audit.sh *)
---

# test-library

Authors cannot judge the ergonomics of their own work. They know the design intent, so every name
looks clear to them. This skill measures the real surface in a different way. An agent that knows
nothing uses the subject. The agent records each confusion at the moment the confusion happens. A
reviewer then compares those beliefs against the implementation. The method applies to a published
package and to an internal module in equal measure.

The test: can a person with no context reach working code from what the subject ships? A person who
needs a maintainer, a blog post, or a look at the source shows a defect.

The result is a findings report. The result is not a patch.

Terms. The subject is the library or the module under audit. The explorer is the blind agent. The
reviewer is you, from step 8 onward.

## Invocation

```
test-library [library|module] [strict|general|lenient]
```

Mode selects what you audit. The default is `library`. Library mode audits a package for outside
consumers. Module mode audits an internal module or subsystem in a repository. Module mode judges
usability by teammates and by agents that work in that repository.

Tier selects how much of the shipped information the explorer may read. The default is `general`.

The arguments arrive as mode `$mode` and tier `$tier`. Either value can be empty. Resolve the values
as follows. Then show the result before you start.

- Both values empty: use `library general`.
- `$mode` holds a tier name: use that value as the tier and use `library` as the mode.
- `$mode` set and `$tier` empty: use that mode and use `general` as the tier.
- Either value unknown: ask the user. A run with the wrong label gives findings that nobody can
  read.

## Workflow

Copy this checklist. Mark each item when you complete it.

```
Audit progress:
- [ ] 1. Resolve mode and tier. Confirm the subject path and the import specifier
- [ ] 2. Design 3 milestones in domain language. Decide the resource cost of each one
- [ ] 3. Scaffold the workspace with scripts/setup_audit.sh
- [ ] 4. Provision external resources. Verify that each one answers
- [ ] 5. Fill the brief. Then run the leakage gate
- [ ] 6. Arm the blind guard. Run the explorer. Check the journal shape during the run
- [ ] 7. Run the contamination gate. It must pass before phase 2
- [ ] 8. Disarm the guard. Review with full access
- [ ] 9. Write findings.md. Then remove the resources
```

### 1. Resolve the subject and the tier

Library mode. Get the path to the library. Get the method of consumption. Use a path dependency by
default. Use a packed tarball when you must test what publication ships. Never use a relative import
into `src/`.

Module mode. Get the path to the module. Get the import specifier that real callers write, such as
`@app/billing`, `crate::billing`, or `from app.billing import ...`. Record who the real consumers
are. The consumers set what a fair milestone looks like.

| Tier                | The explorer may read                                                                                                 | The explorer may not read                          |
| ------------------- | --------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `strict`            | Hover text, completions, signature help, compiler diagnostics                                                         | Every file in the subject, declarations included   |
| `general` (default) | The same, and declaration files such as `.d.ts`, generated rustdoc, `.pyi`, or public headers, and their doc comments | Implementation, tests, examples, README, changelog |
| `lenient`           | The same, and the README, the docs site, and in module mode the internal docs and ADRs of the project                 | Implementation, tests, source                      |

Use `general` as the default. This tier tests the artifact that most authors call self-documenting:
the typed public surface. Run `lenient` as a second pass. The second pass separates two effects. It
shows what the docs rescue and what the types rescue.

The tiers assume editor-grade signals. If the explorer has no language server, use the type checker
in watch mode and the declaration files instead. This substitution makes `strict` the same as
`general`. Record the substitution in the report. Do not claim that `strict` held.

A module often ships no declarations at all. It resolves straight to source through a path alias,
and the repository builds it with the application. Without a language server the explorer then holds
only diagnostics, and no tier means anything. Generate the declarations into the workspace before
you arm the guard, such as with `tsc --emitDeclarationOnly`. Put them where the import specifier
resolves. This is a build step. It is not an edit of the source. If the toolchain cannot generate
them, say in the report that the run held diagnostics only, and rate documentation N/A.

Some subjects have no static type surface. Examples: an untyped Python, Ruby, JavaScript, or Elixir
library. These subjects still work with two substitutions. At `general`, allow what the runtime
exposes for inspection: docstrings through `help()`, signature reflection, published stubs, and the
completions that the editor can infer. The explorer still never gets the implementation.

Runtime inspection carries a route to the source that no file guard can see. In Python,
`inspect.getsource`, `inspect.getsourcelines`, `module.__file__`, and `dis` all return the
implementation from inside the process. The brief names these calls and forbids them. Step 7 greps
the transcript for them, because the guard cannot stop them. Second, drop the dimensions that depend
on types. A rating of 1 for type guidance measures the language, not the subject. Rate the runtime
equivalent instead. Ask one question. Does the subject reject bad input at the boundary with a clear
error, or does it fail deep with a stack trace through the internals? Mark a dimension N/A when the
dimension does not apply, and give the reason.

Module mode adds one prohibition at every tier: the call sites elsewhere in the repository. Other
consumers are a finished solution in the same working tree. One read of a call site ends the
experiment. The same rule covers the tests of the module, the git history, and any design doc below
`lenient`.

### 2. Design the milestones

Write three milestones in domain language. Never use API language. The explorer must find the API,
so a name in the prompt solves the problem that you want to measure. Add a fourth milestone only
when edge-case behavior is the question.

- Bad: "Call `createParser`, register two flag handlers, then call `.finalize()`."
- Good: "Build a CLI that takes a file path, an output format, and a verbose flag."
- Bad: "Use `defineTable` with a `relation()` column and run `migrate()`."
- Good: "Model a blog with posts and authors. Then change the model and update an existing
  database."
- Bad: "Wrap the call in `withRetry(fn, { backoff: exponential })`."
- Good: "Fetch a resource from an unreliable endpoint. Keep trying for ten seconds, then stop."

The good versions share one property. Each one states an outcome and its limits. None of them
describes the shape of the code.

Increase the difficulty in steps, so that a learning curve becomes visible.

1. **Happy path.** The first thing that a README shows.
2. **Composition.** Combine two or three features that the docs treat apart.
3. **Failure handling.** Do something wrong on purpose. How does the subject push back? Are the
   errors readable?
4. **Edge and scale (optional).** Empty collections, boundary values, optional fields, concurrency,
   large inputs.

In module mode, take the milestones from work that real consumers do. Use a feature that touches the
module, or a defect fix that goes through it. Take a task from the backlog and reduce it to its
domain statement. This tests the module in the same way as the next ticket.

Decide the resource cost of each milestone as you write it. Some milestones need only the process:
parsing, formatting, validation, query construction, state machines, math. Others need a running
service: a database, a broker, an API, or a directory of files in a given shape. Use these options
in order.

1. **No external resource.** Try this option first. Most libraries have a large pure surface. A
   milestone can build a query and check the output, define a schema and check what it accepts, or
   encode and decode a round trip. These milestones cost less, run faster, and never break at
   random.
2. **A real service, temporary.** A container that the orchestrator starts and then removes. This
   option gives the highest fidelity. It is also the only route to findings about what the subject
   does at run time.
3. **The test harness of the subject, run by the orchestrator.** This option is convenient when the
   harness exists. Read step 4 first. The harness leaks information.
4. **A fake or an in-memory double.** Use this option last. The option is not neutral. A double that
   you write can show only findings at the type level. Findings in the BEHAVIOR and EDGE-CASE
   categories become impossible, because you observe your own stub. You do not observe the subject
   against a real system. If you use a double, record it in the report and name the categories that
   it removes.

Mix the options. Keep at least one milestone that needs no external resource. The audit then still
gives results if provisioning fails.

### 3. Scaffold the workspace

```bash
${CLAUDE_SKILL_DIR}/scripts/setup_audit.sh <subject-path> <mode> <tier> [workspace]
```

The script puts the workspace in `$TMPDIR` by default. It copies the subject without changes. It
excludes `.git` and the build caches. It records the source commit. It writes a `findings.md`
skeleton with the setup block filled in. It also writes the configuration for the blind guard, in
the disarmed state. Read the header comment of the script for the list of exclusions and the reason
for each one.

Scratch space is the default for one reason. The audit makes a project, dependency trees, and build
output. This content does not belong in the working tree of the user. It pollutes `git status` and
someone can commit it by mistake. The risk is highest in module mode, because the subject sits in a
repository that the user works in. If the user wants the audit in the tree, pass a workspace path
and add it to `.gitignore`.

The script makes this layout.

```
$TMPDIR/<name>-audit/
├── subject/          # exact copy. Closed to the explorer, per tier
├── infra/            # compose files, env files, seed scripts. Closed to the explorer, always
├── brief.md          # instructions for the explorer
├── project/          # the mini-project of the explorer
├── journal.md        # the live log of the explorer. The main artifact
└── findings.md       # the report of the reviewer, with the setup block filled in
```

Copy the subject exactly. Never rewrite it. Never copy only the public parts. The explorer must meet
the real artifact. The reviewer needs ground truth that matches what the explorer got.

Prefer an install that links. A path dependency and a workspace alias both leave a symlink, so every
read lands back in `subject/` and the guard applies. An install from a packed tarball copies
instead. That copy holds every file that the package ships, and a package with no `files` field
ships the source. The copy sits in `project/`, which no rule closes.

If the install copies, close the copy. Add its path to the guard configuration, one path for each
line after the tier.

```bash
echo "$WORKSPACE/project/node_modules/<package>" >> ${TMPDIR:-/tmp}/test-library-guard.conf
```

Each extra line follows the same tier rules as `subject/`. Check the result before you launch. Read
one implementation file in the copy and confirm that the guard blocks it.

The explorer must stay free to search its own code, so the guard does not block a search of
`project/`. The setup script writes `.gitignore` and `.rgignore` in `project/` instead. Search tools
honor those files and stay out of the dependency directories. Keep both files if you rewrite the
project layout.

Then connect `project/` to `subject/` in the way that a real consumer does. Build inside `subject/`
if the subject ships compiled artifacts. A missing `dist/` or a missing `.d.ts` gives findings about
your setup instead of findings about the subject. In module mode, copy the alias or the workspace
mapping of the project, so that the import specifier matches what teammates write. Copy the smallest
configuration that makes the specifier resolve.

A copy of a module also removes information by mechanical means. It removes the call sites of
siblings, the shared fixtures, and the ambient configuration. The explorer cannot absorb what is not
there. If the module works only with the context around it, copy that context in. Record this fact.
A module that nobody can understand without its neighbors is a finding.

### 4. Provision the external resources

The orchestrator starts every resource that a milestone needs, before the explorer starts. Examples:
a database, a directory server, a message broker, an object store. The explorer never provisions
anything. Time that the explorer spends on Docker is time that it does not spend on the API. A stall
there is a finding about your infrastructure, not about the subject.

One line separates what you give from what the explorer finds. You give the coordinates of the
infrastructure. The explorer finds the API that consumes them.

- You give: host, port, URL, credentials, the name of a database or a bucket, a connection string,
  the path to a directory of sample files. These are facts about the world, not facts about the
  subject.
- You do not give: the function that accepts these values, the shape of its options object, the
  order of its arguments, or the choice between three entry points. That is the surface under test.

So `postgres://audit:audit@localhost:55432/audit` goes in the brief.
`createPool({ connectionString })` does not. The rule holds for every resource. You supply the
address. The explorer finds the call.

Keep all infrastructure in `infra/`. Never put it in `project/`. Compose files, env files, and seed
scripts often carry schema definitions and fixture data. That data mirrors the expected model of the
subject. The comments often explain the intended use. All of this answers the milestones in advance.
The blind guard blocks `infra/` at every tier while armed, so a stray read stops instead of spoiling
the run in silence.

You may reuse the harness or the compose file of the subject. You are not blind. Run the harness
from `subject/`, or copy it into `infra/`. The explorer must not read it.

Seed the minimum. Prefer an empty store. A milestone can ask the explorer to model something. If the
store already holds the exact shape that the subject expects, the modeling work ends before the
explorer starts. The same trap applies to sample files, queue contents, and cached responses. Seed
by hand in domain terms when a milestone needs existing data. Never seed from the test fixtures of
the subject.

Verify each resource before you arm the guard. Use a command that does not touch the subject: a
one-line native client call, a raw HTTP request, a port check, or a directory listing. The command
must prove that the resource answers without the code under test. Record the command in
`findings.md`. If a resource stops during the run, mark that milestone as infra-failed. Do not count
it against the subject.

Remove the resources after the report, not after the explorer. The reviewer runs the code of the
explorer again in step 8 and needs the service alive.

### 5. Fill the brief, then run the leakage gate

Fill the placeholders in `references/explorer-brief.md`. Write the result to `brief.md`.

Run this gate before you launch. A brief that leaks makes every later step useless.

1. Search `brief.md` for every public identifier that the subject exports. Any match is a leak.
   Rewrite that milestone in domain terms.
2. Confirm that no milestone states an order, a required option, or a hint of the form "you will
   want X".
3. Confirm that the allowances and the prohibitions in the brief match the resolved tier.
4. Confirm that the resource section lists only coordinates. It must hold no function names, no
   option shapes, and no call order from the subject.
5. Fix the problems and check again. Launch only when all four checks pass.

### 6. Arm the guard, then run the explorer

The build, the wiring, and the packing all need access to the subject, so the guard starts in the
disarmed state. Arm it now that the setup is complete.

```bash
touch ${TMPDIR:-/tmp}/test-library-guard.armed
```

While armed, `scripts/blind_guard.py` runs as a PreToolUse hook. It blocks reads inside `subject/`
that the tier does not allow. It blocks every read inside `infra/`. It closes each extra root from
the configuration. It blocks a search that walks into a closed root, including a search with no path
argument. It also catches read commands that pass through bash. Do not skip the guard. Do not disarm
it early.

The guard covers the common routes and no more. It allows the action when anything is unclear. Three
routes stay open by design. A bash command can name a closed path in relative form. An interpreter
can read a file inside its own process. A copy can move a closed file into open space. So the guard
is not proof that the run held. The manual gate in step 7 is the proof, and the guard writes the log
that the gate reads.

```
${TMPDIR:-/tmp}/test-library-guard.log
```

Each line holds a verdict, a tool name, and a target. The log starts empty at setup.

If you can start a subagent, start one. Give it `brief.md` without changes. Point it at `project/`
and `journal.md`. One explorer runs every milestone in order. The curve across the milestones
carries signal, so do not split the milestones.

If you cannot start a subagent, the honest option is different. Ask the user to run `brief.md` in a
new session with no repository context and to return `journal.md`. An agent that has read the source
cannot unread it. You can also act the part yourself. If you do, say clearly that contamination
makes the result indicative and not evidential. Record the same statement in the report.

Do not help, hint, correct, or answer questions while the explorer runs. Every point where the
explorer stops is the data.

Check the journal shape during the run. A summary written afterward has almost no value. By the end
the explorer understands the subject and tells a clean story that hides the confusion. Each entry
must arrive before the resolution. The guess comes first and the outcome comes second. If entries
appear only after things work, stop, state the requirement again, and run that milestone again.

### 7. Contamination gate

Do not start phase 2 until this gate passes.

Start with the guard log, because it is the one record that the explorer does not write.

```bash
grep '^block' ${TMPDIR:-/tmp}/test-library-guard.log
```

1. Read every blocked line. A block is an attempt, not a breach. Record the attempts. A blocked
   attempt shows what the explorer believed it needed.
2. Search the allowed lines for the three open routes. Look for a bash command with a relative path.
   Look for `python3 -c`, `node -e`, `inspect.getsource`, `__file__`, and `dis`. Look for a `cp` or
   an `mv` out of a closed root. An allowed read of a copy is still a breach.
3. Look for web searches and registry lookups. The hook does not see those tools, so read the
   transcript of the explorer and its own journal.
4. In module mode, look for reads of other call sites, of the module tests, or of the git history.
5. Read the journal for statements about prior knowledge of this subject.

An empty log is a failure of the setup, not a clean run. It means that the guard never ran. Check
that the workspace trust dialog accepted the hooks, and that `$TMPDIR` holds the armed sentinel.

If you find a violation, take one of two paths. Run the audit again clean, or continue and mark the
report as contaminated with the violation named. Silent contamination is the one failure that makes
the whole report misleading instead of incomplete.

### 8. Review with full access

Disarm the guard first. Otherwise it blocks every read in this phase.

```bash
rm -f ${TMPDIR:-/tmp}/test-library-guard.armed
```

Then read `subject/`. This is the snapshot that the explorer met, not the current state of the
working tree.

Run the code of the explorer. Compile it, run it, and inspect what it did. Run it against the live
resources. This is the reason that removal of the resources waits for the report. Code that
compiles, runs, and does the wrong thing is the most valuable finding here. The journal alone cannot
show it.

Compare belief against reality. Mark each hypothesis in the journal as correct, wrong and caught, or
wrong and silent. Treat wrong and silent as severe by default.

Collect these signals. Each one maps to a concrete fix.

- **Phantom APIs.** Names that the explorer reached for and that do not exist. These show what users
  believe the thing is called.
- **Wrong first guess.** A reasonable first approach that was not the intended one. Either the
  intended path is hard to find, or the reasonable path must also work.
- **Diagnostic quality.** For each error, ask if the message named the real mistake. Include walls
  of expanded conditional types, errors that appear at the wrong call site, and `any` or `unknown`
  leaks that removed the error.
- **Escape-hatch pressure.** Every cast, `@ts-expect-error`, `unwrap()`, `# type: ignore`, or reach
  into the internals marks a point where the types blocked a legitimate goal.
- **Boilerplate.** Lines that carry ceremony instead of intent.
- **Order dependence.** A required order that nothing in the API states.
- **Doc gaps.** Members of the surface whose docs omit a required fact: units, ownership, mutation,
  async behavior, throw behavior, ranges, defaults.

In module mode, add one comparison. Compare the usage by the explorer against the real call sites. A
difference means one of two things. Either the idiomatic pattern is hard to find from the surface of
the module, or the call sites carry knowledge. That knowledge belongs in the types and the docs of
the module. Also mark anything that the explorer built again although the module already provides
it.

Attribute each finding with care. Ask if a competent person would make this mistake. An error of the
agent is not a defect of the subject. But a reasonable mistake belongs to the subject: a bad name, a
missing doc, or a type that misleads. This holds even when a careful reader could avoid the mistake.
Mark your confidence when you are unsure. Ten real findings are worth more than forty findings mixed
with noise.

Read `references/finding-taxonomy.md` before you write the findings. The categories, the severities,
and the rating anchors then stay the same across runs.

### 9. Write findings.md

Follow `references/report-template.md`. Two rules sit outside the template.

- Each finding cites evidence in the journal by line and ground truth in the source by location. A
  finding without both is an opinion.
- Report each dimension rating apart from the others. An average hides the information that the
  author needs. An N/A is more honest than a low score for something that the language never
  offered.

Record what you provisioned and at what fidelity. A run against a real service and a run against a
stub support different conclusions. A reader cannot tell the two apart unless you state which one
you did.

Remove the resources after you write the report. Then clear the guard state, so that the next run
starts clean.

```bash
rm -f ${TMPDIR:-/tmp}/test-library-guard.armed \
      ${TMPDIR:-/tmp}/test-library-guard.conf
```

Keep the log until the report is final. Copy it next to `findings.md` if you want the evidence to
outlive the temp directory. An abandoned run leaves the sentinel behind, and the guard then blocks
reads of that old workspace. The same two lines fix that.

Then start your reply to the user with the two or three findings that change the first hour of a
newcomer the most. Do not make the user find the headline in a table.

## Pitfalls

- **Silent contamination.** Worse than a failed run, because the report still looks valid. The gate
  in step 7 exists for this.
- **Journaling after the fact.** The most common failure. It gives a useless report without any
  warning.
- **Review of the code instead of the experience.** The project of the explorer is evidence, not a
  deliverable. Do not comment on its style.
- **Repair during the audit.** Findings come first. Repair destroys the record of the fault.
- **Infra failure counted as a defect of the subject.** A dead container is your problem, not a
  problem of the API. Mark the milestone infra-failed and leave it out of the ratings.
- **An explorer that provisions its own resources.** This turns the audit into a Docker exercise. It
  also routes the explorer straight through the compose file and the fixtures of the subject.
- **One milestone.** This tests the tutorial, not the subject. The interesting failures live in
  composition and in error handling.

## Bundled files

- `scripts/setup_audit.sh`. Run it. It scaffolds the workspace in step 3.
- `scripts/blind_guard.py`. The PreToolUse hook runs it. You do not. It writes the decision log that
  step 7 reads. Read the script itself only if the guard blocks the wrong thing.
- `references/explorer-brief.md`. Fill it and give it to the explorer in step 5.
- `references/finding-taxonomy.md`. Read it before you write the findings in step 8.
- `references/report-template.md`. The structure for `findings.md` in step 9.

The guard holds the state of one audit, at a fixed path in the temp directory. Complete or abandon a
run before you start another one.
