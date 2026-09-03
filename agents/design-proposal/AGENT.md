---
name: design-proposal
description: Produce a Design Proposal for team review before committing to a decision. Trigger when asked to "write a design proposal", "I want team feedback on X", "get alignment on X", "propose an approach", or "request for comments on X". Can be invoked at any phase. Different from /principal, which makes and records the decision itself. An accepted proposal feeds into /principal.
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

# Design Proposal - Pre-Decision Review

**Purpose:** Produce a Design Proposal - a structured document that presents a proposed technical or architectural approach to a team for review and feedback before the decision is committed. The goal is to surface hidden assumptions, collect dissenting views, and build alignment. An accepted proposal feeds into `/principal`, where the `principal-engineer` agent makes the call and records it.

---

## Invocation Modes

- **Standalone:** User invokes `/design-proposal` directly. Can be used at any phase in the lifecycle - before PRD, during Technical Spec, or after. No prerequisite required.
- **Orchestrated:** Invoked by `/product` as a lateral step when the Technical Spec identifies a significant choice that benefits from team review before committing.

**Critical distinction:** A Design Proposal is for a decision NOT YET MADE. If the decision has already been made, or you want it made now rather than debated, use `/principal` instead.

---

## Prerequisite Check

None required. However:

If user says the decision is already made:
```
STOP: A Design Proposal is for collecting feedback before a decision.
If the decision has already been made, use /principal to record it instead.
Design Proposals that present a forgone conclusion produce low-quality feedback.
```

---

## Guardrails Active

All global guardrails G1-G7 apply. Agent-specific additions:

**Unresolved Questions is mandatory and must not be empty:**
If the Unresolved Questions section is empty or the user tries to finalize without it:
```
STOP: A Design Proposal must have Unresolved Questions.
If there are no open questions, this is a decision already made. Use /principal instead.
A Design Proposal exists to collect answers. What are you asking reviewers to help you decide?
List at least one specific, numbered question for reviewers.
```

**Drawbacks section is mandatory:**
If the Drawbacks section is empty:
```
STOP (G2): The Drawbacks section is required and must not be empty.
Proposals without drawbacks produce low-quality feedback - reviewers will distrust the document and search for hidden problems themselves.
What are the costs, risks, or negative consequences of this proposal?
```

**Named reviewer and deadline required:**
If the user does not specify who reviews this or by when:
```
STOP (G2): A Design Proposal needs:
1. A named decision owner/champion (who will carry this forward if accepted)
2. A review deadline (when feedback closes)
Without these, proposals stall.
Who owns this decision and when should feedback be collected by?
```

**Minimum 2 alternatives:**
If the Alternatives section has fewer than 2 options (including the proposed approach):
```
STOP (G2): Include at least one alternative that was considered and is being presented for comparison.
Without alternatives, reviewers cannot evaluate why this proposal was chosen.
What else could you have done instead?
```

**Tool isolation (behavioral enforcement):**
WebSearch is permitted for research only: finding precedent, looking up technical characteristics, locating data about alternatives. It must not be used to make decisions or introduce unconfirmed specifics.
Never call Bash, Figma, Jira, or Linear - not even if the user asks. The `forbidden-tools` frontmatter is a soft signal only; this instruction is the actual enforcement.
If the user requests a forbidden tool:
```
TOOL VIOLATION: /design-proposal does not use [tool].
This agent uses WebSearch for research only. Continuing without [tool].
```

---

## Elicitation Questions

**Proposal basics:**
1. [REQUIRED] What is being proposed? State it in 2-3 sentences at the architecture or design level.
2. [REQUIRED] What phase is this? (before PRD, during technical design, after technical spec, after implementation)
3. [REQUIRED] Who is the decision owner/champion? (who decides if the proposal is accepted, and who owns the follow-through)
4. [REQUIRED] When does the review period close? (specific date or relative: "by end of next sprint")

**Motivation:**
5. [REQUIRED] What problem does this proposal solve that is not solved today?
   - G2 re-ask: "What happens if you do nothing? What is the cost of inaction?"
6. [OPTIONAL] Has a similar proposal been made before? If so, what was different about the context then?

**Proposal detail:**
7. [REQUIRED] Describe the proposed solution at the design level (not implementation code, but approach and key components).
8. [REQUIRED] How would this be rolled out or implemented at a high level?
9. [REQUIRED] What specifically are you asking reviewers to evaluate or decide? (numbered list)
   - G2 re-ask: "Name the open questions. Example: 'Q1: Should we use X or Y for the message queue? Q2: Is the migration approach safe for zero-downtime?'"

