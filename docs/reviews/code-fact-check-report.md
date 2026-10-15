# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q106 (branch feat/q106-host-settings-merge)
**Scope:** range a4f3614a..HEAD (f14cf11a, 2298d18e): devcontainer-config/install.sh, hooks/lib/wiring-merge.jq, README.md, guides/bare-host-hook-wiring.md, docs/decisions/037-bare-host-copy-install.md, docs/working/plan-q106-host-settings-merge.md, test/install-host.bats, the rubric's "Loop pass 2" and "Pass 2 critics" sections, and both commit messages. Commits 184396ea..a4f3614a are context only.
**Commit:** 2298d18e
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-15
**Total claims checked:** 26
**Summary:** 21 verified, 3 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

Complete units read before verdicting: `install_claude_home` (`devcontainer-config/install.sh:795-1228`) from its signature to its end, plus `sjq`/`ONE_OBJ`/`WIRING_SHAPE` (`:723-737`), `vis`/`vis_or_die`, and `hooks/lib/wiring-merge.jq:1-58` (the whole file). No entry in `docs/reviews/hallucination-patterns.md` matches any claim below.

Execution provenance. Every run used cwd `/workspace/.claude/wt-q106`, or a `git archive` extract of a named commit under the scratch dir `/home/node/.claude/jobs/00bcf178/tmp/q106/fc3/` (tree-f14cf11a, tree-a4f3614a, tree-a4f-own, tree-mut). install.sh ran only inside bats, with each test's temp HOME. It never ran against the real HOME. Captured output files are in that scratch dir:
- E1, 2026-10-15T12:18:03Z, exit 0. `timeout 60 bash fc3/probe1.sh` runs WIRING_SHAPE, extracted verbatim from install.sh, on 16 inputs under `sjq -se`, plus two Oniguruma `$` checks. Output: `fc3/probe1.out`.
- E2, 2026-10-15T12:18:24Z, exit 0. `timeout 60 bash fc3/probe2.sh` runs `wiring-merge.jq`, then the review's by-name summary program (extracted verbatim from install.sh:1046-1056), on fixtures. Output: `fc3/probe2.out`.
- E3, 2026-10-15T12:19:09Z to 12:19:38Z. `timeout 600 bash fc3/tests.sh` covers:
  - `LC_ALL=C bats -f 'T9[3-9]|T10[0-3]' test/install-host.bats`: exit 0, 11/11 ok, `fc3/head-install-host.log`.
  - `LC_ALL=C bats test/link-claude-home-wiring.bats`: exit 0, 16/16 ok, `fc3/head-linker.log`.
  - HEAD's T99, T100, T102 and T103 on f14cf11a's tree: exit 1 each, `fc3/f14-T99.log`, `fc3/f14-T100.log`, `fc3/f14-T102.log`, `fc3/f14-T103.log`.
  - HEAD's T102 on a4f3614a's tree: exit 1, `fc3/a4f-T102.log`.
- E4, 2026-10-15T12:20:06Z, output `fc3/probe3.out`. `timeout 600 bash fc3/probe3.sh` covers:
  - f14cf11a's WIRING_SHAPE under its old call (`jq -e`, no `-s`) on the N1 and N2 inputs.
  - f14cf11a's own T102 on a4f3614a: exit 1, `fc3/a4f-ownT102.log`.
  - f14cf11a's own T102 on f14cf11a: exit 0, `fc3/f14-ownT102.log`.
- E5, 2026-10-15T12:21:06Z. `timeout 600 bash fc3/mut.sh` is a mutation run. It replaces WIRING_SHAPE's `| length > 0` with `| true` in an archive of HEAD, then runs T93-T103: exit 0, 11/11 ok. Output: `fc3/mut.out`, `fc3/mut.log`.

All probe processes exited. A `ps` check afterwards found no bats, install.sh or script process.

---

## Claim 1: "The backups of the last 3 installs are kept (the current run's is never removed; one holding only `settings.json` is kept and not counted)."

**Location:** `README.md:61-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a backup holding only settings.json is never stamped, so it is never a prune candidate and never fills one of the 3 slots, on the first-install path T103 runs and by static reading of the prune loop. Does not establish behavior when a user hand-places an `.install-stamp` in such a directory.

The stamp and the prune sit behind one gate:

```bash
# devcontainer-config/install.sh:1194
  if [ -n "$backup" ] && [ "${#moved[@]}" -gt 0 ]; then
