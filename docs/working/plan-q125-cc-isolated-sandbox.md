# Plan: Q-125 — Claude Code's Bash sandbox in cc-isolated

- **Goal**: Make Claude Code's Bash sandbox run in cc-isolated, refusing sandboxed reads of `~/.claude/.credentials.json` and writes of `~/.claude/settings*.json`, without granting the container a capability (Q-124 [1]).
- **Project state**: Builds Q-124 [1] as Q-125, in two stacked units (U1 seccomp, U2 managed settings) · unblocks Q-098 (global allowlist) · blocked on one host run (cite: docs/spikes/weaker-nested-sandbox-cc-isolated.md)
- **Task status**: in-progress (steps 1–5 done: host probe passed 2026-10-07, Q-127 moot; step 6 live run pending, via `docs/working/live-check-q125.sh`)

Research: [research-q125-cc-isolated-sandbox.md](research-q125-cc-isolated-sandbox.md)

## Approach

Start from Docker's default seccomp profile and add one tagged rule that lets namespace and mount syscalls through without CAP_SYS_ADMIN. Load it from runArgs. Install bwrap and socat in a late layer. Bake enforcing sandbox settings as root-owned Claude Code *managed* settings: link-claude-home's merged `settings.json` is agent-editable by design. Render `allowedDomains` from the firewall's own parsed allowlist at build time. Nothing merges until a host probe and a live cc-isolated run pass.

## Steps

1. **U1** `seccomp-cc-sandbox.json`, its runArgs, and the bwrap/socat layer. Add the file to PAYLOAD, enforcement_files, the gate regex and the test fixtures. Add `test/seccomp-cc-sandbox.bats`. (~215 lines, 116 of them upstream-derived data.) Done: `6fdd62d6` on `feat/q125a-seccomp`.
2. **U2** `managed-settings.json` (template) and `cc-sandbox-settings.sh` (renderer), rendered into `/etc/claude-code/managed-settings.json` in the Dockerfile tail, root-owned. Add both to PAYLOAD/enforcement. Add `test/cc-sandbox-settings.bats`. (~230 lines.) On `feat/q125-cc-isolated-sandbox`.
3. Explicit settings decisions, recorded in the template's `_comment` and in decision log 53:
   - no `enableWeakerNestedSandbox`
   - `failIfUnavailable: true` (fail closed, FP-058)
   - `allowUnsandboxedCommands: false`
   - `autoAllowBashIfSandboxed: false`: the sandbox is a floor under the prompts, and widening prompting is Q-098's call
   - `allowManagedDomainsOnly` and `strictAllowlist` (the firewall admits nothing else)
4. Docs: this plan, the research doc, the host probe script, decision log 53 amendment, and questions entries.
5. **Host, you: terminal**: run `docs/working/probe-q125-bwrap.sh`. If A/T1 fails (no fresh `/proc`), the `/proc` judgment question decides between weaker mode, `systempaths=unconfined` and stopping.
6. **Host, you: terminal**: `install.sh`, bless, `cc-isolated --probe-only <repo>`, then in a session:
   - a sandboxed `cat ~/.claude/.credentials.json` is refused
   - a write to `~/.claude/settings.json` and to `.git/config` is refused
   - Q-098's leak list is re-run
   - `gh api user` / `git push --dry-run` do not prompt for network; a sandboxed `curl https://example.com` is denied, not prompted (this confirms `strictAllowlist` is honoured)
   - sandboxed writes are refused for `~/.elan/bin/x`, `/tmp/cc-web-taint/x`, `/workspace/.claude/settings.json`, a nested worktree's `.claude/settings.json`, and a worktree's `.git` pointer file
   - a looping sandboxed `cat ~/.claude/.credentials.json` stays refused across `/login` or a token refresh
   - one build per toolchain a project uses (cargo, uv, npm, lake) succeeds under allowWrite
7. pr-prep review-fix loop per unit, U1 then U2. Merge only after step 6 passes, with `Live-verified: <hash>`.

Implementation order: `1 → 2 → [3, 4] → 5 → 6 → 7` (5 can change step 2's settings or step 1's runArgs).

