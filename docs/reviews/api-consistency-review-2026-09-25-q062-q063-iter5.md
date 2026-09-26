Commit: 9c73ae4

# API Consistency Review: skill-fixtures, fix 272bc83 (iteration 5 of 5, terminal pass)

**Scope:** `git diff main...HEAD` on `skill-fixtures`, focused on `git show 272bc83`. Surfaces: `test/skills/transcript.jq` as a module interface; `transcript_jq`, `transcript_checked` and `tool_inputs_checked` in `test/skills/eval-helpers.bash`; the `mode1-equiv.py` CLI change and its exit contract; the generator's `.failed` marker strings; the `test/skills/malformed-transcripts.bash` helper.
**Date:** 2026-09-25 (probes ran 2026-09-26T05:56:53Z UTC)
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 9c73ae4, 37 claims). Its executed verdicts are cited by claim number and not re-verified here.
**Own probes:** `docs/reviews/execution-logs/acr-9c73ae4-probes.sh` (passes `shellcheck -x -e SC1091 -s bash -S warning`) → `acr-9c73ae4-probes.txt`. The run used jq 1.6 and no `claude` or network commands.

Settled items are not re-raised: the override log (C4, C5, C9, C6, trap RETURN, `--tools` variadic, `RUNNER_ALLOWED_TOOLS`), A1 (Q-064), A20, C24, C30, and the open-by-choice rows C3/C4/C6/C8/C13/C14/C15/C34/C35. Where a finding touches one of those rows, it says so and covers only what 272bc83 newly introduced.

---

## Baseline Conventions

- **Eval helper names** (`test/skills/eval-helpers.bash`). Graders are `assert_<noun>` / `assert_no_<noun>` and take positional args, not check syntax. The dispatcher `eval_fixture` alone parses `<check>:<Tool>=<ERE>` into `(tool, ERE)` (`:146-161`). Plumbing helpers are `<noun>_<noun>`: `eval_transcript_path`, `transcript_tool_inputs`, `field_values`, `claim_heading_re`. Before 272bc83, `tool_inputs_checked` (7bd0974) was the only `_checked` name. It means "produce <noun>, after validation".
- **Diagnostic vocabulary.** A tool invocation is a "call": `"$tool calls seen: N"` (`eval-helpers.bash:463`), `"No $tool call."` (`:462`), `"Bash tripwire: N Bash call(s)"` (`generate-reports.bash:311`). Earlier review rounds settled that one condition gets one greppable label (A24: "`Bash canary:` vs `Bash parser canary:` (grepping one misses the other)"). They also settled that a label names the condition that fired (A17).
- **Checker CLI** (`mode1-equiv.py`). Positional `<SKILL.md> <input> <expected>`, plus a `--check-spec` mode. Exit 0/1/2 = match / model result / setup fault, with stderr prefix `mode1-equiv: `. This follows the repo's convention of exit 2 for usage and setup (A10).
- **jq definitions.** There is no module precedent: `transcript.jq` is the only `.jq` file outside `docs/reviews/`. The only other named jq defs are inline in `hooks/auto-approve-allowed-commands.sh:337-384`, and they are verb_noun (`get_part_value`, `extract_commands`).
- **Test helpers** (`test/*.bats`, `test/skills/*.bats`). Functions are verb_noun (`make_skill`, `make_deny_skill`, `stub_transcript`, `with_expr`). Shared tables are UPPER_SNAKE arrays (`KEY_CHECK`, `EXPECTED_VERDICT`, `DENY_RECORD_FLAGS`, `RUNNER_ALLOWED_TOOLS`).

