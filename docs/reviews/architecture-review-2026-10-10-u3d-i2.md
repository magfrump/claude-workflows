Commit: e3781a2c

# Architecture Review — feat/build-loop-u3d (iteration 2)

**Scope:** `git diff main...HEAD -- scripts test` in /workspace/.claude/wt-build-loop-u3d (scripts/build-loop.sh +172/-10, test/scripts/build-loop-dispatch.bats +102), base main 12913760
**Date:** 2026-10-10
**Based on:** docs/reviews/code-fact-check-report-u3d-i1.md (Commit aff39758; claims 4 and 8b fixed in 23ba4511/e3781a2c per the shared brief); shared brief u3d-i2/shared.md; override log rows 270, 496, 622, 663 and the two U3d rows (A6, A7)
**Replication:** k=1, loop pass

Scope check: in scope. The diff adds two public CLI modes (`--start`, `--prompt`, with `--dir`/`--steal`), a new output contract (`ok BRIEF BRANCH DIR` / `dispatched N` / prompt), a new settings value (`CONSTRAINTS`), changes the cross-cutting startup gate selection (`GATED`), and adds a new test module. The bats file is reviewed only for structure (new suite rather than build-loop-merge.bats: fine, it matches one-suite-per-mode-family). Suite run at e3781a2c: `TMPDIR=$(mktemp -d /tmp/claude-1000/u3d-rev-archrev-XXXX) timeout 600 bats test/scripts/build-loop-dispatch.bats` → 4/4 ok.

Trust-boundary cross-reference: the most recent `docs/reviews/security-review-*.md` is `security-review-2026-10-10-u3a3-i2.md` (Commit: `e25a6e89` — security review predates this diff; boundary may be stale). Its map (B1-B5) labels no boundary at worktree discovery, dispatch or the prompt, so no finding below sits on a labeled boundary. No security review exists for this branch yet.

## Dependency Map

Everything is inside one script (`scripts/build-loop.sh`, 1383 lines) plus its sourced lib (`scripts/lib/dev-cycle-read.sh`). The new code is a vertical slice at the bottom of the script:

```
case start|prompt  →  gate_start (default_gate, mktemp GATE_TMP, gate_repo, store_check --main, reader_settings, read_settings, never_res, open_shared)
                   →  dispatch BRIEF
                        → status_fields (STATUS[...], row 496's values)          [existing, --status/--check]
                        → CONSTRAINTS (new, from read_settings)                  [row 270]
                        → git cat-file blob MAIN_SHA:docs/constraints.md
                        → wt_of BRANCH (MAINWT, WT, WT_N, WT_LOCK, WT_PRUNE)     [new; parallels land's list read]
                        → steal (STEAL, STATUS[sha], WT_LOCK)                     [new]
                        → git update-ref / worktree add|lock|unlock (caller's repo, plain git)
                        → loop_prompt (4 args + globals DIR, STATUS[branch,sha,policy], MAIN_SHA)
```

Direction is sound: the new mode depends on the existing read layer (status_fields, read_settings) and the existing startup gate, and nothing existing depends on the new functions. No new lib dependency, no lib change. The one cross-mode relation is conceptual duplication: `wt_of` and `land` both read `git worktree list --porcelain -z` into the same scratch file.

## Findings

#### 1. wt_of and land carry two parsers of the same worktree list; row 663's trigger has fired

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1246-1262` (wt_of), `scripts/build-loop.sh:1160-1168` (land's list read)
**Move:** 7 (coupling surface), 2 (responsibility)
**Confidence:** High
**Legibility-target:** the U3b/U4 author who next needs worktree discovery, and whoever revisits row 663

Evidence (land, an excerpt of its list read; land continues to :1236, read):
```bash
  git worktree list --porcelain -z > "$GATE_TMP/wts" || { MERGE_WHY="the worktrees could not be listed"; return 1; }
  while IFS= read -r -d '' x; do
    case "$x" in
      "worktree "*) p="${x#worktree }" ;;
      bare) bare=1 ;;  # the repository itself
      "branch refs/heads/$MAIN") [[ -z "$w" ]] || { MERGE_WHY="the default branch is checked out in two worktrees"; return 1; }; w="$p" ;;
```
(wt_of, excerpt; full function :1246-1262 read)
```bash
  git worktree list --porcelain -z > "$GATE_TMP/wts" || return 1
  # NUL-ended fields; an empty field ends each record.
  while IFS= read -r -d '' x; do
    case "$x" in
      "worktree "*) p="${x#worktree }"; b=""; lk=""; pr=""; n=$((n + 1)); [[ "$n" -ne 1 ]] || MAINWT="$p" ;;
      bare) [[ "$n" -ne 1 ]] || MAINWT="" ;;
      "branch refs/heads/$1") b=1 ;;
