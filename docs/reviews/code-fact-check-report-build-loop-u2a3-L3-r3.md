Commit: 0bb98f27
# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`
**Scope:** `git diff main...HEAD` at 0bb98f27 (base main 62d366a7): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3/U2a3c/U2b bullets), the rubric's Loop 2 sections, the override rows added since 0170f16a, and the commits 2b22a082..0bb98f27. Role cfc3, pass i3 (loop 2 iteration 3, the final confirming pass), replicate r3.
**Checked:** 2026-10-07 (UTC; 2026-10-06 local)
**Total claims checked:** 40
**Summary:** 36 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`): five entries, all of them fabricated measured figures or file-to-symbol claims. The nearest pattern is "test tally claimed but the suite holds another number". Every test count checked below was executed and matches, so no claim here matches a logged pattern. No verdict is Incorrect, so the log needs no new entry. This pass writes only this report.

## Execution provenance

- Scratch dir: `S=/tmp/u2a3-cfc3-i3-3sch`. Logs are under `$S/logs/`.
- Environment: git 2.39.5, bash 5. Probes ran with `LC_ALL=C` unless the row says otherwise.
- Lib under probe: `$S/base`, a `git archive HEAD` copy. Mutants were applied to copies of `$S/base` with `python3 -I $S/mut.py`, an exact single-occurrence replacement that refuses to run unless it finds exactly one match. The worktree's files were never modified.
- Probe harness: `$S/h.sh`, which reproduces the suite's `imps` helper (`walk: ok|failed`, then `PATH: imported|-`).
- One probe worktree, `$S/wt-main` (detached at main 62d366a7), was added for P1/P4 and then removed with `git worktree remove`. `git worktree list` shows nothing left.
- No background process outlives the pass.

| Run | Command | cwd | Exit | Time (UTC) | Output |
|---|---|---|---|---|---|
| X1 | `TMPDIR=$(mktemp -d $S/t-XXXX) timeout 600 bats test/scripts/build-loop-check.bats` | worktree | 0 | 04:05:03Z | `$S/logs/blc.txt` (1..17, 17 ok) |
| X2 | `TMPDIR=… timeout 900 bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/build-loop-check.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`, plus `bats --count` per file (75, 19, 17, 2, 2) | worktree | 0 | 04:05:23Z-04:06:05Z | `$S/logs/suites.out` (115 ok, 0 not ok) |
| X3 | `git diff --numstat main...REV -- . ':!docs'` summed, for HEAD, 99cce51b, dfeeb85d, 2b22a082 | worktree | 0 | 04:05:10Z, 04:13:59Z | `$S/logs/numstat.out`, `$S/logs/oldmuts.summary` (400, 400, 400, 392) |
| X4 | `$S/muts.sh` (20 HEAD mutants, each `bats build-loop-check.bats` in its own copy) | `$S/mut-NAME` | 0 (each row rc=1 = killed) | 04:06:08Z-04:07:37Z | `$S/logs/mutants.summary`, `$S/logs/mut-NAME.out` |
| X5 | `bash $S/soft.sh`: an assertion-level map. A suite copy's `want` logs a miss (`test:line`) instead of stopping, so every assertion a mutant flips is recorded. 28 runs: none, plus 27 mutants | `$S/soft-NAME` | 0 | 04:10:14Z-04:12:27Z | `$S/logs/soft.summary`, `$S/logs/soft-NAME.log` |
| X6 | `bash $S/mask.sh`: the three `git rm -qf CLAUDE.md` unmask lines removed from a suite copy (`$S/unmask.py`), then the three mutants they were added for. Test 17 is also run against cc1aa864's and 2b22a082's lib | `$S/mask-NAME`, `$S/old-REV` | 0 | 04:09:05Z | `$S/logs/mask.summary`, `$S/logs/mask-*.out`, `$S/logs/old-*.out` |
| X7 | `bash $S/oldmuts.sh`: the mutants named in 2b22a082's and dfeeb85d's messages, each run against that commit's own `git archive` (lib and tests) | `$S/om-REV-NAME` | 0 | 04:13:09Z-04:13:59Z | `$S/logs/oldmuts.summary` |
| X8 | `bash $S/p1.sh` (this repo's own main in a fresh detached worktree, and the u2a3 worktree) | `$S/wt-main`, worktree | 0 | ~04:05:30Z | `$S/logs/p1.out` |
| X9 | `bash $S/p2.sh` (P2 index-only start deleted from the checkout; P3 ignored start; P4 `@.`/`@./`/`@docs`; P5 nested rules; P6 first-copy lookup; P7 tree-listing failure with and without the index-only start, real lib vs the `treefail` mutant) | `$S/r-p*` | 0 | 04:14:46Z | `$S/logs/p2.out` |
| X10 | `bash $S/p3.sh` (crafted trees via `hash-object -t tree --literally`: two same-named trees, an unsorted tree, a slash in an entry name, non-canonical modes, a 100644 entry naming a tree object, a `.` subtree; a Latin-1 name under C vs C.UTF-8) | `$S/r-p8*` | 0 | 04:15:24Z | `$S/logs/p3.out` |
| X11 | `bash $S/p4.sh` x3 (ancestor-pass timing on main's 2966 entries) | `$S/wt-main` | 0 | 04:16:05Z | `$S/logs/p4.out` |
| X12 | `bash $S/p5.sh` (`@.git` in a linked worktree, `check-attr --source` on 2.39.5, GIT_NO_REPLACE_OBJECTS and T42 greps, check-ignore on /workspace's claude-home, listing time) | `$S/r-p5`, `$S/wt-main` | 0 | 04:16:33Z | `$S/logs/p5.out` |

Assertion-level mutant map (X5). Each row lists the `test:line` assertions the mutant flips. "notok" marks a test that the mutant stops through status or a direct `[ … ]` check rather than through `want`.

| Mutant (lib line) | Flipped assertions |
|---|---|
| none | — (17/17 pass) |
| ckprobe (:612 removed) | 3:59, 9:177, 12:235, 12:237 |
| plaindirallow (:612 first arm) | 9:185 |
| untrackedstart (:574 `continue`) | 3:60, 3:61, 9:179, 9:182, 11:226 |
| indexhalf (:566 `--others` only) | 3:61, 10:206 |
| cknl (:567 newline) | 7:141 |
| mainbyname (:556) | 4:76; notok 16 |
| blobread (:583) | 4:70; notok 8, 14 |
| dupcheck (:561 first half) | 5:86, 5:92, 5:95 |
| treenl (:561 newline half) | 5:105 |
| linknl / linkabs / linkleave (:590, :600) | 7:150 each |
| emptytext (:590 `-z`) | 12:243 only (7:150's `''` iteration still fails, through :612's root arm) |
| parent (:611 removed) | 12:246, 15:284, 15:288 (not 9:172) |
| gitlinkmatch (:611 `^120000$`) | 12:246 |
| parentimm (:611 immediate parent) | 15:288 |
| nulcount (:587) | 9:190 |
| **treefail (:557 `\|\| true`)** | **none** |
| ckfail (:566 `\|\| true`) | 10:202, 10:206 |
| lenchk (:570) | notok 10 (set -u, unbound `low[i]`) |
| dotdot (:595) | 15:277, 15:278, 15:292; notok 10 |
| cklinkL (:597 `-L` half) | 15:292 |
| mainlinkL (:597 ent half) | 15:278; notok 10 |
| herestring (:593 `<<<`) | notok 10 (:216) |
| ancestor (:565) | 17:310 |
| gitlinkarm (:601 removed) | 12:246 |
| starterr (:602 `*) continue`) | none (arm unreachable: ls-tree canonicalises modes, P8d) |

Fail-closed probe summary (task item 1):
- No main tree, crafted tree or checkout state was found where the walk answers ok while a fresh checkout of main gives Claude Code an import the walk misses, beyond the documented and settled gaps.
- Crafted trees all failed closed or were modelled consistently with what checkout writes (X10):
  - two same-named `docs` trees: `cat-file` cannot find the second tree's file, so the walk fails;
  - an unsorted tree: the lookup stops early, so the walk fails;
  - a 100644 entry naming a tree object: the walk fails;
  - non-canonical modes: ls-tree prints 100644/040000;
  - a root entry named `docs/CLAUDE.md`: checkout writes it at `docs/CLAUDE.md`, and the walk reads the same blob and resolves its imports from `docs/`, as Claude Code would;
  - a `.` subtree: checkout refuses `./CLAUDE.md`, and the walk's `MAIN:./CLAUDE.md` reads the root file instead, so this only over-reads.
- Every checkout read in main_imports can only add a failure (Claim 19).
- One wrong refusal on a normal repo: under a UTF-8 locale, a non-UTF-8 file name in main fails the walk at :559 (X10, P8g). It fails closed. The suite and the probes run `LC_ALL=C`, and this repo's own main walks ok (X8).

---

## Claim 1: "A name main stores as both a tree and a symlink (tree first, crafted non-canonical tree) passed the doubled-name check … Not a regression (same at cc1aa864)"; fixed by a "Memoised ancestor pass after the record loop … mutant killed"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:31`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's answer at HEAD, at cc1aa864 and at 2b22a082 on test 17's crafted tree, and the ancestor-pass mutant. It does not establish the rubric's report counts or agreement figures, though 40+8+7+1=56 and 37/51=72.5% are arithmetically consistent.

