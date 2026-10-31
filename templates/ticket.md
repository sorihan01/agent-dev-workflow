# <Verb-first title, 70 characters max>

## Why
<The problem and its consequence for a real person, in two to four sentences. Name the outcome, not a request to one person.>

## Scope
* <what to change>
* Out: <what this ticket does not cover>

## Done when
- [ ] <observable check: a status code, a rejected request, a page that shows or doesn't show something>
- [ ] <the automated test that stops it coming back, with its cases, including one edge case below>
- [ ] <the main user flow still works>

## User impact
* **Flow:** <page → action → result, for each person this touches>
* **Edge cases:** <second submit, expired session, empty or huge data, slow network, small screen…>
* Not affected: <what stays as it is>

## Evidence
* `<path/file:line>` (<what it shows>), or "unknown"

---

> **Human check before building**
> - [ ] Still relevant? <what to re-check>
> - [ ] Duplicates? <what was searched, and when>
> - [ ] Anything to remove at the same time?
> - [ ] Do the done-when checks above really mean done?
