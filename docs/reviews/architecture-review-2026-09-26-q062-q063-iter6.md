Commit: 299727c

# Architecture Review: skill-fixtures (Q-063 [1]), iteration 6 of 6 (terminal pass on the census fix)

**Scope:** `git diff main...HEAD` on skill-fixtures (HEAD 299727c), weighted to `git show b22a026`. Code under review: `test/skills/transcript.jq`, `test/skills/generate-reports.bash` (`generate_one`), `test/skills/eval-helpers.bash` (the transcript helpers, `assert_subagents_min`, `assert_mode1_equiv`), and the shared test inputs in `test/skills/malformed-transcripts.bash`. Prose that restates the module's contract (DD "As built", log #56, rubric A29) is reviewed only as a copy of that contract. install.sh / Q-062 has not changed since iteration 4 and is not reviewed again.
**Date:** 2026-09-26
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 299727c, 38 claims). I rely on its Claims 1, 6, 7, 19, 23, 24 and 25b and do not re-verify them. I wrote two new probes. Both are in `docs/reviews/execution-logs/` and pass `shellcheck -x -e SC1091 -s bash -S warning`:
- `arch-299727c-marker-property.{sh,txt}` (started 2026-09-26T09:07:05Z, jq-1.6, exit 0). It runs HEAD's module and two patched copies (fixA and fixB, defined in Finding 1 and Finding 2) against three things: an insertion property extended to vary the module's own key vocabulary, a type-mutation property, and the 13-shape table.
- `arch-299727c-fix-suites.{sh,txt}` (started 09:10:34Z, exit 0). It runs the four transcript suites in a `git archive HEAD` copy with fixB applied.

**Scope check.** Three trigger categories apply:
- *Public API:* `transcript.jq`'s definitions are imported by two consumers. `tool_uses` and `tool_results` change meaning, and `transcript_failures`, `deny_record_failures`, `print_verdict` and `verdict_end` are new.
- *Data model:* the verdict is now a contract of one-line strings ending in a sentinel.
- *Cross-cutting:* the run-voiding pipeline is shared by the generator and the eval checks.

**Trust-boundary cross-reference:** active. The most recent security review is `docs/reviews/security-review-2026-09-26-q062-q063-iter6.md` (Commit: `299727c`, the commit under review), written in parallel with this pass. Finding 1 sits on its `B1` ([claude -p stdout] → [transcript.jq events + problems + census] → [verdict failure lines]). The readers that do not honor the marker are its `B3` ([events read OUTSIDE the census: init, denials, last result] → [no validation] → …).

## Dependency Map

```
generate-reports.bash (generate_one) ──┐           ┌── report text / result_state (last result event)
                                        ├─ import ─► transcript.jq ── events ─► problems ─► transcript_failures ─► deny_record_failures ─► print_verdict
eval-helpers.bash (transcript_jq,      ─┘           └── tool_uses / tool_results (census), init, denials
  transcript_verdict, tool_inputs_checked,
  assert_subagents_min, assert_mode1_equiv) ──► mode1-equiv.py (a JSON array of command strings only)

test inputs: malformed-transcripts.bash (13-shape table + write_insertion_variants)
             ◄── test/generate-reports.bats, test/skills/mode1-equiv.bats
```

Dependencies point one way: the consumers depend on the module, and the module depends on nothing. b22a026 moved the verdict into the module, which is iteration 5's Finding 2. The consumers now only enforce the sentinel and join or print the lines. mode1-equiv.py no longer knows the stream format. No cycles.

Inside the module, every reader starts from `events`. The question for this pass is which readers see which events. Before b22a026 that was *positions*. At HEAD it is the `__text` marker. The census and `_event_problems` exclude an event that has the marker. `_placed_*`, `init`, `denials` and the generator's report and result reads include it.

## Findings

#### 1. The census is universal over every event *except those a data-controlled key excludes*. `__text` is an in-band "ignore me" marker, and only the census and the validator honor it; seven other readers do not. This is the R3 class once more, moved from position to vocabulary (Claim 24)

**Severity:** Structural
**Location:** `test/skills/transcript.jq:45-46, 56-57, 70` (and the readers that do not exclude the marker: `:62-65`, `:111`, `:114-115`; `generate-reports.bash:252-261`)
**Move:** 7 (coupling surface: the reader's metadata and the CLI's data share one key namespace), 3 (module boundary: `B1`)
**Confidence:** High on the mechanism. Low on exposure: a real `claude -p` event carries no top-level `__text`.
**Legibility-target:** for-author

