Commit: 61d801c

# API Consistency Review — Q-076 (feat/q076-git-exit-scan)

**Scope:** `git diff main...feat/q076-git-exit-scan`. Consumer-facing surfaces: the new `cc-push` CLI (`devcontainer-config/cc-push.sh`: flags, positional, env vars, exit codes, help, messages); `cc-isolated`'s changed exit-code contract (`devcontainer-config/cc-isolated.sh`); `install.sh`'s link/usage text; `guides/cc-isolated-usage.md` command reference.
**Date:** 2026-09-27
**Based on:** `docs/reviews/q076-code-fact-check-report-r1.md`, `-r2.md`, `-r3.md`; CLI probes in `/tmp/claude-1000/-workspace/dbfd30e0-d8d5-40c1-8bac-572239fc44fd/scratchpad/q076rev-perfapi/measurements.log`.

## Baseline Conventions

These are the host-side CLIs in `devcontainer-config/` at 61d801c: `cc-isolated.sh` (`main`, `:1304-1471`) and `install.sh` (`usage` `:28-100`, `main` `:1298-1306`).

- **Flags.** Long `--word` flags, space-separated values only (no `--flag=value`), `-h|--help` → usage on stdout, exit 0. Both scripts share `--yes` (install.sh `:1302`; cc-push reuses it). An unknown flag gets an error line on stderr, **then** usage on stderr (cc-isolated `:1323`; install.sh `:1304`).
- **Positional.** One optional repo path, defaulting to the repo containing `$PWD` (cc-isolated header `:7-8`).
- **Help source.** cc-isolated prints its header comment (`sed -n '2,29p'`, `:1301`). install.sh prints a heredoc that ends in an explicit **"Exit status:"** section (`:98-99`).
- **Exit codes.** cc-isolated: 1 for usage and every error. install.sh: `0 no target declined; 1 a target was declined, or an error; 2 bad arguments` (`:98-99`, `:1304`).
- **Messages.** Prefixes `ERROR:`, `WARNING:`, `NOTE:`, continuation lines indented, to stderr (errors and warnings) or stdout (notes and progress).
- **Env overrides for host paths.** `CLAUDE_DEVC_CONFIG_DIR` (default `~/.config/claude-devcontainer`, cc-isolated `:50`, install.sh `:1309`), `CLAUDE_DEVC_BIN_DIR` (install.sh `:1310`), `CLAUDE_HOME_DIR`/`CLAUDE_CONFIG_DIR`. Nothing in `devcontainer-config/`, `scripts/` or `hooks/` reads `XDG_*` before this diff. `CC_*` names are used for container- and hook-side values (`CC_PROJECT_ID`, `CC_CONFIG_DIR`, `CC_EGRESS_DIR`, `CC_WEB_TAINT_DIR`, `CC_SNI_RUN_DIR`).
- **Installed name.** `$BIN_DIR/<tool>` → `$DEST/<tool>.sh` symlink (install.sh `:598`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `cc-push` | command | `cc-isolated`, `install.sh` | `devcontainer-config/install.sh:598-603` | Consistent — `cc-` prefix, linked `$BIN_DIR/cc-push → $DEST/cc-push.sh` like cc-isolated |
| `--yes` | flag | install.sh `--yes` | `devcontainer-config/install.sh:95,1302` | Consistent — same meaning (answer y without asking) |
| `--help`, `-h` | flag | cc-isolated and install.sh `--help/-h` | `cc-isolated.sh:1321`, `install.sh:1303` | Consistent |
| `--remote URL` | flag | `--profile VALUE` (value flag) | `cc-isolated.sh:1314-1320` | Consistent in form (space-separated value, error when missing). Persists state as a side effect (see F7) |
| `--branch NAME` | flag | none — no existing flag takes a git ref | none — searched `devcontainer-config/*.sh` flag cases | New — matches git's own vocabulary |
| `--clone DIR` | flag | none — no existing flag takes a path; paths come from env vars | `install.sh:1309-1310` | New category — the only path-valued flag; the path is also env-overridable (F4) |
| `CC_PUSH_CLONES_DIR` | env var | `CLAUDE_DEVC_CONFIG_DIR`, `CLAUDE_DEVC_BIN_DIR` | `install.sh:1309-1310`, `cc-isolated.sh:50` | Inconsistent — host-path overrides use `CLAUDE_DEVC_*` (F4) |
| `$XDG_DATA_HOME/cc-isolated/clones` | data dir | `~/.config/claude-devcontainer`, `~/.local/bin` (not XDG-aware) | `cc-isolated.sh:50`, `install.sh:1309-1310` | Inconsistent — first XDG use; directory named `cc-isolated`, not `claude-devcontainer` (F4) |
| `refs/cc/heads/*` | ref namespace | `refs/remotes/origin/*` | git convention; `cc-push.sh:213` | Consistent — a private namespace kept apart from `refs/remotes` |
| `cc-push-checkout` | marker file | `verified-live.sha256`, `manifest.sha256` | `cc-isolated.sh:57-63` | Consistent enough — descriptive, tool-prefixed |
| exit `2` = declined | exit code | install.sh `2` = bad arguments, `1` = declined | `install.sh:98-99,1304` | Inconsistent — inverted (F1) |
| cc-isolated exit `3`, `4` | exit code | cc-isolated's former `exec` pass-through of claude's status | `git show main:devcontainer-config/cc-isolated.sh` (`exec devcontainer exec … claude`) | New codes layered on a pass-through (F3) |
| `GIT_EXIT_SCAN_MAX_FILE_BYTES`, `…_TOTAL_BYTES`, `GIT_EXIT_SCAN_KEYS_RE` | internal constants | `SCAN_KEYS_RE` (awk env) | `cc-isolated.sh:626,710-711` | Internal (not env-overridable; assigned unconditionally). Not a public surface |

## Findings

#### F1. cc-push's exit 2 means "declined"; install.sh's exit 2 means "bad arguments" and declined is 1

**Severity:** Inconsistent
**Location:** `devcontainer-config/cc-push.sh:20-22`, `:178`, `:284`
**Move:** 4 (error consistency), 2 (naming against the grain, for codes)
**Confidence:** High

Precedent: `Exit status: 0 no target declined; 1 a target was declined, or an error; 2 bad arguments.` used in `devcontainer-config/install.sh:98-99` (and `:1304` `exit 2` on an unknown argument)

Evidence:
```bash
# Exit codes: 0 pushed (or nothing to push); 1 error: bad usage, a checkout cc-push
# refuses (below), a failed fetch, or a push the remote rejected (git's own exit
# status is never passed through); 2 declined at the prompt.
...
      -*) usage >&2; die "unknown flag: $1" ;;
...
      *) echo "Not pushed."; exit 2 ;;
```
The two prompting host scripts in the same directory, both with `--yes`, assign opposite meanings to the same code. For install.sh, 2 is a usage error and "declined" is folded into 1. For cc-push, usage errors are 1 and "declined" is 2. A user or wrapper that learned install.sh's contract will read `cc-push`'s 2 as a typo'd flag. cc-push is new, so aligning now breaks no consumer. cc-isolated's "usage = 1" sides with cc-push on usage, so there is no clean majority. Either way, the convention should be chosen deliberately.

**Recommendation:** Pick one contract for the host tools and record it in `docs/decisions/log.md`. The least churn: keep cc-push (0/1/2 with 2 = declined, a useful distinct signal) and change install.sh to "1 error, 2 bad arguments, 3 declined". Or, cheaper for this branch: give cc-push 3 = declined and 2 = bad usage, to match install.sh. Update the guide's "Exit codes" line in step.

#### F2. `cc-isolated --help` does not show the new exit codes 3 and 4

**Severity:** Inconsistent
**Location:** `devcontainer-config/cc-isolated.sh:1296-1302` (`usage`, whole function)
**Move:** 3 (consumer contract / documentation drift)
**Confidence:** High

Evidence:
```bash
usage() {
  # Line range: the header block above, down to the last line of the "WHY THE
  # WORKSPACE IS AN ARGUMENT" paragraph. ...
  sed -n '2,29p' "${BASH_SOURCE[0]}"
}
```
Lines 2–29 contain no exit-code text (`sed -n 2,29p … | grep -ci exit` → 0). The 3 and 4 contract appears only in the exit-scan comment block (`:596-600`), in `main`'s case arms (`:1467-1471`) and in the guide. install.sh's `--help` ends in "Exit status:", and cc-push's `--help` prints its exit codes (fact-check r2/r3 Claim 6, Verified). So among the three host tools, the one whose exit status now carries security meaning ("3 = the session planted something") is the only one whose `--help` does not say so.

**Recommendation:** Add an "Exit status" paragraph to the header inside the printed range, and move the `sed` bound with it. `test/cc-isolated-functions.bats` already pins the last line. Suggested text: 0/claude's status, 1 launcher error or no baseline, 3 changes found, 4 scan incomplete. Alternatively, switch to cc-push's awk-to-first-non-comment approach so the bound cannot go stale.

#### F3. cc-isolated's exit status is now partly claude's and partly the scan's, and the guide states only half

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:1460-1471` (end of `main`, read to its last line); `guides/cc-isolated-usage.md:53-58`
**Move:** 3 (consumer contract), 6 (versioning impact)
**Confidence:** High

Evidence:
```bash
  devcontainer exec "${dc[@]}" claude || rc=$?
  ...
  case "$scan" in
    0) exit "$rc" ;;
    1) exit 3 ;;   # the session planted something: never a clean exit
    *) exit 4 ;;   # the scan could not read .git
  esac
