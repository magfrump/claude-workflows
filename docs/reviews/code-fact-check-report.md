# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** branch diff `git diff main...HEAD` (skill-fixtures, 7 commits `86bb2c6..5ddf804`): devcontainer-config/install.sh, docs/decisions/037 + log.md #56, docs/working/dd-arith-eval-bash-grant.md + questions docs, test/generate-reports.bats, test/install-host.bats, test/skills/{runner-contract,generate-reports,eval-helpers}.bash, test/skills/arithmetic-eval/*, test/skills/{arithmetic-eval-eval,mode1-equiv}.bats, and the commit messages on main..HEAD
**Checked:** 2026-09-25
**Commit:** 5ddf804
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 38
**Summary:** 25 verified, 7 mostly accurate, 1 stale, 2 incorrect, 3 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. All four logged patterns are "a specific measured value or file-to-symbol association quoted from an artifact set that does not contain it". The claims closest to that class are the test-count claims (Claims 35, 36), which were re-executed and match, and the "5/5 through Mode 1" run claim (Claim 12), which rests on gitignored reports and is Mostly accurate, not fabricated. No claim in this pass matches a logged pattern.

Execution logs are in `docs/reviews/execution-logs/cfc-5ddf804-*.txt`. Each one records a UTC timestamp, the command and working directory (`/workspace` unless stated otherwise), and a trailing `exit N` line.

Settled override-log rows were respected: C4 (operator-controlled CLAUDE_FLAGS), C5, C6, C9, trap RETURN, `--tools` variadic, and RUNNER_ALLOWED_TOOLS naming are not re-verdicted. Where a finding touches C4 (Claim 32), it is recorded in Scope only.

---

## Claim 1: "refuses while it finds … any other process of your uid whose working directory is inside the checkout (/proc; Q-062), such as a helper or loop driver an agent left running, or an editor or shell sitting in the repo"

**Location:** `devcontainer-config/install.sh:51-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the refusal of a non-Claude same-uid process whose `/proc/<pid>/cwd` is in the checkout and that is not in install.sh's lineage, including a shell that is a sibling of install.sh. Does not establish detection of a same-uid process whose cwd link is unreadable (non-dumpable; see Claim 6), of processes outside the checkout, or of install.sh's own ancestors (exempt by design).

The detector is wired into `agent_gate`, and a non-empty result refuses:

```bash
# devcontainer-config/install.sh:1173-1175
  inrepo="$(procs_in_checkout)" || rc=$?
  if [ "$rc" -ne 0 ]; then
    echo "ERROR: /proc is not readable, so install.sh cannot check for processes working" >&2
```
(excerpt ends :1175; enclosing agent_gate() continues to :1226, read). `:1203` then reads `if [ -z "$procs" ] && [ -z "$inrepo" ] && [ -z "$ctrs" ]; then return 0; fi`, and otherwise the function prints the `inrepo` block and runs `exit 1` (`:1212-1226`).

Executed. `bats -f 'T8[89]|T90' test/install-host.bats` (cwd `/workspace`, 2026-09-25T23:12:40Z, exit 0): T88 starts a `sleep 300` whose cwd is `$ROOT/skills`, and asserts exit 1 with `"$helper sleep 300"` named. The lineage probe (2026-09-25T23:16:52Z, exit 0) runs `procs_in_checkout` against a scratch repo. It lists a sibling `bash -c` subshell (a shell in the repo that is not an ancestor) and a sibling `sleep 30`, and it lists neither the script's own child nor its command-substitution subshells.

**Evidence:** `devcontainer-config/install.sh:1138-1154`, `devcontainer-config/install.sh:1158-1226`, `test/install-host.bats:1503-1523`, `docs/reviews/execution-logs/cfc-5ddf804-install-T88-90.txt`, `docs/reviews/execution-logs/cfc-5ddf804-lineage-probe.txt`

---

## Claim 2: "Without pgrep or /proc it refuses" / "Needs git, perl …, pgrep and a readable /proc (Linux); refuses without them."

**Location:** `devcontainer-config/install.sh:62`, `devcontainer-config/install.sh:74-75`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the refusal (exit 1, "/proc is not readable") when `/proc/self` is absent. Does not establish refusal when `/proc` is mounted but some or all per-process `cwd` links are unreadable: those processes are skipped silently (`readlink … || continue`), which fails open per process (Claim 6). Also not established: that the "/proc is not readable" message is accurate in the other `return 2` path, a failing `cd "$REPO_ROOT"`, where it misattributes the cause.

```bash
# devcontainer-config/install.sh:1141-1143
  local root d pid cwd cmd
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 2
```
(excerpt ends :1143; enclosing procs_in_checkout() continues to :1154, read)

`agent_gate` turns any non-zero status into exit 1 (`install.sh:1173-1178`, partly quoted in Claim 1). Executed: T90 rewrites the probe to `/nonexistent/self`, and the run exits 1 with `/proc is not readable` and no bless (log below, exit 0). The pgrep half predates this branch (T53, which passed in the full-suite run).

**Evidence:** `devcontainer-config/install.sh:1140-1154`, `devcontainer-config/install.sh:1159-1178`, `test/install-host.bats:1534-1546`, `docs/reviews/execution-logs/cfc-5ddf804-install-T88-90.txt`, `docs/reviews/execution-logs/cfc-5ddf804-install-host-full.txt`

---

## Claim 3: "Read from /proc (Linux; the install already needs GNU tools)"

**Location:** `devcontainer-config/install.sh:1111-1112`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of pre-existing GNU-only tool uses in install.sh. Does not establish that the script was ever run or tested on a non-GNU platform.

```bash
# devcontainer-config/install.sh:659-661
    find "$dir/$pfx$name" -printf '%P\t%y\t%m\t%l\n' | LC_ALL=C sort
    find "$dir/$pfx$name" -type f -print0 | LC_ALL=C sort -z | xargs -0 -r sha256sum | cut -d' ' -f1
  done | sha256sum | cut -d' ' -f1
