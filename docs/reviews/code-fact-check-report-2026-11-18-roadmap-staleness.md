# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-roadmap-staleness (claude-workflows)
**Scope:** branch diff `main...HEAD` of `fix/dev-cycle-roadmap-staleness` (commits e50efe75, b7ebe774 and the plan/research docs): `scripts/dev-cycle.sh`, `scripts/lib/migrations.sh`, `skills/dev-cycle/SKILL.md`, `test/scripts/dev-cycle.bats`, `docs/working/research-2026-11-18-roadmap-staleness.md`, `docs/working/plan-2026-11-18-roadmap-staleness.md`, and both commit messages
**Commit:** b7ebe774
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-11-18
**Total claims checked:** 22
**Summary:** 17 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable (22 verdicts, counting split sub-claims 9a/9b and 11a/11b separately)

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern.

Execution logs (outside the repo, in the session scratchpad; none committed):
- L1 `bats test/scripts/dev-cycle.bats`: `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/cfc-bats-xMM9/bats.out` — cwd `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/cfc-bats-xMM9`, command `timeout 900 bats /workspace/.claude/wt-roadmap-staleness/test/scripts/dev-cycle.bats`, exit 0, started 2026-11-19T06:09:34Z, ended 06:10:07Z; 92/92 ok, including tests 90-92 (the new section 5 tests).
- L2 IFS probe: `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/cfc-probe-gKve/ifs.out` — cwd that directory, `IFS=$'\x1f' read -r sec num title ids` over three records plus one `IFS=$'\t'` control, exit 0, 2026-11-19T06:11:15Z.
- L3 migrations: `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/cfc-probe-gKve/migrations.out` — cwd the worktree, `timeout 60 bash scripts/lib/migrations.sh fingerprint .` (exit 0) and `... check .` (exit 0), 2026-11-19T06:11:15Z.
- L4 end-to-end edge-case probe: `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/cfc-e2e-jXBj/repo/out.txt` (stderr in `err.txt`, empty) — cwd `.../cfc-e2e-jXBj/repo` (a throwaway git repo, HOME and git config isolated), command `timeout 120 bash /workspace/.claude/wt-roadmap-staleness/scripts/dev-cycle.sh`, exit 0, 2026-11-19T06:0x UTC (run just before L1). Fixture: questions.md holding Q-010 OPEN `you: judgment`, Q-011 **ANSWERED** (not archived) `you: judgment`, Q-012 OPEN `trigger` (a legacy watch); roadmap Now items A (names Q-011), B (names Q-012), C (names nothing) followed by a column-0 paragraph and a `### ` heading naming Q-010; then `## Next` with item D; then a second heading `## Now again` with item E.

---

## Claim 1: "`scripts/dev-cycle.sh` section 5 prints only the roadmap's Next section, quoted ... Section 7 counts items in Now, In flight and Next and compares Now with the last brainstorm's commit (`now_of`) [observed]."

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers section 5's pre-branch output (the quoted Next awk is the only roadmap print on main) and section 7's per-section count loop and `now_of` comparison; does not establish anything about section 7's behavior on a roadmap with a repeated heading (see Claim 9a).
**Legibility-target:** for-orchestrator-synthesis

Section 7 loops over the three sections:

```bash
# scripts/dev-cycle.sh:553-556
  for sec in Now "In flight" Next; do
    n="$(awk -v h="## $sec" '... on && /^([-*] |[0-9]+\. )/ { c++ } END { print c + 0 }' docs/roadmap.md)"
    echo "- Roadmap $sec: $n item(s)"
  done
```

and compares Now through `now_of` (`scripts/dev-cycle.sh:598` defines it; `:604` compares `git cat-file blob "$bs_c:docs/roadmap.md" | now_of` with `now_of < docs/roadmap.md`). The diff's context shows section 5 on main held only the `awk ... "## next" ... print "> " $0` line (`scripts/dev-cycle.sh:463`), with no Now print.

