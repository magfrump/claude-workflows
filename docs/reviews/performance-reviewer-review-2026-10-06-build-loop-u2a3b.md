Commit: 7ddff454

# Performance Review: feat/build-loop-u2a3b (U2a3b, iteration 2, loop pass)

**Scope:** `git diff 45ad17b0..7ddff454 -- scripts test` (commits 1ccc8b65 and 7ddff454). Code under review is in `scripts/lib/dev-cycle-read.sh`: `import_targets` (:500-519), `instruction_names` (:524), `imported_names` (:528-553), `main_imports`' lower guard (:622) and `isimported` (:634-643). The enclosing functions :440-650 were read whole, and so was `check_fix` (`scripts/dev-cycle.sh:170-183`), the only caller outside tests.
**Date:** 2026-10-06
**Based on:** the Stage-1 report `docs/reviews/code-fact-check-report-build-loop-u2a3b-i2.md` (25 claims: 22 verified, 3 mostly accurate, none about performance) and the shared context `u2a3b-shared-i2.md`. Override rows 346, 355 and 363 are settled. They are cited below where relevant and are not re-filed.
**Legibility-target:** for-orchestrator-synthesis

**Measurement setup.** All numbers were measured on 2026-10-06 in the scratch dir `/tmp/u2a3b-perf-ezVa/`:
- `repo/` is a `git clone --no-hardlinks` of this worktree, detached at 7ddff454. It has 2,968 tracked files, 45 of which pass `instruction_names`. Those 45 start files hold 735,750 bytes, and the new `IMPORT_RE` finds 4 tokens in them (the old one finds 3).
- `v-45ad17b0/` and `v-7ddff454/` hold `git archive` copies of `scripts/` at each commit. Both versions ran against the same `repo/`.
- The timing scripts are `drv.sh` (whole `imported_names`), `bench.sh` / `bench2.sh` (`import_targets` alone; `bench2.sh` also counts `realpath` forks through a wrapper function), `mem.sh` (VmHWM) and `sedb.sh` (sed and capture parts).
- The synthetic inputs are:
  - `tok1000.md`: 1,000 tokens over six forms (plain, `**…**`, link, `.`-ended, code span, `<br>`).
  - `plain200.md`: 200 plain tokens.
  - `big5mb.md`: 5 MB of prose with no token.
- Timings use bash `$EPOCHREALTIME`, with `LC_ALL=C`, GNU bash 5.2.15 and GNU sed 4.9. Load average was 1.3-2.5.
- Every process ran under `timeout`, and none remains.

## Data Flow and Hot Paths

- **`check_fix`** (`scripts/dev-cycle.sh:181`) is the only non-test caller of `isimported`. **Path temperature: cold.** It is a CLI check that the dev cycle runs per proposed in-cycle fix. The walk runs at most once per process, cached in `IMPORTED_DONE` (`:531`). `main_imports` has no caller outside the lib and tests at this commit.
- **`imported_names`** (`:528-553`) runs in three phases:
  1. The start listing (`:534`). It is now captured into `recs` by `mapfile`, with the same three commands as before: `git ls-files`, `untracked_md` and one `instruction_names` grep.
  2. One `lower` fork and one `inrepo_here` per start name (`:536-541`). This is unchanged, and row 355's per-edge costs apply.
  3. The queue walk, which makes one `import_targets` call per file reached (`:546`).
- **`import_targets`** (`:500-519`) does the following per file:
  1. It builds a 20-expression sed array (`:501-502`).
  2. It makes one `sed` capture (`:504`) and one here-string `grep` capture (`:505`). At 45ad17b0 this was a single streaming `grep` in a process substitution.
  3. **Per token**, it makes two candidates (`c`: whole and Markdown-cut). Each candidate has two forms (`w`: as is and stripped). Each form is one `realpath` fork (`:513`). Only then does the per-token dedup string `n` (`:514`) drop a repeat.

Measured:

