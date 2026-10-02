Commit: 3aee138

# Performance Review — feat/dev-cycle-digest (final pass)

**Scope:** `git diff main...HEAD` — `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`
**Date:** 2026-09-29
**Focus:** digest size as agent context (with and without a cycle record), script runtime, test runtime

> ⚠️ **No code fact-check report provided.** Performance claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

## Data Flow and Hot Paths

The script runs once per dev cycle (every 1–2 weeks). An agent reads its stdout as the input
to the judgment steps. It is a **cold path** for CPU. Its output size matters more, because the
whole digest goes into the agent's context every cycle. It has two loops that grow with repo
content:

- one per decision record that has a `## Revisit triggers` section: 2 `git log -1` calls plus 1 `awk`;
- one per log.md row that mentions "revisit": 2 `awk` plus 1–2 `grep`.

This repo has 32 records (11 with triggers), 9 revisit log rows and 1,885 commits.

### Measurements (this repo, HEAD 3aee138, TODAY = 2026-09-29)

The "with a cycle record" runs used a scratch clone with a dummy `docs/working/cycles/cycle-<date>.md`.

| Run | Window | Digest bytes | §2 Revisit triggers bytes | Records carried | Wall time |
|---|---|---|---|---|---|
| No cycle record (14-day default) | since 09-15 | 20,437 | 17,255 | — (all in full) | 0.14–0.19 s |
| Record dated 09-15 | since 09-15 | 20,565 | 17,390 | 0 records, 1 log row | 0.19 s |
| Record dated 09-22 | since 09-22 | 16,856 | 13,918 | 1 record, 2 log rows | 0.20 s |
| Record dated 09-28 | since 09-28 | 5,224 | 3,171 | 10 records, 5 log rows | 0.15 s |

§2 is 84% of the digest without a record. The bulk is the 11 records' trigger sections
(787–1,389 bytes each, about 12.6 KB in total) plus 9 log rows (3.5 KB). At about 4 bytes per
token, the full digest costs roughly 5k tokens. That is not large in absolute terms. But the
carry-forward saves almost nothing at the intended 14-day cadence (see Finding 1).

Test runtime: `bats test/scripts/dev-cycle.bats` takes 2.09 s wall (1.56 s user) for 13 tests.
That fits the file's `@category fast` tag.

Scaling probe: a synthetic repo with 200 trigger-bearing records, 300 revisit log rows and 201
commits ran in 5.3 s. That is linear, at about 10 ms per item, almost all of it process spawns.

## Findings

#### Carry-forward treats any commit to a record as a changed trigger, so at a 14-day cadence nearly every record still prints in full

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:128-135` (the `changed=` test)
**Move:** Find the work that moved to the wrong place / check the cache (the carry-forward acts as a cache of the last verdicts)
**Classification:** Macro (the digest grows with the record count, and churn defeats the carry-forward) / Cold path for CPU; the cost is agent context, paid on every cycle
**Confidence:** High (measured)
**Baseline:** §2 is 17,255 bytes with no record. With a record at the 14-day default it is 17,390 bytes (0 records carried); at 7 days it is 13,918 bytes (1 of 11 carried). Measured on this repo at 3aee138 today, in scratch clones.

The script prints a record in full if `git log -1 --since=... -- "$f"` finds any commit to the
file. Bulk edits in this repo touch many records outside their triggers section, for example
64132611 (archive link rescue) and b09ebe06 (numbering disambiguation). So 10 of the 11
records count as "changed" since 09-15, and 10 count as changed since 09-22.

I compared each record's extracted `## Revisit triggers` section at the window-start commit
against HEAD. The section actually changed in **2 of 11** records since 09-15 and in **1 of 11**
since 09-22. Comparing sections instead of files would cut §2 from about 17 KB to about 5 KB:
roughly 1–2 records and the dated log rows. That is about a 60% smaller digest (about 3k fewer
tokens each cycle), and the agent would not have to re-decide 8–9 unchanged triggers.

