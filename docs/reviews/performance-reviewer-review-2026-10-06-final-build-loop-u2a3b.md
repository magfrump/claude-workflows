Commit: e48cf0f7

# Performance Review: feat/build-loop-u2a3b (U2a3b, final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test docs/working` (main f6fdda68, HEAD e48cf0f7, four commits). I read these whole: `import_targets` (`scripts/lib/dev-cycle-read.sh:513-548`), `instruction_names`, `nul_list` and `tree_starts` (:554-561), `imported_names` (:563-589), `main_imports`' import loop and its lower guard (:657), `isimported` (:672-682), and `check_fix` (`scripts/dev-cycle.sh:170-185`).
**Date:** 2026-10-06
**Based on:** the Stage-1 summary `fc-final-summary.md`: k=3 replicates, nothing Incorrect, and no claim about performance. I also used the shared context `u2a3b-shared-i3.md` and this unit's iteration-2 performance review (`performance-reviewer-review-2026-10-06-build-loop-u2a3b.md`).
**Legibility-target:** for-orchestrator-synthesis

**Measurement setup.** All numbers were measured on 2026-10-06 in `/tmp/u2a3b-perff-C7te/`:
- `repo/` is a `git clone --no-hardlinks` of the worktree, detached at e48cf0f7. It has 3,022 tracked files, and 45 of them pass `instruction_names`.
- `v-main/` and `v-head/` hold `git archive` copies of `scripts/` at main and at e48cf0f7. Both versions run against the same `repo/`.
- `v-fix/` is HEAD's lib with the two changes recommended below.
- The scripts are `cf.sh` (whole `--check-fix`), `walk.sh` (`imported_names`, plus the summed `import_targets` time), `mainw.sh` (`main_imports`), `perfile.sh` (`import_targets` per start file), `bench.sh` (one `import_targets` call, with a `realpath` fork count and an md5 of the output), and `ops.sh` / `cutops.sh` (single bash operations in isolation).
- Software: GNU bash 5.2.15. Timings use `$EPOCHREALTIME` with `LC_ALL=C` unless a row says otherwise. Load average was 1.4-2.3 on 16 cores.
- WSL's clock jumped in 3 of about 60 walk runs (one negative time, and 3-4 s outliers). Those runs are left out below.
- Every process ran under `timeout`. None remains.

## Data Flow and Hot Paths

- **`--check-fix`** is a cold CLI check that the dev cycle runs once per proposed in-cycle fix (`skills/dev-cycle/SKILL.md:72`). Within one process:
  - `check_fix` now calls `imported_names` (`dev-cycle.sh:181`), then `isimported tree` (:183).
  - The second call hits the cache at lib :566 (`{ [[ "$IMPORTED" != error ]]; return; }`), so the walk runs once per process, as before.
  - No caller wraps the script in a timeout. The agent's tool timeout is the only bound. If the tool kills the script, it never prints `ok`, so the check refuses (fails closed).
- **`imported_names`**:
  - It lists its starts once through `nul_list recs tree_starts` (:568). That is the same three commands as before, so the start listing costs no extra forks.
  - It then makes one `lower` call and one `inrepo_here` call per start name. Both are unchanged and covered by row 355.
  - It makes one `import_targets` call per walked file (:581).
- **`main_imports`**: the lower guard at :657 replaces an identical `$(lower …)` fork, so it adds no fork. It uses the same `import_targets`, so both findings below apply to it per blob. It feeds U2a4's self-merge floor.
- **`import_targets`** works per file and then per token:
  - Per file: the 20-expression sed (settled, row 412/413) and the HTML-comment re-read (:519-526, new).
  - Per token: one prefix per cut mark (:534-546, new), a strip loop per prefix (:535), and two dedup strings, `cs` (:537-538) and `n` (:540-541).

Measured (main vs e48cf0f7):

| What | main | e48cf0f7 |
|---|---|---|
| `dev-cycle.sh --check-fix docs/thoughts/failure-patterns.md`, whole script (`LC_ALL=C.UTF-8`), 6 runs each | 413-462 ms | 663-854 ms |
| `imported_names`, this repo, `LC_ALL=C`, 6 runs each | 354-410 ms | 588-693 ms |
| `imported_names`, `LC_ALL=C.UTF-8`, 3 runs each | 380-419 ms | 646-702 ms |
| `import_targets` summed over the 45 walked files | 59-71 ms | 253-310 ms |
| …of which `skills/dev-cycle/SKILL.md` (25 KB, one unclosed `<!--` at byte 22,619) | ~2 ms | **102-107 ms** |
| `main_imports`, this repo, 3 runs each | 577-619 ms | 887-937 ms |
| `import_targets`, `tok1000.md` (200 lines × 5 token forms) | 3,438 ms, 1,400 forks | 4,870 ms, 2,000 forks |

