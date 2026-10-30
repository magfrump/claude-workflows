# Security Review — feat/q106-host-settings-merge, confirming pass 4

**Range:** main...9f27309b (iteration 4, Q-174 [1]; merge of main 536678c0). Probes in jq 1.6 under `env -i`, as `sjq` runs it. The reviewing subagent could not write files; this is its report, saved by the orchestrating session. S4-1 was reproduced independently before saving.

## Pass-3 findings

| # | Status | Evidence |
|---|---|---|
| S3-F1 group level | Closed | Executed: extra group key, object or empty `hooks`, non-object group, object or null matcher, string timeout, duplicate-key tricks all refused. T100. |
| S3-F2 `$` anchor | Closed | Executed: `lbl` quotes `"allow\n"`, `"\nallow"`; command regex refuses a leading or trailing newline, NUL, look-alike slashes. T105. |
| S3-F3 duplicates | Closed | Executed: one copy → three lists 2 ADD; two → one lists 1 UNWIRE. `["ab","a"] \| less(["a"])` is `["ab"]`. T104. |

## Findings

#### S4-1. The merge program can read any JSON file the user can read and write it into settings.json (Medium; confidence High)

jq 1.6 accepts `import ".credentials" as $c {search: "../../"};`. The search path resolves relative to the program file, `$dest/.cw-new.hooks/lib/`, so it reaches `$dest/.credentials.json`; an absolute search path works too. `env -i`, `HOME=/nonexistent` and `-L` do not stop it. Reproduced: a program of that one line plus `. + {env: {X: ($c[0].accessToken)}}` emits the token. The by-name list prints `(none …)`; the diff shows it. **Exposure:** the token is printed in the review before the y, and after the y it is stored in settings.json, which no deny rule protects from a later agent session. (After the y a hostile branch's hooks run with the same access, so the new exposure is the pre-consent display and the persistence.) Pass 1 listed import reach as cleared but did not try the `search` metadata form.
**Fix:** refuse a merge program containing the words `import` or `include` (install.sh is gated code). Optionally gate `hooks/lib/wiring-merge.jq` and `hooks/wiring.json` in `live-verify-gate.sh` (Q-175 answered [1]: not gated).

#### S4-2. The shape check constrains the program's input, not its output (Medium; High)

A branch that changes only `wiring-merge.jq` bypasses every shape fix. The by-name list covers only hook commands and permission array entries: probe output with `disableAllHooks: true`, a `statusLine` command, `apiKeyHelper`, `env.ANTHROPIC_BASE_URL` and `permissions.defaultMode: "bypassPermissions"` listed one hook change. The full diff shows all of it.
**Fix:** an output-side check in install.sh: `del(.hooks, .permissions)` unchanged; non-array `permissions` keys unchanged; every group in the output that is not in the input passes the wiring group predicate with `{{CLAUDE_DIR}}` resolved. This also closes most of S4-1's write paths.

#### S4-3. A hook's timeout is not in its by-name key, and any number passes (Medium; Medium)

A wiring change setting `"timeout": 0.001` on `guard-trusted-writes.py` lists `(none …)` (executed). Unverified: whether Claude Code lets a tool call proceed when a PreToolUse hook times out; if so, the guard fails open.
**Fix:** refuse `timeout` (the shipped wiring sets none), or key hooks by the whole hook object.

#### S4-4. Event names and permissions are unchecked (Medium; Low)

An unknown event key, a newline in an event or matcher, arbitrary permission modes, an array `defaultMode`, `allow: Bash(*)` and `additionalDirectories: ["/"]` all pass and are written (the last two do show as ADD lines). The risk rests on S3-F1's unverified premise: Claude Code may reject a schema-invalid settings file whole, deny rules and guard hooks with it.
**Fix:** event keys `\A[A-Z][A-Za-z]+\z` (or Claude Code's list), matcher without control characters, permissions `{deny: [string]}` only (the shipped wiring has only `deny`).

#### S4-5. The Write-twin prune ported in 536678c0 is not scoped to `$dir` (Info; Medium)

A wiring `Edit(//etc/shadow)` removes the user's `Write(//etc/shadow)` and `Write(/etc/shadow)`. Each removal prints as `REMOVE … rule:`; Claude Code does not match `Write(path)` today (062acde2), so nothing is lost now.
**Fix (hardening):** scope it like the single-slash prune.

## Not tested

Claude Code's behaviour on a hook timeout and on a schema-invalid settings.json (needs a host); a hook path the payload does not ship (`hooks/-c`); install.sh end to end with the S4-1 program; jq 1.7 import rules.
