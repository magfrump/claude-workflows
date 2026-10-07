Commit: 5c57d367

# Security Review — feat/build-loop-u2a3 (loop 2, iteration 1, after the split)

**Scope:** `git diff main...HEAD` of `feat/build-loop-u2a3` at 5c57d367 (base main 62d366a7). Code: `scripts/lib/dev-cycle-read.sh` (`main_imports`, `nul_list`, `isimported main`), the two bats suites; docs: plan F11/U2a3/U2a3c/U2b bullets, known issue A5.
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3-L2.md` (summary `factcheck-summary-L2i1.md`); probes executed against the HEAD lib and the pre-split lib at cc1aa864 (scratch `/tmp/u2a3-sec2-i1-cTiQ`, 22 checkout-state scenarios).
**Role:** sec2, pass i1.

## Trust Boundary Map

```
B1: [main's commit: tree records + blobs, S1/S2]     → [ls-tree parse :553-560, cat-file + import_targets :578, link-text checks :580-595] → [IMPORTED_MAIN list]
B2: [checkout working tree + index, S3/S4]            → [untracked_md :561, start filter :566-571, main-lacks probe :606, link -L :592] → [walk fail (return 1) or "recorded, not walked"]
B3: [IMPORTED_MAIN / main_imports' return]            → [isimported main :621]                                   → [U2a4 floor "may self-merge X?" (no caller yet)]
B4: [caller environment: GIT_* vars, repo config, S5] → [git ls-tree / ls-files / cat-file, no hardening in the lib] → [B1/B2 listings]
```

Input-source classification:

```
S1: main's tree names/modes (ls-tree -r)   — runtime-mutable (any landed commit) — UNTRUSTED for path construction and exec args;
                                                trusted only as "what main stores" (the gate's reference state)
S2: main's blob text (instruction files,    — runtime-mutable — UNTRUSTED for path construction (tokens, link text)
    symlink text)
S3: checkout untracked/ignored files        — request-time (whatever the iteration worktree holds) — UNTRUSTED for every sink;
                                                after the split used only to fail (B2)
S4: checkout index (tracked-not-on-main)    — request-time — UNTRUSTED; not read by the walk at all (Finding 1)
S5: caller env / repo config                — deploy-time for the gate (U2b's wrapper, F38, T42) — trusted here only
                                                because U2b hardens it; the lib itself does not
S6: MAIN_SHA (resolve_main, rev-parse --verify) — runtime-mutable ref, hash-verified — trusted as an exec argument
```

What enters: main's commit (S1/S2) is the reference state and is parsed defensively (doubled names, newline names, odd link text all fail). Checkout input (S3) after the split can only make the walk fail or leave a path recorded-not-walked; the checkout's index (S4) is not consulted, which is the one asymmetry this pass found. Fail-closed relies on `isimported main` mapping any `main_imports` failure to "imported" (B3).

## Findings

#### 1. An instruction file the checkout's index tracks but main lacks is neither a start nor a failure; the "fails closed on the checkout" contract covers untracked starts only

**Severity:** Medium
**Location:** `scripts/lib/dev-cycle-read.sh:561-571` (start set), `:463-470` (Not-covered list), `docs/working/plan-build-loop-handoff.md` F11 row
**Boundary:** B2 (S4)
**Move:** 5 (invert the access-control model), 11 (bypass enumeration)
**Confidence:** Low (reachability depends on U2b's choice of checkout; a clean gate worktree at MAIN_SHA has no such file)
**Legibility-target:** the lib's block comment :463-470 and plan F11 (both omit what A5 already lists); the start-set loop :561-571 if fixed in code

**Evidence:**
```
  nul_list recs untracked_md || return 1
  for f in "${recs[@]}"; do [[ "$f" != *$'\n'* ]] || return 1; cand+=("t:$f"); done
```
(`:561-562`; `untracked_md` is `git ls-files -z --others`, `:515`) and
```
      [[ "${cand[i]:0:1}" == m ]] || return 1  # untracked: not walked until U2a3c
```
(`:569`; the loop :566-572 continues to `IMPORTED_MAIN=$'\n'` at :573). Candidates come only from main's tree (`m:`) and the untracked list (`t:`), so a start the index tracks is in neither.

Executed probe D (HEAD and cc1aa864 alike): main holds `CLAUDE.md`; the checkout stages `sub/CLAUDE.md` containing `@../x.sh` (`git add`, not committed) → `walk=ok x.sh=-`. Probe E (feature branch checked out, branch adds `.claude/rules/n.md` importing `@../../x.sh`) → `walk=ok x.sh=-`. The same file left untracked (probes A, B, Q, and D after `git reset`) fails the walk.

The split's interim contract is "fail closed on checkout starts until U2a3c walks them", and its motive is the orchestrator session's local instructions (CLAUDE.local.md). A staged-but-uncommitted start, or one the checked-out branch tracks, is the same threat — Claude Code running in that checkout loads it — but the walk answers ok and its imports answer "-", so a floor built on it would let a branch edit `x.sh`. This is not a regression: the pre-split lib and main alone give the same answer, and A5 lists the gap ("an instruction file the checkout tracks but main lacks (not a start)"). The point is that the asymmetry between S3 and S4 is now the only checkout start input that does not fail, and closing it costs nothing in the case the plan expects: when the checkout holds the branch, a branch-added start is already refused by floor item 1 (basename) or item 2 (dot component), so failing the whole walk refuses the same merge.

**Recommendation:** Fail closed on index-tracked starts main lacks too. Tested in a scratch copy: after :562 add
`nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached -- ':(glob,icase)**/*.md' || return 1; for f in "${recs[@]}"; do [[ -n "${ent[$f]+set}" ]] || cand+=("t:$f"); done`
→ probes D and E fail the walk, probes G/I/O stay ok, and `build-loop-check.bats` passes 16/16 on the mutated lib. If the author prefers to defer, add the sentence to the :463-470 Not-covered list and F11's Gaps (as the fact-check escalated) and record a Defer row with U2a3c or U2b as trigger.

No other findings within the paths probed. Every other checkout state I tried that the pre-split walk read (and answered ok) now fails the walk, and none of the 22 scenarios gives HEAD `walk=ok` with a path answering "-" where cc1aa864 answered "imported".

## Probe results (executed)

Script: `/tmp/u2a3-sec2-i1-cTiQ/probe.sh`; each row runs `main_imports` then `isimported main` per path, with the HEAD lib and the cc1aa864 lib.

| # | Checkout state | HEAD | cc1aa864 |
|---|---|---|---|
| A | untracked `CLAUDE.local.md` → `@x.sh` | FAILED, x.sh imp | ok, x.sh imp |
| B | untracked start under a gitignored dir | FAILED | ok (walked) |
| C | untracked start under a mode-000 dir | ok, x.sh `-` (ls-files warns, exits 0) | same |
| D | index-staged `sub/CLAUDE.md` not on main | **ok, x.sh `-`** | same (Finding 1) |
| E | branch checked out, adds `.claude/rules/n.md` | **ok, x.sh `-`** | same (Finding 1) |
| F | path main lacks, checkout plain file importing y.sh | FAILED | ok (walked) |
| G | path main lacks, checkout plain dir | ok, recorded | same |
| H | path main lacks, dangling symlink | FAILED | FAILED |
| I | `@Docs/A.md`, main stores `docs/a.md` → `@b.sh` (case-sensitive FS) | ok, docs/a.md imp, b.sh `-` | same |
| J | path main lacks under checkout-only dir symlink, file present | FAILED | FAILED |
| K | same, file absent | ok, recorded | same |
| L | main link `a.md -> sub/x.md`; checkout's `sub` swapped to a symlink | ok, other/two.sh `-` | same |
| M | path main stores as a tree, checkout holds a file | FAILED | ok (walked) |
| N | `@.git` in a linked worktree | FAILED | ok |
| O | `@docs//./a.md` | ok, a.md and b.sh imp | same |
| P | untracked start that is a symlink | FAILED | FAILED |
| Q | untracked `.claude/rules/deep/x.MD` | FAILED | ok (walked) |
| R | caller exports `GIT_LITERAL_PATHSPECS=1` (build-loop.sh does) | FAILED (pathspec magic still applies) | ok |
| T | caller exports `GIT_NOGLOB_PATHSPECS=1`, start `Claude.LOCAL.md` | FAILED | ok |
| U | `core.untrackedCache=true`, cache primed before the start appears | FAILED | ok |
| V | untracked start beside a `.git` *file* (fake nested repo) | FAILED | ok |
| W | path main lacks is a FIFO | FAILED | FAILED |

Reading: against main alone, every checkout read leads only to `return 1` or "recorded, not walked" (G, K: nothing loads from a directory or an absent path). Against cc1aa864, each input it walked now fails. C is settled (override row "unsearchable checkout directory", Defer to U2a3c; the file is unreadable to a same-uid Claude Code too). I is a case-sensitive-FS answer A5 lists ("other names one file has on a case-insensitive checkout"). L (a tracked path whose checkout content differs from main) is excluded by the design's "a working-tree edit does not count" and is identical pre-split; it matters only if U2b runs the gate in a dirty checkout. N is availability only (fails closed), as the fact-check noted.

## Untested bypass candidates

Guardrail `:569` (untracked start fails) and `:606` (main-lacks path present in the checkout fails):

- `GIT_INDEX_FILE` pointing to an index that lists the untracked start (so `--others` omits it), or a `core.fsmonitor` hook that misreports untracked files — not tested: both are caller environment / repo config (S5), which U2b's hardened wrapper and `--state` (T42) are planned to refuse; the lib itself sets only `GIT_LITERAL_PATHSPECS=0` for this call.
- `refs/replace` or `info/grafts` substituting main's commit or an instruction blob for `ls-tree`/`cat-file` — not tested here: the lib does not set `GIT_NO_REPLACE_OBJECTS`; `scripts/build-loop.sh:118` exports it and F38/T36/T42 refuse replace refs. A lib caller other than build-loop.sh would inherit the gap.
- A case-insensitive checkout (macOS, `/mnt/c` under WSL) for probe I: the `-e` at :606 should see `Docs/A.md` and fail the walk — not tested, no case-insensitive filesystem in the sandbox.
- Sparse checkout (cone mode) hiding an untracked start in an excluded directory — not tested.

Because these candidates are untested, the guardrails at :569 and :606 do not appear in Endorsement Claims as categorical properties; the claims below are scoped to the executed probe set.

## Endorsement Claims

- **Claim:** In each of the 10 probed checkout states where the cc1aa864 walk read a checkout input and returned ok (A, B, F, M, N, Q, R, T, U, V), the HEAD walk returns 1 and `isimported main` answers imported for every queried path.
  **Location:** `scripts/lib/dev-cycle-read.sh:561-571`, `:606`, `:621`
  **Evidence:** executed
  **Verified:** `probe.sh` scenarios A-W run against `lib-head.sh` (5c57d367) and `lib-pre.sh` (cc1aa864); outputs in the table above.
  **Not verified:** states built through caller env or repo config (`GIT_INDEX_FILE`, `core.fsmonitor`, replace refs) and case-insensitive filesystems.
  **route: code-fact-check**
- **Claim:** Across the 22 probed checkout states, there is no case where HEAD returns `walk=ok` and answers "-" for a path that cc1aa864 answers "imported".
  **Location:** `scripts/lib/dev-cycle-read.sh:546-610`
  **Evidence:** executed
  **Verified:** pairwise comparison of the two libs' outputs per scenario.
  **Not verified:** checkout states outside the probe set (the untested candidates above); D and E answer "-" under both libs (Finding 1).
  **route: code-fact-check**
- **Claim:** The walk's git invocations take main's names only after the hash, so a tree name beginning with `-` reaches git as part of `"$MAIN_SHA:$f"`, not as an option; the realpath calls pass `--` before the path.
  **Location:** `scripts/lib/dev-cycle-read.sh:553, 578, 582-583, 591, 594`
  **Evidence:** read-static
  **Verified:** read the five call lines and `resolve_main` (:416-437), which sets MAIN_SHA from `rev-parse --verify`.
  **Not verified:** `blocker`/`plaindir`'s `realpath -e -- "$1"` was read (:99-122) but no `-`-prefixed path was executed through :606.

## Primitive sweep

Primitive: process exec with path-derived arguments (git / realpath / test) and path construction

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:553` `git ls-tree -r -z --full-tree "$MAIN_SHA"` | S6 | hash from `rev-parse --verify`; `nul_list` checks exit and NUL termination | cleared |
| `:515`/`:561` `git ls-files -z --others -- ':(glob,icase)**/*.md'` | S3, S5 | fixed pathspec with explicit magic (R, T probed) | cleared for env probed; S5 hardening is U2b's |
| `:578` `git cat-file blob "$MAIN_SHA:$f"` | S1, S6 | name after `sha:`; pipefail + `|| return 1` | cleared |
| `:582-583` same, symlink text (NUL count, then text) | S1, S2 | NUL, empty, newline, absolute text fail | cleared (fact-check Claims 6, 11) |
| `:591` `realpath -ms ... -- "$ROOT_REAL/${p:+$p/}$c"` | S2 | `--`; `..` after a link fails | cleared (settled lexical-`..` row) |
| `:594` `realpath -ms ... -- "$ROOT_REAL/${d:+$d/}$out"` | S2 | `--`; result `..`/`../*` fails | cleared |
| `:592` `[[ ... ! -L "$p" ]]` | S2, S3 | checkout read can only set `lk` (more failures) | cleared |
| `:606` `-d`/`-L`/`-e "$p"`, `blocker "$p" dir` | S2, S3 | any non-plain-dir presence fails | cleared (probes F, G, H, J, K, M, W); case-insensitive FS untested |
| `:501` `import_targets` realpath (U2a2, on main) | S2 | `--`; leaving-repo paths dropped | cleared (unchanged here; U2a3b changes the parser) |
| `:517` `nul_list` runs `"$@"` | code constant | both call sites pass fixed commands | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Index-tracked start main lacks is neither a start nor a failure; fail-closed covers untracked starts only | Medium | B2 | `scripts/lib/dev-cycle-read.sh:561-571` | Low |

## Overall Assessment

The split does what it claims against both comparisons the task asked for. In the 22 checkout states probed, no checkout input turns a refusal into ok relative to main alone, and every input the cc1aa864 walk read now fails the walk. The settled gaps (unsearchable directory, nested repos, cache keyed without the checkout) behave as their override rows say. The one open security-relevant asymmetry is Finding 1. A start that the checkout's index tracks but main lacks passes unwalked, while the same file untracked fails. This is pre-existing and listed in A5, but it is now the only checkout start input that does not fail closed. A tested one-line listing closes it, costs nothing when the checkout holds the branch, and passes the suite. The fix is in place, not architectural. Endorsement claims are executed-scoped to the probe set; no findings within the code paths read beyond Finding 1, and the untested candidates above (caller env, replace refs, case-insensitive FS) are pending U2b's hardening and a host probe.

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to docs/reviews/security-reviewer-review-2026-10-06-L2-build-loop-u2a3.md, structured per the security-reviewer skill.

- **Answered:** whether the post-split walk is fail-closed on the checkout, and whether any main tree or checkout state lets it answer ok while missing an import that main alone or the pre-split walk at cc1aa864 would catch (none found among 22 executed states; Finding 1 is a same-as-pre-split gap in the checkout contract, with a tested fix).
- **Out of scope:** the token parser and the walks' fail-closed handling of a failing sed/grep/lower (U2a3b, stacked); the checkout phase (U2a3c); the floor's own rules (U2a4) and the gate's checkout, env hardening and mode rule (U2b); the three Claude Code shapes A5 lists as untraced.
- **Escalate:** author — Finding 1: fix in code (tested snippet above) or add it to the :463-470 Not-covered list and F11 with a Defer row; this matches the fact-check's escalation on Claims 7/24. U2b — the gate's checkout choice decides the reach of Finding 1 and of probe L (tracked-path divergence), and the lib relies on the caller for `GIT_NO_REPLACE_OBJECTS` and index/fsmonitor hardening.
