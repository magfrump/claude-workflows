# Roadmap

What this repo is working on, what comes next, and why. Maintained by the `dev-cycle`
skill (`skills/dev-cycle/SKILL.md`), step 6; each cycle's record is in
`docs/working/cycles/`. Decisions waiting on the user live in
`docs/working/questions.md`, not here: this file says *what* and *in what order*, the
questions doc says *who has to decide*.

Seeded 2026-09-29 by hand; first re-checked by the dev cycle on 2026-10-02 (Next kept in the
user's order).

## Now

Being built by hand in this cycle (2026-10-14), each on its own branch and worktree. Each stops
before merging, since this session cannot merge into main (Q-162).

- **U5, the build-loop handoff's last unit** (`feat/build-loop-u5`). Motive: U1–U4 are on
  main, but the docs, Q-103's re-route, the release entry and the brief's `done` are
  still owed (plan items 11–13). Built and reviewed; waits on Q-164 (gate code, escalate).
- **Q-110 — the health check's NOT RUN summary under-counts** (`fix/q110-not-run-undercount`).
  Motive: reproduced again this cycle (runner 50, summary 4). Fixed and reviewed; waits on
  Q-162's paste.
- **Q-145 — the lib's ancestor listing skips vanished entries** (`fix/q145-ancestor-vanish`;
  was Next 4). Motive and revisit trigger as filed under Q-145. A gate-code unit: it lands
  on your approval: built and reviewed, waits on Q-163.
- **T69's stage race** (`fix/t69-stage-race`, 4ee81106; built and verified). Motive: this
  cycle's health-check red. Waits on Q-162's paste.
- **Doc drift** (`fix/doc-drift-cycle1`, c8e87a69; added 2026-10-15). Motive: the In flight
  brief below. Reviewed, loop closed; waits on Q-162's paste (`merge/ready-2026-10-15`).
- **Q-160 — the in-loop size re-check** (`fix/q160-iteration-cap`, 4a44d2f3; added
  2026-10-15). Motive: log row 62 fired again. Reviewed, simplified, narrow-checked; waits on
  Q-162's paste.
- **Q-096 — exit scan follows insteadOf targets** (`fix/q096-exit-scan-insteadof-target`,
  8717fd72; added 2026-10-15). Motive: the In flight brief below. Reviewed, loop closed;
  waits on Q-162's paste, then its host probe (Q-167).
- **Q-168 — the exit scan's loose remote-name parsing** (`fix/q096b-exit-scan-remote-names`;
  added 2026-10-15). Motive: split off from Q-096's review (older routes, now a listed known
  route). Built (75d08a94) and stopped at the review cap with the guide's parity claims
  still wrong; landing waits on Q-171. How much parity the scan chases at all is Q-172,
  and the four split groups (R6 High) are Q-173.
- **The launcher's rebuild hint** (`fix/rebuild-hint-recreate`, 47da5a4b; was Next 3).
  Reviewed, loop closed at the cap; in `merge/ready-2026-10-15`, so it lands with Q-162, and its
  probe is Q-167 (a).
- **One workspace per `cc-isolated` call** (`fix/cc-isolated-one-workspace`, f6f37fad; was
  Next 3). Reviewed; the independent closing review was clean. In `merge/ready-2026-10-15`;
  probe Q-167 (b).
- **Q-092 — drop the auto-approve hook's deny reader** (`fix/q092a-drop-deny-option`
  d27a3891, then `fix/q092-drop-hook-deny-reader` aeda94b2). Built and reviewed, including an
  independent closing review. Merge waits on the host check of Claude Code's deny matcher
  (Q-176, Q-177).
- **Verify a branch without installing it** (was Next 3; `docs/branch-verify-without-install`,
  tip d25254da). Motive: Q-117, Q-125 and Q-098 wait on it. Research and divergent design are
  done: no check needs main's install, and the recommendation is a `cc-verify` host tool that
  runs main's launcher on a staged merge tree (Q-165, Q-166). The hand spike paste on
  Q-117 is written and reviewed (Q-169; its doc lands with Q-162). Next: the `cc-verify`
  unit, if Q-165 picks [1]; its extractor refuses links at every path component (residual A17).

## In flight

- **Build-loop handoff**: the cycle starts autonomous build loops for its briefs; Q-103
  waits on it. Brief: `docs/working/briefs/2026-10-02-build-loop-handoff.md`
