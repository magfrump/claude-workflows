# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** branch diff `git diff main...HEAD` (skill-fixtures), focused on fix commit 272bc83 ("one strict transcript reader", review-fix loop iteration 4 → 5) and the rubric rows it marked Fixed
**Commit:** 9c73ae4
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-09-26
**Total claims checked:** 37
**Summary:** 21 verified, 9 mostly accurate, 2 stale, 4 incorrect, 1 unverifiable

I read the hallucination-pattern log first (`docs/reviews/hallucination-patterns.md`, 5 entries). Claim 27a is close to the logged class "a specific measured value quoted from a checked-in artifact set that does not contain it". Here, though, the artifact set (13 real transcripts) is not in the repo at all, so the claim is Unverifiable, not refuted. No other claim matches a logged pattern, and no Incorrect verdict is a fabricated symbol, so no log entry was added.

Execution logs are in `docs/reviews/execution-logs/cfc-9c73ae4-*`. Every command ran with cwd `/workspace` unless its log says otherwise. jq is 1.6. The three probe scripts (`cfc-9c73ae4-{reader,gen,helper}-probes.sh`) pass `shellcheck -x -e SC1091 -s bash -S warning`. `scripts/health-check.sh` passes with them in place: exit 0, "All checks passed.", 2026-09-26T05:29:45Z, `cfc-9c73ae4-health-check.txt`.

**Headline.** 272bc83 closes the two shapes named in R2 (an array-wrapped event, a string `content`) and all 13 table shapes, in both the generator and the eval checks. The 13 shapes all pass. However, the general contract it states in six places ("an unexpected shape is a problem, never skipped") does not hold. An undenied Bash `tool_use` inside a **`user`** event is validated and then never counted. Other ways to hide a call are an event whose `type` is unknown, missing or not a string, and a tool_use nested in a `tool_result`. Each passes the generator (deny-record included) and `no_tool_called` with no marker (Claims 26, 29). Separately, a newline in the init event's `claude_code_version` silently drops the deny-record counts field, and the `.failed` marker is then removed although no check ran (Claim 22b). mode1-equiv's "exit 1 always means a model result" is still an absolute that a broken SKILL.md evaluator refutes (Claim 14): this is the exit-contract claim again (A10 → A11 → A19 → A21).

---

## Claim 1: "it voids a run when a Bash call is missing from `permission_denials` (tripwire), when a denial names a call the parser did not see (parser canary), or when the init event is missing or does not list Bash"

**Location:** `docs/decisions/log.md:77`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether log #56's list of voiding conditions matches `generate_one` at HEAD. It does not establish the rest of the row, whose "shared by the generator and the eval checks" and "rejects unexpected event shapes" sentences are verdicted in Claims 11 and 26.

This sentence dates from before 272bc83, which edited only the row's closing sentences. The list omits three conditions the generator now applies: a malformed event, which voids any transcript run, and, under deny-record, the `tool_result` canary and foreign denials:

```bash
# test/skills/generate-reports.bash:298-299
      if [ "$n_problems" != 0 ]; then
        failure="${failure:+$failure; }transcript: $n_problems malformed event(s), first: $problems (CLI $cli_version)"
```

```bash
# test/skills/generate-reports.bash:314-317
          [ "$orphans" = 0 ] \
            || failure="${failure:+$failure; }Bash parser canary: $orphans tool_result(s) answer a tool_use the reader did not see (CLI $cli_version; a call may have run unseen)"
          [ "$foreign" = 0 ] \
            || failure="${failure:+$failure; }Bash tripwire: $foreign denial(s) of a tool other than Bash, the only tool granted"
```

The row does say "The code is the reference". The commit claims the conditions are "listed once, in generate_one (A24)", but this row is a second, now partial, list.

**Evidence:** `docs/decisions/log.md:77`, `test/skills/generate-reports.bash:264-320`

---

## Claim 2: R2 "Fixed (structural: one strict reader … rejects unexpected shapes; table test of 13 shapes including Claim 26b's, each beside a good denied call, for the generator and for mode1_equiv/no_tool_called; mutation-checked)"

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:16`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the defect R2 names: the array-wrapped and string-`content` shapes, plus the other 11 table shapes, are rejected by the generator and by `mode1_equiv`/`no_tool_called`, each beside a good denied call, and the tests are mutation-sensitive. It does not establish the parenthetical's general "rejects unexpected shapes". Shapes outside the table still hide an undenied call (a `user`-event tool_use, an unknown or missing event `type`; Claim 26).

The table is `MALFORMED_SHAPES` (`test/skills/malformed-transcripts.bash:15-17`, 13 names, including `array_wrapped` and `string_content`). The two table tests pass: `test/generate-reports.bats:627` (generator) and `test/skills/mode1-equiv.bats:300` (`assert_mode1_equiv` and `assert_no_tool_called Bash=rm`). The runs are `bats --tap`, cwd `/workspace`, 2026-09-26T05:25:07Z, both exit 0: 42/42 and 29/29 (`cfc-9c73ae4-suites.txt`). Each test also runs a control, the same file without the bad line, which must pass. Stubbing `problems` to `[]` fails both table tests (Claim 32).

**Evidence:** `test/skills/malformed-transcripts.bash:15-46`, `test/generate-reports.bats:627-643`, `test/skills/mode1-equiv.bats:300-318`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`, `docs/reviews/execution-logs/cfc-9c73ae4-mutation.txt`

---

