# Roadmap

What this repo is working on, what comes next, and why. Maintained by the `dev-cycle`
skill (`skills/dev-cycle/SKILL.md`), step 6; each cycle's record is in
`docs/working/cycles/`. Decisions waiting on the user live in
`docs/working/questions.md`, not here: this file says *what* and *in what order*, the
questions doc says *who has to decide*.

**Seeded 2026-09-29 by hand** from `docs/working/questions.md` and project memory, before
any cycle had run. The first `/dev-cycle` run should re-check every line against its
evidence and re-rank Next.

## Now

- **This dev cycle** (`feat/dev-cycle`, log row 67). First run: after install, so the
  router skills from log row 66 are live.

## Next

1. **Q-075 — evidence that the self-improvement loop is safe to resume.** Motive: Q-068
   was answered "resume" on condition of this evidence; the loop is the repo's idea
   generator and has been dormant since. First step: list every path, config, hook,
   credential and git ref `scripts/self-improvement.sh` can write outside its working docs.
2. **Q-088 — spike `sandbox.enableWeakerNestedSandbox` in cc-isolated.** Motive: Q-098
   (a global allow list) waits on a Bash sandbox. First step: the spike's own success
   criterion in Q-088.
3. **Q-089 — host-tool trust category.** Motive: `cc-push.sh` and the exit scan are
   gated by a `Live-verified:` trailer they can never satisfy, since they run only on the
   host (Q-083 [1]). First step: the trust-manifest section.
4. **Measure router uptake.** Motive: log row 66's revisit trigger. First step: in each
   of the first three cycles after install, count multi-file merges that carry RPI
   research/plan docs and pr-prep review artifacts (an artifact count, not the usage log,
   which under-counts, Q-017).
5. **A8 post-restructure token measurement.** Motive: the user deferred big compute until
   code and prompts settle; it validates code-review lever #3. First step: confirm
   settlement (no open code-review SKILL changes), then re-run one canon cell.

## Ideas

Unranked. Each names the signal that motivates it.

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

- AGENTS.md names workflows by filename, not `@` import; guard test (log row 65, merge
  c9a370a). Removes ~89K tokens from every session and subagent in this repo.
- A router skill for every workflow except review-fix-loop (log row 66, merge 4225753).
