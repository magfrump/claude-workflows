Commit: 4afdd68b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b2 (branch `feat/build-loop-u3b2`)
**Scope:** full branch `main...4afdd68b` (b5f21758..4afdd68b): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-orchestrator.bats`, `docs/working/plan-build-loop-handoff.md` (U3b2 bullet), `docs/reviews/override-log.md` rows 718-728, the rubric's Fixed claims, commits 1d829fee, cca66dc2, 4afdd68b. Final confirming pass, replicate r1 of k=3.
**Checked:** 2026-10-12
**Total claims checked:** 44
**Summary:** 41 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read; no claim below matches a logged pattern, and the one Incorrect is a measured figure that went stale, not a fabricated symbol, so nothing qualifies for the log.

Execution provenance. Every probe ran under `timeout`, with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, in a throwaway repository under `/tmp/u3b2rv-fcf-XXXX` (created and removed by the same script). Scripts and captured output are in `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/` (`pN.sh` / `pN.out`). Commands were `bash <scratch>/pN.sh`, run from cwd `/tmp`, on 2026-10-12 between 23:16Z and 23:26Z:
- p1: fixture probes (P1 approved gate, P2 amended gate, P3 hand-resolved non-gate merge, P4 chore, P5 answers, P6 failed mktemp, P7 usage and 64-hex, P8 SINCE == MAIN). Exit 0, done 23:16:59Z.
- p2: two mutants of HEAD's script, each run with `bats -f main-log`. Exit 0, done 23:17:26Z.
- p3/p4: a `--no-local` clone of /workspace main (34cf382f, 1,119 first-parent commits, 422 of them merges), with SINCE = the root commit, comparing HEAD with cca66dc2's script (objects written, timing). Exit 0, done 23:18:22Z and 23:19:21Z.
- p8/p9/p9b: rename cost. Exit 0, done 23:24:04Z and 23:25:46Z.
- p10: a gate merge with an extra file added under `--no-commit`. Exit 0, done 23:24:16Z.
- p11: a diff.renames qualifier probe, inconclusive and not used. Exit 0, done 23:24:42Z.

The suite was also run as `TMPDIR=/tmp/u3b2rv-fcf-d3aj bats -f main-log test/scripts/build-loop-orchestrator.bats`, cwd the worktree: exit 0, 2/2 ok, 23:16Z. Its output is captured at `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/bats.txt`.

---

## Claim 1: "Status (iteration 1): no 🔴 · 🟡 3 · 🟢 10" and "report ... (31 claims: 24 Verified, 7 Mostly Accurate, 0 Incorrect)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:5-7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the iteration-1 tier counts against the rubric's own tables and the i1 report's header counts. It does not establish that the i1 report's verdicts themselves are right.
**Legibility target:** a reviewer reading the rubric's status line.

The 🟡 table lists D1, D2 and D3 (three rows). The 🟢 table lists D4 through D13 (ten rows). The i1 report's header reads `**Total claims checked:** 31` / `**Summary:** 24 verified, 7 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable` (`docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md:4-5`), and a grep of its `**Verdict:**` lines counts 24 Verified, 7 Mostly and 0 Incorrect.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:5-30`, `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md:4-5`

---

## Claim 2: D1 "Fixed (tree must equal merge-tree's clean merge of the parents; test; mutant killed)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate and chore branches of log_class calling clean_merge, and a test that fails without it. It does not establish which of the near-miss rows in test 2 would kill the mutant alone, because the run stops at the first failing `ml`.
**Legibility target:** a reviewer deciding whether D1 can close.

Both two-parent branches call it after the subject matches: `b="${BASH_REMATCH[1]}"; x="${BASH_REMATCH[2]}"` / `clean_merge || return 0` (`scripts/build-loop.sh:1657-1658`), and `b="${BASH_REMATCH[1]}"` / `clean_merge || return 0` (`scripts/build-loop.sh:1665-1666`). p2 deleted both `clean_merge || return 0` lines (the grep count after the edit was 0) and ran the suite. Test 2 failed: the merge whose `feat/x` tip carries a slip commit, built with `merge-tree main feat/x`'s tree, read `gate 9828d9b5... Merge branch 'feat/x' (build-loop self-merge)` where the test wants `other`. On HEAD the same test passes (bats exit 0).

**Evidence:** `scripts/build-loop.sh:1644-1666`, `test/scripts/build-loop-orchestrator.bats:347-357`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p2.out`

---

## Claim 3: D2 "Fixed (at least one added answer line; the deleted-answer test killed the mutant; the Status-flip test was empty until E1 ...)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `n > 0` requirement, the mutant kill, and the claim that cca66dc2's Status-flip commit had nothing to flip. It does not establish that the "route change" near miss pins the header-matching rule: that commit adds no answer either, so `n > 0` alone already makes it other.
**Legibility target:** a reviewer deciding whether D2 can close.

The count is taken only on added lines, `if (s == "+") n++` (`scripts/build-loop.sh:1627`), and the pass condition is `END { flush(); exit !(n > 0 && !bad) }` (`scripts/build-loop.sh:1631`). p2's mutant `exit !(!bad)` made test 2 fail. Under the mutant, the flip commit, the blank-line commit and the deleted-answer commit all read `answers`, so each of them kills it.

At cca66dc2, the test changed route and Status together first, `q 's/you: judgment · \*\*Opened:\*\* 2026-10-12 · \*\*Status:\*\* OPEN/agent · ... **Status:** ANSWERED/'`, and only then ran `q '' ''; q 's/\*\*Status:\*\* OPEN/**Status:** ANSWERED/'` (`git show cca66dc2:test/scripts/build-loop-orchestrator.bats` lines 215-216). By then there was no OPEN left, so the flip commit was empty.

**Evidence:** `scripts/build-loop.sh:1612-1631`, `test/scripts/build-loop-orchestrator.bats:361-369`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p2.out`

