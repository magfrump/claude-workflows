Commit: 722884c7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1a (claude-workflows, branch feat/build-loop-u1a)
**Scope:** `git diff main...feat/build-loop-u1a -- . ':!docs/reviews'` at 722884c7: scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md and test/scripts/dev-cycle.bats, plus the bodies of `git log main..feat/build-loop-u1a` (d6426e3e, c8435580, 2da477b7, 78703f22, 722884c7). This is replicate fc2 of the final confirming pass (iteration 3).
**Checked:** 2026-10-05
**Total claims checked:** 47
**Summary:** 43 verified, 2 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) first. No claim matches a logged pattern, and this run found no new fabrication (see the end of the report).

Execution logs: every log is under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i3/fc2/logs/` (abbreviated `$L/` below). Probes ran in throwaway repos under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1a-i3/fc2/` (`$S/`), with `GIT_CONFIG_GLOBAL=/dev/null` and HOME set inside the scratch dir. Old revisions were materialised with `git archive <rev> scripts test | tar -x -C $S/old/<rev>`. Tools: git 2.39.5, mawk 1.3.4.

**Suite run.** Command: `TMPDIR=$S bats test/scripts/dev-cycle.bats`, with `LC_ALL=C.UTF-8` set, run from cwd /workspace/.claude/wt-build-loop-u1a at 2026-10-05T11:32:50Z. It exited 1 with 66 of 67 passing. The one failure is test 21 ("an origin/HEAD naming an option-like branch"), and the cause is the environment: git refuses `refs/heads/--output=$TMPDIR/...` because the scratch path has a `/.claude` component. The orchestrator confirmed it passes with TMPDIR unset. Test 21 is outside this diff and is not a finding. Output: `$L/bats-head.txt`.

---

## Claim 1: "--check-brief ... skip ... a stray carriage return, a NUL byte, or a byte-order mark on line 1"

**Location:** `scripts/dev-cycle.sh:42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a NUL-holding brief committed on main being skipped by `--check-brief`. It does not establish NUL handling in the digest's own readers (settled by override row 223, A11).

Test 64 asserts `"skip $b: line 2 holds a NUL byte, so the brief is not read"` (`test/scripts/dev-cycle.bats:1183`), and it passed in the suite run. The refusal comes from `if (index(l, "\0")) { refuse("nul"); return 1 }` (`scripts/lib/dev-cycle-read.sh:216`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `test/scripts/dev-cycle.bats:1177-1193`, `$L/bats-head.txt`

---

## Claim 2: "--check-answer ... read from docs/working/questions.md or its archive on the default branch's commit (an answer only in the working tree reads open, or no such entry, until it is committed there)"

**Location:** `scripts/dev-cycle.sh:56-58`
**Type:** Behavioral
**Verification mode:** executed
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers two cases: an answer written in the working tree to an entry that is OPEN on main (reads `open`), and an entry that exists only in the working tree (reads no such entry). It does not cover re-answering an entry that is already ANSWERED on main, which reads main's older answer.

Command: `bash $S/old/722884c7/scripts/dev-cycle.sh --check-answer Q-1 Q-2 Q-3`, run from cwd `$S/p5` at 2026-10-05T11:37:07Z, exit 0. Main holds Q-1 ANSWERED [1] and Q-2 OPEN. The working tree answers Q-2, adds Q-3, and moves Q-1 to the archive. Output: `keep Q-1`, `open Q-2`, `skip Q-3: no such entry ... on the default branch`. The reads come from `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:559`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-572`, `$L/wt-only-outcomes.txt`

---

## Claim 3: --check-answer's skip-reason list ("no such entry, a duplicate heading, ... a NUL byte, ... a questions file that is not a regular file under plain directories on the default branch, or a default branch whose tree or file could not be read")

**Location:** `scripts/dev-cycle.sh:61-70`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every skip message check_answer can print through `--check-answer`. It does not establish the wording of any message beyond whether the list names its cause.

Every message this branch adds is in the list: NUL, not a regular file, notdir ("under plain directories"), and the unreadable tree or file. Two reasons are missing:
- **`skip abc: not a question ID (Q- and digits)`** (`scripts/lib/dev-cycle-read.sh:547`) is not listed. This gap is inherited from main.
- **The two-files case** (`skip Q-4: an entry with this heading in both ... and ...`, `:568`) is covered only loosely by "a duplicate heading".

Both messages were printed by the probe run (`$L/probe2.txt`, "normal answers" block). The probe command was `TMPDIR=$S bash $S/probe2.sh`, cwd `$S`, at 2026-10-05T11:35:39Z, exit 0. The "no default branch" message cannot be reached through dev-cycle.sh, which exits 1 at `:191-192`. A precise version would add "an argument that is not a question ID" and "an entry in both files".

**Evidence:** `scripts/dev-cycle.sh:61-70`, `scripts/lib/dev-cycle-read.sh:547-572`, `$L/probe2.txt`

---

## Claim 4: "--check-brief, --check-branch and --check-answer need a default branch found by name (origin/HEAD, main or master): they read its commit."

