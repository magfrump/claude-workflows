Commit: c10b972a

# Performance Review — feat/build-loop-u2b2 (U2b2, the gate's checkout)

**Scope:** `git diff main...HEAD` (scripts/build-loop.sh `checkout_gate`, `check_line`, the `check)` mode block; test and doc changes read for context only)
**Date:** 2026-10-08
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b2.md (Stage 1, k=1; Claim 14 timing)

## Data Flow and Hot Paths

`checkout_gate` (scripts/build-loop.sh:603-648, read whole) runs at most once per `--check` invocation, in the parent shell, only when the stricter policy is self-merge (`if [[ "$POLICY" == self-merge ]]; then checkout_gate || true; fi`, :726); `check_line` (:655-718, read whole) only reads the resulting `CHECKOUT_WHY` string per brief, so the cost does not multiply by brief count. Its checks run cheapest first and return on the first failure: local GIT_* variables, `HEAD == MAIN_SHA` (a loop's advisory run from its own branch exits here, before any listing), three `git config` reads, `ls-files -v`, `git status --untracked-files=no`, `ls-files --others` (no excludes), then `ls-tree -r -z` into a file, a bash `while read` loop over every record, and one `git hash-object --no-filters --stdin-paths` over every regular tracked file.

Path temperature: **cold**. `--check` is run by the orchestrator once per merge decision and by a loop as an advisory dry run (plan D6, docs/working/plan-build-loop-handoff.md:28, :83); nothing calls it per item or per request. Data sizes: this repo has 3,163 tracked files, ~70 MB working tree, 9 untracked entries.

Probe (synthetic repo in /tmp/perfu2b2-*, removed; git 2.39.5, bash 5.2.15, warm page cache, load average 0.22, no leftover busy processes): 50,002 tracked files (50,000 small text + one 200 MB random binary) and 100,000 ignored files under `node_modules/`:

| Step | Time |
|---|---|
| `git status --porcelain=v1 -z --untracked-files=no` | 0.015 s |
| `git ls-files -z --others` (no excludes; 2.5 MB listing) | 0.064 s |
| bash `while read -d ''` + regex loop over 50,002 `ls-tree` records | 1.435 s (~29 µs/record) |
| `hash-object --no-filters --stdin-paths`, all files incl. 200 MB binary | 1.238 s |
| same, without the 200 MB binary | 0.182 s |

In this repo, `ls-tree | hash-object --stdin-paths` measured 0.149 s (warm), consistent with the commit's 0.14 s; the fact-checker's 0.26 s for the whole step is within run-to-run and cache variance.

## Findings

#### Full-tree rehash reads every tracked byte on each self-merge --check

**Severity:** Low
**Location:** `scripts/build-loop.sh:644-647`
**Move:** Ask "what's the size of N?" / price the deployment environment
**Classification:** Macro (cost linear in total tracked bytes, not file count) / Cold path (once per `--check`, once per merge decision)
**Confidence:** High (mechanism and scaling); Medium (realistic repo sizes)
**Baseline:** 1.238 s for 50,002 files including one 200 MB binary, 0.182 s without it (synthetic probe above, warm cache, 2026-10-08); 0.149 s for this repo's 3,163 files.

Evidence (verbatim):
```bash
  if ! x="$(printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths 2>/dev/null)" || [[ "$x" != "$(printf '%s\n' "${ids[@]}")" ]]; then
    CHECKOUT_WHY="a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)"; return 1
  fi
```
Unlike `git status`, which trusts the index's stat data, this reads and SHA-1-hashes every regular file main stores, every run: about 190 MB/s warm here, so a repo carrying a few GB of tracked binaries would spend tens of seconds per `--check`, more on a cold cache. That is the price of the deliberate "checked by effect" design (the comment at :594-598 rejects predicting with check-attr), so it is not a defect; it is unbounded only in the sense that the repo's size bounds it. For this repo (70 MB working tree) it is well under a second. Note the work is done even when every brief in ARGS is a review brief, as long as the stricter policy is self-merge, since the gate runs before any brief is read.

**Recommendation:** No change needed for this repo. If a large-binary repo ever adopts the gate, the cheap lever is to skip the hash when no brief in ARGS is self-merge (it is computed before the per-brief policy is known); restricting the hash to paths whose attributes could convert would reintroduce the prediction the design rejects. Record the expected scaling (linear in tracked bytes) beside the existing timing comment.

#### Bash read loop over ls-tree records is ~29 µs per tracked file

**Severity:** Informational
**Location:** `scripts/build-loop.sh:630-640`
**Move:** Count the hidden multiplications
**Classification:** Micro (per-record bash `read` + `=~` + two array appends) / Cold path (once per `--check`)
**Confidence:** High
**Baseline:** 1.435 s for 50,002 records (synthetic probe above); proportionally ~0.09 s for this repo's 3,163.

Evidence (verbatim):
```bash
  while IFS= read -r -d '' r; do
    [[ "$r" =~ $re ]] || continue
    if [[ "${BASH_REMATCH[1]}" == 160000 ]]; then
      x="$(ls -A -- "${BASH_REMATCH[3]}" 2>/dev/null)" || x=""
      [[ -z "$x" ]] || { CHECKOUT_WHY="a gitlink is checked out with files, whose instruction files the walk does not read"; return 1; }
      continue
    fi
    [[ "${BASH_REMATCH[3]}" != *$'\n'* ]] || { CHECKOUT_WHY="a file on the default branch has a newline in its name"; return 1; }
    ids+=("${BASH_REMATCH[2]}"); ps+=("${BASH_REMATCH[3]}")
  done < "$GATE_TMP/tree"
```
Linear and bounded, but at bash speeds it exceeds the hashing cost it feeds for small-file repos (1.4 s vs 0.18 s at 50k files), so at ~500k tracked files it would be ~15 s. The `ls -A` subshell fires once per gitlink only (none on main today). Not worth changing at this repo's size.

**Recommendation:** None now. If the tree ever grows to six figures of files, one `awk`/`perl` pass over `$GATE_TMP/tree` emitting the path list and id list (and flagging gitlinks / newline names) would replace the per-record bash work.

#### Unexcluded `ls-files --others` walks every ignored tree

**Severity:** Informational
**Location:** `scripts/build-loop.sh:624-626`
**Move:** Ask "what's the size of N?"
**Classification:** Macro (cost linear in ignored-tree file count) / Cold path
**Confidence:** High (mechanism); Medium (cold-cache cost, not measured)
**Baseline:** 0.064 s and a 2.5 MB listing for 100,000 ignored files (synthetic probe above, warm cache); 9 entries in this repo.

Evidence (verbatim):
```bash
  git ls-files -z --others > "$GATE_TMP/others" || { CHECKOUT_WHY="its untracked files could not be listed"; return 1; }
  x="$(tr '\0' '\n' < "$GATE_TMP/others" | LC_ALL=C awk '/\/$/ { n++ } END { print n + 0 }')" || x=x
```
Without excludes git descends into every ignored directory (node_modules, build outputs) and writes each file to the temp file; the result is only scanned for `dir/` entries. Warm, this is cheap even at 100k files; cold on a large node_modules it is a directory walk of that tree. Listing to a file rather than holding it in a shell variable keeps memory flat. The listing is needed for its stated purpose (finding untracked nested repositories inside ignored trees too), so the cost is the design's.

**Recommendation:** None. If it ever matters, `--directory` would not suffice (it collapses untracked directories, hiding nested repos below them), so keep as is.

## Endorsements

- `checkout_gate` runs once per `--check` in the parent shell and `check_line` only reads `CHECKOUT_WHY`, so its cost does not multiply by the number of briefs. [read: scripts/build-loop.sh:603-648, 655-718, 720-733]
- The checks are ordered cheapest first and each returns on failure, so a loop's advisory `--check` from its own branch (HEAD is not main's commit) pays only `rev-parse --local-env-vars` and one `rev-parse` before returning. [read: scripts/build-loop.sh:609-616]
- Hashing uses a single `hash-object --stdin-paths` process for all files instead of one process per path, as the comment states. [read: scripts/build-loop.sh:644-645]
- The whole-tree hash completes in about 0.15-0.26 s on this repo's 3,163 files. [unverified — submitted as claim] (my warm run: 0.149 s for ls-tree + hash-object; fact-check Claim 14: 0.26 s, Mostly accurate)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Full-tree rehash reads every tracked byte per self-merge --check (linear in tracked bytes) | Low | `scripts/build-loop.sh:644-647` | High |
| 2 | Bash read loop over ls-tree records, ~29 µs/file | Informational | `scripts/build-loop.sh:630-640` | High |
| 3 | Unexcluded `ls-files --others` walks every ignored tree | Informational | `scripts/build-loop.sh:624-626` | High |

## Overall Assessment

The change is cold-path and bounded by the repository's own size: once per `--check`, cheapest checks first, one git process per expensive step. At this repo's scale the whole gate costs a fraction of a second. The only cost that scales notably is the deliberate full rehash (linear in tracked bytes), which would matter only in a repo carrying GB-scale binaries; the bash record loop becomes the dominant term only past ~100k tracked files. Nothing needs fixing before merge; no profiling is needed beyond the probe above.

## Goal-Alignment Note

The PR's goal is to make `--check` refuse a self-merge brief unless it runs from a clean checkout of main's commit, so U2c's floor walk can rely on that checkout. Nothing in the performance domain works against that goal: the gate's cost is a cold, once-per-run price proportional to the repo, paid in exchange for checking item 3 by effect rather than prediction, and the findings above are scaling notes, not blockers.
