# Type modeling

The question is not whether the code has types. The question is whether a type admits states the program cannot handle.

Every finding here must pass the metric test in SKILL.md. Name the invariant. Name the sites that re-check it. Name the one place that will prove it. A type change that deletes no check is a guess.

The principles below hold in every language. A static checker makes them cheaper to enforce. It does not create them.

## Contents

- Parse, do not validate
- Illegal states
- Primitive obsession
- Boolean blindness
- Optional soup
- The wrong data structure
- Language notes
- When to leave it alone

## Parse, do not validate

A validator inspects data, returns a yes or a no, and forgets what it learned. A parser takes loose input and returns a narrower type, or fails. The narrow type carries the proof, so no caller checks again.

The anti-pattern is **shotgun parsing**. Checks sit throughout the processing code. None of them is remembered. None of them is systematic. The program acts on part of a bad input before it finds the bad part, so the state after a failure is hard to predict.

### How to spot it

- One condition is tested in three or more places. Grep the condition, not the function name.
- A function opens with four guard clauses that its caller already ran.
- A predicate returns a yes or a no, and the caller then uses the raw value.
- A field is typed as text, and every consumer first splits it, trims it, or matches it against a pattern.
- An absence check sits far from the code that loaded the value.
- A comment says the value is always set by now.

### Threshold

Three or more sites that re-check one rule is a T3 finding. Two sites next to each other is not worth a remodel.

### The fix

1. Find the boundary where the data enters. A request handler, a file read, a database row, a command-line argument, a queue message.
2. Parse there, once. Return the narrow type or an error. Parse the whole input up front, not one field at a time during processing.
3. Change the internal signatures to accept the narrow type.
4. Delete the checks behind the boundary. This step is not optional. If no check can go, the boundary sits in the wrong place.

```ts
// Before. The rule lives in a comment and in four call sites.
function sendWelcome(user: { email?: string; age?: number }) {
  if (!user.email) throw new Error("no email"); // and again in three other files
  mailer.send(user.email, `Welcome, age ${user.age ?? 0}`);
}

// After. One parse. The type is the proof.
type NewUser = { email: Email; age: number };
function parseNewUser(raw: unknown): NewUser { /* throws, or returns */ }
function sendWelcome(user: NewUser) {
  mailer.send(user.email, `Welcome, age ${user.age}`);
}
```

The same move in a language without a compiler check still pays. The parse gives one place to fail and a definite shape after it.

```python
# The boundary returns a frozen record. Internal functions annotate against it.
@dataclass(frozen=True)
class NewUser:
    email: Email
    age: int

def parse_new_user(raw: Mapping[str, object]) -> NewUser: ...
```

## Illegal states

Count the states the type allows. Count the states the code handles. The gap is the finding.

Two independent flags allow four states. If three are legal, the fourth is a latent bug, and every consumer must remember to ignore it.

```ts
// Before. Eight states. Three of them legal.
type Req = { loading: boolean; error?: string; data?: User };

// After. Three states. The compiler checks the switch.
type Req =
  | { status: "loading" }
  | { status: "error"; message: string }
  | { status: "ok"; data: User };
```

The same model in other stacks:

```rust
enum Req { Loading, Error(Message), Ok(User) }
```

```haskell
data Req = Loading | Error Message | Ok User
```

Signals:

- Two or more fields that are only meaningful together, or that must never both hold a value.
- A field whose meaning depends on another field. That is a tagged union in disguise.
- A comment that lists which combinations are valid.
- A test named for a case that cannot happen.
- An optional field that one code path always fills and another never fills.

Fix: one tagged union. Then close the exhaustiveness gap, so a new case becomes a build error rather than a run-time surprise. See `constraint-evasion.md` for the flat-expansion trap that this fix invites.

## Primitive obsession

Two identifiers of the same primitive type can be swapped at any call site. The compiler cannot help. A distinct type restores the help.

Signals:

