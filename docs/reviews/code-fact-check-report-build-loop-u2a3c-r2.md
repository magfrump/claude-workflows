Commit: 380ed01b
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3c (branch `feat/build-loop-u2a3c`)
**Scope:** `git diff main...HEAD` (HEAD 380ed01b; last code commit 4b7f2357) plus the commit messages of main..HEAD (3e58eb9c, cb9723c3, 27364085, 80cc6224, 61e2e734, 21b35ebf, 2fbd929b, 3a35c8b9, 4b7f2357, 380ed01b). Code: `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`; docs: `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3c and U2b bullets), `docs/reviews/override-log.md` (rows 439-460). For the other `docs/reviews/*u2a3c*` files, only the rubric's factual claims about the code were checked.
**Checked:** 2026-10-07
**Commit:** 380ed01b
**Replicate:** r2 of k=3 (role fc2)
**Total claims checked:** 40
**Summary:** 35 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 8 entries). No claim here matches a logged pattern. The closest is the test-count pattern ("All 85 tests … but the suites hold 97"); this branch's counts (66/78/19/2) were re-run and match.

Execution provenance (applies to every `executed` claim). The scratch dir is `/tmp/u2a3c-i4-fc2-hpCT/`. The brief forbids writing any other file in the worktree, so captured output stays in the scratch dir's `logs/` and is not copied to `docs/reviews/execution-logs/`. Mutant and old-lib runs used a `git archive HEAD` copy at `/tmp/u2a3c-i4-fc2-hpCT/repo` through `runmut.sh LIB TESTFILE FILTER TMPDIR LABEL`, which writes to `logs/mut-LABEL.log`. Old libs were extracted with `git show <rev>:scripts/lib/dev-cycle-read.sh` into `lib-<rev>.sh`. Mutants: `lib-m3.sh` drops the PATH memo (`:760`), `lib-m4.sh` drops the link-size check (`:850`), `lib-m5.sh` drops the PATH guard (`:743`), `lib-m6.sh` restores `${x@a}`, `lib-m7.sh` makes the PATH guard refuse any ENT mode, and `lib-m8.sh` is m7 plus the same broad guard on ancestors. All runs were on 2026-10-07 between 21:57Z and 22:30Z, on bash 5.2.15, mawk 1.3.4 and git 2.39.

Suite runs (cwd `/workspace/.claude/wt-build-loop-u2a3c`, `LC_ALL=C`, started 2026-10-07T22:14:45Z). Each exited 0:
- `TMPDIR=/tmp/u2a3c-i4-fc2-XXXX` (22 chars) `bats test/scripts/build-loop-check.bats`: 66/66, `logs/blc-short.log`.
- The same with a 73-char TMPDIR: 66/66, `logs/blc-long.log`.
- `dev-cycle.bats` 78/78, `build-loop-read.bats` 19/19, `fixture-hermeticity.bats` 2/2 (`logs/dev-cycle.bats.log`, `logs/build-loop-read.bats.log`, `logs/fixture-hermeticity.bats.log`).
- `shellcheck -x -e SC1091 -s bash -S warning` (the health check's level) on the lib and on build-loop-check.bats: exit 0.

---

## Claim 1: Rubric D1 author note: "`${x[0]@a}` is O(1) and gives the same answers (empty, large, indexed, scalar, unset checked). 2.5 s now, main 0.9 s. A 20 s-timeout test fails at 3a35c8b9 (it catches on hosts up to ~2x faster)."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:92`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what `${x@a}` and `${x[0]@a}` return for an empty, 1,000-entry and 200,000-entry associative array, an associative array with and without key `0`, an indexed array, a scalar, an integer and an unset name, all read through a nameref under a local `set +u`, plus the two forms' timing and the many-token walk's timing on this host. It does not establish timings on other hosts or variables with other attributes (readonly, exported).

The code reads `set +u; [[ "${mc_e[0]@a}" == *A* && "${mc_m[0]@a}" == *A* ]] || return 1` (`scripts/lib/dev-cycle-read.sh:741`). `attr.sh` and `attr2.sh` (`bash /tmp/u2a3c-i4-fc2-hpCT/attr.sh`, exit 0) printed identical full and `[0]` answers for every case: `A` for every associative array (with or without key `0`, empty, large, or declared without a value), `a` indexed, `i` integer, and empty for a scalar or an unset name. On a 200,000-entry array, 100 evaluations of `${R@a}` took 3.04 s and 100 of `${R[0]@a}` took 0.0002 s.

Many-token timing used 4,000 tokens `@nI/a/b/c/d/x.md` in a committed AGENTS.md, which stands in for the test's CLAUDE.md (a hook blocks shell writes to CLAUDE.md, and both are start files). `main_imports` took HEAD 2.3 s, main 0.9 s and 3a35c8b9 39.1 s (`logs/manytoken-timing.log`). The test itself fails at 3a35c8b9 and on the m6 mutant after its 20 s timeout (`logs/mut-many-3a35.log`, `logs/mut-many-m6.log`, about 21 s each) and passes at HEAD in 3.5 s (`logs/mut-many-head.log`). 39-44.6 s against a 20 s timeout is about a 2x margin.

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-741`, `test/scripts/build-loop-check.bats:982-991`, `/tmp/u2a3c-i4-fc2-hpCT/attr.sh`, `/tmp/u2a3c-i4-fc2-hpCT/attr2.sh`, `/tmp/u2a3c-i4-fc2-hpCT/logs/manytoken-timing.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-many-3a35.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-many-m6.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-many-head.log`

---

## Claim 2: Rubric D2 author note: "Guard: main's link or gitlink at PATH answers 1 (test-strategy's form; a broad "any ENT path" guard would break T1's blob row)."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Scope:** Covers the parenthetical's reason for choosing the narrow guard. Under the natural reading (a guard at PATH that refuses any ENT mode), the reason is refuted. It holds only if "broad" also covers ancestors. The verdict does not touch the guard that shipped, which is right (Claim 22).

T1 never passes a PATH that ENT holds. Its ENT is `declare -A E=([lnk]=120000 [gl]=160000 [nd2/m/l]=120000 [f.md]=100644)` and its PATH list includes `f.md/x.md` but not `f.md` (`test/scripts/build-loop-check.bats:857-859`). Mutant m7 replaces `:743` with `[[ -z "${mc_e[$3]+set}" ]] || return 1`, so any ENT path at PATH answers 1. It passes T1 and the whole suite, 66/66 (`logs/mut-broad-full.log`, exit 0).

Only m8, which applies the same broad test to ancestors at `:749`, breaks T1 (`f.md/x.md 1` where 2 is expected; `logs/mut-broad-anc.log`). The guard that shipped is the PATH form, so a reader would take the note as saying that a PATH-level "any ENT" guard breaks T1, and it does not.

**Evidence:** `scripts/lib/dev-cycle-read.sh:743`, `scripts/lib/dev-cycle-read.sh:749`, `test/scripts/build-loop-check.bats:854-883`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-broad-full.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-broad-anc.log`

---

## Claim 3: Rubric D3: "Test 59 (T3) fixed IMPORT_WORK_MAX=1000 while w grows with the fixture root's length: red under a TMPDIR over ~27 characters … Caps derived from w; verified under 17- and 74-character TMPDIRs."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old T3 (3a35c8b9's test file and lib) under a 22- and a 73-character TMPDIR, and the new T3 under 73. The ~27-character threshold is derived, not bisected. The 17- and 74-character runs themselves were not repeated.

At 3a35c8b9, T3 passes with a 22-char TMPDIR and fails with a 73-char one (`logs/mut-t3old-3a35-short.log`, `logs/mut-t3old-3a35-long.log`). Its output stops after `0 main ok`, because the walk under `IMPORT_WORK_MAX=1000` fails under `set -e`.

The threshold, by arithmetic (paraphrased — no quote available because the figure is derived from IMPORT_AWK's charges, not printed anywhere). For `see @a.md`, emit charges 1+2+3+4 and put charges `4R+18` for the four resolved spellings `root "/" dir "/" c` (`:582-585`), so w = 4R+28. This checks out against a measured `/429` for an 11-char name at a 25-char root. Four files fit in 1000 only while w ≤ 250, so R ≤ 55. Bats' root adds 29 characters (`/bats-run-XXXXXX/test/59/repo`), which puts the threshold at TMPDIR ≈ 27.

The new T3 sets `m=$((10 * w))` (`:908`) and passes at 73 characters (`logs/mut-t3-head-long.log`) and in both full suite runs.

**Evidence:** `test/scripts/build-loop-check.bats:898-912`, `scripts/lib/dev-cycle-read.sh:566-599`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-t3old-3a35-long.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-t3old-3a35-short.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-t3-head-long.log`

---

## Claim 4: Rubric D4: "Restored as the first of four caller duties."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:95`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the U2b bullet's wording and count. It does not establish that any caller performs the duties (none exists yet).

The bullet reads "owes the walk four things: that checkout a clean worktree at MAIN_SHA (…); that checkout final before the walk, or `IMPORTED_MAIN_DONE` cleared (…); a git that prints nothing on stderr for `ls-files` (…); and the git environment the override log hands the caller" (`docs/working/plan-build-loop-handoff.md:279`). The clean-worktree duty is first of four.

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 5: Rubric "Tests after fixes (4b7f2357): build-loop-check 66/66 under a 17- and a 74-character TMPDIR, dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2; shellcheck clean"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:82`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at HEAD 380ed01b (same code as 4b7f2357) under 22- and 73-character TMPDIRs, and shellcheck at the health check's `-S warning` level. It does not establish `scripts/health-check.sh` passing (not run) or the exact 17/74 lengths.

The counts are 66/66 at 22 and 73 characters, 78/78, 19/19 and 2/2, all exit 0. Shellcheck exits 0 at `-S warning` on the lib and on build-loop-check.bats. At its default level it prints info/style notes only (SC2015, SC2016, SC2004; `logs/shellcheck.log`).

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/logs/blc-short.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/blc-long.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/dev-cycle.bats.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/build-loop-read.bats.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/fixture-hermeticity.bats.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/shellcheck.log`

---

## Claim 6: Rubric Confirmed Good: "For PATHs ENT lacks, main_checkout returns 21b35ebf's code under any call order on one MEMO"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:112`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers random checkout shapes up to depth 4 (absent, searchable and unsearchable directories, readable and unreadable files, symlinks to `.` and to nothing, FIFOs) under random ENT modes and 40 random calls per tree on one MEMO, for every PATH, including those ENT holds. It does not cover case-insensitive file systems, depth beyond 4, or ENT shapes main_imports' duplicate check would refuse (ENT here may hold both `p` and `p/x`).

`fuzz.sh` runs 21b35ebf's `main_checkout` (renamed `mc_old`) beside HEAD's, each with its own MEMO, over 300 seeds and 12,000 calls. Command: `bash /tmp/u2a3c-i4-fc2-hpCT/fuzz.sh <lib> mc_old.sh fz 300`, cwd `/tmp/u2a3c-i4-fc2-hpCT`, started 2026-10-07T22:13:03Z, exit 0. Result: `seeds=300 calls=12000 mismatches=0 allowed_link_at_PATH=983`.

Every one of the 983 differences is a PATH that ENT holds as `120000`/`160000` where HEAD answers 1, the intended guard (`:743`). The harness has the power to find a regression: run with 2fbd929b's `main_checkout` (no guard), it reports 62 non-allowed mismatches, such as `path=c/b/b old=1 new=2` (`fuzz2.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, `/tmp/u2a3c-i4-fc2-hpCT/fuzz.sh`, `/tmp/u2a3c-i4-fc2-hpCT/fuzz.log`, `/tmp/u2a3c-i4-fc2-hpCT/fuzz2.log`

---

## Claim 7: Override row 457: "capped_read drains only when the blob arm passes `drain` (since 2fbd929b), and the test row 453 names is "main walk reads an untracked start that a main file also imports once, through the checkout""

**Location:** `docs/reviews/override-log.md:457`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers capped_read's drain condition, the one `drain` caller, and the test title. It does not re-establish rows 449/453's other content.

The code reads `capped_read() { head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null; }` (`scripts/lib/dev-cycle-read.sh:710`). The only call with the word is `git cat-file blob "$MAIN_SHA:$f" | capped_read drain` (`:846`). The checkout arm (`:844`) and the tree walk (`:782`) call it bare. The test title is `@test "main walk reads an untracked start that a main file also imports once, through the checkout (U2a3c; override row 446)"` (`test/scripts/build-loop-check.bats:923`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:710`, `scripts/lib/dev-cycle-read.sh:782`, `scripts/lib/dev-cycle-read.sh:844-847`, `test/scripts/build-loop-check.bats:923`

---

## Claim 8: Override row 458: "A deep token through directories the checkout holds still costs about D³ in realpath (D=1000: 14.3 s; 21b35ebf 33.7 s; main over 120 s) … IMPORT_OUT_MAX caps D near 2,000"

**Location:** `docs/reviews/override-log.md:458`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the mechanism (one realpath per distinct prefix, each linear in depth with per-component lookups) and the D=250/500/1000 timings at HEAD and 21b35ebf on this host. It does not establish the asymptotic exponent: measured growth per doubling is 3.8x to 5.7x at D ≤ 1000, below D³'s 8x. The main lib did not finish within a 300 s timeout (consistent with "over 120 s").

Per distinct prefix candidate, `main_checkout` finds the parent memoized `d` and runs `plaindir "$c"` at PATH, which is `realpath -e` over a k-component path (`scripts/lib/dev-cycle-read.sh:759`, `:106`). That makes Σk² path lookups, about D³/3. Measured with `deep.sh` (token `@a/…/x.md` through D present untracked directories, AGENTS.md start): D=250 0.5 s, D=500 1.9 s, D=1000 10.9 s at HEAD; 21b35ebf D=1000 30.3 s; main killed by `timeout 300` at 300.6 s (`logs/deep.log`, `logs/deep-present-old.log`). These are 10.9 s against the row's 14.3 s and 30.3 s against 33.7 s, which is host variance.

On the D cap (paraphrased — no quote available because the figure is arithmetic over the printed names): the distinct names printed are about D paths of length about 2k, so the printed sum is about D², and 4,000,000 gives D ≈ 2,000.

**Evidence:** `scripts/lib/dev-cycle-read.sh:756-761`, `scripts/lib/dev-cycle-read.sh:106`, `/tmp/u2a3c-i4-fc2-hpCT/deep.sh`, `/tmp/u2a3c-i4-fc2-hpCT/logs/deep.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/deep-present-old.log`

---

## Claim 9: Override row 459: "The walk's caller contract lives in two places (the lib block comment for the cache rules, the plan's U2b bullet for the rest) … A5 now names which part lives where."

**Location:** `docs/reviews/override-log.md:459`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three texts' current content. It does not establish that the U2b bullet holds only "the rest": it repeats the cache-clear duty as well.

The lib comment holds the cache rules: "the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, never the checkout, … so a caller whose checkout may have changed … sets IMPORTED_MAIN_DONE="" to walk again" (`scripts/lib/dev-cycle-read.sh:486-491`). A5 reads "the lib's block comment above `IMPORTED=` holds the cache rules; the plan's U2b bullet holds the rest of what a caller owes the walk" (`docs/working/known-issues-dev-cycle.md:18`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:486-496`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 10: Override row 460: "The Incorrect was unreachable from main_imports; every critic weighed it; fixed in code (guard + test)."

**Location:** `docs/reviews/override-log.md:460`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reachability (both main_checkout call sites), the guard, and its test. "Every critic weighed it" is a process claim and was not checked.

Both call sites skip paths ENT holds. One is `[[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f"`, where `t:` candidates are only those `[[ -n "${ent[$f]+set}" ]] ||` excluded (`scripts/lib/dev-cycle-read.sh:826`, `:832`). The other is `[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"` (`:877`). The guard is at `:743`. Its test fails at 3a35c8b9 and on m5 (`l 2 / l/f.md 0 / g 2 / g/f.md 0`) and passes at HEAD (`logs/mut-pre-3a35.log`, `logs/mut-pre-m5.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:826-834`, `scripts/lib/dev-cycle-read.sh:877`, `test/scripts/build-loop-check.bats:973-980`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-pre-3a35.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-pre-m5.log`

---

## Claim 11: A5: "a checkout path it would walk that lies under a directory main stores as a link or gitlink or under an unsearchable directory, anything but a plain file or directory there (or nothing), an unreadable checkout file, a `..` after a checkout link in link text, and a checkout listing git prints any stderr for fail it"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed fail cases and one unlisted one. Every listed case fails as stated. The list omits a path that lies under a non-plain checkout ancestor (a symlinked directory, a dangling link, a FIFO), which fails even when nothing is at the path. It does not establish Claude Code's behaviour there.

The ancestor test fails on anything but a plain searchable directory: `elif ! plaindir "$c" || [[ ! -x "$c" ]]; then return 1; fi` (`scripts/lib/dev-cycle-read.sh:752`). An executed fixture had a committed `AGENTS.md` holding `see @sl/x.md` and an untracked `sl -> d` with `d/x.md`. `main_imports` printed `failed` and `main_checkout E M sl/x.md` returned `mc=1` (cwd `/tmp/u2a3c-i4-fc2-hpCT/sl`, inline run, exit 0). T1 pins the same shape with nothing at PATH: `sd/nx.md 1` and `dgd/x.md 1` (`test/scripts/build-loop-check.bats:875-876`).

Read literally, A5's "anything but a plain file or directory there (or nothing)" lets `sd/nx.md` pass ("nothing" there). The precise version adds "or under a checkout directory that is not plain (a link, a FIFO)". The omission fails closed, and iteration 1's rubric C8 records the stricter shape as intended.

**Evidence:** `scripts/lib/dev-cycle-read.sh:747-755`, `test/scripts/build-loop-check.bats:854-883`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 12: A5: "the lib's block comment above `IMPORTED=` holds the cache rules; the plan's U2b bullet holds the rest of what a caller owes the walk: a clean worktree at MAIN_SHA, empty `ls-files` stderr, the git environment, `LC_ALL=C`"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of each named item in the named place. It does not establish that the U2b bullet holds only the rest (it also states the cache clear).

The U2b bullet holds "a clean worktree at MAIN_SHA", "a git that prints nothing on stderr for `ls-files`", "the git environment the override log hands the caller" and "runs the walk under `LC_ALL=C` (A5)" (`docs/working/plan-build-loop-handoff.md:279`). The block comment above `IMPORTED=` holds the cache key and clear rules (`scripts/lib/dev-cycle-read.sh:486-491`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `scripts/lib/dev-cycle-read.sh:486-496`

---

## Claim 13: F11: "one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, an unreadable file, or anything but a plain file or directory, and a checkout listing git prints any stderr for fails the walk; the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers F11's admission list against `main_checkout` and its contract parenthetical against the U2b bullet. Both halves are right in what they name but incomplete. The admission list omits the non-plain checkout ancestor (Claim 11). The parenthetical names three duties where the U2b bullet now lists four plus `LC_ALL=C`.

`main_checkout` returns 1 for an ancestor main stores as a link or gitlink (`:749`), an unsearchable or non-plain ancestor (`:752`), an unreadable plain file (`if rawfile "$c"; then [[ -r "$c" ]]; return; fi`, `:758`) and anything else at PATH (`plaindir "$c" || return 1`, `:759`). `checkout_md` fails on any stderr (`:717`).

4b7f2357 added "a clean worktree at MAIN_SHA" as the U2b bullet's first duty (`docs/working/plan-build-loop-handoff.md:279`), and it edited F11 in the same commit ("F11 lists the unreadable file"). F11's "(cache clear, empty `ls-files` stderr, the git environment)" was not extended to name it.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `docs/working/plan-build-loop-handoff.md:279`, `scripts/lib/dev-cycle-read.sh:717`, `scripts/lib/dev-cycle-read.sh:747-761`

---

## Claim 14: U2a3c bullet: "Built 2026-10-07 after the rebase onto U2a3b: the fail rules as stated (a readable plain file main lacks is walked; a non-plain node, an unreadable file, or a path under main's link or gitlink or under an unsearchable directory fails), `capped_read`, the work bound `IMPORT_WORK_MAX` (reported by the parser's trailer, charged by `import_work`), `main_checkout`'s ancestor memo, the `.git` rule, and N1 (`lower_all` under `nul_list`)."

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and wiring of each named piece. Their correctness is verdicted in Claims 20-24 and 40.

The pieces are all present and wired. `capped_read` is at `:710`. `IMPORT_WORK_MAX=50000000` is at `:512`. The trailer is `END { if (trail) print "/" (work + 0) }` (`:630`), and `import_work` is called at `:783`, `:845` and `:847`. The memo is the `mc_m` writes at `:754` and `:760`. `nul_list low lower_all "${cand[@]}"` is at `:827`. "A non-plain node … fails" matches `:752` and `:759`, which also cover the non-plain ancestor that Claims 11 and 13 find missing from A5 and F11.

**Evidence:** `scripts/lib/dev-cycle-read.sh:510-512`, `scripts/lib/dev-cycle-read.sh:630`, `scripts/lib/dev-cycle-read.sh:701-710`, `scripts/lib/dev-cycle-read.sh:752-760`, `scripts/lib/dev-cycle-read.sh:827`

---

## Claim 15: U2b bullet: "that checkout a clean worktree at MAIN_SHA (the walk reads main's blob for every path main stores, so an edited tracked instruction file's own imports go unread …)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arm choice for paths ENT holds. It does not establish that U2b enforces cleanliness (not built).

The read arm is chosen by `case "${ent[$f]-checkout}" in`. A path ENT holds as `100644|100755` is read with `git cat-file blob "$MAIN_SHA:$f"`, and only an ENT-absent path reads the checkout (`scripts/lib/dev-cycle-read.sh:843-847`). Starts that main stores are queued from `m:` candidates without any checkout check (`:832-834`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:829-847`

---

## Claim 16: U2b bullet: "A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too) and a PATH main lacks or stores as a blob (a link or gitlink there answers 1)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the MEMO-hit skip, the 1 at a link or gitlink PATH, and a blob PATH being answered by the checkout's shape. On safety, a blob PATH whose checkout holds a searchable directory is memoized `d`, the same treatment ancestors that ENT holds as blobs already get (`:749` tests link and gitlink modes only), so it opens nothing 21b35ebf did not. That is safe only under the bullet's clean-worktree duty.

A memo hit sets `st` without a mode check: `if [[ -n "${mc_m[$c]+set}" ]]; then st="${mc_m[$c]}"; break; fi` (`:746`). The PATH guard `[[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1` (`:743`) refuses only link and gitlink modes. The fuzz in Claim 6 found no difference from 21b35ebf for blob-mode PATHs.

**Evidence:** `scripts/lib/dev-cycle-read.sh:741-760`, `/tmp/u2a3c-i4-fc2-hpCT/fuzz.log`

---

## Claim 17: Lib block comment: "a checkout path it would walk (a start or an import main lacks) that lies under a directory main stores as a symlink or gitlink or under an unsearchable directory, or that the checkout holds as anything but a readable plain file, a plain directory or nothing (the root included), or a checkout listing git prints any stderr for, fail the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:471-475`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same rule set as Claim 11, for the lib's own comment. It does not cover main_checkout's function comment, which does name "an ancestor that is anything else but a plain searchable directory" (`:729-730`) and is accurate.

Same omission as Claim 11. A path under a checkout symlinked directory (or a dangling link, or a FIFO) with nothing at the path fails, as `sl/x.md` → `failed` and T1's `sd/nx.md 1` and `dgd/x.md 1` show. The block comment's "or nothing" says that case passes. The precise version adds "or under a checkout node that is not a plain directory".

**Evidence:** `scripts/lib/dev-cycle-read.sh:471-477`, `scripts/lib/dev-cycle-read.sh:727-731`, `scripts/lib/dev-cycle-read.sh:752`, `test/scripts/build-loop-check.bats:875-876`

---

## Claim 18: "Each walk also fails once the parser's work (the candidate and comment-splice characters it scans and each resolved spelling it joins, which carries ROOT_REAL, so a longer root buys less; the unit of its per-file bound of 50,000,000 …) passes this in all … reading, draining and the scan of @-less lines are not charged … /workspace's walks spend about 8,100 each (2026-10-07)."

**Location:** `scripts/lib/dev-cycle-read.sh:504-512`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what IMPORT_AWK charges and /workspace's two walks' totals today. A `~/` name's resolved spelling carries the home, not ROOT_REAL. The "about 5 s" per bound is carried from U2a3b and was not re-measured.

The charges are `work += length(c)` per candidate in `emit` (`:567`), `work += length(c)` on `c = root "/" dir "/" c` in `put` (`:582-585`), and `work += length(r)` in `splice` (`:618`). `scan` skips non-`@` characters uncharged (`:605`).

The totals were taken with an instrumented copy of the lib that logs `import_work`'s total (`lib-measure.sh`; `bash measure.sh <root>`, started 2026-10-07T22:22:20Z, exit 0). /workspace: tree 8,110 in 1.0 s, main 8,110 in 1.2 s, both ok. The worktree root: 5,075 each (`logs/workspace-work.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:565-630`, `/tmp/u2a3c-i4-fc2-hpCT/measure.sh`, `/tmp/u2a3c-i4-fc2-hpCT/logs/workspace-work.log`

---

## Claim 19: "IMPORT_LEFT (what may still be printed; IMPORT_OUT_MAX when unset or empty, and as awk reads a number otherwise: its leading digits, or 0, so the first name fails it) and IMPORT_WORK_LEFT (… Unset or empty: no trailer and only the per-file bound; otherwise read as IMPORT_LEFT is). Both walks pass numbers."

**Location:** `scripts/lib/dev-cycle-read.sh:524-529`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk 1.3.4's reading of `ENVIRON[...] + 0` for 14 inputs and the unset/empty/trailer rules. "As awk reads a number" is right. The gloss "its leading digits, or 0" is not: mawk reads a sign, an exponent, hex, and `inf`/`nan`. The walks are unaffected, since both pass `$((…))` integers (`:782`, `:844-846`).

The code is `left = ENVIRON["IT_LEFT"] + 0` and `if (trail && ENVIRON["IT_WORK"] + 0 < wmax) wmax = ENVIRON["IT_WORK"] + 0` (`:626-627`). Executed in `/tmp/u2a3c-i4-fc2-hpCT/pl` (output 77 bytes, 11 names):
- `IMPORT_LEFT=1e3` → ok (read as 1000, not 1).
- `0x1000` → ok (read as 4096, not 0).
- `inf` and `nan` → ok, so the print cap is gone.
- `+500`, `.5e4` and `500 ` → ok.
- `5abc`, `abc`, ` 7`, `-3` and `1.5` → failed.
- empty → ok with no trailer (`ok[abcdefgh.md]`).
- `IMPORT_WORK_LEFT=inf` keeps wmax at 50,000,000 (`inf < wmax` is false).

The precise version is "as awk reads a number (a leading decimal, exponent or hex numeral, `inf`/`nan`; otherwise 0)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:520-530`, `scripts/lib/dev-cycle-read.sh:624-630`, inline runs recorded in this claim (cwd `/tmp/u2a3c-i4-fc2-hpCT/pl`)

---

## Claim 20: "import_work OUT TOTAL: strips the parser's work trailer (its last line, "/N", printed when IMPORT_WORK_LEFT is set; a repo-relative name never starts with /) from the variable OUT, and adds N to the variable TOTAL. It returns 1 when the trailer is missing or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:674-683`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the strip, the missing-trailer test and the bound (equality passes). It does not cover a trailer with leading zeros, which bash would read as octal; awk's `"/" (work + 0)` never prints one.

The function is `iw_w="${iw_o##*/}"`, then `[[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1`, then the strip, then `(( (iw_t += iw_w) <= IMPORT_WORK_MAX ))` (`:679-682`). The parser emits the trailer only when `IT_WORK` is non-empty (`:627`, `:630`); the empty case printed no trailer in Claim 19's run. T3's `-1 failed / 0 ok` rows pin the boundary, and they pass in both suite runs.

