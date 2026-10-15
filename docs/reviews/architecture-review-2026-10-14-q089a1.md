Commit: f2533b33

# Architecture Review — Q-089 unit A1 (feat/q089a1-host-tool-manifest)

**Scope:** `git diff 4ab9a51f f2533b33`: `devcontainer-config/{cc-isolated.sh,cc-exit-scan.sh,cc-gitdir.sh,install.sh}`, `test/cc-isolated-functions.bats`. Files read with `git show f2533b33:<path>`. Sibling context (not reviewed): A2 `feat/q089a2-cc-push-self-check` (840f39b0, 9bd33e26), B `feat/q089b2-host-tool-gate` (66904a84, 613c0ade), `feat/q089-source-guard` (Q-147).
**Date:** 2026-10-14
**Based on:** `docs/reviews/code-fact-check-report-q089a1.md` (21 verified, 7 mostly accurate, 0 incorrect); trust-boundary labels from `docs/reviews/security-review-2026-10-14-q089a2.md` (Commit: `840f39b0`). That security review predates this diff's head only in the sense that it covers A2, which stacks on it, so its boundaries may be stale for A1.
**Iteration:** 1 of 3 (review-fix loop, `--loop-pass`), full scope.

Scope check: in scope. The diff changes a persisted contract (a new `host-tools.sha256` file, and `manifest.sha256` loses three entries). It also changes a cross-cutting trust pipeline: verify-before-source in the launcher, the bless, and the `--list` reporting. And it adds a function block that is meant to be copied into another entry point.

## Dependency Map

- **`cc-isolated.sh` (launcher, composition root)** owns `config_dir()`, both manifest computations (`enforcement_files`/`compute_manifest`, and the new `host_tool_files`/`compute_host_tools_manifest`), `bless_manifest`, `check_manifest`, and the new `verify_host_tools`. At load time (`:692-702`) it runs `verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh`, then sources `cc-exit-scan.sh`, which sources `cc-gitdir.sh`. `main()` (`:734-758`) turns the check result into a policy: refuse for the scan files, warn for cc-push.
- **`cc-exit-scan.sh` → `cc-gitdir.sh`**: unchanged edges. Only their header comments change.
- **`cc-push.sh` → `cc-gitdir.sh`**: unchanged in A1. The edge is still unchecked at f2533b33 (`cc-push.sh:139-140`). A2 adds the check and a byte-for-byte copy of `verify_host_tools`.
- **`install.sh`**: PAYLOAD and DEST are unchanged, and only a comment changes. Its bless calls the launcher's `--bless`, which now writes both manifests into `config_dir()`.
- **`hooks/live-verify-gate.sh`**: not in the diff. Its regex is a third hand-maintained copy of the file set (enforcement files plus host tools), and unit B splits it.
- **Direction.** The dependency direction improves. Host tools no longer feed `blessed_hash`, which is the container's config identity, so editing a host-side tool no longer invalidates the image or its verified-live receipt. The volatile side (host tools) now depends on the stable side (bless/verify). Before, the stable identity depended on the volatile files.
- **Two roots.** "Where the install is" is now computed two ways. It is `config_dir()` (env or default) for bless, check_manifest and `--list`. It is the resolved script dir (`CC_ISOLATED_DIR`) for the pre-source check and the refusal path. See F1.

## Findings

#### F1. Two notions of "the install dir": the bless writes to `config_dir()`, but the check reads the script's own dir

**Severity:** Coupling
**Location:** `devcontainer-config/cc-isolated.sh:205-217` (host_tools_path / compute_host_tools_manifest), `:233`, `:480-489`, `:695-697`, `:739`, `:747`
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** a reader of `--list` or of a refusal message should be able to tell which directory's state they are reading.

Evidence:

```
host_tools_path() {
  echo "$(config_dir)/host-tools.sha256"
}
```
```
  cfg="$(readlink -f -- "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}" 2>/dev/null || true)"
```
```
  # cc-gitdir.sh. Checked in config_dir(); an entry point checks its own dir,
  # which differs only for a custom install run without CLAUDE_DEVC_CONFIG_DIR.
```
```
    if ! CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" check_manifest; then
```

The bless and `--list` anchor on `config_dir()`. The pre-source check anchors on `CC_ISOLATED_DIR`. The refusal path bridges the two by re-pointing `CLAUDE_DEVC_CONFIG_DIR` at the script dir for one `check_manifest` call, and it prints a bless command that does the same. That makes four places that each reconcile the two roots differently:

- `verify_host_tools` re-derives config_dir's default as a literal. It cannot call `config_dir()`, because the block must be self-contained for the cc-push copy.
- `--list` checks `cfg_real`.
- The refusal path overrides the env var for one `check_manifest` call.
- The normal path's `check_manifest` uses `config_dir()`.

