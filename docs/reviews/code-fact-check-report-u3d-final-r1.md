Commit: 4b863735

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3d (feat/build-loop-u3d)
**Scope:** full branch, `git diff main...HEAD -- scripts test` (scripts/build-loop.sh, test/scripts/build-loop-dispatch.bats) plus every commit message in `git log main..HEAD` (525f947a..4b863735) and the plan's step 7 U3d as-built note; reference specs: plan D1, D2, D3, D11, D14, "Script interface" → Dispatch, "Prompt content", T19/T24/T40/T41/T44
**Checked:** 2026-10-11 (UTC)
**Replication:** final confirming pass, replicate r1 of k=3
**Total claims checked:** 50
**Summary:** 41 verified, 5 mostly accurate, 0 stale, 1 incorrect, 3 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): every logged entry is a measured value quoted from an artifact set; no claim below matches one. No fabrication found, so the log is not updated (and this pass writes only this report).

Execution provenance (all runs by this replicate; outputs captured outside the repo because the brief limits writes to this file):
- Suite: `TMPDIR=$(mktemp -d /tmp/claude-1000/u3d-rev-fc3-XXXX) timeout 600 bats test/scripts/build-loop-dispatch.bats`, cwd `/workspace/.claude/wt-build-loop-u3d`, 2026-10-11T02:30:38Z, exit 0, 4/4 ok. Output: `/tmp/claude-1000/u3d-rev-fc3-logs/suite.txt`.
- P1 (`/tmp/claude-1000/u3d-rev-fc3-scripts/p1.sh`; throwaway repo under its own mktemp dir): fresh --start then --status; raw `worktree list --porcelain -z`; --check from the loop worktree and from a clean main checkout (self-merge brief listing AGENTS.md); marker tips; a moved-away locked worktree's listing; --steal on a non-build-loop reason ending " UTC TIME". cwd its temp dir, 2026-10-11T02:32:55Z, exit 0. Output: `/tmp/claude-1000/u3d-rev-fc3-logs/p1.txt`.
- P4 (`.../p4.sh`): a git shim sleeps 4 s inside `worktree add`; flock probe and a second --start during the first; flock after exit; a directory at the lock path. 2026-10-11T02:33:10Z, exit 0. Output: `/tmp/claude-1000/u3d-rev-fc3-logs/p4.txt`.
- P5 (`.../p5.sh`): --prompt with the branch in a worktree whose path has a space, in two worktrees, at a symlinked path; `--dir /`. 2026-10-11T02:35:48Z, exit 0. Output: `/tmp/claude-1000/u3d-rev-fc3-logs/p5.txt`.
- Mutants (`.../mut.sh`): 15 single-line mutants of scripts/build-loop.sh, each in its own copy of scripts/ and test/, dispatch suite run per mutant. 2026-10-11T02:33:37Z, exit 0. Output: `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`. Killed: M1 marker exception (test 4), M2 no flock (3), M3 no `! -d` (4), M4 no create-only `""` (3), M5 no lock time (4), M6 no branch delete (3), M7 no constraints check (3), M8 tip = MAIN_SHA (4), M9 cap `-gt` (3, 4), M12 no --dir readerform (2), M13 no open check (3), M14 no prompt-absent check (4), M15 no --dir mismatch (4). Survived: M10 no readerform on an existing worktree's path, M11 no `-L` test (both the settled "untested symlink/readerform arms" override row).

All temp dirs of this replicate removed (`/tmp/claude-1000/u3d-rev-fc3-*` but the logs and scripts dirs); no process left running.

---

## Claim 1: "--start dispatches a build loop for BRIEF (D1): after --check's state gate, with --settings' constraints line ok and --status reading the brief open, dispatched under 4 times and its branch absent, it creates the branch at the default branch's commit and adds a worktree for it at DIR (absolute; default .claude/wt-STEM in the main worktree), locked with the reason "build-loop dispatch of STEM, UTC TIME""

**Location:** `scripts/build-loop.sh:279-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each rule's check and order in dispatch, the default DIR, and the lock reason's format; does not establish behaviour in a bare repository (MAINWT empty, where no default exists and the default-dir refusal fires).

The rules are dispatch's first five tests:

```bash
# scripts/build-loop.sh:1296-1300
  if [[ "$CONSTRAINTS" != ok ]]; then x="no loop is dispatched until --settings reads the constraints as ok (...)"
  elif [[ "${STATUS[state]}" != open ]]; then x="the brief is ${STATUS[state]} on the default branch; only an open brief is dispatched"
  elif [[ "${STATUS[dispatched]}" -ge "$DISPATCH_CAP" ]]; then x="it was dispatched ${STATUS[dispatched]} times, and the cap is $DISPATCH_CAP"
  elif [[ "$MODE" == start && "${STATUS[loop]}" != absent ]]; then x="its branch $br exists; --prompt re-dispatches it"
```
(excerpt ends :1300; enclosing dispatch() continues to :1327 — read). The state gate runs first for every gated mode (`:471` `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi`). Default DIR: `:1314` `DIR="$MAINWT/.claude/wt-$stem"`; reason: `:1295` `reason="build-loop dispatch of $stem, UTC $(date -u +%Y-%m-%dT%H:%M:%SZ)"`. The suite's test 1 asserts the default `W="$R/.claude/wt-2026-10-01-x"`, HEAD = main's commit and the lock line by regex; mutants M7, M9, M13 are killed.

**Evidence:** `scripts/build-loop.sh:279-285`, `:471`, `:1290-1327`; `test/scripts/build-loop-dispatch.bats:25-39`; `/tmp/claude-1000/u3d-rev-fc3-logs/suite.txt`, `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`, `/tmp/claude-1000/u3d-rev-fc3-logs/p1.txt`

---

## Claim 2: "Prints ok BRIEF BRANCH DIR / dispatched N / N: the brief's Dispatched: count plus one ... then the loop's prompt, every line after"

**Location:** `scripts/build-loop.sh:285-289`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two fixed lines and N; does not establish that the prompt text has no line that could be mistaken for an ok line (it is free text quoting docs/constraints.md).

```bash
# scripts/build-loop.sh:1325-1326
  printf 'ok %s %s %s\ndispatched %s\n' "$a" "$br" "$DIR" "$n"
  loop_prompt "$a" "$stem" "$ct" "$n" "$tip"