---

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `transcript.jq` (module, imported `as t`) | module | _(none: first jq module)_ | none; searched `rg --files -g '*.jq'` repo-wide (only `docs/reviews/execution-logs/cfc-5bdee46-gen.jq`) | New category. Its header documents the invocation (`:9`). |
| `events`, `problems`, `init`, `tool_uses`, `denials` | jq def | `get_part_value`, `find_cmd_substs`, `extract_commands` | `hooks/auto-approve-allowed-commands.sh:337-384` | Consistent within the module (plural nouns for arrays, singular for the nullable `init`). It departs from the hooks' verb_noun style, but that is a different subsystem with no import relation. Acceptable. |
| `tool_result_ids` | jq def | `tool_uses`, `denials` (siblings, which return objects) | `test/skills/transcript.jq:70-75` | Minor asymmetry: siblings return objects, this one returns bare ids (Finding 10). |
| `deny_record_counts` → `{undenied, unseen, orphans, foreign}` | jq def + fields | `FIXTURE_BASH=deny-record`; generator marker words "tripwire", "parser canary" | `test/skills/generate-reports.bash:34,304-317` | Def name consistent with the mode name. Fields mix adjectives and a plural noun, and the helper's message says "orphan" (Finding 10). |
| `_is_str`, `_event_problems`, `_set` | jq private def | _(none)_ | none; searched `*.jq`, `hooks/*.sh` jq programs | New convention (leading `_` = private). Applied consistently. |
| `transcript_jq` | bash fn | `transcript_tool_inputs`, `eval_transcript_path` | `test/skills/eval-helpers.bash:357,383` | Consistent (`transcript_` prefix, noun-noun). |
| `transcript_checked` | bash fn | `tool_inputs_checked` | `test/skills/eval-helpers.bash:417` | Inconsistent. The same suffix names a producer and a status-only validator (Finding 9). |
| `EVAL_HELPERS_DIR` | global | `SCRIPT_DIR` | `test/skills/generate-reports.bash:85`, `scripts/skill-usage-report.sh:15` | Consistent. The prefix avoids clobbering in a sourced file, which is the right call. |
| `commands()` / `<commands.json>` | py fn / CLI arg | `reference()`, `parse_expected()`, `read_text()` | `test/skills/arithmetic-eval/mode1-equiv.py:76-121` | Consistent (noun functions). |
| `"Bash commands seen: N"`, `"  command i: …"`, `"No Mode 1 command computed…"` | diagnostic | `"$tool calls seen: N"`, `"No $tool call."` | `test/skills/eval-helpers.bash:462-463` | Inconsistent: "command" vs "call" in the same eval output (Finding 8). |
| `"mode1-equiv: checker error: …"` | stderr label | `"mode1-equiv: " + SetupError` | `mode1-equiv.py:155` | Consistent prefix. |
| `"transcript: could not be read…"`, `"transcript: N malformed event(s)…"` | marker | `"no init event in the stream…"`, `"Bash tripwire:"`, `"Bash parser canary:"`, `"Bash init canary:"` | `test/skills/generate-reports.bash:293-317` | Inconsistent: the prefix covers 2 of the 3 generic transcript checks (Finding 3). |
| `"Bash tripwire: N denial(s) of a tool other than Bash"` | marker | the comment bullet "only Bash may be denied"; `"Bash tripwire: N Bash call(s)…"` | `test/skills/generate-reports.bash:272-278,311` | Inconsistent: the label is the tripwire's, but the condition is a separate one (Finding 3). |
| `"generation did not finish"` | marker | `"claude exited N"`, `"no result event in the stream"` | `test/skills/generate-reports.bash:245,261` | Consistent (plain lower-case sentence, no prefix, like the other run-level states). |
| `"Malformed transcript $t: …"`, `"Bash tripwire/parser canary: …"` | eval message | generator's `"transcript: N malformed event(s)"`, `"Bash tripwire:"`, `"Bash parser canary:"` | `test/skills/generate-reports.bash:299,311-317` | Inconsistent: same conditions, different strings across the generator/eval boundary (Finding 3). |
| `write_malformed_transcripts`, `MALFORMED_SHAPES` | test helper fn / array | `make_skill`, `stub_transcript`; `KEY_CHECK`, `DENY_RECORD_FLAGS` | `test/generate-reports.bats:*`, `test/skills/mode1-equiv.bats:30-40` | Consistent. |
| shape ids (`array_wrapped`, `no_id`, …) | enum | _(none)_ | none; searched `test/**/*.bash`, `test/**/*.bats` | New. snake_case, consistent with each other. |

---

## Findings

### 1. transcript.jq validates one set of shapes and reads another: a tool_use it accepts can be one no reader counts

**Severity:** Inconsistent
**Location:** `test/skills/transcript.jq:35-79` (contract stated at `:6-7`, `:68-69`; restated in `docs/working/dd-arith-eval-bash-grant.md:175`, `docs/decisions/log.md:77`, `test/skills/eval-helpers.bash:380-381,389-391`, 272bc83 message)
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** High (the fact-check executed this: Claims 26, 29, probes P9, P10, E2)
**Legibility-target:** for-author
**Name-pattern:** n/a (not a naming finding)

The module's interface is a pair: `problems` says what is well formed, and `tool_uses` / `tool_result_ids` / `denials` say what is read. For the module's promise to hold, the two must cover the same domain. They do not:

