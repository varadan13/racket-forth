#lang racket/base

(require racket/port racket/string)

(provide
  read-syntax
  (rename-out [forthe-module-begin #%module-begin])
  push! result define void
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
;; Reads FORTHE source by splitting on whitespace (avoids Racket treating ; as
;; a comment).  Each token is compiled to a Racket form and wrapped in a module
;; datum.  The generated module uses forthe.rkt as its language.

(define (read-syntax path port)
  (define src-datums (port->tokens port))
  (define module-datum `(module forthe-mod "forthe.rkt"
                           ,@(map token->form src-datums)))
  (datum->syntax #f module-datum))

;; Turn a raw string token into a number or symbol.
(define (parse-token s)
  (or (string->number s) (string->symbol s)))

;; Split source into structured tokens, grouping `: name body... ;` into
;; (def name (body-token ...)) so ; is never seen by Racket's reader.
(define (port->tokens port)
  (define words (string-split (port->string port)))
  (let loop ([ws words] [acc '()])
    (cond
      [(null? ws) (reverse acc)]
      [(equal? (car ws) ":")
       (define name (string->symbol (cadr ws)))
       (let body-loop ([rest (cddr ws)] [body '()])
         (cond
           [(null? rest) (error "forthe: missing ; for word" name)]
           [(equal? (car rest) ";")
            (loop (cdr rest) (cons `(def ,name ,(reverse body)) acc))]
           [else (body-loop (cdr rest) (cons (parse-token (car rest)) body))]))]
      [else
       (loop (cdr ws) (cons (parse-token (car ws)) acc))])))

(define (token->form tok)
  (cond
    [(number? tok)                        `(push! ,tok)]
    [(and (pair? tok) (eq? (car tok) 'def))
     (define name (cadr tok))
     (define body (caddr tok))
     (if (null? body)
         `(define (,name) (void))
         `(define (,name) ,@(map token->form body)))]
    [(symbol? tok)                        `(,tok)]))
