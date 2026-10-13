Commit: 5583a2cd
Loop closed at 5583a2cd
Loop-pass short-circuit: used at 7a927183

# Code Review Rubric: feat/build-loop-u3b3 (U3b3, git_harden and the D6 snippet)

**Iteration 1 of 3** · scope: full branch `main...7a927183` (no prior rubric for this loop) · delivery mode: self-read (shared brief plus the saved diff) · fact-check k=1 (loop pass, decision 031), opus · report `docs/reviews/code-fact-check-report-2026-10-12-u3b3-i1.md` (48 claims: 37 Verified, 4 Mostly Accurate, 1 Stale, 3 Incorrect, 3 Unverifiable)

Loop-pass short-circuit: behavioural 🔴 confirmed at fact-check (claim: the snippet "trusts no file the uid can write"; executed probe P3 ran a planted build-loop.sh). Critics skipped this pass; the loop's one short-circuit is now used, so iteration 2 runs the full panel. No enforcement file in the diff (mechanic 7 does not apply).

Status (iteration 1): 🔴 1 · 🟡 1 · 🟢 5, all fixed in the iteration-1 fix commit (unreviewed until iteration 2). Single-sample review; absence of findings is not an attestation.

## 🔴 Must Fix

| ID | Finding | Source | Evidence | Status |
|---|---|---|---|---|
| A1 | The snippet hash-checks the four blobs against ids read from main's trees but never re-hashes the commit or trees: an in-place rewrite of the loose `scripts` tree object (main's ref unchanged) points ls-tree at planted blob ids, and the snippet runs the planted build-loop.sh (exit 0). store_check, which would catch it, runs inside the script the snippet already chose. The root-commit identity has the same gap: an in-place rewrite of a first-parent commit can make a non-claude-workflows repo's chain end at 640cf007 | fact-check claim (Incorrect, executed P3) | `test/lib/d6-snippet.bash` ls-tree / hash-object loop; header lines 10-14 | Fixed (main's first-parent commits and the trees down to scripts/lib/ re-hashed in one cat-file --batch pass; two tests, the tree one killed by a mutant that drops the check) |

## 🟡 Must Address

