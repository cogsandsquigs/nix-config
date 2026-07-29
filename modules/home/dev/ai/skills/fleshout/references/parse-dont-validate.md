# Parse, don't validate — patterns by language

Instead of checking that a value is valid and then passing the _original_, less-trustworthy type
onward, convert it once, at the boundary, into a type that can only hold valid values. Downstream
functions trust the type: no re-checking, no defensive `if` chains, no forgotten edge case three
call frames deep.

Each pattern appears in several languages so you can translate the idea across a diff's language
boundary. Take the one matching your target language, or read a neighboring one to see the same
shape with different type-system power.

## Contents

1. Make illegal states unrepresentable — sum types over boolean and optional soup
2. Smart constructors and newtypes for validated values
3. Non-empty collections instead of a list plus a runtime check
4. Exhaustive matching instead of `if`/`else` with a fallback
5. Parse at the boundary, trust everywhere after

---

## 1. Make illegal states unrepresentable

**Anti-pattern**, in any language: a struct with `is_loading: bool`, `error: Option<Error>`, and
`data: Option<T>`, where `is_loading: true` together with `data: Some(...)` is representable but
meaningless.

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

**Go** — Go has no sum types. Approximate with an interface plus a sealed set of implementers, using
an unexported marker method:

```go
type FetchState interface{ isFetchState() }

type Idle struct{}
type Loading struct{}
type Loaded[T any] struct{ Data T }
type Failed struct{ Err error }

func (Idle) isFetchState()      {}
func (Loading) isFetchState()   {}
func (Loaded[T]) isFetchState() {}
func (Failed) isFetchState()    {}
```

A type switch at the point of use is then exhaustive by convention. Pair it with the `exhaustive`
linter, because the compiler will not enforce it.

**Haskell** — an ADT, the natural home for this pattern:

```haskell
data FetchState a
  = Idle
  | Loading
  | Loaded a
  | Failed Error
```

---

## 2. Smart constructors and newtypes for validated values

Wrap a primitive so that holding the wrapped value guarantees the invariant. There is no way to
construct one without passing validation, and no unwrapped version floating around to reuse by
accident.

**Rust:**

```rust
pub struct Email(String);

impl Email {
    pub fn parse(raw: String) -> Result<Self, ValidationError> {
        if raw.contains('@') { Ok(Email(raw)) } else { Err(ValidationError::BadEmail) }
    }
}
// `parse` is the only public constructor, so every `Email` in the system is valid.
```

**TypeScript** — nominal typing through branding, because TypeScript is structural:

```typescript
type Email = string & { readonly __brand: "Email" };

function parseEmail(raw: string): Email | { error: string } {
  if (!raw.includes("@")) return { error: "invalid email" };
  return raw as Email;
}
```

**Go:**

```go
type Email struct{ value string }

func ParseEmail(raw string) (Email, error) {
    if !strings.Contains(raw, "@") {
        return Email{}, fmt.Errorf("invalid email: %s", raw)
    }
    return Email{value: raw}, nil
}
// The unexported field stops callers outside the package constructing one directly.
```

**Haskell:**

```haskell
newtype Email = Email Text  -- the constructor is not exported from the module

parseEmail :: Text -> Either ValidationError Email
parseEmail raw
  | "@" `T.isInfixOf` raw = Right (Email raw)
  | otherwise             = Left InvalidEmail
```

---

## 3. Non-empty collections

**Anti-pattern:** `items: T[]` plus a function that throws when it is empty, called defensively at
every use site.

**Rust:** use a `NonEmpty<T>` — the `nonempty` crate, or hand-rolled `struct NonEmpty<T> { head: T,
tail: Vec<T> }` — so `.first()` returns `T`, not `Option<T>`.

**Haskell:** `Data.List.NonEmpty`, the same idea: `NonEmpty a = a :| [a]`.

**TypeScript:** `type NonEmptyArray<T> = [T, ...T[]]`, a tuple type the compiler enforces at the
call site.

**Go:** no tuple types. Hand-roll a small type with a private slice field and a constructor that
errors on empty input, the same shape as the `Email` example above.

---

## 4. Exhaustive matching

Once you have a sum type from pattern 1, let the compiler catch missing cases instead of relying on
a `default:` or `else` that silently swallows a case you forgot.

**Rust:** `match` with no wildcard arm — an unhandled variant is a compile error. Add `_ => ...`
only when you genuinely mean "everything else", never as a safety net.

**TypeScript:** omit the `default` case in a `switch` over a discriminated union and add an
`assertNever` helper:

```typescript
function assertNever(x: never): never {
  throw new Error(`Unhandled case: ${JSON.stringify(x)}`);
}
```

Call it in the `default` position. Adding a union member later without updating the switch becomes a
compile error, because `x` is no longer assignable to `never`.

**Haskell:** turn on `-Wincomplete-patterns`, ideally `-Werror=incomplete-patterns`, so an unmatched
constructor fails the build instead of crashing at runtime.

**Go:** no compiler-enforced exhaustiveness. Run the `exhaustive` linter over type switches on the
sealed-interface pattern from section 1, and treat lint failures as build failures in CI.

---

## 5. Parse at the boundary, trust everywhere after

The unifying discipline: do the messy work — parsing JSON, validating user input, reading a config
file — exactly once, where the untrusted data enters the system. Everything downstream takes the
_parsed_ type, never the raw one. Downstream code then has no reason to re-validate, and no way to
forget.

A useful smell test: a function that takes a raw `string`, `int`, or `map` where a narrower type
would do, and whose first few lines are validation, is holding validation that belongs at the
caller's boundary. Push the parse outward until the signature itself documents what is guaranteed.