This is also a behaviour gap against the commit message's claim that "records changed … print
in full; the rest carry forward". The claim is literally true at file level, but the purpose
(don't re-verdict unchanged triggers) is not met at the cadence the skill uses.

**Recommendation:** Resolve the window-start commit once
(`base=$(git rev-list -1 --before="$SINCE_TS" "$MAIN_SHA")`). Then, per record, compare the
awk-extracted triggers section of `git show "$base:$f"` with the working-tree copy. Print the
record in full if they differ or if the file did not exist at `base`. This costs one `git show`
per record in place of one `git log`, so runtime stays about the same. Add a bats case in which
a commit edits only a non-trigger section of a record and the record is still carried. Treat
this as a follow-up if the unit is otherwise clean: it changes which records get a fresh
verdict, not correctness of the current output.

#### Per-row subprocess spawning makes runtime linear at about 10 ms per record or row

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:124-157`
**Move:** Count the hidden multiplications
**Classification:** Micro (process spawn per item) / Cold path (runs once per cycle)
**Confidence:** High (measured)
**Baseline:** 0.14–0.20 s on this repo (11 records, 9 rows); 5.3 s on a synthetic repo with 200 records and 300 rows. Both measured today.

Each log row spawns 3–4 processes (two `awk` calls to split columns, plus `grep`). Each record
spawns 2 `git log` calls (the in-window check, then the last-changed date) and 1 `awk`. At this
repo's size the cost is invisible. It would only matter at hundreds of records, which is
roughly 10 years of this repo's decision rate.

**Recommendation:** No action needed now. If it ever matters, parse log.md in a single `awk`
pass, and have one `git log --format=%h\ %ad` call supply both the in-window test and the date.

## Endorsements

- Everything outside §2 is small and bounded: §1 caps the merge list at 30 lines plus an overflow count; §3 prints only trigger/deferred questions plus a one-line route count; §4 prints `--sample` lines; §5 prints only the roadmap's Next section. Measured §1+§3+§4+§5 = 3.2 KB on this repo [read: scripts/dev-cycle.sh:99-106,164-198].
- The `shuf --random-source=<(yes "$seed")` process substitution left no `yes` process behind after the runs above (`pgrep -u $(id -u) -a yes` was empty) [unverified — submitted as claim: `yes` always exits on SIGPIPE once `shuf` closes the pipe, on every platform the script targets].
- The default branch resolves to a hash once and is reused, so no per-section `rev-parse` runs [read: scripts/dev-cycle.sh:52-69].

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Carry-forward is file-level; bulk edits defeat it, so §2 barely shrinks at a 14-day cadence | Medium | `scripts/dev-cycle.sh:128-135` | High |
| 2 | Per-item process spawns, linear at ~10 ms per item | Informational | `scripts/dev-cycle.sh:124-157` | High |

## Overall Assessment

Runtime is not a concern: 0.15–0.2 s per run and 2.1 s for the 13 tests. The one
performance-relevant issue is digest size. Carry-forward works as coded: a 1-day window drops
the digest from 20.4 KB to 5.2 KB. But it keys on "the file was committed to", and bulk
documentation edits in this repo touch nearly every record. So at the skill's 14-day cadence
the digest is the same size as with no record at all, and the agent re-verdicts about 9
triggers whose text did not change. Comparing the triggers section itself is a small, local fix
that cuts the digest by about 60% at the same runtime. It does not block merge; it is a
Medium-severity efficiency gap, fixable in this unit or as a follow-up.

## Goal-Alignment Note

- **Answered:** measured digest size with no record and with records at three window starts (0/7/14-day analogues); script runtime on this repo and at synthetic scale; bats runtime; checked that no `yes` process was left behind.
- **Out of scope:** the security re-checks (hostile branch names) and the per-test mutation checks listed in the brief are for the security and test-strategy critics; I did not repeat them. No tracked file was edited except this report. All probes ran under `timeout` in scratch clones and have exited.
- **Escalate:** Finding 1 is a judgment call for the author: fix it in this unit (about 10 lines plus 1 test, which keeps the unit near the 400-line cap) or file a follow-up.
