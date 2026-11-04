# Research: a `cc-verify --check` file for Q-125's live run

- **Goal**: one check file on main that the owner runs as `cc-verify --check FILE REPO feat/q125-cc-isolated-sandbox`, whose exit status is the verdict on Q-125's Claude Code Bash sandbox in a container built from main + that branch.
- **Problem framing**: the hard part is reaching Claude Code's *sandboxed* Bash path with no one at a prompt, in a fresh volume with no login. Considered and discarded: framing it as "write a shell probe" (a plain shell in the container is unsandboxed and proves nothing, as the branch's script says).
- **Project state**: brief `docs/working/briefs/2026-11-03-q125-verify-check.md` (dispatch 1), branch `feat/q125-verify-check` from main ed6b0be2; the Q-125 work is unmerged at 2961ca2f (cite: feat/q125-cc-isolated-sandbox).
- **Task status**: implemented; FILE, bats suite and this doc on the branch; the host run is the owner's.

FILE: `docs/working/q125-verify-check.sh`. Test: `test/q125-verify-check.bats`.

Run (host, from the claude-workflows checkout at main, once this branch is merged):

    cc-verify --check docs/working/q125-verify-check.sh . feat/q125-cc-isolated-sandbox

## What exists

- `devcontainer-config/cc-verify.sh` (main): clones REPO bare, stages `git merge-tree --write-tree main BRANCH`, builds it with main's launcher on a scratch clone `VERIFY-<tree8>` (fresh `cc-<pid>-claude-config` volume), asks `[y/N]` once, then runs FILE's text as `devcontainer exec ... bash -c "$BLOCK" </dev/null`, piping output through `relay` (indented `  | `, control bytes dropped). Non-zero from FILE is `RESULT cc-verify fail ...` and exit 3. It `unset`s `GH_TOKEN` and `OPENROUTER_API_KEY` before the build, so no host credential reaches the container.
- Branch `docs/working/live-check-q125.sh`: C1 to C6 checks printing `RESULT <id> pass|FAIL|SKIP`; must run through Claude's Bash tool. Its C1 judges a credential read by **exit status** and aborts the whole script if `cat` succeeds.
- Branch `devcontainer-config/managed-settings.json`: sandbox enabled, `failIfUnavailable`, `allowUnsandboxedCommands: false`, `autoAllowBashIfSandboxed: false`, denyRead `~/.claude/.credentials.json`, denyWrite list, allowWrite caches and `/tmp`.
- Plan step 6 (branch `docs/working/plan-q125-cc-isolated-sandbox.md`): credential refused, settings and `.git/config` writes refused, Q-098 leak list, `gh api user` / `git push --dry-run` without a network prompt, `example.com` denied, the listed denyWrite paths, a looping credential read across a refresh, one build per toolchain.
- `docs/working/research-branch-verify-without-install.md` §4 Q5/Q9: the checks need a Claude Code session and a credential in the verify volume; a fresh volume has none.
- `scripts/self-improvement.sh` `claude_headless_flags()` prints `--permission-mode acceptEdits` (plus `--add-dir`s); the file can be sourced (main guard at :381).
- `hooks/wiring.json`: `permissions.deny` holds `Bash(*.credentials.json*)`; PreToolUse Bash hooks are `guard-trusted-writes.py` (denies a Bash command whose text names `.claude` with a policy file) `auto-approve-allowed-commands.sh` (never asks or denies) and `live-verify-gate.sh` (acts only on `git commit`).

## Findings from the binary (Claude Code in this sandbox, `bin/claude.exe`)

