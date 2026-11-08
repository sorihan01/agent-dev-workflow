# After merge

Work isn't done when the PR opens, or when it merges. It's done when it is checked on production and written down.

1. **Arm the watch.** Right after opening a PR, run `tools/wait-for-merge.sh <owner/repo> <pr>` in the background. Merging stays the human's.
2. **When it fires, run `/landed`.** Don't wait to be told "merged".
3. **Production checks are read-only.** Never write to production data to prove a point. A check that needs a write (a real payment, a real email) is the human's to run; say so and leave it unticked.
4. **Bad news first.** A FAIL, a ❌ or an unrun check leads the report.
5. **One evidence note per ticket, edited in place.** Never a second one.
6. **One log entry per landing**, in `deliverables.md`, past tense, with the measured result or `unknown`.
