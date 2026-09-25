Commit: b4fd792

# Security Review: ans/copy-install Q-058 restart (9ae6e46..b4fd792)

**Scope:** `9ae6e46..b4fd792` (8 commits), limited to `devcontainer-config/install.sh`, `test/install-host.bats`, `test/cc-isolated-functions.bats`, `README.md`, `docs/decisions/037-bare-host-copy-install.md`, `guides/bare-host-hook-wiring.md`, `docs/working/plan-copy-install-bare-host.md` and the commit messages. Code read at b4fd792 in `/workspace/.claude/wt-copyinstall`.
**Date:** 2026-09-24
**Based on:** code-fact-check reports r1/r2/r3 (`docs/reviews/code-fact-check-report-r{1,2,3}.md`, k=3, merged most-severe-wins) and the final rubric `docs/reviews/code-review-rubric-2026-09-23-ans-copy-install-final.md`.
**Own probes (hermetic: temp HOME/TMPDIR, stubbed pgrep/docker, fake repo; the real `~/.claude` was never touched):** `docs/reviews/execution-logs/secrev-q058-b4fd792/` (`probe.bats`, `probe.log`, `sp3-git-config-exec.log`).

No HALT escalation patterns matched.

---

## Answer on R1 and R2 (key judgment)

**R2: resolved.** perl is required at startup (`install.sh:941-945`). A vis failure inside `review_diff` aborts before the prompt (`:265-271`). At the other `| vis` sites a failure exits through `set -e`/`pipefail` with no message. That fails closed, but the fa69656 Notes describe it wrongly (F7). The one site where errexit is suppressed is `mode_diff` (`:299`), which runs under `|| same=0` / `if !`. `review_diff` runs vis again right after it over the same items, so a lasting vis failure still aborts. No fail-open path remains that I could find.

**R1: not resolved. The model *can* resolve it, but the model has not been written down honestly.** The divergence mechanism is intact on both targets:
- **Host:** the hash is still taken before the review prints (`:589`). A writer that swaps a stage file to a benign version after the hash, while the review is produced, and swaps it back before y, installs content the review never showed. The hash matches because the reverted stage *is* the hashed stage. I ran this 6/6 (SP1, below). This is exactly the first sentence of the original R1.
- **Devcontainer:** there is no content check at all between the review and the install and bless (P3 in fact-check r2).

The restart does not remove this mechanism. It adds a premise, "no agent runs", and checks that premise at three instants, and only for command lines shaped like Claude Code. Under the trust model the user chose (Q-058 [2]), that is a legitimate design. The residual then is "an agent the three samples do not see". **But decision 037 does not say that.** 037:66 says "The hash check (R2) catches a stage edited while the prompt waits". That is false for target 1 and incomplete for target 2 (it misses swap-and-revert). The residual list at 037:75 also omits agents active between checks and same-uid processes that aren't Claude.

Sorted into the three classes asked for:
- **(a) promised but not delivered:** the 037:66 assurance (F1, F2). The 037:73 rationale "which the gate refuses" (F5). The residual list at 037:75, which does not cover what the gate actually misses (F3). The 037:74 rationale for `.git/config`, which understates a container-to-host code-execution path the gate never covers (F4).
- **(b) inherent to a sampling gate, acceptable if documented:** agents active only between the checks. Same-uid helpers with non-Claude command lines, which is the r2 open question about detached processes and needs the user's answer. Regex misses.
- **(c) cheap hardening:** stage, review and install from copies under the protected destination (this closes F1 structurally, see below). Hash and re-verify on target 1 (F2). One `agent_gate` call before the host `assemble` (F3). A broader regex, which fails closed (F3). `-c core.fsmonitor=false` plus a refusal of local `filter.*`/`include*` config (F4). One `*$'\t'*` case in the prune (F5). **Not** recommended: re-hashing just before the swap (F8). The only writer it would catch can already write the destination directly.

**Verdict for the merge decision:** R1 moves from a code red to a **documentation red**. The branch is safe to merge once 037 states the residual accurately and the user answers the detached-process question. The corrections are F1–F5's doc parts, about ten lines. Separately, and more important in my view, F4 is a container-to-host code-execution path that the installer triggers every time, and fixing it costs two to five lines. The stage-under-destination change (F1 fix) is the only option that makes the host guarantee independent of the sampling gate. I recommend it, but the model does not require it.

---

## Trust Boundary Map

