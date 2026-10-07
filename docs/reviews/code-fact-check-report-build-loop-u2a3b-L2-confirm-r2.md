Commit: 4828727d

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (feat/build-loop-u2a3b)
**Scope:** `main...4828727d -- . ':!docs/reviews'` (scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md) and `git log main..4828727d`. Claims added or changed in aa379ee9 and 4828727d were prioritized; earlier claims were checked where aa379ee9 touched or depends on them. Replicate r2 of 3.
**Checked:** 2026-10-07
**Total claims checked:** 31
**Summary:** 27 verified, 3 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution environment: archive copy of 4828727d at `/tmp/claude-1000/u2a3bfcc2-HXxN` (cwd for the suites); probes in fresh `mktemp -d /tmp/u2a3bfcc2-XXXX` dirs, scripts in the session scratchpad (`u2a3bfcc2-probe{1..11}.sh`), captured output in `/tmp/claude-1000/u2a3bfcc2-HXxN/*.log`. Claude Code 2.1.292 (`claude.exe`, a Bun executable) run headless with a scratch `CLAUDE_CONFIG_DIR` and HOME, no credentials (each run stops at "Not logged in" after memory loading; no network). Node v22 for the Node comparison. uid 1000 (not root, so mode-000 tests are meaningful). Hallucination log read: the logged "test count claimed in a commit does not match the suites" pattern was checked against aa379ee9's "149/149" (Claim 26) and does not recur.

---

## Claim 1: "The import walks also need python3 when a file they read holds text that is not well-formed UTF-8; without it they fail closed (every path is refused)."

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that python3 forks only for text the UTF-8 gate rejects, that its failure fails the walk, and that a failed walk refuses every path through `isimported`/`check_fix`; does not establish behavior when python3 exists but decodes differently from Claude Code (Claim 13).

The fork is gated: `if [[ "$toks" == *[$'\x80'-$'\xff']* ]] && ! printf '%s\n' "$toks" | env LC_ALL=C awk -v ok="$UTF8_WELL_FORMED" '$0 !~ ok { exit 1 }'; then d="$(... | python3 -I -c ...)" || return 1` (`scripts/lib/dev-cycle-read.sh:636-637`). A failed walk answers imported: `main) main_imports || return 0;` / `tree) imported_names || return 0;` (`:796-797`), and `check_fix` prints `skip $a: the instruction-file import walk failed` when `! imported_names` (`scripts/dev-cycle.sh:181-182`). Executed: the test "both walks read well-formed UTF-8 without python3" (`test/scripts/build-loop-check.bats:714`, a python3 shim that exits 1) passes, so well-formed text does not need python3.

**Evidence:** `scripts/lib/dev-cycle-read.sh:636-638`, `scripts/lib/dev-cycle-read.sh:791-800`, `scripts/dev-cycle.sh:181-182`; `/tmp/claude-1000/u2a3bfcc2-HXxN/bats.log` (command `TMPDIR=<mktemp> timeout 900 bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats`, cwd `/tmp/claude-1000/u2a3bfcc2-HXxN`, exit 0, 2026-10-07T15:40:37Z)

---

## Claim 2: imported_names returns 1 when "import_home or the parser (its comment lists why) fails, the IMPORT_OUT_MAX budget is spent"

**Location:** `scripts/lib/dev-cycle-read.sh:453-456`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three arms aa379ee9 added to the header (import_home, parser, budget) against `imported_names`' body; does not re-verify the older arms (start listing, lower, newline names).

Read `imported_names` signature to final line (`:662-693`). `import_home || return 1` (`:676`); the parser: `out="$(head -c 4194305 -- "$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) import_targets "$d")" || { IMPORTED=error; return 1; }` (`:683`); the budget: `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED=error; return 1; }` (`:685`). One nuance (paraphrased — no quote available because it concerns the absence of an assignment): the `import_home || return 1` at `:676` returns without resetting IMPORTED, which is already `error` from `:666`, so the stated "IMPORTED set to error" holds.

**Evidence:** `scripts/lib/dev-cycle-read.sh:662-693`

---

## Claim 3: "Neither walk starts at an instruction file outside the repo, though Claude Code loads them and follows their imports into it: a parent directory's CLAUDE.md, the user's memory file" (same claim in known issue A5 and plan F11/U2b)

