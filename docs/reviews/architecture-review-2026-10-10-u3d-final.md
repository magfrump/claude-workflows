Commit: 4b863735

# Architecture Review — feat/build-loop-u3d (final confirming pass, iteration 3)

**Scope:** `git diff main...HEAD -- scripts test` in /workspace/.claude/wt-build-loop-u3d (scripts/build-loop.sh +188/-10, test/scripts/build-loop-dispatch.bats +111), base main 12913760
**Date:** 2026-10-10
**Based on:** shared brief u3d-fin/shared.md; Stage 1 fact-check replicates docs/reviews/code-fact-check-report-u3d-final-r{1,2,3}.md (summary in the brief); my iteration-2 report docs/reviews/architecture-review-2026-10-10-u3d-i2.md; override rows 270, 496, 622, 663 and rows 685-694 (2026-10-10, feat/build-loop-u3d)
**Replication:** k=1, final confirming pass (every finding reported, Consider-tier included)

Scope check: in scope (two public CLI modes and their output contract, a new settings value, the GATED default, a process-wide dispatch lock). Suite at 4b863735: `TMPDIR=$(mktemp -d /tmp/claude-1000/u3d-rev-archfin-XXXX) timeout 600 bats test/scripts/build-loop-dispatch.bats` → 4/4 ok (temp dir removed).

Settled, not re-raised: i2 findings 1 (wt_of vs land, row 687), 2 (CONSTRAINTS from line text, row 688), 4's remaining half (prompt restating marker/floor/blocked-body rules, row 689), 5 (gate_start reuse, row 690). i2 findings 6 (GATED comment) and 7 (git's add reason) are fixed: `# Every mode but the two read modes decides or writes (a new mode is gated by default).` and `x="the worktree $DIR could not be added ($(head -n 1 "$GATE_TMP/add"))"`.

Trust-boundary cross-reference: most recent security review is `docs/reviews/security-review-2026-10-10-u3d-i2.md` (Commit: `e3781a2c` — security review predates this diff; boundary may be stale). Finding 1 touches its `B4` ("[branch tip ...] → [... steal's committer time] → [... steal decision]") and `B3` (lock reasons → wt_of → worktree lock/unlock). No recommendation below moves a boundary; finding 1's narrows what crosses B3/B4.

## Dependency Map

Unchanged in shape from i2; the i2 fixes moved two edges:

```
case start|prompt (:1389-1398)
   → gate_start                                  [existing startup; row 690]
   → flock fd 9 on GIT_COMMON_DIR/build-loop-dispatch.lock   [new in i2; process-lifetime, released at exit]
   → dispatch BRIEF (:1290-1328)
        → status_fields  (STATUS[state|dispatched|loop|sha|branch|policy])  [row 496 values]
        → CONSTRAINTS, DISPATCH_CAP
        → wt_of BRANCH (MAINWT, WT, WT_N, WT_LOCK, WT_PRUNE)
        → steal (STEAL, STEAL_AGE, WT_LOCK, STATUS[sha])     gated by STATUS[loop] == working
        → git update-ref / worktree add | unlock+lock
        → loop_prompt BRIEF STEM CT N TIP  (+ globals DIR, STATUS[branch], STATUS[policy], MAIN_SHA, DISPATCH_CAP)
```

Direction is sound: dispatch reads the existing value layers and nothing existing depends on it. The i2 fixes improved two edges: loop_prompt no longer depends on dispatch mutating STATUS[sha] (TIP is an argument; `[[ "$MODE" == prompt ]] || tip="$MAIN_SHA"` writes a local), and the process-level resource (the flock) lives in the mode's case arm, beside gate_start's other process-lifetime setup (GATE_TMP and its EXIT trap), not inside the per-brief function. That is the right owner: fd 9 lives until exit, and dispatch stays a per-brief function with no process state of its own.

## Findings

