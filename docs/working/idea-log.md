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
- A third one-off health-check failure in a day: `test/scripts/build-loop-check.bats` "the ancestor listing skips a file that vanishes" failed once on the harness-feedback branch and passed alone and on the next full run; collect the flakes in one place and find whether load or a shared resource is the common cause (signal: the harness-feedback loop report, 2026-10-29)
- A fourth load flake on 2026-10-29: `test/scripts/dev-cycle.bats` test 37 "--check-fix allows only existing docs/ and README.md files" failed once in a full-file run with two loops running and passed alone (signal: the post-merge check of Q-233)

## Brainstorm 2026-10-29

Ran because 10 ideas were seeded since the 2026-10-25 brainstorm. Sources: this cycle's signals, this log, roadmap Ideas, and `docs/working/feature-ideas.md` (the one idea source `docs/dev-cycle.md` lists; unchanged since 2026-03-23, nothing new in it).

- Diagnose the skill-frontmatter flake (two seeds above): briefed as `docs/working/briefs/2026-10-29-skill-frontmatter-flake.md` (signal: two one-off missing-field reports on 2026-10-29; the vanish research found no shared cause)
- The four load-flake seeds above are two causes, not one: the vanishing-file case is fixed (431397bf); dev-cycle.bats test 37 waits on whether it recurs now that the vanish cause is known (signal: the vanish research's Cause section)
- Run step 1's health check on a clean checkout of main, not on WT (signal: this iteration's health check failed only on a stale index from the orchestrator's own mid-run edit)
- Free a merged loop's worktree (signal: 15 merged branches `branch -d` refused, each held by a finished loop's locked worktree)
- Name the 2026-10-30 `LEGACY_BEFORE` cutoff before the old skill files an `agent` entry past it (signal: unit 3 unmerged, cutoff tomorrow)
- Divergent design's table: separate hard fails from soft costs (signal: a third drift finding of the same class, 6ee39f24)
- Do nothing more: the owner holds the image release review and Q-234; unit 3 is back with its loop (signal: queue state)
- Harness friction, dev-cycle skill (the D6 block): pasting the 56-line block whole into every `build-loop.sh`/`dev-cycle.sh`/`questions.sh` call (about 40 calls in two iterations) costs more context than any other step; this session ran a sha256-checked scratch copy instead. A shorter fixed form, such as a root-owned wrapper in the image that the skill names by absolute path, would keep the same trust properties (signal: session 2026-10-29/30, iterations 0035 and 0100)
- Harness works, `--cycle-diff`: it refused iteration 0100's `Asked: Q-235@…` line on a brief, because a merge entry is found by its heading, not by an `Asked:` item. Step 7's prose read as if every filed entry adds one; the gate caught the misreading before it landed (signal: iteration 2026-10-30-0100, `refuse docs/working/briefs/2026-10-29-questions-owner-only-unit3.md: its first Asked: line adds Q-235@…`)
- Harness friction, the Bash write-guard hook: it blocked a quoted heredoc appending a questions entry to `docs/working/questions.md` because the entry's text named the global instructions' file path in prose. The Edit tool worked. A guard that keys on the destination path rather than on words in the content would skip this (signal: iteration 2026-10-30-0100, "PreToolUse:Bash hook error: Bash write that names a protected policy file")
- Harness friction, the orchestrator's wait: a build-loop subagent that pauses on its own background work sends an interim task notification, which wakes the loop with nothing to collect. Twice this session; each cost a turn (signal: iterations 0035 and 0100, "is waiting on its own background work")
- harness feedback, dev-cycle digest (questions.sh open) (fails): digest-misses-watching-file: section 3 printed "None open" while `watching.md` held three OPEN `deferred` entries (Q-058, Q-079, Q-091). The image's `cmd_open` runs `parse_entries "$LIVE"` only, and `dev-cycle.sh` filters that... (signal: harness feedback philosophy-research F-001, docs/working/feedback/philosophy-research.md)
- harness feedback, dev-cycle path rules vs. the global harness-feedback instruction (friction): cycle-cannot-create-feedback-file: the dev-cycle skill lets an in-cycle fix edit only a file that `--check-fix` prints `ok` for, and `--check-fix` refuses every new file. So the cycle could not create the file. The finding went to t... (signal: harness feedback philosophy-research F-002, docs/working/feedback/philosophy-research.md)
- harness feedback, dev-cycle step 5 (brainstorm) (friction): brainstorm-refires-same-trigger: "Roadmap Now holds 0–1 items ready for a build brief" fired again in the second iteration with Now unchanged, so the brainstorm ran twice on one day for one signal. The second added one idea, and t... (signal: harness feedback philosophy-research F-003, docs/working/feedback/philosophy-research.md)

