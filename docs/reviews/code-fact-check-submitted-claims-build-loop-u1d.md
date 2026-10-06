Commit: ab71bce5

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1d (branch feat/build-loop-u1d)
**Scope:** Submitted claims S1-S2 only (Stage 2.5 of the final confirming pass, k=1). No fresh harvesting. Numbering continues from the merged report's Claim 20.
**Checked:** 2026-10-06
**Total claims checked:** 2
**Summary:** 1 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution setup, shared by both claims. Scratch directory: `$S` = `/tmp/claude-1000/-workspace/57e599b8-f769-48da-96c7-3a02f99f2a8d/scratchpad/review-u1d/f-s25`. The worktree's own `scripts/` at HEAD ab71bce5 ran against throwaway repos under `$S`, with `GIT_CONFIG_NOSYSTEM=1`, `GIT_CONFIG_GLOBAL=/dev/null` and `HOME=$S`. No tracked file was modified apart from this report. Every process ran under `timeout 60` and has exited. Installed locales: `C`, `C.utf8`, `POSIX` (`locale -a`). **`en_US.UTF-8` is not installed in this sandbox.** No logged hallucination pattern applies to these claims.

---

## Submitted Claims

## Claim 21: "main_entry refuses (answers `error`, before any git call) every path form pathform refuses, in the C, C.UTF-8 and en_US.UTF-8 locales: empty, trailing slash, `.GIT`/`.Git`, `:(top)`, `*`, newline, tab, non-ASCII, full-width, absolute, `.` and `..` components, `--`. `docs/a.md` reads blob and `x` reads absent."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:265`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_entry at HEAD for the 22 refused forms probed (every class the claim lists, plus `.git/x`, `docs/..`, `-x` and `docs//a.md`) and the two accepted paths, with git calls counted by a PATH shim, in `LC_ALL=C` and `C.UTF-8`, plus a requested `en_US.UTF-8`. It does not establish behaviour in a real installed `en_US.UTF-8`: that locale is missing here, so bash warned and fell back to C. Locale independence in a real UTF-8 locale rests on the `C.UTF-8` run and on the literal `NAMECHARS` list. It also does not establish that "every" refused form beyond the probed classes behaves the same; that rests on the static reading below. Nor does it cover callers that skip main_entry (U2's floor does not exist yet).

Static reading of the whole unit, `main_entry` (`scripts/lib/dev-cycle-read.sh:262-276`, read to its last line). The guard is the first statement after the locals:

```bash
# scripts/lib/dev-cycle-read.sh:262-266
main_entry() {
  local p="" rest="$1" out mode path dup="" want=()
  local -A m=()
  if ! main_by_name || ! pathform "$1"; then echo error; return; fi
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
```
(excerpt ends :266; enclosing main_entry() continues to :276 — read)

The first git call is `git ls-tree` at `:267`, which comes after the guard. Neither guard function calls git. `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` is at `:247`. pathform (`:142-151`) uses only bash tests: `[[ "$p" =~ $set && "$p" != /* && "$p" != -* ]] || return 1` (`:145`), then a per-component check, `[[ -n "$c" && "$c" != "." && "$c" != ".." && "$c" != [.][gG][iI][tT]* ]] || return 1` (`:149`). The allowed set is the literal `NAMECHARS='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._/-'` (`:141`). It contains no ranges, so the locale cannot widen it.

Execution, part 1: the probe. Command: `timeout 60 env -i HOME=$S PATH=/usr/bin:/bin GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null LC_ALL=$loc bash $S/probe1.sh <lib> $S/shim $S/logs $loc`, for loc in C, C.UTF-8 and en_US.UTF-8. cwd `$S/repo`, a repo with `docs/a.md` committed on `main`. Exit 0 for all three. Run at 2026-10-06T05:49:58Z. The probe sources the lib and runs `resolve_main`. It then puts `$S/shim` first on PATH. That shim is a `git` wrapper that logs each call and then execs `/usr/bin/git`. The probe calls `main_entry` once per path with a fresh log for each call. The result was the same in all three locales: all 22 refused forms answered `error gitcalls=0`; `docs/a.md` answered `blob gitcalls=1` and `x` answered `absent gitcalls=1`. The log for the accepted path shows the shim records real calls: `git ls-tree -t --full-tree 09c86e5a… -- docs docs/a.md`. The en_US.UTF-8 run printed `bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)`, which shows the C fallback.

Execution, part 2: a control and a cross-check.
- Mutant control. A copy of the lib with `:265` reverted to main's `main_by_name || { echo error; return; }` went through the same probe in `LC_ALL=C` (exit 0). Every path made 1 git call. Most refused forms then answered `absent` (`docs/` answered `absent`, `docs/a.md/` answered `notdir docs/a.md`, and `--`, `:(top)docs/a.md` and `docs/café.md` all answered `absent`). Only `''`, `/docs/a.md` and `..` still answered `error`, because ls-tree itself refused them. So the probe tells the guard apart from its absence.
- GIT_TRACE cross-check. `export GIT_TRACE=$S/logs/s1-gittrace.txt` was set after `resolve_main`, and then main_entry ran on `--`, `:(top)docs/a.md` and `docs/../docs/a.md`. It printed three `error` lines and wrote `no trace file`, so git was never started.

**Evidence:** `scripts/lib/dev-cycle-read.sh:141-151`, `scripts/lib/dev-cycle-read.sh:247`, `scripts/lib/dev-cycle-read.sh:262-276`. Logs: `$S/logs/s1-output.txt`, `$S/logs/s1-mutant-output.txt`, `$S/logs/s1-gittrace-output.txt`, `$S/logs/s1-timestamp.txt`, the per-call shim logs `$S/logs/<locale>-<n>.log`, and the probe script `$S/probe1.sh`.