```

Row 663 deferred splitting land with the trigger "U3d or U3b needing the worktree discovery". U3d needed it and wrote a second reader instead. The two now agree only by care: both write `$GATE_TMP/wts`, both parse the same porcelain grammar, and wt_of's outputs already subsume land's list half (`wt_of "$MAIN"` gives WT_N for "two worktrees", WT for `w`, and an empty MAINWT for `bare`, since only the first record can be bare). A future change to the grammar handling (a git version's new field, a record-end rule) has to be made twice, and the two already differ in record handling (land ignores record ends; wt_of resets per record). On the trust question the brief raises: the difference is justified, not inconsistent. land moves the default branch, so it cross-checks every worktree git dir for a HEAD or rebase state the list hides; dispatch only adds or locks a worktree, and git's own `worktree add` is the backstop for what the list hides. Probe (own temp repo, git 2.39.5): with feat/x's worktree mid-rebase, `git worktree list --porcelain` shows that worktree as `detached` (so wt_of counts WT_N=0), and `git worktree add ../wt2 feat/x` fails with `fatal: 'feat/x' is already checked out at '.../wt'`. The honest path is therefore safe; the stricter cross-check belongs to land alone.

**Recommendation:** Have land's list read call `wt_of "$MAIN"` (refuse on WT_N > 1, `w=$WT`, `bare` from an empty MAINWT) and keep the git-dir cross-check in land as land's own stricter half; that is the split row 663 asked about, along the line where the two modes' trust genuinely differs. If declined, append a row closing row 663's trigger with the reason (two readers by choice) so the next unit does not re-raise it.

#### 2. CONSTRAINTS is parsed back out of CONSTRAINTS_LINE's text

**Severity:** Minor
**Location:** `scripts/build-loop.sh:597`
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** whoever rewords a constraints line in read_settings

Evidence (read_settings :541-598, read in full):
```bash
  CONSTRAINTS="${CONSTRAINTS_LINE#constraints }"; CONSTRAINTS="${CONSTRAINTS%%[ :]*}"  # row 270: the line's own word
```

Row 270 asked for "a machine-readable CONSTRAINTS value, as POLICY and NEVER have". POLICY is assigned in the branch that decides it (`POLICY="$v"`); CONSTRAINTS is recovered from the printed sentence, the shape row 496 called Coupling for status lines. Here the blast radius is small: the parse and the five sentences it reads sit in one function 20 lines apart, and it fails closed (a reworded ok line gives a word other than `ok`, so dispatch refuses rather than dispatching). Its cost is that the printed wording is now a data contract nobody can see from the line's assignment, and the first reader is the dispatch gate (D2). Not Coupling-tier because it cannot widen what dispatches.

**Recommendation:** Set CONSTRAINTS beside each CONSTRAINTS_LINE assignment (`missing`, `unreadable`, `ok`, `none-hard`), as POLICY is, and drop the parse; or, if kept, say at the line assignments that their first word after "constraints " is read as the value.

#### 3. loop_prompt takes half its inputs as arguments and half through globals dispatch rewrites

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1315` (STATUS[sha] rewrite), `:1300`/`:1304` (DIR rewrite), `:1322-1343` (loop_prompt)
**Move:** 3 (module boundary), 7 (coupling)
**Confidence:** High
**Legibility-target:** U3b/U4, which may want the prompt without a fresh status_fields run

Evidence (dispatch :1282-1318 and loop_prompt :1322-1343 read in full):
```bash
  [[ "$MODE" == prompt ]] || STATUS[sha]="$MAIN_SHA"
  printf 'ok %s %s %s\ndispatched %s\n' "$a" "$br" "$DIR" "$n"
  loop_prompt "$a" "$stem" "$ct" "$n"
```
```bash
loop_prompt() {
  local a="$1" s="$2" br="${STATUS[branch]}"
  [... heredoc reads $DIR, ${STATUS[sha]}, ${STATUS[policy]}, $MAIN_SHA; continues to :1343]
```

STATUS is documented (:631-640) as --status's fields "each the bare value as printed". After :1315 a --start run's STATUS[sha] no longer matches its STATUS[line] (`-`), and DIR, a parsed argument, is overwritten with the found or default worktree. The prompt builder therefore depends on dispatch having run status_fields and then mutated two globals in a particular order. It works for its one caller; it becomes a trap for a second (a re-print of the prompt, a test that calls loop_prompt, U4 wanting the text for a resumed loop).

