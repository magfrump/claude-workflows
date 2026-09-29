Commit: 2eebdf8

# Performance Review — Q-094 unit B (`q094b-exit-scan-worktree-removal`, 9075003..2eebdf8)

**Scope:** `git diff 9075003 2eebdf8` — `devcontainer-config/cc-exit-scan.sh` (removal branch of `scan_std_worktrees`, new `_snap_unq`), plus guide/plan/test prose (no perf surface). Unit A (dfe4c0d..9075003) is context only.
**Date:** 2026-09-28
**Based on:** Stage-1 merged fact-check summary (`scratchpad/B-fc-summary.md`, k=3): 0 behavioral Incorrect; `_snap_unq` fuzzed on 20,000 strings per locale with 0 wrong decodes.

## Data Flow and Hot Paths

`scan_std_worktrees` runs at most once per cc-isolated session, from `git_exit_scan` (`cc-isolated.sh:745`), after `claude` exits and before the launcher returns. It runs only when the launch and exit snapshots differ and no `invalid` git dir was found. **Path temperature: cold.** It runs once per session and never inside a loop, but it blocks the user's terminal at session exit. The launcher traps Ctrl-C during the scan and exits 4 (`cc-isolated.sh:740-750`), so a slow scan fails closed and never passes silently.

Data size: N is the number of linked worktrees removed during the session. Every removed record must be in the **launch** snapshot, so the session cannot inflate N beyond the worktrees that existed at launch. Agent worktrees "outlive sessions" (script header), so realistic N is 1 to a few tens. N in the hundreds would need a user (or an earlier session using unit A's added path) to accumulate that many.

Per removed worktree the new branch does the following:
- 2 `$(_snap_hash_str …)` calls. Each is a subshell plus a `printf | sha256sum` pipeline. The second call runs only when `ccommon` is set.
- One linear scan over `dot[]` (every added and removed dotgit record).
- One `_snap_unq`: a per-character loop plus one `$(printf %q)` subshell.
- One `looks_like_gitdir`: 3 to 4 `test` builtins, no fork.

It also still pays the 2 pre-existing `$(printf %q)` subshells at `:866-869`.

### Measurements (this review, scratch copy of 2eebdf8, `LC_ALL=C`, WSL2, bash `$EPOCHREALTIME`)

Harness: a scratch repo with N worktrees at `.claude/worktrees/agent-i`, then `git_exec_snapshot`, then all N removed with `git worktree remove` (or N new ones added, for comparison), then `git_exec_snapshot` again. The table times `scan_std_worktrees` and the whole `git_exit_scan` (both returned 0 with the note in every run).

| N | removed: `scan_std_worktrees` | removed: `git_exit_scan` | added (unit A): `scan_std_worktrees` | added: `git_exit_scan` |
|---|---|---|---|---|
| 1 | 0.023 s | 0.098 s | 0.047 s | 0.219 s |
| 10 | 0.130 s | 0.228 s | 0.331 s | 1.24 s |
| 50 | 0.679 s | 0.729 s | 2.13 s | 6.87 s |
| 100 | 1.34 s | 1.51 s | 6.44 s | 14.5 s |
| 200 | 3.09 s | 3.06 s | 9.89 s | 37.5 s |
| 500 | 14.4 s | 11.5 s | — | — |

The removal path costs about 13 ms per worktree up to N≈100. The two whole-scan columns come from separate runs (one single-shot run per cell), which is why removal at N=200 and N=500 shows the whole scan faster than the function alone. The removal path is cheaper than unit A's added path at every N measured. Above N≈200 it grows faster than linearly: going from N=100 to N=500 multiplies the time by 10.7×, where linear growth would give 5×. Findings 1 and 3 explain why.

## Findings

#### 1. Pairing a removed git dir with its `.git` record scans all of `dot[]` once per removal (O(N²) in removed worktrees)

**Severity:** Low
**Location:** `devcontainer-config/cc-exit-scan.sh:876-882`
**Move:** Count the hidden multiplications / asymptotic behavior
**Classification:** Macro (quadratic nested scan) / Cold path (once per session exit, `cc-isolated.sh:745`)
**Confidence:** High (measured)
**Legibility-target:** maintainer of `scan_std_worktrees`
**Baseline:** 3.18 s for the isolated pairing loop at N=500 removed records (this review's synthetic harness, 2026-09-28, WSL2). Scaling: 0.164 s at N=100 and 55.3 s at N=2000.

Evidence:
```bash
      for dk in "${!dot[@]}"; do
        if [ "${dk:0:1}" != - ] || [ -n "${used[${dot[$dk]}]:-}" ]; then continue; fi
        if [[ "${dot[$dk]##*$'\t'}" =~ $re ]]; then ok="${dot[$dk]}"; break; fi
      done
```

The outer loop runs once per `commondir-file` record, so once per worktree (`:858`). For each removed worktree this inner loop walks the associative array until it finds a match. It skips `+` records and already-used records only after visiting them. With N removals that is about N²/2 visits, each costing a bash regex match. Added records (unit A) also sit in `dot[]` and are visited, so a session that both adds and removes pays (added + removed) visits per removal. The loop is not the dominant cost at realistic N: at N=100 it is about 0.16 s of 1.34 s. It is the only part that grows quadratically. By N=500 it is about 3 s of about 14 s, and at the N=2000 extrapolation it alone would pass 50 s at the user's exit prompt. N is bounded by worktrees present at launch, and Ctrl-C fails closed (exit 4). So this is a slow note, not a bypass, and the cost lands in a cold path.

**Recommendation:** If large N matters, index removed dotgit records by content hash once, before the outer loop. For example, `rdot["$attrs_hash"]+="$line"$'\n'` over the `-F dotgit` lines. Then look up `$h` and `$g` directly and take the first unused entry. That is O(N) overall and keeps the content-pairing semantics from security iteration 1. Otherwise, leave the loop as is and record the O(N²) bound next to the loop comment. At the tens of worktrees this feature targets, it is harmless.

#### 2. Each removed worktree forks about 5 subshells and 2 `sha256sum` processes

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:876-877`, `:794` (and the pre-existing `:866`, `:869`)
**Move:** Count the hidden multiplications
**Classification:** Micro (per-item fork overhead) / Cold path
**Confidence:** Medium. The per-worktree figure is measured. How it splits across the individual forks is inferred from the call counts.
**Legibility-target:** maintainer of `scan_std_worktrees`
**Baseline:** about 13 ms per removed worktree (1.34 s ÷ 100, measured above). `_snap_hash_str` alone measured 3.1 ms per call (100-call loop, this review).

Evidence:
```bash
      ok="" h="$(_snap_hash_str "gitdir: $p"$'\n')" g=""
      [ -z "$ccommon" ] || g="$(_snap_hash_str "gitdir: $ccommon/worktrees/$n"$'\n')"
```
```bash
  [ "$(printf '%q' "$s")" = "$q" ] || return 1
```

On a WSL2 host, per-removal cost is dominated by process creation, not by the bash logic: two hash pipelines at about 3 ms each, plus `$(printf %q)` subshells. The total is linear and about 3× cheaper per worktree than unit A's added path. It is only worth touching if the fork count is reduced across both branches together.

**Recommendation:** None required. If anything is done, use `printf -v var '%q' …` in place of `var="$(printf '%q' …)"`, at `:794` and the pre-existing `:866`/`:869`. That removes a fork per call and changes no behavior. Keep the `sha256sum` pipeline, because it is the same primitive the snapshot uses.

#### 3. `_snap_unq` grows quadratically with path length

**Severity:** Informational
**Location:** `devcontainer-config/cc-exit-scan.sh:786-796`
**Move:** Asymptotic behavior, not just the constant
**Classification:** Micro / Cold path
**Confidence:** High (measured). The cause (string rebuild on `s+=`) is inferred.
**Legibility-target:** maintainer of `_snap_unq`
**Baseline:** 1.47 ms per call for a 68-character `%q` path, and 79.9 ms per call at 4008 characters, about PATH_MAX (10-call average each, this review, `LC_ALL=C`).

Evidence (the whole function):
```bash
_snap_unq() {
  local q="$1" s="" c i
  case "$q" in \$\'*|\'*|"") return 1 ;; esac
  for ((i = 0; i < ${#q}; i++)); do
    c="${q:i:1}"
    if [ "$c" = '\' ]; then i=$((i + 1)); c="${q:i:1}"; fi
    s+="$c"
  done
  [ "$(printf '%q' "$s")" = "$q" ] || return 1
  printf -v "$2" '%s' "$s"
}
```

Measured: 208 chars took 2.19 ms, 1008 chars 9.09 ms, and 4008 chars 79.9 ms. That is 8.8× the time for 4× the length between the last two, so the growth is quadratic. `_snap_unq` runs once per removed worktree, on a path under the checkout. Realistic paths (`<ws>/.claude/worktrees/agent-…/.git`) are under 200 characters, so this costs about 1–2 ms. The worst case is about 80 ms × N at PATH_MAX. That needs every removed worktree to have a path about 4 KB long, and it is still bounded and cold.

**Recommendation:** None required. A cheaper equivalent exists: `s="${q//\\\\/$'\x01'}"` style substitution, or `printf -v s '%b'` on the backslash form. Either would change the decoder, though, and the current one is fuzz-verified (fact-check: 20,000 strings per locale, 0 wrong decodes), so the correctness guarantee outweighs about 1 ms. Leave it.

## Endorsements

- The removal branch checks that `P` is gone before it forks either hash subshell. A removed `commondir-file` whose git dir is still on disk declines with builtin tests only. `[read: devcontainer-config/cc-exit-scan.sh:872-877]`
- `_snap_unq` rejects the `$'…'`/`'…'`/empty forms with a `case` before the per-character loop, so declined paths pay no loop and no fork. `[read: devcontainer-config/cc-exit-scan.sh:786-788]`
- `looks_like_gitdir` is pure `test` builtins (no fork, no directory walk). It adds constant cost per removal. `[read: devcontainer-config/cc-gitdir.sh:87-90]`
- The removal path of `git_exit_scan` returns the note in 1.51 s at N=100 removed worktrees. Unit A's added path takes 14.5 s at the same N. `[unverified — submitted as claim: measured once per cell on WSL2 by this review's harness; not execution-verified by the fact-check stage]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Pairing loop over `dot[]` is O(N²) in removed worktrees (3.2 s at N=500, 55 s at N=2000, loop alone) | Low | `cc-exit-scan.sh:876-882` | High |
| 2 | About 5 subshells and 2 `sha256sum` forks per removal (about 13 ms per removal, linear) | Informational | `cc-exit-scan.sh:876-877`, `:794` | Medium |
| 3 | `_snap_unq` is quadratic in path length (1.5 ms at 68 chars, 80 ms at 4008) | Informational | `cc-exit-scan.sh:786-796` | High |

## Overall Assessment

Unit B adds a cold, once-per-session path. At the scale it targets (tens of removed agent worktrees) it costs well under a second, and it is several times cheaper than unit A's added path, which it sits beside. The one asymptotic problem is the content-pairing scan over `dot[]` (finding 1). It is quadratic in removed worktrees and becomes the growing term above a few hundred. N is bounded by worktrees present at launch, and an interrupted scan exits 4, so the worst case is a slow note at exit, never a silent pass. If the fix is wanted, it is local and O(N): index removed dotgit records by hash once. Nothing here blocks merge. Profiling beyond these measurements is not needed. Unit A's added path is out of scope, but it measured 37.5 s at N=200 for the whole exit scan, which is the larger scaling cost on this code path.

## Goal-Alignment Note

The PR aims to let a standard `git worktree remove` produce a note and status 0 without widening what a sandboxed session can make host git run. None of the performance findings trade against that goal:
- The pairing is keyed by content, as security iteration 1 required.
- The `looks_like_gitdir` check from 2eebdf8 costs no forks.
- Every slow case either finishes with the same verdict or is interrupted into exit 4.

The recommended O(N) index in finding 1 must keep content pairing. It must not fall back to count pairing, which is the regression security iteration 1 fixed. Findings 2 and 3 are optional micro-work and should not be traded for the verified decoder's correctness.
