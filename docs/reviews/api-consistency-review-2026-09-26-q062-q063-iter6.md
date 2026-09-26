Commit: 299727c

# API Consistency Review: skill-fixtures, fix b22a026 (iteration 6 of 6, terminal pass)

**Scope:** `git diff main...HEAD` on `skill-fixtures`, focused on `git show b22a026`. Surfaces: the public and `_`-private defs in `test/skills/transcript.jq`; the verdict string vocabulary that `generate-reports.bash` and `eval-helpers.bash` share; the new and changed eval-helpers functions and messages; the `test/skills/malformed-transcripts.bash` helper interface.
**Date:** 2026-09-26 (probes ran 2026-09-26T09:07Z UTC, jq 1.6)
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 299727c, 38 claims). Its executed verdicts are cited by claim number and not re-verified here.
**Own probes:** `docs/reviews/execution-logs/acr-299727c-probes.sh` (passes `shellcheck -x -e SC1091 -s bash -S warning`) → `acr-299727c-probes.txt`. No `claude` or network commands were run.

Settled items are not re-raised: the override log (C4, C5, C9, C6, trap RETURN, `--tools` variadic, `RUNNER_ALLOWED_TOOLS` naming), and the open-by-choice rows C13, C24, C34 and C35. Where a finding overlaps a rubric row that is marked Fixed, it says so and covers only what remains at 299727c. This is the terminal pass, so the Summary Table lists the full remaining inventory, including items carried over from iteration 5.

---

## Baseline Conventions

- **Module interface** (`test/skills/transcript.jq`, the only jq module in the repo). Public defs are bare nouns: arrays are plural (`events`, `tool_uses`, `tool_results`, `problems`, `denials`) and the nullable single value is singular (`init`). Private defs carry a leading `_`. Consumers import the module one way: `jq -rR -n -L <dir> 'import "transcript" as t; t::events | …'`.
- **Verdict protocol** (new in b22a026). A verdict def returns an array of one-line failure strings, where empty means a pass. `print_verdict` prints the strings and then the sentinel. Callers must see the sentinel as the last line (`transcript.jq:120-123`).
- **Failure labels.** Earlier rounds settled that one condition gets one greppable label (A24: "`Bash canary:` vs `Bash parser canary:` (grepping one misses the other)"). They also settled that a label names the condition that fired (A17), and that an executed call must never be hidden behind an earlier failure (C10). Run-level states are plain lower-case sentences with no prefix ("claude exited N", "generation did not finish", "no result event in the stream").
- **Eval helper names** (`test/skills/eval-helpers.bash`). Graders are `assert_<noun>` / `assert_no_<noun>` and take positional args. Plumbing helpers are `<noun>_<noun>` (`transcript_jq`, `transcript_tool_inputs`, `eval_transcript_path`, `field_values`). The only `_checked` name before 272bc83 was `tool_inputs_checked`, which prints validated data.
- **Test helpers.** Functions are verb_noun (`make_skill`, `stub_transcript`, `write_malformed_transcripts`) and shared tables are UPPER_SNAKE (`MALFORMED_SHAPES`, `KEY_CHECK`). Where a helper takes a destination directory, the destination comes first: `fixture_base <dest> <fixture-dir>` (`generate-reports.bash:50`) and `write_malformed_transcripts <dir> <good-bash-command>` (`malformed-transcripts.bash:7`).

---

## Name-Pattern Audit

