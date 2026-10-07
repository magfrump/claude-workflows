Commit: cc1aa864

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`)
**Scope:** `git diff main...HEAD` on `feat/build-loop-u2a3` at cc1aa864 (base main 62d366a7): comments in `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`; `docs/working/known-issues-dev-cycle.md` A5; `docs/working/plan-build-loop-handoff.md` F11 and the U2a3/U2b bullets; override-log rows dated 2026-10-06 for `feat/build-loop-u2a3`; every commit message on main..HEAD. Role `cfcg`, pass `i3` (final confirming pass, replicate r1 of k=3).
**Checked:** 2026-10-06 (probes ran 2026-10-07T00:25Z-00:35Z UTC)
**Total claims checked:** 41
**Summary:** 35 verified, 3 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Execution environment for every `executed` claim: GNU bash 5.2.15, GNU coreutils realpath 9.1, Linux 6.18 (WSL2), not root. Scratch dir `/tmp/u2a3-cfcg-i3-9082` (TMPDIR set to a subdirectory of it for every run); probe repos `r1`-`r8` and mutant copies `m-*` live there; captured output is under `/tmp/u2a3-cfcg-i3-9082/logs/`. Probe scripts: `p1.sh`-`p8.sh`, `h3.sh`, `mutants.py`, `env.sh` in the same dir (each probe sources `env.sh`, which unsets git's local env vars, points git config at /dev/null and runs the lib exactly as the suite's `imps` helper does: `set -euo pipefail; source LIB; resolve_main || true; ROOT_REAL="$(pwd -P)"; main_imports; isimported main PATH...`). Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 patterns); claims 31, 33, 35 and 39 (test tallies) were checked against the "per-suite counts" pattern first seen for commit 37c5ea9: no match, the counts are exact.

---

## Claim 1: "main_imports checks every tree record in bash (mapfile, a regex and a map assignment per entry): 0.4-0.5 s here ... ~2.1 s at 30k entries"

**Location:** `docs/reviews/override-log.md:365`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-record mechanism (one mapfile listing, one regex test and one associative assignment per record); does not establish the quoted timings, which were not re-measured.

```bash
# scripts/lib/dev-cycle-read.sh:556-561
  nul_list recs git ls-tree -r -z --full-tree "$MAIN_SHA" || return 1
  for rec in "${recs[@]}"; do
    [[ "$rec" =~ ^([01234567]{6})\ [abcdefghijklmnopqrstuvwxyz]+\ [0123456789abcdef]{40,64}$'\t'(.+)$ ]] || return 1
    f="${BASH_REMATCH[2]}"
    [[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1
    ent[$f]="${BASH_REMATCH[1]}"
```
(excerpt ends :561; enclosing main_imports() continues to :617 — read)

**Evidence:** `scripts/lib/dev-cycle-read.sh:519`, `scripts/lib/dev-cycle-read.sh:556-563`

---

## Claim 2: "a submodule's files are not starts because `ls-tree -r` does not enter a gitlink (not `*) continue`)" (superseding the D8 row's reason)

**Location:** `docs/reviews/override-log.md:373` (supersedes `:366`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers why a submodule's instruction files never enter `cand` (the start list is built only from ls-tree records and the untracked list); does not establish Claude Code's own loading of a submodule's CLAUDE.md, or the row's exposure statement about parent-repo files.

Starts come only from `ls-tree -r` records ending in `.md` and from `untracked_md`: `[[ "$f" != *.[mM][dD] ]] || cand+=("m:$f")` (`scripts/lib/dev-cycle-read.sh:562`) and `for f in "${recs[@]}"; do ... cand+=("t:$f"); done` (`:565`). A gitlink is listed as one 160000 record and not entered (paraphrased — no quote available because this is git's documented ls-tree behaviour, not code in the repo). The `*) continue ;;` arm at `:606` is reached only for a gitlink that is itself queued, so the superseding row's correction of the D8 row is right.

**Evidence:** `scripts/lib/dev-cycle-read.sh:556-565`, `scripts/lib/dev-cycle-read.sh:606`, `docs/reviews/override-log.md:366`, `docs/reviews/override-log.md:373`

---

## Claim 3: "A symlinked instruction file's imports are resolved from the target's directory only (`CLAUDE.md -> docs/real.md` holding `@x.md` records docs/x.md, not x.md)"

**Location:** `docs/reviews/override-log.md:369`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's side of the row (which path it records); does not establish how Claude Code resolves a symlinked instruction file's imports (the row's Defer premise, untraced).

The 120000 arm turns link text into one more import (`out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" ...)"`, `scripts/lib/dev-cycle-read.sh:601`); that path is queued `m:` and read with `d` set to its own directory (`if [[ "$f" == */* ]]; then d="${f%/*}"`, `:575`). Probe P6/R5 output: `walk: ok`, `docs/x.md: imported`, `x.md: -`.

Command: `bash /tmp/u2a3-cfcg-i3-9082/p6.sh` · cwd `/tmp/u2a3-cfcg-i3-9082` (repo `r6`) · exit 0 · 2026-10-07T00:32:18Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:575`, `scripts/lib/dev-cycle-read.sh:587-603`, `/tmp/u2a3-cfcg-i3-9082/logs/p6.log`

---

## Claim 4: "`.claude/commands/*.md` files are not start files, so a file a command `@`-references can self-merge (walk ok, docs/c.md `-`)"

**Location:** `docs/reviews/override-log.md:370`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's answer for a committed `.claude/commands/c.md` referencing `@docs/c.md`; does not establish whether Claude Code loads command references (untraced, A5).

The start rule is `[[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]` (`scripts/lib/dev-cycle-read.sh:570`), which no `.claude/commands/` name matches. Probe P6/R6: `walk: ok`, `docs/c.md: -`.

Command: `bash /tmp/u2a3-cfcg-i3-9082/p6.sh` · cwd `/tmp/u2a3-cfcg-i3-9082` · exit 0 · 2026-10-07T00:32:18Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:568-573`, `/tmp/u2a3-cfcg-i3-9082/logs/p6.log`

---

## Claim 5: "An `@ld/../q.md` token with `ld` a directory link is recorded as q.md while the kernel reads deep/q.md, even with the link in the checkout"

**Location:** `docs/reviews/override-log.md:371`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's lexical treatment of an `@` token's `..` (tokens resolve through `import_targets`' `realpath -ms`, never the link-text component loop); does not establish how Claude Code resolves the token (untraced, A5).

Probe P6/R7 (main and checkout both hold `ld -> deep/inner`, AGENTS.md `see @ld/../q.md`): `walk: ok`, `q.md: imported`, `deep/q.md: -`. The token path is normalised in `import_targets` (`p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)" || continue`, `scripts/lib/dev-cycle-read.sh:506`).

Command: `bash /tmp/u2a3-cfcg-i3-9082/p6.sh` · cwd `/tmp/u2a3-cfcg-i3-9082` · exit 0 · 2026-10-07T00:32:18Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:495-511`, `/tmp/u2a3-cfcg-i3-9082/logs/p6.log`

---

## Claim 6: "The walk's cache key ignores the checkout, so an untracked start file added after a successful walk is unseen by a later call in the same shell"; "a caller whose checkout changes sets IMPORTED_MAIN_DONE=\"\""

**Location:** `docs/reviews/override-log.md:372`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key's three fields and the clear-to-rewalk contract; does not establish any future caller's compliance (no caller until U2a4).

```bash
# scripts/lib/dev-cycle-read.sh:552-553
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"
```
(excerpt ends :553; enclosing main_imports() continues to :617 — read)

Probe P8 (same shell: query, add untracked CLAUDE.local.md importing docs/n.md, query, clear `IMPORTED_MAIN_DONE`, query): `docs/n.md: -`, `docs/n.md: -`, `docs/n.md: imported`.

Command: `bash /tmp/u2a3-cfcg-i3-9082/p8.sh` · cwd `/tmp/u2a3-cfcg-i3-9082` (repo `r8b`) · exit 0 · 2026-10-07T00:34:07Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:552-553`, `/tmp/u2a3-cfcg-i3-9082/logs/p8.log`

---

## Claim 7: "Every failure path sets IMPORTED_MAIN=error before returning; the known unguarded command (lower) is fixed in U2a3b"

**Location:** `docs/reviews/override-log.md:374`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` in main_imports (each sets or inherits `error`) and the unguarded commands in the unit; does not establish U2a3b's fix of `lower` (stacked, not under review).

Every `return 1` before `:574` returns with the `IMPORTED_MAIN=error` set at `:553`; every one after `IMPORTED_MAIN=$'\n'` (`:574`) is written `{ IMPORTED_MAIN=error; return 1; }` (`:580`, `:582`, `:586`, `:591`, `:593`, `:597`, `:602`, `:614`). So the first sentence holds. But `lower` is not the only unguarded command: the link-text split `lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"` (`scripts/lib/dev-cycle-read.sh:596`) has no failure arm. With link text of 65,535+ bytes and a temp-file write that fails without SIGXFSZ, the read fails, `parts` keeps its old value, the `..`-after-symlink check is skipped and the walk answers ok (probe P4c: `cannot create temp file for here-document`, `walk: ok`, `deep/secret.md: -`). Precise version: "...the known unguarded commands are lower (fixed in U2a3b) and the link-text here-string read at :596". Such link text cannot exist on disk (Linux caps a symlink target below PATH_MAX, 4096), so Claude Code cannot load through it, and the practical miss is nil. See Claim 26.

Command: `bash /tmp/u2a3-cfcg-i3-9082/p3.sh` · cwd `/tmp/u2a3-cfcg-i3-9082` (repo `r3`) · exit 0 · 2026-10-07T00:28:55Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-617`, `/tmp/u2a3-cfcg-i3-9082/logs/p3.log`

---

## Claim 8: "the three copies now agree (lib, A5, F11 edited together in iteration 2) and F11 names all three checkout inputs"

**Location:** `docs/reviews/override-log.md:375`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal and not-covered lists in the lib block comment, A5 and F11 against each other; does not establish that the floor (U2a4), which F11 also mentions, behaves as F11 says.

The lib lists "start files under a symlinked directory ... or in a submodule or an untracked nested repo, other names that one file has on a case-insensitive checkout, absolute imports, and three shapes A5 lists as untraced" (`scripts/lib/dev-cycle-read.sh:467-471`). A5 lists "start files under a symlinked directory or in a submodule or untracked nested repo ..., other names one file has on a case-insensitive checkout, or absolute imports" plus the same three untraced shapes (`docs/working/known-issues-dev-cycle.md:18`). F11 has the same gaps and says "The walk reads the checkout for its untracked starts, for targets main lacks, and for whether a path it would read is a symlink" (`docs/working/plan-build-loop-handoff.md:126`). The refusal lists match item for item. F11 and A5 lump the doubled and newline names together ("odd names" in A5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:458-471`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 9: "untracked_md lists ignored files too (needed for CLAUDE.local.md)"

**Location:** `docs/reviews/override-log.md:377`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the listing command; does not establish the row's timings (0.35 s / ~4 s), which were not re-measured.

```bash
# scripts/lib/dev-cycle-read.sh:515-517
# The checkout's untracked and ignored .md files, NUL-separated: --others
# without --exclude-standard already lists ignored files.
untracked_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; }
```

Test 1 (`test/scripts/build-loop-check.bats:46`) exercises an untracked CLAUDE.local.md start (passes; Claim 30).

**Evidence:** `scripts/lib/dev-cycle-read.sh:515-517`

---

## Claim 10: "Each symlink the walk follows costs ~12 ms (two cat-file reads and a realpath per link-text component)"

**Location:** `docs/reviews/override-log.md:378`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-link work: two `git cat-file blob` calls, one realpath fork per component and a final realpath; does not establish the 12 ms figure, which was not re-measured.

```bash
# scripts/lib/dev-cycle-read.sh:590-601
          if ! i="$(git cat-file blob "$MAIN_SHA:$f" | tr -cd '\0' | wc -c)" || [[ "$i" -ne 0 ]] \
             || ! out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"; then IMPORTED_MAIN=error; return 1; fi
...
            p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${p:+$p/}$c" 2>/dev/null)" || p=..
...
          out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" 2>/dev/null)" || out=..
```
(excerpt elides :592-598 and :600 and ends :601; the enclosing 120000 arm ends :603 and main_imports() at :617 — read)

**Evidence:** `scripts/lib/dev-cycle-read.sh:587-603`

---

## Claim 11: "A name main stores as both a blob and a tree fails the walk closed but prints git's `fatal:` line on stderr"

**Location:** `docs/reviews/override-log.md:379`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a tree holding blob `n` and tree `n` (git mktree sorts them blob-first) with and without an import below `n`; does not establish other orders, which git's tree sort prevents.

The walk fails only when an import reaches a path below the name. With no such import, probe P6/R15 gives `walk: ok` (ls-tree -r lists `n` and `n/y.md` once each, so the doubled-name check at `scripts/lib/dev-cycle-read.sh:560` does not fire). With `@n/y.md`, probe P7 gives `fatal: path 'n/y.md' does not exist in '<sha>'` and `walk: failed`: `git cat-file blob "$MAIN_SHA:$f"` (`:584`) fails and its arm returns error. Precise version: "...fails the walk closed, with git's `fatal:` line, when an import reaches a path below that name; otherwise the walk is ok and reads nothing there."

Commands: `bash /tmp/u2a3-cfcg-i3-9082/p6.sh` (2026-10-07T00:32:18Z) and `bash /tmp/u2a3-cfcg-i3-9082/p7.sh` (2026-10-07T00:32:30Z) · cwd `/tmp/u2a3-cfcg-i3-9082` · exit 0 each.

**Evidence:** `scripts/lib/dev-cycle-read.sh:558-561`, `scripts/lib/dev-cycle-read.sh:584`, `/tmp/u2a3-cfcg-i3-9082/logs/p6.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p7.log`

---

## Claim 12: "Process substitution (tested under ulimit -f 0, mutant killed); nul_list helper ...; the return-1 comment lists every cause in this unit's code including the root and a FIFO (probed); A5 names the tracked-in-checkout start"

**Location:** `docs/reviews/override-log.md:381`
**Type:** Error-handling / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four stated fixes and their tests or probes; does not establish that the walk has no other here-string (it has one, at `:596`: Claim 26) or anything about U2a3b's rebase.

The import list is now read `done < <(printf '%s\n' "$out")` (`scripts/lib/dev-cycle-read.sh:616`). Mutant `j-here-string` (restoring `done <<<"$out"`) fails test 10 (`not ok 10 ... reads a list past 64 KiB under ulimit -f 0`, status 153). The root and FIFO probes fail the walk (Claim 23). A5 says "an instruction file the checkout tracks but main lacks is not a start" (`docs/working/known-issues-dev-cycle.md:18`). Probe P6/A5 confirms it: `walk: ok`, `docs/t.md: -`.

Commands: mutant loop `python3 -I mutants.py LIB j-here-string m-j/.../dev-cycle-read.sh; cd m-j && TMPDIR=... bats test/scripts/build-loop-check.bats` (2026-10-07T00:29:39Z, bats exit 1) and `bash p6.sh` (00:32:18Z, exit 0) · cwd `/tmp/u2a3-cfcg-i3-9082`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:616`, `docs/working/known-issues-dev-cycle.md:18`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-j-here-string.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p6.log`

---

## Claim 13: A5: "closes A2 and A3's symlinked-file half ... (symlinked start files and targets on main are followed, `.claude/rules/` at any depth starts, and odd names, link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an import path main lacks under a directory main stores as a symlink, an unreadable checkout file, or a checkout symlink the walk would read fail it) ... (an instruction file the checkout tracks but main lacks is not a start: `ls-files --others` skips it)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed follow, start and refusal through the passing suite, the ten mutants and probes P1-P8; does not establish the floor's use of the walk (U2a4), Claude Code's side of the three untraced shapes, or the case where link text "leaves the repo" and comes back by the root's own directory name (probe L9: `../r2/evil.md` from repo `r2` is followed as `evil.md`, the target this checkout's kernel reads).

Each refusal fails the walk in the suite or a probe. Odd names: test 3 and test 7. Empty, absolute, trailing-newline and leaving link text: test 7 loop and test 12. NUL: test 9. `..` after a symlink: test 15 and probes L2-L4, L11, L13. Path under a link main stores: test 15 and probes T1, T2, L8, L12. Unreadable checkout file: test 9 (`chmod 000`). Checkout symlink: tests 9 and 12. All ten mutants of these arms are killed (Claim 30). Start files and follows are covered by tests 1, 6 and 11. Probe P6/A5 confirms the tracked-in-checkout sentence (`walk: ok`, `docs/t.md: -`).

Commands: `TMPDIR=$(mktemp -d ...) bats test/scripts/build-loop-check.bats` (cwd worktree, exit 0, 2026-10-07T00:25:07Z); `bash p1.sh`, `p2.sh`, `p6.sh` (cwd `/tmp/u2a3-cfcg-i3-9082`, exit 0, 00:27:39Z / 00:28:18Z / 00:32:18Z).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:549-617`, `/tmp/u2a3-cfcg-i3-9082/logs/build-loop-check.bats.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p1.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p2.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p6.log`

---

## Claim 14: F11: "NUL-safe listings, symlinks on main followed, `.claude/rules/` at any depth and the checkout's untracked files as starts; ... fails the walk ... The walk reads the checkout for its untracked starts, for targets main lacks, and for whether a path it would read is a symlink, so U2b names the checkout `--check` runs in"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the walk properties F11 lists (the same list as A5, Claim 13); does not establish "so floor refuses every path", which describes U2a4's floor, not yet written.

Both listings use `-z` and are read whole through `nul_list` (`scripts/lib/dev-cycle-read.sh:556`, `:564`). The checkout is read only in the `t` arm (`inrepo_here`/`-d`/`-e`/`-L`, `:577-581`) and by `! -L "$p"` in the link-text loop (`:599`), which matches F11's three inputs.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:556-617`

---

## Claim 15: U2a3 bullet "It refuses the tree and link shapes it does not model (a doubled name, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an import path main lacks under a directory main stores as a symlink, an unreadable checkout file, a checkout symlink it would read)"; U2b bullet "the walk reads its untracked starts, targets main lacks, and checkout symlinks"

**Location:** `docs/working/plan-build-loop-handoff.md:276`, `docs/working/plan-build-loop-handoff.md:278`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal list and the three checkout inputs against the code (same evidence as Claims 13-14); does not establish the bullet's "carries ... B14" bookkeeping beyond fbeae280's own note that B14's candidates go to this unit's review.

The list matches the code arms at `scripts/lib/dev-cycle-read.sh:558-614` one for one (paraphrased — no quote available because the eleven refusal arms span 40 lines and are quoted in Claims 23 and 25).

**Evidence:** `docs/working/plan-build-loop-handoff.md:276-278`, `scripts/lib/dev-cycle-read.sh:558-614`

---

## Claim 16: Header: "the instruction-file import walks"; "inrepo, dirok, skipped, check_brief, isimported and the import walks exit 1 (need_root) unless ROOT_REAL is set ..."

**Location:** `scripts/lib/dev-cycle-read.sh:6`, `scripts/lib/dev-cycle-read.sh:15`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both walks calling need_root; does not cover need_root's own messages (unchanged, outside the diff).

`main_imports` calls `need_root` on its third line (`scripts/lib/dev-cycle-read.sh:551`), before the cache test. `imported_names` does the same at `:522`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:95-99`, `scripts/lib/dev-cycle-read.sh:522`, `scripts/lib/dev-cycle-read.sh:551`

---

## Claim 17: Inputs: main_imports "reads the default branch's commit, never the working tree ... (it also reads the checkout's untracked start files, imported files main lacks and whether a path it would read is a symlink there, which can only add imports or fail it, and needs resolve_main to have found main by name, or it fails)"

**Location:** `scripts/lib/dev-cycle-read.sh:32-35`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every place the walk consults the checkout and whether any of them can remove an import that main alone would record; does not establish the cache's freshness against later checkout changes (a documented contract, Claim 21).

I looked for a checkout state that removes an import relative to main alone and found none. Import paths are appended before any dedup: `IMPORTED_MAIN+="$(lower "$p")"$'\n'` precedes `[[ -z "${seen[$p]+set}" ]] || continue` (`scripts/lib/dev-cycle-read.sh:609-610`). Every main path a token names is queued `m:` and read from the blob (`:612`), so checkout state never decides how a main file is read. Untracked starts only push more `t:` items (`:565`, `:571`). A path that is both on main and untracked is queued once as `m:` and once as `t:`, because `seen` is set for each candidate but not consulted when starts are queued (`:571`). The checkout's `-L` in the link-text loop (`:599`) can only set `lk`, which can only fail the walk (`:597`). The `t` arm either reads, skips (directory or absent) or fails (`:577-581`). The precondition is `main_by_name || return 1` (`:554`), and test 2 (main renamed to trunk) asserts `walk failed`. Test 1 asserts that a working-tree edit of a tracked CLAUDE.md does not count (`docs/wt-only.md -`), and test 6 asserts a main blob over a checkout edit.

Command: `TMPDIR=$(mktemp -d /tmp/u2a3-cfcg-i3-9082/t-XXXX) bats test/scripts/build-loop-check.bats` · cwd worktree · exit 0 · 2026-10-07T00:25:07Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:554-616`, `test/scripts/build-loop-check.bats:46-79`, `/tmp/u2a3-cfcg-i3-9082/logs/build-loop-check.bats.log`

---

## Claim 18: "it starts at every instruction file stored there (and every .md under a .claude/rules/ directory at any depth ...), plus the checkout's untracked ones, and follows an import into the file main stores at that path, whatever its name; a symlink there is followed to the path its text names. A target main does not have is read from the checkout when it is a plain file there."

**Location:** `scripts/lib/dev-cycle-read.sh:453-458`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers starts (any case, nested rules, tracked and untracked), follows into main blobs of any name and mode 100644/100755/120000, and checkout reads for targets main lacks; does not establish Claude Code's own start set (A5's untraced shapes).

```bash
# scripts/lib/dev-cycle-read.sh:568-573
  for i in "${!cand[@]}"; do
    f="${low[i]:2}"
    if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]; then
      seen[${cand[i]:2}]=1; queue+=("${cand[i]}")
    fi
  done
```

The `[[ == ]]` pattern `*` matches `/`, so `.claude/rules/a/b.md` starts too. Test 6 (nested `pkg/.claude/rules`, untracked rules files, `docs/a+b.md`, 100755, a chain of links) and test 11 (`.MD`) pass. Mutant `a-nested-rules-start` fails test 6.

Commands: suite run (Claim 17) and the mutant loop (2026-10-07T00:29:39Z, bats exit 1 for each mutant) · cwd `/tmp/u2a3-cfcg-i3-9082/m-*`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:562-616`, `test/scripts/build-loop-check.bats:114-139`, `test/scripts/build-loop-check.bats:226-234`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-a-nested-rules-start.log`

---

## Claim 19: "a doubled name, a name holding a newline (in main's tree or the untracked list), symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink, an import path main lacks under a directory main stores as a symlink, a checkout file it cannot read, and a checkout path it would read that is a symlink or lies under one fail the walk, so isimported main answers imported for every path. A start file answers imported only when an import reaches it"

**Location:** `scripts/lib/dev-cycle-read.sh:458-466`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape failing the walk, and `isimported main` answering imported after a failure, under normal temp-file conditions. It does not establish two residues. First, the `..`-after-symlink check on link text of 65,535+ bytes when the here-string's temp file cannot be written (Claim 26; the check is skipped). Second, "a checkout path it would read ... lies under one" applies only when the path exists: an absent path under a checkout link reads nothing and the walk continues (probes P3, P3b: `walk: ok`), which matches the code but not a looser reading.

Every shape fails the walk: suite tests 3, 7, 9, 12 and 15, ten killed mutants (Claim 30), and probes P1-P2 and L2-L13/T1-T2 (all `walk: failed`). `isimported main` returns 0 on a failed walk through `main) main_imports || return 0;` (`scripts/lib/dev-cycle-read.sh:629`); test 8 and test 14 assert it under `if`. On the start-file sentence: starts get `seen` set and are queued (`:571`), but only the read loop appends to `IMPORTED_MAIN` (`:609`). Test 1 asserts `CLAUDE.md -` for a start no import reaches.

Commands: suite run (Claim 17); `bash p1.sh` (00:27:39Z), `bash p2.sh` (00:28:18Z) · cwd `/tmp/u2a3-cfcg-i3-9082` · exit 0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:558-616`, `scripts/lib/dev-cycle-read.sh:629`, `/tmp/u2a3-cfcg-i3-9082/logs/p1.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p2.log`, `/tmp/u2a3-cfcg-i3-9082/logs/build-loop-check.bats.log`

---

## Claim 20: "Not covered (known issue A5): start files under a symlinked directory (on main or in the checkout: neither listing enters one) or in a submodule or an untracked nested repo, other names that one file has on a case-insensitive checkout, absolute imports, and three shapes A5 lists as untraced against Claude Code"

**Location:** `scripts/lib/dev-cycle-read.sh:467-471`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers each listed gap's mechanism and a search for other fail-open shapes. I tried root, FIFO, `.`, `//`, trailing `/`, `..`-only text, leave-and-return text, links whose final component is a directory link, chains, blob+tree names, checkout links (dangling, to dirs, absent below) and a checkout-tracked start; none fails open beyond the list. It does not establish two things. First, link text of 65,535+ bytes with a failed temp write skips the `..` check (Claim 26); that link cannot exist on disk, so no load is missed. Second, case-insensitive aliasing of a main directory link: `@LD/x.md` against main's `ld` passes the parent check (`ent` lookups are exact-case); this falls under the listed case-insensitive gap.

Absolute imports are dropped by `import_targets` (`[[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue`, `scripts/lib/dev-cycle-read.sh:505`). Neither listing enters a symlinked directory, a gitlink or a nested repo (paraphrased — no quote available because this is git's ls-tree/ls-files behaviour; iteration 2 executed it, and I did not re-run it). Probe results are in `p1.log`, `p2.log`, `p6.log` and `p7.log`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:467-471`, `scripts/lib/dev-cycle-read.sh:495-511`, `/tmp/u2a3-cfcg-i3-9082/logs/p1.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p2.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p7.log`

---

## Claim 21: "IMPORTED_MAIN reads \"error\" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE=\"\" to walk again"

**Location:** `scripts/lib/dev-cycle-read.sh:472-475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the initial value, the reset on every recompute, the three-field key and the clear-to-rewalk contract; does not establish the value while a walk is in progress (it is `$'\n'` plus entries from `:574` on, not "error", and no caller can read it then).

The initial value is `IMPORTED_MAIN=error` (`scripts/lib/dev-cycle-read.sh:476`), and the reset and key are at `:553` (quoted in Claim 6). Test 16's sequence `- docs/b.md x.sh x.sh - y.sh` passes. Mutants `h-cache-key-mbn` and `i-reset-to-error` each fail test 16. Probe P8 confirms the clear contract (Claim 6).

Commands: suite run (Claim 17); mutant loop (2026-10-07T00:29:39Z); `bash p8.sh` (00:34:07Z, exit 0).

**Evidence:** `scripts/lib/dev-cycle-read.sh:476`, `scripts/lib/dev-cycle-read.sh:552-554`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-h-cache-key-mbn.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-i-reset-to-error.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p8.log`

---

## Claim 22: "nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or 1 unless CMD exited 0 (&& || keep errexit off)"; used for main's tree and the untracked list

**Location:** `scripts/lib/dev-cycle-read.sh:518-519` (call sites `:556`, `:564`)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a failing command (with and without partial output), an empty listing, a listing whose last item is literally `rc=0` (succeeding and failing), and `set -e` survival. It does not establish two extra behaviours, both fail-safe at both call sites, which return 1 at once. First, a successful listing whose last record lacks a terminating NUL also returns 1 (`[x][yrc=0]`). Second, on failure NAME is left holding the partial items plus an `rc=1` item.

```bash
# scripts/lib/dev-cycle-read.sh:519
nul_list() { local -n nl_a="$1"; shift; mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || return 1; unset 'nl_a[-1]'; }
```

Probe P5 results:
- failing with output: `rc=1 n=3 items=[a][b][rc=1]`
- `false`: `rc=1`
- `true` (empty listing): `rc=0 n=0 items=[]`
- last item `rc=0`, success: `rc=0 n=2 items=[x][rc=0]` (the real item is kept)
- last item `rc=0`, failing: `rc=1`
- unterminated output: `rc=1`
- under `set -euo pipefail`, `bash -c 'exit 7'` gives `rc=1` and `still-here` prints

Both call sites end `|| return 1`.

Command: `LC_ALL=C bash /tmp/u2a3-cfcg-i3-9082/p5.sh` · cwd `/tmp/u2a3-cfcg-i3-9082` · exit 0 · 2026-10-07T00:30:59Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:518-519`, `scripts/lib/dev-cycle-read.sh:556`, `scripts/lib/dev-cycle-read.sh:564`, `/tmp/u2a3-cfcg-i3-9082/logs/p5.log`

---

## Claim 23: Return-1 comment: "returns 1 ... when main is not found by name, the commit's tree or the untracked list cannot be listed whole (nul_list), a tree record does not parse, a name is listed twice (git's lookups read the first copy) or holds a newline, the lower-cased start list comes back short, a blob or checkout file cannot be read, symlink text ... , an import path main lacks lies under a directory main stores as a symlink, or a checkout path it would read exists but is neither a plain file nor a plain directory below the root (a symlink, under one, the root itself, a FIFO); need_root exits instead"

**Location:** `scripts/lib/dev-cycle-read.sh:538-548`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` statement in main_imports (each maps to a listed cause), the root and FIFO causes and the first-copy parenthetical. It does not establish non-return outcomes: SIGXFSZ killing the shell on the link-text here-string under `ulimit -f 0` (exit 153), and the fail-open read when that write fails without a signal (Claim 26). The cached-failure return (`:552`) is implicit rather than listed.

Each `return 1` maps to a listed cause:
- `:554` main_by_name
- `:556`, `:564` nul_list
- `:558` record parse
- `:560` doubled name or newline (tree)
- `:565` newline (untracked)
- `:567` short lower-cased list
- `:578` checkout read
- `:580` exists but not plain
- `:584` blob read
- `:590-593` NUL, blob read, empty, newline, absolute
- `:597` `..` after a symlink
- `:602` leaves the repo
- `:614` parent link

Root and FIFO reach the generic `elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1` (`:580`), because `blocker "."` prints `./` for the root (realpath of `.` ≠ `$ROOT_REAL/.`) and a FIFO is neither `-f` nor `-d`. Probes P1 (`@.`, `@docs/..`, link text `.`, `sub/AGENTS.md -> ..`) and P2 (FIFO target) all give `walk: failed`. An untracked FIFO start is not listed by `ls-files --others`, so the walk is ok and never opens it (P2b), which is consistent with "a path it would read". Probe P8 shows `git cat-file blob main:z.md` returns the first of two `z.md` entries (`first`).

Commands: `bash p1.sh` (2026-10-07T00:27:39Z), `bash p8.sh` (00:34:07Z) · cwd `/tmp/u2a3-cfcg-i3-9082` · exit 0.

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-617`, `scripts/lib/dev-cycle-read.sh:111-128`, `/tmp/u2a3-cfcg-i3-9082/logs/p1.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p8.log`

---

## Claim 24: "$(...) drops NULs, so they are counted first; the x keeps trailing newlines, which $(...) would also drop."

**Location:** `scripts/lib/dev-cycle-read.sh:588-589`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL count and the trailing-newline guard; does not cover link text holding a NUL that `git cat-file` could not emit (not possible for a blob).

The code is `i="$(git cat-file blob ... | tr -cd '\0' | wc -c)" ... [[ "$i" -ne 0 ]]` and `out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"; ... out="${out%x}"` (`scripts/lib/dev-cycle-read.sh:590-592`). Test 9 (text `docs/rules.md\0zzz`) and test 7 (text `notes.md\n`) pass, both asserting `walk failed`.

Command: suite run (Claim 17).

**Evidence:** `scripts/lib/dev-cycle-read.sh:587-593`, `test/scripts/build-loop-check.bats:159-163`, `test/scripts/build-loop-check.bats:198-202`

---

## Claim 25: "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails." (the link-text component loop)

**Location:** `scripts/lib/dev-cycle-read.sh:594-600`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop for every shape probed: first component a link, a deeper link, `.`, `//`, trailing `/`, text exactly `..`, a final component that is a directory link, a `..` before a link, leave-and-return text, a link in a subdirectory, and a checkout-only link. It does not establish exact refusal: any `..` anywhere after a link component fails, including `ld/sub/..`, which the kernel and lexical resolution agree on. That is an over-refusal (fail-closed), consistent with the comment's wording. It also does not establish the absence of fs access by `realpath -ms` (strace unavailable; static knowledge of coreutils' no-links/missing-ok mode only).

```bash
# scripts/lib/dev-cycle-read.sh:596-600
          lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"
          for c in "${parts[@]}"; do
            [[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }
            p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${p:+$p/}$c" 2>/dev/null)" || p=..
            [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
```
(excerpt ends :600; enclosing 120000 arm continues to :603 and main_imports() to :617 — read)

Probe P2 results:
- L2 `docs/ld2/../evil.md`, L3 `./ld/./../evil.md`, L4 `ld//../evil.md`, L11 `ld/i.md/..`, L13 (link in `sub/`): `walk: failed`
- L4b `docs//../evil.md` and L10 `docs/../evil.md`: ok, `evil.md` imported
- L5 trailing `/`: ok, `docs/evil.md` imported (the kernel would give ENOTDIR; over-records)
- L6 `..`: failed (the root)
- L7/L7b `ld`, `ld/`: ok, chain followed to a plain directory
- L8 `../r2/ld/i.md`: failed (parent check)
- L9 `../r2/evil.md`: ok, `evil.md`

Mutants `e-dotdot-after-link` and `g-checkout-L-half` each fail test 15. The only checkout access in the loop is `-L` (lstat), which can name a path above the root (`-L ..`, `-L ../x`). The parent-link loop at `:614` reads only `ent`.

Commands: `bash p2.sh` (2026-10-07T00:28:18Z, exit 0); mutant loop (00:29:39Z).

**Evidence:** `scripts/lib/dev-cycle-read.sh:594-603`, `/tmp/u2a3-cfcg-i3-9082/logs/p2.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-e-dotdot-after-link.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-g-checkout-L-half.log`

---

## Claim 26: The I2-C4 fix makes the walk free of here-string temp files: "main walk reads its import list without a here-string" read as "the here-string was the only path to a temp file" (prompt item 2; the override row's "Fixed")

**Location:** `scripts/lib/dev-cycle-read.sh:596` (against commit c42f017f and `docs/reviews/override-log.md:381`)
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the remaining here-string in main_imports. It does not establish practical reachability: the link text must be at least 65,535 bytes, longer than any symlink Linux can create, so Claude Code cannot load through such a link and no import is missed in practice.

A second here-string remains in the same unit: `IFS=/ read -ra parts <<<"$out"` (`scripts/lib/dev-cycle-read.sh:596`). Bash 5.2 sends a here-string of 65,536 bytes or more (string plus newline) to a temp file. Under `ulimit -f 0` with SIGXFSZ at its default, bash dies with exit 153, so the walk neither returns 1 nor exits through need_root. When the write fails without the signal (SIGXFSZ ignored; ENOSPC is the same path), the read fails, `parts` keeps its previous value (empty for the first link) and the `..`-after-symlink check is skipped. Probe P4c had main `ld -> deep/inner` and a 68,593-byte `CLAUDE.md -> <pad>/ld/../evil.md`. It printed `line 596: cannot create temp file for here-document: File too large`, then `walk: ok`, `deep/secret.md: -`. P4a, the same tree with no limit, gives `walk: failed`. The commit's stated atom, that the import list is read without a here-string (`:616`), is correct (Claim 39).

Commands: `bash /tmp/u2a3-cfcg-i3-9082/p3.sh` (cwd `/tmp/u2a3-cfcg-i3-9082`, exit 0, 2026-10-07T00:28:55Z) and the threshold probe captured in `hs.log` (00:34:47Z, `n=65535 exit=0`, `n=65536 exit=153`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:596`, `/tmp/u2a3-cfcg-i3-9082/logs/p3.log`, `/tmp/u2a3-cfcg-i3-9082/logs/hs.log`

---

## Claim 27: "Main lacks p: under a directory link main stores (the checkout may lack it), fail."

**Location:** `scripts/lib/dev-cycle-read.sh:613-614`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `/`-bounded prefix of a main-lacked import path, checked against main's 120000 entries; does not cover case-variant prefixes (`LD/` vs `ld`, exact-case `ent`), which belong to the documented case-insensitive gap.

```bash
# scripts/lib/dev-cycle-read.sh:614
      for (( c = ${#p}; c > 0; c-- )); do [[ "${p:c:1}" != / || "${ent[${p:0:c}]:-}" != 120000 ]] || { IMPORTED_MAIN=error; return 1; }; done
```

Probes T1 (`@ld/i.md`), T2 (`@docs/ld2/i.md`), L8 and L12 give `walk: failed`. Mutant `f-parent-check` fails test 15.

Commands: `bash p2.sh` (2026-10-07T00:28:18Z); mutant loop (00:29:39Z).

**Evidence:** `scripts/lib/dev-cycle-read.sh:607-616`, `/tmp/u2a3-cfcg-i3-9082/logs/p2.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-f-parent-check.log`

---

## Claim 28: isimported: "Whether path $2 (any case) is imported, by the walk $1 names: tree or main. A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; ... Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:619-623`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `main`, `tree` and unknown arms and the case folding; does not establish any caller's wording of a failed walk (none exists yet).

```bash
# scripts/lib/dev-cycle-read.sh:624-633
isimported() {
  local lp
  need_root
  lp="$(lower "$2")"
  case "$1" in
    main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
    tree) imported_names; [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]] ;;
    *) return 0 ;;
  esac
}
```

Test 1 asserts `Docs/Imported.md imported`, and tests 2 and 8 the failed-walk answer. Test `isimported answers imported under if for a walk name it does not know` passes.

Command: suite run (Claim 17).

**Evidence:** `scripts/lib/dev-cycle-read.sh:619-633`, `/tmp/u2a3-cfcg-i3-9082/logs/build-loop-check.bats.log`

---

## Claim 29: Test-file header "the reader lib's import walks (... isimported, import_targets, main_imports)" and imps: "\"walk: ok\" or \"walk: failed\" (main_imports' return; tree always reads ok)"

**Location:** `test/scripts/build-loop-check.bats:3-4`, `test/scripts/build-loop-check.bats:13-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helper's output contract; does not cover the U2a4/U2b parts the header names as future.

The helper prints `if [[ "$w" != main ]] || main_imports; then echo "walk: ok"; else echo "walk: failed"; fi` (`test/scripts/build-loop-check.bats:19`), so a `tree` call always prints ok.

**Evidence:** `test/scripts/build-loop-check.bats:13-22`

---

## Claim 30: Each main-walk test's name and comments state what it asserts (tests at :46-:299)

**Location:** `test/scripts/build-loop-check.bats:46-308`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each test's assertions against its name, and that ten mutants of the guarded arms each fail at least one test. It does not establish that the first sub-case of test 9 ("A tracked directory symlink, present in the checkout, that an import passes through", `:182`) reaches the checkout-symlink arm: since e7b5d7ed it fails at the main-side parent check (`:614`), before the checkout is consulted. The later sub-cases of test 9 (untracked `docs/lt.md` link, symlinked CLAUDE.local.md) do exercise the checkout arm, so the name still holds. It also does not establish what the decoy `docs-rules.md` blob in test 9's NUL case is for (`:201`): dropping the NUL would give `docs/rules.mdzzz`, not `docs-rules.md`; the comment "follow another name" is still true.

I checked each name against its assertions; no false passes were found:
- `:46`: starts, untracked, working-tree edit
- `:63`: blob missing, not by name
- `:81`: three doubled shapes and two newline shapes, with an ls-tree count guard
- `:114`: follows
- `:141`: refusals and `..x`
- `:165`: under `if`, NUL
- `:177`: NUL text, checkout links, `chmod 000`, plain directory
- `:205`: returns-not-exits (`[ "$status" -eq 0 ]`) and the 64 KiB read (`isimported main docs/last.md`)
- `:226`, `:236`, `:253`, `:267`, `:277`, `:299`

Each of the ten mutants fails at least one test (`mut-*.log`):
- `a-nested-rules-start`: test 6
- `b-checkout-read-guard`: test 9
- `c-tr-length-check` and `j-here-string`: test 10
- `d-link-escape-guard`: test 7
- `e-dotdot-after-link`, `f-parent-check` and `g-checkout-L-half`: test 15
- `h-cache-key-mbn` and `i-reset-to-error`: test 16

Commands: the suite run (Claim 17, 16/16 ok) and `for m in ...; do python3 -I mutants.py LIB $m m-$m/scripts/lib/dev-cycle-read.sh; (cd m-$m && TMPDIR=... bats test/scripts/build-loop-check.bats); done` · cwd `/tmp/u2a3-cfcg-i3-9082` · each bats exit 1 · 2026-10-07T00:29:39Z.

**Evidence:** `test/scripts/build-loop-check.bats:46-308`, `/tmp/u2a3-cfcg-i3-9082/mutants.py`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-a-nested-rules-start.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-j-here-string.log`

---

## Claim 31: fbeae280: "Tests: build-loop-check.bats 14; 112 across the five suites. Mutants of the nested-rules start, the checkout-read guard, the tr length check (via a failing tr shim) and the link-escape guard each fail. 344 changed code lines against U2a2."; B2, B3, B8, B12 bullets

**Location:** commit fbeae280
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at fbeae280, the line count, the B-bullet behaviours (at HEAD) and the four named mutants (run against HEAD's tests, which keep those assertions). The B5 bullet's test numbering and the Notes line are recorded Accepted-immutable at `docs/reviews/override-log.md:367` and not re-verdicted.

`git show fbeae280:<suite> | grep -c '^@test'` gives 14 for build-loop-check.bats, and 112 over the five suites (dev-cycle, build-loop-read, build-loop-check, fixture-git-env, `test/fixture-hermeticity.bats`, as in iteration 1's E1). `git diff --numstat main...fbeae280 -- . ':!docs'` sums to 344, and U2a2 is main (fbeae280's parent is 62d366a7). The four named mutants (a, b, c, d) each fail (Claim 30).

**Evidence:** commit fbeae280, `/tmp/u2a3-cfcg-i3-9082/logs/mut-a-nested-rules-start.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-b-checkout-read-guard.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-c-tr-length-check.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-d-link-escape-guard.log`

---

## Claim 32: 45ad17b0 "A5 names U2a3 as main_imports' unit"; 277b2fab / cb4ebbc8 "review artifacts and override rows"

**Location:** commits 45ad17b0, 277b2fab, cb4ebbc8
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each commit contains what its subject names; does not re-verdict the contents of the review reports they add.

A5 reads "The gate's walk (`main_imports`, U2a3)" (`docs/working/known-issues-dev-cycle.md:18`). The two docs commits add the iteration-1/2 reports, rubric and override rows (paraphrased — no quote available because the claim is about which files a commit adds; `git show --stat`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, commits 277b2fab, cb4ebbc8

---

## Claim 33: 4f087967: "Tests: one new in build-loop-check.bats (15); 113 across the five suites. A mutant dropping the new check fails it. 369 changed code lines against main."

**Location:** commit 4f087967
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts, line total and mutant; the "resolved a component at a time" wording is recorded Accepted-immutable at `docs/reviews/override-log.md:380`.

The counts are 15 / 113 at 4f087967 and the line total is 369 (`git diff --numstat main...4f087967`). Mutant `e-dotdot-after-link` fails test 15.

**Evidence:** commit 4f087967, `/tmp/u2a3-cfcg-i3-9082/logs/mut-e-dotdot-after-link.log`

---

## Claim 34: 34edec56 subject: "the not-covered symlinked-directory gap names @ tokens, not link text"

**Location:** commit 34edec56
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Pointer only: already recorded Accepted-immutable at `docs/reviews/override-log.md:380` (link text through a directory link main stores failed open at that commit). The current code fails both, at `scripts/lib/dev-cycle-read.sh:614`.

The row reads: "34edec56's subject says the symlinked-directory gap names @ tokens, not link text (false: link text through a directory link main stores failed open)" (`docs/reviews/override-log.md:380`).

**Evidence:** `docs/reviews/override-log.md:380`

---

## Claim 35: e7b5d7ed: "build-loop-check.bats 16; 114 across the five suites. Mutants of the parent check, the checkout -L half, the cache key and the reset to error each fail. 398 changed code lines against main."; the G1-G6 test list

**Location:** commit e7b5d7ed
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts, line total, the four mutants (run at HEAD) and that each listed test shape exists; does not cover the isimported-comment sentence (Claim 36).

The counts are 16 / 114 at e7b5d7ed and the line total is 398. Mutants f, g, h and i each fail (Claim 30). The 100755 arm (`chmod +x real.md docs/a+b.md`, `:125`), a main blob over a checkout edit (`printf 'gone\n' > docs/a+b.md`, `:128`), untracked rules starts, a chain (`ln -s docs/c1.md GEMINI.md && ln -s c2.md docs/c1.md`), the checkout `..` half, link and token through `ld` (`:287-292`) and the cache (`:299`) are all present.

**Evidence:** commit e7b5d7ed, `test/scripts/build-loop-check.bats:114-139`, `test/scripts/build-loop-check.bats:277-308`

---

## Claim 36: e7b5d7ed: "isimported's comment says start files answer imported only when an import reaches them (architecture F2)"

**Location:** commit e7b5d7ed
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the sentence lives; the sentence's truth is Claim 19.

The sentence is in main_imports' block comment above `IMPORTED=` ("A start file answers imported only when an import reaches it (U2a4's floor names start files by its own rules)", `scripts/lib/dev-cycle-read.sh:465-466`). isimported's own comment (`:619-623`) does not carry it. Precise version: "main_imports' comment says ...".

**Evidence:** `scripts/lib/dev-cycle-read.sh:465-466`, `scripts/lib/dev-cycle-read.sh:619-623`

---

## Claim 37: 2a3e499f: "the not-covered list points to A5's three untraced shapes"

**Location:** commit 2a3e499f
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lib comment and A5's list; does not cover the untraced shapes themselves.

The lib comment reads "three shapes A5 lists as untraced against Claude Code (command references, a link's own directory, a token's ..)" (`scripts/lib/dev-cycle-read.sh:470-471`). A5 lists the same three.

**Evidence:** `scripts/lib/dev-cycle-read.sh:467-471`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 38a: c42f017f: "bash writes a here-string past 64 KiB to a temp file, and a failed write ... read as no imports, so the walk answered ok without them"

**Location:** commit c42f017f
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fail-open mechanism for a write that fails without killing bash (full disk, or SIGXFSZ ignored); the `ulimit -f 0` example is Claim 38b.

The threshold probe gives `n=65535 exit=0`, `n=65536 exit=153` under `ulimit -f 0`. With SIGXFSZ ignored, `while read ... done <<<"$x"` (70 KB) prints `cannot create temp file for here-document: File too large` and `rc=1 n=0`: the loop body never runs, which is "read as no imports".

Command: threshold loop plus `timeout 20 bash /tmp/u2a3-cfcg-i3-9082/h3.sh` · cwd `/tmp/u2a3-cfcg-i3-9082` · exit 0 · 2026-10-07T00:34:47Z.

**Evidence:** `/tmp/u2a3-cfcg-i3-9082/logs/hs.log`, `/tmp/u2a3-cfcg-i3-9082/h3.sh`

---

## Claim 38b: c42f017f: "a failed write (ulimit -f 0, ...) read as no imports"

**Location:** commit c42f017f
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old code under `ulimit -f 0` with default signal dispositions (how the test runs it); does not affect the fix, which avoids the temp file either way.

Under `ulimit -f 0`, the temp-file write raises SIGXFSZ and bash dies (exit 153). It is not a quiet empty read. Mutant `j-here-string` (old `done <<<"$out"`) fails test 10 with `# 153` as its status (`mut1.log`, `mut-j-here-string.log`). The test still kills the mutant, but by a crash, not by the fail-open answer the message describes. "Read as no imports" needs a write that fails without the signal (Claim 38a). Commit message, immutable: recorded here for an override row.

Command: `cd /tmp/u2a3-cfcg-i3-9082/mut1 && TMPDIR=... bats -f '64 KiB' test/scripts/build-loop-check.bats` · exit 1 (test failed with status 153) · 2026-10-07T00:26Z.

**Evidence:** `/tmp/u2a3-cfcg-i3-9082/logs/mut1.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-j-here-string.log`, `/tmp/u2a3-cfcg-i3-9082/logs/hs.log`

---

## Claim 39: c42f017f: "It now reads through process substitution"; nul_list "used for main's tree and the untracked list"; "the return-1 comment names every cause in this unit's code, including an import of the repo root and a FIFO ..., and that need_root exits"; "the A2 test also reads a 67 KB import list under ulimit -f 0 (the here-string mutant fails it); build-loop-check.bats 16; 114 across the five suites. 400 changed code lines against main"; the Docs line

**Location:** commit c42f017f
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed atom. Two residues are not established: "every cause" counts return-1 paths only (the `:596` here-string's kill/skip is not a return; Claim 26), and "the here-string mutant fails it" happens by a crash (Claim 38b).

The import loop ends `done < <(printf '%s\n' "$out")` (`scripts/lib/dev-cycle-read.sh:616`), and the nul_list call sites are at `:556` and `:564`. The return-1 causes are mapped in Claim 23. The import list in test 10 is 320 lines of `docs/<200 digits>.md` plus `docs/last.md`, about 66.9 KB after `import_targets` (above 64 KiB). Counts at c42f017f are 16 / 114, and the suite run at HEAD gives 16 + 19 + 75 + 2 + 2 = 114, all ok. `git diff --numstat main...HEAD -- . ':!docs'` gives 120+9 + 265+2 + 2+2 = 400. The plan's U2a3 bullet lists the parent-link refusal, and A5 has the tracked-in-checkout sentence.

Command: suite loop `for t in <five suites>; do TMPDIR=$(mktemp -d ...) bats $t; done` · cwd worktree · each exit 0 · 2026-10-07T00:25:07Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:556`, `scripts/lib/dev-cycle-read.sh:564`, `scripts/lib/dev-cycle-read.sh:616`, `test/scripts/build-loop-check.bats:219-223`, `/tmp/u2a3-cfcg-i3-9082/logs/build-loop-check.bats.log`, `/tmp/u2a3-cfcg-i3-9082/logs/dev-cycle.bats.log`, `/tmp/u2a3-cfcg-i3-9082/logs/build-loop-read.bats.log`

---

## Claim 40: cc1aa864: "finding declined: the root and FIFO causes go through the generic not-plain arm, probed"

**Location:** commit cc1aa864 (and `docs/reviews/lite-review-fix-drift-build-loop-u2a3-i3.txt`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the root (token and link text) and a FIFO import target; does not cover an untracked FIFO start, which is never listed and so never read.

Both reach `elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1` (`scripts/lib/dev-cycle-read.sh:580`). Probes P1 and P2 give `walk: failed` (Claim 23). The fix-drift finding's premise ("no explicit checks for FIFO files or root-directory paths") is true but beside the point: the generic arm covers both.

Command: `bash /tmp/u2a3-cfcg-i3-9082/p1.sh` · cwd `/tmp/u2a3-cfcg-i3-9082` · exit 0 · 2026-10-07T00:27:39Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:576-581`, `/tmp/u2a3-cfcg-i3-9082/logs/p1.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 26** (`scripts/lib/dev-cycle-read.sh:596`): a second here-string (`IFS=/ read -ra parts <<<"$out"`) remains in main_imports. Link text of 65,535+ bytes goes to a temp file. Under `ulimit -f 0` bash is killed (exit 153). A write that fails quietly skips the `..`-after-symlink check, and the walk answers ok (executed, P4c). The link cannot exist on disk, so no real load is missed. Low severity, but "Fixed" for I2-C4 does not make the unit free of here-strings.
- **Claim 34** (commit 34edec56): already Accepted-immutable, `override-log.md:380`.
- **Claim 38b** (commit c42f017f): under `ulimit -f 0` the old here-string killed bash (SIGXFSZ, exit 153) rather than reading as no imports. The test kills the mutant by that crash. The message is immutable and needs an override row.

### Stale
- None.

### Mostly Accurate
- **Claim 7** (`override-log.md:374`): `lower` is not the only unguarded command. The link-text here-string read at `:596` has no failure arm.
- **Claim 11** (`override-log.md:379`): a blob+tree name fails the walk only when an import reaches a path below it; otherwise the walk is ok.
- **Claim 36** (commit e7b5d7ed): the start-file sentence went into main_imports' block comment (`:465`), not isimported's.

### Unverifiable
- None. Timings in override rows `:365`, `:377` and `:378` were not re-measured; they are scoped out of Claims 1, 9 and 10.

## Escalations

- `scripts/lib/dev-cycle-read.sh:596` (addressee: the U2a3 author / review-fix loop). The link-text split uses a here-string. Reading it through process substitution, or giving the read a failure arm (`|| { IMPORTED_MAIN=error; return 1; }`), would make it fail closed, as `:616` now does. Severity Low: unreachable through a materialisable symlink. Optional: name it in the return-1 comment's exit sentence or the `:381` row.
- Commit c42f017f, I2-C4 bullet (addressee: override-log keeper). The `ulimit -f 0` example is incorrect (Claim 38b). Commit messages are immutable, so this wants an Accepted-immutable row like `:367` and `:380`.
- `docs/reviews/override-log.md:374` and `:379` (addressee: override-log keeper). Tighten as stated in Claims 7 and 11 if the rows are edited again.
- `test/scripts/build-loop-check.bats:182` (addressee: test author, informational). The first sub-case of test 9 now fails at main's parent-link check, not at the checkout-symlink arm its test name advertises. Later sub-cases cover that arm, so this is no false pass.

## Goal-Alignment Note

**Success criterion (verbatim):** A code-fact-check report verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages, saved at the path given below.

**Answered:**
- All nine requested items are verdicted: block and return-1 comments (Claims 19, 20, 23), nul_list and I2-C4 (22, 26, 38a/b, 39), Inputs (17), both loops (25, 27), isimported (28), every commit message (31-40, with pointers to rows `:367` and `:380`), A5/F11/U2a3/U2b (13-15), test names (30) and the override rows (1-12).
- Execution covered all five suites (114 ok), ten mutants (each killed) and eight probe scripts.
- No checkout state was found that removes an import relative to main alone.
- Nothing fails open beyond A5's list except the unmaterialisable 64 KiB+ link-text case.

**Out of scope:**
- Claude Code's own resolution (A5's three untraced shapes).
- U2a3b's parser and fail-closed changes (stacked).
- The timings in performance rows.
- The U2a4 floor that F11 and A5 describe.

**Escalate:** Claim 26 (Low) and Claim 38b (commit-message override row). Neither blocks merge on fact-check grounds: there is no Incorrect claim about reachable behaviour.
