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

- Helper names for `rubric_lines`: shims in `landings.sh` (`gate_git` over the digest's hardened git, `fp_blob` and `showpath` copied from build-loop.sh) rather than moving build-loop.sh's copies into a shared lib, which would delete them from build-loop.sh's `--check` path (out of scope). Residual (S3): two short helpers exist twice; a bats case holds the copies identical (review A9), and moving both beside `rubric_lines` is a TODO for a build-loop unit. `gate_git` stays per caller: the digest's runs in the checkout, so repo config applies, and it pins `i18n.logOutputEncoding=UTF-8`, the one key found to change what these reads print (review R1, FP-188).
- Stale-check base: `rubric_lines` takes an optional sixth argument BASE (default `MAIN_SHA`, so build-loop.sh is unchanged); the digest passes the landing's first parent. Overriding `MAIN_SHA` instead would have made `check_answer` read questions from that parent.
- What counts as a build-loop merge: a merge whose message has a blank line 2 and `Build-loop-gate: X` as line 3, where `gate_msg` writes it (review A4, A8: matching any line dropped a hand merge whose subject started with the trailer, or whose body quoted one), not `log_class`'s full check (S1: the section lists honest slips; a merge made to look like the gate's is `--main-log`'s concern). A third reader of the trailer now exists; `gate_msg`'s comment names only `log_class`, and editing it would touch build-loop.sh, which the brief keeps out of scope: TODO for a later build-loop unit, and landings.sh's header says to change its match with `gate_msg`.
- A root commit: compared with the empty tree (`diff-tree --root`), so a fresh repo's first code commit is listed; with itself as BASE, its rubric's fix count prints `unread` (H2-safe; review A1).
- Fast-forwards (review A7): the window keys on each commit's own committer date, so a code commit dated before the window and fast-forwarded onto main later is never listed. Main is never fast-forwarded with code by the rules (`workflows/pr-prep.md`), all four fast-forwards since 21097afa were docs-only, and step 0.2's `--main-log` already lists every hand commit by SHA since `Main at:`. Revisit trigger: if a cycle's `--main-log` `other` lines show a code commit dated before the window, key 6b on reachability from the last `Main at:` instead of the date.
- Unreadable input (H2): a commit whose paths or message cannot be read prints a `Not read` line and is counted apart; an empty `rubric_lines` output prints as `unread`; a missing or unparseable lib prints `**Out-of-loop landings were NOT checked**`.
- Field separator: US (`%x1f`), not a tab: tab is IFS whitespace, and a root commit's empty `%P` collapsed into the subject (found while writing the tests, before the first commit).
- Record template: not changed. Step 4's text says where the count goes on the `4.` line; editing the template would change the record convention's fingerprint and need a migration line in `scripts/lib/migrations.sh` for no gain.
- Section number 6b: next to section 6, since both feed step 4; the numbering of later sections is unchanged.

### Observable (S6)

The count per cycle on the `4.` line, and what the post-hoc reviews it files find. It can come out negative: the skill says to remove the step and the section if the count is 0 for ten full cycles in a row.

### Cost

On this repo, a window since 2026-11-14 (about 200 first-parent commits) adds about 0.5 to 1.6 s to the digest (one `diff-tree` per first-parent commit in the window; the review's measurements; the whole digest takes about 3 s). A single `git log --name-status` pass would be faster but harder to parse with `-z`; not worth it at one digest per iteration.

## Doc changes

- `scripts/dev-cycle.sh` header: what section 6b lists, and the temp directory it uses.
- `scripts/lib/rubric-check.sh` header and `rubric_lines` comment: the second caller and BASE.
- `skills/dev-cycle/SKILL.md`: step 0.4 names section 6b as step 4's input; step 4's "Out-of-loop landings" paragraph files each landing as a roadmap item, records the count on the `4.` line, and removes itself after ten zero cycles.
- This doc.
- `docs/failure-patterns.md`: FP-188 (review R1).

## Verification

- `test/scripts/dev-cycle-landings.bats` (12 cases): a hand commit to `skills/` with no rubric (listed, `none`); a hand merge whose rubric has an open amber (row listed); a `docs(...)` commit changing a skill (listed); a build-loop merge and a docs-only commit (not listed); merges with the trailer in the subject (anywhere, or as its start) or quoted in the body (listed); a repo-local `i18n.logOutputEncoding=UTF-16` (section unchanged, a `stale` line kept); `fp_blob` and `showpath` equal to build-loop.sh's; a symlinked and a table-less rubric (each `unread`, never `none` or `clean`); a commit whose tree is missing (`Not read`); a commit before the window (not listed); a missing `lib/landings.sh` (NOT checked); a root commit adding code (listed).
- Live run on this repo, `--since=2026-11-14`: lists exactly 22735b6e, 9e7c0542, ded17c89, 386ccfa3 and 44000c6d, the five the review-gap research named, with `none` for the four that left no rubric.
- `scripts/confine-tests.sh --probe` exit 3: "confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run." So the touched suites ran unconfined, with the hermeticity lint.

## Review

`docs/reviews/code-review-rubric-2026-11-20-out-of-loop-landings.md`. Iteration 1 at fa2dcfc8: 1 red, 12 ambers, 19 considers. Fixed: R1 (encoding pinned, test), A1 to A6, A8, A11, A12 (comments, skill text, trailer position, record form, removal rule), A9 (parity test); A7 and A10 carry revisit trigger and TODO notes above. Considers applied: C7, C8, C12, C17; C6 as a step 4 clause. Others left as they are.

Iteration 2 (a narrow re-review of 14f0e543) found that R1 and A1 to A12 hold. It added A13, which is fixed: the removal rule now reads the latest block of each of the last ten days and needs ten such blocks. It also added C20 and C21, both left open. The loop closes at iteration 2. `scripts/health-check.sh` passed at 14f0e543 (exit 0). The commits after it change only skill prose, and `scripts/lib/migrations.sh check` passes on them.
