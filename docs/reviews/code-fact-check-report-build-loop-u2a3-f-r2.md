Commit: cc1aa864

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`)
**Scope:** `git diff main...HEAD` (main 62d366a7, HEAD cc1aa864): comments in `scripts/lib/dev-cycle-read.sh`, test names and comments in `test/scripts/build-loop-check.bats`, `docs/working/known-issues-dev-cycle.md` A5, `docs/working/plan-build-loop-handoff.md` F11/U2a3/U2b, the 2026-10-06 `feat/build-loop-u2a3` rows of `docs/reviews/override-log.md`, and every commit message on main..HEAD. Role cfcg, pass i3 (final confirming pass), replicate f-r2.
**Checked:** 2026-10-07
**Total claims checked:** 31
**Summary:** 22 verified, 4 mostly accurate, 0 stale, 5 incorrect, 0 unverifiable

Hallucination log `docs/reviews/hallucination-patterns.md` was read. No claim matches a logged pattern, and no Incorrect verdict below is a fabricated symbol or API. Per the shared context, this pass writes only this report, so the log is not edited.

## Execution provenance

All runs used cwd `/workspace/.claude/wt-build-loop-u2a3` unless noted, with TMPDIR set inside the scratch dir `/tmp/u2a3-cfcg-i3-WrT9`. Logs are under `/tmp/u2a3-cfcg-i3-WrT9/logs/`.

- **E1** (2026-10-07T00:27:41Z): `TMPDIR=$S/tmp bats <suite>.bats` for test/scripts/build-loop-check, dev-cycle, build-loop-read, fixture-git-env and test/fixture-hermeticity. Every run exited 0. Counts: 16 + 75 + 19 + 2 + 2 = 114 ok, 0 not ok. Logs: `bats-*.txt`, `E1-summary.txt`.
- **E2**: `git diff --numstat main...<c> -- . ':!docs'` and `git show <c>:test/scripts/build-loop-check.bats | grep -c '^@test'` for each commit. Exit 0. Log: `E2-linecounts.txt`. Results: fbeae280 344 lines / 14 tests, 4f087967 369 / 15, e7b5d7ed 398 / 16, 2a3e499f 400 / 16, c42f017f 400 / 16, cc1aa864 400 / 16 (HEAD: lib 120+9, build-loop-check.bats 265+2, dev-cycle.bats 2+2).
- **E3** (finished 2026-10-07T00:29:06Z): `$S/mut.sh NAME PERL` applies a perl substitution to a copy of the lib in `$S/m-NAME` (HEAD exported with `git archive`), then runs build-loop-check.bats there. Every mutant made bats exit 1. Results: `herestring` (`done < <(printf ...)` changed to `done <<<"$out"`) → not ok 10. `noparent` (line 614 removed) → not ok 15. `noL` (`&& ! -L "$p"` removed from 600) → not ok 15. `nokeybyname` (MAIN_BY_NAME dropped from the key at 553/554) → not ok 16. `noreset` (`IMPORTED_MAIN=error;` removed from 554) → not ok 16. Logs: `mutant-*.diff`, `mutant-*.txt`.
- **P1** (2026-10-07T00:30:34Z): `LC_ALL=C bash $S/probes1.sh`, which runs in fixture repos under `$S/p/`. Exit 0. Log: `probes1.txt`.
- **P2** (2026-10-07T00:31:28Z): `LC_ALL=C bash $S/probes2.sh`. Exit 0. Log: `probes2.txt`. Its R2 step hit the 30 s timeout (rc 124) on a link text of 33,000 `./` parts, and P3 replaced it.
- **P3** (2026-10-07T00:32:42Z): `LC_ALL=C bash $S/probes3.sh`. Exit 0. Log: `probes3.txt`.
- **E4**: timed `main_imports` three times on this worktree, which has 2966 tree entries on main. Results: rc 0 each time, 0.608-0.696 s. Log: `E4-timing.txt`.

The probe harness `walk` (`$S/probe-lib.sh`) is the bats `imps` helper copied verbatim, and it runs the HEAD lib at `$S/src/scripts/lib/dev-cycle-read.sh`.

---

## Claim 1: override row :365 — "main_imports checks every tree record in bash (mapfile, a regex and a map assignment per entry): 0.4-0.5 s here …"

**Location:** `docs/reviews/override-log.md:365`
**Type:** Performance / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-record mechanism and that the whole walk takes under 0.7 s on this repo. It does not establish the 0.4-0.5 s figure for the record phase alone, the ~2.1 s figure at 30k entries, or the awk prototype's ~5x.
**Legibility-target:** for-orchestrator-synthesis

The records come through `nul_list recs git ls-tree -r -z --full-tree "$MAIN_SHA"`, which uses mapfile. Each record then pays a regex test (`[[ "$rec" =~ ^([01234567]{6})\ … ]]`) and a map store (`ent[$f]="${BASH_REMATCH[1]}"`) (`scripts/lib/dev-cycle-read.sh:556-561`). E4 timed the whole walk at 0.61-0.70 s with 2966 entries, which is consistent with a 0.4-0.5 s record phase. The phase itself was not isolated.

**Evidence:** `scripts/lib/dev-cycle-read.sh:556-563`, `/tmp/u2a3-cfcg-i3-WrT9/logs/E4-timing.txt`

---

## Claim 2: override rows :366 and :373 — a submodule or untracked nested repo's instruction file is not a start ("the walk is ok and its imports answer `-`"), because "`ls-tree -r` does not enter a gitlink (not `*) continue`)"

**Location:** `docs/reviews/override-log.md:366`, `docs/reviews/override-log.md:373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an untracked nested repo (executed) and the gitlink reason (static: the starts come only from `ls-tree -r` records and `untracked_md`). It does not establish what Claude Code loads from either.
**Legibility-target:** for-orchestrator-synthesis