**Location:** `scripts/dev-cycle.sh:71-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit-1 guard for the three modes. It does not cover the other check modes, which do not read main (Claim 7).

The guard reads `if [[ "$CHECK" == --check-brief || "$CHECK" == --check-branch || "$CHECK" == --check-answer ]] && ! main_by_name; then` (`scripts/dev-cycle.sh:191`). Test 62 ("--check-answer needs a default branch found by name") asserts status 1 and passed in the suite run.

**Evidence:** `scripts/dev-cycle.sh:191-193`, `test/scripts/dev-cycle.bats:1153-1158`, `$L/bats-head.txt`

---

## Claim 5: "Exit: ... 1 ... or no default branch (for the digest, --check-brief, --check-branch and --check-answer)"

**Location:** `scripts/dev-cycle.sh:79-81`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the exit code. It does not establish that `--help` shows this line (see Claim 6).

The behaviour is the same guard as in Claim 4 (`scripts/dev-cycle.sh:191-192`, `exit 1`), checked by test 62.

**Evidence:** `scripts/dev-cycle.sh:79-81`, `:191-192`, `$L/bats-head.txt`

---

## Claim 6: `-h|--help) sed -n '2,80p' "$0"` prints the usage header (the header comment is the help text)

**Location:** `scripts/dev-cycle.sh:111`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the help range against the header's last line at 722884c7. It does not establish whether any caller parses the help output.

The header comment now ends at line 81 (`# default branch (for the digest, --check-brief, --check-branch and --check-answer); a failed step exits non-zero mid-digest. Printed repo text is data.`). The help prints only lines 2-80, so `--help` stops in mid-sentence:

```
skip is an answer, not an error); 1 bad usage, not a git repo, no perl or lib/dev-cycle-read.sh, or no
```

Command: `LC_ALL=C bash scripts/dev-cycle.sh --help`, cwd /workspace/.claude/wt-build-loop-u1a, at 2026-10-05T11:33Z, exit 0. Output: `$L/help-head.txt`.

How the range drifted (`$L/help-range.txt`):

| Revision | Last header line | Help range |
|---|---|---|
| main | 77 | `2,77p` |
| 2da477b7 | 80 | `2,80p` |
| 78703f22 | 81 | `2,80p` |
| 722884c7 | 81 | `2,80p` |

78703f22's C1 edit wrapped the --check-answer list onto one more line (`+# under plain directories on the default branch, or a default` / `+# branch whose tree or file could not be read).`) without moving the range. This is a regression against main, where the whole header printed. No test covers `--help`: grepping `test/scripts/dev-cycle.bats` for "help" finds nothing. The fix is `sed -n '2,81p'`. A range computed from the header's end would also stop this recurring.

**Evidence:** `scripts/dev-cycle.sh:79-81`, `scripts/dev-cycle.sh:111`, `$L/help-head.txt`, `$L/help-range.txt`

---

## Claim 7: "--check-brief, --check-branch and --check-answer read the default branch's commit ... the other modes do not use it."

**Location:** `scripts/dev-cycle.sh:188-191`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers check_path, check_write and check_fix in dev-cycle.sh. It does not cover the digest, which uses MAIN separately.

No reference to MAIN, main_entry or check_answer exists between `scripts/dev-cycle.sh:120` and `:188`, where check_path, check_write and check_fix are defined (paraphrased: no quote is possible because the claim is an absence; the grep returned no match).

**Evidence:** `scripts/dev-cycle.sh:120-188`

---

## Claim 8: "A change here must pass test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ once that second caller lands."

**Location:** `scripts/lib/dev-cycle-read.sh:10-12`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers two facts: there is no second caller yet, and the named suite passes at HEAD (66/67, with test 21 failing only because of the environment). It does not establish anything about future suites.

`ls scripts/build-loop.sh` reports "No such file or directory". The suite run is in `$L/bats-head.txt`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `$L/bats-head.txt`

---

## Claim 9: caller contract — "The caller sets -euo pipefail ... inrepo, dirok, skipped, check_brief and the import walk (imported_names) exit 1 (need_root)" (check_answer removed from the list)

**Location:** `scripts/lib/dev-cycle-read.sh:12-17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the following:
- check_answer, main_entry and brief_fields no longer call need_root.
- dev-cycle.sh sets pipefail.
- The R2 read-failure detection depends on pipefail.

It does not establish behaviour for a future caller that skips pipefail.

- **dev-cycle.sh sets the option.** `set -euo pipefail` is at `scripts/dev-cycle.sh:83`.
- **check_answer needs no ROOT_REAL.** Test 63 calls check_answer without ROOT_REAL and passes.
- **The R2 detection depends on pipefail.** With the blob deleted, `brief_fields` returns `rc1 [error]` under `set -euo pipefail` but `rc0 keys=0` under `set -eu` (`$L/probe2.txt`, "missing blob" lines; command `TMPDIR=$S bash $S/probe2.sh`, cwd `$S`, 2026-10-05T11:35:39Z, exit 0).

The R2 fix therefore holds only under the stated contract.

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-17`, `:295-302`, `:559-560`, `scripts/dev-cycle.sh:83`, `$L/probe2.txt`

---

## Claim 10: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:21-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each function's first guard. It does not cover a MAIN_SHA from another repo (settled by override row 208).

The guard is `if ! main_by_name; then echo "skip $a: no default branch found by name ...` (`:548`, and likewise `:322` and `:370`). Test 63's first expected line is that skip, printed before resolve_main runs, and the test passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:322`, `:370`, `:548`, `test/scripts/dev-cycle.bats:1167-1174`

---

## Claim 11: "Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields read the default branch's commit, never the working tree (check_brief also refuses a brief path that is not plain in the working tree, which the cycle writes)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers "never the working tree" for all five functions. It does not cover check_branch's reads, which also take `refs/heads/<name>` and not only main's commit.

