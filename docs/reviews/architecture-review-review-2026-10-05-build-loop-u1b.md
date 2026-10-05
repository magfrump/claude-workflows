Commit: 1d79ffef

# Architecture Review — feat/build-loop-u1b (review-fix loop iteration 3, final)

**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` (merge-base 722884c7): `scripts/build-loop.sh` (new, 186 lines), `test/lib/build-loop-fixtures.bash` (new), `test/scripts/build-loop-read.bats` (new); enclosing context `scripts/lib/dev-cycle-read.sh` and `scripts/dev-cycle.sh` at HEAD (unchanged by this unit)
**Date:** 2026-10-05
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u1b.md` (Stage 1, k=3 merged, at 1d79ffef); plan `docs/working/plan-build-loop-handoff.md` rev 4 ("Script interface", D5); `docs/reviews/override-log.md` rows dated 2026-10-05

Trigger categories: module structure (yes: a new script module and a new test fixture library), public APIs (yes: the `--settings` output contract and the globals `POLICY`, `NEVER` and `main_file` that U1c/U2 consume), data models (yes: the three-line settings format and `NEVER`'s shape), cross-cutting concerns (yes, newly at this commit: `GIT_NO_REPLACE_OBJECTS=1` is a process-wide git setting that governs how the shared lib reads main).

Trust-boundary cross-reference: the scan pattern `security-review-*.md` matches only older files; the newest by date, `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`), predates this diff, so its boundaries may be stale. This unit's own security review is `docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1b.md` (Commit: `0ae7d801`). It falls outside the scan pattern (a known tooling gap, settled as override row 234), but it is read here because its `B3` (`[git refs: origin/HEAD symref, refs/heads/*, refs/replace/*] → [resolve_main / main_by_name (lib), git cat-file] → [MAIN_SHA "the default branch's commit"]`) is where M1 below sits. That review predates 1d79ffef, so the boundary may be stale.

## Dependency Map

- `scripts/build-loop.sh` → `scripts/lib/dev-cycle-read.sh`: one way only, sourced from `$SCRIPT_DIR` (:43-46). It consumes `scrub_reexec`, `resolve_main`, `main_by_name`, `MAIN_SHA`, `main_entry`, `FENCE_AWK` (and its awk globals `odd`, `oddwhy`, `infence`, `fline`), `oddwhy` and `NAMECHARS`. It gives the lib `ROOT_REAL` (:61) and, as of 1d79ffef, the environment `GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1` (:63), which every lib git read inherits.
- `scripts/dev-cycle.sh` → the same lib (the other caller). It exports `GIT_LITERAL_PATHSPECS=1` (dev-cycle.sh:125) but not `GIT_NO_REPLACE_OBJECTS`.
- In code, the lib does not depend on build-loop.sh. Its header names its callers only in prose.
- The interface that build-loop.sh hands to its own later modes (U1c `--status`, U2 gate): `read_settings` sets `POLICY` (the effective policy, already folded with the never line's validity), `NEVER` (an array of checked entries as written), and the `*_LINE` strings. `main_file FILE AWK` sets `FILE_OUT`/`FILE_WHY` and is the generic "file on main under FENCE_AWK" reader that U1c's constraints line will reuse.
- `test/scripts/build-loop-read.bats` → `test/lib/build-loop-fixtures.bash` → `scripts/build-loop.sh`, run as a subprocess only. No test sources the script or the lib.

The direction is correct. A volatile CLI depends on the stable shared reader, with no cycle and no layer violation.

## Findings

#### M1. The replace-ref guard sits in one caller, so the lib's "reads the default branch's commit" now holds for build-loop.sh but not for dev-cycle.sh

**Severity:** Minor
**Location:** `scripts/build-loop.sh:62-63`; `scripts/lib/dev-cycle-read.sh:12-14`, `:29-32`; `scripts/dev-cycle.sh:125`
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** High (behaviour, executed); Medium (severity, which depends on how the dev-cycle skill uses `--check-answer`/`--check-brief` before U3/U4)
**Legibility-target:** for-orchestrator-synthesis

Evidence, `scripts/build-loop.sh:62-63`:
```
# Read main's own objects: a replace ref could swap in any settings blob.
export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1
```
`scripts/dev-cycle.sh:125`:
```
TODAY="${DEV_CYCLE_TODAY:-$(date +%F)}"; export GIT_LITERAL_PATHSPECS=1
```
The lib header's list of caller obligations (`scripts/lib/dev-cycle-read.sh:12-14`) and its input contract (`:29-32`):
```
# once that second caller lands. The
# caller sets -euo pipefail,
# cds to the repo root and sets ROOT_REAL (that root, symlinks resolved) before
...
# Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields
# read the default branch's commit, never the working tree (check_brief also
```

A6's fix is correct for build-loop.sh. It puts a cross-cutting property of the lib's main readers (main_entry, brief_fields, check_brief and check_answer all read objects at `MAIN_SHA`) into one caller's environment. The lib does not state that property as a caller obligation, and the other caller does not meet it. Executed in a scratch repo: main's `docs/working/questions.md` held an OPEN `Q-001`, and `git replace` swapped in a blob that reads ANSWERED with `Q-001: [1]`. `scripts/dev-cycle.sh --check-answer Q-001` then prints `keep Q-001`. With `GIT_NO_REPLACE_OBJECTS=1` it prints `open Q-001`. The same probe against `build-loop.sh --settings` reads main's own blob (`policy review set`). The consequence is structural: whether the lib's reads mean "main's commit" depends on which script sourced it. Any later caller (or a lib function U2 moves out of build-loop.sh) must rediscover the rule. The plan's own gate path (U3's `--approved` → `check_answer`) runs inside build-loop.sh and is covered. The exposure is the dev-cycle.sh entry points that exist today.

