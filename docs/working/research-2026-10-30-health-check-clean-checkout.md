# Research: step 1's health check on a checkout nothing edits mid-run

Brief: `docs/working/briefs/2026-10-30-health-check-clean-checkout.md` (at 330c517b).
Workflow: research-plan-implement, no plan gate; divergent design inline (below).

## Reproduction

Reproduction: in a scratch git repo holding `scripts/` and the two questions files from
330c517b, `bash scripts/questions.sh check` exits 0; append one well-formed `### Q-999`
entry to `docs/working/questions.md` without reindexing (what the orchestrator does when it
files an entry while the check runs) and the same command exits 1 with
`✗ questions.md: index is stale`. That is check 14 of `scripts/health-check.sh`, the gate
that went red in both cycle records; `test/scripts/health-check.bats` 198 and 208 nest the
same run. A timing-exact reproduction of the full check (minutes long) racing an edit is
impractical; the records show the race happened: `docs/working/cycles/cycle-2026-10-29.md`
(iteration 2026-10-30-0035, Q-234 filed by step 1b) and `cycle-2026-10-30.md` line 65
(iteration 0731, Q-238 filed by step 3). Counter-check: a `git worktree add --detach` of the
same commit, run while the first checkout still holds the unindexed entry, passes.

## What step 1 does now (330c517b)

- `skills/dev-cycle/SKILL.md` step 1 runs the check "from WT", in the background, and only
  steps 2–4b's own tests and subagents wait for it. Step 1's own `questions.sh
  init`/`archive`, step 1b's migration entries and steps 2–4's questions entries all write WT
  while the check reads it. That is the race.
- WT is not always MAIN: step 0.3 may merge this session's previous stopped iteration's
  commit into WT. The record line still says `passed at MAIN`.
