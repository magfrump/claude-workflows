Commit: 5ddf804

# API Consistency Review: branch skill-fixtures (Q-062 [2], Q-063 [1])

**Scope:** `git diff main...HEAD` at 5ddf804 (install.sh agent gate; the skill-fixture harness's FIXTURE_BASH=deny-record, `mode1_equiv:`, `no_tool_called:`, mode1-equiv.py, the arithmetic-eval fixture set and eval suite; docs)
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (Stage-1, commit 5ddf804). Execution results and code behaviour are taken from that report, cited by claim number. The three probes in this review that I ran myself are marked "(probe)".
**Settled, not re-litigated:** override-log C4 (CLAUDE_FLAGS/CLAUDE_MODEL unvalidated; this branch now validates CLAUDE_FLAGS only under deny-record, which narrows C4's premise without contradicting it), C5 (eval check-name drift), C9, C6, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming.

## Baseline Conventions

Surfaces surveyed: `test/skills/runner-contract.bash`, `test/skills/generate-reports.bash` (header and `generate_one`), `test/skills/eval-helpers.bash` (whole `eval_fixture` dispatch and every `assert_*`), `test/skills/eval-helpers-transcript.bats`, `test/skills/divergent-design/expected-verdicts.bash` plus the `Check formats` headers of 9 other `expected-verdicts.bash`, `devcontainer-config/install.sh` (`agent_gate` in full, every `ERROR:`/`NOTE:` line), and exit-code use in `scripts/`, `hooks/` and `install.sh`.

- **Runner settings** are `FIXTURE_<DIMENSION>` shell variables. Each names a property of the whole run (`FIXTURE_TOOLS`, `FIXTURE_MODE`, `FIXTURE_TRANSCRIPT`). Values are short lowercase words or `0/1`, and `reset_runner_settings` clears every one. Errors look like `Error: $label: <SETTING> must be <a>, <b> or <c>, got '<value>'` (runner-contract.bash:51, :94). `FIXTURE_TOOLS` uses "may only name".
- **Generator errors** are `Error: $RUNNER_FILE sets <SETTING>=<v>, which needs …` (generate-reports.bash:110). Failure markers written to `<fixture>.failed` are lowercase plain phrases: `claude exited N`, `the result event is an error`, `no result event in the stream` (:230, :245-246).
- **Eval checks** in `KEY_CHECK` are `snake_case` names joined by `;;`. A name is either a bare word (`verdict_match`, `format_check`) or `<name>:<arg>`, and an arg can be `<Key>=<value>` (`field_match:`, `tool_called:`). Negative checks mirror their positive twin's argument shape with a `no_` prefix: `field_match:F=v` / `no_field:F=v`, `cites_pattern:ERE` / `no_pattern:ERE`, `severity_match` / `no_severity:`. Every check is generic across skills, and skill-specific behaviour is reached through `$skill` (`format_check` → `${skill}-format.bats`, `claim_heading_re $skill`). Each `assert_<check>` prints its diagnostic on stdout and returns 1.
- **Eval suites** (`<skill>-eval.bats`) call only `eval_fixture`. Expectations live in `expected-verdicts.bash`, the file health-check reads.
- **Script CLIs**: exit 2 means usage or a failed setup (install.sh:1248, `archive/benchmark/scripts/crb-audit-clone.sh:41`, `scripts/lite-review.py:237`). Exit 1 means the check refused.
- **install.sh gate messages** go through one `ERROR: an agent is running …` block with one paragraph per category. Each paragraph has a header of the form `<What> (<columns>):`, the indented list, and then `Stop them: <concrete action>` (install.sh:1208-1222). A missing tool fails closed with a remedy (`Install procps and rerun.`, :1162) and cites the Q number.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `FIXTURE_BASH` | runner setting | `FIXTURE_TOOLS`, `FIXTURE_MODE`, `FIXTURE_TRANSCRIPT` | `test/skills/runner-contract.bash:31-34`, `generate-reports.bash:13-30` | Consistent prefix. First setting named after one *tool* rather than a run dimension (Finding 9) |
| `deny-record` (value) | enum value | `inline`/`repo`/`tree`, `0`/`1`, `none` | `runner-contract.bash:49-55,91-97` | Consistent (lowercase). First hyphenated value; acceptable |
| `mode1_equiv:` | eval check | `tool_called:`, `subagents_min:`, `field_match:`, `format_check` | `test/skills/eval-helpers.bash:100-161` | Minor: skill-specific check hard-wired in the shared dispatcher (Finding 6) |
| `no_tool_called:` | eval check | `tool_called:<Tool>=<ERE>`, `no_field:`/`field_match:`, `no_pattern:`/`cites_pattern:` | `eval-helpers.bash:114-161` | Inconsistent: does not mirror its twin's `<Tool>=<ERE>` shape, and the mirrored spelling passes silently (Finding 2) |
| `assert_no_tool_called` | function | `assert_no_field`, `assert_no_verdict`, `assert_tool_called` | `eval-helpers.bash:236-285,372` | Consistent (`assert_<check>`) |
| `assert_mode1_equiv` | function | `assert_subagents_min`, `assert_tool_called` | `eval-helpers.bash:372-395` | Consistent |
| `mode1-equiv.py` | script | `lite-review.py`, `cross-model-review.py`, SKILL.md's `check.py` | `scripts/*.py` | Consistent kebab-case. CLI conventions: Finding 5 |
| `<v>[~tol]\|...` value spec | check-arg syntax | `\|`-separated ERE alternatives in `assert_verdict`/`assert_field` | `eval-helpers.bash:180-200,262-270` | Consistent use of `\|`. `~tol` is new; relative-only (Finding 10) |
| `mode1-equiv.bats` | test file | `arithmetic-eval-gate.bats`, `eval-helpers-transcript.bats` | `test/skills/*.bats` | Minor: not skill-prefixed, and it also holds the generic `no_tool_called` tests (Finding 8) |
| `arithmetic-eval-eval.bats` | test file | `divergent-design-eval.bats`, `fact-check-eval.bats` | `test/skills/*-eval.bats` | Consistent name. Body diverges (Finding 4) |
| `after_denial`, `VERDICT_RE`, `NOT_VERIFIED_RE` | suite-local helper/consts | none | none — searched `test/skills/*-eval.bats` for `load_eval_report`/`assert_report_*` | New category (Finding 4) |
| `tc-ae1…tc-ae5-*.md` | fixture names | `tc-dd1-…`, `tc-sec1-…`, `tc-c2.4-…` | `test/skills/*/fixtures/` | Consistent (`tc-<skill abbrev><n>-<planted defect>`) |
| `routes` / `does not route` | EXPECTED_VERDICT values | same values | `test/skills/divergent-design/expected-verdicts.bash:28-40` | Consistent |
| `Bash tripwire: …` / `Tripwire: …` | failure-marker / diagnostic | `claude exited N`, `the result event is an error` | `generate-reports.bash:230,245-246` | Minor: two spellings of one condition, and a different register from the siblings (Finding 7) |
| `FIXTURE_BASH may only be …` | error message | `FIXTURE_MODE must be …`, `FIXTURE_TRANSCRIPT must be …` | `runner-contract.bash:51,94` | Minor (Finding 7) |
| `ppid_of`, `in_lineage`, `procs_in_checkout` | internal shell functions | `agent_gate`, `has_ctrl`, `vis_or_die` | `devcontainer-config/install.sh` | Consistent snake_case (internal) |
| "Other processes of uid N working inside …" | refusal paragraph | "Claude Code processes of uid N (PID and command line):", "Running cc-isolated containers (name and project id):" | `install.sh:1208-1222` | Minor: header and stop-line shape differ (Finding 3) |
| `/proc is not readable …` | refusal message | `pgrep is not installed … Install procps and rerun.` | `install.sh:1160-1162` | Minor: no remedy, and it can misname the cause (Finding 3) |

## Findings

#### 1. `mode1_equiv:`'s stated wrapper contract is not what WRAPPER_RE enforces (Claim 22 escalation)

**Severity:** Inconsistent
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:7-9, 33-40, 116-127`; contract text at `test/skills/eval-helpers.bash:411-417`, `test/skills/arithmetic-eval/expected-verdicts.bash:14-17`, `docs/decisions/log.md` row 56
**Move:** 3 (consumer contract), 8 (what the documented field actually holds)
**Confidence:** High
**Legibility-target:** a fixture author or reviewer who reads "wrapper exact" and trusts that a pass means the command was SKILL.md's block and nothing else.

Evidence. The contract is stated three ways:
- docstring :7-9: "requires the shell wrapper to be SKILL.md's Mode 1 wrapper exactly … with only blank or `#` comment lines after the closing EXPREOF"
- eval-helpers.bash:413: "(wrapper exact, program AST-equal to SKILL.md's)"
- expected-verdicts.bash:15: "(wrapper exact, program AST-equal)"

The regex (whole definition):
```
WRAPPER_RE = re.compile(
    r"\A\( ulimit -t 5 -v 1000000 2>/dev/null; timeout 5 python3 -c '\n"
    r"(?P<program>[^']*)\n"
    r"' \) <<'EXPREOF'\n"
    r"(?P<expr>.*?)\n"
    r"EXPREOF(?P<tail>(\n[ \t]*(#[^\n]*)?)*)\Z",
    re.S,
)
```
Because of `\Z`, the lazy `expr` group grows until the *last* `EXPREOF` line that has only comment lines after it. A command with shell between two `EXPREOF` lines is therefore classified as Mode 1. (probe) Against a block whose heredoc body was followed by `EXPREOF` / `touch pwned` / `EXPREOF`, the script printed:
```
  call 1: Mode 1, expression '3600 / 0.003 * 1000\n1 + 1\nEXPREOF\ntouch pwned' -> None
```
It still fails, but only because SKILL.md's evaluator rejects the `EXPREOF` Name token (Claim 22: no false pass found). Consumers therefore get three problems:
1. The diagnostic calls a command bash would read as two heredoc bodies plus a `touch` "Mode 1".
2. The pass/fail guarantee rests on the behaviour of the evaluator in another file (it parses all of stdin in `mode="eval"` and rejects `ast.Name`), not on the wrapper check the contract names. A future SKILL.md evaluator that reads line by line, or one that allows names such as `pi`, would turn this into a false pass with no test catching it.
3. SKILL.md's own rule, "check the untrusted expression contains no bare line equal to the delimiter `EXPREOF`; if it does, reject it", has a mirror in the checker's docs but none in its code.

The fact-check's Claim 15 shows the DD doc also promises a "no EXPREOF line" check. So the contract is stated in four places, and the code is the one that differs.

The existing test "shell after the closing EXPREOF fails" (mode1-equiv.bats:876-884) covers only the single-`EXPREOF` shape.

**Recommendation:** Make the code match the documented contract. Treat a match whose `expr` contains a line equal to `EXPREOF` as "not the Mode 1 wrapper" (for example, `re.search(r"^EXPREOF$", expr, re.M)` → `continue`), and add a two-`EXPREOF` case to mode1-equiv.bats. Keep the docs as they are once the code enforces them.

#### 2. `no_tool_called:` does not mirror `tool_called:`'s argument shape, and the mirrored spelling passes silently

**Severity:** Inconsistent
**Location:** `test/skills/eval-helpers.bash:153-154, 396-408` (dispatch and `assert_no_tool_called`, read in full); comment at :74-77
**Move:** 2 (naming against the grain), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** a fixture author writing a negative transcript check by analogy with `tool_called:`.

Precedent: negative checks take their positive twin's argument shape (`field_match:<F>=<v>` / `no_field:<F>=<v>`; `cites_pattern:<ERE>` / `no_pattern:<ERE>`), used in `test/skills/eval-helpers.bash:114-127` and in `test/skills/*/expected-verdicts.bash`.

`tool_called:<Tool>=<ERE>` means "some `<Tool>` call's input matches `<ERE>`". Its new twin `no_tool_called:<Tool>` takes the tool name only. The whole argument is passed on as the tool name:
```
      no_tool_called:*)
        assert_no_tool_called "${check#no_tool_called:}" || failed=1
```
So an author who writes the natural mirror, `no_tool_called:Bash=rm`, asks for "no call of a tool named `Bash=rm`", and that check can never fail. (probe) With a transcript holding one Bash call, `assert_no_tool_called "Bash=touch"` returned 0. This is the silent-pass failure mode that eval_fixture's comment at :74-77 exists to prevent. That comment lists the absence-only checks "(no_severity:, no_verdict:, no_field:, no_pattern:)", and `no_tool_called:` was not added to it.

**Recommendation:** Accept the mirrored shape: `no_tool_called:<Tool>[=<ERE>]`, where a present `=<ERE>` means "no `<Tool>` call whose input matches". At minimum, refuse a tool name containing `=` or any non-`[A-Za-z]` character (the same format `FIXTURE_TOOLS` enforces) with an "Unknown check" style failure. Add `no_tool_called:` to the absence-only list at :74-75.

#### 3. The new install.sh refusal paragraph and /proc error break the shape of their siblings

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1156-1157, 1140-1143, 1173-1178, 1204-1225` (`agent_gate` and `procs_in_checkout` read in full)
**Move:** 4 (error consistency), 3 (documentation drift)
**Confidence:** High
**Legibility-target:** the user at the refusal, deciding what to stop and how.

Precedent: every gate paragraph is `<What> (<columns>):` / list / `Stop them: <concrete action>`, used in `devcontainer-config/install.sh:1208-1210, 1219-1221`. A missing prerequisite gives a remedy, as at install.sh:1160-1162 ("Install procps and rerun.").

Evidence:
```
      echo "       Claude Code processes of uid $(id -u) (PID and command line):"
      ...
      echo "       Stop them: end each Claude Code session (/exit), or kill <PID>."
    ...
      echo "       Other processes of uid $(id -u) working inside $REPO_ROOT (Q-062; an"
      echo "       agent may have left them running), PID and command line:"
      ...
      echo "       Stop them, or cd each one out of the checkout (an editor or shell counts)."
```
- The stop line gives no concrete action where the siblings give `kill <PID>` or `docker stop <name>`.
- The header moves the columns out of the parenthetical.
- The paragraph sits under the unchanged lead line "ERROR: an agent is running.", which is now also printed when the only hit is the user's own editor or shell. The paragraph itself says "an editor or shell counts", so the lead line and the paragraph disagree. The user accepted these refusals, but the wording should not call them an agent.
- `ERROR: /proc is not readable …` is printed for any non-zero return from `procs_in_checkout`, including `root="$(cd "$REPO_ROOT" && pwd -P)" || return 2`, so an unreadable checkout path is reported as a /proc problem. Unlike the pgrep sibling, it gives no remedy.
- The `agent_gate` header comment (:1156-1157, "when a Claude Code process or a cc-isolated container runs") was not updated to include the new category.

**Recommendation:** Use `Other processes of uid N working inside <root> (PID and command line):` followed by `Stop them: kill <PID>, or cd each one out of the checkout (an editor or shell counts).` When `procs` and `ctrs` are empty, soften the lead line, for example to "an agent, or a process working in the checkout, is running". Return a distinct code, or print a distinct message, for the `cd` failure. Add a remedy to the /proc line ("run on Linux with /proc mounted"). Update the :1156 comment.

#### 4. arithmetic-eval-eval.bats grades behaviour outside expected-verdicts.bash

**Severity:** Minor
**Location:** `test/skills/arithmetic-eval-eval.bats:326-342, 368-382`
**Move:** 1 (baseline), 3 (consumer contract: the expected-verdicts file as the single machine-readable source)
**Confidence:** High
**Legibility-target:** a maintainer or health-check reading `expected-verdicts.bash` to learn what a fixture is graded on.

Precedent: every other `<skill>-eval.bats` calls only `eval_fixture`, and expectations live in `KEY_CHECK` ("Machine-parseable expected verdicts … Used by health-check"), in `test/skills/*-eval.bats` and `test/skills/*/expected-verdicts.bash`. None of those suites calls `load_eval_report` or `assert_report_*` directly.

The four "after the denial" tests use a local `after_denial` with two suite-level regexes (`VERDICT_RE`, `NOT_VERIFIED_RE`). They also re-implement the `.failed` guard from `eval_fixture` but not its empty-report guard, although an empty report does fail `NOT_VERIFIED_RE`. The design reason is sound: keep the second behaviour from masking routing. The cost is that `expected-verdicts.bash` for these fixtures no longer describes everything they are graded on, and a fixture added without an `after_denial` test drops silently out of that grading.

**Recommendation:** Either add a second, optional array (for example `KEY_CHECK_AFTER["<fixture>"]="cites_pattern:…;;no_pattern:…"`) that the harness evaluates the same way, or at least list the after-denial expectations in the `expected-verdicts.bash` header comment so the two files stay discoverable from each other.

#### 5. mode1-equiv.py's CLI mixes usage and setup failures into "no match", against its docstring

**Severity:** Minor
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:24, 43-52, 77-82, 98-137`
**Move:** 4 (error consistency), 3 (documentation drift; fact-check Claim 26)
**Confidence:** High
**Legibility-target:** whoever reads a red routing test and must tell "the model did not route" from "the harness broke".

Precedent: usage and setup errors exit 2, used in `devcontainer-config/install.sh:1248`, `scripts/lite-review.py:237` and `archive/benchmark/scripts/crb-audit-clone.sh:41`.

The docstring says "Exit 0 on a match, 1 otherwise; diagnostics on stdout." Wrong argc (`sys.exit(__doc__)`), a SKILL.md whose block no longer matches `WRAPPER_RE` (`sys.exit("mode1-equiv: SKILL.md's own Mode 1 block does not match …")`), a missing transcript and a malformed spec (`float('abc')` → traceback) all exit 1, and they write to stderr. (probe) `abc` gave `ValueError: could not convert string to float: 'abc'`, exit 1. In a paid eval run, a SKILL.md edit therefore shows up as five routing failures, with the real cause in stderr. mode1-equiv.bats's extraction test catches that case in the fast suite, which limits the damage.

**Recommendation:** Exit 2 for usage, spec and reference-extraction errors, with a one-line `mode1-equiv:` message rather than a traceback. Correct the docstring to say "diagnostics on stdout; setup errors on stderr, exit 2".

#### 6. `mode1_equiv:` is a skill-specific check hard-wired into the shared dispatcher

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:156-157, 410-421`
**Move:** 2 (naming), 1 (baseline)
**Confidence:** Medium
**Legibility-target:** the next author who needs a command-equivalence check for another skill.

Precedent: skill-specific behaviour is reached through `$skill`, not through a hard-coded skill path: `format_check` → `${BATS_TEST_DIRNAME}/${skill}-format.bats` and `claim_heading_re "$1"`, in `test/skills/eval-helpers.bash:30-35, 159-161`.

`assert_mode1_equiv` hard-codes `arithmetic-eval/mode1-equiv.py` and `skills/arithmetic-eval/SKILL.md`, and ignores the `$skill` that `eval_fixture` already holds. So `mode1_equiv:` used in any other skill's `KEY_CHECK` would silently grade against arithmetic-eval's SKILL.md. The name also under-describes the check: it enforces the deny-record tripwire as well as equivalence. `equiv` is a new suffix beside `_match`, `_called` and `_min`.

**Recommendation:** Pass `$skill` through and resolve `${skill}/mode1-equiv.py` and `skills/${skill}/SKILL.md`, failing with a clear message if the script is absent. Or leave the paths and document in the eval-helpers comment that the check is arithmetic-eval-only. Renaming is optional.

#### 7. The same tripwire condition has two spellings, and the new messages drift from sibling wording

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:249-259`; `test/skills/arithmetic-eval/mode1-equiv.py:111`; `test/skills/runner-contract.bash:59, 74, 113`
**Move:** 4 (error consistency), 2
**Confidence:** High
**Legibility-target:** someone grepping `.failed` markers or eval output.

Precedent: failure markers are lowercase plain phrases (`claude exited N`, `the result event is an error`), and enum errors say `must be …, got '…'`. Both are used in `test/skills/generate-reports.bash:230, 245-246` and `test/skills/runner-contract.bash:51, 94`.

Evidence:
- generator: `failure="Bash tripwire: $undenied Bash call(s) not in permission_denials (may have executed)"`, with `|| undenied="unreadable"`, which renders "Bash tripwire: unreadable Bash call(s) …"
- mode1-equiv.py: `"Tripwire: {len(undenied)} Bash call(s) not in permission_denials (may have executed): {undenied}"`
- runner-contract: `FIXTURE_BASH may only be empty or deny-record, got '…'` next to `FIXTURE_MODE must be inline, repo or tree, got '…'`. The per-tool `FIXTURE_TOOLS` message at :74 gained "(Bash only with FIXTURE_BASH=deny-record)", but the format-error message for the same setting at :59 did not.

`generate-reports.bats` greps "Bash tripwire: 1 Bash call", so the generator string is now a tested contract.

**Recommendation:** Use one phrase in both places (for example `Bash tripwire: N call(s) not in permission_denials (may have executed)`), give the `unreadable` case its own sentence, write `FIXTURE_BASH must be empty or deny-record`, and add the Bash note to :59 so the two FIXTURE_TOOLS messages match.

#### 8. mode1-equiv.bats: file name and contents do not follow the test layout

**Severity:** Informational
**Location:** `test/skills/mode1-equiv.bats` (whole file); tests at :907-915
**Move:** 2
**Confidence:** Medium
**Legibility-target:** a maintainer looking for the tests of a check.

Precedent: per-skill offline suites are `<skill>-<aspect>.bats` (`arithmetic-eval-gate.bats`), and generic transcript checks are tested in `eval-helpers-transcript.bats` (`tool_called`, `subagents_min`), in `test/skills/*.bats`.

The file is not skill-prefixed (`arithmetic-eval-mode1-equiv.bats` would sit next to `arithmetic-eval-gate.bats`). It also holds the one test of the generic `no_tool_called:`, which sits apart from its twin's tests.

**Recommendation:** Optional rename. Move or duplicate the `no_tool_called` test into `eval-helpers-transcript.bats`, next to `tool_called`.

#### 9. `FIXTURE_BASH` sets the pattern of one runner setting per tool

**Severity:** Informational (floor; downgraded from Minor by the no-precedent rule)
**Location:** `test/skills/runner-contract.bash:18-26, 34, 98-116`; `generate-reports.bash:31-36`
**Move:** 2
**Confidence:** Medium
**Legibility-target:** the author of the next deny-and-record tool (for example WebFetch).

No existing precedent in `test/skills/runner-contract.bash`, `test/skills/generate-reports.bash` and `test/skills/*/runner.bash` (all `FIXTURE_*` names).

Every existing `FIXTURE_*` names a dimension of the run. `FIXTURE_BASH` names a tool and takes a policy value. A second tool would need `FIXTURE_<TOOL>` plus another branch in `check_runner_settings` and in the generator's pinning. This is fine for one exception, which the comment at :18-26 says it is.

**Recommendation:** No change needed now. If a second tool ever needs deny-record, generalise to a policy-keyed setting (for example `FIXTURE_DENY_RECORD=Bash,WebFetch`) instead of adding `FIXTURE_WEBFETCH`.

#### 10. The value spec's tolerance is relative-only, and test names state one value of a set

**Severity:** Informational
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:77-82, 130`; `test/skills/arithmetic-eval-eval.bats:346-356`
**Move:** 8 (contract of a value), 3
**Confidence:** High
**Legibility-target:** a fixture author choosing expected values.

`math.isclose(value, v, rel_tol=t, abs_tol=0.0)`: an expected `0` can only match exactly, whatever `~tol` says. This is not documented in any of the three spec descriptions. The eval test names ("Mode 1 call computes 1.9 billion") name one value, while the KEY_CHECK accepts `1900000000|1900000|47500` (fact-check Claim 19). Claim 20 notes that tc-ae4's natural backward check (`4800000 / 4 = 1200000`) is not in its list, so a correct backward route fails.

**Recommendation:** Document "relative tolerance; 0 needs an exact match" wherever the spec is described. Rename the tests to "… routes through Mode 1 (e.g. 1.9 billion)". Add `1200000` to tc-ae4.

## Escalated to security-reviewer (noted, not scored here)

- Claims 6/10b: a same-uid process that sets itself non-dumpable has an unreadable `/proc/<pid>/cwd`, and `procs_in_checkout`'s `readlink … || continue` skips it. For the API, this means the documented contract (usage text, decision 037 "What the gate does not see") says in-checkout processes are refused, and this case is missing from the residuals list. The fix could be either fail-closed (name the PID as "cwd unreadable") or a documented residual. That is security-reviewer's call.
- Finding 1 also has a security aspect: the pass/fail decision depends on SKILL.md's evaluator rejecting `EXPREOF` as a Name.

## What Looks Good

- `FIXTURE_BASH` is added to `reset_runner_settings`, so a runner that omits it cannot inherit a previous runner's value. This is the same discipline as its siblings.
- The deny-record validation fails before any paid run, with messages in the existing `Error: $label: …` form, and `generate-reports.bats` asserts the exact refusal strings and that no claude call was made (`ls "$CALLS" | wc -l` = 0).
- The CLAUDE_FLAGS refusal reuses the generator's existing `Error: $RUNNER_FILE sets <SETTING>=…; …` message shape (compare :110).
- `assert_no_tool_called` and `assert_mode1_equiv` reuse `eval_transcript_path` and `transcript_tool_inputs`, so missing transcripts and non-JSON lines behave exactly as for `tool_called:` (fail, not skip).
- `mode1_equiv:`'s any-call-matches semantics mirror `tool_called:`'s any-input-matches.
- `routes` / `does not route` and the `flaw`/`sound` CLAIM_ACCURACY values reuse divergent-design's router vocabulary. The fixture names follow `tc-<abbrev><n>-<defect>`.
- install.sh's usage text, decision 037 and the refusal all cite Q-062 next to Q-058. The new refusal exits 1 like its siblings, and the missing-/proc case fails closed like the missing-pgrep case (Claims 1, 2 Verified).
- The docs are updated consistently across the runner-contract comment, the generate-reports header, the gate-suite comment and decision log #56 (Claims 11, 30a, 34 Verified).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | WRAPPER_RE does not enforce the "wrapper exact / only comments after EXPREOF" contract | Inconsistent | `test/skills/arithmetic-eval/mode1-equiv.py:33-40,116-127` | High |
| 2 | `no_tool_called:` does not mirror `tool_called:`'s `=<ERE>` shape; the mirrored spelling passes silently | Inconsistent | `test/skills/eval-helpers.bash:153-154,396-408` | High |
| 3 | In-checkout refusal paragraph, /proc error and agent_gate comment break sibling shape | Minor | `devcontainer-config/install.sh:1156-1157,1173-1178,1212-1217` | High |
| 4 | After-denial grading lives outside expected-verdicts.bash | Minor | `test/skills/arithmetic-eval-eval.bats:326-382` | High |
| 5 | mode1-equiv.py: usage/setup errors exit 1 on stderr, against the docstring and the exit-2 convention | Minor | `test/skills/arithmetic-eval/mode1-equiv.py:24,43-52,77-82,100` | High |
| 6 | `mode1_equiv:` hard-wires arithmetic-eval paths in the shared dispatcher | Minor | `test/skills/eval-helpers.bash:156-157,410-421` | Medium |
| 7 | Two tripwire spellings; `may only be` vs `must be`; FIXTURE_TOOLS messages diverge | Minor | `generate-reports.bash:259`, `mode1-equiv.py:111`, `runner-contract.bash:59,74,113` | High |
| 8 | mode1-equiv.bats name and its generic `no_tool_called` test placement | Informational | `test/skills/mode1-equiv.bats` | Medium |
| 9 | `FIXTURE_BASH` starts a per-tool setting pattern | Informational | `test/skills/runner-contract.bash:98-116` | Medium |
| 10 | Relative-only tolerance undocumented; single-value test names | Informational | `mode1-equiv.py:130`, `arithmetic-eval-eval.bats:346-356` | High |

## Overall Assessment

The branch mostly follows the harness's and installer's conventions. The new setting, checks, functions, fixtures and messages reuse the existing prefixes, message forms and fail-before-a-paid-run discipline, and the docs moved with the code. The two Inconsistent findings share one theme: a documented or implied contract that the code enforces only partly. `mode1_equiv:`'s "wrapper exact" guarantee in fact depends on SKILL.md's evaluator (Finding 1). `no_tool_called:` looks like the negation of `tool_called:`, but its natural mirrored spelling passes vacuously (Finding 2). Both are small in-place fixes with a test each, and neither produces a false pass on the committed fixtures today. The rest is message and layout consistency that can be fixed in place or deferred. No breaking change to existing consumers was found: every existing runner, check and install.sh invocation behaves as before, apart from the intended new refusal.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** Saved to `docs/reviews/api-consistency-review-2026-09-25-q062-q063.md` with `Commit: 5ddf804` at the top and the skill's sections: Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment. The Claim 22 escalation is treated as a contract question (Finding 1). All the public surfaces named in the brief are covered: runner settings and their errors (7, 9), check names and syntax (2, 6, 10), mode1-equiv.py's CLI (5), install.sh's usage and refusal text (3), and failure markers (7).
- **Out of scope:** exploitability of the non-dumpable evasion and of CLAUDE_FLAGS spellings (C4; security-reviewer), and runtime model behaviour (Claims 14, 30b and 32 need a claude run).
- **Escalate:** Claims 6/10b (fail-open on an unreadable cwd) to security-reviewer. The security aspect of Finding 1 as well.
- **Decisions:** Finding 1 is rated Inconsistent rather than Breaking because there is no current false pass (Claim 22). Finding 9 uses the no-precedent downgrade.
