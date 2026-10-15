Commit: 12fcb61c
Loop-pass short-circuit: used at 12fcb61c

# Code Review Rubric

**Scope:** `22a4bb1f..12fcb61c` (docs/working/spike-cc-verify-q117.md and its embedded host script) | **Reviewed:** 2026-10-15 | **Status: 🔴 DOES NOT PASS** — 5 red item(s) unresolved (iteration 1; fixes follow in the next commit)

Iteration 1 was a `--loop-pass` run: fact-check at k=1 (opus), then the first-red short-circuit, because the fact-check confirmed behavioral reds. The security critic ran anyway, because the brief requires it. Performance and api-consistency were skipped this pass. Delivery mode: self-read (agents read the doc, the script and the code directly). Skill deviation: agents read their SKILL.md from the repo themselves instead of having it pasted in.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | Step 2's `git show … \| grep -qxF` runs under pipefail. install.sh (65,632 bytes) is larger than a pipe buffer, so SIGPIPE makes ~5% of runs refuse with a wrong reason | Correctness | Incorrect (high), behavioral | Fact-check claim 6 | `spike-q117.sh:191-194` | for-author | row 507 (merge-tree/git exit status trust): related class, inherited as a hint | 🔴 Unresolved |
| R2 | The verdict's `elif … no-rotation` overwrote an earlier `fail`, so a real Q-117 failure exited 2 ("rerun later") | Correctness | Incorrect (high), behavioral | Fact-check claim 9a | `spike-q117.sh:293-294` | for-author | — | 🔴 Unresolved |
| R3 | A planted `run-*.env` steered `--clean`: any `IMG=` was force-removed, and any `PID=` removed that project's containers and claude-config volume (reproduced) | Security | Incorrect (high) + security Medium (F4) | Fact-check claim 24b, security-reviewer F4 | `spike-q117.sh:121-135, 29-58` | for-author | — | 🔴 Unresolved |
| R4 | The step-3 gate pinned only devcontainer.json. The branch's Dockerfile could choose a base image whose `devcontainer.metadata` label grants privileged, capAdd or mounts, giving host root with no human diff | Security | Critical | security-reviewer F1 | doc:244-258 | for-author | — | 🔴 Unresolved |
| R5 | Nothing tied the run to the reviewed tree: main and the branch were resolved by name from a `.git` that cc-isolated containers can write | Security | High | security-reviewer F2 | doc:198-216 | for-author | row 509 (racing writer plants state in a gate repo): same class, inherited as a hint | 🔴 Unresolved |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | A stage edit between the step-3 gate and the launcher's bless gets blessed, and `check_manifest` then confirms it | Security | Medium | security-reviewer F3 | for-author | — | 🟡 Open | — |
| A2 | `GH_TOKEN`/`OPENROUTER_API_KEY` from the user's shell are forwarded into a container running branch code | Security | Medium | security-reviewer F6 | for-author | — | 🟡 Open | — |
| A3 | Container output reaches the terminal unfiltered: escape sequences, OSC 52, forged RESULT/CHECK lines | Security | Medium | security-reviewer F8 | for-author | — | 🟡 Open | — |
| A4 | The verdict is attested by the code under test (the branch's root-run firewall script) | Security | Medium | security-reviewer F5 | for-author | — | 🟡 Open | — |
| A5 | A leftover `VERIFY-<tree8>` has a `.git` that branch code could write | Security | Medium | security-reviewer F7 | for-author | — | 🟡 Open | — |
| A6 | The doc claims the CHECK lines prove the whole "never writes" list; they cover only main's manifests, bin links and the docker lists | Docs | Incorrect (doc) | Fact-check claim 3 | for-author | — | 🟡 Open | — |
| A7 | Step 4's `git clone`/`rev-parse` lack the hooksPath/fsmonitor flags (a global or template post-checkout hook runs) | Security / Docs | Incorrect | Fact-check claim 11b | for-author | — | 🟡 Open | — |
| A8 | In interactive zsh, the paste's trailing `# EDIT` comment became arguments, so the script refused with usage | Correctness | Mostly accurate | Fact-check claim 29 | for-author | — | 🟡 Open | — |
| A9 | Smaller inaccuracies: Ctrl-C exits 130, not 1 (9b); a script comment cites :89-94 instead of :88-93 (8); `repo_git` also passes `--no-optional-locks` (11c); the tag cleanup can remove an earlier same-tree leftover (2); "What was tested" and the commit message wording (25, 28) | Docs | Mostly accurate | Fact-check | for-author | — | 🟡 Open | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Untested gate bypasses: BuildKit `# syntax=` frontends, `RUN --network=host`, upload-pack config during `clone --no-local`, `attr.tree` merge drivers | security-reviewer (open questions) | Informational | for-author | — | 🟢 Open |
| C2 | The devcontainer CLI's image naming is unverifiable here | Fact-check claim 5 | Unverifiable | for-author | — | 🟢 Open |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u2b1a2` / 2026-10-08 (row 507) | merge-tree exit status trusted; a missing tip tree object exits 0 | 🔴 → Defer (Q-133 [3]) | landed as a known issue | Hint only. This script's clone has every object, and R1 is a different exit-status trap; not re-flagged. |
| `feat/build-loop-u2b1a2` / 2026-10-08 (row 509) | a racing same-uid writer plants a merge driver or attributes in a gate repo | 🔴 → Defer (Q-133 [3]) | landed as a known issue | Same class as R5 and the git-config residual; recorded as a residual in the doc. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Main's launcher loads host code only from its own directory | ✅ Confirmed | `cc-isolated.sh:714-718` — "CC_ISOLATED_DIR=…readlink -f…BASH_SOURCE"; pre-Q-089 `source "$(dirname …)/cc-exit-scan.sh"` at :562 (executed: run against a stage, no staged file executed, all writes under the stage) | Fact-check claims 12-13 (executed) | for-orchestrator-synthesis |
| Q-117 block is verbatim | ✅ Confirmed | `questions-archive.md:2463-2475`, byte-identical (executed: diff) | Fact-check | for-orchestrator-synthesis |
| `rm -rf` stays inside `~/cc-verify` | ✅ Confirmed | teardown paths derived from `$V/stage-$T8`, `$V/VERIFY-$T8`, `$V/src-$RUN.git` with format-checked RUN/T8 (executed with planted records) | Fact-check claim 24a, security endorsement | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | loop-pass short-circuit (behavioral red confirmed) | fact-check claims 6, 9a, 24b |
| api-consistency-reviewer | loop-pass short-circuit (behavioral red confirmed) | fact-check claims 6, 9a, 24b |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `spike-q117.sh` `--clean` / teardown | FC-24b, security F4 | distinct defects already merged as R3: each states its mechanism completely |
| 2 | doc step 3 / the start of step 1 | security F1, F2 | distinct defects: F1 is the missing pin, F2 the moving input; one fix (a tree pin) covers both for this branch, as F2 says |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
