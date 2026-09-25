Commit: feba07d

# Security Review: ans/copy-install Q-058 pass 2 (c7c4e34..feba07d)

**Scope:** fix commits `c7c4e34..feba07d` (9 commits: 24ce814 R1, 6ec64c3 R2, c700270 A1, ec1e5bd A2, 477d77f A3, c460912 A4/A5, f946a8b C3/C1, 32247d7 C2, feba07d docs). Files: `devcontainer-config/install.sh`, `docs/decisions/037-bare-host-copy-install.md`, `test/install-host.bats`, README, guide and plan. Code read at feba07d in `/workspace/.claude/wt-q058p2`. The earlier branch history is context only.
**Date:** 2026-09-25
**Based on:** pass-1 rubric `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md` and pass-1 security review `docs/reviews/security-review-2026-09-24-copy-install-q058.md` (F1–F8).
**Own probes (hermetic: temp HOME/TMPDIR, stubbed pgrep/docker, empty `GIT_CONFIG_GLOBAL`, no system config, fake repo; the real `~/.claude` and `~/.config` were never touched):** `docs/reviews/execution-logs/secrev-q058p2/`. That holds `probe.bats` (12 probes), `probe.log`, `repeat.log`, `git-keys-probe.{sh,log}`, `fix-flags-probe.{sh,log}` and `run-probes.sh`. git 2.39.5.

> ⚠️ **No code fact-check report provided for pass 2.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator.

No HALT escalation patterns matched.

---

## Answer on R1 and R2 (key judgment)

**R1 (checkout git state runs commands): not resolved.** The keys that 24ce814 refuses are now refused. My re-run of SP3 (filter + attributes, then `core.fsmonitor`) is refused and no marker runs (SP3a). **But `git status` also runs hooks, and the gate never looks at them.**
- `.git/hooks/post-index-change` runs whenever status refreshes the index. A stat-only `touch` of any tracked payload file triggers that (SP3b, 6/6).
- `core.hooksPath` is not in `GIT_EXEC_KEYS_RE` (SP3c).
- A submodule's own git dir (`.git/modules/<path>/config`, `info/attributes`, `hooks/`) runs its clean filter and its hook, and the superproject gate sees nothing (SP3d).

A cc-isolated container can write all three through its bind mount, so the container-to-host path that R1 named is still open on every install. The fix is three flags on the two `status` calls, and I verified it (`fix-flags-probe.log`). No git command runs on the checkout before the gate (read-static, see Endorsements). The other keys the caller asked about (`diff.external`, `core.pager`/`pager.*`, textconv, `gc.auto`, aliases) are not honoured by the installer's invocations (`git-keys-probe.log`). archive runs local-only, so protocol/url settings have nothing to act on.

**R2 (host review = install): SP1 itself is resolved; the class is not.** My re-run of SP1 now shows `+echo MALICIOUS-PAYLOAD` in the review, and exactly that is installed. The review reads the copies under `$dest`, as claimed. The fix's stated purpose, though, was that the host target stop depending on the sampling gate (pass-1 F1, "the sampling gate is no longer load-bearing for the host target"). Three inputs to the install still sit in `$TMPDIR`, and a same-uid writer the gate does not see can use each one:
- **SP1b (6/6):** the *old* side of the diff, `$HOST_TMP/installed`, is rewritten to match the new copy. The malicious change then produces no diff lines at all, and the hash check passes.
- **SP1d (12/12):** a symlink planted in the stage after `extract_commit`'s link check is copied into `.cw-new.*`. `diff -r` dereferences it, so the review shows the target's (benign) content. It installs as a **live link from `~/.claude/hooks/…` into an agent-writable file**, a persistent denyWrite bypass after one race.
- **SP1c (6/6):** on a first install, a stage edit between `git archive` and the copy lands in an ADD entry whose content is not shown, next to the claim "it is skills at commit X".

SP1d's link variant also defeats A1 on the devcontainer target (SP1e, 12/12). The planted `cc-isolated.sh` link passes both A1 hashes and is blessed.

**Merge verdict:** two reds remain, **R1** (hooks/submodules) and **R2's class** (SP1b, SP1d/SP1e). Both fixes are small. For R1, add `--no-optional-locks -c core.hooksPath=/dev/null … --ignore-submodules=all` to the two status calls. For R2, run the symlink refusal again on the copies (and on `$DEST` after the copy), and build the review's old-side view under `$dest`. The structural version is to extract the host stage directly under `$dest` after taking the lock, which closes SP1b/c/d together.

