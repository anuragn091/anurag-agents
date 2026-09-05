# anurag-agents

Twelve skills and four subagents that force a coding agent to think in the right order: define the problem, decide the approach, write the spec, then build, then review.

Given a one-line prompt, an agent will happily skip straight to code. These stop it. Each stage takes the previous stage's document as input and refuses to start without it, so the thinking happens before the typing and leaves a written trail.

One set of files, read by Claude Code, Codex and Cursor.

## What it looks like in use

```
/product      "let users export their applications as CSV"
              asks who this is for and what done means, then writes a
              Discovery Brief and a PRD. Stops at the PRD.

/principal    interrogates you for constraints, picks one approach, writes a
              decision document recording what you gave up and what should
              make you revisit it. Never writes code.

/senior       turns that decision into an HLD, then an LLD detailed enough
              that a junior implements it without inventing anything.

/dispatch     breaks the LLD into ordered tasks, marks which are parallel
              safe, then runs sde1-engineer subagents in waves and
              checkpoints progress to disk so a crash resumes.

/test-plan    what a human still has to verify, separate from the unit tests.

/staff-review reviews the diff across 14 areas, ranks findings P0 to P3, and
              posts the review to the pull request.
```

`/ladder` runs the middle of that chain with an approval gate at every rung. `/sdlc` runs all of it.

Each of those also works alone. `/staff-review` on a PR needs no PRD.

## Install

Copy three directories. That is the whole install.

```bash
git clone https://github.com/anuragn091/anurag-agents.git
cp -R anurag-agents/.agents anurag-agents/.claude anurag-agents/.codex ~/
```

Swap `~/` for a project path to install there instead, and commit them so the team and any cloud agent get them too. Restart your agent, then try `/staff-review`.

Every file is a real file, no symlinks, so this works on Windows and from a zip download.

Use `./install.sh` when you want the parts a copy cannot do: merging into directories that already hold your own skills, being told what changed, and an undo. It refuses to overwrite anything that differs from what this repo ships unless you pass `--force`.

```bash
./install.sh                    # asks user or project
./install.sh --user
./install.sh --project ~/code/app
./install.sh --dry-run --user
./install.sh --uninstall --user
```

## The skills

| Skill | Takes | Produces |
|---|---|---|
| `discovery` | A rough idea | Discovery Brief |
| `product-requirements` | Discovery Brief | PRD |
| `product` | A rough idea | PRD, running the two above in order |
| `design-proposal` | An open question with real options | Proposal for team review |
| `principal` | A PRD | Decision document: what won, what it cost |
| `senior` | A decision document | HLD, then LLD |
| `dispatch` | An LLD or a task document | Task breakdown, then code |
| `ladder` | Whatever you have | The whole ladder, gated at each rung |
| `sdlc` | Whatever you have | Full lifecycle, requirements through release |
| `code-writing` | Nothing, it is the base layer | Guardrails every other coding skill inherits |
| `test-plan` | LLD and a task document | What a human must verify |
| `staff-review` | A PR, branch, or diff | Review, findings ranked P0 to P3 |

A skill that needs an input stops rather than inventing one. `/product-requirements` without a Discovery Brief refuses. `/test-plan` without an LLD refuses.

## The subagents

Four rungs, dispatched by the skills above. Each is barred from the rung over and under it, so a decision never gets made inside an implementation and a spec never gets written by the thing building from it.

| Subagent | Owns | Refuses | Model |
|---|---|---|---|
| `principal-engineer` | The decision and the record of why it won | Writing or editing any code | opus |
| `senior-engineer` | HLD then LLD, buildable without invention | Making the decision, writing product code | opus |
| `sde2-engineer` | Task breakdown, dispatching juniors, hard implementation | Writing the spec, making the call | sonnet |
| `sde1-engineer` | One scoped task with tests, several in parallel | Migrations, auth, performance, open decisions | sonnet |

`sde1-engineer` has no `Agent` tool, so it cannot spawn anything. The other three can.

## staff-review

The largest of the skills, and the one most worth reading on its own. It reviews a PR the way a staff engineer does, and it cannot edit code: `disallowed-tools` removes `Write`, `Edit` and `NotebookEdit`, so in Claude Code a review cannot quietly become a commit.