**Recommendation:** Pass tip, worktree, branch and policy to loop_prompt as arguments (or a small PROMPT array), and leave STATUS and DIR as their documented values.

#### 4. The prompt restates rules the code owns, as hand-kept copies in the same file

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1326`, `:1328`, `:1338-1339` (prompt); `:1290` (cap), `:1268`/`:1277` (2 hours / 7200), `:629` and header `:78` (stop reason), lib `floor_why` (`scripts/lib/dev-cycle-read.sh:1975-1990`)
**Move:** 7 (coupling), 8 (extension points)
**Confidence:** High
**Legibility-target:** whoever changes the cap, the steal age, the marker grammar or the floor

Evidence:
```bash
  elif [[ "${STATUS[dispatched]}" -ge 4 ]]; then x="it was dispatched ${STATUS[dispatched]} times, and the cap is 4"
You are the build loop for $a (dispatch $4 of at most 4). [...line continues]
  [[ $(( $(date -u +%s) - l )) -gt 7200 ]] || { STEAL_WHY="its worktree $WT is locked, and its lock or tip is under 2 hours old"; return 1; }
- "handoff: stopped: REASON" (1 to 120 printable ASCII characters, no blank at either end), on a stop condition: [...]
  else echo 'bad its subject is not exactly "handoff: ready", "handoff: blocked" or "handoff: stopped: REASON" (REASON: 1 to 120 printable ASCII characters, no blank at either end)'; fi
```
and the floor sentence at :1328 ("instruction and prompt files and what they import, dot paths, the gate's own code, the user's and the cycle's records such as docs/constraints.md, docs/decisions/ and docs/thoughts/, and working docs or reviews not your own"), a hand summary of floor()'s words.

The cap is a literal 4 in three places, the steal age 2 hours/7200 in three, and the stop-reason rule in three, all in one file; the floor summary paraphrases the lib's floor_why list. The blocked-body grammar at :1338 has no enforcing code yet (fact-check claim 21c: unverifiable), so U3b's body parser must be written to match a sentence in a heredoc. Drift is likely to be silent: the prompt is not tested for the floor categories, and a changed cap would leave "of at most 4" true-looking. Within one script this is a Minor maintenance cost, not a boundary problem; the plan does list these items as prompt content, so the restatement itself is required, only its form is in question.

**Recommendation:** Name the cap and the steal age once (`DISPATCH_CAP=4`, `STEAL_AGE=7200`) and interpolate them; keep the stop-reason rule in one string used by marker_kind and loop_prompt; when U3b writes the blocked-body parser, have it own the grammar sentence and the prompt quote it. For the floor, a test asserting each floor_why category is named in the prompt is enough.

#### 5. dispatch reuses gate_start, which sets up a merge repository it never uses

**Severity:** Informational
**Location:** `scripts/build-loop.sh:994-1001` (gate_start), `:1378-1381`
**Move:** 2 (responsibility), 5 (segregation)
**Confidence:** High
**Legibility-target:** U3b, which adds more modes

Evidence (gate_start, in full):
```bash
gate_start() {
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
  store_check --main "$MAIN_SHA" \
    || { echo "refuse state objects: the default branch's commit or an object of its tree does not hash to its id, has a second copy in the object store, or could not be read"; exit 2; }
  reader_settings; read_settings; never_res; open_shared
}
```

Dispatch needs default_gate, GATE_TMP, store_check (it quotes `MAIN_SHA:docs/constraints.md`, whose objects store_check verifies) and read_settings. It does not use gate_repo (dispatch's git calls are plain `git`, not `gate_git`) or never_res. The reuse is fail-closed and matches the header's "after --check's state gate", so it is the right default; the cost is that gate_start is now three modes' startup with a name and comment that still read as --check/--merge's, and a dispatch can refuse with "its merge repository could not be set up".

**Recommendation:** None required now. When U3b adds modes, either split gate_repo out of gate_start or say in gate_start's comment which modes call it and why dispatch takes the whole of it.

#### 6. GATED is now a denylist: every new mode gets the state gate by default

**Severity:** Informational
**Location:** `scripts/build-loop.sh:465`
**Move:** 8 (extension points)
**Confidence:** High
**Legibility-target:** U3b (`--marker`, `--state`, `--main-log`, `--cycle-diff`)

Evidence:
```bash
GATED=""; [[ "$MODE" == settings || "$MODE" == status ]] || GATED=1  # a mode that decides (not the gate repository's GATE_*)
```

Flipping from "check or merge" to "not settings or status" makes the gate the default for modes not yet written, which fails closed and is the better extension point. It also changes what the comment means: U3b's read modes will be gated unless someone adds them to the exemption, and "a mode that decides" will no longer describe the set.

**Recommendation:** Keep it. When U3b adds read modes, decide each one explicitly and reword the comment to "every mode but the read modes listed".

#### 7. A refused add hides git's reason; the list-hidden cases surface only as "could not be added"

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1309-1311`
**Move:** 3 (module boundary: what the CLI contract tells its caller)
**Confidence:** High
**Legibility-target:** the orchestrator (U4 step 10) reading the refusal

