#!/usr/bin/env bash
#
# Copies the agent directories in this repo into your home directory or a
# project. A plain `cp -R .agents .claude .codex <target>/` does the same thing;
# this exists for the parts a copy cannot do: merging into directories that
# already have your own files, telling you what changed, and undoing it.
#
#   ./install.sh                      ask where to install
#   ./install.sh --user               into $HOME
#   ./install.sh --project [path]     into a project, default the current directory
#   ./install.sh --only skills        skills or agents. repeatable
#   ./install.sh --dry-run --user     print the actions without doing them
#   ./install.sh --uninstall --user   remove the entries this repo provides
#   ./install.sh --force              replace files that are in the way

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

SCOPE=""
ROOT=""
UNINSTALL=0
DRY=0
FORCE=0
ONLY=()

C_DIM=$'\033[2m'; C_B=$'\033[1m'; C_G=$'\033[32m'; C_Y=$'\033[33m'; C_R=$'\033[31m'; C_0=$'\033[0m'
if [ ! -t 1 ]; then C_DIM=""; C_B=""; C_G=""; C_Y=""; C_R=""; C_0=""; fi

say()  { printf '%s\n' "$*"; }
info() { printf '%s%s%s\n' "$C_DIM" "$*" "$C_0"; }
ok()   { printf '%s  ok%s  %s\n' "$C_G" "$C_0" "$*"; }
warn() { printf '%swarn%s  %s\n' "$C_Y" "$C_0" "$*"; }
die()  { printf '%serror%s %s\n' "$C_R" "$C_0" "$*" >&2; exit 1; }

short() { case "$1" in "$HOME") printf '~' ;; "$HOME"/*) printf '~%s' "${1#$HOME}" ;; *) printf '%s' "$1" ;; esac; }

usage() { sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; $d'; exit 0; }

while [ $# -gt 0 ]; do
  case "$1" in
    --user)      SCOPE="user" ;;
    --project)   SCOPE="project"
                 if [ "${2-}" ] && [ "${2#--}" = "$2" ]; then ROOT="$2"; shift; fi ;;
    --only)      [ "${2-}" ] || die "--only needs a value: skills or agents"
                 ONLY+=("$2"); shift ;;
    --uninstall) UNINSTALL=1 ;;
    --dry-run)   DRY=1 ;;
    --force)     FORCE=1 ;;
    -h|--help)   usage ;;
    *)           die "unknown option: $1" ;;
  esac
  shift
done

[ ${#ONLY[@]} -eq 0 ] && ONLY=(skills agents)
wants() { local w; for w in "${ONLY[@]}"; do [ "$w" = "$1" ] && return 0; done; return 1; }

if [ -z "$SCOPE" ]; then
  [ -t 0 ] || die "no scope given and no terminal to ask on. Pass --user or --project"
  say ""
  say "${C_B}Where should these be installed?${C_0}"
  say ""
  say "  1) User level     ${C_DIM}$HOME${C_0}"
  say "     ${C_DIM}available in every project on this machine${C_0}"
  say "  2) Project level  ${C_DIM}$(pwd)${C_0}"
  say "     ${C_DIM}commit them and the whole team, and any cloud agent, gets them${C_0}"
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
[ "$ROOT" = "$REPO" ] && die "that would install this repo into itself. Pass --project <path>"

run() { if [ $DRY -eq 1 ]; then info "would: $*"; else "$@"; fi; }

CHANGED=0
SKIPPED=0

# Copies one entry, replacing an entry this repo previously installed but never
# silently overwriting something the user wrote.
place() {                       # $1 source, $2 destination, $3 label
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then
    if [ $FORCE -eq 0 ] && ! diff -r -q "$src" "$dst" >/dev/null 2>&1; then
      warn "differs from ours, skipped: $(short "$dst")   (--force to replace)"
      SKIPPED=$((SKIPPED+1)); return 1
    fi
    run rm -rf "$dst"
  fi
  run cp -R "$src" "$dst"
  CHANGED=$((CHANGED+1))
  ok "$3"
}

# Removes an entry only when it still matches what this repo ships.
unplace() {                     # $1 source, $2 destination
  local src="$1" dst="$2"
  [ -e "$dst" ] || return 0
  if [ $FORCE -eq 0 ] && ! diff -r -q "$src" "$dst" >/dev/null 2>&1; then
    warn "modified locally, left alone: $(short "$dst")   (--force to remove)"
    SKIPPED=$((SKIPPED+1)); return 0
  fi
  run rm -rf "$dst"
  CHANGED=$((CHANGED+1))
}

say ""
if [ $UNINSTALL -eq 1 ]; then
  say "${C_B}Removing from $(short "$ROOT")${C_0}"
else
  say "${C_B}Installing into $(short "$ROOT")${C_0}"
fi
[ $DRY -eq 1 ] && info "dry run, nothing will change"
say ""

# Skills go to both paths: Claude Code reads .claude/skills, Codex reads
# .agents/skills, Cursor reads either.
if wants skills; then
  [ $UNINSTALL -eq 0 ] && run mkdir -p "$ROOT/.agents/skills" "$ROOT/.claude/skills"
  for src in "$REPO"/.agents/skills/*/; do
    name="$(basename "$src")"
    if [ $UNINSTALL -eq 1 ]; then
      unplace "${src%/}" "$ROOT/.agents/skills/$name"
      unplace "${src%/}" "$ROOT/.claude/skills/$name"
    else
      place "${src%/}" "$ROOT/.agents/skills/$name" "skill    $name" || true
      place "${src%/}" "$ROOT/.claude/skills/$name" "" >/dev/null || true
    fi
  done
fi

# Subagents: markdown for Claude Code and Cursor, TOML for Codex.
if wants agents; then
  [ $UNINSTALL -eq 0 ] && run mkdir -p "$ROOT/.claude/agents" "$ROOT/.codex/agents"
  for src in "$REPO"/.claude/agents/*.md; do
    [ -e "$src" ] || continue
    name="$(basename "$src")"
    toml="$REPO/.codex/agents/${name%.md}.toml"
    if [ $UNINSTALL -eq 1 ]; then
      unplace "$src" "$ROOT/.claude/agents/$name"
      [ -e "$toml" ] && unplace "$toml" "$ROOT/.codex/agents/${name%.md}.toml"
    else
      place "$src" "$ROOT/.claude/agents/$name" "subagent $name" || true
      [ -e "$toml" ] && { place "$toml" "$ROOT/.codex/agents/${name%.md}.toml" "" >/dev/null || true; }
    fi
  done
fi

say ""
if [ $UNINSTALL -eq 1 ]; then
  say "${C_B}Removed $CHANGED entries.${C_0}"
  [ $SKIPPED -gt 0 ] && warn "$SKIPPED left in place because they had local changes."
else
  say "${C_B}Installed $CHANGED entries.${C_0}"
  [ $SKIPPED -gt 0 ] && warn "$SKIPPED skipped because something different was already there."
  say ""
  say "  skills     $(short "$ROOT")/.agents/skills   ${C_DIM}Codex, Cursor${C_0}"
  say "             $(short "$ROOT")/.claude/skills   ${C_DIM}Claude Code, Cursor${C_0}"
  say "  subagents  $(short "$ROOT")/.claude/agents   ${C_DIM}Claude Code, Cursor${C_0}"
  say "             $(short "$ROOT")/.codex/agents    ${C_DIM}Codex${C_0}"
  say ""
  say "Restart your agent, then try ${C_B}/staff-review${C_0}."
fi
say ""
