# API Consistency Review: copy-install Q-058, pass 2 (fix commits `c7c4e34..feba07d`)

Commit: feba07d
**Scope:** the 9 fix commits `c7c4e34..feba07d` on `skill-fixtures` (24ce814, 6ec64c3, c700270, ec1e5bd, 477d77f, c460912, f946a8b, 32247d7, feba07d). The surface is install.sh's CLI: its messages, exit codes and `--help`, plus the docs contract (README, `guides/bare-host-hook-wiring.md`, decision 037, the plan). Code was read at feba07d in `/workspace/.claude/wt-q058p2`. The earlier history is context only.
**Date:** 2026-09-25
**Based on:** the pass-1 rubric `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md` and the pass-1 API review `docs/reviews/api-consistency-review-2026-09-24-copy-install-q058.md` (F1–F9). No pass-2 code-fact-check report was supplied.

> ⚠️ **No code fact-check report provided.** API documentation claims have not been independently verified against implementation. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

To make up for that, I ran the claims this review depends on myself. A scratch bats file reused the `install-host.bats` harness (the stubbed pgrep and docker, `run_pty` and `fake_repo`) and ran each case against both the pre-fix `install.sh` (c7c4e34) and the fixed one (feba07d). The probes are in `scratchpad/p2api/test/p.bats` and `q.bats`. Each result cited below comes from one of those runs.

## Baseline Conventions

These are the pass-1 baseline, rechecked at feba07d.

