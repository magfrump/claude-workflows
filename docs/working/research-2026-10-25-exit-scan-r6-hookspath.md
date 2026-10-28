# Research and plan: exit scan, Q-173's sort and R6 (relative core.hooksPath in a linked worktree)

Brief: `docs/working/briefs/2026-10-25-exit-scan-r6-hookspath.md` (at d40e4bae)
Branch: `fix/exit-scan-r6-hookspath` · Date: 2026-10-25 · Workflow: RPI (no plan gate), then pr-prep's review-fix loop
Evidence: Q-168's rubric and p3 reviews on `fix/q096b-exit-scan-remote-names` at 75d08a94
(`docs/reviews/code-review-rubric-2026-10-15-q168-exit-scan-remote-names.md`,
`q168-exit-scan-remote-names-p3-security-review-2026-10-15.md`,
`q168-exit-scan-remote-names-p3-tech-debt-triage-review-2026-10-15.md`). Line numbers in
those reviews are for the Q-168 branch (1,364 lines); main's scan is the Q-096 tip (1,182).

## 1. The sort (Q-172 [2]'s boundary)

The rule: a route is in scope only if it needs no state planted before launch; state a
session can write inside the checkout during the session is in scope. Read with S5 and
S10: "planted" means a value no ordinary workflow produces, left for the scan to miss.
Ordinary setup that a user makes in normal work (husky's relative `core.hooksPath`, agent
worktrees under `.claude/worktrees/`, a sibling-path remote) is the baseline every session
starts from, not a plant; Q-173's own note places R6 inside on that reading. A route is in
when its only malicious write happens in the session inside the checkout, out when it also
needs an unusual value present at launch (which the guide's "Anything present at launch"
route already covers in general).

| Finding | In/out | Why |
|---|---|---|
| R6 | **in, built here** | Launch state is ordinary (relative repo `core.hooksPath`, a linked worktree in the checkout); the session writes only `<worktree>/<rel>/<hook>`. |
| R3 | in; hooksPath half closed here, remote half a follow-up | Launch state is an embedded repo made with `--separate-git-dir` plus a relative remote or `core.hooksPath` in it: rare but ordinary setup, no attacker-shaped value; the session writes only the plant (a bare repo or a hook under the working tree). The per-entry walk resolves the hooksPath half (old rc=0, new rc=1). |
| A14 | in, follow-up | Launch state is a relative local remote (`../upstream.git`), name or legacy URL in the checkout's config plus a linked worktree: ordinary setup; in a worktree inside the checkout the path lands inside the checkout, where the session plants a bare repo. |
| A16 | in, follow-up | Launch state is a relative `core.hooksPath` (husky) in a non-bare repo that is pushed to (`git push .`, a push into the checkout); the session writes `<git dir>/<rel>/pre-receive`, which no walk covers. |
| R4 | out | Needs a local path holding `@[` (or starting `[`) in a URL, name, legacy file or insteadOf result present at launch; adding one in the session is a C record. No ordinary workflow writes such a path. |
| R5 | out, not reachable on main | Needs your own config to define a remote only inside a `gitdir:` include written on a symlinked launch path, name it in `pushDefault`/`branch.*`, and an embedded `gitdir:`-file repo under it: a launch-time config shape. The counting that makes it a route exists only on the held Q-168 branch; on main your own `pushDefault` names are never walked at all (pass-1 fact-check, executed), which the guide's existing "path-valued `pushRemote`/`pushDefault` in your own config" bullet already lists. Q-168's guide must add it when that branch lands. |
| A15 | out, not reachable on main | Needs a `gitdir:` pattern with a `**` not bounded by `/` in your own config at launch; like R5 it hides a name only through Q-168's counting, so on main it is covered by the same existing bullet. |
| T1 | out | Its end-to-end case needs a container-form `.git` ending in CR present at launch (an earlier session's leftover), the guide's existing container-form route; an in-session `.git` not in git's exact form is already a finding. |
| T3 | out, not a route | The `_snap_config` dedup key omission only over-walks (fails toward more findings), so there is nothing to list as a route; it stays tech debt with T1's unit. Like R5/A15 it concerns the held Q-168 branch (`_snap_drid` does not exist on main). |

Out-of-scope routes R4 and T1 are now in the guide's "Known routes it does not see" (T1
as a qualifier on the existing container-form bullet); R5 and A15 are not routes on main
(see their rows) and are covered there by the existing `pushDefault` bullet. The in-scope
follow-ups A14, R3's remote half and A16 are listed too, as "not closed yet", so the guide
does not imply they are closed. The section's intro states the boundary and says to push
with `cc-push`. R6 was never on that list on main
(Q-168's A18 notes none of the split routes was), so nothing leaves it; instead the
coverage paragraph now says a relative repo `core.hooksPath` is walked in every working
tree.

### Follow-ups (not built here: one unit per group, log row 62)

- **Group (1) remainder:** A14 (relative remotes, names, legacy URLs per linked worktree),
  R3's remote half (`_snap_worktree_of` returns the separate git dir), A16 (receive hooks
  under a relative hooksPath run from the git dir). R3's `core.hooksPath` half is already
  resolved by this change's per-entry walk (probe below); its unit should add the test.
