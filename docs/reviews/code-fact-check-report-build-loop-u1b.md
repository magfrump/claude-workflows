# Code Fact-Check Report

**Commit:** 1d79ffef
**Replication:** k=3
**Repository:** /workspace/.claude/wt-build-loop-u1b (branch feat/build-loop-u1b)
**Scope:** `feat/build-loop-u1a...feat/build-loop-u1b` at 1d79ffef: comments, test titles and comments in scripts/build-loop.sh, test/lib/build-loop-fixtures.bash and test/scripts/build-loop-read.bats, and the claims in commit 1d79ffef's message. Earlier commits' messages are re-verdicted only where HEAD changed the code they describe. Review iteration 3 (final confirming pass). Merged from replicates `-r1.md` (33 claims), `-r2.md` (39) and `-r3.md` (37), most-severe-wins, with annotations merged by union.
**Checked:** 2026-10-05
**Total claims checked:** 47
**Summary:** 36 verified, 8 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

The baseline `bats test/scripts/build-loop-read.bats` passes 9/9 for all three replicates (`LC_ALL=C.UTF-8`). Execution logs are in each replicate's scratch dir, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/fc-r{1,2,3}/`. This pass may write only reports, so they are not under `docs/reviews/execution-logs/`.

---

## Claim 1: "--settings three lines from the default branch's commit, never the working tree (a build loop can write any working tree)"

**Location:** `scripts/build-loop.sh:9-10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers reading `$MAIN_SHA:docs/dev-cycle.md` rather than the working tree or HEAD; does not establish resolve_main's choice of default branch (settled row 209 / C18).
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=— · r3=Verified
**Replicate annotations:** r1: the compound's Mostly accurate is for the "leaves the default" part (Claim 2).

`git cat-file blob "$MAIN_SHA:$f"` (`:82`). r3 ran it with a working tree and a checked-out loop branch that differ from main; the output follows main. The HEAD and working-tree mutants each fail T4 (r1 mut-head.log, mut-worktree.log).

**Evidence:** `scripts/build-loop.sh:82`; r3 Claim 1a; r1 mutant logs

---

## Claim 2: "a second copy, or a file the lib's FENCE_AWK refuses, leaves the default (WHY says which)"

**Location:** `scripts/build-loop.sh:11-12`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the default-on-copy and default-on-refusal behaviour of all three lines; does not establish the never grammar (Claim 6).
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "fails closed". r1: ":23-24 covers the unread file. Nothing covers the second copy."

This holds for policy (`review unset`) and slots (`3 default`). For the never line, the default is `none`. A second copy (`:146`) or a refused or unread file (`:136`) prints `never malformed` instead, and self-merge goes off. Executed: two `Self-merge never:` lines give `never malformed: more than one line starts "Self-merge never:" (lines 1 and 3)`. A precise version: "...leaves the default (the never line reads malformed)".

**Evidence:** `scripts/build-loop.sh:136` — `if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi`; `:146`; r1 probes.log

---

## Claim 3: "Set only by "Build-loop policy: self-merge" or "...: review", exactly (one trailing CR dropped); else review."

**Location:** `scripts/build-loop.sh:14-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exact-match regex at `:168` and the CR strip at `:97`.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:97`, `:168`; T1, T2

---

## Claim 4: "Loops at once: "Build-loop slots: N", N from 1 to 9; else 3."

**Location:** `scripts/build-loop.sh:16-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `:174-177`.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:176`; slots test

---

## Claim 5: "single spaces, then a blank line or the end"

**Location:** `scripts/build-loop.sh:19-20`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers which line ends a never line; does not establish a fail-open (none found).
**Replicate verdicts:** r1=Verified (compound, Claim 2) · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "matches CommonMark (a fence interrupts a paragraph), so this is imprecise wording, not a defect." · r3: "fenced text followed by a text line is malformed with a misleading WHY. This fails closed."

The line checked is the next line outside fences, not the next physical line (Claim 13). A fence right after the never line is accepted as if it were blank.

**Evidence:** `scripts/build-loop.sh:98-100`, `:105`; r2 probe-next.log; r3 never-probes.log

---

## Claim 6: "A glob uses letters, digits, . _ - / * ? (a trailing / ignored when comparing), has no empty, . or .. part, does not start with / or -, and is listed once. Malformed (or a file not read) turns self-merge off."

**Location:** `scripts/build-loop.sh:20-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers globform, the `a`/`a/` and `a//` cases, and duplicate detection with bash-special subscripts (`*`, `?`, `a*`, `*/`); does not establish how U2's gate will match the globs.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: `seen[*]` and `seen[?]` act as ordinary associative-array keys. `a/ *` is set, and `* *` reads "twice".

**Evidence:** `scripts/build-loop.sh:114-121`, `:156-161`; r1 Claim 2, r2 Claim 4, r3 Claim 4b

---

## Claim 7: "A line counts as a copy when its letters alone, case folded, start with the key's ("buildlooppolicy")"

