# generated-views: summaries that can't invent a fact

**For:** anyone who asks an agent for a status page, a dashboard, a "where are we" doc, and has caught it writing a confident number nobody measured.

**The problem:** ask an agent to "summarize the project" and it writes prose. Some of it is copied, some is remembered, some is made up, and you can't tell which. A week later the summary is stale and still reads as true.

## What it does

A view is a Markdown table **built** from the documents that own each fact. You write a small spec; the builder fills it in.

```json
{ "label": "Decisions recorded", "source": "decisions", "extract": "count:20*.md" }
{ "label": "Next step",          "source": "NEXT.md",   "extract": "section:Immediate Next Steps" }
```

```
| Fact               | Value                   | Source       |
| Decisions recorded | 3                       | decisions    |
| Next step          | 1. Ship the export button | NEXT.md    |
```

Three rules hold it together, and each one fails the build when broken:

1. **Every row has a source that exists.** A renamed or deleted source → exit 1, naming it.
2. **Nothing is typed.** Numbers come from `count:` (the file system), text is copied from the source verbatim. A fact the source doesn't contain → exit 1, not a blank or a guess.
3. **Stale is a failure.** `--check` rebuilds in memory and compares; any difference → exit 1. The SessionStart hook runs it, so the agent knows a view is out of date before quoting it.

## What's in it

| Path | Goes to | Does |
|---|---|---|
| `project/tools/build-view.py` | `tools/build-view.py` | Builds every `views/<name>.json` into `views/<name>.md`; `--check` for staleness. |
| `project/views/status.json` | `views/status.json` | Example spec: next step, blockers, decision count, tracker. Reads [core-loop](../core-loop/)'s files. |
| `project/rules/generated-views.md` | `rules/generated-views.md` | The three rules, imported from `CLAUDE.md`. |
| `hooks/hooks.json` | `.claude/settings.json` | SessionStart: `--check --quiet`, shows stale views, never blocks. |

Needs `python3`. No packages.

**Extract rules:** `count:<glob>` (files in a folder) · `line:<regex>` (first matching line, group 1 if given) · `section:<heading>` (the lines under a `##` heading).

## Install

```bash
./install.sh core-loop ~/path/to/your-project        # the example spec reads its NEXT.md and AGENTS.md
./install.sh generated-views ~/path/to/your-project
python3 tools/build-view.py                           # run inside the project
```

or as a plugin: `/plugin install generated-views@agent-dev-workflow`, then `./install.sh generated-views <project> --files-only`.

Without core-loop, edit `views/status.json` to point at your own documents.

## Try it in 5 minutes

1. `python3 tools/build-view.py`, then open `views/status.md`.
2. Add a file to `decisions/`, run `python3 tools/build-view.py --check`: exit 1, "status.md is stale".
3. Point one row's `source` at a file that doesn't exist: the build fails and names it.
4. Ask the agent to "add the monthly revenue to the status view". With these rules it has to find a source document for it first, or tell you there isn't one.

## Limits

- Three extract rules, on purpose. Anything that needs real parsing (a JSON field, an API) belongs in your own builder. The pattern to copy is "every node carries a source path that must exist, exit non-zero otherwise".
- It proves a fact was **copied**, not that the source is right. Pair it with [decision-memory](../decision-memory/) so the sources stay current.
