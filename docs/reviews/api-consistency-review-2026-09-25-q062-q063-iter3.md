Commit: c7747c7

# API Consistency Review: branch skill-fixtures (Q-062 [2], Q-063 [1]), iteration 3 (terminal pass)

**Scope:** `git diff main...HEAD` at c7747c7, weighted toward what f9feb2c changed. That covers the `tool_called:`/`no_tool_called:` rewrite (bare form, empty pattern, init-tool check, `tool_inputs_checked`/`match_inputs`), `assert_mode1_equiv`'s SETUP ERROR label, the mode1-equiv.py `--check-spec` CLI and spec grammar, the generator's CLAUDE_FLAGS refusal and its tripwire/canary markers, the runner-contract message order, install.sh's lead-line variants and blind-scan NOTE, and `AE_GRADE_AFTER_DENIAL` with the patterns file.
**Date:** 2026-09-25 (review-fix loop iteration 3 of 3, terminal: full amber inventory)
**Based on:** `docs/reviews/code-fact-check-report.md` (commit c7747c7), cited by claim number. My own probes are marked "(probe)", with their input and output quoted inline. They ran from the session scratchpad against copies, and nothing was written under `test/skills/*/output/`. I ran no `claude` command and no network command.
**Settled, not re-litigated:** C4, C5, C6, C9, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming, A1 (pending Q-064), C24, C13, and the open C3/C4/C6/C8/C14/C15. Three fact-check items are escalated elsewhere and cited here only where they touch a consumer-facing surface: Claims 8/29c (the vacuous `!` and the shellcheck gate) go to the orchestrator, and Claim 2b (the PID-namespace NOTE comment) goes to the security reviewer.

## Baseline Conventions

This carries the baseline from iterations 1 and 2 (`docs/reviews/api-consistency-review-2026-09-25-q062-q063{,-iter2}.md`). I re-read these units in full at c7747c7:
- `eval_fixture`, `transcript_tool_inputs`, `tool_inputs_checked`, `match_inputs`, `assert_tool_called`, `assert_no_tool_called` and `assert_mode1_equiv` (`test/skills/eval-helpers.bash:58-487`)
- all of `mode1-equiv.py`
- `check_runner_settings`
- the generator's header, the flag block and `generate_one` (`generate-reports.bash:1-299`)
- `procs_in_checkout` and `agent_gate` (`install.sh:1138-1254`)
- `after-denial-patterns.bash`, `arithmetic-eval-eval.bats`, `arithmetic-eval-after-denial-patterns.bats`, and `mode1-equiv.bats:1-40, 140-261`

The conventions that matter here:
- **Positive and negative eval checks are twins with one argument grammar and one message register.** Examples are `field_match:`/`no_field:` and `cites_pattern:`/`no_pattern:`. Author errors are labelled as such: `Unknown check type: $check` (`eval-helpers.bash:173`).
- **Runner settings are validated in dependency order.** A setting that a later check reads is validated first. C19's own rationale says so: "Checked before the tools loop, which reads it, so a misspelling … is reported as itself" (`runner-contract.bash:53-54`). Messages take the form `Error: $label: <SETTING> must be …, got '<v>'`.
- **Generator failure markers** are lowercase phrases, joined with `; `, and each one names its mechanism: `claude exited N`, `the result event is an error`, `Bash tripwire: …`, `Bash canary: …` (`generate-reports.bash:237-286`).
- **install.sh notices.** `NOTE: <cause>: <what> not checked, treated as none running.`, printed on **stdout**, once per gate call, and covered by a test (T52). This form is used at `install.sh:1209` and `install.sh:1220`, and in `test/install-host.bats:943`. Refusal paragraphs take the form `<What> (<columns>):`, then a list, then `Stop them: <command>`.
- **Script CLIs** print a `<script>:` prefix on stderr and exit 2 on usage errors (`scripts/lite-review.py:236`; `mode1-equiv.py:161`).

### Iteration-2 fixes re-checked

