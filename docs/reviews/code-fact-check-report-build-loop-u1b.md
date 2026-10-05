# Code Fact-Check Report

**Commit:** 0ae7d801
**Replication:** k=3
**Repository:** /workspace/.claude/wt-build-loop-u1b (branch feat/build-loop-u1b)
**Scope:** unit diff `feat/build-loop-u1a...feat/build-loop-u1b` at 0ae7d801 (review-fix loop iteration 2, full panel, not a loop pass): scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, and commit messages 0797ed32, 224dd52d, 30676e57, 0ae7d801. scripts/lib/dev-cycle-read.sh read as context only.
**Checked:** 2026-10-05
**Total claims checked:** 47
**Summary:** 36 verified, 4 mostly accurate, 0 stale, 6 incorrect, 1 unverifiable (42 harvested in Stage 1 plus 5 submitted-claim rows from Stage 2.5)

Merged by the orchestrator, most-severe-wins, from `code-fact-check-report-build-loop-u1b-r1.md`, `-r2.md` and `-r3.md` (all `Commit: 0ae7d801`). Mechanical collation only: no claim or evidence was added. Execution logs live in the replicates' scratch dirs, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/fc-r{1,2,3}/` (abbreviated `$S1`, `$S2`, `$S3`), not in `docs/reviews/execution-logs/`, because this pass may write only review reports. Iteration 1's k=1 report (at 224dd52d) is superseded by this file; it is in git history.

Bats at 0ae7d801, all three replicates: `test/scripts/build-loop-read.bats` 9/9 and `test/scripts/dev-cycle.bats` 66/66 pass.

---

## Claim 1: "It is set only when exactly one line, outside code fences, starts "Build-loop policy:" and reads exactly "Build-loop policy: self-merge" or "Build-loop policy: review" (one trailing CR is dropped). Any other case, or a malformed never line, means review."

**Location:** `scripts/build-loop.sh:11-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exact text, one line, one trailing CR, fenced copies, duplicates and the malformed-never fallback, by probe and by T1–T3; does not establish what U2's gate does with POLICY.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

The policy branch (`scripts/build-loop.sh:172-179`) accepts only `^Build-loop\ policy:\ (self-merge|review)$` on the single counted line, after SETTINGS_AWK's `sub(/\r$/, "")`; every other path sets `policy review unset`.

**Evidence:** `scripts/build-loop.sh:96`, `:172-179`; `test/scripts/build-loop-read.bats:13-75`; `$S1`, `$S2`, `$S3` probe logs

---

## Claim 2: "How many build loops may run at once: one line "Build-loop slots: N" with N from 1 to 9, else 3."

**Location:** `scripts/build-loop.sh:17-19`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 0, 1, 9, 10, two lines and absent; does not establish how a later mode uses the number.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

`^Build-loop\ slots:\ ([123456789])$` (`:182`); every other branch prints `slots 3 default`.

**Evidence:** `scripts/build-loop.sh:180-183`; `test/scripts/build-loop-read.bats:87-98`

---

## Claim 3: "Self-merge never: GLOB ..." (single spaces, no tab; each glob uses letters, digits, . _ - / * ?, with an optional trailing /; no empty, . or .. part, not starting / or -; none twice, a trailing / ignored)

**Location:** `scripts/build-loop.sh:20-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed rule by probe and T45; does not establish U2's matching semantics for the globs.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "empty parts (`a//`) refused" · r3: "vertical tabs and form feeds are also refused, though the header doesn't say so" · r1+r3: "an entry of `*` does not collide with the array's `[*]` subscript: `a *` is accepted, only `* *` is a duplicate"
**Legibility-target:** for-orchestrator-synthesis

globform (`:118-128`) and the separator check (`:157`) implement the list; the duplicate check keys on `${g%/}` (`:165-166`).

**Evidence:** `scripts/build-loop.sh:118-128`, `:155-170`; `test/scripts/build-loop-read.bats:100-132`

---

## Claim 4: "A malformed line, or a settings file that is not read, turns self-merge off."

**Location:** `scripts/build-loop.sh:26-27`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers malformed never lines, two never lines, a non-blob or FENCE_AWK-refused file; does not establish the gate's use.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

`never_ok=""` on every malformed branch, and `:176-177` turns a self-merge policy into `policy review unset`; a refused file prints `policy review unset` and `never malformed` (`:139-143`).

**Evidence:** `scripts/build-loop.sh:139-143`, `:150-151`, `:172-173`, `:176-177`

---

## Claim 5a: "A line outside a fence counts as a settings line when it starts with the key (any case) after any blanks, >, list markers, # * _ ` ~ and byte-order marks"

**Location:** `scripts/build-loop.sh:28-30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed prefix class (tabs, numbered lists, several BOMs, `~~`); does not establish counting of shapes outside the list.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2+r3: "rendered copies still uncounted, so hidden: GFM task item `- [ ] KEY`, link text `[KEY](x)`, a leading NBSP, a table row `| KEY |`" · r1: "`\# KEY` (escaped heading) and `&#66;uild-loop policy:` (entity)" · r3: "zero-width characters before a key; spacing variants such as `Build-loop  policy:`" · r2: "in each, the policy stayed self-merge (probe1.log)"
**Legibility-target:** for-orchestrator-synthesis

