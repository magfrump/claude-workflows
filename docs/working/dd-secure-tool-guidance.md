# DD: Guiding agents toward known-secure tools (post-hardening)

- **Goal**: Decide how to guide agents toward allowed/secure tools where they would otherwise reach for denylisted or prompt-generating ones — cutting failed-call token waste and notification noise without expanding the security surface; stretch goal: provably-scoped test fixtures.
- **Project state**: claude-workflows main · follows the 2026-07-09 permissions/sandbox hardening (arbitrary-exec prefixes removed from allowlist) · not blocked
- **Task status**: complete (user selected layers 2026-07-09; decision recorded in docs/decisions/014-secure-tool-guidance-layers.md)

## Context

The 2026-07-09 hardening removed arbitrary-execution-capable prefixes from
`permissions.allow` (`find:*`, `fd:*`, `wsl:*`, `hyperfine:*`, `sed -n:*`,
`terraform plan:*`), enabled the bwrap sandbox (network allowlist:
openrouter.ai, github.com, elan.lean-lang.org; writes confined to the project
+ scratchpad), and wired guard-trusted-writes over Bash. Consequences observed
in practice:

- Agents reach for now-denied tools, burn tokens on failing calls, then retry.
- Routine commands surface permission prompts (attention cost) — this session's
  `claude -p`-in-tests incident was exactly this class.
- Known guard false positive: `git commit -m` heredocs with `<...>` trailers.

Three goals, one stretch: (1) fewer failing tool calls, (2) fewer prompts on
routine work, (3) security surface not expanded — and ideally (4) test
fixtures with provably limited scope so suites can run without being able to
hide arbitrary code execution.

## Step 1 — Diverge

**Pre-generation grep**: `grep -B1 -A20 "Pruned candidates" docs/decisions/*.md`
filtered on `denylist|allowlist|sandbox|permission|secure|command` → no
matches. Candidate-0 scan of `docs/decisions/` (`allowlist|denylist|sandbox|permission`)
→ no adjacent prior decisions.
`Prior pruning grep: no matches found for [denylist, allowlist, sandbox, permission, tool selection]`

Candidates (no evaluation yet):

1. **Do nothing** — rely on in-session learning from denials.
2. **Compact CLAUDE.md substitution section** — a ~20-line "prefer allowed
   tools" table in global CLAUDE.md (e.g., `find` → `rg --files -g` / Glob
   tool; `sed -i` → Edit tool; `curl` → WebFetch; shell `>` writes → Write
   tool; `git commit -m` heredoc → `commit -F`).
3. **Standalone guide** `guides/sandbox-tool-map.md` — the full mapping +
   rationale, loaded on demand, referenced from the CLAUDE.md section.
4. **Deny-with-guidance PreToolUse hook** — detect denylisted command shapes
   and deny *with a message naming the allowed equivalent*, so the failure
   itself teaches.
5. **Extend auto-approve hook to safe forms of denied tools** — e.g., approve
   `find` without `-exec`/`-delete` via shfmt AST parse.
6. **Post-failure hint hook (PostToolUse)** — on a Bash result matching
   sandbox/permission-denial signatures, inject the relevant substitution row
   as additionalContext; guidance arrives exactly at the failure, costs zero
   tokens otherwise.
7. **Allowlisted wrapper scripts in the repo** — e.g., `scripts/safe-find.sh`
   allowlisted by prefix, implementing safe subsets.
8. **Sandbox-navigation skill** — skill with denial-related triggers.
9. **UserPromptSubmit reminder hook** — detect prompts likely to involve
   searching/testing and pre-inject tool guidance.
10. **Generated allowlist cheat sheet + drift test** — script renders a
    "currently allowed" digest from `~/.claude/settings.json`; a bats test
    fails when the guide and settings drift apart.
11. **Ideal-if-free: capability-manifest test harness** — each test suite
    declares capabilities (`network: none`, `write: tmpdir`); the runner
    executes bats under a per-suite bwrap profile enforcing the manifest.
    Fixtures become provably scoped, not conventionally scoped.
