Commit: 9c73ae4

# Performance Review — branch skill-fixtures (Q-062 [2], Q-063 [1]), iteration 5 (terminal pass)

**Scope:** `git diff main...HEAD` at 9c73ae4, focused on the structural fix 272bc83. That covers `test/skills/transcript.jq` (new), the generator's verdict (`test/skills/generate-reports.bash:285-320`), `transcript_jq` / `transcript_checked` / `tool_inputs_checked` / `assert_mode1_equiv` (`test/skills/eval-helpers.bash:366-540`), `mode1-equiv.py`'s new `commands()` input, and the 13-shape table (`test/skills/malformed-transcripts.bash`) with the 11 new tests. Q-062's `agent_gate` is unchanged since iteration 4 and is not re-reviewed.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (commit 9c73ae4). It is used for Claims 10 (C33's three-pass item is not fixed), 11, 26, 29 and 31. My timings come from the review sandbox: 16 CPUs, `/proc/loadavg` 6.9–9.0 (a loaded host, so absolute numbers are inflated about equally for every variant), jq 1.6. Probe script: `docs/reviews/execution-logs/perf-9c73ae4-transcript-jq-probes.sh`, which passes `shellcheck -x -e SC1091 -s bash -S warning`. Output: `perf-9c73ae4-transcript-jq-probes.txt`. Suite timing: `perf-9c73ae4-suite-timing.txt`. The synthetic transcripts have an init event, then N denied Bash calls, each with a 1,000-byte text block and a `tool_result`, then one result event that denies all N. Sizes: N = 10 / 2,000 / 10,000 / 40,000, which is 14 KB / 2.7 MB / 13.6 MB / 54.5 MB. These timings support the findings but are not execution verdicts.

C3 and C4 are open by choice and are not repeated here. C24 and C30 are Deferred.

## Data Flow and Hot Paths

Every path 272bc83 touches is **cold**. Each one runs once per fixture, after a paid `claude -p` call that takes tens of seconds, or inside the bats test suites.

- **Generator** (`generate_one`, once per fixture): it makes 3 `jq` processes over the transcript. The report extraction (`:252`) and `result_state` (`:256`) are lenient and unchanged. The verdict (`:286-291`) is one `jq -n -L` program through `transcript.jq`. That program slurps every event (`t::events`) and then evaluates `t::problems` **three** times (`:287` ×2 and the guard at `:290`), `t::init` twice (`:288`, `:289`) and `t::deny_record_counts` once. jq does not memoize a `def`, so each reference re-walks the event array.
- **Eval checks** (once per `tool_called:` / `no_tool_called:` / `mode1_equiv:` check). Each check makes 3 `transcript_jq` processes, and each process re-slurps and re-validates the whole transcript. `tool_inputs_checked` = `transcript_checked` (which evaluates `t::problems` twice), `transcript_tool_inputs` and `known`. `assert_mode1_equiv` = `transcript_checked`, `deny_record_counts` and the command extraction, then one `python3`.
- **Realistic N.** The committed arithmetic-eval set has 5 `mode1_equiv:` fixtures plus one `no_tool_called:Bash`, and a deny-record run makes a handful of Bash calls. At N = 10, one `jq` process costs 25–35 ms, which is almost all process start. So the per-fixture grading cost is on the order of 100–200 ms. At that size, nothing in this review matters in absolute terms. The findings concern how the cost grows and whether the redundant work is legible.

## Findings

