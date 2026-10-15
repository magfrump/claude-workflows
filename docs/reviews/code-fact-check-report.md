# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q106`, branch `feat/q106-host-settings-merge`)
**Scope:** branch diff `git diff 184396ea..HEAD` (9 files: `README.md`, `devcontainer-config/install.sh`, `devcontainer-config/link-claude-home.sh`, `docs/decisions/037-bare-host-copy-install.md`, `docs/working/plan-q106-host-settings-merge.md`, `guides/bare-host-hook-wiring.md`, `hooks/lib/wiring-merge.jq`, `test/install-host.bats`, `test/link-claude-home-wiring.bats`) plus the message of commit 188f5c3c; delivery mode self-read
**Checked:** 2026-10-15
**Total claims checked:** 39
**Summary:** 27 verified, 9 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable
**Commit:** 188f5c3c
**Replication:** k=1 (loop pass, decision 031)

Hallucination-pattern log read first (`docs/reviews/hallucination-patterns.md`, 5 entries). No claim here matches a logged pattern. The closest class is the "measured value quoted from an artifact set" entries; Claim 37 (`Size: 400`) is that kind of claim, and it recomputes exactly.

**Execution logs.** The rules allow no tracked-file edits except this report, so the raw output is kept outside the repo in `/home/node/.claude/jobs/00bcf178/tmp/q106/fc/logs/` (written `$L/` below). The probe scripts are next to it in `/home/node/.claude/jobs/00bcf178/tmp/q106/fc/` (`$P/`). Every install run used bats' own temp HOME (`BATS_TEST_TMPDIR`), never the real HOME or `~/.claude`. Every run was wrapped in `timeout 600`, and none was left running.

- `$P/run-tests.sh` (cwd `/workspace/.claude/wt-q106`, start 2026-10-15T11:24:07Z) does two things:
  - It runs `LC_ALL=C bats -f 'T9[3-8]' test/install-host.bats` (exit 0, 6/6 ok, `$L/head-t93-98.txt`) and `LC_ALL=C bats test/link-claude-home-wiring.bats` (exit 0, 16/16 ok, `$L/head-link-wiring.txt`).
  - It runs the same T93-T98 against **184396ea's** `install.sh`, in a tree holding HEAD's test file and HEAD's `wiring-merge.jq` (`$P/oldtree`, start 11:24:24Z). Each test exits 1 (`$L/old-t93.txt` … `$L/old-t98.txt`).
- `$P/cmp.sh` (11:29:15Z, exit 0, `$L/cmp.txt`) compares the old inline jq program with the new file.
- `$P/jqprobe.sh` (11:25:13Z, exit 0, `$L/jqprobe.txt`) runs jq-only probes A–H of `hooks/lib/wiring-merge.jq`.
- `$P/probe-tests.sh` (11:25:34Z, `$L/probe-tests.txt`) runs probes P1–P4. They are added to a temp copy of `install-host.bats` that drives HEAD's `install.sh`, and they reuse its helpers. P1–P3 pass. P4's status assertion failed only because the devcontainer "n" makes the run exit 1. Its mode capture is valid: `$L/probe-p4.txt`, `$L/p4-modes.txt`, `$L/p4-review-output.txt`, rerun at about 11:25:58Z.
- `$P/mutate.sh` (11:26:35Z, exit 1 as expected, `$L/mutate-chmod.txt`) runs T93 and P1 with `chmod --reference` removed from install.sh.
- The size count and the jq builtins list ran at 11:29:15Z (exit 0, `$L/size-and-builtins.txt`).

---

## Claim 1: "The devcontainer and the `~/.claude` target both merge it (Q-106: shown in the review, applied by the y) … Your memory, projects and logs are never touched."

**Location:** `README.md:63-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the host merge being shown before the prompt, applied only on y, and settings.json now dropped from the "never touched" list. It does not establish the memory/projects/logs non-touch beyond what the pre-existing suite asserts (`symlink_install` user state).
**Legibility-target:** for-orchestrator-synthesis

T93 asserts the review text before the prompt, and that a decline leaves the file byte-identical: `[[ "$output" == *'settings.json: the hooks/wiring.json merge this install applies'*'Aborted. Nothing was changed. (host ~/.claude)'* ]]` then `cmp "$sf" "$S/settings.orig"` (`test/install-host.bats:1651-1652`). On y it asserts `*"Merged hooks/wiring.json into $sf"*` (`test/install-host.bats:1658`). It passes on HEAD and fails on 184396ea.

**Evidence:** `README.md:63-70`, `test/install-host.bats:1646-1673`, `$L/head-t93-98.txt`, `$L/old-t93.txt`

---

## Claim 2: "hooks/wiring.json is merged into <dest>/settings.json by the container's merge (Q-106): shown in the review, applied by the same y, old file to the backup. Never written when it is a symlink or not one JSON object, jq is missing, or the merge fails (the review says why)."

**Location:** `devcontainer-config/install.sh:45-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the review/y/backup path (T93) and the symlink, unparseable and merge-failure skips (T96, T97); jq-missing is covered statically. It does not establish two things. First, the help omits two further skips: not a regular file, and the payload lacking the files. Second, the one-object check (`:1000`) and the copy the merge reads (`:1003`) are separate reads, and the merged copy is never re-checked for being one object. A file swapped to two JSON values between those two commands produces a two-value merge result (probe G), which the review would show and the y would write.
**Legibility-target:** for-orchestrator-synthesis

The skip chain is quoted from `devcontainer-config/install.sh:994-1008`:

```sh
if [ -L "$settings" ] || { [ -e "$settings" ] && [ ! -f "$settings" ]; }; then
  s_why="it is a symlink or not a regular file, and install.sh never writes through one"
elif ! command -v jq >/dev/null 2>&1; then
  s_why="jq is not installed"
elif [ ! -f "${new}hooks/wiring.json" ] || [ ! -f "${new}hooks/lib/wiring-merge.jq" ]; then
...
elif [ -e "$settings" ] && ! jq -se 'length == 1 and (.[0] | type == "object")' "$settings" >/dev/null 2>&1; then
```

