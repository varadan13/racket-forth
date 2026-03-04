#lang racket/base

(require rackunit
         rackunit/text-ui
         "forthe.rkt")

;; ── Helpers ───────────────────────────────────────────────────────────────────

(define-syntax-rule (t: desc input expected)
  (test-case desc
    (check-equal? (run input) expected)))

;; ── Numbers ───────────────────────────────────────────────────────────────────

(define numbers-tests
  (test-suite "Numbers"
    (t: "NUM-01: single positive number"  "5"       '(5))
    (t: "NUM-02: zero"                    "0"       '(0))
    (t: "NUM-03: negative number"         "-5"      '(-5))
    (t: "NUM-04: large number"            "999999"  '(999999))
    (t: "NUM-05: multiple numbers LTR"   "1 2 3"   '(1 2 3))
    (t: "NUM-06: negative then positive" "-3 7"    '(-3 7))))

;; ── Run ───────────────────────────────────────────────────────────────────────

(run-tests numbers-tests)