```
with `:1294` `n=$(( ${STATUS[dispatched]} + 1 ))`. Test 3 ends `"${lines[1]}" = "dispatched 4"` after `Dispatched: 3`; P1 printed `ok ... feat/x .../w` and `dispatched 1`.

**Evidence:** `scripts/build-loop.sh:1294`, `:1325-1326`; `test/scripts/build-loop-dispatch.bats:78`; `/tmp/claude-1000/u3d-rev-fc3-logs/p1.txt`

---

## Claim 3: "or skip BRIEF: WHY as --status skips it, or refuse BRIEF: WHY (a rule above, DIR exists, or the worktree could not be added)"

**Location:** `scripts/build-loop.sh:290-291`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the set of refusal reasons dispatch can print for --start; does not establish wording of the state-gate and gate_start refusals (`refuse state ...`), which the header documents under --check.

The parenthetical reads as the full list, but dispatch has four more --start refusals that are neither "a rule above" nor the two named:

```bash
# scripts/build-loop.sh:1301-1302
  elif ! ct="$(git cat-file blob "$MAIN_SHA:docs/constraints.md")"; then x="docs/constraints.md could not be read from the default branch"
  elif ! wt_of "$br"; then x="the worktrees could not be listed"
# scripts/build-loop.sh:1315
    if ! readerform "$DIR"; then x="the default worktree directory (.claude/wt-$stem in the main worktree) is not an absolute path of letters, digits and . _ - /; give --dir"
# scripts/build-loop.sh:1318
    elif [[ "$MODE" == start ]] && ! git update-ref "refs/heads/$br" "$MAIN_SHA" "" 2>/dev/null; then x="its branch $br could not be created"
```
(excerpts inside dispatch(), :1290-1327 — read). The dispatch-lock refusal is named in the --prompt paragraph ("Both refuse ..."). Precise version: "(a rule above, DIR exists or the default DIR is not one --dir takes, the branch could not be created, or the constraints doc, the worktree list or the add failed)".

**Evidence:** `scripts/build-loop.sh:290-291`, `:1301-1302`, `:1315`, `:1318`

---

## Claim 4: "leaving no branch or worktree it made (unless removing the branch fails; the refusal then says so)"

**Location:** `scripts/build-loop.sh:291-293`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one post-creation failure (a failed add) and the earlier refusals that create nothing; does not establish cleanup if the process is killed between update-ref and the add (no trap removes the branch).

```bash
# scripts/build-loop.sh:1319-1321
    elif ! git worktree add -q --lock --reason "$reason" "$DIR" "$br" > "$GATE_TMP/add" 2>&1; then
      x="the worktree $DIR could not be added ($(head -n 1 "$GATE_TMP/add"))"
      [[ "$MODE" != start ]] || git update-ref -d "refs/heads/$br" "$MAIN_SHA" 2>/dev/null || x+="; its new branch $br could not be removed"
```
(excerpt ends :1321; enclosing dispatch() continues to :1327 — read). Test 3's failed add (`--dir "$BATS_TEST_TMPDIR/f/wt"` under a regular file) then `none`; mutant M6 (delete removed) is killed by test 3.

**Evidence:** `scripts/build-loop.sh:1316-1322`; `test/scripts/build-loop-dispatch.bats:61-63`; `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`

---

## Claim 5: "--prompt re-dispatches a brief whose branch exists ... adds a locked worktree at DIR when no worktree has the branch, and locks the one that has it (DIR, if given, must be that one; a lock is replaced by unlocking first, and a failed relock says the worktree may be left unlocked)"

**Location:** `scripts/build-loop.sh:294-299`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the add-or-relock split, the DIR equality test (string equality with git's listed path) and the unlock-then-lock order; does not establish whether a DIR spelling that names the same directory differently (a symlinked parent) is accepted (it is refused as "not in --dir's directory").

```bash
# scripts/build-loop.sh:1305
    if [[ -n "$DIR" && "$DIR" != "$WT" ]]; then x="its branch $br is checked out in $WT, not in --dir's directory"
# scripts/build-loop.sh:1311
    elif ! { [[ -z "$WT_LOCK" ]] || git worktree unlock "$WT"; } || ! git worktree lock --reason "$reason" "$WT"; then x="its worktree $WT could not be locked (it may be left unlocked)"
```
(inside dispatch(), :1290-1327 — read). Test 4 covers the --dir mismatch (M15 killed), relock of an unlocked worktree, and re-adding after prune; M14 (prompt with an absent branch) is killed.

**Evidence:** `scripts/build-loop.sh:1304-1312`; `test/scripts/build-loop-dispatch.bats:100-111`; `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`

---

## Claim 6: "A locked one refuses unless --steal is given, its lock reason ends "UTC TIME", and that time and the tip's commit time are both over 2 hours ago, or the tip is a handoff marker (the loop has ended); then it is locked again with a new reason."

**Location:** `scripts/build-loop.sh:299-303`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the steal condition and the marker exception; does not establish that the reason must be the script's own ("build-loop dispatch of ...") — it need not, and the header does not say it must.

```bash
# scripts/build-loop.sh:1310
    elif [[ -n "$WT_LOCK" && "${STATUS[loop]}" == working ]] && ! steal; then x="$STEAL_WHY"
# scripts/build-loop.sh:1283-1285
  [[ "$t" -le "$l" ]] || l="$t"
  [[ $(( $(date -u +%s) - l )) -gt "$STEAL_AGE" ]] || { STEAL_WHY="..."; return 1; }
```
(steal() spans :1274-1286, read). Mutants M1 (marker exception dropped) and M5 (lock time ignored) are killed by test 4; P1 shows a hand-written reason `manual UTC 2020-01-01T00:00:00Z` with an old tip is taken (`ok ... feat/x .../w`), consistent with the header.

**Evidence:** `scripts/build-loop.sh:1274-1286`, `:1310`; `test/scripts/build-loop-dispatch.bats:84-99`; `/tmp/claude-1000/u3d-rev-fc3-logs/p1.txt`, `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`

---

## Claim 7: "Also refused: the branch in two worktrees, or in one whose directory is missing or a symbolic link (locked or not) or whose path is not one --dir takes."

**Location:** `scripts/build-loop.sh:303-306`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all four refusal arms by execution (the symlink and readerform arms in P5, unlocked); does not establish the symlink arm on a locked worktree (git listed the path as given; the condition is the same elif).

```bash
# scripts/build-loop.sh:1303
  elif [[ "$WT_N" -gt 1 ]]; then x="its branch $br is checked out in $WT_N worktrees"
# scripts/build-loop.sh:1307-1308
    elif [[ -n "$WT_PRUNE" || ! -d "$WT" || -L "$WT" ]]; then x="its branch $br is checked out in $WT, which is missing or a symbolic link (...)"
    elif ! readerform "$WT"; then x="its branch $br is checked out in a worktree whose path is not an absolute path of letters, digits and . _ - /"