- **Refusal shape.** A refusal prints `ERROR: <what>` to stderr, with continuation lines indented 7 spaces. List items are indented 9 or 11 spaces. It ends with a trailer and exits 1. Examples: `head_commit` (`install.sh:148-154`), `extract_commit` (`:229-232`, `:252-255`), `host_refuse` (`:605-609`) and `agent_gate` (`:1016-1031`).
- **Trailers depend on the phase.** At startup the trailer is `Nothing was staged or installed.` (`:1089`, `:1093`). Shared and devcontainer steps use `Nothing was installed.`. The host target uses `Nothing was installed into the host target.` (`host_refuse`, `:607`), and its copy and swap errors use `nothing was replaced.` (`:751`, `:887`). `agent_gate` takes its trailer as an argument (`<what is refused>`, `:980-983`), so each call site names its own phase.
- **Advisories and progress lines** go to stdout, unprefixed or with `WARNING:`/`NOTE:`. The progress-line style is `<Verb>ing …...`, as in `init-firewall.sh:474` ("Fetching GitHub IP ranges...") and `:1272`.
- **Exit status** (`--help`, `:76-77`): `0 no target declined; 1 a target was declined, or an error; 2 bad arguments.`
- **`--help` lists the refusal conditions** a user can hit: a destination holding a control character, a payload file holding a NUL byte, the Q-058 gate, and a missing pgrep or perl (`:48-71`).
- **Internal helpers** are snake_case. Hashing helpers take the path as two arguments, `<dir> <prefix>`, and join them as `$dir/$pfx$name` (`tree_hash :576`, `payload_hash :590`). Regex constants are UPPER_SNAKE with a `_RE` suffix (`CLAUDE_PROC_RE :978`; `HOST_RE` and `ZONE_RE` in `init-firewall.sh`). Globals shared with the EXIT trap are named `HOST_*` or `DC_*` (`:1095`).
- **The docs contract is stated in three places:** `--help`, README `:25-45`, and decision 037 (the Sub-decisions and the "Trust model"). The guide and the plan's Risks restate parts of it. T56 and T63 pin some of the wording.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `vis_or_die` | function | `vis`, `host_refuse`, `die` | `devcontainer-config/install.sh:124,605`; `scripts/questions.sh:76` | Consistent. It is snake_case, and the `die` idiom already appears in the repo's shell scripts. The `_or_die` suffix is new in install.sh, but its meaning is plain |
| `git_state_gate` | function | `agent_gate` | `devcontainer-config/install.sh:982` | Consistent name. The signature is not: `agent_gate` takes the trailer and `git_state_gate` hard-codes one (F5) |
| `GIT_EXEC_KEYS_RE` | constant | `CLAUDE_PROC_RE`, `HOST_RE`, `ZONE_RE` | `devcontainer-config/install.sh:978`; `devcontainer-config/init-firewall.sh:135,151` | Consistent: UPPER_SNAKE with `_RE` |
| `tree_hash` | function | `payload_hash` | `devcontainer-config/install.sh:590` | Consistent: a noun_hash name with the same `<dir> <prefix>` argument order |
| `review_diff`/`mode_diff` 2nd argument `<src-prefix>` | parameter (changed) | `tree_hash <dir> <prefix>`, `payload_hash <dir> <prefix> <manifest>` | `devcontainer-config/install.sh:576-597` | Inconsistent in convention: one pre-joined prefix instead of the `<dir> <prefix>` pair. Internal only (F7) |
| `HOST_NEW_IN`, `HOST_MADE_DEST` | globals | `HOST_TMP`, `HOST_LOCK`, `DC_TMP` | `devcontainer-config/install.sh:1095` | Consistent `HOST_` prefix, and each is cleared in `main` |
| "the copies to install changed after review" / "the staged devcontainer config changed after review" | refusal message | the old "stage changed after review" | `c7c4e34:devcontainer-config/install.sh` (host post-y check) | Consistent. Both targets now use the same `<what> changed after review … Rerun install.sh.` shape |
| `ERROR: could not show output safely (vis exit N), so install.sh stopped. Nothing was installed.` | refusal message | `ERROR: could not show the review of payload item '…' (vis exit N).` | `devcontainer-config/install.sh:349-350` | Consistent: the same `(vis exit N)` form and the ERROR-then-trailer shape. The trailer does not depend on the target (F5) |
| `ERROR: the checkout's git state can make git run a command …` | refusal message | the `extract_commit` symlink/NUL refusals | `devcontainer-config/install.sh:252-255,270-274` | Consistent: ERROR, a 9-space list, a remedy, then `Nothing was installed.` The remedy text is partly wrong (F2) |
| `Checking for running cc-isolated containers (docker ps; up to 20 s)...` | progress line | `Fetching GitHub IP ranges...`, `Verifying firewall rules...` | `devcontainer-config/init-firewall.sh:474,1272` | Consistent: stdout, `<Verb>ing …...`. The docs don't count it (F4) |
| `stub_pgrep_table`, `plant_marker_cmd` | test helpers | `stub_pgrep`, `stub_docker`, `commit_all`, `fake_repo` | `test/install-host.bats:45-53,91,117` | Consistent |
| `T65`–`T74` | test IDs | `T1`–`T64` | `test/install-host.bats` | Consistent. They are out of numeric order in the file, but the file was already out of order |

One audit row is inconsistent (the parameter convention, F7), and F7 carries a Precedent line. Every other name matches its neighbours.

## Findings

#### F1. Decision 037 says "two or three" NOTE lines per run, but its own "four moments" gives up to four

**Severity:** Minor
**Location:** `docs/decisions/037-bare-host-copy-install.md:74` (compare `:72`)
**Move:** 3 (documentation drift)
**Confidence:** High (executed)
**Legibility-target:** a decision 037 reader, and a user who counts or greps the NOTE lines

Evidence:
```
037:72  It checks at four moments: at startup, before either target stages anything; again at the
        start of the host target, before it stages (review A2); and after each y, …
037:74  If docker is missing or unreachable, a NOTE line says so at each check (two or three per run)
        and no container is assumed.
install.sh:677  agent_gate "Nothing was installed into the host target."   (new in ec1e5bd)
```
Commit c460912 fixed A5's "one line" and wrote "two or three per run". Commit ec1e5bd added the fourth check (`:677`) and updated the "four moments" sentence two lines above, but not this count. I ran an interactive `y`/`y` run with docker removed from PATH: pre-fix code, `NOTE=3`; feba07d, `NOTE=4`. A `--yes` run prints 2. `--help` (`:59-60`, "a NOTE line at each check") has no number and is correct. Only 037 is wrong. This is the one place where A5's fix introduced new drift.

