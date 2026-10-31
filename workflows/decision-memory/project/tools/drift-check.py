#!/usr/bin/env python3
"""Find live documents that still use a retired name.

Reads deprecated-terms.txt (one rule per line: old | new | where the rule lives)
and scans every .md / .mdc file in the project. A hit is skipped when:
  - the file carries a "> **Superseded" stamp (it is history, kept on purpose)
  - the line also names the new term, or reads as a rename note
    ("renamed", "formerly", "deprecated", "superseded", "→")
  - the file sits in decisions/ (the record of the change itself)

    python3 tools/drift-check.py          # table, exit 1 if anything is stale
    python3 tools/drift-check.py --quiet  # silent when clean (SessionStart hook)
"""
import os
import re
import sys

ROOT = os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
TERMS_FILE = os.path.join(ROOT, "deprecated-terms.txt")
SKIP_DIRS = {"node_modules", "decisions", "dist", "build", "vendor"}
RENAME_NOTE = re.compile(r"deprecated|formerly|renamed|superseded|old name|→", re.I)
quiet = "--quiet" in sys.argv


def load_terms():
    if not os.path.exists(TERMS_FILE):
        return []
    terms = []
    for raw in open(TERMS_FILE, encoding="utf-8"):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = [p.strip() for p in line.split("|")] + ["", ""]
        if parts[0]:
            terms.append((parts[0], parts[1], parts[2]))
    return terms


def phrase(text):  # whole phrase, case-insensitive: "Atlas" matches "atlas", not "Atlassian"
    return re.compile(r"(?<!\w)" + re.escape(text) + r"(?!\w)", re.I)


def docs():
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")]
        for name in filenames:
            if name.endswith((".md", ".mdc")):
                yield os.path.join(dirpath, name)


terms = load_terms()
if not terms:
    if not quiet:
        print("drift-check: no deprecated-terms.txt rules yet, nothing to check")
    sys.exit(0)

compiled = [(old, new, where, phrase(old), phrase(new) if new else None) for old, new, where in terms]
stale, scanned = [], 0
for path in docs():
    scanned += 1
    text = open(path, encoding="utf-8", errors="replace").read()
    if re.search(r"^> \*\*Superseded", text, re.M):
        continue
    for n, line in enumerate(text.splitlines(), 1):
        for old, new, where, old_re, new_re in compiled:
            if old_re.search(line) and not RENAME_NOTE.search(line) and not (new_re and new_re.search(line)):
                stale.append((os.path.relpath(path, ROOT), n, old, new, where))

if stale:
    print(f"drift-check: {len(stale)} live mention(s) of retired names. Fix each, or stamp the file "
          "'> **Superseded YYYY-MM-DD** by <path>' if it is history:")
    for path, n, old, new, where in stale:
        print(f"  {path}:{n}  \"{old}\" → \"{new or '(removed)'}\"" + (f"  (rule: {where})" if where else ""))
    sys.exit(1)
if not quiet:
    print(f"drift-check: clean ({len(terms)} retired names, {scanned} documents)")
