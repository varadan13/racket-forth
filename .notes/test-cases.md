# FORTHE Language — Test Cases (Pseudocode)

## Notation

```
TEST "<id>: <description>"
  INPUT  "<forthe source>"
  STACK  [bottom, ..., top]   -- expected final stack; left = bottom
  -- OR --
  TOKENS [...]                -- expected token stream (LEXER tests only)
  -- OR --
  ERROR  "<message>"          -- expected error
```

`[]` means empty stack. Stack underflow errors halt the program immediately.

The runnable Racket implementation of these tests lives in `forthe-test.rkt`
using the `rackunit` framework. Each TEST below maps directly to a `test-case`
in that file.

> **Note:** The LEXER group from earlier drafts has been removed. The tokeniser
> is an internal implementation detail; the public contract of the interpreter
> is `run : string → (listof integer)`, so all tests operate at that level.

---

## GROUP: NUMBERS

Tests push semantics of number literals (§4).

```
TEST "NUM-01: single positive number is pushed"
  INPUT  "5"
  STACK  [5]

TEST "NUM-02: zero is pushed"
  INPUT  "0"
  STACK  [0]

TEST "NUM-03: negative number is pushed"
  INPUT  "-5"
  STACK  [-5]

TEST "NUM-04: large number is pushed"
  INPUT  "999999"
  STACK  [999999]

TEST "NUM-05: multiple numbers are pushed left-to-right"
  INPUT  "1 2 3"
  STACK  [1, 2, 3]   -- 3 is on top

TEST "NUM-06: negative then positive"
  INPUT  "-3 7"
  STACK  [-3, 7]
```

---

## GROUP: IDENTIFIERS

Tests grammar and case-sensitivity rules for identifiers (§5).

```
TEST "IDENT-01: all-uppercase identifier is valid"
  INPUT  ": WORD 1 ; WORD"
  STACK  [1]

TEST "IDENT-02: all-lowercase identifier is valid"
  INPUT  ": word 1 ; word"
  STACK  [1]

TEST "IDENT-03: mixed-case identifier is valid"
  INPUT  ": MyWord 1 ; MyWord"
  STACK  [1]

TEST "IDENT-04: identifier with underscore is valid"
  INPUT  ": FOO_BAR 1 ; FOO_BAR"
  STACK  [1]

TEST "IDENT-05: identifier with digit suffix is valid"
  INPUT  ": WORD2 99 ; WORD2"
  STACK  [99]

TEST "IDENT-06: identifiers are case-sensitive — different words"
  INPUT  ": foo 1 ; : FOO 2 ; foo FOO"
  STACK  [1, 2]
```

---

## GROUP: DEFINITIONS

Tests the `: name body ;` form (§7).

```
TEST "DEF-01: define and call a word that pushes a number"
  INPUT  ": WASHER 1 ; WASHER"
  STACK  [1]

TEST "DEF-02: body is not executed at definition time"
  INPUT  ": WASHER 1 ;"
  STACK  []          -- definition only; nothing pushed

TEST "DEF-03: definition with empty body is valid"
  INPUT  ": NOP ; NOP"
  STACK  []

TEST "DEF-04: multiple definitions, each called once"
  INPUT  ": WASHER 1 ; : DRYER 2 ; WASHER DRYER"
  STACK  [1, 2]

TEST "DEF-05: calling the same word twice"
  INPUT  ": PUSH1 1 ; PUSH1 PUSH1"
  STACK  [1, 1]

TEST "DEF-06: word body with multiple literals"
  INPUT  ": PAIR 3 4 ; PAIR"
  STACK  [3, 4]

TEST "DEF-07: word body references a built-in"
  INPUT  ": DOUBLE DUP + ; 5 DOUBLE"
  STACK  [10]

TEST "DEF-08: word body references an earlier user-defined word"
  INPUT  ": DOUBLE DUP + ; : QUAD DOUBLE DOUBLE ; 3 QUAD"
  STACK  [12]

TEST "DEF-09: redefining a word replaces the earlier definition"
  INPUT  ": FOO 1 ; : FOO 2 ; FOO"
  STACK  [2]

TEST "DEF-10: word can call an earlier user word in its body"
  INPUT  ": A 10 ; : B A 20 ; B"
  STACK  [10, 20]

TEST "DEF-11: definition does not consume values already on the stack"
  INPUT  "5 : PUSH1 1 ; PUSH1"
  STACK  [5, 1]

TEST "DEF-12: body mixing numbers and built-ins"
  INPUT  ": SQUARE DUP * ; 4 SQUARE"
  STACK  [16]
```

