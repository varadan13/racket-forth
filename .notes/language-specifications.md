# FORTHE Language Specification

## 1. Overview

**FORTHE** is a **stack-based concatenative programming language**.

Programs are sequences of **words** executed left-to-right.
Words operate on a **data stack**, consuming inputs and producing outputs.

Characteristics:

* postfix syntax
* stack-based execution
* concatenative composition
* extensible dictionary
* minimal syntax

Example:

```
: WASHER 1 ;
WASHER
```

Resulting stack:

```
[1]
```

---

# 2. Program Structure

A **program** is a sequence of **tokens**.

Tokens may be:

* numbers
* identifiers
* definition delimiters (`:` `;`)

Programs execute **sequentially**.

Example:

```
: WASHER 1 ;
: DRYER 2 ;

WASHER DRYER
```

---

# 3. Lexical Structure

## 3.1 Character Set

FORTHE programs consist of Unicode characters.

The following characters have syntactic meaning:

```
:  ;
```

All other characters participate in token construction.

---

## 3.2 Whitespace

Whitespace separates tokens.

Whitespace characters:

```
space
tab
newline
```

Example:

```
: WASHER 1 ;
```

Equivalent to

```
:   WASHER   1   ;
```

---

## 3.3 Tokens

Tokens are maximal sequences of non-whitespace characters.

Token types:

```
NUMBER
IDENTIFIER
COLON
SEMICOLON
```

---

# 4. Numbers

Numbers represent **signed integers**.

Grammar:

```
number ::= ["-"] digit+
digit  ::= "0" | "1" | ... | "9"
```

Examples:

```
0
1
42
-5
```

Semantics:

```
number → push integer onto stack
```

Example:

```
5
```

Stack:

```
[5]
```

---

# 5. Identifiers (Words)

Identifiers name **words** stored in the dictionary.

Grammar:

```
identifier ::= letter (letter | digit | "_")*
```

Examples:

```
WASHER
ADD
DOUBLE
FOO_BAR
```

Identifiers are **case sensitive**.

---

# 6. Dictionary

FORTHE maintains a **dictionary** mapping identifiers to definitions.

```
Dictionary : Identifier → WordDefinition
```

Example entry:

```
WASHER → [1]
```

---

# 7. Definitions

Words are defined using the syntax:

```
: <identifier> <body> ;
```

Where:

* `:` begins a definition
* `<identifier>` is the word name
* `<body>` is a sequence of tokens
* `;` ends the definition

Example:

```
: WASHER 1 ;
```

Meaning:

```
WASHER pushes 1 onto the stack
```

---

# 8. Grammar (EBNF)

```
program      ::= element*

element      ::= definition
               | word

definition   ::= ":" identifier word* ";"

word         ::= identifier
               | number

identifier   ::= letter (letter | digit | "_")*

number       ::= ["-"] digit+
```

---

# 9. Execution Model

FORTHE execution uses a **data stack**.

```
Stack = sequence of integers
```

Initial stack:

```
[]
```

Programs execute **left-to-right**.

---

# 10. Evaluation Rules

Evaluation is defined by the following rules.

## 10.1 Number Evaluation

```
⟨ stack , number ⟩ → push(number)
```

Example:

```
3
```

Stack:

```
[3]
```

---

## 10.2 Word Evaluation

If token `w` exists in the dictionary:

```
⟨ stack , w ⟩ → execute(dictionary[w])
```

Execution of a definition:

```
execute([t1 t2 ... tn]):
    evaluate t1
    evaluate t2
    ...
    evaluate tn
```

---

## 10.3 Definition Evaluation

```
: name body ;
```

Adds an entry to the dictionary:

```
Dictionary[name] = body
```

---

# 11. Built-in Words

An implementation must provide the following built-ins.

---

# 11.1 Stack Operations

### DUP

Duplicate the top element.

Stack effect:

```
(x -- x x)
```

Example:

```
5 DUP
```

Stack:

```
[5 5]
```

---

### DROP

Remove the top element.

Stack effect:

```
(x -- )
```

Example:

```
5 DROP
```

Stack:

```
[]
```

---

### SWAP

Swap top two elements.

Stack effect:

```
(a b -- b a)
```

Example:

```
1 2 SWAP
```

Stack:

```
[2 1]
```

---

### OVER

Copy second element.

Stack effect:

```
(a b -- a b a)
```

Example:

```
1 2 OVER
```

Stack:

```
[1 2 1]
```

---

# 11.2 Arithmetic Operations

Arithmetic operations consume two integers.

---

### +

```
(a b -- a+b)
```

Example:

```
2 3 +
```

Stack:

```
[5]
```

---

### -

```
(a b -- a-b)
```

Example:

```
5 2 -
```

Stack:

```
[3]
```

---

### *

```
(a b -- a*b)
```

Example:

```
2 4 *
```

Stack:

```
[8]
```

---

### /

Integer division.

```
(a b -- a/b)
```

Example:

```
6 2 /
```

Stack:

```
[3]
```

---

# 12. Stack Effects

Each word transforms the stack.

Notation:

```
(input -- output)
```

Examples:

```
DUP    (x -- x x)
DROP   (x -- )
SWAP   (a b -- b a)
+      (a b -- c)
```

---

# 13. Error Conditions

Implementations must detect the following errors.

---

## 13.1 Unknown Word

If a token is not:

* a number
* a defined word
* a built-in

Error:

```
Unknown word: <token>
```

---

## 13.2 Stack Underflow

Occurs when a word requires more values than available.

Example:

```
+
```

Error:

```
Stack underflow
```

---

## 13.3 Malformed Definition

Example:

```
: FOO 1
```

Error:

```
Missing ;
```

---

# 14. Example Programs

---

## Example 1

```
: WASHER 1 ;
WASHER
```

Stack:

```
[1]
```

---

## Example 2

```
: DOUBLE DUP + ;
5 DOUBLE
```

Stack:

```
[10]
```

---

## Example 3

```
: SQUARE DUP * ;
4 SQUARE
```

Stack:

```
[16]
```

---

# 15. Implementation Architecture

A FORTHE implementation typically consists of:

### 1. Reader

Tokenizes source code.

```
": WASHER 1 ;"
→
(: WASHER 1 ;)
```

---

### 2. Compiler / Expander

Processes definitions.

```
: WASHER 1 ;
```

becomes

```
Dictionary["WASHER"] = [1]
```

---

### 3. Interpreter

Stack machine executing words.

Pseudo:

```
for token in program:
    execute(token)
```

---

# 16. Minimal Interpreter State

An interpreter maintains:

```
Stack       : list of integers
Dictionary  : map (identifier → token list)
Program     : token sequence
```

---