**Location:** `scripts/lib/dev-cycle-read.sh:484-486`; `docs/working/known-issues-dev-cycle.md:18`; `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' start sets (repo listings only) and Claude Code 2.1.292 following imports from a parent directory's instruction file and from the user memory file (`$CLAUDE_CONFIG_DIR/CLAUDE.md`) into the project; does not cover managed-policy files or `--add-dir` directories.

Starts come only from repo listings: `nul_list recs tree_starts` with `tree_starts() { ... { git ls-files -z && untracked_md; } | instruction_names; }` (`:661`, `:667`) and `git ls-tree -r -z --full-tree "$MAIN_SHA"` / `git ls-files -z --cached --others` (`:715`, `:724`). Executed: a scratch parent dir held `See @proj/docs/fromparent`, the scratch config dir's memory file held `See @<abs>/proj/docs/fromuser`; run from `proj/`, the debug log shows `[CLAUDE.md] skipping /tmp/u2a3bfcc2-Mvjl/proj/docs/fromuser` and `... /proj/docs/fromparent` (both resolved and attempted; "skipping" because they are directories).

**Evidence:** `scripts/lib/dev-cycle-read.sh:659-667`, `scripts/lib/dev-cycle-read.sh:715-735`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe10.log` (command `bash u2a3bfcc2-probe10.sh`, cwd scratch, exit 0, 2026-10-07T15:46:39Z)

---

## Claim 4: "IMPORTED_MAIN_DONE ... so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again, and so does a caller that changes HOME (both caches are keyed without it)."

**Location:** `scripts/lib/dev-cycle-read.sh:480-483`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two walk cache keys; does not establish that any caller in scripts/ changes HOME (none was found).

`[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && ...` (`:665`) and `IMPORTED_MAIN_DONE="$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`:713`): neither key holds HOME, while `import_home` does recompute on a HOME change (`:618-619`), so only the walk caches go stale.

**Evidence:** `scripts/lib/dev-cycle-read.sh:665-666`, `scripts/lib/dev-cycle-read.sh:712-713`, `scripts/lib/dev-cycle-read.sh:617-623`

---

## Claim 5: "Not covered (known issue A5): ... checkout conversions (A5), and the one shape A5 lists as untraced against Claude Code." (and plan F11 "and one shape untraced against Claude Code")

**Location:** `scripts/lib/dev-cycle-read.sh:475-479`; `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count matching A5's "Untraced" list; does not trace the shape itself.

A5 lists exactly one: "Untraced (no host probe yet): whether `@` references in `.claude/commands/` files load." (`docs/working/known-issues-dev-cycle.md:18`). The lib and F11 now both say one.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:478`, `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 6: import_targets "also reads ROOT_REAL, HOME (through import_home) and IMPORT_LEFT (what may still be printed; IMPORT_OUT_MAX when unset)."

**Location:** `scripts/lib/dev-cycle-read.sh:504-506`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named inputs; does not claim the list is exhaustive (it also reads PATH's python3, UNI_SPACES, UTF8_WELL_FORMED and import_home's cache variables).

`IT_ROOT="${ROOT_REAL:-}" IT_HOME="$IMPORT_HOME" IT_HOME_REAL="$IMPORT_HOME_REAL" IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}"` (`:645-646`) after `import_home || return 1` (`:626`). `:-` also defaults an empty IMPORT_LEFT, not only an unset one; immaterial.

**Evidence:** `scripts/lib/dev-cycle-read.sh:624-647`

---

## Claim 7: Superset exception "a session in another checkout of the repo (an absolute name into that checkout, or a relative one that re-enters through its directory; the reader set is U2b's)"

**Location:** `scripts/lib/dev-cycle-read.sh:526-527`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that put keeps only names below ROOT_REAL, so a name resolving into another checkout's path is dropped; does not execute a two-worktree session against Claude Code.