- **Doc drift from cycle 2026-10-02** (bug: undocumented is broken): two guides still advise
  a bare `devcontainer up --remove-existing-container`; AGENTS.md/GEMINI.md omit `dev-cycle`.
  Brief: `docs/working/briefs/2026-10-02-doc-drift-cycle1.md`
- **Q-096 — exit scan follows insteadOf targets**: a known route around the exit scan,
  unblocked by Q-094's merge. Brief: `docs/working/briefs/2026-10-02-exit-scan-insteadof-target.md`

## Next

1. **Measure router uptake.** Motive: log row 66's revisit trigger. First step: in each
   of the first three cycles after install, count multi-file merges to main whose message
   carries pr-prep's `← carried from RPI` line and whose branch committed a code-review
   rubric. Both are tracked; research/plan docs are gitignored and the usage log
   under-counts (Q-017), so neither can be counted.
   Cycle 1 (2026-10-02): 3 multi-file landings since 4225753a; 0/3 carry the line, 2/3
   committed a rubric, 1/3 (188e0a7d, 2 files) has neither.
   Cycle 2 (2026-10-14): 42 multi-file landings; 25/42 carry the line, 38/42 committed a
   rubric, 4/42 have neither (df18413a, 0fbf9742, b8807e76, 52053432). About 36 are
   units of the one build-loop plan.
   Cycle 3 (2026-10-15, window closed): 45 multi-file merges since 2026-10-02; 26 carry
   the line, 41 committed a rubric, 4 have neither (all 10-02 to 10-06). The verdict is
   Q-179.
2. **A8 post-restructure token measurement.** Motive: the user deferred big compute until
   code and prompts settle; it validates code-review lever #3 (rubric row A8 in
   `docs/reviews/code-review-rubric-2026-08-07-main.md`). First step: confirm
   settlement (no open code-review SKILL changes), then re-run one canon cell.
3. **`cc-isolated --profile` accepts path-like values, and `--register` with no profile
   registers an empty grant** (bug). Motive: the one-workspace unit's independent review
   found both; they predate it. `--profile ../egress/python` is written as-is. First step:
   validate the profile name against the egress profile directory's names, refuse an empty
   grant, and quote the unregistered-project NOTE's path with `%q`. Enforcement file.
4. **Automate the host settings.json merge (Q-106 [2]).** Built
   (`feat/q106-host-settings-merge`, c6d7544f; it also closes Q-108). Paused at the iteration-4
   gate with one Medium open (Q-174); gate coverage of the moved merge program is Q-175.
5. **Decision 015's re-run: apply the outcome (Q-170).** Motive: Q-105 [3]. The divergent
   design is done (`docs/dd-015-step4`, f050b487, lands with Q-162): keep Docker, since none of
   the 6 breakages was Docker's. First step, once Q-170 is answered: apply §6's amendment
   to 015's revisit triggers.
6. **Q-146 [1] — self-improvement.sh commits for its implementer.** Motive: in a worktree
   or clone the children have no allowlist and cannot commit (F5), and the `/workspace`
   allowlist gives arbitrary code execution (F1); see `docs/working/si-trust-evidence-2026-10-14.md`.
   First step: after the implementer exits, the script runs `git add -A && git commit` in
   the worktree, taking the child's message from a file it wrote (fall back to the task
   description); children get no Bash grants. About 20 lines plus tests. Then the live run
   Q-075 imagined, with `REPO_DIR` a dedicated clone (§5.1), never `/workspace`.

## Ideas

Unranked. Each names the signal that motivates it.

- **Union-merge the append-only review logs.** Signal: on 2026-10-15 every pair of finished
  units conflicted only in `docs/reviews/override-log.md` (and earlier in
  `failure-patterns.md`), so each landing needs a hand-built `merge/*` branch. A
  `merge=union` attribute for those files would land the rows without a merge branch.
  `.gitattributes` is a truth file and install.sh's archive reads it, so this is your call.
- **Move claude-home payload assembly behind a workflows-owned entrypoint (036 [11]).**
  Signal: Q-107. 036's second-consumer trigger fired, but the seam is not met. The seven
  source paths are in `install.sh:135`, and a second copy of the names, with no parity test, is in
  `link-claude-home.sh:50`. The named harm is already mitigated (one shared `git archive`
  assembly), so this is low priority. First step, the cheap half: a test that `ENTRIES`
  equals the names from `CLAUDE_HOME_SRC`, or have the linker read `.manifest`. The full move
  to `scripts/build-payload.sh` is about half a day plus a host live-verify.
