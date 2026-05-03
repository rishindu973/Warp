%{
#include "../include/tokens.h"
%}

%%

"TASK"      { return TOKEN_TASK; }
"RUN"       { return TOKEN_RUN; }
"EVERY"     { return TOKEN_EVERY; }
"DAY"       { return TOKEN_DAY; }
"AT"        { return TOKEN_AT; }
"AFTER"     { return TOKEN_AFTER; }
"IF"        { return TOKEN_IF; }
"success"   { return TOKEN_SUCCESS; }

"{"         { return TOKEN_LBRACE; }
"}"         { return TOKEN_RBRACE; }

[ \t\n\r]+  { /* skip whitespace */}
.           { return TOKEN_ERROR; }

%%

int yywrap() {
    return 1;
}