Commit: 1a513a8

# Performance Review — Unit A (feat/hook-refuse-redirects, auto-approve AST-shape gate)

**Scope:** `git diff main...HEAD` at 1a513a8, which covers `hooks/auto-approve-allowed-commands.sh` (SHAPE_FILTER, `refuses_construct`, REFUSE_CONSTRUCTS gate, empty-extraction branch, slash rule). Tests and docs were read for context only.
**Date:** 2026-09-28
**Based on:** `docs/reviews/code-fact-check-report-unitA-pass2-033ccd6.md`, the latest fact-check. It makes no performance claims. No fact-check exists at 1a513a8, so the runtime numbers below come from this review's own measurements.

## Method (measured, not estimated)

- **Hooks compared:** `git show main:hooks/auto-approve-allowed-commands.sh` against the HEAD copy of the same file. Both ran as `hook --permissions '[git,ls,grep,echo,cat,head,bash,true …]' --deny '[]'`, with JSON on stdin, from a Python harness (`time.perf_counter`, one warm-up run, then N runs, median reported). Host: WSL2, 16 cores, shfmt v3.13.1, jq-1.6. Scripts and raw output are in the session scratchpad (`perfA/bench.py`, `bench2.py`, `comp.sh`, `loop.sh`, `jqcost.py`). They are not committed.
- **Process counts:** PATH shims (`#!/bin/sh` wrappers for jq, shfmt and perl) logged each exec. Bash-internal forks (`$(…)`, `<(…)`) are not counted.
- **Caveat:** This is a noisy, shared WSL2 host. The p10–p90 spread on small commands is about ±15 ms. The ~41 ms delta holds across three separate runs (N=15, N=15, N=30).

## Data Flow and Hot Paths

The hook is a PreToolUse hook on **every** Bash tool call in every session (`hooks/wiring.json:77`). That makes it a hot path, with an agent waiting on it synchronously each time. For each call the hook: reads the settings rules with jq, runs perl to normalise the command, runs `shfmt -tojson`, and runs one jq extraction pass over the AST. HEAD adds `refuses_construct` between shfmt and the extraction. That function runs **one jq pass for SHAPE_FILTER**. If that pass finds nothing to refuse, it runs **a second jq pass to list redirects**, then a bash loop over the redirects that slices bytes out of the command. When a shape is refused, the function returns before the redirect pass and before the extraction pass. Typical commands are 10 B to a few KB, with 0–3 redirects and 1–10 statements.

Measured end to end (`bench2.py`, N=30, median ms, with p10–p90):

| case | bytes | main | HEAD | delta | decision main/HEAD |
|---|---|---|---|---|---|
| `git status` | 10 | 101.1 (88–108) | 142.5 (127–159) | **+41.4** | allow/allow |
| `ls -la \| grep foo \| head -5` | 27 | 98.9 (85–112) | 139.9 (124–159) | **+41.1** | allow/allow |
| `git log --oneline -5 2>/dev/null && echo done` | 45 | 101.8 (92–120) | 144.7 (132–161) | **+42.9** | allow/allow |
| 100 lines `echo x 2>/dev/null` | 1899 | 196.0 | 307.6 | +111.6 | allow/allow |
| 100 lines `echo x` | 699 | 187.0 | 255.1 | +68.1 | allow/allow |
| 1000 lines `echo x 2>/dev/null` | 18999 | 1096.2 | 1846.5 | +750.2 | allow/allow |
| 1000 lines `echo x` | 6999 | 1007.6 | 1489.1 | +481.5 | allow/allow |
| 4000 lines `echo x 2>/dev/null` | 75999 | 4284.1 | 8268.7 | +3984.5 | allow/allow |

From `bench.py` (N=15, median ms), with external execs counted as jq/shfmt/perl:

