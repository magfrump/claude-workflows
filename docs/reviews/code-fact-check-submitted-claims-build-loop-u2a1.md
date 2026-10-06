Commit: d07cc89c

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a1 (claude-workflows, branch feat/build-loop-u2a1)
**Scope:** Stage 2.5 of the U2a1 final confirming pass: the 15 critic endorsements submitted below (Claims 53-67), verdicted at d07cc89c; nothing harvested from the diff
**Checked:** 2026-10-06
**Total claims checked:** 15
**Summary:** 14 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution notes, for every `executed` claim below: probes ran on `git archive` copies of d07cc89c, 900c47d0 and d48f4645 under `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/s25/c-<sha>/` (mutants on separate copies `m59a`, `m59b`, `m67a`, `m67b`), with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, each process under `timeout`. Bats runs used `TMPDIR=/tmp/u2a1s25-5CMy` (no dot-prefixed component). Probe scripts are in the scratch dir (`p53.sh` ... `p65.sh`, `fixture.sh`); captured output is under `docs/reviews/execution-logs/u2a1-s25/`. The `bash: warning: setlocale` lines in some logs come from the session's `LC_ALL=en_US.UTF-8` (not installed) and do not affect results. No tracked file was modified. `docs/reviews/hallucination-patterns.md` was read; no claim matches a logged pattern.

---

## Submitted Claims

## Claim 53: "Every current consumer of main_entry (check_brief, check_answer, build-loop.sh main_file; brief_fields) refuses on every word other than `blob` and `absent` at d07cc89c, including `badform`."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:354-359`, `scripts/lib/dev-cycle-read.sh:573-577`, `scripts/build-loop.sh:129-134`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four call sites of `main_entry` in `scripts/` at d07cc89c and their handling of the words blob, absent, badform, notfile, `notdir docs/working`, error, an unknown word, an empty word and a word with a space; does not establish what `main_entry` itself answers for a given tree (that is Claims 57 and 62), and brief_fields refuses `absent` as well (it accepts only `blob`), which the claim does not contradict.

The consumer set is complete: `git grep` for `main_entry` outside comments finds only `scripts/lib/dev-cycle-read.sh:316` (brief_fields), `:354` (check_brief), `:572` (check_answer) and `scripts/build-loop.sh:129` (main_file) (paraphrased — no quote available because the claim covers absence of other call sites; repo-wide grep result). Each has a catch-all refusal:

```bash
# scripts/lib/dev-cycle-read.sh:354-359 (check_brief; enclosing function :343-380 — read)
  e="$(main_entry "$a")"
  case "$e" in
    absent) echo "ok $a new"; return ;;
    blob) ;;
    *) echo "skip $a: $(entry_why "$e" "")"; return ;;
  esac
```

```bash
# scripts/lib/dev-cycle-read.sh:572-577 (check_answer; enclosing function :567-593 — read)
    e="$(main_entry "$f")"
    case "$e" in
      absent) continue ;;
      blob) ;;
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
    esac
```

```bash
# scripts/build-loop.sh:129-134 (main_file; enclosing function :126-141 — read)
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
  esac
```

`scripts/lib/dev-cycle-read.sh:316` (brief_fields): `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi`.

Executed: `p53.sh` sources the d07cc89c lib, evals `main_file` out of the d07cc89c `build-loop.sh`, stubs `main_entry` to print each word in turn, and calls all four consumers in a fixture repo. For every word but blob/absent, check_brief and check_answer print a `skip` line, main_file returns 1 with a reason, and brief_fields returns 1 with `BRIEF_ODD=error`; badform gives `skip docs/working/briefs/2026-01-01-c.md: not an allowed path form`. For `absent`, check_brief prints `ok ... new`, check_answer moves on to the next file, main_file sets `FILE_WHY=absent`.

