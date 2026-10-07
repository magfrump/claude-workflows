Commit: cebfed35
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3c`, branch `feat/build-loop-u2a3c`)
**Scope:** `git diff 5e51b58b..HEAD` (one commit, cebfed35): comments in `scripts/lib/dev-cycle-read.sh` (`checkout_md`, `main_checkout`, `main_imports`, the header blocks), test names and comments in `test/scripts/build-loop-check.bats`, `docs/working/known-issues-dev-cycle.md` row A5, `docs/working/plan-build-loop-handoff.md` row F11 and the U2a3c and U2b bullets, and the commit message of cebfed35. Three pre-existing test comments outside the hunks are included because this commit's behaviour change makes them stale (Claim 30).
**Checked:** 2026-10-06
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 33 (30 numbered; 10, 17 and 22 split into a/b)
**Summary:** 24 verified, 3 mostly accurate, 2 stale, 4 incorrect, 0 unverifiable

Legibility-target values: **maintainer** (someone editing the lib or its tests), **reviewer** (someone reading the commit message, plan or known-issues row to decide what the code guarantees).

No claim matches an entry in `docs/reviews/hallucination-patterns.md`. The closest pattern is the logged class of wrong test-count tallies (commits 59ca38f and 37c5ea9), and this commit's tallies were checked against it (Claim 21): they are correct. None of the three Incorrect verdicts is a fabricated symbol, so the pattern log is not updated (this pass also writes nothing but this report).

## Execution provenance

Scratch: `/tmp/u2a3c-fc-HJEc` (`$S`). Every run used `TMPDIR=$S/tmp` and a hermetic git environment (`GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, `LC_ALL=C`). Timestamps are UTC on 2026-10-07 (2026-10-06 local). The worktree was never edited: mutants ran on `$S/copy` (a `git archive HEAD scripts test` export), and after each run the copy's lib and test file were checked byte-equal to the worktree's with `cmp`. The process ran as uid 1000, not root. No background process was started. All chmods inside fixtures were restored, except one mode-000 file left inside `$S/fx/p1`.

- **X1. Five suites.** At 05:06:11Z in cwd `/workspace/.claude/wt-build-loop-u2a3c`: `TMPDIR=$S/tmp timeout 900 bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/build-loop-check.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`. This is the five-suite set U2a3's fact-check used. Exit 0, `1..116`, 116 ok, 0 not ok. Output: `$S/logs/x1-five.txt`. An earlier run at 04:59:35Z swapped `fixture-hermeticity` for `utility-smoke.bats` (also 2 tests) and also gave exit 0 with 116 ok. Output: `$S/logs/worktree-5suites.txt`.
- **X2. Mutants.** `$S/scripts/mut.py LIB NAME` applies one exact-string edit to the copy's lib. Then `TMPDIR=$S/tmp timeout 600 bats test/scripts/build-loop-check.bats` runs in cwd `$S/copy`. The batch started at 05:02:18Z. Outputs are in `$S/logs/mut-NAME.txt`. Results (exit code, then failing tests by ordinal):
  - `parentlink`: drop `! "${ent[$c]:-}" =~ ^1[26]0000$` from `main_checkout`'s loop. Exit 1; tests 12, 15 and 18 fail.
  - `unsearchable`: drop `( ! -d "$c" || -x "$c" )`. Exit 1; test 18 fails.
  - `listwarn`: drop `&& [[ -z "$e" ]]` from `checkout_md`. Exit 1; test 18 fails.
  - `startadmit`: replace the start loop's `main_checkout "$f"` with an existence check only. Exit 1; test 9 fails.
  - `p2imports`: drop `[[ $c -ne 0 ]] || tq+=("$p")`. Exit 1; tests 3, 6 and 13 fail.
  - `p2swap`: replace the `queue=("${tq[@]}")` swap with `break`. Exit 1; tests 3, 6, 11, 13 and 16 fail.
  - `readable`: `[[ -r "$1" ]]; return` becomes `return 0`. Exit 0; it survives.
  - `readarm`: the checkout arm's `|| { IMPORTED_MAIN=error; return 1; }` becomes `|| true`. Exit 0; it survives.
  - `readable+readarm`: exit 1; test 9 fails.
  - `treelist`: the `ls-tree` `nul_list ... || return 1` becomes `|| true`. Exit 1; test 10 fails.
  - `parentimmediate`: the ancestor loop checks only the immediate parent. Exit 1; test 15 fails.
  - `seenafter`: mark an import main lacks as seen only after `main_checkout` admits it. Exit 0; it survives, as an equivalent mutant.
- **X3. `startnoparent`.** The start loop runs `( declare -A ent=(); main_checkout "$f" )`, which disables the main-link and gitlink parent check for starts only. It ran at 05:03:59Z, same command. Exit 0; it survives. Output: `$S/logs/mut-startnoparent.txt`.
- **X4. `plainarm`.** `main_checkout`'s final `return 1` answers 2 for anything but a regular file. It ran at 05:05:31Z. Exit 1; tests 9 and 12 fail. Output: `$S/logs/mut-plainarm.txt`.
- **X5. Masking-comment checks.**
  - `$S/scripts/mask.sh`, on the copy, removes the `git rm -qf CLAUDE.md` lines of tests 9 and 12 that carry "no index-only start masks" comments. It then runs those two tests unmutated, under a NUL-count mutant and under an empty-text mutant. Unmutated, exit 0. The NUL-count mutant fails test 9 and the empty-text mutant fails test 12. Outputs: `$S/logs/t9t12-norm-*.txt`.
  - For test 10, the `git rm -qf docs/CLAUDE.md` was removed and the test was run unmutated (exit 0) and under `treelist` (exit 1: `walk: ok` where `walk: failed` was wanted). Outputs: `$S/logs/t10-normm-*.txt`.
