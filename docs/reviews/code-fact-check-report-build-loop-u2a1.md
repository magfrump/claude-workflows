Commit: 6f624cdf

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a1, branch feat/build-loop-u2a1)
**Scope:** branch diff `git diff main...HEAD` (main 900c47d0 .. 6f624cdf): docs/working/plan-build-loop-handoff.md, docs/working/questions.md, scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, and the commit message of 6f624cdf
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-06
**Total claims checked:** 24
**Summary:** 20 verified, 3 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Execution provenance. Every executed claim ran against a `git archive` export of the commit
(6f624cdf exported to `$FC/copy`, main 900c47d0 to `$FC/maincopy`), with
`FC=/home/node/.claude/jobs/814a541d/tmp/review-u2a1/fc`, `GIT_CONFIG_GLOBAL=/dev/null
GIT_CONFIG_NOSYSTEM=1 TMPDIR=$FC/tmp`, each under `timeout`. Captured output is in `$FC/logs/`.
Runs took place 2026-10-06T15:58Z-16:02Z (each log's own timestamp is below). No process
was left running.

Hallucination-pattern log consulted (`docs/reviews/hallucination-patterns.md`). Claim 18
(per-suite test tallies in a commit message) is in the same class as the logged patterns
"All 85 tests ... pass claimed in commit 59ca38f" and "mode1-equiv 33 claimed in commit
37c5ea9". This time the counts match.

---

## Claim 1: "U2 carries about twenty override rows"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count of override-log Defer rows whose revisit trigger names U2. It does not show that each of those rows is assigned to a U2 sub-unit in the split note.

Command `awk '/^\| 20/ && /Defer/ && /Revisit trigger:[^|]*U2/' docs/reviews/override-log.md | wc -l`
run in the worktree printed `23` (exit 0, 2026-10-06T16:02:16Z). Paraphrased, no quote available
because this is a count over 23 table rows. That count is "about twenty".

**Evidence:** `docs/working/plan-build-loop-handoff.md:273`, `docs/reviews/override-log.md`, `$FC/logs/counts.log`

---

## Claim 2: "U2a1: `main_entry`'s `badform` word with one shared reason mapping, `entry_why` (rows 228, 306); one spelling of the closed/ rule, `isclosed` (row 292); `check_fix` also refuses `docs/constraints.md` (row 204 ...); U1d's carried wording and fixture rows."

**Location:** `docs/working/plan-build-loop-handoff.md:274`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the match between the plan's U2a1 bullet and the hunks in this diff. It does not cover the U2a2/U2b/U2c bullets, which describe future work, or the clause "`check_fix` and the floor differ there on purpose" (the floor does not exist yet).

The diff holds each named piece. `scripts/lib/dev-cycle-read.sh:267` has `if ! pathform "$1"; then echo badform; return; fi`,
`:282` has `entry_why() {`, `:159` has `isclosed() { ... }`, and `scripts/dev-cycle.sh:182` adds `|| "$lp" == docs/constraints.md`.
The carried U1d rows are in the test and fixture hunks (Claims 14-17).

**Evidence:** `docs/working/plan-build-loop-handoff.md:273-278`, `scripts/lib/dev-cycle-read.sh:159,267,282-290`, `scripts/dev-cycle.sh:182`

---

## Claim 3: "Interim: [1]. Split recorded in the U2a rubric and commit e8f76379 on `feat/build-loop-u2a`."

**Location:** `docs/working/questions.md:391`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that commit e8f76379 exists on feat/build-loop-u2a, that the rubric records the split, and that `questions.sh check` passes. It does not judge whether the split is the right call (the entry asks the user that).

`git cat-file -t e8f76379` printed `commit`, and `git branch --contains e8f76379` printed `feat/build-loop-u2a`.
The rubric at `feat/build-loop-u2a:docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:74` reads
`- **U2a1** (`feat/build-loop-u2a1`, from main, fresh loop): the parts no review flagged red: ...`.
`bash ~/.claude/scripts/questions.sh check` in the worktree printed `✓ questions: structure valid, indexes current`.
(Paraphrased, no quote available because these commands ran interactively without a log file; each one is a one-line read-only command that can be re-run.)

**Evidence:** `docs/working/questions.md:376-393`, `$FC/rubric.md:74`

---

## Claim 4: "Markup that adds letters (a checked task box, a tag) can still hide a copy; only an exact line ever sets a value."

**Location:** `scripts/build-loop.sh:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the Build-loop policy key with `- [ ]`, `- [x]`, `- [X]`, `- <kbd>…</kbd>` and bold markup. It does not cover a tag at column 0, which FENCE_AWK's `rawhtml` refuses for the whole file instead of hiding the copy.

SETTINGS_AWK keeps letters only and then tests for a prefix:
`s = tolower($0); gsub(/[^a-z]/, "", s); k = ""` / `if (index(s, "buildlooppolicy") == 1) k = "policy"` (`scripts/build-loop.sh:155-156`; excerpt ends :156; the enclosing awk rule continues to :160, read).
In the probe, docs/dev-cycle.md held `Build-loop policy: review` and then the marked-up copy:
```
[- [ ] Build-loop policy: self-merge] -> policy review unset: more than one line starts "Build-loop policy:" (lines 1 and 3)
[- [x] Build-loop policy: self-merge] -> policy review set: line 1 of docs/dev-cycle.md on the default branch
[- [X] Build-loop policy: self-merge] -> policy review set: line 1 of docs/dev-cycle.md on the default branch
[- <kbd>Build-loop policy: self-merge</kbd>] -> policy review set: line 1 of docs/dev-cycle.md on the default branch
[**Build-loop policy: self-merge**] -> policy review unset: more than one line starts "Build-loop policy:" (lines 1 and 3)
```
So the copy count catches an unchecked box and misses a checked box or a tag, as the comment says.
Command: `bash $FC/probe/markup.sh $FC/copy/scripts/build-loop.sh $FC/probe/markup`, cwd `$FC/probe`, exit 0, 2026-10-06T16:00:15Z.

**Evidence:** `scripts/build-loop.sh:150-165`, `$FC/logs/markup.log`

---

## Claim 5: "A tip on a branch not ahead of main, or whose subject does not start "handoff:", is working."

**Location:** `scripts/build-loop.sh:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers branches that are level, behind, or diverged ("ahead" means at least one commit not on main, as in :59-60). It does not run a diverged-branch fixture.

`status_line` sets `loop=working` and reads a marker only when `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`scripts/build-loop.sh:352-354`; the enclosing status_line continues to :362, read).
`ahead` comes from `check_branch`: `$(git rev-list --count "$MAIN_SHA..$sha")` (`scripts/lib/dev-cycle-read.sh:394`).
A level or behind branch counts 0 there and stays `working`. A diverged branch counts more than 0, so its tip is read as a marker. That matches "not ahead". The old phrase "level with main" left out behind branches.

**Evidence:** `scripts/build-loop.sh:325-362`, `scripts/lib/dev-cycle-read.sh:384-397`

---

## Claim 6: main_file words every main_entry refusal through entry_why (commit: "entry_why words every refusal once for check_brief, check_answer and build-loop.sh's main_file")

**Location:** `scripts/build-loop.sh:133`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_file and both of its read_settings callers. It does not establish that `badform` can reach main_file: its only paths are the fixed docs/dev-cycle.md and docs/constraints.md.

`case "$e" in blob) ;; absent) FILE_WHY=absent; return 1 ;; *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;; esac` (`scripts/build-loop.sh:130-134`; the enclosing main_file continues to :141, read).
Both callers treat any value other than `absent` as a refusal. For settings: `if [[ "$FILE_WHY" == absent ]]; then NEVER_LINE="never none: $why"; else NEVER_LINE="never malformed: $why"; fi` (`:217`). For constraints: `else CONSTRAINTS_LINE="constraints unreadable: $FILE_WHY"; fi` (`:265`).
The `error` wording lost its file name: it was `the default branch's tree could not be read for $f` and is now `the tree of the default branch could not be read`. A grep of the scripts and tests finds no remaining copy of the old text.