**Recommendation:** Change "(two or three per run)" to "(two to four per run)", or just drop the count, as `--help` does.

#### F2. Refusing the checkout's git state is a new whole-run refusal that `--help` and README don't mention, and its remedy fails for two of the entries it names

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:202-209` (the message), `:291` (called from `assemble`, so target 1 runs it first); `--help :45-71`; `README.md:25-45`
**Move:** 3 (consumer contract: a new refusal condition) and 4 (a helpful error message)
**Confidence:** High (the remedy was executed with git 2.39.5)
**Legibility-target:** a user with local git config (for example `git lfs install --local`) who hits the refusal, and a `--help` reader

Evidence:
```
install.sh:203  echo "ERROR: the checkout's git state can make git run a command as you during this"
install.sh:207  echo "       these. Check each one, remove it (git config --local --unset <key>, or"
install.sh:208  echo "       empty the attributes file) and rerun. Nothing was installed."
install.sh:174  for f in config config.worktree; do          # entries from both files are listed
--help :48-49   A destination path holding a newline or other control character is refused,
                and so is a payload file holding a NUL byte (a binary the diff cannot show).
24ce814 Notes:  A user who ran `git lfs install --local` in the checkout would now be refused
                until they remove the local filter.lfs keys
```
- **Where it shows up in the docs.** `--help` lists the other content-based refusals, but not this one. README doesn't mention it either. The only user-facing description is 037's Residuals list (`:79`).
- **Its reach.** It runs in `assemble`, which target 1 always calls, so it refuses the whole run. The devcontainer target, which worked before for a git-lfs `--local` user, is refused too.
- **The remedy text fails in two cases** I ran:
  - An entry in `config.worktree` (listed by `:174`): `git config --local --unset core.fsmonitor` exits 5, because `--local` targets `.git/config` only. The command needed is `--worktree --unset`.
  - A multi-valued `include.path`: `--unset` exits 5 with "has multiple values". The command needed is `--unset-all`.
- **Missing warning.** For `filter.lfs.*`, following the remedy silently breaks LFS checkout in that clone, and the message doesn't say so.

The refusal is correct as security (R1). The gap is in the contract and the recovery text.

**Recommendation:**
1. Add one sentence to `--help` after the NUL-byte sentence, and a clause to README: "A checkout whose local git config sets a `filter.*`, `core.fsmonitor` or `include*` key, or whose `info/attributes` is non-empty, is refused (it would make git run a command)."
2. Change the remedy to "`git config --file <the file named above> --unset-all <key>`". This works for both files and for multi-valued keys.

#### F3. An unwritable destination now fails before the review, even when nothing would change: "Nothing to install" (exit 0) becomes ERROR (exit 1)

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:722-753` (the lock and copies now come before the review), `:845-849` (the "nothing to install" path is now after them)
**Move:** 3 (a subtle breaking change in exit status and behaviour) and 7 (asymmetry: a check that needs write access now runs before a read-only step)
**Confidence:** High (executed on both versions)
**Legibility-target:** a user or wrapper that runs install.sh against a destination it cannot write, and a `--help` reader relying on the exit-status line

Evidence:
```
install.sh:732   ok=0   # unwritable destination: reported by the copy step below
install.sh:751   echo "ERROR: could not copy the new files into $dest; nothing was replaced." >&2
install.sh:845   if [ "$changed" -eq 0 ]; then  … echo "Nothing to install into $dest." … return 0
--help :76       Exit status: 0 no target declined; 1 a target was declined, or an error;
```
Probe P1: install, `chmod a-w "$CLAUDE_HOME_DIR"`, then run again with no repo change.
- c7c4e34 printed `Nothing to install into …/home/.claude.`
- feba07d printed `ERROR: could not copy the new files into …/home/.claude; nothing was replaced.`

With target 1 accepted, that is exit 0 before the fix and exit 1 after it. The fix agent flagged the earlier report as a behaviour change, and it holds in three ways:
- **The review is gone.** The user no longer gets to see it for an unwritable destination.
- **An up-to-date read-only destination is now an error.** No step needs to write to it.
- **The trailer is out of place.** It says "nothing was replaced" before any question was asked.

