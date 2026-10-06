Commit: 45ad17b0

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`)
**Scope:** `git diff main...HEAD` on `feat/build-loop-u2a3` (base 62d366a7, HEAD 45ad17b0): scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/working/plan-build-loop-handoff.md, docs/working/known-issues-dev-cycle.md, docs/reviews/override-log.md, and the messages of commits fbeae280 and 45ad17b0
**Checked:** 2026-10-06
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 32
**Summary:** 24 verified, 4 mostly accurate, 0 stale, 3 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): the logged patterns are mis-quoted measured values (test counts, corpus figures) and unreferenced file-symbol associations. The commit's test counts (Claim 27) and line count (Claim 29) were recomputed for that reason; both match. No claim matches a logged pattern.

## Execution provenance

All runs are under the scratch dir `/tmp/u2a3-cfc-i1-S05k` (logs in `logs/`). The worktree was not edited.

- **E1** (2026-10-06T23:27:49Z): `TMPDIR=/tmp/u2a3-cfc-i1-S05k bats test/scripts/<suite>.bats` for build-loop-check, dev-cycle, build-loop-read, fixture-git-env (test/scripts/) and fixture-hermeticity (test/). cwd `/workspace/.claude/wt-build-loop-u2a3`. Each exited 0. Counts: 14, 75, 19, 2, 2 = 112 ok, 0 not ok. Logs: `logs/bats-*.txt`.
- **E2** (finished 2026-10-06T23:29:27Z): the four mutants the commit names (nested-rules start, checkout-read guard, tr length check, link-escape guard), plus an unmutated baseline. Each was applied in a scratch copy `mut/<name>/` holding the lib, the bats file and the fixture lib, then run with `bats test/scripts/build-loop-check.bats` from that copy. Baseline rc=0. Every mutant rc=1: nested → test 6, guard → test 9, trlen → test 10, escape → test 7. Logs: `logs/mutant-{base,nested,guard,trlen,escape}.txt`.
- **E3** (about 2026-10-06T23:30Z, same method): 13 more single-point mutants: dup, treenl, untrnl, nulcnt, empty, linknl, abs, cklink, dircont, byname, blobfail, lsrc, pipefail. Every one rc=1. dup and treenl → test 5; untrnl, linknl and abs → test 7; nulcnt → test 9; empty → test 12; cklink → tests 9 and 12; dircont → test 9; byname → test 4; blobfail → tests 4, 8 and 14; lsrc → test 10; pipefail → test 14. Logs: `logs/mutant-<name>.txt`.
- **E4** (2026-10-06T23:30:58Z): `bash /tmp/u2a3-cfc-i1-S05k/probes.sh`, probes P1-P12. Each builds a probe repo under `p/` and calls the lib through an `imps` copy (`h.sh`). rc=0. Log: `logs/probes.txt`.
- **E5** (2026-10-06T23:32:20Z): `bash /tmp/u2a3-cfc-i1-S05k/probes2.sh`, probes P13 and P14. rc=0. Log: `logs/probes2.txt`.
- **E6**: `main_imports` timed three times on this worktree (2,966 entries on main): 0.387, 0.382 and 0.379 s. Log: `logs/timing.txt`.
- **E7**: a one-line bash check: `set -e; mapfile -t a < <(false; echo after)` gives an empty array, while `$(false; echo after)` gives `after`. So a process substitution inherits errexit (bash 5.2.15).

---

## Claim 1: "main_imports checks every tree record in bash ...: 0.4-0.5 s here against U2a's grep-filtered 0.2 s, ~2.1 s at 30k entries; a one-pass awk prototype cut that phase ~5x"

**Location:** `docs/reviews/override-log.md:365`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the figures as quoted from U2a2 iteration 2 performance F1, and this walk's cost on this repo today (about 0.38 s). Does not establish the 30k-entry figure or the awk prototype's speedup, which come from the performance reviewer's own fixture and were not rerun.
**Legibility-target:** for-orchestrator-synthesis

The source report has the figures: "the 400-500 ms walk, roughly double U2a's walk", the table row "(~0.45 s vs ~0.21 s), about 60× at 30k entries (2.1 s vs 0.03 s)", and "An awk pass prototype cut that phase 4-6×" (`docs/reviews/performance-reviewer-review-2026-10-06-build-loop-u2a2.md:65,115,121`). The rubric row B6 matches: "~0.4 s here; ~2.1 s at 30k entries" (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a2.md:66`). E6 measured 0.379-0.387 s here, at the low edge of the quoted range.

**Evidence:** `docs/reviews/override-log.md:365`, `docs/reviews/performance-reviewer-review-2026-10-06-build-loop-u2a2.md:65,115,121`, `/tmp/u2a3-cfc-i1-S05k/logs/timing.txt`

---

## Claim 2a: A5: the walk "closes A2 and A3's symlinked-file half ... (symlinked start files and targets on main are followed, `.claude/rules/` at any depth starts, and odd names, link text that is empty, absolute, leaves the repo or holds a newline or NUL, an unreadable checkout file, or a checkout symlink the walk would read fail it)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each closed or refused shape the row lists. Does not establish the row's gap list (Claim 2b), or whether Claude Code itself follows symlinks under `.claude/rules`.
**Legibility-target:** for-orchestrator-synthesis

