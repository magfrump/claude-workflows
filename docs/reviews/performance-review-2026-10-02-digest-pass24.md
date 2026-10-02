Commit: c1d0a80 (A) / fb643e2 (B)

# Performance Review — dev-cycle pass 24 (pass-23 fix round, k=1 delta)

**Scope:** Partial. A: `git diff ba39470..c1d0a80 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` in `/workspace/.claude/wt-digest` (HEAD 0b4c97b adds review docs only; `git diff c1d0a80 HEAD -- scripts test` is empty). B: `git diff 36ca12c..fb643e2 -- skills/dev-cycle/SKILL.md` in `/workspace/.claude/wt-devcycle` (merge 0caaba2; `git show 0caaba2:scripts/dev-cycle.sh` is byte-identical to `c1d0a80:scripts/dev-cycle.sh`, checked with `cmp`). Focus, per the brief: re-measure `--check-answer` now that it reads both files fully for duplicates, the check modes now that they run after the default-branch lookup, and the `briefs/closed/` listing. Everything else is context only.
**Date:** 2026-10-02
**Based on:** Stage-1 context `code-fact-check-report-digest-pass23.md` (verdicts on ba39470 / 36ca12c, the code this round changes). Also `performance-review-2026-10-02-digest-pass23.md` (findings 1–4) and its generator and numbers in `scratchpad/perf23/`.

> ⚠️ **No code fact-check report covers c1d0a80 / fb643e2.** Performance claims in this round's comments have not been independently verified by a fact-check stage. The numbers below come from my own runs. Runtime endorsements are submitted as claims.

**Measurements.** All are mine, taken 2026-10-02 in this sandbox: bash 5.2.15, git 2.39.5, mawk 1.3.4 (the only awk installed), 16 CPUs. The environment's `LC_ALL=en_US.UTF-8` is not installed, so every probe sets `LC_ALL=C.UTF-8`. The scripts under test are `git show c1d0a80:scripts/dev-cycle.sh` ("new") and, for comparison, `git show ba39470:…` ("old"), each run in the same session. Scratch is under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf24/` (written `perf24/` below). Each probe (`p1`–`p4`) is one `set -eu` script. It creates its own `mktemp -d` dir under `perf24/` in that same script and checks `$PWD` before any `git init`, commit or write. Every process ran under `timeout`, and none of mine is still running. Nothing was written to either worktree or to `/workspace` except this file. Another session's full bats suite (wt-devcycle) was running at the same time, so absolute times carry some noise. Old and new were always interleaved in the same loop.