This is the fact-check's recurring "wording issue" (Claims 5 and 8b). It is structural rather than verbal, because no single comment can describe both roots correctly. Probe (temp dir under `jobs/00bcf178/tmp/arch-a1.*`, HOME isolated): I blessed an installed copy at `D` with `CLAUDE_DEVC_CONFIG_DIR=D`, then ran `D/cc-isolated.sh --list` with the variable unset. It reported `launches refuse: no host-tool manifest at …/home/.config/claude-devcontainer/host-tools.sha256`. With the scan tampered, the same unset launch refused on `…/inst/cc-exit-scan.sh changed` and said "The boundary config is unchanged". That verdict is about `D`. The normal path would have read the default dir's manifest, which does not exist. So `--list` and the launch report on different directories, and the refusal's boundary verdict is about a directory the next launch will not check. The fact-check found the converse case too (Claim 8b): a repo-checkout launcher with the variable pointing at an installed dir. There `--list` says "launches refuse" and the launch runs. Both cases are off the nominal path, which is why this is rated Coupling and not Structural. But every future host tool and every message about install state inherits the ambiguity.

**Recommendation:** Give "the install" one owner. For an installed launcher (that is, not the positive repo-checkout case), the trust anchor is the directory the code actually sits in, `CC_ISOLATED_DIR`. Assert that it equals `readlink -f "$(config_dir)"`, and refuse or warn once on mismatch. Then `--list`, the bless, the refusal path and `check_manifest` all read one root, and the `CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR"` override and the comment at `:482-483` can go. The other option is to make `host_tools_path`/`compute_host_tools_manifest` use the script's dir. That keeps two roots, but it at least makes the writer and the reader of host-tools.sha256 agree. The assertion is the cleaner owner because it removes the second notion instead of moving it.
**Security implication:** this touches `B3` from `docs/reviews/security-review-2026-10-14-q089a2.md` (Commit: `840f39b0`; the security review covers A2, so the boundary may be stale for A1): `[caller env CLAUDE_DEVC_CONFIG_DIR/HOME + dir contents] → [repo-checkout exemption] → [check skipped]`. Adding a dir-equality assertion moves where the env var can affect the decision, so the security reviewer should confirm that the repo-checkout exemption still evaluates before the assertion and is not widened by it.

#### F2. The per-entry-point file lists and the refuse/warn policy are spread across the launcher, which also encodes cc-push's own list

**Severity:** Coupling
**Location:** `devcontainer-config/cc-isolated.sh:488-489`, `:494-498`, `:697`, `:743`, `:755-757`; A2's `840f39b0:devcontainer-config/cc-push.sh:188`
**Move:** 7 (coupling surface), 2 (responsibility)
**Confidence:** High
**Legibility-target:** to add a fourth host tool, or to change which entry point refuses on which file, there should be one place to edit.

Evidence:

```
  lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true
  perr="$(verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh)" || true
```
```
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
```
```
      echo "  launches warn (cc-push changed) but run"
```

The launcher's executed set `cc-exit-scan.sh cc-gitdir.sh` is written out twice (`:488`, `:697`). cc-push's executed set `cc-push.sh cc-gitdir.sh` is written out in the launcher (`:489`), and that is knowledge cc-push owns, since A2 writes it again at `cc-push.sh:188`. The policy (the launcher refuses on its own files and warns on cc-push) is spelled out in three places: the refusal branch, the warn branch, and the `--list` prose. This was the prior review's F2 ("three places hold the executed-file list"). A1 keeps the lists at the call sites by design, so the finding stands, and it gets worse with A2. Concrete cost: if cc-gitdir.sh starts sourcing a helper, or cc-push sources a new file, both scripts' call sites and `--list` must change in step, and nothing structural catches a miss. Q-147's source guard is the planned net, and it was split out because grep cannot cover bash.

**Recommendation:** Put the lists inside the byte-copied `verify_host_tools` block, for example `host_tools_executed_by launcher|cc-push`. Then A2's parity test makes the two scripts share one owner for free, `--list` iterates over it instead of restating it, and Q-147 has one function to tie `source` lines to. The refuse/warn policy can stay in `main()`, but `--list` should read it from the same table rather than restate it in prose.

#### F3. A1 does not stand on its own: its comments describe A2/B behaviour, and its intermediate state weakens cc-push coverage

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:192-198`, `:219-221`; `cc-gitdir.sh:4-6`; `cc-exit-scan.sh:4-6`; `install.sh:601-602`; `test/cc-isolated-functions.bats:839-842`; `hooks/live-verify-gate.sh:70-73` (not in the diff, made stale by it)
**Move:** 3 (module boundary, across units)
**Confidence:** High
**Legibility-target:** at any commit on main, the comments should describe that commit.

Evidence:

```
# --- verify_host_tools: KEEP IN STEP with the copy in cc-push.sh (a test
# compares the two byte for byte).
```
```
# container alone. Each entry point checks the ones it executes (verify_host_tools,
# below and in cc-push.sh). Commits that change them carry `Host-tool-tested:`, not
# `Live-verified:` (hooks/live-verify-gate.sh).
```
```
# 71), hashed into host-tools.sha256. Both entry points check it against that
# file before it is sourced: cc-push for itself, the launcher for cc-exit-scan.sh.
```

At f2533b33 alone, the following do not exist: the cc-push copy, the parity test, decision-log row 71 (the log ends at row 70), and the `Host-tool-tested:` trailer. The fact-check confirms this in Claims 1, 2 and 20. The gate hook's comment "The enforcement set: what cc-isolated.sh's enforcement_files() hashes" is now false, because its regex still lists the three host tools that `enforcement_files` dropped. A1 is also a weaker intermediate state than the base, not just an unfinished one. At base, a cc-push.sh or cc-gitdir.sh edit made every launch refuse. Now a cc-push edit only warns, and cc-push still sources cc-gitdir.sh unchecked until A2. The stack (A1 → A2 → B) is coherent. A1 alone on main is not, and landing in the order units finish would expose that window.

**Recommendation:** Treat A1, A2 and B as one landing unit. Merge them together, or merge A1 only with A2 and B already reviewed and queued in the same session, and record that constraint in the merge commit or the Q-089 entry. That beats rewording A1's comments to describe a state that will last for minutes. If A1 must land alone, either keep cc-push.sh in the launcher's refuse set until A2 lands, or reword the forward references as "(after unit A2)" / "(after unit B)".

#### F4. Bless and refusal messages now carry review policy that lives in prose, not data

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:261-268`, `:738-748`
**Move:** 2 (responsibility)
**Confidence:** Medium

