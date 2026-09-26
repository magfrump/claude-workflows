Commit: 9c73ae4

# Architecture Review: skill-fixtures (Q-062 [2], Q-063 [1]), iteration 5 (user-authorized terminal pass)

**Scope:** `git diff main...HEAD` on skill-fixtures (HEAD 9c73ae4), with the weight on 272bc83 ("one strict transcript reader"). Code files: `test/skills/transcript.jq` (new), `test/skills/generate-reports.bash` (`generate_one`), `test/skills/eval-helpers.bash` (the transcript helpers, `assert_mode1_equiv`, `assert_subagents_min`), `test/skills/arithmetic-eval/mode1-equiv.py`, and `test/skills/malformed-transcripts.bash` (new, a shared test table). Prose that restates a code contract (the DD doc's "As built", log #56, header comments) is reviewed only as a copy of that contract. `devcontainer-config/install.sh` has no commits since 5bdee46, so iteration 4's review of it stands and it is not re-reviewed here.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 9c73ae4, 37 claims). This review builds on its Claims 11, 14, 22b, 26, 29 and 30 and does not re-verify them. I ran two new probes. Both are saved under `docs/reviews/execution-logs/` and pass `shellcheck -x -e SC1091 -s bash -S warning`:
- `arch-9c73ae4-insertion-fuzz.{sh,txt}` puts one undenied Bash `tool_use` in every array and object of a good transcript, and also renames the event type. It asks both HEAD's reader and a census prototype for a verdict on each variant.
- `arch-9c73ae4-census-probe.{sh,txt}` runs the census prototype against the fact-check's escape shapes, the 13-shape table, a control and a cost case.

**Scope check.** Three trigger categories apply:
- *Module structure:* a new shared module, `transcript.jq`, that two consumers import.
- *Public APIs / data models:* the module's exported definitions (`events`, `problems`, `init`, `tool_uses`, `denials`, `tool_result_ids`, `deny_record_counts`). Also mode1-equiv's input contract changed from transcript to JSON array, while its 0/1/2 exit protocol stayed. The generator's `\x1f` verdict record is also in scope.
- *Cross-cutting:* the run-voiding pipeline (reader → generator verdict → `.failed` → `eval_fixture` → checks).

**Trust-boundary cross-reference.** The newest security review is `docs/reviews/security-review-2026-09-25-q062-q063-iter4.md` (Commit: `5bdee46`). That review predates this diff, so its boundaries may be stale. 272bc83 replaced the transition points it names. Two of its labels are used below:
- `B3`: claude stream-json → the generator's one-pass jq → `.failed`.
- `B4`: transcript.jsonl → the eval-helpers transcript checks and mode1-equiv.py → the fixture's pass or fail.

After 272bc83, `transcript.jq` is the transition point of **both** `B3` and `B4`. No recommendation below moves either boundary. Findings 1 and 2 change what the shared transition point accepts, and are tagged.

**Not re-filed (settled):** the override log (C4, C5, C9, C6, trap RETURN, `--tools` variadic, RUNNER_ALLOWED_TOOLS naming); A1/Q-064; A20; C24 and C30 (Deferred); C3/C4/C6/C8/C13/C14/C15/C34/C35 (open by choice). C29 ("a command that ran could rewrite the transcript") is accepted and bounds everything below: these findings concern *accidental* shape drift, not concealment.

## Dependency Map

```
                      malformed-transcripts.bash (test table, 13 shapes)
                         ▲                       ▲
 test/generate-reports.bats            test/skills/mode1-equiv.bats
         │                                        │
         ▼                                        ▼
 generate-reports.bash ──import──► transcript.jq ◄──import── eval-helpers.bash
   generate_one:                    events/problems/init/       transcript_jq, transcript_checked,
   verdict (\x1f record) → .failed  tool_uses/denials/          tool_inputs_checked, assert_*,
   + 2 lenient fromjson? readers    tool_result_ids/            assert_mode1_equiv ──JSON array──► mode1-equiv.py
     (report text, result_state)    deny_record_counts          assert_subagents_min: own lenient      │
                                                                  fromjson? reader                      ▼
                                                                                        skills/arithmetic-eval/SKILL.md
                                                                                        (Mode 1 block + evaluator, run)
```

