# Security Review — copy-install Q-058, pass 4 (confirmation of f5e3029)

Commit: f5e3029 (diff 516124d..f5e3029, 207 lines; code read in `/workspace/.claude/wt-q058p2`)
**User goal:** merge the copy-install work to main once review passes; this pass confirms the pass-3 fixes in f5e3029 and checks whether they open anything new.
**Scope:** `devcontainer-config/install.sh` (`links_in` and its three callers, `GIT_EXEC_KEYS_RE` / `git_state_gate`), plus the doc and test hunks of the same commit. I read `dc_unwind`, `tree_hash`, `payload_hash` and the host swap too, because every `links_in` failure now lands in one of them.
**Date:** 2026-09-25
**Based on:** pass-3 review (`security-review-2026-09-25-copy-install-q058-pass3.md`), the pass-3 section of `code-review-rubric-2026-09-24-ans-copy-install-q058.md`, and the commit message.
**Own probes (hermetic: temp HOME/TMPDIR, stubbed pgrep/docker, empty `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_NOSYSTEM=1`, throwaway repos. The real `~/.claude`, `~/.config` and `~/.gitconfig` were never touched):** `docs/reviews/execution-logs/secrev-q058p4/`. `run-all.sh` runs everything. `links-probe.{bats,log}` holds the new `links_in`/`dc_unwind` probes, and `run-links.sh` also runs L9 against 516124d. `hookkeys-probe.{sh,log}` holds the hook-key spellings. The other logs are regression re-runs: `rerun-pass2-probes.log`, `newroutes-probe.{sh,log}`, `global-filter-probe.{sh,log}` and `install-host-suite.log`. git 2.39.5.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator. (Mitigation: I executed every claim that bears on a finding. The logs are cited inline.)

## Trust Boundary Map

```
B1: [checkout .git/config, config.worktree, info/attributes]  → [git_state_gate: GIT_EXEC_KEYS_RE read, --no-includes] → [repo_git calls run as the user]   (hook.* added)
B2: [devcontainer stage in $TMPDIR (same-uid writable)]        → [links_in + tree_hash before review; tree_hash after y] → [cp -Rp into $DEST]
B3: [$DEST ~/.config/claude-devcontainer after the copy]       → [links_in + tree_hash; dc_unwind on any failure]       → [chmod, cc-isolated link, --bless]
B4: [host copies $dest/.cw-new.* (under ~/.claude, denyWrite)] → [links_in + payload_hash before review; hash after y]  → [mv swap into ~/.claude]
```

| Label | Source | Mutability | Trust per sink |
|---|---|---|---|
| S1 | `.git/config`, `config.worktree` keys | runtime-mutable (an agent or a cc-isolated container writes `.git` through the bind mount) | UNTRUSTED for exec sinks (git runs commands the keys name) |
| S2 | `$TMPDIR/cw-devc-stage.*/config/*`, the stage tree | runtime-mutable (any same-uid process) | UNTRUSTED for the install/exec sink (cc-isolated.sh runs on the host) |
| S3 | `$DEST/*` after the copy | runtime-mutable (same-uid; 037 says not in `denyWrite`) | UNTRUSTED for bless/exec. A writer here already owns the installed config (037, C8) |
| S4 | `$dest/.cw-new.*` | runtime-mutable only by a writer to `~/.claude`, which `denyWrite` blocks for agents | trusted-for-availability. Out of scope for integrity (037 C8) |
| S5 | `PAYLOAD`, `CLAUDE_HOME_NAMES`, `GIT_EXEC_KEYS_RE` | code-constant | trusted |

The commit changes two things. The first is the B1 refusal set, which gains `hook.`. The second is how `links_in` fails at B2, B3 and B4: a missing item is now skipped, and a `find` that cannot read a tree makes every caller refuse. That second change puts a new input on the path into `dc_unwind`: a tree that `find` cannot read. Following it showed that `dc_unwind` stops at its first `rm` failure. That is the one finding with a real mechanism (F1). The gap predates f5e3029, but no earlier pass tested it.

## Findings