```
B1: checkout HEAD / .git objects / .git/config / .git/info/attributes
      (bare-host sessions; cc-isolated via bind mount)  → git cat-file/archive/status (install.sh:150,162,225-226) → stage + exec as user (host, unsandboxed)
B2: stage ${TMPDIR:-/tmp}/cw-{devc,host}-stage.*
      (any same-uid writer during the run)              → review (diff -ruNa | vis, human y) → install copies ($DEST, $dest/.cw-new.*)
B3: host process table + docker daemon (new)           → agent_gate (install.sh:838-886; calls :947, :391, :695) → permission to stage / install
B4: $dest/.cw-new.* (under ~/.claude, sandbox denyWrite) → payload_hash re-check (:729) → mv swap (:755-768)
B5: $DEST ~/.config/claude-devcontainer (not in documented denyWrite) → cc-isolated.sh --bless (:410) → blessed manifest
B6: file names / contents / process cmdlines            → vis (:119-126)          → user's terminal (the review)
B7: backup dir names under $bkroot (inside ~/.claude)    → prune loop (:796-807)   → rm -rf
B8: checkout path components to claude-home (moved/hardened) → -L walk (:334-345) → rm -rf / mkdir / cp mirror (:353-358)
```

**Input-source classification**

```
S1: committed payload (HEAD, .git objects)      — runtime-mutable (agents commit)  — UNTRUSTED for content (hence the review); the review is the control
S2: .git/config, .git/info/attributes           — runtime-mutable (host agents; cc-isolated bind mount)
                                                  — UNTRUSTED toward exec sinks (git runs fsmonitor/filter commands from it)
S3: stage files in ${TMPDIR:-/tmp}              — mutable by any same-uid writer during the run
                                                  — UNTRUSTED between hash/review and install unless the location is agent-unwritable
S4: pgrep -af output (process command lines)    — chosen by each process (argv is self-set)
                                                  — trusted as evidence of PRESENCE only; absence is not evidence of no agent
S5: docker ps stdout / exit status              — daemon + CLI + env (DOCKER_HOST/DOCKER_CONTEXT)
                                                  — presence evidence only; a failure is treated as absence (fail-open)
S6: PATH-resolved tools (pgrep, docker, perl, git, diff, sha256sum) — user env, deploy-time
                                                  — trusted; a writable PATH dir is host control (outside this review)
S7: backup dir names in $bkroot                 — mutable only by writers of ~/.claude (denyWrite for sandboxed Bash)
                                                  — trusted for the rm sink only to the extent denyWrite holds
S8: CLAUDE_HOME_DIR / TMPDIR / HOME from the user's terminal — deploy-time — trusted (control chars refused, :924-932)
```

What enters from outside: agent-authored commits and `.git` state (S1, S2), whatever a same-uid process writes into the stage during the run (S3), and the process table and docker as the gate's evidence (S4, S5). The diff adds B3 as a new boundary. The gate turns "no agent at three instants, by name" into "no agent throughout", and that inference is where F1–F3 live. B1's exec sink (S2) is a boundary the gate cannot reach, because the state is persistent.

---

## Findings

#### F1: Host target: a swap-and-revert during the review installs content the review never showed (R1, host half)

**Severity:** High
**Location:** `devcontainer-config/install.sh:585-589`, `:640-671`, `:695`, `:729-734`; `docs/decisions/037-bare-host-copy-install.md:66`
**Boundary:** B2, B3
**Move:** #4 (TOCTOU), #11 (guardrail bypass)
**Confidence:** High for the mechanism (executed 6/6). Medium for reach: see "depends on" below.
**Legibility-target:** for-author
**Class:** (a) for the 037:66 claim; the mechanism is (b) under Q-058 [2]; (c) fix available.

**Evidence** (verbatim; `install_claude_home()` runs :530-816, read whole):
```
  assemble "$stage"
  # R2: the stage sits in a same-uid temp dir while [y/N] waits. Hash it before
  # the review; after the y, the copies made under $dest must hash the same.
  local reviewed_hash
  reviewed_hash="$(payload_hash "$stage" "" "$stage/.manifest")"
```
(:585-589. The review follows at :593-675 and reads `$stage` again: `if ! review_diff "$view" "$stage" "${diffnames[@]}"; then changed=1; fi` at :670.)
```
  if [ "$(payload_hash "$dest" .cw-new. "$dest/.cw-new.manifest")" != "$reviewed_hash" ]; then
```
(:729, which compares against the pre-review hash; the function continues through the swap to :816)

037:66: `The hash check (R2) catches a stage edited while the prompt waits.`

