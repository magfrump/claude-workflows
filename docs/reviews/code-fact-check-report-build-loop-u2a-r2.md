Commit: db9cc040

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a, branch feat/build-loop-u2a)
**Scope:** full branch diff `git diff main...HEAD` (merge base 900c47d0; HEAD db9cc040). That covers the four branch commits (cfbf34d2, b9ffe7a8, 36b79f72, db9cc040) and their messages; the brief asked for five, but `git log main..HEAD` lists four. Plan D2/D5/D6, the F10/F11 rows and the step-5 U2 split note are the reference; known-issues A2-A4; override-log rows 321-334; the rubric's iteration-2 section. Final confirming pass, replicate r2 of k=3.
**Checked:** 2026-10-06
**Total claims checked:** 56
**Summary:** 44 verified, 8 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read. No claim matches a logged pattern, and no Incorrect below is a fabricated symbol: each one is a behavioral mismatch.

Skill-format note: the brief asks for a "Legibility-target" and a "Goal-Alignment Note". `skills/code-fact-check/SKILL.md` at db9cc040 defines neither (`grep -i 'legib\|alignment'` finds nothing). A short Goal-Alignment Note is still given at the end.

Execution provenance. Every executed command ran under `timeout`, with cwd `/workspace/.claude/wt-build-loop-u2a` unless noted, and each process exited before this report was written. Logs are in the scratch directory `$SCR` = `/tmp/claude-1000/-workspace/f2b09f27-e8e1-48a1-9e62-9ab10d974ed8/scratchpad/review-u2a/fc3r2/`:

