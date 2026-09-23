# Architecture Review — copy-install plan (shape D)

**Scope:** plan review, pre-implementation: `docs/working/plan-copy-install-bare-host.md`, `docs/decisions/037-bare-host-copy-install.md`, `devcontainer-config/install.sh` at 29cdd16, `docs/reviews/pre-mortem-copy-install.md`
**Date:** 2026-09-23
**User goal:** Replace the bare-host symlink install of global files into `~/.claude` with copies that `devcontainer-config/install.sh` makes only after a human reads the diff and answers y. The specific question: does a host target inside the devcontainer-named installer blur the 016/035 boundary?

> ⚠️ **No code fact-check report provided.** Architectural claims in comments and documentation
> have not been independently verified. For full verification, run the `code-fact-check` skill
> first or use the code-review orchestrator.

Scope check: in scope under **cross-cutting concerns** (the installer is the bless pipeline for two trust domains) and **public API** (install.sh's CLI contract: its flags, its prompts and its exit status). Trust-boundary cross-reference: the only security review on file (`docs/reviews/security-review-egress-zone-entries-2026-09-19.md`) maps egress boundaries and does not cover the installer, so this section is a no-op here.

## Dependency Map

- **`install.sh`** (host-executed, runs from the repo). It reads the repo payload sources (`CLAUDE_HOME_SRC`, the `PAYLOAD` files) and writes two destinations:
  - today: `~/.config/claude-devcontainer` plus the bin link, then calls the *installed* `cc-isolated.sh --bless`;
  - under the plan, also `~/.claude`.
- **`cc-isolated.sh`** depends on install.sh's output (the blessed config dir and `.manifest`) but not on install.sh itself (`enforcement_files()` excludes it, by 035's design).
- **`link-claude-home.sh`** (in-container) consumes the image payload that install.sh staged. It shares the seven-entry list (as basenames, `ENTRIES`) and the `.claude-workflows-manifest` filename and format. The host target becomes a second producer of that manifest filename.
- **`hooks/`** depends on its own relative layout (`lib/`, `../scripts/lib`). Whole-dir copies preserve it.
- **Guides/README** document the procedure. Dependencies flow from volatile (docs, the installer) toward stable (the payload list, the manifest format). Nothing in the plan makes the payload or the launcher depend on the host target. Direction is sound.

## Findings

#### 1. One script, two trust regimes: keep them as separate target functions, not interleaved branches

**Severity:** Coupling
**Location:** `devcontainer-config/install.sh:116-158` (prompt, install, bless) and plan step 5
**Move:** 2 (responsibility boundaries), 8 (extension points)
**Confidence:** High

The devcontainer target's bless is a recorded hash that the launcher checks. The host target's bless is a human at a TTY, with no receipt checked. Those are different postconditions. If step 5 threads host behavior through the existing linear flow (`if host …` branches around the prompt and install), every later edit to the devcontainer path has to reason about the host path too. Decision 037's own revisit trigger ("add Gemini as a third target") would then become a third set of branches. That is the 016 "two code paths, two trust regimes" concern arriving *inside* one file instead of across two.

**Recommendation:** structure install.sh as shared helpers (`assemble`, `review_diff`, `confirm`) plus one function per target (`install_devcontainer`, `install_claude_home`). A main sequence then calls the targets in order and folds their results into the exit status. A new target is a new function and one line in the sequence. Each target's header comment states its own bless semantics.

#### 2. The host entry list must derive from `CLAUDE_HOME_SRC`, not restate it

**Severity:** Coupling
**Location:** plan step 5 ("for each of the seven entry names"); `install.sh:49`; `link-claude-home.sh` `ENTRIES`
**Move:** 7 (coupling surface)
**Confidence:** High

The seven names already live in two places: `CLAUDE_HOME_SRC` as repo paths, and `link-claude-home.sh` `ENTRIES` as basenames. The host swap, review and rollback loops operate on basenames. A hand-written third list in the host code would let the payload grow (a new `CLAUDE_HOME_SRC` entry) while the host install silently skips it. That is FP-066's subset-install failure on the host.

**Recommendation:** compute the host names as `basename` of each `CLAUDE_HOME_SRC` item, in one place, and have the review, swap and manifest loops all iterate that. A test asserting that every staged top-level entry reaches the destination (T6 already compares entries) pins it.

#### 3. The symlink-aware review should wrap `review_diff`, not fork it

**Severity:** Minor
**Location:** plan step 4 (`review_diff` extraction) and step 5 (symlink-aware review)
**Move:** 3 (module boundary)
**Confidence:** Medium

