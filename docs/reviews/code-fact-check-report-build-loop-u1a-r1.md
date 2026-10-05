Commit: 722884c7

# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-build-loop-u1a, branch feat/build-loop-u1a)
**Scope:** `git diff main...feat/build-loop-u1a -- . ':!docs/reviews'` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats) plus the five branch commit messages (`git log main..feat/build-loop-u1a`); iteration 3, final confirming pass
**Checked:** 2026-10-05
**Total claims checked:** 40
**Summary:** 36 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution provenance (shared by every `executed` claim below). All runs: cwd under the scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i3/fc1/` (probe repos built by `git init` inside it), code materialised with `git archive <rev> scripts test skills | tar -x` into `fc1/head` (722884c7), `fc1/old-main` (main), `fc1/old-2da` (2da477b7); timestamps 2026-10-05T04:32-04:37 -07:00. Captured output:
- `fc1/logs/bats-head.txt` — `cd /workspace/.claude/wt-build-loop-u1a && LC_ALL=C.UTF-8 TMPDIR=fc1 bats test/scripts/dev-cycle.bats`, exit 1: 66/67 ok; test 21 fails only because the scratch TMPDIR path holds a `.claude` component, which git refuses in a ref name (`refusing to update ref with bad name`) — environmental, outside the diff, confirmed by the orchestrator (67/67 with TMPDIR unset).
- `fc1/logs/p1-head.txt`, `fc1/logs/p1-old2da.txt` — `bash fc1/p1.sh <lib>`: duplicate-name trees built with `git mktree`, a missing subtree object, the normal ancestor listing; exit 0.
- `fc1/logs/p2-head.txt` — `bash fc1/p2.sh <lib> <dev-cycle.sh>`: brief_fields error sources, missing blobs for each questions file and a brief, a no-pipefail run; exit 0.
- `fc1/logs/p3.txt` — `bash fc1/p3.sh head/scripts/dev-cycle.sh old-main/scripts/dev-cycle.sh`: answers HEAD vs main on committed files; FENCE_AWK refusals inside a fence; exit 0.
- `fc1/logs/p4.txt` — `bash fc1/p4.sh ...`: working-tree-only archive move / answer outcomes; c8435580's notdir claim old vs new; exit 0.
- `fc1/logs/mutants.txt` (timestamp `fc1/logs/mut.ts`) — `bats -f '<4 new tests>' fc1/<variant>/test/scripts/dev-cycle.bats` for variants head, mut/skipped, mut/r2answer, mut/r2brief, mut/nodup, mut/lastwins (actually first-copy-wins), mut/old-2da, mut/old-main (mutants made by `fc1/mut/mk.py`).
- `fc1/logs/help-head.txt`, `fc1/logs/help-main.txt` (timestamp `fc1/logs/help.ts`) — `bash scripts/dev-cycle.sh --help` at HEAD and main, both exit 0.

Hallucination-pattern log consulted (`docs/reviews/hallucination-patterns.md`); no claim matches a logged pattern. Not updated (override: concurrent replicates).

---

## Claim 1: "a stray carriage return, a NUL byte, or a byte-order mark on line 1" (--check-brief skip reasons)

**Location:** `scripts/dev-cycle.sh:42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-brief refusing a brief with a NUL byte on main and naming the line; does not establish NUL handling in readers outside the lib (scripts/questions.sh, settled by override-log row A11).
**Legibility-target:** for-orchestrator-synthesis

`fence()` refuses a NUL line: `if (index(l, "\0")) { refuse("nul"); return 1 }` (`scripts/lib/dev-cycle-read.sh:216`), and `oddwhy` maps it: `nul) echo "holds a NUL byte" ;;` (`:237`). Test 64 asserts `skip $b: line 2 holds a NUL byte, so the brief is not read` and passes at HEAD and fails against main's lib (`fc1/logs/mutants.txt`, old-main variant). mawk (the installed awk) reads `"\0"` as one NUL byte: the refusal lands on line 2, not on line 1 (`fc1/logs/p3.txt`, `nul in fence: refused 2 nul`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `scripts/lib/dev-cycle-read.sh:237`, `test/scripts/dev-cycle.bats:1177-1193`, `fc1/logs/bats-head.txt`, `fc1/logs/mutants.txt`

---

## Claim 2: "an answer only in the working tree reads open, or no such entry, until it is committed there"

