Commit: 90364c73 (main; delta 6f3d55e..5652d33f / 2fd9401..2da55741)

# Performance Review — dev-cycle pass 38 (digest + skill delta, post-merge)

**Scope:** A `git diff 6f3d55e..5652d33f -- . ':!docs/reviews'`, B `git diff 2fd9401..2da55741 -- . ':!docs/reviews'` (scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats); B contains A.
**Date:** 2026-10-02
**Based on:** `docs/reviews/code-fact-check-report-2026-10-02-digest-pass38.md` (Stage 1; its Escalation to performance-reviewer, P5) and shared brief `/tmp/claude-1000/pass38-orchestrator/brief.md`.
**Probes:** P1–P5 in `/tmp/claude-1000/pass38-perf/` (`p2.sh`, `p3.sh`, `p4.sh`, `p5.sh` carry the cited numbers; P1 failed on a missing `/usr/bin/time`/`bc` and gave no numbers). Each ran under `timeout`, in its own `mktemp -d -p` dir, against a clone of /workspace or a fresh `git init`. Times are wall-clock (`TIMEFORMAT=%R`) on this WSL2 host.

## Data Flow and Hot Paths

`--check-fix PATH...` is a CLI check that the dev-cycle skill calls while it runs a cycle. Each call is a fresh `bash` process. The first `check_fix` in a process calls `imported_names()` (`scripts/dev-cycle.sh:425-447`), which is memoized for that process only (`IMPORTED_DONE`, `:427`; fact-check Claim 8, executed). The walk has two phases:

1. **Seed phase (`:428-434`).** For every path that three `git ls-files` producers list, it forks `lower` (`:424`, `printf | tr` in a command substitution) on the basename, *before* the instruction-file test. The producers list all tracked files, all untracked `*.md`, and all ignored `*.md`. Matching names then pay `inrepo` (`blocker` → one `realpath` fork per directory component plus one for the file) and a `seen` string-glob test.
2. **Walk phase (`:435-446`).** It dequeues by copying the array (`:436`). Every `@` token pays one `realpath -ms` fork (`:442`) and one `lower` fork (`:444`). A token not yet seen also pays `inrepo` (`:445`).

**Path temperature: cold, but over the whole file list.** It is a CLI check, a few calls per cycle. Fact-check Claim 22 puts it at about 7 batched check calls per cycle across all modes, with `--check-fix` among them. An agent waits synchronously on each call. Its cost scales with repository size (tracked files plus untracked and ignored `.md`), not with its arguments. That is the hot-path gate's "cold path that runs over large data" exception.

**Realistic sizes, counted read-only in /workspace:**

| What | Count |
|---|---|
| Tracked files | 2,757 |
| `--others` `*.md` | 488 |
| `--others --ignored --exclude-standard` `*.md` | 525 (487 files; the rest are nested-repo directory entries under `external/`) |
| Instruction-named files | 79 |
| `@` tokens matching `IMPORT_RE` across those files | 2 |

So /workspace's walk phase is negligible, and the seed phase is the whole cost.

## Findings

#### F1. Seed phase forks `lower` once per listed path, so `--check-fix` costs about 1 ms per file in the repo

**Severity:** Medium
**Location:** `scripts/dev-cycle.sh:424`, `:428-434` (in scope: the whole of `imported_names()` arrives in delta B; 5652d33f added the two untracked producers)
**Move:** Hidden multiplication; size of N
**Classification:** Macro (cost linear in repository file count, one process fork per file, independent of the arguments) / Cold path over large data (CLI check, run synchronously several times per cycle)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** 5.12–5.22 s wall-clock per `--check-fix README.md` call on a /workspace-shaped clone (P5, 2026-10-02, three runs), against 0.015 s at 2fd9401 and 3.44–3.48 s at 6f3d55e on the same clone.

Evidence (`:429`, inside the `while read -r -d '' f` loop, which runs once per producer line):

```
    if [[ ! "$(lower "${f##*/}")" =~ $INSTRUCTION_FILE ]] || ! inrepo "$f"; then continue; fi
```

The loop is fed by `done < <(git ls-files -z` / `... --others -- ':(glob,icase)**/*.md'` / `... --others --ignored --exclude-standard -- ':(glob,icase)**/*.md')` (`:432-434`). The excerpt stops at the loop test; the rest of the loop is the `seen` test and the enqueue (`:430-431`), which only instruction-named files reach.

Measured costs:

- **One fork.** 1,000 `lower` calls take 1.00 s (P2). `realpath` takes 0.63 ms per call.
- **/workspace-shaped clone, one call (P5):**

  | Script version | Wall-clock |
  |---|---|
  | 2fd9401 | 0.015 s |
  | 6f3d55e (per-tracked-file fork) | 3.45 s |
  | 5652d33f | 5.16 s |

  The 5652d33f row is about 3,730 forks.
- **Growing ignored trees (P3, one call):**

  | Ignored `.md` under `node_modules/` | 6f3d55e | 5652d33f |
  |---|---|---|
  | 1,001 | 3.38 s | 5.97 s |
  | 4,001 | 5.12 s | 12.75 s |

  The fact-check's P5 measured 9.7–11.5 s on a small repo with 4,000 ignored `.md`.