`if (index(out, pre) != 1 || length(out) <= length(pre)) return` (`:571`) with `pre = (root == "/") ? "/" : root "/"` (`:602`): a relative `@../wtB/docs/x.md` resolves to `<parent>/wtB/docs/x.md`, outside `pre`, and is dropped, though a session whose project is wtB reads it as its own file.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-577`, `scripts/lib/dev-cycle-read.sh:600-603`

---

## Claim 8: "It returns 1 when sed, python3, awk or import_home fails, when ROOT_REAL is empty, when a ~/ name appears and the home is not absolute, or when the candidates and comment splices run past a work bound or print past IMPORT_LEFT"

**Location:** `scripts/lib/dev-cycle-read.sh:533-536`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed failure arm, and that the work bound now includes resolved spellings; does not establish the bound's value is safe for every legitimate file (only this repo's 957 docs, Claim 28).

`if (root == "") exit 2` (`:602`), `if (substr(home, 1, 1) != "/") exit 4` (`:551`), `work += length(c); if (work > 50000000) exit 3` in emit (`:543`), put (`:561`) and splice (`:594`), `if (printed - 1 > left) exit 3` (`:575`); each awk exit propagates through `awk "$IMPORT_AWK" || return 1` (`:646`). Executed: a 4 MiB file, 200k distinct names and the 10,100-escaped-space line all return 1 (probe1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:541-604`, `scripts/lib/dev-cycle-read.sh:645-646`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe1.log` (command `bash u2a3bfcc2-probe1.sh <lib>`, exit 0, 2026-10-07T15:42:34Z)

---

## Claim 9: "~/ joins the home directory ..., also spelled through its real path, since ROOT_REAL is real." (homereal rename)

**Location:** `scripts/lib/dev-cycle-read.sh:548-555`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the IT_HOMER→IT_HOME_REAL rename being complete (both ends) and the two spellings; does not cover a home that differs from the reading session's (a named exception).

`if (homereal != home) put(homereal "/" substr(c, 3))` (`:552`) reads `homereal = ENVIRON["IT_HOME_REAL"]` (`:601`), which import_targets sets as `IT_HOME_REAL="$IMPORT_HOME_REAL"` (`:645`); `rg -n 'IT_HOMER|IMPORT_HOMER|IMPORT_HOME_KEY|UTF8_OK|\bhomer\b' scripts test` in the archive copy exits 1 with no matches (paraphrased — no quote available because the claim covers absence of matches). The ~/ tests pass in the executed suite.

**Evidence:** `scripts/lib/dev-cycle-read.sh:550-553`, `scripts/lib/dev-cycle-read.sh:601`, `scripts/lib/dev-cycle-read.sh:645`; `/tmp/claude-1000/u2a3bfcc2-HXxN/bats.log`

---

## Claim 10: "The resolved spelling is what costs (its length grows with the depth of the importing file), so it is charged too, and each is resolved once per file."

**Location:** `scripts/lib/dev-cycle-read.sh:559-563`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers put's charge (before the dedup, so repeats still count) and the per-awk-process `tried` set (one awk per import_targets call, i.e. per file); does not establish dedup across different spellings that resolve alike (each spelling is resolved once).

```
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  work += length(c); if (work > 50000000) exit 3
  if (c in tried) return
  tried[c] = 1
```
(`:558-563`; excerpt ends :563; enclosing put() continues to :577 — read). Executed: the deep 4 MiB `@a` file fails in 0.46 s at 4828727d and succeeds after 13.77 s at e1654266 (probe1, probe8). Mutant "no-charge" (put's charge line removed) fails test 48 (probe5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-577`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe1.log`, `/tmp/claude-1000/u2a3bfcc2-HXxN/probe8.log` (exit 0, 2026-10-07T15:45:48Z), `/tmp/claude-1000/u2a3bfcc2-HXxN/probe5.log` (exit 0, 2026-10-07T15:44:13Z)

---

## Claim 11: import_home "from HOME as Claude Code's runtime (Bun) reads it: unset or empty, the passwd entry (Node would read an empty HOME as "")"

**Location:** `scripts/lib/dev-cycle-read.sh:610-612`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code 2.1.292's ~/ resolution with HOME set, empty and unset, Node 22's `os.homedir()` for the same, and import_home's matching rule; does not cover a passwd lookup that fails (import_home then keeps "" and the parser fails on a ~/ name).

`h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}" || h=""` (`:620`). Executed against the binary (memory file `See @~/.cargo and @~/.npm`): HOME set → `skipping /tmp/u2a3bfcc2-rpPU/fake/.cargo`; `HOME=` → `skipping /home/node/.cargo`; unset → `skipping /home/node/.cargo` (passwd home `/home/node`). Node: `set "/tmp/.../h"`, `empty ""`, `unset "/home/node"`. (`BUN_BE_BUN=1 claude -e` is not supported by this build, so Bun's `os.homedir` was observed only through Claude Code's resolver.)

