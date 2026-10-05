Commit: 2e711a7b

# Architecture Review — feat/build-loop-u1b (review-fix loop iteration 4, final confirming pass)

**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` at 2e711a7b: `scripts/build-loop.sh` (new, 195 lines), `test/lib/build-loop-fixtures.bash` (new), `test/scripts/build-loop-read.bats` (new), 417 lines in all. Enclosing context, unchanged by this unit: `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, and plan `docs/working/plan-build-loop-handoff.md` rev 4.
**Date:** 2026-10-05
**Based on:** the Stage-1 code-fact-check summary (k=3, `docs/reviews/code-fact-check-report-build-loop-u1b-r{1,2,3}.md`, all at Commit 2e711a7b), the iteration-4 fix diff (1d79ffef..2e711a7b), and the rows dated 2026-10-05 in `docs/reviews/override-log.md` (the settled filter).

Trigger categories: module structure applies (a new CLI module and a new test fixture library). Public APIs apply (the `--settings` three-line contract, and the globals `POLICY`, `NEVER` and `main_file` that U1c and U2 will consume). Data models apply (the settings line formats and `NEVER`'s shape). Cross-cutting concerns apply (the process-wide git environment: `GIT_LITERAL_PATHSPECS`, `GIT_NO_REPLACE_OBJECTS` and, new at this commit, a `GIT_CONFIG_COUNT` pair).

Trust-boundary cross-reference: the scan pattern `security-review-*.md` does not match this unit's security review. That tooling gap is settled as override row 234. The unit's own review, `docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1b.md`, is read anyway because its `B3` (git refs → `resolve_main`/`main_by_name`, `git cat-file` → `MAIN_SHA`) is where I1 below sits. That review predates 2e711a7b, so the boundary may be stale.

## Dependency Map

- `scripts/build-loop.sh` → `scripts/lib/dev-cycle-read.sh` is one way only. The lib is sourced from `$SCRIPT_DIR` (:47-50). The script consumes `scrub_reexec`, `resolve_main`, `main_by_name`, `MAIN_SHA`, `main_entry`, `FENCE_AWK` (and its awk globals), `oddwhy` and `NAMECHARS`. It gives the lib `ROOT_REAL` (:65) and, through the process environment exported at :69-70, `GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1` plus the config pair `core.useReplaceRefs=false`. Every git process that the lib or the script starts after :70 inherits all three.
- **Where the iteration-4 environment change does and does not reach (the question asked).** The export runs in the scrubbed child, because `scrub_reexec` (:51) re-execs the script before :69. So neither the outer scrub pipeline nor the caller (the orchestrator's shell) is changed: a process cannot write its parent's environment. Inside the child the export does reach every subprocess: git (intended), awk, perl and `env`, none of which read `GIT_CONFIG_*`. It will also reach whatever later modes start, including the plan's write modes (`--start`'s `git worktree add` and lock at plan :39, and the gate's merge). For those modes the setting is wanted too, since each one acts on main's own objects. The lib does not set or read these variables (grep: no `GIT_CONFIG` or `NO_REPLACE` in `scripts/lib/`).
- `scripts/dev-cycle.sh` → the same lib. It still exports only `GIT_LITERAL_PATHSPECS=1`. That difference between the two callers is settled by override row 259 (Defer to U3b). Its premise is unchanged at 2e711a7b.
- Inside the module, `read_settings` now reads the never line before the policy line (:148-171), and the policy arm reads `never_ok` (:176). The ordering is a local data dependency within one function, and the comment at :148 names it.
- `test/scripts/build-loop-read.bats` → `test/lib/build-loop-fixtures.bash` → `scripts/build-loop.sh` runs the script as a subprocess only. No test sources the script or the lib.

The direction is correct: a thin CLI depends on the stable shared reader. There is no cycle and no layer violation.

## Findings

#### I1. The replace-ref guard has become a two-mechanism inline line in the caller. When U3b moves it toward the lib (row 259), it should become one named lib function that states its caller-environment assumption, not a copied line.

**Severity:** Informational
**Location:** `scripts/build-loop.sh:66-70`. Related: `docs/working/plan-build-loop-handoff.md:78`; override row 259.
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence, `scripts/build-loop.sh:66-70` (excerpt ends :70; the module top level continues to `main_by_name` at :72, which was read):
```
# Read main's own objects: a replace ref could swap in any settings blob.
# core.useReplaceRefs in the repo's config would override the variable: add a
# command-line config pair after any the caller passed.
cfg="${GIT_CONFIG_COUNT:-0}"; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" "GIT_CONFIG_VALUE_$cfg=false" GIT_CONFIG_COUNT=$((cfg + 1))
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1
```
Plan :78, which covers the gate's own replace-ref handling:
```
  - It runs only after `GIT_NO_REPLACE_OBJECTS=1 git for-each-ref refs/replace/` prints nothing and `info/grafts` is absent (F38).
```

Iteration 4 put the guard at the right layer for this unit: the process boundary of the one script whose every mode reads main. It does not leak to callers, and it does not change the lib's code-level contract (see the Dependency Map). Three structural points remain for the next owner.

1. **It is no longer a one-line export.** "Ignore replace refs" now spans two cooperating mechanisms, the env var and an appended `GIT_CONFIG_COUNT` pair. The pair has arithmetic on a caller-supplied value. Row 259 defers a guard for dev-cycle.sh's lib readers to U3b. If that deferral is honoured by copying :69-70 into dev-cycle.sh or into the lib, the copy also carries the caller-environment cases that Stage 1 executed. In those cases `GIT_CONFIG_PARAMETERS`/`git -c` wins over the pair, and an octal or non-numeric `GIT_CONFIG_COUNT` misplaces the pair or aborts. Escalation E1 sends these to security-reviewer, and this review does not judge them.
2. **The plan has a second strategy for the same concern.** U3b's gate refuses replace refs before it reads (plan :78), while U1b ignores them. Both are reasonable. Once both exist, though, "which objects does build-loop.sh read" is answered in two places, with different failure shapes: refusing fails visibly, ignoring fails silently.
3. **The trust assumption is undeclared.** Nothing at the module boundary says whether the caller's git environment is trusted. The lib does state this for its own variable: "DEV_CYCLE_SCRUBBED ... an environment choice, not something repo text can do" (lib :73-74). The comment at :67-68 says "after any the caller passed", and Stage 1 found that false for `GIT_CONFIG_PARAMETERS`.

Row 259's premise (dev-cycle.sh's readers have no guard) still holds, so this finding does not re-raise it. It adds a "how" to that row's revisit, for when U3b acts.

**Recommendation:** No U1b code change is required on architecture grounds. When U3b acts on row 259, add a single lib function, for example `main_objects_only`, that both scripts call, holding the env var, the config pair and a one-line statement of whether the caller's environment is trusted. Have the gate's refusal (plan :78) sit beside it, so the two strategies are documented together. The comment wording at :67-68 is a fact-check/E1 matter, settled by whatever security-reviewer decides.

## Iteration-4 focus items (status at 2e711a7b)

- **The never_ok coupling between the never and policy readers is sound and correctly located.** `never_ok` now starts empty (:135) and is set only on the two valid arms, `none` (:172) and set (:173). The duplicate arm (:153), the malformed arms (:171), the no-line arm (:152) and the unread-file branch (:139-143) all leave it empty, so `POLICY=self-merge` (:181) implies an exact, single, valid never line. Stage 1 killed mutants that drop `never_ok=""` and set it on the duplicate arm. The cross-key decision has one home, in `read_settings`, and is published through `POLICY` (the effective policy). Consumers never re-derive it from `POLICY_LINE` text. The order dependency (never before policy) is local, and the comment at :148 names it. If U1c splits `read_settings` (iteration-3 I2, row 262), the never reader must stay ahead of the policy decision. The present comment carries that requirement. Iteration-3 I1 (an empty `NEVER` is ambiguous) is settled by row 260, and Q-112 has now made its premise true by construction: under self-merge, an empty `NEVER` means "none". There is no finding.
- **The GIT_CONFIG_COUNT mutation at module top level does not leak to callers, and the layer is right for this unit.** See the Dependency Map. It reaches the lib's git calls (intended) and all later modes' subprocesses (also wanted, since they act on main). The residual concerns, which are reuse shape, the two strategies and the trust statement, are I1 above.
- **Help printing is fixed, and row 239's premise has changed.** `sed -n '2,/^[^#]/{/^#/p}'` (:57) prints the header up to `set -euo pipefail`. Executed: 37 lines, ending at "or no default branch found by name." It no longer goes stale when the header grows. dev-cycle.sh:112 now uses the same idiom, so the two CLIs share one help convention. That is two copies of a one-liner, and it does not warrant a lib helper. Override row 239 ("--help prints a fixed line range", Won't-Fix) is now stale because the issue is resolved, as fact-check r3 also noted. The orchestrator may annotate the row. This review raises no finding. The `-h` test gap stays settled under row 249.

## Iteration-3 items in my domain

- M1 (replace guard in one caller) is settled as row 259 (Defer to U3b), and its premise is unchanged. I1 above adds the shape the deferred fix should take.
- I1 (NEVER ambiguity) is settled as row 260, and Q-112 makes it hold by construction.
- I2 (U1c's constraints as its own reader) is settled as row 262 (Defer to U1c).
- I3 (plan :74 "pathform globs") is settled as row 261 (Defer to U5).

## What Looks Good

- **The fail-closed cross-key rule is in one place.** Self-merge requires a valid never line. That is decided once, in the reader, and exposed as `POLICY`. Neither U1c's `--status` nor U2's gate has to reconstruct it.
- **Process-boundary placement of the git environment.** The guard runs after `scrub_reexec` and before any lib read, so it covers every lib call in this script without the lib knowing about it, and it cannot affect the caller.
- **The one-way dependency and self-contained sourcing are intact.** The planted-lib test still guards them.
- **`main_file` stays a generic seam** (`FILE_OUT`/`FILE_WHY`), ready for U1c's constraints reader.
- **Read and print stay separate.** `read_settings` only sets globals, and the mode arm prints them.
- **The fixture library is a clean seam for the `build-loop-*.bats` family.** Tests reach the module only through its CLI.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| I1 | The replace-ref guard is now env var plus config pair with caller-value arithmetic, inline in the caller. When row 259's U3b revisit acts, make it one lib function stating the caller-env trust assumption, beside the gate's refuse-replace-refs check (plan :78), not a copied line | Informational | `scripts/build-loop.sh:66-70` | Medium |

## Overall Assessment

At 2e711a7b, U1b keeps the system's structure sound, and iteration 4 adds no Structural, Coupling or Minor findings. The `never_ok` coupling ties the two keys through one local variable, in a fixed order inside one function, and publishes the result as `POLICY`. That is the right place for a fail-closed cross-key rule. The `GIT_CONFIG_COUNT` mutation is confined to the scrubbed child process, so it cannot leak to callers. It applies to every git read in the script, which is the intended scope. The help fix removes the stale-range problem from both CLIs. The single structural note, I1, concerns the future: the replace-ref guard has grown into two mechanisms that read caller-supplied values. When row 259's deferral is acted on, it should become one named lib function with a stated trust assumption rather than a copied line. Whether the caller-environment bypasses matter now is E1, owned by security-reviewer.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "A report saved at the output path named in your tail, structured per your skill, covering the full unit diff at 2e711a7b."
- **Answered:** Yes. The report is saved at `docs/reviews/architecture-review-review-2026-10-05-build-loop-u1b.md` with `Commit: 2e711a7b`. It covers all three code files in the unit diff (Dependency Map, I1, the focus items, What Looks Good), with emphasis on the three iteration-4 focus areas: the never_ok coupling, the GIT_CONFIG_COUNT mutation and help printing. The finding carries Severity, Location, verbatim Evidence (with a truncation marker), Confidence and a Legibility-target. The settled rows (234, 238, 239, 241, 242, 243, 249, 256, 259, 260, 261, 262, 263, and Q-112/Q-113) are respected. Row 259's premise is unchanged. Row 239's premise has changed, and the issue is resolved, not re-raised.
- **Out of scope:** Several items belong to security-reviewer (E1) and api-consistency (E2): whether the caller's environment is trusted; the `GIT_CONFIG_PARAMETERS`, octal and invalid `GIT_CONFIG_COUNT` cases; and the comment wording at :67-68 and the "Not inside a git repository" message. Comment-accuracy residues (:16-17, :99-100) belong to fact-check.
- **Escalate:** I1 goes to the orchestrator as an input for U3b's row-259 revisit. It is not a U1b blocker.
- **Questions / Decisions:** None for U1b.
