Commit: b1a6f0a2

# API Consistency Review — feat/build-loop-u4a, final confirming pass

**Scope:** full branch `git diff main...HEAD` at b1a6f0a2: `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-orchestrator.bats`, plan "Script interface" and U4a notes. Public surface judged: `--land-cycle` (`--main SHA`, `--answered`, `landed B HEAD TREE NEW`, `refuse HEAD: WHY`, `refuse PATH: WHY`, exit codes, usage text), `--cycle-diff`'s refusal lines, `--main-log`'s narrowed record name.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4a-final.md` (k=3 merge at c4e36d1d; its one Incorrect, claim 1, is fixed by d46cd00f: checked below). Earlier reports: `api-consistency-review-2026-10-13-u4a-i1.md`, `-i2.md`.
**Probes:** `/tmp/u4a-apif-*` (parser cases for `--land-cycle`/`--cycle-diff`, run with bash; the five `--cycle-diff`/`--land-cycle` bats tests, all `ok`); removed, none left.

## Baseline Conventions

Surveyed `scripts/build-loop.sh` header (:141-262 for `--main-log`, `--cycle-diff`, `--land-cycle`; :392-406 `--merge`'s `merged` line), the parser (:528-552), land's `MERGE_WHY` strings (:1444-1564), `floor_why` and `truthrule` in `scripts/lib/dev-cycle-read.sh` (:1899-1946, :2016-2031), `scripts/dev-cycle.sh:225` (record window reader), `skills/dev-cycle/SKILL.md:362` (record writer), and the plan's "Script interface" (`docs/working/plan-build-loop-handoff.md:201-219`).

- **Modes:** read modes are nouns, acting modes verbs; gated modes run `state_start` first.
- **Output lines:** a leading keyword then space-separated fields (`ok BRIEF TIP TREE`, `merged BRIEF TIP TREE NEW`, `main MAIN N`); refusals `refuse SUBJECT: WHY` (SUBJECT a brief, `state WHAT`, `main-log`, `HEAD`, `index` or a path); the header defines each field.
- **Exit codes:** 0 success, 2 any refusal, 1 usage or fatal environment error (stderr only).
- **Ids:** full 40/64 lower-hex only, a usage error otherwise; value flags named for their referent (`--expect SHA` a tip, `--approved Q-NNN`, `--answered Q-NNN`, `--dir DIR`).
- **Wording of truthrule's class words:** each caller words them (lib :1910 "Each caller words the words"); `floor_why` is the shared prose.
- **Plan:** "Read modes:", "Gate:", "Dispatch:"; read modes exit 0 when answered, writing modes exit 2 on any refusal.

## Earlier findings: resolution

| Report # | Finding | Status at b1a6f0a2 | Evidence |
|---|---|---|---|
| i1-1 | `--expect` bound main under `--land-cycle` | Resolved | Parser :538-552 takes `--main` only under land-cycle; probe: `--land-cycle --expect <40hex>` → usage, exit 1. |
| i1-2 | Shared refusals said "index" under land | Resolved | `refuse index: the questions files could not be listed` is in `cycle_diff` only; `k="$side"` gives "its merge copy". |
| i1-3 | Header refusal list omitted read failures | Resolved | Header "or a read that fails (HEAD's commit, the merge, its paths)". |
| i1-4 | `landed` fields / reflog undocumented | Resolved | Header defines B, HEAD, TREE, NEW, the reflog "build-loop: cycle land of B" and, new since c4e36d1d, "with git's ": Fast-forward" after it on the fast-forward path" (fact-check claim 4 addressed). |
| i1-5 | No plan bullet; `entry` line absent | Resolved | Plan :212 bullet; as-built note :339 records the `entry` line's move to U4b. |
| i1-6 | Collapsed usage message | Kept (accepted) | Probe: every malformed case prints "--land-cycle takes --main SHA (the default branch's full commit id), once, and --answered Q-NNN, one ID each"; no `--main` prints "--land-cycle needs --main SHA, ...". |
| i1-7 | `--cycle-diff` narrows; U4b documents | Carried to U4b | No caller yet (`skills/`, `workflows/`). |
| i2-1 | Truth refusal printed raw class word | Resolved | :1919-1921 words it by `floor_why` (settings by its own string); test pins "an instruction or prompt file, which sessions load from the checkout". |
| i2-2 | Plan filed `--land-cycle` under "Read modes:" | Resolved | Plan :211-212, under "Gate:" before `--check`. |
| i2-3 | Empty Asked: item read "adds , which"; "first" dropped | Resolved | :1972 `adds \"$x\", which is not Q-NNN or Q-NNN@SHA` (test pins `adds "", which ...`); every Asked: refusal says "its first Asked: line". |
| i2-4 | Questions guard pre-empts other refusals, undocumented | Resolved | Header: "That refusal is printed alone." |
| i2-5 | Plan `--cycle-diff` bullet omits row 745 rules | Partly resolved | :209 names iteration 1's rules; iteration 2's do not appear: Finding 2. |
| fact-check claim 1 | "another brief's Asked: line adds too" for a same-brief repeat | Resolved (d46cd00f) | :1976 "which is added more than once (by this or another brief's Asked: line)"; header "be added once (by one brief, once)"; test :454 pins it. |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--land-cycle` | CLI mode | `--merge`, `--cycle-diff`, `--check` | `scripts/build-loop.sh:6-16` | Consistent — acting verb mode, shares `cycle` with its companion |
| `--main SHA` | CLI flag | `--expect SHA`, `--approved Q-NNN`, `--dir DIR` | `scripts/build-loop.sh:528, 552-560` | Consistent — named for its referent; full-hex usage check as `--main-log`/`--expect` |
| `--answered Q-NNN` (land) | CLI flag | `--cycle-diff --answered` | `scripts/build-loop.sh:538-552` | Consistent — one parser branch serves both modes |
| `landed B HEAD TREE NEW` | output line | `merged BRIEF TIP TREE NEW`, `ok BRIEF TIP TREE` | `scripts/build-loop.sh:392-406` | Consistent — past-tense keyword, subject, second parent, tree, new commit; HEAD for TIP is explained ("its commit (the merge's second parent)") |
| `refuse HEAD: WHY` (land) | refusal | `--cycle-diff`'s `refuse HEAD:`; `--merge`'s `refuse BRIEF: $MERGE_WHY` | `scripts/build-loop.sh:1874-1876, 1444-1564` | Consistent — land's `MERGE_WHY` texts are mode-neutral |
| `refuse HEAD: the default branch is at X, not --main's Y; ... land with --main X` | refusal | `refuse BRIEF: the tip of BR is X, not the expected Y` | `scripts/build-loop.sh` (`--check`'s CAS refusal) | Consistent — actual then given, with the retry |
| `refuse PATH: the gate's own code; ...` / `...: <floor_why>; an in-cycle fix never edits it (--check-fix refuses it too)` | refusal | `--check`'s deny prose, `--check-fix`'s list | `scripts/lib/dev-cycle-read.sh:2016-2031` | Consistent — shared prose |
| `refuse PATH: one of the dev cycle's own files, spelled in another case, ...` | refusal | `floor_why cycle` "one of the dev cycle's own files" | `scripts/lib/dev-cycle-read.sh:2020` | Consistent |
| `refuse PATH: its first Asked: line ...` (four forms) | refusal | each other; header "A brief's first unfenced "Asked:" line" | `scripts/build-loop.sh:1958-1976` | Consistent |
| `refuse PATH: it is deleted` | refusal | `edited other than by appending`, `a side is not a regular file` | `scripts/build-loop.sh:1944` | Consistent (accepted at i1) |
| `isrecord` | lib predicate | `isbrief`, `isclosed`, `anybrief` | `scripts/lib/dev-cycle-read.sh:240-246` | Consistent |
| `chore_msg`, `chore_record`, `cycle_rules`, `questions_rules`, `land_cycle`, `asked`, `LAND_MAIN` | internal | `gate_msg`, `cycle_diff`, `log_class`, `EXPECT` | `scripts/build-loop.sh` | Consistent (not public) |

