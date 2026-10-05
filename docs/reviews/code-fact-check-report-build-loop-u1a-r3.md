Commit: 722884c7

# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u1a`, branch `feat/build-loop-u1a`)
**Scope:** `git diff main...feat/build-loop-u1a -- . ':!docs/reviews'` (scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/scripts/dev-cycle.bats) plus the branch's commit messages (`git log main..feat/build-loop-u1a`, 5 commits). Replicate 3 of k=3, iteration 3 (final confirming pass).
**Checked:** 2026-10-05
**Total claims checked:** 42
**Summary:** 37 verified, 2 mostly accurate, 0 stale, 1 incorrect, 2 unverifiable

Execution environment: every probe ran in throwaway repos under the scratch dir
`/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i3/fc3/` (`r/`, `fake/`, `dc/`, `old/`), with
`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, `HOME` and `TMPDIR` in the scratch dir. Old code
(main f6357ea1, c8435580, 2da477b7, 78703f22) was materialised with `git show <rev>:<path>` into
`fc3/old/<rev>/`; nothing was checked out in the worktree. Captured outputs are in `fc3/logs/`
(cited per claim). Timestamps: bats suite 2026-10-05T11:32:51Z; probes 11:35-11:50Z.

Suite: `cd /workspace/.claude/wt-build-loop-u1a && LC_ALL=C.UTF-8 TMPDIR=fc3 bats test/scripts/dev-cycle.bats`
→ exit 1, 66/67 ok; the one failure is test 21 (`git update-ref "refs/heads/--output=$victim"` refused
because the scratch TMPDIR path contains a `.claude` component, an invalid ref-name part). That test is
outside the diff and the orchestrator confirmed it passes with TMPDIR unset; not a finding. Log:
`fc3/logs/bats-head.txt`.

Hallucination-pattern log: `docs/reviews/hallucination-patterns.md` was not consulted for updates per
the orchestrator override; no claim in this run names a nonexistent symbol, flag or API (no candidates).

---

## Claim 1: "a stray carriage return, a NUL byte, or a byte-order mark on line 1" (--check-brief skip reasons)

**Location:** `scripts/dev-cycle.sh:41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --check-brief refusing a brief with a NUL byte on main (message names the line); does not establish behavior under awks other than the installed one (override-log C2 row, settled).
**Legibility-target:** for-orchestrator-synthesis

Test 64 (`test/scripts/dev-cycle.bats:1177`) asserts `skip $b: line 2 holds a NUL byte, so the brief is not read` and passes at HEAD. The refusal is `if (index(l, "\0")) { refuse("nul"); return 1 }` (`scripts/lib/dev-cycle-read.sh:216`). Against c8435580's lib, brief_fields on `Status: op\0en` returned `status=[Status: open]` with bash's "ignored null byte" warning; HEAD returns `refused odd 1 nul` (`fc3/logs/pc.txt`).

Command: `bash fc3/pc.sh` (cwd fc3), exit 0, 2026-10-05T11:48Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `test/scripts/dev-cycle.bats:1177-1193`, `fc3/logs/bats-head.txt`, `fc3/logs/pc.txt`

---

## Claim 2: "an answer only in the working tree reads open, or no such entry, until it is committed there"

**Location:** `scripts/dev-cycle.sh:56-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an answer added to an existing main entry (reads `open`) and a new entry only in the working tree (reads `skip … no such entry`); does not establish the outcome when main's questions file is itself refused (then a different skip reason prints, whatever the working tree says).
**Legibility-target:** for-orchestrator-synthesis

Probe (`fc3/p3.sh`, last block): main has `Q-1` OPEN, working tree ANSWERED [1] → HEAD prints `open Q-1` (main's lib prints `keep Q-1`); a new `Q-8` only in the working tree → `skip Q-8: no such entry in docs/working/questions.md or questions-archive.md on the default branch`. The reader is `r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk …)"` (`scripts/lib/dev-cycle-read.sh:559`), never the working-tree path.

Command: `timeout 200 bash fc3/p3.sh` (cwd fc3), exit 0, 2026-10-05T11:40Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-572`, `fc3/logs/p3.txt`

---

## Claim 3: --check-answer skip reasons "… a NUL byte … a questions file that is not a regular file under plain directories on the default branch, or a default branch whose tree or file could not be read"

**Location:** `scripts/dev-cycle.sh:66-71`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every skip check_answer can print through dev-cycle.sh for a well-formed ID (no entry, dup, both files, every FENCE_AWK reason, unbalanced, quoted, notfile, notdir, error, unreadable blob); does not cover `skip X: not a question ID` (absent from the list, but also absent on main, so pre-existing) or the no-default-branch skip (unreachable: dev-cycle.sh exits 1 first, `:192-194`).
**Legibility-target:** for-orchestrator-synthesis

Each message at `scripts/lib/dev-cycle-read.sh:554-572` maps to a listed reason: `notdir` → "not a regular file under plain directories" (`… is not a directory on the default branch, so … is not read`), `error)` → "tree … could not be read", `:560` "could not be read from the default branch" → "file could not be read". Executed in `fc3/p1.sh` (dup leaf, dup parent, missing tree objects → `skip Q-1: the default branch's tree could not be read, …`) and `fc3/p3.sh` (missing blob → `skip Q-1: docs/working/questions.md could not be read from the default branch`; dup, both-files and no-entry cases). Main's help (`git show main:scripts/dev-cycle.sh`, `:56-67`) already omitted the not-a-question-ID case.