**Evidence:** `scripts/lib/dev-cycle-read.sh:617-623`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe4.log` (command `bash u2a3bfcc2-probe4.sh`, exit 0, 2026-10-07T15:43:58Z), `/tmp/claude-1000/u2a3bfcc2-HXxN/probe3.log` (2026-10-07T15:43:20Z)

---

## Claim 12: "it recomputes only when HOME itself changes (IMPORT_HOME_DONE holds the HOME it was computed for)" / commit aa379ee9: "import_home is keyed on the raw HOME, so an unset HOME no longer forks getent, id and cut per file."

**Location:** `scripts/lib/dev-cycle-read.sh:613-615`; commit aa379ee9 message
**Type:** Performance / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key (set-ness and value, so empty and unset differ), the early return before any fork, and per-file calls inside `$(...)` inheriting the walk's precomputed key; does not establish behavior if a caller edits IMPORT_HOME_DONE.

`local h hr="" key="x${HOME+set}:${HOME-}"` / `[[ "$IMPORT_HOME_DONE" != "$key" ]] || return 0` (`:618-619`). Executed with a counting getent shim, HOME unset, a three-file chain: e1654266 called getent 5 times, 4828727d once; both walks answered `walk ok` / `c imported`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:616-623`, `scripts/lib/dev-cycle-read.sh:676`, `scripts/lib/dev-cycle-read.sh:736`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe11.log` (command `bash u2a3bfcc2-probe11.sh`, exit 0, 2026-10-07T15:47:12Z)

---

## Claim 13: "(python3's "replace" decoding matched Claude Code 2.1.292 on every sequence probed in the binary, 13 in all: U2a3b L2 security F1, L2-final fact-check)"

**Location:** `scripts/lib/dev-cycle-read.sh:633-634`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the cited L2-final replicate reports record binary probes summing to 13 (r1: 8, r3: 5); does not establish that the 13 are distinct sequences, nor Bun's decoder beyond them.

r1 scopes its claim to "the 8 sequences probed in the real binary" (`docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r1.md:425`); r3 says it ran "5 invalid-UTF-8 cases ... through the real binary" (`docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r3.md:277`). 8 + 5 = 13 only if no sequence was probed by both; neither report lists its sequences side by side, so "13" may double-count. Precise version: "on 8 + 5 probes in two replicates".

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r1.md:425`, `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r3.md:277`

---

## Claim 14: main_imports' header: returns 1 when "import_home, the parser (its comment lists why) or a lower fails, the IMPORT_OUT_MAX budget is spent, ... (the top-level .git is skipped)"

**Location:** `scripts/lib/dev-cycle-read.sh:703-707`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arms aa379ee9 added; does not re-verify the older tree-shape arms.

Read `main_imports` signature to final line (`:708-785`): `import_home || return 1` (`:736`), the parser arm `out="$(git cat-file blob ... | ... import_targets "$d")" || { IMPORTED_MAIN=error; return 1; }` (`:742`), the budget `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || ...` (`:764`), lower `i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }` (`:766`), and the skip `[[ "$p" != .git ]] || continue` (`:778`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:708-785`

---

## Claim 15: "The top-level .git (a prefix candidate from @.gitignore; a linked worktree's gitfile) names no file main has, and is skipped. A nested .git is not: a nested repository's .git directory passes the plain-directory check below, and a .git file is read by Claude Code like any file, so it fails below, as files under .git do when the checkout holds them"

**Location:** `scripts/lib/dev-cycle-read.sh:772-778`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact-match skip, a plain nested .git directory passing, a nested .git file failing, and Claude Code following imports from an imported nested `.git` file; does not cover a nested .git directory under a symlinked or gitlinked parent (that now fails, which is stricter).

`[[ "$p" != .git ]] || continue` (`:778`), then `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }` (`:782`). Executed: test 44 passes (nested dir ok; `n/.git` file → `walk failed`); against Claude Code, a project file `See @docs/ctl and @n/.git` with `n/.git` holding `see @../docs/viagit` logged `skipping /tmp/u2a3bfcc2-Wn5b/proj/docs/viagit`, so the binary reads a nested .git file and follows its import. Mutant "skip any nested .git" fails test 44.

**Evidence:** `scripts/lib/dev-cycle-read.sh:767-783`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe6.log` (command `bash u2a3bfcc2-probe6.sh`, exit 0, 2026-10-07T15:45:06Z), `/tmp/claude-1000/u2a3bfcc2-HXxN/probe5.log`