**Security implication:** this is `B3` from `docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1b.md` (Commit: `0ae7d801`; that security review predates this diff, so the boundary may be stale). Moving the guard into the lib extends B3's protection to dev-cycle.sh's readers. Whether the dev-cycle.sh exposure matters is security-reviewer's call, not this review's.

**Recommendation:** Put the guard where the readers live. Either the lib exports `GIT_NO_REPLACE_OBJECTS=1` when it is sourced (beside its other top-level variables; one line), or the header's caller obligations name it and dev-cycle.sh:125 adds it. If neither fits the line cap, an override row deferring it to U1c (the next unit to touch the lib header, per row 242), with the dev-cycle.sh exposure stated, keeps the gap visible.

#### I1. `NEVER=()` means "none", "malformed" or "not read" alike; consumers are safe only through an unstated POLICY invariant

**Severity:** Informational
**Location:** `scripts/build-loop.sh:122-125`, `:130`, `:163-164`, `:170-171`
**Move:** 3 (module boundary), 5 (interface segregation)
**Confidence:** Medium
**Legibility-target:** for-author

Evidence, `scripts/build-loop.sh:122-124`:
```
# Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (an array of the checked globs,
# each as written, a trailing / kept) and NEVER_LINE from main's commit. POLICY
# and NEVER are for the modes that judge a brief (--status, then the gate).
```
and `:170-171` (excerpt ends :171; the enclosing `read_settings()` continues to :179, read):
```
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but the Self-merge never: line is malformed, so self-merge is off"
```

`NEVER` comes out empty in three cases: no never line, a malformed line, and a file that was not read. Only `NEVER_LINE`'s text tells them apart. The design is still safe, because a malformed or unread line can never leave `POLICY=self-merge` (:130, :170-171), and the S rules that read `NEVER` apply only under self-merge. But that guarantee lives in `read_settings`'s control flow. The interface comment that U2's author will read does not state it. A U2 gate that read `NEVER` without first requiring `POLICY == self-merge` (for example, reporting never-listed paths under review) would treat "malformed" as "nothing denied".

**Recommendation:** Add one clause to :122-124: "NEVER is empty unless the line is set; a malformed or unread line leaves POLICY review, so read NEVER only when POLICY is self-merge." No code change.

#### I2. `read_settings` couples parsing, the policy decision and the printed WHY text; U1c's constraints line should not extend it

**Severity:** Informational
**Location:** `scripts/build-loop.sh:127-179`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Evidence, `scripts/build-loop.sh:127-132` (excerpt ends :132; the enclosing `read_settings()` continues to :179, read):
```
read_settings() {
  local f=docs/dev-cycle.md where l k c l1 l2 nx t v g i why never_ok=1 parts=()
  local -A cnt=() first=() second=() next=() text=() seen=()
  POLICY=review; NEVER=()
  where="of $f on the default branch"
  if ! main_file "$f" "$SETTINGS_AWK"; then
```