- T1 + T3 (one reader for `gitdir:`/`commondir`, the dedup key), as the tech-debt triage
  recommends. Note that the scan's own `.git`/`commondir` readers on main strip no CR
  (`cc-gitdir.sh`'s `gitdir_common` does, and this change uses it); that family (Q-168
  p1-3) is fixed on the held Q-168 branch.
- Groups (2) and (3) are out of scope by the sort: documented, not built.

## 2. R6 reproduction

Reproduction: `LC_ALL= bats -f R6 test/cc-isolated-functions.bats`

Mechanism (main, d40e4bae): `_snap_config` reads the checkout's common `config` once, with
`base = _snap_worktree_of(config) = $_snap_ws`, so `core.hooksPath=.husky/_` is walked at
`<ws>/.husky/_` only. The working-tree `.git` loop in `git_exec_snapshot` re-applies only
*your* config per entry (`_snap_host_config "$g" "$f" "${f%/*}"`). Git runs hooks in a
linked worktree from `<worktree>/.husky/_`.

Probe (scratch repo, git 2.39.5, `GIT_CONFIG_GLOBAL=/dev/null`; `core.hooksPath=.husky/_`,
`git worktree add .claude/worktrees/a` at launch; the session writes
`.claude/worktrees/a/.husky/_/pre-commit`; then `git commit` in the worktree):

```
old R6 scan rc=0
HOOK-RAN
new R6 scan rc=1
HOOK-RAN
```

(`HOOK-RAN` is the commit after the scan, run in both cases to show the route is live.)
The new bats case fails on the unfixed scan at its first `[ "$status" -eq 1 ]` and passes
with the fix; it ends with the real host commit running the hook.

R3's hooksPath half, same shape (`git init --separate-git-dir <ws>/sgd vendor/e`,
`core.hooksPath=.hk` in it): `old rc=0` (hook ran), `new rc=1`.

## 3. Design (divergent design, seeded with H1-H4, S1-S11 and the brief)

Motive (S5): High per Q-168's security p3-1; husky plus agent worktrees is this project's
own workflow, and the brief and Q-172 [2] put it inside the boundary. Status quo fails it.

