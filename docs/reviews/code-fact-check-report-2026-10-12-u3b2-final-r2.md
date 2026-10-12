Commit: 4afdd68b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b2 (branch `feat/build-loop-u3b2`, HEAD 4afdd68b)
**Scope:** full branch diff `main...HEAD` (main b5f21758): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-orchestrator.bats`, `docs/working/plan-build-loop-handoff.md` (U3b2 "As built" note), `docs/reviews/override-log.md` (rows 718-728), the rubric's Fixed claims, and commit messages 1d829fee, cca66dc2, 4afdd68b. Stage-1 replicate r2, final confirming pass (k=3).
**Checked:** 2026-10-12
**Total claims checked:** 32
**Summary:** 27 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination log read (`docs/reviews/hallucination-patterns.md`, 5 entries). Claim 21a resembles the logged class "a specific measured value quoted from a checked-in artifact set that does not contain it", though here it is a generalisation, not a number. No claim matches a logged pattern exactly.

Legibility target for every claim below: **the orchestrator and the U4 implementer**. They will act on the header, the plan note and the override rows as the --main-log contract.

## Execution provenance

All probes ran from cwd `/tmp`. Each script made its own `mktemp -d /tmp/u3b2rv-fcf-XXXX` directory and cd'd into it. Fixtures used `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`. Captured outputs are in the session scratchpad `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/`:

| ID | Command | Start (UTC) | Exit | Output |
|---|---|---|---|---|
| X1 | `timeout 1200 bash fcf-r2-mut.sh`: bats `-f main-log` on HEAD, on six mutants, on 1d829fee's script, and on cca66dc2's script with both test files | 2026-10-12T23:16:47Z | 0 | `fcf-r2-mut.log` |
| X2 | `timeout 600 bash fcf-r2-probe.sh`: fixture repo covering gate, chore, answers, SINCE and objects | 23:17:44Z | 0 | `fcf-r2-probe.log` |
| X3 | `timeout 300 bash fcf-r2-probe2.sh`: header route change plus answer; Status flip plus answer in one hunk | 23:18:00Z | 0 (script) | `fcf-r2-probe2.log` |
| X4 | `timeout 1500 bash fcf-r2-real.sh`: `git clone --no-local /workspace` at 34cf382f, `--main-log ROOT` with HEAD's and cca66dc2's scripts, timed, loose objects counted | 23:19:19Z | 0 | `fcf-r2-real.log` |
| X5 | `timeout 120 bash fcf-r2-mk.sh`: `TMPDIR` set to a missing directory | 23:20:41Z | 0 (script; build-loop exit 1) | `fcf-r2-mk.log` |
| X6 | `timeout 900 bash fcf-r2-ren.sh`: 3,000 files, branch renames d/ to e/ and edits every file, main edits the same files, gate-shaped merge | 23:20:52Z | 0 | `fcf-r2-ren.log` |
| X7 | `timeout 120 bash fcf-r2-ours.sh`: a chore-shaped `git merge -s ours`, loose objects counted | 23:21:48Z | 0 | `fcf-r2-ours.log` |

---

## Claim 1: Rubric fact-check counts: "31 claims: 24 Verified, 7 Mostly Accurate, 0 Incorrect" (i1); "36 claims, 29 Verified, 5 Mostly Accurate, 2 Incorrect" (i2)

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:5`, `:40`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts against the two reports' Summary lines. It does not re-verdict the claims inside those reports.

`code-fact-check-report-2026-10-12-u3b2-i1.md:9-10` reads `**Total claims checked:** 31` and `**Summary:** 24 verified, 7 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable`. The i2 report (`:9-10`) reads `36` and `29 verified, 5 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable`.

**Evidence:** `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md:9-10`, `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i2.md:9-10`

---

## Claim 2: D1 "Fixed (tree must equal merge-tree's clean merge of the parents; test; mutant killed)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both two-parent branches of `log_class`, killed separately. It does not establish that merge-tree's tree equals every default `git merge` result under every caller configuration (see Claim 13's residue).

