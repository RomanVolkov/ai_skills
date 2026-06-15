# AI Skills for Claude Code & OpenCode

[![Uses Claude Code](https://img.shields.io/badge/Works%20with-Claude%20Code-DA7857?logo=anthropic)](https://claude.ai/code)
[![Uses OpenCode](https://img.shields.io/badge/Works%20with-OpenCode-DA7857?logo=anthropic)](https://opencode.com/)
[![GitHub](https://img.shields.io/badge/GitHub-RomanVolkov%2Fai_skills-blue?logo=github)](https://github.com/RomanVolkov/ai_skills)

Skills for **Claude Code** and **OpenCode**. Tools for planning, analysis, code review, and task automation.

## Overview

This repository contains skills that extend Claude's capabilities for software engineering tasks. Each skill targets a workflow — from root cause analysis and planning to code review and content generation.

For debugging issues, designing implementation strategies, reviewing code changes, or building MCP servers, these skills provide agents and workflows.

**Works with both Claude Code and OpenCode** — install once, use everywhere.

## Available Skills

### Planning & Analysis

- **[plan-make](skills/plan-make/)** — Create implementation plans saved to `docs/plans/`. Use to design solutions before you code.
- **[plan-exec](skills/plan-exec/)** — Execute plan tasks in sequence with inline execution and review phases. Turns plans into implementation, task by task.
- **[plan-review](skills/plan-review/)** — Review plan quality before execution. Checks plans for completeness, correctness, and adherence to project conventions.
- **[brainstorm](skills/brainstorm/)** — Dialogue skill for analysis and design exploration. Use before design work or changes.
- **[dialectic](skills/dialectic/)** — Prove and counter-prove statements using agents in parallel. Stress-tests claims and removes confirmation bias.

### Project Management

- **[create-tasks](skills/create-tasks/)** — Create descriptions for epics, user stories, and tasks. SMART-compliant, adjective-free, with Definition of Ready/Done. Includes type detection and breakdown (epic → stories → tasks). YouTrack markdown output.

### Debugging & Problem Solving

- **[root-cause](skills/root-cause/)** — Root cause analysis using 5-Why methodology. Find the source of errors, build failures, and performance issues.
- **[clarify](skills/clarify/)** — Understand confusion and misalignment. Explains behavior when expectations don't match reality.
- **[wrong](skills/wrong/)** — Reset and re-evaluate when an approach isn't working. Get another perspective when a solution hits a dead end.

### Code & Review

- **[git-review](skills/git-review/)** — Git diff annotation review. Review and give feedback on changes in a loop.
- **[mr](skills/mr/)** — GitLab merge-request (and issue) review via the `glab` CLI. Analyzes architecture, tests, and scope creep, then drafts and posts a review comment.
- **[writing-style](skills/writing-style/)** — Style guide for tickets, MR/PR descriptions, review comments, and commits. Removes hedging, filler, and AI-speak.
- **[skill-creator](skills/skill-creator/)** — Create skills, iterate on them, and benchmark skill performance with evals.

### Content & Documentation

- **[readme-generator](skills/readme-generator/)** — Generate README.md files following GitHub best practices. Includes badges, metrics, and structure.
- **[german-email-composer](skills/german-email-composer/)** — Compose German emails and letters from bullet points.

### Development Tools

- **[frontend-design](skills/frontend-design/)** — Build UI components and interfaces for the web.
- **[mcp-builder](skills/mcp-builder/)** — Create MCP (Model Context Protocol) servers for integrating APIs and services.

## Getting Started

### Installation

Clone this repository:

```bash
git clone https://github.com/RomanVolkov/ai_skills.git
cd ai_skills
```

Run the installation script to copy skills to both Claude Code and OpenCode:

```bash
./install.sh
```

This installs all skills to:
- `~/.claude/skills/` — For Claude Code CLI and Claude Desktop app
- `~/.config/opencode/skills/` — For OpenCode

### Using a Skill

After installation, skills are available in both Claude Code and OpenCode. Invoke them with the `/skill-name` format or in conversation:

```bash
/plan-make          # Create an implementation plan
/plan-exec          # Execute a plan
/root-cause         # Analyze a problem
/git-review         # Review code changes
/skill-creator      # Build a skill
/create-tasks       # Write epic/story/task descriptions
```

Or reference them in conversation:
- "Let's brainstorm how to handle this"
- "Create a plan for adding authentication"
- "Execute the plan"
- "Help me understand why this is failing"

## Repository Structure

```
ai_skills/
├── skills/                        # All skills
│   ├── plan-make/                 # Plan creation
│   ├── plan-exec/                 # Plan execution
│   ├── plan-review/               # Plan review
│   ├── brainstorm/                # Brainstorming & design
│   ├── dialectic/                 # Proof/counter-proof analysis
│   ├── root-cause/                # Root cause analysis
│   ├── clarify/                   # Confusion clarification
│   ├── wrong/                     # Perspective reset
│   ├── git-review/                # Diff annotation review
│   ├── mr/                        # GitLab MR/issue review
│   ├── writing-style/             # Communication style guide
│   ├── skill-creator/             # Skill creation & iteration
│   ├── create-tasks/              # Work item descriptions (epics/stories/tasks)
│   ├── readme-generator/          # README generation
│   ├── german-email-composer/     # German email composition
│   ├── frontend-design/           # UI/frontend design
│   └── mcp-builder/               # MCP server creation
├── install.sh                     # Installation script
├── .git/                          # Git repository metadata
└── README.md                      # This file
```

## How These Skills Work

Each skill in this collection:

1. **Has a purpose** — solves a class of problems or workflows
2. **Includes instructions** — SKILL.md documents when and how to use it
3. **Activates** — invoked with `/skill-name` or through natural-language triggers
4. **Provides guidance** — uses methodologies (5-Why, Dialectic reasoning, etc.)
5. **Integrates with Claude Code** — works with git, file operations, and editor integration

## License

This collection of skills is licensed under the MIT License. See skill directories for license information.


## Contact

**Roman Volkov**

- GitHub: [@RomanVolkov](https://github.com/RomanVolkov)
- X (Twitter): [@romanvdev](https://x.com/romanvdev)
- Repository: [RomanVolkov/ai_skills](https://github.com/RomanVolkov/ai_skills)

Questions, feedback, or collaboration? Reach out on GitHub or X.

---

**Installation:** `./install.sh`
