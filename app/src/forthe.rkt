#lang racket/base

(require racket/port racket/string)

(provide
  read-syntax
  (rename-out [forthe-module-begin #%module-begin])
  push! word-define! word-call! lambda void quote
  #%app #%datum #%top)

;; ── Stack ─────────────────────────────────────────────────────────────────────

(define *stack* '())

(define (push! v) (set! *stack* (cons v *stack*)))

(define (result) (reverse *stack*))

;; ── Word dictionary ────────────────────────────────────────────────────────────
;; Words are stored as thunks (zero-arg functions) in a hash table.
;; Redefinition just overwrites the old entry — FORTH semantics for free.

(define *words* (make-hash))

(define (word-define! name thunk)
  (hash-set! *words* name thunk))

(define (word-call! name)
  ((hash-ref *words* name
             (λ () (error (string-append "Unknown word: "
                                         (symbol->string name)))))))

;; ── Built-in arithmetic ────────────────────────────────────────────────────────
;; Each op pops two values (b on top, a below), computes (f a b), pushes result.

(define (binop! f)
  (when (< (length *stack*) 2)
    (error "Stack underflow"))
  (define b (car *stack*))
  (define a (cadr *stack*))
  (set! *stack* (cddr *stack*))
  (push! (f a b)))

(hash-set! *words* '+ (λ () (binop! +)))
(hash-set! *words* '- (λ () (binop! -)))
(hash-set! *words* '* (λ () (binop! *)))
(hash-set! *words* '/ (λ () (binop! /)))

;; ── Built-in stack ops ─────────────────────────────────────────────────────────

(hash-set! *words* 'DUP
  (λ ()
    (when (< (length *stack*) 1) (error "Stack underflow"))
    (push! (car *stack*))))

(hash-set! *words* 'DROP
  (λ ()
    (when (< (length *stack*) 1) (error "Stack underflow"))
    (set! *stack* (cdr *stack*))))

(hash-set! *words* 'SWAP
  (λ ()
    (when (< (length *stack*) 2) (error "Stack underflow"))
    (define top (car *stack*))
    (define sec (cadr *stack*))
    (set! *stack* (cddr *stack*))
    (push! top)  ; goes in first → ends up below
    (push! sec)  ; goes in last  → ends up on top
    ))

(hash-set! *words* 'OVER
  (λ ()
    (when (< (length *stack*) 2) (error "Stack underflow"))
    (push! (cadr *stack*))))

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
       (when (null? (cdr ws)) (error "Missing word name after :"))
       (define name (string->symbol (cadr ws)))
       (let body-loop ([rest (cddr ws)] [body '()])
         (cond
           [(null? rest) (error "Missing ;")]
           [(equal? (car rest) ";")
            (loop (cdr rest) (cons `(def ,name ,(reverse body)) acc))]
           [else (body-loop (cdr rest) (cons (parse-token (car rest)) body))]))]
      [else
       (loop (cdr ws) (cons (parse-token (car ws)) acc))])))

(define (token->form tok)
  (cond
    [(number? tok)
     `(push! ,tok)]
    [(and (pair? tok) (eq? (car tok) 'def))
     (define name (cadr tok))
     (define body (caddr tok))
     (if (null? body)
         `(word-define! ',name (lambda () (void)))
         `(word-define! ',name (lambda () ,@(map token->form body))))]
    [(symbol? tok)
     `(word-call! ',tok)]))
