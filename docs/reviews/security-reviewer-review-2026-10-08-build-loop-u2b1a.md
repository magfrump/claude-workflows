Commit: 9e5d92df

# Security Review — feat/build-loop-u2b1a (iteration 2, `build-loop.sh --check`)

**Scope:** `git diff main...HEAD` (scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats), plus the lib functions --check calls (resolve_main, check_brief, check_branch, open_shared)
**Date:** 2026-10-08
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2b1a-i2.md (the submodule lazy fetch, Claims 5/7/18, is not re-reported)

Probes: git 2.39.5, throwaway repos under `/tmp/secu2b1a-AsPX/` (scripts `p?.sh`, logs `p?.log`), the fact-check's `mk.sh` fixture sourced read-only, `GIT_CONFIG_GLOBAL` pointed at a probe file to stand in for a planted `~/.gitconfig` (the real home was not touched). No background processes were started.

## Trust Boundary Map

```
B1: [loop-writable .git state: config, config.worktree, shallow, info/*, refs/*] → [state_gate :182-200, once, at :206] → [every later git process of --check]
B2: [loop-writable uid files: ~/.gitconfig, ~/.config/git/config]           → [harden pairs :154-162 (4 keys)]     → [every git process of --check]
B3: [loop-writable refs: refs/remotes/origin/HEAD, refs/heads/<any>]         → [resolve_main lib:483-506]           → [MAIN / MAIN_SHA: "main's committed state"]
B4: [loop-writable object store: loose objects, packs, commit-graph, alternates] → [none: git reads without re-hashing] → [brief Status, settings, merge inputs]
B5: [branch tip ref]                                                          → [check_branch twice + --expect :463-467] → [merge_result by hash :449]
B6: [merge-tree's view of the repo (common dir, cwd, env)]                    → [merge_result :444-453 (empty cwd)]  → [TREE printed in "ok" line]
B7: [repo text, config key names]                                            → [scrub (lib:87)]                     → [stdout/stderr]
```

| Source | Mutability | Trust |
|---|---|---|
| S1: common `config`, `config.worktree` (both worktrees), `shallow`, `info/*` | runtime-mutable (loop shell) | UNTRUSTED for exec and merge-result sinks |
| S2: `~/.gitconfig` / XDG git config | runtime-mutable (same uid) | UNTRUSTED for exec and merge-result sinks; the harden comment treats "the caller's own environment" as trusted, but this file is not environment, it is a uid-writable file |
| S3: refs (`refs/remotes/origin/HEAD`, branch refs) | runtime-mutable | UNTRUSTED for "which commit is main" |
| S4: object store contents (objects/, packs, commit-graph, alternates) | runtime-mutable | UNTRUSTED for any content decision unless re-hashed |
| S5: brief path args, `--expect` SHA | request-time from orchestrator | trusted caller; validated by pathform / full-hex regex |
| S6: process environment (GIT_COMMON_DIR, GIT_CONFIG_*, PATH) | deploy-time (caller) | trusted by design (harden comment :151-153) |

Everything a loop can write (S1-S4) reaches --check. The diff's guard is the state gate (S1 only, at one moment) and four config pairs (S2 partly). S3 and S4 have no guard, and S2 is guarded for four keys only.

## Findings

#### F1. A planted `refs/remotes/origin/HEAD` makes a loop's own branch "the default branch"

