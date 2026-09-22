Commit: 16f2978

# Security Review — answers-2026-09-20, review-fix iteration 2

**Scope:** partial — `git diff f023357..answers-2026-09-20` (fix commits). Focus: `hooks/guard-trusted-writes.py` (c5a7c96), `scripts/questions.sh` (a5c2a2c, 42bf2fc), and the SI Run-cell reader (efd66e4) for A6c.
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report-iter2.md` (k=3 merged). Its verdicts are not re-verified here. Its Claim 1 residual bypasses are adjudicated below, not re-probed.
**Probes:** all hermetic. The repo hook was fed JSON directly, with `CC_WEB_TAINT_DIR` pointing at a scratch dir, and file-tool probes ran against a fake `HOME` that models the installed symlink layout. `questions.sh` ran in temp git repos under a temp `HOME`. The pre-fix hook came from `git show f023357:hooks/guard-trusted-writes.py`. Scripts and outputs are in `scratchpad/security/` (`probe.py.txt`, `fprobe.py.txt`, `fsetup.sh.txt`, `qsetup.sh.txt`, `cmds.txt`).

## Trust Boundary Map

```
B1: model-issued Bash command text (may carry injected intent) → bash_targets() regex tiering → deny / ask / defer, then the shell writes ~/.claude/*
B2: model-issued Edit/Write file_path                        → classify_path() (lexical, normpath, resolve) → defer onto permissions.deny, or ask
B3 (moved): symlinked install layout (~/.claude/{hooks,CLAUDE.md} → $CC_WORKFLOWS_DIR) → _HARD_FILE_TARGETS / _HARD_DIR_TARGETS → treated as HARD, so defer
B4: cloned-repo docs/working/ tree (attacker-authored, symlinks included) → assert_write_target / replace_with → file writes by questions.sh
B5: tracked hypothesis-log.md cells (Round, Run)              → _valid_run_id (Run only) → path construction under docs/working/
B6: web / MCP content ingested this session                   → web-taint-mark.py (WebSearch/WebFetch only) → the taint flag that gates SOFT asks
```

| Label | Source | Mutability | Trust (per sink class) |
|---|---|---|---|
| S1 | Bash `command` string | request-time | UNTRUSTED for the policy-file write sink (it can be steered by injected content) |
| S2 | Edit/Write `file_path` | request-time | UNTRUSTED for the policy-file write sink |
| S3 | `$HOME`, `$CLAUDE_CONFIG_DIR`, `$CC_WORKFLOWS_DIR` | deploy-time | trusted for choosing which dirs are policy dirs |
| S4 | symlink targets under `~/.claude` | deploy-time (linker); runtime-mutable only by a writer who already has `~/.claude` | trusted as layout; the target's writability decides impact |
| S5 | `docs/working/**` in the caller's repo | repo-author-controlled | UNTRUSTED for write-path sinks; UNTRUSTED for read-into-context sinks |
| S6 | `QUESTIONS_LIVE` / `QUESTIONS_ARCHIVE` | deploy-time (operator env) | trusted by design; exempt from containment |
| S7 | hypothesis-log Round and Run cells | repo-author-controlled (tracked file) | UNTRUSTED for path construction |
| S8 | taint flag file | runtime | trusted as a signal, but incomplete: it misses MCP and subagent content (C1) |

The hook is the only gate on B1, because deny rules do not cover Bash. On B2 the hook defers HARD paths, so safety depends on `permissions.deny` matching the same paths. The fixes move more paths onto that dependency (B3). `questions.sh` now treats S5 as hostile on the write side. Of the S7 cells, only Run is validated.

## Findings

#### 1. Directory-granularity writes into `~/.claude` name no policy file, so the hook gives no opinion, even when tainted

**Severity:** Medium
**Location:** `hooks/guard-trusted-writes.py:190-205`
**Boundary:** B1
**Move:** 11 (enumerate bypasses)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
    if HARD_FRAG.search(cmd):
        return "hard"
    # R1 / Q-035: CLAUDE.md plus any home/global indicator -> the global file may be meant.
    if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):
        return "hard"
    # A10: settings*.json / hooks plus the config dir named anywhere.
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
```
The co-occurrence rule still needs a policy-file name in the text. A write whose destination is the config dir itself never names one. Executed probe results (U = untainted, T = tainted):
```
U=defer  T=defer  | cp -r /tmp/p/. ~/.claude/
U=defer  T=defer  | rsync -a /tmp/p/ ~/.claude/
U=defer  T=defer  | cd ~/.claude && cp /tmp/p/* .
U=defer  T=defer  | mv /tmp/p/* ~/.claude/
U=defer  T=defer  | cp -r /tmp/p/. ~
```
Each of these replaces `~/.claude/settings.json`, which in the installed layout is node-owned and writable (`-rw-r--r-- node`). That file wires every hook and holds `permissions.deny`, so one such command removes the guard and the deny rules together. The pre-fix hook gives the same result, so this is **pre-existing, not a regression**. It is a different class from A8 (unrecognised primitives) and A10 (path spelling): here the primitive is recognised, and no policy name is present to spell. The rule's comment at `:166-170` ("a home/global indicator ANYWHERE … together with a policy-file name") describes its reach accurately. The gap is in the design, not the documentation.

**Recommendation:** Treat a recognised write primitive together with a CFG_INDICATOR (the config dir named anywhere) as HARD, with no filename required. This follows the fail-closed direction Q-048 already accepts. Alternatively, treat any write whose text contains the config dir as a bare destination (a trailing `/`, `.` or `*`) as HARD.

#### 2. Resolve-onto-target HARD classification turns the payload CLAUDE.md's tainted "ask" into "defer" (regression in writable-payload layouts)

**Severity:** Medium
**Location:** `hooks/guard-trusted-writes.py:86`, `:133-134`
**Boundary:** B2, B3
**Move:** 5 (invert the access-control model)
**Confidence:** Medium (the mechanism was executed; the impact depends on Claude Code deny-rule symlink semantics, which were not verified)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
_HARD_FILE_TARGETS = {_safe_resolve(CONFIG_DIR / "CLAUDE.md"), _safe_resolve(HOME / "CLAUDE.md")}
```
```
    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
        return "hard"
```
In a fake `HOME` where `~/.claude/CLAUDE.md` and `~/.claude/hooks` are symlinks into a **writable** payload dir, an Edit of the payload path directly behaves as follows:
```
current:  U=defer  T=defer  | FH/payload/CLAUDE.md
pre-fix:  U=defer  T=ask    | FH/payload/CLAUDE.md
```
HARD means "defer and let `permissions.deny` block it". The deny rules name `/home/node/.claude/CLAUDE.md`, not the link target. Unless Claude Code's matcher resolves symlinks, the payload CLAUDE.md now has no gate in a tainted session, where it previously had an ask. c5a7c96's message discloses this ("If a checkout of this repo is the payload that ~/.claude links to, its hooks/ and global CLAUDE.md now defer rather than ask"). The layout is reachable because `link-claude-home.sh:35` honours `SRC="${CC_WORKFLOWS_DIR:-/opt/claude-workflows}"`. In the shipped image `/opt/claude-workflows` is `root:root 0555/0444`, and `touch` into it failed as `node`, so there is no impact in this container. (`payload/hooks/*` was already a defer before the fix, so only CLAUDE.md regressed.)

**Recommendation:** Classify a resolve-only match (a path that reaches a HARD target only through `resolve()`, with no lexical or normpath match) as SOFT rather than HARD. The lexical `~/.claude/...` spelling stays HARD and still defers to deny. The direct target path gets an ask when tainted, which is what the pre-fix hook did. Also ask a host check to confirm whether deny rules match resolved targets (see Finding 3).

#### 3. Deny rules that HARD-defer relies on may be settings-relative, not absolute (unverified, pre-existing)

**Severity:** Medium
**Location:** `hooks/wiring.json:120-127` (as installed: `~/.claude/settings.json:7-12`, `"Edit(/home/node/.claude/settings*.json)"`); consumed by `hooks/guard-trusted-writes.py:240-243`
**Boundary:** B2
**Move:** 3 (check the error path)
**Confidence:** Low (docs recollection only; the probe was not run because it needs a live Claude Code permission check)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
      "Edit({{CLAUDE_DIR}}/settings*.json)",
```
```
        if tier == "hard":
            # DO NOT "ask": that would override your permissions.deny (#39344).
            # Defer and let the deny rule block it.
            defer()
```
This builds on fact-check escalation r2. As recalled, Claude Code's Read/Edit rule syntax reads `//path` as absolute, `~/path` as home-relative, and `/path` as **relative to the settings file**. If that is right, `Edit(/home/node/.claude/settings*.json)` inside `~/.claude/settings.json` does not name the real file. Every file-tool HARD path would then defer onto a rule that never fires. The two `~/CLAUDE.md` rules would be unaffected. This predates the diff (wiring.json is unchanged in this range), but c5a7c96 widens the set of paths routed onto it (normpath, resolve targets). This review did not WebSearch, so the reviewer session stays untainted for its own probes.

**Recommendation:** Run one host check: try an `Edit` of `~/.claude/settings.json` in a session with the hook installed and see whether it is denied. If it is not, emit `{{CLAUDE_DIR}}` rules as `//…` or as `~/.claude/…`, and add a health-check that exercises one deny rule.

#### 4. Round cell still reaches path construction without validation (A6c's sibling)

**Severity:** Low
**Location:** `scripts/lib/si-morning-summary.sh:1010`, `:1199-1203`, `:1360-1364`
**Boundary:** B5
**Move:** 12 (sweep every call site)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
        round="${fields[1]:-}"
```
```
                 printf '%s\n' "$working_dir/archive/${run}-tasks-round-$round.json"
                 _live_run_matches "$working_dir" "$run" \
                     && printf '%s\n' "$working_dir/tasks-round-$round.json"
             fi
             printf '%s\n' "$working_dir/tasks-round-$round.json"
```
efd66e4 validates the Run cell. The Round cell comes from the same tracked row and is glued into the same paths. `_row_is_open_deferred` (`:1623-1624`) only applies its integer check inside the round-window gate, and a non-integer Round falls through to legacy behaviour. Executed probe: with `w/tasks-round-1/` present, `_find_tasks_file "1/../../outside/x" …` returned `…/w/tasks-round-1/../../outside/x.json`, and `_resolve_hypothesis_target` emitted `skill:leak` read from that outside file. The read is read-only, and only `skill:`/`workflow:` names from `files_touched` reach the output. An attacker must commit both the row and a `tasks-round-N/` directory to the repo the SI loop runs on. That is the loop's own trusted input principal, which is why this is rated Low despite the named mechanism.

**Recommendation:** Treat a Round cell that does not match `^[0-9]+$` as absent at the row reader (`:1010`), next to `_valid_run_id`.

#### 5. "Writes never go through a symlink" overstates the guard

**Severity:** Informational
**Location:** `scripts/questions.sh:47-51`, `:91-103`
**Boundary:** B4
**Move:** 2 (implicit sanitization assumption)
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
    [[ -L "$file" ]] && die "refusing to write: $file is a symlink"
    [[ -L "$dir" ]] && die "refusing to write: directory $dir is a symlink"
```
With default paths, a `docs -> .git` symlink passes: `init` exited 0 and created `.git/working/questions.md` and `questions-archive.md`, because the resolved path stays inside the root. That is harmless, since the names and content are fixed and cannot become a git hook or config file. It also sidesteps the intent of A11's `.git` refusal. For overridden paths, a symlinked grandparent is followed (fact-check Claim 4). There, containment is exempt by design, because S6 is trusted. The code is sound for the stated threat, but the header comment claims more than the code enforces.

**Recommendation:** Reword the header comment to "the file and its directory are never symlinks; a default path must resolve inside the repo". Optionally, also refuse a resolved path under `$root/.git/`.

### Untested bypass candidates

- `~/.claude.json` (the MCP server and trust config, which is command-execution-relevant). `echo '{}' > ~/.claude.json` defers in both tiers. This was **tested**, and it is outside the hook's declared HARD/SOFT definition, so it is not filed as a finding. It is listed here as a scoping question for the author.
- `questions.sh check`/`open`/`next-id` read through a symlinked `questions.md` (for example, one pointing at `~/.claude/.credentials.json`). Not tested. `parse_entries` emits only `### Q-` lines, so disclosure looks minimal, but `check`'s error messages were not read to their end.
- A git-config-driven command in a non-cloned `.git/` (an extracted tarball) while `git rev-parse` runs. Not tested, and pre-existing (`:76`, `:80`).
- Claude Code deny-matcher behaviour on case (`SETTINGS.JSON`) and symlinks. Not testable here (Finding 3).

## Endorsement Claims

- **Claim:** Every R1/A10 spelling listed in c5a7c96, plus `cd ~/.claude && cp -r /tmp/p/hooks .`, `echo x > "${HOME}"/.claude/"hooks"/g.py`, `exec 3> ~/.claude/settings.json` and `echo x >| ~/CLAUDE.md`, returns deny from the repo hook.
  **Location:** `hooks/guard-trusted-writes.py:190-205`
  **Evidence:** executed
  **Verified:** `scratchpad/security/probe.py.txt` output, untainted and tainted; the fact-check's Claim 16 covers the listed set.
  **Not verified:** the deployed copy under `~/.claude/hooks` (C14: the old hook is still installed).
  **route: code-fact-check**
- **Claim:** `replace_with` renames over the target, so a symlink planted at the target is replaced rather than written through. Default-path containment refused `docs/working -> ../other` (a directory symlink).
  **Location:** `scripts/questions.sh:115-124`, `:91-103`
  **Evidence:** executed (dir-symlink refusal); read-static (rename semantics)
  **Verified:** `qsetup.sh.txt` case 2 exited 1 with "directory … is a symlink".
  **Not verified:** a concurrent swap of the directory between the `-L` re-check and `mv` (outside the stated threat model).
  **route: code-fact-check**

Not endorsed, because the guardrail has an open bypass (move 11): the Bash co-occurrence rule as a whole (Finding 1 and fact-check Claim 1).

## Primitive sweep

Primitive: path join from untrusted cells or trees (read and write)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/lib/si-morning-summary.sh:1199` `archive/${run}-tasks-round-$round.json` | S7 | `_valid_run_id` (run only) | Finding 4 (round) |
| `scripts/lib/si-morning-summary.sh:1201,1203` `tasks-round-$round.json` | S7 | none | Finding 4 |
| `scripts/lib/si-morning-summary.sh:1360-1364` `…round-$round-report.json` | S7 | `_valid_run_id` (run only) | Finding 4 |
| `scripts/questions.sh:81-82` LIVE/ARCHIVE | S5/S6 | assert_write_target | Finding 5 (Informational); otherwise cleared |
| `scripts/questions.sh:117` mktemp in target dir | S5 | O_EXCL + re-check | cleared |
| `scripts/questions.sh:312` `mktemp` (system tmp) | code-constant | n/a | cleared — scratch, never renamed |
| `scripts/questions.sh:434-436` noclobber create | S5 | re-check + O_EXCL | cleared (fact-check Claim 9 caveat: an existing non-regular target is followed; racing one in needs a concurrent local attacker) |
| `hooks/guard-trusted-writes.py:122-126` expanduser/normpath/resolve | S2 | tiering | Finding 2 |

Primitive: shell write (Bash text)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/guard-trusted-writes.py:190-205` | S1 | co-occurrence regex | Finding 1; fact-check Claim 1 residuals (adjudicated below) |

## Iteration-1 finding status

- R1: partially-resolved — every listed spelling now denies (`hooks/guard-trusted-writes.py:197`). The remaining spellings from fact-check Claim 1, bare `cd; echo x > CLAUDE.md` and `/home/$USER/CLAUDE.md`, are **pre-existing residuals** of the accepted `cd ~` class. They classify SOFT and ask when tainted, the same as at f023357. They are not regressions.
- R2: resolved for default paths — `scripts/questions.sh:91-103,115-124` refuse file and dir symlinks and dangling links, and enforce containment. Explicit-override grandparent symlinks are followed by design (S6 trusted). The comment overstates this (Finding 5).
- R3 (security aspect): resolved — `config_dir()` at `hooks/guard-trusted-writes.py:63-73` matches the linker's `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` for empty and `~` values. The relative-value abspath is disclosed (fact-check Claim 8). The deny-rule syntax premise is unverified (Finding 3, pre-existing).
- R4: partially-resolved — `~/.claude` spellings with `..`, a project `.claude` symlinked to `~/.claude`, and `hooks/*` no longer ask (`:121-134`). The same resolve-onto-target change regresses the direct payload `CLAUDE.md` from ask to defer in writable-payload layouts (Finding 2, disclosed in c5a7c96, no impact under the root-owned `/opt`).
- A6 (part c, Run-cell traversal): partially-resolved — Run is validated at `si-morning-summary.sh:1018,1189,1350`. The Round cell from the same row still traverses (Finding 4, pre-existing).
- A8: acknowledged — settled Defer row in `docs/reviews/override-log.md`; the TODO is at `hooks/guard-trusted-writes.py:150-155`.
- A10: partially-resolved — `~/.claude//settings.json`, `~/".claude"/settings.json` and `cd ~/.claude && … > settings.json` deny (`:200`). Glob or quote obfuscation of the `.claude` dir name (`~/.clau*/…`, `~/.cl""aude/…`) and a glob in `hoo*` still defer. These are pre-existing residuals, the same at f023357, and the same class as the accepted filename obfuscation.
- A11: resolved — `scripts/questions.sh:76-78` refuses a cwd inside `.git`. A `docs -> .git` symlink still lands writes under `.git/working/` (Finding 5, harmless).
- C1: still-open — the taint source is unchanged (`hooks/web-taint-mark.py` is not in this diff). It still widens every SOFT-only residual above (R1 bare `cd`, `/home/$USER`), which ask only when tainted.

Regressions introduced by the fixes: Finding 2 (payload CLAUDE.md ask→defer). No other regression was found in the paths probed. Every other before/after probe pair matched or improved.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Directory-granularity writes into ~/.claude get no opinion, even when tainted (pre-existing) | Medium | B1 | `hooks/guard-trusted-writes.py:190-205` | High |
| 2 | Resolve-target HARD turns payload CLAUDE.md ask→defer (regression, disclosed) | Medium | B2, B3 | `hooks/guard-trusted-writes.py:86,133-134` | Medium |
| 3 | Deny-rule `/abs` paths may be settings-relative (unverified, pre-existing) | Medium | B2 | `hooks/wiring.json:120-127` | Low |
| 4 | Round cell traverses paths (A6c sibling, pre-existing) | Low | B5 | `scripts/lib/si-morning-summary.sh:1010,1199-1203,1360-1364` | High |
| 5 | questions.sh "never through a symlink" overstates; `docs -> .git` accepted | Informational | B4 | `scripts/questions.sh:47-51,91-103` | High |

## Overall Assessment

The fixes do what they claim for the enumerated spellings and for the questions.sh write paths, and nothing here is a HALT. The main residual risk sits in the design of B1. The Bash tier still keys on a policy-file name appearing in the text, so a plain `cp -r …/. ~/.claude/` replaces the node-writable `settings.json` (which holds both the hook wiring and the deny list) with no opinion from the hook, even in a tainted session. That is pre-existing and fixable in place with one more fail-closed co-occurrence clause. The second priority is the host check in Finding 3: every file-tool HARD path defers onto deny rules whose path syntax has not been verified, and c5a7c96 routes more paths onto them. No findings within the code paths read beyond those listed; endorsement claims pending execution verification.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown critique saved to /workspace/docs/reviews/security-review-2026-09-21-answers-iter2.md, structured per your role skill, with an `## Iteration-1 finding status` section covering your domain items, ending with a Goal-Alignment Note.
- **Answered:** all domain items (R1, R2, R3 security aspect, R4, A6c, A8, A10, A11, C1) have status lines. Five findings are filed with executed evidence where possible. Q-048's false denies were not re-flagged.
- **Out of scope:** pre-f023357 commits beyond regression comparison; A7; the non-security aspects of R3 and A6; si-functions migration (R5) and pipe-split (A12) internals.
- **Escalate:** Finding 3 needs a live host check of Claude Code deny-rule path semantics (orchestrator or user, `you: terminal`). Finding 2 asks whether the disclosed writable-payload regression is accepted, which is an author decision.
