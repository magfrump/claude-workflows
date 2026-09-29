# Performance Review — branch q093-cc-push-self-commondir

**Scope:** `git diff dfe4c0d..HEAD` (`devcontainer-config/cc-push.sh`, `test/cc-push.bats`, `guides/cc-isolated-usage.md`, `docs/working/plan-q093-cc-push-self-commondir.md`)
**Date:** 2026-09-28
**Based on:** `docs/reviews/q093-code-fact-check-report.md` (18 claims; E1-E4 executed runs)

## Data Flow and Hot Paths

`cc-push` is a host CLI run by hand, once per push. `main` calls `check_checkout "$co"` exactly once (`cc-push.sh:389`), after `check_no_container`. The new helper `commondir_is_self` is called from one place, the `commondir` test in `check_checkout` (`cc-push.sh:294`), and only when `.git/commondir` exists. It runs three stat-only tests, then `stat`, then `head -c 2 | od`. That is at most four external processes, and the read is capped at 2 bytes and happens only after the size has been checked as 1 or 2. **Path temperature: cold** (a one-shot CLI precondition, not in any loop). Data size: one file of at most 2 bytes; nothing grows.

The suite in `test/cc-push.bats` gains two tests. The accept test runs `cc-push` twice (two real pushes). The refuse test runs it 12 times (8 byte spellings, empty file, directory, FIFO, symlink). Every refusal exits inside `check_checkout`, before any fetch.

Measured cost: the two Q-093 tests take **1.49 s wall** (`LC_ALL=C bats -f Q-093 test/cc-push.bats`, this review, 2026-09-28), and the refuse test alone takes 0.97 s. The full 47-test suite took **25 s** (fact-check E2, 18:01:03–18:01:28). So the new tests are about 6% of suite runtime.

## Findings

#### The helper's own `head` read can still block if a FIFO replaces the file after the type test

**Severity:** Low
**Location:** `devcontainer-config/cc-push.sh:271-279` (read at `:276`)
**Move:** Contention point / resource lifecycle (blocking read)
**Classification:** Macro (an unbounded block, not a constant factor) / Cold path (one-shot CLI precondition)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-orchestrator-synthesis

Evidence, verbatim:

```bash
  [ ! -L "$c" ] && [ -f "$c" ] || return 1
  s="$(stat -c %s -- "$c" 2>/dev/null)" || return 1
  case "$s" in 1|2) ;; *) return 1 ;; esac
  hex="$(head -c 2 -- "$c" 2>/dev/null | od -An -tx1)" || return 1
```

Before this branch, `cc-push` never opened `commondir`. It only tested whether the file existed. Now it opens the file itself. The ordering is correct: fact-check Claim 4 is Verified by execution, and the E3 mutation shows the FIFO test catches a read placed before the type test. The remaining gap is a replacement between `[ -f ]` and `head`. A FIFO swapped in during that window makes `head` block forever, with no timeout. Plan B11 records the TOCTOU residual in terms of *git's* read, and fact-check Claim 13 finds that B11 is accurate. But this window is inside cc-push's own read, which is new with this diff. The practical exposure is small for two reasons. First, the only writer the threat model expects is the container, and `check_no_container` refuses to run while it is up unless `--allow-running` is passed. Second, the config `grep` calls in the same function (`cc-push.sh:318,324`) already have the same unbounded-block window. So this adds one more instance of an accepted class. It does not open a new class.

**Recommendation:** Optional. To make the helper's "nothing blocks" guarantee hold without depending on `check_no_container`, bound the read, e.g. `timeout 5 head -c 2 -- "$c"`. The same bound would also cover the pre-existing config `grep` calls. Otherwise, extend plan B11's wording to name cc-push's own read, so the residual is recorded accurately.

## Endorsements

- The type test runs before any read, and a FIFO `commondir` is refused without being opened. [fact-check: claim 4 — Verified (executed; E3 read-before-type mutation fails the FIFO step)]
- The read is bounded. The size must be 1 or 2 bytes (`case "$s" in 1|2`), and `head -c 2` reads at most 2 bytes, so no input on this path is unbounded. [read: devcontainer-config/cc-push.sh:273-278]
- Every refusal case in the new test runs under `run timeout 30`, so a regression that makes the helper block fails the test within 30 s and does not hang the suite. [fact-check: claim 15 — Verified for `:299` (timeout step)]
- The new tests add 1.49 s of wall time to a suite measured at 25 s, and each of the 12 refusal runs exits inside `check_checkout` before any fetch. [read: test/cc-push.bats:283-308; timing measured this review]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The helper's own `head` read can block if a FIFO replaces the file after the type test | Low | `devcontainer-config/cc-push.sh:271-279` | Medium |

## Overall Assessment

This change is sound on performance. The new code runs once per CLI invocation, and only when `commondir` exists. It spawns at most four short-lived processes and reads at most 2 bytes, only after the type and size checks. It meets the stated requirement that nothing blocks on a FIFO or reads unbounded input, except for one case: a file swapped between the type test and the read. That window is the same kind the function already accepts for its config `grep` calls, and the running-container refusal mitigates it. It is worth either a one-word `timeout` or a sentence in plan B11, but it should not block the merge. The test cost is measured, small (about 1.5 s, roughly 6% of the suite) and bounded by `timeout 30` on every refusal. No profiling is needed.

## Goal-Alignment Note

The PR's goal is to accept a self-referencing `commondir` (`.` or `.\n`) without letting cc-push block or read unbounded input. The diff achieves this for every case the threat model addresses: the stat-only type test comes first, the size gate precedes a fixed 2-byte read, and the tests exercise FIFO, directory, symlink and eight byte spellings under timeouts. The one gap is a replacement race inside the helper's own read (Finding 1). It is already the accepted TOCTOU class for this function, but plan B11 describes it only for git's read. Nothing in this review pulls against the security goal. Bounding the read with `timeout` would strengthen the no-block property and cost nothing measurable.