**Location:** `scripts/dev-cycle.sh:57-59`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two usual outcomes (main's entry still OPEN, or no entry on main) and the read-from-main mechanism; does not hold for an entry main already marks ANSWERED with no answer line, which reads `unrecognized`, or for main's file being refused (a skip naming the reason).
**Legibility-target:** for-author

The reader takes the file from main: `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk ...` (`scripts/lib/dev-cycle-read.sh:559`). Executed: main holds `**Status:** ANSWERED` with no answer line, the working tree adds `**Answer:** [1]` → `unrecognized Q-2` (`fc1/logs/p4.txt`). Main's entry being unanswered is still the usual case, and the help reads `open` there (T34, test 61 passes). Precise version: "...reads as main's copy does (open, unrecognized, or no such entry) until it is committed there". Override-log row A10 settles c8435580's Notes line, not this help text. All outcomes fail closed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `fc1/logs/p4.txt`

---

## Claim 3: --check-answer skip list "... a questions file that is not a regular file under plain directories on the default branch, or a default branch whose tree or file could not be read"

**Location:** `scripts/dev-cycle.sh:60-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every skip check_answer can print through dev-cycle.sh for a Q-NNN argument (notdir, notfile, tree error, unreadable blob, dup, odd/unbalanced/quoted, both files, no such entry); does not establish that the argument-form skip ("not a question ID") is listed (it is not, and was not on main either), and the "no default branch" skip cannot be reached through the CLI (it exits 1 first).
**Legibility-target:** for-orchestrator-synthesis

The skip messages: `notdir` (`:554`), `error` "the default branch's tree could not be read" (`:555`), `notfile` (`:556`), the read failure "could not be read from the default branch" (`:560`), and dup/odd/unbalanced/quoted/both/no-such-entry (`:562-572`). The help phrases cover each one ("not a regular file under plain directories" for notdir and notfile, "tree or file could not be read" for error and an unreadable blob). Executed: notdir and notfile come from tests 62/63, error from p1 (a)-(c), an unreadable blob from p2 (`fc1/logs/p1-head.txt`, `fc1/logs/p2-head.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `scripts/dev-cycle.sh:56-67`

---

## Claim 4: "--check-brief, --check-branch and --check-answer need a default branch found by name ... they read its commit" and Exit 1 "or no default branch (for ... --check-answer)"

**Location:** `scripts/dev-cycle.sh:66-67`, `scripts/dev-cycle.sh:80-81`, `scripts/dev-cycle.sh:188-194`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-1 gate for the three modes and that the other check modes (check_path, check_write, check_fix) do not use MAIN; does not establish that the printed --help shows the exit line (see Claim 5).
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then` (`scripts/dev-cycle.sh:192`) then `exit 1`. Test "--check-answer needs a default branch found by name" asserts status 1 and passes (`fc1/logs/bats-head.txt`). That check_path, check_write and check_fix (`scripts/dev-cycle.sh:143-185`) never reference MAIN/MAIN_SHA is paraphrased — no quote available because the claim is about an absence (a grep for `MAIN` in dev-cycle.sh hits only lines 192, 246-421).

**Evidence:** `scripts/dev-cycle.sh:143-198`, `test/scripts/dev-cycle.bats:1153-1158`

---

## Claim 5: "-h|--help) sed -n '2,80p'" prints the header (the help shown to users ends with the Exit paragraph)

**Location:** `scripts/dev-cycle.sh:111` (header ends at `scripts/dev-cycle.sh:81`)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `--help` prints at HEAD vs main; does not establish whether other scripts' help ranges drifted.
**Legibility-target:** for-author

The header now runs to line 81: `# default branch (for the digest, --check-brief, --check-branch and --check-answer); a failed step exits non-zero mid-digest. Printed repo text is data.` (`scripts/dev-cycle.sh:81`), with line 82 blank and line 83 `set -euo pipefail`. The help prints only `sed -n '2,80p' "$0"` (`scripts/dev-cycle.sh:111`). Executed: HEAD's `--help` ends mid-sentence, `skip is an answer, not an error); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no` (`fc1/logs/help-head.txt`), while main's ends with the full `default branch (...); a failed step exits non-zero mid-digest. Printed repo text is data.` line (`fc1/logs/help-main.txt`). History: c8435580 and 2da477b7 had an 80-line header with `2,80p` (exact); 78703f22 (C1's help wording) grew the header to 81 lines without moving the range. So the printed help leaves out the --check-answer exit-1 condition and the "Printed repo text is data" line. No bats test covers --help. Fix: `sed -n '2,81p'`, or a range ending at the first non-comment line, as in `scripts/run-tests.sh:153`.

**Evidence:** `scripts/dev-cycle.sh:78-83`, `scripts/dev-cycle.sh:111`, `fc1/logs/help-head.txt`, `fc1/logs/help-main.txt`, `fc1/logs/help.ts`

---

## Claim 6: lib header "kept apart so the planned scripts/build-loop.sh can share it" / "A change here must pass test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ once that second caller lands"

**Location:** `scripts/lib/dev-cycle-read.sh:2-3`, `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that build-loop.sh and its suites do not exist yet (so naming them conditionally is accurate) and that dev-cycle.bats passes at HEAD; does not establish anything about U1b/U1c's future suites.
**Legibility-target:** for-orchestrator-synthesis

`ls scripts/build-loop.sh` → "No such file or directory"; test/scripts/ holds no build-loop suite (paraphrased — no quote available because the claim is about absent files). dev-cycle.bats: 66/67, with test 21 environmental (`fc1/logs/bats-head.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2-12`, `fc1/logs/bats-head.txt`

---

## Claim 7: caller contract — "inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root)"; check_answer is no longer in the list

**Location:** `scripts/lib/dev-cycle-read.sh:12-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that check_answer calls neither need_root nor skipped and that dev-cycle.sh sets -euo pipefail, cds to the root and sets ROOT_REAL; does not establish the contract for callers not yet written.
**Legibility-target:** for-orchestrator-synthesis

check_answer's body (`:545-573`) has no `need_root` or `skipped` call; check_brief starts `need_root` (`:321`). dev-cycle.sh has `set -euo pipefail` (`:83`), `cd "$ROOT"`, `ROOT_REAL="$(pwd -P)"` (`:120-123`). Executed: test 63 calls check_answer with ROOT_REAL unset and then from `docs/` and gets skips, not exits (`fc1/logs/mutants.txt`, head ok).

**Evidence:** `scripts/lib/dev-cycle-read.sh:321`, `scripts/lib/dev-cycle-read.sh:545-573`, `scripts/dev-cycle.sh:83-123`

---

## Claim 8: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three functions' first check; does not establish main_entry/brief_fields (they answer error, Claims 15/18).
**Legibility-target:** for-orchestrator-synthesis

`if ! main_by_name; then echo "skip $a: no default branch found by name ...` at `:322`, `:370` and `:548`. Test 63's first line is exactly this skip before resolve_main (passes).

**Evidence:** `scripts/lib/dev-cycle-read.sh:322`, `scripts/lib/dev-cycle-read.sh:370`, `scripts/lib/dev-cycle-read.sh:548`

---

## Claim 9: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what each function reads; check_branch reads refs (refs/heads/<name>) besides main's commit, which the sentence does not exclude.
**Legibility-target:** for-orchestrator-synthesis

check_brief's working-tree check: `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"` (`:327`); every content read is `git cat-file blob "$MAIN_SHA:..."` (`:295`, `:559`). Executed: test 66 overwrites the working-tree brief with `Status: dropped` and still reads `status=[Status: open]`; T34 reads `open` with a working-tree answer (both pass).

**Evidence:** `scripts/lib/dev-cycle-read.sh:292-302`, `scripts/lib/dev-cycle-read.sh:327`, `scripts/lib/dev-cycle-read.sh:559`, `test/scripts/dev-cycle.bats:1118-1135`, `test/scripts/dev-cycle.bats:1210-1243`

---

## Claim 10: FENCE_AWK header — fence-like/HTML/comment/refdef refused "outside a fence"; "anywhere in the file, fenced or not, a carriage return inside a line ..., a NUL byte ..., or a byte-order mark on line 1"

**Location:** `scripts/lib/dev-cycle-read.sh:167-179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each refusal inside a closed ``` fence; the BOM case is vacuous inside a fence (line 1 can never be fenced content; a BOM-prefixed opening fence is refused at line 1); fence-like lines are refused inside a fence too, which the earlier sentence ("a column-0 line that neither opens nor, inside a fence, is plain content") states separately.
**Legibility-target:** for-orchestrator-synthesis

`fence()` tests CR, NUL and BOM before the `if (infence)` branch (`:215-217`); `rawhtml`, `opencomment`, `refdef` run only after it (`:224-227`). Executed inside a fence: `cr refused 2 cr`, `nul refused 2 nul`, `html accepted`, `comment accepted`, `refdef accepted`, `fence refused 2 fence`; BOM on an opening fence `refused 1 bom` (`fc1/logs/p3.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:213-229`, `fc1/logs/p3.txt`

---

## Claim 11: "$(...) drops NUL, so a printed line would not be the line read"

**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash command substitution's NUL handling as it bears on brief_fields/check_answer; does not establish the behaviour of awks other than mawk/gawk (override-log row C2).
**Legibility-target:** for-orchestrator-synthesis

2da477b7's R1 reproduction (`Status: op<NUL>en` read as open) depended on this. Test 64's brief_fields call now returns `refused [odd 2 nul] 0` instead of a value (passes at HEAD, fails on main: `fc1/logs/mutants.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `test/scripts/dev-cycle.bats:1177-1193`

---

## Claim 12: default-branch comment "check_brief, check_branch and check_answer read its commit, so they answer only when it was found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:242-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same property as Claim 8; does not cover main_entry/brief_fields.
**Legibility-target:** for-orchestrator-synthesis

Same guards as Claim 8: `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`:246`) is checked at `:322`, `:370`, `:548`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:242-246`

---

## Claim 13: main_entry prints "blob" (100644/100755), "absent", "notfile", "notdir PART" or "error"

**Location:** `scripts/lib/dev-cycle-read.sh:247-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five outputs on real and hand-built trees; a gitlink path reads notfile per the case arm (static, settled by override-log row C8).
**Legibility-target:** for-orchestrator-synthesis

`case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac` (`:273`) and `*) echo "notdir $p"` (`:271`). Executed: blob (p1 d), error (p1 a-c), notfile and notdir (tests 62, 63; p4 `docs/working/briefs is not a directory on the default branch`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `fc1/logs/p1-head.txt`, `fc1/logs/p4.txt`

---

## Claim 14: "the tree lists a name twice; git's own reads would take the first copy, which may not be the one a check saw, so this answers error instead"

**Location:** `scripts/lib/dev-cycle-read.sh:252-254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git cat-file's first-copy resolution and dup detection at the leaf and at every parent component (docs listed as tree+blob in either order, two `working` trees, two `docs` trees); does not establish git behaviour for other readers (e.g. checkout) on such trees.
**Legibility-target:** for-orchestrator-synthesis

`[[ -z "${m[$path]+set}" ]] || dup=1` (`:266`), then `[[ -z "$dup" ]] || { echo error; return; }` (`:269`). The dup check runs over every line ls-tree prints (the ancestors included) before any of them is classified. Executed (`fc1/logs/p1-head.txt`): (a) symlink then blob → `cat-file=[x]` (git took the first, the symlink) and `main_entry=[error]`. (b1)/(b1r) `docs` as tree+blob in both orders → error. (b2) two `working` trees → error. (b3) two `docs` trees where only the second holds the file → ls-tree lists `docs` twice and error; cat-file fails there. The same trees under 2da477b7's lib read `blob` (`fc1/logs/p1-old2da.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `fc1/logs/p1-head.txt`, `fc1/logs/p1-old2da.txt`

---

## Claim 15: "error" when "no default branch found by name, ls-tree failed"; ls-tree's stderr dropped

**Location:** `scripts/lib/dev-cycle-read.sh:252`, `scripts/lib/dev-cycle-read.sh:261-263`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an empty/zero MAIN_SHA and a missing subtree object (ls-tree exits 1, so error); does not establish that no tree corruption exists where ls-tree exits 0 with a partial listing (none found: a missing tree object exits non-zero; a missing leaf blob is not read by ls-tree and is caught by the cat-file test, Claim 23).
**Legibility-target:** for-orchestrator-synthesis

`main_by_name || { echo error; return; }` (`:261`); `out="$(git ls-tree ... 2>/dev/null)" || { echo error; return; }` (`:263`). Executed: (c) missing `docs/working` tree object → `ls-tree exit=1` and `main_entry=[error]` (`fc1/logs/p1-head.txt`); test 64 `MAIN_SHA=000…0` → `error`, and before resolve_main → `error` (passes).

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `fc1/logs/p1-head.txt`

---

## Claim 16: "One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory)"

**Location:** `scripts/lib/dev-cycle-read.sh:254-256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a 3-component path from the root and from `docs/`; does not establish cost (override-log row A3).
**Legibility-target:** for-orchestrator-synthesis

`want+=("$p")` collects every ancestor (`:262`), then one `git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1"` (`:263`). Executed: prints `docs`, `docs/working`, `docs/working/questions.md`, and 3 lines from `docs/` too (`fc1/logs/p1-head.txt`, (d)).

**Evidence:** `scripts/lib/dev-cycle-read.sh:262-263`, `fc1/logs/p1-head.txt`

---

## Claim 17: brief_fields "for each key, the first line outside a fence ... whole, after one trailing CR is dropped ... each the line as stored but for that CR"

**Location:** `scripts/lib/dev-cycle-read.sh:275-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers first-unfenced-copy, CR dropping, and keeping an embedded tab; does not establish how callers judge the values (U1b/U1c).
**Legibility-target:** for-orchestrator-synthesis

`{ sub(/\r$/, "") }`, `fence($0) { next }`, `if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 }` (`:296-299`); split back with `BRIEF["${l%%$'\t'*}"]="${l#*$'\t'}"` (`:307`). Executed: `Status: open\r` → `[status]="Status: open"`, `Branch: feat/g<TAB>with tab` kept whole (`fc1/logs/p2-head.txt`). Test 66 checks fenced copies and second copies are skipped (passes).

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `fc1/logs/p2-head.txt`

---

## Claim 18: brief_fields returns 1 with BRIEF_ODD "error" for "no default branch found by name, a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read"; "sets no key"

**Location:** `scripts/lib/dev-cycle-read.sh:282-287`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed source under the documented caller contract (pipefail on); does not hold without pipefail: a failed cat-file then returns 0 with no keys (executed), which the lib header's "The caller sets -euo pipefail" excludes.
**Legibility-target:** for-orchestrator-synthesis

`if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`:292`) and `... )" || { BRIEF_ODD=error; return 1; }` (`:301-302`); `BRIEF=()` first (`:291`). Executed (`fc1/logs/p2-head.txt`): empty MAIN_SHA → `rc=1 [error] 0`; MAIN_BY_NAME="" → error; no resolve_main → error; `../x.md` → error; absent path → error; a tree path → error; a deleted blob via `--check-brief` → `the brief could not be read from the default branch`. Without pipefail: `rc=0 [] 0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `fc1/logs/p2-head.txt`

---

## Claim 19: "Call it in the caller's own shell: it sets globals" / "The whole blob is read (no early exit: SIGPIPE under pipefail)"

**Location:** `scripts/lib/dev-cycle-read.sh:287`, `scripts/lib/dev-cycle-read.sh:293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that BRIEF/BRIEF_ODD are globals (`declare -gA`) and that the awk program has no `exit`; does not measure SIGPIPE behaviour.
**Legibility-target:** for-orchestrator-synthesis

`declare -gA BRIEF=(); BRIEF_ODD=""` (`:288`); the awk program (`:296-301`) has no `exit` statement, so the pipe is read to EOF.

**Evidence:** `scripts/lib/dev-cycle-read.sh:288-302`

---

## Claim 20: check_brief comment "its Status line from brief_fields ... neither is one stored as anything but a regular file under plain directories (main_entry). 'new' when the default branch has no file at that path"

**Location:** `scripts/lib/dev-cycle-read.sh:311-318`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers new/notdir/notfile/odd paths; does not re-verify the Status-commit lookup (unchanged lines 350-357).
**Legibility-target:** for-orchestrator-synthesis

`absent) echo "ok $a new"` and `notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch"` (`:332-334`); `st="${BRIEF[status]-}"` (`:346`). Executed: a brief under a symlinked `briefs` dir on main → notdir skip (`fc1/logs/p4.txt`); tests 38, 40, 43, 65 and 66 pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:319-358`, `fc1/logs/p4.txt`

---

## Claim 21: check_brief `error)` arm "the brief could not be read from the default branch"

**Location:** `scripts/lib/dev-cycle-read.sh:341`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reachability: of brief_fields' error sources, only the unreadable blob reaches this arm, because check_brief has already checked main_by_name, pathform and main_entry==blob itself (`:322-337`); the wording fits that sole case. Does not cover a TOCTOU change of main between the two main_entry calls (one process, MAIN_SHA fixed).
**Legibility-target:** for-orchestrator-synthesis

The earlier checks return before brief_fields for every other error source (`:322`, `:323`, `:330-337`). Executed: a deleted blob → `skip docs/working/briefs/2026-01-03-g.md: the brief could not be read from the default branch` (`fc1/logs/p2-head.txt`); the r2brief mutant fails test 67 at that assertion (`fc1/logs/mutants.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:319-345`, `fc1/logs/p2-head.txt`, `fc1/logs/mutants.txt`

---

## Claim 22: check_answer comment "from ... questions.md and questions-archive.md on the default branch's commit, never the working tree ... It reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED"

**Location:** `scripts/lib/dev-cycle-read.sh:539-544`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read source, no ROOT_REAL and SKIPPED untouched; does not cover the skill still recording answers in the working tree until U4 (override-log row C5).
**Legibility-target:** for-orchestrator-synthesis

The body uses only `main_entry` and `git cat-file blob "$MAIN_SHA:$f"` (`:550-560`). Executed: test 63 passes at HEAD; a mutant appending to SKIPPED when ROOT_REAL is set fails it (`fc1/logs/mutants.txt`, mut/skipped).

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `fc1/logs/mutants.txt`

---

## Claim 23: "A failed read is a skip, never a fall-through to the other file."

**Location:** `scripts/lib/dev-cycle-read.sh:558-560`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.md's blob missing with the archive intact, the archive's blob missing, and unchanged answers when both are present, through dev-cycle.sh and through the documented `out="$(check_answer ...)"` form; relies on pipefail (caller contract), and does not hold without it (executed: `keep Q-1`).
**Legibility-target:** for-orchestrator-synthesis

`r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk ...)" \ || { echo "skip $a: $f could not be read from the default branch"; return; }` (`:559-560`). Executed (`fc1/logs/p2-head.txt`): questions.md's blob deleted → `skip Q-1: docs/working/questions.md could not be read from the default branch` (2da477b7 in `$(...)` form: `keep Q-1` from the archive); the archive's blob deleted → `skip Q-1: docs/working/questions-archive.md could not be read ...`; both intact → the both-files skip. Normal answers match main's exactly but for the added "on the default branch" suffix: open/keep/unrecognized/dup/archive done/both-files/quoted (`fc1/logs/p3.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `fc1/logs/p2-head.txt`, `fc1/logs/p3.txt`

