Commit: c86b8f3e

# Security Review: chore/dev-cycle-2026-10-15-0357, review-fix iteration 2

**Scope:** `git diff 16136a60..c86b8f3e` (the iteration-1 fix commit). The fix changes `docs/working/questions.md`, `docs/roadmap.md` and `docs/working/questions-archive.md`, and adds the iteration-1 review reports and two override-log rows. The rest of the branch is context only.
**Date:** 2026-10-15
**Based on:** `docs/reviews/security-review-2026-10-15-0357.md` (iteration 1, F1–F8) and `docs/reviews/code-fact-check-report-2026-10-15-0357.md` (iteration 1).

> ⚠️ **No iteration-2 code fact-check report was provided.** The claims the fix adds (pinned hashes, the extraction hash, the gate regex citation) were checked here by execution where noted. Other prose claims are not independently verified.

No HALT escalation. None of the five escalation patterns matches. A grep of the fix's added lines for credential shapes found only the review reports quoting their own grep.

## Verification of iteration-1 findings

| # | Iteration-1 finding | Status | How established |
|---|---|---|---|
| F1 | Merge pastes bind to movable branch names; Q-162 has no abort | **Resolved as written; new residual N1** | Executed: `a760a5e5…`, `a04d9776…` and `0f94bb77…` equal today's tips of `merge/ready-2026-10-15`, `merge/u5-and-q145` and `merge/build-loop-u5-resolved`. The ancestry each arm assumes holds: `a04d9776` contains both 7c91b974 and c035f2e7, `0f94bb77` contains 7c91b974 but not c035f2e7, and `a760a5e5` contains neither. Read: Q-162's `{ merge \|\| { abort; echo; false; }; } && for …` skips the cleanup loop on any merge failure. A hash pin is still subvertible by a replace ref (N1). |
| F2 | Always-allow hook | **Resolved** | Executed: the hook script was run under dash against 21 command strings plus malformed input (see Endorsement Claims). It approves only the seven listed strings, and those strings with trailing newlines appended. Residuals are in the paste's error path (N3) and in how results are read (N2). |
| F3 | Quoted prefix/exact spellings missing; Q-177 [1] `—` | **Resolved** | Read: `git "push"` is tested against `Bash(git push:*)` (prefix) and `cat "secret"` against `Bash(cat secret)` (exact), with unquoted controls 1 and 5 and "If a control is not denied, the check is void". Q-177 [1]'s cell now names the consequence. |
| F4 | Host version stands in for container's | **Resolved** | Read: both version lines are pasted back, and "all denied" lands Q-092 only when the versions match. |
| F5 | Q-169 self-reported hash, agent-writable source | **Resolved in mechanism; new residual N4** | Executed: the paste's `git show a760a5e5…: \| awk …` reproduces 496 lines with sha256 `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7`, matching the entry. The doc at a760a5e5 is byte-identical to the reviewed spike tip d25254da (`git diff --quiet`). The command runs from `/workspace`, which exists only inside the container (N4). |
| F6 | Q-175 hides the coverage loss | **Resolved** | Executed: `main:hooks/live-verify-gate.sh:83` is `enforcement='^devcontainer-config/(…\|link-claude-home\.sh\|…)'`, as the new text says. The interim is reworded and points at [2]. |
| F7 | Q-166 [1] understates the gap for Q-125 | **Resolved** | Read: `questions.md:191` now names the unexercised `PAYLOAD` and `enforcement_files()` changes. |
| F8 | Q-167 (c) `#` lines inside the fence | **Resolved** | Read: step 2 is prose outside the fence, and its command is in its own block (`questions.md:231`). That block starts with `!`. If it were pasted on the host by mistake, it writes only under a relative `mirror-repo/hooks/`, which exists only in the probe repo. |

## Trust Boundary Map