**Evidence:** `scripts/dev-cycle.sh:457-463`, `scripts/dev-cycle.sh:551-560`, `scripts/dev-cycle.sh:597-606`

---

## Claim 2: "Section 3 runs `questions.sh open` with the three questions paths pinned (`qopen`), keeping its output in `open_q`: one line per open entry or watch, `ID  ROUTE  slug` [observed]."

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:11`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pinning, the output format and what `open` lists; does not establish anything beyond `cmd_open`'s two sources (the live file and watching.md).
**Legibility-target:** for-author

The format and pinning are right (`qopen() { QUESTIONS_LIVE=... QUESTIONS_ARCHIVE=... QUESTIONS_WATCHING="$1" bash "$QS" open; }`, `scripts/dev-cycle.sh:416`; `printf '%s  %-16s  %s\n' "$id" "$route" "$slug"`, `scripts/questions.sh:584`). But "one line per open entry" is imprecise: `open` filters ANSWERED only from watching.md, and lists every entry of the live file whatever its status:

```bash
# scripts/questions.sh:580
    { parse_entries "$LIVE"; parse_entries "$WATCHING" | awk -F'\t' '{ s = $4; sub(/\r$/, "", s) } s != "ANSWERED"'; } \
```

Its own comment says so: "The live file's entries, then watching.md's not closed (ANSWERED) ones" (`scripts/questions.sh:569`). Precise version: one line per live-file entry (any status, answered-but-unarchived included) and per watching.md entry not ANSWERED. This imprecision is what Claim 11b turns on.

**Evidence:** `scripts/dev-cycle.sh:411-417`, `scripts/questions.sh:569-587`, `scripts/questions.sh:200-258`

---

## Claim 3: "Step 3 checks staleness for "Now's agent work items" only [observed]. A light pass skips step 3 (step 0.5) [observed]."

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:13`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step 3 bullet's wording and step 0.5's skip list; does not establish how an orchestrator actually executes those steps.
**Legibility-target:** for-orchestrator-synthesis

`skills/dev-cycle/SKILL.md:508` opens "- Read Now's agent work items." and step 0.5 says "A light pass skips steps 2, 3, 4 and 4b and runs every other step as written" (`skills/dev-cycle/SKILL.md:358-359`).

**Evidence:** `skills/dev-cycle/SKILL.md:347-362`, `skills/dev-cycle/SKILL.md:508-514`

---

## Claim 4: "Step 8 already says a free slot's reason names "each held item and its hold, not a category", and that "an owner call holds an item only when a questions-file entry asks it" [observed]."

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of both phrases in step 8 on main and on the branch; does not establish that anything enforces them (the research's own "Nothing checks either" was not separately tested beyond Claim 21's grep).
**Legibility-target:** for-orchestrator-synthesis

`skills/dev-cycle/SKILL.md:779`: "An owner call holds an item only when a questions-file entry asks it"; the diff's unchanged context at `:787-788` reads "naming each held item and its hold, not a category".

**Evidence:** `skills/dev-cycle/SKILL.md:779`, `skills/dev-cycle/SKILL.md:785-791`

---