#### 1. The marker-tip exemption is keyed on `STATUS[loop] == working`, so every other loop value, `absent` included, replaces a lock without --steal; --start reaches it through the shared WT_N == 1 arm

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1310` (exemption), `:1303-1312` (WT_N == 1 arm, shared by both modes), `:1299` (--start's branch rule)
**Move:** 8 (extension points), 6 (substitutability of the two modes through one chain)
**Confidence:** High
**Legibility-target:** the author fixing Stage 1's r3 item, and U3b if it adds a STATUS[loop] value

Evidence (dispatch :1290-1328 read in full; status_fields :647-689 read in full):
```bash
  elif [[ "$MODE" == start && "${STATUS[loop]}" != absent ]]; then x="its branch $br exists; --prompt re-dispatches it"
  [...]
  elif [[ "$WT_N" -eq 1 ]]; then
    [... DIR, prune/symlink, readerform arms ...]
    # A marker at the tip: the loop has ended (D3), so its lock is replaced without --steal (i2 api-consistency 1).
    elif [[ -n "$WT_LOCK" && "${STATUS[loop]}" == working ]] && ! steal; then x="$STEAL_WHY"
    elif ! { [[ -z "$WT_LOCK" ]] || git worktree unlock "$WT"; } || ! git worktree lock --reason "$reason" "$WT"; then x="its worktree $WT could not be locked (it may be left unlocked)"
    else DIR="$WT"; fi
```
status_fields' loop values (`:655`, `:681-686`): `absent`, `working`, `ready`, `blocked`, `stopped`.

The comment states the rule as "a marker at the tip", but the code states it as "anything not working". Those are the same set today only for --prompt, where `absent` is refused at :1300. For --start, `absent` is the only value that passes :1299. If a worktree has the unborn branch checked out (Stage 1 r3: an orphan checkout, or a worktree whose ref was deleted), WT_N is 1, and the run enters an arm written for --prompt. That arm then treats `absent` as an ended loop and replaces a live lock without --steal. This is the structural cause of r3's "relocks that worktree" result, and it is wider than r3 states: the lock is taken over with no age check. The rule is also a denylist on a value set owned by another function. A new loop state added in status_fields (U3b's marker work is the likely place) becomes "ended" by default, and its lock is taken without --steal. That fails open on the trust edge the security review labels `B3`/`B4` (lock reason and tip → steal decision; `docs/reviews/security-review-2026-10-10-u3d-i2.md`, Commit `e3781a2c`, predates this diff). The honest path reaches the --start case only through an unborn or deleted ref, which is rare. That makes this Minor, not Coupling.

**Recommendation:** Do the author's planned fix (--start refuses when WT_N > 0, so the WT_N == 1 arm is --prompt's alone). Then state the exemption as the values it means: `case "${STATUS[loop]}" in ready|blocked|stopped)` exempt, anything else goes through steal. A new loop state then fails closed, and the code reads like its comment and the header ("or the tip is a handoff marker").

#### 2. The case arm, dispatch and the header still state three overlapping subsets of one contract

**Severity:** Minor
**Location:** `scripts/build-loop.sh:279-307` (header), `:1287-1289` (dispatch's comment), `:1391-1395` (case arm)
**Move:** 3 (module boundary: the CLI contract a caller reads)
**Confidence:** High
**Legibility-target:** U4's orchestrator author, who will code against the header

Evidence:
```bash
#             or skip BRIEF: WHY as --status skips it, or refuse BRIEF: WHY (a
#             rule above, DIR exists, or the worktree could not be added),
#             leaving no branch or worktree it made (unless removing the
#             branch fails; the refusal then says so).
```
```bash
# dispatch BRIEF: --start or --prompt (D1) for one brief. Prints "ok BRIEF
# BRANCH DIR", "dispatched N" and the loop prompt, or one refuse or skip line
# and returns 1, leaving no branch or worktree it made.
```
```bash
    # One dispatch at a time in the repository, from the worktree listing to the
    # printed ok (i2 security 1: two runs could both add or steal); a second refuses.
    if ! { exec 9>> "$(git rev-parse --path-format=absolute --git-common-dir)/build-loop-dispatch.lock" && flock -n 9; } 2>/dev/null; then
      echo "refuse ${ARGS[0]}: another --start or --prompt is running in this repository (its lock could not be taken)"; exit 2
