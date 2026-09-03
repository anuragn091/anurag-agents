# anurag-agents

Skills, subagents and commands that take a piece of work from a rough idea to a reviewed pull request. They run in Claude Code, Codex and Cursor from one set of files.

## Install

```bash
git clone https://github.com/anuragn091/anurag-agents.git
cd anurag-agents
./install.sh
```

It asks two questions: install for your user or for one project, and link to this clone or copy the files. Then it wires up every agent.

```bash
./install.sh --user                 # into $HOME, available in every project
./install.sh --project ~/code/app   # into one repo, commit it for the team
./install.sh --copy                 # independent of this clone
./install.sh --only skills          # skills, agents or commands. repeatable
./install.sh --dry-run --user       # print what it would do
./install.sh --uninstall --user     # remove what it created
```

Restart your agent afterwards, then try `/staff-review`.

## How the wiring works

`.agents/` holds the real files. Everything else is a symlink pointing at it, so one edit or one `git pull` reaches every agent at once.

```
.agents/skills/<name>/         read directly by Codex and Cursor
.agents/agents/<name>.md       our own convention, nothing reads it directly
.agents/commands/<name>.md     our own convention, nothing reads it directly

.claude/skills/<name>    -> .agents/skills/<name>       Claude Code, Cursor
.claude/agents/<n>.md    -> .agents/agents/<n>.md       Claude Code, Cursor
.claude/commands/<n>.md  -> .agents/commands/<n>.md     Claude Code
.cursor/agents/<n>.md    -> .agents/agents/<n>.md       Cursor, wins on name clash
.codex/agents/<n>.toml                                  Codex, generated not linked
```

Two things worth knowing:

**`.agents/` is the skills standard, not a subagent standard.** [The Agent Skills spec](https://agentskills.io) defines `.agents/skills/` and `~/.agents/skills/`, and Codex and Cursor read them. It says nothing about subagents. `.agents/agents/` and `.agents/commands/` are this repo's own idea, kept there so there is one source of truth, with symlinks doing the real work.

**Codex subagents are TOML, not markdown.** Codex expects `.codex/agents/<name>.toml` with a `developer_instructions` field, so the same file cannot be symlinked into place. `scripts/codex-agent-from-md.py` generates them from the markdown, and the installer runs it. Re-run the installer after editing a subagent. The `model` pin is dropped on the way, since `opus` and `sonnet` mean nothing to Codex.

Where each agent looks:

| | Skills | Subagents |
|---|---|---|
| Claude Code | `.claude/skills`, `~/.claude/skills` | `.claude/agents`, `~/.claude/agents` |
| Codex | `.agents/skills`, `~/.agents/skills` | `.codex/agents`, `~/.codex/agents` (TOML) |
| Cursor | `.agents/skills`, `.cursor/skills`, `.claude/skills`, `.codex/skills` | `.cursor/agents`, `.claude/agents`, `.codex/agents` |

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

| Skill | Needs as input | Produces |
|---|---|---|
| `discovery` | A rough idea | Discovery Brief |
| `product-requirements` | Discovery Brief | PRD |
| `product` | A rough idea | PRD, via discovery then requirements |
| `design-proposal` | An open question with real options | Proposal for team review |
| `code-writing` | Nothing, it is the base layer | Guardrails every other coding skill inherits |
| `sdlc` | Whatever you have | Routes to the right stage, gates each one |
| `test-plan` | LLD and a task document | Test plan for what a human must verify |
| `staff-review` | A PR, branch, or diff | Review, findings ranked P0 to P3 |

A skill that needs an input stops and says so rather than inventing one. `/product-requirements` without a Discovery Brief refuses. `/test-plan` without an LLD refuses.

## Subagents

Four rungs. Each is barred from the rung above and below, so a decision never gets made inside an implementation and a spec never gets written by the thing building from it.

| Subagent | Owns | Refuses | Model |
|---|---|---|---|
| `principal-engineer` | The decision, and the record of why it won and what it costs | Writing or editing any code | opus |
| `senior-engineer` | HLD then LLD, detailed enough for a junior to build without inventing | Making the decision, writing product code | opus |
| `sde2-engineer` | Task breakdown, dispatching juniors in waves, hard implementation | Writing the spec, making the call | sonnet |
| `sde1-engineer` | One scoped task with tests, several running in parallel | Migrations, auth, performance, anything with an open decision | sonnet |

## Commands

`/principal`, `/senior`, `/dispatch` and `/ladder` drive the subagents above. `/add-feature`, `/debug`, `/fix-issue`, `/fix-tests`, `/optimize-performance` and `/deploy` are standalone.

Claude Code has merged commands into skills, so a file in `.claude/commands/` and a skill of the same name both create the same slash command.

## staff-review

The largest of the skills. It reviews a PR the way a staff engineer does, and it cannot edit code: `Write` and `Edit` are in `forbidden-tools`, so a review never quietly becomes a commit.

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

## Requirements

- An agent that can read files, run shell commands and search a codebase.
- `python3`, only for generating the Codex TOML files. Without it the installer skips them and says so.
- `gh` CLI, only for `staff-review` posting to a pull request and for `/fix-issue`.
- The subagent `model: opus` and `model: sonnet` pins are Anthropic model names. Cursor accepts a `model` field and will use its own; Codex ignores the pin entirely because the generator drops it.

## Referenced but not bundled

Some files name skills that are not in this repo. They degrade to a no-op if missing.

| Referenced | Where | What it is |
|---|---|---|
| `vercel-react-best-practices` | `code-writing`, `sde1`, `sde2` | Vercel's React performance skill, published separately under MIT |
| `web-design-guidelines` | `code-writing` | Vercel's Web Interface Guidelines skill |
| `code-refactor` | `code-writing` | Not published |
| `/code-review`, `/security-review` | `sdlc`, `fix-issue` | Built into Claude Code, absent elsewhere |

## Adapting to your stack

The review checklists were written against a Next.js and Django codebase, and some lines still assume it: snake_case JSON, service-layer Django, Server Components by default. The technology-agnostic files (`foundation.md`, `internal-standards.md`, everything under `concerns/`) carry no stack assumptions. The files under `platforms/` are meant to be edited.

Six of the commands (`add-feature`, `debug`, `deploy`, `fix-issue`, `fix-tests`, `optimize-performance`) name Next.js and Django specifics in their prompts. Rewrite those lines or drop the commands.

## License

MIT.