## Findings

#### 1. `--main-log`'s chore class narrows to `cycle-YYYY-MM-DD.md`, but the plan's `--main-log` contract still says `cycle-*.md` and no note records the narrowing

**Severity:** Minor
**Location:** `scripts/build-loop.sh:163` (header), `scripts/lib/dev-cycle-read.sh:246` (`isrecord`), `docs/working/plan-build-loop-handoff.md:326` (U3b2 as-built), `:339` (U4a note)
**Move:** 3 (documentation drift), 6 (narrowed accepted input)
**Confidence:** High
**Legibility-target:** for-author (U4b's SKILL.md author reading the plan's `--main-log` contract)

Evidence (verbatim): header now "a cycle record the merge adds or changes (docs/working/cycles/cycle-YYYY-MM-DD.md, mode 100644)"; `chore_record` uses `isrecord` (`^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$`), where main's log_class matched `^docs/working/cycles/cycle-[^/]+\.md$`. Plan :326, the U3b2 as-built note that "supersedes the "Script interface" `--main-log` bullet", still reads "a changed docs/working/cycles/cycle-*.md (mode 100644) holding "Branch: B"". The U4a note (:339) and 722c2e10's body say only "the record stays `cycle-YYYY-MM-DD.md`, so dev-cycle.sh's window reader does not change", which describes the writer, not that `--main-log` now reads a `cycle-2026-10-13-0900.md` or `cycle-notes.md` record's merge as `other`. No honest producer is affected (SKILL.md:362 and dev-cycle.sh:225 use the dated name; the fact-check executed the narrowing), so nothing breaks; the plan simply carries two record-name contracts for one class.