| New / changed name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `tool_results` (was `tool_result_ids`) | jq def | `tool_uses`, `denials` | `test/skills/transcript.jq:56,114` | Consistent. It now returns objects like its siblings, which closes iteration-5 #10. |
| `transcript_failures`, `deny_record_failures` | jq def | `problems`; the mode name `FIXTURE_BASH=deny-record` | `test/skills/transcript.jq:108`; `test/skills/generate-reports.bash:34` | Consistent (plural noun for an array of strings; the second name matches the mode). Minor stutter: `t::transcript_failures` inside a module imported as `t` from `transcript`. |
| `print_verdict` | jq def | `_one_line`; hooks' `get_part_value`, `extract_commands` | `test/skills/transcript.jq:52`; `hooks/auto-approve-allowed-commands.sh:337-384` | Consistent. It is the only verb-first public def, and it is also the only one that emits lines rather than returning a value. |
| `verdict_end` | jq def | `print_verdict` | `test/skills/transcript.jq:123,165` | Public but used by no consumer: both compare against the literal (Finding 8). |
| `_one_line`, `_placed_tool_uses`, `_placed_tool_results`, `_census_problems` | jq private def | `_is_str`, `_event_problems`, `_set` | `test/skills/transcript.jq:48,67,118` | Consistent with the `_` convention. |
| `problems`, `denials`, `tool_results` | jq public def | none | none | Still public, but no consumer references them at 299727c (probe P8: 0 literal references). That is harmless, and it gives future checks a surface. |
| `transcript_verdict` | bash fn | `transcript_checked`, `transcript_jq`, `transcript_tool_inputs` | `test/skills/eval-helpers.bash:376-421` | Consistent (`transcript_` prefix, noun). Its second argument is a def name interpolated into jq source (Finding 5). |
| `transcript_checked` (reimplemented as a one-line alias) | bash fn | `tool_inputs_checked` | `test/skills/eval-helpers.bash:427` | Still inconsistent: the same suffix names a validator and a producer. Carried from iteration-5 #9 (Finding 10). |
| `verdict_def`, `verdict_lines` | generator locals | eval's `def`, `lines` | `test/skills/eval-helpers.bash:394` | Consistent enough (locals). |
| Failure strings `Bash tripwire:` ×3, `Bash parser canary:` ×2, `Bash init canary:` | verdict label | A24's one-label rule; the module's own rule list | `test/skills/transcript.jq:132-138` | Inconsistent: one label, three conditions (Finding 1). |
| Problem strings (`a tool_use …`, `assistant event: …`, `an event of unknown type …`) | verdict label | iteration 4's `transcript: N malformed event(s), first: … (CLI v)` | `git show b22a026 -- test/skills/generate-reports.bash` (removed lines) | Inconsistent: no prefix, no count, no CLI version (Findings 3, 6). |
| `__VERDICT_COMPLETE__` | sentinel | none | none; searched `test/**`, `scripts/**` | New. Written as a literal in 2 consumers and 1 test (Finding 8). |
| `"Transcript $t fails: <first> (N failure(s))"`, `"Could not read $t: its verdict is incomplete"` | eval message | generator's `"; "`-joined lines, `"transcript: could not be read in full, so no check could complete"` | `test/skills/generate-reports.bash:291-296` | Inconsistent across the boundary (Findings 2, 5). |
| `write_insertion_variants <good> <dir>` | test helper fn | `write_malformed_transcripts <dir> <good>`, `fixture_base <dest> <src>` | `test/skills/malformed-transcripts.bash:21`; `test/skills/generate-reports.bash:50` | Inconsistent argument order and output shape (Finding 9). |
| `x_inserted`, `inserted1`, `v<n>.jsonl` | test data | `x1`, `g1`, `<shape>.jsonl` | `test/skills/malformed-transcripts.bash:25,44,47` | Consistent enough (test-local ids). |

---

## Findings

### 1. `Bash tripwire:` still labels three separate conditions, including the two the module's own rule list keeps apart

**Severity:** Inconsistent
**Location:** `test/skills/transcript.jq:151-160` (rule list at `:132-138`)
**Move:** 2 (naming), 4 (error consistency)
**Confidence:** High (executed: probe P3)
**Legibility-target:** for-author
Precedent: one label per condition (A24) that names the condition that fired (A17); rule list in `test/skills/transcript.jq:132-138`

The module's comment lists these as separate rules:

```jq
# test/skills/transcript.jq:132-138
#   - the init event must list exactly ["Bash"], the only tool granted;
#   - every tool_use must be Bash;
#   - tripwire: every tool_use must be named by a Bash denial (else it may
#     have run);
#   - parser canaries: every Bash denial and every tool_result must answer a
#     tool_use in the census;
#   - only Bash may be denied.
```

Only the third bullet is called the tripwire. Its strings label three conditions with it:

```jq
# test/skills/transcript.jq:151-154,159-160 (excerpt; the array continues to :161 and deny_record_failures ends :162 — read)
          ([$u[] | select(.name != "Bash")] | length) as $n
          | if $n > 0 then "Bash tripwire: \($n) call(s) of a tool other than Bash, the only tool granted" else empty end,
          ([$u[] | select($dset[.id] | not)] | length) as $n
          | if $n > 0 then "Bash tripwire: \($n) call(s) not in permission_denials (may have executed)" else empty end,
…
          ([$d[] | select(.tool_name != "Bash")] | length) as $n
          | if $n > 0 then "Bash tripwire: \($n) denial(s) of a tool other than Bash" else empty end
```

For one Read call denied as Read, probe P3 prints three `Bash tripwire:` lines, and the eval side reports the first of them. Iteration 5 raised the foreign-denial label (#3), and rubric A29 lists it ("the other-tool denial is labelled 'Bash tripwire:'"). A29 is marked Fixed, but its fix note ("one set of failure strings from the module for both callers") covers where the strings are defined, not this label. b22a026 added a second non-tripwire condition under the same label. Anyone grepping `.failed` files for `Bash tripwire` to find possibly executed calls gets two conditions that say nothing about execution.

**Recommendation:** Give each rule its own label, matching the comment: `Bash tool canary:` (or `Bash only:`) for "a tool other than Bash", `Bash tripwire:` only for "not in permission_denials", and `Bash denial canary:` for "denial of a tool other than Bash". Update the two tests that grep these strings (`test/generate-reports.bats:661,747`). Correct A29's status note.

### 2. The eval side prints only the first failure, and the verdict's order puts "no init event" ahead of the tripwire, so the eval side hides an executed call in the way C10 fixed for the generator

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:408-411`; order set by `test/skills/transcript.jq:140-142`
**Move:** 4 (error consistency), 7 (asymmetry)
**Confidence:** High (executed: probe P1)
**Legibility-target:** for-author
**Name-pattern:** n/a

```bash
# test/skills/eval-helpers.bash:408-411 (excerpt; transcript_verdict closes at :412 — read)
  if [ "${#lines[@]}" -gt 1 ]; then
    echo "Transcript $t fails: ${lines[0]} ($(( ${#lines[@]} - 1 )) failure(s))"
    return 1
  fi
```

With no init event and an undenied Bash call, the module returns `no init event in the stream (the run did not start?)` and then `Bash tripwire: 1 call(s) not in permission_denials (may have executed)`. The generator records both. `transcript_verdict` prints `… fails: no init event in the stream (the run did not start?) (2 failure(s))` (P1). The generator's comment states the principle this breaks: "These run also when the run already failed, so an executed call is never hidden behind 'claude exited N'" (`generate-reports.bash:278-279`, C10). The commit's "The eval checks print the same strings" is true of the vocabulary but not of what reaches the reader. The consumer impact is limited: `eval_fixture` shows the generator's full `.failed` first. Direct calls (`assert_mode1_equiv`, `assert_no_tool_called`, which the tests use) and hand-graded transcripts show the first line only.

**Recommendation:** Print every failure line, as the generator does: join with `; `, or print one per line after a `Transcript $t fails (N):` header. Alternatively, order `deny_record_failures` so the tripwire lines come first.

### 3. Problem strings are per object and unaggregated, and a missing id also produces a "share an id" line; the deny-record strings are counted per condition

**Severity:** Minor
**Location:** `test/skills/transcript.jq:98-105`
**Move:** 4, 7
**Confidence:** High (executed: probe P2)
**Legibility-target:** for-author
**Name-pattern:** n/a

```jq
# test/skills/transcript.jq:98,105 (excerpt from _census_problems :96-105 — read)
  | ($u[] | if ((.id | _is_str) and (.name | _is_str)) | not then "a tool_use has no string id and name"
…
    (if ([$u[] | .id] | length) != ([$u[] | .id] | unique | length) then "two tool_uses share an id" else empty end);
```

Three id-less Bash tool_uses give four lines (P2): `a tool_use has no string id and name` three times, then `two tool_uses share an id`. The last line is derived from the first condition (three nulls are "duplicates"), so the one defect reads as two. Its wording is also off, since three calls share the value. The deny-record strings, by contrast, are one line per condition with a count ("`1 call(s) not in permission_denials`"). On the generator side every line is `"; "`-joined into `.failed`, so a transcript with thousands of malformed blocks writes thousands of repeated clauses. "has no string id and name" also reads as "lacks both" while it fires when either is missing.

**Recommendation:** Aggregate problems per message with a count, in the style of the deny-record strings (`group_by(.) | map("\(.[0]) (×\(length))")`, or count inside `_census_problems`). Run the duplicate-id check over string ids only (`[$u[] | .id | strings]`). Reword to "a tool_use lacks a string id or name".

### 4. The module's public defs disagree on whether a `__text`-keyed object is an event: `denials`, `init` and the generator's result reads accept one that the validator and census skip

**Severity:** Inconsistent
**Location:** `test/skills/transcript.jq:45-46,56-57,70,111,114-115`; `test/skills/generate-reports.bash:252-261`
**Move:** 7 (asymmetry), 3 (consumer contract)
**Confidence:** High (executed: probe P9; complements fact-check Claim 24)
**Legibility-target:** for-author
**Name-pattern:** n/a

`events` returns parsed events and marker objects (`{"__text": …}`, `{"__unparsed": …}`) in one array, and a parsed line can carry a `__text` key of its own. The defs handle that key differently. `tool_uses`, `tool_results` and `_event_problems` skip such objects (`select(has("__text") | not)`, `:56-57`; `elif has("__text") then empty`, `:70`). `init` (`:111`), `denials` (`:114-115`), the `_placed_*` counts, and the generator's report and `result_state` reads (`generate-reports.bash:253,259`) do not. Fact-check Claim 24 showed one consequence: a call inside such an event is never counted. P9 shows the other direction. A correctly placed, undenied Bash call passes `deny_record_failures` at both the generator and the eval side when the matching denial sits only in a `__text`-keyed result event, which is never validated. The same event also becomes the report text (`# from marker`). Like Claim 24, this is not reachable from real CLI output. The defect is that the module's interface has no single definition of "an event", so each def re-decides it.

**Recommendation:** Keep the marker out of the data namespace. Either have `events` drop `__text` lines entirely and wrap unparsed lines as a distinct non-object (for example `{"__unparsed"}` checked by `type` and key set, or a separate `unparsed_lines` def), or treat any parsed object with a `__text`/`__unparsed` key as a problem. Then every def reads the same event list. Add a `__text`-key variant to `write_insertion_variants` or the shape table, so the property covers key names, not only positions (fact-check Claim 23 scope).

### 5. The harness-level strings still differ across the generator/eval boundary, and the eval side blames the transcript for a caller's typo

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:286-292`; `test/skills/eval-helpers.bash:393-407`
**Move:** 4, 2
**Confidence:** High (executed: probes P5a, P5b)
**Legibility-target:** for-author
Precedent: one string per condition (A24); generator string `transcript: could not be read in full, so no check could complete` in `test/skills/generate-reports.bash:292`

| Condition | Generator `.failed` | eval-helpers message |
|---|---|---|
| transcript unreadable | `transcript: could not be read in full, so no check could complete` (`:286` skips jq, `:291-292`) | `Could not read $t` (`:397-400`) |
| verdict without sentinel | same string (`:291-292`) | `Could not read $t: its verdict is incomplete` (`:404-406`) |
| verdict def misspelled (caller bug) | n/a (def fixed at `:284-285`) | `Could not read $t: its verdict is incomplete` (P5b, on a good transcript) |

b22a026 unified the module-decided strings. These three harness strings sit outside the module, and they split two ways. The generator folds unreadable and incomplete into one string, while eval separates them. The `transcript:` prefix survives only on the generator's string (see Finding 6). Also, `transcript_verdict`'s second argument is spliced into jq source (`"t::$def | t::print_verdict"`, `:401`), with `2>/dev/null`. So a typo such as `deny_record_failure` becomes "Could not read <path>: its verdict is incomplete", which points at the transcript, not the caller.

**Recommendation:** Use one string per condition on both sides, for example `transcript: could not be read` and `transcript: verdict incomplete (no sentinel)`. In `transcript_verdict`, reject a def outside `transcript_failures|deny_record_failures` with its own message before running jq.

### 6. Malformed-stream failures lost their prefix and the CLI version, which is the case that most needs the version

**Severity:** Minor
**Location:** `test/skills/transcript.jq:67-108,141`
**Move:** 4, 3
**Confidence:** High (executed: probe P4)
**Legibility-target:** for-author
Precedent: iteration 4's `transcript: $n_problems malformed event(s), first: $problems (CLI $cli_version)` (removed in `git show b22a026 -- test/skills/generate-reports.bash`), and the `(CLI …)` suffix on the init and parser canaries at `test/skills/transcript.jq:150,156,158`

For a malformed event the module now returns only the raw problem, `assistant event: message is not an object` (P4, init had `claude_code_version` `9.9.9`). The line has no category prefix and no CLI version. `deny_record_failures` returns `$base` before `$cli` is bound (`:141-143`), so no malformed-stream line can carry the version. The module header says a CLI change "voids runs loudly" (`:36`), and C17's fix recorded the CLI in the marker so a change could be traced. The canaries still carry the version, but the malformed class, which a CLI shape change is most likely to produce, does not. The kept transcript still has the init event, so the information is recoverable, just not in the marker. The prefixes are now uneven: `Bash tripwire:`, `Bash parser canary:` and `Bash init canary:` have one, while problems and `no init event …` have none. The only `transcript:` string is a generator-side one (Finding 5).

**Recommendation:** Prefix problems uniformly (`transcript: <problem>`), and append `(CLI <v>)` from `init` when it exists, either in `transcript_failures` or once as a trailing line.

### 7. Result-event conditions are decided in the generator, not the module, so `transcript_failures` (and every eval check) passes a stream the generator voids

**Severity:** Minor
**Location:** `test/skills/generate-reports.bash:256-267`; `test/skills/transcript.jq:120-126`; `test/skills/eval-helpers.bash:438`
**Move:** 3, 7
**Confidence:** High (executed: probe P7; fact-check Claim 7)
**Legibility-target:** for-author
**Name-pattern:** n/a

The module calls `transcript_failures` "The verdict for any transcript run" (`:120`), and the generator's comment says "transcript.jq decides the verdict, in one place, for the generator and the eval checks alike" (`:268-269`). Two conditions are still decided only in the generator, with strings only there: `no result event in the stream` and `the result event is an error` (`:262-266`). An init-only stream gets the empty verdict from `transcript_failures` at both sides (P7), while the generator's `result_state` is `none`. The eval checks therefore pass it (`transcript_checked`, `assert_no_tool_called`; Claim 7). The init `tools` reading has the same split. `deny_record_failures` compares `init | .tools` to `["Bash"]`, while `tool_inputs_checked` has its own array-only reading at `:438`, so a string `tools` turns the misspelling guard off (Claim 7). This is what remains of C36 (marked Fixed) and iteration-5 #4.

**Recommendation:** Move the result-event rule into `transcript_failures` (a `result_failures` part: no result event, or the last one `is_error`), and have the generator use it instead of its inline jq. Export `def init_tools` (null, or an array of strings, else a problem) for `tool_inputs_checked` and `deny_record_failures` to share. Correct C36's status note.

### 8. The sentinel is a public def that no consumer reads; both consumers and a test hard-code the literal

**Severity:** Informational
**Location:** `test/skills/transcript.jq:123`; `test/skills/generate-reports.bash:291`; `test/skills/eval-helpers.bash:404`; `test/generate-reports.bats:758`
**Move:** 2, 3
**Confidence:** High (probe P8b)
**Legibility-target:** for-author
No existing precedent in `test/**`, `scripts/**`, `hooks/**` (no other sentinel or end-of-record marker protocol)

`def verdict_end: "__VERDICT_COMPLETE__";` exists so the value has one name, but both callers compare against the literal string. If the def changed, every run would be voided and every eval check would fail. That is fail-closed, so the mismatch would be caught, but only as a confusing "could not be read" everywhere. The downgrade applies (no precedent): Minor → Informational.

**Recommendation:** Either drop the def and document the literal as part of the protocol in the module header, or have each consumer read it once (`jq -rn -L … 'import "transcript" as t; t::verdict_end'`) into a variable.

### 9. The two malformed-transcripts helpers take their arguments in opposite orders and return results differently; the control transcript is still derived from one shape's bad line

**Severity:** Minor
**Location:** `test/skills/malformed-transcripts.bash:7,21,51-57,69`; `test/generate-reports.bats:633`; `test/skills/mode1-equiv.bats:308`
**Move:** 2, 7
**Confidence:** High
**Legibility-target:** for-author
Precedent: destination-first argument order in `write_malformed_transcripts <dir> <good-bash-command>` (`test/skills/malformed-transcripts.bash:7`) and `fixture_base <dest> <fixture-dir>` (`test/skills/generate-reports.bash:50`)

```bash
# test/skills/malformed-transcripts.bash:21-22 and :57-59 (excerpts; each function continues, to :49 and :70 — read)
write_malformed_transcripts() {
  local dir="$1" good="$2" init call bad shape
…
write_insertion_variants() {
  local good="$1" dir="$2"
  mkdir -p "$dir"
```

The sibling helpers in one file take `<dir>` first and second respectively. One names its outputs after the exported `MALFORMED_SHAPES` and prints nothing. The other names them `v<n>.jsonl` and prints the count, which consumers must capture and then glob anyway. A caller who swaps the arguments of the new helper gets `jq` reading a directory. Separately, iteration-5 #12 is unchanged. Both table tests still build their control with `grep -v '^123$' "$TEST_TMPDIR/bad/number_line.jsonl"`, which couples each consumer to one shape's literal bad line, while the helper promises that control property in its header (`:10-11`).

**Recommendation:** Make it `write_insertion_variants <dir> <good-transcript>`. Have `write_malformed_transcripts` also write `<dir>/control.jsonl`, and point both tests at it.

### 10. `transcript_checked` is now a one-line alias beside `transcript_verdict`, and still shares a suffix with a data producer (carried from iteration-5 #9)

**Severity:** Minor
**Location:** `test/skills/eval-helpers.bash:419-421,427`
**Move:** 2
**Confidence:** Medium
**Legibility-target:** for-author
Precedent: `tool_inputs_checked` in `test/skills/eval-helpers.bash:427` prints validated data on stdout; status-only validators elsewhere are `assert_*` in `test/skills/eval-helpers.bash:188-547`

`transcript_checked` returns only a status and a message, while `tool_inputs_checked` returns data. b22a026 adds `transcript_verdict`, and `transcript_checked` becomes `transcript_verdict "$1" transcript_failures`. The surface now has two names for the same validator, and neither matches `tool_inputs_checked`'s meaning of the suffix.

**Recommendation:** Keep one name. For example, call `transcript_verdict "$t" transcript_failures` at the four call sites and drop the alias, or rename the alias `transcript_ok`.

### 11. Tests and prose still reference strings the code no longer emits

**Severity:** Minor
**Location:** `test/generate-reports.bats:600`; `docs/decisions/log.md:77`
**Move:** 3 (documentation / test drift)
**Confidence:** High (static; fact-check Claim 1)
**Legibility-target:** for-author
**Name-pattern:** n/a

```bash
# test/generate-reports.bats:598-600 (excerpt; the test starts :591 and ends :601 — read)
  [ "$status" -eq 0 ]
  grep -q "no init event in the stream (the run did not start?)" "$out/tc-1-thing.txt.failed"
  ! grep -q "did the deny rule remove the tool" "$out/tc-1-thing.txt.failed"
```

b22a026 removed "did the deny rule remove the tool" from the codebase (rg finds it only in this test and in reviews). So the negative can no longer fail, and the test no longer checks its name's promise ("not blamed on the deny rule"). The current blame string is `Bash init canary:`. Log #56's voiding list keeps the old vocabulary: "a denial names a call the parser did not see" (now "not in the census"), and "does not list Bash" (now "not exactly [\"Bash\"]"). It also omits three conditions (Claim 1).

**Recommendation:** Change the negative to `! grep -q "Bash init canary"`. Replace log #56's list with a pointer to `deny_record_failures`.

### 12. The checker still says "command" where the sibling eval diagnostics say "call" (carried from iteration-5 #8)

**Severity:** Minor
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:168,186`
**Move:** 2
**Confidence:** High
**Legibility-target:** for-author
Precedent: "call" for a tool invocation in `test/skills/eval-helpers.bash:472-473` (`"No $tool call."`, `"$tool calls seen: N"`) and `test/skills/transcript.jq:152,154` (`"call(s) …"`)

The checker prints `Bash commands seen: N` and `No Mode 1 command computed any of: …`. These land in the same `eval_fixture` output as `Bash calls seen: N`, so readers see the same objects counted under two nouns. It is unchanged since iteration 5.

**Recommendation:** Use "call" in the checker's output, or add the noun once: `Bash calls seen (commands checked): N`.

---

## What Looks Good

- **The verdict is now a module output, not a per-consumer re-encoding.** The iteration-5 finding that motivated this (#3, #5: generator and eval printed different strings through different positional `\x1f` records) is closed at the module level. Both sides run `t::<def> | t::print_verdict` and check the same sentinel, and every module string reaches both unchanged (P1-P4).
- **`tool_results` returns objects**, like `tool_uses` and `denials`, and the uneven `{undenied, unseen, orphans, foreign}` record is gone. Iteration-5 #10 is closed.
- **`_one_line` on every emitted string** makes the one-line-per-failure contract hold for CLI-written text (Claim 27). This is the right place for it: in the module, applied at the protocol boundary.
- **The `_` private convention** is applied to all four new helpers, so the public surface is legible at a glance.
- **Test-helper naming** (`write_insertion_variants`, `x_inserted`, `inserted1`) matches the suite's verb_noun and short-id style. The property test uses the same helper at both the generator and eval layers.
- **The iteration-5 test fixes hold.** The `no_tool_called` table leg uses the function's own `(tool, ERE)` shape with a control (#2). The checker test passes a valid commands file (#7). The eval-helpers `.failed` comment lists all failure sources (#13, Claim 16).

---

## Summary Table

The full remaining inventory at 299727c. It includes fact-check items that bear on the API contract, cited rather than re-verified.

| # | Finding | Severity | Location | Confidence | Legibility-target |
|---|---|---|---|---|---|
| 1 | `Bash tripwire:` labels three conditions (A29 status correction) | Inconsistent | `test/skills/transcript.jq:151-160` | High | for-author |
| 4 | Defs disagree on `__text`-keyed objects; a denial in one satisfies the tripwire for a placed call (P9; sibling of Claim 24) | Inconsistent | `test/skills/transcript.jq:56-57,70,111,114` | High | for-author |
| FC-24 | Census skips `__text`-keyed events (fact-check Claim 24; the same fix as #4) | (fact-check Incorrect) | `test/skills/transcript.jq:56-57` | High | for-author |
| FC-25b | Type "allowlists" use `inside` (substring), so "anything else is a problem" does not hold (fact-check Claim 25b). A contract bug in the module's documented input shape | (fact-check Incorrect) | `test/skills/transcript.jq:72,81-82` | High | for-author |
| 2 | Eval prints the first failure only; "no init" hides the tripwire (C10 on the eval side) | Minor | `test/skills/eval-helpers.bash:408-411` | High | for-author |
| 3 | Problems unaggregated; a missing id also reports "share an id" | Minor | `test/skills/transcript.jq:98-105` | High | for-author |
| 5 | Harness strings differ across the boundary; a caller's def typo reads as an unreadable transcript | Minor | `generate-reports.bash:291-292`, `eval-helpers.bash:397-406` | High | for-author |
| 6 | Malformed-stream failures have no prefix and no CLI version | Minor | `test/skills/transcript.jq:108,141` | High | for-author |
| 7 | Result-event rule and init-tools reading live outside the module (C36 status correction) | Minor | `generate-reports.bash:256-267`, `eval-helpers.bash:438` | High | for-author |
| 9 | Helper argument order and outputs differ; control still derived from `number_line` | Minor | `test/skills/malformed-transcripts.bash:21,57` | High | for-author |
| 11 | Vacuous negative grep on a removed string; log #56 vocabulary stale (Claim 1) | Minor | `test/generate-reports.bats:600`, `docs/decisions/log.md:77` | High | for-author |
| 12 | "command" vs "call" (carried, iteration-5 #8) | Minor | `mode1-equiv.py:168,186` | High | for-author |
| 10 | `transcript_checked` alias and suffix (carried, iteration-5 #9) | Minor | `test/skills/eval-helpers.bash:419-427` | Medium | for-author |
| 8 | Sentinel def unused; literal hard-coded 3× | Informational | `transcript.jq:123`, `generate-reports.bash:291`, `eval-helpers.bash:404` | High | for-author |

---

## Overall Assessment

b22a026 does what iteration 5 asked of the interface. The verdict is decided in the module and printed through one protocol, and both consumers bind to the same strings, so the per-consumer re-encoding problem is gone. What remains is smaller and mostly about vocabulary and edges. The first group is labels: one label still covers three rules (Finding 1), and problems lack a prefix, a count and the CLI version (Findings 3, 6). The second group is aggregation at the eval boundary (Finding 2), and a handful of harness strings that sit outside the module (Findings 5, 7). One contract issue is substantive. The module has no single definition of "an event": the reader's own `__text` marker shares the input's key namespace, and the defs treat it differently. That is the root of fact-check Claim 24 and of the new P9 variant, in which a placed call is "denied" by an unvalidated event (Finding 4). Like the inside/substring gap (Claim 25b), it is not reachable from real CLI output, and it is a one- or two-line module fix. Everything here is fixable in place without touching consumers' shape. For consumers today, no fixture known to exist is misgraded. The Inconsistent rows (1, 4, plus the fact-check's 24/25b) are the ones worth closing before the merge if the user wants the documented absolutes to hold. The Minor rows can be recorded as residuals.

---

## Goal-Alignment Note

**Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."

**Answered:** Yes. The critique is saved at `docs/reviews/api-consistency-review-2026-09-26-q062-q063-iter6.md` with `Commit: 299727c` at the top. It follows the api-consistency-reviewer structure: header, baseline, name-pattern audit, findings, what looks good, summary table and assessment. Every finding has Severity, Location, verbatim Evidence (with truncation markers where an excerpt ends inside its unit), Confidence and Legibility-target. Naming findings (1, 5, 6, 8, 9, 10, 12) carry a `Precedent:` or `No existing precedent in` line. The others say `Name-pattern: n/a`. All four named surfaces are covered: the transcript.jq public and private defs (audit, 4, 8); the verdict vocabulary across generator and eval (1, 2, 3, 5, 6, 7); the eval-helpers names and messages (2, 5, 10); and malformed-transcripts.bash (9). As the terminal pass requires, the Summary Table is the full remaining inventory, including carried iteration-5 items and the two fact-check Incorrect items that bear on the module contract.

**Out of scope:** C13, C24, C34 and C35 are open by choice and are not re-reported, and the override-log items are settled. The Q-062 install gate is unchanged since iteration 4. No `claude` or network command was run. The probe script passes the required shellcheck invocation.

**Escalate:** Finding 4 (P9) is new at this pass. It is a second direction of fact-check Claim 24's root cause: a correctly placed undenied call passes deny-record at both the generator and the eval side when its denial sits in a `__text`-keyed event. It is not CLI-reachable, and the same fix closes both. Findings 1 and 7 correct the Fixed status of rubric rows A29 and C36. Whether to fix these at the terminal pass or record them as residuals is the user's call.

**Decisions:** I rated Finding 4 Inconsistent, not Breaking. No existing consumer regressed, and the input shape is hand-made, but it breaks the module's stated contract end to end. I rated Finding 2 Minor, because `eval_fixture` shows the generator's full `.failed` before any eval check runs. I carried iteration-5 #8, #9 and #12 forward as rows rather than re-arguing them.