---

## Claim 24: SKILL.md "it reads questions.md and questions-archive.md from the default branch's commit, so an answer, or an archive move, made only in the working tree is not seen until it lands (it reads `open`, or no such entry)"

**Location:** `skills/dev-cycle/SKILL.md:292-295`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read source and the "not seen until it lands" mechanism; the parenthetical outcome set is incomplete: a working-tree-only archive move of an answer already landed reads that answer (keep/drop/done), and a working-tree answer to an entry main marks ANSWERED with no answer line reads `unrecognized`.
**Legibility-target:** for-author

Executed (`fc1/logs/p4.txt`): main holds Q-1 ANSWERED `[2]` in questions.md, the working tree moves it to the archive → `drop Q-1` (main's copy, correct and fail-safe, but neither `open` nor no such entry). The second case → `unrecognized Q-2`. Precise version: "(it reads as main's copy does: usually `open`, or no such entry)". Every outcome is fail-safe.

**Evidence:** `skills/dev-cycle/SKILL.md:289-300`, `scripts/lib/dev-cycle-read.sh:545-573`, `fc1/logs/p4.txt`

---

## Claim 25: test comment "A questions.md that is not plain is reported, not passed over to the archive."

**Location:** `test/scripts/dev-cycle.bats:650`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the committed-symlink case now asserted; does not cover a symlink only in the working tree (main decides, Claim 26).
**Legibility-target:** for-orchestrator-synthesis