## Size estimate

U1 ~215 changed code lines, U2 ~230. Each is under the decision-62 cap; the combined ~445 was over, hence the split. No file passes 500 lines because of this change (`init-firewall.sh` and `install.sh` were already over and are untouched beyond one PAYLOAD line).

- **Estimated context cost**: Research ~60k, Implementation ~60k, Review ~40k
- **Actual context cost (post-implementation)**: Research ~70k, Implementation ~60k, Review pending

## Test specification

No `test-strategy` run: the change is config plus a 40-line renderer, and the specification below was written by hand from the failure modes.

| Test case | Expected behavior | Level | Diagnostic expectation |
|---|---|---|---|
| Profile minus tagged rule = upstream | canonical sha256 equals the pinned moby v28.3.3 hash | characterization | got/want hashes printed |
| Exactly one added rule | names = clone, mount, pivot_root, umount2, unshare; ALLOW; no args/includes/excludes | unit | the rule JSON is echoed |
| setns / clone3 unchanged | setns only under SYS_ADMIN; no non-SYS_ADMIN ALLOW for clone3 | unit | offending rules echoed |
| runArgs | `seccomp=${localEnv:CC_CONFIG_DIR}/…` present; no SYS_ADMIN/unconfined outside comments | unit | matching lines echoed |
| Render fills domains, drops `_comment`, rest = template | exact JSON equality | unit | jq diff via `[ = ]` |
| Zone → `*.zone`, ports dropped, dedup | as stated | unit | domain list echoed |
| Empty input / bad entry / bad template | non-zero exit, empty stdout | unit | entry and status echoed |
| Every shipped profile renders to exactly its entries plus GitHub | equality per profile | property | profile name echoed |
| Template switches | enabled, failIfUnavailable, unsandboxed=false, autoAllow=false, no weaker, deny paths present, nothing re-opens `~/.claude` | unit | the failing field |
| Dockerfile renders in the tail, root-owned, packages present | line ordering and grep | unit | line numbers |
| **Live (host)** fresh `/proc`, credential refused, settings write refused, leak list, no network prompts | probe + session checks | integration | probe RESULT lines |

## Failure modes considered

| Failure mode | Guard |
|---|---|
| Sandbox cannot start, and Bash silently runs unsandboxed | `failIfUnavailable: true`; template test |
| The agent edits or overrides the sandbox settings | managed settings, root-owned file and dir (0444/0555); Dockerfile test; managed outranks user/project |
| The profile drifts from upstream or widens beyond the five syscalls | canonical-hash test plus exact-rule test |
| allowedDomains admits something the firewall does not, or misses GitHub so `gh`/`git` prompt | rendered from `--print-entries`; per-profile equality test; GitHub forms added; host check |
| Fresh `/proc` mount refused under Docker's masked paths | host probe T1 (not guardable in this sandbox); judgment question |

`/pre-mortem`: the enforcement-file rule requires one. The bypass-family pass is below in place of a separate pre-mortem doc; the security-review subagent's table is appended to it. `/architecture-review`: not triggered. The files touched are config files under one module (`devcontainer-config/`) plus their tests and one gate regex; no module boundary moves.

### Bypass families