- **The working tree is never read.** The reads go through `git ls-tree ... "$MAIN_SHA"` (`:263`) and `git cat-file blob "$MAIN_SHA:$f"` (`:295`, `:559`). Test 66 writes `Status: dropped` into the working tree after committing, and still reads `status=[Status: open]` (passed).
- **The working-tree check stays in check_brief.** `if [[ -n "$(blocker "$a" file)" ]]` is at `:327`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:263`, `:295`, `:327`, `:559`, `test/scripts/dev-cycle.bats:1219-1228`

---

## Claim 12: FENCE_AWK — "and anywhere in the file, fenced or not, a carriage return inside a line ..., a NUL byte ..., or a byte-order mark on line 1" (others only outside a fence)

**Location:** `scripts/lib/dev-cycle-read.sh:173-176`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers CR and NUL inside a fence being refused, and html, comment and refdef shapes inside a fence being read. The BOM check applies only to line 1, which cannot be inside a fence. It does not establish awk implementations other than mawk (settled by override row 224, C2).

The CR, NUL and BOM checks run before `if (infence)` (`:215-218`). Probe results (`$L/probe2.txt`, FENCE_AWK block; same command and run as Claim 9):

| Line inside a fence | Result |
|---|---|
| CR | `skip Q-1: line 5 ... holds a carriage return` |
| NUL | `skip Q-1: line 5 ... holds a NUL byte` |
| `<div>` | `keep Q-1` |
| `<!-- open` | `keep Q-1` |
| `[a]: b` | `keep Q-1` |

**Evidence:** `scripts/lib/dev-cycle-read.sh:213-229`, `$L/probe2.txt`

---

## Claim 13: "$(...) drops NUL, so a printed line would not be the line read"

**Location:** `scripts/lib/dev-cycle-read.sh:216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reason for the refusal and the refusal itself. It does not establish anything about readers outside the lib.

Test 64 commits `Status: op\0en` and expects `refused [odd 2 nul] 0` from brief_fields. It passed. Bash's `$(...)` dropping NUL is the behaviour R1 recorded at c8435580 (iteration 1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:216`, `test/scripts/dev-cycle.bats:1177-1193`

---

## Claim 14: "check_brief, check_branch and check_answer read its commit, so they answer only when it was found by name"

**Location:** `scripts/lib/dev-cycle-read.sh:242-244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** The same guard as Claim 10, with the same residue.

The guards are at `:322`, `:370` and `:548`. Tests 41 and 62 passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:242-246`, `$L/bats-head.txt`

---

## Claim 15: main_entry prints "blob" (100644/100755), "absent", "notfile", "notdir PART" or "error"

**Location:** `scripts/lib/dev-cycle-read.sh:247-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each output word. It does not cover gitlinks by execution (notfile by the case's `*` arm; override row 230, C8).

The classifying lines are `case "${m[$p]-}" in '') echo absent; return ;; 040000) ;; *) echo "notdir $p"; return ;; esac` and `case "${m[$1]-}" in '') echo absent ;; 100644|100755) echo blob ;; *) echo notfile ;; esac` (`:270-273`). The probe and tests reach each word:

| Output | Reached by |
|---|---|
| `blob` | `$L/probe1.txt` (d) |
| `absent` | brief_fields on an absent path (`$L/probe2.txt`) |
| `notfile` | test 61 symlink |
| `notdir docs/working` | test 61 |
| `error` | test 64 and `$L/probe1.txt` |

**Evidence:** `scripts/lib/dev-cycle-read.sh:258-274`, `$L/probe1.txt`, `$L/probe2.txt`

---

## Claim 16: "error (... or the tree lists a name twice; git's own reads would take the first copy, which may not be the one a check saw, so this answers error instead; never read as absent)"

**Location:** `scripts/lib/dev-cycle-read.sh:252-254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers three things: git taking the first copy for `cat-file blob SHA:path`, duplicate detection at the leaf, and duplicate detection at every parent component. It does not establish how other git reads (`git show`, `git log -- path`) resolve duplicates.

Command: `TMPDIR=$S bash $S/probe1.sh`, cwd `$S`, at 2026-10-05T11:35:11Z, exit 0. mktree keeps the order it is given (ls-tree shows it), and in all four orders `cat-file` returned the first entry: blob1 then blob2 gives [1], blob2 then blob1 gives [2], symlink then blob gives `x`, and blob then symlink gives the blob. Each case printed `main_entry: error`.

Duplicates at a parent component are detected too, because the `-t` listing repeats every path under a duplicated directory. All three parent cases print `error`:
- `docs` listed twice as a tree (b)
- `docs` as a blob and a tree (b2)
- two `working` trees (b3)

The detecting line is `[[ -z "${m[$path]+set}" ]] || dup=1` (`:266`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:262-269`, `$L/probe1.txt`

---

## Claim 17: "One ls-tree call lists the path and every directory above it (-t: trees too; --full-tree: paths from the top level, whatever the current directory)", with ls-tree's stderr dropped and a failed ls-tree reading as error

**Location:** `scripts/lib/dev-cycle-read.sh:252-257`, `:263`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the following:
- one call
- parents listed
- `--full-tree` working from a subdirectory
- a missing subtree object giving exit 1 and `error`

It does not establish two things: (1) that no corruption mode makes ls-tree exit 0 with a partial listing; only a missing tree object was probed. (2) That the listing holds only those entries: it also lists the named directories' children (`docs/a.md`, `docs/other`, `docs/working/z.md`; settled by override row 220, A3).

The call is `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }` (`:263`). Probe results (`$L/probe1.txt`):
- **(c)** With the `docs/working` tree object deleted, ls-tree printed `error: Could not read ...`, exit 1, and main_entry printed `error`.
- **(d)** Run from `docs/`, main_entry printed `blob`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:263`, `$L/probe1.txt`

