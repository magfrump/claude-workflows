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

- **Instruction loading and workflow reach**: AGENTS.md without `@` imports
  (branch `fix/agents-md-no-imports`, log row 65), a router skill per workflow
  (`feat/workflow-router-skills`, log row 66), and this dev cycle (`feat/dev-cycle`).

## Next

1. **Q-075 — evidence that the self-improvement loop is safe to resume.** Motive: Q-068
   was answered "resume" on condition of this evidence; the loop is the repo's idea
   generator and has been dormant since. First step: list every path, config, hook,
   credential and git ref `scripts/self-improvement.sh` can write outside its working docs.
2. **Q-088 — spike `sandbox.enableWeakerNestedSandbox` in cc-isolated.** Motive: Q-098
   (a global allow list) and Q-092 wait on a Bash sandbox. First step: the spike's own
   success criterion in Q-088.
3. **Q-089 — host-tool trust category.** Motive: `cc-push.sh` and the exit scan are
   verified by `Live-verified:`, which does not fit host-only tools (Q-083 [1]). First
   step: the trust-manifest section.
4. **Measure router uptake.** Motive: log row 66's revisit trigger. First step: 30 days
   after the next install, `scripts/skill-usage-report.sh` counts for
   `research-plan-implement` and `pr-prep`.
5. **A8 post-restructure token measurement.** Motive: the user deferred big compute until
   code and prompts settle; it validates code-review lever #3. First step: confirm
   settlement (no open code-review SKILL changes), then re-run one canon cell.

## Ideas

Unranked. Each names the signal that motivates it.

- **Q-079 — canon-instance script and proposal filter.** Signal: the review canon grows
  only by hand (Q-072).
- **Automate the failure-pattern harvest, or drop the "do not skip" line.** Signal: Q-074,
  1 entry in ~128 fix commits; it reopens as a judgment on 2026-10-26.

## Done

Items finished since the last cycle, with the merge. (None recorded yet.)