Findings land as **inline comments on the lines they are about**, posted as one review rather than a stream of separate comments. A fix that is a concrete replacement goes in a ` ```suggestion ` block, so the author commits it in one click. Anything that cannot be anchored, because its line is outside the diff or it spans files, goes in the summary with its `path:line` written out.

Checklists are layered. Concerns are technology agnostic and own the question. Platform files sit underneath and show how that question gets answered in a given stack.

```
.agents/skills/staff-review/
├── SKILL.md                         workflow, priorities, output format
└── checklists/
    ├── foundation.md                14 universal review areas
    ├── internal-standards.md        duplication, separation of concerns, clean architecture
    ├── concerns/                    technology agnostic
    │   ├── security.md
    │   ├── performance-frontend.md
    │   └── performance-backend.md
    └── platforms/                   stack specific
        ├── javascript-typescript.md
        ├── react.md
        ├── react-native.md
        ├── python-django.md
        └── fullstack-contract.md
```

Findings are ranked P0 (security, data loss, outage), P1 (correctness, authorization, compatibility, reliability), P2 (maintainability, performance, architecture), P3, and Nit. A nit never blocks a merge.

The files under `platforms/` were written against a Next.js and Django codebase and are meant to be edited for yours. Everything above them carries no stack assumptions.

## How the files are laid out

Every directory here is one an agent actually reads. Installing is a copy because the repo is already in the shape each tool expects.

```
.agents/skills/<name>/SKILL.md     source        Codex, Cursor
.claude/skills/<name>/SKILL.md     mirror        Claude Code, Cursor
.claude/agents/<name>.md           source        Claude Code, Cursor
.codex/agents/<name>.toml          generated     Codex
```

| | Skills | Subagents |
|---|---|---|
| Claude Code | `.claude/skills` | `.claude/agents` |
| Codex | `.agents/skills` | `.codex/agents` |
| Cursor | `.agents/skills`, `.claude/skills`, `.cursor/skills`, `.codex/skills` | `.cursor/agents`, `.claude/agents`, `.codex/agents` |

No tool reads every path, so two of the four directories are derived rather than written by hand:

**`.claude/skills/` is a byte-for-byte copy of `.agents/skills/`.** The obvious alternative is a symlink, but git checks a symlink out as a plain text file on Windows without Developer Mode, which would leave `.claude/skills/staff-review` as a 30 byte file containing a path. Duplicating costs 140KB and cannot break.

**`.codex/agents/*.toml` is generated from `.claude/agents/*.md`.** Codex reads TOML with a `developer_instructions` field, not markdown, so one file cannot serve both. The `model` pin is dropped on the way, since `opus` and `sonnet` mean nothing to Codex.

Edit a source, then run `./scripts/sync.sh` to rebuild both. CI fails any pull request where they are out of date, so the copies cannot drift apart.

## What each tool actually enforces

Instructions are instructions everywhere. Only some of them are backed by the runtime.

| | Claude Code | Cursor | Codex |
|---|---|---|---|
| Skill discovery and invocation | yes | yes | yes |
| Subagents load | yes | yes | yes, as TOML |
| `disallowed-tools` on a skill | **enforced** | no such field | no such field |
| `tools` on a subagent | **enforced** | ignored | dropped by the generator |
| `model` pin | yes | passed through | dropped |

Where a column says no, the rule still holds because the instruction text says so. It is just not a hard stop. In practice that means `/staff-review` genuinely cannot write a file in Claude Code, and merely promises not to elsewhere.

## Requirements

- An agent that can read files, run shell commands and search a codebase.
- `python3`, only for `./scripts/sync.sh`. Not needed to install.
- `gh` CLI, only for `staff-review` posting a review to a pull request.

Four references point at things this repo does not ship, and all of them are optional. `code-writing`, `sde1-engineer` and `sde2-engineer` suggest loading `vercel-react-best-practices`, which is Vercel's own skill published separately under MIT. `sdlc` calls `/code-review` and `/security-review`, which are built into Claude Code. A missing one is skipped, not an error.

## Maintaining

Edit `.agents/skills/` or `.claude/agents/`, never the derived copies. Then:

```bash
./scripts/sync.sh          # rebuild .claude/skills and .codex/agents
python3 scripts/validate.py
```

`validate.py` checks each file against the Agent Skills spec and the fields the runtimes actually read: name matching its directory, description within 1024 characters, no unknown keys, no double-escaped newlines. CI runs both on every pull request.

## License

MIT.
