Commit: c10b972a

# Code Fact-Check Report

**Replication:** k=1 (loop pass, decision 031)
**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2b2, branch feat/build-loop-u2b2)
**Scope:** `git diff main...HEAD` at c10b972a: docs/working/known-issues-dev-cycle.md, docs/working/plan-build-loop-handoff.md, scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, test/scripts/build-loop-check.bats, plus commit c10b972a's message
**Checked:** 2026-10-08 (executions 2026-10-09T00:41Z-00:45Z UTC)
**Total claims checked:** 20
**Summary:** 12 verified, 8 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Reading done: scripts/build-loop.sh whole (735 lines), scripts/lib/dev-cycle-read.sh lines 1-80 and `import_reset` (:603), the three new tests whole, the override-log rows 366, 373, 387 and 397 (docs/reviews/override-log.md). Hallucination pattern log read: the only near pattern is "per-suite counts in a commit message" (commit 37c5ea9, 59ca38f entries); Claim 16 checks it and the counts match.

Execution logs: by the review rules this pass writes nothing into the worktree but this report, so captured output lives in `/tmp/fcu2b2-logs/` (ephemeral: probe1.txt, probe2.txt, suite-*.txt, mut-*.txt, timing.txt, health.txt). Probes ran in `mktemp -d /tmp/fcu2b2-XXXX` dirs with repo-local GIT_* unset and GIT_CONFIG_GLOBAL=/dev/null; suites, mutants and health-check ran in a `git archive c10b972a` copy under `/tmp/fcu2b2-*` (removed after). git is 2.39.5. No process left running (`ps` checked).

---

## Claim 1: "U2b2: `build-loop.sh --check` refuses a self-merge brief unless its checkout is clean at main with `core.symlinks` true and every regular file main stores hashes, unfiltered, to main's blob (`checkout_gate`; the effect of any such attribute, from any source, rather than `git check-attr`)."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the new U2b2 sentence against `checkout_gate` and `check_line`; does not establish that the rest of A5's unchanged "Not covered" list is current (it is not fully: see below).
**Legibility-target:** for-author

The sentence matches the code: the refusal is per self-merge brief (`if [[ "$pol" == self-merge && -n "$CHECKOUT_WHY" ]]`, `scripts/build-loop.sh:668`), the checks are HEAD (`[[ "$x" == "$MAIN_SHA" ]]`, `:612`), `git status` (`:623-624`), `core.symlinks` (`:613-618`) and the byte comparison (`git hash-object --no-filters --stdin-paths`, `:645`).

What to tighten: the same row's unchanged "Not covered" list still names "start files ... in a submodule or untracked nested repo" and "other names one file has on a case-insensitive checkout" as uncovered, with no note that U2b2 now refuses an untracked nested repository, a populated gitlink (`:629-638`) and `core.ignoreCase true` (`:614`) for a self-merge brief; the new sentence also omits those, the sparse-checkout and index-bit refusals (paraphrased — no quote available because the claim is about which items the A5 row's prose omits, i.e. absence of text).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `scripts/build-loop.sh:603-648`, `scripts/build-loop.sh:668-670`

---

## Claim 2: Plan U2b2 bullet: "Built 2026-10-08 ... `checkout_gate`, run once per `--check` when the policy is self-merge; a self-merge brief is refused unless ... (item 3 by its effect, which also covers the user's global attributes that harden hides from the gate's git). A review brief does not read the checkout ... `check_line` calls `import_reset` first."

**Location:** `docs/working/plan-build-loop-handoff.md:284`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed condition, the once-per-run call and the `import_reset` placement; does not establish the "global attributes" part beyond Claim 4's residue (names `hash-object --stdin-paths` re-reads).
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$POLICY" == self-merge ]]; then checkout_gate || true; fi` (`scripts/build-loop.sh:726`) is outside the per-brief loop; `import_reset  # caller contract item 4` is the first statement of `check_line` (`:657`). The bullet's condition list matches `:606-647` one for one (HEAD, repo-local GIT_*, the three core.* keys, plain index entries, clean status, nested repo/populated gitlink, bytes). Harden hides the global attributes: `core.attributesFile=/dev/null` in `harden` (`:207`) and `GIT_ATTR_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null` (`:215`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:284`, `scripts/build-loop.sh:205-215`, `scripts/build-loop.sh:603-648`, `scripts/build-loop.sh:655-657`, `scripts/build-loop.sh:720-733`