Real reach is low, since Claude Code itself writes to `~/.claude`. None of `--help`, README or 037 mention it. 037's host paragraph says the lock and copies come first but not that write access is now a precondition of seeing the review.

**Recommendation:** Pick one of two:
- Keep the order, and say it in 037's host paragraph and the plan: "an unwritable destination is refused before the review, even when nothing would change."
- Or, when the copy step fails, fall back to reviewing the stage read-only, and refuse only at the y.

The first is enough for merge. If you touch the message, use the host trailer (`Nothing was installed into the host target.`), since the error now fires before any prompt.

#### F4. The new progress line adds 2 lines to every scripted `--yes` run on a host with docker, and the "two extra lines" claims don't count them

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1004`; `docs/decisions/037-bare-host-copy-install.md:33`; `docs/working/plan-copy-install-bare-host.md:252`
**Move:** 3 (documentation drift: a changed output contract)
**Confidence:** High (executed)
**Legibility-target:** the author of a script that runs `install.sh --yes`, and a decision 037 reader

Evidence:
```
install.sh:1004  echo "Checking for running cc-isolated containers (docker ps; up to 20 s)..."
037:33  … every existing non-interactive devcontainer run is unchanged apart from two extra lines
        (a blank line and the skip line). *Superseded in part by the Trust model (Q-058) …*
        A host without a reachable docker also prints a NOTE line at each check.
plan:252 The host target adds two lines to non-interactive runs (a blank line and the skip line); …
f946a8b Notes: the progress line adds one stdout line per gate call on hosts with docker
        (up to four per interactive run).
```
Probe Q (stub docker present): the `--yes` run printed the progress line twice (startup, and the gate after target 1's implicit y), and an interactive `y`/`y` run printed it 4 times. The commit Notes say this, and the user-facing prose doesn't. 037's superseded-in-part note lists what now changes for non-interactive runs (the exit 1 in-session, and the NOTE lines without docker) but leaves out the progress lines that a host *with* docker prints. The line itself follows the `<Verb>ing …...` precedent and is a good addition (it answers C1).

**Recommendation:** Add a sentence to 037:33: "A host with docker prints a 'Checking for running cc-isolated containers…' line at each check instead." Add the same clause to plan:252.

#### F5. The new errors' trailers ignore which target the run is in: after target 1 is installed and blessed, a host-target failure still says "Nothing was installed."

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:142` (`vis_or_die`), `:208` (`git_state_gate`), called from the host target at `:708` (`assemble`) and `:767-821`; compare `agent_gate`'s parameter (`:980-983`, `:677`, `:864`)
**Move:** 4 (error consistency)
**Confidence:** High
**Legibility-target:** the user at the terminal after a two-target run

Evidence:
```
install.sh:142  echo "ERROR: could not show output safely (vis exit $rc), so install.sh stopped. Nothing was installed." >&2
install.sh:208  echo "       empty the attributes file) and rerun. Nothing was installed."
install.sh:980  # agent_gate <what is refused>: …
install.sh:864  agent_gate "Nothing was installed into the host target."
install.sh:607  echo "       Nothing was installed into the host target." >&2   (host_refuse)
```
`vis_or_die` now covers the host REPLACE, MOVE and ADD lines (`:767`, `:773`, `:792`, `:813-821`). `git_state_gate` runs again in the host target's `assemble` (`:708`). Both run after target 1 may already have installed and blessed. They still print a flat "Nothing was installed.", while `agent_gate`, their sibling `_gate` function, takes the phase trailer as an argument for exactly this reason. This follows existing precedent: `head_commit` (`:151`), `extract_commit` (`:231`, `:254`, `:273`) and `review_diff` (`:350`) had the same blind spot before this diff. So it isn't a new inconsistency. It is C7 widened to the new sites.

**Recommendation:** No action needed for merge. If C7's trailer cleanup happens, give `vis_or_die` and `git_state_gate` an optional trailer argument in the same form as `agent_gate`'s (or read a `PHASE_TRAILER` global that each target sets).

