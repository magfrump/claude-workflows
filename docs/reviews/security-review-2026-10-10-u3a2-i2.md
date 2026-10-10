# Security Review — feat/build-loop-u3a2 (U3a2 `--merge`, iteration 2: the i1 fix batch)

Commit: f782d9ee
**Scope:** `git diff 7d78e6d0..f782d9ee -- scripts test` (the fix batch: `merge_ident`, `land`, the merge arm, `check_line`'s `verdict_ok`, `test/scripts/build-loop-merge.bats`). The rest of the branch is context only.
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-u3a2-i2.md` (0 Incorrect; mutants M1-M4 caught, M7 and M8 survive), `docs/reviews/security-review-2026-10-10-u3a2-i1.md`, rubric `code-review-rubric-2026-10-10-feat-build-loop-u3a2.md`. The 2026-10-10 override rows (653-661) and rows 215, 494, 509, 512, 639 and 646 are treated as settled.

No HALT escalation: no escalation pattern matched.

**Iteration-1 status.** F1 (mergeOptions) is closed. F2 (identity guessing) is closed. F3 (maintenance) and F4 (unchecked message write) are closed. Untested candidate 1 (dot-named admin dirs) is closed, and so is candidate 2 (core.worktree elsewhere). Candidates 3 to 5 are settled by rows 655-657. Rubric items A1, A2 and A3 are resolved, and no regression was found. One pre-existing ordering gap is new to this review (Finding 1). The fix batch did not cause it, but the reorder question in the brief points straight at it.

## Trust Boundary Map

```
B1: [caller argv + env (S1, S2)]                → [arg parser; harden; GIT_* exports]                → [gate process]
B2: [W's config.worktree (S4w)]                 → [state_gate in W: only at the re-run, :1087]        → [git -C W status :1069 / merge --ff-only :1096]   (ordering at issue: Finding 1)
B3: [caller global config + env (S3, S2)]       → [merge_ident: git -c user.useConfigOnly=true var]   → [GIT_{AUTHOR,COMMITTER}_* → commit-tree, reflogs]  (changed)
B4: [worktree admin dirs (S5)]                  → [worktree list -z; head-name/BISECT_START scan, dot globs] → [CAS-vs-ff choice; refusals]           (changed)
B5: [repo config in W (S4), W's work tree (S7)] → [-ef top-level check; W checks; -c overrides]       → [ff checkout and ref move in W]                    (changed)
B6: [VERDICT values (S6, S8)]                   → [commit-tree in the gate repo, now after the W checks] → [update-ref CAS / ff → refs/heads/MAIN]        (moved)
```

Input-source classification:

```
S1:  argv (brief path, --expect)                   — request-time    — trusted (caller is the orchestrator)
S2:  caller env (GIT_AUTHOR_*/COMMITTER_*, EMAIL,
     GIT_CONFIG_GLOBAL, GIT_CONFIG_PARAMETERS)     — request-time    — trusted (documented)
S3:  caller global config                          — runtime-mutable — UNTRUSTED for exec; read only by git var, for attribution
S4:  common .git/config                            — runtime-mutable — UNTRUSTED for every git sink; state-gated at startup (ROOT) and re-run
S4w: W's config.worktree (W != ROOT)               — runtime-mutable — UNTRUSTED for every git sink; first state-gated only at :1087
S5:  .git/worktrees/*/ (head-name, BISECT_START,
     rebase-merge/update-refs)                     — runtime-mutable — UNTRUSTED for the land/refuse decision
S6:  object store + refs                           — runtime-mutable — ids pinned by --expect and store_check
S7:  W's untracked/ignored files, .gitattributes   — runtime-mutable — UNTRUSTED; feeds git's attribute lookup in W
S8:  brief stem / Branch: on main's commit         — committed       — trusted for message and reflog text (git collapses newlines in reflog messages)
```

The fix batch narrows B5. W's top level must now be W itself, and the branch's mergeOptions and auto-maintenance are switched off for the one merge call. It also narrows B3: no host-guessed identity. One source sits outside the startup gate, though. When W is a linked worktree (not ROOT), the config.worktree of W (S4w) is first read by the gate's own `git -C "$w"` calls and only state-gated at `:1087`. Finding 1 shows a planted filter in that file running inside the gate and erasing itself before the gate looks.

## Findings

#### 1. W's config.worktree is state-gated only after `git -C "$w" status` has run with it; a planted filter runs inside the gate and can delete its own key so the landing proceeds

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1062-1070` (first W reads) against `:1087` (first W state gate)
**Boundary:** B2
**Move:** 4 (TOCTOU), 3 (order of checks), 11 (bypass of the state gate)
**Confidence:** High (executed, on f782d9ee and on 7d78e6d0)
**Legibility-target:** for-author

**Evidence:**
```
    git -C "$w" status --porcelain=v1 -z --untracked-files=no > "$GATE_TMP/wstatus" 2>"$GATE_TMP/err" && [[ ! -s "$GATE_TMP/err" && ! -s "$GATE_TMP/wstatus" ]] \
      || { MERGE_WHY="$in has a tracked change, or git status failed or warned there"; return 1; }
...
  { state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; } > "$GATE_TMP/state" \
    || { MERGE_WHY="the git state changed after the check ($(head -n 1 "$GATE_TMP/state"))"; return 1; }
```

The startup `state_gate` runs in ROOT. It reads the common config and ROOT's own config.worktree. When the default branch is checked out in another worktree W (the `orch` layout), nothing reads W's config.worktree until the re-run at `:1087`. By then the gate's git has already run in W, and `git status` cleans stat-dirty tracked files through any filter that attributes assign. Probes P1 and P1b set this up: `extensions.worktreeConfig=true` (a key the gate does not check), `filter.p.clean` in `$R/.git/config.worktree`, an untracked `* filter=p` `.gitattributes` in W, and a touched tracked file.

- **P1:** the filter ran, then the re-run refused (`refuse state filter.p.clean: set in config.worktree…`), and main stayed put.
- **P1b:** the filter also deleted config.worktree. The filter ran, the re-run saw nothing, and the result was `merged …` with exit 0.

The same P1b result appears at 7d78e6d0, so the gap predates the fix batch. The fix batch's reorder left it in place.

This goes against the state gate's stated purpose: "repo-local git state that can make the gate's git run a command … --check refuses planted state before any git call reads". It is not a race. The command runs deterministically inside the gate, in the window between the W checks and the move. The commit that lands is still the judged one, since NEW is pinned by value and the move is a CAS or a post-checked ff. A clean filter can also make W's status read clean over a modified tracked file. The ff's own up-to-date check (run without the filter, once the key is gone) refuses if the merge touches that file. What escapes is the planted-state refusal itself, plus a command the gate was designed never to run.

**Recommendation:** Run `(cd "$w" && state_gate)` as soon as `w` is known, before the first `git -C "$w"` call at `:1062`, mapping a refusal to the existing "the git state changed…" text or a W-specific one. Keep the re-run at `:1087`. Add a test: the bats layout above with an `exit 1` filter that writes a marker. Expect a refusal and no marker.

#### 2. A paused `rebase --update-refs` in another worktree that will move main is not seen by the scan

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1053-1060`
**Boundary:** B4
**Move:** 5 (what the check does not cover)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
    for q in rebase-merge/head-name rebase-apply/head-name; do
      [[ ! -f "$d/$q" || "$(<"$d/$q")" != "refs/heads/$MAIN" ]] || { MERGE_WHY="a worktree is rebasing the default branch"; return 1; }
```

Probe P4 paused `rebase -i --update-refs main~1` on feat/z in worktree rz. Its `head-name` was `refs/heads/feat/z`, and `rebase-merge/update-refs` listed `refs/heads/main <old> 0…0`. `--merge` landed. A later `rebase --continue` then failed only that ref: `cannot lock ref 'refs/heads/main': is at NEW but expected <old>`, and main stayed at NEW. Main is safe, because git's update is a CAS. The user's rebase errors on that ref instead of `--merge` refusing up front. Git 2.39 itself counts update-refs targets as checked out. The header's "a worktree is rebasing it" reads as covering this case.

**Recommendation:** Either refuse when any `rebase-merge/update-refs` under the scanned dirs has a line starting `refs/heads/$MAIN `, or add an override row naming it as fail-closed for main.

## Untested bypass candidates

Guardrails in scope: the `-c` overrides on the ff (B5), the `-ef` top-level check (B5), the dot-glob scan (B4), and the reordered land (B6).

Tested or traced:

- **mergeOptions (i1 F1), traced and executed.** The `-c` pairs are read last: system and global are off, then local, then config.worktree, then GIT_CONFIG_COUNT, then `-c`. merge.c matches `branch.<HEAD's branch>.mergeoptions`, and `:1062` pins HEAD's branch to `$MAIN`. So the empty value replaces any repo or config.worktree value, including `--squash`, `--autostash` and `--no-ff`. Fact-check M1 and test 4 confirm it.
- **Other config read by `merge --ff-only` in W, traced.**
  - `merge.ff`, `merge.autoStash` and `merge.verifySignatures` are state-gated as `merge.*`, and the command-line `--ff-only` beats `merge.ff`.
  - `branch.<main>.merge`/`.remote` are read only when no commit is named.
  - `branch.<main>.rebase`, `pull.ff` and `pull.rebase` are read by pull only.
  - `rerere.*` applies to conflicts only, and an ff has none.
  - `advice.*`, `color.*` and `merge.stat` affect output only (`-q`).
  - `core.hooksPath`, `core.fsmonitor` and `core.attributesFile` are set by harden's env pairs.
  - `trace2.*` is read from system and global config only, and both are off for this call.
  - `gc.auto` and `maintenance.auto` are set by `-c`. Fact-check claim 19 confirms no maintenance runs.
- **`pull.twohead`, executed (P2).** Merge reads it for its strategy list. Naming a `git-merge-evil` on PATH: the strategy did not run on the ff, and main moved. Naming a missing strategy: the ff fails, so the result is a fail-closed refusal with the text "the fast-forward … failed".
- **`-ef` with a relative `core.worktree=..`, executed (P3).** It names W itself, so the run lands, and the probes and the ff act on the same directory. With `core.worktree` elsewhere, test 6 shows a refusal. With W's `.git` removed, `git -C` would find an enclosing repo, its top level is not `-ef` W, and the run refuses (traced). Before the fix, symbolic-ref would have read the enclosing repo.
- **W added through a symlinked parent, executed (P3).** git records the real path, so the run lands. `-ef` compares inodes, so a symlinked spelling of W also passes, and every later probe goes through the same `$w`.
- **Dot globs.** Fact-check claim 17 (probe of `a .b ..c ... .- .x.y -z .? .[`, plus mutant M3) covers them.
- **Reorder, traced.** Every refusal that reads W, the worktree list or the identity now comes before commit-tree. Only the state and default gates and the move come after it, so a refusal after the write leaves an unreachable object (documented). No check moved past the move. The W checks are one commit-tree further from the move than before (a Q-103 residual).
- **`GIT_REFLOG_ACTION`, traced.** It is a prefix assignment, so it reaches only the merge and its children (hooks off, maintenance off). merge.c does not overwrite an existing value. git collapses whitespace and newlines in reflog messages, so the stem cannot add a line.

Listed, not tested:

1. **`submodule.recurse=true` in W's config with a merge that changes a gitlink.** Not tested whether merge's ff checkout recurses on git 2.39 (traced belief: merge does not read it). No exec route without a transport, since `GIT_ALLOW_PROTOCOL=none`.
2. **`core.autocrlf`, `core.eol` or checkout `working-tree-encoding` in W's config.** These change W's bytes only. They belong to the same class as row 657 (W's own checkout settings) and were not re-tested.
3. **An unreadable (`chmod 000`) `head-name` or `BISECT_START`** reads as empty and passes the scan. git's own `rebase --continue` cannot read it either. Needs a hostile same-uid writer. Not tested.
4. **`GLOBIGNORE` inherited from the caller's environment** would change what the dot globs match. The caller's environment is trusted (S2). Not tested.

Because of Finding 1 and these candidates, the W checks and the scan do not appear under Endorsement Claims.

## Endorsement Claims

- **Claim:** `-c "branch.$MAIN.mergeOptions="` on the ff makes `--squash` in W's repo config inert: main moves to NEW and W's index is left clean.
  **Location:** `scripts/build-loop.sh:1096`
  **Evidence:** executed
  **Verified:** test 4 (`git config branch.main.mergeOptions --squash`, then status 0, W at main, and empty `status --porcelain`); fact-check mutant M1 fails that test.
  **Not verified:** the same key set in W's `config.worktree` rather than the common config. By precedence it is lower than `-c`, but it was not executed.
  **route: code-fact-check**

- **Claim:** `merge_ident` refuses when only a host-guessed name or email is available, including an email only in `EMAIL`.
  **Location:** `scripts/build-loop.sh:1011-1017, 1041`
  **Evidence:** executed
  **Verified:** test 3's EMAIL-only case; fact-check `ident.log` cases 2, 4 and 6, and mutant M2.
  **Not verified:** a host with a resolvable domain (the guess path is refused before it runs, per case 2, but no such host was used).
  **route: code-fact-check**

- **Claim:** A W whose `rev-parse --show-toplevel` is not the same inode as the listed worktree path is refused before any work-tree read.
  **Location:** `scripts/build-loop.sh:1062-1064`
  **Evidence:** executed
  **Verified:** test 6 (`core.worktree` set elsewhere gives the refusal); P3 (a relative `core.worktree=..` naming W lands).
  **Not verified:** a caller-set `GIT_WORK_TREE`. That is covered by checkout_gate's local-env-var refusal for self-merge briefs; not executed here.
  **route: code-fact-check**

- **Claim:** The merge message write is checked before commit-tree reads it.
  **Location:** `scripts/build-loop.sh:1083-1085`
  **Evidence:** read-static
  **Verified:** `printf … > msg && x="$(… commit-tree …)" && [[ hex ]] || refuse`.
  **Not verified:** a full TMPDIR at runtime (not executed).

## Primitive sweep

Primitive: process exec of git against loop-writable config, or with loop-influenced arguments (changed call sites in the fix batch)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:1014` `env … git -c user.useConfigOnly=true var` | S2, S3 | regex on output; no system file | cleared (i1 F2 closed) |
| `build-loop.sh:1043` `git worktree list --porcelain -z` | S5 | NUL-ended parse | cleared (unchanged) |
| `build-loop.sh:1053` `git rev-parse --git-common-dir` | S4 | harden | cleared |
| `build-loop.sh:1057, 1059` `$(<…/head-name)`, `$(<…/BISECT_START)` | S5 | `-f` | Finding 2 (update-refs not read); candidate 3 (unreadable file) |
| `build-loop.sh:1062-1063` `git -C "$w" rev-parse --show-toplevel` / `symbolic-ref` / `rev-parse HEAD` | S4, S4w | harden; `-ef` | reads W's config.worktree before W's state gate (no exec found in these commands) — Finding 1 context |
| `build-loop.sh:1066` `git -C "$w" rev-parse --git-path` | S4, S4w | harden | cleared |
| `build-loop.sh:1069` `git -C "$w" status` | S4w, S7 | harden only | **Finding 1** (planted filter runs) |
| `build-loop.sh:1084` `gate_git commit-tree` | S6, S8 | gate repo, no config, `--no-gpg-sign` | cleared (now after the W checks) |
| `build-loop.sh:1087` `state_gate` / `default_gate` / `(cd "$w" && state_gate)` | S4, S4w, S5 | itself | Finding 1 (too late for W) |
| `build-loop.sh:1090` `git update-ref -m "$msg"` CAS | S6, S8 | old value MAIN_SHA | cleared |
| `build-loop.sh:1096` `GIT_REFLOG_ACTION=… git -C "$w" -c … merge --ff-only` | S4, S4w, S6, S7 | harden; `-c` gc/maintenance/mergeOptions; re-run state gate | i1 F1/F3 closed; candidates 1-2 |

Primitive: path construction from merge paths and admin dirs

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:1054` `"$common"/worktrees/{*,.[!.]*,..?*}` | S5 | `-d` filter | cleared (fact-check claim 17); candidate 4 |
| `build-loop.sh:1072-1079` `"$w/$p"` and its ancestors | S6, S5 | pathform; `-ef` makes `$w` git's top level | cleared (i1 candidate 2 closed) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | W's config.worktree is first state-gated after `git -C W status` ran a planted filter, which can erase itself so the land proceeds (pre-existing at 7d78e6d0) | Medium | B2 | `scripts/build-loop.sh:1069` vs `:1087` | High |
| 2 | A paused `rebase --update-refs` that will move main is not seen; the later rebase fails its ref, and main is safe | Informational | B4 | `scripts/build-loop.sh:1053-1060` | High |

## Overall Assessment

The fix batch closes what it set out to close. The empty `-c` value overrides mergeOptions at every config level below the command line. `user.useConfigOnly` ends host guessing, EMAIL-only included. The `-ef` top-level check closes the core.worktree split, and as a side effect a W whose `.git` vanished. The dot globs cover every admin-dir name. The reorder puts every decision but the state gate before the write. No probe made main point at anything but the judged commit.

The one Medium is an ordering gap the fix batch kept, not one it caused. For a linked W, the first state gate of W's own config.worktree comes after `git -C "$w" status`. So a planted filter runs inside the gate, and it can delete itself before the re-run looks (executed: merged, exit 0). The fix is local: gate W as soon as it is identified and keep the re-run before the move. That is the single most important item. Finding 1 and the listed candidates remain open, so the verdict is: *no further findings within the code paths read; endorsement claims pending execution verification*. This is not a categorical all-clear.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/security-review-2026-10-10-u3a2-i2.md, structured per the security-reviewer skill.
- Answered: i1 F1 and F2 are fully closed (plus F3, F4 and candidates 1-2). The config sweep of `merge --ff-only` in W covered merge.*, branch.<main>.*, pull.* (pull.twohead executed), core.*, rerere, autostash, advice and trace2. The -ef test was probed with a relative core.worktree, a symlinked parent and a missing .git. The dot globs are covered via the fact-check. The reordered land has no check after the write that should precede it, but the W state gate comes after W's first git reads (Finding 1). GIT_REFLOG_ACTION is scoped and sanitized.
- Out of scope: settled override rows (653-661, 215, 494, 509, 512, 639, 646); racing writers (Q-103); the test-coverage gaps the fact-check names (mutants M7 maintenance.auto and M8 CHANGED fill survive). These are test strength, not security, and are worth a test each.
- Escalate: none. Finding 1 predates the fix batch (present at 7d78e6d0). The orchestrator decides whether it is fixed in this loop or recorded as an override row; its fix is a one-line move plus a test.