| Log | Command | Started (UTC) | Exit |
|---|---|---|---|
| `$SCR/bats.out` | `timeout 900 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats` | 2026-10-06T06:55:32Z | 0 (97/97 ok) |
| `$SCR/adv.out` | `timeout 300 bash $SCR/adv.sh scripts/lib/dev-cycle-read.sh $SCR` (S3-S8: symlink+dir, chains, newline symlink text, tab/newline names, doubled names, isimported codes, Unicode spaces) | `$SCR/adv.ts` | 0 |
| `$SCR/adv2.out` | `timeout 300 bash $SCR/adv2.sh … $SCR` (S1/S2: newline-name shadow from main's tree and from an untracked file; S4 chain through `..`) | `$SCR/adv2.ts` | 0 |
| `$SCR/adv3.out` | `timeout 120 bash $SCR/adv3.sh … $SCR` (A4 gaps: symlinked dir, case, absolute; cache key) | `$SCR/adv3.ts` | 0 |
| `$SCR/adv4.out` | inline `timeout 60 bash -c …` in `$SCR/r4` (untracked symlinked CLAUDE.local.md) | 2026-10-06 ~07:03Z | 0 |
| `$SCR/parity.out` | `timeout 300 bash $SCR/parity.sh scripts/lib/dev-cycle-read.sh $SCR` | `$SCR/parity.ts` | 0 |
| `$SCR/hist.out` | `timeout 1500 bash $SCR/hist.sh <worktree> $SCR` (git-archive copies of 36b79f72, db9cc040 and cfbf34d2; guard mutants) | 2026-10-06T07:00:27Z | 0 |
| `$SCR/misc.out` | `timeout 300 bash $SCR/misc.sh <worktree> $SCR` (b9ffe7a8 parity, lower/cat-file timings, doubled-name read order) | `$SCR/misc.ts` | 0 |

---

## Claim 1: Rubric tallies: iteration 1 "36 claims: 1 Incorrect, 7 Mostly accurate, 28 Verified", iteration 2 "25 claims: 16 Verified, 5 Mostly accurate, 3 Incorrect, 1 Unverifiable", and the critic counts (security 3 Medium + 1 Informational; performance 1 Low + 1 Informational; api 1 Inconsistent, 4 Minor, 3 Informational; architecture 5 Minor, 2 Informational)

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:9`, `:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header tallies of both fact-check report versions and the `**Severity:**` line counts in the four critic reports. It does not re-verdict any of those findings.

Iteration 1's report at 36b79f72 reads `**Total claims checked:** 36` / `**Summary:** 28 verified, 7 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable`. The branch copy reads `**Total claims checked:** 25` / `**Summary:** 16 verified, 5 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable` (`docs/reviews/code-fact-check-report-build-loop-u2a.md:10-11`). The critic counts come from grepping `**Severity:**` in each report (paraphrased — no quote available because the count spans 23 severity lines in four files): security has Medium at :36, :65 and :78 and Informational at :108; performance has Low at :45 and Informational at :58; api has Inconsistent at :45, Minor at :66, :87, :104 and :127, and Informational at :148, :172 and :191; architecture has Minor ×5 and Informational ×2.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a.md:10-11`, `git show 36b79f72:docs/reviews/code-fact-check-report-build-loop-u2a.md:10-11`, `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a.md:36-108`

---

## Claim 2: Rubric R1 author note: "every name goes into one map, a doubled name of any kind fails the walk. Test 4: plain and forged newline names are read and their imports refused."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:40`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers names that `ls-tree -r` lists twice (blob/blob, symlink/blob, 100644/100755, and a doubled directory with identical contents) and test 4's newline names. It does not cover a doubled directory name whose two copies list different paths, or a blob and a directory sharing one name: neither fails the walk.

The guard is `[[ -z "${ent[$f]+set}" ]] || return 1` (`scripts/lib/dev-cycle-read.sh:522`), applied to names from `git ls-tree -r -z`. Because `-r` never lists trees, a doubled directory name is caught only when a path under it repeats. In S6 (`$SCR/adv.out`), a tree with `q` twice holding `f` and `g` lists `q/f` and `q/g` once each, and `docs/other.md: -` (the walk succeeded). A blob `q` beside a directory `q` also passes. Reads under the second copy still fail closed at `cat-file`: S3 shows `cat-file main:docs/a.md rc=128` → walk error. The precise wording is "a name `ls-tree -r` lists twice, of any mode, fails the walk".

**Evidence:** `scripts/lib/dev-cycle-read.sh:516-525`, `$SCR/adv.out` (S3, S6), `$SCR/bats.out` (test 4 ok)

---

## Claim 3: Rubric A6/A7: "import_targets ends a token at 18 UTF-8 space sequences (both walks)"; "symlinked start files and targets are followed, `.claude/rules/**.md` start, the pinning test now expects refusal"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:42-43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers symlinks stored on main and `.claude/rules/` starts. It does not establish that an untracked, symlinked start file in the checkout is followed: it is not (Claim 11).

`import_targets` is shared: `done < <(import_targets "$d" < "$f")` (`lib:500`, tree walk) and `git cat-file blob "$MAIN_SHA:$f" | import_targets "$d"` (`lib:545`, main walk). For the `120000)` arm (`lib:546-550`), S4 shows a chain `l1→l2→sub/../../l3.md` refusing every link and `docs/fin.md` (`$SCR/adv2.out`). Test 5 expects `real.md` (the target of a symlinked CLAUDE.md) and `docs/r.md` (from `.claude/rules/style.md`) to refuse, and it passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:500`, `:534`, `:545-550`, `test/scripts/build-loop-check.bats:133-152`, `$SCR/adv2.out`, `$SCR/bats.out`

---

## Claim 4: Rubric A8-A14 fixes (explicit tree/main arms and code 2; entry_why's error arm; plainfile renamed inrepo_here; badform comment; inventory test; header, F10/F11, A4; cache keyed on "MAIN_SHA ROOT_REAL")

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:44-50`
**Type:** Staleness / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each fix's presence in the code. Claims 20, 31b and 26e cover the wording of the comments those fixes touched.

`main) … tree) … *) return 2 ;;` (`lib:571-573`); `error) echo "the tree of the default branch could not be read" ;;` and `*) echo "the default branch answered $1 for $2" ;;` (`lib:290-291`); `grep -rn plainfile scripts test` finds nothing; the inventory test lists `isclosed entry_why isimported ownfile floor inrepo_here main_imports import_targets instruction_names untracked_md` (`test/scripts/dev-cycle.bats:1083`); `IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"` (`lib:514`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:285-292`, `:513-514`, `:567-575`, `test/scripts/dev-cycle.bats:1080-1087`

---

## Claim 5: Override row: "cfbf34d2's 'these fail until the U2a code commit': 10 tests fail there, but the rows 317/318 edits and the bl_setup change already pass"

**Location:** `docs/reviews/override-log.md:323`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three suites run from a `git archive cfbf34d2` copy. It does not establish which of the 86 passing tests carry the row 317/318 edits, beyond those edits not being among the failures.

The run lists exactly 10 `not ok` lines out of `1..96`: tests 1-4, 58, 59, 62, 69, 71 and 77. None is a build-loop-read.bats test.

**Evidence:** `$SCR/hist.out` (section "cfbf34d2"), `test/scripts/build-loop-read.bats:297`, `:436-440`

---

## Claim 6: Override row (performance F2): "45 files here"

**Location:** `docs/reviews/override-log.md:328`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main (900c47d0) start files: instruction-file names plus `.claude/rules/*.md`. It does not count untracked starts.

A Python count of `ls-tree -r` names matching INSTRUCTION_FILE or `.claude/rules/*.md` printed `start files on main: 45`. The timing run cat-files exactly 45 instruction blobs (`cat-file per blob … over 45`).

**Evidence:** `$SCR/misc.out`, `scripts/lib/dev-cycle-read.sh:432`

---

## Claim 7: Override row (performance F1): "floor lower-cases the path and isimported lower-cases it again, ~1 ms per path"

**Location:** `docs/reviews/override-log.md:327`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the cost of a `lower` call on this host (0.63 ms each, so ~1.3 ms for the two). It does not cover other hosts.

`lp="$(lower "$1")"` in floor (`lib:605`) and `lp="$(lower "$2")"` in isimported (`lib:569`). 100 calls measured `lower per call ms=0.63`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:569`, `:605`, `$SCR/misc.out`

---

## Claim 8: Override row (performance F2): "main_imports reads each instruction blob with its own cat-file (~3-4 ms per file; ~4 s at 1,000 files)"

**Location:** `docs/reviews/override-log.md:328`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the one-cat-file-per-blob mechanism and the cost measured here. It does not settle another host's figure.

The mechanism holds: one `git cat-file blob "$MAIN_SHA:$f"` per queued `m:` item (`lib:545`). The figure does not match here. A bare `cat-file` measured `1.01` ms per blob over 45, while the whole walk took 0.37-0.40 s, about 8-9 ms per start file, most of it in the subshell and `import_targets` forks. The precise version is ~1 ms per cat-file and ~8-9 ms of walk time per file here, so ~8 s rather than ~4 s at 1,000 files.

**Evidence:** `scripts/lib/dev-cycle-read.sh:545`, `$SCR/misc.out`, `$SCR/parity.out`

---

## Claim 9: Override row (architecture 2): "Parity on this repo was measured at each commit"

**Location:** `docs/reviews/override-log.md:329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers parity of the IMPORTED_MAIN and IMPORTED sets at b9ffe7a8 and db9cc040 in this worktree. It does not re-run 36b79f72, and it does not establish when the author measured.

`b9 SAME SET` (b9ffe7a8's lib sourced in the worktree) and `main set: 3  tree set: 3` / `SAME SET` (db9cc040).

**Evidence:** `$SCR/misc.out`, `$SCR/parity.out`

---

## Claim 10: Override row (architecture 6): "floor covers D5 items 1-4 only; item 5 (modes) and the brief's own Status rule are U2c's … Stated in floor's comment."

**Location:** `docs/reviews/override-log.md:331`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers floor's comment text. It does not establish that U2c implements item 5.

`# docs/roadmap.md). Floor item 5, symlinks and gitlinks, is the caller's mode` / `# rule, and the caller judges the brief's own Status change before this.` (`lib:597-598`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:591-599`

---

## Claim 11: Known issue A4: "The gate's walk (`main_imports`, U2a) closes A2 and A3's symlinked-file half for the self-merge floor (symlinked start files and targets are followed, `.claude/rules/` starts), but not paths through a symlinked directory, other names one file has on a case-insensitive checkout, or absolute imports into the repo; and its untracked start files come from the checkout the gate runs in."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named gaps (all reproduced) and the symlink following for files main stores. It does not cover an untracked symlinked start file, which is still dropped, so A2's symlinked-start half is closed only for main's files.

The named gaps reproduce in `$SCR/adv3.out`: `@d/x.md` with `d → docs` leaves `docs/x.md: -`; `@Docs/Y.md` leaves `docs/y2.md: -` (Y's import is not followed); an absolute `@$R/docs/z.md` leaves `docs/z.md: -`. An untracked symlink `CLAUDE.local.md → local-real.txt` that imports `@docs/q.md` gives `docs/q.md: - (untracked symlinked start not followed)` (`$SCR/adv4.out`), because the `t:` arm runs `inrepo_here "$f" || continue` (`lib:542`). The precise version: "closes A2's symlinked-start half for start files main stores; an untracked symlinked start (CLAUDE.local.md as a link) is still dropped".

**Evidence:** `scripts/lib/dev-cycle-read.sh:542-552`, `$SCR/adv3.out`, `$SCR/adv4.out`

---

## Claim 12: Plan F10 row: floor item 4 lists `docs/decisions/`, `docs/thoughts/`, `docs/human-author/`, `docs/constraints.md`, the cycle files, and other briefs' working docs and reviews; "`check_fix` keeps its own list: it now refuses `docs/constraints.md` too but still fixes `docs/thoughts/`"

**Location:** `docs/working/plan-build-loop-handoff.md:125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers floor's branches at `lib:612-616` and check_fix's constraints/thoughts outcomes. It does not compare the two lists beyond those paths.

`elif [[ "$lp" == docs/constraints.md ]]` and `elif [[ "$lp" =~ ^docs/(decisions|thoughts|human-author)/ ]]` (`lib:613-614`). dev-cycle.bats test 58 expects `"skip docs/Constraints.md: in-cycle fixes edit only" "ok docs/thoughts/t.md"` and passes (`$SCR/bats.out`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:612-617`, `scripts/dev-cycle.sh:180-183`, `test/scripts/dev-cycle.bats:1013-1029`, `$SCR/bats.out`

---

## Claim 13: Plan F11 row: "Floor item 1 walks main's commit (`main_imports`, U2a: one NUL-safe listing, symlinks followed, `.claude/rules/` and the checkout's untracked instruction files as starts). Gaps: known issue A4 (symlinked directories, case-insensitive names, absolute imports), and the untracked starts come from the checkout `--check` runs in"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the described mechanism and the listed gaps. The does-not-establish residue is that the gap list is not complete. The listing is NUL-safe, but the walk's `seen` set is newline-joined, so a start name holding a newline can stop a main file's imports from being followed (Claim 26a). An untracked symlinked start is dropped (Claim 11).

`mapfile -d '' recs < <(git ls-tree -r -z --full-tree "$MAIN_SHA"; printf 'rc=%s' "$?")` (`lib:516`). The seen set is `seen+="${cand[i]:2}"$'\n'` (`lib:535`), tested with `[[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue` (`lib:557`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:516-560`, `$SCR/adv2.out`, `$SCR/adv4.out`

---

## Claim 14a: Plan U2 split note: U2a's walk "reads main's commit (one `ls-tree -r`, then each instruction blob), started from main's instruction files plus the checkout's untracked ones"; `main_entry`'s `badform`; one closed/ spelling; `check_fix` refuses `docs/constraints.md`

**Location:** `docs/working/plan-build-loop-handoff.md:274`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the unit's listed contents. Claim 14b covers the parenthetical "(they can only add refusals)".

One `git ls-tree -r -z` (`lib:516`) and one `cat-file blob` per `m:` file (`lib:545`). `echo badform` (`lib:270`). The only `briefs/closed` spelling in scripts/ is `isclosed` (`lib:162`). The constraints refusal is at `scripts/dev-cycle.sh:181`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:162`, `:270`, `:516`, `:545`, `scripts/dev-cycle.sh:179-182`

---

## Claim 14b: Plan U2 split note: the checkout's untracked start files "(they can only add refusals)"

**Location:** `docs/working/plan-build-loop-handoff.md:274`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an untracked start file in the checkout removing a refusal that main alone gives. It does not establish the case's reachability from any particular caller (U2b names the checkout).

The mechanism is the same as Claim 26d. With main holding `CLAUDE.md` (`@docs/a.md`) and `docs/a.md` (`@secret.md`), floor refuses `docs/secret.md`. Adding the untracked file `.claude/rules/zz<NL>docs/a.md` makes floor print `docs/secret.md: -` (`$SCR/adv2.out`, S2): the untracked start puts `…zz\ndocs/a.md\n` into `seen`, so main's `docs/a.md` is never queued.

**Evidence:** `scripts/lib/dev-cycle-read.sh:526-536`, `:557`, `$SCR/adv2.out`

---

## Claim 15: build-loop.sh header: "Markup that adds letters (a checked task box, a tag) can still hide a copy"

**Location:** `scripts/build-loop.sh:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers SETTINGS_AWK's letter folding. It does not cover other markup.

`s = tolower($0); gsub(/[^a-z]/, "", s); k = ""` / `if (index(s, "buildlooppolicy") == 1) k = "policy"` (`scripts/build-loop.sh:155-156`). `- [x] ` contributes the letter `x`, so the folded string no longer starts with the key; `- [ ] ` contributes no letter.

**Evidence:** `scripts/build-loop.sh:143-160`

---

## Claim 16: build-loop.sh header: "A tip on a branch not ahead of main, or whose subject does not start 'handoff:', is working."

**Location:** `scripts/build-loop.sh:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers status_one's loop field. It does not cover marker parsing beyond the subject test.

`loop=working` / `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`scripts/build-loop.sh:352-354`), and `[[ "$subj" == handoff:* ]] || { echo working; return; }` (`:286`).

**Evidence:** `scripts/build-loop.sh:279-286`, `:345-362`

---

## Claim 17: dev-cycle.sh `--check-fix` help and the comment above check_fix now name `constraints.md` ("the user's: plan D2") among the refused files

**Location:** `scripts/dev-cycle.sh:50-54`, `scripts/dev-cycle.sh:167-171`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the constraints.md refusal and the unchanged list. It does not re-verify the import-walk known issues C3/C4.

`|| "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || "$a" == */.* …` (`scripts/dev-cycle.sh:181`). Test 58 passes.

**Evidence:** `scripts/dev-cycle.sh:173-186`, `$SCR/bats.out`

---

## Claim 18: Lib header opening list: "… the instruction-file import walks, the self-merge floor, and the default branch."

**Location:** `scripts/lib/dev-cycle-read.sh:2-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of both walks and floor. It does not audit the rest of the list.

`imported_names()` (`:485`), `main_imports()` (`:509`), `floor()` (`:602`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:485`, `:509`, `:602`

---

## Claim 19: "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats)."

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the existence of the named suites and their pass on HEAD. It does not cover other build-loop-*.bats files besides check and read.

Both suites exist and all 97 tests pass.

**Evidence:** `test/scripts/build-loop-check.bats:1`, `test/scripts/build-loop-read.bats`, `$SCR/bats.out`

---

## Claim 20: "inrepo, dirok, skipped, check_brief, isimported, floor and the import walks exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:15-17`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed function's reach to need_root. One residue: isimported with an unknown walk name returns 2 before reaching need_root.

floor runs `need_root` first (`lib:604`), and both walks run it (`:487`, `:512`). isimported reaches need_root only through a walk: `*) return 2 ;;` (`lib:573`). S7 printed `bogus without ROOT_REAL rc=2 (no need_root exit)`. The precise version: "isimported exits through need_root for `tree` and `main`".

**Evidence:** `scripts/lib/dev-cycle-read.sh:567-575`, `$SCR/adv.out` (S7)

---

## Claim 21: Inputs: "… read the default branch's commit, never the working tree …, and so does floor (its import walk also starts from the checkout's untracked instruction files)"

**Location:** `scripts/lib/dev-cycle-read.sh:30-34`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers floor's reads. The stated exception is incomplete: floor also reads checkout files for import targets main lacks, and untracked `.claude/rules/` starts.

`if [[ "$src" == t ]]; then inrepo_here "$f" || continue; out="$(import_targets "$d" < "$f")"` (`lib:542`). `t:` items come from untracked starts and from `else queue+=("t:$p")` for targets main does not store (`lib:559`). The lib's own comment at `:450-451` says so: "A target main does not have is read from the checkout".

**Evidence:** `scripts/lib/dev-cycle-read.sh:445-454`, `:526-560`

---

## Claim 22: "inrepo for a caller that has run need_root itself (a walk, per path)."

**Location:** `scripts/lib/dev-cycle-read.sh:124`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every caller in scripts/. It does not cover test-only calls.

The callers are `inrepo` (`:123`, after `need_root`), `imported_names` (`:490`, `:499`; need_root at `:487`) and `main_imports` (`:542`; need_root at `:512`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:123-125`, `:487-499`, `:512`, `:542`

---

## Claim 23: "isclosed spells the closed/ rule once (row 292)"

**Location:** `scripts/lib/dev-cycle-read.sh:162` (commit b9ffe7a8 message)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers non-comment code in scripts/. It does not cover skills or tests.

`grep -rn 'briefs/closed' scripts/` (comments excluded) returns only `isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief …`. writable, check_brief and shared_branches all call it (`lib:165`, `:345`, `build-loop.sh:318`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:162-166`, `:345`, `scripts/build-loop.sh:318`

---

## Claim 24: main_entry comment: "badform (a path pathform refuses: a .git* part such as .gitattributes, say) … Only blob reads the file, and only absent means there is none: every other word is a refusal. It runs main_by_name and pathform itself, before any read"

**Location:** `scripts/lib/dev-cycle-read.sh:252-265`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_entry and its four callers' case arms. It does not cover git's own reads elsewhere.

`if ! main_by_name; then echo error; return; fi` / `if ! pathform "$1"; then echo badform; return; fi` (`lib:269-270`). Callers treat only `absent` as none: check_brief `absent) echo "ok $a new"` (`:353`), check_answer `absent) continue` (`:712`), main_file `absent) FILE_WHY=absent` (`build-loop.sh:132`), and brief_fields refuses anything but blob (`:313`). Test 77 expects `absent` for `x` and `badform` for six refused forms, including `.gitattributes` and `.github/x.yml`; it passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:266-283`, `:313`, `:351-356`, `:710-715`, `scripts/build-loop.sh:129-134`, `$SCR/bats.out`

---

## Claim 25: "Why main_entry's word $1 for path $2 is not a file to read, for a skip line." (entry_why; "entry_why words every refusal once for check_brief, check_answer and main_file")

**Location:** `scripts/lib/dev-cycle-read.sh:284-292`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three callers. It does not judge the wording.

`*) echo "skip $a: $(entry_why "$e" "$a")"` (`:355`), `*) echo "skip $a: $(entry_why "$e" "$f"), so $f is not read"` (`:714`), `*) FILE_WHY="$(entry_why "$e" "$f")"` (`build-loop.sh:133`). The dev-cycle.bats wording tests pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:285-292`, `:355`, `:714`, `scripts/build-loop.sh:133`, `$SCR/bats.out`

---

## Claim 26a: main_imports "starts at every instruction file stored there (and every .md under .claude/rules/ …), plus the checkout's untracked ones, and follows an import into the file main stores at that path, whatever its name"

**Location:** `scripts/lib/dev-cycle-read.sh:445-449`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the follow step for an import target that main stores. It does not establish the start set itself, which holds (newline and tab start names are read, S6 and test 4).

`seen` joins names with newlines (`seen+="${cand[i]:2}"$'\n'`, `lib:535`), and a target is skipped when `[[ "$seen" != *$'\n'"$p"$'\n'* ]] || continue` (`lib:557`) matches. A start name holding a newline therefore makes its tail look already seen. In S1, main stores `CLAUDE.md` (`@docs/a.md`), `docs/a.md` (`@secret.md`) and `.claude/rules/zz<NL>docs/a.md`. The control run refuses `docs/secret.md`, but with the extra entry floor prints `docs/secret.md: -`: main's `docs/a.md` is recorded as imported but never queued, so its import passes floor (`$SCR/adv2.out`). This is a fail-open of the same family as R1 (newline names), through the `seen` set rather than the listing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:532-537`, `:554-560`, `$SCR/adv2.out` (S1)

---

## Claim 26b: "a symlink there is followed to the path its text names"

**Location:** `scripts/lib/dev-cycle-read.sh:449-450`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers relative symlink text inside the repo: chains, loops, and `..` that stays inside. Text that is absolute or leaves the repo is not followed (`continue`), which matches the "absolute imports" exclusion. A trailing newline in the text is stripped by `$(...)` and the stripped name is followed instead of the walk failing.

The `120000)` arm (`lib:546-550`). S4 refuses `docs/l1.md`, `docs/l2.md`, `l3.md` and `docs/fin.md` along `l1→l2→sub/../../l3.md→@docs/fin.md`. The loop `loopa↔loopb` terminates and refuses both. `docs/up.md → ../../outside.md` and the absolute `docs/abs.md` are refused as targets, but their link texts are not followed (`docs/abstarget.md: -`). In S5, text `docs/a.md\ndocs/b.md` fails the walk, while `tgt.md\n` is followed to `docs/tgt.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:546-551`, `$SCR/adv.out` (S4, S5), `$SCR/adv2.out` (S4)

---

## Claim 26c: "A target main does not have is read from the checkout when it is a plain file there."

**Location:** `scripts/lib/dev-cycle-read.sh:450-451`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers targets absent from main's map. It does not cover a target main stores as a gitlink (`*) continue`), which is not read from the checkout.

`if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); else queue+=("t:$p"); fi` (`lib:559`) and `inrepo_here "$f" || continue` (`:542`). Test 5's untracked chain `CLAUDE.local.md → docs/local-notes.md → docs/t.md` refuses all three.

**Evidence:** `scripts/lib/dev-cycle-read.sh:542`, `:559`, `test/scripts/build-loop-check.bats:145-150`, `$SCR/bats.out`

---

## Claim 26d: "Reading the checkout can only add refusals."

**Location:** `scripts/lib/dev-cycle-read.sh:451`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an untracked checkout file removing a refusal that main alone gives. It does not establish who can write the checkout the gate runs in.

Untracked starts enter the same `seen` set (`lib:535`). An untracked `.claude/rules/zz<NL>docs/a.md` (matched by `"$f" == .claude/rules/*.md`, `:534`) puts `\ndocs/a.md\n` into `seen`, and main's `docs/a.md` is then never walked. S2 control: `docs/secret.md: an instruction file … imports it`. With the untracked file: `docs/secret.md: -` (`$SCR/adv2.out`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:526-537`, `:557`, `$SCR/adv2.out` (S2)

---

## Claim 26e: "Not covered (known issues A2/A3): a path through a symlinked directory, other names that one file has on a case-insensitive checkout, and absolute imports."

**Location:** `scripts/lib/dev-cycle-read.sh:451-453`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three gaps (all reproduced) and the cross-reference. The list is not exhaustive: Claims 26a and 11 name more gaps.

The gaps reproduce in `$SCR/adv3.out` (`docs/x.md: -`, `docs/y2.md: -`, `docs/z.md: -`). The reference is off. The known-issues row that names exactly these three gaps for `main_imports` is A4 (`known-issues-dev-cycle.md:18`). A2 and A3 describe the tree walk, and neither mentions case-insensitive names. The commit message also says "The rest is known issue A4". The precise reference is "known issue A4".

**Evidence:** `docs/working/known-issues-dev-cycle.md:16-18`, `$SCR/adv3.out`

---

## Claim 26f: "Its result is cached for the commit and root in IMPORTED_MAIN_DONE."

**Location:** `scripts/lib/dev-cycle-read.sh:453-454`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key. Checkout changes after the first call are not in the key and are not seen (an untracked file added later was ignored in adv3); the key described matches that.

`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $ROOT_REAL" ]] && …` / `IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"` (`lib:513-514`). adv3 printed `cache key: [5773e66… /…/r3]` and `late untracked after cache: - (cached)`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:513-514`, `$SCR/adv3.out`

---

## Claim 27: "UTF-8 spaces that end an import token, as a blank does: U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F and U+3000." (18 sequences)

**Location:** `scripts/lib/dev-cycle-read.sh:456-460`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the decoded code points and the token cut. It does not establish whether Claude Code itself ends tokens at these code points.

The array has `count=18` entries, decoding to `U+00A0 U+1680 U+2000 … U+200A U+2028 U+2029 U+202F U+205F U+3000`. That equals Python's non-ASCII `str.isspace()` set minus U+0085. `t="${t%%"$u"*}"` (`:469`) runs before the trailing-punctuation strip. S8 and test 5 refuse targets ended by U+3000, U+202F, U+1680 and NBSP.

**Evidence:** `scripts/lib/dev-cycle-read.sh:458-470`, `$SCR/adv.out` (S8), command output recorded in this run's transcript (Python decode)

---

## Claim 28: import_targets: "one repo-relative path per line, case kept"

**Location:** `scripts/lib/dev-cycle-read.sh:463-464`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the output form. It does not cover tokens holding `\`, which IMPORT_RE ends.

`p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)" || continue` / `[[ "$p" != ..* ]] || continue` / `printf '%s\n' "$p"` (`:472-474`). It has no lower-casing. Tokens come from `grep -oE`, so they hold no newline.