12. **Test-fixture hermeticity lint** — static bats suite that scans `test/`
    for un-stubbed invocations of network-capable binaries (`claude`, `curl`,
    `wget`, `gh`) and fails suites that don't stub them in `setup()`
    (generalizes commit 4d39475's stub pattern into an enforced convention).
13. **Naive: dump the full allowlist into CLAUDE.md** — complete visibility,
    always in context.
14. **Memory-based accretion** — on each denial, save a feedback memory with
    the substitution; guidance accumulates organically.
15. **Reframe: make more tools safe instead of steering around them** —
    per-command nested sandbox profiles so `find`/`sed -i` can be
    re-allowlisted inside tighter confinement.

**Lens coverage**: technical (5, 7, 11, 15), interface (2, 3, 10, 13),
procedural (12), time-shifted (14), reframe (1, 15). ≥2 lenses represented.

**Generation health check**: instruction-doc cluster (2, 3, 10, 13) shares the
assumption "guidance = static text an agent must recall"; candidates 4, 6, 11,
15 violate it (guidance delivered at failure time, or need removed entirely) —
cluster addressed, no additional generation needed. Do-nothing present (1),
naive present (13), ideal-if-free present (11). No candidate is untestably
vague. Dimensional variety: instructions / hooks / infrastructure / tests /
memory — no dimensional anchoring.

## Step 2 — Diagnose

Hard constraints:

- **H1 — No expanded security surface.** No new allowlist entry may be capable
  of arbitrary execution, and no guidance content may itself become an
  unguarded trust anchor.
  `success: claude-config-audit + security-reviewer pass over the change reports zero new arbitrary-exec-capable allow prefixes and zero new agent-writable files that influence permission decisions`
- **H2 — Guidance reaches the agent at decision time.** Static text that
  agents don't recall mid-task doesn't move the metric.
  `success: over the next ~2 weeks of sessions, repeat-denials for the same tool class within one session drop to ~zero (observable in usage.jsonl Bash-denial entries / user-reported prompt frequency)`
- **H3 — Non-interactive safe.** Nothing may block or prompt in SI/overnight
  runs.
  `success: an SI round runs end-to-end with the mechanism active, with no added AskUserQuestion/permission prompts attributable to it (round report clean)`
- **H4 — Drift-proof against hand-edited settings.** `settings.json` is
  guarded, hand-edited, not repo-tracked; instructions must not silently go
  stale.
  `success: either a bats drift test compares guidance to live settings, or the guidance is written as tool-preference principles that stay true under allowlist edits (named mechanism, checked in review)`
- **H5 — Bounded always-loaded token cost.** Persistent context additions
  small; detail on demand.
  `success: diff to always-loaded files (CLAUDE.md) ≤ ~30 lines; everything larger lives in guides/ or fires conditionally`

Soft constraints:

- **S1 — Portable to other agents** (Gemini/AGENTS.md read the same repo):
  prefer instructions over Claude-Code-only hooks where equal.
- **S2 — Advances the provably-scoped-fixtures ideal**, even partially.
- **S3 — Low implementation effort.**
- **S4 — Just-in-time delivery** — guidance at the moment of failure beats
  guidance an agent must remember.

Non-obvious constraints considered: settings.json can be *read* by the
sandboxed agent (only writes are denied) so generation/drift-checking is
feasible; the repo working tree is agent-writable, which poisons any design
that allowlists repo-resident executables; WSL2 bwrap nesting is fragile
(prior managed-settings incident), which raises risk on nested-sandbox designs.

## Step 3 — Match and prune

| # | Candidate | H1 surface | H2 decision-time | H3 non-interactive | H4 drift | H5 tokens | Notes |
|---|-----------|-----------|------------------|--------------------|----------|-----------|-------|
| 1 | Do nothing | ✓ | ✗ | ✓ | ✓ | ✓ | fails the point of the exercise |
| 2 | CLAUDE.md section | ✓ | ~ | ✓ | ~ | ✓ | recall-dependent; drift fixable via 10 |
| 3 | Standalone guide | ✓ | ~ | ✓ | ~ | ✓ | needs a pointer from CLAUDE.md to be found |
| 4 | Deny-with-guidance hook | ✓ | ✓ | ✓ | ~ | ✓ | duplicates deny logic already in settings/guard; two sources of truth |
| 5 | Auto-approve safe forms | ⚠ | ✓ | ✓ | ~ | ✓ | re-opens surface the hardening closed; AST-parse evasion risk |
| 6 | Post-failure hint hook | ✓ | ✓ | ✓ | ✓ (reads live settings) | ✓ | first failure still costs one call |
| 7 | Allowlisted repo wrappers | ⚠ | ✓ | ✓ | ✓ | ✓ | **repo is agent-writable → allowlisted repo script = arbitrary exec** |
| 8 | Skill | ✓ | ✗ | ✓ | ~ | ✓ | skills trigger on intent, not on tool failures |
| 9 | UserPromptSubmit reminder | ✓ | ~ | ✓ | ~ | ✗ | fires on most prompts; wrong timing, high token noise |
| 10 | Generated cheat sheet + drift test | ✓ | ~ | ✓ | ✓ | ✓ | solves 2/3's drift; not itself decision-time |
| 11 | Capability-manifest harness | ✓ | ✓(n/a) | ✓ | ✓ | ✓ | high effort; WSL2 nested-bwrap risk; the only *provable* fixture scoping |
| 12 | Fixture hermeticity lint | ✓ | ✓(at test-authoring time) | ✓ | ✓ | ✓ | convention-enforcing, not provable; cheap |
| 13 | Full allowlist in CLAUDE.md | ✓ | ~ | ✓ | ✗ | ⚠ | hundreds of lines, always loaded |
| 14 | Memory accretion | ✓ | ~ | ✓ | ~ | ✓ | unreliable recall of recall; no enforcement |
| 15 | Nested per-command sandboxes | ~ | ✓ | ✓ | ✓ | ✓ | re-allowlisting widens surface unless profiles are provably tight; WSL2 nesting fragile |

**Pruned**: 1 (✗ H2 — the status quo being fixed), 5 (⚠ H1 — re-opens closed
surface; parse-evasion is the guard's own documented weakness), 7 (⚠ H1 —
key insight: *any allowlisted executable inside the agent-writable repo is
arbitrary execution*; same argument as the hook copy-not-symlink rule), 8
(✗ H2 — wrong trigger model), 9 (✗ H5), 13 (⚠ H5, ✗ H4), 14 (mostly ~, no
mechanism), 15 (high effort + WSL2 fragility + H1 only ~; revisit if bwrap
nesting matures), 4 (dominated by 6: 6 delivers the same message without
duplicating deny logic — fixable weakness in 4 was "sync with settings", but
6 sidesteps it by reacting to outcomes instead of predicting them).

**Survivors** (4): [2+3] instruction layer (compact CLAUDE.md section +
on-demand guide — merged: 3 is 2's overflow), [6] post-failure hint hook,
[10] generated cheat sheet + drift test (folds into the guide), [12] fixture
hermeticity lint, with [11] retained as a spike-candidate for the stretch
goal rather than a step-4 scorecard row (its uncertainty is feasibility, not
tradeoff — DD→Spike handoff).

Fix sketches: [2+3] weakness (recall) is mitigated by pairing with [6];
[6] weakness (first failure still costs a call) is mitigated by pairing with
[2+3]; [10] weakness (not decision-time) is irrelevant in its role as drift
enforcement for [2+3].

## Step 4 — Tradeoff matrix

Candidates compose as layers; scored independently, choice is how far up the
stack to go.

| Approach | Effort | Risk | Coverage | Key downside |
|----------|--------|------|----------|--------------|
| [2+3] Instruction layer (CLAUDE.md ≤25 lines + guides/sandbox-tool-map.md) | ~2h | low | H1 ✓ H3 ✓ H5 ✓, H2 partial, H4 needs [10] | recall-dependent mid-task |
| [6] Post-failure hint hook | ~4h (hook + wiring doc + bats) | low-med | H1 ✓ H2 ✓ H3 ✓ H4 ✓ | Claude-Code-only; hook sprawl; first failed call still spends tokens |
| [10] Drift test for the guide | ~2h | low | H4 ✓ | reads live settings from tests (env-dependent; must skip cleanly elsewhere) |
| [12] Fixture hermeticity lint | ~3h | low | S2 partial, prevents 4d39475-class recurrences | convention-level, not provable; grep heuristics can false-positive |
| [11] Capability-manifest harness | days (spike first) | high (WSL2 nested bwrap) | S2 fully — the actual ideal | may be infeasible on this platform; per-suite profiles to maintain |

**Falsifiable hypotheses**:

- [2+3]: If adopted, same-session repeat denials for tools named in the table
  drop to ~zero within 2 weeks; counter-evidence: agents still retry `find`/
  `sed -i`/heredoc-writes after a denial in ≥2 sessions.
- [6]: If adopted, the *second* failing call of any denial class disappears
  from sessions within 2 weeks (hint lands after the first); counter-evidence:
  repeat denials persist, or the hook itself misfires on non-denial failures
  in >1% of Bash calls.
- [10]: If adopted, the guide never disagrees with live settings for longer
  than one test run; counter-evidence: a hand-edit to settings.json ships
  while the drift test stays green.
- [12]: If adopted, zero new suites reach a live network-capable binary
  (measured by strace spot-checks / prompt reports) after the lint lands;
  counter-evidence: another 4d39475-class incident in a suite the lint passed.
- [11]: If spiked, a bats suite runs under a nested bwrap profile on this
  WSL2 host with network denied and writes confined within a 1-day timebox;
  counter-evidence: nested bwrap fails (as managed-settings incident
  suggests) → candidate downgrades to "revisit when platform changes".

**Stress tests applied**:

- *Boring alternative* (vs [6]): is [2+3] alone the 80% version? Partially —
  it fixes the *known, recurring* classes (find, sed -i, heredoc-commit,
  curl), but this session's `claude -p` incident shows novel classes keep
  appearing; only a failure-triggered mechanism generalizes. Kept [6] as a
  layer, not a replacement. Also produced a scope cut: [6] should hint only
  on *sandbox/permission* failure signatures, not general command failure.
- *Invert the thesis* (vs the whole effort): are denials rare enough to
  ignore? No — two user-facing prompt bursts this week, plus SI overnight
  runs multiply any per-session waste. But inversion did downgrade urgency of
  [11]: no observed incident came from a *fixture deliberately hiding*
  execution; the observed incidents were accidental. [11] is insurance, not a
  fix for an active bleed → spike later, don't build now.
- *Failure-driven* (on [6] and [10]): new failure modes — (a) hint content
  becomes trusted policy: if the hint text lives in the agent-writable repo,
  a poisoned edit could steer agents toward a *worse* tool; mitigation: hint
  table ships as part of the deployed-copy hook, not read live from the repo
  (same copy-not-symlink rule). (b) [10]'s generated digest publishes the
  allowlist into the repo: mild information disclosure; acceptable — the
  allowlist is defense-in-depth, not a secret, and the digest can omit
  domains/paths, listing only command prefixes relevant to substitutions.
- *Organizational survival* (on the stack): instructions survive tool churn
  and apply to Gemini/AGENTS.md consumers (S1); hooks are Claude-Code-only
  and need wiring docs. This ordered the recommendation: instruction layer
  first, hook second.

**Matrix updates from stress tests**: [6] risk stays low-med but gains two
design constraints (deny-signature-only trigger; hint table embedded in
deployed copy). [11] demoted from "build" to "timeboxed spike, later".

## Step 4 output — recommendation

Layered adoption, in order: **[2+3] + [10] now** (instruction layer with
drift enforcement — one PR), **[6] next** (just-in-time hint hook), **[12]**
when touching tests next, **[11] as a deferred 1-day spike**. Confidence in
the instruction-layer-first ordering: ~85%; the open choice is how many
layers to commit to now, which is a scoping preference — Path B consult.

## Draft content for the instruction layer (what the CLAUDE.md section would say)

Principles (drift-proof phrasing) + the known substitution table:

- Prefer dedicated tools over shell equivalents: Read (not cat/head/tail for
  files), Edit (not sed -i), Write (not > / tee / heredoc), Glob + Grep/rg
  (not find), WebFetch (not curl/wget).
- File search: `rg --files -g '<glob>'` or the Glob tool replace ~all `find`
  uses; `rg -l`, `rg -n` replace `grep -r` and `sed -n` inspection.
- Commit messages with `<`/`>` content (trailers): `git commit -F <scratchfile>`,
  never `-m` with a heredoc.
- Tests that may invoke network-capable binaries (claude, curl, gh): stub
  them in `setup()` (see test/round-log-functions.bats for the pattern).
- Temp files: `$TMPDIR` / the session scratchpad, never bare `/tmp`.
- On a sandbox/permission denial: check `guides/sandbox-tool-map.md` for the
  allowed equivalent before retrying; never retry the same command verbatim
  and never reach for `dangerouslyDisableSandbox` as a first resort.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`.
Future DDs in adjacent areas can grep this section.
[1]: is the status quo being fixed. [4]: dominated by [6] — predicting denials duplicates settings; reacting to them doesn't. [5]: re-opens surface the 2026-07-09 hardening deliberately closed. [7]: allowlisted executable in an agent-writable repo = arbitrary execution (copy-not-symlink argument). [8]: skills trigger on intent, not tool failure. [9]: wrong timing, fires on every prompt. [13]: hundreds of always-loaded lines, stale on every settings edit. [14]: no mechanism, relies on recall of recall. [15]: WSL2 nested-bwrap fragility + re-allowlisting widens surface; revisit if platform matures.
Prior pruning grep: no matches found for [denylist, allowlist, sandbox, permission, tool selection].