Evidence:

```
    local boundary_note="The boundary config is unchanged: after the re-bless, no rebuild or probe is needed."
```

`main()`'s refusal branch now re-runs the boundary check under an env override, checks cc-push again, and assembles the consequences of a re-bless in prose. The fact-check (Claim 10) already found that "no rebuild or probe is needed" overstates the case for a config that was never probed. That is the kind of drift prose policy invites. This is fine at this size. If a third manifest or another entry point arrives, extract a `trust_status` function that returns a status per manifest, and have `--list`, the refusal and the bless all render from it.

## What Looks Good

- **Correct split of identity.** Taking host tools out of `enforcement_files` means `blessed_hash` and the verified-live receipt now track only what the container actually consumes. This fixes a real inversion, where a host-only script's edit used to force a rebuild and a probe. The test at `:869` pins it.
- **Verify before source.** The check runs before `cc-exit-scan.sh`'s top level executes, and on failure the scan is simply not loaded. `--bless`/`--list` still work, so the failure mode degrades instead of deadlocking.
- **PAYLOAD ⊆ enforcement ∪ host, kept disjoint and exact** (bats `:835-849`). Pinning the host list exactly guards against moving a boundary file into the lighter-gated list, which is the most dangerous drift this split creates.
- **Positive repo-checkout marker** (install.sh beside the script, no manifests, not the config dir). This resolves the prior F3: deleting manifests no longer opts an installed copy out.
- **Bless as review.** Both manifests are computed before either moves, the diff for each is shown, and the split-rename window is documented honestly rather than hidden.
- `bless_cmd` keeps the hint aimed at the dir being checked.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Two install-dir roots: bless/`--list` use `config_dir()`, the check uses the script dir | Coupling | `cc-isolated.sh:205-217,233,480-489,695-697,739` | High |
| F2 | Executed-file lists and the refuse/warn policy restated at call sites; the launcher encodes cc-push's list | Coupling | `cc-isolated.sh:488-489,494-498,697,743,755-757` | High |
| F3 | A1 not self-standing: forward references to A2/B, stale gate comment, weaker cc-push coverage in between | Minor | `cc-isolated.sh:192-198,219-221`; `cc-gitdir.sh:4-6`; `live-verify-gate.sh:70-73` | High |
| F4 | Re-bless consequences held in prose in `main()` | Informational | `cc-isolated.sh:738-748` | Medium |

Rubric mapping: F1 and F2 are 🟡 Must Address; F3 and F4 are 🟢 Consider.

## Overall Assessment

A1 improves the structure. The main move, giving host tools their own manifest so the container identity covers only boundary config, corrects a dependency that pointed the wrong way, and its invariants are pinned by tests. The remaining issues can be fixed in place and do not call for restructuring. The most important one is F1. The fact-check's recurring config_dir-vs-script-dir wording problem is a real second notion of "the install", reconciled ad hoc at four sites, and the probe shows `--list` and a launch reporting on different directories. The cleanest owner is the launcher's resolved dir, with an equality assertion against `config_dir()` for installed copies. F2 is the prior review's F2, still open. Its natural home is inside the byte-copied block that A2 introduces, which would also give Q-147 a single target. On stacking (F3): land A1 only together with A2 and B. On its own, A1 leaves cc-push less protected than the base did.

## Goal-Alignment Note

The goal is to review A1 of the Q-089 trust pipeline before it merges, in iteration 1 of 3, full scope. This review covered A1's diff only and used A2/B for context, judging the stacking explicitly as asked. It answers both brief questions. The dir split is structural (F1, with a proposed single owner), and the stacking is acceptable only as a combined landing (F3). Nothing in A1 blocks the stack. F1 and F2 are Coupling-level and could be fixed in this loop or recorded as follow-ups. F2 overlaps Q-147's scope, so fixing it there may be the cheaper route. I made no source edits. The probe ran only under `/home/node/.claude/jobs/00bcf178/tmp/arch-a1.*`, with HOME isolated and every command under `timeout`.
