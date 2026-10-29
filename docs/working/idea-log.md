# Idea log

Seeds from any step of the dev cycle (`skills/dev-cycle/SKILL.md`, "Seeding is always on"),
one line each, unranked. Each `## Brainstorm` heading marks where a brainstorm read up to.

- Record host vs container in the usage log, so "sessions drift back to the host" and per-session denial counts become countable (signal: cycle 2026-10-02, decision 015 T4 and 014 T1 both "cannot tell" for lack of the field)
- Tune or act on the doc-freshness check: 7 of 7 tracked docs are stale, 0 fresh, one by 67 commits (signal: cycle 2026-10-02 health check, check 11)
- Fixtures for the skills that have none, dev-cycle first (signal: cycle 2026-10-02 health check, check 9 lists 10 skills)
- Replace or retire the dev-cycle idea source `docs/working/feature-ideas*.md`: its only file is a March 2026 DD whose survivors have mostly shipped (signal: cycle 2026-10-02 step 5, file last committed 2026-03-23)
- Bare `bats` in this container shows 5 false reds from the unset locale; `run-tests.sh` pins it, but subagents reach for `bats` directly (signal: cycle 2026-10-02 step 4, spot-check of 7387d8f1)
- Ask the author to adjudicate the ~6 Contested-Soundness rubric rows, the only way 028's precision-guard trigger can be decided (signal: cycle 2026-10-02 step 2, 028 T3 near threshold, "cannot tell")
- `guides/README.md` index line for cc-isolated-usage.md omits cc-push and the exit scan (signal: cycle 2026-10-02 step 4, spot-check of 7387d8f1)

## Brainstorm 2026-10-02

First brainstorm (none recorded before). Signals read: this cycle's steps 1–4, the seeds above,
the idea source `docs/working/feature-ideas.md` (nothing new: its survivors are built or
already on the roadmap), and the roadmap's existing Ideas. Surviving ideas, as filed in the
roadmap's Ideas:

1. Usage log records host vs container (seed 1). Changes: three decision triggers become decidable.
2. Freshness check: refresh the 7 stale docs or loosen the heuristic (seed 2). Flag for `divergent-design` if both are viable: refresh, tune threshold, or per-doc path narrowing.
3. Fixtures for dev-cycle and the other 9 unfixtured skills (seed 3). Waits behind Q-067 (report regeneration) for the report-dependent half.
4. Retire the stale idea-source row in `docs/dev-cycle.md` (seed 4). Changes: step 5 stops reading a finished DD.
5. Author adjudication of Contested-Soundness rows (seed 6). Changes: 028 T3 becomes decidable.
6. Do nothing on direction: Next already holds five user-ranked items and the open judgments; this brainstorm adds no re-ranking.

Dropped: seed 5 (bare-bats locale) as an idea on its own — the remedy is "use `run-tests.sh`", already the documented runner; noted in the cycle record instead. Seed 7 folded into the doc-drift brief.
- Let the orchestrator merge into main (a permission rule), or plan a human merge paste per cycle (signal: cycle 2026-10-14, the auto-mode classifier refused the merge of fix/t69-stage-race)
- Answered questions whose answer says "roadmap item next cycle" get no roadmap line unless the cycle copies it (signal: cycle 2026-10-14, Q-105 [3] and Q-106 [2] answered 2026-10-06, missing from the roadmap)

## Brainstorm 2026-10-14

Signals read: this cycle's steps 1–4b, the two seeds above, the idea source `docs/working/feature-ideas.md` (nothing new), the roadmap's Ideas and the plan's U5 items. Surviving ideas, as filed in the roadmap:

1. Orchestrator merge rights, or a standing human-merge entry (seed 1). Changes: whether a cycle can land anything without the user.
2. Dispatch the two 12-day-old briefs once `docs/constraints.md` exists. Changes: frees 2 slots.
3. Q-105 [3] and Q-106 [2] follow-ups go to Next 4–5 (seed 2, applied directly rather than filed as an idea).
4. Do nothing else: U5 files its own roadmap items (a)–(g), and adding more now would duplicate them.

- Give the three 2026-10-02 briefs `Branch:` lines or close them, so `--status` stops skipping them (signal: all three skipped as "no Branch: line"; they hold every slot)
- List unmerged `chore/dev-cycle-*` branches and the entry IDs they add in the digest (signal: Q-162 to Q-177 lived only on `chore/dev-cycle-2026-10-15-0357`; `next-id` printed Q-149, which is in use)
- Prune worktrees whose branch is merged (signal: 35 registered worktrees, 12 on merged branches)
- Set a locale the image has, so the scripts stop printing setlocale warnings (signal: three `LC_ALL` warnings on every D6 call)

## Brainstorm 2026-10-15

Triggers: roadmap Now holds 0 items ready for a brief; 13 days since the last brainstorm.

1. Close or migrate the pre-handoff briefs (seed 1). Changes: frees the 3 slots for dispatch once U5 lands.
2. Show unlanded cycle branches in the digest (seed 2). Changes: no parallel stream of asks goes unseen; next-id stops colliding.
3. Prune worktrees on merged branches (seed 3). Changes: smaller reader set for the import walks, less disk.
4. Fix the image locale (seed 4). Changes: cleaner gate output.
5. Do nothing on direction: Next keeps the user's order. Q-178 (land the 0357 stream) is the step that unblocks the most.
- The digest flags roadmap Now items whose named branch or commit is already on main (signal: cycle 2026-10-17, 8 of 11 Now items had landed in f265d7f2 and fbe67674 two days earlier and still read "waits on Q-162's paste")
- Measure the D6 block's share of an orchestrator iteration's tokens before the light-pass decision (signal: cycle 2026-10-17, about 30 D6 calls of ~55 pasted lines each in one iteration; bears on Next 7, Q-154)
- Briefs for enforcement-file bugs carry the host check in the ready marker, as the Q-096 brief did (signal: cycle 2026-10-17, roadmap Next 3 needed a `Live-verified: no` route to be briefable)

