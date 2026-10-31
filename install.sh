#!/usr/bin/env bash
# Copy one workflow into a project, without the plugin system.
#   ./install.sh <workflow> <project-dir>              files + skills + hooks
#   ./install.sh <workflow> <project-dir> --files-only files only (you installed the plugin)
#   ./install.sh --list                                show the workflows
# Never overwrites a file that already exists in the project; it says which it kept.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

if [ "${1:-}" = "--list" ] || [ $# -lt 2 ]; then
  echo "Workflows:"; for d in "$here"/workflows/*/; do echo "  $(basename "$d")"; done
  [ "${1:-}" = "--list" ] && exit 0
  echo "Usage: ./install.sh <workflow> <project-dir> [--files-only]" >&2; exit 1
fi

name="$1"; target="$(cd "$2" && pwd)"; mode="${3:-}"
src="$here/workflows/$name"
[ -d "$src" ] || { echo "No workflow called '$name'. Run ./install.sh --list" >&2; exit 1; }
echo "Installing $name into $target"

copy_tree() { # copy_tree <from-dir> <to-dir>: copy files that don't exist yet
  local from="$1" to="$2" rel show
  [ -d "$from" ] || return 0
  while IFS= read -r -d '' f; do
    rel="${f#"$from"/}"
    show="${to#"$target"}/$rel"; show="${show#/}"
    if [ -e "$to/$rel" ]; then echo "  kept yours: $show"
    else mkdir -p "$(dirname "$to/$rel")"; cp "$f" "$to/$rel"; echo "  added: $show"; fi
  done < <(find "$from" -type f -print0)
}

copy_tree "$src/project" "$target"

# Rules load through CLAUDE.md, one import line each (AGENTS.md also serves other agents).
for rule in "$src"/project/AGENTS.md "$src"/project/rules/*.md; do
  [ -e "$rule" ] || continue
  line="@${rule#"$src"/project/}"
  touch "$target/CLAUDE.md"
  grep -qxF "$line" "$target/CLAUDE.md" || { echo "$line" >> "$target/CLAUDE.md"; echo "  CLAUDE.md: imports $line"; }
done

if [ "$mode" != "--files-only" ]; then
  copy_tree "$src/skills" "$target/.claude/skills"
  if [ -d "$src/hooks" ]; then
    mkdir -p "$target/.claude/hooks"
    for f in "$src"/hooks/*; do
      [ "$(basename "$f")" = "hooks.json" ] && continue
      dest="$target/.claude/hooks/$(basename "$f")"
      [ -e "$dest" ] && echo "  kept yours: .claude/hooks/$(basename "$f")" || { cp "$f" "$dest"; echo "  added: .claude/hooks/$(basename "$f")"; }
    done
    [ -f "$src/hooks/hooks.json" ] && python3 "$here/scripts/merge_hooks.py" "$src/hooks/hooks.json" "$target/.claude/settings.json"
  fi
fi

gi="$target/.gitignore"; touch "$gi"
grep -qxF ".claude/.session/" "$gi" || { echo ".claude/.session/" >> "$gi"; echo "  .gitignore: .claude/.session/"; }
echo "Done. Start a new Claude Code session in $target so the rules and skills load."