- **P1, `--check-answer`** (`perf24/p1.log`; the generator is pass 23's, with the same renumbered repetition of wt-devcycle's real `questions-archive.md`, 186,439 B and 89 entries, plus `questions.md`, 20,726 B and 13 entries):

  | Archive | live ID old → new | archived ID old → new | absent ID old → new | 10 IDs old → new | 100 IDs old → new | awk program alone, old → new | non-ID arg (fixed cost) old → new |
  |---|---|---|---|---|---|---|---|
  | x1: 186 KB | 14–15 → **23–24 ms** | 18–19 → 22–23 ms | 19–23 → 24–27 ms | 109 → 108 ms | 849 → 848 ms (89 IDs) | 2 → 2 ms | 7 → 11 ms |
  | x10: 1.7 MB | 12–13 → **24–25 ms** | 19–22 → 23–25 ms | 18–20 → 23–26 ms | 123 → 129 ms | 1,161 → 1,248 ms | 4 → 5 ms | 8 → 12 ms |
  | x100: 17 MB | 12 → **47–49 ms** | 40 → 48 ms | 39 → 48–63 ms | 334 → 381 ms | 3,275 → 3,740 ms | 24 → 30 ms | 8 → 12 ms |

  When every real ID (102) goes in one call on x1, old takes 904 ms and new takes **1,024 ms**. Each prints 102 lines with 0 stderr. Diffing the two outputs shows exactly three changed readings: `Q-070`, `Q-071` and `Q-073` go from `unrecognized` to `keep`. Nothing else changes. A cross-file duplicate (Q-103's heading appended to the archive) prints `skip Q-103: more than one entry with this heading (docs/working/questions.md and docs/working/questions-archive.md)` in 21 ms.
- **P2, every check mode, one argument per call** (`perf24/p2.log`; a small repo, run 3× each, with and without `origin/HEAD`): `--check-path` 13–14 → 17–19 ms; `--check-write` 9–10 → 13–17 ms; `--check-fix` (allowed) 12–13 → 17–20 ms; `--check-fix setup.sh` (refused) 7–8 → 11–16 ms; `--check-branch` existing 10–11 → 15–17 ms; absent 10–12 → 14–16 ms. 100 branch names in one call: 287 → 289 ms. `origin/HEAD` set or not makes no difference. `--check-branch main` prints `skip main: the default branch`. In a repo with no resolvable default branch (detached HEAD, no `main`/`master`, no `origin/HEAD`), and in an unborn repo, the old script answered (`ok …`, rc 0). The new one prints `Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)` on stderr and exits 1.
- **P3, the brief listing with `briefs/closed/`** (`perf24/p3.log`): 1,000 tracked closed briefs in `docs/working/briefs/closed/` and 3 open ones in `docs/working/briefs/`.
  - `--check-path 'docs/working/briefs/*.md'`: **28–29 ms**, printing exactly the 3 open briefs.
  - `--check-path 'docs/working/briefs/closed/*.md'`: 335–339 ms, printing 50 `ok` lines (the oldest) and then `skip …: matches more than 50 files`.
  - A literal closed path: 20–21 ms, `ok` if it is used and `skip …: no tracked file … matches` if it is free.
  - `--check-write` on a `closed/` destination: 16–17 ms, `ok`.
  - `--check-brief` on a `closed/` path: `skip …: not an open build brief`.
  - `git mv` onto a used `closed/` name: `fatal: destination exists`, and nothing moved.
- **P4, tests** (`perf24/p4.log`): `bats test/scripts/dev-cycle.bats` on `git archive c1d0a80 scripts test`: **36/36 ok, rc 0, 9.6 s** (pass 23: 33 tests, 10.4 s). Help range: the header's last comment line is `:52` and `:53` is blank, so `sed -n '2,53p'` (`:116`) covers it.

Legibility-target values: **maintainer** (someone editing the script or skill) and **agent** (the model that runs the skill and reads the check's output).

## Data Flow and Hot Paths

The check modes now run after the default-branch lookup and exit before any digest work (`scripts/dev-cycle.sh:344-377`). The skill calls them from repo text: one Bash call per mode and batch. Every call is a **cold path**, a single agent tool call. Three things can still push a finding up: the agent's 120 s Bash timeout, the agent's context (which receives the output), and inputs that grow without bound.

- **`--check-answer`** (`:328-341`, awk at `:282-327`). For each ID and each of the two files: one `blocker` walk (`skipped`, which forks a `realpath` subshell per existing path part), then one `env LC_ALL=C awk` over the whole file. The loop no longer returns on the first hit. Duplicate detection needs both files read to the end, so a live ID now reads the archive too. That is the main cost change. The awk also does more per line: a CR strip, a fence test, and a `heading()` call. N for the skill is the IDs on open briefs' `Asked:` lines that are not yet `Applied:`, so a handful per cycle. One change matters more for N than for cost: a `skip` now stays off `Applied:` (B `SKILL.md`, In flight 2), so a skipped ID is re-read every cycle until its cause is fixed. That stays a handful of IDs. Duplicate IDs are also reported by `scripts/questions.sh check` (`:259`), so a skip should not persist unnoticed.
- **Default-branch lookup before the check modes** (`:344-364`): `symbolic-ref`, then `show-ref` + `rev-parse` per candidate until one resolves. It runs once per call, not per argument. Measured at about 4 ms per call (P2).
- **`--check-branch`** (`:245-257`): adds one `rev-parse …^{commit}` for an existing branch only. For an absent one the cost is unchanged.
- **`--check-fix`** (`:260-266`): now also calls `writable` (regexes only) before `check_path`. A refused argument still costs no git call.
- **B's listing** (`SKILL.md:75-76`, `:254`, `:291-292`): open briefs are found by the `briefs/*.md` glob. Closed ones are `git mv`'d to `briefs/closed/`, which the glob does not match under `:(glob)` magic. The open set is therefore bounded by the 3-slot limit. `closed/` grows by up to 3 files per cycle without bound, and it is read only by the slug-uniqueness rule (finding 3).
- **Keep-or-drop "shows no work"** (`SKILL.md:274-276`): one `git rev-list --count <default>..<commit>` per open brief with an existing branch. That is O(commits ahead), once per brief per cycle. Negligible, so no finding.

## Findings

#### 1. `--check-answer` now reads both questions files in full for every ID, including live ones

**Severity:** Informational. Preconditions: none beyond a call. It matters only with many IDs per call or a much larger archive, and the skill passes a handful. Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:328-341` (A, c1d0a80), awk program `:282-327`
**Evidence (verbatim):**
```bash
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    if skipped "$f"; then echo "skip $a: $SKIP_AT is not a plain file or directory, so $f is not read"; return; fi
    [[ -f "$f" ]] || continue
    r="$(env LC_ALL=C awk -v id="$a" "$ANSWER_AWK" "$f")"
    [[ -n "$r" ]] || continue
    if [[ "$r" == dup || -n "$hit" ]]; then echo "skip $a: more than one entry with this heading${where:+ ($where and $f)}"; return; fi
    hit="$r"; where="$f"
  done
```
(This is `:331-338`. The function continues at `:339-340`: `if [[ -n "$hit" ]]; then echo "$hit $a"` / `else echo "skip $a: no such entry …"; fi`. The awk's per-line rules `{ sub(/\r$/, "") }` (`:303`) and `heading($0) { count++; inside = (count == 1); next }` (`:306`) run on every line, and no rule calls `exit`, so each file is read to the end.)
**Move:** Find the work that moved to the wrong place (live IDs now pay for the archive scan)
**Classification:** Micro (fixed per-ID process cost plus a full scan of both files) / Cold path (one call per cycle)
**Confidence:** High
**Baseline:** P1, `perf24/p1.log`, 2026-10-02. A live ID on today's 186 KB archive went from 14–15 ms (ba39470) to **23–24 ms**, and on a synthetic 17 MB archive from 12 ms to **47–49 ms**. All 102 real IDs in one call: 904 → 1,024 ms. The awk program alone over 17 MB: 24 → 30 ms.
**Legibility-target:** maintainer

The cost change is the price of duplicate detection. A duplicate can only be found by reading past the first entry, and in the second file too, so the early `exit` that pass 23 (finding 2) offered as an option is now ruled out by design, and rightly so. The per-ID cost is still dominated by about six forks per file per ID, not by the scan. Batches cost the same at today's size (89 IDs: 849 → 848 ms) and about 14% more at 17 MB (3,275 → 3,740 ms). At the skill's N this is well under 100 ms. The 120 s cliff would need thousands of IDs against a multi-megabyte archive.

**Recommendation:** None needed for merge. If batches ever grow: one awk pass over both files for all IDs (`-v ids=…`, with per-ID counters) would make a call O(total file size), with forks independent of N.

#### 2. Every check-mode call now pays the default-branch lookup, and the modes fail where no default branch resolves

**Severity:** Informational (cost). The behavior change is for the API-consistency and security critics to grade. Preconditions: cost, none; failure, a repo with no resolvable default branch (detached HEAD with no `main`/`master`/`origin/HEAD`, or an unborn repo). Confidence: High (measured).
**Location:** `scripts/dev-cycle.sh:344-377` (A, c1d0a80)
**Evidence (verbatim):**
```bash
[[ -n "$MAIN_SHA" ]] || { echo "Could not resolve a default branch (tried origin/HEAD, main, master, the current branch)" >&2; exit 1; }
# The check modes run here: --check-branch refuses the default branch by name.
if [[ -n "$CHECK" ]]; then
```
(This is `:364-366`. The block goes on to dispatch each argument (`:367-376`) and ends with `exit 0` at `:377`. The lookup it now follows is `:344-363`: one `symbolic-ref`, then `show-ref --verify --hash` + `rev-parse --verify --quiet "$sha^{commit}"` per candidate, then the current branch.)
**Move:** Find the work that moved to the wrong place (a per-run lookup now runs per check call)
**Classification:** Micro / Cold path
**Confidence:** High
**Baseline:** P2, `perf24/p2.log`, 2026-10-02. Single-argument calls rose by about 4 ms each: `--check-write` 9–10 → 13–17 ms, a refused `--check-fix` 7–8 → 11–16 ms, `--check-branch` 10–11 → 15–17 ms. 100 names in one call: 287 → 289 ms, because the lookup runs once per call. Where no default resolves, the new script exits 1 with one stderr line, where the old one printed `ok …`.
**Legibility-target:** agent

The cost is a fixed ~4 ms per call, once per batch, so it does not matter. On the failure question the brief asks about ("acceptable?"): in ba39470 the digest already exited at this same line in such repos. A cycle cannot run there at all, so the check modes failing there loses nothing the skill uses. The output is a single stderr line with rc 1, not a stream, so the agent's context is not at risk. The behavior trade, `--check-branch` refusing the default branch by name in return for the modes needing one, belongs to the other lanes.

**Recommendation:** None for performance.

#### 3. `briefs/closed/` grows without bound, and the slug-uniqueness rule names no way to check it; its glob is capped at the oldest 50

**Severity:** Informational. Preconditions: more than 50 closed briefs, *and* an agent that checks uniqueness with the `closed/*.md` glob rather than per name, *and* a new brief whose date and slug match a closed one's. Brief names start with their write date, so a collision needs a brief written today that is also already closed, which is practically nil. `git mv` refuses an existing destination in any case (P3). Confidence: High on the mechanism (measured), High that the impact is negligible.
**Location:** `skills/dev-cycle/SKILL.md:291-292` (B, fb643e2). Closing is at `:254`; the cap is at `scripts/dev-cycle.sh` `check_path` (A, c1d0a80, `max=50`).
**Evidence (verbatim):**
```markdown
letters, digits and hyphens only (a file name no brief has used before, in `briefs/` or
`briefs/closed/`; add `-2`, `-3` if it is
```
(This is `:291-292`. The sentence continues at `:293`, "taken): `Status: open`, the line \"repo …", and goes on to list the brief's fields. It names no check for "used before". Closing, `:254`: "Either way, `git mv` the brief to `docs/working/briefs/closed/` (same file name; its destination passes `--check-write`)".)
**Move:** Ask "what's the size of N?"
**Classification:** Macro (an unbounded directory read through a fixed cap) / Cold path (at most 3 lookups per cycle)
**Confidence:** High
**Baseline:** P3, `perf24/p3.log`, 2026-10-02, with 1,000 closed briefs. `--check-path 'docs/working/briefs/closed/*.md'` took 335–339 ms and listed the oldest 50, then `skip …: matches more than 50 files`. A literal `--check-path docs/working/briefs/closed/<name>.md` took 20–21 ms and answered correctly whether or not the name was used.
**Legibility-target:** agent

This is the residue of pass 23's finding 1 after its fix. The open listing is now bounded (finding 1 is fixed; see Endorsements), but the unbounded directory moved to `closed/`. Nothing on a per-cycle path reads it as a whole. The one rule that refers to it leaves the method open. The cheap and exact method is a per-name probe: a `skip … no tracked file … matches` from `--check-path` on the literal candidate path means the name is free, and it costs 20 ms whatever the size of `closed/`. A glob would cost more, cut the newest names, and push up to 50 lines into the agent's context.

**Recommendation:** Optional. Name the per-name check in `:291-292`, e.g. "(free when `--check-path` on `docs/working/briefs/<name>` and on `docs/working/briefs/closed/<name>` both skip it)". No script change is needed.

## Endorsements

- Pass-23 finding 1 is fixed. With 1,000 closed briefs moved to `briefs/closed/` and 3 open ones, `--check-path 'docs/working/briefs/*.md'` takes 28–29 ms and lists exactly the 3 open briefs. The glob does not descend into `closed/`, so the listing is bounded by the 3-slot limit, not by history. `[unverified — submitted as claim]` (my execution, P3)
- `--check-answer`'s rewrite changes the reading of exactly three real entries, Q-070, Q-071 and Q-073 (`unrecognized` → `keep`). Every other one of the 102 real IDs in wt-devcycle's current questions files reads the same as at ba39470, with 0 stderr lines, and a cross-file duplicate is reported as a skip naming both files. `[unverified — submitted as claim]` (my execution, P1, diff of both versions' outputs)
- `--check-branch`'s peel to a commit adds no cost for absent names (100 names: 287 → 289 ms), and the default-branch refusal costs no git call beyond the shared lookup. `[unverified — submitted as claim]` (my execution, P2)
- The help range `sed -n '2,53p'` covers the whole header: line 52 is the last comment line and line 53 is blank. `[read: scripts/dev-cycle.sh:50-53,116]`
- The suite is 36/36 ok at c1d0a80 in 9.6 s. `[unverified — submitted as claim]` (my execution, P4)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--check-answer` reads both files in full for every ID (live ID 14 → 24 ms on today's archive; 12 → 48 ms at 17 MB); it is the price of duplicate detection | Informational | `scripts/dev-cycle.sh:328-341` (A) | High |
| 2 | Check modes pay the default-branch lookup (~4 ms per call, once per batch) and exit 1 where no default resolves, as the digest already did | Informational | `scripts/dev-cycle.sh:344-377` (A) | High |
| 3 | `briefs/closed/` grows unbounded; the uniqueness rule names no check, and the `closed/*.md` glob is capped at the oldest 50 (per-name probe: 20 ms) | Informational | `skills/dev-cycle/SKILL.md:291-292` (B) | High |

## Overall Assessment

The fix round is sound from a performance standpoint. It closes the one Medium from pass 23 (finding 1): moving closed briefs to `briefs/closed/` bounds the open-brief glob by the 3-slot limit, and with 1,000 closed briefs the listing still takes under 30 ms and returns exactly the open ones. The new costs are small, deliberate and cold-path. `--check-answer` must now read both files to the end to detect duplicates, which costs about +10 ms per live ID on today's archive and changes batches by 0–14%. The check modes now share the default-branch lookup, a fixed ~4 ms per call. The only structural residue is that the unbounded directory has moved to `closed/`. Nothing per cycle reads it whole, but the slug-uniqueness rule should name the 20 ms per-name probe so that no agent reaches for the capped glob. All three findings are Informational. None blocks merge, and no further benchmarking is needed.

## Goal-Alignment Note

Success criterion, restated verbatim: "a markdown report saved at the path your role instructions give, structured per your skill file."
- **Path:** saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-02-digest-pass24.md`, first line `Commit: c1d0a80 (A) / fb643e2 (B)`.
- **Structure:** follows the performance-reviewer layout: header, no-fact-check warning, data flow and hot paths, findings, evidence-tagged endorsements (≤5), summary table and overall assessment. Each finding carries Severity (with preconditions and confidence), Location, verbatim Evidence with truncation notes, Move, Classification, Confidence, Baseline and Legibility-target.
- **Coverage of the brief's scope:**
  - `--check-answer` was re-measured against ba39470 with pass 23's generator at 1×, 10× and 100× (live, archived and absent IDs; 10 and 100 per call; all 102 real IDs). Readings were diffed (only Q-070/071/073 change), and a cross-file duplicate was exercised.
  - All six check modes were timed after the lookup move, with and without `origin/HEAD`, and in detached and unborn repos.
  - The `briefs/closed/` listing was measured at 1,000 closed briefs (open glob, closed glob, literal probes, `--check-write`/`--check-brief` on `closed/`, `git mv` collision). The bats suite and the help range were checked too.
  - Rules found correct and complete for performance: the open-brief glob's bounding by `closed/`; `--check-branch`'s peel and default-branch refusal (no extra cost for absent names); `--check-fix` refusing before any git call; the keep-or-drop `rev-list --count` (O(commits ahead), once per brief).
- **Probe rule:** followed. Every probe is self-contained under `perf24/`, every process ran under `timeout`, and nothing outside the temp dirs changed except this report.
- **Not committed**, per instructions.