**Recommendation:** One clause in the U4a as-built note: "`--main-log`'s chore record narrows to `cycle-YYYY-MM-DD.md` (isrecord; supersedes U3b2's `cycle-*.md`)".

#### 2. The plan's `--cycle-diff` bullet stops at iteration 1's rules and lists only `refuse PATH`

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:209`
**Move:** 3 (documentation drift)
**Confidence:** Medium (the header is the contract; fact-check claim 5, Mostly accurate)
**Legibility-target:** for-author

Evidence (verbatim): "`--cycle-diff [--answered Q-…]` → `ok`, or `refuse PATH: why` (exit 2); ... U4a adds rules every path meets: no gate code, no truthrule file but the cycle's own, and a brief's Asked: line only extended by entries the change files." Not named: exact `Q-NNN`/`Q-NNN@SHA` items, one brief per added ID, two changed paths with one brief name refusing, a case-spelled cycle file refusing; and the `refuse HEAD` / `refuse index` subjects the header documents. The U4a as-built note (:339) does name iteration 2's rules, so the plan is complete overall, just not in the interface list.

**Recommendation:** Point the bullet at the header ("see the script header for the full rule list") or leave to U4b's text; no code change.

#### 3. The `landed` line's reflog text is header contract but pinned by no test

**Severity:** Informational
**Location:** `scripts/build-loop.sh` header (`--land-cycle`, "its reflog entry reads ..."); `test/scripts/build-loop-orchestrator.bats:474-496`
**Move:** 3 (test drift)
**Confidence:** High (fact-check Escalations)
**Legibility-target:** for-author

Evidence: the land test asserts the `landed` fields, parents, tree, message and `--main-log`'s `chore` line, but not `git reflog` for main ("build-loop: cycle land of B", or with ": Fast-forward" in W) nor the absence of hooks; the fact-check's probes executed both. `--merge`'s documented reflog text is the precedent for treating this as surface.

**Recommendation:** A one-line `git reflog -1 --format=%gs main` assertion on each path in the existing test, in this unit or a later one.

## What Looks Good

- `--land-cycle` matches the script's grammar throughout: verb mode, `landed ...` parallel to `merged ...`, `refuse SUBJECT: WHY`, exit 0/2/1, full-hex-only `--main`, gated by `state_start`.
- One parser branch and one `cycle_rules BASE SIDE` serve `--cycle-diff` and `--land-cycle`, so the same `--answered` IDs and refusal texts apply to both, with SIDE making "its index copy"/"its merge copy" true per mode.
- Every refusal reachable from `land_cycle` has subject `HEAD` or a path, as the header and plan bullet say; land's `MERGE_WHY` texts read correctly under either mode.
- `chore_msg` and `chore_record` are the one writer and reader of what `--main-log` calls chore; the land refusal names `--main-log`'s consequence ("so --main-log would read it as other").
- Truth-file refusals now use the shared `floor_why` prose, so `--check`, `--check-fix` and `--cycle-diff` speak one vocabulary.
- The repeated-ID refusal and header now agree ("added more than once", "added once (by one brief, once)").

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `--main-log` chore record narrowed to `cycle-YYYY-MM-DD.md`; plan U3b2 contract still `cycle-*.md`, narrowing unrecorded | Minor | `docs/working/plan-build-loop-handoff.md:326, 339`; `scripts/build-loop.sh:163` | High |
| 2 | Plan `--cycle-diff` bullet omits iteration 2's rules and HEAD/index subjects | Informational | `docs/working/plan-build-loop-handoff.md:209` | Medium |
| 3 | `landed`'s documented reflog text not pinned by a test | Informational | `test/scripts/build-loop-orchestrator.bats:474-496` | High |

## Overall Assessment

The public surface is consistent with the script's conventions, and every actionable finding from iterations 1 and 2 (and the final fact-check's Incorrect) is resolved in code and header; i1-6 was accepted and i1-7 is U4b's. What remains is documentation: the plan's U3b2 note still describes `--main-log`'s record as `cycle-*.md` after the narrowing, the `--cycle-diff` plan bullet summarises only iteration 1's rules, and the reflog text is documented but untested. None affects a consumer (U4b is the first), none needs a code change, and all are fixable in place or by U4b.

## Goal-Alignment Note

- **Success criterion (verbatim from the brief):** "a markdown report saved at the exact path your own prompt names, structured per your skill."
- **Alignment:** saved at `docs/reviews/api-consistency-review-2026-10-13-u4a-final.md`, first line `Commit: b1a6f0a2`, with the skill's sections (Baseline, Name-Pattern Audit, Findings with Severity, Location, Evidence, Confidence and Legibility-target, What Looks Good, Summary Table, Overall Assessment) and a resolution table for every i1/i2 finding. Probes ran under `/tmp/u4a-apif-*` with timeouts and were removed; nothing else in /workspace or the worktree was written.
