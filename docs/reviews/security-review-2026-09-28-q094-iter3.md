Commit: ba03833

# Security Review — Q-094 units A and B, review-fix iteration 3

**Scope:** `git diff 5fadfc2..ba03833`. That is 037621f (unit A, iteration-2 fix: an insteadOf base of `.` keeps a W record; confirming pass) and ba03833 (unit B `q094b-exit-scan-worktree-removal`, which accepts a standard worktree removed during the session; first review). I read all of `devcontainer-config/cc-exit-scan.sh` at ba03833, including `scan_std_worktrees`, `git_exit_scan`, `_snap_config`, `_snap_remote`, `_snap_gitdir`, `_snap_dotgit` and `git_exec_snapshot` in full, and the Q-094 tests at the end of `test/cc-isolated-functions.bats`. I checked the whole branch (`dfe4c0d...HEAD`) before flagging anything as missing.
**Date:** 2026-09-28
**Based on:** the iteration-1 and iteration-2 security reviews (`docs/reviews/security-review-2026-09-28-q094.md`, `-iter2.md`) and the rubric `docs/reviews/code-review-rubric-2026-09-28-q094-exit-scan-worktree-layout.md`.

> ⚠️ **No code fact-check report provided.** Claims about security properties in comments and documentation have not been independently verified. For full verification, run the `code-fact-check` skill first or use the code-review orchestrator. Where a comment claim matters below, I checked it by experiment.

**Experiments:** `scratchpad/sec3/exp.bats` (E1–E12), log in `scratchpad/sec3/exp.log`. I ran them with bats against this worktree's `devcontainer-config/cc-isolated.sh` on git 2.39.5, with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1`, `set -o pipefail`, and every repo under `mktemp -d`. Planted bare repos have a `pre-receive` hook that leaves a marker file.
**Branch tests:** `bats -f Q-094 test/cc-isolated-functions.bats` gives 10/10 ok under `LC_ALL=C.UTF-8`. Under this sandbox's default `LC_ALL=en_US.UTF-8`, which is not installed, test 1 fails its one-line count because bash prints a `setlocale` warning. That comes from the environment, not the code.

## Trust Boundary Map

```
B1: container writes .git/worktrees/** and the working tree (bind mount) → git_exec_snapshot records → scan_std_worktrees accept/decline  (changed: "-" records now accepted)
B2: checkout config at launch (url.<base>.insteadOf bases) → _snap_config / _snap_remote / _snap_wrel → W record (refuses the note)       (changed: base "." now W)
B3: filesystem state at scan time (P existence, after the exit snapshot) → [ -e / -L ] tests in the removal branch → "P gone" decision      (new)
B4: host user runs git in the checkout, a remaining worktree, or a leftover working-tree dir → git discovery / remote resolution → hooks, config programs run as the user
```

Input-source classification:

```
S1: removed dotgit / commondir-file / hooksdir records ("-" lines; paths %q, attrs incl. content hash) — runtime-mutable (container) — UNTRUSTED toward the accept decision
S2: on-disk existence of P = <common>/worktrees/<n> at scan time   — runtime-mutable (container, incl. after claude exits) — UNTRUSTED; checked, not trusted
S3: insteadOf base strings in launch config                          — runtime-mutable (an earlier session, or you) — UNTRUSTED toward the exec sink "which repo a push runs hooks of"
S4: <n> taken from the commondir-file record path                    — runtime-mutable — UNTRUSTED for path construction; guarded by ^[A-Za-z0-9._-]+$, not . or ..
S5: _snap_hash_str of "gitdir: P\n" / container form; ../..\n hash   — code-derived from S4 and constants — trusted (hex only)
```

What crosses the boundaries: unit B lets S1 lines, which were rejected before, reach the accept decision. It pairs each removed private dir with one removed `.git` record by content hash (S5), and it trusts nothing about P on disk except that P is absent (S2). Unit A's fix changes one S3 → W mapping. The assumption the removal branch makes is that once P and the `.git` that named it are gone, host git has nothing new to run where they were. That assumption holds for what the scan records. It does not cover a leftover working-tree directory, which the scan never examined (Finding 2). The assumption behind the insteadOf fix is that `.` is the only base that starts a relative path without already making a W record, and that assumption fails for the empty base (Finding 1).

