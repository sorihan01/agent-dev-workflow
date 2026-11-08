#!/usr/bin/env bash
# One desk per ticket: a git worktree per repo, its own ports and a status file, so two agent
# sessions never share a checkout or a port.
#   tools/desk.sh open <TICKET> <slug> <repo>...    worktrees on one branch, env files copied, ports picked
#   tools/desk.sh run <TICKET> <repo> -- <cmd...>   run a command in that worktree with DESK_PORT_<REPO> set
#   tools/desk.sh check <TICKET> <1|2|3> <todo|pass|fail>   record one of the ticket's three checks
#   tools/desk.sh claim <TICKET> "<session name>"   who is working on it ("-" clears)
#   tools/desk.sh wait <TICKET> "<what it waits for>"   a person, a date or an action ("-" clears)
#   tools/desk.sh list                              every open desk
#   tools/desk.sh done <TICKET>                     remove the worktrees (refuses if one is dirty) and the desk
# Settings: desk.conf next to this folder. Desks live in .desk/<TICKET>.json (gitignored).
# Needs bash, git and python3.
set -euo pipefail

ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
CONF="${DESK_CONF:-$ROOT/desk.conf}"
STATUS="$ROOT/.desk"
die() { echo "desk: $*" >&2; exit 1; }
[ -f "$CONF" ] || die "no settings file at $CONF"
# shellcheck source=/dev/null
. "$CONF"
: "${TICKET_RE:?desk.conf: TICKET_RE}" "${BRANCH_PATTERN:?desk.conf: BRANCH_PATTERN}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"; SLOTS="${SLOTS:-9}"; ENV_FILES="${ENV_FILES:-}"
mkdir -p "$STATUS"

# Read or change one desk file. Usage: desk_json <file> <python expression using d>.
desk_json() { python3 -c 'import json,sys; f=sys.argv[1]; d=json.load(open(f)); r=eval(sys.argv[2]); print(r if r is not None else "")' "$1" "$2"; }
desk_set() { python3 -c 'import json,sys; f=sys.argv[1]; d=json.load(open(f)); exec(sys.argv[2]); json.dump(d,open(f,"w"),indent=2)' "$1" "$2"; }

repo_field() { # repo_field <name> <1-4>: path, base port, install command of one repo in desk.conf
  local line
  for line in "${REPOS[@]}"; do
    IFS='|' read -r n p port inst <<<"$line"
    if [ "$n" = "$1" ]; then case "$2" in 2) echo "$p" ;; 3) echo "$port" ;; 4) echo "$inst" ;; esac; return 0; fi
  done
  return 1
}
repo_names() { local line; for line in "${REPOS[@]}"; do echo "${line%%|*}"; done; }
main_path() { local p; p="$(repo_field "$1" 2)" || die "no repo '$1' in desk.conf (have: $(repo_names | tr '\n' ' '))"; (cd "$ROOT/$p" && pwd); }
worktree_path() { local m; m="$(main_path "$1")"; echo "$(dirname "$m")/$(basename "$m")-$(echo "$2" | tr 'A-Z' 'a-z')"; }
need_ticket() { [[ "${1:-}" =~ $TICKET_RE ]] || die "ticket '${1:-}' does not match TICKET_RE ($TICKET_RE)"; }
desk_file() { echo "$STATUS/$1.json"; }
need_desk() { [ -f "$(desk_file "$1")" ] || die "no desk for $1 (open one: desk.sh open $1 <slug> <repo>...)"; }

