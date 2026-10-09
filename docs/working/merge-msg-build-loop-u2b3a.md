Merge branch 'feat/build-loop-u2b3a': the import walks read every reader root and home (the reader model's parts b and c)

The gate runs from its own worktree (plan D13), so a walk resolving names
against ROOT_REAL alone dropped `@/workspace/docs/x.md`, the spelling every
container session uses. import_readers now lists the roots (ROOT_REAL, every
`git worktree list` path, the caller's IMPORT_READER_ROOTS) and homes
(import_home's, IMPORT_READER_HOMES), each spelled and real, memoized until
import_reset. The parser resolves a relative name against every root's copy
of its directory and `~/` against every home, and prints a name under every
root holding it but a dot-nested outer one (dotnest: the omitted spelling is
a dot path truthrule refuses). Both walk caches key on the reader set; the
lib clears the caller lists when sourced (contract item 9). Override rows
425, 432 and 437 are addressed; part (a), outside-repo starts and the
settings line for the host alias, is U2b3b.

Review converged in 3 iterations at the cap; 0 Must Fix; 3 Must Address
resolved in iteration 1 (a stale registry entry at sub/ hid sub/x.md, the
caller lists inherited from the environment, the reader set re-read per call),
2 in iteration 2 (text); 1 acknowledged at the final pass: start files only
another registered checkout holds are not walked (not a regression; deferred
to U2b3b with a revisit trigger). Fixes after the final pass (eb578e3d) are
unreviewed; its lite fix-drift check found nothing. Rubric:
docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md.

Measured over /workspace (24 roots): both walks give main's 128 names; a
cached isimported takes about 3 ms (23-35 ms at 5516c6e6); honest work is
about 330,600 per walk (8,110 on main); work grows with the square of the
root count, failing closed near 570 roots. (Corrects 5516c6e6's "129 names"
and 4dba56dc's "89 ms" and "8,600": override rows.)

Suites: build-loop-check 114, build-loop-read 19, dev-cycle 78,
fixture-git-env 2, fixture-hermeticity 2, hermeticity-lint 53; health check
passed at eb578e3d; 360 code lines against main.

← carried from RPI: plan step 5's U2b3 bullet (model the reader set rather
than name it as an exception; walks stay supersets that fail closed; honest
loops, registry rewrites are the Q-103 residual).

Confidence: medium
Notes: the dotnest rule replaced the first build's longest-root projection
after review; U2b3b's sub-bullet carries the deferred items.
