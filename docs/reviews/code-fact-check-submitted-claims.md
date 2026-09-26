**Commit:** 5bdee46

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** submitted claims only (security-reviewer, review-fix loop iteration 4 of 4, terminal pass), read against `git diff main...HEAD` (skill-fixtures); `test/skills/generate-reports.bash`, `test/skills/arithmetic-eval/mode1-equiv.py`, `devcontainer-config/install.sh`
**Commit:** 5bdee46
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-09-25
**Total claims checked:** 4 (3 submitted; Claim 26 split into 26a/26b on verdict divergence)
**Summary:** 2 verified, 1 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

This report is a supplement to `docs/reviews/code-fact-check-report.md`, which ends at Claim 24d. So numbering continues at 25. No claims were harvested from the diff. I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) first. None of the three submitted claims quotes a measured value or names a symbol, so none matches a logged pattern.

The execution logs are `docs/reviews/execution-logs/cfc-5bdee46-submitted-*`, with each probe script next to its log. Every command ran with cwd `/workspace`. Tools: jq 1.6, bash 5.2.15, Python 3.11.2. No `claude` or network command was run. The Claim 27 fork-failure reproduction lowers `RLIMIT_NPROC` only inside the one scan subshell under test, so no other sandbox process is limited.

---

## Submitted Claims

## Claim 25: "In the one-pass jq, a deny-record run is voided when a Bash tool_use at `.message.content[]` is absent from the Bash-named denials, when a Bash-named denial names an id not seen at that path, when there is no init event, or when the init tools array lacks \"Bash\". A jq failure is voided as \"could not be read\"."

**Submitted by:** security-reviewer
**Location:** `test/skills/generate-reports.bash:273-302`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers all four voiding conditions and the unreadable arm. They were run end to end through the real generator (HEAD copy) with a stub `claude`, and each writes `<fixture>.failed`. Also covers the fact that runner-contract forces `FIXTURE_TRANSCRIPT=1` under deny-record, so this block always runs for such a run. Not established: tool_use blocks in non-`assistant` events, which are not counted; ids that are equal only after `tostring`; a non-array `tools`; lines that jq 1.6 drops without failing (F3); tool_use off the `.message.content[]` path with no denial (F2); jq ≥1.7.

The jq program, quoted:

```bash
# test/skills/generate-reports.bash:275-287
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

Each count and state is mapped to a `failure` string (`:289-301`, e.g. `[ "$undenied" = 0 ] || failure=…"Bash tripwire: …"`). A non-empty `failure` is written to `$failed_path` (`:306-307`). I read the whole enclosing `generate_one()` (`:139-314`). The block sits inside `if [ "$FIXTURE_TRANSCRIPT" = 1 ]` (`:240`). `test/skills/runner-contract.bash:117-120` refuses deny-record without `FIXTURE_TRANSCRIPT=1` (`"FIXTURE_BASH=deny-record needs FIXTURE_TRANSCRIPT=1"`), so this block runs for every deny-record run.

End-to-end probes, each running the real script with a stub `claude` (`cfc-5bdee46-submitted-c25-gen.txt`, 2026-09-26T04:57:13Z, exit 0):

- **Undenied call:** A02 (`[]` denials), A03 (denied only under `tool_name` `Read`), A04 (null id) and A20 (sub-agent event) → `VOIDED: Bash tripwire: 1 Bash call(s) not in permission_denials`.
- **Denial names an unseen id:** A05 and A06 (null `tool_use_id`) → `VOIDED: Bash parser canary: 1 Bash denial(s) name a tool_use the parser did not see`.
- **No init event:** A07 → `VOIDED: no init event in the stream (the run did not start?)`.
- **Init does not list Bash:** A08 (`[]`), A09 (no key), A10 (`["Bash(**)"]`), A11 (`["bash"]`), A13 (the first of two inits lacks it) → `VOIDED: Bash canary: the init event does not list Bash`. A12 (`["Read","Bash"]`) is not voided.
- **jq failure:** A16 (an event whose `message` is a string, so jq exits non-zero) → `VOIDED: Bash tripwire: the transcript could not be read`.
- **Already-failed run:** A18b (stub exits 3) → `claude exited 3; Bash tripwire: 1 …`. The tripwire still runs.

Where the claim is imprecise:

1. **"a Bash tool_use at `.message.content[]`" is counted only in `assistant` events** (`select(.type == "assistant")`, `:280`). A19 (an undenied Bash tool_use at `.message.content[]` of a `"type":"user"` event) → `NOT VOIDED`.
2. **"absent from" is decided on `tostring`** (`{(tostring): true}`, `:279`, `:282`). A21 (call id `1` as a number, denial `"1"` as a string) → `NOT VOIDED`. This is the security review's F4/M4.
3. **"the init tools array lacks Bash" assumes an array.** `index("Bash")` on a string is a substring search. A14 (`"tools":"NotBash"`) → `NOT VOIDED`. An object `tools` (A15) is voided as nobash rather than erroring.

The CLI is not known to emit any of these three shapes: tool_use only in assistant events, string ids, a `tools` array. So the mechanism and the conclusion hold for the shapes the claim names. Precise version: "a Bash tool_use at `.message.content[]` **of an `assistant` event** whose id (compared as `tostring`) is absent …; … when the init event's `tools` (an array) has no `"Bash"` element".

The bounds the critic already stated also reproduce. A23 (a lone-surrogate line, F3) and A24 (tool_use under `.message.blocks` with no denial, F2) → `NOT VOIDED`. These are dropped or unseen inputs, not jq failures, so the unreadable arm does not apply to them. A22 (init only at the end of the stream) is not voided, which matches Stage-1 Claim 20c (position is not checked).

**Evidence:** `test/skills/generate-reports.bash:139-314`, `test/skills/generate-reports.bash:275-287`, `test/skills/generate-reports.bash:289-301`, `test/skills/generate-reports.bash:306-307`, `test/skills/runner-contract.bash:117-120`, `docs/reviews/execution-logs/cfc-5bdee46-submitted-c25-gen.sh`, `docs/reviews/execution-logs/cfc-5bdee46-submitted-c25-gen.txt`. Command: `bash docs/reviews/execution-logs/cfc-5bdee46-submitted-c25-gen.sh`, cwd `/workspace`, exit 0, 2026-09-26T04:57:13Z.

---

## Claim 26a: "No Claim 13 shape (number-valued `permission_denials`, list `tool_use_id`, object `id`, … a >1000-deep line) makes mode1-equiv exit 0. Each exits 1 or 2." (the four crashing shapes)

**Submitted by:** security-reviewer
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:98-207`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a non-zero number for `permission_denials`, a list `tool_use_id` in a denial, an object `id` on a Bash tool_use, and a 1200-deep line. Each exits 1 even next to a correct, denied Mode 1 call. Not established: `permission_denials: 0`, which is falsy and read as empty, so it exits 0 next to a good call (benign, because it hides no call); depths between 1001 and 1199; Python versions other than 3.11.2; the exit-1-means-model-result misreading (Stage-1 Claim 13).

