Commit: 722884c7

# Architecture Review — feat/build-loop-u1a (review-fix iteration 3, final confirming pass)

**Scope:** `git diff main...feat/build-loop-u1a -- . ':!docs/reviews'` (d6426e3e, c8435580, 2da477b7, 78703f22, 722884c7) over `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`, `test/scripts/dev-cycle.bats`; enclosing units `main_entry` (:258-274), `brief_fields` (:289-310), `check_brief` (:319-358), `check_answer` (:545-573) and the lib header (:1-32) read whole at 722884c7.
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check (k=3, replicates `docs/reviews/code-fact-check-report-build-loop-u1a-r1/-r2/-r3.md`, all Commit 722884c7); plan `docs/working/plan-build-loop-handoff.md` rev 4 (D8, Approach, Script interface, step 3); override-log rows dated 2026-10-05 (`docs/reviews/override-log.md:196-231`).

**Scope check:** in scope. Public APIs: lib functions `main_entry` and `brief_fields`, globals `BRIEF` / `BRIEF_ODD`, `check_answer`'s input moved from the working tree to main's commit. Data models: `main_entry`'s word protocol (`blob|absent|notfile|notdir PART|error`) and `BRIEF_ODD`'s (`odd N WHY|unbalanced N|error`), which U1b/U1c consumers (`--settings`, `--status`, later `--start`/`--prompt`/`--approved`) code against.