| Item | Status at c7747c7 | Note |
|---|---|---|
| A11 SetupError / exit 2 / label / `--check-spec` | Fixed for every enumerated class (Claim 13) | The exit-1 traceback on a wrong-shape transcript remains, unlabelled (Finding 7, from Claim 14) |
| A12 `no_tool_called` fails closed | Fixed on the three named paths (Claims 17, 18, 20) | An init-less transcript or an empty tool name still passes. The helper's doc comment overstates the guarantee (Finding 6, from Claim 16) |
| A13 bare `tool_called:<Tool>` = "called at all" | Fixed (Claim 19) | The failure message still prints `/./` (Finding 6) |
| C18 dispatcher-level tests | Partly fixed | The parse is tested, but "mode1_equiv resolves by skill" is not. Reverting A6 keeps the test green (Finding 2) |
| C19 FIXTURE_BASH validated first | Fixed (Claim 27) | The same dependency-order rule is still broken for `FIXTURE_TOOLS` under deny-record (Finding 3) |
| C20 lead line / header / "Returns" | Fixed (Claim 3) | The header now matches `<What> (<columns>…):`, and the comment says "Returns". The new lead variant is 101 characters wide (Finding 8) |
| C16/C21 CLAUDE_FLAGS refused, one `DENY_RECORD_FLAGS` | Fixed in code (Claims 22-24) | The contract is still described four ways (Finding 4, extends Claims 5b/6/23b) |
| C17 canary | Fixed (Claim 25) | It fires on every run with no init event, and its diagnosis is wrong there (Finding 1) |
| A14 "mounted /proc" + blind NOTE | Wording fixed | The NOTE departs from its sibling NOTEs on stream, shape, docs and tests (Finding 5) |
| C23 patterns file + offline tests | Fixed in structure | One vacuous assertion (Claim 8, escalated). The names follow precedent (audit) |

## Name-Pattern Audit

These are the names and message strings that f9feb2c added or changed. Names that iterations 1-2 audited and that have not changed are omitted.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `DENY_RECORD_FLAGS` | global array constant | `RUNNER_ALLOWED_TOOLS`, `CLAUDE_PROC_RE` | `test/skills/runner-contract.bash:16`, `devcontainer-config/install.sh:1106` | Consistent (UPPER_SNAKE, `<PURPOSE>_<KIND>`) |
| `tool_inputs_checked`, `match_inputs` | internal helpers | `transcript_tool_inputs`, `eval_transcript_path`, `field_values` | `test/skills/eval-helpers.bash:267,357,369` | Consistent enough. Neighbours are noun phrases; `match_inputs` is verb-first, which is harmless for an internal helper |
| `Bash canary: the init event does not list Bash (CLI <v>; did the deny rule remove the tool?)` | failure marker | `Bash tripwire: N Bash call(s) …`, `no result event in the stream` | `test/skills/generate-reports.bash:253,271-272` | The name is consistent (`Bash <mechanism>:`). The marker's condition is not: it fires without an init event (Finding 1) |
| `…, which refuses CLAUDE_FLAGS (got: <%q>); set the model with CLAUDE_MODEL` | error message | `FIXTURE_BASH must be …, got '<v>'`; `sets FIXTURE_TRANSCRIPT=1, which needs jq` | `test/skills/runner-contract.bash:58`, `test/skills/generate-reports.bash:111` | Informational: `(got: %q)` differs from the `got '<v>'` register, but `%q` is the better choice for tabs (Finding 4) |
| `SetupError` | exception class | `HelloError(ValueError)`, `DurationError(ValueError)` | `devcontainer-config/cc-sni-proxy.py:61` | Consistent (`<Noun>Error`). The base is `Exception`, not `ValueError`, which is right because it also wraps `OSError` |
| `--check-spec <SKILL.md> <expected>` | CLI mode flag | `questions.sh check` (subcommand), `--dry-run` | `~/.claude/scripts/questions.sh`, `scripts/archive-working-docs.sh:22` | New shape: the first validate-only flag. Its wrong-arity message is the positional form's (Finding 7) |
| `mode1_equiv: FIXTURE/CHECKER SETUP ERROR (exit 2), not a model result — …` | diagnostic | `Unknown check type: …`, `Generation failed for X: …` | `test/skills/eval-helpers.bash:82,173` | Minor: the label comes after the detail, where siblings lead with the category, and there are two prefixes, `mode1-equiv:` and `mode1_equiv:` (Finding 8) |
| `NOTE: no process's working directory could be read under /proc, …` | install notice | `NOTE: docker not found: … not checked, treated as none running.` | `devcontainer-config/install.sh:1209,1220` | Inconsistent: it goes to stderr, not stdout, has no "treated as" clause, and is untested and undocumented in usage (Finding 5) |
| `ERROR: a process may be acting for an agent. …` | refusal lead line | `ERROR: an agent is running. …` | `devcontainer-config/install.sh:1229` | The wording is consistent (C20 resolved). The width is 101 characters, where siblings are 84 or less (Finding 8) |
| `after-denial-patterns.bash` | sourced data file in `test/skills/<skill>/` | `expected-verdicts.bash`, `runner.bash` | `test/skills/*/expected-verdicts.bash` | Consistent: kebab-case `.bash`, sits beside the skill's other sourced files |
| `NOT_VERIFIED_RE`, `VERDICT_RE`, `FIGURE_RE[<fixture>]` | regex constants | `VERDICT_HEADING_RE`, `CLAUDE_PROC_RE`, `HEAD_RE` | `test/skills/fact-check-format.bats:12`, `devcontainer-config/install.sh:1106`, `mode1-equiv.py:43` | Consistent (`_RE` suffix; fixture-keyed like `KEY_CHECK[...]`) |
| `arithmetic-eval-after-denial-patterns.bats` | suite file | `arithmetic-eval-gate.bats`, `arithmetic-eval-format.bats`, `arithmetic-eval-eval.bats` | `test/skills/arithmetic-eval-*.bats` | Consistent (`<skill>-<topic>.bats`) |
| `AE_GRADE_AFTER_DENIAL` | env knob | `HEALTH_CHECK_SKIP_BATS`, `USAGE_LOG_DEBUG`, `SI_RUN_ID` | `scripts/health-check.sh:370`, `hooks/lib/usage-common.sh:39`, `scripts/self-improvement.sh` | Consistent (exact `=1`, `<SCOPE>_<VERB>_<OBJECT>`, abbreviated-scope precedent `SI_`). Unchanged since iteration 2 |
| `hits` (test-local helper) | bats helper | `transcript`, `with_expr` | `test/skills/mode1-equiv.bats:31,36` | Consistent (short local verbs/nouns) |

