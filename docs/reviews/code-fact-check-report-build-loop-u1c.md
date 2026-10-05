Commit: 553a50d5

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u1c (claude-workflows, branch feat/build-loop-u1c)
**Scope:** unit diff `feat/build-loop-u1b...feat/build-loop-u1c` (scripts/build-loop.sh, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats) plus the commit messages of 859e29e8, aaae80c6 and 553a50d5; lib code (`scripts/lib/dev-cycle-read.sh`) and the plan are context only
**Checked:** 2026-10-05
**Total claims checked:** 54
**Summary:** 38 verified, 13 mostly accurate, 0 stale, 1 incorrect, 2 unverifiable
**Commit:** 553a50d5
**Replication:** k=1 (loop pass, decision 031)

Hallucination-pattern log read first (`docs/reviews/hallucination-patterns.md`). Three of its five entries are "a specific measured value quoted from an artifact set that does not contain it". This unit's measured values (2137/1017 commits, ~1 ms per brief, 79 ms, 399 lines) were each re-measured below. None matches the pattern: the counts and line total reproduce exactly. The 79 ms timing is environment-dependent and is marked Unverifiable, not fabricated.

Execution logs (all under `/home/node/.claude/jobs/989f3e5a/tmp/review-u1c/fact-check/`):
- `suites-head.log`: both suites at HEAD.
- `at-859e.log`: build-loop-read.bats at 859e29e8.
- `probe-constraints.log`, `probe-marker.log`, `probe-locale.log`, `probe-locale-warn.log`, `probe-shared.log`, `probe-wt.log`, `probe-readonly.log`: probes.
- `help.log`, `linecount.log`, `measure.log`.

Probe scripts sit next to the logs: `env.sh`, `probe-*.sh`, `measure.sh`. Every probe built throwaway repos under `.../fact-check/p/` with the fixture's hermetic git env. Unless a log says otherwise, probes ran as `bash <script>` from the scratch dir with `LC_ALL=C.UTF-8` and exit 0.

Test results at HEAD: `cd /workspace/.claude/wt-build-loop-u1c && export LC_ALL=C.UTF-8; bats test/scripts/build-loop-read.bats test/scripts/dev-cycle.bats`, run at 2026-10-05T11:46Z, exit 0. 83 of 83 pass (16 + 67). Output is in `suites-head.log`.

---

## Claim 1: "--settings  four lines from the default branch's commit ... Lines 1-3 from one line of docs/dev-cycle.md"

**Location:** `scripts/build-loop.sh:10-12`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four-line output, its order, and that lines 1-3 (policy, slots, never) come from docs/dev-cycle.md and line 4 from docs/constraints.md. Does not establish U1b's per-line rules (context).
**Legibility-target:** for-orchestrator-synthesis

`printf '%s\n' "$POLICY_LINE" "$SLOTS_LINE" "$NEVER_LINE" "$CONSTRAINTS_LINE"` (`scripts/build-loop.sh:340`). The first three are set from `f=docs/dev-cycle.md` (`:186`), and `f=docs/constraints.md` (`:237`) feeds `CONSTRAINTS_LINE`. Test `:174` asserts `"${#lines[@]}" -eq 4` and the order, and passes (`suites-head.log`). `probe-readonly.log` shows the four lines in order.

**Evidence:** `scripts/build-loop.sh:186`, `scripts/build-loop.sh:237`, `scripts/build-loop.sh:340`, `test/scripts/build-loop-read.bats:174-178`, `.../fact-check/suites-head.log`, `.../fact-check/probe-readonly.log`

---

## Claim 2: "A constraint is a line "H<n>: text" (hard) or "S<n>: text" (soft) at column 0, optionally after "- "; a hard one needs a "success: <observable>" line (any indent, optionally after "- ") before the next constraint, and no ID may repeat."

**Location:** `scripts/build-loop.sh:27-32`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what CONSTRAINTS_AWK counts, the success-line rule, the repeat rule and how each awk output maps to CONSTRAINTS_LINE (aaae80c6's message repeats the same grammar). Does not establish how U5's docs will word it.
**Legibility-target:** for-author

The recognising pattern is `/^(- )?[HS][0123456789]+: [^ \t]/` and the success pattern is `/^[ \t]*(- )?success: [^ \t]/` (`scripts/build-loop.sh:152`, `:160`). Both match the header. The probes (`probe-constraints.log`, 2026-10-05T11:47:20Z, exit 0) confirmed these:
- A success line before any constraint, or after a soft one, is ignored ("success before any" gives `hard constraint H1 (line 2) has no success:`).
- CRLF is accepted (`ok 1-hard 0-soft`), and a CRLF duplicate is caught (`listed twice (lines 1 and 3)`).
- A tab-indented `- success:` counts.
- A fenced constraint or fenced success line is not read (FENCE_AWK).
- An empty, zero-byte or prose-only file gives `none-hard ... has 0 soft constraints`.

Two imprecisions:
- **IDs are compared as written.** `seen[id]` is keyed on the literal text (`if (bad == "" && (id in seen)) bad = "dup " id " " seen[id] " " NR`, `:155`), so `H01` and `H1` are two IDs. The probe gives `constraints ok 2-hard 0-soft` for `H01: a / success: x / H1: b / success: y`. "No ID may repeat" holds only for identical spellings.
- **Near-miss forms are silently not constraints, never refused.** These all leave the line uncounted and can still yield `ok` from the other lines:
  - `H1:<TAB>text`
  - `* H1:`
  - `-  H1:` (two spaces)
  - `  H1:` (indented)
  - `h1:`
  - `1. H1:`
  - `> H1:`

  The header describes the counted shape correctly but not the silent fall-through.

**Evidence:** `scripts/build-loop.sh:149-168`, `scripts/build-loop.sh:243-248`, `.../fact-check/probe-constraints.log`

---

## Claim 3: "docs/constraints.md, which every loop prompt carries ... Only "ok" lets the orchestrator dispatch."

**Location:** `scripts/build-loop.sh:27`, `scripts/build-loop.sh:32`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers consistency with the plan only. Does not establish behaviour, since no prompt builder (`--start`/`--prompt`, U3) or dispatch step (skill, U4) exists on this branch.
**Legibility-target:** for-orchestrator-synthesis

The plan states both:
- "**Seeding.** Every loop prompt carries `docs/constraints.md` from main's commit." (`docs/working/plan-build-loop-handoff.md:44`)
- "**Step 10, dispatch**: only when `--settings` prints `constraints ok`" (`:260`), and `--start` "the constraints doc must read `ok`" (`:216`).

No code in this unit builds a prompt or dispatches. Paraphrased — no quote available because the claim covers absence of code: grep for `--start`/`--prompt` handlers in `scripts/build-loop.sh` finds only the `--settings`/`--status` cases at `:84-90`. Checking this needs U3/U4.

**Evidence:** `docs/working/plan-build-loop-handoff.md:44`, `docs/working/plan-build-loop-handoff.md:216`, `docs/working/plan-build-loop-handoff.md:260`, `scripts/build-loop.sh:84-90`

---

## Claim 4: "--status  one line per brief path, in argument order, from the default branch's commit"

**Location:** `scripts/build-loop.sh:36-37`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one-line-per-argument order and that brief content comes from main's commit. Does not establish that the working tree has no effect: the lib's check_brief also probes the working-tree path.
**Legibility-target:** for-author

Order holds: `for a in "${ARGS[@]}"; do status_line "$a"; done` (`scripts/build-loop.sh:336`), and T28 asserts six mixed ok/skip lines in order. Working-tree content edits are ignored (T21). However, `status_line` starts with `out="$(check_brief "$a")"` (`:298`), and check_brief refuses on a working-tree path check: `if [[ -n "$(blocker "$a" file)" ]]; then echo "skip $a: reached through a symlink, or not a regular file"; return; fi` (`scripts/lib/dev-cycle-read.sh:327`). In `probe-wt.log` (2026-10-05T11:49:29Z, exit 0), the committed brief reads `ok ... open review feat/a absent - - 0`. After the working-tree copy is replaced by a symlink, with main unchanged, the same brief reads `skip ...: reached through a symlink, or not a regular file`. This fails closed and is covered by "(as --check-brief)" at `:56`. Still, "from the default branch's commit" is not the whole input.

**Evidence:** `scripts/build-loop.sh:296-298`, `scripts/build-loop.sh:336`, `scripts/lib/dev-cycle-read.sh:327`, `.../fact-check/probe-wt.log`

---

## Claim 5: "STATE: open, done or dropped (dev-cycle.sh --check-brief), or new when main has no file there (then "new review - absent - - 0")"

**Location:** `scripts/build-loop.sh:39-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers STATE from check_brief (the same function dev-cycle.sh `--check-brief` calls) and the fixed "new" line. Does not establish check_brief's own rules (context).
**Legibility-target:** for-orchestrator-synthesis

`read -r _ _ st _ <<<"$out"` then `if [[ "$st" == new ]]; then echo "ok $a new review - absent - - 0"; return; fi` (`scripts/build-loop.sh:300-301`). dev-cycle.sh routes `--check-brief) check_brief "$a" ;;` (`scripts/dev-cycle.sh:200`). The T8 test at `:310-311` (pass) and `probe-readonly.log` (`ok docs/working/briefs/2026-10-01-zz.md new review - absent - - 0`) confirm it.

**Evidence:** `scripts/build-loop.sh:298-301`, `scripts/dev-cycle.sh:200`, `test/scripts/build-loop-read.bats:310-312`, `.../fact-check/probe-readonly.log`

---

## Claim 6: "POLICY: self-merge only when --settings' policy is self-merge and the brief's first "Policy:" line is exactly "Policy: self-merge"; else review."

**Location:** `scripts/build-loop.sh:41-43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stricter-of rule, that the first unfenced "Policy:" line wins, and the variants in T5. Does not establish anything beyond the lib's "exactly", which allows one trailing CR because brief_fields drops it.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge` (`scripts/build-loop.sh:311`). brief_fields keeps the first line per key: `if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 }` (`scripts/lib/dev-cycle-read.sh:299`). In `probe-shared.log`, `Policy: review` followed by `Policy: self-merge` under settings self-merge gives `review`. T5 (`:315-330`) passes, including a malformed never line turning self-merge off.

