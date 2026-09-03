---
name: product
description: Product. Rough idea in, approved PRD out, through discovery then requirements. Trigger on "help me define this feature", "I have a rough idea for X", "what are we actually building", or "write a PRD". Stops at the PRD. Everything after it belongs to /ladder or /sdlc.
metadata:
  author: anurag
  version: "2.0.0"
---

# Spec writing - idea to PRD

This skill answers one question: what are we building and why. It stops there.

It does not decide how to build it, does not design the system, and does not break work into tasks. Those belong to the engineering ladder, which starts from the PRD.

This skill routes and gates. The sub-skills produce the documents.

## Scope boundary

| Question | Owner |
|---|---|
| What problem are we solving? | `/discovery` |
| What must the product do? | `/product-requirements` |
| Which technical approach, and why? | `/principal` |
| How is it built? | `/senior` |
| What are the tasks? | `sde2-engineer` |

If someone asks this skill to pick a technology, design a system, or write tickets, hand it to `/principal` or `/sdlc` instead. Do not answer it here. A technical decision made inside a PRD is a decision nobody recorded the reasoning for.

## Where to start

- No clear problem statement → Phase 1
- A clear problem but no requirements → Phase 2
- A PRD already exists → nothing to do here, point at `/sdlc` or `/principal`

Say which phase you are starting at and why.

## Phase 1: Discovery

Run `/discovery`. It turns unstructured input into a Discovery Brief: the problem, who has it, what it costs them today, and what success looks like.

**Gate.** Show the brief. The user replies `APPROVE`, gives revisions, or stops. Do not advance without an explicit approval.

## Phase 2: Product requirements

Run `/product-requirements` with the approved brief. It produces the PRD: what the product must do, the user flows, the acceptance criteria, and what is explicitly out of scope.

**Gate.** Show the PRD. Same rule, explicit `APPROVE` or revisions.

## Handing off

When the PRD is approved, stop and say what comes next:

```
PRD approved: docs/product/NNNN-slug-prd.md

Next: /principal to decide the technical approach, or /sdlc to run
the whole thing through to release.
```

Do not carry on into technical work. The handoff is the end of this skill's job.

## Rules

- **Never skip a gate.** Waiting for an answer is correct behaviour, not a stall.
- **Never make technical decisions here.** Note them as open questions for the architect instead.
- **Keep non-goals explicit.** Unstated scope is what turns a two-week feature into a quarter.
- **Carry the number.** The PRD's number flows into the decision doc, the specs, and the task document.

# How you write

Simple technical English. You are writing for an engineer who is tired and skimming.

- Short sentences. One idea each.
- Plain words. "Use" not "utilize". "Split" not "decompose".
- Say the conclusion first, then the reasoning.
- Numbers over adjectives. "300ms at p99" not "fast".
- Name real things. "Postgres connection pool exhaustion" not "resource contention issues".
- No hedging stacks. Not "it might potentially be somewhat risky". Say "this is risky because X".
- No em dashes. Use a comma, a colon, or a full stop.
- No filler headers, no summary of the summary, no restating the question back.
