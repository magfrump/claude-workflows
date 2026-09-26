# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** branch diff `git diff main...HEAD` (skill-fixtures), focused on fix commit 37c5ea9 (review-fix loop iteration 3) and the rubric rows it marked Fixed
**Commit:** 5bdee46
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-09-25
**Total claims checked:** 31
**Summary:** 19 verified, 8 mostly accurate, 1 stale, 3 incorrect, 0 unverifiable

Hallucination-pattern log read first (`docs/reviews/hallucination-patterns.md`, 4 entries). Claim 24b matches the logged class "a specific measured value quoted from a checked-in artifact set that does not contain it" (the "All 85 tests … but the suites hold 97" entry, first seen 2026-09-12). No other claim matches a logged pattern.

Execution logs are all in `docs/reviews/execution-logs/cfc-5bdee46-*`. Every command ran with cwd `/workspace` unless the log says otherwise. Probe scripts are saved next to their logs (`*.sh`, plus `cfc-5bdee46-gen.jq`, the generator's jq program extracted verbatim from `test/skills/generate-reports.bash:275-286`). jq is 1.6.

---

## Claim 1: "If it cannot read any process's working directory under /proc, it prints a NOTE and treats none as inside the checkout. … Run it from a terminal on the host itself: from inside a sandbox, container or other PID namespace, pgrep and /proc see only that namespace, so agents outside it are missed without any NOTE."

**Location:** `devcontainer-config/install.sh:63-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the blind-scan NOTE and its "treated as none" outcome, and the claim that the check stays silent inside a PID namespace. Does not establish the behavior on a host where an LSM hides only *some* cwds (they are skipped silently, per Q-064), or anything about the docker check inside a namespace.

The rc-4 arm prints the NOTE and clears the list:

```bash
# devcontainer-config/install.sh:1204-1207
    4)
      echo "NOTE: no process's working directory could be read under /proc: processes inside"
      echo "      the checkout not checked, treated as none (Q-062)."
      inrepo="" ;;
```

T91 passes (`bats test/install-host.bats`, exit 0, 91/91, 2026-09-26T04:25:29Z). It forces every `readlink` to fail, then asserts exit 0, the NOTE text including "treated as none", and that the install went ahead.

For the namespace half: this review sandbox is itself a PID namespace (PID 1 is `/bin/sh -c echo Container started …`). In it, `/proc` lists 22 processes and 20 own-uid cwds are readable (`cfc-5bdee46-pidns-probe.txt`, 2026-09-26T04:31:34Z). So `procs_in_checkout` would never reach rc 4 there, and no NOTE would print. A clean `unshare -rpf --mount-proc` reproduction was blocked ("Operation not permitted", `cfc-5bdee46-mode1-probes.txt` addendum).

**Evidence:** `devcontainer-config/install.sh:63-68`, `devcontainer-config/install.sh:1204-1207`, `test/install-host.bats:1551-1562`, `docs/reviews/execution-logs/cfc-5bdee46-install-host.txt`, `docs/reviews/execution-logs/cfc-5bdee46-pidns-probe.txt`

---

## Claim 2: "Returns 2 when /proc is not mounted, 3 when the checkout's own path cannot be resolved, 4 when no process's cwd could be read at all, not even this script's own … It cannot detect running inside a PID namespace: there its own namespace's processes are readable, and everything outside is simply not listed"

**Location:** `devcontainer-config/install.sh:1142-1149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three return codes and the counter that drives rc 4. Does not establish that rc 3 is reachable in practice (static only; no test forces `cd "$REPO_ROOT"` to fail), or that an LSM is the only way to reach rc 4.

I read the whole function:

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
(excerpt elides :1165-1170, the in-checkout filter and print, which do not touch `readable`; read)

`readable` counts every own-uid process whose cwd resolves, before the in-checkout filter. That includes the script's own `$(…)` subshell. So "not even this script's own" is right: rc 4 means the script could not read its own cwd either. T90 (rc 2 → refusal) and T91 (rc 4 → NOTE) pass (`cfc-5bdee46-install-host.txt`). The namespace statement matches the probe in Claim 1.

**Evidence:** `devcontainer-config/install.sh:1142-1173`, `docs/reviews/execution-logs/cfc-5bdee46-install-host.txt`, `docs/reviews/execution-logs/cfc-5bdee46-pidns-probe.txt`

---

## Claim 3: gate case block: rc 2 → "/proc is not mounted" refusal; rc 3 → "could not resolve the checkout's path" refusal; rc 4 → NOTE on stdout, "treated as none"; any other rc → "the check … failed (exit $rc)" refusal (commit: "The catch-all rc gets its own error")

**Location:** `devcontainer-config/install.sh:1192-1211`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mapping from each rc to its message, stream and exit. Arms 2 and 4 were executed (T90, T91), arms 3 and `*` were read only. Does not establish that any rc other than 0/2/3/4 can occur (the function has no other return).

```bash
# devcontainer-config/install.sh:1193-1211
  inrepo="$(procs_in_checkout)" || rc=$?
  case "$rc" in
    0) ;;
    2)
      echo "ERROR: /proc is not mounted, …" >&2
      … exit 1 ;;
    3)
      echo "ERROR: could not resolve the checkout's path ($REPO_ROOT), …" >&2
      … exit 1 ;;
    4)
      echo "NOTE: no process's working directory could be read under /proc: processes inside"
      echo "      the checkout not checked, treated as none (Q-062)."
      inrepo="" ;;
    *)
      echo "ERROR: the check for processes inside the checkout failed (exit $rc, Q-062). $what" >&2
      exit 1 ;;
  esac
```
(quote abbreviates the second echo lines of arms 2 and 3 with "…"; the whole block was read)

