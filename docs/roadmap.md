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

- **Agent: confine-tests follow-ups** (filed 2026-11-07, step 7). Motive: the research
  merged at be12889c (`docs/working/research-2026-11-07-confine-tests-situation.md`) found
  the script refuses here (no bwrap, `unshare -rn` EPERM), has never run with a primitive,
  and has no test. First step: in briefs whose acceptance names tests, use its conditional
  wording (run `scripts/confine-tests.sh --probe`; exit 0: tests pass confined; exit 3:
  quote its first line and rely on `scripts/run-tests.sh` plus the hermeticity lint). Then
  add a `--probe` line to Q-125's live run when its paste is filed. The rest are Ideas.
  2026-11-10: the conditional wording is in all three briefs written today, Q-267 (the
  sandbox merge entry) names the `--probe` run as a step after the install, and the bats
  test is In flight. What remains here is that `--probe` run, once Q-267 merges and installs.
  The test merged at 9d6d6101 and found two defects, now In flight as their own brief. It
  also noted that `--probe` asks `bwrap` for less than a run does, so a probe can pass and
  the run then fail to start: check that in the same `--probe` run.
  The two defects are fixed (b0ebed19). Whether the `unshare` fallback should run or refuse
  is Q-272. For the first live run: confirm the script's bash starts under a real
  `unshare -rn`, and count the tests that skip as uid 0 (ten, by the loop's count), since a
  pass from that tier covers less. When a probe names `unshare`, a brief's test step also
  quotes the run's first stderr line. Two small records wait for a review merge that
  touches them anyway: decision 018 cites `scripts/confine-tests.sh:220`, a line that moved
  (the comment above it now opens "Decision 018's reference pattern"), and
  `docs/failure-patterns.md` may deserve an entry for `exec "$@"` under `sh` reading a
  dash-leading word as an option where `sh` is bash.
  2026-11-13: those two records merged with the small-records review unit (00e2e663, Done);
  what remains here is the first live `--probe` run.
  2026-11-18: the run-or-refuse question now waits on watch Q-301 (`docs/working/watching.md`), not Q-278.

- **Trial week: less friction, less habituation (2026-10-30 to about 2026-11-06).** Motive:
  the owner's 2026-10-29 brainstorm request ("try things for a few days to a week").
  Every iteration writes owner entries, the image-lag entry and the final message as
  `docs/working/trials/2026-10-30-friction-engagement.md` says (T1-T7), and the first
  iteration of each week writes `docs/working/weekly/`. First step: done (T1, T2, T4, T5 started
  2026-10-30). Owner feedback on T1-T7 recorded there on 2026-11-06.
  The owner's decision (2026-11-06, after the cycle's reading): "none of them have hurt and
  some have helped so let's commit them and start a new set of trials". So T1-T7 all stay,
  T4 included, and they are written into the skill (3dbf43cb, live in the image since 2026-11-10). A1/A3/A10: no change (Done; watch Q-262). New set: T8-T12, in
  `docs/working/trials/2026-11-06-attention-and-trust.md`, running to about 2026-11-13; no owner feedback on it yet.
  2026-11-13: the set's end is asked in Q-286 (keep all, some, or none).
  2026-11-14: Q-286 answered in session: extend a week, all five running to about 2026-11-20,
  because T11 and T12 live in the weekly digest and have had one edition. Ask again after the
  2026-11-20 weekly digest.

- **Review-gap audit in Behemoth Arsenal** (owner feedback 2026-10-29, point 3). Motive: the
  gap that prompted the audit came up in Behemoth Arsenal; the run here (84f8532e,
  `docs/working/research-2026-11-13-review-gap-audit.md`) found 21 amber rows that reached
  main open, and its fixes merged. What remains is the read-only paste in that repo, which
  is the owner's: Q-302. First step after the answer: compare its gaps and causes with this
  repo's, and file any cause the fixes here do not cover.

- **Agent: Step 0 tests worktree creation first, and names where a stop goes with no worktree** (filed 2026-11-19, step 6; moved from Ideas: it carries reported friction).
  (brainstorm 2026-11-16). Signal: philosophy-research F-018, a read-only `.git/worktrees`
  stopped an iteration with nowhere to file the stop; decision-log row 88 keeps worktrees
  as how agents work.
  2026-11-19: moved to Now by step 6 (iteration 2316). First step: the one the signal names; if none, a research or divergent-design pass on it.

- **Agent: A per-repo health-checkout preparation line** (filed 2026-11-19, step 6; moved from Ideas: it carries reported friction). (brainstorm 2026-11-16). Signal:
  philosophy-research F-016: a fresh health checkout has no Lean build cache (1.9 GB), so
  the iteration linked and copied it in by hand. First step: a `docs/dev-cycle.md` line
  naming paths to link or copy from the main checkout, read through `--settings`.
  2026-11-19: moved to Now by step 6 (iteration 2316). First step: the one the signal names; if none, a research or divergent-design pass on it.

- **Agent: A judgment entry's "Why it's yours" quotes the constraint it relies on** (filed 2026-11-19, step 6; moved from Ideas: it carries reported friction). (brainstorm
  2026-11-16). Signal: philosophy-research F-007, an entry that cited H1 for a change H1
  does not cover, so the whole entry should not have reached the owner.
  2026-11-19: moved to Now by step 6 (iteration 2316). First step: the one the signal names; if none, a research or divergent-design pass on it.

