# Security Review — feat/build-loop-u3a2 (second confirming pass: ce38eafb interim fixes, 2028aa89 test)

Commit: 2028aa89
**Scope:** `git diff 20de9671..2028aa89 -- scripts test`. That is ce38eafb (`land()` in scripts/build-loop.sh: G1 per-admin-dir searchability, G2/G3 HEAD via `git --git-dir=D symbolic-ref -q HEAD`, G4 bare repositories) and 2028aa89 (the test for W's `-ef "$hd"` check). Context read: all of `land`, `state_is`, `state_gate`, `default_gate`, `gate_start`, and the `--merge` header (lines 213-256).
**Date:** 2026-10-10
**Based on:** docs/reviews/security-review-2026-10-10-u3a2-confirm.md (probes n1-n4, findings 1-5); rubric docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a2.md (Confirming pass G1-G7, E-rows); open questions Q-138 and Q-103 (threat-model routing).
**Probes:** /tmp/claude-1000/-workspace/40e0f8b3-aa3f-469f-bdce-910cba5247e9/scratchpad/u3a2-c2-security/. `helpers.sh` is the fixture (test/lib/build-loop-fixtures.bash plus brief x and feat/x). The probes are `h1.sh` (honest layouts), `p1.sh` (re-runs and planted state), `p2.sh` (exec, broken admin dirs, full output) and `m1.sh` (a mutant of the `-ef` clause run against 2028aa89's test). Outputs are in `h1.out`, `p1.out`, `p2.out` and `m1.out`. `old/` is `git archive 20de9671 scripts`. Every probe ran against both scripts with `OLD=0|1`, each in its own `/tmp/u3a2c2-sec-*` dir under `timeout 60`, and every dir was removed (`ls -d /tmp/u3a2c2-sec-*` matched nothing). `bats test/scripts/build-loop-merge.bats` ran serially with its own TMPDIR: 1..7, all ok. git 2.39.5.

> ⚠️ **No code fact-check report provided** for this pass. Claims in comments and in the header were checked against the code and the probes below, but no separate fact-check was run.

## Trust Boundary Map

```
B1: caller argv/env (BRIEF, --expect, identity)              → usage parse, merge_ident regex              → commit and reflog text
B2: W's own git dir and work tree                             → (cd W && state_gate), -ef top level,         → merge --ff-only in W
                                                                -ef holder git dir (now tested), status
B3: repo-shared refs (symbolic refs under refs/heads)         → default_gate; symbolic-ref chain (moved)     → "who has main", CAS --no-deref
B4: per-admin-dir state ($common, $common/worktrees/*,        → searchability loop per dir (moved),          → holder count n vs list's w,
    dot names; HEAD, rebase-*, BISECT_START, commondir)         git --git-dir=D symbolic-ref (new),            "nobody will move main later"
                                                                state_is on rebase/bisect files
B5: (new) worktree list's `bare` marker + $common/index       → bare=1 skips $common's HEAD;                 → holder count
                                                                index present ⇒ refuse
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | caller argv and environment | request-time | trusted (header: the caller's environment is trusted) |
| S3 | refs incl. symbolic refs under refs/heads and per-worktree refs/worktree/* | runtime-mutable (any same-uid loop) | UNTRUSTED toward "who has main" |
| S4 | W's config.worktree, HEAD, index, files | runtime-mutable | UNTRUSTED toward exec (state-gated) and "W is clean" |
| S5 | admin-dir files: HEAD, commondir, config.worktree, rebase-*, BISECT_START | runtime-mutable | UNTRUSTED toward land-or-refuse and toward exec when git opens D (`--git-dir=D` reads D's commondir and config.worktree, which state_gate does not scan) |
| S6 | `core.bare` (common config or the caller's config.worktree) and `$common/index` | runtime-mutable | UNTRUSTED toward "is the common dir's HEAD a checkout" |
| S7 | git 2.39.5's own parsing | code-constant | trusted. Since ce38eafb land asks git (symbolic-ref) and no longer re-implements HEAD parsing |

What crosses: ce38eafb changes B4 from "awk reads HEAD" to "git opens each admin dir as a repository and resolves HEAD". That closes the parse-mismatch class (re-runs below), and it makes S5's `commondir` and `config.worktree` inputs to a git process. B5 is new: a configuration value, `core.bare`, now decides whether one HEAD is counted at all.

## Re-runs of the prior pass's findings, before (20de9671) and after (2028aa89)

| Prior item | Probe (p1.sh / p2.sh variant) | 20de9671 | 2028aa89 |
|---|---|---|---|
| F1 / G2: W's HEAD is `ref:\r…` or `ref:\n…` and its gitdir file is removed (git reads main) | cr-sep, nl-sep | merged, main moved | refuse "…git worktree list does not show" |
| F1 variant: `ref:\v`/`\f` separator or a trailing `\v`/`\f` (git cannot open W) | vt-sep, ff-sep, vt-tail, ff-tail | merged | refuse "git state (HEAD) cannot be read" |
| F2 / G3: W on `refs/heads/alias → refs/heads/main`, gitdir removed | alias | merged | refuse |
| New variant: HEAD → `refs/worktree/m` → `refs/heads/main` (a per-worktree symref), gitdir removed | wtref | merged | refuse |
| F3 / G1: `.x` or `..x` admin dir with a mode-000 `rebase-merge` of main | dot-000, dotdot-000 | merged | refuse "git directory or rebase state cannot be read" |
| F4 / G4: bare clone + detached worktree; + linked W on main; run from W; bare at `p/.git` | h1 bare-none, bare-linked, bare-from-w, bare-dotgit | refuse (false) | merged; W fast-forwarded |
| F5 / G7: symlink HEAD (core.preferSymlinkRefs) | symlink-head | refuse | refuse (unchanged; accepted as G7) |
| G6: 2028aa89's test pins `-ef "$hd"` | m1.sh: mutant with that clause deleted | n/a | mutant: test 6 fails at line 157 (`status 0`, merged into the rogue copy); original: ok |

## Honest layouts (h1.sh, run from the worktree shown; both scripts)

| Layout | 20de9671 | 2028aa89 | Regression? |
|---|---|---|---|
| main worktree on main, no `worktrees/` dir | merged | merged | no |
| detached linked caller, no holder | merged | merged | no |
| linked W on main (from another worktree / from W) | merged, W ff'd | merged, W ff'd | no |
| `.hid` / `..hid` / `o x` worktree paths (git 2.39 names the admin dirs `-hid`, `-o`, `o-x`; it never creates a dot-named admin dir) | merged | merged | no |
| locked W on main (lock reason "bare") | merged | merged | no |
| real paused `rebase -i` of another branch | merged | merged | no |
| bare clone + worktrees (4 shapes) | refused | merged | fixed (G4) |
| bare repo with an index used via `--work-tree` (dotfiles style) | refused | refused ("lists as bare but has an index") | no. The refusal is defensible: that HEAD is checked out at the external work tree |
| `--separate-git-dir` clone + linked W on main | merged | merged | no |
| `--separate-git-dir` clone, main worktree on main | refused | refused | no (pre-existing; Finding 3) |
| submodule (gitfile into `.git/modules/sub`), main worktree on main | refused | refused | no (pre-existing; Finding 3) |
| submodule, detached + linked W on main | merged | merged | no |
| symlinked `.git` directory | merged | merged | no |

I found no false refusal of an honest layout that 20de9671 landed. The only new refusals are admin dirs that git itself cannot open (Finding 2).

## Findings

#### 1. G4 lands under a main worktree when `core.bare=true` is planted and that worktree's index is removed

**Severity:** Low
**Regression:** yes. 20de9671 counted `$common/HEAD` unconditionally and refused. 2028aa89 skips it and lands.
**Class:** planted git state by a same-uid writer (route to Q-103)
**Location:** `scripts/build-loop.sh:1062` (`bare) bare=1`), `:1071` (index check), `:1083` (skip of `$common`)
**Boundary:** B5
**Move:** 11 (bypass of the new guard)
**Confidence:** High (executed)

Probe p1 `corebare-noindex`: the main worktree is on main, the caller is a detached linked worktree, and the writer plants `git config core.bare true` and runs `rm .git/index`. The worktree list then prints the main record as `bare` with no branch line. The index check passes because no index exists. n=0 and w is empty, so land moves main by CAS. The writer then restores the main worktree (`core.bare` unset, `read-tree M`). Its HEAD is the merge and its index is at M, and `git status` shows `D  work-feat-x.txt`. A commit there reverts the merge.

Three things argue for Low rather than Medium:
- At the moment of the move, git takes the same view. `git branch -f main HEAD` from the linked worktree succeeds in the same state, so git's own checked-out guard did not see a holder either. Git in the main worktree fails with "must be run in a work tree".
- The attack needs two plants (a config write and an index deletion) by a writer who could move main directly.
- The floor rule excludes scenarios where the attacker already controls the host. If the team keeps the earlier passes' convention of rating executed planted-state misses Medium, rate this Medium.

The other G4 bypass shapes refuse. A planted `core.bare` with the index present refuses (p1 `corebare-index`), and so does a `core.bare` in the caller's config.worktree, because the common index exists. A `locked`/`prunable` reason cannot equal the `bare` field, because porcelain -z prints those fields as `locked REASON`.

**Recommendation:** Route to Q-103 as Q-138 directs. If it is closed later, the cheapest closure is to also refuse a listed-bare repository whose `$common` has the files a checkout leaves (`logs/HEAD` entries of type checkout, `ORIG_HEAD`), or to add `core.bare` to what state_gate refuses when the repository is not bare by `rev-parse --is-bare-repository` from the main worktree path. Both are heuristics. Q-103's residual entry is the honest answer.

#### 2. An admin dir that git cannot open now refuses every landing, and git's `fatal:` line reaches stderr

**Severity:** Informational
**Regression:** yes (a behaviour change that fails closed). 20de9671 merged in all these cases.
**Class:** other (availability and output contract on a damaged layout; no fail-open)
**Location:** `scripts/build-loop.sh:1081-1082`
**Boundary:** B4
**Move:** 3 (error path)
**Confidence:** High (executed) for the refusals. Medium for the honest reach.

These cases now refuse, with git's `fatal:` line on stderr (p2 `vt-full` shows the exact stream split: stdout has the refusal and the path lines, stderr has `fatal: not a git repository: '<repo>/.git/worktrees/w'`):
- p2 `no-commondir`: a worktree unrelated to main (detached) has no `commondir` file.
- p2 `bad-commondir`: its `commondir` names a missing directory.
- p1 `vt-sep`, `ff-tail`: a HEAD that git rejects.

Each makes `git --git-dir=D symbolic-ref` exit 128. That fails closed, as intended. Two side effects follow:
- A broken worktree that has nothing to do with main blocks every landing until someone repairs or removes it.
- The `symbolic-ref` call has no `2>` redirect, so git's message, with an absolute path, goes to the caller's stderr. Elsewhere land keeps git's stderr in `$GATE_TMP`.

By reading git 2.39's `add_worktree`, the order of writes is gitdir, then HEAD (null oid), then commondir. A `git worktree add` interrupted in that window would leave this state honestly. I did not execute that interruption.

The header's refusal list says a HEAD that "cannot be read (exists but is not a readable plain file…)". It does not say "or git cannot open that worktree's git directory", which is the case here.

**Recommendation:** Send the `symbolic-ref` stderr to `$GATE_TMP/err` (or `/dev/null`) and add the case to the header line. Keep the refusal.

#### 3. Pre-existing: a main worktree on main in a separate-git-dir or submodule (gitfile) repository refuses

**Severity:** Informational
**Regression:** no (identical on 20de9671 and 2028aa89)
**Class:** other (honest-path false refusal; fails closed)
**Location:** `scripts/build-loop.sh:1063`, `:1097-1100`
**Boundary:** B2
**Move:** 5
**Confidence:** High (executed: h1 `sepgit`, `submodule`; p2 `sepgit-full`)

git 2.39's `worktree list` gives the main record's path as the common dir with `/.git` stripped: `<T>/sep.git` and `<super>/.git/modules/sub`. It does not give the real work tree. So w is the git dir, and the top-level check fails with "…is missing, not its own top level…" plus git's "must be run in a work tree" on stderr. The same layouts land when main is held by a linked worktree, or by none. This is outside the diff and is listed for completeness, because the brief asked about gitfile layouts.

**Recommendation:** None for this pass. If it matters later, take W for the `$common` holder from `git --git-dir=$common rev-parse --show-toplevel` / `core.worktree`, not from the list's path.

## Untested bypass candidates

1. **`commondir` redirection combined with a decoy `.git` file.** Admin dir D's `commondir` names another repository, and W's `.git` names D. By trace, `symbolic-ref` via `--git-dir=D` and git inside W read the same `commondir`, so both see the same branch. The count therefore agrees with git, and the case collapses into the header's "git directory outside worktrees/" residual (the decoy family). Not executed.
2. **An interrupted `git worktree add` (HEAD written, commondir not yet).** By source reading this refuses (Finding 2). Not executed.
3. **The `update-ref refs/heads/main` + `rebase --edit-todo` candidate from the prior pass.** This diff does not touch it, and it is still unexecuted.
4. **Races between the scan and the move.** These are the header's residual and were not probed.

Because of Finding 1 and candidates 1-2, the G4 skip and the holder count do not appear under Endorsement Claims as categorical.

## Endorsement Claims

- **Claim:** With `extensions.worktreeConfig=true`, a non-current admin dir's `config.worktree` that names `core.fsmonitor`, `core.pager` and an `include.path` (to `core.sshCommand`) runs no command during `--merge`, including the three new `git --git-dir=D symbolic-ref` calls.
  **Location:** `scripts/build-loop.sh:1081`
  **Evidence:** executed (p2 `wtconfig-exec`: no `ran-*` file, `GIT_TRACE` shows 3 symbolic-ref calls and 0 `run_command` lines; landed)
  **Verified:** that config set, under harden's GIT_CONFIG_COUNT overrides, on git 2.39.5
  **Not verified:** other config keys git reads at repository setup (e.g. an unknown `extensions.*`, which by trace makes git exit 128 and refuse), and later git versions
  **route: code-fact-check**
- **Claim:** 2028aa89's new assertion fails when the `-ef "$hd"` clause is deleted: the mutant merges into the rogue admin-dir copy.
  **Location:** `test/scripts/build-loop-merge.bats:155-157`
  **Evidence:** executed (m1.sh)
  **Verified:** that one mutant, test 6
  **Not verified:** a mutant that compares with `==` on unresolved paths instead of `-ef`
- **Claim:** Every HEAD shape the prior pass executed as a fail-open (CR/LF separator, symbolic alias), plus a per-worktree symref chain, now refuses with the gitdir file removed. The same is true of every dot-named mode-000 rebase dir.
  **Location:** `scripts/build-loop.sh:1074-1083`
  **Evidence:** executed (p1 re-run table)
  **Verified:** the ten variants in the table, on git 2.39.5
  **Not verified:** HEAD shapes git accepts that I did not enumerate. Because the code asks git itself, any such shape would need git to disagree with itself between `--git-dir=D` and running inside W.
  **route: code-fact-check**
- **Claim:** The honest layouts in the table land or refuse exactly as on 20de9671, except bare repositories, which now land.
  **Evidence:** executed (h1.sh)
  **Verified:** those 16 layouts
  **Not verified:** worktrees created by older git versions that did write dot-named admin dirs

## Primitive sweep

Primitive: process exec of git with a path argument taken from planted state (S5/S6)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:1058` `git worktree list --porcelain -z` | S5 | none needed (git's own parse) | cleared: NUL-ended, `bare` matched as a whole field |
| `:1070` `git rev-parse --git-common-dir` | S5 | — | cleared |
| `:1081` `git --git-dir="$d" symbolic-ref -q HEAD` (new) | S5 (glob over `$common/worktrees`, always absolute) | searchability and `-f`/`! -L` checks; harden | Finding 2 (stderr, fail-closed); exec cleared by p2 `wtconfig-exec` |
| `:1096` `(cd "$w" && state_gate)` and `:1097-1121` `git -C "$w" …` | S4 (path from the list) | state_gate before any work-tree read | unchanged by this diff; Finding 3 (pre-existing) |
| `:1132` `git -C "$w" merge --ff-only` | S4 | the checks above, plus `-ef "$hd"` (now tested) | unchanged; cleared for this diff |

## Summary Table

| # | Finding | Severity | Regression | Class | Boundary | Location | Confidence | Executed |
|---|---------|----------|-----------|-------|----------|----------|------------|----------|
| 1 | Planted `core.bare=true` + removed index: G4 skips the main worktree's HEAD and lands under it | Low (Medium by prior-pass convention) | yes | planted-state | B5 | `build-loop.sh:1062,1071,1083` | High | yes |
| 2 | An admin dir git cannot open refuses every landing; git's `fatal:` goes to stderr; the header doesn't list it | Informational | yes (fail-closed) | other | B4 | `build-loop.sh:1081-1082` | High | yes |
| 3 | Separate-git-dir / submodule main worktree on main refuses (git 2.39 list path) | Informational | no | other (honest false refusal) | B2 | `build-loop.sh:1063,1096` | High | yes |

## Overall Assessment

ce38eafb does what G1-G4 asked:
- **G1:** dot-named admin dirs are searched.
- **G2/G3:** asking git to resolve HEAD removes the parse-mismatch class outright. Every prior shape refuses, and so does a per-worktree symref chain.
- **G4:** honest bare repositories land again.
- **G6:** 2028aa89's test kills the `-ef` mutant.
- No honest layout that 20de9671 landed is now refused.

The one fail-open the diff introduces is Finding 1. It needs a writer to plant `core.bare=true` and delete the main worktree's index, and git itself agrees with the landing at that moment. It is in the planted-state class Q-138 routes to Q-103. Finding 2 is a fail-closed side effect with a small fix: redirect stderr and add a header line. There are no Critical/High/Medium findings within the code paths probed. The endorsement claims marked `route: code-fact-check` are pending execution verification by that skill.