```

The three agree on the main contract: the output lines, exit 2 on any refusal, one dispatch at a time, and nothing left behind. Each one omits a part the others carry:
- Dispatch's comment omits the failed-delete exception that the header carries. It also does not state its precondition, that the caller holds the dispatch lock. The case arm is the only place that says so. A second caller of dispatch (a re-dispatch loop in U4, a test) would run without the mutual exclusion, and nothing in dispatch would show it.
- The header's --start refusal list omits four reasons the code has (fact-check: branch not created, worktrees not listed, constraints.md not read, default DIR fails readerform). Those reasons are runtime failures, and "or the worktree could not be added" reads as a closed list.
- The case arm says the lock covers "from the worktree listing to the printed ok". The lock is actually taken before status_fields and held until exit (fact-check verified). That is stronger than the comment says, which is harmless. But when the r3 fix moves the WT_N test, the comment's start point is the line most likely to go stale.
- The lock refusal says "another --start or --prompt is running" also when the lock file cannot be opened or flock is missing. It fails closed, so only the wording is wrong (fact-check).

None of this is wrong behaviour. The cost is that U4 codes against the header, and the header does not say which refusals are policy and which are runtime failures.

**Recommendation:** In the header, end the refusal list with "or a git step failing (each refusal names it)" rather than enumerating. In dispatch's comment, add "the caller holds the dispatch lock" and the failed-delete exception. Change the case arm's comment to "from before status_fields to exit". Two clauses in the lock refusal would separate "held by another run" (flock failed) from "could not be opened".

#### 3. STEAL_AGE was named, but the two refusal sentences and the header still say "2 hours"

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1268`, `:1276`, `:1285`; header `:299-300`
**Move:** 7 (coupling: a value and its prose copies)
**Confidence:** High
**Legibility-target:** whoever changes the steal age

Evidence:
```bash
DISPATCH_CAP=4; STEAL_AGE=7200
[...]
  STEAL_WHY="its worktree $WT is locked (${WT_LOCK//[$'\n\r']/ }): a live loop may hold it; --steal takes it once the lock and the tip are over 2 hours old"
[...]
  [[ $(( $(date -u +%s) - l )) -gt "$STEAL_AGE" ]] || { STEAL_WHY="its worktree $WT is locked, and its lock or tip is under 2 hours old"; return 1; }
```

DISPATCH_CAP is fully interpolated: the cap refusal and the prompt both use `$DISPATCH_CAP`, and only the header's "under 4 times" is prose. STEAL_AGE is used once, in the comparison, and the two sentences a caller reads still hardcode "2 hours". A changed STEAL_AGE would leave both refusals stating the old age. There is no test of the boundary to catch it (test 4 uses lock times far from 2 hours). This is the residue of i2 finding 4's cap/steal-age half, which row 689 records as done.

**Recommendation:** Interpolate `$((STEAL_AGE / 3600)) hours` in both STEAL_WHY strings, or keep "2 hours" and add a comment at STEAL_AGE naming the two sentences and the header line that restate it.