## Brainstorm 2026-10-29 (iteration 2026-10-30-0136)

Ran because the digest counted 14 seeds since the last brainstorm heading; 7 of them are that brainstorm's own lines, so the count inflates itself. Sources: this log (the four harness seeds and the three philosophy-research seeds), roadmap Ideas, and `docs/working/feature-ideas.md` (unchanged since 2026-03-23).

- Count only seeds above a brainstorm's own lines, or stop writing a brainstorm's ideas under its heading in the seed shape, so the 10-seed trigger does not count its own output (signal: this iteration's 14 includes 7 brainstorm lines; philosophy-research F-003, the brainstorm re-firing on one signal)
- Fire the "Now holds 0-1 ready items" brainstorm trigger only when Now changed since the last brainstorm (signal: philosophy-research F-003)
- Let the cycle create a project's `docs/harness-feedback.md` (through `harness-feedback.py init`) and append entries in-cycle, in projects other than claude-workflows (signal: philosophy-research F-002, `--check-fix` refuses every new file)
- Release soon after Q-235 merges: repos that already ran `questions.sh migrate` have a digest blind to their watches until the image carries unit 3 (signal: philosophy-research F-001)
- The D6 block as a fixed, root-owned wrapper the skill names by absolute path (signal: this session's D6 seed)
- Do nothing more now: three merge entries (Q-235, Q-236, Q-237) wait on the owner, and no loop is running (signal: queue state)

## Brainstorm 2026-10-29 (owner: friction and engagement)

Full text: `docs/working/brainstorm-2026-10-29-friction-and-engagement.md`.

- Tier gate merges by risk; only enforcement-changing ones stay owner entries, the rest self-merge with ⚑ (signal: 19 of 19 archived merge entries approved, none dropped or changed)
- One batched merge entry per cycle with merge-all / all-but / hold-all options (signal: Q-235, Q-236, Q-237 open at once)
- Merge and release in one answer: a gate merge option that also yields the release paste (signal: merged gate fixes inactive until install.sh, Q-230 at 014e5219)
- Image-lag entry as release notes: chore lands collapsed to a count, ⚑ self-merges first (signal: Q-227 lists 27 commits, its one ⚑ is item 23)
- One land per iteration instead of two (signal: paired chore merges per iteration on main)
- Stamp the harness image version in the digest and let migrations require a minimum image (signal: philosophy-research F-001)
- Collect projects' harness-feedback files at release time from the host (signal: hand copy staged at the wrong path, 2026-10-30-0116)
- `questions.sh paste`: one dependency-ordered script from every open `you: terminal` entry (signal: five terminal entries open, oldest Q-084 from 2026-09-27)
- In self-merge projects, the first digest after a new image prints the behavior changes that apply there (signal: F-001, F-003)
- A reserved security channel (route, marker or notification) used for nothing else (signal: owner asks for a non-habituating path for security warnings)
- Track owner asks per week and the default-answer rate; propose moving a class off the desk when it is always [1] (signal: S1)
- Weekly "what changed in your harness" digest that asks for nothing (signal: owner awareness request)
- Sampled weekly review of one random self-merged change in place of per-item approval (signal: S1)
- Entries open 21+ days get one forced close/convert/re-ask choice (signal: open entries from 2026-09-26)
- Zero recurring warnings: a warning printed on every run is a bug (signal: setlocale lines on every D6 call)
- Owner entries name in line one what would differ on "no", and for gate merges what an attacker would want from the code (signal: owner-entry clarity memory)
- Quarterly threat-model walk-through of Q-103's residuals (signal: owner awareness request)
- A brief split checks shared append-only ledgers (decision-log rows) and shared SKILL.md passages, not just file ownership, before calling units parallel (signal: units 2 and 3 both conflicted with unit 1 at merge, Q-246, Q-247)
- Re-sample the three critic personas, or loosen the 180-day threshold (signal: health check 2026-11-03: ai-personas, cowen and yglesias personas 184 days since sampled)

## Brainstorm 2026-11-05

Ran because the last brainstorm was 7 days ago (2026-10-29). Sources: this cycle's signals, this log, roadmap Ideas, and `docs/working/feature-ideas.md` (the one idea source `docs/dev-cycle.md` lists; its entries are old and none matched a current signal).

- The skill's identity check reads `git config` only, so it reports none in a session whose identity comes from `GIT_AUTHOR_*` and `GIT_COMMITTER_*`, which the gate's own check accepts; `git var GIT_AUTHOR_IDENT` would answer both (signal: iteration 2026-11-05-2347, config empty, identity real)
- The image-lag paste pins M, but the cycle's land moves main past M in the same iteration, so its check always fails on a checkout at main's tip; pin the last gate-code commit, or have the paste accept any first-parent descendant with the same gate code (signal: Q-252's text said "bring the checkout to main", which could not pass)
- Skip the health rerun when every `other` commit touches only `docs/` (signal: adb22f4d, a docs and questions commit, cost a full health run)
- Record why a free slot stays empty: three iterations wrote "not briefed this iteration" with the queue under its slots and no reason (signal: cycle-2026-11-03 steps 8)
- Free a merged loop's worktree, now 28 merged branches held (signal: `branch -d` refused 28 of 28 this iteration; seeded 2026-10-29 at 15)
- Do nothing more on merge friction until the trial's feedback is in: T1-T7 end about 2026-11-06 (signal: Q-252 and Q-253 both wait on the owner, and A1/A3/A10 are held for that feedback)
- Name the running trials in every final message while a trial is on, since the trial doc is the only surface and nothing brings it to the owner (signal: owner asked on 2026-11-05 how to see which trials are running)

## Brainstorm 2026-11-06

- Give a decision's runtime-log trigger a readable route (signal: decision 039's trigger names an untracked `/run` log that `--check-path` always refuses)
- Keep a list of things waiting for a release, read when the image-lag entry closes (signal: Q-241's item planned to ride on Q-252's next rewrite; the release came first)
- Give a trial a closing step (signal: the trial week reached its end date with feedback on only part of T1-T7)
- Do nothing else until Q-259 and Q-260 are answered (signal: all three briefs wait on the owner, and the queued skill ideas edit passages Q-259 rewrites)
- Give the trial doc and the weekly digest a path the cycle land may write, or fold them into the record (signal: the end-of-trial reading went to the roadmap because `--check-fix` refuses `docs/working/`)
- Generate the questions file's route table from `questions.sh`'s route list (signal: it listed the retired `agent`, `trigger` and `deferred` routes for days after decision 040)
- Re-dispatch a loop after a merge conflict without asking the owner (signal: Q-243 and Q-244's conflict cost six asks for two branches; merge-friction record, section 12)
- Say in the skill that a batched answer to named merge entries counts, as the trial doc asked if T3 was kept (signal: T3 kept, no such text; merge-friction record, section 12)
- Decide what backs up the release entry as the check on self-merged scripts, now that the owner says they do not read it closely (signal: T1 feedback against `docs/dev-cycle.md`; merge-friction record, section 12)
- Narrow the policy-file hook, which refuses Bash commands that only name the instruction file beside a redirect or a `.claude` path (signal: it blocked this cycle's brief writing, and the gloss-rule loop's read-only work)
- Delete the old Reader roots and Reader homes lines from `docs/dev-cycle.md` (lines 63 and 65), a file only the owner writes: `--settings` prints `readers ignored` on every call, which T7 counts as a bug (signal: iteration 2026-11-07-2324's `--settings` call)

## Brainstorm 2026-11-10

Ran because roadmap Now held one item ready for a brief and had changed since the last brainstorm (2026-11-06). Sources: this iteration's signals, this log, roadmap Ideas, and `docs/working/feature-ideas.md` (the one idea source `docs/dev-cycle.md` lists; a March 2026 design doc whose survivors have shipped, and none matched a current signal).

- Total what each dev-cycle iteration costs and how many were quiet, so the owner can decide the light pass of Q-154 (signal: iterations 2026-11-08-0036, 2026-11-08-0600 and 2026-11-10-1902 each re-decided 28 triggers with only cycle lands between them, and none fired; briefed)
- Give `scripts/confine-tests.sh` a first bats test before the sandbox merge makes it live (signal: the confine-tests research at be12889c found no test, and watch Q-161 revives confinement when Q-125 merges; briefed)
- Retarget the deferred review re-evaluation (review k, the lite review, A8) at the model now in use, and still ask before running (signal: the record's `Model:` line changed from `claude-opus-5-5` to `claude-fable-5-2`)
- Ask the owner once for the deep audit's scope and timing instead of listing its triggers in every final message (signal: the task has fired in most cycles since 2026-10-02 and never run; filed as Q-269)
- Give the skill a portable way to pass a list of names to a check, such as `xargs CHECK < FILE` (signal: this iteration ran in zsh, which has no `mapfile`, and the session's safety check refused zsh's array form)
- Move finished history out of roadmap Now (signal: the digest counted 9 Now items and one was ready to brief)
- Do nothing more on merge friction (signal: Q-267 and Q-268 have waited three days, and watch Q-262's wait condition needs a median over 48 hours for two weeks running)
- Look at `test/rubric-selection.bats` "emits nothing when two candidates tie" as a load-sensitive test (signal: the cycle-overhead loop's health check failed it once while reviewers and another loop's bats ran, then passed it 3 of 3 alone and in a full rerun)
- The batch-routing reminder hook fires on a subagent's hand-back report, which is not a user message and holds no list of asks (signal: iteration 2026-11-10-2013 began on such a report and got the reminder)
- Say in the skill what a fallback wakeup does when no loop has finished: check and wait, or run an iteration (signal: three wakeups on 2026-11-10 checked the loops and re-armed without an iteration, and the cycle-overhead doc counts 5 earlier wakeups that ran none)
- Keep a trigger's corrected evidence from being lost when later iterations rewrite the verdict list (signal: the cycle-overhead doc found the log row 57 correction of 2026-11-05-2347 gone from the next two full lists, and 27 of 72 full iterations wrote one "as at" line)
- Record tokens per iteration, starting with what task notifications already report for each build loop (signal: Q-270's option [4]; the cycle-overhead doc found no token count in the repo)
- Keep a test or probe that starts an interactive shell from writing the sandbox's shell history: unset `HISTFILE` in the test helper or the build-loop prompt (signal: the skill-fixes loop's paste tests overwrote `/commandhistory/.bash_history`, 503 lines, the earlier content lost)
- Give the review-fix loop a way to get one more read when its last round changed gate code, instead of ending at its cap with an unread fix (signal: Q-271's paste changed shape in each of three rounds and the third shape went to the owner unread)
- Size a brief against what its review will cost, not only its line count: three small units today each spent 1.3M to 2.0M subagent tokens on review (signal: the loops' own reports for the skill fixes, the confine-tests test and its fix; Q-270's option [4])
- Read a hard constraint whole when a brief cites it: the confine-tests fix brief quoted H2's "names what went unenforced" and left out "refuses" (signal: Q-272, raised by the loop's security review)
- Let models answer their own questions from the repo's docs, measured first (signal: the owner's request of 2026-11-11; Q-272 was answerable from hard constraint H2; on the roadmap, step 1 briefed)

## Brainstorm 2026-11-11

Ran because 10 ideas were seeded since the last brainstorm (2026-11-10). Sources: this log's ten seeds and this iteration's signals; `docs/working/feature-ideas.md` was read on 2026-11-10 and has not changed. Seven went to roadmap Ideas, two were already acted on (the self-answering plan is Now; the cycle-overhead numbers are Q-270), and one is dropped below.

- Do nothing about "move finished history out of Now" as a separate item: step 6 can do it whenever an item is fully merged (signal: seeded 2026-11-10 from the digest's count of 9 Now items)
- After a release that changes what sessions run, the first cycle on the new image checks the watches that waited on it (signal: Q-161 and Q-098 both wait on Q-273's install, and nothing but their dated notes says so)

- Have an owner entry name the doc that bears on it when one does (signal: the self-answer measurement at fd325a74 found about half of the in-part entries did not; it shortens an entry even where it cannot remove one)
- Fix the docs that contradicted each other before adding any lookup over them (signal: the same measurement: 6 entries exist only because two docs disagreed, and 4 where a doc named a different answer than the owner's)
- A docs-only measurement unit cost about 2.5M subagent tokens in readers and reviewers (signal: the self-answer loop's report; feeds Q-270's token question)
- Step 4's drift check counts a soft-line prune only when the pruned option would otherwise have won, so a ranking loss stops reading as drift (signal: the constraint-drift audit found four of six flags were only wording, research-2026-11-11-constraint-drift-audit.md)
- If cycle tokens matter, look at build-loop cost (75% of cycle tokens; median 1.88M weighted per dispatch) before orchestrator steps (signal: research-2026-11-11-cycle-token-cost.md)

## Brainstorm 2026-11-12

Ran because roadmap Now holds at most one item ready for a brief (the D12 doc item, held to ride a review unit) and Now changed since the last brainstorm heading. Sources: this log's five seeds since 2026-11-11 and this iteration's signals; `docs/working/feature-ideas.md` not re-read (unchanged since 2026-11-10). Three went to roadmap Ideas; "do nothing" is recorded here.

- Brief the research halves of the two sandbox-gap items now, as docs-only units: Q-277 names them as reading, but either answer to it needs the same research (signal: three build-loop slots idle for three iterations while both items' first step is a research and divergent-design pass)
- Brief the D12 doc item alone once it has waited a set time for a review unit that touches the decision log (signal: ready since iteration 2026-11-12-0741, and no such unit is queued or likely while the rest of Now waits on Q-277)
- Keep a release entry's live-check history in a working doc the entry links, so the release notes can be rewritten whole each iteration as step 0.1 asks (signal: iteration 2026-11-12-1944 rewrote Q-273's notes around four dated paragraphs and an answer line it could not touch)
- Do nothing with the idle slots: everything substantive waits on Q-277 or a host run, and a loop briefed only to fill a slot spends review tokens and an owner merge entry (signal: Q-277 open one day; the token-cost doc puts 75% of cycle tokens in build loops)
- harness feedback, PreToolUse hook (friction): hook-blocks-land-on-question-prose: The hook blocked Bash calls that named `CLAUDE.md` next to a `.claude` or home (signal: harness feedback belegarth-herald F-001, docs/working/feedback/belegarth-herald.md)
- harness feedback, dev-cycle `--cycle-diff` (friction): cycle-diff-refuses-asked-on-merge-entry: `--cycle-diff` refused the line each time, saying the question's heading was not (signal: harness feedback belegarth-herald F-002, docs/working/feedback/belegarth-herald.md)
- harness feedback, dev-cycle D6 block (friction): d6-block-run-from-a-copy: Three things. The auto-approve hook failed to parse 5 D6 commands that looped over (signal: harness feedback belegarth-herald F-003, docs/working/feedback/belegarth-herald.md)
- harness feedback, build loop dispatch (friction): build-loops-cannot-read-harness-files: The `Read` tool refused them, because the setting blocks reads outside the working (signal: harness feedback belegarth-herald F-004, docs/working/feedback/belegarth-herald.md)
- harness feedback, build loop `--merge` (friction): merge-floor-refuses-a-self-merge-brief: `--merge` refused 1 of 3 paths as not the brief's own file, and the brief fell through (signal: harness feedback belegarth-herald F-005, docs/working/feedback/belegarth-herald.md)
- harness feedback, permissions.additionalDirectories with harness symlinks (fails): added-guides-dir-still-refused-via-symlink: It still refused the guide with the same outside-the-working-directories message. (signal: harness feedback belegarth-herald F-006, docs/working/feedback/belegarth-herald.md)
- harness feedback, PreToolUse hook (web taint) (friction): web-taint-hook-asks-on-build-files: After one or two web searches, the hook asked for approval on each later write to (signal: harness feedback belegarth-herald F-007, docs/working/feedback/belegarth-herald.md)
- harness feedback, Bash working-directory check (friction): bash-refused-after-worktree-removed: The call was not run, with "the working directory no longer leads where it did" or (signal: harness feedback belegarth-herald F-008, docs/working/feedback/belegarth-herald.md)
- harness feedback, Agent tool worktree isolation (fails): agent-worktree-isolation-fails: Both Agent calls failed: Claude Code could not confirm that the repository's `.git` (signal: harness feedback belegarth-herald F-009, docs/working/feedback/belegarth-herald.md)
- harness feedback, Write tool in subagents (friction): subagent-report-file-write-refused: The Write tool refused both, saying subagents should return findings as text, not (signal: harness feedback belegarth-herald F-010, docs/working/feedback/belegarth-herald.md)
- harness feedback, Bash permission prompt (compound command) (friction): compound-read-of-home-claude-md-prompted: It prompted. The owner declined it, then said it was a misclick, and the session (signal: harness feedback belegarth-herald F-011, docs/working/feedback/belegarth-herald.md)
- harness feedback, sandbox egress firewall (fails): sandbox-egress-refused-dl-google-com: The proxy refused `dl.google.com` (`FAIL sni=dl.google.com` in its log), so builds (signal: harness feedback belegarth-herald F-012, docs/working/feedback/belegarth-herald.md)

## Brainstorm 2026-11-12

Trigger: 12 seeds since the last brainstorm (the herald ingest, 30eb0229). Signals: the sandbox rollback (7caea26d, Q-277 [3]), decision-log row 86's trigger firing on an install from 80b7dabe, herald F-001 to F-012.

- Brief one research unit for the sandbox's return covering all three requirements (worktrees, nested paths, the credential after a refresh): briefed this iteration (signal: Q-277 [3] makes worktree creation a third requirement; the earlier seed to brief the gaps' research)
- Add a sandboxed `git worktree add` line to the live check file (signal: the live check passed every line but three, yet the sandbox broke worktree creation, which no line tested)
- Make the by-hand worktree fallback the default for parallel-worktrees in cc-isolated (signal: herald F-009 and 7caea26d both saw Agent worktree isolation refused in the container)
- Have install.sh print the gate-code diff from the last release entry's M (signal: decision-log row 86's trigger fired: the image at 80b7dabe was installed outside Q-273's paste for 7b8b560a); filed as an agent item to look at first
- Triage the herald friction list as one grouped unit (signal: 12 seeds from one ingest, several about hooks this repo ships)
- Do nothing more with the slots this iteration: one research unit is enough while the sandbox design is open (signal: 75% of cycle tokens go to build loops, per the token-cost doc)
- A brief template line that a self-merge brief's research doc is `docs/working/research-STEM.md`, the name the gate reads (signal: iteration 2026-11-13-0143 wrote a brief naming another file in Paths:, caught only by reading the --start prompt)