- **X6. Probes.** `bash $S/scripts/pN.sh` (harness `$S/scripts/h.sh`) builds fixture repos under `$S/fx/pN`.
  - `p1` calls `main_checkout` directly with a chosen `ent`. Output: `$S/logs/p1.txt`.
  - `p2` covers `checkout_md` and the walk under a 000 directory, a `--x` directory and `GIT_TRACE=1`. Output: `$S/logs/p2.txt`.
  - `p3` and `p4` show what the start-only parent mutant lets through. Outputs: `$S/logs/p3.txt` and `$S/logs/p4.txt`.
  - `p5` covers a checkout start importing a main path with an edited checkout copy, `@.`, an index-only start deleted from the checkout, and a start main also imports. Output: `$S/logs/p5.txt`.
  - All probes ran between 05:00Z and 05:05Z, each exiting 0.

These logs live in the scratch directory, not under `docs/reviews/execution-logs/`, because this pass may write only this report.

---

## Claim 1: "Its checkout phase (U2a3c) then walks, and only appends: the checkout's start files main lacks (untracked, ignored, or only in the index) and the imported files main lacks, when each is a plain file there; a checkout path it would walk that lies under a directory main stores as a link or gitlink or under an unsearchable directory, anything but a plain file or directory there (or nothing), an unreadable checkout file, a `..` after a checkout link in link text, and a checkout listing git warns about fail it."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each refusal and each walked category listed, against `main_checkout`, `checkout_md` and the drain loop. It does not establish that the refusal is complete against Claude Code's loader (the A5 "Not covered" list owns that), and it does not establish the precision of "warns" (any git stderr fails the walk; see Claim 10b).
**Legibility-target:** reviewer

The walked categories come from `checkout_md`, which lists `--cached --others`:

```bash
# scripts/lib/dev-cycle-read.sh:524
checkout_md() { local e; { e="$(GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached --others -- ':(glob,icase)**/*.md' 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }
```

They are then filtered to names main lacks (`:582 [[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")`) and admitted by `main_checkout`:

```bash
# scripts/lib/dev-cycle-read.sh:529-535 (whole unit)
main_checkout() {
  local c="$1"
  while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ && ( ! -d "$c" || -x "$c" ) ]] || return 1; done
  if inrepo_here "$1"; then [[ -r "$1" ]]; return; fi
  if [[ -d "$1" && ! -L "$1" && -z "$(blocker "$1" dir)" ]] || [[ ! -e "$1" && ! -L "$1" ]]; then return 2; fi
  return 1
}
```

Probes p1 and p2 found the following. A path under a main link or gitlink, a FIFO, a socket, a live link, a dangling link, a directory link, a mode-000 file, `.` and a path under an unsearchable ancestor each return 1. A plain directory and an absent path return 2. The 000-directory listing fails the walk (`walk: failed`, `$S/logs/p2.txt`). An ignored start is walked (test 3, `printf 'CLAUDE.local.md\n' > .gitignore`, passes in X1). An index-only start is walked (test 3, `git add -f`). The `..` after a checkout link is the pre-existing `-L "$p"` at `:615`. An index-only start deleted from the checkout is skipped (rc 2, p5: `walk: ok sub/agents.md: imported sub/gone-target.md: -`), which matches "when each is a plain file there".

**Evidence:** `scripts/lib/dev-cycle-read.sh:524`, `:529-535`, `:581-593`, `:615`, `:622-630`; `$S/logs/p1.txt`, `$S/logs/p2.txt`, `$S/logs/p5.txt`, `$S/logs/x1-five.txt`

---

## Claim 2: A5's "Not covered" list is still accurate after this commit (start files under a symlinked directory or in a submodule or untracked nested repo, case-insensitive names, absolute imports, checkout conversions, three untraced shapes)

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the symlinked-directory start gap (probed) and confirms that this commit's code adds nothing that closes or widens the other listed gaps (static). It does not establish Claude Code's own behaviour on the three untraced shapes, and it does not cover submodule or nested-repo listing (that was not re-probed).
**Legibility-target:** reviewer

p4 runs with main storing `.claude/rules -> ../docs` and the checkout equal to main. The walk answers `walk: ok docs/bar.md: -` (`$S/logs/p4.txt`), so a start under a symlinked directory is still not started, as the row says. When the checkout replaces that link with a plain directory holding an untracked rule, the walk fails (`walk: failed docs/bar.md: imported`). That is the C1 admission refusing it, not new coverage. The commit adds no conversion, case-folding or absolute-import handling: `main_checkout` and `checkout_md` (quoted in Claim 1) are the only new code, and the checkout read arm `:600` reads raw bytes with `import_targets "$d" < "$f"`. Absolute tokens are still dropped in `import_targets` (`:504 [[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:504`, `:600`; `$S/logs/p4.txt`

---

## Claim 3: F11: "U2a3c adds the checkout phase: once main's walk is done, the checkout's start files main lacks (untracked, ignored or only in the index) and imported files main lacks are walked when each is a plain file there, and only append; one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, or anything but a plain file or directory, and a checkout listing git warns about fails the walk."

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same mechanisms as Claim 1. It does not establish the unreadable-file refusal, which F11 leaves out but A5 lists. The omission is not a misstatement, because the `-r` check sits inside `main_checkout` (`:532 if inrepo_here "$1"; then [[ -r "$1" ]]; return; fi`).
**Legibility-target:** reviewer

Same evidence as Claim 1: "once main's walk is done" is the drain swap `:596 [[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }  # phase 2: main's walk is done`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:529-535`, `:595-597`; X2 (`p2swap`, `parentlink`, `unsearchable`, `listwarn` each fail)

---

## Claim 4: U2a3c bullet: "every phase-2 item passes one admission check (main's links and gitlinks, the checkout's links) before it is marked seen"

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order of `seen` marking against `main_checkout` for both producers of phase-2 items. It does not establish any behavioural consequence: the reordering mutant is equivalent (see below), and no fail-open follows from the order.
**Legibility-target:** maintainer

The order holds for starts (`:589-591`: `main_checkout "$f"` and then `seen[$f]=1`). It does not hold for imports main lacks, the other source of phase-2 items. There the path is marked seen first and admitted afterwards:

```bash
# scripts/lib/dev-cycle-read.sh:625-629 (excerpt ends :629; enclosing main_imports() continues to :632 — read)
      [[ -z "${seen[$p]+set}" ]] || continue
      seen[$p]=1
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); continue; fi
      c=0; main_checkout "$p" || c=$?  # main lacks p
      [[ $c -ne 1 ]] || { IMPORTED_MAIN=error; return 1; }; [[ $c -ne 0 ]] || tq+=("$p")
