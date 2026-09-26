Commit: d8c43ae

# API Consistency Review: branch skill-fixtures (Q-062 [2], Q-063 [1]), iteration 2

**Scope:** `git diff main...HEAD` at d8c43ae. The focus is the surfaces that iteration 1's fix commit 8664e22 changed: `no_tool_called:` vs `tool_called:`, `assert_mode1_equiv`'s `$skill` argument, the mode1-equiv.py CLI, runner-contract messages, the generator's failure markers and CLAUDE_FLAGS refusal, install.sh's refusal and error messages, and `AE_GRADE_AFTER_DENIAL`.
**Date:** 2026-09-25 (review-fix loop iteration 2 of 3)
**Based on:** `docs/reviews/code-fact-check-report.md` (commit d8c43ae). Code behaviour comes from that report, cited by claim number. I ran four small probes of my own, each marked "(probe)", with inputs and output quoted inline. No `claude` or network command was run.
**Settled, not re-litigated:**
- Override log: C4, C5, C6, C9, trap RETURN, `--tools` variadic and RUNNER_ALLOWED_TOOLS naming.
- Iteration 1: A1 (the unreadable-cwd skip) and the open Consider items C3, C4, C6, C8, C13, C14 and C15.
- Claim 25b (mode1-equiv.py setup errors that exit 1) and Claim 2 (the framing of "readable /proc") are escalated elsewhere. They are referenced below only where they bear on a message or on another consumer.

## Baseline Conventions

This carries forward the baseline from iteration 1 (`docs/reviews/api-consistency-review-2026-09-25-q062-q063.md`). I re-read the following surfaces in full at d8c43ae: `eval_fixture` (the whole dispatcher), `transcript_tool_inputs`, `assert_tool_called`, `assert_no_tool_called`, `assert_mode1_equiv`, `check_runner_settings`, the generator's failure block in `generate_one`, `procs_in_checkout` and `agent_gate`.

- **Negative eval checks mirror their positive twin.** Examples are `field_match:F=v` / `no_field:F=v` and `cites_pattern:ERE` / `no_pattern:ERE`. An author error in a check spec is labelled as one: `echo "Unknown check type: $check"` (`test/skills/eval-helpers.bash:169`).
- **Dispatcher-level tests** go through `eval_fixture` with a demo skill: `run eval_fixture demo tc-clean.py` (`test/skills/eval-helpers-empty-report.bats:38-73`). Per-assert tests call `assert_*` directly (`eval-helpers-transcript.bats`).
- **Runner settings are validated in dependency order.** `FIXTURE_MODE` is checked (`runner-contract.bash:49-55`) before the FIXTURE_TOOLS loop, which reads it for the inline file-tool rule (`:78-86`). Messages have the shape `Error: $label: <SETTING> must be …, got '<v>'`.
- **install.sh refusal paragraphs** have the shape `<What> (<columns>):`, then the indented list, then `Stop them: <command>` (`install.sh:1223-1237`). Helper comments state status codes as "Returns N" (`install.sh:359`, `:401`).
- **Opt-in env knobs** are `<SCOPE>_<VERB>_<OBJECT>`, tested as exactly `1`: `HEALTH_CHECK_SKIP_BATS` (`scripts/health-check.sh:370`) and `USAGE_LOG_DEBUG` (`hooks/lib/usage-common.sh:39`). A scope prefix may be an abbreviation: `SI_RUN_ID` and `SI_PRIORITIES` (`scripts/self-improvement.sh`).
- **Script CLIs** print a `<script>:` prefix and exit 2 on usage errors: `lite-review: PARSE FAILURE` (`scripts/lite-review.py:236`).

### Iteration-1 fixes re-checked

