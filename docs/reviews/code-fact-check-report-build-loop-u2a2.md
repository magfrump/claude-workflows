Commit: 39ed1d53

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a2 (branch feat/build-loop-u2a2)
**Scope:** `git diff main...HEAD` (main 20347279, HEAD 39ed1d53): scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/scripts/build-loop-check.bats, test/scripts/fixture-git-env.bats, test/scripts/dev-cycle.bats; docs/working/plan-build-loop-handoff.md, docs/working/known-issues-dev-cycle.md, docs/working/questions.md (Q-119), docs/reviews/override-log.md (appended rows); the messages of commits d8003fbf and 39ed1d53
**Commit:** 39ed1d53
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-06
**Total claims checked:** 43
**Summary:** 31 verified, 6 mostly accurate, 2 stale, 4 incorrect, 0 unverifiable

Execution provenance. Every executed claim ran with cwd `/workspace/.claude/wt-build-loop-u2a2` (repo commands) or a fresh fixture repo `/tmp/u2a2-cfcr-XXXX` (probes), against a copy of HEAD's lib at `/tmp/u2a2-cfc-RrAi/head-lib.sh` (byte copy of `scripts/lib/dev-cycle-read.sh` at 39ed1d53), bash 5.2.15, git 2.39.5. Captured output lives in the scratch dir `/tmp/u2a2-cfc-RrAi/` (shared.md forbids writing into the repo beyond this report, so the skill's `docs/reviews/execution-logs/` was not used). Main commands:

- E1 (2026-10-06T18:35:28Z): `TMPDIR=$(mktemp -d /tmp/u2a2-cfct-XXXX) bats test/scripts/build-loop-check.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/scripts/build-loop-read.bats test/fixture-hermeticity.bats` → exit 0, 105 `ok`, 0 `not ok`; build-loop-check.bats alone 7 `ok`. Log: `/tmp/u2a2-cfc-RrAi/tests.log`.
- E2 (18:38:43Z): build-loop-check.bats in a `git archive HEAD` copy (`/tmp/u2a2-cfc-RrAi/m1`) with main's lib → exit 1, 7/7 fail; then with a tree-only `isimported` shim appended to main's lib, `bats -f 'tree walk'` → exit 1. Logs: `mainlib.log`, `mainlib-tree.log`.
- E3 (18:40:41Z, 18:40:47Z): `bash gap-probe.sh head-lib.sh PATH...` (main_imports then isimported main per path) in two fixture repos → exit 0 each. Logs: `gapA.log` (symlink text holding a NUL), `gapB.log` (untracked symlink at an import target).
- E4 (18:44:18Z, 18:44:41Z): `bash fail-probe.sh head-lib.sh KEY` with KEY ∈ {index, main:AGENTS.md (a symlink), main:docs/real.md, main^{tree}} made unreadable by `chmod 000` → exits 1, 0, 0, 1. Logs: `fail-probe.log`, `lstree3.log` (bash -x trace).
- E5 (18:39:47Z): `bash cache-probe.sh head-lib.sh` (cached failure, cache reset, subshell, wrong cwd under `if`) → exit 1 at the documented need_root stop. Logs: `cache.log`, `cache2.log`.
- E6: `psub-probe.sh` (errexit inside `< <(...)` versus `$(...)`), duplicate-entry probe, UNI_SPACES decode, `untracked_md` ignored-file probe, numstat counts, patch comparison. Recorded inline in each claim.

---

## Claim 1: "inrepo, dirok, skipped, check_brief, isimported and the import walks exit 1 (need_root) unless ROOT_REAL is set, is the current directory and is a repository's top level"

**Location:** `scripts/lib/dev-cycle-read.sh:14-16`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new members of the list (isimported, imported_names, main_imports) calling need_root before any read, and need_root's exit under `if`; does not re-establish the pre-existing members (inrepo, dirok, skipped, check_brief), which this branch does not change except inrepo's split.

`isimported() { local lp; need_root; ...` (`:583-585`), `imported_names() { ... need_root` (`:497-499`), and `main_imports() { ... need_root` (`:522-525`) each run need_root first; inrepo is now `inrepo() { need_root; inrepo_here "$1"; }` (`:123`). E5 ran `cd docs; if isimported main q; then ...` and the process stopped with `dev-cycle-read.sh: ROOT_REAL is not the current directory; the caller cds to the root it names` (`cache2.log`), so the exit holds under `if`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:93-97`, `:123-125`, `:497-499`, `:522-525`, `:583-585`; `/tmp/u2a2-cfc-RrAi/cache2.log`

---

## Claim 2: "main_imports ... reads the default branch's commit ... (it also reads the checkout's untracked start files and imported files main lacks, which can only add imports)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-34`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the walk reads (main's tree and blobs via `$MAIN_SHA`, plus checkout files queued as `t:`) and that the checkout reads only append to IMPORTED_MAIN; does not establish that a checkout read cannot end the process (an unreadable index does, Claim 13a), and "can only add" refers to imports, not to failures (an untracked name holding a newline fails the walk).

Main reads go through `git ls-tree -r -z --full-tree "$MAIN_SHA"` (`:529`) and `git cat-file blob "$MAIN_SHA:$f"` (`:558`, `:561`). Checkout reads are `untracked_md` (`:539`) and `out="$(import_targets "$d" < "$f")"` for `t:` items (`:555`); results only reach `IMPORTED_MAIN+="$(lower "$p")"$'\n'` (`:570`), never a removal. Test 1 (E1) confirms a working-tree edit of tracked CLAUDE.md is not read (`want docs/wt-only.md -`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:529`, `:539`, `:555-575`; `test/scripts/build-loop-check.bats:26-41`; `/tmp/u2a2-cfc-RrAi/tests.log`

---

## Claim 3: "$2 is the path asked about, or "" (or no $2) when the skip line already names it: notfile and badform make it the subject ...; error and any other word end "for $2" unless it is "", and notdir names only the directory above it."

**Location:** `scripts/lib/dev-cycle-read.sh:285-290`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every arm of entry_why for $2 set, "" and unset; does not establish caller usage.

`local w="${1//$'\n'/ }" p="${2-}"` (`:292`) makes a missing $2 "". The arms are `notfile) echo "${p:+$p is }not a regular file ..."`, `error) echo "the tree of the default branch could not be read${p:+ for $p}"`, `*) echo "the default branch answered $w${p:+ for $p}"` and `notdir\ *) echo "${w#notdir } is not a directory ..."` (`:294-299`). The dev-cycle.bats test now adds `entry_why error` and expects `the tree of the default branch could not be read`; it passes (E1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:285-301`; `test/scripts/dev-cycle.bats:1339-1356`; `/tmp/u2a2-cfc-RrAi/tests.log`

