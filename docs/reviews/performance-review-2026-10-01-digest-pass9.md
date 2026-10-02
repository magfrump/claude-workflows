Commit: d503a43 (A) / 1ae9b21 (B)

# Performance Review — dev-cycle pass 9 (k=1 loop pass; pass-8 fix round)

**Scope:** Partial: the pass-8 fix round only. A: `git diff ab8ec06..d503a43 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (worktree `/workspace/.claude/wt-digest`, HEAD 56dfa86; `scripts/` and `test/` are identical to d503a43). B: `git diff cfe4b51..1ae9b21 -- skills/dev-cycle/SKILL.md docs/dev-cycle.md docs/working/questions.md` (worktree `/workspace/.claude/wt-devcycle`, read at 1ae9b21 via `git show`). Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass8.md` (Stage-1 context; it covers the round before this one, so no claim of this round has an execution verdict yet), the pass-8 rubric section "Pass 8", and `docs/reviews/performance-review-2026-10-01-digest-pass8.md`.

Line numbers: A at d503a43, B at 1ae9b21. Probes ran under `timeout` in `mktemp -d` dirs under `scratchpad/perf9/`; nothing was written to either worktree except this file, and no process was left running.

## Data Flow and Hot Paths

**A (digest).** `scripts/dev-cycle.sh` runs once per dev cycle (cold path; "cycles vary from fortnightly to many a day", SKILL.md:183-184). The only code change is `inrepo`'s final comparison: `[[ "$r" == "$ROOT_REAL/$1" ]]` in place of a prefix match. The fork count is unchanged: one `$(realpath -e …)` subshell per call, called once per cycle-record file (line 119), once per decision record (line 155), and once each for the log, questions, roadmap (twice) and idea log. N grows by one cycle record per cycle and one decision record per major decision, so tens to low hundreds of forks per run: negligible. The test change doubles test 5's fixture from 600 to 1200 lines and rewrites the timing comment.

