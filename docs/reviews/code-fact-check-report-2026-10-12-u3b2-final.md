# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u3b2 (branch `feat/build-loop-u3b2`, HEAD 4afdd68b)
**Scope:** full branch diff `main...4afdd68b` (main b5f21758): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-orchestrator.bats`, `docs/working/plan-build-loop-handoff.md` (U3b2 "As built" note), `docs/reviews/override-log.md` rows 718-728, the rubric's Fixed claims, and commit messages 1d829fee, cca66dc2, 4afdd68b. Final confirming pass, merged from replicates r1, r2 and r3 (most-severe-wins).
**Checked:** 2026-10-12
**Commit:** 4afdd68b
**Replication:** k=3
**Total claims checked:** 52
**Summary:** 43 verified, 7 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Merged mechanically from `code-fact-check-report-2026-10-12-u3b2-final-r1.md` (44 claims), `-r2.md` (32 claims) and `-r3.md` (42 claims), all at `Commit: 4afdd68b`, per code-review's "Merging replicate verdicts (most-severe-wins)". No claim or evidence below is new; every verdict, quote and measurement comes from a replicate. Claims are emitted at the finest granularity any replicate used; a replicate that verdicted only a compound carries its verdict on each sub-claim row marked `(compound)`. `rN Cx` names the replicate's own claim number.

Probe outputs cited below live under the session scratchpad `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/` (written `<scratch>`): r1 in `<scratch>/u3b2-fcf-r1/` (`pN.out`, `bats.txt`), r2 as `<scratch>/fcf-r2-*.log` (X1-X7), r3 in `<scratch>/u3b2-fcf-r3/` (`pN.log`). Each replicate's report carries the full command, cwd, exit and timestamp provenance for its probes.

Hallucination-pattern log: r1 and r2 found no exact match; r3 places the row-728 object count (Claim 21b) in the logged family "a count or measured number quoted in prose that the artifact no longer bears out", and r2 notes Claim 19a resembles that family as a generalisation.

---

## Claim 1: Rubric status (iteration 1): "no 🔴 · 🟡 3 · 🟢 10 ... D8 and D10-D13 carry override rows" and the i1 report "(31 claims: 24 Verified, 7 Mostly Accurate, 0 Incorrect)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:5-7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the iteration-1 tier counts against the rubric's own tables and the i1 report's header counts. It does not establish that the i1 report's verdicts themselves are right.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2: "does not re-judge / re-verdict the i1 report's claims" · r3: "does not establish that each finding was tiered correctly" · r3: the override rows exist (D8 `override-log.md:724`, D10 `:725` with hand-off `:719`, D11 `:722`, D12 `:723`, D13 `:726`)

The 🟡 table lists D1, D2 and D3; the 🟢 table lists D4 through D13. The i1 report reads `**Total claims checked:** 31` / `**Summary:** 24 verified, 7 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable`, and a grep of its `**Verdict:**` lines counts 24 Verified, 7 Mostly and 0 Incorrect (r1).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:5-30`, `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i1.md:4-10`

---

## Claim 2: D1 "Fixed (tree must equal merge-tree's clean merge of the parents; test; mutant killed)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:15` (r2, r3: `:17`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate and chore branches of log_class calling clean_merge, and a test that fails without it. It does not establish which of the near-miss rows in test 2 would kill the mutant alone, because the run stops at the first failing `ml`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: does not establish which test-2 assertion kills the chore-amend case alone (the gate-amend assertion fails first) · r2: "does not establish that merge-tree's tree equals every default `git merge` result under every caller configuration" · r2: deleting the gate call and the chore call separately each failed test 2; 1d829fee's script failed test 2 (also r3)

Both two-parent branches call `clean_merge || return 0` after the subject matches (`scripts/build-loop.sh:1657-1658`, `:1665-1666`; r2/r3 cite `:1659`, `:1667`). r1's p2 deleted both lines and test 2 failed: a merge built with `merge-tree main feat/x`'s tree over a slip read `gate 9828d9b5... Merge branch 'feat/x' (build-loop self-merge)` where the test wants `other`. On HEAD the test passes.

**Evidence:** `scripts/build-loop.sh:1644-1666`, `test/scripts/build-loop-orchestrator.bats:347-357`, `<scratch>/u3b2-fcf-r1/p2.out`, `<scratch>/fcf-r2-mut.log`, `<scratch>/u3b2-fcf-r3/p2.log`, `<scratch>/u3b2-fcf-r3/p3.log`

---

## Claim 3: D2 "Fixed (at least one added answer line; the deleted-answer test killed the mutant; the Status-flip test was empty until E1 ...)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:16` (r2, r3: `:18`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `n > 0` requirement, the mutant kill, and the claim that cca66dc2's Status-flip commit had nothing to flip. It does not establish that the "route change" near miss pins the header-matching rule: that commit adds no answer either, so `n > 0` alone already makes it other.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: the header-match rule is not pinned by a test (see Claim 43) · r3: "does not establish the revert clause beyond reading the code" · r3: mutant M3 (header line counts as answer) fails HEAD's test 2 but passes cca66dc2's, confirming the flip assertion pinned nothing before E1 · r2+r3: a mutant counting removed answers (`n++` on any sign) also fails test 2

The count is taken only on added lines, `if (s == "+") n++` (`scripts/build-loop.sh:1627`), and the pass condition is `END { flush(); exit !(n > 0 && !bad) }` (`:1631`). r1's mutant `exit !(!bad)` made test 2 fail. At cca66dc2 the test changed route and Status together first, then ran the flip sed when no OPEN was left, so the flip commit was empty (`git show cca66dc2:test/scripts/build-loop-orchestrator.bats` lines 215-216).

**Evidence:** `scripts/build-loop.sh:1612-1631`, `test/scripts/build-loop-orchestrator.bats:361-369`, `<scratch>/u3b2-fcf-r1/p2.out`, `<scratch>/fcf-r2-mut.log`, `<scratch>/u3b2-fcf-r3/p3.log`

---

## Claim 4: D3, D5, D6, D7 Fixed (hand-off text, re-hash wording, back-pointers, gate_msg parser note)

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:17-28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed fix being present by reading the text. It does not establish the deferred rows D8 and D10-D13.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: D5 rests on Claim 30, D6 on Claims 36 and 42, D7 on Claim 34

D3: the header carries the tail rule, `a subject "Merge branch 'B'" then the end, " into "` / `or ":" (any other text after the quote is other)` (`scripts/build-loop.sh:157-158`), the mode, `mode 100644` (`:161`), and the usage rule, `a short one is a usage error, exit 1` (`:178`) (r1).

**Evidence:** `scripts/build-loop.sh:138-180`

---

## Claim 5: D4 "Fixed (`main MAIN -` first)" and D9 "Empty subject printed as a trailing space ... Fixed (`-`)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:25`, `:30`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal's first line and the empty-subject rendering. It does not cover the rev-list-failure refusal, which was read but not executed.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the rev-list-failure path (`:1693-1694`) prints the same main line by code reading, not execution · r3: "does not establish what U4 does with either line" · r3: mutants M4 (main line removed) and M5 (`SUBJ=-` removed) both fail test 2

`{ echo "main $MAIN_SHA -"; echo "refuse main-log: $1 is not on ..."; return 1; }` (`scripts/build-loop.sh:1696-1697`). In r2's X2 a missing 40-hex SINCE printed `main 487a1d40... -` then the refuse line, exit 2; an empty-message commit printed `other 5ee39163... -`. r1's P7b printed `main 684cd163... -` then the refusal. `[[ -n "$SUBJ" ]] || SUBJ=-` (`:1656`).

**Evidence:** `scripts/build-loop.sh:1690-1703`, `scripts/build-loop.sh:1656`, `<scratch>/fcf-r2-probe.log`, `<scratch>/u3b2-fcf-r1/p1.out`, `<scratch>/u3b2-fcf-r3/p3.log`

---

## Claim 6: "36 claims, 29 Verified, 5 Mostly Accurate, 2 Incorrect (rubric text; a test fixture), none behavioural"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:36` (r2, r3: `:40`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts against the i2 report. It does not re-judge the i2 verdicts.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

The i2 report's header reads `**Total claims checked:** 36` / `**Summary:** 29 verified, 5 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable`, and its verdict lines count 29, 5 and 2.

**Evidence:** `docs/reviews/code-fact-check-report-2026-10-12-u3b2-i2.md:4-10`

---

## Claim 7: E1 "Fixed (flip before the route change; each near-miss commit asserted non-empty)"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:44` (r1: `:40`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reorder and the non-empty assertion over the four answers near-misses. It does not establish a non-empty assertion for the chore near-misses, and it notes that the empty-commit near-miss is empty on purpose.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r1+r2: does not establish that the route-change commit tests the header rule, i.e. that each near miss is other for the reason its comment names (see Claim 43) · r1: under mutant b the flip commit read `answers c40c298a... answer`, so it carries a diff only `n > 0` rejects

