Commit: e3781a2c

# API Consistency Review — feat/build-loop-u3d (U3d, iteration 2)

**Scope:** `git diff main...HEAD -- scripts test` in /workspace/.claude/wt-build-loop-u3d (scripts/build-loop.sh, test/scripts/build-loop-dispatch.bats), base main 12913760
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3d-i1.md (commit aff39758; A1-A5 since fixed in 23ba4511/e3781a2c); plan docs/working/plan-build-loop-handoff.md D1, D4, "Script interface" → Dispatch, "Skill changes" steps 7-10

Probe provenance: every probe ran under `set -eu` in its own `mktemp -d /tmp/claude-1000/u3d-rev-apicons-XXXX` directory, removed afterwards (verified: no `u3d-rev-apicons-*` left, no build-loop process running). Scripts are in `/tmp/claude-1000/-workspace/a5f5e272-7757-42c2-8d1d-5c819728d807/scratchpad/u3d-i2-apicons/`:
- **p1.sh**: the arg parser's usage messages for --start/--prompt flag misuse beside --check/--merge's, run outside any repo (parsing happens before the repo check); and `absform` (build-loop.sh:338) against the lib's `readerform` (dev-cycle-read.sh:598) on 15 inputs.
- **p2.sh**: a bats test using the suite's own fixture (`test/lib/build-loop-fixtures.bash`, copied; `scripts` symlinked to the worktree's) that runs `--start`, commits a `handoff: blocked` marker in the loop's worktree, then `--status`, `--prompt`, `--prompt --steal` and a second `--start`.

## Baseline Conventions

Surveyed the script's existing modes (`--settings`, `--status`, `--check`, `--merge`: header build-loop.sh:6-274, parser :340-375, mode block :1353-1383) and the lib's helpers.

