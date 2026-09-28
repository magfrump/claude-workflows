# Proposal: smaller review units and a cheaper test gate

**Date:** 2026-09-27 · **Status:** proposal, nothing implemented · **Source run:** the Q-076/077/078/080 batch (session dbfd30e0, 2026-09-27 20:45Z → 09-28 04:15Z, ~7.5h, 42 subagents, merges `b7fbb2a` and `7387d8f`)

## What happened (evidence)

- **One review unit for four items.** `parallel-worktrees.md` step 4.4 says to review the combined diff "as one pass, not per-item". The rule held Q-077/078/080 inside Q-076's loop through three fact-check iterations. Every Incorrect claim in every iteration was in Q-076. By 21:50 the reviewers had already isolated it, and the split was offered then, but it happened only at the loop cap (asked 00:09, answered 01:10). The three small items waited ~3h20m.
- **The design moved while under review.** Each fact-check round found new bypass families: receivepack/pushurl, then includeIf/husky/rebase-exec, then gitdir/alternates. The design changed twice (key list → scan → tripwire + `cc-push`). The Q-076 code grew from +476 to +3,613 lines during review. The review loop was doing threat modelling.
- **Every round re-checked the whole diff.** The iteration 2 and 3 fact-check briefs said "every checkable claim … in the pass-1 diff". pr-prep 3d already says to review only `last-review..HEAD`; that instruction lives in prose and was not followed.
- **The critics came late.** The security, architecture, performance and API critics first ran after four fact-check rounds. Security then found 2 High issues ("don't merge").
- **The test gate cost about 55 minutes of re-runs.** There were 8 full health-check runs, 5 of them red, at 7–9 min each, plus ~13 fast-suite runs at ~3.2 min:
  - *Real* (1): shellcheck SC2155 in a new bats file. It took 3 full runs to see: one timed out, one had its output piped through `grep fail` and lost the failure, one wrote to a file.
  - *Environmental* (3): install-host T33, T83 and T6. Each failed only in full runs and passed alone. Leftover probe processes from review agents (a sleep, a `cc-push` Ctrl-C probe blocked on a FIFO) tripped install.sh's no-agent guard. The tests stub `pgrep`, but the `/proc` cwd scan reads the real process table.
  - *Self-inflicted* (1): `questions.md` was edited while a health-check was running, so the index went stale mid-run.
  - *Structural:* health-check re-runs the fast suite after a standalone fast run, and `test/scripts/health-check.bats` runs health-check nested, so every gate failure shows up twice. `run-tests.sh` accepts only `--fast|--slow|--all`. It has no file, changed-only or failed-only mode, and no parallelism.
- **User-decision latency was ~1h45m**, 61m of it on the split question.

## Proposals

Ranked by estimated time saved on a run like this one, against implementation cost.

### A. Make the review unit the item, not the batch

