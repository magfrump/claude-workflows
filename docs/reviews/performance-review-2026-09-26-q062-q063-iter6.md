Commit: 299727c

# Performance Review — branch skill-fixtures (Q-062 [2], Q-063 [1]), iteration 6 (terminal pass)

**Scope:** `git diff main...HEAD` at 299727c, focused on the census fix b22a026: `test/skills/transcript.jq` (whole module), the generator's transcript block (`test/skills/generate-reports.bash:247-298`), `transcript_jq` … `assert_mode1_equiv` (`test/skills/eval-helpers.bash:376-547`), `mode1-equiv.py`'s self-test (`:79-98`, `evaluate` `:134-147`), `write_insertion_variants` (`test/skills/malformed-transcripts.bash:57-70`) and the two property tests (`test/generate-reports.bats:702-724`, `test/skills/mode1-equiv.bats:371-393`).
**Date:** 2026-09-26
**Based on:** `docs/reviews/code-fact-check-report.md` (commit 299727c, 38 claims). Used for Claims 2, 4, 7, 24 and 32, and for its 20,000-call timing (3.4 MB, about 5 s). My timings come from the review sandbox: 16 CPUs, `/proc/loadavg` 4.5–6.7, jq 1.6, bats 1.8.2. Probe script: `docs/reviews/execution-logs/perf-299727c-census-probes.sh`. It passes `shellcheck -x -e SC1091 -s bash -S warning`. Output: `perf-299727c-census-probes.txt`. Suite timing: `perf-299727c-suite-timing.txt`, 84 tests, all ok. Each program is timed as best of 3, and each gets its own `python3` parent so that its RSS is its own. These timings support the findings. They are not execution verdicts.

C3, C4 and C37 are open by choice (settled). F1–F3 below are new instances of C37's class that b22a026 introduced. They are reported as deltas so the user can fold them into C37 or leave them there. They are not a re-opening of C37.

## Data Flow and Hot Paths

Every path in b22a026 is **cold**. Each one runs once per fixture, after a paid `claude -p` call that takes tens of seconds, or inside the bats suites. Realistic N is tiny. The 13 real runs held 21 `tool_use` in total (commit note; fact-check Claim 28), so a deny-record transcript has a handful of calls. At N = 10, every `jq` process here costs 19–33 ms, and `jq -n 1` alone costs 22 ms. Absolute cost is therefore process start, and the findings are about growth and redundancy.

- **The census** (`transcript.jq:56-57`) is `[.[] | objects | select(has("__text") | not) | .. | objects | select(.type == …)]`. That is a full recursive descent over every value of every event, done once for `tool_use` and once for `tool_result`. A single descent took 965 ms at 20,000 calls (7.2 MB), against 347 ms to parse the events, so each descent costs about 1.8× the parse on top of it. The positional count (`_placed_tool_uses`) took 510 ms. `problems` (`:108`) runs `_event_problems`, both descents, both placed counts and a `unique`. It took 2,427 ms at 20,000 calls, about 7× the parse.
- **Generator** (`generate_one`, once per fixture): 3 `jq` processes, the same as iteration 5. The report text (`:252-255`) and `result_state` (`:258-261`) now go through the strict slurping reader (C36). The verdict (`:287-289`) runs `transcript_failures`, or `deny_record_failures` under deny-record.
- **Eval checks** (once per check): `tool_called:` / `no_tool_called:` make 3 `jq` processes (`transcript_checked`, `transcript_tool_inputs`, `known`), the same as before. `mode1_equiv:` makes **2** `jq` processes (`transcript_verdict … deny_record_failures`, then the command extraction), down from 3. It then runs 1 `python3` checker, which spawns 1 `python3` for the self-test and 1 more per Mode 1 command it evaluates. `subagents_min:` goes from 1 lenient streaming `jq` to 2 strict ones (`transcript_checked`, then the count).

## Findings

#### F1 — `deny_record_failures` recomputes `problems` twice, which runs the census three times per kind (6 recursive descents) and `init` four times; bound once, the same verdict is 2.2× faster

**Severity:** Informational
**Location:** `test/skills/transcript.jq:124-126` (`transcript_failures`), `:139-163` (`deny_record_failures`), `:96-105` (`_census_problems`)
**Move:** 1 (hidden multiplication: `def`s are not memoized, so each reference re-walks the events)
**Classification:** Micro (a constant factor of about 2.2×, with no change of complexity class) / Cold path (once per deny-record fixture in the generator, and once per `mode1_equiv:` check)
**Confidence:** High (measured; the outputs are identical)
**Baseline:** The committed `deny_record_failures | print_verdict` took 5,930 ms at 20,000 calls (7.2 MB). The same verdict with `tool_uses`, `tool_results`, `init` and `problems` each bound once took 2,740 ms. At 2,000 calls the times were 568 ms and 300 ms. At 40,000 calls with 1,000-byte text blocks (54.5 MB) they were 14,257 ms and 6,153 ms. At 10 calls both took 32 ms. For comparison, iteration 4's generator verdict (b22a026^) took 2,110 ms at 20,000 calls. Both programs printed `__VERDICT_COMPLETE__` alone on all four passing transcripts. On 127 failing inputs (114 insertion variants plus the 13 malformed shapes) their output was byte-identical: `identical=127 differ=0`. Measured in the review sandbox, 2026-09-26 (`perf-299727c-census-probes.txt`).
**Legibility-target:** for-author

