Commit: 591f098 (A) / 44d06b7 (B)

# Code Fact-Check Report

**Repository:** claude-workflows. A: `/workspace/.claude/wt-digest` (digest code at 591f098; HEAD 8a52771 adds review docs only, `git diff --stat 591f098 HEAD -- scripts test` is empty). B: `/workspace/.claude/wt-devcycle` (content at 44d06b7; `git diff --stat 44d06b7 HEAD -- skills/dev-cycle/SKILL.md` is empty). Both working trees were clean when read.
**Scope:** Partial: the pass-12 fix round only. A: `git diff 71e618d..591f098 -- scripts/dev-cycle.sh test/scripts/dev-cycle.bats` plus the messages of commits 6d6637d and 591f098. B: `git diff 8286c2b..44d06b7 -- skills/dev-cycle/SKILL.md` plus the message of commit 44d06b7. Everything else on both branches is context only.
**Checked:** 2026-10-01
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 31
**Summary:** 25 verified, 3 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Execution logs (scratch, not committed) are all under `/tmp/claude-1000/-workspace/dc1aa358-6e28-4b6b-8788-03dacd3f5ac7/scratchpad/fc13/`. Every script and test file ran from a copy taken with `git show <sha>:<path>` (`fc13/pin/` = 591f098, `fc13/pin6d/` = 6d6637d):
- `bats-pinned.log`: `timeout 300 bats fc13/pin/test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, exit 0, 2026-10-01T23:04:27-07:00, 22/22.
- `shellcheck-pinned.log`: `timeout 60 shellcheck fc13/pin/scripts/dev-cycle.sh`, exit 0, empty, 23:04:33.
- `bats-6d6637d.log` and `shellcheck-6d6637d.log`: the same two commands on `fc13/pin6d/`, exit 0 both, 23:06:14, 22/22, empty.
- `probe.log` (script `probe.sh`): `timeout 300 bash fc13/probe.sh`, exit 0, 23:05:01. Scenarios S1–S7, each in its own repo under one `mktemp -d` directory, removed on exit. Each prints the Window line, every skip note, and section 8. S1, S2 and S7 also run the script with `DEV_CYCLE_SCRUBBED=1 bash -x` (no strace in the sandbox) and grep the trace for every `[[ -d/-e/-f/-L ]]` test and `realpath -e` call on a path below the blocking part.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read. No claim matches a logged pattern, and the three Incorrect verdicts are wrong mechanism claims, not invented symbols, so nothing is logged.

Legibility-target values: **agent** (the model that runs the skill or digest acts on the text), **maintainer** (someone editing the script or tests), **user** (the human reading the digest or the record).

---

## Claim 1: "A regular file reached without any symlink: its real path must be exactly the repo root plus the path as given, so a committed symlink (to the file or to a parent directory, pointing outside the checkout or into .git) is never read."

**Location:** `scripts/dev-cycle.sh:89-92`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `rawfile` for the paths the digest passes it (fixed names and glob items, none containing `..`). It does not establish anything about a repo root whose real path ends in a newline (command substitution would strip it).

`rawfile() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }` (`scripts/dev-cycle.sh:92`). A canonical path contains no symlinks, so if any part of the given path is a symlink, the strings differ (paraphrased — no quote available because this is reasoning about `realpath` semantics, not a line of the script). Test 6 links a decision record into `.git` and others outside the repo, and asserts no `SECRET` text appears; it passes (`bats-pinned.log`, ok 6).

**Evidence:** `scripts/dev-cycle.sh:88-92`, `test/scripts/dev-cycle.bats:126-155`, `fc13/bats-pinned.log`

---

## Claim 2: "A directory the digest globs in must be plain too, or the glob would list names from wherever a symlinked directory points."

**Location:** `scripts/dev-cycle.sh:93-95`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers that both glob loops run only after `plaindir` passes on their directory. It does not establish that the gate itself makes no lookup below a symlinked parent (it does; see Claim 12b).

`if plaindir docs/working/cycles; then for f in docs/working/cycles/cycle-…` (`scripts/dev-cycle.sh:146-147`) and `if plaindir docs/decisions; then decisions_glob=(docs/decisions/[0-9][0-9][0-9]-*.md); else skipdir docs/decisions || true; fi` (`:201`).

**Evidence:** `scripts/dev-cycle.sh:93-95`, `scripts/dev-cycle.sh:146-159`, `scripts/dev-cycle.sh:200-203`

---

## Claim 3: "One rule decides whether an input is skipped, for files and directories alike: walking the path top down, the first part that exists but is not plain (a symlink, or not a regular file / directory) blocks it."

**Location:** `scripts/dev-cycle.sh:96-98`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `blocker()` and that every entry in `SKIPPED` comes from it. It does not establish that the decision whether to *read* a glob item goes through `blocker` (glob items are read on `rawfile` alone, by design; Claim 9).

The walk: `plaindir "$p" || { printf '%s/' "$p"; return 0; }` for each parent (`:108`), then for the last part `if [[ "$2" == dir ]]; then plaindir "$1" || printf '%s/' "$1"` / `else rawfile "$1" || printf '%s' "${1//$'\n'/ }"; fi` (`:111-112`; the function ends at `:113` — read). The only `SKIPPED+=` in the script is in `skipped()`: `SKIP_AT="$(blocker "$1" "${2:-file}")"; [[ -n "$SKIP_AT" ]] || return 1; SKIPPED+=("$SKIP_AT")` (`:118`), and `skipdir` is `skipped "$1" dir` (`:119`). Probes: docs/working symlink → `- docs/working/` (S1); docs symlink → `- docs/` (S2); docs/working/cycles a regular file → `- docs/working/cycles/` (S3); roadmap.md a directory and a dangling idea-log symlink → both listed (S4) (`probe.log`).

**Evidence:** `scripts/dev-cycle.sh:102-119`, `fc13/probe.log` (S1–S4, S7)

---

## Claim 4: "Nothing below a blocking part is probed, not even whether a file exists there"

**Location:** `scripts/dev-cycle.sh:98-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `blocker()` itself and its callers `inrepo`/`skipped`/`skipdir`: the walk returns at the first blocking part. It does not establish the property script-wide: the two glob-directory gates (`plaindir docs/working/cycles` at :146, `plaindir docs/decisions` at :201) run before any walk and do look up through a symlinked `docs/` or `docs/working/` (Claims 12b, 17b, 20b).

