---
name: plan-exec
description: "Execute plan tasks sequentially with inline execution. Use when user says 'exec', 'execute plan', 'run plan', or wants to implement a plan file task by task."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(bash:*), AskUserQuestion, TaskCreate, TaskUpdate, EnterWorktree
---

# plan-exec

Execute plan file tasks sequentially with inline execution of all implementation, review, and finalization logic.

## Environment-Specific Usage

**In Claude Code:**
- Invoke: `/plan-exec docs/plans/<plan-file>.md`
- Execution: All tasks, reviews, and finalization run inline sequentially

**In OpenCode:**
- Invoke: `claude plan-exec docs/plans/<plan-file>.md` (or through OpenCode CLI)
- Execution: All tasks, reviews, and finalization run inline sequentially

Both environments use identical sequential inline execution (no subagent spawning).

## Arguments

- `$ARGUMENTS` — path to plan file (optional; if omitted, ask user to pick from `docs/plans/` directory)

## File Resolution

ALWAYS use the resolve script to read prompt and agent files. NEVER construct the override chain manually. Make sure `SKILL_DIR` is set first (see "Initialize SKILL_DIR" section):
```bash
bash "$SKILL_DIR/scripts/resolve-file.sh" prompts/task.md
bash "$SKILL_DIR/scripts/resolve-file.sh" agents/quality.txt
```
The script checks project overrides, user overrides, and bundled defaults automatically.

### Placeholder Substitution

When reading prompt files for guidance, replace ALL placeholders with actual values for reference. Prompts serve as guidance for inline execution.

Always substitute: `PLAN_FILE_PATH`, `PROGRESS_FILE_PATH`, `DEFAULT_BRANCH`, `TESTING_ENFORCED` (true/false based on plan), `${SKILL_DIR}` (resolve to actual absolute path), `RESOLVE_SCRIPT` (absolute path to `${SKILL_DIR}/scripts/resolve-file.sh`), and phase-specific values (`FINDINGS_LIST`, `REVIEW_PHASE`, `DIFF_COMMAND`).

## Process

### Step 0: Initialize SKILL_DIR (MUST RUN FIRST)

**BEFORE ANY OTHER STEPS**, execute this initialization command using the Bash tool to set up the SKILL_DIR environment variable. This detects which environment (Claude Code or OpenCode) is running the skill.

**CRITICAL**: If SKILL_DIR cannot be located, the initialization **MUST STOP and report the error to the user**. Do NOT proceed to any subsequent steps.

After running the initialization, **print the result to the user** (show SKILL_DIR value and environment detected) before proceeding to Step 1:

```bash
# Detect which environment is running this skill
# Check for OpenCode-specific environment variables or paths
SKILL_DIR=""
ENV_NAME=""

# Priority 1: Detect OpenCode environment
# OpenCode sets OPENCODE_HOME or paths in ~/.config/opencode/
if [ -f "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
    if [ -n "$SKILL_DIR" ]; then
        ENV_NAME="OpenCode"
    fi
fi

# Priority 2: Try Claude Code location if OpenCode not found
if [ -z "$SKILL_DIR" ] && [ -f "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
    if [ -n "$SKILL_DIR" ]; then
        ENV_NAME="Claude Code"
    fi
fi

# Priority 3: Fallback search
if [ -z "$SKILL_DIR" ]; then
    SKILL_DIR=$(find "$HOME/.claude/skills" "$HOME/.config/opencode/skills" -maxdepth 1 -name "plan-exec" -type d 2>/dev/null | head -1)
    if [ -n "$SKILL_DIR" ]; then
        if [[ "$SKILL_DIR" == *"opencode"* ]]; then
            ENV_NAME="OpenCode (fallback)"
        else
            ENV_NAME="Claude Code (fallback)"
        fi
    fi
fi

# Priority 4: Direct invocation fallback
if [ -z "$SKILL_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd 2>/dev/null)"
    if [ -f "$SCRIPT_DIR/SKILL.md" ]; then
        SKILL_DIR="$SCRIPT_DIR"
        ENV_NAME="Direct invocation"
    fi
fi

if [ -z "$SKILL_DIR" ]; then
    echo ""
    echo "ERROR: Cannot locate plan-exec skill directory"
    echo "PROCESS STOPPED - Cannot continue without SKILL_DIR"
    echo ""
    echo "Possible causes:"
    echo "  - Skills not installed (run: ./install.sh)"
    echo "  - Installation is corrupted"
    echo "  - Neither ~/.claude/skills nor ~/.config/opencode/skills found"
    echo ""
    exit 1
fi

# Print result to user BEFORE proceeding to next step
echo ""
echo "✓ SKILL_DIR initialization successful"
echo "  Environment: $ENV_NAME"
echo "  Path: $SKILL_DIR"
echo ""
export SKILL_DIR
```

