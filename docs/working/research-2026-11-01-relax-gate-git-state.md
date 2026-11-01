# Research: narrow the gate's git-state checks to in-scope threats

- **Goal**: The gate's checks on git state, config and the object store refuse only what an honest slip, a concurrent session, a crash or H2 requires, so ordinary honest setups pass every gated mode.
- **Problem framing**: Most of `state_gate`, all of `store_check`, part 2 of `checkout_gate`, `caller_gate`'s config-pair scan and two `git_harden` pins defend against a hostile same-uid writer, which S1 and the owner (2026-10-30) put out of scope, and several refuse common honest setups. Considered and discarded: "the checks are right but their messages are unclear" (the refusals are accurate; the setups they refuse are legitimate).
- **Project state**: unit 1 of the 2026-11-01 restriction audit · units 2-7 follow (unit 3 edits the rest of SKILL.md in parallel) · not blocked (cite: docs/working/research-2026-11-01-restriction-audit.md)
- **Task status**: complete (implemented and reviewed on refactor/relax-gate-git-state)

## Scope and threat model

The threat model is `docs/constraints.md` as the audit reads it: in scope are honest slips by the orchestrator or a same-uid loop, concurrency between sessions, crashes, outside parties, and H1-H4. Out of scope (S1, owner 2026-10-30): a deliberately hostile loop, branch, merge driver or wiring; planted config, hooks, filters, replace refs or grafts; forged objects. H2 still binds every check that stays: it must fail closed and loudly on input it cannot model.

## What exists

All [observed] by reading `scripts/build-loop.sh` and `scripts/lib/dev-cycle-read.sh` at 269cef09.

- `state_gate` (build-loop.sh ~728): refuses any key matching `STATE_KEYS_RE` (filter, include, hook, merge, diff, core.fsmonitor, core.attributesFile, core.hooksPath, gpg, log.showSignature, extensions.partialClone, remote.*.promisor) in `config` or `config.worktree`; a non-empty `info/attributes`, `info/grafts`, `shallow` or `objects/info/alternates`; any `refs/replace/` ref; an `origin/HEAD` naming any branch but origin/main or origin/master. Runs in every gated mode before `resolve_main`, again in `land` (on the repo and on W, the worktree with main checked out) right before the ref moves.
- `caller_gate` (`--state` only): refuses every repo-local variable from `git rev-parse --local-env-vars` but the caller's config pairs, `GIT_NO_REPLACE_OBJECTS` and `GIT_PREFIX`; and any caller `-c`/`GIT_CONFIG_COUNT` pair for a `STATE_KEYS_RE` or `HARDEN` key.
- `default_gate` (after `resolve_main`): both main and master exist; `refs/heads/MAIN` symbolic; it names a non-commit; `origin/HEAD` names a branch other than the one taken.
- `resolve_main` (lib): takes origin/HEAD's branch when that local branch exists, then main, then master.
- `store_check`: re-hashes every object of main's tree (startup), of each tip and merge (`check_line`), and of HEAD and the merge (`land_cycle`), and refuses any id with a second copy (two packs, or loose and packed). In `land_cycle` it is also the blob-presence check (a comment says so: "store_check reads every blob of R").
- `checkout_gate` (self-merge `--check` only): stray repo-local variables, HEAD at MAIN_SHA, then core.symlinks=false, core.ignoreCase=true, core.sparseCheckout=true, any non-`H` `ls-files -v` tag, a dirty `git status`, an untracked nested repository, a gitlink with files, odd names, and a `hash-object --no-filters` of every regular file compared to main's blobs.
- `git_harden` (lib): `HARDEN` pairs (useReplaceRefs, hooksPath, fsmonitor, attributesFile, commitGraph, multiPackIndex, log.date, log.showSignature, commit.gpgSign) plus `GIT_LITERAL_PATHSPECS GIT_NO_REPLACE_OBJECTS GIT_OPTIONAL_LOCKS GIT_ATTR_NOSYSTEM GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM GIT_ALLOW_PROTOCOL=none`. A test holds `HARDEN` and the env list equal to the D6 block's `G=(env ...)` line and SKILL.md's `hg()` line.
- `gate_repo`/`gate_git`: merge-tree, diff-tree, merge-base and commit-tree run in a fresh config-less GIT_DIR in an empty directory, so no repo config, no checkout `.gitattributes` and no submodule repository reaches the merge (audit row G11, kept).
- `land`: lands by `update-ref` compare-and-swap of a `commit-tree` the gate wrote, or by `git merge --ff-only` in W. Neither runs a merge driver.