| What | 45ad17b0 | 7ddff454 |
|---|---|---|
| `imported_names`, this repo, 5 runs (`drv.sh`) | 458-493 ms (median 478) | 586-681 ms (median 643) |
| `--check-fix docs/thoughts/x.md`, whole script, 2-3 runs | 483-588 ms | 688-713 ms |
| `import_targets` summed over the 45 walked files (wrapper timing) | 126 ms | 220 ms |
| `import_targets`, empty file, mean of 200 calls | ~1 ms | ~3 ms |
| `import_targets`, 103 KB `skills/code-review/SKILL.md`, no token | 2-3 ms | 8-9 ms |
| `import_targets`, one plain token, mean of 200 calls | ~4 ms | ~13 ms |
| `import_targets`, `plain200.md` | 271 ms, 200 `realpath` forks | 932 ms, **800 `realpath` forks**, 200 names |
| `import_targets`, `tok1000.md` | 1,823-2,321 ms, 1,334 forks | 4,552-6,799 ms, **4,000 forks**, 1,833 names |
| `import_targets`, `big5mb.md` | 3 ms; VmHWM 3,288 kB | 189 ms; VmHWM 28,840 kB |
| sed parts on `big5mb.md` (`sedb.sh`) | | 20-expr sed 71 ms vs 1-expr 11 ms; capture 115 ms; here-string grep 69 ms |
| `realpath` forks across the whole repo walk (includes `inrepo_here`'s) | 175 | 190 |

## Findings

#### F1. Every import token now pays four `realpath` forks, even a plain one, because the dedup runs after the fork

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:509-515`
**Move:** Count the hidden multiplications
**Classification:** Micro (a constant 4x fork count per token) / Cold path (once per `--check-fix` process; `check_fix` at `scripts/dev-cycle.sh:181`, cached at lib `:531`)
**Confidence:** High
**Baseline:** `import_targets` on `plain200.md` (200 plain `@docs/pN.md` tokens). It took 932 ms with 800 `realpath` forks at 7ddff454, against 271 ms with 200 forks at 45ad17b0 (`/tmp/u2a3b-perf-ezVa/bench2.sh`, 2026-10-06).

**Evidence:**
```
    for c in "$t" "${t%%[][()<!*_"$b"]*}"; do  # b: a backtick, written as \x60
      v="$c"; while [[ "$v" == *[.,\;:!?*_~\)\]] || "$v" == *"$b" ]]; do v="${v%?}"; done
      for w in "$c" "$v"; do
        [[ -n "$w" && "$w" != \~/* && "$w" != /* ]] || continue
        p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$w" 2>/dev/null)" || continue
        [[ "$p" != .. && "$p" != ../* && "$n" != *$'\n'"$p"$'\n'* ]] || continue
        n+="$p"$'\n'; printf '%s\n' "$p"
      done
    done
  done <<<"$toks"
}
```
(excerpt :509-519 ends at the function's close; the token loop starts at :506)

For a plain token, `c` takes the same string twice, and `v == c` each time. So all four `w` values are identical. Each one forks `realpath`, and then three of them are discarded by the `n` check at :514. 45ad17b0 avoided this with `[[ "$v" != "$t" ]] || break`, which this diff removed. On `tok1000.md`, 2,167 of the 4,000 forks (54%) produced no output.

In this repo the effect is not measurable: 4 tokens, about 12 extra forks, and the walk times with and without the fix overlap (577-618 ms vs 593-680 ms, 3 runs each). The cost grows with the number of tokens in walked files.

Row 363 settled the second probe of a *punctuation-ended* token's whole name. This finding is different: it is three redundant forks on *every* token, including plain ones that 45ad17b0 forked once.

**Recommendation:** Dedup on the candidate string before the fork. A scratch mutant (`/tmp/u2a3b-perf-ezVa/v-fix/`) adds `tried=$'\n'` per token and `&& "$tried" != *$'\n'"$w"$'\n'*` plus `tried+="$w"$'\n'` at :512. With it, `plain200.md` takes 237 ms with 200 forks, and `tok1000.md` takes 2,120 ms with 1,833 forks. Its output was byte-identical (md5) to 7ddff454's on both inputs. A real patch would add `tried` to the function's `local` list. The mutant was not run against the bats suites.
**Legibility-target:** for-orchestrator-synthesis

#### F2. Fixed per-file parser cost rose about 2 ms, which made the repo walk about 165 ms (35%) slower

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:501-505`
**Move:** Find the work that moved to the wrong place
**Classification:** Micro (a fixed cost per walked file) / Cold path (as F1)
**Confidence:** High
**Baseline:** `imported_names` on this repo had a median of 478 ms at 45ad17b0 and 643 ms at 7ddff454, 5 runs each (`/tmp/u2a3b-perf-ezVa/drv.sh`, 2026-10-06). `import_targets` summed over the 45 walked files went from 126 ms to 220 ms.

**Evidence:**
```
  local t c v w p u n toks b=$'\x60' s=(-e 's/\x0/ /g')
  for u in "${UNI_SPACES[@]}"; do s+=(-e "s/$u/ /g"); done
  # Two steps, not a pipe: under pipefail grep's "no match" would hide a sed failure.
  toks="$(env LC_ALL=C sed "${s[@]}")" || return 1
  toks="$(env LC_ALL=C grep -aoE "$IMPORT_RE" <<<"$toks")" || [[ $? -eq 1 ]] || return 1
```
(excerpt ends :505; import_targets continues to :519, the token loop F1 quotes)

Each file now costs two command substitutions, an `env`+`sed` fork and an `env`+`grep` fork, where it used to cost one streaming `grep`. The per-call cost on an empty file went from about 1 ms to about 3 ms, and on the 103 KB start file from 2-3 ms to 8-9 ms. With 45 walked files, that accounts for most of the measured +165 ms.

The two-step shape is deliberate: the comment at :503 gives the reason, which is to keep sed's exit status visible. The cost is a few tenths of a second on a cold CLI check, so no change is needed now. Row 346's batching rework (one pass over all walked files) would remove it, and its revisit trigger already covers this.
**Legibility-target:** for-orchestrator-synthesis

#### F3. A large walked file is now held whole in bash and passed through a 20-expression sed: 60x slower and 9x the memory on 5 MB

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:502-505`
**Move:** Trace the memory lifecycle
**Classification:** Micro (linear in file size, with a larger constant) / Cold path (as F1). Instruction files here average 16 KB, and the largest is 103 KB.
**Confidence:** High
**Baseline:** `import_targets` on a 5 MB token-free file took 189 ms with VmHWM 28,840 kB at 7ddff454, against 3 ms and 3,288 kB at 45ad17b0 (`/tmp/u2a3b-perf-ezVa/bench.sh` and `mem.sh`, 2026-10-06).

**Evidence:** the same lines as F2. The `toks="$(… sed …)"` line holds the whole rewritten file in a bash string, and `<<<"$toks"` writes it back out to grep. The old code streamed stdin straight into `grep -aoE` and kept only the matches. On `big5mb.md` (`sedb.sh`), the parts were:
- the 20 `-e s/…/ /g` expressions: 71 ms, against 11 ms for one expression;
- the capture into bash: 115 ms;
- the here-string grep: 69 ms.

An instruction file is the only kind of file walked, and a multi-MB one is unlikely, so this is informational only. If it ever matters, one fix covers both costs: a single alternation expression (`s/(\x0|\xc2\xa0|…)/ /g` with `-E`), piped into grep through a temp file or a `pipefail`-checked group instead of a captured variable.
**Legibility-target:** for-orchestrator-synthesis

## Settled rows touched by this diff (not re-filed)

- **Row 355** (each import edge forks `lower`; the queue pop is O(q²)). The diff adds more emitted names per token. On `tok1000.md`, 1,334 names became 1,833 (+37%). Each extra name pays row 355's `lower` fork in `imported_names` (:549), plus an `inrepo_here` unless it has been seen. On this repo that is 3 extra `IMPORTED` lines. The trigger (1,000+ walked files) is not met.
- **Row 363** (punctuation-ended tokens' extra probes). F1 is the new, broader instance, because the redundant forks now hit every token.

## What's Done Well

- The start listing is still one `git ls-files`, one `untracked_md` and one `instruction_names` grep. `mapfile` only captures the same NUL records (plus a `rc=` sentinel) that the old loop streamed, so the fork count is unchanged. The `lower` and `inrepo_here` calls per start name stay at one each. `[read: scripts/lib/dev-cycle-read.sh:524-541]`
- The per-token dedup string `n` is reset for every token (:508). It holds at most four lines, so the `*$'\n'"$p"$'\n'*` match cannot grow with file size. `[read: scripts/lib/dev-cycle-read.sh:506-515]`
- A failed tree walk is cached as `IMPORTED=error` for its `ROOT_REAL`, so a second `isimported tree` in the same process does not walk again. `[fact-check: claim 13 — verified]`
- The UNI_SPACES handling moved from 19 in-shell `${t%%"$u"*}` cuts per token to one sed pass per file. The claim is that per-token cost then no longer scales with the size of the UNI_SPACES list. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Four `realpath` forks per token, dedup after the fork (plain200: 800 forks / 932 ms vs 200 / 271 ms; a pre-fork dedup mutant gets 200 / 237 ms with identical output) | Informational | `scripts/lib/dev-cycle-read.sh:512-514` | High |
| F2 | Two command substitutions + `env sed` + `env grep` per file; repo walk median 478 → 643 ms | Informational | `scripts/lib/dev-cycle-read.sh:504-505` | High |
| F3 | Whole file held in bash, 20-expr sed; 5 MB file 3 → 189 ms, VmHWM 3.3 → 28.8 MB | Informational | `scripts/lib/dev-cycle-read.sh:502-505` | High |

## Overall Assessment

The change makes the cold `--check-fix` walk about 35% slower on this repo (median 478 → 643 ms), and nothing here blocks the merge. F1 is the item worth fixing in place. The new nested candidate loop forks `realpath` four times per token and dedups only afterward. That undoes the one-fork-per-plain-token behavior 45ad17b0 had through its `break`. The fix is two lines, and a scratch mutant shows it brings fork counts back to one per distinct name with byte-identical output. Its benefit only shows in files with many tokens, though: this repo has 4 tokens. F2 and F3 are the price of the deliberate sed-then-grep shape that keeps sed's failure visible. The batching rework already deferred under rows 346, 355 and 363 would remove them. No profiling is needed beyond what was measured here.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved at the output path named in your role section below, structured per your skill, with a `Commit: 7ddff454` line at the top.
- **Answered:** yes. The dispatch asked for measured `isimported tree` / `--check-fix` times at 45ad17b0 and 7ddff454 rather than estimates. Both are in the table, along with per-mechanism measurements:
  - the per-file sed and grep;
  - candidates and `realpath` per token;
  - the dedup string;
  - the `mapfile` start listing.
- **Out of scope:** running the bats suites against the F1 mutant (output identity was checked on two synthetic inputs only). The `main_imports` walk was not timed separately: it shares `import_targets`, so F1-F3 apply to it per blob, and it has no non-test caller at this commit. No U2a3 (context) defect was found in `main_imports`' own code.
- **Escalate:** none. All three findings are Informational on a cold path.
- **Decisions I made:**
  - I filed F1 as new rather than under row 363. Row 363 prices one extra probe for punctuation-ended tokens. F1 is three redundant forks on every token, a regression from 45ad17b0's `break`.
  - I kept F1 at Informational (Micro × Cold) even though it is a 4x factor, because the measured effect on this repo is within run-to-run noise.