After running this, SKILL_DIR will be set and available for all subsequent commands.

---

### Script Invocation Pattern

**CRITICAL**: Every bash script invocation in this skill MUST include inline SKILL_DIR initialization. Environment variables do not persist between separate bash tool calls.

Use this pattern for ANY script invocation:

```bash
# Initialize SKILL_DIR (inline) - required before each script call
SKILL_DIR=""
if [ -f "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
fi
if [ -z "$SKILL_DIR" ] && [ -f "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
fi
if [ -z "$SKILL_DIR" ]; then
    SKILL_DIR=$(find "$HOME/.claude/skills" "$HOME/.config/opencode/skills" -maxdepth 1 -name "plan-exec" -type d 2>/dev/null | head -1)
fi

# Then invoke your script
bash "$SKILL_DIR/scripts/SCRIPT_NAME" arguments...
```

### How SKILL_DIR Detection Works

The initialization prioritizes OpenCode (since many users run only OpenCode) and falls back to Claude Code:

1. **OpenCode first**: Checks if `~/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh` exists and uses it
2. **Claude Code second**: Checks if `~/.claude/skills/plan-exec/scripts/get-skill-dir.sh` exists and uses it
3. **Find fallback**: Searches for plan-exec in standard installation directories
4. **Direct invocation**: If SKILL.md exists in current directory, uses that as the skill root

### Step 1. Resolve plan file

If `$ARGUMENTS` contains a file path, use it. Otherwise, list `.md` files in `docs/plans/`, excluding `completed/`. If exactly one plan found, use it automatically. If multiple found, ask the user to pick one using AskUserQuestion.

Read the plan file. Count total Task sections (`### Task N:` or `### Iteration N:`) to know the scope.

**Extract testing approach** from the plan's "Development Approach" section:
- Look for `testing approach:` line containing one of:
  - `TDD` or `Test-Driven Development` → `TESTING_ENFORCED=true`
  - `Regular` or `Code-first` → `TESTING_ENFORCED=true`
  - `No tests` or `None` → `TESTING_ENFORCED=false`
- If testing approach is not found in the plan, default to `TESTING_ENFORCED=true` (conservative - require tests)
- Store this value for use during task execution to enforce testing requirements

**Determine the default branch** using this command (includes inline SKILL_DIR initialization):
```bash
# Initialize SKILL_DIR (inline)
SKILL_DIR=""
if [ -f "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
fi
if [ -z "$SKILL_DIR" ] && [ -f "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
fi
if [ -z "$SKILL_DIR" ]; then
    SKILL_DIR=$(find "$HOME/.claude/skills" "$HOME/.config/opencode/skills" -maxdepth 1 -name "plan-exec" -type d 2>/dev/null | head -1)
fi

# Now detect branch
bash "$SKILL_DIR/scripts/detect-branch.sh"
```

### Step 2. Ask about worktree isolation

Ask the user whether to run in an isolated git worktree or in the current working directory using AskUserQuestion:

- **Worktree** — creates an isolated copy of the repo, all work happens there. Clean separation from the main working directory. Best for long-running plans where you want to keep working in the main repo.
- **Current directory** — works directly in the current repo. Simpler, but blocks the working directory during execution.

If user chooses "Worktree", use `EnterWorktree` tool to create an isolated worktree before proceeding. All subsequent steps (branch creation, task execution, reviews, finalize) happen inside the worktree. At completion, report the worktree path and branch so the user can review and merge.

If user chooses "Current directory", proceed normally without worktree.

### Step 3. Create task list

ALWAYS create proper tasks using TaskCreate before starting any work. This prevents OpenCode from trying to interpret markdown task lists with todowrite (which causes the error you may have seen).

**Do this immediately after choosing worktree mode:**

