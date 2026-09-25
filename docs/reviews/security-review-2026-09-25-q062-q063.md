Commit: 5ddf804

# Security Review: skill-fixtures (Q-062 [2] detector, Q-063 [1] deny-record harness)

**Scope:** `git diff main...HEAD` on branch `skill-fixtures` (24 files). Security-relevant code: `devcontainer-config/install.sh` (`ppid_of`, `in_lineage`, `procs_in_checkout`, `agent_gate`), `test/skills/{runner-contract,generate-reports,eval-helpers}.bash`, `test/skills/arithmetic-eval/{mode1-equiv.py,runner.bash}`, decision 037.
**Date:** 2026-09-25
**Based on:** `docs/reviews/code-fact-check-report.md` (commit 5ddf804, 38 claims). Its executed verdicts are used as given and cited as FC-n. Settled override-log rows C4, C5, C6, C9, trap RETURN, `--tools` variadic and RUNNER_ALLOWED_TOOLS naming are not re-litigated.

## Trust Boundary Map

```
B1 (new):     [same-uid process state in /proc: cwd link, cmdline, PPid, S1/S2] → [procs_in_checkout + in_lineage filter]          → [agent_gate verdict: install proceeds or exit 1]
B2 (new):     [same-uid process cmdline, S2]                                     → [agent_gate message block | vis_or_die]         → [user's terminal (stderr)]
B3 (changed): [model's Bash tool_use, S4]                                        → [CLI --permission-mode dontAsk --permission-prompts none] → [execution on the host as the user's uid; --restricted drops the user sandbox config]
B4 (new):     [transcript JSONL: tool_use ids and permission_denials, S5]        → [jq tripwire (generator) + mode1-equiv.py re-check]  → [run recorded as valid / .failed]
B5 (new):     [model's Bash command text and heredoc body, S4]                   → [WRAPPER_RE + ast.dump equality]                → [reference evaluator `python3 -c <SKILL.md program>` with body on stdin] → [eval pass/fail]
B6 (changed): [operator env CLAUDE_FLAGS, S6]                                    → [deny-record case-pattern refusal]              → [claude argv, after the pinned flags]
```

Input-source classification:

```
S1: /proc/<pid>/cwd, /proc/<pid>/status PPid   — runtime, set by any same-uid process — UNTRUSTED toward the gate verdict (a
                                                   same-uid agent controls its own cwd, dumpable flag and lifetime)
S2: /proc/<pid>/cmdline                        — runtime, fully process-controlled        — UNTRUSTED toward terminal display and
                                                   toward text parsing (awk -v); informational only toward the verdict
S3: REPO_ROOT (pwd -P)                         — deploy-time (the user's checkout)        — trusted for path comparison
S4: model tool_use input (Bash command, body)  — request-time (model output)              — UNTRUSTED toward exec; UNTRUSTED toward
                                                   the eval verdict
S5: transcript JSONL written by the CLI        — per-run, CLI-authored; model text is JSON-escaped inside it — trusted as a record of
                                                   what the CLI saw; its completeness (a denied call is listed) rests on CLI behavior
S6: CLAUDE_FLAGS / CLAUDE_MODEL                — operator env                             — trusted (C4, Won't-Fix); partially validated here
S7: skills/arithmetic-eval/SKILL.md Mode 1 block — code-constant (repo file)              — trusted toward exec (the harness runs it,
                                                   as every test runs repo code)
S8: fixture drafts (tc-ae*.md)                 — code-constant, agent-authorable          — trusted toward exec (never executed); an
                                                   injection vector toward the model's choice of command (S4)
```

B1 is the Q-062 guard: it turns attacker-influenced `/proc` state into an allow/refuse decision, and every way it skips a process is a default-allow. B3 is the only thing standing between model-chosen commands and execution in fixture runs; B4 detects a B3 failure after the fact but does not prevent it. B5 executes only repo code (S7), with model text as stdin data.

## Findings

