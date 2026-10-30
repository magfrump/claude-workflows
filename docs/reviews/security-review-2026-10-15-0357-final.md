Commit: 2141f7ee

# Security Review — chore/dev-cycle-2026-10-15-0357 (final confirming pass)

**Scope:** full branch, `git diff main...2141f7ee` (docs only; the security surface is the shell blocks the user runs with their own privileges, plus trust framing)
**Date:** 2026-10-15
**Based on:** `code-fact-check-report-2026-10-15-0357-final-r{1,2,3}.md` (k=3, merged); earlier passes `security-review-2026-10-15-0357.md` (F1–F8) and `-i2.md` (N1–N5) as context only
**Experiments:** throwaway repos and a fake HOME under the session scratchpad (`final-sec/`), git 2.39.5, each under `timeout`; no paste was run against `/workspace` or the host's tools

## Trust Boundary Map

```
B1: [agent-writable .git state in the checkout: refs/replace, info/grafts, shallow, hooks, config] → [the pastes' pre-merge guard]       → [`git merge --no-ff <pinned sha>` → main]
B2: [Q-162/163/164 paste text, written by an agent session]                                       → [the user's reading + pasting]         → [the user's shell (container or host)]
B3: [Q-167 probe lines]                                                                             → [the host's *installed* cc-isolated]   → [blessed manifest = the trust anchor]
B4: [~/q092, pre-existing contents (same-uid writer)]                                               → [Q-176 setup: mkdir -p, git init]      → [host Claude Code session: settings, git status]
B5: [Q-176 tool_input.command from the model]                                                       → [throwaway hook `case` exact match]    → [permission decision vs. deny rules]
B6: [spike doc at a pinned commit in the host checkout]                                             → [`git show` | awk | sha256sum, eye-compare] → [block pasted into the host shell]
B7: [entry prose: Q-166, Q-174, Q-175, Q-177 options/consequences]                                  → [user's judgment]                      → [merge / gate decisions]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | Paste text in `docs/working/questions.md` | runtime-mutable (any agent session edits it) | UNTRUSTED toward exec (the user's shell); trusted only as far as a reviewed commit pins it |
| S2 | `.git` state of the checkout (refs, grafts, shallow, hooks, config) | runtime-mutable (the container writes it through the bind mount; `/workspace/.git/info` is `node`-owned here) | UNTRUSTED toward merge content and toward exec |
| S3 | Pinned full commit hashes (a760a5e5…, a04d9776…, 0f94bb77…, c035f2e7…, 7c91b974…) | code-constant once the object exists | trusted for object identity; NOT for parent links (S2 grafts rewrite them) |
| S4 | The host's installed `cc-isolated` (whatever version install.sh last put there) | deploy-time | trusted for exec; its *behavior on a given argv* depends on the version (pre/post f6f37fad) |
| S5 | `~/q092` before the paste | runtime-mutable (any same-uid writer) | UNTRUSTED toward Claude Code settings and git config sinks |
| S6 | `tool_input.command` the hook reads | request-time (model-authored) | UNTRUSTED (all sinks); the hook only string-matches it |
| S7 | `~/cc-verify/q117-spike.txt` between hash check and paste | runtime-mutable (same-uid writer unless `denyWrite`) | UNTRUSTED toward exec; the entry's `denyWrite` advice covers it |

What enters from outside: paste text written by agents (S1) and repository state that agent sessions can write (S2, S5). The diff's pastes assume that pinning a full hash plus refusing `refs/replace/` fixes merge content; that assumption holds for object content but not for history shape, which `info/grafts` still controls (Finding 1).

## Findings

#### Finding 1 — The pastes' replace-ref guard misses `info/grafts`, which makes a hash-pinned merge silently revert main's content

**Severity:** Medium
**Location:** `docs/working/questions.md:89` (Q-162), `:117` (Q-163), `:148` (Q-164); claim at `:83`
**Boundary:** B1
**Move:** #11 (bypass enumeration), #1
**Confidence:** High (executed)
**Legibility-target:** for-author
**Evidence (verbatim):** guard `{ test -z "$(git for-each-ref refs/replace/)" || { echo "replace refs present: stop"; false; }; }`; claim "(a branch name can move; a hash cannot, once the paste has checked that no replace refs exist)".

In a throwaway repo (`final-sec/graft-probe.sh`), main carried a commit adding `fix.txt`; a feature commit F was pinned. Writing `"$F $(git rev-parse HEAD)"` to `.git/info/grafts` (making main's tip F's parent) left the guard passing (`guard: passes`), and `git merge --no-ff "$F"` exited 0 with no conflict and a merge commit whose diff from `HEAD^1` is `fix.txt | 1 -`: main's change was deleted. The merge commit records the real parents, so the deletion persists after the graft file is emptied. An agent session that can write `/workspace/.git` (it commits there) can therefore make the user's reviewed-hash merge drop a security fix from main, which install.sh later carries to the host. Q-162 would then also run its deletion loop, since the merge "succeeded". The repo's own prior art already pairs the two: the D6 snippet refuses both (`skills/dev-cycle/SKILL.md:234-235`, `[[ ! -e "$x" && ! -L "$x" ]] || no "info/grafts exists (F38)"`), and `scripts/build-loop.sh:622` checks `info/grafts`, `shallow` and `objects/info/alternates`. The exit scan's snapshot list (`cc-exit-scan.sh:51-55`) does not include grafts, so the tripwire won't catch it either. Q-162 is marked not runnable, but Q-163 and Q-164 are live `you: judgment` entries with this paste.

**Recommendation:** Extend the guard in all three pastes to refuse a present `info/grafts` (via `git rev-parse --git-path info/grafts`, as the D6 snippet does), and ideally `shallow`. Reword `:83` so it doesn't claim the replace-ref check alone fixes what is merged.

#### Finding 2 — The merge pastes don't say whether to run in the container or on the host; on the host they run planted hooks and merge drivers

**Severity:** Medium
**Location:** `docs/working/questions.md:83, 88, 116, 147`
**Boundary:** B2, B1
**Move:** #1, #12
**Confidence:** Low (it depends on where `/workspace` exists)
**Legibility-target:** for-author
**Evidence (verbatim):** "Paste the block from `/workspace` with `main` checked out." / `cd /workspace && test "$(git branch --show-current)" = main && \`

`git merge`, `git worktree remove` and `git branch -d` run in the checkout. The repo's own threat model says that doing this on the host "runs whatever hooks, core.fsmonitor, filter drivers … the session planted — as you, with your keys" and that "a clean scan is not permission to run git in the checkout" (`devcontainer-config/cc-exit-scan.sh:33-44`). A planted `post-merge` hook or a `merge.<x>.driver` in `.git/config` runs when these pastes run. If `/workspace` exists only in the container (the i2 review's N4, and Q-169 names the host checkout `~/claude-workflows`), the hook runs inside the agent's own sandbox, and on the host `cd` fails and the chain stops. Both outcomes are safe. The text never says which location is meant, and fact-check r1 recorded this as Unverifiable. If the user's host checkout is at `/workspace`, this is host code execution.

**Recommendation:** Say "run inside a cc-isolated session (`!` prefix) or the container's shell, never in the host checkout", or prefix the git calls with `-c core.hooksPath=/dev/null` and state that merge drivers remain a risk.

#### Finding 3 — Q-167(b)'s third probe line performs an unprompted bless on a pre-fix launcher

**Severity:** Low
**Location:** `docs/working/questions.md:206, 221`
**Boundary:** B3
**Move:** #3 (error path), #11
**Confidence:** Medium
**Legibility-target:** for-author
**Evidence (verbatim):** `cc-isolated --profile '#' --bless; echo "exit=$?"`; and at `:101`: "Before this, `cc-isolated  # --bless` and `--profile '#' --bless` ran a bless."

