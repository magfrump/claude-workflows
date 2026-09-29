Commit: 52071a3

# Code Review Rubric — feat/hook-refuse-redirects (Unit A)

**Scope:** `main...feat/hook-refuse-redirects`. Three review iterations; the 3-pass cap was reached on pass 3.
**Status:** ✅ Mergeable. No Must Fix remains, and every Must Address item is fixed or acknowledged. Single-sample review; absence of findings is not an attestation.

## Iterations

| Pass | Commit | Scope | Stages | Outcome |
|---|---|---|---|---|
| 1 | f05043f | full | fact-check k=1 | 9 Incorrect: the class-based refusal leaked (`let 'a[$(cmd)]=1'` through the old empty-extraction branch, `export PATH=`, escaped backticks and `$'\x3e'` in `bash -c`). Fixed by the AST-shape allowlist (51bbfb6). |
| 2 | 033ccd6 | full | fact-check k=1 | 3 Incorrect: builtins that evaluate their arguments (`read 'a[$(cmd)]'`, `test -v`, `printf -v`, `mapfile -C`, `compgen -C`, `hash -p`); 14 of 18 wrapper test items were vacuous; `Bash(ls:*)` approved `ls/x`. Fixed in 9fad6ec. |
| 3 | 1a513a8 | full (critics); incremental fix range (fact-check) | fact-check (partial), security (static only), performance, api-consistency | No bypass found, no Must Fix. Must Address fixed in 52071a3. Fix-drift lite review of 1a513a8..52071a3: no findings. |

## 🔴 Must Fix
None open.

## 🟡 Must Address

| # | Finding | Source | Status |
|---|---|---|---|
| A1 | Header rule table still said `Bash(ls)` matches `ls/x`; the CLOSED GAPS summary left out VAR=, &, wrapper and builtin refusals | api-consistency F1, F4 | ✅ Fixed 52071a3 |
| A2 | The slash fix also stopped `Bash(dir/path:*)` rules from covering files under the path | api-consistency F2 | ✅ Fixed 52071a3 (+ test) |
| A3 | `guides/bare-host-hook-wiring.md:148` and `README.md:162` described the old behavior | api-consistency F5, F6 | ✅ Fixed 52071a3 |
| A4 | Two extra jq processes per approved call (+41 ms) | performance F1 | ✅ Fixed 52071a3: one jq pass, measured +26 ms (main 110 ms → HEAD 136 ms, mean of 20) |
| A5 | `bash …` project rules (4 in this repo) no longer approve pipelines through the hook | api-consistency F3 | Acknowledged (override log); the design question goes to the user at merge |

## 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | Hardcoded builtin list can go stale on a newer bash | security (static) | ✅ Fixed 52071a3: test diffs the list against `compgen -b` |
| C2 | Redirect loop superlinear at thousands of redirects | performance F2 | Won't-Fix (override log) |
| C3 | AST size and jq re-reads at hundreds of pipeline stages | performance F3 | Defer (override log) |
| C4 | jq 1.6 depth limit at ~100+ stages; fails closed; pre-existing | performance F4 | No change needed |

## ✅ Confirmed Good
- The builtin list equals `compgen -b` on bash 5.2.15 (61 entries each). Fact-check pass 3, executed: `scratchpad/fcA3/builtins.txt`.
- The shape tests are not vacuous: with `REFUSE_CONSTRUCTS` forced off, all 8 fail. Executed by the author at 1a513a8 and again at 52071a3 (`scratchpad/verify_a.sh`).
- `parse_commands` output and the CLI options are unchanged from main. api-consistency, executed.

## Coverage and escalations
- **Security review is static only on pass 3.** Two security-critic dispatches declined to build and run inputs designed to get past the gate. Executed bypass probing for this unit comes from the pass-1 and pass-2 fact-checks (dozens of candidates, run in bash with marker files) and from the author's probe sets, now pinned as tests.
- **The pass-3 fact-check is partial.** A classifier stopped it while it was generating disguised builtin names. Only the builtin-list match and the "Refusing" provenance were verified. The fix-range claims were covered by the author's executed runs (240/240 suites, mutation check, probes) and the fix-drift lite review.
- Out of scope, by design: what an allowed external program does with its own flags (e.g. `git --output=`, git config-driven exec). That is the allow list's job. Recorded in Q-097.

## Considered overrides
Rows matched from `docs/reviews/override-log.md`: 2026-09-27 `integrate/q077-q078-q080` (the hook re-implements part of the permission engine, and the deny-check residuals). Both stand. Row 64 adds shape refusal on top of the deny check and changes neither.

## 🧩 Composition check
No multi-source co-located clusters qualified.

## ⏭️ Skipped Core Critics
None skipped. The security critic ran but produced static notes only (see Coverage).

## Reports
- `docs/reviews/code-fact-check-report-unitA-pass1-f05043f.md`, `…-pass2-033ccd6.md`
- `docs/reviews/api-consistency-review-2026-09-28-unitA.md`
- `docs/reviews/performance-review-2026-09-28-unitA.md`
- Security (static) and the pass-3 fact-check (partial): summarized above; no report file was written.