---

## Claim 3a: Header: the refusal applies when the checkout has "HEAD at another commit, a repo-local GIT_* variable set (GIT_INDEX_FILE, GIT_WORK_TREE...), core.symlinks false, core.ignoreCase or core.sparseCheckout true, an index entry marked skip-worktree, assume-unchanged or unmerged, a change git status shows (untracked files aside), an untracked nested repository or a gitlink checked out with files, or a regular file whose bytes are not main's blob"

**Location:** `scripts/build-loop.sh:112-125`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers code-vs-header correspondence of every refusal reason in `checkout_gate`; does not establish the soundness of each check (Claims 4, 7, 8).
**Legibility-target:** for-author

Every listed condition is in `checkout_gate`, and the code adds no unlisted *checkout state* except these, which the header should name or qualify:

- Not every repo-local GIT_* variable refuses: `[[ "$v" == GIT_CONFIG* || "$v" == GIT_NO_REPLACE_OBJECTS || "$v" == GIT_PREFIX || -z "${!v+set}" ]]` (`:608`) exempts `GIT_CONFIG`, `GIT_CONFIG_PARAMETERS`, `GIT_CONFIG_COUNT`, `GIT_NO_REPLACE_OBJECTS` and `GIT_PREFIX` (git 2.39.5's `--local-env-vars` lists 16 names; executed listing in this session).
- The three core.* keys also refuse when unreadable: `[[ "$rc" -le 1 && "$x" != "${r%%:*}" ]] || { CHECKOUT_WHY="${v%% *} is ${r%%:*} or unreadable ...` (`:617`).
- Unlisted refusals: `"a file on the default branch has a newline in its name"` (`:640`) and the listing failures (`:629`, `:632`, `:622`'s "or could not be listed", `:645`'s failed hash-object).

**Evidence:** `scripts/build-loop.sh:112-125`, `scripts/build-loop.sh:603-648`

---

## Claim 3b: "Untracked and ignored files are allowed."

**Location:** `scripts/build-loop.sh:124-125` (also `:599`, `test/scripts/build-loop-check.bats:1616`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers plain untracked and ignored files (status runs with `--untracked-files=no`; the others listing refuses only `/`-ended entries); does not cover untracked nested repositories, which are refused as stated in the same header.
**Legibility-target:** for-orchestrator-synthesis

`git status --porcelain=v1 -z --untracked-files=no --ignore-submodules=none` (`:623`) ignores untracked files, and the others listing counts only `/\/$/` lines (`:630`). The first U2b2 test writes `CLAUDE.local.md` (ignored via `.git/info/exclude`) and `untracked.md` and expects `cook` (ok) (`test/scripts/build-loop-check.bats:1617-1618`); it passed.

Provenance: `TMPDIR=$(mktemp -d /tmp/fcu2b2-XXXX) timeout 900 bats -j 4 test/scripts/build-loop-check.bats`, cwd the c10b972a archive copy under /tmp/fcu2b2-*, exit 0, 2026-10-09T00:42Z.

**Evidence:** `scripts/build-loop.sh:623-631`, `test/scripts/build-loop-check.bats:1614-1636`, `/tmp/fcu2b2-logs/suite-build-loop-check.txt`

---

## Claim 3c: "A review brief does not read the checkout, so a loop can run --check from its own branch."

**Location:** `scripts/build-loop.sh:125-126`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that CHECKOUT_WHY affects only `pol == self-merge` briefs and that a review brief gets `ok` from a dirty detached checkout; does not establish that other parts of `--check` (check_brief's plain-file test on the brief path) accept every loop checkout.
**Legibility-target:** for-orchestrator-synthesis

`checkout_gate` runs only when `POLICY` is self-merge (`:726`), and its result is read only under `if [[ "$pol" == self-merge && -n "$CHECKOUT_WHY" ]]` (`:668`). Test 3 stages `dirty.txt`, detaches at `HEAD~1` under a review policy and expects `cook` (`test/scripts/build-loop-check.bats:1654-1656`); it passed (same run as Claim 3b).

**Evidence:** `scripts/build-loop.sh:668`, `scripts/build-loop.sh:726`, `test/scripts/build-loop-check.bats:1653-1665`, `/tmp/fcu2b2-logs/suite-build-loop-check.txt`

---

## Claim 4: "every regular file main stores must hash, unfiltered, to main's blob, so no conversion (a filter, working-tree-encoding, ident or eol attribute from any attributes source, the user's global ones included, which harden hides from the gate's own git) changed what a session reads there."

**Location:** `scripts/build-loop.sh:594-598`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte comparison for every 100644/100755 path main stores whose name neither starts with `"` nor ends with CR, and the symlinked-file and symlinked-directory substitutions (caught by `git status`, not by the hash); does not establish files whose names `hash-object --stdin-paths` rewrites, nor anything about symlink (120000) entries, which the loop skips and `core.symlinks`/status cover.
**Legibility-target:** for-author

The mechanism holds: `--no-filters` hashes raw worktree bytes, and the result is compared with main's blob ids in ls-tree order:

```bash
# scripts/build-loop.sh:645-647
  if ! x="$(printf '%s\n' "${ps[@]}" | git hash-object --no-filters --stdin-paths 2>/dev/null)" || [[ "$x" != "$(printf '%s\n' "${ids[@]}")" ]]; then
    CHECKOUT_WHY="a file's checked-out bytes are not the default branch's blob (a filter, working-tree-encoding, ident or eol conversion)"; return 1
  fi
```

Since the comparison is of effect, the attribute's source does not matter, and harden does hide global attributes (`core.attributesFile=/dev/null`, `:207`; `GIT_ATTR_NOSYSTEM=1`, `:215`). The ident and eol=crlf tests pass (Claim 12).

Residue, executed (probe1 P4, probe2): `git hash-object --stdin-paths` C-unquotes a line that starts with `"` and drops a trailing CR, so a main file named `"q"` is hashed from `q` (`printf '"q"\n' | git hash-object --no-filters --stdin-paths` printed `q`'s hash, `8dca2f88...`, not `"q"`'s) and a file named `x\r` is hashed from `x`. Such a file's own checkout bytes are never compared; the check fails closed only when the substitute path is absent or differs. The prompt's two symlink cases are covered, but by `git status`, not by the hash (hash-object follows the link and prints the matching blob id): a regular file replaced by a symlink to identical bytes shows ` T docs/a.md`, a directory replaced by a symlink to a copy shows ` D docs/a.md` / ` D docs/b.md` (probe1 P3a, P3b).

Provenance: `timeout 60 bash .../scratchpad/fcu2b2-probe1.sh` and `fcu2b2-probe2.sh`, each in its own `mktemp -d /tmp/fcu2b2-XXXX`, exit 0, 2026-10-09T00:41Z.

**Evidence:** `scripts/build-loop.sh:603-648`, `scripts/build-loop.sh:205-215`, `/tmp/fcu2b2-logs/probe1.txt`, `/tmp/fcu2b2-logs/probe2.txt`

---

## Claim 5: "A nested repository's files are not walk starts (rows 366, 373), so an untracked one, or a gitlink checked out with any file, fails."

**Location:** `scripts/build-loop.sh:599-601`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the untracked non-bare nested repository (and a linked worktree inside the checkout) and a gitlink directory holding any entry; does not cover a nested bare repository (listed file by file, so not refused; it holds no checked-out instruction files) or a gitlink path that is itself a symlink to an empty directory (status reports it as a type change).
**Legibility-target:** for-orchestrator-synthesis

The gitlink branch: `x="$(ls -A -- "${BASH_REMATCH[3]}" 2>/dev/null)" || x=""` then `[[ -z "$x" ]] || { CHECKOUT_WHY="a gitlink is checked out with files ...` (`:636-637`). Rows 366 and 373 of docs/reviews/override-log.md are the nested-repo/submodule start-file rows, with U2b as the revisit trigger (read). The tests `git init -q nested; coref "it holds an untracked nested repository..."` (`test/scripts/build-loop-check.bats:1633`) and `mkdir sub; cook` then `echo '@../docs/x.md' > sub/CLAUDE.md` refusing (`:1662-1664`) pass.

**Evidence:** `scripts/build-loop.sh:629-638`, `docs/reviews/override-log.md:366`, `docs/reviews/override-log.md:373`, `test/scripts/build-loop-check.bats:1633`, `test/scripts/build-loop-check.bats:1660-1664`, `/tmp/fcu2b2-logs/suite-build-loop-check.txt`

---

## Claim 6: "harden's own config pairs (and the caller's, which it trusts) are not a checkout."

**Location:** `scripts/build-loop.sh:607-608`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the exemption pattern lets through; does not judge whether the caller-trust policy is right (the harden comment at `:202-204` already states it).
**Legibility-target:** for-author

The pattern `GIT_CONFIG*` exempts more than config pairs: it also lets `GIT_CONFIG` through, a file redirect that `git config` (the command the three core.* checks use, `:615`) honours instead of the repo config. Executed (probe1 P5): with `core.symlinks false` in the repo config, `git config --type=bool --get core.symlinks` printed `false`, and with `GIT_CONFIG=../alt` (a file setting it true) printed `true`. A caller exporting `GIT_CONFIG` therefore turns the three core.* refusals off; `git status` still catches the symlink case's effect (probe1 P6: a link checked out as a file shows ` T lnk`). The comment should name `GIT_CONFIG` (and `GIT_NO_REPLACE_OBJECTS`, `GIT_PREFIX`, also exempted on the same line) as trusted caller environment rather than "config pairs".

**Evidence:** `scripts/build-loop.sh:606-610`, `scripts/build-loop.sh:613-618`, `/tmp/fcu2b2-logs/probe1.txt`

---

## Claim 7: "ls-files -v tags each entry: H is plain; S is skip-worktree, lower case is assume-unchanged (git status skips both), M is unmerged."

**Location:** `scripts/build-loop.sh:619-620`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5's `-v` tags for cached entries (the only kind listed without -o/-m/-d/-k) and the fsmonitor bit under `core.fsmonitor=false`; does not cover an entry name holding a newline, which the awk counts as non-H and refuses with the "could not be listed" wording.
**Legibility-target:** for-orchestrator-synthesis

Executed (probe1 P2): `h docs/a.md` after `--assume-unchanged`, `S docs/b.md` after `--skip-worktree`, `H q` plain, and three `M docs/a.md` lines for a conflicted merge's stages. With `-c core.fsmonitor=false`, `ls-files -v` still printed `H docs/a.md` after `update-index --fsmonitor-valid` (the fsmonitor bit lowercases only under `-f`). The check is `awk 'substr($0, 1, 2) != "H " { n++ }'` (`:621`) under pipefail, with `|| n=x` on failure.

**Evidence:** `scripts/build-loop.sh:619-622`, `/tmp/fcu2b2-logs/probe1.txt`

---

## Claim 8: "Without --exclude-standard every untracked file is listed, ignored ones too, and a nested repository as its directory with a trailing / (no file name holds a /)."

**Location:** `scripts/build-loop.sh:625-627`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ignored files, a `git init` nested repository and a linked worktree (its `.git` file) inside the checkout; a nested bare repository is not printed as `dir/` but as its files, so it is not refused (stated in Claim 5's scope).
**Legibility-target:** for-orchestrator-synthesis

Executed (probe1 P1): `git ls-files -z --others` printed `CLAUDE.local.md` (excluded via info/exclude), `untracked.md`, `nested/`, `wt/` (a `git worktree add` inside the repo) and `barerepo/HEAD`, `barerepo/config`, ... file by file.

**Evidence:** `scripts/build-loop.sh:629-631`, `/tmp/fcu2b2-logs/probe1.txt`

---

## Claim 9: `import_reset  # caller contract item 4: no walk cache outlives a decision` and "Once, in this shell, before any verdict; only self-merge briefs read it."

**Location:** `scripts/build-loop.sh:657`, `scripts/build-loop.sh:725-726`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers call placement, the subshell structure and the POLICY → pol implication; does not establish item 4's "after any checkout change" half (nothing in `--check` changes the checkout, and no walk runs in `--check` before U2c, so the reset clears an empty cache today).
**Legibility-target:** for-orchestrator-synthesis

`check_line` runs in a subshell (`out="$(check_line "$a")"`, `:729`), and `import_reset` (`IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""`, `scripts/lib/dev-cycle-read.sh:603`) is its first statement (`:657`). `checkout_gate` runs in the parent shell before the loop (`:726`), so its `CHECKOUT_WHY` is inherited by every subshell. `status_line` prints `pol=self-merge` only via `[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge` (`:482`), with `POLICY` set by `read_settings` (`:721`) before `:726` reads it, so whenever a brief reads as self-merge, `checkout_gate` has run. Under `|| true` set -e is off inside it; every failing command in `:606-647` has its own `||` or `if` branch that sets CHECKOUT_WHY, so an empty CHECKOUT_WHY means it reached a success return (`:643` or the end).

**Evidence:** `scripts/build-loop.sh:466-503`, `scripts/build-loop.sh:603-648`, `scripts/build-loop.sh:655-670`, `scripts/build-loop.sh:720-733`, `scripts/lib/dev-cycle-read.sh:603`

---

## Claim 10: "The walk does not check items 2 and 3; build-loop.sh's checkout_gate does for --check (U2b2), item 3 by its effect: every regular file main stores hashes, unfiltered, to main's blob."

**Location:** `scripts/lib/dev-cycle-read.sh:55-57`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers item 2's listed environment against what `checkout_gate`, `harden` and `state_gate` check; does not establish U2c's walk timing.
**Legibility-target:** for-author

Item 2 asks for "a clean worktree at MAIN_SHA, final before the walk ... where git ls-files prints nothing on stderr ..., under the git environment the override log names (GIT_INDEX_FILE, GIT_WORK_TREE, fsmonitor, sparse checkout, core.ignoreCase, replace refs)" (`:47-51`). `checkout_gate` covers HEAD and status (`build-loop.sh:611-624`), GIT_INDEX_FILE/GIT_WORK_TREE (`:606-610`), sparse checkout (`core.sparseCheckout` plus the S bit, `:614`, `:621`) and `core.ignoreCase` (`:614`). It does not itself cover fsmonitor or replace refs; those are `harden`'s `core.fsmonitor=false core.useReplaceRefs=false` (`:207`), `GIT_NO_REPLACE_OBJECTS=1` (`:215`) and `state_gate`'s refs/replace refusal (`:245-246`). "Final before the walk" is a caller obligation the gate cannot check: it runs once before all briefs (`:726`), not immediately before U2c's walk. And "does for --check" holds only when the policy is self-merge (`:726`). Precise version: "checkout_gate (with harden and the state gate) does for a self-merge --check".

**Evidence:** `scripts/lib/dev-cycle-read.sh:43-60`, `scripts/build-loop.sh:205-215`, `scripts/build-loop.sh:230-252`, `scripts/build-loop.sh:603-648`, `scripts/build-loop.sh:726`

---

## Claim 11: "# Each index flag hides a change git status would show."

**Location:** `test/scripts/build-loop-check.bats:1622`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two fixture lines that follow the comment; does not affect the refusal assertions, which pass and are mutant-sensitive (Claim 15).
**Legibility-target:** for-author

The assume-unchanged case hides a real change: `echo c >> docs/a.md; git update-index --assume-unchanged docs/a.md; coref "$IDX"` (`:1623`). The skip-worktree case does not: the file is restored first (`git update-index --no-assume-unchanged docs/a.md; git checkout -q -- docs/a.md`, `:1624`), then `git update-index --skip-worktree docs/a.md; coref "$IDX"` (`:1625`) sets the bit on a clean file, so no change is hidden there. The statement is true of the flags in general; the fixture exercises it for one of the two.

**Evidence:** `test/scripts/build-loop-check.bats:1622-1626`

---

## Claim 12: The three U2b2 test names, and the ident test's `@docs/x$Id$` fixture ("checked-out bytes are not main's blob though git status is clean: ident and eol attributes (contract item 3, row 397, U2b2)").

**Location:** `test/scripts/build-loop-check.bats:1614`, `test/scripts/build-loop-check.bats:1638-1651`, `test/scripts/build-loop-check.bats:1653`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each test does what its name says and passes; does not establish coverage of conditions the names do not list (Claim 18).
**Legibility-target:** for-orchestrator-synthesis

The ident fixture is meaningful: the test asserts both that `$Id$` expanded and that status is clean before refusing: `grep -q 'Id: ' docs/i.md && [ -z "$(git status --porcelain)" ]` (`:1642`), and `@docs/x$Id$` is row 397's own example (docs/reviews/override-log.md:397, read). The eol=crlf half asserts a clean status too (`:1647`). Test 1's name lists HEAD, env, config, index bits, status and nested repositories, each exercised in its body (`:1619-1633`); test 3's name matches its body (`:1654-1664`). All 104 tests in the suite passed (Claim 16).

**Evidence:** `test/scripts/build-loop-check.bats:1614-1665`, `docs/reviews/override-log.md:397`, `/tmp/fcu2b2-logs/suite-build-loop-check.txt`

---

## Claim 13: Commit message: the enumerated refusal conditions, "only plain (H) index entries, since assume-unchanged and skip-worktree hide edits from git status", "(rows 366, 373)", "row 387 lists a case-insensitive checkout as an untested bypass", "check_line calls import_reset first (item 4)".

**Location:** `git log -1 c10b972a` (message body, paragraphs 1-2 and Notes)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message's condition list, row citations and the import_reset placement; the GIT_* exemptions and unreadable-config residue of Claim 3a apply equally to the message's "no repo-local GIT_* variable".
**Legibility-target:** for-orchestrator-synthesis

The condition list matches `scripts/build-loop.sh:606-647` (same correspondence as Claim 2). Row 387 reads "a case-insensitive filesystem (loop 2 iteration 1 security)" among "Untested bypass candidates" (docs/reviews/override-log.md:387); rows 366 and 373 are the nested-repo/submodule rows (Claim 5). `import_reset` is `check_line`'s first statement (`:657`).

**Evidence:** `scripts/build-loop.sh:603-670`, `docs/reviews/override-log.md:366`, `docs/reviews/override-log.md:373`, `docs/reviews/override-log.md:387`

---

## Claim 14: "It costs 0.14 s over this repo's 3,163 files."

**Location:** `git log -1 c10b972a` (message body, paragraph 2)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the file count and the byte comparison's cost on this host; does not reproduce the author's exact timing method or the full `checkout_gate` (status and listings add to it).
**Legibility-target:** for-author

The count is exact: main's `ls-tree -r` holds 3,105 `100644` and 58 `100755` entries, 3,163 regular files. A harness replaying `:632-647` (ls-tree, the bash read loop, one `hash-object --no-filters --stdin-paths`, the comparison) over the worktree's 3,163 files took 0.261 s, 0.256 s, 0.262 s (load average 0.9), about twice the stated figure; same order, figure not reproduced.

Provenance: `bash -c 'TIMEFORMAT="%R s"; time timeout 60 bash /tmp/fcu2b2-logs/timing.sh'` x3, cwd /workspace/.claude/wt-build-loop-u2b2 (read-only: no `-w`, temp dir under /tmp/fcu2b2-), exit 0, 2026-10-09T00:43Z.

**Evidence:** `scripts/build-loop.sh:632-647`, `/tmp/fcu2b2-logs/timing.txt`

---

## Claim 15: "Mutants that drop the refusal, the byte comparison or the index-bit check each turn a test red."

**Location:** `git log -1 c10b972a` (message body, paragraph 3)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one mutant per named check (the `:668` guard made `if false`, `:643` made an unconditional `return 0`, `:622` made `true ||`); does not cover mutants of the env, HEAD, core.* or nested-repo checks.
**Legibility-target:** for-orchestrator-synthesis

Results with `bats -f 'U2b2' test/scripts/build-loop-check.bats`: refusal mutant, tests 1, 2, 3 red; byte mutant, test 2 red; index-bit mutant, test 1 red.

Provenance: perl substitutions on the archive copy's scripts/build-loop.sh, `TMPDIR=$(mktemp -d /tmp/fcu2b2-XXXX) timeout 600 bats -f 'U2b2' test/scripts/build-loop-check.bats`, cwd the c10b972a archive copy, exit 1 each, 2026-10-09T00:43Z; original restored after.

**Evidence:** `scripts/build-loop.sh:622`, `scripts/build-loop.sh:643-647`, `scripts/build-loop.sh:668-670`, `/tmp/fcu2b2-logs/mut-refusal.txt`, `/tmp/fcu2b2-logs/mut-bytes.txt`, `/tmp/fcu2b2-logs/mut-indexbits.txt`

---

## Claim 16: "Suites 104/19/78/2/2; scripts/health-check.sh passed."

**Location:** `git log -1 c10b972a` (message body, paragraph 3)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers build-loop-check (104), build-loop-read (19), dev-cycle (78), fixture-git-env (2) and utility-smoke (2), the five suites with those test counts that the lib's users name or that match, and health-check, at c10b972a; does not establish which two 2-test suites the author meant (these two are the only 2-test suites under test/scripts).
**Legibility-target:** for-orchestrator-synthesis

Each suite exited 0 with all tests `ok` (104, 19, 78, 2, 2). health-check exited 0 ending "All checks passed." Checked against the logged per-suite-count hallucination pattern: the counts match.

Provenance: `TMPDIR=$(mktemp -d /tmp/fcu2b2-XXXX) timeout 900 bats -j 4 test/scripts/<suite>.bats` per suite and `timeout 590 bash scripts/health-check.sh`, cwd the c10b972a archive copy (a fresh one-commit repo), exit 0 each, 2026-10-09T00:42Z-00:45Z.

**Evidence:** `/tmp/fcu2b2-logs/suite-build-loop-check.txt`, `/tmp/fcu2b2-logs/suite-build-loop-read.txt`, `/tmp/fcu2b2-logs/suite-dev-cycle.txt`, `/tmp/fcu2b2-logs/suite-fixture-git-env.txt`, `/tmp/fcu2b2-logs/suite-utility-smoke.txt`, `/tmp/fcu2b2-logs/health.txt`

---

## Claim 17: "The refusal is per self-merge brief, not a state-gate exit, so review-policy runs are unaffected."

**Location:** `git log -1 c10b972a` (Notes (3))
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers review-policy runs and review briefs under a self-merge policy; does not cover the state gate's own refusals, which are unchanged.
**Legibility-target:** for-orchestrator-synthesis

Under a review policy `checkout_gate` is never called (`:726`), and its failure is swallowed (`checkout_gate || true`) and surfaces only as a per-brief refuse line (`:668-670`). Test 3's review-policy run from a dirty detached checkout returns ok (Claim 3c).

**Evidence:** `scripts/build-loop.sh:668-670`, `scripts/build-loop.sh:726`, `test/scripts/build-loop-check.bats:1653-1656`, `/tmp/fcu2b2-logs/suite-build-loop-check.txt`

---

## Claim 18: "Tests: three in build-loop-check.bats (each refusal; ident and eol conversions under a clean git status; a review brief in a dirty detached checkout; a populated gitlink)."

**Location:** `git log -1 c10b972a` (message body, paragraph 3)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which refusal reasons the three tests exercise; does not judge whether the untested ones need tests.
**Legibility-target:** for-author

"Each refusal" is broader than the tests. Exercised: HEAD, GIT_INDEX_FILE, the three core.* keys, assume-unchanged, skip-worktree, two status cases, the nested repo, bytes, the gitlink (`test/scripts/build-loop-check.bats:1619-1664`). Not exercised: GIT_WORK_TREE or another non-exempt GIT_* variable, an unmerged entry, an unreadable core.* value, the newline-in-name refusal (`scripts/build-loop.sh:640`) and the listing-failure refusals (`:629`, `:632`) (paraphrased — no quote available because the claim covers absence of test code: no matching lines in the three tests).

**Evidence:** `test/scripts/build-loop-check.bats:1604-1665`, `scripts/build-loop.sh:603-648`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 1** (`docs/working/known-issues-dev-cycle.md:18`): A5's "Not covered" list still names untracked nested repos and case-insensitive checkouts without noting U2b2 now refuses them for a self-merge brief.
- **Claim 3a** (`scripts/build-loop.sh:112-125`): "a repo-local GIT_* variable" exempts GIT_CONFIG*, GIT_NO_REPLACE_OBJECTS, GIT_PREFIX; core.* keys also refuse when unreadable; the newline-name and listing-failure refusals are unlisted.
- **Claim 4** (`scripts/build-loop.sh:594-598`): the byte check is sound except for names `hash-object --stdin-paths` rewrites (leading `"` is C-unquoted, trailing CR dropped), whose own bytes are never compared; the symlink substitutions are caught by git status, not the hash.
- **Claim 6** (`scripts/build-loop.sh:607`): the `GIT_CONFIG*` exemption also passes `GIT_CONFIG`, a file redirect that `git config --get` honours, so it can switch off the three core.* refusals; "config pairs" understates it.
- **Claim 10** (`scripts/lib/dev-cycle-read.sh:55-57`): fsmonitor and replace refs are harden's and the state gate's, not checkout_gate's; "final before the walk" is not checked; only for a self-merge --check.
- **Claim 11** (`test/scripts/build-loop-check.bats:1622`): the skip-worktree line sets the bit on a clean file, so no change is hidden in that case.
- **Claim 14** (commit message): 3,163 files exact; the byte comparison measured 0.26 s here, not 0.14 s.
- **Claim 18** (commit message): "each refusal" overstates the tests: GIT_WORK_TREE, unmerged, unreadable config, newline name and listing failures are untested.

### Unverifiable
(none)

---

## Goal-Alignment Note

**Success criterion (restated verbatim):** A markdown report saved to /workspace/.claude/wt-build-loop-u2b2/docs/reviews/code-fact-check-report-build-loop-u2b2.md, structured per the code-fact-check skill, with `Commit: c10b972a` as its first line and `**Replication:** k=1 (loop pass, decision 031)` in its header.

**Answered:** all nine prompt focus areas. (1) Claim 4: the effect check holds for any attributes source; it misses names that hash-object's stdin-paths rewrites, and the two symlink shapes are caught by status, not the hash. (2) Claims 3b, 8: ignored files listed, nested repo and in-tree worktree as `dir/`, a bare repo as its files. (3) Claim 7: tags confirmed on 2.39.5; the fsmonitor bit does not change `-v`'s tag. (4) Claim 3a, 3c. (5) Claim 10. (6) Claim 9. (7) Claims 14-17. (8) Claims 11-12. (9) Claims 1-2.

**Out of scope:** whether the GIT_CONFIG trust and the quoted-name residue need code changes (security critic's call); a full mutant sweep beyond the three named mutants.

**Escalate:** none blocking. Claims 4 and 6 are the two code-adjacent residues a security pass may want to weigh (a `"`-prefixed or CR-suffixed name on main; a caller-exported GIT_CONFIG).

**Questions / Decisions:** none.
