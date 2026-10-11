Commit: e3781a2c

# Security Review — feat/build-loop-u3d (U3d dispatch), iteration 2

**Scope:** `git diff main...HEAD -- scripts test` in /workspace/.claude/wt-build-loop-u3d (scripts/build-loop.sh +172/-10, test/scripts/build-loop-dispatch.bats new), plus the unchanged helpers it calls (state_gate, harden, gate_start, status_fields, check_brief, check_branch, scrub)
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3d-i1.md (its A1-A5 fixed in 23ba4511/e3781a2c); shared brief u3d-i2/shared.md
**Suite:** `bats test/scripts/build-loop-dispatch.bats` 4/4 ok at e3781a2c (run once, serially, with a private TMPDIR).

## Trust Boundary Map

```
B1: [caller argv: BRIEF, --dir, --steal]        → [arg parser, absform, check_brief pathform/isbrief] → [dispatch]
B2: [main's committed brief + constraints.md]  → [store_check, status_fields, check_branch, read_settings] → [update-ref / worktree add args, prompt text]
B3: [repo-local git state: config, worktree registry paths, lock reasons] → [state_gate + harden; wt_of (no validation)] → [worktree add/lock/unlock, printed ok/refuse lines, prompt text]
B4: [branch tip: loop-authored commits and tree] → [hardened git checkout in worktree add; steal's committer time] → [new worktree's files; steal decision]
B5 (new): [script stdout] → [orchestrator parses "ok BRIEF BRANCH DIR", passes prompt] → [loop's shell ("cd $DIR &&")]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | BRIEF argument | request-time (orchestrator) | Trusted after pathform + isbrief (slug chars only) for ref/arg/prompt sinks |
| S2 | `--dir` argument | request-time (orchestrator) | Trusted after absform for git-arg and prompt sinks; parent-component symlinks not checked |
| S3 | Brief fields on main (Branch:, Status:, Dispatched:, Policy:) | runtime-mutable (main commits) | Branch: trusted for ref/arg sinks only after check_branch (NAMECHARS, check-ref-format, no leading `-`); others reduced to fixed words/integers |
| S4 | docs/constraints.md at MAIN_SHA | runtime-mutable, cycle-owned and N-denied (F54) | User text: trusted as prompt content, untrusted for line structure (quoted `> ` per line, then scrub) |
| S5 | `git worktree list --porcelain -z`: paths (WT, MAINWT) and lock reasons | runtime-mutable by any same-uid git user or registry writer | UNTRUSTED for printed-line and shell-text sinks; MAINWT re-checked by absform, WT and WT_LOCK are not |
| S6 | Branch tip commit and tree | loop-authored | UNTRUSTED for checkout (exec) sinks — hardened; committer time untrusted for steal (a loop can only age its own lock) |
| S7 | Repo config / info files | runtime-mutable | UNTRUSTED for exec sinks — state_gate refuses filter/merge/diff/hook/include/fsmonitor/attributesfile/hookspath keys before dispatch; harden overrides the rest |
| S8 | Clock (`date -u`) | environment | trusted |

Everything a dispatch acts on is validated except what wt_of returns: S5's worktree path and lock reason flow into git arguments, the printed `ok`/`refuse` lines and the loop prompt unvalidated (Findings 2, 3). The lock and steal logic is the only guard against two agents in one worktree, and it is a check-then-act sequence without mutual exclusion (Finding 1).

## Findings

#### 1. Concurrent `--prompt` runs can both dispatch a loop into the same branch (steal and add paths are not atomic)

**Severity:** Medium
**Location:** `scripts/build-loop.sh:1299-1312` (dispatch's WT_N=1 steal/relock branch and the WT_N=0 `worktree add` branch)
**Boundary:** B3
**Move:** #4 (TOCTOU), #11
**Confidence:** High that the mechanism exists (executed); Medium on honest-path likelihood (needs two dispatchers within about a second)

Evidence (dispatch, excerpt; remainder of the function read):
```
    elif [[ -n "$WT_LOCK" ]] && ! steal; then x="$STEAL_WHY"
    elif ! { [[ -z "$WT_LOCK" ]] || git worktree unlock "$WT"; } || ! git worktree lock --reason "$reason" "$WT"; then x="its worktree $WT could not be locked (it may be left unlocked)"
    else DIR="$WT"; fi
  else
    ...
    elif ! git worktree add -q --lock --reason "$reason" "$DIR" "$br" > "$GATE_TMP/add" 2>&1; then
