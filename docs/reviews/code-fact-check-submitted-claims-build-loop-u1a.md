Commit: 722884c7

# Code Fact-Check Report

**Repository:** claude-workflows (`/workspace/.claude/wt-build-loop-u1a`, branch `feat/build-loop-u1a`, HEAD 722884c7, base `main` f6357ea1 = merge-base)
**Scope:** Stage-2.5 submitted-claims pass only (iteration 3, final confirming pass): the eight critic endorsements in the review's `submitted/claims.md` (Claims 56-63), checked against `scripts/lib/dev-cycle-read.sh` and `test/scripts/dev-cycle.bats` at 722884c7, with 2da477b7 materialised for comparison. No harvested claims (numbering continues the main report's).
**Checked:** 2026-10-05
**Total claims checked:** 11 (8 submitted claims; Claim 60 split into 60a/60b and Claim 62 into 62a/62b/62c on verdict divergence)
**Summary:** 8 verified, 3 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) first. No claim below matches a logged pattern. Claim 62a misses a numeric bound by about a point, which is not a fabricated count.

Environment for every executed claim: Linux (WSL2), GNU bash 5.2.15, git 2.39.5, `awk` = mawk 1.3.4 20200120 (gawk is not installed), `LC_ALL=C.UTF-8`. Captured output is in the scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i3/submitted/` (abbreviated `$S` below), not in the repo: this pass may write no repo file other than this report. Every probe repo was built with `git init` inside `$S`. The worktree's repo was only read. 2da477b7's and 722884c7's `scripts/` were extracted with `git archive <rev> scripts | tar -x -C $S/perf/{old,new}`.

Full bats run: `TMPDIR=$S/bats bats test/scripts/dev-cycle.bats`, cwd `/workspace/.claude/wt-build-loop-u1a`, started 2026-10-05T11:51:59Z, exit 1. 66 of 67 tests pass. The one failure is test 21, the known failure under a TMPDIR with a `.`-leading component, which the orchestrator said to ignore. Output: `$S/bats/bats-full.out`.

---

## Submitted Claims

## Claim 56: "At 722884c7, main_entry answers `error` for every duplicate-entry tree probed (leaf and parent directories, symlink/regular in both orders, two regular, 100644+100755, `working` as symlink/tree both orders and two trees, a `working/questions.md` entry name inside docs colliding with the real path), and both callers (check_brief, check_answer) turn `error` into a skip."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:264-269`, `scripts/lib/dev-cycle-read.sh:335`, `scripts/lib/dev-cycle-read.sh:555`
**Type:** Invariant / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every duplicate shape the claim lists, rebuilt as raw tree objects (`hash-object -t tree --literally`, entry order kept as written), for `docs/working/questions.md` and a brief path, plus a two-`docs` top-level duplicate: each gives `main_entry` = `error`, `check_answer` → `skip … the default branch's tree could not be read`, and `check_brief` → `skip … the default branch's tree could not be read`. It does not establish four things. (1) A slash-named entry with no colliding real path is not caught: a `docs` tree holding only an entry named `working/questions.md` makes `main_entry` answer `absent`, while `git ls-tree`/`git cat-file` resolve that path to a blob, so check_answer reports "no such entry" and check_brief reports `ok … new`. This is not a duplicate and is fsck-invalid, but it is a tree shape git can read and main_entry calls absent. (2) Duplicates in `questions-archive.md`'s own leaf entry were not probed; only the shared parents were. (3) Case-variant or Unicode-variant names were not probed. (4) git versions other than 2.39.5 were not tested.

The duplicate check sits in the one loop over ls-tree's output:

```bash
# scripts/lib/dev-cycle-read.sh:264-269
  while IFS=$'\t' read -r mode path; do
    [[ -n "$path" ]] || continue
    [[ -z "${m[$path]+set}" ]] || dup=1
    m["$path"]="${mode%% *}"
  done <<<"$out"
  [[ -z "$dup" ]] || { echo error; return; }
```
(excerpt ends :269; enclosing main_entry() continues to :274 — read)

Both callers map `error` to a skip and return: `error) echo "skip $a: the default branch's tree could not be read"; return ;;` (`scripts/lib/dev-cycle-read.sh:335`, check_brief) and `error) echo "skip $a: the default branch's tree could not be read, so $f is not read"; return ;;` (`scripts/lib/dev-cycle-read.sh:555`, check_answer).

