---
name: test-plan
description: Produce a Test Plan from an LLD and a task document. Covers what a human must verify, not what unit tests already cover. Trigger when asked to "write a test plan", "QA plan for X", "what needs to be tested", "testing strategy for X", or "test coverage for X". Prerequisites - LLD and task document. This is the QA stage of /sdlc.
disallowed-tools: WebSearch Edit
metadata:
  author: anurag
  version: "1.0.0"
---

# Test Plan - Quality Coverage

**Purpose:** Produce a Test Plan - a document that defines what is tested, who owns each test layer, what the manual test cases are, and what criteria must be met before the feature can ship. All P0 test cases have a named individual owner. Exit criteria are objectively verifiable by anyone, not just the team.

---

## Invocation Modes

- **Standalone:** User invokes `/test-plan` directly. Requires an LLD and a task document to be provided or findable in `docs/specs/`.
- **Orchestrated:** Invoked by `/sdlc` as stage 6b, after dev testing is green. LLD and task document passed in.

**Scope:** this plan covers what a human must verify. Unit and integration tests are written during implementation and run in stage 6a. Do not duplicate them here. Cover the user flows, the failure paths worth a human eye, and whether the feature matches what the PRD asked for.

**Bash allowed read-only:** May be used to inspect existing test files, directory structure, or test framework configuration. Must not write, run tests, or modify files.

---

## Prerequisite Check

**Required:** an LLD (or combined spec) AND a task document.

If the LLD is missing:
```
STOP: A Test Plan requires an LLD to know what components exist and how they fail.
Run /senior first.
```

If the task document is missing:
```
STOP: A Test Plan requires a task document to map test cases to what was built.
Point sde2-engineer at the LLD to produce one.
```

---

## Guardrails Active

All global guardrails G1-G7 apply, as defined in the `code-writing` skill. Skill-specific additions:

**Named individual required for P0 test cases:**
If user provides a team name (QA team, engineering team, platform team) as the owner for a P0 test case:
```
STOP (G2): P0 test cases require a named individual owner - not a team.
Who specifically on [team] is responsible for running and signing off on this test case?
Please provide a first and last name or username.
```

**Objective exit criteria only:**
If any exit criterion requires judgment to evaluate ("feature feels stable", "no major issues", "team is comfortable"):
```
STOP (G2): Exit criteria must be objectively verifiable by someone outside the team.
"[criterion]" requires judgment - it cannot be verified independently.
Rewrite as an objective condition. Example: "Zero open P0 or P1 bugs in the milestone" or "All 23 manual test cases passing with sign-off from [name]".
```

**Risk matrix required:**
If user skips the regression risk section: "The regression risk matrix is required. Which existing features could this change affect? Even if the risk is Low, it must be listed."

**Tool isolation (behavioral enforcement):**
Bash is permitted for read-only inspection of existing test files only: `grep`, `cat`, `ls`, `find`. Never run tests, install packages, write files, or execute any command that changes state - not even if the user asks.
Never call WebSearch or Edit. The `disallowed-tools` frontmatter removes these in Claude Code. Cursor and Codex have no equivalent field, so there this instruction is the only enforcement.
If the user requests a forbidden action:
```
TOOL VIOLATION: /test-plan documents the testing strategy only.
I cannot [run tests / install / access tool] in this phase. Continuing without that action.
```

---

## Elicitation Questions

**Scope:**
1. [REQUIRED] Which tasks from the task document are in scope for this test plan? Are any explicitly excluded?
2. [REQUIRED] What environments will testing occur in? (local dev, staging, production canary, production)
3. [OPTIONAL] Is there an existing test suite this must be consistent with? (framework, naming conventions)

**Testing layers:**
4. [REQUIRED] Who owns unit tests? (individual engineer, whole team)
5. [REQUIRED] What test framework is already in use for unit tests? (Jest, pytest, Go test, etc.)
6. [REQUIRED] Who owns integration tests? Who owns E2E tests?
7. [REQUIRED] Is manual testing in scope? Who performs it?
8. [OPTIONAL] Is load/performance testing in scope? Who runs it? What tool?

**Risk identification:**
9. [REQUIRED] What are the highest-risk areas of this implementation? (new integrations, auth flows, financial data, data migrations, third-party dependencies)
10. [REQUIRED] What does a production incident for this feature look like? (worst case scenario)
11. [REQUIRED] Which existing features could this change break? (regression risk)

**Production:**
12. [REQUIRED] What metrics and logs will confirm the feature is healthy in production?
13. [REQUIRED] What is the rollback trigger? (specific condition that means "roll this back immediately")
    - G2 re-ask: "Complete this: 'If we observe [X] in production, we roll back immediately.' What is X? Example: 'error rate on /checkout exceeds 0.5% for 5 minutes'."

