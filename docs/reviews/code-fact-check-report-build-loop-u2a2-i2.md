Commit: 7f295cdb

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a2 (branch feat/build-loop-u2a2)
**Scope:** fix range `git diff 39ed1d53..7f295cdb`: commit 7f295cdb (scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md, docs/reviews/override-log.md, and its commit message), plus the iteration-1 rubric's A1-A7 statuses. c3e24e96 (review docs) and the rest of the branch are context only; they were fact-checked at 39ed1d53 (`docs/reviews/code-fact-check-report-build-loop-u2a2.md`).
**Commit:** 7f295cdb
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-06
**Total claims checked:** 22
**Summary:** 18 verified, 0 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Execution provenance. Repo commands ran with cwd `/workspace/.claude/wt-build-loop-u2a2`. Mutants and probes ran in `git archive HEAD` copies under `/tmp/u2a2-fc2-BbNG/` (shared2.md forbids repo writes beyond this report, so the skill's `docs/reviews/execution-logs/` was not used). Captured output is in `/tmp/u2a2-fc2-BbNG/logs/`. Versions: bash 5.2.15, git 2.39.5.

- **E1** (2026-10-06T18:59:17Z): `TMPDIR=$(mktemp -d /tmp/u2a2-x-XXXX) bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/scripts/build-loop-read.bats test/fixture-hermeticity.bats` exited 0 with 107 `ok` and 0 `not ok`; build-loop-check.bats ran 9. Log: `logs/tests.txt`.
- **E2** (about 19:00Z): build-loop-check.bats in an archive copy (`/tmp/u2a2-fc2-BbNG/old`) with the lib swapped for `git show 39ed1d53:scripts/lib/dev-cycle-read.sh` exited 1. Tests 1-7 ok, tests 8 and 9 `not ok`. Log: `logs/old-lib.txt`.
- **E3** (about 19:01Z): `mut.sh NAME OLD NEW` makes an archive copy, applies one exact string replacement to the lib, then runs `bats -f 'iteration 1' test/scripts/build-loop-check.bats`. Results:
  - `nul2` (`[[ "$i" -ne 0 ]]` replaced by `false`) exits 1: test 8 fails.
  - `cosym` (the checkout `-e`/`-L` branch replaced by `continue`) exits 1: test 8 fails.
  - `dir` (the directory branch removed) exits 1: test 8 fails.
  - `untr2` (`{ untracked_md || :; }; printf rc=0`) exits 1: test 9 fails.
  - `lstree2` (the same mutation applied to ls-tree) exits 1: test 9 fails.
  - Three mutants were not real mutants and are listed only so nothing is hidden. `nul` (`-ne 99`) still fails closed. `untr` and `lstree` (`cmd; printf rc=0`) behave the same as the fix under errexit. All three exit 0.
  - Logs: `logs/mut-*.txt`.
- **E4** (19:02:22Z): `bats test/scripts/probe.bats` in the archive copy `/tmp/u2a2-fc2-BbNG/probe` (source `/tmp/u2a2-fc2-BbNG/probe.bats`; P1-P10, each with the test file's `imps` harness) exited 0. Log: `logs/probes.txt`.
- **E5**: inline bash probes.
  - The errexit probe on `mapfile < <(false; printf rc=0)` ran plainly and inside a function called under `if`. Both gave `r=()`. The `&& printf rc=0 || printf rc=1` form gave `r=([0]="rc=1")`.
  - The duplicate-entry probe (`dup-*/`): `git cat-file -p main:a.md` printed `first`, while `git reset --hard` and `read-tree` plus `checkout-index` both wrote `second`.
  - The old lib on a missing tree object, called under `if`, exited 1 with `line 530: recs: bad array subscript` (`logs/oldlib-lstree.txt`).
  - pr-prep 1a's numstat count.
  - Every process ran under `timeout` and has exited.

---

## Claim 1: Header comment: "a doubled name, a name holding a newline ..., symlink text that is empty, absolute or holds a newline or a NUL, and a checkout path it would read that is a symlink or lies under one fail the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:459-463`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape making `main_imports` return 1. It does not establish that this list is exhaustive: fifos and plain directories under a symlinked parent fail too (Claim 5), and some symlinked-directory shapes pass silently (Claim 2b).

Each shape has a return-1 path in `main_imports`:

- Doubled name and newline name: `[[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1` (`scripts/lib/dev-cycle-read.sh:539`).
- Link text that is empty, holds a newline, or is absolute: `if [[ -z "$out" || "$out" == *$'\n'* || "$out" == /* ]]; then IMPORTED_MAIN=error; return 1; fi` (`:574`).
- NUL in link text: `:570-571`, covered in Claim 7.
- Checkout symlink: `elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1` (`:563`).

Every shape passed its test in E1 (tests 3, 5 and 8). P7c, a dangling symlink at a checkout target, answered `walk: failed` (E4).

**Evidence:** `scripts/lib/dev-cycle-read.sh:527-588`, `test/scripts/build-loop-check.bats:162-185`, `logs/tests.txt`, `logs/probes.txt`

---

## Claim 2a: Header comment drops "a symlinked untracked start file" from Not covered (it now fails the walk)

**Location:** `scripts/lib/dev-cycle-read.sh:463-466`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an untracked start file that is itself a symlink. It does not establish anything for start files under an untracked symlinked directory, which are never listed (Claim 2b).

Untracked starts are queued as `t:`. A symlink fails `inrepo_here`, because `rawfile` compares `realpath -e` with `$ROOT_REAL/$1` (`:98`). It then reaches the `-L` branch at `:563`. The test makes `ln -s docs/rules.md CLAUDE.local.md` and then runs `imps main docs/x.md; want walk failed` (`test/scripts/build-loop-check.bats:173-174`). That test passed (E1), and the `cosym` mutant fails it (E3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:98,125,560-564`, `test/scripts/build-loop-check.bats:173-174`, `logs/mut-cosym.txt`

---

## Claim 2b: Header comment, "Not covered (known issue A5): a path through a directory main stores as a symlink when the checkout does not have that link, other names ... on a case-insensitive checkout, and absolute imports" (the old item "a path through a symlinked directory" is narrowed to this)

**Location:** `scripts/lib/dev-cycle-read.sh:463-466`
**Type:** Behavioral
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start discovery under a symlinked directory that is present in the checkout. It does not establish that Claude Code loads through such directories in the version used (see Claim 22). It does not re-open the symlinked-directory gap that the 2026-10-06 `feat/build-loop-u2a` override row settled. The finding is that the new list leaves that gap out.

7f295cdb fails the walk only for an import path that passes through a symlinked directory. Start files under a symlinked directory are still never found, and the walk answers `ok`. That shape is not in the narrowed list.

Start candidates come only from `.md` names that `ls-tree -r` lists (`[[ "$f" != *.[mM][dD] ]] || cand+=("m:$f")`, `:541`) or that `untracked_md` lists (`:544-547`). A directory that main stores as a symlink appears as a single `120000` entry. Its contents are never listed.

- **P2 (E4).** Main stores `.claude/rules` as a symlink to `real-rules/`, and the link is present in the checkout. `ls-tree` shows `120000 blob ... .claude/rules`. `real-rules/x.md` holds `r @docs/s.md`. Output: `walk: ok`, `docs/s.md: -`.
- **P3 (E4).** An untracked symlink `lnk` points outside the repo at a directory that holds `AGENTS.md` with `x @../docs/s.md`. `git ls-files --others` prints only `lnk`. Output: `walk: ok`, `docs/s.md: -`.

The pre-fix list named "a path through a symlinked directory", which covered both shapes. The new wording leaves only the case where the checkout lacks the link. That case is not fail-open: nothing exists there to load (P7, Claim 5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:536-554`, `logs/probes.txt` (P2, P3), `docs/reviews/override-log.md:350`

---

## Claim 3: main_imports comment, which lists every return-1 case: main not found by name, tree or untracked list not listable whole, a record that does not parse, a doubled name, a newline name, an unreadable blob, bad link text, and a non-plain checkout path

**Location:** `scripts/lib/dev-cycle-read.sh:516-521`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the correspondence between the listed cases and the `return 1` sites. It does not establish that every unmodelled shape returns 1. Some paths `continue` silently: an unreadable checkout plain file (P4), `*) continue` for gitlinks, and start files under symlinked directories (Claim 2b).

I read the whole function (`:527-588`). The `return 1` sites are:

- `main_by_name || return 1` (`:533`)
- the two listing guards (`:535`, `:545`)
- the record regex (`:538`)
- the duplicate or newline name guard (`:539`)
- the untracked newline guard (`:547`)
- the `100644|100755` read with `|| { IMPORTED_MAIN=error; return 1; }` (`:566`)
- the NUL/read guard (`:570-571`)
- the link-text guard (`:574`)
- the checkout branch (`:563`)
- the cached-error return (`:530`), which is implied by "with IMPORTED_MAIN set to error"

`need_root` exits rather than returns (`:94-96`), as the header says.

Silent continue on an unreadable plain checkout file: `out="$(import_targets "$d" < "$f")"` (`:561`). Under `if main_imports`, the redirect failure only empties `out`. P4 gave `walk: ok`, `docs/s.md: -`, and stderr `line 561: AGENTS.local.md: Permission denied`. Claude Code running as the same uid cannot read that file either, so nothing it would load is missed. In a plain call, errexit would end the shell there instead.

**Evidence:** `scripts/lib/dev-cycle-read.sh:527-588`, `logs/probes.txt` (P4), `logs/tests.txt`

---

## Claim 4: "git's lookups read the first copy, a checkout keeps the last"

**Location:** `scripts/lib/dev-cycle-read.sh:518-519`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `cat-file main:PATH`, `reset --hard`, and `read-tree` plus `checkout-index` on git 2.39.5, with two blobs under one name. It does not establish behaviour on other git versions or for mixed-mode duplicates.

The tree held `a.md` twice (blobs `first` and `second`). `git cat-file -p main:a.md` printed `first`. After `git reset --hard main`, `a.md` held `second`, and `ls-files -s` listed only `e019be00` (`second`). `read-tree main` plus `checkout-index -a -f` gave the same result (E5).

**Evidence:** `/tmp/u2a2-fc2-BbNG/dup-*/`, E5

---

## Claim 5: "a checkout path it would read exists but is not a plain file (a symlink, or under one) or a plain directory" fails the walk

**Location:** `scripts/lib/dev-cycle-read.sh:520-521`, implemented at `:560-564`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers symlinks, dangling symlinks, fifos, a plain directory under a symlinked parent, and a hard link (which is plain and is read). It does not establish anything for an unreadable plain file, which continues silently (Claim 3). An absent path under a symlinked parent continues, but it is still recorded as imported.

```bash
# scripts/lib/dev-cycle-read.sh:560-564
    if [[ "$src" == t ]]; then
      if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")"
      elif [[ -d "$f" && ! -L "$f" && -z "$(blocker "$f" dir)" ]]; then continue  # a directory: nothing loads
      elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1
      else continue; fi
```

E4 results:

| Probe | Shape | Result |
|---|---|---|
| P5 | fifo | `walk: failed` |
| P6 | `lnk/sub`, a plain directory under the symlink `lnk` | `walk: failed` (`blocker` returns `lnk/`) |
| P7c | dangling link | `walk: failed` |
| P9 | hard link | `walk: ok`, read as plain |
| P7, P7b | absent path under a live or dangling directory link | `walk: ok`, with `lnk/none.md: imported` |

P7 and P7b are not fail-open. The token is added to `IMPORTED_MAIN` before the queue decision (`:581`), and no file exists for Claude Code to load.

**Evidence:** `scripts/lib/dev-cycle-read.sh:109-125,560-587`, `logs/probes.txt`

---

## Claim 6: "each followed by "rc=0" only when its command succeeded (the && and || keep errexit from ending the substitution early)"

**Location:** `scripts/lib/dev-cycle-read.sh:522-524`; code `:534-535`, `:544-545`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `set -euo pipefail` callers, under `if` and in a plain call, on bash 5.2.15. It does not establish that the added `${#recs[@]} -gt 0` guard is reachable. It cannot be in practice, because the substitution always ends with `rc=0` or `rc=1` unless `printf` itself fails or the subshell is killed. It is defensive only, and the comment makes no claim about it.

Errexit is inherited into `< <(...)` both plainly and inside a function called under `if`: `(false; printf rc=0)` gave `r=()` in both cases. `false && printf rc=0 || printf rc=1` gave `r=([0]="rc=1")` (E5).

At 7f295cdb:

- Test 9 (`if main_imports`) passes with status 0 and `walk failed` for both listings (E1).
- P1, a plain call under `set -e`, exits 1 with no `bad array subscript` and no `after` line.
- `main_imports || echo` printed `rc=1 IMPORTED_MAIN=error` (E4).

**Evidence:** `scripts/lib/dev-cycle-read.sh:528-547`, `logs/probes.txt` (P1), `logs/tests.txt`

---

## Claim 7: "$(...) drops NULs, so they are counted first; the x keeps trailing newlines, which $(...) would also drop."

**Location:** `scripts/lib/dev-cycle-read.sh:568-572`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers NUL-holding link text, a missing link blob, and stderr cleanliness. It does not establish behaviour if `wc -c` padded its output, as BSD `wc` does. GNU's output works with `-ne`.

```bash
# scripts/lib/dev-cycle-read.sh:570-572
          if ! i="$(git cat-file blob "$MAIN_SHA:$f" | tr -cd '\0' | wc -c)" || [[ "$i" -ne 0 ]] \
             || ! out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"; then IMPORTED_MAIN=error; return 1; fi
          out="${out%x}"
```

- **Pipefail.** It is set locally: `local - ...; set -o pipefail` (`:528`). With a missing link blob (P8), the walk answered `walk: failed`, and stderr held only git's `fatal: git cat-file ...: bad file`.
- **No NULs reach `$(...)`.** `tr -cd '\0'` keeps only NULs, and `wc -c` turns them into digits.
- **No bash warning.** Test 8 asserts `[ -z "$stderr" ]` after the NUL case (`test/scripts/build-loop-check.bats:185`) and passes. Under the `nul2` mutant, the same case prints `warning: command substitution: ignored null byte in input` and the walk answers `ok` (E3).
- **Second guard.** If pipefail were absent, the `&& printf x` guard (A3) would still catch a failed read.

**Evidence:** `scripts/lib/dev-cycle-read.sh:528,567-576`, `logs/mut-nul2.txt`, `logs/probes.txt` (P8)

---

## Claim 8: "a directory: nothing loads"

**Location:** `scripts/lib/dev-cycle-read.sh:562`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a plain directory at an import target with plain parents. It does not establish anything about directories under non-plain parents, which fail the walk (Claim 5).

Test 8 runs `mkdir docs/lt.md` and then `imps main docs/x.md; want walk ok; want docs/x.md -` (`test/scripts/build-loop-check.bats:176-177`). It passes (E1), and the `dir` mutant fails it (E3).

**Evidence:** `test/scripts/build-loop-check.bats:175-177`, `logs/mut-dir.txt`

---

## Claim 9: Known issue A5 row: "odd names, link text, or a checkout symlink the walk would read fail it, but not a path through a directory main stores as a symlink when the checkout lacks that link, other names ... case-insensitive ..., or absolute imports"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** The "fail it" half is verified (Claims 1, 5). The gap list misses start discovery under a symlinked directory present in the checkout (Claim 2b). This verdict does not establish whether that gap should be closed, which is the settled `feat/build-loop-u2a` row's decision.

The row's wording is quoted above. P2 and P3 (E4) both answer `walk: ok` with the imported file shown as `-`. The row no longer names symlinked directories in general, which it did before (`git diff 39ed1d53..7f295cdb -- docs/working/known-issues-dev-cycle.md`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `logs/probes.txt`

---

## Claim 10: Plan F11 "a doubled name, a name holding a newline, empty, absolute, newline or NUL link text, or a checkout symlink it would read fails the walk ... Gaps: known issue A5 (a directory main stores as a symlink that the checkout lacks, case-insensitive names, absolute imports)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Same split as Claim 9. The failing shapes are verified, and the gap list leaves out P2 and P3.

The failing shapes match Claim 1. The gap list has the same omission as Claims 2b and 9 (P2, P3).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `logs/probes.txt`

---

## Claim 11: Plan step 5 bullets: U2a2 "refuses ... a doubled name, a name holding a newline, empty, absolute, newline or NUL symlink text, a checkout symlink it would read ...; a `..x` name is followed ... then split from the floor at 400 lines"; U2a3 "the floor in the lib ... (rows C1, C3, 308)"

**Location:** `docs/working/plan-build-loop-handoff.md:275-276`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shapes refused, the `..x` behaviour, and that U2a2 holds no floor. It does not establish the U2a3 contents, which are future work.

The shapes match Claim 1. Test 5 ("a ..x name is followed") passes (E1). `grep -n '^floor()\|ownfile\|GATE_CODE' scripts/lib/dev-cycle-read.sh` finds no floor in this branch (paraphrased — no quote available because the claim is about absence of code: no matching grep results). The full branch 6c41aea2 was 398 lines, and 20347279 plus the floor was over 400, per the prior report's Claim 21.

**Evidence:** `docs/working/plan-build-loop-handoff.md:275-276`, `test/scripts/build-loop-check.bats` test 5

---

## Claim 12: Commit 7f295cdb: "Tests: build-loop-check.bats 9 ... 107 across the five suites."

**Location:** commit 7f295cdb message, Tests paragraph
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at 7f295cdb in this sandbox. It does not establish them under another TMPDIR layout (shared2.md notes that test 25 depends on it).

E1 gave 107 `ok` and 0 `not ok`, of which 9 were in build-loop-check.bats.

**Evidence:** `logs/tests.txt`

---

## Claim 13: "Both fail against 39ed1d53's lib"

**Location:** commit 7f295cdb message, Tests paragraph
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each test failing as a whole. Test 8 fails at its first segment (`:169`, the directory symlink), so this does not by itself show that the NUL segment fails on the old lib. E3's `nul2` mutant shows that.

E2 gave `not ok 8` at `want walk failed` (`walk: ok`, `docs/rules.md: -`) and `not ok 9` at the `[ "$status" -eq 0 ]` check. The old lib called under `if` exits 1 with `recs: bad array subscript` (E5).

**Evidence:** `logs/old-lib.txt`, `logs/oldlib-lstree.txt`

---

## Claim 14: "mutants of the NUL count, the checkout-symlink branch and the directory branch each fail"

**Location:** commit 7f295cdb message, Tests paragraph
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named mutants. I also killed the two listing mutants (`untr2`, `lstree2`). This does not establish which mutant forms the author used.

`nul2`, `cosym` and `dir` each turn test 8 `not ok` (E3).

**Evidence:** `logs/mut-nul2.txt`, `logs/mut-cosym.txt`, `logs/mut-dir.txt`

---

## Claim 15: "396 changed code lines against main."

**Location:** commit 7f295cdb message
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pr-prep 1a's count, `main...7f295cdb` excluding `docs/`. It does not establish the count at any later HEAD.

`git diff --numstat main...7f295cdb` outside `docs/` sums to 362 + 34 = 396. The same count at 39ed1d53 is 347, which matches the rubric.

**Evidence:** `workflows/pr-prep.md:86-91`, E5

---

## Claim 16: Corrected d8003fbf facts: "the backup branch holds 6c41aea2 (53a6912b rebased); R4 (the ..x name) was fixed by following it; only the tree walk calls instruction_names."

**Location:** commit 7f295cdb message, A6/A7 bullet
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers branch containment, parentage and the call sites. It does not establish that the rebase was conflict-free; the patch-ids differ.

- `git log feat/build-loop-u2a2-full` shows the tip is 6c41aea2, with parent 20347279.
- 53a6912b has the same subject and author date, with parent 6f624cdf, and is on no branch.
- R4 is U2a rubric row 64 ("never followed"). Test 5 now follows `..x`.
- `instruction_names` is called only at `done < <({ git ls-files -z; untracked_md; } | instruction_names)` (`scripts/lib/dev-cycle-read.sh:506`), inside `imported_names`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:494,506`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:64`

---

## Claim 17: "errexit used to end the process substitution before its printf, and `${recs[-1]}` then stopped the caller (bad array subscript)"

**Location:** commit 7f295cdb message, A2 bullet
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ls-tree failure on the old lib under `if`. It does not establish the untracked-list failure on the old lib separately; that is the same code shape.

E5 gave `dev-cycle-read.sh: line 530: recs: bad array subscript` with rc 1 under `if main_imports`.

**Evidence:** `logs/oldlib-lstree.txt`

---

## Claim 18: "This also covers a path through a directory main stores as a symlink when the checkout has that link, and a symlinked untracked start file, so known issue A5 shrinks."

**Location:** commit 7f295cdb message, A1 bullet
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers import paths through such a directory, and symlinked start files. It does not establish start discovery under such a directory, which is still missed (Claim 2b). The "shrinks" claim is right; the shrunk list is what is wrong (Claims 2b, 9, 10).

Test 8's first segment fails the walk for `@docs-link/x.md` when `docs-link` is a tracked symlink, and the positive control after `git rm docs-link` answers `ok` (`test/scripts/build-loop-check.bats:167-171`). For the start file, see Claim 2a.

**Evidence:** `test/scripts/build-loop-check.bats:162-174`, `logs/tests.txt`

---

## Claim 19: Test 8's name and comments, compared with its assertions

**Location:** `test/scripts/build-loop-check.bats:162-186`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each comment against the step under it, and non-vacuity through mutants. It does not rule out a silent fixture failure in an `&&` chain. Bats' errexit does not stop on a non-final link: if `mkdir docs/lt.md` at `:176` failed, the directory segment would pass. This is the same family as the deferred `feat/build-loop-u1d` row on fixture chains.

Each comment matches its step:

- "A tracked directory symlink, present in the checkout, that an import passes through" matches `ln -s real docs-link` plus `@docs-link/x.md`.
- "An untracked symlink at a target main lacks" matches `ln -s rules.md docs/lt.md`.
- "symlinked start file" matches `CLAUDE.local.md`.
- "A plain directory" matches `mkdir docs/lt.md`.
- "$(...) would drop it and follow another name": the NUL tree holds no `docs/rules.md`, so `docs/rules.mdzzz` would resolve to an absent checkout path and the walk would answer `ok`. `nul2` shows exactly that (E3).

The `want docs/rules.md imported` lines after a failed walk are the fail-closed answer, not proof that the walk followed anything. The `want walk failed` lines carry the test. Each failure segment is killed by its own mutant (E3).

**Evidence:** `test/scripts/build-loop-check.bats:162-186`, `logs/mut-*.txt`

---

## Claim 20: Test 9's name, "returns, not exits, when main's tree or the untracked list cannot be listed", and its comments

**Location:** `test/scripts/build-loop-check.bats:188-198`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `if main_imports` context the harness uses. The plain call is not under test; P1 shows it exits 1 through errexit, as `return 1` would.

Each half is discriminating. `lstree2` and `untr2` each make test 9 `not ok` (E3), so the corrupt-index half really does exercise the `untracked_md` failure rather than an earlier one. The positive control `want walk ok` precedes both halves.

**Evidence:** `test/scripts/build-loop-check.bats:188-198`, `logs/mut-untr2.txt`, `logs/mut-lstree2.txt`

---

## Claim 21: The two new override rows (feat/build-loop-u2a2)

**Location:** `docs/reviews/override-log.md:353-354`
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the facts each row states. It does not judge whether Accepted-immutable or Won't-Fix is the right disposition.

- Row 353's four facts match Claims 16-17 and the prior report's Claims 21-22.
- Row 354 is accurate. The `feat/build-loop-u2a` row at `:339` cites `:13` and `:25`. At 7f295cdb the header lines are 79 (`:13`), 75 (`:25`), 69 (`:18`) and 70 (`:21`) characters long, so the short lines are `:18` and `:21`. 7f295cdb's first lib hunk starts at `:457`, so these lines did not move after 39ed1d53.

**Evidence:** `docs/reviews/override-log.md:339,353-354`, E5 (awk line lengths)

---

## Claim 22: Rubric A1-A7 statuses (A1-A5 "✅ Fixed", A6 Accepted-immutable, A7 Won't-Fix)

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:18-30`
**Type:** Reference
**Verdict:** Unverifiable
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Each status is verified against the code (A1: Claims 1, 5, 7; A2: 6; A3: 7; A4: 3; A5: 11; A6/A7: 21). The one Unverifiable part is whether A1's "fixed" extends to what Claude Code actually loads. That depends on Claude Code's handling of symlinked `.claude/rules/`. The documentation says such symlinks are supported, but an open issue reports external symlinks not loading. There is no egress to check it from the host.

Every status holds against the code. One note on A3: the `&& printf x` guard is now preceded by the NUL count, which fails first on an unreadable blob (P8). The guard is still correct, but it is shadowed.

**Evidence:** rubric `:18-30`; claims above; Claude Code memory docs (web search, unverified): "The .claude/rules/ directory supports symlinks", and claudeissues.com issue 88405 (symlinked rule files not auto-loaded)

---

## Claims Requiring Attention

### Incorrect
- **Claim 2b** (`scripts/lib/dev-cycle-read.sh:463-466`): the narrowed Not-covered list leaves out start files under a symlinked directory present in the checkout: main's `.claude/rules` stored as a symlink (P2), or an untracked symlinked directory (P3). Both answer `walk: ok` and `-`. Restore "start files under a symlinked directory" to the list, or fail the walk on them.
- **Claim 9** (`docs/working/known-issues-dev-cycle.md:18`): the A5 row has the same omission.
- **Claim 10** (`docs/working/plan-build-loop-handoff.md:126`): F11's gap list has the same omission.

### Unverifiable
- **Claim 22** (rubric): whether Claude Code loads `.claude/rules` through symlinks. It needs a host check with egress or a Claude Code run.

## Escalations

- **E1 (Claims 2b, 9, 10, doc-accuracy, Medium).** 7f295cdb narrowed "a path through a symlinked directory" to "a directory main stores as a symlink when the checkout does not have that link". The walk still misses starts under a symlinked directory (P2: a symlinked `.claude/rules` stored on main; P3: an untracked symlinked directory). The gap itself falls under the settled 2026-10-06 `feat/build-loop-u2a` override row ("misses paths through a symlinked directory"), and its revisit trigger has not fired. So this escalation is about the documentation now under-stating that row, not a re-filing of the gap. P2 needs a symlinked `.claude/rules` on main, which a loop branch cannot add before the floor judges it.
- **E2 (Claim 3, informational).** An unreadable plain checkout file makes the walk continue under `if` and prints a bash `Permission denied` on stderr. In a plain call, errexit ends the shell instead. Claude Code (same uid) cannot read the file either, so this is not fail-open, but the behaviour depends on the call context.
- **E3.** The hallucination-pattern log was not updated. No Incorrect verdict is a fabricated symbol, and shared2.md forbids repo writes beyond this report.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7f295cdb` as its first line."
- **Answered:** checks 1-7 from the brief map to these claims:
  1. Claims 3 and 6. The errexit survival was executed under `if` and in a plain call. The empty-array guard is unreachable in practice.
  2. Claim 7.
  3. Claims 5, 3 and 2b. Hard links are read. Fifos, dangling links and plain directories under symlinked parents fail. An absent path under a symlinked parent continues but is recorded as imported, so it is not fail-open. An unreadable file continues silently.
  4. Claims 2a, 2b, 9, 10 and 18.
  5. Claims 12-17.
  6. Claims 19-20.
  7. Claims 21-22.
- **Out of scope:** code quality. Whether the A5 gaps should close is a settled-row decision. c3e24e96 and the rest of the branch are context only.
- **Escalate:** E1.
- **Questions / Decisions:** None. Scratch is `/tmp/u2a2-fc2-BbNG/` (left for inspection). No tracked file was modified except this report.