| Item | Status at d8c43ae | Note |
|---|---|---|
| A5 `no_tool_called:<Tool>[=<ERE>]` | Fixed as a split, but the pair is still asymmetric | Finding 1: bare forms are not inverses. Finding 2: a tool-name typo passes vacuously. Finding 3: the dispatcher split is untested |
| A6 `$skill`-resolved checker | Fixed | The `$skill`-first argument order matches `load_eval_report`/`eval_fixture`/`load_expected_verdicts`. The dispatcher arm is untested (Finding 3) |
| A10 exit 2 on usage/spec errors | Partly fixed (Claim 25b, escalated) | Finding 6 adds the consumer side: exit 2 is collapsed into an ordinary check failure |
| C5 install.sh messages | Partly fixed | The stop line and the separate rc=3 message landed. The lead line and the header shape did not (Finding 5) |
| C7 message wording | Fixed | One tripwire spelling in the generator and the checker. `FIXTURE_BASH must be …`. Both FIXTURE_TOOLS messages carry the Bash note |
| C9 `FIXTURE_TOOLS=Bash` exactly | Fixed | The error order is off when FIXTURE_BASH itself is misspelled (Finding 4) |
| C10 / C11 / C12 | Fixed | No API regressions. The combined marker `…; Bash tripwire: …` is consistent (What Looks Good) |

## Name-Pattern Audit

These are the names and message strings that are new or changed since 5ddf804. Names that iteration 1 already audited and that have not changed are omitted.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `no_tool_called:<Tool>[=<ERE>]` (bare form) | eval check shape | `tool_called:<Tool>=<ERE>`, `no_field:F=v`/`field_match:F=v` | `test/skills/eval-helpers.bash:113-149` | Inconsistent. The bare form means "no call at all", but bare `tool_called:<Tool>` means "input matches /<Tool>/" (Finding 1) |
| `assert_mode1_equiv <skill> <spec>` | function signature | `eval_fixture <skill> <fixture>`, `load_eval_report <skill> <fixture>`, `load_expected_verdicts <skill>` | `test/skills/eval-helpers.bash:34,58` | Consistent (skill first) |
| `mode1_equiv: needs a skill-owned checker at …` | diagnostic | `No transcript at …`, `Unknown check type: …`, `No $tool call with input matching …` | `eval-helpers.bash:169,356,380` | Consistent in tone. Its `mode1_equiv:` prefix differs from the script's `mode1-equiv:` (Finding 6) |
| `usage_error` / `mode1-equiv: <msg>` + exit 2 | script CLI | `lite-review: PARSE FAILURE` + `return 2` | `scripts/lite-review.py:236-237` | Consistent. Consumer side: Finding 6 |
| `split_mode1`, `HEAD_RE`, `TAIL_LINE_RE` | internal (py) | `bash_calls`, `parse_expected`, `WRAPPER_RE` (removed) | `test/skills/arithmetic-eval/mode1-equiv.py` | Consistent (snake_case functions, `_RE` constants) |
| `AE_GRADE_AFTER_DENIAL` | env knob | `HEALTH_CHECK_SKIP_BATS`, `USAGE_LOG_DEBUG`, `SI_RUN_ID` | `scripts/health-check.sh:20,370`, `hooks/lib/usage-common.sh:39`, `scripts/self-improvement.sh` | Consistent: `<SCOPE>_<VERB>_<OBJECT>`, `=1` exactly, and the abbreviated scope has an `SI_` precedent. It is the first env-gated opt-in *test*, so there is no exact analog |
| `FIXTURE_BASH=deny-record needs FIXTURE_TOOLS=Bash exactly, got '…'` | error message | `… needs FIXTURE_TRANSCRIPT=1`, `FIXTURE_MODE must be …, got '…'` | `runner-contract.bash:52,105` | Consistent. Reached late when FIXTURE_BASH is misspelled (Finding 4) |
| `Bash tripwire: the transcript could not be read, so denials are unverified` | failure marker | `claude exited N`, `the result event is an error`, `Bash tripwire: N Bash call(s) …` | `generate-reports.bash:240,253-255,275` | Consistent (iteration-1 C7 resolved) |
| `<failure>; <trip>` join | failure-marker composition | single-phrase markers | `generate-reports.bash:277`, `eval-helpers.bash:80-84` | Consistent. The only consumers `cat` the marker verbatim |
| `CLAUDE_FLAGS may not change permissions: <raw>` | error message | `sets FIXTURE_TRANSCRIPT=1, which needs jq`, `got '<v>'` | `generate-reports.bash:116`, `runner-contract.bash:52` | Informational: it neither quotes the value nor names the matched flag (Finding 7) |
| `procs_in_checkout` return 3 | helper status code | "Returns 0 …", "Returns 1 …" | `devcontainer-config/install.sh:359,401` | Informational: the comment says "Exit", siblings say "Returns" (Finding 5) |
| `ERROR: could not resolve the checkout's path (…), so install.sh cannot check … (Q-062). $what` | error message | `ERROR: pgrep failed (exit $rc) while checking … (Q-058). $what` | `install.sh:1175-1176` | Consistent |
| "Other processes of uid N working inside … (Q-062; an agent may have left them running), PID and command line:" | refusal header | "Claude Code processes of uid N (PID and command line):", "Running cc-isolated containers (name and project id):" | `install.sh:1223,1235` | Minor: the column list sits outside the parentheses (Finding 5) |
| `CW_SEEN` | env var passed to awk | `PQ_WANT` via `ENVIRON[...]`; the `cw-`/`.cw-new.` prefix | `scripts/paper-queue.sh:212`, `install.sh:489,653` | Consistent |

