Commit: 0304a2c

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q065 (branch review/q065)
**Scope:** Submitted claims only (Stage 2.5, final confirming pass), against `git diff main...HEAD` at HEAD 0304a2c. No claims were harvested from the diff; the canonical report (`docs/reviews/q065-code-fact-check-report.md`) ends at Claim 20.
**Checked:** 2026-09-28
**Replication:** k=1
**Total claims checked:** 4 (S1, S2, S3 split into 23a/23b)
**Summary:** 3 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log considered: no submitted claim names a symbol, API or measured value that does not exist; none matches a logged pattern.

Execution provenance (S3 only): script run at 2026-09-28T14:51:44-07:00 to 14:52:52-07:00, cwd `/home/node/.claude/jobs/9f431b13/tmp/q065-sc-s3` (a scratch dir holding `main:test/si-input-rejected-history.bats`, `HEAD:test/si-input-parse-comments.bats`, and `main:scripts/lib/si-input.sh` at `scripts/lib/`, plus a counting `jq` shim on PATH for one run). Commands: `PATH=<shim>:$PATH timeout 120 bats test/si-input-rejected-history.bats` (exit 0, 14/14 ok), then five timed runs each of `timeout 120 bats test/si-input-rejected-history.bats` and `timeout 120 bats test/si-input-parse-comments.bats` (all exit 0). Bats 1.8.2. Captured output: `/home/node/.claude/jobs/9f431b13/tmp/q065-sc-s3-exec.log`. The scratch dir was deleted afterwards; no bats process remains.

---

## Submitted Claims

## Claim 21: "The diff removes every temp-file+rename and jq-over-report call site in scripts/lib/si-input.sh and adds no new write, exec or eval."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/si-input.sh:1-204` (post-change), `main:scripts/lib/si-input.sh:199-308` (deleted block)
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the in-repo `scripts/lib/si-input.sh` at HEAD versus main: the only `mktemp`, `mv` and report-reading `jq` in the file were in the deleted function, and the diff adds zero lines to the file; does not establish anything about installed copies outside the repo (e.g. `~/.claude/scripts/lib/si-input.sh`, which still carries the old function), nor about other files that write `si-input.md`.
**Legibility-target:** for-orchestrator-synthesis

On main, the temp-file+rename and the report-reading `jq` live only inside the deleted function:

```bash
# main:scripts/lib/si-input.sh:250,256 (inside prepend_si_input_rejected_history, :214-308 — read)
        round_rows=$(jq -r --arg round "$round" '
        ' "$report" 2>/dev/null) || round_rows=""
# main:scripts/lib/si-input.sh:284-285,305
    tmpfile=$(mktemp "${input_file}.XXXXXX")
    printf '%s' "$block" > "$tmpfile"
    mv "$tmpfile" "$input_file"
```

At HEAD, a grep for `mktemp|mv|jq|eval|exec|report|>>` finds only the `parse_si_priority_hypotheses` comment and its stdin-fed `jq`, which reads awk output, not a report file:

```bash
# scripts/lib/si-input.sh:189
    printf '%s\n' "$pairs" | jq -R -s '
```
(excerpt ends :189; enclosing parse_si_priority_hypotheses() runs :135-194 — read; `$pairs` comes from awk over `$priorities_text` at :146-182)

`git diff --numstat main...HEAD -- scripts/lib/si-input.sh` prints `0	114`: no lines added.

**Evidence:** `scripts/lib/si-input.sh:135-194`, `main:scripts/lib/si-input.sh:199-308`, `git diff --numstat main...HEAD -- scripts/lib/si-input.sh`

---

## Claim 22: "The deleted function had no committed caller, so removing it changes no runtime write to si-input.md."