`plaindir "$p" || { printf '%s/' "$p"; return 0; }` (`:108`) returns before any longer prefix is tested. In S7 (`docs/decisions` a symlink), the trace has no test or `realpath` call on any path below `docs/decisions/`, so the `log.md` lookup stops at the walk (`probe.log`, S7 xtrace section empty). In S1 the only trace lines below `docs/working/` are `+ [[ -d docs/working/cycles ]]` and `++ realpath -e -- docs/working/cycles`, which come from the gate at :146, not from `blocker` (`probe.log:15-16`).

**Evidence:** `scripts/dev-cycle.sh:103-113`, `fc13/probe.log` (S1, S7)

---

## Claim 5: "the blocking part is what section 8 lists and what the inline note names"

**Location:** `scripts/dev-cycle.sh:99-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the four `skipnote` call sites (questions, roadmap twice, idea log). It does not establish that the section-2 summary note or the Window line's no-record note name a part (they name none; Claim 19).

`skipnote() { echo "$1 is not read: $SKIP_AT is not a plain file or directory (section 8)."; }` (`:120`), with `SKIP_AT` set by the same `skipped` call whose value goes into `SKIPPED` (`:118`). S2: three notes say `… is not read: docs/ is not a plain file or directory (section 8).` and section 8 lists `- docs/`. S1: notes name `docs/working/`, section 8 lists `- docs/working/`. S7: `docs/working/questions.md is not read: docs/working/questions.md is not …` and section 8 lists `- docs/working/questions.md` (`probe.log`).

**Evidence:** `scripts/dev-cycle.sh:118-120`, `:252-253`, `:274-275`, `:324-325`, `:343-344`, `fc13/probe.log` (S1, S2, S4, S7)

---

## Claim 6: "A newline in a name becomes a space before it is ever printed."

**Location:** `scripts/dev-cycle.sh:100-101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers every name that can hold a newline, which are the decision glob items (file mode). It does not establish replacement on parent parts or on directory-mode names (`:108`, `:111` print them unchanged), which are all fixed names in this script.