**Evidence:** `scripts/build-loop.sh:311`, `scripts/lib/dev-cycle-read.sh:298-299`, `test/scripts/build-loop-read.bats:315-330`, `.../fact-check/probe-shared.log`

---

## Claim 7: "BRANCH: from the brief's first "Branch: NAME" line."

**Location:** `scripts/build-loop.sh:43-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the first unfenced line starting "Branch:" is read, and that a malformed one is a skip rather than a search for a later well-formed line. Does not establish check_branch's name rules (context).
**Legibility-target:** for-orchestrator-synthesis

`if [[ ! "${BRIEF[branch]}" =~ ^Branch:\ ([^\ ]+)$ ]]; then echo "skip $a: its first Branch: line is not exactly \"Branch: NAME\""; return; fi` (`scripts/build-loop.sh:304`). Probes (`probe-shared.log`): `Branch: feat/g` followed by `Branch: feat/other` gives `feat/g`, and a fenced `Branch: feat/fenced` is skipped in favour of the later `Branch: feat/h`.

**Evidence:** `scripts/build-loop.sh:303-305`, `scripts/lib/dev-cycle-read.sh:298-299`, `.../fact-check/probe-shared.log`

---

## Claim 8: "LOOP: absent (no such branch), working, ready, blocked or stopped, from the branch tip (SHA, with DATE its commit date as YYYY-MM-DD; "-" when absent)."

**Location:** `scripts/build-loop.sh:44-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five LOOP values, the SHA and the %cs date. Does not establish the "absent" case for a ref pointing at a non-commit, which check_branch also reports as absent.
**Legibility-target:** for-orchestrator-synthesis

`"absent "*) echo "ok $a $st $pol $br absent - - $disp"; return ;;` (`scripts/build-loop.sh:317`). The date comes from check_branch's `$(git log -1 --format=%cs "$sha")` (`scripts/lib/dev-cycle-read.sh:378`). T6 asserts every field for absent, working (0 ahead and 1 ahead), ready, blocked and stopped, and passes.

**Evidence:** `scripts/build-loop.sh:315-330`, `scripts/lib/dev-cycle-read.sh:376-379`, `test/scripts/build-loop-read.bats:211-242`, `.../fact-check/suites-head.log`

---

## Claim 9: "A tip is a marker only when the branch is at least one commit ahead of main and the tip is an empty commit with one parent whose subject is exactly "handoff: ready", "handoff: blocked" or "handoff: stopped: REASON" (1-120 printable ASCII characters, no blank at either end)"

**Location:** `scripts/build-loop.sh:47-51`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ahead gate, parent count, empty tree, the exact subjects and the REASON charset and length. It also covers commits with gpgsig, mergetag and encoding headers. The "alone on its first line" and subject-definition edges are verdicted in Claim 10.
**Legibility-target:** for-orchestrator-synthesis