- **Agent: Build loops start in the orchestrator's removed worktree** (filed 2026-11-19, step 7; herald F-008). Motive: every loop
  dispatched before the cycle's land loses its first Bash call, because the cycle removes its
  worktree after the land while the loop's shell starts there; it reproduced in the 2026-11-19
  herald triage dispatch. First step: the hermetic probe in group F of
  `docs/working/research-2026-11-19-herald-friction-triage.md` (does a main-session `cd` before
  an Agent call move the subagent's start directory?), then divergent design over its four
  approaches. Gate code, so a review merge.

- **Agent: Send a gate-refused ready branch back to its loop, with no owner entry** (filed 2026-11-19,
  step 7; philosophy-research F-006, F-009, F-010). Motive: about 9 re-dispatch answers across the
  repos, each followed by a second merge answer on review briefs. The research (7c137d5d,
  `docs/working/research-2026-11-19-generated-file-conflicts.md`) picked: step 7 sends a branch the
  gate refuses for a conflict with main, or a gap the loop can fix, back once per tip while
  `Dispatched:` is under 3. First step: the review brief its "For the dev cycle" section drafts
  (`skills/dev-cycle/SKILL.md`, gate code). Held: it is area A's ground, asked in Q-312.

## In flight

- **Agent: The cycle cannot create a project's harness-feedback file** (filed 2026-11-19, step 6; moved from Ideas: it carries reported friction). Signal: philosophy-research
  F-002: `--check-fix` refuses every new file, so the owner made it by hand. Allow
  `harness-feedback.py init` and appends in-cycle outside claude-workflows.
  2026-11-19: moved to Now by step 6 (iteration 2316). First step: the one the signal names; if none, a research or divergent-design pass on it.
  2026-11-19: briefed (iteration 0014 UTC): `docs/working/briefs/2026-11-19-harness-feedback-file-in-cycle.md`.

- **A8 settling runs: csp self-read and corpus inline** (Q-308 [1], owner in session 2026-11-19).
  Motive: the first A8 pass found inlining saves nothing on the Agent-tool path, leaving its net
  cost and recall effect unmeasured; these two passes measure both. Briefed (iteration 0056 UTC):
  `docs/working/briefs/2026-11-19-a8-settling-runs.md`; dispatched 2026-11-19 (iteration 0110
  UTC), after the lever #3 correction merged (d383a484), so both passes run the corrected skill.

- **Agent: code-review lever #3 follow-ons in other files** (filed 2026-11-19, from the lever
  #3 loop's report; not built on its branch, by its brief). Motive: the same two claims the
  lever #3 correction removes from `skills/code-review/SKILL.md` also live elsewhere: the
  "paste each sub-agent's skill text, it cannot read your files" rule in
  `skills/draft-review/SKILL.md` (:172, :231-233, :560), `skills/matrix-analysis/SKILL.md`
  (:116, :422) and `workflows/divergent-design.md` (:213); the "cacheable prefix" claim in
  `patterns/orchestrated-review.md` (:151) and `guides/sub-agent-briefing.md` (:78). Also:
  rubric row A7 in `docs/reviews/code-review-rubric-2026-08-07-main.md` reads Fixed for a
  cross-pass cache warmth that does not exist on this path, and decision-log row 35 counts
  10 contract tests where there are now 13. First step: once the lever #3 correction merges
  (its wording is the model), one review brief over these files; `workflows/` is a never
  glob, so review.
  2026-11-19: briefed (iteration 0110 UTC), the correction having merged (d383a484):
  `docs/working/briefs/2026-11-19-lever3-followons.md`.

## Next

1. **Agent first-pass playtest before each `you: walkthrough`** (owner request, 2026-11-12;
   proposal `docs/thoughts/proposal-2026-11-12-agent-first-pass-playtest.md`). Motive: a
   walkthrough spends the owner's most expensive time, and its first stretch may go on
   problems an agent could have found (a launch that fails, a README step missing). The
   owner says it needs consideration, so nothing is built yet. First step: the proposal's
   step 1, measure first: classify the first reported problem of each answered
   `you: walkthrough` entry (mechanical, a finding only a person makes, or none), here and
   per project in each project's own session; under ~20% mechanical, stop and record that.
   Its three open questions (the first trial project, automatic or on request, Chromium in
   the image) wait for that number.
   2026-11-13: step 1 done (a91d42af, self-merge;
   `docs/working/research-2026-11-13-walkthrough-first-problem-measure.md`): this repo has
   no answered `you: walkthrough` entry, so "too few to decide". The three open questions
   are drafted in the loop's marker and held until another repo reports its own count,
   since the first (which project to try first) depends on which repos have walkthroughs.
2. **Revisit the 2-hour wait before re-dispatching an unfinished loop** (owner request,
   2026-11-19: "seems excessive"; not for this release). Motive: `build-loop.sh --prompt
   --steal` takes a loop's locked worktree only when the loop left a marker, or when both
   lock and tip are over `STEAL_AGE` (7200 s, decision D1 in
   `docs/working/plan-build-loop-handoff.md`), because the gate cannot tell a dead loop
   from a live one, perhaps another session's, from git state alone. On 2026-11-19 the
   F-019 loop ended without a marker 7 minutes after its last commit, this session's task
   notification said so, and the re-dispatch still waited two hours. First step: list what
   a lock holder could prove it is gone (the dispatching session's own record of its
   subagent ending, a heartbeat, a shorter age for this session's own loops) and weigh
   each against D1's case (a live loop in another session, S1's honest-slip threat model),
   then pick the threshold or mechanism; gate code, so a review merge.
   2026-11-19, later: two loops in one evening (F-019's at 20:01 UTC, the lever #3
   correction's at 21:47 UTC) were told to hand back before their confirming review
   reported, with work committed and no marker; each then waits the full two hours.

## Ideas

- **Models answer their own questions from the repo's docs** (owner request 2026-11-11;
  parked, moved from Now 2026-11-18). Signal: the measure
  (`docs/working/research-2026-11-11-self-answer-measure.md`, fd325a74) found at most 4 of
  200 answered judgment entries (2%) answered in full by an existing doc, so the owner chose
  to build nothing (Q-274 [1]). Steps 2 to 4 of the plan (design the lookup, guardrails, a
  trial week) come back only if watch Q-276 fires (the owner refuses the Q-272 exception
  when it returns with data). The plan's full text is in this file's history before
  2026-11-18 (`git log -S'Measure before designing' -- docs/roadmap.md`).

- **The next deep audit's sample.** Signal: step 4b fired 2026-11-13 (iteration 2250) on
  `skills/dev-cycle/SKILL.md` as f1238bdb (Q-289) changed it, after the constraint-drift item
  closed; with a1121ac5's Path A record (Done item above), it is what the next deep audit
  reads first. No audit is asked for now: the owner starts one by hand, or the cycle asks
  when a major design decision fires step 4b.
  2026-11-14 (iteration 2243): step 4b fired again on 21097afa (`workflows/pr-prep.md`,
  `workflows/review-fix-loop.md` and `skills/code-review/`, the review rules you approved in
  Q-293); the same sample takes it.
  2026-11-18 (iteration 2026-11-19-0300): step 4b fired on two new skills, `skills/audience-profiles/`
  and `skills/reader-testing/` (900 lines, merged 44000c6d and 386ccfa3 by hand); the same sample takes
  them, with one question added: do their lessons, each resting on one real session, hold on a second?
  2026-11-18 (iteration 2026-11-19-0717): step 4b fired on `skills/dev-cycle/SKILL.md` as
  22735b6e changed it (step 6's check of roadmap items no open entry or watch names); the same
  sample takes it.
  2026-11-19 (iteration 2026-11-19-2008): step 4b fired on `skills/dev-cycle/SKILL.md` as
  7661a2cf changed it (step 6 moves Ideas that carry reported friction); the same sample
  takes it.
  2026-11-19 (iteration 2026-11-19-2316): step 4b fired on `skills/dev-cycle/SKILL.md` and
  `workflows/parallel-worktrees.md` as b3e25cf1 changed them (worktrees under `.worktrees/`);
  the same sample takes them.
- **Record out-of-cycle session answers through `--answered`.** Signal: 4306aa88 (the owner's
  Q-281..284 answers, recorded on a hand branch) read as `other` in `--main-log`, making
  iteration 2026-11-13-2237 a full cycle with a health run.
- **Say what "a cycle" is in decision 040's ask-count trigger** (per day or per full block).
  Signal: 9 asks opened 2026-11-13 (Q-281..289), counted as one cycle.
- **Align the record template's `8.` line with step 8's new rule.** Signal: Q-289's loop kept
  the template's old wording because changing it needs a migration line in
  `scripts/lib/migrations.sh`; `docs/working/seed-build-loop-handoff.md:81` also restates the
  old "Take the Now items" rule. After Q-289 merges.
- **The board treats a repo with no `docs/working/` as not tracked.** Signal: Q-280's
  first host run exited 1 on a registered repo that is not a coding project. Status quo
  first: the owner comments that registry line out with `#`; build only if a second such
  repo appears.
- **A sandboxed worktree line in the live check** (brainstorm 2026-11-12). Signal: the
  sandbox's live check passed every line but three, yet the sandbox broke worktree creation,
  which no line tested (7caea26d). It would add a sandboxed `git worktree add` and
  remove to `docs/working/q125-verify-check.sh`; the research brief proposes the lines.
- **Brief the sandbox gaps' research now.** Signal: three build-loop slots idle for three
  iterations (2026-11-12) while both sandbox-gap Now items start with a research and
  divergent-design pass that either answer to Q-277 (install the sandbox with its two gaps
  written down, or hold the release) needs. Today the cycle reads Q-277 naming them as
  blocking a brief.
- **Give the D12 doc item a deadline to brief alone.** Signal: ready since iteration
  2026-11-12-0741, held to ride a review unit on the decision log, and none is queued.
- **Keep a release entry's live-check history in a linked working doc.** Signal: iteration
  2026-11-12-1944 rewrote Q-273's release notes around four dated paragraphs it had to keep.

Unranked. Each names the signal that motivates it.

- **Repeat the self-answer measurement in another repo.** Signal: the owner's note on
  Q-274 (2026-11-11): "I do expect this repo to be unusually hard to answer questions in,
  so a survey of other repos might change the numbers." The measurement doc
  (`docs/working/research-2026-11-11-self-answer-measure.md`, section 9.5) prices it: about
  1.3 million tokens plus review for the full count, or a read of the other repo's last 14
  hand-written entries for the cheap one. It needs a session in that repo, since no
  session here reads another checkout.

- **`scripts/run-tests.sh` runs the confinement probe and confines itself when it can.**
  Signal: the confine-tests research (be12889c); S4 ranks a script over brief prose.
- **A Landlock tier in `scripts/confine-tests.sh`.** Signal: the same research found
  Landlock ABI 7 works unprivileged here and blocks a child's outgoing TCP (not UDP, and by
  port only), which partly refutes decision 017's finding 1. Needs a 017 amendment.

- **Give a decision's runtime-log trigger a readable route.** Signal: decision 039's trigger names `/run/cc-sni-proxy/proxy.log`, which `--check-path` always refuses as untracked, so the cycle can only ever answer "cannot tell". Either a read-only runtime-log allowance, or the log's FAIL count in Q-255's paste. Gate code if the former.
- **Things waiting for a release need a list of their own.** Signal: Q-241's item planned to ride on Q-252's next rewrite, and the release came first, so Q-252 closed with no rewrite. A section the close step reads would stop the next one being lost.
- **A trial needs a closing step.** Signal: the trial week reached its end date with feedback on only part of T1-T7, and nothing asks for the rest but a line in the final message.
- **Skip the health rerun for docs-only `other` commits.** Signal: adb22f4d cost a full run.
- **Keep a loop's tests from writing the sandbox's shell history.** Signal: the skill-fixes
  loop's paste tests overwrote the sandbox's bash history file on 2026-11-10. Unset
  `HISTFILE` in the test helper, or say so in the build-loop prompt (gate code if the latter).
- **One more read when a review loop's last round changed gate code.** Signal: Q-271's
  release paste changed shape in each of three rounds, and the third went to the owner
  unread. A choice among remedies: flag for `divergent-design`.
- **Size a brief against what its review costs.** Signal: three small units on 2026-11-10
  each spent 1.3M to 2.0M subagent tokens on review. Feeds Q-270.
- **A brief quotes a hard constraint whole.** Signal: Q-272; the fix brief quoted H2 in
  part and the merged fallback runs where H2 refuses.
- **The batch-routing reminder fires on a subagent's hand-back.** Signal: four hand-back
  reports on 2026-11-10 each got the "multiple independent tasks" reminder.
- **`test/rubric-selection.bats` looks load-sensitive.** Signal: "emits nothing when two
  candidates tie" failed once under a loaded health check and passed alone and in a rerun.
- **Say what a fallback wakeup does, and keep corrected trigger evidence.** Signal: the
  cycle-overhead doc (c70bb17a): wakeups that ran no iteration, and a verdict correction
  lost in later "as at" lines. Both wait on Q-270.
- **Retarget the deferred review re-evaluation at the model now in use.** Signal: the
  cycle's `Model:` line changed from `claude-opus-5-5` to `claude-fable-5-2` on 2026-11-10,
  and Next 2 and watch Q-067 still describe runs under the old model. Still ask before running.
- **Give the skill a portable way to pass a list of names to a check.** Signal: iteration
  2026-11-10-1902 ran in zsh, which has no `mapfile`, and the session's safety check refused
  zsh's own array form; `xargs CHECK < FILE` worked. One clause in the skill; gate code.
- **Move finished history out of Now.** Signal: the digest counted 9 Now items on
  2026-11-10 and one was ready to brief; the owner-only questions item and the 2026-10-29
  feedback item are merged but for one point each.

- **Dropped 2026-10-30: Q-168's remote-name parsing branch** (`fix/q096b-exit-scan-remote-names`,
  75d08a94). Reason: Q-238 [1]. Every route it closes needs launch-time state, outside Q-172
  [2]'s boundary; the guide lists them as known routes. The branch stays unmerged as reference.

