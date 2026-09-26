# Audit: do the tests constrain production behavior? (2026-09-26)

Driven by `/loop check that all tests in the repo constrain production behavior`.

**Question per test:** is there a plausible regression in *production* code
(scripts/, hooks/, skills/*/SKILL.md + helpers, install/, global-instructions/,
workflows/, guides/ — anything a user runs or an agent reads) that would turn
this test red? A test that cannot go red on any production change is vacuous.

**Vacuity patterns looked for**

- V1 tests a fixture, stub, or inline copy of the logic instead of the real artifact
- V2 assertion cannot fail (no status/output check after `run`, `|| true`, regex that matches anything, grep of the test file itself)
- V3 the unit under test is itself stubbed/mocked away
- V4 permanently skipped, or skipped in every environment the runner uses
- V5 asserts only on the harness/helper, with no path back to production
- V6 tautology: expected value derived from the same code path as the actual
- V7 weak: exercises production but a named plausible regression still passes

**Verdicts:** `OK` · `WEAK` (V7, fixable by tightening) · `VACUOUS` (V1–V6) · `META` (tests test-infra by design — legitimate only if that infra gates production tests).

Fixes are verified by mutation: break the production line, watch the test go red, restore.

## Batches

| Batch | Scope | Status |
|---|---|---|
| A | test/*.bats agents-gemini-sync … merge-safety (16) | done |
| B | cc-isolated-functions, init-firewall-rules, test_cc_sni_proxy.py | done |
| C | install-host, link-claude-home-wiring, hermeticity-lint | done |
| D | test/*.bats lite-review-grammar … worktree-cleanup-functions (17) | done |
| E | test/hooks/*, test/scripts/* (14) | done |
| F | test/skills non-templated suites (~17) + arithmetic-eval/mode1-equiv.py | done |
| G | test/skills *-eval.bats / *-format.bats pairs (~46) | done |

## Findings

_(filled per iteration)_

### Batch A (16 files): 9 OK, 2 META, 5 WEAK
- VACUOUS test `cross-model-review-stage1.bats:76`: the dry run passes no `--models`, so the $0.00 branch is unreachable. Two mutations stay green.
- `function-inventory.bats` checks existence only. Gutting `generate_morning_summary` (`return 0`) stays green repo-wide, and the `-eq 9` check at :78 is a tautology.
- `claude-headless-flags.bats:141`: `IDEAS_FLAGS=()` stays green, because the flag array is never tied to `claude_headless_flags`.
- `lever-measurement-drift.bats`: ~73% matches twice, the awk check is a literal, and `0/8` matches two log rows.
- `code-review-gate.bats:83` only reaches the empty-nonce path. :123 in stage1 needs a positive control.

### Batch B (3 files): mostly OK
- VACUOUS `test_cc_sni_proxy.py:195`: the SNI can't resolve, so the allowlist check going missing stays green. No test constrains allowlist enforcement. Nothing runs this file (bats-only runners), and the documented `-m unittest` command raises an ImportError.
- VACUOUS for the named property:
  - `cc-isolated-functions.bats:537`: the regex alternation matches the bare assignment, so dropping `export CC_CONFIG_DIR` stays green.
  - `cc-isolated-functions.bats:1037`: same defect for `CC_CONFIG_HASH`.
- WEAK:
  - `cc-isolated-functions.bats:771` (Gate 1h baked-skill fallback)
  - `cc-isolated-functions.bats:786` (archive mkdir)
  - `cc-isolated-functions.bats:765` (status-only)
  - `init-firewall-rules.bats:1120` (lock released before the probes)
  - `test_cc_sni_proxy.py:202` (root refusal never reached)

### Batch C (3 files): OK
- The one META finding is `install-host.bats:1117` T63, which only greps docs/decisions and docs/working.
- Hardening only: the tamper-landed marker in T28, and the non-empty guard at `link-claude-home-wiring.bats:150/:161`.

### Batch D (17 files): 11 OK, 3 WEAK, 3 VACUOUS
- **FIXED** bd01eb5: `round-report-schema.bats`. Every test skipped because the untracked runtime file is absent. The contract moved to `round-log-functions` on the writer; mutation goes red.
- **FIXED**: `pivot-consistency.bats:76`. Asymmetries used to be warnings only; they now fail unless listed in KNOWN_ONE_WAY. `\bDD\b` tightened; mutation goes red.
- **FIXED**: `paper-queue.bats:257`. Added a status check and a positive assertion.
- **FIXED (partly)**: `sandbox-tool-map-drift.bats`. The live checks skip in the sandbox by nature, because the allow list lives only on the host. Added REQUIRE_LIVE_SETTINGS=1 strict mode plus fixture tests showing each check can go red. The live check on the host is queued as Q-066 (you: terminal).
- QUEUED Q-065 (you: judgment): `si-input-rejected-history.bats`. 12 of its 14 tests exercise `prepend_si_input_rejected_history`, which has no caller (dead since 06903d6).
- **FIXED**: `worktree-cleanup-functions.bats:40/:51` claimed to guard `${arr[@]:-}` against `set -u`, which bash ≥4.4 cannot reproduce. Reworded to the drain/no-op behaviour the tests actually constrain.

### Batch E (14 files): 5 OK, 9 WEAK (1 VACUOUS test)
- VACUOUS test `log-usage.bats:283`: an inline copy of the jq filter that never invokes the hook.
- `health-check.bats`: 10 tests grep section headers, and gates 2–4 and 6–15 have no negative test (`check_workflow_crossrefs` → `if false` stays green).
- `self-improvement-smoke.bats:97` claims to check main-loop wiring, but writes the call sequence out by hand.
- `live-verify-gate.bats:266`: a hand copy of `enforcement_files()`.
- Loose fixtures and regexes:
  - `skill-paths.bats:50`
  - `skill-usage-report.bats:88` (the check matches the date)
  - `claude-config-audit.bats:80` (merged streams) and `:231`
  - `log-usage-post.bats:128` (passes on an empty log)
  - `utility-smoke.bats:20`

### Batch F (18 files): 7 OK, 4 META (legitimate), 3 WEAK, 4 VACUOUS
- `cowen-critique/dimensions.bats` reads a stale committed review, and stubbing SKILL.md stays green. `yglesias-critique/dimensions.bats` skips 8 of 8 because its review file doesn't exist. Nothing runs either suite with REPORT_PATH set.
- `code-review-format-contract.bats`: 16 of 19 tests assert only the golden fixture. Gutting the row contracts in `rubric.md` stays green.
- `code-fact-check-edge-cases.bats` and `fact-check-edge-cases.bats` (44 tests) skip without reports, and the runner shows green. With reports present they ignore `.failed`.
- WEAK:
  - `divergent-design-router.bats` (the frontmatter satisfies the body checks)
  - `code-review-factcheck-replication.bats:109` (comment lines satisfy the grep)
  - `code-review-soundness-crosscheck.bats:117` (the channel range is too wide)

### Fix dispatch (iteration 1)
Four fix agents are editing disjoint files; the parent commits. Their groups:
- fixA: batch A, plus the Gate 1h behavioural tests
- fixB: batches B and C
- fixF: batch F
- fixE: batch E

### Batch G (47 skill *-eval/*-format suites): systemic V4/V1 at the template level
- **T1:** `run-tests.sh:88-114` drops every `*-eval`/`*-format` suite unless some `test/skills/*/output/*.md` exists. The output dir is gitignored and no runner generates reports, so all 47 are skipped everywhere while the gate shows green. The skip is noted only on stderr.
  - `arithmetic-eval-format.bats` needs no report at all: it lints SKILL.md, and a mutation turns it red. It is still dropped because of its filename.
- **T2:** the gate is global, so one `.md` anywhere enables all 47 suites. The format suites then grade *committed* `docs/reviews/*.md`, which are frozen, some are 1–6 months older than their SKILL.md, and 13 of the paths don't exist.
  - An empty `skills/security-reviewer/SKILL.md` still passes 18/18.
  - The eval suites skip.
- **T3:** there is no freshness stamp tying a generated report to the SKILL.md, runner and fixture that produced it.
- **T4:** a missing report skips, and a skip counts as ok.
- **T5:** severity, mechanism and verdict are not checked against the same finding. `cites_pattern` also matches fixture echoes and mandated headers (`scop` matches `**Scope:**`).
- **T6:** fixtures with only absence checks pass on a refusal (sec8, dd4).
- Per skill: the eval cites are weak for security, code-fact-check (digit alternations matched by the date), fact-check (`web_search_used` is the literal "Sources"), ui-visual-review, and api-consistency.
- Format suites that are VACUOUS:
  - `matrix-analysis:77-80`
  - `design-space-situating` rows 3 and 6, plus Hand-off
- Format suites that contradict SKILL.md:
  - `ui-visual-review` requires `##` where the skill uses `###`
  - `cowen`/`yglesias` require sections the skill says to omit
- `expected-verdicts`: no empty or `.*` patterns; the fixture↔test mapping is complete.
- Constraint: regenerating reports is model compute. Memory "run-a8-measurement-after-settling" says no big compute yet, so the harness fixes land first and regeneration is queued as a question.

### Fix status (iteration 1)
- A: 86c8e65. B/C: 4a4d0ef. D: bd01eb5, b1780ac, 0b1ebf4. F: ab8f13f. E: next commit.
- Two things for later from fixE, both in scripts/health-check.sh and not changed:
  - An unreproduced one-off `✗ fact-check: missing 'when' field` during a concurrent-edit window; it was clean on 7 reruns.
  - `check_feature_integration` aborts silently under `set -e` if si-functions.sh held only one-line function definitions, because the `grep -v` finds nothing. The real file isn't like that.
- G: harness fix (T1–T6) in progress. The per-skill assertion pass (expected-verdicts cites, *-format assertions vs SKILL.md) follows it.

## Outcome (2026-09-26)

All 118 test files audited, and every VACUOUS/WEAK finding fixed or routed to a question. Each fix was checked by mutation: the named production break stayed green before the fix and goes red after it.

| Batch | Commits |
|---|---|
| A | 86c8e65 |
| B/C | 4a4d0ef |
| D | bd01eb5, b1780ac, 0b1ebf4 |
| E | 920916b |
| F | ab8f13f |
| G | 48680e2 (harness T1–T6), 69b379f (per-skill verdicts/format; synthetic good/bad reports 129/129) |

Final state: `run-tests.sh --fast` gives 1030 ok, and `--slow` gives 261 ok, both exit 0. 50 report-dependent suites are listed NOT RUN until reports are regenerated.

**Open, needs you:**
- Q-065: dead `prepend_si_input_rejected_history`
- Q-066: host strict run of the sandbox drift check
- Q-067: when to regenerate skill eval reports

**Accepted residuals (not vacuity):**
- `cross-model-review` dropping `pricing and` is an equivalent mutant, so no test can catch it.
- `drop_fixture_echo` drops whole lines only.
- The pre-mortem finding block is the whole section when narratives have no headings.
- The fact-check runner records no transcript, so `web_search_used` stays a text check.
- c5.1's expected verdict is arguable.
- health-check gates 9 and 11 have no negative test.
- The security, performance, api-consistency and architecture format suites require `##` sections, although SKILL.md never fixes the report's heading level. This is over-constraint (a false-red risk), not under-constraint. Past reports used `##`.
- `check_feature_integration` has a latent `set -e` edge.