**Evidence:** `scripts/lib/dev-cycle-read.sh:465-476`

---

## Claim 29: instruction_names / untracked_md comments ("one grep … LC_ALL=C makes -i ASCII-only"; "--others without --exclude-standard already lists ignored files")

**Location:** `scripts/lib/dev-cycle-read.sh:477-484`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the moved helpers. It does not re-time the "took seconds" history.

`instruction_names() { env LC_ALL=C grep -zaiE '…' || true; }` and `untracked_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; }`. In test 1, the untracked CLAUDE.local.md's import (`docs/private.md`) is refused.

**Evidence:** `scripts/lib/dev-cycle-read.sh:481`, `:484`, `$SCR/bats.out`

---

## Claim 30: main_imports "returns 1, with IMPORTED_MAIN set to 'error', when the commit's tree cannot be listed whole, lists a name twice (git would read the first copy, whatever its mode) or a blob cannot be read … The listing stays NUL-separated as git writes it (a name may hold a newline), with its exit status after the last NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:503-508`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed failure. The list is not exhaustive: a failed untracked listing (`:527`), a record not matching the shape (`:520`) and a symlink text with an inner newline (`:547`) also fail. A doubled directory name that `-r` does not list twice does not fail (Claim 2). No current test pins the record-shape guard: replacing `|| return 1` with a loose `|| continue` passes all 5 check tests.

