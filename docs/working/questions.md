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

- **C (the image's commit):** 665dbf9521413cf4291b4acebd866826b0ae2f52 · **M (main's commit):** fec9f7a3821c892675c58f02e4da9dc43c5bfbda
- **Merged without your review** (the gate merged these on their own; the image carries none of `docs/`):
  - 319559d9 Merge branch 'docs/loop-start-dir-research' (build-loop self-merge): a research doc only
  - 6a07b026 Merge branch 'docs/why-its-yours-constraint-research' (build-loop self-merge): a research doc only
  - 6c0563b5 Merge branch 'fix/eval-web-tools-grant' (build-loop self-merge): `test/skills/generate-reports.bash` grants headless report runs the web tools a fixture lists, plus a new test file
  - 7b46a90e Merge branch 'fix/self-improvement-worktrees' (build-loop self-merge): `scripts/self-improvement.sh` puts its worktrees under `.worktrees/` instead of `.claude/`, with its test
  - 5eab5704 Merge branch 'fix/self-improvement-env-followups' (build-loop self-merge): `scripts/self-improvement.sh` runs its commit step with literal pathspecs off and moves its `TMPDIR` fallback from `.claude/tmp` to `.worktrees/si-tmp`, with tests
  - 4f1e4150 Merge branch 'measure/regenerate-skill-reports' (build-loop self-merge): 274 generated skill eval reports under `test/skills/*/output/` for 18 skills (Q-321 [2], held by Q-328 [3] until F2 to F7 merged); no code
- **What changes for you:**
  - f6d555d8 (you approved it, Q-333 [1]): `build-loop.sh --health-prep HC` and a sixth `--settings` line, `copies`, read from a `Health checkout copies: PATH ...` line in `docs/dev-cycle.md`; the dev-cycle skill's step 1 copies those gitignored paths into its health checkout, refusing symlinks, unignored paths and anything outside it. To use it in philosophy-research, add `Health checkout copies: verifier/lean-project/.lake` to that repo's `docs/dev-cycle.md`.
  - cd16883e (Q-337 [1]): the dev-cycle skill removes each worktree in a separate call after a bare `cd` into `.worktrees` (R2), so background build loops stop losing commands; the build-loop prompt no longer says "Your shell starts outside any checkout".
  - fec9f7a3 (Q-339 [1]): `--cycle-diff` and `--land-cycle` refuse a cycle-record change that drops or rewrites earlier iteration blocks, or deletes the record; a fix to a landed block now lands by hand.
  - 01eff59e (Q-335 [1]): findings F2 and F3, seven skills' report formats (title first; a field's value word first), with test-helper changes.
  - cef30487 (Q-329 [1]) and ead9191a (Q-330 [1]): findings F4 to F7 and the F5 verdict drift, in six skills and their tests.
  - 21e925d3: your own commit recording the Q-316 and Q-317 answers; 7df4654d: your answers file `docs/human-author/answers-11-20-26.txt`.
  - The routine rest: 21 dev-cycle lands.
