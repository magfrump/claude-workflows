Commit: 516124d

# Security Review: ans/copy-install Q-058 pass 3 (terminal) — fix commits `f8d3f78..516124d`

**User goal:** merge the copy-install work to main once review passes. This is pass 3 (terminal) of the review-fix loop.
**Scope:** the pass-2 fix commits `f8d3f78..516124d` (99656a2 P2-R1, 21bf405 P2-R2, fa25f13 P2-R3/P2-A1, b58d671 P2-A2, e61408f P2-A3, d71715f P2-A4/P2-A5, 767f421 P2-C2/C3, 516124d docs). The host and devcontainer targets are judged whole at 516124d (`install.sh` is 1193 lines). Code read at 516124d in `/workspace/.claude/wt-q058p2`.
**Date:** 2026-09-25
**Based on:** pass-2 security review `security-review-2026-09-25-copy-install-q058-pass2.md` (N1–N6); pass-2 rubric `code-review-rubric-2026-09-24-ans-copy-install-q058.md` §"Pass 2" (P2-R1/R2/R3, P2-A1–A5, P2-C1–C5); decision `docs/decisions/037-bare-host-copy-install.md`; Q-058 (answered [2], archive), Q-061 and Q-062 (open).
**Own probes (hermetic: temp HOME/TMPDIR, stubbed pgrep/docker, empty `GIT_CONFIG_GLOBAL`, `GIT_CONFIG_NOSYSTEM=1`, throwaway repos; the real `~/.claude`, `~/.config` and `~/.gitconfig` were never touched):** `docs/reviews/execution-logs/secrev-q058p3/`. Holds `rerun-pass2-probes.log` (the unchanged pass-2 suite re-run against 516124d), `install-host-suite.log` (the author's 83-test suite), `newroutes-probe.{sh,log}` (six new command-running routes), and `global-filter-probe.{sh,log}`. git 2.39.5.

> ⚠️ **A code fact-check report exists for pass 2** (`code-fact-check-report.md`, 43 claims: 37 Verified, 4 Incorrect) but was produced against feba07d, not the 516124d fix commits under review here. Claims about security properties in the new commits' comments and docs are verified below by direct probe, not by that report.

No HALT escalation patterns matched.

---

## Answer on the two pass-2 reds (key judgment)

**P2-R1 (R1: checkout git state runs commands): RESOLVED on git 2.39.5.** The fix routes every checkout git call through `repo_git` (`install.sh:169-171`): `git --no-optional-locks -C "$REPO_ROOT" -c core.hooksPath=/dev/null -c core.fsmonitor=false`, plus `--ignore-submodules=all` on both `status` calls (`:333-334`). Re-running the unchanged pass-2 probes against 516124d:
- **SP3b** (`.git/hooks/post-index-change`): assertion `[ -e "$S/hook-ran" ]` now **fails** — the hook does not run; the install proceeds and blesses. `--no-optional-locks` removes the index write that would fire it, and `core.hooksPath=/dev/null` covers the path.
- **SP3c** (`core.hooksPath` hook): `[ -e "$S/hookspath-ran" ]` now **fails** — neutralised.
- **SP3d** (submodule git dir's clean filter + hook): `[ -e "$S/sub-clean-ran" ] || [ -e "$S/sub-hook-ran" ]` now **fails**; `markers:` is empty. `--ignore-submodules=all` stops the recursion.
- **SP3a** still refuses a local `filter.*`+`info/attributes` and a local `core.fsmonitor` before git runs them (no marker) — unchanged, still correct.

My own new-route probes (`newroutes-probe.log`) find no surviving exec route on git 2.39.5: config-based hooks (`hook.<event>.command`), a `.git` **gitfile** pointing at a planted git dir, `GIT_DIR`/`GIT_WORK_TREE` inherited from the shell, and `archive` `export-subst` all run **no** command under `repo_git`'s flags. The gate's own `git config --file … --no-includes` correctly lists an `include.path` (so it is refused) without following it.

**P2-R2 / P2-R3 / P2-A1 (R2: host review = install): RESOLVED.** The host target now takes the lock first and stages entirely under `$dest` (`mktemp -d "$dest/.cw-stage.XXXXXX"`, `:807-813`); the copies (`.cw-new.*`), their source stage, and the old-side review view (`$HOST_TMP/installed`, now under `$dest`, `:896`) all sit behind the destination, which `denyWrite` covers for the default `~/.claude`. Re-running the pass-2 probes:
- **SP1 / SP1b / SP1c / SP1d**: `[ -f "$S/helper.done" ]` / `[ -s "$S/helper.hits" ]` now **fail** — the `$TMPDIR/cw-host-stage.*` the writers watched no longer exists, so none of the swap-, old-side-rewrite-, stage-edit- or link-plant races can land. Confirmed by the author's T80/T81/T82 passing.
- **P2-R2 link plant, both targets**: a symlink appearing in the host copies (`links_in` at `:833`) or in the devcontainer stage (`:494`) / `$DEST` (`:563`) is now refused/unwound at every hash site. **SP1e** now aborts with `ERROR: symlinks appeared in the staged devcontainer config after its link check` — the pass-2 High (a blessed `cc-isolated.sh` link) is closed.
- **P2-A2 (A1 fail-open)**: **A1b** — the altered launcher no longer stays live. The copy loop routes a `cp` failure through `dc_unwind` (`:555-562`, `:434-445`); the run exits 1 with `could not copy 'egress'` and no `BLESS-STUB`. `grep -q TAMPERED-LAUNCHER` no longer holds.

The author's full suite is green at 516124d: **83/83** (`install-host-suite.log`), including T75/T76 (P2-R1), T77–T79 (P2-R2), T80–T82 (P2-R3/A1) and T83 (P2-A2).

**Merge verdict on the pass-2 reds:** both are closed. One **new Medium** remains (P3-1 below), plus two informational hardening notes. **No finding is High or above.**

---

## Trust Boundary Map

```
B1: checkout .git state (config, config.worktree, info/attributes, hooks/, modules/*/) + committed .gitattributes + HEAD blobs
      → git_state_gate (:198-240) + repo_git flags (:169-171, --ignore-submodules on :333-334) → archive/status exec as host user
B2 (moved p2): host stage+copies now under $dest/.cw-stage.* and $dest/.cw-new.* (denyWrite for default ~/.claude)
      → extract_commit link/NUL checks (:279-304) + links_in at every hash site (:833) → payload_hash (:843,:955) → mv swap (:981-994)
B3 (moved p2): host review old-side view $HOST_TMP/installed, now under $dest (:896)
      → diff -ruNa (:926) → the human's review
B4: user's global git config ~/.gitconfig + committed .gitattributes (agent-writable; NOT in denyWrite ~/.claude)
      → git archive smudge (:267) exec as host user, before the review
B5: devcontainer stage $DC_TMP/config in ${TMPDIR:-/tmp} (same-uid writers; 037 leaves to the gate)
      → tree_hash (:503,:538,:567) + links_in (:494,:563) → $DEST → chmod/ln/--bless (:571-577)
B6: host process table + docker daemon → agent_gate (startup :1182, pre-host-stage :748, post-y :536/:953) → permission to stage/install
```

**Input-source classification**

```
S1: committed payload (HEAD objects)              — runtime-mutable (agents commit) — UNTRUSTED for content; the review is the control
S2: local .git state (config, config.worktree, info/attributes, hooks/, modules/*/)
                                                   — runtime-mutable (host agents; cc-isolated bind mount)
                                                   — was UNTRUSTED toward exec sinks; now neutralised by repo_git + gate (P2-R1)
S3: committed .gitattributes (repo root)           — runtime-mutable (agents commit; NOT read by git_state_gate) — UNTRUSTED: can assign a filter driver
S4: ~/.gitconfig global filter driver              — runtime-mutable by any same-uid process (NOT denyWrite ~/.claude) — UNTRUSTED toward archive's smudge exec
S5: $dest/.cw-stage.* and .cw-new.* copies         — writable only by writers of $dest (denyWrite for default ~/.claude) — trusted to the extent denyWrite holds
S6: $DEST devcontainer stage in $TMPDIR            — mutable by any same-uid writer during the run — UNTRUSTED toward install/bless; bounded by the gate (037, accepted)
S7: pgrep/docker output; HOME, TMPDIR, CLAUDE_*_DIR, PATH — self-chosen argv / user's terminal — presence evidence / deploy-time trusted
```

The pass-2 fixes moved the host target's whole review-and-install surface (B2, B3) under `$dest`, so a `$TMPDIR` writer can no longer reach it, and neutralised the checkout `.git` exec routes (B1, S2). What remains outside every gate is B4: a committed `.gitattributes` (S3) plus a global filter driver (S4) makes `git archive` run a command as the user, before the review, and `git_state_gate` reads neither.

---

## Findings

#### P3-1: `git archive` runs a global filter driver assigned by a committed `.gitattributes`; `git_state_gate` checks neither

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:267` (`repo_git … archive` in `extract_commit`), `:197` (`GIT_EXEC_KEYS_RE`), `:198-226` (`git_state_gate` reads only local config/`config.worktree` and `.git/info/attributes`); `docs/decisions/037-bare-host-copy-install.md` (Trust model, "Residuals accepted", git-state bullet)
**Boundary:** B4
**Move:** #1 (runtime-mutable ⇒ compromise-reachable), #2 (implicit sanitization assumption), #11, #12
**Confidence:** High for the mechanism (executed, `global-filter-probe.log`: `archive marks: GLOBAL-SMUDGE-RAN` while the gate's read is empty and `info/attributes` is absent). Medium for reach (needs a write to `~/.gitconfig`, which is outside `denyWrite ~/.claude`, plus a committed `.gitattributes`).
**Legibility-target:** for-author

**Evidence (verbatim, `global-filter-probe.log`):**
```
git_state_gate local-config/attributes read (empty = gate passes):
  .git/info/attributes non-empty: no
archive marks: GLOBAL-SMUDGE-RAN
```
The probe sets `[filter "pwn"] smudge = …` in `GIT_CONFIG_GLOBAL` (standing in for `~/.gitconfig`), commits `skills/a.txt filter=pwn` as `.gitattributes`, then runs install.sh's exact `git --no-optional-locks -C … -c core.hooksPath=/dev/null -c core.fsmonitor=false -c tar.umask=022 archive --format=tar HEAD -- skills | tar`. The smudge command runs as the user.

`git_state_gate` refuses a `filter.*` driver in **local** config (`:197`, `:200-217`) and a non-empty `.git/info/attributes` (`:224-226`). It does **not** read the committed `.gitattributes` in the working tree/HEAD, and it does **not** read the user's global config. So the two halves of the attack each sit in a blind spot: the attribute assignment is committed (S3, agent-writable, not `info/attributes`), and the driver is global (S4, not local). `git archive` runs during `assemble` → `extract_commit`, **before** the review, so the review never sees it — and `.gitattributes` at the repo root is not even a payload path, so it would not appear in the diff regardless. The no-agent gate (B6) is irrelevant: both inputs are persistent, so the writer need not be running at install time — the same property that made pass-2 N1 (hooks) a gate-immune path.

**Why Medium, not High.** Unlike pass-2 N1/N2 (closed here), this is **not** reachable from an *isolated* cc-isolated container: that container's `~/.gitconfig` is not the host's (only the checkout is bind-mounted), so an isolated agent can commit the `.gitattributes` but cannot plant the global driver. It needs a **bare-host** agent with write access to `~/.gitconfig`. Such an agent — contained only by `denyWrite ~/.claude` — already has many equivalent host-exec persistence routes (`~/.bashrc`, `~/.profile`, `~/.config/systemd/user`, a cron entry), so this grants essentially no new capability against that threat model, and it injects no unreviewed content into `~/.claude`. Decision 037 already lists "the user's own global or system git config" as an accepted residual. The gap this finding sharpens is that 037 frames global config as *the user's own* (trusted), whereas `~/.gitconfig` is runtime-mutable by any same-uid process (move #1), and that `git_state_gate`'s `info/attributes` check has a **committed-`.gitattributes` blind spot** the docs do not mention. It is filed Medium under the floor rule (a named, executed mechanism in a reachable environment; environmental unlikelihood lives in Confidence), not to reopen the merge.

**Recommendation:** Either (a) accept explicitly and correct 037: add "a committed `.gitattributes` assigning a filter driver defined in the user's global/system git config" to the git-state residual, and stop calling the global config purely "the user's own" — note it is agent-writable unless the sandbox extends `denyWrite` to `~/.gitconfig`; or (b) harden: have `extract_commit`/`assemble` run `git archive` with a neutralised attributes path (e.g. `-c core.attributesFile=/dev/null` does not cover committed `.gitattributes`, so instead check `repo_git check-attr -a --cached -- <paths>` for a `filter` assignment, or archive with the smudge disabled). (a) is consistent with the Q-058 [2] model and needs no code; (b) closes the one install-required program's exposure. This does not block merge.

#### P3-2: Devcontainer target still stages in `$TMPDIR`; a plain content swap-and-revert during the review is caught only by the gate (accepted under Q-058 [2])

**Severity:** Informational
**Location:** `install.sh:473-476` (`DC_TMP` stage in `${TMPDIR:-/tmp}`), `:487-503` (pre-review hash + link check), `:538` (post-y hash); `037` devcontainer bullet
**Boundary:** B5
**Move:** #4 (TOCTOU), #11
**Confidence:** High (read-static; the link variant SP1e is now closed, verified above; the content variant is the documented residual)
**Legibility-target:** for-orchestrator-synthesis

The link-plant variant on the devcontainer stage (pass-2 N2 / SP1e) is closed by `links_in` at `:494` and `:563`. What remains is a same-uid writer that edits the `$TMPDIR` stage to benign content for the review and restores the malicious content before the `y` — the pre-review `tree_hash` (`:503`) is taken *before* the swap and the post-y hash (`:538`) *after* the restore, so both match. This is exactly the residual decision 037 states for the devcontainer target ("It does not catch a stage swapped for the review and swapped back before the y, because the stage stays in `$TMPDIR`. For that case, target 1 relies on the gate alone"), and it is bounded by the no-agent gate under the user's Q-058 [2] answer. `~/.config/claude-devcontainer` is not in the documented `denyWrite`, so staging it there would buy nothing (037). **Amber/accepted, not red.** It is honestly documented and correctly scoped; I record it only to answer judgment 3 explicitly.

**Recommendation:** None required. It is consistent with Q-058 [2]. If Q-061 is ever generalised to the devcontainer target, revisit.

#### P3-3: Config-based hooks (`hook.<event>.command`) and the global-filter route are unverified on git versions newer than 2.39.5

**Severity:** Informational
**Location:** `install.sh:169-171` (`repo_git`), `docs/decisions/037` git-state bullet ("none of 17 further keys probed on git 2.39.5 fired")
**Boundary:** B1, B4
**Move:** #11
**Confidence:** Medium (host git version unknown; 2.39.5 clean)
**Legibility-target:** for-author

On git 2.39.5, `hook.<event>.command` runs no command under `repo_git` (`newroutes-probe.log`, section 1: `hook.*.command marks: none`), and `--no-optional-locks` removes the `post-index-change` trigger regardless. `hook.` is not in `GIT_EXEC_KEYS_RE`, so on a git that honours config-based hooks the defence rests entirely on `core.hooksPath=/dev/null` and `--no-optional-locks`. Both should hold, but neither is verified on the host's actual git. This is defence-in-depth, not a live gap on the tested version.

**Recommendation:** None blocking. Optionally note in 037 that the git-state probe is version-specific (2.39.5) and that config-based hooks rely on `core.hooksPath=/dev/null` + `--no-optional-locks`.

---

## Untested bypass candidates

| Candidate | Guard | Why not tested |
|---|---|---|
| git-lfs custom transfer agent via committed `.lfsconfig` + global `filter.lfs` | B1/B4 | git-lfs not installed here; carried from pass 2. The plain global-filter route (P3-1) is the executed general case. |
| Config-based hooks on a git newer than 2.39.5 | `core.hooksPath=/dev/null`, `--no-optional-locks` | Only 2.39.5 available (P3-3). |
| A submodule as an embedded `<path>/.git` directory rather than `.git/modules` | `--ignore-submodules=all` | Only the `.git/modules` layout re-run; `--ignore-submodules=all` should cover both (it stops entry into any submodule), not separately verified. |
| A writer planting `.git` state between `git_state_gate` and `archive`/`status` in the same `assemble` | one gate per assemble | The accepted "between checks" residual (037); needs an active writer, which Q-058 [2] excludes. |
| A real race (no cp stub) for P2-A2 and the swap window | `dc_unwind` / post-y hash | Executed only with a `cp` stub, as the author's T83 does. |
| Bare-host reach: can sandboxed Bash write the terminal's `$TMPDIR`, `/tmp/cw-*`, or `~/.gitconfig`? | P3-1/P3-2 reach | Carried from pass 1/2; needs the real bwrap host. Decides P3-1's Confidence. |

Because of these, `git_state_gate`, the devcontainer `$TMPDIR` stage, and the git-version-specific defences are not asserted as clean guardrail claims below.

---

## Endorsement Claims

- **Claim:** at 516124d, a planted `.git/hooks/post-index-change`, a `core.hooksPath` hook, and a submodule git dir's clean filter and hook do not run during either target's git calls; the install proceeds.
  **Location:** `install.sh:169-171`, `:333-334`
  **Evidence:** executed (SP3b/SP3c/SP3d re-run, `rerun-pass2-probes.log`; author T75/T76)
  **Verified:** the SP3b/c/d assertions that a marker fired now fail; `markers:` is empty; the install blesses.
  **Not verified:** git versions newer than 2.39.5 (P3-3), and config-based hooks on such a git.
- **Claim:** the host target's stage, copies, and review old-side view all live under `$dest`; a same-uid writer in `$TMPDIR` cannot swap the stage, rewrite the old side, edit between archive and copy, or plant a link that installs.
  **Location:** `install.sh:807-813`, `:817-843`, `:896`, `:955`
  **Evidence:** executed (SP1/SP1b/SP1c/SP1d re-run all now fail to land; author T80/T81/T82)
  **Verified:** `$TMPDIR/cw-host-stage.*` no longer exists; `helper.hits`/`helper.done` empty; the committed payload is what installs.
  **Not verified:** whether sandboxed Bash can write inside `$dest` when `CLAUDE_HOME_DIR`/`CLAUDE_CONFIG_DIR` points outside the denyWrite path (037 caveat).
  **route: code-fact-check**
- **Claim:** a symlink appearing after `extract_commit`'s check is refused at every hash site on both targets; no blessed `cc-isolated.sh` link and no live `~/.claude` hook link results.
  **Location:** `install.sh:494-502`, `:563-566`, `:833-842`
  **Evidence:** executed (SP1d/SP1e re-run now abort/refuse; author T77–T79)
  **Verified:** SP1e aborts with `symlinks appeared in the staged devcontainer config`; SP1d cannot land (no `$TMPDIR` stage).
  **Not verified:** a link planted inside `$dest` between the post-y hash (`:955`) and the `mv` swap (`:992`) — a window inside denyWrite, not exercised.
- **Claim:** a `cp` failure in the devcontainer copy loop unwinds like a mismatch (all PAYLOAD items removed, no chmod/link/bless), so an altered launcher does not stay live.
  **Location:** `install.sh:555-562`, `:434-445`
  **Evidence:** executed (A1b re-run; author T83)
  **Verified:** the run exits 1 with `could not copy 'egress'`, no `BLESS-STUB`, no `TAMPERED-LAUNCHER` left.
  **Not verified:** a real race (no cp stub) hitting the same window.
- **Claim:** the only git invocations on the checkout are `repo_git` (`:170`) and `git_state_gate`'s single-file `git config --file … --no-includes` read (`:209`); the latter runs no filter, hook, or fsmonitor and does not follow includes.
  **Location:** `install.sh:169-171`, `:209`
  **Evidence:** executed (`newroutes-probe.log` §6: `should-not-run marks: none`; the gate lists `include.path` without following it) + read-static grep of the file
  **Verified:** no bare `git` call outside those two; the `--file` read is include-safe.
  **Not verified:** `cc-isolated.sh --bless` (`:577`), which runs after staging and was not traced for git calls on the checkout.
  **route: code-fact-check**

---

## Primitive sweep

**Primitive: git invocation on the checkout (exec through config, attributes, hooks, submodules, global filter)**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:170` `repo_git` (rev-parse/cat-file/archive/status) | S2 | `--no-optional-locks -c core.hooksPath=/dev/null -c core.fsmonitor=false`; gate | cleared for local `.git` exec (SP3a/b/c/d re-run) |
| `:267` `repo_git … archive --format=tar` | S1, S2, **S3+S4** | gate (local filter/attributes only) | **P3-1** (committed `.gitattributes` + global filter driver) |
| `:333`, `:334` `repo_git … status … --ignore-submodules=all` | S2 | gate; flags; `--ignore-submodules=all` | cleared (SP3b/c/d re-run) |
| `:209` `git config --file … --no-includes --get-regexp` | S2 | `--file`, `--no-includes`, `-c core.hooksPath=/dev/null` | cleared (`newroutes-probe.log` §6) |

**Primitive: copy from a staged tree into an install location**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:820` `cp -Rp "$stage/$name" "$dest/.cw-new.$name"` | S5 (now under `$dest`) | `links_in` :833; `payload_hash` :843/:955 | cleared (SP1b/c/d re-run cannot land) |
| `:824` `cp -p .manifest` | S5 | `payload_hash` covers manifest bytes | cleared |
| `:485`, `:556` devcontainer `cp -Rp` | S6 | `links_in` :494/:563; `tree_hash` :503/:538/:567; `dc_unwind` | cleared for links (SP1e) and cp failure (A1b); content swap = P3-2 (accepted) |
| `:915` `cp -RH "$dest/$name" "$view/$name"` (review old side, now under `$dest`) | S5 | under `$dest` | cleared (SP1b re-run) |

**Primitive: `rm -rf` added/moved by the fixes**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:807` `rm -rf "$dest"/.cw-stage.*` (stale stage, under the lock) | S5, fixed prefix | lock held; link's target survives (no trailing slash) | cleared (author T82) |
| `:436` `dc_unwind` `rm -rf "${DEST:?}/$item"` | S7 DEST, code-constant PAYLOAD | `:?` | cleared |
| `:672` `rm_new_copies` / `:693` `host_cleanup` / `:703` `host_rollback` | lock-owner only (`HOST_NEW_IN` :796) | lock | cleared |
| `:818`, `:1023` copy-loop / prune `rm -rf` | fixed names / newline+TAB skip (:1029) | `:?` / TAB guard (A3) | cleared (author T73) |

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| P3-1 | `git archive` runs a global filter driver assigned by a committed `.gitattributes`; the gate checks neither | Medium | B4 | `install.sh:267,:197,:198-226`; 037 | High (mech) / Medium (reach) |
| P3-2 | Devcontainer `$TMPDIR` stage: plain content swap-and-revert caught only by the gate (accepted under Q-058 [2]) | Informational | B5 | `install.sh:473-476,:503,:538`; 037 | High |
| P3-3 | Config-based hooks / global-filter route unverified on git > 2.39.5 | Informational | B1, B4 | `install.sh:169-171`; 037 | Medium |

## Overall Assessment

The two pass-2 reds are closed at 516124d, and I verified both by re-running the pass-2 probe harness unchanged: P2-R1's `repo_git` flags neutralise the hook, `core.hooksPath` and submodule routes (SP3b/c/d no longer fire), and the host target's move under `$dest` plus the link refusal at every hash site closes the whole SP1/SP1b/SP1c/SP1d/SP1e class, with A1b's fail-open unwound through `dc_unwind`. The author's 83-test suite is green. The one residual worth a row is P3-1: `git archive` still runs a *global* filter driver assigned by a *committed* `.gitattributes`, and `git_state_gate` reads neither — but this is not reachable from an isolated container, grants a bare-host agent nothing beyond the HOME-write persistence it already has, and is (obliquely) the "user's own global git config" residual decision 037 already accepts. It is Medium under the floor rule, not a merge blocker; the honest fix is to sharpen 037's residual wording (global config is agent-writable; the `info/attributes` check has a committed-`.gitattributes` blind spot) or, optionally, to disable filters on the install's own `git archive`. The devcontainer `$TMPDIR` content-swap residual (P3-2) is correctly documented and bounded by the user's Q-058 [2] answer. **No finding is High or above. Merge is not blocked on security grounds.** The single most useful follow-up is the one-line documentation correction for P3-1. Endorsement claims marked `route: code-fact-check` are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): "a markdown report saved to /workspace/docs/reviews/security-review-2026-09-25-copy-install-q058-pass3.md, structured per the skill."
- Answered:
  - (1) **Re-ran every prior probe against 516124d.** SP1, SP1b, SP1c, SP1d, SP1e: all now fail to land (closed). SP3a: still refuses. SP3b, SP3c, SP3d: all neutralised (no marker). A1b: now unwinds (no live altered launcher). P3/P4/P5 are covered by the author's passing T69/T72/T73 and the pre-host-stage `agent_gate` (:748). None of the pass-2 probes still demonstrates a vulnerability.
  - (2) **New routes:** config-based hooks, a `.git` gitfile, `GIT_DIR`/`GIT_*` env, `archive` export-subst, and the gate's own include-following are all clean on git 2.39.5. `safe.directory` is a DoS/usability path, not exec. The **one** new exec route is P3-1 (committed `.gitattributes` + global filter driver). Only two git calls exist outside `repo_git`-neutralisation — `repo_git` itself and one include-safe `config --file` read — no third path.
  - (3) The remaining **devcontainer `$TMPDIR`** exposure is honestly documented (037) and bounded: the link variant is closed; the content swap-and-revert is **amber/accepted** under Q-058 [2], not red.
  - (4) **Fail-open:** A1b's path is fixed (`dc_unwind`); the host copy loop and post-y hash fail closed. I found no new fail-open route.
  - **P2-R1: resolved. P2-R2/R3/A1: resolved. P2-A2: resolved.**
- Out of scope / pre-existing: `cc-isolated.sh --bless` having no human guard; the devcontainer first install showing no content review; `~/.config/claude-devcontainer` absent from denyWrite. All pass-1/2 context.
- Escalate:
  - (1) **No merge blocker on security grounds.** P3-1 is Medium and is (obliquely) an already-accepted 037 residual; it warrants a one-line doc correction, not a rework. The user should decide P3-1 (a) accept + correct 037, or (b) harden `git archive`.
  - (2) **Q-061** (host stage under `$dest`): the interim [1] is what closes P2-R2/R3; keeping [1] is what makes the host reds stay closed. The answer should confirm [1].
  - (3) **You: terminal (carried):** whether the bare host's sandboxed Bash can write `~/.gitconfig` (decides P3-1's reach) and the terminal's `$TMPDIR`/`/tmp/cw-*` (decides P3-2's).
- Decisions I made: I rated P3-1 Medium, not High, because it is unreachable from an isolated container and grants a bare-host agent nothing beyond existing HOME-write persistence — distinguishing it from pass-2 N1/N2, which were bind-mount-reachable and are now closed. I re-ran the pass-2 harness unchanged rather than writing fresh equivalents, so "resolved" is directly comparable to pass 2's "not resolved." Probe logs and scripts are under `docs/reviews/execution-logs/secrev-q058p3/` (shellcheck-clean, with shebangs).
