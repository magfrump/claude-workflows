# 023: Wire the hooks from the image, by merge rather than by link

**Date:** 2026-07-30 · **Status:** Accepted · **Amended:** 2026-07-30 (A, B below)

Installed and verified on 2026-07-30: the image was rebuilt, `link-claude-home.sh` ran,
and all eight wiring entries are live in `~/.claude/settings.json` with `{{CLAUDE_DIR}}`
resolved. Seven of the eight hooks were then verified functional by direct invocation;
the eighth is amendment A below.

**Amends:** [022](022-claude-workflows-payload-in-cc-isolated.md), section "Hooks are shipped but NOT wired".

## Context

022 baked the payload into the image and symlinked it into the per-project `~/.claude`
volume, but deliberately stopped short of wiring the hooks:

> `hooks/` is linked so the scripts are present, but nothing is written to `settings.json`.
> Hook wiring changes session behavior — the `PreToolUse` guards can block tool calls — and
> that should be a human opt-in, not something an image rebuild switches on silently.
> Wiring the two non-blocking `UserPromptSubmit` reminders is a reasonable follow-up.

The opt-in never happened, and structurally it could not have: wiring meant hand-editing
`settings.json` inside *every* per-project Docker volume, a file that no repo artifact
tracks and that a fresh volume recreates empty. `docs/working/wire-batch-feedback-reminder.md`
has carried the manual procedure since 2026-06-23 and records it as applied on one host —
a host that predates the volume model. The observed state on a rebuilt image (2026-07-30)
was eight hooks present at `~/.claude/hooks/` and zero of them wired.

This is the same failure shape 022 itself diagnosed for skills: the artifact was present,
looked installed, and did nothing.

## Decision

Keep the human opt-in; move where it lives. The gate is now `install.sh`'s
diff-and-bless — `hooks/wiring.json` is a tracked repo file that appears in that diff —
rather than a per-volume hand-edit that in practice was never performed.

- **`hooks/wiring.json`** (new, tracked) is the canonical wiring: the event key, matcher,
  and command for all eight hooks. Paths use a `{{CLAUDE_DIR}}` token, substituted at merge
  time with the resolved `CLAUDE_CONFIG_DIR`. (Amendment B adds a `permissions` section and
  nests the event keys under a `hooks` key.)
- **`link-claude-home.sh`** merges it into `~/.claude/settings.json` at container start,
  per event key, as `(existing - ours) + ours`. Array subtraction is deep equality, so the
  merge is exactly idempotent and preserves every hook entry it did not author.
- **`CC_SKIP_HOOK_WIRING=1`** skips the merge entirely.

### Why merge, and not symlink like everything else

`settings.json` cannot be a symlink into the root-owned payload. It lives in the volume
because Claude Code **writes** to it at runtime (`theme`, `effortLevel`, and whatever the
next release adds); pointing it at a `0444` root-owned file would make those writes fail.

The consequence is worth stating plainly: **this is a default, not a boundary.** Unlike
`skills/` — which is root-owned precisely so a session cannot rewrite the critics that
review it — the merged `settings.json` is node-writable. A session can delete a hook from
its own wiring; the next container start restores it. Anything that must actually be
enforced against the agent belongs in the image, not here.

### Why the two permission-path hooks are on by default

022's caution was specifically about `PreToolUse` guards that can block calls. Both such
hooks are wired anyway, on the reasoning that their failure modes are asymmetric:

- `guard-trusted-writes.py` denies writes to trusted-policy paths (`~/.claude/settings*.json`,
  `~/.claude/hooks/**`, `CLAUDE.md`). Unwired, the protection is simply absent — and this
  is the one hook whose whole purpose is to constrain the agent. Wiring it can only ever
  cost a false-positive deny on a file the human can still edit by hand.
- `auto-approve-allowed-commands.sh` grants permission for piped commands whose every
  component already matches an allowlisted `Bash(...)` prefix. It widens nothing: a command
  it approves is one the allowlist already approved, minus Claude Code's inability to
  prefix-match through a pipe.

Ordering between them is not load-bearing — Claude Code's precedence is deny > ask > allow,
so a `deny` from the guard beats an `allow` from auto-approve regardless of array order.

### Two dependencies the wiring exposed

Wiring the hooks surfaced two ways in which shipping a script is not the same as shipping a
working hook. Both are fixed here, and both were invisible while nothing was wired:

- **`shfmt`** was absent from the image. `auto-approve-allowed-commands.sh` parses commands
  with `shfmt -tojson`; without it the parse fails, the hook takes its `|| exit 0` fallback,
  and it silently approves nothing. Added to the Dockerfile as a pinned GitHub release with
  per-arch SHA-256 ARGs — the Android layer's discipline (#19) rather than rustup's
  fetch-the-adjacent-checksum, because this binary sits on the permission path.
- **`scripts/`** was not in the payload. `log-usage.sh` sources
  `../scripts/lib/skill-paths.sh` relative to its own resolved path, so a payload with
  `hooks/` but no `scripts/` left that hook dead on arrival. Added to `install.sh`'s
  `CLAUDE_HOME_SRC` and to `link-claude-home.sh`'s `ENTRIES`.

