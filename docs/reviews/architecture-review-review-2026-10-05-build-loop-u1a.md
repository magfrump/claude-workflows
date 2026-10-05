Commit: 2da477b7

# Architecture Review — feat/build-loop-u1a (review-fix iteration 2)

**Scope:** `git diff main...feat/build-loop-u1a` (d6426e3e, c8435580, 2da477b7) over `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`, `test/scripts/dev-cycle.bats`; enclosing units `main_entry`, `brief_fields`, `check_brief`, `check_answer` read whole at the tip.
**Date:** 2026-10-05
**Based on:** merged Stage-1 fact-check `docs/reviews/code-fact-check-report-build-loop-u1a.md` (summary: 33 Verified, 8 Mostly accurate, 2 Incorrect, 1 Unverifiable); plan `docs/working/plan-build-loop-handoff.md` rev 4 (Approach, Script interface, step 3).

**Scope check:** in scope. Public APIs: new lib functions `main_entry` and `brief_fields`, new globals `BRIEF` / `BRIEF_ODD`, and a changed input contract for `check_answer` (working tree → main's commit) that `dev-cycle.sh --check-answer` and, later, build-loop.sh consume. Data models: `main_entry`'s output vocabulary (`blob|absent|notfile|notdir PART|error`) and `BRIEF`'s key/value shape are string protocols that U1b/U1c consumers will parse. Test and SKILL.md changes reviewed only for what they say about those contracts.

**Trust-boundary cross-reference:** active. The glob `docs/reviews/security-review-*.md` matches only older non-build-loop reviews (newest by date: `security-review-2026-10-02-digest-pass38.md`); the build-loop security reviews are named `security-reviewer-review-*.md` and do not match the skill's convention. I used the boundary map of `docs/reviews/security-reviewer-review-2026-10-05-final-build-loop-u0c.md` (Commit: `d8da1fba` — security review predates this diff; boundary may be stale): `B3 (moved): [questions.md / questions-archive.md in the working tree] → [skipped (need_root, blocker); FENCE_AWK + ANSWER_AWK; ANSWERED header] → [keep|drop|done|open|unrecognized Q-NNN]`. This diff relocates B3's source from the working tree to main's commit, which is the planned move (override row 206, D8). No recommendation below moves it further.

## Dependency Map

- `scripts/dev-cycle.sh` → sources `scripts/lib/dev-cycle-read.sh` (unchanged direction). Its only change is that `--check-answer` now joins `--check-brief`/`--check-branch` behind the `main_by_name` gate (`scripts/dev-cycle.sh:191`).
- Inside the lib, a new layer appears between git and the checks:
  - `main_entry` → `main_by_name`, `MAIN_SHA`, `git ls-tree` (one process).
  - `brief_fields` → `MAIN_SHA`, `git cat-file`, `FENCE_AWK` (shared parser); writes globals `BRIEF`, `BRIEF_ODD`.
  - `check_brief` → `need_root`, `pathform`, `isbrief`, `blocker` (working tree), then `main_entry`, `brief_fields`, `git log` (main).
  - `check_answer` → `main_by_name`, `main_entry`, `git cat-file`, `FENCE_AWK + ANSWER_AWK`. It no longer depends on `skipped`/`SKIPPED`/`ROOT_REAL`/`need_root` — a dependency removed, not added.
- Planned consumers (not in this diff; their absence is not flagged): build-loop.sh `--settings`, `--status`, `--start`, `--prompt` (U1b/U1c/U3) call `main_entry` and `brief_fields` in-process (plan "build-loop.sh … calls the lib directly, with no subprocess").
- Direction is sound throughout: the volatile entry scripts depend on the lib; the lib depends only on git and awk; no lib function depends on a caller. No cycle.

## Findings

#### 1. `brief_fields` has three outcomes but two signals, and its unchecked preconditions make every consumer copy check_brief's guard sequence

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:277-300` (excerpt below ends :296; enclosing `brief_fields()` continues to :300 — read whole), guard sequence at `:309-333`
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
# stored). The callers judge the values. The caller has checked
# main_by_name and that the path is a blob on main (main_entry), and calls it in
# its own shell: it sets globals.
...
  out="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'
...
      odd\ *|unbalanced\ *) BRIEF=(); BRIEF_ODD="$l"; return 1 ;;
```

`brief_fields` can end three ways — fields read, file refused (`return 1`, `BRIEF_ODD` set), or blob unreadable — but only the first two have a signal. The third depends on how the caller invoked it: called bare under `set -e` the whole process exits with git's 128; called as `if ! brief_fields …` (exactly how `check_brief` calls it, `:327`) errexit is suspended, the pipeline's failure is the assignment's status and is then discarded, and the function returns 0 with no keys and an empty `BRIEF_ODD` — indistinguishable from a brief that has no machine lines. Probe (scratch repo, path not on main): `if brief_fields nosuch.md; then echo "rc0 keys=${#BRIEF[@]} odd=[$BRIEF_ODD]"; fi` printed `rc0 keys=0 odd=[]`; the bare call then ended the shell with exit 128. Today this is safe only because `check_brief` runs `main_by_name`, `pathform` and `main_entry == blob` first (`:311-326`). The header makes that sequence a precondition the caller must reproduce, so U1b's `--settings` (constraints, `docs/dev-cycle.md`) and `--status`, and U3's `--start`/`--prompt`, will each copy `check_brief`'s guard block, and any one that skips it reads "missing Branch:/Policy:" where it should read "unreadable". That is the concrete change-cost: the module's safety lives in its callers. This extends, and does not contradict, override row at `override-log.md:215` (the guards' three channels, deferred to U3): `brief_fields` adds a fourth, context-dependent behaviour, and U1b lands before U3. (Same mechanism as fact-check Escalation 3, addressed there to security-reviewer; this finding is the structural side only.)

