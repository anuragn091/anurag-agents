# anurag-agents

Claude Code skills that take a piece of work from a rough idea to a reviewed pull request.

Eight skills across three stages: define the product, design and build it through an engineering ladder, then review what came out.

## The skills

| Skill | Stage | What it does |
|---|---|---|
| `discovery` | Product | Turns a vague idea into a structured Discovery Brief |
| `product-requirements` | Product | Turns a Discovery Brief into a PRD |
| `product` | Product | Runs discovery then requirements end to end, stops at the PRD |
| `design-proposal` | Decision | Writes a proposal for team review before a decision is committed |
| `code-writing` | Implementation | Master skill loaded before any other coding skill. Guardrails, stop conditions, tool discipline |
| `sdlc` | Orchestration | Full lifecycle: requirements, engineering ladder, dev testing, QA, release |
| `test-plan` | QA | Produces a test plan covering what a human must verify, not what unit tests already cover |
| `staff-review` | Review | Staff-engineer PR review, layered checklists, P0 to P3 findings, posts to GitHub |

## staff-review

The largest of them. It reviews a PR the way a staff engineer does, and it cannot edit code: `Write` and `Edit` are in `forbidden-tools`, so a review never quietly becomes a commit.

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

Clone anywhere, then symlink the skills you want into `~/.claude/skills/`:

```bash
git clone https://github.com/anuragn091/anurag-agents.git
ln -s "$PWD/anurag-agents/skills/staff-review" ~/.claude/skills/staff-review
```

Symlinking keeps them updatable with a `git pull`. Copying works too:

```bash
cp -R anurag-agents/skills/* ~/.claude/skills/
```

Restart Claude Code, then invoke by name: `/staff-review`, `/product`, `/test-plan`.

## A note on the conventions

Some checklists name conventions from the codebase they were written against: snake_case JSON, no `/api/` prefix, `uv` for Python dependencies, `pnpm` for the frontend. Adjust those lines to your own stack. Everything else is stack independent.

## License

MIT.
