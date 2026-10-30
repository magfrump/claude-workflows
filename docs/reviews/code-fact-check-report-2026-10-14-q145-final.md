# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-q145`, branch `fix/q145-ancestor-vanish`)
**Scope:** `main...HEAD` at 29b807dc (code, tests, docs/thoughts; docs/reviews excluded), final confirming pass
**Checked:** 2026-10-14
**Total claims checked:** 26 clusters (replicates: r1 26, r2 23, r3 27 claims)
**Summary:** 18 Verified, 5 Mostly accurate, 0 Stale, 1 Incorrect (immutable commit message), 2 Unverifiable
**Commit:** 29b807dc
**Replication:** k=3

Merged most-severe-wins from `code-fact-check-report-2026-10-14-q145-final-r1.md`, `-r2.md`, `-r3.md` (all `Commit: 29b807dc`). Only the non-Verified clusters carry full sections; the Verified clusters are listed in the table after them with their replicate verdicts. Fixes for every comment finding below landed in c4bab9ca (narrow check: `code-fact-check-report-2026-10-14-q145-narrow.md`).

## Claim 1: ba5d2d1d subject and body: vanished entries are skipped; -ignore_readdir_race skips only an ENOENT on any name readdir returned

**Location:** commit ba5d2d1d message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Evidence:** findutils 4.9.0 with `-ignore_readdir_race` still reports a directory that vanished between readdir and stat (exit 1); corrected in history by d2dc88c9 and handled by the retry.
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate (compound, claim 20) · r3=Incorrect
**Replicate annotations:** r3: "only matters if the branch is squashed; with a merge commit it stays in history as written"
**Scope:** establishes the commit text is wrong about directories; does not establish any defect in the code at HEAD.
**Legibility-target:** for-author

## Claim 2: ba5d2d1d body "config_seeds lists every ancestor of each reader root"

**Location:** commit ba5d2d1d message
**Type:** Descriptive
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** only ancestors below no reader root are tops; 0d573a7b fixed the code comment.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=—
**Replicate annotations:** none
**Scope:** history only.
**Legibility-target:** for-author

## Claim 3: config_seeds header "(an entry that vanishes mid-listing fails one)"

**Location:** `scripts/lib/dev-cycle-read.sh:1509-1510`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** only a vanished directory fails a try; a vanished file is skipped (shim log `0`).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** none
**Scope:** wording; return contract otherwise Verified.
**Legibility-target:** for-author

## Claim 4: listing comment "a transient one of any kind is retried away, its message dropped"

**Location:** `scripts/lib/dev-cycle-read.sh:1555-1556`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** holds only when a later try is clean; three transient failures in a row fail the walk, the third message shown.
**Replicate verdicts:** r1=Verified (compound, claim 7) · r2=Mostly accurate · r3=Verified (compound, claim 8)
**Replicate annotations:** none
**Scope:** wording.
**Legibility-target:** for-author

## Claim 5: "before Q-145 such a gap failed the walk only when it fell between find's readdir and its stat"

**Location:** `scripts/lib/dev-cycle-read.sh:1560-1561`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** main failed when the delete-and-re-create gap was still open at find's stat of a readdir-returned name; a gap wholly between readdir and stat caused no error; one spanning readdir was missed silently.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound, claim 8) · r3=Mostly accurate
**Replicate annotations:** r3: "the one with security weight ... the comment does disclose the skip ('or now skips'), so this is wording, but the security critic may want to confirm the trade is accepted"
**Scope:** wording; the skip itself is disclosed and was accepted in iteration 2 (override row, security F1).
**Legibility-target:** for-author

## Claim 6: walk header "a name no longer there holds nothing to load"

**Location:** `scripts/lib/dev-cycle-read.sh:828-832`
**Type:** Descriptive
**Verdict:** Mostly accurate
**Confidence:** Medium
**Evidence:** omits the delete-and-re-create case, which only config_seeds' comment covers.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** none
**Scope:** wording.
**Legibility-target:** for-author