Test 17 fails against cc1aa864's lib and against 2b22a082's lib: both answer `walk: ok`, and the test wants `walk failed` (X6, `$S/logs/old-cc1aa864.out`, `old-2b22a082.out`). At HEAD it passes (X1). The fix is the pass after the record loop:

```bash
# scripts/lib/dev-cycle-read.sh:564-565
  done  # then a name that is also a directory of another listed name (a crafted tree) fails:
  for f in "${!ent[@]}"; do c="$f"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ -z "${dir[$c]+set}" ]] || break; [[ -z "${ent[$c]+set}" ]] || return 1; dir[$c]=1; done; done
```

Removing the `ent` check kills test 17 at line 310 (X4, X5 `ancestor`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-565`, `test/scripts/build-loop-check.bats:306-311`, `$S/logs/old-cc1aa864.out`, `$S/logs/soft-ancestor.log`, `$S/logs/mutants.summary`

---

## Claim 2: "Three refusals masked since dfeeb85d's index listing (newline in a tree name, NUL in link text, empty link text): tests 5, 9, 12 left a stale CLAUDE.md in the index" — fixed: "`git rm -qf CLAUDE.md` after those rebuilds …; each mutant killed by its own test"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:32`
**Type:** Behavioral (tests)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named refusals, with and without the unmask lines. It does not establish that no other refusal in the suite is masked: test 10's tree-listing refusal is (Claim 33).

With the three `; git rm -qf CLAUDE.md  # no index-only start masks …` suffixes removed (X6, `unmask.py` reports `removed 3`), the treenl, nulcount and emptytext mutants all pass the suite (`mask-treenl: rc=0`, `mask-nulcount: rc=0`, `mask-emptytext: rc=0`). With the suffixes kept, each mutant is killed by its own test: treenl by 5:105, nulcount by 9:190, emptytext by 12:243 (X5). One of the unmask lines:

```bash
# test/scripts/build-loop-check.bats:189
    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m nul-link)"; git rm -qf CLAUDE.md  # no index-only start masks the NUL count
```

**Evidence:** `test/scripts/build-loop-check.bats:91`, `:189`, `:242`, `$S/logs/mask.summary`, `$S/logs/soft.summary`

---

## Claim 3: F5 "The gitlink arm and a failing `ls-files --cached` were unpinned … ✅ Fixed: gitlink at a start name; a git shim failing `--cached`. The two listings are now one `--cached --others` call"; F7 "`*)` unreachable"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:35-37`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merged listing, the gitlink arm's pin and the `--cached` failure pin. It also covers the `*)` arm's unreachability for the modes `ls-tree -r` prints, including from non-canonical modes. It does not establish behavior under a git version other than 2.39.5.

The listing is one call:

```bash
# scripts/lib/dev-cycle-read.sh:566
  nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached --others -- ':(glob,icase)**/*.md' || return 1
```

- The gitlinkarm mutant (the `160000) continue` line deleted) flips 12:246, the gitlink-start case.
- The ckfail mutant (`:566 || true`) flips 10:202 and 10:206.
- The starterr mutant (`*) continue`) flips nothing.

Crafted modes `100664` and `40755` are listed by ls-tree as `100644` and recursed as a tree (X10 P8d: `100644 blob … CLAUDE.md;100644 blob … docs/b.md;`), so the `*)` arm cannot be reached.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566`, `:601-602`, `test/scripts/build-loop-check.bats:206`, `:246`, `$S/logs/soft.summary`, `$S/logs/p3.out`

---

## Claim 4: Loop 2 iteration 1 rows: E1 "The walk also lists the checkout's tracked .md files … test 3 stages CLAUDE.local.md; mutant killed"; E2 "Ignored instruction files fail the walk (35 in /workspace's own checkout)"; E4 "`160000) continue`, any other type fails the walk"; E5 "fixture `zz<LF>CLAUDE.md`; a 67 KB link under `ulimit -f 0` with XFSZ ignored … both mutants killed"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:49-53`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code claims of E1, E2, E4 and E5 at HEAD. It does not cover the critics' severities or E3's wording items.