- **Full list:** `git -c log.showSignature=false log --first-parent --format='%h %s' 665dbf9521413cf4291b4acebd866826b0ae2f52..fec9f7a3821c892675c58f02e4da9dc43c5bfbda`
- **Paths changed outside `docs/`, the 274 generated reports under `test/skills/*/output/` counted, not listed (`git diff --name-only 665dbf9521413cf4291b4acebd866826b0ae2f52 fec9f7a3821c892675c58f02e4da9dc43c5bfbda -- test/skills/` shows them) (33 under `docs/` too, which the image does not carry):** `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/self-improvement.sh`, `skills/ai-personas-critique/SKILL.md`, `skills/arithmetic-eval/SKILL.md`, `skills/business-plan-critique-market-sizing/SKILL.md`, `skills/business-plan-critique-moat/SKILL.md`, `skills/dependency-upgrade/SKILL.md`, `skills/dev-cycle/SKILL.md`, `skills/security-reviewer/SKILL.md`, `skills/tech-debt-triage/SKILL.md`, `skills/ui-visual-review/SKILL.md`, `skills/what-if-analysis/SKILL.md`, `skills/yglesias-critique/SKILL.md`, `test/generate-reports-web-grant.bats`, `test/scripts/build-loop-dispatch.bats`, `test/scripts/build-loop-health-prep.bats`, `test/scripts/build-loop-orchestrator.bats`, `test/scripts/build-loop-read.bats`, `test/scripts/self-improvement-clean-state.bats`, `test/skills/architecture-review-format.bats`, `test/skills/architecture-review/eval-criteria.md`, `test/skills/architecture-review/fixtures/tc-arch6-clean-ports-adapters.py`, `test/skills/business-plan-critique-moat/expected-verdicts.bash`, `test/skills/code-fact-check/eval-criteria.md`, `test/skills/code-fact-check/expected-verdicts.bash`, `test/skills/code-fact-check/fixtures/tc-c2.5-unverifiable.py`, `test/skills/dependency-upgrade-format.bats`, `test/skills/divergent-design/expected-verdicts.bash`, `test/skills/eval-helpers.bash`, `test/skills/field-value-rules.bats`, `test/skills/generate-reports.bash`, `test/skills/helpers-recommendation.bats`, `test/skills/helpers.bash`, `test/skills/matrix-analysis-format.bats`, `test/skills/pre-mortem-format.bats`, `test/skills/tech-debt-triage/expected-verdicts.bash`, `test/skills/test-strategy/eval-criteria.md`, `test/skills/test-strategy/fixtures/tc-ts6-duration-parser.py`, `test/skills/ui-visual-review-eval.bats`, `test/skills/ui-visual-review-format.bats`, `test/skills/ui-visual-review/eval-criteria.md`, `test/skills/ui-visual-review/expected-verdicts.bash`, `test/skills/ui-visual-review/fixtures/tc-uv6-disappearing-controls.tsx`, `test/skills/ui-visual-review/fixtures/tc-uv7-weak-affordance.tsx`, `test/skills/what-if-analysis-format.bats`

Run this on the host, in your claude-workflows checkout at main's tip, then start a new sandbox session:

```
sh -c 'n=0; if cd "/home/magfrump/claude-workflows"; then n=1; fi; if h="$(git rev-parse HEAD)" && test "$h" = "$(git rev-parse refs/heads/main)"; then n=$((n+1)); else echo "release refused: this checkout is not at the tip of main"; fi; for p in scripts/build-loop.sh scripts/d6.sh scripts/dev-cycle.sh scripts/questions.sh scripts/lib/ skills/dev-cycle/ devcontainer-config/install.sh; do if g="$(git rev-parse "HEAD:$p")" && test "$g" = "$(git rev-parse "fec9f7a3821c892675c58f02e4da9dc43c5bfbda:$p")"; then n=$((n+1)); else echo "release refused: $p changed after fec9f7a3821c892675c58f02e4da9dc43c5bfbda: run the dev cycle for a new paste"; fi; done; case "$n" in 9) ./devcontainer-config/install.sh;; *) echo "release refused: $n of 9 checks passed"; false;; esac'
```

**Pass:** the installer finishes without a `release refused` line. **Send back:** `Q-336: done`.

Optional, for watch Q-167 (post-install-host-probes: the hint a fresh bless prints before any probe has never been seen): if the install re-blesses, add `| tee "$TMPDIR/install.log"` to the end of the paste, and right after it, before any probe, send back the output of `grep -E 'Verified live:|^Next:' "$TMPDIR/install.log"` and `cc-isolated --list 2>&1 | grep -i 'blessed config'` (three lines).

Optional, for watch Q-331 (the write-guard fix 61122f34 has no live check): in a session that has done a web search, an edit to an ordinary file inside a `.claude/worktrees/` worktree applies with no ask, while an edit to that worktree's CLAUDE.md still asks. Add `guard: fine`, or what asked.

- **Interim:** the image's gate (665dbf95) runs; nothing breaks.

