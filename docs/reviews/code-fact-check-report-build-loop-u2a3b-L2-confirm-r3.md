Commit: 4828727d

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3b (feat/build-loop-u2a3b)
**Scope:** `git diff main...4828727d -- . ':!docs/reviews'` (scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md; scripts/dev-cycle.sh, skills/dev-cycle/SKILL.md and test/scripts/dev-cycle.bats were not changed by aa379ee9 and were not re-harvested), plus the commit messages in `git log main..4828727d`. This replicate looked hardest at aa379ee9 and 4828727d, the commits no earlier pass has seen. It also checked the rubric's "Fixed" dispositions L2-F-A3..A5 and L2-F-C1..C13 against the claims below.
**Checked:** 2026-10-07 (replicate r3 of 3)
**Total claims checked:** 37
**Summary:** 31 verified, 6 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination log: I read `docs/reviews/hallucination-patterns.md`. Its test-count pattern ("All 85 tests ... pass" when the suites held 97) is the closest to any claim here. I checked Claim 32 ("149/149") against it, and the count holds.

Execution provenance. Every run used a mktemp dir with the prefix `/tmp/u2a3bfcc3-`, `git archive 4828727d` copies, and `timeout`. The captured outputs are in the session scratchpad `/tmp/claude-1000/-workspace/d85c9919-8193-4546-8b61-a9f00fc88d03/scratchpad/`, abbreviated **SP/** below:
- **SP/u2a3bfcc3-cc-probe.txt**: Claude Code 2.1.292 run headless. Command: `claude -p hi --debug-file …`, with an isolated `CLAUDE_CONFIG_DIR`, HOME set, empty and unset, in `/tmp/u2a3bfcc3-01So/proj`. It exits 1 at "Not logged in" after memory loading, and no network is used. Script `/tmp/u2a3bfcc3-01So/probe.sh`, 2026-10-07T15:43:08Z–15:46:27Z.
- **SP/u2a3bfcc3-suites.txt**: `bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`, cwd `/tmp/u2a3bfcc3-pdBr/src`, TMPDIR a fresh mktemp dir, exit 0, 2026-10-07T15:43:42Z–15:44:33Z.
- **SP/u2a3bfcc3-mut.txt**: the three mutants named in aa379ee9 (script `SP/u2a3bfcc3-mut.sh`), cwd `/tmp/u2a3bfcc3-u0mk`, 2026-10-07T15:45:31Z.
- **SP/u2a3bfcc3-timing.txt**: the parser's depth charge at 4828727d and at e1654266 (script `SP/u2a3bfcc3-time.sh`), 2026-10-07T15:44:15Z.
- **SP/u2a3bfcc3-home.txt**: getent fork count and the cache key (script `SP/u2a3bfcc3-home.sh`), 2026-10-07T15:44:31Z.
- **SP/u2a3bfcc3-py.txt**: a failing python3 on a non-instruction file, and the tree cache across a HOME change (script `SP/u2a3bfcc3-py.sh`), 2026-10-07T15:47:36Z.
- **SP/u2a3bfcc3-cf.txt**: `--check-fix` over every tracked `docs/*.md` and README.md in a clone at 4828727d, main's scripts against 4828727d's (script `SP/u2a3bfcc3-cf.sh`), 2026-10-07T15:47:06Z.
- **SP/u2a3bfcc3-node.txt**: Node v22.23.2's `os.homedir` and python3's replacement decoding, 2026-10-07T15:49:21Z.
- Bundle reads: strings read from `/usr/local/share/npm-global/lib/node_modules/@anthropic-ai/claude-code/bin/claude.exe` (2.1.292) at byte offsets 205304669 (`Ye`, the resolver) and 212107515 (`ZMe`/`kOe`/`reo`/`EF`, the memory loader).

---

## Claim 1: "(Absolute-path imports into the repo are refused since U2a3b.)"

**Location:** `docs/working/known-issues-dev-cycle.md:17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both walks yield an absolute name that lands below ROOT_REAL (however it is spelled), and that `--check-fix` refuses a file that the tree walk lists. It does not establish A3's other half (symlinked files and directories still print ok, unchanged), and it does not cover absolute names into another checkout (U2b).

`put` keeps an absolute candidate and prints it repo-relative when it lies below the root: `if (substr(c, 1, 1) != "/") c = root "/" dir "/" c` … `if (index(out, pre) != 1 || length(out) <= length(pre)) return` / `out = substr(out, length(pre) + 1)` (`scripts/lib/dev-cycle-read.sh:558-572`; excerpt ends :572, and `put` continues to :577, read). The suite test "both walks read an absolute import into the repo however it is spelled: //root, /./root, root/../<name>" (`test/scripts/build-loop-check.bats:503`) and "--check-fix refuses files an instruction file imports" (`test/scripts/dev-cycle.bats:1016`) both pass at 4828727d.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-577`, `test/scripts/build-loop-check.bats:503`, SP/u2a3bfcc3-suites.txt

## Claim 2: "Not covered by either walk (… executed against Claude Code 2.1.292; pre-existing on main): instruction files outside the repo that a session loads, a parent directory's CLAUDE.md and the user's memory file, whose imports reach files in the repo"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that Claude Code 2.1.292 follows imports from a parent directory's CLAUDE.md and from the user memory file into project files, and that neither walk starts there. It does not cover managed-policy memory, or which memory file a loop under its own CLAUDE_CONFIG_DIR loads (both are named in U2b's bullet and were not probed).

Probe: `/tmp/u2a3bfcc3-01So/CLAUDE.md` (the parent) holds `parent @proj/dir3`, and `cfg/CLAUDE.md` (the user memory) holds `@/tmp/u2a3bfcc3-01So/proj/dir4`. The loader logged `[CLAUDE.md] skipping /tmp/u2a3bfcc3-01So/proj/dir4: not a regular file …` and `… skipping /tmp/u2a3bfcc3-01So/proj/dir3 …`, and it logs only for paths it resolved and tried to read. Neither walk starts outside the repo: `tree_starts() { … { git ls-files -z && untracked_md; } | instruction_names; }` (`scripts/lib/dev-cycle-read.sh:661`), and main's starts come from `git ls-tree -r -z --full-tree "$MAIN_SHA"` and `git ls-files` (`:715`, `:724`).

**Evidence:** SP/u2a3bfcc3-cc-probe.txt (tag `parent`), `scripts/lib/dev-cycle-read.sh:661`, `:715-735`

## Claim 3: "and one shape untraced against Claude Code, and instruction files outside the repo). The walks share one name parser but not one start rule (A2's `.claude/rules/`, …)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the agreement between "one shape" and A5's single untraced item, and the start-rule difference between the two walks. It does not establish whether `.claude/commands/` imports load (the untraced shape itself).

A5 lists exactly one untraced item: "Untraced (no host probe yet): whether `@` references in `.claude/commands/` files load." (`docs/working/known-issues-dev-cycle.md:18`). The lib says the same: "and the one shape A5 lists as / untraced against Claude Code" (`scripts/lib/dev-cycle-read.sh:478-479`). For the start rules, the tree walk admits only `[[ ! "$lp" =~ $INSTRUCTION_FILE ]] … continue` (`:672`), while main's walk also admits `"$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md` (`:731`). Both call `import_targets` (`:683`, `:742`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/lib/dev-cycle-read.sh:478-479`, `:672`, `:731`, `:683`, `:742`

## Claim 4: "(b) which directory its relative names resolve against (`@../wtB/docs/x.md` re-enters another checkout through its directory name)"; lib: "or a relative one that re-enters through its directory"

**Location:** `docs/working/plan-build-loop-handoff.md:279` (also `scripts/lib/dev-cycle-read.sh:526-527`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the parser drops a relative name that resolves into a sibling directory of the gate's root, so a session whose root is that sibling imports a file the gate never yields. It does not cover the absolute and `~/` halves of the exception (covered by their own tests), and it does not establish which checkouts exist on the host.

`put` resolves `root "/" dir "/" c` lexically and keeps it only when `index(out, pre) == 1` (`scripts/lib/dev-cycle-read.sh:558-571`). A sibling's path fails that prefix test. The test at `test/scripts/build-loop-check.bats:489-500` pins it with "A sibling whose path is as long as the repo's: its docs/sib.md is not the repo's" … `want docs/sib.md -`, and it passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-577`, `test/scripts/build-loop-check.bats:489-500`, SP/u2a3bfcc3-suites.txt

## Claim 5: "The main checkout's working tree is a parent of every worktree here, so its instruction files load as parent memory"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paths that `git worktree list` registers today. It does not establish that /workspace holds a CLAUDE.md (it holds AGENTS.md), and it does not establish what a host session loads.
**Severity:** Low · **Legibility-target:** for-author

Fifteen of the sixteen registered worktrees lie under `/workspace`. One does not: `/home/magfrump/cw-egress-verify  b26d4b8b (detached HEAD) prunable`. It is prunable here because the path is missing inside the container, so it is a host-side worktree, which is the Q-121 case this same bullet now names. "Every worktree here" holds only for the container's live worktrees. The precise wording is "every worktree inside the container (a host-registered one, such as /home/magfrump/cw-egress-verify, is the Q-121 case)". Also, `/workspace/CLAUDE.md` does not exist; `/workspace/AGENTS.md` does, which Claude Code also loads (`vbt=[["CLAUDE.md"],["CLAUDE.local.md"],["AGENTS.md"],…]` in the bundle).

**Evidence:** `git worktree list` (run 2026-10-07T15:46Z; output quoted above), `ls /workspace/AGENTS.md`

## Claim 6: "reader set includes the host: sessions normally run in cc-isolated, but when the image breaks the user runs one on the host in `~/claude-workflows` under the host HOME (Q-121, answered 2026-10-07)"

**Location:** `docs/working/plan-build-loop-handoff.md:279` (added in 4828727d)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the recorded Q-121 answer. It does not establish the host's actual configuration.

`/workspace/docs/working/questions-archive.md:2059-2061` records: "**Answered 2026-10-07: yes, occasionally.** Sessions normally run in cc-isolated (`/workspace` and its worktrees), but when the container image breaks the user runs one on the host directly in `~/claude-workflows` (the host HOME)."

**Evidence:** `/workspace/docs/working/questions-archive.md:2059-2075`

## Claim 7: "The import walks also need python3 when a file they read holds text that is not well-formed UTF-8; without it they fail closed (every path is refused)."

**Location:** `scripts/lib/dev-cycle-read.sh:12-13`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an imported, non-instruction file holding `\xff` with a failing python3: both walks fail, and `isimported` answers imported for an unrelated path. It also covers well-formed UTF-8 not needing python3 (Claim 26). It does not cover a python3 that succeeds with wrong output.

The gate is `if [[ "$toks" == *[$'\x80'-$'\xff']* ]] && ! printf '%s\n' "$toks" | env LC_ALL=C awk -v ok="$UTF8_WELL_FORMED" '$0 !~ ok { exit 1 }'; then d="$(… python3 -I -c …)" || return 1` (`:636-637`). The probe made `docs/a.md` (imported, not a start) hold `bad \xff @docs/b.md`, with a python3 shim that exits 1. The output was `tree failed`, `main failed`, `tree other: imported`, `main other: imported`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:631-639`, `:786-800`, SP/u2a3bfcc3-py.txt

## Claim 8: "It returns 1, with IMPORTED set to "error", when the start listing …, lower, a file read, import_home or the parser (its comment lists why) fails, the IMPORT_OUT_MAX budget is spent, or a start file's name holds a newline"

**Location:** `scripts/lib/dev-cycle-read.sh:453-456`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every `return 1` in `imported_names` (`:662-693`, read signature to end). It does not establish the callers' handling (covered by the existing `isimported` tests).

`IMPORTED_DONE="$ROOT_REAL"; IMPORTED=error` (`:666`) precedes `nul_list recs tree_starts || return 1` (`:667`), `[[ "$f" != *$'\n'* ]] || return 1` (`:670`), `lower … || return 1` (`:671`) and `import_home || return 1` (`:676`). After `IMPORTED=$'\n'` (`:677`), each failure re-sets it: `… import_targets "$d")" || { IMPORTED=error; return 1; }` (`:683`), `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED=error; return 1; }` (`:685`), and `lp="$(lower "$out")" || { IMPORTED=error; return 1; }` (`:687`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:662-693`

## Claim 9: "so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again, and so does a caller that changes HOME (both caches are keyed without it)."

**Location:** `scripts/lib/dev-cycle-read.sh:480-483`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both cache keys and what a HOME change needs. It does not establish that any current caller changes HOME (none was found).
**Severity:** Low · **Legibility-target:** for-author

The parenthesis is right: `[[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && …` (`:665`) and `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && …` (`:712`). Neither key holds HOME. The instruction names only `IMPORTED_MAIN_DONE`, though, and the tree cache needs `IMPORTED_DONE=""` too. The probe ran `imported_names` with HOME=h1, which gave `docs/h.md` imported via `@~/repo2/docs/h.md`. It then set HOME=h2 and printed `HOME=h2 (cached): imported`. Only after `IMPORTED_DONE=""` did it print `HOME=h2 (cleared): -`. The rubric's L2-F-C11 disposition ("comment says a caller that changes HOME clears both caches") therefore holds only through the parenthesis. The precise version is "a caller that changes HOME clears IMPORTED_DONE and IMPORTED_MAIN_DONE".

**Evidence:** `scripts/lib/dev-cycle-read.sh:665`, `:712`, SP/u2a3bfcc3-py.txt

## Claim 10: "Neither walk starts at an instruction file outside the repo, though Claude Code loads them and follows their imports into it: a parent directory's CLAUDE.md, the user's memory file"

**Location:** `scripts/lib/dev-cycle-read.sh:484-486`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same as Claim 2: parent CLAUDE.md and user memory imports reaching project files were probed. Managed policy was not probed.

The same probe as Claim 2 logged `… skipping /tmp/u2a3bfcc3-01So/proj/dir3` (from the parent) and `… proj/dir4` (from the user memory). The bundle's loader recurses into each include: `for(let Pe of Ce){if(!AD(Pe)&&!z)continue;let Ne=await EF(Pe,n,r,s,g+1,e,…)` (bundle offset ≈212107515, function `EF`).

**Evidence:** SP/u2a3bfcc3-cc-probe.txt, `scripts/lib/dev-cycle-read.sh:661`, `:715-735`

## Claim 11: "It also reads ROOT_REAL, HOME (through import_home) and IMPORT_LEFT (what may still be printed; IMPORT_OUT_MAX when unset)."

**Location:** `scripts/lib/dev-cycle-read.sh:504-507`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the environment that `import_targets` (`:624-647`, read whole) reads. It does not list the globals it writes through `import_home` (IMPORT_HOME, IMPORT_HOME_REAL, IMPORT_HOME_DONE). Inside a walk's `$(...)` those writes are lost, which is why the walks call `import_home` first.

`import_home || return 1` (`:626`), and `IT_ROOT="${ROOT_REAL:-}" IT_HOME="$IMPORT_HOME" IT_HOME_REAL="$IMPORT_HOME_REAL" IT_LEFT="${IMPORT_LEFT:-$IMPORT_OUT_MAX}" awk "$IMPORT_AWK"` (`:645-646`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:617-647`

## Claim 12: "Claude Code trims the name; it rejects a name led by a space first, so trimming one only over-reads."

**Location:** `scripts/lib/dev-cycle-read.sh:544-545`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of the filter and the trim in the 2.1.292 bundle. It does not cover names led by other whitespace, which cannot occur because the token regex excludes `\s` apart from an escaped space.

Bundle `reo`: `if(H=H.replaceAll("\\ "," "),H){if(!EP(H)&&(H.startsWith("./")||H.startsWith("~/")||H.startsWith("/")&&H!=="/"||!H.startsWith("@")&&!H.match(/^[#%^&*()]+/)&&H.match(/^[a-zA-Z0-9._-]/))){let Y=Ye(H,FT(n));` The filter runs before `Ye`, whose body begins `let n=e.trim();` (offset ≈205304669). A name led by a space fails every arm of the filter.

**Evidence:** claude.exe offsets 212107515 and 205304669

## Claim 13: "~/ joins the home directory (Claude Code: path.join(os.homedir(), rest))"

**Location:** `scripts/lib/dev-cycle-read.sh:548-549`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the resolver's `~/` arm. It does not cover `~` alone, which the parser never joins (a bare `~` is not a `~/` prefix and is read as a relative name).

`if(n.startsWith("~/"))return Hn(b(c(),n.slice(2)))`, with `import{homedir as c}from"os";import{dirname as f,extname as m,isAbsolute as P,join as b,…}from"path"`. In this chunk `Hn` is `function Hn(t){return t}` (offset 203416965).

**Evidence:** claude.exe offsets 205304669 and 203416965

## Claim 14: "The resolved spelling is what costs (its length grows with the depth of the importing file), so it is charged too, and each is resolved once per file."

**Location:** `scripts/lib/dev-cycle-read.sh:559-563`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the charge and the per-file `tried` memo (`tried` is global to one awk process, and there is one awk process per file). It does not establish the runtime bound of the bash side, which is bounded separately by IMPORT_OUT_MAX.

`work += length(c); if (work > 50000000) exit 3` / `if (c in tried) return` / `tried[c] = 1` (`:561-563`). The charge happens before the memo check, so a repeated spelling is still charged. A 4 MiB file of `@a ` with IT_DIR 50 levels deep took `new many rc=1 0.49s` and `old many rc=0 14.62s` (e1654266). Removing the charge makes "the parser charges each resolved spelling…" fail (`not ok 48`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-577`, SP/u2a3bfcc3-timing.txt, SP/u2a3bfcc3-mut.txt

## Claim 15: "from HOME as Claude Code's runtime (Bun) reads it: unset or empty, the passwd entry (Node would read an empty HOME as "")"

**Location:** `scripts/lib/dev-cycle-read.sh:610-612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Claude Code 2.1.292 with HOME set, empty and unset (passwd home /home/node), and Node 22.23.2 with HOME empty. It does not cover a passwd entry missing for the uid; in that case `h=""` and the parser fails on a `~/` name.

The user memory's `@~/.local` resolved to `/tmp/u2a3bfcc3-01So/fh/.local` with HOME set, and to `/home/node/.local` with HOME empty and with HOME unset. Node: `HOME='' -> ""`, `unset -> "/home/node"`. The code is `h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}" || h=""` (`:620`).

**Evidence:** SP/u2a3bfcc3-cc-probe.txt (tags set, empty, unset), SP/u2a3bfcc3-node.txt, `scripts/lib/dev-cycle-read.sh:617-623`

## Claim 16: "it recomputes only when HOME itself changes (IMPORT_HOME_DONE holds the HOME it was computed for)"; commit aa379ee9: "import_home is keyed on the raw HOME, so an unset HOME no longer forks getent, id and cut per file"

**Location:** `scripts/lib/dev-cycle-read.sh:613-615`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key's distinction between unset, empty and value, and the fork count for one tree walk. It does not cover main's walk separately, which uses the same `import_home` call shape (`:736`).

`local h hr="" key="x${HOME+set}:${HOME-}"` / `[[ "$IMPORT_HOME_DONE" != "$key" ]] || return 0` (`:618-619`). The key is checked before the getent fork on `:620`. Keys observed: `xset:/a`, `xset:/b`, `xset:` for empty and `x:` for unset. With HOME unset, a tree walk over four files called the getent shim once at 4828727d and five times at e1654266. IMPORT_HOME_DONE holds an encoding of HOME (its set flag plus its value) rather than HOME itself, which is a harmless imprecision.

**Evidence:** `scripts/lib/dev-cycle-read.sh:616-623`, SP/u2a3bfcc3-home.txt

## Claim 17: "(python3's "replace" decoding matched Claude Code 2.1.292 on every sequence probed in the binary, 13 in all: U2a3b L2 security F1, L2-final fact-check)"

**Location:** `scripts/lib/dev-cycle-read.sh:631-634`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the sources' counts, and two further sequences that I probed in the binary. It does not establish Bun's decoder on unprobed shapes.
**Severity:** Low · **Legibility-target:** for-author

"13" is 8 probes in L2-final r1 ("8 invalid sequences (lone `\xff`, truncated 4-byte, surrogate, overlong 3- and 2-byte, past U+10FFFF, truncated 3-byte, overlong 4-byte)", `docs/reviews/code-fact-check-report-build-loop-u2a3b-L2-final-r1.md:294`) plus 5 in r3 ("a truncated 3-byte sequence, an overlong 4-byte sequence, a surrogate, an overlong 2-byte sequence and one past U+10FFFF", `…-r3.md:503`). Every one of r3's five shapes is among r1's eight, so the evidence is 13 probes of at most 8 distinct shapes, not 13 distinct sequences. The cited "U2a3b L2 security F1" compared python3 with Node ("matched node byte for byte", `security-reviewer-review-2026-10-06-L2-build-loop-u2a3b.md:78`) and did not probe the binary. My probe agrees with the comment's conclusion: `@q/1\xff` and `@q/2\xc0\xaf` resolved to `q/1` plus one U+FFFD and `q/2` plus two, which match python3 (`'�'`, `'��'`). The precise version is "on every shape probed in the binary (8 shapes across 13 probes; L2-final fact-check)".

**Evidence:** SP/u2a3bfcc3-cc-probe.txt, SP/u2a3bfcc3-node.txt, the cited report lines

## Claim 18: main walk header: "… import_home, the parser (its comment lists why) or a lower fails, the IMPORT_OUT_MAX budget is spent, or an imported path main lacks lies under … (the top-level .git is skipped)"

**Location:** `scripts/lib/dev-cycle-read.sh:701-707`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arms that aa379ee9 added to the list against `main_imports` (`:708-785`, read whole). It does not re-verify the arms that earlier passes checked.

`import_home || return 1` (`:736`, after `IMPORTED_MAIN=error` at `:713`); `import_targets "$d")" || { IMPORTED_MAIN=error; return 1; }` (`:742`); `(( (used += ${#out}) <= IMPORT_OUT_MAX )) || { IMPORTED_MAIN=error; return 1; }` (`:764`); `i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }` (`:766`); `[[ "$p" != .git ]] || continue` (`:778`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:708-785`

## Claim 19: "The top-level .git … names no file main has, and is skipped. A nested .git is not: a nested repository's .git directory passes the plain-directory check below, and a .git file is read by Claude Code like any file, so it fails below"

**Location:** `scripts/lib/dev-cycle-read.sh:772-778`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the nested `.git` directory passing, the nested `.git` file failing, and Claude Code reading a `.git` file's imports. It does not cover a nested `.git` symlink (it fails, by `:782`, which is the safe direction).

Code: `[[ "$p" != .git ]] || continue`, then `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }` (`:778-782`). Claude Code's extension filter does not skip the name: `let g=r8n(n).toLowerCase();if(g&&!f8n.has(g))return t(\`Skipping non-text file in @include…\`)`, and `extname(".git")` is `""`. In the probe, `AGENTS.md`'s `@sub/.git` was read, and its `@dirx` resolved to `/tmp/u2a3bfcc3-01So/proj/sub/dirx`. The test at `test/scripts/build-loop-check.bats:683` passes, and restoring the `*/.git` arm fails it (`not ok 44`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:767-783`, claude.exe offset ≈212107515 (`ZMe`), SP/u2a3bfcc3-cc-probe.txt, SP/u2a3bfcc3-mut.txt