Only the file-mode branch replaces: `rawfile "$1" || printf '%s' "${1//$'\n'/ }"` (`:112`). Test 7 links `docs/decisions/002-a<newline>- FORGED.md` and asserts section 8 shows `- docs/decisions/002-a - FORGED.md` and no line starting `- - FORGED` (`test/scripts/dev-cycle.bats:172-179`); it passes (`bats-pinned.log`, ok 7).

**Evidence:** `scripts/dev-cycle.sh:103-113`, `test/scripts/dev-cycle.bats:157-189`, `fc13/bats-pinned.log`

---

## Claim 7: "An absent path is not skipped, just absent."

**Location:** `scripts/dev-cycle.sh:101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers an absent last part and an absent parent. It does not establish anything about a path that disappears between `inrepo` and `skipped` (a race).

`[[ -e "$p" || -L "$p" ]] || return 0` for each parent (`:107`) and `[[ -e "$1" || -L "$1" ]] || return 0` for the last part (`:110`) print nothing, so `skipped` returns 1. S5 (plain roadmap, plain record, plain log, no questions.md) prints `None: no input was skipped.`; S4 and S7 have no cycles directory and say `no cycle record found` with no cycles entry in section 8 (`probe.log`).

**Evidence:** `scripts/dev-cycle.sh:105-110`, `fc13/probe.log` (S4, S5, S7)

---

## Claim 8: "A fixed-name input is read only when no part of its path blocks it; the walk runs first, so nothing is looked up through a non-plain parent."

**Location:** `scripts/dev-cycle.sh:114-117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers `inrepo` and its five call sites (log, questions, roadmap twice, idea log). It does not cover the directory gates for the globs, which are not fixed-name file inputs and do not use `inrepo` (Claim 12b).

`inrepo() { [[ -z "$(blocker "$1" file)" ]] && rawfile "$1"; }` (`:117`). Call sites: `inrepo docs/decisions/log.md` (`:212`), `inrepo docs/working/questions.md` (`:234`), `inrepo docs/roadmap.md` (`:269`, `:319`), `inrepo "$LOG"` (`:330`). In S1 and S7 the trace shows no `-f` or `realpath` on `docs/working/questions.md`, `docs/working/idea-log.md` or `docs/decisions/log.md` (`probe.log`). The `$QS` path (`:232-234`) is the running script's own directory or `$HOME/.claude/scripts`, not a repo input, and is tested only after `inrepo` succeeds or as a non-repo file.

**Evidence:** `scripts/dev-cycle.sh:114-117`, `:212`, `:232-234`, `:269`, `:319`, `:330`, `fc13/probe.log` (S1, S7)

---

## Claim 9: "(Glob items use rawfile directly: their directory has already passed plaindir.)"

**Location:** `scripts/dev-cycle.sh:115-116`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers both glob loops. It does not establish the cost of a skipped glob item (Claim 25).

`if plaindir docs/working/cycles; then` … `if ! rawfile "$f"; then` (`:146-149`) and `if plaindir docs/decisions; then decisions_glob=(…)` … `rawfile "$f" || { skipped "$f" || true; continue; }` (`:201-203`).

**Evidence:** `scripts/dev-cycle.sh:145-159`, `scripts/dev-cycle.sh:200-211`

---

## Claim 10: "Keep the newest skipped date (not future-dated) to warn when it is newer than the record the window starts from."