```
B1:       [agent-written doc text (questions.md)]          → [user copy-paste]                  → [host or container shell, user uid]
B2 (moved): [hash-pinned merge targets in the pastes]       → [`git merge <hash>` object lookup] → [main → install.sh → host tools / image]
B3:       [model-chosen Bash command string, Q-176 session] → [allow-tests.sh `case` + deny rules] → [host Bash execution]
B4 (new): [extracted spike block + expected sha256]         → [`sha256sum` run by the user]       → [host shell executing the ~500-line block]
B5:       [Q-176 results as the user records them]          → [Q-177 landing rule]               → [Q-092 lands; the hook's deny backstop is removed]
```

Input-source classification:

```
S1: questions.md text in /workspace (pastes, expected hashes)    — runtime-mutable (any agent with repo write) — UNTRUSTED toward exec;
                                                                    trusted only as far as the user reads it from committed main
S2: object lookups in /workspace/.git: refs/replace/*, repo config — runtime-mutable (same writers; .git is the bind-mounted host .git)
                                                                    — UNTRUSTED toward merge-into-main and toward `git show` content
S3: full commit hashes and the full sha256 in the entries        — code-constant once read from a reviewed commit — trusted as identifiers;
                                                                    the content behind a commit hash is not trusted while S2 can substitute it
S4: Bash command strings the model issues in Q-176               — request-time (model output) — UNTRUSTED toward exec; the hook matches them byte for byte
S5: host and container Claude Code versions                      — deploy-time — trusted as facts
S6: the user's current directory when pasting Q-176              — request-time (user state) — trusted, but the paste's later commands depend on an earlier `cd` (N3)
```

Prose summary. The fix moves the binding from names (S2 branch refs) to hashes (S3). Git still resolves a hash through agent-writable replace refs (S2), so a hash pin alone does not bind content for a merge. Q-169's sha256 check does bind content, but only where it runs. The Q-176 hook is now a strict exact-match allowlist. Its remaining exposure is in the paste's error path and in whether a recorded "denied" came from the tested string.

## Findings

#### N1. A replace ref turns a hash-pinned merge into a merge of other content, with the reviewed hash recorded as the parent

**Severity:** Medium
**Location:** `docs/working/questions.md:87` (Q-162), `:114-115` (Q-163), `:144-145` (Q-164); rationale at `:83` ("a branch name can move, a hash cannot")
**Boundary:** B2 (S2 → S3)
**Move:** 1 (trust per sink), 11 (bypass of the new guard), 12 (sweep of every hash-pinned merge)
**Confidence:** High (mechanism, executed); Low–Medium (likelihood: needs a deliberate `git replace`, not a buggy dispatch)
**Legibility-target:** for-author

Evidence:
```
{ git merge --no-ff a760a5e5057ef3f0abd13145e7d945ef500b8abd -m "Merge branch 'merge/ready-2026-10-15': ..." || { git merge --abort; echo "conflict: merge aborted, nothing deleted"; false; }; } && \
if git merge-base --is-ancestor 7c91b97455db9fba1b155a2bb866abf6b86f1904 HEAD; then B=a04d97762518389f053c3c609a3dfcc4531d553b; else B=c035f2e77f8c083156b397fb32e164dd17cc6b44; fi && \
It merges `merge/ready-2026-10-15` by its reviewed tip, a760a5e5 (a branch name can move, a hash cannot)
```

Git honours `refs/replace/<hash>` on every object read unless replacement is disabled. I ran this in a throwaway repo under the scratchpad. I committed "reviewed" as R and "EVIL" as E, ran `git replace R E`, then ran `git merge --no-ff R` on main. The result was `main f now: EVIL`, with the merge commit's parents shown as `8268b45 119f636`, where 119f636 is R. `git rev-parse R` still printed R.

So the merge lands E's tree while history and the commit message name the reviewed hash. A later `git log` or `git merge-base --is-ancestor` check shows nothing wrong. Whoever can move the refs that F1 worried about (any agent session with write to `/workspace/.git`) can also create a replace ref. Unlike a branch move, a replace ref cannot be created by accident, so the likelihood is lower than F1's. The impact is the same: unreviewed content in main, and from there in `install.sh`'s payload. The project already treats this as real. `scripts/build-loop.sh:626-627` refuses to run when any `refs/replace/` ref exists, `skills/dev-cycle/SKILL.md:68` passes `GIT_NO_REPLACE_OBJECTS=1 … -c core.useReplaceRefs=false` to every git read, and Q-164 (`:139`) defers install.sh's own replace-ref exposure. The three new pastes have neither guard.

