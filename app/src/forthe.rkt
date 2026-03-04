#lang racket/base

(provide
  read-syntax
  (rename-out [forthe-module-begin #%module-begin])
  push! pop! exec! result run)

;; ── Stack ─────────────────────────────────────────────────────────────────────

(define *stack* '())  ; top = car

(define (push! v) (set! *stack* (cons v *stack*)))

(define (pop!)
  (when (null? *stack*) (error "Stack underflow"))
  (let ([v (car *stack*)])
    (set! *stack* (cdr *stack*))
    v))

(define (reset!) (set! *stack* '()))

;; result : -> (listof integer), bottom-to-top
(define (result) (reverse *stack*))

;; ── #%module-begin ─────────────────────────────────────────────────────────────
;; Wraps the compiled forms for `#lang reader "forthe.rkt"` files.
;; Executes all forms then prints the final stack.

(define-syntax forthe-module-begin
  (syntax-rules ()
    [(_ form ...)
     (#%module-begin
       form ...
       (displayln (result)))]))

;; ── Reader ─────────────────────────────────────────────────────────────────────
;; Uses Racket's built-in `read` to tokenise FORTHE source.
;;
;; `read` naturally handles:
;;   - integers (including negatives: -5, -3) → number?
;;   - words and `:` → symbol?
;;
;; Caveat: `;` is Racket's line-comment delimiter, so full FORTHE definition
;; support (which uses `;` as a terminator) will require a custom tokeniser.
;; All NUM tests operate on pure number input — unaffected by this.

(define (port->tokens port)
  (let loop ([acc '()])
    (define tok (read port))
    (if (eof-object? tok)
        (reverse acc)
        (loop (cons tok acc)))))

;; compile-token: raw token -> Racket form to embed in the generated module
(define (compile-token tok)
  (cond
    [(number? tok) `(push! ,tok)]
    [(symbol? tok) `(exec! ',tok)]
    [else (error (format "unrecognised token: ~a" tok))]))

;; read-syntax: entry point for `#lang reader "forthe.rkt"`
;; Produces a module whose language is forthe.rkt itself, so it gets
;; access to push!, exec!, #%module-begin, etc.
(define (read-syntax path port)
  (define tokens (port->tokens port))
  (datum->syntax #f
    `(module forthe-program "forthe.rkt"
       ,@(map compile-token tokens))))

;; ── run ────────────────────────────────────────────────────────────────────────
;; run : string -> (listof integer)
;; Tokenises with `read`, evaluates each token, returns final stack bottom-to-top.

(define (run src)
  (reset!)
  (for-each eval-token! (port->tokens (open-input-string src)))
  (result))

(define (eval-token! tok)
  (cond
    [(number? tok) (push! tok)]
    [(symbol? tok) (exec! tok)]))

;; exec!: word execution — extended in later stages
(define (exec! sym)
  (error (format "Unknown word: ~a" sym)))
