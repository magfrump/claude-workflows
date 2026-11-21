# Research: the dev cycle lists code landings on main that came outside the build loop

Date: 2026-11-20 · Brief: `docs/working/briefs/2026-11-20-out-of-loop-landings.md` · Branch: `feat/out-of-loop-landings` · Base: 977c3f70

Failure-pattern grep: FP-074

FP-074 (null content parsed as clean, "findings: none") is the pattern this section must not repeat: a commit or rubric the section cannot read must print as unread, never as "none". FP-064 (rubrics overwritten each run) bears on the rubrics read, which `rubric_lines` already handles (newest dated file per slug). No other entry names landings, fast-forwards or the digest's sections.

## What was read

- `docs/working/research-2026-11-20-review-gap-ba-compare.md`, rows 1, 2 and 7 and "For the dev cycle" brief 1: five code landings since 21097afa (44000c6d, 386ccfa3, 22735b6e, 9e7c0542, ded17c89), four with no rubric; key on paths, not prefixes.
- `scripts/dev-cycle.sh`: sections 1 to 8; section 6 ("Merges with code but no docs") walks `merges_full` (first-parent merges filtered by `%cs >= SINCE`) and diffs each against its first parent. The new section reuses that window rule, and widens it to non-merge commits, since two of the five landings are direct commits.
- `scripts/lib/rubric-check.sh` `rubric_lines`: needs `gate_git`, `fp_blob`, `showpath`, `MAIN_SHA`, `GATE_TMP` and `check_answer`. Its stale check counted fix commits against `MAIN_SHA`, which for a commit already on main lists nothing and would print `unread ... could not be listed` for every rubric.
- `scripts/build-loop.sh` `gate_msg` (the trailer `Build-loop-gate: STEM` on line 3 of a build-loop merge) and `log_class` (`--main-log`'s full check).
- `skills/dev-cycle/SKILL.md` step 0.4 (sections to steps) and step 4 (spot-check, section 6's merges); the record template, which `scripts/lib/migrations.sh` fingerprints.
- `docs/constraints.md` H1, H2, S3, S6, S8.

## Design

### Where the code lives (3 options: divergent design)

| Option | What it means | Constraints |
|---|---|---|
| [A] Inline in `scripts/dev-cycle.sh` | about 80 lines in the digest itself | S8: the file is 746 lines already; growth works against the ~400 cap |
| [B] New `scripts/lib/landings.sh`, sourced by the digest | the section and the helper names `rubric_lines` needs; the digest checks the lib is present and parses, as it does `lib/migrations.sh` | S8 (small unit, one `git revert`), S3 (reuses `rubric_lines`), H1 (under `scripts/lib/`, already in GATE_CODE), H2 (a missing lib prints NOT checked) |
| [C] A `build-loop.sh` mode (extend `--main-log`) | the gate script prints rubric lines for `other` commits | the brief asks for a digest section; build-loop.sh is over 2000 lines (S8), and its gated modes are out of scope |

Path A: [B] dominates. It keeps every hard constraint and is the only option that does not grow a large file.

### Other choices (one line each)

- Helper names for `rubric_lines`: shims in `landings.sh` (`gate_git` over the digest's hardened git, `fp_blob` and `showpath` with build-loop.sh's contracts) rather than moving build-loop.sh's copies into a shared lib, which would edit `--check`'s code (out of scope). Residual (S3): two short helpers (about 12 lines) exist twice; a later unit can move them to one lib.
- Stale-check base: `rubric_lines` takes an optional sixth argument BASE (default `MAIN_SHA`, so build-loop.sh is unchanged); the digest passes the landing's first parent. Overriding `MAIN_SHA` instead would have made `check_answer` read questions from that parent.
- What counts as a build-loop merge: two parents and a message line `Build-loop-gate: X`, as the brief words it, not `log_class`'s full check (S1: the section lists honest slips; a merge made to look like the gate's is `--main-log`'s concern).
- A root commit: compared with the empty tree (`diff-tree --root`), so a fresh repo's first code commit is listed.
- Unreadable input (H2): a commit whose paths or message cannot be read prints a `Not read` line and is counted apart; an empty `rubric_lines` output prints as `unread`; a missing or unparseable lib prints `**Out-of-loop landings were NOT checked**`.
- Field separator: US (`%x1f`), not a tab: tab is IFS whitespace, and a root commit's empty `%P` collapsed into the subject (found by the tests).
- Record template: not changed. Step 4's text says where the count goes on the `4.` line; editing the template would change the record convention's fingerprint and need a migration line in `scripts/lib/migrations.sh` for no gain.
- Section number 6b: next to section 6, since both feed step 4; the numbering of later sections is unchanged.

### Observable (S6)

The count per cycle on the `4.` line, and what the post-hoc reviews it files find. It can come out negative: the skill says to remove the step and the section if the count is 0 for ten full cycles in a row.

### Cost

On this repo, a window since 2026-11-14 (about 200 first-parent commits) adds about 3 s to the digest (one `diff-tree` per first-parent commit in the window). A single `git log --name-status` pass would be faster but harder to parse with `-z`; not worth it at one digest per iteration.

## Doc changes

- `scripts/dev-cycle.sh` header: what section 6b lists, and the temp directory it uses.
- `scripts/lib/rubric-check.sh` header and `rubric_lines` comment: the second caller and BASE.
- `skills/dev-cycle/SKILL.md`: step 0.4 names section 6b as step 4's input; step 4's "Out-of-loop landings" paragraph files each landing as a roadmap item, records the count on the `4.` line, and removes itself after ten zero cycles.
- This doc.

## Verification

- `test/scripts/dev-cycle-landings.bats` (10 cases): a hand commit to `skills/` with no rubric (listed, `none`); a hand merge whose rubric has an open amber (row listed); a `docs(...)` commit changing a skill (listed); a build-loop merge and a docs-only commit (not listed); a merge naming the trailer only in its subject (listed); a symlinked and a table-less rubric (each `unread`, never `none` or `clean`); a commit whose tree is missing (`Not read`); a commit before the window (not listed); a missing `lib/landings.sh` (NOT checked); a root commit adding code (listed).
- Live run on this repo, `--since=2026-11-14`: lists exactly 22735b6e, 9e7c0542, ded17c89, 386ccfa3 and 44000c6d, the five the review-gap research named, with `none` for the four that left no rubric.
- `scripts/confine-tests.sh --probe` exit 3: "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the touched suites ran unconfined, with the hermeticity lint.