**Location:** `scripts/build-loop.sh:25-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mechanism (`tolower`, `gsub(/[^a-z]/)`, `index(...) == 1` under `env LC_ALL=C awk`); does not establish that every rendered copy is caught (Claim 8).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r2: under LC_ALL=C, a non-ASCII letter in the key (`pólicy`, Cyrillic homoglyphs) is dropped, so that copy is hidden. That is the same class as settled C19, but C19's "does not render as the key" is weaker for homoglyphs. · r2+r3: a prose line starting with the key's words counts as a copy, as 1d79ffef's Notes acknowledge.

**Evidence:** `scripts/build-loop.sh:101-104`, `:82`

---

## Claim 8: "so markup, a table or a misplaced colon cannot hide one"

**Location:** `scripts/build-loop.sh:26-27`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers markup that adds letters before or inside the key; does not establish tables or the misplaced colon (both true) or entity and zero-width copies (settled C19).
**Replicate verdicts:** r1=Incorrect · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "Override-log row C19 ... settled only 'an HTML entity or zero-width characters', on the premise that 'such a copy does not render as the key either'. That premise does not hold for these three shapes." · r3: "A hidden copy cannot raise anything, which is C19's premise and still holds. But it suppresses the 'second copy' refusal that the header promises." · r2: did not probe `[x]` or inline HTML. Its probes of `- [ ]`, tables, links around the whole key, `1.`, `> >`, NBSP and a mid-file BOM were all counted.

The letters-only rule keeps any letters the markup adds, so markup with letters before or inside the key hides the copy. With `Build-loop policy: self-merge` on line 1, each of these on line 2 leaves `policy self-merge set` (r1, r3, executed):
- `- [x] Build-loop policy: review` and `- [X] ...`, a checked GFM task item;
- `Build-loop <span>policy</span>: review`, `*<span>Build-loop policy: review</span>*` and `**<b>Build-loop policy</b>: review**`, inline HTML not at column 0, which FENCE_AWK's rawhtml check does not refuse;
- `[Build-loop](x) policy: review`, a link that closes inside the key.

The never key behaves the same way. `Self-merge never: a/`, a blank line, then `- [x] Self-merge never: b/` (or `[Self-merge](u) never: b/`) gives `never a/ set` and `policy self-merge set`, with no "more than one line" warning. Each of these copies renders as the key.

**Evidence:** `scripts/build-loop.sh:101-105` — `s = tolower($0); gsub(/[^a-z]/, "", s); k = ""` / `if (index(s, "buildlooppolicy") == 1) k = "policy"`; r1 probes.log; r3 copy-probes2.log (taskx, taskX, inlinespan, inlinehtml, neverx)

---

## Claim 9: "Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch found by name ... Read-only: writes nothing. Output passes through the lib's scrub (but for the start-up errors about perl and the lib); printed repo text is data."

**Location:** `scripts/build-loop.sh:29-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the read-only property (the tree and `.git` snapshot are unchanged) and the scrub re-exec at `:47`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:47`, `:58-65`

---

## Claim 10: "Exit: 0 every line printed (or help); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:33-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each exit path, help included (iteration-2 A12).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:38`, `:44`, `:49-58`, `:65`

---

## Claim 11: "The reader shared with dev-cycle.sh, from this script's own directory (never the target repo's scripts/lib/), so a copy of scripts/ with its lib/ is self-contained." / "before the cd: relative paths work"

**Location:** `scripts/build-loop.sh:39-43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers SCRIPT_DIR resolution and the planted-lib test.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:39`, `:43-46`; `test/scripts/build-loop-read.bats:161-168`

---

## Claim 12: "Read main's own objects: a replace ref could swap in any settings blob." (`export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1`)

**Location:** `scripts/build-loop.sh:62-63`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `git replace` of main's blob, tree and commit; does not establish a test pinning it (none exists).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: a copy without the variable is fooled into `policy self-merge set`. · r2+r3: no test pins this (a coverage note, not an error).

**Evidence:** `scripts/build-loop.sh:63`; r1 replace-and-errors.log; r2 and r3 replace probes

---

## Claim 13: main_file — "FILE_OUT is what awk program $2 (after FENCE_AWK) printed over it; or it returns 1 with FILE_WHY "absent" or why it was not read (main_entry, a failed read, or FENCE_AWK's "odd N WHY" / "unbalanced N")."

