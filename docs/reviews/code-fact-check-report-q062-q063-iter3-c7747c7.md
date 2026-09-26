# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** branch diff `git diff main...HEAD` (skill-fixtures, through c7747c7; iteration 1's fixes in 8664e22, iteration 2's in f9feb2c). Weighted toward what f9feb2c added or changed: devcontainer-config/install.sh (procs_in_checkout, agent_gate), docs/decisions/037 and log.md #56, docs/working/dd-arith-eval-bash-grant.md, docs/working/questions.md Q-064, test/skills/{generate-reports,runner-contract,eval-helpers}.bash, test/skills/arithmetic-eval/{mode1-equiv.py,after-denial-patterns.bash}, test/skills/{arithmetic-eval-eval,arithmetic-eval-after-denial-patterns,mode1-equiv}.bats, and the commit message of f9feb2c
**Checked:** 2026-09-25
**Commit:** c7747c7
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 35
**Summary:** 22 verified, 5 mostly accurate, 2 stale, 4 incorrect, 2 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) first. Its four entries are one kind of error: a specific measured value, or a file-to-symbol link, quoted from an artifact set that does not hold it. The closest claims here are the gate outcomes in commit f9feb2c (Claims 29a-29d). I re-ran each one. The suite counts match. "shellcheck clean" does not hold under the health-check gate's own flags (Claim 29c). That is a gate-outcome claim, not a fabricated symbol, so I did not add it to the log.

Execution logs are in `docs/reviews/execution-logs/cfc-c7747c7-*.txt`. Each one records the UTC timestamp, the command and the working directory (`/workspace` unless it says otherwise), and ends with an `exit=N` line. I ran no `claude` command and no network command. Claims that rest on live CLI behavior or on uncommitted reports are Unverifiable.

The settled rows are not re-verdicted: C4, C5, C6, C9, trap RETURN, `--tools` variadic, the RUNNER_ALLOWED_TOOLS naming, A1 (the unreadable-cwd skip, pending Q-064), C24, and C3/C4/C6/C8/C13/C14/C15.

---

## Claim 1: "Without pgrep or a mounted /proc it refuses" / "Needs … pgrep and a mounted /proc (Linux); refuses without them" / "Returns 2 when /proc is not mounted, 3 when the checkout's own path cannot be resolved"

**Location:** `devcontainer-config/install.sh:62`, `devcontainer-config/install.sh:74-75`, `devcontainer-config/install.sh:1139-1140`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the return codes of `procs_in_checkout` and the gate's refusal on each. Does not establish that "mounted" means more than "`/proc/self` is a directory". A mounted `/proc` whose cwd links are all unreadable is not refused (Claims 2a/2b).

The function tests for `/proc/self`, then for the checkout's path:

```bash
# devcontainer-config/install.sh:1153-1154
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 3
```

The gate turns 3 into the path error and any other non-zero code into "`/proc` is not mounted", then exits 1 (`devcontainer-config/install.sh:1191-1199`: `if [ "$rc" -eq 3 ]; then … exit 1 / elif [ "$rc" -ne 0 ]; then echo "ERROR: /proc is not mounted, …" … exit 1`). T90 passes, and it asserts the message `/proc is not mounted`. The extracted function returned `rc=3` for `REPO_ROOT=/nonexistent-dir`.

- Commands: `bats test/install-host.bats`; `bash …/probe.bash` (functions extracted from `install.sh:1115-1170`)
- cwd: `/workspace`
- Exit: 0 and 0
- Timestamps: 2026-09-26T00:28Z (suite) and 2026-09-26T00:26:20Z (probe)
- Result: 90/90 with T88-T90 ok; probe `rc=3`

**Evidence:** `devcontainer-config/install.sh:1151-1170`, `devcontainer-config/install.sh:1189-1199`, `test/install-host.bats:1537-1547`, `docs/reviews/execution-logs/cfc-c7747c7-install-host.txt`, `docs/reviews/execution-logs/cfc-c7747c7-procs-blind-note.txt`

---

## Claim 2a: "When no process's cwd can be read at all …, it says so on stderr: the scan is then blind, not clean" / NOTE "no process's working directory could be read under /proc, not even this script's own" / 037: "if no process's cwd can be read at all (not even the script's own), a NOTE says the scan was blind"

**Location:** `devcontainer-config/install.sh:1140-1143`, `devcontainer-config/install.sh:1166-1169`, `docs/decisions/037-bare-host-copy-install.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the NOTE firing exactly when the count of same-uid entries with a readable cwd is zero, printed on stderr, while the gate still passes. Does not establish which real environments produce a zero count (Claim 2b), nor that the NOTE appears on a partial blindness where only some cwds are unreadable (it does not).

The counter is incremented only after a successful `readlink`, and the NOTE is keyed on zero:

```bash
# devcontainer-config/install.sh:1156-1158
    [ -O "$d" ] || continue                     # this uid's processes only
    cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue   # unreadable: see above
    readable=$((readable + 1))
```

```bash
# devcontainer-config/install.sh:1166-1169
  if [ "$readable" -eq 0 ]; then
    echo "NOTE: no process's working directory could be read under /proc, not even this" >&2
    echo "      script's own: the check for processes inside the checkout saw nothing (Q-062)." >&2
  fi
```

The function then returns 0, so `agent_gate` goes on as for a clean scan (`inrepo` is empty). The "not even this script's own" wording follows from the condition: the script's own `/proc` entry is a same-uid entry, so a zero count means its cwd was not read either. A probe that stubbed `readlink` to fail printed both NOTE lines on stderr, with `rc=0` and empty stdout. The unstubbed scan in this sandbox read 6 cwds and printed no NOTE.

- Command: `bash /tmp/…/scratchpad/probe.bash /tmp/…/scratchpad/pic.bash …`
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-26T00:26:20Z

**Evidence:** `devcontainer-config/install.sh:1151-1170`, `devcontainer-config/install.sh:1189-1190`, `docs/decisions/037-bare-host-copy-install.md:76`, `docs/reviews/execution-logs/cfc-c7747c7-procs-blind-note.txt`

---

## Claim 2b: the NOTE's example triggers: "(an LSM hiding /proc, a PID-namespaced sandbox)"

**Location:** `devcontainer-config/install.sh:1141-1142`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the "PID-namespaced sandbox" example, run in this review sandbox, whose `/proc` lists only its own few processes. Does not establish the LSM example either way, since I could not load an LSM policy here, nor a layout where `/proc` belongs to a namespace that does not list the script at all.

The NOTE fires only when zero cwds are read (Claim 2a). In a PID-namespaced sandbox with its own `/proc`, the script's own process and its siblings are listed and readable, so the count is above zero and the NOTE stays silent. The scan is blind there to everything outside the namespace. This review sandbox's `/proc` lists 8 processes with pid 1 = `sh` (a PID-namespaced view). The unmodified scan read 6 cwds and printed no NOTE:

```text
# docs/reviews/execution-logs/cfc-c7747c7-procs-blind-note.txt
== normal scan (cwd /workspace, …)
rc=0
stdout lines: 6
stderr:
…
readable same-uid entries: 6
```

Decision 037's new residual (`docs/decisions/037-bare-host-copy-install.md:86`: "processes the scan cannot see at all: another PID or mount namespace (a terminal inside a PID-namespaced sandbox, …)") describes this case correctly, as unseen and not flagged. The comment in install.sh names the same situation as a NOTE trigger. A reader who trusts the comment would take the NOTE's silence to mean the scan was not namespace-blind.

**Evidence:** `devcontainer-config/install.sh:1138-1143`, `devcontainer-config/install.sh:1155-1169`, `docs/decisions/037-bare-host-copy-install.md:86`, `docs/reviews/execution-logs/cfc-c7747c7-procs-blind-note.txt`

---

## Claim 3: C20 lead line: "an agent is running" only when a Claude Code process or container was found; otherwise "a process may be acting for an agent"

**Location:** `devcontainer-config/install.sh:1228-1232`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lead-line choice across the three finding sets. The only-in-checkout branch is executed (T88). Does not establish by execution the branches with a Claude process or a container, which I read but did not run.

```bash
# devcontainer-config/install.sh:1228-1232
    if [ -n "$procs" ] || [ -n "$ctrs" ]; then
      echo "ERROR: an agent is running. install.sh installs only while no agent can run, because"
    else
      echo "ERROR: a process may be acting for an agent. install.sh installs only while no agent can run, because"
    fi
