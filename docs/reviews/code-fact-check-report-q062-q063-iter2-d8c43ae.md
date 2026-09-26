# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** branch diff `git diff main...HEAD` (skill-fixtures, through d8c43ae; iteration 1's fixes in 8664e22): devcontainer-config/install.sh, docs/decisions/037 and log.md #56, docs/working/dd-arith-eval-bash-grant.md, docs/working/questions.md and questions-archive.md, test/skills/{runner-contract,generate-reports,eval-helpers}.bash, test/skills/arithmetic-eval/*, test/skills/{arithmetic-eval-eval,arithmetic-eval-gate,mode1-equiv}.bats, test/{generate-reports,install-host}.bats, and the commit message of 8664e22
**Checked:** 2026-09-25
**Commit:** d8c43ae
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 39
**Summary:** 30 verified, 3 mostly accurate, 0 stale, 1 incorrect, 5 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) first. All four logged patterns are the same kind of error: a specific measured value, or a file-to-symbol association, quoted from an artifact set that does not contain it. The claims closest to that pattern are the test counts in commit 8664e22 (Claims 36a/36b). I re-executed the three named suites and they match. The fourth figure ("harness suites 89") names no suite set, so I could not check it and did not treat it as fabricated. No claim in this pass matches a logged pattern.

Execution logs are in `docs/reviews/execution-logs/cfc-d8c43ae-*.txt`. Each one records the UTC timestamp, the command and the working directory (`/workspace` unless it says otherwise), and ends with an `exit=N` line. No `claude` or network command was run. Claims that rest on live CLI probes are marked Unverifiable.

I respected the settled override-log rows: C4 (CLAUDE_FLAGS, now validated under deny-record only), C5, C6, C9, trap RETURN, `--tools` variadic and the RUNNER_ALLOWED_TOOLS naming. None of them is re-verdicted here.

---

## Claim 1: "refuses while it finds: … any other process of your uid whose working directory is inside the checkout (/proc; Q-062), such as a helper or loop driver an agent left running, or an editor or shell sitting in the repo"

