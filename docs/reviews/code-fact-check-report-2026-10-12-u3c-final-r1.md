Commit: ec9dace7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3c (branch `feat/build-loop-u3c`)
**Scope:** full branch diff `main...ec9dace7` (main = dafc0e74): `docs/reviews/override-log.md` (eight new rows, 745-752), `docs/working/plan-build-loop-handoff.md` (lines 104, 209, the U3c bullet 327-333), `scripts/build-loop.sh` (the `--cycle-diff` header and Exit paragraph, raw_records, QKEYS_AWK, QDIFF_AWK, ROADMAP_AWK, cyc_blob, cycle_diff, check_line and log_class on raw_records), `scripts/health-check.sh` (HEALTH_CHECK_LOCK_HELD, take_lock), `scripts/lib/dev-cycle-read.sh` (the ANSWER_AWK pointer comment), `test/scripts/build-loop-orchestrator.bats` (three new tests), `test/scripts/health-check-lock.bats` (T43), and the six non-review commit bodies (6f347256, 3021d0a4, f34fceb0, 414c9295, d77dae74, ec9dace7)
**Checked:** 2026-10-12 (execution timestamps below are UTC, 2026-10-13T06:08Z-06:20Z)
**Commit:** ec9dace7
**Replication:** replicate of k=3 (agent tag fc-u3c-final-r1)
**Total claims checked:** 46
**Summary:** 35 verified, 8 mostly accurate, 0 stale, 1 incorrect, 2 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. Its entries are count and tally fabrications (corpus statistics, test tallies, golden counts, consumer lists). The one claim of that kind here, ec9dace7's "unit at 386 code lines" (Claim 42d), was recounted and matches. No claim matches a logged pattern.

Legibility-target tags: SKILL.md (as read for this pass) defines no such tag set, so none are emitted; every claim carries the seven mandatory fields.

## Execution provenance

Scratch dir S = `/tmp/claude-1000/-workspace/f335f5f6-1b17-4519-891d-602641cba507/scratchpad/fc-u3c-final-r1`. Fixture repos only under `S/p-*`, `S/p2-*`, `S/m-*`, `S/m2-*` (each script `set -eu`, creates its own temp dir and refuses to run outside S). Mutants ran on scratch copies of HEAD's `scripts/` and `test/` (or f34fceb0's `health-check.sh`); nothing in the worktree was written but this report. After E6, `ps` showed no flock or health-check process left.

| Run | Command (cwd) | Exit | Started (UTC) | Output |
|---|---|---|---|---|
| E1 | `TMPDIR=$(mktemp -d /tmp/u3c-fc-u3c-final-r1-XXXX) bats test/scripts/health-check-lock.bats` (worktree) | 0 (2/2 ok) | 2026-10-13T06:08:47Z | `S/logs/hcl.log` |
| E2 | same TMPDIR form, `bats test/scripts/build-loop-orchestrator.bats` (worktree) | 0 (24/24 ok) | 2026-10-13T06:09:04Z | `S/logs/blo.log` |
| E3 | `bash S/run-probe.sh` → `bats S/probe/test/scripts/probe.bats` (cwd `S/p-*`): P1-P4 shapes against HEAD's build-loop.sh | 0 | 2026-10-13T06:10:28Z | `S/logs/probe.log`, `S/logs/probe-bats.log` |
| E4 | `bash S/probe2.sh` (cwd `S/p2-uMdZ`): health-check exit passthrough, no-repo run, ls-tree vs diff-tree pathspec in a gate-like repo | 0 | 2026-10-13T06:11:02Z | `S/logs/probe2.log` |
| E5 | `bash S/run-probe3.sh` → `bats S/probe/test/scripts/probe3.bats` (cwd `S/p-*`): P5, a base questions file `--check-answer` skips as "quoted", made readable | 0 | 2026-10-13T06:12:10Z | `S/logs/probe3.log`, `S/logs/probe3-bats.log` |
| E6 | `bash S/mutants.sh` (cwd `S/m-SN14`): (a) T43 on f34fceb0's health-check.sh; (b) T38 with ec9dace7's main-changed rule deleted | 0 (script); (a) bats 1, (b) bats 1 | 2026-10-13T06:12:54Z | `S/logs/mutants.log`, `S/m-SN14/a.log`, `S/m-SN14/b.log` |
| E7 | `bash S/mutants2.sh` (cwd `S/m2-iiWd`): base = MAIN_SHA; no `take_lock` call; no nested-run exemption; `flock -n` on a FIFO; flock missing from PATH | 0 (script); mutant bats 1, 1, 124 (timeout: deadlock); FIFO 124; missing 127 | 2026-10-13T06:14:38Z | `S/logs/mutants2.log`, `S/m2-iiWd/{base,nolock,nonest}.log` |

---

## Claim 1: "Re-keys row 722 ... --cycle-diff judges only the questions files, the roadmap and the idea log; every other staged path is not judged"

