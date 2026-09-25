# Performance Review — branch skill-fixtures (Q-062 [2], Q-063 [1])

Commit: 5ddf804
**Scope:** `git diff main...HEAD`: `devcontainer-config/install.sh` (agent_gate, procs_in_checkout, in_lineage, ppid_of), `test/skills/generate-reports.bash` (deny-record flags, tripwire), `test/skills/runner-contract.bash`, `test/skills/eval-helpers.bash`, `test/skills/arithmetic-eval/{mode1-equiv.py,runner.bash}`, and the new bats suites. Doc-only files were skipped for performance purposes.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (38 claims, commit 5ddf804). I also took my own timings in the review sandbox (below).

**About the measurements:** I timed the functions by extracting `ppid_of`, `in_lineage` and `procs_in_checkout` verbatim from `install.sh` into a scratch script and sourcing it, with synthetic `sleep` processes. The sandbox has 16 CPUs and was loaded (`/proc/loadavg` 37.62 during the runs), so read absolute times as rough. These numbers come from the review sandbox, not from the host where install.sh really runs. So under the Baseline Requirement every finding below is still marked speculative about host impact, and each one quotes the sandbox number as supporting context.

## Data Flow and Hot Paths

- **install.sh `agent_gate`** runs 4 times per install at most: once at startup (`:1287`), once after the devcontainer prompt (`:553`), once before the host target stages (`:780`) and once after the host prompt (`:992`). Each call now runs `procs_in_checkout` once. That function loops over every `/proc/[0-9]*`. For processes owned by this uid it forks `readlink` inside `$(…)`. For processes whose cwd is in the checkout it also runs `in_lineage`, which forks a `$(ppid_of …)` subshell for every step up the tree, in two walks. For those not exempted it forks `tr` once more. Path temperature is **cold**: the script runs by hand, rarely, and every gate call comes right after a human prompt that takes seconds to minutes. N is the number of same-uid processes on the host. A desktop session with a browser, an editor and language servers often has hundreds. That figure is an assumption; check it on the real host.
- **generate-reports.bash tripwire:** one `jq` pass over each deny-record fixture's transcript, once per fixture run, after a `claude -p` call that takes tens of seconds. **Cold** next to the model call.
- **mode1-equiv.py:** once per `mode1_equiv:` check, so once per fixture in the eval suite. It reads the transcript, runs `WRAPPER_RE` on each Bash command and starts one `python3` subprocess for each call that passes the wrapper and AST gates. **Cold**. The input size is a model's Bash commands, a few KB each.
- **runner-contract / eval-helpers additions:** constant-time string checks and one extra transcript scan (`assert_no_tool_called`). Negligible.

## Findings

#### 1. procs_in_checkout forks once per same-uid process, and in_lineage forks once per tree level, twice

**Severity:** Low
**Location:** `devcontainer-config/install.sh:1116-1154` (ppid_of, in_lineage, procs_in_checkout); called from `agent_gate` at `:1171-1172`
**Move:** Count the hidden multiplications
**Classification:** Micro per process, scaled by N (a fork per process, and a fork per tree level for each candidate in the checkout) / Cold path (a human-run installer; each call follows an interactive prompt)
**Confidence:** Medium. The fork counts are read from the code. Host N and host timings are not known.
**Baseline:** no baseline available — flagged as speculative. Sandbox context only, not a host baseline: with the functions extracted and ~1,012 PIDs of this uid, all with cwd outside the checkout, one `procs_in_checkout` call took 3.78 s wall. With 12 PIDs it took 0.08-0.15 s. With 200 orphaned (`setsid`) same-uid processes whose cwd was in the checkout, one call took 2.67 s. That is roughly 3.7 ms per same-uid process and roughly 13 ms per non-exempt process in the checkout, on a loaded machine.

Evidence (the complete unit, `procs_in_checkout`):
```bash
procs_in_checkout() {
  local root d pid cwd cmd
  [ -d /proc/self ] || return 2
  root="$(cd "$REPO_ROOT" && pwd -P)" || return 2
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
}
```
and in `in_lineage` (the whole function is at `:1123-1134`), both walks fork one subshell per level: `p="$(ppid_of "$p")"` … `q="$(ppid_of "$q")"`.

