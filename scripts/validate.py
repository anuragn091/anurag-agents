#!/usr/bin/env python3
"""Checks every skill and subagent against the Agent Skills specification and the
rules the runtimes actually enforce, so a malformed file fails CI rather than
failing silently inside an agent.

    python3 scripts/validate.py
"""
import json
import re
import sys
from pathlib import Path

FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.S)
NAME_RULE = re.compile(r"\A[a-z0-9]+(?:-[a-z0-9]+)*\Z")

# Fields the spec defines, plus the ones Claude Code and Cursor add. Anything
# outside this set is a typo or a field that silently does nothing.
KNOWN_SKILL_FIELDS = {
    "name", "description", "license", "compatibility", "metadata",
    "allowed-tools", "disallowed-tools", "disable-model-invocation",
    "user-invocable", "argument-hint", "when_to_use", "model", "paths",
    "icon", "color",
}
KNOWN_AGENT_FIELDS = {
    "name", "description", "model", "tools", "color", "readonly", "is_background",
}

errors = []


def fields_of(text, path):
    match = FRONTMATTER.match(text)
    if not match:
        errors.append(f"{path}: no YAML frontmatter")
        return {}
    found = {}
    for line in match.group(1).splitlines():
        if not line or line[0].isspace() or ":" not in line:
            continue
        key, _, value = line.partition(":")
        value = value.strip()
        if value.startswith('"'):
            try:
                value = json.loads(value)
            except json.JSONDecodeError:
                value = value.strip('"')
        found[key.strip()] = value
    return found


def check_skill(skill_md):
    directory = skill_md.parent.name
    f = fields_of(skill_md.read_text(), skill_md)
    if not f:
        return
    name = f.get("name")
    if not name:
        errors.append(f"{skill_md}: name is required")
    elif name != directory:
        errors.append(f"{skill_md}: name '{name}' does not match directory '{directory}'")
    elif not NAME_RULE.match(name):
        errors.append(f"{skill_md}: name '{name}' must be lowercase alphanumeric with single hyphens")
    description = f.get("description", "")
    if not description:
        errors.append(f"{skill_md}: description is required")
    elif len(description) > 1024:
        errors.append(f"{skill_md}: description is {len(description)} characters, the limit is 1024")
    for key in f:
        if key not in KNOWN_SKILL_FIELDS:
            errors.append(f"{skill_md}: '{key}' is not a field any runtime reads")
    if "forbidden-tools" in f:
        errors.append(f"{skill_md}: forbidden-tools is not a real field, use disallowed-tools")


def check_agent(agent_md):
    f = fields_of(agent_md.read_text(), agent_md)
    if not f:
        return
    if not f.get("name"):
        errors.append(f"{agent_md}: name is required")
    elif f["name"] != agent_md.stem:
        errors.append(f"{agent_md}: name '{f['name']}' does not match the filename")
    if not f.get("description"):
        errors.append(f"{agent_md}: description is required")
    if "\\n" in f.get("description", ""):
        errors.append(f"{agent_md}: description contains a literal backslash-n, it is double escaped")
    for key in f:
        if key not in KNOWN_AGENT_FIELDS:
            errors.append(f"{agent_md}: '{key}' is not a field any runtime reads")


def main():
    skills = sorted(Path(".agents/skills").glob("*/SKILL.md"))
    agents = sorted(Path(".claude/agents").glob("*.md"))
    if not skills:
        print("error: no skills found, run this from the repository root", file=sys.stderr)
        return 1
    for s in skills:
        check_skill(s)
    for a in agents:
        check_agent(a)

    if errors:
        for e in errors:
            print(e, file=sys.stderr)
        print(f"\n{len(errors)} problem(s)", file=sys.stderr)
        return 1
    print(f"{len(skills)} skills and {len(agents)} subagents are valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