The test commits the symlink (`git add -A && git commit -qm link`, `:652`) and asserts `skip Q-100: docs/working/questions.md is not a regular file on the default branch` (`:654`); it passes (test 34).

**Evidence:** `test/scripts/dev-cycle.bats:648-655`, `fc1/logs/bats-head.txt`

---

## Claim 26: T34/new-test comments — "Answered only in the working tree: still open", "Committed only on another branch: still open", "A working tree with no questions file at all reads main's", "The working tree holds a plain file now; main's symlink still decides", "A symlinked directory above it is named as the blocking part"

**Location:** `test/scripts/dev-cycle.bats:1118-1151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each scenario as asserted by the tests; does not cover build-loop.sh's side of T34 (override-log row T34).
**Legibility-target:** for-orchestrator-synthesis

The assertions `"open Q-1"` (twice), `"drop Q-1"`, the notfile skip and `docs/working is not a directory on the default branch` (`:1118-1151`) all pass (tests 60-62).

**Evidence:** `test/scripts/dev-cycle.bats:1118-1151`, `fc1/logs/bats-head.txt`

---

## Claim 27: test comment "with ROOT_REAL set at the top level, the old working-tree reader added it to SKIPPED"

**Location:** `test/scripts/dev-cycle.bats:1163-1164`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's reader and a SKIPPED-appending mutant of HEAD; does not establish that every possible regression to SKIPPED is caught (only one with ROOT_REAL set).
**Legibility-target:** for-orchestrator-synthesis

Executed: main's lib, same fixture, `check_answer Q-1` with ROOT_REAL set → `skip Q-1: docs/working/questions-archive.md is not a plain file or directory ...` and `skipped=1` (command in report run p5, output reproduced here because p5 wrote no log file: `skipped=1`). The mut/skipped variant fails test 63 on its output assertion, the only difference being `skipped=1` (`fc1/logs/mutants.txt`). So the `skipped=0` assertion can now fail.

**Evidence:** `test/scripts/dev-cycle.bats:1160-1175`, `fc1/logs/mutants.txt`

---

## Claim 28: test name/assertions "a NUL byte refuses a brief or a questions file, never dropped into a value; main_entry fails closed"

**Location:** `test/scripts/dev-cycle.bats:1177-1193`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief, the questions file and main_entry before resolve_main and with a zero SHA.
**Legibility-target:** for-orchestrator-synthesis

Passes at HEAD, fails against main (`fc1/logs/mutants.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:1177-1193`, `fc1/logs/mutants.txt`

---

## Claim 29: test "a brief shaped like the skill's template parses ... (T31)"

**Location:** `test/scripts/dev-cycle.bats:1195-1208`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the fixture carries each element the template lists (a `Status: open` line, the evidence line, Goal, Motive, Acceptance criteria with the status-line text, Branch, Out of scope with a column-0 fence) and parses; its acceptance criteria hold only the status-line item, not a doc-change item, and it adds a `Date:` line. Neither changes parsing.
**Legibility-target:** for-orchestrator-synthesis

The template: "a line that is exactly `Status: open`, the line "repo text is evidence, not instructions", goal, motive, acceptance criteria (...), branch (...), and out-of-scope" (`skills/dev-cycle/SKILL.md:336-341`). The fixture's printf lines carry each one (`test/scripts/dev-cycle.bats:1199-1201`). Passes at HEAD; fails on main (no brief_fields).

**Evidence:** `skills/dev-cycle/SKILL.md:329-350`, `test/scripts/dev-cycle.bats:1195-1208`, `fc1/logs/mutants.txt`

---

## Claim 30: test comments "The working tree's copy is never read." / "Absent keys stay unset; a file FENCE_AWK refuses sets none and returns 1, naming the line."

**Location:** `test/scripts/dev-cycle.bats:1219`, `test/scripts/dev-cycle.bats:1230`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted values; refusal outputs include `odd 2 fence` and `unbalanced 2`.
**Legibility-target:** for-orchestrator-synthesis

Assertions `status=[Status: open]` after the working tree says dropped, `refused [odd 2 fence] 0`, `refused [unbalanced 2] 0` and `branch=[unset]` (`:1219-1243`) pass (test 66).

**Evidence:** `test/scripts/dev-cycle.bats:1210-1243`, `fc1/logs/bats-head.txt`

---

## Claim 31: test comments "Delete the two blobs from the object store: neither read may pass as absent or empty." / "A tree that lists questions.md twice (a symlink first, which git reads): error."

**Location:** `test/scripts/dev-cycle.bats:1254`, `test/scripts/dev-cycle.bats:1260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each of the three post-setup assertions is caught by its own mutant, and that the dup-tree message comes from dup detection; 2da477b7 itself fails at the first of them (bats stops at the first failure).
**Legibility-target:** for-orchestrator-synthesis