In P1 Q6, `nested/` held its own `.git` and a CLAUDE.md. `git ls-files --others` printed nothing for it, and the result was `walk: ok docs/n.md: -`. The `*) continue` arm (`scripts/lib/dev-cycle-read.sh:604`) is reached only when an import names a gitlink path, so row :373's corrected reason is the right one: the starts are `cand` entries built from tree records and the untracked list (`:562`, `:565`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:556-574`, `scripts/lib/dev-cycle-read.sh:604`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q6)

---

## Claim 3: override rows :367 and :380 — commit messages fbeae280, 4f087967 and 34edec56

**Location:** `docs/reviews/override-log.md:367`, `docs/reviews/override-log.md:380`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the rows exist as Accepted-immutable and that the figures in those three messages hold (E1, E2). It does not re-verdict the messages' prose, which the rows already settle.
**Legibility-target:** for-orchestrator-synthesis

Per the brief, these messages need only a pointer to their rows. Row :367 records fbeae280's B5 test numbering and its Notes line. Row :380 records 4f087967's "resolved" and 34edec56's subject. The figures in those messages still match E2: fbeae280 has 14 tests and 344 lines, and 4f087967 has 15 tests and 369 lines. Its fact (row :367) that an untracked symlinked rules file fails the walk matches the t-arm, which fails on any checkout symlink: `elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1` (`scripts/lib/dev-cycle-read.sh:582`).

**Evidence:** `docs/reviews/override-log.md:367`, `docs/reviews/override-log.md:380`, `/tmp/u2a3-cfcg-i3-WrT9/logs/E2-linecounts.txt`

---

## Claim 4: override row :369 — "`CLAUDE.md -> docs/real.md` holding `@x.md` records docs/x.md, not x.md"

**Location:** `docs/reviews/override-log.md:369`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the walk's base directory for a symlinked start. It does not establish Claude Code's base directory, which the row itself marks as untraced.
**Legibility-target:** for-orchestrator-synthesis

The 120000 arm turns the link text into `out` (`scripts/lib/dev-cycle-read.sh:602`), and the read loop queues it as `m:docs/real.md`. When that item is read, `d="${f%/*}"` is `docs` (`:578`), and `import_targets "$d"` resolves `x.md` to `docs/x.md` (`:586`). Test 4's `real.md` start, a symlink with imports, exercises the same arm.

**Evidence:** `scripts/lib/dev-cycle-read.sh:578`, `scripts/lib/dev-cycle-read.sh:586-603`

---

## Claim 5: override row :370 — "`.claude/commands/*.md` files are not start files … (walk ok, docs/c.md `-`)"

**Location:** `docs/reviews/override-log.md:370`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's start rule. It does not establish whether Claude Code loads command references.
**Legibility-target:** for-orchestrator-synthesis

The start rule is `"${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md` (`scripts/lib/dev-cycle-read.sh:571`). P1 Q8 printed `walk: ok docs/c.md: -`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:571`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q8)

---

## Claim 6: override row :371 and A5 — "An `@ld/../q.md` token with `ld` a directory link is recorded as q.md … even with the link in the checkout"; "the walk is lexical, as Node's path.resolve"

**Location:** `docs/reviews/override-log.md:371`, `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's token resolution and Node's `path.resolve`. It does not establish how Claude Code itself resolves `@` paths.
**Legibility-target:** for-orchestrator-synthesis

`import_targets` resolves tokens with `realpath -ms` (`scripts/lib/dev-cycle-read.sh:503`), which is lexical. In P1 Q9, with ld present on main and in the checkout, the result was `walk: ok q.md: imported deep/q.md: -`. In P2 R6, `node -e 'console.log(require("path").resolve("/r/ld/../q.md"))'` printed `/r/q.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:503`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q9), `/tmp/u2a3-cfcg-i3-WrT9/logs/probes2.txt` (R6)

---

## Claim 7: override row :374 — "Every failure path sets IMPORTED_MAIN=error before returning; the known unguarded command (lower) is fixed in U2a3b"

**Location:** `docs/reviews/override-log.md:374`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` in main_imports and the commands whose failure the walk does not see. It does not establish U2a3b's fix, which is outside this review.
**Legibility-target:** for-orchestrator-synthesis

Every `return 1` before `:575` follows `IMPORTED_MAIN=error` at `:554`, and every later one sets `IMPORTED_MAIN=error;` inline (`:580`, `:582`, `:586`, `:591`, `:593`, `:598`, `:603`, `:614`). The function's final status is that of the outer `while`, which is 0 on the normal path. However, `lower` is not the only unguarded command. `import_targets` reads `< <(env LC_ALL=C grep -aoE "$IMPORT_RE" || true)` (`:508`), and in P2 R3 a `grep` shim exiting 2 gave `walk: ok docs/a.md: -`. That also fails open. The precise version is "the known unguarded commands (lower, and grep in import_targets)". Per the shared context, both are fixed in U2a3b (stacked).

**Evidence:** `scripts/lib/dev-cycle-read.sh:508`, `scripts/lib/dev-cycle-read.sh:552-617`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes2.txt` (R3)

