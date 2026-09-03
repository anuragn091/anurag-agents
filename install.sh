#!/usr/bin/env bash
#
# Installs the skills, subagents and commands in this repo so that Claude Code,
# Codex and Cursor all read the same files.
#
# .agents/ holds the real files. Every other directory is symlinks pointing at it,
# so an edit or a git pull reaches every agent at once.
#
# Every directory used here is one an agent actually reads.
#
#   .agents/skills/<name>/      canonical    Codex, Cursor
#   .claude/skills/<name>       -> .agents/skills/<name>      Claude Code, Cursor
#
#   .claude/agents/<n>.md       canonical    Claude Code, Cursor
#   .cursor/agents/<n>.md       -> .claude/agents/<n>.md      Cursor, wins on name clash
#   .codex/agents/<n>.toml      generated    Codex
#
#   .claude/commands/<n>.md     canonical    Claude Code
#
# Codex subagents are TOML with a developer_instructions field, not markdown, so
# they are generated from the same source rather than symlinked. Re-run this
# script after editing a subagent to regenerate them.
#
# Usage:
#   ./install.sh                      ask where to install
#   ./install.sh --user               into $HOME
#   ./install.sh --project [path]     into a project directory, default the current one
#   ./install.sh --copy               copy the files instead of linking to this clone
#   ./install.sh --only skills        skills, agents or commands. repeatable
#   ./install.sh --uninstall --user   remove what this script created
#   ./install.sh --dry-run --user     print the actions without doing them
#   ./install.sh --force              replace real files that are in the way

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

SCOPE=""
ROOT=""
MODE="link"
UNINSTALL=0
DRY=0
FORCE=0
ONLY=()
YES=0

C_DIM=$'\033[2m'; C_B=$'\033[1m'; C_G=$'\033[32m'; C_Y=$'\033[33m'; C_R=$'\033[31m'; C_0=$'\033[0m'
if [ ! -t 1 ]; then C_DIM=""; C_B=""; C_G=""; C_Y=""; C_R=""; C_0=""; fi

say()  { printf '%s\n' "$*"; }
info() { printf '%s%s%s\n' "$C_DIM" "$*" "$C_0"; }
ok()   { printf '%s  ok%s  %s\n' "$C_G" "$C_0" "$*"; }
warn() { printf '%swarn%s  %s\n' "$C_Y" "$C_0" "$*"; }
die()  { printf '%serror%s %s\n' "$C_R" "$C_0" "$*" >&2; exit 1; }

usage() { sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; $d'; exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --user)      SCOPE="user" ;;
    --project)   SCOPE="project"
                 if [ "${2-}" ] && [ "${2#--}" = "$2" ]; then ROOT="$2"; shift; fi ;;
    --copy)      MODE="copy"; MODE_SET=1 ;;
    --link)      MODE="link"; MODE_SET=1 ;;
    --only)      [ "${2-}" ] || die "--only needs a value: skills, agents or commands"
                 ONLY+=("$2"); shift ;;
    --uninstall) UNINSTALL=1 ;;
    --dry-run)   DRY=1 ;;
    --force)     FORCE=1 ;;
    --yes|-y)    YES=1 ;;
    -h|--help)   usage ;;
    *)           die "unknown option: $1" ;;
  esac
  shift
done

[ ${#ONLY[@]} -eq 0 ] && ONLY=(skills agents commands)
wants() { local w; for w in "${ONLY[@]}"; do [ "$w" = "$1" ] && return 0; done; return 1; }

# Where to install.
if [ -z "$SCOPE" ]; then
  if [ ! -t 0 ]; then die "no scope given and no terminal to ask on. Pass --user or --project"; fi
  say ""
  say "${C_B}Where should these be installed?${C_0}"
  say ""
  say "  1) User level     ${C_DIM}$HOME${C_0}"
  say "     ${C_DIM}available in every project on this machine${C_0}"
  say "  2) Project level  ${C_DIM}$(pwd)${C_0}"
  say "     ${C_DIM}committed with the repo, so the whole team and any cloud agent gets them${C_0}"
  say ""
  printf 'Choose [1/2]: '
  read -r answer
  case "$answer" in
    1) SCOPE="user" ;;
    2) SCOPE="project" ;;
    *) die "expected 1 or 2" ;;
  esac
fi