---

## Claim 4: D3-D9 Fixed (hand-off text, `main MAIN -` before a refusal, re-hash wording, back-pointers, gate_msg parser note, `-` subject)

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:17-28`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fix being present: D4 and D9 by execution, D3, D5, D6 and D7 by reading the text. It does not establish the deferred rows D8 and D10-D13, which are Claims 13-17.
**Legibility target:** a reviewer deciding whether D3-D9 can close.

D4: p1/P7b printed `main 684cd163... -` and then `refuse main-log: 93f56414...d87 is not on the default branch's first-parent history at 684cd163...` (exit 2).

D9: in the suite, the empty commit prints `other $E -`, asserted at `test/scripts/build-loop-orchestrator.bats:368` (pass). It comes from `[[ -n "$SUBJ" ]] || SUBJ=-` (`scripts/build-loop.sh:1656`).

D3: the header carries the tail rule, `a subject "Merge branch 'B'" then the end, " into "` / `or ":" (any other text after the quote is other)` (`scripts/build-loop.sh:157-158`), the mode, `mode 100644` (`:161`), and the usage rule, `a short one is a usage error, exit 1` (`:178`).

D5: see Claim 28. D6: see Claims 33 and 39. D7: see Claim 32.

**Evidence:** `scripts/build-loop.sh:138-180`, `scripts/build-loop.sh:1656`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`

---

## Claim 5: "36 claims, 29 Verified, 5 Mostly Accurate, 2 Incorrect (rubric text; a test fixture), none behavioural"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts against the i2 report. It does not re-judge the i2 verdicts.
**Legibility target:** a reviewer reading the rubric.

The i2 report's header reads `**Total claims checked:** 36` / `**Summary:** 29 verified, 5 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable`, and a grep of its verdict lines gives 29, 5 and 2.

**Evidence:** `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i2.md:4-5`

---

## Claim 6: E1 "Fixed (flip before the route change; each near-miss commit asserted non-empty)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:40`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test's order, its non-empty assertion, and the flip commit carrying a real diff. It does not establish that the route-change commit tests the header rule (see Claim 3's residue).
**Legibility target:** a reviewer deciding whether E1 can close.

The test now flips first, `q 's/\*\*Status:\*\* OPEN/**Status:** ANSWERED/'; q 's/you: judgment/agent/'; q '' ''; q '/^Q-001: \[1\]$/d'`, and asserts every commit non-empty, `for i in 4 3 2 1; do [ -n "$(git diff "main~$i" "main~$((i - 1))")" ] || ...` (`test/scripts/build-loop-orchestrator.bats:366-367`). Under p2's mutant b, the flip commit read `answers c40c298a... answer`, which shows it carries a diff that only the `n > 0` rule rejects.

**Evidence:** `test/scripts/build-loop-orchestrator.bats:365-369`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p2.out`

---

## Claim 7: E4 "merge-tree ran on every merge before the subject could match (+1.5 s on this repo's history; all its store writes)" — Fixed

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:43`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timing difference and the store writes, on a clone of /workspace main with SINCE at the root, on this machine (16 cores, load average about 2-3). It does not establish timings on other hosts.
**Legibility target:** a reviewer, and a reader of the performance row.

p4, two runs each:

| Script | Run 1 | Run 2 |
|---|---|---|
| HEAD | 8583 ms | 8020 ms |
| cca66dc2 | 10541 ms | 9617 ms |

That is a saving of about 1.6-2.0 s. p3: cca66dc2's script took the clone from `count: 0` to `count: 87` / `size: 616` loose objects. HEAD's left `count: 0` / `size: 0` after two runs. Both printed identical output (`same-output`). Today the subject check comes first (`scripts/build-loop.sh:1657-1658`).

**Evidence:** `scripts/build-loop.sh:1655-1666`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p3.out`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p4.out`

---