---

## GROUP: EXECUTION MODEL

Tests left-to-right sequential evaluation and stack machine semantics (§9–10).

```
TEST "EXEC-01: empty program leaves stack empty"
  INPUT  ""
  STACK  []

TEST "EXEC-02: evaluation is strictly left-to-right"
  INPUT  "1 2 -"
  STACK  [-1]        -- a=1, b=2, a-b = -1

TEST "EXEC-03: stack persists across word calls"
  INPUT  "10 : ADD5 5 + ; ADD5"
  STACK  [15]

TEST "EXEC-04: pure definitions leave stack empty"
  INPUT  ": A 42 ; : B 99 ;"
  STACK  []

TEST "EXEC-05: all definitions then all calls"
  INPUT  ": A 1 ; : B 2 ; : C 3 ; A B C"
  STACK  [1, 2, 3]

TEST "EXEC-06: latest definition wins at call time"
  INPUT  ": FOO 1 ; : FOO 2 ; FOO"
  STACK  [2]
```

---

## GROUP: STACK OPS

Tests DUP, DROP, SWAP, OVER (§11.1).

```
-- DUP  (x -- x x)

TEST "DUP-01: duplicates top element"
  INPUT  "5 DUP"
  STACK  [5, 5]

TEST "DUP-02: does not disturb elements below"
  INPUT  "1 2 DUP"
  STACK  [1, 2, 2]

TEST "DUP-03: chained DUP"
  INPUT  "3 DUP DUP"
  STACK  [3, 3, 3]

-- DROP  (x -- )

TEST "DROP-01: removes top element, stack becomes empty"
  INPUT  "5 DROP"
  STACK  []

TEST "DROP-02: leaves elements below"
  INPUT  "1 2 3 DROP"
  STACK  [1, 2]

TEST "DROP-03: chained DROP"
  INPUT  "1 2 3 DROP DROP"
  STACK  [1]

-- SWAP  (a b -- b a)

TEST "SWAP-01: swaps top two elements"
  INPUT  "1 2 SWAP"
  STACK  [2, 1]

TEST "SWAP-02: double SWAP restores original order"
  INPUT  "1 2 SWAP SWAP"
  STACK  [1, 2]

TEST "SWAP-03: leaves elements below untouched"
  INPUT  "10 1 2 SWAP"
  STACK  [10, 2, 1]

-- OVER  (a b -- a b a)

TEST "OVER-01: copies second-from-top to top"
  INPUT  "1 2 OVER"
  STACK  [1, 2, 1]

TEST "OVER-02: original elements remain intact"
  INPUT  "3 4 OVER"
  STACK  [3, 4, 3]

TEST "OVER-03: OVER followed by + (add without consuming original)"
  INPUT  "3 4 OVER +"
  -- after OVER: [3, 4, 3]; after +: [3, 7]
  STACK  [3, 7]
```

---

## GROUP: ARITHMETIC

Tests `+`, `-`, `*`, `/` with stack effect `(a b -- result)` where a is
second-from-top and b is top (§11.2).