When `s_why` is set, `rm -f "$snew"` and a `NOT merged` line are printed (`:1009-1011`), and `s_new_hash` stays empty, so the write block at `:1124` never runs. T96 checks the unparseable and symlink cases, and T97 checks the merge-failure case. All pass. Probe G (`$L/jqprobe.txt`) shows that `{} {"x":1}` input yields two merged output objects.

**Evidence:** `devcontainer-config/install.sh:994-1025`, `devcontainer-config/install.sh:1124-1136`, `test/install-host.bats:1716-1742`, `$L/head-t93-98.txt`, `$L/jqprobe.txt`

---

## Claim 3: "run from the hash-checked copies, so the y covers its result; written only after the y."

**Location:** `devcontainer-config/install.sh:989-990`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the live `settings.json`: it is written only by the `mv` at `:1131`, which comes after `confirm`. It does not establish that nothing is written before the y. The staging copies `.cw-new.settings.json` and `settings.view*` are written before the prompt. "Hash-checked" means compared to the review-time hash after the y, not checked before the merge runs.
**Legibility-target:** for-orchestrator-synthesis

The merge reads `"${new}hooks/wiring.json"` and `-f "${new}hooks/lib/wiring-merge.jq"` (`:1004-1005`). These are the `.cw-new.` copies hashed into `reviewed_hash` at `:904` and re-checked at `:1053`. The only write to the live file is `if ! mv -f "$snew" "$settings"; then` (`:1131`), after `if ! confirm "Install these files into $dest?"` (`:1043`). T93's n run leaves the file byte-identical.

**Evidence:** `devcontainer-config/install.sh:904`, `devcontainer-config/install.sh:1002-1005`, `devcontainer-config/install.sh:1043-1058`, `devcontainer-config/install.sh:1131`, `$L/head-t93-98.txt`

---

## Claim 4: "umask 077: settings can hold secrets."

**Location:** `devcontainer-config/install.sh:991`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the files the subshell creates (`settings.view`, `settings.view.raw`, `.cw-new.settings.json`, all 0600). It does not cover `settings.view.diff`. That file holds the settings lines too, is created outside the subshell at the default umask (0644), and is protected only by its 0700 `mktemp -d` parent.
**Legibility-target:** for-author

The umask sits inside the subshell only: `elif ! (umask 077   # one read of the live file ...` (`:1002`) through `"$s_view" > "$snew") 2>/dev/null` (`:1005`). The diff is written afterwards, outside it: `"$s_view" "$snew" > "$s_view.diff" 2>&1 || rc=$?` (`:1015`). Probe P4 recorded `600 .cw-new.settings.json`, `600 settings.view`, `600 settings.view.raw`, `644 settings.view.diff` and `700 .cw-stage.*` (`$L/p4-modes.txt`). Precise version: "umask 077 for the copies of settings.json; the review diff relies on the stage dir's 0700."

**Evidence:** `devcontainer-config/install.sh:1002-1015`, `$L/p4-modes.txt`, `$L/probe-p4.txt`

---

## Claim 5: "jq's stderr never reaches the terminal."

**Location:** `devcontainer-config/install.sh:991`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three jq invocations in the settings block: the validity check, `jq .`, and the merge. It does not establish anything about jq calls elsewhere in install.sh.
**Legibility-target:** for-orchestrator-synthesis

The validity check ends `>/dev/null 2>&1` (`:1000`). The subshell holding `jq .` and the merge ends `) 2>/dev/null` (`:1005`). Probe P2 used a failing wiring (`defaultMode`): the output contains `the merge program failed on it` and no `jq: error` (`$L/p2-output.txt`). The same wiring run under jq directly prints `jq: error (at s-empty.json:1): Cannot iterate over string` (probe C).

**Evidence:** `devcontainer-config/install.sh:1000-1005`, `$L/p2-output.txt`, `$L/probe-tests.txt`, `$L/jqprobe.txt`

---

## Claim 6: "one read of the live file: s_old_hash is that copy's hash"

**Location:** `devcontainer-config/install.sh:1002`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the diff's old side and `s_old_hash` both derive from one `cp` of the live file. It does not establish that the earlier validity check (`:1000`) read the same bytes (see Claim 2's residue).
**Legibility-target:** for-orchestrator-synthesis

`cp "$settings" "$s_view.raw" && jq . "$s_view.raw"` feeds `$s_view` (`:1003`), and the hash is `s_old_hash="$(file_hash "$s_view.raw")"` (`:1020`). For an absent file `file_hash` returns `absent` (`:715`), because the fresh stage holds no `.raw`.

**Evidence:** `devcontainer-config/install.sh:713-716`, `devcontainer-config/install.sh:1003`, `devcontainer-config/install.sh:1020`

---

## Claim 7: "an edit to settings.json since its review, or to the merged copy, refuses the install rather than writing a result the user did not see."

**Location:** `devcontainer-config/install.sh:1059-1060`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers edits made before the check at `:1061-1062`, which runs after the y and the agent gate. It does not establish refusal for an edit made after that check. That window is Claim 9's subject: such an edit goes to the backup, not to a refusal.
**Legibility-target:** for-orchestrator-synthesis

```sh
if [ -n "$s_new_hash" ] && { [ -L "$settings" ] || [ -L "$snew" ] \
     || [ "$(file_hash "$settings")" != "$s_old_hash" ] || [ "$(file_hash "$snew")" != "$s_new_hash" ]; }; then
  rm_new_copies "$dest"
```
(excerpt ends `:1063`; the block continues to `:1067` with the error and `exit 1`, read)

This runs before the swap at `:1091`. T95 tampers with each file while the prompt waits. It asserts `status 1`, the message, the edited content kept, and `[ -L "$CLAUDE_HOME_DIR/skills" ]` (nothing swapped). It passes.

**Evidence:** `devcontainer-config/install.sh:1059-1067`, `test/install-host.bats:1695-1714`, `$L/head-t93-98.txt`, `$L/old-t95.txt`

---

## Claim 8: "A settings-only change (Q-106) swaps no entry: swap_names stays empty."

**Location:** `devcontainer-config/install.sh:1073`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the swap and manifest being skipped when `files_changed=0`. It does not establish anything about the backup rotation, which still counts a settings-only backup as one of the three kept.
**Legibility-target:** for-orchestrator-synthesis