- A signature with three or more parameters of the same primitive type.
- A name that carries the type: an identifier string, a text field named for its unit, a number named for milliseconds.
- The same parse or the same format applied to one primitive in many places.
- A bug in the git log about arguments in the wrong order.

The fix has a name in each language. The idea is one: a type the compiler tells apart, plus one constructor that checks the rule.

```ts
type Email = string & { readonly __brand: "Email" };
export function parseEmail(raw: string): Email { /* check, then cast once */ }
```

```go
type Email string
func ParseEmail(raw string) (Email, error) { /* check */ }
```

```rust
pub struct Email(String);
impl Email { pub fn parse(raw: &str) -> Result<Self, Invalid> { /* check */ } }
```

```python
Email = NewType("Email", str)
def parse_email(raw: str) -> Email: ...
```

Keep the constructor as the only way to build the value. A public constructor that skips the check makes the type decoration, not proof.

Cost check: a distinct type pays when the value crosses several modules, or when a mix-up is plausible. It does not pay for a local variable. Apply the metric test.

## Boolean blindness

A flag at a call site tells the reader nothing. A call such as `render(true, false)` sends the reader to the definition.

Signals:

- A function with two or more flag parameters.
- A flag that selects between two behaviors rather than describing data. That is two functions, or one union parameter.
- A flag named `mode`, `flag`, or `special`, with no clear opposite.
- A predicate used to pick a branch, where a match on a union would carry the payload too.

Fix: split the function, or accept a small closed set of named cases. The fix usually deletes branches inside the function as well.

## Optional soup

A type where most fields are optional models nothing. It is a bag.

Signals:

- More than half the fields optional.
- A partial or draft version of a type used as an internal type rather than as an input type.
- A string-keyed map of unknown values passed between layers.
- One shape widened again at each layer it crosses.

Fix: split the bag into the states it represents. Usually that is an input type and a stored type. The parser accepts the input type. The rest of the program uses the stored type.

## The wrong data structure

Sometimes the rule belongs in a container, not in a type definition.

Signals and fixes:

| Signal | The rule it hides | Fix |
|---|---|---|
| A duplicate filter over a list at every read | The elements are unique | A set |
| A sort at every read | The order matters | A sorted structure, or sort once at the parse |
| A lookup loop over a list | Access is by key | A map |
| An emptiness check before every head access | The collection is never empty | A non-empty type |
| A search for one element expected to be single | Exactly one matches | Parse to that one element at the boundary |

Each fix moves a repeated run-time check into the choice of structure. Count the checks it deletes.

## Language notes

- **Static and expressive**, such as Haskell, Rust, or Scala: the tagged union and the wrapped primitive are one line each. Take them. The residual risk is the abusable payload inside a variant. See `constraint-evasion.md`.
- **TypeScript**: types are structural, so a wrapped primitive needs a brand and a single constructor. A schema library at the boundary can produce the parse and the type from one declaration. Do not add such a dependency during cleanup unless it deletes a hand-written validator.
- **Go**: a named type per concept costs nothing and reads well. There is no exhaustiveness check, so add a linter for it, and prefer an interface with a closed set of implementers in one package.
- **Python**: parse into a frozen dataclass or a validated model at the boundary. Then run a strict type checker on that module. `NewType` gives a distinct name with no run-time cost.
- **Dynamic, with no checker**: keep the parse boundary and the factory function. Freeze the result. Write the shape down in one place. The win is the single failure point, not the annotation.

For escape hatches such as a cast or a suppression, use the triage table in `constraint-evasion.md`. A cluster of casts in one file is one finding about that file, not many small findings.

## When to leave it alone

- The value never crosses a module boundary.
- The rule is checked once, at the only place it matters.
- The remodel touches a hot path with no test. Write the test first, or record the item as T4.
- The code is due for deletion. Delete it instead.
- Making the state unrepresentable needs machinery out of proportion to the risk, such as a proof for a numeric range. Use one checked constructor and one documented rule.