## Claim 8: E5-E8 Fixed (header store writes, default-merge qualifier, bootstrap SINCE, `-` caveat, SUBJ=- first, re-hash wording)

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:44-47`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each fix being present in the text or code. Their accuracy is Claims 10, 17, 21, 24 and 30.
**Legibility target:** a reviewer deciding whether E5-E8 can close.

Each fix is in place:
- **Store writes:** `(merge-tree, which writes` / `the merged objects as --check's does)` (`scripts/build-loop.sh:151-152`).
- **Default-merge qualifier:** `(no -s or -X, no merge.*` / `config, no merge attribute)` (`:153-154`).
- **`-` caveat:** `("-" when` / `empty, so "-" may also be the text "-")` (`:148-149`).
- **SUBJ=- first:** `CLASS=other; SUBJ=-` (`:1651`).
- **Bootstrap SINCE:** in the plan note and row 726.

**Evidence:** `scripts/build-loop.sh:148-154`, `scripts/build-loop.sh:1651`, `docs/working/plan-build-loop-handoff.md:325`, `docs/reviews/override-log.md:726`

---

## Claim 9: Row 718 "land and log_class both call gate_msg; the reader compares the commit's message byte for byte with gate_msg's output"

**Location:** `docs/reviews/override-log.md:718`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two call sites and the byte comparison. It does not establish that gate_msg's output matches what land wrote before this branch (the format string is unchanged from the removed printf).
**Legibility target:** U4's author and the reviewer closing row 662.

land calls `gate_msg "${VERDICT[branch]}" "$what" "${VERDICT[stem]}" "${2-}" > "$GATE_TMP/msg"` (`scripts/build-loop.sh:1461`). The reader calls `gate_msg "$b" "$x" "$p" "$q" > "$GATE_TMP/want" && cmp -s "$GATE_TMP/want" "$GATE_TMP/m" && CLASS=gate` (`:1664`). `"${2-}"` is empty for self-merge because the merge mode sets `AUTH=self-merge; [[ -z "$APPROVED" ]] || AUTH=approved` and calls `land "$AUTH" "$APPROVED"` (`:1738`, `:1746`).

Test 1 classifies a real `--merge` as `gate` (pass). p1/P1 classifies an approved-merge message with `Build-loop-approved: Q-012` as `gate` (exit 0).

**Evidence:** `scripts/build-loop.sh:1368-1377`, `scripts/build-loop.sh:1461`, `scripts/build-loop.sh:1664`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`

---

## Claim 10: Row 719, the chore hand-off (no-ff; fast-forward lands as other; default merge; merge-tree's tree; subject; record mode 100644; "Branch: B" line; several Branch: lines, any counts)

**Location:** `docs/reviews/override-log.md:719`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reader's acceptance conditions as listed. It does not establish that "no merge.* config" is the complete list of caller settings that can make `git merge`'s tree differ from merge-tree's; that list was not exhausted, and p11 found diff.renames=false did not change a 2.39 merge. "Unfenced line near the top" is an instruction to U4: the reader accepts the line anywhere, unfenced or not.
**Legibility target:** U4's author implementing land of the chore branch.

The subject regex is `^Merge\ branch\ \'(chore/dev-cycle-[0123456789]{4}-[0123456789]{2}-[0123456789]{2}(-[0123456789]{4})?)\'($|\ into\ |:)` (`scripts/build-loop.sh:1664`). The record test is `[[ "$p" =~ ^docs/working/cycles/cycle-[^/]+\.md$ && "$meta" =~ ^:[01234567]{6}\ 100644\ ...\ [AM]$ ]]`, then an awk exact match of `"Branch: $b"` after dropping a CR (`:1669-1672`). A fast-forward leaves single-parent record commits on main, which fail the `${#ps[@]} -eq 1` answers rule's path test (`:1677`).

p1/P4 results:
- Two `--no-ff` merges with CRLF records and an " into main" subject read `chore`.
- A record at mode 100755 read `other`.

**Evidence:** `scripts/build-loop.sh:1664-1673`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`

---

## Claim 11: Row 720 "a multi-line answer, a note under the answer, or the user's archive move reads as other"

**Location:** `docs/reviews/override-log.md:720`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the awk's rejection of a non-blank, non-answer, non-header line, which each case adds. It does not establish what questions.sh archive writes beyond the entry's `### Q-` heading line.
**Legibility target:** U4's author handling other lines.

Any changed line that is not blank, an answer label or a `**Needs:**` line falls to `bad = 1` (`scripts/build-loop.sh:1629`). A note line or a continuation line is such a line. An archive move removes and adds `### Q-NNN · ...` heading lines, which are such lines as well.

**Evidence:** `scripts/build-loop.sh:1621-1631`

---

## Claim 12: Row 721 "--main-log reads history commits without store_check (only main's own commit and tree are re-hashed, by state_start)"

**Location:** `docs/reviews/override-log.md:721`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers --main-log's only store_check call. It does not establish anything about a forged history commit (stated as residual).
**Legibility target:** a security reviewer.

state_start runs `store_check --main "$MAIN_SHA"` (`scripts/build-loop.sh:1224`). main_log and log_class make no store_check call; they read through `gate_git` only (`:1649-1700`).

**Evidence:** `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1649-1700`

---

## Claim 13: Row 722 "A chore merge's other paths are not read"

**Location:** `docs/reviews/override-log.md:722`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the chore loop skipping non-record paths. It does not establish how much a clean_merge check limits a slip (a slip committed on the chore branch merges cleanly).
**Legibility target:** a security reviewer and U3c's author.

The loop `continue`s on any path that is not a record: `[[ "$p" =~ ^docs/working/cycles/cycle-[^/]+\.md$ && ... ]] || continue` (`scripts/build-loop.sh:1670`).

**Evidence:** `scripts/build-loop.sh:1668-1673`

---

## Claim 14: Row 723 "--main-log runs with the caller's git -c pairs unchecked (only --state reads them)"

**Location:** `docs/reviews/override-log.md:723`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mode test around caller_gate. It does not establish harden's handling of the pairs.
**Legibility target:** a security reviewer.

The only call is `if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` (`scripts/build-loop.sh:631`).

**Evidence:** `scripts/build-loop.sh:629-632`

---

## Claim 15: Row 724 "Each fails closed today (the chore loop skips an unparsed record: no record, other)"

**Location:** `docs/reviews/override-log.md:724`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers log_class's two readers. It does not establish check_line's reader (not in this diff).
**Legibility target:** U3c's author.

The chore loop sets `CLASS=chore` only on a matched record (`scripts/build-loop.sh:1672`). Otherwise the class stays `CLASS=other` (`:1651`). The answers loop does `|| return 0` on any record it does not match, then `[[ "$x" -gt 0 && "$(tr -cd '\000' < "$GATE_TMP/d" | wc -c)" -eq $((2 * x)) ]] || return 0` (`:1677-1682`).

**Evidence:** `scripts/build-loop.sh:1651`, `scripts/build-loop.sh:1667-1682`

---

## Claim 16: Row 725 "The cycle-record name is cycle-*.md here but cycle-YYYY-MM-DD.md in the lib's writable and dev-cycle.sh"

**Location:** `docs/reviews/override-log.md:725`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three patterns. It does not establish other readers of cycle records.
**Legibility target:** U4's author.

The patterns are:
- the lib's writable: `^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$` (`scripts/lib/dev-cycle-read.sh:245`);
- dev-cycle.sh: `cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`scripts/dev-cycle.sh:217`);
- here: `cycle-[^/]+\.md$` (`scripts/build-loop.sh:1670`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:245`, `scripts/dev-cycle.sh:217`, `scripts/build-loop.sh:1670`

---

## Claim 17a: Row 726 "Every commit on this repo's main today reads other (hand merges, checkpoint commits)"

**Location:** `docs/reviews/override-log.md:726`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a run over the whole first-parent history of /workspace main at 34cf382f. It does not establish later history.
**Legibility target:** U4's author sizing the attention cost.

p3: of 1,118 commits after the root, 1,117 read `other` and one reads `answers dfe4c0df... docs(questions): answer Q-093 [1] and Q-094 [1]`. The repo's only chore-shaped merge, `cac2ba0c Merge branch 'chore/dev-cycle-2026-10-02': first dev cycle`, reads other. The conclusion holds (human landings read other and stop dispatch), but "every" should read "all but one".

**Evidence:** `docs/reviews/override-log.md:726`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p3.out`

---

## Claim 17b: Row 726 "per-commit cost ~6-9 ms, ~7-10 s for a SINCE at this repo's root (1,119 commits, 422 merges); --state and --main-log each re-hash main's tree", and the bootstrap via "main MAIN -"

**Location:** `docs/reviews/override-log.md:726`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this machine's timing at HEAD and the counts. It does not establish other hosts.
**Legibility target:** U4's author.

p4 at HEAD: 8583 ms and 8020 ms for 1,118 commits after the root, against a 359-452 ms baseline at SINCE = MAIN, which comes to about 7 ms per commit. `git rev-list --first-parent --count main` gives 1119 and `--merges --count` gives 422. Both modes run `state_start` (`scripts/build-loop.sh:1711`, `:1715`). The bootstrap's refusal format is Claim 4 (P7b).

**Evidence:** `scripts/build-loop.sh:1709-1717`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p4.out`

---

## Claim 18: Row 727 "The answers class counts any added answer label in any entry, from anyone ... loops are told never to write the questions files"

**Location:** `docs/reviews/override-log.md:727`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the label match ignoring entry identity, and the prompt line. It does not establish that loops obey the prompt.
**Legibility target:** a security reviewer and U4's digest author.

The answer test is `if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) { if (s == "+") n++; next }` (`scripts/build-loop.sh:1627`), which ties a label to no entry. p1/P5 shows `- Q-9: 2` and `**answered (2026):** 1` both counting (`answers` lines), with no entry Q-9 in the file. The loop prompt carries `Never write the questions files, the roadmap, docs/dev-cycle.md or any other bri...` (the diff context at `scripts/build-loop.sh:1599`).

**Evidence:** `scripts/build-loop.sh:1627`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`

---

## Claim 19a: Row 728 "clean_merge's merge-tree writes merged objects into the real store (a hand-resolved or conflicting merge adds unreachable ones once ... idempotent after), and a constructed merge with thousands of modified renames costs ~5 s per run ... the rename case fails closed past git's limit"

**Location:** `docs/reviews/override-log.md:728`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the write path, idempotence (cca66dc2 run twice: 87 then 87), and the rename cost on this machine with one construction (renamed-and-modified files with new basenames). It does not establish other constructions, or the exact limit value git applies.
**Legibility target:** a performance reviewer.

clean_merge runs `gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}"` in the gate repository, whose `GIT_OBJECT_DIRECTORY` is the real store (`scripts/build-loop.sh:1646`, `:937`).

