Commit: 05b13d11

# API Consistency Review — feat/q106-host-settings-merge

**Scope:** branch diff `git diff 184396ea..HEAD` (9 files), self-read. Read in full: the whole `install_claude_home` (`devcontainer-config/install.sh:774-1171`), `usage`, `main`, and the linker's wiring block (`devcontainer-config/link-claude-home.sh:84-127`).
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 188f5c3c; HEAD 05b13d11 adds only a decision-doc edit), plus probes PROBE1-3 run for this review

**Probes.** These use a throwaway copy of `test/install-host.bats` with three appended `PROBE` tests, run by `/home/node/.claude/jobs/00bcf178/tmp/q106/apiperf/run.sh` (2026-10-15T11:37:10Z, HEAD 05b13d11, `timeout 600`, exit 0, 3/3 ok). The copy drives this worktree's `install.sh` under bats' own temp HOME. Logs are in `/home/node/.claude/jobs/00bcf178/tmp/q106/apiperf/logs/` (`probe1-output.txt`, `probe2-backups.txt`, `probe3-commands.txt`).

## Baseline Conventions

The consumer-facing surface here is a CLI's output and docs, not an HTTP API. These conventions were observed in the existing code:

- **`install.sh` errors** go to stderr and use `ERROR: <what happened>.`. Continuation lines are indented 7 spaces, and the last one states the end state plus what to do: "Nothing was installed." / "Nothing was replaced. Rerun install.sh." (`install.sh:171`, `:285`, `:977`, `:1055-1056`, `:1086`). Host-target refusals go through `host_refuse`: "Nothing was installed into the host target." (`:729-733`). An install that fails part-way names where things are and how to restore them (`host_rollback`, `:762-770`).
- **Non-fatal conditions** carry a severity prefix: `WARNING:` (`:352`, `:624`, `:928`) or `NOTE:` (`:1307`, `:1318`). A trailing `REMINDER:` block follows the install (`:1165-1170`, pre-existing).
- **Review markers** are an uppercase verb plus a path: `ADD`, `REPLACE symlink`, `MOVE`, `MODE` (`:915`, `:932-934`, `:963`, `:425`), plus parenthesised notes such as `(diff: …)` and `(none — …)`.
- **Outcome lines:** `Aborted. Nothing was changed. (<target>)` on a decline (`:557`, `:1045`), `Installed into $dest.` (`:1119`), and `Previous entries moved to $backup (delete it when satisfied).` (`:1138`).
- **Exit codes** (help, `:102-103`): 0 = no target declined; 1 = declined or error; 2 = bad arguments. A skip is not a decline.
- **`link-claude-home.sh` messages** are prefixed `link-claude-home:`. Each missing precondition prints `… — hooks linked but not wired.` to stderr (`:97-103`).
- **Names:** shell constants are UPPERCASE nouns (`WIRING`, `SETTINGS`), hash helpers are `<noun>_hash` (`tree_hash`, `payload_hash`), staging copies are `.cw-new.<name>`, shared hook code lives in `hooks/lib/` with kebab-case file names, and test titles end with the question ID (`(Q-062)`).
- **Docs:** a superseded decision line gets an italic *Superseded <date>* marker pointing at a dated Amendment (`037:37`). The "last 3 installs are kept" retention rule is stated in the README (`:61-63`), the help (`:43-44`) and decision 037 (`:35`).

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `hooks/lib/wiring-merge.jq` | payload file | `hooks/lib/usage-common.sh`, `hooks/wiring.json`, `test/skills/transcript.jq` | `hooks/lib/*`, `hooks/wiring.json` | Consistent: shared code in `hooks/lib/`, kebab-case, named for the `wiring.json` it consumes |
| `file_hash` | shell function | `tree_hash`, `payload_hash` | `devcontainer-config/install.sh:671,704` | Consistent: `<noun>_hash`, same stdout-hash contract |
| `MERGE` | shell constant (linker) | `WIRING`, `SETTINGS`, `SRC` | `devcontainer-config/link-claude-home.sh:91-93` | Consistent |
| `.cw-new.settings.json` | staging path | `.cw-new.<entry>`, `.cw-new.manifest` | `devcontainer-config/install.sh:719-727,872-885` | Consistent; it is also added to the planted-link refusal and to `rm_new_copies` |
| `<backup>/settings.json` | backup path | `<backup>/<entry>` for the seven entries | `devcontainer-config/install.sh:1091-1095` | Consistent |
| `settings.json: the hooks/wiring.json merge this install applies (…)` | review heading | `ADD <path> (new, N file(s)):`, `(diff: …)`, `REPLACE symlink …` | `devcontainer-config/install.sh:963,986,915` | Minor: a new `<file>:` heading shape; readable, and the diff labels carry the path |
| `settings.json: NOT merged: <path>: <why>.` | non-fatal status line | `WARNING: not in the repo; …`, `NOTE: docker not found: …` | `devcontainer-config/install.sh:928,1307,1318` | Inconsistent: a warning-class line without the `WARNING:`/`NOTE:` prefix (Finding 7) |
| `Merged hooks/wiring.json into <path> (the previous file is in <backup>).` | outcome line | `Installed into $dest.`, `Previous entries moved to $backup (…)`, `link-claude-home: wired N hook command(s) … into $SETTINGS` | `devcontainer-config/install.sh:1119,1138`; `link-claude-home.sh:118` | Consistent (past-tense verb + `into`) |
| `ERROR: $settings, or its merged copy, changed after review.` / `Nothing was replaced. Rerun install.sh to review the merge again.` | error | `ERROR: the copies to install changed after review: …` / `Nothing was replaced. Rerun install.sh.` | `devcontainer-config/install.sh:1055-1056` | Consistent |
| `ERROR: could not back up $settings; it was not changed. Rerun install.sh.` | error | `could not create $backup; nothing was replaced.`, `host_rollback`'s INCOMPLETE message | `devcontainer-config/install.sh:1086,767-769` | Inconsistent in content, not in wording (Finding 4) |
| `link-claude-home: no $MERGE — hooks linked but not wired.` | linker skip message | `no $WIRING — …`, `jq not found — …` | `devcontainer-config/link-claude-home.sh:97-103` | Consistent |
| `T93`-`T98 … (Q-106)` | test titles | `T90 … (Q-062)`, `T92 … (Q-064 [2])` | `test/install-host.bats:1571-1602` | Consistent |

