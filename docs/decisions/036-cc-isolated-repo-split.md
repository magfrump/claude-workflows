# 036 — cc-isolated stays in the claude-workflows repo

**Goal**: Decide whether the cc-isolated sandbox setup should be extracted from the
claude-workflows repo into its own repository.
**Project state**: standalone decision on `main`, prompted by the 2026-09-17 `scholar`
egress profile work · not part of a larger initiative · not blocked.
**Task status**: complete (decided Path A; no implementation follows)

## Context

The cc-isolated setup (`devcontainer-config/`: launcher, Dockerfile, firewall, SNI
proxy, egress profiles, installer) and the workflows/skills content (`skills/`,
`workflows/`, `guides/`, `patterns/`, `hooks/`) look like two projects sharing a
repository. Changes to each appeared largely independent, which raised the question of
whether the repository boundary is in the wrong place.

The coupling between them is real but one-directional and narrow: `install.sh` assembles
the image payload by `cp -r`-ing seven paths from the repo root
(`CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks
scripts)`), so cc-isolated does not merely sit beside the workflows content — it **ships**
it (decisions 022, 023). Any split therefore has to turn that `cp -r` into a cross-repo
interface.

DD working doc: [`docs/working/dd-cc-isolated-repo-split.md`](../working/dd-cc-isolated-repo-split.md).

## Options considered

15 candidates across four levers — how the payload crosses a repo boundary (2, 3, 4, 9),
where payload assembly lives (11, 12, 14), whether to restructure without splitting (6, 7,
13, 15), and which direction the dependency points (5, 8) — plus do-nothing (0, 1) and a
naive split (10). Five survived step-3 pruning: **[12]** seam first + split behind a
trigger, **[7]** regroup in place, **[4]** split with a pinned artifact, **[2]** split with
the payload by path, **[0]** status quo.

The Path B consult was paused by the user, who reframed the question rather than answering
it: *is there measurable review-efficiency headroom, or is the motive accessibility to
other users?* — with accessibility priced as low priority, and the status quo the default
if neither motive holds. That reframe decided the outcome, and the measurements it prompted
are the substance of the rationale below.

## Decision and rationale

**Chosen: [0] — cc-isolated stays in this repository.** No split, no seam extraction, no
regroup.

The decision rests on a corrected measurement and three findings, not on inertia.

**The correction.** The first pass at the evidence classified `docs/` and `test/` as
neither side, and reported that zero commits straddled the two sides. That was the wrong
cut. Counted properly, **1 of 43** commits touching `devcontainer-config/` since
2026-05-20 was confined to it; the other 42 co-touched `docs/`, `guides/`, `test/`,
`hooks/` or `scripts/`. The independence is in *subject matter*, not in *changes*.

**Finding 1 — a split would add review friction, not remove it.** Most of the co-touch is
cc-isolated-specific and would move with it (its two main bats suites, 19 and 17 commits;
`guides/cc-isolated-usage.md`, 14; `guides/devcontainer-setup.md`, 9). The residue is what
matters: `docs/decisions/log.md` (21 of 43) and `docs/working/questions.md` (10 of 43) are
shared append-only ledgers. Roughly half of all cc-isolated commits would become two
commits in two repos, or force the ledgers to split per-repo as well.

**Finding 2 — review scope is branch-scoped, not repo-scoped.** `code-review` and the
lite-review path run over a diff or a branch. A branch touching cc-isolated already
produces a cc-isolated-only diff; the repository boundary is not what narrows what a
reviewer reads.

**Finding 3 — the test-runtime lever already exists without a split.**
`scripts/run-tests.sh` selects suites by their `# @category fast|slow` tag. Adding a
per-subsystem category, or a path argument, is a ~10-line change to a script that already
parses flags.

With those three findings, S1 — *reduce cross-side review and clone surface*, the only
constraint a split existed to satisfy — is unsatisfiable by a split and partly worsened by
one. The remaining motive would be making cc-isolated usable by someone who does not want
the workflows payload, which the user has priced as low priority. A restructure with no
live motive is churn against a boundary that four decisions (015, 016, 022, 023) have
already been tuned around.

Decided via **Path A** at ~85% confidence after the consult was reframed. The runner-up is
**[12]** (extract the payload seam, defer the split behind a trigger), which is not dead:
it is the correct *first* move if any revisit trigger below fires, and is preserved in the
working doc for that purpose.

See alternatives considered → *Pruned candidates and why*, below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in
adjacent areas can grep this section to avoid regenerating already-pruned approaches.

