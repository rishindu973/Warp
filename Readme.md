# Warp — TaskLang++ Compiler

A compiler for **TaskLang++**, a domain-specific language for defining, scheduling, and automating tasks. Built with GNU Flex (lexer) and GNU Bison (parser) as part of SE2052 – Programming Paradigms.

---

## What is TaskLang++?

TaskLang++ lets you define automation tasks in plain, readable syntax — no cron expressions, no YAML boilerplate.

```
TASK backupDB {
    RUN "backup.sh"
    EVERY DAY AT 02:00
}

TASK sendReport {
    RUN "report.py"
    AFTER backupDB
    IF success
}
```

The compiler validates your program, checks for unknown dependencies and circular dependency chains, then simulates execution in the correct topological order.

---

## Project Structure

```
Warp/
├── include/
│   └── tokens.h          # Token type enum
├── src/
│   ├── lexer.l           # Flex lexer rules
│   └── parser.y          # Bison grammar + semantic analysis + simulation
├── tests/
│   ├── valid_v1.tp       # Simple daily task
│   ├── valid_v2.tp       # Multi-step workflow with dependency & condition
│   ├── valid_v3.tp       # Weekly task + AT-only schedule
│   ├── valid_v4.tp       # 3-task dependency chain
│   ├── invalid_v1.tp     # Syntax error: missing closing brace
│   ├── invalid_v2.tp     # Syntax error: missing RUN statement
│   ├── invalid_v3.tp     # Semantic error: circular dependency
│   └── invalid_v4.tp     # Semantic error: unknown task in AFTER
├── makefile
└── README.md
```

---

## Language Syntax

### Task definition

```
TASK <name> {
    RUN "<script>"
    [EVERY DAY AT HH:MM]
    [EVERY WEEK ON <day> AT HH:MM]
    [AT HH:MM]
    [AFTER <task_name>]
    [IF success | IF failure]
}
```

### Supported keywords

| Keyword | Purpose |
|---|---|
| `TASK` | Begin a task definition |
| `RUN` | Specify the script or command to execute |
| `EVERY DAY AT` | Daily recurring schedule |
| `EVERY WEEK ON <day> AT` | Weekly recurring schedule |
| `AT` | One-shot time trigger |
| `AFTER` | Declare a dependency on another task |
| `IF success` / `IF failure` | Conditional execution based on dependency outcome |

### Day keywords

`SUNDAY` `MONDAY` `TUESDAY` `WEDNESDAY` `THURSDAY` `FRIDAY` `SATURDAY`

### Comments

Lines beginning with `#` are ignored.

```
# This is a comment
TASK myTask {
    RUN "script.sh"
    EVERY DAY AT 09:00
}
```

---

## Prerequisites

- GCC
- GNU Flex (`flex`)
- GNU Bison (`bison`)

Install on Ubuntu / WSL2:

```bash
sudo apt update && sudo apt install -y gcc flex bison
```

---

## Build

```bash
make
```

This runs Bison first (generates `parser.tab.h`), then Flex (which includes that header), then compiles and links everything into the `warp` binary.

To clean all generated files:

```bash
make clean
```

---

## Usage

```bash
./warp <input_file.tp>
```

**Example:**

```bash
./warp tests/valid_v2.tp
```

**Output:**

```
Parsing TaskLang++ input...

--- EXECUTION START ---

Executing Task: backupDB
  Script: "backup.sh"
  Schedule: EVERY DAY AT 02:00

Executing Task: sendReport
  Script: "report.py"
  Schedule: (none)
  Depends on: backupDB
  Condition: success

Executing Task: cleanup
  Script: "cleanup.sh"
  Schedule: EVERY WEEK ON <day> AT 03:00

--- EXECUTION COMPLETE ---
```

---

## Running Tests

```bash
make test
```

Runs all 8 test cases (4 valid, 4 invalid) and prints results. Invalid programs exit with a descriptive error message.

| Test file | Scenario | Expected |
|---|---|---|
| `valid_v1.tp` | Simple daily task | EXECUTION COMPLETE |
| `valid_v2.tp` | 3-task workflow with dependency + condition | Tasks printed in dependency order |
| `valid_v3.tp` | Weekly task + AT-only schedule | EXECUTION COMPLETE |
| `valid_v4.tp` | 3-task chain: fetch → process → report | Topological output |
| `invalid_v1.tp` | Missing closing brace | Syntax error |
| `invalid_v2.tp` | Task body with no RUN | Syntax error |
| `invalid_v3.tp` | Circular dependency A → B → A | Semantic error: cycle detected |
| `invalid_v4.tp` | AFTER references undefined task | Semantic error: unknown task |

---

## Error Reporting

**Lexer errors** — unrecognised characters are reported with line number:
```
[Lexer Error] Unexpected character: '@' at line 3
```

**Syntax errors** — caught by the parser:
```
[Syntax Error] syntax error near line 5
```

**Semantic errors** — caught after parsing:
```
[Semantic Error] Circular dependency detected involving 'taskA'
[Semantic Error] Task 'sendReport' depends on unknown task 'ghost'
[Semantic Error] Duplicate task name: 'backupDB'
```

---

## How the Compiler Works

```
Source (.tp)
    │
    ▼
[Lexer — lexer.l]
  Tokenises keywords, identifiers, strings, time values
    │
    ▼
[Parser — parser.y]
  Validates grammar, builds symbol table
    │
    ▼
[Semantic Analysis]
  • Resolves AFTER dependencies
  • Detects circular dependency chains (DFS)
  • Checks for duplicate task names
    │
    ▼
[Simulation]
  Executes tasks in topological order, prints schedule
```

---

## Author

Rishindu Weeramanthri (R|ck)
