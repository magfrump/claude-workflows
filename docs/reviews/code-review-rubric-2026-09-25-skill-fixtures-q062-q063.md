Commit: 5ddf804

# Code Review Rubric

**Scope:** `main...HEAD` on `skill-fixtures` (Q-062 [2] install gate + Q-063 [1] deny-record fixtures; 23 files) | **Reviewed:** 2026-09-25 (review-fix loop iteration 1 of 3, `--loop-pass`, delivery mode: self-read) | **Status: 🟡 CONDITIONAL PASS** — 10 amber item(s) awaiting resolution or justification (iteration 1 fix batch: 9 Fixed, 1 Acknowledged via Q-064; iteration 2 at d8c43ae added A11-A14 and C16-C24, A11 is a re-fire of A10)

---

## 🔴 Must Fix

No red items. No critic filed a Critical or High, a Breaking, or a Structural finding. Both fact-check Incorrects are doc-class, so policy T maps them to 🟡.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The Q-062 detector fails open on an unreadable cwd. `procs_in_checkout` runs `readlink "$d/cwd" 2>/dev/null)" \|\| continue`. A same-uid process that calls `prctl(PR_SET_DUMPABLE, 0)` keeps an owned `/proc/<pid>` whose cwd cannot be read, so it can work in the checkout without being refused (reproduced). Refusing instead would refuse on every run while ssh-agent is up, since ssh-agent's cwd is unreadable too. Decision 037's residual list omits this case. `devcontainer-config/install.sh:1146` | Security | Medium | security-reviewer F1; fact-check Claims 6/10b (Mostly Accurate); api-consistency and architecture escalations | for-author | — | 🟡 Acknowledged | Interim [1]: the skip is commented at `procs_in_checkout` and listed in decision 037. Tracked follow-up: Q-064 in `docs/working/questions.md` (refuse vs skip). |
| A2 | "Nothing executes" rests on `dontAsk` + `--permission-prompts none` denying every Bash call. That was probed with one writing command only. A read-only command (`pwd`, `ls`) that the CLI may auto-approve was never tried, and the tripwire detects a breach only after the fact. `test/skills/generate-reports.bash` (deny-record flags), `runner-contract.bash` comment | Security | Medium (Low confidence) | security-reviewer F2; fact-check Claim 30b (Unverifiable) | for-author | — | Fixed | Confirmed worse than stated. `dontAsk` alone ran `pwd`/`ls`/`echo`. The generator now pins `--disallowedTools 'Bash(**)'`, probed to deny every call (multi-line included) while keeping Bash visible. DD doc "As built". |
| A3 | `WRAPPER_RE` does not enforce "wrapper exact / only blank or `#` lines after the closing EXPREOF". The lazy `expr` group, anchored at `\Z`, spans an inner `EXPREOF` line, so a command bash would run with extra shell is labelled "Mode 1". The only rejection is the evaluator's SyntaxError on the `EXPREOF` name, so the guarantee lives in another file. No false pass is reachable today. The same claim is made in the docstring, `eval-helpers.bash:413`, `expected-verdicts.bash` and log #56. `test/skills/arithmetic-eval/mode1-equiv.py:33-52` | Correctness / Docs | Incorrect (high, doc-class) + Inconsistent | fact-check Claim 22; api-consistency #1; security-reviewer F3 (Low); architecture F2 (Minor) | for-author | — | Fixed | `split_mode1` closes the heredoc at the first `EXPREOF` line; test "a second EXPREOF line cannot smuggle shell". |
| A4 | The DD doc describes a design that was not built. `:169` says the helper checks "non-empty with no EXPREOF line", but no such check exists (Claim 15, Incorrect). `:153-154`'s plan bullets (a `no_bash_executed` check, repo mode, 4 planted-wrong fixtures) don't match the build: a tripwire in the generator and in mode1-equiv, inline mode, 3 wrong + 1 correct (Claim 13, Stale). `docs/working/dd-arith-eval-bash-grant.md:153-169` | Docs | Incorrect (doc) + Stale | fact-check Claims 13, 15; tech-debt #4 | for-author | — | Fixed | DD doc gains an "As built" section; the plan bullets are marked superseded. |
| A5 | `no_tool_called:` doesn't take `tool_called:`'s `<Tool>=<ERE>` shape. `no_tool_called:Bash=rm` is read as a tool named `Bash=rm` and passes silently with a Bash call present (probed rc=0). The absence-only check list comment in `eval_fixture` was not updated. `test/skills/eval-helpers.bash:156-158, 402-411` | API | Inconsistent | api-consistency #2 | for-author | — | Fixed | `no_tool_called:<Tool>[=<ERE>]`; absence-only list updated; test added. |
| A6 | The shared dispatcher hard-codes one skill. `assert_mode1_equiv` fixes the paths to `arithmetic-eval/mode1-equiv.py` and `skills/arithmetic-eval/SKILL.md` and ignores `$skill`, unlike `format_check` (`${skill}-format.bats`). A second skill using `mode1_equiv:` would be graded against arithmetic-eval's SKILL.md. `test/skills/eval-helpers.bash:419-424` | Architecture / API | Coupling | architecture F1 (Coupling, High); api-consistency #6 | for-author | — | Fixed | The checker resolves from `$skill` (`test/skills/<skill>/mode1-equiv.py`); a missing checker fails with a message. |
| A7 | Decision log #56 and questions-archive say the run "routed 5/5 through Mode 1". The fifth fixture is the no-arithmetic negative, which must not call Bash, so it should read 4/4 routed plus the negative making no Bash call. `docs/decisions/log.md` (#56), `docs/working/questions-archive.md:1320` | Docs | Mostly Accurate | fact-check Claim 12 | for-author | — | Fixed | Log #56 and the archive say 4 arithmetic fixtures routed plus the negative making no Bash call. |
| A8 | Some test names promise more than the tests assert. The eval tests name one value ("computes 29.2%") but pass on any listed alternate. `mode1-equiv.bats`'s "verbatim, computes its value" swaps in a different expression. `test/skills/arithmetic-eval-eval.bats`, `test/skills/mode1-equiv.bats` | Tests | Mostly Accurate | fact-check Claims 19, 33; tech-debt #3 | for-author | — | Fixed | Test names say "a listed value"; the "verbatim" test is renamed. |
| A9 | The header says the value lists hold "the values any of them would give", but tc-ae4's natural backward check (4.8M / 4 = 1.2M) is missing. The bare `4` alternate is also low-specificity. `test/skills/arithmetic-eval/expected-verdicts.bash` | Tests | Mostly Accurate | fact-check Claim 20; api-consistency #10; tech-debt #3 | for-author | — | Fixed | tc-ae4 lists `4800000|1200000`; the bare `4` is dropped as unspecific. |
| A10 | The mode1-equiv.py docstring says "diagnostics on stdout; exit 0/1". Setup and usage errors go to stderr and exit 1 (the repo convention is 2 for usage). A bad value spec raises an uncaught traceback, and `subprocess.TimeoutExpired` is also uncaught. `test/skills/arithmetic-eval/mode1-equiv.py:24-27, 71-95` | API / Robustness | Mostly Accurate + Minor | fact-check Claim 26; api-consistency #5; performance F3 | for-author | — | Fixed | Exit 2 plus a stderr message for usage/spec/extraction errors; `TimeoutExpired` returns None; docstring updated. |
| A11 | **Re-fire of A10 (divergence flag).** mode1-equiv.py's exit-2 contract is still partial. A negative tolerance, `nan` and unreadable paths escape as tracebacks with exit 1. The dispatcher also flattens 0/1/2 into pass/fail, and a bad spec is caught only if some Mode 1 call reaches the comparison. Iteration 1 patched symptoms. The deeper fix is one setup-error boundary, full spec validation, a distinct exit-2 label in the assert, and a fast pre-flight test that validates every committed `mode1_equiv:` spec. `test/skills/arithmetic-eval/mode1-equiv.py`, `eval-helpers.bash` | API / Robustness | Incorrect (doc, high) | fact-check iter2 Claim 25b; architecture iter2 F2; api-consistency iter2 #6 | for-author | — | 🟡 Open | — |
| A12 | `no_tool_called:` fails open. `grep -iE "$pattern" \|\| true` swallows grep's exit 2 (an invalid ERE, or a pattern starting with `-`) and a jq failure, and a misspelled tool name (`bash`) matches nothing. All three pass with a Bash call present. It guards the only negative fixture, tc-ae5. `test/skills/eval-helpers.bash:411` | Correctness | Inconsistent / Informational | performance iter2 escalation; security iter2 F3; api-consistency iter2 #2 | for-author | — | 🟡 Open | — |
| A13 | `tool_called:Bash` (bare) means "a Bash call whose input matches /Bash/", while the new `no_tool_called:Bash` means "no Bash call at all". The two are not negatives of each other despite the comment. `tool_called:Bash=` with an empty pattern passes with no calls. `test/skills/eval-helpers.bash:146-159` | API | Inconsistent | api-consistency iter2 #1 | for-author | — | 🟡 Open | — |
| A14 | Doc accuracy. "Needs a readable /proc" (usage, 037, archive) overstates the `[ -d /proc/self ]` check: on a host where no cwd link is readable, the gate goes silent (Claim 2; security iter2 F2). The log #56 headline credits "every call is denied" to dontAsk and omits `Bash(**)` (Claim 9). The tc-ae4 after-denial test name promises a computed-figure check it doesn't make (Claim 18). | Docs | Mostly Accurate | fact-check iter2 Claims 2, 9, 18; security iter2 F2 | for-author | — | 🟡 Open | — |
---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | The expected-to-fail after-denial tests sit in a `@category fast` suite. Once any arithmetic-eval report exists, `run-tests.sh` adds every `*-eval.bats` to `--fast`, and health-check treats a red `--fast` as blocking, so slow suites stop running. It is green today only because no `output/` exists. `test/skills/arithmetic-eval-eval.bats`, `scripts/run-tests.sh:88-117` | tech-debt-triage #1 (Fix now) | P1 | for-author | C9 (Deferred) — premise changed: correctness, not timing | Fixed |
| C2 | `VERDICT_RE` passes the failure it targets. "…so the stated 19 billion is wrong by a factor of ten" matches `NOT_VERIFIED_RE` and slips past `VERDICT_RE`, as do "is wrong", "overstated", "checks out" and "42.2 km, not 45.2 km". The hedged "could not verify whether the figure is incorrect" is wrongly failed. Suggestion: forbid the correctly computed figure after a denial (tc-ae1 to ae3). `test/skills/arithmetic-eval-eval.bats` | tech-debt-triage #2 | P2 | for-author | — | Fixed |
| C3 | `procs_in_checkout` forks a `readlink` for every same-uid process, and `in_lineage` recomputes the `$$` ancestor walk for each candidate (≈3.7 ms per process in the loaded sandbox), up to 4× per install. `devcontainer-config/install.sh:1116-1154` | performance F1 | Low | for-author | — | 🟢 Open |
| C4 | install-host.bats tests now scan the live /proc (it isn't stubbed like pgrep and docker), so suite time depends on the host's process count. `test/install-host.bats` | performance F2 | Low | for-author | — | 🟢 Open |
| C5 | The install.sh refusal text is inconsistent. The in-checkout paragraph gives no concrete command (siblings give `kill <PID>` / `docker stop`). The lead "an agent is running" also prints for an editor. "/proc is not readable" also fires when `cd "$REPO_ROOT"` fails. The comment above `agent_gate` lists only the old two categories. `devcontainer-config/install.sh:1156-1226` | api-consistency #3; architecture F4 | Minor | for-author | — | Fixed |
| C6 | After-denial grading lives in the eval suite's own helper, outside expected-verdicts.bash, which the other suites use for all grading. | api-consistency #4 | Minor | for-author | — | 🟢 Open |
| C7 | Message wording: "Bash tripwire:" vs "Tripwire:"; `unreadable Bash call(s)`; `FIXTURE_BASH may only be` vs siblings' `must be`; only one of the two FIXTURE_TOOLS errors mentions Bash. | api-consistency #7 | Minor | for-author | — | Fixed |
| C8 | The tripwire is implemented twice (jq in the generator, Python in mode1-equiv), and `after_denial` copies `eval_fixture`'s failed-marker guard. Nothing keeps them in step. | architecture F3; tech-debt #6 | Minor | for-author | — | 🟢 Open |
| C9 | `FIXTURE_BASH=deny-record` pins `dontAsk` for the whole session, but the contract allows other tools alongside Bash. Whether WebSearch/WebFetch/Agent are then denied is unprobed, and the tripwire checks Bash only. Suggestion: require `FIXTURE_TOOLS=Bash` exactly under deny-record. `test/skills/runner-contract.bash` | architecture F5 | Minor (Low) | for-author | — | Fixed |
| C10 | A tripwire hit is masked when the run already failed (`[ -z "$failure" ]` guard), so an executed Bash call shows only as "claude exited N". `test/skills/generate-reports.bash:251` | security-reviewer F4 | Informational | for-author | — | Fixed |
| C11 | The awk de-dup builds its skip set from `procs` text, so a literal `\n<PID>` inside a Claude command line drops that PID from the refusal list. The gate still refuses. `devcontainer-config/install.sh:1180` | security-reviewer F5 | Informational | for-author | — | Fixed |
| C12 | The CLAUDE_FLAGS refusal misses a tab-prefixed `--permission-mode` and `--permission-prompt-tool`. | fact-check Claim 32 scope | Informational | for-author | C4 (Won't-Fix) — partially superseded under deny-record | Fixed |
| C13 | The generic `no_tool_called` tests sit in the skill-specific `mode1-equiv.bats`; that file isn't skill-prefixed; `FIXTURE_BASH` starts a per-tool setting pattern; `~tol` is relative only. | architecture F7; api-consistency #8-10 | Informational | for-author | — | 🟢 Open |
| C14 | `install.sh` is 1298 lines. Revisit when the next gate class lands or the file passes ~1500 lines. T90 fault-injects by running `sed` on the script's own source. | tech-debt #5 | P3 (defer) | for-author | — | 🟢 Open |
| C15 | Plan state lives in gitignored plan docs that tracked docs point at. | tech-debt #4 | P3 | for-author | — | 🟢 Open |
| C16 | The deny-record flag guard is bypassable through `CLAUDE_MODEL`: `--model $CLAUDE_MODEL` is expanded unquoted after the pinned flags and never scanned, so `CLAUDE_MODEL='m --permission-mode bypassPermissions'` reached argv (probed with the stub). Unlisted flags also pass (`--setting-sources`, a repeated `--tools`, `--mcp-config`, `--add-dir`, `--agents`). A denylist of flag names cannot hold. `test/skills/generate-reports.bash:124-134, 160-163` | security iter2 F1; architecture iter2 F3 | Low | for-author | C4 (Won't-Fix) not reopened; this is the new guard failing its own purpose | 🟢 Open |
| C17 | `Bash(**)` rests on unpinned CLI behavior (the CLI floats to latest). If an update makes `Bash(**)` remove the tool, there are no tool_use events, the tripwire passes, and every fixture reads as "the model didn't route". No CLI version is recorded per run. | tech-debt iter2 A; security iter2 F4 | P2 | for-author | — | 🟢 Open |
| C18 | Tests call the assert functions directly, so the A5/A6 fixes in the `eval_fixture` dispatcher are untested. Reverting them keeps every test green. | api-consistency iter2 #3 | Minor | for-author | — | 🟢 Open |
| C19 | A misspelled `FIXTURE_BASH` with `FIXTURE_TOOLS=Bash` is reported as a FIXTURE_TOOLS error, because the value is validated after the loop that reads it. | api-consistency iter2 #4 | Minor | for-author | — | 🟢 Open |
| C20 | The refusal leads with "an agent is running" even when only an editor or shell is in the checkout; the header's parentheses are unlike its siblings; the helper comment says "Exit 2/3" where siblings say "Returns". | api-consistency iter2 #5 | Minor | for-author | — | 🟢 Open |
| C21 | The deny-record flags live once in code and are restated in prose in four places (one has already drifted, see A14). Suggested: one `DENY_RECORD_FLAGS` array. | architecture iter2 F3, F5 | Minor | for-author | — | 🟢 Open |
| C22 | The Q-064 entry understates option [2]'s cost. It needs a new output class (processes whose cwd is unknown), edits at about five sites, and ideally tagged lines from `procs_in_checkout`. The security review adds a candidate [3], "skip but name": a NOTE listing each skipped same-uid process. A PID-namespaced terminal is a residual to list. | architecture iter2 F4; security iter2 F2 | Minor | for-author | — | 🟢 Open |
| C23 | Opt-in after-denial grading never runs by default and has no "when to opt in" guidance; its regexes have no offline tests. The figure patterns miss `1.9B` and `29 percent`, and match neighbours such as `21.9 billion` and `129%`. | tech-debt iter2 B, C | P3/P4 | for-author | — | 🟢 Open |
| C24 | The shared dispatcher arm still carries one skill's name and contract (`mode1_equiv:`, `mode1-equiv.py`, the EXPREOF/AST comment); naming residue only after A6. | architecture iter2 F1 | Minor | for-author | — | 🟢 Open |
---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `skill-fixtures` / 2026-09-24 (C4) | CLAUDE_FLAGS/CLAUDE_MODEL unvalidated | 🟢 → Won't-Fix | Operator's own machine | Inherited. The branch now validates CLAUDE_FLAGS under deny-record; the remaining gaps are C12. |
| `skill-fixtures` / 2026-09-24 (C5) | Eval check-name drift | 🟢 → Deferred | Rename churn | Inherited; A5/C13 are new instances of it. |
| `skill-fixtures` / 2026-09-24 (C9) | Eval suites join --fast once reports exist | 🟢 → Deferred | Timing unmeasured | Premise changed: C1 is a correctness issue (known-failing tests block health-check), not timing. |
| `skill-fixtures` / 2026-09-24 (C6) | Runners sourced into generator scope | 🟡 → Acknowledged | Fast validation test | Inherited — not re-flagged. |
| `skill-fixtures` / 2026-09-24 | trap RETURN on set -e; --tools variadic; RUNNER_ALLOWED_TOOLS naming | 🟢 → Won't-Fix | as logged | Inherited — not re-flagged. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| install.sh's own lineage is exempt: `$$` inside command substitutions is still install.sh's PID, so the scan's own subshells are skipped | ✅ Confirmed | `install.sh` `in_lineage` — "[ \"$p\" = \"$$\" ] && return 0"; executed probe `docs/reviews/execution-logs/cfc-5ddf804-lineage-probe.txt` | fact-check (executed) | for-orchestrator-synthesis |
| The generator tripwire voids runs with an undenied Bash call, including sub-agent calls, multiple result events and a missing or unreadable transcript | ✅ Confirmed | `generate-reports.bash` tripwire jq; `cfc-5ddf804-tripwire-probes.txt` | fact-check (executed) | for-orchestrator-synthesis |
| CLAIM_ACCURACY arithmetic in expected-verdicts is correct | ✅ Confirmed | `cfc-5ddf804-claim-accuracy.txt` (python3) | fact-check (executed) | for-orchestrator-synthesis |

The security critic routed three endorsement claims (the evaluator always comes from SKILL.md, the tripwire re-check, the runner-contract Bash admission). They are **pending execution verification**, because Stage 2.5 is skipped on a loop pass.

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied. (Contextual critic test-strategy was not selected: every source change ships with tests.)

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `mode1-equiv.py:33-52` | FC-22, api #1, sec F3, arch F2 | distinct defects: none. All four state the same complete mechanism; merged as A3. |
| 2 | `install.sh:1140-1154` | FC-6/10b, sec F1, perf F1 | distinct defects: fail-open on an unreadable cwd (A1) vs the fork cost (C3). |
| 3 | `eval-helpers.bash:402-424` | arch F1, api #2, api #6 | distinct defects: path coupling (A6) vs the argument shape (A5). |
| 4 | `arithmetic-eval-eval.bats` after_denial | tech-debt #1, #2, api #4, FC-19 | distinct defects: gate placement (C1), regex precision (C2), grading location (C6), test naming (A8). |

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
