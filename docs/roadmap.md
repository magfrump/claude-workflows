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

- **Agent: the build-loop handoff plan's D12 after the light pass** (filed 2026-11-11, step 7).
  Motive: if Q-279 merges the light pass, decision-log row 72 and D12 in
  `docs/working/plan-build-loop-handoff.md` still say every iteration is a full cycle
  (the light-pass loop's report). First step: once Q-279 is answered [1], one review unit
  adds a decision-log row recording Q-270 [2] as D12's new answer and corrects the plan.
  Q-279 was answered [1] and the light pass merged at a77bbc97, so this is ready. It edits
  `docs/decisions/log.md`, a record the self-merge floor refuses, so it is a review unit.
  Not briefed alone (a full loop and a merge entry for two lines); it rides the next review
  unit that touches the decision log.

- **Models answer their own questions from the repo's docs (owner request, 2026-11-11).**
  Motive: the owner asked for a plan for how models can answer their own questions based on
  existing docs in a repo. The questions doc spends the owner's attention, the binding
  budget here, and on 2026-11-10 the cycle filed four judgment entries in one day. At least
  one was answerable from a doc on main: Q-272 asks whether a degraded tool should refuse,
  and hard constraint H2 in `docs/constraints.md` already says it does. The plan, in order:
  1. **Measure before designing.** For the archived and open owner entries, record whether a
     doc that existed when the entry was filed answered it fully, in part or not at all:
     the constraints file, a decision record or log row, an earlier answer to the same
     question, the owner's feedback and answer notes, the global instructions. Output: the
     share, the examples, and which kinds of doc held the answers. If the share is small,
     stop there and say so; the status quo is a valid result.
  2. **Design where the lookup lives**, as a divergent-design pass seeded with
     `docs/constraints.md`. Candidates to start from: a "look before you ask" step in the
     build-loop prompt and in research-plan-implement's research phase; a
     `questions.sh` search over the archive and the decision log for earlier answers; an
     index of standing answers the cycle keeps; a `Looked in:` line every owner entry must
     carry, so an ask that searched nothing is visible; moving answers that recur into
     `docs/constraints.md`, where every loop already reads them.
  3. **Guardrails.** An answer taken from a doc names the doc and quotes the line, so it can
     be checked. It is never used for what is the owner's by authority, not information: a
     merge entry, a change or exception to a hard constraint, a release. The weekly digest
     lists each question a model answered for itself, one line each, so a wrong reading is
     caught after the fact; no new stop or entry is added.
  4. **Try it for a week as a writing trial**, with a measure that can come out negative:
     owner entries per cycle fall, and the owner does not reverse the self-answered ones.
  First step: step 1, briefed as a docs-only unit (In flight). It also covers repos other
  than this one in its design step, since the request says "a repo": the four repos that
  run these workflows each have their own docs and questions files.
  2026-11-11, step 1 done (fd325a74, `docs/working/research-2026-11-11-self-answer-measure.md`):
  of 200 answered judgment entries, at most 4 (2%) were answered in full by a doc that
  existed, 35 in part, 56 not at all, and 105 were the owner's by authority. A lookup is not
  shown to remove any entry, so the plan pauses here. How far it goes is Q-274 (interim:
  build nothing); watch Q-275 brings it back when Q-272 is answered. The doc's one positive
  step is already on the roadmap: answers that deserve to be standing rules go into
  `docs/constraints.md` at the deep audit (Q-269).
  2026-11-11, stopped here on the owner's answer (Q-274 [1]: build nothing; look again
  when Q-272 is answered). Q-272 was answered the same day, [1] "to start": the owner
  granted the exception for now, so the exceptions rule has no confirmed case and watch
  Q-275 is closed. Steps 2 to 4 are not to be briefed. The rule comes back only if the
  owner refuses the exception when Q-272 returns with data (watch Q-276). The owner's
  note on other repos is an Ideas item.