**Location:** `scripts/dev-cycle.sh:150-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the changed line with its new `SKIP_AT == f` guard. It does not establish that the guard can ever be false inside this loop (the loop runs only after the directory passed `plaindir`, so `blocker` can only return the item itself).

`skipped "$f" && [[ "$SKIP_AT" == "$f" && "$d" > "$skipped_record" && ! "$d" > "$TODAY" ]] && skipped_record="$d"` (`:152`). S6: an older skipped record and a future-dated one, with a plain record between them → the Window line has no skipped-record note, and section 8 lists both (`probe.log`). Test 10 (newer skipped record) passes (`bats-pinned.log`, ok 10).

**Evidence:** `scripts/dev-cycle.sh:145-167`, `fc13/probe.log` (S6), `fc13/bats-pinned.log`

---

## Claim 11: Window texts "a newer record, docs/working/cycles/cycle-$skipped_record.md, was skipped as not a plain file (section 8)" and "no readable cycle record (records or their directory were skipped as not plain: section 8)"

**Location:** `scripts/dev-cycle.sh:166`, `scripts/dev-cycle.sh:171`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user / agent
**Scope:** Covers the two Window variants that mention skipping. "Their directory" includes an ancestor (`docs/`, `docs/working/`); it does not establish that a record exists when the second variant prints (S2, S3 print it with no record anywhere).

The second variant prints for a symlinked `docs/working` (S1), a symlinked `docs/` (S2) and a `docs/working/cycles` that is a regular file (S3), because `records_skipped=${#SKIPPED[@]}` is taken right after the cycle scan (`:160`) (`probe.log`). The first uses the full path (test 10).

**Evidence:** `scripts/dev-cycle.sh:160-175`, `fc13/probe.log` (S1–S3), `fc13/bats-pinned.log`

---

## Claim 12a: "Each is a symlink, or a file or directory of the wrong kind, so it was not read"

**Location:** `scripts/dev-cycle.sh:353`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user / agent
**Scope:** Covers what section 8 lists and that the digest reads none of it. It does not cover the second half of the sentence (Claim 12b).

S3 lists `docs/working/cycles/` (a regular file, wrong kind), S4 lists `docs/roadmap.md` (a directory) and a dangling idea-log symlink; S1, S2, S7 list symlinks (`probe.log`). Test 6 asserts no `SECRET` text from any skipped file appears (ok 6).

**Evidence:** `scripts/dev-cycle.sh:349-355`, `fc13/probe.log`, `fc13/bats-pinned.log`

---

## Claim 12b: "nothing below a listed directory was read or probed"

**Location:** `scripts/dev-cycle.sh:353`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** user / agent
**Scope:** Covers the "probed" half when `docs/` or `docs/working/` is the listed directory. It does not establish that anything below it is *read* (nothing is) or that the digest's output changes (it does not).

The glob gates call `plaindir` before any walk: `if plaindir docs/working/cycles; then` (`:146`) and `if plaindir docs/decisions; then` (`:201`), and `plaindir` is `[[ -d "$1" ]] && r="$(realpath -e -- "$1" …)"` (`:95`). With `docs/working` a symlink (S1), the trace shows `+ [[ -d docs/working/cycles ]]` and `++ realpath -e -- docs/working/cycles` (`probe.log:15-16`), while section 8 lists `- docs/working/` under this header. With `docs/` a symlink (S2), the trace also shows `+ [[ -d docs/decisions ]]` / `++ realpath -e -- docs/decisions` (`probe.log:33-36`). Both look up a name inside the symlink's target. The gate then fails and `skipdir` lists the parent, so the output is the same either way. This is the same kind of lookup 591f098 removed from `inrepo`. A precise version is: "nothing below a listed directory was read". Alternatively, the gates would need to run the walk first.

**Evidence:** `scripts/dev-cycle.sh:95`, `:146`, `:158`, `:201`, `:353`, `fc13/probe.log` (S1, S2)

---

## Claim 13a: "It says records or their directory were skipped, or names a newer record that was skipped: … (`docs/`, `docs/working/`, the cycles directory)"

**Location:** `skills/dev-cycle/SKILL.md:103-105`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the trigger phrases against the digest's four Window variants, and the directory list against the walk's parents. It does not establish the diagnosis wording (Claim 13b).

The digest prints `records or their directory were skipped as not plain` (`scripts/dev-cycle.sh:171`) and `a newer record, docs/working/cycles/cycle-….md, was skipped` (`:166`); the other variants are `--since` (`:162`), `the last cycle record, …` with no note (`:164`), and `no cycle record found` (`:173`), none of which says "skipped". The walk for `docs/working/cycles` tests exactly `docs`, `docs/working`, `docs/working/cycles` (`:105-111`); S1–S3 show each producing the second variant (`probe.log`).

**Evidence:** `skills/dev-cycle/SKILL.md:100-110`, `scripts/dev-cycle.sh:160-175`, `fc13/probe.log`

---

## Claim 13b: "a record exists but is not a plain file, or a directory above it … is not"

**Location:** `skills/dev-cycle/SKILL.md:104-105`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** agent
**Scope:** Covers the diagnosis the bullet gives for the "records or their directory were skipped" variant. It does not affect the action the bullet prescribes (note, `agent` entry, rerun), which fits every case probed.

The variant fires whenever anything was skipped during the cycle scan, whether or not a record exists: `[[ $records_skipped -gt 0 ]]` (`scripts/dev-cycle.sh:170`). In S2 (`docs/` a symlink to a directory with an empty `working/cycles/`) and S3 (`docs/working/cycles` is a regular file), the line prints and no record exists anywhere (`probe.log`). A precise version: "a record, or a directory that would hold the records (`docs/`, `docs/working/`, the cycles directory), exists but is not plain". Also, "the path section 8 lists" assumes one path, but section 8 can list several (e.g. S2 with a skipped roadmap too). The agent has to pick the cycles-related one.

**Evidence:** `skills/dev-cycle/SKILL.md:103-107`, `scripts/dev-cycle.sh:160-171`, `fc13/probe.log` (S2, S3)

---

## Claim 14: "Otherwise, if the window starts before the last cycle you know ran (or says no cycle record was found when one ran), that cycle skipped step 7"

**Location:** `skills/dev-cycle/SKILL.md:108-110`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that the quoted phrase matches `:173` and that, after bullet 1 has excluded the skip variants, a plain missing record is the remaining cause. It does not cover a newest record that is skipped *and* future-dated (no Window note; bullet 2 would misattribute it to a skipped step 7), an edge outside this round.

`source_note="no cycle record found, so the default of 14 days (…)"` (`scripts/dev-cycle.sh:173`). "Otherwise" makes the bullets exclusive, and every skip that changes the window's start is named by bullet 1's phrases (`:166`, `:171`), except a future-dated skipped record, which `:152` deliberately ignores.

**Evidence:** `skills/dev-cycle/SKILL.md:100-110`, `scripts/dev-cycle.sh:145-175`

---

## Claim 15: "Apply answers here, reading `questions-archive.md` too (step 1 has already archived answered entries)"

**Location:** `skills/dev-cycle/SKILL.md:227-228`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** agent
**Scope:** Covers that step 1 runs `archive` before step 6 and that `archive` moves ANSWERED entries to `questions-archive.md`. It does not establish that an answer is applied only once. The rule says nothing about answers already applied in an earlier cycle, so whether a re-read "keep" re-adds `Kept:` each cycle depends on which date `Kept:` takes, and the text leaves that open.

Step 1: `` `~/.claude/scripts/questions.sh archive` then `index`, so answered entries leave the live file. `` (`skills/dev-cycle/SKILL.md:123-124`). `cmd_archive` skips all but `[[ "$status" == "ANSWERED" ]] || continue` and appends each to `$ARCHIVE`, which defaults to `docs/working/questions-archive.md` (`scripts/questions.sh:379-386`, `:86`). The repo copy is byte-identical to `~/.claude/scripts/questions.sh` (`cmp`).

**Evidence:** `skills/dev-cycle/SKILL.md:116-124`, `skills/dev-cycle/SKILL.md:221-229`, `scripts/questions.sh:86`, `scripts/questions.sh:374-394`

---

## Claim 16: "Each is reported as skipped, not as absent."

**Location:** `test/scripts/dev-cycle.bats:145-148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the updated assertions and that test 6 passes on 591f098. It does not establish that the assertions without `|| return 1` would fail the test on their own on a bash older than 4.1 (bash here is 5.2.15).

The assertions now match `skipnote`'s text: `*"docs/roadmap.md is not read: docs/roadmap.md is not a plain file or directory"*` and `*"no readable cycle record (records or their directory were skipped"*` (`test/scripts/dev-cycle.bats:146-148`). The test passes (ok 6).

**Evidence:** `test/scripts/dev-cycle.bats:126-155`, `fc13/bats-pinned.log`

---

## Claim 17a: "docs/working itself a symlink: only it is listed …, the window says records were skipped, and notes name it."

**Location:** `test/scripts/dev-cycle.bats:180-188`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the three things the new block asserts. It does not cover the parenthetical about probing (Claim 17b).

The block asserts `- docs/working/` is in section 8 with neither `docs/working/cycles` nor `questions.md`, the Window phrase, and `docs/working/questions.md is not read: docs/working/ is not a plain file or directory` (`:186-188`). It passes (ok 7), and S1 reproduces the same output (`probe.log`).

**Evidence:** `test/scripts/dev-cycle.bats:180-188`, `fc13/bats-pinned.log`, `fc13/probe.log` (S1)

---

## Claim 17b: "(nothing below it is probed)"

**Location:** `test/scripts/dev-cycle.bats:180-181`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the parenthetical as a statement about the script in this test's setup. It does not mean the assertions are wrong: they check what is *listed*, which is correct.

In exactly this setup (`docs/working` → a directory holding `cycles/`), the script runs `[[ -d docs/working/cycles ]]` and `realpath -e -- docs/working/cycles` through the symlink (`probe.log:15-16`, S1, same layout). The test can only see output, and the lookup does not change the output, so it passes anyway. A precise version is "(nothing below it is listed)".

**Evidence:** `test/scripts/dev-cycle.bats:180-188`, `scripts/dev-cycle.sh:146`, `fc13/probe.log` (S1)

---

## Claim 18: test 10, "a skipped newer cycle record is named in the window line"

**Location:** `test/scripts/dev-cycle.bats:207-213`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the full-path wording. It does not establish behavior for a newer skipped record that is future-dated (covered by S6 instead).

The assertion now expects `a newer record, docs/working/cycles/cycle-2026-02-20.md, was skipped` (`:212`), matching `scripts/dev-cycle.sh:166`; ok 10.

**Evidence:** `test/scripts/dev-cycle.bats:207-213`, `fc13/bats-pinned.log`

---

## Claim 19: "skipnote names it in every inline note, so section 8, the notes and the Window line agree by construction" (commit 6d6637d)

**Location:** commit 6d6637d message; `scripts/dev-cycle.sh:118-120`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers which notes use `skipnote`. It does not find any disagreement: the notes that do not use it name no part, so they cannot contradict section 8.

All four per-input notes use `skipnote` (`:253`, `:275`, `:325`, `:344`). Two other skip notes do not and name no part. One is section 2's `No revisit triggers read: decision records or the log were skipped as not plain files (section 8).` (`:227`), which also says "files" when the skipped part is `docs/` or `docs/decisions/` (S2, S7). The other is the Window line's `records or their directory were skipped` (`:171`). Precise version: "every per-input note".

**Evidence:** `scripts/dev-cycle.sh:118-120`, `:171`, `:227`, `:253`, `:275`, `:325`, `:344`, `fc13/probe.log` (S2, S7)

---

## Claim 20a: "A symlinked docs/ or docs/working/ is listed once, … and the Window line says records or their directory were skipped (test 7 adds this case)." (commit 6d6637d)

**Location:** commit 6d6637d message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers listing and Window wording. It does not cover the "nothing below it is probed" part (Claim 20b).

Section 8 dedups with `printf '%s\n' "${SKIPPED[@]}" | sort -u` (`scripts/dev-cycle.sh:354`). S1 lists `- docs/working/` once and S2 lists `- docs/` once, each with the Window phrase (`probe.log`). Test 7's new block covers the docs/working case (`test/scripts/dev-cycle.bats:180-188`).

**Evidence:** `scripts/dev-cycle.sh:349-355`, `fc13/probe.log` (S1, S2)

---

## Claim 20b: "nothing below it is probed" (commit 6d6637d, for a symlinked docs/ or docs/working/; restated by 591f098 as now literally true)

**Location:** commit 6d6637d message; commit 591f098 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers 6d6637d and 591f098 alike: the gates were not changed in either. It does not establish any output difference (none) or any read below the symlink (none).

591f098 says the old `inrepo` made "nothing below a blocking part is probed" "not literally true (no output changed)" and fixes `inrepo` only. The same kind of lookup stays in `plaindir docs/working/cycles` (`:146`) and `plaindir docs/decisions` (`:201`). It shows in the traces for a symlinked `docs/working` (S1) and `docs/` (S2) (`probe.log:15-16`, `:33-36`). The 6d6637d copy has the same gates and passes the same 22 tests (`bats-6d6637d.log`).

**Evidence:** `scripts/dev-cycle.sh:146`, `scripts/dev-cycle.sh:201`, `fc13/probe.log` (S1, S2), `fc13/bats-6d6637d.log`

---

## Claim 21: "Inline notes name the part that blocked the read …; The Window line's skipped-record note uses the full path; it fires only when the record itself (not a parent) was skipped; Section 8's header covers a directory where a file is expected." (commit 6d6637d)

**Location:** commit 6d6637d message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the three bullets as stated. "Not a parent" is guaranteed by the loop's outer `plaindir` gate as well as by the new `SKIP_AT == f` test; it does not establish that the new test is ever the deciding one.

Notes: S1 `docs/working/questions.md is not read: docs/working/ is not a plain file or directory (section 8).`, exactly the example in the message. Window: `:166` and test 10. Header: `Each is a symlink, or a file or directory of the wrong kind` (`:353`), and S4 lists `docs/roadmap.md` (a directory) (`probe.log`).

**Evidence:** `scripts/dev-cycle.sh:152`, `:166`, `:353`, `fc13/probe.log` (S1, S4), `fc13/bats-pinned.log`

---

## Claim 22: "22/22; shellcheck clean." (commit 6d6637d)

**Location:** commit 6d6637d message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the 6d6637d copies of the script and test file. It does not establish shellcheck on the test file.

`timeout 300 bats fc13/pin6d/test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, exit 0, 2026-10-01T23:06:14-07:00, 22 `ok` lines; `timeout 60 shellcheck fc13/pin6d/scripts/dev-cycle.sh`, exit 0, empty output.

**Evidence:** `fc13/bats-6d6637d.log`, `fc13/shellcheck-6d6637d.log`

---

## Claim 23: "inrepo's `-f` and `realpath -e` looked a fixed-name path up through a symlinked parent before skipped() ran … (no output changed)" (commit 591f098)

**Location:** commit 591f098 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the old `inrepo` at 71e618d/6d6637d. It does not establish that the fix covers every lookup of that kind (Claim 20b).

At 71e618d: `inrepo() { local r; [[ -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" …` (line 92) was called first: `if inrepo docs/working/questions.md && [[ -f "$QS" ]]; then` (line 228). The walk ran only in `skipped` afterwards (lines 104-113).

**Evidence:** `git show 71e618d:scripts/dev-cycle.sh` lines 92, 104-114, 228

---

## Claim 24: "inrepo is now blocker() first, then the raw check (rawfile)." (commit 591f098)

**Location:** commit 591f098 message; `scripts/dev-cycle.sh:117`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the definition. It does not establish anything beyond `inrepo`'s call sites (Claim 8).

`inrepo() { [[ -z "$(blocker "$1" file)" ]] && rawfile "$1"; }` (`:117`).

**Evidence:** `scripts/dev-cycle.sh:117`

---

## Claim 25: "The two glob loops call rawfile directly, since their directory has already passed plaindir, which keeps them at one realpath per item." (commit 591f098)

**Location:** commit 591f098 message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers the per-item `realpath` count. It does not judge whether the extra cost matters (skipped items are rare).

A readable item costs one `realpath` (`rawfile`, `:92`). A skipped item that exists also goes through `skipped "$f"` → `blocker`, which calls `plaindir` on each parent and `rawfile` again (`:108`, `:112`). For a cycle record that is 1 + 3 + 1 = 5 calls, and for a decision record 1 + 2 + 1 = 4 (paraphrased — no quote available because the count comes from tracing the call chain, not from one line). Precise version: "one realpath per readable item".

**Evidence:** `scripts/dev-cycle.sh:92`, `:103-113`, `:149-152`, `:203`

---

## Claim 26: "22/22; shellcheck clean." (commit 591f098)

**Location:** commit 591f098 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** maintainer
**Scope:** Covers the 591f098 copies of the script and test file. It does not establish shellcheck on the test file.

`timeout 300 bats fc13/pin/test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-digest`, exit 0, 2026-10-01T23:04:27-07:00, 22/22; `timeout 60 shellcheck fc13/pin/scripts/dev-cycle.sh`, exit 0, empty.

**Evidence:** `fc13/bats-pinned.log`, `fc13/shellcheck-pinned.log`

---

## Claim 27: "the two branches no longer overlap" and "keep/drop answers are applied in step 6 from questions.md and the archive (step 1 has already archived them) before deciding to ask" (commit 44d06b7)

**Location:** commit 44d06b7 message; `skills/dev-cycle/SKILL.md:100-110`, `:221-229`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** maintainer
**Scope:** Covers that the message describes the diff. It does not establish one-time application of answers (Claim 15's residue) or the diagnosis wording (Claim 13b).

Bullet 2 opens with "Otherwise" (`SKILL.md:108`). Step 6 adds "Apply answers here, reading `questions-archive.md` too (step 1 has already archived answered entries), and apply each before deciding whether to ask again." (`:227-228`) and "(or does not exist yet)" (`:224`). Step 1 archives (`:123`).

**Evidence:** `skills/dev-cycle/SKILL.md:100-110`, `skills/dev-cycle/SKILL.md:116-124`, `skills/dev-cycle/SKILL.md:221-229`

---

## Claims Requiring Attention

### Incorrect
- **Claim 12b** (`scripts/dev-cycle.sh:353`): section 8's header says nothing below a listed directory was "probed", but the glob gates at :146/:201 run `-d`/`realpath` through a symlinked `docs/` or `docs/working/`. No output changes. Either drop "or probed" or put the walk in front of the gates.
- **Claim 17b** (`test/scripts/dev-cycle.bats:180-181`): "(nothing below it is probed)": the script probes `docs/working/cycles` in exactly this setup. The test only checks listing.
- **Claim 20b** (commits 6d6637d, 591f098): "nothing below it is probed" for a symlinked `docs/`/`docs/working/`. 591f098 fixed only `inrepo`, and the same kind of lookup remains in the two glob gates.

### Stale
- None.

### Mostly Accurate
- **Claim 13b** (`skills/dev-cycle/SKILL.md:104-105`): "a record exists but…" — the Window variant also prints when no record exists (cycles dir is a file, or a symlinked ancestor holds no records), and section 8 may list more than "the path".
- **Claim 19** (commit 6d6637d): "skipnote names it in every inline note": true of the four per-input notes. Section 2's summary note and the Window line name no part.
- **Claim 25** (commit 591f098): "one realpath per item": one per *readable* item. A skipped item costs 4–5.

### Unverifiable
- None.

---

## Goal-Alignment Note

Success criterion (verbatim from the brief): "a markdown report saved at the path your role instructions give, structured per your skill file."

This report is saved at `/workspace/.claude/wt-digest/docs/reviews/code-fact-check-report-digest-pass13.md`, uses the skill's header and per-claim fields plus the requested `Commit:` first line, `**Replication:**` header and `**Legibility-target:**` tags, and covers the brief's priority list (`blocker` and its two modes, every listed call site including the cycle and decisions globs and `$QS`, section 8 / inline notes / Window agreement, plain and absent inputs, the four comments, tests 6, 7, 10, commits 6d6637d, 591f098, 44d06b7, and step 0's bullets against every Window variant). The one behavioral finding (Claims 12b/17b/20b) is the same no-output-change kind of probe 591f098 fixed in `inrepo`, left in the glob gates. Nothing outside this file and the scratch directory was written. Nothing was committed.