```

`moved` gets an entry only when an entry is moved (`install.sh:1139-1143`, `moved+=("$name")`). The prune loop skips any directory without a stamp: `[ -f "$d/.install-stamp" ] || continue` (`install.sh:1215`). T103 passed at HEAD (E3), and it asserts `[ "$(ls -A "$bk")" = settings.json ]` (`test/install-host.bats:1775`), meaning no `.install-stamp` is written.

**Evidence:** `devcontainer-config/install.sh:1123-1143`, `devcontainer-config/install.sh:1173-1221`, `test/install-host.bats:1768-1776`, `fc3/head-install-host.log`

---

## Claim 2a: "Never written when it is a symlink, unreadable or not one JSON object, jq is missing, the payload lacks the merge program, a wiring.json hook is not `bash|python3 {{CLAUDE_DIR}}/hooks/<path>` (or a group is empty), or the merge fails; the review says why."

**Location:** `devcontainer-config/install.sh:47-50`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal conditions --help lists, each checked against the `s_why` chain. Does not establish that --help names every refusal: two are missing.

Every listed condition maps to an `s_why` branch (`install.sh:1018-1036`), and each branch prints `WARNING: settings.json NOT merged: $settings: $s_why.` (`install.sh:1039`). Two refusals the code makes are not in the help list:

1. A wiring.json that is not exactly one object.
2. A hook whose `type` is not `command`, or that carries keys other than type/command/timeout.

The code that makes them:

```bash
# devcontainer-config/install.sh:734-735
WIRING_SHAPE='length == 1 and (.[0] | type == "object") and ([.[0].hooks[]?[]? | (.hooks // []) | length > 0
   and all(.type == "command" and ((keys - ["type", "command", "timeout"]) == [])
```

E1 shows both are refused: `two-docs -> exit 1`, `http -> exit 1`, `extra-key -> exit 1`. Even so, an `http` hook with a well-formed command matches the help's wording "a wiring.json hook is not `bash|python3 …`". The precise version: "wiring.json is not one object whose every hook is a `command` hook (keys type/command/timeout) running `bash|python3 {{CLAUDE_DIR}}/hooks/<path>`, or a group is empty". The guide (`guides/bare-host-hook-wiring.md:61-63`) and 037 (`:105`) already say this.

**Evidence:** `devcontainer-config/install.sh:45-53`, `devcontainer-config/install.sh:734-737`, `devcontainer-config/install.sh:1018-1039`, `fc3/probe1.out`

---

## Claim 2b: "A merge that runs is listed by name: each hook it unwires or adds, each rule it removes or newly allows. A backup holding only settings.json is not counted among the 3 kept."

**Location:** `devcontainer-config/install.sh:50-53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence of the by-name list on the merge path, and the not-counted backup. Does not establish that the list cannot be forged (see Claim 5b) or that it lists added deny rules (it does not: deny additions are excluded by design, `select(. != "deny")`).

The list is printed on the `rc=1` path before the diff: `vis_or_die < "$s_view.sum"` (`install.sh:1064`). Its content is `UNWIRE hook`/`ADD hook`/`REMOVE <mode> rule`/`ADD <mode> rule` lines (`install.sh:1051-1055`). E2's `real` and `legacy-prune` cases print ADD-hook and REMOVE-rule lines. The not-counted half is the same mechanism as Claim 1.

**Evidence:** `devcontainer-config/install.sh:1046-1067`, `devcontainer-config/install.sh:1194`, `fc3/probe2.out`

---

## Claim 3: "wiring.json is exactly one object (jq -e judges only the last of several, the merge reads the first: review pass 2, N1); every hook group has a hook; and every hook is a `command` hook (no other keys but timeout: N2) running `bash|python3 {{CLAUDE_DIR}}/hooks/<path>` with no `..` or shell syntax. ... Used with jq -s."

**Location:** `devcontainer-config/install.sh:728-733`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each conjunct of WIRING_SHAPE as executed under `sjq -se` (16 inputs, plus the real `hooks/wiring.json`), and the old-code premise that `jq -e` judged the last document. Does not establish three things. Group-level keys (`matcher`, others) are not constrained. `.permissions` is not checked at all: a mode key with a newline passes, see Claim 5b. A command ending in one trailing newline passes, because Oniguruma's `$` matches before a final newline. That is harmless to the shell, but it is a literal exception to "no shell syntax".

The shape string is valid jq: the real wiring.json gives `exit 0`, so it parses and accepts. Results for each conjunct (E1):

| Conjunct | Input | Result |
|---|---|---|
| exactly one object | `two-docs` | exit 1 |
| exactly one object | `empty-file` | exit 1 |
| exactly one object | `array` | exit 1 |
| group has a hook | `empty-group` | exit 1 |
| group has a hook | `group-no-hooks` | exit 1 |
| type `command` only | `http` | exit 1 |
| type `command` only | `no-type` | exit 1 |
| keys type/command/timeout | `extra-key` | exit 1 |
| keys type/command/timeout | `ok+timeout` | exit 0 |
| no embedded shell | `newline-cmd` (`h.sh\ncurl x \| sh`) | exit 1 |
| (residue) | `trailing-newline` (`h.sh\n`) | exit 0 |

The call site uses `-s`:

```bash
# devcontainer-config/install.sh:1024
  elif ! sjq -se "$WIRING_SHAPE" "${new}hooks/wiring.json" >/dev/null; then
```

The N1 premise holds on the old code. E4 runs f14cf11a's shape under `jq -e`: "old shape, N1 two-doc -> exit 0 (0 = accepted)". The merge reads the first document: `--slurpfile w` with `$w[0]` (`hooks/lib/wiring-merge.jq:29`).

**Evidence:** `devcontainer-config/install.sh:723-737`, `devcontainer-config/install.sh:1024`, `hooks/lib/wiring-merge.jq:29`, `fc3/probe1.out`, `fc3/probe3.out`

---

## Claim 4: refusal message "hooks/wiring.json is not one object whose every hook is a command hook running 'bash|python3 {{CLAUDE_DIR}}/hooks/<path>' (no '..', no empty group)"

**Location:** `devcontainer-config/install.sh:1025`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the message names the conditions WIRING_SHAPE enforces, and that it is printed and settings.json left untouched for T100's four inputs. Does not establish the extra-keys condition: the message does not name it, but "a command hook" covers it loosely.

T100 passed at HEAD (E3). It asserts the message and `cmp "$CLAUDE_HOME_DIR/settings.json" "$S/settings.orig"` for each of its four inputs: `..`, shell syntax, an `http` hook, and two documents (`test/install-host.bats:1786-1793`).

**Evidence:** `devcontainer-config/install.sh:1025`, `devcontainer-config/install.sh:1037-1039`, `test/install-host.bats:1778-1794`, `fc3/head-install-host.log`

---

## Claim 5a: "each hook the y would unwire or add, and each rule it would remove or newly allow (other than deny), listed by name. A hook is keyed by event, matcher and command, so a move to another event or matcher is listed; a reorder never is."

**Location:** `devcontainer-config/install.sh:1041-1044`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers matcher moves (T102), event moves and reorders (E2). Does not establish two edge cases. An absent matcher and `"*"` share one key (`.matcher // "*"`), so a move between them is not listed (E2 `nomatcher-to-star` printed `(none — …)`); Claude Code treats the two the same. A duplicated hook collapsing to one copy is not listed, because jq array subtraction removes every occurrence.

```jq
# devcontainer-config/install.sh:1047-1048
      def cmds: [.hooks // {} | to_entries[] | .key as $e | .value[]? | (.matcher // "*") as $m
                 | .hooks[]? | "\($e) [\($m)] \(.command)"];
```

E2 results:
- `event-move` printed `UNWIRE hook: "Stop [*] …/hooks/h.sh"` and `ADD hook: "SubagentStop [*] …/hooks/h.sh"`.
- `reorder-only` printed `(none — no hook unwired or added, no rule removed or newly allowed)`.

T102 passed at HEAD (E3).

**Evidence:** `devcontainer-config/install.sh:1041-1057`, `test/install-host.bats:1796-1803`, `fc3/probe2.out`, `fc3/head-install-host.log`

---

## Claim 5b: "Names print as JSON strings, so a newline in one cannot forge another line (review pass 2, N4)."

**Location:** `devcontainer-config/install.sh:1044-1045`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers hook keys and rule names, which are both `tojson`-quoted. Does not establish that the by-name list as a whole cannot be forged: the permission-mode label is interpolated raw.

Hook keys and rules go through `tojson`: E2's `rule-newline` printed one line, `ADD allow rule: "Read(//x)\n  UNWIRE hook: forged"`. The mode name, however, is interpolated without quoting:

```jq
# devcontainer-config/install.sh:1053-1055
         (($a.permissions // {} | keys[]) as $m | (($a | rules($m)) - ($b | rules($m)))[] | "  REMOVE \($m) rule: " + tojson),
         (($b.permissions // {} | keys[] | select(. != "deny")) as $m
          | (($b | rules($m)) - ($a | rules($m)))[] | "  ADD \($m) rule: " + tojson)]
```

WIRING_SHAPE does not check `.permissions` (E1 `perm-mode-newline -> exit 0`), and the merge copies the key through. In E2, a wiring.json mode key `"allow\n  UNWIRE hook: \"FORGED\"\n  ADD x"` produced three summary lines:

```
  ADD allow
  UNWIRE hook: "FORGED"
  ADD x rule: "Read(//x)"
```

`vis` leaves the newline alone: its class `[\x00-\x08\x0b\x0c\x0e-\x1a\x1c-\x1f\x7f]` excludes `\x0a` (`install.sh`, `vis()`). The diff below the list shows the key JSON-escaped, so the forgery is confined to the list. The precise version: "Hook keys and rule names print as JSON strings; the mode name does not." Alternatively, quote `$m` too.

**Evidence:** `devcontainer-config/install.sh:1046-1057`, `devcontainer-config/install.sh:734-737`, `hooks/lib/wiring-merge.jq:46-57`, `fc3/probe1.out`, `fc3/probe2.out`

---

## Claim 6: f14cf11a "a failing summary now prints a WARNING instead of nothing"; rubric P2-4 "Fixed: prints a WARNING line telling the reader to read the whole diff"

**Location:** `devcontainer-config/install.sh:1057`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fallback write on a non-zero exit from the summary jq, and its display on the `rc=1` path. Does not establish that the failure path can be reached in practice: both inputs passed `ONE_OBJ` first. No test exercises it.

```bash
# devcontainer-config/install.sh:1057
      > "$s_view.sum" || echo "  WARNING: the by-name list could not be computed; read the whole diff." > "$s_view.sum"
```

The file is shown by `vis_or_die < "$s_view.sum"` (`install.sh:1064`). Observer: the human reading the review.

**Evidence:** `devcontainer-config/install.sh:1046-1067`

---

## Claim 7: "Stamped, counted and pruned only when entries moved (review A6, pass 2 N7): a backup holding only settings.json never takes one of the 3 slots." / "a directory without that stamp (a settings.json-only backup, or one not made by a completed install) is never removed." / "The previous settings.json is in $backup" printed whenever settings.json was backed up

**Location:** `devcontainer-config/install.sh:1183-1203`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stamp/prune/"Previous entries moved" gate on `moved`, the unconditional settings-backup message after a successful `cp`, and T103's first-install path. Does not establish the combined case: a full install where entries moved and settings.json was merged prints both lines, and that is read only statically.

The settings-backup message comes right after the copy and does not depend on `files_changed`:

```bash
# devcontainer-config/install.sh:1176-1184
    if [ -e "$settings" ] || [ -L "$settings" ]; then
      if [ -z "$backup" ]; then backup="$bkroot/$stamp"; if [ -e "$backup" ]; then backup="$backup.$$"; fi; fi
      if ! mkdir -p "$backup" || ! cp -pP "$settings" "$backup/settings.json"; then
        echo "ERROR: could not back up $settings, so $s_fail." >&2
        echo "       Rerun install.sh." >&2
        exit 1
      fi
      echo "The previous settings.json is in $backup (delete it when satisfied)."
    fi
```

The stamp and "Previous entries moved" are gated at `install.sh:1194` (quoted in Claim 1). T103 passed at HEAD (E3). On f14cf11a it fails: the output has "Previous entries moved to …" (`fc3/f14-T103.log:173`). Both ERROR paths are now two lines (`install.sh:1179-1180`, `:1186-1187`), as API-7 claims.

**Evidence:** `devcontainer-config/install.sh:1170-1221`, `test/install-host.bats:1768-1776`, `fc3/head-install-host.log`, `fc3/f14-T103.log`

---

## Claim 8: 037 Superseded markers on "`settings.json` stays a manual merge" and on the Consequences "Harder" line

**Location:** `docs/decisions/037-bare-host-copy-install.md:37`, `docs/decisions/037-bare-host-copy-install.md:58`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both lines named by the amendment (`:100`) carry a dated Superseded marker that points to the amendment. Does not establish that other 037 lines are free of pre-Q-106 statements.

`:37` ends `*Superseded 2026-10-15: the host target now runs that merge inside its review (Q-106 [2]); see the amendment at the end.*` `:58` carries `*(Superseded 2026-10-15 by Q-106 [2]: see the amendment at the end.)*` The amendment at `:100` names exactly these two lines.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:37`, `docs/decisions/037-bare-host-copy-install.md:58`, `docs/decisions/037-bare-host-copy-install.md:100`

---

## Claim 9: "Loop pass 2 tightened these: `wiring.json` must be exactly one object and every hook a `command` hook; the legacy prune touches only Read/Edit/Write rules (a single-slash Bash rule is a real rule)."

**Location:** `docs/decisions/037-bare-host-copy-install.md:103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tightenings against the code and the E1/E2 runs. Does not establish anything about the rest of the bullet. It sits under "Review loop 1 changes" but also describes pass-2 behavior (the event/matcher keying); that is placement, not a factual error.

The one-object and command-only checks are shown in Claim 3. The narrowed prune is `select(test("^(Read|Edit|Write)\\(//") and contains("(/" + $dir + "/"))` (`hooks/lib/wiring-merge.jq:55`). In E2's `legacy-prune` case, the legacy `Edit(...)` and `Write(...)` forms were removed, while `Bash(<dir>/x*)` and `Read(/x)` stayed.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:103`, `hooks/lib/wiring-merge.jq:52-57`, `fc3/probe1.out`, `fc3/probe2.out`

---

## Claim 10: "**Not written** when the file is a symlink, unreadable or not one JSON object, `jq` is missing, the payload lacks the program, `wiring.json` is not one object of `command` hooks of the right shape (or a group is empty), or the merge fails ..."

**Location:** `docs/decisions/037-bare-host-copy-install.md:105`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a one-to-one match between the bullet's conditions and the six `s_why` branches. Does not establish the "not a regular file" case: it is folded into "symlink" here, and the code's message names it (`install.sh:1019`).

The branches, in order (`install.sh:1018-1036`):
1. symlink or not a regular file
2. jq is not installed
3. no wiring.json or no program in the payload
4. WIRING_SHAPE fails
5. could not be read
6. not one valid JSON object, or the merge program failed

Each maps to a clause of the bullet.

**Evidence:** `docs/decisions/037-bare-host-copy-install.md:105`, `devcontainer-config/install.sh:1018-1036`

---

## Claim 11: Rubric "Loop pass 2" Fixed rows. P2-1: "Fixed: keyed by event, matcher and command; guide reworded; T102 (fails on a4f3614a)". P2-3, P2-4, P2-5: Fixed.

**Location:** `docs/reviews/code-review-rubric-2026-10-15-feat-q106-host-settings-merge.md:89-93`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each Fixed row against the code and docs at HEAD, and T102's failure on a4f3614a in both its f14cf11a and HEAD versions. Does not establish anything about P2-2 and P2-6: they are dispositioned Accepted, not Fixed, and are not re-checked.

P2-1: the keying is shown in Claim 5a. T102 at HEAD fails on a4f3614a (E3, `fc3/a4f-T102.log`). f14cf11a's own T102 also fails on a4f3614a (E4, `fc3/a4f-ownT102.log`) and passes on f14cf11a (`fc3/f14-ownT102.log`), so the failure is a real detection and not only a change of marker format. P2-3 is shown in Claim 10, and P2-4 in Claim 6. P2-5: --help no longer puts "lists what it unwires" on the refusal path. It now says "the review says why. A merge that runs is listed by name" (`install.sh:50-51`). The guide's skip list names the empty group and the missing program (`guides/bare-host-hook-wiring.md:61-64`).

**Evidence:** `devcontainer-config/install.sh:45-53`, `devcontainer-config/install.sh:1047-1048`, `guides/bare-host-hook-wiring.md:53-65`, `fc3/a4f-T102.log`, `fc3/a4f-ownT102.log`, `fc3/f14-ownT102.log`

---

## Claim 12a: Rubric "Pass 2 critics" Fixed rows N1, N2, N3, N6, N7/API-1, API-2 through API-7

**Location:** `docs/reviews/code-review-rubric-2026-10-15-feat-q106-host-settings-merge.md:104-116`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each named fix is present at HEAD and that the named test exists and passes. Does not establish that the empty-group refusal API-4 reworded is tested: no test covers it, see Claim 15. N4 is verdicted separately in Claim 12b.

- N1/N2: Claim 3.
- N3: Claim 9 and Claim 21. T99 passed at HEAD, and the Bash rule is pruned on f14cf11a (`fc3/f14-T99.log:4`).
- N6: the `ADD hook:` line is at `install.sh:1052`.
- N7/API-1: Claim 7.
- API-2: the markers are `UNWIRE`/`ADD`/`REMOVE` (`install.sh:1051-1055`).
- API-3: the `(none — …)` line is at `install.sh:1056`, and E2 `reorder-only` prints it.
- API-4: the message is at `install.sh:1025`, and the help now spells `{{CLAUDE_DIR}}/hooks/<path>` (`install.sh:49`).
- API-5: README `:62-63`, help `:52-53`, and the rotation comment `install.sh:1202-1203`.
- API-6: Claim 8.
- API-7: Claim 7.

**Evidence:** `devcontainer-config/install.sh:45-53`, `devcontainer-config/install.sh:1025`, `devcontainer-config/install.sh:1046-1057`, `devcontainer-config/install.sh:1179-1203`, `fc3/head-install-host.log`, `fc3/probe2.out`

---

## Claim 12b: Rubric N4: "By-name list printed raw; a newline in a rule forged lines. ... Fixed: names print as JSON strings"

**Location:** `docs/reviews/code-review-rubric-2026-10-15-feat-q106-host-settings-merge.md:107`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rule and hook names, which are fixed. Does not establish that the list is forge-proof: the mode label is still raw.

Same evidence as Claim 5b. A rule newline no longer forges a line (E2 `rule-newline`), but a permission-mode key newline does (E2 `mode-key-newline`), and WIRING_SHAPE lets that key through (E1). The precise disposition: "Fixed for rule and hook names; the mode label is still interpolated raw."

**Evidence:** `devcontainer-config/install.sh:1053-1055`, `fc3/probe1.out`, `fc3/probe2.out`

---

## Claim 13: Plan row 2: "the legacy single-slash form of one of our **Read/Edit/Write rules under `$dir`** ... pass 2 (N3) that a single-slash Bash rule is a real rule. A rule absent from the new wiring is never subtracted. T99 asserts all three"

**Location:** `docs/working/plan-q106-host-settings-merge.md:39`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that T99 asserts three properties: a user's `Read(/secrets/**)` survives a branch `Read(//secrets/**)`, a user's single-slash Bash rule survives, and a rule the wiring dropped (`Edit(/$d/old*.json)`) survives. Does not establish allow-mode or ask-mode prunes: T99 tests only deny.

```bash
# test/install-host.bats:1765
  [ "$(jq -c '.permissions.deny' "$sf")" = "[\"Read(/secrets/**)\",\"Bash($d/x*)\",\"Edit(/$d/old*.json)\",\"Read(//secrets/**)\",\"Bash(/$d/x*)\",\"Edit(/$d/settings*.json)\"]" ]
```

T99 passed at HEAD and fails on f14cf11a (E3).

**Evidence:** `docs/working/plan-q106-host-settings-merge.md:39`, `test/install-host.bats:1757-1766`, `fc3/head-install-host.log`, `fc3/f14-T99.log`

---

## Claim 14: Plan row 3: "The review lists each unwired command by name (`UNWIRES hook:`), and removed and newly allowed rules, above the diff (T93); reorders do not appear there"

**Location:** `docs/working/plan-q106-host-settings-merge.md:40`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the marker name and the keying the row describes. Does not establish the row's coverage verdict ("covered by review only"), which still holds.

The marker is now `UNWIRE hook:` (`install.sh:1051`, `"  UNWIRE hook: " + tojson`), and the list keys hooks by event, matcher and command (`install.sh:1047-1048`), not by command. Rows 2 and 5 were updated in this range; row 3 was not. `UNWIRES` survives nowhere else in README, guides, decisions, install.sh, tests or hooks (paraphrased — no quote available because the claim covers absence of code, a grep with no other hits). The current version: "lists each hook unwired or added, keyed by event, matcher and command (`UNWIRE hook:`/`ADD hook:`) … (T93, T102)".

**Evidence:** `docs/working/plan-q106-host-settings-merge.md:40`, `devcontainer-config/install.sh:1047-1056`

---

## Claim 15: Plan row 5: "install.sh refuses the merge unless `wiring.json` is exactly one object ... and every hook is a `command` hook (N2) running `bash` or `python3` `{{CLAUDE_DIR}}/hooks/<path>` with no `..`, in a non-empty group (review loop 1, security F2; T100 covers each)" — covered (T100)

**Location:** `docs/working/plan-q106-host-settings-merge.md:42`
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which conditions T100 exercises, plus a mutation run of T93-T103. Does not establish whether another test file covers the empty-group conjunct: only `test/install-host.bats` was searched and run.

The code enforces every listed condition (Claim 3), but "T100 covers each" is false for the non-empty-group condition. T100's four inputs are `..`, shell syntax, an `http` hook, and two documents (`test/install-host.bats:1786-1789`). None has an empty group, and a grep of `test/install-host.bats` for an empty `hooks` array finds none (paraphrased — no quote available because the claim covers absence of code). E5 confirms the gap: with `| length > 0` replaced by `| true` in WIRING_SHAPE, T93-T103 still pass 11/11 (`fc3/mut.log`). A reader trusting row 5's "covered (T100)" would not know that removing the empty-group refusal goes undetected. Either "T100 covers each but the empty group", or add an empty-group case to T100.

**Evidence:** `docs/working/plan-q106-host-settings-merge.md:42`, `test/install-host.bats:1778-1794`, `devcontainer-config/install.sh:734`, `fc3/mut.out`, `fc3/mut.log`

---

## Claim 16: "each wiring rule is added once, its legacy single-slash form under `~/.claude` dropped (Q-049)"

**Location:** `guides/bare-host-hook-wiring.md:51-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the shipped `hooks/wiring.json`: every rule under `{{CLAUDE_DIR}}` there is a Read, Edit or Write rule, so every one has its legacy form dropped. Does not establish the general case. Since pass 2, a Bash rule under `~/.claude` would keep its legacy form, and this sentence (unchanged in the range) does not say so.

The wiring's `{{CLAUDE_DIR}}` rules are `Read(/{{CLAUDE_DIR}}/.credentials.json)` and Edit/Write rules on `settings*.json`, `hooks/**` and `CLAUDE.md` (`hooks/wiring.json:130-140`). Its only Bash rule, `Bash(*.credentials.json*)`, has no directory part (E2 `real` output). Medium confidence: the sentence is true for today's wiring, but a reader generalizing it to every rule would be wrong after N3.

**Evidence:** `guides/bare-host-hook-wiring.md:51-52`, `hooks/wiring.json:130-140`, `hooks/lib/wiring-merge.jq:55`, `fc3/probe2.out`

---

## Claim 17: "the review lists by name each hook the merge unwires or adds (`UNWIRE hook:`, `ADD hook:`), each rule it removes (`REMOVE deny rule:`) and each non-deny rule it adds (`ADD allow rule:`), or says `(none — …)`. A hook there is named by event, matcher and command (`UNWIRE hook: \"PreToolUse [Bash] python3 …\"`), so a hook moved to another matcher shows as an UNWIRE and an ADD."

**Location:** `guides/bare-host-hook-wiring.md:53-57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each marker's spelling and format against the code and E2 output, and the matcher-move behavior (T102). Does not establish that the list cannot be forged (see Claim 5b). `REMOVE deny rule:` is an example; the code prints `REMOVE <mode> rule:` for any mode.

The code's format strings are `"  UNWIRE hook: " + tojson`, `"  ADD hook: " + tojson`, `"  REMOVE \($m) rule: " + tojson` and `"  ADD \($m) rule: " + tojson` (`install.sh:1051-1055`), plus the `"  (none — no hook unwired or added, no rule removed or newly allowed)"` line (`:1056`). The guide's example `UNWIRE hook: "PreToolUse [Bash] python3 …"` matches the form E2 printed, `ADD hook: "PreToolUse [Bash] bash …/hooks/live-verify-gate.sh"`, including the JSON quotes. T102 asserts both the UNWIRE and the ADD line for a matcher move.

**Evidence:** `guides/bare-host-hook-wiring.md:53-59`, `devcontainer-config/install.sh:1051-1056`, `test/install-host.bats:1802`, `fc3/probe2.out`

---

## Claim 18: "Nothing is written when the file is a symlink, unreadable or not one JSON object, `jq` is missing, `wiring.json` is not one object whose every hook is a `command` hook running `bash|python3 {{CLAUDE_DIR}}/hooks/<path>` (or has an empty group), the payload lacks the merge program, or the merge fails: the review says why, and a `REMINDER` follows if `wiring.json` changed."

**Location:** `guides/bare-host-hook-wiring.md:60-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the match against the `s_why` chain and the REMINDER condition. Does not establish that the guide names the `..` and extra-keys sub-conditions: it does not, and the shorter wording is not wrong.

The REMINDER is gated on `[ "$wiring_changed" -eq 1 ] && [ -n "$s_why" ]` (`install.sh:1222`). The conditions map to `install.sh:1018-1036`, as in Claim 10.

**Evidence:** `guides/bare-host-hook-wiring.md:60-65`, `devcontainer-config/install.sh:1018-1039`, `devcontainer-config/install.sh:1222-1227`

---

## Claim 19: "A permission rule is removed only when it equals one of ours (re-added) or is the legacy single-slash form of one of our Read/Edit/Write rules under $dir, which matched nothing (Q-049); a rule the wiring no longer carries is never removed."

**Location:** `hooks/lib/wiring-merge.jq:22-25`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the subtraction expression for each mode the wiring names. Does not establish modes the wiring does not name: those are not touched at all, which is consistent with the claim.

```jq
# hooks/lib/wiring-merge.jq:52-57
    .permissions[$mode] =
      (((.permissions[$mode] // []) - $wiring.permissions[$mode]
        - ($wiring.permissions[$mode]
           | map(select(test("^(Read|Edit|Write)\\(//") and contains("(/" + $dir + "/"))
                 | sub("\\(//"; "(/"))))
       + $wiring.permissions[$mode])
```

Only rules that equal one of the wiring's rules, or the single-slash form of one of its Read/Edit/Write rules under `$dir`, are subtracted. A rule absent from `$wiring` is never in either subtrahend. E2's `legacy-prune` and T99 bear this out.

**Evidence:** `hooks/lib/wiring-merge.jq:22-28`, `hooks/lib/wiring-merge.jq:45-58`, `fc3/probe2.out`, `fc3/head-install-host.log`

---

## Claim 20: "Also drop the legacy single-slash form ... of each file-tool rule under $dir only: a branch's Read(//x) or Bash(//...) must not delete a user's own Read(/x) or Bash(/...), which may be real rules." (and T99's "Pass 2 N3: a Bash rule's single-slash form is a real rule, never pruned.")

**Location:** `hooks/lib/wiring-merge.jq:48-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Read rules outside `$dir` and Bash rules inside `$dir`, both kept. Does not establish Read/Edit/Write rules whose `$dir` path appears only after the first `(//`: `contains` matches anywhere in the rule.

E2 `legacy-prune` gave a new deny list that keeps the user's `Bash(<dir>/x*)` and `Read(/x)` and drops the legacy `Edit(<dir>/settings*.json)` and `Write(<dir>/a)`. The T99 comment (`test/install-host.bats:1764`) matches the assertion on the next line, which keeps `Bash($d/x*)`.

**Evidence:** `hooks/lib/wiring-merge.jq:48-57`, `test/install-host.bats:1764-1765`, `fc3/probe2.out`

---

## Claim 21: link-claude-home-wiring.bats' legacy test "legacy single-slash deny rules are pruned; the user's own rules survive" still exercises the narrowed prune

**Location:** `test/link-claude-home-wiring.bats:279-293`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test's legacy rules are Edit and Read rules, so they fall inside the narrowed `^(Read|Edit|Write)\(//` filter, and that the test passes at HEAD. Does not establish that the container-side test pins the N3 narrowing: it has no single-slash Bash rule under `$DEST`, so only install-host T99 does.

```bash
# test/link-claude-home-wiring.bats:283-285
  jq -n --arg d "$DEST" '{permissions: {deny: [
      "Edit(\($d)/settings*.json)", "Read(\($d)/.credentials.json)",
      "Edit(/user/own/rule)", "Bash(rm -rf /)"]}}' > "$DEST/settings.json"
```

The test asserts that both legacy forms reach count 0 (`:289-290`). It passed at HEAD: `ok 15 legacy single-slash deny rules are pruned; the user's own rules survive` (E3).

**Evidence:** `test/link-claude-home-wiring.bats:279-293`, `fc3/head-linker.log`

---

## Claim 22: 2298d18e: "Tests: T99, T100, T102 extended and T103 new; each fails on f14cf11a (T100's new N1/N2 cases were reproduced on that code by the pass-2 security critic; on f14cf11a the test also fails on its message)."

**Location:** `git:2298d18e` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the four tests at HEAD failing against f14cf11a's tree, and the N1/N2 inputs being accepted by f14cf11a's shape check. Does not establish assertion-by-assertion failure inside T100: the test stops at its first iteration's message assertion, so its N1/N2 iterations never run on the old code. The message says exactly this.

E3 failures on f14cf11a:
- T99: the deny-list assertion fails, because the Bash rule was pruned (`fc3/f14-T99.log:4`).
- T100: the message assertion fails on the first (`..`) iteration (`fc3/f14-T100.log:4`).
- T102: the JSON-quoted UNWIRE/ADD assertion fails; the old output was `UNWIRES hook: PreToolUse [Bash] …` (`fc3/f14-T102.log:29`).
- T103: fails on "Previous entries moved" (`fc3/f14-T103.log:173`).

E4 independently confirms the N1/N2 premise. f14cf11a's shape under `jq -e` accepts both inputs: "old shape, N1 two-doc -> exit 0", "old shape, N2 http hook -> exit 0".

**Evidence:** `fc3/f14-T99.log`, `fc3/f14-T100.log`, `fc3/f14-T102.log`, `fc3/f14-T103.log`, `fc3/probe3.out`, `test/install-host.bats:1757-1803`

---

## Claim 23: f14cf11a: "T102 (fails on a4f3614a); T93 expects the new key; T94 checks the settings-only prompt explicitly (its %% split passed on old code)."

**Location:** `git:f14cf11a` (commit message)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T102 failing on a4f3614a (executed), T93's assertion (static), and T94's old/new assertion semantics (static, from bash's `%%` behavior). Does not establish re-running T94's old assertion on a4f3614a code.

f14cf11a's own T102 fails on a4f3614a and passes on f14cf11a (E4). T93 now expects `UNWIRE hook: "PreToolUse [Bash] bash $d/hooks/old.sh"` (`test/install-host.bats:1659`); f14cf11a introduced the key and 2298d18e quoted it. T94 is now `[[ "$output" == *'+      "Edit(//'*'Install this settings.json merge into'* ]]` (`test/install-host.bats:1689`). The old `${output%%Install this settings.json merge*}` expands to the whole output when the prompt is absent, so the old form passed without the prompt (paraphrased — no quote available because this is bash parameter-expansion semantics, not repo code).

**Evidence:** `fc3/a4f-ownT102.log`, `fc3/f14-ownT102.log`, `test/install-host.bats:1656-1660`, `test/install-host.bats:1686-1690`

---

## Claims Requiring Attention

### Incorrect
- **Claim 15** (`docs/working/plan-q106-host-settings-merge.md:42`): "T100 covers each" is false for the non-empty-group condition. No install-host test has an empty group, and the mutation `length > 0` → `true` passes T93-T103 (E5). Add an empty-group case to T100, or narrow the row.

### Stale
- **Claim 14** (`docs/working/plan-q106-host-settings-merge.md:40`): plan row 3 still says `UNWIRES hook:` and "each unwired command". The marker is now `UNWIRE hook:`/`ADD hook:`, keyed by event, matcher and command (T102).

### Mostly Accurate
- **Claim 2a** (`devcontainer-config/install.sh:47-50`): --help's refusal list omits "not exactly one object" and "not a `command` hook / extra keys". Say "is not one object whose every hook is a `command` hook running …", as the guide and 037 do.
- **Claim 5b** (`devcontainer-config/install.sh:1044-1045`): hook keys and rule names are JSON-quoted, but the permission-mode label (`\($m)`) is not. WIRING_SHAPE does not check `.permissions`, so a wiring mode key with a newline still forges lines in the by-name list (E2). Quote `$m`, or narrow the comment.
- **Claim 12b** (`docs/reviews/code-review-rubric-2026-10-15-feat-q106-host-settings-merge.md:107`): N4 "Fixed" holds for rule and hook names only. The mode-label residue in Claim 5b remains.

### Unverifiable
- None.
