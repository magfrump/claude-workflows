# Sandbox Tool Map

Last verified: 2026-07-09
Relevant paths: test/sandbox-tool-map-drift.bats, test/round-log-functions.bats, docs/decisions/014-secure-tool-guidance-layers.md

## Overview

The 2026-07-09 hardening removed arbitrary-execution-capable Bash prefixes
from `permissions.allow` in `~/.claude/settings.json` and enabled the bwrap
sandbox (network egress limited to an allowlist; writes confined to the
project and scratchpad). This guide maps each denied or prompt-generating
tool class to its allowed equivalent, so agents stop rediscovering the
denylist by trial and error — every denied call wastes the tokens of the
call plus the retry, and every prompt costs user attention.

Rules of engagement on any sandbox or permission denial:

1. Find the failing command's row below and use the allowed equivalent.
2. Never retry the denied command verbatim.
3. Never reach for `dangerouslyDisableSandbox` as a first resort — it is for
   confirmed sandbox-infrastructure failures, not for routing around the
   denylist.
4. If no row matches, prefer a dedicated tool (Read / Edit / Write / Glob /
   Grep / WebFetch) over the shell equivalent, or ask the user rather than
   escalating privileges.

Decision context: `docs/decisions/014-secure-tool-guidance-layers.md`
(instruction layer, layer 1 of 3).

## Substitution table

| Denied / prompt-generating | Allowed equivalent | Why |
|----------------------------|--------------------|-----|
| `find`, `fd` | Glob tool, or `rg --files -g '<glob>'` | Removed from allowlist: `-exec`/`-delete`/`-x` make them arbitrary-execution-capable. Denied calls waste tokens. |
| `sed -n '<addr>p' <file>` | Read tool (line-addressable via offset/limit); `rg -n '<pattern>'` | `sed` removed from allowlist (scripting surface). Read paginates and numbers lines for free. |
| `sed -i` | Edit tool | In-place shell edits bypass the reviewed-diff path and generate prompts; Edit is tracked. |
| `>` / `>>` / `tee` / heredoc file writes | Write tool | Shell redirection to guarded paths prompts or is denied; Write is tracked and reviewed. |
| `cat` / `head` / `tail` / `wc` / `diff` on files | Still allowlisted, but prefer Read for file contents | Not denied — this row is preference: Read gives line numbers, pagination, and file-state tracking, and avoids prompt risk on unusual paths. |
| `wsl` | None — do not invoke | Removed: arbitrary execution into the Windows host. If Windows-side action is needed, ask the user. |
| `hyperfine <cmd>` | `hyperfine --version` is the only allowlisted form | Removed: benchmarks execute arbitrary command strings. Any real benchmark run will prompt — ask before benchmarking. |
| `terraform plan` | `terraform validate` / `show` / `providers` / `state list` / `output` | `plan` can execute external providers and hooks; the read-only subcommands remain allowlisted. |
| `curl` / `wget` to arbitrary hosts | WebFetch on allowed domains | Sandbox network egress is allowlisted (openrouter.ai, github.com, elan.lean-lang.org); other hosts fail in-sandbox or prompt. `curl -I/--head/-v/--version` are allowlisted command forms but still subject to the host allowlist. |
| `git commit -m` with `<` / `>` in the message | Write the message to a `$TMPDIR` file, then `git commit -F <file>` | Known guard-trusted-writes false positive: heredoc bodies with trailers like `Co-Authored-By: X <email>` look like redirection to the guard. |
| Bare `/tmp` paths | `$TMPDIR` or the session scratchpad | The sandbox write allowlist covers `$TMPDIR` and the scratchpad, not bare `/tmp`. |
| Live `claude` / `gh` / `curl` / `wget` inside bats tests | Stub the binary in `setup()` with a PATH shim | Keeps suites hermetic — a live binary in a test is a hidden network call and prompt source (see the 4d39475 incident). Pattern: `test/round-log-functions.bats` (`mkdir "$TEST_TMPDIR/bin"`, write a stub script, prepend to `PATH`). |

## Drift check (machine-readable)

`test/sandbox-tool-map-drift.bats` parses the marker lines in the fenced
block below and compares them against the live
`~/.claude/settings.json` `permissions.allow` (readable by the sandboxed
agent; only writes are guarded):

- `allow-prefix: X` asserts the broad entry `Bash(X:*)` **is present**.
- `deny-prefix: X` asserts the broad entry `Bash(X:*)` **is absent**
  (narrower forms like `Bash(hyperfine --version:*)` may still exist).

Only command prefixes named by this guide's substitutions are listed —
deliberately not the full allowlist (see decision 014's failure-driven
mitigation: the digest lists substitution-relevant prefixes only). If the
drift test fails, update the table above *and* these markers together.

```text
allow-prefix: rg
allow-prefix: grep
allow-prefix: ls
allow-prefix: cat
allow-prefix: head
allow-prefix: tail
allow-prefix: wc
allow-prefix: diff
allow-prefix: jq
deny-prefix: find
deny-prefix: fd
deny-prefix: sed
deny-prefix: sed -n
deny-prefix: sed -i
deny-prefix: wsl
deny-prefix: hyperfine
deny-prefix: terraform plan
```