```
-- + (addition)

TEST "ADD-01: basic addition"
  INPUT  "2 3 +"
  STACK  [5]

TEST "ADD-02: adding zero"
  INPUT  "7 0 +"
  STACK  [7]

TEST "ADD-03: adding two negatives"
  INPUT  "-3 -4 +"
  STACK  [-7]

TEST "ADD-04: positive + negative"
  INPUT  "10 -3 +"
  STACK  [7]

TEST "ADD-05: addition is commutative (order doesn't matter for result)"
  INPUT  "3 2 +"
  STACK  [5]

-- - (subtraction)

TEST "SUB-01: basic subtraction"
  INPUT  "5 2 -"
  STACK  [3]

TEST "SUB-02: result is negative when b > a"
  INPUT  "2 5 -"
  STACK  [-3]

TEST "SUB-03: subtracting zero"
  INPUT  "7 0 -"
  STACK  [7]

TEST "SUB-04: subtracting a negative adds"
  INPUT  "5 -3 -"
  STACK  [8]

TEST "SUB-05: order is a-b, not b-a"
  INPUT  "10 3 -"
  STACK  [7]         -- a=10, b=3, 10-3=7

-- * (multiplication)

TEST "MUL-01: basic multiplication"
  INPUT  "2 4 *"
  STACK  [8]

TEST "MUL-02: multiply by zero"
  INPUT  "99 0 *"
  STACK  [0]

TEST "MUL-03: multiply by one"
  INPUT  "7 1 *"
  STACK  [7]

TEST "MUL-04: two negatives yield positive"
  INPUT  "-3 -4 *"
  STACK  [12]

TEST "MUL-05: positive times negative"
  INPUT  "-3 2 *"
  STACK  [-6]

-- / (integer division)

TEST "DIV-01: exact integer division"
  INPUT  "6 2 /"
  STACK  [3]

TEST "DIV-02: non-exact division truncates"
  INPUT  "7 2 /"
  STACK  [3]         -- truncation direction is implementation-defined

TEST "DIV-03: dividend smaller than divisor gives 0"
  INPUT  "3 10 /"
  STACK  [0]

TEST "DIV-04: identity division"
  INPUT  "1 1 /"
  STACK  [1]

TEST "DIV-05: order is a/b"
  INPUT  "10 2 /"
  STACK  [5]         -- a=10, b=2, 10/2=5

-- Compound / chained arithmetic

TEST "ARITH-01: chained operations, left-to-right"
  INPUT  "1 2 + 3 *"
  STACK  [9]         -- (1+2)*3

TEST "ARITH-02: two subexpressions multiplied"
  INPUT  "2 3 + 4 5 + *"
  STACK  [45]        -- (2+3)*(4+5) = 5*9

TEST "ARITH-03: SQUARE from spec"
  INPUT  ": SQUARE DUP * ; 4 SQUARE"
  STACK  [16]

TEST "ARITH-04: DOUBLE from spec"
  INPUT  ": DOUBLE DUP + ; 5 DOUBLE"
  STACK  [10]
```

---

## GROUP: ERRORS

Tests all required error conditions (§13).