At 53 lines, `read_settings` computes machine state (`POLICY`, `NEVER`) together with the presentation strings for all three keys, and it couples the policy and never decisions through `never_ok`. That is fine for one file. The plan's interface adds a fourth `--settings` line, `constraints ok N-hard M-soft|missing|none-hard|unreadable` (plan :204, T44), read from a different file. `main_file`'s `FILE_OUT`/`FILE_WHY` seam (:67-88) already makes a separate `read_constraints` cheap.

**Recommendation:** In U1c, add constraints as its own reader over `main_file`, called from the `settings` mode arm (:181-185), rather than as a fourth branch inside `read_settings`.

#### I3. The plan still describes never entries as "pathform globs", which U2 would apply wrongly

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:74` (outside this diff); `scripts/build-loop.sh:112-113`
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Evidence, plan `:74`:
```
  - **Per project.** `docs/dev-cycle.md` may add `Self-merge never: GLOB …` (pathform globs, one line, read from main's commit). A malformed line turns self-merge off for that repo (`--settings` says why).
```
`scripts/build-loop.sh:112-113`:
```
# A never entry: pathform's rule, but a .git* part (.github/) is allowed, since
# the list only adds refusals and must not turn self-merge off by naming one.
```

`NEVER` reaches U2 already checked by `globform`, which differs from `pathform` on purpose. If U2's author follows the plan text and re-validates the entries with `pathform … glob`, `.github/` fails, and the gate would refuse or mishandle a list that `--settings` reported as `set`. The array shape from A8 removes any need to re-validate, but the plan points the wrong way. Override row 238 (C4) defers moving globform into the lib, and this finding does not re-raise that. It is about the plan's description of the rule.

**Recommendation:** When U2 is briefed, change "pathform globs" at plan :74 to "globs checked by --settings (pathform's form, .git* parts allowed); U2 uses NEVER as given".

## Iteration-2 items in my domain (status at 1d79ffef)

- **A7 (main_file error arm and lib copy): error arm fixed; the copy is deferred by a settled row.** `:79` now maps `error)` to "the default branch's tree could not be read for $f", `:82-83` names a failed blob read, and the comment at `:67-69` lists both. `main_file` is still the third copy of the lib's main_entry → cat-file → FENCE_AWK → `odd`/`unbalanced` protocol, and it still reads the lib's awk globals (`infence` is not named in FENCE_AWK's comment). That part is settled by u1a's case-block row (override row 228, Defer, revisit trigger U2's floor function), so it is not re-raised here. Row 228's premise ("U1c's main_file is the third") still holds. The error and failed-read arms are untested (fact-check E4), which belongs to test-strategy.
- **A8 (NEVER shape): fixed.** Executed: `declare -a NEVER=([0]="a/" [1]="h*/x?.md" [2]=".github/")`. It is an array of checked entries, split with `read -ra` (never globbed), kept as written with the trailing `/`. The comparison rule (trailing `/` ignored) is documented at `:20-21` and `:122-123`. Residuals: I1 (an empty NEVER is ambiguous; one comment clause) and I3 (plan :74).
- **C3 (reset): fixed.** `:130` resets `POLICY=review; NEVER=()`, and every branch sets all three `*_LINE`. Executed: a second `read_settings` call after main changed to a malformed never line gives `POLICY="review"`, `NEVER=()`. A second call still needs a fresh `resolve_main` for a moved main, which is the lib's documented contract.
- **R2 (helper fix): fixed.** `test/scripts/build-loop-read.bats:81` and `:130` are now `settings_like …; settings_like …` (separate commands). Mutations on scratch copies: a bogus left operand at `:81` fails T4, a bogus left operand at `:130` fails T45, and `globform` → `pathform … glob` (the A4 regression) fails T45 at `:130`. No remaining `settings_* … && settings_*` chains. The other `A && B || { …; return 1; }` lines cover failure through their `||`. Full suite: 9/9 pass.

## What Looks Good

- **One-way dependency, self-contained sourcing.** build-loop.sh sources the lib from its own directory. The lib has no code dependency back on it, and the planted-lib test guards this.
- **`main_file` is a good seam.** It is generic over the awk program and returns state (`FILE_OUT`/`FILE_WHY`) rather than printing, so U1c's constraints reader can reuse it unchanged.
- **Fail-closed coupling is explicit and located in one place.** A malformed never line turns self-merge off at `:170-171`, and a file that was not read gives `never malformed`. Both are in the reader, so no consumer has to re-derive them.
- **`NEVER` as a validated array.** It removes the re-split and glob-expansion hazard that A8 named, and the decision of what counts as an allowed entry stays with the reader.
- **Read and print are separate.** `read_settings` only sets globals, and the mode arm prints them. `--status` and the gate can call it without output.
- **Tests go through the public CLI only.** The fixture library is a proper seam for the `build-loop-*.bats` family: `settings`, `settings_is` and `settings_like` will serve U1c's constraints tests as they are, and since 1d79ffef each helper call fails the test on its own.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| M1 | `GIT_NO_REPLACE_OBJECTS` lives in one caller; dev-cycle.sh's lib readers still honour replace refs (executed: `--check-answer` reads `keep` from a replaced blob); the lib header omits the obligation | Minor | `scripts/build-loop.sh:62-63`, `scripts/lib/dev-cycle-read.sh:12-14,29-32`, `scripts/dev-cycle.sh:125` | High (behaviour) / Medium (severity) |
| I1 | An empty `NEVER` means none, malformed or unread alike; safe only through the unstated "malformed → POLICY review" invariant | Informational | `scripts/build-loop.sh:122-125` | Medium |
| I2 | `read_settings` mixes parse, decision and WHY text; add U1c's constraints line as its own reader | Informational | `scripts/build-loop.sh:127-179` | Medium |
| I3 | Plan :74 still says "pathform globs" for never entries; U2 following it would refuse `.github/` | Informational | `docs/working/plan-build-loop-handoff.md:74` | High |

## Overall Assessment

U1b keeps the system's structure sound, and 1d79ffef closes every iteration-2 item in this domain that was not settled: A7's error arm, A8's array, C3's reset and the R2 helper fix, each confirmed by execution. There are no Structural or Coupling findings. The dependency runs one way from a thin CLI to the shared reader, and the interface for U1c and U2 (`POLICY`, `NEVER`, `main_file`) is in usable shape. The single most important structural point is M1, which is new at this commit. The replace-ref guard was added to the caller rather than to the module that owns "read main's commit", so the lib's contract now differs between its two callers. It is a one-line fix in place, or a deferral row. The three Informational items are comment- or plan-level notes for U1c and U2.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "A markdown report saved to docs/reviews/architecture-review-review-2026-10-05-build-loop-u1b.md, structured per the architecture-review skill."
- **Answered:** Yes. It covers the module boundaries between build-loop.sh and the lib (M1, A7 status, Dependency Map), the interface U1c/U2 consume (`POLICY`/`NEVER`: I1, I3, A8, C3; `main_file`: I2, A7) and the test fixture structure (R2 status, What Looks Good). Every finding carries Severity, Location, verbatim Evidence, Confidence and a Legibility-target. Settled rows were respected: main_file's protocol copy (row 228), globform's copy (row 238, C4), help range (C5), fixture env (C6), copy models (C7), the lib header's "planned" wording (C8) and many() (C9) are not re-raised. Row 228's premise still holds.
- **Out of scope:** Whether dev-cycle.sh's replace-ref exposure in M1 is exploitable belongs to security-reviewer (B3). Letter-bearing markup hiding a key copy (fact-check E1/E3) belongs to security/orchestrator. Test 9's main-vs-HEAD gap and the untested A6/A7 arms (E2/E4) belong to test-strategy.
- **Escalate:** M1 goes to the orchestrator and security-reviewer. Decide between the lib-level fix now (one line) and a deferral row to U1c that names the dev-cycle.sh exposure. I2 and I3 go to the orchestrator as U1c/U2 brief inputs, not U1b blockers.
- **Questions / Decisions:** Should `GIT_NO_REPLACE_OBJECTS=1` move into the lib (covering both callers) in U1b, or in U1c alongside the lib-header update that row 242 already defers? Recommended: the lib, now, if one line fits the cap; otherwise U1c with an override row.
