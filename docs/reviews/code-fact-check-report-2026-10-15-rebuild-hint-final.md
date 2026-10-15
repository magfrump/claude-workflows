# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-rebuild-hint, branch fix/rebuild-hint-recreate)
**Scope:** `git diff 9660d4f6..2463017f` (whole unit, final confirming pass) plus the three commit bodies and the two override-log rows the branch appends
**Checked:** 2026-10-15
**Commit:** 2463017f
**Replication:** k=3
**Total claims checked:** 12 merged clusters requiring attention, plus the Verified clusters summarized under Verdict stability (replicates: r1 33, r2 37, r3 43 claims)
**Summary:** merged most-severe-wins: 2 incorrect (commit bodies, immutable history), 9 mostly accurate, 1 unverifiable, 0 stale; every other cluster Verified in all reporting replicates

Merged by the orchestrator from `code-fact-check-report-2026-10-15-rebuild-hint-final-r1.md`, `-r2.md`, `-r3.md` (all `Commit: 2463017f`). Collation only: verdicts, evidence and annotations are the replicates'. Each replicate ran the suites on a `git archive` copy (290/290 at HEAD) and ran the regression tests against the 9660d4f6 and 980a9db4 scripts; their logs are under `/home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-final-r{1,2,3}/`.

---

## Claim 1: 980a9db4 Notes: C4 "is deferred with a revisit trigger in the rubric and override log"

**Location:** commit 980a9db4 body, Notes
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Incorrect · r3=— · single-replicate detection
**Replicate annotations:** r2: "Commit 2463017f made the statement true but doesn't say it corrects 980a9db4. Commit bodies can't be changed, so this needs an Accepted-immutable note."
**Scope:** Covers the rubric and override log as of 980a9db4; does not judge 2463017f, where both records exist.

At 980a9db4 the rubric's C4 row read "🟢 Open" and `docs/reviews/override-log.md` had no row for it; the row was added in 2463017f.

**Evidence:** `git show 980a9db4:docs/reviews/code-review-rubric-2026-10-15-fix-rebuild-hint-recreate.md` (C4 row), `git show 980a9db4:docs/reviews/override-log.md` (no `fix/rebuild-hint-recreate` row)

---

## Claim 2: cb56299c Notes: the guide row quotes "Blessed config changed ... rebuilding it." verbatim; the one-time recreate is because init-firewall.sh is baked

**Location:** commit cb56299c body, Notes
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "980a9db4's A4 paragraph already corrects both."
**Scope:** Covers the quoted guide row and the recreate trigger; immutable history.

`guides/cc-isolated-usage.md:956` quotes the line only up to "rebuilding"; the recreate is triggered by the blessed-hash change at `cc-isolated.sh:904-907`.

**Evidence:** `guides/cc-isolated-usage.md:956`, `devcontainer-config/cc-isolated.sh:904-907`

---

## Claim 3: The printed recipe recovers from every rebuild_hint caller

**Location:** `devcontainer-config/cc-isolated.sh:676-677`, `:690-691`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "for an image-provenance or config-identity failure on a plain launch, the recipe is a safe retry, not a recovery" · r2: "I ran a plain launch whose image keeps a stale hash. The launch already does `devcontainer up --remove-existing-container`, then prints the config-identity hint, whose step 1 repeats that same recreate." · r3: "when the build itself is wrong ... the launch has already recreated on the hash mismatch at cc-isolated.sh:904-906, so its provenance and identity hints loop the same way."
**Scope:** Covers the init-firewall caller (recovers) and the two probe_boundary callers reached from a plain launch; pre-existing, the deferred C4 limitation.

Correct for a fail-closed or stale container. When the build itself is wrong, the plain launch has already recreated, so the recipe repeats the recreate. Not a regression.

**Evidence:** `devcontainer-config/cc-isolated.sh:665-693`, `:894`, `:904-907`

---

## Claim 4: Override-log C4 row limits the loop to "inside a `--probe-only` run" and cites `:670-689`

**Location:** `docs/reviews/override-log.md:847`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1: "uses 980a9db4's line numbers. At HEAD the blocks are `:665-693`" · r2: "Its cited range, :670-689, stops before the config-identity hint at :690-691." · r3: "It also happens from a plain launch ... The row should say so."
**Scope:** Covers the row's scope sentence, revisit trigger and line range.

**Evidence:** `docs/reviews/override-log.md:847`, `devcontainer-config/cc-isolated.sh:665-693`

---

## Claim 5: Test comment: step 2 launches the stray word "if that word names a git repo in the cwd"

**Location:** `test/cc-isolated-functions.bats:355-359`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: any directory of that name inside a git work tree resolves to that tree's top level (ran `resolve_workspace`, `cc-isolated.sh:357-370`); r2: "which can be the cwd's own repo".
**Scope:** Covers resolve_workspace's handling of the stray positional.

**Evidence:** `devcontainer-config/cc-isolated.sh:357-370`, `test/cc-isolated-functions.bats:355-359`

---

## Claim 6: Commit bodies 980a9db4 A1 / 2463017f A5 on the zsh outcome