- **Output lines:** a verdict word first, then `BRIEF`, then space-separated fields (`ok BRIEF STATE POLICY ...`, `ok BRIEF TIP TREE`, `merged BRIEF TIP TREE NEW`); refusals `refuse BRIEF: WHY`, skips `skip BRIEF: WHY` (as --status), gate refusals `refuse state WHAT: WHY`. Lines that follow a verdict also carry BRIEF (`path BRIEF S PATH`, `deny BRIEF S PATH: WHY`, :176-177), including in single-brief --merge.
- **Exits:** 0 every verdict ok; 2 any other verdict line or the state gate; 1 bad usage (stderr, `WHY (usage: ...)`), not a repo, no lib, failed mktemp.
- **Usage errors:** flag-value format and placement are usage errors with a specific message: `--expect takes a full 40- or 64-hex commit id`, `--expect takes one commit id, given once`, `--approved goes with --merge` (:349-357). Runtime state is a refusal.
- **Settings variables:** `POLICY` (the word) beside `POLICY_LINE` (the printed line); `NEVER` (the array) beside `NEVER_LINE`; `SLOTS_LINE`, `READERS_LINE` lines only.
- **Path validators:** `*form` predicates in the lib and script: `pathform` (dev-cycle-read.sh:223), `readerform` (:598), `globform` (build-loop.sh:526).
- **Worktree discovery:** `land` parses `git worktree list --porcelain -z` into `$GATE_TMP/wts` (:1161-1168).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--start BRIEF` | CLI mode | `--check BRIEF...`, `--merge BRIEF`, `--status BRIEF...` | `scripts/build-loop.sh:6-11` | Consistent: `--verb BRIEF`, brief path positional; matches plan's name |
| `--prompt BRIEF` | CLI mode | same | `scripts/build-loop.sh:6-11` | Consistent; matches plan |
| `--dir DIR` | CLI flag | `--expect SHA`, `--approved Q-NNN` | `scripts/build-loop.sh:349-357` | Consistent: `--noun VALUE`, given once, value format a usage error |
| `--steal` | CLI flag (bool) | none (first boolean flag in this script) | none — searched `scripts/build-loop.sh` parser :340-375 | New category; name is the plan's (D1). Its misuse message is not (Finding 2) |
| `ok BRIEF BRANCH DIR` | output line | `ok BRIEF TIP TREE`, `ok BRIEF STATE POLICY BRANCH ...`, `merged BRIEF TIP TREE NEW` | `scripts/build-loop.sh:66,165,214` | Consistent: verdict word, BRIEF, fields with no blanks (BRANCH via check-branch, DIR via absform) |
| `dispatched N` | output line | `path BRIEF S PATH`, `deny BRIEF S PATH: WHY` | `scripts/build-loop.sh:176-177` | Minor drift: a follow-on line without BRIEF; the plan names it so (Finding 5) |
| `refuse BRIEF: WHY` / `skip BRIEF: WHY` | output line | --check's and --status's | `scripts/build-loop.sh:86,120,197` | Consistent (A-fix made the header list the skip form) |
| `CONSTRAINTS` | variable | `POLICY` (word) / `POLICY_LINE`, `NEVER` / `NEVER_LINE` | `scripts/build-loop.sh:539` | Consistent: bare noun for the value, `_LINE` for the line |
| `absform` | function | `readerform`, `pathform`, `globform` | `scripts/lib/dev-cycle-read.sh:223,598`, `scripts/build-loop.sh:526` | Name consistent; body duplicates `readerform` (Finding 3) |
| `wt_of`, `WT`, `WT_N`, `WT_LOCK`, `WT_PRUNE`, `MAINWT` | function / globals | `land`'s local `w`, `bare`; `VERDICT[...]`, `STATUS[...]` | `scripts/build-loop.sh:1154-1168` | Informational (Finding 6): a second porcelain parser beside land's |
| `steal`, `STEAL_WHY` | function / global | `approval` / `MERGE_WHY` | `scripts/build-loop.sh:1122,1373` | Consistent: predicate plus a `*_WHY` reason global |
| `dispatch`, `loop_prompt` | function | `check_line`, `land`, `status_line` | `scripts/build-loop.sh` | Consistent |

## Findings

#### 1. --prompt refuses the plan's routine re-dispatch of a loop that ended on a marker, until the lock and marker are 2 hours old and --steal is given

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:1300` (with `steal`, :1266-1279; `dispatch`, :1282-1318)
**Move:** 3 (consumer contract), 9 (retry semantics)
**Confidence:** High
**Legibility-target:** U4's orchestrator (skill steps 7 and 10) and the plan's D1/D4 reader

Evidence:
```bash
# scripts/build-loop.sh:1292, 1300
  elif [[ "$MODE" == prompt && "${STATUS[loop]}" == absent ]]; then x="its branch $br does not exist; --start creates it"
    elif [[ -n "$WT_LOCK" ]] && ! steal; then x="$STEAL_WHY"
```
(non-contiguous lines of dispatch() :1282-1318, read whole; `STATUS[loop]` is read only to test `absent`, so a marker tip does not change the lock rule)

The plan's normal flows re-dispatch with `--prompt` after the loop has ended on a marker: "`blocked` → ... Once every Asked ID is answered (D8), the brief goes back in the queue on its existing branch, and the loop is re-dispatched with `--prompt` plus the answers"; review answer "[3] → re-dispatch with the note"; "`stopped` → one entry with **[1] re-dispatch**" (plan :60-64). Nothing in the plan or the script unlocks a worktree when a marker is collected (grep for `unlock` in the plan, skills/dev-cycle/SKILL.md and the script: only --prompt's own relock and the missing-worktree hint). D1 kept the lock to stop a second agent beside "a worktree still locked by a live session", and its reason was `"<session> <UTC time>"`, which would let the orchestrator tell its own or a dead session's lock from a live one; the author's reason (`build-loop dispatch of STEM, UTC TIME`) has no session, and the script ignores the one signal it does have that the loop ended: a marker at the tip (`STATUS[loop]` is `blocked`, `ready` or `stopped`).