---

## Trust Boundary Map

```
B1: checkout .git/{config,config.worktree,info/attributes,hooks/,modules/*/} (agents; cc-isolated bind mount)
      → git_state_gate (install.sh:171-211), -c core.fsmonitor=false (:304-305) → git archive / git status exec as host user
B2 (moved): host stage $HOST_TMP/payload in ${TMPDIR:-/tmp} (same-uid writers)
      → extract_commit link/NUL checks (:250-275) → cp -Rp into $dest/.cw-new.* (:739-747)
B3: review view $HOST_TMP/installed in ${TMPDIR:-/tmp} (same-uid writers)
      → diff -ruNa old side (:817, :837) → the human's review
B4 (new): $dest/.cw-new.* (under ~/.claude, sandbox denyWrite)
      → payload_hash at :756 and :866 → mv swap (:892-905)
B5 (new): devcontainer stage $DC_TMP/config in ${TMPDIR:-/tmp}
      → tree_hash at :448, :483, :502 → $DEST (~/.config/claude-devcontainer, not denyWrite) → chmod/ln/--bless (:511-517)
B6: host process table + docker daemon → agent_gate (:982-1032; calls :1093, :481, :677 (new), :864) → permission to stage/install
```

**Input-source classification**

```
S1: committed payload (HEAD objects)            — runtime-mutable (agents commit) — UNTRUSTED for content; the review is the control
S2: .git state: config, config.worktree, info/attributes, hooks/, modules/*/{config,hooks,info}
                                                 — runtime-mutable (host agents; container bind mount)
                                                 — UNTRUSTED toward exec sinks (git runs filters, fsmonitor, hooks from it)
S3: $TMPDIR stage and view files                 — mutable by any same-uid writer during the run
                                                 — UNTRUSTED toward the install and review sinks (the premise the gate samples)
S4: $dest/.cw-new.* copies                        — writable only by writers of ~/.claude (denyWrite for sandboxed Bash)
                                                 — trusted toward the install sink to the extent denyWrite holds
S5: $DEST (~/.config/claude-devcontainer)         — not in the documented denyWrite — trusted toward bless only as far as its writers
S6: pgrep -af / docker ps output                  — self-chosen argv / daemon — presence evidence only
S7: HOME, TMPDIR, CLAUDE_*_DIR, PATH, global git config — deploy-time, user's terminal — trusted
```

What enters from outside is agent-authored commits and `.git` state (S1, S2), and whatever a same-uid writer puts into `$TMPDIR` during the run (S3). The fix moved the host review's **new** side from S3 to S4 (B2→B4). It left the review's **old** side (B3) and the source of the copies (B2) in S3. So the host target's review = install still rests on "no writer in `$TMPDIR`", which the gate samples (B6) and does not enforce. For B1, the fix covers config keys but not the hook and submodule parts of S2.

---

## Findings

#### N1: R1 incomplete: `git status` runs `.git/hooks/post-index-change`, a `core.hooksPath` hook, and a submodule's filter and hook; the gate checks none of them

**Severity:** High
**Location:** `devcontainer-config/install.sh:171` (`GIT_EXEC_KEYS_RE`), `:172-211` (`git_state_gate`), `:304-305` (the two `status` calls in `assemble()` :288-321); `docs/decisions/037-bare-host-copy-install.md:78`
**Boundary:** B1
**Move:** #11 (enumerate bypasses), #12 (sweep the primitive), #1 (runtime-mutable ⇒ compromise-reachable)
**Confidence:** High (executed: SP3b 6/6, SP3c, SP3d; `git-keys-probe.log`, `fix-flags-probe.log`)
**Legibility-target:** for-author

**Evidence** (verbatim):
```
GIT_EXEC_KEYS_RE='^(filter\.|core\.fsmonitor|include)'
```
(:171. `git_state_gate` reads only `config` and `config.worktree` (:174-191) and `info/attributes` (:192-200). It never reads `hooks/` or `modules/`.)
```
  dirty="$(git -C "$REPO_ROOT" -c core.quotePath=true -c core.fsmonitor=false status --porcelain --untracked-files=all -- "${CLAUDE_HOME_SRC[@]}" "$@")"
```
(:304; :305 is the same call without `"$@"`.)

037:78: `What remains: a command-running key outside that list, and the user's own global or system git config.`