**Evidence:** `scripts/lib/dev-cycle-read.sh:674-683`, `scripts/lib/dev-cycle-read.sh:627-630`, `test/scripts/build-loop-check.bats:898-912`, `/tmp/u2a3c-i4-fc2-hpCT/logs/blc-long.log`

---

## Claim 21: "capped_read: the first 4 MiB + 1 bytes of stdin, the one reader both walks parse, for checkout files and main's blobs alike … With the word drain (after git cat-file) it reads the rest … an argument, not a [[ -p /dev/stdin ]] test, which needs /proc. The drain is time the work bound does not charge"

**Location:** `scripts/lib/dev-cycle-read.sh:702-710`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte count, the three call sites and the drain condition. The suite's 4 MiB tests pass. "Claude Code skips a file over 4 MiB" is carried from main and not re-checked here. Link blobs are not read through capped_read (they go through the 4096-byte check, Claim 24).

The function is `head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null` (`:710`). 4194305 = 4·1024² + 1. Its callers are the tree walk (`:782`), the checkout arm (`:844`) and the blob arm with `drain` (`:846`). There is no `/dev/stdin` test anywhere in the function.

**Evidence:** `scripts/lib/dev-cycle-read.sh:702-710`, `scripts/lib/dev-cycle-read.sh:782`, `scripts/lib/dev-cycle-read.sh:844-847`, `/tmp/u2a3c-i4-fc2-hpCT/logs/blc-short.log`

