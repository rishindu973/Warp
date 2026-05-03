%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Forward declarations for Bison and Flex integration */
void yyerror(const char *msg);
int  yylex(void);
extern int yylineno;

/* Symbol Table & Task Storage */
#define MAX_TASKS 64

typedef struct Task {
    char *name;
    char *script;
    char *schedule;
    char *depends_on;
    char *condition;
    int   visited;  /* Used for cycle detection and topo-sort */
    int   in_stack; /* Used for circular dependency checks */
} Task;

static Task tasks[MAX_TASKS];
static int  task_count = 0;

/* Global temporary storage for the task currently being parsed */
static char *cur_name = NULL, *cur_script = NULL, *cur_schedule = NULL, *cur_depends = NULL, *cur_condition = NULL;

/* Symbol Table Helpers */
static int find_task(const char *name) {
    for (int i = 0; i < task_count; i++)
        if (strcmp(tasks[i].name, name) == 0) return i;
    return -1;
}

static void register_task(void) {
    if (task_count >= MAX_TASKS) { 
        fprintf(stderr, "[Error] Task limit reached.\n");
        exit(1); 
    }
    tasks[task_count].name = cur_name;
    tasks[task_count].script = cur_script;
    tasks[task_count].schedule = cur_schedule;
    tasks[task_count].depends_on = cur_depends;
    tasks[task_count].condition = cur_condition;
    tasks[task_count].visited = 0;
    tasks[task_count].in_stack = 0;
    task_count++;
    
    /* Reset state for the next task block */
    cur_name = cur_script = cur_schedule = cur_depends = cur_condition = NULL;
}

/* Simulation Engine */
static int exec_order[MAX_TASKS];
static int exec_count = 0;

/* Topological Sort: Ensures parents run before children */
static void topo_visit(int i) {
    if (tasks[i].visited) return;
    tasks[i].visited = 1;

    if (tasks[i].depends_on) {
        int j = find_task(tasks[i].depends_on);
        if (j != -1) topo_visit(j);
    }
    exec_order[exec_count++] = i;
}

static void simulate(void) {
    printf("\n--- EXECUTION SIMULATION START ---\n");
    
    /* Reset visited flags for sorting after they were used in semantic checks */
    for (int i = 0; i < task_count; i++) tasks[i].visited = 0;
    for (int i = 0; i < task_count; i++) topo_visit(i);

    for (int k = 0; k < exec_count; k++) {
        int i = exec_order[k];
        printf("\nExecuting Task: %s\n", tasks[i].name);
        if (tasks[i].script)   printf("  Script: \"%s\"\n", tasks[i].script);
        if (tasks[i].schedule) printf("  Schedule: %s\n", tasks[i].schedule);
        if (tasks[i].depends_on) printf("  Depends on: %s\n", tasks[i].depends_on);
        if (tasks[i].condition) printf("  Condition: %s\n", tasks[i].condition);
    }

    printf("\n--- EXECUTION COMPLETE ---\n");
}

/* Semantic Logic */
static int detect_cycle(int i) {
    if (tasks[i].in_stack) return 1; /* Back-edge found */
    if (tasks[i].visited)  return 0; 

    tasks[i].visited  = 1;
    tasks[i].in_stack = 1;

    if (tasks[i].depends_on) {
        int j = find_task(tasks[i].depends_on);
        if (j == -1) {
            fprintf(stderr, "[Semantic Error] Task '%s' depends on unknown task '%s'\n", tasks[i].name, tasks[i].depends_on);
            exit(1);
        }
        if (detect_cycle(j)) return 1;
    }

    tasks[i].in_stack = 0; 
    return 0;
}

static void run_semantic_checks(void) {
    printf("Running Semantic Analysis...\n");
    for (int i = 0; i < task_count; i++) {
        if (detect_cycle(i)) {
            fprintf(stderr, "[Semantic Error] Circular dependency involving '%s'!\n", tasks[i].name);
            exit(1);
        }
    }
    printf("Semantic Analysis passed. No cycles detected.\n");
    
    /* Now that logic is safe, run the simulation */
    simulate();
}
%}

%union {
    char *strval;
}

/* Token Declarations from tokens.h / Bison */
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
        { run_semantic_checks(); }
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

/* Error Handle*/
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

    printf("Starting Warp Compiler v1.0...\n");
    int result = yyparse();
    
    if (argc > 1) fclose(yyin);
    return result;
}