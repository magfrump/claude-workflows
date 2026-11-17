# Research: a merge-time check of the branch's code-review rubric

Brief: `docs/working/briefs/2026-11-14-merge-rubric-gate.md` (review policy, gate code). Build loop, dispatch 1 from fce8af4a; dispatch 2 from fc2eeb03, after the owner's Q-294 [1] (narrow, one more review pass); dispatch 3 from 27c32c32, after the owner's Q-295 [1] (pass 5: a carried row goes only to a row of its own tier, fix the wording, add the test cases).

## Answer

`scripts/build-loop.sh --check` and `--merge` now end their output for a brief with advisory `rubric BRIEF: ...` lines from a new lib, `scripts/lib/rubric-check.sh`. The lines come from the branch's rubrics, read by table column. They change no verdict and no exit status. Each red or amber row that is neither fixed nor closed by a re-checkable reference gets one `open PATH ID TIER: STATUS` line. A table the parser cannot read gets an `unread` line, a fix after the rubric's last change gets `stale`, and a branch with no rubric gets `none`, which says whether it changes code. Reaching the owner: a review brief's merge entry already quotes `--check`'s lines as printed, so these lines go along with them. A self-merge's record and final message quote them (`skills/dev-cycle/SKILL.md` step 7). The check ships advisory because, measured on this repo's 106 rubrics, most rows it flags are closed somewhere else (see "Measurement"). The falsifier that would take it out of advisory is under "Decisions".

## Context

- **Prior art reused.** The failure-pattern step (`fp_gaps` in `build-loop.sh`, Q-226 [5]) reads committed objects with `gate_git`/`fp_blob` and prints `gap` lines. The rubric check uses the same reads and the same placement inside `check_line`, but prints after the path lines and never refuses. An answered Q-ID is read by the lib's `check_answer`, the same read `--approved` uses (main's commit only, never a working tree). "The loop's rubric" is defined the way `skills/code-review/SKILL.md` Step 1 defines it (the newest date per canonical `code-review-rubric-DATE-SLUG.md` name), so S3 holds: one definition of which file a loop's rubric is.
- **Rubric formats in `docs/reviews/`** (106 files whose name holds `code-review-rubric`), four generations:
  1. Multi-pass files with a fresh set of tier tables per pass, row IDs reused per pass (for example `code-review-rubric-2026-09-29-feat-dev-cycle-digest.md`).
  2. The template in `skills/code-review/references/rubric.md`: `## 🔴 Must Fix` / `## 🟡 Must Address` tables with a `Status` column (and `Author note` for amber), updated in place.
  3. That template plus iteration-status tables above it (`| # | Status | How checked |`, for example `...-feat-build-loop-u1c.md`).
  4. Build-loop rubrics with one `## Findings` table and a `Tier` column (`red`/`amber`/`green`; for example `...-2026-11-10-dev-cycle-skill-held-fixes.md`). This is what recent build loops write, so the parser had to read it. A parser built on the template alone would have reported every recent build-loop rubric as having no tier table.
- **Status vocabulary** is free text after an optional mark: `🔴 Unresolved`, `✅ Fixed in abc`, `Fixed (pending commit)`, `Partly fixed`, `⏸️ Deferred`, `Stands`, `Noted`, `Carried`, `Open (cap)`, `superseded by C1`, `still open as A22`, `Won't-Fix (row: F19)`, `Accepted-immutable`.
- `build-loop.sh` is 2505 lines. S8 bars growth only of `cc-isolated.sh` and `install.sh`, but the parser still went into its own lib file: about 180 lines, with a dozen lines of glue plus the header docs in `build-loop.sh`. `scripts/` ships whole in the image payload (`devcontainer-config/install.sh`, `CLAUDE_HOME_SRC`), so the lib reaches the image with no installer change. `d6.sh` checks for it next to the other image files.
- Perl, not python3: `build-loop.sh` already needs perl, and python3 would be a new runtime dependency for the gate, which is a stop condition. Perl runs in byte mode, like the lib's `scrub`, and emoji are matched as byte sequences.

