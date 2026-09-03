---
name: sdlc
description: Full lifecycle, idea to production. Requirements, then the engineering ladder (principal-engineer decides, senior-engineer specs, sde2-engineer and sde1-engineer build), then dev testing, QA testing, and release. Trigger on "take this from idea to production", "full SDLC for X", "build and ship X". Starts at whichever stage your input lands on.
metadata:
  author: anurag
  version: "2.0.0"
---

# SDLC - idea to production

Six stages. Each has an owner and a gate. Nothing advances without an explicit go from the user.

This skill routes and gates. It does not produce documents or code itself.

## Stage map

| # | Stage | Owner | Output |
|---|---|---|---|
| 1 | Requirements | `/product` | Discovery Brief, PRD |
| 2 | Decide | `/principal` → `principal-engineer` | decision doc |
| 3 | Spec | `/senior` → `senior-engineer` | HLD, LLD |
| 4 | Break down | `sde2-engineer` | task document |
| 5 | Build | `/dispatch` → `sde2-engineer` + `sde1-engineer` | code, unit tests |
| 6a | Dev testing | this skill | green suite, reviewed diff |
| 6b | QA testing | `/test-plan` | test results, exit criteria met |
| 7 | Release | `/deploy` | shipped |

Stages 2 to 5 are the engineering ladder. Each rung runs on its own model tier.

## Where to start

Work out which stage the input lands on. Say which and why before doing anything. Never re-run a stage whose artifact already exists.

- A rough idea, a business problem, no PRD → stage 1
- A PRD or product brief → stage 2
- A decision doc or ADR → stage 3
- An HLD or LLD → stage 4
- A task document → stage 5
- Code already written → stage 6

## Stage 1: Requirements

Run `/product`. It takes a vague idea through discovery to an approved PRD and stops there.

Skip if a PRD already exists.

**Gate.** Show the PRD. The user approves, revises, or stops.

## Stage 2: Decide

Run `/principal` against the PRD. The `principal-engineer` agent, on Opus, gathers constraints and produces a decision document with the reasoning, the trade-off accepted, the reversal cost, and the revisit triggers.

**Gate.** Show the decision, the one reason it won, and what is being given up.

## Stage 3: Spec

Run `/senior` against the approved decision doc. The `senior-engineer` agent, on Opus, produces an HLD and an LLD for a large feature, or one combined document for a medium one.

**Gate.** Run the LLD completeness check before showing it. Reject back to the agent on any TBD language, untyped field, ambiguous unit, one concept under two names, or single-caller abstraction. Then show the file plan and build order.

## Stage 4: Break down

Spawn `sde2-engineer` with the LLD. It returns ordered tasks by layer, each with a file list, dependencies, a parallel-safe flag, an owner, and a definition of done.

**Gate.** Show the task table, the parallel groups, and the SDE-1 versus SDE-2 split. The user may move tasks up or down a rung.

## Stage 5: Build

Run `/dispatch` against the task document. SDE-2 spawns SDE-1 agents in waves and checkpoints every result to disk.

If it stops with work remaining, that is the expected outcome on a large feature, not a failure. Re-run `/dispatch` and say how many tasks are left.

**Gate.** Report what landed, what the tests cover, what is blocked. Route blockers up: a spec gap to `senior-engineer`, a decision gap to `principal-engineer`.

## Stage 6a: Dev testing

The tests written during stage 5 prove each unit works. This stage proves the system still works.

1. Run the full test suite. Not just the new tests, the whole thing. Regressions live in code nobody touched.
2. Run the linter and the type checker. Both must be clean.
3. Check coverage on the changed paths only. A global percentage tells you nothing useful.
4. Find what the unit tests missed: the seams between tasks, the paths that cross two agents' work, the error branches nobody exercised.
5. On failures, run `/fix-tests`. Fix the code when the code is wrong. Fix the test when the test is wrong. Never delete a failing test to get green.
6. Run `/code-review` on the full diff.
7. Run `/security-review` if the change touches auth, user input, file upload, external calls, or personal data.

**Gate.** Paste actual output, not a summary. If something failed, say so and show it. Do not advance on a red suite.

## Stage 6b: QA testing

Different question from dev testing. Dev testing asks whether the code works. QA asks whether the feature is right.

Run `/test-plan` against the LLD and the task document. It produces the manual test cases, the edge cases worth a human's attention, and objective exit criteria.

Then execute it:

1. **Never start a server.** Give the user the command and ask them to run it. This rule is absolute.
2. Walk the primary user flow end to end.
3. Walk the failure flows: bad input, expired session, network dropped mid-request, duplicate submit, empty state, very large input.
4. Check what the PRD asked for, not what the LLD built. This is where scope drift surfaces.
5. Record every case as pass or fail with what was actually observed.

**Gate.** Show the results against the exit criteria. Every P0 case passes or the feature does not ship. A failed case goes back to stage 5 as a new task, not a quick patch.

## Stage 7: Release

Run `/deploy`.

Before it runs, confirm out loud:
- The suite is green and the diff is reviewed
- Every P0 QA case passed
- Migrations are ordered and reversible, or the irreversibility is acknowledged
- The feature flag state is intentional
- The rollback path is known and someone has read it

**Gate.** Deployment is outward facing and hard to undo. Get an explicit yes from the user immediately before it runs. Approval given at an earlier stage does not carry forward to this one.

## Rules for the whole run

- **Never skip a gate.** If the user is not answering, stop and wait. Do not proceed on a guess.
- **Never let a stage do another stage's job.** If `senior-engineer` starts deciding architecture, or `sde1-engineer` starts inventing design, send it back up.
- **Carry the number.** ADR 0007 produces `0007-slug-hld.md`, `0007-slug-lld.md`, `0007-slug-tasks.md`, `0007-slug-test-plan.md`.
- **Escalate gaps upward, never sideways.** Nobody fills a gap by guessing at their own level.
- **Report honestly.** Failed tests get pasted. Skipped steps get named.

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