`files_changed="$changed"` is captured before the settings block (`:993`), and `if [ "$files_changed" -eq 1 ]; then swap_names=("${CLAUDE_HOME_NAMES[@]}"); fi` (`:1075`). The manifest update is gated the same way (`:1112`). T94's drift run asserts no `Installed into`, an unchanged manifest, and a newest backup holding exactly `.install-stamp settings.json`. It passes.

**Evidence:** `devcontainer-config/install.sh:993`, `devcontainer-config/install.sh:1074-1080`, `devcontainer-config/install.sh:1112-1120`, `test/install-host.bats:1675-1693`, `$L/head-t93-98.txt`

---

## Claim 9: "back up right before the rename, so an edit since the check is kept there"

**Location:** `devcontainer-config/install.sh:1122`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the usual case: the file existed at the check, so `backup` was created and `cp -p` copies whatever is there at write time. It does not hold when the file was absent at review and check, no entry swapped (`files_changed=0`), and the file is created after `:1080`. Then `backup` is empty, the `cp` is skipped, and `mv -f` overwrites the newly created file with no copy kept. Nothing tests this window.
**Legibility-target:** for-author

The backup dir exists only if `any=1`: `if [ -n "$s_new_hash" ] && [ -e "$settings" ]; then any=1; fi` (`:1080`). The copy is guarded by `if [ -n "$backup" ] && [ -e "$settings" ]; then` (`:1125`), and then `if ! mv -f "$snew" "$settings"; then` (`:1131`) runs unconditionally. Precise version: "an edit since the check is kept there, provided a backup dir was made (the file existed at `:1080` or entries were swapped)."

**Evidence:** `devcontainer-config/install.sh:1074-1089`, `devcontainer-config/install.sh:1122-1136`

---

## Claim 10: "mv replaces a planted link. The entries stay installed on a failure."

**Location:** `devcontainer-config/install.sh:1123`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `mv -f` over a symlink replacing the link itself while leaving the target untouched (probe H), and the backup/write failures exiting without a rollback. It does not establish that the link's target escapes being read. `cp -p "$settings"` and `chmod --reference="$settings"` (`:1126`) both follow a planted link, so the target's bytes go to the backup and its mode is applied.
**Legibility-target:** for-orchestrator-synthesis

Probe H: `ln -s tgt lnk; mv -f newf lnk` leaves `lnk` a regular file (`-`) containing `new`, with `tgt` still `target` (`$L/jqprobe.txt`). Both failure branches are `echo "ERROR: ..." >&2; exit 1` (`:1127-1128`, `:1132-1133`), after the swap at `:1091-1104`, with no `host_rollback` call.

**Evidence:** `devcontainer-config/install.sh:1124-1136`, `$L/jqprobe.txt`

---

## Claim 11: "The merge program … is hooks/lib/wiring-merge.jq: one copy, which install.sh's host target also runs" (caller claim 1: the jq is byte-for-byte the program link-claude-home.sh had at 184396ea, and the linker's behavior is otherwise unchanged)

**Location:** `devcontainer-config/link-claude-home.sh:110-116`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers program identity (code lines identical after a uniform 10-space dedent, comments excluded) and the linker's 16-test suite passing. Not established:
- The linker gains one new branch: a missing filter file skips the wiring with a message. It is a consequence of reading the file, and untested.
- The two comment blocks differ in wording; the inner legacy-form comment was reworded.
- The image payload's `hooks/lib/` is checked only statically: `CLAUDE_HOME_SRC` includes all of `hooks`.
**Legibility-target:** for-orchestrator-synthesis

`$P/cmp.sh` extracts the 28-line inline program from `git show 184396ea:devcontainer-config/link-claude-home.sh`, drops comment lines, and dedents. It prints `STRICT identical after uniform 10-space dedent` (`$L/cmp.txt`). The new call is `jq --arg dir "$DEST" --slurpfile w "$WIRING" -f "$MERGE" \` followed by `"$SETTINGS" > "$tmp" 2>/dev/null && [ -s "$tmp" ]; then` (`link-claude-home.sh:115-116`). The surrounding validity check, mv and failure branches are unchanged in the diff. The added branch is `elif [ ! -f "$MERGE" ]; then echo "link-claude-home: no $MERGE — hooks linked but not wired." >&2` (`:99-100`). The payload source list is `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`install.sh:139`).

**Evidence:** `devcontainer-config/link-claude-home.sh:91-127`, `devcontainer-config/install.sh:139`, `$L/cmp.txt`, `$L/head-link-wiring.txt`

---

## Claim 12: "The first revisit trigger fired when Q-049 was answered (2026-09-23). The user answered Q-106 [2] on 2026-10-06 … superseding the sub-decision "`settings.json` stays a manual merge" above and the "settings merge is still manual" line under Consequences."

**Location:** `docs/decisions/037-bare-host-copy-install.md:100`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two dates and the existence of both superseded lines. It does not establish whether other docs still carry the old manual-merge wording. Only `docs/working/` history docs do; they were not verdicted.
**Legibility-target:** for-orchestrator-synthesis

The archive reads: "Q-049 was answered on 2026-09-23 (aa21535d …) … **Answered 2026-10-06: [2], automate via link-claude-home's provenance jq.**" (`docs/working/questions-archive.md:2051`). The superseded lines are at `037-bare-host-copy-install.md:37` ("**`settings.json` stays a manual merge.**") and `:58` ("The settings merge is still manual").

**Evidence:** `docs/working/questions-archive.md:2048-2051`, `docs/decisions/037-bare-host-copy-install.md:37`, `docs/decisions/037-bare-host-copy-install.md:58`

---

## Claim 13a: "It inherits the target's skip rules (`--yes`, no TTY, `CLAUDECODE`). The current file's copy and the merged copy are hashed; after the y and the agent gate, a change to either refuses the install. … A settings-only change swaps no entry."