The direction is now right. Two volatile consumers (a generator shell script and a grader shell library) depend on one module that defines the stream's semantics, and neither consumer depends on the other. mode1-equiv.py lost its transcript dependency, so it now depends only on SKILL.md and a list of strings. That is the narrowing iteration 4's Finding 1 asked for. Two dependencies remain wrong-way or unowned:
- **Three readers still bypass the module**: the generator's report-text and `result_state` extraction, and `assert_subagents_min` (Finding 4).
- **mode1-equiv depends on SKILL.md's evaluator *behavior* without validating it.** Only its syntax is checked (Finding 3).

## Findings

#### 1. The strict reader validates one set of positions and counts another. "Every Bash call is counted or the run is voided" is a completeness property, and a per-position validator cannot establish one. This is the fifth firing of the class, relocated inside the new module

**Severity:** Structural
**Location:** `test/skills/transcript.jq:35-79` (`_event_problems`, `tool_uses`, `denials`, `tool_result_ids`); consumers `generate-reports.bash:286-318`, `eval-helpers.bash:380-385, 524-533`
**Move:** #2 responsibility boundaries; #7 coupling surface (two definitions inside one module)
**Confidence:** High (mechanism, executed) / Low (exposure: no escape shape has been observed from the real CLI, and no real transcript is in the repo, fact-check Claim 27a)
**Legibility-target:** for-author

**Evidence (verbatim):**
```jq
# test/skills/transcript.jq:35-44 (excerpt ends :44 inside _event_problems; the rest, :45-60, validates tool_use/tool_result blocks and result denials, and ends `else empty end;` for every other event type — read)
def _event_problems:
  if type != "object" then "a line is not a JSON object"
  elif has("__unparsed") then "a line starting like JSON does not parse"
  elif (.type == "assistant" or .type == "user") then
    if (.message | type) != "object" then "\(.type) event: message is not an object"
    elif (.message.content | type) != "array" then "\(.type) event: message.content is not an array"
    else
      .message.content[] |
      if type != "object" or ((.type // null) | _is_str | not) then "a content block is not an object with a string type"
      elif .type == "tool_use" then
```
```jq
# test/skills/transcript.jq:70-72 (whole definition)
def tool_uses:
  [.[] | objects | select(.type == "assistant") | .message.content[]? | objects | select(.type == "tool_use")
   | {id, name, input}];
```
```text
# docs/reviews/execution-logs/arch-9c73ae4-insertion-fuzz.txt (last line; 22 per-variant lines precede it)
variants: 22  HEAD escapes: 20  CENSUS escapes: 0
```

There are three selectors over the event list, and each has its own domain:
- *validated*: top-level content blocks of `assistant` and `user` events, plus result denials; every other event type or position is accepted as-is (header line 19: "Other event types … need only be objects");
- *counted as calls*: top-level content blocks of `assistant` events only;
- *counted as results*: top-level content blocks of `user` events only.

The safety property the consumers rely on is a statement about the *whole stream*: no Bash `tool_use` exists anywhere that is neither counted nor refused. A validator that checks shapes at chosen positions cannot establish that. It can only say "the positions I look at are well formed". The gap is the set difference between the validated and counted domains, plus everything outside both. The insertion probe measures that gap directly. It inserts an undenied Bash call into every array and object of a good transcript, and 20 of 22 variants pass HEAD's reader with `problems == []` and `undenied == 0`. The escapes include:
- a call in a `user` event (fact-check Claims 26 and 29);
- a call inside a `tool_result`;
- a call next to a denial or inside its `tool_input`;
- a call at an event's root;
- a call in an assistant event whose `type` is renamed, null, an array, `"user"` or `"system"`.

Only the two positions that are both validated *and* counted catch it: the assistant event's `content` array, and the denials array, where it is a malformed denial.

This is the same structural defect iteration 4 found between mode1-equiv and the generator, "two definitions of what is a call/denied". 272bc83 moved both definitions into one file, which was the right step, but inside that file they are still two selectors. One file does not mean one definition. The module header states the property the code lacks: "an unexpected shape is a problem, never skipped" (`:6`).