```
Before this branch, the launcher `exec`'d, so its status was exactly `devcontainer exec … claude`'s. Now: (a) a clean scan passes claude's status through, so a claude or devcontainer status of 3 or 4 is indistinguishable from a scan result; (b) a finding replaces a non-zero claude status; (c) failing to take the baseline at launch exits 1 (`:1392-1401`), the same code as any usage error, while failing the same snapshot at exit is 4. The guide says "exits **3** … It exits 4 …" and never mentions (a) or (c). Fact-check r2 Claim 10 and r3 Claim 11 rated this Mostly Accurate for the same reason. No in-repo caller branches on cc-isolated's status (grep of `scripts/`, `hooks/`, `test/` for a status check on cc-isolated found none outside `test/cc-isolated-functions.bats`), so the drift is documentation, not breakage.

**Recommendation:** Say it in the guide and in `--help` (F2): "0 or claude's own status when the scan is clean; 3/4 override it". Consider exiting 4 rather than 1 when the launch baseline cannot be taken, so "4 = the checkout could not be scanned" holds at both ends.

#### F4. `CC_PUSH_CLONES_DIR` and the XDG data path diverge from the host tools' `CLAUDE_DEVC_*` / `~/.config/claude-devcontainer` convention

**Severity:** Minor
**Location:** `devcontainer-config/cc-push.sh:15-17`, `:194`; `guides/cc-isolated-usage.md:174-176`
**Move:** 2 (naming against the grain)
**Confidence:** Medium

Precedent: host-path overrides named `CLAUDE_DEVC_<WHAT>_DIR` with hard-coded `~/.config/claude-devcontainer` / `~/.local/bin` defaults, used in `devcontainer-config/install.sh:1309-1310` and `devcontainer-config/cc-isolated.sh:50`

Evidence:
```bash
    clone="${CC_PUSH_CLONES_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/cc-isolated/clones}/$name-$id"
