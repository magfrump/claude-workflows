# Performance Review — branch skill-fixtures (Q-062 [2], Q-063 [1]), iteration 2

Commit: d8c43ae
**Scope:** `git diff main...HEAD`, focused on what the iteration-1 fix commit 8664e22 changed: `split_mode1` in `test/skills/arithmetic-eval/mode1-equiv.py`, `assert_no_tool_called` in `test/skills/eval-helpers.bash`, the tripwire in `test/skills/generate-reports.bash` (it now also runs on failed runs), the `CW_SEEN`/`ENVIRON` awk in `devcontainer-config/install.sh` `agent_gate`, and the `VERDICT_RE` and computed-figure greps in `test/skills/arithmetic-eval-eval.bats`.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (commit d8c43ae; Claims 7, 21, 28, 32 used here). I also took my own timings in the review sandbox: 16 CPUs, `/proc/loadavg` 3.85, GNU grep 3.8. They are supporting context only.

C3 and C4 (the per-process forks in `procs_in_checkout`, and the unstubbed /proc scan in install-host.bats) are still open by choice, and this review does not repeat them.

## Data Flow and Hot Paths

Every path 8664e22 touched is **cold**:

- **`split_mode1`** runs once on SKILL.md's block (in `reference()`) and once for each Bash call in a transcript. That is once per `mode1_equiv:` check, which means once per fixture, and a fixture holds a handful of calls. Each input is a single model-written command, capped by the model's output length (a few KB normally, at most a few hundred KB).
- **`assert_no_tool_called`** runs one `jq` pass and one `grep` over a single transcript's tool inputs, once per fixture that has the check. Today that is only `tc-ae5` (`no_tool_called:Bash`).
- **The tripwire `jq`** runs once per deny-record fixture run, after a `claude -p` call that takes tens of seconds. It now also runs on failed runs, which adds one pass over the transcript on the failure path. The success path pays the same as before.
- **The `CW_SEEN` awk** runs once per `agent_gate` call, so at most 4 times per install. Its input is the `pgrep -af` output for Claude processes and the list of processes in the checkout.
- **`VERDICT_RE` and the figure EREs** are single `grep -iE` passes over one report held in `$REPORT_CONTENT`, and they run only when `AE_GRADE_AFTER_DENIAL=1`. Otherwise `after_denial` skips before it loads anything.

## Findings

No findings.

I looked at each item the brief named and found nothing a performance finding could rest on. These are the measurements and reads behind that:

- **`split_mode1` vs the old `WRAPPER_RE`.** The new code does the following, in order: one anchored `HEAD_RE.match`, one `str.split("\n")` of the remainder, one membership test (`"EXPREOF" not in lines`) plus `lines.index`, and one `TAIL_LINE_RE.fullmatch` per line after the terminator. The membership test and `index` scan the list twice, and the split copies the command once. Both costs are constant factors on a linear pass. I timed both versions on adversarial inputs of 200–400 KB. The new code was never slower: 0.13–2.8 ms against 1.35–5.5 ms, and on a 100k-line comment tail 20 ms against 54 ms. Both grow linearly. `HEAD_RE`'s `[^']*` can only backtrack within the text up to the first quote, and `\A` anchors it, so it stays O(n) (2.5 ms on an unterminated 400 KB program).
- **`assert_no_tool_called` now uses `grep -iE "$pattern"`, with `.` as the default, instead of `grep -c .`.** Its hits go into a shell variable and are counted a second time with `grep -c .` only on failure. That second count is one extra pass over data the function already holds, so the cost does not change.
- **The tripwire on failed runs.** It is one extra `jq` pass on the failure path only. Its O(Bash calls × denials) `index` check was endorsed in iteration 1, and both counts are single digits.
- **`CW_SEEN` through `ENVIRON` vs `awk -v`.** The size limit is the same. I checked it: a 140,000-byte value failed with "argument list too long" both ways, and 131,000 bytes worked both ways. That is the kernel's per-string `MAX_ARG_STRLEN` limit (128 KiB). Reaching it would take `pgrep -af` output over 128 KiB, meaning hundreds of Claude processes. Even then `$procs` is non-empty, `set -euo pipefail` (`install.sh:26`) exits on the failed substitution, and the install is refused anyway. Nothing got worse.
- **`VERDICT_RE` and the figure EREs.** I timed them with GNU grep 3.8 over 10 runs each: about 1 ms per call for both the old and the new `VERDICT_RE`, on inputs from empty to a 53 KB, 400-line report. The patterns have no back-references, and the only bounded repeat is `[^a-z]{0,6}`, so grep's DFA takes them without trouble. (The unchanged `NOT_VERIFIED_RE` with `[^.]{0,80}` also measured a few ms.)

One point carried over from iteration 1: perf F3(a), which noted that `evaluate()` runs without SKILL.md's `ulimit -t 5 -v 1000000`, was folded into A10. A10 fixed the `TimeoutExpired` half and did not add the limits. I am not re-filing it. SKILL.md's evaluator checks the size of every intermediate result against `MAX_BITS`, and it predicts `Pow` sizes before computing them, so memory stays bounded without the ulimit. The remaining gap is a CPU bound of 10 s here against SKILL.md's 5 s, which is not a performance concern.

## Endorsements (evidence-gated)

- `split_mode1` is linear in the command's length, and on every adversarial shape I tried (20k repeated `EXPREOF` lines, a 100k-line comment tail, a 400 KB unterminated program, a 100k-term expression) it matched or failed in at most 20 ms, never slower than the regex it replaced. `[unverified — submitted as claim]`
- `split_mode1` and bash agree on where the heredoc ends in the seven edge cases the fact-check probed, so the speedup costs nothing in correctness. `[fact-check: claim 21 — Verified]`
- Moving `$procs` from `awk -v` to `ENVIRON["CW_SEEN"]` stops escape expansion without changing the de-duplication. `[fact-check: claim 7 — Verified]` The size limit is unchanged (the E2BIG threshold is the same for both forms, and the install is still refused past it). `[unverified — submitted as claim]`
- The tripwire now runs outside the `if [ -z "$failure" ]` guard and adds its message to an existing failure. That costs one `jq` pass, and only on the failure path. `[fact-check: claim 32 — Verified]`
- `after_denial` checks `AE_GRADE_AFTER_DENIAL` before `load_eval_report`, so default runs pay nothing for the four opt-in tests. `[read: test/skills/arithmetic-eval-eval.bats:50-60]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings | — | — | — |

## Overall Assessment

For performance, iteration 1's fixes are neutral to slightly positive. The one algorithmic change, replacing `WRAPPER_RE`'s lazy `.*?` and repeated tail group with a split followed by a line scan, measured faster on every adversarial input. It is linear, and the fact-check confirmed it agrees with bash. The rest adds constant work on cold paths: one extra `jq` pass on failed fixture runs, and one `grep` over a single transcript or report. The awk change leaves the size limit where it was. Nothing here needs profiling. C3 and C4 are still the only size-dependent costs on the branch, and they are open by choice.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** This is a performance review of the whole `main...HEAD` changeset at d8c43ae, focused on 8664e22. It covers each item the brief named: `split_mode1` (timed against the old regex), `assert_no_tool_called`'s grep, the tripwire on failed runs, the `CW_SEEN`/`ENVIRON` awk (the size limit was probed), and `VERDICT_RE` with the figure greps (timed). I found no performance findings, and I list five evidence-gated endorsements.
- **Out of scope:** C3 and C4 (not repeated), the Claim 25b exit-code issue (with the orchestrator), and the Claim 2 /proc wording (with security). I ran no `claude` or network commands and committed nothing.
- **Escalate (correctness, outside the performance lane; for api-consistency or the orchestrator):** A5 introduced a fail-open in `assert_no_tool_called`. `test/skills/eval-helpers.bash:408-417` runs `hits="$(transcript_tool_inputs "$t" "$tool" | grep -iE "$pattern" || true)"`. If the ERE is invalid (for example `(`) or begins with `-` (for example `-rf` or `--force`), grep exits 2 and prints nothing. `|| true` swallows that, `hits` stays empty, and the negative assertion **passes**. I reproduced this in the sandbox: an input containing `rm -rf / --force (` gave empty hits for the patterns `(`, `-rf` and `--force`, and a hit for `rm -rf`. The old `grep -c .` used a constant pattern, so it could not fail this way. The only current use is `no_tool_called:Bash`, which has no ERE, so the problem is latent. A possible fix is `grep -iE -e "$pattern"` plus treating grep's exit status 2 as a failed check. Confidence: High (the probe was run). Legibility-target: for-orchestrator-synthesis.
- **Questions:** None.
- **Decisions:** I did not re-file perf F3(a), the ulimit gap in `evaluate()`. The rubric folded it into A10, and SKILL.md's `MAX_BITS` checks keep memory bounded without it.