## Findings

#### 1. A settings-only run counts as one of "the last 3 installs", so three settings fixes prune the only backup of the replaced entries

**Severity:** Inconsistent
**Location:** `devcontainer-config/install.sh:1080`, `devcontainer-config/install.sh:1137-1163`; contract stated at `README.md:61-63`, `devcontainer-config/install.sh:43-44`, `docs/decisions/037-bare-host-copy-install.md:35`
**Move:** 3. Trace the consumer contract (subtle breaking change)
**Confidence:** High (execution-verified, PROBE2)
**Legibility-target:** for-author
**Evidence:**
> `  if [ -n "$s_new_hash" ] && [ -e "$settings" ]; then any=1; fi`
> `  if [ -n "$backup" ]; then`
> `    printf 'installed_epoch=%s\n' "$(date -u +%s)" > "$backup/.install-stamp"`
> README: `` `~/.claude/.claude-workflows-backup/<UTC stamp>/`. The backups of the last 3 ``

Before this branch, every stamped backup held the seven replaced entries, so "the backups of the last 3 installs are kept" meant three restorable states. A settings-only drift fix now creates a stamped backup holding only `settings.json`, and the rotation counts it like any other. PROBE2 ran one full install and then three settings-only fixes. The surviving backups were `20261015T113716Z/`, `…718Z/` and `…720Z/`, each holding only `.install-stamp settings.json`, and the full install's backup with the old entries was gone (`logs/probe2-backups.txt`). A user who reads the README expects the entries from their last real install to survive three more runs. The fact-check flagged the same scope gap (Claim 8: "still counts a settings-only backup as one of the three kept").

**Recommendation:** Make the rotation count only backups that hold entries, for example by writing a distinct stamp key for settings-only backups and excluding those from the keep-3 count. Otherwise, state the new rule in the README, the help and decision 037: "settings-only runs count as installs".

#### 2. The guide's rule for reading the review ("a `-` line on a hook command means the install unwires it") contradicts the review's own output

**Severity:** Inconsistent
**Location:** `guides/bare-host-hook-wiring.md:52-53`
**Move:** 3. Trace the consumer contract (documentation drift)
**Confidence:** High (fact-check Claim 27, Incorrect, execution-verified)
**Legibility-target:** for-author
**Evidence:**
> ``legacy single-slash form dropped (Q-049); everything else is kept. A `-` line on a``
> ``hook command means the install unwires it. The old file goes to``

The merge is `(existing − ours) + ours`, so our group moves to the end of the event array, and `diff -u` shows `-` lines for commands that stay wired. In T93's own fixture, the review shows `-` on `bash /opt/mine.sh` and on our `h.sh`, and both are wired afterwards (fact-check Claim 27, `p4-review-output.txt`). This sentence is the guide's only instruction for the guard the plan rates "covered by review only" (pre-mortem rows 3 and 5: a hostile wiring that drops a hook). A reader who follows it sees false alarms on routine merges and learns to ignore `-` lines, which is exactly the habit row 3 depends on them not having.