The module represents a line it chose to ignore as a data-shaped object, and then filters the census with a predicate over data keys:

```jq
# test/skills/transcript.jq:45-46 (whole definition)
def events: [inputs | select(test("\\S")) | . as $line | (try fromjson catch
  (if ($line | test("[\\[{]")) then {"__unparsed": $line} else {"__text": $line} end))];
```

```jq
# test/skills/transcript.jq:56-57 (whole definitions)
def tool_uses: [.[] | objects | select(has("__text") | not) | .. | objects | select(.type == "tool_use")];
def tool_results: [.[] | objects | select(has("__text") | not) | .. | objects | select(.type == "tool_result")];
```

```jq
# test/skills/transcript.jq:67-70 (excerpt; _event_problems continues to :94 — read)
def _event_problems:
  if type != "object" then "a line is not a JSON object"
  elif has("__unparsed") then "a line containing JSON-like text does not parse"
  elif has("__text") then empty
```

A parsed line can carry a `__text` key as easily as the wrapper can, so any event can opt itself out of both the census and all event validation. The other readers do not honor the marker:

```jq
# test/skills/transcript.jq:111 and :114-115 (whole definitions)
def init: [.[] | objects | select(.type == "system" and .subtype == "init")] | first;
def denials: [.[] | objects | select(.type == "result") | .permission_denials | arrays | .[] | objects
  | {tool_name, tool_use_id}];
```

So a marked result event still supplies denials, but its calls are not counted and its shape is not validated. The marker was meant to mark "a line with no braces". Yet it is a predicate that the census, the validator, the placement counts, `init`, `denials` and the generator's result reads each have to remember or forget, one by one. That is the "list of cases" shape that iteration 5 diagnosed. The census closed it for *positions*. It recurs here for *the module's own vocabulary*.

The probe (`arch-299727c-marker-property.txt`) shows this. When the insertion property also adds a key from the module's `has(...)` vocabulary, HEAD has **6 escapes in 100 variants**, and in **23 variants the census did not grow by one**. The escapes are an undenied call in the init line and in the result line, anywhere, once the event root carries `__text`. The fact-check's end-to-end probe already shows the same shape passing the generator, `no_tool_called` and `mode1_equiv` (Claim 24).

The marker is also unnecessary. A real ignored line has no `{` or `[` by construction, so `{"__text": "<line>"}` contains no object for `..` to find. Excluding it from the census changes nothing for real ignored lines. It only changes what happens for data that imitates it.

**Recommendation:** Represent ignored lines out of band by not representing them at all. In `events`, replace `else {"__text": $line} end` with `else empty end`. Then delete `select(has("__text") | not) | ` from `:56-57` and delete the `elif has("__text") then empty` line at `:70`. That is three edits, and no reader then has a marker to remember. `__unparsed` can stay in band, because it only makes reading *stricter*: a real event with that key is voided, which is a false void and the fail-safe direction. Record the rule in the header: **"an in-band marker may only add a problem, never remove one."**