- **Variant (P3).** I prefiltered the producers with one `env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$'` and dropped the third producer. That variant took 0.34–0.36 s in all three configurations. It gave the same verdict as 5652d33f (`skip docs/imp1.md: an instruction file imports it…`) for imports from both a gitignored root `CLAUDE.local.md` and `node_modules/p/AGENTS.md`.

**Failure scenario, extrapolated from the measured 1 ms/fork, not run:**

- A JS monorepo with 20k tracked files and a `node_modules/` holding 10k README/CHANGELOG `.md` files would make each `--check-fix` call take about 40 s: 20k + 2 × 10k forks.
- A cycle that does not batch (the skill now says to batch, 91b88d7) pays this per call.

**Recommendation:** Filter names before forking. Pipe the producers through one `env LC_ALL=C grep -zaiE` on the basename, which stays locale-safe because the C locale makes `-i` ASCII-only. Alternatively, give `git ls-files` icase glob pathspecs for the instruction names. Either way, `lower` and `inrepo` then run only on the roughly 79 candidates. This keeps the current semantics and was measured at 0.34 s.

#### F2. The third producer lists every ignored `.md` a second time

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:433-434`
**Move:** Hidden multiplication
**Classification:** Micro (a constant 2× on the ignored subset) / Cold path over large data
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** about 1 ms per duplicated path (P2: 1,000 `lower` forks = 1.00 s). In /workspace, 487 ignored `.md` files are listed twice, roughly 0.5 s of the 5.16 s.

Evidence:

```
           GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'
           GIT_LITERAL_PATHSPECS=0 git ls-files -z --others --ignored --exclude-standard -- ':(glob,icase)**/*.md')