#### 4. loop_prompt still takes DIR from a rewritten global

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1312`, `:1315`, `:1325-1327`, `:1329-1335`
**Move:** 3 (module boundary), 7 (coupling)
**Confidence:** High
**Legibility-target:** U4, if it reprints a prompt

Evidence:
```bash
# loop_prompt BRIEF STEM CONSTRAINTS N TIP: the loop's prompt (plan, "Prompt
# content"; D2, D3, D11, D14; row 622), for dispatch N of a branch at TIP in
# DIR (branch and policy from STATUS). [...comment continues to :1332]
```

B8 fixed the worse half: STATUS[sha] is no longer mutated, so STATUS again holds its documented values (`:631-640`). DIR, the parsed `--dir`, is still overwritten by dispatch (`DIR="$WT"`, or the default `$MAINWT/.claude/wt-$stem`) and read by loop_prompt and the ok printf. The comment now documents this ("in DIR (branch and policy from STATUS)"), so it is no longer a hidden dependency. It is a stated one. With one caller and a documented signature, this is acceptable.

**Recommendation:** None required. If a second caller of loop_prompt appears, pass DIR as a sixth argument and keep `--dir`'s global as parsed.

## What Looks Good

- **The flock is in the right place.** It is a process-lifetime resource (fd 9, released at exit), so it sits beside gate_start's other process setup in the case arm. Dispatch stays a per-brief function. The lock lives in the git common dir, so every worktree's run shares it. The header lists the lock file under "Writes nothing but", which keeps that inventory complete.
- **TIP as an argument** removes the one mutation that made STATUS disagree with its own STATUS[line]. dispatch's local `tip` makes the --start/--prompt difference one visible line (`:1325`).
- **DISPATCH_CAP** is now the single source for the cap in the refusal and the prompt ("dispatch $4 of at most $DISPATCH_CAP").
- **The marker-tip rule reads status_fields' value** rather than calling marker_kind again. That is the row 496 arrangement, and it is correct. Finding 1 is only about which values it tests.
- **GATED as a denylist with an honest comment.** New modes fail closed, and the comment now says so.
- **Each write is still at the end of its decision chain.** The create-only `update-ref ... ""` and the paired delete keep "leave nothing behind" a property of the structure.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Marker-tip exemption keyed on `!= working`; `absent` (--start via the shared WT_N == 1 arm, r3) and any future loop state replace a lock without --steal | Minor | `scripts/build-loop.sh:1310`, `:1303-1312` | High |
| 2 | Case arm, dispatch and header state overlapping subsets of the contract (lock precondition, refusal list, delete exception, lock span) | Minor | `scripts/build-loop.sh:279-307`, `:1287-1289`, `:1391-1395` | High |
| 3 | STEAL_AGE named but both refusals and the header hardcode "2 hours" | Minor | `scripts/build-loop.sh:1276`, `:1285` | High |
| 4 | loop_prompt reads DIR as a rewritten global (now documented) | Informational | `scripts/build-loop.sh:1312-1335` | High |

## Overall Assessment

The branch keeps the script's structure intact and the i2 fixes improved it. Process-level exclusion moved to the mode's case arm, where process-lifetime state belongs. The prompt builder no longer depends on a mutated STATUS. The cap has one source. There is no Structural or Coupling-tier finding. The most important structural concern is finding 1. The new marker-tip rule is written as "not working" rather than "a marker", and the WT_N == 1 arm belongs to --prompt but is not guarded by mode. Together they produce Stage 1's r3 result: a --start that relocks an existing worktree without --steal. The author's planned WT_N > 0 refusal for --start closes the reachable case. An explicit `ready|blocked|stopped` test makes the rule fail closed for future loop states. Both are small fixes in place. Findings 2 and 3 are wording drift between three statements of one contract. They are cheap to align now, before U4 codes against the header.

**Goal-Alignment Note:** The user's goal is to land U3d after a clean review-fix loop. Every finding here is Consider-tier (Minor or Informational), so none blocks the merge on architectural grounds. Finding 1 is the one to act on before landing. It explains Stage 1's r3 Incorrect item structurally, and the author's planned fix plus the explicit-values test closes it. Findings 2 and 3 can ride the same fix commit or take override rows with the revisit trigger "U4's orchestrator steps". Finding 4 needs nothing.
