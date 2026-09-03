# anurag-agents

Skills and subagents that take a piece of work from a rough idea to a reviewed pull request. One set of files, read by Claude Code, Codex and Cursor.

## Install

Copy the four directories. That is the whole install.

```bash
git clone https://github.com/anuragn091/anurag-agents.git
cp -R anurag-agents/.agents anurag-agents/.claude anurag-agents/.codex ~/
```

Swap `~/` for a project path to install there instead, and commit them so the team and any cloud agent get them too. Restart your agent, then try `/staff-review`.

Every file is a real file. No symlinks, so this works on Windows and from a zip download.

Use `./install.sh` instead when you want the parts a copy cannot do: merging into directories that already hold your own skills, being told what changed, and `--uninstall`. It refuses to overwrite anything that differs from what this repo ships unless you pass `--force`.

```bash
./install.sh                    # asks user or project
./install.sh --user
./install.sh --project ~/code/app
./install.sh --only skills
./install.sh --dry-run --user
./install.sh --uninstall --user
```

## Layout

Every directory here is one an agent actually reads.

```
.agents/skills/<name>/SKILL.md     source        Codex, Cursor
.claude/skills/<name>/SKILL.md     mirror        Claude Code, Cursor
.claude/agents/<name>.md           source        Claude Code, Cursor
.codex/agents/<name>.toml          generated     Codex
```

| | Skills | Subagents |
|---|---|---|
| Claude Code | `.claude/skills`, `~/.claude/skills` | `.claude/agents`, `~/.claude/agents` |
| Codex | `.agents/skills`, `~/.agents/skills` | `.codex/agents`, `~/.codex/agents` |
| Cursor | `.agents/skills`, `.claude/skills`, `.cursor/skills`, `.codex/skills` | `.cursor/agents`, `.claude/agents`, `.codex/agents` |

Two things are derived rather than written by hand:

**`.claude/skills/` is a byte-identical copy of `.agents/skills/`.** No tool reads both paths, and git checks a symlink out as a plain text file on Windows without Developer Mode, so the files are duplicated instead. CI fails any commit where the two differ.

**`.codex/agents/*.toml` is generated from `.claude/agents/*.md`.** Codex reads TOML with a `developer_instructions` field, not markdown, so the same file cannot serve both. The `model` pin is dropped on the way, since `opus` and `sonnet` mean nothing to Codex.

After editing either source, run:

```bash
./scripts/sync.sh
```

## The pipeline

Each stage consumes the previous stage's document. Nothing starts without its input, and anything ambiguous goes back up a level instead of being guessed at.

```
rough idea
  → /discovery          Discovery Brief
  → /product            PRD                        (runs discovery + requirements)
  → /principal          decision document, an ADR
  → /senior             HLD, then LLD
  → /dispatch           task breakdown, then code  (sde2 dispatches sde1 in waves)
  → /test-plan          manual test plan
  → /staff-review       reviewed PR
```

`/ladder` runs the middle of that chain. `/sdlc` runs all of it.

## Skills

Eighteen, invoked by name.

| Skill | Needs as input | Produces |
|---|---|---|
| `discovery` | A rough idea | Discovery Brief |
| `product-requirements` | Discovery Brief | PRD |
| `product` | A rough idea | PRD, via discovery then requirements |
| `design-proposal` | An open question with real options | Proposal for team review |
| `principal` | A PRD | Decision document, what won and what it costs |
| `senior` | A decision document | HLD, then LLD |
| `dispatch` | An LLD or a task document | Task breakdown, then code |
| `ladder` | Whatever you have | The whole ladder with a gate at every rung |
| `sdlc` | Whatever you have | Full lifecycle, requirements through release |
| `code-writing` | Nothing, it is the base layer | Guardrails every other coding skill inherits |
| `test-plan` | LLD and a task document | Test plan for what a human must verify |
| `staff-review` | A PR, branch, or diff | Review, findings ranked P0 to P3 |
| `add-feature` | A feature description | Implementation with tests |
| `debug` | An error or stack trace | Root cause and a fix |
| `fix-tests` | A failing suite | Repaired tests |
| `fix-issue` | A GitHub issue number | A fix, committed and pushed |
| `optimize-performance` | A slow path | Profiling and an optimization pass |
| `deploy` | A release | Deployment with safety checks |

