Merge branch 'feat/build-loop-u2b3b2c': both import walks read other worktrees' copies of the names they reach

## What this does

U2b3b2c of the build-loop handoff (plan step 5, the U2b3b2c bullet). Both import walks model which repo files Claude Code sessions load as instructions through `@` imports: the self-merge floor's main walk and `--check-fix`'s tree walk. A session started in another worktree loads that worktree's own copy of each file, and that copy may import what this checkout's copy does not. Until now the walks read only this checkout's copy (or main's), so a self-merge could change a file that another worktree's differing copy imports (U2b3b2b i1 security F1). `root_copies` now reads those copies. A seed that is a dangling link into a reader root is now projected too (U2b3b2b final security F1).

**Workflow provenance:** RPI (plan revision 4, step 5) → split at U2b3b2b's review iteration 1 → pr-prep.
← carried from RPI: the superset-and-fail-closed rule for both walks, U2b3b2b's outside seeds and outside_proj's projection, import_outside as the one reader of outside files, contract item 2's clean checkout as the gate's threat model, and the 400-line cap.

**Failures prevented:**
- A self-merge changing a repo file that another worktree's differing copy of an imported file imports, or that a copy only that worktree holds imports, through chains there.
- A dangling link (a seed, or another worktree's copy) to a file this container lacks being skipped instead of read as the repo path it names.
- Found in review: a dangling prompt link's target read as a plain import, without the link's bases, and never re-read once the walk had read it; a copy below a linked directory skipped; an equal-bytes prompt copy in a root below a `.claude/` whose parent is no reader root skipped although its path adds prompt bases.

## Reviewer's path — start here

1. `scripts/lib/dev-cycle-read.sh`, the walk header above `IMPORTED=error`: root_copies' rule, the prompt projections and the named exceptions.
2. `root_copies` and `prompt_marks`, then `import_readers`' `IMPORT_OTHER`.
3. The two walks' start-pass calls, their `//` read arm, and the re-read after `prompt_marks`.
4. `test/scripts/build-loop-check.bats`, the eight tests naming U2b3b2c.

## How it works

- **root_copies Q CMP PDIR NAME...**: for each repo name a walk reaches (starts included, once per walk), each other present reader root's copy is read unless reading it could add nothing: this checkout holds a plain file there with the same bytes, no link on either side, and the name is no prompt or that root has no prompt bases of its own. The parser already resolves this checkout's relative names against every root, so an equal copy adds nothing. A copy that is a dangling link, or is missing below a linked directory, is queued as `//ROOT/NAME` and projected. There is one batched realpath and one batched sha1sum per call.
- **IMPORT_OTHER**: the other roots' real paths, from import_readers (memoized with the reader set). C1 uses it, and its byte skip moved to root_copies.
- **`//PATH` queue entries**: a dangling link (a seed, or a copy) that only outside_proj reads.
- **prompt_marks**: a dangling prompt link's projected names are read as prompts with the link's directory and prompt bases (pext), and a name the walk had already queued is read again with them.

## How to test

- `test/scripts/build-loop-check.bats`, the eight U2b3b2c tests: differing and only-there copies through chains, a prompt copy, a dangling copy; a copy under a linked directory, present or missing; a dangling prompt link at top level and under a nested `.claude/`; re-reads (plain first, a start, an existing prompt with new bases); an equal-bytes prompt copy under a non-root `.claude/`; a dangling-link seed; fail-closed comparison.
- Each test is red on the lib before its fix.
- Suites, run serially: build-loop-check 132, build-loop-read 20, dev-cycle 79, fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53 (288). Over /workspace, both walks give main's 242 names. `scripts/health-check.sh` passed on the branch tip.

## Areas of uncertainty

- **Cost**: about +0.2 s per walk over this repository's 7 other roots (interleaved against main's lib). A worktree at a commit where many imported files differ adds about 11 ms per differing copy, uncapped (override row; revisit over a 5 s walk).
- **Routed to U2c**: a live prompt link in another worktree whose target there holds other bytes is read plain (final security F3, not a regression; override row).
- **Named exceptions**: a host home or root this container cannot see (A3); a symlinked directory in another worktree (A5); a checkout that is not clean (contract item 2); and a projected prompt name main stores as a symlink, which fails the main walk closed.
- **Not panel-reviewed**: the final-pass fix (8da3dfd3) was checked by a k=1 fact-check and the security critic instead (no Incorrect, no new fail-open). The text fixes after that pass (91a74031) were not re-reviewed.
- A `bats -j 8` run once failed a U2b3a test: the ancestor seeds' find listed a bats temp file that a sibling test then deleted. It predates this unit, and serial runs are clean.

## Decisions made

- The outside_seeds split (override row 582's trigger fired here) was built at iteration 1 and reverted at the final pass to stay under the 400-line cap (417 with it); its revisit trigger is re-keyed.
- Equal-bytes copies are skipped as a cost, not deduplicated per bytes across roots: a copy read from another root resolves `..` names against its own directory.

Decisions referenced: none — change is independent of recorded decisions (plan D5's floor, carried through the plan).

## Review evidence

Review converged in 3 iterations (iteration 2 short-circuited at fact-check), plus a confirming pass; 0 Must Fix open. Fixed: one behavioural red (B1) and 17 Must Address (A1-A8, B2-B3, C1-C3, C5, and the confirming pass's text items). Acknowledged with override rows: A9 (per-copy cost) and C4 (routed to U2c).

- `docs/reviews/code-review-rubric-2026-10-09-feat-build-loop-u2b3b2c.md` (iterations 1-3 and the confirming pass; the loop closed at 007e867f)
- `docs/reviews/code-fact-check-report-build-loop-u2b3b2c-{i1,i2,final,confirm}.md`, with `-final-r1/-r2/-r3.md`
- `docs/reviews/{security,performance,api-consistency,architecture}-review-2026-10-09-u2b3b2c-{i1,final}.md`, `security-review-2026-10-09-u2b3b2c-confirm.md`
- Override-log rows dated 2026-10-09 for `feat/build-loop-u2b3b2c`; row 595 struck (fixed by C1)

Retrospective: the prompt kind was the recurring defect. Each pass found one more order in which a name's prompt marks arrived after its read. That held until the walks re-read on any change to the marks.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_018X78L3ajw3rXEbwmifV4wc