## Findings

#### F1. The HTML-comment re-read is quadratic in the distance to a `<!--`: 100 ms on a 25 KB file in this repo, 2.9 s at 100 KB, 10 s at 200 KB

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:519-526`
**Move:** Check the asymptotic behavior (and Count the hidden multiplications)
**Classification:** Macro (O(m²) in the offset of each `<!--`, and O(n·k) over k comments) / Cold path (once per `--check-fix` process, cached at :566). It is already paid on every walk of this repo, though.
**Confidence:** High
**Baseline:** `import_targets` on `skills/dev-cycle/SKILL.md` takes 102-107 ms at e48cf0f7, against ~2 ms at main (`/tmp/u2a3b-perff-C7te/perfile.sh` and `walk.sh`, 2026-10-06).

**Evidence:**
```
  if [[ "$toks" == *'<!--'* ]]; then
    x="$toks"; y=""
    while [[ "$x" == *'<!--'* ]]; do
      y+="${x%%'<!--'*}"; x="${x#*'<!--'}"
      if [[ "$x" == *'-->'* ]]; then x="${x#*'-->'}"; else x=""; fi
    done
    toks+=$'\n'"$y$x"
  fi
```
(This excerpt ends at :526. `import_targets` continues through :548 with the grep and the token loop, and F2 quotes that loop. The `toks` value produced here is grepped at :529.)

Bash implements `${x#*'<!--'}` (shortest prefix removal with a leading `*`) by matching `*<!--` against every prefix of `x`. That is quadratic in the offset of the first `<!--`. `ops.sh` measured the expansion alone on m bytes followed by `<!--`:

| m | `LC_ALL=C` | `C.UTF-8` |
|---|---|---|
| 25 KB | 101 ms | 168 ms |
| 50 KB | 417 ms | 638 ms |
| 100 KB | 2.3 s | 2.5 s |
| 200 KB | 12.1 s | 11.9 s |

`${x%%'<!--'*}` is also superlinear: 175 ms at 200 KB.

End to end (`bench.sh`), `import_targets` timings were:
- `open25k` 177 ms;
- `closed100k` 2.9 s;
- `open100k` 2.9 s;
- `open200k` 10.3 s;
- `many100k` (900 closed comments spread through 100 KB) 1.07 s, because each iteration copies the rest of `x`.

At main, every one of these inputs took 2-4 ms.

The 25 KB start file in this repo already shows the cost: one call takes about 105 ms, roughly 40% of the walk's 190-230 ms regression. The rest of the regression is the per-file sed cost that row 412 settled. The largest start file here is 103 KB (`skills/code-review/SKILL.md`). One `<!--` near its end would add about 3 s to every `--check-fix`, and a similar amount to every `main_imports` that U2a4's floor runs.

The walk only gets slower, never less safe: the original text is still read first, and a killed process refuses.

**Recommendation:** Do the splice in one linear pass outside bash, forked only when `<!--` is present:

```
x="$(printf '%s' "$toks" | env LC_ALL=C perl -0777 -pe 's/<!--.*?(?:-->|\z)//gs')" || return 1
toks+=$'\n'"$x"
```

`dev-cycle.sh` already requires perl. In the scratch `v-fix/`, this gave the following, with md5-identical output to HEAD on three edge-case inputs (`cmt1-3.md`: `<!-->`, `<!---->`, adjacent and unclosed comments, tokens inside and around them) and on every synthetic input:
- `open100k`: 10 ms;
- `open200k`: 16 ms;
- `many100k`: 9 ms;
- `skills/dev-cycle/SKILL.md`: 9-12 ms.

If you keep the splice in bash, replace both `#*` removals with `h="${x%%'<!--'*}"; x="${x:${#h}+4}"`. That removes the quadratic term but keeps the O(n·k) copying.
**Legibility-target:** for-orchestrator-synthesis

#### F2. Per-token work is cubic in the token's cut-mark count: a 2 KB token takes 30 s, and a 4 KB token runs past 120 s

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:532-546` (dedup strings at :537-538 and :540-541; strip loop at :535)
**Move:** Ask "what's the size of N?" / Check the asymptotic behavior
**Classification:** Macro (O(L³) in a token's length when it holds L cut marks) / Cold path. An instruction file needs an unusual token to trigger it. Across all 3,310 `@` tokens in every tracked `.md` in this repo, the maximum is 16 cut marks.
**Confidence:** High
**Baseline:** `import_targets` on `cut1000.md`, one 2,003-byte line `@a_b_b…` with 1,000 cut marks:
- e48cf0f7: 29,774 ms, with 1,001 `realpath` forks.
- main: 7 ms, with 1 fork.
- `cut2000.md` (4 KB) at e48cf0f7 hit the 120 s timeout.

(`/tmp/u2a3b-perff-C7te/bench.sh`, 2026-10-06.)

**Evidence:**
```
    t="${t#*@}"; n=$'\n'; cs=$'\n'; r="$t"
    # r walks back through the token's prefixes, one per cut mark.
    while :; do
      v="$r"; while [[ "$v" == *[.,\;:!?*_~\)\]] || "$v" == *"$b" ]]; do v="${v%?}"; done
      for w in "$r" "$v"; do
        [[ -n "$w" && "$w" != \~/* && "$w" != /* && "$cs" != *$'\n'"$w"$'\n'* ]] || continue
        cs+="$w"$'\n'
        p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$w" 2>/dev/null)" || continue
        [[ "$p" != .. && "$p" != ../* && "$n" != *$'\n'"$p"$'\n'* ]] || continue
        n+="$p"$'\n'; printf '%s\n' "$p"
      done
      [[ "$r" == *$cut* ]] || break
      # shellcheck disable=SC2295  # $cut is the glob bracket, matched as a pattern
      r="${r%$cut*}"
    done
  done < <(printf '%s\n' "$toks")
}
```
(This excerpt runs from :532 to the function's close at :548.)

The cost comes from three places:
- **Forks.** A token with L cut marks yields L+1 distinct prefixes. Each one costs a `realpath` fork, so forks are linear in L: about 1.3 s at L=1,000.
- **The two dedup strings.** `cs` keeps every prefix, and `n` keeps every emitted path, so each grows to O(L²) bytes. Each membership test is a leading-`*` glob over that string. `cutops.sh` isolated the costs at L=1,000:
  - the cut loop alone: 21 ms;
  - with the strip loop added: 85 ms;
  - with the `cs` test added: 15.9 s, with `cs` at 1,003,003 bytes.
- **The strip loop.** It is O(j²) on a prefix ending in a run of j strippable marks. `cutu1000.md` (`@a` followed by 1,000 underscores) took 20.8 s at HEAD, against 34 ms at main.

A realistic way to hit this is minified CSS or JS without spaces (`@media(...)…!important…`) in an instruction file or an ignored `node_modules` instruction file that `untracked_md` lists. Nothing in this repo comes close. When the process is killed, the check fails closed, so the cost is a hung `--check-fix` rather than a fail-open.

**Recommendation:** Replace both newline-joined strings with associative arrays declared per token. `main_imports` already uses `seen[$p]`. In `v-fix/` this was `local -A cs=() n=()`, testing `-z "${cs[$w]+set}"` and `-z "${n[$p]+set}"`. With it:
- `cut1000` took 1,373 ms;
- `cut2000` took 3.1 s;
- `cut500` went from 3,937 ms to 617 ms;
- `tok1000` went from 4,870 ms to 2,404 ms.

The output was md5-identical to HEAD on every input. The test suites `build-loop-check.bats`, `build-loop-read.bats` and `dev-cycle.bats` passed 115/115 against `v-fix/`, which also carries F1's change.

What remains is linear forks plus the strip loop (`cutu1000` still takes 7.3 s). If adversarial instruction files are in scope, bound the work so that it fails closed. For example, `return 1` when a token holds more than some number of cut marks: the walk then refuses, which the threat model accepts.
**Legibility-target:** for-orchestrator-synthesis

## Settled rows touched by this diff (not re-filed)

- **Rows 412 and 413:**
  - Row 412 covers the two command substitutions per file, about 2-4 ms each.
  - Row 413 covers the whole file held through a 20-expression sed, and text holding `<!--` being read twice.
  - The remaining main→HEAD regression after F1 (`v-fix` walk 563-586 ms against main 389-410 ms) is that settled per-file cost. Both rows' triggers are unmet. The largest start file is 103 KB, not over 1 MB.
  - Row 413 settles reading the text twice. It does not settle the quadratic splice. F1 is new evidence: it is a complexity class, not a constant factor, and it costs about 100 ms on a file already in the repo.
- **Iteration-2 F1** (four `realpath` forks per plain token) is fixed: `cs` now dedups each candidate before its fork. `tok1000` makes 2,000 forks for 2,000 names, one fork per distinct name. F2 above is the cost of that fix's data structure at large L, not the same issue.
- **Rows 346, 355 and 363** (batching costs; `lower` per edge; extra probes): unchanged, and their triggers are unmet.

## Escalations from Stage 1

None of the Stage-1 escalations is addressed to performance-reviewer. The test-strategy gaps (cached error, `main_imports` lower guard) and the security note (a failing `tr` gives no wording) carry no performance cost. I took no action on them.

## What's Done Well

- `check_fix`'s added `imported_names` call does not walk twice: the following `isimported tree` returns from the cache. `[read: scripts/dev-cycle.sh:181-183, scripts/lib/dev-cycle-read.sh:563-566, 672-682]`
- `tree_starts` with `nul_list` runs the same three listing commands as main's start loop, plus one `printf rc=` sentinel. Moving the listing into `nul_list` adds no fork per start name. `[read: scripts/lib/dev-cycle-read.sh:554-569]`
- `main_imports`' lower guard at :657 reuses the `$(lower …)` substitution it replaces and adds no fork. `[read: scripts/lib/dev-cycle-read.sh:657]`
- `cs` dedups each candidate before its `realpath` fork, so a plain token forks once, as at main (`tok1000`: 2,000 forks for 2,000 names). `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | HTML-comment splice is quadratic (`${x#*'<!--'}`): 25 KB file in repo 2 → 105 ms; 100 KB 2.9 s; 200 KB 10.3 s; perl one-pass mutant 9-16 ms, identical output | Low | `scripts/lib/dev-cycle-read.sh:519-526` | High |
| F2 | Per-token prefix loop is cubic via `cs`/`n` glob-searched strings: 2 KB token 30 s, 4 KB > 120 s; associative-array mutant 1.4 s / 3.1 s, identical output, 115/115 | Low | `scripts/lib/dev-cycle-read.sh:532-546` | High |

## Overall Assessment

On this repo, the unit makes the cold `--check-fix` walk about 250 ms slower (whole script 413-462 → 663-854 ms; `imported_names` median about 365 → 600 ms in C). About 100 ms of that comes from F1, on one 25 KB start file with a single `<!--`. The rest is the per-file cost that rows 412 and 413 settled. Neither finding can fail open: slowness ends in a killed process, which refuses. Both are complexity-class regressions introduced by this unit, though, and both are fixable in place without changing output.

F1 is the one worth fixing before merge, because it is already paid here and grows quadratically with instruction-file size on both walks (U2a4's floor will run `main_imports`). The fix is a 2-line change, a single perl pass. F2 needs an unusual token, and the fix is to swap two strings for associative arrays. A fail-closed cap on per-token work would bound what remains. Beyond what is measured here, no profiling is needed.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: e48cf0f7` line at the top.
- **Answered:** yes. As the dispatch asked, these were measured against main, not estimated:
  - `--check-fix` on one path;
  - `imported_names` (and `main_imports`);
  - `import_targets` on large and token-heavy inputs;
  - the per-cut-mark prefix loop;
  - the comment re-read.
- **Out of scope:** the bats suites `fixture-git-env.bats` and `test/fixture-hermeticity.bats` were not run against `v-fix/`; the other three passed 115/115. I did not check `v-fix/`'s `local -A` keys `*` and `@` for bash subscript edge cases; a real patch should.
- **Escalate:** none. Both findings are Low and fail closed.
- **Decisions I made:**
  - I filed F1 despite row 413. Row 413 priced reading the text twice, and F1 is a quadratic term that row did not measure.
  - I rated both findings Low (Macro × Cold) and did not escalate them, because a kill refuses and no realistic token in this repo exceeds 16 cut marks.