**Severity:** High
**Location:** `scripts/lib/dev-cycle-read.sh:486-487` (resolve_main), consumed at `scripts/build-loop.sh:207-208`
**Boundary:** B3
**Move:** 1 (trust boundaries), 5 (invert the access model)
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
```
  origin_head="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  [[ -n "$origin_head" ]] && candidates+=("${origin_head#origin/}")
```
resolve_main takes origin/HEAD's target name first and looks it up as `refs/heads/<name>`. A loop can run `git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/evil` and create `refs/heads/evil` holding any brief state and settings it likes. Then MAIN=evil and MAIN_BY_NAME=1. Every "from main's committed state" read follows: the brief's Status, `docs/dev-cycle.md` policy, the merge base and the merge. Probe `pi.sh` (log `pi.log`): main says brief `done` and `policy review`. After the symref, `--check` printed `ok ... TIP TREE` with rc 0, and `--settings` printed `policy self-merge set`. The `ok` line does not name the branch or MAIN_SHA it merged into, so the orchestrator cannot see the swap. D13 watches main's ref, which did not move. This needs no remote: the repo in the probe had none. /workspace has one, and its origin/HEAD is a uid-writable file.
**Recommendation:** The gate should not choose main from a ref a loop can write. Take the default branch name, or better MAIN_SHA, from the orchestrator (its D13 record), or accept only `main`/`master` for --check. Also print the name and MAIN_SHA in each `ok` line so that a swap is visible.

#### F2. The user's global git config is outside both guards: it runs a command during --check and changes the merge result

**Severity:** High
**Location:** `scripts/build-loop.sh:151-162` (harden: "The caller's own environment is trusted"), `:181-192` (the state gate reads only `config`/`config.worktree`); exec sink `scripts/lib/dev-cycle-read.sh:448`; merge sink `scripts/build-loop.sh:449`
**Boundary:** B2
**Move:** 1, 11
**Confidence:** High (executed)
**Legibility-target:** for-author
**Evidence:**
```
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null; do
```
```
      && d="$(git log -1 --format=%cs "$sha" 2>/dev/null)" && [[ "$d" =~ ^$DIGIT{4}-$DIGIT{2}-$DIGIT{2}$ ]]; then echo "ok $a $sha $n $d"
```
A loop runs as the same uid, so it can write `~/.gitconfig`. The state gate refuses `log.showSignature`, `gpg.*`, `merge.*` and `diff.*` only in the repo's own files. (a) Probe `pa.sh`: a global `log.showSignature=true` plus `gpg.program=<marker>`, and a branch tip carrying a `gpgsig` header. check_branch's `git log -1 --format=%cs` ran the marker during `--check`, which still printed `ok`. Adding a `log.showSignature=false` config pair stopped it (same probe). (b) Probe `pb.sh`: a global `merge.directoryRenames=true` turned a `refuse ... conflicts` (main renamed `a/` to `b/`, the branch added `a/new`) into `ok` with `b/new` in TREE. The author's planned temporary git dir does not change this, because global config is still read there.
**Recommendation:** Run the gate's git under `GIT_CONFIG_GLOBAL=/dev/null` (and `GIT_CONFIG_NOSYSTEM=1`), so that only the caller's env pairs and the checked repo files apply, and add `log.showSignature=false` to harden's pairs. Then correct the harden comment: a uid-writable config file is not "the caller's own environment".

#### F3. The object store is loop-writable, so "main's committed state" can be rewritten without moving main

**Severity:** High
**Location:** every MAIN_SHA read: `scripts/build-loop.sh:223` (main_file), `scripts/lib/dev-cycle-read.sh:363` (brief_fields), `scripts/build-loop.sh:449` (merge-tree inputs)
**Boundary:** B4
**Move:** 2 (implicit sanitization assumption: "a hash names its content")
**Confidence:** High for the mechanism (executed); Medium on whether the plan already counts it as a residual (Q-103 does not name it)
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
```
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")" \
```
git does not re-hash loose or packed objects when it reads them. Probe `pe.sh`: main's brief says `Status: done`, and `--check` refuses. The probe rewrote the loose object for that blob's id with `Status: open` (unlink, then write a zlib stream, 10 lines of Python). `git rev-parse main:$B` gave the same id, and `--check` printed `ok` with rc 0. Only `git fsck` reported `hash-path mismatch`. The same write can set `docs/dev-cycle.md` to self-merge, or forge a D8 answer, and D13 sees nothing because main's ref is unchanged. A new pack, a `multi-pack-index` or an alternate store's pack can do the same without touching the original file (untested; see below). The plan's D6 already re-hashes the scripts it extracts for this reason, but the gate's own decision reads do not.
**Recommendation:** For the decision reads (brief, settings, constraints and later answers), hash the bytes actually read (`cat-file` piped to `hash-object --stdin`, and likewise each tree and commit on the path from MAIN_SHA) and refuse a mismatch. Verifying the bytes in hand avoids a check-then-read race. merge-tree's inputs cannot be verified that cheaply, so name object substitution as a residual family in Q-103 or the plan's "What the gate can and cannot do".

