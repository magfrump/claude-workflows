# Research: grant the runner's web tools to headless report generation

Brief: `docs/working/briefs/2026-11-20-eval-web-tools-grant.md` (at eb5b55c1). Branch: `fix/eval-web-tools-grant`.

- Failure-pattern grep: FP-075, FP-076 (headless session denied a tool it was told to use; environment divergence), FP-097 (never `--bare`)
- Failure-pattern skip: FP-075 already records this family (a headless run denied a tool the setup assumed it had); this is one more instance, not a new pattern.

## What the code does

- `test/skills/generate-reports.bash` builds `claude_args` with `-p --system-prompt-file ... --strict-mcp-config --restricted --safe-mode`, then `--tools "$TOOLS_ARG"` from the runner's `FIXTURE_TOOLS`, then `DENY_RECORD_FLAGS` (only under `FIXTURE_BASH=deny-record`), then `--model` and `CLAUDE_FLAGS`. Nothing granted any tool.
- `test/skills/runner-contract.bash` allows `RUNNER_ALLOWED_TOOLS=(Read Grep Glob WebSearch WebFetch Agent)`; `check_runner_settings` already refuses anything else before the grant is computed.
- Only `test/skills/fact-check/runner.bash` lists web tools (`WebSearch,WebFetch`, inline mode).
- `claude_headless_flags()` (`scripts/self-improvement.sh`) is not used by the generator and is out of scope; nothing here passes `--bare`.

## Live probes (2026-11-20, CLI 2.1.329, temp dir, generator's own flags)

- `--tools WebSearch,WebFetch` alone, WebFetch prompt: `permission_denials: ["WebFetch"]` (F1 reproduced).
- Same plus `--allowedTools WebSearch,WebFetch`: `permission_denials: []` for both a WebFetch and a WebSearch call; `is_error: false`, `num_turns: 2`. So `--restricted` ignores settings files but honours the CLI grant flag.

## Design choices (one line each; none has 3+ viable options)

- Grant spelling: `--allowedTools <one comma-joined argv element>` dominates. `--permission-mode bypassPermissions` grants every tool (refused by the brief); a `--settings` JSON allow rule adds a second mechanism for the same job (S3). Path A.
- Which names: the intersection of `FIXTURE_TOOLS`, `{WebSearch, WebFetch}` and `RUNNER_ALLOWED_TOOLS`, computed once after the runner is checked; no grant at all when empty.
- Variadic flag: the real `--allowedTools` takes following non-flag arguments; in every argv the generator builds only flags and their values follow it (`DENY_RECORD_FLAGS` never coexists with a web tool, then `--model`, `CLAUDE_FLAGS`). A test pins that `--model` is not swallowed.
- Tests in a new file, `test/generate-reports-web-grant.bats`, rather than growing the 813-line `test/generate-reports.bats`, with its own strict argv-parsing stub (unknown flag, missing value, `--bare` or a stray positional exits 2) instead of loosening the shared one.

## Verification

- `bats test/generate-reports-web-grant.bats test/generate-reports.bats`: 54/54 pass. The 3 grant-presence cases fail against the eb5b55c1 generator (old-code check), the 2 absence cases pass on both.
- `scripts/hermeticity-lint --root .`: 147 files, no unstubbed spawns.
- `scripts/health-check.sh`: "All checks passed." (rc 0) at 846eee77.
- Review-fix loop: round 1 found two amber test gaps (an empty `--allowedTools` could pass as absent; the deny-record case did not assert the deny flags) and an overstated comment; round 2 found test 4 could not fail (the stub dropped `--model`). All fixed; mutants (grant guard removed, grant split, filter removed, deny flags removed or cut, model dropped) each fail at least one case.

## Host step (for the cycle to file as a `you: terminal` entry once this merges)

The sandbox has no general web egress, and regeneration is out of scope here. On the host, in a checkout of main:

```
bash test/skills/generate-reports.bash fact-check && bats test/skills/fact-check-eval.bats test/skills/fact-check-edge-cases.bats test/skills/fact-check-format.bats
```

Then commit `test/skills/fact-check/output/` (reports, stamps, any `.failed`).

## Docs that describe report generation's tools

- `test/skills/generate-reports.bash` header: updated (the `--allowedTools` entry in the flag list, plus the `WEB_GRANT` comment).
- `guides/skill-creation.md:63` describes report generation but not its tool flags; no edit needed. It is outside `Paths:` (`test/`) anyway.
- `docs/roadmap.md:111` holds the Now item this closes; outside `Paths:` and off-limits, named here for the cycle to retire.
- `docs/thoughts/`: no match for `generate-reports`.