Measured as fixA:
- The fact-check's Claim 24 line now fails with 3 problems.
- 0 escapes in the 100 vocabulary-varied variants.
- The table: 13/13 still fail.
- The good and warning-line controls pass.
- The four suites pass in an archive copy (46/46, 31/31, 7/7, 6/6, together with Finding 2's edit; `arch-299727c-fix-suites.txt`).

**Security implication:** none from relocation. The fix tightens `B1` and shrinks what reaches `B3` unvalidated (`docs/reviews/security-review-2026-09-26-q062-q063-iter6.md`, Commit `299727c`). It moves neither boundary. The fix does not validate `B3`'s readers: they still read events outside the census, and after the fix those events are at least validated by `_event_problems`.

#### 2. Two predicates over the same `type` field disagree. The census matches `"tool_use"` exactly, and the allowlist that is supposed to catch a *renamed* call type matches substrings. The allowlist has no test at all (Claim 25b)

**Severity:** Coupling
**Location:** `test/skills/transcript.jq:72, 81-82`; header `:26-30, 36-37`
**Move:** 7 (coupling between the two halves of one guarantee), 8
**Confidence:** High
**Legibility-target:** for-author

```jq
# test/skills/transcript.jq:81-82 (excerpt inside _event_problems, :67-94 — read; :72 uses the same idiom for event types)
        elif ($et == "assistant" and ([.type] | inside(["text", "thinking", "redacted_thinking", "tool_use"]) | not))
          or ($et == "user" and ([.type] | inside(["tool_result", "text"]) | not)) then
```

The census and the allowlist are complementary halves of one guarantee. A call in the CLI's current format is found because its type equals `"tool_use"`. A call in a *future* format, with the block type renamed, is voided because its type is not on the list. That second half is the premise of the accepted residual: "a CLI format change voids runs until the module is updated (fail-safe)" (DD `:177`). With `inside/1`, the complement has holes: `""`, `"tool"`, `"use"`, `"_use"`, `"a"` and so on. The fact-check shows a `"tool"`-typed Bash call passing end to end.

The type-mutation property in my probe draws its mutants mechanically from the allowlist literals (all prefixes and suffixes, upper case, a trailing space). HEAD accepts **293 of 1036** mutated events or blocks with no problem. With the allowlists as `IN(...)` (fixB), it accepts **0**.

No bats test sends a near-miss type, and none sends any unknown type (`rg -i unknown` over the transcript suites finds only an unrelated runner-mode test). So "Anything else is a problem" was a universal claim with no test cases at all.

**Recommendation:** Replace `[.type] | inside([...])` with `.type | IN(...)` at `:72` and `:81-82`. jq 1.6 has `IN`: `"sys" | IN("system","assistant")` gives `false`. Add Finding 3's type-mutation property as the test. This does not touch the settled residual. It makes the residual's premise true.

#### 3. The insertion property varies one dimension (containers) and holds everything else fixed, so it could not see Finding 1. Restate it as *census context-independence* and generate inputs from the module's own vocabulary

**Severity:** Minor
**Location:** `test/skills/malformed-transcripts.bash:57-70`; `test/generate-reports.bats:702-724`; `test/skills/mode1-equiv.bats:371-392`
**Move:** 8 (the test is a list of the cases the last escape used)
**Confidence:** High
**Legibility-target:** for-author

```jq
# test/skills/malformed-transcripts.bash:65-67 (excerpt from the jq program at :60-68; :68 joins the lines and :69 writes the files — read)
    | ([$ev | paths(type == "object" or type == "array")] + [[]])[] as $p
    | ($ev | getpath($p)) as $v
    | ($ev | setpath($p; if ($v | type) == "array" then $v + [$call] else $v + {"x_inserted": $call} end)) as $new
```

The key name is fixed (`x_inserted`), no sibling key is ever added, and no `type` string is ever changed. That is a table with one row per container, which is the "table-of-cases tests" half of iteration 5's diagnosis, one level up. The property as stated ("the census must find every one") is about the verdict, and the verdict only checks a few things downstream. A census that silently drops an event can still be caught *by accident*: for example, the assistant line with `__text` is voided by the placement mismatch. So the end-to-end form under-reports census defects. In the probe, 23 census defects produced only 6 verdict escapes.

**Recommendation:** Answering (b): yes, vary keys and markers, and state the property on the census itself as well as on the verdict.

- **P1, census context-independence (the core statement).** For every accepted transcript T, and for every T′ made by inserting one tool_use object at any container of any event, *with any set of extra keys added to any object on the path to it*: `t::tool_uses(T′) = t::tool_uses(T) + 1`, and the deny-record verdict of T′ fails. Equivalently, as a differential oracle: for every T′ whose lines all parse, `t::tool_uses | length` equals an independent walk (`python3 -c` over `json.loads` of each line, counting dicts whose `type == "tool_use"`). The oracle has no markers, so *any* pre-census filter shows up as a mismatch, whatever its name. That covers Claim 24 without having to guess the marker.
- **Inputs.** Draw the extra keys from the module's own source (`grep -o 'has("[^"]*")' transcript.jq`), as the probe does, so a marker added later is covered with no edit to the test. Draw type mutants from the allowlist literals (P2: every event or block type outside the allowlist is a problem). Skip a key the target object already has: in the probe, the 3 fixA "census not +1" rows are this artifact, where `permission_denials: "x"` overwrote the array that held the inserted call.
- **Size.** About 30 lines of bats on top of `write_insertion_variants`. The probe script is a working prototype.

#### 4. "The verdict is decided in one place" has one rule outside the module: the result-event requirement. The generator voids an init-only transcript, and the eval checks accept it (Claim 7)

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:256-266`; `test/skills/transcript.jq:124-126`
**Move:** 2 (responsibility boundary)
**Confidence:** High
**Legibility-target:** for-author

```bash
# test/skills/generate-reports.bash:256-266 (the `if [ -z "$failure" ]` block, whole; generate_one continues to :313 — read)
    if [ -z "$failure" ]; then
      local result_state
      result_state=$(jq -rR -n -L "$SCRIPT_DIR" 'import "transcript" as t;
        t::events | [.[] | objects | select(.type == "result")] | last
        | if . == null then "none" elif .is_error == true then "error" else "ok" end' \
        "$transcript_path" 2>/dev/null)
      case "$result_state" in
        ok) ;;
        error) failure="the result event is an error" ;;
        *) failure="no result event in the stream" ;;
      esac
    fi