- **cc-push refuses a `#` word, and the remaining guide notes go.** Signal: the
  one-workspace review (C8, A3, K1–K6). `cc-push # --yes` reads the note's later words as
  flags (it fails safe today, at find_checkout). The guide example blocks still end in
  `# note`, which now exits 2 when pasted. First step: cc-push's guard (a host tool, so
  `Host-tool-tested:`), plus converting the guides' notes to own-line comments.
- **`guard-trusted-writes.py`'s `ask` can turn a Bash deny into a prompt.** Signal: Q-092's
  pre-mortem (F8). On a web-tainted session it emits `ask` for a Bash write to a SOFT-tier
  target, and per #39344 an `ask` overrides a matching deny. "Never asks" holds for the
  auto-approve hook only. First step: confirm with Q-176's setup whether an `ask` beats a deny
  on 2.1.300, then decide whether the guard should emit `deny` there instead.
- **Claude Code can drop a whole settings file the hook accepts.** Signal: Q-092 (F6b, A1). A
  BOM, a NaN literal or another key's bad value can make Claude Code ignore a file, which takes
  its deny rules with it while the hook still approves from its allow rules. First step: trace
  which values do this, then have the hook refuse them.
- **The hook reads project settings from its working directory's git root.** Signal: Q-092's
  independent review (C6, pre-existing). A session that has `cd`'d into another repo gets that
  repo's allow rules. First step: confirm against how Claude Code itself picks the project.
- **Show bidi and zero-width characters in install review diffs.** Signal: Q-106's review
  (rubric A5). `vis` passes U+202A–202E, U+2066–2069 and zero-width characters, so on some
  terminals a crafted line in a review diff can display reordered. Pre-existing; Q-106 only
  extends it to the settings diff. First step: extend `vis` in install.sh, with a test.
- **A launcher flag to refresh the cached Claude Code layer.** Signal: the doc-drift review
  (C3). A recreated container goes back to the image's Claude Code version until
  auto-update runs; something like `--probe-only --no-cache` would rebuild that layer.

- **live-verify-gate: commits it does not see (Q-089 B security F3-F5).** Signal: a
  `git commit <path>`, `-o` or `-i` commits unstaged gated changes with no trailer; a
  `git -C <dir> commit` (how orchestrators commit into `.claude/wt-*`) is checked against
  the hook's cwd; a shebang edit passes as comment-only. Each fails closed at runtime (the
  bless diff, `verify_host_tools`). Also (iteration-3 security F3, F4): a non-ASCII path is
  quoted in `--name-only` output under the default `core.quotePath` and misses the anchors
  (read with `-z`); `diff.relative` with the hook run from a subdirectory drops paths
  (`--no-relative`). `docs/reviews/security-review-2026-10-14-q089b.md`, `-it3.md`.
- **One owner for "the install dir" in cc-isolated (Q-089 A1 architecture F1, rubric C1).**
  Signal: bless/`--list` use `config_dir()` while the pre-source check uses the launcher's own
  dir; every hint now names the right dir, but an installed copy could assert the two agree
  and refuse once on a mismatch.
- **Scoped deep audit** (step 4b). Signal: cycle 2026-10-02's deep-audit triggers fired —
  8 router skills and the dev-cycle skill added in the window, and no earlier cycle record
  to compare the model with. Scope and timing are the user's; runs on its own branch.
  Fired again 2026-10-15: `skills/dev-cycle/SKILL.md` rewritten as the orchestrator
  (U4b1, U4b2, U4c), plus code-review, pr-prep, RPI and onboarding changes in the window.
- **Health check under-counts NOT RUN suites (Q-110).** Signal: the runner printed 50
  report-dependent suites NOT RUN; the health-check summary said 4 (cycle 2026-10-02).
- **Usage log records host vs container.** Signal: decisions 015 T4 and 014 T1 are "cannot
  tell" for lack of the field (cycle 2026-10-02).
- **Doc-freshness check: refresh the 7 stale docs or loosen the heuristic.** Signal: health
  check 11 shows 7/7 stale, 0 fresh. A choice among 3+ remedies: flag for `divergent-design`.
