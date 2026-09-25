# API Consistency Review: copy-install Q-058 restart (`9ae6e46..b4fd792`)

Commit: b4fd792
**Scope:** 8 commits `9ae6e46..b4fd792` on `ans/copy-install`. The files in scope are `devcontainer-config/install.sh`, `test/install-host.bats`, `test/cc-isolated-functions.bats`, `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `guides/bare-host-hook-wiring.md` and `docs/working/plan-copy-install-bare-host.md`, plus the commit messages. Code was read in the worktree `/workspace/.claude/wt-copyinstall`.
**Date:** 2026-09-24
**Based on:** the stage-1 fact-check reports `docs/reviews/code-fact-check-report-r1.md`, `-r2.md` and `-r3.md` (k=3). The prior final rubric `code-review-rubric-2026-09-23-ans-copy-install-final.md` was used as advisory input only.

The surface under review is install.sh's CLI contract: its flags, exit status, the ERROR/WARNING/NOTE message classes, the refusal trailers, `--help`, and the docs that restate that contract (README, the hook-wiring guide, decision 037, the plan's Risks).

## Baseline Conventions

These conventions come from install.sh as it stood at `9ae6e46` and its sibling scripts:

- **Refusal shape.** A refusal prints `ERROR: <what>` to stderr, followed by indented continuation lines (7 spaces). It ends with a trailer saying what was not done and exits 1. Examples: `head_commit` (`install.sh:131-133`), `extract_commit` (`:153-156`, `:176-179`), `host_refuse` (`:491-495`) and the control-character refusal (`:927-930`). Trailers are `Nothing was installed.` for the devcontainer target and startup, and `Nothing was installed into the host target.` for the host target (`host_refuse`).
- **Advisories.** `WARNING:` goes to stdout (`install.sh:228`, `:613`). So does cc-isolated's `NOTE:` (`cc-isolated.sh:594`, `:626`).
- **Declines.** A decline prints `Aborted. Nothing was changed. (<target>)`, with the suffix `(devcontainer config)` or `(host ~/.claude)` (`:384`, `:689`). It sets `DECLINED=1` and the run continues.
- **Skips.** A skip prints `Skipped host target (~/.claude): <reason>. Run install.sh …`. It does not change the exit status (`:541-550`).
- **Exit status** (`--help`, `:71-72`): `0 no target declined; 1 a target was declined, or an error; 2 bad arguments.`
- **Untrusted text shown to the user** goes through `vis` (`:119-126`), for example file names (`:177`) and link targets (`:600`).
- **Internal question IDs appear in user-facing text.** The precedent is `WARNING: not in the repo; these will be MOVED to the backup (Q-057):` (`:613`).
- **Names.** Functions are snake_case, verb_noun or noun_noun (`head_commit`, `review_diff`, `host_refuse`, `has_ctrl`). Constants are UPPER_SNAKE (`PAYLOAD`, `CLAUDE_HOME_SRC`). Temp dirs use the prefix `cw-<target>-stage.XXXXXX` (`:346`, `:583`).
- **The docs contract is stated in three places**: `--help`, README `:15-39`, and decision 037 "Decision and rationale". Earlier reviews flagged drift between them (final rubric A1).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `agent_gate` | function | `host_refuse`, `head_commit`, `review_diff`, `has_ctrl` | `devcontainer-config/install.sh:129,247,491,890` | Consistent: snake_case noun_noun |
| `CLAUDE_PROC_RE` | constant | `HOST_RE`, `ZONE_RE` | `devcontainer-config/init-firewall.sh:135,151` | Consistent: UPPER_SNAKE with an `_RE` suffix for a regex |
| `cw-docker-err.XXXXXX` | temp-file prefix | `cw-devc-stage.XXXXXX`, `cw-host-stage.XXXXXX` | `devcontainer-config/install.sh:346,583` | Consistent: `cw-` prefix |
| `NOTE:` (docker not found / unreachable) | message class | `NOTE: $ws is unregistered …`, `NOTE: blessed config … NOT verified` | `devcontainer-config/cc-isolated.sh:594,626` | Consistent: stdout advisory. See F3 and F4 for its wording and count |
| `ERROR: pgrep is not installed … Install procps and rerun.` / `ERROR: perl is not installed … Install perl and rerun.` | refusal message | `ERROR: … Nothing was installed.` family | `devcontainer-config/install.sh:131-133,153-156,927-930` | Consistent in shape. The trailer varies (F7) |
| `docker ps --filter label=cc-project` | external contract (label) | `--id-label "cc-project=$pid"` | `devcontainer-config/cc-isolated.sh:412,623` | Consistent: the filter reads the label cc-isolated writes |
| `(Q-058)` in messages | user-facing ID | `(Q-057)` | `devcontainer-config/install.sh:613` | Consistent with precedent |
| `stub_pgrep`, `stub_docker` | test helper | `commit_all`, `run_pty`, `fake_repo`; `smart_devcontainer_stub` | `test/install-host.bats`, `test/cc-isolated-functions.bats:901` | Consistent within the file (verb_noun). The one cross-file analog puts `stub` last, but it is a single example, not a convention |
| `path_without` | test helper | `no_host_stage_left`, `installed_then_changed` | `test/install-host.bats` | Consistent: a descriptive snake_case helper |
| `T50`–`T64` | test IDs | `T1`–`T49` | `test/install-host.bats` | Consistent. They are out of numeric order in the file (T64 after T52), but the file was already out of order (T24 after T62) |
| `## Trust model (Q-058)` | decision section heading | `## Validation addendum (2026-08-15, same session)`, `## Implementation status (2026-08-06)` | `docs/decisions/032-review-loop-token-reduction-levers.md`, `docs/decisions/033-fact-check-atomic-verdicts.md` | Consistent: an addendum section with a parenthetical qualifier, placed before `## Revisit triggers` |