---

## Claim 22: main_checkout comment: "set only once its own and every higher ancestor's main mode passed (PATH's own mode is checked first: main's link or gitlink at PATH answers 1). A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT. main_imports calls it only for paths main lacks."

**Location:** `scripts/lib/dev-cycle-read.sh:723-726`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every MEMO write (`:754`, `:760`) and both call sites. Every call order on one MEMO matches 21b35ebf except the intended 1 at a link or gitlink PATH (Claim 6). It does not establish behaviour when a caller reuses a MEMO across ENTs (documented as unsupported).

There are two writes. `mc_m[$c]="$st"` (`:754`) follows `:749`'s mode check of `c`; the ancestors above it were checked in the same loop or, through a memo hit, by an earlier call. `[[ ! -x "$c" ]] || mc_m[$c]=d` (`:760`) is reached only after `:743` has checked PATH. Both call sites skip ENT paths (Claim 10). The PATH memo is pinned: m3 raises the realpath count to 18 and fails `-le 14` (`logs/mut-memo-m3.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, `scripts/lib/dev-cycle-read.sh:826-834`, `scripts/lib/dev-cycle-read.sh:877`, `/tmp/u2a3c-i4-fc2-hpCT/fuzz.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-memo-m3.log`

---

## Claim 23: "${x@a} on an empty array is an unbound-variable error under set -u (an empty main tree, the first call's MEMO) … ${x[0]@a}, not ${x@a}, which costs time linear in the array's size (U2a3c final performance F1: quadratic once MEMO grows with the tokens)."

