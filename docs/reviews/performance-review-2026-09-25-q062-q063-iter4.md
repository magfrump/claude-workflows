Commit: 5bdee46

# Performance Review — branch skill-fixtures (Q-062 [2], Q-063 [1]), iteration 4 (user-authorized terminal pass)

**Scope:** `git diff main...HEAD` at 5bdee46, focused on the fix commit 37c5ea9, which no review has covered yet: the one-pass deny-record `jq` verdict (`test/skills/generate-reports.bash:273-302`), `tool_inputs_checked`'s new init-event pass (`test/skills/eval-helpers.bash:384-401`), mode1-equiv's type checks and `denied` set (`test/skills/arithmetic-eval/mode1-equiv.py:108-126, 159-212`), `procs_in_checkout`'s rc 4 and `agent_gate`'s `case` (`devcontainer-config/install.sh:1142-1211`), and the new tests.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (commit 5bdee46; Claims 13, 14, 24b and the "Verified" generator-jq and count rows are used here). My own timings come from the review sandbox: 16 CPUs, `/proc/loadavg` about 5.2, jq 1.6. They used synthetic transcripts of 10, 2,000, 10,000 and 40,000 Bash calls, each call carrying 1,000 bytes of text. The files were 14 KB, 2.8 MB, 14 MB and 56 MB, each with an init event and every call denied. The timings support the findings but are not execution verdicts.

C3 and C4 (the per-process forks in `procs_in_checkout`, and the unstubbed /proc scan in install-host.bats) are still open by choice, so this review does not repeat them. Iteration 3's F1 (the quadratic tripwire) and F2 (the canary's two passes) are Fixed as C28, and I checked that the fix holds (see Endorsements).

## Data Flow and Hot Paths

Every path 37c5ea9 touched is **cold**. The code is either an install-time gate or test-harness grading that runs after a paid `claude -p` call, which takes tens of seconds.

- **Deny-record verdict** (`generate-reports.bash:275-287`). This runs once per deny-record fixture run. It is one `jq -n` program that reads every event into `$ev`, builds two key sets (`$dset`, `$cset`) and emits four TSV fields. It replaces three passes: the tripwire, canary tools and canary version. So each deny-record run now parses the transcript 3 times (the report at `:245`, `result_state` at `:249`, and the verdict), not 5.
- **`tool_inputs_checked`** (`eval-helpers.bash:384-401`). This runs once per `tool_called:` / `no_tool_called:` check (callers `:423`, `:460`). The committed expected-verdicts files put at most 2 transcript checks on any one fixture. 37c5ea9 adds a third full `jq` pass (`:391`) next to `transcript_tool_inputs` (`:386`) and the `known` pass (`:395`).
- **`mode1-equiv.py`**. This runs once per `mode1_equiv:` check, which is once per fixture. The new `isinstance` guards cost a constant amount per event and per content block. `denied` is a Python set, so each membership test is O(1).
- **`procs_in_checkout` / `agent_gate`**. The loop is unchanged. `[ "$readable" -gt 0 ] || return 4` replaced an `if` that printed a NOTE, and the `case` on `rc` is a branch. Neither adds a fork or a `/proc` read.
- **New tests.** The 7 new fast-suite tests take 29–185 ms each and 743 ms in total (`bats --timing`). The three touched fast suites all pass: mode1-equiv 25/25 in 5.2 s, generate-reports 38/38 in 5.9 s and patterns 5/5 in 0.5 s, wall clock. T91 is in the slow `install-host.bats` suite and takes 466 ms, since it runs a full stubbed install.

## Findings

All three findings are Informational and none blocks the merge. They make up the full remaining performance inventory for this branch, together with C3 and C4 (open by choice).

#### F1 — `tool_inputs_checked` now parses the transcript three times per check (was two)

**Severity:** Informational
**Location:** `test/skills/eval-helpers.bash:384-401` (called from `:423` and `:460`)
**Move:** 1 (hidden multiplication), 3 (work in the wrong place)
**Classification:** Micro (a constant extra full pass) / Cold path (grading, at most 2 transcript checks per fixture)
**Confidence:** High
**Baseline:** 763 ms for `tool_inputs_checked` against 271 ms for `transcript_tool_inputs` alone, on the 14 MB synthetic transcript. At 14 KB it was 82 ms against 21 ms. Both were measured in the review sandbox on 2026-09-25. I have no baseline from real fixture transcripts.
**Legibility-target:** for-author

Evidence (the complete function):