```jq
# test/skills/transcript.jq:38-44 (excerpt ends :44; _event_problems continues to :60 — read)
  elif (.type == "assistant" or .type == "user") then
    if (.message | type) != "object" then "\(.type) event: message is not an object"
    elif (.message.content | type) != "array" then "\(.type) event: message.content is not an array"
    else
      .message.content[] |
      if type != "object" or ((.type // null) | _is_str | not) then "a content block is not an object with a string type"
      elif .type == "tool_use" then
```

```jq
# test/skills/transcript.jq:70-72
def tool_uses:
  [.[] | objects | select(.type == "assistant") | .message.content[]? | objects | select(.type == "tool_use")
   | {id, name, input}];
```

A tool_use in a `user` event is validated as well formed and never read. The same goes for a `tool_result` in an `assistant` event. An event whose `type` is missing, unknown or not a string falls through to `else empty` (`:60`), so it is neither a problem nor read. Consumers are told the opposite: "an unexpected shape is a problem, never skipped" (`:6-7`), and "every tool_use, at any depth" (`:68-69`). The consumers are `no_tool_called`, `tool_called`, `mode1_equiv` and the generator's deny-record counts. The fact-check shows the effect: the generator (deny-record included) and `assert_no_tool_called Bash rm` pass an undenied `rm -rf x` placed in a `user` event (Claims 26, 29). This is R2's class again. The 13-shape table closes the named shapes, but the interface still has a gap between "validated" and "read". Reachability with the current CLI is unknown, since no real transcript is in the repo (Claim 27a).

**Recommendation:** Make the two domains one. Any `tool_use` block outside an assistant event's top-level content is a problem, and any `tool_result` outside a user event is a problem. An event whose `type` is not a string, or is an unknown type carrying `message`, is a problem too. Alternatively, have `tool_uses` read every `tool_use` in any event at any depth (`.. | objects | select(.type == "tool_use")`) and have `tool_result_ids` do the same. Then add `tool_use_in_user_event`, `typeless_event_with_tool_use`, `renamed_event_type` and `tool_use_inside_tool_result` to `MALFORMED_SHAPES`. If neither is done, narrow all six statements of the contract to the fact-check's precise wording (Claim 26).

### 2. The table test's no_tool_called leg passes check syntax to a function that takes `(tool, ERE)`, so it fails on the control and discriminates nothing

**Severity:** Inconsistent
**Location:** `test/skills/mode1-equiv.bats:315-316` (in the test `:300-318`); the interface is `test/skills/eval-helpers.bash:490-503`, the dispatcher's split is `:155-161`
**Move:** 3 (consumer contract / test drift), 2
**Confidence:** High (executed: `acr-9c73ae4-probes.txt` A1)
**Legibility-target:** for-author
Precedent: `assert_no_tool_called <tool> [ERE]` called with separate args in `test/skills/eval-helpers.bash:158` and `test/skills/mode1-equiv.bats:146-165`; the `<Tool>=<ERE>` form exists only as `eval_fixture` check syntax (`eval-helpers.bash:155-161`)

```bash
# test/skills/mode1-equiv.bats:310-317 (excerpt starts inside the @test at :300 and ends at the loop's `done`; the test closes at :318 — read)
  for shape in "${MALFORMED_SHAPES[@]}"; do
    cp "$TEST_TMPDIR/bad/$shape.jsonl" "$T"
    run assert_mode1_equiv arithmetic-eval '2'
    [ "$status" -ne 0 ] || { echo "mode1_equiv passed on $shape"; return 1; }
    [[ "$output" == *"Malformed transcript"* ]] || { echo "$shape: $output"; return 1; }
    run assert_no_tool_called Bash=rm
    [ "$status" -ne 0 ] || { echo "no_tool_called passed on $shape"; return 1; }
  done
```

`Bash=rm` reaches `assert_no_tool_called` as the tool name. On the control transcript (the same file minus its bad line), the probe gives `assert_no_tool_called Bash=rm -> exit 1 : Bash=rm is not a tool of this run (its tools: Bash )`. So this leg fails with or without the bad shape, and it would keep "passing" if `problems` were stubbed to `[]`. It is the A5 confusion (check syntax vs function arguments), reintroduced in a test. As a result, the rubric's R2 "Fixed … for the generator and for mode1_equiv/no_tool_called" rests on the `mode1_equiv` leg alone for the eval side. Note that the fact-check's Claim 2 verified the test's pass status, not what this leg discriminates.

