Commit: fd0cf3ed
Loop closed at fd0cf3ed (iteration-4 gate: the user's decision, below)

# Code Review Rubric

**Branches:** `feat/constraints-builder-u2-references` (u2: the skill's two reference files) and `feat/constraints-builder-u3-skill` (u3: SKILL.md, the onboarding, dev-cycle and README pointers, and the self-eval). These are units 2 and 3 of 3; u1 merged as c9f2fa21. · **Date:** 2026-10-19
**Critics:** code-fact-check (k=1, then k=3 twice) and security-reviewer, all opus. Performance and api-consistency were skipped: both diffs are copy-only prose with no API surface, and the skill's use of the u1 CLI was checked in u1's api-consistency pass. Agents returned their reports as text, and the orchestrator recorded them here, condensed.

## Iteration log

- **Iteration 1** (u2 k=1, u3 k=1 + security): u2 had 1 Incorrect (an immutable commit body) and 8 Mostly accurate, all fixed in c2fbd6b6. u3 had 2 Incorrect and 11 Mostly accurate, plus security with 1 High and 7 Medium (corpus success lines executed, no top-level evidence rule, shell-template git reads, path-based authority, unguarded planting, prefix parse check, in-repo parser, coarse ratification). All fixed in 899d663e.
- **Iteration 2** (k=3 each + one security review over both units): each unit had Incorrect claims on the provenance command (renames, HEAD) and on Done-when. Security found 1 High (readers lacked the quoting rule) and 5 Medium (planting through symlinks, `git archive` filters, spoofable provenance, bare questions.sh, reader isolation). The fixes are a2e90133 and 107690ce (u2; readers now run nothing) and fd0cf3ed (u3; git hardening, blame provenance, trap/realpath planting, rg).
- **Iteration 3** (k=3 over both units + security): u2 clean apart from one wording item, fixed in efb19f49. u3 had 2 Incorrect in all three replicates: the git-config check misses includes and worktree config, and `--no-ignore-dot` does not lift `.rgignore`. Security had 1 High (the same check, bypassed through include.path, includeIf, config.worktree and gpg.program, with execution probes) and 5 Medium/1 Low.

## Iteration-4 gate (cap reached)

The decision is **neither escalate nor split, but rescope** (the user's answer). v1 trusts the operator's own repos, and untrusted target repos are outside its security boundary (decision log 73). Open hardening work is recorded with a revisit trigger in `docs/working/constraints-builder-hardening.md`. The close-out commit:
- adds the "Scope (v1): sole-author repos only" paragraph;
- removes the git-config denylist, which every iteration-3 reviewer showed gives false assurance;
- fixes `.rgignore` (now `--no-ignore`), the deleted-file SHA command, the extracted-file line numbers (ref in the file name), and "stricter label".

The deferred security findings have override rows dated 2026-10-19 for u3.

## 🔴 Must Fix
None open. Iteration-3 security F1 is Won't-Fix (out of v1 scope), with an override row.

## 🟡 Must Address
None open. Iteration-3 security F2, F3, F5 and F6 are Won't-Fix or Defer, with override rows and hardening items.

## ⏭️ Skipped Core Critics
| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | Copy-only diff (markdown skill prose) | `git diff --stat` shows only `.md` under `skills/` and `docs/` |
| api-consistency-reviewer | No public API surface; the CLI the skill uses was reviewed in u1 | u1 rubric, api-consistency final pass |

## Status
Review closed under the cap by a scope decision; single-sample review; absence of findings is not an attestation.