**A1 · One review→fix→merge loop per independent item.** Replace parallel-worktrees step 4.4 ("one pass, not per-item") with: each item branch runs its own pr-prep loop and merges to `main` as soon as it is green. Only items that share files or state are reviewed together. Two things stay combined:
- the final test gate on `main` after each merge;
- one short cross-item check (does item N break item M's assumptions?) when two items touch the same subsystem.

The rule was written against *N tiny review passes*. That cost is real but small next to one hard item holding N−1 easy ones hostage. *Saves ~2h here. Cost: a doc change in two workflows (parallel-worktrees, pr-prep).*

**A2 · A split trigger after iteration 1, not at the cap.** Add to review-fix-loop.md: after any iteration, if one item or file group accounts for ≥ ~75% of the Must Fix/Incorrect findings, split it into its own loop now and let the rest proceed. In /away mode, splitting is the default, logged as an interim in `questions.md`, not a blocking question. A split is cheap to reverse; waiting is not. *Saves the 61-min question plus ~2 iterations on the other items.*

**A3 · Design probe before review, for security-boundary work.** When the diff touches an enforcement file (the `live-verify-gate` manifest already lists them), run one adversarial "enumerate the bypass families" agent against the *design* before the implementation is reviewed. This is a spike (row 8) or a pre-mortem, not a code-review. If it finds a family the design doesn't cover, the design changes before the loop starts, and the loop's counter measures polish, not discovery. *Would have moved two design reversals out of the loop.*

**A4 · A size budget per unit.** At loop entry, a unit over ~600 changed code lines (reviews excluded) must split into stacked units, unless the user waives it. For Q-076 the stack would have been: extract `cc-exit-scan.sh` → `cc-gitdir.sh` validity predicate → scan tripwire → `cc-push` → docs. Each lower unit merges once green, so later units review against a settled base. The pr-prep step-0 size check already computes the number; this makes it a gate.

### B. Make the delta review mechanical

**B1 · Stamp the reviewed commit and compute the range.** The rubric already starts with `Commit: <sha>`. Have `/code-review` (and the fact-check brief template) take `--since <sha>`, defaulting to the last rubric's stamp on this branch, so iteration 2+ reviews `sha..HEAD` without anyone remembering to. Falling back to a full review (pr-prep 3d's "fixes touched most of the PR") stays an explicit flag.

**B2 · Replicate count by round.** Use k=3 fact-check replicates on the first full pass and k=1 on delta passes. The final confirming pass stays k=3, full diff. A round was ~14–19 min × 3 agents.

**B3 · Run the critic panel in iteration 1 alongside fact-check** (with `--loop-pass`) for any unit that touches an enforcement file. The security Highs would have surfaced ~4h earlier.

### C. Make the test gate cheap to re-run

**C1 · `run-tests.sh` gains:**
- `--failed`: re-runs only the last run's failures. Verified on bats 1.8.2: once `.bats/run-logs/` exists, `bats --filter-status failed` re-runs exactly the failed tests. (Add `.bats/` to `.gitignore`.)
- `FILE...`: runs named suites with the same report gating and hermeticity checks as a full run.
- `--changed [BASE]`: runs suites whose file, or whose sourced/executed scripts, changed since `BASE`. Start simple: suites that mention a changed path's basename, plus every fast suite. It is a pre-gate, not the gate.
- `--jobs N` when GNU `parallel` is present (it is not in the image today; see C6).

**C2 · Health-check: fail fast, log always, and allow a subset.**
- Run the cheap gates (shellcheck, questions, frontmatter, cross-refs, which take seconds) *before* bats.
- Always tee full output to `$TMPDIR/health-check-<sha>.log` and end with a summary that lists each failing check and failing test name. No one has to grep the output again.
- Add `--only <check>` and `--skip <check>`, so a shellcheck fix is re-verified in seconds.

**C3 · Remove the double runs.**
- Drop the standalone fast run before health-check. health-check already runs fast first.
- `test/scripts/health-check.bats` should exercise health-check against a fixture repo (it has the `HEALTH_CHECK_SKILLS_DIR` seam) and never re-run the real repo's gates. Then a real gate failure appears once, not once plus three nested test failures.

**C4 · Gate on a frozen snapshot and cache green by tree hash.**
- Run the final health-check in a detached worktree at the commit being merged. Edits to the live tree mid-run (failure D) then can't affect it.
- Record `<tree-sha> green` on success. A merge whose result tree equals an already-green tree (a fast-forward, or a merge of an item that was gated on a `main`-rebased branch) skips the re-run.

**C5 · Classify failures before re-running anything.** On red, re-run just the failing tests once, alone, with C1's `--failed`:
- Passes alone → *environmental*: print the offending processes and stop.
- Fails alone → *real*: fix it.
- Fails on `main` too → *pre-existing*: `tap_new_failures` in `si-functions.sh` already does this baseline diff for the self-improvement loop.

This is pr-prep 5a's triage table, made mechanical.

