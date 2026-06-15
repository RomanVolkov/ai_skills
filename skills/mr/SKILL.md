---
name: mr
description: Comprehensive GitLab merge-request / issue review using the glab CLI - analyzes architecture, tests, identifies unrelated changes mixed in, drafts a review comment or issue comment. Use when the user asks to review an MR, check an MR, look at MR changes, or comment on a GitLab issue.
argument-hint: '<mr-or-issue-iid>'
allowed-tools: Bash, Read, Grep, Glob, Write, Skill, Task, AskUserQuestion
---

# GitLab MR Review Skill

Comprehensive merge-request review that analyzes code quality, architecture, test coverage, and identifies scope creep (unrelated changes mixed into the MR). Uses the `glab` CLI (GitLab) for all platform interaction.

## Usage

Claude Code only — invoke `/mr <iid>`. Not intended for OpenCode.

This skill does NOT approve, request changes, or merge — the user does approve/unapprove/merge manually. It only reviews and (with confirmation) posts a comment.

## Prerequisites

- `glab` installed and authenticated (`glab auth status`). If missing, tell the user and stop.
- A GitLab remote in the current repo.

## Activation Triggers

- "review mr 123", "check mr 123", "look at mr 123"
- "review the mr", "what do you think about this mr"
- "comment on issue 42", "look at issue 42", "review issue 42"

## Workflow

```
1. Fetch MR metadata + discussion history + merge/pipeline status
1.5. Ask review mode: Full (default) or Quick
--- Full path ---
2. Setup worktree, run inline deep analysis (read files, validate, architecture, scope creep)
3. Present findings, ask to proceed
4. Resolve open questions (if any)
5. Draft review comment, post via `glab mr note` after confirmation
--- Quick path ---
Q1. Read diff inline, summarize what/why/size
Q2. Flag obvious issues from diff
Q3. Draft review comment
```

## glab command reference

Verify exact flags during use with `glab mr --help` / `glab issue --help` (flag names vary by glab version):

| Purpose | Command |
|---|---|
| detect MR vs issue | `glab mr view <iid> >/dev/null 2>&1 && echo MR || echo ISSUE` |
| list MRs | `glab mr list` |
| view MR (JSON) | `glab mr view <iid> -F json` |
| MR diff | `glab mr diff <iid>` |
| MR changes (files) | `glab api projects/:id/merge_requests/<iid>/changes` |
| discussion notes | `glab api projects/:id/merge_requests/<iid>/notes` and `/discussions` |
| pipeline / CI status | from `glab mr view`, or `glab ci status` |
| fetch MR ref | `git fetch origin merge-requests/<iid>/head:mr-<iid>` |
| post MR comment | `glab mr note <iid> -m "..."` (use `-F -` / a file for long bodies if supported) |
| issue view | `glab issue view <iid>` |
| issue comment | `glab issue note <iid> -m "..."` |

## Phase 0: Detect MR vs Issue

If a URL is provided, check whether it contains `/merge_requests/` or `/issues/`. If just a number, detect type:

```bash
glab mr view <iid> >/dev/null 2>&1 && echo "MR" || echo "ISSUE"
```

- **MR** → proceed with the full MR review workflow (Phase 1 onwards)
- **Issue** → use the **Issue Comment Flow** below, skip all MR-specific phases

### Issue Comment Flow

For issues, skip worktree/diff/architecture analysis. Focus on understanding the issue and drafting a helpful comment.

1. **Fetch issue details and discussion:**
```bash
glab issue view <iid> --comments
```

2. **Read the full discussion** — understand what was reported, what others said, whether there are linked MRs.

3. **Investigate the codebase** if the issue references specific code, files, or behavior: search for relevant files, read them, understand the reported problem in context.

4. **Draft a comment** addressing the issue — root-cause analysis, a proposed approach, clarifying questions, or acknowledgment with next steps.

5. **Confirm, then post as a regular comment** with AskUserQuestion ("Post / Edit / Cancel"):
```bash
glab issue note <iid> -m "<comment content>"
```

After posting → done. No worktree cleanup needed for issues.

---

## Phase 1: Fetch MR Metadata and Discussion History

Get the MR iid from `$ARGUMENTS`. If not provided, list recent MRs and ask the user to select:

```bash
glab mr list                 # if no iid provided
glab mr view <iid> -F json   # title, description, source/target branch, author, state, diff stats
```

Capture: **title**, **description** (and linked issues), **changed files** with per-file +/-, **scope** (total +/-, file count), and **discussion history**.

### 1.1 Analyze Discussion History