Executed (p2.sh): after `--start` and a `handoff: blocked` marker, `--status` reads `... feat/x blocked <sha> 2026-10-10 0`, yet `--prompt` prints `refuse ...: its worktree .../wt-2026-10-01-x is locked (...): a live loop may hold it; --steal takes it once the lock and the tip are over 2 hours old` (exit 2) and `--prompt --steal` prints `... its lock or tip is under 2 hours old` (exit 2). So a question the user answers within 2 hours of the marker cannot be resumed; after 2 hours it can only be resumed with `--steal`, which turns the plan's exceptional override into the routine path and makes its "a live loop may hold it" text false for every marker re-dispatch. Same for an orchestrator that runs `--start`, then fails to launch the Agent: its own fresh lock blocks its retry for 2 hours.

**Recommendation:** Decide the contract before U4 writes against it: either `--prompt` replaces a lock without `--steal` when `STATUS[loop]` is a marker (the loop ended; F44's two-agents risk needs a live loop), keeping `--steal` for a `working` tip, or the orchestrator unlocks a worktree when it collects a marker (step 7) and the plan says so. Add the marker case to T40 and the header's --prompt paragraph either way.

#### 2. --steal misused under --start, or given twice, reports "takes one brief path" instead of naming the flag

**Severity:** Minor
**Location:** `scripts/build-loop.sh:367-370`
**Move:** 4 (error consistency)
**Confidence:** High

Evidence:
```bash
# scripts/build-loop.sh:367-370
      elif [[ "$1" == --steal && "$MODE" == prompt && -z "$STEAL" ]]; then STEAL=1; shift
      else ARGS+=("$1"); shift; fi
    done
    [[ ${#ARGS[@]} -eq 1 ]] || usage "--$MODE takes one brief path" ;;
```
(excerpt ends inside the parser's `--start|--prompt)` arm, :361-370, read whole)

Executed (p1.sh): `--start b.md --steal` → exit 1, `--start takes one brief path`; `--prompt b.md --steal --steal` → exit 1, `--prompt takes one brief path`. The same script names the misplaced or repeated flag for its other flags: `--check b.md --approved Q-1` → `--approved goes with --merge`; `--expect`/`--approved`/`--dir` say "given once" (:349, :354, :365). The exit (1, usage) is the right class, consistent with D1's usage-vs-refusal split; only the message misleads. An orchestrator that passes `--steal` to `--start` by mistake is told its brief count is wrong.

**Recommendation:** Give `--steal` its own arm: `[[ "$MODE" == prompt ]] || usage "--steal goes with --prompt"`, `[[ -z "$STEAL" ]] || usage "--steal is given once"`, mirroring `--approved` at :353.

#### 3. absform duplicates the lib's readerform

**Severity:** Minor
**Location:** `scripts/build-loop.sh:337-338`
**Move:** 2 (naming against the grain)
**Confidence:** High

Precedent: `readerform` (absolute, NAMECHARS only, not / alone, no empty, . or .. part) used in `scripts/lib/dev-cycle-read.sh:595-601`

Evidence:
```bash
# scripts/build-loop.sh:337-338
# absform PATH: an absolute path of NAMECHARS with no empty, . or .. part.
absform() { [[ "$1" =~ ^/[$NAMECHARS]+$ && "$1/" != *//* && "$1/" != */./* && "$1/" != */../* ]]; }
```
Executed (p1.sh): `absform` and `readerform` agree on all 15 inputs (`/`, `//`, `/a`, `/a/`, `/a/b`, `/a/./b`, `/a/../b`, `/.`, `/..`, `/a.b`, `/a/..`, `a`, `/a b`, `/...`, `/a//b`). The `--dir` usage text also restates readerform's WHY wording ("not an absolute path of letters, digits and . _ - / with no empty, . or .. part", dev-cycle-read.sh:641). Two predicates for one path form can drift apart (a later hardening of one misses the other); the gate's own path rules live in the lib.

**Recommendation:** Call `readerform` for `--dir` and the default DIR (or rename it in the lib to a neutral `absform` used by both), and drop the script's copy.

#### 4. The plan's Dispatch interface, U4's reference, does not describe what was built

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:39,215-218` against `scripts/build-loop.sh:279-303`
**Move:** 3 (documentation drift)
**Confidence:** High

Evidence:
```
# plan :217
- `--prompt BRIEF [--steal]` → the brief must be `open`, with its branch present and `Dispatched:` under 4. Prints the prompt; adds a worktree only if the branch has none; refuses a locked worktree unless `--steal` and the tip is over 2 hours old.
```
```bash
# scripts/build-loop.sh:10
#        scripts/build-loop.sh --prompt BRIEF [--dir DIR] [--steal]
```
The branch diff touches no plan file (`git diff main...HEAD --stat`: scripts, test, docs/reviews only). Built but not in the plan: `--prompt`'s `[--dir DIR]` (and its "must be that one" rule); `--prompt` also needing constraints ok; `--steal` needing the lock reason's own time over 2 hours (a lock without a parseable time never taken); the lock reason `build-loop dispatch of STEM, UTC TIME` instead of D1's `"<session> <UTC time>"`; the `ok BRIEF BRANCH DIR` line (the plan names only `dispatched N` and "the prompt"); the skip line. The script header documents all of these, so the code is self-consistent; the risk is U4's author reading the plan's interface, which is where the orchestrator's parsing will be specified (steps 8-10).

**Recommendation:** Update the plan's Dispatch bullets and D1's lock-reason text to the built contract (the header's --start/--prompt paragraphs are the source), in this unit or as U4's first edit.

#### 5. `dispatched N` is the only follow-on line without BRIEF

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1316`
**Move:** 2 (naming against the grain)
**Confidence:** Medium

Precedent: follow-on lines carry BRIEF as field 2 (`path BRIEF S PATH`, `deny BRIEF S PATH: WHY`), also in single-brief --merge, used in `scripts/build-loop.sh:176-177,1003`

Evidence:
```bash
# scripts/build-loop.sh:1316
  printf 'ok %s %s %s\ndispatched %s\n' "$a" "$br" "$DIR" "$n"
```
The plan fixes the line's text (`print \`dispatched N\``, plan :218) and both modes take one brief, so nothing is ambiguous today; downgraded from Minor because the plan chose it. Noted so the convention is chosen deliberately if a multi-brief dispatch ever appears.

**Recommendation:** None required; keep it if U4's parsing is positional (line 2), which the header states.

#### 6. Row 663's trigger fired: wt_of is a second worktree-list parser beside land's

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1246-1262` against `:1160-1168`
**Move:** 1 (baseline)
**Confidence:** Medium

Evidence:
```bash
# scripts/build-loop.sh:1251-1259 (wt_of, :1246-1262 read whole)
  while IFS= read -r -d '' x; do
    case "$x" in
      "worktree "*) p="${x#worktree }"; b=""; lk=""; pr=""; n=$((n + 1)); [[ "$n" -ne 1 ]] || MAINWT="$p" ;;
      ...
      "") [[ -z "$b" ]] || { WT_N=$((WT_N + 1)); WT="$p"; WT_LOCK="$lk"; WT_PRUNE="$pr"; } ;;