- **Agent: Q-125 · cc-isolated Bash sandbox, live run** (filed 2026-11-01, step 6, from
  Q-234's migrate). Motive: nothing sandboxes Bash in cc-isolated. Built, unmerged
  (`feat/q125-cc-isolated-sandbox`); the host install is done (Q-222, answered 2026-11-03). The
  check file merged at 546788f2 (Q-265 [1]). The conflict merge is ready at cd6d4332 (In
  flight). First step: the owner's `cc-verify` paste in merge entry Q-267, then its answer.
  2026-11-11: merged at 3cd6d9bb on the owner's answer (Q-267 [1]). No live-run output came
  with the answer, so the sandbox has still never run: its commits stay `Live-verified: no`.
  It reaches sessions at the next host install, which is the release entry Q-273; that
  entry puts the live check first. After the install: `scripts/confine-tests.sh --probe`
  in a session, and the leak list in watch Q-098.
  2026-11-11, later: the live check ran on the owner's host against main at f0a55b8a
  (`cc-verify`, tree 08bf2bc9, config 1887e71a2126a27b) and failed: VERDICT FAIL, 3 not
  pass, 0 missing. On record: C3-nested-settings-1 and C3-nested-gitfile-1 FAIL; C4, C5
  and C6 pass. The third line, from the owner later the same day: X4-cred-across-rename
  FAIL (read after a rename). With none missing, every other required line passed, by
  the verdict's count; the lines themselves are not on record. So the sandbox has now
  run, the commits stay `Live-verified: no`, and the install waits for the owner's
  answer to Q-277 (install with the two gaps written down, or hold).
  2026-11-12: Q-277 answered [3]. Under the sandbox a `git worktree add` fails
  (`.git/worktrees` read-only), so main rolled the sandbox back (7caea26d; docs kept), and
  the owner installed the image from 80b7dabe without it. It comes back only when agents
  can create worktrees under it, beside the two gaps below; to restore it, revert 7caea26d.
  The first step for all three is the research brief In flight
  (`docs/working/briefs/2026-11-12-sandbox-return-research.md`). This item is finished
  but for that return.

- **Agent: a sandboxed command can read the credential after a token refresh** (filed
  2026-11-11, from the Q-273 live check). Motive: `X4-cred-across-rename FAIL (read after
  a rename)`. The check file (`docs/working/q125-verify-check.sh`, its X4 block) replaced
  `~/.claude/.credentials.json` by rename every half second while one sandboxed command
  read it in a loop, and that command saw the new content. The plan's acceptance step 6
  requires the read to stay refused across `/login` or a refresh, and its residuals table
  had the case as "unknown" (`docs/working/plan-q125-cc-isolated-sandbox.md`). What
  holds: reads before any rename (X1, four ways) and the first read of the next command
  (C1-cat-credential, after the renames) passed, by the count. So the mask is put back
  for each new command and is lost inside one command when the file is renamed over; a
  command that waits in the background for a refresh fits through. Likely mechanism, not
  confirmed here: `denyRead` is a bind over the file's directory entry, and a rename
  over that entry from outside the sandbox detaches it. First step: a research and
  divergent-design unit seeded with `docs/constraints.md`. Settle first: how Claude Code
  applies `denyRead` (read its sandbox documentation and observe the mounts in a
  sandboxed command), whether a directory-level deny survives a rename inside the
  directory, and how long a sandboxed command may run (background commands included).
  Candidates to start from: deny reading a directory that holds only the credential, if
  the credential's place can be moved; keep the credential out of the container's files
  (an API key helper or a proxy outside the sandbox that adds it); a cap on how long a
  sandboxed command lives; a report to Claude Code, since the masking is its code; or an
  accepted residual beside decision log 53. Until this is fixed, watch Q-098's trigger
  (the sandbox denies reads of the credential) is not met. Enforcement files: a
  pre-mortem, a `Live-verified:` trailer, and the same `cc-verify` check re-run.
  2026-11-12: the sandbox is rolled back (7caea26d); this gap is now one of three
  requirements for its return, researched together in the brief In flight.

- **Agent: the sandbox leaves nested worktree paths writable** (filed 2026-11-11, from
  the Q-273 live check). Motive: the plan's own acceptance step
  (`docs/working/plan-q125-cc-isolated-sandbox.md`, step 6) requires sandboxed writes to
  be refused for a nested worktree's project settings file and for a worktree's `.git`
  pointer file, and its residuals table left both "Unknown" for the live run. The run
  answered: under `/workspace/.claude/worktrees/q125-probe/` a sandboxed command could
  create the `.claude` directory and append to `.git`.
  `devcontainer-config/managed-settings.json` denies those names only at `/workspace`
  itself, by literal path. First step: a research and divergent-design unit seeded with
  `docs/constraints.md`. Open facts to settle first: whether the sandbox's `denyWrite`
  takes a pattern on Linux (not checked here; read Claude Code's sandbox documentation),
  and whether a subagent whose working directory is a nested worktree loads that
  worktree's settings file. Candidates to start from: a pattern entry, if supported; a
  deny on the whole worktrees directory, which would also stop sandboxed commands doing
  ordinary work in an agent worktree; literal entries added as worktrees are made, which
  the root-owned build-time managed file cannot take today; agent worktrees somewhere
  the deny list can name; or recording it as an accepted residual beside decision log
  53, with the exit scan (`devcontainer-config/cc-exit-scan.sh` already walks worktree
  git dirs) as the check on the `.git` side. Any change is to enforcement files: a
  pre-mortem, a `Live-verified:` trailer, and the same `cc-verify` check re-run. The
  third failed line is a separate gap (the item above, the credential after a refresh),
  so the two can be designed apart and checked in one live run.
  2026-11-12: the sandbox is rolled back (7caea26d); this gap is now one of three
  requirements for its return, researched together in the brief In flight.

- **Agent: a release installed from a commit its entry did not describe** (filed
  2026-11-12, step 2). Motive: decision-log row 86's revisit trigger ("if an image's
  `commit=` names gate code other than its entry's M") fired. The image is at 80b7dabe,
  while release entry Q-273 named M = 7b8b560a; between them 30eb0229 changed
  `skills/dev-cycle/SKILL.md` (gate code; one sentence of step 7, owner-requested in
  session) and 7caea26d rolled back the sandbox (Q-277 [3]). Both were the owner's own
  asks, so nothing unreviewed shipped, but the install ran outside the entry's paste,
  which only a later cycle could have rewritten. First step: read the two commits'
  sessions' records and `devcontainer-config/install.sh`, and say whether the release
  path needs a change (for example install.sh printing the gate-code diff from the last
  release entry's M) or the case is an owner-directed install the design already allows.
  Only a proposed change becomes an owner entry.

- **Agent: scoped deep audit, constraint drift** (filed 2026-11-05, step 4b). Motive: the
  drift check on 605d4c18 found its script-home decision resting on a soft constraint (S4
  pruned the checklist option) and on a rule `docs/constraints.md` does not hold (instrument
  code lives in the SWRBench fork). Scope: Path A records since the last audit, using the
  `constraints-builder` skill's amend mode to revise the file. First step: the owner confirms
  scope and timing; it runs on its own branch, outside the cycle. It also covers
  `skills/dev-cycle/SKILL.md` as Q-259 and Q-260 changed it (step 4b, 2026-11-06). Also 85080263's
  Path A record, where S4 (soft) shared the pruning of candidate D with H1 (step 4, 2026-11-06).
  Also aeab6745's Path A record, where S8 (soft) shared the pruning of `bin/d6` with the
  enforcement-file cost, while H1 pruned `/usr/local/bin` (step 4, 2026-11-07); and
  `skills/dev-cycle/SKILL.md` as 3dbf43cb (Q-266) changed it.
  Fired again 2026-11-10 on two more triggers: the model running the cycle changed from
  `claude-opus-5-5` to `claude-fable-5-2`, and 546788f2's Path A record pruned its option A
  on S10 (soft) beside H4 (hard); the pick (B) stands. Scope and timing are now asked in
  Q-269 (run the small constraint-drift audit, the full audit, or wait).
  Fired again 2026-11-11: `skills/dev-cycle/SKILL.md` changed by 1f14e270 (Q-271: the
  identity check, the release paste, the free-slot line).
  2026-11-11, scope and timing answered (Q-269 [1], the small audit now). First step is
  now a brief for one build loop: read the seven flagged Path A records named above and
  draft changes to `docs/constraints.md` with the `constraints-builder` skill's amend
  mode. Its output is one owner entry with a promote, keep soft or drop call per flagged
  line. Nothing else is re-read; the full audit stays unasked.
  Fired again 2026-11-11 (iteration 2026-11-12-0006): the model running the cycle changed
  from `claude-fable-5-2` to `claude-opus-5-5`; within the small audit's scope it changes
  nothing. The small audit is done (b3d3e8f4, Done): it recommends no change to the
  constraints file, and its four calls are with the owner in the cycle's final message. A
  different pick the owner names becomes its own item. This item is finished but for that.

- **Agent: `source_lines_ok` misses an unterminated last line** (filed 2026-11-05, step 7).
  Motive: the Q-147 review found the shipped self-check in `devcontainer-config/cc-verify.sh`
  can miss a final line with no newline; every file ends in one today, so nothing is exposed
  now. It lives otherwise only as a Defer row in `docs/reviews/override-log.md`, merged with
  Q-258. First step: one change with `Host-tool-tested:` and a re-bless,
  which needs a host run, so it is not briefed for a loop yet.

- **Agent: `cc-verify --clean` exits 2 and prints nothing on a run directory with no
  `record`** (filed 2026-11-11, from the owner's Q-273 paste). Motive: it stopped the
  release's live check. `~/cc-verify/run-1793211495-572412.d` was left by the Q-117 trial
  script on 2026-10-28 (its teardown removes `record` last and never the directory), the
  new-run check at `devcontainer-config/cc-verify.sh:222` counts any `run-*`, and
  `--clean` dies at line 210: `sed` cannot read `$d/record`, exits 2, and `pipefail` with
  `set -e` ends the script with the message sent to `/dev/null`. A non-directory `run-*`
  dies the same way before its NOTE. Reproduced with the bats harness of
  `test/cc-verify.bats`: `mkdir "$CC_VERIFY_ROOT/run-1-1.d"`, then `--clean` gives status
  2, empty output, directory kept. Appending `|| p=""` to line 210 gives status 0,
  `cleaning <dir>`, directory removed (`teardown` with no `T8` only removes the
  directory). First step: that change and its test, in the same change as the
  `source_lines_ok` item above, since both need `Host-tool-tested:` and a re-bless. For
  the pre-mortem: a run between its `mkdir` and its `record` write (lines 225 to 228)
  has no `record`, so a `--clean` in that window would remove a live run's fresh
  directory; today the abort hides that. The owner's workaround is in Q-273's paste 1.
  Second defect, same day, same paste: a relative REPO fails. The script changes into its
  run directory (line 225) before the clone at line 232, so `cc-verify --check FILE . main`
  ends with "fatal: repository '.' does not exist" (reproduced with the harness: `cd "$R"`
  and REPO `.` gives status 1; the absolute path passes). `--check FILE` is not affected:
  it is read at line 220, before the `cd`. Fix in the same change: resolve REPO to an
  absolute path before the `cd`, or refuse a relative one by name. The header of
  `docs/working/q125-verify-check.sh` (line 7) shows the `.` form and needs the same
  correction; `guides/cc-isolated-usage.md` and `--help` do not say REPO must be a full path.

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

- **Agent: the `Harness feedback` section warning** (filed 2026-11-06, step 3, trial T7).
  Motive: every health check warns that this H2 of the global instructions is missing from
  `AGENTS.md` and `GEMINI.md`, and T7 files any warning printed every run as a bug. First step:
  add the section to both files or exempt it in the check, depending on whether other agents
  need it. Those are instruction files, so it is a review merge; not briefed, since a full
  build loop outweighs a few lines while it would add another owner entry.

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
- **Questions doc becomes owner-only (Q-221 [14′], decision 040).** Motive: the owner reported
  that agent bookkeeping crowds the one page meant for them (17 open entries, 2 theirs).
  Build in three units: (1) four owner routes (`you: judgment`, `you: terminal`, new
  `you: walkthrough`, new `you: fyi`), with `questions.sh check` refusing `agent`/`trigger`/
  `deferred` in `questions.md` and naming where each goes; (2) `docs/working/watching.md`
  (entry grammar, `## Closed` section) plus a lossless `questions.sh migrate`; (3) dev-cycle
  steps 2/3 read `watching.md` and file agent work to this roadmap, and the global
  instructions' questions section changes to match (≤ ~30 lines, repo S2). Gate code: each
  unit is a `merge-gate` entry. Unit 1 merged at 236f21ee (Q-224 [1]); unit 2 merged at 6ee39f24 (Q-229 [1]). Unit 3 merged at 01022de2 (Q-235 [1]). Next: the release (Q-227), then the owner's one-time `questions.sh migrate` run (Q-234). Follow-ups: entry clarity (gloss every internal reference) and a
  `questions.sh record <answers-file>`.

- **Cross-project board, v1: a host script for active projects and their questions**
  (owner request, 2026-11-12; proposal `docs/thoughts/proposal-2026-11-12-cross-project-board.md`).
  Motive: the owner's attention is spread over several repos, each keeping its own
  roadmap and questions files, and the only way to see which project needs them is to open
  every workspace. The owner's scope for v1: a script that keeps a list of active
  projects, fetches each one's open questions, and takes answers back to the right repo.
  It runs on the host, so it has no LLM component at all (no `claude` call, no model in
  the loop): python3 stdlib or bash, read-only except for the answer write. A board or
  Kanban-like view may grow from it later, not in v1. The proposal's host-vs-container
  table is settled by this: [1] host only.
  First step: a docs-only research and divergent-design unit, seeded with
  `docs/constraints.md`, on the one write, how an answer gets back to its repo (for
  example a `Q-NNN: answer` line in that repo's answers file under
  `docs/human-author/`, an edit of the entry in its questions file, or a commit the
  script makes on the host), and on reading questions through each repo's own
  `questions.sh open` rather than re-parsing (S3). Then a build unit with hermetic bats
  fixtures (H3). For the owner later, when the build is briefed: which repos go in the
  registry and where they live on the host (the proposal's open question 1).
  2026-11-12: the design unit is briefed
  (`docs/working/briefs/closed/2026-11-12-host-board-answer-route.md`) and done
  (1ca6d02b, self-merge; `docs/working/research-2026-11-12-host-board-answer-route.md`).
  The answer goes back as a commit the host script makes on that repo's main, which the
  cycle reads as an owner answer. The build is three units: the listing (In flight),
  the answer commit when main is not checked out, then in place when it is. The
  registry's contents are the owner's (asked in the cycle's final message), needed
  before the first host check, not the build.
  2026-11-12: unit 1, the listing, merged (763aa482, self-merge; `scripts/board.sh`,
  `guides/cross-project-board.md`). It reaches the host at the next release. Unit 2 is In
  flight.

- **Owner feedback 2026-10-29** (`docs/human-author/feedback-10-29-26.txt`), four points:
  1. An answer given in session should approve a merge entry (the gate is too strict).
     Merged at 014e5219 (Q-230 [1]); the orchestrator follows it once the next release
     installs the skill.
  2. Convention changes ship migration instructions, and the dev cycle runs them before
     continuing existing work. Merged at 6f364ba6 (Q-233 [1]).
  3. Audit a repo that committed code-review rubrics with open amber or red items: find
     which step of the review-fix loop let the merge through. First step: a read-only
     `review-gap-audit` procedure (for each committed rubric with amber or red rows, find
     the merge that carried it, whether a fix round followed, and which gate or prose rule
     should have stopped it), tried on the repo the owner names. Waits for the owner to
     name the repo (asked in session 2026-10-29).
  4. A surface for projects to file feedback about the harness. First step (v1): a
     `docs/harness-feedback.md` file any project can append to in a fixed entry shape,
     plus how this repo ingests a copied file; v2 (GitHub issues: search, comment or star,
     else open one) is an idea until v1 is used. v1 merged at a8e941a5 (Q-232 [1]).

## In flight

- **What the Bash sandbox needs before it comes back** (Q-277 [3]):
  `docs/working/briefs/2026-11-12-sandbox-return-research.md`. One docs-only research
  and divergent-design unit on the three requirements: worktree creation under the
  sandbox, nested worktree paths, the credential after a refresh. Self-merge.
- **Cross-project board v1, unit 2: the answer commit when main is not checked out**
  (owner request, 2026-11-12): `docs/working/briefs/2026-11-12-host-board-answer-commit.md`.
  `scripts/board.sh answer PROJECT Q-NNN TEXT` writes the answer as a commit on that repo's
  main; it prints the line instead when main is checked out (unit 3). Self-merge.

## Next

1. **Q-125's host live run, now that `cc-verify` is merged.** Motive: Q-125 (the
   cc-isolated Bash sandbox), and behind it Q-098 (global allowlist) and Q-161 (hermeticity
   layer 2), waited on `cc-verify` (merged at 37b24c02, Q-217 [1]). The host install has
   `cc-verify` (Q-222, answered 2026-11-03). The check file merged at 546788f2 (Q-265 [1]).
   First step: the live-run paste in merge entry Q-267 (the conflict merge is ready at
   cd6d4332). `~/cc-verify` is already in the agents'
   sandbox `denyWrite` (owner, 2026-11-03).
   2026-11-11: the branch is merged (3cd6d9bb, Q-267 [1]); the live run is now the first
   block of the release entry Q-273, run against main.
   2026-11-12: the sandbox is rolled back (7caea26d, Q-277 [3]); its return is researched
   in the brief In flight, and a new live run follows that design, not this one.
2. **A8 post-restructure token measurement.** Motive: the user deferred big compute until
   code and prompts settle; it validates code-review lever #3 (rubric row A8 in
   `docs/reviews/code-review-rubric-2026-08-07-main.md`). First step: confirm
   settlement (no open code-review SKILL changes), then re-run one canon cell. The
   user's 2026-10-20 feedback adds re-evaluating review k and the lite review under Opus
   5.5; deferred, ask before running. (2026-11-10: sessions here now run
   `claude-fable-5-2`, so a re-evaluation, when you ask for it, would be under that model.)
3. **Revisit the light pass between full cycles (C5, Q-154).** Motive: you answered C5 with a
   full cycle every iteration for now and a light pass of steps 7, 8 and 10 between full
   cycles once the costs are visible (plan D12, F53). First step: after the orchestrator's
   first day of iterations here (after Q-156's release), total each iteration's tokens and
   wall time from its records and bring the numbers to you. That first step is done
   (c70bb17a; no token counts exist to total), and the choice is now Q-270.
   2026-11-11: answered (Q-270: [2], and [4] as well). Both are Now items: "light pass
   between full cycles" and "token cost of a cycle iteration". This item is finished.
4. **Agent first-pass playtest before each `you: walkthrough`** (owner request, 2026-11-12;
   proposal `docs/thoughts/proposal-2026-11-12-agent-first-pass-playtest.md`). Motive: a
   walkthrough spends the owner's most expensive time, and its first stretch may go on
   problems an agent could have found (a launch that fails, a README step missing). The
   owner says it needs consideration, so nothing is built yet. First step: the proposal's
   step 1, measure first: classify the first reported problem of each answered
   `you: walkthrough` entry (mechanical, a finding only a person makes, or none), here and
   per project in each project's own session; under ~20% mechanical, stop and record that.
   Its three open questions (the first trial project, automatic or on request, Chromium in
   the image) wait for that number.

## Ideas

- **A sandboxed worktree line in the live check** (brainstorm 2026-11-12). Signal: the
  sandbox's live check passed every line but three, yet the sandbox broke worktree creation,
  which no line tested (7caea26d). It would add a sandboxed `git worktree add` and
  remove to `docs/working/q125-verify-check.sh`; the research brief proposes the lines.
- **cc-isolated's manual worktree fallback as the default** (brainstorm 2026-11-12).
  Signal: herald F-009 and 7caea26d both saw Agent `isolation: "worktree"` refused in the
  container. It would change `workflows/parallel-worktrees.md` to start with the
  by-hand `git worktree add` there, once the research says whether the refusal is the
  sandbox's or the container's.
- **Triage the herald friction list as one unit** (brainstorm 2026-11-12). Signal: 12
  seeds from one ingest (F-001 to F-012, `docs/working/feedback/belegarth-herald.md`),
  several about hooks and permission prompts this repo ships. It would group them by
  cause and file the few with a fix in this repo; do nothing until a slot is free.
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
- **Keep the owner from habituating to asks (owner brainstorm 2026-10-29, area B).** Signal:
  always-[1] merge entries and month-old open entries train skimming. Eight ideas in the same
  doc; the security-channel form (B1) goes to `divergent-design`; B2's metric is the check that
  area A actually lowers owner load.

- **The cycle cannot create a project's harness-feedback file.** Signal: philosophy-research
  F-002: `--check-fix` refuses every new file, so the owner made it by hand. Allow
  `harness-feedback.py init` and appends in-cycle outside claude-workflows.
- **Release soon after Q-235.** Signal: philosophy-research F-001: a repo that ran
  `questions.sh migrate` has a digest that shows "None open" for its watches until the image
  carries unit 3.

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

## Done

Items finished since the last cycle, with the merge.

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