#### F6. Declining a first install into a new nested destination leaves the parent directories that `mkdir -p` made, yet reports "Nothing was changed."

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:723-724`, `:625`, `:856-861`
**Move:** 9 (safety semantics of a decline) and 3 (undocumented)
**Confidence:** High (executed)
**Legibility-target:** a user who sets `CLAUDE_HOME_DIR` to a new path

Evidence:
```
install.sh:723  [ -d "$dest" ] || HOST_MADE_DEST="$dest"   # removed again if left empty
install.sh:724  mkdir -p "$dest" 2>/dev/null || ok=0
install.sh:858  echo "Aborted. Nothing was changed. (host ~/.claude)"
```
Probe P3 used `CLAUDE_HOME_DIR=$HOME/a/b/c` and answered n to both targets.
- c7c4e34 left no `$HOME/a`.
- feba07d left `$HOME/a/b/` behind. The EXIT trap removed `c`.

The 6ec64c3 Notes record this. The default `~/.claude` has an existing parent, so the default path is unaffected.

**Recommendation:** Record it in 037's host paragraph ("a declined first install into a new nested path leaves its parent directories"), or record the directories `mkdir -p` created and `rmdir` them in reverse in `host_cleanup`.

#### F7. `review_diff`/`mode_diff` now take one pre-joined `<src-prefix>`, while the new `tree_hash` in the same diff takes `<dir> <prefix>`

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:323-329`, `:364-369`; callers `:457-458`, `:817`, `:835`, `:837`
**Move:** 2 (naming and argument convention)
**Confidence:** High
**Legibility-target:** the next maintainer who calls `review_diff`

Precedent: separate `<dir> <prefix>` arguments joined as `$dir/$pfx$name` used in `devcontainer-config/install.sh:576-583` (`tree_hash`) and `:590-597` (`payload_hash`)

Evidence:
```
install.sh:323  # review_diff <dest> <src-prefix> <item...>: … (<src-prefix> is "<stage>/" or, on the host target, "<dest>/.cw-new.")
install.sh:346  diff -ruNa "$dest/$item" "$src$item" 2>&1 | vis …
install.sh:576  # tree_hash <dir> <prefix> <name...>
```
All five callers pass a correct prefix. But a caller that passes `"$stage"` without its trailing slash (the old calling convention) gets no error. `diff -N` treats the missing `"$stage$item"` as empty and shows the whole item as deleted. That is a misleading review rather than a refusal. The two helpers added and changed in this diff took different shapes for the same "dir plus prefix" idea. Internal only, so the severity is Informational. By the skill's rules a precedent-backed Inconsistent would be Minor; I lowered it one tier because no external caller exists.

**Recommendation:** Optional. Give `review_diff`/`mode_diff` the `tree_hash` shape (`<dest> <src-dir> <src-prefix> <item...>`), or add a one-line guard: `case "$src" in */|*.) ;; *) echo "BUG: review_diff src-prefix must end in / or ." >&2; exit 1 ;; esac`.

#### F8. Two stale restatements next to text that was updated

**Severity:** Informational
**Location:** `docs/working/plan-copy-install-bare-host.md:139`; `docs/decisions/037-bare-host-copy-install.md:91` (Revisit triggers)
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** a plan or decision 037 reader