## Findings

#### 1. 037621f closes the insteadOf base `.` but not the empty base (`url..insteadOf`), which also rewrites to a relative path and makes no W record

**Severity:** Medium
**Legibility-target:** for-author
**Location:** `devcontainer-config/cc-exit-scan.sh:414-418` (the `url.*.insteadof|url.*.pushinsteadof` arm), and `:349` (`_snap_remote` returns early for `""`)
**Boundary:** B2 → B4
**Move:** #11 (bypasses of the new guard), #12 (every caller of `_snap_remote` with a base)
**Confidence:** High that the mechanism works (executed). Likelihood is low: the launch config must already hold an empty-subsection `url` rewrite.

Git accepts an empty subsection (`[url ""] insteadOf = https://x.invalid/`, key `url..insteadof`) and rewrites a matching URL to `""` + suffix. That is a bare relative path, resolved in whatever working tree git runs in. In `_snap_config`, `t` is `""`: the new line `[ "$t" != . ] || _snap_wrel …` does not fire, and `_snap_remote ""` returns 0 before its own `_snap_wrel`. The worktree acceptance therefore still grants the note, and its header contract ("a relative … local remote (not ".") … leave W records") is still false for this sibling of the iteration-2 finding. E1 and E1b, verbatim:

```
# resolved: evil
# W at launch: 0
# scan: status=0 | note: … (added: agent-x). They take config and hooks from the checkout's own .git, so this is not a finding.
# HOOK RAN (worktree push)
```

(E1b is `pushInsteadOf`, with identical scan and hook lines.) E12 confirms the launch snapshot holds the C record for the key and no W record. As in iteration 2, the top-level variant is the documented "rewritten URL is never walked" known route. The gap specific to this branch is that a *new worktree* receives the note. I also checked the other empty-after-scheme base: E11, `url.file://.insteadOf`, gives `fatal: no path specified` from git and runs no hook, so it is not a sibling.

**Recommendation:** Make the guard `[ -n "$t" ] && [ "$t" != . ] || _snap_wrel "$key" "$f" ./`, extend the comment to "a base "" or "." starts a relative path", and add `"url..insteadOf https://x.invalid/"` to the loop in the "relative hooksPath, attributesFile or remote" test.

#### 2. A removal is accepted while the removed worktree's directory remains, and that directory can be a bare repository host git will use

**Severity:** Informational (no new capability; see the reasoning below)
**Legibility-target:** for-author
**Location:** `devcontainer-config/cc-exit-scan.sh:855-869` (removal branch); guide `guides/cc-isolated-usage.md:334-337`
**Boundary:** B1 → B4
**Move:** #5 (what does the removal rule not prevent), #11
**Confidence:** High (executed)

The removal branch checks P and the `.git` record. It cannot check the working-tree directory, because P/gitdir, which named that directory, is gone. In E2 the session removes P and `wt/.git`, then turns `wt/` itself into a bare layout (`HEAD`, `objects/`, `refs/`, `config` with `core.pager`, `hooks/pre-receive`):

```
# scan-removed+planted: status=0 | note: … (removed: agent-x). …
# git-dir in WT resolves to: /tmp/tmp.2AZHVmNXuZ/r/wts/agent-x
# planted core.pager: touch /tmp/tmp.2AZHVmNXuZ/PAGER; cat
# control-fresh-plant: status=0 |
```

Host git run inside `wt/` uses it as its repository. Before ba03833 this exact combination warned, because any removal warned. It is still the documented known route "a repository in a working-tree directory not named `.git`": the control shows that the same plant in a fresh directory scans 0, silently, with or without this diff. So the attacker gains nothing they lacked. What changes is presentation: the note tells the user `removed: agent-x` about a directory that still exists and is now a repository, which is the directory the user most associates with "the agent's worktree". I rate it below the Medium floor on purpose. The property it violates ("a bare layout in a working-tree dir is reported") was never claimed and is documented as not held. The mechanism is not new.