## Row re-verification

| Row | What it refuses (code) | In-scope threat? | Verdict here |
|---|---|---|---|
| G4 | config keys in `STATE_KEYS_RE` | Only partial clone (`extensions.partialClone`, `remote.*.promisor`): history and objects the gate reads are incomplete (H2, degraded primitive). The rest: the merge runs in `gate_repo` with no repo config; hooks, fsmonitor and attributesFile are overridden by `HARDEN` pairs (command scope outranks repo config); a filter or lfs runs only in `git status` and W's fast-forward, as the owner's own git would. | Keep the two partial-clone keys; drop the rest. |
| G5 | info/attributes, grafts, shallow, alternates | `shallow`: H2 (truncated history; `--main-log` and merge bases read wrong). attributes: the merge reads none (gate_repo). grafts: hostile-only. alternates: an honest `--reference` clone; objects resolve normally. | Keep `shallow`; drop the rest. |
| G6 | refs/replace | Hostile-only, and `GIT_NO_REPLACE_OBJECTS` already ignores them. | Drop. |
| G7 | origin/HEAD naming a branch other than main/master | See D2 below: kept, moved into `default_gate`. | Keep (moved). |
| G8 | both main and master; symbolic; non-commit; origin/HEAD mismatch | (a) both: an ambiguous default (H2); `resolve_main` would silently take main. (b) symbolic and non-commit: unmodelled shapes that make `update-ref` move another branch or never match (H2); no honest friction. | Keep all four (D2). The audit's G8(a) verdict is not followed: see D2. |
| G9 | caller variables and pairs | GIT_DIR, GIT_WORK_TREE, GIT_INDEX_FILE, GIT_OBJECT_DIRECTORY, GIT_COMMON_DIR: an honest run from a git hook or a subshell points the gate at another repository or index. Graft, replace, shallow, alternate variables and config pairs: hostile-only (a planted ~/.zshrc). | Keep the five; drop the rest. |
| G10 | state gate before `resolve_main` | Still useful for the kept partial-clone check (no object read before it refuses), and costs nothing. | Keep the order; its comment narrows. |
| G12 | `store_check` | Hostile-only (forged bytes). Honest side effect: a duplicate copy (loose and packed until `prune-packed`, overlapping packs after fetches) refuses. git's zlib and CRC checks and `gate_git`'s stderr rule catch honest corruption. | Remove. Keep `land_cycle`'s blob-presence half, as `check_line` already does it (D3). |
| G51 | checkout HEAD, status, variables | Honest slip: `--check` from a stale or dirty checkout reads the wrong untracked files. | Keep (with G9's five variables). |
| G52 | symlinks, ignoreCase, sparse, index bits, nested repos, gitlinks, odd names, per-file hash | Hostile mostly (a filter showing the walk other bytes); the walk reads main's blob for every path main stores, so a conversion cannot change what it reads there. Honest: Windows/macOS checkouts (ignoreCase), autocrlf, sparse checkouts (skip-worktree), a nested research clone. | Drop all of part 2. Unmerged entries still refuse, through `git status` (an unmerged path prints a `UU` record). |
| K7 | `git_harden` | See D4. | Drop `core.commitGraph=false` and `core.multiPackIndex=false`; keep the rest, with reasons. |
| R13 | step 0.1's `--state` prose | Follows from the above. | Update the paragraph and the Hardened git note. |
| R6c/R6d | the D6 block's replace/graft and default-branch refusals | D6 block is out of scope (unit 7). The script side: G6 (dropped) and G8 (kept). | Script side only. |

Rows the audit missed or misjudged, kept on purpose:

- **Partial clone in caller variables**: no; `GIT_ALLOW_PROTOCOL=none` still stops any lazy fetch, so dropping `GIT_SHALLOW_FILE` and friends from `caller_gate` leaves the transport closed.
- **`land`'s re-run of `state_gate && default_gate`** right before the ref moves stays: a concurrent session (in scope) can make the repo shallow or create master between the check and the swap. The two W-only `state_gate` runs go: they existed for W's `config.worktree` filter, which is no longer refused, and shallow and partial-clone state is repository-wide.

## Design decisions (divergent design, seeded with H1-H4, S1-S11 and the brief)

**D1. Must the gate's `--merge` still neutralize or refuse a configured merge driver (H1)?**
Options: (A) status quo after this change: the merge is computed in `gate_repo`, landed by `update-ref` of the gate's own commit or `merge --ff-only`; (B) also refuse a `merge.*.driver` key in `--merge` only; (C) also pass `-c merge.verifySignatures=false` and similar to W's fast-forward.
A merge driver runs only on a three-way content merge. `merge-tree` runs in `gate_repo`, whose config is the two-line file the gate writes, in an empty directory with no `.gitattributes`, so no repo config or attribute names a driver there [observed: `gate_repo`; test "--check's merge reads no checkout attributes"]. The landed tree is that tree: `commit-tree` writes it and `update-ref` or `--ff-only` moves the ref to it, and a fast-forward runs no driver. H1 is met by A. B re-adds an honest-config refusal for no case A misses (S1). C changes nothing on the honest path: a `merge.verifySignatures` setting makes the fast-forward fail loudly ("the fast-forward in W failed"), which is H2-correct. **A dominates.** Residual: W's fast-forward runs the owner's own smudge filters (git-lfs) on checkout, as their own `git merge` would.

**D2. G7 and G8(a): origin/HEAD naming another branch; both main and master.**
Options: (A) keep both refusals, loud; (B) take origin/HEAD's branch whatever its name, and let origin/HEAD disambiguate main+master, refusing only when both exist and origin/HEAD names neither; (C) relax only main+master with origin/HEAD disambiguation.
Constraint inputs: the D6 block (out of scope until unit 7) refuses before the gate runs unless exactly one of main and master exists, and it is how the orchestrator reaches the gate at all [observed: SKILL.md D6 block]. So under B or C a repo with both names, or a `develop` repo with no main, still stops at D6: the gate-side relaxation is inert (S6). Worse, under B a repo with `main` and an `origin/HEAD` of `develop` passes D6 (main exists) while the gate lands on `develop`: the cycle's prose and the gate would disagree on the default branch, an H2 failure (one name, two readings). Without origin/HEAD, `resolve_main` takes main silently when both exist; the refusal is what keeps that pick from being silent. The brief's own `state_gate` bullet keeps "a default branch that is not exactly one of main and master". **A dominates now.** The origin/HEAD rule moves from `state_gate` into `default_gate` (one place for default-branch rules), reworded as "the default branch taken is X, not main or master". Revisit when unit 7 moves D6 into the image: B is then the candidate, and it needs the D6 script and the gate to share one resolver.

**D3. `land_cycle` after `store_check`.**
`store_check "$h" "$r"` was also the blob-presence check for the landed merge (merge-tree passes an unchanged side's blob by id without reading it). Options: (A) copy `check_line`'s `cat-file --batch-check` over the merge's changed regular files into `land_cycle`; (B) a shared helper both call; (C) rely on `cyc_blob`'s reads. C reads only the questions files. **B dominates** (S3: one code path per job): `blobs_present TREE` lists the regular files the merge changes against main (the diff-tree records already read) and checks each names a blob in the store.

**D4. `git_harden`'s pins, and safe.directory (K7).**
Classification [observed: lib comment and gate code]:
- Output-stable or correctness pins, kept: `log.date`, `log.showSignature`, `GIT_OPTIONAL_LOCKS`, `GIT_LITERAL_PATHSPECS`.
- Run-no-command pins, kept (H1: no checkout-editable program runs inside the gate, and an honest husky `post-merge` hook should not run during the gate's fast-forward): `core.hooksPath`, `core.fsmonitor`, `commit.gpgSign` (gpg or ssh-keygen could prompt or hang).
- Reproducibility pins, kept: `GIT_CONFIG_GLOBAL=/dev/null` and `GIT_CONFIG_NOSYSTEM` keep the user's `merge.renames`/`directoryRenames` from changing the merge `gate_repo` computes (A17) and `--main-log`'s `clean_merge` re-derives later; `core.useReplaceRefs`/`GIT_NO_REPLACE_OBJECTS` keep real-repo reads and `gate_repo` (which has no refs) reading the same objects; `core.attributesFile`/`GIT_ATTR_NOSYSTEM` keep the real-repo plumbing reads free of outside attributes, as `gate_repo` is.
- Transport, kept: `GIT_ALLOW_PROTOCOL=none` (no network from the gate; a partial clone's lazy fetch fails).
- Anti-forgery only, dropped: `core.commitGraph=false` ("a forged one changes merge bases") and `core.multiPackIndex=false` ("a second route past store_check", which is gone). An honest commit-graph or multi-pack-index only speeds reads.
The equality test against the D6 `G` line and SKILL.md's `hg()` cannot stay exact: both are out of this unit's scope (unit 7, unit 3). Options: (A) change the lines anyway (forbidden); (B) keep the pins (ignores the brief); (C) the test holds each of those lines to carry every `HARDEN` pair and env setting, extra pins allowed. **C**: the two extra pins there are harmless and the next unit to own each line drops them.
safe.directory: `GIT_CONFIG_GLOBAL=/dev/null` stays (reproducibility above), so a repository owned by another uid still needs its safe.directory some other way. A gate-side fix (re-adding the caller's global `safe.directory` values as command-scope pairs, which git honours as protected config) would be inert: the D6 block's `G` and the orchestrator's `hg` also set `GIT_CONFIG_GLOBAL=/dev/null` and run first, and both are out of scope. Recorded for unit 7 rather than built here (S6). In this sandbox the checkout is owned by the session's uid, so nothing hits it today [observed: the repo is owned by `node`, the uid that runs the gate].

## Invariants

- H1: every gate decision still runs from the image copy; the merge still runs in `gate_repo`; no hook or fsmonitor command runs in the gate's git.
- H2: kept checks still fail closed: a shallow or partial clone, an ambiguous or unmodelled default branch, an unreadable config file, a caller variable pointing elsewhere, a missing blob in a landed merge, a dirty or stale checkout for a self-merge. Each refusal still names what went unenforced.
- `--state`'s output grammar (`ok`, or `refuse state WHAT: WHY` lines with exit 2) is unchanged; SKILL.md reads it.
- `land`'s compare-and-swap and its state re-check before the swap stay.

## Prior art

- `gate_repo` (row G11) is the mechanism that already isolates the merge from repo config; this change leans on it rather than adding anything (S3).
- `check_line`'s blob-presence check is the model for D3.

## Gotchas

- Failure-pattern grep: FP-109
  - FP-109 (git checkout restores from the index, so commits survive a reset; cause stale-state): not this area; no implication beyond keeping `git status` the clean-checkout test.
- Grep used: `grep -inE 'state.gate|state_gate|build-loop|git.config|gitconfig|planted|object.store|checkout|harden|safe\.directory|default.branch|origin/HEAD' docs/failure-patterns.md`.
- The D6 block still refuses replace refs and grafts before any script runs; `--state` no longer does. A repo with a replace ref therefore still stops at `refuse d6:` until unit 7. Not this unit's to change.
- `devcontainer-config/install.sh` has its own `git_state_gate` for the host install; it is a different gate (the host-side installer) and is outside this brief.
- Contract items 2 and 3 in the lib header describe what `checkout_gate` checks; they must shrink with it.

## Residual risks (stated, S1)

- A hostile same-uid writer can plant config, hooks dirs, replace refs, grafts or forged objects that the gate no longer refuses. Out of scope; the D6 block's replace/graft refusal and `HARDEN` still cover part of it.
- A caller environment that exports `git -c` pairs (`GIT_CONFIG_PARAMETERS`) is no longer refused: `core.hooksPath=...` there would win over `HARDEN`, and `merge.renames=...` would reach `gate_repo` (callervar keeps the caller's pairs) and change the merge the gate computes. Only a planted shell rc or a deliberate export sets that; SKILL.md tells the orchestrator never to export such settings.
- Review iteration 1 (two reviewers) restored two H2 checks the first cut lost: an origin/HEAD git cannot read refuses again (`default_gate`), and `blobs_present` covers symlink blobs as `store_check` did.
- `docs/working/plan-build-loop-handoff.md` (F25, F51, line 436) still describes the old state gate; it is another unit's working doc, so decision-log row 79 records the amendment instead of editing it.
- A self-merge `--check` from a case-insensitive, sparse or nested-repo checkout: the floor walk reads main's blob for main's paths, so only untracked files are read from the checkout; a nested repository's instruction files are not walked (import walk, unit 6).

## Files read

Last verified: 2026-11-01

docs/working/briefs/2026-11-01-relax-gate-git-state.md
docs/working/research-2026-11-01-restriction-audit.md
docs/constraints.md
docs/failure-patterns.md
docs/decisions/log.md
docs/working/plan-build-loop-handoff.md
scripts/build-loop.sh
scripts/lib/dev-cycle-read.sh
scripts/dev-cycle.sh
skills/dev-cycle/SKILL.md
test/lib/build-loop-fixtures.bash
test/scripts/build-loop-check.bats
test/scripts/build-loop-orchestrator.bats
test/scripts/build-loop-merge.bats
test/scripts/build-loop-dispatch.bats
workflows/research-plan-implement.md
workflows/pr-prep.md
