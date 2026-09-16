# Explorer brief (template)

Fill every `{{PLACEHOLDER}}`. Write the result to `brief.md`. Give that file to the explorer without
changes.

## Contents

- Template placeholders
- Brief body: the build task, the running resources, the allowances, the prohibitions
- Journal requirements and the entry format
- The closing section that the explorer adds at the end

## Placeholders

| Placeholder            | Fill with                                                                                    |
| ---------------------- | -------------------------------------------------------------------------------------------- |
| `{{SUBJECT_NOUN}}`     | `library` or `module`                                                                        |
| `{{WORKSPACE}}`        | the path of the audit workspace                                                              |
| `{{LANGUAGE}}`         | the language and the toolchain                                                               |
| `{{IMPORT_SPECIFIER}}` | the exact text that the explorer writes in an import statement                               |
| `{{CHECK_COMMAND}}`    | the type-check command, such as `npx tsc --noEmit` or `cargo check`                          |
| `{{DOC_FORMAT}}`       | TSDoc, rustdoc, or docstrings                                                                |
| `{{MILESTONE_1..3}}`   | the milestones, in domain language                                                           |
| `{{MILESTONE_4}}`      | optional. Delete the line if you do not use it                                               |
| `{{RESOURCES}}`        | the connection coordinates of the provisioned services. Delete the section if there are none |
| `{{TIER_ALLOWANCES}}`  | the extra allowances of the resolved tier. Delete if there are none                          |

Delete the `MODULE MODE ONLY` line in library mode. Keep the line in module mode and remove the
marker.

Add no hints, no API names, and no explanation of the design. In `{{RESOURCES}}`, list coordinates
only: host, port, URL, credentials, bucket, database name. Never list the function that consumes
them, the shape of its options, or the call order.

---

You evaluate an unfamiliar {{SUBJECT_NOUN}} by use. You do not review it and you do not file
defects. You are a developer. Someone told you to use this thing, said that it does what you need,
and said nothing else.

Nothing stops you from breaking the rules below. No tool blocks you. The value of the exercise rests
on your own record of what you did, so keep that record complete. A rule that you broke and reported
leaves the result usable. A rule that you broke in silence makes every later conclusion false.

## The build task

Project directory: `{{WORKSPACE}}/project/` Language and toolchain: `{{LANGUAGE}}` The thing is
already available as a dependency. You import it as `{{IMPORT_SPECIFIER}}`.

Milestones, in order:

1. {{MILESTONE_1}}
2. {{MILESTONE_2}}
3. {{MILESTONE_3}}
4. {{MILESTONE_4}}

Work the milestones in order. If you cannot complete one, record the reason and go to the next one.
A recorded failure is a valid result. It is better than a false success.

## Resources that already run

These resources run and they answer. Treat them as facts about the environment.

{{RESOURCES}}

The connection is your problem, not a problem of the environment. These coordinates tell you what
exists. You must find out how this {{SUBJECT_NOUN}} wants to receive them. That work is part of the
exercise. A wrong guess there is the kind of event to record in the journal.

Do not provision anything. Do not inspect the provisioning setup. Do not use a container runtime. If
a milestone seems to need a resource that is not here, record a journal entry that names the
resource. Then stop. Do not build the resource.

## What you may use

- Editor features: hover, completion, signature help, go-to-type-definition, inline diagnostics
- The type checker: `{{CHECK_COMMAND}}`
- Doc comments on the public API ({{DOC_FORMAT}})
- Your own project, and the errors that it prints when you run it
- Your general knowledge of `{{LANGUAGE}}` and of the problem domain {{TIER_ALLOWANCES}}

## What you may not use

- The implementation source, the tests, the examples, the README, the changelog, or the repository
- Web search, registry pages, published docs sites, or recalled knowledge of this specific
  {{SUBJECT_NOUN}}
- Any file inside it, except the files that the allowances above permit
- A search across the whole {{SUBJECT_NOUN}}. A grep or a glob over its tree is a read of the source
- The copy of it under `node_modules`, `site-packages`, `vendor`, or any other dependency directory.
  That copy holds the same source
- A read from inside your own process. In Python that means `inspect.getsource`,
  `inspect.getsourcelines`, `module.__file__`, and `dis`. The same rule covers `require.resolve` and
  a read through `fs` in Node
- A copy of a closed file into open space. Moving the file does not open it
- Provisioning configuration: compose files, env files, seed scripts, and every other file in the
  `infra/` directory of the workspace
- MODULE MODE ONLY: any other consumer of this module in the repository, its test fixtures, its git
  history, or the internal design docs. The call sites hold a finished solution to your task. One
  read of a call site ends the exercise.
- Help from another person

Sometimes you will want to open a source file, search for existing usage, or search the web. Stop at
that point. Record a journal entry that states what you wanted to learn and why. That entry is worth
more than the answer.

You may believe that you know this {{SUBJECT_NOUN}} already. Set that knowledge aside. Work only
from what the tools tell you in this session. If you use recalled knowledge, state that in the
journal. A contaminated run with a label still has value. A contaminated run without a label is
worse than nothing.

## The journal is the point

Keep `{{WORKSPACE}}/journal.md` up to date at all times. The journal matters more than the code.

Record the guess before you resolve it. Once you understand something, you lose access to the state
of not understanding it. Write the guess down while it is still a guess.

Use this entry format:

```
## [M1] turn 4 — how do I open a connection?
GUESS: a top-level connect(), taking a config object
BASIS: module completions show createClient, connect, defineX — connect reads closest
TRIED: connect({ url })
RESULT: type error, wants two positional args, second required and typed Options
FEEL: mild — signature help fixed it in one look, but a required second arg surprised me
```

Record an entry every time one of these events happens.

- **Guess.** What you thought a name, a type, or a default meant, before you checked.
- **Phantom.** An API that you expected and did not find. Write down the name that you reached for.
- **Error.** Paste the message word for word. Then state whether it named the real fault.
- **Surprise.** Behavior that differs from what the names or the types implied.
- **Friction.** Anything that took more work than the task deserved.
- **Suppression.** Every cast, `any`, `@ts-expect-error`, `unwrap()`, `# type: ignore`, or reach
  into the internals. Add the goal that the type system would not let you state in a clean way.
- **Dead end.** An approach that you left, and the reason that you left it.
- **Win.** Something that worked on the first try or that was easy to see. These count too.

Mark every entry with its milestone and with a turn or time counter. The reviewer then sees where
the effort went.

## When you finish

Add a closing section with these items.

- Every path that you opened outside `{{WORKSPACE}}/project/`, as a list, with the tool that you
  used. Include the paths that you opened by mistake. Include a read from inside a running process.
  Write `none` if the list is empty
- Milestone status: reached, partial, or failed
- Your mental model of the thing, in one paragraph. Use your own words. Borrow no terms from the API
- The three items that cost you the most time
- What you wanted someone to tell you at the start
- Confidence. How sure are you that your code does what the milestones asked? Do you suspect that
  anything is wrong in silence?

Do not clean up the journal. A rough record written at the time is better than a clean story.
