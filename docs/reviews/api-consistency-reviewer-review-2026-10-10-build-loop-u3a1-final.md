Commit: d10cfba8

# API Consistency Review: feat/build-loop-u3a1 (final confirming pass, full branch)

**Scope:** `git diff main...HEAD` (main d5736445, HEAD d10cfba8), docs/reviews excluded: `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, plan step 7 in `docs/working/plan-build-loop-handoff.md`. Public surface: every `--check` output line and exit path the branch adds, changes or removes; the `--help` header; `STATUS` as `status_fields` leaves it (U3a2's input).
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u3a1-final-r{1,2,3}.md` (k=3: 0 behavioral Incorrect; the second-copy scan test's title names a multi-pack-index case the test lacks). Also the iteration 1 and i2 reports and the 2026-10-10 `feat/build-loop-u3a1` rows of `docs/reviews/override-log.md` (settled: rows 638-649, which are not re-filed here).

## Baseline Conventions

These are unchanged from iteration 1 and i2. State refusals take the form `refuse state WHAT: WHY` and exit 2 before any verdict. WHAT is either a git path (`info/attributes`, `shallow`) or a noun (`gate`, `default-branch`, `objects`). Per-brief refusals take the form `refuse BRIEF: WHY` and name the branch as `the tip of BRANCH` or `the merge of BRANCH`. Each brief gets one verdict line, in argument order (help, "per brief path, in argument order, one verdict line"). Path lines follow only an ok line, a K of N refusal or a checkout refusal. The help quotes each fixed per-brief text word for word. `--status` lines are space-separated fields, with `-` for an absent branch, sha or date. Internal value carriers are global associative arrays with lower-case keys, for example `BRIEF` (`scripts/lib/dev-cycle-read.sh:390`, `declare -gA BRIEF=()`).

## Name-Pattern Audit

| New / changed name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `refuse state objects: the default branch's commit or an object of its tree does not hash to its id, has a second copy in the object store, or could not be read` | output line (state) | `refuse state gate: its merge repository could not be set up`, `refuse state default-branch: ...` | `scripts/build-loop.sh:857-859`, `:330-333` | Consistent. Uses the noun-WHAT form and the family's "could not be read" ending. The help's state paragraph lists it (`:101-107`) |
| `refuse state objects/info/alternates: present and not an empty file` | output line (state) | `refuse state info/grafts: ...`, `refuse state shallow: ...` | `scripts/build-loop.sh` state_gate's file loop | Consistent. Uses the same loop and the same WHY. The WHAT prefix shared with `objects` is settled (row 649) |
| `refuse BRIEF: an object of the tip of BRANCH or of the merge does not hash to its id, has a second copy in the object store, or could not be read` | output line (per brief) | `refuse BRIEF: the tip of BRANCH is SHA, not the expected ...`, `refuse BRIEF: the merge of BRANCH names a blob the object store lacks` | `scripts/build-loop.sh:886,913-914` | Consistent. The help's quote (`:126-128`) matches the runtime text (`:916`) and the test string word for word. Its scope wording: Finding 1 |
| (removed) `refuse BRIEF: its branch BRANCH moved or could not be read again` | output line | none | `git show main:scripts/build-loop.sh:788` | A removal. Nothing outside the help, the tests and docs/reviews quotes it (grep over the worktree, archive/ excluded). Planned (row 625) |
| (removed) `refuse BRIEF: the brief could not be read again from the default branch` and its `deny` reason | output line, deny WHY | none | `git show main:scripts/build-loop.sh:822-829` | A removal. The help's three mentions of it are gone (path-line lead-in, the floor's "not run when" clause, srules' `$5` doc) |
| `STATUS` (keys `line state policy branch loop sha ahead date dispatched reason`) | global assoc. array | `BRIEF` (keys `status branch policy paths asked dispatched`) | `scripts/lib/dev-cycle-read.sh:390` | Consistent. Keys are the lower-cased `--status` field names from the help (`STATE POLICY BRANCH LOOP SHA DATE DISPATCHED [REASON]`), plus `line` and `ahead` |
| `status_fields` / `status_line` | function | `brief_fields`, `check_line` | `scripts/lib/dev-cycle-read.sh:391`, `scripts/build-loop.sh:875` | Consistent. `_fields` = sets values, as `brief_fields` does. `_line` = prints a line, as `check_line` does |
| `GATED` | global flag | `MODE`, `OPEN_SHARED` | `scripts/build-loop.sh:341` | Internal. Its comment separates it from `GATE_*`. No finding |
| `store_check`, `gate_start` | function | — | — | Settled (row 641) |
| `$GATE_TMP/main`, `$GATE_TMP/call` | internal files | `$GATE_TMP/err`, `$GATE_TMP/line`, `$GATE_TMP/diff` | `scripts/build-loop.sh` gate_git, the check loop | Consistent with GATE_TMP's role as per-run scratch space |

## Findings

#### 1. The per-brief object refusal says "of the tip of BRANCH or of the merge", but its second-copy scan also judges main's ids, including main's commit, which neither holds

**Severity:** Informational
**Location:** `scripts/build-loop.sh:644` (scan), `:916` (refusal), help `:126-132`
**Move:** 4 (error consistency), 3 (documentation drift)
**Confidence:** Medium (read from the code; the trigger is a mid-run race, which was not probed)
**Legibility-target:** for-author

Evidence:
```
  } | awk 'FILENAME != "-" { want[$0]; next } ($0 in want) && n[$0]++ { bad = 1 } END { exit bad }' "$GATE_TMP/main" "$GATE_TMP/call" -
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of the tip of $br or of the merge does not hash to its id, has a second copy in the object store, or could not be read"; return; fi
```
help:
```
#                 or of the merge does not hash to its id, has a second copy
#                 in the object store, or could not be read": the tip's
#                 commit, or a tree or blob of its tree or of TREE (gitlinks
#                 aside), read back and re-hashed
```
i2's Finding 1 is fixed. `call` is truncated per call (`> "$GATE_TMP/call"`), so one brief's refusal no longer carries to the next, and the re-hash test checks both argument orders. Each per-brief scan still includes every id in `$GATE_TMP/main`, as store_check's comment says ("no id of main's or of this call"). Suppose one of main's objects gains a second copy after gate_start, for example main's commit or a blob the tip deleted, so that neither the tip nor TREE holds it. Then every later brief refuses, and the reason names the brief's own tip or merge. The help's gloss lists only the tip's and TREE's objects. The refusal fails closed and needs a same-uid writer racing the run (the R8/Q-103 family, as in row 646), so it is not a contract break. It only affects how a quoted refusal reads (D4).

**Recommendation:** In the help gloss, add "(and a second copy of any of main's objects, which gate_start checked)", or say so in row 646's residual note. Leave the runtime text as is.

#### 2. The state paragraph leaves out "(gitlinks aside)", which the per-brief paragraph includes for the same store_check walk

**Severity:** Informational
**Location:** help `scripts/build-loop.sh:101-107` vs `:128-130`
**Move:** 7 (asymmetry)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
#             gate: WHY"); then main's commit, or a tree or blob of its tree,
#             that does not hash to its id, has a second copy in the object
#                 commit, or a tree or blob of its tree or of TREE (gitlinks
#                 aside), read back and re-hashed
```
Both scopes come from one walk, and it drops `commit` entries in both cases (`awk '$1 != "commit"'`). Only one paragraph says so. "every file the gate reads from main is one" stays true, because a gitlink is not a file the gate reads.

**Recommendation:** Add "(gitlinks aside)" after "a tree or blob of its tree" in the state paragraph. This is optional.

## What Looks Good

- **`--status` is unchanged byte for byte.** Checked by code reading: the absent-branch line builds `absent - - $disp` from the same sentinels, and `${reason:+ $reason}` matches the old `" ${kind#stopped }"` because marker_kind never returns an empty REASON. Checked by running the code: on /workspace's briefs plus a non-brief path and a new-brief path, main's script and the branch's script produce identical output (`cmp`). All 7 `--status` tests in `test/scripts/build-loop-read.bats` (T5-T8, T21, T28, U1d) pass at d10cfba8.
- **The STATUS contract fits U3a2.** Every return path of `status_fields` matches its comment. A skip sets only `line`. An ok line sets all ten keys with bare values, `-` sentinels and an empty reason. `ahead` is always a digit string (check_branch's `^$DIGIT+$` guard, or 0), so check_line's `-eq 0` is safe. BRIEF is emptied, and then holds this brief's lines, or nothing for a new brief.
- **The help states the startup order as it runs** (`gate_start`: default_gate → gate repo → store_check → reader_settings/read_settings/never_res/open_shared). It also moves `refuse state gate` before the settings, so the old exception ("comes after the settings and open briefs are read") is gone rather than restated. Every state refusal now precedes every settings read, as the header says.
- **Path lines follow the same rule as before.** The object refusal, like the missing-blob refusal that moved ahead of the checkout, prints no path lines. The checkout paragraph's "The merge's own refusals above ... come first" still describes the order.
- **One exit path now matches the help.** check_brief's `need_root` exit used to be swallowed inside `$(status_line ...)` and printed a blank verdict line. It now stops `--check` with status 1, which the Exit paragraph already promised ("can also stop part way ... with 1 (need_root)"). `--status`'s behaviour is unchanged (it always ran `status_line` in the main shell). This comes from reading the code and was not probed.
- **Every reference to the removed refusals is gone**: the help (three places), srules' doc, `PATHS_WHY=unread`, and check_line's comments. No consumer outside docs/reviews quotes the old texts.
- **The new hardening pair `core.multiPackIndex=false` is in the A15 config-pairs list**, so every logged git call carries it.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The per-brief object refusal names the tip/merge, but its second-copy scan also judges main's ids (mid-run race only) | Informational | `scripts/build-loop.sh:644, 916`, help `:126-132` | Medium |
| 2 | The state paragraph leaves out "(gitlinks aside)", which the per-brief paragraph has | Informational | help `scripts/build-loop.sh:101-107` | High |

## Overall Assessment

`--check`'s public surface after the branch is consistent with the codebase's conventions. The two new refusals follow the `refuse state WHAT: WHY` and `refuse BRIEF: ... the tip of BRANCH ...` forms. The help quotes the per-brief text word for word and states the new startup order exactly as the code runs it. The two removed refusals are gone from every place that mentioned them. `--status` output is unchanged (checked by code reading, by running both versions and by the `--status` suite). STATUS's documented shapes match every return path, so U3a2 can rely on them. i2's Finding 1, the refusal carrying from one brief to the next, is fixed and tested. Nothing is Breaking, Inconsistent or Minor. The two Informational notes are wording in the help.

## Goal-Alignment Note

**Success criterion (restated verbatim):** "a markdown report saved at the path your dispatch names, structured per your skill."
**Answered:** Yes. The report is saved at `docs/reviews/api-consistency-reviewer-review-2026-10-10-build-loop-u3a1-final.md` with `Commit: d10cfba8` at the top. It follows the api-consistency-reviewer skill's structure: baseline, name-pattern audit, findings with Severity/Location/verbatim Evidence/Confidence/Legibility-target, summary table and assessment. The dispatch's focus is covered. Every new, changed or removed output line is an audit row. The exit paths are in What Looks Good (need_root, state refusals before settings). The --help header is covered in Findings 1-2 and What Looks Good. STATUS as U3a2's input is in What Looks Good, checked path by path.
**Out of scope:** Whether the second-copy listing is complete against the store's other routes (security's question). The second-copy scan test's title names a multi-pack-index case the test lacks: that is the fact-check's item and is not re-filed here (A15 does pin the pair on every call). The settled rows 638-649.
**Escalate:** None. Findings 1 and 2 are both for-author and optional.
