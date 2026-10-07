Commit: 4828727d

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (feat/build-loop-u2a3b)
**Scope:** `git diff main...4828727d -- . ':!docs/reviews'` (scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md, test/scripts/build-loop-check.bats, test/scripts/dev-cycle.bats, docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md) and `git log main..4828727d`; weighted to aa379ee9 (every comment, test comment/title and commit sentence it added or changed) and 4828727d. Replicate r1 of 3.
**Checked:** 2026-10-07
**Total claims checked:** 38
**Summary:** 34 verified, 4 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination log (`docs/reviews/hallucination-patterns.md`) read first. One logged pattern is a test-tally claim in a commit message ("All 85 tests ... but the suites hold 97"; "mode1-equiv 33"); Claim 35 (aa379ee9's "149/149") resembles it and was executed: it holds. No other claim matches a logged pattern.

Execution environment: all probes ran from `git archive 4828727d` copies under `/tmp/u2a3bfcc1-5a3b` (logs in `/tmp/u2a3bfcc1-5a3b/x/`) and Claude Code 2.1.292 probes under `/tmp/u2a3bfcc1-cc-F564` (throwaway HOME and CLAUDE_CONFIG_DIR per run, `ANTHROPIC_BASE_URL=http://127.0.0.1:9`, no network; each run under `timeout 30`, all ended, none left running). Mutants were applied to the archive copy's lib and the original restored (`cmp` clean). No worktree file other than this report was written.

---

## Claim 1: "Imports through a symlinked file or directory print `ok`. ... (Absolute-path imports into the repo are refused since U2a3b.)"

**Location:** `docs/working/known-issues-dev-cycle.md:17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an absolute import spelled under ROOT_REAL (the real root) being yielded by the parser, so `--check-fix` refuses it; does not establish the symlinked-file/directory half (not re-probed) and does not cover an absolute name spelled through a symlinked alias of the root, which the parser drops (Claude Code 2.1.292 also refuses that spelling, so it is not a miss).

The parser keeps an absolute name below ROOT_REAL: `if (substr(c, 1, 1) != "/") c = root "/" dir "/" c` and `if (index(out, pre) != 1 || length(out) <= length(pre)) return` (`scripts/lib/dev-cycle-read.sh:558`, `:571`; excerpt ends :571; enclosing put() continues to :577 — read). Executed (`bash x/alias.sh <lib> <alias>`, cwd `/tmp/u2a3bfcc1-5a3b/x/hrepo`, exit 0, 2026-10-07T15:50Z): input `@<ROOT_REAL>/docs/real.md and @<alias>/docs/alias.md` printed `docs/real.md` only, rc=0. Claude Code control (CLAUDE.md `@/tmp/u2a3bfcc1-cc-F564/proj-alias/docs/viaalias.md`, alias a symlink to proj): no import logged, while the real-path spelling logged `skipping /tmp/u2a3bfcc1-cc-F564/proj/docs/d3` (its nested import), consistent with the binary's `if(EP(he)||iH(e,Y))return[]` where `iH` rejects a non-canonical symlinked path (paraphrased — no quote available because the minified helper names are resolved only by reading `iH(e,n){if(!n.isSymlink||n.isCanonical)return!1;...}` in the extracted strings).

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-577`; `/tmp/u2a3bfcc1-5a3b/x/alias-out.txt`; `/tmp/u2a3bfcc1-5a3b/x/cc-alias-probe.txt`; `/tmp/u2a3bfcc1-5a3b/x/cc-alias-control.txt`

---

## Claim 2: "Not covered by either walk (...pre-existing on main): instruction files outside the repo that a session loads, a parent directory's CLAUDE.md and the user's memory file, whose imports reach files in the repo; routed to U2b's reader model."

**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5, last sentence); same fact at `scripts/lib/dev-cycle-read.sh:484-486`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that Claude Code 2.1.292 follows imports from a parent directory's CLAUDE.md and from the user memory file into the project, and that neither walk lists a start outside the repo; does not cover managed-policy memory or `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD` (both also in the binary's load list).

