---
name: create-tasks
description: "Create structured descriptions for epics, user stories, and tasks with SMART compliance, no adjectives, and clear scope definitions. Use this skill whenever the user wants to write, draft, or improve a work item description — whether they say 'epic', 'user story', 'task', 'ticket', 'issue', 'backlog item', 'feature request', or anything related to project management artifacts. Also trigger when users say 'write a description for...', 'create a ticket for...', 'define the scope of...', or 'break this down into stories/tasks'. Works with YouTrack markdown format."
argument-hint: describe what the work item is about
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion
---

# Work Item Creator

Create structured, SMART-compliant descriptions for epics, user stories, and tasks. Output is YouTrack-compatible markdown.

## Core principles

These principles apply to every work item this skill produces. They are non-negotiable because vague descriptions cause rework, scope creep, and misaligned expectations.

1. **SMART compliance** — every work item must be Specific, Measurable, Achievable, Relevant, and Time-bound. Each dimension is enforced through the templates below.
2. **Zero adjectives** — never use subjective qualifiers (fast, simple, intuitive, robust, seamless, user-friendly, clean, modern, scalable, reliable, minimal, significant, easy, good). Replace every adjective with a fact: a number, a named standard, or an operational definition. "Fast" becomes "responds within 200ms at p95." "User-friendly" becomes "new users complete the flow without assistance in under 3 minutes."
3. **Definition of Ready / Definition of Done** — every work item includes both, tailored to its type.
4. **The "why" comes first** — every epic and user story starts by answering: what problem exists, who has it, and what happens if we do nothing. Tasks link back to their parent story's "why."
5. **Type honesty** — if the content doesn't match the declared type, flag it. An "epic" with one done criterion is a task. A "task" that spans multiple teams is an epic. Say so.

## Step 0: Determine the type

If the user specified a type (epic, user story, task), accept it as a starting point but validate it later. If they didn't specify, ask.

Use AskUserQuestion:

```json
{
  "questions": [{
    "question": "What type of work item do you want to create?",
    "header": "Work item type",
    "options": [
      {"label": "Epic", "description": "A business capability spanning multiple sprints, broken into user stories"},
      {"label": "User Story", "description": "A single user-facing behavior completable in one sprint"},
      {"label": "Task", "description": "A specific technical action (hours, not days) tied to a story"},
      {"label": "Not sure", "description": "Describe your idea and I will help determine the type"}
    ],
    "multiSelect": false
  }]
}
```

## Step 1: Gather context through interview

Ask questions **one at a time** using AskUserQuestion. Adapt questions based on the selected type.

### For Epics

Ask in this order, one at a time:

1. **Problem statement**: "What problem are we solving? Who has this problem?"
   - If the user gives a solution ("build feature X"), ask: "What problem does feature X solve? Who experiences this problem today?"
2. **Current impact**: "What is the measurable impact of this problem today? (support tickets/month, revenue lost, time wasted per occurrence, error rate)"
   - Push for numbers. "A lot of support tickets" → "How many per month, approximately?"
3. **Desired outcome**: "What measurable outcome do we want after this is delivered? (target metric with current baseline and target value)"
4. **Scope**: "What capabilities are we building? (list the things that will be delivered)"
5. **User segments**: "Which user roles or segments are affected?"
6. **Dependencies**: "Are there known dependencies on other teams, services, or external systems?"
7. **Time horizon**: "What is the target delivery timeframe? (quarter, PI, specific date)"

### For User Stories

Ask in this order, one at a time:

1. **Persona**: "Who is the specific user? (not 'user' — a role like 'warehouse operator', 'first-time visitor', 'account admin')"
2. **Goal**: "What does this person want to accomplish? (one specific action)"
   - If the user lists multiple actions joined by "and", flag it: "This sounds like it could be multiple stories. Can we focus on one action?"
3. **Benefit**: "Why does this person want this? What happens if they can't do it?"
4. **Acceptance criteria**: "Describe the expected behavior. What should happen on success? On failure? At boundary conditions?"
   - Ask follow-up questions to fill gaps in the happy path, error paths, and edge cases.
5. **Constraints**: "Are there performance, accessibility, security, or compatibility requirements? (specific numbers, not adjectives)"
6. **Parent epic**: "Which epic does this belong to? (or is it standalone?)"

### For Tasks

Ask in this order, one at a time:

1. **Parent story**: "Which user story does this task support? (paste the title or link)"
2. **Action**: "What specific technical action needs to happen? (which file, component, API, system)"
3. **Done state**: "How will we know this is done? (test passes, PR merged, deployed to staging, specific output produced)"
4. **Effort estimate**: "Rough estimate in hours? (if over 8 hours, this might need splitting)"
5. **Dependencies**: "Does this task depend on another task being completed first?"

### For "Not sure"