**Evidence:** `scripts/build-loop.sh:122-141`, `scripts/build-loop.sh:208-276`

---

## Claim 7a: --check-fix refuses docs/constraints.md (in any case), docs/thoughts/ stays fixable, and the help text, skip message and SKILL.md list the same set as the code

**Location:** `scripts/dev-cycle.sh:52`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the header help (`dev-cycle.sh:50-55`), the skip message (`:183`) and `skills/dev-cycle/SKILL.md:72-76` against the code at `:180-185`. It does not cover the comment above check_fix (Claim 7b).

The code compares the lower-cased path: `lp="$(printf '%s' "$a" | tr 'ABC...' 'abc...')"` and `|| "$lp" == docs/constraints.md ||` (`scripts/dev-cycle.sh:177,182`; the enclosing check_fix continues to :186, read). That refuses Constraints.md as well.
The help (`:50-53`) lists `working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with @`. SKILL.md:72-76 and the skip message at `:183` list the same set. The import refusal has its own message at `:185`.
In the suite run, the changed test `ok 54 --check-fix refuses files an instruction file imports, and compares paths ignoring case` passed. That test expects `"skip docs/Constraints.md: in-cycle fixes edit only"` and `"ok docs/thoughts/t.md"`.
Command: `bats test/scripts/dev-cycle.bats`, cwd `$FC/copy`, exit 1 (only test 25 failed, see Claim 18b), 2026-10-06T15:58:00Z.

