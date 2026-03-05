# racket-forth

A stack-based FORTH-inspired language implemented as a Racket `#lang`.

## How it works

FORTHE programs are plain text files. Numbers get pushed onto a stack. Words (named operations) manipulate the stack. Everything runs left to right.

```forth
1 2 +        -- stack: (3)
5 DUP *      -- stack: (25)
: DOUBLE 2 * ; 7 DOUBLE   -- stack: (14)
```

## Running

```bash
racket app/src/example.rkt
```

Or write your own file:

```forth
#lang reader "forthe.rkt"

: SQUARE DUP * ;
3 SQUARE
```

## Built-in words

### Arithmetic
All arithmetic pops two values (b on top, a below) and pushes the result.

| Word | Stack effect  | Description        |
|------|---------------|--------------------|
| `+`  | `(a b -- a+b)` | add               |
| `-`  | `(a b -- a-b)` | subtract           |
| `*`  | `(a b -- a*b)` | multiply           |
| `/`  | `(a b -- a/b)` | divide             |

### Stack ops

| Word   | Stack effect      | Description                    |
|--------|-------------------|--------------------------------|
| `DUP`  | `(x -- x x)`      | duplicate top                  |
| `DROP` | `(x -- )`         | remove top                     |
| `SWAP` | `(a b -- b a)`    | swap top two                   |
| `OVER` | `(a b -- a b a)`  | copy second-from-top to top    |

### Word definition

```forth
: WORDNAME body... ;
```

Words can call other words. Redefining a word replaces the old definition.

## Errors

| Condition               | Message                    |
|-------------------------|----------------------------|
| Unknown word            | `Unknown word: NAME`       |
| Not enough stack items  | `Stack underflow`          |
| Missing `;`             | `Missing ;`                |
| Division by zero        | Racket's native error      |

## Project structure

```
app/
  src/
    forthe.rkt    -- the language implementation (reader + runtime)
    example.rkt   -- example program
.notes/
  teacher.md      -- learning roadmaps for understanding the source
  test-cases.md   -- full test suite spec
```

## Implementation

`forthe.rkt` is the entire language in one file:

- **Stack** — a mutable list (`*stack*`)
- **Word dictionary** — a hash table (`*words*`) mapping names to thunks
- **Reader** (`read-syntax`) — splits source text, parses `: name body ;` definitions, compiles each token to a Racket form
- **Expander** (`forthe-module-begin`) — a macro that wraps all forms and appends `(displayln (result))` at the end