p9/p9b, with HEAD's script:

| Renames | Cost | Outcome |
|---|---|---|
| 3,000 | merge-tree 1333 ms; the run +1.2 s over baseline | gate |
| 6,900 | merge-tree 5854 ms; the run 6035 ms against a 427 ms baseline | gate |
| 8,000 | merge-tree rc 1 (conflicts) | other, so it fails closed |

**Evidence:** `scripts/build-loop.sh:1641-1648`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p9.out`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p9b.out`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p3.out`

---

## Claim 19b: Row 728 "87 objects, 616 KiB over this repo's history"

**Location:** `docs/reviews/override-log.md:728`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a full-history run on a fresh clone of /workspace main at 34cf382f, with HEAD's and cca66dc2's scripts. It does not establish future history: a gate- or chore-subject merge that does not merge cleanly would add objects.
**Legibility target:** a performance reviewer, and whoever acts on the revisit trigger.

This is text, not behaviour. The figure is the pre-E4 code's: cca66dc2's script took the clone from `count: 0` to `count: 87` / `size: 616`. HEAD's script, which the same commit 4afdd68b introduced alongside this row, leaves `count: 0` / `size: 0` after two runs. Since E4, merge-tree runs only after a gate or chore subject matches (`scripts/build-loop.sh:1657-1658`, `:1665-1666`). This repo's only such merge (cac2ba0c) is clean, so its tree already exists. 4afdd68b's own message says the same: "saving ~1.5 s and every store write on this repo's history". The precise version is: at HEAD, 0 objects over this repo's history; 87 objects / 616 KiB was the pre-E4 cost.

**Evidence:** `docs/reviews/override-log.md:728`, `scripts/build-loop.sh:1655-1666`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p3.out`