```

What the code does is check-before-queue, with seen marked immediately before the check and no exit between the two. The mutant `seenafter`, which marks seen only after admission, survives all 18 tests (X2) and is equivalent: rc 1 ends the walk, and rc 2 is the same answer the next time the path is reached. The bullet is a context line rather than a hunk, but it describes this commit's design. The commit message (Claim 17b) and the review intent repeat the same ordering. The parenthetical also leaves out the unsearchable-directory and unreadable-file refusals; that is an omission only.

**Evidence:** `scripts/lib/dev-cycle-read.sh:589-591`, `:625-629`; `$S/logs/mut-seenafter.txt`

---

## Claim 5: U2b bullet: "It names the checkout `--check` runs from (the walk reads its untracked, ignored and index-only start files and the imported files main lacks there)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the walk reads from the checkout. It does not establish anything about U2b's own refusal (not built; the bullet says so).
**Legibility-target:** reviewer

Test 3 walks an untracked, an ignored and an index-only start (X1 passes; `p2imports` and `p2swap` fail it in X2). The checkout read arm is `:600 checkout) out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; } ;;`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:600`; `test/scripts/build-loop-check.bats:46-63`; X1, X2

---

## Claim 6: "check_brief, check_branch, ... read the default branch's commit, never the working tree (...), and so does main_imports (after main's walk it walks the checkout's start files and imported files main lacks, which can only add imports or fail it; ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-35`
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sentence's description of `main_imports`' inputs. It does not separately verdict "can only add imports or fail it" (see Claim 16).
**Legibility-target:** maintainer

"and so does main_imports" attaches to "read the default branch's commit, never the working tree", and the parenthetical then says it walks checkout files. Phase 2 reads working-tree bytes directly (`:600 out="$(import_targets "$d" < "$f")"`). The precise version is: "main_imports reads the default branch's commit first, then the working tree's start files and imported files main lacks, which can only add imports or fail it." The parenthetical is accurate. The governing clause is the imprecise part.

**Evidence:** `scripts/lib/dev-cycle-read.sh:29-35`, `:600`

---

## Claim 7: "Once main's walk is done, a second phase walks the checkout's start files main lacks (untracked, ignored or only in the index) and the imported files main lacks, when each is a plain file there, and only appends."

**Location:** `scripts/lib/dev-cycle-read.sh:456-459`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seeding of the phase-2 queue (`tq`) and the swap point. It does not establish that "plain file" includes the readable requirement; the refusal list at `:463-467` says "readable plain file".
**Legibility-target:** maintainer

`tq` gets starts that main lacks (`:591 ... else tq+=("$f"); fi`) and imports that main lacks and `main_checkout` admits (`:629 [[ $c -ne 0 ]] || tq+=("$p")`). `tq` joins the queue only once `queue` is empty (`:596`). `IMPORTED_MAIN` is only ever appended to (`:624 IMPORTED_MAIN+="$(lower "$p")"$'\n'`). The `p2swap` and `p2imports` mutants fail tests 3, 6, 11, 13 and 16 (X2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:589-596`, `:622-630`; X2

---

## Claim 8: "a checkout path it would walk (a start or an import main lacks) that lies under a directory main stores as a symlink or gitlink or under an unsearchable directory, or that the checkout holds as anything but a readable plain file, a plain directory or nothing (the root included), or a checkout listing git warns about, fail the walk, so isimported main answers imported for every path."

**Location:** `scripts/lib/dev-cycle-read.sh:463-468`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal and the "root included" case. It does not establish the exact trigger of the listing refusal, which is any stderr rather than only warnings (Claim 10b).
**Legibility-target:** maintainer

p1 (`$S/logs/p1.txt`) shows:

- `main_checkout . -> 1`. This is because `blocker . dir` prints `./`: `plaindir .` compares `realpath -e .` with `$ROOT_REAL/.`.
- `fifo.md`, `sock.md`, `devl`, `live.md`, `dangling.md`, `dirlink` and `u.md` (mode 000) each give `-> 1`.
- `gp/par/f.md` gives `-> 1` with `gp` at both `rw-` and 000.

p5 shows that `@.` from a main file fails the walk (`walk: failed docs/m.md: imported`). A failed walk makes `isimported` answer 0 (`:643 main) main_imports || return 0;`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:110-120`, `:529-535`, `:638-647`; `$S/logs/p1.txt`, `$S/logs/p5.txt`

---

## Claim 9: "the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again."

**Location:** `scripts/lib/dev-cycle-read.sh:474-476`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache key, which excludes checkout state, and the documented reset. It does not establish that callers do reset it; that is U2b's concern and is deferred in the override log.
**Legibility-target:** maintainer

```bash
# scripts/lib/dev-cycle-read.sh:569-570
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"
```