## Claim 3: A21 "Fixed — … mode1-equiv no longer reads transcripts … its duplicate tripwire is gone; a `__main__` catch-all maps any unanticipated error to exit 2; docstring narrowed; tests for JSON-array input and a RecursionError → exit 2"

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:44`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers A21's stated defect: TypeError and RecursionError tracebacks exit 1 from the duplicate tripwire and transcript parsing. It also covers the removal of both, the catch-all and the two tests. It does not establish that exit 1 now always means a model result: the narrowed docstring still claims that, and it is refuted by a different path (Claim 14).

`mode1-equiv.py` has no transcript or `permission_denials` code left. Its only mentions of "transcript" are docstring lines 7-9, and `commands()` reads a JSON array of strings (`mode1-equiv.py:99-107`). The catch-all:

```python
# test/skills/arithmetic-eval/mode1-equiv.py:184-188
    try:
        sys.exit(main())
    except Exception as e:  # noqa: BLE001 - deliberate catch-all, see above
        print(f"mode1-equiv: checker error: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(2)
```

`mode1-equiv.bats:327` (JSON-array contract, 200 000-deep nesting → exit 2, no traceback) passes (`cfc-9c73ae4-suites.txt`).

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:1-188`, `test/skills/mode1-equiv.bats:327-345`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 4: A22 "Fixed — A parser canary on `tool_result` ids (a call that ran unseen) plus voiding any non-Bash denial; tests."

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:45`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the orphan-`tool_result` canary and foreign-denial voiding in the generator, and their test. It does not establish coverage of a `tool_result` outside a `user` event: `tool_result_ids` reads only `user` events (`transcript.jq:78`), and `problems` validates a `tool_result` in an assistant event but nothing counts it.

```jq
# test/skills/transcript.jq:98-101 (excerpt starts inside deny_record_counts, which begins :90 — read)
  | { undenied: ([$bash[] | select($denied_set[.] | not)] | length),
      unseen:   ([$denied[] | select($bash_set[.] | not)] | length),
      orphans:  ([tool_result_ids[] | select($all_set[.] | not)] | length),
      foreign:  ([$d[] | select(.tool_name != "Bash")] | length) };
```

The generator voids on non-zero `orphans` and `foreign` (`generate-reports.bash:314-317`, quoted in Claim 1). `generate-reports.bats:645` passes. It checks the "1 tool_result(s) answer a tool_use the reader did not see" marker and the "1 denial(s) of a tool other than Bash" marker.

**Evidence:** `test/skills/transcript.jq:77-79`, `test/skills/transcript.jq:90-101`, `test/skills/generate-reports.bash:314-317`, `test/generate-reports.bats:645-661`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 5: A23 "Fixed — `.failed` is written before the run and removed only after every check passes; test observes it during the run."

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers A23's defect: a generator interrupted between writing the report and the checks now leaves a marker. It does not establish "removed only after every check passes" for every input. A counts field lost to a newline skips the deny-record checks, and the marker is removed anyway (Claim 22b).

The marker is written before the run (`generate-reports.bash:159`, quoted in Claim 22a). `generate-reports.bats:663` has the stub copy the marker while it runs, and passes. Probe P8 aborts the generator under `set -e` (unreadable fixture). It exits 1 and leaves "generation did not finish" (`cfc-9c73ae4-gen-probes.txt`).

**Evidence:** `test/skills/generate-reports.bash:155-159`, `test/skills/generate-reports.bash:323-329`, `test/generate-reports.bats:663-682`, `docs/reviews/execution-logs/cfc-9c73ae4-gen-probes.txt`

---

## Claim 6: A24 "Fixed — The generator header points at the single 'Transcript checks' comment; a jq failure reads 'transcript: could not be read'; `Bash init canary:` naming."

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:47`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three named edits in `generate-reports.bash`. It does not establish that no other document keeps a second list: log #56 still does (Claim 1).

```bash
# test/skills/generate-reports.bash:37-39
#                     Needs FIXTURE_TRANSCRIPT=1; refuses CLAUDE_FLAGS. The
#                     conditions that void such a run are listed once, in the
#                     "Transcript checks" comment in generate_one.
```

`:293` reads `transcript: could not be read, so no check could run` and `:306` reads `Bash init canary: the init event does not list Bash`. A grep for `"Bash canary:"` in `test/` finds nothing (paraphrased — no quote available because the claim is about the absence of a string).

**Evidence:** `test/skills/generate-reports.bash:31-39`, `test/skills/generate-reports.bash:293`, `test/skills/generate-reports.bash:306`

---

## Claim 7: A25 "Fixed — Bare `tool_called:` failure says 'No <Tool> call.'; an empty tool name fails; tests."

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two message and guard fixes and their test. It does not establish the "passes when the init event has no `tools`" half of A25 for a *non-empty* misspelled name: with no `tools` list, a misspelling is still unchecked, by design (`eval-helpers.bash:429`).

```bash
# test/skills/eval-helpers.bash:419-422 (excerpt ends :422; enclosing tool_inputs_checked() continues to :434 — read)
  if [ -z "$tool" ]; then
    echo "Empty tool name in the check"
    return 1
  fi
```

`:462` prints `"No $tool call."` when there is no pattern. `mode1-equiv.bats:347` passes.

**Evidence:** `test/skills/eval-helpers.bash:417-434`, `test/skills/eval-helpers.bash:453-467`, `test/skills/mode1-equiv.bats:347-358`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 8: A26 "Fixed — 'No leading '; init 'contains', not 'starts with'; DD doc no longer says mode1-equiv repeats the tripwire; test name corrected. 37c5ea9's wrong count … is corrected"

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:49`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the five listed edits, all present. It does not cover the row's "'truncated transcript' covers only pre-init truncation" item, which the Fixed note omits and which is unchanged.

The listed edits are all present: `mode1-equiv.py:30-31` "or leading "+" (an exponent may carry one: 1e+5)"; `eval-helpers.bash:388` "holds an init event"; DD `:176-177` no longer mentions a repeated tripwire; `mode1-equiv.bats:241` test is now named "…mode1_equiv reaches the checker"; the count correction is in 272bc83's message. The truncation wording remains:

```bash
# test/skills/eval-helpers.bash:389-391
# junk, truncated or unexpectedly shaped transcript would otherwise read as
# "no calls" and let a negative check pass, or hide a call inside a shape a
# looser reader skips.
```

A tail-truncated transcript, holding only its init line, still passes `assert_no_tool_called Bash` with exit 0 (E1, `cfc-9c73ae4-helper-probes.txt`, 2026-09-26T05:29:40Z). A cut inside a line is now caught: it starts with `{` and does not parse. Precise version: "a transcript cut off before its init event, or mid-line".

**Evidence:** `test/skills/eval-helpers.bash:387-411`, `docs/reviews/execution-logs/cfc-9c73ae4-helper-probes.txt`, `docs/reviews/code-fact-check-report-q062-q063-iter4-5bdee46.md:448-458`

---

## Claim 9: C31 "Fixed (shared reader)" and C32 "Fixed (a JSON-like line that does not parse is a problem)"

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:86-87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers C31's non-object block (table shape `nonobject_block`) and C32's lone-surrogate and deep-nesting lines (`surrogate`, `deep`), for both the generator and `no_tool_called`. It does not establish rejection of other hiding places (Claim 26).

```jq
# test/skills/transcript.jq:29-30
def events: [inputs | select(test("\\S")) | . as $line | (try fromjson catch
  (if ($line | test("^\\s*[\\[{]")) then {"__unparsed": $line} else {"__text": $line} end))];
```

`:43` makes a non-object block a problem. The table tests pass, and fail under the mutation (Claims 2, 32).

**Evidence:** `test/skills/transcript.jq:29-43`, `test/skills/malformed-transcripts.bash:29`, `test/skills/malformed-transcripts.bash:34-35`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 10: C33 "Fixed (ids must be strings; set lookups)"

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:88`
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the id half: ids are checked to be strings, and lookups use object sets. It does not cover C33's second item, "`tool_inputs_checked` makes three passes where one would do", which is unchanged and not mentioned in the Fixed note.

The id half is right (`transcript.jq:45`, `:56`, `:81-82`). The three jq passes remain:

```bash
# test/skills/eval-helpers.bash:423-428 (excerpt starts inside tool_inputs_checked(), which begins :417; continues to :434 — read)
  transcript_checked "$t" || return 1
  if ! inputs="$(transcript_tool_inputs "$t" "$tool")"; then
    echo "Could not read tool calls from $t"
    return 1
  fi
  known="$(transcript_jq "$t" 't::init | .tools // [] | if type == "array" then .[] | strings else empty end' 2>/dev/null || true)"
```

Each call runs `jq` over the whole transcript. `transcript_checked` itself evaluates `t::problems` twice in one pass (`:396`). Precise note: "Fixed (id half); the three-pass item stays open (informational)".

**Evidence:** `test/skills/eval-helpers.bash:392-434`, `test/skills/transcript.jq:81-101`

---

## Claim 11: "The generator and the eval checks both read transcripts through it, so 'a Bash call', 'denied' and 'seen' are defined once."

**Location:** `docs/working/dd-arith-eval-bash-grant.md:175` (same claim: `docs/decisions/log.md:77` "every transcript is read through one strict reader … shared by the generator and the eval checks"; `test/skills/transcript.jq:1-7`)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every check that decides voiding or a Bash/tool verdict: the generator's checks, `tool_called`/`no_tool_called` and `mode1_equiv`, all of which go through `transcript.jq`. It does not cover `assert_subagents_min` or the generator's report and `is_error` extraction, which keep their own lenient `fromjson?` parsers.

```bash
# test/skills/eval-helpers.bash:476-478 (excerpt starts inside assert_subagents_min(), which begins :473; continues to :483 — read)
  n=$(jq -rR 'fromjson? | select(.type == "assistant" and .parent_tool_use_id == null)
       | .message.content[]? | select(.type == "tool_use" and .name == "Agent")
       | .name' "$t" | grep -c . || true)
```

`assert_subagents_min` never calls `transcript_checked`. Probe E3 is a transcript with no init event, a malformed `[1]` line and one Agent call. There, `assert_subagents_min 1` exits 0 and `transcript_checked` exits 1 (`cfc-9c73ae4-helper-probes.txt`). Through `eval_fixture`, a generator-voided run fails first on its `.failed` marker, so the gap bites only when the helper is used directly. The generator also reads the report and the result state leniently (`generate-reports.bash:252`, `:256`; Claim 21).

**Evidence:** `test/skills/eval-helpers.bash:469-483`, `test/skills/generate-reports.bash:252-257`, `docs/reviews/execution-logs/cfc-9c73ae4-helper-probes.txt`

---

## Claim 12: "This script does not read the transcript: the caller … extracts the attempted commands through transcript.jq, the one strict reader, which also refuses malformed transcripts and undenied calls"

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:6-10`
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the script's input (a command list only) and the caller's checks for malformed transcripts, a missing init and the four counts. It does not establish that every undenied Bash call is refused. A Bash tool_use in a `user` event is neither a problem nor counted (Claims 26, 29).

The script has no transcript code (Claim 3). The caller:

```bash
# test/skills/eval-helpers.bash:524-530 (excerpt starts inside assert_mode1_equiv(), which begins :516; continues to :540 — read)
  transcript_checked "$t" || return 1
  counts="$(transcript_jq "$t" 't::deny_record_counts | "\(.undenied) \(.unseen) \(.orphans) \(.foreign)"')" \
    || { echo "Could not read $t"; return 1; }
  if [ "$counts" != "0 0 0 0" ]; then
    echo "Bash tripwire/parser canary: undenied, unseen, orphan, foreign = $counts (every Bash call must be denied and seen)"
    return 1
  fi
```

With an undenied Bash call in a `user` event, `deny_record_counts` gives `{"undenied":0,…}` (reader probe `tool_use_in_user_event`, `cfc-9c73ae4-reader-probes.txt`, 2026-09-26T05:26:37Z). So "refuses … undenied calls" holds only for calls in assistant events.

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:1-38`, `test/skills/eval-helpers.bash:516-540`, `docs/reviews/execution-logs/cfc-9c73ae4-reader-probes.txt`

---

## Claim 13: "<commands.json> is a JSON array of strings: the Bash commands, in order."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the parser, its SetupError on any other shape, and the caller's producer. It does not establish that the list is complete (see Claim 29 on which tool_uses the reader emits).

```python
# test/skills/arithmetic-eval/mode1-equiv.py:99-107
def commands(path):
    """The commands from a JSON array of strings; anything else is a SetupError."""
    try:
        data = json.loads(read_text(path))
    except ValueError as e:
        raise SetupError(f"{path} is not JSON: {e}")
    if not isinstance(data, list) or not all(isinstance(c, str) for c in data):
        raise SetupError(f"{path} is not a JSON array of strings")
    return data
```

The producer is `eval-helpers.bash:532`, `'[t::tool_uses[] | select(.name == "Bash") | .input.command]'`, in stream order. The reader guarantees `.input.command` is a string whenever `problems` is empty (`transcript.jq:46`). `mode1-equiv.bats:327` feeds `{"a":1}`, `[1,2]` and `not json`, and each exits 2 without a traceback; it passes.

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:99-107`, `test/skills/eval-helpers.bash:531-533`, `test/skills/mode1-equiv.bats:327-345`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 14: "Exit 0 on a match (or a valid spec), 1 on no match …, 2 on anything else: a usage, spec, file or SKILL.md problem, or any unexpected error in this script …. Exit 1 therefore always means 'the model's commands did not compute the value', never a checker fault."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:34-37` (same claim: `docs/working/dd-arith-eval-bash-grant.md:182` "So exit 1 is always a model result.")
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the "always … never a checker fault" guarantee. The SetupError and catch-all paths do give exit 2 (Claims 3, 13). It does not establish which other environment faults reach exit 1 beyond the two traced here.

Exit 2 covers only the SKILL.md problems `reference()` detects: no Mode 1 block, a wrapper mismatch, a program that does not parse. The evaluator's *behavior* is never checked. `evaluate()` turns any evaluator failure, timeout or output-format change into `None`:

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

`None` then falls through to exit 1 (`:172-177`). Probe E5 copies SKILL.md with its print line changed from `-> {result}` to `=> {result}`, a SKILL.md problem. There, `--check-spec` exits 0, and a correct Mode 1 command for `6 * 7` with spec `42` exits **1** with "No Mode 1 command computed any of: 42". Against the real SKILL.md the same command exits 0 (`cfc-9c73ae4-helper-probes.txt`, 2026-09-26T05:29:40Z). A 10-second timeout of the reference evaluator on a loaded host also exits 1 (read from `:129-130`; not executed). Precise version: "Exit 1 means no command matched, including when SKILL.md's evaluator fails or prints an unexpected format for it".

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:76-88`, `test/skills/arithmetic-eval/mode1-equiv.py:124-177`, `docs/reviews/execution-logs/cfc-9c73ae4-helper-probes.txt`

---

## Claim 15: "Backstop for the exit contract: an error this script did not anticipate is a checker fault, exit 2, never a traceback with exit 1"

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:181-183`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers exceptions that are `Exception` subclasses and escape `main()` (RecursionError, MemoryError, OSError, TypeError, …). It does not cover failures that do not raise (Claim 14) or `BaseException`s such as KeyboardInterrupt.

The code is quoted in Claim 3 (`:184-188`). `mode1-equiv.bats:327` feeds 200 000-deep nesting and asserts exit 2 with "checker error" or "is not JSON" and no traceback. It passes (`cfc-9c73ae4-suites.txt`).

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:180-188`, `test/skills/mode1-equiv.bats:338-344`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 16: "generate-reports.bash records the failure itself in <fixture>.failed (claude's exit status, or an error/missing result event), which covers a failed run that still printed text."

**Location:** `test/skills/eval-helpers.bash:77-79`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the parenthetical list of what the marker records. It does not affect `eval_fixture`'s behavior, which fails on any marker whatever its cause (`:81-84`).

The comment is unchanged from `main`. The branch added two more kinds of content: every transcript-check void (Claim 1) and the in-progress text written before the run:

```bash
# test/skills/generate-reports.bash:159
  printf '%s\n' "generation did not finish" > "$failed_path"
```

Precise version: "(claude's exit status, an error or missing result event, a transcript check, or a run that never finished)".

**Evidence:** `test/skills/eval-helpers.bash:74-84`, `test/skills/generate-reports.bash:147-159`, `test/skills/generate-reports.bash:264-320`

---

## Claim 17: "Directory of this file, for transcript.jq: BATS_TEST_DIRNAME can be pointed elsewhere (the dispatcher tests do), so the module is found relative to here."

**Location:** `test/skills/eval-helpers.bash:366-368`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers module resolution when `BATS_TEST_DIRNAME` is repointed. It does not establish the behavior if eval-helpers.bash is copied without transcript.jq beside it.

```bash
# test/skills/eval-helpers.bash:368
EVAL_HELPERS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

`mode1-equiv.bats:249` and `:288` set `BATS_TEST_DIRNAME="$root/test/skills"`, a tree that symlinks only `mode1-equiv.py`. Both tests pass, so the module is found through `EVAL_HELPERS_DIR` (`cfc-9c73ae4-suites.txt`).

**Evidence:** `test/skills/eval-helpers.bash:366-378`, `test/skills/mode1-equiv.bats:241-298`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 18: "transcript_checked <transcript>: fail with a message unless the transcript is readable, well formed by transcript.jq's rules and holds an init event. A junk, truncated or unexpectedly shaped transcript would otherwise read as 'no calls' …"

**Location:** `test/skills/eval-helpers.bash:387-391`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the first sentence, which is exactly what the function checks, and the "truncated" wording. The "unexpectedly shaped" wording shares the defect verdicted in Claim 26, and is not re-verdicted here.

The function (`:392-411`) returns 1 on a jq failure or empty output, on `n != 0` and on `init != init`, matching the first sentence. "Truncated" is imprecise: a transcript cut at a line boundary after init passes (E1, exit 0; details in Claim 8).

**Evidence:** `test/skills/eval-helpers.bash:387-411`, `docs/reviews/execution-logs/cfc-9c73ae4-helper-probes.txt`

---

## Claim 19: "tool_inputs_checked <transcript> <tool>: … also fail when <tool> is empty, or when the init event lists the run's tools and <tool> is not one of them (a misspelled name such as 'bash')."

**Location:** `test/skills/eval-helpers.bash:413-416`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the empty-name guard, the init-tools membership test and the `transcript_checked` precondition. It does not cover a run whose init event has no `tools` array, where any name is accepted, as the wording implies.

The body is quoted in Claims 7 and 10. The membership test is `:429` `grep -qxF -e "$tool"` over the init's string tools. The tests at `mode1-equiv.bats:347` (empty name) and the "tool name the run's init event does not list" test pass (`cfc-9c73ae4-suites.txt`).

**Evidence:** `test/skills/eval-helpers.bash:417-434`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 20: "The transcript is read here, through transcript.jq: it must be well formed with an init event, and every Bash call must be denied (the same deny_record_counts the generator voids runs with). The skill-owned checker … only ever sees the list of attempted commands."

**Location:** `test/skills/eval-helpers.bash:509-513`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the sharing of `deny_record_counts` with the generator, the `"0 0 0 0"` gate, the temp-file path and its cleanup on the jq-failure and checker-failure paths, and the argv the checker receives. It does not establish that "every Bash call" includes calls in `user` events (Claim 29).

The gate is quoted in Claim 12. The generator uses the same definition (`generate-reports.bash:290`, `t::deny_record_counts`). Temp file and cleanup:

```bash
# test/skills/eval-helpers.bash:531-535 (excerpt starts inside assert_mode1_equiv(), which begins :516; continues to :540 — read)
  cmds="$(mktemp "${BATS_TEST_TMPDIR:-${TMPDIR:-/tmp}}/mode1-cmds.XXXXXX")"
  transcript_jq "$t" '[t::tool_uses[] | select(.name == "Bash") | .input.command]' > "$cmds" \
    || { rm -f "$cmds"; echo "Could not read $t"; return 1; }
  python3 "$checker" "${BATS_TEST_DIRNAME}/../../skills/${skill}/SKILL.md" "$cmds" "$spec" 2>&1 || rc=$?
  rm -f "$cmds"
```

The checker's argv is SKILL.md, the commands file and the spec, and nothing from the transcript. In probe E4 the checker exits 1, and no files remain in `BATS_TEST_TMPDIR` afterwards (`cfc-9c73ae4-helper-probes.txt`).

**Evidence:** `test/skills/eval-helpers.bash:505-540`, `test/skills/generate-reports.bash:286-291`, `docs/reviews/execution-logs/cfc-9c73ae4-helper-probes.txt`

---

## Claim 21: "Every kept transcript is read strictly through transcript.jq: a malformed event or a missing init event voids the run"

**Location:** `test/skills/generate-reports.bash:31-33`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers voiding: every `FIXTURE_TRANSCRIPT=1` run goes through the strict reader, and a malformed event or missing init sets `failure`. It does not cover the report text or the result state, which are read by a separate, lenient parser.

```bash
# test/skills/generate-reports.bash:252-257 (excerpt starts inside generate_one(), which begins :141; continues to :335 — read)
    jq -rR 'fromjson? | select(.type == "result") | .result // empty' "$transcript_path" \
      > "$report_path" 2>/dev/null || : > "$report_path"
    if [ -z "$failure" ]; then
      local result_state
      result_state=$(jq -rR 'fromjson? | select(.type == "result") | if .is_error then "error" else "ok" end' \
        "$transcript_path" 2>/dev/null | tail -n 1)
```

In jq 1.6, `fromjson?` also swallows the downstream `.type` error on a non-object line. Over a file with `123` and `"str"` lines, the `:256` filter prints `ok` and exits 0 (`cfc-9c73ae4-misc.txt`, 2026-09-26T05:44:34Z). The strict reader still runs afterwards and voids such a file, so voiding does not depend on the lenient parse. Precise version: "every kept transcript is *checked* through transcript.jq; the report text and result state are extracted separately".

**Evidence:** `test/skills/generate-reports.bash:247-263`, `test/skills/generate-reports.bash:285-320`, `docs/reviews/execution-logs/cfc-9c73ae4-misc.txt`

---

## Claim 22a: "Fail-closed: the marker exists from here until every check has passed, so a run interrupted or aborted at any step (set -e, a signal) is never graded"

**Location:** `test/skills/generate-reports.bash:156-159`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the marker's presence during the run and after an abort. The abort is shown under `set -e`; a signal is read from the code, not sent. It does not cover outputs of *later* fixtures in the same invocation: an abort stops the loop, and their outputs from an earlier invocation are left as they were (that earlier run's own marker state applies).

```bash
# test/skills/generate-reports.bash:155-159
  rm -f "$report_path" "$transcript_path" "$failed_path"
  # Fail-closed: the marker exists from here until every check has passed, so
  # a run interrupted or aborted at any step (set -e, a signal) is never graded
  # (review iteration 4, A23).
  printf '%s\n' "generation did not finish" > "$failed_path"
```

The only removal is `:329`, reached only when `failure` is empty; the other exit is `return 0` after overwriting the marker (`:323-327`). P8 (set -e abort) exits 1 with the marker holding "generation did not finish". `generate-reports.bats:663` observes the marker during the run (`cfc-9c73ae4-gen-probes.txt`, 2026-09-26T05:27:25Z; `cfc-9c73ae4-suites.txt`). P6 and P7 show that non-transcript runs follow the same lifecycle: success → no marker; exit 1 → "claude exited 1".

**Evidence:** `test/skills/generate-reports.bash:141-335`, `test/generate-reports.bats:663-682`, `docs/reviews/execution-logs/cfc-9c73ae4-gen-probes.txt`

---

## Claim 22b: "the marker exists from here until every check has passed" / "Every check passed: only now is the fail-closed marker removed."

**Location:** `test/skills/generate-reports.bash:156`, `test/skills/generate-reports.bash:328` (same claim: 272bc83 message "removed only after every check passes (A23)"; `docs/working/dd-arith-eval-bash-grant.md:176`; rubric A23 note)
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the invariant "marker removed ⇒ every deny-record check ran and passed". It does not establish how likely the triggering input is: it needs a newline inside the CLI-written `claude_code_version` string, which the model cannot write, except through a command that rewrites the transcript (C29, accepted).

The fields are split with `read`, which stops at the first newline, and a missing counts field skips all four count checks:

```bash
# test/skills/generate-reports.bash:297
      IFS=$'\x1f' read -r n_problems problems init_state cli_version counts <<< "$verdict"
```

```bash
# test/skills/generate-reports.bash:307-309 (excerpt ends :309; the if-block continues to :318 — read)
        if [ -n "$counts" ]; then
          local undenied unseen orphans foreign
          read -r undenied unseen orphans foreign <<< "$counts"
```

`cli_version` is the only free-text field, and it comes before `counts`. It is not validated by `problems`. Probe P1 runs deny-record with an undenied Bash call, and an init event whose `"claude_code_version":"9.9\n9"` (a JSON-escaped newline). The generator prints "Done", and **no marker** is left. The control P4, with a normal version, gives "Bash tripwire: 1 Bash call(s) …" (`cfc-9c73ae4-gen-probes.txt`). A `\u001f` in the version (P2) shifts the fields and happens to fail closed ("91 Bash call(s)"). An object version (P3) makes jq's `join` fail, which also fails closed.

**Evidence:** `test/skills/generate-reports.bash:285-329`, `docs/reviews/execution-logs/cfc-9c73ae4-gen-probes.txt`

---

## Claim 23a: The "Transcript checks" list: well-formed, init; under deny-record, tripwire, parser canaries ("every Bash denial and every tool_result must answer a tool_use the reader saw"), only-Bash denials, init canary

**Location:** `test/skills/generate-reports.bash:264-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the correspondence between each listed condition and a `failure` assignment at `:298-318`, and the "(A17)" non-blaming of a missing init. It does not establish what "saw" includes: the reader sees tool_uses only in assistant events (Claim 29).

Each bullet maps to one test: `n_problems` (`:298`), `init_state = none` (`:301`), `nobash` (`:305-306`, which does not fire for `none`, as A17 wants), `undenied`/`unseen`/`orphans`/`foreign` (`:310-317`, quoted in Claims 1 and 4). The generator tests at `generate-reports.bats:572-684` pass (`cfc-9c73ae4-suites.txt`).

**Evidence:** `test/skills/generate-reports.bash:264-320`, `test/generate-reports.bats:572-700`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 23b: "tripwire: … Also when the run already failed, so an executed call is never hidden behind 'claude exited N' (C10)."

**Location:** `test/skills/generate-reports.bash:272-274`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the tripwire when the run failed for a non-transcript reason (exit code, result error). It does not cover a failed run whose transcript also has a malformed line. There the counts are never computed, and an undenied call goes unreported, although the run is still voided.

```jq
# test/skills/generate-reports.bash:290 (inside the jq program :286-291)
        (if (t::problems | length) == 0 then (t::deny_record_counts | "\(.undenied) \(.unseen) \(.orphans) \(.foreign)") else "" end)
```

Probe P5 has claude exit 3, an undenied Bash call in a well-formed event, and one `[1]` line. The marker reads "claude exited 3; transcript: 1 malformed event(s) …", with no tripwire line (`cfc-9c73ae4-gen-probes.txt`). Precise version: "also when the run already failed, as long as the transcript is well formed".

**Evidence:** `test/skills/generate-reports.bash:285-320`, `docs/reviews/execution-logs/cfc-9c73ae4-gen-probes.txt`

---

## Claim 24: "\x1f, not a tab: read collapses runs of whitespace separators, so an empty field (no problem text, no counts) would shift the rest."

**Location:** `test/skills/generate-reports.bash:295-296` (same reasoning: `test/skills/eval-helpers.bash:394-395`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the empty-field case the comment names. Problem strings are fixed literals, with `\(.type)` limited to "assistant"/"user", so they carry neither `\x1f` nor a newline. It does not cover a newline or `\x1f` in `cli_version`, which breaks the split (Claim 22b).

The problem strings are the literals in `transcript.jq:36-58`. The passing tests exercise both empty fields: the malformed-shape tests (empty counts) and every clean run (empty problem text), `cfc-9c73ae4-suites.txt`.

**Evidence:** `test/skills/generate-reports.bash:285-320`, `test/skills/transcript.jq:35-60`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 25: "Each holds an init event listing Bash, one well-formed DENIED Bash call (id g1) …, one bad line, and a result event denying g1 only. So a reader that skips the bad line sees a fully passing run …. Where the bad line itself carries a Bash call, that call (id x1) is never denied"

**Location:** `test/skills/malformed-transcripts.bash:7-14`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the file structure and the "skip → passing run" property. The control is the file minus its bad line, and it passes in both suites. It does not hold for the "(id x1)" detail in two shapes.

```bash
# test/skills/malformed-transcripts.bash:32
      object_id)       bad='{"type":"assistant","message":{"content":[{"type":"tool_use","id":{"x":1},"name":"Bash","input":{"command":"pwd"}}]}}' ;;