**C6 · Quiesce agents before the gate.**
- Add a pre-gate step: no subagent is running, and `pgrep -u "$(id -u)" -a` shows no leftover `sleep`, `cat <fifo>` or probe processes started under the scratchpad or a worktree.
- Tell review agents that build adversarial probes to run them under `timeout` and to reap them before reporting.

Also make install-host's failure message name the blocking PID and command line, if it doesn't already, so the environmental class is diagnosable from one run. *Don't* add a test seam that can switch off install.sh's `/proc` guard: it is an enforcement file, and a disable switch is worse than a flaky test. Separately, installing GNU `parallel` in the image (C1 `--jobs`) is a `you: terminal`/image change.

**C7 · Pin the locale in the runner, not per suite.** `main` at 2bf5979 fails 5 tests in a shell whose `LC_ALL=en_US.UTF-8` is not installed:
- cc-isolated-functions: "planted at the checkout root", "HEAD over 255 bytes";
- `gitdir_valid` "stricter than git";
- cc-push `err_vis`;
- install-host T3.

bash's setlocale warning lands inside captured `$output`. All 5 pass under `LC_ALL=C.UTF-8`. This is the Q-076 rubric's D6, "environmental", and it makes a clean tree look red. `test/lib/hermetic-env` already has `pin_hermetic_locale`, but only the suites that call it are covered. `run-tests.sh` should export `LC_ALL=C.UTF-8` (falling back to `C`) when `locale -a` lacks the ambient locale, so every suite inherits it.

### D. Decisions

**D1 · Default the mechanical decisions in /away.** Split-at-cap and split-at-trigger (A2) default to *split* and go into `questions.md` with an interim. Only design choices (the tripwire vs. key-list question) block. That would have removed the 61-min wait and kept the 24-min design wait, which was a real judgment.

## Suggested order

| # | Change | Cost | Saves (this run) |
|---|---|---|---|
| 1 | C7 locale pin + C1 `--failed` / `FILE...` + C2 fail-fast/log/summary + C3 drop double fast run | small, scripts + tests | ~30–40 min |
| 2 | A1 + A2 + D1 (doc changes to parallel-worktrees, review-fix-loop, pr-prep) | small, docs | ~2–3h |
| 3 | C6 quiesce step + C5 classify-on-red | small | ~30 min + no misdiagnosis |
| 4 | B1 `--since` range + B2 replicate policy + B3 early critics | medium, code-review skill | ~1h per multi-round loop |
| 5 | A3 design probe + A4 size budget | medium, workflow design | the scope-churn hours; hardest to estimate |
| 6 | C4 snapshot + tree-hash green cache; C3 fixture-only health-check.bats | medium | ~7–9 min per repeated gate |

## Open questions for the user

1. A1 reverses a documented anti-pattern ("per-item review fragmentation"). Is per-item review→merge the new default, or only when one item dominates the findings (A2 alone)?
2. A4's size budget: is ~600 changed code lines per unit the right number, and should the budget apply only to enforcement files?
3. Where to start: order row 1 (test tooling) is self-contained and could be implemented now.

## Measurements

Full suite on `main` 2bf5979: `bats -T` on all 122 files, serial, 2026-09-28. Machine: 16 cores, bats 1.8.2, no GNU `parallel`.

- **Totals:** 2,129 tests in **742 s wall** (12.4 min). The per-test times sum to 10.1 min.
- **Where the time goes:** the slowest 100 tests are 60% of it (6.1 min).
- **Nested health-check tests** (C3): the two slowest tests are `test/scripts/health-check.bats` running health-check nested, at 54.6 s and 48.9 s. Next is install-host T38 at 9.2 s. Then the hermeticity scans (`fixture-hermeticity.bats`) at ~8 s each.
- **Failures:** 5, all locale (C7). Each passes alone under `C.UTF-8`.
- **`--jobs` estimate:** 16-way parallelism with suite-level `--jobs` would be bounded by the slowest single suite (install-host), not the sum. That estimate is unmeasured; measure it once `parallel` is in the image.
