Commit: 65007bf8

# Architecture Review — feat/build-loop-u3a1 (iteration 1)

**Scope:** `git diff main...HEAD` (base d5736445): `scripts/build-loop.sh` and `test/scripts/build-loop-check.bats`. I also read the unchanged lib, `scripts/lib/dev-cycle-read.sh` (brief_fields, open_shared, check_brief, check_branch, resolve_main), and plan step 7's U3 split note (`docs/working/plan-build-loop-handoff.md:316-320`).
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u3a1.md` (k=1: 0 Incorrect; Claims 9 and 15 Mostly accurate; Claims 12 and 16 Stale)
**Severity → rubric tier:** Structural → 🔴 Must Fix · Coupling → 🟡 Must Address · Minor and Informational → 🟢 Consider

**Scope check:** The diff is in scope on three of the four trigger categories:
- **Cross-cutting.** The startup order and configuration loading move into `gate_start`.
- **Data model.** `STATUS` is a new values contract that U3a2's `--merge` will read.
- **Public surface.** The CLI gains two refusal lines and loses two.

**Trust-boundary cross-reference:** I scanned `docs/reviews/security-review-*.md`. The newest build-loop review is `security-review-2026-10-10-u2c2-final.md` (Commit: `8786f8fc`). Its map is used once, in Finding 4. No security review exists yet for this diff, so the map predates it and its boundaries may be stale.

## Dependency Map

- `build-loop.sh` sources the lib. The direction is one-way: the script depends on the lib, and the lib never calls into the script.
- New in this diff:
  - `status_fields` → lib (`open_shared`, `check_brief`, `brief_fields`, `check_branch`) + `marker_kind`. It is now the only parser of `check_brief`'s and `check_branch`'s printed lines.
  - `status_line` → `status_fields`. It is a one-line printer.
  - `store_check` → `git` only. It reads no globals; its inputs are its arguments and the repository's object format.
  - `gate_start` → `default_gate`, `gate_repo`, `store_check`, then the settings and open-briefs readers: `reader_settings` (lib), `read_settings`, `never_res`, `open_shared` (lib).
  - `check_line` → `status_fields` (values from `STATUS`), `merge_result`/`gate_git`, `store_check`, `checkout_gate`, `read_paths`. `read_paths` reads the lib global `BRIEF` that `status_fields` left behind.
- The top level still runs `state_gate`, `resolve_main` and `main_by_name`, and gates `reader_settings` on `MODE`. The check arm runs `gate_start`, then calls `check_line` once per brief and reads each verdict from its printed first line.

## Findings

#### 1. The gate's startup is still split between the top level and gate_start, behind two mode tests a new gated mode must both edit

**Severity:** Minor
**Location:** `scripts/build-loop.sh:336`, `:343`, `:818-824`, `:913-914`
**Move:** 8 (extension points), 7 (coupling)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:336-343
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }
...
# gate_start calls it once main's objects are checked.
[[ "$MODE" == check ]] || reader_settings
```
```bash
# scripts/build-loop.sh:806-808 (gate_start's comment opens)
# The gate's startup once the top level has run state_gate, resolve_main and
# main_by_name, in this order, each refusal a "refuse state" line and exit 2
# before any setting or brief is read: ...
```

Row 525 asked for "one startup function". `gate_start` holds the second half of the startup. The first half is still two `MODE == check` tests at the top level, and `gate_start`'s comment depends on them having run. U3a2's `--merge` is the next gated mode, so it has to edit three places: line 336, line 343 and the case arm.

The line-343 test is negative (`check || reader_settings`). If a new gated mode is added at line 336 and in the case arm but missed at line 343, it fails open: `reader_settings` reads main's settings blob before `store_check` has re-hashed it. Nothing would catch that:
- The new test's forged-brief case asserts only the output, and an early settings read prints nothing.
- The A15 call-log test (`build-loop-check.bats:1914`) pins `state_gate` before `resolve_main`. It does not pin main's blob reads after `store_check`.

The direct harm is small, because `store_check` still refuses before any verdict. The cost is that the help text's ordering claim ("before the settings or any brief is read") can silently stop being true.