```

```bash
# test/skills/malformed-transcripts.bash:37
      no_id)           bad='{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"pwd"}}]}}' ;;
```

The Bash calls in these two have no id `x1`. `list_tool_use_id` instead *names* `["x1"]` in a denial. The rest holds: `:40-45` writes init, g1, the bad line and the g1-only result; the controls pass (`generate-reports.bats:631-634`, `mode1-equiv.bats:306-309`). Precise version: "that call (id x1, or an id the reader cannot use) is never denied".

**Evidence:** `test/skills/malformed-transcripts.bash:1-47`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 26: "Here an unexpected shape is a problem, never skipped, and 'a Bash call', 'denied' and 'seen' are defined once."

**Location:** `test/skills/transcript.jq:6-7` (same contract: `docs/working/dd-arith-eval-bash-grant.md:175` "It rejects any event of a shape it does not expect instead of skipping it"; `docs/decisions/log.md:77` "It rejects unexpected event shapes rather than skipping them"; `test/skills/eval-helpers.bash:389-391` "…or hide a call inside a shape a looser reader skips"; 272bc83 message "An unexpected event shape is a problem, never skipped" and Notes "a future CLI shape change now voids runs loudly ('malformed event') rather than passing them")
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the "never skipped" contract, and the claim that a CLI shape change voids runs, for tool calls. The 13 table shapes are rejected (Claim 2). It does not establish that the CLI emits any of the shapes below; no real transcript is in the repo (Claim 27a).

`_event_problems` validates content blocks in `assistant` **and** `user` events, and ignores other event types entirely:

```jq
# test/skills/transcript.jq:38-44 (excerpt ends :44; enclosing _event_problems continues to :60 — read)
  elif (.type == "assistant" or .type == "user") then
    if (.message | type) != "object" then "\(.type) event: message is not an object"
    elif (.message.content | type) != "array" then "\(.type) event: message.content is not an array"
    else
      .message.content[] |
      if type != "object" or ((.type // null) | _is_str | not) then "a content block is not an object with a string type"
      elif .type == "tool_use" then
```

`tool_uses` reads only `assistant` events (Claim 29). So a well-formed tool_use in a `user` event is accepted and then skipped. So is any tool_use in an event whose `type` is missing, unknown (`"assistant_message"`) or not a string (`["assistant"]`), and any tool_use nested in a `tool_result`'s `content`. Each probe below adds an undenied Bash call to a good g1 transcript. `problems` is `[]` and `undenied` is 0 for `tool_use_in_user_event`, `typeless_event_with_tool_use`, `renamed_event_type`, `array_type_field` and `tool_use_inside_tool_result` (`cfc-9c73ae4-reader-probes.txt`). End to end:
- The generator under deny-record passes an undenied Bash call in a `user` event: "Done", no marker (P10). The same holds for a plain transcript run (P9) (`cfc-9c73ae4-gen-probes.txt`).
- `assert_no_tool_called Bash rm` exits 0 on a transcript with `rm -rf x` in a `user`-event tool_use (E2, `cfc-9c73ae4-helper-probes.txt`).

Under deny-record, a call that actually *ran* would still leave a `tool_result` in a `user` event, and the orphan canary would void the run. A renamed event type is caught only if its tool_result stays in a `user` event. The plain `tool_called`/`no_tool_called` checks have no such backstop. So the Notes line "a future CLI shape change now voids runs loudly" holds only for changes *inside* assistant, user and result events. Precise version: "an unexpected shape of an assistant, user or result event is a problem; tool calls are read only from assistant events, and events of other types are not inspected".

**Evidence:** `test/skills/transcript.jq:1-19`, `test/skills/transcript.jq:35-79`, `docs/reviews/execution-logs/cfc-9c73ae4-reader-probes.txt`, `docs/reviews/execution-logs/cfc-9c73ae4-gen-probes.txt`, `docs/reviews/execution-logs/cfc-9c73ae4-helper-probes.txt`

---

## Claim 27a: "Shapes accepted, matching 13 real runs of CLI 2.1.283 (2026-09-25)"

**Location:** `test/skills/transcript.jq:12` (related: 272bc83 Notes "the accepted shapes come from 13 real transcripts on CLI 2.1.282/283")
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers whether the 13 transcripts exist and whether they share one CLI version. It does not establish anything about the accepted-shape list itself (Claim 27b).

No `*.transcript.jsonl` exists anywhere under `/workspace`: `rg --files -uu -g '*.transcript.jsonl' /workspace` finds 0 files (`cfc-9c73ae4-misc.txt`; paraphrased — no quote available because the claim covers absence of files). The two sources also disagree on the version: the header says "CLI 2.1.283" and the commit says "2.1.282/283". Verifying either would take the transcripts, or their `claude_code_version` values.

**Evidence:** `test/skills/transcript.jq:12`, `docs/working/dd-arith-eval-bash-grant.md:13`

---

## Claim 27b: The accepted-shapes list: "every line a JSON object; assistant and user events carry an object `message` whose `content` is an array of objects, each with a string `type`; a tool_use has string `id` and `name`, and a Bash tool_use an object `input` with a string `command`; a tool_result has a string `tool_use_id`; a result event's `permission_denials`, when present, is an array of objects with string `tool_name` and `tool_use_id`. Other event types … need only be objects."

**Location:** `test/skills/transcript.jq:12-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the match between the list and `_event_problems`. It does not establish that the list is safe: its last sentence is the gap in Claim 26. "When present" includes `null`, which is accepted as absent.

Each clause has a branch in `_event_problems` (`:36`, `:39-40`, `:43`, `:45`, `:46-47`, `:49`, `:52-58`). The null case:

```jq
# test/skills/transcript.jq:52 (inside _event_problems, :35-60 — read)
  elif .type == "result" and has("permission_denials") and .permission_denials != null then
```

Probes: top-level `"a string"`, `true` and `null` each give "a line is not a JSON object". `permission_denials: null` gives no problem. An assistant event with extra top-level fields is accepted and its call counted (`cfc-9c73ae4-reader-probes.txt`).

**Evidence:** `test/skills/transcript.jq:12-19`, `test/skills/transcript.jq:35-60`, `docs/reviews/execution-logs/cfc-9c73ae4-reader-probes.txt`

---

## Claim 28: "A line that fails to parse becomes {"__unparsed": ...} (a problem) when it starts like JSON, '{' or '[' …. A plain-text line … becomes {"__text": ...} and is ignored. Note: inside `catch`, jq's input is the error message, so the line is bound first"

**Location:** `test/skills/transcript.jq:21-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the parse and classification of each non-blank line (code quoted in Claim 9), including CRLF, leading whitespace, a UTF-8 BOM and two objects on one line. It does not establish that no reader could find a call in a line starting with other text (for example `x{…}`); none of the in-repo readers can.

Probes (`cfc-9c73ae4-reader-probes.txt`):
- A CRLF-terminated event, a line with leading spaces and a BOM-prefixed line all parse under jq 1.6 fromjson, and their Bash call is counted (`undenied: 1`).
- Two objects on one line give "a line starting like JSON does not parse".

The catch-input note is shown in `cfc-9c73ae4-catch-probe.txt` (2026-09-26T05:38:29Z): inside `catch`, `.` is the message `"Invalid \\uXXXX\\uXXXX surrogate pair escape …"`, and the pre-fix form classifies the lone-surrogate line as `__text`. At HEAD it is `__unparsed`. Blank lines are dropped by `select(test("\\S"))`.

**Evidence:** `test/skills/transcript.jq:21-30`, `docs/reviews/execution-logs/cfc-9c73ae4-reader-probes.txt`, `docs/reviews/execution-logs/cfc-9c73ae4-catch-probe.txt`

---

## Claim 29: "Tool calls: {id, name, input} for every tool_use, at any depth (sub-agents' events are assistant events too)."

**Location:** `test/skills/transcript.jq:68-69` (same claim: `test/skills/eval-helpers.bash:380-381` "every tool_use block for the named tool, at any depth (sub-agents' calls included)")
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers which tool_use blocks the definition returns. Sub-agent calls in assistant events *are* returned (probe `tool_use_in_subagent_event`: x1 counted). It does not establish whether the CLI ever emits tool_use outside assistant events.

```jq
# test/skills/transcript.jq:70-72
def tool_uses:
  [.[] | objects | select(.type == "assistant") | .message.content[]? | objects | select(.type == "tool_use")
   | {id, name, input}];
```

Only top-level content blocks of `assistant` events are returned. A tool_use in a `user` event, which `_event_problems` validates as a well-formed tool_use (`:38-48`), is not returned. Neither is one nested inside a block or in an event of any other type. Reader probe `tool_use_in_user_event` gives `bash_ids: ["g1"]` (x1 missing). End-to-end effects are in Claim 26 (P9, P10, E2). Precise version: "every tool_use in the content of an assistant event, top-level or sub-agent".

**Evidence:** `test/skills/transcript.jq:68-72`, `test/skills/eval-helpers.bash:380-385`, `docs/reviews/execution-logs/cfc-9c73ae4-reader-probes.txt`

---

## Claim 30: "Only meaningful when `problems` is empty, which guarantees every id is a string. undenied: Bash tool_uses whose id no Bash denial names … unseen: Bash denials naming a tool_use the parser did not see … orphans: tool_results answering a tool_use the parser did not see … foreign: denials of a tool other than Bash"

**Location:** `test/skills/transcript.jq:84-89`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the string-id guarantee and the four definitions against `:90-101` (quoted in Claim 4). It does not establish that the counts see every call (Claim 29).

The string guarantee holds: every id that `tool_uses`, `denials` or `tool_result_ids` can emit is checked to be a string at `:45`, `:49` or `:56`. `undenied`, `orphans` and `foreign` match their code. `unseen` is narrower than its gloss, since it tests membership in `$bash_set`, not `$all_set`:

```jq
# test/skills/transcript.jq:99 (inside deny_record_counts, :90-101 — read)
      unseen:   ([$denied[] | select($bash_set[.] | not)] | length),
```

So a Bash denial naming a *seen* Read tool_use counts as unseen. Also, `undenied` matches by id: a second Bash tool_use reusing a denied id is not counted (probe `duplicate_id_undenied_second_call`: `undenied: 0`). The gloss says "whose id no Bash denial names", which that literally satisfies. Precise gloss for unseen: "Bash denials naming no Bash tool_use the reader saw".

**Evidence:** `test/skills/transcript.jq:84-101`, `docs/reviews/execution-logs/cfc-9c73ae4-reader-probes.txt`

---

## Claim 31: "Tests (bats TAP plan lines and grep counts, pasted, not typed): generate-reports.bats 1..42 ok=42, mode1-equiv.bats 1..29 ok=29, eval-helpers-transcript.bats 1..7 ok=7, eval-helpers-empty-report.bats 1..6 ok=6, arithmetic-eval-gate.bats 1..18 ok=18, arithmetic-eval-eval.bats 1..9 ok=9 (skip=9), arithmetic-eval-after-denial-patterns.bats 1..5 ok=5, arithmetic-eval-format.bats 1..25 ok=25; scripts/health-check.sh: 'All checks passed.' exit=0"

**Location:** commit 272bc83 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the counts and pass state at 9c73ae4 (272bc83 plus a docs-only commit). It does not establish the counts at 272bc83 itself, though 9c73ae4 changes no test file.

Each suite was run with `bats --tap <file>`, cwd `/workspace`, between 2026-09-26T05:25:07Z and 05:25:29Z, every exit 0. The plan and ok counts equal the commit's figures exactly, including `skip=9` for the eval suite (`cfc-9c73ae4-suites.txt`). `bash scripts/health-check.sh` exits 0 with "All checks passed." at 2026-09-26T05:29:45Z (`cfc-9c73ae4-health-check.txt`).

**Evidence:** `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`, `docs/reviews/execution-logs/cfc-9c73ae4-health-check.txt`

---

## Claim 32: "Mutation check: with `problems` stubbed to [], all 5 tests that depend on the reader fail; restored, they pass."

**Location:** commit 272bc83 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mutation `def problems: [];` in a `git archive HEAD test skills scripts` copy, with all eight suites run. It does not establish mutation coverage of `tool_uses`, `denials` or `deny_record_counts`.

In the mutated copy (cwd `$SCRATCH/mut`, 2026-09-26T05:28:31Z), exactly 5 tests fail: `generate-reports.bats` 36, 38, 39 and 42, and `mode1-equiv.bats` 26. The other six suites pass unchanged (`cfc-9c73ae4-mutation.txt`). The unmutated HEAD passes everything (Claim 31).

**Evidence:** `docs/reviews/execution-logs/cfc-9c73ae4-mutation.txt`, `docs/reviews/execution-logs/cfc-9c73ae4-suites.txt`

---

## Claim 33: "inside jq's `catch`, `.` is the error message, so the first 'starts like JSON' test examined the message and let a lone-surrogate line through as text. The line is now bound before `try`."

**Location:** commit 272bc83 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers jq 1.6's catch input and the before/after classification of a lone-surrogate line. It does not establish that the first version was exactly the form reconstructed here: it was never committed, and the probe uses the form the message describes.

See Claim 28 (`cfc-9c73ae4-catch-probe.txt`). `try fromjson catch .` yields the error-message string. The described pre-fix form yields `{"__text":true}`, and HEAD's `events` yields `["__unparsed"]`.

**Evidence:** `test/skills/transcript.jq:27-30`, `docs/reviews/execution-logs/cfc-9c73ae4-catch-probe.txt`

---

## Claim 34: "Correction to 37c5ea9's message: mode1-equiv.bats had 25 tests, not 33."

**Location:** commit 272bc83 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `@test` count at 37c5ea9. It does not re-examine 37c5ea9's other figures.

`git show <c>:test/skills/mode1-equiv.bats | grep -c '^@test'` gives f9feb2c 23, 37c5ea9 25, 7bd0974 25 and HEAD 29 (cwd `/workspace`, exit 0, 2026-09-26T05:44:34Z, `cfc-9c73ae4-misc.txt`).

**Evidence:** `test/skills/mode1-equiv.bats`, `docs/reviews/execution-logs/cfc-9c73ae4-misc.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 14** (`mode1-equiv.py:34-37`, DD `:182`): "Exit 1 always means a model result". A SKILL.md evaluator that prints another format, fails or times out gives exit 1, and `--check-spec` passes it (E5). Either narrow the wording or have `evaluate()` failures on SKILL.md's own sample expression exit 2.
- **Claim 22b** (`generate-reports.bash:156`, `:328`): "removed only after every check passes". A newline in `claude_code_version` truncates the `read`, drops `counts`, skips all four deny-record checks, and the marker is removed with an undenied Bash call present (P1).
- **Claim 26** (`transcript.jq:6-7`, DD `:175`, log #56, `eval-helpers.bash:389-391`, 272bc83 message and Notes): "an unexpected shape is a problem, never skipped" / "a future CLI shape change voids runs loudly". A tool_use in a `user` event, in an event of unknown, missing or non-string `type`, or nested in a `tool_result` is accepted and skipped. The generator (deny-record included) and `no_tool_called` pass an undenied call (P9, P10, E2).
- **Claim 29** (`transcript.jq:68-69`, `eval-helpers.bash:380-381`): "every tool_use, at any depth". Only assistant-event content is read.

### Stale
- **Claim 1** (`docs/decisions/log.md:77`): the voiding list predates 272bc83 and omits malformed events, the tool_result canary and foreign denials.
- **Claim 16** (`eval-helpers.bash:77-79`): the list of what `.failed` records omits transcript-check voids and the in-progress marker.

### Mostly Accurate
- **Claim 8** (rubric A26): the "truncated transcript" item is unchanged (E1: init-only transcript passes).
- **Claim 10** (rubric C33): the "three passes" half is not fixed.
- **Claim 11** (DD `:175`, log #56): `assert_subagents_min` and the generator's report/result-state extraction still use lenient `fromjson?`.
- **Claim 12** (`mode1-equiv.py:6-10`): "refuses … undenied calls" only for assistant-event calls.
- **Claim 18** (`eval-helpers.bash:387-391`): "truncated" means before init or mid-line only.
- **Claim 21** (`generate-reports.bash:31-33`): transcripts are *checked* strictly; the report text and is_error are extracted leniently.
- **Claim 23b** (`generate-reports.bash:272-274`): the tripwire does not run when the transcript also has a malformed line (P5).
- **Claim 25** (`malformed-transcripts.bash:12-13`): the calls in `object_id` and `no_id` are not "id x1".
- **Claim 30** (`transcript.jq:87`): `unseen` counts denials naming no *Bash* tool_use, not no tool_use.

### Unverifiable
- **Claim 27a** (`transcript.jq:12`): "13 real runs of CLI 2.1.283". No transcripts are kept, and the commit says 2.1.282/283. Needs the transcripts or their `claude_code_version` values.

---

## Goal-Alignment Note

**Success criterion (verbatim):** "A markdown report saved to docs/reviews/code-fact-check-report.md, structured per the code-fact-check skill, with header lines `**Commit:** 9c73ae4` and `**Replication:** k=1 (loop pass, decision 031)`."

**Answered:** Yes. The report is saved at that path with both header lines. It covers all seven "claims that particularly need checking" from the brief:
- transcript.jq: Claims 26-30.
- The generator's comments, marker and field handling: Claims 21-24.
- The eval-helpers functions: Claims 16-20.
- mode1-equiv's docstring and catch-all: Claims 12-15.
- The malformed-transcripts header: Claim 25.
- The DD doc, log #56 and rubric rows: Claims 1-11.
- The commit message: Claims 31-34, plus 22b, 26 and 27a.

Every probe the brief listed was run (`cfc-9c73ae4-reader-probes.txt`).

**Out of scope:** the Q-062 install.sh gate, which is unchanged since iteration 4's review, was not re-verified. So were the settled items (override log, the rubric's Deferred and open-by-choice rows). No `claude` or network command was run.

**Escalate:** Claims 26/29 are the R2 class again: a Bash call in a shape the reader accepts but does not count passes the generator and `no_tool_called`. They sit outside the 13-shape table, so R2's "Fixed" holds only for the named shapes. Claim 14 is the fifth appearance of the mode1-equiv exit-contract overclaim (A10 → A11 → A19 → A21 → here). Claim 22b is a fail-open path in the marker the commit calls fail-closed. None is known to be reachable with the current CLI: the shapes are unobserved, and the version field is CLI-written. Whether that is acceptable at the loop's terminal pass is the orchestrator's and the user's call.

**Questions:** none.

**Decisions:** Duplicate statements of one contract, found in several files, are verdicted once under the first location, with the other locations listed (Claims 11, 14, 22b, 26, 29), so counts are not inflated. I rated Claim 22b Incorrect rather than Mostly accurate because a probe breaks the invariant outright. Its low reachability is stated in the Scope field, so the orchestrator can weigh severity separately.
