#!/usr/bin/env bash
# Builds NEXT.md from .next/, one small file per ticket, so parallel sessions never edit the same file.
#   tools/next.sh                  write NEXT.md (gitignored: every checkout builds its own)
#   tools/next.sh --lint <TICKET>  exit 1 if that ticket's file has too many lines or a line too long
#   tools/next.sh --check          exit 1 if NEXT.md is out of date with .next/
#   tools/next.sh --tickets        list the ticket of every ticket file, one per line
#
# .next/ layout:
#   _header.md     title, Current Status, the "## Immediate Next Steps" heading
#   _footer.md     Potential Roadblocks and anything else that goes after the items
#   <TICKET>.md    the item lines for one ticket
#   _general.md    items with no ticket
#   README.md      how this folder works (skipped)
# Item line: a 3-digit order key, one space, then the item exactly as NEXT.md shows it:
#   120 4. **Login rate limit:** live; next: alert on spikes → ABC-42
# Items print sorted by key; a new item takes a free key between its neighbours. Lines that don't
# start with a 3-digit key are notes for the agent and never printed. A landed ticket deletes its file.
# Limits: NEXT_MAX_LINES (2) and NEXT_MAX_CHARS (220) per ticket file; NEXT_MAX_BYTES (8192) warns.
set -euo pipefail

ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
DIR="$ROOT/.next"
OUT="$ROOT/NEXT.md"
MAX_LINES="${NEXT_MAX_LINES:-2}"; MAX_CHARS="${NEXT_MAX_CHARS:-220}"; MAX_BYTES="${NEXT_MAX_BYTES:-8192}"

ticket_files() { find "$DIR" -maxdepth 1 -name '*.md' ! -name '_*' ! -name 'README.md' "$@"; }

if [ "${1:-}" = "--lint" ]; then
  f="$DIR/${2:?ticket, e.g. ABC-42}.md"
  [ -f "$f" ] || exit 0
  n="$(grep -cE '^[0-9]{3} ' "$f" || true)"
  long="$(grep -E '^[0-9]{3} ' "$f" | awk -v m="$MAX_CHARS" 'length > m' | wc -l | tr -d ' ')"
  [ "$n" -le "$MAX_LINES" ] && [ "$long" -eq 0 ] || {
    echo "next: $f has $n item lines ($long over $MAX_CHARS chars); max $MAX_LINES lines, $MAX_CHARS chars each" >&2; exit 1; }
  exit 0
fi

if [ "${1:-}" = "--tickets" ]; then
  ticket_files -exec basename {} .md \; | LC_ALL=C sort
  exit 0
fi

[ -f "$DIR/_header.md" ] && [ -f "$DIR/_footer.md" ] || { echo "next: $DIR/_header.md or _footer.md missing" >&2; exit 1; }

build() {
  cat "$DIR/_header.md"
  find "$DIR" -maxdepth 1 -name '*.md' ! -name '_header.md' ! -name '_footer.md' ! -name 'README.md' -print0 \
    | xargs -0 cat 2>/dev/null \
    | grep -E '^[0-9]{3} ' \
    | LC_ALL=C sort -s -k1,1n \
    | cut -d' ' -f2- || true
  cat "$DIR/_footer.md"
}

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
build > "$tmp"

if [ "${1:-}" = "--check" ]; then
  cmp -s "$tmp" "$OUT" || { echo "next: NEXT.md is out of date; run tools/next.sh" >&2; exit 1; }
  exit 0
fi

size="$(wc -c < "$tmp" | tr -d ' ')"
if [ "$size" -gt "$MAX_BYTES" ]; then
  echo "next: warning, $size bytes (over $MAX_BYTES); longest ticket files: $(ticket_files -exec wc -c {} + | grep -v ' total$' | sort -rn | head -3 | awk '{print $2}' | xargs -n1 basename | tr '\n' ' ')" >&2
fi
cmp -s "$tmp" "$OUT" || cp "$tmp" "$OUT"
items="$(find "$DIR" -maxdepth 1 -name '*.md' ! -name '_header.md' ! -name '_footer.md' ! -name 'README.md' -print0 | xargs -0 cat 2>/dev/null | grep -cE '^[0-9]{3} ' || true)"
echo "NEXT.md: $size bytes, $items items"