**Location:** `docs/decisions/037-bare-host-copy-install.md:103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip-rule ordering, the hash re-check order and the settings-only path. It does not establish that the existing skip tests exercise the merge (see Claim 19).
**Legibility-target:** for-orchestrator-synthesis

The skip rules `return 0` at `install.sh:784-795`, before any staging. `agent_gate` (`:1051`) precedes the settings check (`:1061`). T95 and T94 pass (Claims 7, 8).

**Evidence:** `devcontainer-config/install.sh:784-795`, `devcontainer-config/install.sh:1051-1067`, `$L/head-t93-98.txt`

---

## Claim 13b: "The old file is copied into the run's backup immediately before the rename, so an edit made after that check is in the backup."

**Location:** `docs/decisions/037-bare-host-copy-install.md:103`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Same as Claim 9. It holds when a backup dir was made, and fails for a file created after `:1080` that was absent at review, when no entries swapped.
**Legibility-target:** for-author

Same code as Claim 9: `if [ -n "$backup" ] && [ -e "$settings" ]; then` (`install.sh:1125`), where `backup` is set only when `any=1` (`:1080-1081`).

**Evidence:** `devcontainer-config/install.sh:1080-1089`, `devcontainer-config/install.sh:1125-1131`

---

## Claim 14: "**Not written** when the file is a symlink, is not one JSON object, `jq` is missing, or the merge fails (a non-list `wiring.json` mode such as `defaultMode`). The review says why, and the old `REMINDER` is printed when `wiring.json` changed."

**Location:** `docs/decisions/037-bare-host-copy-install.md:104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skip cases (T96, T97) and the reminder being printed only on a skip with a changed wiring. It does not establish that the reminder's text is the "old" one: it was reworded to say settings.json was NOT merged.
**Legibility-target:** for-orchestrator-synthesis

`if [ "$wiring_changed" -eq 1 ] && [ -n "$s_why" ]; then   # the merge could not run` (`install.sh:1165`). T96 asserts `*'REMINDER'*'NOT merged'*`. T97 asserts `*'NOT merged'*'the merge program failed on it'*`. Both pass.

**Evidence:** `devcontainer-config/install.sh:1165-1170`, `test/install-host.bats:1716-1742`, `$L/head-t93-98.txt`

---

## Claim 15: "a committed `wiring.json` that … adds a group outside `<dest>/hooks/` (which later merges then treat as foreign) … A user group mixing one of our commands with a foreign one is kept beside ours, as in the container. The merge program now sits outside `live-verify-gate.sh`'s regex, though the trust manifest still hashes it in the devcontainer payload."

**Location:** `docs/decisions/037-bare-host-copy-install.md:105`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mixed-group double wiring (probe F), the provenance predicate, the gate regex text, and the manifest's `claude-home` walk. It does not establish that the manifest hash is checked at runtime on every path; `cc-isolated.sh` was read only as far as `enforcement_files`.
**Legibility-target:** for-orchestrator-synthesis

Probe F: settings with `[h.sh, /opt/x.sh]` in one group comes out with that group intact plus a second group holding `h.sh` (`$L/jqprobe.txt`). The provenance predicate is `all((.command // "") | contains($dir + "/hooks/"))` (`hooks/lib/wiring-merge.jq:36-38`). The gate regex is `enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'` (`hooks/live-verify-gate.sh:83`), which has no `hooks/`. The manifest walk is `if [ -d claude-home ]; then find claude-home \( -type f -o -type l \) | LC_ALL=C sort; fi` (`devcontainer-config/cc-isolated.sh:149`).

**Evidence:** `hooks/lib/wiring-merge.jq:32-41`, `hooks/live-verify-gate.sh:83`, `devcontainer-config/cc-isolated.sh:128-149`, `$L/jqprobe.txt`

---

## Claim 16: Pre-mortem row 1: "test asserts `sandbox`, `allow`, an unrelated key and a foreign group survive" — covered (test)

**Location:** `docs/working/plan-q106-host-settings-merge.md:38`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T93's assertions for those four items. It does not establish survival of other host keys (`env`, `sandbox` sub-keys beyond `enabled`); that rests on the jq touching only `.hooks[ev]` and `.permissions[mode]`.
**Legibility-target:** for-orchestrator-synthesis

`[ "$(jq -c '[.user, .sandbox, .permissions.allow]' "$sf")" = '["settings",{"enabled":true},["Bash(ls:*)"]]' ]` and `… = "[\"bash /opt/mine.sh\",\"bash $d/hooks/h.sh\"]" ]` (`test/install-host.bats:1662,1664`). Passes.

**Evidence:** `test/install-host.bats:1660-1665`, `$L/head-t93-98.txt`

---

## Claim 17: Pre-mortem row 2: "A rule absent from the new wiring is never subtracted. Test asserts a user rule and a stale rule both survive" — covered (test)

**Location:** `docs/working/plan-q106-host-settings-merge.md:39`
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the tests assert about deny rules. It does not dispute the behavior: probe D shows the merge keeps a stale rule (`Bash(rm:*)`, absent from the wiring). It refutes only the "covered (test)" claim.
**Legibility-target:** for-author

No test has a stale rule (a rule of ours that the new wiring no longer carries). `user_settings` deny holds `"Read(./.env)"` (a user rule) and `"Edit(%s/settings*.json)"`, which T93's own comment calls "our legacy single-slash rule" and which is **pruned**, not kept (`test/install-host.bats:1638-1640`, `:1663`). T94 sets deny to `["Read(./.env)"]` only (`:1683`). The wiring fixture has a single rule (`:1631`). A regression that subtracted rules absent from the wiring would pass T93-T98. What to fix: add a rule such as `Bash(rm:*)` to `user_settings` and assert that it survives, or change the row to "covered for the user rule; stale rule by the jq's text only".

**Evidence:** `test/install-host.bats:1628-1641`, `test/install-host.bats:1660-1664`, `test/install-host.bats:1683`, `$L/jqprobe.txt` (probe D)

---

## Claim 18: Pre-mortem row 6: "Non-array modes make jq fail: merge skipped, settings untouched, message (test)"

**Location:** `docs/working/plan-q106-host-settings-merge.md:43`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a non-array mode in the **wiring** (T97). It does not establish anything about non-array modes in settings.json: `defaultMode` there merges normally (P3), and a settings `deny` string fails (probe B).
**Legibility-target:** for-orchestrator-synthesis