- **Cut merge and release friction (owner brainstorm 2026-10-29, area A).** Signal: 19 of 19
  merge entries approved; merged gate fixes wait on a host release; five terminal pastes open.
  Ten ideas in `docs/working/brainstorm-2026-10-29-friction-and-engagement.md`. A1/A2/A3/A10
  (how gate merges and releases are bundled) go to `divergent-design` first; A4, A6, A7, A8 are
  independent of that choice.
  2026-11-19: asked in Q-312 (build now, or wait for the trial's end).
- **Keep the owner from habituating to asks (owner brainstorm 2026-10-29, area B).** Signal:
  always-[1] merge entries and month-old open entries train skimming. Eight ideas in the same
  doc; the security-channel form (B1) goes to `divergent-design`; B2's metric is the check that
  area A actually lowers owner load.
  2026-11-19: asked in Q-312 (build now, or wait for the trial's end).

- **Name the 2026-10-30 cutoff before it bites.** Signal: `questions.sh`'s
  `LEGACY_BEFORE='2026-10-30'` refuses `agent`/`trigger`/`deferred` entries opened from
  that date, but until unit 3 merges and is released the dev-cycle skill still files
  `agent` entries (step 3, step 10's refusals). File such items to the roadmap meanwhile;
  `questions.sh check` would otherwise fail a cycle's land.

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
  Fired again 2026-10-30: `skills/dev-cycle/SKILL.md` changed by decision 040 unit 3
  (01022de2, Q-235 [1]).
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
  reads best after unit 3 lands. Drift finding again 2026-10-28 (step 4, 68287ee2): the
  fix-drift loop's Path A record pruned option D on S8/S1 (soft) beside a trust-boundary
  reason, and E on S2 beside the brief's own rule; the pick (C) stands. Same class as
  43762305: the audit should check that loops rank with S lines rather than prune.
  Fired again 2026-11-01: `skills/dev-cycle/SKILL.md` and the gate scripts changed by
  restriction-audit unit 1 (63ba32e9, Q-245 [1]; 23 SKILL.md lines), plus small pr-prep,
  RPI and onboarding edits. Best read after units 2-7 land, since they rewrite the same
  passages. No drift finding: unit 1's Path A record prunes on H1/H2 and uses S1/S3/S6 to
  rank among options that meet them.
  Fired again 2026-11-02: units 2 and 3 merged (242081af, 78dad60b; Q-248, Q-249), changing
  `skills/dev-cycle/SKILL.md`, code-review, security-reviewer, constraints-builder, RPI, the
  pr-prep and review-fix-loop workflows. Still best read after units 4-7 land.
  Fired again 2026-11-02 (iteration 1803): unit 4 merged (3019016a, Q-250 [1]), changing
  `skills/dev-cycle/SKILL.md`, draft-review and a constraints-builder reference. No drift
  finding: its Path A record prunes on H2 and on the brief's own motive. Still best read
  after units 5-7 land.
  Fired again 2026-10-29 (iteration 2026-10-30-0035): `skills/dev-cycle/SKILL.md` gained
  step 1b (6f364ba6, convention migrations), and a third drift finding (step 4, 6ee39f24):
  the watching-file loop's Path A record marks options 4 and 6 as failing on soft lines
  only (S10, S8; S3, S11) and calls its pick "the only candidate with no hard or brief
  failure", which 4 and 6 also were. The pick (2) stands. Same class: revise with the
  `constraints-builder` skill's amend mode, or have the divergent-design table keep hard
  fails and soft costs in separate columns.
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
  entries have landed by then. Fired (Q-223); you asked for a closer look first, now In
  flight as the failure-pattern use review; the review is done and its options are Q-226.
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
- **Reader-test high-stakes owner entries before filing** (brainstorm 2026-11-18). Signal: Q-278's
  misread (`docs/working/reader-testing/q278-2026-11-18/findings.md`, C1): both simulated readers
  caught the script's name and the owner did not. Light tier, against `docs/audiences/owner.md`, only
  for an entry that reopens a hard constraint or follows a misread; waits on the Q-278 rewrite's own
  test, which tries it once.
- **Flag an entry whose subject is named once, then replaced by a near-synonym** (brainstorm
  2026-11-18). Signal: the owner profile's decider note on Q-278.
- **Hold the reader-testing skills until a second real session** (brainstorm 2026-11-18). Signal:
  ded17c89's lessons each rest on one contaminated session (its Confidence: medium note). Do nothing
  until a second session reports.
- **Reader-test the weekly digest once against the owner profile** (brainstorm 2026-11-18). Signal:
  trials T11/T12 live in the weekly digest; Q-286 asks about them after the 2026-11-20 edition.

## Done

Items finished since the last cycle, with the merge.

- **Build loops wait inside their turn; their subagents return reports as text.** Done acbff6c6
  (approved merge, Q-314 [1]), brief `docs/working/briefs/closed/2026-11-19-loop-wait-rule.md`,
  research `docs/working/research-2026-11-19-loop-wait-rule.md`. Gate code: live at the next
  release (Q-317). Success measure: early hand-backs over the next 20 dispatches; 3 or more
  means revert.

- **Code-review: the lever #3 cache claims corrected.** Done d383a484 (approved merge, Q-315 [1]),
  brief `docs/working/briefs/closed/2026-11-19-code-review-lever3-correction.md`, research
  `docs/working/research-2026-11-19-code-review-lever3-correction.md`; decision 032 amended. The
  same claims elsewhere are the Now item "code-review lever #3 follow-ons in other files", now
  unblocked.

- **Generated-file conflicts: researched.** Done 7c137d5d (self-merge), brief
  `docs/working/briefs/closed/2026-11-19-generated-file-conflicts.md`, research
  `docs/working/research-2026-11-19-generated-file-conflicts.md`: never seen here; widened to an
  automatic send-back for any gate-refused ready branch, filed in Now (held on Q-312).

- **cc-isolated's manual worktree fallback as the default: closed.** The herald triage (8ffddfaf)
  found `workflows/parallel-worktrees.md` already gives the by-hand fallback herald F-009 used, and
  the refusal is Claude Code's worktree isolation, not this repo's.

- **Report-file lines: listed, mostly closed.** Done a8a0a496 (self-merge), brief
  `docs/working/briefs/closed/2026-11-19-subagent-report-files-listing.md`, research
  `docs/working/research-2026-11-19-subagent-report-files-listing.md`: 13 of 13 refused writes
  were a subagent's scratch `report.md`; 95 of 95 writes to `docs/reviews/` were accepted, so the
  skills' save lines stay. The one fix (the build-loop prompt's scratch-directory line) rides in
  `docs/working/briefs/2026-11-19-loop-wait-rule.md`. Revisit if a refusal is recorded on a
  `docs/reviews/` path or a name other than `report.md`. The evidence came from this machine's
  Claude Code transcripts, which the loop read with `rg`.

- **Where loops wait, and why they hand back early: researched.** Done d6c987f3 (self-merge), brief
  `docs/working/briefs/closed/2026-11-19-loops-wait-foreground.md`, research
  `docs/working/research-2026-11-19-loops-wait-foreground.md`: 15 wait points; one prompt rule
  recommended, now In flight as its own review brief.

- **The live-verify hook and merges of main: measured, dropped.** Done 74b9181f (self-merge),
  brief `docs/working/briefs/closed/2026-11-19-live-verify-merge-head-count.md`, research
  `docs/working/research-2026-11-19-live-verify-merge-head-count.md`: of 108 merges of main into
  a branch, 4 were the case, all interactive sessions with an honest `Live-verified: no` the hook
  accepts; no stop on record. The Idea is dropped; watch Q-313 reopens it if a loop stops on the
  hook during a merge of main.

- **Herald friction list triaged.** Done 8ffddfaf (self-merge), brief
  `docs/working/briefs/closed/2026-11-19-herald-friction-triage.md`, research
  `docs/working/research-2026-11-19-herald-friction-triage.md`: F-001, F-002, F-003, F-007 and
  F-012 already fixed and live; F-004, F-005, F-006, F-009 and F-011 out of scope or herald's own
  setup; F-008 and the rest of F-010 filed in Now.

- **Release soon after Q-235.** Done 2026-11-19: the release ran; the image is built from 0feaf080, which carries unit 3 and everything since (image check, iteration 2316).

- **Worktrees and caches out of the protected config directory** (F-019). Done b3e25cf1
  (approved merge, Q-311 [1]), brief `docs/working/briefs/closed/2026-11-19-worktrees-outside-dot-claude.md`,
  research `docs/working/research-2026-11-19-worktrees-outside-dot-claude.md`: loops' worktrees and
  the cycle's three checkouts go under a gitignored `.worktrees/` (`build-loop.sh --worktree-base`);
  old worktrees are still collected. Live with the next release (Q-303). Residual risk
  "worktree-hooks-bash" accepted; `scripts/self-improvement.sh`'s own worktrees not moved.
- **Agent: A8 follow-ups: the cache probe and closing rubric row A8** (filed 2026-11-19). Done
  9e89a31e (approved merge, Q-310 [1]), brief `docs/working/briefs/closed/2026-11-19-a8-cache-probe.md`,
  record `runs/review-arms/a8-2026-11-19/cache-probe.md`: two agents with a byte-identical shared
  block 28.5 s apart both read only the 18,900-token system prefix from the cache; Claude Code's
  breakpoints sit on the system blocks and the request's last block, and an agent's prompt is one
  block, so no prompt order makes the shared block cacheable across agents. Rubric row A8: Split.
- **Agent: an Idea that carries owner-reported friction never leaves Ideas** (filed 2026-11-19).
  Done 7661a2cf (approved merge, Q-309 [1]), brief `docs/working/briefs/closed/2026-11-19-ideas-promotion.md`:
  the digest lists each Idea naming a feedback entry or an owner report, and step 6 moves
  each unheld one to Now (one question per iteration for those needing a call). Live with
  the next release (Q-303); about 12 of today's Ideas move then.
- **A8 post-restructure token measurement** (Q-304 [1]). Done 358c2332 (approved merge, Q-306 [1]),
  brief `docs/working/briefs/closed/2026-11-19-a8-token-measurement.md`, results
  `runs/review-arms/a8-2026-11-19/results.md`: one terminal pass on csp, 852,285 tokens over 9
  agents; no agent got the shared review block from the prompt cache, so the skill's "free"
  claim (rubric row A8) fails on its benefit; net cost and recall effect unmeasured.
- **parallel-worktrees: a subagent returns its report as text** (F-011). Done f8453f26
  (approved merge, Q-307 [1]), brief `docs/working/briefs/closed/2026-11-19-subagent-report-as-text.md`.
- **Agent: dev-cycle section 5 follow-ups (R5, A11)** (filed 2026-11-18). Done 24af50da
  (approved merge, Q-305 [1]), brief `docs/working/briefs/closed/2026-11-18-section5-followups.md`,
  research `docs/working/research-2026-11-18-section5-followups.md`: a `watching.md` with no
  `questions.md` reads as not checked; titles cut without splitting a character; test 97's
  glob half and the first-heading test now fail on their mutants; FP-184 added. Live with
  the next release (Q-303).
- **Agent: flaky board test, the fanout case** (filed 2026-11-18). Done 5a4d2fda (self-merge),
  brief `docs/working/briefs/closed/2026-11-18-board-fanout-flaky.md`, research
  `docs/working/research-2026-11-18-board-fanout-flaky.md`: cause confirmed (an existing
  `objects/ab` directory made `ln` link inside it); the case now moves the directory out and
  links it back, and every case checks its link landed. 20 of 20 runs passed.
- **Agent: check cc-push's git version list against git's release notes** (filed and done
  2026-11-18, branch `docs/roadmap-cleanup-2026-11-18`). The list in
  `devcontainer-config/cc-push.sh` (2.39.4, 2.40.2, 2.41.1, 2.42.2, 2.43.4, 2.44.1, 2.45.1,
  or 2.46 and later) matches the May 14, 2024 security release (CVE-2024-32002 and four
  others): GitHub's blog, the Red Hat tracker and the kernel.org release notes agree, read
  through web search only (no fetch from the sandbox: unverified until a host read).
  `git_version_ok` applies that list, and `test/cc-push.bats`'s version test covers it. No
  change.
- **Questions doc becomes owner-only** (Q-221 [14′], decision 040; moved from Now
  2026-11-18). All three units merged (236f21ee, 6ee39f24, 01022de2), the release ran
  (Q-227) and the one-time `questions.sh migrate` ran (Q-234). The two follow-ups it named
  are done or not pursued: entry glossing is the "Gloss every reference" rule; a
  `questions.sh record <answers-file>` was never briefed (it is not in the idea log).
- **Owner feedback 2026-10-29, points 1, 2 and 4** (moved from Now 2026-11-18): in-session
  answers approve merge entries (014e5219, Q-230 [1]); convention changes ship migrations
  (6f364ba6, Q-233 [1]); the harness-feedback file, v1 (a8e941a5, Q-232 [1]). Point 3 stays
  in Now as the Behemoth Arsenal audit (Q-302).
- **Rewrite Q-278 (the bwrap run-or-refuse question)** (owner, 2026-11-18). Done a61f9a17 (self-merge),
  brief `docs/working/briefs/closed/2026-11-18-rewrite-q278.md`, research
  `docs/working/research-2026-11-18-rewrite-q278.md`: no question is due (neither tool works in any
  session, so every answer behaves the same). Filed as fyi Q-300 and watch Q-301; the owner answered
  `Q-300: seen, Q-278: withdrawn` (2026-11-18, in session), so both are archived and Q-301 holds the question. Optional, not filed: a decision-log row superseding row 87's
  "provisional exception" wording (`docs/decisions/` is the owner's; the research doc drafts it).
- Agent: review-gap audit fixes (Now item filed 2026-11-13, step 7;
  `docs/working/research-2026-11-13-review-gap-audit.md`): both units merged, the written
  rules (21097afa, Q-293 [1]) and the merge-time rubric check (1b50402c, Q-298 [1]); the
  check runs from the next release (Q-297). Closed by iteration chore/dev-cycle-2026-11-17-2049.
- Merge-time rubric check (`docs/working/briefs/closed/2026-11-14-merge-rubric-gate.md`):
  `build-loop.sh --merge` and `--check` print `rubric` lines for each red or amber row of the
  branch's code-review rubric they cannot count as closed; report-only, no verdict changes.
  Merged 1b50402c, approved (Q-298 [1]); gate code, live at the next release (Q-297).
- A build loop may merge the default branch into its own branch (`docs/working/briefs/closed/2026-11-16-loop-may-merge-default-in.md`):
  the dispatch prompt's "never … merge" now forbids only merging into another branch
  (philosophy-research F-009). Merged c1c7a4f3, approved (Q-296 [1]); live at the next release.
- Review rules from the two review-gap audits (`docs/working/briefs/closed/2026-11-14-review-rules-close-gaps.md`):
  no fast-forward to main, superseded loops carry rows, decisions at the cap tracked, fixes
  update their rows, rubric status words. Merged 21097afa, approved (Q-293 [1]).
- Review-gap audit, first run on this repo (Q-285 [2];
  `docs/working/briefs/closed/2026-11-13-review-gap-audit.md`). Merged 84f8532e, self-merge.
- `cc-verify` fixes: `--clean` on a run directory with no `record`, a relative REPO, and
  `source_lines_ok` on an unterminated last line (Now items filed 2026-11-05 and 2026-11-11;
  `docs/working/briefs/closed/2026-11-13-cc-verify-clean-and-relative-repo.md`). Merged
  5740cbfd, approved (Q-291 [1]). Host-verified 2026-11-17 (Q-292: both live checks passed).
- The cycle stops leaving ready work unbriefed (Now item, filed 2026-11-13;
  `docs/working/briefs/closed/2026-11-13-dev-cycle-unblock-ready-work.md`). Merged f1238bdb,
  approved (Q-289 [1]); gate code, so it runs from the next image release (Q-290).
- Small records review (`docs/working/briefs/closed/2026-11-13-small-records-review.md`):
  D12's log row after the light pass, the `Harness feedback` warning (the section added to
  `AGENTS.md` and `GEMINI.md`), decision 018's cite and the `exec "$@"` failure pattern.
  Merged 00e2e663, approved (Q-287 [1]). It closes the Now items for D12 and the warning.
- Scoped deep audit, constraint drift (filed 2026-11-05, step 4b): the small audit merged
  b3d3e8f4 and recommended no change to `docs/constraints.md`; the owner answered its four
  calls [1], keep as is (Q-281 to Q-284, 2026-11-13, merged 4306aa88). a1121ac5's Path A
  record, flagged 2026-11-13 (soft constraints alone pruned [1], [4] and [5]), joins the next
  audit's sample. Moved out of Now 2026-11-13 (branch chore/dev-cycle-2026-11-13-2237).
- Walkthrough first-problem measure (Next item 2's step 1;
  `docs/working/briefs/closed/2026-11-13-walkthrough-first-problem-measure.md`). Merged
  a91d42af, self-merge: too few entries to decide.
- Q-125, the cc-isolated Bash sandbox (filed 2026-11-01): merged 3cd6d9bb (Q-267 [1]), live
  check failed three lines, rolled back 7caea26d (Q-277 [3]); the owner then chose no
  sandbox (decision-log row 88). Its two gap items (the credential after a token refresh,
  nested worktree paths writable) closed with it. Moved out of Now 2026-11-13.
- Cross-project board v1 (owner request, 2026-11-12;
  `docs/working/briefs/closed/2026-11-12-host-board-answer-route.md` and units 1-3 below):
  built, and the first host run is done (Q-280, answered a5fe5de7: exit 0 on the seeded
  registry, exit 1 once a repo with no questions doc was added, which is by design).
  Moved out of Now 2026-11-13; the Kanban-like view stays an idea until the board is used.
- The release-outside-entry item (log row 86) moved out of Now 2026-11-13 (its merge is below).
- A release installed from a commit its entry did not describe (log row 86's trigger;
  `docs/working/briefs/closed/2026-11-12-release-outside-entry.md`). Merged a1121ac5,
  self-merge: no change.
- Cross-project board v1, unit 3: the answer commit when main is checked out (owner
  request; `docs/working/briefs/closed/2026-11-12-host-board-answer-in-place.md`). Merged
  94ace1f2, self-merge.
- Cross-project board v1, unit 2: the answer commit when main is not checked out (owner
  request; `docs/working/briefs/closed/2026-11-12-host-board-answer-commit.md`). Merged
  cb32b381, self-merge.
- What the Bash sandbox needs before it comes back (Q-277 [3];
  `docs/working/briefs/closed/2026-11-12-sandbox-return-research.md`). Merged d6b9206e,
  self-merge.
- Cross-project board v1, unit 1: the listing (owner request;
  `docs/working/briefs/closed/2026-11-12-host-board-listing.md`). Merged 763aa482,
  self-merge: `scripts/board.sh`, `test/scripts/board.bats`, `guides/cross-project-board.md`.
- Cross-project board v1: the design, and how an answer gets back to its repo (owner
  request; `docs/working/briefs/closed/2026-11-12-host-board-answer-route.md`). Merged
  1ca6d02b, self-merge.
- A light pass between full cycles (Q-270 [2];
  `docs/working/briefs/closed/2026-11-11-light-pass.md`). Merged a77bbc97, approved in Q-279
  [1]. Gate code: it runs from the release that carries it.
- Token cost of a cycle iteration (Q-270 [4];
  `docs/working/briefs/closed/2026-11-11-cycle-token-cost.md`). Merged 23c0e0ae, self-merge
  (docs only): `docs/working/research-2026-11-11-cycle-token-cost.md`. Orchestrator median
  0.51M weighted tokens (3.8M raw) per iteration; build loops are 75% of all cycle tokens;
  a light pass saves at most about 2%. The numbers neither argue against Q-270 [2] nor
  support it on tokens; no owner entry.
- The small constraint-drift audit (Q-269 [1];
  `docs/working/briefs/closed/2026-11-11-constraint-drift-audit.md`). Merged b3d3e8f4,
  self-merge (docs only): `docs/working/research-2026-11-11-constraint-drift-audit.md`.
  Recommends no change to `docs/constraints.md`; its four calls (A to D) are quoted in the
  cycle record of 2026-11-11, iteration 2026-11-12-0024.
- Data for the run-or-refuse question's return (watch Q-276;
  `docs/working/briefs/closed/2026-11-11-confine-tests-fallback-data.md`). Merged 6d4c1af6,
  self-merge (docs only): `docs/working/research-2026-11-11-confine-tests-fallback-data.md`.
  The question is back with the owner as Q-278.
- How many owner questions the repo's docs already answered, step 1 of the self-answering
  plan (`docs/working/briefs/closed/2026-11-11-self-answer-measure.md`). Merged fd325a74,
  self-merge (docs only). Its question for the owner is Q-274.

- The cc-isolated Bash sandbox (Q-125), brought up to main
  (`docs/working/briefs/closed/2026-11-07-q125-sandbox-on-main.md`). Merged 3cd6d9bb
  (Q-267 [1], answered in session 2026-11-11). Not verified live; not on the host until the
  release (Q-273).
- Three dev-cycle skill fixes: the identity check accepts an environment identity, the
  release paste runs from main's tip, the record says why a free slot stays free
  (`docs/working/briefs/closed/2026-11-10-dev-cycle-skill-held-fixes.md`). Merged 1f14e270
  (Q-271 [1]). Gate code: live from the next image release; the new paste from the one after.
- One canon-proposal pass: `scripts/canon-instance.py`, its tests, and two new canon
  instances (`docs/working/briefs/closed/2026-11-07-canon-instances-pass.md`). Merged
  1d9d01b4 (Q-268 [1]; the script stays in this repo).

- Two defects in `scripts/confine-tests.sh` fixed: a command name starting with a dash now
  runs as named, and a fallback to `unshare` prints a warning first
  (`docs/working/briefs/closed/2026-11-10-confine-tests-dash-and-fallback.md`). Merged
  b0ebed19, self-merge. Its question (run or refuse on a fallback) is Q-272.

- A first bats test for `scripts/confine-tests.sh`, 17 tests behind PATH stand-ins
  (`docs/working/briefs/closed/2026-11-10-confine-tests-bats.md`). Merged 9d6d6101,
  self-merge. Nothing ran confined (no primitive here); its two defects are In flight.

- What the dev cycle costs per iteration, for the light-pass decision
  (`docs/working/briefs/closed/2026-11-10-cycle-overhead-numbers.md`). Merged c70bb17a,
  self-merge (docs only). Its question for the owner is Q-270.

- Agent: after the Q-261 release (filed 2026-11-06). Done in-cycle on
  `chore/dev-cycle-2026-11-10-1902`: the image now holds main's gate code (both at
  536b7082), so Q-261 (the release entry) closed as met; the cleanup step freed 39 finished
  loops' worktrees and deleted 44 merged branches, which shows 85080263's worktree freeing
  works live. The held idea-log items became a brief (In flight).