`[1 document only] / [6 ownership convention] / [13 worktree lanes] / [15 social rule]: ✗ on S1 — the status quo with a note attached, and S1 turned out to be unsatisfiable anyway.` `[2 split, payload by path]: runner-up among the splits, ✗ on H1/H5 as authored — the payload source becomes an unhashed input (--payload reads whatever that checkout is on, including a feature branch) and the pre-bless diff shows bytes without showing which commit; fixable by stamping .manifest from rev-parse, but H2 stays partial by construction.` `[3 git submodule]: [carried from 016-multi-project-devcontainer-central-config [6]/[13]: "both are [2] with a propagation mechanism bolted on; they inherit [2]'s H2 hole while adding machinery"] — the pinned checkout is still a tree the same host session can rewrite before install.sh reads it, so it buys ceremony rather than provenance.` `[4 pinned artifact]: best-covered split at 4/5 hard, discarded with the split itself — it inserts a release step between every workflows edit and the image, and skipping it once reintroduces exactly the drift decision 022 exists to prevent.` `[5 mirror/subtree]: ⚠ on H3 — boundary commits would land in the repo where live-verify-gate.sh does not enforce.` `[7 regroup in place]: the boring alternative, and it survived to the scorecard at 5/5 hard for two hours of work; discarded because its only benefit is legibility and the user's reframe established that legibility was not the motive.` `[8 three repos]: ✗ on H2 — three repos is three canonical trees.` `[9 npm package]: ✗ on S3, no registry infrastructure on this single-user host; served as the ideal-if-free space-widener and its versioned-payload idea survives in [4] and [11].` `[10 naive split]: ✗ on H1/H4/H5; listed to be explicit that "just move it" is not a plan.` `[11 extract the payload seam]: absorbed into [12] rather than discarded — it is the durable half, and the Organizational-survival move is why.` `[12 seam first, trigger]: the step-4 recommendation before the reframe; discarded as a decision but retained as the named first move if a revisit trigger fires.` `[14 split, drop the payload]: ⚠ on H5 and a direct revival of the state decision 022 was written to fix (a bind-mounted payload works only in sessions editing this repo).` `Prior pruning grep: matches found for [repo, split, payload, submodule, vendor, monorepo] — [carried from 016 [6]/[13] submodule/template: propagation machinery over a vendored copy] → pruned [3]; [carried from 016 [2] vendor-per-repo: config inside an agent-writable repo] → informed H2; [revived from 035-install-sh-gating [7] move the installer off the repo: 035 asked whether the installer should leave any agent-writable repo, which a two-repo split does not achieve since both repos stay agent-writable on the host — the surviving half, "do not split one committed-canonical-config property into two", became hard constraint H2 rather than a candidate].`

## Stress-test mitigations

- How to read: *Invert the thesis* mitigation — arguing sincerely for never splitting
  established that zero cross-side commits is evidence the arrangement **is not costing
  anything**, not evidence it should change. This moved [2]'s risk cell from low to medium
  and pre-figured the reframe that decided the record.
- How to read: *Boring alternative* mitigation — promoted [7] (regroup in place, two
  hours, no cross-repo interface) from an also-ran into the survivor set, which reframed
  [2]'s and [4]'s effort cells from "worth it" to "compared to what?".
- How to read: *Failure-driven* mitigation — named **stale payload source** as the failure
  category every split introduces and the status quo cannot have (today `install.sh` reads
  the working tree it lives in). This is what dropped [2] to 3/5 hard-constraint coverage.
- How to read: *Organizational survival* mitigation — a future maintainer facing two repos
  where one's installer reads seven paths from the other by convention is the condition
  [11]'s explicit `build-payload.sh` contract exists to prevent; this is why [11] was
  absorbed into [12] rather than listed as a rival, and why [12] survives as the named
  first move rather than being discarded outright.

## Consequences

**Easier.** A cc-isolated change stays one commit with its guide, its tests, its decision-log
row and its questions-doc entries — the shape 43 of the last 43 such commits already had.
The trust story stays single: one committed canonical config, one `--bless`, one
`enforcement_files()` hash, one live-verify trailer. `install.sh` keeps reading the working
tree it lives in, so a stale payload source remains structurally impossible.

**Harder.** The repo keeps carrying two subject matters, so a newcomer reads
`devcontainer-config/` and the workflows content as one project when they are not — the
cost [7] would have addressed. Anyone wanting cc-isolated without the workflows payload
must take the whole repo. And `install.sh` keeps knowing seven directory names from its
own repo root, so a reorganization of `skills/` or `guides/` still lands in the installer's
`CLAUDE_HOME_SRC` list (already fatal-on-miss, which is the mitigation).

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt
re-evaluating this decision. Future readers can grep this section when their context
changes to see whether earlier decisions still apply.

`if a second operator or a second machine needs cc-isolated without the workflows payload → the accessibility motive has arrived and [12] becomes the first move (seam), then [4].` `if any commit has to touch both devcontainer-config/ and skills|workflows|patterns for a non-doc reason → the 1-of-43 confinement figure is stale; re-run the matrix.` `if a second consumer of the claude-home payload appears (anything other than cc-isolated staging it) → [11]'s seam is owed regardless of the split, since the cp -r would then encode one consumer's layout assumption for two.` `if docs/decisions/log.md or docs/working/questions.md is split per-subsystem for unrelated reasons → finding 1's shared-ledger objection drops from 21-and-10 of 43 to near zero, and [7] then [2] become materially cheaper.` `if scripts/run-tests.sh grows a per-subsystem selector and cc-isolated's suites still cannot be run alone → finding 3 was wrong; re-open H4.` `if the workflows side acquires a release cadence (versioned skills, external consumers) that cc-isolated should not be coupled to → [4]'s pinned artifact becomes the shape to revisit first.`