**Submitted by:** security-reviewer
**Location:** `scripts/self-improvement.sh:490-499`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every committed revision in `git log --all` (every commit that changed the symbol's count, 06903d6 onward, shows it only in `scripts/lib/si-input.sh`, the two test files and docs) and the installed `~/.claude/scripts/` tree (definition only, no caller); does not establish that no one invoked it by hand or from an uncommitted script, and does not cover other code paths that write `si-input.md`.
**Legibility-target:** for-orchestrator-synthesis

The self-improvement loop only reads `si-input.md` at this point; nothing between parse and prompt-building calls the helper:

```bash
# scripts/self-improvement.sh:489-499
# --- Pre-run input ---
# Parse user feedback, priorities, and constraints from si-input.md.
# Variables SI_FEEDBACK, SI_PRIORITIES, SI_OFF_LIMITS, SI_CONTEXT are set
# (empty strings if file is missing or sections are blank).
parse_si_input "$WORKING_DIR/si-input.md" || true

# Decision 012 pillar 3: pre-commitment hypotheses attached to priorities.
...
SI_PRIORITY_HYPOTHESES_JSON=$(parse_si_priority_hypotheses)
```

`git grep -n prepend_si_input_rejected_history main` hits only the library definition (`main:scripts/lib/si-input.sh:12,214`), `main:test/si-input-rejected-history.bats` and two docs/working ledgers (paraphrased — no quote available because the claim covers absence of code: no matching grep results outside those files). Iterating `git grep -l` over every commit returned by `git log --all -S prepend_si_input_rejected_history` (outside `docs/` and `archive/`) lists only `scripts/lib/si-input.sh`, `test/si-input-rejected-history.bats` and `test/si-input-parse-comments.bats` (the last a header comment naming the deleted function). `grep -rn prepend_si_input ~/.claude/scripts` hits only the installed library's definition lines 12 and 214.

**Evidence:** `scripts/self-improvement.sh:489-499`, `main:scripts/lib/si-input.sh:214`, `test/si-input-parse-comments.bats:6`

---

## Claim 23a: "Deleting the 12 helper tests makes the fast suite faster"

**Submitted by:** performance-reviewer
**Location:** `main:test/si-input-rejected-history.bats`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers wall time of the deleted file (14 tests) versus its replacement `test/si-input-parse-comments.bats` (3 tests), run serially under bats 1.8.2 in this sandbox: median 8.44 s versus 1.85 s over 5 runs each, about 6.6 s less; does not establish the saving under `bats --jobs` parallelism or on other hosts, or the effect on total fast-suite wall time when run through `scripts/run-tests.sh`.
**Legibility-target:** for-orchestrator-synthesis

Both files carry `# @category fast` (`main:test/si-input-rejected-history.bats:2`, `test/si-input-parse-comments.bats:2`). Measured (from the captured log):

```
old-file runs: 8.439 8.828 8.406 11.771 7.772 s   (median 8.439)
new-file runs: 1.486 1.849 2.278 1.790 2.090 s    (median 1.849)
```

**Evidence:** `main:test/si-input-rejected-history.bats:1-214`, `test/si-input-parse-comments.bats:1-3`, `/home/node/.claude/jobs/9f431b13/tmp/q065-sc-s3-exec.log`

---

## Claim 23b: "since each of them called jq several times"

**Submitted by:** performance-reviewer
**Location:** `main:test/si-input-rejected-history.bats:27-51`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of `jq` invocations per test (via a PATH shim logging `$BATS_TEST_NAME`): 10 of the 12 helper tests called `jq` 2 to 13 times (41 calls in all), and the two "no round reports" tests called it zero times; does not establish how much of the measured saving is due to `jq` rather than per-test bats overhead (the zero-`jq` tests were not timed separately).
**Legibility-target:** for-orchestrator-synthesis

Precise version: "10 of the 12 called `jq` 2-13 times; the two no-reports tests called none." The jq calls come from the test helpers and the function under test:

```bash
# main:test/si-input-rejected-history.bats:32-34
  jq -n --argjson v "$validation_json" \
    --argjson r "$round" \
    '{round: $r, validation: $v}' > "$path"
```
(excerpt ends :34; enclosing write_round_report() continues to :35 — read)

The zero-call tests call only the function, which returns before any `jq` when no reports exist:

```bash
# main:test/si-input-rejected-history.bats:55-58
@test "no round reports: file is left alone (or absent stays absent)" {
  prepend_si_input_rejected_history "$INPUT_FILE" "$WORKING_DIR"
  [ ! -f "$INPUT_FILE" ]
}
```

Shim counts per test (from the captured log): spans-many-rounds 13, replaces-prior-block 7, multiple-rejections 5, idempotent 4, reports-but-no-rejections 2, and 3 each for the other five; no entries for the two "no round reports" tests.

**Evidence:** `main:test/si-input-rejected-history.bats:27-51`, `main:test/si-input-rejected-history.bats:55-66`, `main:scripts/lib/si-input.sh:236-238`, `/home/node/.claude/jobs/9f431b13/tmp/q065-sc-s3-exec.log`

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 23b** (`main:test/si-input-rejected-history.bats:27-51`): "each called jq several times" overstates it; 10 of 12 did (2-13 calls), the two no-reports tests called none. The conclusion (Claim 23a) holds.

## Goal-Alignment Note
- **Answered:** All three submitted claims got a verdict: S1 Verified (Claim 21), S2 Verified (Claim 22), S3 split into 23a Verified (executed timing) and 23b Mostly accurate (executed jq count).
- **Out of scope:** Harvesting new claims from the diff; the installed copy under `~/.claude/scripts/` (noted in the Scope lines, not verdicted); how much of the S3 saving comes from jq rather than bats per-test overhead.
- **Escalate:** None. The 23b imprecision is in a critic's endorsement, not in branch content, so nothing on the branch needs fixing.