#### F4. A planted `.git/shallow` changes the merge result cleanly; the state gate does not refuse it

**Severity:** Medium
**Location:** `scripts/build-loop.sh:193-196` (files checked: info/attributes, info/grafts only), `:449`
**Boundary:** B1, B6
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** for-author
**Evidence:**
```
  for f in info/attributes info/grafts; do
```
`shallow` works like grafts: each commit it lists is read as having no parents. Probe `pd.sh`: main had A, then B (f=b), then M, which reverted f to a. The branch merged a commit Q based on B. The true merge keeps f=a, and `--check` printed `ok ... ac4a4cce...`. After `echo $Q > .git/shallow`, the merge base fell back to A, so main's revert was undone silently: `ok ... d913e62e...` with f=b, rc 0. The planned temporary git dir closes this (same probe, `f=a`), unless GIT_COMMON_DIR is inherited (F8).
**Recommendation:** Add `shallow` to the state gate's file list now. The temporary git dir closes it for merge-tree, but `rev-list --count` and the marker reads still use the real dir.

#### F5. A forged commit-graph changes the merge result, and the planned temporary git dir still reads it

**Severity:** Medium
**Location:** `scripts/build-loop.sh:154-160` (no `core.commitGraph` pair), `:449`
**Boundary:** B4, B6
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** for-author
**Evidence:**
```
  for kv in core.useReplaceRefs=false core.hooksPath=/dev/null core.fsmonitor=false core.attributesFile=/dev/null; do
```
git 2.39 takes parents and root trees from `objects/info/commit-graph` without checking its checksum. Probe `pf.sh` used the same history as F4. It wrote the graph, then patched Q's parent entries to "none" (Python, about 15 lines). `--check` printed `ok` with f=b. Under the planned fix (`GIT_DIR`=a fresh git dir, `GIT_OBJECT_DIRECTORY`=the real objects), merge-tree still gave f=b, because the graph lives under `objects/info/`. With `-c core.commitGraph=false` it gave f=a. git's own maintenance writes this file, so the gate cannot refuse its presence; it has to switch it off.
**Recommendation:** Add `core.commitGraph=false` to harden's pairs (they reach merge-tree and every other call), and keep it under the temporary git dir.

#### F6. Run from a linked worktree, the gate never reads the main worktree's `config.worktree`, which merge-tree does read

**Severity:** Medium
**Location:** `scripts/build-loop.sh:184-186` (`--git-path config.worktree` is the current worktree's), `:449` (`--git-dir="$common"` reads `$common/config.worktree`)
**Boundary:** B1, B6
**Move:** 11
**Confidence:** High (executed)
**Legibility-target:** for-author
**Evidence:**
```
  for f in config config.worktree; do
    f="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { echo "refuse state $f: its path could not be read"; return 1; }
```
In the `pb` repo, the probe set `extensions.worktreeConfig=true` (not a refused key) and `merge.directoryRenames=true` in `.git/config.worktree`. From the main worktree, `--check` printed `refuse state merge.directoryrenames: set in config.worktree`. From a linked worktree, it printed `ok` with the changed tree. The orchestrator's checkout is not fixed yet (row 387). The planned temporary git dir closes this for merge-tree.
**Recommendation:** Covered by the planned fix. Until it lands, also read `$common/config.worktree`, or refuse `extensions.worktreeconfig`.

#### F7. The state gate checks once at start-up; state planted after it applies to every later git process

**Severity:** Medium
**Location:** `scripts/build-loop.sh:206` (single call), then the git calls in check_line `:456-474` via the lib (check_brief `:422-423`, check_branch `:444-448`)
**Boundary:** B1
**Move:** 4 (TOCTOU)
**Confidence:** High for the mechanism (read-static: each git call is a new process that rereads config); no race was run
**Legibility-target:** for-author
**Evidence:**
```
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
```
A loop can watch for the gate in `/proc`, since it has the same uid. After the gate passes, it can write `log.showSignature` plus `gpg.program`, which check_branch's `git log` runs (F2's mechanism). Or it can write `extensions.partialClone` plus `remote.x.uploadpack` and delete one of its own commit objects, so that `rev-list --count` in check_line's re-read fetches it lazily and runs the command. The window covers every brief's status_line and check_line. The probes showed race-free switches that close these vectors without a gate:
- `GIT_ALLOW_PROTOCOL=none` in the environment stopped the lazy fetch for the superproject over file and ssh URLs, even with a planted `protocol.file.allow=always` (`ph.log`). It also stopped the submodule case P1 (`pg.log`: `no fetch`).
- `-c protocol.allow=never` did not stop it, because a planted `protocol.file.allow` outranks it (`pg.log`: `fetched`).
**Recommendation:** Prefer environment and config-pair switches, which a loop cannot change mid-run, over the point-in-time refusal. Export `GIT_ALLOW_PROTOCOL=none` with the hardening, and add `log.showSignature=false` and `core.commitGraph=false` to the pairs. Keep state_gate as a tripwire, and keep the temporary git dir for merge-tree.