The checks, in order:
- The ahead gate: `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`scripts/build-loop.sh:322-323`).
- Parent count: `if [[ "$np" -eq 0 ]]` / `-gt 1` (`:264-265`).
- Empty tree: `if [[ "$tree" != "$ptree" ]]; then echo "bad it changes files"` (`:267`).
- REASON: `${#r} -le 120 && "$r" =~ ^[!-~]([\ -~]*[!-~])?$` (`:278`).

The header split `hdr="${raw%%$'\n\n'*}"` (`:258`) is safe for signed or tagged commits, because their continuation lines start with a space (a blank armor line is stored as " "). `probe-marker.log` (2026-10-05T11:47:57Z, exit 0) shows:
- Commits with `encoding` + `gpgsig` headers, and with a `mergetag` header, read `ready`.
- A 120-character reason is `stopped`; 121 is `skip`.
- 119 ASCII characters plus `é` (120 characters, 121 bytes) is `skip`.

T7 covers content, merge, orphan, suffixed and mis-cased subjects, and empty, ESC, bidi and non-ASCII reasons.

**Evidence:** `scripts/build-loop.sh:255-280`, `scripts/build-loop.sh:321-329`, `test/scripts/build-loop-read.bats:244-279`, `.../fact-check/probe-marker.log`

---

## Claim 10: "alone on its first line ... Any other tip is working" together with the skip reason "the tip's subject starts "handoff:" but it is not a marker"

**Location:** `scripts/build-loop.sh:51-53`, `scripts/build-loop.sh:59-60`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what "subject" and "alone" mean in code. Does not establish any spoof that reads as a marker: both mismatches below fail closed.
**Legibility-target:** for-author

The code's "subject" is the raw first line of the message: `subj="${msg%%$'\n'*}"` and `[[ "$subj" == handoff:* ]] || { echo working; return; }` (`scripts/build-loop.sh:259-260`). "Alone" means the next line is zero-length: `if [[ "$msg" == *$'\n'* && -n "${rest%%$'\n'*}" ]]; then echo "bad its subject runs onto a second line"` (`:269`). Git's subject (`%s`) differs in two ways, both probed in `probe-marker.log`:
- **Leading blank line.** A message `"\nhandoff: ready\n"` has git `%s` = `handoff: ready`. `--status` prints `working`, not the skip line the header promises for a tip whose subject starts "handoff:".
- **Whitespace-only next line.** `"handoff: ready\n \nbody"` and `"handoff: ready\n\t\n"` have git `%s` = `handoff: ready`. Both give `skip ...: its subject runs onto a second line`, although git's subject ends there.

Both fail closed (never a marker). The precise wording is "the message's first line is exactly …, and the second line, if any, is empty".

The required cases match the brief: `"handoff: ready\n"` → ready, `"handoff: ready\n\nbody"` → ready, `"handoff: ready\nmore"` → skip.

**Evidence:** `scripts/build-loop.sh:257-269`, `.../fact-check/probe-marker.log`

---

## Claim 11: "DISPATCHED: the brief's "Dispatched: N" (0-99), or 0 without one."

**Location:** `scripts/build-loop.sh:53-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 0-99 regex and the default 0. Does not establish D1's cap of 4 (U3).
**Legibility-target:** for-orchestrator-synthesis

`local ... pol=review disp=0` (`scripts/build-loop.sh:297`) and `[[ "${BRIEF[dispatched]}" =~ ^Dispatched:\ (0|[123456789][0123456789]?)$ ]]` (`:307`). In T6, `Dispatched: 2` gives `2`. In T5, briefs without the line give `0`. In T8, `x`, `100`, `01`, `-1` and empty all skip. All pass.

**Evidence:** `scripts/build-loop.sh:297`, `scripts/build-loop.sh:306-310`, `test/scripts/build-loop-read.bats:304-308`

---

## Claim 12a: "skip BRIEF: WHY — The brief cannot be read (as --check-brief), its Branch: ... line is missing or malformed, its branch name is refused (as --check-branch) ..."

**Location:** `scripts/build-loop.sh:56-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the check_brief, Branch: and check_branch skip causes. The list is otherwise complete: the remaining `skip $a: the brief is not read` (`:302`) is a brief_fields failure after check_brief succeeded, which falls under "cannot be read". The Dispatched-missing atom is Claim 12b.
**Legibility-target:** for-orchestrator-synthesis

These skips appear in order in the code: `[[ "$out" == "ok "* ]] || { echo "$out"; return; }` (`scripts/build-loop.sh:299`), `"skip $a: no Branch: line on the default branch"` (`:303`), the malformed-Branch skip (`:304`), and `*) echo "skip $a: Branch: ${out#*: }"; return ;;` (`:319`). T8 passes for each one.

**Evidence:** `scripts/build-loop.sh:298-319`, `test/scripts/build-loop-read.bats:281-313`

---

## Claim 12b: "skip BRIEF: WHY — ... its ... Dispatched: line is missing or malformed"

**Location:** `scripts/build-loop.sh:56-57`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "missing" half for Dispatched:. The "malformed" half is correct (Claim 11). Does not establish any code defect.
**Legibility-target:** for-author

A missing Dispatched: line is never a skip. The check runs only when the key is set: `if [[ -n "${BRIEF[dispatched]+set}" ]]; then` (`scripts/build-loop.sh:306`). Otherwise `disp=0` stands, which is what the same header says at `:53-54` ("or 0 without one"). T5 runs briefs without the line and asserts `ok $B open $want feat/a absent - - 0` (`test/scripts/build-loop-read.bats:322`), and it passes. The skip list's "Branch: or Dispatched: line is missing or malformed" therefore contradicts both the code and line 53-54. The precise version is "its Branch: line is missing or malformed, or its Dispatched: line is malformed".

**Defect class:** comment/doc-only. The code is correct and the header contradicts itself, but this header is the `--status` contract U4's skill will be written against. It is in the script header on the unmerged branch (introduced in aaae80c6), not in a commit message.

**Evidence:** `scripts/build-loop.sh:53-57`, `scripts/build-loop.sh:306-310`, `test/scripts/build-loop-read.bats:315-323`

---

## Claim 13: "another open brief on main names the same branch (ignoring case)"

**Location:** `scripts/build-loop.sh:58-59`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which briefs the F31 skip applies to. Does not establish F31 for `--check` (U2).
**Legibility-target:** for-author

Two qualifiers are missing:
- **Only an open brief is skipped.** The code is `if [[ "$st" == open && "$SHARED_BRANCHES" == *$'\n'"$(lower "$br")"$'\n'* ]]; then` (`scripts/build-loop.sh:312`). A done or dropped brief naming a branch that two open briefs share prints `ok`. T28 asserts this (`[ "${lines[3]}" = "ok $c done review feat/x absent - - 0" ]`, `test/scripts/build-loop-read.bats:354`), and `probe-shared.log` reproduces it. The literal condition "another open brief on main names the same branch" is true for that done brief, yet it is not skipped.
- **Only briefs directly under docs/working/briefs/ are counted.** `git ls-tree --full-tree --name-only "$MAIN_SHA" -- docs/working/briefs/` (`:287`) lists direct children only. The `closed` tree entry it also lists fails `isbrief`. In the probe, a `closed/` brief whose Status reads `open` and an open brief naming the same `feat/y` both print `ok ... open ... feat/y`, which is two "open" STATE lines on one branch with no skip.

The precise version is "the brief is open and another open brief directly under docs/working/briefs/ on main names the same branch". The closed/-open shape is unusual, since a closed brief should be done or dropped.

**Evidence:** `scripts/build-loop.sh:284-295`, `scripts/build-loop.sh:312-314`, `test/scripts/build-loop-read.bats:342-361`, `.../fact-check/probe-shared.log`

---

## Claim 14: "Read-only: writes nothing."

**Location:** `scripts/build-loop.sh:63`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--status` (with an ok-working brief and a new brief) and `--settings` on a probe repo: the working tree and `.git` are unchanged by path, size, mtime and mode. Does not establish this for repos with hooks or config that make read commands write (for example a commit-graph auto-write); none was configured.
**Legibility-target:** for-orchestrator-synthesis

Command: snapshot `find . -printf '%p %s %T@ %m\n' | sort | sha256sum` before and after `bash "$BL" --status "$B" docs/working/briefs/2026-10-01-zz.md; bash "$BL" --settings`. It ran in `.../fact-check/p/mark` at 2026-10-05T11:48:22Z with exit 0. Result: `before=b5a26d35…` and `after =b5a26d35…`, `SAME`. The new mode calls only `git ls-tree`, `cat-file`, `log`, `rev-list`, `show-ref` and `rev-parse` (paraphrased — no quote available because the git calls span status_line, marker_kind, shared_branches and four lib functions).

**Evidence:** `scripts/build-loop.sh:255-331`, `.../fact-check/probe-readonly.log`

---

## Claim 15: help prints the header via `sed -n '2,67p'`

**Location:** `scripts/build-loop.sh:87`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that lines 2-67 are exactly the comment header (line 68 is blank, 69 is `set -euo pipefail`). Does not establish future edits (override-log row on the fixed range).
**Legibility-target:** for-orchestrator-synthesis

`-h|--help) sed -n '2,67p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;` (`scripts/build-loop.sh:87`). `bash scripts/build-loop.sh --help` ran at 2026-10-05T11:49:18Z with exit 0 and printed 66 lines. The last line is `lib/dev-cycle-read.sh, or no default branch found by name.` (header `:67`), and the first non-comment line after line 1 is 68.

