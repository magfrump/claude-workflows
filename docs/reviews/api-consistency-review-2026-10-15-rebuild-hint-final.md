Commit: 2463017f
# API Consistency Review — fix/rebuild-hint-recreate (final confirming pass)

**Scope:** whole unit, `9660d4f6..2463017f` (devcontainer-config/cc-isolated.sh, devcontainer-config/init-firewall.sh, guides/cc-isolated-usage.md, test/cc-isolated-functions.bats, test/init-firewall-rules.bats; guides/devcontainer-setup.md read as baseline, unchanged)
**Date:** 2026-10-15
**Based on:** docs/reviews/code-fact-check-report-2026-10-15-rebuild-hint-final.md; earlier reports api-consistency-review-2026-10-15-rebuild-hint.md and -i2.md, dispositions in code-review-rubric-2026-10-15-fix-rebuild-hint-recreate.md

## Baseline Conventions

- **Vocabulary.** The guides use "recreate" for the container (`devcontainer up --remove-existing-container`) and "rebuild" for the image (central-image rebuild; `--register`'s "next launch rebuilds that project's image", devcontainer-setup.md:85; cc-isolated.sh:481) and for the firewall's ruleset (init-firewall.sh "PHASE B — REBUILD"). A plain launch recreates only on a config-hash mismatch; `--probe-only` always recreates (devcontainer-setup.md:309, :335, :400).
- **Recovery recipe.** `cc-isolated --probe-only <repo>`, then `cc-isolated <repo>` (cc-isolated-usage.md:957, devcontainer-setup.md:399-401).
- **Copyable launcher output (set by this unit, i2 F1).** The command stands alone on its line. The explanation goes on its own line, either above it as prose or below it as a parenthesised, further-indented line. install.sh's "Next steps" block is the one remaining exception, deferred in override-log.md.
- **Probe-failure lead-ins.** Every caller of `rebuild_hint` now introduces it with "Recreate it": "Recreate it with:" (cc-isolated.sh:676, :690) and "Recreate it (the ~/.claude volume and your repo are not affected):" (:925).

I re-checked the whole public surface against this baseline: the `--help` header (executed, see below), `rebuild_hint`, the unverified-config NOTE, the bless "Next:" line, the three probe-failure lead-ins, init-firewall.sh's fail-closed recipe, and both guides. Every user-facing "rebuild" left in the touched scripts and guides is either about the image or the ruleset (cc-isolated.sh:481, :768, :770, :924; cc-isolated-usage.md:963 "was rebuilt with a bare `devcontainer up`", the by-hand path), or an item already dispositioned (cc-isolated.sh:905, C10 Won't-Fix; install.sh:613, deferred).

## Name-Pattern Audit

The diff adds no new public names: no flag, subcommand, exit code, env var or function. `rebuild_hint` keeps its name (iteration-1 report: two docs refer to it by name). The only new identifier is a private test-stub variable.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `STUB_FW_BRICKED` | test-stub env var (private) | `STUB_FW_MISSING`, `STUB_IMAGE_HASH`, `STUB_FP` | `test/cc-isolated-functions.bats:1155-1170` | Consistent: matches the `STUB_<THING>[_<STATE>]` shape and the FW_ prefix of its sibling |
| `cc-isolated --probe-only WS && cc-isolated WS` | CLI recipe (printed text) | "`cc-isolated --probe-only <repo>` …, then `cc-isolated <repo>`" | `guides/cc-isolated-usage.md:957`, `guides/devcontainer-setup.md:400-401`, `devcontainer-config/init-firewall.sh:354-355` | Consistent (confirmed in i1; unchanged since) |

## Findings

#### 1. The bless "Next:" line's command-alone layout is the only one of the three fixed copyable lines with no test pinning it

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:318-319`; contrast `test/cc-isolated-functions.bats:360` and `test/init-firewall-rules.bats:1498-1499`
**Move:** 3 (consumer contract: test drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
> `echo "  Next: cc-isolated --probe-only <repo>"`
> `echo "        (recreates the container from it and probes as node)"`

`rebuild_hint`'s first line is pinned by an exact-match assertion. init-firewall.sh's two command lines are pinned with `grep -qx`. The bless line has no assertion at all: `rg "Next:|probe-only <repo>" test/` matches only init-firewall-rules.bats, and the bless test at cc-isolated-functions.bats:1257 checks only `Verified live:  NO`. If someone restores a trailing `# ...` there, no test fails. The risk is low because this line reaches only `--probe-only`, which rejects the non-directory that a stray word becomes (i2 F1). The commit body says the "init-firewall test pins both command lines", which is accurate about its own scope.

**Recommendation:** Optional. Add `printf '%s\n' "$output" | grep -qx '  Next: cc-isolated --probe-only <repo>'` to the existing `Verified live:  NO` test.

