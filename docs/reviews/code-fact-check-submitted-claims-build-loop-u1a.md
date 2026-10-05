Commit: 2da477b7

# Code Fact-Check Report

**Repository:** claude-workflows (`/workspace/.claude/wt-build-loop-u1a`, branch `feat/build-loop-u1a`, HEAD 2da477b7, base `main` f6357ea1 = merge-base)
**Scope:** Stage-2.5 submitted-claims pass only: the nine critic endorsements in the review's `submitted.md` (Claims 45-53), checked against `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `skills/dev-cycle/SKILL.md`, `docs/reviews/override-log.md` and the branch's commit messages. No harvested claims (numbering continues the main report's).
**Checked:** 2026-10-05
**Total claims checked:** 10 (9 submitted claims; Claim 46 split into 46a/46b on verdict divergence)
**Summary:** 9 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read first: no claim below matches a logged pattern.

Execution environment for every executed claim: Linux (WSL2), bash, `awk` = mawk 1.3.4 20200120 (gawk is not installed), `LC_ALL=C.UTF-8` for bats. Captured output lives in the scratch dir `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/` (not in the repo: this pass may write no repo file other than this report). Main's scripts for the comparison were extracted with `git archive main scripts | tar -x -C mainsrc` (main = f6357ea1).

---

## Submitted Claims

## Claim 45: "the branch's `--check-answer` and `--check-brief` run within ±15% of main's wall-clock time, and `check_brief` output is identical to main's on the repo's real briefs"

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:286-299`, `scripts/lib/dev-cycle-read.sh:538-547`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers wall-clock time of one `dev-cycle.sh --check-brief` call over the repo's three real briefs and one `--check-answer` call over eight real IDs (Q-001..003, Q-104..108), main's scripts vs the branch's, on this machine, plus byte-identical `--check-brief` (and `--check-answer`) output on those inputs; does not establish timing on a larger docs/ tree or history, on a closed/ brief (none exists), under gawk, or under build-loop.sh's future per-brief `--status` calls.

Command: `./bench.sh` (cwd `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted`; the script `cd`s to the worktree and runs each script 15 times per mode, two alternating rounds), started 2026-10-05T11:18:06Z, exit 0 for every run (`rc=0` in each line). Output:

```
main brief N=15 total_ms=672 per_ms=44 rc=0
main answer N=15 total_ms=1546 per_ms=103 rc=0
branch brief N=15 total_ms=727 per_ms=48 rc=0
branch answer N=15 total_ms=1512 per_ms=100 rc=0
main brief N=15 total_ms=715 per_ms=47 rc=0
main answer N=15 total_ms=1591 per_ms=106 rc=0
branch brief N=15 total_ms=731 per_ms=48 rc=0
branch answer N=15 total_ms=1534 per_ms=102 rc=0
```

Branch vs main per call: `--check-brief` 48/44 = +9% and 48/47 = +2%; `--check-answer` 100/103 = -3% and 102/106 = -4%. All within ±15%. `diff out-main-brief.txt out-branch-brief.txt` printed nothing (`BRIEF_IDENTICAL`); both print, for all three briefs, `ok docs/working/briefs/<name>.md open cac2ba0cdc350c163fa530b0fa868c84c574406b`. The `--check-answer` outputs were also identical (empty `diff`), which holds here only because the worktree's questions files match main's for those IDs. Confidence is Medium because the sample is 2 × 15 runs on a shared machine and only three briefs, all `open`, exist.

**Evidence:** `scripts/lib/dev-cycle-read.sh:281-300`, `scripts/lib/dev-cycle-read.sh:309-347`, `scripts/lib/dev-cycle-read.sh:534-560`; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/bench-output.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/out-main-brief.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/out-branch-brief.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/bench.sh`

---

## Claim 46a: "check_answer as changed discharges override-log rows 206 ... and 217"

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:534-556`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers row 206 (check_answer read questions.md from the working tree) and row 217 (check_answer appended to SKIPPED via `skipped`), both checked against the rewritten function and its tests; does not establish anything about build-loop.sh's future callers (U3).

Row 206 (`docs/reviews/override-log.md:206`) reads: "check_answer, now in the shared lib, reads questions.md from the working tree (F28) ... Revisit trigger: U1." Row 217 (`:217`) reads: "check_answer appends to SKIPPED via skipped; check_brief does not ... the side effect goes with it. Revisit trigger: U1."

The rewritten function reads only main's commit and no longer calls `skipped`:

```bash
# scripts/lib/dev-cycle-read.sh:538-547
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
    case "$e" in
      absent) continue ;;
      blob) ;;
      ...
    esac
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")"
```
(excerpt ends :547; enclosing check_answer() continues to :560 — read; the rest only interprets `r` and prints.)

`grep -n 'skipped ' scripts/lib/dev-cycle-read.sh` finds `skipped` defined at `:125` and called nowhere inside `check_answer` (paraphrased — no quote available because the claim covers absence of code: no `skipped` call in `:534-560`). The bats test "check_answer reads git only: no ROOT_REAL needed, SKIPPED untouched, skip without main by name" passed and asserts `skipped=0` with a symlinked archive on main; "--check-answer reads main's commit: a working-tree or branch-only answer is open (T34)" passed. Command: `bats --filter '<7 U1a test names>' test/scripts/dev-cycle.bats` (cwd `/workspace/.claude/wt-build-loop-u1a`, `LC_ALL=C.UTF-8`), 2026-10-05T11:18:22Z, exit 0, 7/7 ok. My probe P4 (`probe.sh`, 2026-10-05T11:18:46Z, exit 0) made a scratch repo's `docs/working` mode 000 and `--check-answer Q-1` still printed `keep Q-1` from main's commit.

**Evidence:** `docs/reviews/override-log.md:206`, `docs/reviews/override-log.md:217`, `scripts/lib/dev-cycle-read.sh:125`, `scripts/lib/dev-cycle-read.sh:528-560`, `test/scripts/dev-cycle.bats:393-405`; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/bats-targeted.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe-output.txt`