```bash
tool_inputs_checked() {
  local t="$1" tool="$2" inputs known
  if ! inputs="$(transcript_tool_inputs "$t" "$tool")"; then
    echo "Could not read tool calls from $t"
    return 1
  fi
  # grep, not jq -e: jq's exit status reflects only the last input line.
  if ! jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | "init"' "$t" 2>/dev/null | grep -q .; then
    echo "No init event in $t: not a complete stream-json transcript"
    return 1
  fi
  known="$(jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | .tools[]?' "$t" 2>/dev/null || true)"
  if [ -n "$known" ] && ! printf '%s\n' "$known" | grep -qxF -e "$tool"; then
    echo "$tool is not a tool of this run (its tools: $(printf '%s\n' "$known" | tr '\n' ' '))"
    return 1
  fi
  printf '%s' "$inputs"
}
```

The new pass at `:391` and the `known` pass at `:395` both parse every line in order to select the same init event. Iteration 3's F3 recommended merging the passes if the Claim 16 fix restructured this function. That fix did restructure it, but it added a third pass instead. The total is about 2.8× a single pass, repeated for each transcript check. In absolute terms this costs tens of milliseconds per fixture at real transcript sizes, set against a `claude` call of tens of seconds. It is not a cost problem. The point is that the passes still diverge, since each one re-derives the init event with its own filter. One `jq` program could emit an `init` marker line, the tools and the inputs, each with a prefix. That would do the job in one pass, and the init-present and tools-known checks would then come from the same parse.

**Recommendation:** Optional. Merge the `:391` and `:395` passes into one (for example `select(init) | "I", (.tools[]? | "T\t" + .)`) the next time this function is touched. You can leave `transcript_tool_inputs` separate.