---

## Claim 20: Plan U3b2 "As built" note (gated after state_start; reads in the gate repository; SINCE full id, short is usage; output and refusal format; exit 2; clean-merge rule after the subject; bootstrap; gate, chore and answers rules; anything unread is other)

**Location:** `docs/working/plan-build-loop-handoff.md:325`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause against the code and probes P1-P8 and the suite. It does not establish U4's side of the hand-off.
**Legibility target:** U4's author.

The paths are all in the code:
- **Gating:** `GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1` (`scripts/build-loop.sh:629`), then `state_start` / `main_log "${ARGS[0]}" || exit 2` (`:1715-1716`).
- **Reads in the gate repository:** every read in main_log and log_class goes through `gate_git` (`:1649-1700`).
- **Usage:** `[[ $# -eq 2 && "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage` (`:453`).

Executed:
- uppercase → usage, exit 1 (P7);
- 64-hex in a sha1 repo → `main MAIN -` and a refusal, exit 2 (P7b);
- SINCE == MAIN → `main MAIN 0`, exit 0 (P8);
- the suite passes (2/2).

**Evidence:** `docs/working/plan-build-loop-handoff.md:325`, `scripts/build-loop.sh:451-453`, `scripts/build-loop.sh:1649-1717`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`

---

## Claim 21: Header "after --state's gate but its caller check. SINCE: a full 40- or 64-hex id of a commit on the default branch's first-parent history"

**Location:** `scripts/build-loop.sh:138-142`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the startup order. It does not establish what the caller check would add.
**Legibility target:** U4's author.

`if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` / `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`scripts/build-loop.sh:631-632`). The main-log case is `state_start` (`:1715`), so the check is gated and runs no caller_gate.

**Evidence:** `scripts/build-loop.sh:629-639`, `scripts/build-loop.sh:1714-1717`

---

## Claim 22: Header output "main MAIN N ... N: the first-parent commits after SINCE up to MAIN, one line each after this, oldest first ("-" before a refusal)"

**Location:** `scripts/build-loop.sh:143-147`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_log's listing and order. It does not establish a SINCE that equals a non-first-parent commit (which refuses: P7b, test 2).
**Legibility target:** U4's parser author.

The newer commits are cut with `LC_ALL=C awk -v s="$1" '$0 == s { f = 1; exit } { print } END { exit !f }'`, the count is printed by `echo "main $MAIN_SHA $(wc -l < "$GATE_TMP/after")"`, and the loop reads `done < <(tac "$GATE_TMP/after")` (`scripts/build-loop.sh:1696-1701`). Test 1 expects `main $T 5` followed by the oldest-first lines (pass).

**Evidence:** `scripts/build-loop.sh:1690-1703`, `test/scripts/build-loop-orchestrator.bats:331-336`

---

## Claim 23: Header "A two-parent commit is gate or chore only when its tree is the clean merge of its parents (merge-tree ...), as --merge and a git merge with git's defaults write it ...; an amended or hand-resolved merge is other"

**Location:** `scripts/build-loop.sh:149-155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --merge, `git merge --no-ff` with defaults, an amended merge, a `--no-commit` merge with an extra file, and a slip on the merged branch. It does not establish completeness of the "git's defaults" qualifier list against every caller setting.
**Legibility target:** U4's author landing the chore branch.

The check is `[[ "$t" == "$(LC_ALL=C awk '/^tree / { print $2; exit }' "$GATE_TMP/c")" ]]` (`scripts/build-loop.sh:1647`).

Executed:
- --merge → gate (test 1); `git merge --no-ff` → chore (P4, test 1);
- `--amend` adding a file → `other 63728eee...` (P2);
- `--no-commit` plus an extra file → `other 7d099caf...` (p10);
- slip on the branch → other (test 2).

**Evidence:** `scripts/build-loop.sh:1644-1648`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p10.out`

---

## Claim 24: Header "gate: two parents and the message --merge writes, byte for byte"

**Location:** `scripts/build-loop.sh:155-156`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers self-merge and approved forms, an extra line, a missing approved trailer, and one parent. It does not establish messages whose fifth line or later differs (cmp catches these: whole file compared).
**Legibility target:** U4's author.