```
```bash
# scripts/build-loop.sh:1162-1167 (land, :1154-1240 read whole)
      "worktree "*) p="${x#worktree }" ;;
      bare) bare=1 ;;  # the repository itself
      "branch refs/heads/$MAIN") [[ -z "$w" ]] || { MERGE_WHY="the default branch is checked out in two worktrees"; return 1; }; w="$p" ;;
```
`wt_of "$MAIN"` yields what land's loop computes (`WT_N > 1` is land's two-worktree refusal, `WT` its `w`); land's bare flag differs (wt_of exposes only `MAINWT=""`). The two parse the same output with different record boundaries (record start vs empty-field end). Not a consumer-facing problem; land's second pass (the git-dir walk that counts a worktree the list drops) is not in wt_of, which is a gap only for a worktree whose gitdir file is gone. Row 663 left land unsplit until "U3d or U3b needing the worktree discovery": this is that point. Architecture-review owns the structural call.

**Recommendation:** Either let land's first pass call `wt_of "$MAIN"` (adding a bare flag), or record in the override log why two parsers stay.

## What Looks Good

- **Mode and flag names** match the plan exactly (`--start`, `--prompt`, `--dir`, `--steal`) and the script's `--verb BRIEF [--noun VALUE]` shape.
- **The output contract is parseable without guessing:** line 1 `ok BRIEF BRANCH DIR` (DIR always absform, BRANCH check-branch-valid, so whitespace splitting is safe), line 2 `dispatched N`, the prompt every line after to EOF; the orchestrator learns DIR from field 4 and N from line 2. A refusal is exactly one line (`refuse BRIEF: WHY`, `skip BRIEF: WHY` or `refuse state ...`) with exit 2, and output is buffered in `$GATE_TMP/line` so no partial prompt reaches stdout on a refusal (:1378-1381).
- **Usage vs refusal split** follows `--expect`'s precedent: a malformed or repeated `--dir` is usage (exit 1) like a malformed `--expect`; runtime state (DIR exists, default DIR not absolute in a bare repo, `--prompt --dir` naming another worktree) is a refusal (exit 2).
- **Exit codes** extend the header's existing table (:316-325) rather than inventing new ones; `--start`/`--prompt` join `--check`/`--merge` under the state gate (`GATED` now opts modes out instead of in, :465, so a future deciding mode is gated by default).
- **`CONSTRAINTS`** follows `POLICY`/`POLICY_LINE`: a bare noun for the word, derived from the line it reports (row 270), so the value and the printed line cannot disagree.
- **Requiring constraints ok for --prompt** matches the plan's step 10 ("only when `--settings` prints `constraints ok`"), which governs every dispatch, not only --start.
- **Refusal texts point to the other mode** (`--prompt re-dispatches it`, `--start creates it`), a helpful symmetry.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | --prompt refuses marker re-dispatch (blocked/ready/stopped) until 2 h and --steal | Inconsistent | `scripts/build-loop.sh:1300` | High |
| 2 | --steal misuse says "takes one brief path" | Minor | `scripts/build-loop.sh:367-370` | High |
| 3 | absform duplicates readerform | Minor | `scripts/build-loop.sh:337-338` | High |
| 4 | Plan's Dispatch interface not updated to the built contract | Minor | `docs/working/plan-build-loop-handoff.md:215-218` | High |
| 5 | `dispatched N` lacks BRIEF unlike path/deny | Informational | `scripts/build-loop.sh:1316` | Medium |
| 6 | Row 663: second worktree-list parser | Informational | `scripts/build-loop.sh:1246-1262` | Medium |

## Overall Assessment

The new surface is consistent with the script's conventions: names, line shapes, exit codes, the usage-vs-refusal split and the settings-variable naming all follow existing precedent, and the output is positionally parseable for U4. One contract issue matters before U4 is written: the lock rule treats every locked worktree as possibly live, so the plan's own re-dispatch flows after a `blocked`, `ready` or `stopped` marker are refused for 2 hours and then need `--steal` (Finding 1, executed); that needs a decision (marker tip releases the lock, or the orchestrator unlocks on collect) and a T40 case. The rest are fixable in place (a specific `--steal` usage message, reuse of `readerform`, a plan update) or informational.

## Goal-Alignment Note

The unit's goal is a dispatch interface U4's orchestrator can drive through a whole loop's life (start, collect, re-dispatch). The start path and the crash-restart path (`--steal` on a stale working tip) serve it; the answered-question and review-note re-dispatch paths do not yet without a 2-hour wait and a routine `--steal`, so Finding 1 is the one that bears on the goal rather than on polish.