```
-- §13.1 Unknown Word

TEST "ERR-01: unknown identifier raises error"
  INPUT  "FOOBAR"
  ERROR  "Unknown word: FOOBAR"

TEST "ERR-02: unknown identifier mid-program halts execution"
  INPUT  "1 2 FOOBAR +"
  ERROR  "Unknown word: FOOBAR"

TEST "ERR-03: built-in in wrong case is unknown"
  INPUT  "5 dup"
  ERROR  "Unknown word: dup"   -- DUP is defined; dup is not

TEST "ERR-04: never-defined word is unknown"
  INPUT  "NOTDEFINED"
  ERROR  "Unknown word: NOTDEFINED"

-- §13.2 Stack Underflow

TEST "ERR-05: + with empty stack"
  INPUT  "+"
  ERROR  "Stack underflow"

TEST "ERR-06: + with only one element"
  INPUT  "1 +"
  ERROR  "Stack underflow"

TEST "ERR-07: - with empty stack"
  INPUT  "-"
  ERROR  "Stack underflow"

TEST "ERR-08: * with only one element"
  INPUT  "1 *"
  ERROR  "Stack underflow"

TEST "ERR-09: / with only one element"
  INPUT  "1 /"
  ERROR  "Stack underflow"

TEST "ERR-10: DUP on empty stack"
  INPUT  "DUP"
  ERROR  "Stack underflow"

TEST "ERR-11: DROP on empty stack"
  INPUT  "DROP"
  ERROR  "Stack underflow"

TEST "ERR-12: SWAP with empty stack"
  INPUT  "SWAP"
  ERROR  "Stack underflow"

TEST "ERR-13: SWAP with only one element"
  INPUT  "1 SWAP"
  ERROR  "Stack underflow"

TEST "ERR-14: OVER with empty stack"
  INPUT  "OVER"
  ERROR  "Stack underflow"

TEST "ERR-15: OVER with only one element"
  INPUT  "1 OVER"
  ERROR  "Stack underflow"

TEST "ERR-16: underflow inside a user word propagates"
  INPUT  ": BADWORD + ; 1 BADWORD"
  ERROR  "Stack underflow"

-- §13.3 Malformed Definition

TEST "ERR-17: definition missing semicolon at EOF"
  INPUT  ": FOO 1"
  ERROR  "Missing ;"

TEST "ERR-18: definition with multi-token body, no semicolon"
  INPUT  ": FOO 1 2 3"
  ERROR  "Missing ;"

TEST "ERR-19: bare colon with nothing after it"
  INPUT  ":"
  ERROR  (malformed definition error)

-- Division by zero (message is implementation-defined)

TEST "ERR-20: division by zero raises an error"
  INPUT  "5 0 /"
  ERROR  (division by zero — exact message is implementation-defined)
```

---

## GROUP: INTEGRATION

End-to-end programs combining multiple features.

```
TEST "INT-01: spec Example 1 — WASHER"
  INPUT  ": WASHER 1 ; WASHER"
  STACK  [1]

TEST "INT-02: spec Example 2 — DOUBLE"
  INPUT  ": DOUBLE DUP + ; 5 DOUBLE"
  STACK  [10]

TEST "INT-03: spec Example 3 — SQUARE"
  INPUT  ": SQUARE DUP * ; 4 SQUARE"
  STACK  [16]

TEST "INT-04: two words defined and called in sequence"
  INPUT  ": WASHER 1 ; : DRYER 2 ; WASHER DRYER"
  STACK  [1, 2]

TEST "INT-05: QUAD composed from two DOUBLEs"
  INPUT  ": DOUBLE DUP + ; : QUAD DOUBLE DOUBLE ; 3 QUAD"
  STACK  [12]

TEST "INT-06: SQUARE then DOUBLE"
  INPUT  ": SQUARE DUP * ; : DOUBLE DUP + ; 3 SQUARE DOUBLE"
  STACK  [18]    -- (3*3)*2 = 18

TEST "INT-07: SWAP reorders operands before subtraction"
  INPUT  "3 10 SWAP -"
  STACK  [7]     -- after SWAP: [10, 3]; 10-3=7

TEST "INT-08: accumulating results from repeated SQUARE calls"
  INPUT  ": SQ DUP * ; 2 SQ 3 SQ 4 SQ"
  STACK  [4, 9, 16]

TEST "INT-09: deeply nested word composition"
  INPUT  ": A 1 ; : B A A + ; : C B B * ; C"
  STACK  [4]     -- A→1, B→2, C→4

TEST "INT-10: redefined word — both calls use latest definition"
  INPUT  ": FOO 10 ; : FOO 20 ; FOO FOO"
  STACK  [20, 20]

TEST "INT-11: number on stack survives an intervening definition"
  INPUT  "99 : X 1 ; X"
  STACK  [99, 1]

TEST "INT-12: OVER used to compute sum without losing first operand"
  INPUT  "5 3 OVER +"
  -- after OVER: [5, 3, 5]; after +: [5, 8]
  STACK  [5, 8]

TEST "INT-13: mixed arithmetic and stack ops"
  INPUT  "2 3 + DUP *"
  STACK  [25]    -- 2+3=5, DUP→[5,5], *→25
```