Each of these crashes the whole script, whatever else the transcript holds. The tripwire comprehension iterates every result event and hashes every id, outside the `try`:

```python
# test/skills/arithmetic-eval/mode1-equiv.py:178-183
    denied = {d.get("tool_use_id") for ev in evs
              if isinstance(ev, dict) and ev.get("type") == "result"
              for d in (ev.get("permission_denials") or []) if isinstance(d, dict)}
    denied.discard(None)
    # A call with no id counts as undenied (review iteration 3, C28).
    undenied = [cid for cid, _ in calls if cid is None or cid not in denied]
```
(excerpt ends :183; enclosing main() :159-207 — read)

`events()` catches only `ValueError` (`except ValueError:`, `:103`), so a `RecursionError` from `json.loads` propagates.

Probes (`cfc-5bdee46-submitted-c26-mode1.txt`, 2026-09-26T04:52:36Z): each shape was run alone and again appended to a transcript holding a correct, denied Mode 1 call (`2+3`, expected `5`; baseline B00 rc=0):

- S1 `permission_denials = 5`: rc=1 in both, `TypeError: 'int' object is not iterable`
- S2 list `tool_use_id`: rc=1 in both, `unhashable type: 'list'`
- S3 object `id`: rc=1 in both, `unhashable type: 'dict'`
- S7 1200-deep line: rc=1 in both, `RecursionError`

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:98-105`, `test/skills/arithmetic-eval/mode1-equiv.py:108-126`, `test/skills/arithmetic-eval/mode1-equiv.py:159-207`, `docs/reviews/execution-logs/cfc-5bdee46-submitted-c26-mode1.py`, `docs/reviews/execution-logs/cfc-5bdee46-submitted-c26-mode1.txt`. Command: `python3 docs/reviews/execution-logs/cfc-5bdee46-submitted-c26-mode1.py`, cwd `/workspace`, exit 0, 2026-09-26T04:52:36Z.

---

## Claim 26b: "No Claim 13 shape (… non-object event, string `message`/`content` …) makes mode1-equiv exit 0. Each exits 1 or 2." (the three skipped shapes)

**Submitted by:** security-reviewer
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:108-126`
**Type:** Error-handling / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers these three shapes alone and inside a transcript that also holds a correct, denied Mode 1 call. Not established: whether the CLI ever emits a non-object event, or a string `message`/`content` that carries a tool call (no `claude` run); the eval-helpers `no_tool_called` reader.

