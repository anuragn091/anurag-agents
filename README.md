# anurag-agents

Agent instructions that take a piece of work from a rough idea to a reviewed pull request.

Eight agents across three stages: define the product, design and build it through an engineering ladder, then review what came out.

Plain markdown, no framework. Any coding agent that can read a file can use them.

## The agents

| Agent | Stage | What it does |
|---|---|---|
| `discovery` | Product | Turns a vague idea into a structured Discovery Brief |
| `product-requirements` | Product | Turns a Discovery Brief into a PRD |
| `product` | Product | Runs discovery then requirements end to end, stops at the PRD |
| `design-proposal` | Decision | Writes a proposal for team review before a decision is committed |
| `code-writing` | Implementation | Master agent loaded before any other coding agent. Guardrails, stop conditions, tool discipline |
| `sdlc` | Orchestration | Full lifecycle: requirements, engineering ladder, dev testing, QA, release |
| `test-plan` | QA | Produces a test plan covering what a human must verify, not what unit tests already cover |
| `staff-review` | Review | Staff-engineer PR review, layered checklists, P0 to P3 findings |

## staff-review

The largest of them. It reviews a PR the way a staff engineer does, and it cannot edit code: `Write` and `Edit` are in `forbidden-tools`, so a review never quietly becomes a commit.

Checklists are layered. Concerns are technology agnostic and own the question. Platform files sit underneath and show how that question is answered in a given stack.

```
agents/staff-review/
├── AGENT.md                         workflow, priorities, output format
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

Every agent is one directory with an `AGENT.md` and, where the instructions are long enough to warrant it, supporting files beside it.

```
agents/<name>/AGENT.md
```

`AGENT.md` opens with YAML frontmatter carrying the name, a description with trigger phrases, and the tools the agent may and may not use. Everything after the frontmatter is the instruction body.

## Use

**Point an agent at the file.** Most tools accept a path or a pasted file:

```
Read agents/staff-review/AGENT.md and follow it for this PR.
```

**Or install into a runtime that auto-loads instruction directories.** Clone, then link or copy the agents you want.

For Anthropic's CLI, which loads from `~/.claude/skills/` and expects the file to be named `SKILL.md`:

```bash
git clone https://github.com/anuragn091/anurag-agents.git
for d in anurag-agents/agents/*/; do
  name=$(basename "$d")
  mkdir -p ~/.claude/skills/"$name"
  cp -R "$d". ~/.claude/skills/"$name"/
  mv ~/.claude/skills/"$name"/AGENT.md ~/.claude/skills/"$name"/SKILL.md
done
```

Restart your agent, then invoke by name: `/staff-review`, `/product`, `/test-plan`.

For any other runtime, copy `agents/<name>/AGENT.md` to wherever that tool reads its instructions from. The content does not depend on the filename.

## A note on the conventions

Some checklists name conventions from the codebase they were written against: snake_case JSON, no `/api/` prefix, `uv` for Python dependencies, `pnpm` for the frontend. Adjust those lines to your own stack. Everything else is stack independent.

## License

MIT.
