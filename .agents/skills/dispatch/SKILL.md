---
name: dispatch
description: SDE-2 and SDE-1. Task document in, working code and tests out. SDE-2 dispatches junior agents in waves and checkpoints every result to disk, so a crashed or interrupted run resumes instead of restarting.
metadata:
  author: anurag
  version: "1.0.0"
---

Task document: $ARGUMENTS

This command builds what a task document describes, and resumes a run that stopped for any reason.

## Step 1: Find the task document

- If a path was given, read it.
- If not, look in `docs/specs/`, `docs/design/`, `docs/` for `*-tasks.md` and take the most recent. If several could match, ask which.
- If none exists, there is nothing to dispatch. Point the user at `sde2-engineer` with the LLD to produce one first.

## Step 2: Report the current state before doing anything

Count the tasks by status and show it. The user needs to know what they are resuming into.

```
Tasks: 12 total | 5 done | 1 in_progress | 2 blocked | 4 todo
```

Anything still marked `in_progress` is a task that was running when the last run stopped. It is not trustworthy. For each one:

1. Check the repository for what actually landed: `git status`, `git diff`, and the files in that task's list.
2. If the work is complete and the done conditions hold, mark it `done` on disk.
3. If it is half finished, reset it to `todo` and note in `Result` what partial work exists so the next agent knows what it is walking into.

Never leave a task sitting in `in_progress` at the start of a run.

## Step 3: Hand off to SDE-2

Spawn `sde2-engineer` with `run_in_background: false`, in dispatch mode. Pass it:

- The path to the tasks document
- The path to the LLD it came from
- The reconciliation you did in step 2
- An instruction to run the wave loop and checkpoint every result to disk

SDE-2 spawns the `sde1-engineer` agents itself. That is by design: the junior reports stay inside SDE-2's context instead of flooding this conversation, and SDE-2 stays responsible for reviewing its own juniors' work.

## Step 4: When SDE-2 comes back

It returns for one of three reasons. Handle each differently.

**Everything done.** Report what landed, the test results, and anything flagged. Confirm the tasks document shows no remaining `todo`.

**Stopped cleanly, work remaining.** SDE-2 ran out of room and checkpointed. This is the expected outcome on a large feature, not a failure. Report progress and re-run this command. State how many tasks remain so the user can see it converging.

**Blocked.** Something could not be built as specified. Report the blocker and route it up: a spec gap goes to `senior-engineer`, a decision gap goes to `principal-engineer`. Never fill the gap yourself and never let SDE-2 guess past it.

## Rules

- **The disk is the truth, not this conversation.** Re-read the tasks document at every decision point. It may have moved since you last looked.
- **Never run two tasks that share a file.** SDE-2 checks this, verify it did.
- **Never mark a task done without checking its done conditions.** A report saying "complete" is a claim, not evidence.
- **Report failures with the actual output.** If tests failed, paste them.
- **One task, one PR, opened as the task finishes.** Never batch a wave or a stage into a single PR. Each task branches off the previous task's branch and stacks; the first branches off the stage base. When a base merges, rebase what sits above it.
- **Never open a PR you already know is wrong.** If a decision changes after a task commits, fix it on that task's branch and rebase the stack. Shipping a known-wrong change to be corrected in a later PR wastes review time and puts a wrong commit in the history permanently.
- **A completed task is not delivered until its PR is open.** When you report progress, report PR links, not just task ids.

## Parallel branches cannot see each other

When you dispatch several tasks at once, each branches from the same tip. **None of them contains any of the others' work.** That is inherent to fanning out, not a mistake you can prompt your way out of.

It bites in two ways, and both have a cost:

- **A task needs a sibling's output.** It hits an `ImportError`, or a model that does not exist, and either stops or works around it. A good agent stops and reports; a less careful one invents a local duplicate, which is worse, because the duplicate compiles.
- **A task tests against something a sibling deletes.** Both are individually correct. The breakage appears only when they are ordered.

**Before dispatching, check the dependency against the actual base**, not against the task document. "Task X depends on task Y, and Y is done" is not the same as "Y's code is on the branch X will start from".

**Do not bulk-rebase while agents are running.** Rebasing a branch someone is working on moves `HEAD` under them. Even rebasing idle branches invites conflicts in shared files, and a conflict mid-run leaves the tree in a state the running agents will trip over. Linearise when the queue is empty, once, deliberately.

The workable rhythm: **fan out on genuinely independent work, linearise when it drains, then fan out again.** If two tasks are not independent, running them together buys nothing and costs a rebase.

## Saying it is not doing it

An escalation happens when the tool call is made and returns. Nothing before that counts.

Three things feel like escalating and are not:

- Writing "routed to senior-engineer" in the task document.
- Committing that document.
- Telling the user you are routing it.

All three describe the handoff. None performs it. **The document is the most dangerous of the three**, because it produces a durable artifact that reads exactly like a completed handoff to anyone who finds it later, including you in an hour.

The failure is quiet. The gap stays open, the record says it is being handled, and the next person to read the document has no reason to check.

**Write the record after the call returns, not before.** If the call fails, the document should still say the gap is open.

**Before you tell the user you handed something off, verify it.** `ListAgents` shows what is actually running. If you claimed a dispatch and it is not there, you did not dispatch it: say so plainly, then do it.

This generalises past escalation. Any sentence in a report asserting that you did something is a claim to check, not a memory to trust: "I pushed the branch", "I opened the PR", "I killed the background server", "I deleted the scratch file". The cost of checking is one command. The cost of being wrong is that someone believes you.

## Verify, do not relay

SDE-2 and its juniors report what they believe they did. Some of that will be wrong, and the wrong parts are rarely the parts they were unsure about.

Check the load-bearing claims yourself before repeating them to the user:

- **A setting that is accepted is not a setting that took effect.** Load it and print it, or resolve the thing it configures.
- **A passing test is not a load-bearing test.** The claim worth making is that it fails when the behaviour is removed.
- **A library behaves as its installed version behaves, not as its current documentation says.** Read the pinned source when a claim about a dependency matters.
- **A grep is not a row count**, and a plan is not a deployment.

When a report and reality disagree, say so plainly, fix the record, and carry on. Do not soften it and do not relay a claim you have not checked as though you had.

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