## Findings

#### 1. Bare `tool_called:<Tool>` and bare `no_tool_called:<Tool>` are not inverses, though the new twin is documented as "the negative of tool_called:, with the same argument shape"

**Severity:** Inconsistent
**Location:** `test/skills/eval-helpers.bash:146-149` (tool_called arm), `:153-159` (no_tool_called arm), `:403-417` (assert_no_tool_called)
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** a fixture author who writes `tool_called:Bash` expecting "some Bash call", because `no_tool_called:Bash` means "no Bash call".

Evidence. The positive arm always splits on `=`, even when there is none (whole arm):
```bash
      tool_called:*)
        local spec="${check#tool_called:}"
        assert_tool_called "${spec%%=*}" "${spec#*=}" || failed=1
        ;;
```
With no `=` in the spec, `${spec#*=}` returns the whole spec, so `tool_called:Bash` becomes "some Bash call whose input matches /Bash/i". The negative arm special-cases the bare form (whole arm):
```bash
      no_tool_called:*)
        local spec="${check#no_tool_called:}"
        if [[ "$spec" == *=* ]]; then
          assert_no_tool_called "${spec%%=*}" "${spec#*=}" || failed=1
        else
          assert_no_tool_called "$spec" || failed=1
        fi
        ;;
```
and `assert_no_tool_called` defaults the pattern to `.` (`local tool="$1" pattern="${2:-.}" t hits`, `:409`). Its comment says: "with no <ERE>, no call of <tool> at all. The negative of tool_called:, with the same argument shape" (`:404-406`).

(probe) The transcript held one Bash call with input `{"command":"python3 -c 1"}`. The functions were called the way each arm dispatches them:
```
rc=1  assert_tool_called Bash Bash      # what bare tool_called:Bash runs → FAILS with a Bash call present
rc=1  assert_no_tool_called Bash        # bare no_tool_called:Bash → fails, correctly
rc=0  assert_tool_called Bash ""        # tool_called:Bash=   (empty transcript) → PASSES with no call
rc=0  assert_no_tool_called Bash ""     # no_tool_called:Bash= (empty transcript) → passes
```
So `tool_called:Bash` and `no_tool_called:Bash` can both fail on the same transcript. The positive's parse is pre-existing (`git show main:test/skills/eval-helpers.bash:146-148`). The mismatch is new: iteration-1 A5 gave the twin a bare form with "any call" semantics and documented the two as mirror images. The vacuous pass of `tool_called:<Tool>=` (an empty ERE matches the empty line `printf '%s\n' ""` produces) is the same parse's other edge.

**Recommendation:** Give the `tool_called:` arm the same `*=*` branch and let `assert_tool_called` default its pattern to `.`, so both bare forms mean "any call". Alternatively, refuse a bare `tool_called:<Tool>` with an "Unknown check type"-style message. Either way, reject an empty ERE in both arms.

