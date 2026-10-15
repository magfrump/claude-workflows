Commit: fa059477
Loop-pass short-circuit: used at b1539159

# Code Review Rubric

**Scope:** feat/q089-host-tool-trust, unit A (`4ab9a51f..dce5b039`, 1 commit, 272 lines) | **Reviewed:** 2026-10-14 | **Status: 🔴 DOES NOT PASS** — pass 3: 2 red item(s), 1 amber item(s), fixed, pending the pass-4 re-review

Loop pass 1 (`--loop-pass`, k=1 fact-check). Delivery mode: inline-diff-only. Critics:
security, performance, api-consistency, and architecture (auto-selected: a cross-cutting
change to the trust pipeline). Test-strategy was not selected, because the diff changes
tests alongside the code.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | (pass 2) `--list` says "launches refuse" for a cc-push-only mismatch, but launches only warn (Incorrect, executed, contradicting the repo's own test) | Behavior / UX | Incorrect | code-fact-check pass 2, claim 7b | `devcontainer-config/cc-isolated.sh:462` | for-author | — | 🟢 Fixed (pass-2 fix commit): --list splits launcher-refuses and cc-push-refuses-launches-warn |
| R2 | (pass 2) The source-set test's "a form this parse cannot read fails" is false: it misses `.` lines and mid-line `source`, and it is flaky under the sourced script's pipefail (`host_tool_files \| grep -q` SIGPIPE, 1/25 runs) | Test | Incorrect | code-fact-check pass 2, claim 15 + flake probe | `test/cc-isolated-functions.bats:1031` | for-author | — | 🟢 Fixed: catches any `source`/`.` command word after ^ ; & \| ( { then do else; an unreadable form fails; mutation-checked (dot in a function, mid-line source, dynamic path: all fail); here-string instead of pipe; 15/15 clean |
| R3 | (pass 3) `--list` said "launches and cc-push refuse" on a scan-only change (cc-push does not run the scan), and it hid a simultaneous cc-push change | Behavior / UX | Incorrect | code-fact-check pass 3, claim 10b | `devcontainer-config/cc-isolated.sh:472` | for-author | — | 🟢 Fixed: --list runs each entry point's own check and prints "launches refuse: …" or "launches warn …", plus "cc-push refuses: …" |
| R4 | (pass 3) The source-set test still let 12 unchecked forms through (`if source`, `builtin source`, `command .`, eval, backticks, two sources on one line, a sibling name in a comment, a non-sibling path) | Test | Incorrect | code-fact-check pass 3, claim 17b | `test/cc-isolated-functions.bats` | for-author | — | 🟢 Fixed by changing approach: every non-comment line that mentions `source` or has `.` in a command position must exactly match one canonical sibling-source form. Mutation battery: 15/15 caught, 20/20 clean |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The launcher's host-tool refusal exits before `check_manifest`, so a boundary change made at the same time is never shown. It also says "no rebuild or probe is needed" and points to `--bless`, which rewrites both manifests and accepts the boundary change unseen (probes: Dockerfile + scan, init-firewall + scan). Location: `devcontainer-config/cc-isolated.sh:661-667`, `bless_manifest` `:250-253`. | Security / Architecture | Medium / Coupling | security-reviewer F1 + architecture-review F1 (independent) | for-author | — | 🟡 Open | — |
| A2 | `verify_host_tools` decides "repo checkout" when a dir has no manifest and isn't the run-time config dir, and on that decision it skips the check. Delete both manifests, then use a custom install dir with the variable unset, or the default dir with the variable pointing elsewhere, and a tampered `cc-gitdir.sh` or scan runs. Plan B4 and row 71 overclaim. Location: `cc-isolated.sh:227-230` and the cc-push copy. | Security | Low / Minor | code-fact-check 9b + security-reviewer F3 + architecture-review F3 | for-author | — | 🟡 Open | — |
| A3 | Bless writes `host-tools.sha256` before the boundary manifest. A failed bless (a missing enforcement file) leaves the host tools re-blessed beside an empty `manifest.sha256`. A missing host tool gives a bare sha256sum error and a partial file. Location: `cc-isolated.sh` `bless_manifest`, `compute_host_tools_manifest`. | API Consistency / Security | Minor / Info | api-consistency F4 + security-reviewer F4d | for-author | — | 🟡 Open | — |
| A4 | cc-push's refusal runs before argument parsing, so `--help` and bad usage exit 1 against the header's documented 0 and 2. The prefix is `cc-push: refusing to run:`, while `die` and the launcher use `ERROR:`. Location: `cc-push.sh:176-178`, header exit-code block. | API Consistency | Inconsistent | api-consistency F1, F3 | for-author | — | 🟡 Open | — |
| A5 | `--list` (the diagnostic the refusal leaves open) and `--bless` say nothing about host-tool state. A verified config shows "verified live: yes" while every launch is refused. Location: `cc-isolated.sh` `list_projects`, `bless_manifest`. | API Consistency | Inconsistent | api-consistency F2 | for-author | — | 🟡 Open | — |
| A6 | Each entry point's list of executed files (the `verify_host_tools` arguments) is tied to its transitive `source` lines by nothing. A new helper sourced by the scan would be forced into `host_tool_files` by tests, but the launcher would still source it unchecked. Location: `cc-isolated.sh:624`, `cc-push.sh:176`, `cc-exit-scan.sh:10-11`. | Architecture | Coupling | architecture-review F2 | for-author | — | 🟡 Open | — |
| A7 | The headers of `cc-exit-scan.sh:3-5` and `cc-gitdir.sh:3-5` still say `enforcement_files()` hashes them into the trust manifest. | Docs | Stale | code-fact-check 1 + architecture F4 + api F7 | for-author | — | 🟡 Open | — |

| A8 | (pass 2) The refusal named only the first changed tool and no cc-push change; bless accepts first and shows second, and printed nothing with no previous manifest | Security | Low | security-reviewer pass 2 F1 | for-author | — | 🟢 Fixed: verify_host_tools names every mismatch, the refusal adds cc-push, bless prints "No previous …"; bless still does not prompt (the diff is printed before the summary and install.sh's own review gate precedes it) | — |
| A9 | (pass 2) The refusal checked the boundary in `config_dir()` but pointed the bless at the launcher's dir (custom install, variable unset), so it could say "unchanged" while the bless accepted a changed Dockerfile | Security | Low | security-reviewer pass 2 F2, fact-check 8c | for-author | — | 🟢 Fixed: the refusal's check_manifest runs with CLAUDE_DEVC_CONFIG_DIR set to the launcher's dir | — |
| A10 | (pass 3) Side effect of the A9 fix: check_manifest's own hint printed `$0 --bless` without CLAUDE_DEVC_CONFIG_DIR, giving two contradictory bless commands for a custom dir | API / UX | Low | code-fact-check pass 3, claim 8 | for-author | — | 🟢 Fixed: `bless_cmd` names the variable when it is set | — |

Pass-1 rows A1–A7 were fixed in b1539159; pass 2's fact-check and security verified A1, A2, A3 (on a compute failure), A4, A5 and A7. A6 went red as R2 and is fixed. Pass-2 Mostly-accurate items were also fixed: the bless temp-file leak when the second mktemp fails, the cc-gitdir.sh header, and the cc-push header (missing or symlinked manifest).

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | The launcher no longer notices a tampered `cc-push.sh` (it used to refuse through `check_manifest`). Suggestion: the launcher also hashes cc-push.sh and warns on a mismatch, without refusing. | security-reviewer F2 (Low) | Low | for-author | — | 🟢 Open |
| C2 | Names: in this file "verified" means a live probe passed (`is_verified_live`), so `verify_host_tools` reads as a probe, and `host_tools_path` names a manifest. Suggested: `check_host_tools`, `host_tools_manifest_path`. | api-consistency F6 | Minor | for-author | — | 🟢 Open |
| C3 | `guides/cc-isolated-usage.md` has no host-tool step and mentions only `Live-verified:`. | api-consistency F7 | Minor | for-author | — | 🟢 Open (unit B) |
| C4 | Wording: the refusal also prints "no rebuild or probe" on "no host-tool manifest"; `--help` is also answered; the install.sh comment says "checks before it runs" (the prologue runs first); the cc-push test name implies a self-tamper case it lacks. | code-fact-check 11b, 12, 14, 17 | Mostly accurate | for-author | — | 🟢 Open |
| C5 | The check reads `host-tools.sha256` from the script's dir, while bless writes it to `config_dir()`. When the two differ, `--bless` cannot clear the refusal. | security-reviewer F4c | Info | for-author | — | 🟢 Open |
| C6 | TOCTOU between hash and `source`, and hardlinked tool files. These are accepted non-goals (plan B6/B7). | security-reviewer F4a,b | Info | for-orchestrator-synthesis | — | 🟢 Won't-Fix |
| C8 | (pass 2) Leftover temp files on Ctrl-C, manifests at mode 0600, a split when the second rename fails (fails safe), the install.sh-marker opt-out (costlier than editing a tool) | security-reviewer pass 2 F4, F5 | Info | for-orchestrator-synthesis | — | 🟢 Won't-Fix |
| C7 | The check costs about 13.5 ms per launch or push, from forks per file. That's fine for 2 files on a cold path. | performance-reviewer F1, F2 | Info | for-orchestrator-synthesis | — | 🟢 Won't-Fix |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| A host-tool edit followed by `--bless` leaves `blessed_hash` and the verified-live receipt unchanged | ✅ Confirmed | executed: blessed_hash `e5461178fb2c126b` and "Verified live: yes" held across the edit and bless | code-fact-check (executed) | for-orchestrator-synthesis |
| An old install (old manifest, no host-tools.sha256) upgrades through install.sh's own bless command | ✅ Confirmed | executed: exit 0, host-tools.sha256 written, blessed_hash changed once | code-fact-check (executed) | for-orchestrator-synthesis |
| Two copies of `verify_host_tools` with a byte-parity test is the right shape (a sourced verifier would be unchecked code) | ✅ Confirmed | architecture-review F5; parity test in `test/cc-isolated-functions.bats` | architecture-review | for-orchestrator-synthesis |

---

## 🧩 Composition check

| Cluster | Span | Fragments | Disposition |
|---|---|---|---|
| `cc-isolated.sh` refusal + bless | :250-253, :661-667 | security F1, architecture F1, fc 12, api F5 | distinct sources, same defect: A1 already states it whole. No composition needed |
| `verify_host_tools` opt-out | :227-230 | fc 9b, security F3, architecture F3 | same defect: A2 states it whole |

---

## ⏭️ Skipped Core Critics

Pass 1: none. Pass 2: performance-reviewer, api-consistency-reviewer and architecture-review were skipped. Reason: loop-pass short-circuit (behavioral red confirmed at fact-check, R1/R2). security-reviewer ran under mechanic 7 (enforcement files).

---

## Iteration-4 gate: decision `split` (2026-10-14)

The loop ran a 4th pass (pass 4 = iteration 4) without first recording a decision, which breaks review-fix-loop's hard cap. That is recorded here and as Q-147. Pass 4's fact-check (fa059477) found 3 Incorrect. Two concern the static source-set test's reach (`FOO=1 . f`, case arms, `\. f`, quoted or obfuscated `source`, `$c f`), the same item as A6, R2 and R4 in every pass. That makes this a divergence on one separable part, not churn across the unit.

**Decision: `split`.**
- **The source-set static guard (A6/R2/R4)** leaves unit A for its own branch, `feat/q089-source-guard` (at fa059477, which holds the test). It gets a fresh loop later, and its first job is to scope the claim honestly: it guards plain spellings against accidental drift and is not complete for bash. Unit A drops the test, and A6 reverts to 🟡 Open, moved to that unit.
- **Unit A core** closes this loop and starts a new one at iteration 1 with full-branch scope. It takes pass 4's remaining findings:
  - 4b: `--list` dies under set -e when the config dir's parent is missing;
  - the bless-split comment;
  - the `--list` dir comment.

Convergence diagnosis: every pass converged on the runtime code. The only thing that did not converge was a test making a completeness claim that grep cannot meet.

Also from pass 4: the 5 suite failures "pre-existing on main" depend on the locale. Under `LC_ALL=C` every test passes on both trees, so the sandbox's uninstalled `en_US.UTF-8` is the cause.
