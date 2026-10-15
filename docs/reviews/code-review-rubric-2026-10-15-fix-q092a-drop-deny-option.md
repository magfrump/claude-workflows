Commit: b973e678

# Code Review Rubric

**Scope:** fix/q092a-drop-deny-option; pass 1 full unit `00a27a2f..1a831ffe`, pass 2 delta `1a831ffe..b973e678` (`--loop-pass`, k=1) | **Reviewed:** 2026-10-15 | **Status: 🟡 fixes applied, re-review pending** — 0 red, 4 amber fixed in the next commit

Q-092 unit 1 of 2: drop the hook's `--deny` test option and the de-quoted deny match. Delivery mode: self-read (agents ran `git diff`). Critics: security, performance, api-consistency (architecture ran on unit 2, which carries the structural change). Reports: `code-fact-check-report-q092a-2026-10-15.md`, `security-review-q092a-2026-10-15.md`, `performance-review-q092a-2026-10-15.md`, `api-consistency-review-q092a-2026-10-15.md`.

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Test "a NUL inside a --permissions rule drops that rule only" could not tell a dropped rule from a split one (mutant without the NUL filter passed) | Tests | Incorrect (high), test-only | Fact-check claim 20b | for-author | — | Fixed | Uses `["Bash(zz)\u0000Bash(curl:*)"]` now |
| A2 | Rule-table row and test "`Bash(ls *)` approves nothing" are wrong: the allow rule is a literal prefix and approves `ls *`, `ls * -la` | Docs/tests | Incorrect (high), comment | Fact-check claim 22 | for-author | — | Fixed | Header row and paragraph corrected; test pins `ls * -la` approved, `ls -la` not |
| A3 | ROLE section still called allow-vs-deny unverified and the deny check load-bearing, contradicting Q-082 and this unit's own text | Docs | Stale | Fact-check claim 5 | for-author | #129 (2026-09-27, Acknowledged: "if deny wins, delete the hook's deny reader") | Fixed | ROLE now cites Q-082 and says unit 2 removes the check |
| A4 | Two deny mechanisms still present in this unit lost their only tests: the per-extracted-command check and `add_deny_rule`'s escaping (both mutants passed 42/42) | Security/tests | Low | security-reviewer | for-author | — | Fixed | New settings-file test: `ls \| rm -rf x` vs `Bash(rm -rf:*)`, `cat notes[1].txt` vs a literal rule |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `permissions.allow/deny: false` count as absent (jq `//`) | Fact-check claim 7 (Mostly accurate, pre-existing) | Low | for-author | — | Deferred to unit 2, which makes each key, when present, an array of strings |
| C2 | Stdout test comment said "over every exit path of main"; the jq-missing exit is not reached | Fact-check claim 14 (Mostly accurate) | Low | for-author | — | Fixed |
| C3 | Residual list named only the `""` split; backslash, whole-word and exact-rule quoting (`git "push"`, `cat "secret"`) belong to the same family | Fact-check, security-reviewer | Low | for-author | — | Fixed |
| C4 | Header line 15 (`--permissions` "instead of reading from settings files") and the "relative value is used as written" line were already wrong | Fact-check | Low | for-author | — | Fixed |
| C5 | Plan F3 listed `${X:-push}` as exposed; the shape allowlist refuses it | security-reviewer (Informational) | Info | for-author | — | Fixed |
| C7 | Pass 2: new test title said "only * is a wildcard" but checked brackets only (a `?`-unescaped mutant passed) | Fact-check pass 2 claim 13b (Mostly accurate) | Low | for-author | — | Fixed: `Bash(cat file?.txt)` case added |
| C8 | Pass 2: b973e678's message credits F3's plan changes to the unit 2 security review (they came from unit 1's reviews) and omits F6b | Fact-check pass 2 claim 18 (Mostly accurate, commit message) | Low | for-author | — | Accepted: commit message, not rewritten; recorded here |
| C6 | Removed `--deny` is silently swallowed by main's catch-all | api-consistency (Informational) | Info | for-author | #123 (2026-09-27, Won't-Fix: test-only options) | Won't-Fix: no caller exists; a test pins it; Claude Code applies deny regardless |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `integrate/q077-q078-q080` / 2026-09-27 (#122) | `Bash(*)`/`Bash(**)` treated alike | 🟢 → Won't-Fix | deny side only | Moot: the `--deny` tests are gone; unit 2 removes the deny side |
| `integrate/q077-q078-q080` / 2026-09-27 (#123) | `--deny`/`--permissions` pairing | 🟢 → Won't-Fix | test-only | `--deny` removed here; see C6 |
| `integrate/q077-q078-q080` / 2026-09-27 (#127) | No pin for `Bash(rm *)` vs bare `rm` | 🟢 → Defer | until Q-082 | Still unpinned; unit 2 removes the deny side and the note |
| `integrate/q077-q078-q080` / 2026-09-27 (#128) | FIFO at a settings path hangs the hook | 🟢 → Won't-Fix | fails safe | Inherited, unchanged |
| `integrate/q077-q078-q080` / 2026-09-27 (#129) | Hook re-implements the deny engine | 🟡 → Acknowledged | pending Q-082 | Being discharged by this stack (A3) |
| `feat/hook-refuse-redirects` / 2026-09-28 (#146-148) | redirect-loop cost, AST size, `bash` rules | various | various | Inherited; not touched |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| No caller of `--deny` outside the tests | ✅ Confirmed | `rg -- '--deny'` over the repo incl. devcontainer-config/, scripts/, hooks/wiring.json → test file only (executed) | Fact-check, api-consistency | for-orchestrator-synthesis |
| main() writes only the allow JSON to stdout; malformed input exits 4/5/1, never 2 | ✅ Confirmed | executed probes; `grep -o '"permissionDecision":"[a-z]*"'` → one value | Fact-check (executed) | for-orchestrator-synthesis |
| No per-call cost change | ✅ Confirmed | 20-run bench: 85.6 → 85.9 ms | performance-reviewer (executed) | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (architecture-review not auto-selected for this unit: no module-structure change beyond a test-only flag; it ran on unit 2.)

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `test/auto-approve-allowed-commands.bats` rule-table / deny tests | A2, A4 | distinct defects: one is a wrong doc claim, the other a coverage loss |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