Test 16 expects `- - z.sh` across the uncleared and cleared calls, and it passes (X1). The `p2swap` mutant fails it (X2), so the test reaches phase 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-570`; `test/scripts/build-loop-check.bats:298-307`; X1, X2

---

## Claim 10a: `checkout_md` lists "tracked, untracked and ignored" .md files to stdout, and its `{ e="$(... 2>&1 >&3)"; } 3>&1` keeps stdout flowing to `nul_list` while capturing only stderr; a 000 directory produces a warning and a nonzero result

**Location:** `scripts/lib/dev-cycle-read.sh:522-524`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the redirection, the listing categories, and the 000 and `--x` directory cases. It does not establish what git does with an unreadable directory in other git versions (the probe used the sandbox's git).
**Legibility-target:** maintainer

Inside the substitution, `2>&1` sends stderr into the captured pipe, and then `>&3` sends stdout to fd 3, which `3>&1` binds to the function's stdout (the `nul_list` process substitution). The assignment's status is git's exit status, so `&& [[ -z "$e" ]]` fails on either a nonzero exit or non-empty stderr. The p2 runs (`$S/logs/p2.txt`) show this:

- Direct run: stdout is `CLAUDE.local.md|hid/CLAUDE.md|CLAUDE.md|` with rc 0.
- With `hid` at mode 000, raw git prints `warning: could not open directory 'hid/': Permission denied` and exits 0. `checkout_md` returns `rc=1`, and the walk answers `walk: failed`.
- `--x` (111) on `hid` also gives `walk: failed`.

The test-10 wrapper git, which exits 1 with no stderr, makes the walk fail (X1 passes it). So a silent failure is still caught.

**Evidence:** `scripts/lib/dev-cycle-read.sh:521-524`, `:581`; `test/scripts/build-loop-check.bats:208`; `$S/logs/p2.txt`

---

## Claim 10b: "fails when git warns, since an unreadable directory goes unlisted"

**Location:** `scripts/lib/dev-cycle-read.sh:523`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the trigger condition. It does not establish that any real gate environment emits harmless git stderr. Because the effect fails closed, this is a precision note, not a fail-open.
**Legibility-target:** maintainer

The function fails on any git stderr, not only warnings. With `GIT_TRACE=1` (trace lines only), `checkout_md` returns `rc=1` and the walk answers `walk: failed docs/a.md: imported` (`$S/logs/p2.txt`). The precise wording is "fails when git exits nonzero or writes anything to stderr". The `main_imports` comment at `:556-557` ("cannot be listed whole (nul_list, checkout_md)") is similarly broad. Only git's stderr is captured: the bash `setlocale` warning seen in this sandbox comes from the parent shell, not from `git`, and does not reach `e`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:524`; `$S/logs/p2.txt`

---

## Claim 11: "main_checkout PATH ... 0 for a plain checkout file to walk, 2 when nothing there loads (absent, or a plain directory), 1 to fail the walk: a parent main stores as a link or gitlink, an unsearchable parent directory, or anything else."

**Location:** `scripts/lib/dev-cycle-read.sh:525-528`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every return path, probed over the shapes the brief lists. It does not establish behaviour under root (uid 0 passes `-x` and `-r` on 000 modes, but can then also read them), or under a race between check and read.
**Legibility-target:** maintainer

The return codes match. Two qualifiers are missing:

1. "parent" means every ancestor, not only the immediate parent. The loop (`:531`, quoted in Claim 1) visits each prefix, and the `parentimmediate` mutant fails test 15 (X2).
2. "absent" includes three cases where `stat` fails beneath a checkout non-directory:
   - a path under a checkout regular file: `regfile/x.md -> 2`;
   - a path under a checkout directory link whose target lacks it (main storing no link there): `lnkdir/none.md -> 2`;
   - a path under a dangling link.

None of these loads anything, so rc 2 is correct.

Results by probe shape (`$S/logs/p1.txt`):

| Shape | Result |
|---|---|
| Parent is a checkout symlink, main stores a tree there; file below | `lnkdir/f.md -> 1` |
| Same parent; directory below | `lnkdir/sub -> 1` |
| Parent main stores as 120000 or 160000 | `-> 1` |
| Same parent with ent 100644 | `-> 0` |
| FIFO, socket, link to a device | `-> 1` |
| Live symlink, dangling symlink | `-> 1` |
| Mode-000 file | `-> 1` |
| Directory symlink | `-> 1` |
| Grandparent `rw-` or 000 | `-> 1` |
| `--x` parent, file present | `-> 0` (readable, so walked) |
| `--x` parent, file absent | `-> 2` |
| The root `.` | `-> 1` |

`""` gives 2, but it is unreachable, because the drain loop skips empty `p` (`:623`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:529-535`, `:623`; `$S/logs/p1.txt`; `$S/logs/mut-parentimmediate.txt`

---

## Claim 12: main_imports returns 1 "when ... the checkout's .md list (tracked and untracked) cannot be listed whole (nul_list, checkout_md), ..., main_checkout refuses a start or an import main lacks, a blob or checkout file cannot be read, ..."

**Location:** `scripts/lib/dev-cycle-read.sh:554-563`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failure arms this commit added or changed (`checkout_md`, both `main_checkout` call sites, and the checkout read arm). The arms that predate this commit were verified in U2a3's passes and were not re-probed beyond X1. It does not establish the "warns" precision, which is in Claim 10b.
**Legibility-target:** maintainer

The arms are:

- `:581 nul_list recs checkout_md || return 1`
- `:590 [[ $c -ne 1 ]] || return 1`
- `:629 [[ $c -ne 1 ]] || { IMPORTED_MAIN=error; return 1; }`
- `:600 checkout) ... || { IMPORTED_MAIN=error; return 1; }`

The `readable+readarm` mutant fails test 9, `listwarn` fails test 18, and `startadmit` fails test 9 (X2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:581`, `:589-591`, `:600`, `:628-629`; X2

