# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** branch diff `git diff main...HEAD` (skill-fixtures), focused on fix commit b22a026 ("transcript census", review-fix loop iteration 5 → 6, terminal pass) and the rubric rows it marked Fixed
**Commit:** 299727c
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-09-26
**Total claims checked:** 38
**Summary:** 26 verified, 6 mostly accurate, 1 stale, 3 incorrect, 2 unverifiable

I read the hallucination-pattern log first (`docs/reviews/hallucination-patterns.md`, 5 entries). Claim 28 (the commit's "13 real runs … 21 tool_use, 21 tool_result") is near the logged class "a specific measured value quoted from a checked-in artifact set that does not contain it". But the artifact set is not in the repo, so the claim is Unverifiable, not refuted. The commit's pasted test counts, the other number of that kind, all re-run exactly (Claim 32). No Incorrect verdict is a fabricated symbol or API, so no log entry was added.

Execution logs are in `docs/reviews/execution-logs/cfc-299727c-*`. Every command ran with cwd `/workspace` unless its log says otherwise. jq is 1.6 and bats is 1.8.2. The three probe scripts (`cfc-299727c-{census,e2e,r3-c36}-probes.sh`) pass `shellcheck -x -e SC1091 -s bash -S warning`. `scripts/health-check.sh` passes with them in place: exit 0, "All checks passed.", started 2026-09-26T08:48:19Z (`cfc-299727c-health-check.txt`).

**Headline.** b22a026 closes every shape R3 named (9/9 fail, Claim 2). The census also holds against everything the brief asked me to try, except one case. Those were `type` variants (`"tool_use "`, `TOOL_USE`, a Cyrillic lookalike), JSON-in-string, duplicate keys, init `["Bash","Bash"]`, NUL bytes, `type` on arrays, text lines, 256+ nesting and a 20,000-call transcript. Every `type == "tool_use"` object sits in one of three places: it is counted, it trips the census/placement mismatch, or it is not a call in the CLI's format, so the CLI cannot have run it. The exception is the module's own marker key. An event object with a top-level `"__text"` key is dropped from the census, so an undenied Bash call and its `tool_result` inside such an event pass the generator (no `.failed`), `no_tool_called:Bash=pwd` and `mode1_equiv`, end to end (Claim 24). Separately, the event and block "allowlists" use jq's `inside/1`, which tests **substrings** for strings. So `""`, `"sys"`, `"tool"` and `"result"` are accepted types, and "anything else is a problem" does not hold (Claim 25b). That gap does not hide a `tool_use` call: the census still finds it. Neither shape is known to come from the CLI. Both refute absolutes stated in the module header, the generator comment, log #56, the DD doc and rubric A29. The commit's mutation numbers (12/16, 24) and test counts re-run exactly.

---

## Claim 1: "it voids a run when a Bash call is missing from `permission_denials` (tripwire), when a denial names a call the parser did not see (parser canary), or when the init event is missing or does not list Bash"

**Location:** `docs/decisions/log.md:77`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether log #56's list of voiding conditions matches `deny_record_failures`/`transcript_failures` at HEAD. It does not cover the row's census sentence, which is verdicted in Claim 24.

The iteration-5 report (its Claim 1) found this sentence Stale. b22a026 edited only the row's later sentences (`git show b22a026 --word-diff=plain -- docs/decisions/log.md`: the changes start at "Since review [-iteration 4,-]{+iterations 4-5,+}"). The list still says "does not list Bash", but the module now requires exactly `["Bash"]`:

```jq
# test/skills/transcript.jq:150
          | if init != null and $tools != ["Bash"] then "Bash init canary: the init event's tools are \($tools | tojson | _one_line), not exactly [\"Bash\"] (CLI \($cli))" else empty end,
```

The list also leaves out conditions the module applies: a call of a tool other than Bash (`transcript.jq:151-152`), the `tool_result` canary (`:157-158`), a denial of another tool (`:159-160`), and any malformed stream (`:141`, `problems`).

**Evidence:** `docs/decisions/log.md:77`, `test/skills/transcript.jq:139-162`

---

## Claim 2: R3 "Fixed by construction … An insertion property test … passes with 0 escapes; mutation back to positional reading gives 12/16 and 24 escapes."

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:17`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the defect R3 names: each named shape now fails deny-record (a user-event call, a missing/unknown/non-string event type, a call nested in a tool_result, `server_tool_use`, a reused denied id, ANSI and BOM prefixes). It also covers the property test passing and the mutation numbers. It does not establish "by construction" for every shape: an event with a top-level `__text` key hides a call (Claim 24), and the type allowlists accept substrings (Claim 25b).

`cfc-299727c-r3-c36-probes.sh` (2026-09-26T08:47:22Z, exit 0) puts each named shape beside a good denied call. All nine produce a failure line before `__VERDICT_COMPLETE__`. Examples: `user event: unknown content block type tool_use` / `a tool_use outside an assistant event's message.content`, `two tool_uses share an id`, `a line containing JSON-like text does not parse` (ANSI). The BOM line is not rejected as unparsable: jq 1.6 parses it, and the call is counted and tripwired (`Bash tripwire: 1 call(s) not in permission_denials`; see Claim 26). The two property tests pass in the suite run (Claim 32). The mutation re-run reproduces "12/16 and 24" (Claim 34).

**Evidence:** `test/skills/transcript.jq:56-57,96-105`, `docs/reviews/execution-logs/cfc-299727c-r3-c36-probes.txt`, `docs/reviews/execution-logs/cfc-299727c-mutation.txt`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 3: R4 "Fixed: the verdict is decided in the module and printed as one-line failure strings (control characters mapped to spaces) ending in a sentinel; the generator voids any verdict without it. Tests: a newline in the CLI version, and a jq wrapper that drops the sentinel."

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:18`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the R4 defect: a newline in `claude_code_version` or a missing sentinel no longer removes `.failed`. It does not establish the correctness of the checks inside the verdict (Claims 24, 25b).

The generator requires the sentinel as the last line:

```bash
# test/skills/generate-reports.bash:291-292
    if [ "${#verdict_lines[@]}" -eq 0 ] || [ "${verdict_lines[${#verdict_lines[@]}-1]}" != "__VERDICT_COMPLETE__" ]; then
      failure="${failure:+$failure; }transcript: could not be read in full, so no check could complete"
```

(excerpt ends :292; the enclosing `if` continues to :298, and generate_one to :313 — read). Both named tests exist (`test/generate-reports.bats:726`, "a newline in a verdict field…", and `:750`, "a verdict that did not finish (no sentinel line)…") and pass: 46/46, 2026-09-26T08:42:42Z, exit 0.

**Evidence:** `test/skills/generate-reports.bash:284-306`, `test/skills/transcript.jq:49-52,164-165`, `test/generate-reports.bats:726-770`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 4: A27 "Fixed — `reference()` self-tests SKILL.md's evaluator (`6 * 7` gives 42) in both modes; a format-changed SKILL.md now exits 2 … test."

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:52`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the self-test in `reference()`, which both modes call, and its test. It does not establish that exit 1 cannot come from an evaluator that misbehaves only on some inputs (the docstring states this limit; Claim 21).

```python
# test/skills/arithmetic-eval/mode1-equiv.py:96-97
    if evaluate(w[0], "6 * 7") != 42:
        raise SetupError("SKILL.md's Mode 1 evaluator failed its self-test (6 * 7 did not give 42)")
```

(excerpt ends :97; `reference()` continues to :98 `return w[0], dump` — read). `main()` calls `reference()` in `--check-spec` (`:155`) and in grading (`:161`). The test "a SKILL.md whose evaluator changed its output format fails the self-test: exit 2, in --check-spec too" passes (mode1-equiv.bats 31/31).

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:79-98,150-166`, `test/skills/mode1-equiv.bats:395-406`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 5: A28 "Fixed — `deny_record_failures` requires init tools exactly `["Bash"]` and every call a Bash call; test with `[Bash, BashOutput]`."

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:53`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the first init event's tool list and the every-call-is-Bash rule. It does not establish that a *second* init event is checked; it is not (Claim 31a).

The code is at `test/skills/transcript.jq:150-152` (quoted in Claim 1). `cfc-299727c-census-probes.txt` shows `init_tools_bash_twice` failing ("the init event's tools are ["Bash","Bash"], not exactly ["Bash"]") and `second_init_plus_read_call` failing with "1 call(s) of a tool other than Bash". The `[Bash, BashOutput]` test passes (`test/generate-reports.bats:737`).

**Evidence:** `test/skills/transcript.jq:149-152`, `docs/reviews/execution-logs/cfc-299727c-census-probes.txt`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 6: A29 "Fixed — Absolutes now match the code (the census makes 'any depth' true); log #56, the DD doc 'As built' … updated"

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:54`
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the Fixed marker's two checkable assertions: that the absolutes match the code, and that log #56 was updated. It does not dispute the other listed items (the `.failed` description, the malformed-transcripts header, one set of failure strings, the stale checker test, the `no_tool_called` control), which check out (Claims 16, 22, 33).

The absolutes do not match the code. "Wherever a call sits, it is found" and "any depth of any event" are refuted by a `__text`-keyed event (Claim 24). "Anything else is a problem" is refuted by the substring allowlists (Claim 25b). Log #56 was edited, but its voiding list, which A29 names as stale, is unchanged (Claim 1).

**Evidence:** `docs/decisions/log.md:77`, `test/skills/transcript.jq:7-13,26-36,56-57`, `docs/reviews/execution-logs/cfc-299727c-e2e-probes.txt`

---

## Claim 7: C36 "Fixed (report text, result state and `assert_subagents_min` read through the strict reader; the init tools check is part of the verdict)"

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:96`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the fix note's own items, which hold, against the row's three defects. It does not establish that an init-only transcript is rejected by the eval checks, or that the misspelling guard survives a non-array `tools` outside deny-record.

The fix-note items hold. The report and result state are extracted via `t::events` (`generate-reports.bash:252-261`). `assert_subagents_min` calls `transcript_checked` first (`eval-helpers.bash:488`). The init-tools check is in `deny_record_failures` (`transcript.jq:150`). Two parts of the row are fixed only under deny-record or only in the generator (`cfc-299727c-r3-c36-probes.txt`):

- `init-only: transcript_checked -> exit 0` and `init-only: assert_no_tool_called Bash -> exit 0`. The generator voids such a run ("no result event in the stream", `generate-reports.bash:262-265`), and eval_fixture then fails on `.failed`. The eval-level reader, though, still passes it.
- `string tools, misspelled 'bash': assert_no_tool_called -> exit 0`, against exit 1 with an array. The guard reads only arrays (`eval-helpers.bash:438`, `'t::init | .tools // [] | if type == "array" then .[] | strings else empty end'`), and `transcript_failures` has no init shape rule.

**Evidence:** `test/skills/eval-helpers.bash:423-447,479-496`, `test/skills/generate-reports.bash:248-266`, `test/skills/transcript.jq:124-126,150`, `docs/reviews/execution-logs/cfc-299727c-r3-c36-probes.txt`

---

## Claim 8: "Deny-record adds: the init event's tools exactly `["Bash"]`, every call a Bash call, every call denied (tripwire), every Bash denial and every `tool_result` answering a call in the census (parser canaries), and no denial of another tool. The `.failed` marker is fail-closed."

**Location:** `docs/working/dd-arith-eval-bash-grant.md:176`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the one-to-one match between this list and `deny_record_failures`'s six rules, and the marker. It does not establish the census these rules read (Claim 24) or which init event is checked (Claim 31a).

Each item maps to one branch of `transcript.jq:150-160` (quoted in Claims 1 and 31). For the marker, see Claim 13. The DD doc's `:175` and `:177` sentences restate the census and "fail-safe" absolutes, and are verdicted with them in Claims 24 and 25b.

**Evidence:** `docs/working/dd-arith-eval-bash-grant.md:175-177`, `test/skills/transcript.jq:139-162`

---

## Claim 9: "The checker exits 0 on a match, 1 when no command computed the value, and 2 on anything else, including any error it did not anticipate."

**Location:** `docs/working/dd-arith-eval-bash-grant.md:183`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the DD doc's summary of the exit contract. It does not re-verify the contract itself (Claim 21).

The docstring has a qualifier that this summary drops:

```python
# test/skills/arithmetic-eval/mode1-equiv.py:38-40
unexpected error in this script. So exit 1 means "the model's commands did not
compute the value", unless the evaluator misbehaves only on some inputs, which
the self-test cannot see.
```

(excerpt ends :40; the docstring ends at :41 — read). This is the sixth appearance of the exit-contract absolute (A10 → A11 → A19 → A21 → A27). The code's own docstring now carries the limit, and the DD summary should too.

**Evidence:** `docs/working/dd-arith-eval-bash-grant.md:183`, `test/skills/arithmetic-eval/mode1-equiv.py:34-41`

---

## Claim 10: "Fixtures. Inline mode, 5 drafts: 3 wrong figures, 1 correct figure and 1 with no arithmetic (`no_tool_called:Bash`)."

**Location:** `docs/working/dd-arith-eval-bash-grant.md:184`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mode, the count and the tc-ae5 check. It does not establish the correctness of the expected values.

`test/skills/arithmetic-eval/runner.bash:14` has `FIXTURE_MODE="inline"`. `expected-verdicts.bash:28-46` has five `KEY_CHECK` entries. tc-ae1 to tc-ae3 are named for wrong figures, tc-ae4 is `sessions-correct`, and tc-ae5 is `KEY_CHECK["tc-ae5-no-arithmetic.md"]="no_tool_called:Bash"` (`:46`).

**Evidence:** `test/skills/arithmetic-eval/runner.bash:13-16`, `test/skills/arithmetic-eval/expected-verdicts.bash:28-46`

---

## Claim 11: "Every kept transcript is read strictly through transcript.jq: a malformed event or a missing init event voids the run"

**Location:** `test/skills/generate-reports.bash:31-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fact that every `FIXTURE_TRANSCRIPT=1` run gets `transcript_failures` (or its deny-record superset), whose non-empty result voids the run. It does not establish that everything the header calls "malformed" is detected (Claims 24, 25b).

`generate-reports.bash:284-298` computes the verdict for every transcript run, not only for deny-record. `transcript_failures` is `problems` plus `"no init event …"` (`transcript.jq:124-126`). The suite has void tests for both, e.g. `test/generate-reports.bats:685-697` greps `.failed` for "no init event in the stream" and "a line is not a JSON object". It passes 46/46.

**Evidence:** `test/skills/generate-reports.bash:268-298`, `test/skills/transcript.jq:124-126`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 12: "The conditions that void such a run are listed once, in the 'Transcript checks' comment in generate_one."

**Location:** `test/skills/generate-reports.bash:37-39`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers where the voiding conditions are written down. It does not bear on the conditions' behavior.

The "Transcript checks" comment now calls itself a summary and defers to the module: "deny_record_failures instead, which adds (see the module for each rule):" (`generate-reports.bash:275-276`). The authoritative list is the module's comment and code (`transcript.jq:128-162`). The conditions are also listed in the DD doc (`:176`) and in log #56 (stale, Claim 1). The precise version is "defined once, in transcript.jq; summarized in the Transcript checks comment".

**Evidence:** `test/skills/generate-reports.bash:37-39,268-283`, `test/skills/transcript.jq:128-138`

---

## Claim 13: "Fail-closed: the marker exists from here until every check has passed, so a run interrupted or aborted at any step (set -e, a signal) is never graded"

**Location:** `test/skills/generate-reports.bash:156-159`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every path through `generate_one` from `:155` to its end. It does not establish that eval_fixture is the only grader of a report (a hand-run check that ignores `.failed` would not see it).

The marker is written at `:159` (`printf '%s\n' "generation did not finish" > "$failed_path"`). It is overwritten with the failure at `:301`, and removed only at `:306`, after the `if [ -n "$failure" ]` branch at `:300-304` has returned. Every failure source (rc `:245`, result state `:262-265`, verdict `:291-297`) appends to `$failure`. There is no other `return` or `rm` of `$failed_path` in the function (read `:141-313`). The fail-closed tests pass in the 46/46 run, including the property test, which also rejects a marker that says only "generation did not finish".

**Evidence:** `test/skills/generate-reports.bash:141-313`, `test/generate-reports.bats:702-724`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 14: "The report is what the model finally said: the last result event's text, read through transcript.jq like everything else … a malformed transcript is voided by the checks that follow."

**Location:** `test/skills/generate-reports.bash:248-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the report and `result_state` extraction going through `t::events`, and the later void. It does not establish that the extraction step itself validates anything (it does not; the verdict step does).

```bash
# test/skills/generate-reports.bash:252-255
    jq -rR -n -L "$SCRIPT_DIR" 'import "transcript" as t;
      t::events | [.[] | objects | select(.type == "result")] | last | .result // empty
      | if type == "string" then . else tojson end' "$transcript_path" \
      > "$report_path" 2>/dev/null || : > "$report_path"
```

(excerpt ends :255; the transcript block continues to :298 — read). `result_state` uses the same `t::events` (`:258-261`). Any `problems` entry then voids the run at `:291-297`.

**Evidence:** `test/skills/generate-reports.bash:248-298`

---

## Claim 15: "Transcript checks: transcript.jq decides the verdict, in one place … These run also when the run already failed … The verdict ends with a sentinel line: without it (jq failed, output cut short) the run is void"

**Location:** `test/skills/generate-reports.bash:268-283`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rule summary, running the checks when `$failure` is already set, and the sentinel requirement. It excludes the comment's census sentence ("so a call cannot sit anywhere it is not both checked and counted", `:271-273`), which is verdicted in Claim 24.

The verdict call at `:286-289` is not conditioned on `$failure`, and its lines are appended to any earlier failure (`:294-296`). The sentinel logic is quoted in Claim 3. The "jq wrapper that drops the sentinel" test passes.

**Evidence:** `test/skills/generate-reports.bash:268-298`, `test/generate-reports.bats:750-770`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 16: "generate-reports.bash records the failure itself in <fixture>.failed: claude's exit status, an error or missing result event, or a transcript check that voided the run. The marker is fail-closed: written before the run and removed only after every check returned a complete, empty verdict"

**Location:** `test/skills/eval-helpers.bash:74-81`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the list of failure sources and the marker's lifecycle as the generator implements them. "Complete, empty verdict" applies to transcript runs. A non-transcript run computes no verdict and loses the marker on rc 0 alone.

The three sources are exactly the generator's (`generate-reports.bash:245`, `:262-265`, `:291-297`). The lifecycle is as described in Claim 13. The iteration-5 gap (Claim 16 there: the list omitted transcript voids and the in-progress marker) is closed.

**Evidence:** `test/skills/eval-helpers.bash:74-86`, `test/skills/generate-reports.bash:155-159,245,262-306`

---

## Claim 17: "transcript_verdict … fail with its first failure unless it is complete (ends with the sentinel) and empty" / "jq skips an input file it cannot open and reads an empty stream, which would be reported as 'no init event'"

**Location:** `test/skills/eval-helpers.bash:389-412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the readability pre-check's rationale, the sentinel check and the first-failure message. It does not establish the verdict's content (Claims 24, 25b).

Command: `jq -rR -n -L test/skills 'import "transcript" as t; t::events | t::transcript_failures | t::print_verdict' <nonexistent>`, cwd /workspace, captured in `cfc-299727c-unreadable.txt`. Result: exit 2, `jq: error: Could not open file …` on stderr, then `no init event in the stream (the run did not start?)` and `__VERDICT_COMPLETE__` on stdout. Without the `-r` check (`:398-401`), that would be a complete verdict reporting the wrong failure, as the comment says. The sentinel and first-failure logic:

```bash
# test/skills/eval-helpers.bash:404-411
  if [ "$last" != "__VERDICT_COMPLETE__" ]; then
    echo "Could not read $t: its verdict is incomplete"
    return 1
  fi
  if [ "${#lines[@]}" -gt 1 ]; then
    echo "Transcript $t fails: ${lines[0]} ($(( ${#lines[@]} - 1 )) failure(s))"
    return 1
  fi
```

(excerpt ends :411; the function closes at :412 — read).

**Evidence:** `test/skills/eval-helpers.bash:389-412`, `docs/reviews/execution-logs/cfc-299727c-unreadable.txt`

---

## Claim 18: transcript_checked / tool_inputs_checked: "well formed by its rules (including the census …) and holding an init event" and "fail … when the init event lists the run's tools and <tool> is not one of them"

**Location:** `test/skills/eval-helpers.bash:414-447`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two functions as written, including that the guard applies only "when the init event lists" tools (an array). It does not establish the census's completeness (Claim 24), and it does not reject an init-only transcript (Claim 7).

`transcript_checked` is `transcript_verdict "$1" transcript_failures` (`:420`). The guard at `:438-442` fires for an array `tools` and not for a string one (`cfc-299727c-r3-c36-probes.txt`: exit 1 against exit 0), which matches "lists".

**Evidence:** `test/skills/eval-helpers.bash:414-447`, `docs/reviews/execution-logs/cfc-299727c-r3-c36-probes.txt`

---

## Claim 19: "Through the strict reader too (review iteration 5, C36): a malformed transcript fails rather than being counted around."

**Location:** `test/skills/eval-helpers.bash:486-488`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fact that `assert_subagents_min` runs `transcript_checked` before counting. It does not establish that the positional count equals a census count in every accepted stream. It does when `problems` is empty, because the placement check then guarantees census == placed.

```bash
# test/skills/eval-helpers.bash:488-490
  transcript_checked "$t" || return 1
  n=$(transcript_jq "$t" '[.[] | objects | select(.type == "assistant" and .parent_tool_use_id == null)
       | .message.content[] | objects | select(.type == "tool_use" and .name == "Agent")] | length') \
```

(excerpt ends :490; the function continues to :496 — read).

**Evidence:** `test/skills/eval-helpers.bash:479-496`, `test/skills/transcript.jq:103`

---

## Claim 20: "the caller … extracts the attempted commands through transcript.jq, the one strict reader, which also refuses malformed transcripts and undenied calls"

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:6-10`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the call path: `assert_mode1_equiv` runs `deny_record_failures` and then passes only `[t::tool_uses[] | .input.command]`. It does not establish that every undenied call is refused. A call in a `__text`-keyed event is not (Claim 24; `cfc-299727c-e2e-probes.txt`, `mode1_equiv` exit 0).

`eval-helpers.bash:537-539` runs `transcript_verdict "$t" deny_record_failures || return 1`, then `transcript_jq "$t" '[t::tool_uses[] | .input.command]' > "$cmds"`. The script has no transcript-reading code (`commands()` at `mode1-equiv.py:109-117` reads a JSON array of strings).

**Evidence:** `test/skills/eval-helpers.bash:518-547`, `test/skills/arithmetic-eval/mode1-equiv.py:109-117`, `docs/reviews/execution-logs/cfc-299727c-e2e-probes.txt`

---

## Claim 21: "Exit 0 on a match (or a valid spec), 1 on no match …, 2 on anything else …; a SKILL.md whose Mode 1 block does not extract, or whose evaluator fails a self-test (6 * 7 must give 42), which --check-spec runs too … So exit 1 means 'the model's commands did not compute the value', unless the evaluator misbehaves only on some inputs, which the self-test cannot see."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:34-40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit mapping in `main()` and `__main__` and the self-test in both modes. It does not establish the absence of other environment-dependent exit-1 routes, such as `evaluate()`'s 10 s `subprocess` timeout returning None on a slow host (`:137-140`), which is arguably a case of the stated limit.

The paths: `SetupError` returns 2 (`:164-166`); a match returns 0 (`:184-185`); otherwise 1 (`:186-187`); any other `Exception` exits 2 (`:194-198`); the self-test is at `:96-97` (Claim 4). mode1-equiv.bats passes 31/31, including the self-test and exit-2 tests.

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:79-198`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 22: "Each holds an init event listing Bash, one well-formed DENIED Bash call (id g1) …, one bad line, and a result event denying g1 only … Where the bad line itself carries a Bash call, that call is never denied (id x1, or a missing or non-string id in object_id and no_id)"

**Location:** `test/skills/malformed-transcripts.bash:7-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the file layout `write_malformed_transcripts` writes and the ids in each shape. It does not bear on the property test (Claim 23).

`:43-46` writes init (tools `["Bash"]`), the g1 call, `$bad`, and a result denying only g1. The bad-line calls use `x1` (`:25`, `:36`, `:38`) or an object id or no id (`:34`, `:39`). The iteration-5 error (Claim 25 there) is fixed.

**Evidence:** `test/skills/malformed-transcripts.bash:17-49`

---

## Claim 23: write_insertion_variants: "For every event line and every object or array in it (the event itself included), one variant with an undenied Bash tool_use inserted there: appended to an array, or added under a new key of an object … Prints the variant count."

**Location:** `test/skills/malformed-transcripts.bash:51-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the enumeration: one variant per object or array container, root included, with the call appended or added under the fixed key `x_inserted`. It does not vary the key name, the element index or any type string. It therefore cannot reach the `__text`-key escape (Claim 24), and "every position" means every container, not every key.

`paths(type == "object" or type == "array")` plus `[[]]` for the root (`:65`) enumerates containers. Hand count for the generator test's good transcript: init 2 (root, tools), assistant 6, user 4, result 4, total 16. For mode1-equiv's: 2 + 5 + 4 = 11. The mutation run prints `variants=16` and `variants=11` (`cfc-299727c-mutation.txt`), which matches.

**Evidence:** `test/skills/malformed-transcripts.bash:57-70`, `docs/reviews/execution-logs/cfc-299727c-mutation.txt`

---

## Claim 24: "Here the list of calls is a CENSUS: every object whose 'type' is 'tool_use', at any depth of any event … so a call cannot be counted without being checked or checked without being counted. Wherever a call sits, it is found"

**Location:** `test/skills/transcript.jq:7-13`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the census's universality ("any event", "wherever"). It finds no escape among the brief's type-string, JSON-in-string, duplicate-key, NUL, array-`type`, text-line, depth or scale probes, which are either counted, voided, or not calls in the CLI's format (listed below). It does not establish that the CLI can emit the escaping shape; none is known to.

The census skips any event object that has a top-level `__text` key, the marker the reader itself uses for ignored lines:

```jq
# test/skills/transcript.jq:56-57
def tool_uses: [.[] | objects | select(has("__text") | not) | .. | objects | select(.type == "tool_use")];
def tool_results: [.[] | objects | select(has("__text") | not) | .. | objects | select(.type == "tool_result")];
```

`_event_problems` also returns `empty` for it (`:70`, `elif has("__text") then empty`), and `_placed_tool_uses` counts only assistant events (`:62-63`). So an unplaced call in such an event is neither checked nor counted. Probe `event_with___text_key_call_and_result`, the line `{"__text":"x","a":<undenied Bash call x1>,"r":<tool_result for x1>}`, gives a verdict of only `__VERDICT_COMPLETE__` (`cfc-299727c-census-probes.txt`). End to end (`cfc-299727c-e2e-probes.sh`, 2026-09-26T08:46:18Z, exit 0), the generator leaves `no .failed marker: the run PASSED the generator's checks`, and `assert_no_tool_called Bash pwd -> exit 0` and `assert_mode1_equiv arithmetic-eval 2 -> exit 0`. The placed variant (`"type":"assistant"` plus `__text`) *is* caught by the placement count mismatch. Real `claude -p` lines never carry `__text`, so only a CLI shape change or a hand-written transcript reaches this.

Brief probes that are **not** escapes (`cfc-299727c-census-probes.txt`):
- `"tool_use "`, `TOOL_USE` and Cyrillic-lookalike blocks in assistant content are voided ("unknown content block type"). `tool_use` decodes to `tool_use` and is counted.
- A lookalike nested in a system event or in a tool input is not counted and not voided. It is not a call in the CLI's format, so the CLI cannot have run it (harmless).
- JSON-in-string (a call serialized inside a text block) is not counted (harmless: not a structured call).
- Duplicate keys: jq takes the last value (`"type":"tool_use",…,"type":"text"` reads as text, and the reverse is counted). Node's `JSON.parse` resolves the same way, and the CLI writes with `JSON.stringify`, so no duplicates arise (harmless).
- `type` as an array is voided ("no string type"). A `__text`-style text line (no braces) cannot hold an object. NUL bytes inside or before an event line are voided ("does not parse").
- Two objects on one line, ANSI prefixes, and CR-only separators are voided.
- Nesting of 256 or more levels is voided (jq 1.6's parse limit). 200 levels are counted and mismatch-voided.
- 20,000 denied calls plus one undenied call (3.4 MB): tripwired in about 5 s.

The same absolute appears at `generate-reports.bash:271-273`, `eval-helpers.bash:383`, `docs/working/dd-arith-eval-bash-grant.md:175`, `docs/decisions/log.md:77` ("every `tool_use` object at any depth") and rubric A29 (Claim 6). Verdicted once here.

**Evidence:** `test/skills/transcript.jq:7-13,45-46,56-70,96-105`, `docs/reviews/execution-logs/cfc-299727c-census-probes.txt`, `docs/reviews/execution-logs/cfc-299727c-e2e-probes.txt`

---

## Claim 25a: "every line that contains '{' or '[' is one JSON object; a line with neither (a warning a CLI printed to stdout) is ignored"

**Location:** `test/skills/transcript.jq:23-25`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the line rule. The deviation is in the strict direction, so it does not hide calls.

A line with neither bracket is ignored only if it fails to parse. `events` tries `fromjson` first (`:45-46`), so a bracket-free line that is valid JSON becomes an event. Probes `bare_number_line` (`42`), `quoted_string_line` and `true_line` each give "a line is not a JSON object". `bare_word_line` is ignored. A precise version: "a line with neither that is not itself JSON is ignored". The DD doc's "a plain-text line is ignored" (`:175`) is fine under that reading.

**Evidence:** `test/skills/transcript.jq:45-46,68`, `docs/reviews/execution-logs/cfc-299727c-census-probes.txt`

---

## Claim 25b: "event types: system (any subtype), assistant, user, result, rate_limit_event; … assistant blocks are text, thinking, redacted_thinking or tool_use; user blocks are tool_result or text … Anything else is a problem, so a CLI change voids runs loudly rather than passing them."

**Location:** `test/skills/transcript.jq:26-30,36-37`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the event-type and block-type allowlists. It does not claim that a `type == "tool_use"` call escapes through this gap. It does not: the census still finds such a call, and the placement count voids it (`substring_event_type_with_real_call`).

The allowlists use `inside/1`, which for strings tests substring containment, not equality:

```jq
# test/skills/transcript.jq:72
  elif ([.type] | inside(["system", "assistant", "user", "result", "rate_limit_event"]) | not) then
```

(excerpt ends :72; `_event_problems` continues to :94 — read; `:81-82` use the same idiom for block types). `jq -n '["a"] | inside(["abc"])'` gives `true`. The probes `substring_event_type_sys` (`"type":"sys"`), `substring_event_type_empty` (`""`), `substring_block_type_tool` (`{"type":"tool","name":"Bash","input":{"command":"pwd"},…}` in assistant content), `substring_block_type_empty`, and `substring_user_block_type_result` all return only the sentinel. End to end, the `"tool"` block passes the generator and both eval checks (`cfc-299727c-e2e-probes.txt`). A CLI change that introduced a type which is a substring of an allowed one would therefore pass, not "void loudly". The same statement is at `docs/working/dd-arith-eval-bash-grant.md:175` ("Event and content-block types are allowlisted") and `:177` ("a CLI format change voids runs until the module is updated (fail-safe)"), and in b22a026's message. That `:177` residual is a settled item; this verdict covers only its factual premise.

**Evidence:** `test/skills/transcript.jq:67-94`, `docs/reviews/execution-logs/cfc-299727c-census-probes.txt`, `docs/reviews/execution-logs/cfc-299727c-e2e-probes.txt`

---

## Claim 25c: "every tool_use: string `id` (unique in the transcript) and `name`; a Bash tool_use has an object `input` with a string `command`; every tool_result: a string `tool_use_id`; a result event's `permission_denials`, when present and not null: an array of objects with string `tool_name` and `tool_use_id`."

**Location:** `test/skills/transcript.jq:31-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the field rules on census members and on top-level result events. It does not cover members the census skips (Claim 24).

The rules are at `:98-102`, `:105` and `:86-93`. The table shapes `object_id`, `no_id`, `numeric_command`, `tool_result_no_id`, `denials_number` and `list_tool_use_id`, plus the probe `reused_denied_id` ("two tool_uses share an id"), all fail. The table tests pass in the suite run.

**Evidence:** `test/skills/transcript.jq:86-105`, `docs/reviews/execution-logs/cfc-299727c-r3-c36-probes.txt`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 26: "A line that fails to parse becomes {"__unparsed": ...} when it contains '{' or '[' (it could have carried an event: a prefix such as an ANSI escape or a BOM, a lone surrogate, deep nesting)"

**Location:** `test/skills/transcript.jq:40-44`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the mechanism, which holds, and the examples. The one wrong example errs toward reading more, not less.

jq 1.6 parses a BOM-prefixed line. It is not `__unparsed`: its call is counted and tripwired (`cfc-299727c-r3-c36-probes.txt`, `bom_prefixed`: "Bash tripwire: 1 call(s) not in permission_denials"). ANSI prefixes, lone surrogates (table shape) and nesting of 256 or more levels (`call_nested_256_…`) do fail to parse, as stated. b22a026's message repeats "ANSI/BOM prefixes".

**Evidence:** `test/skills/transcript.jq:45-46`, `docs/reviews/execution-logs/cfc-299727c-r3-c36-probes.txt`, `docs/reviews/execution-logs/cfc-299727c-census-probes.txt`

---

## Claim 27: "Control characters (newlines included) become spaces, so every verdict line is exactly one line."

**Location:** `test/skills/transcript.jq:49-52`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers line splitting as the consumers do it (`mapfile -t`, LF only). U+0085, U+2028 and U+2029 are not mapped. That is harmless for these consumers, but they would split lines in a Unicode-aware reader.

`def _one_line: explode | map(if . < 32 or . == 127 then 32 else . end) | implode;` (`:52`) is applied to every string at `print_verdict` (`:165`), to every `problems` entry (`:108`), and to the embedded CLI version and types. The R4 newline test passes.

**Evidence:** `test/skills/transcript.jq:52,108,143,165`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 28: "Accepted shapes, from 13 real runs on CLI 2.1.282/283 (2026-09-25), where the census found exactly the positional calls (21 tool_use, 21 tool_result)"

**Location:** `test/skills/transcript.jq:21-22`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether the repo holds the 13 runs. It does not. As partial corroboration of the accepted-shape list only, the 16 committed real transcripts (CLI 2.1.232, not 2.1.282/283) all pass.

No deny-record transcripts or reports are committed (`git ls-files` has no `test/skills/arithmetic-eval/output`). This was checked by listing `git ls-files` for `transcript.jsonl`, and the only hits are 16 files under `runs/review-arms/e7-fable-3x/`. Run through the module, all 16 have 0 problems and census tool_uses = census tool_results = placed tool_uses (68 to 241 calls each, one with 0) (`cfc-299727c-committed-transcripts.txt`). Verifying the claim needs the 13 transcripts. The same figure is in b22a026's message and the DD doc (`:175`).

**Evidence:** `test/skills/transcript.jq:21-22`, `docs/reviews/execution-logs/cfc-299727c-committed-transcripts.txt`

---

## Claim 29: "The verdict … ends with a sentinel so a caller can tell a complete verdict from a truncated one" / "Callers print it with print_verdict and must see the sentinel as the last line, or treat the verdict as failed."

**Location:** `test/skills/transcript.jq:14-16,120-123`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both callers of `print_verdict` enforcing the sentinel. It does not establish that no other caller exists outside `test/skills/` (a grep of the repo finds none).

`rg -n 'print_verdict' test` finds only `generate-reports.bash:288` and `eval-helpers.bash:401`, and both check the last line (Claims 3, 17). No failure string can equal the sentinel, because each has a fixed prefix (`transcript.jq:68-105,126,150-160`). The verdict array is computed before `print_verdict` emits anything (`:165`), so a jq error cannot print a partial list followed by the sentinel.

**Evidence:** `test/skills/transcript.jq:120-126,164-165`, `test/skills/generate-reports.bash:286-298`, `test/skills/eval-helpers.bash:401-411`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 30: "The first init event, or null."

**Location:** `test/skills/transcript.jq:110-111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `init`'s definition. For its consequence under deny-record, see Claim 31a.

`def init: [.[] | objects | select(.type == "system" and .subtype == "init")] | first;` (`:111`). `first` of an empty array is null in jq 1.6.

**Evidence:** `test/skills/transcript.jq:111`

---

## Claim 31a: "the init event must list exactly ["Bash"], the only tool granted"

**Location:** `test/skills/transcript.jq:132`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers which init event is checked. It does not create a call escape: every call must still be Bash and denied (Claim 31b).

Only the first init event is checked (`init`, Claim 30). Probe `second_init_event_lists_more_tools` (a second init with `["Bash","Read"]`) passes deny-record. With a Read call added, it fails on "a tool other than Bash". A precise version is "the first init event". The DD doc (`:176`) and rubric A28 carry the same wording.

**Evidence:** `test/skills/transcript.jq:111,149-150`, `docs/reviews/execution-logs/cfc-299727c-census-probes.txt`

---

## Claim 31b: deny_record_failures runs "whenever the stream is well formed … even with no init event"; "every tool_use must be Bash; tripwire …; parser canaries …; only Bash may be denied"

**Location:** `test/skills/transcript.jq:128-138`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the conditions and the six rules over the census. It inherits the census gap (Claim 24).

`:141` gates on `(problems | length) > 0` only. Probe `no_init_undenied_call` gives both "no init event in the stream" and "Bash tripwire: 1 call(s) not in permission_denials". The rules are at `:150-160`. The table shapes and the A28 test exercise each rule, and they pass.

**Evidence:** `test/skills/transcript.jq:139-162`, `docs/reviews/execution-logs/cfc-299727c-census-probes.txt`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 32: "Tests (bats TAP plan lines and grep counts, pasted): generate-reports.bats 1..46 ok=46; mode1-equiv.bats 1..31 ok=31; eval-helpers-transcript.bats 1..7 ok=7; eval-helpers-empty-report.bats 1..6 ok=6; arithmetic-eval-gate.bats 1..18 ok=18; arithmetic-eval-eval.bats 1..9 ok=9 (skip=9); arithmetic-eval-after-denial-patterns.bats 1..5 ok=5; arithmetic-eval-format.bats 1..25 ok=25; divergent-design-eval.bats 1..5 ok=5 (skip=5); scripts/health-check.sh: 'All checks passed.' exit=0"

**Location:** commit b22a026 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every count at HEAD 299727c (b22a026 plus a docs-only commit). It does not establish the counts at b22a026 itself, though no test file changed after it.

`bats --tap <file>` for each file, cwd /workspace, 2026-09-26T08:42:42Z to 08:43:19Z. All exit 0, and ok/skip counts equal the commit's: 46, 31, 7, 6, 18, 9 (9 skip), 5, 25, 5 (5 skip). `bats --count` gives the same plan lines. health-check: exit 0, "All checks passed.", 08:48:19Z.

**Evidence:** `docs/reviews/execution-logs/cfc-299727c-suites.txt`, `docs/reviews/execution-logs/cfc-299727c-health-check.txt`

---

## Claim 33: "Also tests for R4 (newline in the CLI version; a jq wrapper dropping the sentinel), A28, the evaluator self-test, and a control for the previously vacuous no_tool_called leg."

**Location:** commit b22a026 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence and passing of each named test. It does not assess their sensitivity beyond the property-test mutation (Claim 34).

The tests are at `test/generate-reports.bats:726`, `:737` and `:750`, and `test/skills/mode1-equiv.bats:395`. The `no_tool_called` control is in b22a026's diff of `mode1-equiv.bats`: `run assert_no_tool_called Bash '"command":"pwd"'`, then `[ "$status" -eq 0 ] || { echo "no_tool_called control failed: …"`. It replaces the old `Bash=rm` single-argument form. All pass.

**Evidence:** `test/generate-reports.bats:726-770`, `test/skills/mode1-equiv.bats:395-406`, `docs/reviews/execution-logs/cfc-299727c-suites.txt`

---

## Claim 34: "Mutation back to the positional reading gives 12/16 and 24 escapes."

**Location:** commit b22a026 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers one natural reading of "positional": `tool_uses`/`tool_results` limited to assistant/user `message.content[]`, which makes the placement check vacuous. Another mutation could give other numbers.

In a `git archive HEAD test skills` copy under the scratchpad, lines 56-57 were replaced as shown in the log's diff. `bats --tap -f property` then gives `variants=16 escapes=12` (generator, not ok) and `variants=11 escapes=24` (mode1-equiv: 3 checks × 11 variants, not ok). Run at 2026-09-26T08:46:29Z. The working tree was untouched.

**Evidence:** `docs/reviews/execution-logs/cfc-299727c-mutation.txt`

---

## Claim 35: "The real Haiku run still grades routing 5/5 with no false voids."

**Location:** commit b22a026 message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether the repo holds that run. It does not.

paraphrased — no quote available because the claim covers absence of files: no `test/skills/arithmetic-eval/output/` reports, transcripts or `.failed` markers are tracked (`git ls-files`), and running `claude` is out of scope for this pass. Verifying it needs that run's output directory. The companion "13 real runs … 21 tool_use, 21 tool_result" is Claim 28.

**Evidence:** `test/skills/arithmetic-eval/runner.bash:13-16`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6** (rubric A29, `:54`): "Absolutes now match the code … log #56 updated". The census and allowlist absolutes are refuted (Claims 24, 25b), and log #56's voiding list is unchanged (Claim 1).
- **Claim 24** (`transcript.jq:7-13`, and 5 restatements): "wherever a call sits, it is found". An event with a top-level `__text` key is skipped. An undenied Bash call plus its tool_result there passes the generator, `no_tool_called` and `mode1_equiv` end to end. Fix candidates: reserve the marker (wrap parsed lines, or flag any parsed object that has `__text`/`__unparsed`), or census over all non-marker lines only by provenance.
- **Claim 25b** (`transcript.jq:26-37,72,81-82`): the type "allowlists" use `inside/1`, a substring test. `""`, `"sys"`, `"tool"` and `"result"` are accepted, so "anything else is a problem" and "a CLI change voids runs loudly" do not hold. `IN(...)` or `index`-based equality would match the comment. No `tool_use`-typed call escapes through this.

### Stale
- **Claim 1** (`docs/decisions/log.md:77`): the voiding list is still the pre-iteration-4 one ("does not list Bash"). It omits the non-Bash-call, tool_result canary, other-tool denial and malformed-stream conditions.

### Mostly Accurate
- **Claim 7** (rubric C36): an init-only transcript still passes `transcript_checked`/`no_tool_called` (the generator voids it), and a string `tools` still turns off the misspelling guard outside deny-record.
- **Claim 9** (DD `:183`): the exit contract is summarized without the docstring's "misbehaves only on some inputs" limit.
- **Claim 12** (`generate-reports.bash:37-39`): the conditions are defined in transcript.jq and only summarized in the comment. They also appear in the DD doc and log #56.
- **Claim 25a** (`transcript.jq:23-25`): a bracket-free line that is valid JSON (`42`, `true`, `"x"`) is a problem, not ignored.
- **Claim 26** (`transcript.jq:40-44`, and the commit): jq 1.6 parses a BOM-prefixed line, so BOM is not an `__unparsed` example (the call is counted).
- **Claim 31a** (`transcript.jq:132`, DD `:176`, A28): only the first init event's tools are checked.

### Unverifiable
- **Claim 28** (`transcript.jq:21-22`, commit, DD): "13 real runs on CLI 2.1.282/283 … 21 tool_use, 21 tool_result". The transcripts are not in the repo. The 16 committed 2.1.232 transcripts all pass with census = placed.
- **Claim 35** (commit): "Haiku … routing 5/5 with no false voids". The run output is not committed, and `claude` was not run.

---

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to docs/reviews/code-fact-check-report.md, structured per the code-fact-check skill, with header lines `**Commit:** 299727c` and `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes. The report is saved at that path with both header lines, and it covers all seven brief items:
  - transcript.jq and the census probes: Claims 24-31b.
  - The generator: Claims 11-15.
  - eval-helpers: Claims 16-19.
  - mode1-equiv: Claims 20-21.
  - malformed-transcripts: Claims 22-23.
  - DD, log #56 and the rubric rows: Claims 1-10.
  - The commit message: Claims 26, 28 and 32-35.
- Out of scope: the Q-062 install gate (unchanged since iteration 4) and the settled or open-by-choice rubric rows. The DD `:177` residual's acceptance was not re-litigated; Claim 25b checks only its factual premise. No `claude` or network command was run.
- Escalate: Claim 24 is the R3 class once more: a place the census does not look, here the reader's own `__text` marker key. The insertion property cannot reach it, because it varies containers, not key names. Claim 25b is an unrelated jq-semantics bug (`inside` is a substring test) that makes the "fail-safe on new CLI shapes" residual weaker than stated. Neither is known to be reachable from real CLI output (all 16 committed real transcripts pass cleanly). Whether to fix them at the loop's terminal pass is the orchestrator's and the user's call. Each fix is a line or two in `transcript.jq`.
- Decisions I made: I verdicted duplicated statements of one contract once, at the defining location, and listed the other locations (Claims 24, 25b, 28), so counts are not inflated. I rated Claim 24 Incorrect rather than Mostly accurate because a probe breaks the invariant end to end; its low reachability is in the Scope field. I rated the probes where a lookalike type is not counted as harmless, not escapes, because the CLI does not execute objects outside its own `tool_use` format.