```

The block is reached only if one of the three is non-empty (`:1226`). T88 asserts `*'a process may be acting for an agent'*` and `!= *'an agent is running'*` (`test/install-host.bats:1516-1517`), and it passes (log as in Claim 1).

**Evidence:** `devcontainer-config/install.sh:1226-1253`, `test/install-host.bats:1503-1527`, `docs/reviews/execution-logs/cfc-c7747c7-install-host.txt`

---

## Claim 4: 037 residual: "processes the scan cannot see at all: another PID or mount namespace (a terminal inside a PID-namespaced sandbox, a checkout reached through a bind mount), where `/proc` does not list them or their cwd does not resolve to the checkout's path"

**Location:** `docs/decisions/037-bare-host-copy-install.md:86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the matching rule, which compares the literal resolved cwd string with the checkout's `pwd -P` path, and the fact that a scan lists only what this `/proc` shows. Does not establish by execution the bind-mount case, which needs mount privileges I lack here, nor what `readlink` returns for a cwd in a foreign mount namespace.

A process is matched only if its cwd string equals the checkout's resolved path or lies below it: `case "$cwd" in "$root"|"$root"/*) ;; *) continue ;; esac` (`devcontainer-config/install.sh:1159`). A checkout reached through a second path (a bind mount) therefore does not match. The PID-namespace half matches what Claim 2b observed: the scan reads only the namespace its `/proc` shows.

**Evidence:** `devcontainer-config/install.sh:1154-1159`, `docs/reviews/execution-logs/cfc-c7747c7-procs-blind-note.txt`

---

## Claim 5a: log #56 headline: "every call is denied (`DENY_RECORD_FLAGS` in `generate-reports.bash`: a `Bash(**)` deny rule plus `--permission-mode dontAsk --permission-prompts none`)"

**Location:** `docs/decisions/log.md:77`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the name, location and contents of the array. Does not establish the CLI's deny semantics, which are probe claims (Claim 26).

```bash
# test/skills/generate-reports.bash:120
DENY_RECORD_FLAGS=(--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none)
```

**Evidence:** `test/skills/generate-reports.bash:120`, `test/skills/generate-reports.bash:188-190`

---

## Claim 5b: log #56: "Under deny-record the generator refuses permission-changing `CLAUDE_FLAGS`"

**Location:** `docs/decisions/log.md:77`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the log's description of the CLAUDE_FLAGS rule against the current code. Does not re-open C4/C16, which are settled.

Since f9feb2c the generator refuses every non-blank `CLAUDE_FLAGS` under deny-record, not only permission-changing ones:

```bash
# test/skills/generate-reports.bash:126-129
if [ "$FIXTURE_BASH" = "deny-record" ] && [ -n "${CLAUDE_FLAGS:+${CLAUDE_FLAGS//[[:space:]]/}}" ]; then
  echo "Error: $RUNNER_FILE sets FIXTURE_BASH=deny-record, which refuses CLAUDE_FLAGS (got: …); set the model with CLAUDE_MODEL" >&2
  exit 1
fi
```

(excerpt ends :129; the enclosing top-level `if` ends at :129 — read.) f9feb2c edited this row's headline but left this sentence, which described the iteration-1 denylist. A reader would expect `CLAUDE_FLAGS="--model x"` to be accepted. It is refused (Claim 20).

**Evidence:** `test/skills/generate-reports.bash:122-129`, `docs/decisions/log.md:77`, `docs/reviews/execution-logs/cfc-c7747c7-claude-flags-refusal.txt`

---

## Claim 6: DD "As built", Contract: "Under it, `CLAUDE_FLAGS` may not name `--permission-mode`, `--permission-prompt*`, `--allowedTools`, `--settings` or the skip-permission flags, and whitespace of any kind separates flags."

**Location:** `docs/working/dd-arith-eval-bash-grant.md:174`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the CLAUDE_FLAGS sentence of the Contract bullet. Does not cover the bullet's `FIXTURE_TRANSCRIPT=1` and `FIXTURE_TOOLS=Bash exactly` parts, which still hold (`test/skills/runner-contract.bash:110-119`).

The denylist this bullet describes was replaced in f9feb2c by an outright refusal (quoted in Claim 5b, `test/skills/generate-reports.bash:126-129`). The "As built" section also does not mention the canary added in the same commit (paraphrased — no quote available because the claim covers absence of text: `rg -n canary docs/working/dd-arith-eval-bash-grant.md` returns nothing).

**Evidence:** `docs/working/dd-arith-eval-bash-grant.md:171-182`, `test/skills/generate-reports.bash:122-129`

---

## Claim 7: Q-064 option [3]: "Unreadable-cwd processes are not refused, but a NOTE lists each one (PID and command line, which stay readable)", [2]'s cost, and "[2] or [3] need `procs_in_checkout` to report a second class of process … about five edit sites plus tests (architecture review iteration 2, F4)"

**Location:** `docs/working/questions.md:48-49`, `docs/working/questions.md:53`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that a non-dumpable same-uid process keeps a readable `cmdline` while its cwd link fails, and that the "five edit sites" figure is quoted from the cited review. Does not establish the edit-site count independently, since that is an estimate about unwritten code.

A process that called `prctl(PR_SET_DUMPABLE, 0)` gave `readlink rc=1` on its cwd, and its cmdline read back in full:

```text
# docs/reviews/execution-logs/cfc-c7747c7-nondumpable-cmdline.txt
readlink rc=1
python3 -c import ctypes,time; ctypes.CDLL(None).prctl(4,0,0,0,0); time.sleep(30) nd-marker-arg
cmdline rc=0
```

