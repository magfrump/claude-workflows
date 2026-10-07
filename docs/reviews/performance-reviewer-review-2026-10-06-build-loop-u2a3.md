Commit: 34edec56

# Performance Review — feat/build-loop-u2a3 (main_imports, iteration 2)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 34edec56). Perf-relevant code: `scripts/lib/dev-cycle-read.sh` main_imports (:545-615) and isimported (:621-630).
**Date:** 2026-10-06
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2a3-i2.md (iteration 2), docs/reviews/code-fact-check-report-build-loop-u2a3.md (iteration 1), and the settled override rows in docs/reviews/override-log.md.

## Data Flow and Hot Paths

main_imports runs once per merge-gate check. It has no caller until U2a4, and it is cached per `"$MAIN_SHA $ROOT_REAL"`. It lists main's tree (`ls-tree -r -z`) and the checkout's untracked and ignored `.md` files (`untracked_md`, which is `git ls-files --others` without `--exclude-standard`, so it also lists ignored files). Both lists go through bash loops into `cand`. One `tr` lower-cases all of them, and a bash regex loop picks the start files. The walk then reads each queued file (one `cat-file` per blob on main, or `import_targets` on a checkout file) and forks `lower` for each import edge. **Path temperature: cold.** It runs once per merge and does not block a latency-sensitive operation. Every finding below starts from that.

