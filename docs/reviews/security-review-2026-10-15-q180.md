Commit: 46342d66

# Security Review — chore/q180-repin-pastes

**Scope:** `git diff main...HEAD` (b71a4e9e..46342d66): the Q-162/Q-163/Q-164 merge pastes, the Q-167(b), Q-169 and Q-176 paste edits, and the prose that says where and how they run
**Date:** 2026-10-15
**Based on:** `docs/reviews/code-fact-check-report.md` (k=3 merged, Commit 46342d66). Its Claim 1 escalation is the main input here.
**Probes:** `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/security-q180/` (`guard.txt`, `harness.sh`, per-case dirs `h-<shell>-<case>/`). Git 2.39.5, bash and zsh.

## Trust Boundary Map

```
B1: agent session (same uid) → writes /workspace/.git (config, info/, objects/, refs/, shallow) → the user's pasted git merge reads it
B2: agent session            → writes the container's shell startup (~/.zshrc, Claude Code's shell snapshot) → the shell that runs the paste
B3: /workspace/.git          → is a bind mount of the host's /home/magfrump/claude-workflows → host-side git in "your checkout" (Q-169, Q-156, any git-aware prompt)
B4: merged commit on main    → install.sh (git archive) on the host → host-installed tooling
```

Input sources:

```
S1: repo config (local, config.worktree, includes)     — runtime-mutable — UNTRUSTED for exec sinks (drivers, filters, fsmonitor, gpg.program) and for merge content
S2: .git/info/{attributes,grafts}, shallow, alternates — runtime-mutable — UNTRUSTED for history and merge content
S3: object store (loose objects, packs, commit-graph)  — runtime-mutable — UNTRUSTED for content; a commit's hash is checked on parse, a blob's is not
S4: refs/heads/main (the merge base)                   — runtime-mutable — UNTRUSTED for what main holds before the merge
S5: shell rc / snapshot in the container               — runtime-mutable — UNTRUSTED for which `git`/`test` runs
S6: pinned hashes in the paste text                    — code-constant   — trusted, for the merged-in side only
```

What enters: everything the merge reads apart from the pinned hash (S1–S5) can be written by an agent session. That includes the base it merges onto. The diff adds a guard for S2 (grafts, shallow) and S1/S3 replace refs, plus hooks-off and `GIT_NO_REPLACE_OBJECTS=1`. It also tells the user to run the pastes in the container. Because the container runs as the same uid as the agent, code that runs there gives the attacker nothing new. The asset is **integrity of what lands on main** (B4), and the host processes that touch the bind-mounted checkout (B3).

## Findings

#### F1: The guard leaves merge drivers, filters, fsmonitor, gpg.program, attributes, alternates and rewritten objects open, so the prose's "the hash names fixed content once the paste has checked …" overclaims

**Severity:** Medium
**Location:** `docs/working/questions.md:84` (claim), `:90-91`, `:119-122`, `:151-154` (guard and merge)
**Boundary:** B1, B4
**Move:** 11 (guardrail bypasses), 2
**Confidence:** High that the mechanisms work (executed). Medium that they matter beyond F2, because F2's cheaper route reaches the same asset.
**Legibility-target:** for-author

Evidence (verbatim, line 84): "the hash names fixed content once the paste has checked that no replace refs, `info/grafts` or `shallow` file exists, and the merge itself ignores replace refs".

The fact-check (Claim 1) found two things: a planted `merge.<x>.driver` plus `info/attributes`, or `core.fsmonitor`, runs under `GIT_NO_REPLACE_OBJECTS=1 git -c core.hooksPath=/dev/null merge`, and a rewritten loose blob merges with exit 0. I reproduced the second and found three more classes the fact-check did not list:
- **Filter drivers.** `filter.x.smudge` with `* filter=x` runs on every file the merge checks out. Probe `r1`: `SMUDGE-RAN` twice, exit 0. So it reaches **Q-162's own merge**, which has no file changed on both sides and so never reaches a merge driver.
- **gpg.program.** `commit.gpgSign=true` plus a planted `gpg.program` runs when the merge commit is written. Probe `r3`: `GPG-RAN`, then the merge failed.
- **Alternates and `info/attributes`.** Neither is checked, and `-c` cannot switch either off.

