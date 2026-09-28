Commit: 12f96cd

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q065 (branch review/q065)
**Scope:** `git diff main...HEAD` (main = 6405e43, HEAD = 12f96cd), full branch, including the 12f96cd commit message; plus live references to the deleted symbol and test file across the repo at HEAD
**Checked:** 2026-09-28
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 8
**Summary:** 7 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read; no claim below matches a logged pattern.

---

## Claim 1: "prepend_si_input_rejected_history had no caller since it landed in 06903d6."

**Location:** commit 12f96cd message, line 3
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every commit on every ref that ever added or removed the string `prepend_si_input_rejected_history` (pickaxe `git log --all -S`) and a HEAD/main grep of scripts, tests, hooks, skills and devcontainer-config; does not establish that no user ever sourced the library and called it by hand outside the repo.

06903d6 introduced only the function and its tests, no call site:

```
06903d6 2026-05-19 feat(si-input): prepend recent-rejections HTML-comment block to si-input.md
 scripts/lib/si-input.sh             | 114 +++++++++++++++++++++
 test/si-input-rejected-history.bats | 191 ++++++++++++++++++++++++++++++++++++
```

Every other commit touching the symbol (`git log --all -S prepend_si_input_rejected_history`: b1780ac, 0b1ebf4, add8f2c, 11b79c6, 48bca90, 12f96cd) changes only `docs/working/*` prose or deletes the function (paraphrased — no quote available because the claim covers absence of code: each commit's `git show | grep` hit is in an audit/questions doc line, e.g. b1780ac `docs/working/audit-test-constraint-2026-09-26.md:61`). At main, the only non-test hits are the definition and its header entry:

```
main:scripts/lib/si-input.sh:12:#   prepend_si_input_rejected_history — New-cycle bootstrap: prepend an
main:scripts/lib/si-input.sh:214:prepend_si_input_rejected_history() {
```

The only production consumer of the library, `scripts/self-improvement.sh`, sources it and calls `parse_si_input` only:

```
scripts/self-improvement.sh:231:source "$SCRIPT_DIR/lib/si-input.sh"
scripts/self-improvement.sh:493:parse_si_input "$WORKING_DIR/si-input.md" || true
```

No dynamic construction (`prepend_si*`, `rejected_history`) exists in scripts/test/hooks/skills at main (paraphrased — no quote available because the grep returned no matches outside the two lines above).

**Evidence:** `scripts/self-improvement.sh:231`, `scripts/self-improvement.sh:493`, `main:scripts/lib/si-input.sh:12`, `main:scripts/lib/si-input.sh:214`, git show --stat 06903d6

---

## Claim 2: "Its 12 tests exercised only that function"

**Location:** commit 12f96cd message, line 4
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the count (14 `@test` blocks − 2 moved = 12 deleted) and which functions each deleted test calls; does not establish whether the lost assertion is otherwise covered by suites outside `test/` or by the moved tests' fixtures beyond what is quoted.

The count is right: `grep -c '^@test'` on `main:test/si-input-rejected-history.bats` returns `14`, and 2 moved. But one of the 12 deleted tests also exercised `parse_si_input` and asserted its behaviour on an HTML-comment block placed *before the first `##` heading*:

```bash
# main:test/si-input-rejected-history.bats:178-188 (diff lines 355-365)
@test "comment block does not pollute parsed sections" {
  ...
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"

  parse_si_input "$INPUT_FILE"
  [[ "$SI_FEEDBACK" == *"the real feedback"* ]]
  [[ "$SI_FEEDBACK" != *"task-foo"* ]]
  [[ "$SI_PRIORITIES" == *"priority one"* ]]
  [[ "$SI_PRIORITIES" != *"Recent rejections"* ]]
}
```

(excerpt elides lines 2-4 of the test body — the fixture writes; test ends at the closing brace shown — read.)

Neither moved test places a comment before the first `##` heading; both put comments inside a section (paraphrased — no quote available because the claim is about fixture layout; see the two `printf` fixtures at `test/si-input-parse-comments.bats:18` and `:28`). The only other suite touching `parse_si_input` is `test/function-inventory.bats`, which checks existence only (`test/function-inventory.bats:52-53`: `[ "$(type -t parse_si_input)" = "function" ]`). Precise version: "11 of the 12 exercised only that function; the 12th also checked that `parse_si_input` discards a pre-heading comment preamble, which no remaining test covers."

**Evidence:** `main:test/si-input-rejected-history.bats:178-188`, `test/si-input-parse-comments.bats:17-33`, `test/function-inventory.bats:52-53`

---

## Claim 3: "the two parse_si_input comment-handling tests move to test/si-input-parse-comments.bats"

**Location:** commit 12f96cd message, lines 4-6
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers byte-identity of the two `@test` blocks and their passing under the project runner, and that the dropped `bats_require_minimum_version 1.5.0`, `WORKING_DIR`, and helpers were not needed by them; does not establish behaviour under a bats older than the one in the sandbox.

Byte comparison of the old file's tail from `@test "parse_si_input drops` to EOF against the new file's same range: `cmp` exit 0 (`BYTE-IDENTICAL`). The new `setup()` keeps what the moved tests use:

```bash
# test/si-input-parse-comments.bats:7-11
setup() {
  source "$BATS_TEST_DIRNAME/../scripts/lib/si-input.sh"
  TEST_TMPDIR=$(mktemp -d)
  INPUT_FILE="$TEST_TMPDIR/si-input.md"
}
```

Neither moved test uses `run !` / `run -N` (grep for `run \(!\|-[0-9]\)` exit 1), so dropping `bats_require_minimum_version 1.5.0` loses nothing; neither references `WORKING_DIR`, `write_round_report`, `rejected_entry`, or `merge_validations` (paraphrased — no quote available because the claim covers absence of references in the 17-line test bodies quoted in the diff).

Execution: command `./scripts/run-tests.sh test/si-input-parse-comments.bats`, cwd `/workspace/.claude/wt-q065`, exit 0, 2026-09-28T21:24:31Z; output `ok 1 parse_si_input drops the middle lines of a multi-line HTML comment` / `ok 2 parse_si_input keeps a heading that carries a trailing inline comment`.

**Evidence:** `test/si-input-parse-comments.bats:7-33`, `main:test/si-input-rejected-history.bats:198-214`, /home/node/.claude/jobs/9f431b13/tmp/q065-fc-parse-comments.log, /home/node/.claude/jobs/9f431b13/tmp/q065-fc-oldtail.txt, /home/node/.claude/jobs/9f431b13/tmp/q065-fc-newtail.txt

---

## Claim 4: "The rejected-history preamble never appeared in a real run, so no behaviour changes."

**Location:** commit 12f96cd message, lines 9-10
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every in-repo code path (no caller has ever existed, Claim 1) and the surviving library functions still sourcing and working (sibling suites executed); does not establish that no human ran the function manually, nor inspect past `si-input.md` files from real runs.

Because no script ever called the function (Claim 1), no self-improvement run could produce the block. The deletion removes only the function body and its header entry; `parse_si_input`, `_save_si_section`, `parse_si_priority_hypotheses`, and `_trim_blank_lines` are unchanged context in the diff (paraphrased — no quote available because the claim is about the diff's hunks: the only `-` lines in `scripts/lib/si-input.sh` are header lines 12-14 and the function block main:199-310). Sibling suites that source the library still pass: `./scripts/run-tests.sh test/function-inventory.bats test/parse-si-priority-hypotheses.bats`, cwd `/workspace/.claude/wt-q065`, exit 0, 2026-09-28 (~21:25Z), 20 `ok`, 0 `not ok`.

**Evidence:** `scripts/self-improvement.sh:493`, `scripts/lib/si-input.sh:1-204`, /home/node/.claude/jobs/9f431b13/tmp/q065-fc-siblings.log

---

## Claim 5: "Sourced by scripts/self-improvement.sh — do not execute directly." / Functions list

**Location:** `scripts/lib/si-input.sh:6-11`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the sourcing site and that the Functions list names exactly the two public functions left in the file; does not establish that self-improvement.sh is the only sourcer (tests source it directly, as before the change).

```bash
# scripts/lib/si-input.sh:6-11
# Sourced by scripts/self-improvement.sh — do not execute directly.
#
# Functions:
#   parse_si_input — Parse si-input.md and export section variables
#   parse_si_priority_hypotheses — Extract user-supplied (priority, hypothesis)
#       pre-commitment pairs from SI_PRIORITIES; emits JSON to stdout
```

Sourcing site: `scripts/self-improvement.sh:231: source "$SCRIPT_DIR/lib/si-input.sh"`. Remaining top-level function definitions are `parse_si_input` (:26), `_save_si_section` (:103), `parse_si_priority_hypotheses` (:135), `_trim_blank_lines` (:197); the two `_`-prefixed internals were never in the list. No remaining comment in the file mentions rejections or the deleted function (paraphrased — no quote available because the claim covers absence: the post-change file quoted in full in the shared context has no such text).

**Evidence:** `scripts/lib/si-input.sh:6-11`, `scripts/lib/si-input.sh:26`, `scripts/lib/si-input.sh:135`, `scripts/self-improvement.sh:231`

---

## Claim 6: "# @category fast" / "Moved from si-input-rejected-history.bats when its subject, prepend_si_input_rejected_history, was deleted (Q-065 [1])."

**Location:** `test/si-input-parse-comments.bats:2-5`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the runner's tag extraction accepting the file and the provenance statement; does not establish the health-check's full fast-suite run (not executed here) beyond the shared `collect_tests` path.

The runner reads the first `# @category` line and errors on untagged files:

```bash
# scripts/run-tests.sh:230
    tag=$(grep -m1 '^# @category ' "$file" 2>/dev/null | sed 's/^# @category //' || true)
```

(excerpt ends :230; enclosing `collect_tests()` continues to :250 — read: untagged files fail with `ERROR: no "# @category fast|slow" tag`.) The run in Claim 3 collected and executed the file with exit 0, so the tag parsed. Test discovery is by glob over candidates, with no hard-coded file manifest: `grep` for `si-input-parse-comments`/`si-input-rejected` in `scripts`, `test`, Makefile/json/yml/txt at HEAD hits only historical execution logs under `docs/reviews/execution-logs/` (paraphrased — no quote available because the claim covers absence of a manifest entry). The provenance sentence matches the diff (the file is new, and its two tests are byte-identical to the deleted file's last two; Claim 3).

**Evidence:** `scripts/run-tests.sh:222-250`, `test/si-input-parse-comments.bats:2-5`, /home/node/.claude/jobs/9f431b13/tmp/q065-fc-parse-comments.log

---

## Claim 7: No live reference to the deleted function or deleted test file remains (PR intent, preamble item 6)

**Location:** repo-wide at HEAD (`git grep` for `prepend_si_input_rejected_history`, `si-input-rejected-history`, `Recent rejections`, `rejected.history`)
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers code, tests, runner config, and the si-morning-summary comment; does not establish freshness of working-doc ledgers, which are historical records (see note below and Claim 8).

Remaining hits at HEAD are: `archive/…` (excluded), `docs/reviews/execution-logs/*` (historical run logs), `docs/decisions/log.md:80` (a dated decision row recording that Q-065 was live on 2026-09-27), `docs/working/audit-test-constraint-2026-09-26.md:68,142` (a closed dated ledger), `docs/working/questions.md:28,49-63` (the Q-065 entry, still `**Status:** OPEN` on this branch and citing `scripts/lib/si-input.sh:214`, which no longer exists), and the new test's own header. The one code hit is unrelated:

```bash
# scripts/lib/si-morning-summary.sh:296
#   - Recent rejections grouped by failing gate (from round reports)
```

This describes `_summary_project_state`'s rejections subsection in the morning summary, not the deleted si-input preamble (paraphrased — no quote available because the distinction rests on the enclosing comment block at :292-299 naming `_summary_project_state`). The questions.md entry is answered on `answers-2026-09-28` (Claim 8), so on this branch it is an un-merged bookkeeping lag, not a live code reference.

**Evidence:** `scripts/lib/si-morning-summary.sh:292-300`, `docs/working/questions.md:49-63`, `docs/decisions/log.md:80`, `docs/working/audit-test-constraint-2026-09-26.md:68`

---

## Claim 8: "Answered 2026-09-28: [1] delete. Done in 11b79c6" (answer record for this change, on the parent branch)

**Location:** `answers-2026-09-28:docs/working/questions.md:1513`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that 11b79c6 exists and carries the same change as 12f96cd; does not establish which of the two hashes will reach `main`, so the record's hash may go stale depending on merge path.

11b79c6 and 12f96cd have identical `+`/`-` diff lines (`diff` of the two patches → `SAME-CHANGE`) and the same stat (`3 files changed, 33 insertions(+), 328 deletions(-)`). `git branch --contains 11b79c6` returns only `answers-2026-09-28`; the reviewed branch carries the change as 12f96cd on base 6405e43. If review/q065 merges to main and answers-2026-09-28's 11b79c6 does not, the "Done in 11b79c6" pointer names a commit that is not on main.

**Evidence:** `answers-2026-09-28:docs/working/questions.md:1510-1515`, /home/node/.claude/jobs/9f431b13/tmp/q065-fc-a.diff, /home/node/.claude/jobs/9f431b13/tmp/q065-fc-b.diff

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 2** (commit 12f96cd message, line 4): 11 of the 12 deleted tests exercised only the deleted function; "comment block does not pollute parsed sections" also asserted that `parse_si_input` discards a pre-heading HTML-comment preamble, and no remaining test covers that case. Tighten the message, or keep a parse-only version of that assertion in `test/si-input-parse-comments.bats`.

### Unverifiable
(none)

---

## Goal-Alignment Note

- **Answered:** All six preamble claim areas: no caller ever (Claim 1), the 12-test/2-moved split (Claims 2-3, with byte-identity and an executed pass), no behaviour change (Claim 4), the si-input.sh header (Claim 5), the new file's category/provenance and runner pickup (Claim 6), and live leftover references (Claim 7).
- **Out of scope:** I did not run the full health-check or fast suite, only the new file and the two sibling suites that source the library. I did not check test-count figures in archive docs (excluded by the brief).
- **Escalate:** (a) For the orchestrator/merge step: the answer record on `answers-2026-09-28` cites 11b79c6, but this branch lands the same change as 12f96cd (Claim 8). Whichever hash reaches main should be the one cited. The Q-065 entry on this branch still says OPEN and points at the deleted `si-input.sh:214` (Claim 7), which fixes itself once the answers branch merges. (b) For test-strategy/code-review synthesis: the pre-heading comment-preamble case of `parse_si_input` lost its only assertion (Claim 2). That is a coverage question, not a doc-accuracy one.
