# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-roadmap-staleness (branch `fix/dev-cycle-roadmap-staleness`)
**Scope:** `git diff b7ebe774..22f9cd8f` (the fix commit): `scripts/dev-cycle.sh` section 5, `test/scripts/dev-cycle.bats` (new test at :1699), `docs/working/research-2026-11-18-roadmap-staleness.md` (:11, :35), commit 22f9cd8f's message. Earlier branch commits (e50efe75, b7ebe774) were read as context only.
**Commit:** 22f9cd8f
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-11-18
**Total claims checked:** 13
**Summary:** 8 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern, and the one Incorrect verdict is a too-broad match, not a fabrication, so nothing is added to the log.

Execution provenance (all from cwd `/workspace/.claude/wt-roadmap-staleness`, or a throwaway repo the probe creates under the session scratchpad; every process finished before this report):

- E1: `timeout 900 bats test/scripts/dev-cycle.bats`, started 2026-11-19T06:19:19Z, exit 0, 93/93 `ok` (test 93 is the new one). Output: `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/bats-cfc2.log`
- E2: `timeout 600 bash /tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/cfc2-probe.sh` (it runs the worktree's `scripts/dev-cycle.sh` against crafted `docs/working/questions.md` and `docs/roadmap.md` in fresh git repos; cases P1-P4), 2026-11-19T06:19:26Z, exit 0. Output: `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/cfc2-probe.log`
- E3: `timeout 120 bash /tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/cfc2-arch.sh` (it runs `questions.sh archive` on a live file holding a CR-ended ANSWERED entry, an `ANSWERED (2026-11-17)` entry and a plain ANSWERED entry), 2026-11-19T06:21:03Z, exit 0. Output: `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/cfc2-arch.log`

---

## Claim 1: "`open_q`: one line per live-file entry of any status, plus each watch not marked ANSWERED, `ID  ROUTE  slug` [observed: `scripts/questions.sh` `cmd_open`]."

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `cmd_open` emits for the live file and watching.md; does not establish anything about the second, live-file-only `qopen` call (`open_l`), which section 5 does not read.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/questions.sh:580
    { parse_entries "$LIVE"; parse_entries "$WATCHING" | awk -F'\t' '{ s = $4; sub(/\r$/, "", s) } s != "ANSWERED"'; } \
```

The live file is not filtered; only watching.md drops ANSWERED. E2 case P1 shows `questions.sh open` listing Q-012 (CR-ended ANSWERED) and Q-013 (`ANSWERED (2026-11-17)`) next to the open ones, and `open_q` comes from that output (`scripts/dev-cycle.sh:417`, `if open_q="$(qopen "$ROOT/$QW" 2>"$qs_err")" && ...`).

**Evidence:** `scripts/questions.sh:575-588`, `scripts/dev-cycle.sh:413-418`, E2 log (P1, "questions.sh open:")

---

## Claim 2: "So an entry marked ANSWERED but not archived yet is still on it; section 5 drops those itself (review 2026-11-18, claim 11b)."

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a well-formed ANSWERED entry (Status on its Needs line) being dropped; does not establish that section 5 drops only those. It also drops open entries in two cases (Claim 5b).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/dev-cycle.sh:509
          [[ "$answered" != *" $id "* ]] || continue
```

E1 test 93 (Q-011 ANSWERED → "Now 1 · Answered, not archived: no open entry or watch names it") passes. In E2 P2, Q-021 ANSWERED → "Now 2 · F: no open entry or watch names it".

**Evidence:** `scripts/dev-cycle.sh:479-481`, `scripts/dev-cycle.sh:507-512`, E1 log, E2 log (P2)

---

## Claim 3: "When section 3 could not read the questions files, `open_q` may still hold a partial list (the first `qopen` succeeded, the second failed), so section 5 gates on `open_ok`, set only when both succeed, and says the list was not checked ..."

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:35`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the gate and the both-calls condition; does not establish what `open_q` holds when the first call fails mid-output (not run).
**Legibility-target:** for-author

The gate and condition are right:

```bash
# scripts/dev-cycle.sh:417-418
  if open_q="$(qopen "$ROOT/$QW" 2>"$qs_err")" && open_l="$(qopen "$qs_err.none" 2>>"$qs_err")"; then
    open_ok=1   # section 5 reads open_q too
```

and `:476-477` prints "Now and Next items were NOT checked ..." when `open_ok != 1`. The parenthetical is imprecise, though. In the case it names (first call succeeded, second failed), `open_q` holds the **full** first list, not a partial one. A partial list happens only if the first call itself fails mid-output. The previous report's precise version, "`open_q` may be empty, partial or full; only `open_ok` says whether it was read", is the accurate statement.

**Evidence:** `scripts/dev-cycle.sh:385`, `scripts/dev-cycle.sh:417-418`, `scripts/dev-cycle.sh:476-477`, `docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness.md:162-182`

---

## Claim 4a: "`questions.sh open` lists every live-file entry whatever its status, so an entry marked ANSWERED but not archived yet ... is left out here too."

**Location:** `scripts/dev-cycle.sh:466-469`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first half (what `open` lists) and that a well-formed ANSWERED entry is left out; does not establish exactly which entries are left out (Claims 5b, 5c).
**Legibility-target:** for-orchestrator-synthesis

Same evidence as Claims 1 and 2 (`scripts/questions.sh:580`; `scripts/dev-cycle.sh:509`; E1 test 93).

**Evidence:** `scripts/questions.sh:580`, `scripts/dev-cycle.sh:481`, `scripts/dev-cycle.sh:509`, E1 log

---

## Claim 4b: "(step 1 archives after this digest runs)"

**Location:** `scripts/dev-cycle.sh:468-469`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skill's step order and `cmd_archive`'s selection rule; does not establish whether step 1 runs at all in a given iteration (it skips `archive` when section 8 lists a questions path, SKILL.md:401-406).
**Legibility-target:** for-author

The order holds. Step 0 item 4 is "**The digest**: `dev-cycle.sh` through d6 from WT" (`skills/dev-cycle/SKILL.md:324`), and step 1 runs "`questions.sh archive` (it also reindexes) through d6 from WT, so answered entries leave the live file" (`skills/dev-cycle/SKILL.md:404-405`). But `archive` takes only an exact status:

```bash
# scripts/questions.sh:464-465
    while IFS=$'\t' read -r id _ _ status _ _; do
        [[ "$status" == "ANSWERED" ]] || continue
```

The digest's matcher is a prefix match (Claim 5c). For an entry whose Status is `ANSWERED` followed by a CR or by trailing text, the digest drops the hold, but step 1 never archives the entry. E3: Q-012 (CR) and Q-013 (`ANSWERED (2026-11-17)`) stay in the live file; only Q-015 is archived. Precise version: "step 1 archives an entry whose Status is exactly ANSWERED after this digest runs".

**Evidence:** `skills/dev-cycle/SKILL.md:324`, `skills/dev-cycle/SKILL.md:401-406`, `scripts/questions.sh:460-475`, E3 log

---

## Claim 5a: "IDs marked ANSWERED in the live file (the Status field on the line under each "### Q-NNN" heading), which section 3's list still carries." (the collection)

**Location:** `scripts/dev-cycle.sh:479-481`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers well-formed entries, the Index table, a heading with no Status line followed by another entry, and legacy watches in questions.md; does not establish exclusivity (Claim 5b) or exact-match semantics (Claim 5c).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/dev-cycle.sh:481
    answered=" $(awk '/^### Q-[0-9]+/ { id = $2; next } id != "" && /\*\*Status:\*\*[ \t]*ANSWERED/ { printf "%s ", id; id = "" }' docs/working/questions.md) "
```

- Needs-line ANSWERED is collected: E1 test 93 (Q-011); E2 P2 (Q-021).
- Index table: the index sits above the first `### Q-` heading, so `id` is still empty there, and its rows hold no `**Status:**` (`docs/working/questions.md:24-32`, e.g. `| [Q-084](#q-084--q076-live-checks) | you: terminal | ...`). It cannot contribute.
- A heading with no Status line, followed by another entry: the next heading resets `id`. E2 P2: Q-020 (no Status line) still reads "open Q-020 (no-status-line)", and the following ANSWERED Q-021 is the only one dropped.
- Legacy watches: an ANSWERED legacy watch in questions.md (Q-022) is dropped, and an OPEN one (Q-023) still holds (E2 P2, "Now 4 · H: open Q-023 (trigger)"). Closed watches in watching.md were never in `open_q` (Claim 1).
- `$2` and the bash test `*" $id "*` compare whole IDs, so Q-010 cannot match Q-0100.

**Evidence:** `scripts/dev-cycle.sh:481`, `scripts/dev-cycle.sh:509`, `docs/working/questions.md:24-37`, E1 log, E2 log (P2)

---

## Claim 5b: "(the Status field on the line under each "### Q-NNN" heading)" (that only that field is read)

**Location:** `scripts/dev-cycle.sh:479-480`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which lines the awk at `:481` reads; does not establish that any current entry in this repo triggers it (none does today, see below).
**Legibility-target:** for-author

The awk does not restrict itself to the Needs line. After a `### Q-NNN` heading, `id` stays set until the next `### Q-` heading or the first match, and **any** line matching `/\*\*Status:\*\*[ \t]*ANSWERED/` marks that ID answered. That includes body prose and lines in a later `## ` section, because `## ` headings do not reset `id` (`scripts/dev-cycle.sh:481`, quoted in Claim 5a). E2 P1 shows two **open** entries dropped:

- Q-010 has `**Status:** OPEN` on its Needs line and the body line `When done, set **Status:** ANSWERED in the Needs line.` The output is "Now 1 · A: no open entry or watch names it", even though `questions.sh open` lists Q-010.
- Q-014 is OPEN, the last entry, followed by `## Notes` containing `Q-014 was once **Status:** ANSWERED by mistake.` The output is "Now 4 · D: no open entry or watch names it".

So, to the caller's question: yes, dropping can drop an entry that is really open. The item is then reported as held by nothing, and step 6 is told to move or explain it. `parse_entries` (`scripts/questions.sh:221-232`) reads Status only from a line starting `**Needs:**`, so the two scripts disagree. There is no live instance today: the only body mention of a bold Status in the questions files is ``a `**Status:**` without you`` (`docs/working/questions-archive.md:5625`), which is not followed by ANSWERED. The precise behavior would need the match anchored to the `**Needs:**` line (as `parse_entries` does), or the comment would have to say "any line under the heading".

**Evidence:** `scripts/dev-cycle.sh:479-481`, `scripts/questions.sh:200-232`, `docs/working/questions-archive.md:5625`, E2 log (P1)

---

## Claim 5c: "IDs marked ANSWERED" (match semantics)

**Location:** `scripts/dev-cycle.sh:479-481`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers CR-ended and trailing-text statuses; does not establish how `questions.sh check` reports them (not run).
**Legibility-target:** for-author

The regex `ANSWERED` is unanchored at the end, so `**Status:** ANSWERED\r` and `**Status:** ANSWERED (2026-11-17)` both count as answered. E2 P1 shows Q-012 and Q-013 dropped ("Now 2 · B", "Now 3 · C": no open entry). `questions.sh` treats both as not answered. `cmd_open`'s header says "Only an explicit ANSWERED is left out, so a malformed status (a typo, a CR, no Needs line) still lists" (`scripts/questions.sh:571-573`), and `archive` leaves them in the live file (E3). These entries are malformed rather than open, so the practical effect is small, but they never leave the live file and the digest never shows them as holds. Precise version: "IDs whose Status starts with ANSWERED".

**Evidence:** `scripts/dev-cycle.sh:481`, `scripts/questions.sh:571-580`, `scripts/questions.sh:464-465`, E2 log (P1), E3 log

---

## Claim 6: Section 5 reads `docs/working/questions.md` only when `open_ok=1`, i.e. when section 3 found it a plain regular file (caller's question).

**Location:** `scripts/dev-cycle.sh:476-481`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch structure from `:385` to `:418`; does not establish anything about the file changing between section 3 and section 5 in the same run (a time-of-check window, not tested).
**Legibility-target:** for-orchestrator-synthesis

`open_ok=0` is set at `:385`. It becomes 1 only inside the final `else` of the chain

```bash
# scripts/dev-cycle.sh:399-401
if skipped docs/working/questions.md; then
  echo "$nc $(skipnote docs/working/questions.md)"
elif ! inrepo docs/working/questions.md; then
```

and `inrepo` is `[[ -z "$(blocker "$1" file)" && -f "$1" ]]` (`scripts/lib/dev-cycle-read.sh:187`), where `blocker` refuses any non-plain path part or a file whose `realpath` differs from `$ROOT_REAL/<path>` (`:162-180`, `rawfile` at `:159`). So it is a regular file reached without a symlink. The awk reads it by relative path, and `need_root` (`:154-158`) guarantees the cwd is the repository root. `questions.sh open` has also just read it successfully, so it is readable.

**Evidence:** `scripts/dev-cycle.sh:385`, `scripts/dev-cycle.sh:399-418`, `scripts/dev-cycle.sh:476-481`, `scripts/lib/dev-cycle-read.sh:154-191`

---

## Claim 7: "An item is its column-0 line and the indented lines under it; a column-0 line that is no item (prose, a ### heading) ends it." (with tabs already converted)

**Location:** `scripts/dev-cycle.sh:469-471` (code `:492`, `:497-499`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers prose, `###` headings, indented and tab-indented continuations, and indented fences; does not establish fence awareness. A column-0 fence ends the item, and a column-0 `- ` or `1. ` line inside such a fence starts a new item. Section 7's count does the same, so this is not new here. It also does not establish that a blank line ends an item (it does not).
**Legibility-target:** for-orchestrator-synthesis

```awk
# scripts/dev-cycle.sh:492, 497-499
      { sub(/\r$/, ""); gsub(/\t/, " "); t = tolower($0) }
      sec != "" && /^([-*] |[0-9]+\. )/ { flush(); cur = sec; num = ++n[sec]; text = $0; next }
      cur != "" && /^[ ]/ && NF { text = text " " $0; next }
      NF { flush() }
```

The tab rule at `:492` has no pattern and comes first, so every later rule sees tabs as spaces. E2 P3:

- Indented line after column-0 prose: dropped. The prose flushed I1, so `cur == ""`, and the indented "names Q-030" joins nothing ("Now 1 · I1: no open entry").
- Indented fence inside an item: continues it ("Now 2 · I2: open Q-031").
- Column-0 fence: ends I3 ("Now 3 · I3: no open entry"). Its body bullet `- fenced bullet Q-033` becomes "Now 4", and section 7 also counts 5 Now items.
- `### Sub`: `/^## /` does not match `### `, so the line falls to `NF { flush() }`. Items after it stay in Now ("Now 5 · I4").
- A tab-indented sub-step continues I4 ("open Q-034").

E1 test 93 (column-0 prose naming Q-010 does not hold "No hold of its own") passes.

**Evidence:** `scripts/dev-cycle.sh:482-500`, E1 log, E2 log (P3)

---

## Claim 8: "Only the first Now and the first Next heading count, as in section 7."

**Location:** `scripts/dev-cycle.sh:471-472` (code `:493-496`)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers heading selection (which section's lines are read); does not establish that the two sections recognize the same item lines. Section 5 converts tabs before matching `^([-*] |...)`, but section 7 does not, so `-<TAB>**x**` is an item in section 5 and not in section 7's count (E2 P4: "Now 1 · Tabbed" vs "Roadmap Now: 0 item(s)").
**Legibility-target:** for-orchestrator-synthesis

```awk
# scripts/dev-cycle.sh:494-495
        if (!seen_now && (t == "## now" || index(t, "## now ") == 1 || index(t, "## now(") == 1)) { sec = "Now"; seen_now = 1 }
        else if (!seen_next && (t == "## next" || index(t, "## next ") == 1 || index(t, "## next(") == 1)) { sec = "Next"; seen_next = 1 }
```

Section 7's counter starts at the first matching heading and `exit`s at the next `## ` (`scripts/dev-cycle.sh:565`, `... { on = 1; next } on && /^## / { exit } on && /^([-*] |[0-9]+\. )/ { c++ } ...`). The brainstorm `now_of` stops for good at the first `## ` after Now via `d = 1` (`:612`). The section-5 Next quote likewise `exit`s (`:463`). The heading predicates (exact, `"## now "` prefix, `"## now("` prefix, lowercased, CR stripped) are identical. E1 test 93 asserts that the second `## Now`'s item is absent and there is no "Now 4"; it passes.

**Evidence:** `scripts/dev-cycle.sh:463`, `scripts/dev-cycle.sh:493-496`, `scripts/dev-cycle.sh:565`, `scripts/dev-cycle.sh:612`, E1 log, E2 log (P4)

---

## Claim 9: Test name "section 5: an entry marked ANSWERED but not archived yet holds nothing; column-0 prose ends an item; only the first Now and Next count (review 2026-11-18, claims 11b, 9a, 9b)" and its fixture lines.

**Location:** `test/scripts/dev-cycle.bats:1699-1735`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the references to the previous report and what the test asserts; does not establish coverage of the Claim 5b/5c cases, which the test does not exercise.
**Legibility-target:** for-orchestrator-synthesis

The previous report has `## Claim 9a: The new awk's Now/Next heading rule mirrors section 7's.` (:189), `## Claim 9b: "Column-0 item"; ...` (:203) and `## Claim 11b: "only an open one counts" — for an answered entry still in questions.md.` (:269), which match the three behaviors named. The fixture line "Column-0 prose after it naming Q-010 belongs to no item." is checked by `"- Now 2 · No hold of its own: no open entry or watch names it"`. The `### A subheading naming Q-010` line is checked the same way. The second Now is checked by `[[ "$section" != *"Now 4"* && "$section" != *"A second Now section"* ]]` (:1734). E1: `ok 93`.

**Evidence:** `test/scripts/dev-cycle.bats:1699-1735`, `docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness.md:189,203,269`, E1 log

---

## Claim 10: Commit 22f9cd8f: "A3 (claims 2, 8): the research doc's two statements about open_q corrected."

**Location:** commit 22f9cd8f message (`docs/working/research-2026-11-18-roadmap-staleness.md:11,35`)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the A3 line of the message; its R1, A1 and A2 lines are covered by Claims 2, 5a, 7 and 8 (with the 5b/5c residue against R1's "drops IDs whose live-file Status is ANSWERED").
**Legibility-target:** for-author

Line 11 is now accurate (Claim 1). Line 35 still says "partial list" for the case where `open_q` holds the full first list (Claim 3). The R1 line, "Section 5 now drops IDs whose live-file Status is ANSWERED", is true but understated: section 5 also drops IDs whose body or trailing text matches, and IDs whose Status merely starts with ANSWERED (Claims 5b, 5c).

**Evidence:** `git show 22f9cd8f`, `docs/working/research-2026-11-18-roadmap-staleness.md:11`, `docs/working/research-2026-11-18-roadmap-staleness.md:35`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`scripts/dev-cycle.sh:479-481`): the `answered` awk matches `**Status:** ANSWERED` on any line under a `### Q-NNN` heading (body prose, or a later `## ` section after the last entry), not only the Needs line. An OPEN entry is then dropped and its roadmap item reported as held by nothing (E2 P1: Q-010, Q-014). Anchor the match to the `**Needs:**` line as `parse_entries` does, or reword the comment.

### Mostly Accurate
- **Claim 3** (`docs/working/research-2026-11-18-roadmap-staleness.md:35`): "partial list (the first `qopen` succeeded, the second failed)". In that case `open_q` holds the full first list. Say "may be empty, partial or full".
- **Claim 4b** (`scripts/dev-cycle.sh:468-469`): "step 1 archives after this digest runs" holds only for an exact `ANSWERED` status. A CR-ended or suffixed ANSWERED is dropped by the digest but never archived (E3).
- **Claim 5c** (`scripts/dev-cycle.sh:481`): "marked ANSWERED" is a prefix match, which is broader than `questions.sh`'s exact match (`cmd_open`, `archive`).
- **Claim 10** (commit 22f9cd8f): A3's "corrected" leaves the line-35 imprecision (Claim 3), and R1's description understates what is dropped (Claims 5b, 5c).

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to /workspace/.claude/wt-roadmap-staleness/docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness-pass2.md, structured per the code-fact-check skill, header `**Commit:** 22f9cd8f` and `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: all five focus claims. (1) The `answered` awk: Index rows, a heading with no Status line and legacy watches are handled correctly. Body text and text after the last entry do drop really-open entries (Incorrect, 5b). CR and suffixed statuses are dropped but never archived (5c, 4b). The file is guaranteed plain when `open_ok=1` (6). (2) The step-order comment is right for exact statuses (4b). (3) The item rules hold: an indented line after column-0 prose is dropped, an indented fence continues the item, a column-0 fence ends it (and its bullets become items, as in section 7), and a `###` heading ends the item but not the section (7). (4) Heading selection matches section 7 and `now_of`. The only divergence is tab-after-marker item recognition (8, scope residue). (5) Research line 11 is Verified, line 35 is Mostly accurate, and the test's references and assertions are Verified (1, 3, 9). bats suite: 93/93 pass.
- Out of scope: code quality and the fix design (sibling critics); commits before b7ebe774..22f9cd8f; whether a `-<TAB>` bullet or column-0 fences occur in real roadmaps.
- Escalate: none beyond the for-author items. Claim 5b is a behavioral mismatch for the rubric. It errs toward reporting an item as unheld (step 6 then has to explain it), and no current questions file triggers it.
