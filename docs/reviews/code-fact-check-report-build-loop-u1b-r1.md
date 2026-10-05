**Commit:** 1d79ffef

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1b (branch feat/build-loop-u1b)
**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` at 1d79ffef: comments, test titles/comments and commit messages in scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, plus commit 1d79ffef's message (earlier commits' claims re-verdicted only where HEAD changed the code they describe). Review iteration 3, replicate r1.
**Checked:** 2026-10-05
**Total claims checked:** 33 (31 numbered, two split into a/b)
**Summary:** 25 verified, 5 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Execution provenance: every executed claim ran with cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/fc-r1` (scratch; throwaway repos under `repos/`) or `/workspace/.claude/wt-build-loop-u1b` for the baseline only, between 2026-10-05T11:42Z and 11:50Z. Captured output (all in the scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/fc-r1/`, since this run may write only this report in the worktree):
- `baseline.log`: `bats test/scripts/build-loop-read.bats` in the worktree, `LC_ALL=C.UTF-8`, exit 0, 9/9 ok (11:42:51Z).
- `probes.log`: `./probe.sh NAME LINE...` (builds `repos/NAME` with `docs/dev-cycle.md` = the lines, commits it on main, runs `bash scripts/build-loop.sh --settings`), exit 0 (11:48Z).
- `replace-and-errors.log`: `bash replace-and-errors.sh` (replace refs, deleted objects, gitlink, absent file, scrub, -h, printf), exit 0 (11:48:05Z).
- `c3.log`: a copy `c3/bl.sh` whose settings arm presets `POLICY=self-merge; NEVER=(zz)` and calls read_settings twice with `declare -p` (11:49Z).
- `mut-{pathform,head,worktree,nonext}.log`: full copies of scripts/, test/, docs/ under `mut-NAME/`, one perl mutation of `scripts/build-loop.sh`, then `bats test/scripts/build-loop-read.bats` there, each exit 1 (11:45:41Z).

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): the logged class "specific measured value quoted from an artifact set that does not contain it" was checked against the "400 changed code lines" claim (Claim 29); it does not recur.

---

## Claim 1: "--settings three lines from the default branch's commit, never the working tree ... Each comes from one line of docs/dev-cycle.md; a second copy, or a file the lib's FENCE_AWK refuses, leaves the default (WHY says which)"

**Location:** `scripts/build-loop.sh:9-12`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the default-on-copy/refusal behaviour of all three lines; does not establish the never line's grammar (Claim 2).

True for policy (`review unset`) and slots (`3 default`). For the never line the default is `none`, but a second copy or a refused/unread file prints `malformed` (self-merge off), not the default:

```bash
# scripts/build-loop.sh:146
    elif [[ "${cnt[never]}" -gt 1 ]]; then NEVER_LINE="never malformed: $(many 'Self-merge never:' never)"; never_ok=""
# scripts/build-loop.sh:136
    if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi
```

Executed: two `Self-merge never:` lines print `never malformed: more than one line starts "Self-merge never:" (lines 1 and 3)`; a deleted blob prints `never malformed: docs/dev-cycle.md could not be read from the default branch`. The behaviour fails closed and `:23-24` ("Malformed (or a file not read) turns self-merge off") covers the unread file. Nothing covers the second copy. Precise version: "...leaves the default (the never line reads malformed)".

**Evidence:** `scripts/build-loop.sh:9-12`, `:132-136`, `:144-146`; probes.log (`### duplicate never`), replace-and-errors.log (`## blob object deleted`)

---

## Claim 2: never grammar — "single spaces, then a blank line or the end. A glob uses letters, digits, . _ - / * ? (a trailing / ignored when comparing), has no empty, . or .. part, does not start with / or -, and is listed once. Malformed (or a file not read) turns self-merge off."

**Location:** `scripts/build-loop.sh:18-24`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the character set, part rules, duplicate detection (including bash-special subscripts `*` and `?` in the `seen` associative array), the blank-line/EOF rule and turning self-merge off; does not establish what "the line after" is when fence() skips it (Claim 9) or how later modes match these globs.

Duplicate detection is a per-key lookup even for `*`: `seen[${g%/}]` with `g='*'` is a key lookup, not `${seen[*]}`:

```bash
# scripts/build-loop.sh:156-160
        for g in "${parts[@]}"; do
          i=$((i + 1))
          if ! globform "${g%/}"; then why="lists entry $i, which is not an allowed glob form"; break; fi
          if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"; break; fi
          seen[${g%/}]=1
```
(excerpt ends :160; enclosing read_settings() continues to :179 — read)

Executed: `a/ *` and `* a/` → `set`; `* *`, `? ?` and `a a/` → `lists entry 2 twice`; `a a//` → entry 2 is not an allowed glob form (one trailing `/` stripped, the rest gives an empty part). The never line at EOF, followed by a whitespace-only line, or (CRLF file) by `\r\n` → `set`. Followed by `b/` → malformed. With `Build-loop policy: self-merge`, every malformed case prints `policy review unset: line 1 reads self-merge, but the Self-merge never: line is malformed, so self-merge is off` (T45 loop, baseline ok 7).

**Evidence:** `scripts/build-loop.sh:148-165`, `:170-172`; probes.log (`### Self-merge never: ...`, `### never at EOF`, `### never then whitespace-only line`); baseline.log

---

## Claim 3a: "A line counts as a copy when its letters alone, case folded, start with the key's ("buildlooppolicy")"

**Location:** `scripts/build-loop.sh:25-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the matching rule as implemented, ASCII letters only (awk runs under `env LC_ALL=C`, so a non-ASCII letter's bytes are dropped like punctuation); does not establish that every rendered copy is caught (Claim 3b).

```awk
# scripts/build-loop.sh:101-104
  s = tolower($0); gsub(/[^a-z]/, "", s); k = ""
  if (index(s, "buildlooppolicy") == 1) k = "policy"
  else if (index(s, "buildloopslots") == 1) k = "slots"
  else if (index(s, "selfmergenever") == 1) k = "never"
```

Executed: `- [ ]`, `1. `, `> > `, table cell, `Build-loop 2 policy`, NBSP-joined, mid-file BOM, one-line `<!-- -->` comment and `**Build-loop policy**: review` second lines all print `more than one line starts "Build-loop policy:"`. `Build-loop pólicy` (non-ASCII ó dropped → `buildloopplicy`) is not counted, as the rule says.

**Evidence:** `scripts/build-loop.sh:82` (`env LC_ALL=C awk`), `:101-105`; probes.log

---

## Claim 3b: "so markup, a table or a misplaced colon cannot hide one"

**Location:** `scripts/build-loop.sh:26-27`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers markup that adds letters before or inside the key; does not establish the tables and misplaced-colon parts (true, Claim 3a) or entity/zero-width copies (settled C19).

The letters-only rule keeps any letters that markup adds, so markup carrying letters ahead of or inside the key hides the copy. Executed, with `Build-loop policy: self-merge` on line 1 and each of these on line 2, the output stays `policy self-merge set: line 1 ...` (the copy is not counted):
- `- [x] Build-loop policy: review` and `- [X] ...` (GFM checked task item: letters `xbuildloop...`)
- `Build-loop <span>policy</span>: review` (inline HTML not at line start, so FENCE_AWK's rawhtml does not refuse it: letters `buildloopspanpolicy...`)
- `[Build-loop](x) policy: review` (a link that wraps only part of the key: letters `buildloopxpolicy`)

Never-line copies behave the same way. `[Self-merge](u) never: b/` and `- [x] Self-merge never: b/` after `Self-merge never: a/` leave `never a/ set:`, with no "more than one line". Each of these renders as the key. A Cyrillic-В homoglyph copy is also hidden; that is closer to C19's class. Override-log row C19 (line 248) settled only "an HTML entity or zero-width characters", on the premise that "such a copy does not render as the key either". That premise does not hold for these three shapes. Whether that row stretches to cover them is the orchestrator's call. Fails open only to the extent C19 describes: a hidden copy cannot raise the policy, but a contradicting rendered copy goes uncounted.

**Evidence:** `scripts/build-loop.sh:25-27`, `:101-105`; lib `FENCE_AWK` rawhtml (shared.md lib :189); probes.log (`### second line: - [x] ...`, `<span>`, `[Build-loop](x)`, `### never second line: ...`); docs/reviews/override-log.md:248

---

## Claim 4: "Acts on $PWD's git repo, like dev-cycle.sh ... Read-only: writes nothing. Output passes through the lib's scrub (but for the start-up errors about perl and the lib); printed repo text is data."

**Location:** `scripts/build-loop.sh:29-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the scrub ordering (perl/lib checks at `:38`, `:44` precede `scrub_reexec` at `:47`) and that only read-only git plumbing is called; does not establish scrub's own coverage limits (lib header :45-47).

`command -v perl ... exit 1` (`:38`) and `[[ -f "$READ_LIB" ]] || ... exit 1` (`:44`) run before `scrub_reexec "${BASH_SOURCE[0]}" "$@"` (`:47`). Executed: a usage argument holding ESC (`--bo\x1bgus`) reaches stderr as `Unknown option: --bogus` with the ESC removed. The git calls are `rev-parse`, `show-ref`, `symbolic-ref`, `ls-tree` and `cat-file` (paraphrased — no quote available because the calls span build-loop.sh `:58-65`, `:82` and lib `main_entry`/`resolve_main`). None of them writes.

**Evidence:** `scripts/build-loop.sh:38-47`, `:58-65`, `:82`; replace-and-errors.log (`## ESC in usage arg`)

---

## Claim 5: "Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:33-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers -h (exit 0, 33 lines = file lines 2-34, ending at the Exit line), usage, not-a-repo, renamed default branch and missing lib, plus every unread-file case exiting 0 with three lines; does not establish exit codes under signals or perl failure mid-run.

`-h|--help) sed -n '2,34p' "$0" | ...; exit 0` (`:53`). Executed: `-h` exits 0 and prints 33 lines. A deleted blob, a deleted tree, a gitlink and an absent file each exit 0 with three lines. Baseline tests 8 and 9 (exit 1 cases) pass.

**Evidence:** `scripts/build-loop.sh:49-56`, `:58`, `:65`; replace-and-errors.log; baseline.log (ok 8, ok 9)

---

## Claim 6: "Read main's own objects: a replace ref could swap in any settings blob." (`export ... GIT_NO_REPLACE_OBJECTS=1`)

**Location:** `scripts/build-loop.sh:62-63`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers replace refs on main's blob, root tree and commit for `--settings`; does not establish a test pinning it (no bats test covers replace refs) or behaviour under `GIT_REPLACE_REF_BASE`/grafts.

Executed: main's file reads `review` and branch `alt`'s reads `self-merge`. With `git replace` of main's blob, of `main^{tree}`, or of the main commit by alt's, plain `git cat-file blob main:docs/dev-cycle.md` returns `self-merge`. The script prints `policy review set:` in all three cases. A copy with ` GIT_NO_REPLACE_OBJECTS=1` deleted (`bl-norepl.sh`) prints `policy self-merge set:` in all three, so the export is what stops the swap.

**Evidence:** `scripts/build-loop.sh:63`; replace-and-errors.log (`## replace blob|tree|commit`)

---

## Claim 7: main_file — "FILE_OUT is what awk program $2 (after FENCE_AWK) printed over it; or it returns 1 with FILE_WHY "absent" or why it was not read (main_entry, a failed read, or FENCE_AWK's "odd N WHY" / "unbalanced N")."

**Location:** `scripts/build-loop.sh:67-69`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every arm (absent, notdir, error, notfile, failed cat-file, odd, unbalanced) and that each reaches the printed lines; does not establish main_entry's duplicate-name `error` branch (not built).

```bash
# scripts/build-loop.sh:77-83
    absent) FILE_WHY=absent; return 1 ;;
    notdir\ *) FILE_WHY="${e#notdir } is not a directory on the default branch"; return 1 ;;
    error) FILE_WHY="the default branch's tree could not be read for $f"; return 1 ;;
    *) FILE_WHY="$f is not a regular file on the default branch"; return 1 ;;
  esac
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")" \
    || { FILE_WHY="$f could not be read from the default branch"; return 1; }
```
(excerpt ends :83; enclosing main_file() continues to :88 — read)

Executed (main_entry's `error` comes from a missing tree object, which makes `ls-tree` fail): `the default branch's tree could not be read for docs/dev-cycle.md`. Missing blob object: `docs/dev-cycle.md could not be read from the default branch` (pipefail carries cat-file's failure out of `$(...)`). Gitlink: `is not a regular file`. Absent: `no docs/dev-cycle.md on the default branch`. odd/unbalanced/notdir/symlink/directory: T3 (baseline ok 3).

**Evidence:** `scripts/build-loop.sh:71-88`; replace-and-errors.log; baseline.log (ok 3)

---

## Claim 8: SETTINGS_AWK — "per key, how many lines start with it once everything but letters is dropped and case folded (so markup, blanks, a BOM or a misplaced colon cannot hide a copy)"

**Location:** `scripts/build-loop.sh:90-92`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the "markup cannot hide a copy" parenthetical, the same defect as Claim 3b; does not re-verdict the count/line-number fields, which match `:105`, `:110` (Verified).

The rule is as stated (Claim 3a). The parenthetical's "markup ... cannot hide a copy" is refuted by the same executed probes as Claim 3b: a GFM `[x]` task box, mid-line inline HTML and a link wrapping part of the key all hide a copy. Blanks, a mid-file BOM and a misplaced colon do not hide one (probes.log, T45 `'Self-merge never : b/'`).

**Evidence:** `scripts/build-loop.sh:90-94`, `:101-105`; probes.log

---

## Claim 9: "whether the line after the first is blank (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:92-93`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what NEXT records when the next physical line is skipped by `fence($0) { next }`, at EOF, and for whitespace-only/CRLF lines; does not establish CommonMark paragraph rules beyond the probed shapes.

```awk
# scripts/build-loop.sh:97-100
{ sub(/\r$/, "") }
fence($0) { next }
{
  if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }
```
(excerpt ends :100; enclosing SETTINGS_AWK continues to :111 — read)

NEXT is decided by the next line that fence() does not skip. If there is none, the `nx[k] = 1` default at `:105` makes EOF count as blank. When the never line is followed directly by a code fence, the fence lines are skipped. The line after the closing fence then decides. Executed: `Self-merge never: a/` + fence + `''` → `never a/ set`. The same with `b/` after the fence → `never malformed: line 1 is followed by a non-blank line (Markdown would join it as more globs)`. A following one-line `<!-- c -->` → the same malformed WHY. In both malformed cases the printed rationale is false: a fence or an HTML comment block interrupts the paragraph, so Markdown joins nothing. Fails closed. Precise version: "whether the next line FENCE_AWK reads (the end counts) is blank".

**Evidence:** `scripts/build-loop.sh:97-111`, `:152`; probes.log (`### never then fence ...`, `### never then one-line comment`)

---

## Claim 10: globform — "pathform's rule, but a .git* part (.github/) is allowed, since the list only adds refusals"

**Location:** `scripts/build-loop.sh:112-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the difference from lib `pathform` (the `[.][gG][iI][tT]*` part test dropped, `*?` always allowed); does not establish how later modes match the globs.

`[[ -n "$c" && "$c" != "." && "$c" != ".." ]] || return 1` (`:119`). Lib pathform also has `&& "$c" != [.][gG][iI][tT]*` (lib :147). Executed mutant `pathform` (`globform "${g%/}"` → `pathform "${g%/}" glob`) fails T45 at bats `:130` (`never .github/ .gitignore set:`).

**Evidence:** `scripts/build-loop.sh:114-121`; mut-pathform.log

---

## Claim 11: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (an array of the checked globs, each as written, a trailing / kept) and NEVER_LINE from main's commit." + reset `POLICY=review; NEVER=()` (C3)

**Location:** `scripts/build-loop.sh:122-124`, `:130`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the array shape, the trailing `/` being kept, and the reset across a second call; does not establish the forward reference to --status/the gate (U1c/U2, not in this diff).

`else NEVER=("${parts[@]}"); NEVER_LINE="never $v set: ..."` (`:164`). The three *_LINE variables are assigned on every path (`:134`, `:136`, `:145-165`, `:166-177`). Executed: in `c3/bl.sh`, with `POLICY=self-merge; NEVER=(zz)` preset, read_settings on an absent file gives `POLICY="review"` and `NEVER=()`, the same on a second call. On `Self-merge never: a/ b/` it gives `NEVER=([0]="a/" [1]="b/")`.

**Evidence:** `scripts/build-loop.sh:125-179`; c3.log

---

## Claim 12: "An absent file sets nothing; one that is not read turns self-merge off."

**Location:** `scripts/build-loop.sh:135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the never line's `none` vs `malformed` choice; does not establish that a reader honours "malformed" (later modes).

Executed: absent → `never none: no docs/dev-cycle.md on the default branch`. Missing blob, missing tree and gitlink → `never malformed: ...`. POLICY stays `review` in all of them (`:130`).

**Evidence:** `scripts/build-loop.sh:132-136`; replace-and-errors.log

---

## Claim 13: "Self-merge never: first, because a malformed line turns self-merge off."

**Location:** `scripts/build-loop.sh:144`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the ordering dependency (`never_ok` is set before the policy arm reads it); does not establish slots' independence (true by reading `:174-177`).

`if [[ "$v" == self-merge && -z "$never_ok" ]]; then POLICY_LINE="policy review unset: ... so self-merge is off"` (`:170-171`) reads `never_ok`, which `:146`/`:163` clear. Executed: each malformed case in T45 and probes.log prints that policy line.

**Evidence:** `scripts/build-loop.sh:144-172`; probes.log; baseline.log (ok 7)

---

## Claim 14: "Split on single spaces only; globform then refuses any other blank in an entry." / "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:149`, `:155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers tabs (left inside an entry by `IFS=' '` and refused by globform's character class) and the no-glob-expansion read; does not establish VT/FF (globform's class excludes them too, by reading).

`IFS=' ' read -ra parts <<<"$v"` (`:155`) does not expand globs. Glob characters reach `parts` as written (`a/ *` → `never a/ * set`). The T45 tab cases (`a\tb`, `\ta`, `a\t`, `a \tb`) are malformed and not echoed (baseline ok 7). The bare-`$v` statement is standard bash pathname expansion (paraphrased — no quote available because it describes code that is not there, an unquoted expansion).

**Evidence:** `scripts/build-loop.sh:149-161`; probes.log; baseline.log

---

## Claim 15: "a throwaway repo under $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the git variables and HOME; does not establish identity of other setup (the fixture also sets `LC_ALL=C`; C6 settled).

Fixture `:11-14` exports `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, the author/committer `t`/`t@example.invalid` and `HOME="$BATS_TEST_TMPDIR/home"`. `test/scripts/dev-cycle.bats:11-15` exports the same values.

**Evidence:** `test/lib/build-loop-fixtures.bash:7-19`; `test/scripts/dev-cycle.bats:8-18`

---

## Claim 16: "settings LINE...: ... With no lines the file holds one empty line."

**Location:** `test/lib/build-loop-fixtures.bash:24-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `printf '%s\n'` with no arguments; does not establish that any test calls `settings` with no arguments.

Executed `printf '%s\n' | od -c` → `0000000  \n`, one newline. `settings() { mkdir -p docs && printf '%s\n' "$@" > docs/dev-cycle.md && commit_all settings; }` (`:26`).

**Evidence:** `test/lib/build-loop-fixtures.bash:26`; replace-and-errors.log (`## printf`)

---

## Claim 17: "settings_is KEY WANT / settings_like KEY PREFIX: run --settings; its KEY line must equal WANT, or start with PREFIX. On a mismatch, print the whole output." / "line KEY: the --settings output line that starts with KEY."

**Location:** `test/lib/build-loop-fixtures.bash:28-29`, `:34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the helpers' comparison and failure print; does not establish a status check (neither helper asserts `$status`).

`settings_is() { run --separate-stderr bash "$BL" --settings; [ "$(line "$1")" = "$2" ] || { echo "want: $2"; echo "$output $stderr"; return 1; }; }` (`:31`). `settings_like` uses `== "$2"*` (`:32`). `line() { printf '%s\n' "$output" | grep -m1 "^$1 " || true; }` (`:36`) returns the first line starting with `KEY `.

**Evidence:** `test/lib/build-loop-fixtures.bash:28-36`

---

## Claim 18: test titles T1, T2, T3, T3/G19, slots, usage/exit and lib-source describe what they assert

**Location:** `test/scripts/build-loop-read.bats:13`, `:24`, `:43`, `:70`, `:90`, `:143`, `:161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each test passes and its assertions match its title; does not establish the subdirectory/worktree part of `:161`'s test (Claim 23) or gaps settled as C14-C17.

All 9 pass (baseline). The `pathform`, `HEAD`, `worktree` and `nonext` mutants each fail at least one test whose title names the mutated property (mut-*.log). Test 4 on the real `docs/dev-cycle.md` prints `policy review unset: line 7 is not exactly ...` (`Build-loop policy: review (interim; Q-103)`).

**Evidence:** baseline.log; mut-*.log; `docs/dev-cycle.md:7`

---

## Claim 19: T4 title "the working tree and other branches never decide" and "Committed on a checked-out loop branch: HEAD is not main."

**Location:** `test/scripts/build-loop-read.bats:78`, `:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that T4 tells main from both HEAD and the working tree; does not establish that the `lower` branch step (uncommitted, so equal to main) adds a further check.

Mutant `HEAD` (`"$MAIN_SHA:$f"` → `"HEAD:$f"`) fails T4 at bats `:84` (`settings_like policy "policy review set:"`). Mutant `worktree` (`git cat-file blob ... |` → `cat "$f" |`) fails T4 too.

**Evidence:** `test/scripts/build-loop-read.bats:78-88`; mut-head.log; mut-worktree.log

---

## Claim 20: "Copies in markup, a table, a link or with a misplaced colon count as second lines too."

**Location:** `test/scripts/build-loop-read.bats:122`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the eight shapes in the loop at `:123-124` (all counted, baseline ok 7); does not establish the general statement for links or markup.

The listed shapes are all counted. As a general statement it misses the shapes in Claim 3b: `[Self-merge](u) never: b/` (a link wrapping part of the key) and `- [x] Self-merge never: b/` are not counted (probes.log). Precise version: "These copies in markup, ... count as second lines".

**Evidence:** `test/scripts/build-loop-read.bats:122-127`; probes.log (`### never second line`)

---

## Claim 21: "A part starting .git is allowed: the list only adds refusals." / "A never line Markdown would continue on the next line is malformed." / "Raised only on a loop's branch or in the working tree: ignored."

**Location:** `test/scripts/build-loop-read.bats:128`, `:131`, `:136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each section discriminates its property under a mutant; does not establish the fence-in-between NEXT case (Claim 9).

Mutant `pathform` fails at `:130`. Mutant `nonext` (the `next[never]` arm replaced by `elif false`) fails T45. Mutants `HEAD` and `worktree` fail at `:140` (`never workflows/ set:`): HEAD is the `loop` branch, with a malformed never line, and the working tree has none.

**Evidence:** `test/scripts/build-loop-read.bats:128-140`; mut-pathform.log; mut-nonext.log; mut-head.log; mut-worktree.log

---

## Claim 22: "The lib it sources (scripts/lib/dev-cycle-read.sh) is also tested from dev-cycle.sh's side, in test/scripts/dev-cycle.bats." / "this repo is untouched"

**Location:** `test/scripts/build-loop-read.bats:3-6`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reference and that tests cd into `$BATS_TEST_TMPDIR/repo`; does not establish dev-cycle.bats's coverage depth.

`test/scripts/dev-cycle.bats:1037` sources `"$REPO_ROOT/scripts/lib/dev-cycle-read.sh"`. `bl_setup` does `R="$BATS_TEST_TMPDIR/repo"; mkdir -p "$R" && cd "$R" || return 1` (fixture `:16-17`).

**Evidence:** `test/scripts/dev-cycle.bats:1037`; `test/lib/build-loop-fixtures.bash:16-18`

---

## Claim 23: "From a subdirectory and from a linked worktree, it reads the same main."

**Location:** `test/scripts/build-loop-read.bats:169`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers telling main apart from the working tree in both runs; does not establish telling main apart from the checked-out HEAD (in a subdirectory or a linked worktree).

```bash
# test/scripts/build-loop-read.bats:170-172
    settings 'Build-loop policy: self-merge'
    git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main && mkdir -p sub
    for d in . "$BATS_TEST_TMPDIR/wt"; do printf 'Build-loop policy: review\n' > "$d/docs/dev-cycle.md"; done
```
(excerpt ends :172; enclosing @test continues to :178 — read)

In both runs HEAD equals main's commit: the main checkout is on `main`, and `wt` is created at `main`. Only the uncommitted working tree differs. The `worktree` mutant fails this test (mut-worktree.log: not ok 9). The `HEAD` mutant passes it (mut-head.log: ok 9). So the test shows the script does not read the working tree. It does not show it reads main rather than the worktree's HEAD. T4 and T45 cover HEAD, but not from a subdirectory or a linked worktree.

**Evidence:** `test/scripts/build-loop-read.bats:161-178`; mut-head.log; mut-worktree.log

---

## Claim 24: 1d79ffef R2 — "`settings_like A && settings_like B` never failed the test when A failed ... The checks are separate commands now; a mutation back to pathform fails T45."

**Location:** commit 1d79ffef message (R2); `test/scripts/build-loop-read.bats:81`, `:87`, `:130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every `settings_is`/`settings_like` call (none in an `&&`/`||` list) and the other assertions (all `[...] && [...] || { ...; return 1; }`, which fail); does not establish setup steps, where a non-final `&&` part (e.g. `:86` `git merge -q loop && ...`) can still fail silently. In every case examined, a later assertion would then fail.

`grep -E 'settings_(is|like)' ... | grep -E '&&|\|\|'` finds nothing. Pairs on one line use `;`: `:81`, `:87`, `:130`. Mutant `pathform` fails T45 at `:130`.

**Evidence:** `test/scripts/build-loop-read.bats:17`, `:81`, `:87`, `:117`, `:130`, `:146`, `:167`; mut-pathform.log

---

## Claim 25: 1d79ffef R3/A5 — "copies with markup closing before the colon, a table cell, a link or "Self-merge never :" were hidden. A line now counts as a copy when its letters alone, case folded, start with the key's, so any of them is a second line"

**Location:** commit 1d79ffef message (R3/A5)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the four named categories; does not establish markup in general (Claim 3b).

`**Build-loop policy**: review` (T2), `| Self-merge never: | b/ |`, `[Self-merge never](x): b/` and `Self-merge never : b/` (T45) are all counted (baseline). "Any ... link" is too broad: `[Self-merge](u) never: b/` and `[Build-loop](x) policy: review`, links that close inside the key, stay hidden (probes.log). Precise version: "a link around the whole key".

**Evidence:** probes.log; baseline.log (ok 2, ok 7)

---

## Claim 26: 1d79ffef — "A never line followed by a non-blank line is malformed (Markdown would join the next line as more globs)."

**Location:** commit 1d79ffef message (R3/A5)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a following plain text line; does not establish the rationale for a following fence or HTML comment line (Claim 9).

`elif [[ "${next[never]}" != 1 ]]; then why="is followed by a non-blank line ..."` (`:152`). T45 `:132` passes; the `nonext` mutant fails T45.

**Evidence:** `scripts/build-loop.sh:152`; mut-nonext.log

---

## Claim 27: 1d79ffef A6, A7, A8, C3, C13, A11-A13 — "GIT_NO_REPLACE_OBJECTS=1 ...", "main_file names main_entry's error and a failed blob read", "NEVER is an array of the checked entries", "read_settings resets POLICY and NEVER", "the no-echo check covers tabs", "fixture and header comments; Exit names help; "Unknown option" as in the sibling scripts"

**Location:** commit 1d79ffef message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each named change as present and working at HEAD; does not establish A13's T45 comment wording beyond Claim 20.

A6: Claim 6. A7: Claim 7. A8 and C3: Claim 11. C13: `"$output" != *$'\t'*` (bats `:117`). A11: Claim 16. A12: Claim 5. "Unknown option": `*) usage "Unknown option: $1" ;;` (`:55`), matching `scripts/dev-cycle.sh:112` `echo "Unknown option: $1"`.

**Evidence:** `scripts/build-loop.sh:55`, `:63`, `:79`, `:130`, `:164`; `scripts/dev-cycle.sh:112`; `test/scripts/build-loop-read.bats:117`; logs above

---

## Claim 28a: 1d79ffef A14/A15 — "T4 and T45 now have a working tree and a checked-out branch that differ from main; a mutant reading HEAD fails them."

**Location:** commit 1d79ffef message (A14/A15)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers T4 and T45; does not establish the subdirectory/worktree runs (Claim 28b).

Executed: the `HEAD` mutant fails T4 (`:84`) and T45 (`:140`).

**Evidence:** mut-head.log (`date -u` 11:45:41Z; cwd `fc-r1/mut-head`; `bats test/scripts/build-loop-read.bats`; exit 1)

---

## Claim 28b: 1d79ffef A14/A15 — "the subdirectory and worktree runs ... now have a working tree and a checked-out branch that differ from main; a mutant reading HEAD fails them."

**Location:** commit 1d79ffef message (A14/A15); `test/scripts/build-loop-read.bats:169-177`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the subdirectory and linked-worktree runs in test 9; does not establish anything about T4/T45 (Claim 28a).

In test 9 the checked-out branch does not differ from main. The subdirectory run is in the main checkout on `main`. The worktree run is on `wt`, created at `main` with nothing committed (`git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main`, `:171`). The `HEAD` mutant passes test 9 (mut-head.log: `ok 9`). Only the working tree differs, and the `worktree` mutant does fail it. A14's "could not tell main from ... worktree HEAD" is still open for these runs. The overall suite does catch a HEAD-reading mutant, through T4/T45.

**Evidence:** `test/scripts/build-loop-read.bats:169-177`; mut-head.log; mut-worktree.log

---

## Claim 29: 1d79ffef — "The unit is 400 changed code lines"

**Location:** commit 1d79ffef message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers scripts/ and test/ in the three-dot diff; does not establish pr-prep's own counting rule beyond that.

`git diff --numstat feat/build-loop-u1a...HEAD -- scripts test` → `186 0 scripts/build-loop.sh`, `36 0 test/lib/build-loop-fixtures.bash`, `178 0 test/scripts/build-loop-read.bats`. 186 + 36 + 178 = 400. Checked against the logged pattern class "specific measured value quoted from an artifact set that does not contain it": not a recurrence.

**Evidence:** command run in /workspace/.claude/wt-build-loop-u1b, exit 0, 11:42Z (output reproduced above)

---

## Claim 30: 1d79ffef — "Override-log rows for A9/A10 and C1, C2, C4-C11, C14-C19." / "Also merges feat/build-loop-u1a's iteration-2 fixes first."

**Location:** commit 1d79ffef message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each code having a u1b row in docs/reviews/override-log.md and the merge order; does not re-judge the rows. Note C19's premise (Claim 3b).

grep of u1b rows: one each for A9, A10, C1, C2, C4-C11, C17, C18, C19. C14-C17 share row `:246` ("C14-C17"). `git log` shows merge 93f09654 directly before 1d79ffef. The commit adds 14 lines to override-log.md (`git show --stat`).

**Evidence:** `docs/reviews/override-log.md:235`, `:245`, `:246`, `:248`

---

## Claim 31: 1d79ffef Notes — "the letters-only match can unset the policy for a prose line that starts with the key's words (docs/dev-cycle.md has none; T3's real-file test would catch one)"

**Location:** commit 1d79ffef message (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the policy key; does not establish detection of a prose line starting "Build-loop slots" or "Self-merge never" (test 4 asserts only the policy line, and under review policy a malformed never line changes nothing it checks).

Executed --settings on a repo holding HEAD's `docs/dev-cycle.md`: `policy review unset: line 7 is not exactly ...`, `slots 3 default: no line starts ...`, `never none: no line starts ...`, so there is one policy line and no slots/never lines. Test 4 (`:74`) requires `policy review unset: line *' is not exactly ...'`. A second prose policy line would print `more than one line starts` and fail it.

**Evidence:** `test/scripts/build-loop-read.bats:70-76`; `docs/dev-cycle.md:7`; executed in `fc-r1/repos/real`, exit 0, 11:47Z

---

## Claims Requiring Attention

### Incorrect
- **Claim 3b** (`scripts/build-loop.sh:26-27`), and the same text in **Claim 8** (`scripts/build-loop.sh:90-92`): "markup ... cannot hide a copy" is false for markup that carries letters. `- [x]` task items, mid-line inline HTML (`Build-loop <span>policy</span>:`) and a link closing inside the key (`[Build-loop](x) policy:`) all hide a copy that renders as the key. The comment should be narrowed, or the orchestrator should decide whether C19's Won't-Fix covers these shapes (its "does not render as the key" premise does not hold for them).
- **Claim 28b** (commit 1d79ffef, A14/A15; `test/scripts/build-loop-read.bats:169-177`): the subdirectory/worktree runs do not have a checked-out branch that differs from main, and a HEAD-reading mutant passes test 9. Only T4/T45 catch it.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`scripts/build-loop.sh:9-12`): "a second copy ... leaves the default" does not hold for the never line, which reads `malformed`, not the default `none`.
- **Claim 9** (`scripts/build-loop.sh:92-93`): NEXT is the next line FENCE_AWK does not skip (EOF counts as blank). A following fence or one-line HTML comment makes it malformed with a false "Markdown would join it" WHY. This fails closed.
- **Claim 20** (`test/scripts/build-loop-read.bats:122`): true for the listed shapes, not for links or markup in general.
- **Claim 23** (`test/scripts/build-loop-read.bats:169`): tells main from the working tree, not from the worktree's or subdirectory's HEAD.
- **Claim 25** (commit 1d79ffef R3/A5): "any ... link is a second line" holds only for a link around the whole key.

### Unverifiable
- None.

---

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to the path below, structured per the code-fact-check skill.

**Answered:** Yes. 33 claims, verdicted at HEAD 1d79ffef: 25 Verified, 5 Mostly accurate, 3 Incorrect (3b and 8 are the same defect at two locations), with most verdicts executed (throwaway repos, replace refs, deleted objects, four mutants run against full copies of the suite). Brief items 1-11 are each covered: copy rule (3a/3b/8), never grammar and `*`/`?` subscripts (2), NEXT (9), replace refs (6), FILE_WHY arms including a real `error` (7), NEVER/reset (11), comments at :135/:149/:155/:112 (10, 12, 14), scrub/Exit (4, 5), commit claims (24-31), fixture (15-17) and test titles/comments (18-23).

**Out of scope:** Code quality and design choices recorded in 1d79ffef's Notes (letters-only matching, blank-after rule, array NEVER) were not judged as choices. Settled override-log rows were not re-raised; C19's premise is noted under Claim 3b only. u1a's merged fixes were not reviewed. No tests or code were edited.

**Escalate:** Claim 3b/8 is a fail-to-detect gap in the copy rule that the header and commit message advertise as closed. It is adjacent to settled C19 but covers different shapes (task box, inline HTML, partial link) where C19's rationale does not hold. Whether this is amber or folds into C19 is the orchestrator's decision. Claim 28b is a commit-message and test-coverage claim; the A14 gap for HEAD inside a linked worktree remains, though T4/T45 catch a HEAD reader in general.

**Questions/Decisions:** None.
