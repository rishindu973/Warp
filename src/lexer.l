%{
#include <stdio.h>
#include <string.h>
#include "parser.tab.h"
%}

%option noyywrap
%option yylineno
%option noinput
%option nounput

%%

"TASK"          { return TOKEN_TASK; }
"RUN"           { return TOKEN_RUN; }
"EVERY"         { return TOKEN_EVERY; }
"DAY"           { return TOKEN_DAY; }
"WEEK"          { return TOKEN_WEEK; }
"ON"            { return TOKEN_ON; }
"SUNDAY"        { return TOKEN_SUNDAY; }
"MONDAY"        { return TOKEN_MONDAY; }
"TUESDAY"       { return TOKEN_TUESDAY; }
"WEDNESDAY"     { return TOKEN_WEDNESDAY; }
"THURSDAY"      { return TOKEN_THURSDAY; }
"FRIDAY"        { return TOKEN_FRIDAY; }
"SATURDAY"      { return TOKEN_SATURDAY; }
"AT"            { return TOKEN_AT; }
"AFTER"         { return TOKEN_AFTER; }
"IF"            { return TOKEN_IF; }
"success"       { return TOKEN_SUCCESS; }
"failure"       { return TOKEN_FAILURE; }

"{"             { return TOKEN_LBRACE; }
"}"             { return TOKEN_RBRACE; }

[0-9]{2}:[0-9]{2}  {
    yylval.strval = strdup(yytext);
    return TOKEN_TIME;
}
\"[^\"]*\"  {
    /* Strip the surrounding quotes for the parser */
    yylval.strval = strndup(yytext + 1, strlen(yytext) - 2);
    return TOKEN_STRING;
}

[a-zA-Z_][a-zA-Z0-9_]* {
    yylval.strval = strdup(yytext);
    return TOKEN_IDENTIFIER;
}

[ \t\n\r]+      { /* skip whitespace */ }

"#"[^\n]*       { /* skip line comments */ }

.               {
    fprintf(stderr, "[Lexer Error] Unexpected character: '%s'\n", yytext);
    return TOKEN_ERROR;
}

%%