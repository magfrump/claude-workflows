Commit: 43b8d7ed

# API Consistency Review: feat/build-loop-u4c (U4c, final confirming pass)

**Scope:** full branch, `git diff main...feat/build-loop-u4c` (HEAD 43b8d7ed): `skills/dev-cycle/SKILL.md` (Rules, the D6 block, step 0.1, steps 0.4, 1 and 9), `test/scripts/build-loop-orchestrator.bats`, `test/lib/d6-snippet.bash` (deleted), `scripts/lib/dev-cycle-read.sh` and `scripts/build-loop.sh` (comments), the plan, override-log rows 812-819
**Date:** 2026-10-13
**Based on:** docs/reviews/code-fact-check-report-2026-10-13-u4c-final.md (k=3); prior reports *-u4c-i1.md and *-u4c-i2.md; rubric docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4c.md

## Baseline Conventions

- **Snippet contract.** Exit 2 with one `refuse d6: WHY` line on stdout and nothing run. Exit 1 with the usage line on stderr. Otherwise the script's own status. The Rules (`SKILL.md:36-61`) treat a `refuse d6:` line and a timed-out call as stops.
- **Keyed `you: judgment` entries filed by step 0.** `other-commit-SHA12` and `main-log-refused-MAIN12` (`SKILL.md:318-322`) are keyed by the SHA. They are suppressed "unless WT's questions files hold one", which includes the archive, so an answered `keep` sticks for that SHA. Their options are numbered: "**[1] reviewed, build on it** and **[2] not yet**". The same pattern appears for `capped-STEM-N`: "**[1] keep** … **[2] drop**" (`:773`).
- **Answers are read** only through `--check-answer`, for brief `Asked:` items and merge entries (`SKILL.md:603-605`). An entry outside those sets has no reader.
- **`you: terminal` entries** (global grammar): one paste block, plus an interim line. The precedent in this file is step 1's merged-branch entry (`:386-394`), where "an open one is updated in place".
- **Closure by observation** (global rule). `image-lag` follows it: "Exit 0: an open `image-lag` entry is answered `done: …` (this diff is the observation)" (`:297-298`).

## Prior-pass closure (i2 F1-F6, rubric D1-D9)

| i2 | Status claimed | Verdict at 43b8d7ed |
|---|---|---|
| F1 image-lag has no close | Fixed (D3) | **Closed.** Exit 0 answers it `done`, with the diff as the observation. |
| F2 no paste/interim; overlaps release entry | Fixed (D3) | **Closed.** The entry has a body (C, M, the changed names), one paste and an interim. Plan `:356` makes U5's release entry its body. |
| F3 missing image file routed as a stop entry | Fixed (D5) | **Closed.** "its entry also gives the release paste below" (`:283-284`). |
| F4 unpinned, case-sensitive pathspec | Fixed (D2) / Won't-Fix (D8, row 818) | **Closed** (the pin test passes) / basis unchanged. |
| F5 step 9 `check` exit 1 | Fixed (D7) | **Closed.** "(`check` exiting 1 names entries to fix before staging)" (`:713`). Fact-check Claim 8 notes it also names files; that is wording only. |
| F6 cat-file failure elsewhere; main only | Fixed (D4) | **Closed.** "If … `cat-file -e` … fails … skip silently". M is "main's commit". |

i1 F4/F6 (row 816) and D8/D9 (rows 818/819): the basis is unchanged. The fact-check's Claim 1 says row 819's stated consequence is Incorrect. That concerns the row's text, not the surface, and I do not re-file it here (see Informational F5).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `refuse d6: X is missing` | refusal line | `refuse d6: X is not a regular file`, `refuse d6: X is not root-owned…` | `SKILL.md:243,259` | Consistent (i2) |
| `d6: the first argument is build-loop.sh, dev-cycle.sh or questions.sh` | usage line | the old two-script line | deleted `test/lib/d6-snippet.bash` | Consistent; only the tests consume it (`bats:291`) |
| SCRIPT `questions.sh` | snippet argument | `build-loop.sh`, `dev-cycle.sh` | `SKILL.md:245` | Consistent: every list of the three agrees (Rules, header, usage, section intro) |
| `-u QUESTIONS_LIVE -u QUESTIONS_ARCHIVE` | launch env | `-u BASH_ENV -u ENV -u DEV_CYCLE_SCRUBBED` | `SKILL.md:262`; `scripts/questions.sh:85-86` | Consistent |
| `image-lag` | questions slug (`you: terminal`) | merged-branch terminal entry (unnamed slug, updated in place) | `SKILL.md:386-394` | Consistent: a single-instance entry, rewritten in place, closed by observation |
| `image-off-main` | questions slug (`you: judgment`) | `other-commit-SHA12`, `main-log-refused-MAIN12`, `capped-STEM-N` | `SKILL.md:318-322`, `:773` | **Inconsistent**: unkeyed, suppressed only while open, unnumbered options, no reader of its answer (F1, F2) |
| `d6_copy OPT [trust]`, `opt_copy DIR` | test helpers | `d6_setup`, `d6_is WANT`, `shim` | `bats:234-252` | Consistent (snake_case verb-noun helpers) |