T97 writes a wiring whose only content is a string-valued `permissions.defaultMode` (`test/install-host.bats:1736`). It asserts the failure message and `cmp` against the original. Passes, and fails on 184396ea.

**Evidence:** `test/install-host.bats:1734-1742`, `$L/head-t93-98.txt`, `$L/old-t97.txt`

---

## Claim 19: Pre-mortem row 8: "The merge sits after the existing skip rules; T1/T2/T4/T22 keep the snapshot equal, and a new test asserts a declined review leaves settings.json byte-identical" — covered

**Location:** `docs/working/plan-q106-host-settings-merge.md:45`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the placement (code order) and T93's decline assertion. It does not establish that T1/T2/T4/T22 would catch a merge moved above the skip rules. Their fixture (`fake_repo` without `with_merge`) has no `hooks/lib/wiring-merge.jq`, so the merge always skips there with "the payload has no …", and the snapshot stays equal either way.
**Legibility-target:** for-author

`fake_repo` writes `"$ROOT/hooks/lib/x.sh"` and `{"hooks":{}}` as the wiring (`test/install-host.bats:105-106`). Only `with_merge` copies the jq in (`:1630`), and T1/T2/T4/T22 do not call it. Each asserts `[ "$(snap "$CLAUDE_HOME_DIR")" = "$before" ]`. Precise version: "placement by code order; the skip tests run without the merge program, so they do not test it."

**Evidence:** `test/install-host.bats:94-121`, `test/install-host.bats:181-230`, `test/install-host.bats:457`, `test/install-host.bats:1628-1633`, `devcontainer-config/install.sh:784-795`

---

## Claim 20: Pre-mortem rows 9-10: "The current file's hash is re-checked after the y: any change refuses the whole install (test)"; "Hashed at review, re-checked after the y (same test as #9)"

**Location:** `docs/working/plan-q106-host-settings-merge.md:46-47`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tamper targets in T95. It does not test the residual window after the check (row 9 states it as recoverable; see Claim 9).
**Legibility-target:** for-orchestrator-synthesis

T95's two halves tamper with `settings.json` and with `.cw-new.settings.json` respectively. Each asserts `[ -e "$S/tamper.landed" ]`, `status 1` and the refusal message (`test/install-host.bats:1698-1713`). Passes.

**Evidence:** `test/install-host.bats:1695-1714`, `$L/head-t93-98.txt`

---

## Claim 21: Pre-mortem row 11: "Never written; review says why; target untouched (test). `.cw-new.settings.json` planted as a link is refused like the other `.cw-new.*` names" — covered (test)

**Location:** `docs/working/plan-q106-host-settings-merge.md:48`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the symlinked-settings half (T96) and the planted-link refusal in code. It does not establish test coverage of the planted `.cw-new.settings.json` link: no test plants one.
**Legibility-target:** for-author

T96: `[[ "$output" == *"NOT merged: $sf: it is a symlink"* ]]` and `[ -L "$sf" ] && [ "$(cat "$S/target.json")" = '{"target":1}' ]` (`test/install-host.bats:1729-1731`). The refusal code is `for name in "${CLAUDE_HOME_NAMES[@]}" manifest settings.json; do if [ -L "$dest/.cw-new.$name" ]; then host_refuse ...` (`install.sh:822-824`). A grep of `test/install-host.bats` for `.cw-new.settings.json` finds only `[ ! -e … ]` checks and T95's write (paraphrased — no quote available because the claim is about the absence of a test, shown by grep).

**Evidence:** `devcontainer-config/install.sh:822-826`, `test/install-host.bats:1716-1732`, `$L/head-t93-98.txt`

---

## Claim 22: Pre-mortem row 12: "The old file is copied into `.claude-workflows-backup/<stamp>/settings.json` … (test asserts the backup)"

**Location:** `docs/working/plan-q106-host-settings-merge.md:49`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the backup copy. It does not establish test coverage of "A failed rename leaves the old file in place and says so" (static only: `install.sh:1131-1133`).
**Legibility-target:** for-orchestrator-synthesis

`bk=$(echo "$d"/.claude-workflows-backup/*)` then `cmp "$bk/settings.json" "$S/settings.orig"` (`test/install-host.bats:1667-1668`). Passes.

**Evidence:** `test/install-host.bats:1666-1669`, `$L/head-t93-98.txt`

---

## Claim 23: Pre-mortem row 13: "`jq -e .` first: refused, untouched, message, reminder (test)"

**Location:** `docs/working/plan-q106-host-settings-merge.md:50`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal, message and reminder (T96). It does not match the mechanism named: the check is a stricter one-object test, not `jq -e .`.
**Legibility-target:** for-author

The code is `jq -se 'length == 1 and (.[0] | type == "object")' "$settings"` (`install.sh:1000`). T96 asserts `*"settings.json: NOT merged: $sf: it is not one valid JSON object"*` and `*'REMINDER'*'NOT merged'*` (`test/install-host.bats:1722-1723`). Precise version: "a one-JSON-object check (`jq -se`) first".

**Evidence:** `devcontainer-config/install.sh:1000-1001`, `test/install-host.bats:1716-1726`, `$L/head-t93-98.txt`

---

## Claim 24a: Pre-mortem row 14 (first half): "Created under umask 077" — covered (test)

**Location:** `docs/working/plan-q106-host-settings-merge.md:51`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a new settings.json landing at 600 (T98) and the merged copy being 600 while the prompt waits (P4). It does not cover the diff file (Claim 4).
**Legibility-target:** for-orchestrator-synthesis

T98: `[ "$(stat -c %a "$sf")" = 600 ]` with no prior settings.json (`test/install-host.bats:1752`). P4 recorded `600 .cw-new.settings.json`.

**Evidence:** `test/install-host.bats:1745-1753`, `$L/p4-modes.txt`, `$L/head-t93-98.txt`

---

## Claim 24b: Pre-mortem row 14 (second half): "given the old file's mode before the rename (test asserts 600 kept)" — covered (test)

**Location:** `docs/working/plan-q106-host-settings-merge.md:51`
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether a test exercises mode keeping. It does not dispute the behavior: P1 shows a 0644 file stays 644. It refutes the "covered (test)" claim.
**Legibility-target:** for-author