No naming findings. No row above is inconsistent with its neighbors.

## Findings

#### F1. The "skipped inside a Claude Code session" contract in `--help`, README and decision 037 can no longer happen in practice: an in-session run is now refused with exit 1

**Severity:** Inconsistent
**Location:** `devcontainer-config/install.sh:60-63`, `:947` · `README.md:28-31` · `docs/decisions/037-bare-host-copy-install.md:31-34`
**Move:** 3 (trace the consumer contract: documentation drift)
**Confidence:** High
**Legibility-target:** a `--help` or README reader, a script or agent that runs `install.sh --yes`, and a decision 037 reader

Evidence:
```
install.sh:60-63
Target 2 is SKIPPED, with a message and no effect on the exit status, when
--yes is given, when stdin is not a terminal, or when running inside a
Claude Code session (CLAUDECODE set). That stops accidental runs,
not a determined agent: a pty wrapper and `env -u CLAUDECODE` get past it.

install.sh:947   (main, before install_devcontainer)
  agent_gate "Nothing was staged or installed."

README.md:28-29
`~/.claude` target is skipped with `--yes`, from a script with no TTY, and inside
a Claude Code session. That stops accidental runs, not a determined agent (a pty

037:33
  - The skip happens before it reads or stages anything, so every existing non-interactive devcontainer run is unchanged apart from two extra lines (a blank line and the skip line).
```
In a real session, the gate's probe finds the session itself. I ran `CLAUDE_PROC_RE` through pgrep in this session, which has `CLAUDECODE=1`, and it listed `1750 claude`. Commit ea2c8fb says the same: "the existing suites stub them to 'none', because the session running them is itself a claude process". So a run from inside a Claude Code session now stops at `:947` with `ERROR: an agent is running …` and exit 1. It never reaches target 1 or the CLAUDECODE skip at `:544-547`. That skip line now fires only when the probe misses the session (for example a renamed binary). The suites exercise it only because pgrep is stubbed. The three docs still describe the old contract: target 1 runs, target 2 is "SKIPPED … with no effect on the exit status". Decision 037:33 still promises that non-interactive devcontainer runs are "unchanged apart from two extra lines". A non-interactive `--yes` run now also gets one or more `NOTE:` lines on a host without docker (F3), and exit 1 whenever any Claude Code process runs. The new "Trust model" section sits next to these statements without reconciling them. The behaviour change itself (exit 0 → 1 for `--yes` from an agent session) is the one the user chose in Q-058 [2]. I found no in-repo automated caller of `install.sh --yes` outside tests and review logs. So this is documentation drift, not an unrecorded break.

**Recommendation:** In `--help` and README, change the CLAUDECODE clause to something like: "Inside a Claude Code session the whole run is refused at startup (the no-agent check finds the session); the CLAUDECODE skip remains as a backstop for a session the check misses." In decision 037:31-34, add a pointer such as "superseded in part by Trust model (Q-058): a run with an agent present exits 1".