**Location:** `scripts/build-loop.sh:67-88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every arm: absent, notdir, error (a real deleted tree object in r1; a duplicate tree entry in r2), notfile/gitlink, a failed cat-file (a deleted blob), odd, and unbalanced; does not establish a test for the error and failed-read arms (none exists).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: the A6/A7 arms have no test (out of scope for fact-check).

**Evidence:** `scripts/build-loop.sh:75-87`; r1 replace-and-errors.log

---

## Claim 14: "per key, how many lines start with it once everything but letters is dropped and case folded (so markup, blanks, a BOM or a misplaced colon cannot hide a copy)"

**Location:** `scripts/build-loop.sh:90-92`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the "markup ... cannot hide a copy" parenthetical, the same defect as Claim 8; does not re-verdict the count and line-number fields, which match `:105` and `:110`.
**Replicate verdicts:** r1=Incorrect · r2=Verified (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r1: "Blanks, a mid-file BOM and a misplaced colon do not hide one." · r3: the same two qualifiers as Claims 5 and 8.

The same executed probes as Claim 8 refute it: a checked `[x]` task box, inline HTML in mid-line, and a link around part of the key.

**Evidence:** `scripts/build-loop.sh:90-94`, `:101-105`; r1 probes.log

---

## Claim 15: "whether the line after the first is blank (NEXT 1) or not"

**Location:** `scripts/build-loop.sh:92-93`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what NEXT records when the next physical line is skipped by `fence($0) { next }`, at EOF, and for whitespace-only and CRLF lines; does not establish CommonMark rules beyond the shapes probed.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r1+r2+r3: "Fails closed." · r2: whitespace-only, tab-only and blank CRLF next lines count as blank.

```awk
{ sub(/\r$/, "") }
fence($0) { next }
{
  if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }
```
(excerpt ends :100; the enclosing SETTINGS_AWK continues to :111, read)

NEXT is decided by the next line that fence() does not skip. If there is none, the `nx[k] = 1` default at `:105` makes EOF count as blank. A never line followed directly by a code fence and then a blank line is accepted. The same with `b/` after the fence gives `never malformed: line 1 is followed by a non-blank line`. A precise version: "whether the next line FENCE_AWK reads (or the end) is blank".

**Evidence:** `scripts/build-loop.sh:97-105`; r1 probes.log; r2 probe-next.log

---

## Claim 16: WHY text "is followed by a non-blank line (Markdown would join it as more globs)", and the same parenthetical in 1d79ffef's message

**Location:** `scripts/build-loop.sh:152`; commit 1d79ffef message (R3/A5)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the reason printed for every non-blank next line; does not establish any fail-open (every case fails closed).
**Replicate verdicts:** r1=Verified (message, Claim 26) · r2=Mostly accurate · r3=Mostly accurate (compound, Claim 4a)
**Replicate annotations:** r1: within Claim 9, "In both malformed cases the printed rationale is false" (the fence-then-text case and the one-line `<!-- c -->` case).

The reason also fires for `# Heading`, `- item` and `<!-- c -->` next lines, and for a text line after a fenced block, none of which Markdown joins. This over-refusal fails closed. A precise version: "(Markdown may join it as more globs)".

**Evidence:** `scripts/build-loop.sh:152` — `elif [[ "${next[never]}" != 1 ]]; then why="is followed by a non-blank line (Markdown would join it as more globs)"`; r2 probe-next.log

---

## Claim 17: globform — "pathform's rule, but a .git* part (.github/) is allowed, since the list only adds refusals and must not turn self-merge off by naming one"

**Location:** `scripts/build-loop.sh:112-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `.github/` and `.gitignore` entries.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:114-121`; T45 `:128-130`

---

## Claim 18: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (an array of the checked globs, each as written, a trailing / kept) and NEVER_LINE from main's commit." and the reset at the start of read_settings (C3)

**Location:** `scripts/build-loop.sh:122-130`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers NEVER's array contents and the POLICY and NEVER reset on a second in-process call; does not establish the gate's use of NEVER (U2).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:130`, `:164`

---

## Claim 19: "An absent file sets nothing; one that is not read turns self-merge off."

**Location:** `scripts/build-loop.sh:135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `:132-136`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3 cited this as `:177` (a line-number slip; the text is at `:135`).

**Evidence:** `scripts/build-loop.sh:136`

---

## Claim 20: "Self-merge never: first, because a malformed line turns self-merge off."

**Location:** `scripts/build-loop.sh:144`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the ordering dependency on `never_ok` at `:170`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:144-146`, `:170-171`

---

## Claim 21: "Split on single spaces only; globform then refuses any other blank in an entry." / "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:149`, `:155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers tab, VT and FF entries (malformed) and globbing against planted files (none).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3 cited `:191` and `:197` (line-number slips).

**Evidence:** `scripts/build-loop.sh:150`, `:155`

---

## Claim 22: fixture — "a throwaway repo under $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-5`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the env block against dev-cycle.bats' setup.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** none

**Evidence:** `test/lib/build-loop-fixtures.bash:11-18`

---

## Claim 23: "settings LINE...: docs/dev-cycle.md holding these lines (printf %s\n each), committed. With no lines the file holds one empty line."