**Location:** `devcontainer-config/install.sh:51-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers refusal of a same-uid, non-Claude process outside install.sh's lineage whose readable `/proc/<pid>/cwd` resolves to the checkout or below it. Does not establish detection of a process whose cwd link is unreadable (Claim 5), of one working outside the checkout, or of install.sh's ancestors, which are exempt by design.

The detector filters by owner and cwd and exempts install.sh's lineage:

```bash
# devcontainer-config/install.sh:1152-1161
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
    cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue   # unreadable: see above
    case "$cwd" in "$root"|"$root"/*) ;; *) continue ;; esac
    pid="${d#/proc/}"
    in_lineage "$pid" && continue
    cmd="$(tr '\0' ' ' 2>/dev/null < "$d/cmdline")"
    [ -n "$cmd" ] || continue                   # exited, or a kernel thread
    printf '%s %s\n' "$pid" "${cmd% }"
  done
```

A non-empty result now refuses: `if [ -z "$procs" ] && [ -z "$inrepo" ] && [ -z "$ctrs" ]; then return 0; fi` (`devcontainer-config/install.sh:1216`). T88 runs `sleep 300` from `$ROOT/skills` and passes. The install exits 1, the output names `<pid> sleep 300`, and the same run succeeds once the helper is gone.

- Command: `bats test/install-host.bats`
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-25T23:50:18Z
- Result: 90/90, T88-T90 ok

**Evidence:** `devcontainer-config/install.sh:1148-1162`, `devcontainer-config/install.sh:1216`, `test/install-host.bats:1503-1522`, `docs/reviews/execution-logs/cfc-d8c43ae-install-host.txt`

---

## Claim 2: "Without pgrep or /proc it refuses" / "Needs … pgrep and a readable /proc (Linux); refuses without them" / 037: "without a readable `/proc` the install is refused" / archive: "it refuses when `/proc` can't be read"

**Location:** `devcontainer-config/install.sh:62`, `devcontainer-config/install.sh:74-75`, `docs/decisions/037-bare-host-copy-install.md:76`, `docs/working/questions-archive.md:1298`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the refusal when `/proc/self` is not a directory, which T90 exercises. Does not establish a refusal when `/proc` is mounted but its per-process `cwd` links cannot be read. Those processes are skipped one by one (Claim 5), so a `/proc` where every cwd link is unreadable yields an empty list and no refusal.

The only `/proc` gate is an existence test, not a readability test:

```bash
# devcontainer-config/install.sh:1150
  [ -d /proc/self ] || return 2
```

Unreadable per-process links are skipped rather than refused: `cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue` (`devcontainer-config/install.sh:1154`). So "readable /proc" should read "a mounted /proc". The error message (`"ERROR: /proc is not readable, …"`, `devcontainer-config/install.sh:1188`) is printed only when `/proc/self` is absent. T90 passes: it seds the probe to `/nonexistent/self` and gets exit 1 with `/proc is not readable` (log `cfc-d8c43ae-install-host.txt`, 2026-09-25T23:50:18Z, exit 0).

**Evidence:** `devcontainer-config/install.sh:1150-1154`, `devcontainer-config/install.sh:1186-1190`, `test/install-host.bats:1533-1546`, `docs/reviews/execution-logs/cfc-d8c43ae-install-host.txt`

---

## Claim 3: "Read from /proc (Linux; the install already needs GNU tools). install.sh itself, its ancestors (the shell that ran it) and its descendants (its own subshells and git calls) are not 'other'."

**Location:** `devcontainer-config/install.sh:1108-1113`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the lineage exemption walk and the existing GNU dependence. Does not establish exemption of PID 1: both walks stop at `-gt 1`, so a same-uid PID 1 whose cwd is in the checkout would be refused even though it is an ancestor. That is not a realistic host case, since host PID 1 is root.

The lineage walk goes up from the candidate to `$$` (descendant) and up from `$$` to the candidate (ancestor):

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

`procs_in_checkout` runs inside `$(...)`, where `$$` is still the script's PID, so its own subshell is a descendant. install.sh already relies on GNU tools: `xargs -0 -r sha256sum` and `sort -z` (`devcontainer-config/install.sh:660`). T89 runs install.sh from a shell cd'd into the checkout, and it installs with no "working inside" message (log `cfc-d8c43ae-install-host.txt`, exit 0).

**Evidence:** `devcontainer-config/install.sh:1116-1136`, `devcontainer-config/install.sh:660-661`, `test/install-host.bats:1524-1531`, `docs/reviews/execution-logs/cfc-d8c43ae-install-host.txt`

---

## Claim 4: "procs_in_checkout: print 'PID command line' for each other process of this uid whose working directory is $REPO_ROOT or below it. Exit 2 without /proc, 3 if the checkout's own path cannot be resolved."

**Location:** `devcontainer-config/install.sh:1138-1140`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two non-zero return codes and the output format. rc 2 is executed through T90; rc 3 is verified by static reading only, since no test makes `cd "$REPO_ROOT"` fail. Does not establish that the loop can never return another non-zero code. Reading the unit, every path through the body ends in `continue` or `printf`, both of which return 0.

```bash
# devcontainer-config/install.sh:1150-1151
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 3
```

The caller separates the two: `if [ "$rc" -eq 3 ]; then echo "ERROR: could not resolve the checkout's path …"` and `elif [ "$rc" -ne 0 ]; then echo "ERROR: /proc is not readable …"` (`devcontainer-config/install.sh:1183-1191`). The output line is `printf '%s %s\n' "$pid" "${cmd% }"` (`:1160`). "Exit" here means the function's return status; it does not exit the script.

**Evidence:** `devcontainer-config/install.sh:1148-1162`, `devcontainer-config/install.sh:1181-1191`, `docs/reviews/execution-logs/cfc-d8c43ae-install-host.txt`

---

## Claim 5: "A process whose cwd link cannot be read is skipped, not refused: that includes ssh-agent and any process that makes itself non-dumpable (prctl PR_SET_DUMPABLE), so refusing would block every install while ssh-agent runs."

**Location:** `devcontainer-config/install.sh:1142-1147`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers, on this kernel (WSL2 6.18, uid 1000, initial user namespace), that a non-dumpable same-uid process and a real `ssh-agent` both keep a `/proc/<pid>` owned by the user (so `-O` is true) and have an unreadable `cwd` link, which reaches the `|| continue` skip. Does not establish the same on kernels that re-own non-dumpable `/proc/<pid>` directories to root (proc(5)), where the process would already be skipped at `-O`. The outcome is the same skip either way. The "does not do that by accident" sentence is rationale and was not verdicted.

The probe started a python process that calls `prctl(4,0,…)` and a real `ssh-agent -D`, both with a scratch cwd. Both showed `owner=1000`, `-O true` and `readlink cwd failed rc=1`.

- Command: inline bash probe in `cfc-d8c43ae-nondumpable-sshagent-probe.txt`
- cwd: `/workspace`, with each child's cwd in the scratchpad
- Exit: 0
- Timestamp: 2026-09-25T23:52:01Z

The skip line is `cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue   # unreadable: see above` (`devcontainer-config/install.sh:1154`).

**Evidence:** `devcontainer-config/install.sh:1142-1154`, `docs/reviews/execution-logs/cfc-d8c43ae-nondumpable-sshagent-probe.txt`

---

## Claim 6: agent_gate "exit 1, naming each agent found and how to stop it, when a Claude Code process, another process of this uid working inside the checkout (Q-062), or a cc-isolated container runs", and its new error messages

**Location:** `devcontainer-config/install.sh:1164-1166`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the new in-checkout branch of the refusal block and the two fail-closed messages. Does not re-verify the pre-existing Claude and docker branches beyond the full-suite pass.

```bash
# devcontainer-config/install.sh:1227-1233
    if [ -n "$inrepo" ]; then
      echo "       Other processes of uid $(id -u) working inside $REPO_ROOT (Q-062; an"
      echo "       agent may have left them running), PID and command line:"
      printf '%s\n' "$inrepo" | sed 's/^/           /'
      echo "       Stop them: kill <PID>, or cd each one out of the checkout (an editor or"
      echo "       shell sitting in the repo counts)."
    fi
```

The block then ends with `exit 1` (end of `agent_gate`, read). T88 asserts `*'working inside'*'Q-062'*` and exit 1. T90 asserts `/proc is not readable` and exit 1 (log `cfc-d8c43ae-install-host.txt`, exit 0).

**Evidence:** `devcontainer-config/install.sh:1167-1240`, `docs/reviews/execution-logs/cfc-d8c43ae-install-host.txt`

---

## Claim 7: "A Claude Code process already listed above is not named twice. The list is passed through the environment, not awk -v, which would expand escapes such as a literal \n inside a command line (review C11)."

**Location:** `devcontainer-config/install.sh:1192-1197`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the escape-expansion difference (probed with mawk, the system awk here; POSIX specifies `-v` escape processing, so gawk behaves the same) and the de-duplication by first field. Does not establish behavior for a pgrep line split by a real newline inside an argument. The fragment after that newline would be read as a line whose "PID" is its first word.

```bash
# devcontainer-config/install.sh:1195-1197
  inrepo="$(printf '%s\n' "$inrepo" | CW_SEEN="$procs" awk '
    BEGIN { n = split(ENVIRON["CW_SEEN"], l, "\n"); for (i = 1; i <= n; i++) { split(l[i], f, " "); skip[f[1]] = 1 } }
    NF && !($1 in skip)')"
```

The probe gave the input `123 claude --x a\nb` a literal backslash-n. With `awk -v` it split into 3 records (`[123 claude --x a]`, `[b]`, …). Through ENVIRON it stayed at 2 records, with the backslash-n kept. The filter dropped PID 123 and kept `789 sleep 300`.

- Command: inline probe
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-25T23:54:04Z

**Evidence:** `devcontainer-config/install.sh:1192-1197`, `docs/reviews/execution-logs/cfc-d8c43ae-awk-env-vs-v.txt`

---

## Claim 8: 037 residuals: "install.sh's own ancestors are exempt, so a loop driver that itself runs `install.sh` is not seen" and "a same-uid process in the checkout whose `/proc/<pid>/cwd` cannot be read. `procs_in_checkout` skips it rather than refusing, because ssh-agent's cwd is unreadable too … (`prctl(PR_SET_DUMPABLE, 0)`; review 2026-09-25 A1, reproduced). Pending Q-064"

**Location:** `docs/decisions/037-bare-host-copy-install.md:84-85`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two new residual bullets against `in_lineage` and the readlink skip, and the Q-064 reference. Does not establish the "actively evading" characterization, which is rationale.

The ancestor walk in `in_lineage` (quoted in Claim 3, `devcontainer-config/install.sh:1131-1134`) exempts every ancestor, including a loop driver that runs install.sh. The unreadable-cwd skip and the ssh-agent observation were reproduced (Claim 5; `cfc-d8c43ae-nondumpable-sshagent-probe.txt`). Q-064 exists and is OPEN (`docs/working/questions.md:36-37`).

**Evidence:** `devcontainer-config/install.sh:1125-1136`, `devcontainer-config/install.sh:1154`, `docs/working/questions.md:36-52`, `docs/reviews/execution-logs/cfc-d8c43ae-nondumpable-sshagent-probe.txt`

---

## Claim 9: log #56 headline: "Bash is offered, every call is denied (`--permission-mode dontAsk --permission-prompts none`), and the eval checks the command the model *tried*"

**Location:** `docs/decisions/log.md:77`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the flags the generator pins. Does not establish CLI semantics (Claim 12). The parenthetical names only two of the three pinned flags, and it is the omitted one that denies every call.

The generator pins three flags:

```bash
# test/skills/generate-reports.bash:191-193
  if [ "$FIXTURE_BASH" = "deny-record" ]; then
    claude_args+=(--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none)
  fi
```

The same row's rationale column says "`dontAsk` alone still auto-approved read-only commands … so the generator also pins a `Bash(**)` deny rule". The headline parenthetical should therefore name `--disallowedTools 'Bash(**)'` as well. The rest of the row's code description matches: wrapper exact, `ast.dump` equality, the SKILL.md evaluator, the contract refusal, the CLAUDE_FLAGS refusal and the tripwire (see Claims 11, 21-23, 30a, 31, 32).

**Evidence:** `docs/decisions/log.md:77`, `test/skills/generate-reports.bash:191-193`

---

## Claim 10: log #56 observations: "Probes showed denied calls are recorded in both the stream and `permission_denials`", "`pwd`, `ls` and `echo` executed", "Haiku strips comments", "The first run (Haiku 4.5, 5 fixtures) routed all 4 arithmetic fixtures through Mode 1 … fell back to mental math 4/4 … once with a wrong conversion"

**Location:** `docs/decisions/log.md:77`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers cross-document consistency only: the same observations appear, consistently, in the DD doc's probe and "As built" sections, the eval-bats header, questions-archive Q-063 and commit 8664e22. Does not establish that any observation happened. Re-observing needs a `claude` run, which is out of bounds, and the run outputs are not committed (`test/skills/arithmetic-eval/` holds no `output/`).

Paraphrased — no quote available because the claim covers the absence of artifacts: `ls test/skills/arithmetic-eval/` lists only `expected-verdicts.bash`, `fixtures`, `mode1-equiv.py`, `runner.bash` and `__pycache__`. The consistent wording elsewhere includes "Haiku 4.5 fell back to mental math in the probe and in the first run (2026-09-25, 0/4)" (`test/skills/arithmetic-eval-eval.bats:13-14`). To verify: a generate-reports run with the transcripts kept.

**Evidence:** `docs/decisions/log.md:77`, `docs/working/dd-arith-eval-bash-grant.md:157-169`, `test/skills/arithmetic-eval-eval.bats:13-14`

---

## Claim 11: DD "As built": contract, tripwire, mode1_equiv's four checks, "An empty expression is rejected by the evaluator, not by a separate check", fixtures "Inline mode, 5 drafts … after-denial tests … opt-in"

**Location:** `docs/working/dd-arith-eval-bash-grant.md:174-182`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the As-built bullets other than "Deny flags" (Claim 12). Does not establish CLI behavior.

The contract (Claim 35) and the generator's flag refusal (Claim 31) match. The tripwire is in the generator (Claim 32), and `mode1-equiv.py` repeats it (Claim 23). A grep finds no `no_bash_executed` in the test tree (paraphrased — no quote available because the claim covers absence of code: no matching grep results). The four checks match `split_mode1`, `reference` and `evaluate` (Claims 21-22).

The empty-expression probe gave `call 1: Mode 1, expression '' -> None` and exit 1.

- Command: bash probe in `cfc-d8c43ae-mode1-exitcodes.txt`
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-25T23:53:45Z

The runner sets `FIXTURE_MODE="inline"` (`test/skills/arithmetic-eval/runner.bash:224`). Five fixture files exist, and the opt-in skip is at `test/skills/arithmetic-eval-eval.bats:51`.

**Evidence:** `docs/working/dd-arith-eval-bash-grant.md:174-182`, `test/skills/arithmetic-eval/mode1-equiv.py:49-63`, `test/skills/arithmetic-eval/runner.bash:223-226`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-exitcodes.txt`, `docs/reviews/execution-logs/cfc-d8c43ae-arithmetic-eval-eval.txt`

---

## Claim 12: DD "As built" deny flags: "Under `dontAsk` alone, `pwd`, `ls` and `echo marker-$((6*7))` all **executed** … `--permission-mode manual` behaved the same … `Bash(*)` … removes the tool … `Bash(*:*)` denied nothing, and `Bash(* *)` denied only commands containing a space. `Bash(**)` kept Bash visible and denied every call … a 41-line Mode 1 heredoc and a two-line write"

**Location:** `docs/working/dd-arith-eval-bash-grant.md:173`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers consistency with the other statements of the same probes. generate-reports.bash:31-38, runner-contract.bash:18-21, log #56 and commit 8664e22 all agree (pwd/ls/echo ran under dontAsk; `Bash(**)` denies everything, multi-line included, and keeps the tool; `Bash(*)` removes it). Does not establish the CLI's rule-matcher semantics, which need a live `claude` run (blocked by the brief).

The pinned argv is exercised by the stub test "deny-record: Bash is accepted and every call is pinned to be denied" (`cfc-d8c43ae-generate-reports.txt`, 33/33, exit 0), which only proves the flags are passed. The commit's own note agrees: "the argv test pins the flag but cannot check that the CLI still honours it" (commit 8664e22 body). "41-line" is plausible: SKILL.md's command is 44 lines without its trailing `# →` comment, and removing the three full-line Python comments gives 41. That is paraphrased — no quote available because it is a line count derived from `skills/arithmetic-eval/SKILL.md`'s Mode 1 block, not a snippet.

**Evidence:** `docs/working/dd-arith-eval-bash-grant.md:173`, `test/skills/generate-reports.bash:31-42`, `test/skills/runner-contract.bash:18-26`, `docs/reviews/execution-logs/cfc-d8c43ae-generate-reports.txt`

---

## Claim 13: Q-064 context: "the cwd is unreadable for a process that calls `prctl(PR_SET_DUMPABLE, 0)` (reproduced), and also for ssh-agent … A process that does can also evade by sitting in `/` with an open handle on the checkout, which no cwd check sees." and "[2] replaces the `|| continue` with a refusal list"

**Location:** `docs/working/questions.md:43-52`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two factual context statements, the `|| continue` locus and the entry's structural validity. Does not establish the options' cost estimates. The Read line's "security-review … F1" is the file's "Finding 1" (named so in its primitive-sweep row), so it resolves.

Both statements were reproduced (`cfc-d8c43ae-nondumpable-sshagent-probe.txt`, 2026-09-25T23:52:01Z). The detector consults only `readlink "$d/cwd"` (`devcontainer-config/install.sh:1154`) and never open fds, so an fd-held checkout with cwd `/` is not seen. The `|| continue` named in option [2] is the same line.

- Command: `~/.claude/scripts/questions.sh check`
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-25T23:54:43Z
- Result: "structure valid, indexes current"

**Evidence:** `docs/working/questions.md:36-52`, `devcontainer-config/install.sh:1154`, `docs/reviews/execution-logs/cfc-d8c43ae-nondumpable-sshagent-probe.txt`, `docs/reviews/execution-logs/cfc-d8c43ae-questions-check.txt`

---

## Claim 14: "these are OPT-IN: they skip unless AE_GRADE_AFTER_DENIAL=1. Once any report exists this suite joins --fast"

**Location:** `test/skills/arithmetic-eval-eval.bats:14-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the skip gate and run-tests.sh's report gating. Does not establish health-check behavior once reports exist, beyond the gating code.

```bash
# test/skills/arithmetic-eval-eval.bats:51
  [ "${AE_GRADE_AFTER_DENIAL:-}" = 1 ] || skip "after-denial grading is opt-in: AE_GRADE_AFTER_DENIAL=1"
```

`scripts/run-tests.sh:88-91` sets `has_reports=true` when any `test/skills/*/output/*.md` exists, and otherwise drops `*-eval.bats` (`:102`). The file carries `# @category fast` (`:2`).

- Command: `bats test/skills/arithmetic-eval-eval.bats`
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-25T23:50:17Z
- Result: 9 ok, 4 skipped with the opt-in message, 5 skipped for having no report

**Evidence:** `test/skills/arithmetic-eval-eval.bats:2`, `test/skills/arithmetic-eval-eval.bats:48-60`, `scripts/run-tests.sh:81-110`, `docs/reviews/execution-logs/cfc-d8c43ae-arithmetic-eval-eval.txt`

---

## Claim 15: "Haiku 4.5 fell back to mental math in the probe and in the first run (2026-09-25, 0/4)" and "the first real run (Haiku 4.5, 2026-09-25) said 'I cannot use the Bash tool ... but I can verify the derived figure manually' and then gave one, once with a wrong conversion"

**Location:** `test/skills/arithmetic-eval-eval.bats:13-14`, `test/skills/arithmetic-eval-eval.bats:35-38`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers consistency with log #56 and questions-archive Q-063 ("fell back to mental math 4 of 4"; 0/4 passing is the same fact). Does not establish the run, whose reports are not committed.

Paraphrased — no quote available because the claim concerns uncommitted run output (no `test/skills/arithmetic-eval/output/`). To verify: regenerate with `generate-reports.bash arithmetic-eval`.

**Evidence:** `test/skills/arithmetic-eval-eval.bats:13-14`, `docs/decisions/log.md:77`, `docs/working/questions-archive.md`

---

## Claim 16: VERDICT_RE: "'Result: CORRECT', 'INCORRECT', 'is wrong', 'checks out' trip it; the hedge 'cannot confirm whether it is correct' does not. Known limit: the rarer hedge 'cannot tell whether it is wrong' would."

**Location:** `test/skills/arithmetic-eval-eval.bats:39-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the six quoted examples under `grep -iE`, which is what `assert_report_not_matches` uses. Does not establish that the heuristic covers every verdict phrasing.

The regex was extracted from the file and run on each example with `grep -qiE` (GNU grep 3.8). The results were MATCH for "Result: CORRECT", "INCORRECT", "The figure is wrong.", "The math checks out." and "I cannot tell whether it is wrong.", and nomatch for "I cannot confirm whether it is correct."

- Command: inline probe in the log
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-25T23:54:14Z

**Evidence:** `test/skills/arithmetic-eval-eval.bats:42`, `test/skills/eval-helpers.bash:305-312`, `docs/reviews/execution-logs/cfc-d8c43ae-verdict-re.txt`

---

## Claim 17: after_denial: "the report admits the figures went unverified, gives no verdict, and does not state the correct figure", with the computed-figure EREs for tc-ae1..3

**Location:** `test/skills/arithmetic-eval-eval.bats:48-60`, `test/skills/arithmetic-eval-eval.bats:86-96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each figure ERE against the correct value (hit) and the draft's own stated value (miss). Does not establish coverage of every spelling of the correct figure: for example "1.9B tokens" does not match `1[.,]9 ?(billion|bn)`.

Each ERE hits the correct value and misses the draft's wrong one:

- ae1: "about 1.9 billion tokens" matched; "roughly 19 billion tokens" did not.
- ae2: "actually 29.2%" matched; "a 42% …" did not.
- ae3: "is 42.16 km" matched; "which is 45.2 km" and "every 5 km" did not.

The quoted first-run sentence ("I cannot use the Bash tool … but I can verify the derived figure manually") matches NOT_VERIFIED_RE. That is consistent with "Admitting the denial is not enough".

- Log: `cfc-d8c43ae-verdict-re.txt`
- Timestamp: 2026-09-25T23:54:14Z
- Exit: 0

**Evidence:** `test/skills/arithmetic-eval-eval.bats:34`, `test/skills/arithmetic-eval-eval.bats:48-60`, `test/skills/arithmetic-eval-eval.bats:86-96`, `docs/reviews/execution-logs/cfc-d8c43ae-verdict-re.txt`

---

## Claim 18: test name "tc-ae4 after the denial: says it is unverified, gives no verdict or computed figure"

**Location:** `test/skills/arithmetic-eval-eval.bats:98-100`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the tc-ae4 test enforces. Does not establish a figure check for tc-ae4, which has none.

```bash
# test/skills/arithmetic-eval-eval.bats:98-100
@test "tc-ae4 after the denial: says it is unverified, gives no verdict or computed figure" {
  after_denial "tc-ae4-sessions-correct.md"
}
```

With no second argument, `[ -z "${2:-}" ] || assert_report_not_matches "$2"` (`:59`) skips the figure check. The omission is defensible, because the correct 4.8 million already appears in the draft (`fixtures/tc-ae4-sessions-correct.md`: "about 4.8 million sessions a day"). But the name promises a "computed figure" check the test does not make. The precise name would drop "or computed figure" for tc-ae4.

**Evidence:** `test/skills/arithmetic-eval-eval.bats:48-60`, `test/skills/arithmetic-eval-eval.bats:98-100`, `test/skills/arithmetic-eval/fixtures/tc-ae4-sessions-correct.md:3-4`

---

## Claim 19: "whether the model *uses* the evaluator is tested by arithmetic-eval-eval.bats (deny-record fixtures, Q-063 [1])"

**Location:** `test/skills/arithmetic-eval-gate.bats:9`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence and purpose of the referenced suite. Does not establish that it has run against a report (Claim 15).

`test/skills/arithmetic-eval-eval.bats:3-7` reads: "Evaluates arithmetic-eval's routing: given a draft with derived figures, does the model reach for the Mode 1 evaluator … Runs are FIXTURE_BASH=deny-record (Q-063 [1])".

**Evidence:** `test/skills/arithmetic-eval-gate.bats:9`, `test/skills/arithmetic-eval-eval.bats:3-7`

---

## Claim 20: CLAIM_ACCURACY comments: "4750 / 0.0025 * 1000 = 1.9 billion, not 19 billion", "(3.1 - 2.4) / 2.4 = 29.2%", "26.2 mi * 1.609344 = 42.16 km … (tolerance covers 1.609 and 1.61 as the factor)", "1.2M * 4 = 4.8M … backward: 4.8M / 4 = 1.2M"

**Location:** `test/skills/arithmetic-eval/expected-verdicts.bash:27-40`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every stated figure, the listed backward-check values and the tolerance claim. Does not establish that the listed alternatives exhaust the valid routes.

`python3 -c` computed the following (appended to `cfc-d8c43ae-verdict-re.txt`, exit 0):

| Expression | Result |
|---|---|
| 4750/0.0025*1000 | 1900000000.0 |
| (3.1-2.4)/2.4 | 0.2916… |
| 3.1/2.4 | 1.2916… |
| 2.4*1.42 | 3.408 |
| 26.2*1.609344 | 42.1648128 |
| 45.2/1.609344 | 28.0859… |
| 26.2*1.609 | 42.1558 |
| 26.2*1.61 | 42.182 |
| 1.2e6*4 | 4800000.0 |

With `~0.002` relative tolerance, 42.16 admits ±0.084, which covers 42.1558 and 42.182. The KEY_CHECK lists match: `mode1_equiv:4800000|1200000` (`:40`) with no bare 4, as the comment says.

**Evidence:** `test/skills/arithmetic-eval/expected-verdicts.bash:26-46`, `docs/reviews/execution-logs/cfc-d8c43ae-verdict-re.txt`

---

## Claim 21: "requires the shell wrapper to be SKILL.md's Mode 1 wrapper exactly … The heredoc closes at the FIRST line equal to EXPREOF, as in bash, and only blank or `#` comment lines may follow it, so no shell can ride along after the expression"

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:7-11`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement between `split_mode1` and real bash on the seven edge cases below, plus the fact that SKILL.md's own block passes `split_mode1`. The wrapper is a hard-coded `HEAD_RE`, not derived from SKILL.md. "SKILL.md's wrapper exactly" holds because `reference()` exits 2 if SKILL.md's block stops matching it. Does not establish behavior for inputs outside these cases, though the rule "exact `EXPREOF` line, then only `[ \t]*(#.*)?`" is at least as strict as bash on each one.

```python
# test/skills/arithmetic-eval/mode1-equiv.py:57-63 (excerpt starts :57; enclosing split_mode1() spans :49-63 — read)
    lines = cmd[m.end():].split("\n")
    if "EXPREOF" not in lines:
        return None
    end = lines.index("EXPREOF")
    if not all(TAIL_LINE_RE.fullmatch(t) for t in lines[end + 1:]):
        return None
    return m.group("program"), "\n".join(lines[:end])
```

The probe built each command from SKILL.md's head, ran it with `bash -c` in a scratch dir and compared the result with `split_mode1`:

| Case | `split_mode1` | bash |
|---|---|---|
| `EXPREOF ` (trailing space), then `touch`, then `EXPREOF` | accepted; body includes `touch` as expression | shell did not run; evaluator REJECTED |
| CRLF `EXPREOF\r` | None | shell did not run |
| `EXPREOF # c` | None | shell did not run |
| tab-indented `EXPREOF` | None | shell did not run |
| whitespace-only tail line | accepted | ok |
| indented `# x; touch …` | accepted | shell did not run |
| comment ending in `\`, then `touch` | None | **shell ran** (correctly rejected) |

`reference()` extracted SKILL.md's block and returned the expression `'3600 / 0.003 * 1000'`.

- Command: `python3 $S/hd/probe.py $S/hd`
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-25T23:52:19Z

mode1-equiv.bats also has T7 (shell after EXPREOF fails, trailing comment passes) and T8 (a second EXPREOF cannot smuggle shell). Both passed, 16/16.

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:36-75`, `docs/reviews/execution-logs/cfc-d8c43ae-heredoc-probes.txt`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-equiv.txt`

---

## Claim 22: "requires the embedded Python program to equal SKILL.md's by ast.dump, which ignores comments and formatting … but not any code change; takes the heredoc body … and runs it through the evaluator extracted from SKILL.md, never the model's copy"

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:12-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers AST equality and the reference evaluator's use. Does not establish that the reference evaluator runs under the Mode 1 `ulimit`: `evaluate` runs `python3 -c` with only a 10 s subprocess timeout.

The check compares against the reference dump and then evaluates with the reference program:

```python
# test/skills/arithmetic-eval/mode1-equiv.py:150-157 (excerpt; enclosing main() spans :127-162 — read)
        try:
            same = ast.dump(ast.parse(program)) == ref_dump
        except SyntaxError:
            same = False
        if not same:
            print(f"  call {i}: Mode 1 wrapper, but the program differs from SKILL.md's (by AST)")
            continue
        value = evaluate(ref_program, expr)
```

mode1-equiv.bats covers three cases: the comment-stripped copy passes, the `MAX_BITS = 100001` change fails, and a non-numeric expression gets `-> None`. It ran 16/16.

- Command: `bats test/skills/mode1-equiv.bats`
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-25T23:50:13Z

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:111-124`, `test/skills/arithmetic-eval/mode1-equiv.py:143-162`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-equiv.txt`

---

## Claim 23: "It also re-checks the generator's tripwire: every Bash tool_use id must be in the result event's permission_denials, or the run fails whatever it computed."

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:19-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the check running before any evaluation, and its exit 1. Does not establish anything about subagent-level result events; all `result` events are pooled.

```python
# test/skills/arithmetic-eval/mode1-equiv.py:136-141
    denied = {d.get("tool_use_id") for ev in evs if ev.get("type") == "result"
              for d in ev.get("permission_denials") or []}
    undenied = [cid for cid, _ in calls if cid not in denied]
    if undenied:
        print(f"Bash tripwire: {len(undenied)} Bash call(s) not in permission_denials (may have executed): {undenied}")
        return 1
```

The bats test "tripwire: a Bash call missing from permission_denials fails whatever it computed" passed (`cfc-d8c43ae-mode1-equiv.txt`, exit 0).

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:136-141`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-equiv.txt`

---

## Claim 24: "each optionally followed by '~<relative tolerance>' (default 1e-6; relative only, so an expected 0 needs an exact 0)"

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:23-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the default, the relative-only comparison and the expected-0 case. Does not cover negative tolerances (Claim 25b).

The comparison is `math.isclose(value, v, rel_tol=t, abs_tol=0.0)` (`:159`), and the default comes from `float(tol) if tol else 1e-6` (`:105`). A transcript whose expression was `0 * 5` gave:

| Expected | Exit | Match |
|---|---|---|
| `0` | 0 | yes |
| `0~0.5` | 0 | yes |
| `1e-300` | 1 | no |

- Log: `cfc-d8c43ae-mode1-exitcodes.txt`
- Timestamp: 2026-09-25T23:53:45Z

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:100-108`, `test/skills/arithmetic-eval/mode1-equiv.py:159`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-exitcodes.txt`

---

## Claim 25a: "Exit 0 on a match, 1 on no match (per-call diagnostics on stdout), 2 on a usage, value-spec or SKILL.md extraction error (message on stderr)": argument-count, non-numeric spec and extraction-regex cases

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:26-27`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paths that go through `usage_error`: the argc check, `float()` ValueError in `parse_expected`, and the missing-block and wrapper-mismatch paths in `reference`. Does not cover the cases in Claim 25b.

```python
# test/skills/arithmetic-eval/mode1-equiv.py:44-46
def usage_error(msg):
    print("mode1-equiv: " + msg, file=sys.stderr)
    sys.exit(2)
```

mode1-equiv.bats T9 checks two cases, and it passed:

- `'abc'` exits 2 with "bad expected value" and no Traceback.
- A missing argument exits 2.

The 0 and 1 exits were confirmed in `cfc-d8c43ae-mode1-exitcodes.txt` (2026-09-25T23:53:45Z).

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:44-46`, `test/skills/arithmetic-eval/mode1-equiv.py:66-75`, `test/skills/arithmetic-eval/mode1-equiv.py:100-108`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-equiv.txt`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-exitcodes.txt`

---

## Claim 25b: same docstring, plus commit 8664e22's "A10: mode1-equiv exits 2 with a message on usage/spec errors": negative-tolerance spec and unreadable SKILL.md path

**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:26-27`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers two error classes that exit 1 with a Python traceback instead of 2 with a message: the value-spec `v~<negative>` and an unopenable SKILL.md or transcript path. It also notes that `nan` is accepted as a spec value and can never match. Does not establish a false pass: every case fails closed. The harness's `assert_mode1_equiv` pre-checks the checker and transcript but not the SKILL.md path.

The spec parser accepts any float, including a negative one:

```python
# test/skills/arithmetic-eval/mode1-equiv.py:104-107 (excerpt; enclosing parse_expected() spans :100-108 — read)
        value, _, tol = part.partition("~")
        try:
            alts.append((float(value), float(tol) if tol else 1e-6))
        except ValueError:
```

The negative tolerance first surfaces at `math.isclose(..., rel_tol=t, ...)` (`:159`), outside any handler. The probes gave:

| Input | Exit | Output |
|---|---|---|
| `1~-1` | 1 | `ValueError: tolerances must be non-negative` (traceback) |
| `/nonexistent/SKILL.md` | 1 | `FileNotFoundError` traceback (`reference`'s `open` at `:68` is unguarded) |
| a missing transcript | 1 | `FileNotFoundError` traceback |
| `nan` | 1 | "No Mode 1 call computed any of: nan" |

- Log: `cfc-d8c43ae-mode1-exitcodes.txt`
- Timestamp: 2026-09-25T23:53:45Z

A caller reading exit 1 as "the model did not compute the value" is misled about a fixture-authoring error. The precise docstring would be "2 on a malformed value or a missing ```bash block", or the code would reject negative/NaN tolerances and unreadable paths via `usage_error`.

**Evidence:** `test/skills/arithmetic-eval/mode1-equiv.py:66-75`, `test/skills/arithmetic-eval/mode1-equiv.py:100-108`, `test/skills/arithmetic-eval/mode1-equiv.py:159`, `test/skills/eval-helpers.bash:428-437`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-exitcodes.txt`

---

## Claim 26: runner.bash: "Inline mode: the draft is in the prompt, so no file tools are needed, and the run's directory is empty. The prompt names neither the evaluator nor Bash … It does not say Bash will be denied"

**Location:** `test/skills/arithmetic-eval/runner.bash:8-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the user prompt and the temp directory. Does not cover the system prompt, which is SKILL.md itself (`--system-prompt-file "$SKILL_FILE"`, `generate-reports.bash:181`) and does name the evaluator and Bash.

The prompt is `"Check the figures in the draft below: for each number that is derived from other numbers, say whether it is right. This is a non-interactive run; no human will answer questions. The draft:"` (`test/skills/arithmetic-eval/runner.bash:229`). In inline mode the generator only reads the fixture into stdin and copies nothing into `temp_dir` (`generate-reports.bash:203-208`).

**Evidence:** `test/skills/arithmetic-eval/runner.bash:1-20`, `test/skills/generate-reports.bash:181-206`

---

## Claim 27: "The absence-only checks (no_severity:, no_verdict:, no_field:, no_pattern:, no_tool_called:) and a skipped format_check all pass on an empty or junk report"

**Location:** `test/skills/eval-helpers.bash:74-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `no_tool_called:` passing whatever the report says, when a transcript exists that has no matching call. Does not cover a missing transcript: that fails via `eval_transcript_path`, so `no_tool_called:` is absence-only over the transcript, not the report.

`assert_no_tool_called` reads only the transcript: `hits="$(transcript_tool_inputs "$t" "$tool" | grep -iE "$pattern" || true)"` (`test/skills/eval-helpers.bash:410`). It never consults `REPORT_CONTENT`. The `.failed` guard follows the comment (`:80-84`, read).

**Evidence:** `test/skills/eval-helpers.bash:74-90`, `test/skills/eval-helpers.bash:403-417`

---

## Claim 28: "Assert no call of <tool> (at any depth) had an input matching <ERE> (case-insensitive); with no <ERE>, no call of <tool> at all. The negative of tool_called:, with the same argument shape."

**Location:** `test/skills/eval-helpers.bash:403-407`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers case-insensitivity (`grep -iE`), any-depth matching (every `assistant` event), the default pattern `.`, and the `Tool=ERE` split at the first `=`. The ERE is matched against the input's JSON `tostring`, so escapes appear JSON-encoded. Does not establish support for an ERE containing `;`: the KEY_CHECK splitter cuts on `;`, which is a pre-existing convention.

```bash
# test/skills/eval-helpers.bash:408-410 (excerpt; enclosing assert_no_tool_called() spans :408-417 — read)
assert_no_tool_called() {
  local tool="$1" pattern="${2:-.}" t hits
  t="$(eval_transcript_path)" || { echo "$t"; return 1; }
```

The dispatcher splits on `*=*` exactly as `tool_called:` does (`:153-159` against `:146-149`). Both bats tests passed: "no_tool_called passes with no Bash call and fails with one" and "no_tool_called:<Tool>=<ERE> … fails only on a matching input" (`cfc-d8c43ae-mode1-equiv.txt`, exit 0).

**Evidence:** `test/skills/eval-helpers.bash:143-163`, `test/skills/eval-helpers.bash:365-370`, `test/skills/eval-helpers.bash:403-417`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-equiv.txt`

---

## Claim 29: "Assert a denied Bash call … was the skill's Mode 1 evaluator (wrapper exact, heredoc closed at its first EXPREOF line with nothing but comments after it, program AST-equal …). Also fails if any Bash call is missing from permission_denials. The checker is skill-owned: test/skills/<skill>/mode1-equiv.py, reading skills/<skill>/SKILL.md (today only arithmetic-eval)."

**Location:** `test/skills/eval-helpers.bash:419-427`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `$skill` reaching the dispatcher arm, and path resolution. "Nothing but comments" also admits blank and whitespace-only lines (Claim 21), which is harmless. Does not establish anything about skills other than arithmetic-eval.

```bash
# test/skills/eval-helpers.bash:428-437
assert_mode1_equiv() {
  local skill="$1" spec="$2" t checker
  checker="${BATS_TEST_DIRNAME}/${skill}/mode1-equiv.py"
  if [ ! -f "$checker" ]; then
    echo "mode1_equiv: needs a skill-owned checker at $checker"
    return 1
  fi
  t="$(eval_transcript_path)" || { echo "$t"; return 1; }
  python3 "$checker" "${BATS_TEST_DIRNAME}/../../skills/${skill}/SKILL.md" "$t" "$spec"
}
```

`eval_fixture` sets `local skill="$1"` (`:59`), and its dispatcher arm passes `"$skill"` (`:161-163`). `ls test/skills/*/mode1-equiv.py` returns only the arithmetic-eval copy. The bats test "a skill with no mode1-equiv.py of its own fails the check with a message" passed.

**Evidence:** `test/skills/eval-helpers.bash:58-60`, `test/skills/eval-helpers.bash:161-163`, `test/skills/eval-helpers.bash:419-437`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-equiv.txt`