Commands: `timeout 120 bash fc3/p1.sh`, `timeout 200 bash fc3/p3.sh` (cwd fc3), both exit 0, 2026-10-05T11:35Z/11:40Z.

**Evidence:** `scripts/dev-cycle.sh:56-71`, `scripts/lib/dev-cycle-read.sh:545-573`, `fc3/logs/p1.txt`, `fc3/logs/p3.txt`

---

## Claim 4: "--check-brief, --check-branch and --check-answer need a default branch found by name … they read its commit" / Exit 1 "… no default branch (for the digest, --check-brief, --check-branch and --check-answer)"

**Location:** `scripts/dev-cycle.sh:72-73`, `scripts/dev-cycle.sh:80-81`, `scripts/dev-cycle.sh:188-194`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh exiting 1 with the "needs a default branch" stderr when only `trunk` exists; does not establish that --help shows the Exit line (it does not: see Claim 5).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/dev-cycle.sh:192-194
if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then
  echo "$CHECK needs a default branch (origin/HEAD, main or master); found none" >&2; exit 1
fi
```

Test "--check-answer needs a default branch found by name" (`test/scripts/dev-cycle.bats:1153`) asserts status 1, empty stdout and that stderr; it passes (`fc3/logs/bats-head.txt`, ok 62).

**Evidence:** `scripts/dev-cycle.sh:188-194`, `test/scripts/dev-cycle.bats:1153-1158`, `fc3/logs/bats-head.txt`

---

## Claim 5: `-h|--help) sed -n '2,80p' "$0"` prints the usage header

**Location:** `scripts/dev-cycle.sh:111`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --help output at HEAD and at each branch commit; does not establish anything about the header's content (Claims 1-4 cover that).
**Legibility-target:** for-author

The header comment now ends at line 81, one line past the help range:

```bash
# scripts/dev-cycle.sh:79-81
# Exit: 0 digest printed (or, for the check modes, every argument answered: a
# skip is an answer, not an error); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no
# default branch (for the digest, --check-brief, --check-branch and --check-answer); a failed step exits non-zero mid-digest. Printed repo text is data.
```

`bash scripts/dev-cycle.sh --help` at HEAD ends with `skip is an answer, not an error); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no` — the sentence is cut mid-way and the default-branch exit condition this diff extended to --check-answer is not shown. At main, c8435580 and 2da477b7 the last help line is the full `default branch (for the digest, …) … Printed repo text is data.`; the cut starts at 78703f22, whose C1 fix added one line (`#             under plain directories on the default branch, or a default` / `branch whose tree or file could not be read).`, `:69-70`) without moving `2,80p` to `2,81p`. No bats test covers --help. Fix: `sed -n '2,81p'`.

Command: `bash fc3/old/<rev>/dev-cycle.sh --help | tail -1` for main, c8435580, 2da477b7, 78703f22, then `bash scripts/dev-cycle.sh --help` (cwd worktree), exit 0, 2026-10-05T11:50Z.

**Evidence:** `scripts/dev-cycle.sh:79-82`, `scripts/dev-cycle.sh:111`, `fc3/logs/help.txt`

---

## Claim 6: "A change here must pass test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ once that second caller lands."

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the factual parts: dev-cycle.bats is the one suite exercising the lib today and it passes (66/67, test 21 environmental); build-loop.sh and its suites do not exist yet; does not establish any enforcement (it is a rule, not a gate).
**Legibility-target:** for-orchestrator-synthesis

`ls scripts/build-loop.sh` → "No such file or directory"; `test/scripts/` holds no build-loop suite, and `grep -rn build-loop test/scripts/*.bats` finds nothing (paraphrased — no quote available because the claim covers absence of files/grep hits). A5 (iteration 2) said the old wording named two callers' suites; the new wording says the second lands later, which matches.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `fc3/logs/bats-head.txt`

---

## Claim 7: "The caller sets -euo pipefail, cds to the repo root and sets ROOT_REAL … inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root) unless ROOT_REAL is set…"

**Location:** `scripts/lib/dev-cycle-read.sh:12-20`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers dev-cycle.sh honouring the contract (`set -euo pipefail` at `scripts/dev-cycle.sh:83`, `cd "$ROOT"`, `ROOT_REAL="$(pwd -P)"`) and check_answer's removal from the need_root list; does not establish what a future caller (build-loop.sh) does — and the new read-failure checks depend on pipefail (Claims 17, 23).
**Legibility-target:** for-orchestrator-synthesis

`check_answer` has no `need_root` call (`scripts/lib/dev-cycle-read.sh:545-573`, read whole); test 63 calls it with ROOT_REAL unset and from `docs/` and gets answers, not an exit (passes). `check_brief` still starts `need_root` (`:321`).

**Evidence:** `scripts/dev-cycle.sh:83`, `scripts/dev-cycle.sh:116-120`, `scripts/lib/dev-cycle-read.sh:91-95`, `scripts/lib/dev-cycle-read.sh:319-321`, `fc3/logs/bats-head.txt`

---

## Claim 8: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name."

