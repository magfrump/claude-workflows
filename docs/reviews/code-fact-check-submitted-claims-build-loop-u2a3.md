Commit: 0bb98f27

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`)
**Scope:** Stage 2.5 submitted-claims pass (role `cfc25`, pass `i3`), branch `feat/build-loop-u2a3` at 0bb98f27, against base main 62d366a7. Only the four claims the critics submitted are verdicted here. Nothing new was harvested from the diff.
**Checked:** 2026-10-06
**Total claims checked:** 4
**Summary:** 4 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Numbering continues from the canonical merged report `docs/reviews/code-fact-check-report-build-loop-u2a3-L3-final.md`, which ends at Claim 42. All probes ran under `timeout` in scratch dir `/tmp/u2a3-cfc25-i3-zYTC` (bash 5.2.15, git 2.39.5, `LC_ALL=C`, hermetic git env as in `test/lib/build-loop-fixtures.bash`). The worktree file was never edited, and the one mutant was a scratch copy.

---

## Submitted Claims

## Claim 43: "When `main_imports` fails, `isimported main` answers "imported" for every path."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:626` (isimported's `main)` arm)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` exit of `main_imports`, on both the first call and the cached call, called under `if` and called bare under `set -euo pipefail`, for any `$2` (empty, spaces, a start file, an imported path, an unrelated path). It does not establish what happens on `need_root`'s failure path. That path exits the shell instead of answering, which is the documented behavior ("need_root exits instead").

The arm is `main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;`. Any non-zero return from `main_imports` short-circuits to `return 0` before `$2` is consulted. On a cached call, `main_imports` returns `[[ "$IMPORTED_MAIN" != error ]]`. `IMPORTED_MAIN=error` is set before the first check that can fail, and it is reassigned only at `IMPORTED_MAIN=$'\n'` once the start list is built, so a cached failed walk also returns 1. I read the whole of `main_imports` (lines 550–620) and the whole of `isimported` (621–629).

Executed probe (`c1.sh`). Three repos each made the walk fail in a different way: an untracked `sub/GEMINI.md` start, no `main` branch (`main_by_name` fails), and a symlink on main with absolute text. In each one, the paths `docs/a.md`, `docs/none.md`, `scripts/x.sh`, `""`, `AGENTS.md` and `"a b/c"` all printed `imported`. That held on the first call, on the cached call, and after `IMPORTED_MAIN_DONE=""`. A bare `isimported main zz/q.md` under `set -e` returned 0. The baseline repo, whose walk succeeds, answered `-` for the non-imported paths, which shows that "imported" is not a constant.

## Claim 44: "`nul_list` returns 1 and empties the array unless the command exited 0 and its output was empty or ended in NUL ("whole-listing contract")."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:519` (`nul_list`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function body as written: the success/failure condition and the array state on both outcomes, including adversarial outputs that themselves contain `rc=0`. It does not establish behavior when the caller's array is itself named `nl_a` (a nameref self-reference). No caller does that: both callers pass `recs`.

`mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1)` appends a marker with no trailing NUL. When the command fails, the stream ends in `rc=1`, so the last element ends in `rc=1`. When it succeeds, the last element equals `rc=0` exactly only when the byte before the marker is a NUL or there is no byte before it. The guard is `[[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }; unset 'nl_a[-1]'`. That is exactly the stated contract.

Executed probe (`c2.sh`). Each array started as `(x)`:
- empty output with exit 0 gave rc=0 and `n=0`
- `a\0b\0` gave rc=0 and `[a b]`
- `\0` gave rc=0 and `['']`
- `rc=0\0` gave rc=0 and `[rc=0]`
- `a\nb\0` gave rc=0 and `[$'a\nb']`
- these all gave rc=1 and `n=0`: `a\0b` (no trailing NUL), `a\0` with exit 3, exit 2 with no output, a bare `rc=0` (no NUL), `x\0rc=0`, and `rc=0\0` with exit 1

## Claim 45: "The merged `git ls-files -z --cached --others -- ':(glob,icase)**/*.md'` listing returns the same set of names as the earlier pair (`untracked_md` plus `ls-files -z --cached` with the same pathspec)."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:566` (main_imports' checkout listing)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shapes listed below on git 2.39.5, comparing both the set and the multiset (duplicates included) of the merged command against the pair as 99cce51b removed it (`untracked_md`, i.e. `GIT_LITERAL_PATHSPECS=0 git ls-files -z --others`, then `GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached`, same pathspec). It does not establish other git versions, and it does not establish output order. Order differs (`--others` entries print first in the merged form too), but the loop at line 567 classifies each name independently, so order does not affect which candidates are built or whether a `t:` start fails the walk.

The removed lines in `git show 99cce51b` are `nul_list recs untracked_md` and `nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached -- ':(glob,icase)**/*.md'`. Both names were then fed into the same loop. The pathspec and `GIT_LITERAL_PATHSPECS=0` are the same in both forms.

Executed probe (`c3.sh`) in one repo, applying these shapes one after another. After each step, the sorted multiset of the merged output was byte-identical to that of the pair:
- tracked `.md` and `.MD` files
- untracked files, including one in a new nested directory
- ignored files, both by directory and by pattern
- a tracked file deleted from the worktree
- a skip-worktree file that was removed
- an intent-to-add file
- an assume-unchanged file
- an untracked nested repo, then the same repo added as a gitlink
- a tracked file replaced by a directory holding a `.md`
- an unmerged path (listed three times in both forms)
- a non-cone sparse checkout, and a cone sparse checkout with `index.sparse=true`

In each case the unique sets were also identical.

## Claim 46: "The memo `break` in the ancestor pass keeps it linear in records plus distinct directories while still detecting every name that is also a directory of another listed name, whatever the listing order."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:565` (main_imports' ancestor pass, the `for f in "${!ent[@]}"` line)
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers detection correctness for every insertion and iteration order, and the iteration count of the inner loop. "Linear" counts loop iterations and associative-array lookups. Each `${c%/*}` step also costs time proportional to path length, so the per-record constant grows with path depth. That is the deep-path cost already recorded in an override row (O(L x depth)). It does not establish bash's hash-table behavior at sizes beyond 80,000 records.

Invariant from the code (`[[ -z "${dir[$c]+set}" ]] || break; [[ -z "${ent[$c]+set}" ]] || return 1; dir[$c]=1`): a directory enters `dir` only after it has been checked against `ent`. The climb then continues to its parent. So every directory in `dir` has all of its ancestors in `dir`, each already checked. A `break` on a memoised directory therefore skips only ancestors that were already checked, and that holds whatever the iteration order. Each record does at most (new directories + 1) inner iterations, which gives O(records + distinct directories) iterations in total. The iteration is over `"${!ent[@]}"` (hash order), not the listing order, which makes the result order-independent by construction.

Executed probes (`c4.sh`, which greps that line 565 matches the pasted copy verbatim before it runs):
- 400 random name sets (1–12 names, depth 1–4, a three-letter alphabet so collisions are frequent) were compared with an O(n²) brute-force "some name is a `/`-prefix of another". There were 0 mismatches, and brute force reported a crafted tree in 281 of the sets.
- Two fixed sets inserted in 6 and 4 shuffled orders all returned 1.
- An instrumented copy counted new-directory steps. On the flat-ish set (≈2,500 distinct directories), N = 5k/20k/80k records took 46/120/437 ms. On a single 40-level directory, N = 5k/20k/80k took 38/140/603 ms with only 40 directories added. Time scales roughly linearly in N.

End to end (`c4e.sh`): I crafted a main commit with `git mktree` in which `docs/sub` is stored both as a symlink and as a tree holding `docs/sub/b.md`. `main_imports` returned 1 (`IMPORTED_MAIN=error`). A scratch mutant with line 565 removed (`c4m.sh`) printed `walk ok` on the same repo. So that line alone is what catches this shape.

---

## Claims Requiring Attention

None. All four submitted claims verified.

## Goal-Alignment Note

- **Success criterion (verbatim):** A report saved to docs/reviews/code-fact-check-submitted-claims-build-loop-u2a3.md with a `## Submitted Claims` section verdicting each submitted claim, first line `Commit: 0bb98f27`.
- **Answered:** Yes. All four submitted claims (numbered 43–46) are verdicted Verified, each executed in scratch probe repos, with scope lines and the submitting critic named.
- **Out of scope:** Fresh harvesting from the diff. The U2a3b parser and the fail-closed behavior of sed/grep/lower. Git versions other than 2.39.5.
- **Escalate:** Nothing.