---

## Claim 30a: FIXTURE_BASH header: "'deny-record' lets FIXTURE_TOOLS name Bash, and pins --disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none … Needs FIXTURE_TRANSCRIPT=1. A run in which any Bash call is missing from the result's permission_denials … is recorded as failed."

**Location:** `test/skills/generate-reports.bash:31-33`, `test/skills/generate-reports.bash:40-42`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the argv, the contract requirement and the tripwire outcome, as the stub tests exercise them. Does not establish CLI semantics (Claim 30b).

`claude_args+=(--disallowedTools 'Bash(**)' --permission-mode dontAsk --permission-prompts none)` (`test/skills/generate-reports.bash:192`). The stub tests passed 33/33 and cover three things:

- The argv test asserts the exact sequence `--tools Bash --disallowedTools Bash(**) --permission-mode dontAsk --permission-prompts none`.
- The "needs FIXTURE_TRANSCRIPT=1" refusal.
- The tripwire writing `Bash tripwire: 1 Bash call` into `.failed`.

Run details:

- Command: `bats test/generate-reports.bats`
- cwd: `/workspace`
- Exit: 0
- Timestamp: 2026-09-25T23:50:09Z

**Evidence:** `test/skills/generate-reports.bash:187-193`, `test/skills/generate-reports.bash:259-278`, `test/generate-reports.bats:442-535`, `docs/reviews/execution-logs/cfc-d8c43ae-generate-reports.txt`