**Recommendation:** Let `brief_fields` own its preconditions: call `main_entry` itself and set `BRIEF_ODD` to `absent`, `notfile`, `notdir PART` or `error` (returning 1, or a distinct 2 for not-a-blob), and turn a failed `cat-file` into `BRIEF_ODD=error; return 1` (e.g. capture with `|| { BRIEF_ODD=error; return 1; }`). `check_brief` then maps `BRIEF_ODD` to its skip lines in one place, and U1b consumers call one function. Verification: the probe above (≤5 lines) should print a non-zero return and `odd=[error]` instead of `rc0`.

#### 2. `main_entry`'s five-word protocol is parsed by a hand-copied case block in each caller

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:320-326` and `:539-545`
**Move:** 7 (coupling surface), 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
    notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch"; return ;;
```
```
      notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch, so $f is not read"; return ;;
```

Both callers translate the same vocabulary (`absent`/`blob`/`notdir PART`/`error`/other) into skip text with near-identical, already-diverging wording. The plan's `--settings` reads two more files from main (`docs/dev-cycle.md`, `docs/constraints.md`, with `unreadable: WHY`), so the block will have four copies after U1b. Adding a sixth outcome (e.g. a distinct gitlink case) then means editing every copy, and the `error` arm — the fail-closed fix for A2 — is the one a future copy is most likely to drop into `*)` and so still fail closed but with a misleading reason. Stamp coupling to a string protocol is acceptable in bash; the cost is the duplication, not the protocol.

**Recommendation:** Add one lib helper, e.g. `main_why PATH` that prints nothing for `blob`, `absent` for absent, and the human reason otherwise, so callers keep their own prefix/suffix (`so $f is not read`) but share the mapping. Optional if Finding 1's fix routes `brief_fields` through `main_entry`; then only non-brief readers need it.

#### 3. `BRIEF` stores whole lines in one global slot: consumers parse the key prefix and must copy values out before the next call

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:280`, `:297`, `:346`
**Move:** 3 (module boundary — data shape)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
declare -gA BRIEF=(); BRIEF_ODD=""
```
```
  echo "ok $a ${st#Status: } $c"
```

Each value is the line "whole" (`BRIEF[branch]="Branch: feat/f"`), so every consumer strips `Key: ` and judges the rest; `check_brief` does it at `:346`, and U1b's `--status` will do it for branch, policy and dispatched. Keeping the whole line is a defensible choice — it lets a caller require an exact form (`^Status: (open|done|dropped)$`) without the lib deciding what whitespace means — and the header says "the callers judge the values". The single global slot also means `--status BRIEF…` must consume one brief's fields before reading the next. Neither is harmful now; both are conventions worth stating once.

**Recommendation:** No change required. When U1b adds the second consumer, consider a tiny accessor (`brief_value KEY` printing the text after `Key: `, or empty if the line is not `Key: ` + text) so the prefix rule lives in one place.

#### 4. `check_answer`'s reader now reads main while the dev cycle still writes answers to the working tree

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:528-533`; `skills/dev-cycle/SKILL.md:291-294`
**Move:** 4 (layering — where the source of truth sits)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
# default branch's commit, never the working tree: an answer that unblocks
```
```
     answer recorded only in the working tree reads `open`, or no such entry, until it lands). `open` is not answered yet (or the answer
```

Moving B3's source to main's commit (row 206, D8) is the right direction: the decision input for autonomous work is now a git object a loop cannot write. It does introduce temporal coupling between the skill's writer (step 1 archives and records answers in the working tree) and this reader until U4 rewrites the flow; the help text, SKILL.md and c8435580's Notes all state it, and it fails closed (answers read `open`). Fact-check claim 21 notes SKILL.md's "once step 1 has archived an entry" no longer quite matches reading from main. No structural action beyond U4 as planned.

**Recommendation:** None for this unit; U4 should make the "answers land before the read" ordering explicit in the flow.

