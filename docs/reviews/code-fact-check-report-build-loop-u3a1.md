# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-build-loop-u3a1`, branch `feat/build-loop-u3a1`)
**Scope:** branch diff `main...HEAD` (base d5736445): `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, and commit 65007bf8's message; lib `scripts/lib/dev-cycle-read.sh` read for context (unchanged)
**Commit:** 65007bf8
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-10
**Total claims checked:** 22
**Summary:** 17 verified, 3 mostly accurate, 2 stale, 0 incorrect, 0 unverifiable

Execution logs (all under `/tmp/claude-1000/-workspace/31623621-5136-469d-9d6b-45f6098630dc/scratchpad/u3a1-i1/fact-check/`):

| Log | Command | cwd | Exit | Started (UTC) |
|---|---|---|---|---|
| `logs/bats-new.log` | `TMPDIR=$S/tmp LC_ALL=C bats -f 're-hashes what it reads' test/scripts/build-loop-check.bats` | worktree | 0 | 2026-10-10T18:10:10Z |
| `logs/bats-read.log` | `TMPDIR=$S/tmp LC_ALL=C bats test/scripts/build-loop-read.bats` (20 tests) | worktree | 0 | 2026-10-10T18:10:11Z |
| `logs/probe-store.log` | `bash probe-store.sh` (store_check, lines 594-610 extracted, in throwaway repos) | probe's own mktemp dir | 0 | 2026-10-10T18:11:10Z |
| `logs/probe-time.log` | `bash probe-time.sh` (store_check on /workspace main d5736445, 3 runs) | /workspace (read-only cat-file) | 0 | 2026-10-10T18:11:20Z |
| `logs/probe-status.log` | `bash probe-status.sh` (--status differential, main's script vs HEAD's, 14 briefs) | probe's own mktemp dir | 0 | 2026-10-10T18:11:37Z |
| `logs/bats-check.log` | `TMPDIR=$S/tmp LC_ALL=C bats test/scripts/build-loop-check.bats` (144 tests, 144 ok) | worktree | 0 | 2026-10-10T18:11:45Z |

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): no entry resembles any claim here.

---

## Claim 1: "then main's commit, or a tree or blob of its tree, that does not hash to its id or cannot be read ("refuse state objects: WHY"; every file the gate reads from main is one)"

**Location:** `scripts/build-loop.sh:101-104`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that gate_start re-hashes main's commit and every tree and blob of main's tree, and that every file the gate reads from main's tree (settings, constraints, briefs via brief_fields/own_blob/open_shared's git grep) is a blob of that tree; does not establish coverage of main's history (check_brief's `git log -G` reads past commits and their blobs, used only for the Status-commit field --check ignores) or of the commit objects resolve_main peels before the check runs.

```bash
# scripts/build-loop.sh:822
  store_check "$MAIN_SHA" || { echo "refuse state objects: the default branch's commit or an object of its tree does not hash to its id, or could not be read"; exit 2; }