The hash fixes the stage's bytes *before* the review reads them. The review is a second read of the same files. A writer that replaces `payload/hooks/h.sh` with a benign copy after `:589`, lets `review_diff` read that copy, and restores the original before y makes the review show benign content. The hash check then passes, because the installed bytes are the hashed bytes. **SP1** (`execution-logs/secrev-q058-b4fd792/probe.bats`) sets this up. The commit makes `hooks/h.sh` print `MALICIOUS-PAYLOAD` and also changes `guides/g.md` benignly. A background helper watches for `$HOST_TMP/installed`, which is created after the hash at `:642`, then swaps h.sh to the installed version and restores it 1.5 s later. The pgrep and docker stubs report nothing running. Result, 6/6 runs: the review shows only `+guide v2 benign`, the run prints `Installed into …`, and `~/.claude/hooks/h.sh` contains `echo MALICIOUS-PAYLOAD`. The only thing between an agent and this outcome is the premise that no writer is active between the startup gate (:947) and the host gate (:695). The gate samples that premise (F3); nothing enforces it.

**What reach depends on (not verified here):** the documented bare-host sandbox allows Bash writes to the session's `$TMPDIR` and scratchpad, not to bare `/tmp` (`guides/sandbox-tool-map.md:44`). With `TMPDIR` unset in the user's terminal, the stage sits at `/tmp/cw-host-stage.*`, where sandboxed Bash cannot write. The writers that remain are the Edit/Write tools (governed by permissions, not bwrap; `~/.claude` is in `permissions.deny`, `/tmp/cw-*` is not), unsandboxed Bash, and a host without the sandbox. Each of these must also be invisible at the host y (F3). Impact if reached: an unsandboxed hook in `~/.claude`, which runs in every session, i.e. an escape from the denyWrite barrier.

**Recommendation:** (c, structural, about 15 lines) Before the review, copy the stage into `$dest/.cw-new.*`, which is behind `denyWrite ~/.claude`, the same copies step 1 makes today. Review those copies against `$view`, and on y hash-check and swap exactly those. On n or error, `rm_new_copies`. The review then reads the bytes that get installed, from a location sandboxed agents cannot write, so the sampling gate is no longer load-bearing for the host target. Take the lock before the pre-review copy. (b, minimum) If not fixed, replace 037:66 with: "The hash check covers only the host target, and only edits that persist until the copy step. A writer that swaps the stage during the review and restores it before y is caught only if the gate sees it at y."

#### F2: Devcontainer target: nothing checks that what is installed and blessed is what was reviewed (R1, target-1 half; E1)

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:346-368`, `:390-410`; `docs/decisions/037-bare-host-copy-install.md:66`
**Boundary:** B2, B3, B5
**Move:** #4, #5
**Confidence:** High (P3, executed in fact-check r2 E2; code read whole, `install_devcontainer()` :321-424)
**Legibility-target:** for-author
**Class:** (a) the 037:66 assurance does not cover this target; (c) fix available.

**Evidence:**
```
  # Q-058: an agent may have started while the prompt waited.
  agent_gate "Nothing was installed. (devcontainer config)"

  mkdir -p "$DEST" "$BIN_DIR"
```
(:390-393 …)
```
  for item in "${PAYLOAD[@]}"; do
    rm -rf "${DEST:?}/$item"
    cp -Rp "$stage/$item" "$DEST/$item"
  done