Both branches call `clean_merge || return 0` (`scripts/build-loop.sh:1659`, `:1667`). In X1, deleting the gate call failed test 2 (`not ok 2`), and deleting the chore call also failed test 2. HEAD passed both tests. 1d829fee's script failed test 2.

**Evidence:** `scripts/build-loop.sh:1644-1648`, `scripts/build-loop.sh:1659`, `scripts/build-loop.sh:1667`, `test/scripts/build-loop-orchestrator.bats:195-207`, fcf-r2-mut.log

---

## Claim 3: D2 "Fixed (at least one added answer line; the deleted-answer test killed the mutant ...)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `n > 0` requirement and the counting of `+` lines only. It does not establish that the header-match rule is pinned by a test (it is not: Claim 29).

`exit !(n > 0 && !bad)` (`scripts/build-loop.sh:1631`) and `if (s == "+") n++` (`:1627`). In X1, both mutants failed test 2: dropping `n > 0`, and counting every answer line (`n++` on any sign).

**Evidence:** `scripts/build-loop.sh:1612-1631`, fcf-r2-mut.log

---

## Claim 4: D4 and D9 Fixed ("main MAIN -" first; empty subject prints "-")

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:25`, `:30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal's first line and the empty-subject rendering. It does not cover the rev-list-failure refusal, which was read but not executed.

`{ echo "main $MAIN_SHA -"; echo "refuse main-log: $1 is not on ..."; return 1; }` (`scripts/build-loop.sh:1696-1697`; refuse echo at `:1697`). In X2, a missing 40-hex SINCE printed `main 487a1d40... -` and then the refuse line, exit 2. An empty-message commit printed `other 5ee39163... -`.

**Evidence:** `scripts/build-loop.sh:1690-1703`, fcf-r2-probe.log

---

## Claim 5: E1 "The 'Status flip alone' test committed an empty diff ... Fixed (flip before the route change; each near-miss commit asserted non-empty)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of the near-miss commits and the non-empty assertion. It does not establish that each near miss is classified other for the reason its comment names (Claim 29).

At cca66dc2 the combined route-and-status sed ran first, and `q 's/\*\*Status:\*\* OPEN/**Status:** ANSWERED/'` came after it, when no OPEN was left (cca66dc2 test lines 215-216). HEAD runs the flip first and adds `for i in 4 3 2 1; do [ -n "$(git diff "main~$i" "main~$((i - 1))")" ] || ...` (`test/scripts/build-loop-orchestrator.bats:216-217`).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:215-217`, `git show cca66dc2:test/scripts/build-loop-orchestrator.bats` lines 215-216

---

## Claim 6: E4 "merge-tree ran on every merge before the subject could match (+1.5 s on this repo's history ...) Fixed (clean_merge after the subject)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:47`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium (timings on a shared host, load average about 3)
**Verification mode:** executed
**Scope:** Covers the ordering and the saving at a root SINCE on a clone of /workspace at 34cf382f. It does not establish timings on other hosts.

`clean_merge` now runs inside the subject-matched branches (`scripts/build-loop.sh:1657-1659`, `:1665-1667`). X4: HEAD took 7,172 ms and 7,761 ms; cca66dc2 took 8,787 ms and 9,497 ms. The saving is about 1.6-1.7 s.

**Evidence:** `scripts/build-loop.sh:1649-1686`, fcf-r2-real.log

---

## Claim 7: E8 "SUBJ=- first"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a failed `cat-file` read, which prints `-`. It does not cover a perl failure after SUBJ was set, which never sets SUBJ either.

`CLASS=other; SUBJ=-` comes before `gate_git cat-file commit "$c" > "$GATE_TMP/c" || return 0` (`scripts/build-loop.sh:1651-1652`).

**Evidence:** `scripts/build-loop.sh:1649-1656`

---

## Claim 8: Override row: "gate_msg is the one definition ... land and log_class both call gate_msg; the reader compares the commit's message byte for byte"