---

## Claim 18: "The caller has checked main_by_name and the path's form (pathform, so ls-tree prints it unquoted)."

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers all three in-repo callers. It does not establish anything about future callers, although main_entry checks main_by_name itself anyway (`:261`).

- **brief_fields** runs `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]` (`:292`).
- **check_brief** calls pathform (`:323`) before `e="$(main_entry "$a")"` (`:330`).
- **check_answer** passes constant paths after `main_by_name` (`:548-550`).

pathform allows only `[a-zA-Z0-9._/-]` (`:139-143`), which core.quotePath never quotes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:139-149`, `:261`, `:292`, `:323`, `:330`, `:548-550`

---

## Claim 19: brief_fields — "for each key, the first line outside a fence (FENCE_AWK) that starts "Status:", ... "Dispatched:", whole, after one trailing CR is dropped ... (a key with no such line stays unset), each the line as stored but for that CR"

**Location:** `scripts/lib/dev-cycle-read.sh:275-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers first-copy selection, fenced copies being skipped, the CR being dropped, and absent keys staying unset. It does not establish that values are judged anywhere; the callers judge them.

The awk keeps only the first copy of each key: `if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 }` (`:299`). The shell side stores `BRIEF["${l%%$'\t'*}"]="${l#*$'\t'}"` (`:307`). Test 66 passed with three cases:
- the fenced `Status: done` is skipped
- `Status: open\r` reads `[Status: open]`
- the later `Branch: second` is ignored

Test 65's `[unset]` branch also passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `test/scripts/dev-cycle.bats:1210-1243`

---

## Claim 20: brief_fields "Otherwise it sets no key and returns 1, with BRIEF_ODD "odd N WHY" ..., "unbalanced N" ... or "error" (no default branch found by name, a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read)"

**Location:** `scripts/lib/dev-cycle-read.sh:282-287`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every listed error source and the cleared BRIEF. The "blob could not be read" source holds under pipefail only (Claim 9).

`$L/probe2.txt` ("brief_fields error sources"; same command and run as Claim 9) gives `rc1 [error] 0` for each of these:
- no resolve_main (empty MAIN_SHA)
- `MAIN_BY_NAME` cleared
- `../x`
- an absent path
- a tree (notfile)
- `a.md/x` (notdir)
- a deleted blob