`git status` refreshes the index. When a tracked file's stat data changed but its content did not, status rewrites the index, and that write runs the `post-index-change` hook. It needs no config key: the default `.git/hooks/` path is enough. SP3b plants `.git/hooks/post-index-change` and touches `skills/a/SKILL.md`. A plain `install.sh --yes` then runs the hook, 6/6, and the install exits 0. SP3c does the same through `core.hooksPath`, which the regex does not match. SP3d commits a submodule at `skills/sub`. It sets `filter.pwn.clean` in the submodule's own config and `* filter=pwn` in `.git/modules/skills/sub/info/attributes`, and plants a hook in `.git/modules/skills/sub/hooks/`. status recurses into the submodule, and both the clean filter and the hook run. The superproject gate finds nothing. A cc-isolated container writes all of `.git` through its bind mount (037:64), so the container-to-host path R1 named is still reachable on every install. The 037:78 residual reads as if only unusual config keys remain. The default hooks directory is not a key, so the residual understates this. **Is any git command run before the check?** No: see the endorsement below. **Other keys asked about:** `diff.external`, `core.pager`, `pager.status`, `pager.archive`, a textconv driver, `gc.auto` and an `alias.status` were all set, and none ran under the installer's exact invocations (`git-keys-probe.log`). The pager is not started, because stdout is a `$(…)` capture or a pipe. archive runs without `--remote`, so url/protocol settings have nothing to act on.

**Recommendation:** Change both status calls to `git --no-optional-locks -C "$REPO_ROOT" -c core.quotePath=true -c core.fsmonitor=false -c core.hooksPath=/dev/null status … --ignore-submodules=all`. `fix-flags-probe.log` shows that this stops the root hook, the submodule hook and the submodule clean filter. `--no-optional-locks` stops the index write, and with it the hook. `--ignore-submodules=all` stops the recursion. Rewrite 037:78 to name hooks and submodule git dirs. Optionally, have `git_state_gate` also refuse a local `core.hooksPath`/`core.attributesFile` and any non-`.sample` file in `hooks/`, so the user is told something was planted.

#### N2: A symlink planted in a stage after `extract_commit`'s link check installs as a live link (host: into `~/.claude`; devcontainer: blessed `cc-isolated.sh`)

**Severity:** High
**Location:** `install.sh:250-256` (the only link check), host copy `:739-747` and hash `:756`; devcontainer copy `:495-498`, hashes `:448`, `:483`, `:502`, `tree_hash` `:576-584`
**Boundary:** B2, B4, B5
**Move:** #4 (TOCTOU), #11
**Confidence:** High for the mechanism (SP1d 12/12, SP1e 12/12). Medium for reach: it needs a same-uid writer in `$TMPDIR` that the gate does not see, the same premise as pass-1 F1.
**Legibility-target:** for-author

