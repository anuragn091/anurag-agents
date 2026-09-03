# anurag-agents

Agent instructions that take a piece of work from a rough idea to a reviewed pull request.

Three parts. **Workflows** define a process and gate it. **Subagents** are the roles that process hands work to, each pinned to a model and restricted to the tools its job needs. **Commands** are the entry points that start a workflow or launch a subagent.

Plain markdown, no framework. Any coding agent that can read a file can use them.

## The pipeline

Each stage consumes the previous stage's document. That is the whole design: nothing starts without its input, and anything ambiguous goes back up a level instead of being guessed at.

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

`/ladder` runs the middle of that chain end to end. `/sdlc` runs all of it.

## Workflows

In `skills/`. Invoked by name.

| Workflow | Needs as input | Produces |
|---|---|---|
| `discovery` | A rough idea | Discovery Brief |
| `product-requirements` | Discovery Brief | PRD |
| `product` | A rough idea | PRD, via discovery then requirements |
| `design-proposal` | An open question with real options | Proposal for team review |
| `code-writing` | Nothing, it is the base layer | Guardrails every other coding workflow inherits |
| `sdlc` | Whatever you have | Routes to the right stage, gates each one |
| `test-plan` | LLD and a task document | Test plan for what a human must verify |
| `staff-review` | A PR, branch, or diff | Review, findings ranked P0 to P3 |

Workflows that need an input stop and say so rather than inventing one. `/product-requirements` without a Discovery Brief refuses. `/test-plan` without an LLD refuses.

## The engineering ladder

In `agents/`. Four rungs, dispatched by the commands below. Each is barred from the rung above and below, so a decision never gets made inside an implementation and a spec never gets written by the thing building from it.

| Subagent | Rung | Owns | Refuses | Model |
|---|---|---|---|---|
| `principal-engineer` | Principal | The decision, and the record of why it won and what it costs | Writing or editing any code | opus |
| `senior-engineer` | SDE-3 | HLD then LLD, detailed enough for a junior to build without inventing | Making the decision, writing product code | opus |
| `sde2-engineer` | SDE-2 | Task breakdown, dispatching juniors in waves, hard implementation | Writing the spec, making the call | sonnet |
| `sde1-engineer` | SDE-1 | One scoped task with tests, several running in parallel | Migrations, auth, performance, anything with an open decision | sonnet |

## Commands

In `commands/`. Thin entry points.

| Command | Runs |
|---|---|
| `/principal` | principal-engineer, for a decision document |
| `/senior` | senior-engineer, for an HLD and LLD |
| `/dispatch` | sde2-engineer, which breaks the spec down and dispatches sde1 agents |
| `/ladder` | The whole ladder, with an approval gate at every rung |
| `/add-feature` | Full-stack feature implementation with TDD |
| `/debug` | Systematic error investigation |
| `/fix-issue` | Fix a GitHub issue and push |
| `/fix-tests` | Test repair |
| `/optimize-performance` | Profiling and optimization pass |
| `/deploy` | Deployment with safety checks |

## staff-review

The largest of the workflows. It reviews a PR the way a staff engineer does, and it cannot edit code: `Write` and `Edit` are in `forbidden-tools`, so a review never quietly becomes a commit.

Checklists are layered. Concerns are technology agnostic and own the question. Platform files sit underneath and show how that question is answered in a given stack.

```
skills/staff-review/
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

## Install

Written for Anthropic's CLI, which auto-loads `~/.claude/skills/`, `~/.claude/agents/` and `~/.claude/commands/`.

```bash
git clone https://github.com/anuragn091/anurag-agents.git
cd anurag-agents
mkdir -p ~/.claude/skills ~/.claude/agents ~/.claude/commands
cp -R skills/*    ~/.claude/skills/
cp    agents/*.md ~/.claude/agents/
cp    commands/*.md ~/.claude/commands/
```

Symlink instead if you want `git pull` to update them:

```bash
for d in skills/*/;   do ln -s "$PWD/$d"  ~/.claude/skills/$(basename "$d"); done
for f in agents/*.md; do ln -s "$PWD/$f"  ~/.claude/agents/$(basename "$f"); done
for f in commands/*.md; do ln -s "$PWD/$f" ~/.claude/commands/$(basename "$f"); done
```

Restart the CLI. Workflows and commands are then invoked by name: `/staff-review`, `/product`, `/ladder`.

**Any other runtime:** copy the file to wherever that tool reads instructions from, or point the agent at the path directly. Nothing in the content depends on the filename.

```
Read skills/staff-review/SKILL.md and follow it for this PR.
```

## Requirements

- A coding agent that can read files, run shell commands, and search a codebase. The workflows name tools (`Read`, `Grep`, `Bash`, `Write`, `WebSearch`) in their `allowed-tools` frontmatter. On a runtime that does not enforce those lists, they are advisory.
- `gh` CLI, only for `staff-review` posting a review to a pull request and for `/fix-issue`. Everything else works offline.
- The subagents carry `model: opus` and `model: sonnet` pins. On another runtime, map those to your strongest and mid-tier models, or delete the line.

## Referenced but not bundled

Some files name workflows that are not in this repo. They degrade to a no-op if missing, except where noted.

| Referenced | Where | What it is |
|---|---|---|
| `vercel-react-best-practices` | `code-writing`, `sde1`, `sde2` | Vercel's React performance skill, published separately under MIT |
| `web-design-guidelines` | `code-writing` | Vercel's Web Interface Guidelines skill |
| `code-refactor` | `code-writing` | Not published |
| `/code-review`, `/security-review` | `sdlc`, `fix-issue` | Built into Anthropic's CLI, absent elsewhere |

## Adapting to your stack

The checklists were written against a Next.js and Django codebase, and some lines still assume it: snake_case JSON, service-layer Django, Server Components by default. The technology-agnostic files (`foundation.md`, `internal-standards.md`, everything under `concerns/`) carry no stack assumptions. The platform files under `platforms/` are meant to be edited.

Six of the commands (`add-feature`, `debug`, `deploy`, `fix-issue`, `fix-tests`, `optimize-performance`) name Next.js and Django specifics in their prompts. Rewrite those lines or drop the commands.

## License

MIT.