| Family | Status |
|---|---|
| Model sets `dangerouslyDisableSandbox` | covered: `allowUnsandboxedCommands: false` (managed) |
| Project or user settings re-enable, widen or weaken the sandbox | covered: managed tier; `allowManagedDomainsOnly`; true/false-restrictive table in the binary |
| Agent rewrites the managed file | covered: root-owned 0444 in a root-owned 0555 dir; node has sudo only for init-firewall.sh |
| Sandboxed read of the credential | covered by denyRead (`/dev/null` bind) under a fresh `/proc` + `--unshare-pid`; **not covered under weaker mode** (probe T3) |
| Sandboxed write of settings / hooks / `.claude.json` | covered: denyWrite; hooks are symlinks into root-owned `/opt` |
| Sandboxed write of `.git/config`, `.git/hooks`, dotfiles, later executed unsandboxed | covered by the runtime's built-in write-deny list [inferred from binary]; host step 6 checks `.git/config` |
| `!` prefix and hooks run unsandboxed | not covered by design; the user types `!`, hooks are reviewed payload |
| Write to an allowWrite cache (`~/.cargo`, `~/.npm`, `~/.cache`, `/tmp`) that is later executed unsandboxed | partially: the only unsandboxed executors are hooks and `!`; a hook that runs a cached binary would execute planted code. Accepted residual, listed in decision log 53 |
| **PATH hijack through `~/.elan/bin`** (it was first on PATH and sandbox-writable; the next hook's bare `bash` would run a planted file) | covered after review: denyWrite `~/.elan/bin`, and elan moved to the END of PATH |
| Project files that execute later: `/workspace/.claude/settings*.json`, `.mcp.json`, `.git/config`, `.git/hooks` | covered: explicit managed denyWrite (absolute; `/workspace` is fixed). **Unknown**: nested `.claude/worktrees/*/.claude/settings*.json` and a worktree's `.git` pointer file / `commondir`. Live step 6 tries each |
| Deleting the web-taint state `/tmp/cc-web-taint` to disarm guard-trusted-writes | covered after review: denyWrite |
| `~/.claude/jobs` replaced by a symlink to `~/.claude`, making allowWrite bind `~/.claude` | covered after review: dropped from allowWrite |
| A lower settings tier flips a switch the managed file omits (weaker mode, `filesystem.disabled`, `allowAllUnixSockets`) | covered after review: each stated explicitly in managed settings |
| User-tier `excludedCommands` (arrays merge; managed cannot empty them) | residual: relies on `~/.claude/settings.json` staying unwritable (wiring's Edit deny + sandbox denyWrite) |
| Credential replaced by rename during a long-running sandboxed command, so the new file sits under no mask | **unknown**: live step 6 runs a looping sandboxed `cat` across a token refresh / `mv` |
| Nested user namespaces from inside the sandbox (Claude Code passes no `--disable-userns`; its own helper needs `unshare(CLONE_NEWUSER)`) | residual, part of Q-124's accepted kernel surface |
| Env secrets (`GH_TOKEN`, `OPENROUTER_API_KEY`) visible to sandboxed commands | not covered: they are opt-in per session and already readable by the agent; the sandbox restricts where they can be sent (allowedDomains = egress) |
| Container escape via the user-namespace kernel surface | accepted by Q-124 [1]; no capability added; setns still cap-gated |
| Network exfiltration to a firewall-admitted host | unchanged: the firewall's residuals (api.anthropic.com, GitHub) |

## Risks

- The fresh `/proc` mount is likely refused (see research Gotchas). If so, every remaining option is a judgment: weaker mode leaks via `/proc/<pid>/root`, `systempaths=unconfined` unmasks `/proc/sysrq-trigger` and friends for container root, or stop at deny + container.
- `failIfUnavailable: true` makes a future Claude Code release that breaks bwrap brick every session until a rebuild. That is the fail-closed price; the error names the cause.
- `allowUnsandboxedCommands: false` plus a narrow allowWrite may break builds that write elsewhere under `~`. Host step 6 should run one build per installed toolchain that a project uses; allowWrite is the knob.
- Coverage deferred: no live test of the sandbox in CI. Every sandbox check is a host step.

## Rollback

1. Before merge, nothing to roll back: both branches stay unmerged until host step 6 passes.
2. After merge, if sessions fail to start (`sandbox required but unavailable`) or Bash breaks: on the host, `git revert <U2 merge>` first. That removes the managed settings, so the sandbox is off and Bash runs exactly as before. Then `install.sh`, read the diff, bless, and `cc-isolated --probe-only <repo>` so the container is recreated on the reverted config (`devcontainer up` never rebuilds a running container on its own; decision log 45).
3. If the container itself fails to start (seccomp profile rejected by the host's Docker): also `git revert <U1 merge>`, then the same install/bless/probe cycle. The profile is additive, and with it gone runArgs is back to the two cap-adds.
4. Per-project volumes hold no state from this change (managed settings live in the image), so no volume surgery is needed. No irreversible component.
