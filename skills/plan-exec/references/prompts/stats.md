# Stats summary prompt

Guidance for the stats summary step, run **inline** by the orchestrator after finalize completes (replace `DEFAULT_BRANCH` and `PROGRESS_FILE_PATH` with actual values).

This skill runs inline (no subagent spawning), so there are no per-subagent session logs to parse. Compute the summary directly from git state, the plan file, and the progress file. This step is best-effort — if any command fails, report the failure and continue; do not block completion.

## Gather data

**Git stats** (run from the repo root / worktree):
- `git diff --shortstat DEFAULT_BRANCH...HEAD` → total files changed and +/- line counts
- `git diff --stat DEFAULT_BRANCH...HEAD | head -20` → pick the top 5 files by churn
- `git log --oneline DEFAULT_BRANCH..HEAD | wc -l` → commit count on the branch

**Plan progress:**
- Count completed (`[x]`) vs total task checkboxes in the plan file to report tasks done.

**Progress file** (`PROGRESS_FILE_PATH`):
- Plan name and branch (from the header)
- The `Started:` timestamp — compute wall-clock as the difference between `Started:` and now
- Fixer iteration counts per review phase (count the logged iterations)
- Final state ("completed", "max iterations reached", or partial)

## Output format

Emit ONLY this markdown report — no preamble, no commentary:

```
## Run summary

**Wall-clock:** <Xm Ys>   **Tasks:** <done>/<total>   **Commits:** <N>

### Branch changes (vs DEFAULT_BRANCH)

<N> files changed, +<adds> / -<dels>

Top files by churn:
- <file>  +<adds>/-<dels>
- <file>  +<adds>/-<dels>
- ...

### Notable

- Review iterations: phase 1: <N>, smells: <N>, critical: <N>
- Final state: <completed | max-iter-hit | partial>
```

## Constraints

- READ-ONLY: do NOT modify any files (no plan edits, no commits, no fixes).
- Be precise with numbers — use actual values from git and the progress file, not estimates.
- Format durations as "Xm Ys" for runs over 60s, else "Ys".
- If a section has no data, write "n/a" rather than omitting the line.
- Keep the report compact — this is a summary, not a transcript.