**Location:** commit 980a9db4 body (A1), commit 2463017f body (A5)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: 2463017f's "otherwise step 2 errors out" is false when `./launches` is a plain directory inside a git work tree; 980a9db4's "retargeted to ./launches" overstated, corrected by 2463017f.
**Scope:** Immutable history; same mechanism as Claim 5.

**Evidence:** `devcontainer-config/cc-isolated.sh:357-370`

---

## Claim 7: Test comment says the --probe-only fail-case test checks it "never start[s] claude"

**Location:** `test/cc-isolated-functions.bats:1427-1428`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2+r3: the assertion was removed in 2463017f; the property still holds because the probe branch never runs claude.
**Scope:** Covers the comment against the test body.

**Evidence:** `test/cc-isolated-functions.bats:1427-1440`, `devcontainer-config/cc-isolated.sh:891-896`

---

## Claim 8: 980a9db4 A2: "The fail-closed launch test asserts it"

**Location:** commit 980a9db4 body (A2)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** r3: "It checks only that the old NOTE wording is absent (:1406-1408), not that the new wording is present."
**Scope:** Covers the test's assertions on the NOTE.

**Evidence:** `test/cc-isolated-functions.bats:1406-1408`

---

## Claim 9: 980a9db4 Notes: the "rebuilding it." line is matched by a guide row and a test

**Location:** commit 980a9db4 body, Notes
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** r3: "the test at :1360 stops before 'rebuilding', so only the guide row (:956) pins that word."
**Scope:** Covers the guide row and the test pattern.

**Evidence:** `test/cc-isolated-functions.bats:1360`, `guides/cc-isolated-usage.md:956`

---

## Claim 10: 980a9db4 C1 calls the bless "Next:" line the `--list` line

**Location:** commit 980a9db4 body (C1)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2+r3: already corrected by 2463017f's A6, which is right (the line is in `bless_manifest`).
**Scope:** Immutable history, already corrected.

**Evidence:** `devcontainer-config/cc-isolated.sh:317-318`

---

## Claim 11: `--help`'s --probe-only line: "record it verified live"

**Location:** `devcontainer-config/cc-isolated.sh:13-15`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: "drops 'on a pass', which the guide at `:25-26` keeps. This was already missing before the branch; the diff only rewrapped the line."
**Scope:** Covers the help text against record_verified_live's call site.

**Evidence:** `devcontainer-config/cc-isolated.sh:13-15`, `guides/cc-isolated-usage.md:25-26`

---

## Claim 12: init-firewall test comment: "--probe-only recreates the container (cached image layers are reused)"

**Location:** `test/init-firewall-rules.bats:1491`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1+r2+r3: depends on Docker and the devcontainer CLI; no Docker in the sandbox; needs a host `--probe-only` run with build output.
**Scope:** No blocking-grade failure mode attached (a comment).

**Evidence:** `test/init-firewall-rules.bats:1491`

---

## Submitted Claims

Stage 2.5 (k=1, opus): `code-fact-check-submitted-claims-2026-10-15-rebuild-hint.md`, `Commit: 2463017f`. Four security-reviewer endorsement claims, numbered 13-16 there, all **Verified**, verification mode **executed**: 13 the printed recipe's `printf %q` path re-parses identically in bash and zsh (space, `$(...)`, newline, `!`); 14 `--probe-only` exits non-zero and writes no receipt on a failed probe (mutant `probe_boundary || true` caught by the test); 15 only comment and echo lines changed in either enforcement script (48 lines read); 16 a plain launch on a fail-closed container does not recreate, does not start claude, exits non-zero and prints the two-step hint (old hint restored → test fails). Scope lines are in that report.

## Escalations

- `docs/reviews/override-log.md:847` (r1, r2, r3) → orchestrator: widen the C4 row to plain launches and fix its line range (Claims 3, 4).
- commit 980a9db4 Notes (r2) → orchestrator: Accepted-immutable row for Claim 1.
- `test/init-firewall-rules.bats:1491` (r1, r2, r3) → orchestrator: the cached-layer claim needs a host check or rewording (Claim 12).

## Verdict stability

Clusters requiring attention: 12. All reporting replicates agreed on 9 (Claims 1, 3-12 where reported; Claims 1, 8, 9, 11 are single-replicate detections). Disagreed: Claim 2 (r1=Mostly accurate · r2=Incorrect · r3=Mostly accurate). Every other cluster (the rebuild_hint comments, the fail-closed recipe and its caller, the NOTE, header and bless lines, init-firewall's recipe and comments, the four guide lines, the regression-test claims, the "no non-comment/non-echo change" claim, the install.sh override row) was Verified by every replicate that reported it. Agreement on clusters reported by 2+ replicates: 7 of 8 (88%).

## Goal-Alignment Note
- Success criterion (restated verbatim): a code-fact-check report saved at the path below, structured per the skill, verdicting at least the claims listed above.
- Answered: yes — merged from three replicates, all seven claim groups covered.
- Out of scope: real Docker behaviour (cached layers, a stopped container's restart); host install, bless and probe.
- Escalate: see Escalations.