## Claim 5: Invariants: section 3's failure prints "Watched questions were NOT checked" [observed: tests ...]; "The output goes through `scrub_reexec` ... [observed: `scripts/dev-cycle.sh:102`]"; headings pinned by "prints all eight sections"; `skills/dev-cycle/` and `scripts/dev-cycle.sh` are gate code (GATE_CODE).

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:19-22`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four cited facts (named tests exist, line 102 calls the scrub re-exec which pipes stdout and stderr through `scrub`, the section test, GATE_CODE's pattern); does not establish what `scrub` removes.
**Legibility-target:** for-orchestrator-synthesis

`scripts/dev-cycle.sh:102`: `scrub_reexec "${BASH_SOURCE[0]}" "$@"`; the function re-runs the script with both streams piped through `scrub`:

```bash
# scripts/lib/dev-cycle-read.sh:139-144
scrub_reexec() {
  [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]] || return 0
  local self="$1"; shift
  { DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub
  exit "${PIPESTATUS[0]}"
}
```

`scripts/lib/dev-cycle-read.sh:1037`: `GATE_CODE='^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/'`. Tests `@test "a questions.sh failure is reported, never shown as 'None open.'"` (`test/scripts/dev-cycle.bats:428`) and `@test "section 3 lists watches from watching.md ..."` (`:682`) and `"prints all eight sections in a repo with no docs"` (`:40`) exist. Section 3's not-checked prefix is `nc="**Watched questions were NOT checked** —"` (`scripts/dev-cycle.sh:398`).

**Evidence:** `scripts/dev-cycle.sh:102`, `scripts/dev-cycle.sh:398`, `scripts/lib/dev-cycle-read.sh:139-144`, `scripts/lib/dev-cycle-read.sh:1037`, `test/scripts/dev-cycle.bats:40`, `test/scripts/dev-cycle.bats:428`, `test/scripts/dev-cycle.bats:682`

---

## Claim 6: "`--cycle-diff` holds the roadmap's preamble and `## ` headings fixed, and keeps a brief path named outside Done [observed: SKILL.md step 6, row 751]. Moving an item from Now to Ideas or Done is allowed."

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers `--cycle-diff`'s documented roadmap rule and the `cycle_rules` dispatch of `docs/roadmap.md` to `ROADMAP_AWK`; does not establish `ROADMAP_AWK`'s body line by line (not read), so a move that rewrites a brief path's line is not cleared beyond the documented rule.
**Legibility-target:** for-orchestrator-synthesis

The contract comment: "docs/roadmap.md: its lines above the first "## " heading or its "## " lines changed, or a brief file ... named outside Done on BASE named on no line of the index ... refuses" (`scripts/build-loop.sh:228-235`, quoted in part). `cycle_rules` sends the roadmap to that rule: `LC_ALL=C awk -v free="$MIG_ROADMAP" "$ROADMAP_AWK" "$t.o" "$t.n"` (`scripts/build-loop.sh:2318`). Moving a line between sections touches neither the preamble nor a `## ` line, so it passes when no brief name is dropped (paraphrased — no quote available because this is an inference from the rule's listed refusals, not one code line).

**Evidence:** `scripts/build-loop.sh:225-240`, `scripts/build-loop.sh:2258-2320`

---

## Claim 7: "Every item names old answered IDs in its history ("Unit 1 merged at 236f21ee (Q-224 [1])"), so "names an answered ID" would flag every item. The signal is an item with **no open** ID [observed: the roadmap at 686258b1]."

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:33`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the quoted history form occurs in the roadmap at 686258b1 (`git show 686258b1:docs/roadmap.md | grep -c 'Q-224 \[1\]'` → 2); does not establish "every item" item by item (not counted).
**Legibility-target:** for-orchestrator-synthesis

The cited form is present at 686258b1 (paraphrased — no quote available because the evidence is a grep count over a historical blob, not a repo line). "Every" was not checked per item.

**Evidence:** `docs/roadmap.md` at 686258b1 (lines 12-161 span Now through Ideas)

---

## Claim 8: "When section 3 could not read the questions files, `open_q` is unset or empty, and the new list must say it was not checked instead of reporting every item as unheld [inferred]."

**Location:** `docs/working/research-2026-11-18-roadmap-staleness.md:35`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every branch of section 3 as it is on the branch; does not establish the pre-branch state beyond "unset" (no initialization on main).
**Legibility-target:** for-author

The conclusion (the list must not flag every item) is implemented and correct (Claim 10). The premise is imprecise: on the branch `open_q` is never unset (`open_ok=0; open_q=""`, `scripts/dev-cycle.sh:385`), and it is not always empty when section 3 fails: in

```bash
# scripts/dev-cycle.sh:417
  if open_q="$(qopen "$ROOT/$QW" 2>"$qs_err")" && open_l="$(qopen "$qs_err.none" 2>>"$qs_err")"; then
