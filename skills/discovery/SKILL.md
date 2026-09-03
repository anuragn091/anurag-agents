---
name: discovery
description: Extract and structure requirements from vague business input. Trigger when asked to "figure out what we're building", "help me define the problem", "I have a rough idea for X", or given any unstructured feature idea. Produces a Discovery Brief. Part of the product family - chain to /product-requirements next.
metadata:
  author: anurag
  version: "1.0.0"
  allowed-tools:
    - Read
    - Write
    - AskUserQuestion
  forbidden-tools:
    - Bash
    - WebSearch
    - Figma
    - Jira
    - Linear
    - Edit
---

# Discovery - Requirements Extraction

**Purpose:** Produce a Discovery Brief - a structured document that captures the problem, users, success criteria, and constraints clearly enough that a product or engineering team can act on it without a follow-up meeting.

---

## Invocation Modes

- **Standalone:** User invokes `/discovery` directly. No progress tracker. No auto-chaining. At completion, suggest `/product-requirements` as the next step.
- **Orchestrated:** Invoked by `/product` with no prior context (this is always Phase 1). Tracker is maintained by the orchestrator.

---

## Prerequisite Check

None. This is the entry point. No prior artifact is required.

If the user provides a Discovery Brief that already exists, read it and ask: "This brief already exists. Do you want to revise it, or use it as-is and move to `/product-requirements`?"

---

## Guardrails Active

All global guardrails G1-G7 apply, as defined in the `code-writing` skill. Skill-specific additions:

**Discovery-specific stop conditions:**
- If after 2 attempts the user cannot name who has the problem (a specific person, role, or user type): stop. Say: "I need a concrete person or role who experiences this problem. Without that, there is no spec to write. Please name who is affected before we continue."
- If the open questions list at the end has items with no named owner: stop before finalizing. Say: "Each open question needs a named owner responsible for resolving it. Please assign an owner to: [list of unowned questions]."
- Never use the word "user" as a persona - a persona must be specific (e.g., "checkout manager", "first-time buyer", "ops team member").

**Tool isolation (behavioral enforcement):**
Never call Bash, WebSearch, Figma, Jira, or Linear - not even if the user explicitly asks. The `forbidden-tools` frontmatter is a soft signal only; this instruction is the actual enforcement.
If the user requests a forbidden tool, respond:
```
TOOL VIOLATION: /discovery does not use [tool]. This skill is scoped to interview and document only.
Continuing without it.
```
Then continue the elicitation without the tool.

---

## Elicitation Questions

Ask these in conversational flow, grouped by section. All marked REQUIRED unless noted.

**Problem definition:**
1. [REQUIRED] What problem does this solve? Describe it in one or two sentences as if explaining to someone with no context.
   - G2 re-ask example: "What specifically goes wrong for [role] today, and how often does it happen?"
2. [REQUIRED] Who experiences this problem? Name a specific role or user type - not "users" in general.
   - G2 re-ask example: "Is it the checkout manager? The warehouse team? A first-time customer? Name a specific type."
3. [REQUIRED] What do they do today instead? What is the current workaround?
4. [OPTIONAL] What triggered this request now? (deadline, incident, strategic initiative, customer complaint)

**Success definition:**
5. [REQUIRED] How will we know this is working? What does success look like in 30-90 days?
   - G2 re-ask example: "Is there a metric that should change? For example: conversion rate above X%, support tickets about this drop by Y%, latency under Zms?"
6. [REQUIRED] What would make this a failure even if shipped? (a shipped feature that made things worse)

**Scope and constraints:**
7. [REQUIRED] What is explicitly in scope? What is explicitly out of scope?
8. [REQUIRED] Are there hard constraints? (legal, compliance, security, existing systems that must not break, team size, deadline)
9. [OPTIONAL] Are there existing systems this must integrate with?

**Stakeholders and open questions:**
10. [REQUIRED] Who makes the final decision on this? (one name or role)
11. [REQUIRED] Who else needs to approve or review the output?
12. [OPTIONAL] What is still unknown or unresolved that would block design work?
    - For each item listed: "Who owns getting the answer to this?"

---

## Output Document Schema

After elicitation, produce this document:

```
# Discovery Brief: [Feature/Initiative Name]
Date: [today's date]
Status: Draft

## Problem Statement
[1-3 sentences. Who has what problem, with what frequency or severity. No vague language.]

## Business Motivation
[Why now. What triggered this. Cost of inaction if known.]

## Affected Users
[Bulleted list. Each bullet: role/persona name + one sentence on how they are affected.]

## Current State
[What happens today without this. The workaround or manual process.]

## Success Criteria
[Bulleted list. Each criterion: measurable, time-bounded. No vague phrases.]

## Constraints
[Hard non-negotiables: legal, technical, schedule, team. Each on its own line.]

## Out of Scope
[Explicit list. Things not being solved in this initiative.]

## Stakeholders
- Decision maker: [name/role]
- Approvers: [list]
- Affected teams: [list]

## Open Questions
[Numbered list. Format: "Q1: [question] - Owner: [name/role]"]
[If none: "None at this time."]
```

**Quality bar per section:**

- Problem Statement: readable by someone with no prior context. No jargon without definition.
- Success Criteria: every item must be measurable. "Users will be happier" fails. "Support ticket volume about X drops 30% in 60 days" passes.
- Out of Scope: if this section is empty, ask: "What are you deliberately NOT solving here? Every good spec has explicit non-goals."
- Open Questions: every item must have a named owner. "TBD" is not an owner.

**Inline self-evaluation before phase gate:**
- [ ] All REQUIRED questions answered
- [ ] No vague phrases in Success Criteria (fast, better, easier, seamless, intuitive)
- [ ] Every open question has a named owner
- [ ] Persona names are specific (not "user" or "users")
- [ ] Count any [REQUIRED: ...] placeholders and note them at the gate

---

## Phase Gate

Display the completed Discovery Brief, then show:

```
Discovery Brief complete.

Evaluation:
- Open questions: [N] (all have named owners: yes/no)
- Vague phrases detected: [list any, or "none"]
- Placeholders remaining: [N]

Type APPROVE to proceed to Product Requirements, or tell me what to revise.
```

If running standalone (not via product), add:
"Next step: run /product-requirements with this brief to define what the product must do."