```

The reads from main all go through `git cat-file blob "$MAIN_SHA:$1"` (`scripts/lib/dev-cycle-read.sh:398`, brief_fields; `:565`, main_file; `scripts/build-loop.sh:635,637`, own_blob) or `git grep ... "$MAIN_SHA"` (`scripts/lib/dev-cycle-read.sh:509`), each a path inside main's tree. Executed: the new bats test forges main's brief blob and removes main's `f.txt` blob; both give exactly the "refuse state objects" line (`logs/bats-new.log`, ok 1). check_brief's history read: `c="$(git log -1 --format=%H --first-parent ... -G'^Status: ' "$MAIN_SHA" -- "$a")"` (`scripts/lib/dev-cycle-read.sh:458`) reads older commits, but status_fields discards that field: `read -r _ _ st _ <<<"$out"` (`scripts/build-loop.sh:512`).

**Evidence:** `scripts/build-loop.sh:818-824`, `scripts/build-loop.sh:631-638`, `scripts/lib/dev-cycle-read.sh:391-421`, `scripts/lib/dev-cycle-read.sh:423-466`, `scripts/lib/dev-cycle-read.sh:503-521`, `scripts/lib/dev-cycle-read.sh:551-569`, `logs/bats-new.log`

---

## Claim 2: "Each finding prints "refuse state WHAT: WHY" and exits 2 before the settings or any brief is read."

**Location:** `scripts/build-loop.sh:105-106`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the order state_gate → resolve_main → main_by_name → default_gate → gate_repo → store_check → reader_settings/read_settings/never_res/open_shared in --check mode, each state refusal exiting 2; does not establish that nothing reads main's commit object before store_check (resolve_main's `rev-parse --verify "$sha^{commit}"` peels it, `scripts/lib/dev-cycle-read.sh:536`), which the claim does not assert.

```bash
# scripts/build-loop.sh:336-343
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }
...
[[ "$MODE" == check ]] || reader_settings
```

```bash
# scripts/build-loop.sh:818-824
gate_start() {
  default_gate || exit 2
  GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT
  gate_repo || { echo "refuse state gate: its merge repository could not be set up"; exit 2; }
  store_check "$MAIN_SHA" || { echo "refuse state objects: ..."; exit 2; }
  reader_settings; read_settings; never_res; open_shared
}
```

Lines 344-903 are definitions only, and the check arm calls `gate_start` first (`scripts/build-loop.sh:913-914`). The old "comes after the settings and open briefs are read" exception for "refuse state gate" is now gone, matching the moved code. Executed: the forged-brief case in the new test asserts the whole output equals the single "refuse state objects" line with empty stderr (`logs/bats-new.log`).

**Evidence:** `scripts/build-loop.sh:330-343`, `scripts/build-loop.sh:818-824`, `scripts/build-loop.sh:904-924`, `logs/bats-new.log`

---

## Claim 3: refusal list no longer includes "it moved or could not be read again after --status read it" (help), and the srules/help references to the brief re-read are removed

**Location:** `scripts/build-loop.sh:116-117`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that no refusal text for the branch re-read or brief re-read remains in the script or tests; does not establish anything about docs outside `scripts/` and `test/` (plan/working docs not in the diff).

`grep -n 'moved or could not\|could not be read again'` over `scripts/*.sh scripts/lib/*.sh test/scripts/*.bats docs/*.md` returns no hit (paraphrased — no quote available because the claim covers absence of code (no matching grep results)). check_line now takes the values once: `st="${STATUS[state]}"; pol="${STATUS[policy]}"; br="${STATUS[branch]}"; sha="${STATUS[sha]}"` (`scripts/build-loop.sh:845`).

**Evidence:** `scripts/build-loop.sh:113-118`, `scripts/build-loop.sh:843-849`, `scripts/build-loop.sh:711-724`

---

## Claim 4: "Or "an object of BRANCH's tip or of its merge does not hash to its id, or could not be read": the tip's commit, or a tree or blob of its tree or of TREE (gitlinks aside), read back and re-hashed (git checks no object's hash when it reads one, so a rewritten object file would pass for the committed one)."

**Location:** `scripts/build-loop.sh:123-128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-brief store_check over the tip and the merge tree, its refusal text, and git 2.39's not re-hashing a loose object on read; does not establish coverage of the tip's ancestors or merge bases (see Claim 9) or detection of a rewrite racing after the check.

```bash
# scripts/build-loop.sh:878-879
  # The tip's objects and the merge's, re-hashed (main's were, in gate_start).
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of $br's tip or of its merge does not hash to its id, or could not be read"; return; fi
```

Executed: the test's `[ "$(git cat-file blob "$o" | grep Branch)" = "Branch: feat/y" ]` passes on git 2.39.5 (the forged blob reads back), and the forged tip file gives exactly `refuse $B: an object of feat/x's tip or of its merge does not hash to its id, or could not be read` (`logs/bats-new.log`, ok 1).

**Evidence:** `scripts/build-loop.sh:594-610`, `scripts/build-loop.sh:878-879`, `test/scripts/build-loop-check.bats:1856-1877`, `logs/bats-new.log`

---

## Claim 5: "After an ok line, a K of N refusal or a checkout refusal, one line per path TREE changes against main"

**Location:** `scripts/build-loop.sh:161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the new store_check refusal and the moved blob batch-check refusal return before any path line, and that the checkout refusal still prints path lines; does not establish behaviour of any refusal text not listed.

```bash
# scripts/build-loop.sh:874-879 (excerpt ends :879; enclosing check_line continues to :902 — read)
  if [[ ${#ids[@]} -gt 0 ]] && { ! out="$(printf '%s\n' "${ids[@]}" | gate_git cat-file --batch-check='%(objecttype)')" \
    || [[ "$(printf '%s\n' "$out" | grep -cx blob)" -ne ${#ids[@]} ]]; }; then
    echo "refuse $a: the merge of $br names a blob the object store lacks"; return
  fi
  ...
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of $br's tip or of its merge does not hash to its id, or could not be read"; return; fi
```

Both return before `co` is computed (`:887`), so their outputs are the same whether the checkout is clean or not; in the old order the blob refusal was also a single line (it returned before the rows printed), so its text and line count are unchanged for any caller. The checkout refusal path still reaches `printf '%s\n' "${rows[@]}"` (`:900-901`). Executed: the new test asserts the tip refusal is the whole output (`logs/bats-new.log`); the full check suite (144/144 ok, including its checkout-refusal and missing-blob tests) passes (`logs/bats-check.log`).

**Evidence:** `scripts/build-loop.sh:158-170`, `scripts/build-loop.sh:869-902`, `logs/bats-new.log`, `logs/bats-check.log`

---

## Claim 6: "--check refuses planted state before any git call reads an object (resolve_main does); gate_start runs the rest of its startup."

**Location:** `scripts/build-loop.sh:334-335`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that state_gate precedes resolve_main and that gate_start holds the rest of check-mode startup; does not establish that state_gate itself reads no object (pre-existing claim at `:280-281`, not re-checked).

`if [[ "$MODE" == check ]]; then state_gate || exit 2; fi` precedes `resolve_main || true` (`scripts/build-loop.sh:336-337`), and the check arm is `gate_start` then the per-brief loop (`:913-915`).

**Evidence:** `scripts/build-loop.sh:334-343`, `scripts/build-loop.sh:913-915`

---

## Claim 7: "gate_start calls it once main's objects are checked."

**Location:** `scripts/build-loop.sh:342-343`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers reader_settings' single call site in --check mode; does not establish the --status/--settings call order (unchanged).

`[[ "$MODE" == check ]] || reader_settings` (`:343`) and `store_check "$MAIN_SHA" || {...}` then `reader_settings; read_settings; never_res; open_shared` (`:822-823`).

**Evidence:** `scripts/build-loop.sh:343`, `scripts/build-loop.sh:822-823`

---

## Claim 8: "STATUS[line] is the line --status prints, and for an "ok" line STATUS holds its fields by name (state, policy, branch, loop, sha, date, dispatched, reason) and ahead ... brief_fields' BRIEF is the brief as read here ... Call it in the caller's own shell."

**Location:** `scripts/build-loop.sh:499-504`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-identity of --status lines between main's status_line and the new one over absent, new, working (ahead 0 and >0, Dispatched 5), ready, blocked, stopped REASON (with an inner double blank and comma), done, and skip lines (bad marker, bad Dispatched, no Branch, bad name, duplicate branch), and that every ok path sets all ten keys; does not establish that BRIEF reflects the brief for a `new` brief (status_fields returns before brief_fields there, so BRIEF keeps the previous brief's fields; check_line refuses a `new` brief at `:846` before read_paths, so nothing reads it), nor skip lines from fence/odd briefs (not in the fixture; same code path through check_brief).

```bash
# scripts/build-loop.sh:513-516
  if [[ "$st" == new ]]; then
    STATUS=([line]="ok $a new review - absent - - 0" [state]=new [policy]=review [branch]=- [loop]=absent [sha]=- [ahead]=0 [date]=- [dispatched]=0 [reason]="")
    return
  fi
```

```bash
# scripts/build-loop.sh:546-547
  STATUS=([line]="ok $a $st $pol $br $loop $sha $date $disp${reason:+ $reason}" [state]="$st" [policy]="$pol" [branch]="$br"
    [loop]="$loop" [sha]="$sha" [ahead]="$ahead" [date]="$date" [dispatched]="$disp" [reason]="$reason")
```

The old `reason=" ${kind#stopped }"` / `$disp$reason` equals the new `${reason:+ $reason}` because marker_kind's REASON is 1-120 printable characters (`scripts/build-loop.sh:496`), never empty. Executed: main's and HEAD's scripts print identical stdout for 14 briefs, both exit 0, no stderr (`logs/probe-status.log`: "IDENTICAL"); `build-loop-read.bats` 20/20 pass (`logs/bats-read.log`). Under `set -u`, check_line reads `STATUS[state|policy|branch|sha|loop|ahead]` only after `[[ "${STATUS[line]}" == "ok "* ]]` (`:844-848`), where every key is set. One behavioural note outside the claim: in --check, status_fields now runs in the main shell under `set -e` (previously inside `$(...)`, where bash does not inherit errexit); the same code already ran that way in --status mode (`:907`), and the check suite exercises it (Claim 22).

**Evidence:** `scripts/build-loop.sh:505-549`, `scripts/build-loop.sh:838-849`, `logs/probe-status.log`, `logs/bats-read.log`

---

## Claim 9: "store_check REV...: every object a decision reads from REV hashes to its id (rows 492, 503)."

**Location:** `scripts/build-loop.sh:585-586`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers REV itself, its root tree and every tree and blob below it; does not establish coverage of objects reached from REV through parents — the tip's parent commit (marker_kind), the commits `rev-list --count MAIN..TIP` walks (check_branch's ahead count), and the merge bases and their trees that merge-tree reads — none of which store_check reads.

The headline says "every object a decision reads from REV"; the mechanism two sentences later is narrower: "Each REV (a commit or a tree), its root tree, and every tree and blob below it" (`:588-590`), and the code lists only `"$r" "$r^{tree}"` plus `git ls-tree -r -t --full-tree ... "$r"` (`:599-600`). Decisions also read ancestors of the tip: `p="$(git rev-list --parents -n 1 "$1" ...)"` and `git rev-parse --verify "${p[1]}^{tree}"` (`scripts/build-loop.sh:478,487`, marker_kind, via status_fields `:539`); `n="$(git rev-list --count "$MAIN_SHA..$sha" ...)"` (`scripts/lib/dev-cycle-read.sh:493`, check_branch, whose ahead count check_line refuses on at `:848`); `bases="$(gate_git merge-base --all "$MAIN_SHA" "$1")"` and merge-tree over them (`scripts/build-loop.sh:617-621`). The commit message states the merge-base exclusion ("merge bases are not checked (the result the rules judge is)"), so the residue is known to the author; the comment should say "every tree and blob of REV" or name the ancestor reads as outside it.

**Evidence:** `scripts/build-loop.sh:585-610`, `scripts/build-loop.sh:471-498`, `scripts/build-loop.sh:615-625`, `scripts/lib/dev-cycle-read.sh:477-496`

---

## Claim 10: "Each REV (a commit or a tree), its root tree, and every tree and blob below it (a gitlink names another repository's commit) are read in one cat-file --batch and re-hashed by one perl, for sha1 or sha256."

**Location:** `scripts/build-loop.sh:588-591`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the object list (REV, REV^{tree}, ls-tree -r -t entries minus gitlinks, deduplicated), the single cat-file/perl pipeline, and both hash formats with REV as a commit and as a tree; does not establish detection of a rewritten object inside a pack (not forged in a probe; the packed store's clean pass is executed, and detection reads cat-file's inflated content, which is storage-independent).

```bash
# scripts/build-loop.sh:598-601
  { for r in "$@"; do
      printf '%s\n' "$r" "$r^{tree}"
      git ls-tree -r -t --full-tree --format='%(objecttype) %(objectname)' "$r" | awk '$1 != "commit" { print $2 }' || exit 1
    done; } | awk '!seen[$0]++' | git cat-file --batch \
```

Executed (`logs/probe-store.log`): a clean sha1 repo and a clean sha256 repo return rc=0; a tree holding a gitlink to `1111…` (absent from the store) returns rc=0; commit plus tree arguments return rc=0. The bats test's `git repack -adq` case passes (`logs/bats-new.log`). `ls-tree -r -t` omits the root tree, which `"$r^{tree}"` supplies.

**Evidence:** `scripts/build-loop.sh:594-610`, `logs/probe-store.log`, `logs/bats-new.log`

---

## Claim 11: "Returns 1 on a mismatch, a missing object or a failed read."

**Location:** `scripts/build-loop.sh:591-592`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a forged blob, a missing blob, a missing subtree (ls-tree fails inside the `{ ...; }` group), a missing REV, and the group's `exit 1` under `set -o pipefail`; does not establish that the status is exactly 1 in every failure (if cat-file died while perl had read only whole records, the pipeline returns cat-file's own non-zero status; both callers test only zero vs non-zero), nor that git's stderr on a missing object is silent (it is not: "error: Could not read …" reaches stderr).

The `{ ...; }` group is a pipeline element, so it runs in a subshell and `exit 1` ends only that subshell; with pipefail the function's status is the rightmost non-zero element. Executed (`logs/probe-store.log`): missing subtree `d/e` → rc=1 (with git's "error: Could not read a1dffc7a…" on stderr); missing commit id → rc=1; the isolated construct `{ for r in 1; do false | cat || exit 1; done; } | cat` under `set -euo pipefail` → rc=1. The forged blob (main's brief) and a removed blob both refuse in the bats test (`logs/bats-new.log`). Perl: `my ($id, $t, $s) = $h =~ /^([0-9a-f]+) ([a-z]+) ([0-9]+)\n\z/ or exit 1;  # "NAME missing" too` (`:604`). Both callers are in conditions (`:822`, `:879`), so `set -e` does not fire inside.

**Evidence:** `scripts/build-loop.sh:594-610`, `scripts/build-loop.sh:822`, `scripts/build-loop.sh:879`, `logs/probe-store.log`, `logs/bats-new.log`

---

## Claim 12: "main's copy with its first Status: line outside a fence, the one brief_fields reads (status_line has read it as "Status: open")"

**Location:** `scripts/build-loop.sh:627-628`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which function reads the brief before own_blob in --check; does not establish anything about own_blob's hashing (unchanged).

own_blob runs only from nrules inside check_line, which now calls `status_fields "$a"` (`scripts/build-loop.sh:843`); `status_line` is the --status printer only: `status_line() { status_fields "$1"; echo "${STATUS[line]}"; }` (`:549`), called at `:907`. The comment should name status_fields.

**Evidence:** `scripts/build-loop.sh:549`, `scripts/build-loop.sh:626-638`, `scripts/build-loop.sh:843`

---

## Claim 13: "$5 the checkout's refusal, if any."

**Location:** `scripts/build-loop.sh:705`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers srules' fifth argument's only source; does not establish the floor's own behaviour.

`co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run ..."; fi` (`:887`) is co's only assignment, passed as `srules "$stem" "$p" "${lps[$i]}" "${ss[$i]}" "$co"` (`:897`); the unread arm `[[ "$PATHS_WHY" != unread ]]` is gone from srules (`:711-724`).

**Evidence:** `scripts/build-loop.sh:702-724`, `scripts/build-loop.sh:887-897`

---

## Claim 14: "The gate's startup once the top level has run state_gate, resolve_main and main_by_name, in this order, each refusal a "refuse state" line and exit 2 before any setting or brief is read: the default branch unambiguous (default_gate); the gate's merge repository (GATE_TMP, removed at exit); main's commit and tree re-hashed (store_check); then the reader lists both walks take, --settings' values, the never globs and the open briefs (once, in this shell)."

**Location:** `scripts/build-loop.sh:809-815`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers gate_start's step order, its three refusals' form and exit 2, and the trap; does not establish that "each refusal" covers main_by_name's failure (that one is a stderr message and exit 1, `:338`) or mktemp's failure (exit 1, no line), which the sentence's natural reading attaches to gate_start's own list only.

`default_gate || exit 2` (default_gate prints "refuse state default-branch: …", `:322,326`); `gate_repo || { echo "refuse state gate: …"; exit 2; }`; `store_check "$MAIN_SHA" || { echo "refuse state objects: …"; exit 2; }`; `reader_settings; read_settings; never_res; open_shared` (`:819-823`).

**Evidence:** `scripts/build-loop.sh:319-329`, `scripts/build-loop.sh:818-824`

---

## Claim 15: "The repository rule: main's files and refs, the branch tips and the checkout are read in the real repository; the merge computations (merge-base, merge-tree, diff-tree, the blob checks) run through gate_git."

**Location:** `scripts/build-loop.sh:815-817`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every git call in check_line, merge_result, own_blob, checkout_gate and store_check; does not establish whether running store_check in the real repository changes anything it reads (cat-file --batch applies no filter or textconv, and both repositories read the same object directory), only that the stated rule does not place it.

The merge computations are as stated: `gate_git merge-base --all` and `gate_git merge-tree` (`:617,621`), `gate_git diff-tree` (`:858`), `gate_git cat-file --batch-check` (`:874`), `gate_git hash-object` (`:637`). But the new per-brief re-hash of the merge's result tree runs in the real repository, not through gate_git: store_check uses bare `git ls-tree` and `git cat-file --batch` (`:600-601`) and is called as `store_check "$sha" "$tree"` (`:879`), where `$tree` is merge-tree's output — an object of the merge computation, read neither as "main's files" nor as a "branch tip". The rule should name store_check's reads (main's tree, the tip and TREE) as real-repository reads.

**Evidence:** `scripts/build-loop.sh:579-584`, `scripts/build-loop.sh:594-625`, `scripts/build-loop.sh:631-638`, `scripts/build-loop.sh:856-879`

---

## Claim 16: "or one skip or refuse line (from status_line, then the gate's own reasons)"

**Location:** `scripts/build-loop.sh:829-830`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which function supplies check_line's skip/refuse lines; does not establish anything about the lines' text (Claim 8).

check_line now prints `"${STATUS[line]}"` set by `status_fields "$a"` (`scripts/build-loop.sh:843-844`); status_line is not called from check_line. The comment should name status_fields.

**Evidence:** `scripts/build-loop.sh:825-844`

---

## Claim 17: "each helper empties its own globals before use (DENY, PATHS and PATHS_WHY, LIST, LIST_WHY and LIST_BAD, STATUS, BRIEF, CHECKOUT_WHY, FLOOR_WHY, TRUTH_WHY)"

**Location:** `scripts/build-loop.sh:834-837`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the newly listed STATUS; does not re-check the pre-existing entries (FLOOR_WHY, TRUTH_WHY live in the lib/floor, not read here).

`STATUS=()` is status_fields' first statement after its locals (`scripts/build-loop.sh:508`), and every return path either assigns `STATUS[line]` or the whole array.

**Evidence:** `scripts/build-loop.sh:506-548`

---

## Claim 18: "The S rules' inputs: the brief as status_fields read it from main's commit."

**Location:** `scripts/build-loop.sh:888-890`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the global BRIEF still holds this brief's fields when read_paths runs; does not establish BRIEF's content after read_paths (the floor walk below may or may not call brief_fields; PATHS is already set by then).

Between status_fields' `brief_fields "$a"` (`:517`) and `read_paths` (`:890`), nothing in the caller's shell writes BRIEF: check_brief and check_branch and marker_kind run in `$(...)` subshells (`:510`, `:531`, `:539`); open_shared declares `local -A count=() BRIEF=()  # a local BRIEF: the caller's stays as it was` (`scripts/lib/dev-cycle-read.sh:505`) and is called before brief_fields anyway (`:509`); merge_result runs in `$(...)` (`:850`); gate_git, store_check and checkout_gate do not call brief_fields (paraphrased — no quote available because the claim covers absence of code: `grep -n brief_fields` over `:551-808` and `:838-890` hits nothing). Only `pol=self-merge` reaches read_paths, which requires an open brief past brief_fields.

**Evidence:** `scripts/build-loop.sh:506-548`, `scripts/build-loop.sh:838-890`, `scripts/lib/dev-cycle-read.sh:503-521`, `scripts/build-loop.sh:680-685`

---

## Claim 19: test comment "git reads the forged bytes as the brief's (cat-file checks no hash); the gate refuses before reading it."

**Location:** `test/scripts/build-loop-check.bats:1860`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 reading a forged loose blob back and the gate refusing with the state line and empty stderr; does not establish behaviour on other git versions.

```bash
# test/scripts/build-loop-check.bats:1862-1865
    [ "$(git cat-file blob "$o" | grep Branch)" = "Branch: feat/y" ] || { echo "the forged blob does not read back"; return 1; }
    chk "$B"
    [ "$status" -eq 2 ] && [ "$output" = "refuse state objects: the default branch's commit or an object of its tree does not hash to its id, or could not be read" ] \
        && [ -z "$stderr" ] || { show; return 1; }
```

Passed (`logs/bats-new.log`, exit 0, `git version 2.39.5`).

**Evidence:** `test/scripts/build-loop-check.bats:1851-1877`, `logs/bats-new.log`

---

## Claim 20: commit 65007bf8: "store_check checks whole trees (0.3 s for main here) rather than each read"

**Location:** commit 65007bf8 message (body, "Notes:")
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers store_check's wall time on /workspace main d5736445 (3,691 tree entries) on this machine today; does not establish the time under other load or for the per-brief tip/merge calls.

Executed (`logs/probe-time.log`): three runs of `store_check d5736445…` from `/workspace`, each `real 0.236` s, at load average 6.2. That is within the stated 0.3 s order (the plan's own figure, `docs/working/plan-build-loop-handoff.md:317`, "3,691 objects, 68 MB here: 0.3 s"); timing on a shared machine is noisy, hence Medium.

**Evidence:** `scripts/build-loop.sh:594-610`, `logs/probe-time.log`

---

## Claim 21: commit 65007bf8: "the branch and brief re-reads and their two untested refusals go (row 625)"; rows 492, 503, 496, 512, 525 cited

**Location:** commit 65007bf8 message (body, paragraph 2)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the override-log rows cited and whether the two removed refusals were tested on main; does not establish whether the rows have been marked resolved (not in this diff).

Neither "moved or could not be read again" nor "could not be read again from the default branch" appears in main's tests (`git grep ... main -- test/` returns nothing; paraphrased — no quote available because the claim covers absence of code). Rows 492, 503 (re-hash), 496 (`a status_fields array with status_line as its printer`), 512 (values for --merge) and 525 (one startup function, the repository rule) match their citations (`docs/reviews/override-log.md:492,496,503,512,525`). Row 625, though, names only the brief re-read: "No suite test runs the failed brief re-read branch (`scripts/build-loop.sh` check_line, srules' unread arm)" (`docs/reviews/override-log.md:625`); the branch re-read's untested refusal has no row cited. Precise version: "(row 625 for the brief's; the branch's was untested too)".

**Evidence:** `docs/reviews/override-log.md:492`, `docs/reviews/override-log.md:496`, `docs/reviews/override-log.md:503`, `docs/reviews/override-log.md:512`, `docs/reviews/override-log.md:525`, `docs/reviews/override-log.md:625`

---

## Claim 22: commit 65007bf8: "probed: a forged brief blob read back as naming another branch"; "merge bases are not checked (the result the rules judge is)"

**Location:** commit 65007bf8 message (body, paragraphs 1 and Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the forged-blob read-back (executed in the new test) and that store_check takes no merge base (static); does not establish that the full check suite passes (see note below).

The test forges main's brief to `Branch: feat/y` and asserts git reads it back (`test/scripts/build-loop-check.bats:1861-1862`, passed in `logs/bats-new.log`). store_check is called only with `"$MAIN_SHA"` and `"$sha" "$tree"` (`scripts/build-loop.sh:822,879`); merge_result's `$bases` (`:617`) never reach it.

Note on the full suite (`logs/bats-check.log`): `TMPDIR=$S/tmp LC_ALL=C bats test/scripts/build-loop-check.bats`, cwd the worktree, started 2026-10-10T18:11:45Z, exit 0, 144 of 144 ok (`1..144`, no `not ok`) — this covers the checkout-refusal, blob-refusal, self-merge Paths: and status-under-check tests that Claims 5, 8 and 18 lean on.

**Evidence:** `test/scripts/build-loop-check.bats:1856-1877`, `scripts/build-loop.sh:615-625`, `scripts/build-loop.sh:822`, `scripts/build-loop.sh:879`, `logs/bats-new.log`, `logs/bats-check.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 12** (`scripts/build-loop.sh:627-628`): own_blob's comment says status_line read the brief; in --check it is status_fields.
- **Claim 16** (`scripts/build-loop.sh:829-830`): check_line's header says its skip/refuse lines come "from status_line"; they come from status_fields' STATUS[line].

### Mostly Accurate
- **Claim 9** (`scripts/build-loop.sh:585-586`): "every object a decision reads from REV" overclaims; the tip's parent commit (marker_kind), the ancestors check_branch counts, and merge bases are read but not re-hashed — say "REV, its tree and every tree and blob below it".
- **Claim 15** (`scripts/build-loop.sh:815-817`): the repository rule omits store_check, which reads the tip and the merge's TREE in the real repository rather than through gate_git.
- **Claim 21** (commit 65007bf8 message): row 625 covers only the brief re-read's untested refusal; the branch re-read's was untested too but has no cited row.

### Unverifiable
(none)

---

## Goal-Alignment Note

**Success criterion (restated verbatim):** "a markdown report saved at the path your dispatch names, structured per your skill."
**Answered:** Yes — saved at `docs/reviews/code-fact-check-report-build-loop-u3a1.md` with the dispatch's Commit and Replication header lines; all six brief focus areas verdicted (store_check coverage and failure paths: Claims 9-11; help-text order and "every file": 1-2; status byte-identity and set -u: 8; BRIEF persistence and lost re-read guarantees: 3, 18, 21; refusal order: 5; commit-message claims: 20-22).
**Out of scope:** code-quality or security judgments on whether the uncovered ancestor reads (Claim 9) matter for a decision — that is the security/architecture critics' call; the plan doc's "at the start of each check_line" wording (`docs/working/plan-build-loop-handoff.md:317`, not in the diff) differs from the as-built once-at-startup check.
**Escalate:** None blocking. Legibility targets: Claims 9, 12, 15, 16, 21 → for-author; Claims 1-8, 10, 11, 13, 14, 17-20, 22 → for-orchestrator-synthesis.