#### F1 — The generator's verdict evaluates `t::problems` three times and `t::init` twice in one program

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:286-291`, and the same pattern at `test/skills/eval-helpers.bash:396`
**Move:** 1 (hidden multiplication)
**Classification:** Micro (a constant 3× on the validation walk, not a change of complexity class) / Cold path (once per fixture, after the `claude` call)
**Confidence:** High (measured; the outputs are identical)
**Baseline:** The committed program took 6,511 ms against 3,926 ms when `problems` and `init` are bound once, at N = 40,000 (54.5 MB). At N = 2,000 it was 319 ms against 214 ms, and at N = 10 it was 35 ms against 32 ms. Both variants printed `0||bash|9.9.9|0 0 0 0` at every size. Measured in the review sandbox, 2026-09-25 (`perf-9c73ae4-transcript-jq-probes.txt`).
**Legibility-target:** for-author

Evidence (the complete verdict assignment, `generate-reports.bash:286-291`):

```bash
    verdict=$(jq -rR -n -L "$SCRIPT_DIR" 'import "transcript" as t;
      t::events | [ (t::problems | length), (t::problems | first // ""),
        (t::init | if . == null then "none" elif ((.tools // []) | type == "array" and index(["Bash"]) != null) then "bash" else "nobash" end),
        (t::init | .claude_code_version // "unknown"),
        (if (t::problems | length) == 0 then (t::deny_record_counts | "\(.undenied) \(.unseen) \(.orphans) \(.foreign)") else "" end)
      ] | join("\u001f")' "$transcript_path" 2>/dev/null) || verdict=""
```

`problems` is `[.[] | _event_problems]` (`transcript.jq:61`), a full walk of every event and content block. On its own it took 2,514 ms at N = 40,000, against 1,211 ms for `events` alone. Three evaluations account for about 2.6 s of the 6.5 s. The walk is linear, so the waste is a fixed 40% at scale and does not change the complexity class. `transcript_checked` (`eval-helpers.bash:396`) repeats the pattern with `t::problems` twice. The brief said the generator calls `problems` "twice plus deny_record_counts". The actual count is three: the `if` guard is the third.

**Recommendation:** Bind once: `t::events | (t::problems) as $p | (t::init) as $i | [ ($p|length), ($p|first // ""), …, (if ($p|length)==0 then … ) ]`. It is shorter, and it makes "one reading" literal inside the program too. Apply the same fix at `eval-helpers.bash:396`. This is optional at realistic N.

#### F2 — Each eval check makes three processes that each slurp and re-validate the whole transcript, where the old passes streamed (C33's pass item, still open)

**Severity:** Informational
**Location:** `test/skills/eval-helpers.bash:392-434` (`transcript_checked`, `tool_inputs_checked`) and `:516-540` (`assert_mode1_equiv`)
**Move:** 3 (work moved to the wrong place: streaming → slurp) and 1 (hidden multiplication: 3 processes per check)
**Classification:** Micro × Cold. It is linear in N in both time and memory, and it runs once per check after the `claude` call.
**Confidence:** High (measured)
**Baseline:** Measured in the review sandbox, 2026-09-25 (`perf-9c73ae4-transcript-jq-probes.txt`). For `tool_inputs_checked`'s three `jq` passes, the old streaming filters (the pre-272bc83 `fromjson? | select(…)` lines) took 194 ms / 10,372 KB at N = 2,000, and the new slurped passes took 420 ms / 16,148 KB. At N = 40,000 the old took 3,479 ms / 69,796 KB and the new took 7,864 ms / 271,068 KB. `assert_mode1_equiv`'s three `jq` passes took 127 ms at N = 10, 568 ms at N = 2,000, and 10,875 ms / 349,644 KB at N = 40,000.
**Legibility-target:** for-author

Evidence (`transcript_jq`, the complete function, `eval-helpers.bash:374-378`):

```bash
transcript_jq() {
  local t="$1" filter="$2"
  shift 2
  jq -rR -n -L "$EVAL_HELPERS_DIR" "$@" "import \"transcript\" as t; t::events | ($filter)" "$t"
}
```

and its three calls in `tool_inputs_checked` (excerpt `:423-428` of the function `:417-435`; the remainder is the `known`/`grep -qxF` membership test and `printf '%s' "$inputs"`, which I read):

```bash
  transcript_checked "$t" || return 1
  if ! inputs="$(transcript_tool_inputs "$t" "$tool")"; then
    echo "Could not read tool calls from $t"
    return 1
  fi
  known="$(transcript_jq "$t" 't::init | .tools // [] | if type == "array" then .[] | strings else empty end' 2>/dev/null || true)"
```

Every `transcript_jq` call starts with `t::events`, which is `[inputs | …]`, a whole-file slurp. The old `tool_inputs_checked` filters read one line at a time, and their memory was bounded by the largest single line (the result event). The new ones hold the whole event array: 271 MB peak at 54.5 MB. Fact-check Claim 10 already records that C33's "three passes where one would do" item is not fixed. 272bc83 keeps the three passes and makes each one strict, which means a full validation walk on top of the slurp. So the item is now about 2.2× the old cost, where it was about 2.8× a single pass at iteration 4. The per-process fixed cost is the same with or without the module. `jq -n 1` took 27 ms and `jq -n -L … 'import "transcript" as t; 1'` took 26 ms, so `-L` module loading is not a cost here. The cost is the number of slurps. `events`' `try fromjson catch` is not much slower than `fromjson?`: 1,211 ms against 1,118 ms at N = 40,000.

At realistic N this is about 3 × 30 ms per check. It is not a cost problem, and it does not block the merge. There is a structural point, and it is why this is not dropped. The check ("well formed, has init") and the extraction ("the Bash inputs", "the counts") come from separate parses of the same file. One `transcript_jq` call could emit a single JSON object, `{problems, init, tools, inputs}` or `{problems, init, counts, cmds}`. Then the verdict and the data it licenses would come from one read, the same argument 272bc83 makes for a single reader.

**Recommendation:** Collapse each check to one `transcript_jq` call that returns one object, with `problems` bound once (F1). Then either mark C33's pass half Fixed or leave it open by choice. Do not reintroduce streaming `reduce` with array `+=` to save memory: iteration 4 measured it as quadratic under jq 1.6 (17,266 ms against 2,396 ms at 40k).

#### F3 — (carried forward, iteration 4 F2) The strict verdict holds the whole transcript in memory

**Severity:** Informational
**Location:** `test/skills/transcript.jq:29-30` (`events`), `:81-101` (`deny_record_counts`); used by `generate-reports.bash:286`
**Move:** 4 (memory lifecycle)
**Classification:** Micro × Cold (linear, once per fixture)
**Confidence:** High (measured) / Low (that a transcript of this size is realistic)
**Baseline:** Peak RSS was 349,688 KB for the committed verdict at N = 40,000 (54.5 MB). `events` alone peaked at 256,868 KB, and iteration 4's program peaked at 314 MB on its 56 MB file. At N = 2,000 the verdict peaked at 19,984 KB. Measured in the review sandbox, 2026-09-25.
**Legibility-target:** for-author

Evidence (`transcript.jq:29-30`, the complete def):

```jq
def events: [inputs | select(test("\\S")) | . as $line | (try fromjson catch
  (if ($line | test("^\\s*[\\[{]")) then {"__unparsed": $line} else {"__text": $line} end))];
```

The strict reader has to see every event, so a slurp is inherent in the design. The only alternative that would bound memory is `reduce`, and under jq 1.6 that is quadratic (F2). `deny_record_counts` adds about 93 MB over `events` at 54.5 MB, for the id arrays and their `_set` objects. None of this has any effect at realistic N.

**Recommendation:** No action. If a transcript of hundreds of MB ever appears, drop `text` blocks and `tool_result.content` before binding. Validation would still see every block's `type`.

#### F4 — The two 13-shape table tests are the slowest tests in the fast suites; the cost is process spawns, not the 20,000-deep line

**Severity:** Informational
**Location:** `test/generate-reports.bats:627-643`, `test/skills/mode1-equiv.bats:300-318`, `test/skills/malformed-transcripts.bash:19-47`
**Move:** 1 (hidden multiplication: 13 shapes × a full generator or eval run)
**Classification:** Micro × Cold (a test-suite wall-clock cost in the `--fast` pre-gate, which `scripts/run-tests.sh` runs serially with one `bats` invocation)
**Confidence:** High (measured)
**Baseline:** `bats --timing` on 2026-09-25 in the review sandbox (`perf-9c73ae4-suite-timing.txt`, 1..78, 78 ok). Test 39 (generator table) took 2,185 ms and test 68 (mode1 table) took 2,075 ms. Together they are 4,260 ms of 19,553 ms, or 22%, for `generate-reports.bats` + `mode1-equiv.bats` + `eval-helpers-transcript.bats`. The next-slowest test took 1,190 ms. `write_malformed_transcripts` alone took 402 ms. Building the 20,000-deep line took 19 ms. Reading the `deep` shape (40,358 B) through `t::problems` took 29 ms, the same as the 344-byte `number_line` shape (32 ms).
**Legibility-target:** for-author

Evidence (`malformed-transcripts.bash:35` and `:40-45`, inside `write_malformed_transcripts` `:19-47`; the remainder is the other `case` arms and `done`, which I read):

```bash
      deep)            bad="{\"type\":\"x\",\"v\":$(printf '[%.0s' $(seq 20000))$(printf ']%.0s' $(seq 20000))}" ;;
…
    {
      printf '%s\n' "$init"
      jq -cn --arg c "$good" '{type:"assistant",message:{content:[{type:"tool_use",id:"g1",name:"Bash",input:{command:$c}}]}}'
      printf '%s\n' "$bad"
      printf '%s\n' '{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"g1","tool_input":{}}]}'
    } > "$dir/$shape.jsonl"
```

The brief asked specifically about the deep line. It is cheap both to build and to read: jq 1.6 rejects it at its parse-depth limit without walking it. Each test's time comes from about 14 full runs, one control plus 13 shapes. On the generator side that is ~150 ms per `bash "$GEN" demo`: a bash start, sourcing the runner, a stub `claude`, and 3 `jq`. On the mode1 side it is 2 `transcript_checked` processes per shape. The table writer adds 15 `jq -cn` spawns: the same `good` line recomputed 13 times, plus two shapes. These are the right tests, since the table's purpose is to run every shape end to end through both consumers, and 4 s is acceptable in a fast gate.

**Recommendation:** No action needed. If the fast gate's time becomes a concern, first compute the `good` line once, outside the loop in `write_malformed_transcripts`, which saves about 12 spawns (~350 ms per test). Keep the end-to-end runs.

## Endorsements (evidence-gated)

- `_set` (`map({(.): true}) | add // {}`) and the set lookups in `deny_record_counts` grow linearly under jq 1.6 now that ids are strings with no `tostring`. `deny_record_counts` alone took 145 / 777 / 2,931 ms at N = 2,000 / 10,000 / 40,000: 5× the data took 5.4× the time, and 4× the data took 3.8× the time. `[unverified — submitted as claim]`
- `jq -L` module loading adds no measurable per-call cost: 26 ms with `import "transcript"` against 27 ms for `jq -n 1`. `[unverified — submitted as claim]`
- `mode1-equiv.py` no longer reads the transcript. Its only input is the commands array (`commands()` → `json.loads(read_text(path))` plus a type check). This retires iteration 4's F3 (the transcript held as one string): the Python side's memory is now bounded by the size of the attempted commands. `[read: test/skills/arithmetic-eval/mode1-equiv.py:91-107]`
- The generator still makes 3 `jq` processes per transcript run (`:252`, `:256`, `:286`), the same as iteration 4. 272bc83 widened the verdict's contents but added no process. `[read: test/skills/generate-reports.bash:247-321]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | The verdict evaluates `t::problems` 3× and `t::init` 2× (not memoized): 6.5 s against 3.9 s bound once at 54 MB; the same pattern in `transcript_checked` | Informational | `test/skills/generate-reports.bash:286-291`; `test/skills/eval-helpers.bash:396` | High |
| F2 | 3 slurping, re-validating `jq` processes per eval check (C33's pass half, still open); 2.2× the old streaming cost, and 271 MB against 70 MB at 54 MB | Informational | `test/skills/eval-helpers.bash:392-434, 516-540` | High |
| F3 | (carried from iteration 4 F2) The strict verdict holds the whole transcript: 350 MB peak at 54 MB; `reduce` is not an option under jq 1.6 | Informational | `test/skills/transcript.jq:29-30, 81-101` | High / Low (size) |
| F4 | The two table tests are 22% of the three suites' time (4.3 s); the cost is spawns, and the deep line is 19 ms + 29 ms | Informational | `test/generate-reports.bats:627-643`; `test/skills/mode1-equiv.bats:300-318`; `test/skills/malformed-transcripts.bash:19-47` | High |

## Overall Assessment

272bc83 does not regress performance in any way that matters at the sizes this harness sees. Every path is cold and runs after a paid `claude` call. At realistic transcript sizes (tens of events), grading is dominated by `jq` process start: about 30 ms per process on this loaded host. All costs grow linearly: `_set` and every `transcript.jq` def scale linearly up to 54 MB, and nothing is super-linear. The strict reader's price is paid in constant factors. F1: `problems` is recomputed three times per verdict. F2: every eval check now makes three full slurps plus validation where it used to stream, about 2.2× slower, with memory proportional to the file. F4: the table tests add about 4.3 s to the fast gate, and the 20,000-deep line accounts for almost none of it. The most useful change is F2's: one `transcript_jq` call per check, with `problems` bound once (F1). It would close C33's still-open pass half, and it would make each check's verdict and its extracted data come from a single parse, which fits the commit's own "one reading" goal. None of this needs profiling, and none of it blocks the merge.

**Full remaining performance inventory for the branch:** F1–F4 here (all Informational), plus C3 and C4 (Low, open by choice). Iteration 4's F1 continues as F2 here, and its F2 continues as F3 here. Iteration 4's F3 is retired (see Endorsements).

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** This is a performance review of `main...HEAD` at 9c73ae4, focused on 272bc83, and it covers every item the brief named:
  - `problems` evaluated several times per verdict: F1. It is three times in the generator, not two, and twice in `transcript_checked`. Measured.
  - eval-helpers' 3–4 `transcript_jq` calls per check: F2. It is 3 per check, plus 1 `python3` for `mode1_equiv`. Measured against the old streaming passes.
  - The `events` slurp: F3, with its memory. `try … catch` against `fromjson?` is in F2's evidence.
  - `_set` construction: linear (endorsement, measured).
  - `jq -L` module load per call: not a cost (endorsement, measured).
  - The 13-shape table tests and the 20,000-deep line in `--fast`: F4, measured.

  The full inventory is stated above.
- **Out of scope:** I did not re-verdict Claims 26, 29, 22b or 14 (the correctness and security gaps in what the reader counts and in the `\x1f` read). They are with the orchestrator. C3 and C4 are not repeated, and settled items are not re-litigated. I ran no `claude` and no network commands, and I committed nothing. The synthetic transcripts are in the session scratchpad, not the repo.
- **Escalate:** None new from the performance lane. One observation for synthesis: F2's single-call fix would also remove a class of divergence between a check's validation and its extraction. Each call re-reads the file, so a transcript rewritten between calls could pass `transcript_checked` and then yield different inputs. This fits C29's "accidental, not concealed" framing. I did not probe it. Confidence: Low. Legibility-target: for-orchestrator-synthesis.