**Recommendation:**
- Set one flag at argument parsing, e.g. `GATED=1` for `check` (and `merge`). Use it at both top-level sites, or move the gated branch whole into `gate_start` (state_gate → resolve_main → main_by_name → …) with an `else` arm for `--status`/`--settings`.
- Extend the A15 call log to assert that the first `cat-file blob <main>:` follows `store_check`'s `cat-file --batch`.

#### 2. Row 512's half (TIP, TREE and the verdict as values) is not done; plan step 7 puts it in U3a1, and the code cites row 512 as if it were

**Severity:** Minor
**Location:** `scripts/build-loop.sh:499-500`, `:891`, `:900-901`, `:919-920`; `docs/working/plan-build-loop-handoff.md:317`
**Move:** 3 (module boundary), 7 (coupling)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:499-500
# --status for one brief, as values (rows 496, 512): STATUS[line] is the line
# --status prints, and for an "ok" line STATUS holds its fields by name
```
```bash
# scripts/build-loop.sh:919-920
      check_line "$a" > "$GATE_TMP/line"; cat "$GATE_TMP/line"
      [[ "$(head -c 3 "$GATE_TMP/line")" == "ok " ]] || fails=1
```
```text
plan-build-loop-handoff.md:317 (U3a1): "... Also check_line's values (rows 496, 512, 613, 525's startup function): status fields as an array, and the collect / judge steps returning TIP, TREE and the verdict as values for `--merge`."
```
The commit body says: "Verdict values for --merge wait for U3a2, their first reader."

Row 496 (status fields as values) is done. Row 512 is not: `check_line` still returns printed text only, and its one caller reads the verdict from the first three bytes. `--merge` needs TIP and TREE. If U3a2 reuses `check_line` as it stands, the easiest path is to split `"ok BRIEF TIP TREE"` by position, which is the field-position coupling row 496 just removed.

Deferring to the first reader is defensible, and row 512's own trigger is "U3's `--merge`". But two things now disagree with the code:
- The plan's U3a1 bullet assigns this work to U3a1.
- The `status_fields` comment cites row 512.

U3a2 also inherits the line cost under plan step 5's 400-line cap.

**Recommendation:**
- Change the comment's citation to row 496 only.
- Record the move in plan step 7: drop "the collect / judge steps returning TIP, TREE and the verdict" from U3a1 and add it to U3a2.
- For U3a2, mirror `STATUS`: `check_line` sets `CHECK=([verdict]=ok|refuse|skip [tip]=… [tree]=… [line]=…)` beside what it prints, and the check arm and `--merge` read `CHECK[verdict]`, not `head -c 3`.

#### 3. STATUS carries the printed format: ok vs skip is known only from the line's prefix, and absent values are "-"

**Severity:** Minor
**Location:** `scripts/build-loop.sh:511`, `:514`, `:546-547`, `:844`
**Move:** 3 (module boundary), 7 (stamp vs content coupling)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:511
  [[ "$out" == "ok "* ]] || { STATUS[line]="$out"; return; }
# scripts/build-loop.sh:514
    STATUS=([line]="ok $a new review - absent - - 0" [state]=new [policy]=review [branch]=- [loop]=absent [sha]=- [ahead]=0 [date]=- [dispatched]=0 [reason]="")
# scripts/build-loop.sh:844 (check_line; continues to :902)
  [[ "${STATUS[line]}" == "ok "* ]] || { echo "${STATUS[line]}"; return; }
```

`STATUS` is the values seam for U3a2's `--merge` (row 512), U3b's `--state` and U3d's dispatch, which reads `dispatched`. Two parts of the printed format leak into it:
- **Which keys exist.** The only signal is the rendered line's first word. A skip sets `[line]` alone, so under `set -u` every consumer must test `STATUS[line]`'s prefix before it can touch any other key.
- **Absent values.** The `--status` placeholder `-` stands for "none" in `branch`, `sha` and `date`.

Each new consumer re-learns both rules from the line format, so changing the printed line changes what the values mean.

**Recommendation:** Add a `STATUS[result]` key (`ok` or `skip`) and test it in `check_line`. Either store absent values as empty strings and print them as `-` in the line, or state in the comment at `:499-504` that `-` means none.

#### 4. BRIEF is an undeclared second output of status_fields, and it holds the previous brief's fields on two return paths

