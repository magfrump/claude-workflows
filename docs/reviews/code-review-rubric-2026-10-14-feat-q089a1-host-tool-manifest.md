Commit: f2533b33

# Code Review Rubric

**Scope:** feat/q089a1-host-tool-manifest (`4ab9a51f..f2533b33`, 1 commit, 392 lines at loop start) | **Reviewed:** 2026-10-14 | **Status: 🟡 DOES NOT PASS** — 0 red, 6 amber, fixed in the iteration-1 fix commit, pending iteration 2

Iteration 1 of 3 of a new loop, re-cut from feat/q089-host-tool-trust after that loop's iteration-4 gate decision `split`. Run with `--loop-pass`, fact-check k=1, delivery self-read. Critics: security, performance, api-consistency, architecture.

**Merge constraint (security F1, architecture F3):** A1 lands only together with A2, its stacked unit, and B. At A1 alone, "cc-push refuses" is false and a tampered cc-push only warns. Merge A2's branch, which contains A1, then B, in one landing.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The bless command was spelled three ways. `--list`'s hint was a bare `cc-isolated --bless`, which blesses the default dir when `CLAUDE_DEVC_CONFIG_DIR` names another. | API / Architecture | Inconsistent / Coupling | api-consistency F1 + architecture F1 | for-author | — | 🟢 Fixed: every hint goes through `bless_cmd`, and the refusal calls it with the launcher's dir. Architecture F1's deeper fix (assert that the launcher's dir equals config_dir) is C1. | — |
| A2 | An unreadable or CRLF-garbled `host-tools.sha256` was reported as every tool "changed" (raw awk errors, a multi-line reason inside the ERROR sentence), and the hint then pointed at a bless that overwrites the anomaly. | Security / API | Info / Minor | security F2 | for-author | — | 🟢 Fixed: "unreadable or malformed: inspect it before any bless overwrites it". The refusal prints the reason lines under a fixed ERROR line, and --list and the cc-push line join them with "; ". New test. | — |
| A3 | A missing host manifest was reported as "CHANGED"; the --list OK and CHANGED lines had different shapes; the host block lacked the entry count. | API Consistency | Minor | api-consistency F2-F4 | for-author | — | 🟢 Fixed: "No blessed host tools (…run: <bless_cmd>)", `Host tools — match the bless (…)` and `Host tools — CHANGED (…)` (the em-dash shape of the line above), plus "(N entries; …)". | — |
| A4 | The refusal said "refusing to run the session-exit scan's code" while also blocking `--register` and `--probe-only`. | API Consistency | Minor | api-consistency F6 | for-author | — | 🟢 Fixed: "refusing to launch, probe or register:". | — |
| A5 | Comment and message accuracy: "DIR is the script's own dir" (`--list` passes config_dir); the dir-split comment listed one case of three; "refuses everything but --bless/--list" (`--help` and usage errors come first); "no rebuild or probe is needed" (an unverified config still probes). | Docs | Mostly accurate ×4 | code-fact-check 2-5 | for-author | — | 🟢 Fixed, all four. | — |
| A6 | The bless-failure test's second case checked only host-tools.sha256 and restored identical Dockerfile bytes. | Test | Mostly accurate | code-fact-check 6 | for-author | — | 🟢 Fixed: it writes a different Dockerfile and checks both manifests. | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Two notions of "the install dir" (`config_dir()` vs the launcher's own dir). Make the launcher's dir the owner: assert it equals `readlink -f config_dir` for an installed copy and refuse once on a mismatch. | architecture F1 | Coupling | for-author | — | 🟢 Open: a behaviour change to the launch path. A1 makes every hint name the right dir; the assertion is a follow-up (roadmap Idea). |
| C2 | The per-entry-point file lists are written out at the call sites; one list inside the byte-copied block would serve the parity test and Q-147. | architecture F2 | Coupling | for-author | — | 🟢 Open: goes with Q-147 (feat/q089-source-guard) |
| C3 | The refusal branch spells out re-bless consequences in message text; pull it into a status function if a third manifest arrives. | architecture F4 | Info | for-author | — | 🟢 Open |
| C4 | `--bless`/`--register` output gains a prelude (`head -1` would change); nothing in the repo parses it. | api-consistency F5 | Info | for-orchestrator-synthesis | — | 🟢 Won't-Fix |
| C5 | The header, `guides/cc-isolated-usage.md` and its Troubleshooting table say nothing about the refusal, the warning or the --list lines. | api-consistency F7 | Minor | for-author | — | 🟢 Moved to unit B |
| C6 | Per-file forks (about 4 ms per call); `--list` hashes cc-gitdir.sh twice; no interrupt trap for bless temp files (dotfiles, which no glob reads). | performance F1-F4 | Info | for-orchestrator-synthesis | — | 🟢 Won't-Fix |
| C7 | Not new, row 45's threat model: an unanchored host-tools.sha256, a forgeable repo marker, TOCTOU and hardlinks. | security (not new) | Info | for-orchestrator-synthesis | — | 🟢 Won't-Fix |

---

## ↩️ Considered Overrides

No prior overrides matched this diff.

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| blessed_hash changes once from base to A1, then stays through a cc-push edit and a re-bless | ✅ Confirmed | executed: 4550ab99… → de595abc… → unchanged | code-fact-check (executed) | for-orchestrator-synthesis |
| A tampered scan is refused before any of its code runs, and the refusal also runs the boundary check | ✅ Confirmed | executed | code-fact-check + security (executed) | for-orchestrator-synthesis |
| A failed bless leaves both manifests byte-identical and no temp files | ✅ Confirmed | executed | code-fact-check + security (executed) | for-orchestrator-synthesis |

---

## 🧩 Composition check

| Cluster | Span | Fragments | Disposition |
|---|---|---|---|
| bless hints / dir owner | :238, :325-334, :493, :747 | api F1, architecture F1, fc 2-3 | composed into A1 (one bless_cmd) plus C1 (one dir owner) |

---

## ⏭️ Skipped Core Critics

None.

Line count: 392 at loop start (cap 400, checked before the loop per decision log 62). It is 418 after this fix round.
