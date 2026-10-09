Commit: 639f7b40

# Code Fact-Check Report

**Replication:** k=1 (loop pass, decision 031)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b2, branch feat/build-loop-u2b2)
**Scope:** iteration-2 delta `c10b972a..639f7b40` (d67966fe adds only review reports): scripts/build-loop.sh (help text, `callervar`, `gate_repo`, `checkout_gate`, `check_line`), scripts/lib/dev-cycle-read.sh (gate caller contract item 3 note), docs/working/known-issues-dev-cycle.md (A5), docs/working/plan-build-loop-handoff.md (U2b2 bullet), test/scripts/build-loop-check.bats (the five U2b2 tests), and commit 639f7b40's message
**Checked:** 2026-10-08 (executions 2026-10-09T01:18Z-01:24Z UTC)
**Total claims checked:** 26
**Summary:** 16 verified, 7 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Reading done: scripts/build-loop.sh help (:80-150), `harden` and the export line (:205-224), `callervar`/`gate_repo`/`gate_git`/`merge_result` (:516-565), `nrules` (:587-607), `checkout_gate` whole (:608-688), `check_line` whole (:695-750) and the `check` mode driver (:764-776); scripts/lib/dev-cycle-read.sh :25-75 and `checkout_md` (:877-880); the five U2b2 tests and their helpers (:1605-1706). Hallucination pattern log read: its nearest pattern is "per-suite counts in a commit message" (37c5ea9, 59ca38f entries); Claim 25 checks it and the counts match. No Incorrect verdict below is a fabricated symbol, so the log is not extended.

Execution environment: git 2.39.5, bash 5.2.15, mawk 1.3.4, shellcheck 0.9.0. All captured output is under `/tmp/claude-1000/-workspace/67a6f690-c029-41ac-9bf2-d19f7c0e4343/scratchpad/fc2/` (below: `$FC2/`). Mutants were run on a `git archive 639f7b40` copy in `/tmp/fc2u2b2-VnfO` by `$FC2/mut.sh` (one perl substitution in scripts/build-loop.sh, then `TMPDIR=<mktemp> timeout 600 bats -f U2b2 test/scripts/build-loop-check.bats`); every temp dir is removed.

---

## Claim 1: help text lists every checkout refusal

**Location:** `scripts/build-loop.sh:115-133`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the match, both ways, between the help's listed refusals and every `CHECKOUT_WHY=` assignment in `checkout_gate`; does not establish the wording of each reason (the help lists conditions, not texts) or anything outside `checkout_gate`.
**Legibility-target:** for-author

Every `CHECKOUT_WHY` assignment in `checkout_gate` (:630-688) has a matching help clause: the env-var rule (:632-633), HEAD (:635-636), the three core keys and their read failure (:640-641, "or one of them unreadable"), the index bits and listing (:646-648), `git status` failing/warning or non-empty (:650-652), untracked listing and nested repository (:657-659), tree listing (:660), gitlink symlink/unlistable/with files (:667-671), the name rule (:678-679), hash failure and blob mismatch (:684-687). The help adds nothing the code lacks. Two imprecisions:

- The name rule is stated for "a file main stores", but it runs only on regular files: the 120000 and 160000 branches `continue` before it:
  ```bash
  # scripts/build-loop.sh:664-672 (excerpt; enclosing checkout_gate continues to :688 — read)
      100644|100755) ;;
      120000) continue ;;
      160000)
        ...
        continue ;;
  ```
  A symlink or gitlink whose name starts with `"` is not refused (and need not be: it is never hashed). "a regular file main stores" is the precise wording.
- Two refusals are folded into neighbours without being named: an unreadable HEAD prints "the checkout's HEAD is unreadable" (`x="unreadable"`, :635), covered only as "HEAD at another commit"; a tree record whose mode is not 100644/100755/120000/160000, or that misses the regex, prints "the default branch's tree could not be read" (:662, :673), covered by "a listing ... that fails".

**Evidence:** `scripts/build-loop.sh:115-133`, `scripts/build-loop.sh:624-688`

---

## Claim 2: "the text up to "; " is fixed; path and deny lines follow it as they follow ok"

**Location:** `scripts/build-loop.sh:115-116`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the checkout refusal's fixed prefix and that the per-path rows print after it when the merge changes paths; does not establish output when an earlier return in `check_line` (blob-missing, lower-casing failure) fires, which drops the checkout refusal entirely (see Claim 3).

