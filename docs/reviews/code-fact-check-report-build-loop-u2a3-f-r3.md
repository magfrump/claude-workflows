Commit: cc1aa864

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`)
**Scope:** `git diff main...HEAD` (main 62d366a7, HEAD cc1aa864): comments in `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`; docs `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3/U2b bullets), `docs/reviews/override-log.md` (rows 2026-10-06 `feat/build-loop-u2a3`); commit messages `main..HEAD` (10 commits). Role `cfcg`, pass `i3`, replicate r3 of k=3.
**Checked:** 2026-10-06 (executions logged 2026-10-07T00:25Z-00:33Z UTC)
**Total claims checked:** 31
**Summary:** 20 verified, 11 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution provenance common to every `executed` claim: cwd `/workspace/.claude/wt-build-loop-u2a3` (or the probe repo under the scratch dir named), `TMPDIR=/tmp/u2a3-cfcg-i3-CgDN`, bash 5.2.15. Captured outputs are in `/tmp/u2a3-cfcg-i3-CgDN/logs/` (scratch, not committed; the shared brief allows writing only this report). Mutants are scratch copies of the lib at `/tmp/u2a3-cfcg-i3-CgDN/m-<name>/` run against a copy of `build-loop-check.bats` by `/tmp/u2a3-cfcg-i3-CgDN/mut.sh`; the worktree file was never edited. The hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) has no pattern matching any claim below.

---

## Claim 1: A5's refusal list: "odd names, link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an import path main lacks under a directory main stores as a symlink, an unreadable checkout file, or a checkout symlink the walk would read fail it"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal (all fail the walk) and A5's not-covered list; does not establish the untraced Claude Code behaviours A5 names, and the list is not complete: the walk also fails on other non-plain checkout paths.

Each listed shape fails the walk; tests 5, 7, 9, 12 and 15 assert them and mutants of each guard fail those tests (`mut-nlcheck`, `mut-escape`, `mut-ckread`, `mut-notplain`, `mut-dotdot`, `mut-parent`, `mut-ckL`, all `rc=1`). The list omits the generic arm that fails on any checkout path that exists but is not a plain file or plain directory below the root:

```bash
# scripts/lib/dev-cycle-read.sh:580-583
      if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }
      elif [[ -d "$f" && ! -L "$f" && -z "$(blocker "$f" dir)" ]]; then continue  # a directory: nothing loads
      elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1
      else continue; fi
```