---

## Claim 4: "it starts at every instruction file stored there (and every .md under .claude/rules/, which Claude Code also loads), plus the checkout's untracked ones"

**Location:** `scripts/lib/dev-cycle-read.sh:453-455`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers start selection over main's tree and the untracked/ignored `.md` listing, any case; does not establish starts reached through a symlinked `.claude/rules` directory (not listed by `ls-tree -r`; known issue A5's symlinked-directory gap) or checkout-tracked files that main lacks and are not untracked.

Candidates are main paths ending `.[mM][dD]` (`:537`) and every untracked `.md` (`:542`); a candidate starts when `[[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md ]]` on the lower-cased path (`:545-549`). Tests 1 and 4 (E1) reach `docs/private.md` from untracked CLAUDE.local.md and `docs/r.md` from `.claude/rules/style.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:529-550`; `test/scripts/build-loop-check.bats:91-111`; `/tmp/u2a2-cfc-RrAi/tests.log`

---

## Claim 5: "follows an import into the file main stores at that path, whatever its name; a symlink there is followed to the path its text names. A target main does not have is read from the checkout when it is a plain file there."

**Location:** `scripts/lib/dev-cycle-read.sh:456-458`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the m:/t: dispatch, symlink following for text without NUL, and the plain-file condition for checkout reads; does not establish correct following when symlink text holds a NUL (Claim 7) or what happens to a non-plain checkout target's own imports (Claim 7).

`if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); else queue+=("t:$p"); fi` (`:574`); `120000)` reads the link text and resolves it against the link's directory (`:559-565`); `t` items run `inrepo_here "$f" || continue` (`:555`). Test 4 (E1) follows `CLAUDE.md -> real.md`, `docs/link.md -> target.md`, `.github/instr.md` and `docs/a+b.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:552-575`; `test/scripts/build-loop-check.bats:91-111`

---

## Claim 6: "a doubled name, a name holding a newline (in main's tree or the untracked list) and symlink text that is empty, absolute or holds a newline fail the walk, so isimported main answers imported for every path"

**Location:** `scripts/lib/dev-cycle-read.sh:459-462`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape returning 1 and isimported main then answering 0 for any path; does not establish that these are all the unmodelled shapes (Claim 7).

`[[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1` (`:535`), `[[ "$f" != *$'\n'* ]] || return 1` for untracked names (`:542`), `if [[ -z "$out" || "$out" == *$'\n'* || "$out" == /* ]]; then IMPORTED_MAIN=error; return 1; fi` (`:563`), and `main) main_imports || return 0` (`:588`). Tests 3 and 5 (E1) pass for each shape, including the `$'notes.md\n'` text.

**Evidence:** `scripts/lib/dev-cycle-read.sh:533-543`, `:561-563`, `:588`; `test/scripts/build-loop-check.bats:58-135`

---

## Claim 7: "It refuses what it does not model, as FENCE_AWK does ... Not covered (known issue A5): a path through a symlinked directory, other names that one file has on a case-insensitive checkout, absolute imports, and a symlinked untracked start file."