```bash
# scripts/build-loop.sh:731-732
  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run from a clean checkout of the default branch's commit; $CHECKOUT_WHY"; fi
  if [[ ${#ps[@]} -eq 0 ]]; then echo "${co:-ok $a $sha $tree}"; return; fi
```
```bash
# scripts/build-loop.sh:748-749
  if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of ${#ps[@]} changed paths refused in the merge of $sha (tree $tree)"; fi
  printf '%s\n' "${rows[@]}"
```
No `CHECKOUT_WHY` text contains "; " (read every assignment, :630-688). Executed: the U2b2 tests' `coref` asserts line 1 = `refuse $B: $CO; WHY` and line 2 = the path row, and the advisory test asserts the refusal plus a deny and a path row; all pass at HEAD (207/207).

**Evidence:** `scripts/build-loop.sh:731-749`, `test/scripts/build-loop-check.bats:1610-1614`, `test/scripts/build-loop-check.bats:1678-1691`; command `TMPDIR=$(mktemp -d /tmp/fc2u2b2-XXXX) timeout 1200 bats test/scripts/build-loop-check.bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`, cwd the worktree, exit 0, 2026-10-09T01:18:49Z; output `$FC2/suites-head.log`

---

## Claim 3: "It is judged after the merge and the N rules, so a loop running --check from its own branch still gets the path lines"

**Location:** `scripts/build-loop.sh:134-137`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers when `checkout_gate` runs relative to `merge_result`, the blob check and `nrules`, and which line wins; does not establish U2c's future placement of the walk.

"After the merge" is right, and the stated consequence (the path lines still print) holds (Claim 2). "After the N rules" holds only for which verdict line wins (`co` is printed over the K-of-N line, :748). The check itself *runs* before the N rules: `checkout_gate` is called at :731, and `nrules` runs later, in the loop at :743-747:
```bash
# scripts/build-loop.sh:743-746 (excerpt; enclosing check_line continues to :750 — read)
  for i in "${!ps[@]}"; do
    p="${ps[$i]}"; shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"
    nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"
```
It also runs before the blob-presence check (:737-740) and the lower-casing pass (:742). Each of those `return`s without printing `co`, so a brief that fails both its checkout and one of those prints only the later refusal. Precise version: "It is judged after the merge, before the N rules; its refusal replaces the ok or K-of-N line, and the path lines still follow."

**Evidence:** `scripts/build-loop.sh:131-137`, `scripts/build-loop.sh:713-749`

---

## Claim 4: "GIT_CONFIG, a whole config file git config reads instead of the repo's"

**Location:** `scripts/build-loop.sh:528-529`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's handling of GIT_CONFIG by `git config --get` and by one non-config command; does not establish every git subcommand's behaviour.

The probe ran with `core.symlinks false` in the repo config and `symlinks = true` in a GIT_CONFIG file:
```
git config core.symlinks: false
GIT_CONFIG=cfg git config core.symlinks: true
repo key under GIT_CONFIG rc=1
rev-parse --is-bare-repository under GIT_CONFIG(bare=true): false
```
`git config` reads the GIT_CONFIG file *in place of every* config scope: a key set only in the repo's config is absent (rc=1). Other commands ignore it (`rev-parse` did not see `core.bare = true`). "instead of the repo's" understates this: it replaces system, global and repo alike. The rest of the comment holds: GIT_CONFIG_PARAMETERS, GIT_CONFIG_COUNT and GIT_NO_REPLACE_OBJECTS all appear in 2.39.5's `--local-env-vars`, and the script exports GIT_NO_REPLACE_OBJECTS (:226). "which harden extends" fits GIT_CONFIG_COUNT only. `harden` appends to the COUNT pairs (:217-220) and leaves `git -c`'s GIT_CONFIG_PARAMETERS alone ("trusts" covers both).

**Evidence:** `scripts/build-loop.sh:216-226`, `scripts/build-loop.sh:525-530`; command `timeout 60 bash $FC2/probes.sh` (sections P1, P5), cwd a `/tmp/fc2u2b2-*` dir it creates, exit 0, 2026-10-09T01:23:43Z; output `$FC2/probes.log`

---

## Claim 5: "(gate_repo unsets it; checkout_gate refuses it)"