---

## Claim 46b: "check_answer as changed discharges override-log row ... 216"

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:534-537`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two parts of row 216 that check_answer itself can carry (add main_by_name; no longer exit via need_root); does not establish row 216's "accept only a positive line" part, which is an obligation on U3's `--approved` capture and is met here only by header guidance.

Row 216 (`docs/reviews/override-log.md:216`) reads: "check_answer is print-only and exits via need_root; --approved will capture it as a merge authorisation, so U1's rewrite should accept only a positive line and add main_by_name". The rewrite adds the gate:

```bash
# scripts/lib/dev-cycle-read.sh:537
  if ! main_by_name; then echo "skip $a: no default branch found by name (origin/HEAD, main or master), or resolve_main has not run"; return; fi
```

and no longer calls `need_root` (the only `need_root` calls in the file are at `:121`, `:124`, `:125`, `:311` and `:420`; paraphrased — no quote available because the claim covers absence of a call in `:534-560`). The "accept only a positive line" part is not something check_answer can enforce: it still prints non-positive answer lines (`open`, `unrecognized`) and skip lines, and the safe-capture rule lives in the lib header, `scripts/lib/dev-cycle-read.sh:24-27`: "check_branch and check_answer answer with one printed line per argument ... treat any line that is not a positive answer as a refusal." So the row's U1 parts are discharged; its positive-line part remains with the consumer (U3 `--approved`), which does not exist yet. "Discharges" is right for what U1 can do but imprecise as a statement about the whole row.

**Evidence:** `docs/reviews/override-log.md:216`, `scripts/lib/dev-cycle-read.sh:22-27`, `scripts/lib/dev-cycle-read.sh:534-560`

---

## Claim 47: "check_brief now reads its Status line through brief_fields, so briefs have one parser"

**Submitted by:** architecture-review, api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:327-337`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the only code reading a brief's machine-line values (Status here; Branch/Policy/Paths/Asked/Dispatched for U1b) is brief_fields' single awk pass, and that no other script in `scripts/` parses brief lines; does not establish that check_brief's commit lookup (`git log -G'^Status: '`, which matches any Status line, fenced or not, by design) uses that parser, nor how future U1b consumers judge the values.