**Recommendation:** Use the function's own argument shape, `run assert_no_tool_called Bash pwd`. `pwd` is the bad line's command and does not occur in SKILL.md's Mode 1 block. Assert the status and also `[[ "$output" == *"Malformed transcript"* ]]`, because several shapes carry no Bash call at all (`denials_number`, `number_line`, `deep`, `tool_result_no_id`). Then add the missing control, the same call on the control transcript, which must give status 0. The leg then fails only because of the reader.

### 3. One condition, several labels: marker and message strings diverge across the generator/eval boundary and inside the generator

**Severity:** Inconsistent
**Location:** `test/skills/generate-reports.bash:293-317`; `test/skills/eval-helpers.bash:398-408,528`
**Move:** 4 (error consistency), 2
**Confidence:** High
**Legibility-target:** for-author
Precedent: one label per condition, settled in A24 ("`Bash canary:` vs `Bash parser canary:` (grepping one misses the other)") and A17 (label names the condition that fired); labels in `test/skills/generate-reports.bash:299-317`

The commit's premise is that "a Bash call", "denied" and "seen" are defined once. Their failure strings are not:

| Condition | Generator `.failed` | eval-helpers message |
|---|---|---|
| malformed | `transcript: $n_problems malformed event(s), first: $problems (CLI $cli_version)` (`:299`) | `Malformed transcript $t: $n event(s) of an unexpected shape, first: $first` (`:404`) |
| no init | `no init event in the stream (the run did not start?)` (`:302`) | `No init event in $t: not a complete stream-json transcript` (`:408`) |
| deny-record counts | `Bash tripwire:` / `Bash parser canary:` ×2 / `Bash tripwire:` (`:311-317`) | `Bash tripwire/parser canary: undenied, unseen, orphan, foreign = $counts` (`:528`) |

Inside the generator there are two more problems. First, the new `transcript:` prefix covers "could not be read" and "malformed" but not "no init event", although the header comment groups all three as the transcript checks every run gets (`:266-270`). Second, foreign denials are labelled `Bash tripwire:` (`:317`), but the "Transcript checks" comment lists them as a separate condition ("only Bash may be denied", `:278`), and the tripwire is defined as "every Bash tool_use must be named by a Bash denial" (`:272`). A reader grepping `.failed` files for `Bash parser canary` misses the eval-side `Bash tripwire/parser canary`. Grepping `transcript:` misses a no-init void, and grepping `malformed` finds the generator's marker and eval's `Malformed` only with `-i`. The probe (A3) shows eval's composite string on a foreign-only denial: `= 0 0 0 1`, labelled "tripwire/parser canary".

**Recommendation:** Pick one string per condition and use it on both sides. For example: `transcript: N malformed event(s), first: …`, `transcript: no init event …`, `Bash tripwire: …`, `Bash parser canary: …`, `Bash foreign denial: …`. Have `assert_mode1_equiv` emit the same per-count lines. Better still, define the messages once as a `def deny_record_failures` in `transcript.jq` that returns the list of labelled strings, so both consumers print what the module returns.

### 4. `init` is exported without a shape contract, so each consumer re-derives "init lists tool X" with different semantics

**Severity:** Minor
**Location:** `test/skills/transcript.jq:65-66`; `test/skills/generate-reports.bash:288-289`; `test/skills/eval-helpers.bash:428-429`
**Move:** 8 (nullability), 7
**Confidence:** High (executed: `acr-9c73ae4-probes.txt` A2)
**Legibility-target:** for-author
**Name-pattern:** n/a

The accepted-shapes list (`transcript.jq:12-19`) says nothing about the init event, although three consumers read its fields:

```jq
# test/skills/generate-reports.bash:288-289 (inside the jq program :286-291, inside generate_one :141-335 — read)
        (t::init | if . == null then "none" elif ((.tools // []) | type == "array" and index(["Bash"]) != null) then "bash" else "nobash" end),
        (t::init | .claude_code_version // "unknown"),
```

```bash
# test/skills/eval-helpers.bash:428-429 (excerpt ends :429; tool_inputs_checked continues to :434 — read)
  known="$(transcript_jq "$t" 't::init | .tools // [] | if type == "array" then .[] | strings else empty end' 2>/dev/null || true)"
  if [ -n "$known" ] && ! printf '%s\n' "$known" | grep -qxF -e "$tool"; then
```

With `"tools":"Bash"` (a string), the generator reads `nobash` and voids a deny-record run. The eval side reads "no tools list" and turns its misspelling guard off: `assert_tool_called Bahs` gives `No Bahs call.`, not "not a tool of this run" (probe A2), so `no_tool_called:Bahs` would pass. The version field is the other half: it is free text in a positional protocol, which is Finding 5.