**Location:** `scripts/build-loop.sh:529`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers GIT_CONFIG's handling in gate_repo and checkout_gate, and whether dropping the old `GIT_CONFIG*` trust changes anything else gate_repo kept; does not establish GIT_CONFIG's effect on the hardened top-level git calls outside these two functions (state_gate uses `--file`).

```bash
# scripts/build-loop.sh:530-534 (excerpt; enclosing gate_repo continues to :539 — read)
callervar() { [[ "$1" == GIT_CONFIG_PARAMETERS || "$1" == GIT_CONFIG_COUNT || "$1" == GIT_NO_REPLACE_OBJECTS ]]; }
gate_repo() {
  local fmt v
  GATE_ENV=(env)
  for v in $(git rev-parse --local-env-vars); do callervar "$v" || GATE_ENV+=(-u "$v"); done
```
Of 2.39.5's sixteen `--local-env-vars`, the old pattern `GIT_CONFIG*` matched exactly GIT_CONFIG, GIT_CONFIG_PARAMETERS and GIT_CONFIG_COUNT (P1). The new rule keeps the latter two, so GIT_CONFIG is the only change. GIT_CONFIG_KEY_n/VALUE_n are not local-env-vars and pass through either way. `gate_git` runs only merge-base, cat-file, merge-tree, diff-tree and hash-object (:546, :557-561, :577, :716, :737), and none of them reads GIT_CONFIG (Claim 4). So gate_repo's merge behaves the same. In checkout_gate, `callervar` is false for a set GIT_CONFIG, so it refuses (:632-633). Mutant m5 (callervar also trusting GIT_CONFIG) turns test 1 red.

**Evidence:** `scripts/build-loop.sh:530-546`, `scripts/build-loop.sh:630-634`, `test/scripts/build-loop-check.bats:1642`; mutant command `$FC2/mut.sh /tmp/fc2u2b2-VnfO m5-gitconfig '<perl subst>'`, exit of bats 1, 2026-10-09T01:20Z; output `$FC2/mut-m5-gitconfig.log`, `$FC2/probes.log`

---

## Claim 6: "Item 2's fsmonitor and replace refs are harden's and the state gate's, and its ls-files stderr rule is the walk's own"

**Location:** `scripts/build-loop.sh:610-611`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers who handles each item-2 element the comment names; does not establish that every ls-files call in the walk has a stderr rule (only `checkout_md`'s was read).

Item 2 names "GIT_INDEX_FILE, GIT_WORK_TREE, fsmonitor, sparse checkout, core.ignoreCase, replace refs" and the ls-files stderr rule (`scripts/lib/dev-cycle-read.sh:47-51`). harden sets `core.fsmonitor=false core.useReplaceRefs=false` (:218), and the export line sets `GIT_NO_REPLACE_OBJECTS=1` (:226). The state gate refuses `core\.fsmonitor` keys (`STATE_KEYS_RE`, :240) and any `refs/replace/` ref (:256-257). The walk owns the stderr rule:
```bash
# scripts/lib/dev-cycle-read.sh:878-880
# phase-2 seeds); fails when git exits nonzero or prints anything on stderr,
# since an unreadable directory goes unlisted with only a warning.
checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }
```
checkout_gate covers the rest: GIT_* variables (:630-634), core.ignoreCase and sparse (:637-642).

**Evidence:** `scripts/build-loop.sh:216-226`, `scripts/build-loop.sh:240-257`, `scripts/build-loop.sh:608-642`, `scripts/lib/dev-cycle-read.sh:47-51`, `scripts/lib/dev-cycle-read.sh:878-880`

---

## Claim 7: "check_line calls it for each self-merge brief, after the N rules and where U2c's floor walk will run, so it is final before that walk"

**Location:** `scripts/build-loop.sh:613-614`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where check_line calls checkout_gate relative to `nrules` and to the per-path loop where U2c's walk is to run; does not establish U2c's eventual code.

check_line calls `checkout_gate` once, at :731, *before* the blob-presence check (:737), the lower-casing pass (:742) and the per-path loop that calls `nrules` (:743-747). The comment's mechanism, "after the N rules", is refuted by the call order (Claim 3's excerpt), and so is "where U2c's floor walk will run". check_line's own comment, three lines further down, places the walk later, per path:
```bash
# scripts/build-loop.sh:728-731
  # A self-merge brief's checkout (contract items 2 and 3), judged after the
  # merge, so the path lines still print (a loop's advisory run from its own
  # branch learns them), and before U2c's floor walk, which runs per path below.
  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: ...
```
(excerpt :731 abbreviated; full line read.) "For each self-merge brief" and "final before that walk" hold: the call is per brief, and nothing between :731 and the loop touches the checkout. Today the behaviour is the same either way. The comment matters because U2c will place its walk by these comments, and this one disagrees with check_line's. Fix: "check_line calls it for each self-merge brief after the merge, before the N rules and U2c's per-path floor walk".