Evidence:
```
plan:139  - **R4:** `<dest>/.claude-workflows-lock` (checked before the review, taken after y, released by the EXIT trap); …
plan:137  … The lock is now taken and the stage copied into `$dest/.cw-new.*` *before* the review. …
037:91    `if Claude Code's process shape changes (argv0 no longer claude or .../claude, and not the npm package path) … update CLAUDE_PROC_RE …`
```
- **The plan's lock timing.** The R2 line got a "Superseded 2026-09-25" note, but the R4 line two lines below still says the lock is "taken after y". The code takes it before the review (`install.sh:726`).
- **037's revisit trigger.** It still describes the probe's shapes as before A2. It doesn't mention `/claude/versions/` or `/claude-agent-sdk/`, which 037:73 now lists.

**Recommendation:** Add "(taken before the review since 2026-09-25, R2)" to plan:139. Change the trigger to "…and none of the package paths CLAUDE_PROC_RE lists".

#### F9. When the A1 check fails after the copy, the message doesn't say that the previously installed config is gone too

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:495-509`; `docs/decisions/037-bare-host-copy-install.md:68`
**Move:** 7 (asymmetry with the host target's rollback) and 4 (a clear message)
**Confidence:** High (code reading, whole function)
**Legibility-target:** the user at the terminal after that rare failure

Evidence:
```
install.sh:496  rm -rf "${DEST:?}/$item"
install.sh:497  cp -Rp "$stage/$item" "$DEST/$item"
install.sh:503  for item in "${PAYLOAD[@]}"; do rm -rf "${DEST:?}/$item"; done
install.sh:505  echo "       showed (the stage changed after review, during the copy). The copied items" >&2
install.sh:506  echo "       were removed again and nothing was blessed, so cc-isolated will not run" >&2
```
The copy loop deletes each previously installed item before copying. A mismatch then removes the new copies. So `$DEST` is left with no payload at all, not with the old config. "The copied items were removed again" reads as though the previous config survives. The host target handles the same kind of failure with `host_rollback`, which restores what was there. The fail-closed choice is deliberate (c700270 Notes), and the "cc-isolated will not run" clause does state the consequence.

**Recommendation:** Change the message to "The previous config and the copies were removed, and nothing was blessed …". Use the same wording in 037:68.

## What Looks Good

- **A4 is fixed in all three places, and a test pins it.** `--help` (`:61-67`), README (`:31-34`) and 037:33 all say an in-session run "exits 1 at startup, before either target". Each says the `CLAUDECODE` skip is a backstop. T56 now greps both `--help` and README for that wording.
- **A5 is fixed apart from the count in F1.** Each place now says "a NOTE line at each check" (`--help`), and README, the guide and 037 give the same four-moment timing. Each says "samples, not a lock" and says to stop leftover helpers. `DOCKER_HOST`/`DOCKER_CONTEXT` are documented in `--help` and 037 (pass-1 F6). 037:64 now names the mapped uid or root. plan:244's pattern wording matches the code comment (pass-1 F5).
- **The refusal wording is the same on both targets.** "the copies to install changed after review … Rerun install.sh." and "the staged devcontainer config changed after review … Rerun install.sh." share one shape. Each keeps its target's trailer ("Nothing was replaced." for host copies, "Nothing was installed." for the devcontainer). The tests match on the common `changed after review`.
- **`vis_or_die` reuses `review_diff`'s wording** (`(vis exit N)`, ERROR to stderr, exit 1). It is applied at every `| vis` site that pass-1 F2 listed, and a comment explains why `mode_diff` and `review_diff` keep plain `vis`. C3 is closed and T74 pins it.
- **The new refusal reads like its neighbours.** `git_state_gate`'s message has the same shape as `extract_commit`'s: ERROR, a 9-space indented list naming each entry and its file, a remedy, then the trailer. All of it goes through `vis_or_die`, as untrusted text should.
- **Exit codes are unchanged.** Every new refusal exits 1, which the "or an error" contract covers. No new code was introduced. Existing grep targets (`Aborted.`, `Skipped host target`, `Nothing to install`) are unchanged.
- **The internal signature change was carried through everywhere.** All five `review_diff`/`mode_diff` callers were updated in the same commit. No other file calls them; I grepped outside `docs/reviews/`.
- **The progress line** follows the `<Verb>ing …...` style of `init-firewall.sh` and goes to stdout, so it doesn't mix with refusals on stderr.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | 037 says "two or three" NOTE lines per run; four checks give up to 4 (executed: 3 → 4) | Minor | `037:74` | High |
| F2 | git-state refusal missing from `--help`/README; refuses both targets; its remedy fails for `config.worktree` and multi-valued `include.path` | Minor | `install.sh:202-209,291`; `--help`; README | High |
| F3 | Unwritable destination fails before the review, even when up to date: "Nothing to install" exit 0 → ERROR exit 1 (executed) | Minor | `install.sh:722-753,845` | High |
| F4 | Progress line adds 2 lines to `--yes` runs (4 interactive); 037:33 and plan:252 don't count it | Minor | `install.sh:1004`; `037:33`; `plan:252` | High |
| F5 | `vis_or_die`/`git_state_gate` trailer ignores the target; `agent_gate` takes one as an argument | Informational | `install.sh:142,208` | High |
| F6 | A declined first install leaves the parent dirs `mkdir -p` made; "Nothing was changed." (executed) | Informational | `install.sh:723-724,858` | High |
| F7 | `<src-prefix>` convention vs `tree_hash`'s `<dir> <prefix>`; a missing slash gives a misleading review | Informational | `install.sh:323-383` | High |
| F8 | plan:139 lock "taken after y" and 037's revisit trigger predate the fixes | Informational | `plan:139`; `037:91` | High |
| F9 | A1 post-copy failure message hides that the previous config is gone too | Informational | `install.sh:503-507`; `037:68` | High |

## Overall Assessment

The fix commits keep install.sh's CLI conventions. The new functions, constant, globals, test helpers and messages all match their neighbours. Both targets' "changed after review" refusals share one shape, and the exit-status contract is unchanged. **A4 is fully fixed and a test pins it. A5 is fixed in every doc, but a count in 037 went stale: F1, the one new drift, a one-word fix.** Of the behaviour changes the fix agent flagged:
- The git-lfs/local-filter refusal (F2) and the unwritable destination reported before the review (F3) are real contract changes that `--help`, README and 037 don't state. F3 also turns an up-to-date read-only destination from exit 0 into exit 1.
- The extra progress lines are documented in the commit Notes but not in the "two extra lines" claims (F4).
- The first-install decline residue is minor and undocumented (F6).
- The new internal `review_diff`/`mode_diff` argument is carried through correctly. Its shape differs from `tree_hash`'s, but that is only a maintainability note (F7).

Everything is fixable in place with text edits. Nothing here fails open, and nothing blocks merging from the API-consistency lens. F1–F4 are worth fixing before merge, because they are what a user reading `--help` or 037 would get wrong.

## Goal-Alignment Note
- Success criterion (restated): "a markdown report saved to /workspace/docs/reviews/api-consistency-review-2026-09-25-copy-install-q058-pass2.md, per the skill."
- **What this report answers:** an API-consistency review of `c7c4e34..feba07d`, with every finding carrying Severity, Location, verbatim Evidence, Confidence and Legibility-target.
  - Name-pattern audit: 12 rows, one inconsistent (F7).
  - Findings: 9 in total, none Breaking or Inconsistent: 4 Minor (F1–F4) and 5 Informational (F5–F9).
  - Focus 1: A4 is fixed in every doc. A5 is fixed except 037:74 (F1). The new messages match R1's refusal shape, A1's mismatch message, "the copies to install changed after review" and `vis_or_die`'s ERROR, except for the trailer that ignores the target (F5).
  - Focus 2: the unwritable-destination change is F3, the decline residue F6, the progress lines F4, the internal argument F7 and the local-`filter.*` refusal F2. Only 037 documents any of them, and then only partly.
  - Focus 3: the audit table.
- **Out of scope:**
  - Whether the git-state key list, the gate and the hash checks are enough as security controls. That belongs to the security critic.
  - Test adequacy beyond names.
  - Performance, such as ~2.4 MB of copies written into `~/.claude` on every interactive run, including runs with nothing to change.
  - The earlier history, which is context only.
- **Escalate:**
  - F3 changes the exit status for one input: an up-to-date, read-only destination goes from 0 to 1. It is low-reach, but the author should decide whether to accept and document it or restore the "review first" order for that case.
  - F2's remedy text is wrong for two of the entries the refusal itself names. A user who follows it gets a git error.
  - No pass-2 fact-check was supplied. I ran the probes the findings depend on myself (P1–P3 and Q, on both versions), but the docs' other claims were not checked independently.