```
(:399-402 …, then `CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless` at :410; the function ends :424 with no hash anywhere.)

This target has the gate at y and nothing else. Fact-check r2's P3 edited `$TMPDIR/cw-devc-stage.*/config/devcontainer.json` while the prompt waited. No agent was detected at y, and the edited file was installed and then blessed (`BLESS-STUB --bless`). The bless (`cc-isolated.sh:171-178`) hashes whatever is in `$DEST`, so it certifies the tampered boundary config. The payload is the sandbox boundary: firewall, egress lists, and the host-run `cc-isolated.sh`.

This is Medium, not High, because the marginal exposure depends on `$DEST` being protected. The documented denyWrite list covers `~/.claude`, `~/CLAUDE.md` and the auditor only (`guides/bare-host-hook-wiring.md:77-78`), and `cc-isolated.sh --bless` has no human guard (`cc-isolated.sh:549`). Any writer that can reach `~/.config/claude-devcontainer` can already edit it and re-bless without the installer. The sandbox's default allowlist ($TMPDIR, the scratchpad, the cwd) probably keeps sandboxed Bash out of both. Not verified.

**Recommendation:** (c) Use `payload_hash`'s pattern: hash the staged PAYLOAD before `mode_diff`/`review_diff` (`:367`). After the copy loop (`:399-402`) and before `--bless` (`:410`), hash `$DEST`'s PAYLOAD items and refuse on mismatch. This catches edits that persist but, like F1, not swap-and-revert. For parity with F1's fix, stage under `$DEST/.cw-stage.*` and add `~/.config/claude-devcontainer` to the sandbox denyWrite in `guides/bare-host-hook-wiring.md` §3. (b, minimum) State in 037 that target 1 relies on the gate alone.

#### F3: The gate samples three instants and recognizes only Claude-shaped command lines; 037's residual list omits what that misses (E2)

**Severity:** Medium
**Location:** `devcontainer-config/install.sh:834`, `:838-886`, call sites `:947`, `:391`, `:695`; no call before `assemble` in `install_claude_home` (`:583-585`); `docs/decisions/037-bare-host-copy-install.md:75`; `guides/bare-host-hook-wiring.md:17-20`
**Boundary:** B3
**Move:** #5 (invert the access control), #11
**Confidence:** High (regex misses executed as SP2; P4 executed in r2)
**Legibility-target:** for-orchestrator-synthesis (it needs the user's answer on Q-058 scope)
**Class:** (b) inherent to a probe gate; (a) for the undocumented part; (c) cheap narrowing available.

**Evidence:**
```
CLAUDE_PROC_RE='(^|/)claude(\.exe)?( |$)|/@anthropic-ai/claude-code/'
```
(:834)
```
  procs="$(pgrep -u "$(id -u)" -af -- "$CLAUDE_PROC_RE")" || rc=$?
```
(:845, inside `agent_gate()` :838-886, read whole; `procs` is used at :850 ($$ filter) and :869/:873-876 (refuse and name))

037:75: `- A process the probe misses: an agent on another host or in another container runtime writing the checkout (a network or shared mount), a renamed or wrapped binary whose command line does not end in \`claude\`, one running under another uid, or a docker the user's uid cannot reach.`

Inverting the check shows what it does not refuse: (i) a writer active only between samples. P4: an agent visible during the devcontainer prompt, answered n, lets the host target stage and review while it runs, because there is no gate before `assemble` at :585. (ii) Same-uid processes that aren't Claude: a detached helper, or a loop driver (`bash ralph-loop.sh`) between iterations. SP2: `MISS`. (iii) Claude shapes the regex misses. SP2: `…/share/claude/versions/2.1.3 --resume`, `node …/@anthropic-ai/claude-agent-sdk/cli.js`, and `node cli.js` all `MISS`. The 037 list names none of (i)–(iii), and "does not end in `claude`" misdescribes the regex, which anchors on `claude` followed by a space or end of line, not on line end. The guide's "refuses to stage … while either runs" is broader than the code. (i) and (ii) are what make F1 and F2 reachable.

**Recommendation:** (b) Add (i)–(iii) to 037's residuals and ask the user the r2 question (see Escalate). (c) Three cheap changes, all fail-closed: call `agent_gate` at the top of `install_claude_home` after the skip rules (one line, closes P4's staging window). Widen the regex with `|/claude/versions/|/claude-agent-sdk/` (false positives refuse and name the process, as today). Optionally refuse any other process of this uid whose `/proc/<pid>/cwd` resolves inside `$REPO_ROOT`, excluding `$$` and its ancestors. That catches helpers and loop drivers started in the checkout, whatever their name.

#### F4: `.git/config` and `.git/info/attributes` run commands as the host user during every install; a cc-isolated container can plant them, and the gate cannot see persistent state

**Severity:** High
**Location:** `devcontainer-config/install.sh:162-163`, `:225-226` (pre-existing code); `docs/decisions/037-bare-host-copy-install.md:74` (the in-scope acceptance)
**Boundary:** B1
**Move:** #1 (runtime-mutable ⇒ compromise-reachable), #12
**Confidence:** High (SP3 executed with git 2.39.5. 037:64 itself states that a container writes `.git` through its bind mount.)
**Legibility-target:** for-author
**Class:** (a) the accepted-residual rationale is inaccurate; (c) cheap hardening.

**Evidence:**
```
  if ! git -C "$REPO_ROOT" -c tar.umask=022 archive --format=tar "$commit" -- "$@" \
       | tar -xpf - -C "$dir/.extract"; then
```
(:162-163, inside `extract_commit()` :140-200)
```
  dirty="$(git -C "$REPO_ROOT" -c core.quotePath=true status --porcelain --untracked-files=all -- "${CLAUDE_HOME_SRC[@]}" "$@")"
```
(:225, inside `assemble()` :212-242; :226 repeats it)