```

Without `--exclude-standard`, `--others` already lists ignored files. In /workspace the two lists differ only by the one non-ignored untracked file, which only the second producer lists, and by nested-repo directory entries such as `external/SWRBench2/`, which only the third lists and which are not files. Each duplicate pays `lower` before `seen` dedups it (`:429` runs before `:430`). A duplicated instruction-named file also pays `inrepo`'s `realpath` forks twice. The fact-check's Claim 5 relies on the second producer for gitignored `CLAUDE.local.md`, so dropping the third loses nothing. The P3 variant without it kept the ignored-file verdicts.

**Recommendation:** Delete the third producer, or keep it and give the second `--exclude-standard`. Either way, move the `seen` test before `lower`/`inrepo`. If F1's prefilter lands, this shrinks to a few duplicated candidates.

#### F3. Walk phase costs three or more forks per `@` token and per reached file

**Severity:** Low
**Location:** `scripts/dev-cycle.sh:437-446`
**Move:** Hidden multiplication
**Classification:** Micro (fixed forks per token) / Cold path
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** P4 (synthetic repo):

| Input | Wall-clock |
|---|---|
| 250 distinct `@` tokens in one `CLAUDE.local.md` | 1.07 s |
| 1,000 tokens | 4.23 s |
| 2,000 tokens | 9.78 s |
| 250-file transitive chain | 1.98 s |
| 1,000-file transitive chain | 7.97 s |

Evidence:

```
      p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$t" 2>/dev/null)" || continue
      [[ "$p" != ..* ]] || continue
      IMPORTED+="$(lower "$p")"$'\n'
      if [[ "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo "$p"; then seen+="$p"$'\n'; queue+=("$p"); fi
```

The loop's remainder is `done < <(env LC_ALL=C grep -oE "$IMPORT_RE" -- "$f" || true)` (`:446`), so there is one `grep` fork per file walked.

The cost is about 4–5 ms per token and about 8 ms per chained file. It is linear and bounded by the import text a repo actually contains. /workspace has 2 tokens, so the realistic cost here is around 10 ms. A repeated token is not deduplicated before its `realpath` and `lower` forks.

**Recommendation:** None needed at realistic sizes. If F1 is fixed, a later pass could compute `lower` once for the whole `IMPORTED` text at the end (one `tr` over the accumulated string) rather than once per token.

#### F4. The `seen` string-glob tests and the copy-on-dequeue queue are O(k²) in the number of instruction files

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:430`, `:436`, `:445`
**Move:** Asymptotic behaviour
**Classification:** Macro (quadratic) / Cold path, with k small in practice
**Confidence:** Medium (the excess over linear is inferred from timings, not profiled)
**Baseline:** P4 with 250, 1,000 and 2,000 ignored `SKILL.md` files and no imports:

| Ignored `SKILL.md` files | Wall-clock |
|---|---|
| 250 | 3.09 s |
| 1,000 | 13.08 s |
| 2,000 | 29.53 s |

The step from 1,000 to 2,000 files is 2.26×. The excess of about 3.5 s over linear is the quadratic part; the forks of F1/F2 plus `inrepo` dominate the rest at about 13 ms per instruction file.

Evidence: `[[ "$seen" == *$'\n'"$f"$'\n'* ]] && continue` scans a string that grows by one path per file, and `f="${queue[0]}"; queue=("${queue[@]:1}")` copies the remaining queue on every dequeue. With k = 79 in /workspace the quadratic term is unmeasurable. It reaches seconds only at thousands of instruction-named files, which would need something like a vendored skills or plugin tree under an ignored directory.

**Recommendation:** If it is ever touched, use an associative array (`declare -A seen`) and an index cursor (`for ((i=0; i<${#queue[@]}; i++))`). Do not change it for performance alone.

## Endorsements

- 5652d33f replaces 6f3d55e's two forks per existing brief in `check_brief` (`git cat-file -t`, then `git ls-tree | cut`) with one `git ls-tree | cut`, because the empty-mode case now answers "new". [read: scripts/dev-cycle.sh:355-361 and diff-A-digest.patch hunk @@ -352,9 +352,10 @@]
- `imported_names()` runs at most once per process for any number of `--check-fix` arguments, so the batching rule added in 91b88d7 ("batch a step's values into one call per mode") also pays the F1 seed cost once per batched call instead of once per path. [fact-check: Claim 8 — Verified (executed, P2: 32 arguments answered from one walk)]
- In a real cycle, the skill's batching instruction cuts the number of `--check-fix` processes to one or two per cycle, which bounds F1's per-cycle cost to about 5–10 s in a /workspace-sized repo. [unverified — submitted as claim]
- The `%cd` date change (6f3d55e) is a format-string swap with no added git invocations. [read: diff-B-skill.patch hunks @@ -628,7 +677,7 @@, @@ -643,7 +692,7 @@, @@ -727,7 +776,7 @@]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Seed phase forks `lower` per listed path: 5.16 s per call in a /workspace-shaped clone (0.015 s at 2fd9401; 0.34 s with a one-`grep` prefilter); 12.75 s with 4k ignored `.md` | Medium | `scripts/dev-cycle.sh:424,428-434` | High |
| 2 | Third producer duplicates every ignored `.md` from the second (2× forks on that subset) | Low | `scripts/dev-cycle.sh:433-434` | High |
| 3 | 3+ forks per `@` token and per walked file: 4–5 ms per token; 2,000 tokens take 9.8 s | Low | `scripts/dev-cycle.sh:437-446` | High |
| 4 | `seen` string glob and the dequeue copy are O(k²) in instruction files; about 3.5 s excess at k = 2,000, unmeasurable at k = 79 | Informational | `scripts/dev-cycle.sh:430,436,445` | Medium |

## Overall Assessment

The delta's logic adds no unbounded work. The cost problem is the per-path process fork in the seed phase.

- **6f3d55e** introduced a `printf | tr` fork for every tracked file. That took `--check-fix` in a /workspace-sized repo from 0.015 s to 3.45 s.
- **5652d33f** extended the fork to every untracked and every ignored `.md`, and listed the ignored ones twice. That gives 5.16 s here, and the cost grows linearly with `node_modules`-style ignored trees (12.75 s at 4k ignored `.md`).

This is fixable in place without changing semantics. Prefilter the basenames with one locale-safe `grep -zaiE` and drop the redundant producer. That variant measured 0.34–0.36 s in every configuration tried, and it gave the same refusal for an ignored-file import. No further profiling is needed to act on F1. F3/F4 are bounded by how much `@` text and how many instruction files a repo actually has, and they are negligible in /workspace (79 files, 2 tokens).

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your role instructions give, structured per your skill file.
- Answered:
  - Saved at `/workspace/docs/reviews/performance-review-2026-10-02-digest-pass38.md` with the required first line. It has the skill's header, data flow, findings with Baseline/Classification lines, evidence-tagged endorsements, summary table and overall assessment.
  - Every escalated item is measured:
    - per-path `lower` fork: F1;
    - duplicate third producer: F2;
    - per-token `realpath` fork: F3;
    - `queue` dequeue and `seen` glob: F4.
  - Realistic preconditions were counted read-only in /workspace: 2,757 tracked files, 488 untracked/ignored `.md`, 79 instruction files, 2 tokens.
  - The rest of delta B has no performance-relevant change: the skill prose, tests, `ANSWER_AWK` cut and `%cd` dates.
- Out of scope:
  - Correctness of the import walk (`_`/`#`/symlink/absolute gaps), which the fact-check report and security-reviewer own.
  - Running a real cycle to count actual `--check-fix` calls.
  - Platforms other than this WSL2 host, where fork cost differs; macOS is typically slower per fork.
- Escalate:
  - Orchestrator: F1's recommended prefilter must keep the fail-safe semantics that the fact-check report and security-reviewer care about. Its pattern must accept the same basenames as `INSTRUCTION_FILE`, including `AGENT.md` and `.local`/`.override` suffixes. Whoever fixes the security items should land both changes together, so the regex is not edited twice.
  - Process note: one read-only count (`instr.txt`, a list of instruction-file paths) was written by redirect from a plain Bash call into `/tmp/claude-1000/pass38-perf/`, not from inside a probe script. It stayed in my lane's scratch dir, and nothing outside scratch and this report was written.