#### F2. A `vis` failure outside `review_diff` exits 1 with no message, unlike every other refusal, and the fa69656 Notes describe the wrong mechanism

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:600`, `:606`, `:625`, `:646-647`, `:653-654` (host pre-pass); `:863`, `:884` (`agent_gate`); `:340` (claude-home symlink error); commit fa69656 Notes
**Move:** 4 (error consistency)
**Confidence:** High (fact-check r3 Claim 7b, probes X2/X3; r1 Claim 27; r2 Claim 27)
**Legibility-target:** the user at the terminal, who sees output stop with no ERROR line, and a commit-log reader who trusts the Notes

Evidence:
```
install.sh:26         set -euo pipefail
install.sh:600        echo "REPLACE symlink $dest/$name -> $(readlink "$dest/$name") with a copy" | vis
install.sh:625        echo "$line" | vis
install.sh:646        echo "ADD $dest/$name (new, $n file(s)):" | vis
install.sh:863        echo "NOTE: docker is unreachable ($err): cc-isolated containers not checked, treated as none running." | vis
install.sh:870-884    {  echo "ERROR: an agent is running. …"  [… :871-883, the refusal body …]  } | vis >&2
install.sh:885        exit 1

fa69656 Notes: "other `| vis` uses (MODE, MOVE, ADD lines) are not individually checked; perl
missing is now refused up front, and a vis that fails there fails in review_diff too, which aborts."
```
`review_diff` now turns a vis failure into `ERROR: could not show the review of payload item '…' (vis exit N). The review diff is incomplete, so nothing was installed.` (`:267-271`), which matches the baseline refusal shape. The other `| vis` sites run under `set -euo pipefail` in a plain (not `||`) context: `install_claude_home` and `agent_gate` are both called directly from `main`. The first failing pipeline therefore ends the script with exit 1 and nothing on stderr. Fact-check r3 X2 and X3 show the host output stopping right after `=== Changes this install would make ===`. The failure is fail-closed (nothing installed, exit 1), so R2's safety half holds. The API contract does not. Every other refusal names itself and ends in a "Nothing was installed" trailer, and here the user gets neither. In `agent_gate`, a vis failure at `:863` also turns "docker unreachable → proceed" into a silent exit 1. At `:884` it drops the list of agents to stop. `mode_diff`'s MODE lines (`:299`) are the only case that reaches `review_diff` as the Notes claim (r2 Claim 27).

**Recommendation:** Pick one of two fixes. (a) Wrap the checked form once, e.g. `vis_or_die() { vis || { echo "ERROR: could not show the review (vis failed). Nothing was installed." >&2; exit 1; }; }`, and use it at the sites above. (b) Add a single `trap 'echo "ERROR: install.sh stopped at line $LINENO. Nothing was installed." >&2' ERR` scoped to the pre-prompt phase. At minimum, correct the mechanism in the plan's Risks or decision 037, since commit messages can't be amended here.

#### F3. "One line" for an absent or unreachable docker is one line per gate call: 2 on a `--yes` run, up to 3 interactively

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:56-57`; `docs/decisions/037-bare-host-copy-install.md:70`; commit ea2c8fb body (`log.txt:26`)
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check r1 Claim 3, X3 `NOTES=2`; r2 Claim 14)
**Legibility-target:** a `--help` reader, and anyone parsing or grepping the output

Evidence:
```
install.sh:56-57   Without pgrep it refuses; without a reachable docker it says so in one line
                   and treats no container as running.
037:70             If docker is missing or unreachable, one line says so and no container is assumed.
ea2c8fb            No or unreachable docker: one NOTE line, treated as none running.
install.sh:391     agent_gate "Nothing was installed. (devcontainer config)"
install.sh:695     agent_gate "Nothing was installed into the host target."
install.sh:947     agent_gate "Nothing was staged or installed."
```
`agent_gate` prints the NOTE on every call (`:853-854`, `:862-863`), and it is called at startup, after target 1 is accepted, and after the host y. On a WSL host without docker, a plain run that accepts both targets prints the same NOTE three times, spread across the devcontainer output and the host review.

**Recommendation:** Either change the docs to "says so (a NOTE line at each check)", or print the NOTE only on the first call. For the second option, keep a run-scoped flag and keep re-probing silently, so the fail-open behaviour stays announced once rather than dropped.