Probe: `./probe.sh $S/dup/repo` (cwd `$S/dup`, `TMPDIR=$S/dup`), started 2026-10-05T11:50:47Z, exit 0. For each tree it prints ls-tree, both `main_entry` answers, and the `--check-answer Q-1` and `--check-brief` lines. Results: the control (no duplicate) gives `blob`/`keep Q-1`/`ok … open`. Every listed duplicate shape gives `error` and both skips. Brief-leaf duplicates give `error` for the brief and leave questions.md's `blob` untouched. The residue case "slash-name entry only (no working tree)" gives `absent`, and a separate run (same cwd, 11:50 UTC) confirmed `git cat-file -t main:docs/working/questions.md` → `blob`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `scripts/lib/dev-cycle-read.sh:330-337`, `scripts/lib/dev-cycle-read.sh:549-557`, `$S/dup/probe.sh`, `$S/dup/probe.out`

---

## Claim 57: "Under `set -euo pipefail`, a blob that main_entry calls `blob` but cat-file cannot read is a skip in check_answer (no fall-through to the archive) and `BRIEF_ODD=error`, rc 1, in brief_fields."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:295-302`, `scripts/lib/dev-cycle-read.sh:559-560`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two failure modes under `set -euo pipefail`: a deleted loose object and a truncated (corrupt zlib) loose object, for questions.md (archive holds a conflicting ANSWERED entry) and a brief. In each, check_answer prints `skip Q-1: docs/working/questions.md could not be read from the default branch`, brief_fields returns 1 with no keys and `BRIEF_ODD=error`, and check_brief prints `skip … the brief could not be read from the default branch`. It does not establish four things: behaviour when the caller has not set `pipefail` (the `||` then sees only awk's status); a failure in a packed object; a read that fails only after awk has consumed a valid prefix whose answer it would print; or that git's own `fatal:` stderr line reaches the user scrubbed. Those lines go to the caller's stderr as written.

The read and its failure branch:

```bash
# scripts/lib/dev-cycle-read.sh:558-560
    # A failed read is a skip, never a fall-through to the other file.
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
      || { echo "skip $a: $f could not be read from the default branch"; return; }
```
(excerpt ends :560; enclosing check_answer() continues to :573 — read)

