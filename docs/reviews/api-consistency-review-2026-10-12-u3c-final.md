Commit: 4aad0f9c

# API Consistency Review — feat/build-loop-u3c, final confirming pass

**Scope:** `git diff main...HEAD` (main = dafc0e74, HEAD = 4aad0f9c). Public surface: `scripts/build-loop.sh --cycle-diff [--answered Q-NNN]...` (usage, `-h` header, parser, refusal lines, exits), `scripts/health-check.sh`'s `HEALTH_CHECK_LOCK_HELD` seam, lock file and messages, and the plan's interface lines U4 builds against.
**Date:** 2026-10-12
**Based on:** `docs/reviews/code-fact-check-report-2026-10-12-u3c-final-r{1,2,3}.md` (k=3 at ec9dace7) and the brief's Stage-1 summary. Behaviour verified there is not re-verified here. The prior pass is `docs/reviews/api-consistency-review-2026-10-12-u3c-i2.md`.
**Legibility target:** U4's author, who writes SKILL.md step 9 from the `-h` header and the plan, and must branch on each refusal line without reading the awk.

## Baseline Conventions

Unchanged from i2's survey. These come from build-loop.sh's other modes, dev-cycle.sh and health-check.sh:

- **Mode shape.** One kebab-case `--mode`; values validated in the parser; a malformed command line exits 1 with stdout empty and one usage line on stderr.
- **Output lines.** Each line is a keyword, then the fields a caller acts on, then `: WHY`. The WHY is prose unless the header pins part of it. The precedent for pinning is `--check`'s self-merge refusal: "the text up to "; " is fixed, but a WHY naming a read failure is not one a clean checkout cures" (`scripts/build-loop.sh:261-265`).
- **Gated modes.** Every gated mode runs the state gate first, so `refuse state WHAT: WHY` lines (exit 2) can appear before the mode's own lines. The header covers this with the phrase "after --state's gate", which --cycle-diff shares with --main-log.
- **Exit codes.** 0 for the mode's ok, 2 for a refusal, 1 for usage and environment errors, enumerated per mode in the `Exit:` paragraph.
- **Plan as-built notes.** Each landed unit's plan bullet carries an "**As built (date, branch; supersedes … where they differ):**" note that U4 reads as the contract: U3b1, U3b2 and U3b3 (`docs/working/plan-build-loop-handoff.md:324-326`).
- **health-check.sh.** Its seams are `HEALTH_CHECK_*` variables in the header. A nested-run marker is on "When 1" and tested with `== 1`.

## Prior findings (i2), re-checked at 4aad0f9c

| i2 # | Status | Evidence (verbatim) |
|---|---|---|
| 1 `Exit:` paragraph omits --cycle-diff | Fixed | `# --state ok, for --main-log no other line, for --cycle-diff ok, for --check every verdict line ok,` / `# line, a --cycle-diff refuse line, or the state gate (--state's included) not ok.` / `# (--state, --main-log, --cycle-diff, --check, --merge, --start, --prompt; no line printed),` |
| 2 Plan says MAIN_SHA | Fixed | plan `:104` "compares the staged files with the fork point of HEAD and `MAIN_SHA`"; `:209` "against the fork point of HEAD and `MAIN_SHA` (U3c)" |
| 3 `HEALTH_CHECK_LOCK_HELD` truthiness | Fixed | `[[ "${HEALTH_CHECK_LOCK_HELD:-}" != 1 ]] \|\| return 0` (`scripts/health-check.sh:1106`); header "When 1, takes no lock. … Not only a test seam: any caller setting it skips the lock." |
| 4 Subjects and ID only in WHY | Fixed (documented) | header `:189` "PATH is HEAD (no merge base), index (not listed) or the file."; "WHY starts with its ID." A caller can now tell entry refusals (WHY matches `^Q-[0-9]+`) from file-level ones: no file-level WHY starts with `Q-`. |
| 5 Repeatable `--answered`, unused IDs | Fixed (documented) | header "exact IDs, Q-14 is not Q-014; a repeat or an unused one is ignored" |
| 6 health-check lock failures without own message | Deferred | override row "health-check.sh's wait for the lock is unbounded … flock missing exits 127 (bash's not found) … api-consistency 6" |

The 4aad0f9c fix adds one refusal shape, `refuse docs/working/questions.md: --check-answer refuses its index copy whole (quoted 13)` and its `base copy` twin. It fits the grammar: the subject is the file, and the WHY names the side and gives QKEYS_AWK's own token and line number. T38 pins both strings (`test/scripts/build-loop-orchestrator.bats`, the `quoted 13` and `quoted 2` cases). T38 and T43 pass at HEAD (run serially in this pass).

## Name-Pattern Audit