`mapfile -d '' recs < <(git ls-tree -r -z --full-tree "$MAIN_SHA"; printf 'rc=%s' "$?")` / `[[ "${recs[-1]}" == rc=0 ]] || return 1` (`:516-517`); `[[ -z "${ent[$f]+set}" ]] || return 1` (`:522`); `|| { IMPORTED_MAIN=error; return 1; }` (`:545`). Test 3 (missing blob), test 4 (doubled names) and S6 (100644/100755 doubled) all fail the walk. In S3, `git cat-file -p` of a doubled symlink/blob `AGENTS.md` returns the symlink's text `x`, the first copy (`$SCR/misc.out`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:509-562`, `$SCR/adv.out` (S3, S5, S6), `$SCR/misc.out`, `$SCR/hist.out` (db9cc040 mutants)

---

## Claim 31a: isimported: "Returns 0 imported, 1 not, 2 when the main walk failed or $1 is neither"

**Location:** `scripts/lib/dev-cycle-read.sh:563-565`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three codes. It does not cover the `tree` arm's failure modes: imported_names has no failure return.

S7: `main imported rc=0`, `main not rc=1`, `tree imported rc=0`, `bogus rc=2`. Test 3 covers the failed walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:567-575`, `$SCR/adv.out` (S7)

---

## Claim 31b: isimported: "(fail closed: a caller that tests it with `if` refuses)"

**Location:** `scripts/lib/dev-cycle-read.sh:565`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a caller that tests isimported with `if` (as check_fix does). It does not affect floor, which reads the code itself.

Under `if`, code 2 is false, the same as "not imported". A caller written as `if isimported …; then refuse` (check_fix's form: `elif isimported tree "$lp"; then echo "skip …"`, `scripts/dev-cycle.sh:183`) does not refuse on 2. S7: `if-form: does not refuse`. Only floor's explicit `rc=0; isimported main "$lp" || rc=$?; [[ "$rc" -ne 1 ]]` (`lib:609`) fails closed. The precise version: "a caller must read the code (2 ≠ 1) to fail closed; an `if` test treats 2 as not imported".

**Evidence:** `scripts/lib/dev-cycle-read.sh:609-611`, `scripts/dev-cycle.sh:183`, `$SCR/adv.out` (S7)

---

## Claim 32: ownfile: "keyed on its full stem … docs/working/{research,plan,checkpoint,handoff,test-strategy}-STEM.md, and a review it adds, docs/reviews/STEM.md or docs/reviews/NAME-STEM.md (a modified or deleted review is never its own)"

**Location:** `scripts/lib/dev-cycle-read.sh:576-581`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers working docs and reviews directly under docs/reviews/. The status letter applies only to reviews (a deleted own working doc is still own), and NAME may be empty (`docs/reviews/-STEM.md`).

`[[ "$3" == A && "$1" == docs/reviews/* && "$b" != */* && ( "$b" == "$2.md" || "$b" == *"-$2.md" ) ]]` (`:586`). Tests 1-2 pass, covering wrong date, `xy` stem, subdirectories, `D` status and empty stem.

**Evidence:** `scripts/lib/dev-cycle-read.sh:582-587`, `test/scripts/build-loop-check.bats:66-80`, `$SCR/bats.out`

---

## Claim 33: GATE_CODE: "The gate's own code: main's copy runs the next merge (plan D6), so a change to it lands only through a merge-gate- review entry"

**Location:** `scripts/lib/dev-cycle-read.sh:588-590`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the files D6 extracts and runs, and D5 item 3 widened to `scripts/lib/`. It does not cover D4's `merge-gate-` list, which also names `skills/dev-cycle/` (plan :61). floor passes that path, as D5's "scripts and skills are self-mergeable" allows.

`GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/'`; plan D6 "extracts `scripts/build-loop.sh`, `scripts/dev-cycle.sh`, `scripts/questions.sh` and `scripts/lib/dev-cycle-read.sh` from `MAIN_SHA`" (`plan:79`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:590`, `docs/working/plan-build-loop-handoff.md:61`, `:71`, `:79`