```bash
# scripts/lib/dev-cycle-read.sh:328-337
  if ! brief_fields "$a"; then
    case "$BRIEF_ODD" in
      ...
    esac
    return
  fi
  st="${BRIEF[status]-}"
  if [[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]; then
```
(excerpt ends :337; enclosing check_brief() continues to :347 — read.) The old inline awk (`!seen && /^Status:/ ...`) is removed in the diff. After `:337` check_brief reads no further brief text: `:344` runs `git log -1 --format=%H --first-parent --diff-merges=first-parent -s -G'^Status: ' "$MAIN_SHA" -- "$a"` to pick the commit, a history search rather than a value parse (its comment at `:339-343` says "Any such line counts (a quoted one ...)"). `rg -n 'briefs' scripts/` outside the lib finds only dev-cycle.sh comments and `skipdir docs/working/briefs` (`scripts/dev-cycle.sh:461`), and the one other `^Status:` match, `scripts/questions.sh:179`, parses question entries, not briefs (paraphrased — no quote available because the claim covers absence of other brief parsers across `scripts/`). Bats tests "brief_fields reads each machine line's first unfenced copy ... check_brief agrees (T31)" and the template test passed (see Claim 46a's run).

**Evidence:** `scripts/lib/dev-cycle-read.sh:281-300`, `scripts/lib/dev-cycle-read.sh:309-347`, `scripts/dev-cycle.sh:461`, `scripts/questions.sh:179`

---

## Claim 48: "main_entry prints `error`, never `absent`, when ls-tree fails or there is no default branch found by name, and both callers (check_brief, check_answer) skip on `error`"

**Submitted by:** architecture-review, api-consistency-reviewer, security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:256-267`, `scripts/lib/dev-cycle-read.sh:320-326`, `scripts/lib/dev-cycle-read.sh:539-545`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_entry's two error branches (main_by_name false; ls-tree non-zero exit, exercised with an unset MAIN_BY_NAME, a missing object, a short unknown SHA and a blob SHA) and the two callers' `error)` arms; does not establish behavior when ls-tree exits 0 but prints a truncated listing, or the handling of ls-tree's unscrubbed stderr (`fatal: ...`), which reaches the caller's stderr.

```bash
# scripts/lib/dev-cycle-read.sh:259-261
  main_by_name || { echo error; return; }
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1")" || { echo error; return; }
```
(excerpt ends :261; enclosing main_entry() continues to :267 — read; `absent` is printed only at `:264` and `:266`, after a successful ls-tree.) Callers: `scripts/lib/dev-cycle-read.sh:325` `error) echo "skip $a: the default branch's tree could not be read"; return ;;` and `:544` `error) echo "skip $a: the default branch's tree could not be read, so $f is not read"; return ;;`. `grep main_entry` finds no other caller in `scripts/` (paraphrased — no quote available because the claim covers absence of further call sites).

Probe P3 (`./probe.sh`, cwd the scratch dir, 2026-10-05T11:18:46Z, exit 0) printed: `before resolve_main: error`, `by name: blob`, `absent path: absent`, `MAIN_SHA=a blob: error`, `MAIN_SHA=short unknown: error`, `MAIN_BY_NAME empty: error`, `check_answer, bad sha: skip Q-1: the default branch's tree could not be read, so docs/working/questions.md is not read`. The bats test "a NUL byte refuses ... main_entry fails closed" (all-zero MAIN_SHA) passed in the run under Claim 46a.

**Evidence:** `scripts/lib/dev-cycle-read.sh:256-267`, `scripts/lib/dev-cycle-read.sh:320-326`, `scripts/lib/dev-cycle-read.sh:539-545`, `test/scripts/dev-cycle.bats:407-423`; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe-output.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/p3-stderr.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/bats-targeted.txt`

---

## Claim 49: "the NUL refusal sits in the shared FENCE_AWK, so every FENCE_AWK reader refuses such a file"

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both FENCE_AWK readers that exist (brief_fields, and so check_brief; check_answer via ANSWER_AWK) under mawk 1.3.4, with a NUL at line start, mid-file, inside a fence, in an unterminated last line and as a run of NULs; does not establish the behavior under gawk or another awk (not installed here; the lib runs whatever `awk` is on PATH), nor readers U1b/U3 add later.

```awk
# scripts/lib/dev-cycle-read.sh:214-217
  if (odd) return 1   # the file is already refused: nothing after it is read
  if (index(l, "\r")) { refuse("cr"); return 1 }
  if (index(l, "\0")) { refuse("nul"); return 1 }  # $(...) drops NUL, so a printed line would not be the line read
  if (NR == 1 && substr(l, 1, 3) == "\357\273\277") { refuse("bom"); return 1 }