`cmp -s "$GATE_TMP/want" "$GATE_TMP/m"` compares against the whole message, which is everything after the header's blank line: `perl -0777 -ne 's/\A.*?\n\n//s and print'` (`scripts/build-loop.sh:1655`, `:1664`). P1: the approved form reads gate. Test 2: `$M$'\nmore'`, the approved form without its trailer, and the single-parent form all read other (pass).

**Evidence:** `scripts/build-loop.sh:1652-1664`, `test/scripts/build-loop-orchestrator.bats:344-357`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`

---

## Claim 25: Header chore rule (subject then the end, " into " or ":"; B pattern; record docs/working/cycles/cycle-*.md, mode 100644, added or changed; "Branch: B" anywhere, a trailing CR dropped)

**Location:** `scripts/build-loop.sh:156-163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed element. It does not establish records in a subdirectory of cycles/ (rejected by `[^/]+`, consistent with the header's glob).
**Legibility target:** U4's author.

The regexes are quoted in Claim 10. P4: CRLF records with `Merge branch '...' into main` read chore; the 100755 record reads other. Test 2: a record that names another branch, the branch `chore/dev-cycle-x`, and an amended chore merge all read other (pass).

**Evidence:** `scripts/build-loop.sh:1664-1673`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`

---

## Claim 26: Header answers rule (one parent; only the two questions files; mode 100644 both sides; blank, answer or header lines; header Status-only, matched in order per hunk; at least one added answer; any entry's)

**Location:** `scripts/build-loop.sh:163-172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule over the probed shapes. It does not establish a header line whose Status field has no value after `**Status:**` (compared literally, so it reads other).
**Legibility target:** U4's author and a security reviewer.

The raw check is `^:100644\ 100644\ ...\ M$` plus the two paths (`scripts/build-loop.sh:1677`). needs() sets aside a field starting `**Status:** ` after leading blanks (`:1614-1616`), and flush() compares the removed and added lists in order (`:1618`).

P5 results:

| Commit | Change | Read |
|---|---|---|
| ans1 | flip plus an added `**answered (...)` | answers |
| ans2 | a Status field with leading blanks plus `- Q-9:` | answers |
| ans3 | Status field removed from the header | other |
| ans4 | mode change to 100755 | other |

**Evidence:** `scripts/build-loop.sh:1612-1631`, `scripts/build-loop.sh:1674-1684`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`

---

## Claim 27: Header "Any other commit, or one whose message, parents or changes cannot be read, is other"

**Location:** `scripts/build-loop.sh:172-174`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers every gate_git read guarded by `|| return 0` with CLASS preset to other, and the pipeline under pipefail. It does not establish a failure inside the `mapfile -t ps < <(awk ...)` process substitution, whose status is unchecked. That awk reads a file cat-file has just written, and a short parent list falls to the default other.
**Legibility target:** a reviewer of fail-closed behaviour.

The class defaults to `CLASS=other; SUBJ=-`, and each read is followed by `|| return 0`: `gate_git cat-file commit "$c" > "$GATE_TMP/c" || return 0`, the perl message extraction, both `diff-tree` calls (`scripts/build-loop.sh:1651-1683`). gate_git returns 3 when git wrote to stderr (`:942-947`).

**Evidence:** `scripts/build-loop.sh:942-947`, `scripts/build-loop.sh:1649-1686`

---

## Claim 28: Header "The class is read from the commit's own text (and commits before MAIN, and objects not in MAIN's tree, are not re-hashed)"

**Location:** `scripts/build-loop.sh:174-176`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers --main-log's store_check scope. It does not establish what a forger could do (F19 residual).
**Legibility target:** a security reviewer.

The only re-hash is `store_check --main "$MAIN_SHA"`, which covers MAIN's commit, root tree and every tree and blob below it (`scripts/build-loop.sh:1224`; store_check's comment at `:952-956`).

**Evidence:** `scripts/build-loop.sh:948-1000`, `scripts/build-loop.sh:1220-1226`

---

## Claim 29: Header "or "main MAIN -" and refuse main-log: WHY, when SINCE (a full id; a short one is a usage error, exit 1) is not on that history ... or it cannot be listed"

**Location:** `scripts/build-loop.sh:177-180`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the not-on-history refusal and usage. It does not establish the "cannot be listed" path, which was not executed; the code is `|| { echo "main $MAIN_SHA -"; echo "refuse main-log: the default branch's first-parent history could not be listed"; return 1; }` at `:1693-1694`.
**Legibility target:** U4's parser author.

P7b and test 2 (`ml "$X" 2 "main $T -` / `refuse main-log: $X is not on ...`) both pass. A 12-hex id gives exit 1 with stderr `--main-log takes one full 40- or 64-hex commit id` (test 2, pass).

**Evidence:** `scripts/build-loop.sh:1690-1698`, `test/scripts/build-loop-orchestrator.bats:371-373`

---

## Claim 30: Header "Writes nothing but --check's and --main-log's merge objects (merge-tree writes the merged trees and blobs into the object store) ... and its own temporary directory, removed at exit"

**Location:** `scripts/build-loop.sh:410-416`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers --main-log's writes: its GATE_TMP files and merge-tree's objects. It does not establish mtime freshening of existing objects, which git does on a re-write and is not a new object.
**Legibility target:** an operator.

main_log and log_class write only `$GATE_TMP/{fp,after,c,m,want,d,p}` and the gate repository under GATE_TMP (`scripts/build-loop.sh:1649-1700`). That directory comes from `GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT` (`:1222`).

**Evidence:** `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1649-1700`

---

## Claim 31: Exit section "for --main-log no other line ... 2 ... --main-log's other or refuse line ... 1 ... a failed mktemp (--state, --main-log, ...; no line printed)"

**Location:** `scripts/build-loop.sh:419-428`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exits 0, 1 and 2 for --main-log. It does not establish exits from state_gate or default_gate refusals, which were not executed here.
**Legibility target:** U4's author.

Executed:
- P8 exits 0 with no other line; P2 and P3 exit 2 on other; P7b exits 2 on a refusal.
- P6 (`TMPDIR=/nonexistent/x`) exits 1, with only mktemp's own stderr and no stdout line.

**Evidence:** `scripts/build-loop.sh:1222`, `scripts/build-loop.sh:1714-1717`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`

---

## Claim 32: gate_msg comment "log_class parses the fields back out by the same shape (subject, line 3, line 4) and compares bytes, so a change here must change its parser too; gate merges already on main keep the old shape and would read as other"

**Location:** `scripts/build-loop.sh:1368-1373`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parser's indices and the byte compare. It does not establish anything about a future format.
**Legibility target:** whoever next edits gate_msg.

The parser reads `${m[2]-}` as `Build-loop-gate: (.+)` and `${m[3]-}` as `Build-loop-approved: (Q-[0123456789]+)` (`scripts/build-loop.sh:1659-1662`), then compares with `cmp -s` (`:1664`).

**Evidence:** `scripts/build-loop.sh:1368-1377`, `scripts/build-loop.sh:1655-1664`

---

## Claim 33: ANSWERS_AWK comment (rule summary; "a Status flip or a deleted answer alone adds none"; any added label counts; labels are --check-answer's, lib points back)

**Location:** `scripts/build-loop.sh:1602-1610`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the awk against the comment and the back-pointer's existence. It does not establish label parity beyond shape: the lib matches only the entry's own `id ":"`, while this matches any `Q-` and digits, as the comment states ("any entry").
**Legibility target:** whoever next edits the answer labels.

See Claims 3, 18 and 26. The lib's pointer reads `# build-loop.sh's ANSWERS_AWK (--main-log's answers class) copies these labels` (`scripts/lib/dev-cycle-read.sh:2019`).

**Evidence:** `scripts/build-loop.sh:1602-1631`, `scripts/lib/dev-cycle-read.sh:2019-2020`

---

## Claim 34: log_class comment "C, its changes and the record it adds are read in the gate repository ...; any failed read makes C other. ... Checked after the subject, so other merges cost no merge-tree run"

**Location:** `scripts/build-loop.sh:1632-1640`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers gate_git use and the order. Failed reads are covered with Claim 27's residue.
**Legibility target:** a performance reviewer.

P3: a hand-resolved merge with a non-gate subject left loose objects at 25 before and 25 after. The full-history run at HEAD wrote 0 objects, against 87 for cca66dc2 (Claim 7).

**Evidence:** `scripts/build-loop.sh:1649-1686`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p3.out`

---

## Claim 35: clean_merge comment "merge-tree writes the merged trees and blobs into the object store, as --check's does (only a conflicting or hand-resolved merge adds new ones)"

**Location:** `scripts/build-loop.sh:1641-1643`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers merges built by git (amend after a merge, `--no-commit` plus a file), both of which added no objects. It does not establish a merge built by commit-tree over an arbitrary tree, which is outside "hand-resolved" as worded and would add the clean tree.
**Legibility target:** a performance reviewer.

The probes found no new objects in either git-built case. P2 (amended gate merge): 14 before, 14 after, and 14 after a second run. p10 (`--no-commit` plus a slip file): 13 before, 13 after. Both read other. git's ort writes the clean result tree during `git merge`, so it already exists.

**Evidence:** `scripts/build-loop.sh:1641-1648`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p1.out`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p10.out`

---

## Claim 36: "# pipefail: a failed read is no record."

**Location:** `scripts/build-loop.sh:1671`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pipeline's status under `set -o pipefail`. It does not establish awk's own failure modes.
**Legibility target:** a reviewer of fail-closed behaviour.

The script sets `set -euo pipefail` (`scripts/build-loop.sh:431`). The pipeline `gate_git cat-file blob "${BASH_REMATCH[1]}" | LC_ALL=C awk ... && { CLASS=chore; return 0; }` (`:1672`) therefore fails when gate_git fails, even if awk found the line. awk reads to EOF, so no SIGPIPE arises.

**Evidence:** `scripts/build-loop.sh:431`, `scripts/build-loop.sh:1672`

---

## Claim 37: "# Every record read whole, as check_line reads its diff."

**Location:** `scripts/build-loop.sh:1681`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the NUL count against the record count. It does not establish check_line's own reader.
**Legibility target:** a reviewer.

`[[ "$x" -gt 0 && "$(tr -cd '\000' < "$GATE_TMP/d" | wc -c)" -eq $((2 * x)) ]] || return 0` (`scripts/build-loop.sh:1682`). A trailing unterminated field adds a NUL-less tail, so the count no longer matches and C reads other.

**Evidence:** `scripts/build-loop.sh:1676-1682`

---

## Claim 38: main_log comment "Returns 1 when SINCE is refused or any commit is other" and "Main's commit first, even before a refusal"

**Location:** `scripts/build-loop.sh:1688-1692`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both returns. It does not establish the list-failure path at runtime.
**Legibility target:** U4's author.

The function ends with `[[ "$CLASS" != other ]] || o=1` and `return "$o"` (`scripts/build-loop.sh:1701-1703`). Both refusals echo `main $MAIN_SHA -` first (`:1694`, `:1697`). P7b confirms it.

**Evidence:** `scripts/build-loop.sh:1690-1703`

---

## Claim 39: Lib back-pointer "build-loop.sh's ANSWERS_AWK (--main-log's answers class) copies these labels and the header line's Status field: change both together"

**Location:** `scripts/lib/dev-cycle-read.sh:2019-2020`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the label shapes (`- ` prefix, `Q-` and digits and `:`, `**answer(:|ed| \()` any case) and the Status field read. It does not establish identity: the lib binds Q-NNN to the entry, ANSWERS_AWK does not.
**Legibility target:** whoever next edits ANSWER_AWK.

The lib's tests are `if (index(line, id ":") == 1)` and `if (low !~ /^\*\*answer(:|ed| \()/) next` after `sub(/^- /, "", line)`, plus `if (substr(f, 1, 12) == "**Status:** ")` (`scripts/lib/dev-cycle-read.sh:2050-2058`). ANSWERS_AWK matches the same shapes (`scripts/build-loop.sh:1615`, `:1626-1627`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2043-2058`, `scripts/build-loop.sh:1612-1631`

---

## Claim 40: Commit 1d829fee message "answers (only answer and Status lines in the questions files) or other; exit 2 on any other ... Gated; reads run in the gate repository"

**Location:** `git show 1d829fee` (message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers 1d829fee's ANSWERS_AWK. It does not judge later commits.
**Legibility target:** a history reader.

At 1d829fee the awk also accepted blank lines, `if (l ~ /^[ \t]*$/) next` (`git show 1d829fee:scripts/build-loop.sh` line 1607). It counted any non-blank changed line in `n++` (line 1608), so a Status flip alone passed; D2 later found and fixed this. The precise version is "only blank, answer and header-Status lines". The rest holds.

**Evidence:** `git show 1d829fee:scripts/build-loop.sh` lines 1594-1613

---

## Claim 41: Commit cca66dc2 message (D1 clean merge, D2 added answer, D4, D9, text fixes)

**Location:** `git show cca66dc2` (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change, as Claims 2-4. It does not re-judge the rubric rows.
**Legibility target:** a history reader.

See Claims 2, 3 and 4. "a hand-resolved chore merge now reads as other (fail closed)" follows from clean_merge (`scripts/build-loop.sh:1666`) and from P3's analogue.

**Evidence:** `scripts/build-loop.sh:1644-1666`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p2.out`

---

## Claim 42: Commit 4afdd68b message "E1 ... every near-miss commit is asserted non-empty. E4: merge-tree runs only once a gate or chore subject matches (clean_merge), saving ~1.5 s and every store write on this repo's history ... SUBJ starts as "-" so a failed read prints it too"

**Location:** `git show 4afdd68b` (message)
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers E1, E4 and SUBJ on this machine and repository. It does not establish timing elsewhere.
**Legibility target:** a history reader.

Measured saving: about 1.6-2.0 s. Objects: 87 to 0 (Claim 7). The initialisation is `CLASS=other; SUBJ=-` (`scripts/build-loop.sh:1651`). E1 is Claim 6.

**Evidence:** `scripts/build-loop.sh:1651`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p3.out`, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-fcf-r1/p4.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19b** (`docs/reviews/override-log.md:728`): text, not behaviour. "87 objects, 616 KiB over this repo's history" is cca66dc2's cost. At HEAD (E4, same commit) a full-history run writes 0 objects. Restate it as the pre-E4 figure, or as 0 at HEAD.

### Stale
None.

### Mostly Accurate
- **Claim 17a** (`docs/reviews/override-log.md:726`): "Every commit on this repo's main today reads other". One of 1,118 (dfe4c0df, an answer commit) reads answers.
- **Claim 40** (1d829fee message): "only answer and Status lines" omits blank lines, which that code also accepted.

### Unverifiable
None.

---

## Goal-Alignment Note

Success criterion: "A code-fact-check replicate report saved at the given path in the worktree, per the code-fact-check skill." It is met. This report is at `docs/reviews/code-fact-check-report-2026-10-12-u3b2-final-r1.md` with first line `Commit: 4afdd68b`. It follows the skill's schema, and every claim carries the seven mandatory fields and a legibility target.

The brief named six claim groups, and all six were checked:
- the --main-log header rules;
- the Writes, Exit and mktemp text;
- the comments;
- the plan note and rows 718-728;
- the rubric's Fixed claims, with mutants for D1 and D2 and a pre-fix run for E4;
- the three commit messages.

No behavioural Incorrect was found. Nothing in the worktree was written but this file, and every probe ran in its own `/tmp/u3b2rv-fcf-` directory, which was removed. Residues worth a reader's attention:
- The "route change" near miss in test 2 does not isolate the header-matching rule, because `n > 0` alone rejects it (Claim 3 scope).
- The "git's defaults" qualifier list was not proven complete (Claim 10 scope).
