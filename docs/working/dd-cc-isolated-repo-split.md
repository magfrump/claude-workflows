# DD working doc — should cc-isolated be its own repository?

**Goal**: Decide whether the cc-isolated sandbox setup should be extracted from the
claude-workflows repo into its own repository, and if so on what seam.
**Project state**: standalone decision on `main`, prompted by the 2026-09-17 `scholar`
egress work · not part of a larger initiative · not blocked.
**Task status**: complete (Path A — [0] status quo; record at docs/decisions/036-cc-isolated-repo-split.md)

---

## Step 1.0 — Pre-generation grep (carry forward prior pruning)

    grep -B 1 -A 20 "Pruned candidates" docs/decisions/*.md | rg -i "repo|split|payload|submodule|vendor|monorepo"

**Prior pruning grep: matches found for [repo, split, payload, submodule, vendor, monorepo].**
Three hits, all load-bearing here:

- **016 [2] vendor-per-repo** — runner-up, declined: the launcher and firewall script
  would sit inside a repo the agent can write (H2), and maintenance becomes recurring
  and per-repo. The *Push to extreme* move (20 projects → 20 drifting copies of
  `init-firewall.sh`) was decisive.
- **016 [6] template generator / [13] git submodule** — "both are [2] with a
  propagation mechanism bolted on; they inherit [2]'s H2 hole while adding machinery."
  **Carried forward** against candidate [3] below: a submodule is exactly the
  propagation mechanism 016 already rejected, and nothing about the present question
  changes the objection, because the submodule would still be a checkout the same
  host session can rewrite before `install.sh` reads it.
- **035 [7] move the installer off the repo** — "the strongest principle in the field
  and the only true closure, declined because it is unverifiable from this sandbox and
  **splits the committed-canonical-config property** into two trust regimes." **Partly
  revived**: 035 was asking whether the *installer* should leave any agent-writable
  repo, which a two-repo split does not achieve (both repos stay agent-writable on the
  host). The half that survives is the objection itself — a split must not turn one
  committed-canonical-config property into two — and it becomes hard constraint H2
  below rather than a candidate.

## Step 1 — Diverge (15 candidates)

Lenses represented: technical (2, 3, 4, 8, 9, 11), interface (11, 14), procedural (6,
12, 15), social/organizational (5, 15), time-shifted (12), reframe (0, 10, 13, 14).

0. **Status quo** — one repo; `install.sh` assembles the payload with `cp -r` from
   seven repo-root paths at install time (decisions 022/023).
1. **Do nothing, document it** — add a "why these live together" note to
   `guides/devcontainer-setup.md` and stop wondering.
2. **Split; payload by path** — cc-isolated becomes its own repo; its `install.sh`
   takes `--payload <path>` (default: a sibling `claude-workflows` checkout).
3. **Split; payload by git submodule** — cc-isolated vendors claude-workflows at a
   pinned commit.
4. **Split; payload by pinned artifact** — claude-workflows emits `claude-home.tar.gz`
   + sha256; cc-isolated pins the hash and verifies before staging.
5. **Split by mirroring** — development stays in claude-workflows; `devcontainer-config/`
   is published read-only to a second repo via subtree, for distribution only.
6. **Ownership convention, no split** — a `docs/ownership.md` naming boundary files,
   plus separate test categories, so the two sides *read* as independent.
7. **Regroup in place** — rename `devcontainer-config/` → `cc-isolated/`, move its five
   test suites under `cc-isolated/test/`, and give it its own `run-tests` target. One
   repo, two clearly separated trees.
8. **Three repos** — cc-isolated, claude-workflows, and a `payload-contract` repo
   defining what the image expects of the payload.
9. **Ideal if effort were free** — claude-workflows publishes a versioned npm package;
   the Dockerfile installs it at a pinned version and `cp -r` disappears entirely.
10. **Naive split** — `git mv` the directory into a new repo, delete it here, let
    `install.sh` fail loudly until someone fixes the paths.
11. **Extract the payload seam (reframe)** — the coupling *is* the payload, so move
    payload assembly out of `install.sh` into claude-workflows itself (`make payload`
    emits `claude-home/` + `.manifest`); cc-isolated consumes an already-assembled
    directory and no longer knows the seven source paths.
12. **Seam first, split behind a trigger (time-shifted)** — do [11] now, defer the
    repo split until a named trigger fires.
13. **Worktree lanes, no split** — one repo, but each side developed in its own git
    worktree so branch lanes never interleave.
14. **Split and drop the payload** — cc-isolated stops shipping skills/workflows;
    sessions bind-mount a workflows checkout instead.
15. **Social rule only** — keep one repo; the live-verify trailer stays the single
    coupling ritual and nothing else changes.

**Generation health check.** Clustering flagged: [2] [3] [4] [9] are four variants of
"split, then pin the payload somehow" — one region of the space (dimension: *how the
payload crosses the repo boundary*). Named the shared assumption ("the split is the
thing; the seam is an implementation detail") and generated [11] [12] [5] [14], which
move on a different dimension (*where payload assembly lives*, *which direction the
dependency points*, *whether a payload exists at all*). Do-nothing present ([0] [1]);
naive present ([10]); ideal-if-free present ([9]). No vague candidates — each names a
concrete mechanism.

## Step 2 — Diagnose (9 constraints: 5 hard · 4 soft)

**H1 — Payload provenance stays checkable.** The image must never ship a payload whose
source commit is unknown.
`success: /opt/claude-workflows/.manifest names a commit that resolves in the payload
source repo (git cat-file -e), and install.sh exits 1 rather than staging a payload it
cannot stamp.`

**H2 — One canonical-config property, not two.** The split must not create a second
trust regime for boundary config (035 [7]'s objection, carried).
`success: exactly one repo's committed tree is hashed by enforcement_files() and blessed
by cc-isolated --bless; grep of the new layout finds no second blessable config tree,
and the pre-bless [y/N] diff still shows the assembled payload bytes.`

**H3 — The live-verify gate keeps gating.** A commit touching
`Dockerfile` / `init-firewall.sh` / `cc-sni-proxy.py` / `egress/` / `cc-isolated.sh` /
`link-claude-home.sh` / `devcontainer.json` / `install.sh` must still be blocked without a
`Live-verified:` trailer.
`success: test/hooks/live-verify-gate.bats passes unchanged against the post-change paths,
and a trial commit touching an egress file without the trailer exits non-zero.`

**H4 — One test command per side, no cross-repo path dependency.** The five boundary
suites (`init-firewall-rules`, `cc-isolated-functions`, `link-claude-home-wiring`,
`hooks/live-verify-gate`, `test_cc_sni_proxy.py`) plus `test/lib/hermetic-env.bash` must
run from their own tree.
`success: each side's run-tests entrypoint exits 0 from a fresh clone of that repo alone,
with no ../ path escaping the repo root (grep the suites for '\.\./\.\.').`

**H5 — No silent drift between repo state and image state.** A missing or stale payload
source must fail loudly, as it does today.
`success: install.sh exits 1 naming every missing payload source (the behavior added in
cb3e/"fail the payload assembly on a missing source"), and the staged claude-home/ appears
in the pre-bless diff.`

**S1 — Reduce cross-side review and clone surface.** Measured baseline: over the last 120
days, 42 commits touched only `devcontainer-config/`, 369 touched only the other side, and
**zero touched both**. The sides already move independently; the gain on offer is smaller
clones and narrower review scope, not unblocking anything.

**S2 — No two code paths / two trust regimes** (carried from 016 [4] and 035 S2).

**S3 — Cheap and reversible.** Prefer ≤ a day of work with an obvious undo.

**S4 — Cross-document links survive.** `guides/` references the cc-isolated docs from
five files, `global-instructions/CLAUDE.md` references the sandbox tool map, and
`test/cross-reference-integrity.bats` enforces that links resolve.

## Step 3 — Match and prune

| # | Approach | H1 prov | H2 one-regime | H3 gate | H4 tests | H5 drift | S1 surface | S3 cheap |
|---|----------|---------|---------------|---------|----------|----------|------------|----------|
| 0 | status quo | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| 1 | document only | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| 2 | split, payload by path | ~ | ~ | ~ | ✓ | ~ | ✓ | ~ |
| 3 | split, submodule | ✓ | ~ | ~ | ✓ | ✓ | ✓ | ✗ |
| 4 | split, pinned artifact | ✓ | ~ | ~ | ✓ | ✓ | ✓ | ✗ |
| 5 | mirror/subtree | ✓ | ✓ | ⚠ | ~ | ✓ | ~ | ~ |
| 6 | ownership convention | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| 7 | regroup in place | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ |
| 8 | three repos | ✓ | ✗ | ~ | ~ | ✓ | ~ | ✗ |
| 9 | npm package | ✓ | ~ | ✓ | ✓ | ✓ | ✓ | ✗ |
| 10 | naive split | ✗ | ~ | ~ | ✗ | ✗ | ✓ | ✓ |
| 11 | extract payload seam | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ |
| 12 | seam first, trigger | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ |
| 13 | worktree lanes | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |
| 14 | split, drop payload | ✗ | ✓ | ✓ | ✓ | ⚠ | ✓ | ✓ |
| 15 | social rule only | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ |

Discarded on the matrix:

- **[1] [6] [13] [15]** — ✗ on S1, the only thing the question is asking about. They are
  the status quo with a note attached.
- **[3]** — ✗ on S3 and carried objection from 016 [6]/[13]: a submodule is a propagation
  mechanism bolted onto a vendored copy; the pinned checkout is still a tree the same host
  session can rewrite before `install.sh` reads it, so it buys ceremony rather than
  provenance over [2].
- **[5]** — ⚠ on H3: a read-only mirror means boundary commits land in the repo where the
  gate does *not* enforce, and the mirror carries no trailer discipline at all.
- **[8]** — ✗ on H2 outright: three repos is three canonical trees.
- **[9]** — ✗ on S3, and no registry infrastructure on this single-user host; it was the
  ideal-if-free space-widener and it did its job by making the *versioned payload* idea
  visible, which [4] and [11] both inherit.
- **[10]** — ✗ on H1/H4/H5; listed to be explicit that "just move it" is not a plan.
- **[14]** — ⚠ on H5 and a direct revival of the state decision 022 was written to fix
  (a bind-mounted payload is exactly the "works only in sessions editing this repo"
  failure). Not carried.

**Survivors: [12] (with [11] absorbed), [2], [4], [7], [0].** Five, so the step-4
scorecard carries all five and the option cap applies at the consult.

Fix sketches for survivors:

- **[2]** — H1/H5 weakness is fixable by having `install.sh` stamp `.manifest` from
  `git -C <payload-path> rev-parse HEAD` and refuse a dirty or non-git payload path.
  H2 weakness is *not* fully fixable: whichever repo holds the payload, its tree is now
  an input the bless gate covers only by the diff, not by a hash.
- **[4]** — H2 weakness fixable by keeping the blessable tree in cc-isolated and treating
  the tarball hash as just another pinned ARG, the way the SDK and shfmt digests already
  work (#19 discipline).
- **[7]** — S1 is only partial by construction: one clone, narrower trees.

## Step 4 — Tradeoff matrix

| # | Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|----------|--------|------|-----------------|--------------|
| 12 | seam first, split behind trigger | ~half day | low | 5/5 | defers the thing actually asked for |
| 7 | regroup in place | ~2 hours | low | 5/5 | cosmetic; one clone still carries both |
| 2 | split, payload by path | ~1 day | med | 3/5 (H1, H5 fixable; H2 partial) | payload source becomes an unhashed input |
| 4 | split, pinned artifact | ~2 days | med | 4/5 | a release step between every workflows edit and the image |
| 0 | status quo | 0 | low | 5/5 | the measured independence stays unrewarded |

Falsifiable hypotheses:

- **[12]** — If chosen, payload assembly moves behind one `make payload` entrypoint and
  the next three boundary changes touch no claude-workflows file; counter-evidence =
  any of those three still requiring an edit under `skills/`, `workflows/` or `hooks/`,
  or the seam adding a step to `install.sh` rather than removing one.
- **[7]** — If chosen, `git log --stat` shows every commit in the next month confined to
  either `cc-isolated/` or the rest, with no reviewer confusion about scope;
  counter-evidence = a commit that has to straddle both trees for a non-doc reason.
- **[2]** — If chosen, two repos and `install.sh --payload ../claude-workflows` reproduce
  a byte-identical `claude-home/` within a week; counter-evidence = a blessed image whose
  `.manifest` commit is not resolvable in either clone, or a second bless prompt appearing.
- **[4]** — If chosen, the image's payload is reproducible from a hash alone;
  counter-evidence = the release step being skipped once, which immediately reintroduces
  drift between the repo and the image.
- **[0]** — If chosen, nothing changes and the friction stays at its measured level;
  counter-evidence = the first commit that has to straddle both sides, which has not
  occurred in 411 commits.

**Stress-test pass** (4 moves, selected on their triggers):

- **Boring alternative** (a complex approach — a repo split with a pinning mechanism — is
  leading on the user's framing): [7] gets most of the legibility benefit for two hours
  and no cross-repo interface at all. This move is what promoted [7] from an also-ran to
  a survivor, and it changed [2]'s and [4]'s effort cells from "worth it" to "compared to
  what?".
- **Invert the thesis** (the split looked dominant on the measured 0-overlap evidence):
  argued sincerely for never splitting. What survives the inversion is strong — the zero
  overlap is *evidence the current arrangement is not costing anything*, not evidence it
  should change. A split's benefit is smaller clones and narrower review; its cost is a
  new cross-repo interface on the one seam that is genuinely coupled. This move moved
  [2]'s risk from low to **medium**.
- **Organizational survival** (the decision outlives the session that made it): a split
  leaves a future maintainer with two repos where `install.sh` in one reads seven paths
  from the other by convention. [11]'s seam is what makes that survivable — an explicit
  `make payload` contract rather than a `cp -r` that knows another repo's layout. This is
  why [11] is absorbed into [12] rather than listed as a rival.
- **Failure-driven** (boundary config; the cost of an unanticipated failure is high): the
  new failure category a split introduces is **a stale payload source**. Today a stale
  payload is impossible — `install.sh` reads the working tree it lives in. After a split,
  `--payload ../claude-workflows` reads whatever that checkout happens to be on, including
  a feature branch, and the pre-bless diff shows bytes without showing *which commit* they
  came from. Mitigation folded into [2]'s and [4]'s fix sketches (stamp `.manifest` from
  `rev-parse`, refuse dirty trees); it is the reason [2] scores 3/5 rather than 5/5.

## Step 5

Decision record: `docs/decisions/036-cc-isolated-repo-split.md` (written after the
Path B consult).

## Step 4b — Reframe after the Path B consult was paused

The user declined the consult and reframed the question: *what is the real motivation?*
Either review efficiency has measurable headroom, or the motive is accessibility to other
users, which is explicitly low priority — and if neither holds, the status quo wins by
default. That reframe is what resolved the decision, so it is recorded here rather than
folded silently into the outcome.

### Correction to the S1 measurement

The step-2 S1 baseline ("42 commits touched only devcontainer-config/, 369 only the other
side, zero both") classified `docs/` and `test/` as neither side. That was the wrong cut
for this question. Re-measured with those trees counted:

- **1 of 43** commits touching `devcontainer-config/` since 2026-05-20 was confined to it.
- The other 42 co-touched, most often: `docs/decisions/log.md` (21),
  `test/init-firewall-rules.bats` (19), `test/cc-isolated-functions.bats` (17),
  `guides/cc-isolated-usage.md` (14), `docs/working/questions.md` (10),
  `guides/devcontainer-setup.md` (9), then `hooks/wiring.json` (3),
  `scripts/health-check.sh` (2), `README.md` (2), `skills/code-review/SKILL.md` (1).

Most of that co-touch is cc-isolated-specific and would move with it. The residue is the
part that matters: **`docs/decisions/log.md` (21/43) and `docs/working/questions.md`
(10/43) are shared append-only ledgers.** About half of all cc-isolated commits would
become two commits in two repos, or force the ledgers to split per-repo too. The
independence is in *subject matter*, not in *changes*.

### Does review efficiency have headroom?

Three findings, all negative:

1. **Review scope is branch-scoped, not repo-scoped.** `code-review` runs over a diff or
   a branch. A cc-isolated branch already yields a cc-isolated-only diff; the repo
   boundary does not narrow what a reviewer reads.
2. **Test runtime is already sliceable without a split.** `scripts/run-tests.sh` selects
   by `# @category fast|slow` tags. A per-subsystem category (or a path argument) is a
   ~10-line change to a script that already parses flags — no repo boundary required.
3. **A split would add review friction** via the shared-ledger commits above.

With accessibility priced as low priority by the user, no surviving candidate has a
motivation left to serve. [12]'s seam remains the right *first* move if a trigger ever
fires, which is why it is preserved as a named revisit path rather than discarded.

## Step 4c — Decision

**Path A** (one approach dominates, ~85% confidence): **[0] status quo**. The step-4
scorecard is unchanged; what changed is that S1 — the only constraint the split existed to
satisfy — was shown to be unsatisfiable by a split and partly worsened by one.