**Location:** `scripts/lib/dev-cycle-read.sh:458-464`
**Type:** Behavioral / Error-handling
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two shapes the walk neither models nor refuses and the A5 list omits; does not establish whether either is reachable through the self-merge floor without a human-reviewed commit on main (both need the shape already on main or in the orchestrator's checkout).

(a) Symlink text holding a NUL. The link text is read with `if ! out="$(git cat-file blob "$MAIN_SHA:$f"; printf x)"` (`:561`); `$(...)` drops NUL bytes (bash prints `warning: command substitution: ignored null byte in input`), and none of the `:563` tests looks for one. E3 built main with `AGENTS.md` as a 120000 entry whose text is `docs/rules.md\0zzz` (git fsck --strict reports nothing); `git checkout` makes `AGENTS.md -> docs/rules.md`, and docs/rules.md imports docs/deep.md. Output (`gapA.log`): `walk: ok`, `docs/rules.md: -`, `docs/deep.md: -`, `docs/rules.mdzzz: imported`. So the file Claude Code loads, and its import, pass. This is the same `$(...)` byte-loss family as U2a rubric R3 (trailing newlines), which the `printf x` fixes for newlines only.

(b) An untracked symlink at an import target main lacks. `t` items run `inrepo_here "$f" || continue` (`:555`), so the target is recorded (`IMPORTED_MAIN+=` at `:570` ran when it was read as a token) but the file it points to is never read. E3 (`gapB.log`): AGENTS.md on main imports `@docs/local.md`; the checkout has untracked `docs/local.md -> target.md`; output `docs/local.md: imported`, `docs/target.md: -`, `docs/deep.md: -`. The comment's "read from the checkout when it is a plain file there" states the condition, but the "Not covered" list names only "a symlinked untracked start file", not an untracked symlinked target.

What the code does: the walk refuses the listed shapes (Claim 6) and silently mis-follows or skips these two. The precise version should either refuse them (a NUL in link text; a non-plain `t:` target) or add them to the Not covered list, A5, F11 and Q-103.

**Evidence:** `scripts/lib/dev-cycle-read.sh:555`, `:559-565`, `:570`; `/tmp/u2a2-cfc-RrAi/gapA.log`, `/tmp/u2a2-cfc-RrAi/gapB.log`

---

## Claim 8: "Its result is cached for the commit and root in IMPORTED_MAIN_DONE."

**Location:** `scripts/lib/dev-cycle-read.sh:465-466`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key and that a cached failure stays a failure; does not cover checkout changes within one process (not in the key, by design).

`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` then `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"` (`:526-527`). E5 (`cache.log`): with the blob unreadable `1 fail [error]`; after restoring it, `2 fail (cached) [error]`; `3 zz imported`; after `IMPORTED_MAIN_DONE=""`, `4 ok after cache reset`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:526-528`; `/tmp/u2a2-cfc-RrAi/cache.log`

---

## Claim 9: "UTF-8 spaces that end an import token, as a blank does: U+00A0, U+1680, U+2000-200A, U+2028/2029, U+202F, U+205F and U+3000."

**Location:** `scripts/lib/dev-cycle-read.sh:468-472`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 18 byte strings in UNI_SPACES and their use in import_targets; does not establish that this is every separator Claude Code's parser uses (external).

Decoding each element of the sourced array (E6) prints `U+00A0 U+1680 U+2000 ... U+200A U+2028 U+2029 U+202F U+205F U+3000`, 18 entries, the comment's list. import_targets cuts at each with `for u in "${UNI_SPACES[@]}"; do t="${t%%"$u"*}"; done` (`:481`). Against main's walk a `@docs/nb.md\xc2\xa0for` token is not `docs/nb.md`; on HEAD it is (E6 probe).

**Evidence:** `scripts/lib/dev-cycle-read.sh:468-472`, `:477-488`

---

## Claim 10: "The import targets in the text on stdin, for a file in directory $1 ("" at the top level): one repo-relative path per line, case kept."

**Location:** `scripts/lib/dev-cycle-read.sh:475-476`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the output form; does not cover the realpath `|| continue`, which `-m -s` makes effectively unreachable.

`p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${1:+$1/}$t" 2>/dev/null)" || continue; [[ "$p" != .. && "$p" != ../* ]] || continue; printf '%s\n' "$p"` (`:484-486`), no lower-casing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:477-488`

---

## Claim 11: "Instruction-file names among NUL-separated paths on stdin ... It matches INSTRUCTION_FILE's names; the walk's own test stays the authority. LC_ALL=C makes -i ASCII-only."

**Location:** `scripts/lib/dev-cycle-read.sh:489-493`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the regex equivalence on basenames; does not cover main_imports, which does not use instruction_names.

`grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$'` (`:493`) against `INSTRUCTION_FILE='^(claude|agents?|gemini)(\.[abcdefghijklmnopqrstuvwxyz0123456789_-]+)?\.md$|^skill\.md$'` (`:440`): the same basename alternation, with `-i` doing on bytes what the walk's `lower` does.

**Evidence:** `scripts/lib/dev-cycle-read.sh:440`, `:489-493`, `:500-505`

---

## Claim 12: "The checkout's untracked and ignored .md files, NUL-separated: --others without --exclude-standard already lists ignored files."

**Location:** `scripts/lib/dev-cycle-read.sh:494-496`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 listing ignored and case-variant `.md` files; does not cover other git versions.

E6, a fixture with `.gitignore` holding `ign/`: `untracked_md` printed `AGENTS.local.md ign/a.md sub/B.MD top.md`; `git ls-files --others --exclude-standard` printed no `ign/a.md`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:496`

---

## Claim 13a: "The main walk; returns 1, with IMPORTED_MAIN set to "error", when the commit's tree cannot be listed whole ... The listings stay NUL-separated as git writes them, each with its exit status after the last NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:515-521`
**Type:** Error-handling
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ls-tree and untracked-listing failure paths under the caller's documented `set -euo pipefail`; does not establish behaviour for a caller without `-e` (there the status line is written and the return-1 path works).

The listings are read with `mapfile -d '' recs < <(git ls-tree -r -z --full-tree "$MAIN_SHA"; printf 'rc=%s' "$?")` and `[[ "${recs[-1]}" == rc=0 ]] || return 1` (`:529-530`, the same at `:539-540`). A process substitution inherits errexit (a command substitution does not), so when git fails the subshell exits before `printf` runs, `recs` is empty, and `${recs[-1]}` is `bad array subscript`, which ends the whole script with exit 1. E4 (`fail-probe.log`, `lstree3.log`): tree object unreadable → `head-lib.sh: line 530: recs: bad array subscript`, exit 1, no `walk:` line; index unreadable (untracked listing fails) → `line 540: recs: bad array subscript`, exit 1. psub-probe (E6) shows the same with `false` in place of git, also when the function is called under `if`. No test covers either path: test 2 makes a blob unreadable and removes main by name, never the tree or index.

What the code does: on these two failures the process exits 1 instead of returning 1 with IMPORTED_MAIN=error, so isimported main never answers and a caller that words a failed walk (U2a3's `elif ! main_imports; then FLOOR_WHY=...`, branch feat/build-loop-u2a2-full) never reaches its wording. The gate still stops, so the result is closed, but the stated mechanism and the "exit status after the last NUL" are refuted.

**Evidence:** `scripts/lib/dev-cycle-read.sh:515-541`; `/tmp/u2a2-cfc-RrAi/fail-probe.log`, `/tmp/u2a2-cfc-RrAi/lstree3.log`, `/tmp/u2a2-cfc-RrAi/psub.log`

---

## Claim 13b: "... the listing holds a name twice ..., a name holds a newline, a blob cannot be read, or symlink text it follows is absolute or holds a newline, so a caller refuses rather than reading a partial list."

**Location:** `scripts/lib/dev-cycle-read.sh:516-520`
**Type:** Error-handling
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named case returning 1 with IMPORTED_MAIN=error; does not establish the mechanism for an unreadable symlink blob (the `if !` guard does not fire, see below) or list completeness (Claim 13c).

Regular blob: `out="$(git cat-file blob ... | import_targets "$d")" || { IMPORTED_MAIN=error; return 1; }` (`:558`) fails through pipefail (`local -` plus `set -o pipefail`, `:523`). E4: `main:docs/real.md` unreadable → `walk: failed [error]`, `zz: imported`. Symlink blob: E4 `main:AGENTS.md` (a 120000 entry) unreadable → `walk: failed [error]`. It fails through `[[ -z "$out" ... ]]` (`:563`), not `if ! out="$(git cat-file ...; printf x)"` (`:561`): the substitution's status is printf's 0 (E6: `if ! out="$(false; printf x)"` printed `guard not fired, out=[x]`). The `:561` guard is dead, and an unreadable link is caught as empty text.

**Evidence:** `scripts/lib/dev-cycle-read.sh:523`, `:533-536`, `:558-563`; `/tmp/u2a2-cfc-RrAi/fail-probe.log`

---

## Claim 13c: completeness of main_imports' return-1 list

**Location:** `scripts/lib/dev-cycle-read.sh:515-520`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the return paths in the function body; does not re-verdict the listing paths (Claim 13a).

The function also returns 1 for `main_by_name || return 1` (`:528`), a record failing the ls-tree regex (`:533`), an untracked name holding a newline (`:542`) and empty link text (`:563`). The comment names none of these, though the block above IMPORTED (`:459-461`) names empty text. A precise list adds "no default branch found by name", "the untracked listing fails" and "empty" link text.

**Evidence:** `scripts/lib/dev-cycle-read.sh:522-566`

---

## Claim 13d: "(git would read the first copy, whatever its mode)"

**Location:** `scripts/lib/dev-cycle-read.sh:516-517`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's path lookup and checkout on a tree listing AGENTS.md twice; does not cover other git commands.

E6: a mktree with `120000 ... AGENTS.md` then `100644 ... AGENTS.md`: `git cat-file -p "${t}:AGENTS.md"` printed `x` (the first, a symlink's text); the reverse order printed `@docs/b.md` (again the first). But `git checkout` of those commits wrote the other copy: the first tree checked out as a regular file holding `@docs/b.md`, the second as a symlink `AGENTS.md -> x` (`git ls-files -s`: `120000`). So path lookups (cat-file, `rev-parse main:path`) read the first copy, while a checkout, which is what Claude Code loads, keeps the last. The refusal is right either way. The precise version: "git's path lookup reads the first copy, a checkout the last".

**Evidence:** `scripts/lib/dev-cycle-read.sh:516-517`; duplicate-entry probe in `/tmp/u2a2-cfcr-Iwax`

---

## Claim 14: "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; a caller that words a failed walk runs main_imports first. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:578-582`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every walk failure that returns 1 (blob unreadable, no main by name, the Claim 6 shapes), the unknown name, the cached second call and need_root under `if`; does not cover the listing failures, which end the process before isimported answers (Claim 13a).

`main) main_imports || return 0; ...` and `*) return 0 ;;` (`:588-590`). Test 6 (E1) prints `bogus: imported` and `failed walk: imported` under `if`. E5: the cached failure answers `3 zz imported`; in `$(...)` the cache does not reach the parent (`7 subshell: rc=1`, from the cached ok walk), and a wrong cwd under `if` stops the process.

**Evidence:** `scripts/lib/dev-cycle-read.sh:583-592`; `test/scripts/build-loop-check.bats:137-149`; `/tmp/u2a2-cfc-RrAi/cache.log`, `/tmp/u2a2-cfc-RrAi/cache2.log`

---

## Claim 15: check_fix's `elif isimported tree "$lp"` with the eager `imported_names` call removed keeps check_fix's behaviour (d8003fbf: "check_fix uses isimported tree")

**Location:** `scripts/dev-cycle.sh:170-185`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers refusal order and output for --check-fix given dev-cycle.sh's own setup (`cd "$ROOT"; ROOT_REAL="$(pwd -P)"`, `:119-121`); does not cover the intended token-rule change shared through import_targets (UTF-8 spaces, `..x` names, NUL text now refuse more paths), which changes outputs on purpose.

Old: `imported_names` ran for every argument before `if writable ...`, then `elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]`. New: `elif isimported tree "$lp"; then` (`:181`), which runs `need_root`, `imported_names` (cached per root) and the same membership test on `lower "$lp"` (idempotent on the already lower-cased `$lp`). Because the script always sets ROOT_REAL at the top level, need_root never fires earlier in the old order than in the new one, and the branches before `:181` read no walk state. dev-cycle.bats' --check-fix tests pass (E1).

**Evidence:** `scripts/dev-cycle.sh:119-121`, `:170-185`; `scripts/lib/dev-cycle-read.sh:583-592`; `/tmp/u2a2-cfc-RrAi/tests.log`

---

## Claim 16: build-loop-check.bats header and helper comments ("Contract tests for ... main_imports, isimported and, from U2a3 and U2b, the self-merge floor ..."; "Each test builds a throwaway repo under $BATS_TEST_TMPDIR ...; this repo is untouched"; imps: "main_imports' return; tree always reads ok"; want: "exactly "PATH: WORD"")

**Location:** `test/scripts/build-loop-check.bats:3-24`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the present-tense statements; the U2a3/U2b clause is a forward plan.

`bl_setup` makes `R="$BATS_TEST_TMPDIR/repo"` and cds there (`test/lib/build-loop-fixtures.bash:21-23`); imps prints `walk: ok` unconditionally unless `$w` is main (`if [[ "$w" != main ]] || main_imports`); want is `grep -qxF "$1: $2"`.

**Evidence:** `test/scripts/build-loop-check.bats:1-24`; `test/lib/build-loop-fixtures.bash:7-24`

---

## Claim 17: the seven test names match what each test asserts

**Location:** `test/scripts/build-loop-check.bats:26`, `:43`, `:58`, `:91`, `:113`, `:137`, `:151`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its assertions, and E1's passing run; does not establish which assertions would fail under a mutant other than main's lib (Claim 25b).

Each name's parts map to `want` lines. Test 1: untracked CLAUDE.local.md start, `docs/wt-only.md -`. Test 2: blob removed, then main deleted. Test 3: a doubled `a.md`, a doubled start, a doubled `z.txt`, two newline names. Test 4: symlinks, `.github/instr.md`, `docs/a+b.md`, untracked notes, `.claude/rules/`, NBSP. Test 5: `..x.md` followed, untracked newline name, three link texts. Test 6: `isimported bogus` and the failed walk under `if`, plus the NUL. Test 7: tree NBSP, `..x`, NUL.

**Evidence:** `test/scripts/build-loop-check.bats:26-160`; `/tmp/u2a2-cfc-RrAi/tests.log`

---

## Claim 18: "A start file listed twice (a symlink first, which git reads), and a plain file listed twice: each fails the walk rather than reading one copy."

**Location:** `test/scripts/build-loop-check.bats:67-68`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's path lookup reading the first (symlink) copy; does not cover checkout, which keeps the last copy (Claim 13d).

E6: `git cat-file -p "${t}:AGENTS.md"` on the test's tree shape printed the symlink's text `x`.

**Evidence:** `test/scripts/build-loop-check.bats:67-73`

---

## Claim 19: "A name holding a newline ...: a plain one, and one shaped so each half looks like an ls-tree record (a forged symlink line)."

**Location:** `test/scripts/build-loop-check.bats:78-79`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fixture's shape; does not establish that a newline-check-removed mutant fails this test (by reading: `we\nird/AGENTS.md` would start and import `docs/d.md`, so `want walk failed` would fail).

The second tree name is `x\n120000 blob %s\tdocs` (`:84`); under `-r` its record reads `100644 blob <q>\tx` + newline + `120000 blob <a>\tdocs/AGENTS.md`, two well-formed lines with the second a forged symlink record. `[ ... wc -c -eq 2 ]` pins two NUL records.

**Evidence:** `test/scripts/build-loop-check.bats:78-89`

---

## Claim 20: fixture-git-env.bats comments ("This suite's own fixture must stay out of an inherited GIT_DIR too"; "The inner runs name the victim's index too: it must come out byte for byte")

**Location:** `test/scripts/fixture-git-env.bats:11-19`, `:27`
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unset, the index copy and its `cmp -s` comparison, and the suite passing (E1); does not re-run the inherited-GIT_DIR victim experiment (the patch's review executed it at d07cc89c).

`unset $(git rev-parse --local-env-vars)` in setup, `cp "$V/.git/index" "$BATS_TEST_TMPDIR/index.before"`, and `cmp -s "$BATS_TEST_TMPDIR/index.before" "$V/.git/index"` in victim_unchanged.

**Evidence:** `test/scripts/fixture-git-env.bats:9-28`; `/tmp/u2a2-cfc-RrAi/tests.log`

---

## Claim 21: d8003fbf "rebuilt as U2a2 with the floor (commit 53a6912b, kept on feat/build-loop-u2a2-full). That was already 400 code lines before U2a1's carried rows"

**Location:** commit d8003fbf message, paragraph 1
**Type:** Reference
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the commit-to-branch reference and the line count; does not judge the split.

`git branch -a --contains 53a6912b` prints nothing. `feat/build-loop-u2a2-full` is `6c41aea2`, and its reflog has one entry, `branch: Created from HEAD` at 11:30:37, 81 s before d8003fbf. `git range-diff` pairs 53a6912b with 6c41aea2 (the same commit rebased onto main). The count holds for 53a6912b: pr-prep 1a's numstat against its base gives `400` (6c41aea2 against main: `398`). The precise version: "commit 6c41aea2 on feat/build-loop-u2a2-full (53a6912b rebased)". shared.md already cites 6c41aea2.

**Evidence:** commit d8003fbf; `git reflog show feat/build-loop-u2a2-full`; `git diff --numstat main...53a6912b -- ':(top)' ':(top,exclude)docs/'`

---

## Claim 22: d8003fbf "main_imports walks main's commit: NUL-safe listings (mapfile -d '', each command's exit status after its last NUL) into one map"

**Location:** commit d8003fbf message, bullet 1
**Type:** Error-handling
**Verdict:** Incorrect
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "exit status after its last NUL" part; the NUL-safe parsing itself holds (tests 3 and 5).

Same mechanism as Claim 13a: when git fails, no status is written under the caller's `set -e`, and the process exits 1 at `${recs[-1]}` (E4).

**Evidence:** `scripts/lib/dev-cycle-read.sh:529-541`; `/tmp/u2a2-cfc-RrAi/fail-probe.log`

---

## Claim 23: d8003fbf "It refuses what it does not model, as FENCE_AWK does: a doubled name, any name holding a newline (main or untracked), and symlink text that is empty, absolute or holds a newline (read with its trailing newlines kept) fail the walk (U2a iteration 3 R2-R4)"

**Location:** commit d8003fbf message, bullet 1
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed shapes (Verified, Claim 6) and the rubric citation; the general "refuses what it does not model" is refuted by Claim 7 and is verdicted there, not double-counted here.

The listed shapes fail the walk (E1). The citation: rubric R2 is the newline-joined `seen`, R3 the link text read through `$(...)`, and R4 "A stored name starting `..` (`..x.md`) is never followed" (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:62-64`). R4 is fixed by following such names (the next bullet), not by failing the walk. "Any name holding a newline (... untracked)" means untracked `.md` names, the only ones `untracked_md` lists. The precise version: "(R2, R3; R4 in the next bullet)".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:62-64`; `scripts/lib/dev-cycle-read.sh:496`, `:533-543`

---

## Claim 24: d8003fbf "isimported tree|main answers imported for a failed walk or an unknown walk name, so `if` fails closed (U2a A16). check_fix uses isimported tree."

**Location:** commit d8003fbf message, bullet 2
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 14 (walk failures that return); the listing failures end the process (Claim 13a), which is also closed.

See Claims 14 and 15; the rubric's A16 is "isimported's 'a caller that tests it with `if` refuses' is false" (`code-review-rubric-...-u2a.md:65`), which `main) main_imports || return 0` now fixes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:588-590`; `scripts/dev-cycle.sh:181`

---

## Claim 25a: d8003fbf "import_targets is shared by both walks: it ends a token at UTF-8 spaces, drops only .. and ../ (a ..x name is followed), and grep -a reads text holding a NUL; inrepo_here is inrepo after need_root; instruction_names and untracked_md name the two listings both walks use."

**Location:** commit d8003fbf message, bullet 3
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both walks' use of import_targets and the token rules; "both walks use" holds for untracked_md, but main_imports does not use instruction_names (it tests INSTRUCTION_FILE itself).

`done < <(import_targets "$d" < "$f")` (imported_names, `:511`); `| import_targets "$d"` and `import_targets "$d" < "$f"` (main_imports, `:555`, `:558`); `[[ "$p" != .. && "$p" != ../* ]]` (`:485`) replaces main's `[[ "$p" != ..* ]]`; `grep -aoE` (`:487`). instruction_names appears only in imported_names (`:505`), so "the two listings both walks use" is loose for instruction_names.

**Evidence:** `scripts/lib/dev-cycle-read.sh:477-512`, `:529-558`

---

## Claim 25b: d8003fbf "Tests: build-loop-check.bats 7 (...; the tree walk's shared token rules, which fail against main's lib). 326 changed code lines against main."

**Location:** commit d8003fbf message, Tests paragraph
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count, the failure against main's lib (each rule on its own too), and the line count at d8003fbf; the full branch is 347 lines after 39ed1d53.

E1: 7 `ok`. E2: with main's lib, test 7 fails. With an `isimported tree` shim on main's lib it still fails (`grep: CLAUDE.md: binary file matches`, every path `-`). Run separately without the NUL (E6), main's walk misses `docs/nb.md` (NBSP) and `..x.md` (`..*`), and HEAD imports both, so each rule fails on its own. pr-prep 1a's command `git diff --numstat main...d8003fbf -- ':(top)' ':(top,exclude)docs/'` sums to `326`.

**Evidence:** `/tmp/u2a2-cfc-RrAi/mainlib.log`, `/tmp/u2a2-cfc-RrAi/mainlib-tree.log`; `workflows/pr-prep.md:91`

---

## Claim 26: d8003fbf "known issue renumbered A4 -> A5: A4 is taken by the preamble's fixed --check-fix slowdown"

**Location:** commit d8003fbf message, Docs bullet
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ID collision; does not check every U2a artifact's references to "A4" (the U2a rubric's A18 recorded the collision).

`R1 (the _/* token cut) and A4 (the --check-fix slowdown) were fixed on fix/dev-cycle-import-re` (`docs/working/known-issues-dev-cycle.md:7-8`); the new row is `| A5 | 🟡 Medium | The gate's walk (main_imports, U2a2) ...` (`:18`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:7-9`, `:18`

---

## Claim 27: 39ed1d53 "applies g1-g2-fixture-git-env.patch ... as written"; "g3-entry-why-one-arg.patch (same Appendix) adds `entry_why error` with no $2"; Notes "patches applied unchanged"

**Location:** commit 39ed1d53 message, C12/C13 bullets and Notes
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte identity with the Appendix; does not re-run the reviewer's execution at d07cc89c.

`git rev-parse HEAD:test/scripts/fixture-git-env.bats` is `6c7fb3eda0cc...`, the g1-g2 patch's post-image `index 5824372..6c7fb3e`. The +/-/context lines of `git diff d8003fbf 39ed1d53 -- test/scripts/dev-cycle.bats` equal the g3 patch's (`diff` empty, E6).

**Evidence:** `docs/reviews/test-strategy-review-2026-10-06-i3-build-loop-u2a1.md:105-172`; commit 39ed1d53

---

## Claim 28: 39ed1d53 "the inner dev-cycle test is one that stages (check-answer needs a default branch found by name)"

**Location:** commit 39ed1d53 message, C12 bullet
**Type:** Behavioral
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the selected test running `git add -A`; does not establish that the filter selects only one test (bats prints `1..1` and victim_unchanged asserts it).

`git add -A && git commit -qm q && git checkout -q -b trunk && git branch -q -D main` (`test/scripts/dev-cycle.bats:1209`).

**Evidence:** `test/scripts/dev-cycle.bats:1207-1212`; `test/scripts/fixture-git-env.bats:23-24`, `:32`

---

## Claim 29: 39ed1d53 "C16 (pin_hermetic_git) stays carried: its trigger is an edit of one of row 327's suites, and none is edited here."

**Location:** commit 39ed1d53 message
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch's file list against row 327's suites.

Row 327 names test/merge-safety.bats, test/cc-push.bats, test/scripts/archive-working-docs.bats, test/si-clean-state.bats and test/cc-isolated-functions.bats; row 335 (C16) amends its trigger. `git diff --stat main...HEAD` touches none of them.

**Evidence:** `docs/reviews/override-log.md:327`, `:335`

---

## Claim 30: 39ed1d53 "Tests: 105 across dev-cycle, build-loop-read, build-loop-check, fixture-git-env and hermeticity."

**Location:** commit 39ed1d53 message
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count and pass at HEAD.

E1: exit 0, `grep -c '^ok'` = 105.

**Evidence:** `/tmp/u2a2-cfc-RrAi/tests.log`

---

## Claim 31: Plan F10 "Floor item 4 keeps the docs `check_fix` denies (`docs/decisions/`, `docs/human-author/`, other briefs' working docs, cycle files) and adds `docs/thoughts/`, which `check_fix` still fixes"

**Location:** `docs/working/plan-build-loop-handoff.md:125`
**Type:** Architectural
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** static
**Scope:** Covers check_fix at HEAD and the floor's planned shape on feat/build-loop-u2a2-full (6c41aea2, context only); the floor itself is not on this branch.

check_fix refuses `^docs/(working|human-author|reviews|decisions)/` but not thoughts/ (`scripts/dev-cycle.sh:179`); 6c41aea2's floor has `elif [[ "$lp" =~ ^docs/(decisions|thoughts|human-author)/ ]]`.

**Evidence:** `scripts/dev-cycle.sh:179-181`; `git show 6c41aea2:scripts/lib/dev-cycle-read.sh` floor()

---

## Claim 32: Plan F11 "a name holding a newline or absolute or newline link text fails the walk, so floor refuses every path). Gaps: known issue A5 (symlinked directories, case-insensitive names, absolute imports, a symlinked untracked start), and the untracked starts come from the checkout `--check` runs in"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed refusals and gaps; does not cover whether the floor (U2a3) uses the walk as described.

What it lists is true (Claims 6, 7). The Gaps list omits the two shapes in Claim 7 (NUL in symlink text; an untracked symlink at an import target), and the refusal list omits doubled names and empty text, which the code also refuses.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`; `/tmp/u2a2-cfc-RrAi/gapA.log`, `/tmp/u2a2-cfc-RrAi/gapB.log`

---

## Claim 33: Plan :273 "U2 carries 26 override rows"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the count under prior reviews' filter (`grep -cE '\| Defer \|.*\bU2\b'`), the filter row 333 cited; other filters give other counts (33 rows have a `Revisit trigger:` naming U2).

The filter gives 26 at 4e12b03c, at main and at HEAD. Medium because "carries" fixes no filter.

**Evidence:** `docs/reviews/override-log.md` (count over table rows); `docs/reviews/code-fact-check-report-build-loop-u2a1.md:443`

---

## Claim 34: Plan :275 "**U2a2, the floor in the lib** (no new mode): `floor`, `ownfile`, `GATE_CODE` and `isimported`, and an import walk ... It refuses the tree and link shapes it does not model (a name holding a newline, absolute or newline symlink text, a `..` name)"

**Location:** `docs/working/plan-build-loop-handoff.md:275`
**Type:** Staleness
**Verdict:** Stale
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the step-5 split note against this branch; the line is context in this diff, not edited.

This branch splits U2a2 again: floor, ownfile and GATE_CODE move to U2a3 (d8003fbf; Q-119 update), and no U2a3 row exists in the plan (`grep -n U2a3` finds none). A `..x` name is now followed, not refused: `[[ "$p" != .. && "$p" != ../* ]] || continue` (`scripts/lib/dev-cycle-read.sh:485`), and `..`/`../` escapes are dropped, not refused.

**Evidence:** `docs/working/plan-build-loop-handoff.md:275`; `scripts/lib/dev-cycle-read.sh:485`; `docs/working/questions.md` Q-119 update

---

## Claim 35: Known issue A5 "closes A2 and A3's symlinked-file half for the self-merge floor (... odd names or link text fail the walk), but not paths through a symlinked directory, other names ... on a case-insensitive checkout, absolute imports into the repo, or a symlinked untracked start file"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Legibility-target:** for-author
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's coverage at HEAD; the floor that consumes it is U2a3's.

The listed gaps are real (static, and the override row of 2026-10-06 records them). "Odd ... link text fail the walk" does not hold for link text holding a NUL, and the list omits the untracked symlinked import target (Claim 7, E3).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`; `/tmp/u2a2-cfc-RrAi/gapA.log`, `/tmp/u2a2-cfc-RrAi/gapB.log`

---

## Claim 36: Q-119 update "U2a2 (the floor plus the walk, 400 code lines before U2a1's carried rows) was split again at the walk/floor seam: U2a2 is the commit-reading walk and `isimported`, U2a3 adds the floor on top."

**Location:** `docs/working/questions.md:392`
**Type:** Reference
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count (53a6912b against its base) and the split's content on this branch.

numstat of 53a6912b: `400`. This branch adds main_imports and isimported, and no floor, ownfile or GATE_CODE (`grep` finds none in the lib at HEAD).

**Evidence:** `docs/working/questions.md:392`; `scripts/lib/dev-cycle-read.sh:515-592`

---

## Claim 37: Override row "Row 319's short header lines remain at `scripts/lib/dev-cycle-read.sh:13` and `:25`"

**Location:** `docs/reviews/override-log.md:339`
**Type:** Staleness
**Verdict:** Stale
**Legibility-target:** for-author
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the line numbers at HEAD; the row is dated for feat/build-loop-u2a and may have been exact there.

At HEAD, `:13` is 79 characters and `:25` is 75; the short header lines are `:18` (69) and `:21` (70) (awk line lengths, E6). The header was re-edited in this branch (`:15`, `:32-34`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-34`

---

## Claim 38: Override row "main_imports reads each instruction blob with its own cat-file ... 45 files here"

**Location:** `docs/reviews/override-log.md:346`
**Type:** Configuration
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start-file count on main 20347279 and the per-blob cat-file; not the ms timing.

Applying INSTRUCTION_FILE and the `.claude/rules/*.md` rule to `git ls-tree -r --name-only 20347279` counts 45; `git cat-file blob "$MAIN_SHA:$f"` runs once per queued `m:` blob (`:558`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-558`

---

## Claim 39: dev-cycle.bats inventory additions (functions isimported, inrepo_here, main_imports, import_targets, instruction_names, untracked_md; variables UNI_SPACES, IMPORTED_MAIN, IMPORTED_MAIN_DONE)

**Location:** `test/scripts/dev-cycle.bats:1083-1094`
**Type:** Staleness
**Verdict:** Verified
**Legibility-target:** for-orchestrator-synthesis
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each named symbol exists when the lib is sourced.

The test passes (E1); each name is defined at `:125`, `:467-496`, `:522`, `:583`.

**Evidence:** `test/scripts/dev-cycle.bats:1083-1094`; `/tmp/u2a2-cfc-RrAi/tests.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`scripts/lib/dev-cycle-read.sh:458-464`): "refuses what it does not model" fails for symlink text holding a NUL (`$(...)` drops it; the walk follows `docs/rules.mdzzz` while checkout links `docs/rules.md`) and for an untracked symlink at an import target (its target is never read). Neither is in the "Not covered" list. Fix: refuse both, or list them in the comment, A5, F11 and Q-103.
- **Claim 13a** (`scripts/lib/dev-cycle-read.sh:515-521`, code `:529-530`, `:539-540`): an ls-tree or untracked-listing failure does not return 1 with IMPORTED_MAIN=error. Under the caller's `set -e` the `< <(...)` subshell exits before `printf 'rc=...'`, and `${recs[-1]}` ends the process with `bad array subscript`. No test covers it.
- **Claim 21** (commit d8003fbf): 53a6912b is on no branch; feat/build-loop-u2a2-full holds 6c41aea2 (rebased, 398 lines).
- **Claim 22** (commit d8003fbf): "each command's exit status after its last NUL" is not written on failure (same as 13a).

### Stale
- **Claim 34** (`docs/working/plan-build-loop-handoff.md:275`): still describes U2a2 as the floor and says a `..` name is refused; U2a3 is not in the plan.
- **Claim 37** (`docs/reviews/override-log.md:339`): `:13` and `:25` are no longer the short header lines at HEAD (`:18`, `:21`).

### Mostly Accurate
- **Claim 13c** (`scripts/lib/dev-cycle-read.sh:515-520`): the return-1 list omits no main by name, the untracked listing, a record failing the regex, and empty link text.
- **Claim 13d** (`scripts/lib/dev-cycle-read.sh:516-517`): git's path lookup reads the first copy, but checkout keeps the last.
- **Claim 23** (commit d8003fbf): "R2-R4" cites R4 (the `..x` name) as a walk refusal; it is fixed by following.
- **Claim 25a** (commit d8003fbf): instruction_names is used by the tree walk only.
- **Claim 32** (plan F11) and **Claim 35** (known issue A5): the gap lists omit Claim 7's two shapes.
- (13b's dead guard: the symlink `if ! out="$(...; printf x)"` at `:561` never fires; an unreadable link fails through the empty-text test. Verified result, mechanism noted.)

### Unverifiable
- None.

## Escalations

- **E1 (Claim 7, fail-open, Medium):** two shapes pass the gate's walk silently. (a) A main symlink whose text holds a NUL: checkout links the text before the NUL, the walk follows the whole text with the NUL dropped, and the real target and its imports answer `-` (executed, `gapA.log`). This is the same `$(...)` byte-loss family as U2a rubric R3, which the `printf x` closed for newlines only. (b) An untracked symlink at an import target main lacks: the target file and its imports answer `-` (`gapB.log`). Neither is in an override row's settled A5 list (rows dated 2026-10-06 for `feat/build-loop-u2a` name symlinked directories, case-insensitive names, absolute imports and a symlinked untracked start). (b) may be read as the same family as "symlinked untracked start"; if so, the row's wording should say "untracked symlinks" rather than "start". Both need the shape already on main or in the orchestrator's checkout, so neither is reachable from a loop branch alone.
- **E2 (Claim 13a, documented contract broken, Medium for U2a3):** the listing-failure paths end the process instead of returning 1. Closed for a gate, but U2a3's `elif ! main_imports; then FLOOR_WHY=...` (6c41aea2) can never word them, and isimported's "answers imported" does not hold there. Mechanism: errexit is inherited into process substitution, not command substitution (executed, `psub.log`). An untested path: no test makes ls-tree or ls-files fail.
- **E3:** the skill's hallucination-pattern update was not performed. No Incorrect verdict is a fabricated symbol (53a6912b exists; the others are behavioural), so nothing qualifies, and shared.md forbids repo writes beyond this report anyway.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 39ed1d53` as its first line."
- **Answered:** all 11 requested checks. 1: Claims 1-2. 2: 4-8. 3: 13a-13d and 7 (realpath/`../`/`*) continue`: the realpath `|| continue` is effectively unreachable with `-ms`; `../` escapes leave the repo, so they cannot hide a repo path; `*)` is reached only by gitlinks (trees are not listed under `-r`), which Claude Code cannot load as a file; the `t:` non-plain `continue` is fail-open, Claim 7b). 4: 14, 8. 5: 9, 10, 25a, 25b. 6: 11, 12. 7: 3. 8: 15. 9: 21-30, 36. 10: 16-20. 11: 31-35, 37-38.
- **Out of scope:** code quality, and whether the A5 gaps are acceptable (settled rows). The U2a review artifacts are history, not checked.
- **Escalate:** E1 and E2 above.
- **Questions / Decisions:** probes ran only in `/tmp/u2a2-cfc-RrAi` and `/tmp/u2a2-cfcr-*` / `/tmp/u2a2-cfct-*` fixture dirs. Every process ran under `timeout` and has exited. No tracked file was modified except this report. The scratch dirs are left for the orchestrator to inspect or remove.