Evidence (`transcript.jq:124-126`, complete):

```jq
def transcript_failures:
  problems as $p
  | $p + (if init == null then ["no init event in the stream (the run did not start?)"] else [] end);
```

and the head of `deny_record_failures` (`:139-150`, excerpt; the remainder, `:151-163`, is the other five failure legs, one of which is `([tool_results[] | select($all[.tool_use_id] | not)] | length) as $n` at `:157`, and `end;`, which I read):

```jq
def deny_record_failures:
  transcript_failures as $base
  | if (problems | length) > 0 then $base
    else $base +
      (init | (.claude_code_version // "unknown") | tostring | _one_line) as $cli
      | tool_uses as $u
      | ([$u[] | .id] | _set) as $all
      | denials as $d
      | ([$d[] | select(.tool_name == "Bash") | .tool_use_id]) as $denied
      | ($denied | _set) as $dset
      | [ (init | .tools) as $tools
          | if init != null and $tools != ["Bash"] then "Bash init canary: … (CLI \($cli))" else empty end,
```

(`:150` is shortened at `…`; it interpolates `$tools | tojson | _one_line`.)

The count comes from reading, and it is confirmed by timing. `problems` runs twice, at `:125` through `transcript_failures` and again at `:141`. Each run calls `_census_problems` (`:97`, `tool_uses as $u | tool_results as $r`) and both `_placed_*` counts. After that, `tool_uses` runs again at `:144` and `tool_results` again at `:157`. The result is 3 descents for each kind, 6 in all, where 2 would do. `init` runs 4 times (`:126`, `:143`, `:149`, `:150`), but each run is a cheap filter. The iteration-5 F1 pattern (C37) is therefore fixed for `transcript_failures`: its 2,425 ms equals `problems` once, at 2,427 ms. The pattern returns for `deny_record_failures`, and the census makes each repetition more expensive, since a descent costs about 1.8× the parse where the old positional walk cost less. The deny-record verdict is now 2.8× iteration 4's (5,930 ms against 2,110 ms at 20,000 calls). Bound once, it would be 1.3×. This agrees with the fact-check's "20,000 denied calls plus one undenied call (3.4 MB): tripwired in about 5 s" (Claim 24's probe list). At the realistic handful of calls the difference is 0 ms, so this does not block the merge.

**Recommendation:** Optional. Bind once at the top: `tool_uses as $u | tool_results as $r | init as $i | ([(.[] | _event_problems), _census_problems_of($u; $r)] | map(_one_line)) as $p | …`, with `_census_problems` taking `$u` and `$r` as parameters. The probe script carries a working 30-line version (`deny_record_failures_once`). The parentheses around the `$p` binding are required: without them, the rest of the pipe runs on the problems array instead of the events. My first draft of the variant made exactly that mistake, and every call read as undenied. Keep the probe's equivalence loop as the guard if this is adopted. Otherwise, record it under C37.

#### F2 — The generator's report and result-state reads moved from streaming to the strict slurp (C36), and `subagents_min:` went from 1 process to 2; memory per read is now proportional to the transcript

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:252-261`; `test/skills/eval-helpers.bash:483-496` (`assert_subagents_min`)
**Move:** 3 (work moved to the wrong place: streaming → slurp) and 4 (memory lifecycle)
**Classification:** Micro × Cold (linear, once per fixture or check)
**Confidence:** High (measured)
**Baseline:** The strict report read took 1,141 ms / 256,980 KB peak at 54.5 MB, and `result_state` took 1,163 ms / 256,880 KB (`perf-299727c-census-probes.txt`). The iteration-5 streaming report read took 889 ms / 27,580 KB on a file of the same size (`perf-9c73ae4-transcript-jq-probes.txt`, "gen report extraction (:252)"). At 7.2 MB the strict reads took 409 / 431 ms and 110 MB each. At 10 calls they took 20 ms each.
**Legibility-target:** for-author

Evidence (`generate-reports.bash:252-261`; the enclosing `if` block runs to `:298`, and the rest is the verdict call quoted under F1's location, which I read):

```bash
    jq -rR -n -L "$SCRIPT_DIR" 'import "transcript" as t;
      t::events | [.[] | objects | select(.type == "result")] | last | .result // empty
      | if type == "string" then . else tojson end' "$transcript_path" \
      > "$report_path" 2>/dev/null || : > "$report_path"
    if [ -z "$failure" ]; then
      local result_state
      result_state=$(jq -rR -n -L "$SCRIPT_DIR" 'import "transcript" as t;
        t::events | [.[] | objects | select(.type == "result")] | last
        | if . == null then "none" elif .is_error == true then "error" else "ok" end' \
        "$transcript_path" 2>/dev/null)
```

The generator's process count is unchanged at 3. Each read now holds every event in memory, which makes about 9× the peak memory at 54.5 MB and 1.3× the time. The report text and `result_state` are fields of the same last `result` event that the verdict process has already slurped. So one `jq` could emit the verdict, the result state and the report, and a verdict and the data it licenses would come from one parse (the iteration-5 F2 argument, C37). `assert_subagents_min` adds a second strict `jq` after `transcript_checked`. At realistic N all of this costs 20–30 ms per process.

**Recommendation:** No action is needed at realistic N. If C37 is ever taken up, fold these two reads into the verdict process (or `subagents_min`'s count into its `transcript_checked`) in the same change.

#### F3 — The two new property tests add 4.5 s to the fast gate: 17 full generator runs and 11 × 3–5 `jq` processes; together with the table tests, 37% of the three suites' time

**Severity:** Informational
**Location:** `test/generate-reports.bats:702-724`; `test/skills/mode1-equiv.bats:371-393`; `test/skills/malformed-transcripts.bash:57-70`
**Move:** 1 (hidden multiplication: variants × end-to-end runs)
**Classification:** Micro × Cold (test-suite wall-clock in the serial `--fast` pre-gate)
**Confidence:** High (measured)
**Baseline:** Measured with `bats --timing` on 2026-09-26 in the review sandbox (`perf-299727c-suite-timing.txt`, 84 ok). Test 43 (generator property) took 2,658 ms, test 76 (mode1 property) took 1,846 ms, test 39 (generator table) took 2,321 ms and test 72 (mode1 table) took 1,858 ms. Together they are 8,683 ms of a 23,634 ms per-test sum. The next-slowest test took 1,055 ms. Wall time was 26.2 s.
**Legibility-target:** for-author

Evidence (the loop in the generator property test, `generate-reports.bats:715-721`, inside the test `:702-724`; the remainder is the control run above it and the `echo`/`[ "$escapes" -eq 0 ]` tail, which I read):

```bash
  for f in "$TEST_TMPDIR"/ins/v*.jsonl; do
    stub_transcript "$f"
    run bash "$GEN" demo
    if [ ! -e "$out/tc-1-thing.txt.failed" ] || grep -q "generation did not finish" "$out/tc-1-thing.txt.failed"; then
      escapes=$((escapes + 1)); echo "not voided by a check: $(basename "$f")"
    fi
  done
```

`write_insertion_variants` produced 16 variants for the generator's 4-line good transcript (counted by hand, then run). With the control that is 17 `bash "$GEN" demo` runs, about 156 ms each: a bash start, sourcing the runner, a stub `claude` and 3 `jq`. The mode1 test's 3-line transcript gives 11 variants. Each variant runs a direct `transcript_jq`, `assert_mode1_equiv` (1 `jq`, which fails at the verdict) and `assert_no_tool_called` (1 `jq`, or 3 when the call is placed where it belongs), at about 168 ms per variant. Variant count grows with the good transcript's object and array count. `write_insertion_variants` writes a full copy per position, so it is O(lines × positions). It generated 114 variants for my 22-line probe transcript without difficulty, and the test inputs have 3–4 lines. The cost is real but proportionate to what the test proves: this is the property test that closes R3 by construction (fact-check Claim 2).

**Recommendation:** No action. If the fast gate's time matters, the generator test could run the verdict `jq` directly for every variant and run `bash "$GEN"` end to end on a sample only. That would weaken "end to end at every position", so I would not do it for 2.7 s.

#### F4 — The mode1-equiv self-test adds one `python3` subprocess (about 16 ms) to every checker invocation, `--check-spec` included

**Severity:** Informational
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:79-98` (`reference`), `:134-147` (`evaluate`)
**Move:** 1 (hidden multiplication: once per invocation)
**Classification:** Micro × Cold
**Confidence:** High (measured)
**Baseline:** `evaluate(prog, '6 * 7')` took 16.3 ms at best. `reference()` including the self-test took 19.5 ms, and the whole `--check-spec` run took 47 ms (`perf-299727c-census-probes.txt`). `python3 -c pass` took 9 ms.
**Legibility-target:** for-author

Evidence (`mode1-equiv.py:95-98`, the end of `reference`; its head, `:79-94`, is the SKILL.md block extraction and the `ast.dump`, which I read):

```python
    # iteration 5, A27). 6 * 7 must give 42.
    if evaluate(w[0], "6 * 7") != 42:
        raise SetupError("SKILL.md's Mode 1 evaluator failed its self-test (6 * 7 did not give 42)")
    return w[0], dump
```

`reference()` is called once per process in both modes (`main`, `:150-165`). The cost is one extra interpreter per `mode1_equiv:` check (5 committed fixtures, so about 80 ms per eval run) and one per checker call in `mode1-equiv.bats`, including the pre-flight `--check-spec` loop over the committed specs. The subprocess has `evaluate`'s 10 s timeout. On a badly stalled host the self-test would return None and exit 2 (setup error), which is the fail-safe direction. This is the price of A27 (fact-check Claim 4), and it is small.

**Recommendation:** No action.

## Endorsements (evidence-gated)

- `assert_mode1_equiv` now makes 2 `jq` processes where it made 3: one `transcript_verdict … deny_record_failures`, then the command extraction. `transcript_verdict` calls `transcript_jq` once. `[read: test/skills/eval-helpers.bash:376-380, 393-412, 529-547]`
- `transcript_failures` evaluates `problems` once. This retires iteration 5's F1 triple on the non-deny generator path and in `transcript_checked`: `transcript_failures` took 2,425 ms against 2,427 ms for `problems` alone at 20,000 calls. `[unverified — submitted as claim]`
- The census and both verdicts grow linearly. `deny_record_failures` took 568 → 5,930 ms for 10× the calls (2,000 → 20,000), and one descent took 120 → 965 ms. Peak memory stays within about 1.3× of the event array (138,688 KB against 109,636 KB at 7.2 MB). `[unverified — submitted as claim]`
- The generator still makes 3 `jq` processes per transcript fixture (report, `result_state`, verdict). b22a026 changed what they read but added no process. `[read: test/skills/generate-reports.bash:247-298]`

(I make no performance claim about the `__text` escape (fact-check Claim 24). Whatever fixes it, the census walk stays the same.)

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `deny_record_failures` runs `problems` twice, which means 6 census descents instead of 2 and `init` 4×. It took 5,930 ms against 2,740 ms bound once at 20,000 calls (identical on 131 inputs), and 2.8× iteration 4's verdict. A C37-class delta | Informational | `test/skills/transcript.jq:124-126, 139-163, 96-105` | High |
| F2 | The report and `result_state` reads are now strict slurps (257 MB against 28 MB at 54.5 MB), and `subagents_min:` makes 2 processes where it made 1. A C37-class delta | Informational | `test/skills/generate-reports.bash:252-261`; `test/skills/eval-helpers.bash:483-496` | High |
| F3 | The property tests add 4.5 s to `--fast`. With the table tests, that is 8.7 s of 23.6 s (37%) | Informational | `test/generate-reports.bats:702-724`; `test/skills/mode1-equiv.bats:371-393` | High |
| F4 | The mode1-equiv self-test costs 1 extra `python3` (about 16 ms) per checker call | Informational | `test/skills/arithmetic-eval/mode1-equiv.py:95-98` | High |

**Full remaining performance inventory (terminal pass):** C3 and C4 are open by choice. C37 is open by choice, and F1–F3 are its new instances. F4 needs no action. Nothing else is open from iterations 1–5. C28 and C33 are Fixed, and I found nothing that re-opens them: the set lookups are unchanged, and the ids are still strings.

## Overall Assessment

b22a026 makes the reader stricter by construction, and it pays in constant factors only. Every path is cold, every cost grows linearly, and at the handful of calls a real deny-record run makes, each `jq` process costs 20–33 ms, almost all of it process start. The census itself is a fair price: one recursive descent costs about 1.8× the parse. The avoidable cost is F1. `deny_record_failures` re-derives `problems` and the census, so the deny-record verdict does 6 descents where 2 would do and takes 2.2× longer than necessary (2.8× iteration 4's). The fix is a local 30-line rebinding, which I checked for byte-identical output on 131 inputs. It is optional, and C37 already covers its class. F2 and F3 are the cost of C36's strict reads and of the property tests that close R3. Both are proportionate. No profiling is needed, and nothing here blocks the local merge.

## Goal-Alignment Note

The user's goal is a terminal review of b22a026 before a local merge, with the remaining inventory stated in full. This review measured the specific costs the brief named: the census's `..` descents, `problems` recomputed inside the verdicts, `init`, the process counts per generator run and per check, the property tests' `--fast` time and the self-test subprocess. It found no blocker, and it named one optional, verified simplification (F1). I did not edit any code under review, committed nothing, ran no `claude` or network command, and did not re-litigate C3, C4 or C37. The only files written are this report and the probe artifacts under `docs/reviews/execution-logs/perf-299727c-*`.
