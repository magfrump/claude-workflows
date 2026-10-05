Commit: 497c8cb5
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-handoff (claude-workflows)
**Scope:** U0a full range `feat/build-loop-handoff..feat/build-loop-u0a` (4ef450da, 32b9ae0e, 497c8cb5): `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `test/scripts/dev-cycle.bats`, and the three commit messages. Final confirming pass, replicate 2 of 3.
**Commit:** 497c8cb5
**Checked:** 2026-10-05
**Total claims checked:** 15
**Summary:** 12 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read. The relevant prior pattern is wrong test counts in commit messages ("All 85 tests…", "mode1-equiv 33"). Every count in this range was checked against a bats run and matches.

Shared execution provenance. SCRATCH = `/home/node/.claude/jobs/989f3e5a/tmp/review/final-fc-r2`. Each unit tip and main were checked out as detached worktrees under SCRATCH, and those worktrees were removed before this report was written.
- **E-bats:** `timeout 600 bats test/scripts/dev-cycle.bats`. Run in `SCRATCH/wt-{main,u0a,u0b,u0c}` at 2026-10-05T07:32:12–14Z. Exit 0 for all four. Counts: main 53, u0a 56, u0b 58, u0c 59. All 53 of main's test names are present at each tip. Output in `SCRATCH/logs/bats-*.txt`.
- **E-modes:** `bash SCRATCH/runmodes.sh <tree>` runs that tree's `scripts/dev-cycle.sh` against main's checkout with `DEV_CYCLE_TODAY=2026-10-05`. It covers the plain digest, `--since=2026-09-01 --sample=3`, and all six `--check-*` modes with mixed arguments. Run in SCRATCH at 07:32:53Z, exit 0. `cmp` shows main's output byte-identical to u0a's, u0b's and u0c's. Output in `SCRATCH/logs/modes-*.txt`.
- **E-mut:** `timeout 1200 bash SCRATCH/mutate.sh` copies a unit tip's scripts/ and test/, applies one perl edit to the lib, and runs the named bats test. Run in SCRATCH at 07:34:12Z, exit 0. Output in `SCRATCH/logs/mutations.txt` and `SCRATCH/mut/*.out`.
- **E-probe1 / E-probe2:** `timeout 60 bash SCRATCH/probe1.sh` (07:33:35Z) and `LC_ALL=C timeout 120 bash SCRATCH/probe2.sh` (07:35:52Z). Both ran in SCRATCH and exited 0. probe2 runs the lib as it was at each named commit, extracted with `git show <c>:scripts/lib/dev-cycle-read.sh`. Output in `SCRATCH/logs/probe1.txt` and `SCRATCH/logs/probe2.txt`.
- **E-moved:** the lines removed from dev-cycle.sh between main and u0c, diffed against the u0c lib. Per-commit versions: `diff rm-<c>.txt add-<c>.txt` for 4ef450da, 0b53fe50 and 41065ce6. Output in `SCRATCH/logs/moved-diff.txt`.

---

## Claim 1: "The dev cycle's reader, used by scripts/dev-cycle.sh and kept apart so the planned scripts/build-loop.sh can share it: the output scrub, the plain-file and path-form rules, and the cycle's own file names."

**Location:** `scripts/lib/dev-cycle-read.sh:2-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that dev-cycle.sh is the lib's only caller at this tip, that build-loop.sh does not exist yet, and that the listed groups are what the lib defines. It does not establish anything about build-loop.sh's future use.
**Legibility target:** for-orchestrator-synthesis

At u0a the lib defines `scrub`, `scrub_reexec`, `need_root`, `rawfile`, `plaindir`, `blocker`, `inrepo`, `dirok`, `skipped`, `pathform`, `isbrief` and `writable`. That matches the three named groups. (Paraphrased: no quote available because the claim is about which symbols the file defines; T29 at this tip lists the same set.) `ls scripts/build-loop.sh` fails at every tip, and the only file that sources the lib is dev-cycle.sh. (Paraphrased: no quote available because the claim covers absence of code, based on a grep of `scripts/` with no other match.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:1-143` (u0a), `scripts/dev-cycle.sh:82-89`

---

## Claim 2: "Sourced, never run: it only defines functions and variables. Each script sources it from its own directory (never from the repo it acts on)"

**Location:** `scripts/lib/dev-cycle-read.sh:6-8`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what sourcing the lib does at top level (assignments and function definitions only, with no git or perl call) and dev-cycle.sh's source path. It does not establish anything about callers other than dev-cycle.sh.
**Legibility target:** for-orchestrator-synthesis

The file is mode 644 (not executable). dev-cycle.sh reads it from `READ_LIB="$SCRIPT_DIR/lib/dev-cycle-read.sh"` (`scripts/dev-cycle.sh:85`), with `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` resolved before the `cd "$ROOT"` (`:82`). T29 passes, and E-mut's mutant `a-t29-git-call` adds `git --version` at top level, which T29 catches (KILLED).

**Evidence:** `scripts/dev-cycle.sh:82-89`, `test/scripts/dev-cycle.bats` T29, `SCRATCH/logs/mutations.txt`

---

## Claim 3: "inrepo, dirok and skipped exit 1 (need_root) when ROOT_REAL is unset or is not the current directory; rawfile, plaindir and blocker then read nothing as plain."

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three exiting checks and the three fail-closed readers at u0a, in both conditions (ROOT_REAL unset, and ROOT_REAL set to another directory). It does not establish that later units' lib functions are listed (see the u0c report, Claim 1).
**Legibility target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:93-97 (u0a)
inrepo() { need_root; [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }
...
dirok() { need_root; [[ -z "$(blocker "$1" dir)" && -d "$1" ]]; }
skipped() { need_root; SKIP_AT="$(blocker "$1" "${2:-file}")"; ...
```

E-probe1 P3 shows `blocker link.md file` printing `link.md` (blocked) with ROOT_REAL unset. P4 shows a regular file reported as blocked at `docs/` when ROOT_REAL names another directory. E-mut kills every guard mutant: `a-inrepo-noneed`, `a-dirok-noneed`, `a-skipped-noneed`, `a-rawfile-guard`, `a-plaindir-guard` and `a-pwd-check`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:64-97`, `SCRATCH/logs/probe1.txt`, `SCRATCH/logs/mutations.txt`

---

## Claim 4: "Call the exiting checks in the caller's shell, not inside $(...) or `local x="$(...)"`, where an exit ends only the subshell."

**Location:** `scripts/lib/dev-cycle-read.sh:12-14`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that need_root's `exit` inside a command substitution ends only that subshell, and that dev-cycle.sh calls inrepo, dirok and skipped in its own shell. It does not establish what the caller does next. Under the header's own `set -e`, a plain `x="$(check)"` then ends the caller too, while `local x="$(...)"` continues with an empty value (E-probe1 P7).
**Legibility target:** for-orchestrator-synthesis

E-probe1 P7: `x="$(check_brief …)"` under `set -euo pipefail` ends the caller with rc=1. `local x="$(check_brief …)"` prints `after local x=[]` and the caller exits 0. Every use in dev-cycle.sh is in the caller's shell, for example `if dirok docs/working/cycles; then` (`scripts/dev-cycle.sh:205`, u0c numbering). (Paraphrased: no quote available because this rests on a grep of all inrepo, dirok and skipped call sites, none of them inside `$(`.)

**Evidence:** `SCRATCH/logs/probe1.txt`, `scripts/dev-cycle.sh:205-457` (u0c)

---

## Claim 5: "Every script that calls scrub_reexec shares its DEV_CYCLE_SCRUBBED marker." and scrub_reexec "returns only in the child (or when the caller already set DEV_CYCLE_SCRUBBED)"

**Location:** `scripts/lib/dev-cycle-read.sh:14-15`, `:57-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers scrub_reexec's return and exit paths and the fixed variable name. It does not establish anything about how a second script would nest a dev-cycle.sh call, because no such script exists.
**Legibility target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:59-64 (u0a)
scrub_reexec() {
  [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]] || return 0
  local self="$1"; shift
  { DEV_CYCLE_SCRUBBED=1 bash "$self" "$@" 2>&1 1>&3 3>&- | scrub >&2; } 3>&1 | scrub
  exit "${PIPESTATUS[0]}"
}
```

The parent always reaches `exit`. The child, and any caller that already exported the marker, take `return 0`. The marker name is fixed, so it is shared across scripts. E-modes shows identical output and exit codes before and after the rewrite.

**Evidence:** `scripts/lib/dev-cycle-read.sh:49-64`, `SCRATCH/logs/modes-*.txt`

---

## Claim 6: "With no ROOT_REAL nothing is plain (fail closed); need_root makes the callers below stop instead, outside the command substitution where blocker runs"

**Location:** `scripts/lib/dev-cycle-read.sh:68-69`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rawfile and plaindir answering not-plain with ROOT_REAL unset (with and without `set -u`), and need_root running before the `$(blocker …)` substitution in inrepo, dirok and skipped. It does not cover the parenthetical that follows (Claim 7).
**Legibility target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:77 (u0a)
rawfile() { local r; [[ -n "${ROOT_REAL:-}" && -f "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }
```

The bats ROOT_REAL test's `set -u` half prints `closed` twice. Its mutant `a-rawfile-guard` aborts with `ROOT_REAL: unbound variable` (KILLED).

**Evidence:** `scripts/lib/dev-cycle-read.sh:68-80`, `SCRATCH/mut/a-rawfile-guard.out`

---

## Claim 7: "(set -u fires there, but its error, like an exit, ends only the subshell)"

**Location:** `scripts/lib/dev-cycle-read.sh:69-70` (u0a; same text at u0b `:75-77` and u0c `:76-77`)
**Type:** Error-handling
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether set -u fires inside blocker's command substitution when ROOT_REAL is unset, in the code as it stands at this tip. It does not establish the pre-fix behaviour, where set -u did fire (E-probe2 (a), lib at 4ef450da: `line 63: ROOT_REAL: unbound variable`).
**Legibility target:** for-author

The comment is in the present tense, next to code where set -u can no longer fire on ROOT_REAL. Every ROOT_REAL read on blocker's path is guarded: `[[ -n "${ROOT_REAL:-}" && -f "$1" ]] && … [[ "$r" == "$ROOT_REAL/$1" ]]` (`:77`, `:80`). The unguarded `$ROOT_REAL` is reached only after the `-n` test passes. In E-probe1 P3 (`set -euo pipefail`, ROOT_REAL unset), `out="$(blocker link.md file)"` gives `subst rc=0 out=[link.md]`, with no unbound-variable error. The suite asserts the same thing: the ROOT_REAL test's comment says "without the guards' ${ROOT_REAL:-} the comparison would abort, not close". Commit 497c8cb5 says it rewrote this comment to say "set -u fires in the subshell rather than not at all". That describes the pre-fix code that 32b9ae0e had already changed. The precise version: "(an exit there, or set -u's error in code without these guards, ends only the subshell)", or drop the set -u mention.

**Evidence:** `scripts/lib/dev-cycle-read.sh:68-80`, `test/scripts/dev-cycle.bats` ("set -u: without the guards'…"), `SCRATCH/logs/probe1.txt` (P3), `SCRATCH/logs/probe2.txt` (a)

---

## Claim 8: "A ROOT_REAL that is not the current directory stops them too: the checks read relative paths, so a stale root would compare one tree's files with another."

**Location:** `scripts/lib/dev-cycle-read.sh:70-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers need_root's second test, and the fact that rawfile and plaindir resolve their relative `$1` against the cwd while comparing with `$ROOT_REAL/$1`. It does not establish anything about callers that pass absolute paths (none do).
**Legibility target:** for-orchestrator-synthesis

`[[ "$ROOT_REAL" == "$(pwd -P)" ]] || { echo "dev-cycle-read.sh: ROOT_REAL is not the current directory; …" >&2; exit 1; }` (`:75`). The bats test's third part (`cd real; inrepo f.md`) exits 1 with that message. The `a-pwd-check` mutant is KILLED.

**Evidence:** `scripts/lib/dev-cycle-read.sh:73-76`, `SCRATCH/logs/mutations.txt`

---

## Claim 9: "A directory dev-cycle.sh's digest globs in must be plain too" / "the blocking part is what the digest's section 8 lists and what the inline note names"

**Location:** `scripts/lib/dev-cycle-read.sh:78`, `:85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claims that the digest's glob directories pass dirok and that section 8 prints SKIPPED. It does not establish anything about build-loop.sh's use.
**Legibility target:** for-orchestrator-synthesis

dev-cycle.sh globs only after `dirok` (`if dirok docs/working/cycles; then for f in docs/working/cycles/cycle-…`, `scripts/dev-cycle.sh:205-206` u0c). Section 8 prints `printf '%s\n' "${SKIPPED[@]}" | sort -u | sed 's/^/- /'` (`:464`), and `skipnote` names `$SKIP_AT` (`:118`).

**Evidence:** `scripts/dev-cycle.sh:117-118, 205-219, 459-465` (u0c)

---

## Claim 10: dev-cycle.sh "The reader, kept in a lib so the planned scripts/build-loop.sh can share it, from this script's own directory: the scrub and the file and path rules." and the Exit line "1 … no perl or lib/dev-cycle-read.sh"

**Location:** `scripts/dev-cycle.sh:76`, `:83-84` (u0a)
**Type:** Reference / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the source path and the missing-lib exit. It does not establish anything about the plain-digest exit codes, which E-modes covers separately.
**Legibility target:** for-orchestrator-synthesis

`[[ -f "$READ_LIB" ]] || { echo "dev-cycle.sh needs $READ_LIB" >&2; exit 1; }` (`:86`). T30 ("a copy of dev-cycle.sh without its lib exits 1 and names the lib") passes in E-bats. Outside a repo, the u0c copy prints `Not inside a git repository` and exits 1, the same as main.

**Evidence:** `scripts/dev-cycle.sh:75-89`, `SCRATCH/logs/bats-u0a.txt`

---

## Claim 11: commit 4ef450da: "…pathform, isbrief and writable, moved verbatim … (scrub_reexec, the one rewritten part)"

**Location:** commit 4ef450da message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a line diff of the block removed from dev-cycle.sh against the block added to the lib, at 4ef450da. It does not cover the later fix commits' deliberate edits (need_root, the guards, comment rewording), which those commits declare.
**Legibility target:** for-orchestrator-synthesis

E-moved for 4ef450da shows only the new header, the `if [[ -z "${DEV_CYCLE_SCRUBBED:-}" ]]` block becoming `scrub_reexec()` with `local self="$1"; shift`, and the `SCRIPT_DIR=` line. That line was moved earlier in dev-cycle.sh, not into the lib. Every other line is identical.

**Evidence:** `SCRATCH/rm-4ef450da.txt`, `SCRATCH/add-4ef450da.txt`, `SCRATCH/logs/moved-diff.txt`

---

## Claim 12: commit 4ef450da: "Behaviour is otherwise unchanged: the 53 dev-cycle tests pass and the digest of this repo is byte-identical to main's." / 497c8cb5: "all 56 tests at this tip pass (main's 53 among them); the digest of this repo is unchanged."

**Location:** commit 4ef450da and 497c8cb5 messages
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the u0a tip: 56 tests, main's 53 names all present, and digest and check-mode output byte-identical to main on this repo. It does not establish byte-identity at the intermediate commit 4ef450da itself (its 55-test count was confirmed from the file).
**Legibility target:** for-orchestrator-synthesis

E-bats: u0a 56/56 ok, with no main test name missing. E-modes: `cmp` is identical for the digest, the `--since/--sample` digest and all six check modes. `git show 4ef450da:test/scripts/dev-cycle.bats | grep -c @test` gives 55 (53 plus T29 and T30).

**Evidence:** `SCRATCH/logs/bats-u0a.txt`, `SCRATCH/logs/modes-u0a.txt`

---

## Claim 13: commit 4ef450da Notes: "U0 measured over the 400-line cap (moves count twice), so it splits into three stacked units, not the plan's two"

**Location:** commit 4ef450da message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the changed-line sizes of the three move commits and the plan's "U0a/U0b if it measures over 400". It does not establish how the cap is defined beyond plan step 1 and log row 62.
**Legibility target:** for-orchestrator-synthesis

`git diff --shortstat`: 4ef450da +160/−114, 0b53fe50 +191/−168, 41065ce6 +154/−152. Main to u0c in scripts/ and test/ is +579/−426 (about 1,005 lines), so two units would each exceed 400. Plan `:268`: "(~260 lines moved; U0a/U0b if it measures over 400)".

**Evidence:** `docs/working/plan-build-loop-handoff.md:268`, git shortstat output (this report)

---

## Claim 14: commit 32b9ae0e: "with no ROOT_REAL, blocker's unbound-variable error ended only its command substitution, so inrepo, dirok and skipped read a symlink as plain." (plus its other bullets)

**Location:** commit 32b9ae0e message
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix inrepo fail-open and the rest of the message (the Exit-line wording, scrub_reexec's comment, the T29 name, the `#!/bin/bash` shebang matching the sibling libs). It does not re-raise the skipped nuance already settled in override-log row 211 (2026-10-05). Before the fix, skipped exited 1 at top level under set -e and read a symlink as plain only in an if/|| context.
**Legibility target:** for-author

E-probe2 (a), lib at 4ef450da: `line 63: ROOT_REAL: unbound variable`, then `inrepo: plain (read)`. All nine `scripts/lib/*.sh` start with `#!/bin/bash`. The remaining bullets match the tip (Claims 5, 10). The nuance above is settled and is not re-raised.

**Evidence:** `SCRATCH/logs/probe2.txt` (a), `scripts/lib/*.sh:1`, `docs/reviews/override-log.md:211`

---

## Claim 15: commit 497c8cb5: "need_root checked only that ROOT_REAL was set. With the current directory elsewhere, the import walk cached an empty set (fewer refusals)." and "The ROOT_REAL test runs its rawfile/plaindir half under set -u, so it fails if their ${ROOT_REAL:-} guard is dropped, and adds a root that is not the current directory. Both mutations checked."

**Location:** commit 497c8cb5 message; `test/scripts/dev-cycle.bats` "the lib's file checks stop, not pass, when ROOT_REAL is unset or not the current directory"
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-fix walk behaviour with the cwd in a subdirectory, and the test's sensitivity to the guard and pwd mutations. It does not establish the walk behaviour when the cwd is outside any repo (not run). For the "set -u fires" wording that this commit introduced, see Claim 7.
**Legibility target:** for-orchestrator-synthesis

E-probe2 (e), lib at 41065ce6 (need_root checks only that ROOT_REAL is set, the walk has no guard of its own, and the cwd is `repo/docs`): `walk returned; IMPORTED=[ ] DONE=[1]`. Run from the root, the same lib gives `IMPORTED=[ docs/imp.md ]`. The u0c tip exits 1 from the subdirectory with "ROOT_REAL is not the current directory". E-mut: `a-rawfile-guard`, `a-plaindir-guard` and `a-pwd-check` are all KILLED by this test. The test name matches its three asserted parts: exit 1 for inrepo, dirok and skipped; fail-closed under set -u; and a wrong-cwd stop.

**Evidence:** `SCRATCH/logs/probe2.txt` (e), `SCRATCH/logs/mutations.txt`, `test/scripts/dev-cycle.bats` (third new test)

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`scripts/lib/dev-cycle-read.sh:69-70` at u0a, carried unchanged to u0b and u0c): "set -u fires there" is present tense, but the `${ROOT_REAL:-}` guards stop set -u from firing in blocker. Reword it to the conditional, or drop the clause.

### Stale
- None.

### Mostly Accurate
- **Claim 14** (commit 32b9ae0e): settled in override-log row 211 and not re-raised. Listed only for completeness.

### Unverifiable
- None.

## Goal-Alignment Note

The goal is to land U0a after a clean review-fix loop with dev-cycle.sh's behaviour unchanged. The behaviour claims all hold under execution: 56 tests, all of main's 53 among them, and byte-identical output for the digest and all six check modes on this repo. Every new guard is pinned by a test that fails when the guard is removed. The one Incorrect item is a single comment clause next to need_root. It describes the pre-fix code, has no behavioural consequence, and is a one-line fix that does not block landing.
