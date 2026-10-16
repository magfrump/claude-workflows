# claude-workflows: repo rules

These rules are for work in this repo only. The global instructions (`global-instructions/CLAUDE.md`, installed as `~/.claude/CLAUDE.md`) already load in every session, so nothing from them is repeated here (log row 47). Because this file exists, Claude Code does not load AGENTS.md, which stays the entry point for other agents. Never import another file into this one: every session and subagent here would load it (log row 65; `test/agents-gemini-sync.bats` checks).

Design constraints that bind every choice a loop makes are in `docs/constraints.md`. The rules below are coding rules.

## Code

- Untrusted or operator-shaped text reaches a subprocess as its own argv element, or through a quoted heredoc (`<<'EOF'`). Never interpolate it into a string a shell re-parses: `sh -c "$x"`, `eval`, `shell: true`. Keep a needed shell body static, pass values as `"$1"`…, and put `--` or `./` before path arguments (record 018; the reference pattern is in `scripts/confine-tests.sh`).
- Headless `claude -p` is built by `claude_headless_flags()` (`scripts/self-improvement.sh`). Never pass `--bare`, which drops subscription auth. Judge a run by its JSON envelope (`is_error`, `num_turns`), not its exit code (log rows 24, 37).
- A change to an enforcement file needs a `Live-verified:` (or `Host-tool-tested:`) trailer, and a plan that changes one needs a pre-mortem listing the bypass families. `hooks/live-verify-gate.sh` refuses the commit otherwise (log rows 45, 61, 71).

## Tests

- Stub `claude`, `curl`, `gh` and `wget` in `setup()` with a PATH shim, or carry `# @network: allowed — <reason>`; `scripts/hermeticity-lint --root .` checks this. The lint is triage; `scripts/confine-tests.sh` is the ground truth (record 017).
- A stub is at least as strict as the tool it replaces: one that accepts any argv once let a test reach a live container (log row 44).
- Never `skip` on the presence of a file in this repo; a missing file is a failure (record 023).
- Test a check in its real default position and under the permission model it ships with (log row 50).

## Probes and scratch work

- Create the temp dir and `cd` into it in the same script as the probe, and abort if that fails; never rely on a variable set in an earlier Bash call.
- Run anything that can hang under `timeout`. Stop processes by PID, never `pkill -f`: other sessions share the uid.
- Before the final test gate, make sure no probe is still running, and send the gate's output to a file (log row 61).