Probed: an `@.` token, link text `sub/..` (the root), and a FIFO at an imported path each print `walk: failed` (`shapes-probe.txt`). So A5 understates the refusals (it fails closed); the precise list adds "an import naming the repo root, or a checkout path that is neither a plain file nor a plain directory (a FIFO)". The not-covered half holds: an untracked nested repo's `AGENTS.md` and a start file under a checkout directory symlink are not listed by `ls-files --others` (`untracked_md:` printed nothing; walk ok, imports `-`, `listings-probe.txt`); `ls-tree -r` lists a symlink or gitlink as one entry (paraphrased — no quote available because the claim is about git's listing behaviour, observed in the probe output). "An instruction file the checkout tracks but main lacks is not a start" follows from `untracked_md` being `ls-files --others` (`scripts/lib/dev-cycle-read.sh:517`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:517`, `scripts/lib/dev-cycle-read.sh:556-614`; command `source probe.sh; mk ...; runw ...` (cwd `/tmp/u2a3-cfcg-i3-CgDN/pr/*/r`, exit 0, 2026-10-07T00:28:54Z and 00:30:18Z) → `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/listings-probe.txt`; mutant logs `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-*.txt`

---

## Claim 2: Plan F11: the walk's refusal list "... fails the walk, so floor refuses every path", and "The walk reads the checkout for its untracked starts, for targets main lacks, and for whether a path it would read is a symlink"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers F11's refusal list, gap list and three checkout inputs against the code; does not establish U2a4's floor (not yet written) beyond `isimported main` answering imported on a failed walk.

Same omission as Claim 1 (the root and FIFO arm at `scripts/lib/dev-cycle-read.sh:582`, probed `walk: failed` in `shapes-probe.txt`). The checkout-input list also leaves out one checkout read: the link-text loop lstat's every component path whether or not the walk would read it:

```bash
# scripts/lib/dev-cycle-read.sh:600
            [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
```

(this only adds failures). The gap list matches A5 and the lib's "Not covered" list. `isimported main` answers imported after a failed walk (`main) main_imports || return 0;`, `scripts/lib/dev-cycle-read.sh:629`; tests 4, 8 and 14 assert it).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:580-583`, `scripts/lib/dev-cycle-read.sh:596-600`, `scripts/lib/dev-cycle-read.sh:629`; `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt` (exit 0, 2026-10-07T00:28:54Z)

---

## Claim 3: Plan U2a3 bullet: "It refuses the tree and link shapes it does not model (a doubled name, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or NUL or has a .. after a symlink, an import path main lacks under a directory main stores as a symlink, an unreadable checkout file, a checkout symlink it would read)"

**Location:** `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape; does not establish completeness (the root and FIFO arm is unlisted), nor the bullet's carried-rows bookkeeping beyond its match with fbeae280's message.

Every listed shape fails (see Claim 1's mutants and tests). Unlisted: an import naming the root, or a checkout FIFO, which fail through `elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1` (`scripts/lib/dev-cycle-read.sh:582`; probed in `shapes-probe.txt`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:276`, `scripts/lib/dev-cycle-read.sh:582`; `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt`

---

## Claim 4: Plan U2b bullet: "the walk reads its untracked starts, targets main lacks, and checkout symlinks"

**Location:** `docs/working/plan-build-loop-handoff.md:278`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three classes of checkout read in `main_imports`; does not establish U2b's future `--check` code.

Untracked starts: `nul_list recs untracked_md` (`scripts/lib/dev-cycle-read.sh:564`); targets main lacks: `queue+=("t:$p")` then `import_targets "$d" < "$f"` (`:615`, `:580`); checkout symlinks: `! -L "$p"` (`:600`) and `-L "$f"` (`:582`). "Checkout symlinks" covers the link-text component lstat that Claim 2 notes F11 words more narrowly.

**Evidence:** `scripts/lib/dev-cycle-read.sh:564`, `scripts/lib/dev-cycle-read.sh:580-583`, `scripts/lib/dev-cycle-read.sh:600`, `scripts/lib/dev-cycle-read.sh:615`

---

## Claim 5: Override row (errexit-off): "Every failure path sets IMPORTED_MAIN=error before returning; the known unguarded command (lower) is fixed in U2a3b"

**Location:** `docs/reviews/override-log.md` (row 2026-10-06 `feat/build-loop-u2a3`, "`isimported main` runs the walk under `main_imports || return 0`")
**Type:** Invariant / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` in `main_imports` and the unguarded commands in its body; does not establish U2a3b's `lower` fix (stacked, not under review).

Every `return 1` before `IMPORTED_MAIN=$'\n'` (`scripts/lib/dev-cycle-read.sh:575`) runs after `IMPORTED_MAIN=error` (`:554`), and every later one sets it inline (`:580`, `:582`, `:586`, `:591`, `:593`, `:598`, `:603`, `:614`). But `lower` is not the only unguarded command: the link-text split still uses a here-string,

```bash
# scripts/lib/dev-cycle-read.sh:596
          lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"
```

and its failure is swallowed. Executed: with main holding `ld -> deep/inner` and `AGENTS.md` link text `ld/../` + 35000×`./` + `evil.md` (70013 bytes), the walk prints `walk-failed` normally; under `trap '' XFSZ; ulimit -f 0` bash prints `line 596: cannot create temp file for here-document: File too large`, `parts` stays empty, the `..` check never runs, and the walk prints `walk-ok` with `deep/secret.md` answering `-` (`herestring-linktext-probe.txt`). Under plain `ulimit -f 0` the shell dies by SIGXFSZ (exit 153). This needs link text over 64 KiB, which git stores but no Linux symlink can hold (PATH_MAX), so no checkout can follow such a link (paraphrased — no quote available because the bound is a kernel limit, not repo code).

**Evidence:** `scripts/lib/dev-cycle-read.sh:554`, `scripts/lib/dev-cycle-read.sh:575-614`, `scripts/lib/dev-cycle-read.sh:596`; command `source probe.sh; ... timeout 60 bash -c "set -euo pipefail; $pre source ...; main_imports ..."` (cwd `/tmp/u2a3-cfcg-i3-CgDN/p1/r`, pipeline exit 0, 2026-10-07T00:28:13Z) → `/tmp/u2a3-cfcg-i3-CgDN/logs/herestring-linktext-probe.txt`

---

## Claim 6: Override row (I2-C4 etc., Fixed): "main_imports' `done <<<"$out"` here-string goes to a temp file past 64 KiB, and a failed write read as no imports (I2-C4, fail-open) ... Process substitution (tested under ulimit -f 0, mutant killed) ... the return-1 comment lists every cause in this unit's code including the root and a FIFO (probed)"

**Location:** `docs/reviews/override-log.md` (last row dated 2026-10-06 `feat/build-loop-u2a3`)
**Type:** Error-handling / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fix (process substitution), its test and mutant, and the root/FIFO causes; does not establish that the walk has no other temp-file path (it has one, Claim 5).

The fix holds: HEAD reads a 67 KB import list whole under `ulimit -f 0` with or without SIGXFSZ ignored (`walk-ok`, `last-imported`), and the here-string mutant fails test 10 (`mut-herestring.txt`, `not ok 10 ... failed # 153`). The failure mechanism is imprecise: under plain `ulimit -f 0` the old code did not "read as no imports"; bash was killed by SIGXFSZ (`timeout: the monitored command dumped core`, status 153). The imports were silently lost only when the write failed without the signal (SIGXFSZ ignored, or a full disk): the mutant then printed `cannot create temp file for here-document`, and a cached second call answered `docs/last.md` `-` (`herestring-importlist-probe.txt`). Root and FIFO: probed `walk: failed` (`shapes-probe.txt`). The row says the routed fix covers the here-string; the link-text here-string at `:596` is still there (Claim 5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:616`; commands `bash /tmp/u2a3-cfcg-i3-CgDN/herestring_mut_probe.sh` (cwd probe repo, exit 0, 2026-10-07T00:32:00Z) → `/tmp/u2a3-cfcg-i3-CgDN/logs/herestring-importlist-probe.txt`; `./mut.sh herestring ...` (cwd `/tmp/u2a3-cfcg-i3-CgDN`, exit 1) → `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-herestring.txt`

---

## Claim 7: Override row: "A name main stores as both a blob and a tree fails the walk closed but prints git's `fatal:` line on stderr"

**Location:** `docs/reviews/override-log.md` (row "A name main stores as both a blob and a tree")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a tree holding blob `a` and tree `a/` with `a/x.md` imported; does not establish the outcome when no import reaches the colliding name (the walk then never reads it).

Probe: `ls-tree -r` lists `a` and `a/x.md`; the walk prints `fatal: path 'a/x.md' does not exist in '<tree>'` and `walk: failed`, with both asked paths `imported` (`dup-blobtree-probe.txt`). The failure comes from the blob read `out="$(git cat-file blob "$MAIN_SHA:$f" | import_targets "$d")" || { IMPORTED_MAIN=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:586`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:586`; `/tmp/u2a3-cfcg-i3-CgDN/logs/dup-blobtree-probe.txt` (exit 0, 2026-10-07T00:30:51Z)

---

## Claim 8: Override row: a symlinked instruction file's imports resolve from the target's directory only ("`CLAUDE.md -> docs/real.md` holding `@x.md` records docs/x.md, not x.md")

**Location:** `docs/reviews/override-log.md` (row "A symlinked instruction file's imports are resolved from the target's directory only")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's side (`AGENTS.md -> docs/real.md` used for the probe, same arm); does not establish Claude Code's resolution, which the row leaves untraced.

The 120000 arm prints the target path, which is queued as `m:docs/real.md`, and that file's `d` is its own directory (`if [[ "$f" == */* ]]; then d="${f%/*}"`, `scripts/lib/dev-cycle-read.sh:578`). Probe: `docs/x.md: imported`, `x.md: -` (`dup-blobtree-probe.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:578`, `scripts/lib/dev-cycle-read.sh:585-605`; `/tmp/u2a3-cfcg-i3-CgDN/logs/dup-blobtree-probe.txt`

---

## Claim 9: Override rows: `.claude/commands/*.md` files are not starts; an `@ld/../q.md` token is recorded as q.md; the cache key ignores the checkout; D8 supersede ("`ls-tree -r` does not enter a gitlink"); untracked_md lists ignored files; per-symlink cost "(two cat-file reads and a realpath per link-text component)"; the tree check is "mapfile, a regex and a map assignment per entry"

**Location:** `docs/reviews/override-log.md` (rows dated 2026-10-06 `feat/build-loop-u2a3`)
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's description of the code; does not re-measure the rows' timings (0.4-0.5 s, ~12 ms, 0.35 s) or verify Claude Code behaviour they defer.

Start rule: `"${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md` (`scripts/lib/dev-cycle-read.sh:571`), no commands directory. Tokens resolve lexically: `realpath -ms --relative-to="$ROOT_REAL"` (`:503`). Cache key: `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:553-554`), no checkout term. Ignored files: `git ls-files -z --others` without `--exclude-standard` (`:517`). Per symlink: two `git cat-file blob` calls (`:590-591`), one `realpath` per component (`:599`) plus one for the target (`:602`). Tree check: `nul_list` (mapfile), the `=~` record regex and `ent[$f]=` per record (`:556-561`). Gitlinks: `ls-tree -r` prints a 160000 entry without entering it, and the case arm `*) continue` skips it (paraphrased — no quote available because the first half is git's listing behaviour, not repo code).

**Evidence:** `scripts/lib/dev-cycle-read.sh:503`, `scripts/lib/dev-cycle-read.sh:517`, `scripts/lib/dev-cycle-read.sh:553-562`, `scripts/lib/dev-cycle-read.sh:571`, `scripts/lib/dev-cycle-read.sh:586-603`

---

## Claim 10: Header Inputs: main_imports "also reads the checkout's untracked start files, imported files main lacks and whether a path it would read is a symlink there, which can only add imports or fail it"

**Location:** `scripts/lib/dev-cycle-read.sh:32-34`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the "can only add imports or fail" invariant for every checkout read in `main_imports` (starts, `t:` targets, `-L` checks, the generic non-plain arm); does not establish behaviour on a case-insensitive checkout, and the list of reads is narrower than the code (see Claim 11).

Search for a checkout state that removes an import main alone yields: (1) untracked starts are only added to `cand`, and `seen` only stops re-queuing an import; the import is recorded before the `seen` test (`IMPORTED_MAIN+="$(lower "$p")"$'\n'` precedes `[[ -z "${seen[$p]+set}" ]] || continue`, `scripts/lib/dev-cycle-read.sh:609-610`); (2) a path main has always goes `m:` and reads main's blob, never the checkout (`if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); continue; fi`, `:612`), probed with the link's own directory replaced by a checkout symlink: the walk still reads main's file, `walk: ok` both times (`owndir-probe.txt`); (3) a `t:` path is read, skipped as absent or as a plain directory (main alone gives nothing there either), or fails (`:580-583`); (4) the checkout `-L` test can only set `lk=1`, which can only fail (`:598`, `:600`). A checkout `t:` start and an `m:` start at the same path are both queued (paraphrased — no quote available because it follows from the separate `cand+=("m:$f")` and `cand+=("t:$f")` loops at `:562` and `:565`). No removal found.

**Evidence:** `scripts/lib/dev-cycle-read.sh:556-615`; `/tmp/u2a3-cfcg-i3-CgDN/logs/owndir-probe.txt` (exit 0, 2026-10-07T00:29:05Z), `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt`

---

## Claim 11: Header Inputs: the checkout reads named are "untracked start files, imported files main lacks and whether a path it would read is a symlink there"

**Location:** `scripts/lib/dev-cycle-read.sh:32-34`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the enumeration of checkout reads; does not affect Claim 10's invariant.

Two checkout reads go beyond "whether a path it would read is a symlink": the link-text loop lstat's each component path even when main has it and the walk will read main's blob (`[[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1`, `scripts/lib/dev-cycle-read.sh:600`), and the walk tests a path's type, not only symlink-ness (`elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1`, `:582`, which fails a FIFO or the root). A precise version: "...and the type of a path it would read, or that link text passes through".

**Evidence:** `scripts/lib/dev-cycle-read.sh:32-34`, `scripts/lib/dev-cycle-read.sh:582`, `scripts/lib/dev-cycle-read.sh:600`

---

## Claim 12: Header: main_imports "needs resolve_main to have found main by name, or it fails"

**Location:** `scripts/lib/dev-cycle-read.sh:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `main_by_name`'s gate and the cache key's MAIN_BY_NAME term; does not establish resolve_main's own candidate order.

`main_by_name || return 1` (`scripts/lib/dev-cycle-read.sh:555`), where `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`:254`), and resolve_main sets `MAIN_BY_NAME=1` only for origin/HEAD, main or master (`:429`). Tests 4 (trunk, main deleted) and 16 (`MAIN_BY_NAME=""` → `y.sh` imported) pass in the HEAD suite run, and the cache-key mutant fails test 16 (`mut-cachekey.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:254`, `scripts/lib/dev-cycle-read.sh:429`, `scripts/lib/dev-cycle-read.sh:553-555`; `TMPDIR=... bats build-loop-check.bats build-loop-read.bats dev-cycle.bats fixture-git-env.bats utility-smoke.bats` (cwd worktree, exit 0, 2026-10-07T00:25:48Z) → `/tmp/u2a3-cfcg-i3-CgDN/logs/suites-head.txt`; `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-cachekey.txt`

---

## Claim 13: Block comment: "It refuses what it does not model, as FENCE_AWK does: a doubled name, a name holding a newline (in main's tree or the untracked list), symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink, an import path main lacks under a directory main stores as a symlink, a checkout file it cannot read, and a checkout path it would read that is a symlink or lies under one fail the walk, so isimported main answers imported for every path."

**Location:** `scripts/lib/dev-cycle-read.sh:458-465`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal and the isimported consequence; does not establish completeness: the root and FIFO arm is unlisted here (the return-1 comment at :538-548 lists it).

All listed refusals fail (tests 5, 7, 9, 12, 15; mutants `nlcheck`, `escape`, `ckread`, `notplain`, `dotdot`, `parent`, `ckL` each `rc=1`). The doubled-name rationale in the return-1 comment ("git's lookups read the first copy") was probed: `git cat-file -p <commit>:AGENTS.md` returns whichever duplicate `ls-tree` lists first (`lb: ls-tree first=120000 cat-file=[x]`, `bl: ... first=100644 cat-file=[@docs/b.md]`, `dup-blobtree-probe.txt`). Missing from this list: "a checkout path it would read that ... lies under one" is right, but an import of the repo root or a checkout FIFO also fails (`shapes-probe.txt`), through `:582`. A precise ending: "...a checkout path it would read that is not a plain file or plain directory below the root (a symlink, under one, the root, a FIFO)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:458-465`, `scripts/lib/dev-cycle-read.sh:556-614`; `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/dup-blobtree-probe.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-*.txt`

---

## Claim 14: "A start file answers imported only when an import reaches it (U2a4's floor names start files by its own rules)."

**Location:** `scripts/lib/dev-cycle-read.sh:465-466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that starts are queued and marked seen but not added to IMPORTED_MAIN; does not establish U2a4's rules.

Starts get `seen[${cand[i]:2}]=1; queue+=("${cand[i]}")` (`scripts/lib/dev-cycle-read.sh:572`) and IMPORTED_MAIN grows only from import targets (`IMPORTED_MAIN+="$(lower "$p")"$'\n'`, `:609`). Test 3 asserts `CLAUDE.md: -` while it is a start, and test 13 asserts a self-import (`@CLAUDE.md`) is recorded (passes in `suites-head.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:572`, `scripts/lib/dev-cycle-read.sh:609`, `test/scripts/build-loop-check.bats:46-61`, `test/scripts/build-loop-check.bats:253-265`; `/tmp/u2a3-cfcg-i3-CgDN/logs/suites-head.txt`

---

## Claim 15: "Not covered (known issue A5): start files under a symlinked directory (on main or in the checkout: neither listing enters one) or in a submodule or an untracked nested repo, other names that one file has on a case-insensitive checkout, absolute imports, and three shapes A5 lists as untraced against Claude Code"

**Location:** `scripts/lib/dev-cycle-read.sh:467-471`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listing behaviour behind each gap and the pointer to A5's three shapes; does not establish Claude Code's behaviour for those shapes or case-insensitive filesystems (not available here).

Probe: an untracked nested repo's `AGENTS.md` and a start under a checkout directory symlink are absent from `untracked_md` and answer `-` (`listings-probe.txt`). Absolute imports are dropped by `import_targets` (`[[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue`, `scripts/lib/dev-cycle-read.sh:502`). A5 lists exactly three untraced shapes (commands, a link's own directory, a token's `..`) (`docs/working/known-issues-dev-cycle.md:18`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:467-471`, `scripts/lib/dev-cycle-read.sh:502`, `docs/working/known-issues-dev-cycle.md:18`; `/tmp/u2a3-cfcg-i3-CgDN/logs/listings-probe.txt` (exit 0, 2026-10-07T00:30:18Z)

---

## Claim 16: "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again."

**Location:** `scripts/lib/dev-cycle-read.sh:472-475`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key, the reset and the replay of a failed result; does not establish that any caller clears the cache (no caller exists yet).

```bash
# scripts/lib/dev-cycle-read.sh:553-554
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"
```

(excerpt ends :554; enclosing main_imports() continues to :618 — read). A key ending in a non-empty ROOT_REAL never equals "", so clearing it re-walks. "Until a walk succeeds" is slightly loose: IMPORTED_MAIN becomes the partial list at `:575` before the walk ends, but every later failure resets it to error (Claim 5). Test 16 passes, and the cache-key and reset mutants each fail it (`mut-cachekey.txt`, `mut-reset.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-554`, `scripts/lib/dev-cycle-read.sh:575`, `test/scripts/build-loop-check.bats:299-308`; `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-cachekey.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-reset.txt` (cwd `/tmp/u2a3-cfcg-i3-CgDN`, exit 1 each, 2026-10-07T00:26Z)

---

## Claim 17: "nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or 1 unless CMD exited 0 (&& || keep errexit off)."

**Location:** `scripts/lib/dev-cycle-read.sh:518-519`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a failing command, an empty listing, a last item literally `rc=0`, and errexit inside CMD, plus both call sites (`:556`, `:564`); does not establish behaviour for a CMD whose output is not NUL-terminated beyond the probe (it returns 1, which git's `-z` listings never produce).

Probe results (`nul_list-probe.txt`): failing after output → `rc1`; failing with no output → `rc1`; empty success → `rc0 n=0`; success whose last item is `rc=0` → `rc0 n=2 [a|rc=0|]` (kept); failure whose last item is `rc=0` → `rc1`; unterminated success → `rc1`. A `false` inside CMD under `set -e` did not abort (`rc=0 n=1 a0=continued`), so CMD runs with errexit off. Both call sites `|| return 1` before IMPORTED_MAIN leaves `error`; the `nulrc` mutant fails test 10 (`mut-nulrc.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:518-519`, `scripts/lib/dev-cycle-read.sh:556`, `scripts/lib/dev-cycle-read.sh:564`; `bash /tmp/u2a3-cfcg-i3-CgDN/nul_probe.sh` and `nul_probe2.sh` (cwd scratch, exit 0, 2026-10-07T00:29:23Z) → `/tmp/u2a3-cfcg-i3-CgDN/logs/nul_list-probe.txt`; `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-nulrc.txt`

---

## Claim 18: Return-1 comment: returns 1 "when main is not found by name, the commit's tree or the untracked list cannot be listed whole (nul_list), a tree record does not parse, a name is listed twice (git's lookups read the first copy) or holds a newline, the lower-cased start list comes back short, a blob or checkout file cannot be read, symlink text it follows is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink, an import path main lacks lies under a directory main stores as a symlink, or a checkout path it would read exists but is neither a plain file nor a plain directory below the root (a symlink, under one, the root itself, a FIFO); need_root exits instead."

**Location:** `scripts/lib/dev-cycle-read.sh:538-548`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` in main_imports (mapped one-to-one below) and that each listed cause fails; does not cover the swallowed here-string failure at :596 (Claim 5), which is not a return path, nor the cached replay at :553.

Mapping: main by name `:555`; listings `:556`, `:564`; record parse `:558`; doubled/newline `:560`, `:565`; short start list `:568`; blob/checkout read `:580`, `:586`, `:590-591`; link text `:593`, `:598`, `:603`; parent link `:614`; non-plain `:582`. The root and FIFO go through the generic arm (`elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1`, `:582`): `@.`, link text `sub/..`, link text exactly `..` in `sub/`, and a FIFO each print `walk: failed` (`shapes-probe.txt`). The fix-drift i3 finding ("no explicit checks for FIFO files or root-directory paths") is answered by that arm. The tree regex lets `.` match a newline (`match f=$'we\nird'`, `re-probe.txt`), so the newline check at `:560` is live, and its mutant fails test 5 (`mut-nlcheck.txt`). need_root exits (`exit 1`, `:96-98`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:96-98`, `scripts/lib/dev-cycle-read.sh:549-618`; `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/re-probe.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-*.txt` (13 mutants, each exit 1, 2026-10-07T00:26-00:33Z)

---

## Claim 19: "$(...) drops NULs, so they are counted first; the x keeps trailing newlines, which $(...) would also drop."

**Location:** `scripts/lib/dev-cycle-read.sh:588-589`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL count and the trailing-newline sentinel; does not cover link text over 64 KiB (Claim 5).

`i="$(git cat-file blob "$MAIN_SHA:$f" | tr -cd '\0' | wc -c)"` then `out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"; out="${out%x}"` (`:590-592`). Test 9 (NUL link text `docs/rules.md\0zzz` → failed) and test 7 (`$'notes.md\n'` → failed) pass in `suites-head.txt`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:588-592`, `test/scripts/build-loop-check.bats:141-163`, `test/scripts/build-loop-check.bats:177-203`; `/tmp/u2a3-cfcg-i3-CgDN/logs/suites-head.txt`

---

## Claim 20: "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails."

**Location:** `scripts/lib/dev-cycle-read.sh:594-595`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a `..` after any symlink component inside the link text (first component, deeper, after `.`, `//`, trailing `/`, text exactly `..`, a chain, a checkout-only link), with no wrong refusal of the legitimate shapes probed, and no read outside the repo beyond lstat; does not cover the link's own directory being a symlink only in the checkout (not checked; main's blob is read), nor link text over 64 KiB with a failing here-string (Claim 5).

```bash
# scripts/lib/dev-cycle-read.sh:596-600
          lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"
          for c in "${parts[@]}"; do
            [[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }
            p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${p:+$p/}$c" 2>/dev/null)" || p=..
            [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
```

(excerpt ends :600; the 120000 arm continues to :603 and main_imports() to :618 — read). Probes (`shapes-probe.txt`): `ln/./../docs/t.md` and `a/ln/../../docs/t.md` fail; `docs//./t.md`, `docs/t.md/`, `a/b/../../docs/t.md` and a two-link chain are followed (`walk: ok`, targets imported); `..` alone fails as leaving the repo (top) or naming the root (in `sub/`). Test 15 covers main and checkout-only links; the `dotdot` and `ckL` mutants fail it. The only filesystem access is `-L "$p"` (lstat), which can reach a path outside the root such as `..` (paraphrased — no quote available because this follows from `realpath -ms` being lexical, observed by no reads in the probes). Not caught: main holds `sub/AGENTS.md -> ../docs/t.md` and the checkout replaces `sub` with a symlink; the walk stays `walk: ok` (`owndir-probe.txt`) because `lk` starts empty at the link's own directory. The walk reads main's `sub/AGENTS.md` blob for that path, consistent with Claim 10.

**Evidence:** `scripts/lib/dev-cycle-read.sh:594-603`, `test/scripts/build-loop-check.bats:277-297`; `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/owndir-probe.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-dotdot.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-ckL.txt`

---

## Claim 21: "Main lacks p: under a directory link main stores (the checkout may lack it), fail."

**Location:** `scripts/lib/dev-cycle-read.sh:613-614`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every slash-ended prefix of a path main lacks; does not cover paths main has (they are read from main, `:612`).

`for (( c = ${#p}; c > 0; c-- )); do [[ "${p:c:1}" != / || "${ent[${p:0:c}]:-}" != 120000 ]] || { IMPORTED_MAIN=error; return 1; }; done` (`:614`) tests each prefix ending before a `/`. Test 15's link and token cases (checkout lacks `ld`) fail; the `parent` mutant fails test 15 (`mut-parent.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:612-615`; `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-parent.txt`

---

## Claim 22: isimported: "Whether path $2 (any case) is imported, by the walk $1 names: tree or main. A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; ... Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:619-623`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main/tree/other arms, case folding and the failed-walk answer; does not establish U2a4's caller.

```bash
# scripts/lib/dev-cycle-read.sh:627-632
  lp="$(lower "$2")"
  case "$1" in
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
    tree) imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
    *) return 0 ;;
  esac
```

IMPORTED_MAIN entries are lower-cased (`:609`). Tests 2, 3 (`Docs/Imported.md`), 8 and 14 pass (`suites-head.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:619-633`; `/tmp/u2a3-cfcg-i3-CgDN/logs/suites-head.txt`

---

## Claim 23: Test names and comments in build-loop-check.bats assert what they say (no false passes)

**Location:** `test/scripts/build-loop-check.bats:13-24`, `test/scripts/build-loop-check.bats:46-308`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers each new test's name against its assertions and the mutant kill map; does not cover root/FIFO refusals, which no test exercises (probed only), or the line-596 here-string.

Each name's shapes are asserted with `want`, and 13 mutants were each killed by the test that names the guarded shape (map: nested→6, escape→7, ckread→9, notplain→9 and 12, nlcheck→5, trlen/nulrc/herestring→10, dotdot/parent/ckL→15, cachekey/reset→16; `mut-*.txt`). Two comments are looser than their checks without making a false pass: test 9's "A tracked directory symlink, present in the checkout, that an import passes through" (`:183`) now fails through the main-parent check (`:614`), whatever the checkout holds; test 15's "A .. after a plain directory is followed" (`:293`) is asserted by `AGENTS.md -> docs/../docs/n.md` (hid.md, docs/n.md imported), while the re-made `CLAUDE.md -> ld/../evil.md` at that point has its `..` after an `ld` absent from both main and the checkout. The `imps` comment ("tree always reads ok") matches `[[ "$w" != main ]] || main_imports` (`:20`).

**Evidence:** `test/scripts/build-loop-check.bats:13-24`, `test/scripts/build-loop-check.bats:177-203`, `test/scripts/build-loop-check.bats:277-297`; `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-*.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/suites-head.txt`

---

## Claim 24: fbeae280: "Tests: build-loop-check.bats 14; 112 across the five suites. Mutants of the nested-rules start, the checkout-read guard, the tr length check (via a failing tr shim) and the link-escape guard each fail. 344 changed code lines against U2a2." (B5 numbering and the Notes line: override row, Accepted-immutable)

**Location:** commit `fbeae280`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at fbeae280 and the four mutants against HEAD's tests; does not re-run the mutants against fbeae280's own test file. B5's test numbering and the Notes line: see the override row "Commit fbeae280's B5 bullet numbers tests two ways".

`grep -c '^@test'` at fbeae280: check 14, read 19, dev-cycle 75, fixture-git-env 2, utility-smoke 2 = 112; `git diff --numstat main...fbeae280 -- . ':!docs'` sums to 344. Mutants `nested`, `ckread`, `trlen`, `escape` each fail (`mut-*.txt`). The B-row behaviours it lists (B2, B3, B12, B8, B4/B10/B11) are present at HEAD (Claims 4, 13, 18).

**Evidence:** commit fbeae280; `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-nested.txt`, `mut-ckread.txt`, `mut-trlen.txt`, `mut-escape.txt` (exit 1 each, 2026-10-07T00:26Z)

---

## Claim 25: 45ad17b0: "A5 names U2a3 as main_imports' unit"

**Location:** commit `45ad17b0`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers A5's wording; nothing else.

A5 reads "The gate's walk (`main_imports`, U2a3)" (`docs/working/known-issues-dev-cycle.md:18`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 26: 4f087967: "Tests: one new in build-loop-check.bats (15); 113 across the five suites. A mutant dropping the new check fails it. 369 changed code lines against main." ("resolved a component at a time": override row, Accepted-immutable)

**Location:** commit `4f087967`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures and the mutant (run against HEAD's test 15); the "resolved" wording is covered by the override row on 4f087967/34edec56.

Counts at 4f087967: 15 + 19 + 75 + 2 + 2 = 113; numstat sum 369. The `dotdot` mutant fails test 15. Its example (`ld -> deep/inner`, `CLAUDE.md -> ld/../evil.md`) is test 15's first case, which fails the walk at HEAD.

**Evidence:** commit 4f087967; `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-dotdot.txt`

---

## Claim 27: 34edec56 subject

**Location:** commit `34edec56`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Pointer only: the subject's inaccuracy is recorded in override row "Commit 4f087967 says link text is 'resolved' ... and 34edec56's subject" (Accepted-immutable), and the comment it touched is gone at HEAD (`grep 'checked above'` finds nothing in the lib).

Accepted-immutable per that row; the replaced "(link text is checked above)" comment no longer exists (paraphrased — no quote available because the claim covers absence of code: zero grep hits).

**Evidence:** `docs/reviews/override-log.md` (row 2026-10-06 `feat/build-loop-u2a3`, "Commit 4f087967 says ..."), `scripts/lib/dev-cycle-read.sh:467-471`

---

## Claim 28: e7b5d7ed: figures and fix claims ("build-loop-check.bats 16; 114 across the five suites. Mutants of the parent check, the checkout -L half, the cache key and the reset to error each fail. 398 changed code lines"; tests G1-G6 listed)

**Location:** commit `e7b5d7ed`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures, the four mutants and the listed test cases; the "isimported's comment" sentence is split out as Claim 29.

Counts at e7b5d7ed: 16 + 19 + 75 + 2 + 2 = 114; numstat sum 398. Mutants `parent`, `ckL`, `cachekey`, `reset` each fail (tests 15, 15, 16, 16). Every listed test case is in HEAD's tests 6 (100755, chain, untracked rules, checkout edit), 15 and 16.

**Evidence:** commit e7b5d7ed; `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-parent.txt`, `mut-ckL.txt`, `mut-cachekey.txt`, `mut-reset.txt`

---

## Claim 29: e7b5d7ed: "isimported's comment says start files answer imported only when an import reaches them (architecture F2)"

**Location:** commit `e7b5d7ed`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the sentence landed; the sentence's truth is Claim 14.

The sentence is in main_imports' block comment ("A start file answers imported only when an import reaches it", `scripts/lib/dev-cycle-read.sh:465`), not in isimported's comment (`:619-623`), at e7b5d7ed and at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:465-466`, `scripts/lib/dev-cycle-read.sh:619-623`

---

## Claim 30: c42f017f: "bash writes a here-string past 64 KiB to a temp file, and a failed write (ulimit -f 0, a full disk) read as no imports, so the walk answered ok without them. It now reads through process substitution"

**Location:** commit `c42f017f`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old and new import-list read under ulimit -f 0 (with and without SIGXFSZ ignored); does not cover the other here-string at :596 (Claim 5).

The fix is right (HEAD reads the list whole in all three regimes). The mechanism is imprecise: under `ulimit -f 0` with SIGXFSZ at its default, the old code's shell was killed (status 153, which fails a caller), not "ok without them". The silent loss happens when the write fails without the signal (SIGXFSZ ignored, or a full disk): the mutant then logged `cannot create temp file for here-document` and the cached answer for `docs/last.md` was `-` (`herestring-importlist-probe.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:607-616`; `/tmp/u2a3-cfcg-i3-CgDN/logs/herestring-importlist-probe.txt` (exit 0, 2026-10-07T00:32:00Z)

---

## Claim 31: c42f017f / 2a3e499f / cc1aa864: "nul_list NAME CMD..., used for main's tree and the untracked list"; "the return-1 comment names every cause ..."; "Docs: the plan's U2a3 bullet lists the parent-link refusal; A5 says a checkout-tracked instruction file main lacks is not a start"; "the A2 test also reads a 67 KB import list under ulimit -f 0 (the here-string mutant fails it); build-loop-check.bats 16; 114 across the five suites. 400 changed code lines"; 2a3e499f "the not-covered list points to A5's three untraced shapes"; cc1aa864 "the root and FIFO causes go through the generic not-plain arm, probed"

**Location:** commits `c42f017f`, `2a3e499f`, `cc1aa864`
**Type:** Configuration / Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed figure and statement; does not cover c42f017f's mechanism sentence (Claim 30) or the docs-only commits 277b2fab and cb4ebbc8, whose messages hold no checkable claim beyond the files they add.

`nul_list` at `scripts/lib/dev-cycle-read.sh:556` and `:564`; return-1 comment, Claim 18; plan `:276` names "an import path main lacks under a directory main stores as a symlink"; A5 has the tracked-in-checkout sentence (`docs/working/known-issues-dev-cycle.md:18`). Test 10 writes 320 lines of `@docs/%0200d.md` (about 67.5 KB) and the `herestring` mutant fails it. HEAD suite run: 114 `ok`, 0 `not ok`, exit 0; numstat sum 400 (120+9, 265+2, 2+2). Not-covered list names three shapes (`:470-471`). cc1aa864: probed (Claim 18).

**Evidence:** `scripts/lib/dev-cycle-read.sh:470-471`, `scripts/lib/dev-cycle-read.sh:556`, `scripts/lib/dev-cycle-read.sh:564`, `test/scripts/build-loop-check.bats:205-224`, `docs/working/plan-build-loop-handoff.md:276`; `/tmp/u2a3-cfcg-i3-CgDN/logs/suites-head.txt` (exit 0, 2026-10-07T00:25:48Z), `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-herestring.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 1** (`docs/working/known-issues-dev-cycle.md:18`): the refusal list omits the root and FIFO (generic non-plain) arm.
- **Claim 2** (`docs/working/plan-build-loop-handoff.md:126`): same omission; the checkout-read list leaves out the link-text component lstat.
- **Claim 3** (`docs/working/plan-build-loop-handoff.md:276`): same omission.
- **Claim 5** (override-log errexit row): `lower` is not the only unguarded command; the `:596` here-string fails silently.
- **Claim 6** (override-log I2-C4 row): plain `ulimit -f 0` killed the old code by SIGXFSZ (exit 153); the silent loss needs SIGXFSZ ignored or a full disk; a second here-string remains at `:596`.
- **Claim 11** (`scripts/lib/dev-cycle-read.sh:32-34`): the checkout reads also include lstat of link-text components and a path's type (FIFO, root), not only symlink-ness.
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:458-465`): the refusal list omits the root and FIFO arm that the return-1 comment names.
- **Claim 29** (commit e7b5d7ed): the start-file sentence is in main_imports' block comment, not isimported's.
- **Claim 30** (commit c42f017f): same SIGXFSZ precision as Claim 6.

### Unverifiable
(none)

(Claims 16 and 20 are Verified, with residues in their Scope lines: IMPORTED_MAIN briefly holds a partial list before a later failure resets it, and the link's own directory is not checked against the checkout.)

## Escalations

- `scripts/lib/dev-cycle-read.sh:596` — addressee: U2a3 implementer (and the U2a3b loop, which owns the here-string class). `IFS=/ read -ra parts <<<"$out"` is a second here-string in main_imports. Executed: with link text over 64 KiB and the temp-file write failing without SIGXFSZ, the `..`-after-symlink check is skipped and the walk answers ok (fails open). Low severity: no Linux symlink can hold text over PATH_MAX, so no checkout can follow such a link. It does contradict the override row's "the known unguarded command (lower)".
- `scripts/lib/dev-cycle-read.sh:458-465`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`, `:276` — addressee: U2a3 implementer. The refusal lists omit the root and FIFO arm (`:582`) that the return-1 comment names. They understate refusals (fail-closed), so this is Low.
- `scripts/lib/dev-cycle-read.sh:596-600` — addressee: security reviewer (informational). `lk` starts empty at the link's own directory, so a checkout that makes that directory a symlink does not trip the `..` check. The walk reads main's blob for that path, as it does for every path main has, so this matches the header's model.
- Out of scope (pre-existing on main, not in this diff): `scripts/lib/dev-cycle-read.sh:281` (main_entry) and `:341` (brief_fields) also read via `done <<<"$out"`. Addressee: dev-cycle-read owner / U2a3b loop. Impact not traced here.

## Goal-Alignment Note

**Success criterion (verbatim):** A code-fact-check report verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages, saved at the path given below.

**Answered:** Yes. 31 claims covering all nine focus areas: the main_imports block and return-1 comments (Claims 13-16, 18-21), nul_list and I2-C4 (17, 5, 6, 30), the header Inputs paragraph including a search for an import-removing checkout state (10-12, none found), the link-text and parent loops across every listed shape (20, 21), isimported (22), every commit on main..HEAD (24-31, with Accepted-immutable pointers), A5/F11/U2a3/U2b docs (1-4), test names (23), and the override rows' code claims (5-9). Every test-count and line-count figure matches. All five suites pass at HEAD (114). 13 mutants were each killed. No claim is Incorrect.

**Out of scope:** Claude Code's own loading behaviour (A5's three untraced shapes); U2a3b's stacked parser changes; the override rows' timing measurements (not re-run); case-insensitive filesystems.

**Escalate:** The `:596` link-text here-string (Low, fails open only on symlink text no kernel can create) and the refusal lists that omit the root/FIFO arm (Low, fail-closed). Neither blocks merge on fact-check grounds; both are wording or residual items for the implementer to fix or record as override rows.