---

## Claim 16: `--check-fix` help and SKILL.md: refuses "a file an instruction file names after an @, read broadly; ... and for every path when the import walk fails"

**Location:** `scripts/dev-cycle.sh:51-55`; `skills/dev-cycle/SKILL.md:72-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_fix's branch order (a failed walk refuses every path that reaches it; earlier branches refuse the rest); does not cover --check-path or --check-write.

`elif ! imported_names; then echo "skip $a: the instruction-file import walk failed, ..."` precedes `elif isimported tree "$lp"` and `else check_path "$a"` (`scripts/dev-cycle.sh:181-185`), so no path prints `ok` when the walk fails.

**Evidence:** `scripts/dev-cycle.sh:170-186`

---

## Claim 17: Known issue A3: "Imports through a symlinked file or directory print `ok`. ... (Absolute-path imports into the repo are refused since U2a3b.)"

**Location:** `docs/working/known-issues-dev-cycle.md:17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new parenthetical (absolute names below ROOT_REAL are kept, so check_fix refuses them) and that the tree walk still does not queue a symlinked file; does not re-trace the symlinked-directory regression.

`if (substr(c, 1, 1) != "/") c = root "/" dir "/" c` keeps absolute names, and `index(out, pre)` keeps those under the root (`scripts/lib/dev-cycle-read.sh:558-572`); the test "both walks read an absolute import into the repo however it is spelled" (`test/scripts/build-loop-check.bats:503`) passes. The tree walk queues only `inrepo_here` paths, `inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }` (`scripts/lib/dev-cycle-read.sh:131`), so a symlinked file's own imports are not followed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:131`, `scripts/lib/dev-cycle-read.sh:688-691`, `test/scripts/build-loop-check.bats:503`; `/tmp/claude-1000/u2a3bfcc2-HXxN/bats.log`

---

## Claim 18: Plan F11: "The walks share one name parser but not one start rule (A2's `.claude/rules/`, the outside-repo starts, U2b's reader model)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two start predicates; does not judge where the shared predicate belongs.

The tree walk starts only on `[[ ! "$lp" =~ $INSTRUCTION_FILE ]] || ! inrepo_here "$f"` → continue (`scripts/lib/dev-cycle-read.sh:672`); main also starts on `"$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md` (`:731`). Both call `import_targets`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:668-675`, `scripts/lib/dev-cycle-read.sh:729-735`

---

## Claim 19: Plan U2b: "project a name under the longest matching root, since worktrees nest inside the main checkout" and "The main checkout's working tree is a parent of every worktree here"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers this repo's `git worktree list` as of the check; does not decide whether the stale entry matters for U2b.

`git worktree list` shows every live worktree under `/workspace/.claude/` (e.g. `/workspace/.claude/wt-build-loop-u2a`), but also `/home/magfrump/cw-egress-verify  b26d4b8b (detached HEAD) prunable`, a host-path worktree outside the main checkout. The same bullet (4828727d) adds the host checkout `~/claude-workflows` as a reader, whose worktrees (that entry's path suggests one) are siblings, not children. Precise version: "the container's live worktrees nest inside the main checkout; the host's need not".

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`; command `git -C /workspace/.claude/wt-build-loop-u2a3b worktree list` (exit 0, 2026-10-07T15:40Z, output transcribed here)

---

## Claim 20: Plan U2b (4828727d): "sessions normally run in cc-isolated, but when the image breaks the user runs one on the host in `~/claude-workflows` under the host HOME (Q-121, answered 2026-10-07)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation against main's questions archive; does not verify host usage.

Main's archive records "**Answered 2026-10-07: yes, occasionally.** Sessions normally run in cc-isolated ... but when the container image breaks the user runs one on the host directly in `~/claude-workflows` (the host HOME)" (`docs/working/questions-archive.md:2063` on main).

**Evidence:** `main:docs/working/questions-archive.md:2059-2063`

---

## Claim 21: "The NBSP ends the token: no name runs on past it" and "ns: the names run on past each space. Neither walk reads one"