**Location:** `scripts/lib/dev-cycle-read.sh:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three functions' first guard; does not establish main_entry/brief_fields (separate claims 14, 17).
**Legibility-target:** for-orchestrator-synthesis

`if ! main_by_name; then echo "skip $a: no default branch found by name …"; return; fi` (`:548`, check_answer; same at `:322` and `:370`). Test 63's first line, `check_answer Q-1` before `resolve_main`, prints that skip (passes).

**Evidence:** `scripts/lib/dev-cycle-read.sh:322`, `:370`, `:548`, `test/scripts/dev-cycle.bats:1160-1175`

---

## Claim 9: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree, which the cycle writes)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that no content is read from the working tree by these functions (test 66 changes the working-tree brief to `Status: dropped` and brief_fields/check_brief still read `open`; T34 test); does not establish that check_branch reads "the default branch's commit" only — it reads `refs/heads/<name>` and counts against MAIN_SHA (unchanged pre-existing wording).
**Legibility-target:** for-orchestrator-synthesis

check_brief's working-tree check is `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi` (`:327`), a plainness check, not a content read.

**Evidence:** `scripts/lib/dev-cycle-read.sh:327-345`, `test/scripts/dev-cycle.bats:1209-1229`, `fc3/logs/bats-head.txt`

---

## Claim 10: FENCE_AWK header: outside a fence `<`, open `<!--`, refdef; "and anywhere in the file, fenced or not, a carriage return inside a line …, a NUL byte …, or a byte-order mark on line 1"

**Location:** `scripts/lib/dev-cycle-read.sh:163-179`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each refusal inside and outside a fence; does not establish the "line 1" BOM being inside a fence (impossible: line 1 cannot be fenced content).
**Legibility-target:** for-orchestrator-synthesis

The CR/NUL/BOM tests run before the `infence` branch (`:215-218`). Probe (`fc3/p5.sh`): CR inside a fence → `odd 3 cr`; NUL inside a fence → `odd 3 nul`; BOM on line 1 → `odd 1 bom`; BOM on line 2 inside a fence → `clean`; `<div>`, `x <!-- y` and `[a]: b` inside a fence → `clean`; `<div>` outside → `odd 2 html`. A6 (iteration 2) is resolved.

Command: `timeout 60 bash fc3/p5.sh` (cwd fc3), exit 0, 2026-10-05T11:43Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:213-229`, `fc3/logs/p5.txt`

---

## Claim 11: "$(...) drops NUL, so a printed line would not be the line read"

**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash command substitution dropping NUL bytes; does not establish other shells.
**Legibility-target:** for-orchestrator-synthesis

c8435580's brief_fields on `Status: op\0en` printed `warning: command substitution: ignored null byte in input` and `status=[Status: open]` (`fc3/logs/pc.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `fc3/logs/pc.txt`

---

## Claim 12: "check_brief, check_branch and check_answer read its commit, so they answer only when it was found by name, never for the current branch's fallback or before resolve_main has succeeded."