**Evidence:** `scripts/build-loop.sh:66-69`, `scripts/build-loop.sh:87`, `.../fact-check/help.log`

---

## Claim 16: "docs/constraints.md: "ok HARD SOFT", "nosuccess ID LINE" or "dup ID FIRST SECOND" (the first problem found)."

**Location:** `scripts/build-loop.sh:146-147`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three CONSTRAINTS_AWK-specific outputs and first-problem ordering. The program can also print FENCE_AWK's `odd`/`unbalanced`, which main_file's comment (`:101-103`) documents and handles before the caller reads FILE_OUT.
**Legibility-target:** for-orchestrator-synthesis

`if (bad == "" && pend != "") bad = "nosuccess " pend " " pendl` comes before `if (bad == "" && (id in seen)) bad = "dup " ...` (`scripts/build-loop.sh:154-155`). The END block prints `(bad != "" ? bad : "ok " hard + 0 " " soft + 0)` (`:166`). In the probe, `H1: a / H1: b / success: x` reports the earlier problem (`hard constraint H1 (line 1) has no success:`), not the dup on line 2.

**Evidence:** `scripts/build-loop.sh:146-168`, `.../fact-check/probe-constraints.log`

---

## Claim 17: "Sets POLICY, POLICY_LINE, SLOTS_LINE, NEVER (...), NEVER_LINE and CONSTRAINTS_LINE from main's commit. POLICY and NEVER are for the modes that judge a brief (--status, then the gate)."

**Location:** `scripts/build-loop.sh:179-182`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the variables set and their readers on this branch. The second sentence is U1b context, but this unit added --status and so made it checkable.
**Legibility-target:** for-author

The first sentence holds: CONSTRAINTS_LINE is now set (`:239-247`). For the second, `--status` reads POLICY (`[[ "$POLICY" == self-merge && ...` at `:311`) but never NEVER. The only references are `:183`, `:188` and `:222`, all writes (paraphrased — no quote available because the claim covers absence of a reader; grep `NEVER` in scripts/build-loop.sh). NEVER is for the gate alone (U2). The precise version is "POLICY is for --status and the gate; NEVER for the gate". The SC2034 disable at `:184` ("POLICY and NEVER: see above") is now needed only for NEVER; shellcheck passes either way.

**Evidence:** `scripts/build-loop.sh:179-188`, `scripts/build-loop.sh:222`, `scripts/build-loop.sh:311`

---

## Claim 18: the `case "$k"` mapping of awk output to CONSTRAINTS_LINE (`*)` arm = "listed twice")

**Location:** `scripts/build-loop.sh:242-248`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every output shape reaching the `case` maps correctly. Does not establish anything else: `odd`/`unbalanced` and awk failure return 1 from main_file and never reach it.
**Legibility-target:** for-orchestrator-synthesis

main_file returns 1 on `odd\ *` / `unbalanced\ *` (`:119-120`) and on a failed read (`:116-117`). That leaves `ok`, `nosuccess` and `dup`, so `*)` sees only `dup`, and `read -r k c l1 l2` lines up with "dup ID FIRST SECOND". The probe shows `constraint S1 is listed twice (lines 1 and 2)` and `constraint H1 is listed twice (lines 1 and 3)` (CRLF).

**Evidence:** `scripts/build-loop.sh:116-121`, `scripts/build-loop.sh:242-248`, `.../fact-check/probe-constraints.log`

---

## Claim 19: "The tip SHA of a brief's branch, read as a handoff marker: prints ready, blocked, "stopped REASON", working (no "handoff:" subject), or "bad WHY"."

**Location:** `scripts/build-loop.sh:252-253`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the output set of marker_kind (`:255-280`, read to its end). "Subject" means the raw first line (Claim 10).
**Legibility-target:** for-orchestrator-synthesis

The outputs are `echo working` (`:260`), `echo ready` / `echo blocked` (`:271-272`), `echo "stopped $r"` (`:278`), and `echo "bad ..."` at `:264`, `:265`, `:267`, `:269` and `:279`. No other output exists.

**Evidence:** `scripts/build-loop.sh:255-280`, `.../fact-check/probe-marker.log`

---

## Claim 20: "The caller has checked that the branch is at least one commit ahead of main."

**Location:** `scripts/build-loop.sh:254`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the only caller. Does not establish future callers (U2/U3).
**Legibility-target:** for-orchestrator-synthesis

The only call is `if [[ "$ahead" -gt 0 ]]; then kind="$(marker_kind "$sha")"` (`scripts/build-loop.sh:322-323`), where `ahead` is check_branch's `git rev-list --count "$MAIN_SHA..$sha"` (`scripts/lib/dev-cycle-read.sh:378`). A grep for `marker_kind` finds only the definition and this call (paraphrased — no quote available because the claim covers absence of other call sites).

**Evidence:** `scripts/build-loop.sh:322-323`, `scripts/lib/dev-cycle-read.sh:378`

---

## Claim 21: "Bytes, not characters: in the C locale the ranges below are ASCII and ${#r} counts bytes (C is always installed, so setting it never warns)."

**Location:** `scripts/build-loop.sh:275-277`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that `local LC_ALL=C` takes effect inside the function under a UTF-8 caller locale and that setting C does not warn. Does not establish silence on return: bash restores the caller's LC_ALL, which warns when that locale is not installed.
**Legibility-target:** for-author

`probe-locale.log` (2026-10-05T11:47:43Z, exit 0) runs a copy of the pattern under `LC_ALL=C.UTF-8`:
- `before local: len=4` then `after local LC_ALL=C: len=5` for `caf\xc3\xa9`. The local assignment does switch `${#r}` to bytes, and the regex rejects the string.
- After return the caller is back to `len=4`.

The claim's mechanism holds. Two residues:
- Every reason that passes `^[!-~]([\ -~]*[!-~])?$` is ASCII, so bytes and characters agree for any accepted REASON. The setting changes only how rejected strings are measured.
- Leaving the function restores the caller's locale. When that locale is not installed, which is this sandbox's default `LC_ALL=en_US.UTF-8`, bash prints a warning. `probe-locale-warn.log` shows that a `handoff: stopped: x` tip run under `LC_ALL=en_US.UTF-8` adds `/workspace/.claude/wt-build-loop-u1c/scripts/build-loop.sh: line 323: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)` to stderr. That is 3 stderr lines against 2 for a `ready` or working tip, whose paths return before `:277`. Exit stays 0 and stdout is unchanged.

"Never warns" is true of setting C but not of the function as a whole. The bats suites cannot see this because `bl_setup` exports `LC_ALL=C` (`test/lib/build-loop-fixtures.bash:14`).

**Evidence:** `scripts/build-loop.sh:274-279`, `scripts/build-loop.sh:323`, `test/lib/build-loop-fixtures.bash:14`, `.../fact-check/probe-locale.log`, `.../fact-check/probe-locale-warn.log`

---

## Claim 22: "Lower-cased branch names that more than one open brief on main names, each on its own line between newlines: such briefs are skipped (F31)."

**Location:** `scripts/build-loop.sh:281-282`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the list format, ASCII case folding (`lower` is `tr` A-Z to a-z), and which briefs feed the count. The "skipped" half is Claim 13.
**Legibility-target:** for-author

