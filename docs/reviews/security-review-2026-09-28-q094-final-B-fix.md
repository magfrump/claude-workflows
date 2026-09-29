Commit: 7c97a6b

# Security Review — q094b-exit-scan-worktree-removal, final-pass fix (a7e9b7a..7c97a6b)

**Scope:** `git diff a7e9b7a..7c97a6b` — `devcontainer-config/cc-exit-scan.sh` (read whole, 1057 lines), `test/cc-isolated-functions.bats` (changed tests + helpers), guide/plan wording. Context-only: `dfe4c0d..a7e9b7a` (11 commits, already reviewed).
**Date:** 2026-09-28
**Based on:** no code-fact-check report; experiments on `git archive 7c97a6b` and `git archive a7e9b7a` (pre-fix control) in `scratchpad/re-sec-413126903/`, git 2.39.5.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and
> documentation have not been independently verified. For full verification, run the
> `code-fact-check` skill first or use the code-review orchestrator.

No HALT pattern applies.

## Trust Boundary Map

```
B1: [container-written .git file "gitdir: /workspace/<rel>"] → [_snap_container_target: -f/!-L, first line, prefix match, [ -d ws/<rel> ], pwd -P] → [_snap_host_config: your config's includeIf/hooksPath walked in that worktree]  (new)
B2: [container-shaped tree at a removed worktree's old path]  → [scan_std_worktrees removal: _snap_unq, ! -e/-L <path>/.git, ! looks_like_gitdir <dir>] → [note + exit 0]  (moved: .git check added)
B3: [launch snapshot + exit snapshot records (container-influenced)] → [scan_std_worktrees record matching] → [note vs WARNING]
B4: [the user's own global config (host-only)] → [_snap_host_config, now also for mapped container-form dirs] → [hooksdir/include records]
```

| Label | Source | Mutability | Trust (per sink) |
|---|---|---|---|
| S1 | `.git` file content in the working tree | request-time (container writes it) | UNTRUSTED for path construction / cd / read sinks |
| S2 | Directory tree at the old worktree path and its parents | request-time | UNTRUSTED for the "no repository here" decision |
| S3 | `%q` path strings in snapshot records (derived from S1/S2 paths) | request-time | UNTRUSTED for decode (`_snap_unq`) |
| S4 | `GIT_EXIT_SCAN_CONTAINER_WS` | code-constant (`/workspace`, test-overridable) | trusted |
| S5 | Your global/system git config | deploy-time, host-only | trusted as config; its relative paths resolve into S2-controlled trees |

The container controls S1–S3 fully. The new code does two things. It turns S1 into a directory that decides which of your includeIf conditions apply (B1), and it adds one more S2 check before the "removed" verdict (B2). Both operate at launch and at exit with identical code, so the launch/exit comparison stays symmetric.

## Findings

#### 1. The container-form mapping models `git worktree repair` only in the note path. A container-form `.git` present at launch still hides a plant that runs after repair.

**Severity:** Medium (floor rule; pre-existing, not a regression)
**Location:** `devcontainer-config/cc-exit-scan.sh:555-567` (`_snap_container_target`), `:719-721`
**Boundary:** B1, B4
**Move:** 11 (bypass enumeration), 5 (invert: what the mapping does not cover)
**Confidence:** High on the mechanism (executed). Medium on reachability: it needs a container-form `.git` in the launch baseline, which only a prior session that already warned (`+ dotgit`/`~ dotgit`) can leave.

The mapping takes `<ws>/<rel>` literally and only runs your config through it. That differs from what repair does and from what the host-form path walks:

- **(a) Mapping by `<rel>` vs repair's inference by id.** git 2.39's `worktree repair <path>` infers the backlink from the **basename** of the named dir (`<current repo common>/worktrees/<id>`), not from `<rel>`. Take a `.git` of `gitdir: /workspace/gone/../.git/worktrees/agent-x`: `[ -d ws/gone/../… ]` is false, so the scan maps nothing. Experiment E6 set that as the baseline and planted `.githooks/pre-commit` under your relative `core.hooksPath`. The exit scan returned **status 0, silent**. `git worktree repair` then rewrote `.git` to `ws/.git/worktrees/agent-x`, and `git commit` ran the hook.
- **(b) Your config walked, not the mapped git dir.** The host-form path runs `_snap_dotgit` → `_snap_gitdir(g)`, which also walks the commondir. The container-form path runs only `_snap_host_config`. Experiment E1: a bare `ws/foo.git` (not named `.git`, so never found by the tree walk) has a linked worktree `ws/wtx` whose `.git` is in container form at launch. A hook planted in `foo.git/hooks` during the session gives **status 0, silent**. After `git -C foo.git worktree repair ws/wtx`, `git checkout` ran `hook-post-checkout`. The host-form control (E1c) warns (status 1). The pre-fix code (a7e9b7a) behaves the same, so this is not a regression.