037:74: `- git obeys the checkout's \`.git/config\` (hooks paths, \`core.fsmonitor\`, filters) when \`install.sh\` runs \`git archive\` and \`git status\`. Any git command the user runs in the checkout has the same exposure; it is not specific to the installer.`

SP3 (`execution-logs/secrev-q058-b4fd792/sp3-git-config-exec.log`): with `filter.pwn.smudge` in `.git/config` and `*.txt filter=pwn` in `.git/info/attributes`, the same `git -c tar.umask=022 archive` invocation ran the smudge command. `git status --porcelain` ran `core.fsmonitor` twice. So an agent in a cc-isolated container, the isolated one, can plant a command that the user's own unsandboxed shell runs the next time `install.sh` runs. That is a container-to-host escape. This is persistent state, so the Q-058 gate is irrelevant: the container has long since stopped. "Any git command the user runs has the same exposure" is true but misleading. The installer is the one git-running program the user is *required* to run on the bare host, and it runs on every install. The rationale also gives the gate credit for nothing here, though the section is framed as residuals of the gate.

**Recommendation:** (c) Add `-c core.fsmonitor=false` to the two `status` calls. Before any git call, refuse when `git config --local --get-regexp '^(filter\.|core\.fsmonitor|include|includeif)'` prints anything, or when `.git/info/attributes` is non-empty, naming the entry. As an alternative for the archive, extract with `git ls-tree -rz` + `git cat-file blob`, which applies no filters. (a) Rewrite 037:74 to name the container-to-host path and whichever mitigation is chosen. Ask the user to accept it explicitly if it stays unfixed: 66891a7 records the acceptance with "Notes: none", in an autonomous commit.

#### F5: 037's TAB/newline residual rationale is false (P5); the real reason it is low-risk is denyWrite, not the gate

**Severity:** Low
**Location:** `docs/decisions/037-bare-host-copy-install.md:73`; mechanism `devcontainer-config/install.sh:796-807` (pre-existing)
**Boundary:** B7
**Move:** #11
**Confidence:** High (P5 executed in r2 E3)
**Legibility-target:** for-author
**Class:** (a) doc; (c) one-line hardening.

**Evidence:**
037:73: `Both need a crafted name, which needs an agent, which the gate refuses.`
```
        case "$d" in *$'\n'*) continue ;; esac
```
(:801, inside the prune `while … done < <( for d in "$bkroot"/*/; do …` loop :796-807; its output `… | tail -n +3 | cut -f2)` at :807 feeds `rm -rf "${bkroot:?}/$old"` at :797)

The gate checks for running processes. A name planted earlier survives into the run. P5 planted `20200101T000000Z<TAB>junk`, and the prune deleted a real, kept backup. The planted name lives in `~/.claude/.claude-workflows-backup`, where sandboxed Bash is denied writes. That is the true reason the risk is low. Below Medium because planting requires writing inside a denyWrite path, which is host-level control (floor-rule exemption).

**Recommendation:** Change :801 to `case "$d" in *$'\n'*|*$'\t'*) continue ;; esac`, then drop the TAB half of the residual. Otherwise rewrite the 037:73 reason as "needs a write inside `~/.claude` (sandbox denyWrite) or the user's choice of working directory".

#### F6: A docker failure is treated as "no cc-isolated container" (fail-open on the model's "cc-isolated counts")

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:853-868`
**Boundary:** B3
**Move:** #3 (error path), #5
**Confidence:** High (T52 pins the behaviour; fact-check noted the `DOCKER_HOST`/`DOCKER_CONTEXT` redirect)
**Legibility-target:** for-orchestrator-synthesis
**Class:** (b)

**Evidence:**
```
    if ! ctrs="$(timeout 20 docker ps --filter label=cc-project \
                   --format '{{.Names}} cc-project={{.Label "cc-project"}}' 2>"$errf")"; then
      err="$(head -n 1 "$errf" 2>/dev/null)"
      echo "NOTE: docker is unreachable ($err): cc-isolated containers not checked, treated as none running." | vis
      ctrs=""
    fi