The format holds: `SHARED_BRANCHES=$'\n'` then `SHARED_BRANCHES+="$b"$'\n'` (`:293-294`). "Open brief on main" is narrower than it reads. A brief is counted only if all of these hold:
- It is a direct child of `docs/working/briefs/` (`git ls-tree ... -- docs/working/briefs/` at `:287` does not recurse, and `closed` fails `isbrief`).
- `main_entry` reports `blob`.
- brief_fields reads it.
- Its first Branch: line is well-formed (`:289-290`).

A `closed/` brief reading `Status: open` is not counted (`probe-shared.log`), and neither is an open brief FENCE_AWK refuses. That last case is harmless, since the refused brief itself skips. The precise version is "...that more than one open, readable brief directly under docs/working/briefs/ on main names".

**Evidence:** `scripts/build-loop.sh:283-295`, `scripts/lib/dev-cycle-read.sh:157`, `.../fact-check/probe-shared.log`

---

## Claim 23: "commit_all [MSG]: stage everything and commit it on the current branch (an empty commit when nothing changed, so rewriting a file as it was still works)."

**Location:** `test/lib/build-loop-fixtures.bash:21-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `--allow-empty`. Does not establish anything else.
**Legibility-target:** for-orchestrator-synthesis

`commit_all() { git add -A && git commit -q --allow-empty -m "${1:-fixture}"; }` (`test/lib/build-loop-fixtures.bash:23`). T5 re-writes `settings`/`brief a` with identical content across iterations, and it passes.

**Evidence:** `test/lib/build-loop-fixtures.bash:21-23`, `test/scripts/build-loop-read.bats:316-319`

---

## Claim 24: "constraints LINE...: docs/constraints.md holding these lines, committed."

**Location:** `test/lib/build-loop-fixtures.bash:29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the file content and commit. With no lines the file holds one empty line, as `settings` documents.
**Legibility-target:** for-orchestrator-synthesis

`constraints() { mkdir -p docs && printf '%s\n' "$@" > docs/constraints.md && commit_all constraints; }` (`test/lib/build-loop-fixtures.bash:30`).

**Evidence:** `test/lib/build-loop-fixtures.bash:29-30`

---

## Claim 25: "brief SLUG LINE...: docs/working/briefs/2026-10-01-SLUG.md holding a title and these lines, committed on the current branch; sets B to its path."

**Location:** `test/lib/build-loop-fixtures.bash:42-43`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the path, title, lines, commit and B. A blank line separates title and lines, which explains T8's "line 4" for the first argument line's successor.
**Legibility-target:** for-orchestrator-synthesis

`B="docs/working/briefs/2026-10-01-$s.md"` and `printf '# Brief: %s\n\n' "$s" > "$B" && printf '%s\n' "$@" >> "$B"`, then `commit_all "brief $s"` (`test/lib/build-loop-fixtures.bash:46-48`).

**Evidence:** `test/lib/build-loop-fixtures.bash:44-49`

---

## Claim 26: "work BRANCH: BRANCH from main with one commit that changes a file."

**Location:** `test/lib/build-loop-fixtures.bash:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch point and the one commit, which adds `work-<name>.txt`. Does not establish isolation: `commit_all`'s `git add -A` would also sweep in any uncommitted working-tree change. Every current call site has a clean tree.
**Legibility-target:** for-orchestrator-synthesis

`git branch -q "$1" main` then `git checkout -q "$1" && echo "$1" > "work-${1//\//-}.txt" && commit_all "work on $1" && git checkout -q main` (`test/lib/build-loop-fixtures.bash:53-54`).

**Evidence:** `test/lib/build-loop-fixtures.bash:52-55`

---

## Claim 27: "tip BRANCH MESSAGE [TREE [PARENT...]]: a commit with exactly MESSAGE (no cleanup: commit-tree takes it as given) on BRANCH's tip. By default it is empty (BRANCH's own tree) with BRANCH's tip as its one parent; pass TREE and the parents ("" for none) to build anything else."

**Location:** `test/lib/build-loop-fixtures.bash:57-60`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message bytes, default tree and parent, and the TREE/parents form. Does not establish anything about marker_kind, which strips trailing newlines, so the extra byte changes no current test.
**Legibility-target:** for-author

The message is piped as `printf '%s\n' "$m" | git commit-tree "$t" "${p[@]}"` (`test/lib/build-loop-fixtures.bash:65`). commit-tree does store stdin as given: `printf 'x' | git commit-tree …` stores `x` with no newline. So the stored message is MESSAGE plus one trailing newline, not "exactly MESSAGE". The default and `""` handling hold: `[[ -n "$x" ]] && p+=(-p "$x")` (`:63`), and T7's orphan case reads `it has no parent`.

**Evidence:** `test/lib/build-loop-fixtures.bash:61-66`, `test/scripts/build-loop-read.bats:258-259`

---

## Claim 28: "status_of BRIEF: the one --status output line for BRIEF."

**Location:** `test/lib/build-loop-fixtures.bash:68`
**Type:** Behavioral / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helper's own behaviour. Does not establish use: `grep -rn status_of test/` finds only its definition and comment, so it is an unused helper.
**Legibility-target:** for-orchestrator-synthesis

`status_of() { printf '%s\n' "$output" | grep -m1 -E "^(ok|skip) $1[ :]" || true; }` (`test/lib/build-loop-fixtures.bash:70`). BRIEF is used as an ERE, so a `.` in a path matches any character. That is harmless for fixture paths.

**Evidence:** `test/lib/build-loop-fixtures.bash:68-70`

---

## Claim 29: T44 test name "--settings: docs/constraints.md from main gives ok, missing, none-hard or unreadable (T44)" and comment "Only in the working tree: still missing."

**Location:** `test/scripts/build-loop-read.bats:143`, `test/scripts/build-loop-read.bats:147`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four outcomes asserted, including a working-tree-only file reading missing. Does not establish the near-miss forms in Claim 2.
**Legibility-target:** for-orchestrator-synthesis

The test asserts `constraints missing: no docs/constraints.md on the default branch` after `printf -- '- H1: x\n  success: y\n' > docs/constraints.md` without commit (`:148-150`), then none-hard, ok, unreadable (nosuccess, dup, refdef, symlink). It passes.

**Evidence:** `test/scripts/build-loop-read.bats:143-172`, `.../fact-check/suites-head.log`

---

## Claim 30: "--settings prints its four lines in order and exits 0; usage errors and a missing default branch exit 1"

**Location:** `test/scripts/build-loop-read.bats:174`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the asserted cases (`""`, `--bogus`, `--settings extra`, bare `--status`). Does not establish `--status --settings`, which is no longer a usage error (Claim 50).
**Legibility-target:** for-orchestrator-synthesis

`for args in "" "--bogus" "--settings extra" "--status"; do` with `[ "$status" -eq 1 ] && [ -z "$output" ]` (`:179-182`). Bare `--status` hits `usage "--status needs at least one brief path"` (`scripts/build-loop.sh:86`). The test passes.

**Evidence:** `test/scripts/build-loop-read.bats:174-190`, `scripts/build-loop.sh:86`

---

## Claim 31: "A ready marker's body is not read here (--marker reads blocked and stopped bodies)."

**Location:** `test/scripts/build-loop-read.bats:238`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--status` reading a ready tip with a body as `ready`, and the plan's `--marker` contract. Does not establish `--marker` code, which does not exist yet (U3).
**Legibility-target:** for-orchestrator-synthesis

The plan says "`--marker BRIEF` → `ok BRIEF SHA`, then the `blocked` or `stopped` body" (`docs/working/plan-build-loop-handoff.md:206`). The test builds `printf 'handoff: ready\n\nAll green.'` and asserts `ok $B open review feat/a ready` (`:239-241`), and passes. The probe `ready + blank + body` reads `ready`.

