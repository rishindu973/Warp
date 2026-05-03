%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Forward declarations */
void yyerror(const char *msg);
int  yylex(void);
extern int yylineno;

/* Symbol Table Logic */
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

/* Temporary storage for the task currently being parsed */
static char *cur_name      = NULL;
static char *cur_script    = NULL;
static char *cur_schedule  = NULL;
static char *cur_depends   = NULL;
static char *cur_condition = NULL;

static void register_task(void) {
    if (task_count >= MAX_TASKS) {
        fprintf(stderr, "[Error] Too many tasks (max %d)\n", MAX_TASKS);
        exit(1);
    }
    
    tasks[task_count].name        = cur_name;
    tasks[task_count].script      = cur_script;
    tasks[task_count].schedule    = cur_schedule;
    tasks[task_count].depends_on  = cur_depends;
    tasks[task_count].condition   = cur_condition;
    task_count++;

    printf("[Internal] Registered Task: %s\n", cur_name);

    /* Reset all temporary variables for the next task block */
    cur_name = cur_script = cur_schedule = cur_depends = cur_condition = NULL;
}
%}

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

/* Grammar Rules */

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
            cur_name = $2;
            register_task();
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
        { cur_script = $2; }
    ;

/* Detailed scheduling logic */
schedule_stmt
    : TOKEN_EVERY TOKEN_DAY TOKEN_AT TOKEN_TIME
        {
            char buf[64];
            snprintf(buf, sizeof(buf), "EVERY DAY AT %s", $4);
            cur_schedule = strdup(buf);
            free($4);
        }
    | TOKEN_EVERY TOKEN_WEEK TOKEN_ON day TOKEN_AT TOKEN_TIME
        {
            char buf[64];
            snprintf(buf, sizeof(buf), "EVERY WEEK ON <day> AT %s", $6);
            cur_schedule = strdup(buf);
            free($6);
        }
    | TOKEN_AT TOKEN_TIME
        {
            char buf[32];
            snprintf(buf, sizeof(buf), "AT %s", $2);
            cur_schedule = strdup(buf);
            free($2);
        }
    ;

day
    : TOKEN_SUNDAY | TOKEN_MONDAY | TOKEN_TUESDAY | TOKEN_WEDNESDAY
    | TOKEN_THURSDAY | TOKEN_FRIDAY | TOKEN_SATURDAY
    ;

after_stmt
    : TOKEN_AFTER TOKEN_IDENTIFIER
        { cur_depends = $2; }
    ;

condition_stmt
    : TOKEN_IF TOKEN_SUCCESS
        { cur_condition = strdup("success"); }
    | TOKEN_IF TOKEN_FAILURE
        { cur_condition = strdup("failure"); }
    ;

%%

void yyerror(const char *msg) {
    fprintf(stderr, "[Syntax Error] %s near line %d\n", msg, yylineno);
}

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