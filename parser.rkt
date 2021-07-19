#lang racket

(require parser-tools/lex
         (prefix-in : parser-tools/lex-sre)
         parser-tools/yacc)

(require "./lexer.rkt")
(require "./DataTypesDefinition.rkt")

(define simple-python-parser
           (parser
            (start Program)
            (end EOF)
            (error void)
            (tokens a b)
            ;(suppress)
            (grammar
             (Program ((Statements) $1))
             (Statements ((Statement semicolon) (list $1))
                         ((Statements Statement semicolon) (append $1 (list $2))))
             (Statement ((Compound-stmt) (c-statement $1))
                        ((Simple-stmt) (s-statement $1)))
             (Simple-stmt ((Assignment) $1)
                          ((Return-stmt) $1)
                          ((Global-stmt) $1)
                          ((pass) (pass-statement))
                          ((break) (break-statement))
                          ((continue) (continue-statement))
                          ((Print-stmt) $1)
                          ((Printval-stmt) $1)
                          ((Evaluate-stmt) $1))
             (Compound-stmt ((Function-def) $1)
                            ((If-stmt) $1)
                            ((For-stmt) $1))
             (Assignment ((ID assignto Expression)
                          (assignment-statement (string->symbol $1) $3)))
             (Return-stmt ((return) (return-statement '()))
                          ((return Expression) (return-statement $2)))
             (Global-stmt ((global ID) (global-statement (string->symbol $2))))
             (Function-def ((def ID opening-paranthesis Params closing-paranthesis colon Statements)
                            (function-def-statement (string->symbol $2) $4 $7))
                           ((def ID opening-paranthesis closing-paranthesis colon Statements)
                            (function-def-statement (string->symbol $2) (list) $6)))
             (Params ((Param-with-default) (list $1))
                     ((Params comma Param-with-default) (append $1 (list $3))))
             (Param-with-default ((ID assignto Expression)
                                  (param-with-default (string->symbol $1) $3)))
             (If-stmt ((IF Expression colon Statements Else-block)
                       (if-statement $2 $4 $5)))
             (Else-block ((ELSE colon Statements) $3))
             (For-stmt ((FOR ID IN Expression colon Statements)
                        (for-statement (string->symbol $2) $4 $6)))
             (Expression ((Disjunction) (disjunction-exp $1)))
             (Disjunction ((Conjunction) (simple-disjunct $1))
                          ((Disjunction OR Conjunction) (compound-disjunct $1 $3)))
             (Conjunction ((Inversion) (simple-conjunct $1))
                          ((Conjunction AND Inversion) (compound-conjunct $1 $3)))
             (Inversion ((NOT Inversion) (not-inversion $2))
                        ((Comparison) (comparison-inversion $1)))
             (Comparison ((Sum Compare-op-sum-pairs) (compound-comp $1 $2))
                         ((Sum) (simple-comp $1)))
             (Compare-op-sum-pairs ((Compare-op-sum-pair) (list $1))
                                   ((Compare-op-sum-pairs Compare-op-sum-pair)
                                    (append $1 (list $2))))
             (Compare-op-sum-pair ((Eq-sum) $1)
                                  ((Lt-sum) $1)
                                  ((Gt-sum) $1))
             (Eq-sum ((equals Sum) (eq-sum $2)))
             (Lt-sum ((lessthan Sum) (lt-sum $2)))
             (Gt-sum ((greaterthan Sum) (gt-sum $2)))
             (Sum ((Sum plus Term) (addition-sum $1 $3))
                  ((Sum minus Term) (subtraction-sum $1 $3))
                  ((Term) (simple-sum $1)))
             (Term ((Term multiply Factor) (multiplication-factor $1 $3))
                   ((Term divide Factor) (division-factor $1 $3))
                   ((Factor) (simple-term $1)))
             (Factor ((plus Factor) (plus-factor $2))
                     ((minus Factor) (minus-factor $2))
                     ((Power) (simple-factor $1)))
             (Power ((Atom power Factor) (to-power $1 $3))
                    ((Primary) (simple-power $1)))
             (Primary ((Atom) (atom-primary $1))
                      ((Primary opening-bracket Expression closing-bracket)
                       (expression-primary $1 $3))
                      ((Primary opening-paranthesis closing-paranthesis)
                       (empty-primary $1))
                      ((Primary opening-paranthesis Arguments closing-paranthesis)
                       (argument-primary $1 $3)))
             (Arguments ((Expression) (list $1))
                        ((Arguments comma Expression) (append $1 (list $3))))
             (Atom ((ID) (id-atom (string->symbol $1)))
                   ((TRUE) (boolean-atom 'True))
                   ((FALSE) (boolean-atom 'False))
                   ((NONE) (none-atom))
                   ((NUM) (number-atom $1))
                   ((List) (list-atom $1)))
             (Atom-list ((Atom) (list $1))
                        ((Atom-list comma Atom) (append $1 (list $3))))
             (List ((opening-bracket Expressions closing-bracket) $2)
                   ((opening-bracket closing-bracket) (list)))
             (Expressions ((Expressions comma Expression) (append $1 (list $3)))
                          ((Expression) (list $1)))
             (Print-stmt ((print opening-paranthesis Atom-list closing-paranthesis)
                          (print-statement $3)))
             (Printval-stmt ((printval opening-paranthesis Atom-list closing-paranthesis)
                          (printval-statement $3)))
             (Evaluate-stmt
              ((evaluate opening-paranthesis double-quote FILE-ADDRESS double-quote closing-paranthesis)
               (evaluate-statement (substring $4 1 (- (string-length $4) 1)))))
             )))

;test
(define lex-this (lambda (lexer input) (lambda () (lexer input))))
(define parse (lambda (program)
                (let ((my-lexer (lex-this simple-python-lexer program)))
                  (simple-python-parser my-lexer))))
(provide parse)

;(define test-program (open-input-file "./test.plpy"))
;(define test-program (open-input-string "evaluate('./test.plpy');"))
;(define test-lex-output (open-output-file "./testparse.txt" #:exists 'replace))
;(pretty-print (parse test-program) test-lex-output)
;(close-output-port test-lex-output)