```

a first call that succeeds and a second that fails leaves `open_q` holding the full list while section 3 prints "questions.sh open failed" (`:442`); a first call that fails mid-way leaves partial stdout in it. Precise version: "`open_q` may be empty, partial or full; only `open_ok` says whether it was read" — which is why the code gates on `open_ok`, not on `open_q`.

**Evidence:** `scripts/dev-cycle.sh:385`, `scripts/dev-cycle.sh:399-446`, `scripts/dev-cycle.sh:471`

---

## Claim 9: "Section 7's heading rule (case-insensitive, `## now`, `## now (…)`) is the one to reuse for finding Now and Next" / brief point 3: the new awk's heading matching mirrors section 7's rule; column-0 items; continuation lines belong to the item; `## ` ends a section; CRLF handled.

Split because the parts diverge.

## Claim 9a: The new awk's Now/Next heading rule mirrors section 7's.

**Location:** `scripts/dev-cycle.sh:484-487` (also `docs/working/research-2026-11-18-roadmap-staleness.md:28`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heading predicate, the item regex, CRLF stripping and `## ` ending a section; does not establish identical behavior on a roadmap with a second matching heading.
**Legibility-target:** for-author

The predicate is the same string test as section 7 (`t == "## now" || index(t, "## now ") == 1 || index(t, "## now(") == 1`, `scripts/dev-cycle.sh:485`, versus `t == g || index(t, g " ") == 1 || index(t, g "(") == 1`, `:554`), the item regex is the same `/^([-*] |[0-9]+\. )/`, and `sub(/\r$/, "")` runs before both (CRLF case passes in L1, test 90). The one difference: section 7 `exit`s at the first `## ` after its section, while the new awk resets `sec` on every `## ` and re-enters a later matching heading, continuing the count. In L4 a second heading `## Now again` produced `- Now 4 · E: no open entry or watch names it` after `Next 1`, where section 7 counts Now as 3. Precise version: "mirrors section 7's predicate; unlike section 7 it reads every matching heading, not only the first".

**Evidence:** `scripts/dev-cycle.sh:474-491`, `scripts/dev-cycle.sh:551-556`, L4 `out.txt`, L1 `bats.out` (test 90)

## Claim 9b: "Column-0 item"; "An indented sub-step belongs to its item ... not an item of its own" (test comment, plan T1 "indented sub-steps are not items").

**Location:** `scripts/dev-cycle.sh:464`, `scripts/dev-cycle.sh:488-489`, `test/scripts/dev-cycle.bats:1663-1664`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which lines start an item and which are folded into one; does not establish fence-awareness (a list line inside a code fence in Now would also start an item; not tested).
**Legibility-target:** for-author

Items start only at column 0 and indented sub-steps fold into their item (L1 tests 90 and 92 pass). But the fold rule is broader than "indented sub-steps": every non-blank line after an item until the next item or `## ` heading joins it, including a column-0 prose paragraph and a `### ` subheading:

```awk
# scripts/dev-cycle.sh:488-489
      sec != "" && /^([-*] |[0-9]+\. )/ { flush(); cur = sec; num = ++n[sec]; text = $0; next }
      cur != "" && NF { text = text " " $0 }
```

In L4, item C names no ID, yet a following column-0 paragraph and `### Sub heading Q-010` made it print `- Now 3 · C: open Q-010 (you: judgment)`. So a section-level note after the last item makes that item read as held. Text before the first item is dropped (`cur == ""`). Precise version: "a column-0 list line starts an item; every later non-blank line up to the next item or `## ` heading, whatever its indent, belongs to it".

**Evidence:** `scripts/dev-cycle.sh:476-491`, `test/scripts/dev-cycle.bats:1622-1677`, L4 `out.txt`

---

## Claim 10: `open_ok=1` is set only when section 3's `questions.sh open` calls succeed, and `open_q` holds their output when section 5 reads it (comment "section 5 reads open_q too"; commit e50efe75 "When section 3 did not read the questions files, the list says it was not checked instead of flagging every item").

**Location:** `scripts/dev-cycle.sh:385`, `scripts/dev-cycle.sh:418`, `scripts/dev-cycle.sh:471-472`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all five section 3 branches (skipped questions.md, no questions.md, no questions.sh, skipped archive/watching, `open` failing) and `set -u` safety; does not establish the wording "section 3 did not read them" as a cause for the no-questions.md case (there section 3 printed "No docs/working/questions.md in this repo", a different cause, though still accurate).
**Legibility-target:** for-orchestrator-synthesis

Both variables are initialized at top level before any branch: `open_ok=0; open_q=""` (`scripts/dev-cycle.sh:385`), so they are set under `set -u` (`:90`) on every path. `open_ok=1` is only inside the `then` of the two-call `if` (`:417-418`); the four earlier `if/elif` branches (`:399-408`) and the `else` at `:441-445` leave it 0. Nothing between `:446` and `:471` reassigns either (grep of `open_q|open_ok` returns only `:385, :417, :418, :425, :439, :465, :471, :500`). Section 5 gates on it:

```bash
# scripts/dev-cycle.sh:471-472
  if [[ "$open_ok" != 1 ]]; then
    echo "Now and Next items were NOT checked against open entries and watches: section 3 did not read them."
```

Executed: L1 test 90's no-archive leg asserts the not-checked line and no "no open entry or watch names it" — ok.

**Evidence:** `scripts/dev-cycle.sh:90`, `scripts/dev-cycle.sh:384-446`, `scripts/dev-cycle.sh:471-472`, L1 `bats.out` (test 90)

---

## Claim 11: "An item names old answered IDs in its history, so only an open one counts." (code comment; also commit e50efe75 body) — and brief point 5: an ID absent from the open list is treated as not holding the item, including legacy watches still in questions.md.

Split because the parts diverge.

## Claim 11a: Archived answers and closed watches do not hold an item; legacy watches in questions.md do.

**Location:** `scripts/dev-cycle.sh:466`, `scripts/dev-cycle.sh:498-501`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers IDs in questions-archive.md, watching.md entries marked ANSWERED, and open legacy watches in questions.md; does not cover ANSWERED entries still in questions.md (Claim 11b).
**Legibility-target:** for-orchestrator-synthesis

The lookup is an exact first-field match in `open_q`: `awk -v id="$id" '$1 == id { ... print r; exit }'` (`scripts/dev-cycle.sh:500`); an empty `r` adds nothing (`:501`). `open` never reads the archive and drops ANSWERED watching.md entries (`scripts/questions.sh:580`). L1 test 90: Q-001 (archived) and Q-021 (closed watch) give "Finished work: no open entry or watch names it"; Q-020 (open watch) holds. L4: legacy watch Q-012 in questions.md gives `- Now 2 · B: open Q-012 (trigger)`.

**Evidence:** `scripts/dev-cycle.sh:496-503`, `scripts/questions.sh:575-587`, L1 `bats.out` (test 90), L4 `out.txt`

## Claim 11b: "only an open one counts" — for an answered entry still in questions.md.

**Location:** `scripts/dev-cycle.sh:466`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an entry marked `**Status:** ANSWERED` that is still in the live questions.md (not yet moved by `questions.sh archive`); does not establish how long such entries sit in the live file in practice.
**Legibility-target:** for-author

`open_q` comes from `questions.sh open`, which lists live-file entries of any status (`parse_entries "$LIVE"` with no status filter, `scripts/questions.sh:580`; see Claim 2). So an answered-but-unarchived entry counts as holding the item, and the digest labels it "open". L4: Q-011 is `**Status:** ANSWERED` in questions.md and item A printed

```
- Now 1 · A: open Q-011 (you: judgment)
```

That's the exact case the branch exists to catch: an item whose hold was answered keeps reading as held. It happens whenever answers are recorded inline and `archive` has not yet run. What the code does: it counts any ID listed by `questions.sh open`, which includes ANSWERED entries in the live file. The comment holds only if the live file never contains ANSWERED entries.

**Evidence:** `scripts/dev-cycle.sh:466`, `scripts/dev-cycle.sh:498-501`, `scripts/questions.sh:569-587`, L4 `out.txt`

---

## Claim 12: "One record per item: SECTION, N, TITLE (its first bold span, else its first 80 characters), IDS, joined by \x1f (a tab is IFS whitespace: an empty field would collapse and shift the rest)."

**Location:** `scripts/dev-cycle.sh:467-469`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `read -r` with `IFS=$'\x1f'` keeping an empty TITLE, an empty IDS and titles with internal, leading and trailing spaces, and the tab-collapse rationale; does not establish behavior for a title holding a \x1f byte, or the bold span being taken from a continuation line when the item line has none (the span is searched over the whole folded `text`, `:478`).
**Legibility-target:** for-orchestrator-synthesis

L2 output: `[Now][1][a title  with spaces][]` (empty trailing IDS kept), `[Now][2][][ Q-1 Q-2]` (empty TITLE kept, IDS not shifted), `[Now][3][ t ][ Q-3]` (spaces kept); tab control `IFS=$'\t'` on `Now\t2\t\t Q-1` gave `[Now][2][ Q-1][]`, i.e. the empty field collapsed and shifted IDS into TITLE, as the comment says. The `IFS=` prefix applies to `read` only, so `for id in $ids` (`:499`) splits on default IFS. The awk emits that layout: `printf "%s\037%d\037%s\037%s\n", cur, num, title, ids` (`scripts/dev-cycle.sh:481`).

**Evidence:** `scripts/dev-cycle.sh:476-482`, `scripts/dev-cycle.sh:497-503`, L2 `ifs.out`

---

## Claim 13: Route extraction `substr($0, index($0, "  ") + 2, 16)` matches how section 3 parses `questions.sh open` lines, including routes with a space.

**Location:** `scripts/dev-cycle.sh:500`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers well-formed `open` lines (ID with no double space, route of at most 16 characters); does not establish behavior for a malformed heading whose ID field contains a double space.
**Legibility-target:** for-orchestrator-synthesis

Identical to section 3's `r = substr($0, index($0, "  ") + 2, 16); sub(/ +$/, "", r)` (`scripts/dev-cycle.sh:425`), against the producer `printf '%s  %-16s  %s\n' "$id" "$route" "$slug"` (`scripts/questions.sh:584`): the first double space follows the ID, and 16 characters span the padded route. L1 test 90 asserts `Q-010 (you: judgment)` and `Q-020 (trigger)`; L4 printed the same forms.

**Evidence:** `scripts/dev-cycle.sh:425`, `scripts/dev-cycle.sh:500`, `scripts/questions.sh:581-586`, L1 `bats.out`, L4 `out.txt`

---

## Claim 14: Registry line `mig record-6-roadmap-holds record 3ea937fac644c6d4 - - 'none: the record's 6. line only gained what moved and each unheld item's hold; every record written before stays valid'`.

**Location:** `scripts/lib/migrations.sh:165`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fingerprint matching the record template's current source and the registry check passing, and the absence of any script that parses the `6.` line; does not establish that every orchestrator reading an old record handles the shorter `6. roadmap: done` form (that's prose read by a model).
**Legibility-target:** for-orchestrator-synthesis