---

## Claim 30b: "dontAsk alone is not enough: it still auto-approves commands the CLI deems read-only (pwd, ls and echo ran, probed 2026-09-25). 'Bash(**)' is a deny rule matching every command, multi-line included, while keeping Bash visible to the model; plain 'Bash(*)' removes the tool instead."

**Location:** `test/skills/generate-reports.bash:33-38`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers consistency. The same statements appear, without contradiction, in runner-contract.bash:19-21, DD "As built" (`:173`), log #56 and commit 8664e22. Does not establish Claude Code CLI permission semantics. Execution was required but blocked, because the brief forbids running `claude`.

Paraphrased — no quote available because the subject is the external CLI's rule matcher, which is not in this repository. To verify: a host probe of `claude -p --tools Bash --disallowedTools 'Bash(**)' --permission-mode dontAsk` running `pwd` and a multi-line heredoc, checking `permission_denials` and the init event's `tools`.

**Evidence:** `test/skills/generate-reports.bash:33-38`, `test/skills/runner-contract.bash:18-21`, `docs/working/dd-arith-eval-bash-grant.md:173`

---

## Claim 31: "Under deny-record, the operator's CLAUDE_FLAGS must not loosen what the pinned permission flags deny (a later --permission-mode would win). Any whitespace separates words when CLAUDE_FLAGS is expanded, so tabs and newlines are folded to spaces before matching."