```
(inside dispatch(), read). P5 printed, in order: "...checked out in a worktree whose path is not an absolute path...", "...checked out in 2 worktrees", "...which is missing or a symbolic link ...". Test 4 covers the missing locked worktree (M3 killed). The suite does not exercise the symlink or path-form arms (M10, M11 survive; settled override row).

**Evidence:** `scripts/build-loop.sh:1303-1308`; `/tmp/claude-1000/u3d-rev-fc3-logs/p5.txt`, `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`

---

## Claim 8: "Both refuse while another --start or --prompt holds the repository's dispatch lock (a flock on build-loop-dispatch.lock in the git common directory)."

**Location:** `scripts/build-loop.sh:306-308`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers refusal while the lock is held, on the common dir's file; does not establish that a refusal means another run is live (see Claim 30).

```bash
# scripts/build-loop.sh:1393-1395
    if ! { exec 9>> "$(git rev-parse --path-format=absolute --git-common-dir)/build-loop-dispatch.lock" && flock -n 9; } 2>/dev/null; then
      echo "refuse ${ARGS[0]}: another --start or --prompt is running in this repository (its lock could not be taken)"; exit 2
    fi
```
P4: a second --start (another brief) during the first printed that refusal with rc 2; test 3's held-lock case; M2 killed.

**Evidence:** `scripts/build-loop.sh:1389-1398`; `/tmp/claude-1000/u3d-rev-fc3-logs/p4.txt`

---

## Claim 9: "Writes nothing but ... --start's branch and its reflog, the worktrees and locks --start and --prompt make or replace, the dispatch lock file, and its own temporary directory, removed at exit."

**Location:** `scripts/build-loop.sh:311-317`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers every write command in dispatch, wt_of, steal, loop_prompt and the case arm (update-ref create/delete, worktree add/unlock/lock, the lock file, GATE_TMP files); does not establish what git itself writes inside a worktree add beyond "the worktree" (admin dir under .git/worktrees/, the worktree's index and HEAD), which the phrase covers only broadly.

The write commands are `git update-ref "refs/heads/$br" "$MAIN_SHA" ""` (`:1318`), `git update-ref -d` (`:1321`), `git worktree add -q --lock` (`:1319`), `git worktree unlock`/`lock` (`:1311`), and `exec 9>> ".../build-loop-dispatch.lock"` (`:1393`); everything else writes under `$GATE_TMP` (`"$GATE_TMP/wts"`, `"$GATE_TMP/add"`, `"$GATE_TMP/line"`) (paraphrased — no quote available because the claim covers absence of other write commands across five functions, established by reading each in full).

**Evidence:** `scripts/build-loop.sh:1251-1386`, `:1389-1398`

---

## Claim 10: "Exit: 0 ... for --start and --prompt ok; 2 any other --check, --merge, --start or --prompt verdict line ... 1 ... a failed mktemp (--check, --merge, --start, --prompt; no line printed)"

**Location:** `scripts/build-loop.sh:320-326`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ok (0), refuse and skip (2), usage (1); the mktemp-failure exit is read statically (`set -e` on `GATE_TMP="$(mktemp -d)"` in gate_start, `:1001`), not executed.

```bash
# scripts/build-loop.sh:1396-1397
    dispatch "${ARGS[0]}" > "$GATE_TMP/line" || { cat "$GATE_TMP/line"; exit 2; }
    cat "$GATE_TMP/line"
```
Observed: rc 2 for refusals (P4, P5), rc 1 for `--dir /` (P5), 0 for ok runs (P1, suite).

**Evidence:** `scripts/build-loop.sh:1389-1398`, `:999-1029`; `/tmp/claude-1000/u3d-rev-fc3-logs/p4.txt`, `/tmp/claude-1000/u3d-rev-fc3-logs/p5.txt`

---

## Claim 11: "A tip is a marker only when the branch is at least one commit ahead of main and the tip is an empty commit with one parent whose subject is exactly ..." (the marker-tip rule dispatch's B1 exception reads; a fresh --start branch reads as working)

**Location:** `scripts/build-loop.sh:74-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers STATUS[loop] for a 0-ahead fresh branch (working) and the three marker kinds ahead of main; does not establish behaviour for a marker that main later contains (0 ahead again, read as working).

```bash
# scripts/build-loop.sh:678-685
  if [[ "$ahead" -gt 0 ]]; then
    kind="$(marker_kind "$sha")"
    case "$kind" in
      bad\ *) STATUS[line]="skip $a: the tip of $br starts \"handoff:\" but is not a marker: ${kind#bad }"; return ;;
      stopped\ *) loop=stopped; reason="${kind#stopped }" ;;
      *) loop="$kind" ;;
    esac
  fi
```
(excerpt inside status_fields(), :647-689 — read). P1: fresh --start → `... feat/x working <MAIN_SHA> ... 0`; after `handoff: ready`, `handoff: blocked`, `handoff: stopped: x y` → `ready`, `blocked`, `stopped ... x y`. So dispatch's `"${STATUS[loop]}" == working` (`:1310`) needs --steal for a fresh --start branch and not for a marker tip.

**Evidence:** `scripts/build-loop.sh:608-635`, `:647-689`; `/tmp/claude-1000/u3d-rev-fc3-logs/p1.txt`

---

## Claim 12: "--dir takes one absolute path of letters, digits and . _ - / (no empty, . or .. part), given once"

**Location:** `scripts/build-loop.sh:367`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers readerform's rule as the usage text states it ("/" alone fails as an empty part); does not establish that DIR's parent exists or is not a symlink.

```bash
# scripts/build-loop.sh:367
        [[ $# -ge 2 && -z "$DIR" ]] && readerform "$2" || usage "--dir takes one absolute path ..."
```
Test 2 rejects `rel/wt /a/../b /a/./b /a//b "/a b"` with exit 1 (M12 killed); P5's `--dir /` gives rc 1 with this text.

**Evidence:** `scripts/build-loop.sh:363-374`; `scripts/lib/dev-cycle-read.sh:598-602`; `/tmp/claude-1000/u3d-rev-fc3-logs/p5.txt`

---

## Claim 13: "Every mode but the two read modes decides or writes (a new mode is gated by default)."

**Location:** `scripts/build-loop.sh:469-470`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the GATED expression over the six modes the parser sets; does not establish anything for -h (it exits in the parser).

```bash
# scripts/build-loop.sh:470
GATED=""; [[ "$MODE" == settings || "$MODE" == status ]] || GATED=1  # not the gate repository's GATE_*
```

**Evidence:** `scripts/build-loop.sh:341-378`, `:470-471`

---

## Claim 14: "CONSTRAINTS (its word: ok, missing, none-hard or unreadable)" / "row 270: the line's own word"

**Location:** `scripts/build-loop.sh:540-542`, `:602`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four CONSTRAINTS_LINE prefixes read_settings writes; does not establish that a future fifth word would be refused (it would, as anything but ok, by `:1296`).

```bash
# scripts/build-loop.sh:602
  CONSTRAINTS="${CONSTRAINTS_LINE#constraints }"; CONSTRAINTS="${CONSTRAINTS%%[ :]*}"  # row 270: the line's own word
```
Each assignment in read_settings (`:585-600`) starts `constraints ok `, `constraints missing:`, `constraints none-hard:` or `constraints unreadable:`. Test 3's refusals quote `(missing: ...)` and `(none-hard: ...)`.