#### F8. An inherited GIT_COMMON_DIR (or other repo-local env var) silently undoes the planned temporary git dir

**Severity:** Low
**Location:** the planned change to `scripts/build-loop.sh:444-453` (not yet written)
**Boundary:** B6 (S6, trusted by design)
**Move:** 3
**Confidence:** High (executed against a sketch of the plan)
**Legibility-target:** for-author
**Evidence:** sketch from `pd` repo: `[] f=a` / `[GIT_COMMON_DIR=.../.git] f=b`
With `GIT_DIR`=a fresh git dir and `GIT_OBJECT_DIRECTORY`=the real objects, merge-tree ignored the planted shallow file. With `GIT_COMMON_DIR` also exported, as it would be when the gate runs from a git hook, the real common dir's `shallow` (and config) came back. Under the harden comment the environment is the caller's, so this is Low. The fix still costs one line.
**Recommendation:** For the merge-tree child, `unset $(git rev-parse --local-env-vars)` before setting GIT_DIR and GIT_OBJECT_DIRECTORY. The test fixture already does this (`test/lib/build-loop-fixtures.bash:15`).

#### F9. The comment "git 2.39 has no switch for it" is wrong: GIT_ALLOW_PROTOCOL is that switch

**Severity:** Informational
**Location:** `scripts/build-loop.sh:174-176`
**Boundary:** B1
**Move:** 11
**Confidence:** High (executed: `ph.log`, `pg.log`)
**Legibility-target:** for-author
**Evidence:**
```
# transport (remote.*.uploadpack, core.sshCommand and the like), and git 2.39
# has no switch for it (GIT_NO_LAZY_FETCH is 2.44). With no promisor remote no
```
2.39 does not stop the lazy fetch from being attempted. GIT_ALLOW_PROTOCOL stops it from reaching any transport (see F7). This is the comment that F7's recommendation would change.
**Recommendation:** Reword the comment when F7 lands.

#### F10. state_gate prints an empty name when `--git-path` fails

**Severity:** Informational
**Location:** `scripts/build-loop.sh:185`
**Boundary:** B7
**Move:** 3
**Confidence:** High (executed: with `core.worktree` set elsewhere, `--check` printed `refuse state : its path could not be read`)
**Legibility-target:** for-author
**Evidence:**
```
    f="$(git rev-parse --path-format=absolute --git-path "$f" 2>/dev/null)" || { echo "refuse state $f: its path could not be read"; return 1; }
```
The failed command substitution assigns an empty string to `f` before the echo runs. The gate still fails closed (rc 2), but the line does not say which file it meant. `:194` avoids this by assigning to `line`.
**Recommendation:** Assign to another variable, as `:194` does.