These shapes exit 1 only when they are the whole transcript. `bash_calls` skips them rather than rejecting them:

```python
# test/skills/arithmetic-eval/mode1-equiv.py:112-119
    for ev in evs:
        if not isinstance(ev, dict) or ev.get("type") != "assistant":
            continue
        message = ev.get("message") or {}
        content = message.get("content") if isinstance(message, dict) else None
        for block in content if isinstance(content, list) else []:
            if not isinstance(block, dict):
                continue
```
(excerpt ends :119; enclosing bash_calls() :108-126 — read)

A skipped event contributes no call to the tripwire at `:183`. So these shapes can make mode1-equiv exit 0 (`cfc-5bdee46-submitted-c26-mode1.txt`):

- **Exit 0 whenever a good call is also present:** S4 array, S4s string, S4n number events, S5 string `message` and S6 string `content` are each rc=1 alone but rc=0 next to the denied good call.
- **A wrong exit 0:** the shape can *carry* an undenied Bash call that the tripwire never sees:
  - C1 (the undenied call's event wrapped in a JSON array): rc=0
  - C2 (a string `message` holding that message's JSON): rc=0
  - C3 (a string `content` holding the content's JSON): rc=0

  In each case, `Bash tripwire` does not fire, although the transcript holds an undenied Bash call.

The generator voids only C2. Its `.message.content` on a string makes jq fail (`cfc-5bdee46-submitted-c25-gen.txt`, G2 → `VOIDED: … could not be read`). G1 (array-wrapped; the generator's `objects` drops it) and G3 (string content; `.content[]?` yields nothing) → `NOT VOIDED`. So for C1 and C3, neither checker catches the call end to end.

This is the security review's F2/M2 class (a call off the parsed path). It is not a new exposure. The CLI is not known to emit these shapes, and nothing suggests the model can steer an event into them. But the claim's guarantee ("no such shape makes it exit 0") does not hold. A reader relying on it for the Claim 13 structural fix would leave these skip paths fail-open. Precise version: "a non-object event or a string `message`/`content` is skipped: alone the run exits 1, next to a good call it exits 0, and any Bash call it carries is invisible to the tripwire".

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:108-126`, `test/skills/arithmetic-eval/mode1-equiv.py:178-186`, `docs/reviews/execution-logs/cfc-5bdee46-submitted-c26-mode1.py`, `docs/reviews/execution-logs/cfc-5bdee46-submitted-c26-mode1.txt`, `docs/reviews/execution-logs/cfc-5bdee46-submitted-c25-gen.txt` (G1-G3). Commands: as for 26a (exit 0, 2026-09-26T04:52:36Z), and `bash docs/reviews/execution-logs/cfc-5bdee46-submitted-c25-gen.sh`, cwd `/workspace`, exit 0, 2026-09-26T04:57:13Z.

---

## Claim 27: "`procs_in_checkout` returns 4 only when no same-uid /proc entry's cwd resolves, including its own subshell's. A fork failure inside the scan exits the subshell 254, and the gate's catch-all arm turns that into a refusal."

**Submitted by:** security-reviewer
**Location:** `devcontainer-config/install.sh:1157-1173`, `devcontainer-config/install.sh:1192-1211`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the one `return 4` site and its readable-count condition, including that the scan subshell's own cwd counts. Also covers fork failure at every fork site in the scan: the root `$(cd …)` at `:1160`, the first and third `$(readlink …)` at `:1163`, and `$(ppid_of …)` in `in_lineage`. Each gives subshell exit 254 and the catch-all refusal, never rc 3 or 4. Not established: a fork failure in install.sh's own main shell (the `$(procs_in_checkout)` fork itself; per the reviewer, install.sh then dies); an end-to-end install.sh run; bash versions other than 5.2.15; running as root, which RLIMIT_NPROC does not bind.

```bash
# devcontainer-config/install.sh:1157-1173
procs_in_checkout() {
  local root d pid cwd cmd readable=0
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 3
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
    cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue   # unreadable: see above
    readable=$((readable + 1))
    ...
  done
  [ "$readable" -gt 0 ] || return 4
}
```
(`...` elides :1165-1170, the in-checkout filter and print, which do not touch `readable` or return — read)

`readable` is incremented for every same-uid entry whose `readlink` succeeds, before the in-checkout filter. The only `return 4` is at `:1172`. The gate:

```bash
# devcontainer-config/install.sh:1193, 1208-1210
  inrepo="$(procs_in_checkout)" || rc=$?
    *)
      echo "ERROR: the check for processes inside the checkout failed (exit $rc, Q-062). $what" >&2
      exit 1 ;;
```

Executed:

- **The own subshell counts** (`cfc-5bdee46-submitted-c27-readable.txt`, 2026-09-26T04:57:04Z). `procs_in_checkout`, sourced verbatim, was run with a `readlink` shim that fails for every entry except the scan subshell's own: rc=0. With the shim failing for every entry, own included: rc=4. With no shim: rc=0.
- **A fork failure means refusal** (`cfc-5bdee46-submitted-c27-fork.txt`, 2026-09-26T04:54:38Z-04:56:08Z). The real `ppid_of`/`in_lineage`/`procs_in_checkout`/`agent_gate` were sourced by line number under install.sh's `set -euo pipefail`. A `set -T` DEBUG trap ran `ulimit -u 1` inside the scan subshell only, just before the chosen command. For each of `root`, `cwd` 1st, `cwd` 3rd (after two successful reads) and `lineage`: `fork: Resource temporarily unavailable`, `procs_in_checkout rc=254`, and `agent_gate` printed `ERROR: the check for processes inside the checkout failed (exit 254, Q-062)` with exit 1. The fork failure at `:1160` does not fall through to `|| return 3`, and one after some successful reads does not fall through to 4.
- **Baseline** (no trigger): rc=0. `agent_gate` then refused for an unrelated reason, this session's own `claude` process, found by pgrep. `vis_or_die` was stubbed to `cat` for the probe.

**Evidence:** `devcontainer-config/install.sh:26`, `devcontainer-config/install.sh:1119-1173`, `devcontainer-config/install.sh:1178-1266`, `docs/reviews/execution-logs/cfc-5bdee46-submitted-c27-readable.sh`, `docs/reviews/execution-logs/cfc-5bdee46-submitted-c27-readable.txt`, `docs/reviews/execution-logs/cfc-5bdee46-submitted-c27-fork.sh`, `docs/reviews/execution-logs/cfc-5bdee46-submitted-c27-fork.txt`. Commands: `bash docs/reviews/execution-logs/cfc-5bdee46-submitted-c27-readable.sh` (cwd `/workspace`, exit 0), and `timeout 120 bash docs/reviews/execution-logs/cfc-5bdee46-submitted-c27-fork.sh <trigger> <n>` for 5 scenarios (cwd `/workspace`). Each exits 1: the gate's refusal, the expected outcome.

---

## Claims Requiring Attention

### Incorrect
- **Claim 26b** (`test/skills/arithmetic-eval/mode1-equiv.py:108-126`): non-object events and string `message`/`content` are skipped, not rejected. Next to a good denied call they exit 0, and an undenied Bash call carried inside them gives a wrong exit 0 (C1-C3). The generator voids only the string-`message` variant. Bear this in mind for the Claim 13 structural fix: skipping is fail-open for any call the skipped event carries.

### Stale
- (none)

### Mostly Accurate
- **Claim 25** (`test/skills/generate-reports.bash:275-287`): add "of an `assistant` event" to the tool_use path, note that ids are compared by `tostring`, and note that `tools` must be an array (a string is a substring search).

### Unverifiable
- (none)

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved to docs/reviews/code-fact-check-submitted-claims.md with a `Commit: 5bdee46` line at the top, containing a `## Submitted Claims` section that verdicts ONLY the three claims below, numbered Claim 25, 26, 27 (the canonical report docs/reviews/code-fact-check-report.md ends at Claim 24d).
- **Answered:** Yes. The report is at that path. `**Commit:** 5bdee46` is its first line. The `## Submitted Claims` section verdicts only the three submitted claims, as Claims 25, 26 (split into 26a and 26b because the parts earned different verdicts) and 27. Each claim has the seven mandatory fields plus `Submitted by` and `Legibility-target`. All four verdicts are executed.
- **Out of scope:** new claims harvested from the diff. Whether the CLI can emit the shapes in Claims 25 and 26b (that needs `claude`). An end-to-end install.sh run under NPROC exhaustion. How to fix 26b (the orchestrator's Claim 13 structural fix).
- **Escalate:** Claim 26b. The critic's endorsement "no Claim 13 shape makes mode1-equiv exit 0" is false for the three skip shapes. When one of them carries an undenied Bash call, mode1-equiv exits 0, and for the array-wrapped and string-`content` forms the generator does not void the run either. This is the F2 class (a call off the parsed path) and is not known to be CLI-producible. But it should not be recorded as a cleared guardrail, and the Claim 13 fix should reject these shapes, not only the crashing ones. Claim 25's imprecisions are wording-level.
- **Decisions:** No hallucination-pattern entry was added: Claim 26b overstates an existing code path and fabricates nothing. Nothing was committed.
