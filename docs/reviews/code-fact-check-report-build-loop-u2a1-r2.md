Commit: d48f4645

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a1, branch feat/build-loop-u2a1)
**Scope:** branch diff `git diff main...HEAD` (main 900c47d0 .. d48f4645): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, docs/working/plan-build-loop-handoff.md, docs/working/questions.md (Q-119), the rubric `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md`, the five new 2026-10-06 `feat/build-loop-u2a1` rows in docs/reviews/override-log.md, and the messages of 6f624cdf, 706e0499 and d48f4645. Other docs/reviews/*.md artifacts were not checked.
**Replication:** replicate r2 of three (final confirming pass)
**Checked:** 2026-10-06
**Total claims checked:** 34
**Summary:** 28 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance. `FC=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-final/fc2`. Executed claims ran against
`git archive` exports: d48f4645 in `$FC/copy`, main 900c47d0 in `$FC/maincopy`, 6f624cdf in `$FC/c1`. They ran with
`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, TMPDIR `$FC/tmp`, or a `/tmp/u2a1fc-XXXX` dir (deleted after) for runs that include
dev-cycle.bats test 25, each under `timeout`. Probe scripts are in `$FC/bin/`, and output was captured to `$FC/logs/`, with a UTC timestamp on
each log's first line. Runs took place 2026-10-06T16:19Z-16:30Z. No process was left running.

Hallucination-pattern log consulted (`docs/reviews/hallucination-patterns.md`). Claims 3, 28 and 31 (per-suite test tallies in
commit messages and the rubric) belong to the class of the logged patterns "All 85 tests ... claimed in commit 59ca38f" and
"mode1-equiv 33 claimed in commit 37c5ea9". This time every count matches.

---

## Claim 1: "Executed: badform with 0 git calls; isclosed equal to all three old spellings on 23 edge cases; the positive control and the split chains each fail their mutants."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers this replicate's own re-run of each of the four probes at d48f4645, with its own mutants and cases. It does not re-run iteration 1's original commands.

`$FC/bin/probe.sh` (cwd `$FC/tmp/probe`, exit 0, 2026-10-06T16:21:50Z) put a logging `git` shim first on PATH. It printed
`badform` for `.gitattributes`, `.github/x.yml`, `../x`, `a<LF>b` and `docs//x.md`, then `git calls during badform probes: 0`. Probe 2
compared `isclosed`, `isbrief || isclosed`, and `writable` against the three old spellings on 23 paths and printed `cases=23 mismatches=0`.
The mutants are in Claim 27.

**Evidence:** `scripts/lib/dev-cycle-read.sh:262-266`, `$FC/logs/probes.log`, `$FC/bin/probe.sh`

---

## Claim 2: "A1 ... setup() did not clear an inherited `GIT_DIR`: executed, the suite wrote 2 commits and branch f1 into a victim repo ... ✅ Fixed: both setups run `unset $(git rev-parse --local-env-vars)`; checked, the victim keeps 1 commit"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers GIT_DIR (with GIT_INDEX_FILE) pointed at a victim for both full suites at d48f4645, plus a mutant with the unset line removed. It does not re-run the security reviewer's filtered command, which produced the "2 commits and branch f1" figure.

The fixed run exported `GIT_DIR=$FC/victim/.git GIT_INDEX_FILE=$FC/victim/.git/index` and ran both suites in `$FC/copy`.
Logged: `before: 1 commits, refs: refs/heads/main` and `after: 1 commits, refs: refs/heads/main`. The only failure was dev-cycle test 25
(the dotted-TMPDIR environmental case). In the mutant, `sed` deleted the `unset $(git rev-parse --local-env-vars)` line from both setups
(copy `$FC/mut1`). That run logged `after dc: 81 commits` and `after bl: 153 commits, 6 refs`, so both suites write into an inherited GIT_DIR without the line.
The rubric's "2 commits and branch f1" quotes the security report, whose command was filtered to one test:
`bats -f 'check-fix refuses files an instruction file imports' ... the victim afterwards held 3 commits and a new branch f1`
(`docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a1.md:63`).

**Evidence:** `test/scripts/dev-cycle.bats:11-13`, `test/lib/build-loop-fixtures.bash:11-15`, `$FC/logs/victim.log`, `$FC/logs/victim-mutant.log`

---

## Claim 3: "Tests after the fixes: 95/95 (dev-cycle 74 with the new entry_why test, build-loop-read 19, hermeticity 2); shellcheck clean. Size after the fixes: 165 changed code lines."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers d48f4645's three suites, shellcheck on the four edited shell files, and the brief's line-count command. It does not cover other suites in the repo.

`$FC/logs/suites.log` (cwd `$FC/copy`, 2026-10-06T16:19Z) shows `1..74` with only `not ok 25`, then `1..19` with `exit=0` and `1..2` with `exit=0`.
Test 25 was re-run alone under `/tmp/u2a1fc-XXXX` and logged `ok 1 an origin/HEAD naming an option-like branch cannot make git write a file`
and `exit=0` (`$FC/logs/t25.log`, 16:19:33Z). That makes 74+19+2 = 95.
`shellcheck scripts/build-loop.sh scripts/dev-cycle.sh scripts/lib/dev-cycle-read.sh test/lib/build-loop-fixtures.bash` (0.9.0, worktree)
exited 0 with no output. `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` printed `165`.

**Evidence:** `$FC/logs/suites.log`, `$FC/logs/t25.log`

---

## Claim 4: "rows 228, 292, 306, 314, 317-320 are Defer rows whose triggers this unit meets, and the diff addresses each"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:17`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that "row N" means line N of override-log.md and that each row's subject has a matching hunk. It does not cover whether row 319's short-line residue is fully reflowed (Claim 33).

Row numbers are line numbers. `sed -n 228p` gives "check_brief and check_answer each copy a case block for main_entry's result words",
292 gives "The closed/ path rule is spelled three ways", 306 gives "main_entry's `error` now also means \"a path pathform refuses\"",
and 314 gives "`bl_setup` does not clear an inherited `GIT_DIR`". 317 is the three fixture `&&` chains, 318 T7's comment,
319 the wording residues and 320 "The main_entry test has no positive control". The matching hunks are `entry_why` (`scripts/lib/dev-cycle-read.sh:283`),
`isclosed` (`:158`), `if ! pathform "$1"; then echo badform; return; fi` (`:266`), the unset (`test/lib/build-loop-fixtures.bash:15`),
the split chains (`test/scripts/build-loop-read.bats:436-440`, `:466-468`, `:473-475`), the T7 comment (`:297`), the header edits and the `x` → `absent` control
(`test/scripts/dev-cycle.bats:1358`).

**Evidence:** `docs/reviews/override-log.md:228,292,306,314,317-320`

---

## Claim 5: "Commit 6f624cdf's Notes say 'the lib's check_fix keeps reading the IMPORTED cache'; check_fix is in scripts/dev-cycle.sh and reads the lib's cache"

**Location:** `docs/reviews/override-log.md:321`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the location of check_fix and its read of IMPORTED. It does not cover U2a2's planned isimported.

`check_fix() {` is at `scripts/dev-cycle.sh:170`. `elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]; then` is at `:182`, after
`imported_names` (`:176`). `rg -n "check_fix" scripts/lib/dev-cycle-read.sh` finds no definition (paraphrased, no quote available because the claim is about absent code).

**Evidence:** `scripts/dev-cycle.sh:170-184`

---

## Claim 6: "Row 204 is closed only in the plan text: check_fix adds constraints.md inline while U2a2's floor will list constraints.md, decisions/ and human-author/ again in the lib (architecture F1, `scripts/dev-cycle.sh:181-183`)"

**Location:** `docs/reviews/override-log.md:322`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the inline test, the plan's floor item 4, and the line range at 6f624cdf, which is the commit iteration 1 reviewed. It does not establish what U2a2 will build. At d48f4645 the same lines are `:179-181`, because d48f4645 shortened the comment above by two lines.

`|| "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || ...` (`scripts/dev-cycle.sh:180`). Plan floor item 4 reads
"files the cycle and later loops read as truth ...: the cycle-owned files ..., `docs/constraints.md`, `docs/decisions/`, `docs/thoughts/`, `docs/human-author/`"
(`docs/working/plan-build-loop-handoff.md:72`). `git show 6f624cdf:scripts/dev-cycle.sh | sed -n 181,183p` gives the `elif` test, its
continuation and the skip echo.

**Evidence:** `scripts/dev-cycle.sh:178-181`, `docs/working/plan-build-loop-handoff.md:72`

---

## Claim 7: "Three call sites write `isbrief X || isclosed X` themselves (lib writable, check_brief; build-loop.sh shared_branches)"

**Location:** `docs/reviews/override-log.md:323`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three sites. check_brief writes the negated form. It does not establish that no other site exists in unchanged files, beyond the grep below.

The three sites are `... ]] || isbrief "$1" || isclosed "$1"` (`scripts/lib/dev-cycle-read.sh:161`), `if ! isbrief "$a" && ! isclosed "$a"; then` (`:344`), and
`if ! { isbrief "$f" || isclosed "$f"; } || ! brief_fields "$f"; then continue; fi` (`scripts/build-loop.sh:318`). `rg -n isclosed scripts`
finds only these sites and the definition (paraphrased, no quote available because this summarises a grep listing).

**Evidence:** `scripts/lib/dev-cycle-read.sh:158-162,344`, `scripts/build-loop.sh:318`

---

## Claim 8: "so `.github/x.yml` is refused under D5's dot rule rather than as badform" (its premise: main_entry answers badform for `.github/x.yml`)

**Location:** `docs/reviews/override-log.md:324`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers today's main_entry answer for `.github/x.yml` and `.gitattributes`. It does not cover the future floor's ordering, which is a plan.

`$FC/logs/probes.log` shows `.github/x.yml -> badform` and `.gitattributes -> badform`. The cause is pathform's
`"$c" != [.][gG][iI][tT]*` (`scripts/lib/dev-cycle-read.sh:146`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:140-148,262-266`, `$FC/logs/probes.log`

---

## Claim 9: "entry_why adds one subshell (~0.3 ms) per refused argument, and isclosed costs ~17 µs more per brief pair in shared_branches than the old substitution"

**Location:** `docs/reviews/override-log.md:325`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers this machine's micro-timings on three runs. It does not cover the row's "suite delta within run-to-run noise", which would need repeated full-suite timings.

`$FC/bin/perf.sh` was run three times (2026-10-06T16:22:55Z, exit 0). It printed `entry_why in $(...) per call: 523 us`, `417 us` and `435 us`, and
for one closed path plus one open path, `delta 19.6 us`, `19.1 us` and `21.1 us`. Both figures are the right order of magnitude, and the
conclusion ("refusal paths ... already start git") is unaffected. The numbers are about 0.4-0.5 ms and about 20 µs on this host, not 0.3 ms and 17 µs.
Timings depend on load.

**Evidence:** `scripts/lib/dev-cycle-read.sh:158,283-292`, `$FC/logs/perf.log`, `$FC/bin/perf.sh`

---

## Claim 10: "U2a1: `main_entry`'s `badform` word with one shared reason mapping, `entry_why` (rows 228, 306); one spelling of the closed/ rule, `isclosed` (row 292); `check_fix` also refuses `docs/constraints.md` (row 204: the user writes it, D2; `docs/thoughts/` stays fixable in-cycle ..., so `check_fix` and the floor differ there on purpose)"

**Location:** `docs/working/plan-build-loop-handoff.md:274`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the match between the bullet and the diff, and the bullet's citation of D2. It does not cover the U2a2/U2b/U2c bullets, which describe future work.

D2 says of the constraints doc: "Creating the doc is your work" (`docs/working/plan-build-loop-handoff.md:50`). Floor item 4 lists `docs/thoughts/`
(`:72`), and check_fix answers `ok docs/thoughts/t.md` (Claim 15). The other named pieces are at `scripts/lib/dev-cycle-read.sh:158`, `:266` and `:283`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:50,72,273-279`

---

## Claim 11: "Split recorded in the U2a rubric and commit e8f76379 on `feat/build-loop-u2a`"

**Location:** `docs/working/questions.md:390`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the commit and rubric exist and record a split. It does not judge the split, which Q-119 leaves to the user.

`git log -1 --format='%h %s' e8f76379` printed `e8f76379 docs(reviews): U2a iteration 3 (final pass, k=3) and the iteration-4 gate decision: split`,
and `git branch --contains` lists `feat/build-loop-u2a`. That branch's rubric has `### Iteration-4 gate decision: \`split\`` (line 69) and
"**U2a1** (`feat/build-loop-u2a1`, from main, fresh loop)" (line 74).

**Evidence:** `feat/build-loop-u2a:docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:69-74`

---

## Claim 12: "Markup that adds letters (a checked task box, a tag) can still hide a copy; only an exact line ever sets a value."

**Location:** `scripts/build-loop.sh:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the checked-box versus unchecked-box contrast (the edit). It does not re-test the unchanged "a tag" example.

`s = tolower($0); gsub(/[^a-z]/, "", s); ... if (index(s, "buildlooppolicy") == 1) k = "policy"` (`scripts/build-loop.sh:155-157`).
`$FC/bin/probe4.sh` (2026-10-06T16:22:16Z, exit 0) used an exact `Build-loop policy: review` plus `- [x] Build-loop policy: self-merge`,
and the output was `policy review set: line 1`, so the copy was hidden. With `- [ ]` it was `policy review unset: more than one line starts "Build-loop policy:" (lines 1 and 3)`.

**Evidence:** `scripts/build-loop.sh:150-165`, `$FC/logs/probe4.log`

---

## Claim 13: "A tip on a branch not ahead of main, or whose subject does not start 'handoff:', is working."

**Location:** `scripts/build-loop.sh:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a branch behind main whose tip is a `handoff: ready` commit. It does not re-test the subject rule, which is unchanged.

`loop=working` then `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`scripts/build-loop.sh:352-353`; status_line continues to `:363` — read).
`$FC/bin/probe3.sh` (16:22:05Z) logged `ahead: 0` for the `handoff: ready` tip and printed `ok ... open review feat/x working eed3c6cf... 2026-10-06 0`.

**Evidence:** `scripts/build-loop.sh:325-363`, `$FC/logs/probe3.log`

---

## Claim 14: main_file returns 1 "with FILE_WHY 'absent' or why it was not read (main_entry, ...)"; every main_entry word but blob/absent becomes `entry_why "$e" "$f"`

**Location:** `scripts/build-loop.sh:122-134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_file and its two callers in read_settings. It does not cover badform reaching it, which cannot happen because both paths are the literals `docs/dev-cycle.md` and `docs/constraints.md`.

```bash
# scripts/build-loop.sh:130-134
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
  esac
```
(excerpt ends :134; enclosing main_file() continues to :141 — read). Its consumers print the reason without naming the file again:
`why="$FILE_WHY"` → `POLICY_LINE="policy review unset: $why"` (`:214-215`), and `CONSTRAINTS_LINE="constraints unreadable: $FILE_WHY"` (`:265`).
So `"$f"` is the right argument here. Each non-absent refusal sets `never malformed` or `constraints unreadable` (`:217`, `:265`).

**Evidence:** `scripts/build-loop.sh:122-141,206-266`

---

## Claim 15: "--check-fix 'ok <path>' for ... a tracked .md file under docs/ (not ... dev-cycle.md, constraints.md, a dot-directory or dotfile ...; compared ignoring case)"

**Location:** `scripts/dev-cycle.sh:49-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers constraints.md in two cases, a nested `constraints.md`, and docs/thoughts/. It does not re-test the unchanged exclusions.

`$FC/bin/probe2.sh` (16:21:57Z, exit 0) printed `skip docs/constraints.md: in-cycle fixes edit only ...` and
`skip docs/CONSTRAINTS.md: ...`, then `ok docs/thoughts/t.md`, `ok docs/sub/constraints.md` and `ok docs/notes.md`. The rule is
`"$lp" == docs/constraints.md` on the lower-cased path (`scripts/dev-cycle.sh:180`). The suite's own test checks `docs/Constraints.md` and
`docs/thoughts/t.md` (`test/scripts/dev-cycle.bats:1019-1029`), and it passed in Claim 3.

**Evidence:** `scripts/dev-cycle.sh:170-184`, `$FC/logs/probe2.log`

---

## Claim 16: "An in-cycle fix edits documentation only; the header's --check-fix paragraph is the rule, and the skip message below repeats it. constraints.md is the user's (plan D2); docs/thoughts/ stays fixable."

**Location:** `scripts/dev-cycle.sh:167-169`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the comment against the header paragraph, the three skip messages and the code. It does not cover SKILL.md (Claim 23).

The header paragraph and code agree (Claim 15). The skip message "below" repeats only part of the rule:
`(not working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, dot-directories or dotfiles, or instruction files)` (`:181`).
The header's "the cycle's own files" and "a file an instruction file imports with @" have separate messages:
`one of the cycle's own files (use --check-write)` (`:178`) and `an instruction file imports it with @` (`:183`). A precise version is "the
skip messages below repeat it".

**Evidence:** `scripts/dev-cycle.sh:49-54,167-184`

---

## Claim 17: "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats)."

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the named suites exist and reach this lib. It does not establish that any gate enforces the rule.

`ls test/scripts` lists `build-loop-read.bats` as the only `build-loop-*` file (paraphrased, no quote available because this is a directory listing).
It loads `test/lib/build-loop-fixtures.bash`, which sets `BL="$REPO_ROOT/scripts/build-loop.sh"` (`:10`), and build-loop.sh sources the lib.

**Evidence:** `test/lib/build-loop-fixtures.bash:10`, `scripts/build-loop.sh:92-95`

---

## Claim 18: isclosed spells the closed/ brief rule once and equals the three old spellings (writable's regex, check_brief's regex, shared_branches' prefix substitution)

**Location:** `scripts/lib/dev-cycle-read.sh:158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 23 edge paths, including a newline-terminated path, `closed//`, `closed/closed/`, an upper-case slug, `Closed/`, a trailing `/`, a literal `*` and `2026-10-0closed/`, and also covers equivalence by construction. It does not cover a caller shell with `nocasematch` set, which would change the old and new forms alike.

`isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }`. isbrief's
`$SLUG` (`[abcdefghijklmnopqrstuvwxyz0123456789-]+`) has no `/`, so the remainder must be exactly `DATE-SLUG.md`, which is the old anchored regex.
For shared_branches, `isbrief f || isclosed f` equals `isbrief "${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}"`.
`$FC/logs/probes.log` shows `cases=23 mismatches=0` across isclosed against the old regex, the shared_branches forms, and old against new `writable`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:155-162`, `$FC/logs/probes.log`

---

## Claim 19: main_entry prints "badform" (a path pathform refuses: a .git* part such as .gitattributes, say) ... "It runs main_by_name and pathform itself, before any read"

**Location:** `scripts/lib/dev-cycle-read.sh:252-258`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the word, its example and that no git process starts before it. It also covers precedence: with no main found by name, a refused path answers `error`, not `badform`. The comment implies this order ("main_by_name and pathform"), but it does not state it.

```bash
# scripts/lib/dev-cycle-read.sh:265-267
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
```
(excerpt ends :267; enclosing main_entry() continues to :279 — read; its first git call is `git ls-tree` at :268). `main_by_name` is a
variable test (`[[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]`, `:247`). Probe 1 logged `git calls during badform probes: 0` and
`.gitattributes (main not by name) -> error`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:247-279`, `$FC/logs/probes.log`

---

## Claim 20: "Only blob reads the file, and only absent means there is none: every other word is a refusal." (and every caller treats it so)

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every main_entry caller in scripts/ (four) and the two build-loop paths that reach it through them. It does not cover callers outside scripts/; `rg main_entry` finds only tests and docs there.

- `check_brief`: `absent) echo "ok $a new"`, `blob) ;;`, then `*) echo "skip $a: $(entry_why "$e" "")"; return ;;` (`:352-354`).
- `check_answer`: `absent) continue ;;` and `blob) ;;`, with both other arms `echo "skip $a: ..."; return` (`:570-574`).
- `brief_fields`: `[[ "$(main_entry "$1")" != blob ]]` → `BRIEF_ODD=error; return 1` (`:312`).
- `main_file`: the same shape (Claim 14).
- `status_line` passes only `ok ` lines from check_brief (`[[ "$out" == "ok "* ]] || { echo "$out"; return; }`, `scripts/build-loop.sh:328`) and refuses on a failed brief_fields (`:332`).
- `shared_branches` reaches main_entry only through brief_fields. On a refusal it runs `continue` (`:318`), so the brief is not counted. That is the pre-existing row-308 behaviour, and the floor's concern, not this claim's.

**Evidence:** `scripts/lib/dev-cycle-read.sh:312,350-355,568-575`, `scripts/build-loop.sh:126-134,306-332`

---

## Claim 21: "$2 is the path, named in the reason; pass \"\" when the skip line already names it. A newline in either becomes a space, so the reason stays one line."

**Location:** `scripts/lib/dev-cycle-read.sh:280-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers all five arms with and without a path, and a newline in the path through the suite test. A newline in the word is covered by reading the code only (`w="${1//$'\n'/ }"`), since no test feeds one. It does not cover callers (Claims 14, 22).

`local w="${1//$'\n'/ }" p="${2//$'\n'/ }"` (`:284`), and each arm uses `${p:+$p is }` or `${p:+ for $p}` (`:286-290`). Every arm is a single
`echo`. The suite test (`test/scripts/dev-cycle.bats:1338-1354`) asserts ten lines and `a ok b is not an allowed path form`, and it passed (Claim 3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:280-292`, `test/scripts/dev-cycle.bats:1338-1354`

---

## Claim 22: check_brief's and check_answer's skip lines name each path once; "\"it\" is $f, except after notdir, whose reason names a directory above it."

**Location:** `scripts/lib/dev-cycle-read.sh:572`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the notfile, notdir and error lines that the suite asserts exactly. It does not cover badform at these callers, which cannot happen: check_brief runs pathform first (`:343`), and check_answer's two paths are literals.

`notdir\ *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"` and `*) echo "skip $a: $(entry_why "$e" "$f"), so no entry in it is read"` (`:573-574`).
The suite asserts these exact lines and passes (Claim 3):
- `skip Q-1: docs/working is not a directory on the default branch, so no entry in docs/working/questions.md is read` (`test/scripts/dev-cycle.bats:1203`)
- `... docs/working/questions.md is not a regular file on the default branch, so no entry in it is read` (`:1198`)
- `... could not be read for docs/working/questions.md, so no entry in it is read` (`:1327`)
- for check_brief: `skip docs/working/briefs/2026-01-01-s.md: not a regular file on the default branch` (`:1042`)

A grep for the old wordings ("so docs/working/questions.md is not read", "the default branch's tree") over scripts, skills, test and the plan finds none.

**Evidence:** `scripts/lib/dev-cycle-read.sh:339-355,563-576`, `test/scripts/dev-cycle.bats:1042,1198,1203,1327`

---

## Claim 23: SKILL.md: --check-fix prints ok for "a tracked `.md` file under `docs/` (not ... `docs/dev-cycle.md`, `docs/constraints.md`, a dot-directory or dotfile, ...)"

**Location:** `skills/dev-cycle/SKILL.md:72-78`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers agreement with the header and the code (Claim 15). It does not cover the rest of SKILL.md.

The SKILL.md list (`:73-77`) matches the header's (`scripts/dev-cycle.sh:51-53`) item for item, with `docs/` prefixes.

**Evidence:** `skills/dev-cycle/SKILL.md:72-78`, `scripts/dev-cycle.sh:49-54`

---

## Claim 24: "a throwaway repo ... with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the git-facing setup. It does not mean the two setups are identical: bl_setup also exports `LC_ALL=C` (`:19`), which dev-cycle.bats' setup does not.

Both setups now run `unset $(git rev-parse --local-env-vars)` (`build-loop-fixtures.bash:15`, `dev-cycle.bats:13`). Both export
`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` and the same author and committer pairs, and both set HOME under `$BATS_TEST_TMPDIR`
(`dev-cycle.bats:14-19`, `build-loop-fixtures.bash:16-19`).

**Evidence:** `test/lib/build-loop-fixtures.bash:7-23`, `test/scripts/dev-cycle.bats:8-23`

---

## Claim 25: "An inherited GIT_DIR (a run from a git hook, say) would send every fixture command to that repo ...; git lists every such repo-local variable itself (GIT_CONFIG_PARAMETERS too)." / "As bl_setup: an inherited GIT_DIR would send fixture commits to that repo."

**Location:** `test/lib/build-loop-fixtures.bash:11-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5's list, the command working under a bogus GIT_DIR, the protection in both suites, and that nothing in the suites needs an inherited variable. GIT_CONFIG_KEY_n and VALUE_n are not in the list, but they are inert once GIT_CONFIG_COUNT is unset.

`git rev-parse --local-env-vars` printed 16 names, including `GIT_DIR`, `GIT_INDEX_FILE`, `GIT_CONFIG_PARAMETERS` and `GIT_CONFIG_COUNT`. It printed the
same list with `GIT_DIR=/nonexistent`, with exit 0. The victim runs are in Claim 2. The only GIT_CONFIG_COUNT uses in the suites set it per command:
`run --separate-stderr env GIT_CONFIG_COUNT=1 ... bash "$BL" --settings` (`test/scripts/build-loop-read.bats:438`, `:483`). Both suites
pass under the unset (Claim 3).

**Evidence:** `test/lib/build-loop-fixtures.bash:11-15`, `test/scripts/dev-cycle.bats:11-13`, `$FC/logs/victim.log`, `$FC/logs/victim-mutant.log`

---

## Claim 26: "A marker whose message body holds a NUL byte (one commit on top of base, with its tree)."

**Location:** `test/scripts/build-loop-read.bats:297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the hand-built object's tree and parent lines. It does not cover the test's other objects.

`printf 'tree %s\nparent %s\n...' "$(git rev-parse "$base^{tree}")" "$base"` (`:298`): base's tree, with base as the parent.

**Evidence:** `test/scripts/build-loop-read.bats:297-300`

---

## Claim 27: Each new or changed test fails when the behaviour it pins is reverted (entry_why newline and empty path, the x→absent positive control, the three split fixture chains)

**Location:** `test/scripts/dev-cycle.bats:1338-1366`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers seven single-line mutants, each run with `bats -f` on its own test via `$FC/bin/mut.sh` against a fresh copy of `$FC/copy`, at 2026-10-06T16:21:08-10Z. It does not cover the `:84` replace chain, which row 317 did not list and which stays guarded by its own `git replace -d` at `:85`.

Each mutant gave `0 ok, 1 not ok, exit=1`, and each log shows the expected cause:

| Mutant | Change | Result |
|---|---|---|
| nl | `local w="$1" p="$2"` | the output splits into `a` / `ok b is not an allowed path form` |
| emptyp | notfile arm uses `$p is` | output ` is not a regular file ...` |
| ctrl | `if true \|\| ! pathform` | seven `badform`; only the `x` line catches it |
| ctrl0 | the badform arm prints `error` | `absent` then six `error` |
| repl | `git replace --bogus` | fails at `:436` with status 129 |
| crlf | the CRLF write goes to `/nonexistent/x` | fails at `:467` |
| odddir | the odd-dir write goes to `/nonexistent/1-x.md` | fails at `:474` |

**Evidence:** `test/scripts/dev-cycle.bats:1338-1366`, `test/scripts/build-loop-read.bats:434-440,465-475`, `$FC/logs/mut-{nl,emptyp,ctrl,ctrl0,repl,crlf,odddir}.log`, `$FC/bin/mut.sh`

---

## Claim 28: 6f624cdf: "Tests: dev-cycle.bats 73, build-loop-read.bats 19, hermeticity 2 pass. 128 changed code lines."

**Location:** commit 6f624cdf
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three suites at 6f624cdf, run under a non-dotted TMPDIR, and the line count for main..6f624cdf. It does not cover the other bullets, which later claims cover or which d48f4645 superseded.

`$FC/logs/c1-suites.log` (cwd `$FC/c1`, 2026-10-06T16:24:06Z) shows `1..73` with exit 0, `1..19` with exit 0, and `1..2` with exit 0.
`git diff --numstat main 6f624cdf -- ':(top)' ':(top,exclude)docs/' | awk ...` printed `128`.

**Evidence:** `$FC/logs/c1-suites.log`

---

## Claim 29: 6f624cdf Notes: "the lib's check_fix keeps reading the IMPORTED cache until U2a2's isimported"

**Location:** commit 6f624cdf
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers where check_fix is defined. The commit is immutable, and override-log.md:321 already records this as Accepted-immutable.

check_fix is defined at `scripts/dev-cycle.sh:170`, not in the lib. It reads the lib's `IMPORTED` at `:182`. The mechanism is right and the file is wrong.

**Evidence:** `scripts/dev-cycle.sh:170-184`, `docs/reviews/override-log.md:321`

---

## Claim 30: 706e0499: "0 Must Fix; 1 Medium (dev-cycle.bats inherits GIT_DIR), 1 Low, 4 Minor, mostly wording. Four declined findings get override rows (C1-C4), and row 204 is closed by C1's row."

**Location:** commit 706e0499
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the commit's tally against the rubric table. It does not judge the severities themselves.

The rubric's A rows are as follows. A1 is `Medium`, and A2 is `Low`. A3 is `Minor`. A4 is `Minor, Informational`, and A5 is `Mostly accurate, Minor, Informational`.
A6 is `Mostly accurate` with source `fact-check`, so it is not a Minor-severity finding (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21-26`).
"4 Minor" is really 3 Minor plus 1 fact-check Mostly accurate. C1-C4 do have four override rows (`docs/reviews/override-log.md:322-325`), and C1's row says
"This row closes 204". The commit does not mention the fifth new row, the Accepted-immutable one at `:321`.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21-34`, `docs/reviews/override-log.md:321-325`

---

## Claim 31: d48f4645: "Tests: dev-cycle.bats 74 ..., build-loop-read.bats 19, hermeticity 2, all pass; test 25 passes run with a TMPDIR that has no dot-prefixed part. shellcheck clean. 165 changed code lines against main."

**Location:** commit d48f4645
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** The same runs as Claim 3. They do not cover other suites.

See Claim 3: 74 (73 plus test 25 run separately), 19 and 2 all pass, shellcheck exits 0, and the line count is `165`.

**Evidence:** `$FC/logs/suites.log`, `$FC/logs/t25.log`

---

## Claim 32: d48f4645: "With GIT_DIR pointing at a victim repo, the suite no longer writes into it (checked: 1 commit before and after)."

**Location:** commit d48f4645
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** The same runs as Claim 2.

Logged: `before: 1 commits` and `after: 1 commits` across both full suites, against 80 and 72 more commits in the mutant without the unset.

**Evidence:** `$FC/logs/victim.log`, `$FC/logs/victim-mutant.log`

---

## Claim 33: d48f4645: "A6: the lib header's short lines reflowed (row 319's residue)." (rubric A6: "✅ Fixed: reflowed")

**Location:** commit d48f4645
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers line lengths in the lib header (`:8-32`) at d48f4645 against main. It is wording only, with no behaviour.

Row 319 named "short lines at :12, :14, :26". On main those lines were 36, 18 and 41 characters, and all three are gone.
One short line remains: `:25` is `# scrub, read it as \`out="$(check_brief ...)"\` under`, at 52 characters. The reflow also left `:16` at 96 characters
(`# ROOT_REAL is set, is the current directory and is a repository's top level; while ROOT_REAL is`), where its neighbours are 70 to 79.
Lengths were measured with `awk '{print length($0)}'` (paraphrased, no quote available because this summarises per-line lengths).

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-27`, `docs/reviews/override-log.md:319`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:26`

---

## Claim 34: d48f4645 Notes: "the old, pre-U2a1 sentences come back except where a path is now named."

**Location:** commit d48f4645
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the reason lines of check_brief, check_answer and main_file on main against d48f4645. It is wording only.

Most of these lines match main exactly. Two differ, although neither names a new path:
- check_answer's notdir line was `..., so $f is not read` on main (`git show 900c47d0:scripts/lib/dev-cycle-read.sh`, the old `notdir\ *)` arm in check_answer). It is now `..., so no entry in $f is read` (`scripts/lib/dev-cycle-read.sh:573`).
- main_file's error reason was `the default branch's tree could not be read for $f` on main. It is now `the tree of the default branch could not be read for $f`, through entry_why's `error` arm (`:289`).

Both changes come from the shared mapping and the sibling wording, so they are deliberate. The note understates them.

**Evidence:** `scripts/lib/dev-cycle-read.sh:283-292,568-575`, `scripts/build-loop.sh:126-134`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 9** (`docs/reviews/override-log.md:325`): the timings measured here are about 0.4-0.5 ms per entry_why subshell and about 20 µs per isclosed pair, not 0.3 ms and 17 µs. The conclusion still holds.
- **Claim 16** (`scripts/dev-cycle.sh:167-169`): "the skip message below repeats it". The cycle's-own and @-import exclusions are in separate skip messages (`:178`, `:183`), so the wording should be "skip messages".
- **Claim 29** (commit 6f624cdf): check_fix is in `scripts/dev-cycle.sh:170`, not in the lib. This is already logged as Accepted-immutable.
- **Claim 30** (commit 706e0499): "4 Minor" counts A6, which is a fact-check Mostly accurate with no Minor severity. The fifth new override row is not mentioned.
- **Claim 33** (commit d48f4645 and rubric A6): the lib header still has a 52-character line at `:25`, and the reflow left a 96-character line at `:16`.
- **Claim 34** (commit d48f4645 Notes): check_answer's notdir wording (`:573`) and main_file's error wording (via `:289`) differ from main, but no new path is named in either.

### Unverifiable
(none)

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved at the replicate path named below (inside the worktree), structured per the code-fact-check skill, with `Commit: d48f4645` as its first line.
- Answered: yes. All nine focus areas are verdicted. Behavioural ones are executed (victim GIT_DIR, mutants, probes, suites at d48f4645 and at 6f624cdf).
- Out of scope: review artifacts other than the rubric and the five new override rows. The U2a2/U2b/U2c plan bullets are future work. `test/scripts/build-loop-read.bats:84` still uses `git replace ... && git config ...`, but row 317 did not list it, and its own `git replace -d` at `:85` guards it.
- Escalate: nothing blocking. All six non-Verified claims are wording or history.
- Decisions I made: I read "row N" as override-log.md line N, which matches every cited row's subject. I graded the row-319 residue (Claim 33) Mostly accurate because the three named lines are fixed and the residue is cosmetic. I graded the timing row Mostly accurate rather than Verified because the figures are about 40% and 15% under this host's measurements.