**Recommendation (optional hardening):** Before accepting a removal, derive `wt` from the paired `-dotgit` record and decline when `looks_like_gitdir "$wt"`. Because `scan_std_worktrees` deliberately never unquotes, compare `printf '%q'` of the candidate the same way the added branch does. Alternatively, reword the note for removals to "git dir and `.git` gone (the directory may remain)".

## Untested bypass candidates

- **P present during the exit snapshot but absent at the `[ ! -e "$p" ]` check (a race by a process still running in the container), then recreated.** Not tested. It belongs to the documented "After the scan" route: any post-scan write defeats the tripwire regardless of this rule.
- **`<common>/worktrees` made unsearchable (mode 0600/0000) so that `-e P` reads false while P exists.** Read-static only: `_snap_nested` `cd`s into `worktrees/` and would fail the exit snapshot first (exit 2 or 4, fail closed). No fixture was run.
- **Container-form `/workspace/...` paths on a host where `/workspace` is itself another checkout.** E8 covers a container-form `.git` removed together with P (note, status 0). A host `/workspace` holding a different repository was not staged for the removal path. The removal branch makes no filesystem call on the container form, so I expect no effect.
- **git versions other than 2.39.5** (worktree layout, the empty-subsection rewrite). Not tested.

## Endorsement Claims

- **Claim:** A removed private dir P is accepted only with a removed `dotgit` record whose content hash is that of `gitdir: P\n` or its container form. A removal whose `.git` is still present, or another worktree's lone `-dotgit`, does not pair.
  **Location:** `devcontainer-config/cc-exit-scan.sh:855-868`
  **Evidence:** executed
  **Verified:** E3 (a copy of the `.git` removed on top of one clean removal gives status 1); branch test "a removed git dir pairs only with the .git that pointed at it" (status 1); E10 (two clean removals give `removed: a b`, status 0); E8 (container form, status 0).
  **Not verified:** a `-dotgit` record whose hash collides in its 16-hex (64-bit) prefix. This is a second-preimage requirement, not examined further.
  **route: code-fact-check**
- **Claim:** "P gone" is decided on the path itself, without following it. P replaced by a regular file or by a dangling symlink warns.
  **Location:** `devcontainer-config/cc-exit-scan.sh:856`
  **Evidence:** executed
  **Verified:** E5: `P-is-file: status=1`, `P-dangling-link: status=1`, `P-really-gone: status=0`. Branch test: a P kept but made invisible to the snapshot (no HEAD, no commondir) gives status 1.
  **Not verified:** an unsearchable `worktrees/` dir (see Untested).
- **Claim:** When a removed `dotgit` key is still present in the exit snapshot (the `.git` changed rather than went away), the new record must be consumed by an *added* standard worktree. Otherwise the scan warns.
  **Location:** `devcontainer-config/cc-exit-scan.sh:833, 891-905, 909`
  **Evidence:** executed
  **Verified:** E4: P removed with `.git` rewritten to the container form of the same P (status 1), to other content (status 1), or replaced by an empty dir (status 1). E6: `git worktree move` under the same name gives status 1, a false positive in the safe direction.
  **Not verified:** a remove-and-re-add at the same path under a *new* name. E6 tried this, but git reused the freed name, so the snapshots were identical (status 0, silent).
  **route: code-fact-check**
- **Claim:** A local remote that names the removed worktree's directory still gets walked. A bare layout planted there after removal warns.
  **Location:** `devcontainer-config/cc-exit-scan.sh:359-367` (unchanged), exercised through the removal branch
  **Evidence:** executed
  **Verified:** E7: removal alone gives status 0, and removal plus a bare plant at the remote's path gives status 1.
  **Not verified:** a relative remote naming it. That case would refuse the note through its W record, so it cannot reach this branch.