**Evidence:** `scripts/build-loop.sh:546-603`; `test/scripts/build-loop-dispatch.bats:52-55`

---

## Claim 15: "wt_of BRANCH: the worktrees git lists. MAINWT is the first (the main worktree; empty when bare); WT_N counts those with BRANCH checked out, and WT, WT_LOCK ("locked", or "locked REASON") and WT_PRUNE (set when git calls it prunable) describe the last. Returns 1 when git cannot list them."

**Location:** `scripts/build-loop.sh:1247-1250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record parsing against git's actual -z output; does not establish the bare case by execution (static only).

```bash
# scripts/build-loop.sh:1256-1263
  while IFS= read -r -d '' x; do
    case "$x" in
      "worktree "*) p="${x#worktree }"; b=""; lk=""; pr=""; n=$((n + 1)); [[ "$n" -ne 1 ]] || MAINWT="$p" ;;
      bare) [[ "$n" -ne 1 ]] || MAINWT="" ;;
      "branch refs/heads/$1") b=1 ;;
      locked|"locked "*) lk="$x" ;;
      prunable|"prunable "*) pr=1 ;;
      "") [[ -z "$b" ]] || { WT_N=$((WT_N + 1)); WT="$p"; WT_LOCK="$lk"; WT_PRUNE="$pr"; } ;;
```
(excerpt ends :1263; wt_of continues to :1265 — read; its only `return 1` is the listing at `:1254`). P1's raw listing ends every record, the last included, with an empty field: `...|locked build-loop dispatch of 2026-10-01-x, UTC ...||`.

**Evidence:** `scripts/build-loop.sh:1251-1265`; `/tmp/claude-1000/u3d-rev-fc3-logs/p1.txt`

---

## Claim 16: "D1: dispatches per brief in all; the age (seconds) of a lock and tip --steal takes."

**Location:** `scripts/build-loop.sh:1267-1268`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two values and their uses (`:1298`, `:1284`, the prompt's "at most"); "takes" means strictly over STEAL_AGE (`-gt`).

```bash
# scripts/build-loop.sh:1268
DISPATCH_CAP=4; STEAL_AGE=7200
```

**Evidence:** `scripts/build-loop.sh:1268`, `:1284`, `:1298`, `:1338`

---

## Claim 17: "steal: whether --prompt may take the locked worktree WT (D1, F44): --steal given, and both the time WT_LOCK's reason ends with and the tip's commit time over STEAL_AGE ago (a loop dispatched on an old tip has a new lock). A lock reason not ending " UTC TIME" is never taken. Sets STEAL_WHY and returns 1 when not."

**Location:** `scripts/build-loop.sh:1269-1273`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex, the later-of-two-times rule and the refusal; does not establish that STEAL_WHY is empty on success (it holds the default text, unused then).

```bash
# scripts/build-loop.sh:1278-1282
  if ! [[ "$WT_LOCK" =~ \ UTC\ ([0123456789]{4}-...Z)$ ]] \
    || ! l="$(date -u -d "${BASH_REMATCH[1]}" +%s)" \
    || ! t="$(git cat-file commit "${STATUS[sha]}" | LC_ALL=C awk '...')" \
    || [[ ! "$t" =~ ^[0123456789]+$ ]]; then
    STEAL_WHY="its worktree $WT is locked, and --steal cannot read the time its lock reason ends with or the tip's commit time"; return 1
```
(excerpt ends :1282; steal() continues to :1286 — read). Test 4: a "by hand" reason refuses; a fresh lock on an old tip refuses; both old → ok. M5 killed.

**Evidence:** `scripts/build-loop.sh:1274-1286`; `test/scripts/build-loop-dispatch.bats:86-97`; `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`

---

## Claim 18: "dispatch BRIEF: --start or --prompt (D1) for one brief. Prints "ok BRIEF BRANCH DIR", "dispatched N" and the loop prompt, or one refuse or skip line and returns 1, leaving no branch or worktree it made."

**Location:** `scripts/build-loop.sh:1287-1289`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers dispatch's outputs and return; does not establish the exception the header names.

The comment drops the exception the header states (Claim 4): when the add fails and the delete fails too, the branch dispatch made stays:

```bash
# scripts/build-loop.sh:1321
      [[ "$MODE" != start ]] || git update-ref -d "refs/heads/$br" "$MAIN_SHA" 2>/dev/null || x+="; its new branch $br could not be removed"
```
Precise version: "... leaving no branch or worktree it made (unless removing the branch fails; the line says so)".

**Evidence:** `scripts/build-loop.sh:1287-1327`

---

## Claim 19: "git never calls a locked worktree prunable, and dispatch always locks: test the directory too."

**Location:** `scripts/build-loop.sh:1306`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's listing for a moved-away worktree locked vs unlocked on this host's git; does not establish the behaviour of other git versions.

P1, worktree directory moved away: while locked the listing shows only `worktree .../w` and `locked build-loop dispatch ...`; after `git worktree unlock` it shows `prunable gitdir file points to non-existent location`. dispatch locks on every path (`:1311`, `:1319` `--lock`).

**Evidence:** `scripts/build-loop.sh:1306-1307`, `:1311`, `:1319`; `/tmp/claude-1000/u3d-rev-fc3-logs/p1.txt`

---

## Claim 20: "A marker at the tip: the loop has ended (D3), so its lock is replaced without --steal (i2 api-consistency 1)."

**Location:** `scripts/build-loop.sh:1309`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the condition at `:1310` and the rubric's B1 source (api-consistency 1); does not establish the orchestrator-side flows (blocked answered, review [3], stopped [1]) that U4 will run.

```bash
# scripts/build-loop.sh:1310
    elif [[ -n "$WT_LOCK" && "${STATUS[loop]}" == working ]] && ! steal; then x="$STEAL_WHY"
```
Test 4's `handoff: blocked` tip re-dispatches without --steal; M1 killed. Rubric row B1: "api-consistency 1 (Inconsistent)".

**Evidence:** `scripts/build-loop.sh:1310`; `test/scripts/build-loop-dispatch.bats:98-99`; `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3d.md:46`

---

## Claim 21: "The branch is made here (the empty old value: it must not exist), so a failed add removes only it."

**Location:** `scripts/build-loop.sh:1317`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers create-only semantics against a racing writer and the delete's own old-value guard (`-d ... "$MAIN_SHA"`); does not establish behaviour when another writer moves the branch after creation and before the delete (the delete then fails and the refusal says so).

```bash
# scripts/build-loop.sh:1318
    elif [[ "$MODE" == start ]] && ! git update-ref "refs/heads/$br" "$MAIN_SHA" "" 2>/dev/null; then x="its branch $br could not be created"