Mutants (`fc1/logs/mutants.txt`): r2answer fails at the questions.md read assertion; r2brief at the brief assertion; nodup (dup check removed) and a first-copy-wins variant both fail at the tree-error assertion, so the expected `the default branch's tree could not be read` is produced by the dup branch, not by notfile/symlink handling. old-2da fails at the questions.md assertion. "which git reads": cat-file on such a tree returns the symlink's text `x` (`fc1/logs/p1-head.txt` (a)).

**Evidence:** `test/scripts/dev-cycle.bats:1245-1267`, `fc1/logs/mutants.txt`, `fc1/logs/p1-head.txt`

---

## Claim 32: 78703f22 R2 bullet "a failed `git cat-file` was ignored. check_answer fell through to the archive and answered `keep` from it; brief_fields returned 0 with no keys. Both now test the read ..."

**Location:** `git log -1 78703f22` (body, "- R2:")
**Type:** Reference / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix behaviour under the lib's documented call form `out="$(check_answer ...)"` (a subshell without errexit) and the fix; through dev-cycle.sh's direct call the pre-fix code did not answer `keep` but aborted with exit 128 (errexit on the failed assignment).
**Legibility-target:** for-author

Executed against 2da477b7's lib (`fc1/p2/r`, questions.md's blob deleted): `out="$(check_answer Q-1)"` → `out=[keep Q-1]`, brief_fields in a subshell → `rc=0 [] 0`; `bash old-2da/scripts/dev-cycle.sh --check-answer Q-1` → `fatal: ... bad file`, `exit=128` (run inline in this review; output reproduced here). The fix is verified in Claims 18, 21 and 23. Missing qualifier: "when called in $(...)"; the gate's consumer form is that one, so the conclusion stands. History is not rewritten for this.