#### F4. The "docker is unreachable (…)" NOTE mislabels a timeout, a missing `timeout` binary and stderr noise; `timeout` is an unlisted dependency

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:860-865`, `:66`
**Move:** 4 (clear, consistent error messages)
**Confidence:** High (executed; see below)
**Legibility-target:** a user deciding whether the fail-open container check really ran

Evidence:
```
install.sh:860-865
    if ! ctrs="$(timeout 20 docker ps --filter label=cc-project \
                   --format '{{.Names}} cc-project={{.Label "cc-project"}}' 2>"$errf")"; then
      err="$(head -n 1 "$errf" 2>/dev/null)"
      echo "NOTE: docker is unreachable ($err): cc-isolated containers not checked, treated as none running." | vis
      ctrs=""
    fi
install.sh:66      Needs git, perl (the review's control-byte filter) and pgrep; refuses without them.
```
I ran this block verbatim in the scratchpad (`api-x/t.sh`) with a stub docker that sleeps past the timeout:
- With the locale clean, it printed `NOTE: docker is unreachable (): cc-isolated containers not checked, treated as none running.` The empty parentheses mean a silent exit 124.
- Under an uninstalled `LC_ALL`, it printed `NOTE: docker is unreachable (/bin/bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)): …`. `head -n 1` shows the first stderr line, which is the same class of noise commit 648124c separated out, not the error. That run used a script stub. A real Go docker binary would not print the bash warning, but wrapper scripts (podman-docker) can.
- Reading the code, a missing `timeout` gives exit 127 and the same "docker is unreachable" wording.

All three cases fail open, and the wording is the user's only cue that the container half of the gate did not run.

**Recommendation:** Tell exit 124 apart ("docker did not answer within 20s"). Show the last non-blank stderr line, or all of them, through vis. Either add `timeout` to the `Needs …` line or check for it along with pgrep.

#### F5. The detector and when it runs are described four ways, and only the code comment matches the code

**Severity:** Minor
**Location:** `docs/decisions/037-bare-host-copy-install.md:75`; `docs/working/plan-copy-install-bare-host.md:244`; `guides/bare-host-hook-wiring.md:17-19`; the accurate one is `devcontainer-config/install.sh:827-834`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check r1 Claims 19/21; r2 Claim 24; r3 Claim 18)
**Legibility-target:** a user trying to understand a false-positive refusal, and a decision 037 reader judging the residuals

Evidence:
```
install.sh:831-834  A command line with a `.../claude`
                    argument (`vim ./claude`, `tail -f /var/log/claude`) also matches: the install
                    is refused, and the message names the process.
                    CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/'