- E1: `git add -f CLAUDE.local.md` at test 3 line 61 is flipped by the indexhalf mutant (X5).
- E2: 35 start-shaped names appear in `git -C /workspace ls-files --others` for the `.md` pathspec, and `check-ignore` reports `devcontainer-config/claude-home/CLAUDE.md` as ignored (X12).
- E4: see the arms at `scripts/lib/dev-cycle-read.sh:601-602`: `160000) continue ;;  # a gitlink: its files are not main's` and `*) IMPORTED_MAIN=error; return 1 ;;`.
- E5: cknl flips 7:141, and the here-string revert kills test 10 at :216. The link text at :213 is 270 × 253 bytes plus `l/../t.md`, 68,319 bytes ≈ 67 KB (paraphrased — no quote available because the size is computed from the printf loop, not written in the file).

**Evidence:** `test/scripts/build-loop-check.bats:61`, `:140-141`, `:212-216`, `scripts/lib/dev-cycle-read.sh:601-602`, `$S/logs/soft.summary`, `$S/logs/p5.out`, `$S/logs/p1.out`

---

## Claim 5: override row "The parent-link loop … is O(L x depth) … Slow, never fail-open; only text committed to main reaches it after the split"

**Location:** `docs/reviews/override-log.md:386`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claims "never fail-open" and "only main's text reaches the loop". It does not re-measure the 9-16 s figure.

The loop's input `p` comes only from `out`, which is computed from `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:583`, `:587-600`), so only text committed to main reaches it. The loop's one exit is a failure:

```bash
# scripts/lib/dev-cycle-read.sh:611
      c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }; done
```

**Evidence:** `scripts/lib/dev-cycle-read.sh:583-613`

---

## Claim 6: override row "the lib does not set GIT_NO_REPLACE_OBJECTS; build-loop.sh exports it"

**Location:** `docs/reviews/override-log.md:387`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence and absence of the variable in the two files. It does not test the bypass candidates themselves (the row says they are untested).

`grep GIT_NO_REPLACE_OBJECTS` finds only `scripts/build-loop.sh:118: export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1` and nothing in the lib (X12).

**Evidence:** `scripts/build-loop.sh:118`, `$S/logs/p5.out`

---

## Claim 7: override row "In a clean linked worktree `.git` is a file, so an instruction file importing `@.git` now fails the walk"

**Location:** `docs/reviews/override-log.md:389`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a probe repo whose CLAUDE.md holds `@.git`, in its main worktree and in a linked one. It does not cover the C9 timing half.

X12 gives `walk: ok` in the main worktree, and in the linked worktree (`.git is a file`) `walk: failed docs/x.md: imported`. The failure comes from the checkout arm `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:612`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:612`, `$S/logs/p5.out`

---

## Claim 8: override row "a name main stores as both a TREE and a SYMLINK … passed the doubled-name check … Fixed: A pass after the record loop … (memoised ancestor walk, ~20 ms here)"

**Location:** `docs/reviews/override-log.md:390`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fix, the memoisation's correctness and the timing on this repo's main. It does not cover larger trees.

Memoisation: a name enters `dir` only after its own `ent` check, and the loop climbs on to its parent unless the parent is already in `dir` (`[[ -z "${dir[$c]+set}" ]] || break`, `:565`). Every ancestor of a `dir` entry is therefore already checked, and the `break` skips nothing unchecked (paraphrased — no quote available because this is an induction over the loop's iterations, not one line). Timing on main's 2966 entries and 368 directories was 20, 18 and 18 ms (X11). This repo's own main walks ok (X8), so the pass does not wrongly refuse it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-565`, `$S/logs/p4.out`, `$S/logs/p1.out`

---

## Claim 9: override rows on checkout conversions: "`check-attr --source` needs git 2.40 … the U2b bullet makes the gate refuse such a checkout"; "T42's config refusals do not list it yet … the U2b bullet makes the gate refuse it"

**Location:** `docs/reviews/override-log.md:391-392`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 rejecting `--source`, T42's text, and what the U2b bullet says. It does not establish the ISO646-DE byte effect, which was not re-run.

- git 2.39.5 answers `error: unknown option `source'` (X12).
- T42 lists `core.fsmonitor`, a local filter, a hook key, `refs/replace/` and `info/attributes`, but not `core.symlinks` (`docs/working/plan-build-loop-handoff.md:347`).
- The U2b bullet, as 0bb98f27 corrected it, reads "U2b is to refuse (not built yet; the walk does not check this) a checkout whose `.gitattributes` sets `working-tree-encoding` or `filter` …, or whose `core.symlinks` is false" (`docs/working/plan-build-loop-handoff.md:279`). Nothing is built yet, so "makes the gate refuse" should read "asks U2b to make the gate refuse". The log is append-only; the bullet itself is now precise.

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `:347`, `$S/logs/p5.out`

---

## Claim 10: override row "The checkout listing and its loop cost ~17 ms here"

**Location:** `docs/reviews/override-log.md:394`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the listing call alone on a fresh main worktree (1452 names, 14 ms). It does not cover the loop's own time or the +150 ms at 20k figure.

`nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached --others -- ":(glob,icase)**/*.md"` gave `listing: 1452 names, 14 ms` (X12). This is the same order as ~17 ms with the loop included.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-567`, `$S/logs/p5.out`

---

## Claim 11: override row "The C3 row's 'fails the walk if present' omits 'unless it is a plain directory'"

**Location:** `docs/reviews/override-log.md:396`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the plain-directory allowance. It does not cover the unsearchable-directory case, which is settled and deferred to U2a3c.

`:612`'s first arm, `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]]`, admits a plain directory. The plaindirallow mutant flips 9:185, which is `mkdir docs/lt.md` → `want walk ok` (X5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:612`, `test/scripts/build-loop-check.bats:184-185`, `$S/logs/soft-plaindirallow.log`

