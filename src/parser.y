%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../include/tokens.h"

/* Forward declarations for Bison */
void yyerror(const char *msg);
int  yylex(void);
extern int yylineno;
%}

/* Token Value Union */
/* define what types of data tokens carry */
%union {
    char *strval;
}

/* Token Declarations */
/* tell Bison about every token from tokens.h */
%token TOKEN_TASK TOKEN_RUN TOKEN_EVERY TOKEN_DAY
%token TOKEN_WEEK TOKEN_ON
%token TOKEN_SUNDAY TOKEN_MONDAY TOKEN_TUESDAY TOKEN_WEDNESDAY
%token TOKEN_THURSDAY TOKEN_FRIDAY TOKEN_SATURDAY
%token TOKEN_AT TOKEN_AFTER TOKEN_IF TOKEN_SUCCESS TOKEN_FAILURE
%token TOKEN_LBRACE TOKEN_RBRACE TOKEN_ERROR

/* These tokens carry a string value (passed from the lexer via yylval) */
%token <strval> TOKEN_IDENTIFIER TOKEN_STRING TOKEN_TIME

%%

/* Grammar Rules */

/* A program is simply a list of one or more tasks */
program
    : task_list
    ;

/* Recursive logic: a task_list is either one task, or a list followed by another task */
task_list
    : task_list task
    | task
    ;

/* A task starts with 'TASK', a name, then a body inside braces */
task
    : TOKEN_TASK TOKEN_IDENTIFIER TOKEN_LBRACE body TOKEN_RBRACE
    ;

/* A body consists of one or more statements */
body
    : body statement
    | statement
    ;

/* Statements are the specific commands allowed inside a task */
statement
    : run_stmt
    | schedule_stmt
    | after_stmt
    | condition_stmt
    ;

run_stmt       : TOKEN_RUN TOKEN_STRING ;
schedule_stmt  : TOKEN_AT TOKEN_TIME ;
after_stmt     : TOKEN_AFTER TOKEN_IDENTIFIER ;
condition_stmt : TOKEN_IF TOKEN_SUCCESS ;

%%

/* Error Handle */
void yyerror(const char *msg) {
    fprintf(stderr, "[Syntax Error] %s at line %d\n", msg, yylineno);
}