| ID | Finding | Source | Evidence | Status |
|---|---|---|---|---|
| A2 | The as-built note says the default branch must be "a commit", but the snippet peels `refs/heads/$m^{commit}`: a main naming an annotated tag passes, and dev-cycle.sh (which runs no default_gate) then runs through it (executed P4) | fact-check claim (Incorrect, behavioural vs doc) | `test/lib/d6-snippet.bash` sha line; plan note | Fixed (the ref's own object must be a commit; T36 case) |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| A3 | Header says "T33 asserts the two match"; T33 has only a pending comment until U4 | fact-check (Incorrect, comment) | Fixed (header: pending until U4) |
| A4 | `build-loop-orchestrator.bats:50` still says "a count harden would misread" | fact-check (Stale) | Fixed |
| A5 | "a bash script body, not a function" (the file defines and calls `d6()`; what holds is that no function lands in the caller's shell) | fact-check (Mostly Accurate) | Fixed (plan note, header); commit a0014ce5 message immutable, left as is |
| A6 | "Every git call ... runs hardened" (build-loop.sh, lib header) omits the two deliberate exceptions: caller_gate's caller-count read and merge_ident's CALLER_GLOBAL | fact-check (Mostly Accurate) | Fixed (both comments name the two exceptions) |
| A7 | The snippet's Exit list omits the "names no commit" refusal and the failed-read / temp-dir refusals | fact-check (Mostly Accurate) | Fixed (Exit list) |

Unverifiable (no action): the zsh alias incident (session transcript), "refuses when run as root" (needs uid 0), the safe.directory note (needs another uid's repo).

## ⏭️ Skipped Core Critics

| Critic | Reason |
|---|---|
| security-reviewer | loop-pass short-circuit (behavioral red confirmed) |
| performance-reviewer | loop-pass short-circuit (behavioral red confirmed) |
| api-consistency-reviewer | loop-pass short-circuit (behavioral red confirmed) |
| architecture-review | loop-pass short-circuit (behavioral red confirmed) |

## 🧩 Composition check

No multi-source co-located clusters qualified (one source this pass).

## Considered overrides

Rows 200, 281, 311, 495, 505, 644, 648, 666, 702, 704, 709 (keyed to this unit; the plan's as-built note discharges or closes them), 509 and 548 (Q-103 residuals). A1 is not covered by any: row 509 is a race on the gate's own temp dir, and the U3a1 rows treat in-place rewrites only behind store_check's re-hash, which the snippet runs before.

## Iteration 2 (full branch `main...5d175c0e`, loop pass, k=1, full panel)

Scope: full branch rather than the delta, since the critics had not yet run on this loop (i1 short-circuited). Fact-check `docs/reviews/code-fact-check-report-2026-10-12-u3b3-i2.md`: 57 claims, 49 Verified, 5 Mostly Accurate, 0 Incorrect, 0 Stale, 3 Unverifiable; two escalations to security. Critics (opus, parallel): security (`security-review-2026-10-12-u3b3-i2.md`; the first run was stopped by a safety classifier mid-report with no findings, its partial file deleted, and the review re-run with a design-only framing), performance, api-consistency, architecture (`*-2026-10-12-u3b3-i2.md`). Dispatch mode: parallel.

**Divergence detection fired: B1 is A1 re-firing.** A1 (i1) said the snippet ran planted bytes after an in-place object rewrite; d9515d09 re-hashed the commits and trees through one `cat-file --batch`. B1 (i2): with two packs, the separate rev-list / rev-parse / ls-tree readers can read a different copy of an id than the re-hash did, so planted bytes still ran (executed). Deeper read: the snippet verified some objects but used ids and bytes other processes read; any check-then-read design keeps the gap. Interim (/away; the user may choose otherwise): the structural fix, a single perl reader over one `cat-file --batch` that uses only bytes it has hashed and takes every next id from them (commits to the root, trees, the four files). The sec2/sec3 two-pack probe re-run against it runs main's real scripts.

| ID | Finding | Tier | Source | Status |
|---|---|---|---|---|
| B1 | A second packed copy of an id lets ls-tree name planted blobs that the re-hash never saw (A1 re-fired) | 🔴 (High, executed) | security F1 | Fixed (verified reader; probe re-run clean; T36 rewrite tests and T33's tampered-stream case) |
| B2 | A failed root-check rev-list (missing commit) or a shallow clone fell to the /opt copy with exit 0 instead of refusing | 🟡 (Medium, executed) | security F2; fact-check escalation 1, claims 7, 33 | Fixed (any read failure refuses; test with a missing commit and a shallow clone; mutant killed) |
| B3 | A moved refs/heads/main passes every hash check | 🟡 (escalated) | fact-check escalation 2; security R1 | Won't-Fix (row: F19's hostile-loop class, rows 509, 721); header states it |
| B4 | --state's header listed six HARDEN keys; caller_gate refuses eight | 🟡 (Inconsistent) | api-consistency F1 | Fixed (header names HARDEN and its eight keys) |
| B5 | Header overclaims: "runs no file the uid can write", "every object ... hashes", the Exit list | 🟢 | security F3; fact-check claims 30c, 33 | Fixed (header rewritten) |
| B6 | The lib's "state gate refuses" holds for build-loop.sh's gated modes only | 🟢 | fact-check claim 26; security R3 (row 548) | Fixed (comment) |
| B7 | Test name said "a tree above scripts/" for the scripts tree itself | 🟢 | fact-check claim 43 | Fixed |
| B8 | git_harden must run once per process but did not enforce it | 🟢 (Minor) | architecture F4 | Fixed (second call returns; pinned in the environment test) |
| B9 | Two tests listed HARDEN's keys by hand | 🟢 (Minor) | architecture F2 | Fixed (both loop over the lib's HARDEN) |
| B10 | The snippet's re-hash is a narrower store_check, neither naming the other | 🟢 (Minor) | architecture F3 | Fixed (cross-reference comments; the verified reader needs no second-copy rule) |
| B11 | Root check and re-hash walked history twice (~35 ms, linear) | 🟢 (Low) | performance F1 | Fixed (one walk; but per-request round trips made the one walk slower: 63 ms vs 30 ms, final performance F1, row) |
| B12 | dev-cycle.sh's header did not say its git reads no user/system config or transport | 🟢 (Minor) | api-consistency F4 | Fixed (header) |
| B13 | The snippet's checks repeat the gate's without saying so | 🟢 | architecture F5 | Fixed (header: before, not instead of) |
| B14 | `refuse d6:` can precede any mode's output | 🟢 (Minor) | api-consistency F2 | Defer (row; U4 hand-off in the plan note) |
| B15 | Row 704's premise (git_harden as the orchestrator's wrapper) no longer holds | 🟢 (Minor) | api-consistency F3, architecture F1 | Defer (row amends 704's trigger; U4) |
| B16 | Fork overhead ~70 ms per call | 🟢 (Info) | performance F2 | Won't-Fix (row) |
| B17 | SHA-1 with no collision detection | 🟢 (Info) | security F4 | Won't-Fix (row) |
| B18 | Opposite -c / count-pair precedence between the snippet and git_harden | 🟢 (Info) | api-consistency F5 | Won't-Fix (row) |
| B19 | Canonical snippet copy in test/lib/ | 🟢 (Info) | architecture F6, api-consistency F6 | Defer (row; U4) |

Re-flagged settled decisions (no action — see override-log): the extracted copy's temp-dir race (rows 200, 509; security R2); dev-cycle.sh runs no state gate (row 548; security R3, fact-check claim 26's residue).

Endorsements routed (`route: code-fact-check`): the own() walk; dev-cycle.sh calls git_harden before any git call. Pending execution verification (Stage 2.5 runs on the final pass). Performance: hardening made no measurable difference to the digest (unverified, submitted).

Composition check: one qualifying cluster, `test/lib/d6-snippet.bash:44-55` (security F1, F2; performance F1; architecture F3; fact-check escalations): composed as B1's root, "the snippet decides what runs from readers it did not verify; read and verify in one process" (fixed as above). Others: distinct defects (text-only rows).

## Final confirming pass (full branch `main...5583a2cd`, k=3, full panel, Stage 2.5)

Fact-check merged `docs/reviews/code-fact-check-report-2026-10-12-u3b3-final.md` (replicates r1-r3): 95 clusters, 80 Verified, 8 Mostly Accurate, 1 Stale, 2 Incorrect (both doc/commit text, unanimous), 4 Unverifiable; agreement 94.7%. No behavioural Incorrect. Critics (opus, parallel): security (1 Medium), performance (1 Low), api-consistency (1 Minor, 1 Info), architecture (1 Coupling, 2 Minor, 1 Info). Dispatch mode: parallel. Stage 2.5 `docs/reviews/code-fact-check-submitted-claims-2026-10-12-u3b3-final.md`: 9 submitted endorsement claims (security 5, performance 4), all Verified, executed (claim 96 included the critic's untested layout: a forged packed copy beside a real loose one refuses). Single-sample review; absence of findings is not an attestation.

| ID | Finding | Tier | Source | Status |
|---|---|---|---|---|
| C1 | The snippet picks main's copy from the repository's own data: in another project, a moved main onto a copy of D6_ROOT (a) or a rewritten `.git` entry (c; also in claude-workflows, unseen by --main-log) runs that project's scripts instead of the image copy | 🟡 (Medium; Coupling) | security F1, architecture F1, fact-check E1/E6 | Defer (row; **Q-140**, you: judgment); header and plan note name the gap |
| C2 | Route (b): the reader followed a late `parent` header line that git ignores | 🟡 (Medium) | security F1 b, architecture F1, fact-check E5 | Fixed (first parent only directly after the tree line; test; old regex killed) |
| C3 | The reader ran with the caller's PERL5LIB / PERL5OPT / PERL_UNICODE / PERLIO | 🟢 | api-consistency F2, architecture F4 | Fixed (env -u) |
| C4 | "each comment names the other": the snippet never named store_check | 🟡 (Incorrect, doc) | fact-check claims 26b, 89 (unanimous) | Fixed (the reader's comment names store_check; commit c9648432 immutable) |
| C5 | Stale "git names the mismatch on stderr too" | 🟢 | fact-check claim 68 | Fixed |
| C6 | Gates scope, "status 255", "trees above scripts/lib/", "never reads the working tree" | 🟢 | fact-check claims 13b, 53, 55, 57; security F1 c | Fixed (text) |
| C7 | `refuse d6:` also covers environmental failures; the hand-off called it planted state | 🟢 (Minor) | api-consistency F1 | Defer (row; plan hand-off reworded) |
| C8 | One request per commit: slower walk, full walk outside claude-workflows on every call | 🟢 (Low) | performance F1 | Defer (row; Q-140 / U4 / ~30k commits) |
| C9 | No direct test seam for the perl reader | 🟢 (Minor) | architecture F2 | Defer (row; U4) |
| C10 | Row 734's "~70 ms fixed" | 🟢 (Mostly Accurate) | fact-check claim 3a | Won't-Fix (correction row appended) |
| C11 | No timeout on a hung git or perl | 🟢 (Info) | Stage 2.5 note | Defer (row; U4) |

Fix commits after the pass: 2e51450e (C2-C6, C7's text), 42022ab1 (fix-drift wording); unreviewed by a full pass; lite fix-drift: one finding, fixed in 42022ab1. Suites 286/286 at 2e51450e. Exit: no Must Fix; the one open Must Address (C1) carries a revisit trigger (Q-140), so the loop exits under "ship with documented known issues" in 3 iterations, with divergence detection fired once (i2, B1 = A1).

Re-flagged settled decisions (no action — see override-log): row 548 (dev-cycle.sh runs no state gate; claims 13b, 53); rows 200/509 (temp-dir race); this branch's moved-main row (claude-workflows case of C1).

Composition check: one qualifying cluster, `test/lib/d6-snippet.bash:55-86` (security F1, architecture F1, performance F1, fact-check E1/E5/E6, api F2): composed as C1's root, "what the snippet trusts is chosen from inside the repository it judges"; routed to Q-140. Others: distinct defects.

Considered overrides: rows 200, 281, 311, 495, 505, 644, 648, 666, 702, 704, 709 (this unit's), 509, 548, 721, and this branch's rows dated 2026-10-12.
