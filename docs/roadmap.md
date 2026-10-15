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
- **Q-096 — exit scan follows insteadOf targets** (`fix/q096-exit-scan-insteadof-target`;
  added 2026-10-15). Motive: the In flight brief below. Built; review iteration 2 is under
  way after the first security pass found five Mediums.
- **Verify a branch without installing it** (was Next 3; `docs/branch-verify-without-install`,
  22a4bb1f). Motive: Q-117, Q-125 and Q-098 wait on it. Research and divergent design are
  done: no check needs main's install, and the recommendation is a `cc-verify` host tool that
  runs main's launcher on a staged merge tree (Q-165, Q-166). First step: the hand spike
  paste on Q-117, being written and reviewed.

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
2. **A8 post-restructure token measurement.** Motive: the user deferred big compute until
   code and prompts settle; it validates code-review lever #3 (rubric row A8 in
   `docs/reviews/code-review-rubric-2026-08-07-main.md`). First step: confirm
   settlement (no open code-review SKILL changes), then re-run one canon cell.
3. **The launcher's rebuild hint misleads after the firewall fails closed** (bug). Motive:
   the doc-drift review (A4, C4, C5). `rebuild_hint` in `cc-isolated.sh` tells the user that
   a plain `cc-isolated <repo>` rebuilds, but a plain launch recreates only when the config
   hash differs, so in that state it does not recover. `init-firewall.sh` and two lines of
   the cc-isolated guide say "rebuild" where they mean "recreate". First step: point the
   hint's first line at `--probe-only`, then a launch, as the guides now do. It touches
   enforcement files, so the commit carries a `Host-tool-tested:` or `Live-verified:` trailer.
4. **Automate the host settings.json merge (Q-106 [2]).** Motive: decision 037 T1 fired;
   Q-106 was answered [2] on 2026-10-06 (via the provenance jq), with a roadmap item due
   "next cycle" that never landed. First step: RPI over install.sh's host target. It is an
   enforcement file, so the plan opens with the bypass pre-mortem.
5. **Re-run decision 015's step 4 as a divergent design (Q-105 [3]).** Motive: 015 T2 fired
   last cycle; Q-105 was answered [3] on 2026-10-06, with the same lost follow-up. First step:
   a `divergent-design` doc seeded with 015's constraints and the breakage record.

## Ideas

Unranked. Each names the signal that motivates it.

- **Union-merge the append-only review logs.** Signal: on 2026-10-15 every pair of finished
  units conflicted only in `docs/reviews/override-log.md` (and earlier in
  `failure-patterns.md`), so each landing needs a hand-built `merge/*` branch. A
  `merge=union` attribute for those files would land the rows without a merge branch.
  `.gitattributes` is a truth file and install.sh's archive reads it, so this is your call.
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