Command: `timeout 60 bash p53.sh c-d07cc89c/scripts/lib/dev-cycle-read.sh c-d07cc89c/scripts/build-loop.sh fx53`; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:18:01Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:316`, `scripts/lib/dev-cycle-read.sh:354-359`, `scripts/lib/dev-cycle-read.sh:572-577`, `scripts/build-loop.sh:129-134`, docs/reviews/execution-logs/u2a1-s25/c53-consumers-stubbed.txt

---

## Claim 54: "Of 11 path candidates (`closed/../`, `closed//`, `closed/closed/`, a subdirectory, a newline suffix, `Closed/`, an uppercase slug, a trailing `/`, a leading `./`, a short date, and the plain path), isclosed and writable accept only `docs/working/briefs/closed/2026-01-01-x.md` (plain shape)."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:157-162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exactly the 11 named candidate shapes (each built on `docs/working/briefs/closed/2026-01-01-x.md`) against `isclosed` and `writable` at d07cc89c; does not establish behaviour for shapes outside that list (other Unicode case folds, other slugs), nor that callers reach `writable`/`isclosed` only after `pathform`.

```bash
# scripts/lib/dev-cycle-read.sh:157-162
isbrief() { [[ "$1" =~ ^docs/working/briefs/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; }
isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }
writable() {
  [[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ \
    || "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]] || isbrief "$1" || isclosed "$1"
}
```

Executed (`p54.sh`): ten candidates print `isclosed=refuse writable=refuse`; only `docs/working/briefs/closed/2026-01-01-x.md` prints `isclosed=accept writable=accept`. The newline-suffixed candidate was built with `$'...\n'` and is shown `%q`-quoted in the log.

Command: `timeout 30 bash p54.sh c-d07cc89c/scripts/lib/dev-cycle-read.sh`; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:17:36Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:157-162`, docs/reviews/execution-logs/u2a1-s25/c54-isclosed-writable.txt

---

## Claim 55: "After 91469367, check_answer has one catch-all refusal arm for every main_entry word but blob/absent, and no caller branches on a specific refusal word, so a new word needs one edit (entry_why)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:574-577`, `scripts/lib/dev-cycle-read.sh:356-359`, `scripts/build-loop.sh:130-134`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four main_entry consumers' case arms at d07cc89c and the 91469367 fold of check_answer's two arms into one; does not establish that a new word needs no edit in `main_entry` itself (which must emit it) or in its header comment, and a word with no `entry_why` arm is already refused and worded by `entry_why`'s default arm, so the one edit is needed only for a dedicated wording.

`git diff d48f4645 91469367 -- scripts/` shows check_answer's `notdir\ *)` arm and `*)` arm replaced by one arm:

```bash
# scripts/lib/dev-cycle-read.sh:576
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
```

check_brief (`:358`, `*) echo "skip $a: $(entry_why "$e" "")"; return ;;`) and main_file (`scripts/build-loop.sh:133`, `*) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;`) likewise name only `blob` and `absent`; brief_fields (`:316`) tests only `!= blob`. No other script code compares a main_entry word (paraphrased — no quote available because the claim covers absence: `git grep` for `main_entry` in `scripts/` finds only these four call sites). The only `FILE_WHY` comparisons in build-loop.sh are to `absent` (`scripts/build-loop.sh:214`, `:217`, `:264`). Wording lives in one function:

```bash
# scripts/lib/dev-cycle-read.sh:289-295 (entry_why, enclosing :286-296 — read)
  case "$w" in
    notdir\ *) echo "${w#notdir } is not a directory on the default branch" ;;
    notfile) echo "${p:+$p is }not a regular file on the default branch" ;;
    badform) echo "${p:+$p is }not an allowed path form" ;;
    error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;
    *) echo "the default branch answered $w${p:+ for $p}" ;;
  esac
```

Executed: the Claim 53 probe fed the unlisted words `odd` and `weird word` to every consumer; all four refused, worded by the default arm (`the default branch answered weird word for docs/working/questions.md`), with no consumer edit.