**Evidence:** `scripts/build-loop.sh:608-622`, `scripts/build-loop.sh:713-749`

---

## Claim 8: "The C locale: under UTF-8 a regex . does not match an invalid byte, and a record skipped for its name would escape the byte comparison."

**Location:** `scripts/build-loop.sh:625-627`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2's `=~` on a 0xFF byte under C.utf8 and C, a function-local `LC_ALL=C`, and the regression when it is removed; does not establish the locale child processes see (see Claim 23).

The probe matched `[[ $'a\xffb' =~ ^a.b$ ]]`:
```
C.utf8 nomatch
C match
-- caller exported LC_ALL=C.utf8
func-local C: match
```
Mutant m1 (delete `local LC_ALL=C`) turns test 2 red: its non-UTF-8 case (`LC_ALL=C.utf8 coref "$WHY"`, test :1664-1667) no longer gets the blob-mismatch reason.

**Evidence:** `scripts/build-loop.sh:625-628`, `test/scripts/build-loop-check.bats:1663-1667`; `$FC2/probes.log` (P2; command `timeout 60 bash $FC2/probes.sh`, exit 0, 2026-10-09T01:23:43Z); `$FC2/mut-m1-noLCALL.log` (bats exit 1, 2026-10-09T01:20Z)

---

## Claim 9: "GIT_PREFIX only names a subdirectory for an alias; the script cds to the top level."

**Location:** `scripts/build-loop.sh:631`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the script's cd to the top level before any checkout_gate call; does not establish git's own use of GIT_PREFIX beyond aliases.

```bash
# scripts/build-loop.sh:280-281
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not inside a git repository" >&2; exit 1; }
cd "$ROOT"
```
This runs at top level, before the mode dispatch (:764+) that reaches check_line.

**Evidence:** `scripts/build-loop.sh:280-281`, `scripts/build-loop.sh:629-634`

---

## Claim 10: "ls-files -v tags each entry: H is plain; S is skip-worktree, lower case is assume-unchanged (git status skips a change under either), M is unmerged."

**Location:** `scripts/build-loop.sh:644-645`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tag meanings under harden (fsmonitor off) and git status's blindness under both bits; does not establish tags under an enabled fsmonitor (harden disables it, :218).

Test 1 now asserts `[ -z "$(git status --porcelain --untracked-files=no)" ]` after a real change under each bit, then refuses with `$IDX` (test :1629-1635). It passes at HEAD.

**Evidence:** `scripts/build-loop.sh:644-648`, `test/scripts/build-loop-check.bats:1629-1635`; `$FC2/suites-head.log` (exit 0, 2026-10-09T01:18:49Z)

---

## Claim 11: "To a file: bash would warn on stderr about the NULs a $(...) drops."

**Location:** `scripts/build-loop.sh:649`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2's warning on NUL bytes in command substitution and its reach to `--check`'s stderr; does not establish other bash versions.

The P3 probe printed `warning: command substitution: ignored null byte in input` on stderr. Mutant m8 put c10b972a's `x="$(git status ... 2>&1)"` back, and the warning reached `--check`'s stderr (`build-loop.sh: line 650: warning: command substitution: ignored null byte in input`). Tests 1 and 5 went red on their empty-stderr assertions.

**Evidence:** `scripts/build-loop.sh:649-652`; `$FC2/probes.log` (P3); `$FC2/mut-m8-statussubst.log` (bats exit 1, 2026-10-09T01:21:18Z)

---

## Claim 12: "git status compares a link's text to its blob unconverted (core.symlinks is true here)."

**Location:** `scripts/build-loop.sh:666`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a tracked symlink retargeted in the checkout, refused through the git status rule; does not establish the core.symlinks-unset case on a filesystem without symlinks.

A scratch test was appended to the archive copy only (`sm`; commit `link.md -> docs/p.md`; `cook`; retarget it to `docs/other.md`; `coref "$STAT"`). It passed. core.symlinks false is refused earlier (:637-642), so "true here" holds whenever the loop is reached.