---

## Claim 12: A5 "closes A2 and A3's symlinked-file half for the self-merge floor (symlinked start files and targets on main are followed, `.claude/rules/` at any depth starts, and odd names (a name listed twice or as both a file and a directory, a name holding a newline), link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an imported path main lacks under a directory main stores as a symlink or gitlink fail it)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed follow and refusal against a test assertion that flips under that refusal's mutant. It does not establish the floor's use of the walk (U2a4, unbuilt).

Follows are tested in test 6, which passes at HEAD. The nested-rules mutant (`*/.claude/rules/*.md` dropped) kills it (X4 `rulesnested`), and P5 shows `.claude/rules/sub/x.md` and `a/.claude/rules/b/y.MD` both start (X9). Each refusal flips under its own mutant:

| Refusal | Mutant | Assertion |
|---|---|---|
| doubled name | dupcheck | 5:86/92/95 |
| file+directory | ancestor | 17:310 |
| newline in name | treenl, cknl | 5:105, 7:141 |
| empty text | emptytext | 12:243 |
| absolute | linkabs | 7:150 |
| leaves the repo | linkleave | 7:150 |
| newline in text | linknl | 7:150 |
| NUL in text | nulcount | 9:190 |
| `..` after a symlink | dotdot | 15:277/278/292 |
| link/gitlink parent | parent, gitlinkmatch | 12:246, 15:284/288 |

**Evidence:** `scripts/lib/dev-cycle-read.sh:559-612`, `$S/logs/soft.summary`, `$S/logs/p2.out`

---

## Claim 13: A5 "Until U2a3c the walk reads main's commit only and fails closed on the checkout: a start file main lacks (untracked, ignored, or only in the checkout's index), a `..` after a checkout link in link text, or anything but a plain directory at an imported path main lacks fails the walk …, and a path main lacks that the checkout does not hold is recorded but not walked"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the untracked, ignored, index-only (including deleted from the checkout) and checkout-link cases, and the record-not-walk case. It does not cover the settled git-hardening bypasses (GIT_INDEX_FILE, fsmonitor, sparse checkout), deferred to U2b.