The reorder is real and now pins the flip: `q 's/\*\*Status:\*\* OPEN/**Status:** ANSWERED/'; q 's/you: judgment/agent/'; q '' ''; q '/^Q-001: \[1\]$/d'` (`test/scripts/build-loop-orchestrator.bats:216`), and mutant M3 is killed. The assertion is `for i in 4 3 2 1; do [ -n "$(git diff "main~$i" "main~$((i - 1))")" ] ...` (`:217`), which covers only the four answers commits. The near-miss `tip main ''; E=...` (`:214`) is an empty commit by design, so "each near-miss commit" is too broad; precise: "each answers near-miss commit" (r3).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:208-219`, `<scratch>/u3b2-fcf-r3/p3.log`, `<scratch>/u3b2-fcf-r1/p2.out`

---

## Claim 8: E4 "merge-tree ran on every merge before the subject could match (+1.5 s on this repo's history; all its store writes)" — Fixed

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:43` (r2, r3: `:47`)
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timing difference and the store writes, on a clone of /workspace main with SINCE at the root, on this machine (16 cores, load average about 2-3). It does not establish timings on other hosts.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** measured savings differ: r1 about 1.6-2.0 s, r2 about 1.6-1.7 s (Confidence Medium, shared host, load ~3), r3 1.8-2.6 s (see Claim 47) · r3: "does not establish the exact seconds saved"; output byte-identical to cca66dc2's on the clone

r1 p4, two runs each: HEAD 8583 / 8020 ms; cca66dc2 10541 / 9617 ms. p3: cca66dc2's script took the clone from `count: 0` to `count: 87` / `size: 616` loose objects; HEAD's left `count: 0` / `size: 0` after two runs. Both printed identical output. The subject check now comes first (`scripts/build-loop.sh:1657-1658`).

**Evidence:** `scripts/build-loop.sh:1655-1666`, `<scratch>/u3b2-fcf-r1/p3.out`, `<scratch>/u3b2-fcf-r1/p4.out`, `<scratch>/fcf-r2-real.log`, `<scratch>/u3b2-fcf-r3/p1.log`, `<scratch>/u3b2-fcf-r3/p5.log`

---

