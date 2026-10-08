Commit: 63ea50e7

# Architecture Review: feat/build-loop-u2b1a2 (U2b1a2, `--check` itself), final confirming pass

**Scope:** `git diff feat/build-loop-u2b1a1...HEAD` (code: `scripts/build-loop.sh`; `test/scripts/build-loop-check.bats` read for context only). Enclosing context: `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `devcontainer-config/install.sh`, plan `docs/working/plan-build-loop-handoff.md` (D7, F8, step 5).
**Date:** 2026-10-08
**Based on:** the shared brief's Stage 1 summary (`code-fact-check-report-build-loop-u2b1a2-final-r{1,2,3}.md`); the iteration-2 architecture review (`architecture-review-review-2026-10-08-build-loop-u2b1a.md`, items 1-7) and their dispositions (rubric `code-review-rubric-2026-10-08-feat-build-loop-u2b1a.md`, override-log rows 491-502).

Scope check: in scope. The diff adds a public mode (`--check`, its output grammar and exit codes), a cross-cutting concern (process-wide git hardening for every mode), and a new internal module (a second, gate-owned git repository).

Trust-boundary cross-reference: the only `docs/reviews/security-review-*.md` files are the 2026-08/09 egress reviews, which cover another subsystem. No finding below falls on one of their labeled boundaries, so the cross-reference is a no-op.

Probes: git 2.39.5, in scratch directories `/tmp/archu2b1a2-*`, all removed. No process was left running.

## Dependency Map

- `build-loop.sh` sources `scripts/lib/dev-cycle-read.sh`, and so does `dev-cycle.sh`. The lib never calls back into either script, so the dependency direction is still correct.
- **Prologue (every mode):** the script runs `harden` (five config-count pairs), then exports six `GIT_*` variables at `:166`. In `--check` only, it runs `state_gate` (`:209`). Then it runs `resolve_main` and `main_by_name`.
- **The `check)` arm (`:499-510`):** it runs `read_settings`, `open_shared`, `mktemp` and the EXIT trap, then `gate_repo`, then `check_line` once per brief.
- **`check_line` call chain:** `status_line` (parsed by position), then the lib's `check_branch` (parsed by position), then `merge_result`.
- **Two git regimes:**
  - Everything except `merge_result` runs in the real repository, hardened only through the inherited environment.
  - `merge_result` runs in the gate repository: `cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git ...`. The gate repository is a git dir with only an object-format config, the real object store, and the repo-local variables unset.
- **Later consumers named by the plan:**
  - U2b1b: `diff-tree -r --no-renames --raw -z MAIN R`, then the per-path lines.
  - U2b2: contract items 2-4, the gate's checkout.
  - U3 `--merge`: `check_line`, then `commit-tree R -p MAIN -p TIP`, then a CAS on main, plus a hardened `merge --ff-only` when main is checked out.
  - U3b: `--state` reuses `state_gate`, and the D6 snippet.
- **A second state gate already exists:** `devcontainer-config/install.sh:208-209` (`GIT_EXEC_KEYS_RE`, `git_state_gate`). This corrects iteration-2 item 7, which said there was no install.sh.

## Findings

#### 1. The gate repository is drawn as merge_result's private setup, but U2b1b's diff-tree needs it too: in the real repository, a moved gitlink disappears from `diff-tree --raw`

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:439-467` (`gate_repo`, `merge_result`); plan `docs/working/plan-build-loop-handoff.md:123` (F8)
**Move:** 3 (module boundary), 8 (extension points)
**Confidence:** High (probed)
**Legibility-target:** for-author

The comment introduces `gate_repo` as "merge_result's own repository". Its calling convention has two parts: `cd "$GATE_TMP/work"` and the `GATE_ENV` prefix. Both are written out inline, only inside `merge_result`. The next unit's call needs the same isolation.

I probed the next unit's command, `git diff-tree -r --no-renames --raw MAIN R`, in a real repository whose two trees differ only in a gitlink:

| Variant | Real repository | Gate repository |
|---|---|---|
| Baseline | shows `:160000 160000 … M sub` | shows the line |
| Repo config `submodule.sm.ignore=all` | **prints nothing** | still shows the line |
| Uncommitted checkout `.gitmodules` with `ignore = all` | **prints nothing** | still shows the line |
| Plan F8's `-c diff.ignoreSubmodules=none` added | prints nothing | (not needed) |
| `--ignore-submodules=none` flag added | shows the line | (not needed) |

Three points follow from the table:
- `STATE_KEYS_RE` has no `submodule.` alternative, so the state gate does not catch the config variant.
- No config-key gate can catch the checkout `.gitmodules`.
- Plan F8's mechanism does not work.