---

## Claim 34: floor comment: "The self-merge floor (plan D5) … $1 is the path as the merge result stores it, $2 the brief's full stem and $3 the diff-tree status letter. Returns 0 with FLOOR_WHY set when the floor refuses, else 1. Paths compare lower-cased" (and commit b9ffe7a8's "plan D5 items 1-4")

**Location:** `scripts/lib/dev-cycle-read.sh:591-599`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers items 1-4 against D5 (`plan:69-72`). floor refuses more than item 4 lists (`docs/reviews/` other than the brief's own, and `docs/dev-cycle.md`), and item 5 is left to the caller, as the comment says.

The branches at `:606-617` are: INSTRUCTION_FILE (item 1, files), `"/$lp" == */.*` (item 2, including top-level `.envrc`), GATE_CODE (item 3), `isimported main` (item 1, imports), and writable/dev-cycle.md, constraints, decisions/thoughts/human-author, working and reviews (item 4). It ends `else return 1; fi`. Test 1 (52 paths, mixed case) passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:602-618`, `docs/working/plan-build-loop-handoff.md:66-73`, `$SCR/bats.out`

---

## Claim 35: `FLOOR_WHY=""  # read by floor's caller (U2c's --check)`

**Location:** `scripts/lib/dev-cycle-read.sh:600`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the absence of a current script reader. It does not establish U2c's future code.

`grep FLOOR_WHY scripts/` finds only the lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:600-617`

---

## Claim 36: SKILL.md: `--check-fix` refuses "… `docs/dev-cycle.md`, `docs/constraints.md`, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with `@`"

**Location:** `skills/dev-cycle/SKILL.md:72-75`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers parity with check_fix. It does not cover the C3 transitive-import wording (a known issue).

The list matches `scripts/dev-cycle.sh:180-183`, and test 58 passes.

**Evidence:** `skills/dev-cycle/SKILL.md:72-75`, `scripts/dev-cycle.sh:180-183`, `$SCR/bats.out`

---

## Claim 37: "An inherited GIT_DIR (a run from a git hook, say) would send every fixture command to that repo instead of the throwaway one."

**Location:** `test/lib/build-loop-fixtures.bash:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers git's documented GIT_DIR precedence and the unset line. It does not re-run the hook scenario (row 314 records it as observed).

`unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES` runs before `git init` (`:13`, `:21`).

**Evidence:** `test/lib/build-loop-fixtures.bash:7-22`

---

## Claim 38: build-loop-check.bats header: lib-level tests of floor, ownfile and isimported; "Each test builds a throwaway repo under $BATS_TEST_TMPDIR … this repo is untouched."

**Location:** `test/scripts/build-loop-check.bats:3-6`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers setup and the floors helper. It does not cover U2b's future tests.

`setup() { bl_setup; …}`. bl_setup does `R="$BATS_TEST_TMPDIR/repo"` … `cd "$R"` … `git init` (`fixtures:19-21`).

**Evidence:** `test/scripts/build-loop-check.bats:11-19`, `test/lib/build-loop-fixtures.bash:19-21`

---

## Claim 39: "Untracked local instruction files add imports; a working-tree edit of a tracked one does not (main's copy decides)."

**Location:** `test/scripts/build-loop-check.bats:40-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test 1's fixture.

`docs/private.md` refuses with IMP, and `docs/wt-only.md` passes. Test 1 is ok.

**Evidence:** `test/scripts/build-loop-check.bats:42-62`, `$SCR/bats.out`

---

## Claim 40: Test 4 title and comments: "a name the tree lists twice fails the walk; a name holding a newline, even one shaped like a record, is read"; "A start file listed twice (a symlink first, which git reads)…"; "one shaped so each half looks like an ls-tree record (a forged symlink line)"

**Location:** `test/scripts/build-loop-check.bats:98-131`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixtures as written. Other newline shapes can still defeat the follow step (Claim 26a), which this test does not exercise.

Test 4 is ok. Git reads the symlink copy first (`read: [x]`, `$SCR/misc.out`). Mutation: deleting `:522` fails test 4 (`$SCR/hist.out`). Under the old newline-split parse, the second name splits into `100644 blob Q\tx` and `120000 blob A\tdocs/AGENTS.md`, both record-shaped.

**Evidence:** `test/scripts/build-loop-check.bats:98-131`, `$SCR/bats.out`, `$SCR/misc.out`, `$SCR/hist.out`

---

## Claim 41: Test 5 title: "floor follows what Claude Code loads: symlinks, any name main stores, the checkout's files, .claude/rules/, a token ended by a Unicode space"

**Location:** `test/scripts/build-loop-check.bats:133`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixture's ten refused paths and one passing path. It does not establish what Claude Code itself loads.

Test 5 is ok.

**Evidence:** `test/scripts/build-loop-check.bats:133-152`, `$SCR/bats.out`

---

## Claim 42: T7 comment: "(one commit on top of base, with its tree)"

**Location:** `test/scripts/build-loop-read.bats:297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fixture commit object.

`printf 'tree %s\nparent %s\n…' "$(git rev-parse "$base^{tree}")" "$base"` (`:298`).

**Evidence:** `test/scripts/build-loop-read.bats:297-300`

---

## Claim 43: dev-cycle.bats: "docs/constraints.md is the user's (plan D2); docs/thoughts/ stays a living doc the cycle may fix." and the title "main_entry answers badform for a path pathform refuses, absent for a plain missing one (U1d, U2a)"

**Location:** `test/scripts/dev-cycle.bats:1023`, `test/scripts/dev-cycle.bats:1335`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tests' assertions.

Both tests pass. Test 77 expects `absent` and then six `badform` lines.

**Evidence:** `test/scripts/dev-cycle.bats:1013-1029`, `:1335-1345`, `$SCR/bats.out`

---

## Claim 44: Commit cfbf34d2 bullets: build-loop-check.bats contents; dev-cycle.bats "main_entry answers badform … with an absent positive control (row 320)"; build-loop-read.bats "the three fixture && chains split, :436 followed by a standalone git replace -d (row 317); T7's comment (row 318)"; "bl_setup unsets GIT_DIR and the other repo-locating variables (row 314)"

**Location:** commit cfbf34d2
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the bullets other than "these fail until the U2a code commit" (Claim 45) and the doubled-name phrasing (already Accepted-immutable, override row 322).

Row 317 names `:436`, `:464` and `:469`. All three are split in the diff, and `git replace -d` stands alone at `:440`. The `&&` chain at `:84` predates the branch and is not one of the three.

**Evidence:** `test/scripts/build-loop-read.bats:84`, `:436-440`, `:466-475`, `docs/reviews/override-log.md:317-320`

---

## Claim 45: Commit cfbf34d2: "these fail until the U2a code commit"

**Location:** commit cfbf34d2
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three suites at cfbf34d2. The disposition is already recorded (override row 323, Accepted-immutable).

10 of 96 tests fail. The build-loop-read.bats edits and the bl_setup change pass.

**Evidence:** `$SCR/hist.out`, `docs/reviews/override-log.md:323`

---

## Claim 46: Commit b9ffe7a8: floor's list; "main_imports walks main's commit (one ls-tree -r, then each instruction blob) … Agrees with the working-tree walk on this repo"; "the main walk does not follow a target whose name pathform refuses (parity gap …)"; "393 changed code lines"

**Location:** commit b9ffe7a8
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit as of b9ffe7a8. Later commits changed the walk.

`b9 SAME SET` (b9ffe7a8's lib run in this worktree). At b9ffe7a8 the follow step was `e="$(main_entry "$p")"; case "$e" in blob) queue+=…` (b9ffe7a8 `lib:~525`), so a badform target was not followed. Non-docs numstat is 162 (cfbf34d2) + 231 (b9ffe7a8) = 393.

**Evidence:** `$SCR/misc.out`, `git show b9ffe7a8:scripts/lib/dev-cycle-read.sh` (main_imports), `git diff --numstat cfbf34d2^ b9ffe7a8`

---

## Claim 47: Commit 36b79f72: R1 "a start file whose name holds a newline split at the NUL-to-newline turn and was dropped, and a tree listing CLAUDE.md twice read only the first copy"; "Every record must now start with a mode, a type and an object id, and any name listed twice (any mode) fails the walk … deleting either guard fails the test"; A1-A4; "three override rows"

**Location:** commit 36b79f72
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit's own code and tests. The R1 reopening (Claims 11/15b/16a of iteration 2) is a later finding about the split-record regex, not a refutation of "deleting either guard fails the test".

At b9ffe7a8 the listing used `| tr '\0' '\n'` with a `seen` check that skipped a second copy. At 36b79f72 the guards are at `:511` and `:513`. Replacing either with `:` makes test 4 `not ok`, while the baseline is all ok (`$SCR/hist.out`). The commit adds 3 override rows.

**Evidence:** `git show 36b79f72:scripts/lib/dev-cycle-read.sh:496-536`, `$SCR/hist.out`

---

## Claim 48: Commit db9cc040 bullets: R1 fix ("listing now stays NUL-separated … a name listed twice, of any kind, fails the walk. Test 4 reads a plain and a forged newline name"); A5-A14; "11 override rows"

**Location:** commit db9cc040
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers names listed by `ls-tree -r` and the listed fixes. The commit does not claim a newline-safe `seen` set, and that set is not newline-safe (Claim 26a).

`mapfile -d ''` (`lib:516`), the `ent` map (`:511`, `:522-523`), and `queue+=("t:$p")` (`:559`) with no main_entry call. `git diff db9cc040^ db9cc040 -- docs/reviews/override-log.md | grep -c '^+|'` → 11.

**Evidence:** `scripts/lib/dev-cycle-read.sh:509-575`, `$SCR/bats.out`

---

## Claim 49: Commit db9cc040 notes: "the early-split trigger fired (3 Incorrect in main_imports)"; "The unit grows past the 400-line cap"; "Walk parity with the tree walk re-measured on this repo (same set); main_imports ~0.45 s here."

**Location:** commit db9cc040
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers this host's measurement: 0.37-0.40 s over three runs, against the stated "~0.45 s". The three Incorrect claims all concern main_imports' behavior, but they sit in a lib comment (Claim 11), a test title (15b) and a commit message (16a).

The iteration-2 report has Incorrect on Claims 11, 15b and 16a. Non-docs numstat for the branch is 162 + 231 + 42 + 202 = 637, which is over 400. The parity run printed `main set: 3  tree set: 3` / `SAME SET`.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a.md:222-323`, `$SCR/parity.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 14b** (`docs/working/plan-build-loop-handoff.md:274`): "(they can only add refusals)". An untracked start whose name holds a newline removes a refusal (S2). Drop the parenthetical or make `seen` newline-safe.
- **Claim 26a** (`scripts/lib/dev-cycle-read.sh:445-449`): "follows an import into the file main stores at that path". The newline-joined `seen` (`:535`, `:557`) lets a start name `.claude/rules/zz<NL>docs/a.md` stop main's `docs/a.md` from being walked, and floor passes `docs/secret.md` (S1).
- **Claim 26d** (`scripts/lib/dev-cycle-read.sh:451`): "Reading the checkout can only add refusals". Same mechanism from an untracked file (S2).
- **Claim 31b** (`scripts/lib/dev-cycle-read.sh:565`): "(fail closed: a caller that tests it with `if` refuses)". An `if` test treats 2 as not imported. Only floor's explicit code read fails closed.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:40`): "a doubled name of any kind". Precisely, a name `ls-tree -r` lists twice; doubled directories with disjoint contents do not fail.
- **Claim 8** (`docs/reviews/override-log.md:328`): cat-file measured ~1 ms per blob here, and the walk ~8-9 ms per file.
- **Claim 11** (`docs/working/known-issues-dev-cycle.md:18`): the symlinked-start fix covers main's files only. An untracked symlinked CLAUDE.local.md is still dropped.
- **Claim 13** (`docs/working/plan-build-loop-handoff.md:126`): the F11 gap list omits the newline `seen` shadow and untracked symlinked starts.
- **Claim 20** (`scripts/lib/dev-cycle-read.sh:15-17`): isimported with an unknown walk name returns 2 without need_root.
- **Claim 21** (`scripts/lib/dev-cycle-read.sh:30-34`): floor also reads checkout files for targets main lacks, not only untracked starts.
- **Claim 26e** (`scripts/lib/dev-cycle-read.sh:451-453`): the gaps are A4's, not "known issues A2/A3".
- **Claim 45** (commit cfbf34d2): 10 of the new or edited tests fail at that commit, not all (already Accepted-immutable).

### Unverifiable
- None.

---

## Goal-Alignment Note

The branch's goal is a fail-closed self-merge floor whose import walk refuses whatever main's instruction files load. The main-walk code meets most of it: NUL-safe listing, doubled listed names, symlinks on main, `.claude/rules/` starts, Unicode spaces, and checkout targets, all reproduced. One newline-name path still fails open. The `seen`/queue bookkeeping (`lib:535`, `:557`) joins names with newlines, while the listing now keeps them whole, so a start name holding a newline can hide a later import target (S1 from main, S2 from an untracked file). That is the same family as R1 and contradicts both the "follows … whatever its name" and the "can only add refusals" comments. Two smaller issues: the isimported comment promises a fail-closed `if` that only floor's explicit code read delivers, and no test pins the record-shape guard at `lib:520` (a loosened regex passes all five check tests).