## Claim 9: E5-E8 Fixed (header store writes, default-merge qualifier, bootstrap SINCE, `-` caveat, re-hash wording)

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:44-47`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each fix being present in the text or code. Their accuracy is Claims 19, 24, 25 and 32.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Store writes: `(merge-tree, which writes` / `the merged objects as --check's does)` (`scripts/build-loop.sh:151-152`). Default-merge qualifier: `(no -s or -X, no merge.*` / `config, no merge attribute)` (`:153-154`). `-` caveat: `("-" when` / `empty, so "-" may also be the text "-")` (`:148-149`). Bootstrap SINCE: in the plan note and row 726 (r1).

**Evidence:** `scripts/build-loop.sh:148-154`, `docs/working/plan-build-loop-handoff.md:325`, `docs/reviews/override-log.md:726`

---

## Claim 10: E8 "SUBJ=- first"

**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:51` (r1: within `:44-47`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a failed `cat-file` read, which prints `-`. It does not cover a perl failure after SUBJ was set, which never sets SUBJ either.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** none

`CLASS=other; SUBJ=-` comes before `gate_git cat-file commit "$c" > "$GATE_TMP/c" || return 0` (`scripts/build-loop.sh:1651-1652`).

**Evidence:** `scripts/build-loop.sh:1649-1656`

---

## Claim 11: Row 718 "land and log_class both call gate_msg; the reader compares the commit's message byte for byte with gate_msg's output"

**Location:** `docs/reviews/override-log.md:718`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two call sites and the byte comparison. It does not establish that gate_msg's output matches what land wrote before this branch (the format string is unchanged from the removed printf).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: does not cover gate merges written by older code (r3: none exist on main) · r2: the same approved message with one extra trailing newline read other · r3: old-printf equivalence is Claim 35

land calls `gate_msg "${VERDICT[branch]}" "$what" "${VERDICT[stem]}" "${2-}" > "$GATE_TMP/msg"` (`scripts/build-loop.sh:1461`). The reader calls `gate_msg "$b" "$x" "$p" "$q" > "$GATE_TMP/want" && cmp -s "$GATE_TMP/want" "$GATE_TMP/m" && CLASS=gate` (`:1664`). Test 1 classifies a real `--merge` as `gate`; r1 P1, r2 X2 and r3 p4 each classify an approved-merge message as `gate`.

**Evidence:** `scripts/build-loop.sh:1368-1377`, `scripts/build-loop.sh:1461`, `scripts/build-loop.sh:1664`, `<scratch>/u3b2-fcf-r1/p1.out`, `<scratch>/fcf-r2-probe.log`, `<scratch>/u3b2-fcf-r3/p4.log`

---

## Claim 12: Row 719, the chore hand-off (no-ff; fast-forward lands as other; default merge; merge-tree's tree; subject; record mode 100644; "Branch: B" line; several Branch: lines, any counts)

**Location:** `docs/reviews/override-log.md:719`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reader's acceptance conditions as listed. It does not establish that "no merge.* config" is the complete list of caller settings that can make `git merge`'s tree differ from merge-tree's; that list was not exhausted, and p11 found diff.renames=false did not change a 2.39 merge.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "an unfenced line near the top" is a convention for U4's writer, not a reader rule; the reader accepts the line anywhere, fenced or not · r2: an `-s ours` chore merge read other (X7) · r3: a trailing blank, an indented line, and `: t` on a record whose line had a trailing blank each read other

The subject regex is `^Merge\ branch\ \'(chore/dev-cycle-[0123456789]{4}-[0123456789]{2}-[0123456789]{2}(-[0123456789]{4})?)\'($|\ into\ |:)` (`scripts/build-loop.sh:1664`). The record test is `[[ "$p" =~ ^docs/working/cycles/cycle-[^/]+\.md$ && "$meta" =~ ^:[01234567]{6}\ 100644\ ...\ [AM]$ ]]`, then an awk exact match of `"Branch: $b"` after dropping a CR (`:1669-1672`). A fast-forward leaves single-parent record commits that fail the answers rule's path test (`:1677`). r1 P4: two `--no-ff` merges with CRLF records and an " into main" subject read `chore`; a record at mode 100755 read `other`.

**Evidence:** `scripts/build-loop.sh:1664-1673`, `<scratch>/u3b2-fcf-r1/p1.out`, `<scratch>/fcf-r2-probe.log`, `<scratch>/fcf-r2-ours.log`, `<scratch>/u3b2-fcf-r3/p4.log`

---

## Claim 13: Row 720 "a multi-line answer, a note under the answer, or the user's archive move reads as other"

**Location:** `docs/reviews/override-log.md:720`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the awk's rejection of a non-blank, non-answer, non-header line, which each case adds. It does not establish what questions.sh archive writes beyond the entry's `### Q-` heading line.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: X2 a9 (`questions-archive.md` added) read other · r3: in p4 an indented answer and a line that gained a CR both read other

Any changed line that is not blank, an answer label or a `**Needs:**` line falls to `bad = 1` (`scripts/build-loop.sh:1629`). A note line, a continuation line, or a moved `### Q-NNN · ...` heading is such a line.

**Evidence:** `scripts/build-loop.sh:1621-1631`

---

## Claim 14: Row 721 "--main-log reads history commits without store_check (only main's own commit and tree are re-hashed, by state_start)"

**Location:** `docs/reviews/override-log.md:721`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers --main-log's only store_check call. It does not establish anything about a forged history commit (stated as residual).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: "tree" here means the whole tree below MAIN, which is what store_check walks

state_start runs `store_check --main "$MAIN_SHA"` (`scripts/build-loop.sh:1224`). main_log and log_class make no store_check call; they read through `gate_git` only (`:1649-1700`).

**Evidence:** `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1649-1700`

---

## Claim 15: Row 722 "A chore merge's other paths are not read"

**Location:** `docs/reviews/override-log.md:722`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the chore loop skipping non-record paths. It does not establish how much a clean_merge check limits a slip (a slip committed on the chore branch merges cleanly).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: does not establish whether U3c will add a path list

The loop `continue`s on any path that is not a record (`scripts/build-loop.sh:1670`).

**Evidence:** `scripts/build-loop.sh:1668-1673`

---

## Claim 16: Row 723 "--main-log runs with the caller's git -c pairs unchecked (only --state reads them)"

**Location:** `docs/reviews/override-log.md:723`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mode test around caller_gate. It does not establish harden's handling of the pairs.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: does not establish what a given pair changes in the reads

The only call is `if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` (`scripts/build-loop.sh:631`).

**Evidence:** `scripts/build-loop.sh:629-632`

---

## Claim 17: Row 724 "Three readers of `diff-tree --raw -z` ... Each fails closed today (the chore loop skips an unparsed record: no record, other)"

**Location:** `docs/reviews/override-log.md:724`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers log_class's two readers. It does not establish check_line's reader (not in this diff).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: the three call sites are `:1276` (check_line), `:1668` and `:1675`

The chore loop sets `CLASS=chore` only on a matched record (`scripts/build-loop.sh:1672`); otherwise the class stays `CLASS=other` (`:1651`). The answers loop does `|| return 0` on any unmatched record, then checks the NUL count (`:1677-1682`).

**Evidence:** `scripts/build-loop.sh:1651`, `scripts/build-loop.sh:1667-1682`

---

## Claim 18: Row 725 "The cycle-record name is cycle-*.md here but cycle-YYYY-MM-DD.md in the lib's writable and dev-cycle.sh"

**Location:** `docs/reviews/override-log.md:725`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three patterns. It does not establish other readers of cycle records.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: does not establish which pattern U4 will use

The lib's writable: `^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$` (`scripts/lib/dev-cycle-read.sh:245`); dev-cycle.sh: `cycle-[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md` (`scripts/dev-cycle.sh:217`); here: `cycle-[^/]+\.md$` (`scripts/build-loop.sh:1670`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:245`, `scripts/dev-cycle.sh:217`, `scripts/build-loop.sh:1670`

---

## Claim 19a: Row 726 "Every commit on this repo's main today reads other (hand merges, checkpoint commits)"

**Location:** `docs/reviews/override-log.md:726`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the class of every first-parent commit after the root on a clone at 34cf382f. dfe4c0df has been on main since 2026-09-28 (an ancestor of b5f21758), so the claim was also false when written. It does not change the row's conclusion: any other still stops dispatch.
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r1+r3: the conclusion holds (a human landing reads other and stops dispatch); precise wording "all but one" · r1: the repo's only chore-shaped merge, cac2ba0c, reads other · r3: dfe4c0df is an honest answers commit (two Status flips, two `**Answer (2026-09-28): [1].**` lines) which the rule accepts; does not establish commits landed after the clone

r2 X4: `--main-log ROOT` printed `1117 other` and `1 answers`: `answers dfe4c0df99c4fb27991355c6632f936a3d8fe1ee docs(questions): answer Q-093 [1] and Q-094 [1]`. `git merge-base --is-ancestor dfe4c0df b5f21758` succeeded. Text error, not behavioural. Precise version: "every commit but one on this repo's main reads other (dfe4c0df, a hand answer commit, reads answers)." r1 p3 and r3 p5 measured the same 1117/1.

**Evidence:** `docs/reviews/override-log.md:726`, `<scratch>/fcf-r2-real.log`, `<scratch>/u3b2-fcf-r1/p3.out`, `<scratch>/u3b2-fcf-r3/p5.log`

---

## Claim 19b: Row 726 "per-commit cost ~6-9 ms, ~7-10 s for a SINCE at this repo's root (1,119 commits, 422 merges); --state and --main-log each re-hash main's tree"; "it runs --state's gate but the caller check"

**Location:** `docs/reviews/override-log.md:726`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one machine (16 cores, load average about 2-2.8) and one clone. It does not establish timings under other loads.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: HEAD 8583 / 8020 ms against a 359-452 ms SINCE=MAIN baseline, about 7 ms per commit · r2: 7.17 s and 7.76 s, about 6.4-6.9 ms per commit; `GATED` set for main-log and `state_gate` runs while `caller_gate` runs only for `state` (`:629-632`)

`git rev-list --first-parent --count main` gives 1119 and `--first-parent --merges --count` gives 422. HEAD's root-SINCE runs took 7323, 7106, 6983, 7092, 7820, 8113 and 8056 ms over 1118 commits, about 6.2-7.3 ms per commit. Both modes call `state_start`, which runs `store_check --main` (`scripts/build-loop.sh:1224`, `:1711`, `:1715`) (r3).

**Evidence:** `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1710-1717`, `<scratch>/u3b2-fcf-r3/p5.log`, `<scratch>/u3b2-fcf-r1/p4.out`, `<scratch>/fcf-r2-real.log`

---

## Claim 19c: Row 726 "bootstrap by running --main-log with any full id off main's history, which prints "main MAIN -" before its refusal"

**Location:** `docs/reviews/override-log.md:726`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers any lowercase 40- or 64-hex string, which awk compares as text. It does not establish that such a string must name an object (it need not).
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** r1: the refusal format is confirmed by P7b

`LC_ALL=C awk -v s="$1" '$0 == s { f = 1; exit } ...' ... || { echo "main $MAIN_SHA -"; ...` (`scripts/build-loop.sh:1696-1697`). The test asserts `main $T -` and then the refusal (`test/scripts/build-loop-orchestrator.bats:221-222`; p2 HEAD ok 2) (r3).

**Evidence:** `scripts/build-loop.sh:1690-1703`, `<scratch>/u3b2-fcf-r3/p2.log`, `<scratch>/u3b2-fcf-r1/p1.out`

---

## Claim 20: Row 727 "The answers class counts any added answer label in any entry, from anyone ... loops are told never to write the questions files"

**Location:** `docs/reviews/override-log.md:727`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the label match ignoring entry identity, and the prompt line. It does not establish that loops obey the prompt.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: does not establish U4's digest · r2: `Q-002: [2]` and `Q-003: [1]` in the archive read answers

The answer test is `if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) { if (s == "+") n++; next }` (`scripts/build-loop.sh:1627`), tied to no entry. r1 P5 shows `- Q-9: 2` and `**answered (2026):** 1` both counting, with no entry Q-9 in the file. The loop prompt carries `Never write the questions files, the roadmap, ...` (`:1598-1599`).

**Evidence:** `scripts/build-loop.sh:1598-1599`, `scripts/build-loop.sh:1627`, `<scratch>/u3b2-fcf-r1/p1.out`, `<scratch>/fcf-r2-probe.log`

---

## Claim 21a: Row 728 "clean_merge's merge-tree writes merged objects into the real store (a hand-resolved or conflicting merge adds unreachable ones once ...; idempotent after)"

**Location:** `docs/reviews/override-log.md:728`
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the object-writing cases and one rename construction. It does not reproduce the source measurement's 100,001-file tree.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate (r2 C13b; r2 C13a=Verified on the write path and idempotence) · r3=—
**Replicate annotations:** r1: clean_merge runs in the gate repository, whose `GIT_OBJECT_DIRECTORY` is the real store (`scripts/build-loop.sh:1646`, `:937`) · r1+r2: idempotent (cca66dc2 run twice: 87 then 87) · r1: an amended merge and a `--no-commit` merge added no objects (see Claim 38) · r3: its C18a quotes this clause inside the "87 objects" figure claim; its Stale verdict is about the figure and is clustered with Claim 21b

Objects: a merge made with `-s ours` (neither conflicting nor hand-resolved) also added a new object (X7: `count: 13` before, `count: 14` after). Precise version: "any merge whose tree is not merge-tree's (hand-resolved, conflicting, a non-default strategy) adds ..." (r2).

**Evidence:** `scripts/build-loop.sh:1641-1648`, `<scratch>/fcf-r2-ours.log`, `<scratch>/fcf-r2-real.log`, `<scratch>/u3b2-fcf-r1/p3.out`

---

## Claim 21b: Row 728 "87 objects, 616 KiB over this repo's history"

**Location:** `docs/reviews/override-log.md:728`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a full-history run on a fresh clone of /workspace main at 34cf382f, with HEAD's and cca66dc2's scripts. It does not establish future history: a gate- or chore-subject merge that does not merge cleanly would add objects.
**Replicate verdicts:** r1=Incorrect · r2=Verified (compound) · r3=Stale
**Replicate annotations:** r2: verdicted as the pre-E4 behaviour, "It does not apply to HEAD, which wrote 0 objects on the same history" · r3: Stale, reword to "only a gate- or chore-subject merge; none on this repo's history at HEAD (87 objects at cca66dc2)"; cac2ba0c's tree equals merge-tree's (`71374d6e...` both); matches the logged "count quoted in prose that the artifact no longer bears out" family

This is text, not behaviour. The figure is the pre-E4 code's: cca66dc2's script took the clone from `count: 0` to `count: 87` / `size: 616`. HEAD's script, which 4afdd68b introduced alongside this row, leaves `count: 0` / `size: 0` after two runs. Since E4, merge-tree runs only after a gate or chore subject matches (`scripts/build-loop.sh:1657-1658`, `:1665-1666`), and this repo's only such merge (cac2ba0c) is clean. 4afdd68b's own message says "saving ~1.5 s and every store write on this repo's history". Precise: at HEAD, 0 objects over this repo's history; 87 objects / 616 KiB was the pre-E4 cost (r1).

**Evidence:** `docs/reviews/override-log.md:728`, `scripts/build-loop.sh:1655-1666`, `<scratch>/u3b2-fcf-r1/p3.out`, `<scratch>/fcf-r2-real.log`, `<scratch>/u3b2-fcf-r3/p1.log`, `<scratch>/u3b2-fcf-r3/p5.log`

---

## Claim 21c: Row 728 "a constructed merge with thousands of modified renames costs ~5 s per run ... the rename case fails closed past git's limit"

**Location:** `docs/reviews/override-log.md:728`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the object-writing cases and one rename construction. It does not reproduce the source measurement's 100,001-file tree.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate (compound) · r3=Unverifiable
**Replicate annotations:** r1: p9/p9b with HEAD's script: 3,000 renames, merge-tree 1333 ms, gate; 6,900 renames, merge-tree 5854 ms, run 6035 ms against a 427 ms baseline, gate; 8,000 renames, merge-tree rc 1, other (fails closed); "does not establish other constructions, or the exact limit value git applies" · r3: not reproduced; verifying needs the i2 performance review's 100,001-file, 5,000-rename fixture · r1's 6,900-rename construction reached ~5.9 s without a ~100k-file tree, which bears on r2's "needs a very large tree" qualifier

X6's 3,000 renamed-and-edited files, also edited on main, cost 681 ms against a 261 ms baseline. The ~5 s figure comes from `performance-review-2026-10-12-u3b2-i2.md:26` (5,000 inexact renames on a 100,001-file tree, merge-tree alone 5.47 s), so the cost needs a very large tree as well. Precise: "thousands of renames both sides touch, on a ~100k-file tree, cost ~5 s" (r2).

**Evidence:** `docs/reviews/performance-review-2026-10-12-u3b2-i2.md:26-27`, `<scratch>/fcf-r2-ren.log`, `<scratch>/u3b2-fcf-r1/p9.out`, `<scratch>/u3b2-fcf-r1/p9b.out`

---

## Claim 22a: Plan U3b2 "As built" note: gated after state_start; reads in the gate repository; SINCE full id (short id is usage, exit 1), else "main MAIN -" and "refuse main-log: WHY"; output format; exit 2 on any other or refusal

**Location:** `docs/working/plan-build-loop-handoff.md:325` (r2: `:329`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause against the code and probes P1-P8 and the suite. It does not establish U4's side of the hand-off.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: the rev-list-failure refusal was read, not executed

Gating: `GATED=""; [[ "$MODE" =~ ^(settings|status|marker)$ ]] || GATED=1` (`scripts/build-loop.sh:629`), then `state_start` / `main_log "${ARGS[0]}" || exit 2` (`:1715-1716`). Reads go through `gate_git` (`:1649-1700`). Usage: `[[ $# -eq 2 && "$2" =~ ^([0123456789abcdef]{40}|[0123456789abcdef]{64})$ ]] || usage` (`:453`). Executed: uppercase → usage, exit 1 (P7); 64-hex in a sha1 repo → `main MAIN -` and a refusal, exit 2 (P7b); SINCE == MAIN → `main MAIN 0`, exit 0 (P8); the suite passes (r1).

**Evidence:** `docs/working/plan-build-loop-handoff.md:325`, `scripts/build-loop.sh:451-453`, `scripts/build-loop.sh:1649-1717`, `<scratch>/u3b2-fcf-r1/p1.out`, `<scratch>/fcf-r2-probe.log`

---

## Claim 22b: Plan note: the class rules (clean merge; gate byte for byte; chore record names the branch; answers matched per hunk with at least one added answer line) and the bootstrap; "Anything unread is other"

**Location:** `docs/working/plan-build-loop-handoff.md:325` (r2: `:329`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each clause against the code and probes P1-P8 and the suite. It does not establish U4's side of the hand-off.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: header nuances (CR, any line of the record) are covered under the header claims (here Claims 26-28) · r2: X3 shows a Status flip plus an answer in one hunk read answers, and a route change plus an answer read other

r2 X2/X3: an id not on main's history printed `main 487a1d40... -`; answers within one hunk and the header rule behave as stated; gate and chore as in Claims 11-12. r3: each class clause checked in its header claims, both tests pass at HEAD.

**Evidence:** `scripts/build-loop.sh:1612-1686`, `<scratch>/fcf-r2-probe.log`, `<scratch>/fcf-r2-probe2.log`, `<scratch>/u3b2-fcf-r3/p2.log`, `<scratch>/u3b2-fcf-r3/p4.log`

---

## Claim 23: Header "after --state's gate but its caller check. SINCE: a full 40- or 64-hex id of a commit on the default branch's first-parent history"

**Location:** `scripts/build-loop.sh:138-142`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the startup order. It does not establish what the caller check would add.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: does not cover the caller-environment checks --main-log skips (row 723 records those) · r3: does not establish the order U4 calls modes in

`if [[ "$MODE" == state ]]; then caller_gate || exit 2; fi` / `if [[ -n "$GATED" ]]; then state_gate || exit 2; fi` (`scripts/build-loop.sh:631-632`). The main-log case is `state_start` (`:1715`).

**Evidence:** `scripts/build-loop.sh:629-639`, `scripts/build-loop.sh:1714-1717`

---

## Claim 24: Header output "main MAIN N ... one line each after this, oldest first ("-" before a refusal)"; SUBJECT "("-" when empty, so "-" may also be the text "-")"

**Location:** `scripts/build-loop.sh:143-149`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_log's listing and order. It does not establish a SINCE that equals a non-first-parent commit (which refuses: P7b, test 2).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: does not cover subjects altered by the lib's scrub; a `-m -` commit also printed `-` · r3: a first message line holding a CR is printed as is, through scrub

The newer commits are cut with `LC_ALL=C awk -v s="$1" '$0 == s { f = 1; exit } { print } END { exit !f }'`, the count printed by `echo "main $MAIN_SHA $(wc -l < "$GATE_TMP/after")"`, and the loop reads `done < <(tac "$GATE_TMP/after")` (`scripts/build-loop.sh:1696-1701`). Test 1 expects `main $T 5` followed by the oldest-first lines (r1).

**Evidence:** `scripts/build-loop.sh:1690-1703`, `test/scripts/build-loop-orchestrator.bats:331-336`, `<scratch>/fcf-r2-probe.log`

---

## Claim 25: Header "A two-parent commit is gate or chore only when its tree is the clean merge of its parents (merge-tree ...), as --merge and a git merge with git's defaults write it (no -s or -X, no merge.* config, no merge attribute); an amended or hand-resolved merge is other"

**Location:** `scripts/build-loop.sh:149-155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers `--merge`'s own result (the same `merge-tree --write-tree --no-messages MAIN TIP` at `:1017` as at `:1646`), a default `git merge --no-ff`, and conflicting, amended and `-s ours` merges reading other. It does not establish that the list of knobs is complete: rename-related `diff.*` settings, which `git merge` also honours, are not named; no probe showed a clean tree that differs because of them.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish completeness of the 'git's defaults' qualifier list against every caller setting"; `--no-commit` plus an extra file → other (p10) · r3: the gate repository reads no global or system config (`GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, `:518`); r3 reads non-default rename settings as excluded by the header, where r2 reads them as unnamed

`t="$(gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}")" && [[ "$t" == "$(LC_ALL=C awk '/^tree / { print $2; exit }' "$GATE_TMP/c")" ]]` (`:1646-1647`) (r2).

**Evidence:** `scripts/build-loop.sh:1017`, `scripts/build-loop.sh:1644-1648`, `<scratch>/fcf-r2-probe.log`, `<scratch>/fcf-r2-ours.log`, `<scratch>/fcf-r2-mut.log`, `<scratch>/u3b2-fcf-r1/p10.out`

---

## Claim 26: Header "gate: two parents and the message --merge writes, byte for byte"

**Location:** `scripts/build-loop.sh:155-156`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers self-merge and approved forms, an extra line, a missing approved trailer, and one parent. It does not establish messages whose fifth line or later differs (cmp catches these: whole file compared).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: the approved message with one extra trailing newline read other

`cmp -s "$GATE_TMP/want" "$GATE_TMP/m"` compares the whole message, everything after the header's blank line: `perl -0777 -ne 's/\A.*?\n\n//s and print'` (`scripts/build-loop.sh:1655`, `:1664`). P1: the approved form reads gate. Test 2: a line more, approved without its trailer, and one parent all read other (r1).

**Evidence:** `scripts/build-loop.sh:1652-1664`, `test/scripts/build-loop-orchestrator.bats:344-357`, `<scratch>/u3b2-fcf-r1/p1.out`

---

## Claim 27: Header chore rule (subject then the end, " into " or ":"; B pattern; record docs/working/cycles/cycle-*.md, mode 100644, added or changed; "Branch: B" anywhere, a trailing CR dropped)

**Location:** `scripts/build-loop.sh:156-163`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed element. It does not establish records in a subdirectory of cycles/ (rejected by `[^/]+`, consistent with the header's glob).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2+r3: DATE is checked for digit shape only, not as a valid calendar date · r2: "mode 100644" is checked on the new side only (`:[01234567]{6}\ 100644`)

P4: CRLF records with `Merge branch '...' into main` read chore; the 100755 record reads other. Test 2: a record naming another branch, the branch `chore/dev-cycle-x`, and an amended chore merge all read other (r1).

**Evidence:** `scripts/build-loop.sh:1664-1673`, `<scratch>/u3b2-fcf-r1/p1.out`, `<scratch>/u3b2-fcf-r3/p4.log`

---

## Claim 28: Header answers rule (one parent; only the two questions files; mode 100644 both sides; blank, answer or header lines; header Status-only, matched in order per hunk; at least one added answer; any entry's)

**Location:** `scripts/build-loop.sh:163-172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule over the probed shapes. It does not establish a header line whose Status field has no value after `**Status:**` (compared literally, so it reads other).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: an indented answer (`  Q-001: [1]`) reads other, since only `- ` is stripped; X3: a route change plus an answer read other and a Status flip plus an answer in one hunk read answers · r3: "does not establish anything about content beyond the line kinds (by design, F19)"

The raw check is `^:100644\ 100644\ ...\ M$` plus the two paths (`scripts/build-loop.sh:1677`). needs() sets aside a field starting `**Status:** ` after leading blanks (`:1614-1616`), and flush() compares the removed and added lists in order (`:1618`). P5: flip plus `**answered (...)` → answers; leading-blank Status plus `- Q-9:` → answers; Status field removed → other; mode 100755 → other (r1).

**Evidence:** `scripts/build-loop.sh:1612-1631`, `scripts/build-loop.sh:1674-1684`, `<scratch>/u3b2-fcf-r1/p1.out`, `<scratch>/fcf-r2-probe.log`, `<scratch>/fcf-r2-probe2.log`, `<scratch>/u3b2-fcf-r3/p4.log`

---

## Claim 29: Header "Any other commit, or one whose message, parents or changes cannot be read, is other"

**Location:** `scripts/build-loop.sh:172-174`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers every gate_git read guarded by `|| return 0` with CLASS preset to other, and the pipeline under pipefail. It does not establish a failure inside the `mapfile -t ps < <(awk ...)` process substitution, whose status is unchecked; a short parent list falls to the default other.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=—
**Replicate annotations:** r2: the answers branch never reads the message, though a perl failure returns 0 (other) first

The class defaults to `CLASS=other; SUBJ=-`, and each read is followed by `|| return 0` (`scripts/build-loop.sh:1651-1683`). gate_git returns 3 when git wrote to stderr (`:942-947`) (r1).

**Evidence:** `scripts/build-loop.sh:942-947`, `scripts/build-loop.sh:1649-1686`

---

## Claim 30: Header "The class is read from the commit's own text (and commits before MAIN, and objects not in MAIN's tree, are not re-hashed)"

**Location:** `scripts/build-loop.sh:174-176`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers --main-log's store_check scope. It does not establish what a forger could do (F19 residual).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: does not establish that reads of history objects are safe from a same-uid writer

The only re-hash is `store_check --main "$MAIN_SHA"`, covering MAIN's commit, root tree and every tree and blob below it (`scripts/build-loop.sh:1224`; store_check's comment at `:948-956`).

**Evidence:** `scripts/build-loop.sh:948-1001`, `scripts/build-loop.sh:1220-1226`

---

## Claim 31: Header "or "main MAIN -" and refuse main-log: WHY, when SINCE (a full id; a short one is a usage error, exit 1) is not on that history ... or it cannot be listed"

**Location:** `scripts/build-loop.sh:177-180`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the not-on-history refusal and usage. It does not establish the "cannot be listed" path, which was not executed; the code is `|| { echo "main $MAIN_SHA -"; echo "refuse main-log: the default branch's first-parent history could not be listed"; return 1; }` at `:1693-1694`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: the "cannot be listed" branch was read, not executed (same as r1's scope) · r3: an uppercase hex id is also a usage error, exit 1 (`:444`, `:453`)

P7b and test 2 (`ml "$X" 2 "main $T -` / `refuse main-log: $X is not on ...`) both pass. A 12-hex id gives exit 1 with stderr `--main-log takes one full 40- or 64-hex commit id` (r1).

**Evidence:** `scripts/build-loop.sh:1690-1698`, `test/scripts/build-loop-orchestrator.bats:371-373`, `<scratch>/fcf-r2-probe.log`

---

## Claim 32: Header "Writes nothing but --check's and --main-log's merge objects (merge-tree writes the merged trees and blobs into the object store) ... and its own temporary directory, removed at exit"

**Location:** `scripts/build-loop.sh:410-416`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers --main-log's writes: its GATE_TMP files and merge-tree's objects. It does not establish mtime freshening of existing objects, which git does on a re-write and is not a new object.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: does not establish mtime freshening of an existing pack by merge-tree, which the i2 performance review reported and which this list does not name (Confidence Medium) · r2: a conflicting gate-shaped merge added 2 loose objects (123 to 125), a second run added none; does not re-verify the other modes' lists

main_log and log_class write only `$GATE_TMP/{fp,after,c,m,want,d,p}` and the gate repository under GATE_TMP (`scripts/build-loop.sh:1649-1700`), from `GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT` (`:1222`) (r1).

**Evidence:** `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1644-1703`, `<scratch>/fcf-r2-probe.log`, `<scratch>/u3b2-fcf-r3/p1.log`

---

## Claim 33: Exit section "for --main-log no other line ... 2 ... --main-log's other or refuse line ... 1 ... a failed mktemp (--state, --main-log, ...; no line printed)"

**Location:** `scripts/build-loop.sh:419-428`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exits 0, 1 and 2 for --main-log. It does not establish exits from state_gate or default_gate refusals, which were not executed here.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: a failed command inside main_log never reaches the top level, because `main_log ... || exit 2` disables set -e inside it · r3: exit under signals not established; r3 read the mktemp exit-1 path from code (r1 and r2 executed it)

P8 exits 0 with no other line; P2 and P3 exit 2 on other; P7b exits 2 on a refusal. P6 (`TMPDIR=/nonexistent/x`) exits 1, with only mktemp's own stderr and no stdout line (r1; r2 X5 the same).

**Evidence:** `scripts/build-loop.sh:1222`, `scripts/build-loop.sh:1714-1717`, `<scratch>/u3b2-fcf-r1/p1.out`, `<scratch>/fcf-r2-mk.log`

---

## Claim 34: gate_msg comment "log_class parses the fields back out by the same shape (subject, line 3, line 4) and compares bytes, so a change here must change its parser too; gate merges already on main keep the old shape and would read as other"

**Location:** `scripts/build-loop.sh:1368-1373`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the parser's indices and the byte compare. It does not establish anything about a future format.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: messages longer than five lines are still compared whole by `cmp` · r3: the "old shape" clause is conditional on a future change; callers are at `:1461` and `:1664` only

The parser reads `${m[2]-}` as `Build-loop-gate: (.+)` and `${m[3]-}` as `Build-loop-approved: (Q-[0123456789]+)` (`scripts/build-loop.sh:1659-1662`), then compares with `cmp -s` (`:1664`) (r1).

**Evidence:** `scripts/build-loop.sh:1368-1377`, `scripts/build-loop.sh:1655-1664`

---

## Claim 35: land's call `gate_msg ... "${2-}"` writes the same message as the removed inline printf

**Location:** `scripts/build-loop.sh:1461`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the self-merge and approved callers. It does not establish a land called with a non-empty `$2` under self-merge (the merge arm never does this).
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

The old line was `[[ "$1" != approved ]] || printf 'Build-loop-approved: %s\n' "$2"`; the new gate_msg line is `[[ -z "${4-}" ]] || printf 'Build-loop-approved: %s\n' "$4"` (`scripts/build-loop.sh:1376`). The only caller is `land "$AUTH" "$APPROVED"`, where APPROVED is empty for self-merge (`:1738`, `:1746`). A real `--merge` reads gate in test 1 (r3).

**Evidence:** `scripts/build-loop.sh:1374-1377`, `scripts/build-loop.sh:1737-1749`, `<scratch>/u3b2-fcf-r3/p2.log`

---

## Claim 36: ANSWERS_AWK comment (rule summary; "a Status flip or a deleted answer alone adds none"; "Any added answer label counts, in any entry and from anyone"; labels are --check-answer's, lib points back)

**Location:** `scripts/build-loop.sh:1602-1610`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the awk against the comment and the back-pointer's existence. It does not establish label parity beyond shape: the lib matches only the entry's own `id ":"`, while this matches any `Q-` and digits, as the comment states ("any entry").
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: same shapes, different entry scope (lib binds the ID to the entry; ANSWERS_AWK accepts any `Q-` number)

The lib's pointer reads `# build-loop.sh's ANSWERS_AWK (--main-log's answers class) copies these labels` (`scripts/lib/dev-cycle-read.sh:2019`). Behaviour is covered by Claims 3, 20 and 28 (r1).

**Evidence:** `scripts/build-loop.sh:1602-1631`, `scripts/lib/dev-cycle-read.sh:2019-2058`, `<scratch>/u3b2-fcf-r3/p3.log`

---

## Claim 37: log_class comment "C, its changes and the record it adds are read in the gate repository ...; any failed read makes C other. ... Checked after the subject, so other merges cost no merge-tree run"

**Location:** `scripts/build-loop.sh:1632-1640`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers gate_git use and the order. Failed reads are covered with Claim 29's residue.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2+r3: "the record it adds" also covers a changed record (`[AM]`), as the header says; harmless for where reads happen

P3: a hand-resolved merge with a non-gate subject left loose objects at 25 before and 25 after. The full-history run at HEAD wrote 0 objects, against 87 for cca66dc2 (r1).

**Evidence:** `scripts/build-loop.sh:1649-1686`, `<scratch>/u3b2-fcf-r1/p1.out`, `<scratch>/u3b2-fcf-r1/p3.out`, `<scratch>/fcf-r2-real.log`

---

## Claim 38: clean_merge comment "merge-tree writes the merged trees and blobs into the object store, as --check's does (only a conflicting or hand-resolved merge adds new ones)"

**Location:** `scripts/build-loop.sh:1641-1643`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which merges add objects. It does not cover merges whose original merge objects were garbage-collected.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: an amended gate merge (14 → 14) and a `--no-commit` merge plus a slip file (13 → 13) added no objects; a merge built by commit-tree over an arbitrary tree is outside "hand-resolved" as worded and would add the clean tree · r3: the header's own list (`:153-155`, "no -s or -X, no merge.* config, no merge attribute") is the precise set; an amended merge usually adds none because the pre-amend tree remains

A chore-shaped `git merge -s ours` (no conflict, no hand resolution) also added an object (X7: 13 to 14 loose). Precise version: "only a merge whose tree is not merge-tree's (conflicting, hand-resolved, a non-default strategy or option) adds new ones" (r2).

**Evidence:** `scripts/build-loop.sh:1641-1648`, `<scratch>/fcf-r2-ours.log`, `<scratch>/u3b2-fcf-r1/p1.out`, `<scratch>/u3b2-fcf-r1/p10.out`

---

## Claim 39: "# pipefail: a failed read is no record."

**Location:** `scripts/build-loop.sh:1671`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pipeline's status under `set -o pipefail`. It does not establish awk's own failure modes.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

The script sets `set -euo pipefail` (`scripts/build-loop.sh:431`). The pipeline `gate_git cat-file blob "${BASH_REMATCH[1]}" | LC_ALL=C awk ... && { CLASS=chore; return 0; }` (`:1672`) fails when gate_git fails, even if awk found the line; awk reads to EOF, so no SIGPIPE arises (r1).

**Evidence:** `scripts/build-loop.sh:431`, `scripts/build-loop.sh:1672`

---

## Claim 40: "# Every record read whole, as check_line reads its diff."

**Location:** `scripts/build-loop.sh:1681`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the NUL count against the record count. It does not establish check_line's own reader.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

`[[ "$x" -gt 0 && "$(tr -cd '\000' < "$GATE_TMP/d" | wc -c)" -eq $((2 * x)) ]] || return 0` (`scripts/build-loop.sh:1682`). A trailing unterminated field changes the count, so C reads other (r1).

**Evidence:** `scripts/build-loop.sh:1676-1682`

---

## Claim 41: main_log comment "Returns 1 when SINCE is refused or any commit is other", "Main's commit first, even before a refusal", "The commits above SINCE (rev-list lists newest first)"

**Location:** `scripts/build-loop.sh:1688-1695`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both returns. It does not establish the list-failure path at runtime.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: if `tac` fails the loop reads nothing and returns 0 with N lines promised (an untested edge)

The function ends with `[[ "$CLASS" != other ]] || o=1` and `return "$o"` (`scripts/build-loop.sh:1700-1703`). Both refusals echo `main $MAIN_SHA -` first (`:1694`, `:1697`). P7b confirms it (r1).

**Evidence:** `scripts/build-loop.sh:1688-1703`, `<scratch>/u3b2-fcf-r1/p1.out`, `<scratch>/u3b2-fcf-r3/p2.log`

---

## Claim 42: Lib back-pointer "build-loop.sh's ANSWERS_AWK (--main-log's answers class) copies these labels and the header line's Status field: change both together"

**Location:** `scripts/lib/dev-cycle-read.sh:2019-2020`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the label shapes (`- ` prefix, `Q-` and digits and `:`, `**answer(:|ed| \()` any case) and the Status field read. It does not establish identity: the lib binds Q-NNN to the entry, ANSWERS_AWK does not.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r3: does not establish the lib's last-Status-wins rule, which ANSWERS_AWK has no need of

The lib's tests are `if (index(line, id ":") == 1)` and `if (low !~ /^\*\*answer(:|ed| \()/) next` after `sub(/^- /, "", line)`, plus `if (substr(f, 1, 12) == "**Status:** ")` (`scripts/lib/dev-cycle-read.sh:2050-2058`); ANSWERS_AWK matches the same shapes (`scripts/build-loop.sh:1615`, `:1626-1627`) (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:2043-2058`, `scripts/build-loop.sh:1612-1631`

---

## Claim 43: Test comment: near misses that read other include "a header line whose route changes too"

**Location:** `test/scripts/build-loop-orchestrator.bats:208-210`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test pins. It does not establish a defect in the code: X3 shows the header rule works.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1 (on its D2 and E1 claims, and its Goal-Alignment residues): "The 'route change' near miss in test 2 does not isolate the header-matching rule, because `n > 0` alone rejects it" · r3: test 2 checks only that the class column is all `other`; the per-line mapping is not asserted

The route-change commit `q 's/you: judgment/agent/'` (`:216`) adds no answer line, so it reads other through `n > 0` alone. In X1 a mutant that skips every `**Needs:**` line without comparing them (`{ next }`) still passed both tests. The header-match rule is unpinned. A route change plus an added answer is the case that pins it (X3: other at HEAD) (r2).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:208-219`, `scripts/build-loop.sh:1628`, `<scratch>/fcf-r2-mut.log`, `<scratch>/fcf-r2-probe2.log`

---

## Claim 44: Test comments: ml, q, qs and chore helpers; gate near misses ("with a line more, on one parent, approved without its trailer, or over another tree"); chore near misses and the empty commit; "The Status flip first ... (a real diff each ...)"

**Location:** `test/scripts/build-loop-orchestrator.bats:162-216`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each fixture doing what its comment names, and both tests passing at HEAD. It does not establish isolation of each near-miss: test 2 checks only that the class column is all `other`, so one near-miss turning gate would be caught, but the per-line mapping is not asserted.
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** none

`chore()` makes `docs/working/cycles/cycle-2026-10-12.md` and runs `git merge -q --no-ff` (`:168-169`). The over-another-tree tip uses `merge-tree main feat/x` after the slip but takes parents `main` and `$X` (`:200-201`). Test 2 asserts nine lines with `lines[4] = "other $E -"` (`:218-219`). p2 HEAD: ok 1, ok 2 (r3).

**Evidence:** `test/scripts/build-loop-orchestrator.bats:162-224`, `<scratch>/u3b2-fcf-r3/p2.log`

---

## Claim 45: Commit 1d829fee message "answers (only answer and Status lines in the questions files) or other; exit 2 on any other ... Gated; reads run in the gate repository"

**Location:** `git show 1d829fee` (message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers 1d829fee's ANSWERS_AWK. It does not judge later commits.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: the blank-line rule is carried unchanged to HEAD (`scripts/build-loop.sh:1625`) · r3: checked the message against 1d829fee's own code (its script passes HEAD's test 1; fails test 2 only on cases the later D1/D2 fixes added)

At 1d829fee the awk also accepted blank lines, `if (l ~ /^[ \t]*$/) next` (`git show 1d829fee:scripts/build-loop.sh` line 1607). It counted any non-blank changed line in `n++` (line 1608), so a Status flip alone passed; D2 later fixed this. Precise: "only blank, answer and header-Status lines" (r1).

**Evidence:** `git show 1d829fee:scripts/build-loop.sh` lines 1594-1613, `<scratch>/u3b2-fcf-r3/p2.log`

---

## Claim 46: Commit cca66dc2 message (D1 clean merge, D2 added answer — "a Status flip, a deleted answer or a revert passed as answers", D4, D9, text fixes; "a hand-resolved chore merge now reads as other")

**Location:** `git show cca66dc2` (message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed change, as Claims 2-5. It does not re-judge the rubric rows.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: a revert that restores an answer still reads answers (E2, row 727) · r3: the Status-flip clause of D2 was not pinned by a test at cca66dc2 (see Claim 3); cca66dc2's script passes HEAD's tests and its output on the clone is byte-identical to HEAD's

See Claims 2, 3 and 5. "a hand-resolved chore merge now reads as other" follows from clean_merge (`scripts/build-loop.sh:1666`) and P3's analogue (r1).

**Evidence:** `scripts/build-loop.sh:1644-1666`, `<scratch>/u3b2-fcf-r1/p2.out`, `<scratch>/fcf-r2-mut.log`, `<scratch>/u3b2-fcf-r3/p2.log`

---

## Claim 47: Commit 4afdd68b message "E1 ... every near-miss commit is asserted non-empty. E4: merge-tree runs only once a gate or chore subject matches (clean_merge), saving ~1.5 s and every store write on this repo's history ... SUBJ starts as "-" so a failed read prints it too"

**Location:** `git show 4afdd68b` (message)
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the ordering, the store writes (0 at HEAD against 87 at cca66dc2) and the measured saving. It does not establish timing on another machine.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate
**Replicate annotations:** coverage differs: r2 did not assess the "non-empty" clause, r3 did not assess the SUBJ clause · r1: measured saving about 1.6-2.0 s; r2: about 1.6-1.7 s (Medium, shared host) · r2: one chore-subject merge (cac2ba0c) still runs merge-tree but writes nothing new

"Every store write" holds: HEAD wrote 0 objects and cca66dc2 wrote 87. Two parts are imprecise. The non-empty assertion covers only the four answers near-misses (`for i in 4 3 2 1`, `test/scripts/build-loop-orchestrator.bats:217`), and the empty-commit near-miss is empty on purpose (Claim 7). The saving measured by r3 was 1.8-2.6 s (cca66dc2 9393, 9698 and 9913 ms against HEAD 7092-8113 ms), more than "~1.5 s"; its direction is right (r3).

**Evidence:** `scripts/build-loop.sh:1651`, `scripts/build-loop.sh:1657-1667`, `test/scripts/build-loop-orchestrator.bats:217`, `<scratch>/u3b2-fcf-r3/p5.log`, `<scratch>/u3b2-fcf-r1/p4.out`, `<scratch>/fcf-r2-real.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 19a** (`docs/reviews/override-log.md:726`): "Every commit on this repo's main today reads other" — dfe4c0df (an answers commit, on main since 2026-09-28) reads answers. Text, not behaviour; the row's conclusion holds. (r2 Incorrect; r1, r3 Mostly accurate.)
- **Claim 21b** (`docs/reviews/override-log.md:728`): "87 objects, 616 KiB over this repo's history" is cca66dc2's pre-E4 cost; at HEAD a full-history run writes 0 objects. Text, not behaviour. (r1 Incorrect; r3 Stale; r2 Verified as pre-E4.)

### Stale
None.

### Mostly Accurate
- **Claim 7** (`docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md:44`): E1's "each near-miss commit asserted non-empty" covers only the four answers near-misses.
- **Claim 21a** (`docs/reviews/override-log.md:728`): a non-default-strategy merge (`-s ours`) also adds objects, not only hand-resolved or conflicting ones.
- **Claim 21c** (`docs/reviews/override-log.md:728`): the ~5 s rename cost — r2 ties it to a ~100k-file tree; r1 measured ~5.9 s at 6,900 renames; r3 could not reproduce.
- **Claim 38** (`scripts/build-loop.sh:1641-1643`): "only a conflicting or hand-resolved merge adds new ones" omits `-s`/`-X`/config merges.
- **Claim 43** (`test/scripts/build-loop-orchestrator.bats:208-210`): the route-change near miss reads other only through `n > 0`; the header-match rule is unpinned (a mutant dropping it survives).
- **Claim 45** (commit 1d829fee message): "only answer and Status lines" omits blank lines.
- **Claim 47** (commit 4afdd68b message): shares Claim 7's "every near-miss" overreach; r3 measured 1.8-2.6 s, not ~1.5 s.

### Unverifiable
None.

---

## Escalations

- **`test/scripts/build-loop-orchestrator.bats:208-219` / `scripts/build-loop.sh:1628`** — the header-match rule (route change with Status set aside) is not pinned by any test; a mutant skipping every `**Needs:**` line survives. Suggested pin: a route change plus an added answer line. Raised by r1 (Goal-Alignment residue; Claim 3/6 scopes) and r2 (C29). Addressee: orchestrator.
- **`scripts/build-loop.sh:153-154` (and `docs/reviews/override-log.md:719`)** — the "git's defaults" qualifier list (no -s/-X, no merge.* config, no merge attribute) was not proven complete; rename-related `diff.*` settings are not named. Raised by r1 (Goal-Alignment residue; Claim 10 scope) and r2 (C18 scope). Addressee: orchestrator.
- **`docs/reviews/override-log.md:728`** — the ~5 s rename-cost figure was not reproduced by r3 and needs execution on the i2 performance review's 100,001-file, 5,000-rename fixture; r1 and r2 measured different constructions with different conclusions about tree size. Raised by r3 (C18b). Addressee: orchestrator.

No replicate wrote a Goal-Alignment `Escalate:` item or an `Out of scope:` bullet naming a critic.

---

## Verdict stability

- **Total clusters (claim rows):** 52 (46 reported by two or more replicates; 6 single-replicate detections: Claims 4, 9, 35, 39, 40, 44).
- **All reporting replicates agreed:** 43 (37 multi-replicate rows plus the 6 single-replicate rows).
- **Verdicts disagreed:** 9
  - Claim 7: r1=Verified · r2=Verified · r3=Mostly accurate
  - Claim 19a: r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate
  - Claim 21a: r1=Verified (compound) · r2=Mostly accurate · r3=—
  - Claim 21b: r1=Incorrect · r2=Verified (compound) · r3=Stale
  - Claim 21c: r1=Verified (compound) · r2=Mostly accurate (compound) · r3=Unverifiable
  - Claim 38: r1=Verified · r2=Mostly accurate · r3=Mostly accurate
  - Claim 43: r1=— · r2=Mostly accurate · r3=Verified (compound)
  - Claim 45: r1=Mostly accurate · r2=Mostly accurate · r3=Verified
  - Claim 47: r1=Verified · r2=Verified · r3=Mostly accurate
- **Agreement rate:** 43/52 = 82.7% (multi-replicate rows only: 37/46 = 80.4%).
- **Clustering notes:** row 728 was split three ways (object-writing clause, the 87-object figure, the rename cost) as the common refinement of r1's, r2's and r3's different splits. r3's C18a quotes the hand-resolved clause but its Scope and verdict are on the object count, so it is clustered with Claim 21b only (annotated on 21a). r2's C13a covered both the write path (21a) and the figure (21b) and is recorded as compound on 21b. Every non-Verified verdict above is on prose (override rows, rubric, commit messages, a code comment, a test comment); no replicate found a behavioural mismatch in the code.

## Submitted Claims

## Claim 53a: "A chore-subject merge whose tree is not merge-tree's clean merge reads other, for `-X theirs` [...] and unrelated-history merges"

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:1644-1648`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two-parent chore-subject merges made with `-X theirs` over a conflicting file and with `--allow-unrelated-histories`, each with a valid cycle record. It does not establish that every `-X theirs` merge reads other: a clean `-X theirs` merge has the clean tree and reads chore, as the claim's qualifier allows. It also does not cover gate-subject merges, which were not probed here.

The chore branch calls the tree check before it reads the record:

```bash
# scripts/build-loop.sh:1644-1648
clean_merge() {
  local t
  t="$(gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}")" \
    && [[ "$t" == "$(LC_ALL=C awk '/^tree / { print $2; exit }' "$GATE_TMP/c")" ]]
}
```

```bash
# scripts/build-loop.sh:1665-1667
  elif [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(chore/dev-cycle-[0123456789]{4}-[0123456789]{2}-[0123456789]{2}(-[0123456789]{4})?)\'($|\ into\ |:) ]]; then
    b="${BASH_REMATCH[1]}"
    clean_merge || return 0
```
(excerpt ends :1667; enclosing log_class continues to :1687 — read)

`log_class` starts with `CLASS=other` (`:1651`), so `return 0` leaves the class as other. A conflicting merge-tree exits non-zero. On unrelated histories merge-tree refuses and writes to stderr, and `gate_git` then returns 3 (`[[ ! -s "$GATE_TMP/err" ]] || return 3`, `:946`). Either way `clean_merge` fails.

Probe p1 used fixture `/tmp/u3b2rv-sub-e7m0` at 2026-10-12T23:38:15Z. The command was `timeout 60 bash .../scripts/build-loop.sh --main-log $S`, run in `$T/repo`, and it exited 2. Every cycle record held its own `Branch:` line. The run printed:
- `chore 64902935… Merge branch 'chore/dev-cycle-2026-10-01': control` (control)
- `other f4824153… Merge branch 'chore/dev-cycle-2026-10-02': theirs-conflict`
- `chore e5c36880… Merge branch 'chore/dev-cycle-2026-10-03': theirs-clean` (a clean `-X theirs` merge; the claim's qualifier excludes it)
- `other ed7af3b0… Merge branch 'chore/dev-cycle-2026-10-05': unrelated`

**Evidence:** `scripts/build-loop.sh:1644-1648`, `scripts/build-loop.sh:1651`, `scripts/build-loop.sh:1665-1667`, `scripts/build-loop.sh:942-948`, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p1.out

---

## Claim 53b: "A chore-subject merge whose tree is not merge-tree's clean merge reads other, for [...] octopus [...] merges (`:1644-1648`, `:1666-1667`)"

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:1665-1667`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which line rejects an octopus merge with a chore subject. The outcome (other) is right; the stated mechanism (clean_merge at the cited lines) is wrong. This does not establish anything about gate-subject octopus merges beyond the same parent-count test at `:1657`.

An octopus merge with a chore subject does read other: p1 printed `other 8f5a119d… Merge branch 'chore/dev-cycle-2026-10-04': octopus` for a commit with three parents. The tree check is not what rejects it. The parent-count test on the `elif` comes first:

```bash
# scripts/build-loop.sh:1665
  elif [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(chore/dev-cycle-...
```
(excerpt ends :1665; enclosing log_class continues to :1687 — read)

The one-parent branch (`elif [[ ${#ps[@]} -eq 1 ]]`, `:1674`) does not take it either, so log_class returns with `CLASS=other` and never runs clean_merge. clean_merge could not judge an octopus anyway: it merges only `"${ps[0]}" "${ps[1]}"` (`:1646`). An octopus whose third parent adds nothing could carry exactly that two-parent tree (paraphrased — no quote available because this is an inference from the two-argument call at `:1646`, not a probed case). A reader who trusts clean_merge for octopus merges, and so drops the `-eq 2` guard, would let one through. The precise version: "-X theirs and unrelated-history merges fail clean_merge (`:1644-1648`, `:1667`). An octopus merge fails the two-parent test (`:1665`, and `:1657` for gate)."

**Evidence:** `scripts/build-loop.sh:1646`, `scripts/build-loop.sh:1657`, `scripts/build-loop.sh:1665-1667`, `scripts/build-loop.sh:1674`, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p1.out

---

## Claim 54: "An answers-shaped commit reads other when it adds a NUL-led line, a lone VT line, or a mode change to 100755, even with a valid `Q-001:` line (`:1624-1625`, `:1677`)"

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:1624-1625`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one-parent commits to docs/working/questions.md that add `Q-001: [1]` together with a `+\0hidden` line, a `+\0` line, a `+ \0` line, a `+\v` line, or a 100644 to 100755 mode change, read by mawk (the only awk on this host). It does not establish gawk's or busybox awk's handling of NUL bytes, which were not installed, or NUL anywhere other than at the start of a line.

The awk's blank test accepts only spaces and tabs, so a line holding NUL or VT falls through to `bad = 1`:

```awk
# scripts/build-loop.sh:1623-1629
  s = substr($0, 1, 1); l = substr($0, 2); sub(/\r$/, "", l)
  if (s != "-" && s != "+") { bad = 1; next }
  if (l ~ /^[ \t]*$/) next
  t = l; sub(/^- /, "", t)
  if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) { if (s == "+") n++; next }
  if (substr(l, 1, 10) == "**Needs:**") { if (s == "-") r[++nr] = needs(l); else a[++na] = needs(l); next }
  bad = 1
```
(excerpt ends :1629; enclosing ANSWERS_AWK continues to :1631 — read)

The mode is checked on the raw record: `[[ "$meta" =~ ^:100644\ 100644\ [0123456789abcdef]+\ [0123456789abcdef]+\ M$ && ...` (`:1677`), and anything else hits `|| return 0`.

p1 used fixture `/tmp/u3b2rv-sub-e7m0` and the command `timeout 60 bash .../build-loop.sh --main-log $S2` in `$T/repo`, which exited 2. It printed `answers 8b5ea1d2… ctl` for the plain answer, and `other 2740ac38… nul`, `other db7d1257… vt` and `other 24fe3c3c… mode` for the three cases. The mode commit's raw record read `:100644 100755 … M	docs/working/questions.md`. `od -c` showed that diff-tree `--text` passes the bytes through (`+  \0   h   i   d   d   e   n`).

p3 and p4 ran the extracted ANSWERS_AWK under `LC_ALL=C mawk` on that patch:
- `nul.p` (the `+\0hidden` patch): exit 1
- the NUL line removed: exit 0
- `+\0` alone (`nulalone.p`): exit 1
- `+ \0` (`spnul.p`): exit 1

So mawk keeps NUL inside `$0` and does not truncate the line to blank.

**Evidence:** `scripts/build-loop.sh:1612-1631`, `scripts/build-loop.sh:1674-1684`, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p1.out, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p2.out

---

## Claim 55: "E4 (clean_merge after the subject, 4afdd68b) brought the root-SINCE time on a /workspace main clone back to the pre-D1 (1d829fee) level and cut store writes from 87 to 0 vs cca66dc2, with identical output."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:1657-1659`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two root-SINCE runs per version on fresh clones of /workspace main at 34cf382f (1,119 first-parent commits) on this host. Store writes were counted as the change in `git count-objects` loose objects. It does not establish timings on other hosts or under load, or object writes on a history that has gate or chore merges with conflicts.

At HEAD the subject test runs first and clean_merge comes after it: `if [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(.+)\'\ \(build-loop\ (self-merge|approved merge)\)$ ]]; then` (`:1657`), followed by `clean_merge || return 0` (`:1659`). The chore branch works the same way (`:1665`, `:1667`).

Probe p5 ran in `/tmp/u3b2rv-sub-perf-Jwpt` from 2026-10-12T23:39:20Z to 23:40:11Z, with load average 0.29-0.66. Each version ran `timeout 120 bash s-<v>/scripts/build-loop.sh --main-log <root>` in its own fresh clone `c-<v>`, and each clone started with 155 loose objects:

| Version | root run 1 | root run 2 | loose after |
|---|---|---|---|
| 1d829fee (pre-D1) | 6,569 ms | 6,526 ms | 155 (+0) |
| cca66dc2 | 7,997 ms | 8,144 ms | 242 (+87) |
| 4afdd68b | 6,468 ms | 6,712 ms | 155 (+0) |

Every run exited 2, printed 1,119 lines and wrote 0 bytes to stderr. `cmp` printed `same-1d-head` and `same-cc-head`, so the outputs are byte-identical. HEAD's output was 1 answers line and 1,117 other lines.

**Evidence:** `scripts/build-loop.sh:1644-1648`, `scripts/build-loop.sh:1657-1667`, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p5.out

---

## Claim 56: "A typical window of 10 commits or fewer costs under 0.45 s, mostly state_start."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:1690-1703`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 10-commit and 0-commit windows at the tip of a /workspace main clone (34cf382f). That window has no gate or chore merges, so no merge-tree ran. It does not establish the cost of windows holding gate or chore merges (each adds a merge-tree and record reads), larger trees, or other hosts. "Mostly state_start" is supported only for the gated startup taken as a whole; state_start was not timed on its own.

`--main-log` runs `state_start` and then `main_log` (`main-log)` / `state_start` / `main_log "${ARGS[0]}" || exit 2`, `:1714-1717`). main_log lists main's whole first-parent history (`gate_git rev-list --first-parent "$MAIN_SHA"`, `:1693`) and runs log_class once per commit above SINCE.

p5 measured HEAD's script:
- N=10: 377, 384 and 373 ms (11 lines, exit 2)
- N=0: 323, 330 and 330 ms

p6 ran `bash s-4afdd68b/scripts/build-loop.sh --state` in `c-4afdd68b`, exit 0: 313, 315 and 318 ms. `--settings` took 33-38 ms. The under-0.45 s figure holds. About 0.31 s of the 0.38 s is the --state path. That path is not state_start alone: it also runs the script's startup and state_gate, and --state adds caller_gate. The roughly 0.06 s left over is main_log's history listing and the 10 log_class calls. The precise version: "a 10-commit window with no gate or chore merge cost about 0.38 s, of which about 0.31 s is the gated startup that --state also runs (state_gate and state_start)."

**Evidence:** `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1690-1703`, `scripts/build-loop.sh:1714-1717`, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p5.out

---

## Claims Requiring Attention

### Incorrect
- **Claim 53b** (`scripts/build-loop.sh:1665`): an octopus merge reads other because of the two-parent test at `:1665` (and `:1657`), not because of clean_merge. clean_merge merges only the first two parents. The outcome is right; cite the parent count for octopus.

### Mostly Accurate
- **Claim 56** (`scripts/build-loop.sh:1690-1703`): about 0.38 s for N=10 holds. "Mostly state_start" should read "mostly the gated startup (state_gate and state_start)", and the measured window had no gate or chore merges.

## Goal-Alignment Note
These verdicts test whether the critics' endorsements of `--main-log`'s fail-closed classification and its per-iteration cost hold. Both security endorsements hold in outcome; one names the wrong guard. Both performance endorsements hold numerically on this host.