case "$SCOPE" in
  user)    ROOT="$HOME" ;;
  project) ROOT="${ROOT:-$(pwd)}" ;;
  *)       die "scope must be user or project" ;;
esac
[ -d "$ROOT" ] || die "not a directory: $ROOT"
ROOT="$(cd "$ROOT" && pwd -P)"

if [ "$SCOPE" = "project" ] && [ "$ROOT" = "$REPO" ]; then
  die "that would install this repo into itself. Run it from the project you want the agents in, or pass --project <path>"
fi

# Ask about mode when we are interactive and the user did not say.
if [ -z "${MODE_SET-}" ] && [ $YES -eq 0 ] && [ -t 0 ] && [ $UNINSTALL -eq 0 ]; then
  say ""
  say "${C_B}How should the files be installed?${C_0}"
  say ""
  say "  1) Link to this clone  ${C_DIM}git pull updates every agent at once${C_0}"
  say "  2) Copy the files      ${C_DIM}independent of this clone, edit them freely${C_0}"
  say ""
  printf 'Choose [1/2] (default 1): '
  read -r answer
  case "$answer" in
    2) MODE="copy" ;;
    ""|1) MODE="link" ;;
    *) die "expected 1 or 2" ;;
  esac
fi

run() {
  if [ $DRY -eq 1 ]; then info "would: $*"; else "$@"; fi
}

# Replace whatever is at $1, if we are allowed to.
clear_path() {
  local p="$1"
  if [ -L "$p" ]; then run rm -f "$p"; return 0; fi
  if [ -e "$p" ]; then
    if [ $FORCE -eq 1 ]; then run rm -rf "$p"; return 0; fi
    warn "exists and is not a link, skipped: $(short "$p")   (--force to replace)"
    return 1
  fi
  return 0
}

# A relative symlink, used only between two paths under the same root so the
# whole tree stays movable. Crossing out to the clone uses an absolute path,
# because a relative one breaks when a parent like /var is itself a symlink.
link_rel() {
  local target="$1" link="$2" linkdir rel
  linkdir="$(dirname "$link")"
  if [ -n "$PYTHON" ]; then
    rel="$("$PYTHON" -c 'import os,sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$target" "$linkdir")"
  else
    rel="$target"
  fi
  run ln -s "$rel" "$link"
}

link_abs() {
  run ln -s "$1" "$2"
}

CREATED=0
SKIPPED=0
CODEX_WARNED=0
PYTHON="$(command -v python3 || true)"

install_canonical() {           # $1 kind, $2 src, $3 dst
  local dst="$3"
  clear_path "$dst" || { SKIPPED=$((SKIPPED+1)); return 1; }
  if [ "$MODE" = "copy" ]; then
    run cp -R "$2" "$dst"
  else
    link_abs "$2" "$dst"
  fi
  CREATED=$((CREATED+1))
}

install_alias() {               # $1 canonical abs, $2 alias abs
  clear_path "$2" || return 1
  link_rel "$1" "$2"
  CREATED=$((CREATED+1))
}

# Codex reads TOML, not markdown, so its subagents are generated from the same source.
generate_codex_agent() {
  local src="$1" dst="$2"
  if [ -z "$PYTHON" ]; then
    if [ $CODEX_WARNED -eq 0 ]; then
      warn "python3 not found, skipping the Codex subagents in .codex/agents"
      CODEX_WARNED=1
    fi
    return 0
  fi
  if [ $DRY -eq 1 ]; then info "would: generate $dst"; return 0; fi
  if "$PYTHON" "$REPO/scripts/codex-agent-from-md.py" "$src" "$dst"; then
    CREATED=$((CREATED+1))
  else
    warn "could not generate $(short "$dst")"
  fi
}

# Removes a file this script generated, identified by the header it writes.
remove_generated() {
  local p="$1"
  [ -f "$p" ] || return 0
  if head -1 "$p" | grep -q '^# Generated from '; then
    run rm -f "$p"; CREATED=$((CREATED+1))
  else
    warn "not ours, left alone: $(short "$p")"; SKIPPED=$((SKIPPED+1))
  fi
}

remove_at() {
  local p="$1"
  if [ -L "$p" ]; then run rm -f "$p"; CREATED=$((CREATED+1)); return; fi
  if [ -e "$p" ]; then
    if [ $FORCE -eq 1 ]; then run rm -rf "$p"; CREATED=$((CREATED+1))
    else warn "not a link, left alone: $(short "$p")   (--force to remove)"; SKIPPED=$((SKIPPED+1)); fi
  fi
}

