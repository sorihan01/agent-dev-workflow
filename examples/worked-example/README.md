# Worked example: a scheduled job that silently stopped

One real loop from 2026-10-31, in a small production web app that reads weekly prices from two stores' flyers. Every block below is copied from the real artefacts. The only edits: the app is "the price app", the stores are "Store A" and "Store B", file paths are shortened, and lines unrelated to this change are cut (`…`).

## 1. The problem shows up in the log, bad news first

The agent's first job was writing down what was true, before anything was fixed. From `NEXT.md` → Current Status:

> ⚠️ no prices since the Oct 8 week, empty-week view proposed

The cause it found: the weekly price read only ran when someone started it on a laptop. Nobody had since the Oct 8–14 week, so every price row went empty.

## 2. The human decides; the decision is recorded the same session

The founder picked option **b** from the agent's plan card in two words: *"b yes"*. `/decide` turned that into `decisions/2026-10-31-weekly-run-on-github-actions.md`:

> **Context:** no prices were read after the Oct 8–14 week; `npm run weekly` only ran when someone started it on the Mac, so every row went empty.
> **Decision (founder):** "b yes": `.github/workflows/weekly.yml` runs `node scripts/weekly.ts` on GitHub Actions every Thu, Fri, Sat and Sun at 13:00 UTC, plus a manual run button. The script stays idempotent (a stored week is skipped, $0), keeps its $3 cap and `npm run check` gate, and still deploys to production under `…-weekly-run-deploys-without-review.md`.
> **Consequences:** secrets … live in the repo's GitHub secrets, the only copy outside the root `.env.local`; … a failed run, or a store still without this week's data on Sunday, makes GitHub email the founder. Flyer images downloaded in CI hold only the newest week, so production `/review` loses last week's pages. The "Mac now, NAS later" plan in `AGENTS.md` is superseded.

What to notice: the $3 spend cap and the deploy rule weren't decided again. They point at the earlier decisions that set them.

## 3. The old plan is replaced where it lives, not left beside the new one

The app's `AGENTS.md`, before → after (one clause of a long line):

```diff
- … runs on the Mac now, NAS later: `sharp` replaces the Mac-only `sips`).
+ … runs on GitHub Actions Thu–Sun 13:00 UTC, `.github/workflows/weekly.yml`, secrets in the repo's
+   GitHub secrets, failure = GitHub email (`decisions/2026-10-31-weekly-run-on-github-actions.md`); …
```

A related decision the same day changed how expired prices show. The rule was rewritten in place and names what it replaces: *"… replaces the 2026-10-08 `show_stale_until` limit … Until that build lands, the old `show_stale_until` behaviour is what runs."* It says what is true now, including the part that hasn't been built yet.

## 4. Small commits, one seam each

```
72d58ec fix: Store B week label with ordinal days (OCT 29th) — parser + test
0525bc4 weekly: run on GitHub Actions Thu–Sun (workflow, CI-aware deploy gate, optional env loader, Sunday no-data failure)
845bcd2 weekly: set-ci-secrets.sh for the founder; NEXT logs the cloud run
```

The first commit is a bug the agent found on the way (the Store B parser broke on `OCT 29th (Thu)`). It was fixed with a test as its own commit, not folded into the feature.

## 5. The wrap report: done, but not claimed as working

The `NEXT.md` line written by `/wrap`. It starts with ⚠️, not ✅, because the job hadn't run in the cloud yet:

> ⚠️ 2026-10-31 **Weekly read moved to GitHub Actions; not yet run there (secrets missing).** … Found + fixed on the way: Store B parser broke on `OCT 29th (Thu)` (ordinal days, + test); `.mcp.json` formatting made `npm run check` fail on main. **Checked:** `npm run check` exit 0, dry run reads `2026-10-29, 35 pages`, deploy gate refuses CI without the decision name, workflow `active` on GitHub. …

Every claim has its evidence next to it: an exit code, a dry-run output, a refusal tested on purpose. The one thing that couldn't be checked yet, a real cloud run, is the headline.

The next step was the founder's, because it handles credentials: run `set-ci-secrets.sh`, which the agent wrote. It pipes the keys already on disk straight into GitHub secrets without printing them, and asks for the one key that isn't on disk with hidden input.

## Which workflow did what

| Moment | Workflow |
|---|---|
| Log the problem before fixing it, ⚠️ first | [core-loop](../../workflows/core-loop/) (`NEXT.md`, Stop hook) |
| Plan card with options, wait for "b yes" | core-loop (`/start`) |
| "b yes" becomes a dated record that cites older decisions | [decision-memory](../../workflows/decision-memory/) (`/decide`) |
| "Mac now, NAS later" rewritten in place, not left to rot | decision-memory |
| Checks run for real, the unrun one named as the headline | core-loop (`/wrap`) |