## Findings

Findings are ordered by severity, then confidence. None is Breaking. The only existing external consumer of the changed checks is divergent-design's `tool_called:Read=…` (`test/skills/divergent-design/expected-verdicts.bash:31-39`). It gains the init-tool name check, and that check is satisfied whenever Read is offered.

#### 1. The Bash canary fires on every deny-record run with no init event, blaming the deny rule for an auth or startup failure

**Severity:** Inconsistent
**Location:** `test/skills/generate-reports.bash:280-287` (canary, inside `generate_one`, which ends at `:299`; `failure` is written to `.failed` at `:291-293`)
**Move:** 4 (error consistency), 7 (asymmetry with the tripwire)
**Confidence:** High
**Legibility-target:** the operator reading a `.failed` marker, or `eval_fixture`'s "Generation failed for …" line, after a failed run.

Evidence. The canary's condition is "no `Bash` line in the init events' tools". It does not check that an init event exists:
```bash
      init_tools=$(jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | .tools[]?' \
        "$transcript_path" 2>/dev/null || true)
      …
      if ! printf '%s\n' "$init_tools" | grep -qx Bash; then
        failure="${failure:+$failure; }Bash canary: the init event does not list Bash (CLI ${cli_version:-unknown}; did the deny rule remove the tool?)"
      fi
```
(probe) A stub `claude` that prints "auth error" on stderr and exits 1, under a deny-record demo runner, produced this `.failed`:
```
claude exited 1; Bash canary: the init event does not list Bash (CLI unknown; did the deny rule remove the tool?)
```
The tripwire beside it stays silent on the same run, because zero calls gives `0`. So the two deny-record markers treat an empty stream differently, and the canary attaches a CLI-regression hypothesis to every network, auth or crash failure. The transcript-unreadable case adds a second contradiction, "the transcript could not be read" followed by "the init event does not list Bash". Claim 25 calls this "loose but fails closed", and the run is voided correctly either way. The problem is only the diagnosis, and it points the reader at the wrong subsystem, the very confusion C17 added the canary to avoid.