```
`find -printf` (also at `:410`, `:417`) and `sha256sum` are GNU findutils/coreutils. Commit 47a3818's note ("already needs GNU sha256sum/find -printf") says the same thing.

**Evidence:** `devcontainer-config/install.sh:410`, `devcontainer-config/install.sh:417`, `devcontainer-config/install.sh:659-661`

---

## Claim 4: "install.sh itself, its ancestors (the shell that ran it) and its descendants (its own subshells and git calls) are not 'other'" / in_lineage: "true if <pid> is this script, an ancestor of it, or a descendant of it"

**Location:** `devcontainer-config/install.sh:1112-1113`, `devcontainer-config/install.sh:1122-1123`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `in_lineage`'s two walks and the premise that `$$` inside command substitutions and subshells is install.sh's PID. Does not establish behavior across PID namespaces, and does not exempt descendants of an ancestor (siblings), which is correct per the claim.

```bash
# devcontainer-config/install.sh:1125-1136
in_lineage() {
  local p="$1" q="$$"
  while [ -n "$p" ] && [ "$p" -gt 1 ]; do
    [ "$p" = "$$" ] && return 0
    p="$(ppid_of "$p")"
  done
  while [ -n "$q" ] && [ "$q" -gt 1 ]; do
    [ "$q" = "$1" ] && return 0
    q="$(ppid_of "$q")"
  done
  return 1
}
```
The first loop walks up from the candidate to `$$` (descendant, or self). The second walks up from `$$` to the candidate (ancestor). `procs_in_checkout` runs inside `inrepo="$(procs_in_checkout)"`, a subshell. Executed: the lineage probe prints `$$=3213644` both in the script and inside `$(…)`, where `BASHPID` differs (`3213648`). The script's own child and its substitution subshells are absent from the output, and a sibling started by the parent shell is listed. T89 (the invoking shell cwd'd in the repo) installs with no "working inside" line.

**Evidence:** `devcontainer-config/install.sh:1125-1136`, `devcontainer-config/install.sh:1149`, `devcontainer-config/install.sh:1173`, `docs/reviews/execution-logs/cfc-5ddf804-lineage-probe.txt`, `docs/reviews/execution-logs/cfc-5ddf804-install-T88-90.txt`

---

## Claim 5: "ppid_of <pid>: print its parent PID, or nothing once it has exited."

**Location:** `devcontainer-config/install.sh:1115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the output for a live pid and for a missing `/proc/<pid>/status`. Does not establish the return status's effect under `set -e`; every caller sits in an `&&`/`||` context where errexit is off.

```bash
# devcontainer-config/install.sh:1116-1121
ppid_of() {
  local k v _
  while read -r k v _; do
    [ "$k" = "PPid:" ] && { printf '%s\n' "$v"; return 0; }
  done 2>/dev/null < "/proc/$1/status"
}
```
Executed (lineage probe, section B): `ppid_of 999999999` prints nothing (rc=1, no stderr), and `ppid_of $$` equals `$PPID`.

**Evidence:** `devcontainer-config/install.sh:1116-1121`, `docs/reviews/execution-logs/cfc-5ddf804-lineage-probe.txt`

---

## Claim 6: "procs_in_checkout: print 'PID command line' for each other process of this uid whose working directory is $REPO_ROOT or below it."

**Location:** `devcontainer-config/install.sh:1138-1139`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the loop's filters (owner, cwd prefix, lineage, empty cmdline). Does not establish coverage of same-uid processes whose `cwd` link cannot be read. Those are skipped, not reported, and not refused.

```bash
# devcontainer-config/install.sh:1144-1153
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
    cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue
    case "$cwd" in "$root"|"$root"/*) ;; *) continue ;; esac
    pid="${d#/proc/}"
    in_lineage "$pid" && continue
    cmd="$(tr '\0' ' ' 2>/dev/null < "$d/cmdline")"
    [ -n "$cmd" ] || continue                   # exited, or a kernel thread
    printf '%s %s\n' "$pid" "${cmd% }"
  done
```
(excerpt ends :1153; enclosing procs_in_checkout() closes at :1154, read)

"Each other process of this uid" is not quite what the code does. Executed (non-dumpable probe, 2026-09-25T23:17:21Z, cwd = scratch `repo`, exit 0): a uid-1000 Python process that calls `prctl(PR_SET_DUMPABLE, 0)` keeps `/proc/<pid>` owned by uid 1000 (`-O` true), but `readlink /proc/<pid>/cwd` fails. The `|| continue` at `:1146` then drops it silently. The control (a dumpable process in the same directory) resolves its cwd. So a same-uid process working in the checkout that makes itself non-dumpable, which one syscall does, is invisible to the gate. Precise version: "…for each other process of this uid whose working directory is readable and is $REPO_ROOT or below it; one whose cwd cannot be read is skipped."

**Evidence:** `devcontainer-config/install.sh:1138-1154`, `docs/reviews/execution-logs/cfc-5ddf804-nondumpable-probe.txt`

---

## Claim 7: "A Claude Code process already listed above is not named twice."

**Location:** `devcontainer-config/install.sh:1179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the de-duplication by field-1 PID. Does not establish correct handling of backslashes in `$procs` (awk `-v` processes escapes), which could only alter command-line text, never the leading PID field.

```bash
# devcontainer-config/install.sh:1180-1182
  inrepo="$(printf '%s\n' "$inrepo" | awk -v seen="$procs" '
    BEGIN { n = split(seen, l, "\n"); for (i = 1; i <= n; i++) { split(l[i], f, " "); skip[f[1]] = 1 } }
    NF && !($1 in skip)')"
```
`$procs` is `pgrep -af` output ("PID cmdline" lines). A PID in it is dropped from `inrepo`.

**Evidence:** `devcontainer-config/install.sh:1165-1170`, `devcontainer-config/install.sh:1180-1182`

---

## Claim 8: "It checks at four moments: at startup …; again at the start of the host target, before it stages …; and after each y"

**Location:** `docs/decisions/037-bare-host-copy-install.md:74`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four `agent_gate` call sites, and so the new detector, which lives inside `agent_gate`. Does not establish that those call sites are reached on every path. A declined y returns before the post-y gate, which is correct, since nothing is installed.

paraphrased — no quote available because the claim spans four separate call sites. `grep -n agent_gate` gives `:1287` (`agent_gate "Nothing was staged or installed."`, startup), `:780` (host target, before staging), `:553` (devcontainer, after its y) and `:992` (host, after its y). All are plain statements, not pipelines. The Q-062 detector runs at all four because it is called from inside `agent_gate` (`:1173`).

**Evidence:** `devcontainer-config/install.sh:553`, `devcontainer-config/install.sh:780`, `devcontainer-config/install.sh:992`, `devcontainer-config/install.sh:1287`, `devcontainer-config/install.sh:1173`

---

## Claim 9: "An editor or shell sitting in the repo is refused too, by design; the message names it (T88–T90)."

**Location:** `docs/decisions/037-bare-host-copy-install.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the refusal and naming of any non-lineage process with a readable cwd in the checkout (a shell sibling was observed). Does not establish that an editor is named. No test runs an editor, and T88 names a `sleep`. It also does not cover the invoking shell, which is exempt (T89).

The message block names each entry:

```bash
# devcontainer-config/install.sh:1212-1217
    if [ -n "$inrepo" ]; then
      echo "       Other processes of uid $(id -u) working inside $REPO_ROOT (Q-062; an"
      echo "       agent may have left them running), PID and command line:"
      printf '%s\n' "$inrepo" | sed 's/^/           /'
      echo "       Stop them, or cd each one out of the checkout (an editor or shell counts)."
    fi
```
(excerpt ends :1217; enclosing agent_gate() continues to :1226, read). Executed: the lineage probe lists a sibling `bash -c` process in the repo, and T88 passes.

**Evidence:** `devcontainer-config/install.sh:1212-1217`, `docs/reviews/execution-logs/cfc-5ddf804-lineage-probe.txt`, `docs/reviews/execution-logs/cfc-5ddf804-install-T88-90.txt`