**Location:** `docs/reviews/override-log.md:745`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which staged paths cycle_diff reads; does not establish anything about how U4 commits the other paths (the row's own deferral).

```bash
# scripts/build-loop.sh:1813-1817
    case "$p" in
      docs/working/questions.md|docs/working/questions-archive.md) qi+=("$i"); continue ;;
      docs/roadmap.md|docs/working/idea-log.md) ;;
      *) continue ;;
    esac
```
(excerpt ends inside the loop; cycle_diff continues to :1866 — read). Test 24 stages `other.md` with the cycle's rewrites and gets `ok` (E2).

**Evidence:** `scripts/build-loop.sh:1811-1829`, `test/scripts/build-loop-orchestrator.bats` test 24, `S/logs/blo.log`

---

## Claim 2: "Row 724 discharged ... Equivalent to the three old readers, but log_class's chore loop now reads a commit with an unparsed or incomplete record as other instead of skipping the record"

**Location:** `docs/reviews/override-log.md:746`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers acceptance of check_line's and log_class's answers loop (unchanged) and the chore loop's one change; does not establish timing (Claim 42c) and was not run against a malformed listing (git does not print one).

Old check_line read `while IFS= read -r -d '' meta && IFS= read -r -d '' p` with the same regex (old ids not captured) and then refused unless the NUL count was `2 * ${#ps[@]}`; new code is `raw_records "$GATE_TMP/diff" || { echo "refuse $a: the paths the merge of $br changes could not be read"; return; }` (`scripts/build-loop.sh:1316`), same text. raw_records returns 1 on a half record (`IFS= read -r -d '' p || return 1`, :975) or an unparsed meta (:976), which the old NUL-count and regex checks also refused; trailing bytes after the last NUL are ignored by both. The answers loop keeps `[[ ${#RAW_P[@]} -gt 0 ]]` (the old `x -gt 0`) and the same `100644 100644 M` + path test (:1706-1709). The chore loop previously `continue`d past a non-matching record and stopped silently at a half record; it now ends with `raw_records "$GATE_TMP/d" || return 0` (:1701), CLASS staying other, as the row says.

**Evidence:** `scripts/build-loop.sh:965-980`, `:1316-1318`, `:1700-1710`; old code in `git diff main...HEAD -- scripts/build-loop.sh`

---

## Claim 3: "a FIFO swapped in between the plain-file test and flock's open hangs instead of refusing; flock missing exits with flock's own status ... every failure exits non-zero"

**Location:** `docs/reviews/override-log.md:749`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers flock(1)'s open of a FIFO and a missing flock binary; does not establish the race window itself (not raced).

E7: `timeout 3 flock -n "$T/fifo" true` → rc 124 (blocked in open, not a lock conflict); `PATH="$T/bin" bash -c 'flock -n -E 75 -o x true'` → rc 127, which take_lock passes to `exit "$rc"` (`scripts/health-check.sh:1113,1118`). "flock's own status" reads as the status of the flock command line, 127.

**Evidence:** `scripts/health-check.sh:1104-1119`, `S/logs/mutants2.log`

---

## Claim 4: "the live roadmap's preamble holds a dated 're-checked' line ... the Done match now follows dev-cycle.sh"

**Location:** `docs/reviews/override-log.md:750`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers main's docs/roadmap.md preamble and the Done-match expression; does not establish that dev-cycle.sh reads a Done section (it matches Now, In flight and Next with the same rule).

`git show main:docs/roadmap.md` preamble: "Seeded 2026-09-29 by hand; first re-checked by the dev cycle on 2026-10-02". ROADMAP_AWK: `done[s] = (d == "## done" || index(d, "## done ") == 1 || index(d, "## done(") == 1)` (`scripts/build-loop.sh:1781`); dev-cycle.sh: `t == g || index(t, g " ") == 1 || index(t, g "(") == 1` (`scripts/dev-cycle.sh:490`).

**Evidence:** `scripts/build-loop.sh:1779-1794`, `scripts/dev-cycle.sh:442,490`

---

## Claim 5: "--cycle-diff now refuses a questions change while main has changed the questions files since the fork point"

**Location:** `docs/reviews/override-log.md:751`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal when either questions file differs between base and MAIN_SHA and the index changes a questions file; does not establish anything about a main that moves after the check (the row's U4 duty).

```bash
# scripts/build-loop.sh:1835-1838
  if ! gate_git ls-tree -z "$base" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lb" \
    || ! gate_git ls-tree -z "$MAIN_SHA" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lm" || ! cmp -s "$t.lb" "$t.lm"; then
    echo "refuse docs/working/questions.md: the default branch changed the questions files since the fork point $base, ..."; return 1
  fi
```
E3 P2a: main changed only the archive, index edited a questions.md body line → exit 2 with this line. T38's case passes (E2) and is red with the block deleted (E6 b).

**Evidence:** `scripts/build-loop.sh:1830-1838`, `S/logs/probe.log`, `S/m-SN14/b.log`

---

## Claim 6: "compares the staged files with the fork point of HEAD and MAIN_SHA ..., and refuses a questions change while main has changed the questions files since then" (and line 209's interface bullet)

**Location:** `docs/working/plan-build-loop-handoff.md:104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the base and the main-changed rule as written at :104 and :209; does not establish the "roadmap or idea-log line removed or edited other than by the cycle's own documented moves" beyond the interim reading (Claim 9).

`base="$(git merge-base HEAD "$MAIN_SHA" 2>/dev/null)"` (`scripts/build-loop.sh:1805`); diff-index against `$base` (:1807); main-changed rule per Claim 5. :209's `ok`/`refuse PATH: why` (exit 2) matches `cycle_diff || exit 2; echo ok` (:1882-1885).

**Evidence:** `docs/working/plan-build-loop-handoff.md:104,209`, `scripts/build-loop.sh:1803-1866,1882-1885`, `S/logs/blo.log`

---

## Claim 7: "the index is compared with `git merge-base HEAD MAIN_SHA` (MAIN_SHA itself when main has not moved) ... No merge base (HEAD unborn or unrelated) refuses"

**Location:** `docs/working/plan-build-loop-handoff.md:328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unborn HEAD, HEAD on main, detached HEAD at main and a chore branch with main moved; does not establish behaviour with several merge bases (git prints one) or an unrelated history with commits (static only: merge-base exits 1, same refusal).

T38 test 24 `git checkout -q --orphan lone; cd_is "refuse HEAD: it shares no commit ..."` passes (E2). E3 P2b (on main) and P2c (detached at main) print `ok`. With the base mutated to MAIN_SHA, T38 fails at `onmain docs/roadmap.md "# R"; cd_is ok --answered Q-001` (E7), showing a moved main would read as the cycle's deletion, as the bullet says.

**Evidence:** `scripts/build-loop.sh:1805`, `S/logs/probe.log`, `S/m2-iiWd/base.log`

---

## Claim 8: "each entry as `--check-answer` delimits it (FENCE_AWK first; a refused file refuses), its key lines are its heading, its `**Needs:**` lines and its answer lines"

**Location:** `docs/working/plan-build-loop-handoff.md:330`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers heading match, entry end, fence tracking, CR handling and the key-line set; does not hold for ANSWER_AWK's "quoted" whole-file skip (a `### Q-` heading inside a fence), which QKEYS_AWK does not model (Claim 13).

Same residue as Claim 13: QKEYS_AWK skips a fenced heading as fenced content, ANSWER_AWK skips the whole file (`infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; inside = 0 }`, `scripts/lib/dev-cycle-read.sh:2082`). The precise version: "delimited as --check-answer delimits one, except that a fenced `### Q-` heading, which makes --check-answer skip the whole file, is not refused".

**Evidence:** `scripts/build-loop.sh:1743-1751`, `scripts/lib/dev-cycle-read.sh:2061-2120`, `S/logs/probe3.log`

---

## Claim 9: roadmap and idea-log interim rule (idea log append-only; preamble and `## ` lines fixed; a brief named outside Done never dropped; every other path not judged)

**Location:** `docs/working/plan-build-loop-handoff.md:331`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three refusals and the closed/ rename; does not establish that SKILL.md step 6 only performs moves this rule passes (U4's text).

Test 24 (E2) covers each refusal and the cycle's rewrites; E3 P3a (brief dropped from plain Done → ok), P3c (`a.md` → `closed/a.md` → ok), P3d (new idea log → ok).

**Evidence:** `scripts/build-loop.sh:1779-1794,1820-1828`, `S/logs/blo.log`, `S/logs/probe.log`

---

## Claim 10: "takes flock on `$(git rev-parse --git-common-dir)/health-check.lock` (plain file only, as the dispatch lock), printing one line when it waits; a run inside a run ... is exempt through an exported variable"

**Location:** `docs/working/plan-build-loop-handoff.md:333`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers take_lock in one repository; does not establish behaviour across linked worktrees beyond the common dir (static: `--git-common-dir` is shared).

`lk="$d/health-check.lock"` with `d` from `--git-common-dir` (`scripts/health-check.sh:1107-1108`); plain-file test (:1109-1111), as dispatch's "Only a plain file is opened (a FIFO would block)" (`scripts/build-loop.sh:1923`); one `yellow "waiting for another health check ..."` (:1115); `export HEALTH_CHECK_LOCK_HELD=1` (:1112). T43 passes (E1); dropping the exemption deadlocks T43 (E7, bats timed out at 300 s).

**Evidence:** `scripts/health-check.sh:1104-1119`, `S/logs/hcl.log`, `S/logs/mutants2.log`

---

## Claim 11: "after --state's gate but its caller check: the index against BASE, git merge-base of HEAD and main's commit"

**Location:** `scripts/build-loop.sh:183-188`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the startup order for MODE cycle-diff; does not establish what state_gate checks (prior units).

```bash
# scripts/build-loop.sh:646-649
GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1
# The caller's environment first: it can point the state gate's own reads elsewhere.
if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi
if [[ -n "$GATED" ]]; then state_gate || exit 2; fi
```
Then `cycle-diff) state_start; cycle_diff || exit 2; echo ok` (:1882-1885); state_start runs default_gate, the gate repository and `store_check --main "$MAIN_SHA"` (:1256-1262).

**Evidence:** `scripts/build-loop.sh:646-656,1256-1262,1882-1885`

---

## Claim 12: "PATH is HEAD (no merge base), index (not listed) or the file."

**Location:** `scripts/build-loop.sh:190`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every refusal subject cycle_diff prints; does not establish that "the file" is the file main changed (the main-changed refusal names questions.md even when only the archive changed, E3 P2a; its WHY says "the questions files").

Subjects: `refuse HEAD:` (:1805), `refuse index:` (:1809), `refuse $p:` / `refuse $f:` / `refuse docs/working/$f:` (:1818-1864).

**Evidence:** `scripts/build-loop.sh:1803-1866`, `S/logs/probe.log`

---

## Claim 13: "The questions files, read together (an entry may move between them, delimited as --check-answer reads them; a copy FENCE_AWK refuses refuses)"

**Location:** `scripts/build-loop.sh:191-193`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reading both files together, entry moves, FENCE_AWK refusals and delimitation for every shape --check-answer reads; does not hold for a base copy --check-answer skips as "quoted", where --cycle-diff passes an index that makes the file readable and turns an entry's --check-answer result from skip into keep with no --answered.

Heading rule, entry end, fence handling and CR drop match ANSWER_AWK (`/^### Q-[0123456789]+([ \t]|$)/`, `/^(#|##|###) / { id = ""; next }`, `{ sub(/\r$/, "") }` / `fence($0) { next }`, `scripts/build-loop.sh:1744-1747` against `scripts/lib/dev-cycle-read.sh:2080-2087`). QKEYS_AWK tags every Needs line and every answer-shaped line of any ID, a superset of the first-Needs, first-own-ID-answer lines ANSWER_AWK reads. ANSWER_AWK's "quoted" refusal (`infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; inside = 0 }`, :2082) has no counterpart in QKEYS_AWK. E5 P5: on main, `--check-answer Q-001` printed `skip Q-001: line 7 of docs/working/questions.md is a question heading inside a code fence ...`; the chore index deleted only that fence block (three body lines, no key line), `--cycle-diff` printed `ok`, and after a `--no-ff` land `--check-answer Q-001` printed `keep Q-001`. The answer line was already on the base, so no new answer text was added; what changed is that an answer the reader refused to trust became readable. E3 P4d (a fenced `Q-001: [1]` after the real answer) and P4b (a trailing CR) behave as --check-answer does.

**Evidence:** `scripts/build-loop.sh:1737-1751,1841-1858`, `scripts/lib/dev-cycle-read.sh:2061-2120`, `S/logs/probe3.log`, `S/logs/probe.log`

---

## Claim 14: "an entry on BASE whose heading, **Needs:** or answer lines (--main-log's labels, any ID) differ in the index, in order, or are gone; a new entry filed answered (Status ANSWERED or an answer line); WHY starts with its ID. Except IDs given with --answered (... exact IDs, Q-14 is not Q-014; a repeat or an unused one is ignored). Other entry lines are free."

**Location:** `scripts/build-loop.sh:193-200`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers QDIFF_AWK's two refusal kinds and the --answered match; does not establish the quoted-file residue (Claim 13).

Labels: QKEYS_AWK `t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/` (:1750) equals ANSWERS_AWK's (:1657). `ok[x[i]] = 1` on a space split (:1765) is an exact-string match; repeats and unused IDs only add keys. `answered()` (:1759-1764) flags an `a` line or any Needs field equal to `**Status:** ANSWERED`, a superset of ANSWER_AWK's last-Status-field rule (E3 P4a: `ANSWERED · OPEN` fields refuse). T38 test 22 (E2) covers flip, answer added, deleted entry, swapped answers, route change, removed answer, deleted archive, body edits, an open new entry, a pre-answered new entry, a repeat/unused --answered.

**Evidence:** `scripts/build-loop.sh:1752-1772,1859-1865`, `S/logs/blo.log`, `S/logs/probe.log`

---

## Claim 15: "A questions change while main has changed those files since BASE refuses (--check-answer reads the merge, where a free fence pair can capture main's newer answer): merge main into HEAD first."

**Location:** `scripts/build-loop.sh:200-203`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal and its recovery (merge main, then base = MAIN_SHA); does not establish the fence-capture mechanism itself (executed by i2 security F1, not re-run here).

See Claim 5. T38's last lines merge main and get `ok` (E2).

**Evidence:** `scripts/build-loop.sh:1830-1838`, `S/logs/blo.log`, `S/m-SN14/b.log`

---

## Claim 16: "docs/working/idea-log.md other than appended to (BASE's bytes start the index's)."

**Location:** `scripts/build-loop.sh:203-204`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a modified idea log; a new idea log is not judged (Claim 18) and a deleted one refuses.

```bash
# scripts/build-loop.sh:1823-1824
      k="$(wc -c < "$t.o")"
      [[ "$(wc -c < "$t.n")" -ge "$k" ]] && cmp -s -n "$k" "$t.o" "$t.n" || { echo "refuse $p: edited other than by appending"; bad=1; }
```
Test 24 (`s/i1/i0/` refused, an appended line passes; E2).

**Evidence:** `scripts/build-loop.sh:1821-1824`, `S/logs/blo.log`

---

## Claim 17: "docs/roadmap.md: ... (Done as dev-cycle.sh reads a section: "## Done", any case, alone or before a blank or "(")"

**Location:** `scripts/build-loop.sh:204-210`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three refusals and the Done match for a space or "(" after "## Done"; "a blank" is a space only: a tab after "## Done" makes the section not Done.

`index(d, "## done ") == 1 || index(d, "## done(") == 1` (:1781) tests a space, not a tab. E3 P3b: a base heading `## Done<TAB>(x)` is not Done, so dropping its brief line refuses ("the brief b.md, named outside Done on the base, is named on no line"). dev-cycle.sh's section rule behaves the same way, so the parenthetical holds and the failure is closed (a refusal). The precise version would say "before a space".

**Evidence:** `scripts/build-loop.sh:1779-1794`, `scripts/dev-cycle.sh:490`, `S/logs/probe.log`

---

## Claim 18: "A deletion, a side not a regular 100644 file, or a failed read refuses; a new roadmap or idea log, and every other path, is not judged."

**Location:** `scripts/build-loop.sh:210-212`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the roadmap and idea log (deletion refused, mode check, new file passes); a questions file's deletion is not refused as a deletion: it refuses only through its entries' key lines going away.

`if [[ "${RAW_S[i]}" == D ]]; then echo "refuse $p: the index deletes it"` (:1820) sits in the roadmap/idea-log loop; questions files `continue` before it (:1814). E3 P1a: deleting an entry-less questions.md → `ok`; P1b: moving the archive's only entry into questions.md and deleting the archive → `ok`. Neither changes what --check-answer reads, so nothing passes that the questions rule meant to stop; the sentence's placement after the roadmap text makes "A deletion" read as covering all three judged files.

**Evidence:** `scripts/build-loop.sh:1811-1829,1841-1858`, `S/logs/probe.log`

---

## Claim 19: "As --main-log, BASE's objects are not re-hashed: it catches the orchestrator's own slip, not a forged commit."

**Location:** `scripts/build-loop.sh:213-214`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which objects store_check re-hashes for this mode (MAIN_SHA's commit and tree only); does not establish that the index's blobs are re-hashed (they are not either).

state_start: `store_check --main "$MAIN_SHA"` (:1260); cycle_diff reads base and index blobs through `gate_git cat-file blob` / `ls-tree` (:1798-1801, :1835, :1847) with no store_check call.

**Evidence:** `scripts/build-loop.sh:1256-1262,1795-1866`

---

## Claim 20: Exit paragraph: "for --cycle-diff ok" (0), "a --cycle-diff refuse line" (2), "a failed mktemp (... --cycle-diff ...; no line printed)" (1)

**Location:** `scripts/build-loop.sh:452-462`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exit 0, 2 and usage 1 (executed by test 24) and mktemp 1 (static: `GATE_TMP="$(mktemp -d)"` under `set -e`); does not establish exits from a write failure inside cycle_diff (it runs in a `||` list, where set -e is off).

`cycle_diff || exit 2; echo ok` (:1883-1884); usage → exit 1 (test 24's three usage cases, E2).

**Evidence:** `scripts/build-loop.sh:452-462,1258,1882-1885`, `S/logs/blo.log`

---

## Claim 21: "raw_records FILE: ... Returns 1 when a record does not parse or lacks its path (a half record; bytes after the last NUL are not read ...). Fork-free: --main-log runs it per commit"

**Location:** `scripts/build-loop.sh:965-971`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers return codes, field order and the absence of a subshell or external command; does not establish the timing figure in ec9dace7 (Claim 42c).

```bash
# scripts/build-loop.sh:972-980
raw_records() {
  local meta p
  RAW_OM=(); RAW_NM=(); RAW_OO=(); RAW_NO=(); RAW_S=(); RAW_P=()
  while IFS= read -r -d '' meta; do
    IFS= read -r -d '' p || return 1
    [[ "$meta" =~ ^:([01234567]{6})\ ([01234567]{6})\ ([0123456789abcdef]+)\ ([0123456789abcdef]+)\ ([AMDT])$ ]] || return 1
    RAW_OM+=(...); ...; RAW_P+=("$p")
  done < "$1"
}
```
A trailing fragment without NUL makes `read` fail and ends the loop unread; the loop's status is then its last body command's (0). Only builtins and a redirect: no fork.

**Evidence:** `scripts/build-loop.sh:965-980`

---

## Claim 22: QKEYS_AWK comment: "per key line of an entry, as --check-answer delimits one ... Then "odd" or "unbalanced" when FENCE_AWK refuses the file."

**Location:** `scripts/build-loop.sh:1737-1741`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Same residue as Claim 13: "as --check-answer delimits one" does not cover ANSWER_AWK's quoted-heading whole-file skip; the odd/unbalanced END line is verified (test 22's `unbalanced 12`).

`END { if (odd) print "odd " odd " " oddwhy; else if (infence) print "unbalanced " fline }` (:1751).

**Evidence:** `scripts/build-loop.sh:1737-1751`, `S/logs/probe3.log`, `S/logs/blo.log`

---

## Claim 23: "An entry's key lines are compared in file order ... and without F, so an archive move is no change."

**Location:** `scripts/build-loop.sh:1752-1756`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a whole entry moving between files and in-entry order; does not establish order independence for an ID split across both files (the concatenation is questions.md then archive, so such a split can differ; --check-answer skips an ID found in both files anyway).

`o[id] = o[id] "\n" k l` / `nw[id] = nw[id] "\n" k l` (:1767-1768), with `$2` (F) kept only for the message. Test 22's swap refuses and its Q-003 archive move passes (E2).

**Evidence:** `scripts/build-loop.sh:1752-1772,1840-1858`, `S/logs/blo.log`

---

## Claim 24: ROADMAP_AWK comment: "A heading is Done as dev-cycle.sh reads its sections ("## Done", any case, alone or before a blank or "(")."

**Location:** `scripts/build-loop.sh:1773-1777`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 17: "a blank" is a space only.

See Claim 17 (E3 P3b).

**Evidence:** `scripts/build-loop.sh:1781`, `S/logs/probe.log`

---

## Claim 25: "cyc_blob MODE ID OUT: ... an absent side (MODE 000000) is an empty file. Returns non-zero when MODE is neither 000000 nor 100644 (a symlink, an executable), or the read fails."

**Location:** `scripts/build-loop.sh:1795-1797`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three mode cases; does not establish read-failure detection beyond gate_git's status-or-stderr rule.

```bash
# scripts/build-loop.sh:1798-1801
cyc_blob() {
  if [[ "$1" == 000000 ]]; then : > "$3"; return 0; fi
  [[ "$1" == 100644 ]] && gate_git cat-file blob "$2" > "$3"
}
```
Test 24's symlinked idea log refuses "a side is not a regular file (mode 100644)" (E2).

**Evidence:** `scripts/build-loop.sh:1795-1801,959-964`, `S/logs/blo.log`

---

## Claim 26: "The chore branch lands as a merge, and --check-answer reads the merged file: lines judged free here ... can capture an answer main gained since the fork ... So the questions files must be as on main"

**Location:** `scripts/build-loop.sh:1831-1834`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that the rule enforces "as on main" (ls-tree entries equal at base and MAIN_SHA) and that T38 needs it; the capture mechanism was executed by i2 security F1, not re-run here.

Equal ls-tree output for both paths at base and MAIN_SHA means the merge takes the index's copy unchanged. Mutant (b) (block deleted) fails T38 at the main-changed line (E6).

**Evidence:** `scripts/build-loop.sh:1830-1838`, `S/m-SN14/b.log`

---

## Claim 27: "Unchanged in the index: the base's copy on both sides; no entry, no copy (fact-check i2 claim 15: a failed read refuses)."

**Location:** `scripts/build-loop.sh:1846`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a failed ls-tree, an absent file and a failed or non-100644 read; does not establish a failed `cp` (unguarded, in a set -e-off context).

```bash
# scripts/build-loop.sh:1847-1850
      gate_git ls-tree -z "$base" -- "$f" > "$t.lt" || { echo "refuse $f: it could not be listed on the base"; return 1; }
      [[ -s "$t.lt" ]] || continue
      IFS=$' \t' read -r -d '' md _ id _ < "$t.lt" && cyc_blob "$md" "$id" "$t.o" || { echo "refuse $f: not a regular file (mode 100644) on the base, or could not be read"; return 1; }
      cp "$t.o" "$t.n"
```
(excerpt ends inside the loop; cycle_diff continues to :1866 — read).

**Evidence:** `scripts/build-loop.sh:1840-1858`

---

## Claim 28: "HEALTH_CHECK_LOCK_HELD When 1, takes no lock ... so a run it starts never waits on it. Not only a test seam: any caller setting it skips the lock."

**Location:** `scripts/health-check.sh:27-31`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the value 1 only (`!= 1`); other values take the lock.

`[[ "${HEALTH_CHECK_LOCK_HELD:-}" != 1 ]] || return 0` (:1106). T43 test 2's nested run with the lock held elsewhere does not wait (E1); without the line, T43 deadlocks (E7).

**Evidence:** `scripts/health-check.sh:1104-1119`, `S/logs/hcl.log`, `S/logs/mutants2.log`

---

## Claim 29: "flock(1) holds it and re-runs this script as its child with the descriptor closed (-o), so nothing a suite leaves running keeps it ... The child, and a run inside it (check 5 runs health-check.bats), get HEALTH_CHECK_LOCK_HELD=1 and take no lock."

**Location:** `scripts/health-check.sh:1096-1103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hold, the leftover-process case, exit passthrough and the nested run; does not establish behaviour when `$REPO_ROOT/scripts/health-check.sh` is not the script that ran (the re-run uses that path, not `$0`; REPO_ROOT is the script's own parent, :51).

T43 test 2's leftover `sleep 5` does not hold the lock (E1) and does on f34fceb0's `exec 8>>` version (E6 a, red at line 38). E4: a failing runner exits 1 through flock, both with no holder and after waiting. check 5 runs `--slow` (:402), and health-check.bats (`@category slow`) runs `bash "$SCRIPT"` (`test/scripts/health-check.bats:29`) with the exported variable inherited.

**Evidence:** `scripts/health-check.sh:51,386-402,1104-1119`, `test/scripts/health-check.bats:13-30`, `S/logs/hcl.log`, `S/m-SN14/a.log`, `S/logs/probe2.log`

---

## Claim 30: "-E 75 marks "held elsewhere" (this script exits 0 or 1)."

**Location:** `scripts/health-check.sh:1099-1100`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the script's explicit exits (`exit "$FAIL"`, FAIL 0 or 1; `exit 1`); does not hold for an unplanned failure under `set -euo pipefail` (:49), which exits with the failing command's status, so a child exiting 75 would be read as "held elsewhere" and re-run.

`fail() { ...; FAIL=1; }` (:70), `exit "$FAIL"` (:1148), `exit 1` (:1110); `set -euo pipefail` (:49). Precise version: "this script's own exits are 0 or 1".

**Evidence:** `scripts/health-check.sh:49,60,70,1110,1113-1118,1148`

---

## Claim 31: "Only a plain file is locked (a FIFO would block); outside a git repository there is nothing to share."

**Location:** `scripts/health-check.sh:1102-1103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a FIFO, a symlink (static) and a non-repo; does not cover a swap after the test (Claim 3).

T43's FIFO case exits 1 with "not a plain file" (E1); `flock -n` on a FIFO blocks (E7); E4 case 2: outside a repo the script ran its checks with no lock file.

**Evidence:** `scripts/health-check.sh:1107-1111`, `S/logs/hcl.log`, `S/logs/probe2.log`, `S/logs/mutants2.log`

---

## Claim 32: "build-loop.sh's ANSWERS_AWK ..., QKEYS_AWK and QDIFF_AWK (--cycle-diff: also this heading rule and entry end) copy these labels and the header line's Status field ... build-loop-orchestrator.bats checks the label regex"

**Location:** `scripts/lib/dev-cycle-read.sh:2055-2059`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the label regex in three readers and the Status rule in QDIFF_AWK (a superset: any field of any Needs line); does not establish that the `Q-NNN:` label or the Status rule is pinned by a test (only the bold-label regex is).

`grep -nF '/^\*\*answer(:|ed| \()/'` finds lib :2097, build-loop.sh :1657 (ANSWERS_AWK) and :1750 (QKEYS_AWK). Test 23 passes (E2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2097`, `scripts/build-loop.sh:1657,1750,1759-1764`, `S/logs/blo.log`

---

## Claim 33: test 22's name and comments ("refuses an entry's header or answer changed or gone without --answered, and passes body edits, an open new entry and an archive move"; the case comments)

**Location:** `test/scripts/build-loop-orchestrator.bats:400-431`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name, the `cd_is`/`onmain`/`qa` helper comments and the case comments but :427's (Claim 34).

Each comment's case is asserted by a `cd_is` line (read in full); the test passes (E2).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:390-431`, `S/logs/blo.log`

---

## Claim 34: "A user's answer on main meanwhile: the merge could fence it off (i2 security F1), so main is merged first."

**Location:** `test/scripts/build-loop-orchestrator.bats:427`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal the case asserts; the fixture's main change is not an answer.

`onmain docs/working/questions.md "# Q"` replaces main's questions.md with one line, deleting its entries; the assertion holds for any change, so the case tests the rule, but the comment's "a user's answer" describes the motive, not the fixture.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:427-429`

---

## Claim 35: "the answer label regex is the same in the lib's ANSWER_AWK, ANSWERS_AWK and QKEYS_AWK"

**Location:** `test/scripts/build-loop-orchestrator.bats:432`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the current files; the assertion counts occurrences per file (1 in the lib, 2 in build-loop.sh), so it would not catch a copy moved from one build-loop.sh reader to another.

`[ "$(grep -cF "$r" ".../dev-cycle-read.sh")" -eq 1 ] && [ "$(grep -cF "$r" "$BL")" -eq 2 ]`; the two build-loop.sh hits are ANSWERS_AWK and QKEYS_AWK (Claim 32).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:432-435`, `S/logs/blo.log`

---

## Claim 36: test 24's name and comments (roadmap preamble, heading, dropped brief, idea-log edit refused; "Step 6's rewrites ... pass"; "No merge base; usage.")

**Location:** `test/scripts/build-loop-orchestrator.bats:437-456`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named case; the "X moved to Done at closed/" line is appended at the file's end, which is inside `## Done (last cycle)`.

Test passes (E2).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:437-456`, `S/logs/blo.log`

---

## Claim 37: health-check-lock.bats header ("copies the script and the libs it sources ... with check 5's runner stubbed, so no real suite runs") and its two test names

**Location:** `test/scripts/health-check-lock.bats:1-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the copied libs (health-check.sh sources exactly log-format, md-utils and skill-paths, :63-67) and both names; the "says it waits" check accepts the line in either run's output.

Both pass (E1); with no `take_lock` call both fail (E7).

**Evidence:** `test/scripts/health-check-lock.bats:1-42`, `scripts/health-check.sh:63-67`, `S/logs/hcl.log`, `S/m2-iiWd/nolock.log`

---

## Claim 38: 3021d0a4 body (the case list and "mutants run: base = MAIN_SHA fails T38 at the main-moved line; no take_lock and no nested-run exemption each fail T43")

**Location:** `3021d0a4 (commit message)`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Re-run on HEAD's tests, not 3021d0a4's; "fail" for the exemption mutant is a deadlock (bats killed by timeout), not an assertion failure.

E7: base mutant fails at `onmain docs/roadmap.md "# R"; cd_is ok --answered Q-001`; no take_lock fails both T43 tests; no exemption times out at 300 s.

**Evidence:** `S/logs/mutants2.log`, `S/m2-iiWd/base.log`, `S/m2-iiWd/nolock.log`

---

## Claim 39: f34fceb0 body (the --cycle-diff rules, raw_records' four users, the flock, the interim readings, row 722 re-keyed)

**Location:** `f34fceb0 (commit message)`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Checked against HEAD; the body predates the main-changed rule and the take_lock rework, which it does not mention.

As Claims 1, 5-10, 14 and 21 (E1-E3).

**Evidence:** `scripts/build-loop.sh:965-980,1803-1866`, `scripts/health-check.sh:1104-1119`

---

## Claim 40: 414c9295 body ("With exec 8>> every suite and any process a test left running inherited the lock's descriptor ... T43 gains the leftover-process case (red on the exec version)")

**Location:** `414c9295 (commit message)`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the red-on-old claim with HEAD's T43 run against f34fceb0's health-check.sh.

E6 (a): test 2 fails at line 38 (`[[ "$output" != *waiting* ]] && grep -qx "out q"`), the run printing "waiting for another health check".

**Evidence:** `S/m-SN14/a.log`, `S/logs/mutants.log`

---

## Claim 41a: d77dae74 A1 ("Sorting each side's key lines lost their order ... The sides are now compared as read ... T38 gains the swap and a deleted-entry case")

**Location:** `d77dae74 (commit message)`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file-order comparison and the two cases; does not cover A6 (Claim 41b).

QDIFF_AWK concatenates in read order (:1767-1768); test 22's swap and deleted-entry lines pass (E2).

**Evidence:** `scripts/build-loop.sh:1758-1772`, `S/logs/blo.log`

---

## Claim 41b: "A6 (QKEYS_AWK lacks ANSWER_AWK's whole-file refusals) left as is: it fails safe."

**Location:** `d77dae74 (commit message)`
**Type:** Error-handling / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quoted-heading refusal on the base side; it holds on the index side (an index copy --check-answer skips passes --cycle-diff but unblocks nothing), and the dup case is caught by key lines.

When the base copy is one --check-answer skips as "quoted" and the index removes the fenced heading block, --cycle-diff prints `ok` and --check-answer moves from skip to `keep` for an entry not in --answered (E5 P5; see Claim 13). The missing refusal can therefore unblock `--approved`/`Asked:` for an answer the reader had refused to trust. The answer line itself was already on the base, which limits the impact.

**Evidence:** `scripts/lib/dev-cycle-read.sh:2082,2111`, `scripts/build-loop.sh:1743-1751`, `S/logs/probe3.log`

---

## Claim 42a: ec9dace7 B1 ("A questions change now refuses while main's questions files differ from the fork point's (an ls-tree comparison in the gate repository ...) ... T38 case; red without the rule") and B2-B5, B7-B10

**Location:** `ec9dace7 (commit message)`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers B1-B5 and B7-B10 as they read at HEAD; B6's figure and the diff-tree aside are Claims 42b-42c.

Mutant (b) red (E6); B3/B4 Claims 25, 27; B5 Claim 4; B8 HEALTH_CHECK_LOCK_HELD `!= 1`.

**Evidence:** `S/m-SN14/b.log`, `scripts/build-loop.sh:1795-1858`

---

## Claim 42b: "(... diff-tree's pathspec misread there)"

**Location:** `ec9dace7 (commit message)`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Scope:** A rationale aside; the failing invocation is not recorded, so it could not be reproduced.

E4 case 3: in a gate-like repository (GIT_DIR with no work tree, cwd an empty dir, GIT_OBJECT_DIRECTORY set; also with GIT_LITERAL_PATHSPECS=1), `git diff-tree -r ... A B -- docs/working/questions.md` listed the path correctly on git 2.39.5. Needed: the exact diff-tree command that misread.

**Evidence:** `S/logs/probe2.log`

---

## Claim 42c: "B6 (performance 1): raw_records is fork-free (--main-log over 1,100 commits had grown 4.3 s)"

**Location:** `ec9dace7 (commit message)`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** "Fork-free" is verified (Claim 21); the 4.3 s figure is a past measurement not re-run.

Needed: timing --main-log over a 1,100-commit history on the f34fceb0 and HEAD readers.

**Evidence:** `scripts/build-loop.sh:965-980`

---

## Claim 42d: "plan lines 104/209 ... unit at 386 code lines after compressing two comment blocks"

**Location:** `ec9dace7 (commit message)`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Counts added plus deleted lines outside docs/ against main, per decision-log row 62.

`git diff --numstat main...ec9dace7 -- . ':!docs'` sums to 355 + 31 = 386; plan :104 and :209 are the two changed bullets.

**Evidence:** `docs/working/plan-build-loop-handoff.md:104,209`, `docs/decisions/log.md:85`

---

## Claims Requiring Attention

### Incorrect
- **Claim 41b** (`d77dae74` message): "A6 ... it fails safe" is false on the base side. A base questions file that --check-answer skips as "quoted" can be made readable in the index with no key-line change, and an existing answer then reads `keep` with no --answered (E5).

### Stale
- (none)

### Mostly Accurate
- **Claim 8** (`docs/working/plan-build-loop-handoff.md:330`): "as --check-answer delimits it" leaves out the quoted-heading whole-file skip.
- **Claim 13** (`scripts/build-loop.sh:191-193`): same residue as Claim 8: name the exception, or refuse a fenced `### Q-` heading in either copy.
- **Claim 17** (`scripts/build-loop.sh:204-210`): "before a blank" means a space only; a tab after "## Done" is not Done (fails closed).
- **Claim 18** (`scripts/build-loop.sh:210-212`): "A deletion ... refuses" covers the roadmap and idea log; a questions file's deletion is judged only through its entries.
- **Claim 22** (`scripts/build-loop.sh:1737-1741`): QKEYS_AWK's "as --check-answer delimits one", same residue as Claim 13.
- **Claim 24** (`scripts/build-loop.sh:1773-1777`): "a blank" means a space only, as Claim 17.
- **Claim 30** (`scripts/health-check.sh:1099-1100`): "this script exits 0 or 1" holds for its own exits only; under `set -e` an unplanned failure can exit with other codes, including 75.
- **Claim 34** (`test/scripts/build-loop-orchestrator.bats:427`): the fixture plants "# Q" on main, not an answer.

### Unverifiable
- **Claim 42b** (`ec9dace7` message): needs the diff-tree invocation that misread in the gate repository.
- **Claim 42c** (`ec9dace7` message): needs a timing run of --main-log over ~1,100 commits on the old and new readers.

## Escalations

1. **E-1 (Claim 41b/13, executed):** a base questions file that --check-answer skips as "quoted" (a `### Q-` heading inside a fence) can be made readable by the chore index without touching a key line. --cycle-diff passes, and after the land `--check-answer Q-001` reads `keep` where it read skip on main. The answer text was already on main, so this is not a fabricated answer. It is a skip turned into an actionable `keep`, which would unblock `--approved` or a brief's `Asked:` with no --answered. QKEYS_AWK could emit a refusal line for a fenced `### Q-` heading as ANSWER_AWK does, or the docs could name the exception. Severity is for the panel to judge; no live questions file has such a heading (the lib's comment says so).
2. **E-2 (minor wording):** Claims 17/24 (tab after "## Done") and 18 (deletion scope) both fail closed or are harmless; they are listed for wording only.

**Goal-alignment note.** The branch does what the brief's goal states. Both interim calls hold under execution: the fork-point base (Claim 7; a MAIN_SHA base fails T38 at the main-moved line) and the roadmap's "moves" reading (Claims 9, 17). The iteration-2 main-changed rule is necessary and works (Claims 5, 26; red without it). raw_records matches the old readers except for the chore-loop change the override row records. The health-check lock serializes, passes exit status through, and is not kept alive by leftover processes (Claims 28-31). One gap is outside what the docs claim: E-1, the "quoted" base-file case.