- What `scripts/confine-tests.sh` needs and where it can run
  (`docs/working/briefs/closed/2026-11-07-confine-tests-situation.md`). Merged be12889c,
  self-merge (docs only). Follow-ups are Now agent work and Ideas.
- Q-125's `cc-verify --check` file for the sandbox live run
  (`docs/working/briefs/closed/2026-11-03-q125-verify-check.md`). Merged 546788f2 (Q-265 [1]).
- The first trial set's practices (T1-T7) written into the dev cycle
  (`docs/working/briefs/closed/2026-11-06-codify-trial-practices.md`). Merged 3dbf43cb
  (Q-266 [1]; the marker's `docs/dev-cycle.md` question takes its pick, [1] leave it). Gate
  code: live from the next image release.
- Owner-facing text explains every internal reference, by a written rule (`docs/working/briefs/closed/2026-11-06-owner-entry-gloss-rule.md`). Merged 771c84e8 (Q-263 [1]). Its falsifier is watch Q-264.
- Merge approval stays as it is: ideas A1, A3 and A10 weighed, status quo picked (`docs/working/briefs/closed/2026-11-06-merge-friction-design.md`). Merged e9f3e176, self-merge. Revisit triggers are watch Q-262.
- Free a finished loop's worktree and branch (`docs/working/briefs/closed/2026-11-06-free-merged-loop-worktrees.md`). Merged 85080263 (Q-260 [1]).
- Restriction audit unit 7, the D6 block as one root-owned image script (`docs/working/briefs/closed/2026-11-05-d6-block-into-image.md`). Merged aeab6745 (Q-259 [1]). All seven units of the audit are now merged (`docs/working/research-2026-11-01-restriction-audit.md`).
- **Agent: Q-241's settings merge check** (filed 2026-11-06, step 3): the check is step (d) of Q-167, since the release closed Q-252 first. `chore/dev-cycle-2026-11-07-0115`.
- **Restriction audit unit 6: the import walk reads plain `@path` imports only.** Merged
  68a05afe (Q-253 [1]). It takes effect from the next image release. Brief:
  `docs/working/briefs/closed/2026-11-03-import-walk-plain.md`.
- **Q-097: the exit scan's two older routes stay open, with reasons in the guide.** Merged
  3424799f (Q-257 [1]). Brief: `docs/working/briefs/closed/2026-11-05-exit-scan-older-routes.md`.
- **Q-147: the Q-089 source-set test landed, narrowed.** Merged 3a663f88 (Q-258 [1]). Brief:
  `docs/working/briefs/closed/2026-11-05-q089-source-guard-narrow.md`.
- **Q-079's design: the canon-instance proposal filter.** Self-merged 605d4c18. Design in
  `docs/working/research-2026-11-05-canon-proposal-filter.md`; the filter choice is Q-256.
  Brief: `docs/working/briefs/closed/2026-11-05-canon-proposal-filter.md`.
- **Restriction audit unit 5: the cycle runs migrations itself, and closes a cleared
  image-lag entry** (owner, 2026-11-01; the Now item "the cycle closes a cleared image-lag
  entry itself" was folded into it). Merged 89ed0db4 (Q-251 [1]; decision-log row 82). It
  takes effect from the next image release. Brief:
  `docs/working/briefs/closed/2026-11-02-cycle-runs-migrations.md`.
- **Health-check gate 12 counts days by date** (filed 2026-11-02, step 1: the DST-day
  flake). Self-merged 686eaf57 (build-loop self-merge). Brief:
  `docs/working/briefs/closed/2026-11-02-health-check-dst-day-count.md`.
- **Restriction audit unit 4: brief, marker and path grammar, the loop prompt** (owner,
  2026-11-01). Merged 3019016a (Q-250 [1]; decision-log row 81). Brief:
  `docs/working/briefs/closed/2026-11-02-relax-grammar-and-loop-prompt.md`.
- **Restriction audit unit 2: narrow the stops in the referenced workflows and skills**
  (owner, 2026-11-01). Merged 242081af (Q-248 [1], after a re-dispatch on Q-246 to merge
  main in; its decision-log row is 80). Brief:
  `docs/working/briefs/closed/2026-11-01-relax-referenced-prose-stops.md`
- **Restriction audit unit 3: drop the dev-cycle skill's out-of-scope rituals** (owner,
  2026-11-01). Merged 78dad60b (Q-249 [1], after a re-dispatch on Q-247); gate code, takes
  effect at the next release. Brief:
  `docs/working/briefs/closed/2026-11-01-relax-dev-cycle-skill-prose.md`
- **Restriction audit unit 1: the gate's git-state checks narrowed to in-scope threats**
  (owner, 2026-11-01). Merged 63ba32e9 (Q-245 [1]); takes effect at the next release. Brief:
  `docs/working/briefs/closed/2026-11-01-relax-gate-git-state.md`
- Q-234: `questions.sh migrate` run (owner, 2026-11-01): watches now in `docs/working/watching.md`; Q-173 (exit-scan split groups) closed, settled by Q-238 [1]. Branch `chore/q234-migrate`.
- **Failure patterns move out of `docs/thoughts/`; `docs/thoughts/` leaves the self-merge
  floor** (owner, 2026-10-31). The library is now `docs/failure-patterns.md`, still on the
  floor; other repos get the `failure-patterns-out-of-thoughts` migration after the next
  release (Q-227). Merged 18e9cb79 (Q-242 [1]). Brief:
  `docs/working/briefs/closed/2026-10-31-failure-patterns-out-of-thoughts.md`
- Bug: step 1's health check read WT while the orchestrator edited it: it now runs in a
  detached clean checkout of WT's HEAD (Q-239 [1]): merged 4c731ab7. Brief:
  `docs/working/briefs/closed/2026-10-30-health-check-clean-checkout.md`
- Bug: the brainstorm triggers counted their own output and re-fired on an unchanged Now
  (Q-240 [1]): merged c24c0916. Brief:
  `docs/working/briefs/closed/2026-10-30-brainstorm-trigger-count.md`
- Host settings.json merge (Q-106 [2]): `install.sh`'s host target runs the container's
  merge program inside its review; also closes Q-108. Merged 086f08c8 (Q-241 [1]).
- Questions doc owner-only, unit 3: the digest reads `watching.md`, agent work goes to the
  roadmap, global instructions updated (decision 040; Q-235 [1]): merged 01022de2. Brief:
  `docs/working/briefs/closed/2026-10-29-questions-owner-only-unit3.md`
- Bug: `migrations.sh check .` refused with a relative root (Q-237 [1]): merged ea1ab6fe.
  Brief: `docs/working/briefs/closed/2026-10-29-migrations-relative-root.md`
- Bug: the skill-frontmatter health check flaked (`echo | grep -q` under pipefail; Q-236 [1]):
  merged b0e907d6. Brief: `docs/working/briefs/closed/2026-10-29-skill-frontmatter-flake.md`
- Bug: the vanishing-file ancestor-listing test failed under load (find listed a churning
  `/tmp`; the fixture now keeps off shared `/tmp` ancestors): merged 431397bf (self-merge).
  Brief: `docs/working/briefs/closed/2026-10-29-flaky-vanish-test.md`
- Convention changes ship migrations the dev cycle runs first (owner feedback point 2,
  Q-231 [1] then Q-233 [1]): merged 6f364ba6. Brief:
  `docs/working/briefs/closed/2026-10-29-convention-migrations-first.md`
- Questions doc owner-only, unit 2 (`watching.md`, `questions.sh migrate`; Q-229 [1]): merged
  6ee39f24. Brief: `docs/working/briefs/closed/2026-10-29-questions-watching-file.md`
- Session answers approve merge entries (owner feedback point 1, Q-230 [1]): merged 014e5219.
  Brief: `docs/working/briefs/closed/2026-10-29-session-answers-for-merge-entries.md`
- Harness feedback file v1 (owner feedback point 4, Q-232 [1]): merged a8e941a5. Brief:
  `docs/working/briefs/closed/2026-10-29-harness-feedback-file.md`
- Failure-pattern steps where build loops run, checked at the gate (Q-226 [5], Q-228 [1]):
  merged f91d7d09. Brief: `docs/working/briefs/closed/2026-10-29-failure-pattern-loop-wiring.md`
- Health check: the three shellcheck findings in `test/questions-doc.bats` from Q-224's
  merge (two of them inert `!` assertions, now `run !` with a status check): done at
  a36df962 (build-loop self-merge). Brief:
  `docs/working/briefs/closed/2026-10-29-questions-doc-bats-lint.md`
- Exit scan: Q-173 group 1 remainder (A14, R3's remote half, A16): done at fd62dd3f
  (Q-225 [1], approved merge). Brief:
  `docs/working/briefs/closed/2026-10-28-exit-scan-group1-remainder.md`
- Questions doc owner-only, unit 1 (owner routes in `questions.sh`): done at 236f21ee
  (Q-224 [1], approved merge; gate code, reaches the gate at the next image release).
  Brief: `docs/working/briefs/closed/2026-10-28-questions-owner-routes.md`
- How the failure-pattern library is used (Q-223): research done at d32c7eb2 (build-loop
  self-merge); its options are Q-226. Brief:
  `docs/working/briefs/closed/2026-10-28-failure-pattern-use-review.md`
- The interview profile's README matches its scripts (settings values, the `cci` drift
  prompt, what preflight checks): done at 9b8a0b34 (build-loop self-merge). Brief:
  `docs/working/briefs/closed/2026-10-28-interview-readme-drift.md`
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