**Location:** `test/lib/build-loop-fixtures.bash:24-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the no-argument case (iteration-2 A11).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

`printf '%s\n' | od -c` gives a single `\n` (1 byte), so the file holds one empty line.

**Evidence:** `test/lib/build-loop-fixtures.bash:26`

---

## Claim 24: "settings_is KEY WANT / settings_like KEY PREFIX: ... On a mismatch, print the whole output." / "line KEY: the --settings output line that starts with KEY."

**Location:** `test/lib/build-loop-fixtures.bash:28-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both helpers and `line`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/lib/build-loop-fixtures.bash:31-36`

---

## Claim 25: suite header — "Each test builds a throwaway repo under $BATS_TEST_TMPDIR ...; this repo is untouched. The lib ... is also tested from dev-cycle.sh's side, in test/scripts/dev-cycle.bats."

**Location:** `test/scripts/build-loop-read.bats:3-6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the header text.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:3-6`

---

## Claim 26: test titles T1, T2, T3, T3/G19, slots, usage/exit and lib source

**Location:** `test/scripts/build-loop-read.bats:13`, `:24`, `:43`, `:70`, `:90`, `:143`, `:161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each title against what its test asserts.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:13-178`; baseline 9/9

---

## Claim 27: T4 — "the working tree and other branches never decide" and "Committed on a checked-out loop branch: HEAD is not main."

**Location:** `test/scripts/build-loop-read.bats:78`, `:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the HEAD and working-tree mutants against T4.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:78-88`; r1 mut-head.log

---

## Claim 28: "Copies in markup, a table, a link or with a misplaced colon count as second lines too."

**Location:** `test/scripts/build-loop-read.bats:122`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the eight shapes in the loop at `:123-124` (all counted); does not establish the general statement for links or markup.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: true for the listed shapes.

As a general statement it misses the shapes in Claim 8: `[Self-merge](u) never: b/` and `- [x] Self-merge never: b/` are not counted.

**Evidence:** `test/scripts/build-loop-read.bats:122-127`; r1 probes.log

---

## Claim 29: "A part starting .git is allowed: the list only adds refusals." / "A never line Markdown would continue on the next line is malformed." / "Raised only on a loop's branch or in the working tree: ignored."

**Location:** `test/scripts/build-loop-read.bats:128`, `:131`, `:136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each test block's assertions; the pathform mutant fails at `:130`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:128-141`

---

## Claim 30: "From a subdirectory and from a linked worktree, it reads the same main."

**Location:** `test/scripts/build-loop-read.bats:169`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers telling main apart from the working tree in both runs; does not establish telling main apart from the checked-out HEAD.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: true as worded (both runs read main). r1: the test cannot tell main from HEAD (see Claim 38).

**Evidence:** `test/scripts/build-loop-read.bats:170-177`; r1 mut-head.log (`ok 9`), mut-worktree.log (`not ok 9`)

---

## Claim 31: 1d79ffef R2 — "The checks are separate commands now; a mutation back to pathform fails T45."