The rc-4 NOTE has no `>&2`, so it goes to stdout, as the commit says. The emptied `inrepo` then flows through the dedupe awk at :1215-1217 to the `[ -z "$inrepo" ]` test at :1238. So the gate passes unless pgrep or docker finds something.

**Evidence:** `devcontainer-config/install.sh:1192-1238`, `test/install-host.bats:1537-1562`, `docs/reviews/execution-logs/cfc-5bdee46-install-host.txt`

---

## Claim 4: decision 037: "if no process's cwd can be read at all (not even the script's own), a NOTE says the scan was blind and treats none as found, like the docker NOTE" and "If `install.sh` itself runs inside a PID namespace …, both pgrep and the `/proc` scan see only that namespace, its own processes stay readable, and nothing outside is listed, with no NOTE; the usage text says to run from a host terminal."

**Location:** `docs/decisions/037-bare-host-copy-install.md:76`, `docs/decisions/037-bare-host-copy-install.md:86`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement between 037's two sentences and install.sh's code and usage text. Does not establish the parenthetical test list: line 76 still cites "(T88–T90)", and the blind-scan NOTE is tested by T91, which it does not name.

The docker NOTE is the model the 037 text compares to: `echo "NOTE: docker not found: cc-isolated containers not checked, treated as none running."` (`devcontainer-config/install.sh:1221`). The rc-4 arm uses the same "not checked, treated as none" shape (Claim 3). The usage text at `install.sh:66-68` carries the "run it from a terminal on the host itself" sentence that 037:86 points to.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:76`, `docs/decisions/037-bare-host-copy-install.md:86`, `devcontainer-config/install.sh:66-68`, `devcontainer-config/install.sh:1204-1207`, `devcontainer-config/install.sh:1221`

---

## Claim 5: log #56: "Under deny-record the generator refuses any non-blank `CLAUDE_FLAGS` …, and it voids a run when a Bash call is missing from `permission_denials` (tripwire), when a denial names a call the parser did not see (parser canary), or when the init event is missing or does not list Bash."

**Location:** `docs/decisions/log.md:77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the CLAUDE_FLAGS refusal and the four voiding conditions. Does not establish the CLI-side claims in the same row (dontAsk behavior, `Bash(**)` vs `Bash(*)`, the Haiku run), which need a live `claude` and are settled history.

```bash
# test/skills/generate-reports.bash:127
if [ "$FIXTURE_BASH" = "deny-record" ] && [ -n "${CLAUDE_FLAGS:+${CLAUDE_FLAGS//[[:space:]]/}}" ]; then
```

The four voiding messages are at `generate-reports.bash:293-301`. Each one has a stub-CLI test in `test/generate-reports.bats` (:532 canary, :541 tripwire, :571 parser canary, :589 no init, :601 no id), and the CLAUDE_FLAGS refusal is tested at :503. All 38 pass (`cfc-5bdee46-harness-suites.txt`, exit 0, 2026-09-26T04:25:04Z). The jq probes (Claim 20a/20b) reproduce each condition directly.

**Evidence:** `docs/decisions/log.md:77`, `test/skills/generate-reports.bash:127`, `test/skills/generate-reports.bash:293-301`, `test/generate-reports.bats:503-601`, `docs/reviews/execution-logs/cfc-5bdee46-harness-suites.txt`

---

## Claim 6: rubric A19 status "Fixed": "Mis-shaped transcript events raise SetupError (exit 2); strict number grammar (no `1~`, spaces, `_`, `+`); `--check-spec` arity message." (the same wording is in 37c5ea9's A19 bullet: "mode1-equiv raises SetupError (exit 2) on mis-shaped transcript events")

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:41`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the four inputs the A19 row named (`123`, a string content block, a string `input`, a numeric `command`), the grammar and the arity message. Does not establish the broad reading, "any mis-shaped event exits 2": other shapes are skipped (exit 1) or still crash (Claim 13).

The four named cases no longer produce a traceback (`cfc-5bdee46-mode1-probes.txt`):

- string `input` → `rc=2 mode1-equiv: Bash tool_use 't1' has no string input.command`
- numeric `command` → `rc=2`, same message
- a non-object event, or a string content → skipped, `rc=1 Bash calls seen: 0 No Mode 1 call computed any of: 1`

The last two exit 1 through the "no match" path, not SetupError, so "raise SetupError (exit 2)" is true only for Bash `tool_use` blocks with a bad `input`/`command`. The grammar and arity parts hold (`1~`, ` 1`, `1 `, `1_000`, `+1` all rc 2; `--check-spec` with 1 or 3 arguments prints "expects 2 arguments", rc 2). The precise version: "a Bash tool_use with a non-dict input or non-string command raises SetupError; other non-object or wrongly-typed events are skipped".

**Evidence:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:41`, `test/skills/arithmetic-eval/mode1-equiv.py:108-126`, `docs/reviews/execution-logs/cfc-5bdee46-mode1-probes.txt`

---