#### F1: `dc_unwind` dies at its first `rm` failure (set -e). A stage edit that leaves an unremovable tree in `$DEST` keeps an altered `cc-isolated.sh` live behind the `cc-isolated` link, with no ERROR line

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:435-437` (`dc_unwind`), reached from `:562-572`. The claim it breaks is `docs/decisions/037-bare-host-copy-install.md:68`.
**Boundary:** B2 → B3
**Move:** #3 (error path), #11 (bypass of the A1/P2-A2 guard)
**Confidence:** High for the mechanism (executed on f5e3029 and on 516124d). Low for marginal impact: see below.
**Legibility-target:** for-author

**Evidence (verbatim):**

```
dc_unwind() {
  local item
  for item in "${PAYLOAD[@]}"; do rm -rf "${DEST:?}/$item"; done
```

This runs under `set -euo pipefail` (`:26`). `PAYLOAD` is ordered `devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh …` (`:99`), so an `rm` failure on `Dockerfile` ends the script before `cc-isolated.sh` is removed and before the ERROR block prints.

`links-probe.log`, L9. A `$TMPDIR` writer acts after the post-y stage hash, while the copy runs. It turns `stage/Dockerfile` into a directory holding a mode-0555 subdirectory with a file inside, and appends to `stage/cc-isolated.sh`. `cp -Rp` copies both, and `-p` keeps the 0555. `find` can read 0555, so `links_in` passes. `tree_hash` mismatches, so `dc_unwind` runs. Its `rm -rf …/Dockerfile` cannot unlink the file inside the non-writable subdirectory:

```
# rm: cannot remove '<T>/test/1/home/.config/claude-devcontainer/Dockerfile/s/f': Permission denied
# --- left in DEST:
# -rwxr-xr-x 1 node node   64 Sep 25 02:06 cc-isolated.sh
# --- running the cc-isolated link, as the user next would:
# BLESS-STUB --version
# TAMPERED-LAUNCHER
```

No `ERROR:` line is printed. Nothing is blessed, but `$BIN_DIR/cc-isolated` from the previous install still points at the altered script, and the user's next `cc-isolated` runs it on the host. The same probe against 516124d's install.sh gives the same result (`=== install.sh at 516124d … not ok 1 L9`), so **f5e3029 did not introduce this**. It is the same outcome pass 3 escalated (an altered cc-isolated.sh left live, with no ERROR line), reached by a different route. 037:68 says "an altered `cc-isolated.sh` copied before the failure never stays live", and this refutes it. f5e3029 also sends `links_in` find failures here (L5, L5b), where the same `rm` failure loses the message. In L5 and L5b `cc-isolated.sh` is removed first, because only a `$DEST` writer (S3) can make `find` fail there.

**Why only Medium:** the writer needs the stage in `$TMPDIR` during the install. The Q-058 premise and the `agent_gate` just before the post-y hash exclude that, and the write must also race the window between the post-y hash and the copy. Under 037's model such a writer can usually write `~/.config/claude-devcontainer/cc-isolated.sh` directly, so it gains nothing new. That changes only for an agent sandbox that allows `$TMPDIR` writes but denies `~/.config`, which is not verified here. The floor rule still applies: this is a named mechanism that defeats the stated A1/P2-A2 guarantee.

**Recommendation:** Make `dc_unwind` best-effort and complete. Remove `cc-isolated.sh` (and the `$BIN_DIR/cc-isolated` link) first, run `chmod -R u+w` before each `rm -rf` and add `|| failed+=…`, then always print the ERROR block (naming anything left) before `exit 1`. Add L9 as a regression test.

#### F2: The new `links_in` comment and commit message say a missing item is "left to the hash check that follows". At two of the three sites the hash does not catch it; a later step does

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:653-655`, and the f5e3029 commit message ("the hash check that follows catches it as a mismatch")
**Boundary:** B2, B4
**Move:** #2 (implicit assumption)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence (verbatim):** `# A missing item holds no link and is left to the hash check that follows;`. Before the review, the hash is taken *of* the missing state (`:505`, `:853`), so it cannot mismatch. What catches it is the copy or the swap:

- L1 (stage, middle item): `ERROR: could not copy 'cc-isolated.sh' into …` → `dc_unwind`.
- L6/L7 (host copy missing): the review shows the whole entry as deleted (`-#!/bin/bash` …). After y the hash matches, and `mv "$dest/.cw-new.$name"` (`:1002`) fails: `ERROR: the install failed part-way and was rolled back`. `snap` shows the destination byte-identical.
- L2 (stage, last item): `status=1` with no ERROR line. `tree_hash`'s last-iteration `find` fails under pipefail, so `reviewed_hash="$(…)"` ends the script silently.

Only at `$DEST` (L4, T85) is it the hash. Every path fails closed. The wording overstates which mechanism does the work, and a future edit that relies on it could open a path.

**Recommendation:** Reword to "a missing item is caught by the copy (stage), the swap (host) or the hash (`$DEST`)". Optionally, have L2's case print a message.

#### F3: A `find` read failure is reported as "symlinks appeared …" and can leave an unremovable `.cw-new.*` behind

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:495-503`, `:842-851`
**Boundary:** B4 (B2 has the same text)
**Move:** #3
**Confidence:** High (executed, L3/L8)
**Legibility-target:** for-author

**Evidence (verbatim, L8):**

```
# ERROR: symlinks appeared in the copies to install after the payload's link check:
#          (the symlink check could not read every item)
# --- .cw-new.* left:
# <T>/test/9/home/.claude/.cw-new.skills
```

The refusal is correct: nothing was installed and the exit status is 1. But the heading says links appeared when none did, and `rm_new_copies`' `|| true` leaves the unreadable copy in place. The next run's `rm -rf "$dest/.cw-new.$name"` (`:827`) then fails under set -e, silently. This is reachable only by a writer to `~/.claude` (S4, out of scope per 037 C8), so it is an availability and clarity issue, not a security one.

**Recommendation:** Use a separate heading for the read-failure case ("could not check … for symlinks"). No hardening is needed.

## Judgement on the three questions

1. **`links_in`.** Skipping a missing item opens no install or bless path in any probe. At every site the missing item is caught downstream (F2 lists where). Every `find` failure becomes a refusal (L3, L8), or goes to `dc_unwind` (L5, L5b). No probe reached a bless. Host `.cw-new.` site: a copy missing *before* the review is hashed as missing, so the hash does not catch it. Nothing is swapped in for it: `mv` fails and `host_rollback` restores every entry (L6, L7). A copy removed *after* the review is a hash mismatch. Devcontainer stage site: a missing item before the review ends in `could not copy` → `dc_unwind` (L1), or in a silent exit if it is the last item (L2). **The one path that ends with an unreviewed file live is F1.** It is pre-existing, and it runs through `dc_unwind`, not through `links_in`.
2. **`hook.*`.** It covers every spelling I could write (`hookkeys-probe.log`). `git config --get-regexp` matches against the canonical key: the section name is lower-cased and the subsection keeps its case. So `[HOOK "X"] COMMAND`, `[Hook "x"] Event`, legacy `[hook.x]`, `[hook]` with no subsection, a dotted or empty subsection, leading whitespace, a key on the section line, a continuation line, a bare boolean and `config.worktree` in a linked worktree are all listed (gate rc=0). The controls `[hooks "x"]` and `core.hooksPath` are correctly not listed, and `includeIf` is. The refusal is broader than git's hook config needs (it refuses `hook.x.enabled`), which fails closed.
3. **Pass-3 harness re-run against f5e3029.** It is unchanged from pass 3 (`rerun-pass2-probes.log`): SP1–SP1e, SP3b–d and A1b do not land, and SP3a, A1 and R2x keep their safe outcome. `newroutes-probe.log` §1 now shows the gate listing `hook.post-index-change.command` (at 516124d it listed nothing). §2–§6 are unchanged and clean. `global-filter-probe.log` still shows `archive marks: GLOBAL-SMUDGE-RAN`. That is P3-1, which 037 now names as an accepted residual. Author suite `test/install-host.bats` at f5e3029: **85/85**, `bats exit=0` (`install-host-suite.log`), including T84 and T85.

### Untested bypass candidates

- **Config-based hooks on git ≥ 2.54:** whether they actually run under `repo_git`'s flags, and whether 2.54 reads hook config from any key outside `hook.*`. Only git 2.39.5 is available here, and the web source could not be opened (carried from pass 3, P3-3).
- **Hook keys from the user's own global/system config or from `GIT_CONFIG_COUNT`/`GIT_CONFIG_PARAMETERS` in the user's shell:** not read by the gate. This is the accepted 037 residual ("the user's own global or system git config").
- **`$TMPDIR` writable but `~/.config` not writable for a sandboxed bare-host agent:** this decides F1's marginal impact. It needs the host's sandbox settings, which I could not see.

## Endorsement Claims

- **Claim:** At f5e3029, a missing PAYLOAD item or unreadable tree at the stage or `$DEST` site never reached `--bless` in probes L1–L5b.
  **Location:** `devcontainer-config/install.sh:495-572`
  **Evidence:** executed (`links-probe.log` L1–L5b: `status=1`, no `BLESS-STUB`)
  **Verified:** the six scenarios, with the `cp` stub acting at the named moments.
  **Not verified:** a failure injected into `chmod`/`ln` after the hash check (`:574-577`).
  **route: code-fact-check**
- **Claim:** A missing host copy before the review leaves `~/.claude` byte-identical after a y.
  **Location:** `devcontainer-config/install.sh:842-1003`
  **Evidence:** executed (L6, L7: `snap` before = after, `rolled back`)
  **Verified:** a middle name (hooks) and the last name (scripts).
  **Not verified:** a missing `.cw-new.manifest`, the `sha256sum <` path in `payload_hash`.
  **route: code-fact-check**
- **Claim:** `git_state_gate` lists every `hook.*` spelling in the eleven shapes tested, in `config` and in `config.worktree`.
  **Location:** `devcontainer-config/install.sh:197-211`
  **Evidence:** executed (`hookkeys-probe.log`), plus T84 in the author's suite.
  **Verified:** git 2.39.5's parser output and the gate's exact read command.
  **Not verified:** git ≥ 2.54's hook-config key set (see Untested bypass candidates).

## Primitive sweep

Primitive: `rm -rf` on an install path (engaged by F1)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:437` `dc_unwind` | S2→S3 tree | none (set -e aborts) | **F1** |
| `:557` copy loop `rm -rf "${DEST:?}/$item"` | S3 | `\|\| copy_failed` | cleared: a failure goes to `dc_unwind` (then F1 applies) |
| `:827` `rm -rf "$dest/.cw-new.$name"` | S4 | none | F3 (reachable only by a `~/.claude` writer) |
| `rm_new_copies` | S4 | `\|\| true` | cleared: best-effort by design |
| `host_rollback` `rm -rf "${dest:?}/$n"` | S4 | none | cleared: S4 is out of scope (037 C8) |
| `host_cleanup` `rm -rf "$HOST_TMP"`/`"$DC_TMP"` | S2/S4 | `\|\| true` | cleared (L9 shows the stage `rm` failing harmlessly) |

Primitive: `find` over a tree (`links_in`, `tree_hash`). `links_in` is now fail-closed at all three callers (L3, L5, L8). `tree_hash` swallows a `find` failure except on the last item (F2, L2). Cleared: no probe turned a `find` failure into an install.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | `dc_unwind` dies at its first `rm` failure; an altered `cc-isolated.sh` stays live, no ERROR (pre-existing, not from f5e3029) | Medium | B2→B3 | `install.sh:435-437` | High (mechanism) / Low (marginal impact) |
| F2 | `links_in` comment and commit message credit the hash for catching a missing item; the copy or swap does | Informational | B2, B4 | `install.sh:653-655` | High |
| F3 | A read failure is reported as "symlinks appeared"; an unreadable `.cw-new.*` is left | Informational | B4 | `install.sh:842-851`, `:827` | High |

## Overall Assessment

f5e3029 does what it claims, and it opens nothing new. The pass-3 escalation route is closed: T85 and my L4 show that a missing item after the copy now unwinds, with a message. A `find` failure is a refusal at every caller. `hook.*` is refused in every spelling git 2.39.5's parser accepts. The pass-3 harness is unchanged apart from the gate now listing the hook key. Following the new failure path into `dc_unwind` found **F1**, a pre-existing gap that 516124d already had. When one of `dc_unwind`'s `rm` calls fails, it stops before removing `cc-isolated.sh` and before printing its ERROR. A same-uid `$TMPDIR` writer that races the copy can therefore leave an altered launcher behind the existing `cc-isolated` link. That is the pass-3 outcome by another route, and it contradicts 037:68. It is Medium, not High. It needs a writer active during the install, which the Q-058 premise and gate exclude, and it grants nothing beyond what 037 already concedes to a writer of `~/.config/claude-devcontainer`. The fix is small and local: make `dc_unwind` best-effort, removing `cc-isolated.sh` and the link first and always printing the message. **No finding is High or above; merge is not blocked on security grounds**, though F1 is worth fixing before merge because it contradicts a documented guarantee. Endorsement claims marked `route: code-fact-check` are pending execution verification; no findings beyond these within the code paths read.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to /workspace/docs/reviews/security-review-2026-09-25-copy-install-q058-pass4.md, per the skill.
- Answered: yes. (1) `links_in`: no install or bless path from a missing item or a find failure. The one live-launcher path (F1) is in `dc_unwind`, predates f5e3029, and was executed on both commits. (2) `hook.*`: every shape is covered (11 spellings plus `config.worktree`). (3) The pass-3 harness is unchanged at f5e3029.
- Out of scope: git ≥ 2.54 behaviour (not available here), global/system/env git config (accepted 037 residual), writers to `$DEST` or `~/.claude` (037 C8).
- Escalate: F1. Either fix `dc_unwind` before merge, or correct 037:68's "never stays live" and accept it as a residual. That is the user's call. There is also a you-terminal check: can a sandboxed bare-host agent write `$TMPDIR` but not `~/.config`? The answer decides F1's marginal impact.
- Decisions I made: I rated F1 Medium, not High, because it needs a writer active during the install that the gate and premise exclude, and it grants nothing beyond 037's conceded `~/.config` write. I reported it here even though it predates f5e3029, because the commit's new failure route leads into it and it contradicts the guarantee this commit restores. I ran my own probes as a separate bats file and did not edit the author's suite.
