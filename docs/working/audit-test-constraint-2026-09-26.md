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
| A | test/*.bats agents-gemini-sync … merge-safety (16) | pending |
| B | cc-isolated-functions, init-firewall-rules, test_cc_sni_proxy.py | pending |
| C | install-host, link-claude-home-wiring, hermeticity-lint | pending |
| D | test/*.bats lite-review-grammar … worktree-cleanup-functions (17) | pending |
| E | test/hooks/*, test/scripts/* (14) | pending |
| F | test/skills non-templated suites (~17) + arithmetic-eval/mode1-equiv.py | pending |
| G | test/skills *-eval.bats / *-format.bats pairs (~46) | pending |

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