## Claim 7: test comment "a clause that runs at the first entry of the fixture's ancestor"

**Location:** `test/scripts/build-loop-check.bats:725-727`
**Type:** Descriptive
**Verdict:** Mostly accurate
**Confidence:** High
**Evidence:** the clause runs at every entry under the ancestor (and at `$a/.claude`); the first run is the one that deletes.
**Replicate verdicts:** r1=Verified (claim 13) · r2=Mostly accurate · r3=Mostly accurate (claim 14)
**Replicate annotations:** none
**Scope:** wording.
**Legibility-target:** for-author

## Claim 8: top_files "It fails, with NAME empty, when ... a DIR is no longer a directory"

**Location:** `scripts/lib/dev-cycle-read.sh` top_files
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Evidence:** executed; but r3's mutant (recheck returns 1 without emptying NAME) survived the tests: the "with NAME empty" half was unpinned. A unit test pinning it landed in c4bab9ca.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "One survives: a recheck that returns 1 without emptying NAME. That is harmless, because config_seeds throws fl away on failure, but the 'with NAME empty' half of top_files' header is not pinned by any test."
**Scope:** behaviour verified by execution; test coverage gap noted.
**Legibility-target:** for-orchestrator-synthesis

## Claim 9: unverifiable figures

**Location:** commits ba5d2d1d (968, 1059/1061), d2dc88c9 ("2 of ~240"), b9f1d2d1 ("Affected suites 238/238")
**Type:** Historical
**Verdict:** Unverifiable
**Confidence:** Medium
**Evidence:** replicates were limited to the Q-145 filter; the run logs are in the author's scratch dir (`suites.log`, `suites3.log`).
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r2 (i2): `suites.log` shows the find message for test 43 only
**Scope:** none.
**Legibility-target:** for-orchestrator-synthesis

## Verified clusters

| Cluster | r1 | r2 | r3 |
|---|---|---|---|
| FP-173 entry (vocabulary, ref d2dc88c9) | V | V | V |
| Walk header: exception, error-free listing, persisting errors fail | V | V | V |
| config_seeds return contract (three tries) | V | V | V |
| "Each ancestor below no reader root is a top"; ENOENT exits 1 | V | V | V |
| findutils 4.9: vanished file skipped, vanished directory reported | V | V | V |
| first two tries' stderr dropped; `2>/dev/null` binds per call | V | V | V |
| only an error-free listing is used; retry hides no existing file | V | V | V |
| "Not covered" list (rename-in; delete-and-re-create) | V | V | V |
| top_files header: files/links, linked DIR at depth 0 | V | V | V |
| vanished file skipped (-ignore_readdir_race) | V | V | V |
| shim: -H listing only; names read before the first visit | V | V | V |
| SHIM_ONCE / SHIM_RMTOP semantics | V | V | V |
| test assertions `0`, `1 0`, `1 1 1`, `0 0 0` | V | V | V |
| test fails against main and mutants | V | — | V |
| ba5d2d1d probe list (permission, loop, missing start, dangling link) | V | V | V |
| d2dc88c9 findutils claims (incl. stat-to-xtype window) | V | V | V |
| b9f1d2d1 recheck move | V | V | V |
| 0d573a7b / 29b807dc claims | V | V | V |

## Escalations

- `scripts/lib/dev-cycle-read.sh:1560-1561` (r3, addressee security-reviewer): confirm the delete-and-re-create trade is accepted. Routed to the final security critic.

## Verdict stability

26 clusters; 19 all replicates agreed; 7 disagreed (Claims 1, 2, 4, 5, 6, 7 above, and the mutant-run cluster that r2 did not surface as its own claim). Agreement 19/26 = 73%. Disagreements were compound-versus-atomic splits or single-replicate wording catches; none split Verified against Incorrect on code.