---

## Claim 13: "Phase 2 begins when queue empties: tq's checkout files then join it, and a path main lacks reads the checkout."

**Location:** `scripts/lib/dev-cycle-read.sh:563-564`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the swap and the dispatch on `${ent[$f]-checkout}`. It does not establish ordering among phase-2 items, which does not matter for the result.
**Legibility-target:** maintainer

```bash
# scripts/lib/dev-cycle-read.sh:595-600 (excerpt ends :600; enclosing main_imports() continues to :632 — read)
  while [[ ${#queue[@]} -gt 0 || ${#tq[@]} -gt 0 ]]; do
    [[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }  # phase 2: main's walk is done
    f="${queue[0]}"; queue=("${queue[@]:1}")
    if [[ "$f" == */* ]]; then d="${f%/*}"; else d=""; fi
    case "${ent[$f]-checkout}" in
      checkout) out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; } ;;
```

`${ent[$f]-checkout}` (no colon) substitutes only when the key is unset. Every `ent` value comes from the `[01234567]{6}` capture at `:574` and is never empty, so a name main stores cannot be routed to the checkout arm.

**Evidence:** `scripts/lib/dev-cycle-read.sh:574-577`, `:595-600`

---

## Claim 14: "Main's walk runs to a fixpoint first; then `tq` (...) joins the queue"

**Location:** commit cebfed35 message, paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the paths reached from main's starts. A main path reached only through a checkout file is read during phase 2, which is consistent with "main's walk" meaning the walk from main's starts.
**Legibility-target:** reviewer

See Claim 13. Every `tq` producer (`:591`, `:629`) appends to `tq`, never to `queue`, so `queue` drains to empty before the first swap.

**Evidence:** `scripts/lib/dev-cycle-read.sh:591`, `:596`, `:629`

---

## Claim 15: "a path main stores that a checkout file imports is still read through main's arms"

**Location:** commit cebfed35 message, paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the dispatch for imports of names in `ent`. It establishes that the checkout's edited copy of such a file is ignored, and so are any extra imports the edit adds. Whether that is the right policy (Claude Code in the checkout would load the edited copy) is a design question outside this check. This is the existing "a working-tree edit does not count" rule (test 3).
**Legibility-target:** reviewer

`:627 if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); continue; fi` queues a path main stores, and the `case` then reads `git cat-file blob "$MAIN_SHA:$f"` (`:601`). In p5, an untracked `CLAUDE.local.md` imports `docs/orph.md`. Main's copy imports `o2.md`, and the checkout copy was edited to import `evil.md`. The result is `walk: ok docs/o2.md: imported docs/evil.md: -` (`$S/logs/p5.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:601`, `:627`; `$S/logs/p5.txt`

---

## Claim 16: "Everything a checkout path adds is appended; nothing it does can drop an import." (also `:47-49` "which can only add imports or fail it")

**Location:** commit cebfed35 message, paragraph 1; `scripts/lib/dev-cycle-read.sh:47-49`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every write to `IMPORTED_MAIN`, `seen` and `queue` in `main_imports`, compared with a main-only walk of the same commit. It does not cover the cache (a checkout change after a walk is not seen; that is documented and deferred, Claim 9) or the conversion gaps listed in A5.
**Legibility-target:** reviewer

The invariant holds for these reasons:

- `IMPORTED_MAIN` is only ever appended to (`:624`), and every import token is recorded before the `seen` test (`:624` precedes `:625`).
- The only checkout paths marked seen before main's walk ends are starts that main lacks (`:591`), which are not in `ent` and so never shadow a path main stores. p5 shows a start that main also imports still yields its imports (`sub/agents.md: imported sub/t2.md: imported`).
- The swap at `:596` runs only on an empty `queue`, so it drops nothing.
- In phase 1, checkout state can only fail the walk: the `-L "$p"` check at `:615`, and `main_checkout` rc 1 at `:629`.
- An index-only start deleted from the checkout is now skipped rather than failed. That changes a failure into an ok walk, but it drops no import: main never had the file, and its absence yields nothing to record.

**Evidence:** `scripts/lib/dev-cycle-read.sh:589-596`, `:615`, `:622-630`; `$S/logs/p5.txt`

---

## Claim 17a: "One admission check, `main_checkout`, runs before any checkout path is marked seen, starts included" — starts half

**Location:** commit cebfed35 message, paragraph 2; `scripts/lib/dev-cycle-read.sh:589-591`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start candidates main lacks (`t:`). It does not cover the imports half (Claim 17b), or whether a test pins the start-parent half (Claim 22a).
**Legibility-target:** reviewer

```bash
# scripts/lib/dev-cycle-read.sh:589-591
      f="${cand[i]:2}"; c=0; [[ "${cand[i]:0:1}" == m ]] || main_checkout "$f" || c=$?
      [[ $c -ne 1 ]] || return 1; [[ $c -eq 0 ]] || continue
      seen[$f]=1; if [[ -n "${ent[$f]+set}" ]]; then queue+=("$f"); else tq+=("$f"); fi
```

