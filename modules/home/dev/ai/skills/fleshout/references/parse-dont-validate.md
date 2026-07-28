# Parse, Don't Validate — Patterns by Language

Core idea: instead of checking a value is valid and then passing around the _original_,
less-trustworthy type, convert ("parse") it into a type that can only represent valid values, once,
at the boundary. Every downstream function then just trusts the type — no re-checking, no defensive
`if` chains, no forgotten edge case three call-frames deep.

Each pattern below appears in multiple languages so you can translate an idea across a diff's
language boundary. Pick the one matching your target language, or use a neighboring one to see how
the same shape plays out with different type-system power.

---

## 1. Make illegal states unrepresentable (sum types over boolean/optional soup)

**Anti-pattern** (any language): a struct with `is_loading: bool`, `error: Option<Error>`,
`data: Option<T>` — where `is_loading: true, data: Some(...)` is possible in the type system but
meaningless in reality.

**Rust** — tagged enum:

```rust
enum FetchState<T> {
    Idle,
    Loading,
    Loaded(T),
    Failed(Error),
}
```

**TypeScript** — discriminated union:

```typescript
type FetchState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "loaded"; data: T }
  | { status: "failed"; error: Error };
```

**Go** — Go lacks sum types; approximate with an interface + sealed set of implementers (unexported
marker method), or a small `Kind` enum plus a struct where only the relevant field is populated by
convention, enforced through constructor functions rather than field access:

```go
type FetchState interface{ isFetchState() }

type Idle struct{}
type Loading struct{}
type Loaded[T any] struct{ Data T }
type Failed struct{ Err error }

func (Idle) isFetchState()       {}
func (Loading) isFetchState()    {}
func (Loaded[T]) isFetchState()  {}
func (Failed) isFetchState()     {}
```

Then a type switch at the point of use is exhaustive by convention (pair with a linter, e.g.
`exhaustive`, since Go won't enforce it for you).

**Haskell** — ADT, the natural home for this pattern:

```haskell
data FetchState a
  = Idle
  | Loading
  | Loaded a
  | Failed Error
```

---

## 2. Smart constructors / newtypes for validated values

Wrap a primitive so that once you hold the wrapped value, the invariant is guaranteed — you can't
construct one without passing validation, and there's no unwrapped version floating around to
accidentally reuse.

**Rust**:

```rust
pub struct Email(String);

impl Email {
    pub fn parse(raw: String) -> Result<Self, ValidationError> {
        if raw.contains('@') { Ok(Email(raw)) } else { Err(ValidationError::BadEmail) }
    }
}
// No public constructor besides `parse` — every `Email` in the system is valid.
```

**TypeScript** (nominal typing via branding, since TS is structurally typed):

```typescript
type Email = string & { readonly __brand: "Email" };

function parseEmail(raw: string): Email | { error: string } {
  if (!raw.includes("@")) return { error: "invalid email" };
  return raw as Email;
}
```

**Go**:

```go
type Email struct{ value string }

func ParseEmail(raw string) (Email, error) {
    if !strings.Contains(raw, "@") {
        return Email{}, fmt.Errorf("invalid email: %s", raw)
    }
    return Email{value: raw}, nil
}
// unexported field means callers outside the package can't construct one directly
```

**Haskell**:

```haskell
newtype Email = Email Text  -- constructor not exported from the module

parseEmail :: Text -> Either ValidationError Email
parseEmail raw
  | "@" `T.isInfixOf` raw = Right (Email raw)
  | otherwise             = Left InvalidEmail
```

---

## 3. Non-empty collections, not "list + a runtime check"

Anti-pattern: `items: T[]` plus a function that throws/panics if it's empty, called defensively at
every use site.

**Rust**: use a `NonEmpty<T>` type (e.g. from the `nonempty` crate, or hand-roll
`struct NonEmpty<T> { head: T, tail: Vec<T> }`) so `.first()` returns `T`, not `Option<T>`.

**Haskell**: `Data.List.NonEmpty`, same idea — `NonEmpty a = a :| [a]`.

**TypeScript**: `type NonEmptyArray<T> = [T, ...T[]]` — a tuple type that TS will actually enforce
at the call site.

**Go**: no tuple types; hand-roll a small type with a private slice field and a constructor that
errors on empty input, same shape as the `Email` example above.

---

## 4. Exhaustive matching over `if/else` + fallback

Once you have a sum type (pattern 1), let the compiler catch missing cases instead of relying on a
`default:`/`else` that silently swallows a case you forgot.

**Rust**: `match` without a wildcard arm — compiler error if a variant is unhandled. Only add
`_ => ...` when you genuinely mean "everything else," not as a safety net.

**TypeScript**: omit the `default` case in a `switch` over a discriminated union, then add an
`assertNever` helper:

```typescript
function assertNever(x: never): never {
  throw new Error(`Unhandled case: ${JSON.stringify(x)}`);
}
```

Called in the `default` position — if a new union member is added later without updating the switch,
this becomes a compile error (`x` is no longer assignable to `never`).

**Haskell**: turn on `-Wincomplete-patterns` (ideally `-Werror=incomplete-patterns`) so an unmatched
constructor is a build failure, not a runtime `Non-exhaustive patterns` crash.

**Go**: no compiler-enforced exhaustiveness. Use the `exhaustive` linter on type switches over the
sealed-interface pattern from section 1, and treat lint failures as build failures in CI.

---

## 5. Parse at the boundary, trust everywhere after

The unifying discipline: do the messy work (parsing JSON, validating user input, checking a config
file) exactly once, right where the untrusted data enters the system. Everything downstream takes
the _parsed_ type as input, never the raw one — which means downstream code has no reason to
re-validate, and can't forget to.

A useful smell test: if a function takes a raw `string`/`int`/`map` where a narrower type would do,
and its first few lines are validation, that validation belongs at the caller's boundary instead —
push the parse outward until the function's signature itself documents what's guaranteed.
