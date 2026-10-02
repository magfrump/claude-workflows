Commit: ba39470 (A) / 36ca12c (B)

# Performance Review — dev-cycle pass 23 (pass-22 fix round, k=1 delta)

**Scope:** Partial. A: `git diff bc98571..ba39470 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` (HEAD ca8ba77 adds review docs only; `git diff ba39470 HEAD -- scripts test` is empty). B: `git diff 6c8ae91..36ca12c -- skills/dev-cycle/SKILL.md docs/dev-cycle.md` in `/workspace/.claude/wt-devcycle` (merge f2843cd; its `scripts/dev-cycle.sh` is byte-identical to A's). Focus: measure `--check-answer` on a large questions archive and with many IDs per call, `--check-fix`, `--check-branch`, and re-measure `--check-path` after `exact()`. Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `code-fact-check-report-digest-pass22.md` (verdicts on bc98571 / 6c8ae91; its Claim 9 is the wording residue of pass-22 perf finding 1, which this round fixes in code). Also `performance-review-2026-10-02-digest-pass22.md` (findings 1–2).

> ⚠️ **No code fact-check report covers ba39470 / 36ca12c.** Performance claims in this round's comments have not been independently verified by a fact-check stage. The numbers below are my own executions. Runtime endorsements are submitted as claims.

**Measurements.** All mine, 2026-10-02, this sandbox: bash 5.2.15, git 2.39.5, mawk 1.3.4 (the only awk installed; no gawk), 16 CPUs. The environment's `LC_ALL=en_US.UTF-8` is not installed (`locale -a`: C, C.utf8, POSIX); probes set `LC_ALL` explicitly. Scripts are `git show ba39470:scripts/dev-cycle.sh` and, for comparison, `git show bc98571:…`. Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf23/` (`perf23/` below). Each probe (`p1`–`p5`) is one `set -eu` script that creates its own `mktemp -d` dir under `perf23/` and checks `$PWD` before any write; every process ran under `timeout` and none of mine was left running. Nothing was written to either worktree except this file. Another session's bats suite (wt-devcycle) was running concurrently during p5, so p5's wall time is an upper bound.

- **P1, `--check-answer`** (`perf23/p1.log`). Repos built from wt-devcycle's real `questions.md` (20,726 B, 13 entries) and `questions-archive.md` (186,439 B, 89 entries), the archive body repeated with renumbered IDs:

  | Archive | 1 live ID | 1 archived ID (first / last) | absent ID | 10 IDs | 100 IDs | bare `awk END{print NR}` |
  |---|---|---|---|---|---|---|
  | x1: 186 KB, 89 entries | 12 ms | 16 / 16 ms | 16–19 ms | 100 ms | 850 ms (89 IDs) | 1 ms |
  | x10: 1.7 MB, 890 entries | 12 ms | 19 / 18–19 ms | 19 ms | 124 ms | 1,180 ms | 2 ms |
  | x100: 17 MB, 8,900 entries | 13–14 ms | 40–42 / 39–40 ms | 39–40 ms | 395 ms | 3,333 ms | 6 ms |

  All real IDs (102) in one call on x1: **903 ms**, 102 lines, 0 stderr. Marginal cost per archived ID ≈ **9.5 ms** at today's size and ≈ **33 ms** at 100×. The first and last entry cost the same: the awk program reads the whole file even after its entry has ended.
- **P2, `--check-branch`** (`perf23/p2.log`): 1 name 10–11 ms (bc98571: 8–9 ms); 100 names **281–294 ms** (bc98571: 87–91 ms). Unchanged across 0 refs, 10,000 loose refs and 10,000 packed refs. A tag `feat/shadow` with no such branch gives `ok feat/shadow absent`.
- **P3, `--check-path` / `--check-fix`** (`perf23/p3.log`) on a repo of pass 22's R3 shape, rebuilt with `perf22/gen.py`: 50,005 tracked, 250,021 ignored, of which 50,021 under `docs/working/` (50,000 in `docs/working/scratch/`, plus one non-UTF-8 name). Two runs each, under `C.UTF-8` and the uninstalled `en_US.UTF-8`:

  | Arg | ba39470 | bc98571, same session |
  |---|---|---|
  | `docs/working` (plain dir, 50,021 ignored below) | **40–45 ms** | 477–513 ms |
  | `docs` | **45–49 ms** | 472–510 ms |
  | `docs/working/scratch` | **40–47 ms** | 488–523 ms |
  | `docs/working/scratch/d000` | 22–23 ms | 29–31 ms |
  | `README.md`, `src`, `docs/working/round-3.md` | 14–23 ms | 13–24 ms |
  | `docs/working/*.md` | 109–121 ms | 101–113 ms |
  | `*/working/x` | 118–162 ms | 115–135 ms |
  | `**/*.md`, `src/d000/*/*.md` (capped) | 218–310 ms | 213–307 ms |
  | batch of 120 args (40 files, 40 dirs, 40 globs) | 4,778 ms, 960 lines | 4,664 ms |

  stderr: 0 lines under `C.UTF-8`, exactly 2 (bash start-up) under `en_US.UTF-8`, for every call. `--check-fix`: refused shapes (`setup.sh`, `src/…`, `docs`, `docs/*.md`) 7–9 ms with no git call; allowed paths 14–20 ms (same as `--check-path`); `docs/working` 39–42 ms; a 120-argument batch 628 ms.
- **P4, brief listing** (`perf23/p4.log`): 60 tracked briefs `docs/working/briefs/2026-01-05-item-0.md` … one per week, the last 3 `Status: open`. `--check-path 'docs/working/briefs/*.md'` took 262 ms and printed 50 `ok` lines (items 0–49) then `skip docs/working/briefs/*.md: matches more than 50 files; the rest are not listed (narrow the glob)`. Open briefs among the listed: **0 of 3**.
- **P5, tests** (`perf23/p5.log`): `bats test/scripts/dev-cycle.bats` on `git archive ba39470 scripts test`: **33/33 ok, rc 0, 10.4 s** (pass 22: 30 tests, 8.1 s; concurrent load from another session's suite). The header ends at line 47 and line 48 is blank, so `sed -n '2,48p'` covers it.

Legibility-target values: **maintainer** (someone editing the script or skill) and **agent** (the model running the skill and reading the check's output).

## Data Flow and Hot Paths

All the new modes run before any digest work and exit (`scripts/dev-cycle.sh:298-310`). The skill calls them from repo text, one Bash call per mode and batch. Every call is a **cold path**: one agent tool call. The standing escalation conditions are the agent's 120 s Bash timeout, the agent's context (which receives stdout and stderr), and growth of inputs the cycle never prunes.

Per-argument cost, from reading each function whole with every callee opened:
- **`--check-answer`** (`:255-297`): per ID, for up to two files, `inrepo "$f"` (one `blocker` subshell, then a `realpath` subshell per existing path component and one for the file), then one `env LC_ALL=C awk` over the whole file. An ID found in `questions.md` reads one file; an archived or absent ID reads both. The awk program has no early `exit`, so the cost is O(file size) per ID, whatever the entry's position. N for the skill is the IDs on open briefs' `Asked:` lines not yet `Applied:` (B `SKILL.md:253-261`): at most 3 open briefs, one question each per 14 days, so a handful per cycle.
- **`--check-branch`** (`:236-245`): three git processes per name (`check-ref-format`, `check-ref-format --branch`, `show-ref --verify --hash`) where bc98571 ran one. About 2 ms more per name, independent of ref count. N is at most the open briefs plus those written this cycle.
- **`--check-fix`** (`:248-253`): a regex on the argument; only an argument under `docs/` or exactly `README.md` reaches `check_path`. A refused argument costs no git call.
- **`--check-path` after `exact()`** (`:186-198`): a plain argument's ignored listing is now filtered by `grep -zxF` too, so the bash loop sees at most one record from each side. A glob's listings each pass through one extra `cat` (`:187`).
- **Default-branch lookup** (`:315-326`): one extra `rev-parse` fork per candidate found, once per digest run. Negligible; no finding.
- **B's brief listing** (`SKILL.md:74`, `:147-149`, `:279-282`): every cycle now finds briefs only by one capped glob, and closed briefs are never moved or deleted (`:250-251` sets `Status: closed`; `:283-284` requires "a path no brief has used before"). The input grows by up to 3 files per cycle without bound (finding 1).

## Findings

#### 1. The brief listing is one glob capped at 50, and closed briefs are never removed, so after the 50th brief the newest briefs — the open ones — drop out of the listing

**Severity:** Medium. Matrix default for Macro × Cold is Low; escalated because the cold path runs over an input that grows without bound by design and the failure is a functional cliff, not a slowdown. Preconditions: more than 50 tracked files in `docs/working/briefs/` (no repo has any yet: wt-devcycle has no `docs/working/briefs/`). At up to 3 new briefs per cycle that is reached after roughly 17–50 cycles. Confidence: High on the mechanism (measured), Medium on how soon it bites (cycle cadence is not documented).
**Location:** `skills/dev-cycle/SKILL.md:74` (B, 36ca12c), used at `:147-149` and `:279-282`; cap at `scripts/dev-cycle.sh:199-214` (A, ba39470)
**Evidence (verbatim):**
```markdown
not written. Briefs are found only through `--check-path 'docs/working/briefs/*.md'`, and a
roadmap brief path counts as a brief (and holds a slot) only if `--check-brief '<path>'` and
```
(The excerpt is `:74-75`; the sentence ends at `:76` with "`--check-path '<path>'` both print `ok` for it." The listing is consumed by step 1, `:147-149`: "Skip any branch or worktree an open brief (found as in the Rules) names", and by Build briefs, `:279-282`: "while fewer than 3 briefs are open, counting earlier cycles' (found as in the Rules) and the ones this cycle has written". Briefs are retained: `:250-251` "Either way the brief gets `Status: closed`", `:283-284` "a path no brief has used before". The script side, `check_path` `:199-214`: `if [[ $n -gt $max ]]; then echo "skip $a: matches more than $max files; the rest are not listed (narrow the glob)"; break; fi` with `max=50`.)
**Move:** Ask "what's the size of N?"
**Classification:** Macro (unbounded collection read through a fixed cap) / Cold path (one call per cycle)
**Confidence:** High
**Baseline:** P4, `perf23/p4.log`, 2026-10-02: with 60 dated briefs, the last 3 open, the listing returned the oldest 50 in 262 ms and **0 of the 3 open briefs**.
**Legibility-target:** agent

`git ls-files` returns paths in sorted order, and brief names start with their date, so the cap keeps the oldest 50 and cuts the newest. Open briefs are by construction the newest (or recently kept) ones. Past 50 briefs, the open count at Build briefs under-counts, so the cycle writes briefs past the 3-slot limit, and step 1 loses the protection for open briefs' branches and worktrees. The skip line is printed, and the Rules say "past that, narrow the glob", but the same Rules say briefs are found "only through" this exact glob, so the agent has no sanctioned narrowing. Before the cliff, the cost is also linear: each cycle reads every brief ever written (up to 50) to find `Status: open`, which is agent context, not CPU. The In-flight checks themselves are not affected: they take brief paths from the roadmap (`:247`), one `--check-brief` + `--check-path` each.

**Recommendation:** Make the set the cycle scans bounded. For example, move a brief to `docs/working/briefs/closed/` when it gets `Status: closed` (the glob `briefs/*.md` does not match a subdirectory under `:(glob)` magic), or take open briefs from the roadmap's In flight paths instead of a directory glob. If the glob stays, have the script or skill handle more than 50 (e.g. per-year globs) and add a bats case with 51+ briefs.

#### 2. `--check-answer` rescans the whole archive once per ID, with ~9 ms of process overhead per ID

**Severity:** Informational. Preconditions: many IDs in one call or a much larger archive. The skill's N is a handful of IDs per cycle (at most 3 open briefs, one keep-or-drop question each per 14 days). Confidence: High on the cost.
**Location:** `scripts/dev-cycle.sh:288-297` (A, ba39470), with the awk program at `:263-287`
**Evidence (verbatim):**
```bash
check_answer() {
  local a="$1" f r
  if [[ ! "$a" =~ ^Q-[0123456789]+$ ]]; then echo "skip ${a//$'\n'/ }: not a question ID (Q- and digits)"; return; fi
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    inrepo "$f" || continue
    r="$(env LC_ALL=C awk -v id="$a" "$ANSWER_AWK" "$f")"
    if [[ -n "$r" ]]; then echo "$r $a"; return; fi
  done
  echo "skip $a: no such entry in docs/working/questions.md or questions-archive.md"
}
```
(The full function. It is called once per argument from the dispatch loop at `:298-310`. The awk program's last rule is `END { if (found) print (done ? result : answered ? "unrecognized" : "open") }` (`:287`); no rule calls `exit`, so after `inside = 0` (`:274`) every remaining line is still read and tested against the heading rule at `:273`.)
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed per-ID process cost plus a full-file scan) / Cold path (one call per cycle)
**Confidence:** High (measured)
**Baseline:** P1, `perf23/p1.log`, 2026-10-02: on today's 186 KB archive, one archived ID takes 16 ms and 89 IDs take **850 ms** (≈9.5 ms per ID, against 1 ms for a bare awk scan of the file). On a synthetic 17 MB / 8,900-entry archive, one ID takes 40 ms and 100 IDs **3,333 ms**. The first and last entries cost the same.
**Legibility-target:** maintainer

Cost is O(IDs × (questions.md + archive)) plus about six forks per file per ID (`inrepo`'s `blocker` and `realpath` subshells, `env`, `awk`). At the skill's realistic N this is well under 100 ms, and even all 102 real IDs in one call take 0.9 s; the 120 s cliff would need thousands of IDs against a multi-megabyte archive. No action needed for merge.

**Recommendation:** Optional. Hoist the two `inrepo` checks out of the per-ID loop, and/or add `inside && /^##/ { exit }` once `found` is set (only if a duplicate heading should not be re-entered, which is a behavior choice, not a speed one). A single awk pass over both files for all IDs would make the call O(file size) total.

#### 3. `--check-branch` now spawns three git processes per name

**Severity:** Informational. Preconditions: none beyond a call; N is the open briefs plus this cycle's (at most a few). Confidence: High.
**Location:** `scripts/dev-cycle.sh:236-245` (A, ba39470)
**Evidence (verbatim):**
```bash
check_branch() {
  local a="$1" sha
  if [[ ! "$a" =~ ^[$NAMECHARS]+$ || "$a" == -* ]]; then echo "skip ${a//$'\n'/ }: not an allowed branch name"
  elif ! git check-ref-format "refs/heads/$a" || ! git check-ref-format --branch "$a" >/dev/null 2>&1 \
    || [[ "$a" == HEAD || "$a" == refs/* ]]; then echo "skip $a: not a valid branch name"
  else
    sha="$(git show-ref --verify --hash "refs/heads/$a" 2>/dev/null || true)"
    echo "ok $a ${sha:-absent}"
  fi
}
```
(The full function.)
**Move:** Count the hidden multiplications
**Classification:** Micro / Cold path
**Confidence:** High (measured)
**Baseline:** P2, `perf23/p2.log`, 2026-10-02: 100 names take **281–294 ms** against 87–91 ms for bc98571; one name 10–11 ms against 8–9 ms. 10,000 loose or packed refs change nothing.
**Legibility-target:** maintainer

About 2 ms per name for the correctness gain (hash by exact ref, `--branch` rules). Not worth changing. Recorded so the cost is on file.

**Recommendation:** None required.

#### 4. (Cross-lane note, not a performance problem) `--check-fix` allows the cycle's own bookkeeping files and ignored scratch under `docs/working/`

**Severity:** Informational (for the security and API-consistency critics to grade). Preconditions: the agent calls `--check-fix` on such a path. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:248-253` (A, ba39470)
**Evidence (verbatim):**
```bash
check_fix() {
  local a="$1"
  if ! pathform "$a" || [[ "$a" == *[*?]* ]]; then echo "skip ${a//$'\n'/ }: not an allowed path form"
  elif [[ ! "$a" =~ ^docs/|^README\.md$ ]]; then echo "skip $a: in-cycle fixes edit only docs/ and README.md; file it instead"
  else check_path "$a"; fi
}
```
(The full function.)
**Move:** n/a (observed while measuring)
**Classification:** n/a
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative (not a cost finding). Observation from P3: `--check-fix docs/working/round-3.md` (an ignored scratch file) prints `ok`.
**Legibility-target:** agent

The brief asks whether anything under `docs/` should not be edited in-cycle. By the code, `--check-fix` accepts any tracked file under `docs/` (including `docs/working/questions*.md`, `docs/working/cycles/*`, `docs/decisions/*`, `docs/reviews/*`) and any ignored file under `docs/working/`. Whether the cycle's own files should go through `--check-write` only, and whether ignored scratch should be fix-eligible, is a scope question outside this lane.

**Recommendation:** Hand to the security / API critics; no performance action.

## Endorsements

- Pass-22 finding 1 is fixed. With `exact()` on the ignored listing, a plain `docs/working` argument over 50,021 ignored files takes **40–45 ms** (bc98571: 477–513 ms, same session); `docs` 45–49 ms (was 472–510), `docs/working/scratch` 40–47 ms (was 488–523). Output is unchanged (`a directory, not a file`). `[unverified — submitted as claim]` (my execution, P3)
- No regression elsewhere in `--check-path`: literal files, tracked dirs, globs and the capped globs are within run-to-run noise of bc98571 (e.g. `**/*.md` 218–261 ms vs 213–274 ms); the glob path's extra `cat` adds at most ~10 ms. A 120-argument batch takes 4.8 s vs 4.7 s. `[unverified — submitted as claim]` (my execution, P3)
- stderr stays bounded: every call in P1–P3 wrote 0 stderr lines under `C.UTF-8` and exactly the 2 bash start-up lines under the uninstalled `en_US.UTF-8`, including the new modes and the 120-argument batches. `[unverified — submitted as claim]` (my execution)
- `--check-fix` refuses out-of-scope arguments before any git call (7–9 ms) and costs the same as `--check-path` otherwise. `[read: scripts/dev-cycle.sh:248-253]`
- `--check-branch` cost does not depend on ref count or packing (10,000 loose or packed refs: 10–11 ms per single-name call). `[unverified — submitted as claim]` (my execution, P2)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Brief listing is one glob capped at 50 and briefs are never removed; past 50, the newest (open) briefs are cut (P4: 0 of 3 open listed) | Medium | `skills/dev-cycle/SKILL.md:74` (B); `scripts/dev-cycle.sh:199-214` (A) | High |
| 2 | `--check-answer` rescans whole files per ID with ~9 ms process overhead (89 IDs: 850 ms; 17 MB archive, 100 IDs: 3.3 s) | Informational | `scripts/dev-cycle.sh:288-297` | High |
| 3 | `--check-branch` runs 3 git processes per name (100 names: 281–294 ms vs 87–91 ms) | Informational | `scripts/dev-cycle.sh:236-245` | High |
| 4 | Cross-lane: `--check-fix` allows bookkeeping files and ignored `docs/working/` scratch | Informational | `scripts/dev-cycle.sh:248-253` | High |

## Overall Assessment

The script side of the round is in good shape. `exact()` closes pass-22 finding 1: a plain directory over 50k ignored files dropped from about 0.5 s to about 45 ms with identical output. Nothing else in `--check-path` regressed, and stderr stays at the interpreter's two start-up lines. The new modes are cheap at the skill's realistic sizes: `--check-answer` is about 16 ms per call on today's archive and scales linearly per ID; `--check-branch` adds about 2 ms per name; `--check-fix` is `--check-path` behind a regex. Those are Informational. The one item to address is on the skill side (finding 1): routing brief discovery through a single capped glob over a directory that only grows creates a deterministic cliff at 51 briefs, where the cap cuts exactly the open briefs. It does not bite today (no briefs exist yet) and is fixable in place by bounding what the glob scans (moving closed briefs aside) or by taking open briefs from the roadmap. No further benchmarking is needed; a bats case with 51+ briefs would pin the fix.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file."
- **Path:** saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass23.md`, first line `Commit: ba39470 (A) / 36ca12c (B)`.
- **Structure:** performance-reviewer layout: header, no-fact-check warning, data flow and hot paths, findings, evidence-tagged endorsements (≤5), summary table, overall assessment. Each finding carries Severity (with preconditions and confidence), Location, verbatim Evidence with truncation notes, Move, Classification, Confidence, Baseline and Legibility-target.
- **Coverage of the brief's scope:** `--check-answer` measured on 1×, 10× and 100× the real archive with 1, 10 and 100 IDs per call; `--check-fix` measured on allowed, refused and directory arguments and in a 120-argument batch; `--check-branch` measured at 0 and 10,000 refs, loose and packed, and with a shadowing tag; `--check-path` re-measured after `exact()` on pass 22's R3 shape against bc98571. Rules checked and found correct and complete for performance: `exact()`'s filtering of both listings; the default-branch lookup (one extra fork per run).
- **Probe rule:** followed; every probe self-contained under `perf23/`, all processes under `timeout`, nothing outside the temp dirs changed except this report.
- **Not committed**, per instructions.