**Evidence:** `scripts/dev-cycle.sh:50-55,172-186`, `skills/dev-cycle/SKILL.md:72-76`, `test/scripts/dev-cycle.bats:1013-1029`, `$FC/logs/dev-cycle.log`

## Claim 7b: "An in-cycle fix edits documentation only: a tracked .md file under docs/, outside the cycle's own files, working/, human-author/ (the user's), reviews/ and decisions/ (records), the settings file, constraints.md (the user's: plan D2), any dot-directory, and any instruction file (...); or README.md. Anything else is filed."

**Location:** `scripts/dev-cycle.sh:167-171`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers this comment's list against check_fix's refusals. It does not establish whether the omissions predate this diff (they do: the diff only added constraints.md to the list).

The comment's list is missing two refusals that the code makes. Files an instruction file imports are refused by `elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]; then echo "skip $a: an instruction file imports it with @ ..."` (`scripts/dev-cycle.sh:184-185`). Dotfiles are refused by `"$a" == */.*` (`:182`), but the comment names only "any dot-directory".
The help, the skip message and SKILL.md all list both. A precise version adds "dotfiles" and "a file an instruction file imports with @" to the comment.

**Evidence:** `scripts/dev-cycle.sh:167-186`

---

## Claim 8: "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats)."

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the named suites exist and source this lib or build-loop.sh. It does not establish that any CI or gate enforces the rule; it is a standing instruction.

`ls test/scripts` lists `build-loop-read.bats` as the only `build-loop-*.bats` file. It sets `BL="$REPO_ROOT/scripts/build-loop.sh"` through `test/lib/build-loop-fixtures.bash:10`, and build-loop.sh sources the lib (`scripts/build-loop.sh:92-95`).
The stale "once that second caller lands" is gone. Both suites ran (Claim 18).

**Evidence:** `scripts/lib/dev-cycle-read.sh:8-13`, `test/lib/build-loop-fixtures.bash:8-10`, `$FC/logs/build-loop-read.log`

---

## Claim 9: isclosed spells the closed/ brief rule once, for writable, check_brief and shared_branches (commit, row 292)

**Location:** `scripts/lib/dev-cycle-read.sh:159`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that `isbrief X || isclosed X` (and `isclosed` alone, inside writable) agrees with the three old spellings on 23 edge-case paths and by construction. It does not establish anything about inputs pathform refuses, since every caller runs pathform first or reads git's own listing.

