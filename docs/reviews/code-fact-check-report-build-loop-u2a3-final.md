Commit: cc1aa864

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`)
**Scope:** `git diff main...HEAD` (main 62d366a7, HEAD cc1aa864): comments in `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`; `docs/working/known-issues-dev-cycle.md` A5; `docs/working/plan-build-loop-handoff.md` F11 and the U2a3/U2b bullets; the 2026-10-06 `feat/build-loop-u2a3` rows of `docs/reviews/override-log.md`; every commit message on main..HEAD. Role `cfcg`, pass `i3`. Merged from `docs/reviews/code-fact-check-report-build-loop-u2a3-f-r1.md`, `-f-r2.md`, `-f-r3.md` (most-severe-wins, annotations by union).
**Checked:** 2026-10-06 (replicate executions 2026-10-07T00:25Z-00:35Z UTC)
**Total claims checked:** 51
**Summary:** 30 verified, 12 mostly accurate, 0 stale, 9 incorrect, 0 unverifiable
**Commit:** cc1aa864
**Replication:** k=3

Merge notes. This report is mechanical collation of the three replicate reports; it adds no claims or evidence. Clusters are emitted at the finest granularity any replicate used. A replicate that verdicted only a compound has that verdict recorded on each sub-claim row, marked `(compound)`, and that verdict competes in most-severe-wins. One exception applies: where the compound replicate's own text assigns an enum verdict to a specific atom (r2 Claim 27: "The figures are Verified"; r2 Claim 22: "The process-substitution half is Verified"), that stated verdict is recorded for that atom. Claims 20, 25 and 46 take their winning verdict only from a compound entry; the annotations say which. Execution provenance (commands, cwd, exit codes, timestamps, captured outputs) is in each replicate report: r1 under `/tmp/u2a3-cfcg-i3-9082/logs/`, r2 under `/tmp/u2a3-cfcg-i3-WrT9/logs/`, r3 under `/tmp/u2a3-cfcg-i3-CgDN/logs/`. All three ran the five suites at HEAD: 114 ok. Each replicate's mutants were all killed (r1: 10, r2: 5, r3: 13).

---

## Claim 1: override row — "main_imports checks every tree record in bash (mapfile, a regex and a map assignment per entry): 0.4-0.5 s here … ~2.1 s at 30k entries"

**Location:** `docs/reviews/override-log.md:365`
**Type:** Performance / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the per-record mechanism and that the whole walk takes under 0.7 s on this repo. It does not establish the 0.4-0.5 s figure for the record phase alone, the ~2.1 s figure at 30k entries, or the awk prototype's ~5x.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3: "does not establish the quoted timings, which were not re-measured" · r2: "E4 timed the whole walk at 0.61-0.70 s with 2966 entries … The phase itself was not isolated."

Carried from r2 Claim 1: the records come through `nul_list recs git ls-tree -r -z --full-tree "$MAIN_SHA"`, and each record pays a regex test and a map store `ent[$f]="${BASH_REMATCH[1]}"` (`scripts/lib/dev-cycle-read.sh:556-561`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:556-563`, `/tmp/u2a3-cfcg-i3-WrT9/logs/E4-timing.txt`

---

## Claim 2: override rows — a submodule's files are not starts because "`ls-tree -r` does not enter a gitlink (not `*) continue`)" (superseding the D8 row)

**Location:** `docs/reviews/override-log.md:366`, `docs/reviews/override-log.md:373`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers why a submodule's instruction files never enter `cand` (the start list is built only from ls-tree records and the untracked list); does not establish Claude Code's own loading of a submodule's CLAUDE.md, or the row's exposure statement about parent-repo files.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: untracked nested repo executed (P1 Q6: `walk: ok docs/n.md: -`); "does not establish what Claude Code loads from either" · r3: gitlink half is "git's listing behaviour, not repo code" (paraphrased)