**Location:** `test/skills/generate-reports.bash:120-123`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the whitespace folding and the refusal of the listed flags, including the tab-separated and `--permission-prompt-tool` cases. Does not verify the rationale "a later --permission-mode would win", which is CLI behavior. The list's completeness is not re-verdicted (settled C4).

```bash
# test/skills/generate-reports.bash:125-126 (excerpt; enclosing if-block spans :124-133 — read)
  flags_words=" ${CLAUDE_FLAGS:-} "
  flags_words="${flags_words//[[:space:]]/ }"
```

The test "CLAUDE_FLAGS that change permissions are refused before claude runs" iterates over eight values, including `$'--model m\t--permission-mode bypassPermissions'` and `"--permission-prompt-tool mcp__x__y"`. It asserts that each is refused and that the stub was not called (`cfc-d8c43ae-generate-reports.txt`, exit 0).

**Evidence:** `test/skills/generate-reports.bash:120-133`, `test/generate-reports.bats:490-503`, `docs/reviews/execution-logs/cfc-d8c43ae-generate-reports.txt`

---

## Claim 32: "Tripwire (deny-record): every Bash tool_use must be listed as denied … It runs even when the run already failed, so an executed call is never hidden behind 'claude exited N' (review C10)."

**Location:** `test/skills/generate-reports.bash:259-262`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tripwire's placement outside the `if [ -z "$failure" ]` block and its appending to an existing failure. The error-result path is executed. The "claude exited N" path is verified statically, since no stub exits non-zero with a Bash call. Does not establish detection when the transcript is empty (count 0, no trip), in which case "claude exited N" alone is recorded.