cmd="${1:-}"; shift || true
case "$cmd" in
open)
  ticket="${1:-}"; slug="${2:-}"; shift 2 || true
  need_ticket "$ticket"
  [[ "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] && [ "${#slug}" -le 30 ] || die "slug: lowercase letters, digits and dashes, 30 characters at most"
  [ "$#" -ge 1 ] || die "name at least one repo from desk.conf"
  file="$(desk_file "$ticket")"
  [ -f "$file" ] && die "$ticket already has a desk"
  lower="$(echo "$ticket" | tr 'A-Z' 'a-z')"
  branch="${BRANCH_PATTERN//\{ticket\}/$lower}"; branch="${branch//\{slug\}/$slug}"

  used="$(for f in "$STATUS"/*.json; do [ -e "$f" ] && desk_json "$f" 'd["slot"]'; done; true)"
  slot=""
  for s in $(seq 1 "$SLOTS"); do grep -qx "$s" <<<"$used" || { slot=$s; break; }; done
  [ -n "$slot" ] || die "all $SLOTS slots are in use"

  worktrees=()
  for r in "$@"; do
    main="$(main_path "$r")"; wt="$(worktree_path "$r" "$ticket")"
    [ -d "$wt" ] && die "$wt already exists"
    base="$DEFAULT_BRANCH"
    if git -C "$main" remote get-url origin >/dev/null 2>&1; then
      git -C "$main" fetch -q origin "$DEFAULT_BRANCH" && base="origin/$DEFAULT_BRANCH"
    fi
    if git -C "$main" show-ref -q --verify "refs/heads/$branch"; then
      git -C "$main" worktree add -q "$wt" "$branch"
    else
      git -C "$main" worktree add -q -b "$branch" "$wt" "$base"
    fi
    for env in $ENV_FILES; do
      [ -f "$main/$env" ] || continue
      sed_args=()
      for n in $(repo_names); do
        p="$(repo_field "$n" 3)"; [ "${p:-0}" -gt 0 ] || continue
        # the port, not a longer number that starts with it (portable: BSD sed has no \b)
        sed_args+=(-e "s/(localhost|127\\.0\\.0\\.1):$p([^0-9]|\$)/\\1:$((p + slot))\\2/g")
      done
      if [ "${#sed_args[@]}" -gt 0 ]; then sed -E "${sed_args[@]}" "$main/$env" > "$wt/$env"; else cp "$main/$env" "$wt/$env"; fi
    done
    inst="$(repo_field "$r" 4)"
    [ -z "$inst" ] || (cd "$wt" && bash -c "$inst")
    worktrees+=("$wt")
    echo "ready: $wt on $branch"
  done

  python3 - "$file" "$ticket" "$branch" "$slot" "${worktrees[@]}" <<'PY'
import json, sys
f, ticket, branch, slot, *wts = sys.argv[1:]
json.dump({"ticket": ticket, "checks": [{"status": "todo"}] * 3, "branch": branch,
           "slot": int(slot), "worktrees": wts}, open(f, "w"), indent=2)
PY
  echo
  echo "$ticket desk, slot $slot. Ports:"
  for n in $(repo_names); do p="$(repo_field "$n" 3)"; [ "${p:-0}" -gt 0 ] && echo "  $n  $((p + slot))"; done
  true
  ;;
run)
  ticket="${1:-}"; repo="${2:-}"; shift 2 || true
  [ "${1:-}" = "--" ] && shift
  need_ticket "$ticket"; need_desk "$ticket"; [ "$#" -ge 1 ] || die "usage: desk.sh run <TICKET> <repo> -- <command...>"
  wt="$(worktree_path "$repo" "$ticket")"; [ -d "$wt" ] || die "$ticket's desk has no worktree for $repo"
  slot="$(desk_json "$(desk_file "$ticket")" 'd["slot"]')"
  for n in $(repo_names); do
    p="$(repo_field "$n" 3)"; [ "${p:-0}" -gt 0 ] || continue
    export "DESK_PORT_$(echo "$n" | tr 'a-z-' 'A-Z_')=$((p + slot))"
  done
  cd "$wt" && exec "$@"
  ;;
check)
  ticket="${1:-}"; n="${2:-}"; st="${3:-}"
  need_ticket "$ticket"; need_desk "$ticket"
  [[ "$n" =~ ^[123]$ ]] && [[ "$st" =~ ^(todo|pass|fail)$ ]] || die "usage: desk.sh check <TICKET> <1|2|3> <todo|pass|fail>"
  desk_set "$(desk_file "$ticket")" "d['checks'][$((n - 1))]={'status':'$st'}"
  echo "$ticket check $n: $st"
  ;;
claim|wait)
  ticket="${1:-}"; value="${2:-}"
  need_ticket "$ticket"; need_desk "$ticket"
  field=session; max=40; [ "$cmd" = wait ] && { field=waiting; max=80; }
  [ -n "$value" ] || die "usage: desk.sh $cmd <TICKET> \"text\" (or - to clear)"
  if [ "$value" = "-" ]; then
    desk_set "$(desk_file "$ticket")" "d.pop('$field', None)"
  else
    [[ "$value" =~ ^[A-Za-z0-9][A-Za-z0-9\ ,.:/_-]*$ ]] && [ "${#value}" -le "$max" ] \
      || die "$field: letters, digits, spaces and , . : / _ - only, $max characters at most"
    desk_set "$(desk_file "$ticket")" "d['$field']='$value'"
  fi
  echo "$ticket $field: $(desk_json "$(desk_file "$ticket")" "d.get('$field','(none)')")"
  ;;
list)
  found=0
  for f in "$STATUS"/*.json; do
    [ -e "$f" ] || continue; found=1
    desk_json "$f" '"%s  slot %s  %s  session: %s  waiting: %s  checks: %s" % (d["ticket"], d["slot"], d["branch"], d.get("session","-"), d.get("waiting","-"), " ".join(c["status"] for c in d["checks"]))'
  done
  [ "$found" = 1 ] || echo "no desks"
  ;;
done)
  ticket="${1:-}"; need_ticket "$ticket"; need_desk "$ticket"
  file="$(desk_file "$ticket")"
  while IFS= read -r wt; do
    [ -n "$wt" ] && [ -d "$wt" ] || continue
    [ -z "$(git -C "$wt" status --porcelain)" ] || die "$wt has uncommitted changes; commit or discard them first"
  done < <(desk_json "$file" '"\n".join(d["worktrees"])')
  while IFS= read -r wt; do
    [ -n "$wt" ] && [ -d "$wt" ] || continue
    # --force only because ignored files (env files, installed packages) are present; dirty was refused above
    git -C "$wt" worktree remove --force "$wt"
    echo "removed $wt (branch kept)"
  done < <(desk_json "$file" '"\n".join(d["worktrees"])')
  rm "$file"
  echo "desk $ticket closed"
  ;;
*)
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  [ -z "$cmd" ] || exit 1
  ;;
esac