L3: `migrations.sh fingerprint .` prints `record 3ea937fac644c6d4` (same value as the line), and `migrations.sh check .` exits 0. `rg` for `6\. roadmap` / a `^6\.` matcher across `scripts/` and `hooks/` finds no parser of the record's `6.` line (paraphrased — no quote available because the claim covers absence of code: no matching grep results), so older records cannot fail a check on it.

**Evidence:** `scripts/lib/migrations.sh:162-165`, `skills/dev-cycle/SKILL.md:858`, L3 `migrations.out`

---

## Claim 15: Step 0's section map: "5 roadmap (steps 6 and 8)".

**Location:** `skills/dev-cycle/SKILL.md:328`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that step 6 and step 8 both now name section 5 as their input; does not establish other steps reading section 5.
**Legibility-target:** for-orchestrator-synthesis

Step 6's new bullet opens "The digest's section 5 lists each Now and Next item" (`skills/dev-cycle/SKILL.md:624`) and step 8's new sentence "The holds come from the digest's section 5 list" (`:789-790`).

**Evidence:** `skills/dev-cycle/SKILL.md:328`, `skills/dev-cycle/SKILL.md:624-639`, `skills/dev-cycle/SKILL.md:789-791`

---

## Claim 16: Step 3: "Every other Now item is checked in step 6, which a light pass runs too."