The cost is N forks of `readlink` per gate call, where N is the number of same-uid processes, times 4 gate calls per install. Processes of other uids cost only a `stat`, because `[ -O ]` runs first. For each process in the checkout, `in_lineage` walks from the candidate up to PID 1 and from `$$` up to PID 1, one fork per level. The second walk (the ancestors of `$$`) gives the same answer for every candidate, and it is recomputed every time. The work grows linearly, so this is not an algorithm problem. At an assumed 300-800 same-uid host processes, that is on the order of 1-3 s per gate call and a few seconds per install. On a cold path that follows prompts, users will feel it but it is not harmful. One secondary effect: the scan is not instant, so it adds to the time between one process's `readlink` and the end of the sweep. That window belongs to the security reviewer, since the gate is already documented as a sample, not a lock.

**Recommendation:** No change is required for correctness. If the host timing turns out to be noticeable, compute the ancestor set of `$$` once before the loop instead of once per candidate. Read cwd without a per-process fork, for example one `find /proc -mindepth 2 -maxdepth 2 -name cwd -user "$(id -u)" -printf '%h %l\n' 2>/dev/null` pass (GNU find, which the script already assumes). Or read all `PPid:` values once into an associative array. Before deciding, time `procs_in_checkout` once on the real host to get a baseline.

#### 2. The install-host suite now runs a live, unstubbed /proc scan in every test that reaches agent_gate

**Severity:** Low
**Location:** `test/install-host.bats` (the whole suite: 90 `@test`s; pgrep and docker are stubbed at `:35-49`, but `/proc` is not); `devcontainer-config/install.sh:1171-1172`
**Move:** Price the deployment environment
**Classification:** Micro (a per-test constant set by host N) / Cold (the test suite, run by a developer)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative. The fact-check ran the suite at 90/90 in the sandbox (Claim 35 / execution log `cfc-5ddf804-install-host-full.txt`). I found no wall-time figure there. The sandbox has about 12 same-uid PIDs.

Evidence: the setup stubs `pgrep` and `docker` (`stub_pgrep 'exit 1'`, `:41`), but `procs_in_checkout` reads the live `/proc` (`for d in /proc/[0-9]*; do`). So each test that gets through the startup gate pays the scan cost from finding 1 up to 4 times. In the sandbox that cost is about 0.1 s. On a host with hundreds of same-uid processes it would be seconds per test, which could add minutes across 90 tests. The scan also makes the suite depend on its environment: its speed and output now depend on what else the developer is running. `fake_repo` lives in a temp directory, so a real editor should not normally sit inside it.

**Recommendation:** If the suite is ever run on the host, time it there first. If the cost shows up, add a test-only seam for the `/proc` root, like the `sed` rewrite T90 already applies to its copy of `$INSTALL`. The other tests can then point it at a small fixture tree, and T88/T89 keep using the real `/proc`.

#### 3. mode1-equiv.py runs the reference evaluator on model-derived input without the SKILL.md ulimit; a TimeoutExpired aborts the whole check

**Severity:** Informational
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:85-95` (`evaluate`), called from `main` at `:126`
**Move:** Trace the memory lifecycle
**Classification:** Micro (one subprocess per Mode 1 call) / Cold (eval suite, once per fixture)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

Evidence (the complete unit):
```python
def evaluate(program, expr):
    """Run <expr> through the reference evaluator; return its value or None."""
    r = subprocess.run(["python3", "-c", program], input=expr + "\n",
                       capture_output=True, text=True, timeout=10)
    m = re.search(r"-> (\S+)\s*\Z", r.stdout)
    if r.returncode != 0 or not m:
        return None
    try:
        return float(m.group(1))
    except ValueError:
        return None
