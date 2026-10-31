Commit: 05b13d11

# Security Review — feat/q106-host-settings-merge (Q-106 [2])

**Scope:** `git diff 184396ea..HEAD` (whole branch; delivery mode: self-read). Code: `devcontainer-config/install.sh` (`install_claude_home`, read whole), `devcontainer-config/link-claude-home.sh` (read whole), `hooks/lib/wiring-merge.jq`; docs/tests read for claims.
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report.md` (k=1); plan `docs/working/plan-q106-host-settings-merge.md` (pre-mortem table attacked below); decision 037 "Trust model (Q-058)".
**Probes:** jq 1.6 under a temp HOME (`/home/node/.claude/jobs/00bcf178/tmp/q106/sec/probe-jq.sh`, `probe-jq2.sh`); `LC_ALL=C bats -f 'T9[3-8]' test/install-host.bats` (6/6 ok). No install.sh run against the real HOME; no process left running.

No HALT escalation: none of the five escalation patterns matches.

## Trust Boundary Map

```
B1 (new):   [committed branch: hooks/wiring.json, hooks/lib/wiring-merge.jq (S2,S3)] → [git archive → $dest/.cw-new.hooks, payload_hash, settings diff + one y] → [~/.claude/settings.json]
B2 (new):   [live ~/.claude/settings.json (S1)]  → [type/symlink test, jq -se, cp → s_view.raw, hash, post-y re-hash, cp -p backup] → [merge input / backup / mv -f rename]
B3 (new on host; pre-existing in container): [$HOME/.jq file, process env (S5,S6)] → [jq process, no isolation] → [merge output → review → settings.json]
B4 (new):   [merge output (jq JSON text) + diff stderr] → [diff -u → vis_or_die] → [human terminal → y/N decision]
B5 (moved): [root-owned /opt payload (S2c,S3c)] → [link-claude-home.sh jq -f, no review] → [container settings.json]
B6 (removed from gate): [agent commit touching the merge program] → [live-verify-gate.sh enforcement regex] → [commit lands]
```

Input-source classification:

```
S1: live <dest>/settings.json     — runtime-mutable (user, Claude Code; denyWrite for sandboxed agents)
                                     — UNTRUSTED for "review shows what is written" (TOCTOU) sinks;
                                       trusted as user content for the merge itself
S2: hooks/wiring.json @HEAD        — runtime-mutable (agent-writable checkout, agents commit)
                                     — UNTRUSTED for settings-write sinks; mediated only by the review
S3: hooks/lib/wiring-merge.jq @HEAD— same as S2 — UNTRUSTED for the program-execution sink (jq: no exec/
                                       file-write builtins, but reads env and ~/.jq data, probe 3b)
S4: $dest/.cw-new.*, $HOST_TMP     — install-owned under $dest (denyWrite) — trusted between review and
                                       swap modulo the payload_hash / s_new_hash re-checks
S5: $HOME/.jq                      — runtime-mutable, OUTSIDE denyWrite, not watched by the guard hook
                                     — UNTRUSTED for the program-execution sink (executed: sourced, probe 2)
S6: process environment            — request-time (user shell) — trusted for availability; secret-bearing,
                                       so UNTRUSTED as a destination of S3's output (terminal, settings.json)