**Location:** commit 1d79ffef message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every helper pair on one line (all joined with `;`), helpers inside `for` loop bodies (a failure is fatal), and the pathform mutant (fails at `:130`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:81`, `:87`, `:130`; mutant logs

---

## Claim 32: 1d79ffef R3/A5 — "copies with markup closing before the colon, a table cell, a link or "Self-merge never :" were hidden. A line now counts as a copy when its letters alone ... so any of them is a second line"

**Location:** commit 1d79ffef message (R3/A5)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the four named categories; does not establish markup in general (Claim 8).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** none

"Any ... link" is too broad: a link that closes inside the key (`[Build-loop](x) policy: review`) stays hidden. A precise version: "a link around the whole key".

**Evidence:** `test/scripts/build-loop-read.bats:33-37`, `:122-127`; r1 probes.log; baseline ok 2, ok 7

---

## Claim 33: 1d79ffef "A never line followed by a non-blank line is malformed"

**Location:** commit 1d79ffef message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rule itself; its parenthetical reason is Claim 16.
**Replicate verdicts:** r1=Verified · r2=Verified (compound, Claim 34) · r3=Verified (compound, Claim 29)
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:131-133`

---

## Claim 34: 1d79ffef A6, A7, A8, A11–A13, C3, C13

**Location:** commit 1d79ffef message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers GIT_NO_REPLACE_OBJECTS, main_file's error and failed-read arms, NEVER as an array, the comment, Exit and "Unknown option" fixes, the C3 reset, and the tab case in the no-echo check.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:55`, `:63`, `:79-83`, `:130`, `:164`; `test/scripts/build-loop-read.bats:117`

---

## Claim 35: 1d79ffef A14/A15 — "T4 and T45 now have a working tree and a checked-out branch that differ from main; a mutant reading HEAD fails them."

**Location:** commit 1d79ffef message; `test/scripts/build-loop-read.bats:78-88`, `:136-141`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers T4 and T45 against the `"HEAD:$f"` mutant.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:78-88`; r1 mut-head.log (`not ok 5`, `not ok 7`)

---

## Claim 36: 1d79ffef A14/A15 — "the subdirectory and worktree runs ... now have a working tree and a checked-out branch that differ from main; a mutant reading HEAD fails them."

**Location:** commit 1d79ffef message; `test/scripts/build-loop-read.bats:169-178`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers test 9's subdirectory and linked-worktree runs; does not establish anything about T4 and T45 (Claim 35).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: no coverage is lost overall, because T4 and T45 kill the HEAD mutant. · r1: "A14's 'could not tell main from ... worktree HEAD' is still open for these runs." · r3: "Fix: commit on `wt` after creating it, or reword the message."

The subdirectory run is in the main checkout on `main`. The `wt` branch is created at main (`git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main`, `:171`) with nothing committed on it. The `"HEAD:$f"` mutant passes test 9. Only the working-tree mutant fails it.

**Evidence:** `test/scripts/build-loop-read.bats:171` — `git worktree add -q -b wt "$BATS_TEST_TMPDIR/wt" main && mkdir -p sub`; r1 mut-head.log (`ok 9`)

---

## Claim 37: 1d79ffef — "The unit is 400 changed code lines"

**Location:** commit 1d79ffef message
**Type:** Behavioral (line count)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** `git diff --numstat feat/build-loop-u1a...HEAD -- scripts test`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

186 + 36 + 178 = 400.

**Evidence:** `scripts/build-loop.sh:1-186`; numstat output

---

## Claim 38: 1d79ffef — "Override-log rows for A9/A10 and C1, C2, C4-C11, C14-C19." / "Also merges feat/build-loop-u1a's iteration-2 fixes first."

**Location:** commit 1d79ffef message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the override-log rows and the merge-commit order.
**Replicate verdicts:** r1=Verified · r2=— · r3=—
**Replicate annotations:** none

**Evidence:** `docs/reviews/override-log.md`; `git log`

---

## Claim 39: 1d79ffef Notes — "the letters-only match can unset the policy for a prose line that starts with the key's words (docs/dev-cycle.md has none; T3's real-file test would catch one)"

**Location:** commit 1d79ffef message (Notes)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers docs/dev-cycle.md at HEAD and test 4's detection for each key; does not establish future edits.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "Covers the policy key; does not establish detection of a prose line starting 'Build-loop slots' or 'Self-merge never'". · r2: a never-key prose line "would make the never line malformed and turn self-merge off"; a slots-key prose line would drop slots to 3. Test 4 passes both.

"has none" holds. "T3's real-file test would catch one" holds only for the policy key, because test 4 asserts only the policy line (`:74`).

**Evidence:** `test/scripts/build-loop-read.bats:70-76`; r2 doc-policy.log (exit 1), doc-never.log (exit 0), doc-slots.log (exit 0)

---

## Claim 40: earlier commits' copy-rule and never claims (224dd52d, 30676e57) at HEAD

**Location:** commit 224dd52d and commit 30676e57 messages
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether the named shapes still behave as stated (HEAD's mechanism is a superset); does not re-verdict A10 (settled).
**Replicate verdicts:** r1=— · r2=— · r3=Verified
**Replicate annotations:** none

**Evidence:** `scripts/build-loop.sh:101-105`; r3 copy-probes.log, never-probes.log

---

## Claim 41: "--settings: policy variants are unset, so review, and say why (T2)" and the remaining T1/T3/slots/usage titles' sub-assertions

**Location:** `test/scripts/build-loop-read.bats:24-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the T2 loops.
**Replicate verdicts:** r1=Verified (Claim 18) · r2=Verified (Claims 25-26) · r3=Verified (Claim 27)
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:13-178`; baseline 9/9

---

## Claim 42: "Missing, a symlink, a directory, and a file only in the working tree."

**Location:** `test/scripts/build-loop-read.bats:55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers T3's file-kind cases.
**Replicate verdicts:** r1=— · r2=Verified · r3=—
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:55-67`

---

## Claim 43: "--settings prints its three lines in order and exits 0; usage errors and a missing default branch exit 1"

**Location:** `test/scripts/build-loop-read.bats:143`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the order, exit codes and stderr-only usage errors.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:143-159`

---

## Claim 44: the no-echo check covers malformed entries, tabs included (C13)

**Location:** `test/scripts/build-loop-read.bats:117-118`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tab case.
**Replicate verdicts:** r1=Verified (Claim 27) · r2=Verified (Claim 35) · r3=Verified (Claim 30)
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:117`

---

## Claim 45: "--settings: slots are 1 to 9 on one exact line, else 3"

**Location:** `test/scripts/build-loop-read.bats:90-101`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the slots test.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

**Evidence:** `test/scripts/build-loop-read.bats:90-101`; baseline ok 6

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (`scripts/build-loop.sh:26-27`) and **Claim 14** (`:90-92`): "markup ... cannot hide a copy" is false for markup that adds letters before or inside the key: a checked `[x]` task item, inline HTML in mid-line, or a link that closes inside the key. Such a copy is not counted. A second `- [x] Self-merge never: b/` leaves `never a/ set` and self-merge on.
- **Claim 36** (1d79ffef A14/A15; `test/scripts/build-loop-read.bats:171`): test 9's runs have HEAD equal to main's commit, so the HEAD mutant passes test 9. T4 and T45 still catch it.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`:11-12`): a second never copy or an unread file reads `malformed`, not the default.
- **Claim 5** (`:19-20`), **Claim 15** (`:92-93`): NEXT is the next line outside fences (EOF counts as blank).
- **Claim 16** (`:152`, and the 1d79ffef message): "Markdown would join it" is too broad; a heading, list item or comment is refused too.
- **Claim 28** (`build-loop-read.bats:122`): true only for the listed shapes.
- **Claim 30** (`build-loop-read.bats:169`): tells main from the working tree, not from HEAD.
- **Claim 32** (1d79ffef R3/A5): "any link" is true only for a link around the whole key.
- **Claim 39** (1d79ffef Notes): T3's real-file test catches a prose copy for the policy key only.

### Unverifiable
- None.

---

## Escalations

| # | Entry | path:line | Raised by | Addressee |
|---|---|---|---|---|
| E1 | Letter-bearing markup (`- [x]` task item, mid-line inline HTML, a link closing inside the key) hides a second copy of a key. This differs from settled C19 (entity, zero-width): C19's "does not render as the key" premise does not hold for these shapes. Decide whether this is amber, a C19 extension, or a strip before the match. | `scripts/build-loop.sh:101-105`, `:25-27` | r1, r3 | security-reviewer / orchestrator |
| E2 | Test 9 cannot tell main's commit from a linked worktree's HEAD (A14 partly open). Amber test gap, or a message-only inaccuracy? | `test/scripts/build-loop-read.bats:169-178` | r1, r2, r3 | test-strategy / orchestrator |
| E3 | A non-ASCII-letter (homoglyph) copy of a key stays hidden. It is the same class as C19, but it renders as the key. | `scripts/build-loop.sh:101` | r2 | orchestrator (C19 premise note) |
| E4 | The replace-ref guard (A6) and main_file's error and failed-read arms (A7) have no test. | `scripts/build-loop.sh:63`, `:79-83` | r2, r3 | test-strategy |

---

## Verdict stability

- Total clusters: 45.
- Clusters where every replicate that reported agreed: 37.
- Clusters where verdicts disagreed: 8.
  - Claim 7: r1=V, r2=V (compound), r3=MA (compound).
  - Claim 8: r1=I, r2=V (compound), r3=MA.
  - Claim 14: r1=I, r2=V (compound), r3=MA (compound).
  - Claim 16: r1=V, r2=MA, r3=MA (compound).
  - Claim 28: r1=MA, r2=V, r3=V.
  - Claim 30: r1=MA, r2=V, r3=V.
  - Claim 32: r1=MA, r2=V, r3=V.
  - Claim 39: r1=V, r2=MA, r3=MA.
- Agreement rate: 37/45 = 82%.

The Claim 8/14 split comes from coverage, not judgment: r2 never probed letter-bearing markup, while r1 and r3 both found the hidden copies by running them. Claim 5 is counted as agreeing, because r1's Verified there is compound.

---

## Submitted Claims

## Claim 46: "The policy and slots lines print no repo text besides line numbers, and the never line prints its value only after every entry passes globform."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (the trust-boundary row for `--settings` output: which repo-controlled bytes can reach stdout)
**Location:** `scripts/build-loop.sh:143-177`; `test/scripts/build-loop-read.bats:117-118` (T45 no-echo assertion)
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every assignment to POLICY_LINE, SLOTS_LINE and NEVER_LINE in read_settings (`:127-179`), `many()`, main_file's FILE_WHY strings (`:71-88`) and the lib's `oddwhy`, on the raw pre-scrub output, for the hostile payloads listed below; also confirms by mutation that the T45 assertion at `:117-118` fails when a malformed never entry is echoed. Does not establish anything about how later modes (U1c/U2) consume POLICY/NEVER, does not cover stderr from a git or awk failure, and does not claim the printed globs are safe for a consumer that expands them with a shell (the set line holds literal `*` and `?`). "Line numbers" is read loosely: the policy set line also prints the regex capture `self-merge`/`review` and the slots set line the captured digit 1-9; both are fixed alternatives, not free repo text.

Policy and slots lines. Every value that is not a fixed string is a line number from awk's `NR` or a capture of a fixed alternative:

```bash
# scripts/build-loop.sh:166-177
    if [[ -z "${cnt[policy]-}" ]]; then POLICY_LINE='policy review unset: no line starts "Build-loop policy:"'
    elif [[ "${cnt[policy]}" -gt 1 ]]; then POLICY_LINE="policy review unset: $(many 'Build-loop policy:' policy)"
    elif [[ "${text[policy]}" =~ ^Build-loop\ policy:\ (self-merge|review)$ ]]; then
      v="${BASH_REMATCH[1]}"
      if [[ "$v" == self-merge && -z "$never_ok" ]]; then
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but the Self-merge never: line is malformed, so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
    else POLICY_LINE="policy review unset: line ${first[policy]} is not exactly \"Build-loop policy: self-merge\" or \"Build-loop policy: review\""; fi
    if [[ -z "${cnt[slots]-}" ]]; then SLOTS_LINE='slots 3 default: no line starts "Build-loop slots:"'
    elif [[ "${cnt[slots]}" -gt 1 ]]; then SLOTS_LINE="slots 3 default: $(many 'Build-loop slots:' slots)"
    elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: line ${first[slots]} $where"
    else SLOTS_LINE="slots 3 default: line ${first[slots]} is not exactly \"Build-loop slots: N\" with N from 1 to 9"; fi
```
(excerpt ends :177; enclosing read_settings() continues to :179 (closing `fi` and `}`) — read; the values flow to the `printf` at `:184`, their first and only use)

`first[...]`/`second[...]` are awk's `NR` (`l1[k] = NR`, `l2[k] = NR`, `:105`), parsed from the part of each record before its first tab (`read -r k c l1 l2 nx <<<"${l%%$'\t'*}"`, `:140`); that prefix is built entirely by the END block (`print k " " c[k] " " l1[k] ...`), so it holds no repo bytes. `many()` prints only those numbers and its fixed key argument (`:143`). `$where` is built from the constant `f=docs/dev-cycle.md` (`:128`, `:131`). When the file is not read, FILE_WHY holds only fixed prose, the constant path, a line number and `oddwhy`'s fixed reason (main_file `:84-87`, lib `oddwhy`); SETTINGS_AWK's END prints `odd`/`unbalanced` records only from `odd`, `oddwhy` (fixed `refuse()` arguments) and `fline`.

Never line. `$v` reaches NEVER_LINE only on the set branch:

```bash
# scripts/build-loop.sh:150-164
      if [[ "$t" != "Self-merge never: "* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
        why='is not exactly "Self-merge never: GLOB ..." with single spaces'
      elif [[ "${next[never]}" != 1 ]]; then why="is followed by a non-blank line (Markdown would join it as more globs)"
      else
        i=0
        IFS=' ' read -ra parts <<<"$v"  # not a bare $v: the shell would expand * and ? against files
        for g in "${parts[@]}"; do
          i=$((i + 1))
          if ! globform "${g%/}"; then why="lists entry $i, which is not an allowed glob form"; break; fi
          if [[ -n "${seen[${g%/}]-}" ]]; then why="lists entry $i twice"; break; fi
          seen[${g%/}]=1
        done
      fi
      if [[ -n "$why" ]]; then NEVER_LINE="never malformed: line ${first[never]} $why"; never_ok=""
      else NEVER=("${parts[@]}"); NEVER_LINE="never $v set: line ${first[never]} $where"; fi
```
(excerpt starts inside the never `else` arm opened at `:147`; enclosing read_settings() runs `:127-179` — read)

The `=~` test makes `$v` exactly the single-space join of non-space runs, and `read -ra` with `IFS=' '` splits on exactly those spaces, so `parts` covers every byte of `$v` but the separators. Each `${g%/}` must pass globform (`:114-121`, NAMECHARS plus `*` `?`, not starting `/` or `-`, no empty, `.` or `..` part), so the printed value is NAMECHARS, `*`, `?`, `/` and single spaces. The malformed branch prints only `line N` and fixed `why` text with the entry index `i`.

Executed (probe-out.txt, 21 cases). Payloads: ESC/OSC sequences (`\e[31m`, `\e]0;title\a`, `\e[2J`) in the policy, slots and never values; `$(touch /tmp/pwn)` and backticks in policy and never; non-ASCII (Arabic-Indic digit for slots, `caf\xc3\xa9`, U+202E in never); a 6000-byte policy line and never line (valid, and with a trailing ESC); duplicate keys whose second copy holds ESC (`**build loop policy** \e x`); three hostile slots copies; near-miss keys (`Build loop policy: self-merge`, `BUILD_LOOP_SLOTS=5`, `Self merge never - x/`, `Buildlooppolicy:self-merge`); `a[b] c\d` and a tab separator in never; files refused by FENCE_AWK (a `<div>\e[31m` line, a mid-line CR followed by ESC, an indented fence with ESC). Results: every policy/slots line was a fixed reason with line numbers only (e.g. `policy review unset: line 1 is not exactly ...`, `slots 3 default: more than one line starts "Build-loop slots:" (lines 1 and 2)`); every hostile never value gave `never malformed: line 2 lists entry 1, which is not an allowed glob form` or the single-spaces reason; refused files printed only `line 2 of docs/dev-cycle.md <oddwhy reason>, so the file is not read` on all three lines. `cat -A` showed no `^[` or other control byte in any output, and `/tmp/pwn` was not created. Accepted values printed verbatim and only NAMECHARS/`*`/`?`: `never * ? */*.sh set: ...`, `never .github/ x/* set: ...`, and the 6000-`a` entry whole (pre-scrub; the scrub's 4096-byte cut of such a line is settled as C2).

Mutation (`submitted/mut/`, copies only): changing `:163` to `NEVER_LINE="never malformed: line ${first[never]} $why [$v]"` makes T45 fail at `test/scripts/build-loop-read.bats:118` with `echoed a malformed entry: ... never malformed: line 2 lists entry 1, which is not an allowed glob form [../x]`, so the cited no-echo assertion is live for the never line. (Echoing on the policy/slots lines would be caught by the exact-string `settings_is` checks of T2 and the slots test instead.)

**Evidence:** `scripts/build-loop.sh:71-88`, `scripts/build-loop.sh:96-111`, `scripts/build-loop.sh:114-121`, `scripts/build-loop.sh:127-179`, `scripts/build-loop.sh:181-186`, `scripts/lib/dev-cycle-read.sh:139`, `scripts/lib/dev-cycle-read.sh:231-241`, `test/scripts/build-loop-read.bats:117-118`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/submitted/probe.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/submitted/probe-out.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/submitted/mut/`

---

## Claim 47: "A never line followed by a non-blank, non-fence line is malformed and turns self-merge off."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (A5 closure: a never line Markdown would continue on the next line must not be read short)
**Location:** `scripts/build-loop.sh:100`, `:152`, `:170-171`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line after the first never copy outside a fence: text, an indented line, a list item, a heading, a one-line HTML comment, another key line, a form feed (all malformed), and a blank, whitespace-only, CRLF-blank line or EOF (all set); fence lines after the never line; and the self-merge-off consequence on the policy line. Does not establish a matching rule for the policy or slots lines (there is none; see below), and does not judge whether the rule matches CommonMark beyond failing closed.

```awk
# scripts/build-loop.sh:97-106 (SETTINGS_AWK)
{ sub(/\r$/, "") }
fence($0) { next }
{
  if (pk != "") { nx[pk] = ($0 ~ /^[ \t]*$/); pk = "" }
  s = tolower($0); gsub(/[^a-z]/, "", s); k = ""
  if (index(s, "buildlooppolicy") == 1) k = "policy"
  else if (index(s, "buildloopslots") == 1) k = "slots"
  else if (index(s, "selfmergenever") == 1) k = "never"
  if (k != "") { c[k]++; if (c[k] == 1) { l1[k] = NR; t[k] = $0; nx[k] = 1; pk = k } else if (c[k] == 2) l2[k] = NR }
}
```
(excerpt ends :106; the SETTINGS_AWK string continues to :111 (END block, which prints `nx[k]` as the NEXT field) — read)

`nx[never]` starts at 1 (blank-or-EOF) and is overwritten by the next record that is not consumed by `fence($0) { next }`; `next[never] != 1` gives the malformed reason at `:152`, `never_ok=""` at `:163`, and `:170-171` turns a `self-merge` policy into `policy review unset ... so self-merge is off`. Lines that `fence()` refuses (open comment, raw HTML, refdef, CR, NUL) make the whole file unread, which is `never malformed` by the not-read path (`:136`).

Executed (probe2-out.txt). Malformed with `policy review unset: line 1 reads self-merge, but the Self-merge never: line is malformed, so self-merge is off`: next line `b/`, `    b/`, `- b/`, `# H`, `<!-- note -->`, `\f`, `Build-loop slots: 4`, and the policy line itself (`Self-merge never: a/` then `Build-loop policy: self-merge` gives `never malformed: line 1 is followed by a non-blank line ...` and `policy review unset: line 2 reads self-merge ...`). Set (`never a/ set`, `policy self-merge set`): next line empty, spaces-and-tab only, `\r` alone, or EOF. Fence cases: a fenced block right after the never line is skipped, so the next unfenced line decides: block then blank or EOF is set; block then `b/` is malformed (backtick and tilde fences alike). An open comment after the never line refuses the file (`line 3 ... opens an HTML comment ...`, all three lines; policy review unset). With `Build-loop policy: review`, a continued never line is still `never malformed` and policy stays `review set`, so "turns self-merge off" is vacuous there, as expected.

Observation for the critic (not a verdict input; the claim asserts nothing about it): the next-line rule is applied only to the never line. `Build-loop policy: self-merge` followed by `except on Fridays` prints `policy self-merge set: line 1 ...`, and `Build-loop slots: 4` followed by `more` prints `slots 4 set`, though Markdown would render each as one longer paragraph. `nx[k]` is computed for every key (`:100`, `:105`) but read only for `never` (`:152`). Whether that asymmetry matters is the critic's call; the header (`:13-17`) documents "exactly" for policy and slots, which holds line by line.

**Evidence:** `scripts/build-loop.sh:96-111`, `scripts/build-loop.sh:136`, `scripts/build-loop.sh:147-164`, `scripts/build-loop.sh:168-173`, `scripts/lib/dev-cycle-read.sh:186-229` (FENCE_AWK `fence()`), `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/submitted/probe2.sh`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i3/submitted/probe2-out.txt`

---

## Claims Requiring Attention

None: both submitted claims are Verified. One observation is attached to Claim 47 for the critic: the policy and slots lines have no next-line rule, so a continued `Build-loop policy: self-merge` paragraph still reads `self-merge set`.