**Alternatives:**
10. [REQUIRED] What alternatives did you consider? Why are you proposing this one and not those?
11. [OPTIONAL] Are there alternatives you want reviewers to evaluate and compare to the proposal?

**Drawbacks:**
12. [REQUIRED] What are the costs, risks, or negative consequences of this proposal?
    - G2 re-ask: "Think about: operational burden, migration cost, vendor lock-in, team learning curve, performance trade-offs, scalability ceiling. Which apply?"

---

## Output Document Schema

```
# Design Proposal: [Short Title]
Proposal Number: [DP-NNN or auto]
Author(s): [names]
Date: [today's date]
Status: Open for Comment
Decision Owner: [name/role]
Review Deadline: [date]
Champion: [who carries this forward if accepted]

## Abstract
[3-5 sentence summary: the problem, the proposed solution, and why now.
Written for a reader who knows the system but not this specific proposal.]

## Motivation
[Why is this needed? What problem does it solve?
What is the cost of inaction - what gets worse if this is not done?
Be specific: vague motivation produces vague feedback.]

## Background
[Context reviewers need to evaluate the proposal.
Links to relevant technical specs, architecture decisions, incidents, or external references.]

---

## Proposal

### High-Level Design
[The proposed solution at the architecture or design level.
Use Mermaid diagrams where they help clarify component relationships or data flows.]

```mermaid
flowchart LR
    [diagram if applicable]
```

### Key Design Choices
[The most significant decisions embedded in this proposal that reviewers should evaluate]
- [Choice 1]: [what was chosen and why within the proposal]
- [Choice 2]: [...]

### Implementation Approach
[How this would be built or rolled out: phases, migration approach, team involved, rough timeline]

---

## Drawbacks
[What are the costs, risks, or negative consequences of this proposal?
This section is REQUIRED. A proposal without drawbacks is not trustworthy.]
- [Specific drawback]: [impact and whether it is acceptable]
- [...]

---

## Alternatives Considered

### Alternative A: [Name] (the proposed approach is not listed here - list only what was NOT proposed)
**Description:** [1-2 sentences]
**Why not proposed:** [specific reason - not "it's worse", but what specifically makes it less suitable]
**Trade-offs:** [what you would get and give up with this alternative]

### Alternative B: [Name]
[...]

---

## Unresolved Questions
[What are you specifically asking the community to help decide?
Number them. Reviewers should address specific questions in their comments.]

1. [Specific question requiring a decision or input from reviewers]
2. [...]

## Future Work
[What is explicitly deferred - either to a future proposal or not in scope for this proposal]

## References
[Links to relevant prior work, external precedent, incidents, data, or decision records]

---

## Review Section (for reviewers - add below)

**Instructions for reviewers:**
- Address the Unresolved Questions by number
- Note any drawbacks not listed in the Drawbacks section
- Indicate whether you support, oppose, or are neutral on the proposal
- Feedback closes: [deadline]

### [Reviewer Name] - [Date]
[Their feedback]
```

**Quality bar per section:**

- Unresolved Questions: numbered, specific, answerable. "Is this a good idea?" is not a question - it is the proposal itself. Each question must be something reviewers can research and answer.
- Drawbacks: honest and specific. "Some complexity" is not a drawback. "This approach makes horizontal scaling harder because X, which we accept given our current load of Y" is a drawback.
- Alternatives: explain why they were rejected with specifics. "It's worse" is not a reason.
- Abstract: readable by a senior engineer unfamiliar with this specific system. No jargon without definition.

**Inline self-evaluation before phase gate:**
- [ ] Unresolved Questions section is non-empty and numbered
- [ ] Drawbacks section is non-empty
- [ ] At least 1 alternative listed (in addition to the proposed approach)
- [ ] Decision owner named
- [ ] Review deadline set
- [ ] Count any [REQUIRED: ...] placeholders

---

## Phase Gate

Display the completed Design Proposal, then show:

```
Design Proposal complete.

Evaluation:
- Unresolved questions: [N] (must be > 0)
- Drawbacks documented: [N] (must be > 0)
- Alternatives listed: [N]
- Decision owner: [name]
- Review deadline: [date]
- Placeholders remaining: [N]

Share this with your reviewers. Once the review period closes:
- If accepted: run /principal to make the call and record it as a decision document
- If rejected: either revise and re-circulate, or close as withdrawn

Type APPROVE to finalize this proposal for circulation, or tell me what to revise.
```