- **Claim:** An insteadOf base of exactly `.` now leaves a W record, and a new worktree then warns (the iteration-2 Finding 1).
  **Location:** `devcontainer-config/cc-exit-scan.sh:417`
  **Evidence:** executed
  **Verified:** the branch test loop entry `url...insteadOf https://x.invalid/` passes (status 1 expected and observed).
  **Not verified:** the empty base, which is Finding 1 and a counterexample to the general form of this claim.
  **route: code-fact-check**

## Primitive sweep

Primitive: path construction from container-chosen names and existence tests (feeding the accept decision)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `cc-exit-scan.sh:846-849` `n`, `p="$common/worktrees/$n"` | S4 | name regex, not `.`/`..`, %q round-trip equality | cleared: unchanged by ba03833, now also used for `-` records |
| `cc-exit-scan.sh:856` `[ ! -e "$p" ] && [ ! -L "$p" ]` | S2, S4 | both tests, not following | cleared: E5 |
| `cc-exit-scan.sh:859-861` hash of `gitdir: $p` / `$ccommon/worktrees/$n`, regex from the hashes | S5 | hex only in the regex | cleared: no filesystem access, no metacharacters |
| `cc-exit-scan.sh:862-865` `dot[]` / `used[]` lookups keyed by record lines | S1 | keys are whole %q record lines, sign included | cleared: E3, E4, E10 |
| `cc-exit-scan.sh:417` `_snap_wrel "$key" "$f" ./` | S3 | only for `t == .` | Finding 1 (misses `t == ""`) |
| `cc-exit-scan.sh:418` `_snap_remote "$t" "$base"` | S3 | early return for `""` and URLs | Finding 1 (for `""`), E11 cleared `file://` |

Exec sink (host git choosing a repository): discovery in a leftover working-tree dir falls under Finding 2. Discovery through a dangling `.git` (E3, E9) gives `fatal: not a git repository`, with no fallback and nothing run.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Empty insteadOf base (`url..insteadOf`) rewrites to a relative path with no W record; the iteration-2 fix covers only `.` | Medium | B2 → B4 | `cc-exit-scan.sh:414-418` | High (executed); low likelihood |
| 2 | Removal note while the old working-tree dir remains and can be a bare repo (known route, no new capability) | Informational | B1 → B4 | `cc-exit-scan.sh:855-869` | High (executed) |

## Overall Assessment

**Unit B (ba03833).** The content pairing does what the iteration-1 finding asked for. Across every probe I ran (copies, changed rather than removed `.git`, P faked gone, remove and re-add, container/host mix, a local remote at the old directory), the only states that pass are ones where host git has nothing newly planted to run from what the scan records. Each endorsement claim is `executed` and names its `Not verified` hop, so unit B is safe to merge within the code paths read. Finding 2 is optional hardening. **Unit A.** 037621f is correct for `.`, but it is one case short. The empty base is the same bypass class, confirmed end to end: note, status 0, and the planted hook runs on push from the new worktree. Its precondition is an unusual launch config, which is why it rates Medium rather than higher. It is a one-line guard change plus a test-loop entry, and it should land in unit A before merging. Unit B stacks on A, so it carries the same gap until then. There is no architectural problem. The most important thing to address is Finding 1's guard.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to docs/reviews/security-review-2026-09-28-q094-iter3.md, per the security-reviewer skill, `Commit: ba03833` at the top.
- Answered: yes. Removal-path probes all executed; unit B safe within the paths read; unit A needs the empty-base guard (Finding 1).
- Out of scope: post-scan writes by a still-running container (documented route); git versions other than 2.39.5.
- Escalate: Finding 1: extend 037621f's guard to `t == ""` in unit A before merging A and B.
- Decisions I made: I rated Finding 2 Informational rather than Medium under the floor rule, because the mechanism is a documented known route that the control shows needs no removal. Treating it as Medium would also have been defensible, since the note's wording is new.