**Location:** `skills/dev-cycle/SKILL.md:513-514`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that a light pass runs step 6 and that step 6's bullet covers every Now item the digest lists; does not establish coverage of Now items when section 5 prints the not-checked line (step 6's bullet gives no rule for that case, and step 3, which handles the not-checked case, is skipped in a light pass).
**Legibility-target:** for-orchestrator-synthesis

Step 0.5: "A light pass skips steps 2, 3, 4 and 4b and runs every other step as written" (`skills/dev-cycle/SKILL.md:358-359`).

**Evidence:** `skills/dev-cycle/SKILL.md:358-360`, `skills/dev-cycle/SKILL.md:508-514`, `skills/dev-cycle/SKILL.md:624-639`

---

## Claim 17: Step 6's "Items nothing open holds" bullet: "The digest's section 5 lists each Now and Next item with the open entries and watches it names ... acts on each item it shows as "no open entry or watch names it"".

**Location:** `skills/dev-cycle/SKILL.md:624-627`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact quoted string and the per-item list's existence when section 3 read the questions files; does not establish that "open" means unanswered (see Claim 11b: an ANSWERED live entry shows as open) or the list's presence when section 3 failed (the digest prints the not-checked line instead).
**Legibility-target:** for-orchestrator-synthesis

The digest prints that string verbatim: `else echo "- $sec $num · $title: no open entry or watch names it"; fi` (`scripts/dev-cycle.sh:503`), asserted in L1 test 90.