**B (skill).** The procedure is executed by an agent, not a machine, so the cost units are agent tool calls, whole build loops (one autonomous RPI run plus pr-prep's review-fix loop each, the most expensive unit this skill spends), and user attention. The pass-8 round changed four rules: the policy parse, the per-component symlink check, the per-brief path allowlist, and the three In-flight outcomes. The questions to answer are: can the new lifecycle burn a whole build loop and then send the item back for a rebuild, and are the per-cycle and per-loop checks bounded?

## Findings

#### 1. Every build loop must write a questions file to finish, but the brief's Paths list can never include one, so finishing becomes a stop condition, and an entry filed on the loop's branch is invisible to the next cycle, which then sends the finished item to Ideas

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:242-247` (Paths), `skills/dev-cycle/SKILL.md:296-300` (what a loop files), `skills/dev-cycle/SKILL.md:215-220` (In-flight outcomes)
**Move:** Hidden multiplication (one whole build loop spent per round trip); work moved to the wrong place
**Classification:** Macro (each lost round trip costs a whole build loop plus a user decision) / Cold path, but it qualifies for the gate's "runs over large data" exception, because each unit is a multi-hour autonomous run
**Confidence:** Medium (the skill does not say where a loop files its entries; the finding holds for the reading in which the loop files them on its own branch, the default for a loop that works in its own worktree)
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** no baseline available — flagged as speculative

**Evidence:** "**Paths**: the files and directories the work may change. Changing anything else is a stop condition. The list never includes hook, enforcement or harness-settings files, the roadmap, the questions files, `docs/dev-cycle.md` or `docs/working/handoffs/`; work that needs one of them is not handed to a loop." (242-245) Against: "**`review`**: the loop runs `pr-prep`'s review-fix loop, then stops without merging: it opens a PR where the project uses them, otherwise it files one `you: judgment` entry, "merge <branch>?", naming the roadmap item. / Either way, a build that hits a stop condition files a `you: judgment` entry naming the roadmap item instead of guessing." (296-300). And: "running, or finished and waiting on the user's merge decision (an open PR or an open `merge <branch>?` entry) → stays, however long; … ended any other way (merge declined, a stop condition hit, or still building with no commit on its branch for 7 days) → Ideas" (215-220).

In a repo with no PRs (this one: Q-103 option [1] says "no PRs here"), each loop's two possible exits are both writes to `docs/working/questions.md`. That file is excluded from every brief's Paths, so by line 243 the exit is itself a stop condition, which in turn files another entry (300): the rule triggers itself. Where the entry lands is not said. If the loop commits it on its branch, which is the only branch it works on, then `main`'s `questions.md` has no open `merge <branch>?` entry when the next cycle checks the item (215-216). The item is then "finished" but not "waiting on an open entry", so it falls to "ended any other way" → Ideas (218-220), its brief is closed, and only the user can bring it back (222-224). The user never saw the merge question. The loop's whole run is spent, and a re-promotion writes a new brief and launches a new loop (233-237), so the cost is one build loop per round trip, plus the user's attention to notice and re-promote. Under `review`, the default and the current interim value, this applies to every item handed off, not to an edge case. A loop that applies the settings rule's "unless an open `you: judgment` entry already asks for the setting, file one" (58-59) at merge time writes the same excluded file (see finding 5).

**Recommendation:** Name the loop's exits as outside the Paths rule and say where they land. For example: "a loop's own `merge <branch>?` or stop-condition entry is filed on the default branch's `docs/working/questions.md` in one commit naming only that file, and is not a change under Paths". Or have the loop return the entry text in its final report and let the next cycle file it. In either case, make line 216's "open entry" check read the place the entry actually lands.

#### 2. Paths must also cover the artifacts RPI and pr-prep always write (`docs/working/research-*`, `plan-*`, `checkpoint-*`, `docs/reviews/*`, the override log), and the obvious way to cover them, listing `docs/working/`, contains two excluded paths

**Severity:** Medium
**Location:** `skills/dev-cycle/SKILL.md:242-247`, `skills/dev-cycle/SKILL.md:286-289`; context `workflows/research-plan-implement.md:28-32`, `workflows/pr-prep.md:25`
**Move:** Hidden multiplication (a stop at pr-prep's artifact commit wastes a nearly finished loop)
**Classification:** Macro (whole-loop waste per affected brief) / Cold path with the large-unit exception, as in finding 1
**Confidence:** Medium (a careful brief writer can list these globs by hand; the skill neither requires nor mentions them)
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** no baseline available — flagged as speculative

**Evidence:** "start an autonomous build loop (`research-plan-implement`) in its own worktree on the brief's branch" (286-287). RPI: "This workflow produces markdown artifacts in `docs/working/` within the project: - `docs/working/research-{topic}.md` … - `docs/working/plan-{topic}.md` … - `docs/working/checkpoint-{topic}.md`" (`workflows/research-plan-implement.md:28-32`). pr-prep: "**Commit the review artifacts on the branch** (`docs/reviews/`, override-log rows) before merging, so they land with the change." (`workflows/pr-prep.md:25`). The brief's Paths: "Changing anything else is a stop condition." (SKILL.md:242-243)

The skill tells the brief to list "the files and directories the work may change", and a writer naturally lists the product files. The process artifacts of the loop the skill itself starts are then outside Paths. The RPI research doc is the loop's first write. The `docs/reviews/` commit comes at the end, after the whole review-fix loop, so a stop there costs a nearly complete run and sends the item to Ideas (218-220). Covering them by directory is the obvious fix, but `docs/working/` contains `docs/working/handoffs/` and the questions files, which "the list never includes". The writer must instead enumerate topic-named files whose names RPI chooses later. This is not an exclusion that makes the work impossible, but it is a gap that a reasonable reading of the rule falls into on every brief.

**Recommendation:** State in the Paths bullet that the loop's own process artifacts (`docs/working/{research,plan,checkpoint,pre-mortem}-*.md`, `docs/reviews/`) are always allowed and are not "the work". Or make the brief template list them by default.

#### 3. A `merge <branch>?` answered "yes" but not yet merged matches none of the three outcomes except the catch-all, so approved work goes to Ideas and can be rebuilt

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:213-224`; `skills/dev-cycle/SKILL.md:115-116` (archive before step 6)
**Move:** Find the work that moved to the wrong place (the user's decision is lost between archive and classification)
**Classification:** Macro (whole-loop rebuild when it bites) / Cold path, per cycle
**Confidence:** Medium (no step in the skill performs the merge on a "yes", so the gap is real; how often it bites depends on how fast the user, or some other session, acts on their own answer)
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** no baseline available — flagged as speculative

**Evidence:** "running, or finished and waiting on the user's merge decision (an open PR or an open `merge <branch>?` entry) → stays, however long; - merged → Done; - ended any other way (merge declined, a stop condition hit, or still building with no commit on its branch for 7 days) → Ideas, with the reason and a link to the brief; the branch is kept." (215-220) and "`~/.claude/scripts/questions.sh archive` then `index`, so answered entries leave the live file." (115-116)

The three outcomes are claimed exhaustive, and they are, but only through the catch-all. An entry answered "yes" is no longer open, so the item is not "waiting"; the branch is not merged, so it is not "Done"; "ended any other way" therefore takes it, although the user approved the work. Nothing in steps 1–7 merges an approved branch. Step 3 handles only `trigger`, `deferred` and `agent` entries (139-146), and step 1 archives the answer before step 6 runs. The line-214 note ("answers to its entries may already be in `questions-archive.md`") lets the cycle *see* the "yes", but no outcome uses it. The cost is the user's decision plus, if they re-promote the item to Now, a fresh brief and loop for work that already passed review.

**Recommendation:** Add "merge approved (entry answered yes, or the PR approved) → land the kept branch through pr-prep in this cycle, then Done", or route it to one `agent` entry. Keep "Ideas" for declined and abandoned work only.

#### 4. "Running" and "no commit for 7 days" overlap; moving a live loop's item to Ideas frees an in-flight slot without stopping the loop, so concurrent loops can exceed the cap of 3, and its later self-merge goes untracked

**Severity:** Low
**Location:** `skills/dev-cycle/SKILL.md:215-220`, `skills/dev-cycle/SKILL.md:233-235`, `skills/dev-cycle/SKILL.md:110` (stop only this session's processes)
**Move:** Find the contention point (the cap counts roadmap rows, not running loops); trace the lifecycle
**Classification:** Macro (the number of concurrent loops is not bounded by the cap) / Cold path
**Confidence:** Low–Medium (a loop that is alive but silent for 7 days is rare; when it happens, the effect follows directly from the text)
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** no baseline available — flagged as speculative

**Evidence:** "running, or finished and waiting on the user's merge decision … → stays, however long;" vs "still building with no commit on its branch for 7 days → Ideas" (215-219). "up to the in-flight cap: at most 3 items In flight at once, counting earlier cycles'." (234-235). "stop only processes this session started, by PID" (110).

A loop that is still building but has made no commit for 7 days matches both "running → stays" and "→ Ideas". Precedence is only implied by specificity, so the three outcomes overlap here and are not disjoint. The cycle cannot observe "running" directly (the loop runs in another session) and may not stop it, so taking the Ideas branch closes the brief and frees a cap slot while the loop may still be alive. Each later cycle can then launch 3 more loops, so the running count is bounded by the cap only if silent loops are in fact dead. If the live loop later self-merges, the item sits in Ideas while its work is on `main`; Done never records it, and a user re-promotion rebuilds merged work. It also cannot look up `Status: closed` in its own brief, because "the loop reads the brief from that commit" (288-289).

**Recommendation:** Make the 7-day rule the explicit exception ("running with a commit in the last 7 days"). When it fires, file one `you: terminal` entry to stop the loop, and keep the item's slot counted until that entry is answered. A merge that lands for a closed brief goes to Done, not Ideas.

#### 5. Concurrent loops reading an unset policy at merge time could each file the same "set the build-loop policy" entry

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:57-59`, `skills/dev-cycle/SKILL.md:290-293`
**Move:** Find the contention point (check-then-file on shared state from up to 3 parallel loops)
**Classification:** Micro (at most 3 duplicate entries per cycle) / Cold path
**Confidence:** Low (the skill does not say whether the filing clause binds build loops or only the cycle; in this repo Q-103 is open, so nothing files today)
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** no baseline available — flagged as speculative

**Evidence:** "Unset (no file, no such line, both lines, or any other text such as `review (interim; Q-103)`): use `review`, and unless an open `you: judgment` entry already asks for the setting, file one." (57-59). "the build-loop policy in the default branch's `docs/dev-cycle.md` at the moment the loop would merge" (291-292).

Each loop now reads the setting itself at merge time. If a loop follows the full settings rule, including "file one", then up to three loops finishing in the same window each check that no entry is open and each file one. Each write is also outside Paths (finding 1). The cost is up to 3 duplicate `you: judgment` entries per cycle when the setting is unset and unasked.

**Recommendation:** Say in 6b that a loop only *reads* the setting (unset → `review`) and never files the policy question; the cycle alone files it.

#### 6. The per-component symlink check runs by hand "before each read or write", so its cost scales with paths × depth × accesses, and the `## Skipped paths` list has no bound

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:62-67`, `skills/dev-cycle/SKILL.md:269`
**Move:** Count the hidden multiplications; trace the memory lifecycle (record growth)
**Classification:** Micro (a `test -L` per component) / Cold path, per cycle
**Confidence:** High for the scaling shape; Low that it matters at this repo's size
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** no baseline available — flagged as speculative

**Evidence:** "before each read or write, check that no part of the path below the repo root is a symlink (`test -L` on each component; a file not yet created is checked through its directories). A path that fails is skipped and listed in the record under `## Skipped paths`." (63-66)

The check can be done with ordinary tools: one shell loop over the components runs `test -L` on each, and for an uncreated file it checks the existing directories. Taken literally, though, it runs per access, not per path per cycle. The roadmap and questions file are read and written in several steps (1, 3, 6, 7), and an idea-source glob multiplies it by its match count. An agent doing one tool call per check pays O(paths × accesses) calls. Within one cycle the result can only change if the cycle itself creates a symlink. The `## Skipped paths` section lists every failing path with no cap, so a glob over a symlinked directory of N files writes N lines into a committed record. This carries forward pass-8 finding 4 (Informational), now on the new rule.

**Recommendation:** Allow one check per path per cycle (re-check only after the cycle itself changes a directory), and cap the list (for example, the first 20 paths and a count), as section 6 of the digest already does for its file lists.

## Endorsements

- `inrepo`'s rewrite adds no work: it still forks one `realpath -e` per call at the same call sites, and only the final test changes from a prefix glob to an exact string comparison. [read: scripts/dev-cycle.sh:86-92, 118-120, 154-156, 164, 181, 214, 262, 271]
- Claim (brief item 1, the plain-path half): with the repo under a symlinked parent directory and the script run from a subdirectory, the digest still reads the cycle-record glob, a decision record, the log, the roadmap and the idea log. Probe `perf9/sym.*`: TRIG1, LOGROW, "Roadmap Now: 1", "Ideas seeded since: 1" and the cycle-record window were all printed. The questions branch was not probed. [unverified — submitted as claim]
- Claim: test 5's new comment ("~35 s on the authoring host for these 1200 lines, against about 1 s with the resume") holds on this host. The 1200-line fixture took 1.03 s on d503a43 and 34.65 s on the no-resume mutant `fc8/mut.J9cy/m1`, so the 10 s timeout gives the fix about 10× headroom and fails the mutant about 3.5× over. The full suite passed 20/20 in 5.3 s, test 5 in 2.5 s. [unverified — submitted as claim]
- The policy rule fails safe in cost terms. Every variant that is not exactly one of the two lines resolves to `review`, and the stricter-of-two can only lower a loop's policy, never raise it, so no input makes a loop merge unreviewed more often than the brief allowed. [read: skills/dev-cycle/SKILL.md:54-59, 290-293]
- The "returns to Now only when the user puts it there" rule removes pass-8 findings 1–2's autonomous re-queue loop. With no route from Ideas to the handoff queue except the user, no cycle can rebuild a returned item on its own (findings 1, 3 and 4 above are user-mediated rebuilds, not autonomous loops). [read: skills/dev-cycle/SKILL.md:218-224, 233-237]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Loop exits (merge / stop entries) write the questions file, which Paths excludes; a stop that triggers itself; an entry on the branch is invisible on `main`, so a finished item goes to Ideas and is rebuilt | Medium | `skills/dev-cycle/SKILL.md:242-247, 296-300, 215-220` | Medium |
| 2 | Paths silent on RPI/pr-prep artifacts; covering `docs/working/` collides with the exclusions; stop at the final artifact commit wastes a near-complete loop | Medium | `skills/dev-cycle/SKILL.md:242-247, 286-289` | Medium |
| 3 | "Merge approved, not yet merged" has no outcome but the catch-all → Ideas; approved work can be rebuilt | Low | `skills/dev-cycle/SKILL.md:213-224, 115-116` | Medium |
| 4 | "Running" overlaps "7 days silent"; moving a live loop to Ideas frees a cap slot without stopping it; its later merge goes untracked | Low | `skills/dev-cycle/SKILL.md:215-220, 233-235, 110` | Low–Medium |
| 5 | Up to 3 loops may each file the unset-policy entry | Informational | `skills/dev-cycle/SKILL.md:57-59, 290-293` | Low |
| 6 | Symlink check per access, not per path per cycle; `## Skipped paths` unbounded | Informational | `skills/dev-cycle/SKILL.md:62-67, 269` | High / Low |

## Overall Assessment

The digest half (A) is clean for performance. The `inrepo` change keeps the same fork count and only tightens the comparison. Test 5's doubled fixture still separates the fix (1.0 s) from the no-resume mutant (34.7 s) with wide margins on both sides of the 10 s timeout. A probe with the repo under a symlinked parent directory, run from a subdirectory, read every plain path checked. The skill half (B) fixes pass 8's autonomous re-queue loop: nothing returns an item to Now without the user. But its new path allowlist has a gap: the exits every build loop must take, a `merge <branch>?` or stop entry in the questions file, are outside every brief's Paths and land at an unspecified place. Read with the In-flight outcomes, the default `review` policy can spend a whole build loop and then file the finished item under Ideas, so the only way forward is a user-triggered rebuild. Findings 1 and 2 are the ones to fix before the clean pass. Both are fixable in place with one sentence each in the Paths bullet (which writes are the loop's own bookkeeping, and where entries land), and finding 3 needs one more outcome line. None needs profiling. All findings are speculative cost reasoning from the procedure's text, and findings 1 and 3 should go to the fact-check stage as claims about where a loop's entry lands and who merges an approved branch.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-01-digest-pass9.md` with the skill's header, Data Flow, Findings (each with Severity, Location, Move, Classification, Confidence, Baseline, plus the brief's Evidence and Legibility-target), evidence-tagged Endorsements, Summary Table and Overall Assessment. It serves the user goal (merge both branches once a clean pass is reached) by naming two Medium findings that stand between this round and a clean pass.