**Location:** `test/scripts/build-loop-check.bats:40`, `test/scripts/build-loop-check.bats:63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 19 UTF-8 spaces in UNI_SPACES ending a name; does not cover ASCII \v and \f, which JavaScript's \s also holds but the parser does not end on (a run-on name over-reads, and its prefix is still a candidate, so the superset holds).

The sed step maps each to a blank: `for u in "${UNI_SPACES[@]}"; do s+=(-e "s/$u/ /g"); done` (`scripts/lib/dev-cycle-read.sh:627`); scan breaks on `ch == " " || ch == "\t" || ch == "\r"` (`:586`). Both tests pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:496-501`, `scripts/lib/dev-cycle-read.sh:578-590`; `/tmp/claude-1000/u2a3bfcc2-HXxN/bats.log`

---

## Claim 22: "Seven 4200-byte runs after an @: the first run's prefixes alone print past IMPORT_OUT_MAX, so the parser returns 1 (the candidate-work bound, which prints nothing, has its own test)."

**Location:** `test/scripts/build-loop-check.bats:388-390`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which bound stops this input; does not cover other inputs.

Executed: with the default IMPORT_LEFT the parser returns 1 after printing 2,826 lines, the longest 2,826 characters, so it stopped inside the first 4,200-byte run on the print budget (`if (printed - 1 > left) exit 3`, `scripts/lib/dev-cycle-read.sh:575`); with IMPORT_LEFT=999999999 it prints all 4,200 first-run names and then fails on the work bound. Test 43 is the print-free work-bound test.

**Evidence:** `test/scripts/build-loop-check.bats:388-394`, `scripts/lib/dev-cycle-read.sh:575`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe7.log` (command `bash u2a3bfcc2-probe7.sh <lib>`, exit 0, 2026-10-07T15:45:33Z)

---

## Claim 23: "A sibling whose path is as long as the repo's: its docs/sib.md is not the repo's." and "a tab and a CR are blanks too, as in JavaScript's \s"

**Location:** `test/scripts/build-loop-check.bats:491`, `test/scripts/build-loop-check.bats:549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the root-prefix test using `root "/"` (so `/p/repx` is not under `/p/repo`) and tab/CR ending a name; does not cover \v or \f (Claim 21).

`pre = (root == "/") ? "/" : root "/"` (`scripts/lib/dev-cycle-read.sh:602`) and `index(out, pre) != 1` (`:571`); `else if (ch == " " || ch == "\t" || ch == "\r") break` (`:586`). Both tests pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:571`, `scripts/lib/dev-cycle-read.sh:586`, `scripts/lib/dev-cycle-read.sh:602`; `/tmp/claude-1000/u2a3bfcc2-HXxN/bats.log`

---

## Claim 24: "import_targets prints 13 bytes for each file (a, a., a.m, a.md; 39 in all). Three files, not two: the parser gets what is left (IMPORT_LEFT), and a budget that restarted at each file would look walk-wide until the third."

**Location:** `test/scripts/build-loop-check.bats:610-612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic and a "budget counts only the latest file" mutant; does not cover other budget mutants (a per-file budget with no bash check is already caught by the 20 case).

1+2+3+4 characters plus 3 newlines = 13 per file, 39 for three. Executed: mutant `used = ${#out}` (both walks) passes e1654266's two-file test (`ok 1`) and fails the three-file test with `38 tree ok`.

**Evidence:** `test/scripts/build-loop-check.bats:609-617`, `scripts/lib/dev-cycle-read.sh:683-685`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe9.log` (command `bash u2a3bfcc2-probe9.sh`, exit 0, 2026-10-07T15:46:21Z)

---

## Claim 25: "10,100 escaped spaces after one @: every candidate trims to nothing, so the print budget (IMPORT_LEFT) never runs, while the candidates' lengths sum to about 51 million. About 0.5 s."

**Location:** `test/scripts/build-loop-check.bats:674-676`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic, emit's trim-to-empty return before put, and the run time on this host; does not cover slower hosts.

Sum 1..10100 = 51,010,050 (python3). `sub(/^ +/, "", c); sub(/ +$/, "", c)` / `if (c == "") return` (`scripts/lib/dev-cycle-read.sh:546-547`) after the emit charge (`:543`). The input returns 1 in 0.26 s. Mutant "no emit bound" fails this test (test 43).

**Evidence:** `scripts/lib/dev-cycle-read.sh:542-556`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe1.log`, `/tmp/claude-1000/u2a3bfcc2-HXxN/probe5.log`