## Findings

#### F1. `image-off-main` re-files after every `keep`, and nothing closes it after a rebuild

**Severity:** Inconsistent (introduced by this branch, 43b8d7ed)
**Location:** `skills/dev-cycle/SKILL.md:288-290`
**Move:** 2 (slug shape), 3 (consumer contract), 7 (asymmetry: `image-lag` closes, `image-off-main` does not)
**Confidence:** High
**Legibility-target:** for-author

Precedent: SHA-keyed step-0 judgment slugs suppressed by any entry in the questions files (the archive included), so a `keep` holds for that SHA. Used in `skills/dev-cycle/SKILL.md:318-322` (`other-commit-SHA12`, `main-log-refused-MAIN12`).

Evidence: "file one `you: judgment` entry `image-off-main` naming C, unless one is open (options: rebuild from main, the paste below; or keep)."

The slug carries no key, and the only thing that suppresses it is "unless one is open". The orchestrator reads answers only for `Asked:` items and merge entries (`:603-605`), so it never reads a `keep` on this entry. Once the user answers `keep` and step 1's `questions.sh archive` moves the entry out, the next iteration's step 0.1 sees none open and files `image-off-main` for the same C again. The `keep` option therefore holds for one iteration only. The other direction has the same gap. After a rebuild from main, step 0.1 takes the `diff --quiet` branch and closes only an open `image-lag`. An open `image-off-main` for the old C stays OPEN, a stale ask. By contrast, its sibling `image-lag` (`:297-298`) and the SHA-keyed step-0 entries each have a defined end state.

**Recommendation:** Key it as `image-off-main-C12`, and suppress it when WT's questions files hold one for that key, as `:321` does. Also add the close: when C is on main, answer an open `image-off-main` `done`. Or say that `keep` is read nowhere and the entry closes only when C changes.

#### F2. `image-off-main`'s options are unnumbered, and the "rebuild from main" paste fails as written when the host checkout is off main

**Severity:** Minor (introduced by this branch)
**Location:** `skills/dev-cycle/SKILL.md:290`, `:295-296`
**Move:** 2 (option naming), 3
**Confidence:** Medium
**Legibility-target:** for-author

Precedent: numbered bold options for orchestrator-filed judgment entries, used in `skills/dev-cycle/SKILL.md:322` ("**[1] reviewed, build on it** and **[2] not yet**") and `:773` ("**[1] keep** … **[2] drop**").

Evidence: "(options: rebuild from main, the paste below; or keep)" and "the paste `cd A && test "$(git rev-parse HEAD)" = M && ./devcontainer-config/install.sh`".

The global grammar expects answers like `Q-NNN: [2]`, and the answer reader maps `1`/`keep` and `2`/`drop` by number (`:607-608`). This entry gives prose options with no numbers. The entry exists precisely because the host checkout's HEAD is not on main, so the paste's `test … = M` fails there by construction. That is fail-closed and safe, but the "rebuild from main" option does not tell the user to check out main on the host first.

**Recommendation:** Write "**[1] rebuild from main** (on the host, check out main, then the paste) and **[2] keep**".

#### F3. Step 0.1's no-manifest case reads as "skip silently", not "note it"

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:286-288`, `:298-299`
**Move:** 3 (documented outcome vs reachable outcome)
**Confidence:** Medium (from fact-check Claim 6; not re-executed)
**Legibility-target:** for-author

Evidence: "If `hg -C MAIN_WT cat-file -e 'C^{commit}'` fails, the image was not built here: skip silently." … "A missing `.manifest` or line, or any other exit: note it in the record."

The text tests `cat-file` first. With no `commit=` line, C is empty, `cat-file -e '^{commit}'` fails, and the silent skip fires before the "note it" rule can. The two documented outcomes overlap, and the orchestrator has to pick one. "Was not built here" also says more than the test shows: the test shows only that the repository does not hold C.

**Recommendation:** Read the manifest first ("no `.manifest` or no `commit=`/`assembled_from=` line: note it"), then run the `cat-file` test. Change "was not built here" to "is not in this repository".

#### F4. The plan never names `image-off-main`

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:344` (U4c as-built note), `:432` (Risks)
**Move:** 3 (documentation drift)
**Confidence:** High

Evidence: ":432: step 0.1 files an `image-lag` entry when main's GATE_CODE paths differ from the image's `.manifest` commit". The as-built note says "step 0.1 files `image-lag` (architecture 1, security F3)".

