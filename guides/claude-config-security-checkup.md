# Claude Config Security Checkup

Last verified: 2026-07-07
Relevant paths: hooks/claude-config-audit.sh, test/hooks/claude-config-audit.bats

## Overview

Claude Code reads certain files as **instructions**, not data: `settings*.json`,
`CLAUDE.md` / `AGENTS.md`, skill and command markdown, memory files, `.mdc`
rules. A prompt-injection or sandbox-escape payload smuggled into one of these
— by a compromised plugin, a pasted snippet, or an errant autonomous edit —
gets executed with the session's trust. This checkup process audits those
trusted-policy files with `~/private_reviews/claude_config_audit.py`, which
detects:

- **ESCAPE** — sandbox/permission bypasses (`bypassPermissions`,
  skip-permissions and no-sandbox flags, the IS_SANDBOX env override —
  written out here in prose so this guide doesn't flag itself).
  Severity splits on *directive* (config sets it / a command runs it → HIGH)
  vs *mention* (prose names it → LOW).
- **HIDDEN** — invisible Unicode: bidi overrides (Trojan-Source), the Tags
  block (invisible ASCII smuggling), zero-width chars outside emoji context,
  stego variation selectors. Emoji construction chars are whitelisted.
- **SEMANTIC** — plain-language red flags in policy files: instruction
  overrides ("ignore previous…"), pipe-to-shell, base64 decode,
  credential-dir references, exfil verbs, external URLs.

The auditor exits nonzero iff any HIGH finding exists. It lives **outside
this repo** (it reviews this repo's own policy files, so committing it
alongside them would let a policy-file attacker also edit the scanner).

The process has two layers: a per-edit hook (continuous) and a periodic full
sweep (batch).

## Layer 1: per-edit hook (automatic)

`hooks/claude-config-audit.sh` is a `PostToolUse` hook on `Edit|Write|MultiEdit`.
When the edited file is a trusted-policy file, it runs the auditor on that one
file. HIGH findings come back to Claude as post-edit feedback (exit 2), so the
session that made the edit is told to review or revert it; everything else is
silent. Ordinary source edits are never scanned — the sandbox, not this
scanner, is the mitigation for code-as-data.

Wiring (settings.json + symlink) is manual; see
`docs/working/wire-claude-config-audit.md`. Until wired, the hook is inert.

Env knobs: `CLAUDE_CONFIG_AUDIT_SCRIPT` overrides the auditor path
(default `~/private_reviews/claude_config_audit.py`);
`CLAUDE_CONFIG_AUDIT_DISABLE=1` disables the hook. If the auditor or
`python3` is missing, the hook degrades to a silent no-op.

## Layer 2: periodic full sweep (manual)

Run the auditor over everything it considers policy:

```sh
# Default roots: ./.claude, ~/.claude, ./CLAUDE.md
python3 ~/private_reviews/claude_config_audit.py

# Explicit roots — this repo IS ~/.claude's backing store, so sweep both:
python3 ~/private_reviews/claude_config_audit.py ~/.claude ~/claude-workflows

# Aggregate counts only (quick health signal):
python3 ~/private_reviews/claude_config_audit.py --summary ~/.claude
```

Run a sweep when:

- **After installing or updating a plugin** — plugin-shipped skills auto-trigger
  from their own descriptions. Plugins are skipped by default; include them:
  `python3 ~/private_reviews/claude_config_audit.py --include-plugins ~/.claude/plugins`
- **After merging a branch that touched `skills/`, `workflows/`, `hooks/`,
  `CLAUDE.md`, or templates** — especially branches produced by autonomous
  (SI/Ralph) loops, where no human read every edit.
- **After pasting external content** into any policy file (hidden Unicode
  survives copy-paste invisibly).
- **On a schedule** — monthly, or fold `--summary` into
  `scripts/health-check.sh`-style routine checks.

`--all-files` scans every text file, not just policy files; it is noisy by
design and only for spot checks.

## Triage

- **HIGH** (auditor exits nonzero): stop and inspect before continuing.
  - *ESCAPE DIRECTIVE*: a config actually sets a bypass or a command actually
    invokes one. If you didn't put it there deliberately, treat as compromise:
    revert the file from git, then check `git log -p` for how it arrived.
  - *HIDDEN*: view the exact bytes (`grep -nP '[^\x00-\x7F]' <file>` or
    `hexdump -C`), delete the invisible chars, and re-run. Don't trust what
    the rendered text *looks* like — that's the attack.
- **MED** (word-joiners, odd control chars): usually LaTeX/paste cruft.
  Clean up when convenient.
- **LOW** (escape *mentions*, SEMANTIC flags): spot-check only. Docs that
  *discuss* the skip-permissions flag (like this repo's guides) will always
  produce these; that is expected and fine.

### Known baseline noise (2026-07-07 sweep)

A full `~/.claude` sweep flags some paths that are HIGH by pattern but benign
by provenance — verify once, then expect them:

- `~/.claude/cache/changelog.md` — Anthropic's own CLI changelog documents
  invocations of the skip-permissions flag; refreshed on update, not editable
  policy.
- `~/.claude/projects/*/tool-results/*.txt` — session transcripts, not
  instructions Claude re-reads; the auditor's `.claude`+`.txt` rule catches
  them. Findings there reflect past session *content*, not live policy.

Anything HIGH in `settings*.json`, `CLAUDE.md`, `skills/`, `memories/`, or
`hooks/` wiring does **not** belong on this list — investigate those.

A finding in a file you're about to **trust for the first time** (new plugin,
cloned starter config) deserves stricter reading than one in a file you wrote
yourself.