#### 2. `--help` says `--probe-only` will "record it verified live" without the "on a pass" condition that the guide's copy of the line carries

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:13-15` vs `guides/cc-isolated-usage.md:25-26`
**Move:** 3 (documentation drift between two copies of one usage line)
**Confidence:** High (fact-check final: Mostly accurate)
**Legibility-target:** for-author

Evidence:
> `#   cc-isolated --probe-only [WS]        # recreate WS's container from the blessed`
> `#                                        # config, run the boundary self-probe, record`
> `#                                        # it verified live`

> `cc-isolated --probe-only [REPO]   # RECREATE REPO's container from the blessed config, run the`
> `                                   # self-probe, record the config verified live on a pass`

The omission predates this unit (the old line also said "record it verified live"). The unit did rewrite these lines to match the guide's verb, so the remaining difference stands out more. A reader is unlikely to be misled: the header's BLESSED IS NOT VERIFIED paragraph says the receipt is written "ONLY by a passing self-probe".

**Recommendation:** Optional. Change it to "record it verified live on a pass" the next time the line is touched; it fits within the block's 92-column width.

#### 3. The rewrapped header paragraph leaves one short line

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:62-64` (printed by `--help`)
**Move:** 1 (baseline: `--help` formatting)
**Confidence:** High (executed `cc-isolated.sh --help`, line widths measured)
**Legibility-target:** for-author

Evidence:
> `# config so the probe exercises the new config rather than an old image (--probe-only`
> `# always recreates), and refuses to start a session unless the baked`
> `# firewall script reached its completion marker. See guides/devcontainer-setup.md,`

The surrounding lines run 79-86 columns, and this one is 66. It is cosmetic only, and the wording is correct and matches devcontainer-setup.md:335.

**Recommendation:** None required. Reflow the paragraph if it is edited again.

## What Looks Good

- **Vocabulary sweep is complete on the in-scope surface.** "Recreate" now covers the container in `--help` (:13, :61-63), the NOTE (:884-887), the bless "Next:" line (:319), the hint and its three lead-ins, init-firewall.sh (:346-353), and the guide (:25, :841-842, :955, :963). "Rebuild" remains only where it means the image, the ruleset or the by-hand path. This matches the guides' split exactly.
- **One recipe, one order, everywhere.** `rebuild_hint`, init-firewall.sh and both guides give the same two steps in the same order with the same placeholder. Only the hint joins them with `&&`, and the `--probe-only` non-zero-exit test now backs that join (C3).
- **Consistent copyable layout.** Each fixed command stands alone, with its explanation on a separate line: prose above it in init-firewall.sh, a parenthesised indented line below it in `rebuild_hint` and in the bless "Next:" line. The rationale is written next to each (cc-isolated.sh:565-566, init-firewall.sh:347-349).
- **Lead-ins converge.** All three `rebuild_hint` callers now say "Recreate it". Before, two said "Rebuild with:", against the guides' "recreate".
- **NOTE, header and guide row now agree with runtime behaviour** in the fail-closed state, which is the contradiction i1 F1 found. The new fail-closed launch test asserts the old NOTE text is gone.
- **No contract change.** No flag, exit code, env var, or the `rebuild_hint` name changed (fact-check: no behavioural Incorrect; the diff changes only echo text, comments, tests and one stub case arm).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Bless "Next:" command-alone layout has no test pin, unlike its two siblings | Informational | `devcontainer-config/cc-isolated.sh:318-319` | High |
| 2 | `--help` omits "on a pass" that the guide's copy of the `--probe-only` line carries (pre-existing) | Informational | `devcontainer-config/cc-isolated.sh:13-15` | High |
| 3 | Rewrapped header paragraph leaves a 66-column line | Informational | `devcontainer-config/cc-isolated.sh:62-64` | High |

## Overall Assessment

The unit is consistent with the codebase's established public surface. The launcher, init-firewall.sh and both guides now use one vocabulary (recreate the container, rebuild the image), one recovery recipe in one order, and one copyable-line layout. The only exception, install.sh's "Next steps" block, is deferred with a revisit trigger. Every iteration-1 and iteration-2 API finding is either fixed or carries a disposition in the rubric, and this pass found nothing that re-opens one. The three remaining notes are Informational: an optional test pin, a pre-existing two-word omission in `--help`, and a cosmetic line wrap. None affects what a consumer types or what the launcher does. No Breaking, Inconsistent or Minor findings.

## Goal-Alignment Note

The goal was to stop the launcher's hint from sending a user whose firewall failed closed back into a plain launch that reuses the broken container, and to say "recreate" where recreate is meant. The diff does this. On the public surface, the hint's first line is now exactly the guides' recipe, and the texts around it (NOTE, `--help` header, lead-ins, init-firewall recipe, guide rows) no longer promise a recreate that a plain launch skips. Nothing in this pass argues against landing it. Pre-existing C4 (the `--probe-only` loop when the build itself is at fault) and install.sh's block stay deferred, as recorded.