The strip regex `^([ \t>#*_`~]|[-+][ \t]|[0123456789]+[.)][ \t]|\357\273\277)*` (`:106`) covers the listed classes.

**Evidence:** `scripts/build-loop.sh:104-112`; `$S1`, `$S2/probe1.log`, `$S3/cases1.log`

---

## Claim 5b: "so a quoted, bold, heading or indented copy is a second line, not a hidden one"

**Location:** `scripts/build-loop.sh:30-31`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bold, emphasis and code-span forms whose closing marks sit before the colon; does not establish whether hidden copies matter to any reader other than a human viewing rendered Markdown.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Incorrect
**Replicate annotations:** r3: "the precise version: a copy counts when the key text including its colon is contiguous after the stripped prefix; a bold/emphasis/code span that closes before the colon stays hidden" · r1+r2: "the header's four named shapes are counted when the colon sits inside the markup (the tested forms)"
**Legibility-target:** for-author

After the strip at `:106`, `**Build-loop policy**: review` becomes `build-loop policy**: review`, which does not start with `build-loop policy:` (`:108`; excerpt ends :108, enclosing awk rule continues to :112 — read). With `Build-loop policy: self-merge` on line 1, each of `**Build-loop policy**: review`, `*Build-loop policy*: review`, `` `Build-loop policy`: review `` and `__Build-loop policy__: review` leaves `policy self-merge set`; `**Self-merge never**: b/` after `Self-merge never: a/` leaves `never a/ set`. Rendered, each shows the key label and a value: a second visible setting the script ignores.

**Evidence:** `scripts/build-loop.sh:106-110`; `$S3/cases1.log`, `$S3/cases2.log`

---

## Claim 6: "A file the lib's FENCE_AWK refuses (its comment lists each shape) is not read at all, and the line printed says why."

**Location:** `scripts/build-loop.sh:31-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers odd and unbalanced outputs through main_file; does not re-verify FENCE_AWK's own shape list (U1a's).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

`main_file` turns `odd N WHY` and `unbalanced N` into FILE_WHY and returns 1 (`:89-92`); read_settings prints it (`:140-141`).

**Evidence:** `scripts/build-loop.sh:89-92`, `:139-143`

---

## Claim 7: "Acts on $PWD's git repo, like dev-cycle.sh, and needs its default branch found by name (origin/HEAD, main or master)."

**Location:** `scripts/build-loop.sh:35-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rev-parse, resolve_main and main_by_name use; does not establish origin/HEAD edge cases (override-log u0b row).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

`ROOT=... --show-toplevel`, `resolve_main || true`, `main_by_name || exit 1` (`:65-71`).

**Evidence:** `scripts/build-loop.sh:65-71`

---

## Claim 8: "Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the working tree and `.git` before and after a run; does not establish behaviour under a read-only object store.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

A snapshot of the tree and `.git` was unchanged after runs; the script only calls ls-tree, cat-file, rev-parse.

**Evidence:** `scripts/build-loop.sh:64-200`; `$S1`, `$S2`, `$S3` read-only probes

---

## Claim 9: "Output passes through the lib's scrub (all but the two start-up errors before it, about perl and the lib, which carry no repo text); printed repo text is data."

**Location:** `scripts/build-loop.sh:37-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which messages print before `scrub_reexec`; does not establish scrub's own completeness (U0's).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "a `DEV_CYCLE_SCRUBBED` value already set in the caller's environment skips the scrub entirely; the lib documents this" · r3: "ESC and bidi characters in a usage error are stripped"
**Legibility-target:** for-orchestrator-synthesis

Only the perl (`:46`) and lib (`:52`) errors precede `scrub_reexec` (`:54`).

**Evidence:** `scripts/build-loop.sh:45-54`

---

## Claim 10: "Exit: 0 every line printed; 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no default branch found by name."