New: `isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }` (`:159`).
`isbrief` anchors `^docs/working/briefs/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$` (`:158`). SLUG has no `/` and no uppercase, so after the prefix is stripped the rest must be exactly one dated, lower-case slug. That is the old writable / check_brief regex `^docs/working/briefs/closed/$DIGIT{4}-...-$SLUG\.md$` with its prefix factored out.
shared_branches' old `isbrief "${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}"` tested the same two cases (an open path as is, a closed/ path with the prefix stripped).
The probe compared the new form with all three old spellings on 23 paths: `closed/closed/...`, `closed/` alone, `closed` with no slash, `CLOSED/`, an uppercase slug, `.MD`, `closed//x`, a trailing `/`, a trailing or embedded newline, `2026-10-0closed/1-x.md`, a doubled prefix, a `*`, and others. It printed `differences=0`.
Command: `bash $FC/probe/isclosed.sh $FC/copy/scripts/lib/dev-cycle-read.sh`, cwd `$FC/probe`, exit 0, 2026-10-06T15:59:50Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:156-163,342`, `scripts/build-loop.sh:318`, `$FC/logs/isclosed.log`

---

## Claim 10: "\"badform\" (a path pathform refuses: a .git* part such as .gitattributes, say) or \"error\" (no default branch found by name, ls-tree failed, or the tree lists a name twice ...). Only blob reads the file, and only absent means there is none: every other word is a refusal."

**Location:** `scripts/lib/dev-cycle-read.sh:253-258`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_entry's words and every caller of it: check_brief, check_answer, brief_fields, main_file, and shared_branches and status_line through brief_fields/check_brief. Each one handles badform (and notfile/notdir/error) as a refusal, never as absent. It does not change, or clear, shared_branches' pre-existing `continue` past a brief that brief_fields refuses (row 308's concern, which applies to the future floor).

`if ! main_by_name; then echo error; return; fi` / `if ! pathform "$1"; then echo badform; return; fi` (`:266-267`; the enclosing main_entry continues to :280, read).
Probe output: `.gitattributes -> badform`, `.github/x.yml -> badform`, `a"b.md -> badform`, `docs/a.md -> blob`, `docs/missing.md -> absent`, and with MAIN_BY_NAME cleared `no-main .gitattributes -> error`.
How each caller handles the words:
- check_brief: `absent) echo "ok $a new"; return ;; blob) ;; *) echo "skip $a: $(entry_why "$e" "$a")"; return ;;` (`:349-353`). It also runs pathform first (`:341`), so badform cannot reach it.
- check_answer: `absent) continue ;; blob) ;; *) echo "skip $a: $(entry_why "$e" "$f"), so $f is not read"; return ;;` (`:567-571`), on fixed paths.
- brief_fields: `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`:310`). The probe printed `brief_fields .gitattributes rc=1 BRIEF_ODD=error`.
- main_file: see Claim 6.
- shared_branches: `if ! { isbrief "$f" || isclosed "$f"; } || ! brief_fields "$f"; then continue; fi` (`scripts/build-loop.sh:318`). Any isbrief/isclosed path passes pathform, so badform cannot occur there.

`continue` follows only `absent` (check_answer) or a brief_fields failure in F31's count (pre-existing). Nothing in this diff turns badform into a continue-to-ok.
Command: `bash $FC/probe/mainentry.sh $FC/copy/scripts/lib/dev-cycle-read.sh $FC/probe/repo $FC`, cwd `$FC/probe`, exit 0, 2026-10-06T15:59:59Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:249-280,305-328,337-374,561-587`, `scripts/build-loop.sh:126-141,306-324`, `$FC/logs/mainentry.log`

---

## Claim 11: "It runs main_by_name and pathform itself, before any read" (and, per the brief, badform is answered before any git call)