```
(:860-865, inside `agent_gate()` :838-886)

Informational, not Medium, because I found no mechanism by which a container running during the install breaks review = install. A container cannot reach the host `$TMPDIR` stage (B2). Its checkout writes after staging do not reach the stage. Its one real channel, F4, is persistent and time-independent. The container half of the gate is therefore mostly hygiene. That is worth saying in 037, so nobody later relies on it or "fixes" the fail-open at the cost of refusing whenever docker hiccups.

**Recommendation:** Add one 037 sentence: "the container check is not load-bearing for review = install; a container's route to the host is `.git` state (see the git residual)".

#### F7: fa69656's Notes misdescribe how non-`review_diff` vis failures are handled

**Severity:** Informational
**Location:** commit fa69656 message; `devcontainer-config/install.sh:293-303` (`mode_diff`), `:600-647`
**Boundary:** B6
**Move:** #3
**Confidence:** High (errexit-under-`||` semantics executed; r1/r3 fact-check)
**Legibility-target:** for-author
**Class:** (a) commit-message accuracy only; fails closed.

**Evidence:** fa69656 Notes: `other \`| vis\` uses (MODE, MOVE, ADD lines) are not individually checked; perl missing is now refused up front, and a vis that fails there fails in review_diff too, which aborts.`
```
        echo "MODE $dest/$item${p%/}: ${dm[$p]} -> ${rec%% *}" | vis
```
(:299, inside `mode_diff()` :287-305, called as `mode_diff … || same=0` at :367 and `if ! mode_diff …` at :668)

At the MOVE/REPLACE/ADD sites, a vis failure kills the script through `set -e`/`pipefail` before `review_diff` runs, with exit 1 and no message. It fails closed, but not "in review_diff". Inside `mode_diff`, errexit is suppressed because of the `||`/`if !` context (confirmed: `f || …` continues past a failing pipeline inside `f`), so a MODE line can vanish. `review_diff` runs vis over the same items right after and aborts on any lasting vis failure. A failure transient enough to hit only the MODE line is not a realistic attack path.

**Recommendation:** Correct the explanation wherever it is carried forward (plan or 037). No code change needed.

#### F8: Do not add a re-hash immediately before the swap (E2, second half)

**Severity:** Informational
**Location:** `devcontainer-config/install.sh:729-768`
**Boundary:** B4
**Move:** #4 ("not security theater")
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Class:** (c) rejected hardening option.

**Evidence:**
```
  if [ "$(payload_hash "$dest" .cw-new. "$dest/.cw-new.manifest")" != "$reviewed_hash" ]; then
```
(:729; the swap follows at :755-768 as `mv "$dest/.cw-new.$name" "$dest/$name" || host_rollback`, and the function continues to :816)

The window between :729 and :766 is on `$dest/.cw-new.*`, inside `$dest`. Any writer that can edit there can edit `$dest/hooks` directly after the install, so a second hash only moves the line. The worthwhile fix for this window is F1's, which moves the *review* onto these protected copies.

---

## Untested bypass candidates

| Candidate | Guard | Why not tested |
|---|---|---|
| A sandboxed Bash process that outlives its Claude session (setsid/nohup) and keeps writing | agent_gate (B3), F1/F2 premise | Needs the real bare-host bwrap (pid namespace / `--die-with-parent` flags unknown). This environment is a container without bwrap. If sandboxed children die with the session, (ii) in F3 narrows to unsandboxed writers. |
| Sandbox write reach to bare `/tmp/cw-*-stage.*` | F1/F2 reach | Only the repo's own statement (`sandbox-tool-map.md:44`) says bare `/tmp` is not allowlisted. Not executed on a bare host. |
| Edit/Write tool writes to `/tmp/cw-*` under auto mode | F1 reach | Depends on the permission and classifier configuration of the user's host sessions. |
| The claude-home mirror `mkdir`→`cp` swap to a symlink (`:354-358`) | B8 no-follow rebuild | Needs a between-checks writer (F3 class). The target is only a new `claude-home` subdir wherever it points, with committed content. Documented as a residual in dfa5791. |
| `DOCKER_HOST`/`DOCKER_CONTEXT` pointing at another daemon, giving an empty list with exit 0 and no NOTE | F6 | Not executed. Informational per F6 either way. |
| The VS Code extension's process shape | CLAUDE_PROC_RE | No host access. b4fd792's Notes also mark it unverified. |

Because of these, neither `agent_gate` nor the no-follow rebuild appears in the endorsements below as a guardrail claim.

---

## Endorsement Claims

- **Claim:** perl's absence is refused before any staging or gate.
  **Location:** `devcontainer-config/install.sh:940-947`
  **Evidence:** executed (T57, fact-check r1–r3, 315/315)
  **Verified:** `command -v perl` failure exits 1 before `agent_gate` and before `trap host_cleanup EXIT`; T57 passes.
  **Not verified:** a perl present but broken for `-pe` only at the MODE sites (F7).
  **route: code-fact-check**