**Evidence:** `test/scripts/build-loop-read.bats:238-241`, `docs/working/plan-build-loop-handoff.md:206`, `.../fact-check/probe-marker.log`

---

## Claim 32: T7 test name "spoofed markers read as unreadable or working, and a bad reason is not echoed (T7)"

**Location:** `test/scripts/build-loop-read.bats:244`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts. "Unreadable" is plan T7's word (`docs/working/plan-build-loop-handoff.md:324`), not an output.
**Legibility-target:** for-author

Spoofed tips produce a skip line, not a LOOP value named "unreadable": `check "skip $B: $n: it changes files" content`, where `n='the tip of feat/a starts "handoff:" but is not a marker'` (`:248`, `:255`). The precise name is "spoofed markers are a 'not a marker' skip, or working". Commit 859e29e8's Notes record the mapping ("plan T7's 'unreadable'").

**Evidence:** `test/scripts/build-loop-read.bats:244-267`, `docs/working/plan-build-loop-handoff.md:324`

---

## Claim 33: "Not a marker at all: an ordinary commit, even one that mentions a marker."

**Location:** `test/scripts/build-loop-read.bats:268`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a subject not starting "handoff:". Does not establish anything else.
**Legibility-target:** for-orchestrator-synthesis

`tip feat/a 'wip: before handoff: ready'` then `check "ok $B open review feat/a working "` (`:269-270`). Code: `[[ "$subj" == handoff:* ]] || { echo working; return; }` (`scripts/build-loop.sh:260`). The test passes.

**Evidence:** `test/scripts/build-loop-read.bats:268-270`, `scripts/build-loop.sh:260`

---

## Claim 34: "A marker at main's tip with the branch 0 commits ahead is main's, not the loop's."

**Location:** `test/scripts/build-loop-read.bats:271`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ahead=0 gate. Does not establish anything else.
**Legibility-target:** for-orchestrator-synthesis

`tip main 'handoff: ready' && git branch -q -f feat/a main`, asserting `working $(git rev-parse main)` (`:272-274`). Code: `if [[ "$ahead" -gt 0 ]]` (`scripts/build-loop.sh:322`). The test passes.

**Evidence:** `test/scripts/build-loop-read.bats:271-274`, `scripts/build-loop.sh:321-322`

---

## Claim 35: "So is a branch that is a symbolic ref to main."

**Location:** `test/scripts/build-loop-read.bats:275`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `refs/heads/alias` → `refs/heads/main`. show-ref resolves it to main's commit, which is 0 ahead. Does not establish symrefs to other branches.
**Legibility-target:** for-orchestrator-synthesis

`git symbolic-ref refs/heads/alias refs/heads/main` and the assertion `ok $B open review alias working ` (`:276-278`). The name check `[[ "$a" == "$MAIN" ]]` (`scripts/lib/dev-cycle-read.sh:374`) does not catch `alias`, so the 0-ahead gate is what makes it working. The test passes.

**Evidence:** `test/scripts/build-loop-read.bats:275-278`, `scripts/lib/dev-cycle-read.sh:374-378`

---

## Claim 36: "Not landed on main: new, with nothing else to read."

**Location:** `test/scripts/build-loop-read.bats:309`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the new line. Does not establish anything else.
**Legibility-target:** for-orchestrator-synthesis

The test asserts `"ok docs/working/briefs/2026-10-01-none.md new review - absent - - 0"` (`:311`). Code: `scripts/build-loop.sh:301`. It passes.

**Evidence:** `test/scripts/build-loop-read.bats:309-312`, `scripts/build-loop.sh:301`

---

## Claim 37: "A malformed Self-merge never: line turns it off."

**Location:** `test/scripts/build-loop-read.bats:325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--status` POLICY under a malformed never line. Does not establish anything else.
**Legibility-target:** for-orchestrator-synthesis

`settings 'Build-loop policy: self-merge' 'Self-merge never: ../x'` gives `ok $B open review feat/a absent - - 0` (`:326-329`). In read_settings, `if [[ "$v" == self-merge && -z "$never_ok" ]]` leaves `POLICY=review` (`scripts/build-loop.sh:228-229`). The test passes.

**Evidence:** `test/scripts/build-loop-read.bats:325-329`, `scripts/build-loop.sh:228-230`

---

## Claim 38: T21 test name "--status reads main's commit: working-tree and branch edits to a brief's lines are ignored (T21)"

**Location:** `test/scripts/build-loop-read.bats:332`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers content edits to Status/Branch/Policy/Dispatched on a branch and in the working tree. Does not establish working-tree replacement of the file by a symlink, which does change the output (Claim 4).
**Legibility-target:** for-orchestrator-synthesis

The branch edit commits `Status: done / Branch: feat/z / Policy: self-merge / Dispatched: 0` on feat/a. The working-tree edit writes `Status: dropped / Branch: feat/y ...`. The output still reads `ok $B open review feat/a working ... 1` (`:336-339`). The test passes.

**Evidence:** `test/scripts/build-loop-read.bats:332-340`, `.../fact-check/probe-wt.log`

---

## Claim 39: T28 test name "two open briefs naming one branch both skip; many briefs keep their order" and comment "An open brief only in the working tree does not count."

**Location:** `test/scripts/build-loop-read.bats:342`, `test/scripts/build-loop-read.bats:357`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers case-insensitive sharing among open briefs directly under briefs/, order across six mixed lines, and that a working-tree-only brief is not counted. The closed/ residue is in Claim 22.
**Legibility-target:** for-orchestrator-synthesis

`feat/x` and `Feat/X` both skip (`:352`, `:355`). The order is asserted line by line (`:351-356`). The working-tree file `2026-10-01-wt.md` naming `feat/d` leaves `d` as `ok` (`:358-360`), because shared_branches lists `$MAIN_SHA`'s tree (`scripts/build-loop.sh:287`). The test passes.

**Evidence:** `test/scripts/build-loop-read.bats:342-361`, `scripts/build-loop.sh:287`

---

## Claim 40: 859e29e8 message, "Failing tests for the rest of U1"

**Location:** commit `859e29e8` (message body, line 3)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that every test the commit adds or changes fails at 859e29e8, and that the tests it does not touch still pass. Does not establish why each one fails, beyond the missing mode or line.
**Legibility-target:** for-orchestrator-synthesis

Command: `git archive 859e29e8 | tar -x -C .../fact-check/at-859e && cd .../at-859e && LC_ALL=C.UTF-8 bats test/scripts/build-loop-read.bats`, run at 2026-10-05T11:46Z with exit 1. Tests 8 (T44), 9 (four lines) and 11-16 (T6, T7, T8, T5, T21, T28) are `not ok`. Tests 1-7 and 10 are `ok`.

**Evidence:** `test/scripts/build-loop-read.bats:143`, `.../fact-check/at-859e.log`

---

## Claim 41: 859e29e8 message, the T-descriptions (T6, T7 "skip as "not a marker" without echoing the reason", T8, T5, T21, T28 "order kept across mixed ok and skip lines")