## Claim 7: rubric A18 status "Fixed": "Log #56, the DD doc 'As built' Contract and Run-voiding bullets, and the generator Environment block now point at `FIXTURE_BASH`/`DENY_RECORD_FLAGS`."

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:40`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the three named places, which were updated (Claims 5, 9a, 19). Does not establish the row's underlying goal, that the prose now agrees with the code: the reference the DD doc names (the generator header's `FIXTURE_BASH` entry) lags the code (Claim 18).

The DD doc now says `**Contract.** The code is the reference: the \`FIXTURE_BASH\` entry in \`generate-reports.bash\`'s header, …` (`docs/working/dd-arith-eval-bash-grant.md:174`). That header entry lists only the tripwire and the no-Bash canary: `# … A run is recorded as failed when any Bash call is missing from the # result's permission_denials (it may have executed), or # when the init event does not list Bash (canary).` (`test/skills/generate-reports.bash:34-37`). It omits the parser canary and the missing-init case that 37c5ea9 added.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:40`, `docs/working/dd-arith-eval-bash-grant.md:174-175`, `test/skills/generate-reports.bash:31-37`, `test/skills/generate-reports.bash:78-79`

---

## Claim 8: rubric status "Fixed" for R1, A15, A16, A17, C25, C26, C27, C28, C29

**Location:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:15`, `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:37-39`, `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:73-77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each row's stated defect no longer reproducing. Does not establish: that A16's parser canary catches a CLI change that alters *both* the assistant and the result event shapes (it does not; Claim 20b); that C26's single message covers an empty FIXTURE_TOOLS (that value gets the earlier "must set FIXTURE_TOOLS" message); or C27's "prints up to 4× per install" point, which the fix kept, as the docker NOTE does.

Per row (paraphrased — no quote available because the evidence spans nine rows, six source files and several logs; each item names its log):

- **R1.** Mutating VERDICT_RE to match the hedge fails test 3, and ten mutations all fail at least one test (`cfc-5bdee46-patterns-mutation.txt`). Health-check's shellcheck section lists `✓ test/skills/arithmetic-eval-after-denial-patterns.bats` and `✓ test/skills/mode1-equiv.bats`, and the run ends "All checks passed." with EXIT=0 (`cfc-5bdee46-health-check.txt`).
- **A15.** See Claims 1-2.
- **A16.** Parser canary: a Bash denial whose tool_use sits under an unknown key gives `0	1	bash`, so unseen=1 (`cfc-5bdee46-gen-jq-probes.txt`). Init required: `assert_no_tool_called` on a junk or empty file prints "No init event" and returns rc 1 (`cfc-5bdee46-eval-helpers-probes.txt`).
- **A17.** No init event → `none` state → the message "no init event in the stream (the run did not start?)" (`generate-reports.bash:299`, bats :589).
- **C25.** See Claim 22.
- **C26.** See Claim 23.
- **C27.** See Claim 3 and T91.
- **C28.** One jq program with object-key sets (`generate-reports.bash:279,282`). A null-id call plus a null-id denial gives undenied=1 in both the generator and mode1-equiv (`cfc-5bdee46-null-id-probe.txt`).
- **C29.** Stated at `generate-reports.bash:271-272` and `dd-arith-eval-bash-grant.md:175`.

**Evidence:** `docs/reviews/code-review-rubric-2026-09-25-skill-fixtures-q062-q063.md:15`, `docs/reviews/execution-logs/cfc-5bdee46-patterns-mutation.txt`, `docs/reviews/execution-logs/cfc-5bdee46-health-check.txt`, `docs/reviews/execution-logs/cfc-5bdee46-gen-jq-probes.txt`, `docs/reviews/execution-logs/cfc-5bdee46-null-id-probe.txt`, `docs/reviews/execution-logs/cfc-5bdee46-c25-mutation.txt`

---

## Claim 9a: DD doc "Run voiding": "The generator writes a `.failed` marker, also when the run already failed for another reason, if: a Bash `tool_use` (or one with no id) is missing from `permission_denials` (tripwire); a Bash denial names a `tool_use` the parser did not see (parser canary …); the stream has no init event; or the init event does not list Bash"

**Location:** `docs/working/dd-arith-eval-bash-grant.md:175`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four conditions and the "also when already failed" ordering. Does not establish that a malformed event (e.g. `"message":"oops"`) is reported under its true cause: the whole jq pass fails and is reported as "the transcript could not be read", which still fails closed.

The deny-record block sits outside the `if [ -z "$failure" ]` guard (`generate-reports.bash:247-256` vs :273) and appends with `failure="${failure:+$failure; }…"`, so earlier failures are kept. Bats :554 ("tripwire still runs when the run already failed") passes. The jq probes reproduce each condition (`cfc-5bdee46-gen-jq-probes.txt`: undenied 1, no-id 1, unseen 1, `none`, `nobash`).

**Evidence:** `docs/working/dd-arith-eval-bash-grant.md:175`, `test/skills/generate-reports.bash:247-303`, `docs/reviews/execution-logs/cfc-5bdee46-gen-jq-probes.txt`

---

## Claim 9b: "`mode1-equiv.py` repeats the tripwire."

**Location:** `docs/working/dd-arith-eval-bash-grant.md:175`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers id-in-denials, with no-id calls counted as undenied. Does not establish that the two checks are identical: they differ on which denials count.

The generator counts only Bash denials, `select(type == "object" and .tool_name == "Bash") | .tool_use_id` (`generate-reports.bash:278`). mode1-equiv counts any denial: `denied = {d.get("tool_use_id") for ev in evs … for d in (ev.get("permission_denials") or []) if isinstance(d, dict)}` (`mode1-equiv.py:178-180`). Probe: a Bash call whose id is denied under `"tool_name":"Read"` passes mode1-equiv's tripwire, and the checker goes on to "call 1: not the Mode 1 wrapper". The generator would count the same call as undenied (`cfc-5bdee46-mode1-probes.txt`, line 10). Precise version: "repeats the tripwire's id check, without the Bash tool_name filter".

**Evidence:** `test/skills/generate-reports.bash:277-278`, `test/skills/arithmetic-eval/mode1-equiv.py:178-183`, `docs/reviews/execution-logs/cfc-5bdee46-mode1-probes.txt`

---

## Claim 10: "Every phrase goes through the grader's own assert_report_matches / assert_report_not_matches under `run`, with the status checked explicitly" and test "the helpers themselves can fail (a guard against vacuous assertions)"

**Location:** `test/skills/arithmetic-eval-after-denial-patterns.bats:7-10`, `test/skills/arithmetic-eval-after-denial-patterns.bats:35`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the claim that the suite has no vacuous assertions, tested by ten mutations of the patterns and the helpers. Does not establish that the regexes are adequate on real model output (the graded tests are opt-in and were skipped).

```bash
# test/skills/arithmetic-eval-after-denial-patterns.bats:22-27
expect_hit() {
  # shellcheck disable=SC2034  # read by assert_report_matches
  REPORT_CONTENT="$2"
  run assert_report_matches "$1"
  [ "$status" -eq 0 ] || { echo "expected a match: $2"; return 1; }
}
```

The unmutated suite passes 5/5. Each of M1-M10 fails at least one test (`cfc-5bdee46-patterns-mutation.txt`, 2026-09-26T04:29:24Z). The mutations: VERDICT_RE matching the hedge, NOT_VERIFIED_RE dropping `unverified` or matching everything, each FIGURE_RE losing its left anchor, VERDICT_RE dropping ✓, `assert_report_matches` or `assert_report_not_matches` made unable to fail, and a misspelled FIGURE_RE key.

**Evidence:** `test/skills/arithmetic-eval-after-denial-patterns.bats:1-87`, `docs/reviews/execution-logs/cfc-5bdee46-patterns-mutation.txt`, `docs/reviews/execution-logs/cfc-5bdee46-patterns-mutation.sh`

---

## Claim 11: "tc-ae4 has none: \"4.8 million\" is already in the draft."

**Location:** `test/skills/arithmetic-eval/after-denial-patterns.bash:21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fixture's wording and the absence of a tc-ae4 FIGURE_RE key. Does not establish anything about graded after-denial output.