#### F2 — The one-pass verdict keeps the whole transcript in memory (about 5.6× the file size)

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:275-287`
**Move:** 4 (memory lifecycle), 2 (size of N)
**Classification:** Micro (memory proportional to the transcript, not super-linear) / Cold path (once per deny-record fixture run)
**Confidence:** High (measured), Low (that real transcripts get large enough for it to matter)
**Baseline:** Peak RSS was 314,320 KB for the new program on the 56 MB synthetic transcript and 80,364 KB on the 14 MB one. The old slurping tripwire used 69,876 KB on the 14 MB file. All measured in the review sandbox on 2026-09-25 (`ru_maxrss` of the child).
**Legibility-target:** for-author

Evidence (the full `verdict=` assignment; the enclosing `if [ "$FIXTURE_BASH" = "deny-record" ]` block continues to `:302` and was read):

```bash
      verdict=$(jq -rRn '[inputs | fromjson? | objects] as $ev
        | ([$ev[] | select(.type == "system" and .subtype == "init")] | first) as $init
        | ([$ev[] | select(.type == "result") | .permission_denials[]?
            | select(type == "object" and .tool_name == "Bash") | .tool_use_id]) as $denied
        | ($denied | map(select(. != null) | {(tostring): true}) | add // {}) as $dset
        | [$ev[] | select(.type == "assistant") | .message.content[]? | objects
           | select(.type == "tool_use" and .name == "Bash") | .id] as $calls
        | ($calls | map(select(. != null) | {(tostring): true}) | add // {}) as $cset
        | [ ($calls | map(select(. == null or ($dset[tostring] | not))) | length),
            ($denied | map(select(. == null or ($cset[tostring] | not))) | length),
            (if $init == null then "none" elif (($init.tools // []) | index("Bash")) then "bash" else "nobash" end),
            ($init.claude_code_version // "unknown") ] | @tsv' \
        "$transcript_path" 2>/dev/null) || verdict="unreadable"
```

`$ev` holds every parsed event for the whole program, including the assistant text blocks and tool results that the verdict never reads. The old tripwire already did this, so the two key sets add only about 15% on top (80 MB against 70 MB at 14 MB). This is not a regression. I tried a streaming `reduce (inputs …)` variant that keeps only the ids. It cut peak RSS to 88,412 KB at 56 MB, but under jq 1.6 its `.c += [...]` accumulation is quadratic: 17,266 ms at 40k calls against 2,396 ms for the slurp. So under the jq this sandbox ships, the slurp is the better trade. A 56 MB transcript is far beyond a five-fixture arithmetic run anyway.

**Recommendation:** No action. If deny-record ever runs on transcripts of hundreds of MB, drop the text before binding, e.g. `[inputs | fromjson? | objects | select(.type == "system" or .type == "result" or .type == "assistant")]`. Do not switch to a `reduce` with array `+=` under jq 1.6.

#### F3 — (carried forward, iteration 3 F4) `mode1-equiv.py` holds the whole transcript as one string before parsing it

**Severity:** Informational
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:90-105`
**Move:** 4 (memory lifecycle)
**Classification:** Micro (about one extra transcript-sized buffer) / Cold path (once per `mode1_equiv:` check)
**Confidence:** High
**Baseline:** Peak RSS was 253,784 KB and wall time 1,083 ms on the 56 MB synthetic transcript, and 72,200 KB and 201 ms on the 14 MB one. Measured in the review sandbox on 2026-09-25. These runs exit 1 at the Mode 1 comparison, after `events()` and `bash_calls()` have both run.
**Legibility-target:** for-author

Evidence (the complete functions):

```python
def read_text(path):
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except (OSError, UnicodeDecodeError) as e:
        raise SetupError(f"cannot read {path}: {e}")


def events(transcript_path):
    out = []
    for line in read_text(transcript_path).split("\n"):
        try:
            out.append(json.loads(line))
        except ValueError:
            continue  # a stray non-JSON line, as the other transcript checks allow
    return out
```

37c5ea9 does not change this code. I list it again only so the inventory is complete. The `isinstance` guards 37c5ea9 added to `bash_calls` (`:108-126`) and to the `denied` comprehension (`:178-183`) cost a constant amount per event and do not change the memory profile.

**Recommendation:** No action, as in iteration 3.

## Endorsements (evidence-gated)

- The C28 fix removes the quadratic cost. The new verdict took 646 ms at 10k Bash calls × 10k denials, against 18,414 ms for the old `index` tripwire on the same file. At 40k × 40k it took 2,396 ms, which is linear growth, so `map({(tostring): true}) | add` does not go quadratic under jq 1.6. It printed the same `0` undenied as the old program at every size. `[unverified — submitted as claim]`
- A deny-record run now parses its transcript 3 times, not 5: the report at `:245`, `result_state` at `:249` and the verdict at `:275`. The two canary passes from iteration 3's F2 are gone. `[read: test/skills/generate-reports.bash:243-302]`
- mode1-equiv's tripwire looks up each call in a Python `set` (`denied`), so it is O(calls + denials). The new `isinstance` guards are constant per event and per block. `[read: test/skills/arithmetic-eval/mode1-equiv.py:108-126, 159-212]`
- `procs_in_checkout`'s rc 4 and `agent_gate`'s `case` add no fork and no `/proc` read. The per-process loop is unchanged from the C3 baseline. `[read: devcontainer-config/install.sh:1156-1211]`
- The 7 new fast-suite tests add about 0.74 s in total (29–185 ms each). None of them calls `claude` or the network. T91 (466 ms) is in the slow suite. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | `tool_inputs_checked`: three full `jq` passes per check (was two); the init event is found twice | Informational | `test/skills/eval-helpers.bash:384-401` | High |
| F2 | The one-pass verdict keeps the whole transcript in memory (314 MB at 56 MB); the streaming alternative is quadratic under jq 1.6 | Informational | `test/skills/generate-reports.bash:275-287` | High (measured) / Low (realistic size) |
| F3 | (carried) `read_text` holds the whole transcript as one string | Informational | `test/skills/arithmetic-eval/mode1-equiv.py:90-105` | High |

## Overall Assessment

37c5ea9 is a net performance improvement. It removes the branch's only super-linear cost (the tripwire's `index`: 18.4 s down to 0.65 s at 10k × 10k, and linear beyond that), and it cuts a deny-record run's transcript passes from 5 to 3. The only step backwards is F1: one more cold `jq` pass per transcript check, which costs milliseconds at real sizes. Every changed path is cold and runs after a paid `claude` call. No finding needs profiling or blocks the merge. The full performance inventory for the branch is F1–F3 here (all Informational) plus C3 and C4 (Low, open by choice).

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** This is a performance review of `main...HEAD` at 5bdee46, focused on 37c5ea9. It covers each item the brief named:
  - The one-pass jq's slurp and object-set construction: measured linear (endorsement), with its memory profile in F2.
  - `tool_inputs_checked`'s added init pass: F1, measured.
  - mode1-equiv's type checks: constant cost, endorsed from reading.
  - The new tests' cost in `--fast`: 0.74 s in total, all suites green.

  I found no performance regression in the iteration-3 fixes beyond F1. The inventory is complete: F1–F3 plus C3/C4.
- **Out of scope:** C3 and C4 are not repeated. Claim 13 (mode1-equiv's traceback exits) is with the orchestrator, and I did not re-verdict it. I ran no `claude` and no network commands, and I committed nothing. The synthetic transcripts and timing scripts are in the session scratchpad, not the repo.
- **Escalate:** I found one behavior change outside the performance lane, for the orchestrator to route to security or correctness. The new key sets compare ids by `tostring`, so a tool_use with a numeric id `5` counts as denied when a denial has the string `"5"`. Probed: the new program prints `0` undenied, and the old `index` tripwire printed `1`. mode1-equiv's Python set compares ids exactly (`5 != "5"`), so the two tripwires now disagree on this input, which is another instance of C8's duplication. Real CLI ids are `toolu_…` strings, so I know of no reachable case. Confidence: Medium (probed with a hand-written transcript). Legibility-target: for-orchestrator-synthesis.
- **Questions:** None.
- **Decisions:** I gave baselines from sandbox measurements on synthetic transcripts and labelled them that way, rather than using the speculative disclaimer, because each number comes from a real run of the exact committed program. Each finding also says there is no baseline from real fixture runs.