A skill that needs an input stops and says so rather than inventing one. `/product-requirements` without a Discovery Brief refuses. `/test-plan` without an LLD refuses.

`deploy` and `fix-issue` carry `disable-model-invocation: true`, so only you can start them. They ship to production and push to GitHub. The rest can be invoked by name or picked up by the agent when relevant.

## Subagents

Four rungs. Each is barred from the rung above and below, so a decision never gets made inside an implementation and a spec never gets written by the thing building from it.

| Subagent | Owns | Refuses | Model |
|---|---|---|---|
| `principal-engineer` | The decision, and the record of why it won and what it costs | Writing or editing any code | opus |
| `senior-engineer` | HLD then LLD, detailed enough for a junior to build without inventing | Making the decision, writing product code | opus |
| `sde2-engineer` | Task breakdown, dispatching juniors in waves, hard implementation | Writing the spec, making the call | sonnet |
| `sde1-engineer` | One scoped task with tests, several running in parallel | Migrations, auth, performance, anything with an open decision | sonnet |

`sde1-engineer` has no `Agent` tool, so it cannot spawn anything. The other three can.

## staff-review

The largest of the skills. It reviews a PR the way a staff engineer does. `disallowed-tools` removes `Write`, `Edit` and `NotebookEdit`, so in Claude Code a review cannot quietly become a commit.

Checklists are layered. Concerns are technology agnostic and own the question. Platform files sit underneath and show how that question is answered in a given stack.

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

## What is enforced where

Instructions are instructions everywhere. Only some of them are backed by the runtime.

| | Claude Code | Cursor | Codex |
|---|---|---|---|
| Skill discovery and invocation | yes | yes | yes |
| Subagents load | yes | yes | yes, as TOML |
| `disallowed-tools` on a skill | **enforced** | no such field | no such field |
| `tools` on a subagent | **enforced** | ignored | dropped by the generator |
| `disable-model-invocation` | yes | yes | unverified |
| `model` pin | yes | passed through | dropped |

Where a column says no, the rule still holds because the instruction text says so. It is just not a hard stop.

## Requirements

- An agent that can read files, run shell commands and search a codebase.
- `python3`, only for `./scripts/sync.sh`. Not needed to install.
- `gh` CLI, only for `staff-review` posting to a pull request and for `fix-issue`.

## Referenced but not bundled

Some files name skills that are not in this repo. They degrade to a no-op if missing.

| Referenced | Where | What it is |
|---|---|---|
| `vercel-react-best-practices` | `code-writing`, `sde1`, `sde2` | Vercel's React performance skill, published separately under MIT |
| `web-design-guidelines` | `code-writing` | Vercel's Web Interface Guidelines skill |
| `code-refactor` | `code-writing` | Not published |
| `/code-review`, `/security-review` | `sdlc`, `fix-issue` | Built into Claude Code, absent elsewhere |

## Contributing

Edit `.agents/skills/` or `.claude/agents/`, never the derived copies. Then:

```bash
./scripts/sync.sh          # rebuild .claude/skills and .codex/agents
python3 scripts/validate.py
```

CI runs `./scripts/sync.sh --check` and `validate.py` on every pull request, so a change that edits one copy and not the other cannot merge.

## Adapting to your stack

The review checklists were written against a Next.js and Django codebase, and some lines still assume it. The technology-agnostic files (`foundation.md`, `internal-standards.md`, everything under `concerns/`) carry no stack assumptions. The files under `platforms/` are meant to be edited.

Six of the skills (`add-feature`, `debug`, `deploy`, `fix-issue`, `fix-tests`, `optimize-performance`) name Next.js and Django specifics in their prompts. Rewrite those lines or delete the skills.

## License

MIT.