**Recommendation:** start each paste with the build-loop's refusal, `test -z "$(git for-each-ref refs/replace/)" || { echo "replace refs present: stop"; false; } && \`. Alternatively run the merge as `GIT_NO_REPLACE_OBJECTS=1 git -c core.useReplaceRefs=false merge …`. Drop or qualify "a hash cannot [move]".

#### N2. Q-176 can record "denied" for a command the hook never saw, and its landing rule does not cover "prompts"

**Severity:** Medium
**Location:** `docs/working/questions.md:398-410` (Q-176); `:421` (Q-177 [1])
**Boundary:** B5, B3 (S4)
**Move:** 3 (error path), 11 (bypass of the result-reading guard)
**Confidence:** Medium (mechanism, executed against the hook script); Low–Medium (whether the model rewrites the string)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
Then ask Claude to run each of these one at a time, exactly as written, and note for each whether it **runs**, **prompts** or is **denied**:
7. `git "push"`
- **If the answer differs:** any "runs" sends Q-177 to its options; all "denied" with matching versions lands Q-092; different versions mean the check is re-run at the container's version.
```

The hook approves only the exact strings, and any other spelling leaves it silent. I ran the hook on `git push` (silent), `cat secret ` with a trailing space (silent) and `' cat secret'` (silent). If the model normalises test 7 to `git push` or test 6 to `cat secret`, the hook stays silent and the unquoted deny rule matches. The user then records "denied" for a spelling that was never tested against a hook `allow`, and Q-177 [1] lands Q-092 on that record. That is the false all-clear the controls do not catch, because the controls only show that a deny rule beats a hook `allow` for unquoted strings. The opposite drift, where the model prefixes `cd ~/q092 && …`, leaves the hook silent too. The user sees "prompts", answers no as instructed, and the landing rule has no case for "prompts".

**Recommendation:** have the hook log what it saw, for example `printf '%s\n' "$c" >> "$HOME/q092/seen.log"` before the `case`, and have the user paste back `seen.log` with the results. Then a result counts only if its exact string appears in the log. Add to the landing rule that a "prompts" on tests 2–4, 6 or 7 voids that test, and the test is re-asked.

#### N3. If `mkdir`/`cd` fails, Q-176's paste overwrites the current directory's `.claude/settings.local.json` and launches `claude` there

**Severity:** Medium (floor rule: concrete mechanism; rarity goes to Confidence)
**Location:** `docs/working/questions.md:381-395` (Q-176)
**Boundary:** B1 (S6)
**Move:** 3 (error path), 4 (the `cd` checked once, used by later commands)
**Confidence:** Low (needs `~/q092` to be a non-directory or unwritable, or a failing `echo` under `noclobber` on a re-run)
**Legibility-target:** for-author

Evidence:
```
mkdir -p ~/q092/.claude && cd ~/q092 && echo canary > x.q092-canary && echo secret > secret && cat > .claude/allow-tests.sh <<'EOF'
...
EOF
cat > .claude/settings.local.json <<'EOF'
...
claude --version && claude
```

Only the first heredoc is chained to `cd ~/q092`. The second `cat > .claude/settings.local.json` and `claude` are separate commands. I simulated this under `zsh -f` with neutral file names (the harness forbids writing `.claude/settings*` paths). With `~/q092` existing as a file, `mkdir` fails, the shell stays in the pasting directory, and that directory's `cfg/local.json` went from `ORIGINAL` to `OVERWRITTEN`. The "launch" line then ran in that directory. In the real paste, the overwritten file is whatever project the user pasted from, plausibly the host checkout. It loses its local allow/deny rules, which is the weakened-enforcement direction. `claude` then starts there with a hook path that does not exist (a silent hook) and test-only deny rules.

**Recommendation:** use absolute paths for every write (`> ~/q092/.claude/settings.local.json`), and chain the whole block with `&&`, or wrap it as `( set -e; … )` before `claude`.

#### N4. Q-169's hash check names the container path for a host-run paste

**Severity:** Medium
**Location:** `docs/working/questions.md:251-257` (Q-169)
**Boundary:** B4 (S1, S2)
**Move:** 1 (where the check runs is a boundary), 4 (TOCTOU between check and paste)
**Confidence:** Medium that the instruction misroutes; Low that a container agent can subvert the user's container shell
**Legibility-target:** for-author

Evidence:
```
  cd /workspace && git show a760a5e5057ef3f0abd13145e7d945ef500b8abd:docs/working/spike-cc-verify-q117.md | awk '/^```bash$/{f=1;next} f&&/^```$/{exit} f' > ~/q117-spike.txt && sha256sum ~/q117-spike.txt
  The hash must be `032cc9a8…ccfed4afb7`; otherwise stop. Then paste the file's contents, editing only its last line, the checkout path.
