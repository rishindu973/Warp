%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/* Forward declarations for Bison */
void yyerror(const char *msg);
int  yylex(void);
extern int yylineno;

/* Symbol Table */
#define MAX_TASKS 64

typedef struct Task {
    char *name;
    char *script;
    char *schedule;
    char *depends_on;
    char *condition;
} Task;

static Task tasks[MAX_TASKS];
static int  task_count = 0;

/* Working storage for the task currently being parsed */
static char *cur_name     = NULL;
static char *cur_script   = NULL;

static void register_task(void) {
    if (task_count >= MAX_TASKS) {
        fprintf(stderr, "[Error] Too many tasks (max %d)\n", MAX_TASKS);
        exit(1);
    }
    
    tasks[task_count].name   = cur_name;
    tasks[task_count].script = cur_script;
    task_count++;

    printf("[Internal] Registered Task: %s\n", cur_name);

    /* Reset temporary storage for the next task */
    cur_name   = NULL;
    cur_script = NULL;
}
%}

/* Token Value Union */
%union {
    char *strval;
}

/* Token Declarations */
%token TOKEN_TASK TOKEN_RUN TOKEN_EVERY TOKEN_DAY
%token TOKEN_WEEK TOKEN_ON
%token TOKEN_SUNDAY TOKEN_MONDAY TOKEN_TUESDAY TOKEN_WEDNESDAY
%token TOKEN_THURSDAY TOKEN_FRIDAY TOKEN_SATURDAY
%token TOKEN_AT TOKEN_AFTER TOKEN_IF TOKEN_SUCCESS TOKEN_FAILURE
%token TOKEN_LBRACE TOKEN_RBRACE TOKEN_ERROR
%token <strval> TOKEN_IDENTIFIER TOKEN_STRING TOKEN_TIME

%%

/* Grammar Rules*/

program
    : task_list
        { printf("\nParsing Complete. Total tasks found: %d\n", task_count); }
    ;

task_list
    : task_list task
    | task
    ;

task
    : TOKEN_TASK TOKEN_IDENTIFIER TOKEN_LBRACE body TOKEN_RBRACE
        {
            cur_name = $2;     /* Capture the task name from $2 (TOKEN_IDENTIFIER) */
            register_task();    /* Save to symbol table */
        }
    ;

body
    : body statement
    | statement
    ;

statement
    : run_stmt
    | schedule_stmt
    | after_stmt
    | condition_stmt
    ;

run_stmt
    : TOKEN_RUN TOKEN_STRING
        { cur_script = $2; }    /* Capture the script command from $2 (TOKEN_STRING) */
    ;

/* Placeholders for schedules, dependencies, and conditions */
schedule_stmt  : TOKEN_AT TOKEN_TIME ;
after_stmt     : TOKEN_AFTER TOKEN_IDENTIFIER ;
condition_stmt : TOKEN_IF TOKEN_SUCCESS ;

%%

/*Error Handle*/
void yyerror(const char *msg) {
    fprintf(stderr, "[Syntax Error] %s near line %d\n", msg, yylineno);
}

/* Main Entry Point */
int main(int argc, char *argv[]) {
    extern FILE *yyin;
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
        if (!yyin) {
            perror("Could not open input file");
            return 1;
        }
    }

    printf("Starting Warp Compiler Validator...\n");
    int result = yyparse();
    
    if (argc > 1) fclose(yyin);
    return result;
}