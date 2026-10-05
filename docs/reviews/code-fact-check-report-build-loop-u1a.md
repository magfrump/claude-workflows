Commit: c8435580

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1a (claude-workflows, branch feat/build-loop-u1a)
**Scope:** `git diff main...feat/build-loop-u1a` (d6426e3e test, c8435580 feat): scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats, plus both commit messages
**Checked:** 2026-10-05
**Commit:** c8435580
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 20
**Summary:** 12 verified, 4 mostly accurate, 1 stale, 3 incorrect, 0 unverifiable

Execution provenance (all probes): scratch dir `S=/home/node/.claude/jobs/989f3e5a/tmp/review-u1a/fact-check`, `LC_ALL=C.UTF-8`, awk is `/usr/bin/mawk`, git 2.39.5, bash 5.2.15. Each probe builds its own throwaway repo under `$S` with `mktemp -d "$S/repo*.XXXXXX"` and aborts if creation fails.

| Run | Command | cwd | Exit | Time (UTC) | Output |
|---|---|---|---|---|---|
| P1 (main_entry) | `./probe1.sh "$S"` | `$S` | 0 | 2026-10-05T10:43:36Z | `$S/logs/probe1.log` |
| P2 (brief_fields, check_brief old vs new) | `./probe2.sh "$S"` | `$S` | 0 | 2026-10-05T10:44:00Z | `$S/logs/probe2.log` |
| P3 (check_answer) | `./probe3.sh "$S"` | `$S` | 0 | 2026-10-05T10:44:28Z | `$S/logs/probe3.log` |
| H (help) | `bash scripts/dev-cycle.sh --help` | worktree root | 0 | 2026-10-05T10:44:35Z | `$S/logs/help.log` |
| B (suite) | `bats test/scripts/dev-cycle.bats` | worktree root | 0 | 2026-10-05T10:44:35Z | `$S/logs/bats.log` |

P2 compares against main's lib, saved as `$S/lib-main.sh` (`git show main:scripts/lib/dev-cycle-read.sh`).