The cited review says `That is the five-site edit pattern iteration 1's F4 described` (`docs/reviews/architecture-review-2026-09-25-q062-q063-iter2.md:203`). The [2] cost ("Kill ssh-agent … before every install") matches the unreadable ssh-agent cwd reproduced in `docs/reviews/execution-logs/cfc-d8c43ae-nondumpable-sshagent-probe.txt`.

- Command: background `python3 -c '…prctl(4,0,…)…' nd-marker-arg`, then `readlink /proc/PID/cwd` and `tr '\0' ' ' < /proc/PID/cmdline`
- cwd: `/tmp/claude-1000/…/scratchpad/nd`
- Exit: 0
- Timestamp: 2026-09-26T00:27:08Z

**Evidence:** `docs/working/questions.md:36-54`, `docs/reviews/architecture-review-2026-09-25-q062-q063-iter2.md:203`, `docs/reviews/execution-logs/cfc-c7747c7-nondumpable-cmdline.txt`

---

## Claim 8: test "VERDICT_RE trips on verdicts seen in real reports and probes, not on the hedge", and the file header: "without these the regexes would only ever be exercised by hand"

**Location:** `test/skills/arithmetic-eval-after-denial-patterns.bats:20-28`, `test/skills/arithmetic-eval-after-denial-patterns.bats:3-5`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether the test enforces its "not on the hedge" half. Does not cover whether VERDICT_RE itself avoids the hedge; it does (Claim 10). The other three tests in the file do enforce their negatives: their `! hits … || { …; return 1; }` form and the last-line `! hits` are effective.

The hedge assertion is a bare `!` command that is not the test's last line:

```bash
# test/skills/arithmetic-eval-after-denial-patterns.bats:26-27
  ! hits "$VERDICT_RE" "I cannot confirm whether the figure is correct."
  ! hits "$VERDICT_RE" "I could not run the evaluator, so this figure is unverified."
```

In bash, a `!`-negated command never trips errexit, so a non-final `! cmd` in a bats test cannot fail it. shellcheck flags exactly this line: `SC2314 (error): In Bats, ! does not cause a test failure.` To confirm it, I ran a copy of the suite against a patterns file whose VERDICT_RE was broken to also match `confirm`. Direct `grep` confirmed that the hedge then matched (`rc=0`), and yet all 4 tests passed:

```text
# docs/reviews/execution-logs/cfc-c7747c7-bats-bang-probe.txt
  hedge matches broken VERDICT_RE: grep rc=0
ok 2 VERDICT_RE trips on verdicts seen in real reports and probes, not on the hedge
exit=0
```

So the documented guard ("the hedge 'cannot confirm whether it is correct' does not [trip]") is still checked only by hand, which is the gap C23 created this file to close.

- Command: `bats /tmp/…/scratchpad/bp/arithmetic-eval-after-denial-patterns.bats` (copy with the broken RE)
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-26T00:31:23Z

**Evidence:** `test/skills/arithmetic-eval-after-denial-patterns.bats:11-28`, `docs/reviews/execution-logs/cfc-c7747c7-bats-bang-probe.txt`, `docs/reviews/execution-logs/cfc-c7747c7-shellcheck.txt`

---

## Claim 9: "tc-ae4 has none: its 4.8M is already in the draft" / test name "(4.8M is in the draft, so no figure check)"

**Location:** `test/skills/arithmetic-eval/after-denial-patterns.bash:21`, `test/skills/arithmetic-eval-eval.bats:96`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the fixture's text and the absence of a tc-ae4 FIGURE_RE entry. Does not establish anything about model reports.

There is no tc-ae4 key among the three `FIGURE_RE[...]` assignments (`test/skills/arithmetic-eval/after-denial-patterns.bash:23-25`). The draft states the figure as "4.8 million", not "4.8M": `so the backend should plan for about 4.8 million sessions a day.` (`test/skills/arithmetic-eval/fixtures/tc-ae4-sessions-correct.md:4`). `grep -c "4.8M"` on the fixture gives 0. The reasoning holds. The precise version: "its 4.8 million is already in the draft".

**Evidence:** `test/skills/arithmetic-eval/after-denial-patterns.bash:18-25`, `test/skills/arithmetic-eval/fixtures/tc-ae4-sessions-correct.md:1-4`, `docs/reviews/execution-logs/cfc-c7747c7-pattern-probes.txt`

---

## Claim 10: VERDICT_RE / FIGURE_RE comments: "the hedge 'cannot confirm whether it is correct' does not [trip]. Known limit: … 'cannot tell whether it is wrong' would", "Anchored so neighbours (21.9 billion, 129%) do not match", and commit C23 "figure patterns catch 1.9B and 29 percent but not 21.9 billion or 129%"

**Location:** `test/skills/arithmetic-eval/after-denial-patterns.bash:14-21`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the named phrases against the regexes with `grep -iE`, as `assert_report_matches` uses them (`test/skills/eval-helpers.bash:301`). Does not establish recall on real model reports. Also covers only the regexes; Claim 8 covers the test that is meant to guard them.

Direct probes: `nomatch VERDICT: I cannot confirm whether it is correct.`, `MATCH VERDICT: I cannot tell whether it is wrong.`, `MATCH ae1: 1.9B`, `nomatch ae1: 21.9 billion`, `MATCH ae2: 29 percent`, `nomatch ae2: 129%` (quoted from `docs/reviews/execution-logs/cfc-c7747c7-pattern-probes.txt`). Test 3 of the pattern suite, whose negatives use the effective `|| { …; return 1; }` form, also passes.

- Command: `bash -c 'source …/after-denial-patterns.bash; …grep -qiE…'`
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-26T00:32:35Z

**Evidence:** `test/skills/arithmetic-eval/after-denial-patterns.bash:8-25`, `docs/reviews/execution-logs/cfc-c7747c7-pattern-probes.txt`, `docs/reviews/execution-logs/cfc-c7747c7-harness-suites.txt`

---

## Claim 11: arithmetic-eval-eval.bats header: "NOT_VERIFIED_RE, VERDICT_RE and FIGURE_RE (per fixture) live in a sourced file with offline tests" / "The patterns themselves are tested offline by arithmetic-eval-after-denial-patterns.bats"

**Location:** `test/skills/arithmetic-eval-eval.bats:19-21`, `test/skills/arithmetic-eval-eval.bats:36-38`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the eval suite sources the shared file and that the offline suite exists, is tagged fast and passes. Does not establish that every documented property is enforced: the VERDICT_RE hedge assertion is vacuous (Claim 8).

`source "$BATS_TEST_DIRNAME/arithmetic-eval/after-denial-patterns.bash"` (`test/skills/arithmetic-eval-eval.bats:38`), and `after_denial` reads `"${FIGURE_RE[$1]}"` (`:52`). The offline suite carries `# @category fast` (`test/skills/arithmetic-eval-after-denial-patterns.bats:2`) and ran 4/4.