## Brainstorm 2026-10-17

Triggers: roadmap Now held 0 items ready for a brief (every listed item had landed or waits on an open entry).

1. Brief the two Next items whose choice is made and needs no open entry: Q-146 [1] (Next 6) and the `cc-isolated --profile` bug (Next 3). Changes: two build loops start now that `docs/constraints.md` exists.
2. Digest check for landed Now items (seed 1). Changes: Now stops reading stale between cycles.
3. Measure the D6 paste cost (seed 2). Changes: gives Next 7 (Q-154) a number.
4. Do nothing on direction: Next keeps the user's order; items 1, 2, 4, 5 and 7 wait on open entries or settlement.
- Re-read the three 2026-10-17 review briefs under the self-merge policy now set, so a future fix of the same shape is briefed `Policy: self-merge` with `Paths:` (signal: cycle 2026-10-20, `--settings` prints `policy self-merge set` while every open brief reads `Policy: review`)

## Brainstorm 2026-10-20

Triggers: roadmap Now holds 0 items ready for a brief (all three wait on open entries); the three In flight loops are ready and wait on merge entries Q-195, Q-197, Q-198, open since 2026-10-17.

1. Do nothing on direction: the binding constraint is the four open merge and host entries (Q-195 to Q-198), not missing work. Changes: no new asks while those wait.
2. Brief new fixes under the self-merge policy (seed 1). Changes: a fix whose paths are off the floor and the never globs lands without a merge entry, so it costs no attention.
3. Doc freshness now reads 8 of 8 stale (health check 2026-10-20; the roadmap item says 7). Changes: the existing divergent-design item gets its current count; no new item.

## Brainstorm 2026-10-20 (iteration 2344)

Triggers: roadmap Now holds 0 items ready for a brief once this iteration's two briefs moved to In flight (Q-168 holds on Q-171 [2]).

1. Check that code review follows decision 031's k policy (k=3 on the first fact-check, k=1 in review-fix iterations, a clean final pass). Signal: the user's feedback note of 2026-10-20 (`docs/human-author/feedback-10-20-26.txt`, untracked) observes k=3 on every pass. Changes: shows whether the skill text or the agents drift from 031; re-evaluating k itself stays deferred (ask first).
2. Count each cycle's overhead against feature work: lines and commits the cycle lands versus feature merges in its window. Signal: the same note says the dev cycle spends more on verification overhead than on features. Changes: gives Q-154's light-pass question and the feedback a number.
3. Do nothing else: two briefs dispatch this iteration; the rest of Next waits on Q-174, Q-175 or settlement.
- `cc-isolated --register` with no `--profile` exits 1 where log row 58 says usage errors exit 2 (signal: cycle 2026-10-20-2344 step 2, cc-isolated.sh after c80fec22)
- Let the dev cycle close an `agent` entry it has verified done on main (a dated done line plus a status the archive moves), instead of leaving it for the user (signal: cycle 2026-10-25, Q-092, Q-096, Q-110 and Q-160 verified done but left OPEN because `--cycle-diff` refuses a Status flip without `--answered`)

## Brainstorm 2026-10-25

Ran because roadmap Now held 0 items ready for a brief (Q-168 is held; its first step is already briefed). Sources: this cycle's signals, this log and roadmap Ideas (`docs/dev-cycle.md` lists no idea sources).

- Let a brief continue an existing hand branch (a `Base:` line naming its commit), so authorized work like Q-106's iteration 4 can take a free loop slot (signal: Q-174 [1] authorized iteration 4 on 2026-10-22, no commit since, and one slot sat free in iteration 2026-10-26-0027 because briefs require a new branch)
- Skip step 1's health check when every non-chore line on main since the last pass is a gate merge that touched only `docs/` (signal: iteration 2026-10-26-0027 re-ran the full health check because of 4388056e, a docs-only approved merge)
- Give the interview profile a hermetic bats test of preflight's ancestor loop (fake HOME; stubbed claude, curl and nvidia-smi) (signal: the step 4 spot-check of be464869 found no test covers `profiles/interview/`, and the check counts the exclude key's presence as coverage)
- Do nothing else: two loops are running and two merge entries (Q-217, Q-218) wait on the user (signal: queue state this iteration)
- `questions.sh check` refuses an entry whose Status is ANSWERED but which has no line the answer reader accepts (`Q-NNN:` or a bold `**Answer…:**` label), naming the accepted forms; and merge entries print the exact answer line to write (signal: the owner's 6b490257 recorded Q-224 and Q-225 as plain `Answered: [1]`, which `--check-answer` reads as `unrecognized`, so two approved merges waited a round)
- `build-loop.sh --cycle-diff` should refuse a chore commit that removes a brief's `Status:` line or empties an open brief (signal: 2342b0a4 truncated `docs/working/briefs/2026-10-29-questions-doc-bats-lint.md` to its `Dispatched:` line and `--cycle-diff` printed `ok`)
- Find why the nested health check once flagged `test-strategy: missing 'description' field` (tests 198, 199, 208 of the 2026-10-29-2003 run at eecf0268) when the outer check passed the same file and a rerun of both tests passed (signal: a one-off red health check with no code change)
- The skill-frontmatter health check flakes on more than one file: a build loop saw `user-testing-workflow: missing 'name' field` once on its branch, and passed 200 of 200 repeats (signal: the unit 2 loop report, 2026-10-29, and the 2003 iteration's `test-strategy` flake)