**Evidence:** `scripts/build-loop.sh:637-642`, `scripts/build-loop.sh:664-666`; command `TMPDIR=<mktemp> timeout 600 bats -f 'FC2 probe' test/scripts/build-loop-check.bats`, cwd `/tmp/fc2u2b2-VnfO`, exit 0, 2026-10-09T01:22:43Z; output `$FC2/probe-fc2.log`

---

## Claim 13: "hash-object --stdin-paths reads a line: a newline splits a name, a leading " is unquoted and a trailing CR dropped, so another file is hashed."

**Location:** `scripts/build-loop.sh:676-679`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's stdin-paths for a `"q"` name and an `r<CR>` name, and the rule's refusal; does not establish names that are badly C-quoted (`"x`, which makes hash-object fail, caught by :684-685).

P4 output:
```
stdin-paths '"q"': b9bca019...  file '"q"': b04fedbe...  file q: b9bca019...
stdin-paths 'r<CR>': 7f7e6aec...  file 'r<CR>': 59fb00aa...  file r: 7f7e6aec...
```
So `"q"` hashes `q`, and `r<CR>` hashes `r`. Mutant m2 (drop the quote and CR tests) turns test 3 red.

**Evidence:** `scripts/build-loop.sh:676-679`, `test/scripts/build-loop-check.bats:1670-1676`; `$FC2/probes.log` (P4); `$FC2/mut-m2-noquoteCR.log` (bats exit 1)

---

## Claim 14: "judged after the merge, so the path lines still print ..., and before U2c's floor walk, which runs per path below."

**Location:** `scripts/build-loop.sh:728-730`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call's position in check_line; does not establish U2c's code.

The call is at :731, after `merge_result` (:708) and the diff-tree listing and parse (:716-727), and before the per-path loop (:743). The rows print after `co` (:748-749, quoted in Claim 2).

**Evidence:** `scripts/build-loop.sh:708-749`

---

## Claim 15: lib item-3 note: "The walk checks neither item but item 2's ls-files stderr rule. build-loop.sh --check does, for each self-merge brief before the walk (U2b2): harden and its state gate own item 2's fsmonitor and replace refs; checkout_gate the rest ... (so an eol conversion fails it too, and an attribute that changes no bytes does not)."

**Location:** `scripts/lib/dev-cycle-read.sh:55-62`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ownership split (Claim 6), the per-brief call (Claim 14), the eol case (test 2) and a no-op attribute; does not establish that "the walk checks neither item" covers every walk function. Only the walk's comment (:575-594) and `checkout_md` were read.