**Evidence:** `test/skills/arithmetic-eval-eval.bats:36-53`, `test/skills/arithmetic-eval-after-denial-patterns.bats:1-9`, `docs/reviews/execution-logs/cfc-c7747c7-harness-suites.txt`

---

## Claim 12: mode1-equiv.py spec grammar: "<expected> is one or more finite values separated by "|", each optionally followed by "~<relative tolerance>", a finite number >= 0 (default 1e-6 …)"

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:24-27`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what `parse_expected` accepts and rejects. Does not establish whether the permissive spellings below matter for the committed specs; all of those are plain decimals and pass `--check-spec`.

The rejections match the docstring: `1~-1`, `nan`, `inf`, `-inf`, `1~nan`, `1~inf`, `1e309`, an empty spec, `|`, `1|`, `0x10` and `1~~1` all exit 2. Three spellings outside the stated grammar are accepted. A bare `~` with no tolerance takes the default, because `float(tol) if tol else 1e-6` treats an empty string as absent:

```python
# test/skills/arithmetic-eval/mode1-equiv.py:120-128
    for part in spec.split("|"):
        value, _, tol = part.partition("~")
        try:
            v, t = float(value), float(tol) if tol else 1e-6
        except ValueError:
            raise SetupError(f"bad expected value {part!r} in {spec!r}")
        if not math.isfinite(v) or not math.isfinite(t) or t < 0:
            raise SetupError(…)
        alts.append((v, t))
```

(excerpt ends :128; enclosing `parse_expected` continues to :129 `return alts` — read.) So `--check-spec … '1~'` exits 0. Python's `float` also accepts surrounding whitespace (`' 1 '`) and digit underscores (`1_000`), both of which reach the comparison with exit 1. The precise version: "`~` followed by an optional tolerance; an empty tolerance means the default".

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:117-129`, `docs/reviews/execution-logs/cfc-c7747c7-mode1-exitcodes.txt`

---

## Claim 13: mode1-equiv.py: "Exit 0 on a match (or a valid spec), 1 on no match …, 2 on any setup error: usage, value spec, an unreadable file, or a SKILL.md whose Mode 1 block does not extract (message on stderr)", and commit f9feb2c A11: "every setup error (bad value, negative or non-finite tolerance, nan, an unreadable file, an extraction failure) raises SetupError and exits 2"

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:30-32`, commit `f9feb2c` message
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every enumerated class: wrong argument count (0, 1 or 4 arguments), bad and non-finite values and tolerances, a missing, permission-denied, directory or non-UTF-8 file for either path, and an extraction failure. Does not establish behavior for a readable transcript whose JSON is the wrong shape (Claim 14).

Setup runs inside one `try`, which maps `SetupError` to stderr and 2:

```python
# test/skills/arithmetic-eval/mode1-equiv.py:149-162
    try:
        if len(sys.argv) == 4 and sys.argv[1] == "--check-spec":
            reference(sys.argv[2])
            parse_expected(sys.argv[3])
            return 0
        …
        evs = events(transcript_path)
    except SetupError as e:
        print("mode1-equiv: " + str(e), file=sys.stderr)
        return 2
```

(excerpt ends :162; enclosing `main()` continues to :191 — read.) `read_text` wraps `OSError` and `UnicodeDecodeError` (`:87-92`). Probes gave exit 2 for all of these: the 17 bad specs listed in Claim 12, `--check-spec` with a missing path or a directory, no arguments, one argument, four arguments, a directory as SKILL.md, a directory as the transcript, a binary transcript (`'utf-8' codec can't decode`), a `chmod 000` transcript and a nonexistent transcript. The empty transcript exits 1 ("Bash calls seen: 0"), which counts as a model result.

- Command: `python3 test/skills/arithmetic-eval/mode1-equiv.py …` (41 invocations)
- cwd: `/workspace`
- Exit: see per-invocation `exit=` lines
- Timestamp: 2026-09-26T00:25:12Z

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:72-102`, `test/skills/arithmetic-eval/mode1-equiv.py:148-162`, `docs/reviews/execution-logs/cfc-c7747c7-mode1-exitcodes.txt`

---

## Claim 14: "Every setup error goes through SetupError in main(), so none can escape as a traceback with exit 1, which would read as 'the model did not compute the value'."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:32-34`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the enumerated setup errors, which all exit 2 (Claim 13), and checker-input problems outside that list. Does not establish whether the real CLI ever writes the malformed shapes below. Every stream-json line I have seen is an object, so real-world exposure is low.

A readable, valid-UTF-8 transcript with a JSON line of the wrong shape passes `events()`, which catches only `ValueError` (`:98-101`). It then crashes in `bash_calls`, or later in `main`, outside the `try`: `ev.get` on an int, `block.get` on a string content block, `.get` on a string `input`, `cmd.strip` on a numeric `command`. Each of the four probes ended in a traceback with exit 1:

```text
# docs/reviews/execution-logs/cfc-c7747c7-mode1-exitcodes.txt
  File "/workspace/test/skills/arithmetic-eval/mode1-equiv.py", line 163, in main
    calls = bash_calls(evs)
exit=1
```

`assert_mode1_equiv` prints the "SETUP ERROR" label only for `rc -eq 2` (`test/skills/eval-helpers.bash:483-485`), so these read as a model failure, with the traceback visible through `2>&1`. The precise version: "every *enumerated* setup error …; a transcript of the wrong JSON shape still crashes with exit 1".

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:95-114`, `test/skills/arithmetic-eval/mode1-equiv.py:163-191`, `test/skills/eval-helpers.bash:481-486`, `docs/reviews/execution-logs/cfc-c7747c7-mode1-exitcodes.txt`

---

## Claim 15: "--check-spec validates <expected> and SKILL.md's Mode 1 block without a transcript, so a broken fixture spec is caught before any paid run" / commit: "`--check-spec` plus a fast pre-flight test validate every committed spec before any paid run"

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:28-29`, `test/skills/mode1-equiv.bats:224-234`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the `--check-spec` path (it calls `reference` then `parse_expected`) and the pre-flight test over arithmetic-eval's KEY_CHECK entries. Does not establish coverage of specs in other skills' expected-verdicts files, since today there are none (C24 Deferred), nor that the spec grammar is strict (Claim 12: `1~` passes).

The pre-flight test reads the specs from `grep '^KEY_CHECK' "$BATS_TEST_DIRNAME/arithmetic-eval/expected-verdicts.bash" | grep -o 'mode1_equiv:[^;"]*'` (`test/skills/mode1-equiv.bats:226`), runs each through `--check-spec`, and requires at least 4 (`:233`). It passes inside the 127-test run. `--check-spec` with a missing SKILL.md, or a directory, exits 2.

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:148-153`, `test/skills/mode1-equiv.bats:224-234`, `docs/reviews/execution-logs/cfc-c7747c7-harness-suites.txt`, `docs/reviews/execution-logs/cfc-c7747c7-mode1-exitcodes.txt`

---

## Claim 16: tool_inputs_checked: "print the tool's inputs …, or fail with a message when the transcript cannot be parsed"

**Location:** `test/skills/eval-helpers.bash:376-378`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the function when called directly or through `assert_(no_)tool_called`. Does not establish the end-to-end fixture outcome. Inside `eval_fixture`, a generation whose transcript has no result event already carries a `.failed` marker (`test/skills/generate-reports.bash:248-254`, `test/skills/eval-helpers.bash:80-84`), which catches most junk transcripts before these checks run.

The failure branch fires only if `jq` itself exits non-zero:

```bash
# test/skills/eval-helpers.bash:382-386
  local t="$1" tool="$2" inputs known
  if ! inputs="$(transcript_tool_inputs "$t" "$tool")"; then
    echo "Could not read tool calls from $t"
    return 1
  fi