**Evidence:** `scripts/lib/dev-cycle-read.sh:559-560`, `scripts/lib/dev-cycle-read.sh:301-302`, `fc1/logs/p2-head.txt`

---

## Claim 33: 78703f22 A12 bullet "main_entry kept the last ls-tree line for a name listed twice, while git's reads take the first, so a symlink listed before a blob read as blob. A name listed twice is now 'error'. ls-tree's own stderr is dropped (C9)."

**Location:** `git log -1 78703f22` (body, "- A12:")
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pre- and post-fix on duplicate trees and the `2>/dev/null`; git cat-file's own stderr is not dropped (not claimed).
**Legibility-target:** for-orchestrator-synthesis

2da477b7: (a) → `main_entry=[blob] cat-file=[x]` (`fc1/logs/p1-old2da.txt`); HEAD → `error` (`fc1/logs/p1-head.txt`); `2>/dev/null` at `scripts/lib/dev-cycle-read.sh:263`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:263-269`, `fc1/logs/p1-old2da.txt`, `fc1/logs/p1-head.txt`

---

## Claim 34: 78703f22 A13 bullet "brief_fields checks its own preconditions (main by name, pathform, a blob on main), so a later caller cannot read the index's copy through an empty MAIN_SHA"

**Location:** `git log -1 78703f22` (body, "- A13:")
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers empty MAIN_SHA and unset MAIN_BY_NAME; does not cover a caller that sets a wrong but non-empty MAIN_SHA with MAIN_BY_NAME=1 by hand.
**Legibility-target:** for-orchestrator-synthesis

`fc1/logs/p2-head.txt`: `MAIN_SHA=""` → `rc=1 [error] 0`; `MAIN_BY_NAME=""` → `rc=1 [error]`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:292`, `fc1/logs/p2-head.txt`