**Evidence:**
```
  links="$(cd "$dir" && find . -type l | sed 's|^\./||' | LC_ALL=C sort)"
  if [ -n "$links" ]; then
    echo "ERROR: the committed payload contains symlinks, which install.sh never installs:" >&2
```
(:250-252, inside `extract_commit()` :216-276. It runs once, on the stage, right after extraction.)
```
    find "$dir/$pfx$name" -printf '%P\t%y\t%m\t%l\n' | LC_ALL=C sort
```
(:581, `tree_hash`. It *records* a link's type and target, so a link present at hash time hashes the same afterwards. Nothing refuses it.)

After `extract_commit` returns, the host stage still goes through the NUL scan, two `git status` calls and the manifest write (`assemble`), then the lock and the copy loop. A writer that replaces `payload/hooks/h.sh` with a symlink once `.manifest` exists (SP1d) gets a link into `.cw-new.hooks`. `payload_hash` hashes it. The review's `diff -ruNa` follows the link and shows the target's content, which the attacker set equal to the installed hook, so the review shows only a benign `guides/g.md` change. After y, `~/.claude/hooks/h.sh` is a symlink to an agent-writable file. SP1d then writes `AGENT-EDIT-AFTER-INSTALL` to the target, and the installed hook reads it. The writer has to be present only once. After that it controls a hook that every session runs, outside `denyWrite ~/.claude`. SP1e does the same on the devcontainer target. It triggers on the checkout mirror rebuild (:434-439), which runs after `extract_commit` and before the pre-review `tree_hash`. `$DEST/cc-isolated.sh` becomes a link, both A1 hashes match, and `--bless` runs it. cc-isolated's launch-time manifest check hashes link-resolved content (`cc-isolated.sh:143-148`), but the launcher is the linked file itself, so the check runs in attacker code. My first three SP1d runs planted too early, and `extract_commit` refused them. The check works when the link predates it (logged in the SP1d comment).

**Recommendation:** Refuse links again at every hash site. Before `reviewed_hash` on the host (:756), run `find "$dest"/.cw-new.* -type l`. On the devcontainer target, do the same on `$stage` before :448 and on `$DEST`'s PAYLOAD items inside the post-copy check (:502), taking the removal path on any hit. Alternatively, have `tree_hash` fail when `%y` is `l`. This is a few lines and holds wherever the stage lives.

#### N3: The old side of the host review is still in `$TMPDIR`; rewriting it hides a change (R2 class not closed)

**Severity:** High
**Location:** `install.sh:807-838` (the view is built at :826-832 and diffed at :817 and :837); comment :710-718; `docs/decisions/037-bare-host-copy-install.md:67`
**Boundary:** B3
**Move:** #4, #11
**Confidence:** High for the mechanism (SP1b 6/6). Medium for reach, with the same premise as N2.
**Legibility-target:** for-author

**Evidence:**
```
  local view="$HOST_TMP/installed" diffnames=() n lines src
```
(:807; `HOST_TMP` is `mktemp -d "${TMPDIR:-/tmp}/cw-host-stage.XXXXXX"` at :706)
```
    if ! review_diff "$view" "$new" "${diffnames[@]}"; then changed=1; fi
```
(:837)

037:67: `The copies sit under ~/.claude, which the sandbox's denyWrite keeps agents out of.`

The code comment at :711 says "The review reads the copies that get installed, never the stage". That holds for the `+` side. The `-` side is a copy of the destination in `$TMPDIR`. SP1b uses the SP1 setup (commit a malicious `hooks/h.sh` plus a benign `guides/g.md` change). Its helper atomically rewrites `$HOST_TMP/installed/hooks/h.sh` to the new content as soon as it appears. The review then prints only `+guide v2 benign`, the y is accepted, the hash check passes (the copies were never touched), and `~/.claude/hooks/h.sh` contains `echo MALICIOUS-PAYLOAD`. This needs no revert and leaves no trace, because the view is deleted by the EXIT trap. The ADD path (:817) has the same exposure: a writer who creates `$view/<name>` suppresses the `+` lines, though the file-name list at :814 still prints. So under Q-061 [1] the host target still depends on the gate for review = install, which is what Q-061 [1] was chosen to remove.

**Recommendation:** Build the view under `$dest` after the lock (for example, `$dest/.cw-view`), and add it to `rm_new_copies`/`host_cleanup`. Or fold it into the structural fix under N4. Say in 037:67 which parts of the review are protected.

#### N4: A stage edit between `git archive` and the copy into `$dest` installs content not shown on an ADD entry; the review's "it is <src> at commit X" is then false

**Severity:** Medium
**Location:** `install.sh:706-708` (stage in `$TMPDIR`), `:739-747` (the copy), `:815-821` (ADD over 200 lines: content not shown, commit named); `037:70`
**Boundary:** B2
**Move:** #4
**Confidence:** High for the mechanism (SP1c 6/6). Medium for reach.
**Legibility-target:** for-author

**Evidence:**
```
        echo "    (content not shown: $lines lines, over the $ADD_MAX_LINES-line limit for a new entry;" \
             "it is $src at commit ${STAGED_COMMIT:0:12})" | vis_or_die
```
(:820-821)

037:70: `Neither target catches an agent that rewrites the commit, the checkout's .git or the installer itself before the stage is built.`

The copies are made from the `$TMPDIR` stage after the stage has sat there through the NUL scan and two `git status` runs. An edit in that window reaches the copies, the hash and the install. When the entry is new and over 200 lines (every entry except `CLAUDE.md` on a fresh host), the review shows only file names plus the assurance that the content "is skills at commit X". SP1c's first install printed exactly that, and `skills/a/SKILL.md` was installed as `MALICIOUS-SKILL`. The manifest's `commit=` (:747) is copied from the same stage and can be forged the same way. This window predates the fix, since b4fd792 hashed after `assemble`. But 037:70 limits the unhandled case to "before the stage is built", and this happens after. Medium, not High: it is limited to entries the destination lacks, where the user reviewed names, not content.

**Recommendation (structural, closes N2-host, N3 and N4 together):** in `install_claude_home`, take the lock first. Then create the stage with `mktemp -d "$dest/.cw-stage.XXXXXX"` and pass it to `assemble`, so extraction, link and NUL checks, the copies and the view all sit behind denyWrite. Clean it in `host_cleanup`. `$TMPDIR` then plays no part in the host target. Minimum: correct 037:70 to "before the copies under `$dest` are made".

#### N5: A1 fails open on its error path: a `cp` failure later in the loop exits through `set -e` before the post-copy check

**Severity:** Medium
**Location:** `install.sh:495-509` (inside `install_devcontainer()` :402-531)
**Boundary:** B5
**Move:** #3 (error path)
**Confidence:** Medium. The mechanism was executed with a `cp` stub (A1b), the same method as the author's T70. A real race needs the writer to act in the millisecond window after the pre-copy check at :483.
**Legibility-target:** for-author

**Evidence:**
```
  for item in "${PAYLOAD[@]}"; do
    rm -rf "${DEST:?}/$item"
    cp -Rp "$stage/$item" "$DEST/$item"
  done
  # A1: what landed must be what was reviewed, before chmod and the bless. On a
```
(:495-499; the check and removal follow at :502-509)

`cc-isolated.sh` is the 5th PAYLOAD item. A writer that alters the stage's `cc-isolated.sh` as it is copied, and then makes a later item uncopyable (for example by removing `$stage/egress`), stops the script at the failing `cp` through `set -e`. The check that would remove the altered file never runs. A1b: the run exits non-zero with no "differs from what the review" message and no bless. `~/.local/bin/cc-isolated` still points at `$DEST/cc-isolated.sh` from the previous install, and that file now holds `echo TAMPERED-LAUNCHER`. The launcher runs unsandboxed on the host the next time the user types `cc-isolated`. Its own manifest check is the attacker's code (see N2).

**Recommendation:** `cp -Rp … || { copy_failed=1; break; }`, then go through the same removal branch as a mismatch (remove every PAYLOAD item, no chmod/ln/bless). Or put the check in a function that the loop's failure path also calls.

#### N6: The staging under `$dest` introduced no new exposure I could find (judgment 3)

**Severity:** Informational
**Location:** `install.sh:697-704`, `:722-753`, `:599-603`, `:615-626`
**Boundary:** B4
**Move:** #3, #4
**Confidence:** High (R2x executed; the rest read-static)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  [ -d "$dest" ] || HOST_MADE_DEST="$dest"   # removed again if left empty
```
(:723)
```
  if [ -n "$HOST_NEW_IN" ]; then rm_new_copies "$HOST_NEW_IN"; fi
```
(:622, set at :728 only once `mkdir` of the lock succeeded)

Each point the caller asked about:
- **(a) Leftovers after a crash.** A SIGKILL leaves `.cw-new.*` and the lock. The next run stops at `lock_msg` (:702-704). After the user removes the lock, `rm -rf "$dest/.cw-new.$name"` (:740) clears the old copies before recopying. Claude Code does not load `.cw-new.*` names.
- **(b) A planted `.cw-new.*`.** A top-level link is refused (:697-701). A planted directory is removed, not reviewed or installed (R2x: `evil.sh` absent, `PLANTED` not shown). A writer able to plant there can already write `~/.claude`.
- **(c) Lock ordering.** The lock is now held through the review. `HOST_NEW_IN` is set only by the lock's owner, so a refused concurrent run never removes another run's copies.
- **(d) `$dest` created on decline.** R2x: a first-install decline leaves no `~/.claude`. `mkdir -p` parents stay, as documented in 6ec64c3.
- **(e) Symlinks inside `$dest`.** `$dest` itself may be a link to a directory outside the repo (resolve_phys guard, :686). `.cw-new.*` and the lock are checked for links.

The one new property is that the review's validity now depends on denyWrite covering `$dest`. When `CLAUDE_HOME_DIR` points outside `~/.claude`, that protection is whatever the user's sandbox config gives it. 037:67 names `~/.claude` specifically. It would be worth one clause.

**Recommendation:** None required. Optionally add that clause to 037:67.

---

## Untested bypass candidates

| Candidate | Guard | Why not tested |
|---|---|---|
| git-lfs: a committed `.gitattributes` `filter=lfs` plus a globally installed `filter.lfs` driver, with a committed `.lfsconfig` steering transfer settings | `git_state_gate` (B1) | The driver command is the user's own. Whether `.lfsconfig` can name an executable (custom transfer agents) depends on git-lfs's allowlist for that file, and git-lfs isn't installed here. |
| A local `core.attributesFile` pointing at a planted file that assigns a global driver | `GIT_EXEC_KEYS_RE` | Same dependency on a global driver. Not in the refused list. Not executed. |
| Config-based hooks (`hook.<event>.command`) on a newer git | N1 fix (`core.hooksPath=/dev/null`) | git 2.39.5 here has no config-based hooks. Whether `core.hooksPath=/dev/null` disables them on the host's git is unverified. `--no-optional-locks` still removes the index write that triggers `post-index-change`. |
| A submodule as an embedded `<path>/.git` directory rather than `.git/modules` | N1 fix (`--ignore-submodules=all`) | Only the `.git/modules` layout was executed. `--ignore-submodules=all` should cover both, but that is not verified. |
| A FIFO at `info/attributes` (passes `[ -s ]` as empty) | `git_state_gate` :198 | It can only hang the install (DoS), and it needs a writer to feed it. |
| A writer planting config between `git_state_gate` and `git archive`/`status` in the same `assemble` | `git_state_gate` (one check per assemble) | Needs a writer active mid-run, which is the accepted "between checks" residual (037:80). |
| A real race (no stub) for N5 | A1 post-copy check | Executed only with a `cp` stub. |
| Bare-host reach: can sandboxed Bash write the terminal's `$TMPDIR` or `/tmp/cw-*`? Can sandboxed children outlive their session? | N2–N5 reach | Carried from pass 1. Needs the real bwrap host. |

Because of these, `git_state_gate` and the A1/R2 hash checks do not appear below as guardrail claims.

---

## Endorsement Claims

- **Claim:** a local `filter.*` with a non-empty `info/attributes`, and a local `core.fsmonitor`, are refused before git runs them, and no marker command runs.
  **Location:** `install.sh:171-211`, `:291`
  **Evidence:** executed (SP3a; also the author's T65/T66)
  **Verified:** `install.sh --yes` exits 1 and the `smudge-ran` and `fsmon-ran` markers are absent.
  **Not verified:** the hook and submodule routes (N1), which this claim does not cover.
- **Claim:** no git command runs on the checkout before `git_state_gate`, on either target.
  **Location:** `install.sh:1048-1101` (main), `:408-429` (install_devcontainer up to assemble), `:649-708` (install_claude_home up to assemble), `:291`
  **Evidence:** read-static
  **Verified:** before `assemble`, main runs arg parsing, `has_ctrl`, `command -v perl` and `agent_gate`, which calls pgrep and docker. install_devcontainer runs the `-L` walk and `mktemp`. install_claude_home runs the skip rules, the gate, the path guards and `mktemp`. `assemble`'s first statement is `git_state_gate`.
  **Not verified:** `cc-isolated.sh --bless` (:517), which runs after staging and was not traced for git calls on the checkout.
  **route: code-fact-check**
- **Claim:** the installer's git invocations do not honour `diff.external`, `core.pager`, `pager.status`, `pager.archive`, a textconv driver, `gc.auto` or an `alias.status`.
  **Location:** `install.sh:149`, `:226`, `:238`, `:304-305`
  **Evidence:** executed (`git-keys-probe.log`, git 2.39.5)
  **Verified:** all seven were set and no marker ran under the exact invocations.
  **Not verified:** newer git versions on the host.
- **Claim:** a stage swapped to benign content during the host review and restored before y no longer changes what is installed. The review shows the installed content.
  **Location:** `install.sh:738-756`, `:834-838`, `:866-871`
  **Evidence:** executed (SP1 re-run; the author's T67)
  **Verified:** the review prints `+echo MALICIOUS-PAYLOAD` and exactly that lands.
  **Not verified:** the old side of the diff (N3) and links planted before the copy (N2).
- **Claim:** after an A1 post-copy mismatch, `~/.local/bin/cc-isolated` points at a removed file, neither the old launcher nor an unreviewed one, and nothing is blessed.
  **Location:** `install.sh:502-509`
  **Evidence:** executed (A1 probe)
  **Verified:** the link exists and is dangling, `$DEST/cc-isolated.sh` is absent, and no `BLESS-STUB` runs.
  **Not verified:** a `cp` failure inside the loop, where this does not hold (N5).
- **Claim:** a first-install decline removes the `$dest` this run created, and a planted `.cw-new.<name>` directory is discarded rather than reviewed or installed.
  **Location:** `install.sh:723`, `:740`, `:615-626`
  **Evidence:** executed (R2x)
  **Verified:** `~/.claude` is absent after `n`/`n`. `evil.sh` is neither shown nor installed, and no `.cw-new.*` remains.
  **Not verified:** a SIGKILL during the review (read-static only, see N6).
- **Claim:** `vis_or_die` stops the script with a message when vis fails outside `review_diff`.
  **Location:** `install.sh:138-145`
  **Evidence:** read-static (the author's T74 executes it)
  **Verified:** every `vis_or_die` pipeline runs in an errexit-active context (main, `install_*`, `extract_commit`, `agent_gate`, `git_state_gate` with an explicit `exit 1`).
  **Not verified:** `mode_diff` (:380), which keeps plain `vis` by design.

---

## Primitive sweep

**Primitive: git invocation on the checkout (exec through config, attributes, hooks, submodules)**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:149` `rev-parse --verify` | S2 | none needed | cleared: runs no filter, hook or fsmonitor |
| `:175`, `:192` `rev-parse --git-path` | S2 | none needed | cleared (same) |
| `:183` `git --no-pager config --file … --no-includes --get-regexp` | S2 | `--no-includes`, `--no-pager` | cleared |
| `:226` `cat-file -e` | S2 | none needed | cleared |
| `:238` `archive --format=tar` | S1, S2 | `git_state_gate` (local filter/attributes) | cleared for local config (SP3a). The global-driver route is an untested candidate |
| `:304` `status --porcelain` | S2 | `git_state_gate`, `-c core.fsmonitor=false` | **N1** (hooks, `core.hooksPath`, submodule git dir) |
| `:305` `status --porcelain` | S2 | same | **N1** |

**Primitive: copy from a `$TMPDIR` stage into an install location**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:742` `cp -Rp "$stage/$name" "$dest/.cw-new.$name"` | S3 | link check at :250 (earlier) | **N2** (late link), **N4** (late edit) |
| `:747` `cp -p "$stage/.manifest" …` | S3 | none | **N4** (`commit=` forgeable) |
| `:497` `cp -Rp "$stage/$item" "$DEST/$item"` | S3 | tree_hash :483, :502 | **N2** (SP1e), **N5** (error path) |
| `:439` `cp -Rp` into the checkout mirror | S3 | no-follow rebuild | cleared: a staging copy, not installed |
| `:826` `cp -RH "$dest/$name" "$view/$name"` (the review's old side) | S4 → S3 | none | **N3** |

**Primitive: `rm -rf` / `rmdir` added or moved by the fixes**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:503` A1 removal loop `rm -rf "${DEST:?}/$item"` | S7 DEST, code-constant PAYLOAD | `:?` | cleared |
| `:602` `rm_new_copies` | S7 dest, fixed names | `:?` | cleared |
| `:622` `host_cleanup` → `rm_new_copies "$HOST_NEW_IN"` | set only by the lock owner (:728) | lock | cleared |
| `:625` `rmdir "$HOST_MADE_DEST"` | S7 | `rmdir` removes only an empty dir | cleared (R2x) |
| `:740` `rm -rf "$dest/.cw-new.$name"` (moved before the review) | S7 | top-level link refusal :697-701 | cleared |
| `:934` prune `rm -rf "${bkroot:?}/$old"` | names in `$bkroot` | newline+TAB skip (:940, A3) | cleared (the author's T73; read-static) |

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| N1 | R1 incomplete: status runs `.git/hooks/post-index-change`, a `core.hooksPath` hook, and a submodule's filter/hook | High | B1 | `install.sh:171-211,:304-305`; 037:78 | High |
| N2 | A symlink planted after the link check installs as a live link (host `~/.claude/hooks`; blessed `cc-isolated.sh`) | High | B2, B4, B5 | `install.sh:250,:742,:497,:581` | High (mech) / Medium (reach) |
| N3 | The review's old side (`$HOST_TMP/installed`) is rewritable; a change vanishes from the review | High | B3 | `install.sh:807,:826,:837`; 037:67 | High (mech) / Medium (reach) |
| N4 | A stage edit before the copy installs unseen content on ADD entries; "it is X at commit Y" false | Medium | B2 | `install.sh:742,:820-821`; 037:70 | High (mech) / Medium (reach) |
| N5 | A1 fails open: a later `cp` failure exits before the post-copy check, leaving an altered launcher live | Medium | B5 | `install.sh:495-509` | Medium |
| N6 | Staging under `$dest`: no new exposure found (leftovers, planted copies, lock order, decline, links) | Informational | B4 | `install.sh:697-753,:615-626` | High |

## Overall Assessment

The fixes do what their commits test. The listed git keys are refused, SP1's swap-and-revert is closed, A1 refuses a persistent stage edit, the gate runs before host staging with a wider pattern, TAB names are skipped, and vis failures are named. Neither key red is closed, though. **R1** refuses config keys, but `git status` runs hooks that need no key, and a cc-isolated container can plant one in `.git/hooks/` or a submodule's git dir. That is still a container-to-host execution path on every install (N1). The fix is three flags, and it was verified. **R2** moved the review's new side under `$dest`, but the old side of the diff (N3) and the stage the copies are made from (N2, N4) are still in `$TMPDIR`. So the host target still depends on the sampling gate. Worse, N2 turns one brief race into a permanent link from `~/.claude/hooks` into an agent-writable file, which is a denyWrite bypass that persists after the writer is gone. The same link trick passes A1's hashes on the devcontainer target and gets blessed. All of this is fixable in place. The single most important change is N1's flags. After that comes one structural change: extract the host stage under `$dest` after the lock, which closes N2-host, N3 and N4 together. Add a link refusal at each hash site, which closes N2 on both targets, and route A1's copy-loop failures to its removal path (N5). No other findings within the code paths read. Endorsement claims marked `route: code-fact-check` are pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): "a markdown report saved to /workspace/docs/reviews/security-review-2026-09-25-copy-install-q058-pass2.md, structured per the skill."
- Answered:
  - (1) SP1 no longer works (re-run: the review shows the installed payload). SP3's original filter and fsmonitor variants are refused (SP3a).
  - (2) Yes, the refusal list misses command-running state: `.git/hooks/post-index-change`, `core.hooksPath` and submodule git dirs (N1). `diff.external`, pagers, textconv, `gc.auto`, aliases and protocol/url settings are not honoured by these invocations. No git command runs before the check.
  - (3) Staging under `$dest` introduced no new exposure of its own (N6). But the parts left in `$TMPDIR` keep the R2 class open (N2–N4).
  - (4) After an A1 mismatch, `~/.local/bin/cc-isolated` dangles, which fails closed. On a mid-loop `cp` failure it points at an unchecked, possibly altered launcher, which fails open (N5).
  - (5) The fail-open cases are N5 and, through tree_hash accepting links, N2.
  - **R1: not resolved. R2: SP1 resolved, class not resolved.**
- Out of scope: `cc-isolated.sh --bless` having no human guard, and `~/.config/claude-devcontainer` missing from denyWrite (pre-existing, pass-1 context). The devcontainer first install shows no content review at all (pre-existing, :464-466). It is noted only because SP1e's `--yes` run relied on it.
- Escalate:
  - (1) **Merge blocker:** R1 (N1) and R2's class (N2, N3) are red under the rubric's own definitions. They should not be relabelled as residuals without the user's explicit acceptance, because N1 and N2 are persistent host-execution paths.
  - (2) **You: terminal (carried from pass 1):** whether the bare host's sandboxed Bash can write the terminal's `$TMPDIR` or `/tmp/cw-*`. That decides the reach of N2–N5.
  - (3) Q-061's framing assumed the host target stops depending on the gate under [1]. That is only true once N2–N4 are fixed, which the answer to Q-061 should reflect.
- Questions I would have asked: whether git-lfs is installed globally on the bare host (it decides the untested lfs candidate), and which git version the host runs (config-based hooks).
- Decisions I made: I rated N1–N3 High, consistent with pass-1 F1/F4 (container-to-host or denyWrite bypass). I rated N4 Medium (first-install entries only) and N5 Medium (stub-simulated). I ran the SP1b/c/d/e races repeatedly and saved the counts to `repeat.log`. My first three SP1d attempts were refused by `extract_commit` because of a harness timing error, which I record rather than drop. N5 is shown with a `cp` stub, as T70 does, not with a real race.