T93 sets `chmod 600 "$d/settings.json"` (`test/install-host.bats:1641`) and asserts `[ "$(stat -c %a "$sf")" = 600 ]` (`:1666`). The umask already makes the merged copy 600, so that assertion holds with or without `chmod --reference`. Mutation run: with `|| ! chmod --reference="$settings" "$snew"` removed from install.sh, **T93 still passes** and P1 (a 0644 original) fails (`$L/mutate-chmod.txt`: `ok 1 T93 …`, `not ok 2 P1 …`). What to fix: start T93's (or a new test's) settings at a mode other than 600, such as 644, and assert that mode afterwards. T93's title ("mode kept") carries the same overclaim.

**Evidence:** `devcontainer-config/install.sh:1126`, `test/install-host.bats:1636-1641`, `test/install-host.bats:1666`, `$L/mutate-chmod.txt`, `$L/p1-output.txt`

---

## Claim 25: Pre-mortem row 15: "Same program text, read from the payload; the existing 16 link-claude-home-wiring tests run against it; a missing filter file says so and leaves settings alone" — covered (existing suite)

**Location:** `docs/working/plan-q106-host-settings-merge.md:52`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the program identity, the count of 16 (16 at both 184396ea and HEAD), and 16/16 passing. It does not establish suite coverage of the missing-filter branch: none of the 16 tests removes the filter.
**Legibility-target:** for-author

`grep -c '^@test' test/link-claude-home-wiring.bats` gives 16 at both commits. HEAD's run is `1..16`, all ok (`$L/head-link-wiring.txt`). The branch exists at `link-claude-home.sh:99-100` (Claim 11). The suite's setup always copies the filter: `cp "$REPO_ROOT/hooks/lib/wiring-merge.jq" "$SRC/hooks/lib/"` (`test/link-claude-home-wiring.bats:39`).

**Evidence:** `test/link-claude-home-wiring.bats:33-40`, `devcontainer-config/link-claude-home.sh:99-100`, `$L/head-link-wiring.txt`

---

## Claim 26: "Groups whose commands all run something under `~/.claude/hooks/` are replaced by the current wiring's (FP-161); each wiring rule is added once, its legacy single-slash form dropped (Q-049); everything else is kept."

**Location:** `guides/bare-host-hook-wiring.md:50-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the provenance replacement, the rule add/prune, and the survival of foreign groups, user rules and other keys (T93; probes A, D). Not established:
- Groups are replaced only for the event keys the wiring carries.
- A user's own group whose commands all run user scripts under `~/.claude/hooks/` counts as "ours" and is removed (probe E). The definition states this, but a reader may not expect it.
- jq rewrites the file's layout.
**Legibility-target:** for-orchestrator-synthesis

T93 asserts the stale group (h.sh + old.sh) is gone, `/opt/mine.sh` kept, `h.sh` re-added, and deny `["Read(./.env)","Edit(/$d/settings*.json)"]` (legacy dropped, `//` form added once) (`test/install-host.bats:1663-1664`). Probe E: a settings group with only `bash /h/.claude/hooks/my-own.sh` comes out without it (`$L/jqprobe.txt`).

**Evidence:** `hooks/lib/wiring-merge.jq:32-51`, `test/install-host.bats:1660-1665`, `$L/jqprobe.txt`, `$L/head-t93-98.txt`

---

## Claim 27: "A `-` line on a hook command means the install unwires it."

**Location:** `guides/bare-host-hook-wiring.md:52-53`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reading of the review's `diff -u` output for the T93 fixture. It does not establish how often a reorder produces such lines on real settings files. It happens whenever an "ours" group sits before a foreign group in the same event, because the merge appends ours at the end.
**Legibility-target:** for-author

The merge is `(existing − ours) + ours`, so our group moves to the end of the event's array. `diff -u` of the reordered JSON shows `-` lines on commands that stay wired. The review the installer printed in P4 (same fixture as T93) has:

```
-            "command": "bash /opt/mine.sh"
+            "command": "bash /tmp/bats-run-oEfxlg/test/1/home/.claude/hooks/h.sh"
```
(`$L/p4-review-output.txt`, hunk `@@ -32,7 +28,7 @@`)

There is also an earlier `-            "command": "bash …/hooks/h.sh"` line. Yet T93 asserts that both `bash /opt/mine.sh` and `bash $d/hooks/h.sh` are wired after the install (`test/install-host.bats:1664`). A reader following the guide would conclude that the foreign hook and our own hook are being unwired. What to fix: say that a command unwires only if it has a `-` line and no matching `+` line anywhere in the diff. Alternatively, have the review list the hook commands removed (set difference) alongside the diff.

**Evidence:** `devcontainer-config/install.sh:1014-1019`, `hooks/lib/wiring-merge.jq:33-41`, `test/install-host.bats:1664`, `$L/p4-review-output.txt`

---

## Claim 28: "The old file goes to `~/.claude/.claude-workflows-backup/<stamp>/settings.json`. Nothing is written when the file is a symlink or not one JSON object, `jq` is missing, or the merge fails: the review says why, and a `REMINDER` follows if `wiring.json` changed. An edit to the file between the review and the y refuses the install."