037:75   … a renamed or wrapped binary whose command line does not end in `claude`, …
plan:244 … on a host where some unrelated command line ends in `/claude`; the message names the process.
guide:17-19  First close every Claude Code session and stop every
             cc-isolated container: the installer refuses to stage or install while either runs (Q-058; see
```
The regex matches any token that is `claude` or ends in `/claude`, anywhere in the command line: `claude --resume` does not "end in claude" and still matches, and `vim ./claude` matches through its argument. Decision 037 describes a miss as "does not end in `claude`", and the plan describes a false positive as "command line ends in `/claude`". Both are narrower than the rule. The guide says the installer refuses "to stage … while either runs", but the host target stages with no fresh check after the startup gate (r2 Claim 24). README:35-36 and `--help` state the timing correctly ("before it stages anything and again after each y").

**Recommendation:** Reuse the install.sh comment's wording in 037:75 and plan:244 ("a token that is `claude` or ends in `/claude`, anywhere in the command line"). In the guide, use README's timing sentence.

#### F6. `DOCKER_HOST`/`DOCKER_CONTEXT` are undocumented inputs to the gate, although ea2c8fb says it has "no bypass beyond PATH"

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:33-40` (the env vars `--help` lists), `:860`; commit ea2c8fb Notes (`log.txt:35`)
**Move:** 3 (consumer contract: implicit inputs)
**Confidence:** High (fact-check r1 Claim 25; r3 Claim 22)
**Legibility-target:** a `--help` reader who wants to know which environment changes the result

Evidence:
```
ea2c8fb Notes: No env override for the probes: tests use PATH
               stubs, so the gate has no bypass beyond what PATH already allows.
install.sh:860 if ! ctrs="$(timeout 20 docker ps --filter label=cc-project \
```
`--help` lists every environment variable install.sh reads to choose destinations. The docker CLI also chooses its daemon from `DOCKER_HOST`, `DOCKER_CONTEXT` and `~/.docker/config.json`. Pointing it at an empty or unreachable daemon turns the container check off, with only a NOTE to show for it (F4). That is an input to the refusal decision that the CLI contract doesn't name. It is announced, so the scope is small.

**Recommendation:** Add one line to the Q-058 paragraph of `--help`: "docker's own DOCKER_HOST/DOCKER_CONTEXT choose which daemon is asked." Add the same line to decision 037's "probe misses" residual.

#### F7. The refusal trailers across the new call sites mix the decline-suffix style and the error style

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:391`, `:695`, `:943`, `:947`; compare `:384`, `:493`, `:929`
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** a user reading which target a refusal applied to

Evidence:
```
install.sh:384  echo "Aborted. Nothing was changed. (devcontainer config)"      (decline)
install.sh:391  agent_gate "Nothing was installed. (devcontainer config)"       (new: error)
install.sh:493  echo "       Nothing was installed into the host target." >&2  (host_refuse)
install.sh:695  agent_gate "Nothing was installed into the host target."        (new: matches host_refuse)
install.sh:929  echo "       or HOME). install.sh refuses it. Nothing was installed." >&2   (startup, pre-staging)
install.sh:943  echo "       (vis). Install perl and rerun. Nothing was staged or installed." >&2   (new: startup)
```
The host gate follows `host_refuse`. The devcontainer gate takes the decline's `(devcontainer config)` suffix, which no other devcontainer error uses. The two new startup refusals say "staged or installed", while the existing startup refusal at `:929`, which also fires before any staging, says "Nothing was installed". Each variation is accurate. Together they give three trailer forms for the same condition.

**Recommendation:** No action needed for merge. If the messages are touched again, pick one trailer per phase: startup "Nothing was staged or installed.", devcontainer "Nothing was installed (devcontainer config).", host as today.

#### F8. A gate refusal shares exit 1 with a decline and any error

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:71-72`, `:885`
**Move:** 4 / 6 (error codes; versioning impact)
**Confidence:** High
**Legibility-target:** a wrapper script's author

Evidence:
```
install.sh:71-72  Exit status: 0 no target declined; 1 a target was declined, or an error;
                  2 bad arguments.
install.sh:885    exit 1
```
This is consistent with the documented contract: a refusal is "an error". But a wrapper cannot tell "close your sessions and retry" from "the user said n" or "the payload is broken". The prior rubric's C1 already noted the coarse exit-1 semantics. Q-058 adds the first refusal that is transient and retryable.

**Recommendation:** Leave as is unless a wrapper appears. If one does, reserve a distinct code (e.g. 3, "refused: an agent is running") and document it in the Exit status line.

#### F9. README and the guide don't name the perl/pgrep requirement; only `--help` does

**Severity:** Informational
**Location:** `README.md:15-39`; `guides/bare-host-hook-wiring.md:14-20`; `devcontainer-config/install.sh:66`
**Move:** 3 (documentation drift)
**Confidence:** High (grep of README, the guide and 037 for `perl`: no match)
**Legibility-target:** a first-time user on a minimal host

Evidence:
```
install.sh:66   Needs git, perl (the review's control-byte filter) and pgrep; refuses without them.
README.md:31    access to `~/.claude`. `install.sh --help` has the details.
```
Prior R2 (API half) called perl "a new, undocumented host dependency". It is now documented in `--help` and pinned by T57. The startup refusal names it and says how to fix it. README defers to `--help`, which is acceptable, so this finding records the remaining gap rather than a defect.

**Recommendation:** Optionally add "(needs git, perl and pgrep)" to README's first install sentence.

## What Looks Good

- **The perl and pgrep refusals** (`:941-945`, `:840-844`) match the baseline exactly: `ERROR:` to stderr, an indented continuation, a concrete remedy (`Install perl and rerun.`, `Install procps and rerun.`) and exit 1. Both run before anything is staged, in the order `--help` lists them.
- **The `review_diff` vis check** (`:265-271`) reuses the wording of the neighbouring `diff exit` error (`The review diff is incomplete, so nothing was installed.`) instead of inventing a new one.
- **The agent refusal says how to recover.** It lists each PID and command line, and each container name and project id, and gives the stop command for each (`/exit` or `kill <PID>`, `docker stop <name>`). All of it goes through `vis`, as untrusted text should.
- **stdout/stderr discipline.** Advisories (`NOTE:`) go to stdout as cc-isolated's do. Refusals go to stderr. 648124c keeps docker's stderr out of the container list, which is the right separation (T64).
- **Cross-component contract.** The `label=cc-project` filter reads exactly the `--id-label "cc-project=$pid"` that cc-isolated writes (`cc-isolated.sh:412,623`). Decision 037's new revisit trigger names that coupling.
- **Docs are pinned by tests.** T56 pins `--help`, README and the guide; T63 pins the 037 section and the plan's Risks line. That guards against the three-places drift the earlier rubric (A1) flagged, although it did not catch F1.
- **Existing refusal texts are unchanged.** The existing refusal and skip messages still read the same, so scripts grepping for `Aborted.`, `Skipped host target` and the like are unaffected.
- **R2's API half is resolved.** perl is a declared, checked and documented dependency with a named refusal, and a `vis` failure in the review diff is an explicit error, not an empty review that still prompts. The silent-exit residual (F2) fails closed.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | In-session skip contract in `--help`/README/037 no longer happens; the run exits 1 | Inconsistent | `install.sh:60-63,947`; `README.md:28-31`; `037:31-34` | High |
| F2 | vis failure outside `review_diff` exits 1 with no message; fa69656 Notes misstate it | Minor | `install.sh:600,606,625,646,863,884,340` | High |
| F3 | "one line" NOTE is one per gate call (2–3 per run) | Minor | `install.sh:56-57`; `037:70`; ea2c8fb | High |
| F4 | "docker is unreachable ()" mislabels a timeout, a missing `timeout` and stderr noise | Minor | `install.sh:860-865,66` | High |
| F5 | Detector shape and timing described four ways; only the code comment is right | Minor | `037:75`; `plan:244`; `guide:17-19` | High |
| F6 | DOCKER_HOST/DOCKER_CONTEXT are undocumented gate inputs | Minor | `install.sh:33-40,860`; ea2c8fb | High |
| F7 | Refusal trailers mix the decline-suffix and error styles | Informational | `install.sh:391,695,943,947` | High |
| F8 | Gate refusal shares exit 1 with a decline or an error | Informational | `install.sh:71-72,885` | High |
| F9 | perl/pgrep named only in `--help` | Informational | `README.md:15-39`; guide `:14-20` | High |

## Overall Assessment

The Q-058 restart follows install.sh's established CLI conventions closely. The new function, constant, temp-file prefix, NOTE class, label filter and test helpers all match their neighbours; the name-pattern audit has no inconsistent rows. The new refusals use the existing `ERROR: … Nothing was installed.` shape, and the exit-status contract is unchanged. The one consumer-visible problem is F1: `--help`, README and decision 037 still promise that an in-session run installs target 1 and skips target 2 "with no effect on the exit status". In practice that run is now refused at startup with exit 1. This is the change the user chose; only the docs lag. It is a text fix in three places. F2–F6 are wording and accuracy issues in messages, docs and commit Notes, all fixable where they are, and none of them fail open beyond what the docs already accept. From the API-consistency lens nothing blocks merging. **R2's API half (perl as an undocumented dependency, and a review that is empty yet still prompts) is resolved.** The remaining vis gap (F2) is a missing message on a fail-closed path, not a fail-open review.

## Goal-Alignment Note
- Success criterion (restated verbatim): "a markdown report saved to the output path named at the end of this prompt, structured per the skill."
- Answered: an API-consistency review of `9ae6e46..b4fd792` covering install.sh's flags, exit codes, messages, `--help` and refusal behaviour, plus the docs contract (README, guide, decision 037, plan). It includes the required name-pattern audit (11 rows, no naming findings) and 9 findings (1 Inconsistent, 5 Minor, 3 Informational, no Breaking). Verdict on R2's API half: resolved. The fact-check's "silent exit 1 with no message" question is answered in F2: it is inconsistent with every other refusal, which names itself, but it fails closed.
- Out of scope:
  - Whether the gate is sufficient as a security control. That covers point-in-time sampling, the devcontainer stage having no content check after review (fact-check r2 escalation, P3), the `mkdir`→`cp` race before the prompt (r1 Claim 28b), and the completeness of decision 037's residual list (TAB/newline names planted earlier; r1 Claim 19). These belong to the security critic.
  - Test adequacy beyond naming.
  - Performance.
  - The `docs/reviews/` files, which were context only.
- Escalate:
  - F1 should be fixed before merge if the three-place CLI contract is meant to stay authoritative. It is the only finding a user or script would act on wrongly.
  - The merge decision should weigh the security critic's view of fact-check r2's escalation: target 1's stage is protected only by the gate sampled at the y, with no hash check like R2's host-side one. That concern belongs to R1, not to this lens.