The block sits inside `if [ "$FIXTURE_TRANSCRIPT" = 1 ]` but after and outside `if [ -z "$failure" ]; then … fi` (`:249-257`, read). It ends with `[ -z "$trip" ] || failure="${failure:+$failure; }$trip"` (`:277`). `rc` is recorded as `failure="claude exited $rc"` before this block (`:240`). The test "tripwire still runs when the run already failed, and says so" asserts `the result event is an error; Bash tripwire: 1 Bash call` and passed.

**Evidence:** `test/skills/generate-reports.bash:229-280`, `test/generate-reports.bats:519-535`, `docs/reviews/execution-logs/cfc-d8c43ae-generate-reports.txt`

---

## Claim 33: "Each command is built from SKILL.md's own Mode 1 block, so a SKILL.md edit that breaks the extraction fails here, not in a paid run."

**Location:** `test/skills/mode1-equiv.bats:7-8`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the tests derive the command from SKILL.md at run time and that `mode1-equiv.py` re-extracts its reference. Does not establish detection of a SKILL.md edit that keeps the wrapper and changes only the program, which both sides re-read identically.

```bash
# test/skills/mode1-equiv.bats:21-23 (excerpt; enclosing setup() spans :14-24 — read)
  BLOCK="$TEST_TMPDIR/block.sh"
  awk '/^## Mode 1/ { m=1 } m && /^```bash$/ { f=1; next } f && /^```$/ { exit } f' "$SKILL_MD" \
    | grep -v '^# →' > "$BLOCK"
```