**Location:** `guides/bare-host-hook-wiring.md:53-57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the backup (T93), the skips plus the reminder (T96, T97), and the refusal (T95). It does not establish refusal for an edit after the post-y check, or the backup edge in Claim 9. The dir may also be named `<stamp>.<pid>` on a stamp collision (`install.sh:1083`).
**Legibility-target:** for-orchestrator-synthesis

See Claims 7, 14 and 22 for the quoted code and assertions. All of T93, T95, T96 and T97 pass on HEAD and fail on 184396ea.

**Evidence:** `devcontainer-config/install.sh:1059-1067`, `devcontainer-config/install.sh:1122-1136`, `devcontainer-config/install.sh:1165-1170`, `$L/head-t93-98.txt`

---

## Claim 29: "When `wiring.json` changes, the next `install.sh` run merges it again (above). After a hand merge, rerun `install.sh`: its review shows anything your merge left out."

**Location:** `guides/bare-host-hook-wiring.md:94-95`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers a hand-edited file missing a wiring rule: T94 deletes our deny rule, and the rerun's review shows it as `+`. It does not establish recognition of hand-merged groups written with a different path spelling than `$dest` (for example a non-default `CLAUDE_HOME_DIR`). Those groups would be kept as foreign and a duplicate appended.
**Legibility-target:** for-orchestrator-synthesis

T94: `jq '.permissions.deny = ["Read(./.env)"]' …`, then `[[ "${output%%Install these files*}" == *'+      "Edit(//'* ]]` (`test/install-host.bats:1683-1686`). Passes.

**Evidence:** `test/install-host.bats:1675-1693`, `$L/head-t93-98.txt`

---

## Claim 30: "Two callers run it: devcontainer-config/link-claude-home.sh, at every container start (decision 023), from the image's root-owned payload; devcontainer-config/install.sh's host target (Q-106 [2]), from the reviewed, hash-checked copy it is about to install, before the y."

**Location:** `hooks/lib/wiring-merge.jq:3-7`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two in-repo callers and their sources. It does not establish that no out-of-repo script runs the file. "Hash-checked" here means re-checked after the y (Claim 3).
**Legibility-target:** for-orchestrator-synthesis

A repo grep for `wiring-merge` outside tests and docs finds only `link-claude-home.sh:92` (`MERGE="$SRC/hooks/lib/wiring-merge.jq"`) and `install.sh:998-1005` (`-f "${new}hooks/lib/wiring-merge.jq"`). The payload is root-owned: `chown -R root:root /opt/claude-workflows` (`devcontainer-config/Dockerfile:516`).

**Evidence:** `devcontainer-config/link-claude-home.sh:92`, `devcontainer-config/install.sh:998-1005`, `devcontainer-config/Dockerfile:499`, `devcontainer-config/Dockerfile:516`

---

## Claim 31: "jq has no builtin that runs a command or writes a file; the caller writes the output."

**Location:** `hooks/lib/wiring-merge.jq:11-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers jq 1.6, the version in this sandbox. Its I/O builtins are `debug`, `stderr`, `halt_error` (stderr writes), `input`, `inputs`, `input_filename`, `env` (reads), and no `system` or exec. It does not establish this for the host's jq version, which was not available. `import`/`include` directives can read module files, and stderr writes exist but are discarded by both callers.
**Legibility-target:** for-orchestrator-synthesis

`jq -nr 'builtins | sort | .[]'` under `jq-1.6`, filtered for I/O-like names, gives `debug/0 env/0 halt/0 halt_error/0 halt_error/1 input/0 input_filename/0 input_line_number/0 inputs/0 stderr/0`, and no `system` or `exec` appears anywhere in the list (`$L/size-and-builtins.txt`).

**Evidence:** `$L/size-and-builtins.txt`

---

## Claim 32: "(existing - ours) + ours, so a rerun is exactly idempotent and everything we did not author stays in place."

**Location:** `hooks/lib/wiring-merge.jq:15-16`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers idempotence (T94 rerun: "Nothing to install", snapshot equal) and survival of foreign groups and user rules. It does not hold literally for groups the user authored whose commands all run something under `$dir/hooks/`. Those are "ours" by provenance and are removed (probe E). The rest of the header defines "ours" that way, so the precise version is "everything not ours by provenance stays in place".
**Legibility-target:** for-author

Probe E removed a user group running only `bash /h/.claude/hooks/my-own.sh` (`$L/jqprobe.txt`). T94 asserts `*'Nothing to install into'*` and an equal snapshot on rerun (`test/install-host.bats:1679-1681`). The plan accepts the provenance case as residual row 4.

**Evidence:** `hooks/lib/wiring-merge.jq:15-19`, `test/install-host.bats:1675-1681`, `$L/jqprobe.txt`

---

## Claim 33: "a rule the wiring no longer carries is never removed."