```
The steal is unlock-then-lock. Two stealers can interleave A-unlock, A-lock, B-unlock, B-lock, and each sees its own lock succeed. When no worktree holds the branch, two `--prompt` runs with different `--dir` values each pass wt_of's `WT_N=0` and each `worktree add` succeeds. git's "already checked out" check is not atomic across processes. Probe (`p2.sh` in my scratch directory, throwaway repo):
```
round 3: A=ok docs/working/briefs/2026-10-01-x.md f | B=ok docs/working/briefs/2026-10-01-x.md feat/x /tmp/claude-10
add round 1: A=ok docs/working/briefs/2026-10-01-x.md f | B=ok docs/working/briefs/2026-10-01-x.md feat/x .../d2-1
2        <- worktrees with branch refs/heads/feat/x afterwards
```
The steal race produced two `ok` lines in 1 of 6 rounds. The add race produced them in 3 of 4 rounds, leaving the branch checked out in two worktrees, both locked, with both prompts printed. Each orchestrator then launches a loop, which is the F44 failure ("Two agents in one worktree after re-dispatch"). The plan marks F44 covered and says for F37 that "atomic `worktree add -b` stop[s] a second loop on one brief". `--start` honours that through the create-only `update-ref` (executed: suite test 3, the i1 A5 shim). `--prompt` has no equivalent. In this repository, two orchestrator sessions in one repo is a real configuration: sessions share /workspace (memory: check-branch-before-merging-shared-checkout). An honest pair restarting together and both re-dispatching stale branches with `--steal` reaches the steal race without any hostile writer. The add race also needs two different `--dir` values: with the default directory, the second add fails on the existing directory.

**Recommendation:** Serialize `--start`/`--prompt` per repository. One option is `flock -n` on a file under `git rev-parse --git-common-dir`, held from wt_of to the printed `ok`. Another is to write a per-run nonce into the lock reason and re-read wt_of after locking or adding, refusing (and undoing what this run made) unless WT_N is 1 and the lock reason is this run's. Add a two-process test (T40) for each path.

#### 2. `--prompt` adopts an existing worktree's path unvalidated into the `ok` line and the loop's shell command

**Severity:** Low
**Location:** `scripts/build-loop.sh:1302` (`else DIR="$WT"; fi`), feeding `:1316` (`printf 'ok %s %s %s\n'`) and `:1326` (`start every command with "cd $DIR &&"`)
**Boundary:** B3 → B5
**Move:** #2 (implicit sanitization assumption), #12
**Confidence:** High (executed)

The `--dir` argument and the default directory both pass absform before use. When a worktree already holds the branch, DIR takes git's listed path WT, which nothing validates. The only checks are `-d`, `! -L`, and equality with `--dir` when one was given. Probe: `git worktree move` the loop worktree to `$T/my wt;$(touch INJ)` and unlock it, then run `--prompt BRIEF`:
```
ok docs/working/briefs/2026-10-01-x.md feat/x /tmp/claude-1000/u3d-rev-secrev-nj7x/my wt;$(touch INJ)
... Your shell starts outside any checkout: start every command with "cd /tmp/claude-1000/u3d-rev-secrev-nj7x/my wt;$(touch INJ) &&".
```
On the honest path, a worktree the user added by hand at a path with a space breaks two things. The orchestrator's field-4 parse of the `ok` line splits the path, and the loop's `cd` command fails or runs in the wrong place. A path holding shell metacharacters needs someone to choose it or write the registry. The injected text then runs in the next loop's shell under the same uid that set the path, so no privilege boundary is crossed. A hostile writer of that path is a Q-103 residual. The finding stands because the diff's own rule ("DIR: an absolute path of NAMECHARS") is enforced on two of the three DIR sources.

**Recommendation:** Refuse in the WT_N=1 branch when `! absform "$WT"`, with a reason naming the path, as `--dir` and the default directory already do. One added line, plus a test.

#### 3. Lock reasons and worktree paths reach the refusal line raw; a newline adds lines after `refuse`

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1268` (`STEAL_WHY="its worktree $WT is locked ($WT_LOCK): ..."`), `:1314` (`echo "refuse $a: $x"`)
**Boundary:** B3 → B5
**Move:** #2
**Confidence:** High (executed)

`git worktree list -z` gives the lock reason verbatim. Probe with a hand-set reason `x\nok fake line\ndispatched 1`:
```
refuse docs/working/briefs/2026-10-01-x.md: its worktree ... is locked (locked x
ok fake line
dispatched 1): a live loop may hold it; ...
exit 2
```
The scrub keeps LF, so the reason prints as three lines. An honest orchestrator is unaffected: the exit is 2 and the first line starts `refuse`, so nothing is dispatched. Only someone who can run `git worktree lock --reason` on the repo (same uid) can trigger this, which makes it a Q-103 residual. It still contradicts dispatch's header ("one refuse or skip line"), and D11's model treats printed repo text as data that should not be able to take the shape of a verdict line. check_branch already flattens newlines in the names it prints (`${a//$'\n'/ }`).