```

`transcript_failures` requires an init event but not a result event. So `transcript_checked` and `assert_no_tool_called` pass a transcript that has only an init event, while the generator voids the same transcript. End to end this is safe, because eval_fixture fails on `.failed`. But the eval checks and the generator no longer share a verdict, which is the property b22a026's header asserts. The same split applies to the misspelled-tool guard, which reads `tools` only when it is an array (Claim 7).

**Recommendation:** Add `def result: [.[] | objects | select(.type == "result")] | last;` to the module. Add "no result event" (and "the result event is an error", if eval-time grading should also refuse error runs) to `transcript_failures`. The generator then keeps only the rc check. If this is deferred, narrow the header's "in one place" to "transcript shape and calls, in one place; run outcome in the generator".

#### 5. The absolutes are restated in five prose places, and log #56's voiding list is still the pre-iteration-4 list (Claims 1, 6)

**Severity:** Informational
**Location:** `docs/decisions/log.md:77`; `docs/working/dd-arith-eval-bash-grant.md:175, 177`; rubric A29
**Move:** 3
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```
# docs/decisions/log.md:77 (excerpt; the row continues — read)
… and it voids a run when a Bash call is missing from `permission_denials` (tripwire), when a denial names …
```

With Findings 1 and 2 applied, the census and allowlist absolutes become true as written, so the DD doc and the module header need no edit. Log #56's condition list is the only copy that is stale. Iteration 5's Finding 5 recommended replacing it with a pointer, and that edit was not made. A29's "Fixed" should be re-marked once Findings 1 and 2 land, or should record them as open.

**Recommendation:** Replace log #56's list with "voiding rules: `transcript_failures` / `deny_record_failures` in `test/skills/transcript.jq`".

## Convergence verdict

**Did b22a026 change the shape?** Yes, along the dimension that kept firing. At HEAD:
- The call list is one expression that quantifies over all objects (`..`).
- Validation, counting and the eval checks read that same list.
- Placement is checked as a count equality, not by a separate selector.
- The verdict is computed once, with a completeness sentinel.
- The tests include a property over every container, not only the table.

The fact-check's probes found no escape by position, depth, duplicate key, NUL byte, lookalike type or scale (Claim 24's list). Iteration 5's claim and code now share one quantifier.

**Is the class closed by construction, apart from Claims 24 and 25b?** For calls in the CLI's format, yes, with one exception, and that exception *is* Claim 24. The census's domain is "every event", minus the events that carry a key the module chose as a marker. That is a list-of-cases *exclusion* sitting in front of the universal quantifier. The tests could not see it because they vary positions and not vocabulary. So the diagnosis from iteration 5 ("universal claim, list-of-cases code, table-of-cases tests") recurs in a smaller form: *universal quantifier, data-controlled pre-filter, single-dimension property*.

Claim 25b is the same pattern on the other half of the guarantee. It does not hide a `tool_use`-typed call. It does make the "renamed type voids" half, and with it the accepted residual's premise, a substring list with no tests.

I found no third instance:
- The remaining positional readers (`init`, `denials`, the last result event, `assert_subagents_min`'s placed Agent count) all miss in the fail-closed direction. A missed denial trips the tripwire. A missed init is reported. A missed result voids the run. A missed Agent call lowers a minimum.
- Once `problems` is empty, census equals placed, so the positional Agent count is exact (Claim 19).

**Minimal structural fix for Claim 24.** Do not represent ignored lines at all (fixA, three edits), so that no data value can mark itself ignored. The alternatives:
- Reserving the key (void any parsed object that has `__text`) also closes the escape. But it keeps an in-band namespace that every future reader must remember, so it re-arms the class.
- Wrapping every line (`{kind, value}`) is fully out of band, but it changes every consumer's filter, including `transcript_jq` callers in eval-helpers. That is a larger diff for no extra safety over dropping.

With fixB (fixA plus `IN`), the extended property and the type property both give 0 escapes and 0 accepted mutants. The table still fails 13/13, and the suites pass unchanged. After that, the only remaining limits are the ones accepted in the DD doc: concealed breaches, and the absence of a real deny-record transcript in the repo (Claim 28).

## What Looks Good

- **The census is the right design**, and it is implemented as a single expression. It is what iteration 5 recommended, and the one defect in it is a filter placed in front of it, not the recursion itself.
- **The verdict moved into the module.** Consumers only enforce the sentinel and join or print. That removed iteration 5's positional record and its opposite empty-field semantics, and `print_verdict` computes the array before emitting, so a jq error cannot print a partial list followed by the sentinel (Claim 29).
- **The fail-closed marker plus the sentinel** form a consistent rule: absence of evidence voids the run. The R4 tests exercise both halves.
- **`deny_record_failures` runs whenever the stream is well formed, even with no init event.** So a run that already failed still reports an executed call.
- **Every remaining positional reader misses in the fail-closed direction** (see the convergence verdict). This is worth stating in the header as a design rule.
- **A property test exists**, is shared by the generator and the eval checks, and its mutation check (12/16 and 24 escapes against the positional reader) shows it can fail. Finding 3 asks it to vary one more dimension. It does not ask for a new mechanism.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `__text` is an in-band "ignore" marker that data can carry. It filters the census and validation; 7 other readers do not honor it. 6/100 vocabulary-varied insertions escape at HEAD, 0 with fixA (drop ignored lines; 3 edits) | Structural | `transcript.jq:45-46,56-57,70` | High (mechanism) / Low (exposure) |
| 2 | Census `==` versus allowlist `inside` (substring) over the same `type` field. 293/1036 type mutants accepted at HEAD, 0 with `IN`. No test of the allowlist | Coupling | `transcript.jq:72,81-82` | High |
| 3 | The insertion property varies containers only. Restate it as census context-independence or a differential oracle, with keys and types drawn from the module source | Minor | `malformed-transcripts.bash:57-70` | High |
| 4 | The result-event rule lives in the generator only. The eval checks accept an init-only transcript | Minor | `generate-reports.bash:256-266` | High |
| 5 | Log #56's voiding list is still stale. A29's "absolutes match" is premature until Findings 1 and 2 land | Informational | `log.md:77` | High |

## Overall Assessment

b22a026 is a real structural improvement. The census, the in-module verdict and the sentinel close the positional class that fired five times, and nothing in this pass shows a regression. The class is not quite closed by construction. The census is guarded by a data-controlled pre-filter (the `__text` marker), and the allowlist that covers renamed types matches substrings. Both are one-line-scale defects in the same "list of cases in front of a universal" shape, and both are invisible to a property that varies only containers.

The single most important concern is Finding 1. It is fixable in place by *deleting* the marker: about three edits, with the suites passing unchanged. Together with Finding 2's `IN`, the module's header claims become true as written. Exposure is low: no real CLI event carries `__text`, and no known CLI type is a substring of an allowed one. So this does not block a local merge if the user prefers to record 24/25b as residuals. But the fix is smaller than the prose needed to record them honestly.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** Yes. The critique is saved at `docs/reviews/architecture-review-2026-09-26-q062-q063-iter6.md` with `Commit: 299727c` at the top, and nothing is committed. Every finding has Severity, Location, verbatim Evidence (partial excerpts name their remainder), Confidence and Legibility-target.
  - (a) The convergence verdict and the minimal fix for Claim 24 are in "Convergence verdict" and Finding 1.
  - (b) Whether the property test should also vary keys and markers, and how to state it, is Finding 3.
- **New evidence:** `arch-299727c-marker-property.{sh,txt}`. HEAD has 6/100 escapes and 23 census-not-+1 rows. fixA and fixB have 0 escapes. The allowlist type mutants are accepted 293/1036 at HEAD and fixA, and 0/1036 at fixB. The table fails 13/13 in all three modules, and the controls pass. `arch-299727c-fix-suites.{sh,txt}` shows the four suites passing with fixB in an archive copy. Both scripts pass the shellcheck gate. Patched modules exist only in mktemp copies, and the working tree is untouched apart from these four log files and this report.
- **Out of scope:** install.sh / Q-062 (unchanged). The settled rows C8, C13, C14, C24, C35 and C37-C39, and the accepted residual, were not re-litigated. Finding 2 addresses only the residual's factual premise. No `claude` or network command was run.
- **Escalate:** a decision for the user at this terminal pass:
  - (i) Land fixB (about 6 lines of jq) plus Finding 3's property (about 30 lines of bats). This closes the class by construction as far as these probes can tell.
  - (ii) Record Claims 24 and 25b as open residuals, and re-mark A29.
  Either ends the loop honestly. Leaving A29 "Fixed" does not.