The fixture reads `so the backend should plan for about 4.8 million sessions a day.` (`test/skills/arithmetic-eval/fixtures/tc-ae4-sessions-correct.md:4`). FIGURE_RE has keys for tc-ae1..3 only (`after-denial-patterns.bash:23-25`).

**Evidence:** `test/skills/arithmetic-eval/after-denial-patterns.bash:19-25`, `test/skills/arithmetic-eval/fixtures/tc-ae4-sessions-correct.md:4`

---

## Claim 12: "<expected> is one or more values separated by \"|\", each a plain number (digits, an optional \".\" part and exponent, an optional leading \"-\"), optionally followed by \"~<relative tolerance>\", a plain number >= 0 … No spaces, \"_\", \"+\", nan or inf."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:24-29`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the grammar enforced by `parse_expected` over 23 probe specs. Does not establish behavior on values that underflow (`1e-400` is accepted and becomes 0.0, which then needs an exact 0).

```python
# test/skills/arithmetic-eval/mode1-equiv.py:51
NUMBER_RE = re.compile(r"-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?")
```

As documented, these are refused with rc 2: `nan`, `inf`, `1_000`, `+1`, ` 1`, `1 `, `1~`, `.5`, `5.`, `0x10`, a non-ASCII digit, empty alternatives (`1|`, `1||2`), `1e400` (not finite) and `1~-1`. `1e5` and `-2.5E-3~0.1` are accepted. The one mismatch: "No … \"+\"" is absolute, but the exponent may carry one, and `--check-spec … '1e+5'` returns rc 0 (`cfc-5bdee46-mode1-probes.txt` addendum). Precise version: "no leading \"+\"". Minor: `1~-0` is accepted, which is consistent with ">= 0".

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:51`, `test/skills/arithmetic-eval/mode1-equiv.py:129-140`, `docs/reviews/execution-logs/cfc-5bdee46-mode1-probes.txt`

---

## Claim 13: "Exit … 2 on any setup error: usage, value spec, an unreadable file, a transcript event of the wrong shape, or a SKILL.md whose Mode 1 block does not extract … Every setup error goes through SetupError in main(), so none can escape as a traceback with exit 1, which would read as \"the model did not compute the value\"."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:31-36`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the "transcript event of the wrong shape" clause and the "none can escape as a traceback" guarantee, against readable transcripts. Does not establish whether the CLI ever emits these shapes. The enumerated usage, spec, unreadable-file and non-UTF-8 errors do give rc 2 (verified).

Two things refute the mechanism.

**(a) Some wrong shapes still crash.** The tripwire code runs *after* the `try/except SetupError` block:

```python
# test/skills/arithmetic-eval/mode1-equiv.py:174-183
        calls = bash_calls(evs)
    except SetupError as e:
        print("mode1-equiv: " + str(e), file=sys.stderr)
        return 2

    denied = {d.get("tool_use_id") for ev in evs
              if isinstance(ev, dict) and ev.get("type") == "result"
              for d in (ev.get("permission_denials") or []) if isinstance(d, dict)}
    denied.discard(None)
    # A call with no id counts as undenied (review iteration 3, C28).
    undenied = [cid for cid, _ in calls if cid is None or cid not in denied]
```
(excerpt ends :183; enclosing main() continues to :206 — read)

Three wrong shapes make this code raise an uncaught `TypeError`, exit 1 with a traceback (`cfc-5bdee46-mode1-probes.txt`, lines 6-8):

- `"permission_denials": 5` → `'int' object is not iterable`
- a denial whose `tool_use_id` is a list → `unhashable type: 'list'`
- a Bash tool_use whose `id` is an object → `unhashable type: 'dict'`

**(b) Most wrong shapes are skipped, not reported.** A non-object event, a string `message` and a string `content` are skipped by `bash_calls` (`:113-118`). The run then exits 1 with "No Mode 1 call computed any of: 1". That is the reading the docstring says exit 2 prevents. Only a Bash tool_use with a non-dict `input` or non-string `command` gives rc 2.

