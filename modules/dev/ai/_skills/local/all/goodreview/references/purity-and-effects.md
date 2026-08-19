# Purity and effects

The question is whether you can test a decision without the world. A function that computes a
decision and also reads a file, reads the clock, or writes a row cannot be tested alone. Such code
collects fake objects instead of tests.

The rule from SKILL.md holds here too. A change must delete something: a fake object, a branch, a
defensive check, or a class.

## Contents

- A pure core and a thin shell
- Hidden inputs
- Mutation
- Errors as values
- Total functions
- Objects that are functions
- Effects that spread
- Language notes

## A pure core and a thin shell

Keep decisions pure. Keep effects at the edge. The shell reads the input, calls the core, and
performs what the core decided.

### How to spot the failure

- A function over 50 lines that mixes a database call, a business rule, and a log line.
- A test file with more setup of fake objects than assertions.
- A pure calculation that takes a repository or a client as a parameter and calls one method on it.
- A business rule inside a request handler, a user-interface component, or a database transaction
  block.
- One rule implemented twice, because the first copy could not be reached from the second context.

### The fix

1. Find the decision inside the function. It sits between the reads and the writes.
2. Extract it as a function from plain data to plain data. No parameter performs input or output.
3. Leave the reads and the writes in the caller.
4. Delete the fake objects that existed only to reach the decision. That deletion justifies the
   change.

One test tells you whether the split landed. Call the extracted function from a test with literal
arguments and no setup. If it still needs a fake object, the split is in the wrong place.

## Hidden inputs

A function that reads the clock, the environment, a random source, or a global variable is not a
function of its arguments. Its result cannot be reproduced.

Signals:

- A clock read inside a rule.
- A random value or a fresh identifier generated inside a rule.
- An environment variable read below the entry point, or read at load time.
- A mutable variable at module scope, used as a cache or as a single instance.
- A test that fails at a certain hour, or in a certain time zone, or in a different order.

Fix: pass the value in. A clock parameter costs one argument and deletes a fake timer. Read the
environment once at startup, parse it into one config value, and pass that value down. See
`type-modeling.md` for the parse.

## Mutation

Shared mutable state makes the reachable-state count unbounded. This is the run-time form of the
illegal-state problem.

Signals:

- A function that takes a value, changes it, and returns nothing. The caller cannot tell what
  changed.
- An in-place sort, reverse, or append applied to a parameter.
- A loop that builds a result by appending to a variable declared far above it, mixed with
  conditions and early exits.
- A value reused across iterations, or across requests.
- A field documented as read-only after construction, with no language support for that claim.

Fix: return a new value. Mark the field immutable if the language allows it. Use a map, a filter, or
a fold when they read more clearly than the loop. Do not turn a clear loop into a clever chain.
Clarity beats style.

Cost check: do not copy a large structure in a hot path for tidiness. Measure it, or leave it.

## Errors as values

Signals:

- An exception raised for an expected outcome, such as a missing record or invalid input.
- A function that signals failure with an absent value, a negative number, a false, or an empty
  collection. The caller then cannot tell failure from an empty result.
- A catch around a whole function body that turns every failure into one generic message.
- Two conventions in one codebase, with no rule about which layer uses which.
- An error type so wide that every handler converts it to text.

Fix: pick one convention per layer and write it down. An expected outcome belongs in the return
type. An unexpected failure raises and reaches one handler at the top. A tagged result type forces
the caller to handle both branches, and the compiler checks the match.

Record the win as the count of defensive checks and generic catch blocks the change removes.

## Total functions

A total function returns a value for every input its type allows. A partial function has inputs it
cannot handle, so it raises, returns a magic value, or falls through.

Signals:

- A match with a catch-all branch that raises "unreachable" or "unknown case".
- A condition chain with no final branch, which returns an absent value by accident.
- Indexed access with no bounds check, and no non-empty type.
- A function documented as safe to call only after another call.

Fix: narrow the input type until the impossible case cannot be passed. Then delete the guard. Add an
exhaustiveness check, so a new case becomes a build error. The final branch should assert that the
case cannot occur, rather than raise a text message.

## Objects that are functions

Signals:

- A class with no fields, or with fields set once and read inside one method.
- A class with one public method, constructed at every call site.
- A manager, service, helper, or handler class that wraps one function.
- A builder for a value with two fields.
- An interface with one implementer, present only to allow a fake object in tests.

Fix: a function that takes the former constructor arguments. This deletes the class, the interface,
the fake object, and the wiring. See `architecture.md`.

Keep the class when it holds real state with rules that span methods, or when the language needs it.

## Effects that spread

An effect marker on a function forces the marker onto every caller. One unnecessary marker spreads
through the call graph.

Signals:

- An asynchronous function that never waits for anything.
- A pure calculation marked asynchronous because one caller was.
- A wait inside a loop where the calls do not depend on each other.
- A started task that nobody waits for, so its failure disappears.
- An effect type or a monad added to a signature for one log line.

Fix: keep the core free of the marker. Effects belong to the shell. The change also shortens the
tests.

## Language notes

- **Haskell, or another language with tracked effects**: the type system already separates the core
  from the shell. The finding is usually a function in the effect type that does not need it, or a
  rule inlined into the shell. Push the rule out and give it a pure signature.
- **Rust**: immutability is the default, so the mutation section shifts to interior mutability and
  to shared ownership. Look for a lock or a reference-counted cell used to dodge a design problem.
- **Go**: no immutability support. Prefer value receivers and returning new structs. Look for a
  slice or a map passed and then modified, since both alias.
- **TypeScript and JavaScript**: mark fields read-only and freeze at the boundary. Watch for
  asynchronous markers that spread, and for a class that exists to hold a single method.
- **Python**: use a frozen dataclass for values. Watch for a default argument that is a mutable
  value, and for module-level state created at import time.
- **Object-oriented codebases in general**: a pure core does not require a functional language. A
  static method over plain data, or a value class with no dependencies, achieves the same
  testability.