**Recommendation:** Add the init event to the module's contract. `problems` should report an init whose `tools` is present and not an array of strings, or whose `claude_code_version` is present and not a plain version string. Export `def init_tools: (init.tools // [])` so the generator and eval-helpers share one reading.

### 5. The reader's results reach bash through per-consumer positional `\x1f` records, and the free-text version field sits before the counts

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:285-318`; `test/skills/eval-helpers.bash:394-402`
**Move:** 7, 8
**Confidence:** High (the fact-check executed this: Claim 22b, probe P1)
**Legibility-target:** for-author
**Name-pattern:** n/a

The unnamed positional schema itself is rubric C35 (open by choice) and is not re-raised. What 272bc83 added is a five-field record whose fourth field is CLI-written free text, ahead of the counts:

```bash
# test/skills/generate-reports.bash:297
      IFS=$'\x1f' read -r n_problems problems init_state cli_version counts <<< "$verdict"
```

A newline in `claude_code_version` ends the `read` early, `counts` comes back empty, `[ -n "$counts" ]` (`:307`) skips all four deny-record checks, and the fail-closed marker is removed with an undenied Bash call present (Claim 22b, P1). eval-helpers builds its own three-field record from the same module (`:396`), so the module has two ad hoc wire formats and no exported one. Reachability is low, because the field is CLI-written (Claim 22b scope).

**Recommendation:** Emit the verdict as one JSON object from a module def (for example `def verdict: {problems, init_state, cli_version, counts: deny_record_counts}`). Read each field with its own `jq -r` call, or with `@sh` into `declare`. At minimum, put `counts` first, strip control characters from `cli_version` (`gsub("[\\u0000-\\u001f]"; "?")`), and treat an empty `counts` under deny-record with no problems as a failure rather than a skip.

### 6. mode1-equiv's exit contract still overclaims "exit 1 always means a model result"; `--check-spec` does not check what the main mode depends on

**Severity:** Inconsistent
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:34-37,76-88,124-137`; `docs/working/dd-arith-eval-bash-grant.md:182`
**Move:** 4 (error consistency), 3
**Confidence:** High (the fact-check executed this: Claim 14, probe E5)
**Legibility-target:** for-author
**Name-pattern:** n/a

```python
# test/skills/arithmetic-eval/mode1-equiv.py:124-137
def evaluate(program, expr):
    """Run <expr> through the reference evaluator; return its value or None."""
    try:
        r = subprocess.run(["python3", "-c", program], input=expr + "\n",
                           capture_output=True, text=True, timeout=10)
    except subprocess.TimeoutExpired:
        return None
    m = re.search(r"-> (\S+)\s*\Z", r.stdout)
    if r.returncode != 0 or not m:
        return None
    try:
        return float(m.group(1))
    except ValueError:
        return None
```

The docstring says "2 on anything else: a usage, spec, file or SKILL.md problem … Exit 1 therefore always means 'the model's commands did not compute the value', never a checker fault." Yet a SKILL.md whose evaluator prints `=> {result}` passes `--check-spec` (exit 0), and a correct Mode 1 command then exits 1 (E5). Every fixture would read as "the model did not route", which is exactly what the exit contract exists to prevent. `--check-spec` is sold as the pre-flight that catches a broken setup "before any paid run" (`:32-33`), but it validates only the extraction (`reference()`), not the evaluator's output format that `evaluate()` needs. This is the fifth report of the same contract (A10 → A11 → A19 → A21 → here). Each fix has caught a new class of *raised* error, while this failure is a *non-raising* one.

**Recommendation:** In `reference()`, which both modes run, execute the extracted evaluator on a fixed self-test expression (for example `1 + 1`), and raise `SetupError` unless `evaluate()` returns 2.0. That moves evaluator drift to exit 2 in both modes. Then narrow the docstring and DD `:182` to the one residual: "a reference-evaluator timeout on the model's expression is read as exit 1". A model expression can legitimately hang, so a timeout is ambiguous by nature.

### 7. mode1-equiv's CLI re-types a positional argument at the same arity; one test still passes the old type

