Commit: c7747c7

# Performance Review — branch skill-fixtures (Q-062 [2], Q-063 [1]), iteration 3 (terminal)

**Scope:** `git diff main...HEAD` at c7747c7, focused on what the iteration-2 fix commit f9feb2c changed: `procs_in_checkout`'s `readable` counter (`devcontainer-config/install.sh`), `tool_inputs_checked` / `match_inputs` / `assert_tool_called` / `assert_no_tool_called` / `assert_mode1_equiv` (`test/skills/eval-helpers.bash`), the deny-record canary (`test/skills/generate-reports.bash`), `read_text` / `SetupError` / `--check-spec` (`test/skills/arithmetic-eval/mode1-equiv.py`), and the new fast-suite tests (`test/skills/mode1-equiv.bats`, `test/generate-reports.bats`, `test/skills/arithmetic-eval-after-denial-patterns.bats`).
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (commit c7747c7; Claims 2a, 16, 17, 18, 25 used here). I also ran my own timings in the review sandbox (16 CPUs, `/proc/loadavg` about 8.6, jq 1.6, a synthetic 24 MB transcript with 20,000 assistant events and 10,000 Bash calls). They support the findings but are not execution verdicts.

C3 and C4 (the per-process forks in `procs_in_checkout`, and the unstubbed /proc scan in install-host.bats) are still open by choice. This review does not repeat them.

## Data Flow and Hot Paths

Every path f9feb2c touched is **cold**. None of it serves requests. It is either an install-time gate or test-harness grading that runs after a paid `claude -p` call, and that call takes tens of seconds.

- **`procs_in_checkout`** runs once per `agent_gate` call, and `agent_gate` runs at most 4 times per install (`install.sh:553, 780, 992, 1315`). It loops over every `/proc/[0-9]*` entry. The new `readable=$((readable + 1))` is shell arithmetic, runs once per same-uid entry with a readable cwd, and forks nothing.
- **`tool_inputs_checked`** runs once per `tool_called:` or `no_tool_called:` check. Each check makes two full `jq` passes over the fixture's transcript: `transcript_tool_inputs`, plus a new pass for the init event's `.tools[]`. The committed expected-verdicts files hold 3 `tool_called:` checks, 1 `no_tool_called:` check and 4 `subagents_min:` checks, at most 5 checks per fixture, and never more than two of them read the transcript. N is tiny.
- **`match_inputs`** is one `grep -iE -e` over inputs the function already holds. It replaced an equivalent grep.
- **The canary** runs once per deny-record fixture run and adds two full `jq` passes over the transcript (init tools, then `claude_code_version`). With the report extraction, `result_state` and the tripwire, that makes 5 passes per run.
- **`mode1-equiv.py`** runs once per `mode1_equiv:` check, which means once per fixture. `read_text` now reads the whole transcript into one string before splitting it.
- **The new fast tests** measured 44–667 ms each (`bats --timing`). The costliest are the eval_fixture dispatch test (667 ms, 8 `eval_fixture` runs), the tripwire test (391 ms), the CLAUDE_MODEL argc test (380 ms) and the CLAUDE_FLAGS refusal loop (294 ms, 9 generator invocations). All three suites f9feb2c touched passed: mode1-equiv 23/23, generate-reports 35/35, patterns 4/4.

## Findings

All four findings are Informational. None blocks the merge. They are listed for the terminal amber inventory.