- The skip rule ("previous `1.` line `passed at P`/`unchanged since P` and only `chore`
  lines") and `HEALTH_CHECK_LOCK_WAIT=3600` (exit 75: nothing checked) are independent of the
  checkout. The lock lives in the git common directory (`take_lock`,
  `scripts/health-check.sh` ~1146), shared by every worktree of the repository.
- Prior art: step 7's gate checkout GT (`hg -C MAIN_WT worktree add --detach GT
  refs/heads/main`, made for one call, removed as step 0.3 removes WT).
- No test pins step 1's wording (`rg` over `test/`); `convention-migrations.bats`
  fingerprints the step 9 record template, which this change leaves alone (the `1.` line's
  `passed at MAIN / ...` vocabulary is unchanged, so no migration).
- The health check has no branch dependence (no `show-current`/`symbolic-ref` in it,
  `run-tests.sh` or `health-check.bats`), so a detached HEAD is fine; build loops already run
  it in their own worktrees.

## Gotchas

- Failure-pattern grep: no matches found
  (`grep -inE 'health-check|race-condition|stale-index|dirty-worktree|mid-run'
  docs/thoughts/failure-patterns.md` hit only the `race-condition` cause-vocabulary line,
  no FP entry.)
- `git archive`-style exports are not checkouts: `take_lock` returns without a lock when
  `rev-parse --git-common-dir` fails, which would silently drop the lock behaviour.
- `worktree remove --force` (not plain remove) for the same reason step 0.3 gives: the
  clean check's status run would execute a planted filter.

## Divergent design

Motive (S5): real. Two red checks in one day, each costing a triage and a reindex, from a
memory rule that failed twice; status quo stays a candidate.

| Option | Verdict | Why |
|---|---|---|
| A. Detached checkout HC of MAIN, made for the run and removed after (as GT) | **Pick** | Reads exactly the commit the record names, even when WT holds a merged earlier iteration; nothing else names HC, so no discipline is needed (S4); reuses the GT mechanism (S3); prose-only, one `git revert` (S8); lock and skip rule unchanged; failure of the add is named and retried next iteration (H2). Cost: one checkout's disk and seconds per run, removed at once. |
| B. Run the check before WT exists (from MAIN_WT) | Pruned | MAIN_WT is the user's checkout, may be on another branch or dirty (other sessions switch it): reads a tree other than MAIN, breaking the brief's rule. |
| B'. Run in WT, but before any edit, serializing steps 1b–4 after it | Pruned | Dominated by A: costs the whole check's duration (up to an hour's lock wait) of iteration latency, still reads a merged earlier commit when step 0.3 merged one, and still rests on the ordering being remembered. |
| C. Stage edits outside WT until the check ends | Pruned | The same remembered rule that failed twice, now spread over steps 1–4 (S4, S10). |
| D. Status quo | Pruned | The bug recurs; triage each time. |
| E. Export MAIN's tree to a temp dir (`git archive`) | Pruned | Not a git checkout: the lock in the git common directory silently goes away (H2), and tests needing git would fail. |

Hard constraints: A adds no gate logic in a writable copy (H1 unchanged: the interim
exception already runs the change's own `scripts/` and `test/`, and HC holds MAIN's, the
same as WT did); fails loudly (H2); hermetically verifiable (H3: a bats wording pin plus
the scratch reproduction); no LLM judgment (H4). Path A dominates; decided.

## Plan

1. `skills/dev-cycle/SKILL.md` step 1: run the check from HC (`hg -C MAIN_WT worktree add
   --detach HC W`, W = WT's HEAD commit, MAIN unless step 0.3 merged an earlier
   iteration's commit; `.claude/wt-dev-cycle-health-DATE-HHMM`), removed once it exits; say
   why (the two records); an add failure is `skipped: HC not made`, so the next iteration
   runs it again. No script mode needed.
2. `test/scripts/build-loop-orchestrator.bats`: pin that wording, and that "health check
   from WT" is gone (fails on 330c517b's text).
3. Full health check on the branch; pr-prep Step 0 and review-fix loop; brief Status to done.

Test strategy: the change is skill prose the orchestrator follows, no code path; the only
mechanical guard available is a wording pin (G1, added). The behavioural claim (a detached
checkout is unaffected by WT edits) was shown in the scratch counter-check above.

Failure-pattern skip: the fix is one orchestrator step's prose (where it runs a check), not a code bug with a reusable cause-and-fix shape a future grep would find; the brief and roadmap Idea already record the two cases.

## Review round 1 (code-review subagent, fe692928)

No red. Ambers fixed in the next commit:

- HC is made from W, WT's HEAD commit (MAIN, or step 0.3's merge of an earlier iteration's
  commit), not always MAIN. With MAIN, a merged earlier commit carrying code would have
  landed unchecked: `--main-log` classes a cycle land `chore` by subject and record alone
  (`scripts/build-loop.sh` `log_class`, header ~164-178), so the next iteration's skip rule
  would skip it. W is a commit, so WT's working-tree edits still cannot reach HC, and the
  `1.` line names W, the tree the check read (the brief's rule). Option A's row above reads
  "of MAIN" for the common case W = MAIN.
- `--state` from MAIN_WT before the add, as for GT (dropped again in round 2, below); a
  name taken goes to the next minute.
- A stop while the check runs stops it by PID or process group, then removes HC; a failed
  removal is recorded and named in the final message, and an HC this session's earlier
  iteration left is removed (not any `wt-dev-cycle-health-*`: another session's may be live). (The
  Rules' general stop line, SKILL.md ~58, is outside step 1 and left alone: step 1's own
  text covers HC.)
- "Reads exactly MAIN" narrowed to "reads W's tree" (the check also reads
  `~/.claude/settings.json` and the git common dir).
- The log is "in the orchestrator's directory", per the Rules.
- The test pins short fragments rather than one sentence.
- "`health-check.bats` 198 and 208" above are bats test ordinals, not line numbers.

## Review round 2 (fresh code-review subagent, a868c911)

No red; naming W was checked sound against the skip rule and `log_class`. Fixed:

- The step 1 `--state` added in round 1 is dropped: it was missing from the Rules' list of
  calls run outside WT and its refusal handling differed from step 0.1's stop. The text
  now says why none is needed (step 0.1's `--state` passed minutes before the add; GT runs
  its own because step 7 is much later).
- Leftover HCs: this session's are removed before the add; any other
  `wt-dev-cycle-health-*` (another session's, maybe live) is only named in the final
  message.
- Rewrapped an overlong line; the plan above now says W.

Left as a residual (amber): step 9's record template still shows
`passed at MAIN / ...`; step 1 says the `1.` line names W in MAIN's place when they
differ. Changing the template changes the `record` convention's fingerprint and needs a
`scripts/lib/migrations.sh` registry line, which is beyond step 1 (the brief's scope) for a
case (step 0.3 merging a stopped iteration) that is rare.