**Location:** `scripts/build-loop.sh:40-41`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every exit path; does not establish exit codes of a future mode.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "`-h`/`--help`, with or without extra arguments, exits 0" (the extra-arguments case is an override-log Won't-Fix row)
**Legibility-target:** for-author

The listed codes hold; the list omits the help exit 0 (`:60`).

**Evidence:** `scripts/build-loop.sh:56-70`

---

## Claim 11: "The reader shared with dev-cycle.sh, from this script's own directory (never the target repo's scripts/lib/), so a copy of scripts/ with its lib/ is self-contained."

**Location:** `scripts/build-loop.sh:46-51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers SCRIPT_DIR resolution before the cd and G16; does not establish the D6 hash check (U3b, override-log row).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

`SCRIPT_DIR` is resolved from `BASH_SOURCE` before `cd "$ROOT"`; test `:152` removes the lib and gets exit 1.

**Evidence:** `scripts/build-loop.sh:46-53`; `test/scripts/build-loop-read.bats:152-158`

---

## Claim 12: help prints `sed -n '2,41p'`, the whole header

**Location:** `scripts/build-loop.sh:60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the range against the header at HEAD; does not establish it stays aligned after U1c edits.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

Lines 2–41 are exactly the header comment block.

**Evidence:** `scripts/build-loop.sh:2-41`, `:60`

---

## Claim 13: main_file: "sets FILE_WHY and returns 1 when it is absent ("absent"), stored as anything but a regular file under plain directories, or refused by FENCE_AWK; otherwise FILE_OUT holds what the awk program $2 printed over it"

**Location:** `scripts/build-loop.sh:73-77`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every main_entry result main_file handles; does not establish when ls-tree fails in practice.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "main_entry's `error` result (ls-tree failed, or no default branch by name) also returns 1, through the catch-all, and is reported as 'is not a regular file on the default branch'" · r1: "only with a broken object store"
**Legibility-target:** for-author

The `*)` arm at `:87` takes `error` as well as non-blob types; it fails closed but names the wrong reason.

**Evidence:** `scripts/build-loop.sh:79-88`; `scripts/lib/dev-cycle-read.sh` main_entry

---

## Claim 14: SETTINGS_AWK: "per key, how many lines start with it (after blanks, >, list markers, heading and emphasis marks (# * _ ` ~) and a BOM, any case), the first two line numbers and the first line whole"

**Location:** `scripts/build-loop.sh:96-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output format and the strip; same residue as Claim 5a.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** see Claim 5a (same uncounted shapes)
**Legibility-target:** for-orchestrator-synthesis

The END block prints `k c l1 l2\tt[k]` (`:115`).

**Evidence:** `scripts/build-loop.sh:101-116`

---

## Claim 15: globform: "pathform's characters and glob marks, not starting / or -, no empty, . or .. part. Unlike pathform it allows a part starting .git (.github/, .gitignore): the list only adds refusals, so naming one must not make the line malformed and turn self-merge off."

**Location:** `scripts/build-loop.sh:117-125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the comparison with the lib's pathform and NAMECHARS; does not establish U2's matching.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "`.git`, `.git/`, `.GIT`, `.git/x`, `.git/config` are accepted too; harmless if the list only ever adds refusals (git never tracks `.git` paths)"
**Legibility-target:** for-orchestrator-synthesis

globform drops pathform's `.git*` part test and keeps the rest.

**Evidence:** `scripts/build-loop.sh:118-128`; `scripts/lib/dev-cycle-read.sh` pathform

---

## Claim 16: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (the globs, or empty) and NEVER_LINE from main's commit. POLICY and NEVER are for the modes that judge a brief (--status, then the gate)."

**Location:** `scripts/build-loop.sh:126-129`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the assignments; the consumers are U1c/U2, not in this diff.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/build-loop.sh:130-192`

---

## Claim 17: "An absent file sets nothing; one that is not read turns self-merge off."

**Location:** `scripts/build-loop.sh:142`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers absent vs refused/non-blob files.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/build-loop.sh:139-143`

---

## Claim 18: "Single spaces only: a tab or other blank would split differently in a later reader." (with `*[$'\t\v\f\r']*`)

**Location:** `scripts/build-loop.sh:156-157`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tab, VT, FF in the value; does not establish other Unicode blanks (refused by globform's character class).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "the CR branch is unreachable: the awk strips one trailing CR and the lib refuses any other"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/build-loop.sh:155-158`; `test/scripts/build-loop-read.bats:107-113`

---

## Claim 19: "not a bare $v: the shell would expand * and ? against files"

**Location:** `scripts/build-loop.sh:161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers word splitting via `read -ra` vs unquoted expansion.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/build-loop.sh:161`

---

## Claim 20: "a" and "a/" count as the same entry for "none twice"; the stored NEVER value

**Location:** `scripts/build-loop.sh:163-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `seen[${g%/}]`; does not establish U2's treatment of the trailing slash.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "the stored value keeps the slashes as written"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/build-loop.sh:163-170`

---

## Claim 21: "A policy of self-merge with a malformed never line prints "policy review unset", so the policy line always shows the policy in force." (224dd52d Notes; code `:176-177`)

**Location:** `scripts/build-loop.sh:176-177`; commit 224dd52d
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers POLICY staying `review` on that path.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/build-loop.sh:172-179`

---

## Claim 22: "a throwaway repo under $BATS_TEST_TMPDIR with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the env exports vs dev-cycle.bats.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/lib/build-loop-fixtures.bash:1-24`

---

## Claim 23: "settings LINE...: docs/dev-cycle.md holding these lines (printf %s\n each), committed. Pass no lines for an empty file."

**Location:** `test/lib/build-loop-fixtures.bash:26-28`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the no-argument call; no current test calls it that way.
**Replicate verdicts:** r1=Incorrect · r2=— · r3=Incorrect
**Replicate annotations:** r1+r3: "no current test relies on it"
**Legibility-target:** for-author

`printf '%s\n'` with no arguments writes one newline, so the file is one byte (one blank line), not empty.

**Evidence:** `test/lib/build-loop-fixtures.bash:26-29`; `$S1`, `$S3` probes

---

## Claim 24: "settings_is KEY WANT / settings_like KEY PREFIX: run --settings; its KEY line must equal WANT, or start with PREFIX. On a mismatch, print the whole output."

**Location:** `test/lib/build-loop-fixtures.bash:30-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the helpers' own return; their composition with `&&` is Claim 38.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/lib/build-loop-fixtures.bash:30-38`

---

## Claim 25: "Each test builds a throwaway repo under $BATS_TEST_TMPDIR (test/lib/build-loop-fixtures.bash); this repo is untouched."

**Location:** `test/scripts/build-loop-read.bats:3-6`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers setup and git status after the suite.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/scripts/build-loop-read.bats:1-11`

---

## Claim 26: test titles and comments (T1, T2, T3/G19 "Missing, a symlink, a directory, and a file only in the working tree", slots, usage/exit) describe what they assert

**Location:** `test/scripts/build-loop-read.bats:13`, `:24`, `:42`, `:54`, `:69`, `:87`, `:134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers titles against bodies; enforcement of `&&`-joined lines is Claim 38.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/scripts/build-loop-read.bats:13-150`

---

## Claim 27: "--settings reads main's commit: the working tree and other branches never decide (T4)"

**Location:** `test/scripts/build-loop-read.bats:77-85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title; a mutant reading the working tree is caught by `:84`, the test's last line.
**Replicate verdicts:** r1=— · r2=Verified · r3=—
**Replicate annotations:** r2: "`:80`'s working-tree check is off (Claim 38); a working-tree mutant is still caught, but only by `:84`" · single-replicate detection
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/scripts/build-loop-read.bats:77-85`

---

## Claim 28: no-echo check: malformed entries are never echoed (A3)

**Location:** `test/scripts/build-loop-read.bats:114-115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the entries the test discriminates on.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "it only tells cases apart for `../x`, `/etc`, `-x`, `./b` and `\xc3`"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/scripts/build-loop-read.bats:100-116`

---

## Claim 29: T45 comment "Bold, heading and emphasis copies count as second lines too."

**Location:** `test/scripts/build-loop-read.bats:119`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four tested forms; colon-outside forms are Claim 5b.
**Replicate verdicts:** r1=Verified · r2=— · r3=Mostly accurate
**Replicate annotations:** r3: "true only for the four tested forms, where the colon is inside the markup"
**Legibility-target:** for-author

**Evidence:** `test/scripts/build-loop-read.bats:117-123`; `$S3/cases2.log`

---

## Claim 30: "From a subdirectory and from a linked worktree, it reads the same main." (G20)

**Location:** `test/scripts/build-loop-read.bats:160`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test can distinguish; T4 is what pins main-only reading.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "it cannot tell main from the subdirectory's or worktree's own files, because they hold the same content"
**Legibility-target:** for-author

**Evidence:** `test/scripts/build-loop-read.bats:160-168`

---

## Claim 31: commit 0797ed32 body (the tests cover policy, slots, never "never echoed", usage and exit codes, G16, G20) and "U1 is split three ways"

**Location:** commit 0797ed32
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the listed coverage areas at 0797ed32 and HEAD.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `git show 0797ed32`; `test/scripts/build-loop-read.bats`

---

## Claim 32: commit 224dd52d: "malformed, or a settings file that is not read, turns self-merge off and is never echoed"

**Location:** commit 224dd52d
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD behaviour.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/build-loop.sh:150-174`

---

## Claim 33: commit 30676e57 R1/A1: "A tab, VT, FF or CR in the value is now malformed, and the split uses IFS=' '."

**Location:** commit 30676e57
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code at 30676e57 and HEAD.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "CR branch unreachable (see Claim 18)"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/build-loop.sh:157`, `:161`

---

## Claim 34: commit 30676e57 A2: "a bold, heading, emphasis or code-span copy of a key, or one behind a mid-file BOM, was not counted. The key strip now also drops # * _ ` ~ and BOMs, so such a copy is a second line"

**Location:** commit 30676e57; `scripts/build-loop.sh:106`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers colon-outside-markup copies; same mechanism as Claim 5b.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Incorrect
**Replicate annotations:** r3: "the same hidden-copy gap as 6b" · r1: "verified for the colon-inside forms"
**Legibility-target:** for-author

The commit claims every bold, emphasis or code-span copy counts; copies whose markup closes before the colon remain hidden (Claim 5b's probes).

**Evidence:** `scripts/build-loop.sh:106-110`; `$S3/cases1.log`, `$S3/cases2.log`

---

## Claim 35: commit 30676e57 A3, A4, "a" vs "a/", and header bullet

**Location:** commit 30676e57
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet at 30676e57; the header bullet was later replaced by 0ae7d801.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "its header bullet was later replaced by 0ae7d801 (history, not Stale)"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `git show 30676e57`; `test/scripts/build-loop-read.bats:100-132`, `scripts/build-loop.sh:118-128`

---

## Claim 36: commit 30676e57 Notes: "The wider key strip fails closed: a prose line starting "**Build-loop policy:**" now unsets the policy."

**Location:** commit 30676e57
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the colon-inside bold form named.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/build-loop.sh:106-110`

---

## Claim 37: commit 0ae7d801: "The review fixes took U1b to 426 changed code lines ... U1b is 398 lines."

**Location:** commit 0ae7d801
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pr-prep 1a count (192 + 38 + 168).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `git diff --stat feat/build-loop-u1a...0ae7d801 -- scripts test`; `scripts/build-loop.sh`, `test/lib/build-loop-fixtures.bash`, `test/scripts/build-loop-read.bats`

---

## Claim 38: commit 0ae7d801: "Two test helpers replace the repeated three-line ... blocks ... No assertion was dropped"

**Location:** commit 0ae7d801; `test/scripts/build-loop-read.bats:80`, `:126`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers enforcement of every assertion the refactor rewrote; does not establish whether later units repeat the `&&` pattern.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r3: "most of the coverage remains, because the second check on each line catches the same regressions" · r2: "with globform's `.git*` refusal put back, HEAD's T45 passes; the T45 from 30676e57 fails on the same change (mutations.log, M1)" · r1: "T4's `:82` and the slots operand at `:80` still partly cover the first"
**Legibility-target:** for-author

Each pair became `settings_like A && settings_like B` (`:80`, `:126`). Under bash errexit, a failing left operand of `&&` does not stop the shell, and neither line is the last in its test, so a wrong first operand is ignored. Mutation m4 (r1) changes both first operands to wrong values and T4 and T45 still pass; r2's M1 reverts the A4 fix and T45 still passes. The unenforced checks are T4's working-tree policy check and T45's `.github/ .gitignore set` check, the A4 regression test.

**Evidence:** `test/scripts/build-loop-read.bats:77-85`, `:124-126`; `test/lib/build-loop-fixtures.bash:33-34`; `$S1/mutation-and.log`, `$S2/mutations.log`, `$S2/andlist.bats`

---

## Claim 39: commit 0ae7d801: "A mutation check: without the IFS=' ' split, T45 fails on the tab cases; the explicit tab test is a second guard"

**Location:** commit 0ae7d801; `scripts/build-loop.sh:157`, `:161`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three mutations on the HEAD tree (both guards existed at 30676e57 too); does not establish what an uncommitted intermediate tree held.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "neither guard is pinned by a test on its own" · r2: "the roles are reversed: the tab test at `:157` is the first guard; the split plus globform is the backup" · r1: "matches the logged pattern of commit messages claiming test outcomes that do not reproduce"
**Legibility-target:** for-author

Removing only `IFS=' '`: T45 passes. Removing only the tab test: T45 passes. Removing both: T45 fails with `a<TAB>b` set.

**Evidence:** `scripts/build-loop.sh:157-164`; `test/scripts/build-loop-read.bats:107-113`; `$S1/mutation.log`, `$S2/mutations.log`, `$S3/mutation.log`

---

## Claim 40: commit 0ae7d801: "(globform also refuses a tab inside an entry)"

**Location:** commit 0ae7d801; `scripts/build-loop.sh:124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `a<TAB>b` as one entry under `IFS=' '`.
**Replicate verdicts:** r1=Incorrect (compound) · r2=Incorrect (compound) · r3=Verified
**Replicate annotations:** r1: "the parenthetical is accurate: with `IFS=' '`, `a<TAB>b` is one entry and globform refuses it (m2)"
**Legibility-target:** for-orchestrator-synthesis

Merge note: r1 and r2 verdicted the whole sentence; their Incorrect reasoning concerns the mutation sentence (Claim 39), and r1 states this parenthetical is accurate, so the compound verdict is not carried onto this sub-claim (the compound rule's purpose: a sub-claim's severe verdict must not swallow a sibling's clean one).

**Evidence:** `scripts/build-loop.sh:118-128`; `$S1/mutation.log` (m2)

---

## Claim 41: commit 0797ed32: "U1 is split three ways ...: U1a the lib, U1b --settings' settings-file lines, U1c the constraints line (T44) and --status"

**Location:** commit 0797ed32
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff contents.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `git diff --stat feat/build-loop-u1a...feat/build-loop-u1b`; `scripts/build-loop.sh`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5b** (`scripts/build-loop.sh:30-31`): bold, emphasis and code-span copies whose markup closes before the colon (`**Build-loop policy**: review`, `**Self-merge never**: b/`) stay hidden; with an exact self-merge line, `policy self-merge set` is printed.
- **Claim 23** (`test/lib/build-loop-fixtures.bash:27`): `settings` with no lines writes one newline, not an empty file.
- **Claim 34** (commit 30676e57, A2): the same gap as 5b.
- **Claim 38** (commit 0ae7d801; `test/scripts/build-loop-read.bats:80`, `:126`): two `&&` first operands are no longer enforced, including the A4 regression check.
- **Claim 39** (commit 0ae7d801): the mutation claim does not reproduce; either guard alone keeps T45 passing.

### Stale
- None.

### Mostly Accurate
- **Claim 10** (`scripts/build-loop.sh:40-41`): exit list omits help's exit 0.
- **Claim 13** (`scripts/build-loop.sh:73-77`): main_file's `error` case is undocumented and misreported as "is not a regular file".
- **Claim 29** (`test/scripts/build-loop-read.bats:119`): true only for colon-inside markup.
- **Claim 30** (`test/scripts/build-loop-read.bats:160`): the G20 test cannot tell main from the working tree.

### Unverifiable
- None.

## Escalations

- **E1** `scripts/build-loop.sh:30-31`, `:106-110` (Claims 5b, 34): a hidden bold-key copy (`**Build-loop policy**: review` beside an exact `Build-loop policy: self-merge`) leaves self-merge set. Raised by r3. Addressee: security-reviewer.
- **E2** `test/scripts/build-loop-read.bats:80`, `:126` (Claim 38): non-final `&&` assertions are unenforced under bats; the A4 guard is disabled. A few-line fix that touches the 400-line cap. Raised by r2, r3. Addressee: test-strategy (r3) / orchestrator (r2).
- **E3** `scripts/build-loop.sh:28-31` (Claim 5a): residual uncounted rendered shapes (task item, table cell, link text, NBSP, escaped heading, entity). Raised by r1 (Goal-Alignment: "for the security and API critics to weigh"). Addressee: security-reviewer, api-consistency-reviewer.

## Verdict stability

- Total clusters: 42 (sub-claim rows counted).
- All reporting replicates agreed: 35.
- Disagreed: 7 —
  - Claim 5b: r1=Verified (compound) · r2=Verified (compound) · r3=Incorrect
  - Claim 10: r1=Verified · r2=Mostly accurate · r3=Mostly accurate
  - Claim 29: r1=Verified · r2=— · r3=Mostly accurate
  - Claim 30: r1=Verified · r2=Verified · r3=Mostly accurate
  - Claim 34: r1=Verified · r2=Verified (compound) · r3=Incorrect
  - Claim 38: r1=Incorrect · r2=Incorrect · r3=Mostly accurate
  - Claim 40: r1=Incorrect (compound) · r2=Incorrect (compound) · r3=Verified
- Agreement rate: 35/42 = 83%. The two single-replicate Incorrects (5b, 34) are one mechanism found only by r3, which probed colon-outside markup.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report in the code-fact-check schema saved at the path below, with `**Commit:** 0ae7d801` at the top, every claim tagged with a Legibility-target, and a Goal-Alignment Note at the end.
- Answered: yes (merged from three replicates, each answered yes).
- Out of scope: U1c (constraints line, --status), U2's use of POLICY/NEVER, the lib's own claims (U1a), settled override-log rows.
- Escalate: E1–E3 above.
- Decisions I made: Claim 40 kept Verified despite the compound Incorrects (see its merge note); r1's Claims 1 and 2 merged into Claim 1.

---

## Submitted Claims

## Claim 42: "Policy and slots lines print no repo text besides line numbers; the never line prints the value only after every entry passed globform (NAMECHARS plus `*` `?`)."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (the trust-boundary row for `--settings` output: what repo-controlled bytes can reach stdout)
**Location:** `scripts/build-loop.sh:113-185`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every assignment to POLICY_LINE, SLOTS_LINE and NEVER_LINE in read_settings (`:135-185`), including `many()`, the FILE_WHY strings set by main_file (`:113-129`) and the lib's `oddwhy`, on the raw pre-scrub output; does not establish anything about POLICY/NEVER as later modes will consume them (U1c/U2), does not cover stderr text from git or awk failures, and does not claim the printed globs are safe for a consumer that expands them with a shell (the line holds literal `*` and `?`).

Policy and slots lines. Every value that is not a fixed string is a line number or a regex capture of a fixed alternative:

```bash
# scripts/build-loop.sh:177-183
        POLICY_LINE="policy review unset: line ${first[policy]} reads self-merge, but the Self-merge never: line is malformed, so self-merge is off"
      else POLICY="$v"; POLICY_LINE="policy $v set: line ${first[policy]} $where"; fi
    else POLICY_LINE="policy review unset: line ${first[policy]} is not exactly \"Build-loop policy: self-merge\" or \"Build-loop policy: review\""; fi
    if [[ -z "${cnt[slots]-}" ]]; then SLOTS_LINE='slots 3 default: no line starts "Build-loop slots:"'
    elif [[ "${cnt[slots]}" -gt 1 ]]; then SLOTS_LINE="slots 3 default: $(many 'Build-loop slots:' slots)"
    elif [[ "${text[slots]}" =~ ^Build-loop\ slots:\ ([123456789])$ ]]; then SLOTS_LINE="slots ${BASH_REMATCH[1]} set: line ${first[slots]} $where"
    else SLOTS_LINE="slots 3 default: line ${first[slots]} is not exactly \"Build-loop slots: N\" with N from 1 to 9"; fi
```
(excerpt starts :177 inside the policy branch begun at `:172`; enclosing read_settings() runs `:135-185` — read)

`$v` on the policy line is `BASH_REMATCH[1]` of `^Build-loop\ policy:\ (self-merge|review)$` (`:174-175`), so only those two words; `first[...]`/`second[...]` come from awk's `NR` (`l1[k] = NR` and `l2[k] = NR`, SETTINGS_AWK `:111`); `many()` prints only those two numbers and its fixed key argument (`:150`). `$where` is `"of $f on the default branch"` with the constant `f=docs/dev-cycle.md` (`:136-138`). The key `k` read back at `:147` is one of the three literals awk assigns (`k = "policy"`, `"slots"`, `"never"`, SETTINGS_AWK `:108-110`).

When the file is not read, the three lines carry FILE_WHY:

```bash
# scripts/build-loop.sh:117-128
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    notdir\ *) FILE_WHY="${e#notdir } is not a directory on the default branch"; return 1 ;;
    *) FILE_WHY="$f is not a regular file on the default branch"; return 1 ;;
  esac
  FILE_OUT="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk "$FENCE_AWK$2")"
  case "$FILE_OUT" in
    odd\ *) read -r _ n why <<<"$FILE_OUT"; FILE_WHY="line $n of $f $(oddwhy "$why"), so the file is not read"; return 1 ;;
    unbalanced\ *) FILE_WHY="the code fence opened at line ${FILE_OUT#unbalanced } of $f is never closed, so the file is not read"; return 1 ;;
  esac
```
(excerpt ends :128; enclosing main_file() continues to :129 — read)

The `notdir` PART is a prefix of the script's own constant path (main_entry builds `want` from `$1` only: `while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; ...` at `scripts/lib/dev-cycle-read.sh:260`), so it can only be `docs`. `n` is awk's `NR`/`fline`, and `why` is one of FENCE_AWK's fixed `refuse()` arguments, mapped to fixed prose by `oddwhy` (`scripts/lib/dev-cycle-read.sh:231-241`). SETTINGS_AWK's body prints nothing; its END prints only `"odd " odd " " oddwhy`, `"unbalanced " fline`, or the per-key records (`:113-117`), so no repo line reaches FILE_OUT's `odd`/`unbalanced` forms.

Never line. NEVER_LINE carries `$v` only at `:170`, which is reached only when `why` stayed empty, i.e. the line passed the exact-prefix, no-tab/VT/FF/CR and single-space checks (`:157`) and every `${g%/}` passed globform and the duplicate check (`:161-167`). globform's first test is `[[ "$1" =~ ^[*?$NAMECHARS]+$ && "$1" != /* && "$1" != -* ]] || return 1` (`:124`), with `NAMECHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-'` (`scripts/lib/dev-cycle-read.sh:139`). The only bytes not checked by globform are a stripped trailing `/` (itself a NAMECHARS byte) and the single separating spaces, so the printed value is NAMECHARS, `*`, `?` and space only.

Executed (probe-out.txt, probe2-out.txt): `Build-loop policy: self-merge EVIL\033[31m$(id)` and `Build-loop slots: 4 EVIL` printed `policy review unset: line 1 is not exactly ...` and `slots 3 default: line 2 is not exactly ...`; duplicate hostile keys printed only `(lines 1 and 2)` / `(lines 3 and 4)`; `Self-merge never: a/ $(touch PWNED) b`, `a/ EVIL\033[2J`, `a/ caf\xc3\xa9 \xe2\x80\xae (U+202E)`, `a @`, `a //` and a NBSP separator all printed `never malformed: line 2 lists entry N, which is not an allowed glob form` (or the single-spaces reason) with no entry text; no `PWNED` file was created. HTML, refdef, unbalanced-fence (`` ```EVIL8 ``) and NUL files printed only the fixed oddwhy reasons with line numbers; a `docs` symlink to `EVIL$(id)` printed `docs is not a directory on the default branch`. No raw output contained ESC, VT, FF, CR or TAB. Accepted globs printed verbatim: `never * ?/ **/x .github/ set: ...`. The associative-array subscripts `seen[*]` behaved as a literal key: `* a` and `a b *` were accepted, `* *` and `* a *` were refused as `lists entry N twice`.

Residue noted, not a claim failure: main_entry's `error` result (ls-tree failed) falls into main_file's `*)` arm and is reported as `docs/dev-cycle.md is not a regular file on the default branch` (`:122`), a mislabel of a fixed string, not repo text, and it still turns self-merge off (`never malformed`, `:143`).

**Evidence:** `scripts/build-loop.sh:113-129`, `scripts/build-loop.sh:101-117`, `scripts/build-loop.sh:122-129`, `scripts/build-loop.sh:135-185`, `scripts/lib/dev-cycle-read.sh:139`, `scripts/lib/dev-cycle-read.sh:231-241`, `scripts/lib/dev-cycle-read.sh:256-267`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/submitted/probe-out.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/submitted/probe2-out.txt`

---

## Claim 43a: "A tab, VT [or] FF ... in the never value makes the line malformed and turns self-merge off (R1/A1)."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (R1/A1 closure: blanks other than a single space in `Self-merge never:`)
**Location:** `scripts/build-loop.sh:157`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers TAB, VT and FF anywhere in the value (interior, trailing, and TAB leading/mixed per the suite's T45 cases), each making NEVER_LINE `never malformed` and the policy line `policy review unset ... so self-merge is off`; does not establish behavior for other Unicode blanks beyond NBSP (those fail globform instead, as one probe showed for NBSP) and does not cover CR (Claim 43b).

```bash
# scripts/build-loop.sh:155-158
      t="${text[never]}"; v="${t#Self-merge never: }"; why=""
      # Single spaces only: a tab or other blank would split differently in a later reader.
      if [[ "$t" != "Self-merge never: "* || "$v" == *[$'\t\v\f\r']* || ! "$v" =~ ^[^\ ]+(\ [^\ ]+)*$ ]]; then
        why='is not exactly "Self-merge never: GLOB ..." with single spaces'
```
(excerpt ends :158; enclosing read_settings() continues to :185 — read)

A non-empty `why` sets `never_ok=""` (`:169`), and `never_ok` empty turns a `self-merge` policy into `policy review unset` (`:176-177`). Executed (probe-out.txt): `a\tb`, `a\vb`, `a\v`, `a\fb`, `a\f` each printed `never malformed: line 2 is not exactly "Self-merge never: GLOB ..." with single spaces` and `policy review unset: line 1 reads self-merge, but the Self-merge never: line is malformed, so self-merge is off`.

**Evidence:** `scripts/build-loop.sh:155-158`, `scripts/build-loop.sh:169-177`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/submitted/probe-out.txt` (cases c2-tab, c2-vt, c2-vt-trail, c2-ff, c2-ff-trail)

---

## Claim 43b: "A ... CR in the never value makes the line malformed and turns self-merge off (R1/A1)."

**Submitted by:** security-reviewer
**Legibility-target:** security-reviewer (R1/A1 closure; whether `:157`'s `\r` test is a live guard)
**Location:** `scripts/build-loop.sh:157`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a single trailing CR (accepted: line set), a CR inside the line or two trailing CRs (file refused by FENCE_AWK, so self-merge off by the not-read path); does not establish any security impact, which is nil: the case where the claim fails is a CRLF line ending that is dropped before any check, leaving no CR in the value.

A single trailing CR never reaches `:157`: SETTINGS_AWK drops it before the line is recorded, and the stored text has no CR.

```awk
# scripts/build-loop.sh:101-102 (SETTINGS_AWK)
{ sub(/\r$/, "") }
fence($0) { next }
```
(excerpt ends :102; enclosing SETTINGS_AWK string continues to :117 — read)

Any other CR is refused by FENCE_AWK's `if (index(l, "\r")) { refuse("cr"); return 1 }` (`scripts/lib/dev-cycle-read.sh:215`), so the whole file is not read and the never line is `never malformed: line N of docs/dev-cycle.md holds a carriage return that does not end it, so the file is not read` (main_file `:126`, read_settings `:143`). Therefore the `\r` member of `[$'\t\v\f\r']` at `:157` is unreachable, and "a CR makes the line malformed" is false for the one CR that survives: executed (probe-out.txt, case c2-cr-trail), `Self-merge never: a\r` printed `never a set: line 2 of docs/dev-cycle.md on the default branch` with `policy self-merge set`. Cases c2-cr-mid (`a\rb`) and c2-crcr-trail (`a\r\r`) printed the file-refused reason on all three lines, with policy `review unset`: self-merge off, but by the file-not-read mechanism, not by `:157`.

A precise version: "A tab, VT or FF in the never value makes the line malformed; a CR inside the line makes the whole file unread (FENCE_AWK), which also turns self-merge off; one trailing CR is dropped."

**Evidence:** `scripts/build-loop.sh:101-102`, `scripts/build-loop.sh:126`, `scripts/build-loop.sh:141-143`, `scripts/build-loop.sh:157`, `scripts/lib/dev-cycle-read.sh:213-216`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1b-i2/submitted/probe-out.txt` (cases c2-cr-mid, c2-cr-trail, c2-crcr-trail)

---

## Claim 44a: "read_settings is called once per --settings run"

**Submitted by:** performance-reviewer
**Legibility-target:** performance-reviewer (per-run cost: one ls-tree, one cat-file and one awk pass over docs/dev-cycle.md)
**Location:** `scripts/build-loop.sh:187-191` (submitted as `:194-198`, which is past the file's last line, `:192`)
**Type:** Architectural / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call count in build-loop.sh at 0ae7d801 (one call, in the only mode); does not establish the cost of the re-exec under scrub_reexec (`:89`), which runs the whole script body twice as processes but read_settings only in the child, and does not cover future modes.

```bash
# scripts/build-loop.sh:187-192
case "$MODE" in
  settings)
    read_settings
    printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE"
    ;;
esac
```

A repo-wide grep finds one definition and one call (paraphrased — no quote available because the claim covers absence of other call sites: `grep -rn read_settings` over `*.sh`, `*.bats`, `*.bash` returns `scripts/build-loop.sh:135` (definition) and `:189` (call), plus the unrelated `read_settings_rules` in `hooks/auto-approve-allowed-commands.sh`). The outer process returns from `scrub_reexec` only in the child (`scripts/lib/dev-cycle-read.sh:77-80`: the parent `exit`s after the pipeline), so the call runs once per invocation.

**Evidence:** `scripts/build-loop.sh:89`, `scripts/build-loop.sh:135`, `scripts/build-loop.sh:187-192`, `scripts/lib/dev-cycle-read.sh:76-81`

---

## Claim 44b: "U1c/U2 will call it once per process as well."

**Submitted by:** performance-reviewer
**Legibility-target:** performance-reviewer (whether the per-run cost bound carries to --status / --check)
**Location:** `scripts/build-loop.sh:130-133` (the comment naming the future consumers); U1c and U2 code does not exist yet
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the code and plan at 0ae7d801 say about future callers; does not establish how U1c (`--status BRIEF…`) or U2 (`--check`/`--merge`) will call read_settings, and does not establish that a second in-process call would be correct (see below).

The code only says the globals are meant for later modes: `# Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (the globs, or empty) and / NEVER_LINE from main's commit. POLICY and NEVER are / for the modes that judge a brief (--status, then the gate).` (`scripts/build-loop.sh:130-132`). The plan specifies `--status BRIEF…` (several briefs in one process) and `--check BRIEF… [--expect SHA]` (`docs/working/plan-build-loop-handoff.md:205`, `:214`), which makes once-per-process the natural design, but nothing written fixes it. Needed to verify: U1c's and U2's code.

Relevant to the claim's premise: read_settings does not reset POLICY or NEVER on entry. They are initialized once at file scope, `POLICY=review; POLICY_LINE=""; SLOTS_LINE=""; NEVER=""; NEVER_LINE=""` (`scripts/build-loop.sh:133`), and set only on success, `else NEVER="$v"; ...` (`:170`) and `else POLICY="$v"; ...` (`:178`). So a second call in one process whose read fails or finds a malformed line would leave the first call's POLICY and NEVER in place while the *_LINE strings report review/malformed. Once-per-process is therefore a correctness precondition for U1c/U2, not only a performance property.

**Evidence:** `scripts/build-loop.sh:130-133`, `scripts/build-loop.sh:135-185`, `docs/working/plan-build-loop-handoff.md:203-215`

---