Hallucination-pattern log: read `docs/reviews/hallucination-patterns.md`. No claim here matches a logged pattern. Claim 4 names a file that does not exist at this commit, but the file exists on `feat/build-loop-u1b` (3a22c826). That makes it a premature forward reference, not a fabrication, so it is not logged (and this pass's rules allow writing only this report).

Settled-decision coverage (override-log rows deferred to U1):
- Row 206 (check_answer reads the working tree, F28): **discharged**. check_answer reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:538`). See Claims 1a and 12.
- Row 216 (positive-line capture plus main_by_name): **discharged for the lib's part**. check_answer gates on `main_by_name` (`:529`), and the header tells callers to treat any non-positive line as a refusal (`:26`). Positive-line-only capture by `--approved` belongs to the caller (U1b/U3) and is not in this diff.
- Row 217 (SKIPPED side effect): **discharged**. check_answer and main_entry call neither `skipped` nor `need_root`, and SKIPPED stays 0 even with a symlinked archive on main (P3). See Claim 12.
- Row 197 (header note "with" build-loop-read.bats): the note landed before the suite did. See Claim 4.

---

## Claim 1a: "read from docs/working/questions.md or its archive on the default branch's commit"

**Location:** `scripts/dev-cycle.sh:56-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers that --check-answer reads both files from MAIN_SHA's blobs (the working tree is never read; a branch-only commit is not seen; the archive is read when questions.md is absent on main). Does not establish anything about the answer grammar (ANSWER_AWK, unchanged here).

The lib reads the blob from main's commit: `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")"` (`scripts/lib/dev-cycle-read.sh:538`). In run B, the test at `test/scripts/dev-cycle.bats:1118` passes. It asserts `open Q-1` for an answer present only in the working tree and for one committed only on `side`, and `drop Q-1` after the merge with the working-tree file removed. In P3, a repo whose main has only `questions-archive.md` printed `archive only: drop Q-1` (`$S/logs/probe3.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:526-551`, `test/scripts/dev-cycle.bats:1118-1135`, `$S/logs/probe3.log`, `$S/logs/bats.log`

---

## Claim 1b: "(an answer only in the working tree reads open until it is committed there)"

**Location:** `scripts/dev-cycle.sh:58-59`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Verification mode:** executed
**Scope:** Covers an entry that exists on main unanswered while its answer exists only in the working tree. Does not hold for an entry that is itself absent from main: that case reads as a skip, not `open`.

The claim holds when main carries the entry as OPEN (bats `:1118`, first assertion `[ "$output" = "open Q-1" ]`). When the whole entry exists only in the working tree, check_answer finds nothing on main and prints the skip line: `else echo "skip $a: no such entry in docs/working/questions.md or questions-archive.md on the default branch"; fi` (`scripts/lib/dev-cycle-read.sh:549-550`). In P3, `unknown id: skip Q-9: no such entry … on the default branch`. A precise version would read: "an answer only in the working tree reads open (or, for an entry not yet on the default branch at all, skip … no such entry) until it is committed there". Both outcomes fail closed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:530-550`, `$S/logs/probe3.log`

---

## Claim 2: "--check-brief, --check-branch and --check-answer need a default branch found by name (origin/HEAD, main or master): they read its commit" / Exit "1 … no default branch (for the digest, --check-brief, --check-branch and --check-answer)" / "a questions file that is not a regular file under plain directories on the default branch"

**Location:** `scripts/dev-cycle.sh:68-72`, `scripts/dev-cycle.sh:78-80`, `scripts/dev-cycle.sh:187-192`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers the main_by_name gate at :191 (exit 1 with a stderr line and no stdout) and the skip for a non-regular questions file or a non-tree directory above it on main. Does not establish behaviour when origin/HEAD names a branch a loop created (override row about resolve_main candidates, settled).

The gate is `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then` followed by `echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1` (`scripts/dev-cycle.sh:191-192`). It runs after `resolve_main || [[ -n "$CHECK" ]] || …` (`:186`), so a check mode with no branch at all also reaches the gate. In run B, bats `:1153` (main deleted, on `trunk`) asserts `[ "$status" -eq 1 ] && [ -z "$output" ]` and that stderr has "needs a default branch", and it passes. Bats `:1137` asserts both the `not a regular file on the default branch` skip and the `docs/working is not a directory on the default branch` skip, and passes. P3 confirms that a symlinked `questions-archive.md` on main gives `… is not a regular file on the default branch, so no entry in it is read`.

**Evidence:** `scripts/dev-cycle.sh:186-206`, `scripts/lib/dev-cycle-read.sh:529-537`, `test/scripts/dev-cycle.bats:1137-1158`, `$S/logs/bats.log`, `$S/logs/probe3.log`

---

## Claim 3: `sed -n '2,80p'` prints the header comment block

**Location:** `scripts/dev-cycle.sh:110`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers that lines 2-80 are exactly the comment block (line 1 is the shebang, line 81 is blank, line 82 is `set -euo pipefail`). Does not establish that the range stays right after later header edits.

`sed -n '78,82p' scripts/dev-cycle.sh` shows `:80` as `# default branch (for the digest, --check-brief, --check-branch and --check-answer); …`, with `:81` empty and `:82` `set -euo pipefail`. In run H the help output starts with `Gather the mechanical signals for one dev cycle into a markdown digest.` and ends with that Exit line (`$S/logs/help.log`). The diff added three header lines (`:56-59` +2, `:68-72` +1), which moved the end from 77 to 80.

**Evidence:** `scripts/dev-cycle.sh:1-82`, `scripts/dev-cycle.sh:110`, `$S/logs/help.log`

---

## Claim 4: "A change here runs under both callers' suites (test/scripts/dev-cycle.bats and build-loop-read.bats)."

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Reference / Architectural
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author
**Verification mode:** static
**Scope:** Covers whether a second suite and a second caller exist at c8435580. Does not judge whether U1b (feat/build-loop-u1b, 3a22c826) will make the sentence true when it lands.

At this commit there is one caller and one suite. `ls test/scripts/build-loop-read.bats` reports `No such file or directory`, and no `scripts/build-loop.sh` exists either. The lib's own first lines still say the second caller is planned: `kept apart so the planned scripts/build-loop.sh can share it` (`scripts/lib/dev-cycle-read.sh:2-3`). The file is added by `3a22c826 test(build-loop): --settings from main's commit (U1b; …)`, which is only on `feat/build-loop-u1b`. The name also has no directory (`build-loop-read.bats` rather than `test/scripts/build-loop-read.bats`). Override row 197 deferred this note to arrive "with" that suite. As written, a reader at U1a's merge looks for a second suite that does not exist. Either hold the sentence for U1b or write it as planned ("…and, from U1b, test/scripts/build-loop-read.bats").

**Evidence:** `scripts/lib/dev-cycle-read.sh:1-12`, `docs/reviews/override-log.md:197`, git object 3a22c826 (branch feat/build-loop-u1b)

---

## Claim 5: "inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root) …" (check_answer removed from the list)

**Location:** `scripts/lib/dev-cycle-read.sh:14-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers that check_answer, main_entry and brief_fields neither call need_root nor depend on ROOT_REAL. Does not establish need_root's own correctness (unchanged).

check_answer's body (`scripts/lib/dev-cycle-read.sh:526-551`) has no `need_root`, `skipped`, `SKIPPED` or `ROOT_REAL`. In P3, a grep over `declare -f check_answer main_entry` printed `no need_root in check_answer/main_entry` and `no skipped/SKIPPED/ROOT_REAL`. brief_fields (`:274-293`) has neither either. Bats `:1160` runs check_answer with ROOT_REAL unset and from `docs/` and gets `keep Q-1`. check_brief still calls `need_root` (`:304`), and imported_names does too (`:412`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:274-304`, `scripts/lib/dev-cycle-read.sh:526-551`, `$S/logs/probe3.log`, `test/scripts/dev-cycle.bats:1160-1170`

---

## Claim 6: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:20-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers the main_by_name guard in each of the three functions. Does not establish that MAIN_SHA belongs to the current repository (settled won't-fix row on main_by_name).

Each function has the guard: check_brief `if ! main_by_name; then echo "skip …"` (`:305`), check_branch the same (`:351`), and check_answer `if ! main_by_name; then echo "skip $a: no default branch found by name …"; return; fi` (`:529`). check_answer runs its ID-form check first (`:528`), which is also a skip. P3, before resolve_main, printed `skip Q-1: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run`. Bats `:1160` asserts the same.

**Evidence:** `scripts/lib/dev-cycle-read.sh:242`, `:305`, `:351`, `:528-529`, `$S/logs/probe3.log`

---

## Claim 7: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree, which the cycle writes); imported_names reads the working tree at ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:28-31`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers that the file content each function reads comes from MAIN_SHA objects, and that check_brief's only working-tree access is the `blocker` plainness test. Does not establish that main_entry/brief_fields refuse to run on a fallback MAIN_SHA (they read whatever MAIN_SHA holds; the caller checks main_by_name). check_branch also reads `refs/heads/<name>`, which is a ref, not main's commit.

main_entry reads `git ls-tree -t --full-tree "$MAIN_SHA" …` (`:255`), and brief_fields and check_answer read `git cat-file blob "$MAIN_SHA:…"` (`:279`, `:538`). check_brief's working-tree access is `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"` (`:310`). In P2, a working-tree edit to a committed brief did not change check_brief's answer. Bats `:1172` also overwrites the working-tree copy with `Status: dropped` and still gets `status=[Status: open]`. check_branch uses `git show-ref --verify --hash "refs/heads/$a"` (`:357`). That predates this diff, and the parenthetical reading "never the working tree" still holds for it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:251-261`, `:274-339`, `:349-362`, `:526-551`, `test/scripts/dev-cycle.bats:1172-1205`

---

## Claim 8: "The default branch, set by resolve_main (below). check_brief and check_branch read its commit, so they answer only when it was found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:238-240`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author
**Verification mode:** static
**Scope:** Covers the list of readers named in this block comment. Does not concern main_by_name's definition on `:242`, which is correct.

The comment above `MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""` (`:241`) still names only two readers. Since this diff, check_answer also reads main's commit and gates on it (`if ! main_by_name; then echo "skip $a: …"`, `:529`), and the new main_entry and brief_fields read MAIN_SHA as well (`:255`, `:279`). The header (`:20-22`, `:28-31`) was updated, but this comment was not. It should read "check_brief, check_branch and check_answer read its commit (and main_entry/brief_fields, which their callers gate) …".

**Evidence:** `scripts/lib/dev-cycle-read.sh:238-242`, `:255`, `:279`, `:529`

---

## Claim 9: main_entry comment ("prints blob (100644 or 100755), absent, notfile, or notdir PART … One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory). The caller has checked main_by_name and the path's form (pathform, so ls-tree prints it unquoted).")

**Location:** `scripts/lib/dev-cycle-read.sh:243-250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers every outcome class (regular and exec blob, absent leaf, absent mid-path component, symlink leaf, tree leaf, gitlink leaf, symlinked/blob/gitlink directory above), the -t and --full-tree effects, and both callers' preconditions. Does not establish behaviour when a caller skips the precondition. With MAIN_SHA empty or not a commit, main_entry prints `absent` and returns 0, with git's error on stderr only, and check_brief would then print `ok … new` (fails open). The output also holds every entry inside each named directory, not only the path and its ancestors.

From P1 (`$S/logs/probe1.log`): `a/b/f.md blob`, `top.md blob` (100755), `nope.md absent`, `a/x/y/z.md absent` (missing mid-path), `lnk/f.md notdir lnk` (symlinked directory), `a/b/sl.md notfile` (120000), `a/dir notfile` (tree leaf), `sm notfile` (160000), `sm/x notdir sm`, `top.md/x notdir top.md`. Run from `a/b`, it still gave `blob` (--full-tree). Without `-t` the output had no `040000 tree … a` or `… a/b` lines, and with `-t` both appeared, so `-t` is what supplies the ancestors. A path with no slash leaves `want=()` empty and only `"$1"` is passed (`:254-255`; `top.md` case). Both callers meet the precondition. check_brief runs `pathform "$a"` (`:306`) and `main_by_name` (`:305`) before `e="$(main_entry "$a")"` (`:313`). check_answer gates `main_by_name` (`:529`) and passes only the literals `docs/working/questions.md docs/working/questions-archive.md` (`:530`), which pass pathform by construction (paraphrased — no quote available because the claim is that the fixed literals contain only NAMECHARS and no `.git`-prefixed component, an absence). The fail-open residue: P1 with `MAIN_SHA=""` printed `[fatal: Not a valid object name` / `absent] status=0`, because inside `$(...)` errexit is not inherited, so the failed `out="$(git ls-tree …)"` at `:255` does not stop the function.

**Evidence:** `scripts/lib/dev-cycle-read.sh:243-261`, `:305-319`, `:529-537`, `$S/logs/probe1.log`

---

## Claim 10a: brief_fields reads each key's first unfenced line "whole, after one trailing CR is dropped"

**Location:** `scripts/lib/dev-cycle-read.sh:264-265`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author
**Verification mode:** executed
**Scope:** Covers the value BRIEF[key] receives for a line that contains a NUL byte: NUL bytes are dropped, so the value is not the whole line. Lines without NUL (tabs, a single trailing CR) are stored whole, and that part is covered by 10b. Does not establish whether any real brief holds a NUL.

awk prints `kv[i]` (`k "\t" $0`, `:283`, `:285`), and the result is captured with `out="$(git cat-file blob … | env LC_ALL=C awk …)"` (`:279`). Bash command substitution removes NUL bytes. P2's brief `Status: op\000en\nBranch: feat/a\000;b\n` gave `nul rc=0 status=[Status:\ open] branch=[Branch:\ feat/a\;b]` and printed `dev-cycle-read.sh: line 285: warning: command substitution: ignored null byte in input` on stderr (`$S/logs/probe2.log`). The value is the line with its NULs removed, not the line whole. Under main's code, the old reader matched the exact regex inside awk (on the raw bytes) and printed only a matching line, so a NUL never reached bash as a value. See Claim 11a for the consequence on Status.

**Evidence:** `scripts/lib/dev-cycle-read.sh:274-293`, `$S/lib-main.sh` (old check_brief awk), `$S/logs/probe2.log`

---

## Claim 10b: brief_fields' remaining contract ("first line outside a fence … that starts Status:/Branch:/…; a key with no such line stays unset; empties BRIEF_ODD; a file FENCE_AWK refuses sets no key and returns 1, with BRIEF_ODD 'odd N WHY' or 'unbalanced N'"; "The whole blob is read (no early exit: SIGPIPE under pipefail)")

**Location:** `scripts/lib/dev-cycle-read.sh:262-277`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers first-copy-per-key, fenced-line skipping, case-sensitive keys at column 0, unset absent keys, both refusal forms, BRIEF_ODD being emptied, return 0 on success when called at top level under `set -e`, and that tabs in values are kept. Does not establish behaviour when the precondition (a blob on main) fails. A bad path under `set -e` at top level exits the caller through the failed assignment at `:279`, while inside `if !` the function returns 0 with BRIEF empty.

Bats `:1172` (run B, passes) asserts the six first copies (a fenced `Status: done`/`Branch: fenced` is skipped, a later `Branch: second`/`Status: done` is ignored, `Status: open\r` reads `Status: open`), `refused [odd 2 fence] 0`, `refused [unbalanced 2] 0`, and, after a refusal, `status=[Status: open] branch=[unset] odd=[]` (BRIEF_ODD emptied, absent key unset). P2 adds: `tab rc=0 status=[$'Status: open\tx'] branch=[$'Branch: feat/a\tb']` (later tabs kept, because `${l%%$'\t'*}` / `${l#*$'\t'}` split at the first tab, which is the separator), `lower` → `Status: done` (`status:` is not matched; `match($0, /^(Status|Branch|Policy|Paths|Asked|Dispatched):/)`, `:282`, is case-sensitive like the old `/^Status:/`), `none rc=0 n=0 odd=[]`, and `top-level set -e call survived`. The loop's last body command is a `case` whose arms are an assignment or no command, so the `while` returns 0 (`:286-292`). The no-early-exit claim: neither FENCE_AWK (`:184-227`) nor the brief_fields program (`:280-285`) contains an `exit` statement (paraphrased — no quote available because the claim is the absence of an `exit` statement in both awk programs).

**Evidence:** `scripts/lib/dev-cycle-read.sh:184-227`, `:262-293`, `test/scripts/dev-cycle.bats:1172-1205`, `$S/logs/probe2.log`, `$S/logs/bats.log`

---

## Claim 11a: check_brief's Status line "must be exactly 'Status: open|done|dropped'" (the Status check is unchanged by moving to brief_fields)

**Location:** `scripts/lib/dev-cycle-read.sh:295-296`, `scripts/lib/dev-cycle-read.sh:327-330`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author
**Verification mode:** executed
**Scope:** Covers the old and new check_brief compared over CR, CR+CR, leading space, lower case, a bad first line, a tab, no Status line, and a NUL byte. All of them agree except the NUL case, which the new code accepts and main's code refused. Does not establish a fix, or whether any downstream consumer of BRIEF[branch]/[paths] (U1b) re-validates its values.

The new check is `st="${BRIEF[status]-}"` then `if [[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]` (`:327-328`), applied to a value whose NUL bytes bash has already dropped (Claim 10a). From P2: main's lib gave `nul: skip …: its first Status: line is not exactly Status: open, done or …`, and the branch's lib gave `nul: … ignored null byte in input` / `ok docs/working/briefs/2026-01-01-nul.md open`. So a first Status line `Status: op<NUL>en` is not exactly `Status: open`, yet it is accepted. Every other case matched between old and new: `cr` → open, `crcr` → refused (line 1 carriage return), `lower` → done, `sp` → done, `tab`/`none`/`bad` → refused (`$S/logs/probe2.log`). The CR handling is equivalent because both run `{ sub(/\r$/, "") }` before `fence($0)`. A fix would refuse NUL in brief_fields, as the old in-awk match effectively did.

**Evidence:** `scripts/lib/dev-cycle-read.sh:279-293`, `:320-330`, `$S/lib-main.sh` (old check_brief), `$S/logs/probe2.log`

---

## Claim 11b: "…neither is one stored as anything but a regular file under plain directories (main_entry). 'new' when the default branch has no file at that path"

**Location:** `scripts/lib/dev-cycle-read.sh:296-301`, `scripts/lib/dev-cycle-read.sh:311-319`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers the absent/blob/notdir/notfile dispatch in check_brief. Does not cover the fail-open path when main_entry's ls-tree errors (Claim 9 residue).

`case "$e" in absent) echo "ok $a new"; return ;; blob) ;; notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch"; return ;; *) echo "skip $a: not a regular file on the default branch"; return ;; esac` (`:314-319`). P2 used a repo whose main stores `docs/working/briefs` as a symlink while the working tree has a plain directory. The new code printed `skip docs/working/briefs/2026-01-01-ok.md: docs/working/briefs is not a directory on the default branch`. Claim 9's probes cover the notfile cases.

**Evidence:** `scripts/lib/dev-cycle-read.sh:302-319`, `$S/logs/probe2.log`, `$S/logs/probe1.log`

---

## Claim 12: check_answer comment ("from docs/working/questions.md and questions-archive.md on the default branch's commit, never the working tree … A file stored as anything but a regular file under plain directories there is not read (main_entry). It reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED.")

**Location:** `scripts/lib/dev-cycle-read.sh:520-525`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers the main-only reads, the notdir/notfile refusals for either file, absent questions.md falling through to the archive, no ROOT_REAL, and SKIPPED staying unchanged with a symlinked file on main. Does not cover ANSWER_AWK's grammar (unchanged) or the caller's positive-line capture (U1b/U3).

The function reads only through `main_entry` and `git cat-file blob "$MAIN_SHA:$f"` (`:531`, `:538`). `absent) continue ;;` (`:533`) passes an absent questions.md over to the archive. P3 shows `archive only: drop Q-1`. With questions.md answered and the archive a symlink on main it prints `skip Q-2: docs/working/questions-archive.md is not a regular file on the default branch, so no entry in it is read`, and then `SKIPPED=0`. Bats `:1160` runs with ROOT_REAL unset and from `docs/` and gets `keep Q-1` and `skipped=0`. Note that this fixture has no non-plain input, so the old code would also leave SKIPPED at 0 there. P3 is the probe that actually exercises the side effect.

**Evidence:** `scripts/lib/dev-cycle-read.sh:520-551`, `$S/logs/probe3.log`, `test/scripts/dev-cycle.bats:1160-1170`

---

## Claim 13: "both from the default branch's commit (an answer recorded only in the working tree reads `open` until it lands)"

**Location:** `skills/dev-cycle/SKILL.md:292-294`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Verification mode:** executed
**Scope:** Covers the same split as Claim 1b. Does not cover the rest of In flight step 2.

The claim is right when main has the entry unanswered. An entry that exists only in the working tree reads `skip Q-N: no such entry in docs/working/questions.md or questions-archive.md on the default branch` (`scripts/lib/dev-cycle-read.sh:550`; P3 `unknown id`), not `open`. The skill's next lines handle a skip separately: "A `skip` (the entry could not be read) goes in the record and the final message, and the ID stays off `Applied:`" (`skills/dev-cycle/SKILL.md:303-304`). The outcome fails closed in both cases. A precise version would read "…reads `open`, or `skip` when the entry itself is not on the default branch yet, until it lands".

**Evidence:** `skills/dev-cycle/SKILL.md:289-304`, `scripts/lib/dev-cycle-read.sh:549-550`, `$S/logs/probe3.log`

---

## Claim 14: c8435580 message: "check_brief also skips a brief whose directory is not a directory on main (before, ls-tree printed nothing and it read as "new")."

**Location:** commit c8435580 (message body); code at `scripts/lib/dev-cycle-read.sh:313-319`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers main's check_brief compared with the branch's on a main whose briefs/ is a symlink. Does not cover other non-tree ancestor kinds on main's version (not probed there).

In P2, main's lib (`case "$(git ls-tree "$MAIN_SHA" -- "$a" | cut -c1-6)" in '') echo "ok $a new"`) printed `OLD: ok docs/working/briefs/2026-01-01-ok.md new`, and the branch printed `NEW: skip …: docs/working/briefs is not a directory on the default branch`.

**Evidence:** `$S/lib-main.sh` (check_brief), `scripts/lib/dev-cycle-read.sh:313-319`, `$S/logs/probe2.log`

---

## Claim 15: c8435580 message Notes: "Until U4 rewrites the skill, a dev cycle run from this repo's scripts/ reads an answer it recorded only in the working tree as open and lists it in the final message; that fails closed."

**Location:** commit c8435580 (Notes)
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Verification mode:** executed
**Scope:** Covers the open-vs-skip outcome and the fail-closed conclusion. U4 is real as a planned unit (plan step 10, `docs/working/plan-build-loop-handoff.md:277`, "U4, skill and pr-prep"). Does not establish what U4 will change.

The claim is right for an entry already on main. For an entry the cycle filed and answered only in the working tree, the line is `skip … no such entry …` (P3), which the skill records and lists rather than treating as open (`skills/dev-cycle/SKILL.md:303-304`). Both outcomes fail closed, so the conclusion holds and only the outcome name is imprecise.

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-550`, `skills/dev-cycle/SKILL.md:303-304`, `docs/working/plan-build-loop-handoff.md:277`, `$S/logs/probe3.log`

---

## Claim 16: Plan-test references: d6426e3e "(U1a, T31, T34)", c8435580 "(T31)", test names "… is open (T34)" and "… check_brief agrees (T31)"; test name "check_answer reads git only: no ROOT_REAL needed, SKIPPED untouched, …"

**Location:** `test/scripts/dev-cycle.bats:1118`, `test/scripts/dev-cycle.bats:1160`, `test/scripts/dev-cycle.bats:1172`; commits d6426e3e, c8435580
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Verification mode:** static
**Scope:** Covers how much of each plan row the tests in this diff cover. Does not establish whether U1b's tests cover the rest.

T34 in the plan reads "`--check-answer` (both scripts): an answer only in the working tree → `open`; committed on main → read; committed only on another branch → `open`; the E2 fixture with the body quoted by `--marker` → option 2, and `questions.sh open` omits the ID" (`docs/working/plan-build-loop-handoff.md:330`). The test at `:1118` covers the first three parts for dev-cycle.sh only. The "both scripts" part and the E2/`--marker` parts are not in this unit (no build-loop.sh exists yet). The plan also places T34 in `test/scripts/build-loop-read.bats` (`:269`). T31 in rev 2 reads "`brief_fields` agrees with `check_brief`" (`git show 3a005378:…:186`), and its step 3 adds "a brief made from SKILL's template parses" (`:110`). The test at `:1172` covers agreement on Status, not the SKILL-template parse. In the test named "SKIPPED untouched" (`:1160`), `skipped=0` is asserted on a fixture with no non-plain input, where the old code would also have left SKIPPED at 0. The assertion is weak, though the property holds (Claim 12, P3). The names would be precise as "T34, part" and "T31, Status part".

**Evidence:** `docs/working/plan-build-loop-handoff.md:269`, `:316-330`, git `3a005378:docs/working/plan-build-loop-handoff.md:110,186`, `test/scripts/dev-cycle.bats:1118-1205`

---

## Claim 17: "Tests: `bats test/scripts/dev-cycle.bats` (64 tests, all passing at c8435580)" (shared context)

**Location:** `test/scripts/dev-cycle.bats:1`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Verification mode:** executed
**Scope:** Covers one run at HEAD c8435580 with LC_ALL=C.UTF-8. Does not establish stability across runs or locales.

Run B printed `1..64` with 64 `ok` lines and no `not ok`, exit 0 (`$S/logs/bats.log`).

**Evidence:** `$S/logs/bats.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`scripts/lib/dev-cycle-read.sh:10-11`): names a second suite, `build-loop-read.bats`, that does not exist at c8435580 (it is U1b's, on another branch). Hold the sentence for U1b or mark it planned, and give the full path.
- **Claim 10a** (`scripts/lib/dev-cycle-read.sh:264-265`): the value is not "whole". Bash command substitution at `:279` drops NUL bytes from BRIEF values, with a warning on stderr.
- **Claim 11a** (`scripts/lib/dev-cycle-read.sh:295-296,327-330`): a first Status line `Status: op<NUL>en` is now accepted as `open`, where main's check_brief refused it. This is a regression from the old in-awk exact match.

### Stale
- **Claim 8** (`scripts/lib/dev-cycle-read.sh:238-240`): still names only check_brief and check_branch as readers of main's commit that are gated by main_by_name. check_answer, main_entry and brief_fields now read it too.

### Mostly Accurate
- **Claim 1b** (`scripts/dev-cycle.sh:58-59`): an entry absent from main reads `skip … no such entry`, not `open`.
- **Claim 13** (`skills/dev-cycle/SKILL.md:292-294`): same imprecision as 1b.
- **Claim 15** (commit c8435580 Notes): same, for "reads … as open". The fail-closed conclusion holds.
- **Claim 16** (`test/scripts/dev-cycle.bats:1118,1160,1172`; d6426e3e, c8435580): the tests cover T34 and T31 only in part, and the SKIPPED assertion is vacuous on its fixture.

### Unverifiable
- None.

## Escalations

- `scripts/lib/dev-cycle-read.sh:279-292` → **security-reviewer**: brief_fields stores BRIEF values after bash has dropped NUL bytes. check_brief now accepts `Status: op\0en` (P2), and `Branch: feat/a\0;b` becomes `Branch: feat/a;b`. U1b reads BRIEF[branch]/[paths]/[policy]/[asked]. Judge whether every consumer re-validates its value, or whether brief_fields should refuse a NUL byte (awk can test for it before printing).
- `scripts/lib/dev-cycle-read.sh:255` → **security-reviewer / api-consistency-reviewer**: when `git ls-tree` fails (empty or invalid MAIN_SHA), main_entry prints `absent` and returns 0, with the error on stderr only (P1). check_brief maps absent to `ok … new`, which fails open. Both current callers gate main_by_name first, but U1b's new callers rely on the comment's precondition alone.
- `scripts/lib/dev-cycle-read.sh:255` → **performance-reviewer**: each directory pathspec makes ls-tree list that directory's children. For `docs/working/questions.md` that means every entry in `docs/` and `docs/working/`, twice per question ID. This is probably negligible; flagged for U1b's `--status` per-brief loop.
- `test/scripts/dev-cycle.bats:1160` → **test-strategy (orchestrator)**: the SKIPPED-untouched assertion would pass for the old function on this fixture. A symlinked file on main (as in P3) would make it bite.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to the output path named in your task tail, structured per your skill, with every finding carrying Severity, Location (path:line), a verbatim Evidence quote, Confidence and Legibility-target.
- Answered: all nine claim groups in the task tail are checked against callers, tests and executed probes. Lib header items are Claims 4-7. main_entry is Claim 9, brief_fields Claims 10a/10b, check_brief Claims 11a/11b/14, check_answer Claim 12, help text Claims 1-3, SKILL.md Claim 13, commits and test names Claims 14-16, and the bats run Claim 17 (64/64 pass). The settled override rows 206, 216 and 217 are discharged (coverage notes above). Severity follows the verdict scale (Incorrect > Stale > Mostly accurate). This skill's schema has no separate Severity field, so the verdict carries it.
- Out of scope: code quality, the design of U1b's consumers, ANSWER_AWK grammar (unchanged), and whether the U1b branch makes Claim 4 true.
- Escalate: the NUL-byte regression in brief_fields/check_brief (security-reviewer), main_entry failing open on a git error (security/api-consistency), and the ls-tree listing breadth (performance), as listed above.