The suites cover the eol case (test 2's `eol=crlf` refusal). For the no-op case, a scratch test committed `docs/p.md ident eol=lf` on a file with no `$Id$` and LF endings, then ran `cook`. It passed (`$FC2/probe-fc2.log`). The byte comparison has no attribute input: `git hash-object --no-filters --stdin-paths` against main's blob ids (:684-687).

**Evidence:** `scripts/lib/dev-cycle-read.sh:44-62`, `scripts/build-loop.sh:682-687`; `$FC2/probe-fc2.log` (exit 0, 2026-10-09T01:22:43Z), `$FC2/suites-head.log`

---

## Claim 16: A5: "U2b2 closes several of these for the gate ... Still open there: start files under a symlinked directory, a FIFO start, and a checkout file swapped between the gate's check and the walk's read."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the mapping from A5's "Not covered" items to checkout_gate's rules; does not establish case-insensitive filesystem behaviour, which this Linux sandbox cannot exercise.

The not-covered list has seven entries: a symlinked directory, a submodule or untracked nested repo, a FIFO, a swapped file, other names on a case-insensitive checkout, conversions, and core.symlinks=false. The rules close four of them: nested repo and populated gitlink (:657-659, :667-671), conversions (:684-687), core.symlinks (:637-642). The "Still open" list names three more. That leaves "other names one file has on a case-insensitive checkout", which is neither listed as open nor fully closed. checkout_gate refuses only `core.ignoreCase` *true*:
```bash
# scripts/build-loop.sh:637-642 (excerpt of checkout_gate's loop; function continues to :688 — read)
  for v in "core.symlinks false: a symlink is checked out as a file holding its text" \
    "core.ignoreCase true: a case-insensitive checkout" "core.sparseCheckout true: a sparse checkout"; do
```
A case-insensitive filesystem with `core.ignoreCase=false` still gives one file several names. That residue is inferred from git's documented meaning of the key and not executed (no case-insensitive filesystem here). The sentence's own list ("core.ignoreCase and sparse checkout off") is accurate. Only the open list is incomplete.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/build-loop.sh:637-688`

---

## Claim 17: plan U2b2 bullet: "`checkout_gate`, run per self-merge brief inside `check_line` after the merge and the N rules"

**Location:** `docs/working/plan-build-loop-handoff.md:284`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the stated call position; the bullet's list of refusals and the iteration-1 additions agree with Claims 1, 5, 8 and 13.

Same mechanism error as Claim 7: the call (:731) precedes `nrules` (:743-747); quoted in Claims 3 and 7. "(so path lines still print ..., and the check is final before U2c's floor walk)" is right.

**Evidence:** `docs/working/plan-build-loop-handoff.md:284`, `scripts/build-loop.sh:731-747`

---

## Claim 18: "Each index flag hides the change from git status."

**Location:** `test/scripts/build-loop-check.bats:1629`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers assume-unchanged and skip-worktree on a modified tracked file; does not establish the unmerged bit (not hidden; not claimed).

```bash
# test/scripts/build-loop-check.bats:1630-1634
    echo c >> docs/a.md; git update-index --assume-unchanged docs/a.md
    [ -z "$(git status --porcelain --untracked-files=no)" ]; coref "$IDX"
    git update-index --no-assume-unchanged docs/a.md; git checkout -q -- docs/a.md
    git update-index --skip-worktree docs/a.md; echo d >> docs/a.md
    [ -z "$(git status --porcelain --untracked-files=no)" ]; coref "$IDX"
```
Passes at HEAD.

**Evidence:** `test/scripts/build-loop-check.bats:1629-1635`; `$FC2/suites-head.log`

---

## Claim 19: "an empty directory there passes (git status reports an absent one)"

**Location:** `test/scripts/build-loop-check.bats:1695`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's status for a gitlink path absent, an empty directory and a symlink; does not establish an absent path's handling inside checkout_gate's 160000 branch, where it passes because git status already refused it.

P6 output: `absent: rc=0 out=[ D sub|]`, `empty dir: rc=0 out=[]`.

**Evidence:** `test/scripts/build-loop-check.bats:1693-1698`; `$FC2/probes.log` (P6)

---

## Claim 20: advisory test: "On feat/x itself, as a loop runs it: the refusal, then every path line, a deny among them."

**Location:** `test/scripts/build-loop-check.bats:1685-1690`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three-line output (refusal with the actual HEAD, one deny, one path) for a self-merge brief run from its own branch; does not establish ordering among path rows (diff-tree's order, tested elsewhere).

The test asserts `${#lines[@]} -eq 3`, line 0 the checkout refusal naming `$(git rev-parse feat/x)`, and both `has` rows. It passes at HEAD. Mutant m9 (the check moved back before `merge_result`, with an early return) turns all five U2b2 tests red, this one included.

**Evidence:** `test/scripts/build-loop-check.bats:1678-1691`; `$FC2/suites-head.log`; `$FC2/mut-m9-earlygate.log` (bats exit 1, 2026-10-09T01:21Z)

---

## Claim 21: "git status already warns about a symlink there, before the gitlink rule reads it" (test), and the commit's "a symlink at a gitlink path is refused by the git status rule (git warns) before the gitlink rule reads it"

**Location:** `test/scripts/build-loop-check.bats:1703`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's status on a symlink at a gitlink path and which rule refuses; does not establish other git versions.

The status rule refuses before the gitlink rule, as claimed. But git does not merely warn: it fails. P6 printed `symlink: rc=128 out=[] err=[error: expected submodule path 'sub' not to be a symbolic link]`. Precise wording: "git status fails (exit 128) on a symlink there". The asserted reason, "git status failed or warned", covers both. Mutant m3 (drop `[[ -L "$p" ]]`) stays green, which confirms the test cannot reach the gitlink rule's symlink half.

**Evidence:** `test/scripts/build-loop-check.bats:1700-1704`, `scripts/build-loop.sh:650-651`, `scripts/build-loop.sh:667-668`; `$FC2/probes.log` (P6); `$FC2/mut-m3-noL.log` (bats exit 0)

---

## Claim 22: commit 639f7b40: "checkout_gate runs inside check_line for each self-merge brief, after the merge and the N rules, and before the point U2c's floor walk runs"

**Location:** commit 639f7b40 message, A4-A6 bullet
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the call order; the bullet's other statements (path and deny lines follow; CHECKOUT_WHY computed where read) are Verified by Claims 2 and 14.

`checkout_gate` runs at `scripts/build-loop.sh:731`, before `nrules` (:743-747); quoted in Claims 3 and 7. The commit subject's "after the N rules" carries the same error.

**Evidence:** `scripts/build-loop.sh:731-747`

---

## Claim 23: commit 639f7b40: "A1 (security 2): checkout_gate runs under LC_ALL=C."

**Location:** commit 639f7b40 message, A1 bullet
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash's own matching and the locale checkout_gate's children inherit; does not establish any behavioural difference in those children under mawk (none found).

Bash's own `=~` and pattern tests do run under C (Claim 8). But `local LC_ALL=C` is exported to children only when the caller had already exported LC_ALL. P2 output: `caller exported LC_ALL=C.utf8 ... child sees LC_ALL=C: 1`; `caller LC_ALL unset, LANG=C.utf8 ... child sees LC_ALL=C: 0`. The same diff dropped the explicit `LC_ALL=C` from both awk calls:
```bash
# scripts/build-loop.sh:646
  n="$(git ls-files -v -z | tr '\0' '\n' | awk 'substr($0, 1, 2) != "H " { n++ } END { print n + 0 }')" \
```
With LANG=C.UTF-8 and no LC_ALL, those awk and tr calls, `ls -A` and git run in the caller's locale. With mawk 1.3.4 (byte-based) and ASCII-only patterns, no effect was found. Precise version: "checkout_gate's own bash matching runs under the C locale".

**Evidence:** `scripts/build-loop.sh:625-628`, `scripts/build-loop.sh:646`, `scripts/build-loop.sh:658`; `$FC2/probes.log` (P2)

---

## Claim 24: commit 639f7b40: "Each fix's mutant turns a test red."

**Location:** commit 639f7b40 message, Tests paragraph
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers nine mutants of the iteration-1 fixes against the five U2b2 tests; does not establish mutants of the wording-only changes (A8/A9 reason texts are pinned verbatim by `coref`).

Red (bats exit 1): m1 no `local LC_ALL=C` (test 2), m2 no quote/CR rule (test 3), m4 no unlistable-gitlink rule (test 5), m5 GIT_CONFIG trusted (test 1), m8 status back in `$(...)` (tests 1, 5), m9 the check before the merge (all five).

Green (bats exit 0):
- m3: `[[ -L "$p" ]]` dropped. The commit's Notes disclose this.
- m6: an unmatched tree record goes back to `continue`. That is A1's "refuses instead of being skipped" half; under LC_ALL=C, git's own output always matches the regex, so no test can reach it.
- m7: the status rule's stderr-only half (`[[ ! -s "$GATE_TMP/err" ]]`) dropped. The only test that reaches it is the symlink case, and there git exits 128 (Claim 21), so the stderr half is never the deciding test.

Each A-numbered fix has at least one red mutant, so the claim holds per fix. Three defensive sub-rules have none.

**Evidence:** `$FC2/mut.sh`; `$FC2/mut-m1-noLCALL.log` ... `$FC2/mut-m9-earlygate.log` (cwd `/tmp/fc2u2b2-VnfO`, 2026-10-09T01:20:27Z-01:22Z)

---

## Claim 25: commit 639f7b40: "Suites 106/19/78/2/2; shellcheck clean"

**Location:** commit 639f7b40 message, Tests paragraph
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts of the five suites U2b1b's merge message names, an all-pass run at HEAD, and shellcheck at the health check's severity; does not establish `scripts/health-check.sh` as a whole (not rerun).

`bats --count`: build-loop-check 106, build-loop-read 19, dev-cycle 78, fixture-git-env 2, fixture-hermeticity 2. One run printed 207 `ok`, no `not ok`, exit 0. `shellcheck -x -e SC1091 -s bash -S warning` (the health check's invocation, `scripts/health-check.sh:480`) exits 0 on scripts/build-loop.sh. At default severity there is one new info note, SC2015, on :650. Matches the prior "per-suite counts" pattern class only in kind; the counts are right.

**Evidence:** `scripts/health-check.sh:476-480`; `$FC2/suites-head.log` (exit 0, 2026-10-09T01:18:49Z)

---

## Claim 26: commit 639f7b40: "Every cook/coref now asserts an empty stderr" and "(found by the new stderr assertions)"

**Location:** commit 639f7b40 message, A8/A9 and Tests paragraphs
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two helpers and the NUL warning they catch; does not establish the direct `chk` call in the advisory test (:1687), which asserts no stderr.

```bash
# test/scripts/build-loop-check.bats:1610-1615
coref() {
    chk "$B"
    [ "$status" -eq 2 ] && [ "${lines[0]}" = "refuse $B: $CO; $1" ] && [ "${lines[1]}" = "path $B A work-feat-x.txt" ] && [ "${#lines[@]}" -eq 2 ] \
        && [ -z "$stderr" ] || { echo "want: $1"; show; return 1; }
}
cook() { chk "$B"; [ "$status" -eq 0 ] && [[ "${lines[0]}" == "ok $B "* ]] && [ -z "$stderr" ] || { show; return 1; }; }
```
m8 shows these assertions catch the NUL warning (Claim 11).

**Evidence:** `test/scripts/build-loop-check.bats:1610-1615`; `$FC2/mut-m8-statussubst.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`scripts/build-loop.sh:613-614`): checkout_gate is called before the N rules and before the per-path loop where U2c's walk runs, not "after the N rules and where U2c's floor walk will run"; it disagrees with check_line's own comment at :728-730.
- **Claim 17** (`docs/working/plan-build-loop-handoff.md:284`): "after the merge and the N rules" should be "after the merge, before the N rules".
- **Claim 22** (commit 639f7b40, subject and A4-A6 bullet): same call-order error.

### Stale
None.

### Mostly Accurate
- **Claim 1** (`scripts/build-loop.sh:128`): the name rule applies to regular files only; an unreadable HEAD and an unexpected tree mode are folded into neighbouring clauses.
- **Claim 3** (`scripts/build-loop.sh:134`): "judged after the N rules" is true of which line wins, not of when the check runs; the blob and lower-casing refusals pre-empt the checkout refusal.
- **Claim 4** (`scripts/build-loop.sh:528`): GIT_CONFIG replaces every config scope for `git config`, not only the repo's; "harden extends" fits GIT_CONFIG_COUNT only.
- **Claim 16** (`docs/working/known-issues-dev-cycle.md:18`): "other names on a case-insensitive checkout" (case-insensitive filesystem, core.ignoreCase false) is neither closed nor in the "Still open" list.
- **Claim 21** (`test/scripts/build-loop-check.bats:1703`, commit Notes): git status fails (exit 128), it does not warn.
- **Claim 23** (commit A1): only bash's own matching runs under C; children inherit LC_ALL=C only if the caller exported LC_ALL, and the two awk calls lost their explicit `LC_ALL=C` (no effect found under mawk).
- **Claim 24** (commit Tests): mutants of three defensive sub-rules (gitlink `-L`, unmatched-record refusal, status stderr-only) stay green.

### Unverifiable
None.

---

## Goal-Alignment Note

**Success criterion (restated verbatim):** A markdown report saved to /workspace/.claude/wt-build-loop-u2b2/docs/reviews/code-fact-check-report-build-loop-u2b2-i2.md, structured per the code-fact-check skill, with `Commit: 639f7b40` as its first line and `**Replication:** k=1 (loop pass, decision 031)` in its header.

**Answered:** all seven prompt focus areas. (1) Claims 1-3: every listed refusal exists and vice versa; the early refusals still come first, and the blob/lower-casing refusals also pre-empt it. (2) Claims 6, 7, 15: the ownership split holds; "after the N rules" does not. (3) Claims 4, 5: GIT_CONFIG redirects only `git config` and replaces all scopes; dropping `GIT_CONFIG*` trust from gate_repo changes only GIT_CONFIG, which no gate_git command reads. (4) Claims 8, 13: both executed. (5) Claims 11, 16. (6) Claims 21-25. (7) Claims 10, 18-20.

**Out of scope:** whether the call order should change or the comments should (author's call); a case-insensitive filesystem run; `scripts/health-check.sh` as a whole.

**Escalate:** none blocking. Claims 7/17/22 are a single wording fix, and U2c will place its walk by these comments. Claim 24's green mutants and Claim 23's unexported locale are for the security pass to weigh.

**Questions / Decisions:** none.
