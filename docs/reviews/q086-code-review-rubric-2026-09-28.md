Commit: ed28f76
Loop closed at ed28f76

# Code Review Rubric

<!-- Canonical name per SKILL.md would be code-review-rubric-2026-09-28-review-q086.md; prefixed with the item slug per the 2026-09-28 shared brief to avoid merge collisions. -->

**Scope:** `review/q086` vs `main`, full branch (`git diff main...HEAD`), iteration 3 of 3 = final confirming pass (no `--loop-pass`) | **Reviewed:** 2026-09-28 | **Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation

Pass log:
- **Iteration 1** (`--loop-pass`, full branch at 1ef3090): fact-check k=1 (`q086-code-fact-check-report.md`, 11 claims, 0 Incorrect); critics security, performance, dependency-upgrade; api-consistency gated off. Found A1-A2, C1-C6. Fixed in 577bef7.
- **Iteration 2** (`--loop-pass`, range `1ef3090..577bef7`): fact-check k=1 on the delta (`q086-code-fact-check-report-iter2.md`, 16 claims, 0 Incorrect); all critics gated off on the comment-only delta. Found B1-B3. Fixed in ed28f76. It also found that the iteration-1 probe log prints `exit=0` after the `--jobs 2` abort while its summary says exit 1; the iteration-2 and final logs show exit 1 and supersede it.
- **Iteration 3** (final confirming pass, full branch at ed28f76): fact-check k=1 per this worktree's SKILL.md (`q086-code-fact-check-report-final.md`, claims 1-20 plus Stage-2.5 claims 21-22; 0 Incorrect, 0 Stale); critics security, performance, dependency-upgrade on opus (0 findings each; `*-final.md`); Stage 2.5 verdicted 2 routed security endorsements (21 Verified, 22 Mostly accurate). No new finding on the branch's code or commits. Its two rubric-citation slips (FC claims 16, 20) are corrected in this file.
- All passes: models opus; delivery mode inline-diff-only (diff and commit messages inlined, Dockerfile self-read). Skill texts were handed to sub-agents by path (read in full from the worktree) rather than pasted.

---

## 🔴 Must Fix