In brief_fields the pipeline closes with `')" \` and `|| { BRIEF_ODD=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:301-302`), after `BRIEF=(); BRIEF_ODD=""` at `:291`, so no key is set.

Probe: `./probe.sh $S/unread/repo-<mode> <mode>` for mode `delete` and `corrupt` (cwd `$S/unread`, `TMPDIR=$S/unread`), started 2026-10-05T11:51:19Z, exit 0 for both. In both modes, `main_entry` = `blob / blob`, then `check_answer: skip Q-1: docs/working/questions.md could not be read from the default branch`, `brief_fields rc=1 keys=0 odd=[error]`, `check_brief: skip … the brief could not be read from the default branch`, and the script reached its last line. Bats test 67 ("an unreadable blob … is a skip") passed in the full run.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `scripts/lib/dev-cycle-read.sh:545-573`, `$S/unread/probe.sh`, `$S/unread/probe.out`, `$S/bats/bats-full.out`

---

## Claim 58: "check_answer opens no working-tree path: its only reads are `main_entry "$f"` and `git cat-file blob "$MAIN_SHA:$f"`, with `f` from a two-element constant list." (scope excludes refs/replace substitution)

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:549-560`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer and the helpers it calls (`main_by_name`, `main_entry`, `oddwhy`). Their only external reads are `git ls-tree … "$MAIN_SHA"` and `git cat-file blob "$MAIN_SHA:$f"`, with `f` drawn from the literal list. Executed: answers are unchanged and nothing blocks when both working-tree questions files are FIFOs under a `chmod 000` `docs/`, run from the top level and from a subdirectory. It does not establish what git itself reads to find the repository: `.git` discovery in the cwd and its parents, config, `GIT_DIR`/`GIT_*` environment overrides, alternates, and the excluded `refs/replace`. It also does not establish working-tree reads by other functions the same process runs, such as dev-cycle.sh's own setup.

The loop's list and its two git reads:

```bash
# scripts/lib/dev-cycle-read.sh:549-550
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
```
(excerpt ends :550; enclosing check_answer() continues to :573 — read)

The read itself is `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk …)"` (`scripts/lib/dev-cycle-read.sh:559`). main_entry's only external command is `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)"` (`scripts/lib/dev-cycle-read.sh:263`). The rest of check_answer (`:561-572`) is shell string tests and `echo`s on `$r` (paraphrased — no quote available because the claim covers the absence of any other read, i.e. no file operand or redirection from a path in those lines, which a 12-line quote would only restate).

Probe: `./probe.sh $S/nowt/repo` (cwd `$S/nowt`, `TMPDIR=$S/nowt`), started 2026-10-05T11:57:10Z, exit 0, with a 20 s `timeout` around each run that would have fired on a FIFO open. The output was `drop Q-1`, `keep Q-2`, `skip Q-3: no such entry …` from both `.` and `sub/`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:246`, `scripts/lib/dev-cycle-read.sh:258-274`, `scripts/lib/dev-cycle-read.sh:545-573`, `$S/nowt/probe.sh`, `$S/nowt/probe.out`

---

## Claim 59: "brief_fields owns its preconditions: with no default branch by name, an empty MAIN_SHA, a path pathform refuses, or any main_entry answer but blob, it returns 1 with BRIEF_ODD=error and sets no key."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:289-310`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 17 refused cases, each started with `BRIEF` and `BRIEF_ODD` pre-set: no resolve_main (empty MAIN_SHA); MAIN_BY_NAME=1 with an empty MAIN_SHA; the current-branch fallback (MAIN_BY_NAME empty); eight pathform-refused paths (`../`, leading `/`, leading `-`, `.git/`, `./` component, a space, the empty string, `.GIT`); `absent`; `notfile` (a symlink, a tree); `notdir` (a symlinked directory, a file used as a directory); and `error` (a bad MAIN_SHA). Each returns 1 with `keys=0` and `BRIEF_ODD=[error]`. The control case returns 0. It does not establish four things. brief_fields does not check that the path is a brief (`isbrief`): any pathform-valid blob, such as `x.md`, is parsed. A MAIN_SHA set by hand to a non-default commit with MAIN_BY_NAME=1 is not detected. A caller that calls it bare under `set -e`, outside `if` or `||`, exits on the return 1. The unreadable-blob precondition is covered by Claim 57, not this one.

The guard is the function's first statement after the reset:

```bash
# scripts/lib/dev-cycle-read.sh:290-292
  local out l
  BRIEF=(); BRIEF_ODD=""
  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
```
(excerpt ends :292; enclosing brief_fields() continues to :310 — read)

An empty MAIN_SHA or a missing MAIN_BY_NAME reaches `error` through `main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`scripts/lib/dev-cycle-read.sh:246`) and `main_by_name || { echo error; return; }` (`:261`).

Probe: `./probe.sh $S/pre/repo` (cwd `$S/pre`, `TMPDIR=$S/pre`), started 2026-10-05T11:57:10Z, exit 0. All 17 refused cases printed `rc=1 keys=0 odd=[error]`, and the control printed `rc=0 keys=2 odd=[] status=[Status: open]`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:140-149`, `scripts/lib/dev-cycle-read.sh:246`, `scripts/lib/dev-cycle-read.sh:258-274`, `scripts/lib/dev-cycle-read.sh:289-310`, `$S/pre/probe.sh`, `$S/pre/probe.out`

---

## Claim 60a: "check_brief reads a brief only through brief_fields (one brief parser)"

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:338-349`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_brief's parsed values. The Status value is taken only from `BRIEF[status]` after `brief_fields`, and check_brief has no awk or cat-file of its own. It does not establish that brief_fields is the only reader of the brief's content. The commit field comes from `git log -G'^Status: '` over the brief's history, which matches any added or removed `Status: ` line, fenced lines included and outside FENCE_AWK. The precise wording is "check_brief takes every parsed value from brief_fields; only its commit lookup matches brief text separately (git log -G)".

The value path holds:

```bash
# scripts/lib/dev-cycle-read.sh:338, :346-347
  if ! brief_fields "$a"; then
  st="${BRIEF[status]-}"
  if [[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]; then
```
(excerpt ends :347; enclosing check_brief() continues to :358 — read)

But the same function then matches the brief's text a second way:

```bash
# scripts/lib/dev-cycle-read.sh:354-356
  # counts (a quoted one, or a move into closed/, which adds the file whole).
  c="$(git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a")"
  [[ -n "$c" ]] || c="$(git log -1 --format=%H "$MAIN_SHA" -- "$a")"
```
(excerpt ends :356; enclosing check_brief() continues to :358 — read)

The comment at `:354` documents this ("Any such line counts (a quoted one …)"), so the behaviour is intended. Only the claim's "only" is too broad.

Probe: `./probe.sh $S/onepar/repo` (cwd `$S/onepar`, `TMPDIR=$S/onepar`), started 2026-10-05T11:57:10Z, exit 0. One commit lands a brief with `Status: open`, and a later commit appends a fenced `Status: done`. brief_fields gives `status=[Status: open]`, and check_brief prints `ok … open <fenced-quote commit>`, not the landing commit.

**Legibility-target:** for-author

**Evidence:** `scripts/lib/dev-cycle-read.sh:319-358`, `$S/onepar/probe.sh`, `$S/onepar/probe.out`

---

## Claim 60b: "its output agrees with brief_fields on the template-shaped fixture" (T31 tests)

**Submitted by:** architecture-review
**Location:** `test/scripts/dev-cycle.bats` ("a brief shaped like the skill's template parses: check_brief and brief_fields agree (T31)", "brief_fields reads each machine line's first unfenced copy from main in one pass; check_brief agrees (T31)")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two T31 fixtures: the template-shaped brief, with a fenced `Status: done` under Out of scope, and the multi-key brief, with a fenced block, a CRLF Status line, and later duplicate keys. On both, `brief_fields` gives `Status: open` and check_brief prints `ok <path> open …`. It does not establish agreement on briefs outside these fixtures, or under gawk. It also does not establish that the U1b/U1c consumers will read BRIEF[] the way check_brief does.

The template test asserts `[ "${lines[0]}" = "[Status: open] [unset]" ] && [[ "${lines[1]}" == "ok $b open "* ]]`. The second test asserts `status=[Status: open]` … `[[ "${lines[6]}" == "ok $b open "* ]]` (quoted from the diff hunk at `test/scripts/dev-cycle.bats`, tests 65 and 66 of the run).

Run: the full bats command in the header (exit 1 from test 21 only). The output shows `ok 65 a brief shaped like the skill's template parses: check_brief and brief_fields agree (T31)` and `ok 66 brief_fields reads each machine line's first unfenced copy from main in one pass; check_brief agrees (T31)`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `test/scripts/dev-cycle.bats:1195-1243`, `$S/bats/bats-full.out`

---

## Claim 61: "check_answer no longer calls need_root or skipped (no ROOT_REAL dependency, SKIPPED untouched)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:539-573`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer and its callees (`main_by_name`, `main_entry`, `oddwhy`, the awk programs). None calls `need_root` or `skipped` or reads `ROOT_REAL`/`SKIPPED`. Bats test 63 runs check_answer with ROOT_REAL unset and from a subdirectory, with `skipped=0`, and the Claim 58 probe also ran it without ROOT_REAL from `sub/`. It does not establish that dev-cycle.sh's `--check-answer` path no longer requires a root. The script still cds and sets ROOT_REAL itself, and that was not re-read for this claim. It also does not establish that a future build-loop.sh caller could drop its own root setup.

A text search of the three functions' bodies for `need_root|skipped|ROOT_REAL|SKIPPED` returned nothing (paraphrased — no quote available because the claim covers the absence of code: `awk '/^check_answer\(\)|^main_entry\(\)|^main_by_name\(\)/,/^}/' scripts/lib/dev-cycle-read.sh | grep -n 'need_root\|skipped\|ROOT_REAL\|SKIPPED'` printed no lines). The function's own comment says so: `# … It reads only git objects,` / `# so it needs no ROOT_REAL and adds nothing to SKIPPED.` (`scripts/lib/dev-cycle-read.sh:543-544`). The 2da477b7→main diff removed `if skipped "$f"; then …` and `[[ -f "$f" ]] || continue` (the `-` lines of the diff's check_answer hunk).

Run: the full bats run (header) shows `ok 63 check_answer reads git only: no ROOT_REAL needed, SKIPPED untouched, skip without main by name`.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:539-573`, `scripts/lib/dev-cycle-read.sh:246-274`, `$S/bats/bats-full.out`, `$S/nowt/probe.out`

---

## Claim 62a: "On this repo's main (f6357ea1), check_answer over 20 archived IDs runs within 5% of 2da477b7's wall clock"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:545-573`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 20 archived IDs (Q-001 to Q-010, Q-012 to Q-018 but not Q-011 or Q-019, and Q-020 to Q-022, as listed in bench.sh) on main f6357ea1, on this machine, measured two ways with alternating order. At the script level, `dev-cycle.sh --check-answer`, 4×15 and 8×20 runs: the median is 5.2% and 6.7% slower and the minimum 6.5% and 5.7% slower. At the function level, `check_answer` sourced in-process, 8×100 calls: the median is 5.5% slower and the minimum 6.5% slower. A same-code A/A run gave a median of −2.2% and a minimum of −1.5%. The overhead is small, about 12 ms per 20-ID call, but it sits consistently just above the claimed 5%, not within it. It does not establish the cause of the slowdown: the 2da477b7→722884c7 lib diff adds no process (Claim 63), and the gap was not isolated. It also does not establish timing on another machine or under gawk.

The only code difference on this path is main_entry's duplicate check and `2>/dev/null` (`scripts/lib/dev-cycle-read.sh:263-269`, quoted under Claim 56) and the `|| { echo "skip …"; return; }` on the read (`:559-560`, quoted under Claim 57).

Runs (cwd `$S/perf`, `TMPDIR=$S/perf/tmp`, exit 0 for each): `./bench.sh $S/perf 15`, 2026-10-05T11:53:16Z → `bench.out`. `./bench.sh $S/perf 20 8`, 11:53:54Z → `bench2.out`. `./micro.sh $S/perf`, 11:55:34Z → `micro.out`. The A/A run `./micro.sh $S/perf/aa`, 11:56:03Z → `micro-aa.out`. The ratios were computed with python3 (`statistics.mean/median`, `min`).

**Legibility-target:** for-author

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `scripts/lib/dev-cycle-read.sh:545-573`, `$S/perf/bench.sh`, `$S/perf/bench.out`, `$S/perf/bench2.out`, `$S/perf/micro.sh`, `$S/perf/micro.out`, `$S/perf/micro-aa.out`

---

## Claim 62b: "with byte-identical output"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:545-573`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `dev-cycle.sh --check-answer` over the 20 IDs on main f6357ea1: 2da477b7's and 722884c7's outputs are byte-identical (`cmp`, 20 lines, all `unrecognized Q-NNN`, since archived entries are not keep-or-drop answers). It does not establish identical output for IDs that resolve to keep/drop/done/open, for questions.md entries, or for any duplicate-tree or unreadable-blob case, where the two revisions are meant to differ.

Run: inside `./bench.sh` (see 62a), which printed `outputs byte-identical (20 lines)`. The outputs are in `$S/perf/out-old.txt` and `$S/perf/out-new.txt`. The output starts `unrecognized Q-001` (quoted from `out-new.txt` line 1).

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `$S/perf/out-old.txt`, `$S/perf/out-new.txt`, `$S/perf/bench2.out`

---

## Claim 62c: "check_brief at 722884c7 issues exactly 2 `git ls-tree`, 1 `cat-file` and 1 `log` per brief whose main entry is a blob."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:319-358`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count on briefs that answer `ok`: the repo's three real briefs on main each issue 2 `ls-tree`, 1 `cat-file` and 1 `log`, counted with a PATH git shim. It does not establish the count for every blob brief. A blob brief that FENCE_AWK refuses, or whose Status line is not exact, issues 2 ls-tree, 1 cat-file and 0 log. An `ok` brief whose Status line `-G` cannot see (for example, a root-commit brief under `log.showRoot=false`) issues 2 log through the `:356` fallback. The precise version is "2 ls-tree and 1 cat-file per blob brief, plus 1 log (2 when -G finds nothing) when it answers ok".

The two ls-tree calls are main_entry from check_brief (`e="$(main_entry "$a")"`, `scripts/lib/dev-cycle-read.sh:330`) and again from brief_fields (`[[ "$(main_entry "$1")" != blob ]]`, `:292`). The logs are at `:355-356` (quoted under Claim 60a), and both follow the Status check at `:347-349`, which returns first on a bad line.

Runs (cwd `$S/count`, `TMPDIR=$S/count`, exit 0): `./count.sh $S/count`, 2026-10-05T11:56:36Z → `count.out`, which shows `1 cat-file; 1 log; 2 ls-tree` for each of the three real briefs. `./count2.sh $S/count`, 11:56:50Z → `count2.out`, which shows `1 cat-file; 2 ls-tree` for the odd and bad-Status blobs, and `1 cat-file; 2 log; 2 ls-tree` for the ok brief under `log.showRoot=false`.

**Legibility-target:** for-author

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `scripts/lib/dev-cycle-read.sh:319-358`, `$S/count/count.sh`, `$S/count/count.out`, `$S/count/count2.sh`, `$S/count/count2.out`

---

## Claim 63: "main_entry's duplicate-name check adds no process and no second pass (one assoc-array membership test per ls-tree line in the existing loop)."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:258-274`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the 2da477b7→722884c7 change to main_entry. The check is one `[[ -z "${m[$path]+set}" ]]` builtin test per line inside the pre-existing `while read` loop, plus one `[[ -z "$dup" ]]` after it, with no new command substitution or external command. The same `git ls-tree` remains main_entry's only process, which the Claim 62c git-shim count confirms: one ls-tree per main_entry call. It does not establish zero wall-clock cost. Claim 62a measured the whole check_answer path about 6% slower without isolating why, and the change also adds a `2>/dev/null` on the ls-tree.

The before and after loops, from `git diff 2da477b7 722884c7 -- scripts/lib/dev-cycle-read.sh`:

```bash
# 2da477b7 scripts/lib/dev-cycle-read.sh:262
  while IFS=$'\t' read -r mode path; do [[ -n "$path" ]] && m["$path"]="${mode%% *}"; done <<<"$out"
# 722884c7 scripts/lib/dev-cycle-read.sh:264-269 (quoted in full under Claim 56)
```

The only other changed line in the function is `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)"` (`scripts/lib/dev-cycle-read.sh:263`), which runs the same single ls-tree.

**Legibility-target:** for-orchestrator-synthesis

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `$S/count/count.out`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 60a** (`scripts/lib/dev-cycle-read.sh:338-356`): every parsed value comes from brief_fields, but the commit lookup's `git log -G'^Status: '` also matches the brief's text, fenced lines included. Say "every parsed value via brief_fields; the commit lookup matches separately".
- **Claim 62a** (`scripts/lib/dev-cycle-read.sh:545-573`): measured 5.2–6.7% slower (median/min) against an A/A noise level of about 2%. Say "within about 7%", or "about 12 ms per 20-ID call".
- **Claim 62c** (`scripts/lib/dev-cycle-read.sh:319-358`): 1 log holds only for briefs that answer ok. Blob briefs that skip issue 0, and the `:356` fallback can issue 2.

### Unverifiable
(none)

## Legibility notes

- A residue outside every submitted claim, from Claim 56: a `docs` tree entry literally named `working/questions.md`, with no `working` tree, reads as `absent` in main_entry while git resolves the path to a blob. check_answer then fails closed (no entry). check_brief prints `ok … new` for such a brief path. Such a tree needs `hash-object --literally` and fails fsck.
- Claims 56-63 were checked under mawk only. gawk is not installed.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u1a/docs/reviews/code-fact-check-submitted-claims-build-loop-u1a.md (overwrite the iteration-2 one), first line `Commit: 722884c7`, with a `## Submitted Claims` section of Claims 56-63 per the code-fact-check format, ending with the canonical Goal-Alignment Note.
- Answered: yes. All 8 submitted claims have verdicts (11 entries after splits: 8 Verified, 3 Mostly accurate, 0 Incorrect). Every entry but Claim 63 rests on executed probes in scratch repos or the bats run.
- Out of scope: no fresh claim harvesting, and hallucination-patterns.md was not updated (as instructed). Bats test 21 fails under the dotted TMPDIR and was ignored per the orchestrator note. gawk and other git versions were not run.
- Escalate: nothing merge-blocking. Optionally, the author could tighten the three Mostly-accurate endorsements' wording. The slash-named-entry `absent` residue (Claim 56 Scope) could go to a security critic if the orchestrator wants it judged; it is fsck-invalid and fails closed for check_answer.
- Decisions I made: I split Claims 60 and 62 on verdict divergence. I judged the ~6% versus 5% gap as Mostly accurate rather than Incorrect, because the conclusion that the overhead is negligible holds and only the bound is off. I verdicted Claim 63 statically, because a git-shim comparison of old and new main_entry was blocked by a sandbox removal check, and Claim 62c's shim count covers the new side.
