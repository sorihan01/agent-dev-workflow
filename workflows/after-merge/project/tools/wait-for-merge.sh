#!/usr/bin/env bash
# Wait until a pull request is merged or closed, then print one line. Run it in the background
# right after opening the PR; when it fires, run /landed. Re-arm it if it times out.
#   tools/wait-for-merge.sh <owner/repo> <pr-number> [minutes]
# Exit 0 merged, 2 closed without merge, 1 timeout. Read-only: polls GitHub once a minute.
# Needs the GitHub CLI (`gh`), logged in. WAIT_SECONDS changes the poll interval (tests use 0).
set -u
repo="${1:?owner/repo}"; pr="${2:?pr number}"; minutes="${3:-120}"
for _ in $(seq 1 "$minutes"); do
  read -r state merged <<<"$(gh pr view "$pr" -R "$repo" --json state,mergedAt --jq '"\(.state) \(.mergedAt // "-")"' 2>/dev/null || echo "? -")"
  case "$state" in
    MERGED) echo "MERGED: $repo #$pr at $merged"; exit 0 ;;
    CLOSED) echo "CLOSED WITHOUT MERGE: $repo #$pr"; exit 2 ;;
  esac
  sleep "${WAIT_SECONDS:-60}"
done
echo "TIMEOUT: $repo #$pr still open after $minutes minutes; re-arm"
exit 1