short() { case "$1" in "$HOME") printf '~' ;; "$HOME"/*) printf '~%s' "${1#$HOME}" ;; *) printf '%s' "$1" ;; esac; }

say ""
if [ $UNINSTALL -eq 1 ]; then
  say "${C_B}Removing from $(short "$ROOT")${C_0}"
else
  say "${C_B}Installing into $(short "$ROOT")${C_0}  ${C_DIM}($MODE)${C_0}"
fi
[ $DRY -eq 1 ] && info "dry run, nothing will change"
say ""

# ---- skills ----------------------------------------------------------------
if wants skills && [ -d "$REPO/skills" ]; then
  [ $UNINSTALL -eq 0 ] && run mkdir -p "$ROOT/.agents/skills" "$ROOT/.claude/skills"
  for src in "$REPO"/skills/*/; do
    name="$(basename "$src")"
    canon="$ROOT/.agents/skills/$name"
    if [ $UNINSTALL -eq 1 ]; then
      remove_at "$ROOT/.claude/skills/$name"; remove_at "$canon"
    else
      install_canonical skill "${src%/}" "$canon" || continue
      install_alias "$canon" "$ROOT/.claude/skills/$name" || true
      ok "skill    $name"
    fi
  done
fi

# ---- subagents -------------------------------------------------------------
if wants agents && [ -d "$REPO/agents" ]; then
  [ $UNINSTALL -eq 0 ] && run mkdir -p "$ROOT/.claude/agents" "$ROOT/.cursor/agents" "$ROOT/.codex/agents"
  for src in "$REPO"/agents/*.md; do
    [ -e "$src" ] || continue
    name="$(basename "$src")"
    canon="$ROOT/.claude/agents/$name"
    if [ $UNINSTALL -eq 1 ]; then
      remove_generated "$ROOT/.codex/agents/${name%.md}.toml"
      remove_at "$ROOT/.cursor/agents/$name"; remove_at "$canon"
    else
      install_canonical agent "$src" "$canon" || continue
      install_alias "$canon" "$ROOT/.cursor/agents/$name" || true
      generate_codex_agent "$src" "$ROOT/.codex/agents/${name%.md}.toml"
      ok "subagent $name"
    fi
  done
fi

# ---- commands --------------------------------------------------------------
if wants commands && [ -d "$REPO/commands" ]; then
  [ $UNINSTALL -eq 0 ] && run mkdir -p "$ROOT/.claude/commands"
  for src in "$REPO"/commands/*.md; do
    [ -e "$src" ] || continue
    name="$(basename "$src")"
    canon="$ROOT/.claude/commands/$name"
    if [ $UNINSTALL -eq 1 ]; then
      remove_at "$canon"
    else
      install_canonical command "$src" "$canon" || continue
      ok "command  $name"
    fi
  done
fi

say ""
if [ $UNINSTALL -eq 1 ]; then
  say "${C_B}Removed $CREATED entries.${C_0}"
  [ $SKIPPED -gt 0 ] && warn "$SKIPPED left in place because they were not links."
else
  say "${C_B}Linked $CREATED entries.${C_0}"
  [ $SKIPPED -gt 0 ] && warn "$SKIPPED skipped because something real was already there."
  say ""
  say "  skills     $(short "$ROOT")/.agents/skills   ${C_DIM}Codex, Cursor${C_0}"
  say "             $(short "$ROOT")/.claude/skills   ${C_DIM}Claude Code, Cursor${C_0}"
  say "  subagents  $(short "$ROOT")/.claude/agents   ${C_DIM}Claude Code, Cursor${C_0}"
  say "             $(short "$ROOT")/.cursor/agents   ${C_DIM}Cursor${C_0}"
  say "             $(short "$ROOT")/.codex/agents    ${C_DIM}Codex, generated TOML${C_0}"
  say "  commands   $(short "$ROOT")/.claude/commands ${C_DIM}Claude Code${C_0}"
  say ""
  say "Restart your agent, then try ${C_B}/staff-review${C_0}."
  if [ "$SCOPE" = "project" ]; then
    say ""
    info "Commit these directories if you want teammates to get them without running this script."
  fi
fi
say ""