| Option | What | Verdict |
|---|---|---|
| A. Per-entry hooksPath walk | For each `.git` entry the existing loop already visits, read the configs git uses for that git dir (common `config`, `config.worktree`, includes followed) and walk a relative `core.hooksPath` at `<entry dir>/<value>` | **Chosen.** ~45 lines, reuses the loop, `_snap_hooks` and `_snap_path` (S3); fails closed on an unreadable config (H2); no new mandatory dispatch (S2); one `git revert` undoes it (S8). |
| B. Re-read the whole repo config per entry | The security review's suggestion: `_snap_config` per (config, base), closing R6, A14 and R3 together | Builds A14/R3 against the brief's one-unit rule; multiplies URL/insteadOf queueing per worktree, so the pair and target caps can fail the launch for users with many agent worktrees; changes the C-record dedup. Better as group (1)'s follow-up design. |
| C. Refuse when a relative repo hooksPath and a linked worktree coexist | A W-style finding at every exit | Fails closed, but warns on every session for husky users with agent worktrees (S10, S1): a recurring false alarm that trains the user to ignore the warning. |
| D. Walk `<common>/worktrees/*/gitdir` targets | Use git's own worktree list instead of found `.git` entries | Misses embedded repos and separate git dirs; the back-pointer files are session-writable; a second discovery path (S3). |

A dominates: Path A, decide and continue.

## 4. Plan

1. Add `_snap_cfg_hooks <config>` (with `_snap_cfg_hooks_file`) and `_snap_entry_hooks
   <git dir> <working tree>` to `devcontainer-config/cc-exit-scan.sh`; call the latter
   from the working-tree `.git` loop with `${f%/*}`. `_snap_cfg_hooks` collects every
   `core.hooksPath` value of a config and every file it includes, once per snapshot per
   config (cached by real path); `_snap_entry_hooks` walks each value resolved in the
   entry's directory (absolute values too: cheap, and it covers configs `_snap_config`
   never reads). Every include is followed whatever its path form, with no depth cap
   (over-walk).
   - As built in cf15f4f9 the walk was per (config, worktree) with a depth cap of 10;
     the pass 1 and pass 2 reviews changed it (section 5).
2. Header and guide: a relative repo `core.hooksPath` is walked in every working tree.
3. Bats case in `test/cc-isolated-functions.bats`: direct, through a relative and an
   absolute `include.path`, and through a file first met deep in an untaken `includeIf`
   chain.
4. Guide known routes: R4, T1, and the open in-scope follow-ups; boundary sentence and cc-push.
5. Gate: full `test/cc-isolated-functions.bats`, `scripts/hermeticity-lint --root .`,
   shellcheck, the health check.

### Pre-mortem: bypass families for this change (enforcement file)