1. Ask: "Describe what you want to build or accomplish."
2. Based on the answer, apply type detection heuristics (see below) and propose a type with reasoning.
3. Proceed with the appropriate interview.

## Step 2: Validate the type

After gathering context, check whether the declared type matches the content. Apply these heuristics:

**It should be an Epic if:**
- The scope spans more than one sprint (2+ weeks of work for a team)
- Multiple user roles or personas are involved
- It decomposes into 5+ distinct user-facing behaviors
- The description contains "and" connecting distinct capabilities
- It contains the word "manage" implying CRUD + search + permissions
- The done criteria would require multiple teams to deliver

**It should be a User Story if:**
- It describes one user-facing behavior for one persona
- It fits within a single sprint
- It can be demonstrated to a stakeholder
- It has 3-8 Given/When/Then scenarios

**It should be a Task if:**
- No user-facing behavior (purely technical: migration, refactor, config change)
- Estimated at under 8 hours
- Cannot be independently demonstrated to a stakeholder
- It is a sub-step of a larger feature

If the type doesn't match, say so directly:

> "You asked for a user story, but this scope includes account creation, profile editing, role management, and audit logging — that's at least 4 separate user-facing behaviors across multiple sprints. This is an epic. I will generate it as an epic. If you disagree, let me know."

Do not ask permission to change the type. State the mismatch, state what you'll do, and let the user override if they want.

## Step 3: Generate the description

Use the template for the validated type. Output is YouTrack-compatible markdown.

### Epic template

```markdown
# [Epic Title — verb-noun format, e.g., "Implement Self-Service Subscription Management"]

## Problem Statement
[1-2 sentences: who has the problem, what the problem is, measurable impact (number + unit).]

## Scope
- [Capability 1]
- [Capability 2]
- [Capability 3]

## Dependencies
| Dependency | Owner | Status | Required by |
|---|---|---|---|
| [Dependency 1] | [Team/person] | [Resolved/Pending] | [Date/Sprint] |

## Success Metrics
| Metric | Baseline | Target | Measurement method | Review date |
|---|---|---|---|---|
| [Metric 1] | [Current value] | [Target value] | [How measured] | [When to check] |

## Definition of Ready
- [ ] Problem statement reviewed by stakeholders
- [ ] Success metrics have baselines and targets
- [ ] Scope agreed by stakeholders
- [ ] Initial story breakdown exists
- [ ] Dependencies identified with owners and resolution dates
- [ ] T-shirt size or rough estimate provided
- [ ] Epic owner assigned

## Definition of Done
- [ ] [Outcome-based criterion with measurable threshold]
- [ ] [Outcome-based criterion with measurable threshold]
- [ ] [Non-functional requirement: performance, security, accessibility — with numbers]
- [ ] [Observability: monitoring, analytics, alerting in place]
- [ ] All child stories meet their own Definition of Done
- [ ] Success metrics instrumentation deployed and collecting data
- [ ] End-to-end integration tested
- [ ] Stakeholder demo completed
- [ ] Documentation updated (user-facing, API, runbooks)
- [ ] Deployed to production (or release-ready)
```

The epic DoD serves double duty: the top items are the measurable outcome criteria (what was previously "acceptance criteria"), and the bottom items are the process quality gates. This avoids having a separate acceptance criteria section that duplicates DoD.

### User Story template

```markdown
# [Story Title — describes the user behavior]

## User Story
**As a** [specific persona],
**I want to** [single concrete action],
**so that** [measurable benefit / problem solved].

## Context
[1-2 sentences: why this matters now, what problem exists, link to parent epic if applicable]

## Acceptance Criteria

### [Scenario 1 name]
**Given** [specific precondition]
**When** [specific user action]
**Then** [observable, measurable outcome]

### [Scenario 2 name]
**Given** [specific precondition]
**When** [specific user action]
**Then** [observable, measurable outcome]

### [Error scenario name]
**Given** [specific precondition]
**When** [invalid action or failure condition]
**Then** [specific error handling behavior]

## Constraints
- Performance: [specific metric, e.g., "page renders in under 1.5s on 4G (Lighthouse mobile)"]
- Accessibility: [specific standard, e.g., "meets WCAG 2.1 AA, all form inputs have labels"]
- Security: [specific requirement, e.g., "input sanitized against XSS, authentication required"]
- Compatibility: [specific scope, e.g., "Chrome 120+, Firefox 120+, Safari 17+, viewport 320px-1440px"]

## Definition of Ready
- [ ] Persona identified (not generic "user")
- [ ] "So that" clause states a measurable benefit
- [ ] At least 3 acceptance criteria in Given/When/Then format
- [ ] Error and edge case scenarios included
- [ ] Performance/accessibility/security constraints stated with numbers
- [ ] Story estimated and fits within one sprint
- [ ] Dependencies resolved or scheduled before sprint start
- [ ] UX/UI designs available (if applicable)

## Definition of Done
- [ ] All acceptance criteria pass
- [ ] Code peer-reviewed and approved
- [ ] Unit tests written and passing
- [ ] Integration tests written and passing (if applicable)
- [ ] No regressions in existing test suite
- [ ] Deployed to staging and verified
- [ ] Product owner accepted
- [ ] Documentation updated (if applicable)
```