### Design notes (choices with fewer than 3 viable options)

- **Placement of the lines:** last, after the path lines (the other choice was before them, like `gap` lines). Last keeps every existing line index, which the dev-cycle skill and about 16 existing bats cases read. The suites' `chk`/`mrg` helpers move the lines into `$rubric` (`unrubric` in `test/lib/build-loop-fixtures.bash`).
- **The lib missing:** `build-loop.sh` exits 1 naming it, like `lib/dev-cycle-read.sh` (H2). Printing an `unread` line and going on was the other option, but a partial image is the environment's failure, and the reader lib already has this precedent.
- **Duplicate row IDs in one file:** the last row wins. Multi-pass files append passes, and the in-place template keeps one row per ID.
- **A row naming its successor** (`superseded by C1`, `→ X1`): it takes the successor row's class and Q-IDs, up to 5 hops. A red follows only red rows, so it never borrows an amber's closure. A name that is not a row in the same file changes nothing. The first build also followed `as`, `see` and `into`, which matched prose ("same as A2"); review 1 R1 removed them.
- **Code vs docs-only:** a branch with no rubric and any changed path outside `docs/` gets a `none` line that counts those paths. A docs-only branch gets a `none ... no rubric is needed` note.
- **Stale:** the newest commit on the branch (not on main) that touches the rubric, then the `fix(` / `fix:` / `fix!` commits after it on the branch, matched the way `fp_gaps` matches them. The brief's other reading compares the rubric's `Commit:` stamp with later fixes. The stamp is a short SHA that the loop writes by hand, while the commit that last changed the file comes from git, so the check uses that.

## Decisions (divergent design, seeded with docs/constraints.md and the brief)

### D1. Refuse, or only report, at first

Options:

| Option | What it means | Fit |
|---|---|---|
| **[1] advisory everywhere** | lines only, no verdict change | H4 (free-text status read by keyword), S10 (no false stops), the brief's default |
| [2] refuse an open red only | `--check` refuses on an open red row | H2, but a false red stops every merge, a self-merge included |
| [3] refuse any open row | red or amber | H2, but most corpus flags are false (Measurement) |
| [4] advisory on review, fall-through on self-merge | an open red sends a self-merge to review | the brief's criterion 4 target state |