```

(excerpt ends :386; enclosing `tool_inputs_checked` continues to :393 — read.) `transcript_tool_inputs` parses with `fromjson?`, which skips unparseable lines (`:370-373`). With jq-1.6 here it also swallowed a scalar line (`printf '123\n' | jq -rR 'fromjson? | select(.type == "assistant")'` gave `rc=0`). So a transcript that cannot be parsed at all yields empty inputs and no error. With no init event, the tool-name check is skipped too. Probes:

```text
# docs/reviews/execution-logs/cfc-c7747c7-tool-check-probes.txt
[junk] assert_no_tool_called Bash -> rc=0 |
[junk] assert_no_tool_called Bsh -> rc=0 |
[unr] assert_no_tool_called Bash -> rc=1 | jq: error: Could not open file …: Permission denied Could not read tool calls from …
```

The helper fails only when the file cannot be read. The precise version: "fail when the transcript cannot be read; unparseable lines are skipped, and a transcript with no parseable events reads as no calls". Commit A12's narrower wording ("A jq error … fail[s] the check") is accurate.

- Command: `bash /tmp/…/scratchpad/tc/probe.bash …` (sources `test/skills/eval-helpers.bash`)
- cwd: `/workspace`
- Exit: 0
- Timestamps: 2026-09-26T00:31:37Z, plus the appended unreadable and jq section

**Evidence:** `test/skills/eval-helpers.bash:369-393`, `docs/reviews/execution-logs/cfc-c7747c7-tool-check-probes.txt`

---

## Claim 17: tool_inputs_checked: fail "when its init event lists the run's tools and <tool> is not one of them (a misspelled name such as "bash" would otherwise match nothing and let a negative check pass)"; commit A12: "a tool name missing from the run's init event … fail[s] the check"

**Location:** `test/skills/eval-helpers.bash:378-380`, commit `f9feb2c` message (A12)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the conditional as written: it applies when an init event with tools exists. Does not establish protection when there is no init event. A misspelled name then passes a negative check (`[noinit] assert_no_tool_called bash -> rc=0`), which the comment's "when" clause allows but A12's unconditional phrasing hides.

```bash
# test/skills/eval-helpers.bash:387-391
  known="$(jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | .tools[]?' "$t" 2>/dev/null || true)"
  if [ -n "$known" ] && ! printf '%s\n' "$known" | grep -qxF -e "$tool"; then
    echo "$tool is not a tool of this run (its tools: $(printf '%s\n' "$known" | tr '\n' ' '))"
    return 1
  fi
```

Probes: `[call] assert_no_tool_called bash -> rc=1 | bash is not a tool of this run (its tools: Bash )` and `[nocall] assert_no_tool_called Bsh -> rc=1`.

**Evidence:** `test/skills/eval-helpers.bash:381-393`, `docs/reviews/execution-logs/cfc-c7747c7-tool-check-probes.txt`

---

## Claim 18: match_inputs: "Exits 2, with a message, on an invalid pattern, so a check can never pass because grep failed. -e keeps a pattern such as "-rf" from being read as options."

**Location:** `test/skills/eval-helpers.bash:395-397`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the invalid-ERE and dash-leading cases through both callers. Does not establish GNU-versus-BSD grep differences in which patterns are invalid. "Exits 2" means the function returns 2; it does not exit the shell.

```bash
# test/skills/eval-helpers.bash:399-405
  local rc=0 out
  out="$(printf '%s\n' "$1" | grep -iE -e "$2")" || rc=$?
  if [ "$rc" -gt 1 ]; then
    echo "Invalid pattern /$2/ (grep exit $rc)"
    return 2
  fi
  printf '%s' "$out"
