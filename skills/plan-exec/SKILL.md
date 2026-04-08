---
name: plan-exec
description: "Execute plan tasks sequentially using subagents. Use when user says 'exec', 'execute plan', 'run plan', or wants to implement a plan file task by task with isolated subagents."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(bash:*), Agent, AskUserQuestion, TaskCreate, TaskUpdate, EnterWorktree
---

# plan-exec

Execute plan file tasks sequentially, each in an isolated subagent.

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

After reading a prompt file, replace ALL placeholders with actual values before passing to a subagent. Subagents run in fresh contexts without plugin env vars.

Always substitute: `PLAN_FILE_PATH`, `PROGRESS_FILE_PATH`, `DEFAULT_BRANCH`, `TESTING_ENFORCED` (true/false based on plan), `${SKILL_DIR}` (resolve to actual absolute path), `RESOLVE_SCRIPT` (absolute path to `${SKILL_DIR}/scripts/resolve-file.sh`), and phase-specific values (`FINDINGS_LIST`, `REVIEW_PHASE`, `DIFF_COMMAND`).

## Process

### Step 0: Initialize SKILL_DIR (MUST RUN FIRST)

**BEFORE ANY OTHER STEPS**, execute this initialization command using the Bash tool to set up the SKILL_DIR environment variable. This detects which environment (Claude Code or OpenCode) is running the skill:

```bash
# Detect which environment is running this skill
# Check for OpenCode-specific environment variables or paths
SKILL_DIR=""

# Priority 1: Detect OpenCode environment
# OpenCode sets OPENCODE_HOME or paths in ~/.config/opencode/
if [ -f "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.config/opencode/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
fi

# Priority 2: Try Claude Code location if OpenCode not found
if [ -z "$SKILL_DIR" ] && [ -f "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" ]; then
    SKILL_DIR=$(bash "$HOME/.claude/skills/plan-exec/scripts/get-skill-dir.sh" 2>/dev/null)
fi

# Priority 3: Fallback search
if [ -z "$SKILL_DIR" ]; then
    SKILL_DIR=$(find "$HOME/.claude/skills" "$HOME/.config/opencode/skills" -maxdepth 1 -name "plan-exec" -type d 2>/dev/null | head -1)
fi

# Priority 4: Direct invocation fallback
if [ -z "$SKILL_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd 2>/dev/null)"
    if [ -f "$SCRIPT_DIR/SKILL.md" ]; then
        SKILL_DIR="$SCRIPT_DIR"
    fi
fi

if [ -z "$SKILL_DIR" ]; then
    echo "error: cannot locate plan-exec skill directory" >&2
    echo "hint: install with: ./install.sh" >&2
    exit 1
fi

echo "SKILL_DIR=$SKILL_DIR"
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
- Store this value to pass to task subagents

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

ALWAYS create tasks using TaskCreate before starting any work. Create one task per plan Task section plus review phases:

For each `### Task N:` section in the plan:
- `TaskCreate(subject="Task N: <title>", description="<checkbox items>", activeForm="Executing task N...")`

Then add review tasks:
- `TaskCreate(subject="Review phase 1: comprehensive", description="5 parallel review agents + fixer", activeForm="Running review phase 1...")`
- `TaskCreate(subject="Review phase 2: code smells", description="smells agent + fixer", activeForm="Running smells review...")`
- `TaskCreate(subject="Review phase 3: critical only", description="2 review agents + fixer", activeForm="Running review phase 3...")`
- `TaskCreate(subject="Finalize", description="rebase, clean up commits, verify", activeForm="Finalizing...")`

Update tasks as you go: `TaskUpdate(taskId, status="in_progress")` when starting, `TaskUpdate(taskId, status="completed")` when done.

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

### Step 6. Task loop

Repeat until no `[ ]` checkboxes remain in any Task section:

1. **Re-read the plan file** (subagent modifies it each iteration)
2. **Find the first Task section** (`### Task N:` or `### Iteration N:`) that still has `[ ]` checkboxes
3. **If none found** — all tasks complete, go to step 7
4. **Announce the task to the user** — before spawning the subagent, output a visible summary:
   - Task number and title (from the `### Task N:` header)
   - List all `[ ]` checkbox items in that task section
   - Example output:
     ```
     --- Task 1: Fix error handling ---
     - [ ] Handle the error from os.ReadFile
     - [ ] Either log and exit or handle gracefully
     ```
5. **Spawn a subagent** using Agent tool with:
   - `mode: "bypassPermissions"`
   - `subagent_type: "general-purpose"`
   - The task prompt from `prompts/task.md`, with ALL placeholders replaced:
     - `PLAN_FILE_PATH` → actual path
     - `PROGRESS_FILE_PATH` → actual path
     - `TESTING_ENFORCED` → "true" if tests are required, "false" if optional
     - `DEFAULT_BRANCH` → the detected default branch
     - `SKILL_DIR` → absolute path to skill directory
6. **After subagent returns**, re-read the plan file and check if that task's checkboxes are now `[x]`
   - If yes — task succeeded, continue loop
   - If no — **retry** with a fresh subagent for the same task up to `task_retries` times (default: 1). If all retries fail, stop and report failure to user
7. **Report to user**: "Task N completed" (one line). The task subagent logs details to the progress file.

CRITICAL: Do NOT stop the loop based on subagent return text. The ONLY condition to stop is: no `[ ]` checkboxes remain in any Task section (`### Task N:` or `### Iteration N:`). Always re-read the plan file to check.

CRITICAL: You are the ORCHESTRATOR. Never read code, debug errors, investigate diagnostics, or fix issues yourself. If a subagent leaves problems (compiler errors, test failures, lint issues), retry with a fresh subagent — pass the error details in the prompt so it can fix them. All code work happens inside subagents, not in the orchestrator.

