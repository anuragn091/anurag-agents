---
name: staff-review
description: Staff-engineer code review of a PR, branch, or diff. Reviews intent, correctness, architecture, contracts, security, reliability, performance, maintainability, tests, observability, rollout, UX, org impact, and PR quality, then reports findings by P0-P3 severity and posts them to GitHub. Trigger on "review this PR", "staff review", "review before I merge", "is this safe to ship", "review my branch", or when given a PR number, PR URL, branch name, or diff.
disallowed-tools: Write Edit NotebookEdit
metadata:
  author: anurag
  version: "1.1.0"
---

# Staff Review

**Purpose:** review a change the way a staff engineer does. Judge the change against the system it lands in, not against itself. Every finding is verified against the actual code before it is written down, and every finding carries a priority so preference-level feedback never blocks a sound change.

**This skill reviews. It does not fix.** `disallowed-tools` removes `Write`, `Edit` and `NotebookEdit`, so in Claude Code a review cannot quietly become a commit. Cursor and Codex have no equivalent field, so there the rule holds only because this line says so. If the user wants the findings applied, hand the work to a separate implementation pass after the review is posted.

---

## Invocation Modes

| Input | What to review |
|---|---|
| `/staff-review` with no argument | Uncommitted changes plus the current branch against `main` |
| `/staff-review 142` | GitHub PR 142 in the current repo |
| a PR URL | That PR, in whatever repo it belongs to |
| a branch name | That branch against `main` |
| a path or diff pasted in | Exactly what was given |

Submodules: if the project splits frontend and backend into git submodules, check the diff inside each one, not just the parent pointer bump. A parent commit that only moves a submodule SHA is not a reviewable diff, go into the submodule and diff there.

---

## Step 0: Gather context before reading the diff

Run these first. Do not start commenting from the diff alone.

```
gh pr view <n> --json title,body,author,files,additions,deletions,baseRefName,headRefName
gh pr diff <n>
gh pr checks <n>
git log --oneline main..HEAD
```

Then find the intent:
- Linked issue or ticket in the description.
- Any architecture decision record that governs this area, wherever the project keeps them. If the change contradicts a recorded decision, that is resolved before any code discussion.
- The project's own instruction and convention docs (`AGENTS.md`, `CLAUDE.md`, a contributing guide) for the rules this repo already agreed to.
- The files the diff touches, read whole, not just the changed hunks. A diff hunk lies about context.

**Read the surrounding code before judging the new code.** Most bad review comments come from reviewing a hunk in isolation.

---

## Step 1: Intake gate

Answer these before reviewing line by line. If one fails, say so up front rather than burying it under 30 line comments.

- **Does this PR need to exist?** Is the problem real, and is this the cheapest fix?
- **Is the scope one thing?** Feature plus refactor plus reformat means none of it can be reviewed properly. Ask for a split.
- **Does the description explain why, not what?** The diff already says what.
- **Is it reviewable in size?** Past roughly 400 lines of real logic, review quality collapses. Push back on the size, not the content.
- **Are generated files, lockfiles, and new dependencies intentional?** A lockfile change with no dependency change in `package.json` or `pyproject.toml` is a question.

If the PR fails the gate, output the gate result, list what needs to change, and still review whatever is reviewable. Do not refuse the whole thing.

---

## Step 2: Pick the layers

Checklists are layered. Concerns are technology agnostic and own the question. Platform files sit underneath and show how the question is answered in that stack. Load top down.

**Always**
- `checklists/foundation.md` - the 14 universal review areas
- `checklists/internal-standards.md` - the rules this codebase already agreed to

**Concerns, by what the change touches**
- `concerns/security.md` - any PR that touches auth, input, data, sessions, uploads, dependencies or config. In practice, most of them.
- `concerns/performance-frontend.md` - any client UI change
- `concerns/performance-backend.md` - any server change

**Platforms, by file type**
- `platforms/javascript-typescript.md` - `.ts`, `.tsx`, `.js`
- `platforms/react.md` - React or Next.js components, hooks, routes
- `platforms/react-native.md` - only when the diff touches a React Native app
- `platforms/python-django.md` - `.py`, models, serializers, views, migrations, tasks
- `platforms/fullstack-contract.md` - both sides touched, or an API contract changed on one side

Never report a platform finding when the concern file already frames it better. "N+1 in the serializer" is one finding, not a Django finding plus a performance finding.

## Step 3: Verify every finding before writing it

This is the step that separates a useful review from noise.

- **Read the file, do not infer it.** If a claim depends on what a function does, open that function.
- **Trace the call sites.** `grep` for every caller before saying a signature change is safe or unsafe.
- **Check the duplication claim.** Before saying "this already exists", find the existing thing and quote its path.
- **Check the N+1 claim.** Look for `select_related` / `prefetch_related` before calling it. Read the serializer, that is where the extra query usually hides.
- **Check the auth claim.** Read the permission class and the queryset filter, not just the view decorator.
- **Run what can be run.** Lint, type-check, and the affected tests, if the working tree supports it.