S7: HOST_DEST path                 — deploy-time (user-chosen; main refuses control chars) — trusted
S2c/S3c: /opt payload in container — deploy-time, root-owned 0555 — trusted (but see S5 in-container)
```

What enters: committed, agent-authorable wiring and merge code (B1), the live settings file (B2), and ambient jq state (B3). The diff's central assumption is that the human reading one `settings.json:` diff before one `Install these files into $dest? [y/N]` is sufficient mediation for everything B1 can express, and that the jq program that runs is exactly the reviewed payload file. The first is a stated design choice (Q-106 [2]) with some camouflage gaps (F1, F2, F5); the second is false in jq 1.6 (F3).

## Findings

#### F1. A hostile wiring.json removes a user's deny rule through the legacy-form subtraction, disguised as a one-slash edit

**Severity:** Medium
**Location:** `hooks/lib/wiring-merge.jq:47-50`
**Evidence:**
> `.permissions[$mode] =`
> `(((.permissions[$mode] // []) - $wiring.permissions[$mode]`
> `- ($wiring.permissions[$mode] | map(sub("\\(//"; "(/"))))`
> `+ $wiring.permissions[$mode])`
**Boundary:** B1
**Move:** 11 (bypass enumeration on the plan's row 2 guard), 5 (invert the model)
**Confidence:** High (executed)
**Legibility-target:** for-author

Plan row 2 says a user deny rule always survives and that the legacy single-slash form "matched nothing". That is true only for single-slash forms of rules this repo's wiring once emitted. A user's own single-slash rule is meaningful (relative to the settings file, i.e. under `~/.claude`). A committed wiring.json carrying `Read(//secrets/**)` deletes the user's `Read(/secrets/**)` and adds an absolute rule that matches a different path. Probe 4: input deny `["Read(/secrets/**)"]` with that wiring yields `["Read(//secrets/**)"]`. In the review this shows as a `-`/`+` pair one slash apart, which reads as the documented Q-049 cleanup. The fact-check also found that the row-2 "test covers stale-rule survival" claim has no test.

**Recommendation:** Restrict the legacy subtraction to the exact rule strings Q-049 retired (a fixed list), or drop it once Q-049's migration window has passed. Add a test that a user single-slash rule with no matching retired rule survives. Correct plan row 2.

#### F2. Hostile wiring hooks: a `{{CLAUDE_DIR}}/hooks/../…` command is classified "ours" but runs agent-writable code; no mechanical flag for security-relevant deltas

**Severity:** Medium
**Location:** `hooks/lib/wiring-merge.jq:34-40`; `devcontainer-config/install.sh:1018-1021`, `:1043`
**Evidence:**
> `| all((.command // "")`
> `| contains($dir + "/hooks/")))`
> `1) echo "settings.json: the hooks/wiring.json merge this install applies (Q-106; jq rewrites the file's layout):"`
> `if ! confirm "Install these files into $dest?"; then`
**Boundary:** B1, B4
**Move:** 1, 11
**Confidence:** Medium (path classification executed; reviewer-miss likelihood is judgment)
**Legibility-target:** for-author

Provenance is a substring test, so a wiring command `python3 <dest>/hooks/../../../tmp/x.py` counts as ours (probe 5). It survives later merges as long as the wiring carries it, and runs a script from agent-writable `$TMPDIR` on every matching tool call. The script's content was never reviewed and can change at any time after the y. The same B1 channel can also append `permissions.allow` rules (e.g. `Bash(*)`), `additionalDirectories`, hooks on new events, or "sticky" groups outside `<dest>/hooks/` (plan row 5), and can drop `guard-trusted-writes.py` (row 3). All of these appear in the diff. But the diff also carries jq's layout rewrite and reorder `-` lines (fact-check: reorders produce `-` lines too). The single prompt says "Install these files" and does not mention settings. Before Q-106, applying a wiring change took a deliberate hand edit. Now one y does it.

**Recommendation:** Cheap and not theater, because each check can fail on a real hostile payload: (a) refuse any wiring hook command that contains `..` or does not resolve to a file under `.cw-new.hooks/`. (b) Before the prompt, print explicit summary lines for the security-relevant deltas: deny or ask rules removed, allow rules or `additionalDirectories` added, hook commands removed and not re-added, and commands outside `<dest>/hooks/`. (c) Name settings.json in the prompt when `s_new_hash` is set.

#### F3. `$HOME/.jq` is sourced into the merge: unreviewed, unhashed code outside denyWrite shapes settings.json (and env is readable by the filter)

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:1003-1005`; `devcontainer-config/link-claude-home.sh:115-116`
**Evidence:**
> `if [ -e "$settings" ]; then cp "$settings" "$s_view.raw" && jq . "$s_view.raw"; else echo '{}'; fi > "$s_view"`
> `jq --arg dir "$dest" --slurpfile w "${new}hooks/wiring.json" \`
> `-f "${new}hooks/lib/wiring-merge.jq" "$s_view" > "$snew") 2>/dev/null \`
**Boundary:** B3 (host), B5 (container)
**Move:** 2 (implicit assumption: "the program that runs is the reviewed file"), 1
**Confidence:** Medium (mechanism executed on jq 1.6; jq 1.7 not tested; reachability depends on who can write `~/.jq`)
**Legibility-target:** for-author

jq 1.6 sources a `$HOME/.jq` file into every program, and its definitions shadow builtins. A one-line `def walk(f): {};` made the real wiring-merge.jq wire 0 hooks instead of 9 (probe 2/probe-jq2: `plain HOME=fake: 0`). `-L` does not stop it; `HOME=/nonexistent` does. `~/.jq` is outside the documented `denyWrite ~/.claude`, and the guard hook did not flag writes naming it (it matches `.claude` paths). So an agent with one approved unsandboxed Bash write, or any earlier process the fixed-moment gate did not see (Q-058: the gate samples), can persist code that runs in the next host merge. This contradicts plan row 7 ("the filter is in the reviewed, hashed payload"). On the host the output is still shown and hashed, which caps impact at "review must catch it" (same as F2), but with no payload diff pointing at the cause. A hostile S3 filter (or `~/.jq`) can also read env (`env.X`, probe 3b) and data files under `~/.jq/` (`import "cred" as $c`, probe-jq2 last line), which puts secrets onto the terminal and into settings.json. In the container (B5) the same sourcing is pre-existing and not a boundary (link-claude-home.sh:84-88 says the merged file is "a default, not a boundary").

**Recommendation:** Run every jq in the merge with a clean environment, e.g. `env -i PATH="$PATH" HOME="$HOST_TMP/nohome" LC_ALL=C jq …` (a non-existent HOME disables the sourcing, as probe-jq2 shows). Do the same in link-claude-home.sh for consistency. Add a test that plants `$HOME/.jq` in the temp HOME and asserts the merge output is unchanged.

#### F4. The merge program left the commit-time Live-verified gate

**Severity:** Medium
**Location:** `hooks/live-verify-gate.sh:83` (unchanged); `hooks/lib/wiring-merge.jq` (new)
**Evidence:**
> `enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'`
**Boundary:** B6
**Move:** 5 (what does the control now not cover)
**Confidence:** High
**Legibility-target:** for-author

Before this branch, editing the settings-merge logic meant editing `link-claude-home.sh`, and the commit gate required a `Live-verified` trailer for that. The logic now lives in `hooks/lib/`, which the regex does not match. An agent can change what writes host and container settings.json in an ordinary commit. What remains is the install review (the file's diff plus the settings diff) and the container trust-manifest hash. Plan row 16 and the 037 amendment state this openly and leave it as a question. It is listed here because the merge program now writes a host security policy file.

**Recommendation:** Add `^hooks/lib/wiring-merge\.jq$` (and arguably `^hooks/wiring\.json$`) to the gate's enforcement set, with a bats case. Or record the user's decision on the plan's row-16 question in decision 037.

#### F5. Bidi control characters pass `vis`, so a settings-diff line can render reordered

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:155` (pre-existing), reached newly at `:1019`
**Evidence:**
> `s/([\xc2-\xdf][\x80-\xbf]|[\xe0-\xef][\x80-\xbf]{2}|[\xf0-\xf4][\x80-\xbf]{3})|[\x80-\x9f]/defined $1 ? $1 : "?"/ge;`
> `vis_or_die < "$s_view.diff"`
**Boundary:** B4
**Move:** 11 (bypass candidates for vis)
**Confidence:** Low (vis pass-through executed; on-screen reordering depends on the terminal's bidi support)
**Legibility-target:** for-author

jq escapes ESC and other C0 controls (`\u001b`, probe 8), and vis turns UTF-8-encoded C1 into `?`. U+202E and the other bidi overrides are well-formed 3-byte UTF-8, so vis keeps them (probe 8: `342 200 256` passes through). A committed wiring rule or hook command holding RLO can make an allow rule or a hook path look different on a bidi-capable terminal. This gap already exists for every review diff, and this branch extends it to the settings diff.

**Recommendation:** In `vis`, also replace U+200E/200F, U+202A-202E and U+2066-2069 (`\xe2\x80[\x8e\x8f\xaa-\xae]|\xe2\x81[\xa6-\xa9]`).

#### F6. Validation and copy are separate reads, and the merged output is never checked to be one object; a symlink in the post-check window makes `chmod --reference` follow it

**Severity:** Low
**Location:** `devcontainer-config/install.sh:1000-1006`, `:1126`
**Evidence:**
> `elif [ -e "$settings" ] && ! jq -se 'length == 1 and (.[0] | type == "object")' "$settings" >/dev/null 2>&1; then`
> `if [ -e "$settings" ]; then cp "$settings" "$s_view.raw" && jq . "$s_view.raw"; else echo '{}'; fi > "$s_view"`
> `if ! cp -p "$settings" "$backup/settings.json" || ! chmod --reference="$settings" "$snew"; then`
**Boundary:** B2, B1
**Move:** 4 (TOCTOU), 3 (error path)
**Confidence:** High (traced; two-object propagation and garbage-tail behaviour executed, probes 6-7)
**Legibility-target:** for-author

Fact-check escalation (d) is confirmed, with one more case. If the file is swapped to `{"a":1} garbage` between the validation and the `cp`, `jq .` prints the first object and exits 4. The merge then succeeds on that partial view, because the subshell's status is the last jq's. The review's "now" side lacks the tail, so the y silently drops content that neither diff side showed (the backup keeps it). A two-object swap writes a two-object settings.json. A hostile S3 filter can emit a non-object or several values, and nothing checks that before the review. Separately, if settings.json becomes a symlink after the post-y `-L` check, `cp -p` and `chmod --reference` follow it: the backup holds the target, and the new file takes the target's mode (0666 is possible). The B2 cases need a same-uid write inside `~/.claude`, which already controls the file, hence Low.

**Recommendation:** Validate `$s_view.raw` (the copy) rather than the live path, and require the `jq .` step to succeed. Require `jq -se 'length==1 and (.[0]|type=="object")' "$snew"` before the review. Use `stat -c %a` on the regular file checked with `[ -f ] && [ ! -L ]` instead of `--reference` through a path.

#### F7. No backup when settings.json was absent at review, no entry changed, and a file appears after the check

**Severity:** Low
**Location:** `devcontainer-config/install.sh:1080`, `:1125-1131`
**Evidence:**
> `if [ -n "$s_new_hash" ] && [ -e "$settings" ]; then any=1; fi`
> `if [ -n "$backup" ] && [ -e "$settings" ]; then`
> `if ! mv -f "$snew" "$settings"; then`
**Boundary:** B2
**Move:** 3, 4
**Confidence:** High (traced; fact-check escalation (b) confirmed)
**Legibility-target:** for-author

When the file is absent at the post-y check and `files_changed=0`, `backup` stays empty. A settings.json created (by Claude Code or the user) between line 1062 and the `mv` is overwritten with no copy. The plan's row 9 recovery claim ("an edit in that window is in the backup") does not hold on this path.

**Recommendation:** Just before the `mv`, if `$settings` exists and `backup` is empty, create the backup dir and copy the file. Or `mv -n`/`ln`-based no-clobber when `s_old_hash=absent`, refusing if the target appeared.

#### F8. Secrets in settings.json print to the terminal as diff context

**Severity:** Low
**Location:** `devcontainer-config/install.sh:1014-1019`
**Evidence:**
> `diff -u --label "$settings (now, as jq prints it)" --label "$settings (after the wiring merge)" \`
> `vis_or_die < "$s_view.diff"`
**Boundary:** B4
**Move:** 6 (follow the secrets)
**Confidence:** Medium
**Legibility-target:** for-author

On a first merge, `.hooks //= {}` and `.permissions //= {}` append at the end of the object, so the 3 lines of `-u` context are the file's last keys. Those are often `env` values such as tokens, which land in terminal scrollback and screen-shares. `settings.view.diff` is created under umask 022 (0644, fact-check (a)), but inside the 0700 mktemp dir and removed on exit, so that part is informational.

**Recommendation:** Mask string values under `.env` (and keys matching `*KEY*|*TOKEN*|*SECRET*`) in both diff inputs, then show the masked diff while still hashing and writing the real `$snew`. Or use `diff -U0` for keys outside `hooks`/`permissions`.

#### F9. Settings-only runs take backup-retention slots and say "Previous entries moved"

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:1137-1162`
**Evidence:**
> `echo "Previous entries moved to $backup (delete it when satisfied)."`
**Boundary:** B2
**Move:** 3
**Confidence:** High (traced)
**Legibility-target:** for-orchestrator-synthesis

A settings-only backup gets `.install-stamp` and counts toward the 3 kept. Three settings-only runs prune the last backup of the seven entries. The message also overstates what moved.

**Recommendation:** Prune only among backups that hold entries, or put settings-only backups in a separate subdirectory. Make the message conditional.

## Untested bypass candidates

- **Provenance matcher (`contains($dir + "/hooks/")`)**: a dest spelled differently from the one the hooks were wired with (a hand merge done with `~/.claude`, or a `CLAUDE_HOME_DIR` with a trailing slash or symlinked path). Expected: old groups are not recognized as ours and survive beside the new ones, so guard hooks double-fire. Not run: needs a pty install with a pre-wired file using another spelling. (The `..` candidate was executed, see F2. The mixed-group and substring candidates were traced: plan row 4, accepted.)
- **jq binary resolution**: `command -v jq` follows PATH, and an agent-writable PATH entry (e.g. `~/.local/bin`) would substitute the merger. This already applies to every tool install.sh runs; not probed.
- **jq 1.7 `~/.jq` behaviour**: F3 is executed on jq 1.6 only.
- **Hostile filter reading arbitrary `.json` files via `import`**: absolute and relative import paths failed under jq 1.6 (probe 3). Only `~/.jq/*.json` succeeded. Other search-path entries (`$ORIGIN/../lib/jq`) not tried.

(The post-y re-hash guard's candidates were traced: swap-and-revert yields reviewed bytes, a symlink at check time is refused, and an edit after the check goes to F6/F7. The symlink/non-regular guard's candidates were executed (T96) or traced. None remain untested.)

## Endorsement Claims

- **Claim:** Answering n at the host prompt leaves an existing settings.json byte-identical and removes `.cw-new.settings.json`.
  **Location:** `devcontainer-config/install.sh:1043-1047`
  **Evidence:** executed
  **Verified:** `bats -f T93` passed (asserts the decline leaves the file unchanged); read `rm_new_copies` covering `settings.json` (:721).
  **Not verified:** the decline after a review in which the merge was skipped (`s_why` set) with entry changes.
  **route: code-fact-check**
- **Claim:** A settings.json that is a symlink at review time is not written through, and the files still install.
  **Location:** `devcontainer-config/install.sh:994-995`, `:1061`
  **Evidence:** executed
  **Verified:** `bats -f T96` passed.
  **Not verified:** a symlink created after the post-y check at :1061 (see F6: `cp -p`/`chmod --reference` follow it; `mv -f` replaces the link).
  **route: code-fact-check**
- **Claim:** An edit to settings.json, or to `.cw-new.settings.json`, made while the prompt waits refuses the whole install.
  **Location:** `devcontainer-config/install.sh:1061-1067`
  **Evidence:** executed
  **Verified:** `bats -f T95` passed (FEED_TAMPER on both files).
  **Not verified:** edits between :1062 and the `mv` at :1131 (F6, F7).
  **route: code-fact-check**
- **Claim:** The settings merge is reached only after the `--yes`, `CLAUDECODE` and non-TTY skip returns.
  **Location:** `devcontainer-config/install.sh:784-795` precede `:994`
  **Evidence:** read-static
  **Verified:** read the whole of `install_claude_home`; the three `return 0` skips come before any staging or the merge block.
  **Not verified:** T1/T2/T4/T22 were not rerun on this commit.
  **route: code-fact-check**
- **Claim:** The merge program reads `$wiring.hooks` and `$wiring.permissions` and no other wiring key, so a wiring `env`/`sandbox`/`apiKeyHelper` key does not reach settings through the shipped filter.
  **Location:** `hooks/lib/wiring-merge.jq:26-50`
  **Evidence:** read-static
  **Verified:** read the full filter.
  **Not verified:** a hostile `wiring-merge.jq` itself (S3) or `~/.jq` overrides (F3), which can emit anything.
- **Claim:** The merge's jq stderr is discarded rather than written to the terminal.
  **Location:** `devcontainer-config/install.sh:1005`
  **Evidence:** read-static
  **Verified:** `2>/dev/null` applies to the whole umask subshell.
  **Not verified:** the `jq -se` at :1000 (also `2>/dev/null`) under a jq that writes to the tty directly. Not plausible, not tested.

## Primitive sweep

Primitive: program execution (jq `-f` program / ambient jq library)
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `install.sh:1000` `jq -se …` | S1, S5 | none for S5 | cleared for S1 (validation only); S5 → F3 |
| `install.sh:1003` `jq .` | S1 copy, S5 | none | cleared: `.` cannot be overridden by `~/.jq` definitions (probe 2c); partial-output case → F6 |
| `install.sh:1004-1005` `jq -f wiring-merge.jq` | S2, S3, S5, S6 | payload_hash + review + s_new_hash | F1, F2, F3 |
| `link-claude-home.sh:108` `jq -e .` | container settings | none | cleared: pre-existing, validation only |
| `link-claude-home.sh:115` `jq -f "$MERGE"` | S2c, S3c, S5 (container) | root-owned payload | F3 (pre-existing in container; not a boundary there per :84-88) |
| `link-claude-home.sh:118-119` count jq | container settings | none | cleared: read-only count |

Primitive: file write / rename into the policy directory
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `install.sh:1003` `cp → s_view.raw` | S1 | umask 077, under 0700 `$HOST_TMP` | cleared |
| `install.sh:1015` `> "$s_view.diff"` | S1+S2/S3 output | 0700 dir | F8 (informational part) |
| `install.sh:1126` `cp -p → backup` | S1 | `-e` check | F6 (follows a late symlink) |
| `install.sh:1126` `chmod --reference` | S1 | none | F6 |
| `install.sh:1131` `mv -f "$snew" "$settings"` | S4 | post-y hash, `-L` check | F7 (no-backup path); otherwise cleared (rename, not write-through) |
| `link-claude-home.sh:104` `printf '{}' >` | — | `-f` check | cleared: pre-existing |
| `link-claude-home.sh:117` `mv -f "$tmp"` | merge output | `-s` check | cleared: pre-existing, container default |

Primitive: terminal output of untrusted bytes
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `install.sh:1011` NOT-merged line | S7 | vis_or_die | cleared |
| `install.sh:1019` settings diff | S1, S2, S3 | jq escaping + vis_or_die | F5 (bidi), F8 (secrets) |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Legacy-form subtraction removes a user deny rule | Medium | B1 | `hooks/lib/wiring-merge.jq:47-50` | High |
| 2 | `hooks/..` command classified ours; no mechanical flag for security deltas; prompt omits settings | Medium | B1, B4 | `wiring-merge.jq:34-40`, `install.sh:1018-1021,1043` | Medium |
| 3 | `$HOME/.jq` sourced into the merge; filter reads env | Medium | B3, B5 | `install.sh:1003-1005`, `link-claude-home.sh:115-116` | Medium |
| 4 | Merge program outside the commit gate | Medium | B6 | `hooks/live-verify-gate.sh:83` | High |
| 5 | Bidi overrides pass vis into the settings diff | Medium | B4 | `install.sh:155,1019` | Low |
| 6 | Validate/copy split; output not checked as one object; late symlink followed by chmod | Low | B2, B1 | `install.sh:1000-1006,1126` | High |
| 7 | No backup on the absent-at-review, no-entry-change path | Low | B2 | `install.sh:1080,1125-1131` | High |
| 8 | Secrets shown as diff context | Low | B4 | `install.sh:1014-1019` | Medium |
| 9 | Settings-only backups consume retention slots | Informational | B2 | `install.sh:1137-1162` | High |

## Overall Assessment

The branch is built carefully on the B2/B4 mechanics. The merge runs from the hash-checked copies. The live file and the merged copy are hashed and re-checked after the y (T95). Symlinks are never written through at review time (T96). A decline leaves the file alone (T93). The merge sits behind the existing skip rules. Nothing found is Critical or High, and every issue can be fixed in place without changing the architecture. The weak point is B1/B3. One y now applies whatever a committed `wiring.json`/`wiring-merge.jq` expresses, and the human reading the diff is the only guard. That diff can carry a deny-rule removal disguised as a one-slash cleanup (F1) and an "ours" hook that runs `$TMPDIR` code (F2). The jq that computes the diff also sources `$HOME/.jq`, which sits outside denyWrite and outside the payload (F3). Most important to address: run the merge's jq with a clean environment (`env -i … HOME=<nonexistent>`), and add mechanical checks on the wiring before the prompt: no `..` or out-of-payload hook paths, legacy subtraction limited to the retired rules, and explicit summary lines for removed deny rules and added allow rules. Then decide on F4's gate coverage. Endorsement claims are scoped. Three are executed and three are pending execution verification. So: no blocking findings within the code paths read, Medium findings recommended before merge, and the read-static endorsement claims are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): a report at /workspace/.claude/wt-q106/docs/reviews/security-review-2026-10-15-q106.md structured per the security-reviewer skill, with a `Commit: <HEAD short sha>` first line.
- Answered: yes — all requested attack families covered; jq-level mechanisms executed, install-level windows traced, T93-T98 run.
- Out of scope: pre-existing install.sh surfaces not touched by the diff (PATH resolution, devcontainer target); jq 1.7 behaviour.
- Escalate: F3 also applies to link-claude-home.sh (container; pre-existing); F4 needs the user's row-16 decision; plan rows 2, 7 and 9 claims are inaccurate (F1, F3, F7).
- Decisions I made: rated F5 Medium under the floor rule despite terminal-dependent rendering (alternative: Low as pre-existing vis gap); treated same-uid writes inside ~/.claude as host control (Low for F6/F7) rather than reachable.
