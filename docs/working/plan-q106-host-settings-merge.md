# Plan: the host target merges settings.json (Q-106 [2])

- **Status**: implementing on `feat/q106-host-settings-merge` (base `merge/ready-2026-10-15`, 184396ea)
- **Task**: roadmap Next 4. Q-106 answered [2] on 2026-10-06: the host target of `devcontainer-config/install.sh` runs the same provenance-tracked, TTY-gated `settings.json` merge the container uses, instead of printing a manual-merge reminder.
- **Enforcement file**: `install.sh` and `link-claude-home.sh` are both in `hooks/live-verify-gate.sh`'s `enforcement` set, so the bypass and failure pre-mortem below comes before any code (decision log row 61(4)).

## Research

What exists (read in full, not by signature):

- `devcontainer-config/link-claude-home.sh` lines 90-171: the merge. One `jq` program: drop `_`-keys from the wiring, substitute `{{CLAUDE_DIR}}` with `$DEST`, then per event key `(existing − groups whose every command contains "$DEST/hooks/") + ours` (provenance, FP-161), and per permission mode `(existing − ours − legacy single-slash forms of ours) + ours` (Q-049). It refuses an unparseable `settings.json`, writes a temp file and `mv`s it, and on a jq failure leaves the file alone.
- `install.sh` `install_claude_home`: skip rules (`--yes`, `CLAUDECODE`, no TTY) run before anything is read; then the agent gate, the lock in `$dest`, the stage in `$dest/.cw-stage.*`, copies in `$dest/.cw-new.*` hashed before the review (`payload_hash`), the review, `confirm`, the agent gate again, the hash re-check, the transactional swap with `host_rollback`, the manifest, the backup prune, and finally the `REMINDER` when `hooks/wiring.json` changed.
- Decision 037 kept the merge manual because Q-049 was open and "the only correct merger is link-claude-home's provenance jq (FP-161)". Q-049 is answered; wiring.json now emits `//abs` rules and the jq prunes the legacy form.
- `test/install-host.bats` (T1-T92) drives install.sh in a pty against a temp HOME with stubbed `pgrep`/`docker`; `test/link-claude-home-wiring.bats` exercises the container merge against the real `hooks/wiring.json`.
- Both the claude-home payload (`hooks/**`) and `link-claude-home.sh` are hashed by the cc-isolated trust manifest (`enforcement_files`). Only `link-claude-home.sh` is in the commit gate's regex.

## Design

**Reuse by moving the jq program into the payload.** The filter moves verbatim from `link-claude-home.sh` into `hooks/lib/wiring-merge.jq`, beside `wiring.json`. `link-claude-home.sh` runs `jq -f "$SRC/hooks/lib/wiring-merge.jq"`; the host target runs `jq -f "$dest/.cw-new.hooks/lib/wiring-merge.jq"`, i.e. the hash-checked copy it is about to install. One program, two callers, no duplicated jq. The alternatives were weighed:

| Option | Reuse | Trust of the code that runs on the host | Container impact |
|---|---|---|---|
| **Filter file in the payload** (chosen) | one program | the reviewed, hash-checked `.cw-new.hooks` copy under `$dest` | link-claude-home reads the file; rebuild + re-bless (as for any payload change) |
| `--settings-only` mode in link-claude-home.sh | one script | needs the committed script extracted into the host stage and hashed separately | same rebuild |
| Run link-claude-home.sh unchanged with SRC=DEST=$dest | zero change there | as above | none, but relies on its link loop being a no-op on real dirs (warns 7 times) |
| Copy the jq into install.sh | duplicated | n/a | none, but two copies drift (the FP-161 class) |

