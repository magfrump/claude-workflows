Commit: 3a35c8b9
# Code Fact-Check Report

**Commit:** 3a35c8b9
**Repository:** /workspace/.claude/wt-build-loop-u2a3c (branch `feat/build-loop-u2a3c`)
**Scope:** `git diff main...HEAD` at 3a35c8b9 (scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/working/known-issues-dev-cycle.md row A5, docs/working/plan-build-loop-handoff.md F11/U2a3c/U2b, docs/reviews/override-log.md rows 439-456, the iteration-2 rubric's code claims) and the commit messages of main..HEAD (3e58eb9c..3a35c8b9). Replicate fc1 of 3 (final confirming pass, iteration 3).
**Checked:** 2026-10-07
**Total claims checked:** 44
**Summary:** 30 verified, 11 mostly accurate, 1 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 8 entries). Two entries are test-count claims in commit messages; every count on this branch was checked against `grep -c '^@test'` and by running the suites, and none matches that pattern (no fabricated count). No claim matches a logged fabricated-symbol pattern.

Execution environment: bash 5.2, mawk 1.3.4 20200120, git 2.39, bats; scratch `/tmp/u2a3c-i2-fc1-6NBv` (all captured output under `/tmp/u2a3c-i2-fc1-6NBv/logs/` and the files named per claim). The worktree was not modified; mutants and older libs were run from a copy of `test/` and `scripts/` in the scratch dir (`/tmp/u2a3c-i2-fc1-6NBv/rt`, driver `runt.sh`).

---

## Claim 1: "Tests after fixes (2fbd929b): build-loop-check 63/63, dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:24`
**Type:** Configuration / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four suites' counts and pass status at 3a35c8b9 under two TMPDIR lengths; does not establish pass status on hosts whose bats run directory is longer than this one's (see the threshold below).

The counts are right (`grep -c '^@test'`: 63, 78, 19; fixture-hermeticity 2). Running the suites with the TMPDIR template the shared brief prescribes, but a slightly longer tag (`/tmp/u2a3c-i2-fc1-bats-XXXX`, 27 chars), build-loop-check is **62/63** in two full runs: test 59 fails every time in the full file and passes when run alone (`-f`).

Cause (executed): the test fixes the walk budget at a constant,

```bash
# test/scripts/build-loop-check.bats:907
        IMPORT_WORK_MAX=1000; want="$(printf "%s\n" 1000 $((1000 - w)) $((1000 - 2 * w)) $((1000 - 3 * w)) | sort -n | tr "\n" " ")"
```

while `w` grows with ROOT_REAL's length, because `put` charges the resolved spelling:

```awk
# scripts/lib/dev-cycle-read.sh:581-584
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  # The resolved spelling is what costs (its length grows with the depth of
  # the importing file), so it is charged too, and each is resolved once per file.
  work += length(c); if (work > wmax) exit 3
```
(excerpt ends :584; enclosing `put` continues to :600 — read)

Measured `w` for the test's file: ROOT_REAL length 55 gives 4w = 992, length 56 gives 4w = 1008. Past 1000 the caps phase's walk fails and the `set -euo pipefail` script exits silently after "0 main ok", which is the observed failure output. The fixture root is `$TMPDIR/bats-run-XXXXXX/test/<N>/repo`, so test 59 fails once TMPDIR is 27+ characters (alone it is test 1, one character shorter). The default `/tmp` passes; a 97-character TMPDIR fails it alone too.

**Evidence:** `test/scripts/build-loop-check.bats:897-912`, `scripts/lib/dev-cycle-read.sh:580-600`; command `TMPDIR=$T LC_ALL=C timeout 900 bats test/scripts/build-loop-check.bats` (cwd worktree, exit 1, 2026-10-07T20:1x, twice): `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check-run2.log`; isolation by TMPDIR length (exit 0 at len 24, exit 1 at len 97, 2026-10-07T20:22:38Z): `/tmp/u2a3c-i2-fc1-6NBv/logs/caps-tmpdir-length.log`; w by root length (2026-10-07T20:22:47Z): `/tmp/u2a3c-i2-fc1-6NBv/logs/work-vs-rootlen.log`; other suites exit 0: `/tmp/u2a3c-i2-fc1-6NBv/logs/dev-cycle.log`, `.../build-loop-read.log`, `.../fixture-hermeticity.log`, `.../fixture-git-env.log`

---

## Claim 2: "D=1000: 0.62 s (main 0.50, 21b35ebf 10.67). Test with a 6 s timeout fails at 21b35ebf." / B3 "Link text over 4096 bytes fails before it is read" / B4 "T1 ... and T2 ... applied" / C8 "Pinned by T1 (`sd/nx.md 1`)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:34-37,48`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the D=1000 timings, the deep-token and link-text tests failing on 21b35ebf's lib, T1/T2's presence and the `sd/nx.md 1` row; does not establish that T2 alone kills a fail-open mutant of HEAD's bottom-up loop (it does not; see Escalations).

