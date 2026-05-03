#ifndef TOKENS_H
#define TOKENS_H

typedef enum {
    TOKEN_EOF =0,
    TOKEN_TASK,
    TOKEN_RUN,
    TOKEN_EVERY,
    TOKEN_DAY,
    TOKEN_WEEK,
    TOKEN_ON,
    TOKEN_SUNDAY,
    TOKEN_MONDAY,
    TOKEN_TUESDAY,
    TOKEN_WEDNESDAY,
    TOKEN_THURSDAY,
    TOKEN_FRIDAY,
    TOKEN_SATURDAY,
    TOKEN_AT,
    TOKEN_AFTER,
    TOKEN_IF,
    TOKEN_SUCCESS,
    TOKEN_FAILURE,

    /* Identifiers and Literals */
    TOKEN_IDENTIFIER,  
    TOKEN_STRING,      
    TOKEN_TIME,

    /* Structural Symbols */
    TOKEN_LBRACE,     
    TOKEN_RBRACE,
    
    /* Special */
    TOKEN_ERROR
} TokenType;

#endif