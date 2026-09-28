Commit: 1ef3090

# Code Review Rubric

<!-- Canonical name per SKILL.md would be code-review-rubric-2026-09-28-review-q086.md; prefixed with the item slug per the 2026-09-28 shared brief to avoid merge collisions. -->

**Scope:** `review/q086` vs `main` (full branch, `git diff main...HEAD`, iteration 1, `--loop-pass`) | **Reviewed:** 2026-09-28 | **Status: 🟡 CONDITIONAL PASS** — 0 red; 2 amber items, both resolved in this iteration (A1 fixed, A2 acknowledged) — confirming pass pending

Pass notes: fact-check k=1 (loop pass, decision 031, model opus); critics on opus; delivery mode: inline-diff-only (diff + commit message inlined, Dockerfile self-read). Skill texts were handed to sub-agents by path (read in full from the worktree) rather than pasted.

---

## 🔴 Must Fix

No items.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Dockerfile header "Local changes" list (`devcontainer-config/Dockerfile:1-6`) does not record the new `parallel` package; it is the only local addition with no rationale anywhere in the file. Convergence: fact-check (Stale) + security-reviewer (Informational) + dependency-upgrade D1 (advisory). | Docs / enforcement-file hygiene | Stale | Fact-check | for-author | — | Fixed | Header line added naming Q-086 and why (`bats --jobs N>1`; bats only Recommends parallel, image installs with --no-install-recommends). |
| A2 | Commit 1ef3090 message: "bats --jobs needs GNU parallel" is imprecise — `--jobs 1` and `--jobs N --no-parallelize-across-files` run without it; only `--jobs N>1` across files aborts (executed: `docs/reviews/execution-logs/q086-bats-jobs-probe.log`). | Docs | Mostly Accurate | Fact-check | for-author | — | Acknowledged | Not rewriting the reviewed commit (would change its sha under the parallel merge). The precise wording now lives in the Dockerfile header; override-log row added. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Package-version claims in the commit Notes (user's 20210822 = Ubuntu 22.04's; bookworm ships 20221122) are unverifiable offline. Host check: `docker run --rm debian:bookworm sh -c 'apt-get update -qq && apt-cache policy parallel'`, or `parallel --version` in the rebuilt image. | Fact-check (Unverifiable) | Unverifiable | for-author | — | Deferred |
| C2 | bats runs `parallel ... 2>&1` with no `--will-cite` (`bats-exec-suite:420`), so a citation notice or Perl locale warnings would land in test output; `run-tests.sh` already pins `C.UTF-8` when the locale is missing, a bare `bats --jobs` does not. | dependency-upgrade D3 + fact-check | Low | for-author | — | Deferred (Q-090) |
| C3 | Debian `parallel` may hard-depend on `sysstat` (not blocked by --no-install-recommends); likely inert (no cron/init in image). Check at rebuild: `apt-cache depends parallel`, setuid scan vs baseline in the security report. | security-reviewer | Informational | for-author | — | Deferred |
| C4 | Editing the first apt RUN invalidates every later layer (git-delta, uv, JDK, Android SDK, Rust, `claude-code@latest`…) on the next build; one-off cold-path cost. | performance-reviewer | Low | for-author | — | Won't-Fix |
| C5 | For Q-090: `bats --jobs N` in 1.8.2 also parallelises within files (`bats-exec-file:294-296`); `install.sh` `procs_in_checkout` reads real `/proc` and may make `install-host.bats` flake under concurrency. Start with `--no-parallelize-within-files`. | performance-reviewer | Informational | for-author | — | Deferred (Q-090) |
| C6 | Header "Local changes" list was already missing earlier additions (dnsmasq-base #40, uv #18, poppler-utils, JDK/SDK #19, Rust #21). Pre-existing. | Fact-check (Stale, pre-existing part) | Stale | for-author | — | Deferred |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Without parallel, bats 1.8.2 `--jobs 2` aborts and `--jobs 1` runs, so the package is what the planned `--jobs` needs | ✅ Confirmed | `/usr/libexec/bats-core/bats-exec-suite:100-101` — "Cannot execute \"${num_jobs}\" jobs without GNU parallel"; FC claim 2 (executed, `execution-logs/q086-bats-jobs-probe.log`) | code-fact-check | for-orchestrator-synthesis |
| Live-verified trailer's mechanism: Dockerfile is an enforcement file, shipped by install.sh, and a changed blessed hash rebuilds the container | ✅ Confirmed | `hooks/live-verify-gate.sh:73` enforcement regex includes `Dockerfile`; FC claim 9 (static; scope covers enforcement set, re-bless and hash-triggered rebuild — not whether the apt layer cache is reused) | code-fact-check | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| api-consistency-reviewer | No public API surface touched | Diff is one apt package name in `devcontainer-config/Dockerfile`; no exported symbol, schema, route, CLI flag or config key; no fact-check claim in the domain |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `devcontainer-config/Dockerfile:1-6` + `:40` | A1 (FC), security Info #1, dependency D1 | distinct defects: every fragment states the same complete finding (missing rationale); nothing new composes |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

## Escalations (orchestrator, not tiered)

- **Duplicate commit identity.** 1ef3090 (this branch) and bb9982f (on `answers-2026-09-28`) carry the same subject and diff. Commit 48bca90 on `answers-2026-09-28` cites bb9982f as the commit that adds parallel. If this branch is what lands on main, those references point at a commit not on main. Needs a decision at merge time (caller/user).
- **Q-090 absent from this base.** The follow-up the commit promises exists only on `answers-2026-09-28`; C2/C5 should be attached to it there.