**Recommendation:** Reword to "a command is unwired only if it has a `-` line and no matching `+` line anywhere in the diff". Better still, have the review print the set difference of hook commands (removed / added) above the diff, so the reader does not have to work out a reordered JSON diff.

#### 3. A settings-only run prompts "Install these files" and reports "Previous entries moved" when no entry moved

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1043`, `devcontainer-config/install.sh:1137-1138`, `devcontainer-config/install.sh:1163`
**Move:** 4. Verify error consistency (message accuracy)
**Confidence:** High (execution-verified, PROBE1)
**Legibility-target:** for-author
**Evidence:**
> `  if ! confirm "Install these files into $dest?"; then`
> `    echo "Previous entries moved to $backup (delete it when satisfied)."`
> `    echo "Backups: this one plus the 2 most recent earlier installs' are kept in $bkroot ($pruned older removed)."`

The diff correctly suppresses `Installed into $dest.` on a settings-only run (`:1112-1120`, asserted by T94), but leaves the lines around it unchanged. PROBE1's settings-only run printed `Install these files into …? [y/N]`, then `Merged hooks/wiring.json into …settings.json (the previous file is in …/20261015T113712Z).`, then `Previous entries moved to …/20261015T113712Z (delete it when satisfied).` (`logs/probe1-output.txt:33-36`). Only `settings.json` is in that backup, so the user is told that entries moved when none did. The two adjacent lines also both name the backup, once correctly and once wrongly.

**Recommendation:** Gate the `Previous entries moved` line on `${#moved[@]} -gt 0`, the same way `Installed into` is gated on `files_changed`. Word the prompt from what changed, for example "Apply these changes to $dest?", or "Merge settings.json in $dest?" when only the settings changed.

#### 4. After the entries are swapped, a settings backup/write failure says only "it was not changed. Rerun install.sh."

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1124-1134`
**Move:** 4. Verify error consistency
**Confidence:** High (static; branch order unambiguous)
**Legibility-target:** for-author
**Evidence:**
> `      if ! cp -p "$settings" "$backup/settings.json" || ! chmod --reference="$settings" "$snew"; then`
> `        echo "ERROR: could not back up $settings; it was not changed. Rerun install.sh." >&2`
> `      echo "ERROR: could not write $settings; it was not changed. Rerun install.sh." >&2`

When `files_changed=1`, these branches run after the swap and after `Installed into $dest.`. They `exit 1` before the `Previous entries moved to $backup` line (`:1138`) and before `.install-stamp` is written (`:1147`). The user is therefore never told where the previous entries went, and that backup falls outside the rotation for good (performance review, Finding 1). The established pattern for a failure part-way (`host_rollback`, `:767-769`) names what is installed, where the backup is, and how to recover it. The plan's pre-mortem row 17 also promises "Error names the merged file; files stay installed". The message names neither, and the merged copy is deleted by the EXIT trap anyway.

**Recommendation:** Say the end state plainly, for example: "The files were installed; $settings was not changed. Previous entries are in $backup. Rerun install.sh to merge settings.json." Stamp the backup before the settings block, so the rotation still owns it.

#### 5. The host destination is passed to the merge unnormalised, so a trailing slash changes the hook paths written into settings

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1004`, `devcontainer-config/install.sh:1387-1389`
**Move:** 8. Verify the nullability/value contract (input normalisation; the parameter now reaches a persisted artifact)
**Confidence:** High that it happens (PROBE3). How often destinations carry a trailing slash is unknown.
**Legibility-target:** for-author
**Evidence:**
> `          jq --arg dir "$dest" --slurpfile w "${new}hooks/wiring.json" \`
> `  elif [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then HOST_DEST="$CLAUDE_CONFIG_DIR"; HOST_LABEL='$CLAUDE_CONFIG_DIR'`

Before Q-106, `HOST_DEST` reached only file operations, where `x/` and `x` behave the same. It is now the `{{CLAUDE_DIR}}` value and the provenance key. With `CLAUDE_HOME_DIR="$HOME/.claude/"` and a hand-merged group spelled `$HOME/.claude/hooks/h.sh` (the guide §2 spelling), PROBE3 produced `["bash …/.claude/hooks/h.sh","bash …/.claude//hooks/h.sh",["Edit(//…/.claude//settings*.json)"]]`. The old group survives as foreign and the hook is wired twice. This is the FP-161 duplicate the provenance rule exists to prevent. The container caller never hits it, because its `DEST` comes from a fixed spelling. The two callers of "one program" therefore accept different `dir` spellings with different results.

**Recommendation:** Normalise `HOST_DEST` once in `main` (strip trailing slashes, and decide whether to resolve to the physical path). Then add a trailing-slash test asserting a single `h.sh` command.

#### 6. Two docs still say the bare-host merge is manual

**Severity:** Minor
**Location:** `guides/claude-config-security-checkup.md:46-47`, `docs/decisions/037-bare-host-copy-install.md:58`
**Move:** 3. Trace the consumer contract (documentation drift)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> `image payload (decision 023 and its amendment A). On a bare host the wiring is`
> ``still manual — see `guides/bare-host-hook-wiring.md`; until wired, the``
> 037:58: ``… Every plain run asks a second question. The settings merge is still manual, and a changed `wiring.json` is only announced, not applied. …``

The security-checkup guide is outside the diff and was not updated. It now tells bare-host users to wire by hand something `install.sh` does for them. In decision 037, the Decision-section line got the established *Superseded 2026-10-15* marker (`:37`). The matching Consequences line at `:58` did not, although HEAD 05b13d11 edited that same paragraph. The amendment's Q-108 note says "the stale lines under Decision and Consequences are corrected in place" (`:107`), but the line is still uncorrected. The amendment does name it as superseded (`:100`), so a careful reader can recover it.

**Recommendation:** In the security-checkup guide, replace the sentence with "On a bare host, `install.sh`'s `~/.claude` target merges it (Q-106); see …". At `037:58`, add the same italic *Superseded 2026-10-15* marker used at `:37`.

#### 7. The review's "NOT merged" line lacks the `WARNING:`/`NOTE:` prefix the script uses for non-fatal conditions

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1011`
**Move:** 2. Check naming against the grain (message shape)
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence:**
> `    echo "settings.json: NOT merged: $settings: $s_why." | vis_or_die`

Precedent: `WARNING:` / `NOTE:` prefixes for conditions that do not stop the run, used in `devcontainer-config/install.sh:352,928,1307,1318`.

This is the only signal, before the y, that the hook wiring will be left stale. It sits in a review full of `ADD`/`MOVE`/`REPLACE` lines, and its shape (`settings.json: … : … : …`) matches neither the review markers nor the severity prefixes a user has learned to scan for. The trailing `REMINDER` does catch it, but only after the y, and only when `wiring.json` changed.

**Recommendation:** Use `WARNING: settings.json NOT merged ($settings): $s_why.`, matching `:928`'s "WARNING: … MOVED" capitalisation pattern.

#### 8. The help text's "never written" list and its "Needs" line are incomplete

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:45-48`, `devcontainer-config/install.sh:85-86`
**Move:** 3. Trace the consumer contract (documentation drift)
**Confidence:** High (fact-check Claim 2 scope)
**Legibility-target:** for-author
**Evidence:**
> `     the backup. Never written when it is a symlink or not one JSON object,`
> `     jq is missing, or the merge fails (the review says why).`
> `Needs git, perl (the review's control-byte filter), pgrep and a mounted /proc (Linux);`

The code has two more skips: not a regular file, and a payload without `hooks/wiring.json` or `wiring-merge.jq` (`:994-999`). jq is now a soft dependency: without it the merge is skipped, not refused. The "Needs" line lists hard dependencies only, so a reader cannot learn from `--help` that jq is required for the settings merge. The guide (`:55-57`) and the decision amendment repeat the same incomplete list.

**Recommendation:** Add "(jq for the settings merge; skipped without it)" to the Needs line. Either list all five skip reasons or say "or cannot be merged safely (the review says why)".

#### 9. The two callers of the one merge program validate `settings.json` differently

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:1000`, `devcontainer-config/link-claude-home.sh:108`
**Move:** 7. Look for the asymmetry
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Evidence:**
> `  elif [ -e "$settings" ] && ! jq -se 'length == 1 and (.[0] | type == "object")' "$settings" >/dev/null 2>&1; then`
> `  if ! jq -e . "$SETTINGS" >/dev/null 2>&1; then`

The host target refuses anything except exactly one JSON object. The linker accepts anything `jq -e .` accepts, which includes a stream of several values. The linker check is unchanged code, so this is not a regression. But `wiring-merge.jq`'s header presents the program as having one contract with two callers. With identical input, the host refuses and the container may write a multi-document file. Worth aligning when the linker is next touched.

**Recommendation:** Reuse the one-object check in `link-claude-home.sh`, or note the difference in `wiring-merge.jq`'s header.

## What Looks Good

- **Names are consistent throughout.** `file_hash` matches `tree_hash`/`payload_hash`, `MERGE` matches `WIRING`/`SETTINGS`, `.cw-new.settings.json` joins the `.cw-new.*` family in all three places that enumerate it (the planted-link refusal `:822`, the leftover check `:872`, and `rm_new_copies` `:721`), and the new linker skip message copies its siblings word for word.
- **The tamper refusal matches its sibling.** It reuses the existing "changed after review … Nothing was replaced. Rerun install.sh" wording and its exit 1 (`:1064-1066` vs `:1055-1056`).
- **The exit-status contract is unchanged.** A merge that cannot run is reported but does not change the exit status, like the old REMINDER path. New hard failures exit 1, matching "1 a target was declined, or an error".
- **The REMINDER keeps its prefix and pointer** and narrows to the case where it is still actionable (`:1165-1170`). The README drops "settings.json … never touched" in the same commit that makes it untrue.
- **The review labels its diff honestly.** "(now, as jq prints it)" / "(after the wiring merge)" and "jq rewrites the file's layout" tell the reader that the layout normalisation is hidden from the diff but will be applied.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Settings-only runs count toward "last 3 installs"; three of them prune the entries backup | Inconsistent | `devcontainer-config/install.sh:1080,1137-1163`; `README.md:61-63` | High |
| 2 | Guide says a `-` line means unwiring; reordering produces `-` lines on kept hooks | Inconsistent | `guides/bare-host-hook-wiring.md:52-53` | High |
| 3 | Settings-only run prompts "Install these files" and prints "Previous entries moved" | Minor | `devcontainer-config/install.sh:1043,1138` | High |
| 4 | Post-swap settings failure message omits installed state and backup path | Minor | `devcontainer-config/install.sh:1124-1134` | High |
| 5 | Unnormalised `HOST_DEST`: a trailing slash duplicates a hand-merged hook | Minor | `devcontainer-config/install.sh:1004,1387-1389` | High |
| 6 | Security-checkup guide and 037 Consequences still say "manual" | Minor | `guides/claude-config-security-checkup.md:46-47`; `docs/decisions/037-bare-host-copy-install.md:58` | High |
| 7 | "NOT merged" review line lacks the `WARNING:` prefix | Minor | `devcontainer-config/install.sh:1011` | Medium |
| 8 | Help's skip list and Needs line incomplete (jq soft dependency) | Minor | `devcontainer-config/install.sh:45-48,85-86` | High |
| 9 | Host and container callers validate settings.json differently | Informational | `devcontainer-config/install.sh:1000`; `link-claude-home.sh:108` | Medium |

## Overall Assessment

The change follows the codebase's conventions closely. Every new identifier, staging path, error and linker message matches its nearest sibling, and the exit-code contract is untouched. The problems are in the contract around the new path, not in its names:

- **Inconsistent (two findings).**
  - Finding 1 is a quiet change to the documented backup-retention promise.
  - Finding 2 gives users a wrong rule for reading the one review the plan relies on to catch a hostile unwiring.
- **Minor.** The remaining findings are wording and docs that still describe the pre-Q-106 world: a settings-only run reuses full-install wording, a post-swap failure is under-reported, and two docs still say "manual". The one exception is Finding 5: an unnormalised destination brings back the duplicate-hook bug the shared program was built to avoid, and a one-line fix in `main` closes it.

All of these can be fixed in place. None needs a redesign. Consumer impact before fixing: users may lose the entries backup after a few settings fixes, may misread the merge diff, and with an edge-case `CLAUDE_HOME_DIR` may get a hook that runs twice.

## Goal-Alignment Note
- Success criterion (restated verbatim): both reports saved at those paths.
- Answered: yes. This is the API-consistency half: baseline, a 12-row name audit and 9 findings, with the user-facing wording, help text, exit codes, payload path and docs all covered.
- Out of scope: whether `Edit(//…/.claude//settings*.json)` (PROBE3) still matches as a deny rule (security). The test-coverage overclaims in the plan (fact-check Claims 17 and 24b), which are test-strategy matters, not API surface.
- Escalate: PROBE3's double-slash deny rule to the security reviewer. Finding 1 to synthesis, as a recovery-semantics question the author may prefer to answer by changing the rotation rather than the docs.
- Decisions I made: I treated CLI output lines and docs as the "public surface", since there is no programmatic API. I rated Findings 1 and 2 Inconsistent rather than Breaking: neither breaks a script, but each contradicts a documented promise. I filed the README's "WIRED in settings … will stop running" warning as no finding: it stays true after the merge.
