Commit: 83cdb005

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u1d, branch feat/build-loop-u1d)
**Scope:** branch diff `git diff main...HEAD` (one commit, 83cdb005): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, and the commit message. Replicate r2 of k=3.
**Checked:** 2026-10-06
**Total claims checked:** 21
**Summary:** 14 verified, 5 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Execution provenance. Every executed claim ran under bash 5.2 / git 2.39.5. Logs are in the scratch directory `L=/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/fc2/logs/`, and probe scripts are in `.../fc2/bin/`. Each mutant is a copy of `scripts/` and `test/` under `.../fc2/m/<name>/`, with the diff printed in its run. All runs took place between 2026-10-06T04:30Z and 04:39Z.
- Baseline: `bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats` ran in the worktree, exit 0, 92/92 ok, 2026-10-06T04:30:41Z (`$L/baseline-bats.log`).
- Mutant runs: `bats test/scripts/build-loop-read.bats` (or `-f` on the named test) ran in `.../fc2/m/<name>`. Their logs are `$L/mutant-<name>.log`. In every scratch copy, test 4 (T3, which copies this repo's own `docs/dev-cycle.md`) fails because the copy has no `docs/`. That failure is environmental and ignored below.
- The hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read. No claim matches a logged pattern. The one count claim ("118") was executed and holds.

---

## Claim 1: "Self-merge also needs a valid never line, so a never list hidden in markup, with no exact never line beside it, turns it off."

**Location:** `scripts/build-loop.sh:16-18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a never list that markup hides from the copy count (a task box), with and without an exact line beside it, and a never list in letter-preserving markup (`**...**`), with and without an exact line beside it. It does not establish the behaviour of markup shapes not probed.

How the copy count works. A line counts as a copy when its letters alone start "selfmergenever" (`scripts/build-loop.sh:152,155`: `s = tolower($0); gsub(/[^a-z]/, "", s)` … `else if (index(s, "selfmergenever") == 1) k = "never"`). Two copies make the line malformed: `elif [[ "${cnt[never]}" -gt 1 ]]; then NEVER_LINE="never malformed: $(many ...)"` (`:224`). Self-merge then needs `never_ok` (`:250`).

Executed (`bash .../fc2/bin/p12.sh`, cwd `.../fc2/p1`, exit 0, 2026-10-06T04:38Z):
- `- [x] Self-merge never: a/` alone gives `never none: no line starts "Self-merge never:"` and policy review unset. With `Self-merge never: none` beside it, the result is `policy self-merge set`. The qualifier is right for this case: the hidden list is ignored, and the exact line rescues self-merge.
- `**Self-merge never:** a/` alone gives `never malformed: line 3 is not exactly ...`, so self-merge is off. With `Self-merge never: none` beside it, the result is `never malformed: more than one line starts "Self-merge never:" (lines 3 and 5)`, and self-merge is **still off**.

The sentence reads true under the header's own sense of "hide" (`:39-42`: markup "that adds letters ... can still hide a copy"). It reads false if "hidden in markup" is taken to include markup that keeps the letters, such as bold or a list marker. The header elsewhere says most of that markup cannot hide a copy (`:141-142`). For that markup, an exact line beside the list does not keep self-merge on. A precise version: "a never list in markup turns it off, unless the markup hides it from the copy count and an exact never line stands beside it."

**Evidence:** `scripts/build-loop.sh:16-18`, `:39-42`, `:150-157`, `:222-245`, `:250-251`; `$L/probe-p12.log`

---

## Claim 2: Skip list: "for an open brief, another open brief on main ... names the same branch (ignoring case) or the open briefs on main could not be listed, or on a branch ahead of main the tip's subject ... starts "handoff:" but it is not a marker."

**Location:** `scripts/build-loop.sh:68-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "could not be listed" skip (open briefs only), the ahead>0 gate on the marker skip, and the 0-ahead tip whose subject starts "handoff:" (reported as working, not skipped). It does not establish the wording of the header's unchanged line 61 ("level with main"): a branch behind main is also 0 ahead.

The code: `if [[ "$st" == open && "$SHARED_BRANCHES" == error ]]; then echo "skip $a: the open briefs on the default branch could not be listed"; return; fi` (`scripts/build-loop.sh:338`). The marker is read only when the branch is ahead: `loop=working` / `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` … `bad\ *) echo "skip $a: the tip of $br starts \"handoff:\" but is not a marker: ..."` (`:348-352`; the enclosing status_line runs on to `:358` — read). marker_kind returns `working` when the subject does not start "handoff:" (`:283`). Every one of its `bad` returns comes after that check (`:284-297`).

Executed (`bash .../fc2/bin/p3.sh`, exit 0, 2026-10-06T04:36Z):
- A branch at main whose tip subject is `handoff: junk subject on main` printed `ok ... feat/lvl working <sha> ...`.
- A branch one commit ahead with subject `handoff: junk` printed `skip ...: the tip of feat/ahd starts "handoff:" but is not a marker: ...`.
- The "could not be listed" path runs in the suite with `grep.patternType bogus` (`test/scripts/build-loop-read.bats:386-388`, which passes in the baseline).

**Evidence:** `scripts/build-loop.sh:321-358`, `:278-298`; `$L/probe-claim3.log`; `$L/baseline-bats.log`

---

## Claim 3: "# the header, to the first non-empty line not starting with #"

**Location:** `scripts/build-loop.sh:99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `sed -n '2,/^[^#]/{/^#/p}'` on this file and on probe files: empty lines inside the range neither end it nor print, and a whitespace-only line or an indented non-# line ends it. It does not establish the case of a non-comment line 2 (GNU sed never tests the end address on the range's start line, so line 2 cannot end the range). This file's line 2 is a comment, so that case does not arise here.

`^[^#]` needs one character that is not `#`, so an empty line never matches it, while a whitespace-only line does. Executed (`bash .../fc2/bin/p4.sh`, exit 0, 2026-10-06T04:38:27Z):
- On this file the range ends at line 81 (`set -euo pipefail`). The empty line 80 before it is inside the range and is not printed.
- Probe 1 (`# a`, empty line, `# b`, `   x`, `# c`) printed `# a`, `# b`.
- Probe 1b (a line of spaces after `# a`) printed only `# a`.
- Probe 3 (line 2 `set -e`, then `# after`, then `x`) printed `# after`. This is the start-line edge named in Scope.

"Non-empty" is therefore the right word for the end line: an empty line is not it.

**Evidence:** `scripts/build-loop.sh:99`; `$L/probe-p4.log`

---

## Claim 4: "whether the next line outside a fence after the first is blank or the end of the file (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:142-145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fence skip, whitespace-only lines (spaces and tabs), the end of the file with and without a trailing newline, and a fence immediately followed by a non-blank line. It does not establish other whitespace: a form-feed-only line is non-blank, since `[ \t]` is the class.

The code (`scripts/build-loop.sh:148-156`):

```
{ sub(/\r$/, "") }
fence($0) { next }
{
  if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }
  ...
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0; nx[k] = 1; pk = k } ...
```

Fence lines and fenced content skip the NEXT update, and `nx[k] = 1` stands when no later unfenced line comes. A fence still open at the end of the file refuses the whole file (`:160`, `unbalanced`), so the end of the file cannot be inside a fence.

Executed (`p12.sh`):
- a fence `x` fence, then the end: `never a/ set`
- an empty fence, then `y`: `never malformed: line 3 is followed by a non-blank line outside a fence`
- `\t `: set
- `\f`: malformed
- no trailing newline: set

**Evidence:** `scripts/build-loop.sh:147-162`, `scripts/lib/dev-cycle-read.sh:214-230`; `$L/probe-p12.log`

---

## Claim 5a: "Exit 1 is "none"; an exit above 1 fails closed (SHARED_BRANCHES=error: every open brief skips)."

**Location:** `scripts/build-loop.sh:307-309`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git grep's exit 1 (no match), exit 128 (bad config, corrupt object) and the resulting skips. It does not establish exits from a killed git (the u1c rubric R1 recorded 137).

The code: `list="$(git grep ...)" || rc=$?` / `if [[ "$rc" -gt 1 ]]; then SHARED_BRANCHES=error; return; fi` (`scripts/build-loop.sh:310-311`), followed by the open-only skip at `:338`.

Executed (`bash .../fc2/bin/p5.sh`, exit 0, 2026-10-06T04:38Z):
- No match gave rc=1.
- `-c grep.patternType=bogus` gave rc=128.
- `-c color.grep=bogus` gave rc=128.
- A corrupt blob gave rc=128. --status then printed `skip b: the open briefs ... could not be listed` and `skip c: ...` for c, which is on another branch.

**Evidence:** `scripts/build-loop.sh:303-320`, `:338`; `$L/probe-p5.log`

---

## Claim 5b: "A brief git grep cannot read is not counted (row 293)."

**Location:** `scripts/build-loop.sh:309`
**Type:** Error-handling / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a brief whose blob is missing and a brief whose blob is corrupt, plus what override-log row 293 settles. It does not establish other object-store failures, such as a pack error.

- **Missing blob:** git grep prints `error: ... unable to read <sha>` and exits 0 (or 1 when nothing else matches). The brief is left out of the list: `ok b open review feat/a ...` although a names the same branch, and a skips on its own line (`p5.sh`, "missing blob a").
- **Corrupt blob:** git grep cannot read it either, but it exits 128 (`fatal: loose object ... is corrupt`). That falls under the previous sentence: the list is not built, and every open brief skips, including one on another branch. So "cannot read → not counted" holds only for a missing object. A corrupt one fails closed.
- **Row 293:** `docs/reviews/override-log.md:293` reads "An unreadable open brief is not counted for F31 ... | Won't-Fix | The unreadable brief skips in its own --status line". The u1c rubric scoped its premise to "the missing-blob exit-0 case" (`docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1c.md:145`). The comment's reference is apt for that case.
- **Precise version:** "A brief whose object is missing (git grep warns and exits 0 or 1) is not counted (row 293)."

**Evidence:** `scripts/build-loop.sh:309-316`; `docs/reviews/override-log.md:293`; `docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1c.md:26,113,145`; `$L/probe-p5.log`

---

## Claim 6: "an answer only in the working tree is not seen: it reads what main's copy says until it lands there"

**Location:** `scripts/dev-cycle.sh:64-65`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer reading only `$MAIN_SHA`'s blobs (working tree and other branches ignored) and seeing the answer once it is merged to the default branch. It does not establish behaviour under a default branch not found by name, which the next claim's gate refuses.

check_answer reads `r="$(git cat-file blob "$MAIN_SHA:$f" | ...)"` (`scripts/lib/dev-cycle-read.sh:563`) after `main_entry "$f"` (`:554`). T34 (`test/scripts/dev-cycle.bats:1164`) asserts three things: `open Q-1` with the answer only in the working tree, `open Q-1` with it committed on `side`, and `drop Q-1` after `git merge -q side`. T34 passed in the baseline run (`ok 83`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-577`; `test/scripts/dev-cycle.bats:1164-1180`; `$L/baseline-bats.log`

---

## Claim 7: "# The header: from line 2 to the first non-empty line not starting with # (no fixed range to go stale)."

**Location:** `scripts/dev-cycle.sh:111`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same sed expression as Claim 3, on dev-cycle.sh: the range ends at line 83 (`set -euo pipefail`), and the empty line 82 is skipped. It does not establish the non-comment-line-2 edge noted in Claim 3.

The command is `sed -n '2,/^[^#]/{/^#/p}' "$0"` (`scripts/dev-cycle.sh:112`). `p4.sh` printed `range end line 83: set -euo pipefail` and `first empty line at 82`. The dev-cycle.bats --help test (`ok 91`) passes in the baseline.

**Evidence:** `scripts/dev-cycle.sh:111-112`; `$L/probe-p4.log`; `$L/baseline-bats.log`

---

## Claim 8: "The caller sets -euo pipefail (check_answer and brief_fields also set pipefail for themselves)"

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `set -o pipefail` in the lib and both callers' `set -euo pipefail`. It does not establish the behaviour of a third caller (none exists).

`grep -n pipefail` over the lib finds two function-level sets: `local - out l; set -o pipefail` (`:294`, brief_fields) and `local - a="$1" ... ; set -o pipefail  # as brief_fields` (`:550`, check_answer). The only other hit, `:72`, is scrub_reexec's comment. No other function sets pipefail, so the list is complete. The callers are `scripts/build-loop.sh:81` and `scripts/dev-cycle.sh:83`, both `set -euo pipefail`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-14`, `:72`, `:291-294`, `:549-550`; `scripts/build-loop.sh:81`; `scripts/dev-cycle.sh:83`

---

## Claim 9: "It checks main_by_name and the path's form itself (pathform, so ls-tree prints it unquoted): either failing is error." (and the commit's "main_entry checks the path's form itself ... either failing is error (U1a C16)")

**Location:** `scripts/lib/dev-cycle-read.sh:257-259`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard and every caller of main_entry in scripts/: none changes behaviour beyond pathform refusals now answering error. It does not establish the completeness of the comment's earlier "error (...)" list at `:252-255`, an unchanged line that still names only three causes (no default branch, ls-tree failed, a duplicate name); the new sentence adds the fourth.

The guard: `if ! main_by_name || ! pathform "$1"; then echo error; return; fi` (`:263`, before the ls-tree at `:265`). Callers (`rg main_entry scripts/`):
- **brief_fields** (`:296`) runs `! pathform "$1" ||` before main_entry. Unchanged.
- **check_brief** (`:327`) refuses `not an allowed path form` before main_entry at `:334`. Unchanged.
- **check_answer** (`:554`) passes the fixed names `docs/working/questions.md` and `docs/working/questions-archive.md`.
- **build-loop.sh main_file** (`:124`) is reached only with `docs/dev-cycle.md` and `docs/constraints.md` (`:210`, `:260`).
- **dev-cycle.sh** has no direct caller.

All four fixed names pass pathform: an executed probe in the worktree printed `pathform ok:` for each. The only other callers are tests (`dev-cycle.bats:1234-1235`, `:1328`). Mutant m5 (guard reverted to `main_by_name || { echo error; return; }`) printed `absent error absent absent` and failed the U1d test (`$L/mutant-m5.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:248-276`, `:291-296`, `:323-341`, `:549-561`; `scripts/build-loop.sh:121-131`, `:210`, `:260`; `$L/mutant-m5.log`

---

## Claim 10a: Test "--settings: deferred cases: reasons, review with a malformed never line, the next-line rule, an absent file, a caller's config (U1d)" and its comments "Under review a malformed never line leaves the policy as written" and "The next line outside a fence decides; a whitespace-only line is blank."

**Location:** `test/scripts/build-loop-read.bats:402-419`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact glob-form and "twice" reasons, policy review set beside `Self-merge never: ../x`, the fence half and the whitespace-only half of the next-line rule, and the slots line for a deleted file. The caller's-config half is Claim 10b. This verdict does not establish the unread-file slots case (Claim 17).

The assertions match exactly:
- `settings_is never "never malformed: line 2 lists entry 2, which is not an allowed glob form"` (`:405`)
- `"... lists entry 3 twice"` (`:407`)
- `settings_is policy "policy review set: line 1 ..."` (`:410`)
- a fence-wrapped `x` followed by `''` gives `never a/ set:` (`:412-413`), and the same followed by `b/` gives `never malformed: line 2 is followed by a non-blank line` (`:414-415`)
- `'   '` gives set (`:416-417`)
- `settings_is slots "slots 3 default: no docs/dev-cycle.md on the default branch"` (`:419`)

The test passes at 83cdb005 (baseline). The code paths are `scripts/build-loop.sh:237-238` (the reasons), `:248-252` (policy under review ignores never_ok), `:151` (next-line) and `:211-212` (absent).

**Evidence:** `test/scripts/build-loop-read.bats:402-419`; `scripts/build-loop.sh:205-258`; `$L/baseline-bats.log`

---

## Claim 10b: "# A caller's own GIT_CONFIG_COUNT pairs stay, and the guard still applies after them." (commit: "a caller's own GIT_CONFIG_COUNT pairs with a replace ref")

**Location:** `test/scripts/build-loop-read.bats:420-425`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the test fails when the guard pair is removed (it does) and when the caller's pairs are clobbered (it does not). The code itself does keep the caller's pairs (`cfg="${GIT_CONFIG_COUNT:-0}"` appends at index cfg, `scripts/build-loop.sh:112`). This verdict does not establish behaviour for a zero-padded count, which the comment at `:110-111` already concedes.

- **Mutant m4** deletes `:112` (the `cfg=...; export "GIT_CONFIG_KEY_$cfg=core.useReplaceRefs" ...` line). The test fails at `:425` with `policy self-merge set: line 1 ...`, because the replace ref was honoured (`$L/mutant-m4.log`; T4, test 5, also kills it). So the guard half is genuinely asserted.
- **Mutant m4b** replaces `:112` with `export GIT_CONFIG_KEY_0=core.useReplaceRefs GIT_CONFIG_VALUE_0=false GIT_CONFIG_COUNT=1`, overwriting the caller's `user.name` pair. It **passes** (`$L/mutant-m4b.log`; only the environmental test 4 fails). The caller's pair (`user.name=caller`) has no observable effect on --settings, so "pairs stay" is stated in the comment but not asserted.
- **Precise version:** "A caller's GIT_CONFIG_COUNT does not stop the guard."

**Evidence:** `test/scripts/build-loop-read.bats:420-425`; `scripts/build-loop.sh:108-113`; `$L/mutant-m4.log`, `$L/mutant-m4b.log`

---

## Claim 11: Test "build-loop.sh --help prints the whole header, through its last line (U1d)" (commit: "build-loop.sh --help ends at the header's last line")

**Location:** `test/scripts/build-loop-read.bats:428-432`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers status 0, the first line ("The build-loop handoff's state and checks"), and a last line ending "or no default branch found by name." (header line 79). It does not assert middle lines: a range that skipped interior lines would still pass.

The header's last comment line is `# lib/dev-cycle-read.sh, or no default branch found by name.` (`scripts/build-loop.sh:79`). The range ends at 81 (Claim 3). The test passes in the baseline.

**Evidence:** `test/scripts/build-loop-read.bats:428-432`; `scripts/build-loop.sh:2,79,99`; `$L/baseline-bats.log`

---

## Claim 12a: Test title's "F31's open-only filter" and comment "A done brief sharing an open brief's branch does not make the open one skip." (commit: "a done brief sharing an open brief's branch", offered for U1c C17/C18's "F31's open-only filter ... untested")

**Location:** `test/scripts/build-loop-read.bats:434`, `:440-443`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the step exercises the open-only filter at `scripts/build-loop.sh:315`. It does not dispute that the asserted output is correct.

The done brief d holds no "Status: open" line, so git grep (`'^Status: open'$'\r''?$'`, `scripts/build-loop.sh:310`) never lists it, and the filter at `:315` (`[[ "${BRIEF[status]-}" == "Status: open" && ...`) is never reached for it.

- **Mutant m7** drops the `"${BRIEF[status]-}" == "Status: open" &&` term. It passes the whole build-loop-read suite (`$L/mutant-m7.log`; only the environmental test 4 fails).
- **Executed probe** (`bash .../fc2/bin/p7.sh`, exit 0, `$L/probe-m7-filter.log`). The filter becomes observable only for a brief whose first Status line is `Status: done` and a later line reads `Status: open`. With that brief beside open brief o on feat/x, the real script printed `ok ...o.md open review feat/x ...` and m7 printed `skip ...o.md: another open brief ...`.

The step tests the git grep prefilter, not the filter. C17/C18's open-only-filter gap remains open.

**Evidence:** `test/scripts/build-loop-read.bats:434-443`; `scripts/build-loop.sh:303-320`; `$L/mutant-m7.log`; `$L/probe-m7-filter.log`

---

## Claim 12b: "# Another open brief (CRLF line endings) on the same branch counts; the queried brief keeps its own Dispatched value whatever F31 read."

**Location:** `test/scripts/build-loop-read.bats:444-448`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the second clause (Dispatched kept) at this step. The first clause (CRLF counts) is Verified in Claim 12c.

The step's only assertion is `[[ "$output" == "skip $o: another open brief"* ]]` (`:448`). A skip line carries no Dispatched field. p's file is overwritten as `printf 'Status: open\r\nBranch: feat/x\r\n'` (`:446`), so it no longer has the `Dispatched: 3` the `brief p` call wrote.

Mutant m1b (local BRIEF dropped, shared_branches call moved after `brief_fields "$a"`) passes `:448` and first fails at `:457` (`$L/mutant-m1b.log`: `line 457 ... ok ...o.md open review feat/q absent - - 3`). The Dispatched-kept property is asserted at `:454-457`, not at this step.

**Evidence:** `test/scripts/build-loop-read.bats:444-457`; `$L/mutant-m1b.log`

---

## Claim 12c: The --status test's other cases: "No open brief on main at all (git grep exits 1): a done brief reads normally", CRLF counts, "A directory whose name merely contains "closed" is not closed/", "Another open brief on another branch, read by F31 after o, leaves o's fields alone", "A NUL byte refuses the brief, naming the line."

**Location:** `test/scripts/build-loop-read.bats:436-461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each case is asserted and fails on its regression (mutants below). It does not establish that the rc=1 arm is distinguishable from fail-closed: m8 survives, see below.

Each mutant fails at its own line:

| Mutant | Change | Fails at | Output |
|---|---|---|---|
| m3 | drops `$'\r''?'` from the grep pattern | `:448` | `ok ...o.md open review feat/x absent - - 2` (`$L/mutant-m3.log`) |
| m2 | restores `${f/closed\//}` | `:453` | `skip ...o.md: another open brief ...` (`$L/mutant-m2.log`) |
| m1b | local BRIEF dropped, call moved | `:457` | `ok ...o.md open review feat/q absent - - 3` |
| m9 | drops FENCE_AWK's NUL refusal | `:461` | `ok ...n.md open review feat/nx ...` (`$L/mutant-m9.log`) |

The no-open-brief step (`:436-439`) asserts the done brief's normal `ok` line. Mutant m8 (`-gt 1` changed to `-ge 1`) passes the suite (`$L/mutant-m8.log`). The error branch only skips open briefs, and when git grep exits 1 no open brief exists on main to query. So the mutant is unobservable through --status, and the comment's claim (a done brief reads normally) holds.

**Evidence:** `test/scripts/build-loop-read.bats:434-462`; `scripts/build-loop.sh:310-319`; `scripts/lib/dev-cycle-read.sh:217`; `$L/mutant-m1b.log`, `$L/mutant-m2.log`, `$L/mutant-m3.log`, `$L/mutant-m8.log`, `$L/mutant-m9.log`

---

## Claim 13: Test "--check-brief, --check-branch and --check-answer need a default branch found by name; the others do not" (loop extended to `--check-answer feat/x`)

**Location:** `test/scripts/dev-cycle.bats:813-823`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop failing when --check-answer leaves dev-cycle.sh's default-branch gate. "The others do not" is asserted for --check-path only, which is pre-existing.

The gate is `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then echo "$CHECK needs a default branch ..." >&2; exit 1` (`scripts/dev-cycle.sh:193-194`). It runs before any argument is checked, so the argument `feat/x` is never parsed.

Mutant m6 removes `--check-answer` from `:193`. The test fails at `:818` (`[ "$status" -eq 1 ]`) (`$L/mutant-m6.log`). On a trunk-only repo, m6 printed `skip feat/x: not a question ID (Q- and digits)` with rc 0, against the real script's `--check-answer needs a default branch ...` with rc 1. The test therefore fails for the gate: the exit status is what it checks. A Q-ID argument would also have made the mutant exit 0 (`skip Q-1: no default branch found by name ...`, rc 0). `feat/x` changes only which refusal text the mutant prints.

**Evidence:** `test/scripts/dev-cycle.bats:813-823`; `scripts/dev-cycle.sh:188-204`; `scripts/lib/dev-cycle-read.sh:551-552`; `$L/mutant-m6.log`

---

## Claim 14: Test "main_entry refuses a path pathform refuses, before any read (U1d)"

**Location:** `test/scripts/dev-cycle.bats:1328-1335`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four `error` answers and the test's failure when the guard is removed. It does not establish "before any read", which the code does but the test does not assert.

The code checks pathform before ls-tree (`scripts/lib/dev-cycle-read.sh:263`, `:265`).

- **Mutant m5** (guard removed) fails: `absent / error / absent / absent`. `../x` already errors via ls-tree, so 3 of the 4 paths carry the kill (`$L/mutant-m5.log`).
- **Mutant m5b** moves the pathform check to just after the ls-tree read (`pathform "$1" || { echo error; return; }` after `:265`). It **passes** (`$L/mutant-m5b.log`, exit 0).

The title's "before any read" is not observed by the test. A precise title: "main_entry answers error for a path pathform refuses".

**Evidence:** `test/scripts/dev-cycle.bats:1328-1335`; `scripts/lib/dev-cycle-read.sh:260-266`; `$L/mutant-m5.log`, `$L/mutant-m5b.log`

---

## Claim 15: "Mutants that drop the local BRIEF (moving the call), or un-anchor the closed/ prefix, fail the new --status test."

**Location:** commit 83cdb005 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named mutants, read as in u1c's C29/C39: the local dropped and the call moved, and `${f/closed\//}` restored. It does not establish that the test kills dropping the local alone, or dropping only the `#` anchor; both survive (below).

| Mutant | Change | Result |
|---|---|---|
| m1b | `local -A n=()`, call moved after `brief_fields "$a"` | fails test 19 at `:457`, and T28 at `:385` |
| m2 | `${f/closed\//}` | fails test 19 at `:453` |
| m1a | local dropped, call not moved | passes: shared_branches runs before status_line's own `brief_fields "$a"` (`scripts/build-loop.sh:323`, `:328`), so the overwrite is unobservable |
| m1c | call moved, local kept | passes, correctly |
| m2b | only the `#` removed, `${f/docs\/working\/briefs\/closed\//...}` | passes: equivalent for these inputs, since `briefs/closed/` must still appear literally |

The parenthetical "(moving the call)" is the needed condition.

**Evidence:** `scripts/build-loop.sh:303-328`; `$L/mutant-m1a.log`, `$L/mutant-m1b.log`, `$L/mutant-m1c.log`, `$L/mutant-m2.log`, `$L/mutant-m2b.log`

---

## Claim 16: "Notes: 118 changed code lines."

**Location:** commit 83cdb005 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pr-prep step 1a count (`workflows/pr-prep.md:91`). It does not establish other counting conventions (non-comment lines: 69).

Command: `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'`. It ran in the worktree, exit 0, at 2026-10-06T04:36:35Z, and printed `118`. Per file: 15+12, 2+2, 6+4, 63+1, 11+2.

**Evidence:** `workflows/pr-prep.md:86-92`; `$L/sizegate.log`

---

## Claim 17: "Tests (... U1c ... C26 ...): ... the slots line for an absent file" (row 246 / C26: "the slots line for an absent or unread file")

**Location:** commit 83cdb005 message; `test/scripts/build-loop-read.bats:418-419`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absent half (asserted exactly) and the unread half (not asserted for slots anywhere). It does not establish row 246's other gaps beyond those in Claim 10a.

The commit's own wording, "an absent file", is accurate. But it lists C26 (row 246, "the slots line for an absent or unread file") as addressed. `rg 'slots 3 default'` in the suite finds only the format, duplicate and no-line reasons (`:98`, `:101`, `:103`), the T3 prefix (`:81`) and the new absent case (`:419`). No test asserts `slots 3 default: <FILE_WHY>` for an unread file, such as a refused fence. The unread-file tests (`:48-62`) check the policy and never lines only. The code path is `SLOTS_LINE="slots 3 default: $why"` with `why="$FILE_WHY"` (`scripts/build-loop.sh:211-212`; paraphrased — no quote available because the "no test exists" half is an absence of grep results).

**Evidence:** `test/scripts/build-loop-read.bats:48-62`, `:81`, `:98-103`, `:419`; `scripts/build-loop.sh:210-214`; `docs/reviews/override-log.md` (row for `feat/build-loop-u1b` G7-G11)

---

## Claims Requiring Attention

### Incorrect
- **Claim 12a** (`test/scripts/build-loop-read.bats:434,440-443`): the "done brief sharing a branch" step never reaches F31's open-only filter (git grep already drops it). Mutant m7, with the filter removed, passes. Testing the filter needs a brief whose first Status line is done and a later line reads `Status: open`. C17/C18's filter gap stays open.
- **Claim 12b** (`test/scripts/build-loop-read.bats:444-445`): "the queried brief keeps its own Dispatched value" is not asserted at this step (the output is a skip line, and p has no Dispatched line). It is asserted at `:454-457`. Move or drop the clause.

### Mostly Accurate
- **Claim 1** (`scripts/build-loop.sh:17-18`): holds only when the markup hides the list from the copy count. A detected markup copy (`**Self-merge never:**`) plus an exact line is two copies, and self-merge stays off.
- **Claim 5b** (`scripts/build-loop.sh:309`): true for a missing object (exit 0 or 1). A corrupt object makes git grep exit 128, which fails closed for every open brief. Say "a brief whose object is missing".
- **Claim 10b** (`test/scripts/build-loop-read.bats:420`): the guard half is asserted (m4 killed). "Pairs stay" is not: m4b, which clobbers the caller's pair, passes.
- **Claim 14** (`test/scripts/dev-cycle.bats:1328`): "before any read" is not asserted (m5b, with the check after ls-tree, passes).
- **Claim 17** (commit; row 246/C26): only the absent half of "absent or unread" is tested for the slots line.