| case | main | HEAD | delta | execs main | execs HEAD |
|---|---|---|---|---|---|
| `bash -c 'ls \| grep x'` | 132.2 | 102.8 | −29.4 | 9 (5/2/2) | 6 (4/1/1) |
| `echo "$(git rev-parse HEAD)"` (refused on HEAD) | 104.7 | 97.1 | −7.6 | 6 (4/1/1) | 6 (4/1/1) |
| 200-line heredoc (7.5 KB) | 95.6 | 152.2 | +56.6 | 6 (4/1/1) | 8 (6/1/1) |
| 2000-line heredoc (77 KB) | 116.2 | 166.3 | +50.1 | 6 | 8 |
| 50-stage pipeline | 169.8 | 264.9 | +95.1 | 6 | 8 |
| 50 `&&` commands each `2>/dev/null` | 157.7 | 265.0 | +107.3 | 6 | 8 |
| 200-stage pipeline / 200 `&&` | 242.5 / 289.7 | 343.8 / 487.0 | +101 / +197 | 6 | 6 (fail closed on both, see F4) |

Every approvable command costs exactly **+2 jq execs** on HEAD. A refused command costs the same as main (6). `bash -c` now costs 3 fewer execs, because it is refused before recursion.

## Findings

#### F1. Two extra jq processes on every approvable Bash call add ~41 ms (+~41%)

**Severity:** Medium
**Location:** `hooks/auto-approve-allowed-commands.sh:813`, `:837-838` (called from `:769`)
**Move:** Find the work that moved to the wrong place / Serialization tax
**Classification:** Micro (fixed per-call process startup and AST re-parse) / Hot path (PreToolUse on every Bash tool call)
**Confidence:** High
**Legibility target:** hook maintainer deciding whether to merge the three jq passes. The per-call cost is not mentioned in the header's "Cost:" line, which lists only prompt-frequency costs.
**Baseline:** median hook latency 101.1 ms for `git status` on main vs 142.5 ms on HEAD (N=30, `perfA/bench2.py`, 2026-09-28, this host)

**Evidence:**
```
  reason=$(jq -r "$SHAPE_FILTER" <<<"$ast") || reason="shape check failed"
```
```
  done < <(jq -r '.. | objects | select(has("Redirs")) | .Redirs[]?
                  | "\(.OpPos.Offset) \(.Word.Pos.Offset) \(.Word.End.Offset)"' <<<"$ast")
```
```
  # Extract commands using jq (always newline-separated internally)
  echo "$ast" | jq -r "$JQ_FILTER" 2>/dev/null
```

Each approvable command now parses the same shfmt AST three times, in three separate jq processes. jq-1.6 startup costs about 20.7 ms here (`jq -n 1`, median of 40 runs, `perfA/jqcost.py`). The SHAPE_FILTER pass measures 26.8 ms and the redirect-list pass 20.8 ms on a 7 KB AST. Nearly all of the added ~41 ms is therefore process startup, not filter work. The shim counts confirm it: 6 execs on main, 8 on HEAD, for every approvable case. The cost is paid on every allowed Bash call in every session, and it lands on calls the hook *does* approve, which are the reason the hook exists. Relative to the ~100 ms baseline, that is ~40% slower. Because the micro cost runs at extreme frequency, it rises from Low to Medium.

**Recommendation:** Emit the shape verdict and the redirect offsets from one jq program. For example, print the reason, or a `R <offsets>` line per redirect. One redirect-listing pass would then disappear: measured, ≈20 ms of the 41. Going further, fold both into the existing JQ_FILTER pass with a tagged-line protocol. That brings HEAD back to main's exec count, but it means a larger rework of `extract_commands_raw`. Re-measure against the 101 ms / 142 ms baseline afterwards.

#### F2. The redirect slicing loop is O(redirects × command length)

**Severity:** Low
**Location:** `hooks/auto-approve-allowed-commands.sh:818-838`
**Move:** Check the asymptotic behavior, not just the constant
**Classification:** Macro (quadratic in input size) / Hot path, but the input size is bounded in practice by what an agent writes in one Bash call
**Confidence:** High (measured per-redirect cost grows with command length)
**Legibility target:** hook maintainer. Nothing in the function comment signals that per-redirect cost depends on command length.
**Baseline:** isolated loop cost 2.1 ms for 100 redirects, 79.1 ms for 1,000, 1,073.8 ms for 4,000 and 17,719.6 ms for 16,000 (`perfA/loop.sh`, `LC_ALL=C`, same slicing statements as the hook, 2026-09-28)

