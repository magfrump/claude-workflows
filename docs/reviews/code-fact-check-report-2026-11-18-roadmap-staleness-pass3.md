# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-roadmap-staleness (branch `fix/dev-cycle-roadmap-staleness`)
**Scope:** `git diff 22f9cd8f..969e8227` (commits 57e8950a, 969e8227): `scripts/dev-cycle.sh` section 5 (`answered` awk, :479-486), `test/scripts/dev-cycle.bats` (new test at :1737), `docs/working/research-2026-11-18-roadmap-staleness.md:35`, `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md` (R2, A4, A5 rows), both commit messages. The pass-2 report added in this delta is a review artifact, not checked. Everything before 22f9cd8f was read as context only.
**Commit:** 969e8227
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-11-18
**Total claims checked:** 14
**Summary:** 9 verified, 2 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim matches a logged pattern. The three Incorrect verdicts are one over-broad parity claim ("as parse_entries reads it" / "drops exactly what archive moves"), not fabricated symbols, so nothing is added to the log.

Legibility-target: every claim below is **for-author** (the fix's author acts on it; nothing here needs the owner).

Execution provenance. All runs finished before this report; none is still running. Captured output lives in the session scratch dir `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/cfc-pass3-1962027/` (called `$S` below; this review may write only this report, so logs were not copied to `docs/reviews/execution-logs/`, and a scratch cleanup would remove them; the decisive output is quoted inline).

- **E1** (2026-11-19T06:27:08Z). cwd `$S`. `digest.awk` is the `answered` awk program extracted byte-for-byte from `scripts/dev-cycle.sh:483-486` with a Python regex, not retyped. The fixture `questions.md` has: Q-001 (two Needs lines, OPEN then ANSWERED), Q-002 (ANSWERED then OPEN), Q-003 (CRLF, ANSWERED), Q-004 (`### Q-004  · …`, two spaces), Q-005 (plain ANSWERED), Q-006 (no Needs line, then `## Notes` with a Needs line). Commands: `awk -f digest.awk questions.md`, then `QUESTIONS_LIVE=$S/q3.md QUESTIONS_ARCHIVE=$S/arch3.md QUESTIONS_WATCHING=$S/none.md timeout 30 bash scripts/questions.sh archive` run on a copy with index markers. Archive exit 0. Output in `$S/archive-run.log`. Results: digest answered set `Q-002 Q-004 Q-005 Q-006`; archive moved `Q-001 Q-004 Q-005`, left `Q-002 Q-003 Q-006`.
- **E2** (2026-11-19T06:27:21Z). cwd `$S`. Q-007 has a Needs line with no Opened field (`**Needs:** you: judgment · **Status:** ANSWERED`). Same two commands. Archive exit 0, `archived 0 entries`. Output in `$S/archive-run4.log`. Digest answered set: `Q-007`.
- **E3** (2026-11-19T06:28:14Z). cwd `$S/fx`. The new test's fixture was extracted byte-for-byte from `test/scripts/dev-cycle.bats` and run through the new awk, the old awk (from `git show 22f9cd8f:scripts/dev-cycle.sh:481`) and `questions.sh archive`. Archive exit 0. Output in `$S/archive-fixture.log`. Results: new set `Q-013`; old set `Q-010 Q-012 Q-013`; archive moved `Q-013` only.
- **E4** (2026-11-19T06:28:37Z). cwd `$S`. `questions.sh index` then `questions.sh check` on the Q-001 (two Needs) and Q-007 (no Opened) entries. Exit 1. Output in `$S/check-run.log`. Results: `⚠ Q-001 is ANSWERED but still in questions.md`; `✗ Q-007: invalid Opened date 'ANSWERED'`; `✗ Q-007: invalid status 'no-opened'`.
- **E5** (2026-11-19T06:27:22Z to 06:28:02Z). cwd `/workspace/.claude/wt-roadmap-staleness`. Command: `timeout 900 bats test/scripts/dev-cycle.bats`. Exit 0, 94/94 ok, including `ok 94 section 5 reads an entry's Status only from its Needs line…`. Output in `$S/bats.log`.
- **E6** (2026-11-19T06:28:4xZ). cwd the worktree. The old and new awk were run read-only on the worktree's `docs/working/questions.md`. Both printed an empty set. The file has 3 headings, 3 Needs lines, no CR, and no entry with more than one Needs line.

---

## Claim 1: "the `answered` awk matched `**Status:** ANSWERED` on any line under a heading (body text, a later `## ` section) and any status starting with ANSWERED, so an open entry could read as no hold; its comment said "the Status field"."

**Location:** `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:15` (also commit 57e8950a body, "matched "**Status:** ANSWERED" on any line under a heading and any status starting with ANSWERED")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix awk at 22f9cd8f on the new test's fixture (a body line, a `## Notes` line and a dated ANSWERED); does not establish behavior on any other input.

The pre-fix program, quoted from `git show 22f9cd8f:scripts/dev-cycle.sh` line 481:

```
answered=" $(awk '/^### Q-[0-9]+/ { id = $2; next } id != "" && /\*\*Status:\*\*[ \t]*ANSWERED/ { printf "%s ", id; id = "" }' docs/working/questions.md) "
```

Any line under a heading that matches the unanchored regex counts, and the regex has no end anchor. E3 shows it: the old awk printed `Q-010 Q-012 Q-013`. Q-010 is OPEN and only quotes the string in its body. Q-012 is `ANSWERED (2026-11-02)`. The old comment read "(the Status field on the line under each "### Q-NNN" heading)" (pass-2 diff, quoted in this delta's `-` lines).

**Evidence:** `git show 22f9cd8f:scripts/dev-cycle.sh` :479-481; `$S/archive-fixture.log`; E3

---

## Claim 2: "Errs the safe way." / "the error went the safe way (an open entry read as no hold)"

**Location:** `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:15`; commit 57e8950a `Notes:` line
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the direction of the pre-fix error: it read open entries as answered, never answered ones as open, so it could only add items to the "no open entry" list that step 6 inspects. Does not establish that every step 6 action on a falsely flagged item is harmless. Medium because "safe" is a judgment about what step 6 does with the flag.

The old awk only adds IDs to `answered` (Claim 1), and an ID in `answered` is skipped as a hold. The skip is `[[ "$answered" != *" $id "* ]] || continue` (`scripts/dev-cycle.sh:514`; the loop runs :510-521 — read). So the error could only make an item print "no open entry or watch names it". The dev-cycle skill makes each such item a prompt to check it, not a silent move: it "reads that list and acts on each item it shows as "no open entry or watch names it"", sorting it into finished, parked, held outside the questions files, or held by an owner call (`skills/dev-cycle/SKILL.md:624-635`). The opposite error, a stale hold that hides an item, is the R1 class.

**Evidence:** `scripts/dev-cycle.sh:510-521`; `skills/dev-cycle/SKILL.md:624-640`

---

## Claim 3: "Fixed (57e8950a): reads Status only from the `**Needs:**` line, split on " · ", compared exactly as `questions.sh archive` does"

**Location:** `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:15` (Status column)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the R2 cases (body text, a later `##` section, a dated status), which are fixed. Does not establish parity with `archive` for an entry with two `**Needs:**` lines (Claim 6b) or a Needs line with no Opened field (Claim 6c).

The R2 cases are fixed. On the test fixture the new set is `Q-013` only, which matches what `archive` moved (E3). Precise version: the awk "reads Status only from the **first** `**Needs:**` line under the heading". `archive` acts on the status from the **last** Needs line (Claim 6b), so "as `questions.sh archive` does" needs that qualifier.

**Evidence:** `scripts/dev-cycle.sh:483-486`; `scripts/questions.sh:221-231`, `:464-465`; E1, E3

---

## Claim 4: "Fixed with R2: the digest now drops exactly what `archive` moves"

**Location:** `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:23` (A4 Status column)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "exactly" claim, refuted on three inputs. It holds for well-formed single-Needs entries, including CRLF and a two-space heading. It does not establish how often multi-Needs entries occur in practice (none in this worktree's file, E6).

E1: the digest dropped `Q-002 Q-004 Q-005 Q-006`, and `archive` moved `Q-001 Q-004 Q-005`. The two sets differ both ways:
- Q-001 (OPEN, then a second Needs line with ANSWERED). `archive` moves it, but the digest still lists it as a hold. This is the R1 stale-hold direction.
- Q-002 (ANSWERED, then OPEN). The digest drops it, but `archive` keeps it.
- Q-006 and Q-007 (E2; a Needs line with no Opened field). The digest drops them, but `archive` moves neither.

`check` (E4) flags the Q-007 shape as invalid. It flags Q-001 only as "ANSWERED but still in questions.md", which is the same last-line reading `archive` uses, so nothing reports the disagreement. The causes are in Claims 6b and 6c.

**Evidence:** `$S/archive-run.log`, `$S/archive-run4.log`, `$S/check-run.log`; E1, E2, E4

---

## Claim 5: "A5 … Fixed" and the corrected research line: "`open_q` may still hold the first `qopen` call's full list (the first call succeeded, the second failed), so section 5 gates on `open_ok`, set only when both succeed"

**Location:** `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:24`; `docs/working/research-2026-11-18-roadmap-staleness.md:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the and-chain at section 3 and the `open_ok` gate in section 5. Does not establish what `open_q` holds when the first call itself fails partway, which the line does not claim.

```
# scripts/dev-cycle.sh:417-418
  if open_q="$(qopen "$ROOT/$QW" 2>"$qs_err")" && open_l="$(qopen "$qs_err.none" 2>>"$qs_err")"; then
    open_ok=1   # section 5 reads open_q too
```

When the first call succeeds, `open_q` gets its whole stdout before the second call runs. `open_ok` is set only inside the `then`. Section 5 tests `if [[ "$open_ok" != 1 ]]` (`scripts/dev-cycle.sh:476`). Commit 57e8950a's "The research doc's open_q line is corrected again" matches the delta's one-line change at :35.

**Evidence:** `scripts/dev-cycle.sh:385`, `:417-418`, `:476-477`; `docs/working/research-2026-11-18-roadmap-staleness.md:35`

---

## Claim 6a: "read as questions.sh's parse_entries reads it: the Status field of the **Needs:** line under a "### Q-NNN " heading, the fields split on " · "" (the field extraction)

**Location:** `scripts/dev-cycle.sh:479-481`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers, for one Needs line: the heading regex, the `id` guard, the `**` strip, the ` · ` split and `substr(f[i], 9)`. Also covers a two-space heading giving the same result. Does not establish which Needs line counts when there are several (Claim 6b).

```
# scripts/dev-cycle.sh:483-486
    answered=" $(awk '/^### Q-[0-9]+ / { id = $2; next }
      /^\*\*Needs:\*\*/ && id != "" { l = $0; gsub(/\*\*/, "", l); n = split(l, f, " · ")
        for (i = 1; i <= n; i++) if (f[i] ~ /^Status:/ && substr(f[i], 9) == "ANSWERED") printf "%s ", id
        id = "" }' docs/working/questions.md) "
```

```
# scripts/questions.sh:211-231 (parse_entries; enclosing awk :203-257 — read)
        /^### Q-[0-9]+ / {
            ...
            split(line, parts, " · ")
            id = parts[1]
        /^\*\*Needs:\*\*/ {
            if (id == "") next
            line = $0
            gsub(/\*\*/, "", line)
            n = split(line, f, " · ")
            ...
                if (f[i] ~ /^Status:/) { status = substr(f[i], 9) }
            }
            next
```

The heading regex, the guard, the strip, the split and the offset all match. One difference: the ID comes from `$2` here and from `parts[1]` in parse_entries. For `### Q-004  · …`, parse_entries yields `Q-004 ` with a trailing space. The outcome is the same anyway: the digest dropped Q-004 and `archive` moved it (E1), and section 5's `open_q` lookup compares awk's `$1`.

**Evidence:** `scripts/dev-cycle.sh:483-486`; `scripts/questions.sh:200-258`; E1

---

## Claim 6b: "read as questions.sh's parse_entries reads it" (over a whole entry)

**Location:** `scripts/dev-cycle.sh:479-480`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers entries with more than one column-0 `**Needs:**` line before the next `### Q-` heading, including one in a later `## ` section. Does not establish that such entries occur in real files (none in this worktree, E6).

The digest clears `id = ""` after the first Needs line (quoted in Claim 6a, :486), so the first one wins. parse_entries never resets `id` on a Needs line. It ends that block with `next` (`scripts/questions.sh:231`) and resets only in `flush()` at the next heading or at END, so each later Needs line overwrites `status` and the last one wins. `archive` acts on that value (Claim 6c). E1 shows the two readings disagreeing both ways (Q-001, Q-002; see Claim 4). Precise version: "reads the first `**Needs:**` line's Status; parse_entries keeps the last".

**Evidence:** `scripts/dev-cycle.sh:483-486`; `scripts/questions.sh:203-210`, `:221-231`; `$S/archive-run.log`

---

## Claim 6c: "compared as `archive` compares it"

**Location:** `scripts/dev-cycle.sh:482`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-string comparison and the CR case (neither side strips a CR, so `ANSWERED\r` counts on neither side; E1's Q-003). Does not cover a Needs line with an empty field before Status, where `archive` compares a different field.

```
# scripts/questions.sh:464-465 (cmd_archive :460-481 — read)
    while IFS=$'\t' read -r id _ _ status _ _; do
        [[ "$status" == "ANSWERED" ]] || continue
```

Both sides use an exact `==` on `ANSWERED`, and neither strips a CR (`cmd_open` strips one, but only for watching-file lines at :580). However, a tab in `IFS` is whitespace, so an empty Opened field collapses and the status shifts into `_`. E2's Q-007 (`**Needs:** you: judgment · **Status:** ANSWERED`) is answered for the digest but not moved by `archive`. `check` rejects that shape (E4). Precise version: "compared exactly, as `archive` compares a well-formed entry's Status".

**Evidence:** `scripts/questions.sh:460-481`, `:580`; `$S/archive-run4.log`, `$S/check-run.log`; E1, E2, E4

---

## Claim 6d: "Section 3's list still carries these entries."

**Location:** `scripts/dev-cycle.sh:482`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers live-file entries in `open_q`. Does not cover watching-file entries, which `open` already filters.

```
# scripts/questions.sh:580
    { parse_entries "$LIVE"; parse_entries "$WATCHING" | awk -F'\t' '{ s = $4; sub(/\r$/, "", s) } s != "ANSWERED"'; } \
```

Live-file entries reach the listing whatever their status. `open_q` is the first `qopen` call's output (`scripts/dev-cycle.sh:416-417`).

**Evidence:** `scripts/questions.sh:575-591`; `scripts/dev-cycle.sh:416-417`

---

## Claim 7: "Q-012's status is not exactly ANSWERED, so archive would not move it and it still holds."

**Location:** `test/scripts/dev-cycle.bats:1767`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Q-012 in this fixture (`**Status:** ANSWERED (2026-11-02)`, with Opened present). Does not cover other non-exact statuses.

Q-012's line is `**Needs:** you: judgment · **Opened:** 2026-11-01 · **Status:** ANSWERED (2026-11-02)` (`test/scripts/dev-cycle.bats:1750`). In E3, `archive` on the extracted fixture printed `→ archived Q-013` and `✓ archived 1 entry`, so Q-012 stayed. The test asserts `- Now 2 · B: open Q-012 (you: judgment)` and passes (E5).

**Evidence:** `test/scripts/dev-cycle.bats:1737-1771`; `scripts/questions.sh:464-465`; `$S/archive-fixture.log`, `$S/bats.log`

---

## Claim 8: "section 5 reads an entry's Status only from its Needs line, exactly, as questions.sh does" (test name)

**Location:** `test/scripts/dev-cycle.bats:1737`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's three entries: a body quote, a `## Notes` quote, a dated status and a plain ANSWERED. The test passes, and its expected holds match `archive`'s result on the same fixture. Does not cover the multi-Needs or no-Opened inputs where the parity fails (Claims 6b, 6c), which the test does not exercise.

The test passes (E5, `ok 94`). On the same fixture the old awk would have dropped Q-010 and Q-012 (E3), so the test tells the fix apart from the bug.

**Evidence:** `test/scripts/dev-cycle.bats:1737-1771`; `$S/bats.log`, `$S/archive-fixture.log`

---

## Claim 9: "It now reads the Status field of the **Needs:** line alone, split on " · " as questions.sh's parse_entries splits it, and compares it exactly, as `archive` does, so the digest drops exactly what step 1 archives."

**Location:** commit 57e8950a message body
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the conclusion "drops exactly what step 1 archives", refuted (Claim 4). The split and the exact comparison are right for well-formed single-Needs entries (Claims 6a, 6c). Does not establish real-world frequency.

The verdict rests on the conclusion. The same three counterexamples as Claim 4 apply: Q-001 and Q-002 (two Needs lines, E1) and Q-007 (no Opened field, E2). "The **Needs:** line" also assumes there is one; the awk reads the first, while archive acts on the last.

**Evidence:** `scripts/dev-cycle.sh:483-486`; `scripts/questions.sh:221-231`, `:464-465`; E1, E2

---

## Claim 10: "Addresses review R2, A4, A5" (57e8950a) and "add the R2 row the last commit's rubric edit missed" (969e8227)

**Location:** commit 57e8950a and 969e8227 messages
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric's rows at each commit. Does not establish the content of the rows beyond Claims 1-5.

`git show 57e8950a:docs/reviews/code-review-rubric-…md` contains A4 (line 22) and A5 (line 23) but no `| R2` row. At 969e8227 the R2 row is at line 15. The pass-2 report added in this delta has the Claims 3, 4b, 5b, 5c and 10 that the rows cite.

**Evidence:** `docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:15`, `:23-24`; `git show 57e8950a:` same path :22-23

---

## Claim 11: "no questions file in this repo triggered it."

**Location:** commit 57e8950a `Notes:` line
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the worktree's `docs/working/questions.md` at 969e8227: the old and new awk give the same result there. Does not cover other repos' questions files or other branches of this one.

E6: both programs printed an empty set on the worktree's file. The file has 3 entries, each with exactly one Needs line and no CR, so the Claim 6b and 6c residue cannot fire on it either.

**Evidence:** `docs/working/questions.md`; E6

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`docs/reviews/code-review-rubric-2026-11-18-fix-dev-cycle-roadmap-staleness.md:23`): "the digest now drops exactly what `archive` moves" is false for an entry with two Needs lines (both directions; Q-001 is the R1 stale-hold direction) and for a Needs line with no Opened field.
- **Claim 6b** (`scripts/dev-cycle.sh:479-480`): the digest uses the first `**Needs:**` line (`id = ""` after it), while parse_entries keeps overwriting `status` and uses the last. Either match parse_entries (the last Needs line) or state "the first Needs line".
- **Claim 9** (commit 57e8950a): "so the digest drops exactly what step 1 archives" is the same over-broad parity claim as Claim 4.

### Mostly Accurate
- **Claim 3** (`docs/reviews/code-review-rubric-…md:15`): "compared exactly as `questions.sh archive` does" needs the first-vs-last Needs qualifier.
- **Claim 6c** (`scripts/dev-cycle.sh:482`): "compared as `archive` compares it" holds for well-formed entries. `archive`'s `IFS=$'\t' read` collapses an empty Opened field and compares a shifted field (Q-007); `check` rejects that shape.

---

## Goal-Alignment Note

**Success criterion (verbatim):** "a markdown report saved to /workspace/.claude/wt-roadmap-staleness/docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness-pass3.md, structured per the code-fact-check skill, header `**Commit:** 969e8227` and `**Replication:** k=1 (loop pass, decision 031)`."

**Answered:** Yes. All three requested claim groups were checked: the new comment against parse_entries and cmd_archive, including CR handling and the two-Needs case; the test comment; and the R2/A4/A5 rows, both commit messages and the research line. The R2 defect (body text, a later section, prefix match) is fixed and tested. A narrower parity gap remains: first vs last Needs line, and the empty-Opened field shift.

**Out of scope:** Code quality and whether the residue is worth fixing. Commits before 22f9cd8f. The pass-2 report's own content. Real-world frequency of multi-Needs entries outside this worktree.

**Escalate:** None to the owner. The Incorrect parity claim is for-author: the author either aligns the awk with parse_entries' last-Needs-line rule or narrows the comment, rubric A4 and commit wording.