Maximum iterations safety limit: 50. If reached, stop and report to user.

### Step 7. Review phase 1 — comprehensive

After all tasks complete, run a comprehensive code review.

Report to user: "--- Review phase 1: comprehensive ---"

Loop up to `review_iterations` times (default: 5):

1. **Spawn a review agent** — resolve `prompts/review.md` through the override chain. Launch one Agent tool call with `mode: "bypassPermissions"`, `subagent_type: "general-purpose"`, and the resolved prompt with `REVIEW_PHASE` set to `comprehensive`. Replace `DEFAULT_BRANCH`, `PLAN_FILE_PATH`, `PROGRESS_FILE_PATH`, and `${SKILL_DIR}`. The review agent launches 5 agents in parallel, collects findings, and reports back.

2. **Collect findings** — pass the review agent's COMPLETE output (not a summary) to the fixer. Do NOT summarize, filter, or dismiss any findings. ALL findings are actionable. Report to user with a short list of findings. Log to progress file:
   `bash "$SKILL_DIR/scripts/append-progress.sh" <progress-file> "review phase 1: findings"`
   Then pipe: `echo "<findings>" | bash "$SKILL_DIR/scripts/append-progress.sh" <progress-file>`

3. **If ALL agents reported zero issues** → report "Review phase 1: clean" and proceed to the next phase.

4. **Spawn a fixer agent** — resolve `prompts/fixer.md` through the override chain. Launch with `mode: "bypassPermissions"`, `subagent_type: "general-purpose"`. Pass the FULL unedited review output as FINDINGS_LIST — the fixer decides what's real, not you.

5. **After fixer returns** → show the "FIXES:" section to the user. Report "Review phase 1: iteration N fixes applied". Loop back to step 1.

If `review_iterations` reached with issues still found, report "Review phase 1: max iterations reached, moving on" and continue.

### Step 8. Review phase 2 — code smells

Report to user: "--- Review phase 2: code smells analysis ---"

Run once (no loop):

1. **Spawn a smells agent** — resolve `agents/smells.txt` through the override chain. Launch one Agent tool call with `mode: "bypassPermissions"`, `subagent_type: "general-purpose"`, and the resolved agent prompt.

2. **Collect findings** — after the agent returns, report to user with a compact list of findings (one line per finding). Log findings to progress file:
   `bash "$SKILL_DIR/scripts/append-progress.sh" <progress-file> "review phase 2 smells: findings"`
   Then pipe the findings: `echo "<findings>" | bash "$SKILL_DIR/scripts/append-progress.sh" <progress-file>`

3. **If no issues found** → report "Smells analysis: clean" and proceed to the next phase.

4. **Spawn a fixer agent** — resolve `prompts/fixer.md` through the override chain. Launch with `mode: "bypassPermissions"`, `subagent_type: "general-purpose"`. Pass the FULL smells output as FINDINGS_LIST.

5. **After fixer returns** → report fixes to user. Proceed to the next phase.

### Step 9. Review phase 3 — critical only

Report to user: "--- Review phase 3: critical/major only (single pass) ---"

Same structure as step 7 but with `REVIEW_PHASE` set to `critical`. Resolve `prompts/review.md` through the override chain, spawn one review agent. The review agent launches 2 agents (quality, implementation) focusing on critical/major issues only. Same fixer flow — pass findings to fixer, show FIXES to user.

### Step 10. Finalize

Check `finalize_enabled` (default: true). If false, skip this step.

After all reviews pass, rebase and clean up commits.

Report to user: "--- Finalize: rebase and clean up commits ---"

Spawn one Agent tool call with `mode: "bypassPermissions"`, `subagent_type: "general-purpose"`, and the prompt from `prompts/finalizer.md`. Replace `DEFAULT_BRANCH`, `PLAN_FILE_PATH`, and `PROGRESS_FILE_PATH`.

This is best-effort — if rebase fails, report the issue but don't block completion.

### Step 11. Completion

When finalize is done (or skipped on failure):
- Log completion to progress file: `bash "$SKILL_DIR/scripts/append-progress.sh" <progress-file> "completed"`
- Report summary: "All N tasks completed, reviews passed, branch finalized"
- Do NOT move the plan file or push — just report completion

## Key rules

- Each subagent gets a fresh context — no accumulated state from previous tasks
- Parent session only tracks: task number, success/failure, retry count
- **Testing enforcement**: Detect testing approach from plan file (Step 1) and pass `TESTING_ENFORCED` to all task subagents:
  - If `TESTING_ENFORCED=true`: subagent MUST write tests for every task and ensure all tests pass before marking task done
  - If `TESTING_ENFORCED=false`: subagent may skip tests (but should still write them for non-trivial code)
- Plan file is the single source of truth for progress — always re-read it
- No signals — just checkboxes in the plan for task progress
- Maintain progress file (`/tmp/progress-<plan-name>.txt`) — see `prompts/progress-file.md` for format and when to write
- Do not modify the plan file yourself — only subagents modify it
- Do not implement or fix code yourself — only subagents implement and fix
- If a subagent fails or leaves broken code, re-run the loop — do NOT investigate or fix it yourself
- NEVER dismiss findings as "pre-existing", "not from changes", or "architectural" — ALL findings are actionable
- NEVER summarize or filter agent findings — pass the full output to the fixer agent verbatim
- All prompt and agent files MUST be resolved through the three-layer override chain before use
- All `subagent_type` values must be `general-purpose` — agent files provide the specialized prompt
- After reading a prompt file, substitute all placeholders before passing to subagent (see Placeholder Substitution)