**Severity:** Minor
**Location:** `scripts/build-loop.sh:502-503`, `:506-515`, `:843`, `:890`; `scripts/lib/dev-cycle-read.sh:390`, `:505`
**Move:** 7 (coupling: temporal, through a global), 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:502-503
# branch's commit count past main. brief_fields' BRIEF is the brief as read
# here (check_line takes Paths: from it, so no second read). Call it in the
# scripts/build-loop.sh:508-515
  STATUS=()
  open_shared
  out="$(check_brief "$a")"
  [[ "$out" == "ok "* ]] || { STATUS[line]="$out"; return; }
  read -r _ _ st _ <<<"$out"
  if [[ "$st" == new ]]; then
    STATUS=([line]="ok $a new review - absent - - 0" ...)
    return
# scripts/build-loop.sh:890
  [[ "$pol" != self-merge ]] || read_paths
# scripts/lib/dev-cycle-read.sh:505
  local -A count=() BRIEF=()  # a local BRIEF: the caller's stays as it was
```

`status_fields` resets `STATUS`, but `BRIEF` is set only by `brief_fields`. On the `new` path and on a non-ok `check_brief` line, `BRIEF` still holds the previous brief's fields. The comment at :502 says "BRIEF is the brief as read here" without that condition. This sits against `check_line`'s inventory, "Nothing … may carry from one brief to the next" (:834).

Today nothing reads it: `check_line` refuses a non-open brief before `read_paths` (fact-check Claims 8 and 18). But Paths: now reaches `read_paths` 47 lines later through a lib global. The step that used to re-read it is gone. Every step in between (merge_result, store_check, checkout_gate, and U3a2's CAS and state-gate re-run) must keep from calling `brief_fields`, a rule stated only in a comment. `open_shared`'s local `BRIEF` shows the hazard has already been met once.

**Trust boundary:** The Paths: allowlist feeds `srules`, which lies on `B1` from `docs/reviews/security-review-2026-10-10-u2c2-final.md` (Commit: `8786f8fc`). That security review predates this diff, so the boundary may be stale. The recommendation below does not move that crossing.

**Recommendation:** Reset `BRIEF=()` (and `BRIEF_ODD`) beside `STATUS=()` so the comment holds on every path. Better, copy the one field `check_line` needs into the values seam (`STATUS[paths]`, set when present), so `check_line` and U3a2 read `STATUS` alone and never the lib's `BRIEF`.

#### 5. The repository rule, newly stated once, does not place its first new member (store_check)

**Severity:** Minor
**Location:** `scripts/build-loop.sh:815-817`, `:594-610`, `:879`
**Move:** 4 (layering: real repository vs gate repository)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:815-817
# in this shell). The repository rule: main's files and refs, the branch tips
# and the checkout are read in the real repository; the merge computations
# (merge-base, merge-tree, diff-tree, the blob checks) run through gate_git.
# scripts/build-loop.sh:879
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of $br's tip or of its merge does not hash to its id, or could not be read"; return; fi
```

Row 525 asked for this rule to be stated once so that later code can be placed by it. The first function added under it, `store_check`, reads merge-tree's result `TREE` with bare `git` in the real repository. The rule assigns merge objects to `gate_git`. This is fact-check Claim 15.

Running it there does no harm: `cat-file --batch` applies no filter, and both repositories share one object directory. But the rule no longer answers the question it exists for. U3a2 will add `commit-tree`, `update-ref` and `merge --ff-only`, each of which must be placed by this rule.

**Recommendation:** Add a clause such as: "store_check's re-hash (main's tree, the tip, TREE) reads objects only, in the real repository: cat-file --batch applies no filter". While editing, fix the two stale `status_line` mentions (`:628`, `:830`; fact-check Claims 12 and 16).

#### 6. store_check's placement in build-loop.sh rather than the lib

**Severity:** Informational
**Location:** `scripts/build-loop.sh:585-610`
**Move:** 2 (responsibility), 1 (dependency direction)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```bash
# scripts/build-loop.sh:594-597 (store_check opens; continues to :610)
store_check() {
  local r alg
  case "$(git rev-parse --show-object-format)" in sha1) alg=1 ;; sha256) alg=256 ;; *) return 1 ;; esac
  # One object name per line, each once.
```

Leaving it in the script is right for now:
- Every caller is in `build-loop.sh` (`gate_start`, `check_line`, and soon `--merge` and `--state`).
- It reads no script global, so moving it later is a cut-and-paste.