**Recommendation:** Flatten newlines in WT_LOCK and WT before they go into STEAL_WHY and the missing-or-symlink reason, for example `${WT_LOCK//$'\n'/ }`. Finding 2's absform check covers WT on the adopt path. Optional.

### Untested bypass candidates

- **Branch held in a worktree that is mid-rebase or mid-bisect** (porcelain lists it `detached`, so WT_N=0): I expect git's own `worktree add` check (find_shared_symref covers rebase/bisect state) to refuse. Not probed in git 2.39.5.
- **`submodule.recurse=true` in repo config** (not in STATE_KEYS_RE) during `worktree add` of a loop tree holding a gitlink and `.gitmodules`: `GIT_ALLOW_PROTOCOL=none` should stop any clone, and `.gitmodules` cannot set `update=!cmd`. Not probed.
- **A symlinked parent component of DIR** (for example `.claude` in the main worktree as a symlink): absform is syntactic, so the worktree would be created at the link's target. Traced, not probed. Making `.claude` a symlink takes a writer of the main worktree, which is a Q-103 residual. A `--dir` given by the user is the user's own choice.

Because of these candidates and Finding 1, the steal/lock guard does not appear in the Endorsement Claims.

## Endorsement Claims

- **Claim:** A `post-checkout` hook in the repo's default hooks directory does not run when `--start` adds the worktree.
  **Location:** `scripts/build-loop.sh:389-396` (harden: `core.hooksPath=/dev/null`), `:1309`
  **Evidence:** executed
  **Verified:** p1.sh planted an executable `$(git rev-parse --git-path hooks)/post-checkout` that touches a marker. After `--start` printed `ok`, the marker was absent ("P1 hook did not run").
  **Not verified:** a hook configured as `hook.<name>.command` (state_gate refuses `hook.` keys; not exercised by me), and the `--prompt` add path with a loop-authored tree.
  **route: code-fact-check**
- **Claim:** `--prompt` refuses rather than dispatching into the main worktree when the branch is checked out there.
  **Location:** `scripts/build-loop.sh:1297-1302`
  **Evidence:** executed
  **Verified:** with `feat/x` checked out in the main worktree, `--prompt` printed `refuse ...: its worktree .../repo could not be locked (it may be left unlocked)` and exited 2 (git: "The main working tree cannot be locked or unlocked").
  **Not verified:** the same case with the old worktree locked and `--steal` given (the unlock step would also fail first; traced only).
- **Claim:** The state gate runs before any dispatch step, and a planted `filter.*` key refuses `--start` with nothing created.
  **Location:** `scripts/build-loop.sh:465-466` (`GATED` now covers start/prompt), `:1378-1380`
  **Evidence:** executed
  **Verified:** suite test 3 (`git config filter.x.clean cat` → `refuse state filter.x.clean ...`, exit 2, `none`) passed at e3781a2c.
  **Not verified:** config keys outside STATE_KEYS_RE that `worktree add`'s checkout reads (for example `submodule.recurse`, `core.worktree`); see Untested bypass candidates.
  **route: code-fact-check**