```
In SKILL.md the evaluator runs inside `( ulimit -t 5 -v 1000000 …; timeout 5 python3 -c …)`. Here it gets only `timeout=10` and no memory cap. The fact-check scope note on Claim 30 says the same. The evaluator's own `MAX_BITS` guard limits the size of integer results, and the input is one heredoc body from a model's command, a few KB, so realistic memory use is small. There are two effects, both small. (a) The evaluator's CPU and memory limits here differ from the ones the skill documents. (b) A `subprocess.TimeoutExpired` is not caught. A slow expression therefore ends `main()` with a traceback (exit 1) instead of `evaluate` returning `None` and moving on to the next call. That turns one slow call into a failed check even when a later call would have matched.

**Recommendation:** Catch `subprocess.TimeoutExpired` in `evaluate` and return `None`. You could also run the evaluator under the same limits SKILL.md uses, for example with `preexec_fn=lambda: resource.setrlimit(resource.RLIMIT_AS, …)`, so the check and the skill share one resource envelope.

## Endorsements (evidence-gated)

- `WRAPPER_RE` should not backtrack catastrophically. It is anchored (`\A`). The `program` group is `[^']*`, a single character class. Every repetition of the `tail` group has to begin with `\n`, so its nested quantifier cannot split the same text in more than one way. In the sandbox, adversarial commands of about 200 KB (20,000 `EXPREOF` lines separated by `x` or by blank lines, or a 100,000-term expression) matched or failed in 6-13 ms, and an unterminated 400 KB program failed in 7 ms. The time grows roughly linearly. `[unverified — submitted as claim]`
- The generator tripwire's `jq` does all its work in one pass over the transcript (`[inputs | fromjson?]`, then a membership check through `index`). The checking is O(Bash calls × denials), and both numbers are single digits per fixture, so it adds nothing next to the `claude -p` call it follows. `[read: test/skills/generate-reports.bash:249-260]`
- `procs_in_checkout` checks ownership with `[ -O "$d" ]` before its first fork, so processes of other uids (root daemons, other users) cost a `stat` and no fork. `[read: devcontainer-config/install.sh:1144-1146]`
- The `CLAUDE_FLAGS` refusal and the `FIXTURE_BASH` checks in runner-contract are fixed-size `case` and `[[ ]]` string tests that run once per generator run. `[read: test/skills/generate-reports.bash:114-124; test/skills/runner-contract.bash:99-116]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | procs_in_checkout: one fork per same-uid process, and in_lineage's `$$` ancestor walk recomputed for each candidate | Low | `devcontainer-config/install.sh:1116-1154` | Medium |
| 2 | install-host suite does a live /proc scan in every test that reaches agent_gate | Low | `test/install-host.bats` / `install.sh:1171` | Medium |
| 3 | mode1-equiv evaluator has no ulimit, and an uncaught TimeoutExpired aborts the check | Informational | `test/skills/arithmetic-eval/mode1-equiv.py:85-95` | Medium |

## Overall Assessment

For performance, the branch is fine. Every changed path is cold: a human-run installer whose checks come after interactive prompts, and a fixture and eval harness where each `claude -p` call costs far more than anything this branch added. The only cost that grows with the machine is `procs_in_checkout`: it forks for each same-uid process, and for each candidate in the checkout it walks the process tree twice, recomputing the same ancestor chain every time. It grows linearly, it is paid at most 4 times per install, and in the sandbox it is about 4 ms per same-uid process. The next step is to take one timing on the real host. Rewrite the loop as a single pass only if that timing is noticeable. None of the three findings blocks the merge. The regex, the tripwire and the runner checks all show linear, bounded behavior.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** A performance critique of the whole `main...HEAD` changeset. It covers each hot spot the brief named: the /proc loop and in_lineage forks (finding 1, measured in the sandbox), the tripwire's jq slurp (endorsement), mode1-equiv's per-call subprocess (finding 3), and WRAPPER_RE backtracking (endorsement, measured). It also covers the side effect on the test suite (finding 2).
- **Out of scope:** The security side of the /proc scan: the non-dumpable fail-open (Claims 6/10b) and the check-to-install window. The WRAPPER_RE contract gap (Claim 22). I ran no `claude` or network commands, and nothing was committed.
- **Escalate:** None from performance. Finding 1's point about the scan duration widening the check window is passed to security-reviewer for context only.
- **Questions:** How many same-uid processes does the host that runs install.sh typically have? One `time` of `procs_in_checkout` on that host would turn findings 1 and 2 from speculative into measured.
- **Decisions:** I used sandbox timings as supporting context and did not treat them as baselines, because they do not measure the host where install.sh runs.