It does not affect the note path. There the added `.git` must be exactly `gitdir: <ccommon>/worktrees/<n>`, so the mapping equals P, which the common dir's `worktrees/` walk covers. A container-form `.git` created in the session is a new `dotgit` record and warns. The gap is only in a baseline carried over from a warned session. That sits next to the guide's "Anything present at launch" bullet, but there the *plant* is from this session and only the *structure* is old, which the bullet does not describe.

**Recommendation:** For any `.git` file whose gitdir resolves to nothing on the host:
- Walk your config's relative `core.hooksPath`/`core.attributesFile` in its working tree regardless of the gitdir, treating every `includeIf gitdir:` condition as matching (the same conservative rule `_snap_cond` already uses for `onbranch:`).
- When a mapped or inferred dir is inside the checkout, `_snap_gitdir` it as `_snap_dotgit` does for host form.

Otherwise add a Known-routes bullet: "a `.git` file that names nothing on the host, present at launch: what `git worktree repair` would connect it to is not scanned." Not merge-blocking: the commit is a strict improvement on a7e9b7a.

#### 2. Removing a worktree now warns for users with a relative `core.hooksPath`, including the container-form removals agents normally do.

**Severity:** Informational (fails closed; attention cost, not exposure)
**Location:** `devcontainer-config/cc-exit-scan.sh:719-721` × `:873-879`, `:961`
**Boundary:** B3, B4
**Move:** 3 (what the new records do to the matcher)
**Confidence:** High (executed)

The launch snapshot now records `F hooksdir <wt>/.githooks missing` for a container-form worktree (from your config). When the worktree is removed, that record is gone. `scan_std_worktrees` puts it in `left` but only ever marks `P/hooks` as `used`, so line 961 declines. E2: a container-form removal with `git config --global core.hooksPath .githooks` warns on 7c97a6b (status 1) and gave the note on a7e9b7a (status 0). The commit's Notes line covers the **added** side ("see the warning on every new worktree"), which is correct and needed (E2b; the added side has to warn). It does not mention the removal side, where a vanished `missing` hooksdir under a vanished tree runs nothing.

**Recommendation:** Either accept a gone `hooksdir <old wt>/<rel> missing` record under a removal that passed the B2 checks, or say in the commit and guide that removals also warn for these users. Optional.

## Endorsement Claims

- **Claim:** Q2 guardrail: with the working tree left in place, a `.git` behind a symlinked parent, or an unlistable old tree, the removal is not accepted.
  **Location:** `cc-exit-scan.sh:913-918`
  **Evidence:** executed
  **Verified:** the commit's symlinked-parent test (warns; control gives the note). E4: old tree at modes 000/100/600 holding a repo → status 2 ("could not read"); mode 700 → status 1. Full `cc-isolated-functions.bats`: 173/173.
  **Not verified:** the ancestor-bare-repo route. E3: `.claude/worktrees` turned into a bare repo while the removed dir remains still gives the note, and `git rev-parse --git-dir` in the old dir resolves to the parent. That is the guide's existing "repository in a working-tree directory not named `.git`" route, not something this check claims to close.
- **Claim:** The new mapping evaluates your `includeIf gitdir:` against the mapped physical dir and the logical launch route, so a hook under an included relative hooksPath in a new container-form worktree warns.
  **Location:** `cc-exit-scan.sh:719-721`, `_snap_cond`
  **Evidence:** executed (E5: both the physical and the `lnk/` patterns → status 1; a7e9b7a → status 0 for both)
  **Verified:** those two pattern forms with an exact-form container `.git`.
  **Not verified:** `gitdir/i:` and bracket patterns through the mapped dir (the code path is shared with the host form).
  **route: code-fact-check**