Under deny-record, the orphan canary is a partial backstop: a call that actually *ran* leaves a `tool_result` in a `user` event. `no_tool_called:` and plain transcript runs have no backstop at all (fact-check E2, P9).

**Recommendation:** Make the selector that validates and the selector that counts **the same expression**, over the whole event tree:
```jq
def _calls:   [.[] | objects | .. | objects | select(.type == "tool_use")];
def _results: [.[] | objects | .. | objects | select(.type == "tool_result")];
```
- Validate every element of `_calls` and `_results`: string id and name, a Bash call has a string `command`, and a result has a string `tool_use_id`. Add "tool_use ids are unique", which closes Claim 30's duplicate-id case, where a second call reuses a denied id.
- Define `tool_uses` and `tool_result_ids` from these same arrays.
- Keep the event-level checks (object line, `message`/`content` types, denial shapes) as they are.

After this, position no longer matters. A `tool_use` anywhere is counted and validated, and the only way to hide a call is to change the discriminator `"type":"tool_use"` itself, which the unseen and orphan canaries cover under deny-record. The prototype in `arch-9c73ae4-census-probe.txt` does this in about 15 lines:
- the 13 table shapes: rejected, identical to HEAD;
- the fact-check's 7 escape shapes: all voided;
- sub-agent calls, denied `tool_result`s and rate-limit events: still pass;
- the insertion probe: 0 escapes.

Then land the insertion probe as a bats test (Finding 6), and restate the header as what is now true: "every `tool_use` object anywhere in the stream is validated and counted".

**Security implication:** This tightens the shared transition point of `B3` and `B4` (`docs/reviews/security-review-2026-09-25-q062-q063-iter4.md`, Commit: `5bdee46` — security review predates this diff; boundary may be stale). It does not move either boundary. It widens what voids a run (fail-closed), including tool_use-shaped objects inside model-chosen `input` or CLI-embedded copies (Finding 7). The security reviewer should confirm that false voids are the acceptable direction.

#### 2. The deny-record pass condition is computed in jq, carried to bash as a positional record containing a free-text field, and judged twice with opposite empty-field semantics. That is how "removed only after every check passes" fails open (Claim 22b)

