Commit: c9ff3e84

# Code Review Rubric

**Scope:** fix/q092-drop-hook-deny-reader, unit 2 `1a831ffe..ed06dec1` (stacked on unit 1); pass 1 `1a831ffe..ed06dec1`, pass 2 delta `ed06dec1..c9ff3e84` (fact-check at 72b8c825, critics at c9ff3e84) (`--loop-pass`, k=1) | **Reviewed:** 2026-10-15 | **Status: 🟡 fixes applied, re-review pending** — 0 red, 3 amber addressed in the next commit

Q-092 unit 2 of 2: drop the settings-file deny reader. Delivery mode: self-read. Critics: security, performance, api-consistency, architecture (auto-selected: removes a module responsibility and a CLI behaviour). Reports: `code-fact-check-report-q092b-2026-10-15.md`, `security-review-q092b-2026-10-15.md`, `performance-review-q092b-2026-10-15.md`, `api-consistency-review-q092b-2026-10-15.md`, `architecture-review-q092b-2026-10-15.md`.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Bypass family missing from the plan (F6 said Covered): Claude Code 2.1.300 can ignore a whole settings file for an invalid value; the hook still approved from a file with a non-string allow entry, `deny: null/false` or any `ask` value, so with such a file `cat ~/.claude/.credentials.json` went from prompt (1a831ffe) to allow | Security | Medium | security-reviewer | for-author | — | Fixed in part | `allow`/`deny`/`ask`, when present, must now be arrays with no NUL in a string (tests added); pass 2 narrowed this: non-string entries are skipped, matching Claude Code (see A4). A value outside those keys (e.g. `defaultMode`, a BOM) remains a stated residual in the header FAILS CLOSED section, plan F6/F6b and log row 53. Revisit trigger: Claude Code's whole-file-drop conditions get traced, or a deny rule is found missing after a settings edit; question filed in the unit report |
| A2 | A NUL inside a `permissions.deny` string no longer failed closed (tests that pinned it were deleted) | API/security | Minor | api-consistency-reviewer | for-author | — | Fixed | The shape check now rejects NUL in deny and ask; test "a NUL inside a settings deny or ask rule fails closed" |
| A3 | Residual statements omitted version drift and the Claude Code version Q-082 ran on | Security/docs | Low | security-reviewer | for-author | — | Fixed | ROLE carries the version note and a re-test trigger; log row 53 points to it |
| A4 | Pass 2: failing closed on a non-string allow/ask entry is stricter than Claude Code, which drops such entries with a warning and keeps the file (2.1.300 binary, read not run); one stray entry silently turned every allow-listed call into a prompt, and the stated premise did not hold for that case | API | Minor | api-consistency-reviewer (pass 2) | for-author | — | Fixed | Option (b): non-string entries skipped in all three lists; non-array values and NUL still fail closed; test "non-string rule entries are skipped" |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | "array of strings" overstated: `deny: null/false` passed | Fact-check claims 9, 18 (Mostly accurate) | Low | for-author | — | Fixed by A1's stricter check |
| C2 | Rule-table row "`Bash(ls *)` approves nothing" is wrong | Fact-check claim 12b; unit 1 A2 | Low | for-author | — | Fixed (header row and test) |
| C3 | Deny shape check copied only part of Claude Code's validation (`ask` unchecked) and rested on an unstated premise | architecture-review (Minor) | Minor | for-author | — | Fixed: ask checked; comment names the whole-file-drop premise and the residual |
| C4 | Row 53's older amendment points at header sections unit 2 deleted | architecture-review (Info) | Info | for-author | — | Fixed: the 2026-10-15 amendment names the replacements |
| C5 | Removed `--deny` silently swallowed; with no deny reader a stale caller gets no deny from the hook | api-consistency, architecture (Info) | Info | for-author | #123 | Won't-Fix: no caller; Claude Code applies deny |
| C6 | `--permissions` skips the settings files' fail-closed check too | api-consistency (Info) | Info | for-author | #123 | Won't-Fix: test-only option, documented |
| C7 | Glob spelling getting past Claude Code's matcher is unverified | Fact-check claim 3 (Unverifiable) | Info | for-author | — | Accepted (plan F3/F4/F5); live check in the unit report |
| C9 | Pass 2: FAILS CLOSED said "a permissions that is not an object" but `permissions: null` was accepted | Fact-check pass 2 claim 9 (Mostly accurate) | Low | for-author | — | Fixed: a present `permissions` must be an object (null fails closed); test case added |
| C10 | Pass 2: which values make Claude Code drop a whole file is untraced | Fact-check pass 2 claim 11b (Unverifiable) | Info | for-author | — | Accepted: the stated residual (A1); question in the unit report |
| C11 | Pass 2: RESIDUAL named only a BOM; jq 1.6 also accepts NaN/Infinity literals that a strict JSON parser rejects | security-reviewer pass 2 (Info) | Info | for-author | — | Fixed: "anything Claude Code rejects that this check accepts" |
| C12 | Pass 2: `explode \| any(. == 0)` per string is slow at scale (6000 rules: 528 ms); `test("\u0000")` is ~10x faster; `contains` is wrong on jq 1.6 | performance-reviewer pass 2 (Info) | Info | for-author | — | Fixed: uses `test`, with a comment on `contains` |
| C13 | Final pass: log row 53 cited Q-081 as open (answered; now Q-125), and its "now also" list overstated what is new; the guide pointed at RULE SYNTAX for what deny leaves; ROLE's "exit 0" ignored malformed stdin (exit 4/5, empty stdout) | Fact-check final (Stale / Mostly accurate) | Low | for-author | — | Fixed |
| C14 | Final pass: load_rules discarding partial jq output was untested (mutant passed) | Fact-check final r2 | Low | for-author | — | Fixed: the unparseable-project test now has a rule in the global file, which jq prints first |
| C15 | Final pass: ed06dec1's message says a non-array-of-strings deny fails closed; at that commit null/false passed | Fact-check final (Mostly accurate, commit message) | Info | for-author | — | Accepted-immutable: superseded by fdae7834 and 0444b1ac |
| C8 | `guard-trusted-writes.py` can emit `ask` on Bash (SOFT target, tainted session), which per #39344 can turn a deny into a prompt; "never asks" is true of this hook only | api-consistency (out of lane), plan F8 | Info | for-author | — | Out of scope; reported as a question |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `integrate/q077-q078-q080` / 2026-09-27 (#122, #123, #127) | deny-side `Bash(*)`, `--deny` pairing, `Bash(rm *)` divergence | 🟢 → Won't-Fix/Defer | deny side | Moot: the deny side is removed |
| `integrate/q077-q078-q080` / 2026-09-27 (#128) | FIFO at a settings path hangs the hook | 🟢 → Won't-Fix | fails safe | Inherited |
| `integrate/q077-q078-q080` / 2026-09-27 (#129) | Hook re-implements the deny engine | 🟡 → Acknowledged | pending Q-082 | Discharged by this unit (architecture-review confirms) |
| `feat/hook-refuse-redirects` / 2026-09-28 (#146-148) | redirect cost, AST size, `bash` rules | various | various | Inherited; not touched |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| Hook emits only the allow JSON or nothing; no main path exits 2 | ✅ Confirmed | 33 executed probes (security), one decision string in source, stdout test | Fact-check, security-reviewer (executed) | for-orchestrator-synthesis |
| Partial jq output before an error is discarded | ✅ Confirmed | executed good-file-then-bad-file probe: 0 prefixes loaded | Fact-check (executed) | for-orchestrator-synthesis |
| wiring.json change is `_comment` only and the linker drops `_` keys | ✅ Confirmed | `link-claude-home.sh:134-136`; linker suite 16/16 | Fact-check (executed) | for-orchestrator-synthesis |
| Per-call cost flat in the number of deny rules (200 rules: 109.5 → 85.8 ms) | ✅ Confirmed | executed bench | performance-reviewer | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `hooks/auto-approve-allowed-commands.sh` SETTINGS_RULES_JQ and FAILS CLOSED header | A1, A2, C1, C3 | composed: one root, the shape check covered deny only partly (null/false, NUL, ask unchecked); fixed by one change (each list, when present, an array of NUL-free strings). Inherits 🟡 |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
