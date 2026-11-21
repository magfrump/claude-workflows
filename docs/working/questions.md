# Running questions

Questions raised during autonomous work that did not justify stopping.

**To answer:** write `Q-0NN: <your answer>` anywhere — a reply, a file, a commit.
The ID is the whole handle; you never have to restate the question. Answers move
the entry to `questions-archive.md`, so this file only ever holds what is still open.

**Needs** is the route — who or what actually discharges the item, from
`docs/working/triage-2026-09-17-backlog.md` §3.1:

| Route | Meaning |
|---|---|
| `you: judgment` | Needs your taste or authority. The only real attention spend. |
| `you: terminal` | Needs your machine, not your mind. Collected into one paste below. |
| `you: walkthrough` | A hands-on walkthrough or playtest only you can do. |
| `you: fyi` | A quick read to acknowledge, answered `seen`. |

Agent work is on the roadmap (`docs/roadmap.md`), and conditions the cycle is watching are in `docs/working/watching.md`.

Maintained by `scripts/questions.sh` (`check` · `index` · `archive` · `next-id` · `open`).
The index below is generated — edit entries, not the table.

## Index

<!-- index:start -->
| ID | Needs | Question | Opened |
|---|---|---|---|
| [Q-340](#q-340--threat-model-walkthrough-after-t12) | you: judgment | Should a quarterly threat-model walk-through of the risks you have accepted come back now that you said tri... | 2026-11-20 |
| [Q-341](#q-341--decision-040-ask-trigger) | you: judgment | Decision 040's "too many asks" revisit trigger has fired if "a cycle" means a day; should the cycle reopen ... | 2026-11-20 |
| [Q-342](#q-342--merge-gate-2026-11-20-codify-trial-set-2-a77146f3a174) | you: judgment | Merge the build loop's change that writes trials T9, T11 and T12 into the dev-cycle skill? | 2026-11-20 |
| [Q-343](#q-343--merge-2026-11-20-write-guard-wt-exemption-e7222f55bc6e) | you: judgment | Merge the build loop's change that keeps the write guard's `.claude/wt-*` worktree case and corrects the co... | 2026-11-20 |
| [Q-344](#q-344--merge-gate-2026-11-20-ask-counter-47210f4bf75f) | you: judgment | Merge the build loop's `questions.sh counts`, a reproducible ask counter for the weekly digest? | 2026-11-20 |
| [Q-345](#q-345--answers-file-counts-as-answer) | you: judgment | Should a committed answers file under `docs/human-author/` (like `answers-11-20-26.txt`) count as your answ... | 2026-11-20 |
| [Q-348](#q-348--merge-gate-2026-11-20-si-commit-literal-pathspecs-1925b0ea957e) | you: judgment | Merge the build loop's fix that makes the self-improvement loop's commit helper work when literal pathspecs... | 2026-11-20 |
| [Q-332](#q-332--regenerate-fact-check-reports-host) | you: terminal | Regenerate the fact-check skill's eval reports on the host, where the web works, and commit them. | 2026-11-20 |
| [Q-336](#q-336--image-lag) | you: terminal | Install the release that carries three gate changes you approved: the health-checkout preparation step (Q-3... | 2026-11-20 |
<!-- index:end -->

## Open

### Q-332 · regenerate-fact-check-reports-host
**Needs:** you: terminal · **Opened:** 2026-11-20 · **Status:** OPEN

Regenerate the fact-check skill's eval reports on the host, where the web works, and commit them.

**If you say no:** fact-check's 3 report-dependent test suites stay NOT RUN in every health check (they need generated reports to test against), and the skill's web-search behaviour goes untested; nothing else waits on it.

- **Why it's yours:** the reports need live WebSearch and WebFetch calls, and this sandbox has no web egress; only the host has it.
- **Read:** `docs/working/research-2026-11-20-eval-web-tools-grant.md` (the fix that merged at 6c0563b5: the report generator, `test/skills/generate-reports.bash`, now grants the web tools a fixture lists; before it, all 23 fact-check reports came out Unverified because every web call was denied) · the closed brief `docs/working/briefs/closed/2026-11-20-eval-web-tools-grant.md`.

**Where:** your claude-workflows checkout on the host, at main's tip (6c0563b5 or later), signed in to Claude Code. It runs the skill on each fixture with headless `claude` (subscription usage), then the three suites:

```
bash test/skills/generate-reports.bash fact-check && bats test/skills/fact-check-eval.bats test/skills/fact-check-edge-cases.bats test/skills/fact-check-format.bats
```

**Pass:** the bats run ends with no `not ok`; then commit `test/skills/fact-check/output/`. **Send back:** `Q-332: done`, or the first `not ok` lines if any fail (a failure is a skill finding for the cycle to file, not something to fix by hand).

- **Interim:** the suites stay NOT RUN; the regeneration of the other skills' reports (brief `docs/working/briefs/2026-11-19-regenerate-skill-reports.md`, held by Q-328 [3] until the F2 and F3 format fixes merge) excludes fact-check.
- **2026-11-20, iteration 2338:** the regeneration loop (merged 4f1e4150) ran fact-check's 23 fixtures in the sandbox with the new grant, and they produced real verdicts, so the host is not needed for the reports. 9 fact-check cases still fail on them (finding F12 in `docs/working/research-2026-11-19-regenerate-skill-reports.md`), so its reports were held back and its suites stay NOT RUN; the fix is now agent work on the roadmap. If you agree, answer `Q-332: drop`; nothing is lost.

### Q-336 · image-lag
**Needs:** you: terminal · **Opened:** 2026-11-20 · **Status:** OPEN

Install the release that carries three gate changes you approved: the health-checkout preparation step (Q-333), worktree removals from a parked shell (Q-337) and the cycle-record rule (Q-339): run the one paste below on the host.

**If you say no:** sessions keep running the image built from main 665dbf95: the dev cycle's gate has no `--health-prep` mode and `--settings` prints no `copies` line, so a `Health checkout copies:` line in a repo's `docs/dev-cycle.md` does nothing and philosophy-research keeps copying its Lean cache by hand. Nothing breaks. (The skill and test changes below are in the image too, but sessions read skills from it only after an install.)

- **C (the image's commit):** 665dbf9521413cf4291b4acebd866826b0ae2f52 · **M (main's commit):** 1bb24e5c1213fa1a44a279b081b5ca7979e2257b
- **Merged without your review** (the gate merged these on their own; the image carries none of `docs/`):
  - 319559d9 Merge branch 'docs/loop-start-dir-research' (build-loop self-merge): a research doc only
  - 6a07b026 Merge branch 'docs/why-its-yours-constraint-research' (build-loop self-merge): a research doc only
  - 6c0563b5 Merge branch 'fix/eval-web-tools-grant' (build-loop self-merge): `test/skills/generate-reports.bash` grants headless report runs the web tools a fixture lists, plus a new test file
  - 7b46a90e Merge branch 'fix/self-improvement-worktrees' (build-loop self-merge): `scripts/self-improvement.sh` puts its worktrees under `.worktrees/` instead of `.claude/`, with its test
  - 5eab5704 Merge branch 'fix/self-improvement-env-followups' (build-loop self-merge): `scripts/self-improvement.sh` runs its commit step with literal pathspecs off and moves its `TMPDIR` fallback from `.claude/tmp` to `.worktrees/si-tmp`, with tests
  - 4f1e4150 Merge branch 'measure/regenerate-skill-reports' (build-loop self-merge): 274 generated skill eval reports under `test/skills/*/output/` for 18 skills (Q-321 [2], held by Q-328 [3] until F2 to F7 merged); no code
  - 867f6546 Merge branch 'docs/review-gap-ba-compare' (build-loop self-merge): a research doc only
  - aa91635c Merge branch 'docs/harness-feedback-triage-2026-11-20' (build-loop self-merge): a research doc only
  - 7f086d40 Merge branch 'docs/board-feedback-research' (build-loop self-merge): a research doc only
  - 8daaa173 Merge branch 'fix/rubric-selection-flake' (build-loop self-merge): `scripts/self-improvement.sh`'s rubric selector reads here-strings instead of `printf | grep -q` (a SIGPIPE under `pipefail` dropped a point and broke ties), with two cases in `test/rubric-selection.bats`
  - 1bb24e5c Merge branch 'docs/stale-report-warnings' (build-loop self-merge): a research doc only
- **What changes for you:**
  - f6d555d8 (you approved it, Q-333 [1]): `build-loop.sh --health-prep HC` and a sixth `--settings` line, `copies`, read from a `Health checkout copies: PATH ...` line in `docs/dev-cycle.md`; the dev-cycle skill's step 1 copies those gitignored paths into its health checkout, refusing symlinks, unignored paths and anything outside it. To use it in philosophy-research, add `Health checkout copies: verifier/lean-project/.lake` to that repo's `docs/dev-cycle.md`.
  - cd16883e (Q-337 [1]): the dev-cycle skill removes each worktree in a separate call after a bare `cd` into `.worktrees` (R2), so background build loops stop losing commands; the build-loop prompt no longer says "Your shell starts outside any checkout".
  - fec9f7a3 (Q-339 [1]): `--cycle-diff` and `--land-cycle` refuse a cycle-record change that drops or rewrites earlier iteration blocks, or deletes the record; a fix to a landed block now lands by hand.
  - 01eff59e (Q-335 [1]): findings F2 and F3, seven skills' report formats (title first; a field's value word first), with test-helper changes.
  - cef30487 (Q-329 [1]) and ead9191a (Q-330 [1]): findings F4 to F7 and the F5 verdict drift, in six skills and their tests.
  - 21e925d3: your own commit recording the Q-316 and Q-317 answers; 7df4654d: your answers file `docs/human-author/answers-11-20-26.txt`; ad4f0eef: your harness-feedback ingest (three `docs/working/feedback/` files).
  - The routine rest: 36 dev-cycle lands.
- **Full list:** `git -c log.showSignature=false log --first-parent --format='%h %s' 665dbf9521413cf4291b4acebd866826b0ae2f52..1bb24e5c1213fa1a44a279b081b5ca7979e2257b`
- **Paths changed outside `docs/`, the 274 generated reports under `test/skills/*/output/` counted, not listed (`git diff --name-only 665dbf9521413cf4291b4acebd866826b0ae2f52 1bb24e5c1213fa1a44a279b081b5ca7979e2257b -- test/skills/` shows them) (51 under `docs/` too, which the image does not carry):** `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/self-improvement.sh`, `skills/ai-personas-critique/SKILL.md`, `skills/arithmetic-eval/SKILL.md`, `skills/business-plan-critique-market-sizing/SKILL.md`, `skills/business-plan-critique-moat/SKILL.md`, `skills/dependency-upgrade/SKILL.md`, `skills/dev-cycle/SKILL.md`, `skills/security-reviewer/SKILL.md`, `skills/tech-debt-triage/SKILL.md`, `skills/ui-visual-review/SKILL.md`, `skills/what-if-analysis/SKILL.md`, `skills/yglesias-critique/SKILL.md`, `test/generate-reports-web-grant.bats`, `test/scripts/build-loop-dispatch.bats`, `test/scripts/build-loop-health-prep.bats`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-read.bats`, `test/scripts/self-improvement-clean-state.bats`, `test/skills/architecture-review-format.bats`, `test/skills/architecture-review/eval-criteria.md`, `test/skills/architecture-review/fixtures/tc-arch6-clean-ports-adapters.py`, `test/skills/business-plan-critique-moat/expected-verdicts.bash`, `test/skills/code-fact-check/eval-criteria.md`, `test/skills/code-fact-check/expected-verdicts.bash`, `test/skills/code-fact-check/fixtures/tc-c2.5-unverifiable.py`, `test/skills/dependency-upgrade-format.bats`, `test/skills/divergent-design/expected-verdicts.bash`, `test/skills/eval-helpers.bash`, `test/skills/field-value-rules.bats`, `test/skills/generate-reports.bash`, `test/skills/helpers-recommendation.bats`, `test/skills/helpers.bash`, `test/skills/matrix-analysis-format.bats`, `test/skills/pre-mortem-format.bats`, `test/skills/tech-debt-triage/expected-verdicts.bash`, `test/skills/test-strategy/eval-criteria.md`, `test/skills/test-strategy/fixtures/tc-ts6-duration-parser.py`, `test/skills/ui-visual-review-eval.bats`, `test/skills/ui-visual-review-format.bats`, `test/skills/ui-visual-review/eval-criteria.md`, `test/skills/ui-visual-review/expected-verdicts.bash`, `test/skills/ui-visual-review/fixtures/tc-uv6-disappearing-controls.tsx`, `test/skills/ui-visual-review/fixtures/tc-uv7-weak-affordance.tsx`, `test/skills/what-if-analysis-format.bats`

Run this on the host, in your claude-workflows checkout at main's tip, then start a new sandbox session:

```
sh -c 'n=0; if cd "/home/magfrump/claude-workflows"; then n=1; fi; if h="$(git rev-parse HEAD)" && test "$h" = "$(git rev-parse refs/heads/main)"; then n=$((n+1)); else echo "release refused: this checkout is not at the tip of main"; fi; for p in scripts/build-loop.sh scripts/d6.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/ devcontainer-config/install.sh; do if g="$(git rev-parse "HEAD:$p")" && test "$g" = "$(git rev-parse "1bb24e5c1213fa1a44a279b081b5ca7979e2257b:$p")"; then n=$((n+1)); else echo "release refused: $p changed after 1bb24e5c1213fa1a44a279b081b5ca7979e2257b: run the dev cycle for a new paste"; fi; done; case "$n" in 9) ./devcontainer-config/install.sh;; *) echo "release refused: $n of 9 checks passed"; false;; esac'
```

**Pass:** the installer finishes without a `release refused` line. **Send back:** `Q-336: done`.

Optional, for watch Q-167 (post-install-host-probes: the hint a fresh bless prints before any probe has never been seen): if the install re-blesses, add `| tee "$TMPDIR/install.log"` to the end of the paste, and right after it, before any probe, send back the output of `grep -E 'Verified live:|^Next:' "$TMPDIR/install.log"` and `cc-isolated --list 2>&1 | grep -i 'blessed config'` (three lines).

Optional, for watch Q-331 (the write-guard fix 61122f34 has no live check): in a session that has done a web search, an edit to an ordinary file inside a `.claude/worktrees/` worktree applies with no ask, while an edit to that worktree's CLAUDE.md still asks. Add `guard: fine`, or what asked.

- **Interim:** the image's gate (665dbf95) runs; nothing breaks.

### Q-340 · threat-model-walkthrough-after-t12
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Should a quarterly threat-model walk-through of the risks you have accepted come back now that you said trial T12 does not cover what it is for?

**If you say no:** nothing is scheduled; the reshaped T12 (below) is the only regular look at those risks, and the question does not come back on its own.

- **Background:** Q-103's residual risks are the known gaps you accepted in the build-loop design (for example, a process running as your user can still reach the gate's shell through PATH or the session's settings). Area B's research (`docs/working/research-2026-11-19-area-b-ask-habituation.md` §6) proposed a short walk-through of them each quarter (idea B8, about 20 minutes) and set it aside while trial T12 ("what the checks caught" in the weekly digest, `docs/working/trials/2026-11-06-attention-and-trust.md`) tested a cheaper answer. The watch holding it (Q-322, now closed) fired on your T12 verdict of 2026-11-20 (Q-327 [2]): "this is alright, but it doesn't really address the chain of trust between the reports and the facts in the code".
- **Why it's yours:** it spends about 20 minutes of your time a quarter; only you can say whether that look is worth it.
- **Read:** the research doc §6 above; the in-flight brief `docs/working/briefs/2026-11-20-codify-trial-set-2.md`, which reshapes T12 so each line names a number or output you can check yourself.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] schedule it** | The cycle files one `you: walkthrough` each quarter, the first now: a list of the accepted risks, each with what would show it has become live. | About 20 minutes a quarter. | You spend the time on risks that have not moved. |
| **[2] hold to 2027-01** | A watch brings this question back at the first iteration on or after 2027-01-01, after the reshaped T12 has run about six weeks. | Nothing now. | A risk that becomes live waits up to six weeks for a deliberate look (the `⚠ SECURITY` line still fires on one). |
| **[3] the reshaped T12 replaces it** | No walk-through; the digest's "what the checks caught" lines, each naming a fact you can check, are the regular look. | A minute a week, reading the digest. | The digest reports what the checks stopped, not risks no check covers, so a gap in the design itself is never revisited. |

- **Interim:** nothing is scheduled; the T12 brief runs either way.
- **If the answer differs:** [1] adds a quarterly entry and a first walk-through doc; [2] opens a dated watch.

### Q-341 · decision-040-ask-trigger
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Decision 040's "too many asks" revisit trigger has fired if "a cycle" means a day; should the cycle reopen that decision, wait for exact counts, or read "a cycle" as one iteration (not fired)?

**If you say no:** nothing is reopened; the interim below holds and the next weekly digest shows the counts.

- **Background:** decision 040 (`docs/decisions/040-questions-doc-owner-only.md`) made `questions.md` hold only things that need you. One of its revisit triggers is "`you:` asks exceed ~5 per cycle for 3 cycles". Counting one day's cycle record as one cycle, the asks opened were 6 (2026-11-18), 19 (11-19) and 10 (11-20); 19 of those 35 were merge entries (requests to approve a finished build loop's merge). Read as one iteration, a cycle opens one or two asks and the trigger has not fired. The roadmap Idea "Say what 'a cycle' is in decision 040's ask-count trigger" has waited on this since 2026-11-13.
- **Why it's yours:** the trigger exists to protect your attention, and which reading it meant is your call.
- **The number:** counted by hand from the questions files by this iteration's trigger pass; the hand counts behind area B's research disagreed by edition, which is why the in-flight brief `docs/working/briefs/2026-11-20-ask-counter.md` builds a reproducible counter (`questions.sh counts`). You answered fast: 2 of the 35 are still open.
- **Read:** decision 040's revisit triggers; watch Q-262 in `docs/working/watching.md` (reopens merge approval if merge entries pass 11 a week in 3 of 4 weekly digests), which covers the merge share only.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] reopen 040 now** | Agent work: a divergent-design pass on cutting asks per day (merge entries first), answered with a brief or "no change". | One later read of its result. | Effort on a problem you do not feel; the merge share is already watched by Q-262. |
| **[2] wait for the counter** | Decide after the ask counter lands and one weekly digest prints exact per-class counts. | Nothing now. | A week more at today's ask rate. |
| **[3] a cycle is one iteration** | The trigger has not fired; the record's wording is fixed to say so and the Idea closes. | Nothing. | A real overload by day goes unflagged by this trigger (Q-262 still flags merge entries). |

- **Interim:** [2]; nothing is reopened.
- **If the answer differs:** [1] adds a Now item; [3] edits the trigger's wording through a review merge (decision records are not cycle-writable).

### Q-342 · merge-gate-2026-11-20-codify-trial-set-2-a77146f3a174
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Merge the build loop's change that writes trials T9, T11 and T12 into the dev-cycle skill?

**If you say no:** the branch waits unmerged; the cycle keeps following the trial doc for T9, T11 and T12 by hand, as it does today.

This is the work you asked for in Q-327 [2] (keep T9 further reading, T11 one deliberate look a week, T12 what the checks caught; stop T8 and T10), from brief `docs/working/briefs/2026-11-20-codify-trial-set-2.md`. The skill is gate code (the dev cycle's own instructions), which is why it needs your review and reaches sessions only with the next release (Q-336).

- **What changes:** T9: links in each entry's existing `**Read:**` line and at the end of the final message, as many as help, no cap of two. T11: the weekly digest's random self-merge sample becomes one deliberate look (a self-merge or a design pick, one question, about five minutes), and the digest counts the looks you took. T12: a new weekly-digest bullet listing what the gates and reviews stopped, each line naming a refusal line, a red row's file or a count with its command, so you can check it yourself.
- **Outside the brief:** one line of your ratified audience profile `docs/audiences/owner.md` (who reads final messages, ratified in Q-299) changes from "at most two links" to links with no fixed count, to match T9.
- **Left open:** rubric row A6 (amber): whether "a fact you can check" answers your note that T12 should report numbers you have actually seen; the next weekly digests show it.
- **Read:** the loop's research doc `docs/working/research-2026-11-20-codify-trial-set-2.md`; the rubric `docs/reviews/code-review-rubric-2026-11-20-codify-trial-set-2.md`; the diff: `git diff b7663bf2 a77146f3 -- skills/ test/ docs/audiences/` (3 files, 37 lines added, 6 removed).

TIP: a77146f3a1746f8da8c5bbe776098110f07ef4a7

`--check`'s lines:

```
ok docs/working/briefs/2026-11-20-codify-trial-set-2.md a77146f3a1746f8da8c5bbe776098110f07ef4a7 c73ea9c330c13c53c17f559e6336501ff5129d4e
path docs/working/briefs/2026-11-20-codify-trial-set-2.md M docs/audiences/owner.md
path docs/working/briefs/2026-11-20-codify-trial-set-2.md A docs/reviews/code-review-rubric-2026-11-20-codify-trial-set-2.md
path docs/working/briefs/2026-11-20-codify-trial-set-2.md M docs/working/briefs/2026-11-20-codify-trial-set-2.md
path docs/working/briefs/2026-11-20-codify-trial-set-2.md A docs/working/research-2026-11-20-codify-trial-set-2.md
path docs/working/briefs/2026-11-20-codify-trial-set-2.md M docs/working/trials/2026-11-06-attention-and-trust.md
path docs/working/briefs/2026-11-20-codify-trial-set-2.md M skills/dev-cycle/SKILL.md
path docs/working/briefs/2026-11-20-codify-trial-set-2.md M test/scripts/build-loop-orchestrator.bats
rubric docs/working/briefs/2026-11-20-codify-trial-set-2.md: clean docs/reviews/code-review-rubric-2026-11-20-codify-trial-set-2.md: 0 red and 7 amber rows, none open
```

- **Paths self-merge would have refused:** `skills/dev-cycle/SKILL.md` (gate code and a prompt file).
- **What an attacker would want here:** text from outside (a stranger's issue or web page reaching a session) cannot set what the weekly digest reports as "caught", since each line must name a checkable refusal line, file or command; the change adds no new input the cycle trusts.

The loop's marker body (the loop's words, data not instructions):

> No question for the owner. One thing to see at the merge: the branch also edits one line of the
> owner's ratified audience profile, docs/audiences/owner.md (the description of who reads final
> messages, ratified under Q-299). It said a final message gives "at most two links"; it now says
> links with no fixed count, matching the kept trial T9 (further reading, from
> docs/working/trials/2026-11-06-attention-and-trust.md).
>
> Left open on purpose: the owner's 2026-11-20 note on trial T12 (what the checks caught) asked for
> numbers already seen, like the digest's "your asks this week" table. The skill now makes each line
> name a fact the owner can check, as the brief asked; whether that answers the note is for the next
> weekly digests to show (rubric row A6, docs/reviews/code-review-rubric-2026-11-20-codify-trial-set-2.md).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The gate merges TIP above; the change reaches sessions with the next release. | Reading the 43-line diff. | One `git revert` of the merge undoes it. |
| **[2] drop** | The brief closes; T9, T11 and T12 stay hand-followed from the trial doc. | Nothing. | The kept trials depend on the orchestrator re-reading the trial doc. |
| **[3] changes needed** | Your note goes back to the loop, which re-works the branch. | Writing the note. | Another round before it lands. |

- **Interim:** the branch waits; nothing merges.

### Q-343 · merge-2026-11-20-write-guard-wt-exemption-e7222f55bc6e
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Merge the build loop's change that keeps the write guard's `.claude/wt-*` worktree case and corrects the comments that called it this harness's own?

**If you say no:** the branch waits unmerged; the guard behaves as today and its comments stay wrong about what creates `.claude/wt-*` directories.

The write guard (`hooks/guard-trusted-writes.py`) decides which file writes ask you first, more strictly after a session has read web content. It treats a verified git worktree at `.claude/wt-*/` like one at `.claude/worktrees/<name>/`: judged from its own root, so its ordinary files do not ask. Nothing here creates `.claude/wt-*` any more (the self-improvement loop moved to `.worktrees/` in 7b46a90e, build loops in b3e25cf1), but `.claude/wt-q096b` still exists in your checkout. Brief: `docs/working/briefs/2026-11-20-write-guard-wt-exemption.md`.

- **What changes:** comments only in the hook (four places now say the case serves any such worktree, for example one left from before `.worktrees/`), and one bats case pinning it: in a web-tainted session a plain file in a `.claude/wt-x/` worktree gets no opinion and that worktree's `CLAUDE.md` asks. The loop checked the code is unchanged (same syntax tree with docstrings blanked).
- **Why keep the case:** dropping it removes no risk (the worktree's policy files still ask) and would bring back failure pattern FP-185 in `docs/failure-patterns.md` ("every edit in a worktree under `.claude/` asks") for `.claude/wt-q096b`.
- **No code-review rubric:** the loop's two review rounds are in its research doc, not a `docs/reviews/` rubric file, so `--check` printed `rubric … none`. No `Live-verified:` trailer: `hooks/live-verify-gate.sh` gates only `devcontainer-config/` files.
- **Read:** `docs/working/research-2026-11-20-write-guard-wt-exemption.md`; the diff: `git diff b06a2b8b e7222f55 -- hooks/ test/` (2 files, 37 lines added, 10 removed).

TIP: e7222f55bc6e97c8ef21c8bb70a590c8d540f317

`--check`'s lines:

```
ok docs/working/briefs/2026-11-20-write-guard-wt-exemption.md e7222f55bc6e97c8ef21c8bb70a590c8d540f317 047e2ce79efc31990dceb7db206125812da7cd5b
path docs/working/briefs/2026-11-20-write-guard-wt-exemption.md M docs/working/briefs/2026-11-20-write-guard-wt-exemption.md
path docs/working/briefs/2026-11-20-write-guard-wt-exemption.md A docs/working/research-2026-11-20-write-guard-wt-exemption.md
path docs/working/briefs/2026-11-20-write-guard-wt-exemption.md M hooks/guard-trusted-writes.py
path docs/working/briefs/2026-11-20-write-guard-wt-exemption.md M test/hooks/guard-trusted-writes.bats
rubric docs/working/briefs/2026-11-20-write-guard-wt-exemption.md: none: fix/write-guard-wt-exemption changes 2 paths outside docs/ and adds or changes no code-review rubric under docs/reviews/
```

- **Paths self-merge would have refused:** none is gate code; `hooks/guard-trusted-writes.py` is a hook the harness installs into sessions.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The gate merges TIP above; the comment fix reaches sessions with the next release. | Reading a comment-only diff. | One `git revert` undoes it. |
| **[2] drop** | The brief closes; the comments stay as they are. | Nothing. | Readers of the hook keep a wrong account of what creates `.claude/wt-*`. |
| **[3] changes needed** | Your note goes back to the loop (for example, drop the case after all). | Writing the note. | Another round. |

- **Interim:** the branch waits; nothing merges.

### Q-344 · merge-gate-2026-11-20-ask-counter-47210f4bf75f
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Merge the build loop's `questions.sh counts`, a reproducible ask counter for the weekly digest?

**If you say no:** the branch waits unmerged; weekly digests keep counting your asks by hand, and Q-341 (whether decision 040's "too many asks" trigger fired) has no exact numbers to wait for.

Brief: `docs/working/briefs/2026-11-20-ask-counter.md` (area B's B2, from `docs/working/research-2026-11-19-area-b-ask-habituation.md`). `scripts/questions.sh` and the dev-cycle skill are gate code, so this needs your review and reaches sessions only with the next release (Q-336).

- **What it does:** `questions.sh counts --since YYYY-MM-DD [--until YYYY-MM-DD]` prints one table: per class (merge, re-dispatch, real choice, walkthrough, terminal, fyi) the entries opened, answered, answered with the first option, and the median and longest wait in days; then sittings (distinct commits that record a judgment answer), and by ID any answer it could not read as an option and any entry it could not date. It refuses, naming the entry or file, on a malformed entry, unreadable file or history. The weekly digest's ask-counter bullet now says to paste its output.
- **Checked against the hand count** behind area B (2026-10-30 to 11-19): merge 44 answered, 43 first option, and terminal 12 and fyi 1 match; re-dispatch 5 as the brief predicted; real choice 18 (the hand count's 17 plus Q-278, which it had left out as withdrawn).
- **Worth knowing:** an answer's date is its commit's author date, so a branch commit merged later can shift an already-printed window by one; answers `[4]` and up are listed as "not read as an option" (the shared answer rule models 1 to 3) but still counted as not first option.
- **Review:** one reviewer subagent, two rounds; round 1's High (an unreadable questions file printed a zero table and exit 0) is fixed with tests. No `docs/reviews/` rubric file, so `--check` printed `rubric … none`.
- **Overlap:** Q-342 (trial set 2) also edits the weekly-digest step of the same skill; whichever merges second may be sent back automatically to merge main in.
- **Read:** `docs/working/research-2026-11-20-ask-counter.md`; the diff: `git diff b7663bf2 47210f4b -- scripts/ skills/ test/` (3 files, 335 lines added: 146 in `questions.sh`, 3 in the skill, 187 of tests).

TIP: 47210f4bf75f3d63979c000bf9ba145251b1ac5d

`--check`'s lines:

```
ok docs/working/briefs/2026-11-20-ask-counter.md 47210f4bf75f3d63979c000bf9ba145251b1ac5d 5df6c8ea40f9baf9152353cf689ef7b99607e813
path docs/working/briefs/2026-11-20-ask-counter.md M docs/working/briefs/2026-11-20-ask-counter.md
path docs/working/briefs/2026-11-20-ask-counter.md A docs/working/research-2026-11-20-ask-counter.md
path docs/working/briefs/2026-11-20-ask-counter.md M scripts/questions.sh
path docs/working/briefs/2026-11-20-ask-counter.md M skills/dev-cycle/SKILL.md
path docs/working/briefs/2026-11-20-ask-counter.md A test/scripts/questions-counts.bats
rubric docs/working/briefs/2026-11-20-ask-counter.md: none: feat/ask-counter changes 3 paths outside docs/ and adds or changes no code-review rubric under docs/reviews/
```

- **Paths self-merge would have refused:** `scripts/questions.sh` and `skills/dev-cycle/SKILL.md` (gate code; the skill is also a prompt file).
- **What an attacker would want here:** `counts` reads the questions files and git history, which a session can write; a stranger's text that reached a session could plant entries to skew the counts you read. It only reports and decides nothing (no gate keys on it), and it refuses malformed entries by name.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The gate merges TIP above; the digest uses `counts` after the next release. | Reading a 146-line script change. | One `git revert` undoes it. |
| **[2] drop** | The brief closes; asks stay hand-counted. | Nothing. | The counts behind Q-262 and Q-341 stay inconsistent between editions. |
| **[3] changes needed** | Your note goes back to the loop. | Writing the note. | Another round. |

- **Interim:** the branch waits; nothing merges.

### Q-345 · answers-file-counts-as-answer
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Should a committed answers file under `docs/human-author/` (like `answers-11-20-26.txt`) count as your answer, the way an answer line you write into `docs/working/questions.md` already does?

**If you say no:** nothing is built; answers files stay unread by the gate, and the cycle picks up their answers only when it notices them and you confirm in session, as on 2026-11-20.

- **Background:** the cycle reads answers only through `dev-cycle.sh --check-answer`, which looks at the two questions files on main. A commit adding an answers file is classed `other`, and every ID in it stays open. This happened in three projects: behemoth-arsenal (its harness-feedback entry F-002, whose 21 answers merged nothing until you repeated three in session), philosophy-research (its F-004 and F-005) and here (7df4654d, your answers to Q-255, Q-302 and Q-327). Build loops and the cycle cannot write `docs/human-author/` (the self-merge floor and `--cycle-diff` refuse it), so only you and hand sessions can, as with `questions.md`.
- **Why it's yours:** it decides what counts as your word.
- **Read:** the triage's F-002 section in `docs/working/research-2026-11-20-harness-feedback-triage.md` (design and residual risks); the global instructions' "Running questions document" (you may answer "in a file").

The triage loop's tentative pick is [1], on S10 (spend your attention last, `docs/constraints.md`).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] read the file** | The gate reads `Q-NNN: [N]` lines from new `docs/human-author/answers-*` files on main dated after the entry opened; a conflict with the questions file skips; `--main-log` classes such a commit `answers`. | None per batch. | A hand session's file could answer for you, as `questions.md` already can. |
| **[2] detect and confirm** | The cycle lists a new file's answers in its final message; one reply from you takes them. | One reply per batch. | Answers wait for your next session. |
| **[3] status quo** | Answer in `questions.md` or in session. | Changing your habit. | Answers files keep being ignored. |

- **Blocks:** the roadmap Now item "answers files count as the owner's answer" (brief 2 of the triage).
- **Interim:** nothing is built; the cycle reads a new answers file by hand and asks you to confirm in session.
- **If the answer differs:** [2] is a smaller brief to the same paths; [3] closes the item.

### Q-348 · merge-gate-2026-11-20-si-commit-literal-pathspecs-1925b0ea957e
**Needs:** you: judgment · **Opened:** 2026-11-20 · **Status:** OPEN

Merge the build loop's fix that makes the self-improvement loop's commit helper work when literal pathspecs are exported?

**If you say no:** the branch waits unmerged; the helper keeps relying on its one caller's guard (5eab5704), and `test/si-commit-child-work.bats` keeps failing 8 of 15 cases whenever `GIT_LITERAL_PATHSPECS=1` is exported, as the dev-cycle reader does.

`si_commit_child_work` (in `scripts/lib/si-commit.sh`, gate code because everything under `scripts/lib/` is) commits a self-improvement child's work with `git add -A -- . ":(exclude).si-commit-msg"`. Under `GIT_LITERAL_PATHSPECS=1` git reads that exclude as a file name, and the add fails. Brief: `docs/working/briefs/2026-11-20-si-commit-literal-pathspecs.md`.

- **What changes:** the lib sets `GIT_LITERAL_PATHSPECS=0` on that one `git add` only (not exported); the caller's copy of the guard in `scripts/self-improvement.sh` is removed so the rule has one home (S3, one source of truth per rule, `docs/constraints.md`); a new bats case exports the variable and checks the commit, that the message file is not committed, and that the caller's value is still 1.
- **Tests:** the helper's suite 16/16 and the self-improvement clean-state suite 29/29, each with the variable exported and unset; health check and hermeticity lint pass. Rubric clean (0 red, 0 amber).
- **Left for later:** `guides/validation-gates.md:33` lists this helper's hardening but not the new guard; the cycle cannot write `guides/`, so it is a roadmap item.
- **Read:** `docs/working/research-2026-11-20-si-commit-literal-pathspecs.md`; the rubric `docs/reviews/code-review-rubric-2026-11-20-si-commit-literal-pathspecs.md`; the diff: `git diff 10c42a29 1925b0ea -- scripts/ test/` (3 files, 27 lines added, 5 removed).

TIP: 1925b0ea957ed9cda91c14b43c2c2fb6773475c8

`--check`'s lines:

```
ok docs/working/briefs/2026-11-20-si-commit-literal-pathspecs.md 1925b0ea957ed9cda91c14b43c2c2fb6773475c8 9ee93e1d1f9047414761fc46c3fbe047e96766bb
path docs/working/briefs/2026-11-20-si-commit-literal-pathspecs.md A docs/reviews/code-review-rubric-2026-11-20-si-commit-literal-pathspecs.md
path docs/working/briefs/2026-11-20-si-commit-literal-pathspecs.md M docs/working/briefs/2026-11-20-si-commit-literal-pathspecs.md
path docs/working/briefs/2026-11-20-si-commit-literal-pathspecs.md A docs/working/research-2026-11-20-si-commit-literal-pathspecs.md
path docs/working/briefs/2026-11-20-si-commit-literal-pathspecs.md M scripts/lib/si-commit.sh
path docs/working/briefs/2026-11-20-si-commit-literal-pathspecs.md M scripts/self-improvement.sh
path docs/working/briefs/2026-11-20-si-commit-literal-pathspecs.md M test/si-commit-child-work.bats
rubric docs/working/briefs/2026-11-20-si-commit-literal-pathspecs.md: clean docs/reviews/code-review-rubric-2026-11-20-si-commit-literal-pathspecs.md: 0 red and 0 amber rows, none open
```

- **Paths self-merge would have refused:** `scripts/lib/si-commit.sh` (gate code).
- **What an attacker would want here:** nothing new: the change narrows a git variable for one call and adds no input the loop trusts.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] merge** | The gate merges TIP above. | Reading a 32-line diff. | One `git revert` undoes it. |
| **[2] drop** | The brief closes; the caller's guard stays the only one. | Nothing. | A new caller of the helper fails the same way. |
| **[3] changes needed** | Your note goes back to the loop. | Writing the note. | Another round. |

- **Interim:** the branch waits; nothing merges.
