# Roadmap

What this repo is working on, what comes next, and why. Maintained by the `dev-cycle`
skill (`skills/dev-cycle/SKILL.md`), step 6; each cycle's record is in
`docs/working/cycles/`. Decisions waiting on the user live in
`docs/working/questions.md`, not here: this file says *what* and *in what order*, the
questions doc says *who has to decide*.

Seeded 2026-09-29 by hand; first re-checked by the dev cycle on 2026-10-02 (Next kept in the
user's order).

## Now

Built by hand, each on its own branch, or briefed this cycle (cycle 2026-10-26-0002).

- **Q-168 — the exit scan's loose remote-name parsing** (`fix/q096b-exit-scan-remote-names`,
  75d08a94). Motive: split off from Q-096's review. Built and stopped at the review cap.
  Q-171 was answered [2]: hold it until the split units land, fixing red findings that
  predate it first. Q-172 was answered [2]: close only routes that need no state planted
  before launch, list the rest as known routes, push with cc-push. The four split groups
  are Q-173 (now `agent`); first step: sort them by that rule (R6, High, is inside it and
  builds first). R6 merged at 7a5b4f4a (Q-220 [1]), and its sort left group 1's remainder
  (A14, R3's remote half, A16) in scope; that unit is briefed (In flight, the group 1
  remainder line).

- **Questions doc becomes owner-only (Q-221 [14′], decision 040).** Motive: the owner reported
  that agent bookkeeping crowds the one page meant for them (17 open entries, 2 theirs).
  Build in three units: (1) four owner routes (`you: judgment`, `you: terminal`, new
  `you: walkthrough`, new `you: fyi`), with `questions.sh check` refusing `agent`/`trigger`/
  `deferred` in `questions.md` and naming where each goes; (2) `docs/working/watching.md`
  (entry grammar, `## Closed` section) plus a lossless `questions.sh migrate`; (3) dev-cycle
  steps 2/3 read `watching.md` and file agent work to this roadmap, and the global
  instructions' questions section changes to match (≤ ~30 lines, repo S2). Gate code: each
  unit is a `merge-gate` entry. First step: brief unit 1 (done: In flight, the owner routes
  line). Follow-ups: entry clarity (gloss every internal reference) and a
  `questions.sh record <answers-file>`.

## In flight

- **Exit scan: Q-173 group 1 remainder (A14, R3's remote half, A16)** (Q-168's next step,
  Now). Motive: Q-172 [2] puts these routes inside the boundary; the R6 unit listed them as
  "not closed yet". Brief: `docs/working/briefs/2026-10-28-exit-scan-group1-remainder.md`
- **Questions doc owner-only, unit 1: owner routes in `questions.sh`** (Now, decision 040).
  Motive: the owner's report that agent bookkeeping crowds their page. Gate code, so its
  merge is a `merge-gate` entry. Brief: `docs/working/briefs/2026-10-28-questions-owner-routes.md`
- **Bug: the interview profile's README does not match its scripts** (was Next 4). Motive:
  undocumented is broken (spot-check of be464869). Docs only, `Policy: self-merge`. Brief:
  `docs/working/briefs/2026-10-28-interview-readme-drift.md`

## Next

1. **Q-125's host live run, now that `cc-verify` is merged.** Motive: Q-125 (the
   cc-isolated Bash sandbox), and behind it Q-098 (global allowlist) and Q-161 (hermeticity
   layer 2), waited on `cc-verify` (merged at 37b24c02, Q-217 [1]). First step: once the host
   install has `cc-verify` (Q-222), write the probe FILE for Q-125's live check (a sandboxed
   `cat ~/.claude/.credentials.json` refused, Q-098's leak list re-run, `gh`/`git push` not
   prompting) and file it as one `you: terminal` paste.
2. **A8 post-restructure token measurement.** Motive: the user deferred big compute until
   code and prompts settle; it validates code-review lever #3 (rubric row A8 in
   `docs/reviews/code-review-rubric-2026-08-07-main.md`). First step: confirm
   settlement (no open code-review SKILL changes), then re-run one canon cell. The
   user's 2026-10-20 feedback adds re-evaluating review k and the lite review under Opus
   5.5; deferred, ask before running.
3. **Automate the host settings.json merge (Q-106 [2]).** Built
   (`feat/q106-host-settings-merge`, c6d7544f; it also closes Q-108). Paused at the iteration-4
   gate with one Medium open. Q-174 answered [1]: run iteration 4 (tighten the group
   shape, anchor the regexes, count duplicate hooks), then the k=3 confirming pass. Q-175
   answered [1]: the moved merge program stays in the `hooks/**` class, no gate change.
