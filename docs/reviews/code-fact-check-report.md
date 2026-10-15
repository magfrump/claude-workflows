# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q106`, branch `feat/q106-host-settings-merge`)
**Scope:** range `git diff 05b13d11..HEAD` (commits f7680e0d, d53d2bf4, a4f3614a; code and docs files: `devcontainer-config/install.sh`, `devcontainer-config/link-claude-home.sh`, `docs/decisions/037-bare-host-copy-install.md`, `docs/working/plan-q106-host-settings-merge.md`, `guides/bare-host-hook-wiring.md`, `guides/claude-config-security-checkup.md`, `hooks/lib/wiring-merge.jq`, `test/install-host.bats`), the messages of d53d2bf4 and a4f3614a, and the rubric's "Iteration 1 fix dispositions" table; `184396ea..05b13d11` read as context only; delivery mode self-read
**Checked:** 2026-10-15
**Total claims checked:** 38
**Summary:** 27 verified, 8 mostly accurate, 1 stale, 2 incorrect, 0 unverifiable
**Commit:** a4f3614a
**Replication:** k=1 (loop pass, decision 031)

Hallucination-pattern log read first (`docs/reviews/hallucination-patterns.md`, 5 entries). No claim asserts a symbol or API that does not exist. Claim 32b ("each new or changed assertion fails on 05b13d11") closely resembles the logged "All 85 tests … pass" class: a claim about test results that the tests do not bear out. It is a behavioural over-claim, not a fabricated symbol, and the rules for this pass allow no edits to tracked files except this report, so no log entry was added. The caller decides.

**Execution logs.** Raw output lives outside the repo in `/home/node/.claude/jobs/00bcf178/tmp/q106/fc2/logs/` (`$L/` below). The scripts sit next to it in `/home/node/.claude/jobs/00bcf178/tmp/q106/fc2/` (`$P/`). Each install run used bats' own temp HOME (`export HOME="$S/home"`, `test/install-host.bats:25`), never the real HOME or `~/.claude`. Each run was wrapped in `timeout`, ran in the foreground, and had exited before this report was written.