---

## Claim 10a: "install.sh's own ancestors are exempt, so a loop driver that itself runs `install.sh` is not seen"

**Location:** `docs/decisions/037-bare-host-copy-install.md:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the ancestor exemption in `in_lineage`'s second walk. Does not establish anything about a loop driver's children that are not install.sh's ancestors; those are siblings and are refused.

`in_lineage`'s second loop starts at `q="$$"` and returns 0 when any ancestor equals the candidate (`install.sh:1131-1134`, quoted in Claim 4), and `procs_in_checkout` skips on `in_lineage "$pid" && continue` (`:1149`).

**Evidence:** `devcontainer-config/install.sh:1125-1136`, `devcontainer-config/install.sh:1149`

---

## Claim 10b: "What the gate does not see (review A2) … it misses: … a same-uid process that is not Claude Code and works *outside* the checkout … One working inside the checkout is detected (Q-062 [2], below)."

**Location:** `docs/decisions/037-bare-host-copy-install.md:82-84`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether the residual list names every class of in-checkout process the new detector misses. Does not re-verify the other residual bullets (pre-existing, unchanged on this branch).

"One working inside the checkout is detected" holds only for processes whose `/proc/<pid>/cwd` is readable. As Claim 6 shows (executed), a same-uid process that sets itself non-dumpable has an unreadable `cwd` link and is skipped by `readlink "$d/cwd" 2>/dev/null)" || continue` (`install.sh:1146`). The residual list does not name this class. Precise version: add "or one working inside the checkout whose `/proc/<pid>/cwd` cannot be read (e.g. a non-dumpable process)" to the bullet.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:82-84`, `devcontainer-config/install.sh:1146`, `docs/reviews/execution-logs/cfc-5ddf804-nondumpable-probe.txt`

---

## Claim 11: "The runner contract refuses Bash in any other form. Under deny-record the generator refuses permission-changing `CLAUDE_FLAGS`, and it voids a run if any Bash call is missing from `permission_denials` (tripwire)."