**Location:** commit `859e29e8` (message body, T6-T28 bullets)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each bullet against the test bodies at HEAD (859e29e8's tests differ only by the dropped `--status --settings` case and the `feat/a^{tree}` quoting).
**Legibility-target:** for-author

Every listed case is present:
- T6: absent, working at 0 ahead and with ordinary commits, ready, blocked, and stopped at 120 and 121.
- T7: content, merge, orphan, suffixed and mis-cased subjects, empty/ESC/bidi/non-ASCII reasons, a two-line subject, a marker at main's tip, and a symref.
- T8, T5, T21 and T28 as described.

One overstatement: "without echoing the reason" is asserted only for two byte patterns, `[[ "$output" != *$'\xc3'* && "$output" != *'[31m'* ]]` (`test/scripts/build-loop-read.bats:264`). The bidi reason `x\xe2\x80\xaey` is not checked for echo. The code never echoes any reason (the `bad` texts are constant, `scripts/build-loop.sh:264-279`), so behaviour matches, but the test does not show it for that case.

**Evidence:** `test/scripts/build-loop-read.bats:211-361`, `test/scripts/build-loop-read.bats:260-265`, `scripts/build-loop.sh:264-279`

---

## Claim 42: aaae80c6 message, "check_branch for the tip, ahead count and date (the name reaches git only through show-ref --verify)"

**Location:** commit `aaae80c6` (message body, paragraph 2)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every git invocation that receives the brief's branch name. Does not establish exploitability, which NAMECHARS bounds.
**Legibility-target:** for-author

As a ref lookup, only `git show-ref --verify --hash "refs/heads/$a"` sees the name (`scripts/lib/dev-cycle-read.sh:376`). Later calls use `$sha`. But the name also reaches git twice in validation: `git check-ref-format "refs/heads/$a"` and `git check-ref-format --branch "$a"` (`:372`). The second form expands `@{-N}`-style syntax; NAMECHARS excludes `@{}` (`:371`), so this is harmless. The precise version is "reaches git only through check-ref-format and show-ref --verify". This is in an unmerged commit message (lib code is context).

**Evidence:** `scripts/lib/dev-cycle-read.sh:371-378`

---

## Claim 43: aaae80c6 message, "POLICY is the stricter of --settings' policy and the brief's Policy: line."

**Location:** commit `aaae80c6` (message body, paragraph 2)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As in Claim 6.
**Legibility-target:** for-orchestrator-synthesis

`[[ "$POLICY" == self-merge && "${BRIEF[policy]-}" == "Policy: self-merge" ]] && pol=self-merge` (`scripts/build-loop.sh:311`). T5 passes for all ten combinations.

**Evidence:** `scripts/build-loop.sh:311`, `test/scripts/build-loop-read.bats:315-324`

---

## Claim 44: aaae80c6 message, "LOOP reads the tip as a marker only when ... an exact subject, alone on its first line; a "handoff:" tip that breaks a rule is a skip that names the rule and never echoes the subject."

**Location:** commit `aaae80c6` (message body, paragraph 2)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the marker rule and the never-echo property. The "subject" mismatch is the same as Claim 10.
**Legibility-target:** for-author

Never-echo holds: the skip is `"skip $a: the tip of $br starts \"handoff:\" but is not a marker: ${kind#bad }"` (`scripts/build-loop.sh:325`), and every `bad` text is constant (`:264-279`). "A 'handoff:' tip that breaks a rule is a skip" is not quite right. A message with a leading blank line has git subject `handoff: ready` but reads `working`, and a whitespace-only second line is called "runs onto a second line" (`probe-marker.log`). Both fail closed. This is in an unmerged commit message.

**Evidence:** `scripts/build-loop.sh:257-269`, `scripts/build-loop.sh:325`, `.../fact-check/probe-marker.log`

---

## Claim 45: aaae80c6 message, "Two open briefs on main naming one branch (ignoring case) both skip (F31)."

**Location:** commit `aaae80c6` (message body, paragraph 2)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers briefs directly under docs/working/briefs/ (true), and a closed/ brief reading open (not counted).
**Legibility-target:** for-author

The claim is true for open briefs under `docs/working/briefs/` (T28 passes). It is false for an open `closed/` brief plus an open brief on the same branch: both print `ok ... open ... feat/y` (`probe-shared.log`), because `git ls-tree ... -- docs/working/briefs/` (`scripts/build-loop.sh:287`) does not recurse. This is in an unmerged commit message. See Claims 13 and 22.

**Evidence:** `scripts/build-loop.sh:287-291`, `.../fact-check/probe-shared.log`

---

## Claim 46: aaae80c6 message, "The lib is called in-process (no dev-cycle.sh subprocess), so the import walk's per-process cache question does not arise here."

**Location:** commit `aaae80c6` (message body, paragraph 3)
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the lib is sourced, not run as dev-cycle.sh. check_brief, check_branch and marker_kind still run in `$(...)` subshells (forks of this process). Does not establish anything about the walk, which `--status` never calls: no `imported_names` or `IMPORTED` reference in scripts/build-loop.sh.
**Legibility-target:** for-orchestrator-synthesis

The lib is loaded with `source "$READ_LIB"` (`scripts/build-loop.sh:79`) and called as `out="$(check_brief "$a")"` (`:298`). A grep for `imported_names\|IMPORTED` in scripts/build-loop.sh returns nothing (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `scripts/build-loop.sh:79`, `scripts/build-loop.sh:298`, `scripts/lib/dev-cycle-read.sh:426-432`

---

## Claim 47a: aaae80c6 message, "check_brief's git log -1 -G'^Status: ' costs about 1 ms per brief on this repo (2137 commits, 1017 first-parent): the walk stops at the commit that added or last changed the Status line, so its cost tracks the brief's age, not the repo's."

**Location:** commit `aaae80c6` (message body, "Measured" paragraph)
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo counts on main (f6357ea1), the per-call cost, and the early-stop mechanism. "Age" here means first-parent commits since the last Status-line change.
**Legibility-target:** for-orchestrator-synthesis

Command: `bash .../fact-check/measure.sh` (cwd the worktree), run at 2026-10-05T11:49:04Z with exit 0. It printed `commits 2137 first-parent 1017` for main. Each real brief costs `git log -G avg 1 ms`, stops at `cac2ba0c`, and walks 4 first-parent commits, the same as a bare `git rev-parse` (1 ms). A full no-match walk costs 6 ms and an old file 8 ms, which confirms the early stop. The call is at `scripts/lib/dev-cycle-read.sh:355`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:355-356`, `.../fact-check/measure.log`

---

## Claim 47b: aaae80c6 message, "--status over the 3 real briefs: 79 ms."

**Location:** commit `aaae80c6` (message body, "Measured" paragraph)
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one re-measurement under concurrent review load. Does not establish the original environment's timing.
**Legibility-target:** for-orchestrator-synthesis

The same `measure.sh` run gives `109 ms`, `112 ms` and `112 ms` for `bash scripts/build-loop.sh --status <3 briefs>`. Other reviews ran concurrently. Wall time is environment-dependent; the mechanism claim (47a) holds.

**Evidence:** `scripts/build-loop.sh:333-337`, `.../fact-check/measure.log`

---

## Claim 48: aaae80c6 message, "The real briefs have no Branch: line yet, so --status skips them until the cycle writes machine lines (U4)."

**Location:** commit `aaae80c6` (message body, Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three briefs on main at f6357ea1. Does not establish anything about U4.
**Legibility-target:** for-orchestrator-synthesis

`measure.log` shows `skip docs/working/briefs/2026-10-02-build-loop-handoff.md: no Branch: line on the default branch`, and the same for the other two. The message comes from `scripts/build-loop.sh:303`.

**Evidence:** `scripts/build-loop.sh:303`, `.../fact-check/measure.log`

---

## Claim 49: aaae80c6 message, "The fixtures' commit_all allows an empty commit, so re-writing a file unchanged no longer fails a test."

**Location:** commit `aaae80c6` (message body, Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** As Claim 23. `git diff 859e29e8 aaae80c6 -- test/lib/` shows exactly this change.
**Legibility-target:** for-orchestrator-synthesis

`commit_all() { git add -A && git commit -q --allow-empty -m "${1:-fixture}"; }` (`test/lib/build-loop-fixtures.bash:23`).

**Evidence:** `test/lib/build-loop-fixtures.bash:23`

---

## Claim 50: aaae80c6 message, "The "--status --settings" usage case is dropped from the test: a path argument is data, refused per argument as dev-cycle.sh does."

**Location:** commit `aaae80c6` (message body, Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test change and the runtime result. The usage loop still lists bare `"--status"`, which is a different case (no path) and still exits 1.
**Legibility-target:** for-orchestrator-synthesis

`git diff 859e29e8 aaae80c6 -- test/` changes `"--status" "--status --settings"; do` to `"--status"; do`, now at `test/scripts/build-loop-read.bats:179`. A probe of `build-loop.sh --status --settings` prints `skip --settings: not an allowed path form` with exit 0, via check_brief's pathform skip (`scripts/lib/dev-cycle-read.sh:323`).

**Evidence:** `test/scripts/build-loop-read.bats:179`, `scripts/lib/dev-cycle-read.sh:323`

---

## Claim 51: 553a50d5 message, "U1c stays at 399 changed code lines against U1b."

**Location:** commit `553a50d5` (message body)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers pr-prep step 1a's count with BASE=feat/build-loop-u1b (tip 1d79ffef). Does not establish whether that BASE is the right one, which the stack description says it is.
**Legibility-target:** for-orchestrator-synthesis

Command: `BASE=feat/build-loop-u1b; git diff --numstat "$BASE"...553a50d5 -- ':(top)' ':(top,exclude)docs/' | awk '{ n += $1 + $2 } END { print n+0 }'` (the rule at `workflows/pr-prep.md:91`). It ran in the worktree at 2026-10-05T11:48:47Z with exit 0 and printed `399`. The numstat is 164+8 + 36+2 + 186+3.

**Evidence:** `workflows/pr-prep.md:86-92`, `.../fact-check/linecount.log`

---

## Claim 52: 553a50d5 message, "this says four lines, three of them from docs/dev-cycle.md"

**Location:** commit `553a50d5` (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header text after the commit. The behaviour is in Claim 1.
**Legibility-target:** for-orchestrator-synthesis

`#   --settings  four lines from the default branch's commit, never the working` / `#             tree (a build loop can write any working tree). Lines 1-3 from` (`scripts/build-loop.sh:10-11`).

**Evidence:** `scripts/build-loop.sh:10-12`

---

## Claims Requiring Attention

### Incorrect
- **Claim 12b** (`scripts/build-loop.sh:56-57`): the skip list says a *missing* Dispatched: line is a skip. Code (`:306`) and the same header (`:53-54`) give 0. It should read "its Branch: line is missing or malformed, or its Dispatched: line is malformed". This is a doc-only defect in the `--status` contract text on the unmerged branch.

### Stale
- none

### Mostly Accurate
- **Claim 2** (`scripts/build-loop.sh:27-32`): IDs are compared as written (`H01` ≠ `H1`), and near-miss shapes (`* H1:`, tab after colon, indented, lowercase, `1. H1:`, `> H1:`) are silently not constraints.
- **Claim 4** (`scripts/build-loop.sh:36-37`): "from the default branch's commit" omits check_brief's working-tree symlink check. A working-tree symlink at the brief path makes it skip.
- **Claim 10** (`scripts/build-loop.sh:51-53, 59-60`): "subject" is the raw first message line. A leading blank line reads working (not a skip), and a whitespace-only second line skips as "runs onto a second line". Both fail closed.
- **Claim 13** (`scripts/build-loop.sh:58-59`): the F31 skip applies only when the brief itself is open, and counts only briefs directly under docs/working/briefs/.
- **Claim 17** (`scripts/build-loop.sh:179-182`): --status reads POLICY but not NEVER. NEVER is for the gate only.
- **Claim 21** (`scripts/build-loop.sh:275-277`): `local LC_ALL=C` works (bytes), but on return bash restores an uninstalled caller locale with a stderr warning (`build-loop.sh: line 323: warning: setlocale…`) for stopped/bad-subject tips.
- **Claim 22** (`scripts/build-loop.sh:281-282`): "open brief on main" means open, readable and directly under docs/working/briefs/ with a well-formed Branch: line.
- **Claim 27** (`test/lib/build-loop-fixtures.bash:57-60`): `tip` stores MESSAGE plus a trailing newline, not exactly MESSAGE.
- **Claim 32** (`test/scripts/build-loop-read.bats:244`): spoofs read as a "not a marker" skip, not "unreadable".
- **Claim 41** (commit 859e29e8): the "without echoing the reason" assertion covers the é and ESC cases, not bidi.
- **Claim 42** (commit aaae80c6): the name also reaches `git check-ref-format` (twice), not only show-ref --verify.
- **Claim 44** (commit aaae80c6): same subject-definition gap as Claim 10.
- **Claim 45** (commit aaae80c6): a closed/ brief reading open is not counted for F31.

### Unverifiable
- **Claim 3** (`scripts/build-loop.sh:27, 32`): the prompt seeding and the ok-only dispatch need U3/U4 code. Both are consistent with the plan.
- **Claim 47b** (commit aaae80c6): 79 ms not reproduced. This run measured 109-112 ms under concurrent load, which is environment-dependent.

## Goal-Alignment Note
- Success criterion (restated verbatim): Your report saved at the path given in your task tail, structured per your skill, with every finding carrying a verbatim Evidence quote at a `path:line` in this worktree.
- Answered: yes — 54 claim atoms verdicted, every executable guarantee executed, with logs in the scratch dir.
- Out of scope: the lib's own rules (check_brief, check_branch, FENCE_AWK), which are context and were cited only where this unit relies on them; U1b's --settings lines 1-3.
- Escalate:
  - api-consistency-reviewer / security-reviewer: `scripts/build-loop.sh:152` and `:160`. A hard constraint written in a near-miss shape (`* H1:`, `H1:<TAB>`, indented, `1. H1:`, `> H1:`, lowercase) is dropped silently rather than refused. A file whose other lines are well-formed still reads `constraints ok`, which is the line that gates dispatch (plan `:260`), so a mis-bulleted hard constraint disappears from the gate's view without a WHY.
  - api-consistency-reviewer: `scripts/build-loop.sh:56-57`. The `--status` skip contract misstates the Dispatched:-missing case (Claim 12b); U4 binds to this text.
  - architecture-review / api-consistency-reviewer: `scripts/build-loop.sh:287`. F31 counting ignores `docs/working/briefs/closed/`, although `--status` accepts closed/ paths and reports their STATE.
  - performance-reviewer (informational): `scripts/build-loop.sh:277`. Under an uninstalled caller locale, each stopped or bad-subject tip adds a setlocale warning to stderr on function return.
- Questions I would have asked: whether a `closed/` brief can legitimately read `Status: open` (if not, Claims 13/22/45 shrink to wording).
- Decisions I made: I split the Dispatched atom out of the skip-list sentence (12a/12b) because the halves earn different verdicts. I verdicted the 79 ms figure Unverifiable, not Incorrect, because wall time under concurrent review load cannot refute it. One probe (`printf 'x' | git commit-tree …`, run to confirm commit-tree stores the message as given) wrote a single dangling loose commit object into the shared repository's object store, with no ref and no working-tree change. It is unreachable and will be pruned by gc.