**Recommendation:** Branch on whether an init event exists. With none, say `Bash canary: no init event in the stream (CLI unknown)`, or add nothing when `failure` is already set. Keep the "did the deny rule remove the tool?" text for an init event that exists and lacks Bash. Add a stub test for the no-init case next to `test/generate-reports.bats:527`.

#### 2. The dispatcher test's "mode1_equiv resolves by skill" does not test resolution: reverting A6 keeps it green

**Severity:** Minor
**Location:** `test/skills/mode1-equiv.bats:239-261`; `test/skills/eval-helpers.bash:473-487`
**Move:** 3 (test drift)
**Confidence:** High
**Legibility-target:** the next editor of `assert_mode1_equiv`, and the orchestrator counting C18 as fully fixed.

Evidence. The test builds a tree with only `arithmetic-eval` and calls `run eval_fixture arithmetic-eval tc-1.md` with `mode1_equiv:2` / `mode1_equiv:3`. A path hard-coded to `arithmetic-eval` resolves to the same file. (probe) In a copy of `eval-helpers.bash` edited back to the pre-A6 shape (`checker="${BATS_TEST_DIRNAME}/arithmetic-eval/mode1-equiv.py"` and `skills/arithmetic-eval/SKILL.md`):
```
1..1
ok 1 eval_fixture dispatch: tool_called and no_tool_called parse <Tool>[=<ERE>]; mode1_equiv resolves by skill
```
The "needs a skill-owned checker" message is tested only by calling the assert directly (`mode1-equiv.bats:121`). The `tool_called:`/`no_tool_called:` half of the test does exercise the parse, and it is sound.

**Recommendation:** Add one dispatcher case with a second skill name that has no checker (for example `KEY_CHECK[…]="mode1_equiv:2"` under skill `demo`), and assert that it fails with `needs a skill-owned checker at …/demo/mode1-equiv.py`. Otherwise, drop "resolves by skill" from the test name.

#### 3. Under deny-record, a wrong FIXTURE_TOOLS gets one of three different errors, depending on which loop check it trips first

**Severity:** Minor
**Location:** `test/skills/runner-contract.bash:63-95` (tools loop) vs `:106-121` (deny-record cross-checks)
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** a runner author adopting deny-record for a second skill.

Precedent: a setting that a later check depends on is validated first, as in `FIXTURE_BASH`'s own value check "Checked before the tools loop, which reads it, so a misspelling … is reported as itself" (`test/skills/runner-contract.bash:53-61`).

Evidence. The deny-record rule is "FIXTURE_TOOLS=Bash exactly", but it is checked only after the general tools loop, so the loop reports first. (probe) Each runner below has `FIXTURE_MODE=inline FIXTURE_TRANSCRIPT=1 FIXTURE_BASH=deny-record`:
```
[Bash,Read]  Error: r: inline mode must not grant file tools; got 'Read'
[Bash(**)]   Error: r: FIXTURE_TOOLS may only name Read Grep Glob WebSearch WebFetch Agent, … or be 'none' (Bash only with FIXTURE_BASH=deny-record); got 'Bash(**)'
[Bash,Bash]  Error: r: FIXTURE_BASH=deny-record needs FIXTURE_TOOLS=Bash exactly, got 'Bash,Bash'
[none]       Error: r: FIXTURE_BASH=deny-record needs FIXTURE_TOOLS=Bash exactly, got 'none'
```
All four break the same rule. The second message tells the author to use `FIXTURE_BASH=deny-record`, which the runner already sets. A second round trip hides behind the first: fix `Read` and the next run reports "needs FIXTURE_TOOLS=Bash exactly".

**Recommendation:** Move the deny-record "Bash exactly" check to just after the `FIXTURE_BASH` value check (it reads only `FIXTURE_TOOLS`), so every wrong tools value under deny-record gets the one message. The `FIXTURE_TRANSCRIPT` cross-check can stay where it is, because it needs the normalisation at `:97-104`.