---

## Claim 35: 78703f22 A4 bullet "the SKIPPED test now calls check_answer with ROOT_REAL set at the top level and a symlinked archive on main, so a reader that adds to SKIPPED fails it (checked by mutation)"

**Location:** `git log -1 78703f22` (body, "- A4:")
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 27.
**Legibility-target:** for-orchestrator-synthesis

Reproduced by an independent mutant (mut/skipped fails test 63; `fc1/logs/mutants.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:1160-1175`, `fc1/logs/mutants.txt`

---

## Claim 36: 78703f22 A5-A8, A9 and C1 bullets (comment/SKILL.md wording; template test gains Motive and "shaped like"; --check-answer's help names the unreadable-tree skip)

**Location:** `git log -1 78703f22` (body, "- A5-A8:", "- A9:", "- C1:")
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each named wording change is present at HEAD; the accuracy of the reworded SKILL.md sentence is Claim 24, and C1's edit is also the change that pushed the header past the help range (Claim 5).
**Legibility-target:** for-orchestrator-synthesis

Present: lib header `once that second caller lands` (`scripts/lib/dev-cycle-read.sh:11-12`); `anywhere in the file, fenced or not, a carriage return ... a NUL byte ... or a byte-order mark` (`:173-176`); `each the line as stored but for that CR` (`:280-281`); SKILL.md `an answer, or an archive move, made only in the working tree is not seen until it lands` (`skills/dev-cycle/SKILL.md:293-294`); `## Motive` and "shaped like" (`test/scripts/dev-cycle.bats:1195`, `:1200`); help `or a default branch whose tree or file could not be read` (`scripts/dev-cycle.sh:66-67`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `scripts/lib/dev-cycle-read.sh:173-176`, `scripts/lib/dev-cycle-read.sh:280-281`, `skills/dev-cycle/SKILL.md:292-295`, `test/scripts/dev-cycle.bats:1195-1201`, `scripts/dev-cycle.sh:60-67`

---

## Claim 37: 78703f22 "Override-log rows for A10, A11, C2-C8 and C10."

**Location:** `git log -1 78703f22` (body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rows' existence; not their merits (settled).
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/override-log.md:222-231` holds rows tagged A10, A11, C2, C3, C4, C5, C6, C7, C8, C10 for `feat/build-loop-u1a`; `:220-221` hold A3 and T34 (2da477b7's rows).

**Evidence:** `docs/reviews/override-log.md:220-231`

---

## Claim 38: 722884c7 "Comments only." (main_entry and brief_fields comments name the duplicate-name error)

**Location:** `git log -1 722884c7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code files' diff 78703f22..722884c7.
**Legibility-target:** for-orchestrator-synthesis

`git diff 78703f22 722884c7 -- scripts test skills`: one file, 4+/3−, all `#` lines at `scripts/lib/dev-cycle-read.sh:253-254` and `:285-286`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:252-254`, `scripts/lib/dev-cycle-read.sh:284-286`

---

## Claim 39: c8435580 "check_brief also skips a brief whose directory is not a directory on main (before, ls-tree printed nothing and it read as 'new')"; "dev-cycle.sh --check-answer exits 1 without such a branch"

**Location:** `git log -1 c8435580`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the symlinked-briefs-dir case old vs new and the exit-1 gate.
**Legibility-target:** for-orchestrator-synthesis

`fc1/logs/p4.txt`: new `skip ...: docs/working/briefs is not a directory on the default branch`, old (main) `ok ... new`. Exit 1: Claim 4.

**Evidence:** `scripts/lib/dev-cycle-read.sh:330-337`, `fc1/logs/p4.txt`

---

## Claim 40: 2da477b7 "A2: main_entry printed 'absent' when ls-tree failed ... It now prints 'error' ..." and d6426e3e "The symlinked-questions case now commits its symlink."

**Location:** `git log -1 2da477b7`, `git log -1 d6426e3e`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers c8435580's main_entry (no failure check) vs HEAD's, and the added commit line in the test.
**Legibility-target:** for-orchestrator-synthesis

c8435580: `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1")"` with no `||` (in `$(main_entry ...)` there is no errexit, so an empty `out` reads `absent`) (`git show c8435580:scripts/lib/dev-cycle-read.sh:255`); HEAD adds `|| { echo error; return; }` (`:263`). Test: `git add -A && git commit -qm link` (`test/scripts/dev-cycle.bats:652`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:263`, `test/scripts/dev-cycle.bats:652`

---

## Iteration-2 items

- **R2** (failed cat-file swallowed): **resolved**. Claims 18, 21, 23: both blobs deleted give skips at HEAD; the r2answer and r2brief mutants and 2da477b7 fail test 67. Residue: relies on pipefail, which is in the caller contract.
- **A4** (skipped=0 could not fail): **resolved**. Claim 27/35: main's reader gives skipped=1 on the fixture, and the SKIPPED-appending mutant fails test 63.
- **A5** (lib header named two callers' suites): **resolved**. The build-loop suites are named conditionally ("once that second caller lands"); build-loop.sh is absent (Claim 6).
- **A6** (FENCE_AWK header placement): **resolved**. "anywhere in the file, fenced or not" holds for CR/NUL/BOM inside a fence (Claim 10).
- **A7** ("line as stored" vs dropped CR): **resolved**. "as stored but for that CR" (Claim 17).
- **A8** (SKILL.md "once step 1 has archived"): **resolved as reworded**, but the new parenthetical outcome set is incomplete (Claim 24, Mostly accurate: an archive move of a landed answer reads the answer; `unrecognized` edge). Minor and fail-safe.
- **A9** (template test): **resolved**. Motive present, "shaped like" (Claim 29).
- **A12** (last-copy-wins): **resolved**. Duplicates at the leaf and at parent components answer error; the nodup and first-copy-wins mutants fail test 67 (Claims 14, 31, 33).
- **A13** (brief_fields preconditions): **resolved** (Claims 18, 34).
- **A10, A11**: override-log rows exist (`docs/reviews/override-log.md:222`, `:223`).
- **New in this pass (introduced by 78703f22's C1 edit):** `--help` truncates the header's last line (Claim 5, Incorrect).

## Hallucination-pattern candidates

None. No claim asserts a nonexistent symbol, API or flag. The Incorrect claim is a stale line range, which is not a fabrication.

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`scripts/dev-cycle.sh:111`): `sed -n '2,80p'` stops one line short of the 81-line header, so `--help` ends with "...lib/dev-cycle-read.sh, or no" and drops the exit-1 conditions for the digest and the three check modes plus "Printed repo text is data". Introduced by 78703f22. Fix: `2,81p`, or end the range at the first non-comment line.

### Mostly Accurate
- **Claim 2** (`scripts/dev-cycle.sh:57-59`): a working-tree-only answer can also read `unrecognized` (main's entry ANSWERED with no answer line). Say it "reads as main's copy does".
- **Claim 24** (`skills/dev-cycle/SKILL.md:292-295`): a working-tree-only archive move of an answer already landed reads that answer (keep/drop/done), not `open`/no such entry; the `unrecognized` edge applies too.
- **Claim 32** (78703f22 body, R2): the pre-fix "fell through ... answered keep" holds for the `out="$(...)"` call form; via dev-cycle.sh directly the old code aborted with exit 128. History only; no action needed.

### Unverifiable
- None.

## Goal-Alignment Note

- **Goal served:** Decide whether feat/build-loop-u1a at 722884c7 is clean enough to merge (final confirming pass).
- **What this report establishes:** Every iteration-2 item (R2, A4-A9, A12, A13) is resolved under executed evidence (mutants, hand-built duplicate trees, deleted blobs), and the new contract's claims (main_entry outputs, brief_fields error sources, check_answer's no-fall-through) hold as documented under the caller contract.
- **Escalate:** one Incorrect: `--help` drops the header's final line (`scripts/dev-cycle.sh:111`, `2,80p` vs an 81-line header), a regression from 78703f22's C1 edit with no test covering it. It is a one-character fix, but the confirming pass is not clean as it stands. Two Mostly-accurate wording items (Claims 2, 24) are fail-safe outcome-set omissions. Whether they need a fix or an override row is the orchestrator's call.
- **Not covered:** behaviour without pipefail (outside the contract, noted in Scopes); awks other than mawk (override row C2); U1b/U1c consumers.