**Evidence:** `scripts/dev-cycle.sh:494-504`, `skills/dev-cycle/SKILL.md:624-639`, L1 `bats.out`

---

## Claim 18: Step 8: "The holds come from the digest's section 5 list and step 6's `6.` line, never from the last record's `8.` line".

**Location:** `skills/dev-cycle/SKILL.md:789-791`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both named sources exist (section 5's list; step 6's bullet that requires naming each outside hold on the `6.` line, `:632-633`, and the template's `6.` line, `:858`); does not establish enforcement (none exists: prose rule).
**Legibility-target:** for-orchestrator-synthesis

Step 6 says "it stays, and the record's `6.` line names that hold for this item" (`skills/dev-cycle/SKILL.md:632-633`); the template reads `6. roadmap: <done; moved to Done or Ideas: ITEMS (why) / none; items no open entry names: each with its hold>` (`:858`).

**Evidence:** `skills/dev-cycle/SKILL.md:632-633`, `skills/dev-cycle/SKILL.md:789-791`, `skills/dev-cycle/SKILL.md:858`

---

## Claim 19: Commit e50efe75 Notes: the `--cycle-diff` refusal of a blanket `8.` line was "dropped (research Gotchas: the line is prose and Now has no stable item IDs)".

**Location:** commit e50efe75 message (Notes); `docs/working/research-2026-11-18-roadmap-staleness.md:36`; `docs/working/plan-2026-11-18-roadmap-staleness.md:10`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit's citation matching the research Gotcha, and `--cycle-diff` judging cycle records by path class only, not by line content; does not establish that a mechanical check is impossible (the Gotcha is tagged [inferred]: a design judgment).
**Legibility-target:** for-orchestrator-synthesis

Research line 36: "the record's `8.` line is prose, Now has no item IDs, and an iteration edits Now before writing the line". In `cycle_rules` a cycle record passes the truth-rule and path checks and then falls into `*) continue ;;` of

```bash
# scripts/build-loop.sh:2295-2299
    case "$p" in
      docs/working/questions.md|docs/working/questions-archive.md) qi+=("$i"); continue ;;
      docs/roadmap.md|docs/working/idea-log.md|docs/working/watching.md) ;;
      *) continue ;;
    esac
```

(excerpt ends :2299; enclosing cycle_rules() continues past :2330 — read to :2330), so no record line is parsed today. Roadmap items carry bold titles, not an ID grammar (`docs/working/research-2026-11-18-roadmap-staleness.md:34`; the bats fixture `test/scripts/dev-cycle.bats:1630-1645`).

**Evidence:** `scripts/build-loop.sh:2258-2330`, `docs/working/research-2026-11-18-roadmap-staleness.md:33-36`, `docs/working/plan-2026-11-18-roadmap-staleness.md:10`

---

## Claim 20: Commit b7ebe774: "The record template's 6. line changed, so migrations.sh gains record-6-roadmap-holds (none: older records stay valid)."

**Location:** commit b7ebe774 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 14; does not establish anything beyond it.
**Legibility-target:** for-orchestrator-synthesis

See Claim 14: L3 fingerprint `record 3ea937fac644c6d4` equals the registry line; `check` exits 0.

**Evidence:** `scripts/lib/migrations.sh:165`, L3 `migrations.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11b** (`scripts/dev-cycle.sh:466`): "only an open one counts" does not hold for an entry marked ANSWERED that is still in questions.md. `questions.sh open` lists live-file entries of any status, so the digest prints it as `open Q-NNN (route)` and the item reads as held. This is the staleness the branch targets (L4: `- Now 1 · A: open Q-011 (you: judgment)`). Fix the code (filter ANSWERED from the live file too, for section 5's lookup) or narrow the comment and the skill's step 6 wording.

### Mostly Accurate
- **Claim 2** (`docs/working/research-2026-11-18-roadmap-staleness.md:11`): `open_q` is not "one line per open entry": it lists every live-file entry whatever its status, plus non-ANSWERED watches.
- **Claim 8** (`docs/working/research-2026-11-18-roadmap-staleness.md:35`): `open_q` is never unset now, and after a failed second call it can hold the full list; only `open_ok` tells whether it was read.
- **Claim 9a** (`scripts/dev-cycle.sh:484-487`): the heading predicate mirrors section 7, but the new awk re-enters a second matching `## Now`/`## Next` heading (continuing the numbering), while section 7 stops at the first.
- **Claim 9b** (`scripts/dev-cycle.sh:488-489`, `test/scripts/dev-cycle.bats:1663`): any non-blank line up to the next item or `## ` heading folds into the item, column-0 prose and `### ` headings included, not only indented sub-steps. A section note after the last item makes that item read as held.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to /workspace/.claude/wt-roadmap-staleness/docs/reviews/code-fact-check-report-2026-11-18-roadmap-staleness.md, structured per the code-fact-check skill, with `**Commit:** b7ebe774` and `**Replication:** k=1 (loop pass, decision 031)` in its header.
- Answered: all nine requested checks: 1 → Claim 10 (+8); 2 → Claim 12; 3 → Claims 9a/9b; 4 → Claim 13; 5 → Claims 11a/11b; 6 → Claims 15-18; 7 → Claims 14/20; 8 → Claim 19; 9 → Claims 1-8. The report is written and not committed.
- Out of scope: code quality and fixes; `ROADMAP_AWK`'s body; fence-awareness of the item rule; how often ANSWERED entries sit unarchived in practice. Also ran `bash scripts/lib/migrations.sh fingerprint|check` (read-only), which the brief did not list. A full-suite `bats` run (PIDs 1699336 and others) was running in this worktree during the review. It was not started by this review and was left alone.
- Escalate: Claim 11b (Incorrect) affects the branch's purpose. The orchestrator should decide whether to fix it before merge.