Before reviewing, understand what's already been discussed:

```bash
glab api projects/:id/merge_requests/<iid>/notes
glab api projects/:id/merge_requests/<iid>/discussions   # inline, line-anchored threads
```

Summarize:
- What issues were raised by reviewers?
- What was the MR author's response?
- Are there unresolved threads or pending questions?
- What's already addressed vs still open?

**Check automated reviews** (GitLab bots, SAST/Code Quality): read them — they can have valuable findings. Verify before including; don't dismiss just because automated.

**Important:** do not re-raise issues already discussed and resolved. Focus on new or unaddressed concerns. The inline discussion threads are where the real line-by-line feedback lives.

### 1.2 Check Merge / Pipeline Status

From `glab mr view <iid>` (or `glab ci status`), report:
- **merge status**: mergeable / has conflicts / needs rebase
- **pipeline status**: passing / failing / running
- If the MR has conflicts or is behind its target branch, note this early — it may explain "deletions" in the diff that are just missing commits from the target.

Print summary:
```
MR !<iid>: <title>
Author: <author> | State: <state> | <source> → <target>
+<additions>/-<deletions> across <changedFiles> files
Merge: <status> | Pipeline: <status>

Discussion: <N> notes
- Resolved: <addressed issues>
- Open: <unresolved questions>
```

## Phase 1.5: Select Review Mode

After the Phase 1 summary, ask the user to choose review depth (AskUserQuestion):

```
question: "Review mode for MR !<iid>?"
header: "Mode"
options:
  - Full review (Recommended) — worktree, run tests/linter, architecture analysis, scope creep detection
  - Quick review — diff-only, summarize what/why/size, flag obvious issues
```

- **Full review** → continue to Phase 2
- **Quick review** → jump to the Quick Review path

## Quick Review Path

Lightweight review based on diff and metadata only. No worktree, no test/linter execution.

### Q1. Read and Summarize Diff

```bash
glab mr diff <iid>
```

From the diff and Phase 1 metadata, present:
- **What**: 2-3 sentence summary of what the MR does
- **Why**: purpose/motivation (from description, linked issues, or inferred)
- **Size**: +adds/-dels across N files — small/medium/large
- **Files changed**: grouped (code, tests, config, docs)

### Q2. Flag Obvious Issues

Scan the diff for issues detectable without full file context: obvious bugs (nil deref, unchecked errors, off-by-one), missing error handling, hardcoded values, added TODO/FIXME/HACK, test files missing for new code, large functions (50+ lines), unrelated changes mixed in. If nothing found, say so explicitly.

### Q3. Proceed to Draft

Skip directly to Phase 5 (Draft Review Comment). All Phase 5 rules apply. No worktree cleanup needed (quick review never creates one).

## Phase 2: Deep Analysis via Subagent

**Delegate file reading, validation, and architecture analysis to a subagent** (Task tool) to protect the main conversation's context window. The subagent does the heavy lifting and returns a condensed report.

### 2.1 Setup Worktree (in main conversation)

Create the worktree before launching the subagent:

```bash
# fetch the MR ref directly (does NOT affect the current checkout)
git fetch origin merge-requests/<iid>/head:mr-<iid>

# create a worktree from the fetched ref
git worktree add "/tmp/mr-review-<iid>" mr-<iid>
```

**Do NOT** switch the main repo's branch — always use `git fetch` + worktree.

### 2.2 Launch Analysis Subagent

Use the **Task tool** with `subagent_type: "general-purpose"`. Pass all context the subagent needs (MR title, description, file list, discussion summary from Phase 1, worktree path, repo path). Instruct it to:

1. **Read changed files** in full from the worktree to understand context, not just the diff. Focus on what the code actually does vs what the description claims.
2. **Run validation** from the worktree directory — detect project type (package.json, pyproject.toml, go.mod, Cargo.toml, …) and run the test suite, the linter, and race/concurrency checks if applicable. Record all failures.
3. **Architecture analysis** — over-engineering (unnecessary abstractions, premature generalization), pattern violations (inconsistent with the codebase), error handling, concurrency, security, test quality (fake tests, missing coverage).
4. **Scope creep detection** — categorize each file as Core / Supporting (tests, config) / Related cleanup / Unrelated.

Tell the subagent: **do NOT clean up the worktree** — the main conversation handles cleanup after all phases.

Require it to return a structured report (skip sections with no findings):
- **Functionality**: 3-5 sentences on what the MR does
- **Key decisions**: notable implementation choices
- **Validation results**: test pass/fail, linter issues, race conditions
- **Architecture issues**: list with file:line references
- **Over-engineering**: specific instances with simpler alternatives
- **Scope creep**: unrelated files with explanation
- **Positives**: what's done well
- **Open questions**: design decisions needing user input