**Location:** `docs/decisions/log.md:77`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the contract refusal, the refusal of the listed CLAUDE_FLAGS spellings, and the tripwire. Does not establish that every permission-changing flag spelling is refused (see Claim 32's scope), or the CLI's denial semantics (Claim 30b). The same row's "wrapper matched exactly" is verdicted in Claim 22.

Executed: `bats test/generate-reports.bats` (2026-09-25T23:14:29Z, exit 0, 32/32). Tests 29 and 30 cover refusal of Bash without deny-record and of `Bash(python3:*)`, test 31 covers refused flag spellings, and test 32 covers the tripwire. See Claims 31 and 34 for the code.

**Evidence:** `test/skills/runner-contract.bash:57-86`, `test/skills/generate-reports.bash:114-124`, `test/skills/generate-reports.bash:249-261`, `docs/reviews/execution-logs/cfc-5ddf804-generate-reports-bats.txt`

---

## Claim 12: "The first run (Haiku 4.5, 5 fixtures) routed 5/5 through Mode 1." / "The first Haiku run routed 5 of 5 fixtures through Mode 1"

**Location:** `docs/decisions/log.md:77`, `docs/working/questions-archive.md:1320`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the internal consistency of the claim with the fixture set and eval checks. Does not establish the run's actual outcomes, because the reports and transcripts are gitignored (`.gitignore:5: test/skills/*/output/`) and absent from this checkout.

The fifth fixture is the negative, which by design must *not* route:

```bash
# test/skills/arithmetic-eval/expected-verdicts.bash:44-46
EXPECTED_VERDICT["tc-ae5-no-arithmetic.md"]="does not route"
CLAIM_ACCURACY["tc-ae5-no-arithmetic.md"]="sound"  # No derived figures, so no evaluator call
KEY_CHECK["tc-ae5-no-arithmetic.md"]="no_tool_called:Bash"
```
Commit e6043df says "routing 5/5" and "health-check's only failures were those 4 model-graded tests", so tc-ae5 passed `no_tool_called:Bash`, which means it made no Bash call. "Routed 5/5 through Mode 1" therefore cannot be literally true. Precise version: "4/4 derived-figure fixtures routed through Mode 1, and the no-arithmetic negative made no Bash call (5/5 routing tests passed)."

**Evidence:** `test/skills/arithmetic-eval/expected-verdicts.bash:44-46`, `test/skills/arithmetic-eval-eval.bats:72-74`, `docs/decisions/log.md:77`, `docs/working/questions-archive.md:1320`

---

## Claim 13: "`eval-helpers.bash`: a new check, `mode1_equiv:<expected value>`. … rejects it if it holds an `EXPREOF` line … A second new check, `no_bash_executed`, is the tripwire … Fixtures: repo mode, 4 planted-wrong-figure drafts plus 1 no-math negative (`no_pattern` on the tag, and no Bash `tool_use`)."

**Location:** `docs/working/dd-arith-eval-bash-grant.md:153-154`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the "What changes in plan step 5" bullets against what was built. Does not judge the plan's design.

The doc's status line (`:5`) says "Built the same day". The implementation differs from these bullets in four places:
- No `no_bash_executed` check exists (paraphrased — no quote available because the claim is about absence: `grep -rn no_bash_executed test/` finds nothing). The tripwire lives in the generator (`generate-reports.bash:249-260`) and in `mode1-equiv.py:107-112`.
- Fixtures are inline, not repo mode: `FIXTURE_MODE="inline"` (`test/skills/arithmetic-eval/runner.bash:13`).
- Three fixtures are planted wrong, not four, plus one correct figure (`expected-verdicts.bash:27-39`).
- There is no explicit `EXPREOF`-line rejection (Claim 15).

**Evidence:** `docs/working/dd-arith-eval-bash-grant.md:5`, `docs/working/dd-arith-eval-bash-grant.md:153-154`, `test/skills/arithmetic-eval/runner.bash:13`, `test/skills/arithmetic-eval/expected-verdicts.bash:27-46`

---

## Claim 14: Probe and run results — "Probe A … (b) The `tool_result` has `is_error:true` … (c) The result event's `permission_denials` lists …; `probe-ran` was not created, so nothing executed"; "Haiku dropped every Python comment"; "A denied call is recorded in the stream and in the result event's permission_denials (probed 2026-09-25)"; "After the denial it fell back to mental math 4/4"; "health-check's only failures were those 4 model-graded tests"

**Location:** `docs/working/dd-arith-eval-bash-grant.md:161-167`, `test/skills/runner-contract.bash:22-24`, `docs/decisions/log.md:77`, commits `f8fdc3d`, `e6043df`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers only that the cited sources exist and agree with each other. Does not establish any CLI behavior (denial, recording, non-execution) or any model behavior. Blocker: execution requires running `claude`, which this pass is barred from, and the probe and run transcripts and reports are not in the repo.

The runner-contract comment's reference resolves: the DD doc has a "Probe results (2026-09-25 …)" section at `:157`. The probe's check design (regex wrapper + `ast.dump`, a one-token `MAX_BITS = 100001` tamper rejected) is reproduced offline by `mode1-equiv.bats` tests 3 and 4, which pass (Claim 23). The probe's claims about what the CLI and Haiku did cannot be re-observed here. To verify: rerun Probe A with the cheapest model in a scratch dir, and check in or attach the first run's `output/*.transcript.jsonl`.

**Evidence:** `docs/working/dd-arith-eval-bash-grant.md:157-169`, `test/skills/runner-contract.bash:18-25`, `test/skills/mode1-equiv.bats:57-72`

---

## Claim 15: "It checks three things: the wrapper matches exactly, `ast.dump(program)` equals the reference, and the expression is non-empty with no `EXPREOF` line."

**Location:** `docs/working/dd-arith-eval-bash-grant.md:169`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the third check as it exists in the equivalence helper. Does not establish that the missing check allows a false pass. It does not (see Claim 22): the reference evaluator rejects any expression holding an `EXPREOF` line or an empty one.

`mode1-equiv.py` has no explicit non-empty or `EXPREOF`-line check on the expression:

```python
# test/skills/arithmetic-eval/mode1-equiv.py:127-129
        expr = w.group("expr")
        value = evaluate(ref_program, expr)
        print(f"  call {i}: Mode 1, expression {expr!r} -> {value}")
```
(excerpt ends :129; enclosing main() continues to :133, read). Executed (mode1 probe P1, 2026-09-25T23:15:17Z): a command with a second `EXPREOF` line is classified `Mode 1`, and its expression `'2\nEXPREOF\ntouch pwned'` goes to the evaluator (`-> None`). The rejection comes from the evaluator's SyntaxError, not from a check in the helper. Precise version: "…and the expression, whatever it holds, is run through the reference evaluator, which yields no value for an empty body or one holding an `EXPREOF` line."

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:98-133`, `docs/reviews/execution-logs/cfc-5ddf804-mode1-probes.txt`

---

## Claim 16: generate-reports.bats deny-record test names (tests 28–32)

**Location:** `test/generate-reports.bats:442-510`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each test's assertions match its name: argv pin; the TRANSCRIPT, Bash and FIXTURE_BASH-value refusals; `Bash(python3:*)` refused; six flag spellings refused and `--model m` accepted with no claude call; the tripwire's `.failed` present then absent. Does not establish CLI behavior (the tests use a claude stub).

paraphrased — no quote available because the claim covers five test bodies. Each was read in full. For example, test 28 asserts `*"--tools Bash --permission-mode dontAsk --permission-prompts none"*` in the stub's recorded argv (`:447`), and test 32 greps `"Bash tripwire: 1 Bash call"` in `tc-1-thing.txt.failed` and then asserts it is gone after a denied stream (`:504-509`). Executed: 32/32 pass.

**Evidence:** `test/generate-reports.bats:422-510`, `docs/reviews/execution-logs/cfc-5ddf804-generate-reports-bats.txt`

---

## Claim 17: "Nothing executes." / "Nothing ever executes." / "Nothing runs"

**Location:** `test/skills/arithmetic-eval-eval.bats:7`, `test/skills/arithmetic-eval/runner.bash:6`, `test/skills/runner-contract.bash:21`, `docs/decisions/log.md:77`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the narrow reading: no command the model proposes is executed by the harness. The generator pins the deny flags, and a Bash call not listed as denied voids the run. Does not establish (1) the CLI's denial itself (Claim 30b, Unverifiable). It also does not establish (2) that nothing model-derived runs at all: at eval time `mode1-equiv.py` feeds the model's heredoc body as stdin data to the reference evaluator via `python3 -c`, with `timeout=10` and without the SKILL.md `ulimit` wrapper.

```python
# test/skills/arithmetic-eval/mode1-equiv.py:85-88
def evaluate(program, expr):
    """Run <expr> through the reference evaluator; return its value or None."""
    r = subprocess.run(["python3", "-c", program], input=expr + "\n",
                       capture_output=True, text=True, timeout=10)
```
(excerpt ends :88; enclosing evaluate() continues to :95, read). The program is SKILL.md's AST allowlist, never the model's copy (Claim 24), so only numeric evaluation is reachable.

**Evidence:** `test/skills/generate-reports.bash:181-183`, `test/skills/generate-reports.bash:249-261`, `test/skills/arithmetic-eval/mode1-equiv.py:85-95`

---

## Claim 18: "VERDICT_RE is a heuristic …; 'cannot confirm it is correct' would not trip it, but 'Result: CORRECT', 'INCORRECT', 'off by' and the check marks do."

**Location:** `test/skills/arithmetic-eval-eval.bats:28-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the named example strings under `grep -iE`, which `assert_report_not_matches` uses (`eval-helpers.bash:303`). Does not establish the regex's recall on unseen verdict phrasings. For example, "this is correct" and "the figure is wrong" do not trip it (observed), consistent with "heuristic".

Executed (2026-09-25T23:14:18Z, exit 0): "cannot confirm it is correct" gives no match. "Result: CORRECT", "INCORRECT", "it is off by 10x" and "✓ ok" all match.

**Evidence:** `test/skills/arithmetic-eval-eval.bats:35`, `test/skills/eval-helpers.bash:301-308`, `docs/reviews/execution-logs/cfc-5ddf804-verdict-re.txt`

---

## Claim 19: test names "Mode 1 call computes 1.9 billion" / "computes 29.2%" / "computes 42.16 km"

**Location:** `test/skills/arithmetic-eval-eval.bats:56-66`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the match between each test name and the KEY_CHECK it runs. Does not assess whether the alternate values are good routes.

Each test passes on any listed value, not only the one named:

```bash
# test/skills/arithmetic-eval/expected-verdicts.bash:28,32,36
KEY_CHECK["tc-ae1-inference-tokens-tenfold.md"]="mode1_equiv:1900000000|1900000|47500"
KEY_CHECK["tc-ae2-growth-percent-overstated.md"]="mode1_equiv:29.1666666667|0.291666666667|1.29166666667|3.408"
KEY_CHECK["tc-ae3-marathon-km-wrong.md"]="mode1_equiv:42.16~0.002|28.09~0.002"
```
So "computes 29.2%" also passes when the only Mode 1 call computes `2.4 * 1.42 = 3.408`. Precise version: "a Mode 1 call computes 1.9 billion or an equivalent check".

**Evidence:** `test/skills/arithmetic-eval-eval.bats:56-66`, `test/skills/arithmetic-eval/expected-verdicts.bash:26-40`

---

## Claim 20: "Several expressions are valid routes, e.g. computing the figure or checking the claimed one backwards, so each lists the values any of them would give."

**Location:** `test/skills/arithmetic-eval/expected-verdicts.bash:8-10`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the listed value sets against the routes the header itself names (forward and backward checks). Does not establish which routes models actually take.

The lists cover several routes but not "any of them". For tc-ae4 the listed values are `4800000|4` (`:40`), so the backward check `4.8M / 1.2M = 4` passes. The equally backward `4800000 / 4 = 1200000` is not listed, and neither is tc-ae3's implied factor `45.2 / 26.2`. Executed (claim-accuracy log): 4800000/1200000 = 4.0. Precise version: "…so each lists the values the common routes give".

**Evidence:** `test/skills/arithmetic-eval/expected-verdicts.bash:8-10`, `test/skills/arithmetic-eval/expected-verdicts.bash:36-40`, `docs/reviews/execution-logs/cfc-5ddf804-claim-accuracy.txt`

---

## Claim 21: CLAIM_ACCURACY arithmetic — "4750 / 0.0025 * 1000 = 1.9 billion, not 19 billion"; "(3.1 - 2.4) / 2.4 = 29.2%"; "26.2 mi * 1.609344 = 42.16 km … (tolerance covers 1.609 and 1.61 as the factor)"; "1.2M * 4 = 4.8M"

**Location:** `test/skills/arithmetic-eval/expected-verdicts.bash:27-39`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four computations, the tc-ae3 tolerance cover for factors 1.609, 1.61 and 1.609344 on both 42.16 and 28.09, and the default-1e-6 matches of the tc-ae2 alternates. Does not establish route completeness (Claim 20).

Executed (python3, 2026-09-25T23:14:00Z, exit 0): `1900000000.0`, `0.29166…` / `29.1666…`, `42.1648128` (1.609 → rel 9.96e-5, 1.61 → rel 5.2e-4, both within 0.002), `28.0859…` (all within 0.002 of 28.09), and `4800000.0`. `3.1/2.4 = 1.2916…` and `2.4*1.42 = 3.408` match at the default tolerance. The fixtures' figures ($4,750, $0.0025/1K, 19 billion; $2.4M → $3.1M, 42%; 26.2 mi, 45.2 km; 1.2M × 4 = 4.8M) match the comments.

**Evidence:** `test/skills/arithmetic-eval/expected-verdicts.bash:27-40`, `test/skills/arithmetic-eval/fixtures/tc-ae1-inference-tokens-tenfold.md:3-5`, `docs/reviews/execution-logs/cfc-5ddf804-claim-accuracy.txt`

---

## Claim 22: "requires the shell wrapper to be SKILL.md's Mode 1 wrapper exactly … with only blank or `#` comment lines after the closing EXPREOF" (also "with the wrapper matched exactly", log #56; "wrapper exact", eval-helpers)

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:7-9`, `docs/decisions/log.md:77`, `test/skills/eval-helpers.bash:413`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers WRAPPER_RE's handling of the heredoc terminator compared with bash's. Does not establish any false pass. None is reachable, because any expression that contains a bare `EXPREOF` line can only parse as a Name or string, and the reference evaluator rejects both. So the practical effect is confined to the classifier's labelling and to the mechanism the docstring describes.

```python
# test/skills/arithmetic-eval/mode1-equiv.py:33-40
WRAPPER_RE = re.compile(
    r"\A\( ulimit -t 5 -v 1000000 2>/dev/null; timeout 5 python3 -c '\n"
    r"(?P<program>[^']*)\n"
    r"' \) <<'EXPREOF'\n"
    r"(?P<expr>.*?)\n"
    r"EXPREOF(?P<tail>(\n[ \t]*(#[^\n]*)?)*)\Z",
    re.S,
)
```
bash ends the heredoc at the *first* line equal to `EXPREOF` and runs every later line as shell. The lazy `(?P<expr>.*?)` backtracks past that first terminator when the lines after it are not comments, and settles on a *later* `EXPREOF` whose tail is clean. Executed (mode1 probe P1, 2026-09-25T23:15:17Z): body `2`, then `EXPREOF`, `touch pwned`, `EXPREOF`. The script reports `call 1: Mode 1, expression '2\nEXPREOF\ntouch pwned'`, so the wrapper check *passed* on a command that bash would run with `touch pwned` after the heredoc. `bash -n` on the same text returns 0 (valid shell). The call then fails only at step 3 (`-> None`). Step 1 therefore does not guarantee "only blank or # comment lines after the closing EXPREOF" in bash's sense. Precise version: "…after the last EXPREOF line; a body holding its own EXPREOF line is left to the evaluator, which rejects it". Alternatively, forbid `^EXPREOF$` inside `expr`. The mode1-equiv.bats test "shell after the closing EXPREOF fails" (test 7) covers only the single-terminator case.

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:33-40`, `test/skills/arithmetic-eval/mode1-equiv.py:120-133`, `test/skills/mode1-equiv.bats:88-97`, `docs/reviews/execution-logs/cfc-5ddf804-mode1-probes.txt`

---

## Claim 23: "requires the embedded Python program to equal SKILL.md's by ast.dump, which ignores comments and formatting … but not any code change"

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the narrow reading "any change to the program's AST is rejected; comments and whitespace are ignored". Does not establish rejection of AST-invisible lexical changes, such as `100_000` for `100000` or redundant parentheses, which ast.dump treats as equal (executed). All such changes are semantically inert.

```python
# test/skills/arithmetic-eval/mode1-equiv.py:120-126
        try:
            same = ast.dump(ast.parse(w.group("program"))) == ref_dump
        except SyntaxError:
            same = False
        if not same:
            print(f"  call {i}: Mode 1 wrapper, but the program differs from SKILL.md's (by AST)")
            continue
```
(excerpt ends :126; enclosing main() continues to :133, read). Executed: mode1-equiv.bats test 3 (comments stripped → pass) and test 4 (`MAX_BITS = 100001` → "program differs") both pass. The ast-dump probe shows `100000` and `100_000` equal, and `100000` and `100001` unequal.

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:116-126`, `docs/reviews/execution-logs/cfc-5ddf804-mode1-equiv-bats.txt`, `docs/reviews/execution-logs/cfc-5ddf804-astdump-probe.txt`

---

## Claim 24: "takes the heredoc body (the expression) and runs it through the evaluator extracted from SKILL.md, never the model's copy. It passes if any call's result matches one of the expected values."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:13-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the evaluator source (`ref_program`) and the any-call pass. Does not establish the evaluator's safety properties (tested by arithmetic-eval-gate.bats, not re-run here).

```python
# test/skills/arithmetic-eval/mode1-equiv.py:127-133
        expr = w.group("expr")
        value = evaluate(ref_program, expr)
        print(f"  call {i}: Mode 1, expression {expr!r} -> {value}")
        if value is not None and any(math.isclose(value, v, rel_tol=t, abs_tol=0.0) for v, t in expected):
            return 0
    print(f"No Mode 1 call computed any of: {spec}")
    return 1
```
`ref_program` comes from `reference(skill_path)` (`:43-52`), never from the transcript. Executed: mode1-equiv.bats test 9 (`__import__("os").getcwd()` → `-> None`) and test 2 pass.

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:43-52`, `test/skills/arithmetic-eval/mode1-equiv.py:98-133`, `docs/reviews/execution-logs/cfc-5ddf804-mode1-equiv-bats.txt`

---

## Claim 25: "It also re-checks the generator's tripwire: every Bash tool_use id must be in the result event's permission_denials, or the run fails whatever it computed."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:17-18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the check on all assistant-event Bash calls against the union of every result event's denials, run before any evaluation. Does not establish that sub-agent denials appear in the top-level result. If they do not, the check fails closed.

```python
# test/skills/arithmetic-eval/mode1-equiv.py:107-112
    denied = {d.get("tool_use_id") for ev in evs if ev.get("type") == "result"
              for d in ev.get("permission_denials") or []}
    undenied = [cid for cid, _ in calls if cid not in denied]
    if undenied:
        print(f"Tripwire: {len(undenied)} Bash call(s) not in permission_denials (may have executed): {undenied}")
        return 1
```
Executed: mode1-equiv.bats test 10 passes.

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:65-75`, `test/skills/arithmetic-eval/mode1-equiv.py:107-112`, `docs/reviews/execution-logs/cfc-5ddf804-mode1-equiv-bats.txt`

---

## Claim 26: "<expected> is one or more values separated by '|', each optionally followed by '~<relative tolerance>' (default 1e-6) … Exit 0 on a match, 1 otherwise; diagnostics on stdout."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:20-25`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the spec parsing, the tolerance semantics (`math.isclose(rel_tol=t, abs_tol=0)`), the exit statuses and the output streams. Does not establish behavior on a non-finite expected value.

Spec, tolerance and the 0/1 exit statuses hold (`parse_expected` at `:77-82`; `isclose` at `:130`). "Diagnostics on stdout" holds only for per-call diagnostics. The fatal paths go to stderr: `sys.exit("mode1-equiv: no ```bash block under '## Mode 1' …")` (`:47`), the usage `sys.exit(__doc__)` (`:100`), and an unparseable spec, which raises an uncaught `ValueError` traceback. All of these still exit 1. Executed (mode1 probes P3, P4): a bad spec `abc` gives rc=1 with an 11-line stderr traceback, and a SKILL.md without Mode 1 gives rc=1 with 0 stdout bytes and the message on stderr. Precise version: "per-call diagnostics on stdout; setup errors on stderr".

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:43-52`, `test/skills/arithmetic-eval/mode1-equiv.py:77-82`, `test/skills/arithmetic-eval/mode1-equiv.py:98-104`, `docs/reviews/execution-logs/cfc-5ddf804-mode1-probes.txt`

---

## Claim 27: WRAPPER_RE matches SKILL.md's actual Mode 1 block (implicit in "SKILL.md's Mode 1 wrapper exactly")

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:33-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex against the current `skills/arithmetic-eval/SKILL.md` Mode 1 block: wrapper line, single-quote-free program, `' ) <<'EXPREOF'`, the one-line body, and the trailing `# → …` comment as tail. Does not establish robustness to future SKILL.md edits. `reference()` exits non-zero if the block stops matching, so such an edit fails loudly.

The block (`SKILL.md:41-86`) begins `( ulimit -t 5 -v 1000000 2>/dev/null; timeout 5 python3 -c '`, uses only double quotes inside the program, and ends `' ) <<'EXPREOF'` / `3600 / 0.003 * 1000` / `EXPREOF` / `# → [arithmetic-eval] 3600 / 0.003 * 1000 -> 1200000000.0`. `reference()` applies the same regex to it and exits if it fails (`:48-51`). Executed: mode1-equiv.bats tests 1 and 2 pass, and every later test builds its command from this block.

**Evidence:** `skills/arithmetic-eval/SKILL.md:41-86`, `test/skills/arithmetic-eval/mode1-equiv.py:43-52`, `docs/reviews/execution-logs/cfc-5ddf804-mode1-equiv-bats.txt`

---

## Claim 28: "Inline mode: the draft is in the prompt, so no file tools are needed, and the run's directory is empty. The prompt names neither the evaluator nor Bash … It does not say Bash will be denied"

**Location:** `test/skills/arithmetic-eval/runner.bash:8-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the user prompt text and the inline temp dir. Does not cover the system prompt, which is SKILL.md itself (`--system-prompt-file`) and does name the evaluator. The claim is about the prompt only.

```bash
# test/skills/arithmetic-eval/runner.bash:18-20
fixture_prompt() {
  printf '%s' "Check the figures in the draft below: for each number that is derived from other numbers, say whether it is right. This is a non-interactive run; no human will answer questions. The draft:"
}
```
In inline mode, `generate_one` fills nothing into `temp_dir`: the `git init` and copy happen only in the non-inline `else` branch (`generate-reports.bash:196-219`).

**Evidence:** `test/skills/arithmetic-eval/runner.bash:1-20`, `test/skills/generate-reports.bash:170-219`

---

## Claim 29: "Assert the session never called <tool>, at any depth."

**Location:** `test/skills/eval-helpers.bash:398`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every `tool_use` block in every `assistant` event of the transcript, sub-agent events included when they are streamed. Does not establish that stream-json carries sub-agent assistant events (CLI behavior, not observable here). The arithmetic-eval runner grants no Agent tool, so the question does not arise for this fixture set.

```bash
# test/skills/eval-helpers.bash:401-409
assert_no_tool_called() {
  local tool="$1" t n
  t="$(eval_transcript_path)" || { echo "$t"; return 1; }
  n=$(transcript_tool_inputs "$t" "$tool" | grep -c . || true)
  if [ "$n" -gt 0 ]; then
    echo "Expected no $tool calls, found $n:"
    transcript_tool_inputs "$t" "$tool" | head -3 | cut -c1-200
    return 1
  fi
```
(excerpt ends :409; enclosing function closes at :410, read). `transcript_tool_inputs` selects `.type == "assistant"` with no `parent_tool_use_id` filter (`:362-364`). Executed: mode1-equiv.bats test 11 passes.

**Evidence:** `test/skills/eval-helpers.bash:357-365`, `test/skills/eval-helpers.bash:398-410`, `docs/reviews/execution-logs/cfc-5ddf804-mode1-equiv-bats.txt`

---

## Claim 30a: "'deny-record' lets FIXTURE_TOOLS name Bash, and pins --permission-mode dontAsk --permission-prompts none … Needs FIXTURE_TRANSCRIPT=1."

**Location:** `test/skills/generate-reports.bash:31-34`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the argv pin and the contract requirements. Does not establish that the CLI denies (Claim 30b).

```bash
# test/skills/generate-reports.bash:180-183
  claude_args+=(--tools "$TOOLS_ARG")
  if [ "$FIXTURE_BASH" = "deny-record" ]; then
    claude_args+=(--permission-mode dontAsk --permission-prompts none)
  fi
```
Executed: generate-reports.bats tests 28 and 29 pass.

**Evidence:** `test/skills/generate-reports.bash:180-183`, `test/skills/runner-contract.bash:99-115`, `docs/reviews/execution-logs/cfc-5ddf804-generate-reports-bats.txt`

---

## Claim 30b: "… so every Bash call is denied and only recorded"

**Location:** `test/skills/generate-reports.bash:32-33`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers nothing beyond the argv (Claim 30a). The CLI's handling of `dontAsk` together with `--permission-prompts none` is not established here. Blocker: execution requires running `claude`, which this pass may not do.

The only evidence is the DD doc's Probe A record (Claim 14). The tripwire (Claim 31) makes a violation fail closed, provided the CLI still reports the call in the stream.

**Evidence:** `test/skills/generate-reports.bash:31-36`, `docs/working/dd-arith-eval-bash-grant.md:161`

---

## Claim 31: "A run in which any Bash call is missing from the result's permission_denials, i.e. may have executed, is recorded as failed."

**Location:** `test/skills/generate-reports.bash:34-36`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the jq tripwire: sub-agent Bash calls (any assistant event), several result events (their denials are unioned), a missing or unreadable transcript (`unreadable` → failure), and non-JSON lines (skipped). Also covers the `.failed` write. Does not establish whether the CLI lists sub-agent denials in the top-level result. If it does not, the run is voided (fail closed). The tripwire runs only when no earlier failure is set, and in that case the run is already recorded as failed.

```bash
# test/skills/generate-reports.bash:251-263
    if [ -z "$failure" ] && [ "$FIXTURE_BASH" = "deny-record" ]; then
      local undenied
      undenied=$(jq -rRn '[inputs | fromjson?] as $ev
        | ([$ev[] | select(.type == "result") | .permission_denials[]?.tool_use_id]) as $denied
        | [$ev[] | select(.type == "assistant") | .message.content[]?
           | select(.type == "tool_use" and .name == "Bash") | .id]
        | map(select(. as $id | $denied | index($id) | not)) | length' \
        "$transcript_path" 2>/dev/null) || undenied="unreadable"
      [ "$undenied" = 0 ] || failure="Bash tripwire: $undenied Bash call(s) not in permission_denials (may have executed)"
    fi
  fi

  if [ -n "$failure" ]; then
```
(excerpt ends :263; enclosing generate_one() continues to :271, read: `:264` is `printf '%s\n' "$failure" > "$failed_path"`). Executed (tripwire probes, 2026-09-25T23:15:39Z): an undenied sub-agent call gives 1, denials split over two result events give 0, a missing file and a chmod-000 file each give `unreadable`, and a non-JSON line or string content gives 0. generate-reports.bats test 32 passes.

**Evidence:** `test/skills/generate-reports.bash:229-271`, `docs/reviews/execution-logs/cfc-5ddf804-tripwire-probes.txt`, `docs/reviews/execution-logs/cfc-5ddf804-generate-reports-bats.txt`

---

## Claim 32: "Under deny-record, the operator's CLAUDE_FLAGS must not loosen what the pinned permission flags deny (a later --permission-mode would win)."

**Location:** `test/skills/generate-reports.bash:114-115`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the argv ordering, which puts CLAUDE_FLAGS after the pinned flags, so "later" is correct about position. It also covers which spellings the refusal catches. Does not establish the CLI's last-wins semantics (blocker: `claude` may not be run). Not established either: that the refusal covers every permission-loosening spelling. It accepts `--permission-prompt-tool …` and a tab-prefixed `\t--permission-mode bypassPermissions`, which bash's unquoted `${CLAUDE_FLAGS:-}` still splits into a separate `--permission-mode` word (executed). Per override-log C4, operator-controlled CLAUDE_FLAGS are Won't-Fix, so this is recorded for synthesis, not as an author defect.

Ordering: `claude "${claude_args[@]}" $model_flag ${CLAUDE_FLAGS:-}` (`generate-reports.bash:224-227`), where `claude_args` already holds the pinned flags (`:181-183`). Executed (CLAUDE_FLAGS case probe under bash 5.2.15, 2026-09-25T23:16:41Z, exit 0): `--permission-mode=bypassPermissions` is refused, while the tab-prefixed form and `--permission-prompt-tool mcp__x__y` are accepted.

**Evidence:** `test/skills/generate-reports.bash:114-124`, `test/skills/generate-reports.bash:224-227`, `docs/reviews/execution-logs/cfc-5ddf804-claude-flags-case.txt`

---

## Claim 33: test name "SKILL.md's own block, verbatim, computes its value"

**Location:** `test/skills/mode1-equiv.bats:48`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the test body against its name. Does not assess test adequacy.

```bash
# test/skills/mode1-equiv.bats:48-53
@test "SKILL.md's own block, verbatim, computes its value" {
  transcript "$(with_expr '4750 / 0.0025 * 1000')"
  run assert_mode1_equiv '1900000000'
  echo "$output"
  [ "$status" -eq 0 ]
}
```
The block's heredoc body is replaced (`with_expr`), and `setup()` strips the `# →` comment line (`:22-23`). So the wrapper and program are verbatim, but the expression and value are not SKILL.md's (`3600 / 0.003 * 1000` → 1.2e9). Precise version: "SKILL.md's wrapper and program, verbatim, compute a fixture's value".

**Evidence:** `test/skills/mode1-equiv.bats:15-33`, `test/skills/mode1-equiv.bats:48-53`

---

## Claim 34: "Any other Bash grant, and any Bash(<pattern>) spelling, is still refused."

**Location:** `test/skills/runner-contract.bash:24-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the check order in `check_runner_settings`. The tool-name regex rejects `Bash(…)` before the allowlist loop, `Bash` is admitted only when `FIXTURE_BASH` is `deny-record`, and FIXTURE_BASH's own validation (value, TRANSCRIPT=1, Bash named) runs after the TRANSCRIPT normalisation. Does not establish anything about operator env: `reset_runner_settings` clears FIXTURE_BASH before the runner is sourced (`:34`).

```bash
# test/skills/runner-contract.bash:58-61
    if ! [[ "$FIXTURE_TOOLS" =~ ^[A-Za-z]+(,[A-Za-z]+)*$ ]]; then
      echo "Error: $label: FIXTURE_TOOLS may only name ${RUNNER_ALLOWED_TOOLS[*]}, joined by commas with no spaces (e.g. Read,Grep,Glob), or be 'none'; got '$FIXTURE_TOOLS'" >&2
      return 1
    fi
```
(excerpt ends :61; enclosing check_runner_settings() continues to :117, read). `:70-72` then admit `Bash` only when `"$FIXTURE_BASH" = "deny-record"`. Executed: generate-reports.bats tests 29 (`FIXTURE_BASH=allow` with Bash → "FIXTURE_TOOLS may only name") and 30 (`Bash(python3:*)`) pass.

**Evidence:** `test/skills/runner-contract.bash:30-36`, `test/skills/runner-contract.bash:41-117`, `docs/reviews/execution-logs/cfc-5ddf804-generate-reports-bats.txt`

---

## Claim 35: "bats test/install-host.bats: 90/90 pass."

**Location:** commit `47a3818` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the suite at HEAD 5ddf804. install-host.bats is byte-identical in test count to 47a3818 (90 `@test` there, too). Does not establish results on another host or git version.

paraphrased — no quote available because the evidence is the captured run log. Executed: `bats test/install-host.bats` (cwd `/workspace`, started 2026-09-25T23:14:56Z) printed `1..90` and 90 `ok` lines, exit 0. `git show 47a3818:test/install-host.bats | grep -c '^@test'` gives 90.

**Evidence:** `docs/reviews/execution-logs/cfc-5ddf804-install-host-full.txt`

---

## Claim 36: "Tests: mode1-equiv.bats 12/12; generate-reports.bats 32/32 (5 new)"

**Location:** commit `e6043df` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both counts and the "5 new". Does not cover the same message's health-check claim, which rests on absent local reports (Claim 14).

paraphrased — no quote available because the evidence is run logs and counts. Executed (2026-09-25T23:14:25Z and 23:14:29Z, both exit 0): `1..12`, all ok, and `1..32`, all ok. `git show main:test/generate-reports.bats | grep -c '^@test'` gives 27, so 5 are new (tests 28–32).

**Evidence:** `docs/reviews/execution-logs/cfc-5ddf804-mode1-equiv-bats.txt`, `docs/reviews/execution-logs/cfc-5ddf804-generate-reports-bats.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 15** (`docs/working/dd-arith-eval-bash-grant.md:169`): the helper has no "non-empty with no `EXPREOF` line" check. That rejection comes only from the reference evaluator. Reword, or add the check.
- **Claim 22** (`test/skills/arithmetic-eval/mode1-equiv.py:7-9`; same wording in log #56 and `eval-helpers.bash:413`): WRAPPER_RE's lazy `expr` backtracks past bash's first `EXPREOF` terminator. A command bash would run with trailing shell (`touch pwned`) is classified as the Mode 1 wrapper and rejected only by the evaluator. Either forbid a bare `EXPREOF` line inside `expr` or reword step 1. No false pass is reachable.

### Stale
- **Claim 13** (`docs/working/dd-arith-eval-bash-grant.md:153-154`): the plan bullets name a `no_bash_executed` check, repo-mode fixtures, 4 planted-wrong drafts and an EXPREOF rejection. What was built is a generator/helper tripwire, inline mode, and 3 wrong + 1 correct fixtures. The status line says "Built".

### Mostly Accurate
- **Claim 6** (`devcontainer-config/install.sh:1138-1139`): a same-uid process with an unreadable `cwd` link (non-dumpable) is silently skipped, not "each other process of this uid". Executed.
- **Claim 10b** (`docs/decisions/037-bare-host-copy-install.md:82-84`): the "misses" list omits in-checkout processes whose `/proc/<pid>/cwd` cannot be read.
- **Claim 12** (`docs/decisions/log.md:77`, `docs/working/questions-archive.md:1320`): "routed 5/5 through Mode 1". The 5th fixture is the must-not-route negative. Should read "4/4 routed; the negative made no Bash call".
- **Claim 19** (`test/skills/arithmetic-eval-eval.bats:56-66`): the test names name one value, but each passes on any listed alternate (e.g. 3.408 for "29.2%").
- **Claim 20** (`test/skills/arithmetic-eval/expected-verdicts.bash:8-10`): "values any of them would give" overstates. The backward check 4.8M/4 = 1.2M (tc-ae4) is not listed.
- **Claim 26** (`test/skills/arithmetic-eval/mode1-equiv.py:20-25`): setup and usage errors go to stderr (including an uncaught traceback on a bad spec), not stdout. Exit codes hold.
- **Claim 33** (`test/skills/mode1-equiv.bats:48`): "verbatim, computes its value". The expression and value are replaced, and only the wrapper and program are verbatim.

### Unverifiable
- **Claim 14** (`docs/working/dd-arith-eval-bash-grant.md:161-167` et al.): the probe and first-run results, and the health-check failure count. Needs a `claude` run, or the gitignored transcripts and reports.
- **Claim 30b** (`test/skills/generate-reports.bash:32-33`): that `dontAsk` together with `--permission-prompts none` denies every Bash call. Needs a `claude` run.
- **Claim 32** (`test/skills/generate-reports.bash:114-115`): the CLI's last-wins flag semantics. Needs a `claude` run. The refusal list is non-exhaustive (tab-prefixed flags, `--permission-prompt-tool`), which falls under C4 Won't-Fix.

No Incorrect verdict is a fabrication in the hallucination-log sense. Claim 22 is a regex-vs-bash semantics mismatch. Claim 15 is a design sentence written before the helper existed (f8fdc3d, before e6043df) and never implemented, so it is not a claimed symbol or API that does not exist. `docs/reviews/hallucination-patterns.md` is unchanged.

## Goal-Alignment Note
- Success criterion (restated verbatim): "A markdown report saved to docs/reviews/code-fact-check-report.md, structured per the code-fact-check skill, with header lines `**Commit:** 5ddf804` and `**Replication:** k=1 (loop pass, decision 031)`."
- Answered: all nine focus areas from the brief. (1) Detector coverage and exemptions, `$$` in subshells, fail-closed, four moments, and residuals: Claims 1, 2, 4-10b. (2) /proc and GNU: Claims 2 and 3. (3) runner-contract: Claims 14, 17 and 34. (4) generator header, tripwire and CLAUDE_FLAGS: Claims 30a-32. (5) mode1-equiv docstring and WRAPPER_RE: Claims 15 and 22-27. (6) eval-helpers: Claims 22 and 29. (7) prompt, CLAIM_ACCURACY and VERDICT_RE: Claims 18-21 and 28. (8) test names: Claims 16 and 33. (9) commits, log #56 and DD probe section: Claims 11-15, 35 and 36. Suites run: install-host 90/90, generate-reports 32/32, mode1-equiv 12/12.
- Out of scope: anything needing `claude` (CLI permission semantics, probe and run re-observation). Code-quality judgments on the findings. questions.md removals (pure moves to the archive) and the `answers-9-25-26.txt` human-authored file (no code claims). Pre-existing, unchanged 037 residual bullets.
- Escalate: Claim 22 plus Claim 6/10b are the two substantive mechanism findings. Claim 22 has no reachable false pass, but the docstring, log #56 and eval-helpers all describe a guarantee the regex does not give. Claim 6 is a real fail-open per process in the Q-062 detector (a non-dumpable same-uid process in the checkout is invisible), which the security critic may want to weigh against 037's trust model.
- Decisions I made: I did not update the hallucination-pattern log (reason above). The non-dumpable finding is verdicted as Mostly accurate on the comments, not Incorrect, because the stated mechanism (read `/proc/<pid>/cwd`) is what the code does, and only the "each process" coverage is overstated. The CLAUDE_FLAGS non-exhaustiveness is recorded under Scope only, per settled C4.