#### 1. Q-062 detector fails open on any same-uid process whose cwd link is unreadable (non-dumpable), and fail-closed is blocked by ssh-agent

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:1146` (in `procs_in_checkout`, `:1140-1154`); `docs/decisions/037-bare-host-copy-install.md:84`
**Boundary:** B1
**Move:** #3 (error path), #5 (invert the access model), #11 (bypass enumeration)
**Confidence:** High (mechanism executed); Medium on how often an agent helper would be non-dumpable by accident
**Legibility-target:** for-author

Evidence:
```bash
# devcontainer-config/install.sh:1144-1153
  for d in /proc/[0-9]*; do
    [ -O "$d" ] || continue                     # this uid's processes only
    cwd="$(readlink "$d/cwd" 2>/dev/null)" || continue
    case "$cwd" in "$root"|"$root"/*) ;; *) continue ;; esac
    ...
```
(excerpt ends :1146 of the loop body shown; the loop continues to :1153 and the function closes at :1154, read in full)

A failed `readlink` means the process is skipped, and a skip is an allow. One `prctl(PR_SET_DUMPABLE, 0)` makes a same-uid process's `/proc/<pid>/cwd` unreadable to the same uid. FC-6 executed this, and I reproduced it: a detached `python3 … prctl(4,0,…)` started with cwd in a scratch checkout gave `cwd=UNREADABLE` and was absent from `procs_in_checkout`'s output. A dumpable `sleep 40` in the same directory was listed. So an agent-spawned helper that is working inside the checkout gets past the Q-062 check if it drops its dumpable flag, or if it is started by something that does. This is the gate's purpose (Q-058: "one could change what you review before it is installed"). 037's residual list (`:84`) says an in-checkout process "is detected" and does not list this class.

The obvious fix, refusing when the cwd cannot be read, would refuse installs for a common benign process. In the same probe `ssh-agent -D` (same uid) also read `cwd=UNREADABLE`, because OpenSSH's agent disables tracing on Linux. So fail-closed means "stop ssh-agent before every install", and allowlisting it by cmdline is spoofable (S2). This is a trade-off for the user to decide, not a mechanical fix. Note also that an evading agent has cheaper routes: `chdir("/")` while holding a directory fd into the checkout also passes (probe: `sleep 41` with cwd `/` and fd 3 on the repo, not listed). That route is already covered by the "works outside the checkout" residual. The detector is a heuristic for leftovers, not a barrier against an evading same-uid process, which matches 037's "samples, not a lock" framing.

**Recommendation:** At minimum, add to 037's "What the gate does not see" and to the install.sh header: "a process in the checkout whose `/proc/<pid>/cwd` cannot be read (non-dumpable, e.g. `prctl(PR_SET_DUMPABLE, 0)`) is skipped". If the user wants it closed instead, refuse on an unreadable cwd and name the process with "cwd unreadable". That trades a guaranteed nuisance (ssh-agent) for closing a gap an evading agent can route around anyway (fd-held cwd). This is a question for the user (route `you: judgment`), not an author defect.

#### 2. deny-record's "nothing executes" rests on CLI permission semantics probed for one command class; the tripwire detects execution but does not prevent it

**Severity:** Medium
**Location:** `test/skills/generate-reports.bash:181-183` (pin), `:249-261` (tripwire); claims at `test/skills/arithmetic-eval/runner.bash:6`, `test/skills/runner-contract.bash:21`
**Boundary:** B3, B4
**Move:** #1 (per-consequence trust), #2 (implicit sanitization assumption), #11
**Confidence:** Low (whether any Bash call is auto-allowed under `dontAsk` is unverified; FC-30b is Unverifiable)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```bash
# test/skills/generate-reports.bash:181-183
  if [ "$FIXTURE_BASH" = "deny-record" ]; then
    claude_args+=(--permission-mode dontAsk --permission-prompts none)
  fi
```
and `docs/working/dd-arith-eval-bash-grant.md:161`: "**Probe A: `touch probe-ran && echo hi`.** … `probe-ran` was not created, so nothing executed."

`dontAsk` denies what would *prompt*. Anything that resolves to "allow" before the prompt stage runs. Three sources could do that: allow rules in managed settings or `--settings` (both survive `--restricted`, per FC pass-2 claim 4b; this host has none), hooks in managed settings, and the CLI's own read-only command auto-approval, if it applies in this mode. Probe A tested a compound command containing a write. It did not test a pure read-only command (`ls`, `pwd`, `cat subject.md`). If one of these sources fires, the command runs as the user's uid. It runs **without the Bash sandbox**, because `--restricted` ignores the user settings that enable it. The model's choice of command is steerable by fixture text (S8, agent-authorable). The tripwire then voids the run, so result integrity holds (FC-31, executed). But the property the docs state is "nothing ever executes", and the tripwire only records a breach after it has happened. The impact bound today is small: an empty inline temp dir, and read-only or path-confined commands. The claim, though, is categorical.

**Recommendation:** Extend Probe A with one pure read-only command (`claude -p … --permission-mode dontAsk --permission-prompts none … "run: pwd; ls"`), and confirm it appears in `permission_denials` (route `you: terminal`, one paste). If it executes, pin a deny layer that still records denials (for example a `--settings` deny rule, whose recording behavior needs its own probe), or reword the claims to "every Bash call is denied by the CLI unless pre-approved; any call that is not denied voids the run".

#### 3. WRAPPER_RE accepts commands that bash would run with trailing shell; safety currently rests on the evaluator rejecting `Name` nodes (Claim 22 escalation)

**Severity:** Low
**Location:** `test/skills/arithmetic-eval/mode1-equiv.py:33-40`; docstring `:7-9`; `test/skills/eval-helpers.bash:413`; `docs/decisions/log.md` #56
**Boundary:** B5
**Move:** #11 (bypass enumeration), #2
**Confidence:** High
**Legibility-target:** for-author

Evidence:
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
The lazy `expr` group backtracks past bash's first terminator line. I executed three bodies, each wrapped by SKILL.md's real wrapper and program and followed by a final `EXPREOF`: `(1900000000 +⏎EXPREOF⏎*0)`, `1900000000⏎EXPREOF⏎#` and `'''⏎EXPREOF⏎'''`. All three printed `call 1: Mode 1, expression … -> None` and exited 1. FC-22's `2⏎EXPREOF⏎touch pwned` gives the same result. So step 1 labels as "the Mode 1 wrapper" a command that bash would run with the post-terminator lines as shell. No false pass is reachable today, for this reason: a line that is exactly `EXPREOF` can only be a Python `Name` token, or sit inside a string constant, and the reference evaluator (`ev`) rejects `Name` and every non-numeric `Constant`. The mode1_equiv contract ("the command is Mode 1") therefore holds only through that evaluator property, not through the wrapper check the docstring credits. The coupling is fragile. A future Mode 1 extension that accepts identifiers would weaken it, for example a names table for `pi`/`e` or a lookup that falls back to a default. The model's command is never executed (B5 runs only S7 on stdin data), so this is a grading-contract flaw, not an execution path. It is Low, not Medium, because no reachable mechanism violates a security property.

**Recommendation:** Reject any `expr` that contains a line equal to `EXPREOF` (`re.search(r"(?m)^EXPREOF$", expr)` → "not the Mode 1 wrapper"), which makes the docstring's guarantee true on its own. Add the double-terminator case to `mode1-equiv.bats` next to test 7.

#### 4. Tripwire result is masked when an earlier failure is set

**Severity:** Informational
**Location:** `test/skills/generate-reports.bash:251`
**Boundary:** B4
**Move:** #3 (error path)
**Confidence:** High
**Legibility-target:** for-author

Evidence: `if [ -z "$failure" ] && [ "$FIXTURE_BASH" = "deny-record" ]; then` (`:251`; the block ends at `:261`, and `:264` writes `$failure` to `.failed`, read).

A run that executed a Bash call and then also exited non-zero, or ended in an error result, is recorded as `claude exited N` or `the result event is an error`, with no mention of the undenied call. The run fails either way, so no false pass is possible. But the one signal that says "a fixture run executed a model command on the host" is lost exactly when a run went wrong, and that is when an operator would most want it.

**Recommendation:** Evaluate the tripwire unconditionally under deny-record, and append its message to any existing `failure`.

#### 5. `awk -v seen="$procs"` decodes backslash escapes, so a Claude process's command line can hide another PID from the refusal listing

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:1180-1182`
**Boundary:** B1, B2
**Move:** #2, #11
**Confidence:** High (awk behavior executed); the gate verdict is unaffected
**Legibility-target:** for-author

Evidence:
```bash
# devcontainer-config/install.sh:1180-1182
  inrepo="$(printf '%s\n' "$inrepo" | awk -v seen="$procs" '
    BEGIN { n = split(seen, l, "\n"); for (i = 1; i <= n; i++) { split(l[i], f, " "); skip[f[1]] = 1 } }
    NF && !($1 in skip)')"
```
`awk -v` turns the two characters `\n` into a newline. Executed: `seen='111 claude a\n222'` yields skip entries `111` and `222`. pgrep keeps a literal backslash, so a Claude Code process whose argv contains `\n<PID>` removes that PID from the "Other processes … working inside" list. The gate still refuses, because `$procs` is non-empty. What goes wrong is that the user is shown an incomplete list and sees the hidden process only on the rerun. FC-7 says escapes "could only alter command-line text, never the leading PID field". That scope note is slightly off, because an escape can create a new field-1 entry.

**Recommendation:** Pass the PIDs through the environment or stdin instead of `-v` (e.g. `ENVIRON["seen"]`, which awk does not escape-process), or extract field 1 with `cut` before handing it to awk.

## Untested bypass candidates

- **Helpers started inside the Claude Code bwrap Bash sandbox on the bare host.** This is the population Q-062 targets. Whether their `/proc/<pid>/cwd` is readable from the host depends on their dumpable flag and on user-namespace ownership (a same-uid owner of a child user namespace passes the ptrace check even when the process is non-dumpable). Not tested because this sandbox has no `bwrap` and `unshare -Ur` returns "Operation not permitted". One bare-host check settles it: start `sleep 600 &` via a Claude Code Bash call in the checkout, `/exit`, then run `readlink /proc/<pid>/cwd` and `install.sh`.
- **Bind-mount or user-namespace aliasing of the checkout path** (the cwd is shown under another path in another mount namespace). Needs `unshare -Urm`, which is denied here.
- **Pure read-only Bash commands under `dontAsk`** (Finding 2). Needs a `claude` run.
- **Process-controlled empty cmdline** (`[ -n "$cmd" ] || continue`, `:1151`). Traced, not executed: on kernel ≥ 5.18 an `argc=0` exec gets an empty `argv[0]` inserted, and an all-NUL arg area still reads back as NULs → spaces (non-empty). Overwriting arg bounds needs `PR_SET_MM` (CAP_SYS_RESOURCE). Not exercised with a C helper.

Tested and cleared: **terminal-control bytes in an in-repo process's cmdline.** A detached `exec -a $'\e]0;PWNED-TITLE\a\e[2K\rclean' sleep 40` was listed by `procs_in_checkout` with raw ESC/BEL/CR bytes. The whole message block, however, is piped through `vis_or_die` (`install.sh:1203-1226`, `} | vis_or_die >&2`), which maps `\x1b`→`^[`, `\r`→`^M` and C0→`?`. So B2 is covered. `pgrep -af` output (the sibling path) already arrives escaped (`.]0;T.claude x`). **Sibling shell or process in the checkout, not in lineage:** detected (FC-1, and my `sleep 40` control). **fd-held checkout with cwd `/`:** not detected, by design (the documented "outside" residual).

## Endorsement Claims

- **Claim:** In `mode1_equiv`, the program executed is always the one extracted from SKILL.md (`ref_program`), never the model's copy. The model's heredoc body reaches it only as stdin data.
  **Location:** `test/skills/arithmetic-eval/mode1-equiv.py:85-88`, `:102`, `:127-128`
  **Evidence:** read-static (plus FC-24, executed)
  **Verified:** `evaluate(ref_program, expr)` passes `ref_program` from `reference(skill_path)` as the `-c` argv, and `expr` via `input=`. The model's `program` group is used only for `ast.dump` comparison.
  **Not verified:** the reference evaluator's own rejection set on adversarial stdin without the `ulimit` wrapper (covered by `arithmetic-eval-gate.bats`, which I did not rerun).
  **route: code-fact-check**

- **Claim:** Under deny-record, a Bash `tool_use` id missing from every result event's `permission_denials` marks the run `.failed` in the generator and fails `mode1_equiv` independently.
  **Location:** `test/skills/generate-reports.bash:249-261`; `test/skills/arithmetic-eval/mode1-equiv.py:107-112`
  **Evidence:** read-static (FC-25 and FC-31 executed the paths)
  **Verified:** both checks compute undenied = Bash tool_use ids − union of denial ids, and treat an unreadable transcript as failure.
  **Not verified:** that the CLI emits a `tool_use` event for every executed Bash call (a call that executes but is not streamed would evade both). Also the masking in Finding 4.
  **route: code-fact-check**

- **Claim:** The runner contract admits `Bash` in `FIXTURE_TOOLS` only together with `FIXTURE_BASH=deny-record` and `FIXTURE_TRANSCRIPT=1`, and rejects `Bash(<pattern>)` spellings through the tool-name regex.
  **Location:** `test/skills/runner-contract.bash:58-61`, `:70-72`, `:99-116`
  **Evidence:** read-static (FC-34 executed tests 29 and 30)
  **Verified:** check order (regex → allowlist or deny-record exception → FIXTURE_BASH validation); `reset_runner_settings` clears FIXTURE_BASH before each runner is sourced.
  **Not verified:** the newline-in-FIXTURE_TOOLS gap from pass 2 (Finding 1 there), which I did not re-probe against this branch's regex.
  **route: code-fact-check**

- **Claim (scoped prose):** Refusal messages that name in-repo processes pass through `vis_or_die`, so a process-controlled cmdline cannot emit raw terminal control bytes to the user's terminal.
  **Location:** `devcontainer-config/install.sh:1203-1226`
  **Evidence:** executed (probe above: raw bytes in `procs_in_checkout` output) plus read-static (message block piped to `vis_or_die`)
  **Verified:** the pipe placement and `vis`'s substitution set.
  **Not verified:** end-to-end rendering of that refusal on a real terminal (T88 asserts the text, not the absence of escapes).

## Primitive sweep

Primitive: process exec / shell interpolation of external data
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/skills/arithmetic-eval/mode1-equiv.py:87` `subprocess.run(["python3","-c",program], input=expr…)` | S7 program; S4 expr as stdin | argv list (no shell); program from SKILL.md only; timeout=10 | cleared: model text is data; Finding 3 concerns the classifier, not this call |
| `test/skills/eval-helpers.bash:422-423` `python3 …/mode1-equiv.py … "$t" "$spec"` | S5 path; spec from `expected-verdicts.bash` (code-constant) | quoted args | cleared |
| `test/skills/generate-reports.bash:225-227` `claude "${claude_args[@]}" $model_flag ${CLAUDE_FLAGS:-}` | S6 | deny-record case refusal (`:117-124`) | C4 Won't-Fix. Partial validator misses tab-prefixed flags and `--permission-prompt-tool` (FC-32); noted, not re-litigated |
| model Bash `tool_use` → CLI executor | S4 | `dontAsk` + `--permission-prompts none` | Finding 2 |
| `devcontainer-config/install.sh:1146` `readlink "$d/cwd"` | S1 | `-O` owner check | Finding 1 |
| `devcontainer-config/install.sh:1150` `tr '\0' ' ' < "$d/cmdline"` → message | S2 | `vis_or_die` at the sink | cleared (probe) |
| `devcontainer-config/install.sh:1180` `awk -v seen="$procs"` | S2 (via pgrep) | none (escape processing) | Finding 5 |
| `devcontainer-config/install.sh:1116-1121` `< "/proc/$1/status"` | glob-derived numeric PID | `/proc/[0-9]*` glob | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Unreadable (non-dumpable) cwd skipped by the Q-062 detector; fail-closed collides with ssh-agent | Medium | B1 | `install.sh:1146`; `037:84` | High |
| 2 | "Nothing executes" rests on `dontAsk` semantics probed for one command class; tripwire is detect-only | Medium | B3, B4 | `generate-reports.bash:181-183, 249-261` | Low |
| 3 | WRAPPER_RE accepts post-terminator shell; safety rests on the evaluator rejecting Names | Low | B5 | `mode1-equiv.py:33-40` | High |
| 4 | Tripwire masked by an earlier failure | Informational | B4 | `generate-reports.bash:251` | High |
| 5 | `awk -v` escape decoding lets a cmdline hide a PID from the listing | Informational | B1, B2 | `install.sh:1180-1182` | High |

## Overall Assessment

No finding blocks the merge. The branch adds no execution path for model-chosen commands on the eval side: `mode1_equiv` runs only SKILL.md's evaluator on model text as stdin. The two escalations resolve as follows. The WRAPPER_RE gap (Claim 22) is a contract flaw with no reachable false pass, fixable with one regex line. The non-dumpable gap (Claims 6/10b) is a real fail-open in the Q-062 detector. Its cheap fix is documentation, because the fail-closed alternative refuses whenever ssh-agent runs, and an evading agent has the fd-held-cwd route anyway. The detector is a leftover-process heuristic, consistent with 037's "samples, not a lock", and 037 should say that about unreadable cwds. The single most important open item is Finding 2's one-paste probe: the harness's categorical "nothing ever executes" has so far been observed only for a compound write command, and the tripwire catches a breach only after the fact. No findings within the code paths read are High or Critical. Endorsement claims are pending execution verification.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** "A markdown critique saved to the path named in your role section below, structured per your skill."
- **Answered:** Security design review of the full branch diff, saved to `docs/reviews/security-review-2026-09-25-q062-q063.md` with `Commit: 5ddf804`. On the Q-062 detector's trust assumptions: a same-uid adversary evades it by going non-dumpable (Finding 1, executed) or by holding an fd with cwd outside (documented residual). TOCTOU across the four gate moments is left as 037's known residual. Terminal injection via cmdline was tested and cleared, and lineage exemption has no adversarial insertion path found. On the harness boundary: can a fixture run execute anything? Only if a Bash call resolves to "allow" under `dontAsk`, which is unverified for read-only commands (Finding 2). Is the tripwire sound? Yes for integrity, but it is detect-only and masked on earlier failure (Finding 4). Can mode1_equiv be satisfied by a non-Mode-1 command? No, but the guarantee holds through the evaluator, not the wrapper regex (Finding 3). Does it execute untrusted code? No, only S7 with S4 as stdin. Both escalations are actioned (Findings 1 and 3).
- **Out of scope:** running `claude` (Finding 2's probe; FC-14/30b/32); C4 CLAUDE_FLAGS completeness (noted in the sweep only); re-running `arithmetic-eval-gate.bats`; the bwrap-sandboxed-helper and mount-alias candidates (no bwrap or user namespaces in this sandbox).
- **Escalate:** Finding 1's fix direction is a user judgment (document the gap vs. fail-closed with an ssh-agent nuisance) and should become a questions-doc entry. Finding 2 needs one `you: terminal` probe on the host. The bare-host bwrap-helper readability check (Untested candidates, first bullet) could share that paste.
- **Questions:** Does the Q-062 threat model intend to cover an agent that actively evades (non-dumpable, fd-held cwd), or only accidental leftovers? The answer sets Finding 1's severity reading, and whether 037 should say "heuristic" explicitly.
- **Decisions:** I rated Finding 3 Low rather than Medium under the floor rule because no security property is violated by a reachable mechanism: nothing is executed, and no pass is possible. I rated Finding 2 Medium, with Low confidence, per the floor rule, since the mechanism is named but its existence is unverified. I did not write separate execution-log files. The probe outputs are summarized inline.