1. **Read the plan file** and extract each `### Task N:` section
2. **For each task section**, call TaskCreate with:
   - `subject`: "Task N: [exact title from plan]"
   - `description`: "[list of all checkbox items in that task]"
   - `activeForm`: "Executing task N..."

   Example:
   ```
   TaskCreate(
     subject="Task 1: Add password hashing utility",
     description="- create `src/auth/hash` with HashPassword and VerifyPassword functions\n- implement bcrypt-based hashing with configurable cost\n- write tests for HashPassword (success + error cases)\n- write tests for VerifyPassword (success + error cases)\n- run tests - must pass before task 2",
     activeForm="Executing task 1..."
   )
   ```

3. **Store the task IDs** returned by TaskCreate so you can update them as you progress

4. **Add review phase tasks** (these run after all plan tasks are done):
   ```
   TaskCreate(subject="Review phase 1: comprehensive", description="Review implementation completeness", activeForm="Running review phase 1...")
   TaskCreate(subject="Review phase 2: code smells", description="Check for design issues", activeForm="Running review phase 2...")
   TaskCreate(subject="Review phase 3: critical only", description="Final critical review", activeForm="Running review phase 3...")
   TaskCreate(subject="Finalize", description="Rebase, clean up commits, verify test suite", activeForm="Finalizing...")
   ```

5. **Update tasks as you progress**:
   - `TaskUpdate(taskId, status="in_progress")` when starting a task
   - `TaskUpdate(taskId, status="completed")` when task succeeds
   - Store task IDs for later updates

**CRITICAL FOR OPENCODE**: Explicitly calling TaskCreate with proper structure prevents OpenCode from auto-invoking todowrite. Without these explicit calls, OpenCode sees markdown task lists and tries to interpret them as todos, causing the "status undefined" error you may have encountered.

### Step 4. Create branch

**MANDATORY**: Run the script below (includes inline SKILL_DIR initialization). Do NOT create the branch manually — the script strips the date prefix from the plan filename (e.g., `20260329-feature-name.md` → branch `feature-name`).

```bash
# Initialize SKILL_DIR (inline)
SKILL_DIR=""
if [ -f "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
fi
if [ -z "$SKILL_DIR" ] && [ -f "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
fi
if [ -z "$SKILL_DIR" ]; then
    SKILL_DIR=$(find "$HOME/.claude/skills" "$HOME/.config/opencode/skills" -maxdepth 1 -name "plan-exec" -type d 2>/dev/null | head -1)
fi

# Create branch (replace <plan-file-path> with actual path)
bash "$SKILL_DIR/scripts/create-branch.sh" <plan-file-path>
```

The script creates a feature branch if currently on main/master, or stays on the current branch if already on a feature branch. Capture and use the branch name it outputs.

### Step 5. Initialize progress file

Initialize the progress file using this command (includes inline SKILL_DIR initialization):

```bash
# Initialize SKILL_DIR (inline)
SKILL_DIR=""
if [ -f "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
fi
if [ -z "$SKILL_DIR" ] && [ -f "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
fi
if [ -z "$SKILL_DIR" ]; then
    SKILL_DIR=$(find "$HOME/.claude/skills" "$HOME/.config/opencode/skills" -maxdepth 1 -name "plan-exec" -type d 2>/dev/null | head -1)
fi

# Initialize progress file (replace <plan-name>, <plan-file-path>, <branch-name> with actual values)
bash "$SKILL_DIR/scripts/init-progress.sh" /tmp/progress-<plan-name>.txt <plan-file-path> <branch-name>
```

Derive `<plan-name>` from the plan file stem (e.g., `fix-issues.md` → `progress-fix-issues`). The script creates the file with a header. Report the full progress file path to the user.

**IMPORTANT**: Always use the inline SKILL_DIR initialization before calling `bash "$SKILL_DIR/scripts/append-progress.sh"` to write to the progress file. Never write directly.

### Step 6. Task loop (Sequential Inline Execution)

Repeat until no `[ ]` checkboxes remain in any Task section:

1. **Re-read the plan file** to check current state
2. **Find the first Task section** (`### Task N:` or `### Iteration N:`) that still has `[ ]` checkboxes
3. **If none found** — all tasks complete, go to step 7
4. **Announce the task to the user** — output a brief text summary (NOT markdown task list):
   - Task number and title
   - Brief summary of what needs to be done
   - Example output (text only, not checkboxes):
     ```
     Starting Task 1: Fix error handling
     This task involves: handling os.ReadFile errors, logging/exiting appropriately
     ```
   - **IMPORTANT**: Do NOT output markdown task lists with `- [ ]` syntax here, as OpenCode may try to interpret them as todos and call todowrite. The actual task tracking happens via the TaskCreate calls from Step 3.
5. **Execute task inline** (no subagent spawning):
   - Resolve `prompts/task.md` from override chain (use `bash "$SKILL_DIR/scripts/resolve-file.sh" prompts/task.md`)
   - Read the task prompt for guidance
   - Extract task implementation details from plan file
   - Use standard tools to implement the task:
     - `Read` — read code files
     - `Write`/`Edit` — modify/create files
     - `Bash` — run commands, tests
     - `Glob`/`Grep` — search code
   - Follow ALL placeholder substitutions from the resolved prompt:
     - `PLAN_FILE_PATH` → actual path
     - `PROGRESS_FILE_PATH` → actual path
     - `TESTING_ENFORCED` → "true" or "false"
     - `DEFAULT_BRANCH` → detected branch
     - `${SKILL_DIR}` → absolute path
   - Write/update tests as required by plan
   - Run tests via bash: `bash test_command`
   - Commit changes via bash
   - Log progress: `bash "$SKILL_DIR/scripts/append-progress.sh" <progress-file> "Task N completed"`

6. **After task execution**, re-read the plan file and check if that task's checkboxes are now `[x]`
   - If yes — task succeeded, continue loop
   - If no — **automatically attempt to fix and continue** (no user confirmation needed):
     - Check for errors/failures from previous attempt
     - Fix issues directly using same tools
     - Run tests again to verify fixes
     - If issue persists after `task_retries` attempts (default: 1):
       - Mark task as failed with error details
       - Move to next task automatically (do NOT stop the loop)
       - Log failure and continue with next incomplete task

7. **Automatic continuation**: After each task (success or failure), automatically:
   - Continue to the next incomplete task in the loop
   - Do NOT wait for user confirmation
   - Do NOT ask "should I continue?" — just continue
   - Report task status to user and move forward

8. **Report to user**: Brief status line per task (e.g., "Task N completed" or "Task N: attempted 2x, issues remain, moving to Task N+1")

**CRITICAL**: Do NOT stop the loop based on completion text or to ask for confirmation. The ONLY stop condition is: no `[ ]` checkboxes remain in any Task section. Always re-read the plan file to verify.

**CRITICAL**: All implementation work happens inline in this step using standard tools (Read, Write, Edit, Bash, Glob, Grep). No subagent spawning.

**CRITICAL**: Automatic task continuation in OpenCode — do NOT pause between tasks waiting for user input. Process all tasks sequentially without interruption.

Maximum iterations safety limit: 50 total iterations across all tasks. If reached, stop and report to user.

### Step 7. Review phase 1 — comprehensive (Sequential Inline Execution)

After all tasks complete, run a comprehensive code review.

Report to user: "--- Review phase 1: comprehensive ---"

Loop up to `review_iterations` times (default: 5):

1. **Execute review inline** (no subagent spawning):
   - Resolve `prompts/review.md` from override chain (use resolve-file.sh)
   - Read the review prompt for guidance
   - Execute review analysis for each review type:
     - Resolve `agents/quality.txt` — analyze for bugs, security, quality issues
     - Resolve `agents/implementation.txt` — analyze for requirement coverage
     - Resolve `agents/testing.txt` — analyze for test coverage gaps
     - Resolve `agents/simplification.txt` — detect over-engineering
     - Resolve `agents/documentation.txt` — find missing docs
   - Collect ALL findings from each review type with file:line references
   - Deduplicate findings (same file:line + same issue = merge)
   - Report findings to user with compact list

2. **If no findings found** → report "Review phase 1: clean" and proceed to step 8

3. **Execute fixer inline** (no subagent spawning):
   - Resolve `prompts/fixer.md` from override chain
   - Read the fixer prompt for guidance
   - Analyze ALL collected findings (do NOT filter or summarize)
   - For each finding:
     - Verify it's real (not false positive)
     - If confirmed, fix it directly using standard tools (Read, Write, Edit, Bash)
     - If not confirmed, skip it
   - Run tests to verify fixes don't break anything
   - Commit fixes
   - Log iteration results to progress file