43b8d7ed added a second step-0.1 entry and a fail-closed paste. The plan, which is the design of record that U5's release entry builds on, describes only `image-lag`. Fact-check Claims 3 and 6 record the same and nearby stale plan text: `:77` "never trusts a file the uid can write", `:156` F38 "compares hashes", and `:394` T27 "refuse from main's copy".

**Recommendation:** Add `image-off-main` and the HEAD check in the paste to the U4c as-built note and to Risks. Refresh `:77`, `:156` and `:394` in the same edit.

#### F5. Row 819's stated consequence is Incorrect (fact-check Claim 1)

**Severity:** Informational
**Location:** `docs/reviews/override-log.md:819`; rubric D9
**Move:** 3 (documentation of behaviour)
**Confidence:** High (fact-check, k=3 unanimous)
**Legibility-target:** for-orchestrator-synthesis

Evidence (fact-check): "a failed `cat-file -e 'C^{commit}'` skips silently; a missing commit exits 128". Row 819 says "deleting C's objects turns the check into a record note".

The row's Won't-Fix reason still holds: the check is advisory and the scenario is Q-103's class. Only the described consequence is wrong. The fix is an amending row, not a code change. The surface itself is not affected.

**Recommendation:** Append an amending override row, and correct D9's wording in the rubric.

## What Looks Good

- **One canonical copy.** The block lives only in `SKILL.md`, and the tests extract it with awk. T33 asserts one `bash -s` line and one `D6` line, and that `test/lib/d6-snippet.bash` is gone. The remaining references to the old path are historical: the checkpoint, the archived Q-140 and the plan's U3b3 row.
- **The three-script set is consistent everywhere.** The Rules' call and timeout sentences, the block's header and usage line, the section intro, and step 1's `questions.sh init`/`archive` through the block all list the same three scripts.
- **The refusal vocabulary is complete and tested.** Each header case has its own `refuse d6:` string, and the tests run the real `own()` text, not only the stub's.
- **The semantic change is deliberate and documented.** The gate now runs the image copy in claude-workflows too, per the user's Q-140 [1]. This is the one consumer-visible behaviour change (a merged gate fix takes effect only at the next release). The Rules, the header, the GATE_CODE comment, plan D5 item 3, D6, Risks and Rollback all say so, and step 0.1 makes the lag observable.
- **`image-lag` now matches the `you: terminal` grammar.** It has one paste, an interim, rewrite in place and closure by observation. Its path list is pinned to GATE_CODE by a test.
- bats `test/scripts/build-loop-orchestrator.bats`: 26/26 pass at 43b8d7ed (run in this pass).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `image-off-main` unkeyed: re-filed after every archived `keep`, never closed after a rebuild | Inconsistent (this branch) | `SKILL.md:288-290` | High |
| F2 | `image-off-main` options unnumbered; the rebuild paste fails off main without saying to check out main | Minor (this branch) | `SKILL.md:290,295-296` | Medium |
| F3 | No-manifest case: skip silently fires before "note it" | Minor (this branch) | `SKILL.md:286-299` | Medium |
| F4 | Plan omits `image-off-main`; older stale plan text | Minor (this branch) | plan `:344`, `:432` (+ `:77`, `:156`, `:394`) | High |
| F5 | Row 819 / D9 consequence Incorrect | Informational | `override-log.md:819` | High |

## Overall Assessment

**No finding is Breaking.** One finding is **Inconsistent and introduced by this branch**: F1, the `image-off-main` entry added in 43b8d7ed. Its slug is not keyed like the step-0 siblings it imitates, and no step reads its answer. In practice its `keep` lasts one iteration, and after a rebuild it stays open as a stale ask. The failure is noise in the questions file, never a wrong merge, because step 0.1 is advisory and never stops the iteration. All i2 findings are closed. The rest of the D6 surface is consistent: the three-script set, the refusal strings, the environment strips, the one canonical copy and the `image-lag` entry. F1-F4 are text fixes inside step 0.1 and the plan.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report saved to /workspace/.claude/wt-build-loop-u4c/docs/reviews/api-consistency-review-2026-10-13-u4c-final.md (first line `Commit: 43b8d7ed`), per the skill. State clearly whether any finding is Breaking or Inconsistent AND introduced by this branch.
- Answered: yes. None Breaking; one Inconsistent introduced by this branch (F1, `image-off-main`, 43b8d7ed); i2 F1-F6 closed; bats 26/26.
- Out of scope: the trust wording and the same-uid residual (security); root and host runs (fact-check Claim 9, Unverifiable); override rows 812-818, which were not re-litigated.
- Escalate: F1 (whether `image-off-main` gets a key and a close, or a sentence saying `keep` is not read) is for the orchestrator to decide before the merge. F5 needs an amending row, which is the orchestrator's to write.