Measured on this host (WSL2), all runs from my own scratch dir `/tmp/u2a3-perf-i2-liNm`:
- The walk on this worktree (2,966 tree entries, 1 untracked .md) takes 0.46-0.67 s over 5 runs. This matches the B6 row's 0.4-0.5 s.
- A cached `isimported main` call costs 2.4-5.7 ms (100 calls took 0.24-0.57 s across runs). That cost is two `need_root` `$(pwd -P)` forks plus one `lower`. This is the class settled by row 345 (the per-path lower, Won't-Fix, trigger "U2c measures --check over 100+ paths above 1 s"), so it is not re-filed. The number is recorded for U2c.
- The full build-loop-check.bats suite: 15/15 ok in 2.7 s.

Settled rows that I did not re-file and that this diff does not change: row 365 / B6 (bash check per tree record), row 346 (one cat-file per blob), row 355 (O(q²) queue pop and `lower` forked per edge before the seen check), row 363 (punctuation second pass), and row 345 (per-path lower).

## Findings

#### F1. Every untracked or ignored `.md` in the checkout (node_modules READMEs, say) goes through three bash passes before the start filter: about 35 µs per name, 3.7-4.1 s at 100k names

**Severity:** Low
**Location:** `scripts/lib/dev-cycle-read.sh:562-573` (excerpt ends :573; the enclosing main_imports() continues to :615. Read: the walk loop uses only the names that were queued.)
**Move:** 2 (size of N), 1 (hidden multiplication)
**Classification:** Macro (linear in the size of the ignored tree, with no bound) / Cold path (once per merge gate)
**Confidence:** High (measured)
**Baseline:** Measured in probe repos built in /tmp/u2a3-perf-i2-liNm on 2026-10-06. One tracked CLAUDE.md, with `node_modules/` gitignored. The walk took 0.012-0.013 s with no node_modules, 0.34-0.36 s with 10,000 ignored .md files, and 3.74-4.08 s with 100,000.
**Legibility-target:** whoever sets U2c's `--check` budget, or meets a slow gate on a JS repo.

**Evidence:**
```
  mapfile -d '' recs < <(untracked_md && printf rc=0 || printf rc=1)
  ...
  for f in "${recs[@]}"; do [[ "$f" != *$'\n'* ]] || return 1; cand+=("t:$f"); done
  # One tr lower-cases every candidate (lower would fork per path).
  [[ ${#cand[@]} -eq 0 ]] || mapfile -d '' low < <(printf '%s\0' "${cand[@]}" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz')
  [[ ${#low[@]} -eq ${#cand[@]} ]] || return 1
  for i in "${!cand[@]}"; do
    f="${low[i]:2}"
    if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]; then
```
`untracked_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; }` (:513) has no `--exclude-standard`, so ignored trees are listed too. In /workspace that is 488 .md files, against 0 that are untracked and not ignored.

This is not the B6 row (365). That row prices *tracked* tree records, and its revisit trigger ("10k+ tracked entries") never fires on a small repo with a large ignored `node_modules`, `.venv` or vendored docs tree. The listing must include ignored files, because CLAUDE.local.md is usually gitignored. The cost is in what happens next. At 100k names the phases split as follows: `mapfile` 1.03-1.07 s, the newline check and `cand` append 0.31-0.39 s, the `tr` plus `mapfile` 0.61-0.65 s, and the start-filter regex loop 1.50-1.85 s. git's own listing is 0.8 s of the total. Almost none of these names are starts. Typical JS repos hold 2k-30k such READMEs and CHANGELOGs, which puts the walk at about 0.1-1 s. It is cold, so Low. It does land inside U2c's 1 s revisit bar from rows 345 and 365.

**Recommendation:** Prefilter the untracked stream in C before bash sees it. `untracked_md | env LC_ALL=C grep -zaiE '<INSTRUCTION_FILE basename form>|(^|/)\.claude/rules/'` took 0.48 s for the 100k listing (0 matches), against about 4 s for the bash path. Keep the walk's newline refusal: a second `grep -zc $'\n'` over the same listing does it, or a newline name could be fed through the filter. Re-run the newline and `.claude/rules` start tests afterwards. If you defer this, add a revisit trigger to row 365 phrased in untracked or ignored .md count, not tracked entries.

#### F2. Each symlink on main that the walk follows costs about 12 ms: two `cat-file` reads of the same blob, plus one `realpath` fork per link-text component plus one more

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:590-603` (excerpt ends :603; the enclosing main_imports() continues to :615. Read: `out` flows into the edge loop at :607-613.)
**Move:** 1 (hidden multiplication)
**Classification:** Micro (fixed forks per symlink) / Cold path
**Confidence:** High (measured)
**Baseline:** Measured in a probe repo in /tmp/u2a3-perf-i2-liNm on 2026-10-06. A CLAUDE.md imports 50 symlinks, each `L$i.md -> a/b/c/d/r$i.md`, and the walk took 1.13-1.28 s. The same 50 targets imported directly took 0.35-0.50 s. That is about 15 ms per symlink edge, and about 12 ms per symlink node once the extra edge's `lower` fork from row 355 is taken out.
**Legibility-target:** whoever does the batching rework from rows 346 and 355.

**Evidence:**
```
          if ! i="$(git cat-file blob "$MAIN_SHA:$f" | tr -cd '\0' | wc -c)" || [[ "$i" -ne 0 ]] \
             || ! out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"; then IMPORTED_MAIN=error; return 1; fi
...
          for c in "${parts[@]}"; do
            [[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }
            p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${p:+$p/}$c" 2>/dev/null)" || p=..
            [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
          done
          out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" 2>/dev/null)" || out=..
```
The per-component loop is new in 4f087967. It is the iteration-1 red fix, and it is what makes the `..` check correct (iteration 2, Claim 1, verified with caveats). Main has 0 symlinks among walked files here, and a repo usually has a handful. At 5 components and 5 symlinks the cost is about 60 ms per gate. This is not worth changing on its own. If the row-346 batching rework (`git cat-file --batch`) happens, read each symlink blob once, then fold the component walk into pure bash string handling over `ent` (`-L` is a builtin test). That removes the forks without changing what the check decides.

**Recommendation:** None now. Fold this into row 346's or row 355's batching rework when its trigger fires. Do not trade the component check for speed: it closes the iteration-1 red.

## Endorsements

- The start candidates are lower-cased by one `tr` over the whole NUL-separated list, not by a `lower` fork per path. That is one process for every candidate, against about 3 ms per candidate the per-path way. [read: scripts/lib/dev-cycle-read.sh:566-568]
- The walk result is cached for the commit and root, so a gate checking many paths walks once. In my probe, 100 cached `isimported main` calls took 0.24-0.57 s in total, against 0.46-0.67 s for one walk. (The key ignores checkout state, which is a correctness concern owned by the architecture and security reviewers, iteration-1 escalation P1.) [fact-check: iteration 1 Claim 12 — Verified (executed)]
- `git ls-files --others` does not descend into the nested worktrees under /workspace/.claude/ (a nested repo is not entered). The ignored-file listing in /workspace showed only docs/working/ and devcontainer-config/ entries. [unverified — submitted as claim]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Untracked and ignored .md names each pass three bash loops before the start filter (3.7-4.1 s at 100k; outside row 365's tracked-entry trigger) | Low | `scripts/lib/dev-cycle-read.sh:562-573` | High |
| F2 | About 12 ms per followed symlink on main (two cat-file reads, a realpath per component) | Informational | `scripts/lib/dev-cycle-read.sh:590-603` | High |

## Overall Assessment

The performance posture fits a once-per-merge cold path: 0.5 s on this repo, and the per-path query after the cache is a few ms. The settled rows (B6/365, 346, 355, 363, 345) still describe the main costs, and this diff does not move them. The iteration-1 fix adds a small per-symlink cost (F2) that is worth paying. The one new scaling input is F1. The untracked listing includes ignored trees, so an ignored `node_modules` drives the bash loop cost, and no existing revisit trigger watches for that. A C-side `grep -z` prefilter fixes it in place, about 8x faster at 100k names, and is the structural fix. At minimum, give row 365 an untracked-count trigger. No profiling is needed beyond what was measured here. U2c should time `--check` on a repo with a populated `node_modules`.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/performance-reviewer-review-2026-10-06-build-loop-u2a3.md, structured per the performance-reviewer skill."
- **Answered:** Performance review of `git diff main...HEAD` at 34edec56: walk timing on the repo, the cached-query cost, the scaling of the untracked and ignored listing (F1, new and outside the settled rows), the cost of the iteration-1 symlink fix (F2), and the bats suite runtime. The settled rows 345, 346, 355, 363 and 365 were checked and not re-filed.
- **Out of scope:** The cache key's correctness (it ignores checkout state and MAIN_BY_NAME) belongs to architecture-review and security-reviewer. The Q10/Q11 fail-open belongs to security-reviewer. The parser and lower-failure behavior is U2a3b (stacked).
- **Escalate:** F1 to the rubric as a candidate for a new Defer row, or for a revisit-trigger amendment to row 365 (an untracked or ignored .md count, for example 10k), so U2c's budget check covers JS repos. Nothing blocks.
