# .next/: the running log, one file per ticket

`tools/next.sh` builds `NEXT.md` from these files. `NEXT.md` is gitignored, so every checkout builds its own, and two sessions never edit the same file.

- One file per ticket, `<TICKET>.md`: at most 2 item lines of 220 characters (`tools/next.sh --lint <TICKET>`).
- An item line is a 3-digit order key, a space, then the item as `NEXT.md` shows it: what is true now, what is next, and the ticket.
- Write what is true now. A new fact rewrites the line; no history.
- A landed ticket deletes its file. An open follow-up moves to the open ticket it belongs to first.

## Sweep: tickets closed elsewhere

1. `tools/next.sh --tickets` lists every ticket that has a file.
2. Read each one's status in your tracker (read-only).
3. Done or canceled: move any open follow-up to the ticket it belongs to (create that ticket's file if needed), then delete the file. Report what moved where.
4. Not found: keep the file and ask. A missing answer is not "done".
5. Commit the changes in a worktree and land them with `tools/land.sh`.
