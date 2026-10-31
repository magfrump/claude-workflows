Commit: f14cf11a

# API Consistency Review — feat/q106-host-settings-merge (loop pass 2)

**Scope:** range `git diff 05b13d11..HEAD` (f7680e0d, d53d2bf4, a4f3614a, f14cf11a), self-read. `git diff 184396ea..HEAD` checked before calling anything missing. Read in full at HEAD: `install_claude_home` (`devcontainer-config/install.sh:790-1218`), the new helpers (`:721-732`), `usage` (`:29-108`), and the changed guide, decision and plan sections.
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit a4f3614a, k=1; f14cf11a then rekeys the by-name list and adds its failure WARNING), my pass-1 report `api-consistency-review-2026-10-15-q106.md` (context only), and probes PROBE1-4.

**Probes.** `/home/node/.claude/jobs/00bcf178/tmp/q106/apiperf2/run.sh`, run 2026-10-15T12:06:19Z at HEAD f14cf11a under `timeout 600`, exit 0, 4/4 ok. It runs a throwaway copy of `test/install-host.bats` with four `PROBE` tests appended, driving this worktree's `install.sh` under bats' own temp HOME (never the real HOME). Logs are in `…/apiperf2/logs/`:
- `p1-output.txt`, `p1-backup.txt`: a first install into a dir holding only `settings.json`;
- `p2-output.txt`: a merge that unwires nothing;
- `p3-output.txt`: a wiring with an empty hook group;
- `p4-output.txt`, `p4-backup.txt`: a full install plus merge over an existing tree.

T93-T102 were rerun at HEAD (10/10 ok, `logs/suite.txt`).

## Baseline Conventions

These are the pass-1 baseline (`api-consistency-review-2026-10-15-q106.md`, "Baseline Conventions"), rechecked at HEAD:

- **Errors:** `ERROR: <what happened>.` to stderr. Continuation lines are indented 7 spaces, and the last one gives the end state and the action (`install.sh:870-872`, `:1095-1096`, `:1104-1105`). A part-way failure names what is where and how to recover (`host_rollback`, `:779-785`).
- **Non-fatal conditions:** `WARNING:` (`:355`, `:627`, `:944`) or `NOTE:` (`:1354`, `:1365`).
- **Review markers:** an uppercase verb in base form plus its object: `ADD <path> (new, N file(s)):` (`:979`), `REPLACE symlink … with a copy` (`:931`, `:937`), `MOVE to backup (not in the repo): …` / `MOVE link …` (`:948-950`), `MODE <path>: a -> b` (`:428`). Parenthesised notes mark absence or omission: `(none — the destination already matches the repo)` (`:1064`), `(content not shown: …)` (`:986`).
- **Outcome lines:** `Installed into $dest.` (`:1158`), `Previous entries moved to $backup (delete it when satisfied).` (`:1185`), and on decline `Aborted. Nothing was changed. (<target>)` (`:1085`).
- **Help/README contract:** "The backups of the last 3 installs are kept" (`install.sh:43-44`, `README.md:61-62`).
- **Names:** UPPERCASE shell constants, lowercase helper functions (`file_hash`, `vis_or_die`, `confirm`), `.cw-new.*` staging copies, `$HOST_TMP/settings.view.*` scratch files, test titles ending in the question ID.

## Pass-1 findings: status