Evidence:
```bash
    elif ! git worktree add -q --lock --reason "$reason" "$DIR" "$br" > "$GATE_TMP/add" 2>&1; then
      x="the worktree $DIR could not be added"
```
(excerpt of dispatch's else arm, which continues to :1312; read)

Following from finding 1: because wt_of trusts the list, the cases the list hides (a worktree rebasing or bisecting the branch) reach `worktree add`, which refuses correctly, but git's reason goes to `$GATE_TMP/add` and is deleted at exit. The orchestrator gets a refusal that names no cause.

**Recommendation:** Append git's first error line (scrubbed, as other refusals print repo text) to the refusal, or name the likely cause ("the branch may be in use by a rebase or bisect in another worktree").

## What Looks Good

- **The prompt lives in the script, as the plan's "Script interface → Prompt content" sets out, and that is the right home.** `scripts/build-loop.sh` matches GATE_CODE, so a loop cannot self-merge a prompt change, and D6 runs the script from main's commit, so the orchestrator never prints a checkout-edited prompt. U4's SKILL.md should invoke `--start`/`--prompt` and relay their output, not hold a second copy of the text.
- **Dispatch is a separate slice with the right dependency direction.** It consumes status_fields' values (row 496's arrangement) and read_settings, and adds nothing the existing modes depend on.
- **Each write sits at the end of its decision chain.** In dispatch's elif chain every refusal is decided before the first write, and the one compound write (update-ref then add) undoes only what it made (`update-ref ... ""` create-only). That keeps "leave nothing behind" a property of the structure, not of cleanup code.
- **wt_of is a small, documented reader** (its outputs named in its comment) that another mode could adopt as-is, which makes finding 1 cheap to act on.
- **The new suite file** keeps dispatch's fixtures (`ready`, `refused`, `none`, `lock`) local and reuses the shared `build-loop-fixtures` lib, matching the existing per-mode suites.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | wt_of and land carry two parsers of the same worktree list; row 663's trigger has fired | Minor | `scripts/build-loop.sh:1246-1262`, `:1160-1168` | High |
| 2 | CONSTRAINTS parsed back out of CONSTRAINTS_LINE's text | Minor | `scripts/build-loop.sh:597` | High |
| 3 | loop_prompt reads globals dispatch rewrites (STATUS[sha], DIR) | Minor | `scripts/build-loop.sh:1315`, `:1322-1343` | High |
| 4 | Prompt restates cap, steal age, marker and floor rules as hand copies | Minor | `scripts/build-loop.sh:1290`, `:1326-1339`, `:1277`, `:629` | High |
| 5 | gate_start reused by a mode that never uses its merge repository | Informational | `scripts/build-loop.sh:994-1001` | High |
| 6 | GATED became a denylist: new modes gated by default | Informational | `scripts/build-loop.sh:465` | High |
| 7 | A refused worktree add drops git's reason | Informational | `scripts/build-loop.sh:1309-1311` | High |

## Overall Assessment

The change keeps the script's structure intact: dispatch is a new slice that reads the existing value layers and writes only at the end of each decision path. There is no Structural or Coupling-tier issue. The main structural concern is finding 1. Row 663 set U3d as its revisit trigger, and U3d answered by writing a second reader of the worktree list rather than sharing one. The trust difference between the two readers is sound: land cross-checks git dirs because it moves main, and dispatch can lean on git's own refusal. That makes the split cheap: land should call wt_of for the list and keep its cross-check. Otherwise row 663 should be closed explicitly. Findings 2 to 4 are small fixes in place that keep the new code's contracts visible (a value set where it is decided, a prompt builder fed by arguments, named constants). The placement of the prompt in the script is correct and should hold through U4.

**Goal-Alignment Note:** The user's goal is to land U3d after a clean review-fix loop. None of these findings blocks that. All are Consider-tier (Minor/Informational), and none makes the honest dispatch path unsafe. Finding 1 is the one that a settled override row asks this unit to decide, so its disposition (share the reader, or close row 663 with a reason) should be recorded either way. Findings 2 to 4 are cheap and lower drift risk for U3b/U4. 5 to 7 can be deferred to U3b with revisit triggers.