- **Claim:** `--start` makes the branch create-only, so a branch someone else creates between the status read and the creation is neither taken over nor deleted.
  **Location:** `scripts/build-loop.sh:1307-1311`
  **Evidence:** executed
  **Verified:** suite test 3's PATH shim (i1 A5) refused with "its branch feat/x could not be created" and left the other writer's commit on `feat/x`. A failed add deletes the branch only at MAIN_SHA (`update-ref -d ... "$MAIN_SHA"`).
  **Not verified:** a failed add that leaves a partial worktree registry entry (git's own cleanup; only the file-as-parent case is tested).
  **route: code-fact-check**
- **Claim:** Every value interpolated into the loop prompt except DIR on the adopt path comes from a validated or fixed-form source. The brief path and stem pass pathform and isbrief, the branch passes check_branch, MAIN_SHA and STATUS[sha] are object ids, the policy is a fixed word and N is an integer. The constraints text is quoted with `> ` per line after CR removal.
  **Location:** `scripts/build-loop.sh:1322-1342`
  **Evidence:** read-static
  **Verified:** read loop_prompt in full; read status_fields, check_brief and check_branch for the field sources; suite test 1 shows `> H1: keep it small` in the output.
  **Not verified:** constraints text holding a NUL (dropped by `$(...)` with a bash warning on stderr), and how the orchestrator (U3b/U4 skill text, not yet written) splits the prompt from the `ok`/`dispatched` lines.

## Primitive sweep

Primitive: process exec with externally derived arguments (git, date) and shell text sent to the loop

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `build-loop.sh:1249` `git worktree list --porcelain -z` | — | none needed | cleared — no input |
| `build-loop.sh:1271` `date -u -d "${BASH_REMATCH[1]}"` | S5 lock reason | regex `[0-9]{4}-…Z$` | cleared — digits only reach date |
| `build-loop.sh:1272` `git cat-file commit "${STATUS[sha]}"` + awk | S6 tip | check_branch's object id | cleared; committer time can only age the loop's own lock |
| `build-loop.sh:1293` `git cat-file blob "$MAIN_SHA:docs/constraints.md"` | S4 | store_check re-hashed main's tree; read_settings judged the same blob ok | cleared |
| `build-loop.sh:1301` `git worktree unlock/lock "$WT"` | S5 path, S1 stem in reason | none on WT | Finding 1 (race); WT unvalidated → Finding 2 (same uid only for args, no option injection: WT starts `/`) |
| `build-loop.sh:1308` `git update-ref "refs/heads/$br" "$MAIN_SHA" ""` | S3 Branch: | check_branch | cleared — create-only |
| `build-loop.sh:1309` `git worktree add -q --lock --reason "$reason" "$DIR" "$br"` | S2/S5 DIR, S3 br, S6 tree | absform on DIR, check_branch on br, harden + state_gate on checkout | cleared for exec; Finding 1 (add race) |
| `build-loop.sh:1311` `git update-ref -d "refs/heads/$br" "$MAIN_SHA"` | S3 | old-value guard | cleared |
| `build-loop.sh:1316` printed `ok … DIR` line | S5 on adopt path | none | Finding 2 |
| `build-loop.sh:1326` prompt `"cd $DIR &&"` (shell text for the loop) | S2/S5 | absform except adopt path | Finding 2 |
| `build-loop.sh:1314` printed `refuse` line with WT/WT_LOCK | S5 | scrub (keeps LF) | Finding 3 |
| `build-loop.sh:1332` `printf '%s\n' "$3" \| sed 's/\r$//; s/^/> /'` | S4 | per-line quote + scrub | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Concurrent `--prompt` steal/add both dispatch (no mutual exclusion) | Medium | B3 | `scripts/build-loop.sh:1299-1312` | High (mechanism) / Medium (likelihood) |
| 2 | Adopted worktree path unvalidated into `ok` line and `cd $DIR &&` | Low | B3→B5 | `scripts/build-loop.sh:1302, 1316, 1326` | High |
| 3 | Lock reason / path newlines add lines after `refuse` | Informational | B3→B5 | `scripts/build-loop.sh:1268, 1314` | High |

## Overall Assessment

The honest single-dispatcher path holds up. The state gate runs before anything is created. The worktree checkout runs with hooks, fsmonitor, global and system config, and transports switched off, and with the filter, merge and diff drivers refused, so a loop-authored tree checks out without running a command (a planted hook did not run). `--start` creates the branch create-only and undoes only what it made. The prompt carries validated values plus quoted constraints. Q-103 residuals are settled and not re-raised here. A hostile same-uid writer can edit the registry, lock reasons, worktree paths, a symlinked `.claude` parent or its own tip times, and all of these stay out of scope. Finding 3, and Finding 2's metacharacter case, belong to that family.

The one gap the honest path can reach is Finding 1. The lock is the only thing keeping two agents out of one worktree (D1, F44). `--start` gets mutual exclusion from create-only `update-ref`, but `--prompt`'s steal (unlock then lock) and its add-when-none path are plain check-then-act sequences, and two concurrent runs both printed `ok` in probes. Whether this blocks U3d depends on how real two simultaneous dispatchers are. F37 is already "partly" and listed in Q-103, so the alternative to a fix is an override row that moves the `--prompt` part of F44 from "covered" to F37's "partly". The fix is small and in place (a per-repo `flock`, or re-reading the lock after acting). Finding 2 is a one-line absform check that makes all three DIR sources agree.

No findings beyond these within the code paths read. The endorsement claims marked `route: code-fact-check` are pending execution verification.

Outside security scope: the hardened environment sets `GIT_CONFIG_GLOBAL=/dev/null`, so a repo that relies on a global `filter.lfs` checks out LFS pointer files in a loop worktree. That is a functional consequence of the same hardening, not a risk.

**Goal-Alignment Note:** The goal is to land U3d after a clean review-fix loop. Finding 1 is the only item that bears on U3d's own success criterion: F44, which the plan marks "covered", depends on `--prompt`'s lock. It needs a fix or an explicit override row before merge. Findings 2 and 3 are cheap consistency fixes and do not block on their own.