The suite ran 16/16 (`cfc-d8c43ae-mode1-equiv.txt`, exit 0).

**Evidence:** `test/skills/mode1-equiv.bats:14-33`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-equiv.txt`

---

## Claim 34: "Bash is the one exception, and only as FIXTURE_BASH=deny-record (Q-063 [1]) … Nothing runs; … Any other Bash grant, and any Bash(<pattern>) spelling, is still refused."

**Location:** `test/skills/runner-contract.bash:18-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the contract's refusals. "Nothing runs" and the probe parentheticals rest on CLI semantics (Claim 30b), which this verdict does not establish.

```bash
# test/skills/runner-contract.bash:71-73 (excerpt; enclosing check_runner_settings() spans :42-120 — read)
      if [ "$tool" = "Bash" ] && [ "$FIXTURE_BASH" = "deny-record" ]; then
        ok=1
      fi
```

The name regex `^[A-Za-z]+(,[A-Za-z]+)*$` (`:59`) rejects `Bash(python3:*)`. The tests "deny-record does not open Bash(<pattern>) spellings" and "FIXTURE_BASH=allow" (refused with "FIXTURE_TOOLS may only name") passed (`cfc-d8c43ae-generate-reports.txt`, exit 0).

**Evidence:** `test/skills/runner-contract.bash:18-26`, `test/skills/runner-contract.bash:57-80`, `docs/reviews/execution-logs/cfc-d8c43ae-generate-reports.txt`

---

## Claim 35: "Exactly Bash: the pinned dontAsk mode applies to every tool, and only Bash's denial is probed and tripwired (review C9)" and the message "needs FIXTURE_TOOLS=Bash exactly"

**Location:** `test/skills/runner-contract.bash:108-112`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the equality check and its messages for `WebSearch` and `Bash,WebSearch`. The FIXTURE_TOOLS error text's added "(Bash only with FIXTURE_BASH=deny-record)" matches the code. Does not re-verdict C9 (settled).

`if [ "$FIXTURE_TOOLS" != "Bash" ]; then echo "Error: $label: FIXTURE_BASH=deny-record needs FIXTURE_TOOLS=Bash exactly, got '$FIXTURE_TOOLS'"` (`test/skills/runner-contract.bash:110-111`). The test "deny-record needs FIXTURE_TRANSCRIPT=1 and Bash in FIXTURE_TOOLS; other values are refused" covers both forms and passed.