| Pass-1 # | Finding | Status at f14cf11a |
|---|---|---|
| 1 | Settings-only runs counted toward the last 3 installs | Resolved: unstamped (`:1180-1183`), T94 asserts `settings.json` alone in the newest backup. The new retention is undocumented (Finding 5 below) |
| 2 | Guide's "`-` line means unwired" rule | Resolved: guide §2 points at the by-name list and explains the reorder (`guides/bare-host-hook-wiring.md:53-58`) |
| 3 | Settings-only run said "Install these files" / "Previous entries moved" | Resolved for `files_changed=0`. **Recurs** on a first install, where the backup holds only `settings.json` (Finding 1) |
| 4 | Post-swap failure message | Resolved in content (`:1165-1166`). The shape departs from the two-line ERROR convention (Finding 7) |
| 5 | Unnormalised `HOST_DEST` | Resolved: `s_dir` (`:1012`); T98 passes at HEAD, fails on 05b13d11 (fact-check claim 6) |
| 6 | Checkup guide and 037:58 still said "manual" | Half resolved: the checkup guide is fixed; `037:58` is unchanged (Finding 6) |
| 7 | `NOT merged` lacked `WARNING:` | Resolved (`:1034`; T96, T100) |
| 8 | --help skip list and Needs line | Needs line resolved (`:89`). The skip list is still partial (Finding 4) |
| 9 | Callers validate differently | Accepted (rubric C8); not re-filed |

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `sjq` | shell function | `file_hash`, `vis_or_die`, `confirm` | `devcontainer-config/install.sh:170,439,717` | Consistent: lowercase helper with a header comment giving its contract |
| `ONE_OBJ`, `WIRING_SHAPE` | shell constants | `CLAUDE_HOME_NAMES`, `ADD_MAX_LINES` | `devcontainer-config/install.sh:974` and the top-level arrays | Consistent: UPPERCASE nouns |
| `$s_view.sum` | scratch file | `$s_view.raw`, `$s_view.diff` | `devcontainer-config/install.sh:1021,1051` | Consistent |
| `UNWIRES hook:`, `REMOVES <mode> rule:`, `ADDS <mode> rule:` | review markers | `ADD <path> (new, …)`, `REPLACE symlink …`, `MOVE …`, `MODE …` | `devcontainer-config/install.sh:428,931,948-950,979` | Inconsistent: third-person verbs beside base-form markers; `ADD` and `ADDS` appear in one review (Finding 2) |
| `  WARNING: the by-name list could not be computed; read the whole diff.` | non-fatal line | `WARNING: not in the repo; …` | `devcontainer-config/install.sh:944` | Consistent (indented as part of the list it replaces) |
| `WARNING: settings.json NOT merged: <path>: <why>.` | non-fatal line | `WARNING: … MOVED to the backup (Q-057):` | `devcontainer-config/install.sh:944` | Consistent (pass-1 Finding 7 fixed) |
| `Install this settings.json merge into <file>?`, `Install these files and the settings.json merge into <dest>?` | prompts | `Install these files into $dest?`, `Install this config and bless it?` | `devcontainer-config/install.sh:556,1080` | Consistent: same `Install … into …?` shape, worded from what changed |
| `The previous settings.json is in $backup (delete it when satisfied).` | outcome line | `Previous entries moved to $backup (delete it when satisfied).` | `devcontainer-config/install.sh:1185` | Consistent |
| `ERROR: could not back up/write $settings, so <s_fail>. Rerun install.sh.` | error | `ERROR: …` plus 7-space continuation | `devcontainer-config/install.sh:1095-1096,1104-1105` | Content consistent; one long line instead of the two-line shape (Finding 7) |
| `T99`-`T102 … (Q-106 review A1/A2/A3/pass 2)` | test titles | `T93 … (Q-106)` | `test/install-host.bats:1757-1795` | Consistent. Cosmetic: T102 sits before T101 in the file |

## Findings