**Location:** `hooks/lib/wiring-merge.jq:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers permission rules in modes the wiring carries. It does not cover hook groups, which are removed by provenance whether or not the wiring still carries them.
**Legibility-target:** for-orchestrator-synthesis

The subtraction removes only `$wiring.permissions[$mode]` and its `sub("\\(//"; "(/")` forms (`wiring-merge.jq:48-50`). Probe D: settings deny `["Bash(rm:*)","Read(./.env)"]` comes out as `["Bash(rm:*)","Read(./.env)","Edit(//h/.claude/settings*.json)"]` (`$L/jqprobe.txt`).

**Evidence:** `hooks/lib/wiring-merge.jq:43-51`, `$L/jqprobe.txt`

---

## Claim 34: "A mode whose value is not an array (e.g. "defaultMode") makes jq fail, and both callers then leave the settings file alone."

**Location:** `hooks/lib/wiring-merge.jq:24-25`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the wiring-side reading, a non-array mode in wiring.json (probe C, T97), and a settings mode that the wiring also carries holding a non-array (probe B). Both callers' skip-on-failure paths are covered as well. It does not hold for a non-array mode that only settings.json has. The `defaultMode` the example names is the common real-world case, and in settings.json it merges without error (probe A, P3).
**Legibility-target:** for-author

The reduce iterates over `($wiring.permissions // {}) | keys_unsorted[]` (`wiring-merge.jq:44`), so only the wiring's modes are touched. Probe outputs (`$L/jqprobe.txt`):
- A: settings `"defaultMode":"acceptEdits"` gives exit 0 with defaultMode kept.
- B: settings `"deny":"Read(./.env)"` gives `string … and array … cannot be subtracted`, exit 5.
- C: a wiring with `defaultMode` set to a string (the bypass mode name, as in T97) gives `Cannot iterate over string`, exit 5.

P3 runs install.sh with a settings `defaultMode` and gets `Merged hooks/wiring.json into`, with defaultMode kept (`$L/p3-output.txt`). The callers' failure paths are `rm -f "$tmp"; echo "link-claude-home: hook merge failed — $SETTINGS left unchanged."` (`link-claude-home.sh:121-123`) and `s_why=…` (`install.sh:1007`). Precise version: "A wiring.json mode whose value is not an array (e.g. "defaultMode"), or a settings.json value for one of the wiring's modes that is not an array, makes jq fail".

**Evidence:** `hooks/lib/wiring-merge.jq:43-51`, `devcontainer-config/link-claude-home.sh:115-124`, `devcontainer-config/install.sh:1002-1008`, `$L/jqprobe.txt`, `$L/p3-output.txt`

---

## Claim 35: "Tests T93-T98 (install-host.bats) each fail on 184396ea's install.sh."

**Location:** `git:188f5c3c` (commit message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each test failing against the old install.sh, with HEAD's test file and HEAD's `wiring-merge.jq` present. It does not establish that each fails *for the reason its title names*. T93 fails at its first review assertion, and T98 at the settings content check.
**Legibility-target:** for-orchestrator-synthesis

Each old run exits 1. The first failing assertions are: T93 `:1651` (the review text), T94 `:1686`, T95 `:1702`, T96 `:1722`, T97 `:1740`, T98 `:1750` (`$L/old-t93.txt` … `$L/old-t98.txt`).

**Evidence:** `$L/old-t93.txt`, `$L/old-t94.txt`, `$L/old-t95.txt`, `$L/old-t96.txt`, `$L/old-t97.txt`, `$L/old-t98.txt`

---

## Claim 36: "The old file is copied into the run's backup right before the rename, with its mode kept (umask 077 for the merged copy)."

**Location:** `git:188f5c3c` (commit message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mode being kept for an existing file (P1: 644 stays 644), the merged copy at 600 (P4), and the backup (T93). It does not establish ownership being kept (not claimed), or test-suite coverage of mode keeping (Claim 24b).
**Legibility-target:** for-orchestrator-synthesis

`if ! cp -p "$settings" "$backup/settings.json" || ! chmod --reference="$settings" "$snew"; then` (`install.sh:1126`). P1 passes with `$L/p1-output.txt` showing the merge; its mode capture was 644.

**Evidence:** `devcontainer-config/install.sh:1124-1131`, `$L/probe-tests.txt`, `$L/p1-output.txt`, `$L/p4-modes.txt`

---

## Claim 37: "Size: 400 code lines against merge/ready-2026-10-15 (184396ea)"

**Location:** `git:188f5c3c` (commit message body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count from pr-prep step 1a's command against 184396ea. It does not establish anything about the gate's tolerance: exactly 400 sits at the cap, and "the gate fires above 400".
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat 184396ea...188f5c3c -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` prints `400` (`$L/size-and-builtins.txt`). The command is from `workflows/pr-prep.md:91`.

**Evidence:** `workflows/pr-prep.md:86-91`, `$L/size-and-builtins.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 17** (`docs/working/plan-q106-host-settings-merge.md:39`): no test has a stale rule (one of ours that the new wiring dropped); the "legacy" rule in the fixture is pruned. Add a stale rule to `user_settings` and assert that it survives, or narrow the row.
- **Claim 24b** (`docs/working/plan-q106-host-settings-merge.md:51`): T93's `600` assertion does not test mode keeping. With `chmod --reference` removed, T93 still passes (the umask yields 600). Start from a 644 file in a test, and fix T93's "mode kept" title.
- **Claim 27** (`guides/bare-host-hook-wiring.md:52-53`): `-` lines also come from reordering. In T93's own review, `bash /opt/mine.sh` and our `h.sh` have `-` lines and both stay wired. Reword the guide: a command is unwired only if it has a `-` line and no matching `+` line. Or have the review list the removed commands.

### Mostly Accurate
- **Claim 4** (`devcontainer-config/install.sh:991`): the umask does not cover `settings.view.diff`, which is 0644 inside the 0700 stage.
- **Claim 9** (`devcontainer-config/install.sh:1122`): no backup is taken if the file was absent at review and check, no entries swapped, and the file was created after `:1080`.
- **Claim 13b** (`docs/decisions/037-bare-host-copy-install.md:103`): same edge as Claim 9.
- **Claim 19** (`docs/working/plan-q106-host-settings-merge.md:45`): T1/T2/T4/T22 run without the merge program, so they cannot catch a merge placed above the skip rules.
- **Claim 21** (`docs/working/plan-q106-host-settings-merge.md:48`): the planted `.cw-new.settings.json` link refusal is in the code but untested.
- **Claim 23** (`docs/working/plan-q106-host-settings-merge.md:50`): the check is `jq -se 'length == 1 and …object'`, not `jq -e .`.
- **Claim 25** (`docs/working/plan-q106-host-settings-merge.md:52`): the existing suite never exercises the missing-filter branch.
- **Claim 32** (`hooks/lib/wiring-merge.jq:15-16`): "we did not author" should be "not ours by provenance". User groups running scripts under `$dir/hooks/` are removed.
- **Claim 34** (`hooks/lib/wiring-merge.jq:24-25`): a non-array mode fails only when it is in the wiring, or in a settings mode the wiring carries. A settings `defaultMode` (the example given) merges fine.

---

## Goal-Alignment Note
- Success criterion (restated verbatim): a report at /workspace/.claude/wt-q106/docs/reviews/code-fact-check-report.md in the code-fact-check skill's format, with `**Commit:** <HEAD short sha>` and `**Replication:** k=1 (loop pass, decision 031)` header lines.
- Answered: yes. All six caller-flagged claim groups are verdicted, the requested suites were run (6/6, 16/16), and T93-T98 were each run against 184396ea's install.sh.
- Out of scope:
  - Quality, security or design judgments, for example whether the multi-value TOCTOU in Claim 2's residue matters; this is verification only.
  - The working-doc history files still saying "manual merge" were not verdicted.
- Escalate: the three Incorrect claims (17, 24b, 27). Claim 27 is user-facing guidance on how to read the review, and the security reviewer may want Claim 2's two-read residue.
- Decisions I made:
  - Execution logs stay outside the repo (`/home/node/.claude/jobs/00bcf178/tmp/q106/fc/logs/`) because tracked-file edits were limited to this report.
  - I did not append to `docs/reviews/hallucination-patterns.md`, for the same reason. None of the Incorrects is a fabricated symbol or API anyway: they are coverage overclaims and one diff-reading claim.