Consequence: the F8 "gitlinks refuse" rule that U2b1b builds would never see the gitlink. The gate repository sees it by construction, because it has no config, no HEAD commit and an empty working directory. This is the same argument that justified building `gate_repo` for merge-tree.

**Evidence:**
```
# merge_result's own repository, set up once per run in GATE_TMP (the caller's
```
```
  out="$(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?
```
```
| F8 | Mode-only change, gitlink | covered (with F25) | Modes ∈ {100644, 100755, absent}: the exec bit is allowed (rev 4); gitlinks refuse; plumbing `diff-tree` with `diff.ignoreSubmodules=none` (T1
```
(F8 excerpt ends at 200 columns; the row continues.)

**Recommendation:**
- Turn the convention into one wrapper, `gate_git() { (cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@"); }`. Iteration-2 item 5 suggested this shape.
- Write the placement rule once, in `gate_repo`'s comment: calls that take only object ids run through `gate_git` (merge-tree, diff-tree, commit-tree); calls that read or move refs run in the real repository (check_branch, the CAS).
- Correct plan F8 to "diff-tree in the gate repository". If it stays in the real repository, use `--ignore-submodules=none` instead.
- This can land as U2b1b's first edit, but the comment and plan fix belong to this unit's merge entry.

#### 2. The state gate is switched on by a mode test in the shared prologue, apart from the rest of `--check`'s setup, and nothing tests its order

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:209-210`, against `:129` (the `--check` parse arm) and `:499-503` (the `check)` arm)
**Move:** 8 (extension points), 2
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

`--check`'s setup is now split across three places:
- the parse arm sets `MODE=check`;
- the prologue runs `state_gate` only when `MODE == check`, before `resolve_main`;
- the case arm builds `GATE_TMP` and `gate_repo`.

The plan says U3's `--merge` is "as `--check`, then commit-tree and CAS". The natural way to build it is a new parse arm plus a case arm that reuses `check_line`. That leaves line 209 untouched, so `--merge` would move main without a state gate. No test would notice: per the Stage 1 fact-check (r1, r2), the partial-clone test still passes with the gate moved after `resolve_main`. The order "state gate before the first object read" is therefore pinned only by where the line sits. This extension point fails open, on the one mode that writes.

**Evidence:**
```
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
```

**Recommendation:**
- Decide gating where the mode is defined. Set `GATED=1` in each deciding mode's parse arm (`--check` now, `--merge` and `--state` later), and have the prologue test `[[ -n "$GATED" ]]`.
- Pin the order in the existing shim test: no object-reading call (`show-ref`, `rev-parse --verify`, `cat-file`) may be logged before the state gate's last call.

#### 3. Harden grew from 4 to 11 settings, and the exports sit outside `harden()`; dev-cycle.sh still calls the same lib functions with none of them (item 1, carried)

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:158-166`; `scripts/dev-cycle.sh:127`
**Move:** 2, 7
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Since iteration 2, `harden` has added `core.commitGraph=false`, and the export line has added `GIT_CONFIG_GLOBAL=/dev/null` and `GIT_ALLOW_PROTOCOL=none`, for every mode including `--status` and `--settings`.

The name `harden` covers only the five pairs. The six exports follow it at `:166` as a separate statement. Row 495's planned move (one `git_harden` in the lib) therefore has to move two things, and a reader of `harden()` does not see half the policy.

The divergence item 1 described is wider now. The lib's `check_branch` and `check_brief` read the user's `~/.gitconfig`, a commit-graph and remote transports under `dev-cycle.sh`, but not under `build-loop.sh`. These are the global-config cases the security review probed (R4).

Row 495's deferral (trigger: U3b's D6 snippet) still holds. Each unit before U3b adds rows to the gap.

**Evidence:**
```
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1 GIT_OPTIONAL_LOCKS=0 GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null GIT_ALLOW_PROTOCOL=none
```
```
TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"; export GIT_LITERAL_PATHSPECS=1
```

**Recommendation:** Fold the `:166` exports into `harden()` now, at no behavioural cost, so that it is one function to move. Keep row 495. Consider moving its trigger earlier, to U2c's floor caller: that is the first time the lib's walk runs as gate code under two entry points.

#### 4. The gate's temporary directory has three owners in sequence

**Severity:** Minor
**Location:** `scripts/build-loop.sh:447-457` (`gate_repo`), `:502-503`
**Move:** 2, 7
**Confidence:** High
**Legibility-target:** for-author

Ownership is split three ways:
- The `check)` arm creates `GATE_TMP` and installs the EXIT trap.
- `gate_repo` assumes the directory exists and fills `GATE_ENV`.
- `merge_result` assumes both.