- **denyRead masks a file with `--ro-bind /dev/null <file>`** (the regular-file read-deny path in the binary's Linux sandbox code: `R.push("--ro-bind","/dev/null",Tn)`). A refused read therefore *succeeds* and prints nothing. The branch script judges C1 by exit status, so `C1-cat-credential` will print FAIL on a working sandbox, and the abort right after it skips the other C1 lines and C2 to C6: a VERDICT pass is impossible until the branch is fixed. FILE's X1 checks judge by content instead. This is a branch fix, out of scope here: it is the question in the final marker.
- `ANTHROPIC_BASE_URL` is read by the binary (also under the gateway mode), which is what the stub design uses.

## Design choice 1: how FILE reaches the sandboxed Bash path (divergent design)

Constraints: H2 (fail closed, loud), H3 (hermetic tests), H4 (an LLM is not the enforcement), S1, S3 (headless flags from their one source), S10 (one host paste, nothing waits on the owner when a fail-closed alternative exists); brief: stdin closed, no login in the fresh volume, never `--bare`, judge by the envelope.

| Option | How | Verdict |
|---|---|---|
| A. `claude -p` with a real login | the owner logs in inside the verify container from a second terminal while FILE waits | Fails S10: the owner at a prompt mid-run; cc-verify's `relay` pipe buffers FILE's instructions, so FILE cannot even tell them when. A real LLM also decides whether to run the script (H4). |
| B. `claude -p` against a local model stub | FILE starts a stdlib Python server on 127.0.0.1 that speaks the Messages API (JSON and SSE) and answers with fixed `tool_use` Bash calls; `ANTHROPIC_BASE_URL` points there, `ANTHROPIC_API_KEY` is a dummy | No login, no owner, no LLM, deterministic. The real Claude Code permission rules, hooks and sandbox handle the tool calls. Residual: unverified live (Claude Code's request shapes against a stub); every way it can go wrong is a `Q0-*` FAIL, not a pass. |
| C. Walkthrough | the owner runs the branch script by asking Claude in an interactive verify session | Several host steps and an exit status that is not the verdict; the brief's fallback only if no non-interactive way works. |
| D. Call bwrap directly with Claude's arguments | reimplement the sandbox invocation | Proves a copy, not Claude Code's sandbox. Rejected outright. |

B dominates (Path A of divergent design): decided.

## Smaller choices (one line each)

- Order of tool calls: FILE's X checks first, branch script second, so the X results exist even when the branch C1 aborts.
- Credential: a canary JSON with a per-run random marker and no `claudeAiOauth` key (so Claude Code keeps the API key); FILE refuses if a credential already exists.
- Rename check (plan's C10, `--watch` needs `/login`): FILE's unsandboxed renamer replaces the canary by `mv` every 0.5 s between x.sh's `go` and `stop` signals in a `/tmp` dir; `X4-renamer-ran` fails if fewer than 2 renames happened, so the loop cannot pass vacuously.
- `gh`/`git push` "not prompting": in `-p` mode a network prompt cannot be answered, so a reply from GitHub (401 for a dummy token, a username refusal for push) is the pass.
- C3 nested worktree: FILE adds one, so `C3-nested-settings-1` runs instead of SKIP.
- The marker has no hyphen: groff (`man -l`) prints `-` as U+2010 under the container's UTF-8 locale, which hid a readable credential from the first version's grep (review finding). x.sh matches the marker's shape (`q125canary` + 16 hex), so the full marker is on no command line.
- Non-vacuity: `X1-credential-present` (the path exists in the sandbox; a mask shows a character device) and `X0-canary-intact` (the first canary was still in place when x.sh reached X4).
- Stub sequencing: the next tool call goes only to the main thread (after the prompt, or after the previous call's result); a side query carrying the tool list gets text.
- Envelope: `is_error` false, `num_turns` at least 3, no `permission_denials`. `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` is not set, so the run keeps daily sessions' feature flags.
- Required ids: a fixed list; a branch rename of an id fails the verdict naming it (fail closed).
- FILE's private state lives in `$HOME/q125-verify.*` (not sandbox-writable, name free of `.claude` so `guard-trusted-writes.py` ignores the command text).
- Paths: no `Paths:` line in the brief; changes are FILE, its test and this doc, off `devcontainer-config/`, `hooks/` and the Q-125 branch.

- Failure-pattern skip: the fix commit corrects review findings in this branch's own unmerged file; no shipped code failed, and the groff-hyphen mechanism is recorded above.

## Invariants

- cc-verify's contract: FILE's exit 0 is pass, anything else is exit 3 (cc-verify.sh step 7).
- No host credential reaches the container (cc-verify `unset`s); FILE needs none.
- The branch script runs unmodified.

## Gotchas

- Failure-pattern grep: FP-047, FP-075, FP-076, FP-096, FP-097, FP-147 (see Prior failures)
- Probes in this sandbox's zsh do not word-split `$var`; probe under `bash -c`.

### Prior failures

`grep -inE 'sandbox|credential|headless|stub-accept|permissive-stub|exit-status|process-substitution|vacuous-pass|masked|renam' docs/failure-patterns.md` (FP-038, FP-043, FP-138 matched on "rename" but are unrelated).

- FP-075/FP-076: headless sessions deny tools not allowed; FILE passes exact `--allowedTools "Bash(<cmd>)"` rules, and a denied call is `Q0-tool-call-N` FAIL.
- FP-096: a run that exits 0 with empty results; FILE requires the stub to have received each tool result and every required id to appear.
- FP-097: `--bare` drops auth; FILE refuses flags holding `--bare`.
- FP-147: an exit status lost in a process substitution; FILE checks that `claude_headless_flags` printed something.
- FP-047: a poisoned helper persisting to a later unsandboxed run; FILE's helpers live in the throwaway container and are removed.

## Verification

- `bats test/q125-verify-check.bats`: 10 cases (pass, FAIL line, SKIP line, missing id, canary leak, canary removed before X4, envelope `is_error`, denied tool call, unsandboxed exec detecting every X1/X2/X4 leak including `man -l`, refusals before planting). The fake `claude` refuses wrong argv/env and runs only commands matching an allow rule.
- The live run is the owner's paste (final marker).

## Files read

`devcontainer-config/cc-verify.sh`, branch `docs/working/live-check-q125.sh`, branch plan step 6, branch `devcontainer-config/managed-settings.json` and `egress/base.txt`, `docs/working/research-branch-verify-without-install.md`, `scripts/self-improvement.sh` (claude_headless_flags, main guard), `hooks/wiring.json`, `hooks/guard-trusted-writes.py` header, `devcontainer-config/init-firewall.sh` (loopback accepts, nat rules), `docs/working/watching.md` Q-098.