- **Claim:** a vis failure inside `review_diff` exits 1 before the `[y/N]` prompt on both targets.
  **Location:** `devcontainer-config/install.sh:265-271`
  **Evidence:** executed (T58)
  **Verified:** T58's perl stub fails `-pe` only; output has `could not show the review`, no `bless it?`.
  **Not verified:** the host target's ADD path (`:650`, `review_diff … || true`), which relies on the same in-function `exit 1`; read-static only.
  **route: code-fact-check**
- **Claim:** NUL-holding staged files are refused on both targets before any review.
  **Location:** `devcontainer-config/install.sh:185-199`
  **Evidence:** executed (T61)
  **Verified:** T61 refuses `hooks/blob.bin` (host) and `egress/x.bin` (devcontainer) with no `[y/N]`.
  **Not verified:** a file the scan's `open` fails on mid-run (perl `die` → the `if !` branch), read-static only.
  **route: code-fact-check**
- **Claim:** on the host target, a stage edit that persists from after the hash until the copy step is refused.
  **Location:** `devcontainer-config/install.sh:589`, `:729-734`
  **Evidence:** executed (existing T43-class tests)
  **Verified:** hash mismatch → `stage changed after review`, nothing replaced.
  **Not verified:** an edit reverted before the copy step. That is F1, where the claim does not hold.
- **Claim:** gate output (process command lines, container names, docker stderr) passes through vis before reaching the terminal.
  **Location:** `devcontainer-config/install.sh:863`, `:870-884`
  **Evidence:** read-static
  **Verified:** both the NOTE line and the whole refusal block are piped to `vis`.
  **Not verified:** the `pgrep is not installed` / `pgrep failed` messages at :841-848, which print no external data, so vis is not needed there.

---

## Primitive sweep

**Primitive: git invocation reading checkout config (exec via fsmonitor/filter/include)**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `install.sh:130` `git rev-parse --verify` | S2 | none | cleared: rev-parse runs no fsmonitor or filters (read-static) |
| `install.sh:150` `git cat-file -e` | S2 | none | cleared: object existence only |
| `install.sh:162` `git archive` | S1, S2 | none | **F4** (smudge filter runs, SP3) |
| `install.sh:225` `git status --porcelain` | S2 | none | **F4** (fsmonitor runs, SP3) |
| `install.sh:226` `git status --porcelain` | S2 | none | **F4** (same) |

**Primitive: `rm -rf` / recursive delete (path sink)**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:170` `rm -rf "$dir/.extract"` | mktemp stage | private mktemp dir | cleared |
| `:215` `rm -rf "$stage"` | mktemp stage | private mktemp dir | cleared |
| `:353` `rm -rf "$SRC/claude-home"` (changed) | S1 checkout path | -L walk :334-345, no trailing slash | cleared for a link planted before the run (T59, T60). A between-checks swap is an untested candidate (B8) |
| `:400` `rm -rf "${DEST:?}/$item"` | S8 DEST, code-constant PAYLOAD | `:?`, control chars refused | cleared (pre-existing) |
| `:488` `rm -rf "${1:?}/.cw-new.$n"` | S8 | fixed names, `:?` | cleared |
| `:504-505` cleanup of HOST_TMP / DC_TMP | mktemp | set only from mktemp | cleared |
| `:513` rollback `rm -rf "${dest:?}/$n"` | code-constant names | only `swapped` entries | cleared |
| `:715` `rm -rf "$dest/.cw-new.$name"` | S8 | `-L` refusal at :574-578 | cleared (pre-existing) |
| `:797` prune `rm -rf "${bkroot:?}/$old"` | S7 names | newline skip, stamp check | **F5** (a TAB name mis-prunes) |

**Primitive: process listing as an authorization signal (new, B3)**

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:845` `pgrep -u uid -af` | S4 | regex :834, `$$` filter | **F3** |
| `:860` `docker ps --filter label=cc-project` | S5 | 20 s timeout, stdout only | **F6** |

---

## Summary Table

