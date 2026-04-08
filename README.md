# AI Skills for Claude Code

[![Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-DA7857?logo=anthropic)](https://claude.ai/code)
[![Claude Skills](https://img.shields.io/badge/Uses-Claude%20Skills-DA7857?logo=anthropic)](https://github.com/RomanVolkov/ai_skills)
[![GitHub](https://img.shields.io/badge/GitHub-RomanVolkov%2Fai_skills-blue?logo=github)](https://github.com/RomanVolkov/ai_skills)

A collection of 15 powerful, production-ready Claude Code skills designed to enhance your software engineering workflow with AI-assisted planning, analysis, code review, and specialized task automation.

## Overview

This repository contains a curated set of Claude Code skills that extend Claude's capabilities for professional software engineering tasks. Each skill is purpose-built to tackle specific workflows—from systematic root cause analysis and structured planning to interactive code review and AI-assisted content generation.

Whether you're debugging complex issues, designing implementation strategies, reviewing code changes, or building MCP servers, these skills provide specialized agents and workflows that make you a more efficient developer.

## Available Skills

### Planning & Analysis

- **[plan-make](skills/plan-make/)** — Create structured implementation plans saved to `docs/plans/`. Perfect for designing solutions before you code.
- **[plan-exec](skills/plan-exec/)** — Execute plan tasks sequentially using isolated subagents. Turns your plans into systematic, step-by-step implementation.
- **[plan-review](skills/plan-review/)** — Review plan quality before execution. Ensures plans are complete, correct, and follow project conventions.
- **[brainstorm](skills/brainstorm/)** — Collaborative dialogue skill for deep analysis and design exploration. Use before creative work or significant changes.
- **[dialectic](skills/dialectic/)** — Prove and counter-prove statements using parallel agents. Stress-tests claims and eliminates confirmation bias.

### Debugging & Problem Solving

- **[root-cause](skills/root-cause/)** — Systematic root cause analysis using 5-Why methodology. Find the real source of errors, build failures, and performance issues.
- **[clarify](skills/clarify/)** — Understand confusion and misalignment. Explains actual behavior when expectations don't match reality.
- **[wrong](skills/wrong/)** — Reset and re-evaluate when your current approach isn't working. Get a fresh perspective on dead-end solutions.

### Code & Review

- **[git-review](skills/git-review/)** — Interactive git diff annotation review. Review and provide feedback on changes in a structured loop.
- **[skill-creator](skills/skill-creator/)** — Create new skills, iterate on existing ones, and benchmark skill performance with quantitative evals.

### Content & Documentation

- **[readme-generator](skills/readme-generator/)** — Generate professional README.md files following GitHub best practices. Includes badges, metrics, and structure.
- **[german-email-composer](skills/german-email-composer/)** — Compose polite, professional German emails and letters from bullet points.

### Development Tools

- **[frontend-design](skills/frontend-design/)** — Build distinctive, production-grade UI components and interfaces with high design quality.
- **[mcp-builder](skills/mcp-builder/)** — Create high-quality MCP (Model Context Protocol) servers for integrating external APIs and services.

## Quick Start

### Installation

Clone this repository:

```bash
git clone https://github.com/RomanVolkov/ai_skills.git
cd ai_skills
```

Run the installation script to copy skills to Claude Code:

```bash
./install.sh
```

This copies all skills to:
- `~/.claude/skills/` (primary location)
- `~/.config/opencode/skills/` (OpenCode compatibility)

### Using a Skill

After installation, skills are available in Claude Code. Invoke them using the `/skill-name` format or through Claude's natural language understanding:

```bash
/plan-make          # Create an implementation plan
/plan-exec          # Execute a plan
/root-cause         # Analyze a problem systematically
/git-review         # Review code changes
/skill-creator      # Build a new skill
```

Or reference them naturally in conversation:
- "Let's brainstorm how to handle this"
- "Create a plan for adding authentication"
- "Execute the plan"
- "Help me understand why this is failing"

## Repository Structure

```
ai_skills/
├── skills/                        # All Claude Code skills
│   ├── plan-make/                 # Planning skill
│   ├── plan-exec/                 # Plan execution skill
│   ├── plan-review/               # Plan quality review
│   ├── brainstorm/                # Brainstorming & design
│   ├── dialectic/                 # Proof/counter-proof analysis
│   ├── root-cause/                # Root cause analysis
│   ├── clarify/                   # Confusion clarification
│   ├── wrong/                     # Fresh perspective tool
│   ├── git-review/                # Code review skill
│   ├── skill-creator/             # Skill creation & iteration
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

1. **Has a clear purpose** — Designed to solve a specific class of problems or workflows
2. **Includes instructions** — SKILL.md documentation explains when and how to use it
3. **Activates intelligently** — Can be invoked with `/skill-name` or through natural language triggers
4. **Provides expert guidance** — Uses systematic methodologies (5-Why, Dialectic reasoning, etc.)
5. **Integrates with Claude Code** — Works seamlessly with git, file operations, and editor integration

## Skill Statistics

| Metric | Count |
|--------|-------|
| Total Skills | 15 |
| Planning Skills | 3 |
| Analysis Skills | 5 |
| Development Tools | 2 |
| Content Generation | 2 |
| Code Review Tools | 1 |
| Specialized Utilities | 1 |

## Reporting Issues

Found a bug, have a suggestion, or want to improve a skill?

[GitHub Issues](https://github.com/RomanVolkov/ai_skills/issues)

When reporting issues, please include:

- Which skill is affected
- Description of the problem or suggestion
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Your Claude Code version and environment

## Contributing

Contributions are welcome! To add a new skill or improve an existing one:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-skill`)
3. Add or modify your skill following the existing structure
4. Test thoroughly with Claude Code
5. Commit and push your changes
6. Open a pull request with a description of your skill

For skill development guidance, see the `skill-creator` skill documentation.

## License

This collection of skills is licensed under the MIT License. See individual skill directories for specific license information.


## Contact

**Roman Volkov**

- GitHub: [@RomanVolkov](https://github.com/RomanVolkov)
- Repository: [RomanVolkov/ai_skills](https://github.com/RomanVolkov/ai_skills)

Questions, feedback, or collaboration opportunities? Feel free to open an issue or reach out on GitHub.

---

**Last updated:** 2026-04-08
**Active Skills:** 15
**Installation:** `./install.sh`