**Trust-boundary cross-reference:** active. The skill's glob `docs/reviews/security-review-*.md` misses this initiative's file (settled tooling gap, override row :231 / C10). I used the boundary map of `docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1a.md` as committed at 78703f22 (Commit: `2da477b7` — security review predates this diff's HEAD; boundary may be stale; the file is being rewritten concurrently). Relevant labels: `B2 (new): [tree entries under MAIN_SHA] → [main_entry] → [verdict]`, `B3 (moved): [blob bytes at MAIN_SHA:path] → [git cat-file | FENCE_AWK (+ANSWER_AWK)] → [BRIEF[...] / check_answer result line]`, `B5 (new): [git process exit status / object-store integrity] → [$(...) assignment under the caller's set -e/pipefail] → [caller's skip-or-answer decision]`.

**Settled, not re-raised:** C3 (row :225, main_entry case block copied per caller), C4 (row :226, BRIEF whole lines in one global), C5 (row :227, reader on main while the skill writes the working tree until U4), row :223 (questions.sh NUL divergence, my iteration-2 F5), C10 (row :231, security glob), row :215 (guards' three channels, U3). No revisit trigger has fired: no U1c/U2/U4 code is in this diff.

## Iteration-2 F1 status (A13: brief_fields preconditions + signal)

**Fixed at 722884c7, confirmed by execution** (scratch repo, `set -euo pipefail`, lib sourced from the worktree). `brief_fields` now runs `pathform` and `main_entry` itself (`:292`, which also covers `main_by_name` through `main_entry`'s first line `:261`) and turns a failed read into `BRIEF_ODD=error; return 1` (`:302`). Probe output, each call inside `if brief_fields …`:

```
before-resolve rc1 keys=0 odd=[error]
absent rc1 keys=0 odd=[error]
symlink rc1 keys=0 odd=[error]
badform rc1 keys=0 odd=[error]
good rc0 keys=2 odd=[]
deleted-blob rc1 keys=0 odd=[error]
bare call rc=1 odd=[error]
empty-sha rc1 keys=0 odd=[error]
```

The iteration-2 probe that printed `rc0 keys=0 odd=[]` for a path not on main now prints `rc1 … odd=[error]`; the bare call no longer kills the shell with git's 128; empty `MAIN_SHA` (the index-read case in A13) is refused. `check_brief` maps `BRIEF_ODD` in one case block (`:338-345`). The one residue is the pipefail dependency below (Finding 1), which is a property of the caller contract, not of the F1 fix.

Suite: `bats test/scripts/dev-cycle.bats` with `TMPDIR` set to my scratch dir: 66/67, only test 21 failing (the orchestrator's known `.`-leading-TMPDIR artefact, not a finding).

## Dependency Map

- `scripts/dev-cycle.sh` → sources `scripts/lib/dev-cycle-read.sh` from its own `SCRIPT_DIR` (unchanged direction). Its change: `--check-answer` joins `--check-brief`/`--check-branch` behind the `main_by_name` gate (`scripts/dev-cycle.sh:192`).
- Inside the lib, one layer sits between git and every main-reading check:
  - `main_entry` → `main_by_name`, `MAIN_SHA`, one `git ls-tree -t --full-tree`.
  - `brief_fields` → `pathform`, `main_entry`, `git cat-file`, `FENCE_AWK`; writes `BRIEF`, `BRIEF_ODD`.
  - `check_brief` → `need_root`, `main_by_name`, `pathform`, `isbrief`, `blocker` (working tree), `main_entry`, `brief_fields`, `git log`.
  - `check_answer` → `main_by_name`, `main_entry`, `git cat-file`, `FENCE_AWK + ANSWER_AWK`; no longer `need_root`/`skipped`/`SKIPPED`/`ROOT_REAL`.
- Planned consumers (U1b/U1c/U3, not in this diff; absence not flagged): build-loop.sh calls `main_entry`, `brief_fields`, `check_brief`, `check_answer` in-process (plan :194).
- Direction is sound: entry scripts depend on the lib; the lib depends only on git, awk and the caller's shell options; no lib function depends on a caller; no cycle.

## Findings

#### 1. The lib's failed-read signal still depends on the caller's `pipefail`, now the only precondition `brief_fields` does not check itself

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:295-302` (brief_fields; excerpt ends :302, enclosing `brief_fields()` continues to :310 — read), `:559-560` (check_answer; enclosing `check_answer()` continues to :573 — read); contract stated at `:13`
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
  out="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'
...
    || { BRIEF_ODD=error; return 1; }
```
```
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
      || { echo "skip $a: $f could not be read from the default branch"; return; }
```
```
# caller sets -euo pipefail,
```

F1's fix moved every other precondition (`main_by_name`, `pathform`, `main_entry == blob`) inside `brief_fields`, so its safety no longer lives in its callers, except this one: the `||` arms fire only when the pipeline's status is `cat-file`'s, which requires `pipefail` in the shell that calls the function. Probe, same deleted-blob repo, `set -eu` without pipefail: `if brief_fields …` printed `nopipefail rc0 keys=0 odd=[]` — the iteration-2 symptom (a missing brief reads as "no machine lines"). Stage-1 replicates found the same for `check_answer` (`keep Q-1` on a deleted questions.md blob). The header states the contract and dev-cycle.sh honours it (`set -euo pipefail`), so nothing ships broken; the structural point is that this sits on `B5` from `docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1a.md` (Commit: `2da477b7` — security review predates this diff; boundary may be stale), whose transition point is literally "the caller's set -e/pipefail", and U1b/U1c add callers (build-loop.sh, its bats tests that source the lib with ad-hoc `bash -c` preambles) that each have to get it right. Not a merge blocker for U1a.

**Recommendation:** Make the two readers self-sufficient with a function-scoped option: `local -; set -o pipefail` as the first line of `brief_fields` and `check_answer` (bash ≥ 4.4; probed on 5.2: the option is caught inside and restored for the caller). Alternatively, leave it and have U1b's first build-loop.sh test source the lib under `set -eu` only and assert the skip. Either can land with U1b.
**Security implication:** this moves `B5`'s enforcement point from the caller's shell options into the lib; it does not relocate the boundary's source or destination. Defer the choice to security-reviewer if it prefers the caller-side contract.

#### 2. `brief_fields`' single `error` word folds absent, not-a-file and unreadable together, so a consumer that needs "new" or a reason still calls `main_entry` first

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:292`; caller pattern at `:330-338`
**Move:** 3 (module boundary — data shape)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
```
```
  e="$(main_entry "$a")"
  case "$e" in
    absent) echo "ok $a new"; return ;;
```

The fix took the narrower form of my iteration-2 recommendation (one `error` word rather than passing `main_entry`'s answer through). That is safe — every non-blob outcome refuses — and it keeps `BRIEF_ODD`'s vocabulary at three words. The cost is that a consumer which must distinguish "brief not on main yet" (`--status`'s `new` state, `--start`'s "open on main") or name *why* it was refused calls `main_entry` before `brief_fields`, as `check_brief` does, and the path is classified twice (two `ls-tree` processes per brief; cost owned by rows :220/:229). This is a contract note for U1c, not a defect: consumers that route through `check_brief` inherit the distinction for free.

**Recommendation:** None for U1a. If U1c's `--start`/`--status` call `brief_fields` directly and need the reason, pass `main_entry`'s word through as `BRIEF_ODD="entry WORD"` then; otherwise keep the three-word vocabulary.

## What Looks Good

Positive assertions below are submitted as claims for code-fact-check, not self-certified.

- `brief_fields` now owns its preconditions and gives every non-success outcome a return-1 signal with a `BRIEF_ODD` word, so U1b consumers call one function rather than copying `check_brief`'s guard block (iteration-2 F1 / A13 resolved). `route: code-fact-check` — `scripts/lib/dev-cycle-read.sh:289-310`.
- `main_entry` treats a tree listing a name twice as `error` rather than picking one copy (A12), keeping "what the check saw" and "what git reads" from diverging behind the B2 boundary. `route: code-fact-check` — `scripts/lib/dev-cycle-read.sh:264-269`.
- `check_answer`'s failed read is a skip, not a fall-through to the archive (R2), so the two-file search can no longer answer from the wrong file. `route: code-fact-check` — `scripts/lib/dev-cycle-read.sh:558-560`.
- One brief parser: `check_brief` reads Status through `brief_fields`, and the template test pins both to the same answer (T31). `route: code-fact-check` — `scripts/lib/dev-cycle-read.sh:338-349`; `test/scripts/dev-cycle.bats` "a brief shaped like the skill's template parses".
- `check_answer` shed `need_root`/`skipped`/`SKIPPED`, discharging rows :206, :216, :217. `route: code-fact-check` — `scripts/lib/dev-cycle-read.sh:539-573`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Failed-read signal of `brief_fields`/`check_answer` depends on caller's `pipefail` (B5) | Minor | `scripts/lib/dev-cycle-read.sh:295-302`, `:559-560` | High |
| 2 | `brief_fields`' `error` folds absent/notfile/unreadable; "new" needs a prior `main_entry` | Informational | `scripts/lib/dev-cycle-read.sh:292`, `:330-338` | High |

## Overall Assessment

The change maintains and improves the lib's structure: dependency direction is correct, `check_answer` sheds its working-tree dependencies, and `main_entry`/`brief_fields` form one layer between git and every main-reading check, with one brief parser. Iteration-2's only Coupling finding (F1/A13) is fixed and confirmed by execution. No Structural or Coupling finding remains; the two new items are Minor/Informational (rubric 🟢 Consider) and both are contract notes for U1b/U1c rather than defects in U1a. Architecturally, the branch is clean to merge; the most useful follow-up is making the readers' failed-read signal independent of the caller's `pipefail` (Finding 1) before build-loop.sh adds callers. No disagreement with the security review's boundary placement.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u1a/docs/reviews/architecture-review-review-2026-10-05-build-loop-u1a.md (overwrite the iteration-2 one), first line `Commit: 722884c7`, structured per the architecture-review skill, every finding with Severity, Location, verbatim Evidence, Confidence and Legibility-target, ending with the canonical Goal-Alignment Note.
- Answered: architecture review of `main...feat/build-loop-u1a` at 722884c7 (scope check in scope; dependency map; 2 findings: 1 Minor, 1 Informational; no Structural/Coupling); iteration-2 F1 confirmed fixed by an executed probe; positive claims routed to code-fact-check; bats 66/67 with only the known test 21.
- Out of scope: the `--help` range regression (`scripts/dev-cycle.sh:111`, fact-check Incorrect, owned by the orchestrator's must-fix list, not structural); SKILL.md wording residue (fact-check Mostly accurate); settled rows :215, :220, :223, :225-:231; U1b/U1c consumers' absence.
- Escalate: Finding 1 to the orchestrator and security-reviewer as a B5 enforcement-point choice (lib-local `local -; set -o pipefail` vs the caller contract), non-blocking for U1a; Finding 2 to the U1c brief as a contract note.
