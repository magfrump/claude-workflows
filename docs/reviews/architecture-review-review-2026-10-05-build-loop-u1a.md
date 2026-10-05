Commit: 4aa2e98e

# Architecture Review — feat/build-loop-u1a (U1a, review iteration 4 of 4, final confirming pass)

**Scope:** `git diff main...feat/build-loop-u1a` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats)
**Date:** 2026-10-05
**Based on:** Stage-1 merged fact-check (k=3 at 4aa2e98e, `docs/reviews/code-fact-check-report-build-loop-u1a-r{1,2,3}.md`); security review `docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1a.md` (Commit: `722884c7`; it predates this diff's fix commit, so its boundaries may be stale)

**Scope check:** in scope. The diff adds two public lib functions (`main_entry`, `brief_fields`), a new global (`BRIEF`, `BRIEF_ODD`), and changes `check_answer`'s input contract from working tree to default-branch commit (trigger categories 2 and 3).

**Trust-boundary scan:** `ls docs/reviews/security-review-*.md` matches only older, unrelated reviews (the glob gap is covered by override row 231). I used the u1a security review's map by hand. Finding 1 sits on `B2` (main_entry) and `B6` (argument form) from `docs/reviews/security-reviewer-review-2026-10-05-build-loop-u1a.md` (Commit: `722884c7`). That review predates this diff's fix commit, so the boundary may be stale.

## Dependency Map

- `scripts/dev-cycle.sh` → `scripts/lib/dev-cycle-read.sh` (sourced from its own directory) → `git`, `awk`. The lib depends on nothing in the repo it reads. Nothing in the lib calls back into dev-cycle.sh, and nothing references build-loop.sh except comments.
- Inside the lib, the diff adds one layer of shared readers under the existing checks. The direction is acyclic:
  - `check_brief` → `main_entry`, `brief_fields`
  - `brief_fields` → `pathform`, `main_entry`, `FENCE_AWK`
  - `check_answer` → `main_by_name`, `main_entry`, `FENCE_AWK` + `ANSWER_AWK`
  - `main_entry` → `main_by_name`, `MAIN_SHA` (set by `resolve_main`)
- `check_answer` loses its dependency on the working-tree plain-file layer (`skipped`/`need_root`/`ROOT_REAL`/`SKIPPED`), so it now depends only on git objects. Override rows 216 and 217 asked for this.
- Later units couple to this surface as follows:
  - U1b's `--settings` and U1c's constraints and `main_file` will read through `brief_fields` and `main_entry`.
  - U3's `--approved` will capture `check_answer`'s one-line answer.
  - U2's floor function is the expected fourth caller of `main_entry`'s result words (override row 225).

## Findings

#### 1. main_entry relies on callers to check the path form, and an unchecked path fails open as `absent`

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:256-263`
**Move:** 3 (module boundary), 6 (precondition placement)
**Confidence:** High (probed)
**Evidence:**
```
256	# paths from the top level, whatever the current directory). The caller has checked
257	# main_by_name and the path's form (pathform, so ls-tree prints it unquoted).
258	main_entry() {
259	  local p="" rest="$1" out mode path dup="" want=()
260	  local -A m=()
261	  main_by_name || { echo error; return; }
262	  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
263	  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
```
(truncated: the rest of the function, :264-274, parses `out` into `m` and answers `absent` when the `m` key is missing, at :271 and :273)

**The problem:**
- The comment states two caller preconditions. The function enforces one of them itself (:261, `main_by_name`), so half of the comment is stale (fact-check: Mostly accurate).
- The other precondition, `pathform`, is left to the caller, and breaking it fails open. I committed `a"b.md` and `d"x/q.md` to a scratch repo, then ran `main_entry` on each with no `pathform` check. Both answered `absent`: ls-tree prints a quoted name, so the `m` lookup misses.
- No live caller is affected:
  - `check_brief` (:325) and `brief_fields` (:294) run `pathform` first.
  - `check_answer` passes constant paths.
- The planned new callers (U1c's `main_file`, U2's floor function) each have to remember the precondition. `absent` is the answer that callers turn into a permissive result: `check_brief` prints `ok … new`, and `check_answer` moves on to the other file.

This is related to override row 230 (C8, untested bypass candidates, deferred with "./x fails pathform before any read"), but it is not the same issue. Row 230 settles test coverage. This finding is about where the precondition lives.

**Security implication:** none. The recommendation duplicates the `B6` check at the `B2` entry rather than moving either one.

**Recommendation:**
- Add `pathform "$1" || { echo error; return; }` next to :261, so `main_entry` fails closed on its own input as it already does for `main_by_name`.
- Rewrite :256-257 to say that `main_entry` checks both preconditions itself. `brief_fields`' own `pathform` call can then go, or stay as a harmless duplicate.

**Legibility-target:** the comment at `scripts/lib/dev-cycle-read.sh:256-257` (the stated precondition contract of a public lib function).

#### 2. The lib header's environment contract does not mention the functions that now set their own pipefail

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:12-13`, `:290-292`, `:548`
**Move:** 3 (module boundary: the contract between the lib and its callers)
**Confidence:** High
**Evidence:**
```
12	# once that second caller lands. The
13	# caller sets -euo pipefail,
```
```
290	  # pipefail for this function only (local -), so a failed read is caught
291	  # whatever the caller set.
292	  local - out l; set -o pipefail
```
```
548	  local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields
```

**The problem:**
- Fact-check escalated this question: does the change contradict the header's contract? No.
  - The change is defence in depth, and it points the right way: the two readers whose `$(a | b) || skip` guards decide fail-closed now depend less on caller state.
  - Every other lib function still assumes the caller's `-euo pipefail` (for example the `imported_names` walk). So the header's rule stays true as a requirement.
- What is missing is the exception. A reader of the header alone would not know which functions are self-protecting. A future reader that adds a pipeline-guarded read could copy either convention.

**Recommendation:**
- After "The caller sets -euo pipefail," add one clause: "brief_fields and check_answer also set pipefail for their own body (local -), since their read guards depend on it."
- This also gives U1b, U1c and U2 readers one stated pattern to follow.

**Legibility-target:** the lib header, `scripts/lib/dev-cycle-read.sh:12-13`.

#### 3. The lib states no minimum bash version, and `local -` raises the implicit one

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:292`, `:548` (and `:288`, `declare -gA`)
**Move:** 1 (dependency on the runtime)
**Confidence:** Medium. Restore behaviour before 5.1 is not verified here; only bash 5.2.15 is installed.
**Evidence:**
```
288	declare -gA BRIEF=(); BRIEF_ODD=""
292	  local - out l; set -o pipefail
548	  local - a="$1" f e r hit="" where="" n why; set -o pipefail  # as brief_fields
```

**The problem:** The lib now depends on three bash-version behaviours:

| Feature | Bash needed | Source |
|---|---|---|
| `declare -g` | 4.2 or later | already present before this diff |
| `local -` | 4.4 or later | added by this diff |
| `local -` restoring `pipefail`, which has no single-letter flag | possibly 5.1 or later | installed CHANGES (5.1-beta, item i): "Several changes to how `local -' restores the values of options and $SHELLOPTS" |

**Impact by version:**
- On bash 4.4 to 5.0 the worst case is that pipefail leaks into the caller. Under the header's own contract the caller has already set pipefail, so a conforming caller is unaffected.
- Before 4.4, `local -` is an error. Under `set -e` that stops the caller, which fails closed.
- So the runtime risk is low. The structural gap is that the runtime dependency is undocumented, and the macOS default bash (3.2) already cannot run the lib.

The fact-check summary escalated this point (r1-r3).

**Recommendation:**
- State "bash 4.4 or later" in the lib header beside the sourcing rule.
- Optionally, add a cheap `BASH_VERSINFO` guard in the scripts that source the lib, so an old bash fails with a message instead of a `local` error.

**Legibility-target:** the lib header, `scripts/lib/dev-cycle-read.sh:8-13`.

#### 4. The list of check modes that need a default branch found by name is kept in several places, and one copy has already drifted

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:72-73`, `:81`, `:189-193`; `scripts/lib/dev-cycle-read.sh:22-23`, `:242-243`; `test/scripts/dev-cycle.bats:767`
**Move:** 8 (extension points)
**Confidence:** High
**Evidence:**
```
scripts/dev-cycle.sh:193	if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then
test/scripts/dev-cycle.bats:767	@test "--check-brief and --check-branch need a default branch found by name; the others do not" {
```

**The problem:**
- Adding `--check-answer` to the set meant editing the condition at :193 plus prose copies in two help lines, a code comment and two lib-header sentences.
- The test title at bats:767 was missed, and it now states the opposite of the behaviour (fact-check r2: Stale). The behaviour itself is tested at bats:1153.
- Each new main-reading mode (U1c's `--status`, U3's modes) repeats this edit. This is a small extension point that grows by modification.

**Recommendation:**
- Now: rename the bats:767 title. For example, "--check-brief, --check-branch and --check-answer need a default branch found by name; --check-path does not". Optionally add `--check-answer` to its loop.
- Later, if the list keeps growing: keep the set in one shell variable or `case` in dev-cycle.sh. The help text then names "the modes that read the default branch" rather than listing them.

**Legibility-target:** the test title at `test/scripts/dev-cycle.bats:767`.

## Settled, not re-raised (override log)

- Row 225: `check_brief` and `check_answer` duplicate the `main_entry` result-word `case`.
- Row 226: `BRIEF` keeps whole lines in a global.
- Row 227: `check_answer` reads main while the skill records answers in the working tree until U4. SKILL.md now says this.
- Row 233: `check_brief` calls `ls-tree` twice.
- Row 234: `brief_fields` collapses absent, notfile and unreadable into `error`.
- Row 230: untested `main_entry` bypass candidates. Finding 1 is about where the precondition lives, not test coverage.
- Row 215: three guard channels; U3 must check `main_by_name`.
- Row 216: `check_answer` as merge authorisation. This branch adds `main_by_name`; the "positive line only" half belongs to U3's caller.

## What Looks Good

Each row below makes a positive claim (route: code-fact-check).

| # | Claim | Evidence |
|---|---|---|
| G1 | `check_answer` no longer depends on the working-tree plain-file layer: no `need_root`, no `ROOT_REAL`, nothing added to `SKIPPED`. Override rows 216 and 217 are discharged in structure, not just in prose. | `scripts/lib/dev-cycle-read.sh:547-575`; bats test "check_answer reads git only" at `test/scripts/dev-cycle.bats:1160` |
| G2 | A brief now has one parser. `brief_fields` is the only reader of machine lines, and `check_brief` uses its `status` instead of keeping its own awk. U1b and U1c add keys without adding parsers. | `scripts/lib/dev-cycle-read.sh:289-312`, `:340-351` |
| G3 | `main_entry` puts the "regular file under plain directories on main" rule in one function that fails closed (`error`) on a missing default branch, an ls-tree failure or a duplicate tree name. The three readers share it instead of each running `ls-tree \| cut`. | `scripts/lib/dev-cycle-read.sh:258-274` |
| G4 | Dependency direction is unchanged. dev-cycle.sh depends on the lib, and the lib depends only on git and awk. The diff adds no reverse or circular dependency and no reference to build-loop.sh beyond comments. | `scripts/lib/dev-cycle-read.sh` (no `source`, no call to scripts/) |
| G5 | `--help` is derived from the header and no longer from a fixed line range. The header is now the single source, and a bats test pins its last line. | `scripts/dev-cycle.sh:111-112`; `test/scripts/dev-cycle.bats:1276-1280` |
| G6 | The lib's sourced-surface test lists the new public names (`main_entry`, `brief_fields`, `BRIEF`, `BRIEF_ODD`), so the public surface is registered where U1b's suite will also look. | `test/scripts/dev-cycle.bats:1032`, `:1036` |

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | main_entry relies on callers to check the path form, and an unchecked path fails open as `absent`; its stated precondition is half stale | Minor | `scripts/lib/dev-cycle-read.sh:256-263` | High |
| 2 | The header's "caller sets -euo pipefail" does not mention the two self-protecting readers | Informational | `scripts/lib/dev-cycle-read.sh:12-13` | High |
| 3 | No minimum bash version is stated; `local -` needs 4.4, and restoring pipefail possibly needs 5.1 | Informational | `scripts/lib/dev-cycle-read.sh:292,548` | Medium |
| 4 | The needs-main mode list is copied in several places; the test title at bats:767 is stale | Informational | `scripts/dev-cycle.sh:193`; `test/scripts/dev-cycle.bats:767` | High |

## Overall Assessment

The branch improves the lib's structure:
- one brief parser
- one fail-closed tree classifier
- an answer reader that depends only on git objects

Dependencies still point one way. The iteration-4 fixes (`local -` + pipefail, and help derived from the header) add nothing structural that is wrong. Their only cost is the two documentation gaps in findings 2 and 3.

Nothing here is Structural or Coupling. Everything can be fixed in place in a few lines.

The most important item is finding 1. `main_entry` is the primitive that U1c and U2 will call directly, and today its one unenforced precondition fails toward `absent`. A one-line `pathform` guard inside the function closes that before the next caller arrives.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/architecture-review-review-2026-10-05-build-loop-u1a.md, structured per the architecture-review skill, first line `Commit: 4aa2e98e`.
- Answered: yes
- Out of scope: the BSD sed `{/^#/p}` portability of the help address (api-consistency or orchestrator); the "until committed" help wording at `scripts/dev-cycle.sh:59` (fact-check, wording); the security review's own staleness (Commit `722884c7`).
- Escalate: finding 1 to the orchestrator as the one actionable item before U1c builds on `main_entry`. Fact-check's bash-version question (finding 3) is unresolved without a bash 4.4 to 5.0 binary.
- Decisions I made: I filed finding 1 although it touches row 230's subject, because row 230 settles test coverage and its rationale assumes callers run pathform, which is the dependency finding 1 questions. I used the u1a security review found by hand, because the skill's glob misses it (row 231).