No public name was added since i2. The rows are carried forward and re-checked at HEAD.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--cycle-diff` | CLI mode | `--main-log`, `--check`, `--merge` | `scripts/build-loop.sh:7-16`, `:479-530` | Consistent: kebab-case noun phrase like `--main-log`. Listed in the usage line, the `-h` synopsis and the per-mode block (`-h` output checked). |
| `--answered Q-NNN` | CLI option | `--approved Q-NNN`, `--expect SHA`, dev-cycle `--check-answer Q-NNN...` | `scripts/build-loop.sh` parser; `scripts/dev-cycle.sh:14` | Consistent: same ID regex as `--approved`. It is the first repeatable flag, and its repeat and unused semantics are now documented. |
| `refuse PATH: WHY` (PATH a file, `HEAD` or `index`) | output line | `refuse BRIEF: WHY`, `refuse state WHAT: WHY`, `refuse main-log: WHY` | `scripts/build-loop.sh:174-181`, `:225-243` | Consistent, and documented at `:189`. The subjects cannot collide with `state` or `d6`. |
| `ok` (bare) | output line | `--state`'s bare `ok` | `scripts/build-loop.sh:143-146` | Consistent |
| `HEALTH_CHECK_LOCK_HELD` | env var | `HEALTH_CHECK_SKIP_BATS`, `HEALTH_CHECK_RUN_TESTS` | `scripts/health-check.sh:11-31` | Consistent: same prefix, and "When 1" now matches its sibling |
| `health-check.lock` | lock file | `build-loop-dispatch.lock` | `scripts/build-loop.sh` (dispatch lock) | Consistent: same location (`--git-common-dir`) and same plain-file test |
| `raw_records`, `RAW_*`, `QKEYS_AWK`, `QDIFF_AWK`, `ROADMAP_AWK`, `cyc_blob`, `cycle_diff`, `take_lock` | internal | `ANSWERS_AWK`, `FENCE_AWK`, `log_class` | `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` | Not public. They follow the `*_AWK` and snake_case conventions. |

## Findings

#### 1. The refusal U4 must act on ("merge main first") shares one unpinned line with a read failure

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1839-1842` (the ls-tree compare in `cycle_diff`); header `:199-202`
**Move:** 3 (consumer contract) / 4 (error consistency)
**Confidence:** High

Evidence, verbatim (the full `if` block; `cycle_diff` continues with the per-file key reads):

```
  if ! gate_git ls-tree -z "$base" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lb" \
    || ! gate_git ls-tree -z "$MAIN_SHA" -- docs/working/questions.md docs/working/questions-archive.md > "$t.lm" || ! cmp -s "$t.lb" "$t.lm"; then
    echo "refuse docs/working/questions.md: the default branch changed the questions files since the fork point $base, or they could not be compared; merge it into HEAD, then stage again"; return 1
  fi
```

This is the one --cycle-diff refusal with a prescribed recovery. The branch's override row hands it to U4 as a duty: "merge main into the chore branch before re-running --cycle-diff when it refuses for main's questions change". To carry out that duty, U4 has to recognise this line among the other refusals, which call for a stop or a re-stage.

The line covers two cases:

- an actionable state: main moved the questions files
- an environmental failure: either ls-tree failed

The header's text for it (`:199-202`, "A questions change while main has changed those files since BASE refuses … merge main into HEAD first") does not pin the WHY. U4 would therefore match unpinned prose, and its retry would also fire on a read failure. A read failure does not go away after a merge, so the merge-and-rerun loop can repeat with no new information. The subject also always names `questions.md`, even when only the archive moved (fact-check summary, not changed).

The codebase already solves this exact shape. `--check`'s self-merge refusal pins its prefix and states that a read-failure WHY is not one the prescribed action cures (`:261-265`).

**Recommendation:** Do one of two things:

- Split the line in two: `… the default branch changed the questions files since the fork point BASE; merge it into HEAD, then stage again` for the cmp mismatch, and a separate `… could not be listed` for an ls-tree failure.
- Keep one line and pin its text in the header the way `--check` does (`the text up to "; " is fixed`).

Either way, name the remedy line in the plan's U4 hand-off.