| # | Family | Covered? |
|---|---|---|
| 1 | Hooks base differs from the `.git` entry's dir (`core.worktree` set in the config) | Not covered for the checkout and linked worktrees: pass-2 security probed it end to end (per-worktree `core.worktree` via `config.worktree`, rc=0, hook ran). An embedded repo whose own config sets `core.worktree` is walked there by `_snap_config` (`_snap_worktree_of`; pass-3 fact-check, rc=1). It needs that value at launch, an unusual state: out of scope by the sort, now a guide known route. The main working tree already ignored `core.worktree` (not a regression). |
| 2 | Linked worktree added during the session | Covered: W records already refuse the note; the new walk adds the hook records. |
| 3 | hooksPath set through `include.path`/`includeIf` in repo config | Covered: every include is followed, whatever form its path takes, with no depth cap (conditions not evaluated: over-walk). Pass 1 found absolute and `~/` include paths skipped; pass 2 found a depth cap beside the seen set dropped the include of a file first met at depth 10 of an untaken `includeIf` chain (both rc=0, hook ran); both fixed and tested. |
| 4 | `config.worktree` (extensions.worktreeConfig) | Covered: walked for each private git dir (over-walk when the extension is off). |
| 5 | Unreadable or unparseable config on the new path | Covered: the snapshot fails (launch refused / exit 4), as `_snap_config` does (H2). |
| 6 | Hooks dir is a symlink, or unlistable | Covered by `_snap_hooks` (same as every other hooks walk). |
| 7 | `commondir` with a trailing CR (git strips it) | Covered for this walk: it reads the common dir through `gitdir_common` (git's reading; an unreadable or empty file fails the snapshot), not a fifth raw reader (override-log row 135). `_snap_gitdir`'s own reader is unchanged: T1's unit. |
| 8 | Receive hooks under a relative hooksPath (A16) | Not covered: follow-up. |
| 9 | Relative remotes per worktree (A14), separate git dir remotes (R3) | Not covered: follow-ups. |
| 10 | `.git` entries the find does not reach (other names, symlinked dirs) | Not covered: existing guide routes. |

## 5. Review-loop changes (passes 1-3)

- Pass 1 (fact-check): absolute/`~/` include paths skipped (fixed); comment and guide
  wording (fixed); the R5/A15 bullet described a Q-168-only mechanism (dropped, see the
  sort).
- Pass 2 security M1: the depth cap beside the seen set dropped a deep-first file (fixed:
  no cap).
- Pass 2 security M2: a `core.worktree` elsewhere is not followed (guide known route;
  pre-mortem row 1).
- Pass 2 security, informational: an empty or non-regular `commondir` in an embedded repo
  now refuses the launch (git dies there too, rc=128): availability, never a false clean.
- Pass 2 performance M1: the per-(config, worktree) walk re-read each include set once per
  `.git` entry (100 entries x 100 includes: 46.6 s vs 2.2 s). Fixed by caching each
  config's value set once per snapshot.
- Pass 2 performance L1: every value is walked in every worktree (git takes the last):
  100 entries x 100 values, 6.0 s vs 1.3 s at e1d7d912 (pass 2's figure; 9.5-11.3 s
  at 28dfcd3b and after, which walks absolute values per entry too and forks one
  `_snap_path` subshell per pair). Kept: an availability cost only; the values
  must be present at launch (one added in the session is a C-record finding anyway), and
  the guide's "A slow scan" route already covers planted volume.
- Pass 2 fact-check: an absolute `core.hooksPath` in a config only this walk reads (a
  container-form git dir) was not walked; the walk now walks absolute values too.

Cost after pass 2 (the pass-2 performance review's harness, git calls counted by a shim,
load ~0.7): 100 embedded repos 2.32 s -> 2.85 s (3 runs each; about 5 ms more per repo:
one `git config` for its config, one more for `config.worktree` when present, plus the
`gitdir_common` and `realpath` forks); 100 entries x 100 includes 2.06 s -> 2.71 s (46.6 s
before the cache); 100 entries x 100 lines naming one include 1.82 s -> 2.23 s. That
is about 23 ms -> 28 ms per entry (about +20%) measured on d40e4bae and HEAD here; the
guide's older figure (about 29 ms, measured on an earlier scan and host) becomes "about
30 ms", which matches the measured absolute cost, and now names linked worktrees.

Pass 3 (final confirming pass, k=3 fact-check, security, performance on 28dfcd3b): no
Must Fix, no Incorrect.
- Performance M1: the per-config duplicate-value check scanned the values already
  collected (quadratic: one config with 3,000 values took 23.7 s). Fixed with an
  associative-array lookup: 10.4 s, against 5.0 s on d40e4bae, the rest being the extra
  hooks dirs walked. Performance L2 (one subshell per entry-value pair) kept, as above.
- Security M1: a repo config that is a symlink to another repo's makes the second repo's
  relative include unread (the cache and `_snap_config`'s seen set key by real path; git
  resolves includes against the opened path). Predates this change (d40e4bae: rc=0) and
  needs launch-time state: out by the sort, now a guide known route.
- Security, informational: a directory `commondir` also fails the snapshot (git dies).
- Fact-check: wording fixes (the bats comment's depth, the `core.worktree` bullet's scope
  for embedded repos, the container-form bullet's absolute values, the R3 and T3 rows,
  pre-mortem rows 1 and 3, this section's figures).

Host check (the container cannot run it): after `install.sh`, in a husky repo with an
agent worktree, launch `cc-isolated`, have the session write
`.claude/worktrees/<x>/.husky/_/pre-commit`, exit, and see the warning name it.