**Location:** `scripts/lib/dev-cycle-read.sh:258-260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_entry's own git calls for refused paths. It does not cover git calls made earlier by resolve_main.

`main_by_name` is pure shell: `[[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]` (`:248`). pathform is pure shell too (`:141-150`). The first git call is `git ls-tree` at `:269`.
With a logging `git` shim first on PATH, the probe counted cumulative git calls: `.gitattributes -> badform calls=0`, `.github/x.yml -> badform calls=0`, `a"b.md -> badform calls=0`, then `docs/a.md -> blob calls=1`.
The check order means a refused path with no main by name answers `error`, not `badform`. The comment's `error` list ("no default branch found by name") says so.

**Evidence:** `scripts/lib/dev-cycle-read.sh:248,263-269`, `$FC/logs/mainentry.log`

---

## Claim 12: entry_why words each main_entry word; "the default names an unknown word" (commit)

**Location:** `scripts/lib/dev-cycle-read.sh:281-289`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the text printed for each word. The default arm cannot be reached from any current caller: main_entry prints only blob/absent/notfile/notdir/badform/error (`:266-279`), and every caller handles blob and absent first. So the arm is defensive only. The `error` text "could not be read" is also used for a tree that lists a name twice, where it is imprecise; that wording predates this diff.

```
# scripts/lib/dev-cycle-read.sh:282-289
entry_why() {
  case "$1" in
    notdir\ *) echo "${1#notdir } is not a directory on the default branch" ;;
    notfile) echo "$2 is not a regular file on the default branch" ;;
    badform) echo "$2 is not an allowed path form" ;;
    error) echo "the tree of the default branch could not be read" ;;
    *) echo "the default branch answered $1 for $2" ;;
```
(excerpt ends :288; enclosing entry_why closes at :290, read.) The probe printed `entry_why[weird] = the default branch answered weird for P`, and the expected text for each of the other words.
Every caller checks main_by_name before main_entry (check_brief `:340`, check_answer `:564`, build-loop.sh `:120` exits). So `error` reaches entry_why only for an ls-tree failure or a doubled name, never for a missing main.

**Evidence:** `scripts/lib/dev-cycle-read.sh:263-290`, `$FC/logs/mainentry.log`

---

## Claim 13: check_brief and check_answer skip lines now read "<why>, so $f is not read" and name the path for notfile; no doc, help, SKILL.md or test quotes the old wording

**Location:** `scripts/lib/dev-cycle-read.sh:352`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers scripts/, skills/, test/, guides/, workflows/ and docs/ outside docs/reviews/ and archive/. Past review reports quote the old text as history; this verdict does not cover those.

`*) echo "skip $a: $(entry_why "$e" "$a")"; return ;;` (`:352`) and `*) echo "skip $a: $(entry_why "$e" "$f"), so $f is not read"; return ;;` (`:570`).
`rg -n "no entry in it is read|tree could not be read|default branch's tree|not a regular file on the default"` outside docs/reviews/ and archive/ finds only the new lib lines and tests that expect the new text. For example, `test/scripts/dev-cycle.bats:1195` expects `... is not a regular file on the default branch, so docs/working/questions.md is not read`, and `:1039` expects `skip docs/working/briefs/2026-01-01-s.md: docs/working/briefs/2026-01-01-s.md is not a regular file on the default branch`.
The `--check-answer` help (`scripts/dev-cycle.sh:66-68`) still describes these cases correctly in general terms. Lines like `so no entry in $f is read` at `:578-580` belong to the FENCE_AWK refusals, which this diff does not change.

**Evidence:** `scripts/lib/dev-cycle-read.sh:348-353,566-571,578-580`, `test/scripts/dev-cycle.bats:700,1039,1195,1223-1225`, `test/scripts/build-loop-read.bats:61,63,193`

---

## Claim 14: "An inherited GIT_DIR (a run from a git hook, say) would send every fixture command to that repo instead of the throwaway one." / commit: "bl_setup unsets GIT_DIR and the other repo-locating variables (314)"

**Location:** `test/lib/build-loop-fixtures.bash:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers GIT_DIR/GIT_WORK_TREE inherited by build-loop-read.bats, and confirms no test depends on those variables. It does not cover variables that are not repo-locating and are not cleared (GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT, GIT_NAMESPACE, GIT_CEILING_DIRECTORIES).

`unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES` (`:13`).
The probe exported `GIT_DIR`/`GIT_WORK_TREE` pointing at a scratch victim repo and ran `bats -f T4 test/scripts/build-loop-read.bats`. On 6f624cdf, 3 tests passed and the victim stayed at 1 commit (`before=1 after=1`). On main, all 3 failed and the victim grew to 8 commits (`before=1 after=8`).
`rg` finds no other mention of these variables in `test/scripts/build-loop-read.bats` or the fixture file, so no test relies on them.
Command: per copy, `GIT_DIR=$V/.git GIT_WORK_TREE=$V bats -f "T4" test/scripts/build-loop-read.bats`, cwd `$FC/copy` and `$FC/maincopy`, exit 0 and 1, 2026-10-06T16:00:58Z.

**Evidence:** `test/lib/build-loop-fixtures.bash:7-22`, `$FC/logs/gitdir-copy.log`, `$FC/logs/gitdir-maincopy.log`

---

## Claim 15: "A marker whose message body holds a NUL byte (one commit on top of base, with its tree)."

**Location:** `test/scripts/build-loop-read.bats:297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the object the next line builds. It does not establish whether that object is ahead of main (the test's `check` handles that).

`printf 'tree %s\nparent %s\n...' "$(git rev-parse "$base^{tree}")" "$base"` (`:298`). The commit has one parent, `base`, and base's tree. That is what the comment says ("its" = base's), and it closes row 318's wording.

**Evidence:** `test/scripts/build-loop-read.bats:297-301`

---

## Claim 16: commit: "the three fixture && chains split with a standalone git replace -d (317)" — a failed fixture step now fails the test

**Location:** `test/scripts/build-loop-read.bats:436-440`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three chains row 317 names (:436, :464, :469 at U1d; now :436-437, :466-468, :472-474). Only the :436 chain was mutated and run; the other two are judged by bats' errexit on simple commands. Other `&&` chains that remain (`git rm -q "$B" && commit_all rm-p` at :471, T4's `:84`) are outside row 317 and not covered.