```
Test 3's git shim creates feat/x just before the update-ref; the run refuses and feat/x stays at the other commit. M4 (empty old value dropped) killed.

**Evidence:** `scripts/build-loop.sh:1317-1321`; `test/scripts/build-loop-dispatch.bats:69-74`; `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`

---

## Claim 22: "loop_prompt BRIEF STEM CONSTRAINTS N TIP: the loop's prompt ... for dispatch N of a branch at TIP in DIR (branch and policy from STATUS). It says "send your branch to a remote": T20 holds this file to never naming git's command."

**Location:** `scripts/build-loop.sh:1329-1332`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the argument order, the globals read (DIR, STATUS[branch], STATUS[policy], MAIN_SHA, DISPATCH_CAP) and T20's grep; does not establish T20's run at HEAD (not run in this pass; `grep -n -i push scripts/build-loop.sh` printed nothing).

```bash
# scripts/build-loop.sh:1334
  local a="$1" s="$2" br="${STATUS[branch]}"
# test/scripts/build-loop-check.bats:1668
    run grep -nwi push "$BL" "$LIB"
```

**Evidence:** `scripts/build-loop.sh:1333-1357`; `test/scripts/build-loop-check.bats:1667-1670`

---

## Claim 23: "Your own "scripts/build-loop.sh --check $a" is advisory: run from your branch, it refuses a self-merge brief for the checkout and skips the self-merge floor. The orchestrator's run, from the default branch's commit, decides, and for a self-merge brief applies the floor"

**Location:** `scripts/build-loop.sh:1339`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a self-merge brief run from the loop worktree vs a clean checkout at main's commit; does not establish a review brief (no checkout rule, no floor under either run) or a run from a 0-ahead branch (refused earlier, "no commit the default branch lacks").

The checkout refusal (`checkout_gate`, `:928` `the checkout's HEAD is $x, not the default branch's commit`) sets `co`, and srules runs the floor only when `$5` (co) is empty: `:888` `if [[ -z "$5" ]] && floor "$2" "$1" "$4" "$3"; then`. P1: from the loop worktree, `refuse ...: a self-merge brief needs --check run from a clean checkout ...` then `path ... A AGENTS.md` (floor skipped, though Paths: lists it); from a clean detached checkout at main, `deny ... A AGENTS.md: an instruction or prompt file, which sessions load from the checkout`.

**Evidence:** `scripts/build-loop.sh:885-905`, `:916-997`, `:1030-1110`; `/tmp/claude-1000/u3d-rev-fc3-logs/p1.txt`

---

## Claim 24: the prompt's floor list "(instruction and prompt files and what they import, dot paths, paths below the name of an instruction file or an imported .md file, the gate's own code, the user's and the cycle's records such as docs/constraints.md, docs/decisions/ and docs/thoughts/, and working docs or reviews not your own)"

**Location:** `scripts/build-loop.sh:1339`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each floor() word (instr, imported, dot, below, gate, cycle/settings, user, record, working, review); does not establish the walk-failure word (every path refused), which is a failure mode, not a path category.

floor() refuses `truthrule` words, then `gate`, `docs/thoughts/*` as record, non-own `docs/working/*` and `docs/reviews/*`, the walk's `imported`, and `below` (`scripts/lib/dev-cycle-read.sh:1953-1970`). "below" in floor covers any isstart name, prompt files included; the prompt says "instruction file", but every prompt-file pattern lies under `.claude/` (`:669` `PROMPT_DIR='(^|/)\.claude/(commands|agents|output-styles|skills)/'`, plus `.claude/rules/`), so a path below one is already a dot path the list names. docs/human-author/ is not named, but the list says "such as".

**Evidence:** `scripts/lib/dev-cycle-read.sh:669-673`, `:1873-1893`, `:1953-1990`

---

## Claim 25: "Force-add your research doc (git add -f docs/working/research-$s.md), so your design records land with your work."

**Location:** `scripts/build-loop.sh:1346`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the path is ignored in this repo (so -f is needed) and that ownfile/the floor take it with s = the brief's full stem; does not establish other repos' ignore rules.

```bash
# scripts/lib/dev-cycle-read.sh:1916
  if [[ "$1" =~ ^docs/working/(research|plan|checkpoint|handoff|test-strategy)-(.+)\.md$ && "${BASH_REMATCH[2]}" == "$2" ]]; then return 0; fi
```
`.gitignore:27` `docs/working/research-*.md`; dispatch's `stem="${a##*/}"; stem="${stem%.md}"` (`:1294`) is the same stem check_line passes to srules (`:1083`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:1913-1919`; `.gitignore:27`; `scripts/build-loop.sh:1294`, `:1083`

---

## Claim 26: "End with one marker, an empty commit at your branch tip whose first line is exactly one of: ... "handoff: stopped: REASON" (1 to 120 printable ASCII characters, no blank at either end)"

**Location:** `scripts/build-loop.sh:1347-1350`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the subject grammar, emptiness and the REASON range against marker_kind; does not establish the one-parent rule (not stated in the prompt; a loop's `git commit --allow-empty` meets it).

```bash
# scripts/build-loop.sh:633
  if [[ "$subj" == "handoff: stopped: "* ]] && printf '%s\n' "$r" | LC_ALL=C grep -qxE '[!-~]([ -~]{0,118}[!-~])?'; then echo "stopped $r"
```
P1's three marker commits read as ready, blocked and `stopped ... x y`.

**Evidence:** `scripts/build-loop.sh:608-635`; `/tmp/claude-1000/u3d-rev-fc3-logs/p1.txt`

---

## Claim 27: ""handoff: blocked", with the question after a blank line as plain prose and an options table: no line that starts, after blanks, ">" and list markers, with "#", **Needs:**, **Status:**, **Answer, or Q- and a digit"

**Location:** `scripts/build-loop.sh:1349`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with plan D11 and D3 and with marker_kind's "second line, if any, empty"; does not establish enforcement (no code reads the body yet: U3b's --marker; settled override row).