## Untested bypass candidates

- A forged object supplied by a new pack, a `multi-pack-index` or `.idx` remap, or a pack in an `objects/info/alternates` store (F3's class; not run, since the loose-object case already shows the property fails). The planned temporary git dir still reads alternates and packs through GIT_OBJECT_DIRECTORY.
- The XDG `~/.config/git/attributes`: I expect the `core.attributesFile=/dev/null` pair to supersede it (git uses XDG only when the key is unset). Not run.
- A remote-helper URL (`foo::`) with a `git-remote-foo` in a uid-writable PATH directory, under `GIT_ALLOW_PROTOCOL=none`: I expect it to be blocked, since helpers are checked by name. Not run.
- An actual race against state_gate (F7) was not run. The mechanism is per-process config rereading.

## Endorsement Claims

- **Claim:** The state gate runs before any git call that reads an object: `:206` precedes `resolve_main` at `:207`.
  **Location:** `scripts/build-loop.sh:205-207`
  **Evidence:** read-static
  **Verified:** the order of the three lines, and that state_gate's own calls are `rev-parse --git-path`, `config --file --no-includes` and `for-each-ref`.
  **Not verified:** whether `for-each-ref refs/replace/` reads an object when a replace ref points at a missing object under a planted promisor (the ref is printed by name, `%(refname)` only).
  **route: code-fact-check**
- **Claim:** The merge is computed from the tip's hash, which is read twice and compared (and against `--expect`), never from the branch name. A tip that moves after the re-read does not change what merge-tree merges.
  **Location:** `scripts/build-loop.sh:463-468`
  **Evidence:** read-static
  **Verified:** check_line passes `$sha` (from status_line, re-compared at :465) to merge_result, which passes it to merge-tree as a positional argument.
  **Not verified:** MAIN_SHA's own provenance (F1) and object integrity (F3).
  **route: code-fact-check**
- **Claim:** A `.gitattributes` staged only in the main worktree's index, or untracked in the checkout, did not change merge-tree's result (`* merge=union` stayed a conflict).
  **Location:** `scripts/build-loop.sh:444-453`
  **Evidence:** executed (`pc.log` and a follow-up probe in the same repo)
  **Verified:** both placements, with a one-line conflict; rc 2 refuse each time.
  **Not verified:** an index `.gitattributes` under a submodule path, or with `core.worktree` pointing at a directory holding one (that probe failed earlier, at rev-parse, so the merge was not reached).
  **route: code-fact-check**
- **Claim:** The printed output passes through scrub. Branch names are limited to NAMECHARS before they are echoed, and the brief path is pathform-checked before any `refuse` line names it.
  **Location:** `scripts/build-loop.sh:461-473`, `scripts/lib/dev-cycle-read.sh:438-441`
  **Evidence:** read-static
  **Verified:** status_line returns non-ok for a path or name that fails those checks before check_line echoes `$a` or `$br`.
  **Not verified:** config key names in `refuse state` lines carry subsection text (any byte but newline and NUL); scrub's C0 drop was not re-run on such a key.

## Primitive sweep

Primitive: git processes that can spawn a configured command (transport, gpg, fsmonitor, hooks, drivers) or read loop-writable merge inputs

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:449` merge-tree | S1, S2, S4, S6 | empty cwd; harden pairs; state gate (once) | F2(b), F4, F5, F6, F8; submodule fetch per fact-check i2 |
| `lib:448` `git log -1 --format=%cs` | S2, S1 (post-gate) | harden pairs | F2(a), F7 |
| `lib:422-423` `git log -G --no-textconv` / `git log -1` | S1, S2 | `--no-textconv`; pairs | F7 (log.showSignature planted after the gate, or set globally: same mechanism as F2(a)); signatures on main's commits need main's history to hold one |
| `lib:447` `rev-list --count` | S1, S4 | pairs | F7 (lazy fetch after the gate); F5 (commit-graph also feeds the count) |
| `build-loop.sh:376,382,385` marker_kind cat-file / rev-list / rev-parse | S4 | pairs | F7 (lazy fetch); F3 (content) |
| `build-loop.sh:223`, `lib:363`, `lib:467` cat-file / git grep on MAIN_SHA | S3, S4 | main_entry | F1, F3 |
| `lib:312` ls-tree | S3, S4 | — | F1, F3 |
| `lib:486-501` symbolic-ref / show-ref / rev-parse | S3 | name list | F1 |
| `build-loop.sh:185,187,194,197` rev-parse --git-path / config --file / for-each-ref | S1 | `--no-includes` | cleared: no object read, no command key consulted; F10 wording |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Planted origin/HEAD symref makes a loop branch "main": brief state, policy and merge spoofed | High | B3 | `lib:486-487`; `build-loop.sh:207-208` | High |
| F2 | Global ~/.gitconfig unguarded: gpg.program runs (log.showSignature); merge.directoryRenames changes TREE | High | B2 | `build-loop.sh:151-162,181`; `lib:448` | High |
| F3 | Loose-object rewrite spoofs main's brief/settings without moving main | High | B4 | `build-loop.sh:223`; `lib:363`; `build-loop.sh:449` | High |
| F4 | Planted .git/shallow changes the merge cleanly; not refused | Medium | B1, B6 | `build-loop.sh:193-196,449` | High |
| F5 | Forged commit-graph changes the merge; survives the planned temporary git dir; fix `core.commitGraph=false` | Medium | B4, B6 | `build-loop.sh:154-160,449` | High |
| F6 | Main worktree's config.worktree unchecked from a linked worktree, read by merge-tree | Medium | B1, B6 | `build-loop.sh:184-186,449` | High |
| F7 | State gate is point-in-time; post-gate plants apply; GIT_ALLOW_PROTOCOL=none is a race-free lazy-fetch switch | Medium | B1 | `build-loop.sh:206` | High |
| F8 | Inherited GIT_COMMON_DIR undoes the planned temporary git dir | Low | B6 | planned `:444-453` | High |
| F9 | "2.39 has no switch" comment: GIT_ALLOW_PROTOCOL is one | Info | B1 | `build-loop.sh:174-176` | High |
| F10 | `refuse state :` prints an empty name when --git-path fails | Info | B7 | `build-loop.sh:185` | High |

## Overall Assessment

U2b1a's structure is right: decide by hash, re-read the tip, compute the merge rather than check it out, and refuse before any object read. But "decide from main's committed state" rests on three things a loop can write and the gate does not guard:

- which ref is main (F1);
- the user's global git config (F2);
- the object store itself (F3, F5).

The state gate also checks only once (F7). F1 and F2 can be fixed in place with a few lines: take main from the orchestrator or by fixed name and print it, and set `GIT_CONFIG_GLOBAL=/dev/null` plus a `log.showSignature=false` pair. F3 is architectural: re-hash what the decision reads, and name substitution of merge inputs as a residual. On the author's planned fix for the submodule lazy fetch: it works (no fetch, the merge conflicts; `pg.log`), and it also closes F4 and F6 for merge-tree. It does not close the commit-graph (F5), global config (F2b), alternates or forged packs (F3), or an inherited GIT_COMMON_DIR (F8). Pair it with `core.commitGraph=false`, `GIT_CONFIG_GLOBAL=/dev/null`, `unset $(git rev-parse --local-env-vars)` and `GIT_ALLOW_PROTOCOL=none`. The last of these closes the lazy-fetch family for every git call, not only merge-tree. The single most important item is F1: it needs one `git symbolic-ref` and flips the policy as well as the merge. The endorsement claims are pending execution verification; the review is not a categorical all-clear.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your task names, structured per your skill, with a `Commit: 9e5d92df` line at the top.
- Answered: yes
- Out of scope: U2b1b's per-path rules (whether they would catch F2b/F4's changed paths); the D6 snippet; the U2b2 merge/CAS step that would act on F1's wrong MAIN.
- Escalate: F1 (origin/HEAD redirects main for --check and --settings), F2 (global config runs a command during --check), F3 (object substitution: a plan-level residual not named in Q-103).