#### 5. Two parsers of questions.md now diverge further (NUL handling)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:216` (FENCE_AWK); readers in `scripts/dev-cycle.sh` via `scripts/questions.sh`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium (relies on fact-check Escalation 4 / claim 35, not re-executed)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  if (index(l, "\0")) { refuse("nul"); return 1 }  # $(...) drops NUL, so a printed line would not be the line read
```

Putting the NUL refusal in the shared FENCE_AWK is structurally good (one parser for every FENCE_AWK reader). But questions.md has a second, pre-existing parser family (`scripts/questions.sh`, used by the digest), which per fact-check lists a NUL-holding file instead of skipping it. The two readers of the same file now disagree on what a readable file is. Pre-existing duplication, slightly widened here; not a merge blocker.

**Recommendation:** Track for the unit that next touches questions.sh or the digest's question readers; the long-term shape is one lib predicate ("is this questions file readable") both use.

#### 6. Coverage note: security cross-reference glob does not match this initiative's security reviews

**Severity:** Informational
**Location:** `skills/architecture-review/SKILL.md` (activation condition, `docs/reviews/security-review-*.md`)
**Move:** n/a (review tooling)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
ls docs/reviews/security-review-*.md 2>/dev/null
```

The build-loop security reviews are saved as `docs/reviews/security-reviewer-review-*.md`, which this glob misses; a literal run would pick an unrelated 2026-10-02 review. I used the u0c final security review manually (see header). Not a finding against this diff.

**Recommendation:** Orchestrator: align the output name or the glob in a separate change.

## What Looks Good

Positive assertions below are submitted as claims for code-fact-check, not self-certified.

- `check_answer` drops its `need_root`/`skipped`/`SKIPPED` dependencies and gains `main_by_name`, discharging override rows at `override-log.md:206`, `:216` and `:217` (D8 move; main_by_name check; SKIPPED side effect). `route: code-fact-check` — `scripts/lib/dev-cycle-read.sh:534-556`.
- One brief parser: `check_brief` now reads Status through `brief_fields`, so the Status rule and the build loop's machine lines cannot drift apart (T31). `route: code-fact-check` — `scripts/lib/dev-cycle-read.sh:327-336`.
- `main_entry` is one place deciding "is this a regular file under plain directories on main", replacing the ad-hoc `ls-tree | cut -c1-6`, and it fails closed with a distinct `error` word rather than `absent` (A2). `route: code-fact-check` — `scripts/lib/dev-cycle-read.sh:256-267`.
- The NUL refusal lives in shared FENCE_AWK rather than in `brief_fields` alone, so every FENCE_AWK reader (briefs, answers, later constraints) gets it. `route: code-fact-check` — `scripts/lib/dev-cycle-read.sh:216`.
- `dev-cycle.sh`'s check-mode gate lists the three main-reading modes in one condition, keeping the "needs a default branch by name" rule at the entry point. `route: code-fact-check` — `scripts/dev-cycle.sh:191`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `brief_fields` conflates "unreadable" with "no fields" under `if`; preconditions pushed to every caller | Coupling | `scripts/lib/dev-cycle-read.sh:277-300` | High |
| 2 | `main_entry` output parsed by a copied case block per caller | Minor | `scripts/lib/dev-cycle-read.sh:320-326`, `:539-545` | Medium |
| 3 | `BRIEF` holds whole lines in one global slot | Informational | `scripts/lib/dev-cycle-read.sh:280`, `:346` | Medium |
| 4 | Reader on main, writer still in working tree until U4 | Informational | `scripts/lib/dev-cycle-read.sh:528-533` | High |
| 5 | Two questions.md parsers diverge on NUL | Informational | `scripts/lib/dev-cycle-read.sh:216` | Medium |
| 6 | Security cross-reference glob misses `security-reviewer-review-*` | Informational | `skills/architecture-review/SKILL.md` | High |

## Overall Assessment

The change improves the lib's structure: dependency direction is unchanged and correct, `check_answer` sheds its working-tree dependencies, and a single `main_entry`/`brief_fields` layer now sits between git and every main-reading check, with one brief parser. The issues are fixable in place. The most important one is Finding 1: `brief_fields` is about to gain several in-process consumers in U1b, and its contract currently relies on each of them reproducing `check_brief`'s guard sequence, with a git failure reading as "no fields" in the `if`-context callers use. Folding `main_entry` and a failed-read `error` into `brief_fields`' own `BRIEF_ODD` channel before U1b would let those consumers call one function.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path given in your tail, structured per your skill, with `Commit: 2da477b7` as its first line.
- Answered: architecture review of `main...feat/build-loop-u1a` at 2da477b7: scope check (in scope), dependency map, 6 findings (1 Coupling, 1 Minor, 4 Informational), positive claims routed to code-fact-check; Finding 1 backed by an executed probe in the scratch dir.
- Out of scope: correctness of the NUL refusal and its `"\0"` portability (Escalation 1, api-consistency/orchestrator), the SKIPPED test's power (Escalation 2, test-strategy), security consequences of Finding 1's mechanism (Escalation 3, security-reviewer), ls-tree cost (row 220), U1b/U1c consumers' absence.
- Escalate: Finding 1 to the orchestrator as the pre-U1b contract decision (relates to the deferred three-channel row at `override-log.md:215`); Finding 6 to the orchestrator as review-tooling drift.