**Location:** `scripts/lib/dev-cycle-read.sh:737-741`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the linear cost of `${x@a}` and the O(1) cost of `${x[0]@a}` (Claim 1), plus the quadratic walk at 3a35c8b9. The set -u error itself was not re-executed here; `set +u` precedes both expansions, so the point is moot at HEAD.

On 200k entries, 3.04 s versus 0.0002 s per 100 evaluations (`attr2.sh`). 4,000 tokens take 39.1 s at 3a35c8b9 against 2.3 s at HEAD (`logs/manytoken-timing.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:736-741`, `/tmp/u2a3c-i4-fc2-hpCT/attr2.sh`, `/tmp/u2a3c-i4-fc2-hpCT/logs/manytoken-timing.log`

---

## Claim 24: "Link text past PATH_MAX (4096) names nothing; it fails before the two whole reads below."

**Location:** `scripts/lib/dev-cycle-read.sh:849-850`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ordering and the bound at 4096/4097 bytes. It does not establish Claude Code's own limit.

The line is `i="$(git cat-file -s "$MAIN_SHA:$f")" && [[ "$i" -le 4096 ]] || { IMPORTED_MAIN=error; return 1; }` (`:850`), followed by the two `git cat-file blob` reads (`:853-854`). The cat-file shim test passes at HEAD. On m4 (check removed) it fails with `walk: ok / link blob read` for the 4097-byte link (`logs/mut-cat-m4.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:848-866`, `test/scripts/build-loop-check.bats:944-956`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-cat-m4.log`

---

## Claim 25: Test comment: "Unmemoized, each candidate re-checks every ancestor (102 calls; 74 at 3e58eb9c); memoized, each directory once, plus each candidate's own check (10 at 2fbd929b; 18 without its memo of a prefix candidate's own directory)." (bound `-le 14`)

**Location:** `test/scripts/build-loop-check.bats:822-832`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at HEAD, 3a35c8b9, 21b35ebf, 3e58eb9c and m3, using the test with its assertion replaced by a print (`blc-count.bats`). The "102 unmemoized" figure was not re-run.

realpath counts: HEAD 10, 3a35c8b9 10, 21b35ebf 18, m3 18, 3e58eb9c 74 (`logs/mut-cnt-*.log`). The bound 14 separates 10 from 18: m3 fails (`logs/mut-memo-m3.log`), and HEAD and 3a35c8b9 pass.

**Evidence:** `test/scripts/build-loop-check.bats:821-833`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-cnt-head.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-cnt-21b3.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-cnt-3e58.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-cnt-m3.log`

---

## Claim 26: T1 title: "… and memoizes plain searchable directories as d and absent or plain-file ancestors as 2 (U2a3c)"

**Location:** `test/scripts/build-loop-check.bats:854`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T1's expected memo line and its pass at 22 and 73 characters. `nd2/m=2` is an absent ancestor below an absent one, which the title's "absent" covers.

The expected line is `memo d=d f.md=2 nd2/m=2 nd2=2 nd=2` (`:880`), and T1 passes in both suite runs and in `logs/mut-t1-head-long.log`.

**Evidence:** `test/scripts/build-loop-check.bats:854-883`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-t1-head-long.log`

---

## Claim 27: T3 comment: "The caps derive from w: each candidate is charged its resolved spelling, so w grows with the fixture root."

**Location:** `test/scripts/build-loop-check.bats:907`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same evidence as Claim 3. It does not establish the comment's "each candidate" for `~/` names, whose spelling carries the home instead.

`put` charges `length(c)` after `c = root "/" dir "/" c` (`scripts/lib/dev-cycle-read.sh:582-585`). The worktree root's walks cost 5,075 and /workspace's 8,110 over the same files, a difference driven by the root length (Claim 18).

**Evidence:** `test/scripts/build-loop-check.bats:907-908`, `scripts/lib/dev-cycle-read.sh:582-585`, `/tmp/u2a3c-i4-fc2-hpCT/logs/workspace-work.log`

---

## Claim 28: cat-file shim test: "A git shim logs each `git cat-file blob` object name: the long link must fail with no read of its blob."

**Location:** `test/scripts/build-loop-check.bats:947`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shim's logging condition and the test's power against m4. At 3a35c8b9 it passes (it pins behaviour 2fbd929b added, not a 4b7f2357 fix).

The shim logs `$3` when `"$1 $2"` is `cat-file blob` and the test greps `:CLAUDE\.md$` (`:948`, `:952`). m4 fails, 3a35c8b9 passes, HEAD passes (`logs/mut-cat-m4.log`, `logs/mut-cat-3a35.log`).

**Evidence:** `test/scripts/build-loop-check.bats:944-956`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-cat-m4.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-cat-3a35.log`

---

## Claim 29: xtrace test comment: "Linear work gives a ratio of about 4 (4.0 at 3a35c8b9); 21b35ebf's top-down rescan of every absent ancestor gives about 16 (15.6). A count, so no host is fast enough to hide it."

**Location:** `test/scripts/build-loop-check.bats:959-962`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the command counts at HEAD, 3a35c8b9 and 21b35ebf, and the test's result on each. The test does not catch D1 (the `${x@a}` cost, which xtrace does not count). The many-token test covers that (Claim 31), and the commit message assigns them so.

Counts at 100/400 levels: 3a35c8b9 4,701/18,801 (4.0), HEAD 4,901/19,601 (4.0), 21b35ebf 72,704/1,130,804 (15.55). The test fails at 21b35ebf (`logs/mut-xt-21b3.log`) and passes at 3a35c8b9 and at HEAD under a 73-char TMPDIR.

**Evidence:** `test/scripts/build-loop-check.bats:958-971`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-xt-21b3.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-xt-3a35.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-xt-head-long.log`

---

## Claim 30: Precondition test title: "main_checkout refuses a PATH main stores as a link or gitlink, so a plain checkout directory there never passes a path below it (U2a3c final)"

**Location:** `test/scripts/build-loop-check.bats:973`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's expectations and its power against 3a35c8b9 and m5. It does not cover a PATH that main stores as a link whose checkout holds a file.

The test expects `l 1 / l/f.md 1 / g 1 / g/f.md 1` (`:979`). 3a35c8b9 and m5 give `l 2 / l/f.md 0 / g 2 / g/f.md 0`, and HEAD passes.

**Evidence:** `test/scripts/build-loop-check.bats:973-980`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-pre-3a35.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-pre-m5.log`

---

## Claim 31: Many-token test comment: "4,000 tokens @nI/a/b/c/d/x.md, none in the checkout: about 2.5 s here; at 3a35c8b9 … (44.6 s), so this catches it on hosts up to about 2x faster than the one it was measured on."

**Location:** `test/scripts/build-loop-check.bats:983-986`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers this host's timings (HEAD 2.3 s bare and 3.5 s under bats; 3a35c8b9 39.1 s; timeout 20 s). It does not establish behaviour on other hosts. On a host about 6x slower than this one, HEAD would approach the 20 s timeout, a possible flake on loaded CI.

See Claim 1. Both 3a35c8b9 and m6 fail at about 21 s.

**Evidence:** `test/scripts/build-loop-check.bats:982-991`, `/tmp/u2a3c-i4-fc2-hpCT/logs/manytoken-timing.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-many-head.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-many-3a35.log`

---

## Claim 32: Commit 4b7f2357: "main_checkout answers 1 when main stores PATH as a link or gitlink, before a checkout directory there is memoized as d: a caller other than main_imports could otherwise admit a file under main's link … main_imports never passes such a PATH."

**Location:** commit 4b7f2357
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard's position before the memo write and the 3a35c8b9 fail-open (`l/f.md 0`). Reachability is static (Claim 10).

The guard is at `:743`, before any write at `:754` or `:760`. At 3a35c8b9 the precondition test shows `l/f.md 0` (admitted under main's link).

**Evidence:** `scripts/lib/dev-cycle-read.sh:743`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-pre-3a35.log`

---

## Claim 33: Commit 4b7f2357: "(performance F1: 4,000 deep tokens 44.6 s at 3a35c8b9, 2.5 s now, main 0.9 s). Test added; it fails at 3a35c8b9."

**Location:** commit 4b7f2357
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this host's 39.1 / 2.3 / 0.9 s and the test failing at 3a35c8b9. Exact seconds vary by host.

See Claims 1 and 31.

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/logs/manytoken-timing.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-many-3a35.log`

---

## Claim 34: Commit 4b7f2357: "T3's caps derived from w (it failed under a TMPDIR over ~27 characters), a host-independent xtrace-count test for the deep-token cost, a cat-file shim pinning that link text over 4096 is never read, the PATH memo pinned, T1 prints the whole MEMO, the precondition test. 66/66 under a 17- and a 74-character TMPDIR; 78/19/2."

**Location:** commit 4b7f2357
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed test, its power against its target (Claims 3, 25, 26, 28, 29, 30) and the counts at 22- and 73-character TMPDIRs. The PATH memo pin is the realpath bound tightened from 30 to 14, which the message does not spell out.

The diff `3a35c8b9..4b7f2357 -- test/` changes `[ "$n" -le 30 ]` to `[ "$n" -le 14 ]` and adds the four new tests and the T1 and T3 edits.

**Evidence:** `test/scripts/build-loop-check.bats:821-991`, `/tmp/u2a3c-i4-fc2-hpCT/logs/blc-short.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/blc-long.log`

---

## Claim 35: Commit 4b7f2357 Notes: "the many-token test's 20 s timeout catches the regression only on hosts up to about 2x faster than this one; the xtrace test covers the deep case host-independently."

**Location:** commit 4b7f2357
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 39-44.6 s against 20 s margin and the xtrace test's power against 21b35ebf. "The deep case" means the top-down rescan, not D1; the xtrace test passes at 3a35c8b9.

See Claims 29 and 31.

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-xt-21b3.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-xt-3a35.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/manytoken-timing.log`

---

## Claim 36: Commit 380ed01b: "Merged fact-check (64 clusters, 1 Incorrect, agreement 78.1%), five critic reports, Stage 2.5 submitted claims (at 4b7f2357), and the rubric's final section."

**Location:** commit 380ed01b
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the files' headers and the commit's file list. The merge's arithmetic was not re-derived.

The merged report's header reads `**Total claims checked:** 64` and `**Summary:** 41 verified, 14 mostly accurate, 2 stale, 1 incorrect, 6 unverifiable` (`docs/reviews/code-fact-check-report-build-loop-u2a3c.md:8-9`). The rubric reads "Agreement 78.1% (50/64)" (`code-review-rubric-…:74`). Five `*-final.md` critic files are in the commit (security, performance, api-consistency, architecture, test-strategy). The submitted-claims file has `Commit: 4b7f2357` as its first line.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a3c.md:1-9`, `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:74`, `docs/reviews/code-fact-check-submitted-claims-build-loop-u2a3c.md:1`

---

## Claim 37: Commit 2fbd929b: "performance F1: D=1000 took 10.7 s at 21b35ebf, 0.6 s now, main 0.5 s"

**Location:** commit 2fbd929b
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one absent token D=1000 levels deep (`deep2.sh 1000 <lib> absent`, started 2026-10-07T22:24:05Z) on this host: HEAD (same main_checkout as 2fbd929b plus the guard and `[0]@a`), 21b35ebf and main.

HEAD 0.6 s, 21b35ebf 10.2 s, main 0.5 s, all `ok` (`logs/deep-absent.log`).

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/deep2.sh`, `/tmp/u2a3c-i4-fc2-hpCT/logs/deep-absent.log`

---

## Claim 38: Commit 61e2e734: "Measured 2026-10-07: /workspace's walks spend about 8,100 each (1.1 s tree, 1.4 s main; the main walk now passes on this developer checkout, which failed closed before U2a3c)."

**Location:** commit 61e2e734
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's /workspace checkout with HEAD's lib: work 8,110 each, tree 1.0 s, main 1.2 s, both `ok`. "Failed closed before U2a3c" was not re-run.

See Claim 18.

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/logs/workspace-work.log`

---

## Claim 39: Commit 80cc6224: "A test's realpath count: 18, against 102 unmemoized and 74 at 3e58eb9c."

**Location:** commit 80cc6224
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 18 (21b35ebf, whose `main_checkout` is byte-identical to 80cc6224's: `diff` of the two functions printed `same`) and 74 at 3e58eb9c. The 102 figure was not re-run.

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-cnt-21b3.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-cnt-3e58.log`

---

## Claim 40: Commit 3e58eb9c: "The top-level .git special case is gone: the .git directory passes main_checkout as a plain directory, and a linked worktree's gitfile is read as a checkout file"; lib: "A linked worktree's .git file and files under .git are checkout files like any other."

**Location:** commit 3e58eb9c; `scripts/lib/dev-cycle-read.sh:476-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_checkout's answer for `.git` in a linked worktree and in the main checkout, and `.git/HEAD`. Whether Claude Code reads a gitfile is Q-126's host probe and was not checked here.

Inline runs with the lib, each exit 0, with ENT and MEMO empty:
- In the worktree, `main_checkout E M .git` → `0` (a readable plain file).
- In /workspace, `.git` → `2` with memo `d`, and `.git/HEAD` → `0`.

Tests at `:411`, `:657` and `:700` pin these shapes and pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:476-477`, `scripts/lib/dev-cycle-read.sh:756-761`, `test/scripts/build-loop-check.bats:411`, `test/scripts/build-loop-check.bats:657`, `test/scripts/build-loop-check.bats:700`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`): a broad "any ENT path" guard at PATH does not break T1 (m7 passes 66/66). Only a broad guard on ancestors breaks T1's `f.md/x.md` row. The fix is to say "on ancestors too", or drop the reason. This is a history doc, so the fix is a correction note, not a code change.

### Stale
- None.

### Mostly Accurate
- **Claim 11** (`docs/working/known-issues-dev-cycle.md:18`): A5's fail list omits a path under a non-plain checkout ancestor (symlinked directory, dangling link, FIFO), which fails even with nothing at the path (`sd/nx.md 1`). It fails closed.
- **Claim 13** (`docs/working/plan-build-loop-handoff.md:126`): F11 has the same omission. Its "caller contract (cache clear, empty `ls-files` stderr, the git environment)" also leaves out the clean-worktree duty that 4b7f2357 added to U2b, and `LC_ALL=C`.
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:471-475`): the block comment says "or nothing" passes, but a path with nothing there under a checkout link or FIFO ancestor fails. main_checkout's own comment (`:729-730`) is accurate.
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:524-529`): "its leading digits, or 0" is wrong for mawk, which reads `1e3` as 1000, `0x1000` as 4096, and `inf`/`nan` with no bound. "As awk reads a number" is right, and the walks always pass integers.

### Unverifiable
- None. Partial scopes (not re-run): the "102 unmemoized" realpath count, the 17- and 74-character TMPDIRs exactly (22 and 73 used), `scripts/health-check.sh`, and Claude Code's gitfile reading (Q-126).

## Escalations

- **security-reviewer**: Claims 11, 13 and 17. The written fail rules (lib block comment, A5, F11) omit main_checkout's refusal of any path under a non-plain checkout ancestor, even when nothing is at the path. The code fails closed and T1 pins it. No exposure; this is a docs-precision item for whoever owns A5.
- **api-consistency-reviewer**: Claim 19. A direct caller passing `IMPORT_LEFT=inf` or `nan` gets no print bound, and `1e3`/`0x…` read as numbers, unlike the comment's "leading digits" gloss. Not reachable from either walk (both pass `$((…))`). Informational.
- **test-strategy**: Claim 31. At HEAD the many-token test runs 2.3-3.5 s here against `timeout 20`, so a host or CI runner about 6x slower would flake. The xtrace test is the host-independent pin for the deep case, but nothing host-independent pins D1 (`${x@a}`'s linear cost). Also, Claim 6's differential fuzz (12,000 random-order calls, 0 unintended differences; 62 differences against 2fbd929b) could become a kept property test if wanted.
- **code-review orchestrator (rubric)**: Claim 2. Iteration 3's D2 author note gives a reason that does not hold for a PATH-level guard. History doc; a correction note in the rubric or log would close it.
- **performance-reviewer**: none new. Row 458's D³ mechanism holds, and at D ≤ 1000 the measured growth is 3.8-5.7x per doubling (Claim 8).

## Goal-Alignment Note

The branch's goal is a checkout phase that only appends, behind one admission check, plus the carried items (capped reader, walk-wide work bound, ancestor memo, the `.git` rule, N1). The code matches that.

4b7f2357's two fixes check out. The PATH guard closes the second-caller fail-open without changing any return code main_imports can observe (a 12,000-call differential fuzz against 21b35ebf found only the intended 1 at a link or gitlink PATH). `${x[0]@a}` gives the same type answer as `${x@a}` in O(1).

Each new test fails on the mutant or old lib it targets and passes at 22- and 73-character TMPDIRs. Nothing found here blocks landing. The open items are four documentation-precision points and one rubric note, all fail-closed or history.