| # | Finding | Severity | Class | Boundary | Location | Confidence |
|---|---------|----------|-------|----------|----------|------------|
| F1 | Host: swap-and-revert during the review installs unreviewed content; 037:66 overclaims | High | (a) doc + (b) mechanism; (c) fix | B2, B3 | `install.sh:585-589,:729`; 037:66 | High (mechanism) / Medium (reach) |
| F4 | `.git/config` / attributes run commands as the host user on every install; a container can plant them; 037:74 understates | High | (a) + (c) | B1 | `install.sh:162,225-226`; 037:74 | High |
| F2 | Devcontainer: no content check between review and install/bless | Medium | (a) + (c) | B2, B3, B5 | `install.sh:390-410`; 037:66 | High |
| F3 | Gate samples 3 instants, recognizes Claude-shaped cmdlines only; 037 residuals omit this | Medium | (b) + (a) + (c) | B3 | `install.sh:834,845,585`; 037:75 | High |
| F5 | TAB residual rationale false; real reason is denyWrite; 1-line prune fix | Low | (a) + (c) | B7 | 037:73; `install.sh:801` | High |
| F6 | docker failure → no containers (fail-open), not load-bearing | Informational | (b) | B3 | `install.sh:860-865` | High |
| F7 | fa69656 Notes misdescribe vis-failure handling (fails closed) | Informational | (a) | B6 | fa69656; `install.sh:299` | High |
| F8 | Re-hash before swap would be theater; don't add it | Informational | (c) rejected | B4 | `install.sh:729-768` | High |

## Overall Assessment

The restart does what its commits say. The perl requirement, the vis abort, the NUL refusal, the no-follow mirror rebuild and the three gate calls all hold, and R2 is closed. It does not change the mechanism behind R1. On the host target the review and the install still read the stage twice, and on target 1 nothing links them at all. What changed is the premise: the install now proceeds only if no Claude-shaped process is seen at three instants. Q-058 [2] makes that premise the guarantee, which is a coherent trust model. But decision 037 currently promises more than the code delivers (the hash "catches a stage edited while the prompt waits"). It also omits the residuals a sampling, name-based gate inherently leaves: writers between checks, same-uid non-Claude helpers, regex misses. So the issues are fixable in place, and none is architectural. The most important single item is F4, not R1. Every install runs commands from `.git/config` as the unsandboxed host user, a cc-isolated container can write them, and the fix is a few lines. After that comes F1's structural fix: review and install the protected `$dest/.cw-new.*` copies, which removes the host target's dependence on the gate. At minimum, correct 037:66, :73, :74 and :75 before merge. No findings within the code paths read beyond those listed. Endorsement claims are pending execution verification where marked `route: code-fact-check`.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved to the output path named at the end of this prompt, structured per the skill.
- Answered: whether R1/R2 are resolved under Q-058 [2]. R2 is resolved. R1's mechanism is intact (SP1 host 6/6, P3 devcontainer) and is now bounded only by the sampling gate. It is a documentation red (037:66/:75 overclaim), not a code red under the chosen model. Findings are separated into (a) promised but not delivered (F1/F2 doc parts, F3 residual list, F4 rationale, F5 rationale), (b) inherent residuals (F3 i–iii, F6), and (c) hardening (stage under `$dest`, target-1 hash, one gate before host `assemble`, a broader regex or cwd probe, git config refusal, a TAB case; F8 rejects the pre-swap re-hash).
- Out of scope: `cc-isolated.sh --bless` having no human guard, and `~/.config/claude-devcontainer` missing from the documented denyWrite. Both are pre-existing, outside the file list, and cited only to calibrate F2. The `docs/reviews/` files in the range (context only).
- Escalate: (1) **User judgment (the r2 open question):** does a same-uid process left running by an earlier agent session, or a loop driver between its `claude` iterations, count as "an agent" under Q-058 [2]? If yes, the pgrep probe cannot enforce it, so either take F1's structural fix or record it as an accepted residual in 037. My recommendation: take F1's fix, which makes the question moot for the host target. (2) **F4 acceptance:** 037:74's acceptance of `.git/config` exec was written in an autonomous commit (66891a7, "Notes: none"). Whether the user knowingly accepts a container-to-host exec path triggered by every install should be confirmed, or the 2-5 line fix taken. (3) **Environment facts to verify on the bare host (you: terminal):** whether bwrap-sandboxed Bash processes can outlive their session, and whether sandboxed Bash can write `/tmp/cw-*`. These set F1/F2's reach.
- Questions I would have asked: whether the user's terminal sets `TMPDIR`, and to what (it decides whether the stage sits inside a sandbox-allowlisted path).
- Decisions I made: I rated F4 High although the code predates the range, because the range's 037 text accepts it with a rationale that doesn't hold, and container escape is High under the skill's guidelines. I ran my own SP1/SP2/SP3 probes rather than relying only on r2's, because the fact-check did not exercise the host target's swap-and-revert, which is the original R1 wording. I saved the probe harness and logs under `docs/reviews/execution-logs/secrev-q058-b4fd792/` so "executed" is auditable.