**Evidence:**
```
  while read -r op_off word_off word_end; do
    op=${cmd:op_off:word_off-op_off}
    op=${op//[[:space:]]/}
    word=${cmd:word_off:word_end-word_off}
```

Each `${cmd:off:len}` measured as linear in `${#cmd}`, not constant. The per-redirect cost went 0.021 → 0.079 → 0.268 → 1.107 ms as redirects (and the command length with them) went 100 → 1,000 → 4,000 → 16,000. That is roughly 4× per 4× step, so the loop as a whole is quadratic. It explains about 1 s of the +3.98 s delta at 4,000 lines. The rest is F1/F3 (jq re-parses). Realistic commands have fewer than 10 redirects, where the loop costs well under 1 ms. The effect only shows in generated scripts with thousands of redirects, and the outcome is a slow approval or prompt, not a wrong decision. So this is Low.

**Recommendation:** No change is needed at current sizes. If it is revisited, have jq emit the operator text and word text directly (for example, pass the command as `--arg` and slice with `.[a:b]` inside jq, which also works in bytes only if the command is passed as bytes). Otherwise, cap the command length the hook will attempt, above which it falls through to the prompt.

#### F3. The added passes scale with the AST, which shfmt pretty-prints with depth-proportional indentation

**Severity:** Low
**Location:** `hooks/auto-approve-allowed-commands.sh:755`, `:813`, `:837`
**Move:** What's the size of N? / Serialization tax
**Classification:** Micro-per-byte, linear in AST bytes / Hot path. AST bytes grow super-linearly with pipeline depth.
**Confidence:** High for the measurements. Medium for the attribution of the byte blow-up to indentation, which is inferred from the growth curve and not read in shfmt's source.
**Legibility target:** hook maintainer sizing the jq-pass merge in F1
**Baseline:** AST 7,240 B for a 3-stage pipeline, 468,830 B for 50 stages, 6,201,784 B for 200 stages and 93,943,384 B for 800 stages (`perfA/comp.sh`, shfmt v3.13.1). End-to-end HEAD delta: +95.1 ms at 50 stages and +750.2 ms at 1,000 flat lines.

**Evidence:**
```
  if ! ast=$(echo "$cmd" | shfmt -ln bash -tojson 2>&1); then
```
```
  reason=$(jq -r "$SHAPE_FILTER" <<<"$ast") || reason="shape check failed"
```

Every extra jq pass re-parses the full AST string, and bash copies it through a here-string each time. On flat input the jq cost is linear: SHAPE_FILTER took 61 ms, 478 ms and 1,606 ms at 100, 1,000 and 4,000 lines. For nested pipelines and `&&` chains, the JSON grows roughly with depth² (a ×16 depth step gave ×200 bytes). So each added pass costs more than the command's length suggests. The fixed ~41 ms dominates for ordinary commands. This matters from about 50 stages or 100 statements upward.

**Recommendation:** Same fix as F1. Fewer passes over the same AST shrink this proportionally. Piping shfmt through a single compact re-serialisation would add a pass rather than remove one, so do not do that.

#### F4. Deep pipelines and `&&` chains fail closed on jq's depth limit (pre-existing, not a regression)