**Location:** `scripts/lib/dev-cycle-read.sh:242-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three guards (Claim 8) and resolve_main leaving MAIN_BY_NAME empty on the current-branch fallback (`:401-406`); does not establish main_by_name's MAIN_SHA belonging to this repo (override-log row 208, settled).
**Legibility-target:** for-orchestrator-synthesis

`main_by_name() { [[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]; }` (`:246`); the fallback branch sets only `MAIN` and `MAIN_SHA` (`:405`). Test 62 (only `trunk`) exits 1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:245-246`, `:387-409`, `fc3/logs/bats-head.txt`

---

## Claim 13: main_entry "prints "blob" (a regular file, mode 100644 or 100755), "absent", "notfile" …, "notdir PART" …"

**Location:** `scripts/lib/dev-cycle-read.sh:247-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers blob, absent, notfile (symlink on main), notdir (symlinked docs/working and symlinked briefs/ on main); does not establish gitlink handling (override-log C8, settled).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:270-273
  for p in "${want[@]}"; do
    case "${m[$p]-}" in '') echo absent; return ;; 040000) ;; *) echo "notdir $p"; return ;; esac
  done
  case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac
```

Tests 60/61 (symlinked questions.md and docs/working on main) pass; `fc3/pc.sh` symlinked briefs dir on main → `skip …: docs/working/briefs is not a directory on the default branch` (main printed `ok … new`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `test/scripts/dev-cycle.bats:1137-1151`, `fc3/logs/pc.txt`

---

## Claim 14: "error" for "no default branch found by name, ls-tree failed, or the tree lists a name twice; git's own reads would take the first copy, which may not be the one a check saw, so this answers error instead; never read as absent"

**Location:** `scripts/lib/dev-cycle-read.sh:251-254`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers (a) git's first-copy rule, (b) duplicates at the leaf and at parent components, (c) ls-tree failure on missing tree objects and the `2>/dev/null`; does not establish trees whose objects are present but malformed in ways ls-tree reads with exit 0 (none found).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:263-269
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
  while IFS=$'\t' read -r mode path; do
    [[ -n "$path" ]] || continue
    [[ -z "${m[$path]+set}" ]] || dup=1
    m["$path"]="${mode%% *}"
  done <<<"$out"
  [[ -z "$dup" ]] || { echo error; return; }
```

(excerpt ends :269; enclosing main_entry() continues to :274 — read.) Probe `fc3/p1.sh`:
(a) Leaf duplicate built with `git mktree` (which keeps same-name entries in input order): symlink-then-blob → `git cat-file blob c:docs/working/questions.md` = `x` (the symlink); blob-then-symlink → the entry text. First copy confirmed both ways. main_entry → `error` both ways.
(b) Parent duplicates: `docs` as blob and tree → ls-tree lists both, `cat-file` fails ("path … does not exist", it took the blob), main_entry `error`; two `working` trees (either order) → ls-tree lists `docs/working` twice → `error`.
(c) Missing `docs/working` or `docs` tree object → ls-tree prints a partial listing but exits 1 → `error`; missing root tree → `error`. No exit-0 partial listing observed.
Without the dup check (mutant `fake/headnodup`), test 67's last assertion fails with `skip Q-1: no such entry …`, so the dup path is what produces the expected message.

Commands: `timeout 120 bash fc3/p1.sh` (exit 0, 11:35Z); `bats -f 'unreadable blob or a tree naming' fc3/fake/headnodup/test/scripts/dev-cycle.bats` (exit 1 as expected, 11:34Z).

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `fc3/logs/p1.txt`, `fc3/logs/t67-headnodup.txt`

---

## Claim 15: "One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory)."

**Location:** `scripts/lib/dev-cycle-read.sh:254-257`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one process per main_entry call naming every prefix; does not establish its cost (override-log A3 row, settled: -t also lists named directories' children).
**Legibility-target:** for-orchestrator-synthesis

`while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; …; want+=("$p"); done` then one `git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1"` (`:262-263`). Test 63 calls check_answer from `docs/` and still reads main's paths (passes).

**Evidence:** `scripts/lib/dev-cycle-read.sh:262-263`, `fc3/logs/p1.txt`

---

## Claim 16: brief_fields: "for each key, the first line outside a fence … whole, after one trailing CR is dropped … each the line as stored but for that CR"

**Location:** `scripts/lib/dev-cycle-read.sh:275-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers first-unfenced-copy selection, the six keys, unset absent keys and CR drop; does not establish values containing a TAB in the key part (impossible: keys are fixed words).
**Legibility-target:** for-orchestrator-synthesis

`{ sub(/\r$/, "") }` then `match($0, /^(Status|Branch|Policy|Paths|Asked|Dispatched):/) { k = tolower(…); if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 } }` (`:296-300`). Test 66 (`Status: open\r\n` → `status=[Status: open]`, fenced and later copies ignored) passes. A7 resolved.

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `test/scripts/dev-cycle.bats:1209-1243`, `fc3/logs/bats-head.txt`

---

## Claim 17: brief_fields "Otherwise it sets no key and returns 1, with BRIEF_ODD "odd N WHY" …, "unbalanced N" … or "error" (no default branch found by name, a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read)"

**Location:** `scripts/lib/dev-cycle-read.sh:282-287`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each error source under the caller contract (`set -euo pipefail`); does not hold without pipefail: there a missing blob returns 0 with no keys (the old R2 behavior), since `awk` exits 0.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:292, :301-302
  if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi
    END { … }')" \
    || { BRIEF_ODD=error; return 1; }
```

Probe `fc3/p2.sh` at HEAD, all `rc=1 odd=[error] n=0`: before resolve_main; MAIN_BY_NAME emptied; MAIN_SHA emptied with MAIN_BY_NAME=1; `../<path>`; absent path; symlinked briefs dir (notdir); missing blob object under `set -euo pipefail`. Under `set -eu` only, the missing blob gives `rc=0 odd=[] n=0` and check_brief prints `its first Status: line is not exactly …`. The odd/unbalanced arms are covered by test 66 (`refused [odd 2 fence] 0`, `refused [unbalanced 2] 0`).

Command: `timeout 120 bash fc3/p2.sh` (cwd fc3), exit 0, 2026-10-05T11:37Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `fc3/logs/p2.txt`

---

## Claim 18: "Call it in the caller's own shell: it sets globals."

**Location:** `scripts/lib/dev-cycle-read.sh:287-288`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that BRIEF and BRIEF_ODD are globals (`declare -gA BRIEF=(); BRIEF_ODD=""`) assigned without `local`; does not establish anything about `$(brief_fields …)` callers (none exist).
**Legibility-target:** for-orchestrator-synthesis

`declare -gA BRIEF=(); BRIEF_ODD=""` (`:288`); `local out l` only (`:290`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:288-291`

---

## Claim 19: "The whole blob is read (no early exit: SIGPIPE under pipefail)."

**Location:** `scripts/lib/dev-cycle-read.sh:293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the awk program (no `exit` statement); does not establish timing on huge blobs.
**Legibility-target:** for-orchestrator-synthesis

The awk program at `:295-301` has only pattern-action rules and an END block, no `exit` (paraphrased — no quote available because the claim covers absence of a statement).

**Evidence:** `scripts/lib/dev-cycle-read.sh:295-301`

---

## Claim 20: check_brief comment: Status from brief_fields "must be exactly "Status: open|done|dropped" … neither is one stored as anything but a regular file under plain directories (main_entry). "new" when the default branch has no file at that path"

**Location:** `scripts/lib/dev-cycle-read.sh:311-318`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main_entry case block and the exact-Status regex; does not establish the commit-selection rule at `:350-356` (unchanged by this diff).
**Legibility-target:** for-orchestrator-synthesis

`absent) echo "ok $a new"`, `notdir\ *) … is not a directory on the default branch`, `*) … not a regular file on the default branch` (`:332-336`); `[[ ! "$st" =~ ^Status:\ (open|done|dropped)$ ]]` (`:347`). Tests 65/66 and `fc3/pc.sh` pass/agree.

**Evidence:** `scripts/lib/dev-cycle-read.sh:319-358`, `fc3/logs/pc.txt`

---

## Claim 21: check_brief `error) echo "skip $a: the brief could not be read from the default branch"`

**Location:** `scripts/lib/dev-cycle-read.sh:341`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one reachable source (the blob read failing); the other brief_fields error sources (no main by name, pathform, non-blob) are caught earlier in check_brief (`:322`, `:323`, `:330-337`), so the wording fits every case that reaches it.
**Legibility-target:** for-orchestrator-synthesis

Missing blob via dev-cycle.sh: HEAD → `skip docs/working/briefs/2026-01-03-gone.md: the brief could not be read from the default branch`; 2da477b7 → `… its first Status: line is not exactly …` (`fc3/logs/p67.txt`).

Command: `timeout 120 bash fc3/p67.sh` (cwd fc3), exit 0, 2026-10-05T11:46Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:319-345`, `fc3/logs/p67.txt`

---

## Claim 22: check_answer comment: reads both files "on the default branch's commit, never the working tree … A file stored as anything but a regular file under plain directories there is not read (main_entry). It reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED."

**Location:** `scripts/lib/dev-cycle-read.sh:539-544`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers no need_root, no `skipped` call and main-only reads; does not establish the D8 plan rationale (a design claim).
**Legibility-target:** for-orchestrator-synthesis

Same fixture as test 63, ROOT_REAL set at the top: main's lib → `skip Q-1: … is not a plain file or directory …` and `skipped=1`; 2da477b7 and HEAD → `skip Q-1: … is not a regular file on the default branch …` and `skipped=0` (`fc3/logs/p9.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `fc3/logs/p9.txt`

---

## Claim 23: "A failed read is a skip, never a fall-through to the other file."

**Location:** `scripts/lib/dev-cycle-read.sh:558-560`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers questions.md and archive blobs missing, under `set -euo pipefail`; does not hold without pipefail (`set -eu` only: a missing questions.md blob falls through to the archive and prints `keep Q-1`), and git's own `fatal: … bad file` still reaches stderr next to the skip.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/dev-cycle-read.sh:559-561
    r="$(git cat-file blob "$MAIN_SHA:$f" | env LC_ALL=C awk -v id="$a" "$FENCE_AWK$ANSWER_AWK")" \
      || { echo "skip $a: $f could not be read from the default branch"; return; }
    [[ -n "$r" ]] || continue
```

(excerpt ends :561; enclosing check_answer() continues to :573 — read.) `fc3/p3.sh` via dev-cycle.sh: questions.md blob gone + archive ANSWERED [1] → `skip Q-1: docs/working/questions.md could not be read …` (2da477b7: exit 128, no stdout; main: `keep Q-1` from the working tree); archive blob gone, questions.md without the entry → skip naming the archive; archive blob gone, questions.md with the answer → skip (not `drop`). Normal cases (OPEN, both files, drop, dup, done, unrecognized, no entry, bad ID) print identically at HEAD, 2da477b7 and main except main's no-entry wording. Without pipefail: `bash -c 'set -eu; source …; resolve_main; check_answer Q-1'` → `keep Q-1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `fc3/logs/p3.txt`

---

## Claim 24: "it reads `questions.md` and `questions-archive.md` from the default branch's commit, so an answer, or an archive move, made only in the working tree is not seen until it lands (it reads `open`, or no such entry)"

**Location:** `skills/dev-cycle/SKILL.md:292-295`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main-commit read and the answer case (open / no such entry); the parenthetical does not cover an archive move of an answer that has already landed, which reads that answer (`keep`), not `open` or no entry.
**Legibility-target:** for-author

`fc3/p3.sh`: answer committed on main, then the entry moved to the archive only in the working tree → HEAD `keep Q-1`. The mechanism (moves are not seen until they land) holds; only the listed outcomes are incomplete. Precise version: "(it reads what main holds: `open` or no such entry for an answer not yet landed)". A8's original mismatch ("once step 1 has archived") is gone.

**Evidence:** `skills/dev-cycle/SKILL.md:289-299`, `fc3/logs/p3.txt`

---

## Claim 25: "A questions.md that is not plain is reported, not passed over to the archive."

**Location:** `test/scripts/dev-cycle.bats:650`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the committed symlink case (now `git add -A && git commit -qm link`); does not establish a symlink only in the working tree (not read by design).
**Legibility-target:** for-orchestrator-synthesis

The assertion expects `skip Q-100: docs/working/questions.md is not a regular file on the default branch*`, and the test passes (`fc3/logs/bats-head.txt`).

**Evidence:** `test/scripts/dev-cycle.bats:648-656`, `fc3/logs/bats-head.txt`

---

## Claim 26: T34 comments: "Answered only in the working tree: still open (D8 …)", "Committed only on another branch: still open", "A working tree with no questions file at all reads main's."

**Location:** `test/scripts/dev-cycle.bats:1122-1134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three states as asserted; does not establish build-loop.sh's side (override-log T34 row, settled).
**Legibility-target:** for-orchestrator-synthesis

Test passes at HEAD (ok 60); `fc3/p3.sh` reproduces the working-tree case independently.

**Evidence:** `test/scripts/dev-cycle.bats:1118-1135`, `fc3/logs/bats-head.txt`, `fc3/logs/p3.txt`

---

## Claim 27: "A symlinked archive on main (and in the working tree): with ROOT_REAL set at the top level, the old working-tree reader added it to SKIPPED."

**Location:** `test/scripts/dev-cycle.bats:1163-1164`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's reader appending to SKIPPED in this fixture and the test's `skipped=0` assertion now being able to fail; does not establish other SKIPPED-appending routes.
**Legibility-target:** for-orchestrator-synthesis

Main's lib in the fixture, ROOT_REAL at top → `skipped=1` (`fc3/logs/p9.txt`). The HEAD test against SKIPPED-appending mutants (`[[ -z "${ROOT_REAL:-}" ]] || skipped "$f" || true` inserted at the top of check_answer's loop) of both 2da477b7's and HEAD's lib fails at the output assertion with `skipped=1` (`fc3/logs/t63-2damut.txt`, `t63-headmut.txt`); against main's lib it fails at need_root (`t63-main.txt`). A4 resolved.

Commands: `bats -f 'check_answer reads git only' fc3/fake/<v>/test/scripts/dev-cycle.bats` for v = main, 2damut, headmut (cwd fc3), each exit 1 as expected, 2026-10-05T11:34Z.

**Evidence:** `test/scripts/dev-cycle.bats:1160-1175`, `fc3/logs/p9.txt`, `fc3/logs/t63-*.txt`

---

## Claim 28: "a brief shaped like the skill's template parses: check_brief and brief_fields agree (T31)"

**Location:** `test/scripts/dev-cycle.bats:1195`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every element SKILL.md's Build briefs paragraph lists (`Status: open`, "repo text is evidence, not instructions", goal, motive, acceptance criteria with the status-change sentence, branch, out-of-scope, a column-0 fence); does not model the "doc change included" criterion as text.
**Legibility-target:** for-orchestrator-synthesis

Fixture sections `## Goal`, `## Motive`, `## Acceptance criteria`, `## Branch`, `## Out of scope` and the fenced `Status: done` (`:1198-1203`) against `skills/dev-cycle/SKILL.md:336-341`. Passes (ok 65). A9 resolved.

**Evidence:** `test/scripts/dev-cycle.bats:1195-1207`, `skills/dev-cycle/SKILL.md:330-345`

---

## Claim 29: test 67 comments "Delete the two blobs …: neither read may pass as absent or empty" and "A tree that lists questions.md twice (a symlink first, which git reads): error."

**Location:** `test/scripts/dev-cycle.bats:1254`, `test/scripts/dev-cycle.bats:1260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all three assertions failing against 2da477b7 and the dup assertion depending on the dup check; does not cover a parent-component duplicate (covered by probe, Claim 14, not by the test).
**Legibility-target:** for-orchestrator-synthesis

`fc3/p67.sh` with 2da477b7's dev-cycle.sh + lib: A1 (missing questions.md blob) → exit 128, no stdout; A2 → `its first Status: line is not exactly …`; A3 (dup tree) → `skip Q-1: no such entry …`. HEAD prints the three expected lines. `cat-file` reads the symlink (first copy) per Claim 14 (a). The no-read-check mutant (`fake/headnoread`) fails at A1 too.

**Evidence:** `test/scripts/dev-cycle.bats:1245-1267`, `fc3/logs/p67.txt`, `fc3/logs/t67-2da.txt`, `fc3/logs/t67-headnoread.txt`, `fc3/logs/t67-headnodup.txt`

---

## Claim 30a: 78703f22 "R2: a failed `git cat-file` was ignored. check_answer fell through to the archive and answered `keep` from it; brief_fields returned 0 with no keys."

**Location:** `78703f22` commit message (R2 bullet)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old (2da477b7) behavior; the `keep` fall-through occurs when check_answer runs inside `$(...)` (the lib header's documented capture), while dev-cycle.sh's direct call instead aborted (exit 128, no output) under `set -e`; brief_fields returned 0 with no keys in both forms.
**Legibility-target:** for-author

2da477b7 lib, `out="$(check_answer Q-1)"` under `set -euo pipefail` → `keep Q-1`; `bash dev-cycle.sh --check-answer Q-1` → rc 128, empty stdout (`fc3/logs/p3.txt`). brief_fields at 2da477b7 with a missing blob → `rc=0 odd=[] n=0` (`fc3/logs/p2.txt`). The rubric's R2 row names the `$(...)` pattern; the commit drops that qualifier. History; low impact.

**Evidence:** `fc3/logs/p3.txt`, `fc3/logs/p2.txt`

---

## Claim 30b: 78703f22 "Both now test the read: check_answer skips ("could not be read from the default branch"), brief_fields returns 1 with BRIEF_ODD "error" and check_brief skips."

**Location:** `78703f22` commit message (R2 bullet)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 17, 21, 23 (pipefail-dependent).
**Legibility-target:** for-orchestrator-synthesis

See Claims 17, 21, 23 (paraphrased — no quote available because the evidence is the executed outputs already quoted there).

**Evidence:** `fc3/logs/p2.txt`, `fc3/logs/p3.txt`, `fc3/logs/p67.txt`

---

## Claim 31: 78703f22 "A12: main_entry kept the last ls-tree line for a name listed twice, while git's reads take the first, so a symlink listed before a blob read as blob. A name listed twice is now "error". ls-tree's own stderr is dropped (C9)."

**Location:** `78703f22` commit message (A12 bullet)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old last-wins map (`while … do [[ -n "$path" ]] && m["$path"]=…` at 2da477b7), the new error, and the added `2>/dev/null`; does not establish how such trees arise in practice (needs `mktree`/`--literally`).
**Legibility-target:** for-orchestrator-synthesis

`git diff 2da477b7 78703f22` shows `out="$(git ls-tree … "$1" 2>/dev/null)"` and the dup check. 2da477b7 on the dup tree reads the symlink (`no such entry`, Claim 29); HEAD → `error` (Claim 14).

**Evidence:** `scripts/lib/dev-cycle-read.sh:263-269`, `fc3/logs/p1.txt`, `fc3/logs/p67.txt`

---

## Claim 32: 78703f22 "A13: brief_fields checks its own preconditions (main by name, pathform, a blob on main), so a later caller cannot read the index's copy through an empty MAIN_SHA."

**Location:** `78703f22` commit message (A13 bullet)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the empty-MAIN_SHA case and the three preconditions; does not establish a MAIN_SHA from another repo (row 208, settled).
**Legibility-target:** for-orchestrator-synthesis

2da477b7's brief_fields with `MAIN_SHA=""` (or before resolve_main) returned `status=[Status: open]` from the index (`git cat-file blob ":path"`); HEAD → `rc=1 odd=[error]` (`fc3/logs/p2.txt`). A13 resolved.

**Evidence:** `scripts/lib/dev-cycle-read.sh:292`, `fc3/logs/p2.txt`

---

## Claim 33: 78703f22 "A4: the SKIPPED test now calls check_answer with ROOT_REAL set at the top level and a symlinked archive on main, so a reader that adds to SKIPPED fails it (checked by mutation)."

**Location:** `78703f22` commit message (A4 bullet)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the property (independently re-checked by mutation, Claim 27); does not establish the author's own mutation run.
**Legibility-target:** for-orchestrator-synthesis

See Claim 27 (paraphrased — no quote available because the evidence is the mutant runs logged there).

**Evidence:** `fc3/logs/t63-2damut.txt`, `fc3/logs/t63-headmut.txt`

---

## Claim 34: 78703f22 "A5-A8: comment and SKILL.md wording (the second caller does not exist yet; CR, NUL and BOM refusals apply anywhere; brief_fields' values are the line but its trailing CR; archive moves count only once landed). A9: the template test brief gains its Motive section and is named "shaped like" the template."

**Location:** `78703f22` commit message (A5-A9 bullets)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each reworded line now matching the code (Claims 6, 10, 16, 24, 28); A8's new SKILL.md text has its own residue (Claim 24, Mostly accurate).
**Legibility-target:** for-orchestrator-synthesis

See the cited claims (paraphrased — no quote available because each sub-item is verdicted with quotes in its own claim).

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `:173-176`, `:280-282`, `skills/dev-cycle/SKILL.md:292-295`, `test/scripts/dev-cycle.bats:1195-1200`

---

## Claim 35: 78703f22 "C1: --check-answer's help names the unreadable-tree skip."

**Location:** `78703f22` commit message (C1 bullet)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the added text at `scripts/dev-cycle.sh:69-70`; does not establish that --help still prints the whole header — this edit pushed the Exit line out of `sed -n '2,80p'` (Claim 5, Incorrect).
**Legibility-target:** for-orchestrator-synthesis

`#             under plain directories on the default branch, or a default` / `#             branch whose tree or file could not be read).` (`scripts/dev-cycle.sh:69-70`).

**Evidence:** `scripts/dev-cycle.sh:66-71`, `fc3/logs/help.txt`

---

## Claim 36: 78703f22 "Override-log rows for A10, A11, C2-C8 and C10."

**Location:** `78703f22` commit message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rows' existence; does not re-judge them (settled).
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/override-log.md:222` (A10, "c8435580's Notes say a working-tree-only answer reads open …"), `:223` (A11, "2da477b7 says "every reader skips" a NUL file …"), `:224-230` (C2-C8), `:231` (C10).

**Evidence:** `docs/reviews/override-log.md:220-231`

---

## Claim 37: 78703f22 Notes "The reviewer routed R2, A12 and A13 to "you: judgment" because they set the contract U1b/U1c code against"

**Location:** `78703f22` commit message (Notes)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The rubric committed at 2da477b7 and 78703f22 contains no "judgment" routing for these rows; the routing may have been in the orchestrator's message, which is not in the repo.
**Legibility-target:** for-orchestrator-synthesis

`git show 78703f22:docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1a.md | grep -i judgment` → no hits (paraphrased — no quote available because the claim covers absence of grep results). Needed: the iteration-2 orchestrator transcript.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1a.md`

---

## Claim 38: 722884c7 "The lite fix-drift check on 78703f22 found the duplicate-name comment read as if the lib followed git's first-copy rule, and brief_fields' error list left out main_entry's error. Comments only."

**Location:** `722884c7` commit message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff (two comment hunks) and the two wordings it replaced; does not establish the fix-drift check's own output.
**Legibility-target:** for-orchestrator-synthesis

`git diff 722884c7~1 722884c7` changes only comment lines: `-# twice, which git's own reads resolve to the first copy: never read as absent)` and `-# default branch found by name, a path pathform refuses, no regular file there` / `-# on main by main_entry, …` (the old list did not name main_entry's `error`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:251-254`, `:284-286`

---

## Claim 39: 722884c7 Notes "Run on a code-only commit object; the review artifacts made the branch range too large for the lite check."

**Location:** `722884c7` commit message (Notes)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** A process claim about how a review was run; no repo artifact records it.
**Legibility-target:** for-orchestrator-synthesis

No committed artifact names the lite run (paraphrased — no quote available because the claim covers absence of a record). Needed: the fix-drift run's transcript.

**Evidence:** `722884c7`

---

## Claim 40: 2da477b7 "R1/A1: … FENCE_AWK now refuses any line holding a NUL byte" and "A2: main_entry printed "absent" when ls-tree failed, which check_brief turned into "ok ... new". It now prints "error" …, and both callers skip."

**Location:** `2da477b7` commit message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL and unreadable-tree cases against c8435580; the "every reader skips" sentence is override-log A11 (settled).
**Legibility-target:** for-orchestrator-synthesis

Unreadable briefs tree object: c8435580 → `ok docs/working/briefs/2026-01-03-g.md new`; 2da477b7 and HEAD → `skip …: the default branch's tree could not be read`. NUL brief: c8435580 `Status: open`, HEAD `refused odd 1 nul` (`fc3/logs/pc.txt`).

**Evidence:** `fc3/logs/pc.txt`

---

## Claim 41: c8435580 "check_brief also skips a brief whose directory is not a directory on main (before, ls-tree printed nothing and it read as "new")."

**Location:** `c8435580` commit message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a symlinked `docs/working/briefs` on main; the Notes' "reads … as open" is override-log A10 (settled).
**Legibility-target:** for-orchestrator-synthesis

main → `ok docs/working/briefs/2026-01-03-g.md new`; c8435580 and HEAD → `skip …: docs/working/briefs is not a directory on the default branch` (`fc3/logs/pc.txt`).

**Evidence:** `fc3/logs/pc.txt`

---

## Iteration-2 items

| Item | Status | Executed evidence |
|---|---|---|
| R2 (failed cat-file swallowed) | Resolved (under the `-euo pipefail` contract) | Claims 17, 21, 23, 29: missing questions.md blob → skip at HEAD (2da477b7: `keep` via `$(...)`, abort via dev-cycle.sh); missing brief blob → `the brief could not be read`. Residue: without pipefail both readers still fall through (`keep Q-1`, rc=0 no keys) — the lib header's contract requires pipefail, and dev-cycle.sh sets it. |
| A4 (skipped=0 could not fail) | Resolved | Claim 27: mutants of 2da477b7's and HEAD's lib fail the test with `skipped=1`. |
| A5 (lib header names two suites) | Resolved | Claim 6. |
| A6 (FENCE_AWK NUL/CR/BOM placement) | Resolved | Claim 10 (`odd 3 cr`, `odd 3 nul` inside fences). |
| A7 ("line as stored" vs CR) | Resolved | Claim 16. |
| A8 (SKILL.md "once step 1 has archived") | Resolved, new residue | Claim 24 (Mostly accurate: an unlanded archive move of a landed answer reads the answer, not open/no entry). |
| A9 (template test) | Resolved | Claim 28. |
| A12 (last vs first copy) | Resolved | Claims 14, 29, 31: leaf and parent duplicates → `error`; dup-check mutant fails test 67. |
| A13 (brief_fields preconditions) | Resolved | Claims 17, 32: empty MAIN_SHA / no main / pathform / non-blob → `rc=1 error`. |
| A10, A11 | Override-log rows exist | `docs/reviews/override-log.md:222`, `:223` (Claim 36). |
| C1 (help names unreadable-tree skip) | Resolved, but introduced a regression | Claims 35 and 5: the added line moved the Exit line out of `sed -n '2,80p'`. |

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`scripts/dev-cycle.sh:111`): `sed -n '2,80p'` now cuts the header's last line (`:81`, the Exit/default-branch line) from --help since 78703f22; change it to `2,81p`.

### Stale
- None.

### Mostly Accurate
- **Claim 24** (`skills/dev-cycle/SKILL.md:292-295`): "(it reads `open`, or no such entry)" leaves out an unlanded archive move of an already-landed answer, which reads that answer; say it reads what main holds.
- **Claim 30a** (`78703f22` message, R2): the `keep` fall-through happened under `$(...)` capture; dev-cycle.sh's direct call aborted with exit 128. History only.

### Unverifiable
- **Claim 37** (`78703f22` Notes): "routed … to you: judgment" not in any committed rubric; needs the orchestrator transcript.
- **Claim 39** (`722884c7` Notes): how the lite fix-drift check was run; needs its transcript.

## Goal-Alignment Note

- **Goal served:** Decide whether feat/build-loop-u1a at 722884c7 is clean enough to merge (final confirming pass), by fact-checking every claim in the code diff and commit messages, executing where possible.
- **What this report establishes:** All nine iteration-2 code items (R2, A4-A9, A12, A13) are resolved by execution against 2da477b7 and mutants; one new defect: the C1 help edit made --help drop the header's last line (Claim 5, Incorrect, high, executed). Two Mostly-accurate wording items (SKILL.md parenthetical; a commit message's missing qualifier).
- **What it does not establish:** behavior without `pipefail` (both read-failure checks rely on it, per the caller contract); awk variants beyond the installed one; build-loop.sh (not yet written).
- **Escalate:** Claim 5 is a for-author fix (one character, `2,80p` → `2,81p`) and blocks a "clean" verdict under the loop's rules unless the orchestrator overrides it; Claim 24 is a one-line SKILL.md tightening. No hallucination-pattern candidates.