A second mode (U3's `--merge`) has to copy the same four steps in the same order. The bare `trap … EXIT` also overwrites any EXIT trap installed earlier; there is none today.

**Evidence:**
```
    GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
    gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
```

**Recommendation:** Let `gate_repo` (or a `gate_init`) own the `mktemp` and the trap, so a mode calls one function.

#### 5. merge_result judges git by exit code alone, while the lib's prior art treats any stderr as failure

**Severity:** Minor
**Location:** `scripts/build-loop.sh:461-467`; `scripts/lib/dev-cycle-read.sh:47-51` (contract item 2)
**Move:** 6 (substitutability of the 0/1/2 contract)
**Confidence:** High (the behavior is from fact-check r3, P2; this finding covers only the structure)
**Legibility-target:** for-author

The fact-check showed a missing tree object makes merge-tree exit 0 with an `error:` on stderr, which `2>/dev/null` discards. As a result `--check` prints `ok` with a wrong TREE.

The structural point is about who inherits that TREE. U2b1b diffs it, and U3 commits it, so the "2 when git failed" leg of the contract is the only guard downstream has. The lib already has a convention for this case ("where git ls-files prints nothing on stderr (any fails the walk)"). `merge_result` does not follow it.

**Evidence:**
```
  out="$(cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1" 2>/dev/null)" || rc=$?
  [[ "$rc" -le 1 && "${out%%$'\n'*}" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || return 2
```
(excerpt ends at :464; merge_result continues to :467.)

**Recommendation:** Capture stderr and return 2 when it is non-empty, matching the lib's rule. Put the same rule in `gate_git` (finding 1) so that diff-tree and commit-tree inherit it.

#### 6. Two state gates, and three key lists, with no subset pin for the new one

**Severity:** Minor
**Location:** `scripts/build-loop.sh:180`; `devcontainer-config/install.sh:208`; `test/cc-isolated-functions.bats:1966-1977`
**Move:** 7
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Three lists overlap:
- `install.sh`'s `GIT_EXEC_KEYS_RE`, read by `git_state_gate`;
- the exit scan's `GIT_EXIT_SCAN_KEYS_RE`;
- `STATE_KEYS_RE`, which is a superset of the first.

The repo already has prior art for this: a bats test that pins the exit scan's list as a superset of `install.sh`'s. `STATE_KEYS_RE` has no such pin. A key added to `install.sh` (the more often audited list) would not reach the build gate.

Iteration-2 item 7 ("No `install.sh` exists") was wrong. Plan D7's "after `install.sh`'s `git_state_gate`" is accurate as a lineage note.

**Evidence:**
```
GIT_EXEC_KEYS_RE='^(filter\.|core\.fsmonitor|include|hook\.)'
```
```
@test "exit scan keys include every alternative of install.sh's refusal list" {
```

**Recommendation:** Add the same subset test for `STATE_KEYS_RE`. That costs about 8 lines in `build-loop-check.bats`.

#### 7. The split seam: clean in code at gate_repo/merge_result, but not clean in the output contract

**Severity:** Informational
**Location:** `scripts/build-loop.sh:439-467`, `:487-494`, `:502-503`
**Move:** 3
**Confidence:** Medium (line counts estimated from the diff)
**Legibility-target:** for-orchestrator-synthesis

**The code seam is clean.** `gate_repo` and `merge_result` are leaves with one caller each, and they share no state with harden, the state gate or the brief/branch checks except `MAIN_SHA` and `GATE_*`. The upper half would be about 35 script lines plus about 40 test lines (T16, the union test, the submodule test, SHA-256) and a TREE field to drop from T17/T18's expected lines. The lower half would be about 245.

**The output contract is not clean.**
- Without `merge_result`, the lower unit's `ok BRIEF TIP` would claim nothing about mergeability, so a conflicting branch would print `ok`. Adding TREE in the upper unit would then change a public line format between units.
- The header's "Writes nothing but --check's merge objects" claim would flip back to "read-only".

If a split is needed, there are two options:
- Have the lower unit print no `ok` at all (each passing brief prints `refuse BRIEF: the merge is not computed in this unit`, exit 2). The grammar then only gains a line kind.
- Split at harden instead (harden plus its shim test, all modes), which is the more natural cross-cutting seam. Its shim test currently drives `--check`, so it would drive `--status`.

#### 8. How U2b2 and U3 build on this shape

**Severity:** Informational
**Location:** plan `:84` (D7), `:213` (`--merge`); `scripts/build-loop.sh:448-457`
**Move:** 8
**Confidence:** Medium (commit-tree identity probed; the rest is reasoned)
**Legibility-target:** for-orchestrator-synthesis

- **(a) commit-tree in the gate repository.** It cannot find an identity: the probe shows "Author identity unknown" with `GIT_CONFIG_GLOBAL=/dev/null` and no `user.*`. U3 must therefore pass `GIT_AUTHOR_*` and `GIT_COMMITTER_*` explicitly. That is the desired outcome, because it also keeps out the repo's `i18n.commitEncoding` and `user.*` (iteration-2 item 5d). `GATE_ENV` keeps `GIT_CONFIG_*`, so a caller's `git -c` still reaches it, as harden's comment intends.
- **(b) The CAS, and D7's hardened `merge --ff-only`.** Both stay in the real repository. The ff-only is a working-tree operation that reads the checkout's `.gitattributes` and `.gitmodules`, which the gate repository cannot cover. For that call, the only guards are U2b2's item-3 refusal and the state gate. Name it in `gate_repo`'s comment as the known exception.
- **(c) U3's consumption of `check_line`.** If U3 reads TIP and TREE from `check_line`'s printed `ok` line, it adds a third positional parse (row 496's trigger fires there as planned). Row 497's every-line-ok duty is still U2b1b's.
- **(d) U2b2's value rules.** `core.symlinks` and the like still have no place in a key-name regex. C8 stands unchanged.

## What Looks Good

- **Isolation by construction:** `gate_repo` removes config, modules/, info/, shallow, HEAD's tree and the checkout in one move, rather than adding regex keys one by one. Finding 1 shows that this pays off again for diff-tree.
- `gate_repo` takes the object format from the repository (SHA-256 is tested) and keeps the caller's `GIT_CONFIG_*`, so the trusted-caller rule in harden's comment holds in both regimes.
- `merge_result` keeps a three-way verdict that `check_line` maps without parsing git text. `check_line` passes it the re-verified SHA, never a branch name.
- The state gate reads no object (`--file --no-includes`, `--git-path`), and the fact-check verified that it runs ahead of `resolve_main`.
- Hardening is uniform across modes, with one shim test pinning every call. Mode-independent hardening is simpler to reason about than per-mode hardening.
- `--expect` accepts only a full id, so git never picks the commit.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | gate_repo is scoped to merge_result; U2b1b's diff-tree in the real repo hides a gitlink under `submodule.*.ignore` or a checkout `.gitmodules` (probed); plan F8's fix does not work | Coupling | `build-loop.sh:439-467`, plan `:123` | High |
| 2 | State gate switched on by `MODE == check` in the prologue, apart from `--check`'s setup; `--merge` would skip it; the order is untested | Coupling | `build-loop.sh:209` | Medium |
| 3 | Harden is 5 pairs in `harden()` plus 6 exports outside it; dev-cycle.sh's lib calls get none (item 1, row 495) | Coupling | `build-loop.sh:158-166`, `dev-cycle.sh:127` | High |
| 4 | GATE_TMP, its trap, and gate_repo set up across three owners in order | Minor | `build-loop.sh:447-457`, `:502-503` | High |
| 5 | merge_result trusts the exit code; the lib's convention is that any stderr fails | Minor | `build-loop.sh:461-467` | High |
| 6 | Two state gates and three key lists; no subset pin for `STATE_KEYS_RE` (item 7 corrected) | Minor | `build-loop.sh:180`, `install.sh:208` | High |
| 7 | Split seam: clean in code at gate_repo/merge_result, not in the `ok` line contract | Informational | `build-loop.sh:439-503` | Medium |
| 8 | U3: commit-tree needs explicit identity in the gate repo (good); the CAS and ff-only stay real-repo; C8 and rows 496-497 unchanged | Informational | plan `:84`, `:213` | Medium |

## Overall Assessment

The unit keeps the dependency direction right and puts the right boundary, a gate-owned repository, under the call that computes content. It is drawn one call too narrow, though. The most important concern is finding 1: in the real repository, U2b1b's `diff-tree` hides a moved gitlink, through a config key the state gate does not list or through a checkout file no gate can list, and the plan's stated mitigation does not work. The gate repository already shows the gitlink. Promoting `gate_repo` to a `gate_git` wrapper, with a written rule for which calls run inside it (ids in, refs out), makes U2b1b and U3 build on the boundary instead of copying it.

Finding 2 has the same shape at the mode level: the state gate is attached to a mode name in the prologue, so the one mode that moves main (U3's `--merge`) would not inherit it unless someone remembers. Everything else is fixable in place. The carried items (rows 495-497, C8) still have sound triggers.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 63ea50e7` line at the top.
- Answered: yes
- Out of scope: the exploitability of a hidden gitlink once U2b1b exists, and whether system config belongs inside the gate's threat model (security); merge_result's missing-object behavior (fact-check r3 owns it; finding 5 covers only the structure).
- Escalate: finding 1's plan F8 error, since U2b1b would build on a mitigation that does not work.
