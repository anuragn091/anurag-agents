#!/usr/bin/env python3
"""Converts a Claude-style subagent (markdown with YAML frontmatter) into the
TOML file Codex expects at .codex/agents/<name>.toml.

Codex requires name, description and developer_instructions, and reads TOML
rather than markdown, so the same file cannot simply be symlinked into place.
The model pin is dropped on purpose: opus and sonnet mean nothing to Codex, so
the agent inherits whatever default the user has configured.

    codex-agent-from-md.py <input.md> <output.toml>
"""
import json
import re
import sys
from pathlib import Path

FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n(.*)\Z", re.S)


def read_frontmatter(text):
    """Returns (fields, body). Handles the plain `key: value` and double-quoted
    forms these files use, which are close enough to JSON to unescape that way."""
    match = FRONTMATTER.match(text)
    if not match:
        raise ValueError("no YAML frontmatter found")
    fields, body = {}, match.group(2)
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
        fields[key.strip()] = value
    return fields, body


def toml_literal(value):
    """A multi-line literal string, so nothing in the body needs escaping."""
    if "'''" in value:
        raise ValueError("content contains ''' and cannot be a TOML literal string")
    return "'''\n" + value.rstrip() + "\n'''"


def toml_basic(value):
    return json.dumps(value)


def convert(src: Path, dst: Path):
    fields, body = read_frontmatter(src.read_text())
    name = fields.get("name") or src.stem
    description = fields.get("description")
    if not description:
        raise ValueError(f"{src}: description is required")

    instructions = body.strip()
    if not instructions:
        raise ValueError(f"{src}: body is empty")

    out = [
        f"# Generated from {src.name}. Edit that file and re-run the installer.",
        f"name = {toml_basic(name)}",
        f"description = {toml_literal(description)}",
        f"developer_instructions = {toml_literal(instructions)}",
        "",
    ]
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text("\n".join(out))


def main():
    if len(sys.argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    try:
        convert(Path(sys.argv[1]), Path(sys.argv[2]))
    except (ValueError, OSError) as err:
        print(f"error: {err}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