A start skipped with rc 2 is not marked seen, so a later import of it is checked again (p5: `sub/agents.md: imported sub/gone-target.md: -`, walk ok). The `startadmit` mutant fails test 9 (X2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:589-591`; `$S/logs/p5.txt`; X2

---

## Claim 17b: the same sentence, imports half ("before any checkout path is marked seen")

**Location:** commit cebfed35 message, paragraph 2; `scripts/lib/dev-cycle-read.sh:625-629`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal ordering for imports main lacks. It establishes that the ordering is equivalent in effect, so this is a documentation mismatch with no behavioural (code-contract) fail-open.
**Legibility-target:** reviewer

`seen[$p]=1` at `:626` runs before `main_checkout "$p"` at `:628` (quoted in Claim 4). The accurate statement is: "admits every checkout path before it is queued; starts are admitted before they are marked seen, and imports immediately after." The `seenafter` mutant is equivalent (X2, exit 0).

**Evidence:** `scripts/lib/dev-cycle-read.sh:625-629`; `$S/logs/mut-seenafter.txt`

---

## Claim 18: "It refuses a path under a link or gitlink main stores (C2), under an unsearchable directory (C3, fail closed as the coordinator set), or anything but a readable plain file, a plain directory or nothing. `checkout_md` lists the seeds and fails when git warns (an unreadable directory goes unlisted; C3's ls-files half)."

**Location:** commit cebfed35 message, paragraph 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same evidence as Claims 1, 10a and 11. The "warns" precision is in Claim 10b.
**Legibility-target:** reviewer

See Claims 10a and 11 (`$S/logs/p1.txt`, `$S/logs/p2.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:524`, `:529-535`

---

## Claim 19: "tests 3, 11, 16 and the "follows" and cycle tests walk the checkout again"

**Location:** commit cebfed35 message, paragraph 3
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each named test exercises phase 2. It does not establish what each one pins individually beyond the mutant that fails it.
**Legibility-target:** reviewer

The `p2swap` mutant fails tests 3, 6 ("follows"), 11, 13 (cycle) and 16 (X2).

**Evidence:** `$S/logs/mut-p2swap.txt`

---

## Claim 20: "Mutants of the parent-link check, the unsearchable check, the listing-warning check, the start admission and phase-2 imports each fail; the readable check and the checkout read's failure arm back each other up (each alone survives)."

**Location:** commit cebfed35 message, paragraph 3
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these mutants as I constructed them (X2). It does not establish that a narrower mutant of the start admission (its parent-link half only) fails; it does not (Claim 22a).
**Legibility-target:** reviewer

Results from X2:

| Mutant | Exit | Failing tests |
|---|---|---|
| `parentlink` | 1 | 12, 15, 18 |
| `unsearchable` | 1 | 18 |
| `listwarn` | 1 | 18 |
| `startadmit` | 1 | 9 |
| `p2imports` | 1 | 3, 6, 13 |
| `readable` | 0 | survives |
| `readarm` | 0 | survives |
| `readable+readarm` | 1 | 9 |

**Evidence:** `$S/logs/mut-*.txt`

---

## Claim 21: "build-loop-check.bats 18; 116 across the five suites" and "140 changed code lines against U2a3 (434 against main)"

**Location:** commit cebfed35 message, paragraph 3
**Type:** Configuration
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test counts and both line counts. The counts are verified. The verdict carries only the "434 against main" part, which was true when the message was written and is now out of date.
**Legibility-target:** reviewer

The test counts hold: `grep -c '^@test'` gives 18 for `build-loop-check.bats`, and X1 shows `1..116`, all ok.

`git diff --numstat 5e51b58b..HEAD -- ':(top)' ':(top,exclude)docs/'` gives 43+26 (lib) and 44+27 (bats), 140 in total. Against `62d366a7` (main before the U2a3 merge) it gives 134+9, 285+2 and 2+2, which is 434.

cebfed35 was committed at 21:52:22 local, 49 s before the U2a3 merge 97aa2d35 (21:53:11). Against today's main (f6fdda68, which contains 97aa2d35), the same numstat gives 140, so "434 against main" is now stale. It matches the logged tally-error pattern class in name only: these figures were correct when written.

**Evidence:** command output recorded in this session (numstat lines quoted above); `$S/logs/x1-five.txt`

---

## Claim 22a: "a new test pins C1 (including a .claude/rules link the checkout replaces with a directory)"

**Location:** commit cebfed35 message, paragraph 3; `test/scripts/build-loop-check.bats:316-322`
**Type:** Behavioral (test claim)
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether test 18's C1 cases fail when the start admission's main-link and gitlink check alone is removed. It does not establish a defect in the shipped code: the real code refuses the shape (p4 `walk: failed`). This is a test-coverage misstatement, not a code-contract fail-open.
**Legibility-target:** maintainer

Both C1 fixtures copy a file that itself imports something under the linked directory:

- `cp deep/CLAUDE.md ld/` puts `evil @secret.md` into `ld/CLAUDE.md`.
- `cp docs/foo.md .claude/rules/` puts `see @bar.md` into `.claude/rules/foo.md`.

The walked checkout start therefore imports `ld/secret.md` or `.claude/rules/bar.md`, and the import's own `main_checkout` (`:628`) hits the main link. That refuses the walk whether or not the start was admitted. The `startnoparent` mutant (X3) skips the parent-link check for starts only, and it survives all 18 tests.

p4 builds the original C1 shape with a start that imports nothing: main stores `.claude/rules -> ../docs`, and the checkout's plain `.claude/rules/foo.md` reads `harmless`. The real code gives `walk: failed docs/bar.md: imported`. The mutant gives `walk: ok docs/bar.md: -` (`$S/logs/p4.txt`). So the C1 start-admission guard is exercised by test 18 but not pinned. The `startadmit` mutant fails only test 9, through its symlink and unreadable starts, not through the parent check.

**Evidence:** `test/scripts/build-loop-check.bats:316-322`; `scripts/lib/dev-cycle-read.sh:589`, `:628`; `$S/logs/mut-startnoparent.txt`, `$S/logs/p4.txt`

---

## Claim 22b: "... and C3 (an r-- directory, and a 000 directory only git's listing meets)"

**Location:** commit cebfed35 message, paragraph 3; `test/scripts/build-loop-check.bats:324-327`
**Type:** Behavioral (test claim)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each C3 half is pinned by test 18 alone. It does not cover a `--x` directory: the walk fails on it through the listing (p2), but no test has one.
**Legibility-target:** maintainer

`unsearchable` fails only test 18, and `listwarn` fails only test 18 (X2). The 000 `hid/` holds an untracked start that `main_checkout` never sees, because no listing names it. That matches "only git's listing meets".

**Evidence:** `test/scripts/build-loop-check.bats:324-327`; `$S/logs/mut-unsearchable.txt`, `$S/logs/mut-listwarn.txt`

---

## Claim 23: Test 3 name: "phase 2 walks an untracked, ignored or index-only start and a checkout file at a path main lacks"

**Location:** `test/scripts/build-loop-check.bats:46`
**Type:** Behavioral (test claim)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four cases in the body (`:57-60`). It does not cover a deleted index-only start (skipped; probed in p5 only).
**Legibility-target:** maintainer

The body writes `docs/new.md` (a checkout file at a path main lacks), an untracked `CLAUDE.local.md`, then a `.gitignore` naming it, then `git add -f`. Each expects `walk ok`. `p2imports` and `p2swap` fail it (X2).

**Evidence:** `test/scripts/build-loop-check.bats:46-63`; X2

---

## Claim 24: Test 6 name and comment: "the checkout's files"; "Untracked .claude/rules starts, top level and nested; a local instruction file importing an untracked note, which imports a tracked file; a checkout edit of a tracked import does not count."

**Location:** `test/scripts/build-loop-check.bats:109`, `:124`
**Type:** Behavioral (test claim)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shapes named. It does not establish what each shape pins individually.
**Legibility-target:** maintainer

`docs/local-notes.md` imports `@t.md` (`docs/t.md`, not tracked), so "which imports a tracked file" is loose. `docs/t.md` is expected imported because the token is recorded, not because a tracked file is read. A tracked file is reached only through the .claude/rules starts (`../../docs/u.md` resolves to `docs/u.md`, also untracked). This is an aside that does not change the verdict: the test's assertions hold, and `p2swap` and `p2imports` fail it.

**Evidence:** `test/scripts/build-loop-check.bats:124-129`; X2

---

## Claim 25: Test 9 name and comment: "on an untracked start that is a symlink or unreadable"; "the checkout's docs-link fails the plain-directory check too; tests 12 and 15 pin each alone."

**Location:** `test/scripts/build-loop-check.bats:167`, `:173`
**Type:** Behavioral (test claim)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the name and the cross-reference. It does not establish which step of test 9 the `plainarm` mutant trips; it also fails test 9, through the target-symlink and start-symlink steps.
**Legibility-target:** maintainer

Results:

- `parentlink` survives test 9 (the checkout's `docs-link` still fails the final arm, `:534`) and fails tests 12 and 15. Test 15 has the checkout lacking `ld`, so it pins the parent-link check alone.
- `plainarm` (X4) fails test 12, whose `lnk` exists only in the checkout, so test 12 pins the plain-directory arm alone.
- `startadmit` and `readable+readarm` fail test 9, which pins the symlink and unreadable starts.

**Evidence:** `test/scripts/build-loop-check.bats:167-193`, `:231-249`, `:273-296`; `$S/logs/mut-parentlink.txt`, `$S/logs/mut-plainarm.txt`

---

## Claim 26: Test 10 comment: "git rm -qf docs/CLAUDE.md  # no index-only start masks the tree-listing refusal" (and the commit's "test 10's masked tree-listing refusal")

**Location:** `test/scripts/build-loop-check.bats:199`; commit cebfed35 message, paragraph 3
**Type:** Behavioral (test claim)
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether an index-only start can mask the `ls-tree` refusal under this commit's code. It does not establish anything about U2a3, where an index-only start failed the walk and the masking was real.
**Legibility-target:** maintainer

Under U2a3c, an index-only start is walked, not refused (`:591`, Claim 17a), so it cannot make the walk fail for some other reason. With the `git rm` removed, test 10 still passes unmutated, and the `treelist` mutant still fails it (`want: walk: failed` / `walk: ok`, `$S/logs/t10-normm-treelist.txt`). The `git rm` is inert. The comment describes U2a3's hazard, which this commit removed.

**Evidence:** `test/scripts/build-loop-check.bats:199`; `$S/logs/t10-normm-none.txt`, `$S/logs/t10-normm-treelist.txt`

---

## Claim 27: Test 10 name and comment: "when main's tree or the checkout's .md list cannot be listed"; "A corrupt index: git ls-files --cached --others fails."

**Location:** `test/scripts/build-loop-check.bats:195`, `:201`
**Type:** Behavioral (test claim)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the corrupt-index and wrapper-git steps. It does not establish which of the two `checkout_md` failure arms (exit status or stderr) the corrupt index trips. Git prints an error and exits nonzero, so both apply.
**Legibility-target:** maintainer

X1 passes these steps, and the `treelist` mutant fails test 10 (X2).

**Evidence:** `test/scripts/build-loop-check.bats:195-216`; X1, X2

---

## Claim 28: Tests 11 and 13 names: "an upper-case .MD instruction file starts it, tracked or untracked; an upper-case token matches any case"; "a cycle through an untracked file"

**Location:** `test/scripts/build-loop-check.bats:221`, `:251`
**Type:** Behavioral (test claim)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertions as written. "Matches any case" is established for the recorded token (`docs/mixed.md` against `@Docs/Mixed.md`), not for a file read under another case.
**Legibility-target:** maintainer

X1 passes both, and `p2swap` fails both (X2).

**Evidence:** `test/scripts/build-loop-check.bats:221-261`; X1, X2

---

## Claim 29: Test 14 comment: "first, with no .md on main or in the checkout: an empty start list is no failure"; test 16 name: "a checkout change is not seen until IMPORTED_MAIN_DONE is cleared"; test 18 name and comments ("still failed, as main alone"; "only git's listing meets")

**Location:** `test/scripts/build-loop-check.bats:263-264`, `:298`, `:316-327`
**Type:** Behavioral (test claim)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion. It does not cover C1 pinning, which is in Claim 22a.
**Legibility-target:** maintainer

Test 14's fixture starts from an empty initial commit, so `cand` is empty, and `:584 [[ ${#cand[@]} -eq 0 ]] || mapfile ...` guards the length check (without the guard, `printf '%s\0'` with no arguments would yield one element). Test 16: see Claim 9. Test 18: main alone (the first `imps`) fails, as the comment says, and the listing case is Claim 22b. All pass in X1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:584-585`; X1

---

## Claim 30: Pre-existing comments "no index-only start masks the NUL count" / "the empty-text check" / "the refusals ..." (tests 5, 9, 12)

**Location:** `test/scripts/build-loop-check.bats:92`, `:191`, `:244`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** These lines are context, not this commit's hunks, but this commit's behaviour change made them stale. Lines 191 and 244 are executed. Line 92 is inferred from the same mechanism and was not executed.
**Legibility-target:** maintainer

In U2a3 an index-only start failed the walk, so these `git rm` lines kept that failure from masking the check under test. U2a3c walks index-only starts (`:591`), so no masking is possible. With the `git rm` lines removed (X5), tests 9 and 12 pass unmutated. A NUL-count mutant still fails test 9, and an empty-text mutant still fails test 12 (`$S/logs/t9t12-norm-*.txt`). The `git rm` lines are now inert, and the comments name a hazard that no longer exists. They are a sibling of Claim 26.

**Evidence:** `test/scripts/build-loop-check.bats:92`, `:191`, `:244`; `$S/logs/t9t12-norm-none.txt`, `$S/logs/t9t12-norm-nul.txt`, `$S/logs/t9t12-norm-empty.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`docs/working/plan-build-loop-handoff.md:277`): the U2a3c bullet says every phase-2 item is admitted "before it is marked seen". For imports, `seen[$p]=1` (`:626`) precedes `main_checkout` (`:628`). It is equivalent in effect: reword to "before it is queued".
- **Claim 17b** (commit cebfed35, paragraph 2): the same ordering claim, which holds for starts only. This is documentation-level, not a fail-open.
- **Claim 22a** (commit cebfed35, paragraph 3; `test/scripts/build-loop-check.bats:316-322`): "a new test pins C1" is not true. A mutant that drops the main-link check for starts only survives all 18 tests, because both C1 fixtures' starts import a path under the link, which the import's admission refuses anyway. A start that imports nothing (p4) is the shape that would pin it. The shipped code is correct.
- **Claim 26** (`test/scripts/build-loop-check.bats:199` and the commit's "test 10's masked tree-listing refusal"): under U2a3c no index-only start can mask the `ls-tree` refusal. Without the `git rm`, the `treelist` mutant still fails test 10.

Claims 4 and 17b are one mismatch stated in two places. The four Incorrect verdicts are three distinct mismatches.

### Stale
- **Claim 21** (commit cebfed35): "434 against main" was true against main 62d366a7 at commit time. Main now contains U2a3 (97aa2d35), against which the figure is 140.
- **Claim 30** (`test/scripts/build-loop-check.bats:92`, `:191`, `:244`): "no index-only start masks ..." comments and their `git rm` lines are inert now that index-only starts are walked.

### Mostly Accurate
- **Claim 6** (`scripts/lib/dev-cycle-read.sh:29-35`): "...never the working tree ..., and so does main_imports" contradicts the parenthetical. Say that main_imports reads main's commit and then the checkout's start and imported files main lacks.
- **Claim 10b** (`scripts/lib/dev-cycle-read.sh:523`): `checkout_md` fails on any git stderr (for example `GIT_TRACE=1`) and on a nonzero exit, not only on warnings. This fails closed.
- **Claim 11** (`scripts/lib/dev-cycle-read.sh:525-528`): "parent" means every ancestor. "Absent" includes a path below a checkout non-directory, or below a checkout directory link whose target lacks it.

### Unverifiable
- None.

## Goal-Alignment Note

**Success criterion (verbatim):** "a markdown report saved at the output path given in your tail section, structured per your skill, with every finding carrying Location, verbatim Evidence, Severity/verdict, Confidence and Legibility-target."

**Answered:**

- All nine claim groups in the brief are verdicted.
  - Group 1, `main_checkout`'s contract: every listed shape was probed (Claim 11).
  - Group 2, admission before `seen`: this holds for starts and is inverted, but equivalent, for imports (Claims 4 and 17).
  - Group 3, append-only: this holds. No probe or reading found checkout content that makes the walk end ok with fewer imports than main alone (Claim 16). In particular, `${ent[$f]-checkout}` cannot misroute, and the `tq` swap drops nothing.
  - Group 4, `checkout_md`: the redirection is right, 000 and `--x` directories fail, silent failures are caught, and any stderr fails closed (Claim 10).
  - Group 5, main's arms: confirmed. The checkout's edited copy is ignored (Claim 15).
  - Group 6, test names and comments: Claims 23-30.
  - Group 7, counts and mutants: all reproduced. One line count is stale (Claims 20 and 21).
  - Group 8, A5, F11 and the U2b bullet: Claims 1, 2, 3 and 5.
  - Group 9, the header: Claim 6.
- No behavioural (code-contract) Incorrect was found. The one coverage gap that matters for the security goal is Claim 22a: the C1 start-admission parent check is unpinned by any test, so a regression that reintroduced C1 would pass the suite.
- No parser-side (`import_targets`, `lower`) issue arose, so nothing is routed to U2a3b.

**Not answered:** behaviour under root (uid 0) and under a case-insensitive filesystem was not probed. Both are outside this commit's claims, and the second is an A5 gap.