Timed `main_imports` on one `@a/…/x.md` token 1,000 deep: 21b35ebf 10,855 ms and 11,750 ms; 2fbd929b 669 ms and 670 ms; main 532 ms. With HEAD's tests and 21b35ebf's lib, "stays linear" and "longer than 4096 bytes" both fail; with HEAD's lib both pass. T1's table holds `sd/nx.md 1` (`test/scripts/build-loop-check.bats:871`). A mutant that breaks out of the top-down loop once an ancestor is absent (the HEAD analog of M13) fails T1 but passes T2.

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/deep.sh` (cwd scratch, exit 0, 2026-10-07T20:16:27Z): `/tmp/u2a3c-i2-fc1-6NBv/logs/deep.log`; `runt.sh` runs (2026-10-07T20:15:37Z, 20:21:15Z): `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants3.log`

---

## Claim 3: Override rows 439-441, 443, 444 (U2a3c iteration 1): mitigations "Comment, A5 and the U2b bullet now say the caller clears IMPORTED_MAIN_DONE"; "A FIFO ... is never listed by `git ls-files --others`"; "the snapshot assumption is now written in the block comment and A5"; "Both callers test the code explicitly"; "its only caller"

**Location:** `docs/reviews/override-log.md:439-441,443-444`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each row's cited mitigation text as it stands at HEAD, the FIFO listing and the two call sites; does not establish whether Claude Code loads a FIFO (the row says untraced).

The cache-clear text is in the lib (`# the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, never the checkout,` `scripts/lib/dev-cycle-read.sh:487`), in A5 ("so a caller clears `IMPORTED_MAIN_DONE` after any checkout change", `docs/working/known-issues-dev-cycle.md:18`) and in the U2b bullet ("`IMPORTED_MAIN_DONE` cleared (the cache key ignores the checkout)", `docs/working/plan-build-loop-handoff.md:279`). The cache test pins the stale answer (`- - z.sh`, `test/scripts/build-loop-check.bats:340-341`), passing. `git ls-files -z --others` in a repo holding a FIFO `f.md`, a link `l.md` and a file `r.md` listed only `l.md` and `r.md`. Snapshot: `# snapshot: a file swapped between its admission and its read is not seen.` (`scripts/lib/dev-cycle-read.sh:485`). Both callers capture the code: `main_checkout ent pok "$f" || c=$?` then `[[ $c -ne 1 ]] || return 1` (`:825-826`) and `main_checkout ent pok "$p" || c=$?` then `[[ $c -ne 1 ]] || { IMPORTED_MAIN=error; return 1; }` (`:870-871`); `git grep` finds no other call outside the test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:485-491,825-826,870-871`; `/tmp/u2a3c-i2-fc1-6NBv/logs/fifo-listing.log` (cwd mktemp repo, exit 0, 2026-10-07T20:22:47Z)

---

## Claim 4: Rows 448-451: N1 "the test fails at 3e58eb9c"; L2-C5 "a no-drain mutant fails the test"; L2-C6 "18 realpath calls in the test's walk, against 102 unmemoized and 74 at 3e58eb9c ... fixed a crash on an empty main tree"; P2 "N adversarial files cost one bound ... one bound still costs about 5 s"

**Location:** `docs/reviews/override-log.md:448-451`
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each fails-at, mutant and count claim against the commit it names; does not establish the 18 count at HEAD (it is 10 there: Claim 33).

N1 test with 3e58eb9c's lib: not ok. No-drain mutant (`| capped_read drain |` → `| capped_read |` in HEAD's lib): the 4 MiB test fails with `walk: failed`. Realpath shim over the test's scenario: 3e58eb9c 74, 80cc6224 18, 80cc6224 with its memo store removed 102. Empty-tree test: 27364085 fails with `line 699: mc_e: unbound variable`, 80cc6224 passes. One bound of the many-component shape: 46,301,220 charged in 3,444 ms (about 5 s at 50,000,000).

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/rpcount.log` (cwd scratch, exit 0, 2026-10-07T20:15-20:17Z); bound timing run inline (cwd worktree, exit 0, 2026-10-07T20:19Z; output quoted here: `n=3400 rc=0 trailer=46301220 ms=3444`)

---

## Claim 5: Row 452: "the rebase resolution 3e58eb9c dropped the cache-clear rule, the FIFO start and the snapshot assumption from known issue A5 and U2b's 'owes the walk three things' clause ... Iteration 2 restored"

**Location:** `docs/reviews/override-log.md:452`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers presence of the three items in A5 and the U2b clause at 2b1399ab, 3e58eb9c and HEAD; does not establish the restored wording is identical to 2b1399ab's.

Counts per revision (A5 row: `IMPORTED_MAIN_DONE`/`FIFO`/swap-or-snapshot; U2b bullet: "three things"): 2b1399ab 1/1/1(swapped)/1; 3e58eb9c 0/0/0/0; HEAD 1/1/1/1.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:279`; `git show <rev>:<file> | grep -c` (cwd worktree, exit 0, 2026-10-07T20:2xZ; counts quoted above, paraphrased — no captured file because the counts were printed inline and are reproduced in full here)

---

## Claim 6: Row 453: "main_imports records the parser's whole output before the seen test ... Test "a main import of an untracked start" pins it"

**Location:** `docs/reviews/override-log.md:453`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the record-before-seen order and that a test pins it; does not establish a test by the quoted name.

The order holds: `i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }; IMPORTED_MAIN+="$i"$'\n'` (`scripts/lib/dev-cycle-read.sh:866`) precedes the per-name loop with `[[ -z "${seen[$p]+set}" ]] || continue` (`:869`). No test is titled "a main import of an untracked start"; the pinning test is `@test "main walk reads an untracked start that a main file also imports once, through the checkout (U2a3c; override row 446)"` (`test/scripts/build-loop-check.bats:921`), whose `want docs/AGENTS.md imported` fails if the record moved after the seen test. Precise version: name that title.

**Evidence:** `scripts/lib/dev-cycle-read.sh:863-874`, `test/scripts/build-loop-check.bats:921-930`

---

## Claim 7: Row 454: "The symlink arm fails link text over 4096 bytes (`git cat-file -s`) before reading it; test added"

**Location:** `docs/reviews/override-log.md:454`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fix and its test; does not re-measure the cited "256 MiB link blob, 58 s and 2 GiB" (not re-run: 2 GiB of memory per run).

```bash
# scripts/lib/dev-cycle-read.sh:842-843
        # Link text past PATH_MAX (4096) names nothing; it fails before the two whole reads below.
        i="$(git cat-file -s "$MAIN_SHA:$f")" && [[ "$i" -le 4096 ]] || { IMPORTED_MAIN=error; return 1; }
```
(excerpt ends :843; enclosing `120000)` arm continues to :859 — read)

