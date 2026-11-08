#!/usr/bin/env bash
# Land one workspace branch on the default branch, rebuild NEXT.md, remove the branch's worktree.
#   tools/land.sh <branch>          land, then remove the worktree and the branch
#   tools/land.sh <branch> --keep   land, keep the worktree
# Flow for every session: edit .next/<TICKET>.md and other shared files in a worktree
# (git worktree add ../<workspace>-<ticket> -b <branch>), commit there, then run this.
# It rebases the branch when the default branch moved, and refuses when another session has
# uncommitted edits to a file the branch changes. Fast-forward only: never a merge commit,
# never a force-push.
set -euo pipefail

ws="$(git -C "$(dirname "$0")" rev-parse --path-format=absolute --git-common-dir | xargs dirname)"
conf="${DESK_CONF:-$ws/desk.conf}"
DEFAULT_BRANCH=main
# shellcheck source=/dev/null
[ -f "$conf" ] && . "$conf"
main="${DEFAULT_BRANCH:-main}"
branch="${1:?branch to land}"
keep="${2:-}"
fail() { echo "STOP: $1" >&2; exit 1; }

[ "$branch" != "$main" ] || fail "nothing to land: $branch is the default branch"
git -C "$ws" rev-parse -q --verify "refs/heads/$branch" >/dev/null || fail "no branch $branch"
[ "$(git -C "$ws" branch --show-current)" = "$main" ] || fail "$ws is not on $main"

wt="$(git -C "$ws" worktree list --porcelain | awk -v b="refs/heads/$branch" '/^worktree /{w=substr($0,10)} $0=="branch "b{print w}')"
if [ -n "$wt" ]; then
  [ -z "$(git -C "$wt" status --porcelain --untracked-files=no)" ] || fail "$wt has uncommitted changes; commit them first"
fi

if ! git -C "$ws" merge-base --is-ancestor "$main" "$branch"; then
  [ -n "$wt" ] || fail "$main moved and $branch has no worktree to rebase in"
  git -C "$wt" rebase -q "$main" || { git -C "$wt" rebase --abort; fail "rebase of $branch onto $main conflicts; resolve in $wt"; }
fi

changed="$(git -C "$ws" diff --name-only "$main" "$branch")"
[ -n "$changed" ] || echo "note: $branch has no changes against $main"
dirty="$(git -C "$ws" status --porcelain --untracked-files=no | cut -c4- | grep -vx NEXT.md || true)" # NEXT.md is a build output
overlap="$(comm -12 <(printf '%s\n' "$changed" | sort -u) <(printf '%s\n' "$dirty" | sort -u) | sed '/^$/d')"
[ -z "$overlap" ] || fail "another session has uncommitted edits to: $overlap"

git -C "$ws" merge -q --ff-only "$branch"
[ ! -x "$ws/tools/next.sh" ] || bash "$ws/tools/next.sh" || true
echo "landed $branch at $(git -C "$ws" log -1 --oneline)"

if [ "$keep" != "--keep" ]; then
  [ -z "$wt" ] || git -C "$ws" worktree remove "$wt"
  git -C "$ws" branch -d "$branch"
fi