Measurement: across all 106 rubrics the parser classes 1164 red and amber rows, 41 red and 204 amber of them as open (and 1 red that names a Q-ID, open unless that Q-ID is answered), and finds 29 unreadable tables. The audit (`docs/working/research-2026-11-13-review-gap-audit.md`) adjudicated the same corpus and found 15 unfixed reds (14 with an owner decision recorded only in a landing's message) and 21 open ambers. So most open lines on old rubrics are rows closed outside the rubric, in a merge message or a later file. On the 8 rubrics from November the parser prints 3 lines in all: d6-block A2 and confine-tests A5, both closed by prose with no reference, and one row of confine-tests whose cell count is off by a pipe inside a code span. Refusing on that would stop real merges for formatting. **Pick [1] (Path A).** [4] is the stage after this one, and the falsifier says when.

**Falsifier (to leave advisory):** over the next 10 build-loop landings that carry a rubric, every `open` and `unread` line the cycle quotes is a real gap. "Real" means the owner's answer on the merge entry, or the record, confirms the row was not closed. If any such line is a row the rubric did close, the check stays advisory and that status word or format goes into the parser and its tests first. On passing, the next brief switches self-merge to [4]: an `open` red line makes `--merge` refuse, without `--approved`, and the cycle files it as a review merge entry. That is a single condition in `check_line`, and an `--approved` merge still lands, because the owner's answer is the waiver.

### D2. Can a waiver quoted in the marker body or the merge message clear a row?

| Option | What it means | Fit |
|---|---|---|
| **[1] no: only the rubric row closes it** | a red cites an answered Q-ID; an amber a qualifying note | H4: re-checkable from the artifact; S3: one record |
| [2] yes, any waiver text naming the row ID | marker body or message | an agent-written waiver of a red, the U2a2 D1 failure (audit fix 6) |
| [3] yes, if the quoted waiver cites an answered Q-ID | marker body | re-checkable, but a second place to look for the same fact (S3) |

Nothing else writes the merge message: `--merge` builds it itself (`gate_msg`). On a review brief the owner's `[1]` on a merge entry that quotes the `rubric` lines is already the waiver. **Pick [1] (Path A).** Falsifier: a landing where the row could not be edited (an immutable artifact) and no Q-ID or override row could be filed. In that case the cycle files the case and [3] gets reconsidered.

**Correction to criterion 2, from the dev-cycle orchestrator (2026-11-14, mid-build).** As written, the criterion let a red closed by waiver or deferral count as closed when it cited an answered Q-ID, an override-log row or a named revisit trigger. An agent can write an override-log row or a trigger itself, so that would pass the audit's U2a2 D1 case (a red an agent waived on its own). The orchestrator's reading, applied here:

- A **red** closed by anything but a fix counts as closed only when it cites a Q-NNN the owner has answered on main (read by `check_answer`). An override-log row, a trigger or `Accepted-immutable` does not close it.
- An **amber** may still be closed by a Q-ID (open or answered: a filed entry is a tracked follow-up), an override-log row, a named trigger, a TODO or a roadmap item: the qualifying author note of `skills/code-review/references/rubric.md`.

The parser reads the "Status words" table of `skills/code-review/references/rubric.md` (landed on main through Q-293 [1], the review-rules merge). The first word is read: `Fixed`, or `Resolved` from older rubrics, is a fix, and any other first word is open unless a reference closes it. `Defer` and `Deferred` are the same word.

**Narrowed by Q-294 [1] (dispatch 2).** Dispatch 1 let `Split` and `Carried` close a red without a Q-ID, as the table does, through a keyword classifier for the named target. Three review passes kept finding wordings that classifier closed wrongly (rubric rows R2, A1, A23). The owner picked option [1]: Split and Carried no longer close a red. A red now closes only by a fix or by a Q-ID answered on main, whatever its first word. This is the one place the check departs from the table: a red the table counts as split or carried prints as `open` until a Q-ID it cites is answered. It over-reports, which is the safe direction for an advisory line, and it cost nothing measured: across the 106 rubrics in `docs/reviews/` no red was closed by Split or Carried, and the row classes are the same before and after the change. An amber is read as before: any first word, closed by a qualifying note found by keyword (a Q-ID, an override-log row, a TODO, a roadmap item, a revisit trigger). A Split amber naming a Q-ID now closes at once, like an Open amber with one. The lib's header comment is the single place that says how the words are read (rubric A25), and a bats case runs every word of the table through the parser on each tier the table lists it for.

### D3. Which rubric(s)

| Option | What it means | Fit |
|---|---|---|
| [1] every rubric the branch adds or changes | all of them | recall; a superseded day-file's stale rows flag falsely |
| **[2] newest DATE per canonical SLUG; other names each read** | the loop's rubric as code-review Step 1 finds it | S3 (one definition); a superseded line names the rest |
| [3] only `code-review-rubric-*-BRANCHSLUG.md` | the branch's own slug | misses rubrics named for the stem or a unit |
| [4] newest file overall | one file | misses parallel loops on one branch |

**Pick [2] (Path A):** it reuses the existing rule. Each older file still gets a `superseded OLD by NEW (not read)` line, so the owner can see it is there.

## Pre-mortem (gate code; bypass families)

Assume this landed and a gap still reached main. Ways it happens:

1. **Wrong file read (selection bypass).** The rubric is named without `code-review-rubric`, sits outside `docs/reviews/`, or was committed on main before the branch, so the branch never changes it. Result: a `none` line, which says so. A docs-only branch with a rubric somewhere else passes with the docs note. Residual, noted.
2. **Status words read as fixed (classification bypass).** A row reads `Fixed` with nothing fixed (an agent's say-so), or `Resolved` in the first clause of a status that is really open further on. The check keys on the row as written (H4). It cannot verify the claim behind it, and the `stale` line covers only fixes after the rubric's last change. Residual: an honest slip in a status word. A hostile loop is out of scope (S1).
3. **Row hidden from the parser (format bypass).** A tier table under a heading with neither mark nor tier words, a table with no `Tier` or `Status` column, or rows in prose. The heading case reads as `none` or `unread` (a file with no tier table at all is named, never passed). Lines inside a code fence are not read, and a fence left open is named. A Tier cell that reads as no tier (not green or Consider) is named. A Must Fix heading spelled differently, `## Red findings` or `## Blocking`, is missed if the file also has another tier table. Residual; revisit trigger: a rubric generator that writes tier headings without a mark or the Must words.
4. **Reference that closes nothing (reference bypass).** An amber cites a made-up `Q-999` or a nonexistent "override row 12". For a red, only a Q-ID answered on main closes it (checked); since dispatch 2 no split or carry target closes a red. Residual: an amber's Q-ID, override-log row or trigger is taken on presence, and a Q-ID cited only for context closes a red once answered (rubric A3).
5. **Advisory ignored (attention bypass).** The cycle quotes the lines, but nobody reads them, or a self-merge lands past an open red. That is the cost of advisory, and the falsifier exists to end it. The dev-cycle skill names each non-clean line in the final message.
6. **Lines not reached (path bypass).** A merge outside `build-loop.sh` (a hand merge, a fast-forward) never runs the check. Out of scope by the brief; see Follow-ups.
7. **The check itself fails quietly (H2).** A failed git read prints an `unread` line naming it, a missing lib stops `build-loop.sh` with exit 1, and `d6.sh` refuses a partial image. Tests cover the missing lib, a non-regular file, a malformed row, a table with no Status column and a file with no tier table.

## Plan (as built)

1. `scripts/lib/rubric-check.sh`: `rubric_parse FILE` (perl, bytes) and `rubric_lines BRIEF BRANCH TIP PATHS STATUSES` (PATHS and STATUSES are namerefs to check_line's arrays; glue on `gate_git`, `fp_blob`, `check_answer`).
2. `scripts/build-loop.sh`: source the lib beside `lib/dev-cycle-read.sh`, call `rubric_lines` at both ends of `check_line`, and add the header docs for `--check`'s `rubric` line and `--merge`'s note.
3. `scripts/d6.sh`: check the lib among the image files.
4. `skills/dev-cycle/SKILL.md` step 7: what the lines are, and how they reach the owner on each policy.
5. Tests: `test/scripts/build-loop-check.bats` (status words, Tier-column and multi-pass, none/docs/stale/clean/superseded, malformed, missing lib, real rubrics of three generations), `test/scripts/build-loop-merge.bats` (self-merge lands past an open red), `test/scripts/build-loop-orchestrator.bats` (image copies carry the lib; d6 refuses it missing), and the `unrubric` helper in `test/lib/build-loop-fixtures.bash`.

## Follow-ups (not built)

- A hook or a post-merge check for hand merges and fast-forwards of main, which bypass `build-loop.sh` (brief "Out of scope"; the audit's landing 3).
- Leaving advisory, per D1's falsifier.
- Looking up the override-log row an amber cites (pre-mortem 4).
- Letting a Split or Carried red close as the Status words table says, through a real lookup of its target (the brief, branch or roadmap item exists; the carried file and row exist and are newer), not by keyword. Until then such a red prints as `open` (Q-294 [1]).
- A fixed close-out line in the rubric template (the audit's fix 1 note) would make the parse exact. Template changes belong to brief `2026-11-14-review-rules-close-gaps`.
- A check on hand merges and fast-forwards (above) is the only way past `build-loop.sh`; nothing in this design reaches them.

## Gotchas

Failure-pattern grep: FP-064, FP-033, FP-156

- FP-064 (an overwritten rubric destroyed prior findings, so rubrics became date-stamped files): a branch can carry several dated rubrics for one loop. The check reads the newest per slug and names the older ones `superseded`, and does not silently drop them.
- FP-033 (a substring denylist missed its subject; the fix was a structural parse): this is why the parser reads cells by header column and status words as whole words. "Unresolved" is never "resolved".
- Failure-pattern skip: the fix(...) commits on this branch (dba77376 included) correct review findings in code that never reached main; the reusable shape (keyword and substring closure misread as structure) is already FP-033.
- FP-156 (a bare substring assertion stayed green across the move it covered): the new tests compare `$rubric` exactly, not by `grep -q`. The one substring check (R5 closing once Q-003 is answered) also asserts that another red stays open.

## Review

- **Pass 1** (at 66304b3d, the full `code-review` pipeline: fact-check k=3 and five critics, run by a separate read-only agent; rubric `docs/reviews/code-review-rubric-2026-11-14-merge-rubric-gate.md`): 1 Must Fix, 14 Must Address, 9 Consider.
  - R1, the successor pass let a red borrow an amber's closure and matched prose: fixed.
  - Classifier findings fixed: A1 (split and carried, completed in pass 2 as R2), A2 (negation in the whole cell), A3 (only explicit answered states close; empty output is open) and A5 (empty fields).
  - A4 (code fences, Tier-cell words, unread rows) is fixed, except unmarked tier headings (pre-mortem 3).
  - A6 (set -e hazards) is fixed.
  - The A7, A10 and A12 docs are reworded.
  - A8 (cut at a UTF-8 boundary) is fixed.
  - A9 is documented: amber closure is keyword presence.
  - A11 is fixed with namerefs, A13 by showpath, and A14 with two cases.
  - C3 (a red superseded by an answered red) closes now, since the successor's Q-IDs carry over. C4 (the skill's list) is fixed.
  - C9 is a record note: bb0030a1's Notes line states the first red rule (fix, answered Q-ID or override-log row). 66304b3d and this doc supersede it, and history is not rewritten.
- **Pass 2** (at 655df91d, a loop pass: fact-check k=1, then the first-red short-circuit, so no critics ran; rubric updated in place): 1 new Must Fix, 6 new Must Address.
  - R2: a Split closed a red on a bare keyword ("no branch yet"), and a Carried did not check its file was newer. Patched in dd6aa89e (a target shape, no "no" or "none", a carried date no earlier); pass 3 found it only partly fixed, and dispatch 2 removed the closure instead.
  - A15: the superseded list split on a space and tripped set -u. Fixed with separate arrays.
  - A16 and A14 (tests) are fixed: a case pins R2, C3 and A15.
  - A17, A19 and A20 (wording) are fixed. For A19 the words not, open and still stay first-clause only, and the docs and test title now say so ("Fixed; follow-up still needed" is a fix).
  - A18 (fence length) is fixed.
  - A3 (an answered Q-ID closes a red whatever the answer) is kept on purpose. The answer's meaning is the owner's judgment, which the gate does not read (H4). The rubric row carries a revisit trigger.
  - C4: the skill now says an `unread` failed-read line is the environment's.
- **Pass 3** is the loop's last under the 3-pass cap (`workflows/review-fix-loop.md`). All critics run, since the short-circuit is spent.
- **Pass 3** (at 70c549f7, full panel): not clean. R2 is only partly fixed: a Split still closes a red on a repo path, on a negation found only in the Author note, or on a later "not started". A1 and A18 are not fully fixed. There are 7 new amber findings (A21-A27). The loop hit the 3-pass cap. **Decision: escalate** (recorded in the rubric's "Cap decision" section). The recommended next step narrows instead of patching: only a fix or an answered Q-ID closes a red, and the Split and Carried closures wait for a follow-up once `docs/review-rules-close-gaps` lands.
- **Pass 4** (dispatch 2, allowed by the owner's Q-294 [1]): the narrowing above. Split and Carried no longer close a red (R2, A1, A23 and C15 go with the classifier they were about). A fence line with an info string (```` ```bash ````) no longer closes a fence (A21). `partial`, `except` and `remains` in the Status cell negate a fix (A22). The Author note is not read for a fix: measured on `docs/reviews/`, doing so turned 4 correct fixes into false opens out of 6 rows it changed ("the overshoot half", "not yet on main"), and the table puts the word in the Status cell. A Carried forward table reads its `Now` column (A24). The `--check` header now names only the line formats (A26). Tests: one case per item above, plus the Status-words contract case (A25, A27). Each new case fails on the dispatch-1 lib.
- **Pass 4 review** (at dba77376, fact-check k=1 plus security, api-consistency and test-strategy; rubric updated in place): not clean. Confirmed fixed: R2, A1, A18, A21, A23, A25, A26, C4, C15. The narrowing left every row class over the 107 rubrics in `docs/reviews/` byte-identical, and each new case fails on the dispatch-1 lib. New: one regression red, R3. A carried-forward red whose Now cell names an amber row is dropped, and the amber's closure stands in for it, because the hand-off looks the ID up across both tiers. Also 4 amber: A28 (more partial wordings such as `Fixed in part` and `Fixed (WIP)` read as fixed), A29 (dev-cycle step 7 still says an `open` row is one the review did not close), A30 (three surviving test mutants that could hide a red) and A31 (wording). The owner's allowance was this one pass, so the loop is at its revised cap. **Decision: escalate** (rubric "Cap decision (after iteration 4 of 4)"). No fix was made after the review.
- **Pass 5** (dispatch 3, allowed by the owner's Q-295 [1]; the fix commit after 27c32c32):
  - R3 (a carried red handed to an amber row) is fixed: a Carried forward row is left only to a row of the same tier. A row naming a row of the other tier only is read on its own, under its own tier, so a red stays `open` unless a Q-ID it cites is answered (it prints as `carried:ID` with its Now cell as STATUS). A row naming no row of the file is still an `unread` line.
  - A28: `in part`, `mostly`, `WIP`, `TBD`, "next PR" (or pass, release, branch, iteration, round), "for ... only" within one clause, and a bare "Fixed: no" now negate a fix. `Fixed: no early return` and `Fixed (next commit: ...)` stay fixes. Measured over the 107 rubrics in `docs/reviews/`: 3 rows change class, all from fixed to open or closed and none the other way: one red, `Fixed for the 13 table shapes only` (its remainder is a separate red, fixed, so this is the one false open), and two ambers worded `Fixed in part`, which are real partial fixes (one now closes on its own Q-ID). No red reading `Fixed` became fixed.
  - A29: dev-cycle step 7 now says an `open` row is one the check could not count as closed (since Q-294 [1], a Split or Carried red the review closed prints `open`).
  - A30: one case pins the same-tier hand-off (both directions), an info-string opener as a fence and the closer's same-character rule. Each of four mutants fails it (the dispatch-2 lib, the cross-tier row dropped, the hand-off to any tier, the same-character check removed, an opener needing no info string).
  - A31: the case-9 comment (R12 takes R13's class and Q-IDs), the lib's fence comment (blanks may follow a closer) and the contract case title (each word on the tiers the table lists) are reworded.
  - C17, in part: the `--check` header says a carried row's STATUS is its Now cell.