The supporting evidence is in Claims 8, 9 and 10: symlink chains and targets on main are followed (P3), nested and untracked `.claude/rules` starts work (P2), and each refusal has a test that a mutant breaks (E2, E3).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:542-603`, `/tmp/u2a3-cfc-i1-S05k/logs/probes.txt`

---

## Claim 2b: A5: "but not start files under a symlinked directory ..., a path through a directory main stores as a symlink when the checkout lacks that link, other names one file has on a case-insensitive checkout, or absolute imports into the repo"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the row's gap list is complete. It is not: two shapes walk `ok` with a loaded file's imports unprotected. Does not establish whether Claude Code loads instruction files inside nested repos or submodules.
**Legibility-target:** for-author

The listed gaps are real (Claim 11a), but the list is not complete, and its qualifier "when the checkout lacks that link" implies the opposite case is caught. Two probes show otherwise.

- **P4.** Main stores `ld -> deep/inner` and `CLAUDE.md -> ld/../evil.md`, and `deep/evil.md` holds `evil @secret.md`. The checkout has the link. The kernel follows the link to `deep/evil.md`: `cat CLAUDE.md` printed `evil @secret.md`. The walk printed `walk: ok evil.md: imported deep/evil.md: - deep/secret.md: -`. The cause is lexical resolution, `out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" 2>/dev/null)" || out=..` (`scripts/lib/dev-cycle-read.sh:586`): `-s` collapses `ld/..` without consulting `ld`, so no checkout symlink is ever probed. The miss happens whether or not the checkout has the link.
- **P5.** An untracked nested repo `sub/` holds `CLAUDE.md` with `n @../docs/n.md`. `git ls-files --others` lists nothing for it, and the walk printed `walk: ok docs/n.md: -`. This is the override-log row "An instruction file inside an untracked nested repo or submodule is not a start file", whose revisit trigger is "U2a3's review (the gate walk's start set)". Neither A5 nor the code's "Not covered" list mentions it.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:586-587`, `docs/reviews/override-log.md:364`, `/tmp/u2a3-cfc-i1-S05k/logs/probes.txt` (P4, P5)

---

## Claim 3a: F11: "Floor item 1 walks main's commit (`main_imports`, U2a3: NUL-safe listings, symlinks on main followed, `.claude/rules/` at any depth and the checkout's untracked files as starts; a doubled name, a name holding a newline, link text that is empty, absolute, leaves the repo or holds a newline or NUL, an unreadable checkout file, or a checkout symlink it would read fails the walk ...)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's modelled and refused shapes. Does not establish "so floor refuses every path": `floor` does not exist yet (U2a4), so that clause is a plan statement.
**Legibility-target:** for-orchestrator-synthesis

Both listings are read with `-z` into `mapfile -d ''`: `git ls-tree -r -z --full-tree "$MAIN_SHA"` and `untracked_md` (`scripts/lib/dev-cycle-read.sh:549,559`). The other shapes are verified in Claims 8-10.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:549-603`

---

## Claim 3b: F11: "Gaps: known issue A5 (start files under a symlinked directory, a directory main stores as a symlink that the checkout lacks, case-insensitive names, absolute imports)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the gap list is complete. Same omissions as Claim 2b. Does not establish Claude Code's handling of nested repos.
**Legibility-target:** for-author

The same two omissions apply. P4: link text with `..` after a directory main stores as a symlink is resolved lexically, and the walk is ok whether or not the checkout has the link. P5: nested-repo and submodule instruction files are not starts.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `/tmp/u2a3-cfc-i1-S05k/logs/probes.txt`

---

## Claim 4: U2a3 bullet: "It refuses the tree and link shapes it does not model (a doubled name, a name holding a newline, empty, absolute, newline or NUL symlink text, a checkout symlink it would read)"

**Location:** `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parenthesized refusal list against the code. This line is unchanged context in the diff, but the task asked for it to be checked. Does not establish the other bullets' content.
**Legibility-target:** for-author

Every listed refusal exists. The list omits two refusals the code has, both fixed in this unit (B12 and B3): link text that leaves the repo (`[[ "$out" != .. && "$out" != ../* ]] || { IMPORTED_MAIN=error; return 1; }`, `scripts/lib/dev-cycle-read.sh:587`) and an unreadable checkout file (`out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }`, `:577`). A precise version would add "or leaving the repo" and "an unreadable checkout file", as F11 at :126 does.

**Evidence:** `docs/working/plan-build-loop-handoff.md:276`, `scripts/lib/dev-cycle-read.sh:577,587`

---

## Claim 5: U2b: "It names the checkout `--check` runs from (the walk reads its untracked starts, targets main lacks, and checkout symlinks)"

**Location:** `docs/working/plan-build-loop-handoff.md:278`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three checkout reads in main_imports. Does not establish anything about U2b's future code.
**Legibility-target:** for-orchestrator-synthesis

The three reads:

- Untracked starts: `mapfile -d '' recs < <(untracked_md && ...)` (`scripts/lib/dev-cycle-read.sh:559`).
- Targets main lacks: `if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); else queue+=("t:$p"); fi` (`:601`).
- The `t:` arm's `inrepo_here`, `-d`, `-e` and `-L` probes (`:576-579`).