- P2: an index-only CLAUDE.local.md that was deleted from the checkout gives `walk: failed`.
- P3: an ignored one (`!! CLAUDE.local.md`) gives `walk: failed` (X9).
- The start rule: `[[ "${cand[i]:0:1}" == m ]] || return 1  # main lacks it: not walked until U2a3c` (`scripts/lib/dev-cycle-read.sh:574`).
- A `..` after a link only the checkout has gives 15:292 (cklinkL).
- A path main lacks that is absent from the checkout answers imported with walk ok (test 3: `docs/new.md` imported, 3:56-57).

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-577`, `:597`, `:612`, `test/scripts/build-loop-check.bats:46-62`, `$S/logs/p2.out`

---

## Claim 14: A5 "A developer checkout with ignored instruction files (here, `devcontainer-config/claude-home/`) therefore always fails it; the gate needs a fresh worktree until U2a3c"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's ignored start files and a fresh main worktree walking ok. It does not run the walk inside /workspace itself, because the shared rules forbid cd there.

/workspace's `--others` .md list holds 35 start-shaped names, and `devcontainer-config/claude-home/CLAUDE.md` is ignored (X12). Each of those is a start main lacks, so `:574` returns 1 (P3 demonstrates the ignored case). A fresh detached worktree at main answers `walk ok` with 3 imports in 0.47 s (X8).

**Evidence:** `scripts/lib/dev-cycle-read.sh:574`, `$S/logs/p5.out`, `$S/logs/p1.out`

---

## Claim 15: A5 "Not covered: start files under a symlinked directory or in a submodule or untracked nested repo …, other names one file has on a case-insensitive checkout, absolute imports into the repo, and checkout conversions … Untraced against Claude Code: … whether a symlinked instruction file's imports resolve from the link's directory (the walk uses the target's), and whether an `@` token's `..` after a directory link resolves through the link (the walk is lexical, as Node's path.resolve)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the walk's side of each listed gap: it does not start, follow or refuse these shapes. It does not establish Claude Code's behavior, which A5 itself says is untraced.

- The target's directory: a symlink's `out` is queued under its target path (`:609`), and that path's `d` is computed from the queued name (`if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi`, `:581`).
- Lexical `..`: import_targets uses `realpath -ms` (`:503`).
- Absolute imports are dropped: `[[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue` (`:502`).
- Starts come only from `ls-tree -r` (which does not enter a gitlink) and from `ls-files` (`:557`, `:566`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:502-503`, `:557`, `:566`, `:581`, `:609`

---

## Claim 16: F11 row "Floor item 1 walks main's commit (`main_imports`, U2a3: NUL-safe listings, symlinks on main followed, `.claude/rules/` at any depth as starts; a doubled name, a name holding a newline, link text … fails the walk …). Until U2a3c it fails closed on the checkout: a start file main lacks (untracked, ignored, or only in the checkout's index), or anything but a plain directory at an imported path main lacks, fails the walk … Gaps: known issue A5 …"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row's description of main_imports and its gap list against A5. It does not cover "Floor item 1", which is U2a4 and unbuilt.

- Listings use `-z` (`:557`, `:566`) through nul_list.
- The refusals are the same set as Claim 12, and the checkout cases are the same as Claim 13.
- The gap list matches A5's not-covered list item for item.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:557`, `:566`

---

## Claim 17: U2a3 bullet "started from main's instruction files and `.claude/rules/`. It refuses the tree and link shapes it does not model (…), as FENCE_AWK does, and fails closed on the checkout (a start file main lacks, or anything but a plain directory at an imported path main lacks)"

**Location:** `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bullet's code claims (the same set as Claims 12-13). It does not cover the carried-row references (B2-B6 …).

The start rule is `if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]; then` (`scripts/lib/dev-cycle-read.sh:573`). The refusals were executed as in Claim 12.

**Evidence:** `scripts/lib/dev-cycle-read.sh:573-574`, `$S/logs/soft.summary`

---

## Claim 18: U2b bullet "a fresh worktree at MAIN_SHA, since until U2a3c the walk fails on any start file main lacks, ignored ones included, and on anything but a plain directory at an imported path main lacks; U2b is to refuse (not built yet; the walk does not check this) a checkout whose `.gitattributes` sets `working-tree-encoding` or `filter` …, or whose `core.symlinks` is false (A5)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's checkout behavior and the absence of any attribute or config check in it. It does not cover U2b's future design.

main_imports reads no `.gitattributes` and no `core.symlinks` (paraphrased — no quote available because the claim is an absence; main_imports at `:550-615` runs only `ls-tree`, `ls-files` and `cat-file`, plus `realpath` and test operators). The ignored case was executed (P3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:550-615`, `$S/logs/p2.out`

---

## Claim 19: header Inputs "so does main_imports (it reads the checkout only to fail, until U2a3c, so the gate needs a fresh worktree; the block above IMPORTED= lists each case; it needs resolve_main to have found main by name)"

**Location:** `scripts/lib/dev-cycle-read.sh:32-35`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every checkout read in main_imports: each can only add a failure. Coverage includes `-L` probes outside the repo (for example `../x`). It does not cover git hardening (the caller's job, settled).

There are three checkout reads:
1. The listing (`:566-567`) only adds `t:` candidates, which `:574` refuses.
2. `-L "$p"` at `:597` only sets `lk=1`, which only enables `:595`'s failure.
3. `:612`, whose only non-failing outcomes are a plain directory or nothing at all. Neither adds or removes an import.

`realpath -ms` is lexical (`-s`), so its result does not depend on the checkout (paraphrased — no quote available because this is coreutils' documented `-s` semantics, not repo code). `main_by_name || return 1` (`:556`) is the by-name requirement, and its mutant flips 4:76 (X5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:556`, `:566-574`, `:593-598`, `:612`, `$S/logs/soft-mainbyname.log`

---

## Claim 20: block comment "it starts at every instruction file stored there (and every .md under a .claude/rules/ directory at any depth, which Claude Code also loads) and follows an import into the file main stores at that path, whatever its name; a symlink there is followed to the path its text names. An imported path main lacks is recorded and not read."

**Location:** `scripts/lib/dev-cycle-read.sh:452-457`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start selection, following by `ent` lookup and symlink following. It does not establish that Claude Code loads `.claude/rules/` at any depth (an external fact) or the untraced shapes.

- Follow: `if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); continue; fi` (`:609`).
- Not read: no `cat-file` runs unless `ent` holds the path (`:582-603`).
- Test 6 (`docs/a+b.md`, `real.md`, two-link chain, nested rules) passes, and P5 (X9) shows a nested rules subdirectory and `.MD` starting.

**Evidence:** `scripts/lib/dev-cycle-read.sh:573-575`, `:582-613`, `test/scripts/build-loop-check.bats:108-130`, `$S/logs/p2.out`

---

## Claim 21: block comment refusal list "a name listed twice or as both a file and a directory, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink (on main or in the checkout), an imported path main lacks that lies under a directory main stores as a symlink or gitlink, or that the checkout holds as anything but a plain directory (the root itself included), and a start file main lacks (untracked, ignored, or in the checkout's index) fail the walk, so isimported main answers imported for every path"

**Location:** `scripts/lib/dev-cycle-read.sh:457-465`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal, including the root clause and the consequence for `isimported main`. It does not establish completeness against Claude Code beyond the documented gaps; no fail-open was found (probe summary).

- Each refusal flips its assertion under its mutant (Claim 12's table).
- Root: `@.` and `@./` give `walk: failed`, while `@docs` (a plain directory) gives `walk: ok` (X9, P4). `blocker "." dir` prints `./`, because `plaindir` compares `realpath -e .` with `"$ROOT_REAL/."` (paraphrased — no quote available because the path runs through `blocker`/`plaindir` at `:102`, `:110-120`; the executed result is P4).
- isimported: `main) main_imports || return 0;` (`:626`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:102`, `:110-120`, `:612`, `:626`, `$S/logs/p2.out`, `$S/logs/soft.summary`

---

## Claim 22: block comment "Not covered (known issue A5): start files under a symlinked directory or in a submodule or untracked nested repo, other names one file has on a case-insensitive checkout, absolute imports, checkout conversions (A5), and three shapes A5 lists as untraced against Claude Code"

**Location:** `scripts/lib/dev-cycle-read.sh:467-471`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the agreement between the lib's list and A5's list. It does not cover Claude Code's behavior.

A5 lists the same five gaps and "three shapes untraced". Its last sentence names exactly three ("whether `@` references in `.claude/commands/` files load, whether a symlinked instruction file's imports resolve from the link's directory …, and whether an `@` token's `..` after a directory link resolves through the link", `docs/working/known-issues-dev-cycle.md:18`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:467-471`

---

## Claim 23: cache sentence "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again."

**Location:** `scripts/lib/dev-cycle-read.sh:472-474`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key, the reset to error, and the observable value after a success or a failure. It does not cover concurrent callers. Mid-walk, IMPORTED_MAIN is set to `$'\n'` at `:578` before the walk ends (settled row), but every later failure path resets it to `error`.

```bash
# scripts/lib/dev-cycle-read.sh:554-555
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"
```

Test 16 passes, and the cachereset mutant (dropping `IMPORTED_MAIN=error;`) kills it (X4).

**Evidence:** `scripts/lib/dev-cycle-read.sh:554-555`, `:578-614`, `test/scripts/build-loop-check.bats:295-304`, `$S/logs/mutants.summary`

---

## Claim 24: "nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0 and its output was empty or ended in NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:518`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the success and failure outcomes, including empty output and output not ending in NUL. It does not cover a CMD that reads stdin.

```bash
# scripts/lib/dev-cycle-read.sh:519
nul_list() { local -n nl_a="$1"; shift; mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }; unset 'nl_a[-1]'; }
```

The marker stands alone only if the output was empty or NUL-terminated; otherwise it is glued to the last name. A failure prints `rc=1`. Both of these, and an empty array, empty the array and return 1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:519`

---

## Claim 25: return-1 comment, every listed cause fails and every failure path is listed ("when main is not found by name, the commit's tree or the checkout's .md list (tracked and untracked) cannot be listed whole (nul_list), a tree record does not parse or has a type but blob, link or gitlink, a name is listed twice (git's lookups read the first copy), is also a directory of another listed name, or holds a newline, the lower-cased start list comes back short, a start file main lacks is listed (even one deleted from the checkout), a blob cannot be read, symlink text … or an imported path main lacks lies under … or exists in the checkout as anything but a plain directory below the root; need_root exits instead"); also `set -o pipefail  # as brief_fields`

**Location:** `scripts/lib/dev-cycle-read.sh:538-549`, `:551`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 17 `return 1` sites in main_imports (`:556`, `:557`, `:559`, `:561`, `:565`, `:566`, `:567`, `:570`, `:574`, `:583`, `:588`, `:590`, `:595`, `:600`, `:602`, `:611`, `:612`), which map to the listed causes, plus the parenthetical about git's lookup. The type clause is checked only on records the walk reaches, and it is unreachable. The does-not-parse clause also fires under a UTF-8 locale on a non-UTF-8 name (P8g: `C walk ok`, `C.UTF-8 walk failed`), which fails closed and is not called out.

- The first-copy parenthetical: `git cat-file blob "$t:AGENTS.md"` on a tree listing a link and then a blob under that name returns `x`, the link's text. With the blob first, it returns `@docs/b.md` (X9, P6).
- `:567`'s checkout-name newline is covered by "or holds a newline".
- `:583` also fails when import_targets' pipeline fails, which falls under "a blob cannot be read".
- brief_fields does the same: `local - out l; set -o pipefail` (`:321`).
- Every site's mutant is killed (X4, X5), except the unreachable `:602` and `:557` (masked in the suite, Claim 33; the code path was executed in P7, `walk: failed`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:321`, `:538-614`, `$S/logs/p2.out`, `$S/logs/p3.out`, `$S/logs/soft.summary`

---

## Claim 26: ancestor-pass comment "then a name that is also a directory of another listed name (a crafted tree) fails"

**Location:** `scripts/lib/dev-cycle-read.sh:564`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers blob, link and gitlink names that are also directory prefixes, in any listing order. It does not cover two same-named trees with disjoint files, which pass this check but fail closed at `cat-file` (X10 P8a).

Test 17 and the ancestor mutant are covered in Claim 1. P8a: two `docs` trees give `walk: failed` (`fatal: path 'docs/b.md' exists on disk, but not in …`). This repo's main is not wrongly refused (X8).

**Evidence:** `scripts/lib/dev-cycle-read.sh:565`, `$S/logs/p3.out`, `$S/logs/p1.out`

---

## Claim 27: symlink arm comments "a symlink: its text names the file read, as one more import"; "$(...) drops NULs, so they are counted first; the x keeps trailing newlines, which $(...) would also drop."; "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails."

**Location:** `scripts/lib/dev-cycle-read.sh:584-592`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL count, trailing-newline preservation, the recorded target and the `..`-after-link refusal for links on main and links only in the checkout. It does not cover `..` in `@` tokens, which is lexical and listed as untraced.

- nulcount flips 9:190.
- linknl flips 7:150, where the text is `notes.md\n`; it would be dropped without the `x`.
- mainlinkL flips 15:278 (the link only on main), and cklinkL flips 15:292 (the link only in the checkout).
- The target is recorded: the arm ends with `out` holding the resolved path, which the read loop at `:604-613` records (`IMPORTED_MAIN+="$(lower "$p")"$'\n'`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:584-600`, `:604-613`, `$S/logs/soft.summary`

---

## Claim 28: "160000) continue ;;  # a gitlink: its files are not main's" and the `*)` arm

**Location:** `scripts/lib/dev-cycle-read.sh:601-602`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a gitlink reached as a start or import: it is recorded, not read. It does not cover gitlink contents as starts (listed as not covered).

12:246's gitlink-at-`CLAUDE.md` case answers `walk ok` and `docs/x.md imported` from AGENTS.md. Deleting the arm makes it `walk failed` (X5 gitlinkarm). For `*)`, see Claim 3.

**Evidence:** `scripts/lib/dev-cycle-read.sh:601-602`, `test/scripts/build-loop-check.bats:246`, `$S/logs/soft-gitlinkarm.log`

---

## Claim 29: "Main lacks p: under a link or gitlink main stores, or in the checkout as anything but a plain directory, fail."

**Location:** `scripts/lib/dev-cycle-read.sh:610`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every ancestor, not just the parent (parentimm flips 15:288), and both link kinds. It does not cover an unsearchable checkout directory (settled, U2a3c).

`:611-612` was quoted in Claims 5 and 7. The mutants parent, gitlinkmatch, parentimm, ckprobe and plaindirallow each flip their assertions (X5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:610-612`, `$S/logs/soft.summary`

---

## Claim 30: isimported "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; a caller that words a failed walk runs main_imports first. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:616-620`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main/tree/other arms and the failed-walk answer. It does not cover isimported's own `lower` failing (U2a3b's area).

```bash
# scripts/lib/dev-cycle-read.sh:625-629
  case "$1" in
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
    tree) imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
    *) return 0 ;;
  esac
```

Tests 2, 8 and 14 pass, and blobread kills 8 and 14 (X5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:621-630`, `test/scripts/build-loop-check.bats:40-44`, `:154-163`, `:260-268`

---

## Claim 31: "Symlink text with a trailing newline, an absolute one, none, or one leaving the repo: the walk fails."

**Location:** `test/scripts/build-loop-check.bats:144`
**Type:** Behavioral (test)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the four iterations answering `walk failed`. It does not establish that the `''` iteration pins the empty-text check: with `:590`'s `-z` removed, empty text resolves to the root, which `:612` refuses. The empty-text check is pinned instead by test 12 (12:243).

The emptytext mutant flips only 12:243, while linknl, linkabs and linkleave each flip 7:150 (X5).

**Evidence:** `test/scripts/build-loop-check.bats:144-151`, `:239-243`, `$S/logs/soft-emptytext.log`

---

## Claim 32: "An import through a directory link main stores (the parent-link refusal)."

**Location:** `test/scripts/build-loop-check.bats:171`
**Type:** Behavioral (test)
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what 9:172's assertion pins. It does not affect coverage of the parent-link refusal, which tests 12 and 15 pin.

The `docs-link` link is checked out here, so with `:611` removed the walk still fails at `:612`: `docs-link/x.md` exists and is not a plain directory. The parent mutant does not flip 9:172. It flips 12:246, 15:284 and 15:288 (X5). Precise version: "(the parent-link refusal, or the checkout probe, since the link is checked out)".

**Evidence:** `test/scripts/build-loop-check.bats:166-172`, `scripts/lib/dev-cycle-read.sh:611-612`, `$S/logs/soft-parent.log`

---

## Claim 33: test 10 "main walk returns, not exits, when main's tree or the untracked list cannot be listed …"; "# The docs/ tree object is missing: ls-tree -r fails part-way."

**Location:** `test/scripts/build-loop-check.bats:193`, `:196-198`
**Type:** Behavioral (test)
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the tree-listing assertion at :198 pins. It is pinned for "returns, not exits", since status 0 is asserted. It is not pinned for "fails": the treefail mutant (`:557 … || return 1` → `|| true`) passes all 17 tests. The listing half is pinned (ckfail flips 10:202 and 10:206).

```bash
# test/scripts/build-loop-check.bats:194-198
    mkdir -p docs && printf 'see @a.md\n' > docs/CLAUDE.md && commit_all base
    imps main docs/a.md; want walk ok; want docs/a.md imported
    # The docs/ tree object is missing: ls-tree -r fails part-way.
    o="$(git rev-parse main:docs)"; rm ".git/objects/${o:0:2}/${o:2}"
    imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; want docs/b.md imported
```

(excerpt ends :198; enclosing test continues to :217 — read)

This is the same masking class as rubric F2. With `:557`'s refusal gone, `ent` is empty and the index still lists `docs/CLAUDE.md`, so it becomes a `t:` start main lacks and `:574` fails the walk. P7 (X9) reproduces this:

| State | Real lib | treefail mutant |
|---|---|---|
| index as test 10 leaves it | `walk: failed` | `walk: failed` |
| `docs/CLAUDE.md` removed from the index and the checkout | `walk: failed` | `walk: ok … docs/b.md: -` |

The real code takes the `:557` path (P7 prints `error: Could not read …` from ls-tree), so the lib is correct. Only the test does not pin it. The masking dates from dfeeb85d's index listing: at 2b22a082 the listing was `--others` only (X7 diff), so a tracked `docs/CLAUDE.md` was no candidate.

**Evidence:** `test/scripts/build-loop-check.bats:193-217`, `scripts/lib/dev-cycle-read.sh:557`, `:566-574`, `$S/logs/soft-treefail.log`, `$S/logs/soft.summary`, `$S/logs/p2.out`

---

## Claim 34: the other test names and comments in build-loop-check.bats (tests 1-6, 8, 11-17; the header; `imps`/`want` comments)

**Location:** `test/scripts/build-loop-check.bats:3-24`, `:26-62`, `:64-130`, `:154-163`, `:219-311`
**Type:** Behavioral (tests)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named behavior. Each is asserted, and each refusal flips under its mutant (X5 table). Ordering follows the file. It does not repeat Claims 31-33.

All 17 tests pass (X1, X2). Each `want walk failed` other than 9:172 (Claim 32) and 10:198 (Claim 33) is flipped by the mutant of the refusal it names. The `imps` comment, `"walk: ok" or "walk: failed" (main_imports' return; tree always reads ok)`, matches `if [[ "$w" != main ]] || main_imports; then echo "walk: ok"` (`:20`).

**Evidence:** `test/scripts/build-loop-check.bats:13-24`, `$S/logs/blc.txt`, `$S/logs/soft.summary`

---

## Claim 35: commit 2b22a082 figures: "build-loop-check.bats 16; 114 across the five suites. Mutants of the untracked-start refusal, the checkout probe, the gitlink match, the parent loop (immediate parent only), the plain-directory allowance and the link-text split each fail. 392 changed code lines against main." (headline and D13 sentence: override row `docs/reviews/override-log.md:388`, Accepted-immutable — pointer only)

**Location:** commit `2b22a082`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures and the six mutants, each run on 2b22a082's own archive. "Link-text split" is read as removing the split (`parts=("$out")`). A here-string revert of the split survived at 2b22a082 (`2b22a082 herestring: rc=0`); dfeeb85d later pinned it. Only the figures are verdicted here; the rest of the message has an Accepted-immutable override row.

From X7, at 2b22a082:
- 16 tests pass.
- untrackedstart is killed by [3 9 11], ckprobe by [3 9 12], gitlinkmatch by [12], parentimm by [15], plaindirallow by [9] and nosplit by [15].
- numstat gives 392.

114 = 75 + 19 + 16 + 2 + 2. The other four suites' counts are unchanged since (paraphrased — no quote available because this is per-file `bats --count` arithmetic).

**Evidence:** `$S/logs/oldmuts.summary`, `docs/reviews/override-log.md:388`

---

## Claim 36: commit dfeeb85d figures: "build-loop-check.bats 16; 114 across the five suites. Mutants of the index listing, the link-text split (here-string revert) and the newline check each fail. 400 changed code lines against main." (test-7/test-3 wording: override row `docs/reviews/override-log.md:395`, Accepted-immutable — pointer only)

**Location:** commit `dfeeb85d`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures and the three mutants on dfeeb85d's own archive. It does not cover the E1-E6 prose, apart from the code states that HEAD still holds (Claims 4, 13).

From X7, at dfeeb85d:
- 16 tests pass.
- indexlist is killed by [3], herestring by [10] and cknl by [7].
- numstat gives 400.

**Evidence:** `$S/logs/oldmuts.summary`, `docs/reviews/override-log.md:395`

---

## Claim 37a: commit 99cce51b behavior and figures: F1 "A pass after the record loop now fails the walk when a listed name is also a directory of another listed name (memoised ancestor walk)"; F2 "tests 5, 9 and 12 failed on a stale index-only CLAUDE.md before reaching the refusal they name …; they now `git rm -qf CLAUDE.md` first"; F5 "the two checkout listings are one `ls-files --cached --others` call …; a gitlink at a start name and a git whose `ls-files --cached` fails are pinned"; "build-loop-check.bats 17; 115 across the five suites. Mutants of the ancestor pass, the tree-name newline check, the NUL count, the empty-text check, the gitlink arm and the index half of the listing each fail. 400 changed code lines against main."

**Location:** commit `99cce51b`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fixes, the figures and the six named mutants, run at HEAD; 99cce51b and HEAD differ only in docs. The message does not claim, and this verdict does not establish, that no other refusal stayed masked (Claim 33).

- Six mutants: ancestor kills 17, treenl 5, nulcount 9, emptytext 12, gitlinkarm 12, and indexhalf kills 3 and 10 (X4).
- F2's masking was confirmed (Claim 2).
- 17 tests, and 115 = 75+19+17+2+2 (X2).
- numstat at 99cce51b gives 400 (X7).
- `git diff 99cce51b 0bb98f27 --stat` touches only `docs/` (paraphrased — no quote available because this comes from `git show --stat 0bb98f27`: plan and fix-drift file only).

**Evidence:** `$S/logs/mutants.summary`, `$S/logs/suites.out`, `$S/logs/oldmuts.summary`, `$S/logs/mask.summary`

---

## Claim 37b: commit 99cce51b F3: "override rows, listed in A5 and F11; the U2b bullet makes the gate refuse them"

**Location:** commit `99cce51b`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the U2b bullet says. It does not cover the override rows, which say the same as Claim 9.

At HEAD the bullet reads "U2b is to refuse (not built yet; the walk does not check this)" (`docs/working/plan-build-loop-handoff.md:279`). That is a plan item for U2b, not a gate that refuses. 0bb98f27 tightened the bullet in response to the fix-drift finding (`docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i2.txt`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i2.txt:1-3`

---

## Claim 38: commit 0bb98f27 "the U2b bullet states the checkout-conversion refusal as U2b's to build … Notes: lite-review fix-drift finding 1 on 99cce51b; output committed."

**Location:** commit `0bb98f27`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the bullet's new wording and the committed fix-drift output. It does not cover anything else.

`git show --stat 0bb98f27` lists `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i2.txt | 3 +++` and `docs/working/plan-build-loop-handoff.md | 2 +-`. The finding says "asserts that U2b 'refuses a checkout …' … with no visible implementation". The bullet now says "U2b is to refuse (not built yet; the walk does not check this)" (`docs/working/plan-build-loop-handoff.md:279`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i2.txt:1-3`

---

## Claim 39: docs-only commits: 5c57d367 and 1898d21c "fix-drift output … (no findings)"; 0032ed5a and 664c18fe "fact-check, critic reports, rubric and override rows"

**Location:** commits `5c57d367`, `0032ed5a`, `1898d21c`, `664c18fe`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and contents of the named fix-drift outputs and the presence of the report files. It does not cover the reports' contents.

`lite-review-fix-drift-build-loop-u2a3-split.txt` and `-L2i1.txt` each read `lite-review [fix-drift]: FINDINGS: NONE`. The `-L2-` and `-L2f-` reports, the merged `-L2-final` and the rubric's Loop 2 iteration sections are in the diff (`git diff --stat main...HEAD`).

**Evidence:** `docs/reviews/lite-review-fix-drift-build-loop-u2a3-split.txt:1`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i1.txt:1`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 9** (`docs/reviews/override-log.md:391-392`): "the U2b bullet makes the gate refuse" should read "asks U2b to make the gate refuse". The log is append-only; the bullet itself is now precise.
- **Claim 32** (`test/scripts/build-loop-check.bats:171`): 9:172 is also met by the checkout probe (the link is checked out), so it does not pin the parent-link refusal alone. Tests 12 and 15 do pin it.
- **Claim 33** (`test/scripts/build-loop-check.bats:193-198`): the tree-listing refusal (`:557`) is masked by the index-only `docs/CLAUDE.md`. The treefail mutant survives all 17 tests. This is a fourth instance of rubric F2's masking class.
- **Claim 37b** (commit 99cce51b): "the U2b bullet makes the gate refuse them" was a plan statement; 0bb98f27 corrected the bullet.

### Unverifiable
(none)

## Escalations

- `test/scripts/build-loop-check.bats:196-198` → test-strategy and implementer: the `:557` tree-listing refusal is unpinned. Before line 198, take `docs/CLAUDE.md` out of both the index and the checkout. `git rm -q --cached` alone leaves it untracked, which `--others` lists, so the refusal stays masked. Restore it before line 204's `commit_all again`. P7 shows that the treefail mutant is then killed (`walk: ok` under the mutant, `walk: failed` under the real lib).
- `test/scripts/build-loop-check.bats:171` → test-strategy (Informational): the comment names the parent-link refusal, but the assertion is also met by the checkout probe.
- `scripts/lib/dev-cycle-read.sh:559` → U2a4/U2b caller (Informational): under a UTF-8 locale, a non-UTF-8 name in main fails the walk (`C.UTF-8 walk failed`, X10 P8g). It fails closed, but the caller should run the walk under `LC_ALL=C`, as the suite does. `scripts/build-loop.sh` sets no global `LC_ALL`.
- `docs/reviews/override-log.md:391-392` → coordinator (Informational): the "makes the gate refuse" wording stays in the append-only log; the plan bullet is correct.

## Goal-Alignment Note

**Success criterion:** A code-fact-check report verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages, saved at the path given below.

**Answered:** Yes. The report has 40 claims, covering the six focus items:
1. Every main_imports lib comment (Claims 19-30), plus a fail-closed probe over crafted trees (two same-named trees, unsorted, slash name, non-canonical modes, blob-is-tree, `.` subtree) and checkout states (index-only deleted, ignored, root import, linked worktree). No fail-open was found beyond the documented and settled gaps.
2. The ancestor pass and merged listing (Claims 1, 3, 8, 26), including no wrong refusal of this repo's main.
3. A5, F11 and the U2a3 and U2b bullets (Claims 12-18). The U2a3c bullet is a plan with no code to check.
4. Every commit since 0170f16a (Claims 35-39), with figures executed: 17 tests; 115 across the five suites; 400 lines at HEAD and 99cce51b, 400 at dfeeb85d, 392 at 2b22a082. Every named mutant was executed on its own commit. Accepted-immutable parts get pointers only.
5. Every test assertion was mapped to the mutants that flip it. One unmasked gap was found (Claim 33) and one mislabelled assertion (Claim 32).
6. The rubric's Loop 2 rows and the override rows since 0170f16a (Claims 1-11).

All five suites pass at HEAD (115/115). 27 HEAD mutants were run at assertion level; all are killed except treefail (masked, Claim 33) and starterr (unreachable arm, settled).

**Out of scope:** U2a3b's parser, failing sed/grep/lower, and settled override rows (deferred git hardening, the cache contract, unsearchable directories, the untraced Claude Code shapes) were not re-filed. Claude Code's own loading behavior was not executed.

**Escalate:** test 10's masked tree-listing refusal (Claim 33) to test-strategy and the implementer. It is a test gap only; the lib refuses correctly (P7).