- **Claim:** `_snap_container_target` adds no FIFO read or new launch refusal beyond what `_snap_dotgit_target` already risks on the same file.
  **Location:** `cc-exit-scan.sh:559-567`
  **Evidence:** read-static
  **Verified:** `-f && ! -L` gate before `_snap_first_line`, which also has the size cap; the same file was already read by `_snap_dotgit_target` one line earlier; `cd` failures yield empty (`|| true`). New refusals come only from `_snap_host_config`/`_snap_hooks` on the newly walked tree (e.g. an unlistable `.githooks`), which fails closed.
  **Not verified:** a concurrent writer swapping the file between the two reads (the container is not running during either snapshot in the documented flow).
- **Claim:** `_snap_unq` on stdout does not change which paths are accepted.
  **Location:** `cc-exit-scan.sh:807-817`, `:914`
  **Evidence:** read-static + executed (`_snap_unq` test; the `$'…'` removal case still warns)
  **Verified:** only the backslash form is decoded, and it cannot end in a newline, so `$(…)` trimming cannot alter it. The re-quote check runs inside the substitution, and its status reaches `|| return 1`.
  **Not verified:** non-C `LC_CTYPE` during the snapshot (launcher environment).

## Untested bypass candidates

- A container-form `.git` whose `<rel>` passes through a symlink **inside** the checkout to a dir other than P, with an includeIf pattern matching only the repaired path. Not built: it needs the Finding 1 precondition (a baseline `.git` not in exact form), and in the note path the exact-content match rules it out.
- Host checkout located **at** `/workspace`, or under a host `/workspace` that is itself a repo with a same-named `worktrees/<n>`. Reasoned only: `_snap_dotgit_target` resolves first and host git uses that dir, so the mapping is not reached.

## Primitive sweep

Primitive: path construction + `cd`/read from a container-written gitdir/back-pointer line

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:125-142` `scan_git_dirs` | S1 | `-f`, `-d`, size-capped read | cleared — unchanged; root `.git` only |
| `:540-553` `_snap_dotgit_target` | S1 | `-d`/`-f`, size-capped read | cleared — unchanged; mirrors host git |
| `:559-567` `_snap_container_target` (new) | S1, S4 | `-f && !-L`, prefix match, `-d` | Finding 1 (models repair only for the exact form) |
| `:603-609` `_snap_gitdir` commondir | S1 | `_snap_inside_ws` | cleared — unchanged |
| `:929-941` added back-pointer | S1 | regular file, ≤4097 B, hash re-check, `..`/`.` parts refused | cleared — unchanged |
| `:913-918` removal decode + `-e/-L/looks_like_gitdir` | S3, S2 | `_snap_unq` re-quote, `*/.git` | cleared (E4, symlink test); E3 route documented |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Container-form mapping ≠ repair outside the note path; the mapped git dir itself is not walked | Medium (pre-existing) | B1, B4 | `cc-exit-scan.sh:555-567, 719-721` | High mechanism / Medium reach |
| 2 | Removals now warn for users with a relative hooksPath | Informational | B3, B4 | `cc-exit-scan.sh:719-721, 961` | High |

## Overall Assessment

Both fixes do what the commit says, and each fails closed. The container-form walk closes the Medium hidden-hook case in the note path, including when includeIf is involved. The `.git` check closes the symlinked-parent removal, and unreadable old trees refuse the scan. `_snap_unq`'s stdout form is behavior-neutral. Launch and exit use identical code, so the only new difference is the intended warning, plus the unmentioned removal-side warning (Finding 2). Finding 1 was already present at a7e9b7a: the fix applies its "as repair would" model only to your config and only to the exact form, so a container-form `.git` in the baseline still lets a session's plant pass silently and run after repair. It needs a previously warned state, so it does not block this merge. It should become a follow-up (a conservative walk for any unresolvable `.git`) or a Known-routes bullet. Within the code paths read and executed: no new findings from this commit. Endorsements marked `route: code-fact-check` are pending execution verification.

## Goal-Alignment Note

The goal is to confirm the final-pass fix commit before the parent merges. The commit's two targeted security fixes are confirmed by experiment, and there are no regressions in exposure (173/173 tests; pre/post controls). The one Medium finding is pre-existing and outside the note path, so it is not introduced by this commit. It is a recommended follow-up or doc line, not a merge blocker. Finding 2 is a noise cost that works against Q-094's aim (fewer spurious warnings) for users with a relative `core.hooksPath`, and it is worth a line in the commit or guide. A caveat on the evidence: the full suite ran with `TMPDIR` in a canonical path (`/tmp/claude-1000/xt`, removed afterwards). With a `TMPDIR` containing `..`, three pre-existing tests fail on both a7e9b7a and 7c97a6b, which is a test-harness path assumption, not a scan defect.