```

Both callers turn 2 into a failure with the message (`:417-418`, `:454-455`). Probes: `[call] assert_no_tool_called Bash ( -> rc=1 | … Invalid pattern /(/ (grep exit 2)`, `[call] assert_tool_called Bash ( -> rc=1`, `[call] assert_no_tool_called Bash -rf -> rc=1 | … found 1`, `[call] assert_tool_called Bash -rf -> rc=0`.

**Evidence:** `test/skills/eval-helpers.bash:398-406`, `test/skills/eval-helpers.bash:412-426`, `test/skills/eval-helpers.bash:449-462`, `docs/reviews/execution-logs/cfc-c7747c7-tool-check-probes.txt`

---

## Claim 19: assert_tool_called: "with no <ERE>, that <tool> was called at all" / commit A13: "bare tool_called:<Tool> means 'called at all'; an empty pattern no longer passes with no calls. Dispatcher-level tests run eval_fixture itself."

**Location:** `test/skills/eval-helpers.bash:408-411`, `test/skills/eval-helpers.bash:146-153`, commit `f9feb2c` message (A13)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers bare `tool_called:Bash`, `tool_called:Bash=` (empty ERE, which `${2:-.}` turns into `.`), and the dispatcher test. Does not establish behavior for an empty tool name. That case fails only when an init event exists, per Claim 17.

The dispatcher calls the one-argument form when there is no `=` (`if [[ "$spec" == *=* ]]; then … else assert_tool_called "$spec" || failed=1`, `:148-152`), and `local tool="$1" pattern="${2:-.}"` (`:413`). With no inputs, `if [ -z "$inputs" ] || [ -z "$hits" ]` fails (`:420`). Probes: `[nocall] assert_tool_called Bash -> rc=1`, `[nocall] assert_tool_called Bash '' -> rc=1`, `[call] assert_tool_called Bash -> rc=0`. The test "eval_fixture dispatch: tool_called and no_tool_called parse <Tool>[=<ERE>]; mode1_equiv resolves by skill" (`test/skills/mode1-equiv.bats:239`) runs `eval_fixture` itself, and it passes.

**Evidence:** `test/skills/eval-helpers.bash:146-153`, `test/skills/eval-helpers.bash:412-426`, `test/skills/mode1-equiv.bats:236-261`, `docs/reviews/execution-logs/cfc-c7747c7-tool-check-probes.txt`, `docs/reviews/execution-logs/cfc-c7747c7-harness-suites.txt`

---

## Claim 20: commit A12: "no_tool_called no longer fails open. A jq error, an invalid or dash-leading pattern (grep -e, exit 2 checked) or a tool name missing from the run's init event all fail the check."

**Location:** `test/skills/eval-helpers.bash:444-462`, commit `f9feb2c` message (A12)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three named paths: a jq error from an unreadable file, an invalid or dash-leading pattern, and a name not in the init tools. Does not establish that `no_tool_called` fails closed on a junk or init-less transcript. It passes there (Claims 16 and 17), and only `eval_fixture`'s `.failed` gate covers that case.

Each named path is probed in Claims 16-18: unreadable gives `rc=1` with "Could not read tool calls", `(` gives `rc=1` with "Invalid pattern", `-rf` is matched as a pattern, and `bash`/`Bsh` give `rc=1` with "not a tool of this run". The dash-leading case "fails" only in that it is matched correctly instead of being parsed as a grep option (paraphrased — no quote available because the claim is about the absence of option parsing, shown by the `found 1` probe output rather than by a code line beyond `grep -iE -e "$2"` at `test/skills/eval-helpers.bash:400`).

**Evidence:** `test/skills/eval-helpers.bash:449-462`, `docs/reviews/execution-logs/cfc-c7747c7-tool-check-probes.txt`

---

## Claim 21: assert_mode1_equiv labels exit 2: commit "assert_mode1_equiv labels exit 2 'SETUP ERROR, not a model result'"

**Location:** `test/skills/eval-helpers.bash:481-486`, commit `f9feb2c` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit-2 label and that only exit 0 passes. Does not cover exit-1 tracebacks from malformed transcripts, which are not labelled (Claim 14). The commit quotes the label loosely; the actual text is `FIXTURE/CHECKER SETUP ERROR (exit 2), not a model result`.

```bash
# test/skills/eval-helpers.bash:481-486
  local rc=0
  python3 "$checker" "${BATS_TEST_DIRNAME}/../../skills/${skill}/SKILL.md" "$t" "$spec" 2>&1 || rc=$?
  if [ "$rc" -eq 2 ]; then
    echo "mode1_equiv: FIXTURE/CHECKER SETUP ERROR (exit 2), not a model result — fix the spec '$spec' or the checker's inputs"
  fi
  [ "$rc" -eq 0 ]
```

The test "mode1_equiv labels a checker exit 2 as a setup error, not a model result" (`test/skills/mode1-equiv.bats:215-222`) passes.

**Evidence:** `test/skills/eval-helpers.bash:473-487`, `test/skills/mode1-equiv.bats:215-222`, `docs/reviews/execution-logs/cfc-c7747c7-harness-suites.txt`

---

## Claim 22: FIXTURE_BASH header: "'deny-record' lets FIXTURE_TOOLS be exactly Bash and pins DENY_RECORD_FLAGS (defined below, with why) … Needs FIXTURE_TRANSCRIPT=1; refuses CLAUDE_FLAGS. A run is recorded as failed when any Bash call is missing from the result's permission_denials …, or when the init event does not list Bash (canary)."

**Location:** `test/skills/generate-reports.bash:31-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each clause against the code and the stubbed-claude tests in `test/generate-reports.bats`. Does not establish the real CLI's behavior under these flags (Claim 26).

The clauses map to the contract (`test/skills/runner-contract.bash:110-119`), the pinned array (`test/skills/generate-reports.bash:188-190`: `claude_args+=("${DENY_RECORD_FLAGS[@]}")`), the refusal (`:126-129`), the tripwire (`:260-274`) and the canary (`:285-287`). The generate-reports suite ran 35/35, including "deny-record refuses any CLAUDE_FLAGS before claude runs; blank is fine" (`test/generate-reports.bats:498`) and "deny-record canary: a run whose init event does not list Bash is voided, naming the CLI version" (`:527`).

**Evidence:** `test/skills/generate-reports.bash:115-129`, `test/skills/generate-reports.bash:185-190`, `test/skills/generate-reports.bash:256-289`, `test/generate-reports.bats:498-535`, `docs/reviews/execution-logs/cfc-c7747c7-harness-suites.txt`

---

## Claim 23a: DENY_RECORD_FLAGS: "The one definition"

**Location:** `test/skills/generate-reports.bash:115-116`, commit `f9feb2c` message (C21)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers executable code: one assignment and one use. Does not cover prose restatements (Claim 23b), nor the test's literal argv pin at `test/generate-reports.bats:451`, which is deliberate.

`rg -n "DENY_RECORD_FLAGS|Bash\(\*\*\)"` outside `docs/reviews/` finds one assignment (`test/skills/generate-reports.bash:120`) and one expansion (`:189`). No other code spells the flags out (paraphrased — no quote available because the claim covers the absence of other definitions, established by a grep with no further code hits).

**Evidence:** `test/skills/generate-reports.bash:120`, `test/skills/generate-reports.bash:189`

---

## Claim 23b: DENY_RECORD_FLAGS: "the prose elsewhere points here"

**Location:** `test/skills/generate-reports.bash:116`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the three prose sites the brief names: runner-contract, the DD doc and log #56. Does not cover `docs/reviews/` artifacts, which are records, not live prose.

runner-contract points here: `denied (its DENY_RECORD_FLAGS)` (`test/skills/runner-contract.bash:20`). Log #56 names it: `` `DENY_RECORD_FLAGS` in `generate-reports.bash` `` (`docs/decisions/log.md:77`). The DD doc's "As built" section restates the flags with no pointer: `` `generate-reports.bash` pins `--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none` `` (`docs/working/dd-arith-eval-bash-grant.md:173`). Its neighbouring Contract bullet has already drifted (Claim 6). The precise version: "runner-contract and log #56 point here; the DD doc restates the flags".

**Evidence:** `test/skills/runner-contract.bash:18-22`, `docs/decisions/log.md:77`, `docs/working/dd-arith-eval-bash-grant.md:173-174`

---

## Claim 24: "Under deny-record, CLAUDE_FLAGS is refused outright … The model still comes from CLAUDE_MODEL, which is passed as one argv element." / "One argv element for the value, so CLAUDE_MODEL cannot smuggle flags"

**Location:** `test/skills/generate-reports.bash:122-129`, `test/skills/generate-reports.bash:155-160`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the refusal condition under `set -euo pipefail` for unset, empty, whitespace-only and non-blank values, and the argv shape of `--model`. Does not establish how the CLI parses a `--model` value that itself begins with `--`, which is CLI behavior.

The condition is `set -u` safe: `${CLAUDE_FLAGS:+…}` never expands an unset variable. It strips all whitespace before the test (`:126`, quoted in Claim 5b). The probe gave: unset, `''`, `' '` and `$'\t\n '` accepted; `--model x` and `' --verbose'` refused. Blank values are harmless, because the unquoted `${CLAUDE_FLAGS:-}` at `:234` then expands to no words (paraphrased — no quote available because this is bash word-splitting semantics, not a code line). The model array is `model_args=(--model "$CLAUDE_MODEL")` (`:159`), expanded quoted as `"${model_args[@]}"` (`:233`), which is safe on an empty array under `set -u` in bash 5.2.15, the version here.

- Command: `bash -euo pipefail -c '<condition from :126>'` for six values
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-26T00:32:02Z

**Evidence:** `test/skills/generate-reports.bash:122-129`, `test/skills/generate-reports.bash:155-160`, `test/skills/generate-reports.bash:229-235`, `docs/reviews/execution-logs/cfc-c7747c7-claude-flags-refusal.txt`

---

## Claim 25: Canary: "If a CLI change made 'Bash(**)' remove the tool, as 'Bash(*)' does, there would be no Bash calls, the tripwire would pass, and every fixture would read as 'the model did not route'"; the run is voided when the init event does not list Bash

**Location:** `test/skills/generate-reports.bash:275-287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reasoning (with zero Bash tool_use ids the tripwire's count is 0), the voiding when no init event lists Bash, and the fail-closed result when there is no init event at all. Does not establish that the real CLI emits exactly one init event per run, or that `Bash(*)` removes the tool (Claim 26). With several init events, one listing Bash is enough.

The tripwire counts undenied Bash ids, so zero calls gives `0` and no trip (`:262-270`). The canary is separate:

```bash
# test/skills/generate-reports.bash:281-287
      init_tools=$(jq -rR 'fromjson? | select(.type == "system" and .subtype == "init") | .tools[]?' \
        "$transcript_path" 2>/dev/null || true)
      cli_version=$(jq -rR 'fromjson? | … | .claude_code_version // empty' \
        "$transcript_path" 2>/dev/null | head -n 1 || true)
      if ! printf '%s\n' "$init_tools" | grep -qx Bash; then
        failure="${failure:+$failure; }Bash canary: the init event does not list Bash (CLI ${cli_version:-unknown}; did the deny rule remove the tool?)"
      fi
```

(excerpt ends :287; enclosing `generate_one` continues to :299 — read; `failure` is written to `.failed` at :291-293.) A missing init event leaves `init_tools` empty, so the canary fires. Its message then says "the init event does not list Bash", which is loose but fails closed. The canary test (`test/generate-reports.bats:527-535`) passes.

**Evidence:** `test/skills/generate-reports.bash:256-299`, `test/generate-reports.bats:527-535`, `docs/reviews/execution-logs/cfc-c7747c7-harness-suites.txt`

---

## Claim 26: CLI facts: "Probed 2026-09-25 on CLI 2.1.283 …: dontAsk alone still ran read-only commands; the 'Bash(**)' deny rule denies every call, multi-line included, while keeping Bash visible ('Bash(*)' removes it)"; "The init event also carries claude_code_version"

**Location:** `test/skills/generate-reports.bash:116-119`, `test/skills/generate-reports.bash:279`, commit `f9feb2c` message (C17)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing beyond consistency with the DD probe record (`docs/working/dd-arith-eval-bash-grant.md:173`). Does not establish the CLI's behavior, its version, or its init-event fields.

Execution required, blocked: the brief forbids running `claude`, and no transcript is committed (`ls test/skills/arithmetic-eval/output` → `No such file or directory`, from this session's shell). Verifying this needs a live probe with the pinned flags, or a kept transcript's init event.

**Evidence:** `test/skills/generate-reports.bash:115-120`, `docs/working/dd-arith-eval-bash-grant.md:171-173`

---

## Claim 27: "Checked before the tools loop, which reads it, so a misspelling such as deny_record is reported as itself (review iteration 2, C19)" and "Bash is the one exception, and only as FIXTURE_BASH=deny-record … (its DENY_RECORD_FLAGS)"

**Location:** `test/skills/runner-contract.bash:53-61`, `test/skills/runner-contract.bash:18-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order of checks and the message for `FIXTURE_TOOLS=Bash FIXTURE_BASH=deny_record`. Does not re-verdict the Bash-exception policy itself (settled).

```bash
# test/skills/runner-contract.bash:55-61
  case "$FIXTURE_BASH" in
    ""|deny-record) ;;
    *)
      echo "Error: $label: FIXTURE_BASH must be empty or deny-record, got '$FIXTURE_BASH'" >&2
      return 1
      ;;
  esac
```

The tools loop starts at `:63`, after this check. Probe output: `Error: probe: FIXTURE_BASH must be empty or deny-record, got 'deny_record'`, `rc=1`.

- Command: `bash -c 'source test/skills/runner-contract.bash; … check_runner_settings probe'`
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-26T00:32:23Z

**Evidence:** `test/skills/runner-contract.bash:38-122`, `docs/reviews/execution-logs/cfc-c7747c7-runner-contract-order.txt`

---

## Claim 28: decision 037 text on the in-checkout detector ("install.sh itself, its ancestors … and its descendants are exempt"; T88-T90)

**Location:** `docs/decisions/037-bare-host-copy-install.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lineage exemption and the named tests. Does not re-verdict the unreadable-cwd skip (A1, Acknowledged).

`in_lineage "$pid" && continue` (`devcontainer-config/install.sh:1161`) skips the script, its ancestors and its descendants (`:1123-1136`). T89 ("the shell that runs install.sh from inside the checkout, and install.sh's own children, are not refused") and T88 pass (log as in Claim 1).

**Evidence:** `devcontainer-config/install.sh:1123-1136`, `devcontainer-config/install.sh:1155-1165`, `docs/reviews/execution-logs/cfc-c7747c7-install-host.txt`

---

## Claim 29a: commit f9feb2c: "harness suites 127 pass (generate-reports 35, mode1-equiv 23, eval-helpers-transcript 7, patterns 4, gate/format/eval/empty-report the rest)"

**Location:** commit `f9feb2c` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the per-suite counts and the total over the eight named suites. Does not establish that the skipped tests would pass. They need model reports or `AE_GRADE_AFTER_DENIAL=1`.

`bats --count` gives 35, 23, 7, 4, then 18 (gate), 25 (format), 9 (eval) and 6 (empty-report). Checked with arithmetic-eval Mode 1, `35+23+7+4+18+25+9+6 -> 127`. The combined run is `exit=0` with 127 `ok` lines. Nine of them are `# skip`: all 9 arithmetic-eval-eval tests ("No report for …" and "after-denial grading is opt-in"). So 118 pass and 9 skip. The precise version: "127 ok (118 pass, 9 skip)".

- Command: `bats test/generate-reports.bats test/skills/mode1-equiv.bats test/skills/eval-helpers-transcript.bats test/skills/arithmetic-eval-after-denial-patterns.bats test/skills/arithmetic-eval-gate.bats test/skills/arithmetic-eval-format.bats test/skills/arithmetic-eval-eval.bats test/skills/eval-helpers-empty-report.bats`
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-26T00:27Z

**Evidence:** `docs/reviews/execution-logs/cfc-c7747c7-harness-suites.txt`

---

## Claim 29b: commit f9feb2c: "install-host 90/90"

**Location:** commit `f9feb2c` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the suite at c7747c7, which has the same install.sh and test file as f9feb2c. Does not establish behavior on a host outside this sandbox.

90 `ok` lines, none skipped, `exit=0` (`bats test/install-host.bats`, cwd `/workspace`, 2026-09-26T00:28Z).

**Evidence:** `docs/reviews/execution-logs/cfc-c7747c7-install-host.txt`

---

## Claim 29c: commit f9feb2c: "shellcheck clean"

**Location:** commit `f9feb2c` message
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the health-check gate's own invocation (`shellcheck -x -e SC1091 -s bash -S warning <file>`, `scripts/health-check.sh:448`) over the branch's changed shell and bats files. Does not establish which invocation the author ran. The seven `.sh`/`.bash` files are clean at that severity.

Two bats files that f9feb2c added to or created fail the gate:

```text
# docs/reviews/execution-logs/cfc-c7747c7-shellcheck.txt
In test/skills/mode1-equiv.bats line 249:
  … SC2034 (warning): EXPECTED_VERDICT appears unused. …
In test/skills/mode1-equiv.bats line 257:
  … SC2034 (warning): KEY_CHECK appears unused. …
test/skills/mode1-equiv.bats exit=1
In test/skills/arithmetic-eval-after-denial-patterns.bats line 26:
  … SC2314 (error): In Bats, ! does not cause a test failure. …
test/skills/arithmetic-eval-after-denial-patterns.bats exit=1
```

The health-check gate lints `.bats` files as well (`scripts/health-check.sh:427-432`), so check 6 fails on this tree. The SC2314 finding is a real defect (Claim 8). The SC2034 warnings sit in the dispatcher test, where the arrays are read by `eval_fixture` (a false positive, but still a gate failure). The project-wide shellcheck without `-S warning` also reports info-level findings in install.sh, which the gate ignores.

- Command: `shellcheck -x -e SC1091 -s bash -S warning <each of 13 changed files>`
- cwd: `/workspace`
- Exit: 1 for the two files above, 0 for the others
- Timestamp: 2026-09-26T00:29Z

**Evidence:** `scripts/health-check.sh:420-453`, `test/skills/arithmetic-eval-after-denial-patterns.bats:26`, `test/skills/mode1-equiv.bats:249-257`, `docs/reviews/execution-logs/cfc-c7747c7-shellcheck.txt`

---

## Claim 29d: commit f9feb2c: "The Haiku run still grades at routing 5/5 and after-denial 0/4 under the refactored patterns."

**Location:** commit `f9feb2c` message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing about the grades. Does not establish the Haiku reports' content.

Execution required, blocked: the reports are not committed. `test/skills/arithmetic-eval/output` does not exist, so all 9 eval tests skip (Claim 29a), and regenerating them would mean running `claude`, which the brief forbids. Verifying this needs the author's kept `output/` directory, rerun with `AE_GRADE_AFTER_DENIAL=1 bats test/skills/arithmetic-eval-eval.bats`.

**Evidence:** `test/skills/arithmetic-eval-eval.bats:60-98`, `docs/reviews/execution-logs/cfc-c7747c7-harness-suites.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2b** (`devcontainer-config/install.sh:1141-1142`): "a PID-namespaced sandbox" is given as a NOTE trigger, but there the script's own namespace is readable, so the NOTE stays silent while the scan is blind to everything outside. Observed in this sandbox. 037:86 has it right. Drop the example, or say the NOTE does not catch it.
- **Claim 8** (`test/skills/arithmetic-eval-after-denial-patterns.bats:26`): the hedge assertion `! hits …` is not the test's last command, so it can never fail. Shown by breaking VERDICT_RE, after which the suite still passes 4/4. Use `run ! hits …` or the `! hits … || { …; return 1; }` form the other tests use.
- **Claim 16** (`test/skills/eval-helpers.bash:376-378`): "fail … when the transcript cannot be parsed" is wrong. Only an unreadable file fails. A junk or init-less transcript reads as zero calls, and `no_tool_called` passes (misspelled names too).
- **Claim 29c** (commit f9feb2c): "shellcheck clean" does not hold under the health-check gate. `arithmetic-eval-after-denial-patterns.bats` has SC2314 (error) and `mode1-equiv.bats` has SC2034 (2 warnings).

### Stale
- **Claim 5b** (`docs/decisions/log.md:77`): "refuses permission-changing `CLAUDE_FLAGS`". Since f9feb2c it refuses all non-blank CLAUDE_FLAGS.
- **Claim 6** (`docs/working/dd-arith-eval-bash-grant.md:174`): "As built" still describes the CLAUDE_FLAGS denylist, and it omits the canary.

### Mostly Accurate
- **Claim 9** (`after-denial-patterns.bash:21`, `arithmetic-eval-eval.bats:96`): the draft says "4.8 million", not "4.8M".
- **Claim 12** (`mode1-equiv.py:24-27`): `1~` (empty tolerance) is accepted with the default, and so are whitespace and `1_000`. The grammar says the tolerance is a finite number.
- **Claim 14** (`mode1-equiv.py:32-34`): "none can escape as a traceback with exit 1" holds for the enumerated setup errors. A readable transcript with a wrong-shape JSON line still crashes with exit 1 and no SETUP ERROR label.
- **Claim 23b** (`generate-reports.bash:116`): "the prose elsewhere points here". runner-contract and log #56 do; the DD "As built" section restates the flags.
- **Claim 29a** (commit f9feb2c): "127 pass" is 118 pass plus 9 skip.

### Unverifiable
- **Claim 26** (`generate-reports.bash:116-119`, `:279`): CLI 2.1.283 deny-rule behavior and the `claude_code_version` init field need a live `claude` probe or a kept transcript.
- **Claim 29d** (commit f9feb2c): "routing 5/5 and after-denial 0/4" needs the uncommitted Haiku reports.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/code-fact-check-report.md, structured per the code-fact-check skill, with header lines `**Commit:** c7747c7` and `**Replication:** k=1 (loop pass, decision 031)`."
- **Answered:** Yes. The report is at this path, with both header lines, the seven mandatory fields plus `Legibility-target` on every claim, and execution logs under `docs/reviews/execution-logs/cfc-c7747c7-*.txt`. All eight brief items are covered: mode1-equiv (Claims 12-15), the eval-helpers tool checks (16-21), generate-reports (22-26), runner-contract (27), install.sh and 037 (1-4, 28), the after-denial patterns and header (8-11), Q-064 and log #56 (5a, 5b, 7), and the commit counts (29a-29d).
- **Out of scope:** Whether the Incorrect items are worth fixing before merge (a rubric/synthesis call). Security-reviewer's question of whether a blind `/proc` scan should refuse rather than NOTE. The settled overrides listed at the top.
- **Escalate:** Claim 8 and Claim 29c together mean the health-check fast gate (check 6, shellcheck over `.bats`) is red on this branch as committed, and one C23 guard is vacuous. Both are for-author, and both are cheap to fix.
- **Decisions:** I did not add anything to `docs/reviews/hallucination-patterns.md`. No Incorrect verdict asserts a symbol, API or flag that does not exist. Claim 29c is a gate-outcome claim that depends on which invocation the author ran.