Command: as Claim 53 (`p53.sh`); cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:18:01Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:286-296`, `scripts/lib/dev-cycle-read.sh:316`, `scripts/lib/dev-cycle-read.sh:356-359`, `scripts/lib/dev-cycle-read.sh:574-577`, `scripts/build-loop.sh:130-134`, `scripts/build-loop.sh:214-217`, docs/reviews/execution-logs/u2a1-s25/c53-consumers-stubbed.txt

---

## Claim 56a: "Dependency direction is unchanged: no lib-to-script call, and entry_why [uses] no git and no globals" (and isclosed uses no git)

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:158`, `scripts/lib/dev-cycle-read.sh:286-295`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers references from the lib to functions defined only in `scripts/dev-cycle.sh` or `scripts/build-loop.sh`, at d07cc89c and at 900c47d0, plus the bodies of `entry_why` and `isclosed` (with `isbrief`); does not cover the lib's documented reliance on the caller setting `ROOT_REAL` (a variable contract, not a call), which is unchanged.

Executed (`p56.sh`): for every function defined in either script, grep the lib for the name outside column-0 comments. At both commits, the only hits are two indented comment lines (`:417`/`:401` "the exact ref", `:461`/`:445` "matches INSTRUCTION_FILE's names"). Neither script's name appears in lib code. Function bodies, as `declare -f` printed them (`p56b.sh`):

```bash
# scripts/lib/dev-cycle-read.sh:286-288 (entry_why)
entry_why() {
  local w="${1//$'\n'/ }" p="${2-}"
  p="${p//$'\n'/ }"
```

entry_why reads only `$1`, `$2` and its locals `w` and `p` (the rest of its body is the case statement quoted in Claim 55). Neither entry_why nor isclosed/isbrief contains a `git` call (`scripts/lib/dev-cycle-read.sh:157-158`, quoted in Claim 54).

Commands: `timeout 30 bash p56.sh c-<sha>` for d07cc89c and 900c47d0 (exit 0, 2026-10-06T17:19:27Z); `timeout 30 bash p56b.sh c-d07cc89c/scripts/lib/dev-cycle-read.sh` (exit 0, 2026-10-06T17:19:37Z); cwd `/workspace/.claude/wt-build-loop-u2a1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:157-158`, `scripts/lib/dev-cycle-read.sh:286-296`, docs/reviews/execution-logs/u2a1-s25/c56-lib-to-script.txt, docs/reviews/execution-logs/u2a1-s25/c56-isclosed-globals.txt

---