On main's launcher (the version installed until Q-162 lands; f6f37fad isn't on main), `--profile` takes `'#'` as its value and `--bless` sets `action="bless"`, which reaches `bless_manifest; exit 0` (`devcontainer-config/cc-isolated.sh:734-745, 788`). `bless_manifest` (`:281-319`) prints the diff and then renames the new manifests into place without any prompt. The only safeguard is the prose ordering ("After Q-162's paste lands, run install.sh … then run the two probes"). Q-167 sits in the index as an open `you: terminal` entry while Q-162 is marked not runnable, so running it out of order is plausible. In that case, any change a same-uid writer made to the installed config since the last bless gets blessed by a line the user meant as a refusal test. Without tampering it is a no-op re-bless. Exploiting it needs a host-side writer, so it sits under the floor rule's reachable-environment bar.

**Recommendation:** Use `cc-isolated --profile '#' --list; echo "exit=$?"`. The fixed launcher refuses it in the same parse branch (`f6f37fad:cc-isolated.sh:795-796`, exit 2), and the old one turns it into a harmless list.

#### Finding 4 — Q-176's setup accepts a pre-existing `~/q092`, keeping planted git config and Claude Code settings

**Severity:** Low
**Location:** `docs/working/questions.md:386`
**Boundary:** B4
**Move:** #4 (TOCTOU), #1
**Confidence:** Medium (executed for git; whether Claude Code's startup `git status` triggers it was not run)
**Legibility-target:** for-author
**Evidence (verbatim):** `mkdir -p ~/q092/.claude && cd ~/q092 && git init -q && jq --version && echo canary > x.q092-canary && echo secret > secret && cat > ~/q092/.claude/allow-tests.sh <<'EOF' && …`

Executed (`final-sec/q092-preexist-probe.sh`, fake HOME): with `~/q092` already holding a repo whose `.git/config` sets `core.fsmonitor`, and a `.claude/settings.json` with `"allow":["Bash(*)"]`, the paste's `mkdir -p … && git init -q` succeeded. The planted fsmonitor survived and ran on `git status` ("planted fsmonitor RAN on git status"), and `settings.json` was still there, because the paste overwrites only `settings.local.json`. A planted symlink at `x.q092-canary` or `secret` would also redirect the `echo … >` writes. The writer needs to be same-uid. That is the threat Q-169 itself names for `~/cc-verify` ("A same-uid writer there is the one threat left open"), so the two entries are inconsistent.

**Recommendation:** Start with `mkdir ~/q092 && mkdir ~/q092/.claude` (no `-p`) so that a pre-existing directory stops the paste, or `test ! -e ~/q092 ||` stop.

## Untested bypass candidates

| Candidate | Guard | Why not tested |
|---|---|---|
| A replace ref created between the guard's `for-each-ref` and `git merge` (race) | pastes' replace-ref guard (B1) | It needs a concurrent same-uid writer timed to a window of a few milliseconds. Not run because it is a timing race. The fix in Finding 1 doesn't close it either; only a merge with `GIT_NO_REPLACE_OBJECTS=1` would |
| `.git/shallow` listing a pinned commit or a main commit | pastes' guard (B1) | Reasoned only: a parentless pin most likely gives "refusing to merge unrelated histories", so the merge aborts (fail-closed). A shallow entry deeper in main's history could move the merge base, as grafts do. Not executed |
| `GIT_REPLACE_REF_BASE` / `GIT_GRAFT_FILE` in the user's environment | pastes' guard (B1) | Partly run: `GIT_REPLACE_REF_BASE=refs/other/` hides a replacement from the `refs/replace/` listing (guard passed). It needs control of the user's shell environment, which an agent doesn't have. Not a reachable route |
| Planted `post-merge` / `reference-transaction` hook, `merge.*.driver` during the pastes | pastes (B2) | Filed as Finding 2. Whether it matters depends on where the paste runs, which isn't stated |

## Endorsement Claims

- **Claim:** Q-169's extraction, run at the pinned commit, reproduces the stated full sha256, and a missing pin fails into a hash mismatch rather than into an unchecked paste.
  **Location:** `docs/working/questions.md:259-262`
  **Evidence:** executed
  **Verified:** the paste's `git -c core.useReplaceRefs=false show a760a5e5…:docs/working/spike-cc-verify-q117.md | awk …` in this worktree's repo: 496 lines, `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`, matching the entry. With an absent commit the pipeline exits 0 (awk's status) and writes an empty file hashing `e3b0c442…b855`, which doesn't match, so the "otherwise stop" check covers it. This also covers r1's risk note that the pin becomes reflog-only after a rebuild.
  **Not verified:** the host checkout `~/claude-workflows` holding the same objects as this container's repo, and the user's eye comparison of 64 hex characters.
  **route: code-fact-check**

- **Claim:** In the extraction, `git show <sha>:<path>` piped to awk ran none of the planted repo-config commands tried.
  **Location:** `docs/working/questions.md:259`
  **Evidence:** executed
  **Verified:** `final-sec/show-probe.sh` planted `log.showSignature`+`gpg.program`, `core.fsmonitor`, `core.pager`, `pager.show`, a `diff.*.textconv` via `info/attributes`, and `post-checkout`/`post-merge`/`reference-transaction` hooks. The block was extracted and no marker was written.
  **Not verified:** other exec-capable keys (`include.path` targets that set further keys, `core.sshCommand` is irrelevant without a fetch). Also git versions other than 2.39.5 on the host.

- **Claim:** Q-176's hook approves exactly the nine listed commands among the 14 strings tried, and stays silent for compound, spaced, extended and malformed inputs.
  **Location:** `docs/working/questions.md:387-394`
  **Evidence:** executed
  **Verified:** the script extracted from the entry, run under `sh` with a fake HOME: 9/9 listed strings ALLOW. `cat secret; id`, `cat  secret`, `git push origin`, `rm -rf ./nothing-here /`, `cat x.q092-canary | sh`, an array-valued command and non-JSON all got no output. Residuals: `"cat secret\n\n"` and `"cat se\u0000cret"` are approved, because `$(…)` strips trailing newlines and `sh` drops the NUL, and `seen.log` records the stripped form. So the log can't tell those spellings apart from the exact command.
  **Not verified:** what Claude Code does with a NUL-bearing command (Node's spawn is expected to reject it), and how the user's global hooks, if any are wired on the host, interact with this one in the live session.
  **route: code-fact-check**

- **Claim:** The pinned-hash merges refuse an existing `refs/replace/` entry, packed or loose.
  **Location:** `docs/working/questions.md:89, 117, 148`
  **Evidence:** executed
  **Verified:** `final-sec/guard-probe.sh`: a packed replace ref makes the guard print `guard: stops`. A 40-hex branch name pointing elsewhere does not redirect `rev-parse <40-hex>` (the raw object id wins).
  **Not verified:** grafts, which bypass the guard (Finding 1), and shallow (untested above).

- **Claim:** Q-166 [1], Q-174 [2], Q-175 [1] and Q-177 [1]/[2] each state the security consequence of the option in its "If it's wrong" cell (staged run skips PAYLOAD/`enforcement_files()`; a malformed group could stop deny rules applying; the program loses commit-gate coverage it has today; a quoted credential read could run).
  **Location:** `docs/working/questions.md:196, 359, 373, 427-428`
  **Evidence:** read-static
  **Verified:** the cell text at those lines, against F6/F7 of the iteration-1 report.
  **Not verified:** whether Claude Code rejects a schema-invalid settings file whole (Q-174 [3]'s open host question).

## Primitive sweep

Primitive: process exec in the user's shell (pasted blocks) and git-in-checkout

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `questions.md:88-91` Q-162 merge + deletion loop | S1, S2, S3 | branch = main; replace-ref refusal; abort + `false` | Finding 1 (grafts), Finding 2 (location). Abort path cleared (fact-check replicates executed it) |
| `questions.md:116-119` Q-163 merge | S1, S2, S3 | same, no deletions | Finding 1, Finding 2 |
| `questions.md:147-150` Q-164 merge | S1, S2, S3 | same, no deletions | Finding 1, Finding 2 |
| `questions.md:211` Q-167(a) | S4 | none needed (`--probe-only`, `--list`) | cleared |
| `questions.md:219-222` Q-167(b) | S4 | the fixed launcher's exit-2 refusals | Finding 3 (line 221 on a pre-fix launcher) |
| `questions.md:230` Q-167(c) step 1 | S1 | `mktemp` `&&` chain; `rm -rf "$T"` after `cd "$HOME"` | cleared (with an empty `T`, `rm -rf ""` is a no-op error) |
| `questions.md:236` Q-167(c) step 2 | S1 | relative path that exists only in the probe repo | cleared (unchanged since i2) |
| `questions.md:259` Q-169 extraction | S2, S3, S7 | full sha256, `core.useReplaceRefs=false` | cleared (Endorsements 1–2); S7 window covered by the entry's `denyWrite` advice |
| spike block via Q-169 | S7 | full sha256 + self-hash first line | cleared for content binding; internal logic out of scope (reviewed on the spike branch) |
| `questions.md:386-399` Q-176 setup + launch | S1, S5 | one `&&` chain, absolute paths, `git init` with no remote | Finding 4 (pre-existing `~/q092`) |
| `questions.md:387-394` Q-176 hook | S6 | exact `case` match | cleared (Endorsement 3), with the newline/NUL residual noted |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Replace-ref guard misses `info/grafts`; a pinned merge silently reverts main's content | Medium | B1 | `docs/working/questions.md:83,89,117,148` | High |
| 2 | Merge pastes don't say container vs host; on the host, planted hooks/merge drivers run | Medium | B2, B1 | `docs/working/questions.md:83,88,116,147` | Low |
| 3 | Q-167(b) line 3 blesses unprompted on a pre-fix launcher | Low | B3 | `docs/working/questions.md:206,221` | Medium |
| 4 | Q-176 setup accepts a pre-planted `~/q092` (fsmonitor, settings.json survive) | Low | B4 | `docs/working/questions.md:386` | Medium |

## Overall Assessment

The earlier fixes hold. Pastes are pinned by hash and abort without deleting anything on conflict. Q-169 binds its content to a full sha256 and fails into a mismatch when the pin is missing. Q-176's hook approves exactly its nine commands. Every finding can be fixed in place with one or two lines of paste text, and none points to a design problem. The most important fix is Finding 1: the guard added to close N1 checks replace refs only. `info/grafts`, which the repo's own D6 snippet refuses next to replace refs, still lets agent-written repository state change what a user-approved, hash-pinned merge does to main (executed). Because Q-163 and Q-164 are live judgment entries with that paste, I'd fix it before landing, or record a qualifying author note. Findings 2–4 are cheap wording or flag changes. No findings outside those within the code paths read. Endorsement claims are scoped and marked pending execution verification where routed.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/security-review-2026-10-15-0357-final.md (first line `Commit: 2141f7ee`), structured per the security-reviewer skill."
- **Answered:** whether the shell blocks the branch adds (Q-162/163/164, Q-167, Q-169, Q-176) and the trust framing (Q-166, Q-174, Q-175, Q-177) are safe for the user to run or decide on at 2141f7ee. Four findings: two Medium (one executed), two Low.
- **Out of scope:** the spike block's internal logic (reviewed on its branch); the code in the units the pastes merge; the fact-check's non-security drifts (Q-169 "8 items" vs 12; Q-163/164 missing a "not runnable yet" note; Q-170 87 vs 88; Q-162 conflict-list wording). The abort paths those notes concern were executed safe by the replicates.
- **Escalate:** none. No HALT pattern matched.
- **Questions/Decisions:** whether to fix Finding 1 in this landing or defer it with an override row. Its fix is one guard clause per paste and mirrors existing prior art (`skills/dev-cycle/SKILL.md:234-235`).
