---
name: product-requirements
description: Produce a Product Requirements Document (PRD) from a Discovery Brief. Trigger when asked to "write a PRD", "define the requirements", "product requirements for X", or "what must this product do". Prerequisite - Discovery Brief (Approved). Part of the product family and its final phase. Chain to /principal next, which decides the technical approach.
metadata:
  author: anurag
  version: "1.0.0"
  allowed-tools:
    - Read
    - Write
    - AskUserQuestion
    - WebSearch
  forbidden-tools:
    - Bash
    - Figma
    - Jira
    - Linear
    - Edit
---

# Product Requirements - PRD

**Purpose:** Produce a PRD - the binding contract between product and engineering that defines what must be built, for whom, and how to know it is done. This document must be specific enough that two engineers could build independently and produce compatible results.

---

## Invocation Modes

- **Standalone:** User invokes `/product-requirements` directly. Checks for Discovery Brief. If none provided, stops and requests it (G1).
- **Orchestrated:** Invoked by `/product` after Discovery Brief is Approved. Context (problem statement, personas, success criteria, constraints) is passed in - do not re-ask questions already answered.

---

## Prerequisite Check

**Required:** A completed Discovery Brief (status: Approved or provided by user).

If missing:
```
STOP: A Discovery Brief is required before writing a PRD.
I need to understand: who has the problem, what they experience, and what success looks like.
Run /discovery first, or paste your Discovery Brief here.
```

If provided but incomplete (missing problem statement or personas): list exactly what is missing and stop.

---

## Guardrails Active

All global guardrails G1-G7 apply, as defined in the `code-writing` skill. Skill-specific additions:

**Vague phrase detector (triggers G2 immediately):**
If any acceptance criterion contains these words, stop on that criterion before continuing:
- fast, slow, quick, faster
- easy, easier, simple, seamless, smooth, frictionless
- intuitive, user-friendly, delightful
- better, improved, enhanced, good
- robust, reliable, stable (without a numeric SLA attached)
- "should work", "should feel"

When triggered:
```
STOP: "[phrase]" in an acceptance criterion is not testable.
Re-ask: What specific, measurable behavior is required here?
Example of an acceptable criterion: "Page loads in under 1.5 seconds measured at First Contentful Paint on a 4G connection."
```

**Binary test rule:**
Every acceptance criterion must be pass/fail evaluable by a person who has never spoken to the product team. If evaluating requires judgment, the criterion must be rewritten.

**Tool isolation (behavioral enforcement):**
WebSearch is permitted for benchmarking only (e.g., "what is industry-standard p95 for checkout pages"). It must not be used to make product decisions or infer missing specifics.
Never call Bash, Figma, Jira, or Linear - not even if the user explicitly asks. The `forbidden-tools` frontmatter is a soft signal only; this instruction is the actual enforcement.
If the user requests a forbidden tool:
```
TOOL VIOLATION: /product-requirements does not use [tool].
This skill uses WebSearch for benchmarking only. Continuing without [tool].
```

---

## Elicitation Questions

Grouped by output section. Skip any question already answered in the Discovery Brief context.

**User journey (for User Stories section):**
1. [REQUIRED] Walk me through the user journey step by step from trigger to completion. What does the user do first, then what?
   - G2 re-ask: "Start with: 'The user lands on [page/screen]...' and describe each step they take."
2. [REQUIRED] What are the edge cases in that flow? (empty states, errors, unauthenticated access, mobile vs desktop, slow network)
3. [REQUIRED] Are there multiple user types with different views or permissions for this feature?

**Functional requirements:**
4. [REQUIRED] What must the system do? List each capability as a testable statement starting with "The system must..."
5. [REQUIRED] What must the system NOT do? (negative requirements - behaviors to explicitly prevent)
6. [OPTIONAL] Are there any modes or states? (e.g., trial vs paid plan, feature flag on/off, admin vs standard user)

**Non-functional requirements:**
7. [REQUIRED] Performance: what are the latency expectations? Under what load?
   - G2 re-ask: "Give me a number. Example: p95 response time under 300ms at 1,000 concurrent users."
8. [REQUIRED] Availability: is there an uptime SLA?
   - G2 re-ask: "Example: 99.9% uptime, or 'same SLA as the rest of the platform'."
9. [REQUIRED] Security and data: what is the sensitivity classification of data involved? Any auth requirements specific to this feature?
10. [OPTIONAL] Accessibility: is there a WCAG target level?

**Dependencies:**
11. [OPTIONAL] Does this depend on any other team's work completing first?
12. [OPTIONAL] Does this change any existing feature's behavior? What backward compatibility is required?

---

## Output Document Schema

```
# Product Requirements Document: [Feature Name]
Status: Draft
Author: [from context or "product session"]
Date: [today's date]
Discovery Brief: [reference or "provided in session"]

## TL;DR
[2-3 sentence executive summary. What is being built, for whom, and why now.]

## Background
[Summary of problem from Discovery Brief. Link or paste if available.]

## Goals
1. [Measurable goal tied to a success criterion]
2. [...]

## Non-Goals
- [Explicit list of what this PRD does NOT address]

## User Stories

### [Persona Name]
As a [specific persona], I want to [action], so that [outcome].

**Acceptance Criteria:**
- [ ] [Binary, testable criterion]
- [ ] [Binary, testable criterion]
- [ ] [Binary, testable criterion - minimum 3 per story]

[Repeat for each user story]

## Functional Requirements

### Must Have
1. The system must [testable statement].
2. [...]

### Should Have
1. The system should [testable statement].
2. [...]

### Will Not Have (This Release)
1. [Explicit deferrals]

## Non-Functional Requirements
- Performance: [specific numeric target and conditions]
- Availability: [uptime SLA]
- Security: [data sensitivity, auth requirements]
- Accessibility: [WCAG level or "N/A"]

## Dependencies
- [Team/system] must complete [what] before [which part of this feature] can begin.
- [Or: "No external dependencies identified."]

## Success Metrics
- [30 days post-launch]: [what metric, what target]
- [60 days post-launch]: [what metric, what target]

## Open Questions
[Numbered list with owner. Or: "None."]

## Revision History
| Date | Author | Change |
|------|--------|--------|
| [today] | [from context] | Initial draft |
```

**Quality bar per section:**

- Every acceptance criterion: binary. Can be verified by someone with no product context.
- NFRs: every field has a number or explicit SLA. "TBD" = G2 on that field.
- Non-Goals: must not be empty. "What are you deliberately not building here?"
- Success Metrics: tied to goals. If a goal has no metric, ask for one.

**Inline self-evaluation before phase gate:**
- [ ] Every user story has 3+ acceptance criteria
- [ ] No acceptance criterion contains vague phrases
- [ ] All NFRs have numeric targets or explicit SLAs
- [ ] Non-Goals section is populated
- [ ] Success Metrics are measurable and time-bound
- [ ] Count any [REQUIRED: ...] placeholders

---

## Phase Gate

Display the completed PRD, then show:

```
Product Requirements Document complete.

Evaluation:
- User stories: [N] (all have 3+ acceptance criteria: yes/no)
- Vague phrases detected: [list any, or "none"]
- NFRs with numeric targets: [N of N]
- Placeholders remaining: [N]

Type APPROVE to proceed to Technical Spec, or tell me what to revise.
```

If running standalone: "Next step: run /principal with this PRD to decide the technical approach, or /sdlc to run it through to release."