---

## Claim 26: Test title "the main walk skips a nested .git directory, ..." and comment "A nested repository's .git directory names no file: a prefix of @n/.github/x.md is skipped."

**Location:** `test/scripts/build-loop-check.bats:683-684`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mechanism the title and comment name (a skip) against main_imports; does not dispute the test's assertions, which pass.
**Severity:** Low
**Legibility-target:** for-author

The code comment the same commit wrote says the opposite: "A nested .git is not [skipped]: a nested repository's .git directory passes the plain-directory check below" (`scripts/lib/dev-cycle-read.sh:773-775`), and the only skip is `[[ "$p" != .git ]] || continue` (`:778`). The prefix `n/.git` goes through `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]]` (`:782`) and stays in `IMPORTED_MAIN` (`IMPORTED_MAIN+="$i"$'\n'`, `:766`), so `isimported main n/.git` answers imported: it is admitted and recorded, not skipped. The removed mutant arm was the skip. Precise wording: "the main walk passes a nested .git directory (a plain directory), but fails closed on a nested .git file".

**Evidence:** `scripts/lib/dev-cycle-read.sh:764-783`, `test/scripts/build-loop-check.bats:683-695`

---

## Claim 27: "Claude Code's runtime (Bun) falls back to the passwd entry for an empty HOME as for an unset one (L2-final fact-check r1 22b)."

**Location:** `test/scripts/build-loop-check.bats:698-700`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code 2.1.292's behavior (Claim 11) and the test passing for both walks; the citation is slightly off (the Bun behavior is r1 Claim 22a; 22b is the Node attribution), which does not mislead about behavior.

Same execution as Claim 11; the test passes in the suite.

