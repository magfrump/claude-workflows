# Research: apply decision 015's amendment and close log row 66

Brief: `docs/working/briefs/2026-10-20-decision-015-amendment.md` (at c1a28e20). Branch: `docs/decision-015-amendment`. Workflow: research-plan-implement, no plan gate; pr-prep's review-fix loop after.

## What the change touches

- `docs/decisions/015-cc-process-isolation-docker-devcontainer.md`: three edits drafted in `docs/working/dd-015-step4-isolation-mechanism.md` §6 (Revisit triggers sentence, the decision-rule table's Revisit cell, a dated note in `## Consequences`). Q-170 [A] approved them. Q-170's V1 answer ("installed a new devcontainer config that was unable to launch cc-isolated ... egress problems blocking claude, and one was the startup check failing") goes in the note.
- `docs/decisions/log.md` row 66: dated amendment closing the trigger on Q-179 [1]. Tally from `docs/roadmap.md` Done and the Q-179 entry: 45 multi-file merges since 2026-10-02, 26 carry the `← carried from RPI` line (19 lack it), 41 committed a rubric, 4 have neither (188e0a7d 10-02, 52053432 10-05, b8807e76 10-06, 0fbf9742 10-06; hashes checked with `git log -1`).
- `docs/decisions/log.md` row 53: dated amendment settling "Not verified on a host". Q-176: spellings 2 (`x.q092-ca""nary`), 3 (`x.q092-c\anary`), 7 (`cat "secret"`), 9 (`git "push"`) ran; the `&&` compound (5) and all controls were denied; no version lines or `seen.log` came back. Q-177 [3]: 43656fe5 refuses a word whose quoting or escaping splits its text, 05245c92 refuses backslash-newline and brace expansion; merged at dfc78e9a. A whole quoted word (7, 9) still passes the hook: the commit states it as a residual, since no shipped deny rule is an exact or prefix rule of that shape.
- `docs/decisions/039-pin-resolver-to-phase-a.md`: `## Revisit trigger` → `## Revisit triggers`, because `scripts/dev-cycle.sh` (line ~300) skips a record without `^## Revisit triggers`.
- `docs/working/dd-015-step4-isolation-mechanism.md` §6 heading: "(not applied)" → where applied.

## Invariants and pitfalls

- The digest prints a log row's first `Revisit[^|]*` match: the clause to the end of its cell, cut at 4096 bytes per output line. Row 66's trigger is in cell 4 (Context / Why), so the amendment goes at that cell's end, where the next digest prints it beside the trigger. Row 53's printed clause is 3383 bytes now, so its amendment must stay under ~650 bytes to avoid the cut.
- No `|` in amendment text (it would split the cell).
- No test pins the real text of 015, 039 or `log.md`: `test/scripts/dev-cycle.bats` builds fixtures. Run it and the decision-related suites anyway.
- No other record or row changes; roadmap and questions files are the cycle's.

## Design choices (divergent design, seeded with docs/constraints.md and the brief)

Every substantive choice is already made by the user (Q-170 [A], Q-179 [1], Q-177 [3]) and the text for 015 is drafted. The open choices are placement and dating:

| Choice | Options | Pick (Path A, dominates) |
|---|---|---|
| Where a row amendment sits | (a) end of the Context / Why cell; (b) the Decision cell; (c) a new row | (a): the existing pattern (row 53's amendments), and the only place the digest prints it next to the trigger (S3, S4). (c) would leave row 66's trigger reading as live. |
| 015 note date | (a) 2026-10-15 as drafted; (b) 2026-10-20, the date applied, naming the 2026-10-15 re-run | (b): the note now carries Q-170's 2026-10-16 answer, so a 10-15 date would be false; the body keeps the DD's date. |
| V1 in the note | (a) a sentence in the note; (b) also edit §7's V1 row in the DD doc | (a): the brief allows only §6's heading in the DD doc. |
| Row 53: say 7 and 9 are closed? | (a) say all four are now refused; (b) say 2 and 3 are refused and 7 and 9 stay a stated residual | (b): 43656fe5 says a whole quoted word passes; (a) would be false. |

No hard constraint is touched: docs only, no gate code, no new dispatch, nothing always-loaded.

## Plan

1. Apply the three 015 edits; the note adds V1's answer.
2. Append the row 66 and row 53 amendments.
3. Rename 039's heading.
4. Update §6's heading in the DD doc.
5. Check: `scripts/dev-cycle.sh` digest section 2 lists 039 and prints both amendments uncut; `bats test/scripts/dev-cycle.bats`.
6. Review-fix loop (code-fact-check of the new text against the sources above), then set the brief's Status to done.