State plainly which findings are verified and which are inference. An unverified hunch is written as a `Question`, never as a P0 or P1.

---

## Step 4: Priority, applied strictly

| Priority | Meaning | Blocks merge |
|---|---|---|
| **P0** | Security hole, data loss, or production outage | Yes, immediately |
| **P1** | Correctness, authorization, backward compatibility, or serious reliability defect | Yes |
| **P2** | Maintainability, performance, architecture concern, or a meaningful edge case | Yes, unless the author records why it is being deferred |
| **P3** | Optional improvement or minor readability issue | No |
| **Nit** | Style preference only | Never blocks |
| **Question** | Not understood yet, or could not be verified | No |
| **Praise** | Genuinely good, worth copying | No |

Rules:
- If everything is marked equally, the review gets ignored. Be honest about which is which.
- Never mark a preference above P3. Never soften a security defect below P0.
- Anything the linter or formatter owns is not a review comment at all. Fix the tool config instead.
- Cap the nits. Over five, collapse them into one comment.
- A P2 the author disagrees with is resolved by a written reason in the thread, not by silence.

---

## Step 5: Output format

```markdown
## Staff Review: <PR title>

**Verdict:** Approve / Approve with comments / Request changes / Not reviewable as submitted
**Scope:** <files, lines, layers touched>
**Checks:** <CI status, lint, type-check, tests: what was run and what it said>
**Counts:** P0: n | P1: n | P2: n | P3: n | Nits: n

### What is good
<specific, not generic. name the file. skip this section rather than pad it.>

### P0 - security, data loss, outage
1. **<one-line title>** - `path/to/file.py:120`
   What is wrong, and the failure it produces.
   ```suggestion
   <the fix>
   ```
   *Verified by:* <how you confirmed it>

### P1 - correctness, authorization, compatibility, reliability
<same shape>

### P2 - maintainability, performance, architecture, edge cases
<same shape>

### P3 and nits
<collapsed into one list>

### Questions
<things that could not be verified>

### Six-month question
If this fails in production six months from now, will the code, tests, telemetry and docs
make the cause and the recovery path obvious? Answer it, do not just ask it.

### Scorecard
| Area | Rating | Note |
|---|---|---|
| Correctness | | |
| Architecture | | |
| Security | | |
| Reliability | | |
| Performance | | |
| Tests | | |
| Observability | | |
| Maintainability | | |

### Priority fixes before merge
1.
2.
```

---

## Step 6: Post to GitHub

Repo rule, not optional: any review of a real PR is posted to that PR.

`Write` and `Edit` are disallowed here, so build the review body with a heredoc
outside the repository rather than writing a file into it:

```
cat > "${TMPDIR:-/tmp}/review.md" <<'REVIEW'
...the full review...
REVIEW
gh pr comment <n> --body-file "${TMPDIR:-/tmp}/review.md"
```

Post the full review with file paths, line numbers and code, not a summary. To request changes or approve, use `gh pr review <n> --request-changes --body-file <file>` or `--approve`.

Before finishing, confirm:
1. Full review posted, not abbreviated.
2. File paths and line numbers included.
3. Priority label on every finding.
4. Verdict stated.

**Never merge.** Open the review and stop. The merge is Anurag's call.

If the target is a local branch with no PR, skip the posting step and say so.

---

## The questions that catch the most

Ask these on every PR, whatever the stack.

**The three that find real bugs**
1. What happens when this fails halfway?
2. Who else can call this, and are they allowed to?
3. How many times does this hit the database?

**Client-side, React or React Native**
- What happens under a slow network, repeated taps, retries, or navigating away mid-request?
- Can old async work overwrite newer state?
- Is this state truly necessary, or is it derivable?
- Does this introduce a second source of truth?

**Design and ownership**
- How will we diagnose this failure in production?
- Can it be released gradually and rolled back safely?
- Will another team understand and extend this in six months?
- Does the PR solve the underlying problem, or add framework and platform complexity around it?

**The closing one**
If this fails in production six months from now, will the code, tests, telemetry and documentation make the cause and the recovery path obvious?

---

## Reviewer conduct

- One clear recommendation per comment, with the fix, not a riddle.
- Ask when you are guessing, assert when you checked.
- Discuss the code, never the author.
- Point out what is good. It is the only way a standard spreads.
- More than three round trips on one thread means get on a call and paste the outcome back.
- Do not rewrite the author's PR in the review. Point at the seam and let them cut it.
- Do not invent work the PR did not sign up for. Out-of-scope findings are recorded as follow-ups, not as blockers.