The test fails on 21b35ebf's lib and passes on HEAD's (Claim 2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:841-859`, `test/scripts/build-loop-check.bats:942-950`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`

---

## Claim 8: Row 455: "capped_read's drain (git inflates the whole blob, about 0.7 s per GiB) and the scan of @-less lines are uncharged, and a caller running both walks pays two bounds"

**Location:** `docs/reviews/override-log.md:455`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the drain rate on this host and which work is charged; does not establish the rate on other hosts.

`git cat-file blob <1 GiB zeros> | (head -c 4194305; cat)` took 788 ms (4 ms without the drain). Work is charged only in `emit`, `put` and `splice` (`work +=` at `scripts/lib/dev-cycle-read.sh:566,584,617`); `scan` (`:601-613`) adds nothing; `work=0` is a local of each walk (`:757`, `:802`).

**Evidence:** inline run (cwd mktemp repo, exit 0, 2026-10-07T20:18Z; output quoted: `1GiB drain ms=788`, `no-drain ms=4`); `scripts/lib/dev-cycle-read.sh:564-629`

---

## Claim 9: Row 456: "Each call site is one line"

**Location:** `docs/reviews/override-log.md:456`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three reader→parser→trailer→budget sites; does not assess whether they should be shared.

Each site is one logical command over two physical lines, e.g. `out="$(capped_read < "$f" | IMPORT_LEFT=… import_targets "$d")" \` / `&& import_work out work || { IMPORTED=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:775-776`; also `:837-838`, `:839-840`), and the budget add is a further line at each site (`:778`, `:864`). Precise version: "each call site is one statement".

**Evidence:** `scripts/lib/dev-cycle-read.sh:775-778,837-840,864`

---

## Claim 10: A5: "a checkout path it would walk that lies under a directory main stores as a link or gitlink or under an unsearchable directory, anything but a plain file or directory there (or nothing), an unreadable checkout file, a `..` after a checkout link in link text, and a checkout listing git prints any stderr for fail it; a linked worktree's `.git` file is read like any checkout file. ... (the lib's block comment above `IMPORTED=` holds the caller contract; the U2b bullet names what U2b owes it)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fail rule (tests and mutants), the .git rule and the pointer; does not establish anything about Claude Code's loading of the same shapes.

Every fail rule matches `main_checkout` (`scripts/lib/dev-cycle-read.sh:742,745,751-752`), the `..`-after-link check (`[[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1`, `:856`) and `checkout_md` (`[[ -z "$e" ]]`, `:716`); the suites exercising them pass. The pointer overstates: the lib's block comment holds the cache-clear and HOME rules (`:486-491`) but not the git-environment duty (`GIT_INDEX_FILE`, fsmonitor, …), which `grep` finds nowhere in the lib; it is only in the U2b bullet. Precise version: "the lib's block comment holds the cache rule; the U2b bullet holds all three duties".

**Evidence:** `scripts/lib/dev-cycle-read.sh:464-491,713-755,841-859`; `grep -n GIT_INDEX_FILE scripts/lib/dev-cycle-read.sh` (no hits)

---

## Claim 11: F11: "one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, or anything but a plain file or directory, and a checkout listing git prints any stderr for fails the walk; the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal list and the pointer; does not establish the omitted rule's test coverage beyond T1.

All listed refusals are in `main_checkout`; the list omits its unreadable-plain-file refusal, `if rawfile "$c"; then [[ -r "$c" ]]; return; fi` (`scripts/lib/dev-cycle-read.sh:751`), which the U2a3c bullet and A5 both list. The U2b pointer is right.

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755`, `docs/working/plan-build-loop-handoff.md:126,277,279`

---

## Claim 12: U2a3c bullet: "Built 2026-10-07 ...: the fail rules as stated (a readable plain file main lacks is walked; a non-plain node, an unreadable file, or a path under main's link or gitlink or under an unsearchable directory fails), `capped_read`, the work bound `IMPORT_WORK_MAX` (reported by the parser's trailer, charged by `import_work`), `main_checkout`'s ancestor memo, the `.git` rule, and N1 (`lower_all` under `nul_list`)"

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named item's presence and its test; does not establish the bullet's carried-from-U2a3b requirements text (history).

Each item exists (`capped_read` `:709`, `IMPORT_WORK_MAX` `:511`, trailer `END { if (trail) print "/" (work + 0) }` `:629`, `import_work` `:677-682`, `pok` `:804`, `lower_all` `:700` used as `nul_list low lower_all "${cand[@]}"` `:820`) and its tests pass; the fail-rule mutants in Claims 2 and 4 fail their tests.

**Evidence:** `scripts/lib/dev-cycle-read.sh:677-755,801-876`; logs as Claims 2, 4

---

## Claim 13: U2b bullet: "A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the contract another caller needs; does not establish any current caller other than main_imports (there is none).

The stated duties are needed but not sufficient: such a caller must also never pass a PATH that ENT holds, because the PATH arm memoizes `d` without testing PATH's own main mode (Claim 23), and a later call through it then skips that mode. main_imports meets this by calling only when `ent` lacks the path (`[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"`, `scripts/lib/dev-cycle-read.sh:870`; `t:` candidates only when `ent` lacks them, `:819`). Precise version: add "and only for a path ENT does not hold".

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755,819,870`; `/tmp/u2a3c-i2-fc1-6NBv/logs/memo-path-in-ent.log`

---

## Claim 14: Block comment: "Once main's walk is done, a second phase walks the checkout's start files main lacks (untracked, ignored or only in the index) and the imported files main lacks, when each is a plain file there, and only appends. ... a checkout path it would walk (a start or an import main lacks) that lies under a directory main stores as a symlink or gitlink or under an unsearchable directory, or that the checkout holds as anything but a readable plain file, a plain directory or nothing (the root included), or a checkout listing git prints any stderr for, fail the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:464-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the phase ordering, append-only reads and each fail rule through the passing tests and mutants; does not give "(the root included)" a code path (the parser never yields the root: `if (index(out, pre) != 1 || length(out) <= length(pre)) return`, `:594`), so that parenthesis is inert rather than wrong.

Phase 2 starts only when `queue` empties: `[[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }  # phase 2: main's walk is done` (`:833`); checkout reads only add to `IMPORTED_MAIN` (`:866`). The index-only case is covered (`md_ls --cached --others`, `:716`; test line 89, "an index-only start deleted from the checkout loads nothing").

**Evidence:** `scripts/lib/dev-cycle-read.sh:713-755,801-876`; `test/scripts/build-loop-check.bats:77-91,782-799`; `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check.log`

---

## Claim 15: "the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, never the checkout, whose files it read, so a caller whose checkout may have changed (a file added or edited) sets IMPORTED_MAIN_DONE="" to walk again"

**Location:** `scripts/lib/dev-cycle-read.sh:486-491`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key and the clear; does not establish any caller clearing it (none exists yet).

`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` (`:806`). The cache test's last three answers are `- - z.sh`: stale after `CLAUDE.local.md` gains `@z.sh`, fresh after the clear; it passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:806-807`, `test/scripts/build-loop-check.bats:330-341`, `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check.log`

---

## Claim 16a: "Each walk also fails once the parser's work (the candidate and comment-splice characters it scans, the unit of its per-file bound of 50,000,000, about 5 s) passes this in all"

**Location:** `scripts/lib/dev-cycle-read.sh:504-506`
**Type:** Configuration / Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the work counter charges; does not establish the time for shapes other than the many-component one.

The unit omits the largest term: `put` also charges each candidate's resolved spelling, which includes ROOT_REAL (`work += length(c)` after `c = root "/" dir "/" c`, `:581-584`). So the same file costs more work under a longer root: for `see @a.md`, w = 228 at a 50-character root and 252 at 56 (Claim 1). Precise version: "the candidate and comment-splice characters it scans and the resolved spelling of each candidate". "About 5 s" holds for the adversarial many-component shape (Claim 4) but not in general: 49,063,020 units of one long name took 62 ms.

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-629`; `/tmp/u2a3c-i2-fc1-6NBv/logs/work-vs-rootlen.log`; inline timing (cwd worktree, exit 0, 2026-10-07T20:19Z; quoted: `n=7000 rc=0 trailer=49063020 ms=62`)

---

## Claim 16b: "/workspace's walks spend about 8,100 each (2026-10-07)"

**Location:** `scripts/lib/dev-cycle-read.sh:508`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace at main e5d0f838 today; does not establish the figure for other roots (it scales with the root's length: Claim 16a).

`import_work` wrapped to sum charges: tree walk ok, work 8,110, 1,099 ms, 128 names; main walk ok, work 8,110, 1,352 ms.

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/wswork.sh` (cwd /workspace, exit 0, 2026-10-07T20:17:29Z): `/tmp/u2a3c-i2-fc1-6NBv/logs/wswork.log`

---

## Claim 16c: "reading, draining and the scan of @-less lines are not charged ... The bound is per walk: a caller that runs both walks pays up to two."

**Location:** `scripts/lib/dev-cycle-read.sh:507-510`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which work is charged and the per-walk counter; does not establish any caller's combined cost.

`local - f d p lp out used=0 work=0 …` (`:757`) and `local - rec f d p i c lk out used=0 work=0 …` (`:802`) give each walk its own counter; charging sites as in Claim 8.

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-629,757,802`

---

## Claim 17: "IMPORT_WORK_LEFT (set by a walk: what its IMPORT_WORK_MAX has left, which then also caps the per-file work bound, and a last line "/N" reports the work spent; import_work reads it. Unset or empty: no trailer and only the per-file bound; not a number: 0, so the first candidate fails it)"

**Location:** `scripts/lib/dev-cycle-read.sh:524-528`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unset, empty, non-numeric, partly numeric, 0 and large values; does not establish behaviour for values the walks never pass (they always pass a non-negative integer).

Unset and empty: output `a|ab|ab.|ab.m|ab.md`, no trailer, rc 0. `abc` and `0`: rc 1 at the first candidate. But a value with leading digits is read as those digits, not 0: `12abc` gives wmax 12 and fails at work 17 (`ENVIRON["IT_WORK"] + 0`, `:626`). Precise version: "not a number: its leading number, or 0". On a failing exit awk's END still prints the trailer (`/1`), harmless since the caller fails on the status.

**Evidence:** `scripts/lib/dev-cycle-read.sh:623-629,670-671`; `/tmp/u2a3c-i2-fc1-6NBv/logs/work-left-values.log` (cwd worktree, exit 0, 2026-10-07T20:22:47Z)

---

## Claim 18: "import_work OUT TOTAL: strips the parser's work trailer (its last line, "/N", printed when IMPORT_WORK_LEFT is set; a repo-relative name never starts with /) from the variable OUT, and adds N to the variable TOTAL. It returns 1 when the trailer is missing or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:673-682`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the strip, the add and both failures; does not establish that a printed name can never start with / beyond `put`'s `out = substr(out, length(pre) + 1)` (`:595`), which removes the root and its slash.

```bash
# scripts/lib/dev-cycle-read.sh:677-682
import_work() {
  local -n iw_o="$1" iw_t="$2"; local iw_w="${iw_o##*/}"
  [[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1
  iw_o="${iw_o%/*}"; iw_o="${iw_o%$'\n'}"
  (( (iw_t += iw_w) <= IMPORT_WORK_MAX ))
}
```

The test at line 842 (cases `a.md\n/12`, `/7`, `docs/12`, `b/12x`, spent budget, `/0`) passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:677-682`, `test/scripts/build-loop-check.bats:842-851`, `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check.log`

---

## Claim 19: "lower_all ...: a tr that dies after a partial flush then fails the list rather than truncating its last name and dropping a start (U2a3b final N1)"

**Location:** `scripts/lib/dev-cycle-read.sh:696-700`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failing tr shim; does not establish a tr that exits 0 after truncating (nothing detects that, as for any tool).

`lower_all() { local -; set -o pipefail; printf '%s\0' "$@" | tr … ; }` under `nul_list low lower_all "${cand[@]}" || return 1` (`:820`). The shim test passes at HEAD and fails with 3e58eb9c's lib.

**Evidence:** `scripts/lib/dev-cycle-read.sh:695,700,820-821`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`

---

## Claim 20: capped_read: "With the word drain (after git cat-file) it reads the rest, so the writer never dies of SIGPIPE ...; an argument, not a [[ -p /dev/stdin ]] test, which needs /proc. The drain is time the work bound does not charge"

**Location:** `scripts/lib/dev-cycle-read.sh:701-709`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers drain placement, the no-drain failure and the uncharged drain; the /proc dependency is established only as far as `/dev/stdin -> /proc/self/fd/0` on this host (a /proc-less run was blocked: `unshare` not permitted).

`capped_read() { head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null; }` (`:709`). `drain` appears only at the blob arm (`git cat-file blob "$MAIN_SHA:$f" | capped_read drain |`, `:839`); the checkout arm and the tree walk read `capped_read < "$f"` (`:837`, `:775`). The no-drain mutant fails the 4 MiB test (Claim 4). `ls -l /dev/stdin` shows `/dev/stdin -> /proc/self/fd/0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:701-709,775,837-840`; `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`

---

## Claim 21: checkout_md: "fails when git exits nonzero or prints anything on stderr, since an unreadable directory goes unlisted with only a warning"

**Location:** `scripts/lib/dev-cycle-read.sh:713-716`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stderr capture and the corrupt-index and `chmod 000` cases; does not establish every warning git can print.

`checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }`. The `hid` case (`chmod 000`, walk failed, `test/scripts/build-loop-check.bats:794`) and the corrupt-index case (`:242-244`) pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:716,818`, `test/scripts/build-loop-check.bats:227-251,782-799`

---

## Claim 22: main_checkout (2fbd929b): "Bottom up to the nearest decided ancestor, then top down from it" preserves the top-down version's answers

**Location:** `scripts/lib/dev-cycle-read.sh:737-748`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every return code of 21b35ebf's top-down main_checkout against HEAD's, for random checkout shapes (absent, file, searchable and unsearchable directories, links to a file or directory, FIFOs) to depth 3, random ENT modes (none, 100644, 120000, 160000) and random call orders of 8 paths to depth 4 sharing one MEMO, for paths ENT does not hold (main_imports' only use); does not cover paths ENT holds (Claim 23) or unreadable files (identical code on both sides).

1,200 trees, 8,387 calls (rc 0: 245, 1: 3,554, 2: 4,588): zero mismatches, including the asked order (a shorter prefix memoized 2, then a longer path whose deeper ancestor main stores as a link: the memo hit stops the upward scan at the 2 ancestor and the link ancestor below it still meets `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1`, `:742`, which runs whatever `st` is).

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/diff.sh`, `/tmp/u2a3c-i2-fc1-6NBv/diff2.sh` (cwd scratch, exit 0, 2026-10-07T20:10:29Z): `/tmp/u2a3c-i2-fc1-6NBv/diff.out`, `/tmp/u2a3c-i2-fc1-6NBv/diff2.out`; `scripts/lib/dev-cycle-read.sh:732-755`

---

## Claim 23: MEMO "d for a plain searchable directory, 2 for one absent or a plain file (nothing below it loads), set only once its own and every higher ancestor's main mode passed. A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT."

**Location:** `scripts/lib/dev-cycle-read.sh:720-723`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the PATH arm's memo write; the invariant does hold for every ancestor entry (`:742` before `:747`) and for main_imports, which never passes a path ENT holds (`:819`, `:870`); does not establish any live fail-open (there is no other caller today).

The PATH arm writes `d` without testing PATH's own main mode:

```bash
# scripts/lib/dev-cycle-read.sh:749-754
  [[ "$st" == d ]] || return 2
  c="$3"; [[ -e "$c" || -L "$c" ]] || return 2
  if rawfile "$c"; then [[ -r "$c" ]]; return; fi
  plaindir "$c" || return 1
  [[ ! -x "$c" ]] || mc_m[$c]=d  # a prefix candidate's directory, which longer ones pass through
  return 2
```
(excerpt ends :754; enclosing `main_checkout` ends :755 — read)

Executed: ENT `[a]=120000`, checkout `a/b/c.md` a plain file. `main_checkout ENT M a` returns 2 and memoizes `[a]=d`; then `main_checkout ENT M a/b/c.md` hits that entry, never tests `a`'s mode, and returns **0** (walk it), where 21b35ebf's version returns 1. A caller following the U2b contract (fresh MEMO and ENT) but passing a main-stored path would admit a file under a link main stores. Precise version: "set only once every higher ancestor's main mode passed, and for an ancestor its own; PATH itself is memoized without its own mode, so callers pass only paths ENT lacks".

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755,819,870`; `/tmp/u2a3c-i2-fc1-6NBv/e1.sh` (cwd `/tmp/u2a3c-i2-fc1-6NBv/e1/x`, exit 0, 2026-10-07T20:22:38Z): `/tmp/u2a3c-i2-fc1-6NBv/logs/memo-path-in-ent.log` (shows `old(a/b/c.md)=1`, `new(a/b/c.md)=0`, `mn=([a]="d" [a/b]="d")`)

---

## Claim 24: "0 for a readable plain checkout file to walk, 2 when nothing there loads (absent, below an absent ancestor or a plain file, or a plain directory), 1 to fail the walk: an ancestor main stores as a link or gitlink, an ancestor that is anything else but a plain searchable directory, an unreadable plain file, ENT or MEMO not an associative array, or anything else at PATH"

**Location:** `scripts/lib/dev-cycle-read.sh:724-728`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed code through T1's 17-row table, the indexed-array rows and three mutants; does not establish the answer for a PATH ENT holds (Claim 23).

T1 passes; mutants that drop the mode check (`:742`), drop `-r` (`:751`) or break out of the loop below an absent ancestor each fail it.

**Evidence:** `test/scripts/build-loop-check.bats:853-882`; `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants3.log`

---

## Claim 25: Iteration-1 fixes A1-A3 and C1 survive the rebase and the new commits

**Location:** `scripts/lib/dev-cycle-read.sh:736,750,825-827,870-872`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the associative-array check (A1), the start's own parent check (A2), admission before seen (A3) and the no-fork fast return (C1); does not re-derive iteration 1's findings.

A1: `set +u; [[ "${mc_e@a}" == *A* && "${mc_m@a}" == *A* ]] || return 1` (`:736`; T1's `ent-indexed 1`, `memo-indexed 1`). A2: start candidates go through `main_checkout ent pok "$f"` (`:825`); the mode-check mutant fails the `.claude/rules` link case (`test/scripts/build-loop-check.bats:788-789`). A3: `main_checkout` (`:870`) precedes `seen[$p]=1` (`:872`), and at starts `:825` precedes `seen[$f]=1` (`:827`). C1: `c="$3"; [[ -e "$c" || -L "$c" ]] || return 2` (`:750`) before `rawfile` forks; ancestors likewise `[[ ! -e "$c" && ! -L "$c" ]] || rawfile "$c"` (`:744`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755,822-829,867-874`; `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`

---

## Claim 26: main_imports header: "main_checkout refuses a start or an import main lacks, a blob or checkout file cannot be read ... or the IMPORT_OUT_MAX or IMPORT_WORK_MAX budget is spent ... Phase 2 begins when queue empties: tq's checkout files then join it, and a path main lacks reads the checkout."

**Location:** `scripts/lib/dev-cycle-read.sh:787-800`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed failure's return site; does not establish the order of reads within phase 2 (main-stored imports found in phase 2 still go to `queue` and are read through main's arms, `:873`).

Return sites: `:825-826`, `:837-840`, `:843`, `:846-849`, `:854`, `:859`, `:864`; the checkout arm is `case "${ent[$f]-checkout}" in checkout) …` (`:836-838`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:801-876`

---

## Claim 27: "Link text past PATH_MAX (4096) names nothing; it fails before the two whole reads below."

**Location:** `scripts/lib/dev-cycle-read.sh:842`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size gate's position and the 4097-byte test; does not establish behaviour at exactly 4096 bytes (allowed by `-le`, and also unresolvable since PATH_MAX counts the NUL; failing it there would be stricter, not looser).

As quoted in Claim 7; the gate (`:843`) precedes both `git cat-file blob` reads (`:846-847`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:841-859`, `test/scripts/build-loop-check.bats:942-950`

---

## Claim 28: "A linked worktree's .git file and files under .git are checkout files like any other" and the three inverted U2a3b tests

**Location:** `scripts/lib/dev-cycle-read.sh:476-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the removed special case and the three tests (lines 411, 657, 700); does not establish that Claude Code reads a gitfile this way (iteration 2's C9: unverifiable here).

main's `if [[ "$p" == .git ]]; then …` block is gone from HEAD's main_imports; `.git` now reaches `main_checkout` like any path main lacks. The gitfile test (`:411`), the under-.git test (`:657`) and the nested .git file test (`:700`) now expect `walk ok` and pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:867-874`; `git show main:scripts/lib/dev-cycle-read.sh` (main_imports lines 65-78 of the function); `test/scripts/build-loop-check.bats:411-425,657-664,700-714`

---

## Claim 29: "Unmemoized, each candidate re-checks every ancestor (102 calls; 74 at 3e58eb9c); memoized, each directory once, plus each candidate's own check (18)."

**Location:** `test/scripts/build-loop-check.bats:822-825`
**Type:** Performance
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at HEAD; the 102 and 74 are right for the commits named; does not affect the test's `-le 30` bound, which still passes.

At 80cc6224 the count was 18; at HEAD (2fbd929b's lib) it is **10**, because 2fbd929b also memoizes a searchable PATH directory (`:753`), so a candidate's own check is no longer repeated by longer ones. Precise version: "(10 at 2fbd929b; 18 at 80cc6224)".

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/rpcount.sh` (cwd scratch, exit 0, 2026-10-07T20:15Z): `/tmp/u2a3c-i2-fc1-6NBv/logs/rpcount.log`

---

## Claim 30: Test title "… and memoizes only plain searchable directories (U2a3c)"

**Location:** `test/scripts/build-loop-check.bats:853`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the test asserts about MEMO; does not establish the 2 entries' contents.

MEMO also holds `2` entries (every decided ancestor, `mc_m[$c]="$st"`, `scripts/lib/dev-cycle-read.sh:747`); the test filters to `d` values: `for k in "${!M[@]}"; do [[ "${M[$k]}" != d ]] || echo "$k"; done` (`test/scripts/build-loop-check.bats:860`). Precise version: "memoizes as d only plain searchable directories".

**Evidence:** `scripts/lib/dev-cycle-read.sh:747,753`, `test/scripts/build-loop-check.bats:853-882`

---

## Claim 31: Test "each walk caps every file's parser at what IMPORT_WORK_MAX has left, in every arm, and charges every arm"; "Four top-level files alike but for one letter cost w each: two on main, two only in the checkout, so each main_imports arm runs twice"

**Location:** `test/scripts/build-loop-check.bats:897-912`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test checks (the -1/0 boundary relative to 4w, and the four caps) and that a per-file mutant fails it; does not establish robustness to the fixture root's length, which it lacks (Claim 1).

Two files on main (`AGENTS.md`, `GEMINI.md`, blob arm) and two in the checkout (`CLAUDE.md`, `CLAUDE.local.md`, checkout arm); the shim logs `IT_WORK`. A mutant with no walk-wide check (import_work's comparison and awk's cap both removed) fails it.

**Evidence:** `test/scripts/build-loop-check.bats:897-912`; `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`

---

## Claim 32: "@a/a/.../x.md, 1,000 levels deep, none in the checkout: about 0.6 s; 21b35ebf's top-down loop rescanned every absent ancestor per prefix candidate (10.7 s)" (under `timeout 6`)

**Location:** `test/scripts/build-loop-check.bats:932-940`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timings and the test's discrimination on this host; does not establish behaviour on a host about 9x slower, where 0.67 s would pass 6 s (the test does not separate a timeout from a failure).

669 ms at HEAD, 10,855 ms at 21b35ebf (Claim 2); the test fails on 21b35ebf's lib. The test's work and print use are far under both bounds at any plausible root length.

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/deep.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`

---

## Claim 33: Test title "main walk fails on link text main stores longer than 4096 bytes before reading it whole"

**Location:** `test/scripts/build-loop-check.bats:942`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test observes; does not establish the "before reading it whole" ordering, which no assertion observes.

The test checks only `walk: failed` for 4,097 bytes and `walk: ok` for `r.md` (`:949`). It discriminates the cap (21b35ebf's lib, which reads the text, walks ok and fails the test), but a mutant that read the blob whole first and then failed on its size would pass. Precise version: "fails on link text … longer than 4096 bytes".

**Evidence:** `test/scripts/build-loop-check.bats:942-950`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`

---

## Claim 34: Test "main walk fails on a path under a link main stores below a directory the checkout lacks, and walks a path under a plain file (U2a3c)"

**Location:** `test/scripts/build-loop-check.bats:884-895`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers its two halves and the mode-check mutant; does not establish that it alone pins the HEAD analog of M13 (a break below an absent ancestor survives it, because the walk's shorter prefixes memoize `a` and `a/b` first, so the link ancestor is the first undecided one; T1 kills that mutant).

Passes at HEAD; the no-mode-check mutant fails it.

**Evidence:** `test/scripts/build-loop-check.bats:884-895`; `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants3.log`

---

## Claim 35: Test "main walk reads an untracked start that a main file also imports once, through the checkout (U2a3c; override row 446)"

**Location:** `test/scripts/build-loop-check.bats:921-930`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record and the start's checkout read, and the symlink refusal at the start; does not establish "once" by a read count.

Passes; `docs/x.md imported` is reachable only by reading the checkout's `docs/AGENTS.md` (main stores no such file).

**Evidence:** `test/scripts/build-loop-check.bats:921-930`, `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check.log`

---

## Claim 36: Commit 3e58eb9c: "Tests: build-loop-check 51/51, build-loop-read 19/19, dev-cycle 78/78, fixture-git-env 2/2"; "Three U2a3b tests that pinned the interim fail-closed rule for .git paths now expect the walk to read them"; "its pok memo, which returns in the memo commit that follows"

**Location:** `git log 3e58eb9c` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts (51 run at 3e58eb9c), the three tests and the memo's return in 80cc6224; does not re-run 3e58eb9c's dev-cycle or build-loop-read suites (counts only).

build-loop-check at 3e58eb9c (git archive copy): 51 ok, exit 0. `@test` counts 19 and 78; fixture-git-env 2 ok. 3e58eb9c's main_imports calls `main_checkout ent "$f"` (no MEMO); 80cc6224 adds `pok`.

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/blc-3e58eb9c.log` (cwd `/tmp/u2a3c-i2-fc1-6NBv/rt3e`, exit 0, 2026-10-07T20:20Z), `/tmp/u2a3c-i2-fc1-6NBv/logs/fixture-git-env.log`

---

## Claim 37: Commit 3e58eb9c: "squash-rebase chosen over a per-commit rebase (same final tree, review reports carried in the next commit)"

**Location:** `git log 3e58eb9c` (commit message)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about the claimed equivalence; the reports-carried half is true (cb9723c3 adds them).

The per-commit rebase it compares against was abandoned on conflicts, so no tree exists to compare. Would need: replaying cebfed35..2b1399ab onto 581d41d8 with the same resolutions and diffing trees.

**Evidence:** paraphrased — no quote available because the claim concerns a rebase result that was never committed

---

## Claim 38: Commit 27364085: "Tests: both new tests fail on 3e58eb9c's lib; a mutant without the drain fails the 4 MiB test (walk failed)"

**Location:** `git log 27364085` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tests on 3e58eb9c's lib and the no-drain mutant (built on HEAD's explicit drain, equivalent at that site); does not cover 27364085's `-p` drain on a /proc-less host.

N1 test and 4 MiB test: not ok on 3e58eb9c's lib, ok on 27364085's; no-drain mutant: `walk: failed`.

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`

---

## Claim 39: Commit 80cc6224: "A test's realpath count: 18, against 102 unmemoized and 74 at 3e58eb9c"; "an empty main tree with an untracked start killed the caller's shell (test added; it fails at 27364085)"

**Location:** `git log 80cc6224` (commit message)
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and the crash at the commits named; does not establish the counts at HEAD (10: Claim 29).

As Claim 4.

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/rpcount.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`

---

## Claim 40: Commit 61e2e734: "/workspace's walks spend about 8,100 each (1.1 s tree, 1.4 s main; the main walk now passes on this developer checkout, which failed closed before U2a3c)"; "a per-file mutant passes at 3w - 1 and fails the test"; "about 6,000x this repo's real work"; "Without IMPORT_WORK_LEFT the parser's output is unchanged"

**Location:** `git log 61e2e734` (commit message)
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each figure on this host today and the mutant against 61e2e734's own test; does not establish the timings elsewhere.

8,110 work each, 1,099 ms and 1,352 ms; main's lib fails the main walk on /workspace (`main-lib: failed`). 50,000,000 / 8,110 = 6,165. The per-file mutant on 61e2e734's lib with 61e2e734's test prints `-1 tree ok`, `-1 main ok` and fails; the unmutated lib passes. Unset IMPORT_WORK_LEFT prints no trailer (Claim 17).

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/wswork.log`; mutant run (cwd `/tmp/u2a3c-i2-fc1-6NBv/rt61`, 2026-10-07T20:19Z; quoted output above); `/tmp/u2a3c-i2-fc1-6NBv/logs/work-left-values.log`

---

## Claim 41: Commit 2fbd929b: "D=1000 took 10.7 s at 21b35ebf, 0.6 s now, main 0.5 s"; "capped_read drains only when told (drain), not on [[ -p /dev/stdin ]]"; "shellcheck SC2034 on pok (passed by name) failed the health check"; "T3 replaces the work-bound test it extends"

**Location:** `git log 2fbd929b` (commit message)
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timings, the drain change (27364085-21b35ebf used `[[ ! -p /dev/stdin ]] || cat > /dev/null`), SC2034 without the directive, and the replaced test; does not re-run the repo health check.

Timings as Claim 2. `shellcheck -S warning` is clean at HEAD and reports `SC2034 (warning): pok appears unused` with the directive removed. No test titled "bounds the parser" remains.

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/deep.log`; `shellcheck -S warning scripts/lib/dev-cycle-read.sh` (cwd worktree, exit 0) and on `/tmp/u2a3c-i2-fc1-6NBv/nosc.sh` (exit 0, SC2034 printed), 2026-10-07T20:20Z, output quoted above

---

## Claim 42: Commit 2fbd929b: "Tests: … 63/78/19/2."

**Location:** `git log 2fbd929b` (commit message)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and their pass status; does not establish that they pass on a host whose bats root is 56+ characters.

Counts are exact; build-loop-check passes only while the fixture root is under 56 characters (Claim 1). Precise version: add "with a TMPDIR under 27 characters" or fix the test's constant.

**Evidence:** as Claim 1

---

## Claims Requiring Attention

### Incorrect
- **Claim 23** (`scripts/lib/dev-cycle-read.sh:720-723`): the PATH arm memoizes `d` without PATH's own main mode (`:753`); a caller passing a path ENT holds as a link then gets 0 below it (executed: 21b35ebf 1, HEAD 0). Unreachable from main_imports; tighten the comment and the U2b contract, or test the mode before memoizing.

### Stale
- **Claim 29** (`test/scripts/build-loop-check.bats:822-825`): the memoized realpath count is 10 at HEAD, not 18 (2fbd929b memoizes PATH too).

### Mostly Accurate
- **Claim 1** (rubric:24): build-loop-check is 62/63 when the bats root is 56+ characters; test 59's fixed `IMPORT_WORK_MAX=1000` fails as `w` grows with ROOT_REAL.
- **Claim 6** (override-log:453): no test has the quoted name; cite the line-921 title.
- **Claim 9** (override-log:456): each call site is one statement over two lines.
- **Claim 10** (A5): the lib's block comment holds the cache rule, not the git-environment duty.
- **Claim 11** (F11): the admission list omits the unreadable-plain-file refusal.
- **Claim 13** (U2b bullet): another main_checkout caller must also pass only paths ENT lacks.
- **Claim 16a** (lib:504-506): the work unit also includes each resolved spelling (root length included); "about 5 s" holds for the many-component shape only.
- **Claim 17** (lib:524-528): a value with leading digits is read as that number, not 0.
- **Claim 30** (test:853): MEMO holds 2 entries too; the test checks only the d ones.
- **Claim 33** (test:942): the test cannot observe "before reading it whole".
- **Claim 42** (2fbd929b): 63/63 depends on TMPDIR length.

### Unverifiable
- **Claim 37** (3e58eb9c): "same final tree" compares with a rebase that was never completed.

## Escalations

- **test-strategy**: (1) test 59 ("each walk caps every file's parser…", `test/scripts/build-loop-check.bats:897-912`) depends on the host path: fixed `IMPORT_WORK_MAX=1000` against `4w`, which passes 1000 at a 56-character fixture root; it fails in the full file with a 27-character TMPDIR (and alone at 97), and silently (set -e, no stderr). Other replicates using longer scratch tags will see 62/63. Derive the cap from `w` (e.g. `10 * w`). (2) T2 does not pin HEAD's analog of M13 (break below an absent ancestor) because the walk's prefixes memoize the absent ancestors first; only T1 kills it. (3) The link-text test cannot see read order (Claim 33).
- **security-reviewer / api-consistency-reviewer**: Claim 23, main_checkout's memo write at `:753` skips PATH's own main mode, so the U2b contract for another caller ("a fresh MEMO per walk and ENT") is not enough to keep a link main stores from being passed through. No live caller is affected; the fix is a precondition in the contract (path not in ENT) or a mode test before the write.
- **performance-reviewer**: the parser's work unit is root-length dependent (each candidate is charged its resolved spelling including ROOT_REAL), so the fixed IMPORT_WORK_MAX buys less real work under a long checkout path; 8,110 at /workspace (10 characters) would be about 4x at a 100-character root. Not a defect at 6,000x headroom, but the comment's unit omits it (Claim 16a).

## Goal-Alignment Note

The branch's code claims hold under execution: the bottom-up memo returns the same codes as 21b35ebf's top-down version over 8,387 randomized calls in random orders, the link cap, drain, work bound and .git rule behave and are pinned by tests that fail on the pre-fix libs, and every timing and count in the commit messages reproduces. What stands between this pass and a clean landing is small: one comment-level invariant (Claim 23) that matters only for a future second caller, one stale test comment, and one test (59) whose pass depends on the length of the host's temp path. That last one does affect the goal directly, since it makes the suite red on some hosts and in some review replicates.