A reader who trusts "exit 1 = a model result" would misread these runs.

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:31-36`, `test/skills/arithmetic-eval/mode1-equiv.py:108-126`, `test/skills/arithmetic-eval/mode1-equiv.py:159-206`, `docs/reviews/execution-logs/cfc-5bdee46-mode1-probes.txt`

---

## Claim 14: "A Bash tool_use whose fields have the wrong types is a SetupError, not a crash."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:109-110`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the `input`, `command` and `id` fields of a Bash tool_use. Does not cover other event types (Claim 13).

`bash_calls` type-checks only `input` and `command`:

```python
# test/skills/arithmetic-eval/mode1-equiv.py:120-125
                inp = block.get("input")
                cmd = inp.get("command") if isinstance(inp, dict) else None
                if not isinstance(cmd, str):
                    raise SetupError(f"Bash tool_use {block.get('id')!r} has no string input.command")
                calls.append((block.get("id"), cmd))
```
(excerpt ends :125; enclosing bash_calls() continues to :126 `return calls` — read)

An `id` of the wrong type (an object) is appended unchanged. It then crashes at `cid not in denied` (`:183`) with `TypeError: unhashable type: 'dict'` and exit 1 (`cfc-5bdee46-mode1-probes.txt`, line 8). Precise version: "a Bash tool_use whose input or input.command has the wrong type is a SetupError".

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:108-126`, `test/skills/arithmetic-eval/mode1-equiv.py:183`, `docs/reviews/execution-logs/cfc-5bdee46-mode1-probes.txt`

---

## Claim 15: "A call with no id counts as undenied (review iteration 3, C28)."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:182`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a missing id, including when a denial also lacks an id. Does not cover ids of unhashable types (Claim 14).