Carried from r1 Claim 2: starts come only from `[[ "$f" != *.[mM][dD] ]] || cand+=("m:$f")` (`scripts/lib/dev-cycle-read.sh:562`) and `cand+=("t:$f")` (`:565`). The `*) continue ;;` arm (`:606`) is reached only for a gitlink that is itself queued (paraphrased — no quote available because gitlink non-entry is git's documented ls-tree behaviour, not repo code).

**Evidence:** `scripts/lib/dev-cycle-read.sh:556-565`, `scripts/lib/dev-cycle-read.sh:606`, `docs/reviews/override-log.md:366`, `docs/reviews/override-log.md:373`

---

## Claim 3: override row — "`CLAUDE.md -> docs/real.md` holding `@x.md` records docs/x.md, not x.md"

**Location:** `docs/reviews/override-log.md:369`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's side of the row (which path it records); does not establish how Claude Code resolves a symlinked instruction file's imports (the row's Defer premise, untraced).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

Carried from r1 Claim 3: the queued target is read with `d` set to its own directory (`if [[ "$f" == */* ]]; then d="${f%/*}"`, `scripts/lib/dev-cycle-read.sh:575`). Probe P6/R5: `walk: ok`, `docs/x.md: imported`, `x.md: -`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:575`, `scripts/lib/dev-cycle-read.sh:587-603`, `/tmp/u2a3-cfcg-i3-9082/logs/p6.log`

---

## Claim 4: override row — "`.claude/commands/*.md` files are not start files … (walk ok, docs/c.md `-`)"

**Location:** `docs/reviews/override-log.md:370`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's answer for a committed `.claude/commands/c.md` referencing `@docs/c.md`; does not establish whether Claude Code loads command references (untraced, A5).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

Carried from r1 Claim 4: the start rule `[[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]` (`scripts/lib/dev-cycle-read.sh:570`) matches no `.claude/commands/` name. Probe P6/R6: `walk: ok`, `docs/c.md: -`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:568-573`, `/tmp/u2a3-cfcg-i3-9082/logs/p6.log`

---

## Claim 5: override row and A5 — "An `@ld/../q.md` token with `ld` a directory link is recorded as q.md … even with the link in the checkout"; "the walk is lexical, as Node's path.resolve"

**Location:** `docs/reviews/override-log.md:371`, `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's lexical treatment of an `@` token's `..` (tokens resolve through `import_targets`' `realpath -ms`, never the link-text component loop); does not establish how Claude Code resolves the token (untraced, A5).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: Node check executed (`require("path").resolve("/r/ld/../q.md")` printed `/r/q.md`, P2 R6)

Carried from r1 Claim 5: the token path is normalised by `p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)" || continue` (`scripts/lib/dev-cycle-read.sh:506`). Probe P6/R7: `walk: ok`, `q.md: imported`, `deep/q.md: -`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:495-511`, `/tmp/u2a3-cfcg-i3-9082/logs/p6.log`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes2.txt`

---

## Claim 6: override row — "The walk's cache key ignores the checkout …"; "a caller whose checkout changes sets IMPORTED_MAIN_DONE=\"\""

**Location:** `docs/reviews/override-log.md:372`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key's three fields and the clear-to-rewalk contract; does not establish any future caller's compliance (no caller until U2a4).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

Carried from r1 Claim 6: `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` (`scripts/lib/dev-cycle-read.sh:552`). Probe P8 (query, add untracked CLAUDE.local.md, query, clear, query): `docs/n.md: -`, `-`, `imported`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:552-553`, `/tmp/u2a3-cfcg-i3-9082/logs/p8.log`

---

## Claim 7: override row — "Every failure path sets IMPORTED_MAIN=error before returning; the known unguarded command (lower) is fixed in U2a3b"

**Location:** `docs/reviews/override-log.md:374`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` in main_imports (each sets or inherits `error`) and the unguarded commands in the unit; does not establish U2a3b's fix of `lower` (stacked, not under review).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r3: the link-text here-string `IFS=/ read -ra parts <<<"$out"` (`:596`) is a second unguarded command; past 64 KiB with a soft temp-file failure the `..` check is skipped and the walk answers ok; unreachable through a real symlink (PATH_MAX) · r2: `grep` in `import_targets` (`:508`, `< <(env LC_ALL=C grep -aoE "$IMPORT_RE" || true)`) is also unguarded; a grep shim exiting 2 gave `walk: ok docs/a.md: -` (P2 R3); "Per the shared context, both are fixed in U2a3b (stacked)"

Carried from r1 Claim 7: every `return 1` before `:574` inherits `IMPORTED_MAIN=error` from `:553`, and every later one is written `{ IMPORTED_MAIN=error; return 1; }`, so the first sentence holds. `lower` is not the only unguarded command. Precise version: "...the known unguarded commands are lower (fixed in U2a3b) and the link-text here-string read at :596".

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-617`, `scripts/lib/dev-cycle-read.sh:508`, `/tmp/u2a3-cfcg-i3-9082/logs/p3.log`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes2.txt`

---

## Claim 8: override row — "the three copies now agree (lib, A5, F11 edited together in iteration 2) and F11 names all three checkout inputs"

**Location:** `docs/reviews/override-log.md:375`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal and not-covered lists in the lib block comment, A5 and F11 against each other; does not establish that the floor (U2a4), which F11 also mentions, behaves as F11 says.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "F11 and A5 lump the doubled and newline names together ('odd names' in A5)"

Carried from r1 Claim 8: F11 says "The walk reads the checkout for its untracked starts, for targets main lacks, and for whether a path it would read is a symlink" (`docs/working/plan-build-loop-handoff.md:126`); the refusal lists match item for item.

**Evidence:** `scripts/lib/dev-cycle-read.sh:458-471`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 9: override row — "untracked_md lists ignored files too (needed for CLAUDE.local.md)"

**Location:** `docs/reviews/override-log.md:377`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the listing command; does not establish the row's timings (0.35 s / ~4 s), which were not re-measured.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** none

Carried from r1 Claim 9: `untracked_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; }` (`scripts/lib/dev-cycle-read.sh:517`), with no `--exclude-standard`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:515-517`

---

## Claim 10: override row — "Each symlink the walk follows costs ~12 ms (two cat-file reads and a realpath per link-text component)"

**Location:** `docs/reviews/override-log.md:378`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-link work: two `git cat-file blob` calls, one realpath fork per component and a final realpath; does not establish the 12 ms figure, which was not re-measured.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

Carried from r1 Claim 10: `git cat-file blob "$MAIN_SHA:$f"` appears twice at `scripts/lib/dev-cycle-read.sh:590-591`, then `p="$(realpath -ms … "$ROOT_REAL/${p:+$p/}$c" …)"` per component and one final `realpath` on `out`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:587-603`

---

## Claim 11: override row — "A name main stores as both a blob and a tree fails the walk closed but prints git's `fatal:` line on stderr"

**Location:** `docs/reviews/override-log.md:379`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a tree holding blob `n` and tree `n` (git mktree sorts them blob-first) with and without an import below `n`; does not establish other orders, which git's tree sort prevents.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: `@x` (import of the name itself) gave `walk: ok` and read the blob; "does not establish what a checkout of such a tree writes" · r3: "does not establish the outcome when no import reaches the colliding name (the walk then never reads it)"

Carried from r1 Claim 11: with no import below the name, P6/R15 gives `walk: ok`. With `@n/y.md`, P7 gives `fatal: path 'n/y.md' does not exist in '<sha>'` and `walk: failed`. Precise version: "...fails the walk closed, with git's `fatal:` line, when an import reaches a path below that name; otherwise the walk is ok and reads nothing there."

**Evidence:** `scripts/lib/dev-cycle-read.sh:558-561`, `scripts/lib/dev-cycle-read.sh:584`, `/tmp/u2a3-cfcg-i3-9082/logs/p6.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p7.log`

---

## Claim 12: override row (I2-C4, Fixed) — the here-string "goes to a temp file past 64 KiB, and a failed write read as no imports … Process substitution (tested under ulimit -f 0, mutant killed) … the return-1 comment lists every cause … including the root and a FIFO (probed); A5 names the tracked-in-checkout start"

**Location:** `docs/reviews/override-log.md:381`
**Type:** Error-handling / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fix (process substitution), its test and mutant, and the root/FIFO causes; does not establish that the walk has no other temp-file path (it has one, Claim 34).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "does not establish that the walk has no other here-string (it has one, at `:596`)"; mutant `j-here-string` fails test 10 with status 153 · r2: "does not establish the U2a3b-side rows" · r3: "under plain `ulimit -f 0` the old code did not 'read as no imports'; bash was killed by SIGXFSZ … status 153"; silent loss only with SIGXFSZ ignored or a full disk

Carried from r3 Claim 6: HEAD reads a 67 KB import list whole under `ulimit -f 0` with or without SIGXFSZ ignored, and the here-string mutant fails test 10 (`not ok 10 ... failed # 153`). The failure mechanism in the row is imprecise for plain `ulimit -f 0`. Root and FIFO: probed `walk: failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:616`, `/tmp/u2a3-cfcg-i3-CgDN/logs/herestring-importlist-probe.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/mut-herestring.txt`

---

## Claim 13: A5 refusal list — "odd names, link text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, … or a checkout symlink the walk would read fail it" and "closes A2 and A3's symlinked-file half"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal (all fail the walk); does not establish the untraced Claude Code behaviours A5 names, and the list is not complete: the walk also fails on other non-plain checkout paths.
**Replicate verdicts:** r1=Verified · r2=— · r3=Mostly accurate
**Replicate annotations:** r1: "does not establish … the case where link text 'leaves the repo' and comes back by the root's own directory name (probe L9: `../r2/evil.md` from repo `r2` is followed as `evil.md`)" · r2: (Claim 11) "Whether A5's refusal list holds is verdicted in Claims 17-19" · r3: omits the root and FIFO arm; precise list adds "an import naming the repo root, or a checkout path that is neither a plain file nor a plain directory (a FIFO)"

Carried from r3 Claim 1: the list omits the generic arm `elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1` (`scripts/lib/dev-cycle-read.sh:582`). An `@.` token, link text `sub/..` and a FIFO at an imported path each print `walk: failed`. A5 understates the refusals (fails closed).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:556-614`, `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt`

---

## Claim 14: A5 not-covered gaps — "start files under a symlinked directory or in a submodule or untracked nested repo … an instruction file the checkout tracks but main lacks is not a start: `ls-files --others` skips it"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal (all fail the walk) and A5's not-covered list; does not establish the untraced Claude Code behaviours A5 names, and the list is not complete: the walk also fails on other non-plain checkout paths.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Mostly accurate (compound)
**Replicate annotations:** r3: the compound's Mostly accurate is attributed in r3's text to the refusal list's root/FIFO omission (Claim 13); "The not-covered half holds" · r2: P1 Q6 (nested repo) and Q7 (tracked in checkout, absent from main: `walk: ok docs/t.md: -`) reproduce the stated behaviour · r1: P6/A5 `walk: ok`, `docs/t.md: -`

Carried from r3 Claim 1: an untracked nested repo's `AGENTS.md` and a start file under a checkout directory symlink are not listed by `ls-files --others` (walk ok, imports `-`); `untracked_md` is `ls-files --others` (`scripts/lib/dev-cycle-read.sh:517`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:517`, `/tmp/u2a3-cfcg-i3-CgDN/logs/listings-probe.txt`

---

## Claim 15: Plan F11 — the walk's refusal list "... fails the walk, so floor refuses every path"; "The walk reads the checkout for its untracked starts, for targets main lacks, and for whether a path it would read is a symlink"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers F11's refusal list, gap list and three checkout inputs against the code; does not establish U2a4's floor (not yet written) beyond `isimported main` answering imported on a failed walk.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "does not establish 'so floor refuses every path', which describes U2a4's floor" · r2: "the checkout's untracked files as starts" means untracked instruction and `.claude/rules` files only (`:571`); does not cover the refusal items in Claims 24 and 26 · r3: omits the root/FIFO arm; the checkout-input list leaves out the link-text component lstat (`:600`), which only adds failures

Carried from r3 Claim 2: same root/FIFO omission as Claim 13; also `[[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1` (`scripts/lib/dev-cycle-read.sh:600`) lstats every component path whether or not the walk would read it.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:580-583`, `scripts/lib/dev-cycle-read.sh:596-600`, `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt`

---

## Claim 16: Plan U2a3 bullet — "It refuses the tree and link shapes it does not model (a doubled name, a name holding a newline, symlink text that is empty, absolute, leaves the repo, …, a checkout symlink it would read)"

**Location:** `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape; does not establish completeness (the root and FIFO arm is unlisted), nor the bullet's carried-rows bookkeeping beyond its match with fbeae280's message.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "does not establish the bullet's 'carries ... B14' bookkeeping beyond fbeae280's own note" · r2: does not cover the refusal items in Claims 24 and 26 · r3: root/FIFO arm unlisted

Carried from r3 Claim 3: an import naming the root, or a checkout FIFO, fail through `elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1` (`scripts/lib/dev-cycle-read.sh:582`), which the bullet does not list.

**Evidence:** `docs/working/plan-build-loop-handoff.md:276`, `scripts/lib/dev-cycle-read.sh:582`, `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt`

---

## Claim 17: Plan U2b bullet — "the walk reads its untracked starts, targets main lacks, and checkout symlinks"

**Location:** `docs/working/plan-build-loop-handoff.md:278`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three classes of checkout read in `main_imports`; does not establish U2b's future `--check` code.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

Carried from r3 Claim 4: untracked starts `nul_list recs untracked_md` (`scripts/lib/dev-cycle-read.sh:564`); targets main lacks `queue+=("t:$p")` (`:615`); checkout symlinks `! -L "$p"` (`:600`) and `-L "$f"` (`:582`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:564`, `scripts/lib/dev-cycle-read.sh:580-583`, `scripts/lib/dev-cycle-read.sh:600`, `scripts/lib/dev-cycle-read.sh:615`

---

## Claim 18: Header — "the instruction-file import walks"; "… isimported and the import walks exit 1 (need_root) unless ROOT_REAL is set"

**Location:** `scripts/lib/dev-cycle-read.sh:6`, `scripts/lib/dev-cycle-read.sh:15`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both walks calling need_root; does not cover need_root's own messages (unchanged, outside the diff).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 16: `main_imports` calls `need_root` on its third line (`scripts/lib/dev-cycle-read.sh:551`); `imported_names` does the same at `:522`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:95-99`, `scripts/lib/dev-cycle-read.sh:522`, `scripts/lib/dev-cycle-read.sh:551`

---

## Claim 19: Header Inputs — the checkout reads "can only add imports or fail it"

**Location:** `scripts/lib/dev-cycle-read.sh:29-35`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one checkout state that turns main's own failure into an ok walk, and the code path that allows it. It does not establish other such states (none others found among the shapes probed in P1-P3).
**Replicate verdicts:** r1=Verified (compound) · r2=Incorrect · r3=Verified
**Replicate annotations:** r1: "I looked for a checkout state that removes an import relative to main alone and found none"; "does not establish the cache's freshness against later checkout changes" · r2: "Practical exposure is bounded: the paths exposed this way are start-shaped names … under the link target. The floor names those through other items (F9, and `.claude/` per row :370)" · r3: "No removal found"; "does not establish behaviour on a case-insensitive checkout"

Carried from r2 Claim 13 (P1 Q3): main holds `ld -> deep` and a CLAUDE.md with `@ld/CLAUDE.md`. Main alone: `walk: failed`. With an untracked `ld/CLAUDE.md` in a checkout where `ld` is a plain directory: `walk: ok deep/CLAUDE.md: - ld/CLAUDE.md: imported docs/z.md: imported`. Starts are marked seen before the walk (`seen[${cand[i]:2}]=1`, `:572`), and the parent-link check runs only after `[[ -z "${seen[$p]+set}" ]] || continue` (`scripts/lib/dev-cycle-read.sh:610-614`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-574`, `scripts/lib/dev-cycle-read.sh:607-616`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt`

---

## Claim 20: Header Inputs — the checkout reads named are "untracked start files, imported files main lacks and whether a path it would read is a symlink there"

**Location:** `scripts/lib/dev-cycle-read.sh:29-35`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one checkout state that turns main's own failure into an ok walk, and the code path that allows it. It does not establish other such states (none others found among the shapes probed in P1-P3).
**Replicate verdicts:** r1=Verified (compound) · r2=Incorrect (compound) · r3=Mostly accurate
**Replicate annotations:** merge: the Incorrect is r2 Claim 13's compound verdict, whose text locates it on Claim 19's invariant; the atom-level verdict is r3's · r3: "Two checkout reads go beyond 'whether a path it would read is a symlink': the link-text loop lstat's each component path … (`:600`), and the walk tests a path's type, not only symlink-ness (`:582`, which fails a FIFO or the root)"; precise version "...and the type of a path it would read, or that link text passes through"; "does not affect Claim 10's invariant"

Carried from r2 Claim 13: see Claim 19 (same evidence: P1 Q3, `scripts/lib/dev-cycle-read.sh:572`, `:610-614`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-574`, `scripts/lib/dev-cycle-read.sh:582`, `scripts/lib/dev-cycle-read.sh:600`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt`

---

## Claim 21: Header Inputs — main_imports "needs resolve_main to have found main by name, or it fails"

**Location:** `scripts/lib/dev-cycle-read.sh:33-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main_by_name gate and its caching. It does not establish resolve_main's own candidate order.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** none

Carried from r2 Claim 14: `main_by_name || return 1` (`:555`) runs after `IMPORTED_MAIN=error` (`:554`). Test 2's `trunk` case passes (`walk failed`); mutant `nokeybyname` shows the cache key is what makes test 16's `MAIN_BY_NAME=""` case walk again.

**Evidence:** `scripts/lib/dev-cycle-read.sh:553-555`, `/tmp/u2a3-cfcg-i3-WrT9/logs/bats-build-loop-check.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-nokeybyname.txt`

---

## Claim 22: Block comment — "it starts at every instruction file stored there (and every .md under a .claude/rules/ directory at any depth …), plus the checkout's untracked ones, and follows an import into the file main stores at that path, whatever its name; a symlink there is followed …"

**Location:** `scripts/lib/dev-cycle-read.sh:453-458`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers starts (any case, nested rules, tracked and untracked), follows into main blobs of any name and mode 100644/100755/120000, and checkout reads for targets main lacks; does not establish Claude Code's own start set (A5's untraced shapes).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 18: the start test is `if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]` (`scripts/lib/dev-cycle-read.sh:570`); `*` matches `/`, so `.claude/rules/a/b.md` starts. Tests 6 and 11 pass; mutant `a-nested-rules-start` fails test 6.

**Evidence:** `scripts/lib/dev-cycle-read.sh:562-616`, `test/scripts/build-loop-check.bats:114-139`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-a-nested-rules-start.log`

---

## Claim 23: Block comment refusal list — "a doubled name, a name holding a newline …, symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink, … and a checkout path it would read that is a symlink or lies under one fail the walk, so isimported main answers imported for every path"

**Location:** `scripts/lib/dev-cycle-read.sh:458-465`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal and the isimported consequence; does not establish completeness: the root and FIFO arm is unlisted here (the return-1 comment at :538-548 lists it).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1: does not establish the `..` check for link text of 65,535+ bytes when the here-string's temp file cannot be written (Claim 34); "a checkout path it would read ... lies under one" applies only when the path exists: an absent path under a checkout link reads nothing and the walk continues (probes P3, P3b: `walk: ok`) · r2: "The list is not exhaustive (it omits the root and a FIFO, which the return-1 comment names), but it does not claim to be" · r3: precise ending "...a checkout path it would read that is not a plain file or plain directory below the root (a symlink, under one, the root, a FIFO)"

Carried from r3 Claim 13: all listed refusals fail (tests 5, 7, 9, 12, 15; seven guard mutants each `rc=1`). An import of the repo root or a checkout FIFO also fails, through `:582`, and the list does not name it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:458-465`, `scripts/lib/dev-cycle-read.sh:556-614`, `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/dup-blobtree-probe.txt`

---

## Claim 24: "an import path main lacks under a directory main stores as a symlink … fail[s] the walk" (block comment; return-1 comment; A5; F11; U2a3 bullet)

**Location:** `scripts/lib/dev-cycle-read.sh:462-463`, `scripts/lib/dev-cycle-read.sh:545-546`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`, `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers import paths that are also untracked start files in the checkout. For paths first reached as imports or link text, the refusal holds (test 15, E3 `noparent`).
**Replicate verdicts:** r1=Verified (compound) · r2=Incorrect · r3=Mostly accurate (compound)
**Replicate annotations:** r1: probes T1, T2, L8, L12 `walk: failed`; mutant `f-parent-check` fails test 15 · r3: compound Mostly accurate is attributed in r3's text to the lists' root/FIFO omission; "Every listed shape fails"

Carried from r2 Claim 18: P1 Q3 (Claim 19): main imports `ld/CLAUDE.md` with `ld -> deep` on main, and the walk answers `walk: ok` because the path is an untracked start already in `seen`. The `continue` at `:610` skips the loop at `:614`. r2's suggested remedy: apply the parent check to every path main lacks, including t: starts, before the seen test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:572`, `scripts/lib/dev-cycle-read.sh:610-614`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-noparent.txt`

---

## Claim 25: "a checkout file it cannot read" fails the walk — the file's own permissions

**Location:** `scripts/lib/dev-cycle-read.sh:463`, `scripts/lib/dev-cycle-read.sh:543`, `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal and the isimported consequence; does not establish completeness: the root and FIFO arm is unlisted here (the return-1 comment at :538-548 lists it).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Mostly accurate (compound)
**Replicate annotations:** merge: the Mostly accurate is r3's compound verdict (Claims 13/1/2/3), which r3's text attributes to the root/FIFO omission (Claims 13, 23); the atom-level verdict is r2's Verified · r2: plain checkout file with mode 000, run as non-root `node`: `line 580: sec/x.md: Permission denied walk: failed` (P1 Q4); test 7's `chmod 000` case passes; "does not cover unreadability that comes from a parent directory (Claim 19b)" (here Claim 26)

Carried from r3 Claim 13: each listed refusal, including the unreadable checkout file, fails (test 9 `chmod 000`; mutant `ckread` `rc=1`); the list's Mostly accurate is its omission of the root/FIFO arm at `scripts/lib/dev-cycle-read.sh:582`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:580`, `scripts/lib/dev-cycle-read.sh:582`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/shapes-probe.txt`

---

## Claim 26: "a checkout file it cannot read" fails the walk — a file under an unsearchable directory

**Location:** `scripts/lib/dev-cycle-read.sh:463`, `scripts/lib/dev-cycle-read.sh:543`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a target main lacks that lies under a checkout directory with mode 000. It does not establish exposure: Claude Code running as the same user cannot read the file either.
**Replicate verdicts:** r1=Verified (compound) · r2=Incorrect · r3=Mostly accurate (compound)
**Replicate annotations:** r3: compound Mostly accurate attributed to the root/FIFO omission

Carried from r2 Claim 19b: the t-arm `if inrepo_here "$f"; then … elif [[ -d "$f" && ! -L "$f" … ]]; then continue … elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1 … else continue; fi` (`scripts/lib/dev-cycle-read.sh:580-583`). In P1 Q4, CLAUDE.md imports `sec/x.md` (main lacks it), which imports `docs/y.md`. Readable `sec`: `walk: ok docs/y.md: imported`. After `chmod 000 sec`: `walk: ok docs/y.md: -`; `-f`, `-e`, `-L` all fail with EACCES and the `else continue` arm treats the file as absent.

**Evidence:** `scripts/lib/dev-cycle-read.sh:580-583`, `scripts/lib/dev-cycle-read.sh:111-121`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt`

---

## Claim 27: "A start file answers imported only when an import reaches it (U2a4's floor names start files by its own rules)"

**Location:** `scripts/lib/dev-cycle-read.sh:465-466`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers IMPORTED_MAIN's only append site. "Import" includes a symlink's text (the 120000 arm feeds the target through the same loop), so a start that another start's link names answers imported. Floor semantics are U2a4's and are not covered.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: test 13 asserts a self-import (`@CLAUDE.md`) is recorded

Carried from r2 Claim 20: the only append is `IMPORTED_MAIN+="$(lower "$p")"$'\n'` inside the import loop (`:609`); the start loop only sets `seen` and `queue`. Test 1 asserts `CLAUDE.md -`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:569-575`, `scripts/lib/dev-cycle-read.sh:607-616`, `/tmp/u2a3-cfcg-i3-WrT9/logs/bats-build-loop-check.txt`

---

## Claim 28: "Not covered (known issue A5): start files under a symlinked directory … or in a submodule or an untracked nested repo, other names that one file has on a case-insensitive checkout, absolute imports, and three shapes A5 lists as untraced against Claude Code"

**Location:** `scripts/lib/dev-cycle-read.sh:467-471`, `scripts/lib/dev-cycle-read.sh:540`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed gap (true) and the fail-open shapes that are not listed. It does not establish any Claude Code behaviour.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1 (Medium confidence): "link text of 65,535+ bytes with a failed temp write skips the `..` check (Claim 26); that link cannot exist on disk"; "case-insensitive aliasing of a main directory link: `@LD/x.md` against main's `ld` passes the parent check (`ent` lookups are exact-case); this falls under the listed case-insensitive gap" · r2: "listed whole" (return-1 `:540`) relies on git's exit status: with `pkg/` mode 000, `git ls-files --others` exited 0 with `warning: could not open directory 'pkg/'` and the walk gave `walk: ok docs/p.md: -`; "Exposure is minimal" · r3: "does not establish Claude Code's behaviour for those shapes or case-insensitive filesystems (not available here)"

Carried from r2 Claim 21: every listed gap is real. The list omits these fail-open shapes: the untracked-start bypass of the parent-link refusal (Claim 24), a target under an unsearchable checkout directory (Claim 26), link text past 64 KiB when a temp file cannot be written (Claim 34), a failing `lower` or `grep`, fixed in U2a3b (Claim 7).

**Evidence:** `scripts/lib/dev-cycle-read.sh:467-471`, `scripts/lib/dev-cycle-read.sh:517-519`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt`

---

## Claim 29: "IMPORTED_MAIN reads \"error\" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE=\"\" to walk again"

**Location:** `scripts/lib/dev-cycle-read.sh:472-475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the initial value, the reset on every recompute, the three-field key and the clear-to-rewalk contract; does not establish the value while a walk is in progress (it is `$'\n'` plus entries from `:574` on, not "error", and no caller can read it then).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "Behaviour when a caller changes ROOT_REAL without cd is need_root's concern" · r3: "'Until a walk succeeds' is slightly loose: IMPORTED_MAIN becomes the partial list at `:575` before the walk ends, but every later failure resets it to error"; "does not establish that any caller clears the cache (no caller exists yet)"

Carried from r1 Claim 21: initial value `IMPORTED_MAIN=error` (`scripts/lib/dev-cycle-read.sh:476`); reset and key at `:553`. Test 16 passes; mutants `h-cache-key-mbn` and `i-reset-to-error` each fail it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:476`, `scripts/lib/dev-cycle-read.sh:552-554`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-h-cache-key-mbn.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-i-reset-to-error.log`

---

## Claim 30: "nul_list NAME CMD...: array NAME gets CMD's NUL-split output, or 1 unless CMD exited 0 (&& || keep errexit off)"; used for main's tree and the untracked list

**Location:** `scripts/lib/dev-cycle-read.sh:518-519`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a failing command (with and without partial output), an empty listing, a listing whose last item is literally `rc=0` (succeeding and failing), and `set -e` survival. It does not establish two extra behaviours, both fail-safe at both call sites, which return 1 at once. First, a successful listing whose last record lacks a terminating NUL also returns 1. Second, on failure NAME is left holding the partial items plus an `rc=1` item.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish completeness when the command exits 0 with an incomplete list" (see Claim 28) · r3: mutant `nulrc` fails test 10

Carried from r1 Claim 22: `nul_list() { local -n nl_a="$1"; shift; mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1); [[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || return 1; unset 'nl_a[-1]'; }` (`:519`). Probe P5 covers each case; both call sites end `|| return 1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:518-519`, `scripts/lib/dev-cycle-read.sh:556`, `scripts/lib/dev-cycle-read.sh:564`, `/tmp/u2a3-cfcg-i3-9082/logs/p5.log`

---

## Claim 31: Return-1 comment — returns 1 "when main is not found by name, the commit's tree or the untracked list cannot be listed whole (nul_list), … or a checkout path it would read exists but is neither a plain file nor a plain directory below the root (a symlink, under one, the root itself, a FIFO); need_root exits instead"

**Location:** `scripts/lib/dev-cycle-read.sh:538-548`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` statement in main_imports (each maps to a listed cause), the root and FIFO causes and the first-copy parenthetical. It does not establish non-return outcomes: SIGXFSZ killing the shell on the link-text here-string under `ulimit -f 0` (exit 153), and the fail-open read when that write fails without a signal (Claim 34). The cached-failure return (`:552`) is implicit rather than listed.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that each listed cause always fails: Claims 18, 19, 21 and 22 cover the shapes that do not" (here Claims 24, 26, 28, 34); `:540` "listed whole" not checked for an `ls-files` directory warning with exit 0 (Claim 28) · r3: the tree regex lets `.` match a newline, so the newline check at `:560` is live (mutant `nlcheck` fails test 5); "does not cover the swallowed here-string failure at :596"

Carried from r1 Claim 23: each `return 1` maps to a listed cause (`:554` main_by_name; `:556`, `:564` nul_list; `:558` parse; `:560` doubled/newline; `:565` untracked newline; `:567` short list; `:578`, `:584`, `:590-593` reads and link text; `:597` `..`; `:602` leaves; `:614` parent; `:580` not plain). Root and FIFO reach `elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1`; probes P1 and P2 give `walk: failed`. Probe P8: `git cat-file blob main:z.md` returns the first of two `z.md` entries.

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-617`, `scripts/lib/dev-cycle-read.sh:111-128`, `/tmp/u2a3-cfcg-i3-9082/logs/p1.log`, `/tmp/u2a3-cfcg-i3-9082/logs/p8.log`

---

## Claim 32: "$(...) drops NULs, so they are counted first; the x keeps trailing newlines, which $(...) would also drop."

**Location:** `scripts/lib/dev-cycle-read.sh:588-589`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL count and the trailing-newline guard; does not cover link text holding a NUL that `git cat-file` could not emit (not possible for a blob).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r3: "does not cover link text over 64 KiB (Claim 5)" (here Claim 34)

Carried from r1 Claim 24: `i="$(git cat-file blob ... | tr -cd '\0' | wc -c)" ... [[ "$i" -ne 0 ]]` and `out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"; ... out="${out%x}"` (`:590-592`). Tests 9 and 7 pass, both asserting `walk failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:587-593`, `test/scripts/build-loop-check.bats:159-163`, `test/scripts/build-loop-check.bats:198-202`

---

## Claim 33: "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails." (link-text component loop)

**Location:** `scripts/lib/dev-cycle-read.sh:594-600`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the loop for every shape probed: first component a link, a deeper link, `.`, `//`, trailing `/`, text exactly `..`, a final component that is a directory link, a `..` before a link, leave-and-return text, a link in a subdirectory, and a checkout-only link. It does not establish exact refusal: any `..` anywhere after a link component fails, including `ld/sub/..`, which the kernel and lexical resolution agree on. That is an over-refusal (fail-closed), consistent with the comment's wording. It also does not establish the absence of fs access by `realpath -ms` (strace unavailable; static knowledge of coreutils' no-links/missing-ok mode only).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: trailing `/` (L5) is followed as `docs/evil.md` where the kernel would give ENOTDIR (over-records) · r2 (Medium confidence): `ld/..` with `ld` a file link also fails (kernel ENOTDIR); exceptions in Claim 24 (starts bypass `:614`) and Claim 34 (oversized text) · r3: "does not cover the link's own directory being a symlink only in the checkout": main `sub/AGENTS.md -> ../docs/t.md` with the checkout replacing `sub` by a symlink stays `walk: ok` because `lk` starts empty at the link's own directory; the walk reads main's blob for that path

Carried from r1 Claim 25: `lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"` then `[[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }` per component (`:596-598`). Probe P2: L2, L3, L4, L11, L13 `walk: failed`; L4b, L10 ok; L6 `..` failed; L8 failed (parent check). Mutants `e-dotdot-after-link` and `g-checkout-L-half` each fail test 15.

**Evidence:** `scripts/lib/dev-cycle-read.sh:594-603`, `/tmp/u2a3-cfcg-i3-9082/logs/p2.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-e-dotdot-after-link.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-g-checkout-L-half.log`

---

## Claim 34: I2-C4 — the import-list here-string was the walk's only path to a temp file ("main walk reads its import list without a here-string", read as the unit being free of here-strings; the override row's "Fixed")

**Location:** `scripts/lib/dev-cycle-read.sh:596`, `scripts/lib/dev-cycle-read.sh:616`, `docs/reviews/override-log.md:381`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the remaining here-string in main_imports. It does not establish practical reachability: the link text must be at least 65,535 bytes, longer than any symlink Linux can create, so Claude Code cannot load through such a link and no import is missed in practice.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Mostly accurate (compound)
**Replicate annotations:** r1+r2: the commit's stated atom, that the import list is read without a here-string (`:616`), is correct; r2: "The process-substitution half is Verified" · r2: Linux cannot create such a symlink (P3 X2, `ln: failed …`) · r1+r2+r3: under default SIGXFSZ the shell is killed (exit 153) instead, a crash rather than an ok answer · r3 (Claim 5): it "does contradict the override row's 'the known unguarded command (lower)'"

Carried from r1 Claim 26: `IFS=/ read -ra parts <<<"$out"` (`scripts/lib/dev-cycle-read.sh:596`) remains. When the temp-file write fails without the signal, the read fails, `parts` keeps its previous value and the `..`-after-symlink check is skipped. Probe P4c (main `ld -> deep/inner`, 68,593-byte `CLAUDE.md -> <pad>/ld/../evil.md`): `line 596: cannot create temp file for here-document: File too large`, then `walk: ok`, `deep/secret.md: -`. P4a, no limit: `walk: failed`. Threshold: `n=65535 exit=0`, `n=65536 exit=153`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:596`, `/tmp/u2a3-cfcg-i3-9082/logs/p3.log`, `/tmp/u2a3-cfcg-i3-9082/logs/hs.log`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes3.txt`, `/tmp/u2a3-cfcg-i3-CgDN/logs/herestring-linktext-probe.txt`

---

## Claim 35: "Main lacks p: under a directory link main stores (the checkout may lack it), fail."

**Location:** `scripts/lib/dev-cycle-read.sh:613-614`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `/`-bounded prefix of a main-lacked import path, checked against main's 120000 entries; does not cover case-variant prefixes (`LD/` vs `ld`, exact-case `ent`), which belong to the documented case-insensitive gap.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: the check runs only after the `seen` test, so a path already seen as an untracked start skips it (Claim 24) · r3: "does not cover paths main has (they are read from main, `:612`)"

Carried from r1 Claim 27: `for (( c = ${#p}; c > 0; c-- )); do [[ "${p:c:1}" != / || "${ent[${p:0:c}]:-}" != 120000 ]] || { IMPORTED_MAIN=error; return 1; }; done` (`:614`). Probes T1, T2, L8, L12 `walk: failed`; mutant `f-parent-check` fails test 15.

**Evidence:** `scripts/lib/dev-cycle-read.sh:607-616`, `/tmp/u2a3-cfcg-i3-9082/logs/p2.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-f-parent-check.log`

---

## Claim 36: isimported — "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; … the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:619-623`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `main`, `tree` and unknown arms and the case folding; does not establish any caller's wording of a failed walk (none exists yet).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish behaviour when `lower "$2"` fails (fixed in U2a3b)"

Carried from r1 Claim 28: `main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;`, `tree) imported_names; …`, `*) return 0 ;;` (`:624-633`). Tests 1, 2, 8 and the unknown-walk-name test pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:619-633`, `/tmp/u2a3-cfcg-i3-9082/logs/build-loop-check.bats.log`

---

## Claim 37: Test-file header — "the reader lib's import walks (… isimported, import_targets, main_imports)"; imps — "\"walk: ok\" or \"walk: failed\" (main_imports' return; tree always reads ok)"

**Location:** `test/scripts/build-loop-check.bats:3-4`, `test/scripts/build-loop-check.bats:13-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helper's output contract; does not cover the U2a4/U2b parts the header names as future.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** none

Carried from r1 Claim 29: the helper prints `if [[ "$w" != main ]] || main_imports; then echo "walk: ok"; else echo "walk: failed"; fi` (`test/scripts/build-loop-check.bats:19`).

**Evidence:** `test/scripts/build-loop-check.bats:13-22`

---

## Claim 38: Each main-walk test's name and comments state what it asserts

**Location:** `test/scripts/build-loop-check.bats:46-308`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each test's assertions against its name, and that ten mutants of the guarded arms each fail at least one test. It does not establish that the first sub-case of test 9 ("A tracked directory symlink, present in the checkout, that an import passes through", `:182`) reaches the checkout-symlink arm: since e7b5d7ed it fails at the main-side parent check (`:614`), before the checkout is consulted. The later sub-cases of test 9 do exercise the checkout arm, so the name still holds. It also does not establish what the decoy `docs-rules.md` blob in test 9's NUL case is for (`:201`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the `:182`/`:183` "tracked directory symlink" sub-case fails through the parent-link check, not the checkout-symlink check; later sub-cases cover that arm · r2 (Medium confidence): "does not establish that every sub-case in a test is mutant-pinned: only the five mutants were run"; test 12's empty-text comment is accurate · r3 (Medium confidence): test 15's "A .. after a plain directory is followed" (`:293`) is asserted by `AGENTS.md -> docs/../docs/n.md`, while the re-made `CLAUDE.md -> ld/../evil.md` at that point has its `..` after an `ld` absent from both main and the checkout; "does not cover root/FIFO refusals, which no test exercises (probed only), or the line-596 here-string"

Carried from r1 Claim 30: each name checked against its assertions with no false passes; each of ten mutants fails at least one test (a→6, b→9, c and j→10, d→7, e, f, g→15, h, i→16).

**Evidence:** `test/scripts/build-loop-check.bats:46-308`, `/tmp/u2a3-cfcg-i3-9082/mutants.py`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-a-nested-rules-start.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-j-here-string.log`

---

## Claim 39: fbeae280 — "Tests: build-loop-check.bats 14; 112 across the five suites. Mutants of the nested-rules start, the checkout-read guard, the tr length check … and the link-escape guard each fail. 344 changed code lines against U2a2."

**Location:** commit `fbeae280`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at fbeae280, the line count, the B-bullet behaviours (at HEAD) and the four named mutants (run against HEAD's tests, which keep those assertions). The B5 bullet's test numbering and the Notes line are recorded Accepted-immutable at `docs/reviews/override-log.md:367` and not re-verdicted.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2 (Claim 3, located at override rows `:367`/`:380`): the rows exist as Accepted-immutable; row :367's fact that an untracked symlinked rules file fails the walk matches the t-arm (`:582`) · r3: "does not re-run the mutants against fbeae280's own test file"

Carried from r1 Claim 31: `git show fbeae280:<suite> | grep -c '^@test'` gives 14 for build-loop-check.bats and 112 over the five suites; `git diff --numstat main...fbeae280 -- . ':!docs'` sums to 344; mutants a, b, c, d each fail.

**Evidence:** commit fbeae280, `/tmp/u2a3-cfcg-i3-9082/logs/mut-a-nested-rules-start.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-b-checkout-read-guard.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-c-tr-length-check.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-d-link-escape-guard.log`

---

## Claim 40: 45ad17b0 — "A5 names U2a3 as main_imports' unit"

**Location:** commit `45ad17b0`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers A5's text at HEAD. It does not cover the doc-only commits 277b2fab and cb4ebbc8, whose subjects only name the artifacts they add.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** none

Carried from r2 Claim 30: A5 reads "The gate's walk (`main_imports`, U2a3)" (`docs/working/known-issues-dev-cycle.md:18`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 41: 277b2fab / cb4ebbc8 — "review artifacts and override rows"

**Location:** commit `277b2fab`, commit `cb4ebbc8`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that each commit contains what its subject names; does not re-verdict the contents of the review reports they add.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r2+r3: scoped these docs-only commits out as holding no checkable claim beyond the files they add

Carried from r1 Claim 32: the two docs commits add the iteration-1/2 reports, rubric and override rows (paraphrased — no quote available because the claim is about which files a commit adds; `git show --stat`).

**Evidence:** commits 277b2fab, cb4ebbc8

---

## Claim 42: 4f087967 — "Tests: one new in build-loop-check.bats (15); 113 across the five suites. A mutant dropping the new check fails it. 369 changed code lines against main."

**Location:** commit `4f087967`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts, line total and mutant; the "resolved a component at a time" wording is recorded Accepted-immutable at `docs/reviews/override-log.md:380`.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

Carried from r1 Claim 33: counts 15 / 113 at 4f087967, line total 369 (`git diff --numstat main...4f087967`); mutant `e-dotdot-after-link` fails test 15.

**Evidence:** commit 4f087967, `/tmp/u2a3-cfcg-i3-9082/logs/mut-e-dotdot-after-link.log`

---

## Claim 43: 34edec56 subject — "the not-covered symlinked-directory gap names @ tokens, not link text"

**Location:** commit `34edec56`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Pointer only: already recorded Accepted-immutable at `docs/reviews/override-log.md:380` (link text through a directory link main stores failed open at that commit). The current code fails both, at `scripts/lib/dev-cycle-read.sh:614`.
**Replicate verdicts:** r1=Incorrect · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not re-verdict the messages' prose, which the rows already settle" · r3: verdicted as a pointer: "the subject's inaccuracy is recorded in override row … (Accepted-immutable), and the comment it touched is gone at HEAD (`grep 'checked above'` finds nothing in the lib)"

Carried from r1 Claim 34: the row reads "34edec56's subject says the symlinked-directory gap names @ tokens, not link text (false: link text through a directory link main stores failed open)" (`docs/reviews/override-log.md:380`).

**Evidence:** `docs/reviews/override-log.md:380`

---

## Claim 44: e7b5d7ed — "build-loop-check.bats 16; 114 across the five suites. Mutants of the parent check, the checkout -L half, the cache key and the reset to error each fail. 398 changed code lines against main."; the G1-G6 test list

**Location:** commit `e7b5d7ed`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts, line total, the four mutants (run at HEAD) and that each listed test shape exists; does not cover the isimported-comment sentence (Claim 46).
**Replicate verdicts:** r1=Verified · r2=Verified (compound; stated for this atom) · r3=Verified
**Replicate annotations:** none

Carried from r1 Claim 35: counts 16 / 114 at e7b5d7ed, line total 398; mutants f, g, h, i each fail; the 100755 arm, a main blob over a checkout edit, untracked rules starts, a chain, the checkout `..` half, link and token through `ld` and the cache test are present.

**Evidence:** commit e7b5d7ed, `test/scripts/build-loop-check.bats:114-139`, `test/scripts/build-loop-check.bats:277-308`

---

## Claim 45: e7b5d7ed — the parent check "makes the header's 'the checkout can only add imports' true and closes that A5 gap"

**Location:** commit `e7b5d7ed`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The figures are Verified: 16 tests, 114 across the five suites, 398 lines, and the four mutants (parent check, checkout -L half, cache key, reset to error) each fail (E1, E2, E3, run at HEAD's tests). The Incorrect part is "which makes the header's 'the checkout can only add imports' true and closes that A5 gap". This verdict does not establish anything about the other prose.
**Replicate verdicts:** r1=— · r2=Incorrect · r3=— · single-replicate detection
**Replicate annotations:** r2: commit message is immutable, so this needs an override row

Carried from r2 Claim 27: the header's invariant does not hold; an untracked start under main's link bypasses the new check (Claim 19, P1 Q3).

**Evidence:** `/tmp/u2a3-cfcg-i3-WrT9/logs/E2-linecounts.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/E1-summary.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt`

---

## Claim 46: e7b5d7ed — "isimported's comment says start files answer imported only when an import reaches them (architecture F2)"

**Location:** commit `e7b5d7ed`
**Type:** Configuration / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** The figures are Verified: 16 tests, 114 across the five suites, 398 lines, and the four mutants (parent check, checkout -L half, cache key, reset to error) each fail (E1, E2, E3, run at HEAD's tests). The Incorrect part is "which makes the header's 'the checkout can only add imports' true and closes that A5 gap". This verdict does not establish anything about the other prose.
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect (compound) · r3=Mostly accurate
**Replicate annotations:** merge: the Incorrect is r2 Claim 27's compound verdict, whose text locates it on Claim 45's atom and calls this sentence "A smaller imprecision"; r1 and r3 verdict this atom Mostly accurate · r1+r2+r3: the sentence is in main_imports' block comment above `IMPORTED=` (`scripts/lib/dev-cycle-read.sh:465-466`), not in isimported's comment (`:619-623`); r1 precise version "main_imports' comment says ..."

Carried from r2 Claim 27: "at e7b5d7ed that sentence is in the block comment above `IMPORTED=` (e7b5d7ed's lib `:465-466`), not in isimported's comment (`:622-626` there)."

**Evidence:** `scripts/lib/dev-cycle-read.sh:465-466`, `scripts/lib/dev-cycle-read.sh:619-623`, `/tmp/u2a3-cfcg-i3-WrT9/logs/probes1.txt`

---

## Claim 47: 2a3e499f — "the not-covered list points to A5's three untraced shapes"

**Location:** commit `2a3e499f`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the lib comment and A5's list; does not cover the untraced shapes themselves.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "does not establish 2a3e499f's line delta (E2: 2 lines, taking HEAD from 398 to 400)"

Carried from r1 Claim 37: the lib comment reads "three shapes A5 lists as untraced against Claude Code (command references, a link's own directory, a token's ..)" (`scripts/lib/dev-cycle-read.sh:470-471`); A5 lists the same three.

**Evidence:** `scripts/lib/dev-cycle-read.sh:467-471`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 48: c42f017f — "bash writes a here-string past 64 KiB to a temp file, and a failed write … read as no imports, so the walk answered ok without them" (write that fails without killing bash)

**Location:** commit `c42f017f`
**Type:** Error-handling / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism under both SIGXFSZ dispositions, plus the counts and the mutant. It does not cover a full disk, which was not executed. The claim "U2a3b's own fix" was checked only as far as U2a3b's imported_names using process substitution.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r1: with SIGXFSZ ignored, `while read ... done <<<"$x"` (70 KB) prints `cannot create temp file for here-document: File too large` and `rc=1 n=0`: "read as no imports" · r2: in its probe, main_imports itself returned 1 because the failing file was the last one processed, but IMPORTED_MAIN was not `error`, so isimported read the short list · r3: the cached answer for `docs/last.md` was `-` with SIGXFSZ ignored; "does not cover the other here-string at :596"

Carried from r2 Claim 28: the figures hold and the mutant is killed. The mechanism is imprecise for `ulimit -f 0`: under the default disposition the mutant's shell is killed by SIGXFSZ (rc 153). Precise version: "a failed write that does not kill the shell (a full disk, or a file-size limit with SIGXFSZ ignored) reads as no imports, and isimported answers from the short list".

**Evidence:** `/tmp/u2a3-cfcg-i3-WrT9/logs/probes3.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-herestring.txt`, `/tmp/u2a3-cfcg-i3-9082/logs/hs.log`

---

## Claim 49: c42f017f — "a failed write (ulimit -f 0, …) read as no imports"

**Location:** commit `c42f017f`
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old code under `ulimit -f 0` with default signal dispositions (how the test runs it); does not affect the fix, which avoids the temp file either way.
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** r1: "The test still kills the mutant, but by a crash, not by the fail-open answer the message describes"; commit message immutable, wants an override row · r2+r3: same SIGXFSZ finding, verdicted Mostly accurate within the whole mechanism sentence

Carried from r1 Claim 38b: under `ulimit -f 0` the temp-file write raises SIGXFSZ and bash dies (exit 153), not a quiet empty read. Mutant `j-here-string` fails test 10 with `# 153` as its status.

**Evidence:** `/tmp/u2a3-cfcg-i3-9082/logs/mut1.log`, `/tmp/u2a3-cfcg-i3-9082/logs/mut-j-here-string.log`, `/tmp/u2a3-cfcg-i3-9082/logs/hs.log`

---

## Claim 50: c42f017f — "It now reads through process substitution"; nul_list "used for main's tree and the untracked list"; "the return-1 comment names every cause …"; "the A2 test also reads a 67 KB import list under ulimit -f 0 (the here-string mutant fails it); build-loop-check.bats 16; 114 across the five suites. 400 changed code lines against main"; the Docs line

**Location:** commit `c42f017f`
**Type:** Error-handling / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mechanism under both SIGXFSZ dispositions, plus the counts and the mutant. It does not cover a full disk, which was not executed. The claim "U2a3b's own fix" was checked only as far as U2a3b's imported_names using process substitution.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
**Replicate annotations:** merge: r2 (Claim 28) and r3 (Claims 30/31) each verdicted this atom inside a compound; r3's Claim 31, which covers the figures and Docs line, is Verified, and its Claim 30 (mechanism plus "now reads through process substitution") is Mostly accurate · r1: "'every cause' counts return-1 paths only (the `:596` here-string's kill/skip is not a return; Claim 26)"; "the here-string mutant fails it" happens by a crash (Claim 38b) · r2: "The commit title's 'reads its import list without a here-string' is exact, since the link-text here-string at `:596` is not the import list"

Carried from r2 Claim 28: the figures hold (E1, E2: 16 / 114, 400 lines), and the mutant is killed (E3 `herestring`); the mechanism sentence is imprecise for `ulimit -f 0` (Claims 48-49).

**Evidence:** `scripts/lib/dev-cycle-read.sh:556`, `scripts/lib/dev-cycle-read.sh:564`, `scripts/lib/dev-cycle-read.sh:616`, `/tmp/u2a3-cfcg-i3-WrT9/logs/E2-linecounts.txt`, `/tmp/u2a3-cfcg-i3-WrT9/logs/mutant-herestring.txt`

---

## Claim 51: cc1aa864 — "finding declined: the root and FIFO causes go through the generic not-plain arm, probed"

**Location:** commit `cc1aa864`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the root (token and link text) and a FIFO import target; does not cover an untracked FIFO start, which is never listed and so never read.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: the fix-drift finding's premise ("no explicit checks for FIFO files or root-directory paths") is true but beside the point

Carried from r1 Claim 40: both reach `elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1` (`scripts/lib/dev-cycle-read.sh:580`); probes P1 and P2 give `walk: failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:576-581`, `/tmp/u2a3-cfcg-i3-9082/logs/p1.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:29-35`): "can only add imports or fail it" is false; an untracked start under a directory main stores as a link turns main's failed walk into ok (r2 only).
- **Claim 20** (`scripts/lib/dev-cycle-read.sh:29-35`): compound-inherited from Claim 19; r3's atom-level verdict is Mostly accurate (the reads list omits component lstat and type tests).
- **Claim 24** (`scripts/lib/dev-cycle-read.sh:462-463`, `:545-546`, A5, F11, U2a3 bullet): the parent-link refusal is skipped for a path already seen as a start (`:610` before `:614`).
- **Claim 26** (`scripts/lib/dev-cycle-read.sh:463`, `:543`, A5, F11): a checkout file under an unsearchable directory reads as absent and its imports drop, walk ok.
- **Claim 34** (`scripts/lib/dev-cycle-read.sh:596`): a second here-string remains; unreachable through a real symlink.
- **Claim 43** (commit 34edec56): already Accepted-immutable, `docs/reviews/override-log.md:380`.
- **Claim 45** (commit e7b5d7ed): "makes the header's … true and closes that A5 gap"; needs an override row (r2 only).
- **Claim 46** (commit e7b5d7ed): compound-inherited; r1 and r3 verdict it Mostly accurate (the sentence went into main_imports' comment, not isimported's).
- **Claim 49** (commit c42f017f): under `ulimit -f 0` the old code was killed by SIGXFSZ, not read as no imports; needs an override row.

### Stale
- None.

### Mostly Accurate
- **Claim 7** (`docs/reviews/override-log.md:374`): `lower` is not the only unguarded command (`:596` here-string; `grep` at `:508`).
- **Claim 11** (`docs/reviews/override-log.md:379`): fails only when an import reaches a path below the name.
- **Claim 12** (`docs/reviews/override-log.md:381`): failure mechanism imprecise for plain `ulimit -f 0`; a second here-string remains.
- **Claims 13, 15, 16, 23** (A5, F11, U2a3 bullet, block comment): refusal lists omit the root/FIFO arm (`:582`); F11 also omits the component lstat.
- **Claim 14** (A5 gaps): compound-inherited from r3's Claim 1.
- **Claim 25** (unreadable file, own permissions): compound-inherited; r2's atom-level verdict is Verified.
- **Claim 28** (`scripts/lib/dev-cycle-read.sh:467-471`): gap list omits Claims 24, 26, 34 and Claim 7's grep/lower; `ls-files` can exit 0 with an incomplete list.
- **Claims 48, 50** (commit c42f017f): mechanism precision under SIGXFSZ.

### Unverifiable
- None. Timings in override rows `:365`, `:377` and `:378` were not re-measured; they are scoped out of Claims 1, 9 and 10.

## Escalations

1. `scripts/lib/dev-cycle-read.sh:596` — raised by r1, r2, r3 — addressee: U2a3 implementer / review-fix loop (r1, r3), orchestrator (r2), U2a3b loop (r3). The link-text split `IFS=/ read -ra parts <<<"$out"` is a second here-string; past 64 KiB with a soft temp-file failure the `..` check is skipped and the walk answers ok. Process substitution, a failure arm or a length check would close it. Low: unreachable through a symlink a checkout can hold. r2 suggests an informational override row; r1 suggests naming it in the return-1 comment or the `:381` row. (Claim 34)
2. `scripts/lib/dev-cycle-read.sh:610-614` (with `:572`) — raised by r2 — addressee: implementer / orchestrator. The parent-link refusal does not cover untracked starts. Either run the `:614` check for every path main lacks, starts included, or narrow the header (`:29-34`), the block and return-1 comments, A5, F11 and the U2a3 bullet. Commit e7b5d7ed's message needs an Accepted-immutable row. (Claims 19, 24, 45)
3. `scripts/lib/dev-cycle-read.sh:580-583` (and `:517`) — raised by r2 — addressee: implementer. Decide whether EACCES under a parent directory should fail the walk or be documented as not covered; the same applies to `ls-files --others` exiting 0 with a could-not-open-directory warning. (Claims 26, 28)
4. Commit `c42f017f`, I2-C4 bullet — raised by r1 — addressee: override-log keeper. The `ulimit -f 0` example is incorrect; commit messages are immutable, so this wants an Accepted-immutable row like `:367` and `:380`. (Claim 49)
5. `docs/reviews/override-log.md:374`, `docs/reviews/override-log.md:379` — raised by r1, r2 — addressee: override-log keeper (r1), orchestrator (r2). Tighten as in Claims 7 and 11 if the rows are edited again; r2 adds naming `grep` alongside `lower`. (Claims 7, 11)
6. `scripts/lib/dev-cycle-read.sh:458-465`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`, `docs/working/plan-build-loop-handoff.md:276` — raised by r3 — addressee: U2a3 implementer. The refusal lists omit the root and FIFO arm (`:582`) that the return-1 comment names. Low (fail-closed). (Claims 13, 15, 16, 23)
7. `scripts/lib/dev-cycle-read.sh:596-600` — raised by r3 — addressee: security-reviewer (informational). `lk` starts empty at the link's own directory, so a checkout that makes that directory a symlink does not trip the `..` check; the walk reads main's blob for that path, matching the header's model. (Claim 33)
8. `test/scripts/build-loop-check.bats:182` — raised by r1 — addressee: test author (informational). The first sub-case of test 9 fails at main's parent-link check, not the checkout-symlink arm its name advertises; later sub-cases cover that arm, so no false pass. (Claim 38)
9. `scripts/lib/dev-cycle-read.sh:281`, `scripts/lib/dev-cycle-read.sh:341` — raised by r3 (out of scope, pre-existing on main) — addressee: dev-cycle-read owner / U2a3b loop. `main_entry` and `brief_fields` also read via `done <<<"$out"`; impact not traced.

## Verdict stability

- **Total clusters:** 51 (46 surfaced by two or more replicates; 5 single-replicate: Claims 8, 18, 22, 41 from r1, Claim 45 from r2).
- **All reporting replicates agreed:** 32 (27 multi-replicate + 5 single-replicate). Entries marked `(compound)` count at their recorded value.
- **Disagreeing clusters (19):**
  - Claim 11: r1=Mostly accurate · r2=Mostly accurate · r3=Verified
  - Claim 12: r1=Verified · r2=Verified (compound) · r3=Mostly accurate
  - Claim 13: r1=Verified · r2=— · r3=Mostly accurate
  - Claim 14: r1=Verified (compound) · r2=Verified · r3=Mostly accurate (compound)
  - Claim 15: r1=Verified · r2=Verified (compound) · r3=Mostly accurate
  - Claim 16: r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
  - Claim 19: r1=Verified (compound) · r2=Incorrect · r3=Verified
  - Claim 20: r1=Verified (compound) · r2=Incorrect (compound) · r3=Mostly accurate
  - Claim 23: r1=Verified (compound) · r2=Verified · r3=Mostly accurate
  - Claim 24: r1=Verified (compound) · r2=Incorrect · r3=Mostly accurate (compound)
  - Claim 25: r1=Verified (compound) · r2=Verified · r3=Mostly accurate (compound)
  - Claim 26: r1=Verified (compound) · r2=Incorrect · r3=Mostly accurate (compound)
  - Claim 28: r1=Verified · r2=Mostly accurate · r3=Verified
  - Claim 34: r1=Incorrect · r2=Incorrect · r3=Mostly accurate (compound)
  - Claim 43: r1=Incorrect · r2=Verified (compound) · r3=Verified
  - Claim 46: r1=Mostly accurate · r2=Incorrect (compound) · r3=Mostly accurate
  - Claim 48: r1=Verified · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
  - Claim 49: r1=Incorrect · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
  - Claim 50: r1=Verified · r2=Mostly accurate (compound) · r3=Mostly accurate (compound)
- **Agreement rate:** 32/51 = 62.7% over all clusters; 27/46 = 58.7% over clusters at least two replicates surfaced. This is below the 90% falsifier for dropping k to 2.
- **Per-replicate Incorrect counts:** r1 3 (Claims 34, 43, 49), r2 5 atom-level (Claims 19, 24, 26, 34, 45), r3 0. Of the 9 merged Incorrect clusters, only Claim 34 was called Incorrect by more than one replicate.
