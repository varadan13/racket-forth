#lang racket

(provide run)

;; run : string -> (listof integer)
;;
;; Executes a FORTHE program and returns the final stack, bottom-to-top.
;; Raises exn:fail for:
;;   - Unknown word: <name>
;;   - Stack underflow
;;   - Missing ;
;;   - Division by zero

(define (run src)
  ;; ── Tokenise ──────────────────────────────────────────────────────────────
  ;; string-split handles space, tab, and newline
  (define raw-tokens (string-split src))

  ;; classify : string -> token
  ;; token = 'colon | 'semi | (cons 'num integer) | (cons 'word string)
  (define (classify tok)
    (cond
      [(equal? tok ":")  'colon]
      [(equal? tok ";")  'semi]
      [(regexp-match? #rx"^-?[0-9]+$" tok) (cons 'num (string->number tok))]
      [else (cons 'word tok)]))

  (define tokens (map classify raw-tokens))

  ;; ── Interpreter state ─────────────────────────────────────────────────────
  (define stack '())          ; top = car
  (define dict  (make-hash))  ; string → (listof token)

  (define (push! v)
    (set! stack (cons v stack)))

  (define (pop!)
    (when (null? stack) (error "Stack underflow"))
    (begin0 (car stack)
            (set! stack (cdr stack))))

  ;; ── Built-in word execution ───────────────────────────────────────────────
  ;; Returns #f if w is not a built-in (caller handles user-defined lookup).
  (define (exec-builtin! w)
    (match w
      ["DUP"  (let ([x (pop!)]) (push! x) (push! x))]
      ["DROP" (pop!) (void)]
      ["SWAP" (let* ([b (pop!)] [a (pop!)]) (push! b) (push! a))]
      ["OVER" (let* ([b (pop!)] [a (pop!)]) (push! a) (push! b) (push! a))]
      ["+"    (let* ([b (pop!)] [a (pop!)]) (push! (+ a b)))]
      ["-"    (let* ([b (pop!)] [a (pop!)]) (push! (- a b)))]
      ["*"    (let* ([b (pop!)] [a (pop!)]) (push! (* a b)))]
      ["/"    (let* ([b (pop!)] [a (pop!)])
                (when (= b 0) (error "Division by zero"))
                (push! (quotient a b)))]
      [_      #f]))

  ;; ── Word / token execution ────────────────────────────────────────────────
  (define (exec-word! w)
    (unless (exec-builtin! w)
      (if (hash-has-key? dict w)
          (for-each exec-token! (hash-ref dict w))
          (error (format "Unknown word: ~a" w)))))

  (define (exec-token! t)
    (match t
      [(cons 'num n)  (push! n)]
      [(cons 'word w) (exec-word! w)]))

  ;; ── Top-level processing loop ─────────────────────────────────────────────
  (let loop ([toks tokens])
    (unless (null? toks)
      (match (car toks)

        ;; Definition: : NAME body... ;
        ['colon
         (when (null? (cdr toks)) (error "Missing ;"))
         (match (cadr toks)
           [(cons 'word name)
            (define-values (body rest)
              (let collect ([ts (cddr toks)] [acc '()])
                (cond
                  [(null? ts)           (error "Missing ;")]
                  [(eq? (car ts) 'semi) (values (reverse acc) (cdr ts))]
                  [else                 (collect (cdr ts) (cons (car ts) acc))])))
            (hash-set! dict name body)
            (loop rest)]
           [_ (error "Missing ;")])]

        ;; Number literal — push onto stack
        [(cons 'num n)
         (push! n)
         (loop (cdr toks))]

        ;; Word call
        [(cons 'word w)
         (exec-word! w)
         (loop (cdr toks))]

        ;; Bare semicolon outside a definition
        ['semi (error "Unexpected ;")])))

  ;; Return stack bottom-to-top
  (reverse stack))