**Location:** `docs/reviews/override-log.md:718`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two callers and the byte compare. It does not cover gate merges written by older code (gate_msg's own comment covers them).

`gate_msg "${VERDICT[branch]}" "$what" "${VERDICT[stem]}" "${2-}" > "$GATE_TMP/msg"` (`scripts/build-loop.sh:1461`) and `gate_msg "$b" "$x" "$p" "$q" > "$GATE_TMP/want" && cmp -s "$GATE_TMP/want" "$GATE_TMP/m" && CLASS=gate` (`:1664`). In X2 an approved-merge message read gate, and the same message with one extra trailing newline read other.

**Evidence:** `scripts/build-loop.sh:1374-1377`, `scripts/build-loop.sh:1461`, `scripts/build-loop.sh:1664`, fcf-r2-probe.log

---

## Claim 9: Override row (chore hand-off): --no-ff, git's default merge, the subject tail, a docs/working/cycles/cycle-*.md record with mode 100644 holding "Branch: B", any line of which counts

**Location:** `docs/reviews/override-log.md:719`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reader's acceptance rules the row hands to U4. It does not establish that "an unfenced line near the top" is needed: the reader also accepts a fenced line further down (X2), so that phrase is a convention for U4, not a reader rule.

X2 results: `' into main'` read chore; `' x'` read other; record mode 755 read other; a CRLF record read chore; a fenced `Branch:` line after other content read chore. In X7 an `-s ours` chore merge read other.

**Evidence:** `scripts/build-loop.sh:1665-1673`, fcf-r2-probe.log, fcf-r2-ours.log

---

## Claim 10: Override rows 720-725 (strict answers false positives; history not re-hashed; chore's other paths unread; caller -c pairs unchecked; three diff-tree readers; record name)

**Location:** `docs/reviews/override-log.md:720-725`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's description of the code. It does not judge the recorded Defer or Won't-Fix reasoning beyond whether its premises hold.

- Answer lines: any changed line that is not blank, an answer label or a `**Needs:**` line sets `bad = 1` (`scripts/build-loop.sh:1629`), so a multi-line answer, a note or an archive move reads other. X2 a9 (`questions-archive.md` added) read other.
- Caller pairs: `if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` (`:631`).
- Record names: the lib accepts only `^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$` (`scripts/lib/dev-cycle-read.sh:245`), while the reader takes `^docs/working/cycles/cycle-[^/]+\.md$` (`scripts/build-loop.sh:1670`).
- Chore paths: the chore loop only `continue`s past non-record paths (`:1670`).

**Evidence:** `scripts/build-loop.sh:631`, `scripts/build-loop.sh:1665-1684`, `scripts/lib/dev-cycle-read.sh:245`

---

## Claim 11a: "Every commit on this repo's main today reads other (hand merges, checkpoint commits)"

**Location:** `docs/reviews/override-log.md:726`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the class of every first-parent commit after the root on a clone at 34cf382f. dfe4c0df has been on main since 2026-09-28 (an ancestor of b5f21758), so the claim was also false when written. It does not change the row's conclusion: any other still stops dispatch.

In X4, `--main-log ROOT` printed `1117 other` and `1 answers`: `answers dfe4c0df99c4fb27991355c6632f936a3d8fe1ee docs(questions): answer Q-093 [1] and Q-094 [1]`. `git merge-base --is-ancestor dfe4c0df b5f21758` succeeded. Text error, not behavioural. Precise version: "every commit but one on this repo's main reads other (dfe4c0df, a hand answer commit, reads answers)."

**Evidence:** `docs/reviews/override-log.md:726`, fcf-r2-real.log

---

## Claim 11b: "per-commit cost ~6-9 ms, ~7-10 s for a SINCE at this repo's root (1,119 commits, 422 merges)"; "it runs --state's gate but the caller check"

**Location:** `docs/reviews/override-log.md:726`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** Medium (shared host)
**Verification mode:** executed
**Scope:** Covers the timings and counts at main 34cf382f, and the gate order. It does not establish timings on another host.

- Counts: `git rev-list --first-parent main | wc -l` gives 1119 (1118 after the root, the N that was printed), with 422 first-parent merges.
- Timing: HEAD took 7.17 s and 7.76 s, about 6.4-6.9 ms per commit (X4).
- Gate order: `GATED` is set for main-log and `state_gate` runs, while `caller_gate` runs only for `state` (`scripts/build-loop.sh:629-632`).

**Evidence:** `scripts/build-loop.sh:629-632`, fcf-r2-real.log

---

## Claim 12: Override row (answers counts any added label from anyone; "loops are told never to write the questions files")

**Location:** `docs/reviews/override-log.md:727`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the label match across entries and the prompt line. It does not establish that loops obey the prompt.

`t ~ /^Q-[0123456789]+:/` matches any entry's ID (`scripts/build-loop.sh:1627`). In X2, `Q-002: [2]` and `Q-003: [1]` (in the archive) read answers. The prompt says `Never write the questions files, the roadmap, ...` (`:1598`).

**Evidence:** `scripts/build-loop.sh:1598`, `scripts/build-loop.sh:1627`, fcf-r2-probe.log

---

## Claim 13a: "clean_merge's merge-tree writes merged objects into the real store (... 87 objects, 616 KiB over this repo's history; idempotent after)"

**Location:** `docs/reviews/override-log.md:728`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pre-E4 behaviour, cca66dc2's merge-tree on every merge. It does not apply to HEAD, which wrote 0 objects on the same history.

X4 ran on a fresh clone with 0 loose objects. After cca66dc2's script: `count: 87`, `size: 616`. After a second run: still `87`, `616`. After HEAD's run: `0`.

**Evidence:** `scripts/build-loop.sh:1644-1648`, fcf-r2-real.log

---

## Claim 13b: "(a hand-resolved or conflicting merge adds unreachable ones once ...) and a constructed merge with thousands of modified renames costs ~5 s per run"

**Location:** `docs/reviews/override-log.md:728`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the object-writing cases and one rename construction. It does not reproduce the source measurement's 100,001-file tree.

- Objects: a merge made with `-s ours` (neither conflicting nor hand-resolved) also added a new object (X7: `count: 13` before, `count: 14` after).
- Renames: X6's 3,000 renamed-and-edited files, also edited on main, cost 681 ms against a 261 ms baseline. The ~5 s figure comes from `performance-review-2026-10-12-u3b2-i2.md:26` (5,000 inexact renames on a 100,001-file tree, merge-tree alone 5.47 s), so the cost needs a very large tree as well.

Precise version: "any merge whose tree is not merge-tree's (hand-resolved, conflicting, a non-default strategy) adds ...; thousands of renames both sides touch, on a ~100k-file tree, cost ~5 s."

**Evidence:** `docs/reviews/performance-review-2026-10-12-u3b2-i2.md:26`, fcf-r2-ours.log, fcf-r2-ren.log

---

## Claim 14: Plan "As built" note: gated after state_start; reads in the gate repository; SINCE full id (short id is usage, exit 1), else "main MAIN -" and "refuse main-log: WHY"; output format; exit 2 on any other or refusal

**Location:** `docs/working/plan-build-loop-handoff.md:329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers usage, refusal, output and exit codes for the cases probed. It does not cover a rev-list failure, which was read but not executed.

The argument check is `[[ $# -eq 2 && "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage ...` (`scripts/build-loop.sh:453`). X2 results:

- an uppercase SINCE: exit 1 with the usage text;
- a missing id: `main M -`, the refuse line, exit 2;
- SINCE equal to MAIN: `main M 0`, exit 0.

The bats tests at HEAD pass (X1).

**Evidence:** `scripts/build-loop.sh:451-453`, `scripts/build-loop.sh:1690-1717`, fcf-r2-probe.log, fcf-r2-mut.log

---

## Claim 15: Plan note: the class rules (clean merge; gate byte for byte; chore record names the branch; answers matched per hunk with at least one added answer line) and the bootstrap ("running --main-log with a full id off main's history and recording the MAIN its 'main MAIN -' line prints")

**Location:** `docs/working/plan-build-loop-handoff.md:329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rules as summarised. Header nuances (CR, any line of the record) are checked in Claims 18-20.

All of the following come from X2 and X3:

- Bootstrap: an id not on main's history printed `main 487a1d40... -`.
- Answers in one hunk: a Status flip plus an answer in the same hunk read answers.
- Header rule: a route change plus an answer read other.
- Gate and chore: see Claims 8-9.

**Evidence:** `scripts/build-loop.sh:1612-1686`, fcf-r2-probe.log, fcf-r2-probe2.log

---

## Claim 16: Header: "--main-log ... after --state's gate but its caller check. SINCE: a full 40- or 64-hex id of a commit on the default branch's first-parent history"

**Location:** `scripts/build-loop.sh:138-142`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the top-level gate order and the argument regex. It does not cover the caller-environment checks that --main-log skips (row 723 records those).

`GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1`, then `if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi`, then `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`scripts/build-loop.sh:629-632`). The main-log case runs `state_start` (`:1715`).

**Evidence:** `scripts/build-loop.sh:629-634`, `scripts/build-loop.sh:1714-1717`

---

## Claim 17: Header output: "main MAIN N ... oldest first ('-' before a refusal)"; "SUBJECT: the message's first line, display only ('-' when empty, so '-' may also be the text '-')"

**Location:** `scripts/build-loop.sh:142-150`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line format, the order and the `-` rendering. It does not cover subjects altered by the lib's scrub.

`done < <(tac "$GATE_TMP/after")` (`:1701`). In X2 the empty-message commit and the `-m -` commit both printed `-`, oldest first.

**Evidence:** `scripts/build-loop.sh:1690-1703`, fcf-r2-probe.log

---

## Claim 18: Header: "A two-parent commit is gate or chore only when its tree is the clean merge of its parents (merge-tree, which writes the merged objects as --check's does), as --merge and a git merge with git's defaults write it (no -s or -X, no merge.* config, no merge attribute); an amended or hand-resolved merge is other"

**Location:** `scripts/build-loop.sh:150-155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the following:
- `--merge`'s own result: the same `merge-tree --write-tree --no-messages MAIN TIP` at `:1017` as at `:1646`, and test 1 passes.
- A default `git merge --no-ff` (X2 chore cases).
- Conflicting, amended and `-s ours` merges reading other (X2, X7, X1).

It does not establish that the list of knobs is complete: rename-related `diff.*` settings, which `git merge` also honours, are not named. No probe showed a clean tree that differs because of them.

`t="$(gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}")" && [[ "$t" == "$(LC_ALL=C awk '/^tree / { print $2; exit }' "$GATE_TMP/c")" ]]` (`:1646-1647`).

**Evidence:** `scripts/build-loop.sh:1017`, `scripts/build-loop.sh:1644-1648`, fcf-r2-probe.log, fcf-r2-ours.log, fcf-r2-mut.log

---

## Claim 19: Header gate and chore rules: gate "the message --merge writes, byte for byte"; chore subject "then the end, ' into ' or ':' (any other text after the quote is other)", B pattern, record "(docs/working/cycles/cycle-*.md, mode 100644) holding the line 'Branch: B', anywhere in it (a trailing CR dropped)"

**Location:** `scripts/build-loop.sh:155-162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all the listed rules. It does not establish that DATE is a valid calendar date (it is digits only), and "mode 100644" is checked on the new side only (`:[01234567]{6}\ 100644`).

The chore subject regex ends `\'($|\ into\ |:)` (`:1665`). The record check is `{ sub(/\r$/, "") } $0 == w { f = 1 }` (`:1672`). For X2 results see Claim 9, plus the trailing-newline gate case reading other.

**Evidence:** `scripts/build-loop.sh:1657-1673`, fcf-r2-probe.log

---

## Claim 20: Header answers rules: questions.md or questions-archive.md only, mode 100644 both sides, blank / answer lines ("after an optional '- ', 'Q-' and digits and ':', or a bold '**Answer:', '**Answer (' or '**Answered' in any case") / header lines whose Status field alone changed (per hunk, in order); at least one answer line added (any entry's)

**Location:** `scripts/build-loop.sh:162-171`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed case. It does not establish acceptance of an indented answer: `  Q-001: [1]` reads other, since only `- ` is stripped, which matches "after an optional '- '".

X2 results:
- answers: `- Q-001: [1]`, `**answer:** 1`, `**ANSWERED** yes`, `- **Answer (user):** [2]`, a CRLF answer line, an archive answer;
- other: an indented answer, a mode-755 questions.md, a second file changed.

X3 results: a route change plus an answer read other; a Status flip plus an answer in one hunk read answers.

**Evidence:** `scripts/build-loop.sh:1612-1631`, `scripts/build-loop.sh:1674-1684`, fcf-r2-probe.log, fcf-r2-probe2.log

---

## Claim 21: Header: "Any other commit, or one whose message, parents or changes cannot be read, is other. The class is read from the commit's own text (and commits before MAIN, and objects not in MAIN's tree, are not re-hashed)"

**Location:** `scripts/build-loop.sh:171-176`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the read failures and the store_check scope. It does not establish that an unreadable message makes a one-parent answers commit other: the answers branch never reads the message, though a perl failure returns 0 (other) first.

Each read is guarded with `|| return 0` and CLASS starts as other (`:1651-1655`, `:1668`, `:1675`, `:1682`). `store_check --main "$MAIN_SHA"` (`:1224`) re-hashes MAIN's commit, its tree and every tree and blob below (`:976-993`), and nothing else.

**Evidence:** `scripts/build-loop.sh:973-1001`, `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1649-1686`

---

## Claim 22: Header: "or 'main MAIN -' and refuse main-log: WHY, when SINCE (a full id; a short one is a usage error, exit 1) is not on that history ... or it cannot be listed"

**Location:** `scripts/build-loop.sh:177-180`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the off-history and usage cases. The "cannot be listed" branch was read, not executed.

X2 and bats test 2: a 12-hex id gave exit 1 with `--main-log takes one full 40- or 64-hex commit id`; an off-history id gave `main T -` and the refuse line, exit 2.

**Evidence:** `scripts/build-loop.sh:1694-1697`, fcf-r2-probe.log, fcf-r2-mut.log

---

## Claim 23: File header: "Writes nothing but --check's and --main-log's merge objects ... and its own temporary directory, removed at exit"

**Location:** `scripts/build-loop.sh:410-416`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --main-log's writes, which are merge-tree objects and GATE_TMP. It does not re-verify the other modes' lists.

The only writing git call in log_class is `merge-tree --write-tree`. The others are `cat-file`, `diff-tree` and `rev-list`. X2: a conflicting gate-shaped merge added 2 loose objects (123 to 125), and a second run added none.

**Evidence:** `scripts/build-loop.sh:1644-1703`, fcf-r2-probe.log

---

## Claim 24: Exit section: "0 ... for --main-log no other line"; "2 ... --main-log's other or refuse line"; "1 ... a failed mktemp (--state, --main-log, ...; no line printed)"

**Location:** `scripts/build-loop.sh:419-428`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exits 0, 2 and 1 (mktemp). It does not cover a failed command's own status inside main_log; none reaches the top level, because `main_log ... || exit 2` disables set -e inside it.

- Exit 0 and exit 2: X2.
- Exit 1 (X5): with `TMPDIR` set to a missing directory, the script exited 1 with empty stdout and mktemp's error on stderr.

**Evidence:** `scripts/build-loop.sh:1220-1223`, `scripts/build-loop.sh:1714-1717`, fcf-r2-mk.log

---

## Claim 25: gate_msg comment: "log_class parses the fields back out by the same shape (subject, line 3, line 4) and compares bytes"

**Location:** `scripts/build-loop.sh:1368-1373`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parser's indices. It does not cover messages longer than five lines, where `cmp` still compares the whole message.

`mapfile -t -n 5 m`, `[[ "${m[2]-}" =~ ^Build-loop-gate:\ (.+)$ ]]`, `[[ "${m[3]-}" =~ ^Build-loop-approved:\ (Q-[0123456789]+)$ ]]` (`:1656`, `:1660`, `:1663`). land passes `"${2-}"`, which is empty for self-merge, so the no-trailer path matches the old `[[ "$1" != approved ]]` form.

**Evidence:** `scripts/build-loop.sh:1374-1377`, `scripts/build-loop.sh:1393-1396`, `scripts/build-loop.sh:1461`, `scripts/build-loop.sh:1655-1664`

---

## Claim 26: ANSWERS_AWK comment: rules per hunk; "a Status flip or a deleted answer alone adds none"; "Any added answer label counts, in any entry and from anyone"; labels are --check-answer's

**Location:** `scripts/build-loop.sh:1602-1610`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the label set compared with the lib (both strip `^- ` and use `^\*\*answer(:|ed| \()` case-folded). It does not claim the same entry scope: the lib requires the entry's own `Q-NNN:`, while this reader takes any.

Lib: `line = $0; sub(/^- /, "", line)` and `if (low !~ /^\*\*answer(:|ed| \()/) next` (`scripts/lib/dev-cycle-read.sh:2055`, `:2058`). Here: `t = l; sub(/^- /, "", t)` and `tolower(t) ~ /^\*\*answer(:|ed| \()/` (`scripts/build-loop.sh:1626-1627`). The behaviour checks are in X1, X2 and X3.

**Evidence:** `scripts/build-loop.sh:1612-1631`, `scripts/lib/dev-cycle-read.sh:2019-2075`, fcf-r2-probe.log

---

## Claim 27: log_class comment ("any failed read makes C other"; "Checked after the subject, so other merges cost no merge-tree run") and main_log comment ("Returns 1 when SINCE is refused or any commit is other")

**Location:** `scripts/build-loop.sh:1632-1640`, `scripts/build-loop.sh:1688-1689`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering and the return values. It does not cover the phrase "the record it adds", which also covers a changed record (`[AM]`); this is harmless for where reads happen.

X4: HEAD wrote no objects over 422 merges, and cca66dc2 wrote 87. `return "$o"` (`:1702`), and `o=1` on other (`:1700`).

**Evidence:** `scripts/build-loop.sh:1649-1703`, fcf-r2-real.log

---

## Claim 28: clean_merge comment: "merge-tree writes the merged trees and blobs into the object store, as --check's does (only a conflicting or hand-resolved merge adds new ones)"

**Location:** `scripts/build-loop.sh:1641-1643`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which merges add objects. It does not cover merges whose original merge objects were garbage-collected.

A chore-shaped `git merge -s ours` (no conflict, no hand resolution) also added an object (X7: 13 to 14 loose). Precise version: "only a merge whose tree is not merge-tree's (conflicting, hand-resolved, a non-default strategy or option) adds new ones."

**Evidence:** `scripts/build-loop.sh:1641-1648`, fcf-r2-ours.log

---

## Claim 29: Test comment: near misses that read other include "a header line whose route changes too"

**Location:** `test/scripts/build-loop-orchestrator.bats:208-210`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test pins. It does not establish a defect in the code: X3 shows the header rule works.

The route-change commit `q 's/you: judgment/agent/'` (`:216`) adds no answer line, so it reads other through `n > 0` alone. In X1 a mutant that skips every `**Needs:**` line without comparing them (`{ next }`) still passed both tests. The header-match rule, which E1's fix meant to exercise, is unpinned (the same pattern as E1). A route change plus an added answer is the case that pins it (X3: other at HEAD).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:208-219`, `scripts/build-loop.sh:1628`, fcf-r2-mut.log, fcf-r2-probe2.log

---

## Claim 30: Commit 1d829fee: "answers (only answer and Status lines in the questions files)"

**Location:** commit 1d829fee message (body line 4)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rule at 1d829fee. It does not cover later commits.

The 1d829fee ANSWERS_AWK also passed blank lines (`if (l ~ /^[ \t]*$/) next`, carried unchanged to HEAD `:1625`). Precise version: "only blank, answer and Status-only header lines".

**Evidence:** `git show 1d829fee:scripts/build-loop.sh` (ANSWERS_AWK), `scripts/build-loop.sh:1625`

---

## Claim 31: Commit cca66dc2: "a Status flip, a deleted answer or a revert passed as answers; at least one added answer line is required" and D4/D9/text items

**Location:** commit cca66dc2 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a revert that removes an answer. It does not cover a revert that restores one, which still reads answers (E2, row 727).

X1: 1d829fee's script fails test 2, and cca66dc2's script passes its own tests and HEAD's.

**Evidence:** fcf-r2-mut.log, `scripts/build-loop.sh:1631`

---

## Claim 32: Commit 4afdd68b: "merge-tree runs only once a gate or chore subject matches (clean_merge), saving ~1.5 s and every store write on this repo's history"; "SUBJ starts as '-' so a failed read prints it too"

**Location:** commit 4afdd68b message
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** Medium (shared host timing)
**Verification mode:** executed
**Scope:** Covers this repo's history at 34cf382f, where one chore-subject merge (cac2ba0c) still runs merge-tree but writes nothing new. It does not cover other repositories.

X4: HEAD left 0 loose objects; cca66dc2 left 87; the saving was about 1.6-1.7 s. SUBJ: see Claim 7.

**Evidence:** `scripts/build-loop.sh:1651`, fcf-r2-real.log

---

## Claims Requiring Attention

### Incorrect
- **Claim 11a** (`docs/reviews/override-log.md:726`): "Every commit on this repo's main today reads other" is false. dfe4c0df ("docs(questions): answer Q-093 [1] and Q-094 [1]", on main since 2026-09-28) reads answers. Text, not behavioural. Fix the row: "every commit but one (dfe4c0df reads answers)".

### Stale
- None.

### Mostly Accurate
- **Claim 13b** (`docs/reviews/override-log.md:728`): a non-default-strategy merge (`-s ours`) also adds objects. The ~5 s rename cost needs a ~100k-file tree as well as thousands of renames that both sides touch.
- **Claim 28** (`scripts/build-loop.sh:1641-1643`): "only a conflicting or hand-resolved merge adds new ones" should be "only a merge whose tree is not merge-tree's (including -s/-X merges)".
- **Claim 29** (`test/scripts/build-loop-orchestrator.bats:208-210`): the route-change near miss reads other only through the added-answer rule. The header-match rule is unpinned (a mutant that drops it survives). Add a route change plus an answer line.
- **Claim 30** (commit 1d829fee): the answers summary omits blank lines.

### Unverifiable
- None.

## Goal-Alignment Note

Success criterion: "A code-fact-check replicate report saved at the given path in the worktree, per the code-fact-check skill."

- **Met:** this report is at `/workspace/.claude/wt-build-loop-u3b2/docs/reviews/code-fact-check-report-2026-10-12-u3b2-final-r2.md`, first line `Commit: 4afdd68b`, in the skill's schema, with the seven fields per claim, executed provenance and a legibility target.
- **Writes:** nothing else was written to the worktree or /workspace. Probes and logs live under `/tmp/u3b2rv-fcf-*` and the session scratchpad. Each probe's temp directory came from its own mktemp, and the X4 clone was removed by its script.
- **Captured output:** not under `docs/reviews/execution-logs/` (the brief forbids other writes). It is in the scratchpad files named above.
- **Hallucination log:** not updated. The one Incorrect is a false generalisation about observed behaviour, not a fabricated symbol, API or option, so it does not qualify. The brief also limits writes to this report.
- **Not done:** the rev-list-failure refusal path was not executed.