#### 4. The CLAUDE_FLAGS contract under deny-record is described four ways, and the generator's own Environment block omits it

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:76-78` (Environment), `:34` (FIXTURE_BASH header), `:126-129` (refusal); `docs/decisions/log.md:77`; `docs/working/dd-arith-eval-bash-grant.md:173-174`
**Move:** 3 (documentation drift), 4 (message register)
**Confidence:** High
**Legibility-target:** an operator who sets `CLAUDE_FLAGS` (the documented way to pass extra flags) and reads the script header first.

Evidence. Four descriptions of one rule:
- `# CLAUDE_FLAGS — additional flags to pass to claude -p` (`generate-reports.bash:78`). No caveat. **This one is not in the fact-check.**
- `Needs FIXTURE_TRANSCRIPT=1; refuses CLAUDE_FLAGS.` (`:34`). This is accurate.
- Log #56: "refuses permission-changing `CLAUDE_FLAGS`" (Stale, Claim 5b).
- The DD "As built" text: "may not name `--permission-mode`, … whitespace of any kind separates flags" (Stale, Claim 6). It also restates the flags instead of pointing at `DENY_RECORD_FLAGS` (Claim 23b).

The refusal itself reads (probe) `… which refuses CLAUDE_FLAGS (got: --model\ x\ --verbose); set the model with CLAUDE_MODEL`. It uses `(got: <%q>)`, where every sibling uses `got '<v>'` (`runner-contract.bash:48,58,101,117`). `%q` is the better choice for a value that can hold tabs, so this is noted, not a request to change it.

**Recommendation:** Add "(refused under FIXTURE_BASH=deny-record; use CLAUDE_MODEL for the model)" to the Environment line. Fix log #56 to "refuses any non-blank CLAUDE_FLAGS". Replace the DD Contract sentence and the flag restatement with a pointer to `DENY_RECORD_FLAGS`, and mention the canary there (Claim 6).

#### 5. The blind-scan NOTE does not follow the sibling NOTE convention: wrong stream, no consequence clause, untested, undocumented

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1166-1169` (inside `procs_in_checkout`, which ends at `:1170`; called from `agent_gate` at `:1190`), usage text `:59-63`
**Move:** 4 (error consistency), 3 (test drift)
**Confidence:** High
**Legibility-target:** the operator skimming install output for NOTE lines, and whoever implements Q-064 [3] ("skip but name"), which would add a second NOTE of this family.

Precedent: `NOTE: <cause>: <what> not checked, treated as none running.` on stdout, used in `devcontainer-config/install.sh:1209` and `:1220`; one NOTE per gate call, documented in usage (`install.sh:62`) and 037 ("one per check (one to four per run)"), tested by T52 (`test/install-host.bats:943`).

Evidence:
```bash
  if [ "$readable" -eq 0 ]; then
    echo "NOTE: no process's working directory could be read under /proc, not even this" >&2
    echo "      script's own: the check for processes inside the checkout saw nothing (Q-062)." >&2
  fi
```
The NOTE departs from its siblings in four ways:
- **Stream.** It goes to stderr, while both docker NOTEs go to stdout. `install.sh … > log` captures the docker NOTE and loses this one.
- **Shape.** "saw nothing" does not say what happens next. The siblings end "treated as none running". The gate goes on as for a clean scan (Claim 2a), so the NOTE should say "treated as none found".
- **Docs.** Usage lists the docker NOTE ("without a reachable docker it prints a NOTE line at each check") but not this one. Like the docker NOTE, this one repeats at each of the four gate calls.
- **Tests.** `rg "could be read|saw nothing" test/install-host.bats` finds nothing. The fact-check reached the NOTE only by stubbing `readlink` (Claim 2a).

The comment above it also gives "a PID-namespaced sandbox" as a trigger, which is wrong (Claim 2b, escalated to the security reviewer). I mention it only because a NOTE whose documented triggers are wrong gives the operator false reassurance when it stays silent.

**Recommendation:** Print it on stdout, and reword it to the sibling form: `NOTE: no process's working directory is readable under /proc (not even this script's): processes inside the checkout not checked, treated as none found (Q-062).` Add it to the usage paragraph. Add a T-test that stubs `readlink` to fail (T90 already edits the script copy, so the pattern exists).

#### 6. `tool_called:`/`no_tool_called:` edges: the bare form's message shows `/./`, an empty tool name is not a spec error, and the helper's doc overstates its guarantee

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:376-393` (`tool_inputs_checked`), `:412-426` (`assert_tool_called`), `:449-462` (`assert_no_tool_called`), `:146-164` (dispatcher arms)
**Move:** 7 (asymmetry), 4 (error consistency), 8 (nullability of the tool name)
**Confidence:** High
**Legibility-target:** a fixture author reading a red eval, or writing a new check spec.