**The merge is part of the host review, not a step after it.** After the content diff, install.sh computes the merged result into `$dest/.cw-new.settings.json` (umask 077) from the current `settings.json` (or `{}` when absent) and the reviewed copies' `wiring.json` and filter. When it differs from `jq .` of the current file, it is shown as a `diff -u` (through `vis`) under a `settings.json` heading and counts as a change, so the y covers it. Its hash and the current file's hash are recorded. After the y and the agent gate, both must still hash the same, or nothing is installed. The swap then runs as today; if no entry changed (a settings-only change), the seven entries and the manifest are left alone, so there is no 2.4 MB backup for a settings fix. The old `settings.json` is copied (`cp -p`) into the run's backup dir immediately before the `.cw-new.settings.json` is given the old file's mode and renamed over it.

**When the merge cannot run**, the review says why and the old `REMINDER` is printed (on install) as before: `jq` missing, `settings.json` a symlink (never written through), not valid JSON, the filter missing from the payload, or the jq program failing (e.g. a wiring key whose value is not an array).

## Failure modes considered (bypass and failure pre-mortem)

`/pre-mortem`: triggered (enforcement file, trust boundary); this section is its adversarial pass. `/architecture-review`: not triggered as a separate plan review (two modules, `devcontainer-config/` and `hooks/`, but the change moves one existing program; code-review's architecture critic covers it at review).

| # | Family | What a merge bug or attacker could do | Guard | Covered? |
|---|---|---|---|---|
| 1 | Host hardening loss | The rewrite drops `permissions.allow`, `sandbox`, `env`, or other host-private keys | The jq touches only `.hooks[ev]` for the wiring's events and `.permissions[mode]` for its modes; test asserts `sandbox`, `allow`, an unrelated key and a foreign group survive | covered (test) |
| 2 | Deny-rule loss | The merge removes a user deny rule, or a branch whose wiring drops a rule removes it | Rules are subtracted only when equal to one of ours (re-added) or the legacy single-slash form of one of our **Read/Edit/Write rules under `$dir`** (which matched nothing, Q-049); review loop 1 (security F1) found the unscoped prune let a branch's `Read(//x)` delete a user's `Read(/x)`, and pass 2 (N3) that a single-slash Bash rule is a real rule. A rule absent from the new wiring is never subtracted. T99 asserts all three | covered (T99) |
| 3 | Hook unwiring by a hostile branch | A committed wiring.json omits `guard-trusted-writes.py`; provenance removes the old group and nothing replaces it | The review lists by name, keyed by event, matcher and command, each hook unwired or added (`UNWIRE hook:`, `ADD hook:`) and each rule removed or newly allowed, above the diff (T93, T102); reorders do not appear there | covered by review only (no mechanical refusal) |
| 4 | Provenance spoofing | A group the user authored is treated as ours because its commands contain `$dest/hooks/` | `$dest/hooks` is install-owned: a file the repo lacks there is moved to the backup by the same install (Q-057), so such a group already broke. A mixed group (ours + foreign command) is kept, which can double-fire one hook; same as the container | accepted residual (same as container) |
| 5 | Sticky hostile group, or code outside the payload | A wiring command not under `$dest/hooks/`, or one with `..` or shell syntax that still contains that path, runs unreviewed code and later counts as ours or as foreign | install.sh refuses the merge unless `wiring.json` is exactly one object (pass 2 N1: `jq -e` judged only the last document) and every hook is a `command` hook (N2) running `bash` or `python3` `{{CLAUDE_DIR}}/hooks/<path>` with no `..`, in a non-empty group (review loop 1, security F2; T100 covers each) | covered (T100) |
| 6 | Hostile wiring payload | wiring.json adds `permissions.allow` rules, hooks on new events, or a non-array mode such as `defaultMode` | Non-array modes make jq fail: merge skipped, settings untouched, message (test). Array additions are shown in the review | partly covered (test for the failure path; additions by review) |
| 7 | Hostile filter, or a planted jq library | A committed `wiring-merge.jq` rewrites settings arbitrarily; a `~/.jq` (jq 1.6 loads it) redefines builtins | The filter is in the reviewed, hashed payload and its output is shown and hashed. jq has no exec or file-write builtins. Both callers run jq with HOME and the environment emptied (review loop 1, security F3; T101). Its stderr is discarded | covered (review + hash; T101) |
| 8 | Non-TTY / --yes / CLAUDECODE run | An agent run writes settings.json | The merge sits after the existing skip rules (code order). T1/T2/T4/T22 run without the merge program, so they would not catch a merge moved above them; T93's decline leg asserts n leaves the file byte-identical | covered by code order; tests partial |
| 9 | Concurrent edit while the prompt waits | The user or a process edits settings.json between review and write; the write discards it | The live file is read once, into a copy that is checked, hashed and merged; after the y, a change to the live file refuses the whole install (T95). The backup copy is taken at write time (its dir made then if no entry needed one), so an edit after the check is in the backup | covered (T95); window recoverable |
| 10 | Merged copy tampered while the prompt waits | `$dest/.cw-new.settings.json` is edited after review | Hashed at review, re-checked after the y (same test as #9 for the mechanism) | covered (test) |
| 11 | Write through a link | `settings.json` is a symlink into the checkout or elsewhere | Never written; review says why; target untouched (T96). A planted `.cw-new.settings.json` link is refused like the other `.cw-new.*` names (code; untested) | covered (T96); code only for `.cw-new` |
| 12 | Backup and recovery | A bad merge leaves no way back | The old file is copied into `.claude-workflows-backup/<stamp>/settings.json`; the install says where. A settings-only backup is not stamped, so it never counts among (or prunes) the last 3 installs' backups (review loop 1, API #1; T94). A failed rename leaves the old file in place and says so | covered (T93, T94) |
| 13 | Unparseable settings.json | The merge replaces real settings with `{}`-based output | The read copy must be exactly one JSON object (`jq -se`), and so must the merged output: refused, untouched, message, reminder (T96) | covered (T96) |
| 14 | Mode / secret exposure | The merged copy is world-readable while it waits; the final file loses its mode | Created under umask 077, then given the live file's mode read at review (T93 asserts 640 kept; T98: a new file is 600). Diff context can show `env` values on the user's own terminal (accepted) | covered (T93, T98) |
| 15 | Container regression | link-claude-home.sh changes behaviour | Same program text read from the payload, now with HOME emptied; the 16 link-claude-home-wiring tests run against it. The missing-filter branch is untested | covered (existing suite) |
| 16 | Commit-gate coverage | The merge program moves out of `link-claude-home.sh` (gated) into `hooks/lib/` (not in the gate regex) | Still hashed by the trust manifest (claude-home) and shown in both installs' reviews. Adding it to the gate regex is gate code; left as a question | not covered by the commit gate (question) |
| 17 | Partial failure | Files swapped, settings write fails | Error names the merged file; files stay installed (consistent on their own, as before Q-106); exit 1 | accepted, stated |

No family is uncovered in a way that changes the design; 16 is a question for the user.

**Review loop 1 (2026-10-15).** Rows 2, 5, 7 and 9 were wrong or incomplete as first written: security F1 (the unscoped legacy prune), F2 (`..` and shell syntax in a command), F3 (`~/.jq`) and F7 (no backup on one path). Rows 3, 8, 11, 13, 14 and 15 overstated their tests (fact-check). Row 12 missed that settings-only backups pruned full ones (API #1). All are fixed or restated above.

## Steps

1. Move the jq program to `hooks/lib/wiring-merge.jq`; link-claude-home.sh reads it; link-claude-home-wiring.bats copies it into its fixture.
2. install.sh: compute, review, hash, check and write the merge; settings-only path skips the swap; reminder only when the merge cannot run.
3. Tests T93-T98 in `test/install-host.bats`, each failing on the old code (checked by running them against 184396ea's install.sh).
4. Docs: install.sh header and `--help`, `guides/bare-host-hook-wiring.md` §2, README, a dated amendment to decision 037.