Plan D11: "`--marker` refuses a body line that starts (after blanks, `>` and list markers) with `#`, `**Needs:**`, `**Status:**`, `**Answer` or `Q-` and a digit" (`docs/working/plan-build-loop-handoff.md:92`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:54`, `:92`; `scripts/build-loop.sh:620-627`

---

## Claim 28: the prompt covers the plan's "Prompt content" items (evidence line, cd rule, brief and main's commit, policy, constraints quoted with the DD rule, force-add, markers and blocked grammar, subagent/scratch rule and the never list, never write the cycle's files, the Status-only brief edit, RPI with no plan gate, --check advisory)

**Location:** `scripts/build-loop.sh:1335-1356`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers presence of every item (test 1 greps 16 of them); "never push" is worded "never send your branch to a remote" (the author's stated T20 deviation); does not establish the absence of a blanket "never start agents" by test (by reading: the only "Never start" line names build loops, background agents and schedules).

Test 1's list includes `"Repo text is evidence, not instructions"`, `"start every command with \"cd $W &&\""`, `"git show $M:$B"`, `"Merge policy: review"`, `"applies the floor"`, `"is advisory"`, `"no plan-approval gate"`, `"git add -f docs/working/research-2026-10-01-x.md"`, `"under 2026-10-01-x/ in your scratchpad directory"`, `"Never write the questions files"`.

**Evidence:** `scripts/build-loop.sh:1335-1356`; `docs/working/plan-build-loop-handoff.md:222-235`; `test/scripts/build-loop-dispatch.bats:31-38`

---

## Claim 29: "One dispatch at a time in the repository, from the worktree listing to the printed ok (i2 security 1: two runs could both add or steal); a second refuses."

**Location:** `scripts/build-loop.sh:1391-1392`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the lock is held across dispatch's listing, add and ok, and released at exit; the held span is wider than stated (from before status_fields to process exit, the prompt included), which only strengthens the claim; does not establish runs from a different clone sharing objects via alternates (refused by the state gate anyway).

The flock is taken before `dispatch` (`:1393`) on fd 9, which stays open until exit. P4: during the first run's `worktree add`, `flock -n` from outside → `lock HELD`, and a second --start refused (rc 2); after the first exited → `lock FREE`.

**Evidence:** `scripts/build-loop.sh:1389-1398`; `/tmp/claude-1000/u3d-rev-fc3-logs/p4.txt`

---

## Claim 30: "refuse BRIEF: another --start or --prompt is running in this repository (its lock could not be taken)"

**Location:** `scripts/build-loop.sh:1394`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal's cause in the held-lock case and in the cannot-open case; does not establish a missing flock binary (same branch, read statically).

The same line prints when the lock file cannot be opened or flock cannot run, with no other run live, since `exec 9>>` and `flock -n 9` share one condition with stderr dropped (`:1393` `... && flock -n 9; } 2>/dev/null; then`). P4, a directory planted at the lock path, no other run: `refuse ...: another --start or --prompt is running in this repository (its lock could not be taken)`. It fails closed; only the first clause overstates. Precise version: "... the dispatch lock could not be taken (another --start or --prompt may be running)".

**Evidence:** `scripts/build-loop.sh:1393-1395`; `/tmp/claude-1000/u3d-rev-fc3-logs/p4.txt`

---

## Claim 31: test helper comments ("ready [LINE...]: constraints ok and brief x ...", "refused WHY: the run refused brief x with WHY alone, exit 2", "none: no feat/x and no worktree but the main one", "lock WT REASON: WT locked with REASON alone")

**Location:** `test/scripts/build-loop-dispatch.bats:13-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each helper's body; does not establish that `refused` checks stderr (it does not).

```bash
# test/scripts/build-loop-dispatch.bats:19,21
refused() { [ "$status" -eq 2 ] && [ "$output" = "refuse $B: $1" ] || { echo "want: $1"; show; return 1; }; }
none() { ! git show-ref --verify -q refs/heads/feat/x && [ "$(git worktree list --porcelain | grep -c '^worktree ')" -eq 1 ] || { show; return 1; }; }
```

**Evidence:** `test/scripts/build-loop-dispatch.bats:13-23`

---

## Claim 32: test 1, "--start creates the branch at main's commit and a locked worktree, and prints the loop prompt (T19, row 622, U3d)"

**Location:** `test/scripts/build-loop-dispatch.bats:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted branch, HEAD, lock line, prompt strings and row 622's "applies the floor"; does not establish T19's "--dir rules" (test 2).

Passed in the suite run; it asserts `"$(git -C "$W" rev-parse HEAD) $(git -C "$W" symbolic-ref HEAD) $(git rev-parse feat/x)" = "$M refs/heads/feat/x $M"` and the lock regex.

**Evidence:** `test/scripts/build-loop-dispatch.bats:25-39`; `/tmp/claude-1000/u3d-rev-fc3-logs/suite.txt`

---

## Claim 33: test 2, "--start takes an absolute new --dir and refuses anything else (T19, U3d)"

**Location:** `test/scripts/build-loop-dispatch.bats:41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers relative, `..`, `.`, `//`, blank, an existing DIR and --steal with --start; does not establish a symlinked DIR (refused by `-L`, untested).

M12 (no --dir readerform) is killed by test 2.

**Evidence:** `test/scripts/build-loop-dispatch.bats:41-49`; `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`

---

## Claim 34: test 3, "--start refuses without ok constraints, for a brief not open or dispatched 4 times, and on planted state, leaving nothing (T24, T41, T44, U3d)", with its comments "A failed add removes the branch it made.", "One dispatch at a time: a held dispatch lock refuses (i2 security 1).", "Create-only: a branch another writer makes after the check is not taken over (i1 A5)."