Code running in the container adds no capability, since the agent already has the uid. The harm is content: a driver chooses what lands in `docs/working/questions.md` and `docs/roadmap.md` during Q-164, and those files hold later host pastes. A rewritten blob can change any file, scripts included, and install.sh then carries it to the host (B4). These classes predate the branch. The branch's new sentence states a sufficient condition that does not hold.

**Recommendation:** replace the guard line in all three pastes with the guard below. Add `-c core.commitGraph=false` to the merge. Narrow the sentence: see F2's text, which also names what no guard closes.

Proposed guard. It keeps every existing check and adds build-loop.sh's `STATE_KEYS_RE` keys with `log.showsignature` dropped (merge does not log) and `fsck.` added, then `info/attributes`, alternates and a full `git fsck`:

```
{ test -z "$(git for-each-ref refs/replace/)" && test -z "$(git config --name-only --get-regexp '^(filter\.|include|hook\.|merge\.|diff\.|fsck\.|core\.fsmonitor|core\.attributesfile|core\.hookspath|gpg\.|extensions\.partialclone$|remote\..*\.promisor$)')" && g="$(git rev-parse --git-path info/grafts)" && s="$(git rev-parse --git-path shallow)" && a="$(git rev-parse --git-path info/attributes)" && o="$(git rev-parse --git-path objects/info/alternates)" && test ! -e "$g" && test ! -L "$g" && test ! -e "$s" && test ! -L "$s" && test ! -e "$a" && test ! -L "$a" && test ! -e "$o" && test ! -L "$o" && git -c core.commitGraph=false fsck --no-dangling --no-progress >/dev/null || { echo "replace refs, grafts, shallow, attributes, alternates, driver config or a bad object present: stop"; false; }; } && \
{ GIT_NO_REPLACE_OBJECTS=1 git -c core.hooksPath=/dev/null -c core.commitGraph=false merge --no-ff ... (unchanged)
```

How it was tested (`harness.sh`, 21 cases × bash and zsh, run with `bash -c` and `zsh -c` on a fresh copy of a scratch repo each time). It **refused** each of these, with nothing planted running and HEAD unmoved:
- merge driver + `info/attributes`; driver config alone
- filter
- `include.path`; `includeIf.gitdir:` → fsmonitor
- `core.fsmonitor`
- gpg
- `extensions.partialClone`; `remote.origin.promisor`
- `core.attributesFile`
- empty `info/attributes`
- alternates
- `info/grafts`; empty `shallow`; dangling-symlink `shallow`
- a replace ref
- a rewritten loose blob (fsck: "hash-path mismatch")
- grafts seen from a linked worktree

It **passed and merged** clean, in both shells, in the main checkout and in a linked worktree. Read-only, on the real `/workspace` and on `.claude/wt-q180`, it prints GUARD-PASS in about 5 s under both shells: fsck over 25k objects and 430 MiB of packs took 5 s, with no output. A planted `fsck.skipList` naming the bad blob did not hide the mismatch, and `fsck.` is refused anyway.

One side effect: the host's global `~/.gitconfig` sets `core.hooksPath` (Q-139's archive note), so on the host this guard refuses. That happens to enforce "run it in the container" for this user. If kept, end the message with "(run it in the container's /workspace)". Dropping `core\.hookspath` is also sound, since the merge already passes `-c core.hooksPath=/dev/null`, and none of the paste's other git calls (`worktree remove`, `branch -d`, `merge --abort`) run hooks.

#### F2: No guard can close the cheaper routes to the same asset: a moved main, a planted shell startup, a writer racing the paste. The prose should name them instead of implying the result is fixed

**Severity:** Medium
**Location:** `docs/working/questions.md:84` (claim), `:89`, `:118`, `:150` (`test "$(git branch --show-current)" = main` is the only check on the base)
**Boundary:** B1 (S4), B2 (S5), B4
**Move:** 5 (invert: what does the paste *not* check), 4 (TOCTOU)
**Confidence:** High for the moved-main mechanism (executed). Medium for shell startup: it depends on whether the session's sandbox lets the agent write `~/.zshrc`, though `scripts/build-loop.sh`'s caller_gate comment assumes "a loop can write ~/.zshrc".
**Legibility-target:** for-author

