# Roadmap

What this repo is working on, what comes next, and why. Maintained by the `dev-cycle`
skill (`skills/dev-cycle/SKILL.md`), step 6; each cycle's record is in
`docs/working/cycles/`. Decisions waiting on the user live in
`docs/working/questions.md`, not here: this file says *what* and *in what order*, the
questions doc says *who has to decide*.

Seeded 2026-09-29 by hand; first re-checked by the dev cycle on 2026-10-02 (Next kept in the
user's order).

## Now

Nothing waiting outside a brief: this cycle's three ready items moved to In flight.

## In flight

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
2. **A8 post-restructure token measurement.** Motive: the user deferred big compute until
   code and prompts settle; it validates code-review lever #3 (rubric row A8 in
   `docs/reviews/code-review-rubric-2026-08-07-main.md`). First step: confirm
   settlement (no open code-review SKILL changes), then re-run one canon cell.
3. **Verify a branch without installing it on the host.** Motive: Q-117 and Q-130 were
   answered "not run" on 2026-10-12: installing a branch image refuses while any session
   runs, so it blocks the harness, and a forgotten test install is a security risk.
   Q-125's merge and Q-098 wait on this; the egress fix (`fix/egress-dnsmasq-ipset`) too.
   First step: list what Q-117's and Q-130's checks need from the host, and which of
   those a container or second install prefix could provide side by side with main's.
4. **Q-145 — the lib's ancestor listing skips vanished entries.** Motive: Q-102's parallel
   gate (merged on Q-145 [2]) goes red when an entry in a repo ancestor such as `/tmp`
   vanishes mid-listing (`scripts/lib/dev-cycle-read.sh`, `find -H "${tops[@]}" -maxdepth 1`
   fails closed). First step: skip an entry that no longer exists instead of failing; a
   gate-code unit, so it lands on the user's approval. Revisit trigger (the user's): if re-runs
   on this class cost more than an hour in total before it lands, reopen Q-145.
5. **Revisit the light pass between full cycles (C5, Q-154).** Motive: you answered C5 with a
   full cycle every iteration for now and a light pass of steps 7, 8 and 10 between full
   cycles once the costs are visible (plan D12, F53). First step: after the orchestrator's
   first day of iterations here (after Q-156's release), total each iteration's tokens and
   wall time from its records and bring the numbers to you.

## Ideas

Unranked. Each names the signal that motivates it.

- **A process for writing a repo's constraints doc** (owner attention: routed to you, never
  dispatched). Signal: the orchestrator dispatches nothing in a repo without a hard
  constraint in `docs/constraints.md` (plan D2), and this repo has none (Q-155).
- **Merged-branch deletion in the health step.** Signal: your answer 2 ("safe branch
  deletion doesn't need to wait"); every orchestrator iteration and loop leaves a branch.
  Needs C4 (Q-153), since the global instructions forbid it today.
- **An audit-dimension menu, extendable per project.** Signal: your answer 3 (audits get an
  explicit trigger and a menu of dimensions, like the review critics); step 4b names
  triggers, and its only named dimension is D2's constraints one.
- **Brainstorm confidence routing.** Signal: your answer 4 (ideas with no downside at 90%+
  confidence go to the roadmap, ~70% ones to the questions doc); the hard-constraints half
  is now D2's `docs/constraints.md`.
- **The rest of the build-loop audit.** Signal: plan D13 built only `--main-log`'s check of
  what moved main; re-running the N and S rules over past gate merges is not built.
- **Build-loop future directions (plan D4, D5).** Signal: your 2026-10-04 walk-through. Send
  a refused self-merge back to its loop once before asking you; take the fixed floor itself
  from per-project settings.
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

## Done

Items finished since the last cycle, with the merge.

- Build-loop handoff: the dev cycle is an orchestrator loop that dispatches its briefs to
  build loops and merges what the gate allows (decision log row 72; units U0a to U5, the
  last merged with `feat/build-loop-u5`). Brief:
  `docs/working/briefs/2026-10-02-build-loop-handoff.md`. Runs here only after the release
  (Q-156) and once `docs/constraints.md` exists (Q-155); Q-103 (the policy) is yours.
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