---

## Claim 22: "`--status` prints the could-not-be-listed skip for every open brief whenever git grep exits above 1."

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:313-314`, `:340` as submitted. At HEAD the comment is `:310-314`, the exit test `:316` and the skip line `:343`.
**Type:** Error-handling / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--status` at HEAD when git grep exits 128, caused three ways: a repo-config `grep.patternType=bogus`, the same pair passed through the caller's `GIT_CONFIG_COUNT`, and a corrupt loose object (one blob, and separately the `briefs/closed` tree). It also covers open, done, dropped, new and malformed briefs, all in one invocation. The skip is printed for every open brief that passes check_brief and the Branch:/Dispatched: parsing. An open brief that fails one of those earlier checks gets its own earlier skip line instead, and that line is still a refusal. It does not establish git exit codes for failure causes not tried, such as a promisor or partial clone.

The mechanism is correct, and so is the fail-closed conclusion. Its two parts:
- shared_branches sets the sentinel on any exit above 1. `list="$(git grep --no-color -l -E '^Status: open'$'\r''?$' "$MAIN_SHA" -- docs/working/briefs/)" || rc=$?` (`scripts/build-loop.sh:315`), then `if [[ "$rc" -gt 1 ]]; then SHARED_BRANCHES=error; return; fi` (`:316`).
- status_line computes the sentinel once (`[[ -n "$SHARED_BRANCHES" ]] || shared_branches`, `:328`). The dispatch loop `for a in "${ARGS[@]}"; do status_line "$a"; done` (`:368`) calls status_line in the main shell, so every brief sees `error`. The skip is `if [[ "$st" == open && "$SHARED_BRANCHES" == error ]]; then echo "skip $a: the open briefs on the default branch could not be listed"; return; fi` (`:343`).

"Every open brief" needs a qualifier. Reading status_line in full (`:326-363`) shows four earlier returns that come before `:343`, each with its own line:
- check_brief not `ok` (`:330`)
- `skip $a: the brief is not read` (`:334`)
- `no Branch: line` (`:335`)
- the malformed Branch:/Dispatched: skips (`:336`, `:339-340`)

So an open brief that fails any of these prints its own skip, not the could-not-be-listed one. The submitted line numbers are also 2-3 lines early. The security report's own body cites `:315-316` and `:343`, which are correct.

Execution. Command: `timeout 60 bash /workspace/.claude/wt-build-loop-u1d/scripts/build-loop.sh --status <11 briefs>`, run via `$S/run-s2.sh`. cwd `$S/repo2` (and copies of it). `LC_ALL=C`. Exit 0 for every run. Start time 2026-10-06T05:50:29Z.
- Control. With no fault, four open briefs printed `ok … open …`; this group includes a CRLF brief and one in `closed/`. Also in that run: a done brief printed `ok`, a dropped brief printed `ok`, and a new brief printed `ok … new`. Four malformed briefs printed their own skips: bad Branch, Dispatched 100, no Branch, and `Status: Open`.
- `git config grep.patternType bogus`, with git grep's rc confirmed as 128. All four valid open briefs printed `skip <a>: the open briefs on the default branch could not be listed`. Done, dropped and new still printed `ok`. The open briefs with a bad Branch, a bad Dispatched or no Branch line printed their earlier skips, not the could-not-be-listed one.
- The caller pair `GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=grep.patternType GIT_CONFIG_VALUE_0=bogus` gave identical output.
- A corrupt loose blob (the dropped brief's) gave git grep rc 128, and all four open briefs printed the skip. A corrupt `briefs/closed` tree also gave rc 128: the three open briefs in `briefs/` printed the skip, and the brief inside the corrupt tree printed check_brief's `the tree of the default branch could not be read`. This closes the security report's "Not verified: a corrupt tree object" hop.

Outside the claim and not verdicted: under the bogus `grep.patternType`, git printed `fatal: bad grep.patterntype argument` twice per brief from calls other than shared_branches' git grep. These look like check_brief's `git log -G` lookups (`scripts/lib/dev-cycle-read.sh:361-362`). That is the already-deferred family of git log failures under a broken config, so it is not filed here.

**Evidence:** `scripts/build-loop.sh:306-325`, `scripts/build-loop.sh:326-363`, `scripts/build-loop.sh:365-369`, `scripts/lib/dev-cycle-read.sh:325-364`. Logs: `$S/logs/s2-output.txt`, `$S/logs/s2-corrupt-output.txt`, `$S/logs/s2-timestamp.txt`, and the runner `$S/run-s2.sh`.

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 22** (`scripts/build-loop.sh:343`): the skip covers every open brief that passes check_brief and the Branch:/Dispatched: parse; malformed open briefs get their own earlier skip (still a refusal). The cited lines should be `:310-316` and `:343`, not `:313-314` and `:340`.

## Goal-Alignment Note
- Success criterion (restated verbatim): A report saved to docs/reviews/code-fact-check-submitted-claims-build-loop-u1d.md (overwriting iteration 1's), first line `Commit: ab71bce5`, with a `## Submitted Claims` section, claims numbered 21 and 22 (the merged report ends at Claim 20), each with Location, Type, Verdict, Confidence, Verification mode, Scope, Evidence and **Submitted by:**.
- Answered: yes. Both claims were executed on scratch repos. Claim 21 is Verified, and its scope names the residue: en_US.UTF-8 is not installed, so that run is the C fallback. Claim 22 is Mostly accurate: the fail-closed behaviour holds, but "every open brief" needs the earlier-skip qualifier, and the line citations are off by 2-3.
- Out of scope: the security report's non-routed endorsement (the replace-ref step), and the stray `fatal:` lines from check_brief's git log under a broken config (already deferred).
- Escalate: nothing.