- `$P/run_tests.sh` (cwd `/workspace/.claude/wt-q106`, start 2026-10-15T11:55:35Z, end 11:56:04Z):
  - `LC_ALL=C bats -f 'T9[3-9]|T10[01]' test/install-host.bats`: exit 0, 9/9 ok (`$L/head-install-host.txt`).
  - `LC_ALL=C bats test/link-claude-home-wiring.bats`: exit 0, 16/16 ok (`$L/head-link.txt`).
  - It builds `$P/oldtree` (`git archive HEAD`, then 05b13d11's `install.sh`, `wiring-merge.jq` and `link-claude-home.sh` copied over it) and runs each of HEAD's T93, T94, T96, T98, T99, T100 and T101 there (cwd `$P/oldtree`). Each exits 1 (`$L/old-T*.txt`). The first failing lines are T93 :1659, T94 :1694, T96 :1725, T98 :1753, T99 :1764, T100 :1774 and T101 :1784.
- `$P/t93_variant.sh` (cwd `$P/oldtree`, 2026-10-15T11:56:22Z): HEAD's T93 with line 1659 deleted, run against 05b13d11's code. Exit 0 (`$L/old-T93-minus1659.txt`).
- `$P/probe_jq.sh` (cwd `$P/probe`, 2026-10-15T11:56:51Z): exit 0 (`$L/probe_jq.txt`). It extracts `sjq`, `ONE_OBJ` and `WIRING_SHAPE` verbatim from `install.sh`, and the summary program verbatim from `install.sh:1037-1042`, then runs them against the real `hooks/wiring.json` and crafted inputs. It also runs `hooks/lib/wiring-merge.jq` and jq 1.6's `~/.jq` loading against a fake HOME.
- `$P/gate.sh` (cwd `/workspace/.claude/wt-q106`, 2026-10-15T11:58:15Z): `bats -f 'install.sh is gated although it is not manifest-hashed' test/hooks/live-verify-gate.bats`, exit 0 (`$L/gate.txt`).

---

## Claim 1: "Never written when it is a symlink, unreadable or not one JSON object, jq is missing, wiring.json names a hook outside <dest>/hooks, or the merge fails (the review says why and lists what it unwires or removes)."

**Location:** `devcontainer-config/install.sh:47-49`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the --help list of skip reasons against the `s_why` chain at `:1011-1029`; does not establish the wording of each skip message, and does not cover the empty-group refusal, which the help leaves out.

The listed skip reasons all exist in `install_claude_home`: a symlink or non-regular file (`:1011`), jq missing (`:1013`), the shape refusal (`:1017`), unreadable (`:1019-1020`, `s_why="it could not be read"`), not one object (`:1021`) and merge failure (`:1023-1028`). Two parts are imprecise:

- "names a hook outside <dest>/hooks" understates the check. `WIRING_SHAPE` (`:728-730`) also refuses a command inside `{{CLAUDE_DIR}}/hooks` that contains `..` or any character outside `[A-Za-z0-9_./-]`, an interpreter other than `bash` or `python3`, and a group with no hooks: `` `(.hooks // []) | length > 0 and all(.command | type == "string" and (contains("..") | not) and test("^(bash|python3) …` ``.
- The parenthetical "the review says why and lists what it unwires or removes" sits in the refusal sentence, but the list prints only on the merged path. The refusal branch prints the reason alone: `rm -f "$snew"; echo "WARNING: settings.json NOT merged: $settings: $s_why." | vis_or_die` (`:1031-1032`). The `UNWIRES`/`REMOVES` summary is computed in the `else` branch (`:1033-1042`) and printed only in `case 1)` (`:1049`).

**Evidence:** `devcontainer-config/install.sh:47-49`, `devcontainer-config/install.sh:728-730`, `devcontainer-config/install.sh:1011-1056`

---

## Claim 2: "Without jq the settings.json merge is skipped."

**Location:** `devcontainer-config/install.sh:87`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the host target's settings block; does not establish what the container side (`link-claude-home.sh:101-102`) does, though it also skips.

`elif ! command -v jq >/dev/null 2>&1; then s_why="jq is not installed"` (`devcontainer-config/install.sh:1013-1014`). A non-empty `s_why` leads to `WARNING: settings.json NOT merged` and no `snew` (`:1030-1032`). The files target still proceeds.

**Evidence:** `devcontainer-config/install.sh:1013-1014`, `devcontainer-config/install.sh:1030-1032`

---

## Claim 3: "sjq <args...>: jq for the settings merge (Q-106), with HOME and the environment emptied, so no ~/.jq library (jq 1.6 loads it) or env value shapes the result (review A3), and with its stderr dropped, so it never reaches the terminal."

**Location:** `devcontainer-config/install.sh:719-722`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers jq 1.6's `$HOME/.jq` auto-load and the `env -i` wrapper for every settings-block jq call in `install.sh`; does not establish that jq's `$ORIGIN/../lib` module paths are excluded (the merge program uses no `import`/`include`, so they are never consulted).

`sjq() { env -i PATH="$PATH" HOME=/nonexistent jq "$@" 2>/dev/null; }` (`:722`). Every jq call in the settings block goes through `sjq` (`:1017`, `:1021`, `:1024-1027`, `:1036`). A grep for bare `jq` in `install.sh` finds only comments, `command -v jq` and strings (paraphrased — no quote available because the claim covers the absence of other call sites; the grep output is reproduced by `$P/s2.sh`). HOME is set to `/nonexistent`, not left unset. That matters: the probe shows jq 1.6 loading a fake `~/.jq` that redefines `walk` (`{}` out), while `env -i … HOME=/nonexistent jq` gives `{"a":{"b":1}}` (`$L/probe_jq.txt`). T101 passes at HEAD and fails on 05b13d11 at `:1784`.

**Evidence:** `devcontainer-config/install.sh:719-722`, `devcontainer-config/install.sh:1017-1042`, `test/install-host.bats:1780-1786`, `$L/probe_jq.txt`, `$L/head-install-host.txt`, `$L/old-T101.txt`

---

## Claim 4: "Every wiring hook group has a hook, and every command is `bash|python3 {{CLAUDE_DIR}}/hooks/<path>` with no `..` or shell syntax"

**Location:** `devcontainer-config/install.sh:724-730`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `WIRING_SHAPE` accepts and refuses for `.hooks` commands, and that the real `hooks/wiring.json` passes; does not establish anything about wiring `permissions` rules, which the check does not constrain (they surface only as `ADDS` lines), nor the container path, which does not run the check (claim 34).

```
WIRING_SHAPE='[.hooks[]?[]? | (.hooks // []) | length > 0
   and all(.command | type == "string" and (contains("..") | not)
           and test("^(bash|python3) \\{\\{CLAUDE_DIR\\}\\}/hooks/[A-Za-z0-9_./-]+$"))] | all'
```
(`devcontainer-config/install.sh:728-730`)

Probe results (`$L/probe_jq.txt`):

- The real `hooks/wiring.json` gives `true`.
- Accepted: `bash {{CLAUDE_DIR}}/hooks/h.sh` and `python3 {{CLAUDE_DIR}}/hooks/a/b.py`.
- Refused: `../x`, `h.sh; curl x`, `h.sh x` (a space), a null command, an empty `hooks` list, and a group with no `hooks` key.
- A newline mid-string is refused in either order (`h.sh\ncurl evil` and `curl evil\nh.sh`), so jq 1.6's `^…$` does not act as a per-line anchor here.

Two edge acceptances do not contradict the comment:

- A single trailing newline (`h.sh\n`) passes. It adds no second command.
- A group whose `hooks` is an object rather than a list passes, but `all(...)` still checks each value's `.command`.

**Evidence:** `devcontainer-config/install.sh:724-730`, `devcontainer-config/install.sh:1017-1018`, `hooks/wiring.json`, `$L/probe_jq.txt`

---

## Claim 5: "umask 077: settings can hold secrets; the merged copy then gets the live file's mode. The live file is read once, into $s_view.raw: the check, the hash and the merge all read that copy."

**Location:** `devcontainer-config/install.sh:1005-1007`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the content reads of `settings.json` between the review and the prompt; does not establish atomicity of the separate `stat` (metadata) read against the `cp`, and does not cover the post-y hash, which reads the live file on purpose to detect edits.

- Read once: `s_mode="$(stat -c %a "$settings")" && (umask 077; cp "$settings" "$s_view.raw")` (`:1019`).
- Checked: `sjq -se "$ONE_OBJ" "$s_view.raw"` (`:1021`).
- Merged: `sjq . "$s_view.raw"` then `> "$s_view"`, and the merge reads `"$s_view"` (`:1024-1026`).
- Hashed: `s_old_hash="$(file_hash "$s_view.raw")"` (`:1051`).
- Mode: `|| ! chmod "$s_mode" "$snew"` (`:1027`), with `s_mode=600` as the default for a new file (`:1009`).

The rename at `:1168` (`mv -f "$snew" "$settings"`) carries that mode. T93 (640 kept) and T98 (new file 600) pass at HEAD.

**Evidence:** `devcontainer-config/install.sh:1005-1029`, `devcontainer-config/install.sh:1051`, `devcontainer-config/install.sh:1168`, `$L/head-install-host.txt`

---

## Claim 6: "no trailing slash in the paths it writes (review C1)"

**Location:** `devcontainer-config/install.sh:1010`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--arg dir` for the host merge when `CLAUDE_HOME_DIR` ends in `/`; does not establish symlink resolution (bash `pwd` is logical, so a symlinked destination keeps its link path), nor the container's `$DEST`.

`s_dir="$(cd "$dest" && pwd)"` (`:1010`), passed as `sjq --arg dir "$s_dir"` (`:1025`). T98 runs with `CLAUDE_HOME_DIR="$CLAUDE_HOME_DIR/"` (`test/install-host.bats:1750`). It passes at HEAD and fails on 05b13d11 at `:1753`, where the old `--arg dir "$dest"` wrote `…//hooks/h.sh`.

**Evidence:** `devcontainer-config/install.sh:1010`, `devcontainer-config/install.sh:1025`, `test/install-host.bats:1748-1756`, `$L/old-T98.txt`

---

## Claim 7a: "A reorder shows as -/+ in the diff below but never here."

**Location:** `devcontainer-config/install.sh:1035`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reordered groups and rules; does not establish behavior for duplicates (array subtraction removes every equal element, so collapsing a duplicated command is not listed either).

`((($a | cmds) - ($b | cmds))[] | "  UNWIRES hook: " + .)` (`:1039`) is a set-style difference, so order cannot produce a line. The probe swaps the two `PreToolUse` groups and gets no output (`$L/probe_jq.txt`, "reorder only"). T93's negative assertion (`:1660`) also passes at HEAD.

**Evidence:** `devcontainer-config/install.sh:1036-1042`, `test/install-host.bats:1660`, `$L/probe_jq.txt`

---

## Claim 7b: "Review A2/A7: what the y would unwire, remove or newly allow, listed by name."

**Location:** `devcontainer-config/install.sh:1034`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers hook commands that disappear from the settings file and rules that disappear from, or newly appear in, any `permissions` mode; does not establish a list entry when a command stays in the file but stops firing where it did (matcher retargeted, or moved to another event), nor any notice when the summary program fails.

```
def cmds: [.hooks[]?[]?.hooks[]?.command]; def rules(m): [.permissions[m]?[]?];
$o[0] as $a | $n[0] as $b
| ((($a | cmds) - ($b | cmds))[] | "  UNWIRES hook: " + .),
  (($a.permissions // {} | keys[]) as $m | (($a | rules($m)) - ($b | rules($m)))[] | "  REMOVES \($m) rule: " + .),
  (($b.permissions // {} | keys[] | select(. != "deny")) as $m
   | (($b | rules($m)) - ($a | rules($m)))[] | "  ADDS \($m) rule: " + .)' > "$s_view.sum" || true
```
(`devcontainer-config/install.sh:1037-1042`)

`cmds` flattens every event and drops matchers, so the list keys on the command string only. Probe results (`$L/probe_jq.txt`):

- `python3 /h/.claude/hooks/guard.py` with its matcher changed from `Edit|Write` to `Nope` prints nothing.
- The same command moved from `PreToolUse` to `Stop` prints nothing.

In both cases the hook no longer guards what it did, and only the diff shows it. That is the hostile-branch case of plan row 3.

The summary's failure is also silent:

- A user `settings.json` whose hook `command` is a number makes the program exit 5 with no output (`$L/probe_jq.txt`, "numeric command").
- `sjq` drops stderr and `|| true` swallows the exit, so the review shows the diff with no by-name list and no note that the list is missing.

Legacy-form labelling is literal, not wrong. A replaced single-slash deny rule shows as `REMOVES deny rule: Edit(/h/.claude/settings*.json)`, with no paired line for its `//` replacement, because `ADDS` excludes `deny` (`:1041`). It does not list a reorder (claim 7a).

**Evidence:** `devcontainer-config/install.sh:1034-1042`, `devcontainer-config/install.sh:1049`, `$L/probe_jq.txt`

---

## Claim 8: "back up right before the rename (the backup dir is made here if no entry needed one), so an edit since the check is kept there; -P copies a planted link as a link and mv replaces it."

**Location:** `devcontainer-config/install.sh:1155-1157`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the settings write tail; does not establish behavior under a concurrent writer between `cp -pP` and `mv` (an edit in that window is lost from the live file but not from the backup only if it landed before the `cp`).

```
if [ -e "$settings" ] || [ -L "$settings" ]; then
  if [ -z "$backup" ]; then backup="$bkroot/$stamp"; if [ -e "$backup" ]; then backup="$backup.$$"; fi; fi
  if ! mkdir -p "$backup" || ! cp -pP "$settings" "$backup/settings.json"; then
```
(`devcontainer-config/install.sh:1161-1163`), followed by `if ! mv -f "$snew" "$settings"` (`:1168`).

**Evidence:** `devcontainer-config/install.sh:1155-1173`

---

## Claim 9: "Review A6: not stamped, so it never counts among (or prunes) the 3 kept."

**Location:** `devcontainer-config/install.sh:1175`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers settings-only runs (`files_changed=0`); does not cover a first install with `files_changed=1` and no earlier entries, where the lazily made backup holds only `settings.json` yet is stamped, pruned against and announced as "Previous entries moved to".

The stamp and the prune sit only in `if [ -n "$backup" ] && [ "$files_changed" -eq 1 ]; then` (`:1178`, stamp at `:1188`). The prune skips unstamped directories: `[ -f "$d/.install-stamp" ] || continue` (`:1199`). T94's `[ "$(ls -A "$newest")" = settings.json ]` passes at HEAD and fails on 05b13d11 at `:1694`.

**Evidence:** `devcontainer-config/install.sh:1174-1205`, `test/install-host.bats:1694`, `$L/old-T94.txt`

---

## Claim 10: Both callers run the merge with HOME and the environment emptied (d53d2bf4 "A3"; 037 :102; wiring-merge.jq :12-14), container side

**Location:** `devcontainer-config/link-claude-home.sh:115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merge invocation; does not cover the two count-only jq calls at `:118-119`, which still run plain `jq` (their output reaches only the "wired N hook command(s)" message), and does not establish that the container still wires in a real container (the commit's own `Live-verified: no` owes that).

`if env -i PATH="$PATH" HOME=/nonexistent jq --arg dir "$DEST" --slurpfile w "$WIRING" -f "$MERGE" \` (`devcontainer-config/link-claude-home.sh:115`). By contrast `echo "link-claude-home: wired $(jq -r '[.hooks[][]?.hooks[]?] | length' "$SETTINGS") …"` (`:118`) is unwrapped. `test/link-claude-home-wiring.bats` passes 16/16.

**Evidence:** `devcontainer-config/link-claude-home.sh:108-119`, `$L/head-link.txt`

---

## Claim 11: "Both run jq with HOME and the environment emptied … both callers stay in the gate, and neither reads it from the checkout."

**Location:** `docs/decisions/037-bare-host-copy-install.md:102`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two callers' jq wrapper (claims 3, 10), their presence in the gate regex and the merge-program source paths; does not establish that `wiring-merge.jq` itself is gated (it is not, as the same entry's Residuals line says).

The gate regex includes both callers: `enforcement='^devcontainer-config/(…|link-claude-home\.sh|cc-isolated\.sh|install\.sh$|egress/)'` (`hooks/live-verify-gate.sh:83`). Each caller reads the merge program from a staged or packaged copy:

- Host: `-f "${new}hooks/lib/wiring-merge.jq"` (`install.sh:1026`), where `new="$dest/.cw-new."` (`:906`) holds the copies made from the `git archive` stage (`:892-895`).
- Container: `MERGE="$SRC/hooks/lib/wiring-merge.jq"` (`link-claude-home.sh:92`).

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:102`, `hooks/live-verify-gate.sh:83`, `devcontainer-config/install.sh:892-906`, `devcontainer-config/install.sh:1026`, `devcontainer-config/link-claude-home.sh:92`

---

## Claim 12: "The host target refuses a wiring.json whose hook commands are not bash or python3 {{CLAUDE_DIR}}/hooks/<path> without `..`. The review lists by name each hook command the merge unwires and each rule it removes or newly allows. A settings-only backup is not stamped…"

**Location:** `docs/decisions/037-bare-host-copy-install.md:103`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the amendment's four statements against claims 4, 7b, 9 and 31; does not establish more than those claims do.

The prune, refusal and stamping statements match the code (claims 31, 4, 9). The by-name sentence carries claim 7b's residue: a retargeted matcher or an event move is not listed (`cmds: [.hooks[]?[]?.hooks[]?.command]`, `install.sh:1037`).

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:103`, `devcontainer-config/install.sh:1037-1042`

---

## Claim 13: "Not written when the file is a symlink, is not one JSON object, `jq` is missing, or the merge fails"

**Location:** `docs/decisions/037-bare-host-copy-install.md:105`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the enumerated skip list against `install.sh:1011-1029`; does not establish the REMINDER sentence, which still holds (`:1206-1211`).

This bullet was not edited in d53d2bf4, and the code now has two more skip reasons:

- the shape refusal: `elif ! sjq -e "$WIRING_SHAPE" …; then s_why="hooks/wiring.json has a hook command that is not …"` (`install.sh:1017-1018`);
- unreadable: `s_why="it could not be read"` (`:1020`).

The next bullet (`:103`) mentions the refusal. The --help (`install.sh:47-49`) and guide §2 (`:58`) lists were both updated.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:105`, `devcontainer-config/install.sh:1017-1020`

---

## Claim 14: "a committed `wiring.json` that drops a hook, or adds allow rules, is caught only by reading the review (its by-name list) … The merge program now sits outside `live-verify-gate.sh`'s regex"

**Location:** `docs/decisions/037-bare-host-copy-install.md:106`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the residual's mechanism and the gate-regex fact; does not establish the trust-manifest hashing clause (unchanged context, not re-checked here).

- Gate regex: Verified. `wiring-merge.jq` matches neither `enforcement` nor `host_tools` (`hooks/live-verify-gate.sh:83`, `:91`).
- "its by-name list": catches a dropped command but not a hook neutered by a matcher or event change (claim 7b), which only the diff shows.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:106`, `hooks/live-verify-gate.sh:83-91`, `devcontainer-config/install.sh:1037`

---

## Claim 15: "the regex landed in addae610 (2026-09-26) and `test/hooks/live-verify-gate.bats` ("install.sh is gated although it is not manifest-hashed") pins install.sh's coverage" / "The first revisit trigger fired when Q-049 was answered (2026-09-23)"

**Location:** `docs/decisions/037-bare-host-copy-install.md:100`, `docs/decisions/037-bare-host-copy-install.md:108`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit date, the test's existence, name and pass status, and Q-049's answer date; does not establish what the test asserts beyond its name. The Q-108 paragraph is context (unchanged in this range), checked on request.

- The commit: `git log -1 addae610` prints `addae610 2026-09-26 fix(hooks): gate install.sh commits on Live-verified, as decision 035 chose`.
- The test: `@test "install.sh is gated although it is not manifest-hashed (decision 035)"` (`test/hooks/live-verify-gate.bats:146`). The doc quotes the name without the "(decision 035)" suffix. It passes (`$L/gate.txt`).
- Q-049: `**Answered 2026-09-23, run 3: single-slash rules match nothing; …**` (`docs/working/questions-archive.md:1241`).

**Evidence:** `test/hooks/live-verify-gate.bats:146`, `docs/working/questions-archive.md:1241`, `$L/gate.txt`

---

## Claim 16a: Rubric dispositions "Fixed" for A1, A3, A6, A9, A10, C1

**Location:** `docs/reviews/code-review-rubric-2026-10-15-feat-q106-host-settings-merge.md:63-73`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fix being present in the code, and its named test passing at HEAD and failing on 05b13d11 where one is named; does not establish that T93 discriminates A9 (its 640 assertion also passes on 05b13d11, claim 32b).

- A1: scoped prune `map(select(contains("(/" + $dir + "/")) | sub(…))` (`wiring-merge.jq:53`). T99 passes at HEAD and fails on old code.
- A3: `env -i … HOME=/nonexistent` (claims 3, 10). T101 passes at HEAD and fails on old code.
- A6: claim 9. T94 passes at HEAD and fails on old code.
- A9: mode read at review (`install.sh:1019`, `:1027`).
- A10: one read, `ONE_OBJ` re-check of `$snew` (`:1027`), lazy `mkdir -p "$backup"` and `cp -pP` (`:1162-1163`).
- C1: claim 6.

**Evidence:** `hooks/lib/wiring-merge.jq:47-55`, `devcontainer-config/install.sh:1009-1029`, `devcontainer-config/install.sh:1158-1177`, `$L/head-install-host.txt`, `$L/old-T94.txt`, `$L/old-T99.txt`, `$L/old-T101.txt`

---

## Claim 16b: Rubric A2 "Fixed: host refuses wiring commands not `bash|python3 {{CLAUDE_DIR}}/hooks/<path>` (no `..`, no shell syntax, no empty group); the review lists `UNWIRES hook:` / `REMOVES … rule:` / `ADDS … rule:`; the prompt names the settings merge"

**Location:** `docs/reviews/code-review-rubric-2026-10-15-feat-q106-host-settings-merge.md:64`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal (claim 4), the summary (claim 7b) and the prompt text (`install.sh:1074-1076`); does not establish that the list closes the composed A2+A7 root ("the review gives no explicit list of removed hook commands"), because matcher and event changes stay `-`/`+`-only.

The refusal and the prompt are present: `q="Install this settings.json merge into $settings?"` and `q="Install these files and the settings.json merge into $dest?"` (`install.sh:1075-1076`). T100 passes at HEAD and fails on 05b13d11 at `:1774`. The list has claim 7b's gap.

**Evidence:** `devcontainer-config/install.sh:1017`, `devcontainer-config/install.sh:1037-1042`, `devcontainer-config/install.sh:1074-1076`, `$L/old-T100.txt`, `$L/probe_jq.txt`

---

## Claim 17: Plan row 2: "Rules are subtracted only when equal to one of ours (re-added) or the legacy single-slash form of one of ours **under `$dir`** … A rule absent from the new wiring is never subtracted. T99 asserts both"

**Location:** `docs/working/plan-q106-host-settings-merge.md:39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the jq subtraction and T99's two assertions; does not cover a wiring rule containing `..` after `$dir/`, which is still textually "under `$dir`" (`contains`, not a path check).

`(((.permissions[$mode] // []) - $wiring.permissions[$mode] - ($wiring.permissions[$mode] | map(select(contains("(/" + $dir + "/")) | sub("\\(//"; "(/")))) + $wiring.permissions[$mode])` (`hooks/lib/wiring-merge.jq:51-54`).

- The probe keeps a user's `Read(/secrets/**)` beside the wiring's `Read(//secrets/**)` and drops `Edit(/h/.claude/settings*.json)`.
- The sibling-prefix `/h/.claude-x` is not pruned.
- T99 asserts `Read(/secrets/**)` and `Edit(/$d/old*.json)` both survive (`test/install-host.bats:1770`).

**Evidence:** `hooks/lib/wiring-merge.jq:47-55`, `test/install-host.bats:1763-1771`, `$L/probe_jq.txt`

---

## Claim 18: Plan row 3: "The review lists each unwired command by name (`UNWIRES hook:`), and removed and newly allowed rules, above the diff (T93); reorders do not appear there"

**Location:** `docs/working/plan-q106-host-settings-merge.md:40`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the list for dropped commands and reorders; does not establish coverage of the row's own threat when the hostile wiring keeps `guard-trusted-writes.py`'s command but changes its matcher or event.

The statements about T93 and reorders hold (`test/install-host.bats:1659-1660`, claim 7a). The row's threat is a hostile branch unwiring the guard. A wiring that keeps the command string but sets its matcher to `Nope` produces no `UNWIRES` line (claim 7b probe). The row's "covered by review only" is right, but only the diff, not the list, carries that case.

**Evidence:** `docs/working/plan-q106-host-settings-merge.md:40`, `devcontainer-config/install.sh:1037-1039`, `$L/probe_jq.txt`

---

## Claim 19: Plan row 5: "install.sh refuses the merge unless every command is `bash` or `python3` `{{CLAUDE_DIR}}/hooks/<path>` with no `..` and every group has a hook (… T100)"

**Location:** `docs/working/plan-q106-host-settings-merge.md:42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal (claim 4); does not establish that T100 tests every refused shape (it tests only `..` and `; curl x`; empty groups, other interpreters and paths outside hooks are covered only by this pass's probe).

`for cmd in 'bash {{CLAUDE_DIR}}/hooks/../../tmp/x.py' 'bash {{CLAUDE_DIR}}/hooks/h.sh; curl x'; do` (`test/install-host.bats:1776`).

**Evidence:** `devcontainer-config/install.sh:728-730`, `test/install-host.bats:1774-1783`, `$L/probe_jq.txt`

---

## Claim 20: Plan row 7: "Both callers run jq with HOME and the environment emptied (review loop 1, security F3; T101)"

**Location:** `docs/working/plan-q106-host-settings-merge.md:44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as claims 3 and 10; T101 exercises only the host caller.

See claims 3 and 10. T101 passes at HEAD and fails on 05b13d11 (`$L/old-T101.txt`).

**Evidence:** `devcontainer-config/install.sh:722`, `devcontainer-config/link-claude-home.sh:115`, `$L/old-T101.txt`

---

## Claim 21: Plan row 8: "T1/T2/T4/T22 run without the merge program, so they would not catch a merge moved above them"

**Location:** `docs/working/plan-q106-host-settings-merge.md:45`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether those four tests call `with_merge`; does not establish what else they assert.

None of the bodies of T1, T2, T4 or T22 calls `with_merge` (paraphrased — no quote available because the claim covers absence; `awk` over those four test bodies counts 0 `with_merge` lines, `$P/s2.sh`). `with_merge` is what copies the program in: `cp "$BATS_TEST_DIRNAME/../hooks/lib/wiring-merge.jq" "$ROOT/hooks/lib/"` (`test/install-host.bats:1631`).

**Evidence:** `test/install-host.bats:1630-1635`

---

## Claim 22: Plan row 11: "A planted `.cw-new.settings.json` link is refused like the other `.cw-new.*` names (code; untested)"

**Location:** `docs/working/plan-q106-host-settings-merge.md:48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guard and the absence of a test; does not establish the refusal at run time.

`for name in "${CLAUDE_HOME_NAMES[@]}" manifest settings.json; do if [ -L "$dest/.cw-new.$name" ]; then host_refuse …` (`install.sh:836-838`). The only test references to `.cw-new.settings.json` are absence checks and T95's tamper (`test/install-host.bats:1653`, `:1672`, `:1709`).

**Evidence:** `devcontainer-config/install.sh:836-840`, `test/install-host.bats:1653`, `test/install-host.bats:1709`

---

## Claim 23: Plan row 14: "Created under umask 077, then given the live file's mode read at review (T93 asserts 640 kept; T98: a new file is 600)"

**Location:** `docs/working/plan-q106-host-settings-merge.md:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism and that both assertions exist and pass; does not establish that T93 distinguishes read-at-review from 05b13d11's copy-at-write (`chmod --reference`), which also keeps 640.

The mechanism is in claim 5. `[ "$(stat -c %a "$sf")" = 640 ]` (`test/install-host.bats:1670`) and `[ "$(stat -c %a "$sf")" = 600 ]` (`:1755`) pass at HEAD. T93 without line 1659 also passes on 05b13d11 (`$L/old-T93-minus1659.txt`).

**Evidence:** `devcontainer-config/install.sh:1019`, `devcontainer-config/install.sh:1027`, `test/install-host.bats:1670`, `test/install-host.bats:1755`, `$L/old-T93-minus1659.txt`

---

## Claim 24: Plan row 15: "the 16 link-claude-home-wiring tests run against it. The missing-filter branch is untested"

**Location:** `docs/working/plan-q106-host-settings-merge.md:52`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test count and the absence of a test that removes the filter; does not establish the missing-filter branch's behavior.

`grep -c '^@test' test/link-claude-home-wiring.bats` gives 16, and the run passes 16/16 (`$L/head-link.txt`). The suite's only reference to the filter copies it in: `cp "$REPO_ROOT/hooks/lib/wiring-merge.jq" "$SRC/hooks/lib/"` (`test/link-claude-home-wiring.bats:39`).

**Evidence:** `test/link-claude-home-wiring.bats:39`, `$L/head-link.txt`

---

## Claim 25: "Above the diff, the review lists by name each hook command the merge unwires (`UNWIRES hook:`), each rule it removes (`REMOVES deny rule:`) and each non-deny rule it adds (`ADDS allow rule:`)."

**Location:** `guides/bare-host-hook-wiring.md:53-55`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three line kinds and their placement above the diff; does not establish that "unwires" includes matcher or event changes, which it does not.

The placement is right: `vis_or_die < "$s_view.sum"` comes before `vis_or_die < "$s_view.diff"` (`install.sh:1049-1050`). The `REMOVES` label carries each mode's name, so `REMOVES allow rule:` and others can appear as well as `deny`: `"  REMOVES \($m) rule: "` (`:1040`). The "unwires" residue is claim 7b's.

**Evidence:** `devcontainer-config/install.sh:1037-1050`, `$L/probe_jq.txt`

---

## Claim 26a: "the merge moves our groups to the end, so a group that stays wired also shows as `-`/`+`"

**Location:** `guides/bare-host-hook-wiring.md:55-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merge's ordering; does not establish the diff tool's exact hunk shape.

`.hooks[$ev] = (((.hooks[$ev] // []) | map(select(… | not))) + $wiring.hooks[$ev])` (`hooks/lib/wiring-merge.jq:36-43`): the user's groups first, ours appended.

**Evidence:** `hooks/lib/wiring-merge.jq:34-44`

---

## Claim 26b: "Read that list, not the `-` lines"

**Location:** `guides/bare-host-hook-wiring.md:55`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the list alone surfaces every change that stops one of our hooks firing; does not establish how often such a wiring change occurs.

The instruction treats the by-name list as a full replacement for reading the hook `-` lines, and it is not one. The list compares command strings flattened across events, with matchers ignored: `def cmds: [.hooks[]?[]?.hooks[]?.command]` (`install.sh:1037`). A committed `wiring.json` that keeps `guard-trusted-writes.py`'s command but changes its matcher to one that never matches, or moves it to another event, prints no `UNWIRES` line. The probe prints nothing for both cases (`$L/probe_jq.txt`). That change shows only as `-`/`+` lines in the diff, which the guide tells the reader to skip. A reader who follows the guide accepts a neutered guard. The precise version is: read the list for dropped commands, and also check the `matcher` and event of each of our groups in the diff.

**Evidence:** `devcontainer-config/install.sh:1037-1039`, `guides/bare-host-hook-wiring.md:53-56`, `$L/probe_jq.txt`

---

## Claim 27: "Nothing is written when the file is a symlink, unreadable or not one JSON object, `jq` is missing, `wiring.json` names a hook command other than `bash|python3 {{CLAUDE_DIR}}/hooks/<path>`, or the merge fails"

**Location:** `guides/bare-host-hook-wiring.md:57-59`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guide's skip list against `install.sh:1011-1029`; does not establish the REMINDER wording.

All listed reasons exist (claim 1). Two refusals are not named:

- an empty hook group, refused by `(.hooks // []) | length > 0` (`install.sh:728`);
- a payload missing `wiring.json` or the merge program (`:1015-1016`).

The `..` exclusion is implied by `<path>` but not stated, whereas the help and the refusal message both say "without '..'" (`:1018`).

**Evidence:** `guides/bare-host-hook-wiring.md:57-59`, `devcontainer-config/install.sh:1011-1029`

---

## Claim 28: "remove any older copy of these groups (every command under `~/.claude/hooks/`), then add these beside your own; an old copy left in place fires its hooks twice (FP-161)"

**Location:** `guides/bare-host-hook-wiring.md:73-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the merge's provenance rule; does not establish Claude Code's double-firing behavior (cited to FP-161, not re-run).

This matches the program's rule: drop a group whose every command `contains($dir + "/hooks/")`, then append ours (`hooks/lib/wiring-merge.jq:37-43`). The program's header says `the first time a group gained a hook, so shared hooks fired twice (FP-161)` (`:21`).

**Evidence:** `hooks/lib/wiring-merge.jq:19-21`, `hooks/lib/wiring-merge.jq:34-44`

---

## Claim 29: "On a bare host `install.sh` merges the same wiring after its review (Q-106)"

**Location:** `guides/claude-config-security-checkup.md:46-47`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the host target merges `hooks/wiring.json` from the installed payload after the y; does not establish that every bare host has jq (without it the merge is skipped, claim 2).

`sjq --arg dir "$s_dir" --slurpfile w "${new}hooks/wiring.json" -f "${new}hooks/lib/wiring-merge.jq"` (`install.sh:1025-1026`) is reviewed before the prompt, and `mv -f "$snew" "$settings"` runs after it (`:1168`).

**Evidence:** `devcontainer-config/install.sh:1023-1029`, `devcontainer-config/install.sh:1158-1173`

---

## Claim 30: "Callers run jq with HOME and the environment emptied: jq 1.6 loads $HOME/.jq as a library, which would let unreviewed code redefine builtins such as walk (Q-106 review A3)."

**Location:** `hooks/lib/wiring-merge.jq:12-14`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers jq 1.6 (the installed `jq-1.6`) and both callers' merge invocations; does not cover the count-only jq calls in `link-claude-home.sh:118-119` (claim 10), and does not cover other jq versions.

Probe (`$L/probe_jq.txt`): `HOME=fakehome jq -nc '{a:{b:1}} | walk(.)'` with `def walk(f): {};` in `fakehome/.jq` prints `{}`. Under `env -i PATH="$PATH" HOME=/nonexistent` it prints `{"a":{"b":1}}`. The program does call `walk(...)` (`hooks/lib/wiring-merge.jq:30`).

**Evidence:** `hooks/lib/wiring-merge.jq:12-14`, `hooks/lib/wiring-merge.jq:28-32`, `$L/probe_jq.txt`

---

## Claim 31: "is its legacy single-slash form under $dir, which matched nothing (Q-049)" / "of each rule under $dir only: a branch's Read(//x) must not delete a user's own Read(/x)."

**Location:** `hooks/lib/wiring-merge.jq:23`, `hooks/lib/wiring-merge.jq:47-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `select` filter and its effect; does not establish path normalization (it is a substring test on `"(/" + $dir + "/"`, so it relies on `$dir` having no trailing slash, which claim 6 ensures on the host).

`map(select(contains("(/" + $dir + "/")) | sub("\\(//"; "(/"))` (`hooks/lib/wiring-merge.jq:53`). See claim 17's probe. T99 passes at HEAD and fails on 05b13d11 at `:1764`.

**Evidence:** `hooks/lib/wiring-merge.jq:45-55`, `$L/probe_jq.txt`, `$L/old-T99.txt`

---

## Claim 32a: "Tests: T93/T94/T96/T98 strengthened; T99-T101 new" (each fails on 05b13d11)

**Location:** commit `d53d2bf4` (message body, "Tests:" paragraph)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named test as a whole passing at HEAD and failing against 05b13d11's `install.sh` + `wiring-merge.jq`; does not establish the per-assertion claim (32b).

Command: `$P/run_tests.sh`, cwd `$P/oldtree`, 2026-10-15T11:55:35Z–11:56:04Z. All seven exit 1 on old code. First failing lines are T93 :1659, T94 :1694, T96 :1725, T98 :1753, T99 :1764, T100 :1774 and T101 :1784. All nine T93–T101 pass at HEAD.

**Evidence:** `test/install-host.bats:1655-1786`, `$L/stamp.txt`, `$L/old-T93.txt`, `$L/old-T94.txt`, `$L/old-T96.txt`, `$L/old-T98.txt`, `$L/old-T99.txt`, `$L/old-T100.txt`, `$L/old-T101.txt`, `$L/head-install-host.txt`

---

## Claim 32b: "each new or changed assertion fails on 05b13d11 (checked by running them against its install.sh and wiring-merge.jq)"

**Location:** commit `d53d2bf4` (message body, "Tests:" paragraph)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new and changed assertions in T93 and T94; does not cover T96/T98–T101 assertion-by-assertion (each test's first changed assertion fails, and the rest were not isolated).

Three new or changed assertions pass on 05b13d11:

- T93's new negative assertion `[[ "$review" != *'UNWIRES hook: bash /opt/mine.sh'* && … ]]` (`test/install-host.bats:1660`). Old code prints no `UNWIRES` line at all, so a `!=` match holds trivially.
- T93's changed `[ "$(stat -c %a "$sf")" = 640 ]` (`:1670`, with `user_settings`'s `chmod 640`). Old code's `chmod --reference="$settings"` also kept 640.

  Run: `$P/t93_variant.sh` deletes only line 1659 and runs T93 against old code (cwd `$P/oldtree`, 2026-10-15T11:56:22Z). It exits 0, so lines 1660 and 1670 both pass there (`$L/old-T93-minus1659.txt`).
- T94's changed `[[ "${output%%Install this settings.json merge*}" == *'+      "Edit(//'* ]]` (`:1689`). When the old prompt text is absent, `%%` strips nothing and the full output still contains the diff line. The old T94 run fails first at `:1694`, so `:1689` passed (`$L/old-T94.txt`).

The tests as wholes do fail on old code (32a).

**Evidence:** `test/install-host.bats:1659-1670`, `test/install-host.bats:1689-1694`, `$L/old-T93-minus1659.txt`, `$L/old-T94.txt`

---

## Claim 33: "Size: 501 code lines against merge/ready-2026-10-15 (184396ea)"

**Location:** commit `d53d2bf4` (message body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count by pr-prep step 1a's command at d53d2bf4; does not establish anything else.

`git diff --numstat 184396ea...d53d2bf4 -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` prints `501` (cwd `/workspace/.claude/wt-q106`, 2026-10-15). The same command against HEAD (a4f3614a) also prints `501`.

**Evidence:** `workflows/pr-prep.md:88-92`

---

## Claim 34: "The wiring-shape check is host-only; the container keeps the old acceptance (its settings.json is a default, not a boundary)."

**Location:** commit `d53d2bf4` (message body, Notes)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of a shape check in each caller; does not assess the parenthetical rationale.

`link-claude-home.sh` checks only `jq -e . "$SETTINGS"` (`:108`) before the merge at `:115`. It has no `WIRING_SHAPE` or command test (paraphrased — no quote available because the claim covers the absence of a check; `grep -n jq devcontainer-config/link-claude-home.sh` lists every jq use, `$P/s2.sh`).

**Evidence:** `devcontainer-config/link-claude-home.sh:101-119`

---

## Claims Requiring Attention

### Incorrect
- **Claim 26b** (`guides/bare-host-hook-wiring.md:55`): "Read that list, not the `-` lines". The list keys on command strings only, so a matcher retarget or an event move of `guard-trusted-writes.py` prints no `UNWIRES` line. Tell readers to also check our groups' matcher and event in the diff, or make the summary compare (event, matcher, command).
- **Claim 32b** (commit `d53d2bf4`): "each new or changed assertion fails on 05b13d11". T93 `:1660` (negative UNWIRES) and `:1670` (mode 640), and T94 `:1689` (prompt-prefixed diff), all pass on 05b13d11. Narrow the commit claim to "each test fails", or make those assertions discriminate.

### Stale
- **Claim 13** (`docs/decisions/037-bare-host-copy-install.md:105`): the "Not written" list omits the new shape refusal and the unreadable skip.

### Mostly Accurate
- **Claim 1** (`devcontainer-config/install.sh:47-49`): --help. The "lists what it unwires" parenthetical sits on the refusal path, where nothing is listed, and "names a hook outside <dest>/hooks" understates the shape check.
- **Claim 7b** (`devcontainer-config/install.sh:1034`): the by-name list misses matcher and event changes, and a failing summary program (`|| true`, stderr dropped) silently leaves no list.
- **Claim 12** (`docs/decisions/037-bare-host-copy-install.md:103`): carries claim 7b's residue.
- **Claim 14** (`docs/decisions/037-bare-host-copy-install.md:106`): "its by-name list" carries claim 7b's residue.
- **Claim 16b** (rubric `:64`, A2 "Fixed"): the list part has claim 7b's gap.
- **Claim 18** (plan row 3, `:40`): the row's own threat (guard unwired by a hostile branch) is list-visible only when the command string is dropped.
- **Claim 25** (`guides/bare-host-hook-wiring.md:53-55`): `REMOVES` covers every mode, not just deny, and "unwires" carries claim 7b's residue.
- **Claim 27** (`guides/bare-host-hook-wiring.md:57-59`): leaves out the empty-group and missing-payload refusals and the `..` exclusion.

### Unverifiable
- (none)