---

## Claim 8: override row :378 — "Each symlink the walk follows costs ~12 ms (two cat-file reads and a realpath per link-text component)"

**Location:** `docs/reviews/override-log.md:378`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the operation count. It does not establish the 12 ms figure.
**Legibility-target:** for-orchestrator-synthesis

Lines `:590-591` run `git cat-file blob` twice. The loop at `:597-601` runs one `realpath -ms` per component, and `:602` runs one more for the whole text.

**Evidence:** `scripts/lib/dev-cycle-read.sh:590-602`

---

## Claim 9: override row :379 — "A name main stores as both a blob and a tree fails the walk closed but prints git's `fatal:` line on stderr"

**Location:** `docs/reviews/override-log.md:379`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers three cases: an import through the name, an import of the name itself, and no import of it. It does not establish what a checkout of such a tree writes.
**Legibility-target:** for-orchestrator-synthesis

The walk fails only when an import reads a path under the name. In P2 R5, with `x` stored as both a blob and a tree:

- `@x/y` printed `fatal: path 'x/y' does not exist in '…'` and then `walk: failed`.
- `@x` gave `walk: ok`, and the import of the blob's content was read.
- No import of `x` gave `walk: ok` with no stderr (also P1 Q11).

`ls-tree -r` lists `x` once (blob) plus `x/y`, so the doubled-name refusal (`:560`) does not fire. The precise version is "an import read through such a name fails the walk closed with git's `fatal:` line".

**Evidence:** `scripts/lib/dev-cycle-read.sh:560`, `scripts/lib/dev-cycle-read.sh:586`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes2.txt` (R5), `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q11)

---

## Claim 10: override rows :372 and :381 — the cache "ignores the checkout"; the key "now includes MAIN_BY_NAME"; "Process substitution (tested under ulimit -f 0, mutant killed) … the return-1 comment lists every cause … including the root and a FIFO (probed); A5 names the tracked-in-checkout start"

**Location:** `docs/reviews/override-log.md:372`, `docs/reviews/override-log.md:381`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cache key, the I2-C4 test and mutant, the root and FIFO causes, and A5's tracked-in-checkout sentence. It does not establish the U2a3b-side rows, and it does not establish that no other here-string remains (Claim 22).
**Legibility-target:** for-orchestrator-synthesis

- **Cache key:** the key is `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:553-554`), with no checkout input.
- **Mutants:** E3 `nokeybyname` and `noreset` each fail test 16, and `herestring` fails test 10.
- **Root and FIFO:** in P1, Q1 (`@.` and `@docs/..`), Q1b (link text `..` from docs/AGENTS.md) and Q2 (a FIFO at a target main lacks) each printed `walk: failed`. The plain control printed `walk: ok`.
- **Tracked-in-checkout start:** in P1 Q7, an instruction file tracked on the checkout's branch but absent from main gave `walk: ok docs/t.md: -`, as A5 states.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-554`, `scripts/lib/dev-cycle-read.sh:580-582`, `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-*.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q1, Q1b, Q2, Q7)

---

## Claim 11: A5 — the not-covered gaps: "start files under a symlinked directory or in a submodule or untracked nested repo (neither `ls-tree -r` nor `ls-files --others` enters one) … an instruction file the checkout tracks but main lacks is not a start: `ls-files --others` skips it"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each gap A5 names. Whether A5's refusal list holds is verdicted in Claims 17-19, and whether the gap list is complete in Claim 20.
**Legibility-target:** for-orchestrator-synthesis

P1 Q6 (nested repo) and Q7 (tracked in the checkout, absent from main) reproduce the stated behaviour. The starts come only from `ls-tree -r` records and `untracked_md`, which is `git ls-files -z --others -- ':(glob,icase)**/*.md'` (`scripts/lib/dev-cycle-read.sh:517`). Neither listing enters a symlinked directory, because a symlink is stored and listed as a leaf (paraphrased — no quote available because the claim is about git's listing behaviour, which Q6 and the code's use of the two listings cover).

**Evidence:** `scripts/lib/dev-cycle-read.sh:517`, `scripts/lib/dev-cycle-read.sh:556-574`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q6, Q7)

---

## Claim 12: plan F11, U2a3 and U2b bullets — what the walk models, refuses and reads from the checkout

**Location:** `docs/working/plan-build-loop-handoff.md:126`, `docs/working/plan-build-loop-handoff.md:276`, `docs/working/plan-build-loop-handoff.md:278`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed starts, the three checkout inputs, the gap list and the rows the bullet says it carries. It does not cover the refusal-list items "an import path main lacks under a directory main stores as a symlink" (Claim 18) and "an unreadable checkout file" (Claim 19), which these bullets copy and which fail in those claims. Nor does it establish the floor itself (U2a4).
**Legibility-target:** for-orchestrator-synthesis

The three checkout reads are all in the code:

- untracked starts: `nul_list recs untracked_md` (`scripts/lib/dev-cycle-read.sh:564`)
- targets main lacks: `queue+=("t:$p")` (`:615`)
- symlink checks: `! -L "$p"` (`:600`) and `inrepo_here`/`blocker` in the t-arm (`:580-582`)