- **Fixtures for dev-cycle and the 9 other unfixtured skills.** Signal: health check 9. The
  report-dependent half waits on Q-067.
- **Retire the stale idea-source row in `docs/dev-cycle.md`.** Signal: its only file is a
  March 2026 DD whose survivors have shipped.
- **Author adjudication of Contested-Soundness rubric rows.** Signal: decision 028 T3 can't
  be decided without it (~6 rows, none adjudicated).
- **Q-079 — canon-instance script and proposal filter.** Signal: the review canon grows
  only by hand (Q-072).
- **Automate the failure-pattern harvest, or drop the "do not skip" line.** Signal: Q-074,
  1 entry in ~128 fix commits; it reopens as a judgment on 2026-10-26 if fewer than 5 new
  entries have landed by then.
- **Narrow code-review's "default whenever a PR is prepared" description.** Signal: it
  overlaps the pr-prep router (override log, deferred from log row 66's review).
- **Finish skill-format-audit F1: drop `when:` repo-wide and from
  `divergent-design-router.bats`.** Signal: override log, deferred from log row 66's review.
- **Review artifacts collide across branches.** Signal: merging the row-66 branch hit
  conflicts on `code-fact-check-report-r*.md` (undated, so any two branches collide) and
  add/add conflicts on `*-review-<date>.md` (any two branches reviewed the same day).
- **Pre-handoff briefs hold every slot and are never collected.** Signal: `--status` skips
  all three 2026-10-02 briefs ("no Branch: line"), so they hold the 3 slots for 13 days while
  their work goes on in by-hand branches (cycle 2026-10-15). Give each its `Branch:` line,
  or set it done or dropped where its work lands.
- **The digest shows unlanded cycle branches.** Signal: `chore/dev-cycle-2026-10-15-0357`
  held Q-162 to Q-177 and a cycle record, none on main, so the digest and `next-id` could not
  see them (Q-178). List unmerged `chore/dev-cycle-*` branches with the entry IDs they add.
- **Prune worktrees on merged branches.** Signal: 35 registered worktrees, 12 of them on
  branches already merged. Each one costs disk and joins the import walks' reader set.
- **Set a locale the image has.** Signal: every D6 call prints three
  `setlocale: LC_ALL: cannot change locale (en_US.UTF-8)` warnings into the output the
  orchestrator reads.

- **Let the orchestrator merge, or plan for a human merge each cycle.** Signal: cycle
  2026-10-14. The auto-mode classifier refused this session's merge into main, so every
  finished branch waits on a paste (Q-162), and `--land-cycle` cannot run here either.
  The remedy is a permission rule only you can add, or a standing per-cycle merge entry.
- **Dispatch the two briefs held since 2026-10-02.** Signal: the doc-drift and Q-096 briefs
  held 2 of 3 slots for 12 days unstarted (log row 68's cap clause). Since U4, a dispatcher
  exists, but dispatch stays off here until `docs/constraints.md` exists (D2; U5 files it).

## Done

Items finished since the last cycle, with the merge.

- Q-089: host-only tools get their own trust category (decision log row 71). Units A1+A2
  merged as 626dc300 and B as df18413a, on Q-148 [1]. Not live-verified: re-run install.sh, then
  `cc-isolated --list`, and edit an installed `cc-gitdir.sh` to see both refusals. Q-145's
  revisit clock: one 752 s health-check re-run on this landing (two `/tmp`-race failures).
- Q-088's spike (answered 2026-10-07, failure: the weaker nested sandbox still needs user
  namespaces; record `docs/spikes/weaker-nested-sandbox-cc-isolated.md`); it had stayed in Next.
- Q-075: evidence on the self-improvement loop's write surface, from an inventory, a hermetic
  stubbed run and a live permission check (`docs/working/si-trust-evidence-2026-10-14.md`). The
  loop stays dormant on Q-146: the children are unconfined from `/workspace` and cannot commit
  in a worktree.
- The dev cycle (skill and digest script, log rows 67–68, merge 90364c73); first cycle run
  2026-10-02.
- AGENTS.md names workflows by filename, not `@` import; guard test (log row 65, merge
  c9a370a). Removes ~89K tokens from every session and subagent in this repo.
- A router skill for every workflow except review-fix-loop (log row 66, merge 4225753).