Evidence (probe). An init event lists `["Bash"]`, and assertions were run with no call or one call:
```
rc=1  assert_tool_called Bash      :: No Bash call with input matching /./.|Bash calls seen: 0|
rc=1  assert_no_tool_called Bash   :: Expected no Bash calls, found 1:|{"command":"echo hi"}|
rc=1  assert_no_tool_called ""     ::  is not a tool of this run (its tools: Bash )|
```
The same checks against a transcript with **no** init event:
```
rc=0  assert_no_tool_called ""        :: |
rc=0  assert_no_tool_called "" rm     :: |
```
Three things follow:
- **Message register.** The negative twin hides the default pattern with `${2:+ with input matching /$2/}` (`:458`). The positive twin prints the internal default `/./` for the bare form A13 introduced. They were meant to be mirror images (`:445-446`), and the bare positive's message should read "No Bash call".
- **Empty tool name.** `no_tool_called:` and `no_tool_called:=rm` reach the assert with `tool=""`. With an init event, the message has a leading blank (" is not a tool of this run"). Without one, the check passes. Neither case is labelled as the author error it is, as `Unknown check type` is.
- **Doc overstatement.** "fail with a message when the transcript cannot be parsed" (`:377-378`) is Incorrect per Claim 16. Only an unreadable file fails, and a junk or init-less transcript reads as zero calls. Inside deny-record runs, the generator's canary (Finding 1) and `.failed` gate close this in practice. The helper is shared, though, and the comment is the contract other skills will read.

**Recommendation:** In `assert_tool_called`, use the same `${2:+…}` form ("No Bash call" / "No Bash call with input matching /x/"). In both dispatcher arms, reject an empty tool name as `Bad check spec: <check> (no tool name)`. Reword the helper comment to "fails when the transcript cannot be read; unparseable lines are skipped; the tool-name check applies only when an init event lists tools".

#### 7. mode1-equiv.py's exit-code contract still has two leaks: an exit-1 traceback, and the positional form's message for a wrong-arity `--check-spec`