#### 1. A first install into a `~/.claude` that holds only `settings.json` says "Previous entries moved" for a backup with no entries in it

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1167-1169`, `devcontainer-config/install.sh:1184-1185`
**Move:** 4. Verify error consistency (message accuracy); recurrence of pass-1 Finding 3
**Confidence:** High (execution-verified, PROBE1; fact-check claim 9 flagged the case statically in its Scope line)
**Legibility-target:** for-author
**Evidence:**
> `      if [ -z "$backup" ]; then backup="$bkroot/$stamp"; if [ -e "$backup" ]; then backup="$backup.$$"; fi; fi`
> `  if [ -n "$backup" ] && [ "$files_changed" -eq 1 ]; then`
> `    echo "Previous entries moved to $backup (delete it when satisfied)."`

The closing lines are keyed on `files_changed`, not on what the backup holds. On a first install, none of the seven entries exists, so `any=0` and no backup is made before the swap. The settings tail then makes one lazily for `settings.json`. Because `files_changed=1`, the run prints the entries line, stamps the directory and rotates against it. PROBE1 (fresh dir with `{"user":"x"}` as `settings.json`) printed `Installed into …`, `Merged hooks/wiring.json into …/settings.json.` and `Previous entries moved to …/20261015T120619Z (delete it when satisfied).` (`p1-output.txt:196-198`). That backup held only `.install-stamp settings.json` (`p1-backup.txt`). This is a common first-install shape: Claude Code creates `settings.json` before the user installs anything. The mirror case loses information. On a full install over an existing tree (PROBE4), the backup does hold `settings.json` (`p4-backup.txt`), but the closing lines only say `Previous entries moved to …` (`p4-output.txt:159-161`). Pass 1's `(the previous file is in $backup)` was dropped, so nothing says the old `settings.json` is in there. Pass 1 recommended gating on `${#moved[@]}`. The fix gated on `files_changed`, which differs exactly in this case.

**Recommendation:** Print `Previous entries moved to $backup …` only when `${#moved[@]} -gt 0`. Print `The previous settings.json is in $backup …` whenever `settings.json` was backed up, alone or beside the entries. Whether a settings-only-content backup on a first install is stamped is a separate choice. Today it is, which is harmless on a first install.

#### 2. The by-name markers use third-person verbs (`UNWIRES`, `REMOVES`, `ADDS`) where every other review marker is a base-form verb, so `ADD` and `ADDS` appear in the same review

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1044-1047`; also pinned in `test/install-host.bats` (T93, T102) and `guides/bare-host-hook-wiring.md:53-57`
**Move:** 2. Check naming against the grain
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> `      | ((($a | cmds) - ($b | cmds))[] | "  UNWIRES hook: " + .),`
> `      echo "ADD $dest/$name (new, $n file(s)):" | vis_or_die`

Precedent: base-form uppercase verb + object (`ADD`, `REPLACE symlink`, `MOVE`, `MODE`) used in `devcontainer-config/install.sh:428,931,937,948-950,979`, and named in `README.md:55-57`.

A first install's review prints `ADD …/skills (new, 3 file(s)):` at column 0 and, further down, `  ADDS allow rule: …` (and `REMOVES` / `UNWIRES`) under the settings heading. The README teaches the reader to scan the review for its markers. A second verb form for the same action makes `ADD` vs `ADDS` look like two different kinds of event, and it gives the new list a different grammar from the lines around it. The colon after the noun (`hook:`, `rule:`) is closest to `MOVE to backup (not in the repo): $f`, so that part has precedent. The impact is cognitive only: no script parses these lines. That is why this is Minor, not Inconsistent.

**Recommendation:** Use `UNWIRE hook:`, `REMOVE <mode> rule:`, `ADD <mode> rule:` (base form, describing what the y will do, like `REPLACE … with a copy`). Update T93, T102 and guide §2 in the same commit. If the third-person form is kept on purpose, say why in the guide.

#### 3. An empty by-name list prints nothing, so "nothing is unwired" looks the same as "no list"

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1039-1048`, `devcontainer-config/install.sh:1054-1056`; reader contract at `guides/bare-host-hook-wiring.md:53-58`
**Move:** 8. Verify the nullability contract (absent vs empty output)
**Confidence:** High (execution-verified, PROBE2)
**Legibility-target:** for-author
**Evidence:**
> `      1) echo "settings.json: the hooks/wiring.json merge this install applies (Q-106; jq rewrites the file's layout):"`
> `         vis_or_die < "$s_view.sum"`
> guide: `` is listed too. Read that list first: the merge moves our groups to the end, so in the ``

When the merge only adds or reorders, `$s_view.sum` is empty, and the heading is followed directly by the `---`/`+++` diff labels (PROBE2, `p2-output.txt:127-131`; the same happens on a first merge, `p1-output.txt:164-168`). The guide tells the reader to "Read that list first", but an empty list has no visible form, so the reader cannot tell whether nothing is unwired or the list is absent. A failed summary is now announced (`WARNING: the by-name list could not be computed`), so the gap is only the empty case. The codebase's convention for an empty review section is an explicit parenthesised line: `(none — the destination already matches the repo)` (`:1064`).

**Recommendation:** When `$s_view.sum` is empty, write `  (none — this merge unwires no hook, removes no rule and adds no non-deny rule)` into it. Add a negative assertion to T98 or T94 so the line is pinned.

#### 4. The shape refusal blames "a hook command" when the cause is an empty group, and `--help` still lists only some of the skip reasons

**Severity:** Minor
**Location:** `devcontainer-config/install.sh:1019-1020`, `devcontainer-config/install.sh:730-732`, `devcontainer-config/install.sh:47-51`
**Move:** 4. Verify error consistency (message accuracy); 3. Trace the consumer contract (documentation drift), partial carry-over of pass-1 Finding 8
**Confidence:** High (execution-verified, PROBE3)
**Legibility-target:** for-author
**Evidence:**
> `    s_why="hooks/wiring.json has a hook command that is not 'bash|python3 {{CLAUDE_DIR}}/hooks/<path>' without '..'"`
> `WIRING_SHAPE='[.hooks[]?[]? | (.hooks // []) | length > 0`
> `     jq is missing, a wiring.json hook command is not `bash|python3`
> `     <dest>/hooks/<path>`, or the merge fails; the review says why. A merge`

`WIRING_SHAPE` also refuses a group with no hooks. PROBE3 (`{"hooks":{"Stop":[{"hooks":[]}]}}`) printed `WARNING: settings.json NOT merged: …: hooks/wiring.json has a hook command that is not 'bash|python3 {{CLAUDE_DIR}}/hooks/<path>' without '..'.` (`p3-output.txt:128`), although the wiring has no command at all. A user debugging that message will look for a malformed command that does not exist. Guide §2 lists the empty group (`:61-62`), but `--help` lists neither it nor the missing-program skip ("the payload has no hooks/wiring.json or hooks/lib/wiring-merge.jq", `:1018`). Help also spells the allowed shape `<dest>/hooks/<path>`, while the warning and the guide spell it `{{CLAUDE_DIR}}/hooks/<path>`. A reader comparing the warning with `--help` sees two forms of the same rule.

**Recommendation:** Word the reason to cover both causes, for example "hooks/wiring.json has an empty hook group, or a command that is not 'bash|python3 {{CLAUDE_DIR}}/hooks/<path>' without '..'". In `--help`, either add "or has an empty group; the payload lacks the merge program" or use the generic "or cannot be merged safely (the review says why)" that pass 1 suggested, and spell the shape the way the warning does.

#### 5. Settings-only backups now sit outside the "last 3 installs" rule, but the README, `--help` and the rotation comment do not say so

**Severity:** Informational
**Location:** `README.md:61-63`, `devcontainer-config/install.sh:43-44`, `devcontainer-config/install.sh:1192-1193`
**Move:** 3. Trace the consumer contract (documentation drift)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> `     <dest>/.claude-workflows-backup/<UTC stamp>/. The backups of the last 3`
> `    # (.install-stamp); a directory without that stamp was not made by a`
> `    # completed install and is never removed.`

The fix for pass-1 Finding 1 is right. Its consequence is that every settings-only run leaves an unstamped directory that is never removed (performance pass-2 Finding 1). The run's own line says "delete it when satisfied", so the user is told at the time. The standing docs still state only the keep-3 rule, and the rotation comment now gives the wrong reason why an unstamped directory exists: a completed settings-only run makes one on purpose.

**Recommendation:** Add one clause to the README and `--help`: "a settings.json-only run's backup is kept until you delete it". Change the comment to "…was not made by a completed entries install (a failed run, or a settings-only backup) and is never removed".

#### 6. Decision 037's Consequences line still says the settings merge is manual (pass-1 Finding 6, second half)

**Severity:** Minor
**Location:** `docs/decisions/037-bare-host-copy-install.md:58`
**Move:** 3. Trace the consumer contract (documentation drift)
**Confidence:** High
**Legibility-target:** for-author
**Evidence:**
> `` Every plain run asks a second question. The settings merge is still manual, and a changed `wiring.json` is only announced, not applied. ``
> `` *Superseded 2026-10-15: the host target now runs that merge inside its review (Q-106 [2]); see the amendment at the end.* ``

The rubric's C4 disposition fixed the checkup guide but not this line, and nothing in `05b13d11..HEAD` touches it. The Decision-section line (`:37`) carries the established italic *Superseded* marker, and the Consequences line does not. The amendment's Q-108 note still says the stale lines "under Decision and Consequences are corrected in place".

**Recommendation:** Append the same `*Superseded 2026-10-15: …*` marker after that sentence at `:58`.

#### 7. The new post-swap ERROR is one long line, not the ERROR-plus-continuation shape its siblings use

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:1165-1176`
**Move:** 4. Verify error consistency (message shape)
**Confidence:** High (static)
**Legibility-target:** for-author
**Evidence:**
> `    if [ "$files_changed" -eq 1 ]; then s_fail="$s_fail; the files above WERE installed${backup:+, their previous versions are in $backup}"; fi`
> `        echo "ERROR: could not back up $settings, so $s_fail. Rerun install.sh." >&2`

Fully expanded, this prints `ERROR: could not back up <path>/settings.json, so it was not changed; the files above WERE installed, their previous versions are in <path>/.claude-workflows-backup/<stamp>. Rerun install.sh.` on one line of roughly 200 characters. Every other multi-clause error in the function puts the failure on the `ERROR:` line and the end state plus action on 7-space-indented continuation lines (`:870-872`, `:1095-1096`, `:1104-1105`, `host_rollback` `:779-785`). The content is now right (pass-1 Finding 4), so only the shape differs.

**Recommendation:** Optional. Split it into `ERROR: could not back up $settings; it was not changed.` and a continuation line `       The files above WERE installed; their previous versions are in $backup. Rerun install.sh to merge settings.json.`

## What Looks Good

- **Pass-1 wording findings are fixed in the codebase's own idiom.** `WARNING: settings.json NOT merged` takes the severity prefix. The settings-only prompt and outcome line (`Install this settings.json merge into …?`, `The previous settings.json is in $backup (delete it when satisfied).`) copy the shape of their entries siblings. The decline line is unchanged.
- **The prompt names what the y covers.** There are three variants, chosen from `files_changed` and `s_new_hash`, so a settings merge is never hidden behind "Install these files". T94 pins the settings-only variant.
- **The summary's failure mode is announced, not silent.** It prints an indented `WARNING:` line that tells the reader to fall back to the diff (rubric P2-4).
- **The by-name key `<event> [<matcher>] <command>`** is documented with an example in guide §2, which matches the code's format exactly. T102 pins the matcher case.
- **New helpers and constants follow the naming grain** (`sjq`, `ONE_OBJ`, `WIRING_SHAPE`, `$s_view.sum`), and each new test title cites the review item it closes.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | First install with only `settings.json` says "Previous entries moved"; full install omits that `settings.json` is in the backup | Minor | `devcontainer-config/install.sh:1167-1169,1184-1185` | High |
| 2 | `UNWIRES`/`REMOVES`/`ADDS` vs base-form `ADD`/`REPLACE`/`MOVE`/`MODE` | Minor | `devcontainer-config/install.sh:1044-1047` | High |
| 3 | Empty by-name list prints nothing; no `(none — …)` line | Minor | `devcontainer-config/install.sh:1039-1056` | High |
| 4 | Empty-group refusal blamed on a hook command; `--help` skip list partial and shape spelled differently | Minor | `devcontainer-config/install.sh:1019-1020,47-51` | High |
| 5 | Settings-only backups outside keep-3, undocumented; rotation comment stale | Informational | `README.md:61-63`; `devcontainer-config/install.sh:43-44,1192-1193` | High |
| 6 | Decision 037:58 still says "manual" | Minor | `docs/decisions/037-bare-host-copy-install.md:58` | High |
| 7 | Post-swap ERROR is one long line, not ERROR + continuation | Informational | `devcontainer-config/install.sh:1165-1176` | High |

## Overall Assessment

This range resolves pass-1 Findings 1, 2, 5 and 7 outright, Finding 4 in content and Finding 3 for the case it named, and the new names and prompts match their neighbours. What remains is wording and docs, all fixable in place:
- **Finding 1** is the same wrong "Previous entries moved" line pass 1 found, now on the first-install path, because the fix gated on `files_changed` rather than on what was moved. It is the most user-visible item.
- **Findings 2 and 3** concern the new by-name list, which the guide now names as the thing to read first. Its verbs differ from the review's other markers, and its empty state is invisible.
- **Finding 4** is a refusal reason that blames the wrong thing on one input.
- **Findings 5-7** are doc drift and message shape.

None is Breaking or Inconsistent. Consumer impact before fixing: a first-time user is told entries moved when none did, and a reader cannot tell an empty by-name list from a missing one.

## Goal-Alignment Note
- Success criterion (restated verbatim): "(2) API consistency per … SKILL.md → docs/reviews/api-consistency-review-2026-10-15-q106-pass2.md"; "Verify your pass-1 findings are resolved and check the new user-facing strings (prompt variants, WARNING lines, UNWIRES format, --help) for consistency with the script's conventions"; first line `Commit: <HEAD short sha>`.
- Answered: yes. A status table covers every pass-1 finding: 4 resolved, 2 resolved with a remainder, 1 half, 1 partial, 1 accepted. Prompt variants, both WARNING lines, the UNWIRES/REMOVES/ADDS format, `--help` and the ERROR variants are each audited. There are 7 findings, 3 of them execution-verified by PROBE1-3.
- Out of scope: whether a first-install backup holding only `settings.json` should be stamped (a retention-policy choice, noted in Finding 1); the security weight of the by-name list (security reviewer).
- Escalate: none beyond the findings. Finding 1 is the one I would fix before merging, because it repeats a pass-1 message bug on the most common first-install shape.
- Decisions I made: I rated Finding 2 Minor rather than Inconsistent, because nothing parses the markers and the cost is scanning load. I treated the empty-list gap (Finding 3) as a nullability contract, not a naming one, so it carries no precedent line, though I cite `(none — …)` as the convention.