**Trigger to move it:** `dev-cycle.sh`'s digest becomes gate code (U3b's D6). That is the same trigger as the deferred `git_harden` row ("Hardening lives in build-loop.sh, the lib … and the state gate", Coupling, Defer). Move it then, together with `git_harden`, so that hardening and integrity checks live in one place.

## What Looks Good

- **One parser.** The field-position parse of `check_brief`'s and `check_branch`'s lines now lives only in `status_fields`. `check_line` reads named values (`:845`), which closes row 496's coupling for `check_line`. `status_line` is a one-line printer over the values, so `--status` and `--check` cannot drift; the fact-check's 14-brief differential confirms byte-identical lines.
- **One snapshot per decision.** `check_line` decides on the `sha` that `status_fields` read and drops the branch and brief re-reads. That removes two untested refusal arms (row 625) and the `PATHS_WHY=unread` special case in `srules`, so the verdict chain gets shorter, not longer (row 613).
- **`store_check` is a clean primitive.** It takes `REV...` arguments, reads no globals and returns 0 or 1, and both call sites wrap it in their own refusal wording. Re-hashing whole trees once, rather than adding a check at each read, keeps the integrity concern out of the walk and reader code. This matches the plan's U3a1 rationale.
- **`gate_start` gathers the check-mode startup:**
  - the refusals in one order;
  - the `GATE_TMP` trap;
  - settings read once, after `store_check`.

  It also removes the old exception where "refuse state gate" came after the settings were read.
- **`STATUS` is declared next to its producer and listed in `check_line`'s global inventory.** This follows the existing `LIST`/`PATHS` convention.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Startup split between top level and gate_start; two mode tests, one fail-open | Minor | `scripts/build-loop.sh:336,343,818-824` | Medium |
| 2 | Row 512's TIP/TREE/verdict values not done; plan places them in U3a1; comment cites 512 | Minor | `scripts/build-loop.sh:499,919-920`; plan `:317` | High |
| 3 | STATUS carries the printed format (ok from line prefix, "-" sentinels) | Minor | `scripts/build-loop.sh:511,514,844` | High |
| 4 | BRIEF an undeclared second output, stale on the new and non-ok paths | Minor | `scripts/build-loop.sh:502-515,890` | High |
| 5 | Repository rule omits store_check's real-repo reads | Minor | `scripts/build-loop.sh:815-817,879` | High |
| 6 | store_check placement: keep it here; move it with git_harden at U3b's D6 | Informational | `scripts/build-loop.sh:585-610` | Medium |

## Overall Assessment

The change improves the structure:
- Values replace field-position parsing.
- One snapshot replaces two re-reads.
- The integrity check is a self-contained primitive.
- The startup has a named home.

Nothing is Structural or Coupling. All five Minor findings can be fixed in place in a few lines each. The most important concern is the seam U3a2 depends on.

`STATUS` is values-shaped but still keyed off its printed line (Finding 3). It leaves Paths: in a lib global (Finding 4). And `check_line`'s own verdict is still text only (Finding 2). If U3a2 builds `--merge` on that seam as it stands, the cheapest path re-parses printed lines, which is the coupling row 496 removed.

A `[result]` key, `Paths:` in `STATUS`, and a plan note moving row 512's half to U3a2 would let U3a2 add `CHECK` the same way `STATUS` was added.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill.
- Answered: yes. All five focus areas are covered: the STATUS seam (Findings 3 and 4), gate_start (Finding 1), store_check placement (Finding 6), the top-level split (Finding 1), and global state between briefs (Finding 4); U3a2's needs are covered in Finding 2.
- Out of scope: correctness and coverage of store_check (fact-check Claims 9-11; security lane), its per-brief cost of re-hashing main's shared objects through the tip's tree (performance lane), and the CLI refusal wording (API-consistency lane).
- Escalate: Finding 2 needs a plan-step-7 edit (move "TIP, TREE and the verdict as values" from U3a1 to U3a2) or the code, either one; the orchestrator should pick which.
- Decisions I made: I rated Finding 1 Minor rather than Coupling because the fail-open still refuses before any verdict; the alternative was Coupling, on the change-propagation cost to U3a2. I rated Finding 2 Minor rather than Coupling because row 512's trigger (`--merge`) has not fired yet; the alternative was to treat the plan's U3a1 assignment as binding.