**Severity:** Minor
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:148-191` (all of `main`), `:105-114` (`bash_calls`), `:117-129` (`parse_expected`)
**Move:** 4 (error consistency), 3 (consumer contract)
**Confidence:** High
**Legibility-target:** a fixture author reading `assert_mode1_equiv` output, which treats exit 1 as "the model did not compute it".

Evidence:
- **Traceback with exit 1.** Everything after `evs = events(transcript_path)` runs outside the `try` (`:163`). A readable transcript with a wrong-shape line (`123`, a string content block, a string `input`, a numeric `command`) raises inside `bash_calls` and exits 1 with a traceback, which `assert_mode1_equiv` does not label (Claim 14). The docstring promises the opposite: "none can escape as a traceback with exit 1" (`:32-34`).
- **Arity message.** (probe) `mode1-equiv.py --check-spec SKILL.md` (one operand) and `--check-spec SKILL.md 1 2` both print `mode1-equiv: expected 3 arguments` followed by the docstring, exit 2. For the `--check-spec` form the right count is 2. The usage text printed below the message is correct, so this is small.
- **Grammar.** (probe) `--check-spec … '1~'`, `' 1 '`, `'1_000'` and `'+1'` all exit 0. The docstring's grammar says a tolerance follows `~` and values are plain numbers (Claim 12, Mostly Accurate). Every committed spec is a plain decimal, so nothing is misread today. But `--check-spec` is presented as the gate that proves a spec is valid, and it accepts spellings outside the documented grammar.

**Recommendation:** Wrap the post-setup body so that any unexpected exception prints `mode1-equiv: checker error: …` and exits 2. Alternatively, validate event shape in `events()`/`bash_calls` and raise `SetupError`. Say "expected 2 arguments after --check-spec" on that branch. Either tighten `parse_expected` to a regex (`^[+-]?\d+(\.\d+)?([eE][+-]?\d+)?(~…)?$`) or widen the docstring to "anything Python's float() accepts; an empty tolerance means the default".

#### 8. Small wording and layout drift

**Severity:** Informational
**Location:** `test/skills/eval-helpers.bash:482-485`; `devcontainer-config/install.sh:1231`; commit `f9feb2c` message and rubric A11 author note
**Move:** 2, 4
**Confidence:** High
**Legibility-target:** a reader of bats output and of the review record.

Precedent: category-first diagnostics (`Generation failed for $fixture: …`, `Unknown check type: …`) used in `test/skills/eval-helpers.bash:82,173`. Refusal lines wrapped at 84 characters or less in `devcontainer-config/install.sh:1227-1251`.

- `assert_mode1_equiv` prints the checker's `mode1-equiv: <detail>` first and its own `mode1_equiv: FIXTURE/CHECKER SETUP ERROR (exit 2)…` label after it. The category comes second, and the two lines use two spellings of the check's name. Iteration 2 F6 noted the prefix pair, and it remains.
- The commit message and the rubric's A11 note quote the label as "SETUP ERROR, not a model result". The code says `FIXTURE/CHECKER SETUP ERROR (exit 2), not a model result` (Claim 21). A reader grepping the record for the commit's wording will not find it in the code.
- The new lead variant `ERROR: a process may be acting for an agent. install.sh installs only while no agent can run, because` is 101 characters. Every other line in the block is 84 or less (measured), so it wraps unevenly in an 80-column terminal.

**Recommendation:** Print the label before the checker output (capture the output, echo the label, then the output). Rewrap the lead variant into two lines. Leave the historical record as is, but quote the full label if the rubric row is edited again.

## What Looks Good

- **Bare `tool_called:<Tool>` now means "called at all"**, and the empty pattern no longer passes vacuously (Claim 19). The positive and negative arms parse `<Tool>[=<ERE>]` identically (`eval-helpers.bash:146-164`). This closes iteration 2's Finding 1.
- **`match_inputs` fails closed** on an invalid ERE with a labelled message, and `-e` stops a dash-leading pattern from being read as options (Claim 18). The init-tool check lists the run's tools in its message, which makes a misspelling self-diagnosing (Claim 17). Divergent-design's existing `tool_called:Read=…` is unaffected, because Read is offered there.
- **One setup-error boundary in mode1-equiv.py.** Every enumerated setup class exits 2 with a `mode1-equiv:` stderr line (Claim 13), and the fast pre-flight test runs every committed spec through `--check-spec` (Claim 15).
- **`DENY_RECORD_FLAGS`** is defined once and expanded once (Claim 23a), and the argv-pin test holds the literal. `CLAUDE_MODEL` goes in as one argv element (Claim 24).
- **The marker family is uniform.** `Bash tripwire:` and `Bash canary:` share the `Bash <mechanism>:` prefix, and the checker's tripwire text matches the generator's (`mode1-equiv.py:169`, `generate-reports.bash:272`).
- **C19 and C20 landed as recommended.** `deny_record` is reported as itself (Claim 27). The in-checkout header now reads `… (PID and command line; Q-062: …):`, and the lead line matches what was found (Claim 3).
- **The patterns file and suite names follow precedent** (`_RE` constants, `<skill>-<topic>.bats`, a fixture-keyed associative array). `AE_GRADE_AFTER_DENIAL`'s skip message names the knob and the value that enables it.

## Summary Table

| # | Finding | Severity | Location | Confidence | Legibility-target |
|---|---------|----------|----------|------------|-------------------|
| 1 | Bash canary fires on every run with no init event, blaming the deny rule | Inconsistent | `test/skills/generate-reports.bash:280-287` | High | operator reading `.failed` |
| 2 | Dispatcher test's "resolves by skill" is untested (A6 revert stays green) | Minor | `test/skills/mode1-equiv.bats:239-261` | High | next editor of `assert_mode1_equiv` |
| 3 | Under deny-record, a wrong FIXTURE_TOOLS gets 3 different errors, one self-contradicting | Minor | `test/skills/runner-contract.bash:63-121` | High | runner author |
| 4 | CLAUDE_FLAGS contract described 4 ways; Environment block silent | Minor | `test/skills/generate-reports.bash:78`; `docs/decisions/log.md:77`; DD `:173-174` | High | operator |
| 5 | Blind-scan NOTE: stderr vs stdout, no consequence clause, untested, not in usage | Minor | `devcontainer-config/install.sh:1166-1169`, `:59-63` | High | operator; Q-064 [3] implementer |
| 6 | `tool_called` bare message prints `/./`; empty tool name passes or mis-reads; helper doc overstates | Minor | `test/skills/eval-helpers.bash:146-164,376-462` | High | fixture author |
| 7 | mode1-equiv.py: exit-1 traceback on bad transcript shape; `--check-spec` arity message; permissive grammar | Minor | `test/skills/arithmetic-eval/mode1-equiv.py:117-191` | High | fixture author |
| 8 | Label order and prefixes, label misquoted in the record, 101-column lead line | Informational | `eval-helpers.bash:482-485`; `install.sh:1231` | High | reader |

## Overall Assessment

f9feb2c resolved every API item iteration 2 raised, and each resolution was checked:
- the bare/empty `tool_called` semantics
- the fail-closed negative check
- the exit-2 consumer label
- the runner-contract error order
- the lead line and header
- the one flag definition

It introduced no Breaking change, and its new names follow their neighbours. What remains is the edges of those same surfaces rather than new design problems:
- The canary's diagnosis assumes an init event exists (1).
- One named test property is not actually tested (2).
- The dependency-order rule applied for C19 was not applied to deny-record's own tools rule (3).
- Docs and the Environment block lag the stricter CLAUDE_FLAGS rule (4).
- The new NOTE was written without reference to its two siblings (5).
- The tool-check and checker contracts still have small leaks, each already half-noted by the fact-check (6, 7).

All of these can be fixed in place, and each is at most a few lines plus a test. Consumer impact is low: the only committed consumers are arithmetic-eval's five fixtures and divergent-design's `tool_called:Read=`, and none of these findings changes a result they get today. Finding 1 is the one worth fixing before the first real deny-record regeneration, because its misleading text will appear on exactly the runs an operator has to triage.

## Goal-Alignment Note

- **Success criterion (restated):** "A markdown critique saved to the path named in your role section below, structured per your skill." The file is saved at `docs/reviews/api-consistency-review-2026-09-25-q062-q063-iter3.md` with `Commit: c7747c7` at the top. It has the skill's sections (Baseline, Name-Pattern Audit, Findings, What Looks Good, Summary Table, Overall Assessment). Every finding carries Severity, Location, verbatim Evidence, Confidence and Legibility-target, and each naming-shaped finding (3, 5, 8) carries a `Precedent:` line. The work is not committed.
- **Answered:** every focus surface in the brief.
  - `tool_called`/`no_tool_called` semantics and messages: bare form, empty pattern, init-tool check (F6, audit).
  - The SETUP ERROR label (F7, F8).
  - The `--check-spec` CLI and spec grammar (F7, audit).
  - Generator messages: the CLAUDE_FLAGS wording (F4) and canary vs tripwire (F1, audit).
  - Runner-contract message order (F3).
  - install.sh lead-line variants and the blind NOTE vs its sibling NOTEs (F5, F8).
  - `AE_GRADE_AFTER_DENIAL` and the patterns-file naming (audit, What Looks Good).
  - Each iteration-2 fix was re-checked, with a status (the table under Baseline).
- **Out of scope / not re-reported:**
  - C13 and C24 (per brief), and C6/C8 (open by choice). F1's duplicated init-event read is the C8 family and is not raised separately.
  - Claims 8 and 29c (the vacuous `!` and the shellcheck gate): escalated to the orchestrator.
  - Claim 2b's substance: escalated to the security reviewer. F5 cites it only as context for the NOTE's contract.
- **Escalate:** F1 and F5 are the two items most likely to confuse a human on a real run, and each is a small fix. F2 means C18's author note ("dispatcher-level tests") is only partly true for the `mode1_equiv:` arm. The rubric may want to reflect that.
- **Probes:** they ran in `/tmp/claude-1000/-workspace/be3f0769-…/scratchpad/api3/` (the generator stub, the eval-helpers edge cases, mode1-equiv arity and grammar, the runner-contract order, and the A6-revert copy). They were not saved as execution logs; their inputs and outputs are quoted inline.