F11's phrase "the checkout's untracked files as starts" means untracked instruction and `.claude/rules` files only (`:571`), which the surrounding text implies. All other refusals were executed in E1 and P1 (Claim 17).

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-615`, `/tmp/u2a3-cfcg-i3-WrT9/logs/bats-build-loop-check.txt`

---

## Claim 13: header — main_imports "also reads the checkout's untracked start files, imported files main lacks and whether a path it would read is a symlink there, which can only add imports or fail it"

**Location:** `scripts/lib/dev-cycle-read.sh:29-34`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one checkout state that turns main's own failure into an ok walk, and the code path that allows it. It does not establish other such states (none others found among the shapes probed in P1-P3).
**Legibility-target:** for-orchestrator-synthesis

An untracked start file can suppress the parent-link refusal. Main's own content fails the walk, but the checkout makes it succeed with fewer imports. The setup in P1 Q3:

- main holds `ld -> deep` and a CLAUDE.md with `@ld/CLAUDE.md`.
- With main's content alone, the walk printed `walk: failed`. The checkout on a branch where ld is a plain directory, with no untracked file, also printed `walk: failed`.
- After adding an untracked `ld/CLAUDE.md` in that checkout, the walk printed `walk: ok deep/CLAUDE.md: - ld/CLAUDE.md: imported docs/z.md: imported`.

So `deep/CLAUDE.md`, which Claude Code reads through main's link after a merge, went from imported (failed walk) to `-`.

The cause is that a start is marked seen before the walk (`seen[${cand[i]:2}]=1`, `:572`). The parent-link check runs only after the seen test:

```bash
# scripts/lib/dev-cycle-read.sh:610-614
      [[ -z "${seen[$p]+set}" ]] || continue
      seen[$p]=1
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); continue; fi
      # Main lacks p: under a directory link main stores (the checkout may lack it), fail.
      for (( c = ${#p}; c > 0; c-- )); do [[ "${p:c:1}" != / || "${ent[${p:0:c}]:-}" != 120000 ]] || { IMPORTED_MAIN=error; return 1; }; done
```

(excerpt ends :614; enclosing read loop continues to :616 and main_imports to :618 — read). Starts are never checked against main's links. Practical exposure is bounded: the paths exposed this way are start-shaped names (an instruction file or `.claude/rules/*.md`) under the link target. The floor names those through other items (F9, and `.claude/` per row :370). But the claim as written is false.

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-574`, `scripts/lib/dev-cycle-read.sh:607-616`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q3)

---

## Claim 14: header — main_imports "needs resolve_main to have found main by name, or it fails"

**Location:** `scripts/lib/dev-cycle-read.sh:33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main_by_name gate and its caching. It does not establish resolve_main's own candidate order.
**Legibility-target:** for-orchestrator-synthesis

`main_by_name || return 1` (`:555`) runs after `IMPORTED_MAIN=error` (`:554`). Test 2's `trunk` case passes in E1 (`walk failed`). Test 16's `MAIN_BY_NAME=""` case answers `y.sh`, and E3 `nokeybyname` shows that the cache key is what makes it walk again.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-555`, `/tmp/u2a3-cfcg-i3-WrT9/logs/bats-build-loop-check.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-nokeybyname.txt`

---

## Claim 15: nul_list — "array NAME gets CMD's NUL-split output, or 1 unless CMD exited 0 (&& || keep errexit off)"; used for main's tree and the untracked list

**Location:** `scripts/lib/dev-cycle-read.sh:518-519`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a failing command, an empty listing, a last item literally `rc=0`, partial output and an errexit caller. It does not establish completeness when the command exits 0 with an incomplete list (Claim 21).
**Legibility-target:** for-orchestrator-synthesis

Results from P2 R4:

| Case | Result |
|---|---|
| `false` | rc 1 |
| empty listing, success | rc 0, 0 items |
| empty listing, failure | rc 1 |
| `x\0rc=0\0`, success | rc 0, items `[x, rc=0]` (the literal item is kept) |
| same output, failure | rc 1 |
| `x\0rc=0` without a NUL, then failure | rc 1 (the last item became `rc=0rc=1`) |
| `nul_list a false` under `set -e` | returned 1, no exit |

One unstated edge: output that succeeds but lacks a trailing NUL (`a\0b`) returns 1, because `b` and `rc=0` merge. That fails closed, and `git ls-tree -z` and `ls-files -z` always end with a NUL. Both call sites are `nul_list recs …` (`:556`, `:564`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:519`, `scripts/lib/dev-cycle-read.sh:556`, `scripts/lib/dev-cycle-read.sh:564`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes2.txt` (R4)

---

## Claim 16: the return-1 comment lists every failure path in main_imports, including "the root itself, a FIFO"; "need_root exits instead"

**Location:** `scripts/lib/dev-cycle-read.sh:538-548`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mapping from every `return 1` in the code to a listed cause, plus root and FIFO executed. It does not establish that each listed cause always fails: Claims 18, 19, 21 and 22 cover the shapes that do not.
**Legibility-target:** for-orchestrator-synthesis

Each `return 1` maps to a listed cause:

| Line | Cause |
|---|---|
| `:553` | cached failure |
| `:555` | main not by name |
| `:556`, `:564` | nul_list |
| `:558` | record parse |
| `:560` | doubled name or newline |
| `:565` | untracked newline |
| `:568` | short lower-cased list |
| `:580` | checkout read |
| `:582` | not a plain file or directory |
| `:586` | blob read |
| `:590-591` | NUL count or blob read |
| `:593` | empty, newline or absolute text |
| `:598` | `..` after a symlink |
| `:603` | text leaving the repo |
| `:614` | parent link |

`need_root` (`:552`) exits. The root and a FIFO reach `:582` because `inrepo_here` and the plain-directory test are both false while `-e` is true. P1 Q1, Q1b and Q2 each printed `walk: failed`. This confirms cc1aa864's reason for declining the fix-drift finding: no dedicated check exists, and the generic arm covers both.

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-618`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q1, Q1b, Q2)

---

## Claim 17: block comment — the refusal list (a doubled name, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink, a checkout path it would read that is a symlink or lies under one) "fail the walk, so isimported main answers imported for every path"

**Location:** `scripts/lib/dev-cycle-read.sh:459-465`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed shapes at the sizes the tests use. It does not cover the two items split out in Claims 18 and 19, or link text past 64 KiB under a failing temp-file write (Claim 22). The list is not exhaustive (it omits the root and a FIFO, which the return-1 comment names), but it does not claim to be.
**Legibility-target:** for-orchestrator-synthesis

Each shape fails a test that passes in E1:

| Shape | Test |
|---|---|
| doubled name | 3 |
| newline in a tree name | 3 |
| newline in an untracked name | 5 |
| newline, absolute, empty and escaping link text | 5 |
| empty text below the top level | 12 |
| NUL in link text | 7 |
| `..` after a link on main and in the checkout only | 15 |
| checkout symlink, dangling link, and directory under a link | 7, 12 |

E3 `noL` fails test 15. Test 6 checks that `isimported main` answers imported under `if` after a failed walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-603`, `/tmp/u2a3-cfcg-i3-WrT9/logs/bats-build-loop-check.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-noL.txt`

---

## Claim 18: "an import path main lacks under a directory main stores as a symlink … fail[s] the walk" (block comment; return-1 comment; A5; F11; U2a3 bullet)

**Location:** `scripts/lib/dev-cycle-read.sh:462-463`, `scripts/lib/dev-cycle-read.sh:545-546`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`, `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers import paths that are also untracked start files in the checkout. For paths first reached as imports or link text, the refusal holds (test 15, E3 `noparent`).
**Legibility-target:** for-orchestrator-synthesis

This is the P1 Q3 case from Claim 13. Main imports `ld/CLAUDE.md` with `ld -> deep` on main, and the walk answers `walk: ok`, because the path is an untracked start already in `seen`. The `continue` at `:610` skips the loop at `:614`. The refusal needs to cover paths first seen as starts. A fix would apply the parent check to every path main lacks, including t: starts, before the seen test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:572`, `scripts/lib/dev-cycle-read.sh:610-614`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q3), `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-noparent.txt`

---

## Claim 19a: "a checkout file it cannot read" fails the walk — the file's own permissions

**Location:** `scripts/lib/dev-cycle-read.sh:463`, `scripts/lib/dev-cycle-read.sh:543`, `docs/working/known-issues-dev-cycle.md:18`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a plain checkout file with mode 000, run as a non-root user (`node`). It does not cover unreadability that comes from a parent directory (Claim 19b).
**Legibility-target:** for-orchestrator-synthesis

`out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }` (`:580`). In P1 Q4 ("file itself 000"), the run printed `line 580: sec/x.md: Permission denied walk: failed`. Test 7's `chmod 000` case passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:580`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q4)

---

## Claim 19b: "a checkout file it cannot read" fails the walk — a file under an unsearchable directory

**Location:** `scripts/lib/dev-cycle-read.sh:463`, `scripts/lib/dev-cycle-read.sh:543`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a target main lacks that lies under a checkout directory with mode 000. It does not establish exposure: Claude Code running as the same user cannot read the file either.
**Legibility-target:** for-orchestrator-synthesis

When the parent directory is unsearchable, the t-arm's tests all report false, so the path reads as absent and the walk continues:

```bash
# scripts/lib/dev-cycle-read.sh:580-583
      if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }
      elif [[ -d "$f" && ! -L "$f" && -z "$(blocker "$f" dir)" ]]; then continue  # a directory: nothing loads
      elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1
      else continue; fi
```

In P1 Q4, CLAUDE.md imports `sec/x.md`, which main lacks, and the checkout's `sec/x.md` imports `docs/y.md`. With `sec` readable: `walk: ok docs/y.md: imported`. After `chmod 000 sec`: `walk: ok docs/y.md: -`. `-f`, `-e` and `-L` all fail with EACCES, so the `else continue` arm treats the file as absent and its imports are dropped.

**Evidence:** `scripts/lib/dev-cycle-read.sh:580-583`, `scripts/lib/dev-cycle-read.sh:111-121`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q4)

---

## Claim 20: "A start file answers imported only when an import reaches it"

**Location:** `scripts/lib/dev-cycle-read.sh:465-466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers IMPORTED_MAIN's only append site. "Import" includes a symlink's text (the 120000 arm feeds the target through the same loop), so a start that another start's link names answers imported. Floor semantics are U2a4's and are not covered.
**Legibility-target:** for-orchestrator-synthesis

The only append is `IMPORTED_MAIN+="$(lower "$p")"$'\n'` inside the import loop (`:609`). The start loop (`:569-574`) only sets `seen` and `queue`. Test 1 asserts `CLAUDE.md -`, and it passes in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-575`, `scripts/lib/dev-cycle-read.sh:607-616`, `/tmp/u2a3-cfcg-i3-WrT9/logs/bats-build-loop-check.txt`

---

## Claim 21: "Not covered (known issue A5): …" list, read as the walk's complete set of gaps, and the return-1 cause "the untracked list cannot be listed whole (nul_list)"

**Location:** `scripts/lib/dev-cycle-read.sh:467-471`, `scripts/lib/dev-cycle-read.sh:540`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed gap (true) and the fail-open shapes that are not listed. It does not establish any Claude Code behaviour.
**Legibility-target:** for-orchestrator-synthesis

Every listed gap is real (Claims 2, 5, 6 and 11). The list omits these fail-open shapes:

- the untracked-start bypass of the parent-link refusal (Claim 18)
- a target under an unsearchable checkout directory (Claim 19b)
- link text past 64 KiB when a temp file cannot be written (Claim 22)
- a failing `lower` or `grep`, fixed in U2a3b (Claim 7)

Separately, "listed whole" relies on git's exit status. In P1 Q5, with `pkg/` at mode 000 holding an untracked `pkg/CLAUDE.md`, `git ls-files --others` exited 0 and printed `warning: could not open directory 'pkg/': Permission denied`. The walk then gave `walk: ok docs/p.md: -`. The untracked list can therefore be incomplete without `nul_list` returning 1. Exposure is minimal: the same user's Claude Code cannot read that start either, and untracked starts only ever add imports.

**Evidence:** `scripts/lib/dev-cycle-read.sh:467-471`, `scripts/lib/dev-cycle-read.sh:517-519`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q5)

---

## Claim 22: I2-C4 — the import-list here-string was the walk's path to a temp file; "the process substitution reads a >64 KiB list under `ulimit -f 0`"

**Location:** `scripts/lib/dev-cycle-read.sh:616`, `scripts/lib/dev-cycle-read.sh:596`, `docs/reviews/override-log.md:381`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The process-substitution half is Verified (test 10, E3 `herestring`, P3 X1 "real"). The part that is Incorrect is "the here-string was the only path to a temp file", for link text past 64 KiB. This does not establish reachability: Linux cannot create a symlink whose text is that long (P3 X2, `ln: failed …`), so Claude Code never follows one.
**Legibility-target:** for-orchestrator-synthesis

`done < <(printf '%s\n' "$out")` (`:616`) read a 66,893-byte list under `ulimit -f 0`: test 10 passes, and P3 X1 printed `walk: ok docs/last.md: imported`. A second here-string remains in the link-text step: `lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"` (`:596`). In P3 X2, main stored AGENTS.md as a link whose text is a 70,000-byte component followed by `/../ld/../evil.md`, with `ld -> deep/inner`.

| Run | Result |
|---|---|
| No limit | `walk: failed` |
| `trap "" XFSZ; ulimit -f 0` | `line 596: cannot create temp file for here-document: File too large walk: ok deep/secret.md: - evil.md: imported` |

In the second run, `parts` stayed empty and the `..` check never ran. Under the default SIGXFSZ disposition the shell is killed instead (exit 153, P3 X1 mutant run), which is a crash, not an ok answer.

**Evidence:** `scripts/lib/dev-cycle-read.sh:596-603`, `scripts/lib/dev-cycle-read.sh:616`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes3.txt` (X1, X2), `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-herestring.txt`

---

## Claim 23: the link-text component loop and the parent-symlink loop handle every shape (a first component that is a link, a deeper one, `.`, `//`, a trailing `/`, text that is exactly `..`, a final component that is a symlink) with no wrong refusal and no read outside the repo beyond lstat

**Location:** `scripts/lib/dev-cycle-read.sh:594-603`, `scripts/lib/dev-cycle-read.sh:613-614`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the shapes listed. Exceptions are in Claim 18 (starts bypass `:614`) and Claim 22 (oversized text). "No wrong refusal" holds only in the documented over-refusing sense: any `..` after any earlier link fails, even where the kernel would agree with the lexical result, and so does `ld/..` with `ld` a file link (kernel ENOTDIR).
**Legibility-target:** for-orchestrator-synthesis

Results from P1 Q10 and Q1b:

| Link text | Result |
|---|---|
| `./docs//a.md/` | `walk: ok docs/z.md: imported` (`read -ra` with `IFS=/` drops the trailing empty field; an empty `//` component leaves `p` unchanged) |
| `./docs//a.md` | `ok` |
| `docs/./a.md` | `ok` |
| `CLAUDE.md -> ld -> docs/a.md` (final component a link) | `ok`, with docs/z.md imported (followed as `m:ld`) |
| `ld/../docs/a.md` | `failed` |
| `..` from docs/AGENTS.md | `failed` (it names the root, `:582`) |

Test 15 covers a first-component link on main and a link that only the checkout has.

The loop touches the filesystem only through `-L "$p"` (`:600`), which is an lstat, including for `..`-prefixed `p` outside the root. `realpath -ms` (`:599`, `:602`) does not touch the filesystem. The parent loop (`:614`) reads only the in-memory `ent`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:594-603`, `scripts/lib/dev-cycle-read.sh:614`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q1b, Q10)

---

## Claim 24: cache sentence — "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again"

**Location:** `scripts/lib/dev-cycle-read.sh:472-475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key, the reset and the cached-failure answer. During a walk, IMPORTED_MAIN is `$'\n'` from `:575` onward; that window is settled in row :374. Behaviour when a caller changes ROOT_REAL without cd is need_root's concern, not this claim's.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` and `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:553-554`). Test 16 passes. E3 `nokeybyname` and `noreset` each fail it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-554`, `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-nokeybyname.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-noreset.txt`

---

## Claim 25: isimported's comment — "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; … the walk exits through need_root and caches its result"

**Location:** `scripts/lib/dev-cycle-read.sh:619-623`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main, tree and unknown-name arms. It does not establish behaviour when `lower "$2"` fails (fixed in U2a3b).
**Legibility-target:** for-orchestrator-synthesis

The code is `main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;` and `*) return 0 ;;` (`:629-631`). Tests 2 (bogus name), 6 and 13 pass in E1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:624-633`, `/tmp/u2a3-cfcg-i3-WrT9/logs/bats-build-loop-check.txt`

---

## Claim 26: test names and comments in build-loop-check.bats assert what they say

**Location:** `test/scripts/build-loop-check.bats:46-308`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 14 main-walk tests read in full and the five mutants E3 ran. It does not establish that every sub-case in a test is mutant-pinned: only the five mutants were run.
**Legibility-target:** for-orchestrator-synthesis

Every main-walk test asserts `want walk ok|failed` plus per-path answers, so the walk's own result is pinned rather than inferred from imports. A few points I checked:

- Test 7's first case ("A tracked directory symlink, present in the checkout, that an import passes through") fails through the parent-link check (`:614`), not the checkout-symlink check. The comment does not name a mechanism, and the checkout-symlink path is exercised by that test's `docs/lt.md` and `CLAUDE.local.md` cases.
- Test 12's "Empty symlink text in sub/ would name sub/ itself, a plain directory here" is accurate: without the empty-text check the text resolves to `sub`, which main lists as a tree only. The t-arm then sees a plain checkout directory and continues.
- Test 10's comment "An import list past 64 KiB with no room for a temp file is read whole" is confirmed by E3 `herestring` (not ok 10, status 153).

**Evidence:** `test/scripts/build-loop-check.bats:46-308`, `/tmp/u2a3-cfcg-i3-WrT9/logs/bats-build-loop-check.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-*.txt`

---

## Claim 27: commit e7b5d7ed — figures and behaviour

**Location:** commit e7b5d7ed message
**Type:** Configuration / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The figures are Verified: 16 tests, 114 across the five suites, 398 lines, and the four mutants (parent check, checkout -L half, cache key, reset to error) each fail (E1, E2, E3, run at HEAD's tests). The Incorrect part is "which makes the header's 'the checkout can only add imports' true and closes that A5 gap". This verdict does not establish anything about the other prose.
**Legibility-target:** for-orchestrator-synthesis

The header's invariant does not hold: an untracked start under main's link bypasses the new check (Claim 13, P1 Q3). A smaller imprecision: "isimported's comment says start files answer imported only when an import reaches them" — at e7b5d7ed that sentence is in the block comment above `IMPORTED=` (e7b5d7ed's lib `:465-466`), not in isimported's comment (`:622-626` there).

**Evidence:** `/tmp/u2a3-cfcg-i3-WrT9/logs/E2-linecounts.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/E1-summary.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q3), `scripts/lib/dev-cycle-read.sh:465-466`

---

## Claim 28: commit c42f017f — "bash writes a here-string past 64 KiB to a temp file, and a failed write (ulimit -f 0, a full disk) read as no imports, so the walk answered ok without them"; tests 16/114; "400 changed code lines"; "the here-string mutant fails it"

**Location:** commit c42f017f message
**Type:** Error-handling / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism under both SIGXFSZ dispositions, plus the counts and the mutant. It does not cover a full disk, which was not executed. The claim "U2a3b's own fix" was checked only as far as U2a3b's imported_names using process substitution.
**Legibility-target:** for-orchestrator-synthesis

The figures hold (E1, E2), and the mutant is killed (E3 `herestring`).

The mechanism is imprecise for `ulimit -f 0`. Under the default disposition, the mutant's shell is killed by SIGXFSZ (`File size limit exceeded`, rc 153, P3 X1). It does not answer. Only with SIGXFSZ ignored does the write fail softly (`cannot create temp file for here-document: File too large`), and then `isimported main docs/last.md` answered `-` (P3 X1 mutant). In that probe, main_imports itself returned 1, because the failing file was the last one processed and the outer loop's status became the failed redirect's. IMPORTED_MAIN was still not `error`, so isimported read the short list.

The precise version: "a failed write that does not kill the shell (a full disk, or a file-size limit with SIGXFSZ ignored) reads as no imports, and isimported answers from the short list". The commit title's "reads its import list without a here-string" is exact, since the link-text here-string at `:596` is not the import list (Claim 22).

**Evidence:** `/tmp/u2a3-cfcg-i3-WrT9/logs/probes3.txt` (X1), `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-herestring.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/E2-linecounts.txt`

---

## Claim 29: commits 2a3e499f and cc1aa864 — "the not-covered list points to A5's three untraced shapes"; "finding declined: the root and FIFO causes go through the generic not-plain arm, probed"

**Location:** commit 2a3e499f message, commit cc1aa864 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both subjects. It does not establish 2a3e499f's line delta (E2: 2 lines, taking HEAD from 398 to 400).
**Legibility-target:** for-orchestrator-synthesis

`and three shapes A5 lists as untraced against Claude Code (command references, a link's own directory, a token's ..)` (`scripts/lib/dev-cycle-read.sh:470-471`). The root and the FIFO reach `elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1` (`:582`), shown in P1 Q1 and Q2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:470-471`, `scripts/lib/dev-cycle-read.sh:582`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt` (Q1, Q2)

---

## Claim 30: commit 45ad17b0 — "A5 names U2a3 as main_imports' unit"

**Location:** commit 45ad17b0 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers A5's text at HEAD. It does not cover the doc-only commits 277b2fab and cb4ebbc8, whose subjects only name the artifacts they add.
**Legibility-target:** for-orchestrator-synthesis

A5 reads "The gate's walk (`main_imports`, U2a3)" (`docs/working/known-issues-dev-cycle.md:18`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`

---

## Claims Requiring Attention

### Incorrect
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:29-34`): "can only add imports or fail it" is false. An untracked start under a directory main stores as a link turns main's failed walk into `ok` (P1 Q3).
- **Claim 18** (`scripts/lib/dev-cycle-read.sh:462-463`, `:545-546`, A5, F11, U2a3 bullet): the parent-link refusal is skipped for a path already seen as a start (`:610` before `:614`).
- **Claim 19b** (`scripts/lib/dev-cycle-read.sh:463`, `:543`, A5): a checkout file under an unsearchable directory reads as absent, and its imports are dropped with the walk still ok.
- **Claim 22** (`scripts/lib/dev-cycle-read.sh:596`): a second here-string remains. Link text past 64 KiB skips the `..` check when the temp-file write fails softly. This is unreachable as a real checkout symlink.
- **Claim 27** (commit e7b5d7ed): "makes the header's … true and closes that A5 gap" (see Claim 13). The commit message is immutable, so this needs an override row.

### Mostly Accurate
- **Claim 7** (`docs/reviews/override-log.md:374`): grep in import_targets is a second unguarded command (fixed in U2a3b).
- **Claim 9** (`docs/reviews/override-log.md:379`): a blob/tree name fails the walk only when an import reads through it.
- **Claim 21** (`scripts/lib/dev-cycle-read.sh:467-471`, `:540`): the gap list omits Claims 18, 19b and 22. git exits 0 when it cannot open a directory, so "listed whole" is not checked for that case.
- **Claim 28** (commit c42f017f): under `ulimit -f 0` with the default SIGXFSZ the shell is killed rather than reading empty.

## Escalations

- `scripts/lib/dev-cycle-read.sh:610-614` (with `:572`) — addressee: implementer / orchestrator. Claims 13, 18 and 27: the parent-link refusal does not cover untracked starts. Either run the `:614` check for every path main lacks, starts included, or narrow the header (`:29-34`), the block and return-1 comments, A5, F11 and the U2a3 bullet. e7b5d7ed's message needs an Accepted-immutable row.
- `scripts/lib/dev-cycle-read.sh:580-583` — addressee: implementer. Claim 19b: decide whether EACCES under a parent directory should fail the walk (for example, fail when the parent exists but `-x` is false) or be documented as not covered. The same applies to Claim 21's `ls-files` warning, exit 0 (`:517`).
- `scripts/lib/dev-cycle-read.sh:596` — addressee: orchestrator (likely an informational override row). Claim 22: the link-text here-string. A process substitution or a length check would close it, and it is unreachable for a symlink a checkout can hold.
- `docs/reviews/override-log.md:374`, `:379` — addressee: orchestrator. Claims 7 and 9 wording: name grep alongside lower, and scope the blob/tree row to imports read through the name.

---

## Goal-Alignment Note

**Success criterion (verbatim):** A code-fact-check report verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages, saved at the path given below.

**Answered:** All nine brief items are verdicted:

1. main_imports block and return-1 comments: Claims 13, 16-21 and 24.
2. nul_list and I2-C4: Claims 15 and 22.
3. Header Inputs, including a checkout state that removes an import relative to main alone: found (Claim 13).
4. Link-text and parent loops: Claims 18, 22 and 23.
5. isimported: Claim 25.
6. Commit figures and claims: E1, E2 and E3 all match; Claims 3 and 27-30.
7. A5, F11 and the U2a3/U2b bullets: Claims 11, 12, 18 and 19b.
8. Tests: Claim 26.
9. Override rows: Claims 1-10.

**Out of scope:** Claude Code's own resolution and loading (rows :369-371). U2a3b's parser changes and its fail-closed fixes for lower and grep, beyond noting them. Timing figures other than the whole-walk time on this repo. A full-disk run.

**Escalate:** The four escalations above. The parent-link bypass (Claims 13 and 18) is the one that contradicts the header invariant the iteration-2 fix claimed to make true.
