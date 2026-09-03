# anurag-agents

Agent instructions that take a piece of work from a rough idea to a reviewed pull request.

Two halves. **Workflows** define a process and gate it. **Subagents** are the roles that process hands work to, each pinned to a model and restricted to the tools its job actually needs.

Plain markdown, no framework. Any coding agent that can read a file can use them.

## Workflows

In `skills/`. Invoked by name.

| Workflow | Stage | What it does |
|---|---|---|
| `discovery` | Product | Turns a vague idea into a structured Discovery Brief |
| `product-requirements` | Product | Turns a Discovery Brief into a PRD |
| `product` | Product | Runs discovery then requirements end to end, stops at the PRD |
| `design-proposal` | Decision | Writes a proposal for team review before a decision is committed |
| `code-writing` | Implementation | Master instruction loaded before any other coding workflow. Guardrails, stop conditions, tool discipline |
| `sdlc` | Orchestration | Full lifecycle: requirements, engineering ladder, dev testing, QA, release |
| `test-plan` | QA | Produces a test plan covering what a human must verify, not what unit tests already cover |
| `staff-review` | Review | Staff-engineer PR review, layered checklists, P0 to P3 findings |

## The engineering ladder

In `agents/`. Four rungs, dispatched by `sdlc`. Each one is deliberately barred from the rung above and below it, so a decision never gets made inside an implementation and a spec never gets written by the thing building from it.

| Subagent | Rung | Owns | Refuses | Model |
|---|---|---|---|---|
| `principal-engineer` | Principal | The decision, and the record of why it won and what it costs | Writing or editing any code | opus |
| `senior-engineer` | SDE-3 | HLD then LLD, detailed enough for a junior to build without inventing | Making the decision, writing product code | opus |
| `sde2-engineer` | SDE-2 | Task breakdown, dispatching juniors in waves, hard implementation | Writing the spec, making the call | sonnet |
| `sde1-engineer` | SDE-1 | One scoped task with tests, several running in parallel | Migrations, auth, performance, anything with an open decision | sonnet |

Work moves down the ladder: PRD to decision to spec to tasks to code. Anything ambiguous moves back up rather than being guessed at.

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

## Structure

```
skills/<name>/SKILL.md      a workflow, plus supporting files where the instructions warrant them
agents/<name>.md            a subagent, one file
```

Both open with YAML frontmatter. A workflow carries its name, a description with trigger phrases, and the tools it may and may not use. A subagent carries its name, a description with worked routing examples, a model pin, and its tool allowlist.

The filenames follow the convention used by Anthropic's CLI, which is where these run today. Nothing in the content depends on them. Any other runtime can read the same files from wherever it expects to find them.

## Use

**Point an agent at the file.** Most tools accept a path or a pasted file:

```
Read skills/staff-review/SKILL.md and follow it for this PR.
```

**Or install into a runtime that auto-loads instruction directories.** Clone, then symlink what you want:

```bash
git clone https://github.com/anuragn091/anurag-agents.git
cd anurag-agents
ln -s "$PWD/skills/staff-review" ~/.claude/skills/staff-review
ln -s "$PWD/agents/principal-engineer.md" ~/.claude/agents/principal-engineer.md
```

Symlinking keeps them updatable with a `git pull`. Copying works too:

```bash
cp -R skills/* ~/.claude/skills/
cp agents/*.md ~/.claude/agents/
```

Restart your agent. Workflows are invoked by name (`/staff-review`, `/product`, `/test-plan`). Subagents are dispatched by a workflow, or requested directly by role.

For any other runtime, copy the files to wherever that tool reads its instructions from.

## A note on the conventions

Some checklists name conventions from the codebase they were written against: snake_case JSON, no `/api/` prefix, `uv` for Python dependencies, `pnpm` for the frontend. Adjust those lines to your own stack. Everything else is stack independent.

## License

MIT.