```
Three small divergences. (1) The env prefix is `CC_`, which the repo otherwise uses for container- and hook-side values (`CC_CONFIG_DIR`, `CC_EGRESS_DIR`, `CC_WEB_TAINT_DIR`). (2) This is the first `XDG_*`-aware path, while the sibling config dir ignores `XDG_CONFIG_HOME`. (3) The data dir is named `cc-isolated`, while the config dir is `claude-devcontainer`. A user overriding locations must learn two naming schemes, and a user who sets `XDG_CONFIG_HOME` gets clones moved but config not.

**Recommendation:** Name it `CLAUDE_DEVC_CLONES_DIR`. Either drop the XDG lookup (default `~/.local/share/claude-devcontainer/clones`) or make the config dir XDG-aware too, in a separate change. Keep `CC_PUSH_CLONES_DIR` only if the `CC_` prefix is being adopted deliberately for host tools. If so, log that decision.

#### F5. `cc-push A -- B` silently ignores B, while `cc-push A B` is an error

**Severity:** Minor
**Location:** `devcontainer-config/cc-push.sh:170-182` (the argument loop and the line after it, read whole)
**Move:** 7 (asymmetry)
**Confidence:** High

Evidence:
```bash
      --) shift; break ;;
      -*) usage >&2; die "unknown flag: $1" ;;
      *)  [ -z "$start" ] || die "one checkout at a time"; start="$1"; shift ;;
    esac
  done
  [ $# -eq 0 ] || { [ -z "$start" ] && start="$1"; }
```
Probe: `cc-push --clone X a -- b` proceeded on `a` (reached the "no host-only clone" message), while `cc-push --clone X a b` exited 1 with "ERROR: one checkout at a time". After `--`, only the first word is taken, and only when no positional preceded it. Everything else is dropped with no message. The same input shape therefore gets opposite treatment depending on whether `--` is present. (cc-isolated's pre-existing `--)` arm at `:1322` drops every argument after `--`, and its `*)` arm keeps the last positional. That behaviour is not in this diff, but it means neither tool has a coherent `--` story.)

**Recommendation:** After the loop, `[ $# -le 1 ] && [ -z "$start" -o $# -eq 0 ] || die "one checkout at a time"`, i.e. apply the same rule to post-`--` words. Fix cc-isolated's `--` in a follow-up.

#### F6. Ctrl-C at the prompt exits 130, outside the documented and enforced 0/1/2

**Severity:** Minor
**Location:** `devcontainer-config/cc-push.sh:296-306` (main-execution guard, whole), `:280-281`
**Move:** 3 (consumer contract)
**Confidence:** Medium (from fact-check; not re-executed here)

Evidence:
```bash
# Main-execution guard: allow sourcing for tests. main runs in a subshell with
# errexit on, so an unexpected failure still exits 1 rather than git's own status
# (128 and so on): the exit codes stay 0, 1 and 2.
```
Fact-check r3 Claim 1 (Mostly Accurate) found that SIGINT at `Push these? [y/N]` exits 130. Nothing is pushed, which is safe. But the header, `--help` and the guide all promise exactly 0/1/2, and the guard's comment says so too. install.sh has the same prompt shape. Its contract does not claim exhaustiveness.

**Recommendation:** Either `trap 'echo; echo "Not pushed."; exit 2' INT` around the prompt (a decline is what the user meant), or amend the contract to "… 130 interrupted".

#### F7. `--remote` persists configuration as a side effect of a push run

**Severity:** Informational
**Location:** `devcontainer-config/cc-push.sh:12-13`, `:221-224`
**Move:** 9 (idempotency and safety semantics)
**Confidence:** Medium

Evidence:
```bash
    if [ -n "$remote" ]; then
      hgit "$clone" config remote.origin.url "$remote" || die "could not set the remote in $clone"
      say "Remote for $co set to: $remote"
    fi
```
cc-isolated separates persistent state changes into action flags that do only that and exit (`--register`, `--bless`, `:1309-1311`, `:1335`, `:1343-1346`). `cc-push --remote URL` both rewrites the stored remote and goes on to push, and a later bare `cc-push` silently reuses it. The "Remote … set to" line is printed, so this is visible, and the design is defensible: the first run needs both steps. It is still worth being deliberate about, because a mistyped `--remote` on a later run repoints every future push.

**Recommendation:** None required. Optionally print the stored remote on every run (it already appears in the preview: "to origin (<remote>)") and document that `--remote` is sticky in the guide's command reference.

#### F8. Guide command reference lists only one cc-push form

**Severity:** Informational
**Location:** `guides/cc-isolated-usage.md:28-29`
**Move:** 3 (documentation drift)
**Confidence:** High

Evidence:
```
cc-push --remote <url> [REPO]     # push a session's commits via a host-only clone
                                  # (first time; later just `cc-push [REPO]`)
```
The cc-isolated rows list every flag, including `--help`. The cc-push row omits `--branch`, `--clone`, `--yes` and `--help`. They are in the "Pushing: cc-push" section below it (`:179-183`), so nothing is lost. The reference block is just less complete than its neighbours.

**Recommendation:** Add `cc-push --branch NAME [REPO]`, `cc-push --yes [REPO]` and `cc-push --help` rows, or a "(see Pushing: cc-push)" pointer.

## What Looks Good

- `cc-push` follows the host-tool conventions: `-h|--help` to stdout and exit 0, `--yes` with install.sh's meaning, `ERROR:`-prefixed errors on stderr, space-separated option values, and a repo positional that defaults to the checkout containing `$PWD`, as cc-isolated does. [read: `devcontainer-config/cc-push.sh:168-186`, `cc-isolated.sh:1310-1325`, `install.sh:1298-1306`]
- Its help is generated from the header with an awk bound at the first non-comment line (`:73-75`). That removes the stale-line-range hazard cc-isolated has to pin with a bats test. [fact-check: r2 Claim 6 — Verified]
- The exit-code funnel (subshell plus a case mapping anything else to 1) keeps git's own statuses (128 and so on) from leaking, so scripts can rely on the documented codes apart from F6. [fact-check: r1 Claim 4 — Verified]
- install.sh links cc-push exactly as it links cc-isolated. PAYLOAD, `enforcement_files()` and live-verify-gate's enforcement regex all name `cc-push.sh` in step. [fact-check: r3 Claim 12 — Verified]
- The launcher's and cc-push's warnings cross-reference each other by the same guide anchor (`"Pushing: cc-push"`) and give a concrete next command (`cc-push $ws`). [read: `devcontainer-config/cc-isolated.sh:1240-1293`]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Exit 2 = declined in cc-push vs 2 = bad arguments (declined = 1) in install.sh | Inconsistent | `devcontainer-config/cc-push.sh:20-22,284` | High |
| F2 | `cc-isolated --help` omits the new 3/4 exit codes | Inconsistent | `devcontainer-config/cc-isolated.sh:1296-1302` | High |
| F3 | cc-isolated status mixes claude's and the scan's; launch-baseline failure = 1 vs exit-scan failure = 4; guide half-states it | Minor | `devcontainer-config/cc-isolated.sh:1460-1471` | High |
| F4 | `CC_PUSH_CLONES_DIR` / XDG / `cc-isolated` dir name vs `CLAUDE_DEVC_*` / `claude-devcontainer` | Minor | `devcontainer-config/cc-push.sh:194` | Medium |
| F5 | Words after `--` silently dropped; asymmetric with the "one checkout at a time" error | Minor | `devcontainer-config/cc-push.sh:170-182` | High |
| F6 | Ctrl-C at prompt exits 130, outside the promised 0/1/2 | Minor | `devcontainer-config/cc-push.sh:280-306` | Medium |
| F7 | `--remote` is sticky and changes stored config on a push run | Informational | `devcontainer-config/cc-push.sh:221-224` | Medium |
| F8 | Guide command reference lists one cc-push form | Informational | `guides/cc-isolated-usage.md:28-29` | High |

## Overall Assessment

`cc-push` was clearly written against the existing host-tool conventions. Flags, help, `--yes`, error prefixes, the positional default and install linking all match. Its help mechanism is an improvement on cc-isolated's. The real consistency problem is exit codes across the three host tools. The new tool inverts install.sh's meaning of 2 (F1). The launcher now carries security-relevant codes 3 and 4 that its own `--help` never mentions (F2), mixed into a pass-through of claude's status that the guide only half-describes (F3). All of this is fixable in place, and nothing breaks an existing consumer: no in-repo caller branches on these statuses, and cc-push is new. So now, before users script against the codes, is the cheap time to choose one exit-code contract for the host tools and write it down. The naming (F4) and `--` handling (F5) are small cleanups.

## Goal-Alignment Note

- **Success criterion (verbatim):** both reports saved at those paths.
- **Answered:** I compared cc-push's CLI (flags, positional, `--help`, exit codes, `CC_PUSH_CLONES_DIR`/`XDG_DATA_HOME`) against cc-isolated.sh's and install.sh's conventions. I covered the exit-code contracts across cc-isolated (0/3/4 plus claude's status, 1 at launch) and cc-push (0/1/2, plus 130 on Ctrl-C), message formats, and the guide's command reference. The name-pattern audit covers every new public name.
- **Out of scope:** Whether cc-push's refusals and the scan hold against bypass belongs to the fact-check reports (r1 Claims 1 and 9 are Incorrect) and to security-reviewer. Performance is in the sibling report. cc-isolated's pre-existing `--` handling is noted only as context.
- **Escalate:** F1 and F2 need a user decision on the host tools' exit-code convention. It is cheapest to settle before merge, and a `docs/decisions/log.md` row would record it.