### 2.3 Receive Report

The subagent returns the condensed report — that is what enters the main conversation, not the raw files or diff.

## Phase 3: Present Findings, Ask to Proceed

Present the report. Use AskUserQuestion:

```
question: "How would you like to proceed?"
header: "Continue?"
options:
  - Draft review comment (proceed to Phase 5)
  - Investigate specific finding (dig into a specific area)
  - Done (end review without posting)
```

If "Investigate specific finding", launch another targeted subagent to dig into that area, then ask again.

## Phase 4: Resolve Open Questions

If the report contains open questions (design decisions needing user input), ask about EACH one specifically before proceeding (AskUserQuestion: Accept / Reject / Need more context). On "Need more context", launch a targeted subagent to investigate, then ask again. Note each decision for the review comment. Repeat for all open questions.

## Phase 5: Draft Review Comment

Only proceed when the user explicitly asks to draft/post the review.

### 5.1 Check Previous Comments (Critical)

**NEVER duplicate what the user already said in their previous comments.** From the Phase 1.1 discussion history, exclude anything the USER already raised, recommended, or asked — even if phrased differently.

**Include only**: NEW findings, updates on issues (e.g. "tests still failing after fix attempt"), responses to the contributor's questions, the user's decisions on Phase 4 open questions, and valid unaddressed automated-tool findings.

If the user already covered everything → say "no new findings to add" and don't draft.

### 5.2 Draft Comment

Activate the writing-style skill for tone (Skill tool, name `writing-style`).

**CRITICAL: don't restate what the MR does** — the author knows what they built. Focus only on issues that need fixing, questions about unclear decisions, or LGTM if everything is fine.

**Keep it casual and brief.** Examples:
```markdown
LGTM
```
```markdown
lgtm. one minor thing - `loadPatterns` could filter in a single pass instead of two, but not a blocker
```
```markdown
couple issues:

1. test failure in `TestFoo` - looks like missing mock setup
2. linter complains about unused param on line 42

otherwise looks good
```
```markdown
I don't get why we need the Factory pattern here - there's only one implementation. could simplify to just `NewNotifier()` directly?
```

**Only add sections if there are actual issues** — Issues (numbered), Questions, Complexity concerns (with a simpler alternative). Omit empty sections. For clean MRs, "LGTM" is fine.

**Code examples**: when suggesting fixes, always show proper error handling — never ignore errors even in snippets.

## Output

### Display Draft First

Always display the complete draft as a text block before asking:
```
--- Draft Review Comment ---
<actual review content here>
--- End Draft ---
```

### Ask User via AskUserQuestion

```
question: "Post this comment to MR !<iid>?"
header: "Comment"
options:
  - Post (post as a comment via glab mr note)
  - Edit (tell me what to change)
  - Cancel (discard draft)
```

### Handle Response

- **Post**: post as a regular MR comment. Approve/merge are out of scope — the user does those manually.
  ```bash
  glab mr note <iid> -m "<review content>"
  ```
  (For long bodies, write to a temp file and pass it via the supported flag, e.g. `glab mr note <iid> -F /tmp/mr-review.md` if available; otherwise `-m`.)
- **Edit**: ask for specific changes, update the draft, display again, repeat the ask.
- **Cancel**: acknowledge and stop.

### Cleanup Worktree

**After the review is fully complete** (comment posted, cancelled, or "Done"), clean up:
```bash
cd <repo_path>
git worktree remove "/tmp/mr-review-<iid>" --force 2>/dev/null || true
git branch -D mr-<iid> 2>/dev/null || true
```
This must happen AFTER all phases — the worktree is needed for follow-up investigations in Phases 3-4.

## Notes

- **Comment-only** — never approve, unapprove, request changes, or merge. The user handles those manually.
- **NEVER duplicate the user's previous comments** — check the discussion history and exclude what the user already said.
- **proper error handling in code suggestions** — never ignore errors even in example snippets.
- **subagent for heavy lifting** — file reading, validation, and architecture analysis run in a subagent to protect the main context window; only the condensed report enters the conversation.
- **never switch the main repo's branch** during review — use `git fetch` + worktree.
- use the `writing-style` skill for review comments.
- be specific about file:line when noting issues.
- distinguish "unrelated but acceptable" (linter fixes) from "unrelated and problematic" (refactoring).
- draft locally first, confirm before posting.
- let the user guide when to proceed vs when to discuss more.