```

The spike block runs on the host, and its last line defaults to `~/claude-workflows`. `/workspace` is the container's bind-mount target (`devcontainer-config/devcontainer.json:134`, `target=/workspace`). On the host, the `cd` most likely fails, which fails closed but stalls the check. The working fallback is to run the line inside the container. The check then runs in the shell environment shared with the agents that Q-169 names as the threat, and its file lands in the container's `~`, which the user must then carry to the host by copy. A check run where the attacker lives does not certify what the host executes. Separately, `~/q117-spike.txt` is not under `~/cc-verify`, the one path Q-169 asks to be `denyWrite`'d, so a same-uid host writer has the window between `sha256sum` and the copy.

Running the extraction on the host is sound: `git show <hash>:` honours replace refs (N1), and the full sha256 catches that. I reproduced the hash.

**Recommendation:** run the extraction on the host in the host checkout, for example `cd ~/claude-workflows && GIT_NO_REPLACE_OBJECTS=1 git show …`, and write the file under `~/cc-verify/`. Then run it straight from the checked file, so nothing is re-copied between check and run.

#### N5. Q-176's `git "push"` payload is not inert in the outcome it tests for

**Severity:** Low
**Location:** `docs/working/questions.md:381`, `:405`
**Boundary:** B3 (S4)
**Move:** 3 (the failure case's side effect)
**Confidence:** Low (needs `~` or a parent of `~/q092` to be a git work tree with a push destination)
**Legibility-target:** for-author

Evidence:
```
mkdir -p ~/q092/.claude && cd ~/q092 && echo canary > x.q092-canary && echo secret > secret && cat > .claude/allow-tests.sh <<'EOF'
7. `git "push"`
```

The check exists to find out whether test 7 runs. If it does, `git push` runs in `~/q092`. That directory is not a repository, so git searches upward. If `~` is a dotfiles work tree with an upstream, the session pushes it. The other payloads are inert (a canary file, a non-existent path). Rated Low because the only destination is the user's own configured remote.

**Recommendation:** add `git init -q` to the chain in `~/q092` (with no remote, a push fails with "No configured push destination"), or set `GIT_CEILING_DIRECTORIES` for the session.

### Untested bypass candidates

- N1 for `git merge-base --is-ancestor` in Q-163/Q-164's arm selection. A replace ref can rewrite a commit's parents and so flip which arm is chosen. Not executed: both arms are pinned reviewed hashes, so the impact is bounded by N1 itself.
- Repository-scope config in `/workspace/.git/config` (`core.hooksPath`, a `merge.<driver>.driver`, `core.attributesFile`) running code during the user's `git merge`. The pastes do not harden against it, and `skills/dev-cycle/SKILL.md:68` does. Not tested. This predates the fix and was not raised in iteration 1, so it is listed here, not filed as a new finding on this diff.
- Pruning of a now-unreachable pinned commit after the loop force-rebuilds a merge branch. Traced: `git merge <missing>` fails into the abort arm, and `git show` produces an empty file whose hash mismatches. Both fail closed. Not executed.
- Q-176 under a host without `jq`. Executed with `PATH=/nonexistent`: the hook prints nothing and exits 0, so it fails toward prompting, never toward `allow`. Listed because the user's host `jq` was not checked, and a missing `jq` makes every test read "prompts" or "denied", which lands in N2's ambiguity.

## Endorsement Claims

- **Claim:** the Q-176 hook script approves exactly the seven listed strings. Of the probe inputs, the only others it approves are those strings with trailing newlines, because `$(…)` strips them. Leading or trailing spaces, `\r`, tabs, glob characters (`*`, `?`, `[s]`), case changes, a compound suffix (`; rm -rf ~`), a newline-joined second command, a doubled backslash, a JSON array `command`, malformed JSON and a missing `jq` all leave it silent with exit 0.
  **Location:** `docs/working/questions.md:381-388`
  **Evidence:** executed
  **Verified:** the script, copied byte for byte into the scratchpad and run with `/bin/sh` (dash) and `/usr/bin/jq` against 21 JSON payloads plus 3 malformed ones.
  **Not verified:** Claude Code's own hook invocation on the user's host (its `/bin/sh` and `jq` version), and how the host Claude Code orders a hook `allow` against a deny rule. The latter is what the check measures.
  **route: code-fact-check**
- **Claim:** the three pinned merge hashes equal today's branch tips, and the ancestor tests in Q-163/Q-164 pick a target that contains the unit being merged.
  **Location:** `docs/working/questions.md:87`, `:114`, `:144`
  **Evidence:** executed
  **Verified:** `git rev-parse` on the three refs, and `git merge-base --is-ancestor` for 7c91b974 and c035f2e7 against each hash.
  **Not verified:** that `/workspace/.git` has no `refs/replace/` entry at paste time (N1). `git for-each-ref refs/replace` was empty in this worktree's shared store today.
  **route: code-fact-check**
- **Claim:** Q-169's extraction command reproduces the published full sha256, and the doc at a760a5e5 equals the reviewed spike tip d25254da.
  **Location:** `docs/working/questions.md:254-257`
  **Evidence:** executed
  **Verified:** the paste's `git show … | awk …` (output redirected to the scratchpad) gave `032cc9a8…ccfed4afb7` over 496 lines, and `git diff --quiet d25254da a760a5e5 -- docs/working/spike-cc-verify-q117.md` succeeded.
  **Not verified:** the same command on the host checkout (N4).
- **Claim:** Q-162's grouping stops the branch-deletion loop whenever the merge exits non-zero.
  **Location:** `docs/working/questions.md:86-88`
  **Evidence:** read-static
  **Verified:** the `{ A || { abort; echo; false; }; } && for …` structure.
  **Not verified:** a merge that succeeds but leaves the checkout dirty because a merge hook writes files. Hooks are config-controlled; see the untested candidates.

## Primitive sweep

Primitive: host or container shell execution of agent-authored paste text, plus object lookups by hash (an exec or merge sink fed by S1/S2). These are all paste blocks the fix adds or changes.

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `questions.md:86-88` Q-162 merge + cleanup | S1, S2, S3 | branch = main; hash pin; abort + `false` | N1 (replace ref); otherwise F1 resolved |
| `questions.md:113-115` Q-163 merge | S1, S2, S3 | branch = main; hash pins in both arms; abort | N1 |
| `questions.md:143-145` Q-164 merge | S1, S2, S3 | branch = main; hash pins in both arms; abort | N1 |
| `questions.md:224-226` Q-167 (c) step 1 | S1 | `mktemp` `&&` chain | cleared, unchanged since iteration 1 |
| `questions.md:230-232` Q-167 (c) step 2 | S1 | relative path that exists only in the probe repo | cleared (F8 resolved) |
| `questions.md:254` Q-169 extraction | S1, S2, S3 | full sha256 | N4 (where it runs); replace refs are caught by the hash |
| spike block via Q-169 | S1 | full sha256 + self-hash line | cleared for content binding; internal logic out of scope |
| `questions.md:381-395` Q-176 setup + launch | S1, S6 | first line `&&`-chained only | N3, N5 |
| `questions.md:383-388` Q-176 hook `case` | S4 | exact byte match | cleared (executed); result reading in N2 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| N1 | A replace ref subverts the hash-pinned merges and records the reviewed hash as the parent | Medium | B2 | `docs/working/questions.md:87,114-115,144-145` | High (mechanism) |
| N2 | Q-176 can record "denied" for an untested spelling; "prompts" is not in the landing rule | Medium | B5, B3 | `docs/working/questions.md:398-410,421` | Medium |
| N4 | Q-169's hash check names the container path for a host-run paste | Medium | B4 | `docs/working/questions.md:251-257` | Medium |
| N3 | Q-176's paste overwrites the current directory's local settings if `mkdir`/`cd` fails | Medium | B1 | `docs/working/questions.md:381-395` | Low |
| N5 | Q-176's `git "push"` payload is not inert if it runs | Low | B3 | `docs/working/questions.md:381,405` | Low |

## Overall Assessment

All eight iteration-1 findings are fixed. For F2 and F3, the fix is strong: the hook is now an exact-match allowlist that fails closed, as executed against 24 inputs, and it has controls. The fix introduces no Critical or High issue, and the branch still changes only docs. The new findings are text fixes inside the same entries. None needs an architectural change. The most important one is N1. The fix's own rationale, "a hash cannot [move]", does not hold while replace refs are honoured, and the project's build loop already refuses them, so the pastes should do the same with a one-line guard. N2 matters next, because a false "all denied" removes an enforcement backstop. N3–N5 are cheap hardening of the Q-176 and Q-169 pastes. There are no findings within the code paths read beyond those listed. The endorsement claims are executed where marked, and the routed ones are pending code-fact-check intake.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/security-review-2026-10-15-0357-i2.md (first line `Commit: c86b8f3e`), structured per the security-reviewer skill."
- **Answered:**
  - Each fix resolves its iteration-1 finding (table above).
  - **The Q-176 `case`:** a command that differs from the listed string cannot match, except by trailing newlines (harmless), and nothing else is approved (executed). The `jq` dependency fails closed toward prompting. The hook script in `~/q092` adds no new capability for a same-uid writer, who could already edit `~/.claude/settings.json`. Its new risks are the unchained writes (N3) and the result reading (N2).
  - **Q-162's grouping on failure:** correct. The loop is skipped.
  - **Q-169's extraction:** it reproduces the full hash, and a760a5e5's doc equals the reviewed d25254da. a760a5e5 is reachable only through the agent-movable `merge/ready-2026-10-15` ref. For a hash-pinned `git show` that matters only through replace refs and pruning, and the full sha256 catches both. The real gap is where the check runs (N4).
  - **Hash pins against "the loop rebuilds their merge branches":** a rebuild leaves the entry's pin on the old reviewed commit. The paste then merges reviewed-but-stale content, or aborts on a conflict, until the entry is updated with the new hash. That is fail-safe and forces a re-binding to review. If the old commit is pruned, the merge fails into the abort arm. The pins are still bypassable by replace refs (N1).
- **Out of scope:** the spike block's internal logic, and the Q-092, Q-106 and Q-125 branches themselves. Repository-scope git config hardening of the pastes predates this fix and is listed under untested candidates, not filed. No paste was run against `/workspace` or the host's claude, cc-isolated or install.sh. Experiments ran only in fresh repos and files under `/tmp/claude-1000/-workspace/b1fde0b4-befb-4424-9add-ef12273f2f26/scratchpad/i2sec/`, each under `timeout`. All have exited, and no ref was moved in the real repository.
- **Escalate:** none at the HALT level. N1 and N2 should be fixed before the user runs Q-162/Q-163/Q-164 and Q-176. Each is a line or two of paste text.
