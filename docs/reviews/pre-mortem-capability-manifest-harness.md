# Pre-Mortem: capability-manifest bats harness (nested bwrap)

**Proposal:** Per-suite capability manifests (`network: none`, `write: tmpdir`) enforced by a runner that executes bats under a nested-bwrap profile on WSL2 — decision 014 layer 3, validated by `docs/working/spike-nested-bwrap-fixture-confinement.md`
**Date:** 2026-07-09
**Upstream what-if analysis:** none

> No upstream what-if analysis provided. Narratives are generated directly from the
> proposal, seeded by the spike's findings and prior considerations in
> `docs/working/dd-secure-tool-guidance.md` and decision 014.

## Failure Narratives

### 1. The platform pulled the rug (harness goes red everywhere, then gets bypassed)

- **Root cause:** A Claude Code or WSL2 kernel update changes the outer sandbox to block
  nested user namespaces — e.g. the outer bwrap starts passing `--disable-userns`, or a
  seccomp filter denies `clone(CLONE_NEWUSER)`. The primitive the spike validated on
  bubblewrap 0.6.1 / kernel 6.18.33.2 stops existing.
- **Chain of consequences:** Every confined suite fails at `bwrap: Creating new namespace
  failed: Operation not permitted` → the SI overnight run goes fully red → the next session
  "fixes" CI by invoking `bats` directly, bypassing the runner → the harness stays in the
  repo, green-looking and dead, and nobody notices confinement has been off for months.
- **Observable outcome:** One commit whose diff replaces `scripts/confined-bats` invocations
  with bare `bats`; zero runner invocations in `git log` afterward.
- **Plausibility:** Plausible · **Severity:** Medium
- **Tag:** [PRIOR CONSIDERATION] — DD doc step 2 ("WSL2 bwrap nesting is fragile"),
  memory `project_sandbox_bwrap_wsl_broken.md` (outer-sandbox managed-settings incident).
- **Mitigation:** The runner must open with the spike's preflight probe
  (`bwrap --unshare-all --ro-bind / / --dev /dev --proc /proc -- true`) and on failure emit a
  single loud `CONFINEMENT UNAVAILABLE — suites running UNCONFINED` line and a nonzero exit
  in strict mode, rather than dying per-suite; wire the probe's failure into decision 014's
  revisit-trigger list so the platform regression is recorded, not routed around.

### 2. Manifests are self-declared by the code they confine (laxity creep)

- **Root cause:** The manifest lives next to the suite in the agent-writable repo. A suite
  that wants network just declares `network: full` — including a future test written by an
  agent (or a poisoned edit) that widens its own manifest in the same commit that adds the
  hostile fixture.
- **Chain of consequences:** First legitimate exception ships (a suite exercising `gh`)
  → its manifest gets copy-pasted as the template for new suites → within months most
  manifests grant network → the harness runs everything "confined" under profiles that
  confine nothing, and reviewers stop reading manifest diffs because they're routine.
- **Observable outcome:** `grep -c "network: full" test/*.manifest` grows monotonically;
  a 4d39475-class incident occurs in a suite the harness "passed".
- **Plausibility:** Likely · **Severity:** Medium
- **Tag:** [PRIOR CONSIDERATION] — same trust-anchor argument as 014's pruned candidate 7
  and the hint-table failure-driven mitigation ("guidance content is itself trusted policy").
- **Mitigation:** Default-deny with no per-suite override read from the repo at run time:
  the runner ships the manifest table in its deployed copy (copy-not-symlink rule, per 014
  stress-test mitigation 3), and any `network` grant requires an entry there — an agent
  editing `test/` cannot widen its own confinement. Add a fixture-lint rule (014 layer 2)
  that fails any suite whose manifest grants network without a justification comment.

### 3. Death by environment drift (confined-only failures rot the harness)

- **Root cause:** `--clearenv` plus `--tmpfs /tmp` removes variables and paths suites
  implicitly depend on — `HOME`-based tool config (`~/.gitconfig` is readable but
  `$HOME` unset), `BATS_*` internals, the session scratchpad path, nvm's `PATH` entries.
- **Chain of consequences:** Suites pass under bare `bats`, fail under the runner with
  unrelated-looking errors ("command not found: bats" from a stripped PATH; "fatal: unable
  to auto-detect email" from git) → each failure costs a debugging session → contributors
  learn "the runner is flaky" and run bare `bats` locally → drift accumulates until the
  confined path is red permanently.
- **Observable outcome:** Test-fix commits whose only change is exporting env vars inside
  `setup()`; runner marked "known failing" in a working doc.
- **Plausibility:** Likely · **Severity:** Medium
- **Mitigation:** The runner defines one explicit env allowlist in a single function
  (`PATH`, `HOME`, `TMPDIR`, `BATS_*` passthrough), and the repo gains a
  `test/confinement-selftest.bats` suite — the spike's hostile fixture plus a "benign suite
  passes" case — run first by the runner, so env-allowlist regressions fail with a named
  cause instead of scattered symptoms.

### 4. "Provably scoped" oversells what the profile proves (secret reads still possible)

- **Root cause:** The profile severs network and confines writes, but `--ro-bind / /`
  leaves nearly everything readable — including `~/.claude/settings.json` and, without
  `--clearenv`, the outer sandbox's proxy credentials in the environment (observed directly
  in the spike). Someone reads "capability-manifest-passing" as "safe to run untrusted test
  code" and runs a fixture that exfiltrates nothing *now* (no network) but stages secrets
  into the writable scratch dir that a later unconfined step uploads.
- **Chain of consequences:** Manifest language says "provably limited scope" → review
  standards for fixture code relax ("the sandbox catches it") → a staged-exfil pattern
  ships → the write-confined scratch output is consumed by an unconfined CI step → data
  leaves through the seam between confined and unconfined stages.
- **Observable outcome:** Credentials appearing in test artifacts/logs under the scratch
  dir; no alert fires because every individual step behaved within its own boundary.
- **Plausibility:** Plausible · **Severity:** High
- **Mitigation:** `--clearenv` is mandatory in the profile (already in the seed), the
  harness doc must state what the manifest does NOT prove (reads are unconfined), and the
  runner treats scratch-dir contents as untrusted output — the RPI plan's harness section
  must forbid piping scratch artifacts into network-capable post-steps without review.

## Recommendations

- **Must address before proceeding:** Narrative 2 (self-declared manifests). If manifests
  are read live from the agent-writable repo, the harness is convention dressed as proof —
  strictly worse than no harness because it changes reviewer behavior. The deployed-copy
  manifest table is a design invariant, not an option.
- **Worth mitigating:** Narrative 1 (preflight probe + loud degradation path — cheap,
  build it into the runner skeleton on day one); Narrative 3 (env allowlist in one place +
  confinement self-test suite).
- **Acknowledged risks:** Narrative 4's staged-exfil chain requires an unconfined
  post-step consuming scratch output, which this repo's test flow doesn't currently have;
  carrying the risk is acceptable if the harness doc states the read-scope limitation
  explicitly.