**Location:** `test/scripts/build-loop-dispatch.bats:51`, `:61`, `:64`, `:69`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named refusal followed by `none` (or, for create-only, the other writer's branch kept, then deleted and `none`); "without ok constraints" is tested for missing and none-hard, not unreadable.

Killed here: M2, M4, M6, M7, M9, M13. Rubric sources: B2 "security 1 (Medium)", A5 "fact-check claim 25b".

**Evidence:** `test/scripts/build-loop-dispatch.bats:51-79`; `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3d.md:23`, `:47`; `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`

---

## Claim 35: test 4, "--prompt locks the branch's worktree, refuses a locked one but with --steal over 2 hours, and adds one when none has the branch (T24, T40, T41, U3d)", with its comments "A marker at the tip ... (i2 api-consistency 1)", "A dead loop's worktree, gone but still locked (git never calls it prunable), even with old times (i1 A1)", "-a: not the worktree under .claude/"

**Location:** `test/scripts/build-loop-dispatch.bats:81`, `:98`, `:104`, `:109`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named behaviour and the `-a` reason (commit_all's `git add -A` would stage the worktree under `.claude/` as a gitlink); does not establish the stopped or ready marker kinds through --prompt (only blocked).

Killed here: M1, M3, M5, M8, M9, M14, M15. P1 confirms the "never prunable while locked" premise.

**Evidence:** `test/scripts/build-loop-dispatch.bats:81-111`; `test/lib/build-loop-fixtures.bash` (`commit_all() { git add -A && ...`); `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`, `/tmp/claude-1000/u3d-rev-fc3-logs/p1.txt`

---

## Claim 36: the T41 tag on tests 3 and 4 (plan T41: "A brief with `Dispatched: 4` → `--prompt` refuses; `Dispatched: 3` → ok, prints `dispatched 4`")

**Location:** `test/scripts/build-loop-dispatch.bats:51`, `:81`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers T41's two halves across the two tests; does not establish T41's ok half through --prompt.

The refusal half runs through --prompt (`:109-110`, `Dispatched: 4` → "it was dispatched 4 times, and the cap is 4"), but the ok half runs through --start (`:78` `dsp --start "$B"; [ "$status" -eq 0 ] && [ "${lines[1]}" = "dispatched 4" ]`), not --prompt as T41 states. The cap test is shared code (`:1298`), so the gap is small. Precise version: tag test 3 as T41's ok half "via --start".

**Evidence:** `test/scripts/build-loop-dispatch.bats:57`, `:78`, `:109-110`; `docs/working/plan-build-loop-handoff.md:383`

---

## Claim 37a: 525f947a body: "four tests: the prompt's required lines, the worktree at main's commit and its lock; --dir rules; refusals that leave no branch or worktree (constraints, state, cap, a failed add, planted state); --prompt's lock, --steal at two hours, a missing worktree"

**Location:** `git log 525f947a` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test file as of 525f947a (4 `@test`s; the missing-worktree case was then an unlocked one); does not establish later changes.

`git show 525f947a:test/scripts/build-loop-dispatch.bats` has `@test` at lines 25, 41, 50, 69 and `:89` `git worktree unlock "$W"; rm -rf "$W"`.

**Evidence:** `test/scripts/build-loop-dispatch.bats` at 525f947a, lines 25-93

---

## Claim 37b: 525f947a body: "Mutation-checked against the code commit that follows."

**Location:** `git log 525f947a` (commit message)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about which mutants were run then; this pass's own mutants at HEAD are listed in the provenance block.

No mutation record for aff39758 is in the repo (paraphrased — no quote available because the claim covers absence of an artifact: no file under docs/ names those mutants). Would need the author's mutant list and outputs.

**Evidence:** `docs/reviews/code-fact-check-report-u3d-i1.md` (no such record)

---

## Claim 38a: aff39758 body (subject and first paragraphs: rules, update-ref create-only, the outputs, --prompt's lock and 2-hour --steal, rows 270 and 622; Notes on --prompt's constraints, --dir absolute, the lock reason, "never push" wording)

**Location:** `git log aff39758` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against the code at aff39758 (the marker exception came later, ad5ff2d5); does not cover the Notes' steal sentence (Claim 38b).

At aff39758, `:1300` (then) read `elif [[ -n "$WT_LOCK" ]] && ! steal; then x="$STEAL_WHY"` (from `git diff aff39758 23ba4511`), matching "a locked one is taken only with --steal when both ... over 2 hours old".

**Evidence:** `git diff aff39758 23ba4511 -- scripts/build-loop.sh`

---

## Claim 38b: aff39758 Notes: "--steal also weighs the lock's own time, so a loop just dispatched on an old tip is not stolen, and a lock without a build-loop time is never taken"

**Location:** `git log aff39758` (commit message)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "build-loop time" clause; the first clause (lock time weighed) is correct. Settled: override row (A6, Won't-Fix; to be corrected in the merge message). No new evidence beyond confirming it.

Any reason ending " UTC TIME" is read (`:1278` regex anchors only ` UTC ...Z$`). P1: `manual UTC 2020-01-01T00:00:00Z` with an old tip → `ok ... feat/x .../w`.

**Evidence:** `scripts/build-loop.sh:1278`; `docs/reviews/override-log.md` (row "aff39758's commit Notes say ..."); `/tmp/claude-1000/u3d-rev-fc3-logs/p1.txt`

---

## Claim 39: bdf61b16 body: "Iteration 1 of 3, full branch at aff39758, fact-check k=1 (opus): 31 claims, 2 Incorrect, 6 Mostly Accurate. A1 ... is a behavioral red, so the loop-pass short-circuit skipped the critics"

**Location:** `git log bdf61b16` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts and the short-circuit; does not establish the model used.

`docs/reviews/code-fact-check-report-u3d-i1.md`: `**Total claims checked:** 31`, `**Summary:** 21 verified, 6 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable`; rubric: `Loop-pass short-circuit: used at aff39758`.

**Evidence:** `docs/reviews/code-fact-check-report-u3d-i1.md:1-10`; `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3d.md:2`

---

## Claim 40a: 23ba4511 body: A1 (missing locked worktree refuses; tested), A2 (header names the skip line), A3 (failed branch removal, the new branch's reflog, relock), A5 (create-only test)

**Location:** `git log 23ba4511` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers A1, A2, A3, A5 against the 23ba4511 diff; A4 is Claim 40b.

The aff39758..23ba4511 diff adds `or skip BRIEF: WHY as --status skips it`, `unless removing the branch fails`, `and its reflog`, `a failed relock says the worktree may be left unlocked`, and `elif [[ -n "$WT_PRUNE" || ! -d "$WT" || -L "$WT" ]]`; the create-only test is test 3's shim block.

**Evidence:** `git diff aff39758 23ba4511 -- scripts/build-loop.sh`

---

## Claim 40b: 23ba4511 body: "A4: the prompt's floor list, the stopped REASON's blanks and the blocked-body rule (D11) match the code and plan."

**Location:** `git log 23ba4511` (commit message)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the floor list at 23ba4511; the REASON and blocked-body parts were accurate. Superseded at HEAD by ad5ff2d5 (B12).

At 23ba4511 the list read `(instruction and prompt files and what they import, dot paths, the gate's own code, the user's and the cycle's records ...)`, lacking floor's `below` word; ad5ff2d5 added "paths below the name of an instruction file or an imported .md file". Known (brief item 6).

**Evidence:** `git diff aff39758 23ba4511 -- scripts/build-loop.sh` (prompt hunk); `scripts/build-loop.sh:1339`

---

## Claim 40c: 23ba4511 Notes: "A6 (aff39758's Notes overstate the steal rule) is corrected in the merge message"

**Location:** `git log 23ba4511` (commit message)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of the merge message at 4b863735; does not establish its future text.

No `docs/working/merge-msg-build-loop-u3d.md` exists yet (paraphrased — no quote available because the claim covers absence of a file: `ls docs/working/` lists merge-msg files through u3a3 only). The merge-message author must carry the correction (override row A6 says so too).

**Evidence:** `docs/working/` listing; `docs/reviews/override-log.md` (A6 row)

---

## Claim 41: e3781a2c body: "Lite fix-drift over 23ba4511 found the refusal also covers a symlink at the worktree path. Rows for the two declined iteration-1 items."

**Location:** `git log e3781a2c` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal text change and the two rows; does not establish the fix-drift pass's process.

The message now reads `which is missing or a symbolic link` (`:1307`); override-log gains the A6 and A7 rows dated 2026-10-10 for `feat/build-loop-u3d`.

**Evidence:** `scripts/build-loop.sh:1307`; `docs/reviews/override-log.md` (last 10 rows)

---

## Claim 42: 4a0bedfd body: "Iteration 2 of 3 (full branch for the critics, k=1 fact-check on the fix delta): no Must Fix; B1 (marker re-dispatch) and B2 (concurrent dispatch) Must Address, fixed in the next commit; 8 override rows for the declined items; plan step 7's U3d bullet gains its as-built note."

**Location:** `git log 4a0bedfd` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric's iteration-2 section, the row count (10 u3d rows: A6, A7, then 8) and the plan diff; does not establish the reports' contents.

Rubric: `Status (iteration 2): no Must Fix; Must Address B1, B2 fixed.` and B13 `Defer / Won't-Fix (8 override rows)`.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3d.md:40-60`; `git diff main...HEAD -- docs/reviews/override-log.md`

---

## Claim 43: ad5ff2d5 body: B1-B12 as listed ("B2: ... flock on build-loop-dispatch.lock in the git common directory from the worktree listing to the printed ok; a second run refuses. B3/B6: readerform ... (absform dropped). B4: a lock reason's newlines are flattened ... B8: loop_prompt takes TIP as an argument. ... Tests for B1, B2, B5, B8.")

**Location:** `git log ad5ff2d5` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each B item against HEAD's code and the named tests (M1, M2, M8 killed; B5's usage text asserted in test 2); does not establish the orchestrator flows named in B1's parenthetical (U4).

`grep -n absform scripts/build-loop.sh` finds nothing; B4 is `:1276` `${WT_LOCK//[$'\n\r']/ }`, the only place a lock reason is printed; B8 is `:1326` `loop_prompt "$a" "$stem" "$ct" "$n" "$tip"`.

**Evidence:** `scripts/build-loop.sh:1276`, `:1326`, `:1393`; `/tmp/claude-1000/u3d-rev-fc3-logs/mut.txt`

---

## Claim 44a: 4b863735 subject: "U3d rubric: restore the composition check section"

**Location:** `git log 4b863735` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the section's presence at HEAD.

The rubric holds `## 🧩 Composition check` with iteration 1 and 2 entries.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3d.md:62-66`

---

## Claim 44b: 4b863735 body: "Lite fix-drift over 4a0bedfd..ad5ff2d5: no findings."

**Location:** `git log 4b863735` (commit message)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing about that pass's inputs; this report's findings on ad5ff2d5's lines (Claims 18, 30) are Mostly accurate wording items, not drift.

No fix-drift artifact is committed (paraphrased — no quote available because the claim covers a review pass with no file in docs/reviews/).

**Evidence:** `docs/reviews/` listing

---

## Claim 45: plan step 7, U3d as-built note ("`--start` creates the branch by `update-ref` with an empty old value (create-only), then `worktree add --lock --reason ...` ... a lock is taken without `--steal` when the tip is a handoff marker ... Both hold a flock ... `--dir` must be absolute (readerform). Output: ...")

**Location:** `docs/working/plan-build-loop-handoff.md:320`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each stated behaviour (Claims 1-8, 19-21, 29); does not establish the note's completeness (it omits the readerform refusal of an existing worktree's path).

Each sentence matches the code cited in Claims 1, 4, 5, 6, 7, 8 and 21.

**Evidence:** `docs/working/plan-build-loop-handoff.md:320`; `scripts/build-loop.sh:1290-1327`, `:1389-1398`

---

## Findings

All findings are wording; no executed behaviour contradicted a claim but 38b (settled).

- **F1 (Claim 3)** Severity: Low (🟢). Location: `scripts/build-loop.sh:290-291`. Evidence: `#             or skip BRIEF: WHY as --status skips it, or refuse BRIEF: WHY (a` / `rule above, DIR exists, or the worktree could not be added),` while dispatch also refuses at `:1301`, `:1302`, `:1315`, `:1318`. Confidence: High. Legibility-target: the orchestrator author (U4) reading the header to map refusal lines to actions.
- **F2 (Claim 18)** Severity: Low (🟢). Location: `scripts/build-loop.sh:1289`. Evidence: `# and returns 1, leaving no branch or worktree it made.` vs `:1321` `|| x+="; its new branch $br could not be removed"`. Confidence: High. Legibility-target: a maintainer editing dispatch.
- **F3 (Claim 30)** Severity: Low (🟢). Location: `scripts/build-loop.sh:1394`. Evidence: `echo "refuse ${ARGS[0]}: another --start or --prompt is running in this repository (its lock could not be taken)"`, printed in P4 with no other run (a directory at the lock path). Confidence: High. Legibility-target: the orchestrator and the user reading a refusal (they might wait for a run that does not exist).
- **F4 (Claim 36)** Severity: Low (🟢). Location: `test/scripts/build-loop-dispatch.bats:51`, `:78`. Evidence: `dsp --start "$B"; [ "$status" -eq 0 ] && [ "${lines[1]}" = "dispatched 4" ]` (T41 names --prompt for the ok half). Confidence: High. Legibility-target: a reader tracing plan T-ids to tests.
- **F5 (Claim 40c)** Severity: Low (🟢), action item for the merge. Location: commit 23ba4511 Notes. Evidence: `A6 (aff39758's Notes overstate the steal rule) is corrected in the merge message`; no `docs/working/merge-msg-build-loop-u3d.md` yet. Confidence: High. Legibility-target: the merge-message author.
- Known, settled, re-confirmed without new evidence: 38b (A6 row), 40b (fixed by B12).

## Claims Requiring Attention

### Incorrect
- **Claim 38b** (commit aff39758 Notes): "a lock without a build-loop time is never taken" — any reason ending " UTC TIME" is taken (P1). Settled (A6 Won't-Fix row); the merge message must carry the correction.

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`scripts/build-loop.sh:290-291`): the refusal list omits the default-DIR form, create-only, constraints-read and worktree-list refusals.
- **Claim 18** (`scripts/build-loop.sh:1289`): dispatch's comment drops the failed-delete exception the header states.
- **Claim 30** (`scripts/build-loop.sh:1394`): "another ... is running" also prints when the lock file cannot be opened or flock cannot run.
- **Claim 36** (`test/scripts/build-loop-dispatch.bats:51`): T41's ok half is tested through --start, not --prompt.
- **Claim 40b** (commit 23ba4511): A4's "match the code" missed floor's "below" (fixed in ad5ff2d5).

### Unverifiable
- **Claim 37b** (commit 525f947a): "Mutation-checked" — needs the author's mutant list and outputs (this pass's own 15 mutants at HEAD are recorded above).
- **Claim 40c** (commit 23ba4511): the merge message that should correct A6 does not exist yet.
- **Claim 44b** (commit 4b863735): no artifact for the lite fix-drift pass.

## Goal-Alignment Note

The goal is to land U3d after a clean review-fix loop. Every behavioural claim in the header, comments, prompt and tests that this pass could execute holds: the dispatch rules, the steal and marker-tip rule, all four existing-worktree refusal arms, create-only creation with cleanup, and the dispatch flock (held from before the listing to process exit, released at exit). The suite passes, and 13 of 15 mutants are killed (the two survivors are the settled untested symlink and readerform arms). What remains is wording: three Low-severity header and comment imprecisions (F1-F3) and a T-id tag (F4), none of which misleads the honest dispatch path, plus one merge-time duty (F5: the merge message must correct aff39758's steal Note). Nothing here blocks the merge.