The new form runs each step as its own command: `git replace "$(git rev-parse main:docs/dev-cycle.md)" "$(git hash-object -w x.md)"` / `git config core.useReplaceRefs true` / ... / `git replace -d "$(git rev-parse main:docs/dev-cycle.md)"` (`:436-440`).
A mutant pointed the replace at `main:docs/no-such.md`. On 6f624cdf the test failed (`not ok 1 --settings: deferred cases ...`, with ``git replace "$(git rev-parse main:docs/no-such.md)" ...' failed with status 255``). The same mutant on main's chained form passed (`ok 1 ...`), which is the vacuous pass row 317 describes.
The CRLF and closed-directory steps are now separate lines (`:466-468`, `:472-474`), so bats' errexit stops on any step that fails.
Commands: `bats -f "settings: deferred cases" test/scripts/build-loop-read.bats`, cwd `$FC/mut-copy` (exit 1) and `$FC/mut-maincopy` (exit 0), 2026-10-06T16:00:38Z.

**Evidence:** `test/scripts/build-loop-read.bats:432-441,463-475`, `$FC/logs/mutant-chain-copy.log`, `$FC/logs/mutant-chain-maincopy.log`

---

## Claim 17: commit: "main_entry's positive control (320)" — the `x` → absent line fails if main is not found by name

**Location:** `test/scripts/dev-cycle.bats:1335-1344`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers losing main-by-name, the failure row 320 names. It does not cover a fixture where main exists but `x` does too (that would give blob, so the test would also fail).

`for p in x "a\"b.md" "../x" "-x" "docs//x.md" .gitattributes .github/x.yml; do main_entry "$p"; done` expects `absent` and then six `badform` lines (`:1337-1344`).
A mutant inserted `git branch -q -m main trunk;` before `resolve_main`. The new test failed (`not ok 1 main_entry answers badform ...`). The old test with the same mutation passed (`ok 1 main_entry answers error ...`), so the old test could pass vacuously and the new `x` line closes that gap.
Command: `bats -f "main_entry answers" test/scripts/dev-cycle.bats`, cwd `$FC/mut-copy` (exit 1) and `$FC/mut-maincopy` (exit 0), 2026-10-06T16:00:38Z.

**Evidence:** `test/scripts/dev-cycle.bats:1335-1345`, `$FC/logs/mutant-posctl-copy.log`, `$FC/logs/mutant-posctl-maincopy.log`

---

## Claim 18a: commit: "Tests: dev-cycle.bats 73, build-loop-read.bats 19, hermeticity 2 pass." (counts, and every test this diff touches)

**Location:** commit 6f624cdf message
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the per-suite counts and passes for build-loop-read.bats (19/19), fixture-hermeticity.bats (2/2) and 72/73 dev-cycle.bats tests, including every test changed in this diff. Test 25 is not covered here (Claim 18b).

`grep -c '^@test'` gives `dev-cycle.bats:73`, `build-loop-read.bats:19` and `fixture-hermeticity.bats:2`. The runs gave `ok` counts of 72, 19 and 2. The one dev-cycle failure, `not ok 25 an origin/HEAD naming an option-like branch cannot make git write a file`, is not related to this diff (Claim 18b).
Commands: `bats test/scripts/dev-cycle.bats` (exit 1), `bats test/scripts/build-loop-read.bats` (exit 0), `bats test/fixture-hermeticity.bats` (exit 0), cwd `$FC/copy`, from 2026-10-06T15:58:00Z.

**Evidence:** `$FC/logs/dev-cycle.log`, `$FC/logs/build-loop-read.log`, `$FC/logs/hermeticity.log`, `$FC/logs/counts.log`

## Claim 18b: commit: dev-cycle.bats test 25 passes

**Location:** commit 6f624cdf message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers why test 25 could not run in this review sandbox. It does not establish that the test passes elsewhere.

The test creates `refs/heads/--output=$victim` with `$victim` under TMPDIR. The review's scratch path, `/home/node/.claude/...`, has a `.claude` component, so git refuses the ref name: `fatal: update_ref failed for ref 'refs/heads/--output=/home/node/.claude/jobs/.../victim.txt': refusing to update ref with bad name` (`test/scripts/dev-cycle.bats:437`).
main 900c47d0 fails the same way (`$FC/logs/main-test25.log`: `not ok 1 an origin/HEAD naming an option-like branch ...`), so the failure comes from the environment, not this diff. Blocker: the review rules confine scratch files to a dotted path. A TMPDIR with no `.`-leading component is needed to verify this test.

**Evidence:** `test/scripts/dev-cycle.bats:437`, `$FC/logs/dev-cycle.log`, `$FC/logs/main-test25.log`

---

## Claim 19: commit: "128 changed code lines."

**Location:** commit 6f624cdf message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers added plus deleted lines outside docs/ (the measure in log row 62, which skills/dev-cycle/SKILL.md falls under). It does not cover any other way of counting.

`git diff --numstat main...HEAD | awk '$3 !~ /^docs\// {s+=$1+$2} END {print s}'` printed `128`. That is 13 (build-loop.sh) + 12 (dev-cycle.sh) + 48 (lib) + 2 (SKILL.md) + 3 (fixtures) + 14 (build-loop-read.bats) + 36 (dev-cycle.bats). Exit 0, cwd the worktree, 2026-10-06T16:02:16Z.

**Evidence:** `$FC/logs/counts.log`

---

## Claim 20: commit: rows 306, 228, 292, 204, 319, 317, 318, 314, 320 are each addressed by the diff

**Location:** commit 6f624cdf message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers each cited row's revisit-trigger request against the diff. It does not cover rows the commit does not cite (308 stays open for the floor).

Rows 306 (badform word), 228 (one mapping), 292 (one spelling), 204 (constraints.md refused, with a plan note on docs/thoughts/), 317 (chains split, with a standalone `git replace -d`), 318 (T7 comment), 314 (unset) and 320 (`x` → absent) are each done (Claims 9-17).
Row 319 is not fully done. It names three residues: "the lib header's 'once that second caller lands' is stale since U1b, with short lines at :12, :14, :26", the build-loop copy paragraph's "a task box", and the LOOP paragraph's "level with main". The stale phrase and both build-loop wordings are fixed.
Two of the short lines remain in the new header: `# pipefail for themselves),` (`scripts/lib/dev-cycle-read.sh:13`) and `# with one printed line per argument that` (`:25`). The commit names only "the lib header's stale caller phrase (319)", so this is a partly addressed row rather than a false statement. A precise version says row 319's short-line residue is still open, or reflows :12-14 and :24-26.

**Evidence:** `docs/reviews/override-log.md:204,228,292,306,314,317-320`, `scripts/lib/dev-cycle-read.sh:10-27`

---

## Claim 21: commit: "these parts drew no red in U2a's three review iterations" and "(row 228; U2a iteration 2 architecture 4)"

**Location:** commit 6f624cdf message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every 🔴 row in the U2a rubric on feat/build-loop-u2a. It does not reread the individual U2a critic reports.

The rubric's 🔴 rows are R1 (`main_imports` start files / newline names), R2 (the walk's `seen` set), R3 (symlink text through `$(...)`) and R4 (`..x.md` names). All four are about the import walk that goes to U2a2.
The rows about U2a1's parts are all 🟡: `A3 | docs/constraints.md refuses ...`, `A9 | entry_why's catch-all words any unknown main_entry word as "could not be read" (row 306's misreport). | Minor | architecture 4 | 🟡 Fixed | Explicit error) arm; the default names the word.` and `A11 | badform's comment ...`.

**Evidence:** `feat/build-loop-u2a:docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:13,16,40,45,47,62-64,74`

---

## Claim 22: commit: "the lib's check_fix keeps reading the IMPORTED cache until U2a2's isimported."

**Location:** commit 6f624cdf message
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers where check_fix lives and what it reads. It does not cover `isimported`, which does not exist on this branch (U2a2 is future work).

check_fix is defined in `scripts/dev-cycle.sh`, not in the lib: `check_fix() {` (`scripts/dev-cycle.sh:172`). It reads the lib's cache: `imported_names` (`:179`) and `elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]; then` (`:184`). `IMPORTED` is defined at `scripts/lib/dev-cycle-read.sh:442`.
`rg -n "check_fix" scripts/lib/dev-cycle-read.sh` returns no definition (paraphrased, no quote available because the claim is about the absence of code). The mechanism is right; only the location is wrong. A precise version is "dev-cycle.sh's check_fix keeps reading the lib's IMPORTED cache".

**Evidence:** `scripts/dev-cycle.sh:172-186`, `scripts/lib/dev-cycle-read.sh:442-474`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 7b** (`scripts/dev-cycle.sh:167-171`): the comment above check_fix does not list imported files or dotfiles, which the code refuses (`:182`, `:184-185`). Add both, to match the help and SKILL.md.
- **Claim 20** (commit 6f624cdf): row 319's short-line residue is still open (`scripts/lib/dev-cycle-read.sh:13`, `:25`). Reflow those lines or carry the residue forward.
- **Claim 22** (commit 6f624cdf): check_fix is in `scripts/dev-cycle.sh:172`, not the lib. It reads the lib's IMPORTED cache (history; the note is wording only).

### Unverifiable
- **Claim 18b** (commit 6f624cdf): dev-cycle.bats test 25 cannot run under a TMPDIR with a `.claude` component (bad ref name; main fails the same way). It needs a run with a non-dotted TMPDIR.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to docs/reviews/code-fact-check-report-build-loop-u2a1.md (inside the worktree), structured per the code-fact-check skill, with `Commit: 6f624cdf` as its first line and `**Replication:** k=1 (loop pass, decision 031)` in its header.
- Answered: yes. All nine focus areas are verdicted, with executed probes for the behavioural ones.
- Out of scope: the U2a2/U2b/U2c plan bullets (future work), and shared_branches' pre-existing `continue` on refused briefs (row 308, for the floor).
- Escalate: the dev-cycle.bats test 25 run needs a non-dotted TMPDIR before merge, if the gate requires a full 73/73 observed in this session.
- Decisions I made: counted "code lines" as all +/- lines outside docs/ (log row 62's measure); graded the row-319 residue Mostly accurate rather than Incorrect, because the commit cites only the stale phrase for 319.