**Severity:** Coupling
**Location:** `test/skills/generate-reports.bash:285-318`; `test/skills/eval-helpers.bash:524-530`
**Move:** #7 coupling surface (stamp coupling through an implicit positional schema); #2 (policy split across two languages)
**Confidence:** High (fail-open executed by the fact-check, probe P1)
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/generate-reports.bash:289-290 (inside the jq program :286-291, inside generate_one :141-335)
        (t::init | .claude_code_version // "unknown"),
        (if (t::problems | length) == 0 then (t::deny_record_counts | "\(.undenied) \(.unseen) \(.orphans) \(.foreign)") else "" end)
```
```bash
# test/skills/generate-reports.bash:297 and :307-309 (excerpt ends :309; the if-block continues to :318 with the four count tests — read)
      IFS=$'\x1f' read -r n_problems problems init_state cli_version counts <<< "$verdict"
...
        if [ -n "$counts" ]; then
          local undenied unseen orphans foreign
          read -r undenied unseen orphans foreign <<< "$counts"
```
```bash
# test/skills/eval-helpers.bash:527-530 (inside assert_mode1_equiv :516-540)
  if [ "$counts" != "0 0 0 0" ]; then
    echo "Bash tripwire/parser canary: undenied, unseen, orphan, foreign = $counts (every Bash call must be denied and seen)"
    return 1
  fi
```

Iteration 4's Finding 4 (Informational) noted the positional schema and predicted that it "touches both ends with nothing to connect them". 272bc83 widened the record from four fields to five, and put the only free-text field (`cli_version`, not validated by `problems`) *before* the safety field. Two design choices then compose into a fail-open:
- `read` splits at a newline, so a newline in the version drops `counts`.
- The generator treats an empty `counts` as "skip the four checks". The skip is meant for the case "problems > 0, so the run is already voided", but that case is only implied. The code never checks it.

`assert_mode1_equiv` judges the same counts with the opposite rule (empty ≠ `"0 0 0 0"` → fail). So there are two consumers, two pass predicates and two empty-field semantics. The count *definitions* are shared, but the *verdict* is not. This is a small copy of Finding 1's pattern: shared data, duplicated judgment. Exposure is low, because the version string is CLI-written (C29 covers a command that rewrites it).

**Recommendation:** Move the verdict into the module: `def deny_record_failures: [ …one message string per failed condition… ];` (problems, missing init, init canary, the four counts), and return `["transcript: …"]` when problems exist, so an empty array means exactly "every check ran and passed".
- The generator runs `jq … 't::deny_record_failures | join("; ")'` and voids iff the output is non-empty or jq fails. No positional record, no `read`, no second policy in bash.
- `assert_mode1_equiv` calls the same definition.

This removes the `\x1f` record, the `if [ -n "$counts" ]` skip, and the duplicated `"0 0 0 0"` literal, about −20 lines net. If the record stays, emit `cli_version` through `@json` and fail when `counts` is empty while `n_problems` is 0.

**Security implication:** None for boundary placement. The judgment moves from bash to jq on the same side of `B3`.

#### 3. mode1-equiv's exit protocol routes a failure of an unvalidated dependency (SKILL.md's evaluator) into the model-result channel. The docstring's "exit 1 always … never a checker fault" is the fifth absolute over an open input domain (Claim 14)

**Severity:** Coupling
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:34-37, 76-88, 124-137, 172-177`
**Move:** #1 dependency direction (depends on the behavior of a module it validates only syntactically); #6 substitutability of the exit contract
**Confidence:** High (executed by the fact-check, probe E5)
**Legibility-target:** for-author

**Evidence (verbatim):**
```python
# test/skills/arithmetic-eval/mode1-equiv.py:124-137 (whole function)
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
```python
# test/skills/arithmetic-eval/mode1-equiv.py:34-37 (end of the module docstring :2-38)
Exit 0 on a match (or a valid spec), 1 on no match (per-command diagnostics on
stdout), 2 on anything else: a usage, spec, file or SKILL.md problem, or any
unexpected error in this script (message on stderr). Exit 1 therefore always
means "the model's commands did not compute the value", never a checker fault.
```

The checker has two dependencies on SKILL.md: the Mode 1 *text* (wrapper and program) and the evaluator's *behavior* (its output format `-> <value>`, its exit status and its speed). `reference()` validates the first and turns problems into `SetupError` → 2. Nothing validates the second, and `evaluate()` collapses all of its failures into `None`, a value the caller cannot tell apart from "the model's expression was wrong". So a SKILL.md edit that changes the print format turns every Mode 1 fixture into a model failure (E5), and `--check-spec`, the gate meant to catch "a broken fixture spec … before any paid run", passes it. The chain A10→A11→A19→A21→Claim 14 has one shape: each fix routed one more *enumerated* failure to exit 2, while the docstring kept claiming a total classification.

**Recommendation:** Validate the behavior dependency where the text dependency is validated. In `reference()`, run the extracted program on a fixed sample (for example `6 * 7`) and raise `SetupError` unless `evaluate()` returns `42.0`. `--check-spec` then catches E5 before a paid run, and per-command `None` can only come from the model's expression. The one remaining ambiguity is a timeout on a loaded host, so narrow the docstring to "exit 1: no command matched, given a reference evaluator that passed its self-test (a model expression that exceeds the 10 s limit counts as no match)". About 8 lines. The rubric row should record that the contract is now "self-tested dependency + narrowed claim", so that a sixth pass does not re-open it on a timeout.

#### 4. "One reader" is not yet true. Three lenient `fromjson?` readers remain outside the module, and one of them (`assert_subagents_min`) grades transcripts the strict reader rejects

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:250-263`; `test/skills/eval-helpers.bash:473-483`
**Move:** #3 module boundary (consumers re-deriving what the module owns)
**Confidence:** High (fact-check Claims 11 and 21, probe E3)
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/eval-helpers.bash:476-478 (excerpt starts inside assert_subagents_min, which begins :473; :479-483 compare n to min — read)
  n=$(jq -rR 'fromjson? | select(.type == "assistant" and .parent_tool_use_id == null)
       | .message.content[]? | select(.type == "tool_use" and .name == "Agent")
       | .name' "$t" | grep -c . || true)
```

The DD doc (`:175`) and log #56 say the generator and the eval checks "both read transcripts through it". Three readers do not:
- the report text (`generate-reports.bash:252`);
- `result_state` (`:256`);
- sub-agent counting (`eval-helpers.bash:476`), which also depends on a shape field, `parent_tool_use_id`, that the module does not define.

None of them is on the Bash deny-record path. The first two run before the strict check, which still voids, and the third is reached through `eval_fixture` only after the `.failed` gate. So this is a boundary leak, not a hole. It matters for convergence, though: each such reader is one more place where a future fact-check will find "the one reader skips X".

**Recommendation:** Add `def result:` (the last result event, or null) and `def subagent_dispatches:` (with the Finding 1 census, top-level `Agent` calls) to `transcript.jq`. Have `assert_subagents_min` call `transcript_checked` first, as its siblings do. The generator's report and `result_state` can then come from the same jq invocation as Finding 2's verdict.

#### 5. The reader's contract is restated in prose in six places, each as a universal claim the code does not implement. That multiplies the fact-check surface of every fix

**Severity:** Minor
**Location:** `test/skills/transcript.jq:1-19`; `docs/working/dd-arith-eval-bash-grant.md:175`; `docs/decisions/log.md:77`; `test/skills/eval-helpers.bash:387-391`; `test/skills/generate-reports.bash:31-33`; 272bc83's message
**Move:** #3 module boundary (the contract lives in consumers' prose, not at the module)
**Confidence:** High (fact-check Claims 1, 11, 16, 21 and 26)
**Legibility-target:** for-author

**Evidence (verbatim):**
```text
# docs/working/dd-arith-eval-bash-grant.md:175 (excerpt; the bullet continues through the end of the line — read)
It rejects any event of a shape it does not expect instead of skipping it.
```
```text
# docs/decisions/log.md:77 (excerpt from the row; the row continues — read)
It rejects unexpected event shapes rather than skipping them
```

Iteration 4's Finding 3 found the voiding rules restated four times, and 272bc83 fixed that for the generator's header. The same pattern then reappeared for the *reader's* contract. Every copy says "rejects unexpected shapes", which is universal, while the code implements "rejects unexpected shapes at these positions". Log #56's list of voiding conditions is also stale (Claim 1), and `eval-helpers.bash:77-79` describes an old `.failed` (Claim 16). Each copy is a separate place for the next pass to refute.

**Recommendation:** State the rule once, in `transcript.jq`'s header, in the as-built form (after Finding 1: "every `tool_use`/`tool_result` object anywhere is validated and counted; events are otherwise only required to be objects"). Everywhere else, write one clause and a pointer: "read through `test/skills/transcript.jq`; its header is the contract". Replace log #56's condition list with a pointer to the "Transcript checks" comment in `generate_one`, as the generator header already does.

#### 6. The test design mirrors the implementation's enumeration, so it cannot find the class. The shape table is the list of past findings, and the mutation check covers `problems` only

**Severity:** Informational
**Location:** `test/skills/malformed-transcripts.bash:15-17`; `test/generate-reports.bats:627-643`; `test/skills/mode1-equiv.bats:300-318`
**Move:** #8 extension points (a test that grows by one case per finding)
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim):**
```bash
# test/skills/malformed-transcripts.bash:15-17 (whole array)
MALFORMED_SHAPES=(array_wrapped string_content string_message nonobject_block
  denials_number list_tool_use_id object_id number_line surrogate deep
  numeric_command no_id tool_result_no_id)
```

The shared table is good. It holds both consumers to the same shapes, and it found the `catch` binding bug on its first run. But the table is the finding history, and the reader was written to reject exactly that history. So the table passes by construction and says nothing about completeness. Claim 32's mutation (`problems` stubbed to `[]`) shows that the table depends on `problems`. No test depends on `tool_uses`, which is where the defect is. A property test that quantifies over *positions*, not shapes, would have found every Claim 26/29 case on its first run.

**Recommendation:** Promote `arch-9c73ae4-insertion-fuzz.sh`'s loop to a bats test in `test/generate-reports.bats`, about 30 lines. For every array/object path in a good transcript (`jq 'paths(type == "array" or type == "object")'`), insert an undenied Bash call and assert that the generator voids the run. Add a variant for `assert_no_tool_called Bash`. Keep the 13-shape table for the parse and validation cases.

#### 7. The census has three costs to accept knowingly: false voids on tool_use-shaped objects that are not calls, a constant-factor slowdown, and no real transcript to validate against

**Severity:** Informational
**Location:** proposed change to `test/skills/transcript.jq`; `docs/reviews/execution-logs/arch-9c73ae4-census-probe.txt`
**Move:** #8 (what the extension point admits)
**Confidence:** Medium (the cost figures are executed; false-void reachability is inferred from the CLI format, which I cannot run here)
**Legibility-target:** for-author

**Evidence (verbatim):**
```text
# docs/reviews/execution-logs/arch-9c73ae4-census-probe.txt (last 5 lines; the per-shape results precede them)
size: 690361 bytes
HEAD: counts 0 0 0 0
HEAD ms: 243
CENSUS: counts undenied=0 orphans=0
CENSUS ms: 2008
```

Three costs:
- **False voids.** `..` counts any object with `"type":"tool_use"`. That includes one embedded in a model-chosen `input` (the insertion probe's `…,"input"` and `tool_input` paths) and any CLI-embedded copy of a message. Examples are a `tool_use_result` payload for an Agent call, or partial-message events if `--include-partial-messages` were ever added; the unique-id rule would also flag those duplicates. Every one of these voids a run and none passes one, so the direction is safe.
- **Slowdown.** About 8× on a synthetic 690 KB file with 50-deep nesting (0.24 s → 2.0 s, with the prototype calling `_calls` several times). That is negligible beside a model run.
- **No ground truth.** The accepted shapes cite "13 real runs", which are not in the repo (Claim 27a). So neither HEAD's strict validator nor the census can be checked against the real CLI here, and every reviewer has had to argue from synthetic shapes. That is one reason this loop has not converged.

**Recommendation:** Check in one real deny-record transcript and one plain `FIXTURE_TRANSCRIPT=1` transcript as golden fixtures (redacted if needed), and add a test that both pass the reader with zero problems. Refresh them when `claude_code_version` changes. If a real transcript does embed tool_use copies, restrict the census to "anywhere except under keys the CLI documents as copies", and name those keys in the header.

## Convergence diagnosis

**The re-fire history, as one class.**

| Iteration | Finding | Fix | Why the fix left a gap |
|---|---|---|---|
| 1-3 | A10, A11, A19 (mode1-equiv exit contract) | Route one more *named* failure (bad file, `nan`, bad `input`) to `SetupError` → 2 | The docstring claimed a total classification. Each fix enumerated one more member |
| 4 | Claim 13, A21, R2 (tracebacks; skipped shapes pass both checkers) | One shared reader; a strict validator; a catch-all; the checker stops reading transcripts | The checker half is closed by construction (catch-all + no transcript input). The reader half re-enumerated: strict at chosen *positions*, accept-all elsewhere, and it counts at a *narrower* set of positions than it validates |
| 5 (this) | Claims 26/29 (positions), 22b (positional record), 14 (exit contract) | — | See below |

**The common cause.** In each instance the *claim* is universally quantified over an open input domain: "every Bash call", "an unexpected shape is never skipped", "exit 1 always means the model", "removed only after every check". The *implementation* is a list of cases: positions, shapes, exception types, fields. The *test* is a table of the same cases. A reviewer who probes outside the list will always find a counterexample, and a fix that adds the counterexample to the list re-arms the next pass. Iteration 4 diagnosed this correctly for the checker, and its fix (a catch-all) closed that half by construction: no probe this pass found a traceback. But the reader re-created the pattern one level down. "Strict" was implemented as a list of validated positions, and "counted" as a different list.

The three remaining gaps each have a by-construction fix, where the implementation's quantifier matches the claim's:

| Claim | Quantifier the code needs | By-construction fix | Size |
|---|---|---|---|
| every Bash call is counted or voids | over **all objects** in the stream | one selector, `.. \| objects \| select(.type == "tool_use")`, feeding both validation and counting, plus unique ids (Finding 1) | ~20-25 lines of jq; tool_use/tool_result definitions replaced; 13-shape table unchanged |
| the marker is removed only if every check ran | over **all checks**, with no lossy hop between computing and judging | `deny_record_failures` in jq; empty array ⇔ pass; bash only joins and writes (Finding 2) | ~15 lines of jq, −20 lines of bash, 1 line in eval-helpers |
| exit 1 is a model result | over **all failures of the evaluator dependency** | self-test the evaluator in `reference()`; narrow the timeout clause (Finding 3) | ~8 lines of Python + 1 test |
| (tests) | over **all positions** | insertion property test (Finding 6) | ~30 lines of bats |

**Alternatives considered for the reader.**
- *(a) Keep enumerating shapes.* This is the status quo, and it will re-fire; the insertion probe already lists 20 more positions.
- *(b) A closed-world schema.* Reject unknown event types and unknown keys at every level. This does close the class, but it voids on every benign CLI addition (new `system` subtypes, rate-limit events, new metadata fields), and it would need a maintained schema of the whole stream. That is a rethink, and a brittle one.
- *(c) The census.* This closes the class for the property that matters (calls and results) and stays tolerant of everything else.
- *(d) (c) plus a positional allowlist.* This adds "tool_use may appear only in assistant content" as a *problem*, not a skip. It is cheap to add to (c), and it turns the census's false-void cases into named diagnostics.

I recommend (c), and (d) if the golden transcripts from Finding 7 confirm that the CLI only emits calls there.

**Estimate: a small change, not a rethink.** The module boundary 272bc83 drew is the right one. Both consumers already go through it, and all of Findings 1-4 are edits *inside* it or deletions in its consumers. The total is roughly 60-80 changed lines plus one property test, and none of the settled decisions is disturbed. The one real unknown is empirical, not structural: whether the real CLI emits tool_use-shaped copies that the census would falsely void. One golden transcript settles it (Finding 7). If the author wants to stop the loop here instead, the honest alternative is to narrow the six prose copies to the as-built rule (Finding 5): "assistant/user/result events are validated; calls are read from assistant content only". Then record the positional gap as an accepted, CLI-unobserved residual in the rubric, next to C29.

## What Looks Good

- **Dependency direction is now correct and minimal.** One semantics module, two consumers, and no consumer-to-consumer dependency. mode1-equiv.py's input narrowed from "a transcript" to "a JSON array of strings", so it no longer knows the stream format at all. Iteration 4's Finding 1 steps 1-5 are all implemented in the recommended order: positive marker, duplicate removed, catch-all, docstring narrowed on transcripts, table test.
- **The `.failed` marker is fail-closed by construction** (write first, clear last). That removes the interrupt window iteration 4 found, and makes the marker's absence mean "checked" (with Finding 2's one exception).
- **The shared test table** holds both consumers to the same inputs, each next to a passing control. The first run found a real jq `catch`-binding bug, which is exactly what shared fixtures are for.
- **Module resolution via `EVAL_HELPERS_DIR`** is independent of `BATS_TEST_DIRNAME`, so repointed test trees still find the module (Claim 17).
- **The voiding conditions are listed once** in `generate_one`, and the generator header points at that list, which fixes iteration 4's Finding 3 for the code (Finding 5 covers the prose that did not follow).
- **The canaries cross-check independent parts of the stream** (denials and tool_results against calls). That is the reason Finding 1's gap is partly backstopped under deny-record, and it stays valuable after the census.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The reader validates one set of positions and counts another, so "every call counted or voided" is not established. 20/22 insertion variants escape. Fix: one `..` selector for both, plus unique ids | Structural | `transcript.jq:35-79` | High (mechanism) / Low (exposure) |
| 2 | Deny-record pass condition carried as a positional record with a free-text field, and judged twice with opposite empty semantics (22b fail-open). Fix: `deny_record_failures` in the module | Coupling | `generate-reports.bash:285-318`; `eval-helpers.bash:524-530` | High |
| 3 | mode1-equiv maps failures of the unvalidated evaluator dependency to exit 1 (Claim 14). Fix: evaluator self-test in `reference()`; narrow the timeout clause | Coupling | `mode1-equiv.py:34-37, 76-88, 124-137` | High |
| 4 | Three lenient readers remain outside the module; `assert_subagents_min` grades transcripts the reader rejects | Minor | `generate-reports.bash:250-263`; `eval-helpers.bash:473-483` | High |
| 5 | The reader's contract is restated in six prose places as a universal; log #56 is stale | Minor | `transcript.jq:1-19`; DD `:175`; `log.md:77`; `eval-helpers.bash:387-391` | High |
| 6 | The shape table equals the finding history, and the mutation check covers `problems` only. Add an insertion property test | Informational | `malformed-transcripts.bash:15-17` | High |
| 7 | Census costs: fail-closed false voids, ~8× jq time, no golden transcript to validate either reader | Informational | proposed `transcript.jq`; census probe | Medium |

## Overall Assessment

272bc83 improves the structure substantially. It creates the module boundary the design needed, makes the dependency direction correct, turns the marker fail-closed, and closes the checker's exit-contract crash class by construction. No structural regression was found.

The single most important concern is Finding 1. Inside the new module, "validated" and "counted" are still two selectors over different positions. So the property every consumer relies on is asserted in six places but implemented nowhere, and that is why this class has now fired five times. Findings 2 and 3 are the same pattern at smaller scale: a universal claim, and an implementation that lists cases or drops a field. All three are fixable in place, inside the module 272bc83 created, by making each implementation quantify over the same domain as its claim. That is roughly 60-80 lines plus one property test, not a restructuring.

Exposure is low. No escape shape has been seen from the real CLI, the version-newline case needs a CLI-written field, and the orphan canary backstops a call that actually ran under deny-record. So this does not block a local merge, provided the rubric records the residual honestly (Finding 5's alternative) if the census is deferred.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** Yes. The critique is saved at `docs/reviews/architecture-review-2026-09-25-q062-q063-iter5.md`, with `Commit: 9c73ae4` at the top, and nothing is committed. Every finding carries Severity, Location, verbatim Evidence (partial excerpts carry a truncation marker naming the remainder), Confidence and Legibility-target. The requested convergence diagnosis is its own section. It covers why each fix left a gap, the by-construction design (the census via `..`, i.e. the brief's second suggestion, with the allowlist variant compared as options (b) and (d)), and a size estimate: small, roughly 60-80 lines plus one test.
- **New evidence:** `docs/reviews/execution-logs/arch-9c73ae4-insertion-fuzz.{sh,txt}` (HEAD 20/22 escapes vs census 0/22) and `arch-9c73ae4-census-probe.{sh,txt}` (the census rejects all 13 table shapes like HEAD, voids all 7 fact-check escape shapes, passes the benign shapes; cost 0.24 s → 2.0 s). Both scripts pass `shellcheck -x -e SC1091 -s bash -S warning`, and the census is a prototype for feasibility, not a patch.
- **Caveat on the insertion probe:** the five rename variants are caught by the census's duplicate-id rule (the renamed copy carries g1) as well as by x1 being undenied. So they show that the census catches the variant, not which rule fired first.
- **Out of scope:** install.sh / Q-062 (no commits since 5bdee46; iteration 4's review stands); the settled items listed at the top; performance of the three-pass `tool_inputs_checked` (C33, a performance-critic concern).
- **Escalate:**
  - To the orchestrator/user: the decision between (i) landing Findings 1-3 and 6 (small, closes the class by construction) and (ii) narrowing the prose and recording the positional gap as an accepted residual (Finding 5's alternative). Either one ends the loop honestly. Leaving the prose as it is will re-fire.
  - To security-reviewer: Finding 1's Security implication (false voids as the accepted direction on `B3`/`B4`).
- **Decisions:** None made. I wrote two probe scripts and their logs, and changed nothing else.