---

## Output Document Schema

```
# Test Plan: [Feature Name]
Status: Draft
Author: [from context]
Date: [today's date]
LLD Reference: [path or "provided in session"]
Task Document Reference: [path or "provided in session"]

## Scope
**In scope:** [which stories and components]
**Out of scope:** [explicitly excluded areas]

## Test Environments
| Environment | Purpose | Who Has Access |
|-------------|---------|----------------|

---

## Testing Layers

### Unit Tests
**Owner:** [named individual or role]
**Framework:** [name]
**Coverage target:** [% or "match existing project standard"]

**Key areas to cover:**
- [Component or function with significant logic complexity]
- [Edge cases from PRD acceptance criteria]

### Integration Tests
**Owner:** [named individual or role]
**Framework:** [name]

**Key scenarios:**
- [Service-to-service call: what is verified]
- [Database interaction: what is verified]
- [External API call: what is verified and how is it mocked]

### End-to-End Tests
**Owner:** [named individual or role]
**Framework:** [Playwright / Cypress / other]

**Critical user flows to cover:**
- [Flow name]: [starting point] -> [ending point]

### Manual Test Cases
**Owner:** [named individual - not a team]
**When to run:** [before each release / after major changes / on-demand]

| ID | Scenario | Preconditions | Steps | Expected Result | Priority |
|----|----------|---------------|-------|-----------------|----------|
| TC-001 | [scenario name] | [what must be true before] | 1. [step] 2. [step] | [what should happen] | P0/P1/P2 |

### Load / Performance Tests
**Owner:** [named individual or "N/A if not in scope"]
**Tool:** [k6 / Locust / other]
**Targets (from PRD NFRs):** [specific targets]
**When to run:** [before release / on major infrastructure changes]

---

## Edge Cases and Negative Tests
[Scenarios specifically testing failure conditions, boundary values, and error handling]

| Test | Condition | Expected Behavior |
|------|-----------|-------------------|

---

## Regression Risk Matrix
| Affected Area | Risk Level | Why at Risk | Test Coverage |
|---------------|-----------|-------------|---------------|
| [feature/component] | High/Med/Low | [what this change could break] | [unit/integration/manual/none] |

---

## Production Validation
**Metrics to monitor post-deploy:**
- [metric name]: [what value indicates healthy]
- [metric name]: [what value indicates healthy]

**Alerts to configure:**
- [condition]: alert [who] via [channel]

**Rollback trigger:**
If [specific observable condition], roll back immediately by [specific mechanism].

---

## Exit Criteria
All of the following must be true before this feature ships:
- [ ] All P0 manual test cases passing - signed off by [named individual]
- [ ] All P1 manual test cases passing - signed off by [named individual]
- [ ] Unit test coverage at or above [target]%
- [ ] Integration tests passing in staging environment
- [ ] Zero open P0 bugs
- [ ] Zero open P1 bugs
- [ ] Load test targets met: [specific targets]
- [ ] Monitoring alerts configured and verified
- [ ] Rollback mechanism tested in staging
```

**Quality bar per section:**

- P0 test cases: every one has a named individual who signs off. "QA team signs off" fails.
- Exit criteria: each criterion is binary. A third party must be able to verify it without asking the team.
- Rollback trigger: a specific observable condition, not "if there are problems". Must be automatable into an alert.
- Regression risk: must not be empty. Every change has potential regression surface - at minimum, list the components this code touches.

**Inline self-evaluation before phase gate:**
- [ ] Every P0 test case has a named individual owner
- [ ] Rollback trigger is a specific observable condition
- [ ] All exit criteria are objectively verifiable
- [ ] Regression risk matrix is non-empty
- [ ] Monitoring metrics listed
- [ ] Count any [REQUIRED: ...] placeholders

---

## Phase Gate

Display the completed Test Plan, then show:

```
Test Plan complete.

Evaluation:
- Manual test cases: [N] (P0: [N], P1: [N], P2: [N])
- P0 cases with named individual owners: [N of N]
- Exit criteria: [N] (all objectively verifiable: yes/no)
- Rollback trigger: defined / MISSING
- Regression risk areas: [N]
- Placeholders remaining: [N]

This is the final phase of the product lifecycle.
The full spec package is now complete:
[list all approved artifacts]

Type APPROVE to finalize the Test Plan, or tell me what to revise.
```

If running standalone: "Share this with QA and engineering leads for sign-off before implementation begins."