**Severity:** Minor
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:23-25,148-153`; `test/skills/mode1-equiv.bats:108-116`
**Move:** 6 (versioning), 3 (test drift)
**Confidence:** High
**Legibility-target:** for-author
**Name-pattern:** n/a

Argument 2 changed from `<transcript.jsonl>` to `<commands.json>` at the same arity. It is handled well: an old-shape caller now gets exit 2 (`is not JSON` or `is not a JSON array of strings`), not a silent misread. `assert_mode1_equiv` is the only production caller and was updated. One test was not:

```bash
# test/skills/mode1-equiv.bats:108-111 (excerpt ends :111; the test continues to :116 — read)
@test "a bad value spec or missing argument exits 2 with a message, not a traceback" {
  transcript "$(with_expr '1 + 1')"
  run python3 "$BATS_TEST_DIRNAME/arithmetic-eval/mode1-equiv.py" "$SKILL_MD" "$T" 'abc'
  [ "$status" -eq 2 ]
```

`$T` is a transcript. The test passes only because `main()` validates the spec before it reads the commands (`:151-153`). If the order changed, the test would still pass, but on "is not JSON" rather than "bad expected value", and the assertion on `:112` would catch that.

**Recommendation:** Pass a valid commands file there (`jq -cn '[]' > "$c"`), so the test exercises only the spec error it names.

### 8. The checker says "command" where every sibling diagnostic says "call"

**Severity:** Minor
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:158-176`
**Move:** 2
**Confidence:** High
**Legibility-target:** for-author
Precedent: "call" for a tool invocation in diagnostics, used in `test/skills/eval-helpers.bash:462-463` (`"No $tool call."`, `"$tool calls seen: N"`) and `test/skills/generate-reports.bash:311` (`"Bash call(s) not in permission_denials"`)

272bc83 renamed the checker's output from `Bash calls seen: N` / `call i:` to `Bash commands seen: N` / `command i:` / `No Mode 1 command computed…`. Both kinds of line land in the same `eval_fixture` output, so a failing `tool_called:Bash` next to a failing `mode1_equiv:` now counts the same objects under two nouns. The rename is defensible, since the checker now receives command strings, not tool_use events. But consumers see only the output.

**Recommendation:** Either keep "call" in the checker's output, or add the noun once: `Bash calls seen (commands checked): N`. Low priority.

### 9. `_checked` now names both a producer and a status-only validator

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:392` (`transcript_checked`), `:417` (`tool_inputs_checked`); generator local `problems` at `test/skills/generate-reports.bash:285,297`
**Move:** 2
**Confidence:** Medium
**Legibility-target:** for-author
Precedent: `tool_inputs_checked` in `test/skills/eval-helpers.bash:417` (the only earlier `_checked` name) prints the checked inputs on stdout

`tool_inputs_checked` returns data: the tool's inputs, after checks. `transcript_checked` returns no data, only a status and an error message. By the existing name, a reader expects `transcript_checked` to print the transcript, or its events. A related small drift: the generator binds the *first* problem string to a local named `problems`, while the module's `problems` is the list and eval-helpers names the same field `first` (`:401`).

**Recommendation:** Rename `transcript_checked` to `check_transcript` or `transcript_ok`, or document `_checked` as "validated; prints X when X is data". Rename the generator local to `first_problem`.

### 10. Module output shapes and count names are uneven

**Severity:** Informational
**Location:** `test/skills/transcript.jq:74-101`; `test/skills/eval-helpers.bash:528`
**Move:** 2, 7
**Confidence:** Medium
**Legibility-target:** for-author
No existing precedent in `rg --files -g '*.jq'` (repo-wide) and the jq programs in `hooks/*.sh`, `test/skills/*.bash`

`tool_uses` and `denials` return objects, while `tool_result_ids` returns bare ids. The counts `{undenied, unseen, orphans, foreign}` mix adjectives with one plural noun, and eval's message spells it `orphan`. `unseen`'s gloss ("naming a tool_use the parser did not see") is wider than its code, which checks only Bash tool_uses (Claim 30). None of these has an established convention to break. This is a new module, so the conventions are being set now. The no-precedent rule applies: Minor, downgraded to Informational.

**Recommendation:** Rename to `tool_results` returning `{tool_use_id}` objects, or document the asymmetry. Rename the fields to `undenied, unseen, orphaned, foreign`. Correct the `unseen` gloss to "Bash denials naming no Bash tool_use the reader saw".

### 11. Two lenient readers remain beside the "one strict reader"

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:473-483` (`assert_subagents_min`); `test/skills/generate-reports.bash:252-257`
**Move:** 1 (baseline), 3
**Confidence:** High (the fact-check executed this: Claims 11, 21, probe E3)
**Legibility-target:** for-author
**Name-pattern:** n/a

```bash
# test/skills/eval-helpers.bash:476-478 (excerpt starts inside assert_subagents_min(), which begins :473; continues to :483 — read)
  n=$(jq -rR 'fromjson? | select(.type == "assistant" and .parent_tool_use_id == null)
       | .message.content[]? | select(.type == "tool_use" and .name == "Agent")
       | .name' "$t" | grep -c . || true)
```

`subagents_min:` is a sibling of `tool_called:` in the same check grammar. The generator's report text and `is_error` state are read the same lenient way. Voiding does not depend on them (Claim 21), but `assert_subagents_min` used directly passes on a transcript that `transcript_checked` rejects (E3). The documented "every transcript is read through one strict reader" (log #56, DD `:175`) is therefore false for one grader.

**Recommendation:** Route `assert_subagents_min` through `transcript_checked` and `t::tool_uses` (the module would need `parent_tool_use_id` kept on each use). Optionally add `def result_event` for the generator's report and `is_error` reads.

### 12. `write_malformed_transcripts` provides no control; both consumers derive it from one shape's internals

**Severity:** Minor
**Location:** `test/skills/malformed-transcripts.bash:7-47`; `test/generate-reports.bats:632`; `test/skills/mode1-equiv.bats:307`
**Move:** 3
**Confidence:** High
**Legibility-target:** for-author
**Name-pattern:** n/a

Both table tests build their control with `grep -v '^123$' "$TEST_TMPDIR/bad/number_line.jsonl"`. This couples each consumer to the literal bad line of one shape. The helper's own header promises the property the control proves ("a reader that skips the bad line sees a fully passing run"), but its interface does not expose the control. The header's "(id x1)" is also not true for `object_id` and `no_id` (Claim 25).

**Recommendation:** Have the helper also write `<dir>/control.jsonl` (init, g1, result), and point both consumers at it. Correct the header to "id x1, or an id the reader cannot use".

### 13. Contract prose drifted from the new interface

**Severity:** Minor
**Location:** `docs/decisions/log.md:77`; `test/skills/eval-helpers.bash:77-79`; `test/skills/eval-helpers.bash:380-381`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claims 1, 16, 29)
**Legibility-target:** for-author
**Name-pattern:** n/a

Log #56 lists three voiding conditions. It omits malformed events, the tool_result canary and foreign denials, although the commit says the list lives "once, in generate_one". `eval_fixture`'s comment lists what `.failed` records as "(claude's exit status, or an error/missing result event)" and omits transcript voids and "generation did not finish". `transcript_tool_inputs` still says "at any depth".

**Recommendation:** Replace log #56's list with a pointer to `generate_one`'s "Transcript checks" comment. Use the fact-check's precise wordings for the other two (Claims 16, 29).

---

## What Looks Good

- **One module, one import form.** Both consumers invoke `transcript.jq` identically (`jq -rR -n -L <dir> 'import "transcript" as t; t::events | …'`), exactly as its header documents (`:9`). `transcript_jq` wraps that in one place for the eval side. `EVAL_HELPERS_DIR` makes resolution independent of `BATS_TEST_DIRNAME` (Claim 17).
- **The `_` private-def convention** is applied consistently, so the public surface is easy to read: `events`, `problems`, `init`, `tool_uses`, `denials`, `tool_result_ids`, `deny_record_counts`.
- **The mode1-equiv CLI change fails loudly for old callers.** A transcript path passed as `<commands.json>` exits 2 with a message, never a silent misread. The usage and arity strings now match between modes ("expects 3 arguments: …", "--check-spec expects 2 arguments: …"), which closes A19's arity item. The stderr prefix `mode1-equiv:` is uniform, including the catch-all (Claims 3, 15).
- **The fail-closed marker** reuses the existing plain-sentence style for run-level states ("generation did not finish" beside "claude exited N").
- **A25's fixes** hold: an empty tool name fails with a message, and a bare `tool_called:` failure says "No Bash call." (Claim 7).
- **Test helper naming** (`write_malformed_transcripts`, `MALFORMED_SHAPES`, snake_case shape ids) matches the suite's verb_noun / UPPER_SNAKE conventions.

---

## Summary Table

| # | Finding | Severity | Location | Confidence | Legibility-target |
|---|---|---|---|---|---|
| 1 | transcript.jq validates one domain and reads another (user-event tool_use, unknown types, nested) | Inconsistent | `test/skills/transcript.jq:35-79` | High | for-author |
| 2 | Table test's `assert_no_tool_called Bash=rm` fails on the control; the eval-side no_tool_called leg discriminates nothing | Inconsistent | `test/skills/mode1-equiv.bats:315-316` | High | for-author |
| 3 | Same condition, different labels: generator vs eval, `transcript:` prefix partial, foreign denial labelled tripwire | Inconsistent | `generate-reports.bash:293-317`, `eval-helpers.bash:404-408,528` | High | for-author |
| 6 | mode1-equiv "exit 1 always a model result" refuted; `--check-spec` skips evaluator format | Inconsistent | `mode1-equiv.py:34-37,124-137` | High | for-author |
| 4 | `init` has no shape contract; tools-list reading diverges | Minor | `transcript.jq:65-66`, `generate-reports.bash:288`, `eval-helpers.bash:428` | High | for-author |
| 5 | Positional `\x1f` records; free-text version before counts (22b) | Minor | `generate-reports.bash:297` | High | for-author |
| 7 | Positional arg re-typed; one test still passes a transcript | Minor | `mode1-equiv.bats:110` | High | for-author |
| 8 | "command" vs "call" in eval diagnostics | Minor | `mode1-equiv.py:158-176` | High | for-author |
| 11 | `assert_subagents_min` and report/is_error reads stay lenient | Minor | `eval-helpers.bash:476-478`, `generate-reports.bash:252-257` | High | for-author |
| 12 | Malformed-transcripts helper has no control output | Minor | `malformed-transcripts.bash:7-47` | High | for-author |
| 13 | Log #56, `.failed` comment, "any depth" prose drift | Minor | `docs/decisions/log.md:77`, `eval-helpers.bash:77-79,380-381` | High | for-author |
| 9 | `_checked` names a producer and a validator | Minor | `eval-helpers.bash:392,417` | Medium | for-author |
| 10 | Uneven module output shapes and count names (new convention) | Informational | `transcript.jq:74-101` | Medium | for-author |

---

## Overall Assessment

272bc83 is the right shape of fix. It replaces three private parsers with one imported module, and gives the checker CLI a narrower input that fails loudly for old callers. Most of its new names fit the neighbouring conventions. The remaining inventory is about the module's *contract* rather than its naming. Its validation domain and read domain differ (Finding 1), so the promise stated six times, "never skipped", is not yet true, and the eval-side half of the table test that was meant to prove it does not discriminate (Finding 2). The failure vocabulary that A24 unified inside the generator has split again across the generator/eval boundary (Finding 3). The mode1-equiv exit contract overclaims for a fifth time (Finding 6), this time through a non-raising path that a `reference()` self-test would close for both modes. Everything is fixable in place. Findings 1, 2 and 6 are small code changes (a widened `tool_uses` or new problems, one test line, a self-test in `reference()`). Findings 3-5 would all shrink if `transcript.jq` also exported the labelled failure list and a JSON verdict, so that consumers print what the module decides instead of re-encoding it. For consumers, no fixture known today is misgraded: the gaps need transcript shapes or a SKILL.md edit that have not been observed.

---

## Goal-Alignment Note

**Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."

**Answered:** Yes. The critique is saved at `docs/reviews/api-consistency-review-2026-09-25-q062-q063-iter5.md` with `Commit: 9c73ae4` at the top. It follows the api-consistency-reviewer structure: header, baseline, name-pattern audit, findings with the precedent rule, what looks good, summary table and assessment. Every finding carries Severity, Location, verbatim Evidence (with truncation markers where an excerpt ends inside its unit), Confidence and Legibility-target, plus either a `Precedent:` / `No existing precedent in` line (naming findings 2, 3, 8, 9, 10) or `Name-pattern: n/a`. All five named surfaces are covered: the transcript.jq defs (1, 4, 5, 10), the eval-helpers functions (2, 3, 9, 11), the mode1-equiv CLI and exit contract (6, 7, 8), the marker strings (3) and malformed-transcripts.bash (2, 12).

**Out of scope:** Q-062's `install.sh` gate (unchanged since iteration 4), and the settled or open-by-choice rubric rows listed in the header. Finding 5 notes its overlap with C35 and covers only the new free-text field.

**Escalate:** Finding 2 is new at this pass and contradicts part of R2's "Fixed" note. The fact-check verified that the test passes, not that its no_tool_called leg can fail for the right reason. Findings 1 and 6 repeat escalations the fact-check already raised (Claims 26/29 and 14). Whether to fix them before the merge or record them as residuals is the user's call at this terminal pass.

**Decisions:** I rated Finding 1 Inconsistent rather than Breaking, because no existing consumer regressed: the pre-fix readers had the same assistant-only domain. The defect is the gap between the documented contract and the code. I rated Finding 6 Inconsistent because it is the checker's own documented contract, relied on by `assert_mode1_equiv`'s exit-2 label.