`undenied = [cid for cid, _ in calls if cid is None or cid not in denied]` after `denied.discard(None)` (`mode1-equiv.py:181-183`). A no-id call next to a no-id denial gives `Bash tripwire: 1 Bash call(s) not in permission_denials (may have executed): [None]`, rc 1 (`cfc-5bdee46-null-id-probe.txt`).

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:178-186`, `docs/reviews/execution-logs/cfc-5bdee46-null-id-probe.txt`

---

## Claim 16a: tool_inputs_checked fails "when the file cannot be read, when it holds no init event …, or when the init event lists the run's tools and <tool> is not one of them … It does not detect a changed event shape that hides tool_use blocks: generate-reports.bash's parser canary does, for deny-record runs, and eval_fixture fails any run with a .failed marker."

**Location:** `test/skills/eval-helpers.bash:376-383`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three failure conditions and the stated limit. Does not establish: that the parser canary catches a change to *both* event shapes (Claim 20b); that a misspelled tool name is caught when the init event has no `tools` list (it is not, and the comment says so by its "when the init event lists" condition); or that the helper fails on an event whose `message` is a string (under jq 1.6 that line is silently skipped, a case of the stated limit).

```bash
# test/skills/eval-helpers.bash:384-401
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
  known="$(jq -rR '… | .tools[]?' "$t" 2>/dev/null || true)"
  if [ -n "$known" ] && ! printf '%s\n' "$known" | grep -qxF -e "$tool"; then
  …
  printf '%s' "$inputs"
}
```
(quote abbreviates the jq filter at :395 and the message lines :397-399 with "…"; the whole function was read)

Probe results (`cfc-5bdee46-eval-helpers-probes.txt`, 2026-09-26T04:28:22Z):

- junk file and empty file → "No init event", rc 1
- `bash` against an init event listing `Bash Read` → "bash is not a tool of this run", rc 1
- a missing transcript → rc 1
- an invalid ERE → rc 1
- a hidden-shape tool_use → rc 0 (the stated limit)
- a string-`message` event → rc 0 (the stated limit)

`eval_fixture` fails on `.failed` at `eval-helpers.bash:80-83`.

**Evidence:** `test/skills/eval-helpers.bash:74-83`, `test/skills/eval-helpers.bash:369-401`, `docs/reviews/execution-logs/cfc-5bdee46-eval-helpers-probes.txt`

---

## Claim 16b: "(a junk or truncated transcript, which would otherwise read as \"no calls\" and let a negative check pass)"

**Location:** `test/skills/eval-helpers.bash:378-379`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers which truncations the init check itself catches. Does not establish end-to-end handling of a tail-truncated stream: that is the generator's `.failed` marker ("no result event in the stream", `generate-reports.bash:254`), not this function.

The init event is the stream's first line, so the check catches only a transcript truncated *before or inside* that line. A transcript that holds only its init event (tail-truncated) passes `assert_no_tool_called Bash` with rc 0 (`cfc-5bdee46-eval-helpers-probes.txt`, "truncated: init only"). Precise version: "a junk transcript, or one cut off before its init event".

**Evidence:** `test/skills/eval-helpers.bash:376-394`, `test/skills/generate-reports.bash:247-256`, `docs/reviews/execution-logs/cfc-5bdee46-eval-helpers-probes.txt`

---

## Claim 17: "grep, not jq -e: jq's exit status reflects only the last input line."

**Location:** `test/skills/eval-helpers.bash:390`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers jq 1.6, the version in this sandbox. Does not establish the behavior of jq 1.7+, whose `-e` semantics may differ.

Run on jq 1.6 (`cfc-5bdee46-jq-e-probe.txt`, 2026-09-26T04:28:55Z): with the init event on line 1 followed by other lines, `jq -erR '… | "init"'` prints `init` but exits 4. That is the status of the last input, which produced no output. Confidence is Medium because this is version-specific.

**Evidence:** `test/skills/eval-helpers.bash:390-391`, `docs/reviews/execution-logs/cfc-5bdee46-jq-e-probe.txt`

---

## Claim 18: generator header `FIXTURE_BASH`: "A run is recorded as failed when any Bash call is missing from the result's permission_denials (it may have executed), or when the init event does not list Bash (canary)."

**Location:** `test/skills/generate-reports.bash:34-37`
**Type:** Behavioral / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the header's list of voiding conditions against the code. Does not establish anything beyond the header text; the code itself is verified in Claims 20a-20c.

Since 37c5ea9 the code voids on two more conditions:

- `Bash parser canary: $unseen Bash denial(s) name a tool_use the parser did not see` (`generate-reports.bash:296`)
- `no init event in the stream (the run did not start?)` (`:299`)

The header was not updated. It matters because the DD doc names this header entry as the contract reference (`dd-arith-eval-bash-grant.md:174`, "The code is the reference: the `FIXTURE_BASH` entry in `generate-reports.bash`'s header"). Precise version: list all four conditions, as log #56 and the DD "Run voiding" bullet do.

**Evidence:** `test/skills/generate-reports.bash:31-37`, `test/skills/generate-reports.bash:293-301`, `docs/working/dd-arith-eval-bash-grant.md:174`

---

## Claim 19: "CLAUDE_FLAGS — additional flags to pass to claude -p (refused under FIXTURE_BASH=deny-record; see DENY_RECORD_FLAGS)"

**Location:** `test/skills/generate-reports.bash:78-79`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers non-blank CLAUDE_FLAGS refused before claude runs, and blank accepted. Does not establish the non-deny-record path's handling of CLAUDE_FLAGS (unvalidated, settled override C4).

See the guard quoted in Claim 5 (`:127`). Bats "deny-record refuses any CLAUDE_FLAGS before claude runs; blank is fine" passes: 8 flag strings are refused with no stub call recorded, and `$' \t'` is accepted (`test/generate-reports.bats:503-517`, `cfc-5bdee46-harness-suites.txt`).

**Evidence:** `test/skills/generate-reports.bash:78-79`, `test/skills/generate-reports.bash:123-130`, `test/generate-reports.bats:503-517`, `docs/reviews/execution-logs/cfc-5bdee46-harness-suites.txt`

---

## Claim 20a: "Deny-record checks, in one pass over the stream …: tripwire: every Bash tool_use must be listed as denied …. A tool_use with no id counts as undenied. It runs even when the run already failed"

**Location:** `test/skills/generate-reports.bash:257-261`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tripwire's counting and the one-jq-invocation structure (the commit's "O(1) lookups" is object-key indexing). Does not establish the cost of building the key sets with `add` in jq 1.6. "One pass" covers only the deny-record checks: the report and result_state extractions at :245 and :249 are two further jq reads.

```bash
# test/skills/generate-reports.bash:279-283
        | ($denied | map(select(. != null) | {(tostring): true}) | add // {}) as $dset
        | [$ev[] | select(.type == "assistant") | .message.content[]? | objects
           | select(.type == "tool_use" and .name == "Bash") | .id] as $calls
        | ($calls | map(select(. != null) | {(tostring): true}) | add // {}) as $cset
        | [ ($calls | map(select(. == null or ($dset[tostring] | not))) | length),
```
(excerpt ends :283; enclosing jq program continues to :286 and generate_one() to :314 — read)

Probes over 24 stub transcripts (`cfc-5bdee46-gen-jq-probes.txt`, 2026-09-26T04:24:07Z) all count as documented:

- clean → `0 0 bash`; undenied → `1`; no id → `1`; sub-agent (`parent_tool_use_id`) undenied → `1`
- denials split across two result events → `0`; duplicate call ids with one denial → `0`
- a denial lacking `tool_name` → `1`; a string `permission_denials` → `1`
- non-object lines (array, string, junk) are ignored

**Evidence:** `test/skills/generate-reports.bash:257-303`, `docs/reviews/execution-logs/cfc-5bdee46-gen-jq-probes.txt`, `docs/reviews/execution-logs/cfc-5bdee46-gen.jq`

---

## Claim 20b: "parser canary: every Bash denial must name a tool_use the parser saw. If the CLI's event shape changed, the tripwire and every transcript check would see no calls and pass; this makes that fail loudly (A16)."

**Location:** `test/skills/generate-reports.bash:262-264`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a change to the assistant event shape while the result's `permission_denials` still parse. Does not establish detection when both shapes change together, or when denials stop carrying `tool_name: "Bash"`. In that second case the tripwire fires instead (probe "denial missing tool_name" → undenied 1).

Probe "Bash denial names unseen tool_use (shape change)" (tool_use under `message.blocks`) gives `0	1	bash`, so unseen=1. A denial with a null `tool_use_id` also counts as unseen (`0	1`). Denials for other tools (`Read`) are excluded (`0	0`). An event with a string `message` makes jq exit 5, which the code reports as "the transcript could not be read" (fail closed). Bats :571 passes.

**Evidence:** `test/skills/generate-reports.bash:277-296`, `test/generate-reports.bats:571-587`, `docs/reviews/execution-logs/cfc-5bdee46-gen-jq-probes.txt`

---

## Claim 20c: "init canary: the stream must start with an init event (a run that dies before it is reported as that, not blamed on the deny rule; A17), and that event must list Bash."

**Location:** `test/skills/generate-reports.bash:265-267`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers presence of an init event and its Bash listing, and the separate "no init" message. Does not establish any check on the init event's position in the stream.

The program takes the first init event *anywhere*: `([$ev[] | select(.type == "system" and .subtype == "init")] | first) as $init` (`:276`). Probe "init only at END of stream" gives `0	0	bash`, and the run passes (`cfc-5bdee46-gen-jq-probes.txt`). Precise version: "the stream must contain an init event". The A17 message split is correct: `none` → "no init event in the stream (the run did not start?)" (`:299`, bats :589).

**Evidence:** `test/skills/generate-reports.bash:265-267`, `test/skills/generate-reports.bash:276`, `test/skills/generate-reports.bash:285`, `test/skills/generate-reports.bash:297-301`, `docs/reviews/execution-logs/cfc-5bdee46-gen-jq-probes.txt`

---

## Claim 21: test name "eval_fixture dispatch: tool_called and no_tool_called parse <Tool>[=<ERE>]; mode1_equiv resolves by skill"

**Location:** `test/skills/mode1-equiv.bats:241`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what this one test proves about mode1_equiv resolution. Does not affect the dispatch-parsing half of the name, which the test does exercise (4 pass and 4 fail cases).

The test builds its tree only for `arithmetic-eval` (`:243-245`), so it cannot tell per-skill resolution from a hard-coded path. With `assert_mode1_equiv`'s checker path or SKILL.md path hard-coded to arithmetic-eval (relative or absolute), this test still passes in all three mutations (`cfc-5bdee46-c25-mutation.txt`). The property is carried by the sibling test at `:278` (Claim 22). Precise version: drop "resolves by skill" from this name, or say "dispatches".

**Evidence:** `test/skills/mode1-equiv.bats:238-269`, `docs/reviews/execution-logs/cfc-5bdee46-c25-mutation.txt`

---

## Claim 22: "With the checker path hard-coded to arithmetic-eval, this fails: the stub below is never run (review iteration 3, C25)."

**Location:** `test/skills/mode1-equiv.bats:279-280`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the checker-path and SKILL.md-path mutations of `assert_mode1_equiv`. Does not establish resolution for skill names containing path separators.

M1 (relative hard-code), M2 (absolute hard-code) and M3 (SKILL.md path hard-coded) each fail this test. The unmutated copy passes (`cfc-5bdee46-c25-mutation.txt`, 2026-09-26T04:29:59Z).

**Evidence:** `test/skills/mode1-equiv.bats:278-298`, `test/skills/eval-helpers.bash:481-494`, `docs/reviews/execution-logs/cfc-5bdee46-c25-mutation.txt`, `docs/reviews/execution-logs/cfc-5bdee46-c25-mutation.sh`

---

## Claim 23: "Checked before the tools loop, which reads it, so a misspelling such as deny_record is reported as itself (review iteration 2, C19), and so every wrong FIXTURE_TOOLS under deny-record gets the one message below (C26)."

**Location:** `test/skills/runner-contract.bash:53-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every non-empty wrong value. Does not cover an empty FIXTURE_TOOLS, which is caught first by the "must set FIXTURE_TOOLS" check at `:40-43` (a missing value rather than a wrong one).

`Bash,Read`, `bash`, `none`, `Read`, `Bash ` and `Bash(**)` all return rc 1 with `FIXTURE_BASH=deny-record needs FIXTURE_TOOLS=Bash exactly, got '…'`. `deny_record` gives `FIXTURE_BASH must be empty or deny-record, got 'deny_record'`. An empty value gives `must set FIXTURE_TOOLS and define fixture_prompt` (`cfc-5bdee46-runner-contract-probes.txt`, 2026-09-26T04:28:10Z).

**Evidence:** `test/skills/runner-contract.bash:38-125`, `docs/reviews/execution-logs/cfc-5bdee46-runner-contract-probes.txt`

---

## Claim 24a: 37c5ea9: "harness suites 1..133 with 9 skips (generate-reports 38, … patterns 5, eval-helpers-transcript 7, gate/format/eval/empty-report the rest …)"

**Location:** commit 37c5ea9 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the total, the skip count and the three per-file counts named here. Does not cover the mode1-equiv count (Claim 24b) or the skip attribution (Claim 24c).

Command: `bats test/generate-reports.bats test/skills/mode1-equiv.bats test/skills/eval-helpers-transcript.bats test/skills/arithmetic-eval-after-denial-patterns.bats test/skills/arithmetic-eval-gate.bats test/skills/arithmetic-eval-format.bats test/skills/arithmetic-eval-eval.bats test/skills/eval-helpers-empty-report.bats`. Cwd `/workspace`, exit 0, 2026-09-26T04:25:04Z. Output: `1..133`, 133 ok, 9 `# skip`, no `not ok`. `bats --count` per file: 38, 25, 7, 5, 18, 25, 9, 6.

**Evidence:** `docs/reviews/execution-logs/cfc-5bdee46-harness-suites.txt`

---

## Claim 24b: 37c5ea9: "mode1-equiv 33"

**Location:** commit 37c5ea9 message
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the test count of `test/skills/mode1-equiv.bats` at 37c5ea9 and HEAD. Does not affect the correct total of 133.

`bats --count test/skills/mode1-equiv.bats` gives 25 (`cfc-5bdee46-harness-suites.txt`). `git show 37c5ea9:test/skills/mode1-equiv.bats | grep -c '^@test'` gives 25, and 23 at f9feb2c. No commit on the branch has 33. The file is unchanged between 37c5ea9 and HEAD (`git diff --stat 37c5ea9 HEAD` touches only two review docs). The per-file figures as stated sum to 141, not 133. Matches the prior pattern "a specific measured value quoted from a checked-in artifact set that does not contain it" (first seen 2026-08-18).

**Evidence:** `test/skills/mode1-equiv.bats:1`, `docs/reviews/execution-logs/cfc-5bdee46-harness-suites.txt`

---

## Claim 24c: 37c5ea9: "the 9 skips are the report-dependent eval tests"

**Location:** commit 37c5ea9 message
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the skip reasons printed by bats. Does not establish what happens with reports present.

All 9 skips are in `arithmetic-eval-eval.bats` (tests 119-127). Five skip with "No report for … — run generate-reports.bash first". Four skip with "after-denial grading is opt-in: AE_GRADE_AFTER_DENIAL…" (`cfc-5bdee46-harness-suites.txt`). Those four would still skip with reports present, unless the variable is set. Precise version: "5 report-dependent, 4 opt-in after-denial tests".

**Evidence:** `docs/reviews/execution-logs/cfc-5bdee46-harness-suites.txt`

---

## Claim 24d: 37c5ea9: "install-host 91/91; scripts/health-check.sh: \"All checks passed\", exit 0, including its shellcheck section."

**Location:** commit 37c5ea9 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers these runs at HEAD 5bdee46, whose only changes since 37c5ea9 are review docs. Does not establish the report-dependent eval tests, which skip without generated reports.

`bats test/install-host.bats`: `1..91`, 91 ok, exit 0, 2026-09-26T04:25:29Z. `bash scripts/health-check.sh`: cwd `/workspace`, started 2026-09-26T04:23:00Z, ended 04:32:28Z. The log shows "✓ Fast BATS suites passed", "✓ Slow BATS suites passed" and a shellcheck section with ✓ for every changed shell file, including the two `.bats` files R1 was about. It ends "All checks passed." with `EXIT=0`. The warnings printed (skills lacking fixtures, AGENTS/GEMINI drift) are non-failing.

**Evidence:** `docs/reviews/execution-logs/cfc-5bdee46-install-host.txt`, `docs/reviews/execution-logs/cfc-5bdee46-health-check.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 13** (`test/skills/arithmetic-eval/mode1-equiv.py:31-36`): "a transcript event of the wrong shape" → exit 2 and "none can escape as a traceback" are both false. A number-valued `permission_denials`, or an unhashable `tool_use_id` or `id`, still crashes with a traceback and exit 1, because the tripwire runs outside the `try`. Non-object events and string `message`/`content` are skipped and exit 1 as "no Mode 1 call". Either move the tripwire into the SetupError scope and type-check ids, or narrow the docstring.
- **Claim 14** (`mode1-equiv.py:109-110`): "fields have the wrong types is a SetupError" does not cover `id`. An object-valued id crashes at `:183`.
- **Claim 24b** (commit 37c5ea9): "mode1-equiv 33" should be 25. The total of 133 is right.

### Stale
- **Claim 18** (`test/skills/generate-reports.bash:34-37`): the header's FIXTURE_BASH entry lists two voiding conditions. The code has four (parser canary and missing init were added), and the DD doc names this entry as the reference.

### Mostly Accurate
- **Claim 6** (rubric A19 row, and the same line in the commit): the named cases are fixed, but "mis-shaped transcript events raise SetupError (exit 2)" is true only for a Bash tool_use with a bad input or command.
- **Claim 7** (rubric A18 row): the three named places were updated, but the reference the DD doc points to (Claim 18) still lags.
- **Claim 9b** (`dd-arith-eval-bash-grant.md:175`): mode1-equiv's tripwire does not filter denials by `tool_name == "Bash"`, as the generator's does.
- **Claim 12** (`mode1-equiv.py:24-29`): "No '+'" should say "no leading '+'", because `1e+5` is accepted.
- **Claim 16b** (`eval-helpers.bash:378-379`): "truncated" holds only for truncation before the init line. A tail-truncated transcript passes a negative check here and is caught by the generator's `.failed` marker instead.
- **Claim 20c** (`generate-reports.bash:265`): "must start with an init event" should be "must contain". Position is not checked.
- **Claim 21** (`mode1-equiv.bats:241`): the test name's "mode1_equiv resolves by skill" is not proven by this test, which survives the hard-coded-path mutations. The sibling test at :278 proves it.
- **Claim 24c** (commit 37c5ea9): 5 of the 9 skips are report-dependent; the other 4 are opt-in after-denial tests.

### Unverifiable
- (none)

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved to docs/reviews/code-fact-check-report.md, structured per the code-fact-check skill, with header lines `**Commit:** 5bdee46` and `**Replication:** k=1 (loop pass, decision 031)`.
- **Answered:** Yes. The report is at the path with both header lines and the seven mandatory fields plus Legibility-target on all 31 claims. The logs are `docs/reviews/execution-logs/cfc-5bdee46-*`. It covers all three brief items:
  - item 1, 37c5ea9's comments and docs: Claims 1-5, 9-23. The jq block was probed with 24 stub transcripts, mode1-equiv with 35 edge cases, and the patterns suite with 10 mutations.
  - item 2, the commit counts: all rerun, including a full health-check (Claims 24a-24d).
  - item 3, the rubric Fixed rows: Claims 6-8.
- **Out of scope:** Whether Claims 13/14 should be fixed in code or in the docstring (an author/synthesis call). The settled overrides (C4, C24, C30, A1/Q-064, A20).
- **Escalate:** Claim 13 is the only substantive finding. mode1-equiv's promise that a non-model failure never reads as exit 1 does not hold for three malformed-transcript shapes. All are unlikely from the real CLI, and they fail closed (the run does not pass). Claim 24b is a one-number commit-message error in unmerged history.
- **Decisions:** I appended one entry to `docs/reviews/hallucination-patterns.md` for Claim 24b, a count that never existed on the branch, following the precedent of the "All 85 tests" entry. Claims 13 and 14 are not fabrications (the code path exists; its handling is overstated), so they were not logged. Nothing was committed.

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

_(Merged from `code-fact-check-submitted-claims.md`, Stage 2.5 of iteration 4; submitting critic: security-reviewer.)_