#### 2. The U3c plan bullet has no "As built" note, unlike U3b1–U3b3

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:327-333`
**Move:** 3 (documentation drift for the downstream consumer)
**Confidence:** Medium

Precedent: each landed unit's bullet ends with "**As built (2026-10-12, `feat/build-loop-u3bN`; supersedes the "Script interface" … bullet where they differ):**", used in `docs/working/plan-build-loop-handoff.md:324-326`.

The U3c bullet still opens with "Planned 2026-10-12, before code (interim calls, /away; each named below so the review can test it)". It has one inline "**As reviewed (i2 security F1):**" clause. The contract details U4 needs now exist only in the `-h` header and in scattered override rows:

- the refusal subjects (`HEAD`, `index`, the file)
- the base-side versus index-side "refuses its … copy whole" refusals
- `--answered`'s exact-ID, repeat and unused semantics
- the "merge main into HEAD, then stage again" recovery
- exit 1 for usage and a failed mktemp

The Script-interface line at `:209` (`→ ok, or refuse PATH: why (exit 2)`) does not mention the recovery. U4's author is told by the earlier bullets' pattern to read the as-built note as the authority, and for U3c there is none.

**Recommendation:** When landing, add an "**As built (2026-10-12, `feat/build-loop-u3c`; supersedes …):**" sentence to the U3c bullet. It should list the subjects, the merge-main refusal (Finding 1), and `--answered`'s semantics, and point to the override rows that hand step 9 its duties: index-only commit, compare-and-swap land, list --answered IDs, and hooks.

#### 3. A base-side "refuses its base copy whole" has no remedy the orchestrator can apply

**Severity:** Informational
**Location:** `scripts/build-loop.sh` `cycle_diff`, the `for p in o n` loop (`refuse $f: --check-answer refuses its $k copy whole (…)`)
**Move:** 3 (consumer contract: what the caller does next)
**Confidence:** Medium

Evidence, verbatim (the loop body; the QDIFF comparison follows the loop):

```
      if grep -qv '^Q-' "$t.k"; then echo "refuse $f: --check-answer refuses its $k copy whole ($(grep -v '^Q-' "$t.k"))"; return 1; fi
```

When `$k` is `index`, the orchestrator can fix its own staging. When `$k` is `base`, the cause is a questions file the fork point already holds: main's unbalanced fence, or a fenced question heading. Every cycle that stages any questions change then refuses until that file is repaired on main. A repair from the chore branch that removes the fenced heading is itself refused: T38's last case refuses exactly that edit (`quoted 2`).

This fails closed and matches --check-answer, which already skips such a file whole. The live questions files read clean today (this pass ran FENCE_AWK + QKEYS_AWK over `/workspace/docs/working/questions{,-archive}.md`: no `odd`, `unbalanced` or `quoted` line). The header documents the refusal but not that `base` means a stop for the user rather than something to re-stage.

**Recommendation:** In the header, or in the as-built note of Finding 2, add one clause: "a base copy refused whole is a stop (the user repairs the file on main); an index copy is the orchestrator's to re-stage."

## What Looks Good

- All five actionable i2 findings were fixed in place, with the exact wording recommended. The truthiness fix also makes health-check's two nested-run markers read the same way.
- The 4aad0f9c refusal reuses the existing `refuse FILE: --check-answer refuses its SIDE copy whole (TOKEN N)` shape rather than adding a subject, and both sides are pinned by tests.
- Entry refusals are now mechanically distinguishable from file-level ones, because only entry WHYs start with `Q-`. This is enough for U4 to list the blocking IDs without parsing possessives.
- The parser rejects `--answered` with no value, a non-`Q-` value, and stray operands, each with exit 1 and empty stdout (T38's usage loop). A bare `--cycle-diff` prints `ok`.
- The `HEALTH_CHECK_LOCK_HELD` header entry now says who sets it and warns that any caller setting it skips the lock, matching how `HEALTH_CHECK_SKIP_BATS`'s entry names its setter.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The "merge main first" refusal, the only one with a recovery, shares an unpinned line with an ls-tree failure | Minor | `scripts/build-loop.sh:1839-1842`, header `:199-202` | High |
| 2 | The U3c plan bullet lacks the "As built" note U3b1–U3b3 carry, so U4's contract lives only in the header and override rows | Minor | `docs/working/plan-build-loop-handoff.md:327-333` | Medium |
| 3 | A base-side "copy whole" refusal is a stop for the user, but is not documented as distinct from the index-side one | Informational | `scripts/build-loop.sh` `cycle_diff` (`for p in o n`) | Medium |

## Overall Assessment

The --cycle-diff surface is consistent with build-loop.sh's mode family:

- naming
- gate placement
- bare `ok`
- exit 2 per refusal and exit 1 for usage
- the documented subject grammar

health-check.sh's seam now matches its sibling. Every i2 finding is fixed or deferred by an override row, and nothing breaks an existing consumer.

What remains is about how U4 will branch on the output. One refusal asks the caller to act (merge main and re-run), but it is neither pinned nor separated from a read failure (Finding 1). The as-built contract U4 reads by convention is missing from the plan (Finding 2). Both are a few lines each and can be fixed in place, or handed to U4 by override row. Neither is at blocking grade.

**Goal-alignment note.** The PR's goal is that the orchestrator's chore commit cannot launder an answer, or drop roadmap or idea-log content. The interface serves that goal: one call, an explicit `--answered` allow-list, and refusals that fail closed. The findings concern the step after a refusal. U4 must tell "merge and retry" from "re-stage" from "stop", and only Finding 1's line asks for a retry. Getting that wrong cannot launder anything, because every path still refuses. It costs at most a stuck or looping iteration.