Evidence (verbatim, `:89`): `cd /workspace && test "$(git branch --show-current)" = main && \`

The pin fixes the merged-in side. Nothing fixes the base:
- **Moved main.** An agent that can write `.git` can commit a payload onto main (or `update-ref` it). The ancestor check `merge-base --is-ancestor 09a2876f HEAD` still passes, the proposed guard and fsck pass (the objects are valid), and the reviewed merge lands on top. Probe `h-bash-movedmain`: `git show HEAD:payload` → `PAYLOAD`, guard rc=0, in both shells.
- **Shell startup.** An alias or function for `git` or `test` in the container's shell startup defeats any guard written in the paste, because the paste runs in that shell. A `!` command runs in Claude Code's shell snapshot, which is built from the same startup files.
- **A concurrent writer.** An agent still running (a subagent, a background task in the session the `!` runs in) can plant state between the guard and the merge.

No line in the paste closes these at an attention cost the user would accept. Pinning main's tree would need the post-Q-180 merge hash, and that hash changes with each paste.

**Recommendation:** narrow line 84 to something like: "the merged side is the reviewed commit, provided the guard passes (no replace refs, grafts, shallow, attributes, alternates or driver config, and fsck clean). The paste does not check what main itself holds, or the shell it runs in. Run it while no agent session or subagent is working, and look over `git log --oneline --first-parent b71a4e9e..HEAD` before pasting: it should list only merges you made." Q-163/Q-164 inherit the wording through "as for Q-162". Optionally put the `git log` line at the head of Q-162's paste. It is the one cheap check on S4, and it costs the user a glance.

#### F3: `/workspace` *is* the host checkout (a bind mount), so "never in your host checkout" misdescribes it, and Q-169's paste `cd`s host shells into the agent-writable repo

**Severity:** Medium
**Location:** `docs/working/questions.md:84` ("never in your host checkout: it runs git in `/workspace`"); `:263` and `:266` (Q-169: `cd ~/claude-workflows && … git … show`, "Run it on the host, in your checkout")
**Boundary:** B3
**Move:** 1 (trace the boundary)
**Confidence:** High for the mount (read from `/proc/self/mountinfo`). Low–Medium for the exploit, which depends on the user's prompt.
**Legibility-target:** for-author

Evidence: mountinfo `… /home/magfrump/claude-workflows /workspace rw,relatime …`. Line 84 reads as if the host checkout were a separate, safe clone. It is the same `.git`. What the container instruction actually controls is *which process* runs git: a container shell versus a host shell. Running there is safe because in-container exec adds nothing (F1).

The inverse case is the risky one. Any host-side git that refreshes the index in `~/claude-workflows` runs a planted `core.fsmonitor` **on the host**. Probe `r7`: `git status` and `git diff --quiet` each ran the planted fsmonitor once, while `git show C:path` and `git rev-parse` did not. Many zsh prompts (vcs_info, oh-my-zsh git plugins) run status- or diff-class commands on `cd`. Q-169's paste starts with `cd ~/claude-workflows`. The `git show` that follows is benign: probe `r4` piped it, and the planted textconv and core.pager did not run. The sha256 check covers content.

This is pre-existing. The branch edited Q-169's line, and the new line-84 wording makes the boundary sound stronger than it is.

**Recommendation:**
- Change line 84's parenthetical to: "the container's `/workspace` is your host checkout, bind-mounted; run the paste from a container shell so any planted git config runs there, not on your host."
- In Q-169 (`:263`), drop the `cd` and use `git -C ~/claude-workflows -c core.useReplaceRefs=false show …`, so the host shell's prompt never enters the repo.
- Add an orchestrator note for Q-156's host release (install.sh from a checkout at main). It is outside this diff, but it is the same boundary.

#### F4: Paste text is read from an agent-writable working tree

**Severity:** Informational
**Location:** `docs/working/questions.md` (all `you: terminal` entries)
**Boundary:** B1/B3
**Move:** 2
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Every hash, guard and expected sha256 the user trusts comes from `questions.md`. In `/workspace` (= the host checkout) the agent can edit that file without committing. The pastes' guarantees hold only for text read from a committed, reviewed revision (for example `git show <main-hash>:docs/working/questions.md`, or a reviewer's relay). This is pre-existing and wider than this diff. It is listed so that F1's fix is not read as closing it.

**Recommendation:** none for this branch. Consider a revisit trigger or idea-log row on "trusted rendering of terminal pastes".

## Untested bypass candidates

- **A rewritten object inside a pack (with a matching .idx).** Not crafted. By git's documentation, `git fsck` verifies pack objects, but this was not executed.
- **A crafted `commit-graph` or `multi-pack-index` that lies about parents or object location.** Not crafted. The proposed merge and fsck pass `core.commitGraph=false`. The `merge-base --is-ancestor` branch selection does not, but the worst a lie there can do is pick the other reviewed hash. `core.multiPackIndex=false` (in build-loop's HARDEN) is not added: unknown whether a lying midx yields wrong content or an error.
- **Working-tree `.gitattributes` with a built-in driver (`merge=union`).** Not tested. It needs a conflicting hunk, and the pinned merges are expected to be clean.
- **A planted `MERGE_HEAD`.** Not tested. It makes the merge refuse, and the paste's `git merge --abort` then runs `reset --merge`. That affects availability of the user's staged work only.
- **Shell-startup aliases (F2) and a concurrent writer (F2).** Inherent. A guard in the paste cannot test the shell it runs in.

The existing guard and the proposed one both have untested candidates, so neither appears under Endorsement Claims.

## Endorsement Claims

- **Claim:** Prior F3 (Q-167(b) line 3 blessing on a pre-fix launcher) is closed: line 3 is now `cc-isolated --profile '#' --list`, which lists on main's launcher and exits 2 on f6f37fad's.
  **Location:** `docs/working/questions.md:225`
  **Evidence:** executed (fact-check Claim 19, all three replicates)
  **Verified:** both launcher versions, by the fact-check's probes
  **Not verified:** by this review directly; also a launcher between main and f6f37fad, if the user has one installed
  **route: code-fact-check**
- **Claim:** Prior F4 (Q-176's `mkdir -p` accepting a planted `~/q092`) is closed: `mkdir ~/q092 && mkdir ~/q092/.claude` stops on an existing directory, file, symlink or dangling symlink.
  **Location:** `docs/working/questions.md:390`
  **Evidence:** executed (fact-check Claim 23)
  **Verified:** those four planted states, with a fake HOME
  **Not verified:** a same-uid host writer racing the window between `mkdir ~/q092/.claude` and the `cat >` writes
  **route: code-fact-check**
- **Claim:** With `-m`, the pasted `git merge` does not launch a planted `core.editor`, even on a tty.
  **Location:** `docs/working/questions.md:91,122,154`
  **Evidence:** executed (probe `r2`, under `script` for a pty, with `GIT_EDITOR` unset)
  **Verified:** no editor ran; the merge commit message was the `-m` text
  **Not verified:** `GIT_MERGE_AUTOEDIT` or `--edit` set through the user's shell (F2's shell trust)
- **Claim:** A staged change to a path the merge does not touch makes the pasted merge refuse, so an agent cannot ride a payload in through `/workspace`'s index.
  **Location:** `docs/working/questions.md:91`
  **Evidence:** executed (probe `r6`: "Your local changes … would be overwritten by merge", rc=2)
  **Verified:** one staged modified file, ort strategy
  **Not verified:** a staged new file (an add rather than a modify)
- **Claim:** Q-169's piped `git -c core.useReplaceRefs=false show <hash>:<path>` ran no planted textconv, core.pager or core.fsmonitor.
  **Location:** `docs/working/questions.md:263`
  **Evidence:** executed (probes `r4`, `r7`)
  **Verified:** those three keys with stdout piped
  **Not verified:** the `cd` into the checkout triggering the user's prompt (F3)

## Primitive sweep

Primitive: git invocation that reads agent-writable repo state (can run config-named commands: drivers, filters, fsmonitor, gpg, hooks)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `questions.md:89,118,150` `git branch --show-current` | S1, S4 | none | cleared: reads HEAD only, runs no driver |
| `:90,119,151` guard's `for-each-ref`, `rev-parse --git-path` | S1, S2 | — | cleared: no index or driver path. Proposed `git config` and `fsck` added (F1) |
| `:91` Q-162 `git merge` | S1–S4 | hooks off, no replace | F1 (filters, gpg, fsmonitor, objects), F2 (base) |
| `:91` `git merge --abort` | S1 | none (runs after a failed merge) | cleared under the proposed guard (filters and fsmonitor refused before it). Planted MERGE_HEAD listed as untested |
| `:92` `git worktree remove` / `git branch -d` loop | S1, S4 | none | cleared: no hooks. Deletion in the container is same-uid, so nothing escalates |
| `:120-121,152-153` `merge-base --is-ancestor` | S3, S4 | replace refs refused | cleared: worst case picks the other reviewed hash (commit-graph untested) |
| `:122,154` Q-163/Q-164 `git merge` | S1–S4 | hooks off, no replace | F1 (merge drivers reach roadmap/questions here), F2 |
| `:263` Q-169 host `git show` | S1, S3 | `core.useReplaceRefs=false`, sha256 | cleared for show (probes). F3 for the `cd` |
| `:391` Q-176 host `git init` in a fresh `~/q092` | — | `mkdir` refuses an existing dir | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| F1 | Guard misses drivers, filters, fsmonitor, gpg, attributes, alternates, rewritten objects; line 84 overclaims | Medium | B1, B4 | `questions.md:84,90-91,119-122,151-154` | High |
| F2 | Moved main, shell startup, concurrent writer: unclosable by a guard, unnamed in prose | Medium | B1, B2, B4 | `questions.md:84,89,118,150` | High / Medium |
| F3 | `/workspace` is the host checkout; Q-169 `cd`s a host shell into it | Medium | B3 | `questions.md:84,263,266` | High / Low–Medium |
| F4 | Paste text read from an agent-writable working tree | Informational | B1, B3 | `questions.md` (terminal entries) | Medium |

## Overall Assessment

The branch closes the prior review's F1 (grafts, with shallow added), F3 and F4 as claimed. F2's container instruction is present but misdescribes the boundary (F3 here). The new merge flags (hooks off, no replace objects) work and nothing in the edits regresses the old guard. The problems are scope and wording. The guard covers three of the roughly ten repo-state classes that change what a merge runs or lands. And the sentence on line 84 promises fixed content, which a same-uid agent can defeat more cheaply by moving main (F2), something no guard written in a paste can see. All four are fixable in place, as text in `questions.md`:
1. Swap in the proposed guard. It was executed against 21 planted states in bash and zsh, in a linked worktree, and on the real `/workspace`, in about 5 s.
2. Add `core.commitGraph=false` to the merge.
3. Rewrite line 84 to name the residuals: the base is unchecked, run with no agent working, glance at the first-parent log.
4. Drop the `cd` from Q-169.

The single most important change is (3). Without it, the user reads the paste as an integrity guarantee it cannot give. There are no findings within the code paths read beyond those above. Endorsement claims are scoped as stated, and those marked for routing are pending code-fact-check verdicts.

## Goal-Alignment Note

- Success criterion (restated verbatim): "a markdown report at the output path you were given, structured per your skill."
- Answered: yes. Saved at `docs/reviews/security-review-2026-10-15-q180.md`, first line `Commit: 46342d66`.
- User goal served: whether the user can safely run Q-162, Q-164 and Q-163. Yes, after the four text edits above. Running them as they stand is no less safe than main's versions, but the prose overstates what they guarantee.
- Out of scope, noted: Q-156's host release crosses the same B3 boundary (F3); a trusted rendering of terminal pastes (F4).
- Probes: every probe ran under `timeout` in the scratch dir; no process left running; nothing written in `/workspace` or any worktree except this report.
