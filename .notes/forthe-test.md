#lang racket

(require rackunit
         rackunit/text-ui
         "forthe.rkt")

;; ── Helpers ───────────────────────────────────────────────────────────────

;; Stack result check
(define-syntax-rule (t: desc input expected)
  (test-case desc
    (check-equal? (run input) expected)))

;; Error check — exn message must contain fragment
(define-syntax-rule (t:err desc input fragment)
  (test-case desc
    (check-exn
      (λ (e) (string-contains? (exn-message e) fragment))
      (λ () (run input)))))

;; Error check — any exn:fail (for impl-defined messages)
(define-syntax-rule (t:any-err desc input)
  (test-case desc
    (check-exn exn:fail? (λ () (run input)))))

;; ── Test Suites ───────────────────────────────────────────────────────────

(define numbers-tests
  (test-suite "Numbers"
    (t: "NUM-01: single positive number"     "5"          '(5))
    (t: "NUM-02: zero"                       "0"          '(0))
    (t: "NUM-03: negative number"            "-5"         '(-5))
    (t: "NUM-04: large number"               "999999"     '(999999))
    (t: "NUM-05: multiple numbers LTR"       "1 2 3"      '(1 2 3))
    (t: "NUM-06: negative then positive"     "-3 7"       '(-3 7))))

(define identifiers-tests
  (test-suite "Identifiers"
    (t: "IDENT-01: uppercase"                ": WORD 1 ; WORD"            '(1))
    (t: "IDENT-02: lowercase"                ": word 1 ; word"            '(1))
    (t: "IDENT-03: mixed case"               ": MyWord 1 ; MyWord"        '(1))
    (t: "IDENT-04: underscore"               ": FOO_BAR 1 ; FOO_BAR"      '(1))
    (t: "IDENT-05: digit suffix"             ": WORD2 99 ; WORD2"         '(99))
    (t: "IDENT-06: case-sensitive"           ": foo 1 ; : FOO 2 ; foo FOO" '(1 2))))

(define definitions-tests
  (test-suite "Definitions"
    (t: "DEF-01: define and call"            ": WASHER 1 ; WASHER"                           '(1))
    (t: "DEF-02: body not executed at def"   ": WASHER 1 ;"                                  '())
    (t: "DEF-03: empty body"                 ": NOP ; NOP"                                   '())
    (t: "DEF-04: multiple defs"              ": WASHER 1 ; : DRYER 2 ; WASHER DRYER"         '(1 2))
    (t: "DEF-05: call same word twice"       ": PUSH1 1 ; PUSH1 PUSH1"                       '(1 1))
    (t: "DEF-06: body with multiple lits"    ": PAIR 3 4 ; PAIR"                             '(3 4))
    (t: "DEF-07: body refs built-in"         ": DOUBLE DUP + ; 5 DOUBLE"                     '(10))
    (t: "DEF-08: body refs user word"        ": DOUBLE DUP + ; : QUAD DOUBLE DOUBLE ; 3 QUAD" '(12))
    (t: "DEF-09: redefinition wins"          ": FOO 1 ; : FOO 2 ; FOO"                       '(2))
    (t: "DEF-10: word calls earlier word"    ": A 10 ; : B A 20 ; B"                         '(10 20))
    (t: "DEF-11: def does not consume stack" "5 : PUSH1 1 ; PUSH1"                           '(5 1))
    (t: "DEF-12: body mixes nums + builtins" ": SQUARE DUP * ; 4 SQUARE"                     '(16))))

(define execution-tests
  (test-suite "Execution Model"
    (t: "EXEC-01: empty program"             ""                              '())
    (t: "EXEC-02: left-to-right eval"        "1 2 -"                         '(-1))
    (t: "EXEC-03: stack persists"            "10 : ADD5 5 + ; ADD5"          '(15))
    (t: "EXEC-04: pure defs leave no stack"  ": A 42 ; : B 99 ;"             '())
    (t: "EXEC-05: defs then calls"           ": A 1 ; : B 2 ; : C 3 ; A B C" '(1 2 3))
    (t: "EXEC-06: latest def wins"           ": FOO 1 ; : FOO 2 ; FOO"       '(2))))

(define stack-ops-tests
  (test-suite "Stack Ops"
    ;; DUP
    (t: "DUP-01: duplicates top"             "5 DUP"        '(5 5))
    (t: "DUP-02: does not disturb below"     "1 2 DUP"      '(1 2 2))
    (t: "DUP-03: chained DUP"               "3 DUP DUP"    '(3 3 3))
    ;; DROP
    (t: "DROP-01: removes top"               "5 DROP"       '())
    (t: "DROP-02: leaves elements below"     "1 2 3 DROP"   '(1 2))
    (t: "DROP-03: chained DROP"              "1 2 3 DROP DROP" '(1))
    ;; SWAP
    (t: "SWAP-01: swaps top two"             "1 2 SWAP"     '(2 1))
    (t: "SWAP-02: double swap restores"      "1 2 SWAP SWAP" '(1 2))
    (t: "SWAP-03: leaves deeper elems"       "10 1 2 SWAP"  '(10 2 1))
    ;; OVER
    (t: "OVER-01: copies second to top"      "1 2 OVER"     '(1 2 1))
    (t: "OVER-02: originals intact"          "3 4 OVER"     '(3 4 3))
    (t: "OVER-03: OVER then +"               "3 4 OVER +"   '(3 7))))

(define arithmetic-tests
  (test-suite "Arithmetic"
    ;; +
    (t: "ADD-01: basic addition"             "2 3 +"        '(5))
    (t: "ADD-02: adding zero"                "7 0 +"        '(7))
    (t: "ADD-03: two negatives"              "-3 -4 +"      '(-7))
    (t: "ADD-04: positive + negative"        "10 -3 +"      '(7))
    (t: "ADD-05: commutative result"         "3 2 +"        '(5))
    ;; -
    (t: "SUB-01: basic subtraction"          "5 2 -"        '(3))
    (t: "SUB-02: negative result"            "2 5 -"        '(-3))
    (t: "SUB-03: subtract zero"              "7 0 -"        '(7))
    (t: "SUB-04: subtract negative"         "5 -3 -"       '(8))
    (t: "SUB-05: order is a-b"              "10 3 -"       '(7))
    ;; *
    (t: "MUL-01: basic multiplication"       "2 4 *"        '(8))
    (t: "MUL-02: multiply by zero"           "99 0 *"       '(0))
    (t: "MUL-03: multiply by one"            "7 1 *"        '(7))
    (t: "MUL-04: two negatives"              "-3 -4 *"      '(12))
    (t: "MUL-05: positive × negative"        "-3 2 *"       '(-6))
    ;; /
    (t: "DIV-01: exact division"             "6 2 /"        '(3))
    (t: "DIV-02: truncating division"        "7 2 /"        '(3))
    (t: "DIV-03: dividend < divisor"         "3 10 /"       '(0))
    (t: "DIV-04: identity division"          "1 1 /"        '(1))
    (t: "DIV-05: order is a/b"              "10 2 /"       '(5))
    ;; Compound
    (t: "ARITH-01: chained ops"              "1 2 + 3 *"          '(9))
    (t: "ARITH-02: two subexpressions"       "2 3 + 4 5 + *"      '(45))
    (t: "ARITH-03: SQUARE from spec"         ": SQUARE DUP * ; 4 SQUARE" '(16))
    (t: "ARITH-04: DOUBLE from spec"         ": DOUBLE DUP + ; 5 DOUBLE" '(10))))

(define errors-tests
  (test-suite "Errors"
    ;; §13.1 Unknown word
    (t:err     "ERR-01: unknown word"              "FOOBAR"          "Unknown word: FOOBAR")
    (t:err     "ERR-02: unknown word mid-program"  "1 2 FOOBAR +"    "Unknown word: FOOBAR")
    (t:err     "ERR-03: wrong-case built-in"       "5 dup"           "Unknown word: dup")
    (t:err     "ERR-04: never-defined word"        "NOTDEFINED"      "Unknown word: NOTDEFINED")
    ;; §13.2 Stack underflow
    (t:err     "ERR-05: + empty stack"             "+"               "Stack underflow")
    (t:err     "ERR-06: + one element"             "1 +"             "Stack underflow")
    (t:err     "ERR-07: - empty stack"             "-"               "Stack underflow")
    (t:err     "ERR-08: * one element"             "1 *"             "Stack underflow")
    (t:err     "ERR-09: / one element"             "1 /"             "Stack underflow")
    (t:err     "ERR-10: DUP empty stack"           "DUP"             "Stack underflow")
    (t:err     "ERR-11: DROP empty stack"          "DROP"            "Stack underflow")
    (t:err     "ERR-12: SWAP empty stack"          "SWAP"            "Stack underflow")
    (t:err     "ERR-13: SWAP one element"          "1 SWAP"          "Stack underflow")
    (t:err     "ERR-14: OVER empty stack"          "OVER"            "Stack underflow")
    (t:err     "ERR-15: OVER one element"          "1 OVER"          "Stack underflow")
    (t:err     "ERR-16: underflow inside word"     ": BADWORD + ; 1 BADWORD" "Stack underflow")
    ;; §13.3 Malformed definition
    (t:err     "ERR-17: missing ; at EOF"          ": FOO 1"         "Missing ;")
    (t:err     "ERR-18: missing ; multi-token"     ": FOO 1 2 3"     "Missing ;")
    (t:any-err "ERR-19: bare colon"                ":")
    ;; Division by zero
    (t:any-err "ERR-20: division by zero"          "5 0 /")))

(define integration-tests
  (test-suite "Integration"
    (t: "INT-01: spec ex1 WASHER"            ": WASHER 1 ; WASHER"                              '(1))
    (t: "INT-02: spec ex2 DOUBLE"            ": DOUBLE DUP + ; 5 DOUBLE"                        '(10))
    (t: "INT-03: spec ex3 SQUARE"            ": SQUARE DUP * ; 4 SQUARE"                        '(16))
    (t: "INT-04: two words sequentially"     ": WASHER 1 ; : DRYER 2 ; WASHER DRYER"            '(1 2))
    (t: "INT-05: QUAD = DOUBLE DOUBLE"       ": DOUBLE DUP + ; : QUAD DOUBLE DOUBLE ; 3 QUAD"   '(12))
    (t: "INT-06: SQUARE then DOUBLE"         ": SQUARE DUP * ; : DOUBLE DUP + ; 3 SQUARE DOUBLE" '(18))
    (t: "INT-07: SWAP before subtract"       "3 10 SWAP -"                                      '(7))
    (t: "INT-08: accumulate SQ results"      ": SQ DUP * ; 2 SQ 3 SQ 4 SQ"                     '(4 9 16))
    (t: "INT-09: deep composition"           ": A 1 ; : B A A + ; : C B B * ; C"               '(4))
    (t: "INT-10: redefined word both calls"  ": FOO 10 ; : FOO 20 ; FOO FOO"                    '(20 20))
    (t: "INT-11: stack survives def"         "99 : X 1 ; X"                                     '(99 1))
    (t: "INT-12: OVER for sum"               "5 3 OVER +"                                       '(5 8))
    (t: "INT-13: arith + stack ops mixed"    "2 3 + DUP *"                                      '(25))))

;; ── Run all ───────────────────────────────────────────────────────────────

(define forthe-tests
  (test-suite "FORTHE"
    numbers-tests
    identifiers-tests
    definitions-tests
    execution-tests
    stack-ops-tests
    arithmetic-tests
    errors-tests
    integration-tests))

(run-tests forthe-tests)