**Evidence:** `test/scripts/build-loop-check.bats:697-712`, `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r1.md:374-399`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe4.log`

---

## Claim 28: "the tree walk fails closed on an imported file it cannot read, when the caller did not set pipefail"

**Location:** `test/scripts/build-loop-check.bats:724`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers imported_names' own pipefail being what the test pins (as uid 1000, so mode 000 denies the read); does not cover a root runner, where the test would not exercise the failure.

`local - f d p lp out used=0 seen=$'\n' queue=() recs=(); set -o pipefail` (`scripts/lib/dev-cycle-read.sh:663`). Executed: with that `set -o pipefail` removed, the test fails with `0 walk: ok head: cannot open 'docs/a.md' for reading: Permission denied`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:663`, `scripts/lib/dev-cycle-read.sh:683`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe9.log`

---

## Claim 29: "400,000 copies of @a, from a file 50 directories down: each resolves to a path of over 150 characters, past the 50,000,000 bound in all ... (performance L2-final F1 measured 22 s and success before the charge)."

**Location:** `test/scripts/build-loop-check.bats:736-738`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the resolved length and the bound's margin under bats' default layout; does not cover the 22 s figure for this input (it was measured on the 4 MiB file, not this 1.2 MB one).

The resolved spelling is `root "/" dir "/" c` (`scripts/lib/dev-cycle-read.sh:558`) with a 99-character dir, so it is root length + 102. With the default `TMPDIR=/tmp`, bats' repo root is `/tmp/bats-run-XXXXXX/test/48/repo` (33 characters; `BATS_TEST_TMPDIR="$tests_tmpdir/$BATS_SUITE_TEST_NUMBER"`, bats-exec-test:69), so each path is 135 characters, not over 150; the test still fails as intended (400,000 × 136 ≈ 54 M). Executed: the same input returns 1 with a 33-character root and 0 (passes the bound) with 19- and 2-character roots: the test needs a root of about 23+ characters, which bats' layout always gives. Precise version: "about 135 characters or more".

**Evidence:** `test/scripts/build-loop-check.bats:735-743`, `scripts/lib/dev-cycle-read.sh:557-561`; `/tmp/claude-1000/u2a3bfcc2-HXxN/probe1.log`

---

## Claim 30: Commit aa379ee9: "A 4 MiB file of @a 50 directories down fails in 0.6 s (22 s and success before); 200k distinct names at that depth fail in 1.8 s." and "--check-fix over 948 paths identical to main; interleaved, main 2.46-2.61 s, this branch 2.70-2.71 s."

**Location:** commit aa379ee9 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the outcomes (fail vs success) and output identity; the timings are host-dependent and were reproduced only in direction, and the path count differs because docs/ has grown since.

Executed: 4 MiB file fails in 0.46 s (4828727d) vs succeeds in 13.77 s (e1654266); 200k distinct names fail in 0.61 s. `--check-fix` over 957 tracked `docs/*.md` and README.md in a clone at 4828727d: merge-base f6fdda68's scripts and 4828727d's give byte-identical output (2.55 s vs 2.57 s, one run each).

**Evidence:** `/tmp/claude-1000/u2a3bfcc2-HXxN/probe1.log`, `/tmp/claude-1000/u2a3bfcc2-HXxN/probe8.log`, `/tmp/claude-1000/u2a3bfcc2-HXxN/probe2.log` (command `bash u2a3bfcc2-probe2.sh`, exit 0, 2026-10-07T15:43:06Z)

---

## Claim 31: Commit aa379ee9: "149/149; the no-charge, skip-any-nested-.git and no-emit-bound mutants fail." and "The unit is 794 changed code lines against main"

**Location:** commit aa379ee9 message
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five suites the rubric names (build-loop-check 48, dev-cycle 78, build-loop-read 19, fixture-git-env 2, fixture-hermeticity 2), the three mutants, and the numstat count outside docs/; does not cover hermeticity-lint (53, also passing), which the count excludes.

Executed: 48+78 (bats.log, 126 ok), 19, 2, 2 → 149 pass, 0 fail. Mutants (probe5): no-charge fails test 48, nested-.git skip fails test 44, no-emit-bound fails test 43. `git diff --numstat <merge-base> aa379ee9 -- . ':!docs'` sums to 712 + 82 = 794 (679 at e1654266). Does not match the logged pattern "test count claimed in a commit does not match the suites".

**Evidence:** `/tmp/claude-1000/u2a3bfcc2-HXxN/bats.log`, `/tmp/claude-1000/u2a3bfcc2-HXxN/herm.log`, `/tmp/claude-1000/u2a3bfcc2-HXxN/probe5.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 26** (`test/scripts/build-loop-check.bats:683-684`): the title and comment say a nested .git directory is "skipped"; the code admits it as a plain directory and records it as imported (its own comment at `scripts/lib/dev-cycle-read.sh:773-775` says "not" skipped). Reword to "passes".

### Mostly Accurate
- **Claim 13** (`scripts/lib/dev-cycle-read.sh:633-634`): "13 in all" sums two replicates' probes (8 + 5) that may overlap.
- **Claim 19** (`docs/working/plan-build-loop-handoff.md:279`): "worktrees nest inside the main checkout" holds for the container's live worktrees; `git worktree list` also holds a host-path worktree, and the host checkout this same bullet adds need not nest.
- **Claim 29** (`test/scripts/build-loop-check.bats:736-738`): resolved paths are about 135 characters under the default TMPDIR, not "over 150"; the 22 s figure was for the 4 MiB file.

### Unverifiable
- None beyond the residues named in Scope fields (Bun's `os.homedir` observed only through Claude Code's resolver; Claim 11).

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 4828727d` line at the top.
- **Answered:** every aa379ee9 fix the rubric marks Fixed was checked (C1 nested .git: Claim 15; C2 depth charge: Claims 10, 30; C3 HOME key: Claim 12; C4 renames: Claim 9; C5 inputs: Claim 6; C6 failure lists: Claims 2, 14; C7 stale wording: Claims 5, 17, 22; C8 Bun: Claims 11, 27; C9 precision: Claims 21, 23; C10 python3: Claim 1; C11 caches: Claim 4; C12: Claim 1; A3-A5 tests: Claims 24, 25, 28); all hold in behavior, and the mutants named in the commit fail. No behavioral Incorrect; one Low wording Incorrect in a test title (Claim 26).
- **Out of scope:** code quality, whether the 50 M work bound is the right size, U2b's reader model.
- **Escalate:** nothing.
- **Decisions I made:** counted r1's 22a/22b citation slip in Claim 27 as within Verified (the behavior it cites is right); treated the commit's timings as direction-only (host-dependent).
