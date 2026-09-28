Commit: ed28f76

# Performance Review — review/q086 (Q-086, final confirming pass)

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-q086` (full branch; code part is `devcontainer-config/Dockerfile`: 3 header-comment lines at :4-6 and `parallel \` at :43), plus commit messages 1ef3090, 577bef7, ed28f76
**Date:** 2026-09-28
**Based on:** `docs/reviews/q086-code-fact-check-report-final.md` (k=1, final pass); iteration-1 report `docs/reviews/q086-performance-review-2026-09-28.md` read for context only

## Data Flow and Hot Paths

The change adds the Debian package `parallel` to the image's first apt RUN (`Dockerfile:22-46`) and documents it in the header's "Local changes" list (`Dockerfile:1-9`). There is no runtime code: no loops, queries, caches or allocations.

- **Image build (cold).** Runs once per rebuild after an install.sh re-bless. The RUN-text edit busts the cache for `:22` onward. The header comment is not an instruction, so it adds no layer and no RUN cache key. It does change the file hash baked in at `ARG CC_CONFIG_HASH` (`:484`), but any Dockerfile edit does that, and the RUN edit already invalidates everything after `:22`.
- **Test-suite wall time (the premise, hot for Q-090 only).** The package enables across-file `bats --jobs N` for Q-090. The baseline is 742 s wall, serial full suite (iteration-1 report, citing `docs/working/proposal-2026-09-27-smaller-review-units.md:109-111`). Nothing in this diff runs `--jobs`, so nothing here is on a hot path yet.

Iteration 1 → final delta: ed28f76 and 577bef7 changed only the header comment and review artifacts. The package line is byte-identical to 1ef3090 apart from its line number (`:40` → `:43`), per `git diff 1ef3090 HEAD -- devcontainer-config/Dockerfile`, which shows only the three added comment lines.

## Findings

No findings.

All three iteration-1 findings are settled and nothing new was found:
- iter-1 #3 (base-layer cache invalidation) = override C4, Won't fix. I re-checked the rationale at ed28f76. The claude-code layer still floats (`Dockerfile:19` `ARG CLAUDE_CODE_VERSION=latest`, `:403` `RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`; `devcontainer.json:29` `"CLAUDE_CODE_VERSION": "latest"`), so the prior call stands. The only change is that the line is now `:43`, which the C4 row already cites.
- iter-1 #1 and #2 (within-file semaphore parallelism; install-host `/proc` scan under concurrency) = override C5, deferred to Q-090. No new evidence.

## Coverage notes (not findings)

- **New fact-check edge, relevant to Q-090 rather than this diff.** Fact-check Claim 1a found that `bats --jobs 2` on a *single* file also aborts without `parallel` (probe `docs/reviews/execution-logs/q086-bats-jobs-probe-final.log`). This is a correctness or usability point for Q-090's `run-tests.sh <files>` and `--failed` paths, not a performance cost. With `parallel` installed, a one-file `--jobs` run goes through a one-item `parallel` fan-out, which adds process startup cost only (no baseline available — flagged as speculative). Legibility-target: for-orchestrator-synthesis.
- The package's installed size and its Depends (e.g. `sysstat`) are still unverified offline. This is settled as C1/C3 and is a host check at rebuild. Legibility-target: for-orchestrator-synthesis.

## Endorsements

- The added package goes through the same RUN's `--no-install-recommends` and `apt-get clean && rm -rf /var/lib/apt/lists/*`, so this edit adds no apt index and no Recommends to the layer. `[read: devcontainer-config/Dockerfile:22-46]`
- The header comment adds no image layer and no RUN cache key. Only the RUN edit determines the cache miss. `[fact-check: claim 11 — Mostly accurate (settled B1; the "no layer" part is the accurate portion)]`
- Without `parallel`, `bats --jobs N>1` aborts in bats 1.8.2 unless `--no-parallelize-across-files` is given, so the package is a real prerequisite for Q-090's speedup lever. `[fact-check: claim 1a — Verified (executed)]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| — | No findings (iter-1 items settled as C4, C5) | — | — | — |

## Overall Assessment

From a performance standpoint the branch is clean at ed28f76. The only direct cost is a one-off, cold-path rebuild from `Dockerfile:22` onward, which is accepted as C4. The fixes since iteration 1 are comment-only and add no build or runtime cost. The open performance questions (within-file semaphore parallelism, install-host flake risk, the unparallelized `bats --count` step, and the actual speedup against the 742 s baseline) belong to Q-090 and need a measured `--jobs` run in the rebuilt image. Nothing needs profiling before this item merges.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-q086/docs/reviews/q086-performance-review-2026-09-28-final.md, structured per the performance-reviewer skill.
- Answered: yes
- Out of scope: image build and rebuild timing (no Docker, no egress); any `--jobs` suite run (`parallel` not installed; Q-090 not in this diff); the 1ef3090/bb9982f duplicate-commit escalation (already with the user).
- Escalate: nothing for this branch. For the Q-090 entry: the single-file `--jobs` abort (fact-check Claim 1a) should sit next to the C5 notes.
- Decisions I made: I did not re-file C4 or C5, because a re-check at ed28f76 found no new evidence. I put the single-file `--jobs` edge under coverage notes rather than findings because it has no performance cost in this diff.