## Consequences

- **Easier:** every cc-isolated session gets the routing reminders, the usage telemetry that
  decision 012's measurement program assumes exists, the web-taint marker, and the
  trusted-write guard — in any repo, without per-volume setup.
- **Harder:** a hook that misbehaves now misbehaves everywhere at once, and the fix path is
  install + bless + rebuild. `CC_SKIP_HOOK_WIRING=1` is the escape hatch for a session that
  needs to get work done before that lands.
- **Editing `wiring.json` strands the old entry.** Idempotency is by exact match on the
  matcher-group object, so changing a command leaves the previous version in any
  already-merged `settings.json`. Bump and prune in the same pass.
- **`docs/working/wire-batch-feedback-reminder.md` is superseded** for cc-isolated. It
  remains the procedure for a bare host install with no devcontainer.
- **Usage telemetry starts flowing for the first time.** Any longitudinal read of
  `skill-usage-report.sh` should treat 2026-07-30 as the start of the series, not a change
  in behavior — prior emptiness measured an unwired hook, not unused skills.

## Amendment A (2026-07-30): the config auditor ships in-repo

Post-install verification found `claude-config-audit.sh` wired into every session and
**inert**. It resolved its auditor from `$HOME/private_reviews/claude_config_audit.py` — a
path that does not exist in any container and structurally cannot, since the payload is
assembled from repo contents. Every edit to a trusted-policy file hit the
`[[ -f "$AUDIT_SCRIPT" ]] || exit 0` bail and nothing was ever scanned.

This is the third instance of the same failure this decision keeps meeting: an artifact
that is present, looks installed, and does nothing. 022 found it for skills, 023 found it
for hook wiring, and the wiring itself surfaced it for the auditor.

**The auditor now lives at `scripts/claude_config_audit.py`**, tracked, and the hook
resolves it relative to its own `readlink -f` path — the same mechanism `log-usage.sh`
already relies on, and the reason `scripts/` is in the payload at all. Resolution order is
`CLAUDE_CONFIG_AUDIT_SCRIPT` → payload `scripts/` → `~/private_reviews/` (retained for bare-host
installs).

The original rationale for keeping it out of the repo was that a policy-file attacker
should not also be able to edit the scanner. Moving it into the payload **strengthens**
that property rather than weakening it: `/opt/claude-workflows` is root-owned `0555`, so
the agent cannot modify the auditor at all, whereas `~/private_reviews/` was node-writable.
The property is genuinely weaker only for a bare-host install pointed at a writable
checkout — there, keep using `CLAUDE_CONFIG_AUDIT_SCRIPT` to point outside the repo.

Three integration tests in `test/hooks/claude-config-audit.bats` had been silently
skipping on `[ -f "$REAL_AUDIT" ] || skip`. The skip guard is removed: the auditor's
presence is now a repo invariant with its own test, and the integration tests run.

## Amendment B (2026-07-30): wire the deny rules the guard depends on

`guard-trusted-writes.py` does **not** block HARD-tier paths for `Edit`/`Write`/`MultiEdit`.
It deliberately defers, because a hook returning `ask` silently overrides `permissions.deny`
(Claude Code issue #39344) — the deny rules are what does the blocking on that path. Its
docstring says so: *"These are also covered by your Edit/Write DENY rules."*

They were not. The merged `settings.json` had no `permissions` key at all. 023 carried over
only the first of the three layers `docs/working/wire-security-hooks.md` describes (hook,
`permissions.deny`, sandbox `denyWrite`), and the second was recorded there as *"guarded and
not repo-tracked; apply manually"* — the same never-happens manual step 023 exists to
eliminate. Net effect: the guard's HARD tier was live for Bash and a no-op for the file
tools.

`hooks/wiring.json` now carries a `permissions` section merged by the same
`(existing - ours) + ours` rule, per mode. Its event keys move under a `hooks` key so the two
sections sit side by side; the matcher-group objects are byte-identical to before, so
already-merged settings strand nothing. The wired deny list covers the guard's HARD tier
(`settings*.json`, `hooks/**`, `~/.claude/CLAUDE.md`, `~/CLAUDE.md`) plus the credential
reads from that doc, and adds `~/.claude/.credentials.json`, which holds the session OAuth
token and was readable.

Notable consequences:

- **`~/.claude/settings.json` is no longer agent-editable via the file tools.** 023 called
  the merged settings "a default, not a boundary" on the grounds that the agent could edit
  it back; with the deny rules wired, it is closer to a boundary. Bash writes were already
  denied by the guard. Editing it now means doing so by hand, or via
  `CC_SKIP_HOOK_WIRING=1`. The `update-config` skill will be denied on this file.
- **Layer three is still absent.** Sandbox `denyRead`/`denyWrite` is not wired here, and
  `~/.claude/hooks/**` in cc-isolated is protected by root ownership rather than by the deny
  rule — the rule is belt-and-braces that makes the failure legible (denied, not `EACCES`).
- **`docs/working/wire-security-hooks.md`'s "Related settings hardening" section is
  superseded for cc-isolated**, the same way this decision superseded the batch-reminder
  wiring doc. It remains the procedure for a bare host.
