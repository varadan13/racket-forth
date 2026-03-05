#lang racket/base

(provide
  read-syntax
  (rename-out [forthe-module-begin #%module-begin])
  push! result
  #%app #%datum #%top)

;; ── Stack ─────────────────────────────────────────────────────────────────────

(define *stack* '())

(define (push! v) (set! *stack* (cons v *stack*)))

(define (result) (reverse *stack*))

;; ── #%module-begin ─────────────────────────────────────────────────────────────
;; Required so forthe.rkt can be used as a module language.
;; Runs all compiled forms then displays the final stack.

(define-syntax forthe-module-begin
  (syntax-rules ()
    [(_ form ...)
     (#%module-begin
       form ...
       (displayln (result)))]))

;; ── Reader ─────────────────────────────────────────────────────────────────────
;; Reads FORTHE source from port using Racket's built-in `read`.
;; Each token is compiled to a Racket form and wrapped in a module datum.
;; The generated module uses forthe.rkt as its language, giving it access
;; to push!, result, and #%module-begin defined above.

(define (read-syntax path port)
  (define src-datums (port->tokens port))
  (define module-datum `(module forthe-mod "forthe.rkt"
                           ,@(map token->form src-datums)))
  (datum->syntax #f module-datum))

(define (port->tokens port)
  (let loop ([acc '()])
    (define tok (read port))
    (if (eof-object? tok)
        (reverse acc)
        (loop (cons tok acc)))))

(define (token->form tok)
  (cond
    [(number? tok) `(push! ,tok)]))
