Merge branch 'feat/build-loop-u4a': --land-cycle lands the orchestrator's chore branch from the main it checked, judging the merge; cycle rules bound to the cycle's own paths and briefs

## What this does

U4a of the build-loop handoff (plan step 10's U4 split note and its As-built note), in `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` and `test/scripts/build-loop-orchestrator.bats`:
- **`--land-cycle --main SHA [--answered Q-NNN]...`** (gated; `state_start`): lands the orchestrator's committed `chore/dev-cycle-DATE[-HHMM]` HEAD. It refuses unless SHA is main's commit (the one `--cycle-diff` checked: a compare-and-swap base) and the index equals HEAD's commit. It judges merge-tree's merge of HEAD into main against main with the cycle rules (so a rename git pairs into a new questions file, or a fence pair capturing main's answer, is judged: row 753) and requires a cycle record holding `Branch: B` (what `--main-log` reads as chore). Then commit-tree with `Merge branch 'B'` (`chore_msg`) and `land`'s move: update-ref from SHA, or `merge --ff-only` in the worktree that has main checked out; no hook runs (rows 719, 749, 752). Prints `landed B HEAD TREE NEW`. It replaces pr-prep's hand merge for the chore branch.
- **Cycle rules** (`cycle_rules BASE SIDE`, `questions_rules`; shared by `--cycle-diff` and `--land-cycle`), every path meets them (row 745):
  - only the cycle's own files, a `.md` under `docs/` or `README.md`, compared lower-cased (a loop's commit carried on the chore branch refuses);
  - no gate code (GATE_CODE), no file the lib's `truthrule` reads as truth but the cycle's own, no cycle file spelled in another case;
  - a brief's first `Asked:` line only extended; each added item exactly `Q-NNN` or `Q-NNN@SHA`, naming an entry the questions files gain whose heading slug is `WORDS-STEM-N` for that brief, added once across the briefs; a brief deleted or renamed with an `Asked:` line refuses, and so do two changed brief paths with one file name on a side.
  The questions guard (main changed the questions files since the fork point) stays `--cycle-diff`'s.
- **`isrecord`** (lib) is the one cycle-record name test (`cycle-YYYY-MM-DD.md`, row 725); `--main-log`'s chore class now reads only that name (narrower than U3b2's `cycle-*.md`); `chore_record` is shared by `log_class` and the land.

**Workflow provenance:** RPI (plan revision 4, step 10; U4 split before code at 774a0eef) → pr-prep: three iterations, the iteration-4 gate's escalate to a confirming pass, which stopped the merge (Q-141), and a second confirming pass under Q-141's interim [1].
← carried from RPI: D7, D11 and D13; rows 719, 722, 725, 745, 747, 749, 752 and 753 (U3b2 and U3c hand-offs).

**Corrections to branch commit bodies:**
- 722c2e10's `--expect MAIN` became `--main` (70d24331); its "no hooks run: rows 719, 749, 752" credits row 749 wrongly (the land judges HEAD's commit; the chore commit's own hooks are U4b's).
- 70d24331's `asked_rule` was inlined into `cycle_rules` (4df6ec58); its class list after "but the cycle's own" reads as cycle files.
- 4df6ec58's "by floor_why's prose": the settings class uses `cycle_rules`' own string.

## Reviewer's path — start here

1. The `--land-cycle` block and the end of the `--cycle-diff` block in the header of `scripts/build-loop.sh`: the contract U4b's SKILL.md names.
2. `land_cycle`, `cycle_rules`, `questions_rules` and `cycle_diff` above the mode dispatch; then `land`'s cycle branch and `chore_msg`/`chore_record` beside `log_class`.
3. `isrecord` and `truthrule`'s comment in the lib.
4. The last three tests of `build-loop-orchestrator.bats`.

## How to test

- Suites, run serially, 292 in all: orchestrator 27, read 20, merge 12, dispatch 4, check 146, dev-cycle 79, fixtures 2+2. shellcheck is clean, and `scripts/health-check.sh` passes on the branch tip.
- Each U4a case fails on the code before its fix (checked by the fact-check replicates: skipping `cycle_rules` in the land, Asked: by full path, the hyphen-anchored slug, the case-sensitive allowlist).
- `--cycle-diff` ≈ 0.4 s and `--land-cycle` ≈ 0.5 s on a clone of this repo.

## Areas of uncertainty

- **Q-141 is open for the user** (interim [1] applied: merged after the second confirming pass). [2] would revert the slug and lower-casing fix; [3] would move the binding to a `Brief:` line in U4b's entry grammar.
- **U4b owes** (override rows dated 2026-10-13 on this branch): name the cycle rules and each refusal's remedy; step 9 lands with `--land-cycle --main MAIN_SHA`; run `--check-fix` on every in-cycle fix before staging (docs an instruction file imports, a directory at an instruction file's name, symlinks); the record template ("one per day, updated in place"); blocked-entry slugs `WORDS-STEM-N`; row 674's merge-entry heading rule with GATE_CODE pinned by a test.
- **Interim /away calls:** the U4 split; the chore land as a gated mode (not pr-prep's hand merge); the allowlist as the paths an in-cycle fix may touch (wider than `--check-fix`); one brief per new ID and the `WORDS-STEM-N` slug binding.

Review converged as follows:
- **Iteration 1** (k=1, full panel): no red; 3 Must Address fixed: Asked: IDs added were unchecked, truth files landed unjudged (security), `--expect` named two different commits (api).
- **Iteration 2** (k=1, fix range, full panel): a behavioral Incorrect at medium confidence (an Asked: item checked only at its start) and four security Mediums (one ID on several briefs, a duplicate-name map collision, case-spelled cycle files): all fixed.
- **Iteration 3**, the final pass (k=3 at 74% agreement, full panel, Fact-Check Gate fix-first on a message-only Incorrect): two security Mediums (a carried commit landed any path; an Asked: ID not bound to its brief), fixed.
- **Confirming pass** (k=1 fact-check with 5 submitted claims, 4 Verified executed, 1 doc-only Incorrect; security): a Medium residue of the binding (D1) stopped the merge: Q-141.
- **Second confirming pass** (Q-141 interim [1]; k=1 fact-check, security): no Must Fix or Must Address.
- Rubric: `docs/reviews/code-review-rubric-2026-10-13-feat-build-loop-u4a.md`. 21 override rows dated 2026-10-13 for this branch. 390 changed code lines.

Single-sample review; absence of findings is not an attestation.

Confidence: medium
Notes: merged under Q-141's interim [1] (the Q-138 precedent); the user may still answer [2] or [3].

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_019UpfX7SZK8HDDreexNffjp