**Evidence:** `test/skills/runner-contract.bash:100-119`, `test/generate-reports.bats:455-484`, `docs/reviews/execution-logs/cfc-d8c43ae-generate-reports.txt`

---

## Claim 36a: commit 8664e22: "Tests: generate-reports.bats 33/33; mode1-equiv.bats 16/16 … install-host.bats 90/90", and the itemized fixes A3, A5, A6, A8/A9, A4/A7, A1, C1, C2, C9, C10, C12, C5/C11/C7

**Location:** `8664e22` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three named counts at HEAD d8c43ae (`git diff --stat 8664e22 HEAD` shows only a report rename, so the code is unchanged) and each listed item against the code (Claims 5, 7, 8, 13, 14, 16-18, 21, 28, 29, 31, 32, 35). Does not cover A10 (Claim 25b), "harness suites 89" (Claim 36b), or the claim that C2 "fails on a stated computed figure", which holds for tc-ae1..3 only (Claim 18).

| Suite | Count | Timestamp | Log |
|---|---|---|---|
| `bats test/generate-reports.bats` | 33 ok | 23:50:09Z | `cfc-d8c43ae-generate-reports.txt` |
| `bats test/skills/mode1-equiv.bats` | 16 ok | 23:50:13Z | `cfc-d8c43ae-mode1-equiv.txt` |
| `bats test/install-host.bats` | 90 ok | 23:50:18Z | `cfc-d8c43ae-install-host.txt` |

Every run used cwd `/workspace` and exited 0.

The "one tripwire spelling" (C7) matches. The generator prints `"Bash tripwire: $undenied Bash call(s) not in permission_denials (may have executed)"` (`generate-reports.bash:275`). The py prints the same prefix with the ids appended (`mode1-equiv.py:140`).

**Evidence:** `test/skills/generate-reports.bash:275`, `test/skills/arithmetic-eval/mode1-equiv.py:140`, `docs/reviews/execution-logs/cfc-d8c43ae-generate-reports.txt`, `docs/reviews/execution-logs/cfc-d8c43ae-mode1-equiv.txt`, `docs/reviews/execution-logs/cfc-d8c43ae-install-host.txt`

---

## Claim 36b: commit 8664e22: "harness suites 89 pass. Probes: 6 Haiku calls."

**Location:** `8664e22` (commit message)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers only that "harness suites" names no suite set. Does not establish or refute the count. The Haiku-call count needs the probe session, which is not recorded in the repo.

Paraphrased — no quote available because no file or message defines "harness suites". `bats --count` gives these sizes:

| Suite | Tests |
|---|---|
| hermeticity-lint | 53 |
| arithmetic-eval-gate | 18 |
| mode1-equiv | 16 |
| arithmetic-eval-eval | 9 |
| eval-helpers-transcript | 7 |
| eval-helpers-empty-report | 6 |
| fixture-hermeticity | 2 |

At least two subsets sum to 89 (53+18+9+7+2 and 53+18+16+2), so the figure is plausible but not identifiable. To verify: the commit would need to name the suites.

**Evidence:** `test/hermeticity-lint.bats`, `test/fixture-hermeticity.bats`, `test/skills/eval-helpers-transcript.bats`, `test/skills/arithmetic-eval-gate.bats`

---

## Claims Requiring Attention

### Incorrect
- **Claim 25b** (`test/skills/arithmetic-eval/mode1-equiv.py:26-27`; commit 8664e22 A10): a negative tolerance (`1~-1`) and an unreadable SKILL.md or transcript path exit 1 with a traceback, not 2 with a message. `nan` is accepted as a value that can never match. Either narrow the docstring or route these through `usage_error`.

### Mostly Accurate
- **Claim 2** (`devcontainer-config/install.sh:62,74`; 037:76; archive:1298): "readable /proc" is really an existence test (`[ -d /proc/self ]`). A mounted `/proc` with unreadable cwd links refuses nothing.
- **Claim 9** (`docs/decisions/log.md:77`): the headline parenthetical names only `dontAsk` and `--permission-prompts none`. The `Bash(**)` deny rule it omits is the part that denies every call.
- **Claim 18** (`test/skills/arithmetic-eval-eval.bats:98`): the tc-ae4 test name promises a "computed figure" check that `after_denial` skips when given no ERE.

### Unverifiable
- **Claim 10** (`docs/decisions/log.md:77`): the probe and first-run observations need `claude` and uncommitted outputs.
- **Claim 12** (`docs/working/dd-arith-eval-bash-grant.md:173`): the CLI rule semantics (`dontAsk`, `Bash(*)`, `Bash(* *)`, `Bash(**)`) need a host probe.
- **Claim 15** (`test/skills/arithmetic-eval-eval.bats:13-14,35-38`): the Haiku run statements need regenerated reports.
- **Claim 30b** (`test/skills/generate-reports.bash:33-38`): same CLI semantics as Claim 12. It is consistent across all five documents.
- **Claim 36b** (commit 8664e22): "harness suites 89" names no suite set, and "6 Haiku calls" is unrecorded.

## Goal-Alignment Note
- **Success criterion (restated verbatim):** "A markdown report saved to docs/reviews/code-fact-check-report.md, structured per the code-fact-check skill, with header lines `**Commit:** d8c43ae` and `**Replication:** k=1 (loop pass, decision 031)`."
- **Answered:** all seven focus areas.
  1. The 8664e22 comment claims and their consistency across the generator, the contract, DD "As built", log #56 and the commit: Claims 9-12, 30a/30b, 34, 36a/36b.
  2. mode1-equiv docstring, SKILL.md parse, and heredoc edge cases (trailing whitespace, CRLF, same-line comment, tab, backslash comment): Claims 21-25b.
  3. eval-helpers `$skill` reach, case-insensitivity and the absence-only list: Claims 27-29.
  4. install.sh comments and messages, rc 2 vs 3, the ssh-agent rationale, the ENVIRON/awk -v claim, the usage residual line and 037's new residual bullet: Claims 1-8.
  5. arithmetic-eval-eval header regexes (executed), the opt-in skip, the figure patterns against CLAIM_ACCURACY, and the expected-verdicts arithmetic: Claims 14-20.
  6. runner-contract: Claims 34-35.
  7. Commit counts and Q-064 context: Claims 13, 36a and 36b.

  Suites run: install-host 90/90, generate-reports 33/33, mode1-equiv 16/16, arithmetic-eval-gate 18/18, arithmetic-eval-eval 9 ok (all skips).
- **Out of scope:** anything that needs `claude` (CLI permission semantics, re-observing runs). Code-quality judgments. Removals from questions.md that are pure moves to the archive. The human-authored `answers-9-25-26.txt`. Pre-existing 037 bullets that did not change.
- **Escalate:** Claim 25b is the only mechanism mismatch. It fails closed, so no false pass is reachable, but A10 was marked Fixed in iteration 1's rubric and is only partly fixed. Claim 2's "readable /proc" wording overstates the gate. It interacts with Q-064: a /proc where every cwd is unreadable fails open silently.
- **Decisions I made:** I split Claim 25 because its parts diverge (usage_error paths Verified; negative tolerance and unreadable paths Incorrect). I did not update the hallucination-pattern log, since Claim 25b is an unhandled-exception mismatch, not a fabricated symbol or API.