#### F1 — The deny-record tripwire's `index` check is quadratic in Bash calls × denials

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:262-267`
**Move:** 9 (asymptotic behavior), 2 (size of N)
**Classification:** Macro (O(calls × denials)) / Cold path (once per fixture run, after a tens-of-seconds `claude` call)
**Confidence:** High (measured), Low (that real runs reach the size where it matters)
**Baseline:** 18,060 ms for this `jq` program over a synthetic transcript with 10,000 Bash calls and 10,000 denials, and 772 ms at 2,000 × 2,000. Both measured in the review sandbox on 2026-09-25. There is no baseline from real fixture runs, where the count is single digits.
**Legibility-target:** for-author

Evidence (the full `undenied=` assignment; the enclosing `if [ "$FIXTURE_BASH" = "deny-record" ]` block continues to :288 and was read):

```bash
      undenied=$(jq -rRn '[inputs | fromjson?] as $ev
        | ([$ev[] | select(.type == "result") | .permission_denials[]?.tool_use_id]) as $denied
        | [$ev[] | select(.type == "assistant") | .message.content[]?
           | select(.type == "tool_use" and .name == "Bash") | .id]
        | map(select(. as $id | $denied | index($id) | not)) | length' \
        "$transcript_path" 2>/dev/null) || undenied="unreadable"
```

`$denied | index($id)` scans the denial array once for each Bash id. The iteration-1 review endorsed this because both counts are single digits, and for arithmetic-eval's five fixtures that is still true. f9feb2c did not change the check, but it is the one super-linear cost left in the harness. A runaway run that loops on denied Bash calls would pay for it quadratically, and since each denied call is a model turn, the paid run would cost far more than the check. A keyed lookup gives the same answer in 499 ms at 10k × 10k in the same sandbox: `([…tool_use_id] | map({(.):1}) | add // {}) as $d | … | select($d[.] | not)`. That variant also printed `0`.

**Recommendation:** Leave it unless deny-record spreads to skills with long Bash loops. If it does, switch to the object lookup above. It is a single-expression change.

#### F2 — The canary makes two full passes over the transcript where one would do

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:280-287`
**Move:** 3 (work in the wrong place), 6 (serialization tax)
**Classification:** Micro (a constant extra pass) / Cold path (once per deny-record fixture run)
**Confidence:** High
**Baseline:** 286 ms per pass over the 24 MB synthetic transcript, measured in the review sandbox on 2026-09-25. There is no baseline from real transcripts.
**Legibility-target:** for-author

Evidence (complete canary block, :280-287):

```bash
      local init_tools cli_version
      init_tools=$(jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | .tools[]?' \
        "$transcript_path" 2>/dev/null || true)
      cli_version=$(jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | .claude_code_version // empty' \
        "$transcript_path" 2>/dev/null | head -n 1 || true)
      if ! printf '%s\n' "$init_tools" | grep -qx Bash; then
        failure="${failure:+$failure; }Bash canary: the init event does not list Bash (CLI ${cli_version:-unknown}; did the deny rule remove the tool?)"
      fi
```

Both commands parse every line to find the same init event, and the `head -n 1` does not stop the second `jq` early. Each deny-record run now parses the transcript 5 times: report, `result_state`, tripwire, and the two canary passes. At realistic sizes of tens to hundreds of KB this costs milliseconds against a `claude` call of tens of seconds, so it does not matter today. One pass can emit both values, for example `select(…init) | (.tools[]? | "T " + .), ("V " + (.claude_code_version // ""))`, and bash can split them afterwards. A jq `first(inputs …)` early exit gave no gain under jq 1.6 (340 ms), so combining the two passes is the only saving available.

**Recommendation:** Optional: fold the two passes into one. Only worth doing if the canary is touched again for another reason.

#### F3 — Each transcript check re-reads the whole transcript twice (`tool_inputs_checked`)

**Severity:** Informational
**Location:** `test/skills/eval-helpers.bash:381-393`, called from `:412-426` and `:449-462`
**Move:** 1 (hidden multiplication)
**Classification:** Micro (a second full pass per check) / Cold path (grading, at most 2 transcript checks per fixture)
**Confidence:** High
**Baseline:** 701 ms for `tool_inputs_checked` against 379 ms for `transcript_tool_inputs` alone, over the 24 MB synthetic transcript, measured in the review sandbox on 2026-09-25. There is no baseline from real transcripts.
**Legibility-target:** for-author

Evidence (the complete function):

```bash
tool_inputs_checked() {
  local t="$1" tool="$2" inputs known
  if ! inputs="$(transcript_tool_inputs "$t" "$tool")"; then
    echo "Could not read tool calls from $t"
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

The init lookup is a second full `jq` pass, and it repeats for every `tool_called:` and `no_tool_called:` check on the same transcript. The multiplier is checks per fixture, at most 2 transcript checks in the committed files. So the realistic cost is under 100 ms per fixture even for a multi-MB sub-agent transcript: `assert_no_tool_called` took 993 ms and `assert_tool_called` 1,239 ms end to end at 24 MB. A single `jq` program could return the init tools and the matching inputs together, with a marker prefix. It would also be the natural place to fix fact-check Claim 16 (a junk or init-less transcript reads as zero calls), because one pass could count parsed lines and init events and fail on zero. That fix is a correctness matter for the orchestrator, not a performance one.

**Recommendation:** No action needed for performance. If Claim 16's fix restructures this function, merge the two passes then.

#### F4 — `mode1-equiv.py` holds the whole transcript as one string before parsing it

**Severity:** Informational
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:87-102`
**Move:** 4 (memory lifecycle)
**Classification:** Micro (roughly one transcript-sized buffer) / Cold path (once per `mode1_equiv:` check)
**Confidence:** High
**Baseline:** peak RSS rose from 78,516 KB (8664e22's version) to 100,240 KB (c7747c7's) on the 24 MB synthetic transcript, measured in the review sandbox on 2026-09-25 (`ru_maxrss` of the child). Wall time went from 0.18 s to 0.20 s.
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

Routing the transcript through `read_text` made the old streaming loop (`for line in open(...)`) into `f.read()` plus `split("\n")`. At the peak the process holds both the string and the list, which adds about one transcript's size. `events()` already materialized every parsed event before this change, so the growth is bounded at roughly 1.3× and cannot run away. This is the correct price for turning a mid-read `UnicodeDecodeError` into exit 2 (fact-check Claim 13 verified the exit code). Streaming with the `try` around the loop would keep both properties.

**Recommendation:** No action. If transcripts ever reach hundreds of MB, stream inside a `try` that raises `SetupError`.

## Endorsements (evidence-gated)

- The `readable` counter in `procs_in_checkout` is shell arithmetic inside the existing loop. It adds no fork and no extra `/proc` read per process, so the blind-scan NOTE comes at no measurable cost on top of C3's existing per-process `readlink`. `[read: devcontainer-config/install.sh:1151-1170]`
- The NOTE fires exactly when the count of readable same-uid cwds is zero, and the gate then goes on as for a clean scan. It adds no retry and no extra pass. `[fact-check: claim 2a — Verified]`
- `match_inputs` makes the same single `grep -iE` pass as before, and checking exit 2 adds no work on the success path. `[fact-check: claim 18 — Verified]`
- The canary and the tripwire run only under `FIXTURE_BASH=deny-record`, once per fixture, after the `claude` call returns, so non-deny-record skills pay nothing for them. `[read: test/skills/generate-reports.bash:239-289]`
- The iteration-2 tests add about 3 s in total to the fast suites. The largest single test is 667 ms, the `--check-spec` pre-flight is 167 ms for 4 specs, and none of the new tests calls `claude` or the network. `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Tripwire `index` is O(Bash calls × denials) | Informational | `test/skills/generate-reports.bash:262-267` | High (measured) / Low (realistic N) |
| F2 | Canary: two full `jq` passes where one would do | Informational | `test/skills/generate-reports.bash:280-287` | High |
| F3 | `tool_inputs_checked`: a second full `jq` pass per transcript check | Informational | `test/skills/eval-helpers.bash:381-393` | High |
| F4 | `read_text` holds the whole transcript in memory (+22 MB at 24 MB) | Informational | `test/skills/arithmetic-eval/mode1-equiv.py:87-102` | High |

## Overall Assessment

f9feb2c is performance-neutral. Every change sits on a cold path: a counter inside the existing /proc loop, two to three extra `jq` passes per fixture after a paid `claude` call, one extra transcript-sized buffer in the checker, and about 3 s of new fast-suite tests with no network. None of it scales with anything a real run produces in quantity. The one super-linear cost in the harness is F1, the tripwire's quadratic `index`. It predates f9feb2c, stays sub-second below about 2,000 calls, and has a one-expression linear fix if deny-record ever spreads to Bash-heavy skills. C3 and C4 remain the only install-side costs that grow with size, and they are open by choice. Nothing here needs profiling before the merge.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** This is a performance review of `main...HEAD` at c7747c7, focused on f9feb2c. It covers each item the brief named: the `readable` counter (endorsed, no fork), `tool_inputs_checked`'s extra `jq` pass (F3, measured), the canary's two passes (F2, measured), the pre-flight and dispatcher tests' cost in the fast suite (measured with `bats --timing`: about 3 s in total, all green) and the new eval-helpers helpers under many checks (N is at most 2 transcript checks per fixture). A terminal-pass sweep found two more: F1, the quadratic tripwire from iteration 1, measured at scale, and F4, the checker's memory. All four findings are Informational. I found no regression in the iteration-2 fixes on performance grounds.
- **Out of scope:** C3 and C4 (not repeated). The failing fast gate from Claims 8 and 29c is with the orchestrator. The blind-scan NOTE versus PID namespaces (Claim 2b) is with security. I did not re-verdict Claim 16's fail-open on junk transcripts; F3 only notes that fixing it and merging the passes would touch the same function. I ran no `claude` or network commands and committed nothing. The synthetic transcripts are in the session scratchpad, not the repo.
- **Escalate:** None new. One observation outside the performance lane, for the orchestrator to route if wanted: `agent_gate` runs up to 4 times per install, so a blind /proc scan prints the two-line NOTE up to 4 times (`install.sh:553, 780, 992, 1315` → `:1166-1169`). This is a UX repetition, not a cost. Confidence: Medium (read, not run). Legibility-target: for-orchestrator-synthesis.
- **Questions:** None.
- **Decisions:** I gave baselines from sandbox measurements on synthetic transcripts and named them as such, rather than using the speculative disclaimer, because each number comes from a real run of the exact code. Each finding also says there is no baseline from real fixture runs.