## Claim 56b: "isclosed use[s] no git and no globals"

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:158`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers isclosed's own body and its one callee, isbrief; does not establish anything about mutable state beyond the two constants named.

isclosed names no global itself, but its callee reads two lib-level globals:

```bash
# scripts/lib/dev-cycle-read.sh:155-158
DIGIT='[0123456789]'
SLUG='[abcdefghijklmnopqrstuvwxyz0123456789-]+'
isbrief() { [[ "$1" =~ ^docs/working/briefs/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; }
isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }
```

Executed (`p56b.sh`): with the default globals, `isclosed docs/working/briefs/closed/2026-01-01-x.md` accepts. After `SLUG='[q]+'` the same call refuses, so isclosed's answer depends on a global. The claim's point holds: no git, and no runtime state such as `MAIN_SHA` or `ROOT_REAL`. A precise version: "isclosed runs no git and reads only the lib's constant patterns DIGIT and SLUG, through isbrief".

Command: `timeout 30 bash p56b.sh c-d07cc89c/scripts/lib/dev-cycle-read.sh`; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:19:37Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:155-158`, docs/reviews/execution-logs/u2a1-s25/c56-isclosed-globals.txt

---

## Claim 57: "main_entry's comment states the guard order (main_by_name, then pathform) and that every word but blob/absent is a refusal, and the code matches."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:257-260`, `scripts/lib/dev-cycle-read.sh:267-268`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the header sentences on guard order and on refusal words, and main_entry's two guards and its output words; that consumers treat the words as refusals is Claim 53. Does not establish the header's other statements (the duplicate-name and ls-tree-failure meanings of `error`).

```bash
# scripts/lib/dev-cycle-read.sh:256-260 (comment)
# check saw, so this answers error instead). Only blob reads the file, and only
# absent means there is none: every other word is a refusal. It runs
# main_by_name, then pathform, itself, before any read (so with no default
# branch even a refused form answers error; pathform also means ls-tree prints
# the name unquoted). entry_why words the refusals. One ls-tree call lists the
```

```bash
# scripts/lib/dev-cycle-read.sh:266-267 (main_entry, enclosing :263-280 — read)
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
```

The cited `:267-268` is off by one: the guards are at `:266-267`, and `:268` is the `want` loop. main_entry's remaining outputs are `error`, `absent`, `notdir $p`, `blob` and `notfile` (`:269-279`). Executed: test 74 (`main_entry answers badform ...`) passes at d07cc89c, and its last line checks the order (`MAIN_SHA=""; main_entry .gitattributes` answers `error`). With the guards swapped (mutant M2, Claim 67), the same line answers `badform` and the test fails.

Command: `cd c-d07cc89c && timeout 300 bats -f 'main_entry answers badform for a path pathform refuses' test/scripts/dev-cycle.bats`; exit 0; 2026-10-06T17:18:54Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:248-280`, `test/scripts/dev-cycle.bats:1356-1369`, docs/reviews/execution-logs/u2a1-s25/c67-mutants.txt

---

## Claim 58: "isclosed is the single spelling of the closed/ rule across writable, check_brief and shared_branches, and its prefix guard is pinned by a test (dropping it fails a test)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:158`, `scripts/lib/dev-cycle-read.sh:161`, `scripts/lib/dev-cycle-read.sh:348`, `scripts/build-loop.sh:318`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers code under `scripts/` at d07cc89c (comments and message text excluded) and the prefix-guard mutant; does not establish that docs restating the closed/ rule (the check_brief message text `docs/working/briefs/[closed/]YYYY-MM-DD-<slug>.md`, `:349`) stay in step.

The three uses call isclosed: `:161` (`... || isbrief "$1" || isclosed "$1"`), `:348` (`if ! isbrief "$a" && ! isclosed "$a"; then`) and `scripts/build-loop.sh:318` (`if ! { isbrief "$f" || isclosed "$f"; } || ! brief_fields "$f"; then continue; fi`). `rg -n closed scripts/` with comment lines excluded finds no other closed/ path rule. The other hits are "failing closed" in self-improvement.sh, the `never closed` fence messages, and the check_brief message text (paraphrased — no quote available because the claim covers absence of other spellings; grep result). The diff from 900c47d0 removes the two earlier spellings: the closed/ regex in writable and check_brief, and `${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}` in shared_branches.

Executed: mutant M1 (on a copy) drops the guard, leaving `isclosed() { isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }`. Test 75 (`a closed brief is a closed/ path only ...`) then fails because `--check-write 2026-01-01-x.md` answers `ok 2026-01-01-x.md`. The unmutated copy passes it.

Command: `cd m67a && timeout 300 bats -f 'a closed brief is a closed/ path only' test/scripts/dev-cycle.bats`; exit 1 (control on c-d07cc89c: exit 0); 2026-10-06T17:18:54Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:158`, `scripts/lib/dev-cycle-read.sh:161`, `scripts/lib/dev-cycle-read.sh:348`, `scripts/build-loop.sh:318`, `test/scripts/dev-cycle.bats:1371-1378`, docs/reviews/execution-logs/u2a1-s25/c67-mutant-diffs.txt, docs/reviews/execution-logs/u2a1-s25/c67-mutants.txt

---

## Claim 59: "fixture-git-env.bats fails loudly if a filtered test is renamed (it requires `1..1` and `ok 1`), so its name coupling to the two suites cannot pass vacuously."

**Submitted by:** architecture-review
**Location:** `test/scripts/fixture-git-env.bats:17-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers renaming either target test so that its `-f` filter matches nothing; does not establish failure when a filter matches 10-19 tests, since the glob `*"1..1"*"ok 1 "*` also matches `1..10`-`1..19` output whose first test passes (no current filter is close to that; Claim 64).

```bash
# test/scripts/fixture-git-env.bats:17-22 (victim_unchanged, whole function)
victim_unchanged() {
    # The inner run must have run one test and passed, or this proves nothing.
    [ "$status" -eq 0 ] && [[ "$output" == *"1..1"*"ok 1 "* ]] || { echo "$output"; return 1; }
    [ "$(git -C "$V" rev-list --all --count)" = 1 ] && [ "$(git -C "$V" for-each-ref --format=x | wc -l)" = 1 ] \
        || { git -C "$V" log --all --oneline | head; git -C "$V" for-each-ref; return 1; }
}
```

Executed on copies: `m59a` renames dev-cycle.bats's `prints all eight sections in a repo with no docs`, and `m59b` renames build-loop-read.bats's `--settings: an exact policy line is set, a trailing CR included (T1)`. In each, the matching fixture-git-env test fails at line 19, with the inner output `1..0` echoed, and the suite exits 1. The other test still passes. The unmutated copy passes both (exit 0).

Command: `cd <copy> && timeout 300 bats test/scripts/fixture-git-env.bats` for c-d07cc89c, m59a and m59b; exit 0 / 1 / 1; 2026-10-06T17:18:40Z.

**Evidence:** `test/scripts/fixture-git-env.bats:17-32`, docs/reviews/execution-logs/u2a1-s25/c59-rename-target.txt

---

## Claim 60: "No script or doc outside test/ and docs/reviews/ parses or quotes a main_entry refusal reason (entry_why output)."

**Submitted by:** api-consistency-reviewer
**Location:** repo-wide; the reason is produced at scripts/lib/dev-cycle-read.sh:286 and spliced at scripts/build-loop.sh:133
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tracked files at d07cc89c outside `test/` and `docs/reviews/`, searched for each `entry_why` reason phrase, the old pre-U2a1 wording, and `entry_why`/`FILE_WHY` uses; does not cover consumers outside this repo that might read the scripts' printed lines, and build-loop.sh does relay the reason unparsed inside its own output lines (`never malformed: $why`, `constraints unreadable: $FILE_WHY`).

Executed `git grep -F` at d07cc89c (excluding `test/` and `docs/reviews/`) for each reason phrase: "is not a directory on the default branch", "not a regular file on the default branch", "tree of the default branch could not be read" and "default branch answered" match only entry_why's own lines (`scripts/lib/dev-cycle-read.sh:290-294`). "not an allowed path form" also matches the separate pathform skip messages at `scripts/dev-cycle.sh:146,152,162,173` and `scripts/lib/dev-cycle-read.sh:347`, which are the scripts' own messages and not entry_why output. The old wordings ("default branch's tree", "could not be read for") and the relayed prefixes ("never malformed", "constraints unreadable") appear in no doc or skill. The only non-script `entry_why` hit is a plan bullet naming the function (`docs/working/plan-build-loop-handoff.md:274`), not a reason. build-loop.sh compares `FILE_WHY` only to `absent`:

```bash
# scripts/build-loop.sh:214
    [[ "$FILE_WHY" == absent ]] && why="no $f on the default branch" || why="$FILE_WHY"
```

and interpolates the reason unparsed (`scripts/build-loop.sh:217`, `:265`). In the docs-search log the `exit=` lines are `cut`'s status; empty match lists there mean no hits.

Commands: `git grep -n -F '<phrase>' d07cc89c -- . ':!test/' ':!docs/reviews/'` (and a second set also excluding `scripts/`); cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:19:04Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:290-294`, `scripts/build-loop.sh:214-217`, `scripts/build-loop.sh:264-265`, docs/reviews/execution-logs/u2a1-s25/c60-reason-grep.txt, docs/reviews/execution-logs/u2a1-s25/c60-reason-grep-docs.txt

---

## Claim 61: "`${2-}` and `${2:-}` produce the same value of p for every argument list entry_why can receive."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:286-288`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default-value expansion for every arity (unset, set-empty, set-nonempty $2), with and without `set -u`; does not establish anything about the newline replacement on the next line, which is the same for both spellings.

```bash
# scripts/lib/dev-cycle-read.sh:287-288
  local w="${1//$'\n'/ }" p="${2-}"
  p="${p//$'\n'/ }"
```

The two forms differ only when the parameter is set but empty: `${2-}` gives the empty value and `${2:-}` gives the default. Here the default is also empty, so the results are the same. Executed (`p61.sh`): with 0, 1, 2 (empty, nonempty, newline) and 3 arguments, and again under `set -u`, every case prints `same`.

Command: `timeout 30 bash p61.sh`; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:17:36Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:286-288`, docs/reviews/execution-logs/u2a1-s25/c61-param-expansion.txt

---

## Claim 62: "check_brief's notdir, notfile and error skip lines at d07cc89c are byte-identical to main's (900c47d0)."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:354-359`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_brief's skip lines for one real notdir case (`docs/working/briefs/closed` stored as a symlink), one notfile case (a brief stored as a symlink) and error (forced by an unreadable `MAIN_SHA`), from the same fixture under both libs; does not cover check_answer or main_file (whose wording did change on purpose), nor the badform line, which is new.

At 900c47d0, check_brief spelled the three lines inline (`notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch"`; `error) echo "skip $a: the tree of the default branch could not be read"`; `*) echo "skip $a: not a regular file on the default branch"`, per `git diff 900c47d0 d07cc89c`). At d07cc89c it uses `*) echo "skip $a: $(entry_why "$e" "")"; return ;;` (`:358`), and with an empty `$2` entry_why's `${p:+...}` parts drop out. Executed (`p62.sh`) on the fixture from `fixture.sh`, under each copy's lib: the outputs (main_entry words plus the three skip lines) are the same in full (`diff` is empty and `cmp` reports the files identical), e.g. `skip docs/working/briefs/2026-01-01-b.md: not a regular file on the default branch`.

Command: `timeout 30 bash p62.sh c-<sha>/scripts/lib/dev-cycle-read.sh fx53` for d07cc89c and 900c47d0; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0 both; 2026-10-06T17:18:10Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:343-380`, docs/reviews/execution-logs/u2a1-s25/c62-check-brief-d07cc89c.txt, docs/reviews/execution-logs/u2a1-s25/c62-check-brief-900c47d0.txt

---

## Claim 63: "badform is answered before any git call, so a refused path form costs no ls-tree fork."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:267-268`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git invocations made inside main_entry for refused forms when main is found by name; does not count the `$(main_entry ...)` command-substitution subshell the callers make in any case, and does not cover callers' own earlier pathform checks.

The guards (`:266-267`, quoted in Claim 57) come before the only git call, `:269` `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)"`. `main_by_name` (`:247`) is a pure `[[ ... ]]` test. Executed (`p63.sh`): with a logging `git` shell function, main_entry makes 0 git calls for `.gitattributes`, `../x`, `docs//x.md`, `-x` and `.github/x.yml` (all `badform`). The plain-path control makes 1 call (`git ls-tree ...`).

Command: `timeout 30 bash p63.sh c-d07cc89c/scripts/lib/dev-cycle-read.sh fx53 gitlog`; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:18:17Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:247`, `scripts/lib/dev-cycle-read.sh:263-280`, docs/reviews/execution-logs/u2a1-s25/c63-git-calls.txt

---

## Claim 64: "Each fixture-git-env `-f` filter selects exactly one test of its target suite."

**Submitted by:** performance-reviewer
**Location:** `test/scripts/fixture-git-env.bats:24-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two filters against the suites at d07cc89c; does not establish that future test names will not also match (`exact policy line is set` is unanchored).

```bash
# test/scripts/fixture-git-env.bats:25, :30
    run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f '^prints all eight sections' "$REPO_ROOT/test/scripts/dev-cycle.bats"
    run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f 'exact policy line is set' "$REPO_ROOT/test/scripts/build-loop-read.bats"
```

Executed: `bats --count -f` prints `1` for each filter. The matching tests are `test/scripts/dev-cycle.bats:40` and `test/scripts/build-loop-read.bats:13`.

Command: `timeout 60 bats --count -f '<filter>' c-d07cc89c/test/scripts/<suite>`; exit 0 both; 2026-10-06T17:18:23Z.

**Evidence:** `test/scripts/fixture-git-env.bats:24-32`, docs/reviews/execution-logs/u2a1-s25/c64-filter-counts.txt

---

## Claim 65: "Iteration 2's changes (91469367) leave dev-cycle.bats and build-loop-read.bats wall time within run-to-run noise of d48f4645 (time both, alternating, ≥3 runs each)."

**Submitted by:** performance-reviewer
**Location:** test/scripts/dev-cycle.bats:1, test/scripts/build-loop-read.bats:1 (whole suites)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whole-suite wall time on this 16-core host, 3 alternating runs per commit per suite, from `git archive` copies of d48f4645 and d07cc89c (whose scripts and these suites match 91469367's; d07cc89c adds only docs); does not separate script cost from test-count change (dev-cycle.bats has 74 tests at d48f4645 and 75 at d07cc89c) and is too few runs for a statistical test.

Executed (`p65.sh`, order d48f4645 then d07cc89c, repeated three times per suite; every run exit 0 with 0 failures):

| suite | d48f4645 runs (s) | d07cc89c runs (s) | median d48 / d07 |
|---|---|---|---|
| dev-cycle.bats | 18.60, 18.30, 15.29 | 15.53, 18.46, 18.39 | 18.30 / 18.39 |
| build-loop-read.bats | 9.17, 9.11, 9.03 | 9.11, 11.80, 9.11 | 9.11 / 9.11 |

The two commits' ranges overlap in both suites. Within each commit, run-to-run spread is about 3.3 s on dev-cycle.bats, and that is larger than the gap between the medians (0.09 s). The one high build-loop-read run (11.80 s) sits between two 9.11 s runs at the same commit (paraphrased — no quote available because the claim is about measured timings, not code).

Command: `timeout 3000 bash p65.sh /tmp/u2a1s25-5CMy` (each bats run under `timeout 600`); cwd `/workspace/.claude/wt-build-loop-u2a1` (runs cd into each copy); exit 0; started 2026-10-06T17:20:34Z.

**Evidence:** `docs/reviews/execution-logs/u2a1-s25/c65-timing.txt`

---

## Claim 66: "Iteration 2's script changes add no fork on any path: entry_why gains one in-function parameter expansion; check_answer's folded arm still makes one `$(entry_why …)` call before `return`."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:286-296`, `scripts/lib/dev-cycle-read.sh:567-580`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `git diff d48f4645 91469367 -- scripts/` (lib and dev-cycle.sh); does not cover forks added by earlier U2a1 commits (6f624cdf moved check_brief and main_file to `$(entry_why ...)`), which are outside iteration 2.

The iteration-2 script diff has three code changes. (1) entry_why's `local ... p="${2//$'\n'/ }"` becomes `local ... p="${2-}"` plus `p="${p//$'\n'/ }"` (`:287-288`): one extra builtin assignment with parameter expansion, and no command substitution or external command. (2) check_answer's two refusal arms, each `echo "skip $a: $(entry_why "$e" "$f"), ..."; return`, become the single `:576` arm with the same one `$(entry_why ...)` before `return`. (3) The rest is comment-only (lib header and main_entry header; `scripts/dev-cycle.sh:167` changes "message" to "messages" in a comment). The rest of check_answer (`:567-593`) was read in full and is unchanged by 91469367 (paraphrased — no quote available because the claim is about a diff; the full diff was read and is summarised above).

**Evidence:** `scripts/lib/dev-cycle-read.sh:286-296`, `scripts/lib/dev-cycle-read.sh:567-593`, `scripts/dev-cycle.sh:167-168`

---

## Claim 67: "Mutant M1 (drop isclosed's `closed/*` guard) fails the new closed-brief test; mutant M2 (swap main_entry's two guards) fails the badform/guard-order test."

**Submitted by:** test-strategy
**Location:** `test/scripts/dev-cycle.bats:1356-1378` (tests 74, 75)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named mutants against tests 74 and 75 (run by `-f` filter), each mutant made on its own `git archive` copy with the unmutated copy as control; does not establish that other tests in the suite also catch them, or that each test catches only its own mutant (the cross results are recorded: M1 passes test 74, and M2 passes test 75).

Mutant diffs (captured): M1 changes `:158` to `isclosed() { isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }`, and M2 swaps `:266` and `:267`. Results:

| copy | test 75 (closed brief) | test 74 (badform / order) |
|---|---|---|
| c-d07cc89c (control) | ok (exit 0) | ok (exit 0) |
| m67a (M1) | **not ok** (exit 1): `--check-write 2026-01-01-x.md` answered `ok 2026-01-01-x.md` | ok |
| m67b (M2) | ok | **not ok** (exit 1): last line `badform` instead of `error` |

`bats --count` at d07cc89c is 75, and these are its last two `@test`s (`test/scripts/dev-cycle.bats:1356`, `:1371`), so they are tests 74 and 75.

Command: `cd <copy> && timeout 300 bats -f '<test name>' test/scripts/dev-cycle.bats` for the three copies and two tests; exits as tabled; 2026-10-06T17:18:54Z.

**Evidence:** `test/scripts/dev-cycle.bats:1356-1378`, `scripts/lib/dev-cycle-read.sh:158`, `scripts/lib/dev-cycle-read.sh:266-267`, docs/reviews/execution-logs/u2a1-s25/c67-mutant-diffs.txt, docs/reviews/execution-logs/u2a1-s25/c67-mutants.txt

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 56b** (`scripts/lib/dev-cycle-read.sh:158`): isclosed runs no git, but through isbrief it reads the lib globals DIGIT and SLUG (reassigning SLUG changes its answer). Say "no git and no runtime state (only the constant patterns DIGIT/SLUG)".

### Unverifiable
(none)

---

## Goal-Alignment Note

**Success criterion (verbatim):** A report saved to docs/reviews/code-fact-check-submitted-claims-build-loop-u2a1.md inside the worktree, with `Commit: d07cc89c` as its first line, holding a `## Submitted Claims` section with one `## Claim N:` per submitted claim, numbered from 53.

- **Answered:** All 15 submitted claims (53-67) are verdicted, with the submitting critic, a verification mode and a Scope line on each. 14 are executed and one (66) is static. Claim 56 is split into 56a and 56b because its parts got different verdicts.
- **Out of scope:** No claims were harvested from the diff. No tracked file was modified. The only new files are this report and `docs/reviews/execution-logs/u2a1-s25/`. Claim 57's cited lines are off by one (the guards are at `:266-267`), which does not change the verdict.
- **Escalate:** Nothing blocking. The one minor point: Claim 56b's "no globals" is loose for isclosed.