#### 2. A misspelled tool name in `no_tool_called:` passes vacuously

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:365-370` (`transcript_tool_inputs`, exact `.name == $n`), `:408-417`
**Move:** 4 (error consistency), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** a fixture author; a typo turns a negative expectation into a check that can never fail.

Evidence. The tool name is matched exactly and case-sensitively: `select(.type == "tool_use" and .name == $n)` (`:369`). The ERE is case-insensitive (`grep -iE`, `:411`), and the comment advertises it: "had an input matching <ERE> (case-insensitive)". (probe) The transcript held one `Bash` call:
```
rc=0  assert_no_tool_called bash   # lowercase typo: PASSES with a Bash call present
rc=1  assert_tool_called bash .    # positive twin fails loudly on the same typo
```
The positive twin exposes a typo as a failure, but the negative twin hides it as a pass. That is the same silent-pass class as iteration-1 A5, reached through a different spelling. Iteration 1's recommendation also asked for name validation, and only the `=` shape was implemented.

**Recommendation:** Fail `no_tool_called:<Tool>` when `<Tool>` is not among the tools the run was offered. The stream-json init event lists them (the DD doc records init `tools: []` for `Bash(*)`, `docs/working/dd-arith-eval-bash-grant.md:173`). That makes the negative non-vacuous by construction. The minimum fix is to reject names that do not match `^[A-Z][A-Za-z]+$`.

#### 3. The A5 and A6 fixes live in the dispatcher, but only the assert functions are tested

**Severity:** Minor
**Location:** `test/skills/mode1-equiv.bats:145-162`; `test/skills/eval-helpers.bash:153-162`
**Move:** 3 (test drift)
**Confidence:** High
**Legibility-target:** the next editor of `eval_fixture`, who needs a red test if the `=` split or the `$skill` pass-through regresses.

Evidence. The test named for the check syntax bypasses the parser it names:
```bash
@test "no_tool_called:<Tool>=<ERE> takes tool_called's shape: fails only on a matching input" {
  transcript "rm -rf /tmp/x"
  run assert_no_tool_called Bash 'rm -rf'
  [ "$status" -ne 0 ]
  [[ "$output" == *"matching /rm -rf/"* ]]
  run assert_no_tool_called Bash 'curl'
  [ "$status" -eq 0 ]
}
```
Iteration 1's bug was in the dispatcher's parse: `no_tool_called:Bash=rm` was read as a tool named `Bash=rm`. `rg no_tool_called test` finds no `eval_fixture` call with a `no_tool_called:` or `mode1_equiv:` KEY_CHECK. Reverting the split at `:155-159` would therefore leave every test green. The precedent for dispatcher tests is `test/skills/eval-helpers-empty-report.bats:38-73` (`run eval_fixture demo tc-clean.py` with a demo `expected-verdicts.bash`).

**Recommendation:** Add a demo-skill `eval_fixture` test with `KEY_CHECK="no_tool_called:Bash=rm -rf"` (it fails on an `rm -rf` call and passes on `echo`). Add one with `mode1_equiv:` under a demo skill that has no checker, which proves `$skill` reaches the arm. If Finding 1 is fixed, add a bare `tool_called:Bash` case too.

#### 4. A misspelled `FIXTURE_BASH` is reported as a FIXTURE_TOOLS error

**Severity:** Minor
**Location:** `test/skills/runner-contract.bash:57-80` (tools loop) vs `:100-119` (FIXTURE_BASH validation); the test that locks it in is `test/generate-reports.bats:473-478`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** a runner author who typed `deny_record` or `Deny-Record`.

Precedent: a setting that the FIXTURE_TOOLS loop depends on is validated before the loop, as `FIXTURE_MODE must be inline, repo or tree` used in `test/skills/runner-contract.bash:49-55` shows (the loop reads `FIXTURE_MODE` at `:78`).

Evidence. The loop consults `FIXTURE_BASH` (`if [ "$tool" = "Bash" ] && [ "$FIXTURE_BASH" = "deny-record" ]; then ok=1`, `:71-73`), but `FIXTURE_BASH`'s own value is validated only after the loop. (probe) With a runner that sets `FIXTURE_TOOLS=Bash FIXTURE_MODE=inline FIXTURE_TRANSCRIPT=1 FIXTURE_BASH=deny_record`:
```
Error: r.bash: FIXTURE_TOOLS may only name Read Grep Glob WebSearch WebFetch Agent, joined by commas with no spaces (e.g. Read,Grep,Glob), or be 'none' (Bash only with FIXTURE_BASH=deny-record); got 'Bash'
```
With `FIXTURE_TOOLS=Read`, the same typo gets the accurate `FIXTURE_BASH must be empty or deny-record, got 'deny_record'`. The parenthetical hints at the cause, but the message blames the setting that is correct. The test asserts the misdirected text: `[[ "$output" == *"FIXTURE_TOOLS may only name"* ]]   # Bash is refused outright` (`generate-reports.bats:477`).