4. **Loop** — re-run review analysis and repeat until no findings or max iterations reached

If `review_iterations` reached with issues still found, report "Review phase 1: max iterations reached, moving on" and continue.

### Step 8. Review phase 2 — code smells (Sequential Inline Execution)

Report to user: "--- Review phase 2: code smells analysis ---"

Run once (no loop):

1. **Execute smells analysis inline**:
   - Resolve `agents/smells.txt` from override chain
   - Read the agent prompt for guidance
   - Analyze code for smells (duplication, complexity, anti-patterns, etc.)
   - Collect smells findings with file:line references
   - Report findings to user

2. **If no findings** → report "Smells analysis: clean" and proceed to step 9

3. **Execute fixer inline**:
   - Resolve `prompts/fixer.md` from override chain
   - Analyze ALL collected smells findings
   - For each finding:
     - Verify it's real
     - If confirmed, fix using standard tools
     - If not, skip
   - Run tests to verify fixes
   - Commit fixes
   - Report to user and proceed to next phase

### Step 9. Review phase 3 — critical only (Sequential Inline Execution)

Report to user: "--- Review phase 3: critical/major only (single pass) ---"

Run once with focus on critical/major issues only:

1. **Execute critical review inline**:
   - Resolve `prompts/review.md` from override chain (with `REVIEW_PHASE=critical`)
   - Resolve `agents/quality.txt` and `agents/implementation.txt` only (focus on critical issues)
   - Analyze code with critical/major issue filter
   - Collect critical findings
   - Report to user

2. **If no critical findings** → report "Phase 3: clean" and proceed to step 10

3. **Execute fixer inline**:
   - Resolve `prompts/fixer.md` from override chain
   - Analyze ALL collected critical findings
   - For each finding:
     - Verify it's real and critical
     - If confirmed, fix using standard tools
     - If not, skip
   - Run tests to verify fixes
   - Commit fixes
   - Report to user and proceed to next phase

### Step 10. Finalize (Sequential Inline Execution)

Check `finalize_enabled` (default: true). If false, skip this step.

After all reviews pass, rebase and clean up commits.

Report to user: "--- Finalize: rebase and clean up commits ---"

Execute finalization inline:
1. Resolve `prompts/finalizer.md` from override chain for guidance
2. Fetch latest from `DEFAULT_BRANCH`
3. Rebase current branch onto `DEFAULT_BRANCH` using bash: `git rebase <DEFAULT_BRANCH>`
4. Squash related commits for cleaner history using bash: `git rebase -i <DEFAULT_BRANCH>` or auto-squash
5. Run final validation tests using bash
6. Verify all tests pass
7. Log completion to progress file

This is best-effort — if rebase fails, report the issue but don't block completion.

### Step 11. Completion

When finalize is done (or skipped on failure):
- Log completion to progress file: `bash "$SKILL_DIR/scripts/append-progress.sh" <progress-file> "completed"`
- Report summary: "All N tasks completed, reviews passed, branch finalized"
- Do NOT move the plan file or push — just report completion

## Key rules

- **Testing enforcement**: Detect testing approach from plan file (Step 1):
  - If `TESTING_ENFORCED=true`: MUST write tests for every task and ensure all tests pass before marking task done
  - If `TESTING_ENFORCED=false`: may skip tests (but should still write them for non-trivial code)
- Plan file is the single source of truth for progress — always re-read it after each task
- No signals — just checkboxes in the plan for task progress
- Maintain progress file (`/tmp/progress-<plan-name>.txt`) — see `prompts/progress-file.md` for format and when to write
- **Modify the plan file** by updating checkboxes as tasks complete (mark `[ ]` → `[x]`)
- **Implement code directly** using standard tools (Read, Write, Edit, Bash, etc.) during task execution
- **Fix issues directly** when they arise during task execution — do not retry without investigation
- NEVER dismiss findings as "pre-existing", "not from changes", or "architectural" — ALL findings are actionable
- NEVER summarize or filter review findings — pass the full output to fixer for analysis
- All prompt and agent files MUST be resolved through the three-layer override chain before use
- After reading a prompt file, substitute all placeholders for reference during inline execution (see Placeholder Substitution)