### Task template

```markdown
# [Task Title — imperative verb + object + qualifier, e.g., "Create database migration for user preferences table"]

## Context
Part of: [parent story title and ID]
Why: [1 sentence — how this task contributes to the parent story's goal]

## Description
[What needs to happen, in concrete terms. Name the file, component, API, or system. Specify requirements and constraints, not exact implementation steps.]

## Technical Details
- Component: [exact file path or module name]
- Input: [what data/state this task works with]
- Output: [what this task produces]
- Approach: [suggested implementation path, if relevant]

## Dependencies
- Blocked by: [task ID or "none"]
- Blocks: [task ID or "none"]

## Estimate
[N] hours

## Definition of Ready
- [ ] Parent story is understood (persona, goal, benefit)
- [ ] Technical approach understood (no major unknowns)
- [ ] Dependencies resolved or on track
- [ ] Estimated at 8 hours or fewer

## Definition of Done
- [ ] [Binary-verifiable criterion: test passes, endpoint returns correct schema, migration runs without errors]
- [ ] [Binary-verifiable criterion]
- [ ] [Binary-verifiable criterion]
- [ ] Unit tests cover new/modified code
- [ ] Code reviewed and approved
- [ ] CI pipeline passes
```

## Step 4: Internal validation (do not include in output)

Before presenting the description, silently run two checks. Fix any issues directly in the output. Do NOT include the check results as sections in the generated description — they are internal quality gates, not part of the deliverable.

**SMART compliance check:** Verify every dimension passes. If any fails, fix the output or ask the user for missing info.
- Specific: personas named, scope bounded
- Measurable: DoD criteria have numeric thresholds, success metrics have baselines and targets
- Achievable: dependencies confirmed or flagged
- Relevant: traces to a business objective
- Time-bound: target date or quarter stated

**Adjective scan:** Check for banned words: fast, quick, slow, simple, easy, complex, intuitive, user-friendly, robust, reliable, scalable, performant, secure, clean, modern, seamless, minimal, lightweight, significant, substantial, good, bad, major, minor, large, small, high, low (without number), better, improved, enhanced, efficient, effective, flexible, comprehensive, extensive, powerful, elegant, smooth, responsive (without metric). Replace any found with facts.

## Step 6: Present and offer breakdown

Present the generated description to the user. Then ask:

For epics, use AskUserQuestion:
```json
{
  "questions": [{
    "question": "The epic is ready. Do you want to break it down further?",
    "header": "Next step",
    "options": [
      {"label": "Break into user stories", "description": "Generate user story descriptions for each capability in the scope"},
      {"label": "Done", "description": "The epic description is complete as-is"}
    ],
    "multiSelect": false
  }]
}
```

For user stories, use AskUserQuestion:
```json
{
  "questions": [{
    "question": "The user story is ready. Do you want to break it down further?",
    "header": "Next step",
    "options": [
      {"label": "Break into tasks", "description": "Generate task descriptions for implementing this story"},
      {"label": "Done", "description": "The user story description is complete as-is"}
    ],
    "multiSelect": false
  }]
}
```

For tasks, just present the result — tasks don't break down further.

### Breakdown process

When breaking down an epic into stories:
1. Identify distinct user-facing behaviors within the epic's scope
2. For each, generate a full user story using the template above
3. Verify each story passes INVEST: Independent (can be delivered alone), Negotiable (describes outcome, not implementation), Valuable (delivers user-facing value), Estimable (team can size it), Small (fits in one sprint), Testable (acceptance criteria are verifiable)
4. After generating all stories, ask if the user wants to break any of them into tasks

When breaking down a story into tasks:
1. Decompose by layer or concern (database, backend, frontend, tests)
2. Each task should be 2-8 hours of focused work
3. For each, generate a full task description using the template above
4. Show dependencies between tasks

## Writing style rules

These rules apply to all generated text:

- Use imperative form in titles: "Create...", "Implement...", "Add..."
- State facts, not opinions: "340 support tickets per month" not "too many support tickets"
- Every number has a unit: "200ms", "500 concurrent users", "3 hours"
- Every threshold has a measurement method: "p95 latency measured by Datadog APM"
- Pronouns are replaced with specific names: not "the system" but "the order service"; not "the user" but "the warehouse operator"
- Ranges over false precision: "5-15% improvement" not "8.7% improvement" (unless the baseline is that precise)
- No circular reasoning: "we need this because customers asked for it" — instead state what problem the customers have
- No solution-as-justification: "migrate to X because X is better" — instead state what measurable outcome the migration achieves