```
(excerpt ends :217; enclosing fence() continues to :229 — read.) The check runs before the `infence` branch at `:218`, so fenced lines are covered too. `grep -n FENCE_AWK scripts/*.sh scripts/lib/*.sh` shows the two awk invocations, `scripts/lib/dev-cycle-read.sh:286` (brief_fields) and `:547` (check_answer); dev-cycle.sh mentions it only in a comment (`scripts/dev-cycle.sh:88`). Both END blocks print `odd` first (`:292`, `:522`).

Probe P1/P2 (`./probe.sh`, 2026-10-05T11:18:46Z, exit 0): brief variants with NUL at line 2, line 3, inside a fence, as an unterminated last line and as `\0\0\0` each printed `skip ...: line N holds a NUL byte, so the brief is not read`; a NUL-free control printed `ok ... open <sha>`; a questions file with a NUL inside a fence printed `skip Q-1: line 6 of docs/working/questions.md holds a NUL byte, so no entry in docs/working/questions.md is read`, and its clean control `keep Q-1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:186-230`, `scripts/lib/dev-cycle-read.sh:286-292`, `scripts/lib/dev-cycle-read.sh:521-527`, `scripts/lib/dev-cycle-read.sh:547`, `scripts/dev-cycle.sh:88`; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe-output.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe.sh`

---

## Claim 50: "scripts/dev-cycle.sh has a single main-by-name gate for the --check-* modes"

**Submitted by:** architecture-review
**Location:** `scripts/dev-cycle.sh:191`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that dev-cycle.sh tests main_by_name at exactly one place, for --check-brief, --check-branch and --check-answer together; does not establish that --check-path, --check-write or --check-fix are gated (they are not, by design: they do not read main), and does not count the lib's own per-function main_by_name guards.

```bash
# scripts/dev-cycle.sh:191-193
if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then
  echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
fi
```
`grep -n 'main_by_name\|MAIN_BY_NAME' scripts/dev-cycle.sh` returns only line 191 (paraphrased — no quote available because the claim covers absence of any other gate). The dispatch loop follows at `:194-204`. The lib functions also skip without main by name (`scripts/lib/dev-cycle-read.sh:312`, `:359`, `:537`), a second layer, not a second gate in dev-cycle.sh.

**Evidence:** `scripts/dev-cycle.sh:186-204`, `scripts/lib/dev-cycle-read.sh:312`, `scripts/lib/dev-cycle-read.sh:359`, `scripts/lib/dev-cycle-read.sh:537`

---

## Claim 51: "the --check-answer behaviour change (reads main's commit) is documented in the help text, its Exit line, `skills/dev-cycle/SKILL.md:291-294` and the commit notes, and `skills/dev-cycle/SKILL.md:100-101` covers the new exit 1"

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/dev-cycle.sh:56-80`, `skills/dev-cycle/SKILL.md:100-101`, `skills/dev-cycle/SKILL.md:291-294`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named places and that `--help` actually prints the changed lines including the Exit line; does not establish that every other doc naming --check-answer (for example docs outside the skill) was updated, nor the installed image copy (the commit notes say it is unchanged until a release).

Command: `bash scripts/dev-cycle.sh --help` (cwd `/workspace/.claude/wt-build-loop-u1a`), 2026-10-05T11:18:55Z, exit 0. Its output includes "from docs/working/questions.md or its archive on the default branch's commit (an answer only in the working tree reads open, or no such entry, until it is committed there)", "--check-brief, --check-branch and --check-answer need a default branch found by name", and ends with the Exit line "default branch (for the digest, --check-brief, --check-branch and --check-answer); a failed step exits non-zero mid-digest. Printed repo text is data." (help output lines 77-79; the `sed -n '2,80p'` range at `scripts/dev-cycle.sh:110` reaches the Exit line's end at `:80`). `skills/dev-cycle/SKILL.md:292-293` reads "both from the default branch's commit (an answer recorded only in the working tree reads `open`, or no such entry, until it lands)". `skills/dev-cycle/SKILL.md:100-101` reads "A check that exits non-zero (no default branch, say) is recorded, and the step that needed it stops." (pre-existing text that covers any check mode's exit 1). Commit c8435580's body says "check_answer reads docs/working/questions{,-archive}.md from the default branch's commit ... dev-cycle.sh --check-answer exits 1 without such a branch".

**Evidence:** `scripts/dev-cycle.sh:56-60`, `scripts/dev-cycle.sh:70-71`, `scripts/dev-cycle.sh:78-80`, `scripts/dev-cycle.sh:110`, `skills/dev-cycle/SKILL.md:100-101`, `skills/dev-cycle/SKILL.md:291-294`, commit c8435580; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/help-output.txt`

---

## Claim 52: "check_answer reads only `MAIN_SHA:<constant path>` objects and never a working-tree path"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:538-547`
**Type:** Invariant / Security
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_answer's file inputs: the loop's two literal paths, read only through `git ls-tree` on MAIN_SHA (main_entry) and `git cat-file blob "$MAIN_SHA:$f"`, with awk reading stdin only; does not establish git-level indirection inside the object store (for example `refs/replace/` objects, which cat-file honors) or what MAIN_SHA names when a caller sets it by hand rather than through resolve_main.

```bash
# scripts/lib/dev-cycle-read.sh:538-547
  for f in docs/working/questions.md docs/working/questions-archive.md; do
    e="$(main_entry "$f")"
    ...
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")"
```
(excerpt ends :547; enclosing check_answer() continues to :560 — read; the remaining lines only compare `r`, `hit` and `where` and print.) `f` is only ever one of the two literals; awk receives no file operand, so it reads the pipe. main_entry reads only `git ls-tree -t --full-tree "$MAIN_SHA" ...` (`:261`). Because the paths have no `./` prefix, `<rev>:<path>` resolves from the tree root, not the current directory, and the test that runs check_answer after `cd docs` passed. Probe P4 (`probe.sh`, 2026-10-05T11:18:46Z, exit 0): with the scratch repo's working `docs/working` at mode 000, `--check-answer Q-1` printed `keep Q-1`. The T34 bats test (working-tree-only and side-branch answers read `open`) passed (Claim 46a's run).

**Evidence:** `scripts/lib/dev-cycle-read.sh:256-267`, `scripts/lib/dev-cycle-read.sh:534-560`, `test/scripts/dev-cycle.bats:351-368`, `test/scripts/dev-cycle.bats:393-405`; captured output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe-output.txt`, `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/bats-targeted.txt`

---

## Claim 53: "the `git cat-file blob "$MAIN_SHA:…"` argument cannot be parsed as an option, because it starts with the hex MAIN_SHA"

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:286`, `scripts/lib/dev-cycle-read.sh:547`
**Type:** Invariant / Security
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the argument's first character whenever MAIN_SHA was set by resolve_main (the only setter in the lib; it is reset to "" at source time, so the environment cannot preset it) and the guards before each call; does not establish behavior if a caller assigns MAIN_SHA itself, or brief_fields called with an empty MAIN_SHA (no own guard: the argument becomes `:<path>`, which is not an option but reads the index entry instead of main).

MAIN_SHA is assigned only in resolve_main, from `rev-parse --verify`:

```bash
# scripts/lib/dev-cycle-read.sh:386-388
    sha="$(git show-ref --verify --hash "refs/heads/$c" 2>/dev/null || true)"
    [[ -z "$sha" ]] || sha="$(git rev-parse --verify --quiet "$sha^{commit}" 2>/dev/null || true)"
    if [[ -n "$sha" ]]; then MAIN="$c"; MAIN_SHA="$sha"; MAIN_BY_NAME=1; break; fi
```
(excerpt ends :388; enclosing resolve_main() continues to :398 — read; the fallback at `:394` also takes `git rev-parse --verify --quiet HEAD`.) The lib resets it on source: `scripts/lib/dev-cycle-read.sh:245` `MAIN=""; MAIN_SHA=""; MAIN_BY_NAME=""`. check_answer reaches `:547` only after `main_by_name` (`:537`), which requires a non-empty MAIN_SHA (`:246`); brief_fields' only caller, check_brief, checks main_by_name at `:312`. Probe P5 printed `byname MAIN_SHA=6df09f6d31da324b6b86e6b1d5f83e6cd219a26d` and the same 40-hex form for the current-branch fallback (supporting evidence only; the verdict rests on reading). Under the claim's premise (a hex prefix) a leading `-` is impossible. The residue in Scope is the unguarded brief_fields entry point.

**Evidence:** `scripts/lib/dev-cycle-read.sh:245-246`, `scripts/lib/dev-cycle-read.sh:281-300`, `scripts/lib/dev-cycle-read.sh:309-312`, `scripts/lib/dev-cycle-read.sh:376-398`, `scripts/lib/dev-cycle-read.sh:537-547`; supporting output `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i2/submitted/probe-output.txt`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 46b** (`scripts/lib/dev-cycle-read.sh:534-537`): row 216's main_by_name and need_root parts are discharged; its "accept only a positive line" part stays with U3's `--approved` consumer (header guidance only). Say "discharges row 216's U1 part".

### Unverifiable
(none)

## Legibility notes

- Claim 45 holds on a small sample (three open briefs, 2 × 15 runs). The +9% upper reading for `--check-brief` is the closest to the ±15% bound.
- Claim 49 holds under mawk only. gawk is not installed, so `index(l, "\0")` was not run under gawk.
- Claim 53's residue: brief_fields does not guard itself. Called with an empty MAIN_SHA it would read the index's copy of the file (`:<path>`) rather than main's. Its comment puts the main_by_name check on the caller, and its only caller does that check.
