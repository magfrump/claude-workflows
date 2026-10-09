Merge branch 'feat/build-loop-u2b3b2a': both import walks follow imports to files below no reader root

## What this does

U2b3b2a of the build-loop handoff (plan step 5, the U2b3b2 split note). Both import walks model which repo files Claude Code sessions load as instructions through `@` imports: the self-merge floor's main walk and `--check-fix`'s tree walk. Until now the parser dropped every name that resolved below no reader root (`@~/notes.md`, `@/etc/x.md`, a `..` that leaves every checkout). So a chain from a repo file to an outside file and back into the repo was invisible, and a self-merge could change a repo file a session imports that way. This unit gives the parser a second output channel for such names, and both walks now read those files and follow their imports.

**Workflow provenance:** RPI (plan revision 4, step 5) → split before code (U2b3b2 → U2b3b2a, U2b3b2b) → pr-prep.
← carried from RPI: the superset-and-fail-closed rule for both walks, one path resolver (the parser's put), the 400-line cap, contract item 9's lists from reader_settings, and the carried items G9 (second channel), H2 (dotnest once), H5 with architecture final A1 (one refusal state).

**Failures prevented:**
- A self-merge changing `docs/x.md`, which a repo CLAUDE.md imports through `@~/notes.md` (whose text says `@/workspace/docs/x.md`), or through an outside symlink into the repo.
- An exported `IMPORT_WHOLE` silently switching every walk to whole-name mode, found in review.
- An outside link whose real path holds a newline hiding its target, found in review.

## Reviewer's path — start here

1. `scripts/lib/dev-cycle-read.sh`, the walk header above `IMPORTED=error`: what the walks now follow, and the named exceptions the review found.
2. `scripts/lib/dev-cycle-read.sh` IMPORT_AWK `emit`/`put` and `import_outside`/`import_file`/`outside_ok`: the second channel (`//` and the absolute path), the absolute-base join, the whole-name projection of a real path, and the one admission rule.
3. `test/scripts/build-loop-check.bats`, the four U2b3b2a tests: the parser's channel and modes, chains back into the repo, outside links, and the newline and DIRS cases.

## How it works

- **The parser.** A resolved name below no reader root prints as `/` plus its absolute path, so `//...`; the work trailer stays `/` and digits, and import_work cannot confuse the two. A directory argument led by `/` is joined as it is, not under each root. `IMPORT_WHOLE=1` reads each input line as one whole name. The lib clears it when sourced, and import_outside sets it only as a one-call prefix.
- **The walks.** Both walks queue a `//` name when `outside_ok` admits it (a readable regular file). It is read from the file system through `import_file` → `import_outside`, against its own directory; the main walk does this in phase 2, never through main's arms. When the real path differs, `import_outside` projects it whole, so an outside link into a reader root reads as an import of the repo path. A real path holding a newline, or a failed read, fails the walk.
- **H2.** import_readers builds the dotnest pairs once per reader set (`IMPORT_DOTNEST`), rather than once in each parser process.
- **H5, A1.** import_targets takes its reader set only from import_readers, so a refusal has one state; the ROOT_REAL-only fallback is gone, and a ROOT_REAL of `/` now fails a direct call too.

## How to test

- `test/scripts/build-loop-check.bats`, "the parser prints a name below no reader root as //PATH, …": the channel, the absolute base, whole mode, the reader set outside a walk, a dot-nested root's outer spelling, and a ROOT_REAL of `/` or empty.
- "both walks follow an import below no reader root, …": outside chains back into the repo by absolute and relative names, a cycle, `~/` against the home's directory, and an inherited `IMPORT_WHOLE=1`.
- "an outside link whose real path holds a newline fails the tree walk …": the newline refusal, and import_file's DIRS.
- "an outside name whose real path lies in the repo reads as that repo path; …": outside links into the repo, and the skipped missing, directory and mode-000 names.
- The sourcing inventory in `test/scripts/dev-cycle.bats` names the new functions and globals.
- Each test is red on main's lib, and each iteration-1 fix mutant fails one; the fact-check executed both.
- Suites: build-loop-check 120, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2. `scripts/health-check.sh` passed on the branch at 1f27b584 (the code of 64da3e16 plus this message).

## Areas of uncertainty

- Two narrow fail-opens remain, each named in the walk header and neither a regression (main dropped every outside name):
  - **S1**, routed to U2b3b2b: an outside link into another reader root whose checkout lacks a file main has is skipped as missing.
  - **S2**, a named exception: an outside name holding a newline, which only a quoted mention across lines can name.
- **A3**, routed to U2b3b2b: a `//` name under a reader home this container cannot see (the host's) is skipped.
- The walks now parse any readable regular file an `@` prefix names, `/etc/passwd` included. The review found no way for that content to surface. A large binary, or a very long absolute name, spends the budget and fails the walk closed.
- The final-pass text fixes and the two pipefail lines (64da3e16) were not reviewed. The suites passed on them, and the lite fix-drift check found nothing.
- Over this worktree both walks give main's 64 names, with no `//` names, in about the same time.

## Decisions made

- Split before code: U2b3b2a holds the outside chains, and U2b3b2b holds the outside seeds and C1.
- The second channel is always on, since every caller is a walk or a test. An absent reader home and a newline spelling are named exceptions rather than refusals, because refusing either would fail honest walks.

Decisions referenced: none — change is independent of recorded decisions (plan D5's floor, carried through the plan).

## Review evidence

Review converged in 3 iterations; 0 Must Fix; Must Address: 4 resolved (A1, A2, A4, B1), 3 acknowledged (A3 and S1 routed to U2b3b2b, S2 a named exception).

- `docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b2a.md` (iterations 1-3; the loop closed at 82bb5281)
- `docs/reviews/code-fact-check-report-build-loop-u2b3b2a.md` (iteration 1), `-i2.md` (iteration 2), and `-final.md` with `-final-r1/-r2/-r3.md` (iteration 3)
- `docs/reviews/{security,performance,api-consistency,architecture}-review-2026-10-09-u2b3b2a.md` (iteration 1), `-i2.md` (iteration 2) and `-final.md` (iteration 3)
- 21 override-log rows dated 2026-10-09 for `feat/build-loop-u2b3b2a`

Retrospective: the split held, at 239 lines. Running the critics in parallel with the fact-check in iteration 1 cost nothing visible, but iteration 2's sequential order let the critics confirm the fact-check's one Incorrect at once. The checkpoint's apostrophe gotcha fired once more and was caught within the same step.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01WXq2z7f7uQu97mRuecPKLC
