# Security Review — feat/build-loop-u3a2 (U3a2 `--merge`, iteration 1)

Commit: 7d78e6d0
**Scope:** `git diff main...HEAD` — `scripts/build-loop.sh` (`--merge`, `merge_ident`, `land`, `check_line` verdict values), `test/scripts/build-loop-merge.bats`
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-u3a2-i1.md` (Stage 1), shared context `u3a2-i1-shared.md` (override rows 215, 494, 501, 509, 512, 524, 613, 625, 639, 642, 646 treated as settled)

No HALT escalation: no escalation pattern matched.

## Trust Boundary Map

```
B1: [caller argv + env (S1, S2)]            → [arg parser, harden, GIT_* exports]           → [gate process]
B2: [repo config / config.worktree (S4)]    → [state_gate at start + re-run in ROOT and W]  → [git merge --ff-only in W] (new: W's config now drives a ref move and a checkout)
B3: [caller global config + host (S3)]      → [merge_ident: git var + ident regex]          → [GIT_{AUTHOR,COMMITTER}_{NAME,EMAIL} → commit-tree] (new)
B4: [worktree admin metadata (S5)]          → [worktree list -z parse; head-name/BISECT_START scan] → [choice: CAS vs ff-in-W] (new)
B5: [W's working tree files, index (S7)]    → [W checks: HEAD/op files/status/added-path probes] → [ff checkout writes into W] (new)
B6: [verdict values from check_line (S6, S8)] → [commit-tree in gate repo]                  → [update-ref CAS / ff → refs/heads/MAIN] (new)
```

Input-source classification:

```
S1: argv (brief path, --expect 40/64-hex)       — request-time     — trusted (caller is the orchestrator); --expect format-checked
S2: caller env (GIT_CONFIG_PARAMETERS/COUNT,
    GIT_AUTHOR_*/COMMITTER_*, GIT_CONFIG_GLOBAL) — request-time     — trusted (documented: "the caller's own environment is trusted")
S3: caller ~/.gitconfig / XDG config, host
    gecos + FQDN                                 — runtime-mutable  — UNTRUSTED for exec/include sinks (loop-writable);
                                                                       read only by git var, for names: trusted for nothing but attribution
S4: .git/config, config.worktree (ROOT and W)   — runtime-mutable  — UNTRUSTED for every git sink (loop-writable); state_gate's denylist is the only filter
S5: .git/worktrees/*/ (gitdir, HEAD, rebase-*/head-name, BISECT_START) — runtime-mutable — UNTRUSTED for the CAS-vs-ff choice
S6: object store + refs (main, tip, merged tree) — runtime-mutable  — UNTRUSTED for content; store_check re-hash + --expect pin the ids judged
S7: W's untracked/ignored files and index flags  — runtime-mutable  — UNTRUSTED (loop-writable); damage target, not a decision input
S8: brief content on main's commit (Branch:, stem) — committed     — trusted for commit-message text after status_fields' line grammar
```

New in this diff: S6-derived ids now flow into a write (B6) that moves the default branch, and two loop-writable sources (S4 for W, S5) now steer *how* the move happens. The diff assumes that what the state gate's denylist does not name is inert for `git merge --ff-only`; Finding 1 is a config key outside that list that changes the ff's effect. The commit written is pinned to the judged ids (tree, MAIN_SHA, tip) by value, which is the strongest part of the design.

## Findings

#### 1. `branch.<main>.mergeOptions` is not gated, and `--squash` there makes the ff in W stage the merge in W's index without moving main

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1072`
**Boundary:** B2, B5
**Move:** 11 (bypasses of the state gate's key list), 3 (error path)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
    git -C "$w" -c gc.auto=0 merge --ff-only -q "$NEW" > "$GATE_TMP/ff" 2>&1 || { MERGE_WHY="the fast-forward in $in failed"; return 1; }
    [[ "$(git rev-parse --verify -q "refs/heads/$MAIN")" == "$NEW" ]] || { MERGE_WHY="the default branch is not at the merge after the fast-forward in $in"; return 1; }
```
and the state gate's key list (`:329`), which names `merge.*` but not `branch.*`:
```
STATE_KEYS_RE='^(filter\.|include|hook\.|merge\.|diff\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|log\.showsignature|extensions\.partialclone$|remote\..*\.promisor$)'
```

`git merge` reads `branch.<current>.mergeOptions` and applies it before the command line. `--no-ff` there is overridden by `--ff-only` (probed: main moves, W clean), but `--squash` is not: probe P1 (throwaway repo, `git config branch.main.mergeoptions --squash` in W, then `--merge`) gave exit 2 "the default branch is not at the merge after the fast-forward…", main left at M (fail-closed for main), but W left with `A  work-feat-x.txt` staged and `.git/SQUASH_MSG`/`ORIG_HEAD` written. W is now the merge's content as an uncommitted change in the user's checkout. A later `git commit` there lands the branch as a plain non-merge commit with no `Build-loop-gate:` trailer, and every following `--merge` refuses on W's tracked change. The refusal text does not say W was modified. This is reachable on the honest path (a user who sets mergeOptions on main) and by a loop planting one key in `.git/config` (S4) with no race. Main still never moves to an unjudged commit, so the impact is damage to W's checkout plus a misleading refusal, not a gate bypass.

**Recommendation:** Neutralize the key for this one call: `git -C "$w" -c gc.auto=0 -c "branch.$MAIN.mergeOptions=" merge --ff-only …` (probed: an empty `-c` value overrides the repo's `--squash`, and main moves, W clean). Do not add `branch.*` to the state gate, because that would refuse honest `--no-ff` users. If the post-ff check fails after git touched W, consider saying so in MERGE_WHY.

#### 2. `merge_ident` lets git guess an identity from the host; the header's "none known refuses" holds only on hosts without a domain

**Severity:** Low
**Location:** `scripts/build-loop.sh:994-1001`
**Boundary:** B3
**Move:** 1 (per-consequence trust of S3), 2 (implicit assumption)
**Confidence:** High (fact-check 2b; refusal fix executed here)
**Legibility-target:** for-author

**Evidence:**
```
# commit-tree in the gate repository, which has no config. Returns 1 when git
# knows none (it never guesses one from the host name).
merge_ident() {
  local w x
  for w in AUTHOR COMMITTER; do
    x="$(env "${CALLER_GLOBAL[@]}" git var "GIT_${w}_IDENT" 2>/dev/null)" || return 1
```

Stage 1 claim 2b, built on here: with no env or config identity, `git var` builds one from the gecos name and `user@FQDN` (or `EMAIL`). It refuses only when the guess is bogus. On this host it refuses (`node@c965a4a7cd4f.(none)`), so test 3's "no identity" step passes here and would fail on a host with a domain. There, the merge commit lands under a guessed identity instead of refusing as documented. Rated Low, not higher: the identity is not an authenticated property (any same-uid caller can set any name through S2/S3), so no security property is lost. The impact is that attribution differs from the documented contract and the test depends on the host.

**Recommendation:** Pass `-c user.useConfigOnly=true` to the `git var` call. Probed on this host: it refuses with "no email was given and auto-detection is disabled" when only the guess is available, while `GIT_AUTHOR_*` env and config still win. That makes the comment true and test 3 independent of the host.

#### 3. The ff in W runs `git maintenance run --auto`; repo `maintenance.*` keys are outside the state gate, and `gc.auto=0` turns off only the gc task

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1071-1072`
**Boundary:** B2
**Move:** 12 (exec sweep), 1
**Confidence:** Medium (read-static plus fact-check 13; not executed)
**Legibility-target:** for-author

**Evidence:**
```
    # gc.auto=0: merge would start a git gc of the store store_check read.
    git -C "$w" -c gc.auto=0 merge --ff-only -q "$NEW" > "$GATE_TMP/ff" 2>&1 || { MERGE_WHY="the fast-forward in $in failed"; return 1; }
```

Per fact-check 13, the merge invokes auto-maintenance after the ref update. A planted `maintenance.<task>.enabled=true` in `.git/config` (for example loose-objects, incremental-repack, pack-refs) would then rewrite the store or refs after the move. None of these tasks is a command-exec primitive. Prefetch is stopped by `GIT_ALLOW_PROTOCOL=none`, and harden's env pairs carry to the child. On git 2.39 the run is synchronous, with no autoDetach. So this is hygiene, not an exploit. It matters because the comment presents `gc.auto=0` as the whole switch.

**Recommendation:** Use `-c maintenance.auto=false` in place of, or beside, `gc.auto=0`, and update the comment.

#### 4. The commit message is written with an unchecked redirect; a failed write commits with a truncated or empty message (no trailer)

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1023-1025`
**Boundary:** B6
**Move:** 3 (error path)
**Confidence:** Medium (read-static: `land` runs inside `if land`, so `set -e` is off there)
**Legibility-target:** for-author

**Evidence:**
```
  printf "Merge branch '%s' (build-loop self-merge)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "${VERDICT[stem]}" > "$GATE_TMP/msg"
  x="$(gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}" < "$GATE_TMP/msg")" \
```

If the write fails (for example a full disk in TMPDIR), commit-tree reads what was written, possibly nothing. The merge lands with the judged tree and parents but without the `Build-loop-gate:` provenance trailer. Tree and parents are unaffected.

**Recommendation:** `printf … > "$GATE_TMP/msg" || { MERGE_WHY="the merge message could not be written"; return 1; }`.

## Untested bypass candidates

Guards in scope: the W checks (B5), the rebase/bisect scan (B4), and the state-gate re-run (B2). Candidates traced or executed:

- **Tested, fail-closed:** assume-unchanged (P3) or skip-worktree (P4) set in W's index on a file the merge modifies, with a local edit. In both, the ff fails, main stays at M, and the local edit survives. W's index flags are not checked by `land` (unlike `checkout_gate` for ROOT), but git's own up-to-date check refuses.
- **Tested, cleared:** a worktree added at a dot-named path (`../.hid`). git names its admin dir `-hid`, so `"$common"/worktrees/*` (no dotglob) still sees it, and the rebasing-main refusal fired.
- **Tested, cleared:** `branch.main.mergeOptions=--no-ff`. `--ff-only` wins, and main moves.
- **Traced, cleared:** `worktree list --porcelain -z`. Every attribute is NUL-ended and prefix-tagged, so a `locked`/`prunable` reason or a path containing a newline cannot produce a `branch refs/heads/MAIN` record.

Listed, not tested:

1. **Hand-made dot-named admin dir** (`mv .git/worktrees/w .git/worktrees/.w` plus fixing W's `.git` file): git lists the worktree, but the bash glob skips it, so a rebase or bisect there goes unseen. Not tested because it needs a hostile non-git rename. Consequence traced, not run: the rebase's final update-ref is a CAS from orig-head and should fail, so no unjudged commit lands. Fix: `shopt -s dotglob` or `nullglob` around the loop.
2. **`core.worktree` in W's config (common config for the main worktree, or config.worktree):** `worktree list` reports the registered path, while `git -C "$w" status`/`merge` use the configured work tree. The added-path probes `-e "$w/$p"` then examine a different directory from the one the ff writes, so an ignored file there is overwritten. Not tested (it needs a populated clean alternate tree). A loop able to plant this can write that directory directly.
3. **Case-insensitive ref store (macOS/Windows, files backend):** a worktree on `Main` resolves to main's loose ref file but is listed as `branch refs/heads/Main`. The exact match at `:1032` misses it, `w` stays empty, and the CAS path moves main under a checked-out worktree, whose index then shows the merge reverted. Not testable on this Linux/ext4 host. If the repo ever runs on such a filesystem, this becomes a Medium.
4. **`refs/heads/main` holding an annotated tag id:** resolve_main peels it to MAIN_SHA. The CAS (old value MAIN_SHA ≠ the tag id) fails closed. In W, the ff's update of HEAD from the peeled id should fail after the checkout already wrote W. Not tested. Damage to W only.
5. **`core.sparseCheckout` / `core.ignoreCase` / `core.symlinks=false` in W (when W ≠ ROOT):** `checkout_gate` checks these for ROOT only. Their effect on the ff in W (unwritten sparse paths, case-folded collisions with an ignored file) is not tested.

Because of these candidates, the W checks and the rebase/bisect scan do not appear under Endorsement Claims.

## Endorsement Claims

- **Claim:** The commit `--merge` writes has the tree `check_line` judged and the parents (MAIN_SHA, the judged tip) in that order. It is built from the VERDICT values set only by `verdict_ok`, not re-resolved from refs.
  **Location:** `scripts/build-loop.sh:976, 1024, 1100-1103`
  **Evidence:** executed
  **Verified:** read `verdict_ok` and `land` through the commit-tree call. Ran `test/scripts/build-loop-merge.bats` serially (6/6 ok); test 1 asserts `n^1 n^2 n^{tree}` = `M T TR`.
  **Not verified:** that `check_line "$a" > file` cannot leave VERDICT set from an earlier path in some refusal branch other than the ones read (`co` refusal, `nd>0`, early returns all precede or skip `verdict_ok`). A fact-check pass should mutate each early-return branch.
  **route: code-fact-check**

- **Claim:** In the no-W path, the branch moves only by `update-ref` with old value MAIN_SHA, so a branch moved after the check is left as it is.
  **Location:** `scripts/build-loop.sh:1068-1069`
  **Evidence:** executed
  **Verified:** test 2 (shim moves main just before update-ref; main stays at the other commit; refusal printed).
  **Not verified:** the case where `refs/heads/MAIN` is a symref. update-ref follows it (row 215's main_by_name guard is settled, and not re-checked here).
  **route: code-fact-check**

- **Claim:** The ff in W runs with hooks, fsmonitor and core.attributesFile overridden by harden's `GIT_CONFIG_COUNT` pairs, which take precedence over W's repo config, and with the global config at /dev/null.
  **Location:** `scripts/build-loop.sh:302-315, 1072`
  **Evidence:** read-static
  **Verified:** harden exports the pairs before any git call. `land` adds only `-c gc.auto=0` and does not unset them.
  **Not verified:** keys outside harden's list and the state gate's list that `git merge`/checkout read (Finding 1 is one; `maintenance.*` is Finding 3; `core.worktree` is candidate 2).
  **route: code-fact-check**

- **Claim:** `merge_ident` exports a name and email only when `git var`'s line matches `NAME <EMAIL> SECONDS ±HHMM` with no `<`/`>` in either part, so the ident cannot carry a header-injecting newline into commit-tree.
  **Location:** `scripts/build-loop.sh:997-999`
  **Evidence:** read-static
  **Verified:** the regex. `$(...)` strips only trailing newlines, and `[^<>]+` admits no newline-free bypass of the angle brackets.
  **Not verified:** whether `[^\<\>]+` admits an embedded newline in NAME. git's ident sanitizer (strbuf_addstr_without_crud) is the hop that removes it, and it was not executed here.
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec of git against loop-writable config (S4) or with loop-influenced arguments

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:997` `env … git var GIT_*_IDENT` | S3, S4 | harden pairs; regex on output | Finding 2 (guessing); include/fifo in S3 can hang the call (DoS only, cleared: a loop already controls the host) |
| `build-loop.sh:1024` `gate_git commit-tree` | S6 ids (VERDICT), S8 text | gate repo (no repo config), `--no-gpg-sign`, ids hex | Finding 4 (message write); args cleared |
| `build-loop.sh:1028` `git worktree list --porcelain -z` | S5 | NUL-ended parse | cleared (traced) |
| `build-loop.sh:1040-1043` `cat …/head-name`, `BISECT_START` | S5 | none (read only) | candidate 1 (dot-named dir) |
| `build-loop.sh:1045` `git -C "$w" symbolic-ref` / `rev-parse` | S4 (W), S5 | harden | cleared |
| `build-loop.sh:1048` `git -C "$w" rev-parse --git-path` | S4 (W) | harden | cleared |
| `build-loop.sh:1051` `git -C "$w" status` | S4 (W), S7 | harden; stderr must be empty | cleared (index flags: P3/P4 fail-closed later) |
| `build-loop.sh:1065` `state_gate`, `default_gate`, `(cd "$w" && state_gate)` | S4, S5 | itself | cleared; scope gap is Finding 1 |
| `build-loop.sh:1068` `git update-ref` CAS | S6 | old-value MAIN_SHA, harden (no reference-transaction hook) | cleared (endorsement 2) |
| `build-loop.sh:1072` `git -C "$w" merge --ff-only` | S4 (W), S6, S7 | harden, state gate re-run, W checks | Finding 1, Finding 3, candidates 2-5 |
| `build-loop.sh:1074` `git rev-parse refs/heads/MAIN` | S6 | — | cleared (post-condition) |

Primitive: path construction from merge paths and the worktree list

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:1055` `"$w/$p"` | S5 (w), S6 (p, from diff-tree) | p passed nrules' pathform (no `..`, no leading `/`, no `.git*`), else no verdict | cleared for traversal; candidate 2 (core.worktree mismatch) |
| `build-loop.sh:1056-1061` `"$w/$q"` ancestors | S5, S6 | `-d && ! -L` per ancestor | cleared for symlinked ancestors (test 6); candidate 5 |
| `build-loop.sh:1039` `"$common"/worktrees/*` | S5 | glob without dotglob | candidate 1 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `branch.<main>.mergeOptions=--squash` stages the merge in W without moving main; key outside the state gate | Medium | B2, B5 | `scripts/build-loop.sh:1072` | High |
| 2 | `git var` guesses an identity on a host with a domain; doc says it refuses | Low | B3 | `scripts/build-loop.sh:994-1001` | High |
| 3 | Auto-maintenance after the ff; `maintenance.*` ungated, `gc.auto=0` covers gc only | Informational | B2 | `scripts/build-loop.sh:1071-1072` | Medium |
| 4 | Unchecked write of the merge message; trailer can be lost | Informational | B6 | `scripts/build-loop.sh:1023-1025` | Medium |

## Overall Assessment

On the paths read and run, `--merge` moves main only to a commit whose tree and parents are the ids the gate judged, and only by compare-and-swap from MAIN_SHA (CAS path) or by a post-checked fast-forward (W path). No finding makes main point to something the gate did not judge. The one Medium is checkout damage: an ungated `branch.<main>.mergeOptions=--squash` leaves the merge staged in W's index (and stops later runs) while main stays put. It is reachable on the honest path, and a one-token `-c "branch.$MAIN.mergeOptions="` fixes it in place. Finding 2 is the fact-check's 2b with a verified one-flag fix (`-c user.useConfigOnly=true`). Findings 3 and 4 are hygiene. The design is sound and the fixes are local. The single most important item is Finding 1. The W checks and the rebase/bisect scan have listed untested bypass candidates (dot-named admin dir, core.worktree redirect, case-insensitive ref store, W-only checkout config), so the verdict is: *no findings beyond those listed within the code paths read; endorsement claims pending execution verification*. This is not a categorical all-clear.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/security-review-2026-10-10-u3a2-i1.md, structured per the security-reviewer skill.
- Answered: what can make `--merge` move main to something unjudged (nothing found; the commit is pinned by value, and the CAS and the post-ff check hold), or damage a checkout (Finding 1, executed; candidates 2-5); the W checks, worktree-list parsing, the state-gate re-run, merge_ident's global config and identity guessing (Finding 2), and maintenance after the ff (Finding 3).
- Out of scope: settled override rows (GATE_TMP race 509, rewrite of main's objects after startup 646, symref main 215); racing writers (Q-103 residual, already named in the header); the U3a1 gate rules themselves.
- Escalate: none. Candidate 3 (case-insensitive ref store) becomes a Medium if the repo is ever used on macOS/Windows; worth a line in the plan's residuals.