`review_diff`'s contract (`-N` for new content, rc 1 = change, rc >1 = abort before the prompt) is the hard-won D1 fix. If the host review copies the loop to add `REPLACE symlink` and `MOVE to backup` lines, the two copies can drift the next time the contract changes.

**Recommendation:** the host review runs a separate pre-pass (symlinks, foreign files, WIRED hooks) that only prints and counts. It then calls the same `review_diff` for the content diff and combines the counts. `review_diff` returns the changed flag rather than writing a global, so both targets consume it the same way.

#### 4. install.sh's CLI contract changes and should be stated in one place

**Severity:** Minor
**Location:** `install.sh:21` → the new argument loop; plan Risks ("Exit status under D")
**Move:** 3 (public surface)
**Confidence:** Medium

Under D the script's observable contract gains three things: a second prompt, "skipped" as an outcome that does not affect the exit status, and exit 2 for unknown flags. The README, the bare-host guide and decision 037 each describe part of this.

**Recommendation:** put the contract in the `usage()` text (targets in order, the skip rules, exit codes 0/1/2), and have the README and guide point to `install.sh --help` rather than restating the rules.

#### 5. `.claude-workflows-manifest` gets a second producer: keep the format additive

**Severity:** Minor
**Location:** plan step 5 Provenance; `link-claude-home.sh` manifest copy; pre-mortem #4 (`installed_by=`)
**Move:** 7
**Confidence:** Medium

The manifest filename and format were owned by the image path. The host target now writes the same file with the same keys, plus `installed_by=` if pre-mortem #4 is adopted. Any future reader of the manifest (a SessionStart staleness hook, DD [9]) must handle both producers.

**Recommendation:** keep the keys a superset (`commit=`, `dirty=` and `assembled_from=` unchanged; new keys appended). The host copy starts as the stage's `.manifest` and then has keys appended, so the two producers can't disagree on the shared keys.

#### 6. The 016/035 boundary: not blurred structurally, but 035's exposure widens

**Severity:** Informational
**Location:** `install.sh:1-14` header; decision 035
**Move:** 4 (layer violations)
**Confidence:** High

016's contract is "only the installed copy under `~/.config/claude-devcontainer` is read by the launcher". The plan leaves that unchanged. The host target adds no file to `PAYLOAD` or `enforcement_files()`, and the launcher never reads `~/.claude` host content. So the layers stay intact. What changes is the blast radius of install.sh itself, which 035 already names as the unhashed, agent-writable exception. Placement in `devcontainer-config/` is now a slight misnomer, but moving the script would break the documented path in every guide and the 035 decision's regex target. A rename is not worth it now.

**Recommendation:** the plan's step 7 (a 035 Consequences note) and step 5's header rewrite are sufficient. Revisit a move to a neutral path only if a third non-devcontainer target is added.

## What Looks Good

- **One payload definition** for the image, the in-container linker and the host. The host stages with the same `assemble`, so the host cannot get a hand-picked subset.
- **The skip-before-read ordering** for non-interactive runs keeps the devcontainer path's observable behavior (and its tests, which don't pin HOME) unchanged. The new target cannot reach outside the scratch paths of old tests.
- **`settings.json` stays out of the installer.** It avoids a second merger competing with link-claude-home's provenance jq (FP-161) and keeps host-private hardening host-owned.
- **Whole-directory copies** respect the hooks' relative-layout contract instead of special-casing `lib/`.
- `link-claude-home.sh` is untouched: the in-container symlinks point at a read-only blessed payload, which is a different trust situation, and the plan correctly leaves it alone.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Separate per-target functions, not interleaved branches | Coupling | `install.sh:116-158`, plan step 5 | High |
| 2 | Host entry names derived from `CLAUDE_HOME_SRC` | Coupling | plan step 5; `install.sh:49` | High |
| 3 | Host review wraps `review_diff`, doesn't fork it | Minor | plan steps 4–5 | Medium |
| 4 | CLI contract stated once, in `--help` | Minor | `install.sh:21` | Medium |
| 5 | Manifest format additive across two producers | Minor | plan step 5 | Medium |
| 6 | 016 layers intact; 035 exposure widens | Informational | `install.sh:1-14` | High |

## Overall Assessment

The plan keeps the system's structure intact. Dependencies still flow from the installer and docs toward the stable payload list and manifest format. The launcher and the in-container linker gain no dependency on the host target, and the 016 layering is unchanged. The risk is internal to install.sh: one file now carries two bless semantics. The single most important structural concern is finding 1, keeping the targets as separate functions over shared helpers, with finding 2 (deriving the entry names) as its necessary companion. Both are fixable in place, in plan steps 4–5, without restructuring.