No items.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Dockerfile header "Local changes" list (`devcontainer-config/Dockerfile:1-9`) did not record the new `parallel` package (at `:43`); it was the only local addition with no rationale in the file. Convergence: fact-check (Stale) + security-reviewer (Informational) + dependency-upgrade D1 (advisory). | Docs / enforcement-file hygiene | Stale | Fact-check | for-author | — | Fixed (577bef7) | Header entry at `:4-6`; all three clauses Verified in the final fact-check (claims 1a-1c). |
| A2 | Commit 1ef3090 message: "bats --jobs needs GNU parallel" is imprecise. `--jobs 1` and `--jobs 2 --no-parallelize-across-files` run without it; `--jobs 2` aborts, on a single file too. | Docs | Mostly Accurate | Fact-check | for-author | override-log `review/q086` A2 | Acknowledged | Commit not rewritten (would change the reviewed sha). The precise wording is in the Dockerfile header. Revisit trigger: if 1ef3090 is re-created at merge (e.g. resolving the bb9982f duplicate in Escalations), correct the wording then. |
| B1 | Commit 577bef7's Live-verified trailer says the build is "unchanged apart from the layer text"; a `#` comment enters no layer or cache key. | Docs | Mostly Accurate | Fact-check (iter 2) | for-author | override-log `review/q086` B1 | Acknowledged | Commit not rewritten; it overstates the change and hides nothing. Revisit trigger: same as A2 — if the branch's commits are re-created at merge, correct the trailer then. |
| B2 | Override-log row C3 cited `Dockerfile:19-46`; the base apt RUN is `:22-46`. | Docs | Mostly Accurate | Fact-check (iter 2) | for-author | — | Fixed (ed28f76) | |
| B3 | Override-log row C6 cited `Dockerfile:1-6`, the pre-fix header; now `:1-9`. | Docs | Stale | Fact-check (iter 2) | for-author | — | Fixed (ed28f76) | |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Package-version claims in 1ef3090's Notes (user's 20210822 = Ubuntu 22.04's; bookworm ships 20221122) are unverifiable offline. Host check: `docker run --rm debian:bookworm sh -c 'apt-get update -qq && apt-cache policy parallel'`, or `parallel --version` in the rebuilt image. | Fact-check (Unverifiable) | Unverifiable | for-author | override-log C1 | Deferred |
| C2 | bats runs `parallel ... 2>&1` with no `--will-cite` (`bats-exec-suite:420`), so a citation notice or Perl locale warnings would land in test output. `run-tests.sh` pins `C.UTF-8` when the locale is missing; a bare `bats --jobs` does not. | dependency-upgrade D3 + fact-check | Low | for-author | override-log C2 | Deferred (Q-090) |
| C3 | Debian `parallel` may hard-depend on `sysstat` (not blocked by --no-install-recommends); likely inert with no cron/init in the image. Check at rebuild: `apt-cache depends parallel`; compare `find / -xdev -perm /6000 -type f` with the baseline in `q086-security-review-2026-09-28.md`. | security-reviewer | Informational | for-author | override-log C3 | Deferred |
| C4 | Editing the first apt RUN invalidates every later layer (git-delta, uv, JDK, Android SDK, Rust, `claude-code@latest`…) on the next build; one-off cold-path cost. | performance-reviewer | Low | for-author | override-log C4 | Won't-Fix |
| C5 | For Q-090: `bats --jobs N` in 1.8.2 also parallelises within files (`bats-exec-file:294-296`); `install.sh` `procs_in_checkout` reads the real `/proc` and may make `install-host.bats` flake under concurrency. Start with `--no-parallelize-within-files`. Final pass adds: `--jobs 2` aborts without parallel even on one file, so Q-090's fallback must test for `parallel`, not the file count. | performance-reviewer (+ final FC claim 1a) | Informational | for-author | override-log C5 | Deferred (Q-090) |
| C6 | Header "Local changes" list was already missing earlier additions (dnsmasq-base #40, uv #18, poppler-utils, JDK/SDK #19, Rust #21). Pre-existing. | Fact-check (Stale, pre-existing part) | Stale | for-author | override-log C6 | Deferred |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `review/q086` / 2026-09-28 | A2, B1, C1-C6 (rows written by iterations 1-2 of this loop) | 🟡/🟢 → Won't-Fix / Defer | See each row in `docs/reviews/override-log.md` | Inherited; the final-pass critics were told they were settled and found no new evidence on any. |

No prior override from before this loop matched this diff.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Without parallel, bats 1.8.2 `--jobs 2` aborts and `--jobs 1` runs, so the package is what the planned `--jobs` needs | ✅ Confirmed | `/usr/libexec/bats-core/bats-exec-suite:100-101` — "Cannot execute \"${num_jobs}\" jobs without GNU parallel"; final FC claim 1a (executed, `execution-logs/q086-bats-jobs-probe-final.log`) | code-fact-check | for-orchestrator-synthesis |
| Live-verified trailer mechanism: Dockerfile is an enforcement file, shipped by install.sh, and a changed blessed hash rebuilds the container | ✅ Confirmed | `hooks/live-verify-gate.sh:73` enforcement regex includes `Dockerfile`; `install.sh:110` PAYLOAD; `cc-isolated.sh:705-708` rebuild on hash mismatch. FC claim 9 (static; scope covers the three hops, not whether the apt layer cache is reused) | code-fact-check | for-orchestrator-synthesis |
| Adding `parallel` does not widen node's root path in the current image: the only sudo grant is env-reset `init-firewall.sh ""`, and no root-run script invokes `parallel`/`sem`/`niceload` | ✅ Confirmed | `Dockerfile:528` sudoers `printf`; `devcontainer.json:141` sole lifecycle command. FC claim 21 (executed: `sudo -n -l`, word-boundary grep over `devcontainer-config/`). Rebuilt image not tested. | security-reviewer endorsement, verified by code-fact-check | for-orchestrator-synthesis |

The second security endorsement (parallel adds no capability node lacks) was verdicted Mostly accurate (claim 22): process spawning, concurrency and ssh remote exec are already available (`perl`, `ssh`, `xargs`, `bash`), but reading `$PARALLEL`/`~/.parallel` config is new in kind, not in effect, since it only affects node's own runs. Narrowed to that and not promoted to ✅.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| api-consistency-reviewer | No public API surface touched (all three iterations) | Diff is one apt package name plus a header comment in `devcontainer-config/Dockerfile`; no exported symbol, schema, route, CLI flag or config key; no fact-check claim in the domain |
| security-reviewer, performance-reviewer, dependency-upgrade | Iteration 2 only: copy-only delta (3 `#` comment lines plus review artifacts); ran in iterations 1 and 3 | `git diff --stat 1ef3090..577bef7` |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `devcontainer-config/Dockerfile:1-9` + `:43` | A1 (FC), security Info #1 (iter 1), dependency D1 (iter 1) | distinct defects: every fragment states the same complete finding (missing rationale), so nothing new composes |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.

## Escalations (orchestrator, not tiered)

- **Duplicate commit identity.** 1ef3090 (this branch) and bb9982f (on `answers-2026-09-28`) have the same subject and diff. Commit 48bca90 on `answers-2026-09-28` cites bb9982f as the commit that adds parallel. If this branch is what lands on main, those references point at a commit that is not on main. Decide at merge time.
- **Q-090 is not on this base.** The follow-up the commit promises exists only on `answers-2026-09-28`. C2 and C5 (and the single-file `--jobs 2` abort) should be attached to it there.