A good call followed by an error call leaves `0 keys [error]`. The odd and unbalanced outcomes are covered by test 66 (`refused [odd 2 fence] 0`, `refused [unbalanced 2] 0`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:289-310`, `$L/probe2.txt`, `test/scripts/dev-cycle.bats:1230-1243`

---

## Claim 21: "Call it in the caller's own shell: it sets globals."

**Location:** `scripts/lib/dev-cycle-read.sh:287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers BRIEF_ODD being lost when brief_fields runs in `$(...)`. It does not cover other subshell forms.

The probe prints `parent sees [] / sub said: in-sub error` (`$L/probe2.txt`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:288-291`, `$L/probe2.txt`

---

## Claim 22: "The whole blob is read (no early exit: SIGPIPE under pipefail)."

**Location:** `scripts/lib/dev-cycle-read.sh:293`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the brief_fields awk program having no `exit`. It does not cover the SIGPIPE timing on large blobs (see test 43 for check_brief's large-brief read).

The awk program's rules are `{ sub(/\r$/, "") }`, `fence($0) { next }`, the `match(...)` rule and `END {...}` (`:296-301`). None of them calls `exit`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:295-302`

---

## Claim 23: check_brief — "its Status line from brief_fields ... neither is one stored as anything but a regular file under plain directories (main_entry). "new" when the default branch has no file at that path"

**Location:** `scripts/lib/dev-cycle-read.sh:311-318`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the absent, notdir, non-blob, odd and status outcomes. It does not cover the commit lookup at `:355-357`, which is pre-existing.

The probe on a symlinked `briefs` directory on main prints `skip ...: docs/working/briefs is not a directory on the default branch` at HEAD, where main's lib printed `ok ... new` (`$L/probe2.txt`, last block). Tests 38, 43 and 65-67 passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:319-358`, `$L/probe2.txt`

---

## Claim 24: check_brief's `error)` arm: "skip $a: the brief could not be read from the default branch"

**Location:** `scripts/lib/dev-cycle-read.sh:341`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers reachability and wording. brief_fields' other error sources are caught before this arm:
- pathform at `:323`
- main_by_name at `:322`
- a non-blob at `:330-337`

So only a failed `git cat-file`, or a tree changing between the two ls-tree calls, reaches the arm, and the wording fits both.

Probe3 at HEAD prints `A2 check-brief: skip ...: the brief could not be read from the default branch` (`$L/probe3.txt`). Command: `TMPDIR=$S bash $S/probe3.sh`, cwd `$S`, at 2026-10-05T11:36:05Z, exit 0. Test 67 asserts the same line and passed.

**Evidence:** `scripts/lib/dev-cycle-read.sh:322-345`, `$L/probe3.txt`

---

## Claim 25: check_answer — "never the working tree: an answer that unblocks autonomous work must have reached main (plan D8) ... It reads only git objects, so it needs no ROOT_REAL and adds nothing to SKIPPED."

**Location:** `scripts/lib/dev-cycle-read.sh:539-544`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers no ROOT_REAL, no SKIPPED and no working-tree read. It does not verify the plan's D8 text.

- **HEAD passes test 63.** The test expects `skipped=0`.
- **A mutant that calls `skipped "$f"` fails it.** The mutant (`$S/mut-skip`, line 550 `if [[ -n "${ROOT_REAL:-}" ]]; then skipped "$f" || true; fi  # MUTANT`) fails test 63 with `skipped=1` (`$L/bats-mutants.txt`). Command: `TMPDIR=$S bats -f '...' $S/mut-skip/test/scripts/dev-cycle.bats`, cwd `$S/mut-skip`, at 2026-10-05T11:36:18Z, exit 1.

**Evidence:** `scripts/lib/dev-cycle-read.sh:545-573`, `$L/bats-mutants.txt`

---

## Claim 26: "A failed read is a skip, never a fall-through to the other file."

**Location:** `scripts/lib/dev-cycle-read.sh:558-560`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a missing questions.md blob, a missing archive blob, and the normal outcomes being unchanged against main. It holds only under pipefail (Claim 9).

**HEAD** (`$L/probe2.txt`):
- questions.md blob missing → `skip Q-1: docs/working/questions.md could not be read from the default branch`
- archive blob missing → `skip Q-1: docs/working/questions-archive.md could not be read ...`

**2da477b7 for comparison:**
- Through dev-cycle.sh (errexit on), both cases printed nothing and exited 128.
- Through `out="$(check_answer Q-1)"` (`$L/probe3.txt`), 2da477b7 gives `out=[keep Q-1]`, the R2 fall-through. HEAD gives the skip.

**Normal outcomes match main's lib.** Both libs print the same lines for open, drop, dup in one file, both files, keep from the archive, no such entry and a non-ID. The only difference is the new "on the default branch" suffix.

**Evidence:** `scripts/lib/dev-cycle-read.sh:549-573`, `$L/probe2.txt`, `$L/probe3.txt`

---

## Claim 27: "it reads `questions.md` and `questions-archive.md` from the default branch's commit, so an answer, or an archive move, made only in the working tree is not seen until it lands (it reads `open`, or no such entry)"

**Location:** `skills/dev-cycle/SKILL.md:292-295`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the outcome set for working-tree-only answers and archive moves. It does not establish the In-flight step's handling of the outcomes.

"Not seen until it lands" holds. The parenthetical, however, is not the complete set of outcomes. Take an archive move made only in the working tree, for an entry whose answer already landed in main's questions.md. That reads main's answer (`keep Q-1` in `$L/wt-only-outcomes.txt`), not `open` or no such entry. Re-answering an entry that is already ANSWERED on main likewise reads the old answer. Both outcomes are harmless: the answer read is main's.

A precise version: "(it reads main's state: `open`, no such entry, or the answer already on main)".

**Evidence:** `skills/dev-cycle/SKILL.md:292-295`, `$L/wt-only-outcomes.txt`

---

## Claim 28: "A questions.md that is not plain is reported, not passed over to the archive."

**Location:** `test/scripts/dev-cycle.bats:650`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the symlinked questions.md committed on main. It does not cover the working-tree-only symlink, which is no longer read.

Test 34 expects the prefix `"skip Q-100: docs/working/questions.md is not a regular file on the default branch"` (`:653`), and it passed.

**Evidence:** `test/scripts/dev-cycle.bats:649-654`, `$L/bats-head.txt`

---

## Claim 29: T34 test comments — "Answered only in the working tree: still open", "Committed only on another branch: still open", "A working tree with no questions file at all reads main's."

**Location:** `test/scripts/dev-cycle.bats:1122`, `:1126`, `:1131`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three assertions of test 59. It does not cover build-loop.sh (deferred; override row 221).

Test 59 passed (`$L/bats-head.txt`). Its three assertions print `open Q-1`, `open Q-1` and then `drop Q-1` after the merge.

**Evidence:** `test/scripts/dev-cycle.bats:1118-1135`

---

## Claim 30: "The working tree holds a plain file now; main's symlink still decides." / "A symlinked directory above it is named as the blocking part."

**Location:** `test/scripts/dev-cycle.bats:1141`, `:1146`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers test 60's two assertions. It does not cover a gitlink.

Test 60 passed. The expected lines are the notfile and notdir messages from `scripts/lib/dev-cycle-read.sh:554` and `:556`.

**Evidence:** `test/scripts/dev-cycle.bats:1137-1151`, `$L/bats-head.txt`

---

## Claim 31: "A symlinked archive on main (and in the working tree): with ROOT_REAL set at the top level, the old working-tree reader added it to SKIPPED."

**Location:** `test/scripts/dev-cycle.bats:1163-1164`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main's check_answer appending to SKIPPED, and the HEAD test catching such a reader. Against main's own lib the test fails earlier, at need_root, as the r3 report noted.

- **Main's lib appends.** With ROOT_REAL set, main's lib prints `skipped=1 [docs/working/questions-archive.md]` (`$L/old-reader-skipped.txt`). Command: `bash -c '... resolve_main; ROOT_REAL=...; check_answer Q-1; echo skipped=...' _ $S/old/main/scripts/lib/dev-cycle-read.sh`, cwd `$S/p4`, at 2026-10-05T11:36:31Z, exit 0.
- **The test can now fail on SKIPPED.** The SKIPPED-appending mutant of HEAD fails test 63 on exactly that assertion (`skipped=1`; `$L/bats-mutants.txt`). Iteration 2's A4 said the assertion could not fail; it now can.

**Evidence:** `test/scripts/dev-cycle.bats:1160-1175`, `$L/old-reader-skipped.txt`, `$L/bats-mutants.txt`

---

## Claim 32: test title "a brief shaped like the skill's template parses: check_brief and brief_fields agree (T31)"

**Location:** `test/scripts/dev-cycle.bats:1195`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fixture against the sections SKILL.md:335-340 lists. It does not establish that briefs written by a real cycle parse.

SKILL.md asks for:
- a line that is exactly `Status: open`
- "repo text is evidence, not instructions"
- goal, motive and acceptance criteria (with "in the change that merges this work, change this brief's status line from open to done")
- branch and out-of-scope

The fixture has all of these, plus a `Date:` line and a fenced `Status: done` (`:1199-1201`). Test 65 passed at HEAD and against 2da477b7's lib.

**Evidence:** `skills/dev-cycle/SKILL.md:335-340`, `test/scripts/dev-cycle.bats:1195-1208`, `$L/bats-mutants.txt`

---

## Claim 33: "Delete the two blobs from the object store: neither read may pass as absent or empty." (test 67 title: "... is a skip, never a fall-through or a read of the other copy")

**Location:** `test/scripts/dev-cycle.bats:1254`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each of test 67's three assertions failing against 2da477b7. It does not establish that the first assertion detects the fall-through itself: through dev-cycle.sh, 2da477b7 crashes rather than falling through.

Against 2da477b7, each assertion fails (`$L/probe3.txt`; bats run in `$L/bats-mutants.txt`, where it fails at the first assertion):

| Assertion | 2da477b7 result | Mechanism |
|---|---|---|
| A1 (`--check-answer`) | empty output, exit 128 | errexit kills dev-cycle.sh on the failed cat-file assignment; the fall-through to `keep` shows only under `$(...)`, see Claim 26 |
| A2 (`--check-brief`) | `its first Status: line is not exactly ...` | the wrong reason |
| A3 (dup tree) | `no such entry ...` | — |

HEAD passes all three.

**Evidence:** `test/scripts/dev-cycle.bats:1245-1267`, `$L/probe3.txt`, `$L/bats-mutants.txt`

---

## Claim 34: "A tree that lists questions.md twice (a symlink first, which git reads): error."

**Location:** `test/scripts/dev-cycle.bats:1260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git reading the symlink copy, and the expected message coming from duplicate detection. It does not cover blob-then-symlink in the test; probe1 (a4) covers that order.

- **Git reads the symlink copy.** probe1 (a3) shows `cat-file` returns `x`, the symlink text.
- **The message comes from duplicate detection.** In probe3, ls-tree on the dup tree exits 0. A mutant with the duplicate check removed (`$S/mut-nodup`, `: nodup` in place of `:269`) prints `skip Q-1: no such entry ...`: it takes the last line (blob), then reads the first copy (the symlink text). HEAD prints `the default branch's tree could not be read`.

**Evidence:** `test/scripts/dev-cycle.bats:1260-1266`, `scripts/lib/dev-cycle-read.sh:266-269`, `$L/probe1.txt`, `$L/probe3.txt`

---

## Claim 35: d6426e3e — "Failing tests for U1a ...; check_answer needs no ROOT_REAL and leaves SKIPPED alone; brief_fields reads ... The symlinked-questions case now commits its symlink."

**Location:** commit d6426e3e
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the commit's tests failing against its own lib, and the commit changing tests only. It does not cover passing tests in other filters.

d6426e3e changes only `test/scripts/dev-cycle.bats`, and `git diff --stat main d6426e3e -- scripts` is empty. Command: `TMPDIR=$S bats -f 'check-answer|check_answer|brief_fields' test/scripts/dev-cycle.bats`, cwd `$S/old/d6426e3e`, at 2026-10-05T11:37:29Z. All six new or changed tests fail, plus the modified test 34. The two pre-existing tests in the filter pass (`$L/bats-d6426e3e.txt`).

**Evidence:** `$L/bats-d6426e3e.txt`

---

## Claim 36: c8435580 — check_answer reads main, "skips without a default branch found by name, reads only git objects ..., dev-cycle.sh --check-answer exits 1"; "check_brief also skips a brief whose directory is not a directory on main (before, ls-tree printed nothing and it read as "new")"

**Location:** commit c8435580
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the body's behavioural bullets. The Notes' "reads ... as open" is settled by override row 222 (A10) and is not re-verdicted.

The "before" claim reproduces: main's lib prints `ok docs/working/briefs/2026-01-01-a.md new` for a symlinked briefs directory on main, and HEAD prints the notdir skip (`$L/probe2.txt`). The other bullets are Claims 4, 10 and 25.

**Evidence:** `$L/probe2.txt`, `scripts/lib/dev-cycle-read.sh:330-337`

---

## Claim 37: 2da477b7 — R1/A1 (FENCE_AWK refuses NUL), A2 (main_entry prints error without main by name or on a failed ls-tree), A4 ("fails against the old working-tree reader"), T31, the lib header no longer naming a nonexistent suite

**Location:** commit 2da477b7
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each bullet at its own commit. "every reader skips" is settled by override row 223 (A11).

- **A4.** HEAD's test 63 fails against main's lib (`$L/bats-mutants.txt`, libmain).
- **A2.** See Claims 15 and 17.
- **R1.** See Claims 12 and 13.
- **Lib header.** 2da477b7's header reads "callers' suites (test/scripts/dev-cycle.bats, and build-loop.sh's suites under test/scripts/ as they land)", where c8435580 named `build-loop-read.bats`.

**Evidence:** `$L/bats-mutants.txt`, `$L/probe1.txt`

---

## Claim 38: 78703f22 R2 — "check_answer fell through to the archive and answered `keep` from it; brief_fields returned 0 with no keys. Both now test the read"

**Location:** commit 78703f22
**Type:** Reference / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the behaviour under the lib's documented `out="$(check_answer ...)"` capture. Through dev-cycle.sh, 2da477b7 exited 128 instead (errexit).

- **check_answer.** 2da477b7 gives `out=[keep Q-1]` (`$L/probe3.txt`).
- **brief_fields.** Without the read test it returns rc0 with 0 keys (`$L/probe2.txt`, pipefail OFF, which mirrors the `if !` context).

**Evidence:** `$L/probe2.txt`, `$L/probe3.txt`

---

## Claim 39: 78703f22 A12/C9 — "main_entry kept the last ls-tree line ... while git's reads take the first, so a symlink listed before a blob read as blob. A name listed twice is now "error". ls-tree's own stderr is dropped (C9)."

**Location:** commit 78703f22
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git's first-copy behaviour, the last-line behaviour, the error on duplicates, and the `2>/dev/null`. It does not cover other git commands.

See Claims 16 and 34. The mutant without the duplicate check prints the read through the symlink. The stderr redirect is in `... "$1" 2>/dev/null)"` (`scripts/lib/dev-cycle-read.sh:263`).

**Evidence:** `$L/probe1.txt`, `$L/probe3.txt`, `scripts/lib/dev-cycle-read.sh:263`

---

## Claim 40: 78703f22 A13 — "brief_fields checks its own preconditions (main by name, pathform, a blob on main), so a later caller cannot read the index's copy through an empty MAIN_SHA."

**Location:** commit 78703f22
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the empty-MAIN_SHA path returning error before any `git cat-file blob ":path"` (the index's stage-0 copy). It does not cover a stale MAIN_SHA.

With no resolve_main, the probe prints `rc1 [error] 0` (`$L/probe2.txt`). The guard runs first: `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]` (`:292`), and main_entry starts with `main_by_name || { echo error; return; }` (`:261`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:261`, `:292`, `$L/probe2.txt`

---

## Claim 41: 78703f22 A4 — "the SKIPPED test now calls check_answer with ROOT_REAL set at the top level and a symlinked archive on main, so a reader that adds to SKIPPED fails it (checked by mutation)"

**Location:** commit 78703f22
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the mutation that was re-run here. It does not reproduce the author's own mutation.

The independent mutant fails test 63 on `skipped=1` (Claim 31).

**Evidence:** `$L/bats-mutants.txt`

---

## Claim 42: 78703f22 A5-A8 — "the second caller does not exist yet; CR, NUL and BOM refusals apply anywhere; brief_fields' values are the line but its trailing CR; archive moves count only once landed"

**Location:** commit 78703f22
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each reworded comment's substance. Claim 27 covers the SKILL.md parenthetical's completeness.

See Claims 8, 12, 19 and 27. "Count only once landed" holds; the parenthetical's outcome list is what is incomplete.

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-12`, `:173-176`, `:279-282`, `skills/dev-cycle/SKILL.md:292-295`

---

## Claim 43: 78703f22 A9 — "the template test brief gains its Motive section and is named "shaped like" the template"

**Location:** commit 78703f22
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the fixture and the title. Claim 32 covers whether the sections are complete.

The fixture holds `## Motive\n\nRoadmap Next, NAME.` (`test/scripts/dev-cycle.bats:1200`), and the title reads "a brief shaped like the skill's template" (`:1195`).

**Evidence:** `test/scripts/dev-cycle.bats:1195-1201`

---

## Claim 44: 78703f22 C1 — "--check-answer's help names the unreadable-tree skip."

**Location:** commit 78703f22
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the new help line appearing in `--help`. It does not cover the side effect: the added line pushed the Exit line out of the help range (Claim 6, Incorrect).

`--help` prints "under plain directories on the default branch, or a default branch whose tree or file could not be read)." (`$L/help-head.txt`).

**Evidence:** `scripts/dev-cycle.sh:68-70`, `$L/help-head.txt`

---

## Claim 45: 78703f22 — "Override-log rows for A10, A11, C2-C8 and C10."

**Location:** commit 78703f22
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rows' existence. It does not cover their reasons, which are settled.

`docs/reviews/override-log.md` rows dated 2026-10-05 for `feat/build-loop-u1a`:

| Row | Item |
|---|---|
| 222 | A10 |
| 223 | A11 |
| 224 | C2 |
| 225 | C3 |
| 226 | C4 |
| 227 | C5 |
| 228 | C6 |
| 229 | C7 |
| 230 | C8 |
| 231 | C10 |

(paraphrased: no quote is given because these are table rows, cited by line.)

**Evidence:** `docs/reviews/override-log.md:222-231`

---

## Claim 46: 78703f22 Notes — "The reviewer routed R2, A12 and A13 to "you: judgment" because they set the contract U1b/U1c code against"

**Location:** commit 78703f22
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the committed rubric only. It does not establish what the iteration-2 orchestrator's chat report said.

The committed rubric (`docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1a.md`, at both 2da477b7 and 78703f22) has no "you: judgment" string. Its R2, A12 and A13 rows say `for-author`. Verifying the claim needs the iteration-2 orchestrator transcript.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-05-feat-build-loop-u1a.md:16`, `:35-36`

---

## Claim 47: 722884c7 — "found the duplicate-name comment read as if the lib followed git's first-copy rule, and brief_fields' error list left out main_entry's error. Comments only."

**Location:** commit 722884c7
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the diff being comment-only and the before/after wording. It does not cover the lite check's run.

`git show 722884c7` changes only `#` lines in `scripts/lib/dev-cycle-read.sh`:

| | Before | After |
|---|---|---|
| Duplicate-name comment | `-# twice, which git's own reads resolve to the first copy: never read as absent)` | `+# twice; git's own reads would take the first copy, which may not be the one a check saw, so this answers error instead` |
| brief_fields error list | `-# ... no regular file there on main by main_entry, ...` | `+# ... any main_entry answer but blob, its error included, ...` |

**Evidence:** `scripts/lib/dev-cycle-read.sh:252-254`, `:284-286`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6** (`scripts/dev-cycle.sh:111`): the help range `sed -n '2,80p'` stops one line short of the header's end (line 81). `--help` ends mid-sentence ("... or no") and drops the Exit line's no-default-branch clause. This is a regression from main, introduced by 78703f22's C1 wrap, and no test covers `--help`. Fix: `'2,81p'`.

### Mostly Accurate
- **Claim 3** (`scripts/dev-cycle.sh:61-70`): --check-answer's skip list omits "not a question ID" (inherited from main), and covers "an entry in both files" only as "a duplicate heading".
- **Claim 27** (`skills/dev-cycle/SKILL.md:292-295`): "(it reads `open`, or no such entry)" is incomplete. An archive move made only in the working tree for an entry already answered on main reads main's answer (e.g. `keep`).

### Unverifiable
- **Claim 46** (commit 78703f22 Notes): the "you: judgment" routing is not in the committed rubric. Verifying it needs the iteration-2 orchestrator report.

## Iteration-2 items

| Item | Status | Executed evidence |
|---|---|---|
| R2 | **Resolved** | Both readers test the read. HEAD skips with questions.md's blob or the archive's blob missing, where 2da477b7 gave `keep Q-1` under `$(...)`. brief_fields returns `rc1 [error]`. Only under pipefail, which is the stated contract (Claims 9, 26, 38). |
| A4 | **Resolved** | A SKIPPED-appending mutant fails test 63 on `skipped=1` (Claims 31, 41). |
| A5 | **Resolved** | The header says the second caller's suites apply "once that second caller lands", and `scripts/build-loop.sh` is absent (Claim 8). |
| A6 | **Resolved** | CR and NUL inside a fence are refused, while html, comment and refdef inside a fence are read. The header now places CR, NUL and BOM "anywhere ... fenced or not" (Claim 12). |
| A7 | **Resolved** | "the line as stored but for that CR"; test 66 reads `Status: open\r` as `[Status: open]` (Claim 19). |
| A8 | **Resolved, residue** | "once step 1 has archived" is gone. The new parenthetical's outcome list is incomplete (Claim 27, Mostly accurate). |
| A9 | **Resolved** | The fixture has every section SKILL.md:335-340 lists, Motive included, and the title is "shaped like" (Claims 32, 43). |
| A12 | **Resolved** | Duplicates at the leaf and at every parent component print `error`. Git reads the first copy. Test 67's dup case is produced by duplicate detection; the no-dup mutant prints `no such entry` (Claims 16, 34). |
| A13 | **Resolved** | Empty MAIN_SHA, cleared MAIN_BY_NAME, pathform refusal, absent, notfile and notdir each give `rc1 [error] 0` (Claims 20, 40). |
| A10, A11 | **Rows exist** | `docs/reviews/override-log.md:222`, `:223`. |

A new item not in iteration 2 is Claim 6 (the help range), introduced by the C1 fix.

## Hallucination-pattern candidates

None. Claim 6 is a range that went stale, not a fabricated symbol. Claim 46 is an unsourced process claim. Neither qualifies for the log. As instructed, the log was not edited.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u1a/docs/reviews/code-fact-check-report-build-loop-u1a-r2.md (overwrite the stale one there), first line `Commit: 722884c7`, structured per the code-fact-check skill, every claim tagged with Legibility-target (Incorrect/Stale/Mostly Accurate → for-author; Verified/Unverifiable → for-orchestrator-synthesis), a `## Iteration-2 items` section (brief item 11), and the canonical Goal-Alignment Note at the end.
- Answered: yes. 47 claims were checked, most by execution. Every fc-brief item (1-11) is covered, and all nine iteration-2 items are resolved with executed evidence.
- Out of scope: bats test 21, which fails only because the scratch TMPDIR contains `/.claude` (confirmed by the orchestrator). Settled override-log rows (220-231) were not re-raised.
- Escalate: Claim 6. `scripts/dev-cycle.sh:111` `sed -n '2,80p'` cuts the help's last line (line 81). This is a regression from main introduced by 78703f22, with no test, and it is a one-character fix plus ideally a `--help` test. It is a new for-author item that keeps this from being a clean pass unless the orchestrator rates it below amber. Claims 3 and 27 are wording-only Mostly accurate.
- Decisions I made: I counted the help-range truncation as a claim (the header comment is the help text). I treated c8435580's Notes and 2da477b7's "every reader skips" as settled by rows 222 and 223, and did not re-verdict them.
