Commit: f47de85 (A) / cb2e5f9 (B)

# Performance Review — dev-cycle pass 15 (pass-14 fix round, k=1)

**Scope:** Partial. A: `git diff 096042b..f47de85 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` (commits f920f0d, f47de85), in `/workspace/.claude/wt-digest`. B: `git diff 374d559..cb2e5f9 -- skills/dev-cycle/SKILL.md`, in `/workspace/.claude/wt-devcycle`. Everything else on both branches is context only.
**Date:** 2026-10-01
**Based on:** `docs/reviews/code-fact-check-report-digest-pass14.md` (Stage-1 context named in the brief. It covers the pass-13 round at 096042b, not this round's diff, so no claim in it is an execution verdict on the lines under review here.)

Scratch: `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/perf15/` (`perf15/` below).
- `bats.log`: `timeout 600 bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest` (scripts/ and test/ identical to f47de85, `git diff --stat f47de85 HEAD -- scripts test` empty), 2026-10-02T06:34:12Z, exit 0, 23/23 ok, 6.345 s wall.
- `probe.log` (script `perf15/probe.sh`): `timeout 300 ./probe.sh`, 2026-10-02T06:34:27Z, exit 0. Throwaway repo under `mktemp -d`, removed on exit. Measures (a) `realpath -e` calls in section 3 under `bash -x` with questions.md and the archive both plain and `scripts/questions.sh` present, (b) the mean wall time of 20 full digest runs, (c) section 3 with a symlinked archive.

Legibility-target values: **maintainer** (someone editing the script or tests), **agent** (the model running the skill), **user** (the human reading the digest).

## Data Flow and Hot Paths

A: `dev-cycle.sh` runs once per dev cycle, by hand or by an agent following the skill. It runs at most a handful of times per cycle (the skill reruns it with `--since` in some branches). Every path in this diff is **cold**: section 2's summary line is one `echo` after the decision-record loop. Section 3 is a fixed sequence of at most three `blocker` walks over two fixed paths of depth 3, then at most one `questions.sh open` fork. Nothing in the diff runs inside a loop over user-scale data. Measured: one full digest takes a mean of 60 ms on a near-empty repo (`perf15/probe.log`, 20 runs).

B: the In-flight rule runs once per cycle for each item with an open build brief. That is bounded by what the user put in flight (in practice a handful). Step 2 searches `questions.md` and `questions-archive.md` for one question string per brief. The archive grows without bound over the project's life, but a text search over it is linear and is done by the agent with a search tool, not by reading it whole.

## Findings

#### Section 3 walks questions.md's path up to three times per run (one more than before)

**Severity:** Informational
**Location:** `scripts/dev-cycle.sh:249-254` (A, f47de85)
**Evidence (verbatim):** `if skipped docs/working/questions.md; then` / `elif inrepo docs/working/questions.md && [[ -f "$QS" ]] && skipped "$QA"; then` / `elif inrepo docs/working/questions.md && [[ -f "$QS" ]]; then` (the chain continues to `:272-274`, `else` / `echo "No docs/working/questions.md (or questions.sh) in this repo."` / `fi`)
**Move:** Hidden multiplication
**Classification:** Micro (repeated path walk, fixed cost) / Cold path (once per digest run)
**Confidence:** High
**Baseline:** 12 `realpath -e` calls in section 3 and a 60 ms mean full-digest run, measured in `perf15/probe.log` (2026-10-02T06:34:27Z)
**Legibility-target:** maintainer

When questions.md and the archive are both plain and questions.sh exists, the chain runs `blocker` on questions.md three times (once in `skipped`, once in each `inrepo`) and on the archive once. Each walk is a command-substitution subshell plus one `realpath` fork per path component. That is the 12 `realpath` calls measured. The pass-13 chain walked questions.md twice, so this round adds about one subshell and three forks, a few milliseconds of a 60 ms run. The paths are fixed and depth 3, so the cost cannot grow with repo size. Not worth changing. Noted only because the repeated `inrepo docs/working/questions.md && [[ -f "$QS" ]]` guard is also the thing a maintainer has to keep in sync across two branches.

**Recommendation:** None needed for performance. If the chain is touched again for clarity, one `qok` variable computed once (`inrepo … && [[ -f "$QS" ]]`) removes the duplicate walk and the duplicated guard together.

#### Test 10 gains one full digest run

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:220-226` (A, f47de85)
**Evidence (verbatim):** `printf '# 002\n\nno triggers here\n' > docs/decisions/002-none.md` / `rm docs/decisions/001-plain.md` / `run --separate-stderr bash "$DC"` (the unit continues to `:227`, the section-2 assertion and `}`)
**Move:** Hidden multiplication
**Classification:** Micro / Cold (test suite)
**Confidence:** High
**Baseline:** 6.345 s wall for the 23-test suite, measured in `perf15/bats.log` (2026-10-02T06:34:12Z); one digest run measured at 60 ms mean in `perf15/probe.log`
**Legibility-target:** maintainer

The new mixed read/skipped case reuses test 10's repo and adds one `run`, about 1% of the suite's wall time. That is the cheapest way to cover the case (no new `make_repo`). No action.

**Recommendation:** None.

No finding at Low or above. B adds no executable code, and its only scaling-relevant text (step 2's search of the archive) is the bounded pattern already endorsed below.

## Endorsements (evidence-gated)

- B, step 2 bounds each answer to one application: an answer applies only if "dated after the brief's last `Kept:` date (no `Kept:` yet: on or after the brief's own date) and not after today". So a `keep` answer that stays searchable in the growing archive cannot append a new `Kept:` line every cycle, and the brief does not grow cycle over cycle. [read: /workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:225-233]
- B, step 2 keeps the per-cycle cost of the archive to a search, not a whole read: "Find answers by searching `questions.md` and `questions-archive.md` for that question … not by reading the archive whole." [read: /workspace/.claude/wt-devcycle/skills/dev-cycle/SKILL.md:228-230]
- B, step 0's new guard ("unless an open one already reports them") and step 3's "and no such question is open" mean repeated cycles under the same condition do not add a new entry to questions.md each cycle. The text says so; whether an agent applies it reliably is not something this read can establish. [unverified — submitted as claim]
- A, section 3: with a symlinked archive, `questions.sh` is not forked at all; the banner prints instead. [read: /workspace/.claude/wt-digest/scripts/dev-cycle.sh:252-256] (also seen in `perf15/probe.log` case (c), whose section 3 holds only the banner)
- A, section 2's new summary line is a constant `echo` that reuses the `SKIPPED` count already computed for the "Not read:" list. It adds no work to the record loop. [read: /workspace/.claude/wt-digest/scripts/dev-cycle.sh:229-240]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Section 3 walks questions.md's path up to three times (one more than pass 13) | Informational | `scripts/dev-cycle.sh:249-254` | High |
| 2 | Test 10 gains one digest run (~1% of suite time) | Informational | `test/scripts/dev-cycle.bats:220-226` | High |

## Overall Assessment

This round's changes have no performance problems. Every path in A is cold and of fixed size: one digest run per cycle at about 60 ms measured, and the diff's added cost is a handful of forks. B is prose. Its one scaling-relevant rule, the answer search over an archive that grows without bound, is bounded per brief and protected against re-application by step 2's date bounds. The two Informational notes need no action. The rules I checked for hidden multiplication, unbounded growth and wasted forks (section 2's summary, section 3's five-way chain, B's steps 0, 2 and 3) are correct for this lens and complete within it. No profiling is needed.

## Goal-Alignment Note

Success criterion (verbatim): "a markdown report saved at the path your role instructions give, structured per your skill file." This report is saved at `/workspace/.claude/wt-digest/docs/reviews/performance-review-2026-10-01-digest-pass15.md` and follows the skill's structure (header, Data Flow, Findings with Baseline, Endorsements with evidence tags, Summary Table, Overall Assessment). It also carries the per-finding Location / Evidence / Confidence / Legibility-target the brief asked for. It serves the user goal (merge both branches once a clean pass is reached) by adding no blocking finding from the performance lens for this round.