**Recommendation:** Move the `case "$FIXTURE_BASH" in "") ;; deny-record) ;; *) … must be empty or deny-record …` value check above the tools loop, next to FIXTURE_MODE, and keep the deny-record cross-checks where they are. Update `generate-reports.bats:477` to expect `FIXTURE_BASH must be`.

#### 5. install.sh: C5's fix is incomplete, so the lead line and header still misdescribe the new category

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1220-1221` (lead), `:1228-1229` (header), `:1188` (/proc message), `:1139` (helper comment)
**Move:** 4 (error consistency), 2 (message shape)
**Confidence:** High
**Legibility-target:** the operator reading a refusal caused by their own editor or second shell in the checkout, which is the likeliest trigger of the new gate.

Precedent: `<What> (<columns>):` used in `devcontainer-config/install.sh:1223` ("Claude Code processes of uid $(id -u) (PID and command line):") and `:1235` ("Running cc-isolated containers (name and project id):"). Helper status codes are described as "Returns N" in `install.sh:359,401`.

Evidence. The lead line is unconditional. It prints the same text when the only finding is an editor (excerpt; the block continues through `:1241` with the three category paragraphs and `exit 1`, all read):
```bash
  if [ -z "$procs" ] && [ -z "$inrepo" ] && [ -z "$ctrs" ]; then return 0; fi
  {
    echo "ERROR: an agent is running. install.sh installs only while no agent can run, because"
    echo "       one could change what you review before it is installed (Q-058)."
```
The new header puts its column list after a Q-reference aside:
```
      echo "       Other processes of uid $(id -u) working inside $REPO_ROOT (Q-062; an"
      echo "       agent may have left them running), PID and command line:"
```
Iteration-1 C5 asked for three things: the sibling header shape, a softer lead when `procs` and `ctrs` are empty, and a concrete stop command. Only the stop command landed (`Stop them: kill <PID>, or cd each one out …`). Two smaller points are about wording only; the substance is escalated as Claim 2. First, `ERROR: /proc is not readable` is printed only when `[ -d /proc/self ]` fails, which is an absence, not a readability failure. Second, the `procs_in_checkout` comment says "Exit 2 without /proc, 3 if …", where sibling helpers say "Returns".

**Recommendation:** When `procs` and `ctrs` are empty, lead with "ERROR: a process is working inside the checkout (Q-062) …" instead of "an agent is running". Rewrite the header as `Other processes of uid N working inside <root> (PID and command line; an agent may have left them running):`. Say "/proc is not mounted" (or leave the wording to the security reviewer's Q-064 framing) and "Returns 2 …, 3 …".

#### 6. mode1-equiv.py's exit 2 has no consumer: `assert_mode1_equiv` passes it through as an ordinary check failure

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:428-437` (whole `assert_mode1_equiv`), `:160-162` (dispatcher arm)
**Move:** 4 (error consistency), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** the orchestrator planning the structural fix for Claim 25b, and a fixture author reading a red eval.

Precedent: author errors in a check spec are labelled as such in `test/skills/eval-helpers.bash:169` (`echo "Unknown check type: $check"`).

Evidence. The function's last line is the bare call `python3 "$checker" "${BATS_TEST_DIRNAME}/../../skills/${skill}/SKILL.md" "$t" "$spec"` (`:436`), and the arm is `assert_mode1_equiv "$skill" "${check#mode1_equiv:}" || failed=1` (`:161`). Exit 1 ("the model did not compute it") and exit 2 ("the fixture spec is broken") both become `failed=1`. (probe) The transcript held one non-Mode-1 Bash call:
```
spec=abc   rc=2 :: mode1-equiv: bad expected value 'abc' in 'abc'
spec=1~-1  rc=1 ::   call 1: not the Mode 1 wrapper: 'python3 -c 1'|No Mode 1 call computed any of: 1~-1
spec=42    rc=1 ::   call 1: not the Mode 1 wrapper: 'python3 -c 1'|No Mode 1 call computed any of: 42
```
The spec error is visible only as stderr text, whose prefix `mode1-equiv:` (the script's name) differs from the assert's own `mode1_equiv:` (the check's name). The `1~-1` row shows that a negative tolerance is accepted whenever no Mode 1 call reaches `math.isclose`, so the spec is validated only as a side effect of model output (Claim 25b). A structural fix that only routes more cases through `usage_error` will still read as an ordinary eval failure at the `eval_fixture` level.

**Recommendation:** In `assert_mode1_equiv`, capture the status. On 2, print `mode1_equiv: bad check spec or setup (not a model result):` before the script's message and return 1. Validate the value spec (a negative, NaN or empty tolerance) in `parse_expected` before any transcript is read, so the outcome does not depend on what the model did.

#### 7. Small message and name drift left after C7 and C9

**Severity:** Informational
**Location:** `test/generate-reports.bats:452`; `test/skills/generate-reports.bash:130`
**Move:** 2, 4
**Confidence:** High
**Legibility-target:** a reader who uses test names and error text as the spec.

Precedent: `got '<value>'` quoting used in `test/skills/runner-contract.bash:52,111,116`. Test names that state the exact rule are used in `test/generate-reports.bats:487` ("deny-record does not open Bash(<pattern>) spellings").

Evidence:
- **Test name.** `@test "deny-record needs FIXTURE_TRANSCRIPT=1 and Bash in FIXTURE_TOOLS; other values are refused"` says "Bash in FIXTURE_TOOLS", but the rule since C9 is `FIXTURE_TOOLS=Bash exactly`. The body asserts `*"needs FIXTURE_TOOLS=Bash exactly"*` for `Bash,WebSearch`.
- **CLAUDE_FLAGS refusal.** `echo "Error: $RUNNER_FILE sets FIXTURE_BASH=deny-record; CLAUDE_FLAGS may not change permissions: ${CLAUDE_FLAGS}"` prints the raw value unquoted. Since C12 that value can hold a tab or newline. The message does not say which of the seven patterns matched.
- **tc-ae4 test name.** Fact-check Claim 18 already covers this one; it is not repeated here.

**Recommendation:** Rename the test to "… needs FIXTURE_TRANSCRIPT=1 and FIXTURE_TOOLS=Bash exactly …". Quote the value (`got '${CLAUDE_FLAGS}'`) and name the refused flag family (for example "--permission-mode/--permission-prompt*/--allowedTools/--settings/skip-permissions").

## What Looks Good

- **One tripwire phrase.** The generator (`generate-reports.bash:275`) and the checker (`mode1-equiv.py:140`) both say `Bash tripwire: N Bash call(s) not in permission_denials (may have executed)`, and the `unreadable` case has its own sentence (C7 resolved). The `; ` join (`:277`) keeps each marker a lowercase phrase, and its only consumers (`eval-helpers.bash:80-84`, `arithmetic-eval-eval.bats:53-55`) print it verbatim.
- **Skill-first `assert_mode1_equiv`.** The new signature follows `eval_fixture`/`load_eval_report`/`load_expected_verdicts`. The missing-checker message names the resolved path.
- **`AE_GRADE_AFTER_DENIAL`.** It matches the repo's opt-in knob shape (`HEALTH_CHECK_SKIP_BATS`, `USAGE_LOG_DEBUG`: exact `=1`, `<SCOPE>_<VERB>_<OBJECT>`). The skip message names the variable and its value, so a reader of skipped output knows how to turn it on.
- **mode1-equiv.py CLI.** `mode1-equiv: <msg>` on stderr with exit 2 matches `lite-review:`'s shape. Per-call diagnostics stay on stdout, as the other `assert_*` diagnostics do.
- **The rc=3 message.** "could not resolve the checkout's path (…) … (Q-062). $what" follows the `pgrep failed … (Q-058). $what` sibling exactly.
- **FIXTURE_BASH messages.** `FIXTURE_BASH must be empty or deny-record, got '…'` and `needs FIXTURE_TOOLS=Bash exactly, got '…'` both match the `must be … got '…'` register. Both FIXTURE_TOOLS messages now carry the same Bash note.
- **`CW_SEEN` via `ENVIRON`.** It follows `PQ_WANT` in `scripts/paper-queue.sh:212` and the install's `cw-` prefix.

## Summary Table

| # | Finding | Severity | Location | Confidence | Legibility-target |
|---|---------|----------|----------|------------|-------------------|
| 1 | Bare `tool_called:<Tool>` ≠ inverse of bare `no_tool_called:<Tool>`; `tool_called:<Tool>=` passes with no call | Inconsistent | `test/skills/eval-helpers.bash:146-159,403-417` | High | fixture author |
| 2 | Misspelled tool name in `no_tool_called:` passes vacuously | Minor | `test/skills/eval-helpers.bash:365-370,408-417` | High | fixture author |
| 3 | A5/A6 dispatcher fixes have no dispatcher-level test | Minor | `test/skills/mode1-equiv.bats:145-162` | High | next editor of `eval_fixture` |
| 4 | Misspelled FIXTURE_BASH reported as a FIXTURE_TOOLS error | Minor | `test/skills/runner-contract.bash:57-119`; `test/generate-reports.bats:477` | High | runner author |
| 5 | install.sh lead line/header still misdescribe the in-checkout category (C5 partial) | Minor | `devcontainer-config/install.sh:1139,1188,1220-1229` | High | operator |
| 6 | Checker's exit 2 collapsed to an ordinary failure by `assert_mode1_equiv` | Minor | `test/skills/eval-helpers.bash:428-437` | High | orchestrator (Claim 25b fix), fixture author |
| 7 | Test name and CLAUDE_FLAGS message drift | Informational | `test/generate-reports.bats:452`; `test/skills/generate-reports.bash:130` | High | reader |

## Overall Assessment

8664e22 resolved most of iteration 1's API items correctly: one tripwire spelling, `$skill` resolution, the `FIXTURE_BASH must be` register, exit 2 with a prefixed message for the common spec errors, and a distinct rc=3 message. It introduced no Breaking change, and the new names follow their neighbours. What remains comes from fixes that were narrower than the recommendations behind them:
- A5 made `no_tool_called:` accept `=<ERE>`, but it did not make the pair symmetric (Finding 1) or non-vacuous on a bad name (Finding 2), and the fix sits in untested dispatcher code (Finding 3).
- C5 fixed the stop line but not the lead line or the header (Finding 5).
- A10's exit 2 has no consumer at the harness boundary (Finding 6).

Every item can be fixed in place, and none changes a consumer-visible contract that is already in use (the only committed use of these checks is `no_tool_called:Bash` and `mode1_equiv:`). Consumer impact today is low, because no committed fixture uses bare `tool_called:`. Finding 1 is the one to fix before other skills adopt `no_tool_called:`, since authors will reasonably write both bare forms.

## Goal-Alignment Note

- **Success criterion (restated):** "A markdown critique saved to the path named in your role section below, structured per your skill." The file is saved at `docs/reviews/api-consistency-review-2026-09-25-q062-q063-iter2.md` with `Commit: d8c43ae` at the top. It has the skill's sections (Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment). Every finding carries Severity, Location, verbatim Evidence, Confidence and Legibility-target. Every naming-shaped finding carries a `Precedent:` line. The work is not committed.
- **Answered:** every focus surface in the brief.
  - `no_tool_called` vs `tool_called`: parsing and case-sensitivity (F1-F3), plus its messages (audit).
  - `assert_mode1_equiv`'s `$skill` argument and message (audit, F6).
  - mode1-equiv.py exits and stderr (F6, What Looks Good).
  - Runner-contract messages (F4, F7, audit).
  - Generator failure markers (audit, What Looks Good).
  - install.sh refusal and rc=3 messages (F5, audit).
  - `AE_GRADE_AFTER_DENIAL` naming (audit, What Looks Good).
  - Each iteration-1 fix, with a status (the "Iteration-1 fixes re-checked" table).
- **Out of scope / deferred:**
  - Claim 25b's structural fix belongs to the orchestrator. F6 adds only the consumer side.
  - Claim 2's substance and Q-064's framing belong to the security reviewer. F5 touches only the message wording.
  - Not re-reported: C13 (the `mode1-equiv.bats` name and location, per-tool setting names, relative-only tolerance), C6/C8, and the fact-check's Claim 18.
- **Escalate:** F1 is a pre-existing parse in `tool_called:` that the new twin's documentation turns into a visible asymmetry. The author may prefer to fix it together with F3's dispatcher tests in one small change. Probes were run from the session scratchpad and were not saved as execution logs; their inputs and outputs are quoted inline.
