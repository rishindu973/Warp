CC      = gcc
CFLAGS  = -Wall -Wextra -g -I include

BISON   = bison
FLEX    = flex

SRC_DIR = src
OBJ_DIR = obj
BIN     = warp

PARSER_C = $(SRC_DIR)/parser.tab.c
PARSER_H = $(SRC_DIR)/parser.tab.h
LEXER_C  = $(SRC_DIR)/lex.yy.c

.PHONY: all clean test

all: $(BIN)

# Step 1: Generate parser from Bison grammar
$(PARSER_C) $(PARSER_H): $(SRC_DIR)/parser.y
	$(BISON) -d -o $(PARSER_C) $(SRC_DIR)/parser.y

# Step 2: Generate lexer from Flex rules (depends on parser header for token codes)
$(LEXER_C): $(SRC_DIR)/lexer.l $(PARSER_H)
	$(FLEX) --header-file=$(SRC_DIR)/lex.yy.h -o $(LEXER_C) $(SRC_DIR)/lexer.l

# Step 3: Compile and link everything
$(BIN): $(PARSER_C) $(LEXER_C)
	$(CC) $(CFLAGS) -o $@ $(PARSER_C) $(LEXER_C) -lfl

# ── Test targets ──────────────────────────────────────────────────
test: $(BIN)
	@echo "==============================="
	@echo "TEST 1: Simple daily task"
	@echo "==============================="
	@./$(BIN) tests/valid_v1.tp

	@echo ""
	@echo "==============================="
	@echo "TEST 2: Multi-step workflow"
	@echo "==============================="
	@./$(BIN) tests/valid_v2.tp

	@echo ""
	@echo "==============================="
	@echo "TEST 3: Weekly task"
	@echo "==============================="
	@./$(BIN) tests/valid_v3.tp

	@echo ""
	@echo "==============================="
	@echo "TEST 4: Deep dependency chain"
	@echo "==============================="
	@./$(BIN) tests/valid_v4.tp

	@echo ""
	@echo "==============================="
	@echo "TEST 5: Invalid - syntax error"
	@echo "==============================="
	@./$(BIN) tests/invalid_v1.tp || true

	@echo ""
	@echo "==============================="
	@echo "TEST 6: Invalid - missing RUN"
	@echo "==============================="
	@./$(BIN) tests/invalid_v2.tp || true

	@echo ""
	@echo "==============================="
	@echo "TEST 7: Invalid - circular dep"
	@echo "==============================="
	@./$(BIN) tests/invalid_v3.tp || true

	@echo ""
	@echo "==============================="
	@echo "TEST 8: Invalid - unknown dep"
	@echo "==============================="
	@./$(BIN) tests/invalid_v4.tp || true

clean:
	rm -f $(PARSER_C) $(PARSER_H) $(LEXER_C) $(SRC_DIR)/lex.yy.h $(BIN)