4. **Revisit the light pass between full cycles (C5, Q-154).** Motive: you answered C5 with a
   full cycle every iteration for now and a light pass of steps 7, 8 and 10 between full
   cycles once the costs are visible (plan D12, F53). First step: after the orchestrator's
   first day of iterations here (after Q-156's release), total each iteration's tokens and
   wall time from its records and bring the numbers to you.

## Ideas

Unranked. Each names the signal that motivates it.

- **Let a brief continue an existing hand branch.** Signal: Q-174 [1] authorized Q-106's
  iteration 4 on 2026-10-22 with no commit since, while a loop slot sat free (briefs need a
  new branch). A `Base:` line naming the commit would let a loop pick it up; the gate code
  is yours to change.
- **Skip the health check after a docs-only gate merge.** Signal: iteration 2026-10-26-0027
  re-ran the full check for 4388056e, which touched only `docs/`.
- **A hermetic test for the interview profile's preflight.** Signal: no test covers
  `profiles/interview/` (spot-check of be464869); pairs with Next 4.

- **Check that code review follows decision 031's k policy.** Signal: the user's feedback
  note of 2026-10-20 observes k=3 fact-checks on every pass, where 031 sets k=3 on the
  first fact-check, k=1 in review-fix iterations and a clean final pass. First step: read
  the code-review and review-fix-loop texts against 031, then the rubrics of the last few
  merges. Re-evaluating k under Opus 5.5 is a separate, deferred ask.
- **Count each cycle's overhead against feature work.** Signal: the same note says the dev
  cycle spends more on verification overhead than on features. First step: from the
  records, total each iteration's own landed lines and commits against feature merges in
  its window; feeds Next 3 (Q-154).

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
- **install.sh's archive honors replace refs.** Signal: U5's security review i2 F2:
  `repo_git` does not switch replace refs off and `git_state_gate` does not check
  `refs/replace/` (nor a `core.attributesFile` in the repository's or worktree's config, U5 final and narrow security F1), so `.manifest` can record a commit whose content the image does not
  hold (`docs/reviews/security-review-2026-10-14-u5-i2.md`). Q-156's paste refuses replace
  refs for its own release; a decision-035 boundary change, so its own unit.
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
  Not fired 2026-10-17: five skill and workflow files changed, 53 lines added in all.
  Fired again 2026-10-20: the `constraints-builder` skill added (`SKILL.md` and two
  references, 539 lines; 512a1512 and 55e0bdac), a new skill no audit has read. The
  dev-cycle skill and onboarding workflow changed by 9 lines between them.
  Fired again 2026-10-20 (iteration 2344): `constraints-builder` revised (rev2, ec86e1fd;
  93 changed lines in SKILL.md, plus two references) and `skills/dev-cycle/SKILL.md` (87)
  (d120b2dc, f858482f: fewer stops, merged-branch deletion, `other` commits no longer
  stop). Decision 039 (pin the resolver to phase A) is added; not a major design decision.
  Drift finding (step 4, 43762305): the loop's Path A decision pruned options with soft
  lines S3, S5 and S9, and S9 was gone from `docs/constraints.md` (2620b419) before the
  merge. The pick stands (A dominates), but the audit should check that loops rank with S
  lines rather than prune with them; revise the file with the `constraints-builder` skill's
  amend mode.
  Fired again 2026-10-28: decision 040 (the questions doc holds only owner items) is a major
  design decision that changes the dev cycle's steps 2 and 3 in three gate units; an audit
  reads best after unit 3 lands.
- **Usage log records host vs container.** Signal: decisions 015 T4 and 014 T1 are "cannot
  tell" for lack of the field (cycle 2026-10-02).
- **Doc-freshness check: refresh the 7 stale docs or loosen the heuristic.** Signal: health
  check 11 shows 7/7 stale, 0 fresh (8/8 on 2026-10-20). A choice among 3+ remedies: flag
  for `divergent-design`.
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
- **The digest shows unlanded cycle branches.** Signal: `chore/dev-cycle-2026-10-15-0357`
  held Q-162 to Q-177 and a cycle record, none on main, so the digest and `next-id` could not
  see them (Q-178). List unmerged `chore/dev-cycle-*` branches with the entry IDs they add.
- **The digest flags landed Now items.** Signal: cycle 2026-10-17 found 8 of 11 Now items
  already merged (f265d7f2, fbe67674) two days earlier, still reading "waits on Q-162's
  paste". List Now items whose named branch or commit is on main.
- **Measure the D6 paste's share of an iteration's tokens.** Signal: cycle 2026-10-17 made
  about 30 D6 calls of ~55 pasted lines each. Gives Next 5 (Q-154) a number.
- **The release entry misses self-merges outside gate code.** Signal: cycle 2026-10-20's
  spot-check of f8d5217f. `docs/dev-cycle.md` says the `image-lag` entry flags self-merged
  subjects, but step 0.1 files that entry only when GATE_CODE's paths differ from the image,
  so a self-merged `devcontainer-config/install.sh` or `test/` change reaches a host
  install unflagged. Either file the entry when `devcontainer-config/` differs too, or
  narrow the prose.
- **Set a locale the image has.** Signal: every D6 call prints three
  `setlocale: LC_ALL: cannot change locale (en_US.UTF-8)` warnings into the output the
  orchestrator reads.

- **Let the orchestrator merge, or plan for a human merge each cycle.** Signal: cycle
  2026-10-14. The auto-mode classifier refused this session's merge into main, so every
  finished branch waits on a paste (Q-162), and `--land-cycle` cannot run here either.
  The remedy is a permission rule only you can add, or a standing per-cycle merge entry.

## Done

Items finished since the last cycle, with the merge.

- The `cc-verify` host tool: done at 37b24c02 (Q-217 [1], build-loop approved merge). Brief:
  `docs/working/briefs/closed/2026-10-20-cc-verify-host-tool.md`
- Exit scan R6 (a relative `core.hooksPath` in a linked worktree) and the sort of Q-173's
  groups: done at 7a5b4f4a (Q-220 [1]). Brief:
  `docs/working/briefs/closed/2026-10-25-exit-scan-r6-hookspath.md`
- Widen the fix-drift lite check (decision 031's fourth trigger): done at 68287ee2
  (Q-219 [1]). Brief: `docs/working/briefs/closed/2026-10-25-widen-fix-drift-check.md`
- Log row 73's second trigger reworded as the same-uid residual: done at ce0f8463
  (Q-218 [1]). Brief: `docs/working/briefs/closed/2026-10-25-log-row-73-trigger.md`
- Decision 015's amendment, log row 66's close and row 53's Q-176/Q-177 amendment: done at
  4388056e (Q-216 [1], build-loop approved merge). Brief:
  `docs/working/briefs/closed/2026-10-20-decision-015-amendment.md`
- Q-146 [1] — self-improvement.sh commits for its implementer: done at 86993a8c (Q-197 [1]).
  Brief: `docs/working/briefs/closed/2026-10-17-q146-si-script-commits.md`
- `cc-isolated --profile` path-like values and the empty `--register` grant: done at
  c80fec22 (Q-195 [1]; host check Q-196 open). Brief:
  `docs/working/briefs/closed/2026-10-17-cc-isolated-profile-names.md`
- The repo rules file's import guard test: done at 43762305 (Q-198 [1]). Brief:
  `docs/working/briefs/closed/2026-10-17-claude-md-import-guard.md`
- Q-092 — drop the auto-approve hook's deny reader, with Q-177 [3]'s quote check: merged by
  hand at 79c8a6a6 and dfc78e9a.
- Measure router uptake (log row 66): Q-179 answered [1], close; recording it on row 66
  rides on the decision-015 brief. Tally: 45 multi-file merges since 2026-10-02, 26 carry
  pr-prep's line, 41 committed a rubric, 4 have neither (all 2026-10-02 to 2026-10-06).
- Merged-branch deletion in the health step: step 1 now runs `git branch -d` on merged branches without asking (`fix/dev-cycle-fewer-stops`, log row 74).
- Build-loop handoff brief closed: `--check-brief` reads `done` at 9bb19d2a (`feat/build-loop-u5`).
  Brief: `docs/working/briefs/closed/2026-10-02-build-loop-handoff.md`
- Doc drift from cycle 2026-10-02: done at f265d7f2 (`merge/ready-2026-10-15-r2`). Brief:
  `docs/working/briefs/closed/2026-10-02-doc-drift-cycle1.md`
- Q-096 — exit scan follows insteadOf targets: done at f265d7f2. Brief:
  `docs/working/briefs/closed/2026-10-02-exit-scan-insteadof-target.md`
- Landed by hand in f265d7f2 (2026-10-15): Q-110 (the health check's NOT RUN summary; the
  2026-10-17 health check's summary and runner both say 50), T69's stage race, Q-160 (the
  in-loop size re-check), the launcher's rebuild hint, one workspace per `cc-isolated` call,
  and the branch-verify research and divergent-design docs. Q-145 (the lib's ancestor
  listing) in fbe67674.
- `docs/constraints.md` exists (83b653d2, 4 hard and 11 soft constraints), so dispatch is on.

- Build-loop handoff: the dev cycle is an orchestrator loop that dispatches its briefs to
  build loops and merges what the gate allows (decision log row 72; units U0a to U5, the
  last merged with `feat/build-loop-u5`). Brief:
  `docs/working/briefs/closed/2026-10-02-build-loop-handoff.md`. Runs here only after the release
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