## Claim 20: "Seven 4200-byte runs after an @: the first run's prefixes alone print past IMPORT_OUT_MAX, so the parser returns 1 (the candidate-work bound, which prints nothing, has its own test)."

**Location:** `test/scripts/build-loop-check.bats:388-390`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which bound trips first under the default IMPORT_OUT_MAX. It does not cover a caller-supplied IMPORT_LEFT.

The first run prints `x`, `xx`, …, so the printed total passes 4,000,000 at a prefix length of about 2,828: the sum of (k+1) for k ≤ 2,828 is ≈4.0M. The work charged by then (emit about 4.0M, put about 4.0M plus 2,828 × (root+2)) is far under 50,000,000. `printed += length(out) + 1; if (printed - 1 > left) exit 3` (`scripts/lib/dev-cycle-read.sh:575`). The test passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:542-577`, SP/u2a3bfcc3-suites.txt

## Claim 21: "both walks fail once the parser has printed more than IMPORT_OUT_MAX characters in all"

**Location:** `test/scripts/build-loop-check.bats:406`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walks' `${#out}` accounting (characters in the caller's locale; bytes under the test's LC_ALL=C). It does not cover non-C locales, where awk's byte count can stop first, as the lib's comment at `:489-491` says.

`(( (used += ${#out}) <= IMPORT_OUT_MAX ))` (`scripts/lib/dev-cycle-read.sh:685`, `:764`). The test passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:685`, `:764`, SP/u2a3bfcc3-suites.txt

## Claim 22: "import_targets prints 13 bytes for each file (a, a., a.m, a.md; 39 in all). Three files, not two: the parser gets what is left (IMPORT_LEFT)…"

**Location:** `test/scripts/build-loop-check.bats:610-612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic and the 38/39 boundary. It does not cover main's walk visiting the files in another order (the order does not matter for the total).

1+2+3+4 plus 3 newlines is 13 per file, and 39 for three files. The test's expected `38 tree failed … 39 tree ok, 39 main ok` holds, and the suite passes.

**Evidence:** `test/scripts/build-loop-check.bats:609-618`, SP/u2a3bfcc3-suites.txt

## Claim 23: "10,100 escaped spaces after one @: every candidate trims to nothing, so the print budget (IMPORT_LEFT) never runs, while the candidates' lengths sum to about 51 million. About 0.5 s."

**Location:** `test/scripts/build-loop-check.bats:674-676`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic and the bound that stops the run. The timing is machine-dependent.

The sum of k for k = 1..10,100 is 51,010,050, which exceeds 50,000,000. `emit` charges before trimming (`work += length(c); if (work > 50000000) exit 3` / `sub(/^ +/, "", c); …; if (c == "") return`, `scripts/lib/dev-cycle-read.sh:543-547`), so nothing reaches `put`. Removing that line fails this test (`not ok 43`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:542-556`, SP/u2a3bfcc3-mut.txt

## Claim 24: "the main walk skips a nested .git directory, but fails closed on a nested .git file"; "A nested repository's .git directory names no file: a prefix of @n/.github/x.md is skipped."

**Location:** `test/scripts/build-loop-check.bats:683-684`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the observable outcome (walk ok with a nested `.git` directory, failed with a nested `.git` file) and the code's mechanism. It does not cover other nested `.git` node types.
**Severity:** Low · **Legibility-target:** for-author

The outcome is right, and the test passes. The mechanism word is not. Since aa379ee9 the code skips only the top-level `.git` (`[[ "$p" != .git ]] || continue`, `scripts/lib/dev-cycle-read.sh:778`). A nested `.git` directory is not skipped: it goes through the parent and plain-directory checks and passes them. The lib's own comment says so: "A nested .git / is not: a nested repository's .git directory passes the plain-directory check below" (`:773-775`). The precise wording is "the main walk passes a nested .git directory (a plain directory) but fails closed on a nested .git file".

**Evidence:** `scripts/lib/dev-cycle-read.sh:772-782`, `test/scripts/build-loop-check.bats:683-695`

## Claim 25: "Claude Code's runtime (Bun) falls back to the passwd entry for an empty HOME as for an unset one"

**Location:** `test/scripts/build-loop-check.bats:698-700`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same as Claim 15.

The binary resolved `@~/.local` to `/home/node/.local` with HOME empty and with HOME unset.

**Evidence:** SP/u2a3bfcc3-cc-probe.txt

## Claim 26: "both walks read well-formed UTF-8 without python3, which only text holding an invalid sequence needs"

**Location:** `test/scripts/build-loop-check.bats:714`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the UTF8_WELL_FORMED gate on the test's text (`é`, `à`). It does not re-verify the regex's agreement with python3 on 20,013 cases (an earlier claim).

The gate forks python3 only when awk rejects a line (`scripts/lib/dev-cycle-read.sh:636`). The test passes with python3 shimmed to `exit 1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:631-639`, SP/u2a3bfcc3-suites.txt

## Claim 27: "the tree walk fails closed on an imported file it cannot read, when the caller did not set pipefail"

**Location:** `test/scripts/build-loop-check.bats:724-725`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a non-root user. A root runner reads mode-000 files, so the test's premise would not hold there.

`imported_names` sets its own: `local - … ; set -o pipefail` (`scripts/lib/dev-cycle-read.sh:663`), so a failing `head -c 4194305 -- "$f"` fails the `$(...)` on `:683`. The test passes as uid 1000.

**Evidence:** `scripts/lib/dev-cycle-read.sh:663`, `:683`, SP/u2a3bfcc3-suites.txt

## Claim 28: "400,000 copies of @a, from a file 50 directories down: each resolves to a path of over 150 characters, past the 50,000,000 bound in all"

**Location:** `test/scripts/build-loop-check.bats:735-738`
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the resolved length under the default TMPDIR and whether the bound still trips. It does not cover very short TMPDIR values (the bound needs a root of at least about 23 characters).
**Severity:** Low · **Legibility-target:** for-author

The root is `$BATS_TEST_TMPDIR/repo`. With TMPDIR=/tmp, BATS_TEST_TMPDIR is `/tmp/bats-run-XXXXXX/test/48` (a measured sibling was `len=27 /tmp/bats-run-nfnLl8/test/1`), so the root is 33 characters. The resolved path is root + "/" + 99 characters of `d/…/d` + "/a", 135 characters, not "over 150". The conclusion holds: 400,000 × (135 + 1) = 54.4M, which exceeds 50M, and the test passes. Precise: "a path of over 130 characters (under the default TMPDIR)".

**Evidence:** `test/lib/build-loop-fixtures.bash:21-22`, `test/scripts/build-loop-check.bats:733-744`, `scripts/lib/dev-cycle-read.sh:557-563`

## Claim 29a: aa379ee9: "A 4 MiB file of @a 50 directories down fails in 0.6 s (22 s and success before)"

**Location:** commit aa379ee9 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers fail versus success and the order of magnitude. The absolute times depend on the machine.

`new many rc=1 0.49s`; `old many rc=0 14.62s` (e1654266's lib).

**Evidence:** SP/u2a3bfcc3-timing.txt

## Claim 29b: aa379ee9: "200k distinct names at that depth fail in 1.8 s"

**Location:** commit aa379ee9 message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 200,000 distinct in-repo names (`@n000000`…) at depth 50. I do not know the commit's own test names; if they resolved outside the repo, they would print nothing.
**Severity:** Low · **Legibility-target:** for-orchestrator-synthesis

They fail (`new distinct rc=1 0.64s`), but they failed before the charge too (`old distinct rc=1 2.57s`). Every prefix of an in-repo name prints a path of about 100 characters, so the IMPORT_OUT_MAX print budget stops the run whether or not the charge exists. Offered as evidence for the performance-F1 fix, this case does not show the charge. Claim 29a does.

**Evidence:** SP/u2a3bfcc3-timing.txt

## Claim 30: aa379ee9: "security F2: only the top-level .git is skipped. A nested .git file is read by Claude Code …; the nested .git directory arm was equivalent (a directory passes the plain-directory check), so it is gone."

**Location:** commit aa379ee9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the equivalence for a nested `.git` directory. It does not cover a nested `.git` that is a symlink or other non-plain node. The old arm skipped those and the new code fails them, which is not "equivalent" but is safe, and the message claims equivalence only for the directory arm.

See Claim 19. A nested `.git` directory under a parent that main stores as a gitlink already failed before the arm at `:778`: the earlier prefix `n/.g` trips the gitlink parent check `[[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }` (`:781`). So removing the arm changes nothing there either.

**Evidence:** `scripts/lib/dev-cycle-read.sh:767-783`, SP/u2a3bfcc3-cc-probe.txt, SP/u2a3bfcc3-mut.txt

## Claim 31: aa379ee9: "api F1-F4: IMPORT_HOME_REAL (IT_HOME_REAL), IMPORT_HOME_DONE, UTF8_WELL_FORMED"

**Location:** commit aa379ee9 message
**Type:** Staleness / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the old names across the worktree outside `docs/reviews`. It does not cover review reports, which keep the old names on purpose.

`rg 'IMPORT_HOMER|IT_HOMER|UTF8_OK|IMPORT_HOME_KEY|homer\b' --glob '!docs/reviews/**'` finds nothing, and the new names appear at `scripts/lib/dev-cycle-read.sh:601`, `:609-622`, `:636`, `:645`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:601-646`

## Claim 32: aa379ee9: "149/149"

**Location:** commit aa379ee9 message (also rubric "Verification: 149/149")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers build-loop-check (48), build-loop-read (19), dev-cycle (78), fixture-git-env (2) and fixture-hermeticity (2) at 4828727d, which is code-identical to aa379ee9. That set of five is my inference; the commit does not name the suites.

`1..149`, 149 `ok` lines, exit 0.

**Evidence:** SP/u2a3bfcc3-suites.txt

## Claim 33: aa379ee9: "the no-charge, skip-any-nested-.git and no-emit-bound mutants fail"

**Location:** commit aa379ee9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers my reconstruction of each mutant, each a single-line removal or restoration. It does not cover other mutants of the same lines.

`nocharge rc=1 … not ok 48`, `nestedgit rc=1 … not ok 44`, `noemit rc=1 … not ok 43`.

**Evidence:** SP/u2a3bfcc3-mut.txt, SP/u2a3bfcc3-mut.sh

## Claim 34: aa379ee9: "--check-fix over 948 paths identical to main; interleaved, main 2.46-2.61 s, this branch 2.70-2.71 s."

**Location:** commit aa379ee9 message
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-path verdicts (ok or skip) at 4828727d. The path count differs because aa379ee9 itself adds nine review reports (948 + 9 = 957). The times depend on the machine.

`paths: 957`, `main: … ok=14 time=2.45s`, `head: … ok=14 time=2.56s`, `verdicts identical`.

**Evidence:** SP/u2a3bfcc3-cf.txt

## Claim 35: aa379ee9: "The unit is 794 changed code lines against main" (rubric: "679 at e1654266")

**Location:** commit aa379ee9 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers added plus deleted lines outside `docs/`. It does not establish that Q-104's measure is exactly this one.

`git diff --numstat main...<c> -- . ':!docs'` summed gives 794 at aa379ee9 and 679 at e1654266. 4828727d touches only `docs/`.

**Evidence:** command output in this session (2026-10-07T15:46Z)

## Claim 36: 4828727d: "Q-120 [1] goes in the rubric's iteration-4 gate section. Q-121's answer … joins U2b's reader-model bullet in plan step 5. … docs only"

**Location:** commit 4828727d message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the commit's diff contains. Whether the plan sentence matches the answer is Claim 6.

The diff touches only `docs/reviews/code-review-rubric-…u2a3b.md` (+2: "**Answered 2026-10-07 (Q-120 [1]):** …") and `docs/working/plan-build-loop-handoff.md` (one insertion in the U2b bullet, "reader set includes the host: … (Q-121, answered 2026-10-07)…").

**Evidence:** `git diff aa379ee9 4828727d`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 5** (`docs/working/plan-build-loop-handoff.md:279`): "a parent of every worktree here" leaves out the host-registered worktree `/home/magfrump/cw-egress-verify` (prunable here, the Q-121 case). Scope it to the container's worktrees.
- **Claim 9** (`scripts/lib/dev-cycle-read.sh:480-483`): a caller that changes HOME must clear IMPORTED_DONE as well as IMPORTED_MAIN_DONE. The executed probe shows that the tree cache serves the old HOME's result. Rubric L2-F-C11's "Fixed" holds only through the parenthesis.
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:631-634`): "13 in all" is 13 probes of at most 8 distinct shapes (r3's five repeat r1's shapes), and "U2a3b L2 security F1" probed Node, not the binary.
- **Claim 24** (`test/scripts/build-loop-check.bats:683-684`): the test title says "skips a nested .git directory". The code no longer skips it: the directory passes the plain-directory check, as the lib's comment says.
- **Claim 28** (`test/scripts/build-loop-check.bats:735-738`): the resolved path is about 135 characters under the default TMPDIR, not "over 150". The bound still trips (54.4M).
- **Claim 29b** (commit aa379ee9): 200k distinct in-repo names also failed at e1654266 (the print budget), so this case does not demonstrate the charge.

### Unverifiable
(none)

---

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 4828727d` line at the top.
- **Answered:** every checkable claim that aa379ee9 and 4828727d added or changed in the lib comments, the known issues, the plan, the new and retitled tests, and both commit messages. Execution against the real Claude Code 2.1.292 binary covered empty and unset HOME (Bun), a nested `.git` file being read, parent and user-memory imports reaching the repo, and two more invalid-UTF-8 sequences. The rubric's "Fixed" dispositions hold for L2-F-A3, A4, A5, C1, C2, C3, C4, C5, C6, C7 (A3 wording), C8, C10 and C12. C11 holds only partially (Claim 9), and C13's wording overcounts (Claim 17). No change in aa379ee9 contradicts an override-log row.
- **Out of scope:** comments that are unchanged since e1654266 (the merged L2-final report verdicted them); code quality; whether the routed outside-repo gap should block the merge.
- **Escalate:** none. All six findings are Low wording issues, and none hides a fail-open. Claim 29b is the only one that touches the evidence offered for a fix, and Claim 29a supplies the right evidence.
- **Questions I would have asked:** which five suites make "149/149" (I inferred them from the counts); the exact names behind the commit's "200k distinct names".
- **Decisions I made:** I merged the lib's relative re-entry exception into the plan claim (Claim 4), and the commit's performance-F3 sentence into the lib claim (Claim 16). I wrote the execution logs to the session scratchpad rather than to `docs/reviews/execution-logs/`, because the brief forbids writing anything but this report.