**Severity:** Informational
**Location:** `hooks/auto-approve-allowed-commands.sh:774` (main's pass). HEAD's `:813` hits the same limit first.
**Move:** What's the size of N?
**Classification:** Macro / Hot path, but fail-closed and pre-existing on main
**Confidence:** High
**Legibility target:** future reader of the latency tables. Timings at ≥~100 stages measure the failure path, not approval.
**Baseline:** no baseline available — flagged as speculative (for how often agents emit such commands). The failure itself is measured: `parse error: Exceeds depth limit for parsing at line 1842, column 137` from jq-1.6 on the 100-, 200-, 400- and 800-stage pipeline ASTs.

**Evidence:**
```
  reason=$(jq -r "$SHAPE_FILTER" <<<"$ast") || reason="shape check failed"
```

The 200-stage pipeline, and 200 or more `&&`-joined commands, fall through to a prompt on both main and HEAD. At 800 stages, HEAD takes 4.6–5.0 s to reach that prompt, against 2.1–2.4 s on main. Most of that time is shfmt producing 94 MB of JSON plus bash copying it. The limit is safe, because the hook fails closed, and the diff did not introduce it. It is recorded so the scaling rows above are not read as approval latency.

**Recommendation:** None for this unit. If long chains matter later, a length or depth cap before shfmt would turn a multi-second failure into an immediate fall-through.

## Endorsements

- The HEAD path returns before the redirect pass and before JQ_FILTER when SHAPE_FILTER yields a reason. A refused command therefore spawns no more processes than main did: 6 execs in both, measured. `[read: hooks/auto-approve-allowed-commands.sh:769-774, 810-817]`
- `bash -c`, `sh -c` and `env …` are refused at the outer level. On the hook path, `extract_commands_from_string` therefore no longer runs a second shfmt/perl/jq round per recursion level: 9 execs on main and 6 on HEAD for `bash -c 'ls | grep x'`, 132 ms against 103 ms. `[read: hooks/auto-approve-allowed-commands.sh:720-723, 769-771, 894-901]` Whether the recursion is *never* reached with REFUSE_CONSTRUCTS on is a categorical claim that this review did not verify for every name form. `[unverified — submitted as claim]`
- The redirect loop runs in the hook's own shell, with no fork per redirect. Its cost is bash string slicing only, which is sub-millisecond below about 100 redirects (measured 2.1 ms at 100). `[read: hooks/auto-approve-allowed-commands.sh:818-838]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Two extra jq execs per approvable call: +41 ms median (~+41%) | Medium | `hooks/auto-approve-allowed-commands.sh:813,837` | High |
| 2 | Redirect slicing loop is O(redirects × length) | Low | `hooks/auto-approve-allowed-commands.sh:818-838` | High |
| 3 | Added passes re-parse an AST that grows ~depth² for chains | Low | `hooks/auto-approve-allowed-commands.sh:755,813,837` | High |
| 4 | jq-1.6 depth limit makes ≥~100-stage chains fail closed (pre-existing) | Informational | `hooks/auto-approve-allowed-commands.sh:774,813` | High |

## Overall Assessment

The unit's performance posture is acceptable and fixable in place. The one real cost is F1: a flat ~41 ms (≈+41%) added to every approved Bash call, from two more jq process startups over an AST that has already been parsed. It sits on the hottest path in the harness. Merging the redirect listing into the SHAPE_FILTER pass would recover about half of it (≈20 ms, measured jq startup). Folding both into JQ_FILTER would recover nearly all of it. That merge is worth doing, but it does not block a security fix: the latency is below what an agent notices per call, and every refused shape is no slower than main. Nothing is O(n²) at realistic command sizes. The redirect loop's quadratic term (F2) shows only past about 1,000 redirects. Large commands already cost seconds on main, from per-line bash loops and shfmt, and HEAD roughly doubles that (F3). No further profiling is needed to act on F1. After any merge, re-run `bench2.py` against the 101/142 ms baseline.

## Goal-Alignment Note
- Success criterion (restated verbatim): A critique saved to /workspace/.claude/wt-hook-a/docs/reviews/performance-review-2026-09-28-unitA.md with `Commit: 1a513a8` at the top, structured per the performance-reviewer skill, every finding with Severity/Confidence/Legibility-target and a verbatim Evidence field, and a Goal-Alignment Note at the end.
- Answered: I timed main against HEAD for typical commands, a 200-line and a 2000-line heredoc, 50- to 800-stage pipelines, `&&` chains and flat multi-line scripts. I counted spawned jq/shfmt/perl processes per case (+2 jq on every approvable command, −3 for `bash -c`). I isolated the jq pass costs and jq startup, and measured the redirect loop's asymptotics (quadratic, F2). The re-parse question is F1/F3: three jq passes over the same AST. Per-recursion-level cost: recursion no longer happens on the hook path for the `bash -c` forms tested.
- Out of scope: security correctness of the shape gate, which belongs to the security critic and the fact-check. Main's pre-existing per-line costs (≈1 s per 1,000 lines on main). Claude Code's hook timeout: the default is assumed to be 60 s and was not checked, and the worst measured case here is 8.3 s.
- Escalate: None blocking. F1 is a merge-or-accept call for the author. If the ~41 ms per call is acceptable for a security fix, record it in the header's "Cost:" line so the trade is visible.