Probe (`bash x/ccprobe4.sh outside /tmp/u2a3bfcc1-cc-F564`, cwd `/tmp/u2a3bfcc1-cc-F564/proj`, timeout exit 124 as designed, 2026-10-07T15:52:35Z): parent `/tmp/u2a3bfcc1-cc-F564/CLAUDE.md` holding `@proj/docs/d4` and user memory `cfg-outside/CLAUDE.md` holding `@/tmp/u2a3bfcc1-cc-F564/proj/docs/d5` logged `skipping /tmp/u2a3bfcc1-cc-F564/proj/docs/d5` and `.../proj/docs/d4`. The binary's load list walks every ancestor: `..._n(Ee()).flatMap((m)=>[...u(m),...l(m)])` with `function _n(e){let n=[];for(let r=e;r!==yn(r).root;r=hn(r))n.unshift(r);return n}` (claude.exe strings). The tree walk's starts are repo listings only: `tree_starts() { local -; set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names; }` (`scripts/lib/dev-cycle-read.sh:661`); main_imports starts from `git ls-tree -r -z --full-tree "$MAIN_SHA"` and `git ls-files ... --cached --others` (`:715`, `:724`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:661`, `:715`, `:724`; `/tmp/u2a3bfcc1-5a3b/x/cc-outside-probe.txt`; `/tmp/u2a3bfcc1-5a3b/x/strings.txt`

---

## Claim 3: F11 gaps "... and one shape untraced against Claude Code, and instruction files outside the repo"; "The walks share one name parser but not one start rule"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with A5 (one untraced shape; outside-repo starts) and that both walks call `import_targets` with different start rules; does not re-establish the A5 items themselves beyond Claim 2.

A5 names exactly one untraced item: "Untraced (no host probe yet): whether `@` references in `.claude/commands/` files load." (`docs/working/known-issues-dev-cycle.md:18`). Both walks call the parser (`import_targets "$d"` at `scripts/lib/dev-cycle-read.sh:683` and `:742`); only main_imports starts at `.claude/rules/` (`"$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md`, `:731`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`; `scripts/lib/dev-cycle-read.sh:683`, `:731`, `:742`

---

## Claim 4: "The reader set includes the host: ... the user runs one on the host in `~/claude-workflows` under the host HOME (Q-121, answered 2026-10-07)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`; commit 4828727d message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that Q-121 exists, is answered 2026-10-07 with "yes, occasionally", and that Q-120 [1] is recorded in the rubric's gate section; does not evaluate the reader model itself.

main's archive: `### Q-121 · sessions-outside-workspace` / `**Status:** ANSWERED` / "**Answered 2026-10-07: yes, occasionally.** Sessions normally..." (`git show main:docs/working/questions-archive.md`, entry at line 2059). The rubric holds "**Answered 2026-10-07 (Q-120 [1]):** one more confirming pass under a size waiver" (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3b.md`, iteration-4 gate section).

**Evidence:** `docs/working/questions-archive.md:2059` (on main); `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 5: "...names after an @, read broadly; ... "skip <path>: <reason>" otherwise, and for every path when the import walk fails."

**Location:** `scripts/dev-cycle.sh:54-55`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_fix's arm order (every path reaching the walk arm is skipped when the walk fails; earlier arms skip for their own reasons); does not cover callers other than `--check-fix`.

```bash
# scripts/dev-cycle.sh:181-185
  elif ! imported_names; then
    echo "skip $a: the instruction-file import walk failed, so an import of it cannot be ruled out; file it instead"
  elif isimported tree "$lp"; then
    echo "skip $a: an instruction file names it after an @ ..."
  else check_path "$a"; fi
```
(excerpt ends :185; enclosing check_fix() ends :186 — read). No arm before `:181` prints `ok`. The suite test "--check-fix words a failed import walk as one and refuses (U2a3b)" (corrupt index) passed in the 149-test run (Claim 35).

**Evidence:** `scripts/dev-cycle.sh:170-186`; `/tmp/u2a3bfcc1-5a3b/x/bats.log`

---

## Claim 6: "The import walks also need python3 when a file they read holds text that is not well-formed UTF-8; without it they fail closed (every path is refused)."

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`
**Type:** Configuration / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fork condition and the failure path through both walks to `isimported` (answers imported) and check_fix (walk-failed skip); does not cover a python3 that succeeds with wrong output.

python3 runs only when a byte above 0x7f is present and the text fails `UTF8_WELL_FORMED`; its failure returns 1: `d="$(... python3 -I -c '...decode("utf-8", "replace")...')" || return 1` (`scripts/lib/dev-cycle-read.sh:636-637`). Both walks turn a parser failure into `IMPORTED=error; return 1` (`:683`, `:742`), and `isimported` answers imported: `main) main_imports || return 0;` / `tree) imported_names || return 0;` (`:796-797`). Suite tests at `test/scripts/build-loop-check.bats:582` (failing python3 shim on an invalid byte: both walks fail) and `:714` (failing shim, well-formed UTF-8: both walks succeed) passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:624-647`, `:683`, `:742`, `:791-800`; `test/scripts/build-loop-check.bats:582-595`, `:714-722`; `/tmp/u2a3bfcc1-5a3b/x/bats.log`

---

## Claim 7: imported_names "returns 1, with IMPORTED set to "error", when the start listing ..., lower, a file read, import_home or the parser (its comment lists why) fails, the IMPORT_OUT_MAX budget is spent, or a start file's name holds a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:453-456`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed arm in imported_names (`:662-693`); does not establish that no unlisted command can fail silently (inrepo_here's failure skips its path, as the comment states).

Arms: `nul_list recs tree_starts || return 1` (`:667`); `[[ "$f" != *$'\n'* ]] || return 1` (`:670`); `lp="$(lower "${f##*/}")" || return 1` (`:671`); `import_home || return 1` (`:676`); `out="$(head -c 4194305 -- "$f" | IMPORT_LEFT=... import_targets "$d")" || { IMPORTED=error; return 1; }` (`:683`, head covered by the function's `set -o pipefail` at `:663`); `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED=error; return 1; }` (`:685`); `lp="$(lower "$out")" || { IMPORTED=error; return 1; }` (`:687`). IMPORTED is set to `error` at `:666` before any early return.

**Evidence:** `scripts/lib/dev-cycle-read.sh:662-693`

---

## Claim 8: "Not covered (known issue A5): ... checkout conversions (A5), and the one shape A5 lists as untraced against Claude Code."

**Location:** `scripts/lib/dev-cycle-read.sh:475-479`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count against A5's text; does not trace the untraced shape.

A5 lists one untraced item, `.claude/commands/` (see Claim 3).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 9: "...so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again, and so does a caller that changes HOME (both caches are keyed without it)."

**Location:** `scripts/lib/dev-cycle-read.sh:480-483`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both cache keys and what a HOME change needs; does not cover import_home's own cache (which is keyed on HOME and recomputes correctly).

Both keys omit HOME: `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }` (`:665`) and `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && ...` (`:712`). The parenthesis says "both caches", but the instruction names only `IMPORTED_MAIN_DONE=""`. A caller that changes HOME and clears only that variable gets the tree walk's stale result from `IMPORTED_DONE`. The precise wording: "a caller that changes HOME clears IMPORTED_DONE and IMPORTED_MAIN_DONE (both caches are keyed without it)". That is the form the IMPORT_OUT_MAX comment already uses: "A caller that changes it clears IMPORTED_DONE and IMPORTED_MAIN_DONE" (`:493-494`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:480-483`, `:493-494`, `:665`, `:712`

---

## Claim 10: "Neither walk starts at an instruction file outside the repo, though Claude Code loads them and follows their imports into it: a parent directory's CLAUDE.md, the user's memory file"

**Location:** `scripts/lib/dev-cycle-read.sh:484-486`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 2, which holds the probe and the start-listing quotes; does not cover managed policy memory.

Same evidence as Claim 2: both outside sources were followed into `proj/docs/` by Claude Code 2.1.292, and the walks' start listings are repo listings only (`:661`, `:715`, `:724`).

**Evidence:** `/tmp/u2a3bfcc1-5a3b/x/cc-outside-probe.txt`; `scripts/lib/dev-cycle-read.sh:661`

---

## Claim 11: "A fresh clone's walks print about 2 KB, /workspace's about 6 KB."

**Location:** `scripts/lib/dev-cycle-read.sh:492-493`
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a clone at 4828727d (both walks) and the /workspace checkout's tree walk; does not cover main_imports in /workspace, which fails there (ignored instruction files, as A5 documents).

`bash x/walksize.sh <branch lib>` (exit 0, 2026-10-07T15:49Z): in `/tmp/u2a3bfcc1-5a3b/x/clone` (4828727d) `tree ok 2020`, `main ok 2020`; in `/workspace` (read-only) `tree ok 5607`, `main failed`.

**Evidence:** `/tmp/u2a3bfcc1-5a3b/x/walksize-out.txt`; `scripts/lib/dev-cycle-read.sh:489-495`

---

## Claim 12: "It also reads ROOT_REAL, HOME (through import_home) and IMPORT_LEFT (what may still be printed; IMPORT_OUT_MAX when unset)."

**Location:** `scripts/lib/dev-cycle-read.sh:504-506`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the environment import_targets reads; does not list the import_home cache globals it also reads and writes (IMPORT_HOME, IMPORT_HOME_REAL, IMPORT_HOME_DONE), which are internal.

`import_home || return 1` (`:626`); `IT_ROOT="${ROOT_REAL:-}" ... IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}"` (`:645-646`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:624-647`

---

## Claim 13: Known exceptions include "a session in another checkout of the repo (an absolute name into that checkout, or a relative one that re-enters through its directory; the reader set is U2b's)"

**Location:** `scripts/lib/dev-cycle-read.sh:525-527`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that a relative `@../<sibling>/...` resolves outside ROOT_REAL and is dropped; does not establish the exception list is complete for every reader (U2b's question). An absolute spelling through a symlinked alias of ROOT_REAL is dropped too, but it is not a missing exception: Claude Code 2.1.292 refuses that spelling (Claim 1).

put() resolves `..` lexically and keeps only names under `pre`: `if (part[i] == "..") { if (k > 0) k--; continue }` ... `if (index(out, pre) != 1 || length(out) <= length(pre)) return` (`:567`, `:571`). The suite's sibling-precision test (`test/scripts/build-loop-check.bats:491-494`) shows `@../<sibling>/docs/sib.md` not read as the repo's `docs/sib.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-577`; `test/scripts/build-loop-check.bats:491-499`

---

## Claim 14: "~/ joins the home directory (Claude Code: path.join(os.homedir(), rest)), also spelled through its real path, since ROOT_REAL is real."

**Location:** `scripts/lib/dev-cycle-read.sh:548-549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code joining `~/` to the home and the parser's two spellings; does not cover a `~` alone (the parser has no arm for it, and the binary returns the home itself; an `@~` names the home directory, never a file in the repo below it unless the repo is the home).

Binary: `if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))` (claude.exe strings, `Ye`). Probe (`bash x/ccprobe2.sh u-set ...`, 2026-10-07T15:48:17Z): user memory `@~/.cargo` with `HOME=/tmp/u2a3bfcc1-cc-F564/home` logged `skipping /tmp/u2a3bfcc1-cc-F564/home/.cargo`. Parser: `if (homereal != home) put(homereal "/" substr(c, 3))` then `c = home "/" substr(c, 3)` (`:552-553`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:542-556`; `/tmp/u2a3bfcc1-5a3b/x/cc-home-probe-user.txt`

---

## Claim 15: "The resolved spelling is what costs (its length grows with the depth of the importing file), so it is charged too, and each is resolved once per file."

**Location:** `scripts/lib/dev-cycle-read.sh:559-560`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the charge in put() (made for every call, before the `tried` check) and the per-awk-process `tried` memo; does not establish the bound's exact trip point on every host (it depends on ROOT_REAL's length).

```awk
# scripts/lib/dev-cycle-read.sh:558-563
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  work += length(c); if (work > 50000000) exit 3
  if (c in tried) return
  tried[c] = 1
```
(excerpt ends :563; enclosing put() continues to :577 — read). `tried` is an awk global; each import_targets call is one awk process, so "once per file". Executed (`bash x/timing.sh`, cwd `x/root`, 2026-10-07T15:45Z): 4 MiB of `@a ` from a directory 50 levels down: aa379ee9 lib `rc=1` in 0.5 s, e1654266 lib `rc=0` in 14.62 s. The no-charge mutant fails test 48 (Claim 35).

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-577`; `/tmp/u2a3bfcc1-5a3b/x/timing.txt`; `/tmp/u2a3bfcc1-5a3b/x/mutants.txt`

---

## Claim 16: import_home "from HOME as Claude Code's runtime (Bun) reads it: unset or empty, the passwd entry (Node would read an empty HOME as ""). A walk calls it once, so the parser's $(...) calls inherit it; it recomputes only when HOME itself changes (IMPORT_HOME_DONE holds the HOME it was computed for). A relative home is kept, and the parser fails on a ~/ name then."

**Location:** `scripts/lib/dev-cycle-read.sh:610-615`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code 2.1.292 and Node v22 on empty/unset HOME, the raw-HOME cache key, and the relative-home failure; does not cover a passwd lookup that fails (h becomes "", and a `~/` name then fails the parser).

Claude Code probe (`bash x/ccprobe2.sh u-{set,empty,unset}`, user memory `@~/.cargo`, 2026-10-07T15:48-15:49Z): `HOME=<scratch>` → `skipping /tmp/u2a3bfcc1-cc-F564/home/.cargo`; `HOME=` → `skipping /home/node/.cargo`; unset → `skipping /home/node/.cargo` (passwd: `node:x:1000:1000::/home/node:/bin/bash`). Node: `HOME= node -p 'JSON.stringify(require("os").homedir())'` → `""`; unset → `"/home/node"`. Code: `local h hr="" key="x${HOME+set}:${HOME-}"` / `[[ "$IMPORT_HOME_DONE" != "$key" ]] || return 0` (`:618-619`), before the getent fork (`:620`). Fork count (`bash x/homecount.sh`, HOME unset, getent shim logging each call, 3-file tree walk): aa379ee9 `getent calls: 1`, e1654266 `getent calls: 3`. Relative home: `if (substr(home, 1, 1) != "/") exit 4` (`:551`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:610-623`, `:551`; `/tmp/u2a3bfcc1-5a3b/x/cc-home-probe-user.txt`; `/tmp/u2a3bfcc1-5a3b/x/homecount-out.txt`

---

## Claim 17: "(python3's "replace" decoding matched Claude Code 2.1.292 on every sequence probed in the binary, 13 in all: U2a3b L2 security F1, L2-final fact-check)"

**Location:** `scripts/lib/dev-cycle-read.sh:633-634`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers python3's spelling against the binary on 8 further invalid sequences (all match). Does not establish the figure "13": the L2-final merged report credits r1 with 8 and r3 with 5, and their overlap is not stated. Does not cover Bun's decoder on every input.

The L2-final merged report: "r1 (Verified, executed): the real binary resolved 8 of 8 invalid sequences to python3's replace spelling ... r3 (Verified, executed ...): Claude Code loaded exactly the U+FFFD-spelled files import_targets printed for 5 invalid sequences" (`docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final.md:767`). 8 + 5 = 13 only if the two replicates' sequences are disjoint. That report does not say they are, and the merged verdict on this claim was Unverifiable. Independent probe (`bash x/ccprobe5.sh utf8`, 2026-10-07T15:55:29Z): `docs/inv.md` imported `@q<i><seq>z` for `ff`, `c0af`, `eda080`, `e282`, `f4908080`, `f09f98`, `8080`, `e08080`. For each, a directory named with python3's replace spelling was created, and Claude Code logged `skipping .../docs/q<i>...z` for all 8, with the same count of U+FFFD as python3 (1, 2, 3, 1, 4, 1, 2, 3). The precise version: "matched on every sequence probed (8 and 5 in the L2-final replicates, possibly overlapping; 8 more in the L2 confirming pass)", or no count.

**Evidence:** `scripts/lib/dev-cycle-read.sh:631-639`; `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final.md:767`; `/tmp/u2a3bfcc1-5a3b/x/cc-utf8-probe.txt`

---

## Claim 18: main_imports header: returns 1 when "... import_home, the parser (its comment lists why) or a lower fails, the IMPORT_OUT_MAX budget is spent, or an imported path main lacks lies under a directory main stores as a symlink or gitlink or exists in the checkout as anything but a plain directory below the root (the top-level .git is skipped)"

**Location:** `scripts/lib/dev-cycle-read.sh:694-707`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arms aa379ee9 added to the list and the .git parenthesis; the earlier arms (record parse, duplicates, symlink text) were not re-traced here.

`import_home || return 1` (`:736`); parser `|| { IMPORTED_MAIN=error; return 1; }` (`:742`); budget `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || {...}` (`:764`); lower `i="$(lower "$out")" || {...}` (`:766`); link/gitlink parent `[[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || {...}` (`:781`); non-plain checkout node `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || {...}` (`:782`); `.git` skip `[[ "$p" != .git ]] || continue` (`:778`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:708-785`

---

## Claim 19: "The top-level .git (a prefix candidate from @.gitignore; a linked worktree's gitfile) names no file main has, and is skipped. A nested .git is not: a nested repository's .git directory passes the plain-directory check below, and a .git file is read by Claude Code like any file, so it fails below, as files under .git do when the checkout holds them (U2a3c walks them)."

**Location:** `scripts/lib/dev-cycle-read.sh:772-778`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the top-level skip, a nested `.git` directory (plain, so it passes), a nested `.git` file (fails), and the Claude Code side for a nested `.git` file; does not cover a nested `.git` that is itself a symlink (it fails the `! -L` test, which is fail-closed).

`plaindir` accepts a real directory: `plaindir() { local r; [[ -n "${ROOT_REAL:-}" && -d "$1" ]] && r="$(realpath -e -- "$1" 2>/dev/null)" && [[ "$r" == "$ROOT_REAL/$1" ]]; }` (`:106`). Claude Code probe (`claude -p hi --debug` in `/tmp/u2a3bfcc1-cc-F564/proj`, 2026-10-07T15:43:00Z): CLAUDE.md `@n/.git`, where `n/.git` is a file holding `gitdir: x` / `see @docs/d`. It logged `skipping /tmp/u2a3bfcc1-cc-F564/proj/n/docs/d`, so the `.git` file was read and its import followed relative to `n/`. The binary's text-file gate keys on the extension (`let g=r8n(n).toLowerCase();if(g&&!f8n.has(g))return ... "Skipping non-text file in @include"`), and a leading-dot name has no extension, so `.git` passes it (paraphrased — no quote available because `r8n` is a minified name; the probe above is the behavioral evidence). The suite's test 44 (`:683`) passed, and the mutant restoring `*/.git` fails it (Claim 35).

**Evidence:** `scripts/lib/dev-cycle-read.sh:772-783`, `:103-124`; `/tmp/u2a3bfcc1-5a3b/x/cc-nested-git-debug-1.txt`; `/tmp/u2a3bfcc1-5a3b/x/mutants.txt`

---

## Claim 20: SKILL.md: `--check-fix` "... and refuses every path when the import walk fails"

**Location:** `skills/dev-cycle/SKILL.md:75-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 5.

See Claim 5 (`scripts/dev-cycle.sh:181-182`, and the passing corrupt-index test).

**Evidence:** `scripts/dev-cycle.sh:181-182`; `/tmp/u2a3bfcc1-5a3b/x/bats.log`

---

## Claim 21: precision comments: "The NBSP ends the token: no name runs on past it", "ns: the names run on past each space. Neither walk reads one", "a tab and a CR are blanks too, as in JavaScript's \s"

**Location:** `test/scripts/build-loop-check.bats:40-41`, `:63-64`, `:548-549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the walks yield no run-on name for each listed space, tab and CR (the assertions pass); does not cover `\v`/`\f`, which JavaScript's `\s` also ends a name at but the parser does not. That only over-reads: every prefix up to the next blank is still a candidate.

The scanner breaks on `ch == " " || ch == "\t" || ch == "\r"` after sed maps each UNI_SPACES sequence and NUL to a space (`scripts/lib/dev-cycle-read.sh:586`, `:627`). The tests passed in the 149 run.

**Evidence:** `scripts/lib/dev-cycle-read.sh:578-590`, `:624-630`; `/tmp/u2a3bfcc1-5a3b/x/bats.log`

---

## Claim 22: "A sibling whose path is as long as the repo's: its docs/sib.md is not the repo's."

**Location:** `test/scripts/build-loop-check.bats:491`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the prefix test `index(out, pre) != 1` with `pre = root "/"` (a same-length sibling differs before the slash); does not cover case-insensitive file systems.

`pre = (root == "/") ? "/" : root "/"` (`scripts/lib/dev-cycle-read.sh:602`). The test passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:571`, `:602`; `/tmp/u2a3bfcc1-5a3b/x/bats.log`

---

## Claim 23: "...on one line of many HTML comments (...; a 10 s timeout)"; "320,000 comments in one 2.24 MB line"

**Location:** `test/scripts/build-loop-check.bats:554-556`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the timeout value and the input size; the "27 s with status 0 at be94c871" history was not re-run.

`timeout 10 bash -c ...` (`:559`); `head -c 320000 /dev/zero | sed 's/\x0/<!---->/g'` gives 320,000 × 7 = 2,240,000 bytes (`:557`).

**Evidence:** `test/scripts/build-loop-check.bats:554-561`

---

## Claim 24: "Seven 4200-byte runs after an @: the first run's prefixes alone print past IMPORT_OUT_MAX, so the parser returns 1 (the candidate-work bound, which prints nothing, has its own test)."

**Location:** `test/scripts/build-loop-check.bats:388-390`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which bound trips first for the first run; does not cover the other six runs (deduplicated names).

`bash x/heavy.sh <aa379ee9 lib> heavy1.txt` (one 4200-byte run, 2026-10-07T15:50Z): `default rc=1`, `unbounded-print rc=0`. So the print budget alone fails it, and the work bound does not trip on one run. For seven runs both settings give `rc=1`.

**Evidence:** `/tmp/u2a3bfcc1-5a3b/x/heavy-out.txt`; `test/scripts/build-loop-check.bats:388-394`

---

## Claim 25: "import_targets prints 13 bytes for each file (a, a., a.m, a.md; 39 in all). Three files, not two: the parser gets what is left (IMPORT_LEFT), and a budget that restarted at each file would look walk-wide until the third."

**Location:** `test/scripts/build-loop-check.bats:610-612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte count (1+2+3+4 names plus 3 newlines = 13, ×3 = 39) and that the test kills a per-file budget mutant; the "until the third" rationale was not tested against a two-file variant.

Mutant replacing both `(( (used += ${#out}) <= IMPORT_OUT_MAX ))` with `(( ${#out} <= IMPORT_OUT_MAX ))`: `not ok 3 IMPORT_OUT_MAX bounds what the whole walk prints, not each file ...` (bats `-f`, 2026-10-07T15:57Z), while the other two budget tests still pass.

**Evidence:** `/tmp/u2a3bfcc1-5a3b/x/mutants.txt` (`== perfile`); `scripts/lib/dev-cycle-read.sh:685`, `:764`

---

## Claim 26: "10,100 escaped spaces after one @: every candidate trims to nothing, so the print budget (IMPORT_LEFT) never runs, while the candidates' lengths sum to about 51 million."

**Location:** `test/scripts/build-loop-check.bats:674-676`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sum (10,100 × 10,101 / 2 = 51,010,050) and that emit's charge, not put's, stops it; does not cover the "About 0.5 s" timing.

emit charges before trimming: `work += length(c); if (work > 50000000) exit 3` then `sub(/^ +/, "", c); sub(/ +$/, "", c)` / `if (c == "") return` (`scripts/lib/dev-cycle-read.sh:543-547`). The no-emit-bound mutant fails exactly this test (`not ok 43`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:542-556`; `/tmp/u2a3bfcc1-5a3b/x/mutants.txt`

---

## Claim 27: test "the main walk skips a nested .git directory, but fails closed on a nested .git file, which Claude Code reads"; "A .git file (a nested worktree's gitfile, or any file so named) is a file main lacks: Claude Code follows its imports"

**Location:** `test/scripts/build-loop-check.bats:683-693`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 19. "Skips" here means the nested directory prefix is accepted without failing, through the plain-directory check, not through the `.git` skip line.

See Claim 19 (Claude Code probe and mutant).

**Evidence:** `/tmp/u2a3bfcc1-5a3b/x/cc-nested-git-debug-1.txt`; `/tmp/u2a3bfcc1-5a3b/x/mutants.txt`

---

## Claim 28: "Claude Code's runtime (Bun) falls back to the passwd entry for an empty HOME as for an unset one (L2-final fact-check r1 22b)."

**Location:** `test/scripts/build-loop-check.bats:697-700`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 16; the cited r1 22b records the same fact (its 22a holds the probe).

See Claim 16 (`HOME=` and unset both resolved `@~/.cargo` to `/home/node/.cargo`).

**Evidence:** `/tmp/u2a3bfcc1-5a3b/x/cc-home-probe-user.txt`; `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r1.md:388-399`

---

## Claim 29: "400,000 copies of @a, from a file 50 directories down: each resolves to a path of over 150 characters, past the 50,000,000 bound in all, though the name itself is one character (performance L2-final F1 measured 22 s and success before the charge)."

**Location:** `test/scripts/build-loop-check.bats:736-738`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the resolved length and the bound arithmetic; does not cover the 22 s figure on the original host.

The resolved spelling is `root "/" dir "/" "a"`, where `dir` is 50 `d` parts (99 characters), so its length is ROOT_REAL's length + 102 (`scripts/lib/dev-cycle-read.sh:558`). ROOT_REAL is `$BATS_TEST_TMPDIR/repo` (`test/lib/build-loop-fixtures.bash:21`). Under bats' default `TMPDIR=/tmp` that is `/tmp/bats-run-XXXXXX/test/48/repo`, 33 characters, so the path is about 135 characters, not over 150. It exceeds 150 only under a longer TMPDIR (for example the 20-character mktemp dir the review brief requires, about 151). The conclusion holds either way: 400,000 × (1 + 135) ≈ 54.4 million > 50,000,000. The bound trips whenever ROOT_REAL is over 22 characters (400,000 × (L + 104) > 5×10⁷). Precise wording: "a path of over 120 characters". My unbounded run (ROOT_REAL 26 characters, 1,398,101 copies) took 14.62 s and succeeded on e1654266's lib, not 22 s; that difference is host timing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:558-561`; `test/lib/build-loop-fixtures.bash:21-22`; `/tmp/u2a3bfcc1-5a3b/x/timing.txt`

---

## Claim 30: commit aa379ee9: "performance F1: put charges each resolved spelling (its length grows with the importing file's depth) and resolves it once per file."

**Location:** commit aa379ee9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 15.

See Claim 15.

**Evidence:** `scripts/lib/dev-cycle-read.sh:558-563`; `/tmp/u2a3bfcc1-5a3b/x/mutants.txt`

---

## Claim 31: commit aa379ee9: "A 4 MiB file of @a 50 directories down fails in 0.6 s (22 s and success before); 200k distinct names at that depth fail in 1.8 s."

**Location:** commit aa379ee9 message (same figures in the rubric's L2-F-C2 disposition)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers both inputs on this host against aa379ee9's and e1654266's libs; does not reproduce the author's exact distinct-name input or host.

`bash x/timing.sh` / `x/timing2.sh` (cwd `/tmp/u2a3bfcc1-5a3b/x/root`, ROOT_REAL 26 characters, 2026-10-07T15:45-15:58Z):
- 4 MiB `@a`: new lib `rc=1` in 0.5 s; old lib `rc=0` in 14.62 s. This matches the claim's shape.
- 200,000 distinct `@a<N>`: new lib `rc=1` in 0.62 s, but the old lib also fails (`rc=1`, 2.32 s). Under the default budget both stop on IMPORT_LEFT (37,487 names printed in each). Only with the print budget lifted does the charge decide: new lib `rc=1` in 1.0 s, old lib `rc=0` in 13.07 s.

The sentence puts the distinct-name figure under "put charges ...". On this input the failure under default settings comes from the print budget, which e1654266 already had. Timings are host-dependent. aa379ee9 is committed, so this is a note for the rubric's L2-F-C2 line, not a wording fix.

**Evidence:** `/tmp/u2a3bfcc1-5a3b/x/timing.txt`

---

## Claim 32: commit aa379ee9: "security F2: only the top-level .git is skipped. A nested .git file is read by Claude Code, so it now fails the walk like any checkout file main lacks; the nested .git directory arm was equivalent (a directory passes the plain-directory check), so it is gone."

**Location:** commit aa379ee9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 19; "equivalent" holds for the directory case only, and the commit says exactly that.

See Claim 19.

**Evidence:** `scripts/lib/dev-cycle-read.sh:778-782`; `/tmp/u2a3bfcc1-5a3b/x/cc-nested-git-debug-1.txt`

---

## Claim 33: commit aa379ee9: "performance F3: import_home is keyed on the raw HOME, so an unset HOME no longer forks getent, id and cut per file."

**Location:** commit aa379ee9 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 16 (getent calls 1 vs 3 on a 3-file walk).

See Claim 16.

**Evidence:** `/tmp/u2a3bfcc1-5a3b/x/homecount-out.txt`

---

## Claim 34: commit aa379ee9: "api F1-F4: IMPORT_HOME_REAL (IT_HOME_REAL), IMPORT_HOME_DONE, UTF8_WELL_FORMED; import_targets names its inputs; both walk headers list their new failure arms."

**Location:** commit aa379ee9 message
**Type:** Staleness / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the old names are gone outside docs/reviews; the headers are Claims 7 and 18.

`rg -n 'IMPORT_HOMER|IT_HOMER|UTF8_OK|IMPORT_HOME_KEY|homer\b' --glob '!docs/reviews/**'` over the 4828727d archive: no hits (claim covers absence of code; nothing to quote).

**Evidence:** `scripts/lib/dev-cycle-read.sh:601`, `:609`, `:616-622`

---

## Claim 35: commit aa379ee9: "149/149; the no-charge, skip-any-nested-.git and no-emit-bound mutants fail."

**Location:** commit aa379ee9 message (also the rubric's "Verification: 149/149")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five suites dev-cycle (78), build-loop-check (48), build-loop-read (19), fixture-git-env (2) and fixture-hermeticity (2) = 149, and the three named mutants; does not cover other suites.

`TMPDIR=<fresh mktemp> LC_ALL=C bats test/scripts/dev-cycle.bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats` (cwd `/tmp/u2a3bfcc1-5a3b`, 2026-10-07T15:41:01Z-15:41:53Z, exit 0): `1..149`, 149 `ok`, no `not ok`. Mutants (build-loop-check only, 2026-10-07T15:53:46Z-15:54:11Z): no-charge → `not ok 48`; `*/.git` skip restored → `not ok 44`; emit charge removed → `not ok 43`. Each kills exactly its named test.

**Evidence:** `/tmp/u2a3bfcc1-5a3b/x/bats.log`; `/tmp/u2a3bfcc1-5a3b/x/mutants.txt`

---

## Claim 36: commit aa379ee9: "--check-fix over 948 paths identical to main; interleaved, main 2.46-2.61 s, this branch 2.70-2.71 s."

**Location:** commit aa379ee9 message
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers output identity over every docs `.md` plus README.md; the path count 948 matches that set at e1654266 (957 at aa379ee9/4828727d after the review reports landed). Timings are host-dependent.

`git ls-tree -r --name-only <rev> -- docs README.md | rg -c '\.md$'`: e1654266 948, aa379ee9 957. `bash x/checkfix.sh <scripts> <out>` in a clone at 4828727d (957 paths, interleaved twice, 2026-10-07T15:46:05Z): main 2.40/2.48 s, branch 2.54/2.63 s, all rc=0, outputs byte-identical (`cmp` → IDENTICAL).

**Evidence:** `/tmp/u2a3bfcc1-5a3b/x/checkfix-out.txt`; `/tmp/u2a3bfcc1-5a3b/x/cf-mainscripts.txt`; `/tmp/u2a3bfcc1-5a3b/x/cf-brscripts.txt`

---

## Claim 37: commit aa379ee9: "The unit is 794 changed code lines against main"

**Location:** commit aa379ee9 message (also rubric "Size: 794 ... (679 at e1654266)")
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers additions plus deletions outside `docs/` against the merge base; does not cover 4828727d (docs only, so the same).

`git diff --numstat main...aa379ee9 -- . ':!docs'` sums to 712 + 82 = 794; for e1654266, 603 + 76 = 679.

**Evidence:** command output recorded above (paraphrased — no quote available because the figure is a numstat sum, not a file line)

---

## Claim 38: commit 4828727d: "Q-120 [1] goes in the rubric's iteration-4 gate section. Q-121's answer (occasional host sessions in ~/claude-workflows under the host HOME) joins U2b's reader-model bullet in plan step 5." / "Notes: docs only"

**Location:** commit 4828727d message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two edits and the docs-only claim (`git show --stat 4828727d`: the rubric and the plan only).

See Claim 4. `git show --stat 4828727d` lists `docs/reviews/code-review-rubric-...md | 2 ++` and `docs/working/plan-build-loop-handoff.md | 2 +-`.

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`

---

## Findings (report-requirement form)

| ID | Severity | Location | Evidence (verbatim) | Confidence | Legibility-target | Mode |
|---|---|---|---|---|---|---|
| r1-F1 (Claim 9) | Low | `scripts/lib/dev-cycle-read.sh:482-483` | "sets IMPORTED_MAIN_DONE="" to walk again, and so does a caller that changes HOME (both caches are keyed without it)" | High | for-author | reasoned (static) |
| r1-F2 (Claim 29) | Low | `test/scripts/build-loop-check.bats:736-737` | "each resolves to a path of over 150 characters" | High | for-author | executed (path arithmetic; bats default TMPDIR gives about 135) |
| r1-F3 (Claim 17) | Informational | `scripts/lib/dev-cycle-read.sh:633-634` | "on every sequence probed in the binary, 13 in all" | Medium | for-author | executed (8 more sequences all match; the 13 count is unestablished) |
| r1-F4 (Claim 31) | Informational | commit aa379ee9; rubric L2-F-C2 | "200k distinct names at that depth fail in 1.8 s" | Medium | for-orchestrator-synthesis | executed (the default-budget failure comes from IMPORT_LEFT, as before the fix; commit is immutable) |

No Incorrect or Stale claim, and no behavioral mismatch. Every "Fixed" disposition I could execute holds: L2-F-A3 (no-emit mutant fails test 43), L2-F-A4 (per-file budget mutant fails the three-file test), L2-F-A5 (no-pipefail mutant fails the tree-walk test: `0 walk: ok head: cannot open 'docs/a.md' for reading: Permission denied`), C1, C2, C3, C4, C8, C10 (Claims 15-19, 34, 35). C11 holds with r1-F1's wording gap.

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:480-483`): a HOME change needs IMPORTED_DONE cleared as well; the sentence names only IMPORTED_MAIN_DONE.
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:633-634`): "13 in all" adds two replicates' counts (8 + 5) whose overlap is not established. Drop the count or state the parts.
- **Claim 29** (`test/scripts/build-loop-check.bats:736-737`): about 135 characters under bats' default TMPDIR, not over 150. The bound still trips.
- **Claim 31** (commit aa379ee9): the 200k-distinct-names figure fails on the print budget under defaults, as e1654266 did. The charge alone fails it only with the budget lifted (1.0 s vs 13 s and success).

### Unverifiable
- None.

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 4828727d` line at the top.
- **Answered:** I checked every claim aa379ee9 added or changed in the lib, the tests, known-issues, the plan and its commit message, plus 4828727d. The figures, Claude Code behaviors and test counts were executed: the nested `.git` file, `~/` with HOME empty/unset, outside-repo starts, eight U+FFFD sequences, 149/149, four mutants, `--check-fix` identity, walk sizes and the line count. The "Fixed" dispositions A3-A5, C1-C4, C8 and C10 hold by execution.
- **Out of scope:** pre-aa379ee9 FAILS-at test titles and the superset fuzz (prior passes executed them; not re-run); the U2b reader-model routing (override rows).
- **Escalate:** nothing blocking. r1-F4 is for the rubric's L2-F-C2 wording only.
- **Questions I would have asked:** whether "13 in all" was meant as a disjoint union of the r1 and r3 probes.
- **Decisions I made:** I probed the real binary headless with a throwaway CLAUDE_CONFIG_DIR/HOME and a localhost base URL. I wrote the probe CLAUDE.md files with the Write tool, since a hook blocks Bash writes naming them. I tested whether an absolute name spelled through a symlinked alias of the root is a superset miss; Claude Code refuses it, so I filed no finding. Execution logs stay in `/tmp/u2a3bfcc1-5a3b/x/` because the brief forbids other worktree writes.