No other checkout reads were found (paraphrased — no quote available because the claim covers absence of further reads in the unit read end to end, `:542-603`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:559,576-579,601`

---

## Claim 6: "inrepo, dirok, skipped, check_brief, isimported and the import walks exit 1 (need_root) unless ROOT_REAL is set ..."

**Location:** `scripts/lib/dev-cycle-read.sh:14-16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that main_imports and isimported run need_root before anything else. Does not re-verify need_root's three conditions, which were not changed here.
**Legibility-target:** for-orchestrator-synthesis

main_imports calls `need_root` before anything else (`:545`), and isimported calls it before `lower` (`:612`). need_root's checks `exit 1` (`:95-97`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:94-98,545,612`

---

## Claim 7: Inputs: main_imports reads "the default branch's commit, never the working tree ... (it also reads the checkout's untracked start files and imported files main lacks, which can only add imports, and needs resolve_main to have found main by name, or it fails)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-35`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the checkout reads never remove an import relative to main's commit, and the by-name precondition. Does not establish that the checkout symlink probes add nothing: they fail the walk, which is the fail-closed "imported for every path", consistent with "add".
**Legibility-target:** for-orchestrator-synthesis

**Can only add.** Every path main stores is read from main: `case "${ent[$f]}"` for `m:` items (`:582`). The queue picks `m:` whenever `ent` has the path (`:601`). The checkout's possible effects are:

- adding `t:` starts, including a duplicate start of a path main also stores. P8: a file on main, dropped from the index and rewritten in the checkout, gave `docs/m.md: imported docs/c.md: imported`, so both copies were read;
- reading targets main lacks;
- `continue` on an absent path or a plain directory, where main has nothing to read either;
- failing the walk.

None of these removes a main-derived import.

**By name.** `main_by_name || return 1` (`:548`). Mutant `byname` (test `[[ -n "$MAIN_SHA" ]]` only) fails test 4 (E3). P11 confirms a walk with `MAIN_BY_NAME=""` returns 1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:548,576-582,601`, `/tmp/u2a3-cfc-i1-S05k/logs/probes.txt` (P8, P11), `/tmp/u2a3-cfc-i1-S05k/logs/mutant-byname.txt`

---

## Claim 8: "it starts at every instruction file stored there (and every .md under a .claude/rules/ directory at any depth, which Claude Code also loads), plus the checkout's untracked ones"

**Location:** `scripts/lib/dev-cycle-read.sh:452-454`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start set: main's and the untracked list's instruction files, any case including `.MD`, and `.claude/rules/**.md` at any nesting, tracked or untracked. Does not establish "which Claude Code also loads" (Claude Code's loader was not read), or starts in nested repos and submodules (Claim 11b).
**Legibility-target:** for-orchestrator-synthesis

The start test is applied to both `m:` and `t:` candidates after one lower-casing: `if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]` (`:568`). In `[[ == ]]`, `*` crosses `/`, so `.claude/rules/sub/deep.MD` matches. P2 started from four untracked files and printed `walk: ok docs/r.md: imported docs/c.md: imported docs/s.md: imported x/docs/x.md: imported docs/o.md: -`: `.claude/rules/u.md`, `.claude/rules/CLAUDE.md`, `.claude/rules/sub/deep.MD` and `x/.claude/rules/n.md`. The upper-case `.MD` start has its own test (test 11). The nested-rules mutant fails test 6 (E2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:557,566-571`, `/tmp/u2a3-cfc-i1-S05k/logs/probes.txt` (P2), `/tmp/u2a3-cfc-i1-S05k/logs/mutant-nested.txt`

---

## Claim 9: "follows an import into the file main stores at that path, whatever its name; a symlink there is followed to the path its text names. A target main does not have is read from the checkout when it is a plain file there" (and ":578 a directory: nothing loads")

**Location:** `scripts/lib/dev-cycle-read.sh:455-457`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers symlink chains on main, a symlink to a directory, a target read from the checkout, and a checkout directory. Does not establish lexical-versus-physical resolution of link text (Claim 11b, P4).
**Legibility-target:** for-orchestrator-synthesis

P3 set up a chain `CLAUDE.md -> l2.md -> real.md` (real.md imports `@docs/deep.md`) and `AGENTS.md -> docs`. The walk printed `walk: ok l2.md: imported real.md: imported docs/deep.md: imported docs: imported`. The directory link was recorded and nothing below it was read. A link to `docs/missing.md`, which main lacks, read the checkout's plain file once it existed: `docs/m2.md: imported`. A plain checkout directory does `continue  # a directory: nothing loads` (`:578`), and mutant `dircont` fails test 9 (E3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:576-603`, `/tmp/u2a3-cfc-i1-S05k/logs/probes.txt` (P3)

---

## Claim 10: refused shapes: "a doubled name, a name holding a newline (in main's tree or the untracked list), symlink text that is empty, absolute, leaves the repo or holds a newline or a NUL, a checkout file it cannot read, and a checkout path it would read that is a symlink or lies under one fail the walk, so isimported main answers imported for every path"

**Location:** `scripts/lib/dev-cycle-read.sh:457-462`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape: each fails the walk, and a mutant removing its guard fails a test. Does not establish that the refusals cover every unmodelled shape (Claim 11b). The unreadable-file case was verified as uid 1000; as root, `chmod 000` would not block the read.
**Legibility-target:** for-orchestrator-synthesis

Guards and the mutant each one kills:

| Shape | Guard | Mutant → failing test |
|---|---|---|
| Doubled name in main's tree | `[[ -z "${ent[$f]+set}" && ...` (`:555`) | dup → test 5 |
| Newline in a name in main's tree | `... "$f" != *$'\n'* ]]` (`:555`) | treenl → test 5 |
| Newline in an untracked name | `for f in "${recs[@]}"; do [[ "$f" != *$'\n'* ]] || return 1` (`:562`) | untrnl → test 7 |
| NUL in link text | `[[ "$i" -ne 0 ]]` (`:583`) | nulcnt → test 9 |
| Empty link text | `-z "$out"` (`:585`) | empty → test 12 |
| Newline in link text | `*$'\n'*` (`:585`) | linknl → test 7 |
| Absolute link text | `/*` (`:585`) | abs → test 7 |
| Link text leaving the repo | `:587` | escape → test 7 |
| Unreadable checkout file | `:577` | guard → test 9 |
| Checkout symlink, or a path under one | `elif [[ -e "$f" || -L "$f" ]]` (`:579`) | cklink → tests 9 and 12 |

isimported answers imported after a failure via `main) main_imports || return 0` (`:615`), which test 8 checks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:555,562,576-587,615`, `/tmp/u2a3-cfc-i1-S05k/logs/mutant-*.txt`

---

## Claim 11a: "Not covered (known issue A5): start files under a symlinked directory (on main or in the checkout: neither listing enters one), a path through a directory main stores as a symlink when the checkout does not have that link, other names that one file has on a case-insensitive checkout, and absolute imports" (each listed item is a real gap)

**Location:** `scripts/lib/dev-cycle-read.sh:463-467`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the symlinked-directory starts (main and checkout) and absolute imports as real gaps. Does not establish the case-insensitive item (this Linux checkout is case-sensitive), or the list's completeness (Claim 11b).
**Legibility-target:** for-orchestrator-synthesis

The probes:

- **P7.** Main's `.claude/rules -> ../rr`, with `rr/q.md` importing `@../docs/q.md`, gave `walk: ok docs/q.md: -`.
- **P13.** An untracked `lnk` pointing at an outside directory that holds `AGENTS.md`: the untracked listing was empty, and the walk gave `walk: ok`.
- **Absolute imports.** import_targets drops them: `[[ -n "$t" && "$t" != "~"* && "$t" != /* ]] || continue` (`:497`).
- **Directory main stores as a symlink, absent from the checkout.** A `t:` path that does not exist does `else continue` (`:580`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:497,580`, `/tmp/u2a3-cfc-i1-S05k/logs/probes.txt` (P7), `/tmp/u2a3-cfc-i1-S05k/logs/probes2.txt` (P13)

---

## Claim 11b: The "Not covered" list (with the refusal list above it) accounts for the walk's gaps; in particular a path through a directory main stores as a symlink is a gap only "when the checkout does not have that link"

**Location:** `scripts/lib/dev-cycle-read.sh:463-467`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two fail-open shapes absent from the list. Does not establish how Claude Code resolves an `@` token holding `..` after a symlinked directory: P14 shows the token case is also lexical, which matches Node's `path.resolve` if Claude Code uses it (unverified).
**Legibility-target:** for-author

**P4: link text, `..` after a symlinked directory.** Link text is resolved with `realpath -ms`, which never consults a symlink (`out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" 2>/dev/null)" || out=..`, `:586`). A link on main whose text is `ld/../evil.md`, where main's `ld` is a directory symlink, is read as top-level `evil.md`. The kernel reads `deep/evil.md` (P4's `cat CLAUDE.md` printed its content). The walk was ok with `deep/secret.md: -`, and the checkout had the link. The qualifier "when the checkout does not have that link" is therefore wrong for link text: no checkout probe runs on the lexically collapsed path.

**P5: instruction files in an untracked nested repo or a submodule.** They are not starts. Main's gitlinks hit `*) continue ;;` (`:593`), and `git ls-files --others` does not descend into a nested repo. P5 printed `walk: ok docs/n.md: -`. The open override-log row on this names U2a3's review as its revisit trigger (`docs/reviews/override-log.md:364`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:586,593`, `docs/reviews/override-log.md:364`, `/tmp/u2a3-cfc-i1-S05k/logs/probes.txt` (P4, P5), `/tmp/u2a3-cfc-i1-S05k/logs/probes2.txt` (P14)

---

## Claim 12: "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit and root in IMPORTED_MAIN_DONE"

**Location:** `scripts/lib/dev-cycle-read.sh:467-470`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the source-time value, the reset on each new key, a cache hit after a failure (it keeps failing) and after a success. Does not establish freshness: the key omits checkout state and MAIN_BY_NAME (see Escalations).
**Legibility-target:** for-orchestrator-synthesis

The source-time value is `IMPORTED_MAIN=error` (`:470`). Each new key resets it: `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"` (`:547`). The partial list `$'\n'` is assigned only after the start set is built (`:573`), and every later `return 1` sets `error` first (`:577,579,583-587`). A hit returns the stored outcome: `{ [[ "$IMPORTED_MAIN" != error ]]; return; }` (`:546`).

P1 results, all in one shell:

- First call with the blob missing: `first:1 [error]`.
- Second call after restoring the blob: `second:1 [error]`. The cached failure stands.
- With the key cleared: `fresh:0`.
- After adding an untracked `CLAUDE.local.md` importing `docs/new.md`: `cached-after-untracked:0` and `new:-`. The successful result is reused, and the new start is not read.

**Evidence:** `scripts/lib/dev-cycle-read.sh:470,546-547,573`, `/tmp/u2a3-cfc-i1-S05k/logs/probes.txt` (P1)

---

## Claim 13: main_imports "returns 1, with IMPORTED_MAIN set to "error", when main is not found by name, the commit's tree or the untracked list cannot be listed whole, a tree record does not parse, the listing holds a name twice ..., a name holds a newline, a blob or checkout file cannot be read, symlink text ... or a checkout path it would read exists but is not a plain file ... or a plain directory"

**Location:** `scripts/lib/dev-cycle-read.sh:530-537`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` in `:542-603` against the list. Does not establish behavior when `lower` fails mid-loop (`:598`), which does not return 1. That is fixed in U2a3b (stacked).
**Legibility-target:** for-author

Every listed condition has a `return 1` (Claim 10, plus `:548,550,554,560`). One `return 1` is not listed: the short lower-cased candidate list, `[[ ${#low[@]} -eq ${#cand[@]} ]] || return 1` (`:565`). The commit's B3 bullet names it ("a short lower-cased start list (a failing tr)"), and test 10 pins it (mutant trlen → test 10, E2). A precise list adds "or the lower-cased start list comes back short".

Other ways the function ends, for completeness:

- need_root's `exit 1` (`:545`), documented in the header.
- A cache hit after a failure returns 1 (`:546`), consistent with the list.
- Mid-loop, `IMPORTED_MAIN+="$(lower "$p")"$'\n'` (`:598`): under a caller's bare `set -e` call, a failing `lower` ends the shell. Under `if` or `||`, it appends an empty line and the walk reports success. Fixed in U2a3b (stacked).

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-565,598`, `/tmp/u2a3-cfc-i1-S05k/logs/mutant-trlen.txt`

---

## Claim 14a: "(git's lookups read the first copy ..." of a doubled name

**Location:** `scripts/lib/dev-cycle-read.sh:532-533`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git cat-file -p <commit>:AGENTS.md` on a tree that lists AGENTS.md as a 120000 entry and then a 100644 entry. Does not establish other lookup paths (e.g. `git show`, the index).
**Legibility-target:** for-orchestrator-synthesis

In P10, `git ls-tree` showed both records, and `<commit>:AGENTS.md` returned `x`, the first (symlink) blob. This matches test 5's comment "(a symlink first, which git reads)".

**Evidence:** `/tmp/u2a3-cfc-i1-S05k/logs/probes.txt` (P10)

---

## Claim 14b: "... a checkout keeps the last)"

**Location:** `scripts/lib/dev-cycle-read.sh:533`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond noting the claim. Does not establish git checkout's behavior on a tree with doubled names.
**Legibility-target:** for-orchestrator-synthesis

Not run. Verifying it needs a `git checkout`/`read-tree` of a tree with a doubled entry, observing which blob lands (or whether git refuses). The walk refuses the shape either way (`:555`), so the parenthetical is rationale only.

**Evidence:** `scripts/lib/dev-cycle-read.sh:533,555`

---

## Claim 15: "The listings stay NUL-separated as git writes them, each followed by "rc=0" only when its command succeeded (the && and || keep errexit from ending the substitution early)"

**Location:** `scripts/lib/dev-cycle-read.sh:538-540`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rc marker on both listings and the errexit mechanism in a process substitution. Does not establish behavior when git succeeds yet prints a truncated listing.
**Legibility-target:** for-orchestrator-synthesis

The listings use `< <(git ls-tree -r -z --full-tree "$MAIN_SHA" && printf rc=0 || printf rc=1)` and `[[ ${#recs[@]} -gt 0 && "${recs[-1]}" == rc=0 ]] || return 1` (`:549-550`; same at `:559-560`). E7 shows a process substitution inherits errexit: `(false; echo after)` printed nothing. So without the `&&`/`||` chain, a failed git would end the subshell before `rc=1`. The guard is still safe in that case, since `recs[-1]` would not be `rc=0`. Mutant `lsrc` (accept any last element) fails test 10 (E3). The "substitution" is a process substitution.

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-561`, `/tmp/u2a3-cfc-i1-S05k/logs/mutant-lsrc.txt`

---

## Claim 16: "$(...) drops NULs, so they are counted first; the x keeps trailing newlines, which $(...) would also drop."

**Location:** `scripts/lib/dev-cycle-read.sh:581-582`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL count (`tr -cd '\0' | wc -c`) and the `x` sentinel. Does not establish lexical-versus-physical resolution of the text afterwards (Claim 11b).
**Legibility-target:** for-orchestrator-synthesis

The code is `if ! i="$(git cat-file blob "$MAIN_SHA:$f" | tr -cd '\0' | wc -c)" || [[ "$i" -ne 0 ]] || ! out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"; then ...; fi; out="${out%x}"` (`:583-585`). Mutant `nulcnt` fails test 9, whose `docs/rules.md\0zzz` text would otherwise be followed as `docs/rules.mdzzz`. Mutant `linknl` fails test 7, whose `$'notes.md\n'` text depends on the `x`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:583-587`, `/tmp/u2a3-cfc-i1-S05k/logs/mutant-nulcnt.txt`, `/tmp/u2a3-cfc-i1-S05k/logs/mutant-linknl.txt`

---

## Claim 17: isimported: "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; a caller that words a failed walk runs main_imports first. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:604-608`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers isimported's three arms and the cached-failure path. Does not establish caller behavior: no caller of `isimported main` or `main_imports` exists yet (grep: only the lib, build-loop-check.bats and dev-cycle.bats's sourcing test).
**Legibility-target:** for-orchestrator-synthesis

The arms are `main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;` and `*) return 0 ;;` (`:615-617`). Tests 2, 8 and 14 assert "imported" under `if` for a bogus name and for failed walks. Since isimported returns 0 for both "imported" and "walk failed", only main_imports' own return can tell the two apart, which the advice about wording a failed walk reflects. A cache hit after a failure still answers imported (P1 `second:1`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:610-619`, `test/scripts/build-loop-check.bats:40,161,258`

---

## Claim 18: Test names and comments in build-loop-check.bats assert what they say (no false passes)

**Location:** `test/scripts/build-loop-check.bats:46-266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 12 new or changed main-walk tests: each named guard is load-bearing per 17 single-point mutants (all killed). Also covers test 3's comment "a symlink first, which git reads" (P10). Does not establish coverage of untested behaviors: no test covers an untracked `.claude/rules` start, a symlink chain on main, or the cache (P1-P3 cover them here).
**Legibility-target:** for-orchestrator-synthesis

Each test's named shape has a mutant that fails it (E2, E3; mapping in Claims 10, 13, 15, 16). Test 4's "the walk reads again, so the next failure is the name alone" holds: `imps` runs each walk in a fresh bash (`bash -c` at `:17-21`), so there is no cache carry-over, and mutant `byname` fails test 4. Test 8 asserts `want walk ok` before its NUL check (`:166`), so a failed walk would not pass it. The test-12 comment "Empty symlink text in sub/ would name sub/ itself, a plain directory here" is confirmed: mutant `empty` fails test 12, which shows the failure comes from the `-z "$out"` guard and not from the directory arm.

**Evidence:** `test/scripts/build-loop-check.bats:13-24,46-266`, `/tmp/u2a3-cfc-i1-S05k/logs/mutant-*.txt`

---

## Claim 19: fbeae280: "Split from U2a2 at its review's iteration 2 (size). The walk is the one U2a2 iterations 1-2 reviewed (commits d8003fbf and 7f295cdb, kept on feat/build-loop-u2a3-src), stacked on U2a2's shared token parser"

**Location:** commit fbeae280 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both commits exist and are ancestors of `feat/build-loop-u2a3-src`, and that the branch sits on main, which holds U2a2's parser. Does not establish line-by-line identity of the walk with those commits.
**Legibility-target:** for-orchestrator-synthesis

`git cat-file -t` shows `commit` for both, and `git merge-base --is-ancestor` succeeds for both against `feat/build-loop-u2a3-src`. Its tip, 9b658b2b, reads "U2a2 review iteration 2 ... split: main_imports moves to U2a3". Main contains the U2a2 merge 1ffb72d4.

**Evidence:** `git log feat/build-loop-u2a3-src`, `git log main` (paraphrased — no quote available because the claim is about commit ancestry, not a file snippet)

---

## Claim 20: fbeae280 B2, B3, B12, B8 bullets: nested `.claude/rules` starts; "a checkout file the walk cannot read fails it (under `if` the walk used to continue and drop that file's imports), and so does a short lower-cased start list (a failing tr)"; link text leaving the repo "fails the walk (it was skipped ...)"; "IMPORTED_MAIN reads "error" until a walk succeeds"

**Location:** commit fbeae280 message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each fix against the pre-fix code on `feat/build-loop-u2a3-src` and against HEAD. Does not establish whether Claude Code loads `.claude/rules` at any depth.
**Legibility-target:** for-orchestrator-synthesis

Before and after, from the src branch's main_imports to HEAD:

| Row | Before (src) | After (HEAD) |
|---|---|---|
| B2 | Start test `|| "$f" == .claude/rules/*.md ]]` (top-level only) | Adds `*/.claude/rules/*.md` |
| B3 | `if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")"`, with no failure arm | `:577` fails the walk; `:565` checks the lower-cased list length |
| B12 | `... 2>/dev/null)" || continue` and `[[ "$out" != .. && "$out" != ../* ]] || continue ;;` | `:586-587` fail the walk |
| B8 | Initial value `IMPORTED_MAIN=$'\n'` (src :468) | Initial value `IMPORTED_MAIN=error` (`:470`) |

The E2 mutants for B2, B3 (both halves) and B12 each fail.

**Evidence:** `git show feat/build-loop-u2a3-src:scripts/lib/dev-cycle-read.sh` (main_imports), `scripts/lib/dev-cycle-read.sh:470,565,568,577,586-587`

---

## Claim 21: fbeae280 B4, B10, B11: the not-covered list names symlinked-directory starts; the header names the resolve_main precondition; "plan F11 and the U2b bullet name the three checkout reads ...; known issue A5 updated"

**Location:** commit fbeae280 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers presence of each wording change. Does not establish the gap lists' completeness (Claims 2b, 3b, 11b).
**Legibility-target:** for-orchestrator-synthesis

Each change is present:

- The not-covered list has "start files under a symlinked directory" (`scripts/lib/dev-cycle-read.sh:463`).
- The header has "needs resolve_main to have found main by name" (`:34`).
- F11 has "The walk reads the checkout for its untracked starts, for targets main lacks, and for whether a path it would read is a symlink" (`plan:126`). U2b has "(the walk reads its untracked starts, targets main lacks, and checkout symlinks)" (`plan:278`).
- A5 differs from the src branch's version, which lacked the symlinked-directory and unreadable-file wording. A5 is new relative to main, so "updated" is relative to the src branch.

**Evidence:** `scripts/lib/dev-cycle-read.sh:34,463`, `docs/working/plan-build-loop-handoff.md:126,278`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 22: fbeae280 B5: "test 2 checks the name rule alone, test 8 asserts the walk succeeded, and new tests cover upper-case .MD starts, a dangling checkout link, a directory under a checkout link, empty link text below the top level, a cycle, and a caller without pipefail"

**Location:** commit fbeae280 message
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed test change. Does not establish the Appendix-A patch's other contents.
**Legibility-target:** for-author

Every change is present and load-bearing (mutants byname → test 4; empty → test 12; pipefail → test 14). The numbering is mixed, though:

- "test 2" uses the pre-split numbering. The test-strategy report's G8 says "test 2's ... case (build-loop-check.bats:52-55)", and that test is now test 4 (`:63`).
- "test 8" uses the current numbering. The report called the NUL test "test 6" (G9), and it is now test 8 (`:161`).

A precise version says "test 4 (the old test 2)" or names the tests.

**Evidence:** `test/scripts/build-loop-check.bats:63-79,161-171`, `docs/reviews/test-strategy-review-2026-10-06-build-loop-u2a2.md:35-36`

---

## Claim 23: fbeae280 B6: "override row (Defer, trigger: U2c's --check over 1 s at 10k+ entries)"

**Location:** commit fbeae280 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the row exists with that decision and trigger. Does not establish the row's figures (Claim 1).
**Legibility-target:** for-orchestrator-synthesis

The row reads "| Defer | ... Revisit trigger: U2c's --check measured over 1 s on a repo with 10k+ tracked entries" (`docs/reviews/override-log.md:365`).

**Evidence:** `docs/reviews/override-log.md:365`

---

## Claim 24: fbeae280: "Tests: build-loop-check.bats 14; 112 across the five suites"

**Location:** commit fbeae280 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and that all pass at HEAD. The five suites are taken as the list a prior main commit names ("dev-cycle, build-loop-read, build-loop-check, fixture-git-env and hermeticity"), with "hermeticity" read as `test/fixture-hermeticity.bats` (2 tests). `test/hermeticity-lint.bats` has 53, which would not sum to 112.
**Legibility-target:** for-orchestrator-synthesis

E1: 14 + 75 + 19 + 2 + 2 = 112 ok, 0 not ok.

**Evidence:** `/tmp/u2a3-cfc-i1-S05k/logs/bats-*.txt`

---

## Claim 25: fbeae280: "Mutants of the nested-rules start, the checkout-read guard, the tr length check (via a failing tr shim) and the link-escape guard each fail."

**Location:** commit fbeae280 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one natural mutant per named guard, each run against build-loop-check.bats. Does not establish that every possible mutant of those lines is killed.
**Legibility-target:** for-orchestrator-synthesis

E2: nested → test 6 fails; guard (`|| true`) → test 9; trlen (line removed) → test 10, the tr-shim test; escape (line removed) → test 7.

**Evidence:** `/tmp/u2a3-cfc-i1-S05k/logs/mutant-{nested,guard,trlen,escape}.txt`

---

## Claim 26: fbeae280: "344 changed code lines against U2a2"

**Location:** commit fbeae280 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers insertions plus deletions under scripts/ and test/, against main (which holds U2a2) and against fbeae280's parent. Does not establish the counting convention beyond matching the plan's "outside docs/".
**Legibility-target:** for-orchestrator-synthesis

`git diff main...HEAD --numstat -- scripts test` sums to 106+9 + 223+2 + 2+2 = 344. The same sum over fbeae280's own diff is also 344.

**Evidence:** `git diff main...HEAD --numstat` (paraphrased — no quote available because the claim is a computed sum over numstat rows)

---

## Claim 27: fbeae280 Notes: "Whether Claude Code follows symlinks under .claude/rules is unverified here (fact-check U2a2 i2 Claim 22); the walk follows them, which can only add imports."

**Location:** commit fbeae280 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers how the walk treats symlinks under `.claude/rules` in three placements. Does not establish Claude Code's own behavior.
**Legibility-target:** for-author

The walk follows only one of the three kinds of symlink:

- **A symlinked file on main under `.claude/rules` is followed.** P6, after commit: `walk: ok docs/z.md: imported docs/t.md: imported`.
- **An untracked symlink there is not followed; it fails the walk.** P6, before commit: `walk: failed`. The cause is the `t:` arm's `elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1` (`scripts/lib/dev-cycle-read.sh:579`).
- **A `.claude/rules` directory stored as a symlink is not entered.** P7: `walk: ok docs/q.md: -`. This is the listed gap.

"Can only add imports" holds for the first two (following adds; failing closes). For the third, "the walk follows them" is not true. A precise version says "follows symlinked files under .claude/rules on main; fails on an untracked one; a symlinked rules directory is the A5 gap".

**Evidence:** `scripts/lib/dev-cycle-read.sh:579,582-587`, `/tmp/u2a3-cfc-i1-S05k/logs/probes.txt` (P6, P7)

---

## Claim 28: 45ad17b0: "A5 names U2a3 as main_imports' unit (U2a2 final fact-check E4)"

**Location:** commit 45ad17b0 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the one-word change and the cited source item. Does not establish anything else in A5.
**Legibility-target:** for-orchestrator-synthesis

The commit's diff changes "(`main_imports`, U2a2)" to "(`main_imports`, U2a3)" in A5. The final U2a2 report has "E4 (r1 → U2a3 review): U2a3's known-issues A5 says "(main_imports, U2a2)"" (`docs/reviews/code-fact-check-report-build-loop-u2a2-final.md:117`).

**Evidence:** `git show 45ad17b0`, `docs/reviews/code-fact-check-report-build-loop-u2a2-final.md:117`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2b** (`docs/working/known-issues-dev-cycle.md:18`): A5's gap list omits two shapes. (1) Link text on main holding `..` after a directory symlink is resolved lexically, so the walk is ok while the kernel loads another file (P4), even when the checkout has the link. (2) Instruction files in untracked nested repos or submodules are not starts (P5).
- **Claim 3b** (`docs/working/plan-build-loop-handoff.md:126`): F11's "Gaps" list has the same two omissions.
- **Claim 11b** (`scripts/lib/dev-cycle-read.sh:463-467`): The "Not covered" list has the same omissions, and its qualifier "when the checkout does not have that link" is wrong for link text, which `realpath -ms` (`:586`) collapses without any checkout probe.

### Mostly Accurate
- **Claim 4** (`docs/working/plan-build-loop-handoff.md:276`): The U2a3 bullet's refusal list omits link text leaving the repo and an unreadable checkout file.
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:530-537`): The return-1 list omits the short lower-cased candidate list (`:565`).
- **Claim 22** (commit fbeae280 B5): "test 2" is the pre-split number (now test 4), while "test 8" is the current number.
- **Claim 27** (commit fbeae280 Notes): The walk follows symlinked files under `.claude/rules` on main, but fails on an untracked one and does not enter a symlinked rules directory.

### Unverifiable
- **Claim 14b** (`scripts/lib/dev-cycle-read.sh:533`): "a checkout keeps the last" of a doubled name. Needs a checkout or read-tree of a doubled-entry tree.

## Escalations

- **security-reviewer.** `scripts/lib/dev-cycle-read.sh:586`: link text on main is resolved with `realpath -ms`, which is lexical, while the kernel resolves symlink text physically. P4: `CLAUDE.md -> ld/../evil.md` with `ld -> deep/inner` loads `deep/evil.md`, but the walk is ok with `deep/secret.md: -`, a fail-open floor answer. Assess whether link text holding a `..` part should fail the walk, as other unmodelled link shapes do.
- **security-reviewer.** `scripts/lib/dev-cycle-read.sh:557-559,593`: instruction files in an untracked nested repo or a submodule (gitlink) are not starts (P5). The open override-log row (`docs/reviews/override-log.md:364`) names this review as its revisit trigger. Decide whether to refuse, model or re-defer it, and record it in A5 either way.
- **architecture-review / security-reviewer.** `scripts/lib/dev-cycle-read.sh:546-547`: the cache key is `"$MAIN_SHA $ROOT_REAL"`. It omits checkout state and MAIN_BY_NAME. P1: an untracked start added after a successful walk is not read by a second call in the same shell (fail-open if U2a4 or U2b walks before the checkout changes). P11: a failed walk with `MAIN_BY_NAME=""` stays failed after it is set (fail-closed). Relevant to U2a4's caller design.
- **test-strategy.** `test/scripts/build-loop-check.bats`: no test covers an untracked `.claude/rules` start (P2), a symlink chain on main (P3), or the cache (P1). Mutating the start test's `t:` handling or the cache key would go undetected.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to docs/reviews/code-fact-check-report-build-loop-u2a3.md verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages.
- Answered: all ten claim groups the task listed (32 verdicts). The commit's four mutants were rerun, plus 13 more, all killed. Fourteen behavior probes were run (P1-P14) for the cache, the start set, symlink chains, nested repos and lexical link resolution. The commit's counts (14, 112, 344) were recomputed and match.
- Out of scope: Claude Code's own loader behavior (`.claude/rules` depth and symlinks, `@` resolution of `..`, nested repos). A case-insensitive checkout. The parser and `lower`-failure behaviors fixed in U2a3b (stacked). Code-quality and performance judgments.
- Escalate: P4 (lexical link-text `..`, fail-open) and P5 (nested-repo and submodule starts, an override-row trigger) to security-reviewer. The cache key (P1, P11) to architecture and security. The P1-P3 coverage gaps to test-strategy.
