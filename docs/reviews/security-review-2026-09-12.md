# Security Review — prompt-audit application (2d679ce..HEAD)

Commit: 0661353

**Scope:** `git diff -M -C 2d679ce..HEAD` in `/workspace` (27 files; the security-bearing subset is `devcontainer-config/install.sh`, `scripts/health-check.sh`, `scripts/cross-model-review.py`, and the `CLAUDE.md` → `global-instructions/CLAUDE.md` rename)
**Date:** 2026-09-12
**Based on:** merged code-fact-check (k=3) supplied by the code-review orchestrator; not re-verified here
**Delivery mode:** self-read (218 KB diff, over the inline budget)

No HALT-ESCALATE pattern matched. No plaintext credentials, no unauthenticated privileged endpoint, no injection into user-facing code, no TLS disablement, no hardcoded keys appear in this diff.

---

## Trust Boundary Map

```
B1 (moved):  [repo working tree — agent-writable bind mount]
                 → [install.sh staging + `diff -ru` + human y/N + --bless]
                 → [$DEST installed config → Dockerfile COPY → /opt/claude-workflows root:root 0555]
                 → [link-claude-home.sh symlinks → ~/.claude → session instruction context]

B2:          [Edit/Write/MultiEdit or Bash write targeting a policy file]
                 → [guard-trusted-writes.py classify_path() / HARD_FRAG + permissions.deny]
                 → [on-disk trusted-policy file]

B3:          [a just-written policy file]
                 → [claude-config-audit.sh is_policy_file() gate → claude_config_audit.py]
                 → [ESCAPE/HIDDEN/SEMANTIC findings surfaced to the session]

B4 (moved):  [autonomous self-improvement worktree branch]
                 → [Gate 1d critical-file protection (name-matched against DELETED_FILES)]
                 → [merge into main]

B5:          [repo diff text + extracted finding text]
                 → [cross-model-review.py api() with OPENROUTER_API_KEY]
                 → [OpenRouter third-party inference, --judge model]
```

### Input-source classification

```
S1: repo working-tree files                — runtime-mutable (agent sessions
    (the moved global instructions file,     bind-mount the repo RW; install.sh's own
     hooks/, skills/, install.sh,            header says "an agent CAN edit these files")
     scripts/self-improvement.sh)          — UNTRUSTED toward the image-payload and
                                             instruction-context sinks; trusted only
                                             AFTER the human diff-and-bless at B1

S2: CLAUDE_HOME_SRC array + the staging    — nominally code-constant, but it lives in
    expression in install.sh                 install.sh, which is S1 and is in neither
                                             enforcement_files() nor live-verify-gate.sh
                                           — UNTRUSTED toward the payload-layout sink

S3: $DEST (~/.config/claude-devcontainer)  — host-only, in no bind mount
                                           — trusted for the build-context sink

S4: OPENROUTER_API_KEY (env)               — deploy-time — trusted for the auth sink

S5: --judge / --models / --max-usd argv    — invocation-time, operator-supplied
                                           — trusted for availability; UNTRUSTED for the
                                             cost and egress-destination sinks (the
                                             fail-closed pricing guard is the control)
```

What actually crosses in this diff: a **trusted-policy asset moved path** (repo root → `global-instructions/`), and the **payload staging expression changed shape** (`$STAGE/$item` → `$STAGE/$(basename "$item")`). No new external input is admitted and no sanitizer is weakened. The risk in this change is not injection — it is **name-matched controls that still name the old path**. Three guards classify by basename and survive the move unharmed (B2, B3-hook); two guards classify by repo-relative path or by a default root and do not (B4, B3-sweep). Findings 1 and 2 are those two.

---

## Findings

#### Gate 1d's critical-file protection no longer covers the global instructions file

**Severity:** Medium
**Location:** `scripts/self-improvement.sh:1172-1181` (unchanged by this diff; broken by the rename in `c56be81`)
**Boundary:** B4
**Move:** #5 (invert the access control model) · #1 (trust boundaries — the asset moved, the guard did not)
**Confidence:** High
**Legibility-target:** for-author

Gate 1d rejects a self-improvement branch that deletes any of three named critical files. The match is an exact shell `case` glob against repo-relative paths:

```
        # --- Gate 1d: Critical file protection ---
        if [ -z "$REJECT_REASON" ]; then
            for FILE in $DELETED_FILES; do
                case "$FILE" in
                    scripts/self-improvement.sh|docs/evaluation-rubric.md|CLAUDE.md)
```

`DELETED_FILES` is produced at `scripts/self-improvement.sh:1126` as `DELETED_FILES=$(git diff --name-only --diff-filter=D "main..$BRANCH")`, i.e. repo-relative paths. After the rename the deleted path is `global-instructions/CLAUDE.md`, which does not match the pattern `CLAUDE.md` — `case` globs have no implicit path-component semantics. The attack path this gate exists to close, per the boundary model the repo itself documents (an autonomous agent producing a branch that the loop merges), is now open for the single highest-value file in the set: an autonomous branch that deletes the global instruction set is merged with `critical_files: pass`. The other two entries are already directory-qualified and are unaffected.

**Recommendation:** add the new path to the `case` list. Prefer a `*/CLAUDE.md|CLAUDE.md)` pattern, or hoist the list into a `CRITICAL_FILES` array, so the next move of this file does not silently reopen the gate.

#### `claude_config_audit.py`'s default sweep roots no longer reach the repo's global instructions file, and the operator guide still says they do

**Severity:** Medium
**Location:** `scripts/claude_config_audit.py:201`; operator documentation at `guides/claude-config-security-checkup.md:61`
**Boundary:** B3
**Move:** #11 (enumerate bypasses) · #2 (implicit sanitization assumption — the scan is assumed to happen somewhere)
**Confidence:** Medium
**Legibility-target:** for-author

The auditor's whole purpose is to scan files the harness reads *as instructions* for injection / unicode-escape / bidi-override payloads. Its default roots are:

```
    roots = args.paths or [".claude", str(Path.home()/".claude"), "CLAUDE.md"]
```

The literal relative root resolved, when run from this repo's root, to the global instructions file. It no longer exists there. `iter_targets` (`scripts/claude_config_audit.py:140-161`) silently skips a missing root — `root.is_file()` is false and `os.walk` on a nonexistent path yields nothing, with no warning — so the sweep reports success over a set that no longer includes the file. The operator-facing guide still asserts the old coverage:

```
# Default roots: ./.claude, ~/.claude, ./CLAUDE.md
python3 ~/.claude/scripts/claude_config_audit.py
```

Confidence is Medium, not High, because coverage does **not** disappear everywhere: on a host where `~/.claude/CLAUDE.md` is the README's symlink into this repo, or inside cc-isolated where it links into `/opt/claude-workflows/`, the `~/.claude` root still walks to the same content (`iter_targets` passes `followlinks=True` and yields symlinked files found during the walk). The loss is specific to scanning a **repo checkout in place** — a fresh clone, a CI/host run before `install.sh`, a worktree, or any machine whose `~/.claude` points elsewhere — which is exactly the "review a branch produced by an autonomous session" case the guide names at `guides/claude-config-security-checkup.md:77`.

**Recommendation:** add the new path to the default `roots` list (keeping the bare filename so the default still works when the auditor is run from an arbitrary project), and update the `# Default roots:` comment in the guide in the same commit.

#### `basename` staging decouples the payload layout from the array a reviewer reads, with no test on the resulting layout

**Severity:** Low
**Location:** `devcontainer-config/install.sh:47-57`
**Boundary:** B1
**Move:** #12 (sweep every call site of the engaged primitive — path construction / `cp -r`) · #4 (TOCTOU-adjacent: the `-e` check and the `cp` use different path expressions)
**Confidence:** High
**Legibility-target:** for-author

```
CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)
STAGE="$SRC/claude-home"
rm -rf "$STAGE"
mkdir -p "$STAGE"
for item in "${CLAUDE_HOME_SRC[@]}"; do
  if [ -e "$REPO_ROOT/$item" ]; then
    cp -r "$REPO_ROOT/$item" "$STAGE/$(basename "$item")"
```

Before this change the staged path *was* the array entry, so the array was a readable spec of the payload. Now the source path and the staged path are different strings, and the array is no longer that spec: a future entry `anything/hooks` stages as `hooks` and lands at `/opt/claude-workflows/hooks`, which `link-claude-home.sh:47` symlinks into `~/.claude/hooks` — the HARD tier of `guard-trusted-writes.py`. Two concrete consequences, both silent:

- **Basename collision.** I executed the collision case against a fixture: with entries `hooks` and `evil/hooks`, `cp -r` does *not* overwrite — because `$STAGE/hooks` already exists it copies *inside*, producing `stage2/hooks/hooks/y.sh` alongside `stage2/hooks/x.sh`. The extra tree is then walked by `enforcement_files()` (`devcontainer-config/cc-isolated.sh:128`, `find claude-home \( -type f -o -type l \)`) and blessed as part of the manifest. A file-vs-file collision overwrites outright.
- **No layout assertion.** The only test touching this is `test/cc-isolated-functions.bats:420-427`, which greps the array *text* for the substrings `skills` and the filename. It asserts nothing about `$STAGE`, so the now-load-bearing invariant "every `CLAUDE_HOME_SRC` basename appears in `link-claude-home.sh`'s `ENTRIES`, and vice versa" is untested in both directions.

This is Low rather than Medium because the content gate still holds: `install.sh:73-77` diffs `$DEST/claude-home` against `$SRC/claude-home` before the y/N prompt, so a changed or duplicated payload is shown to the human. The cost here is review legibility of the array itself, not a violated property — with the exception of a first install, where `install.sh:83-86` prints `First install — $DEST does not exist yet.` and no diff at all.

**Recommendation:** stage explicitly rather than by derivation — an entry list of `source:dest` pairs, or a hard `[ -e "$STAGE/$(basename "$item")" ] && { echo "ERROR: basename collision"; exit 1; }` guard in the loop. Add a bats test that runs the staging loop against a fixture repo and asserts the resulting `$STAGE` listing equals `link-claude-home.sh`'s `ENTRIES`.

#### A missing payload source warns and continues, so a payload with no global instruction file can still be blessed

**Severity:** Low
**Location:** `devcontainer-config/install.sh:51-57`, consumed at `devcontainer-config/link-claude-home.sh:50-63`
**Boundary:** B1
**Move:** #3 (check the error path, not just the happy path)
**Confidence:** High
**Legibility-target:** for-author

```
  if [ -e "$REPO_ROOT/$item" ]; then
    cp -r "$REPO_ROOT/$item" "$STAGE/$(basename "$item")"
  else
    echo "WARNING: $REPO_ROOT/$item not found — omitted from the image payload." >&2
  fi
```

The failure mode is fail-open: a typo, a rename of `global-instructions/`, or a dangling symlink (`-e` follows links) drops the global instruction set from the image, the script continues to the `--bless` at `install.sh:114`, and `link-claude-home.sh:51`'s `[ -e "$SRC/$name" ] || continue` skips it again without comment. The session then runs with *no* global policy — no Debugging defaults, no Operating Modes, no routing table — while every gate downstream reports success. This is pre-existing, but the move makes it materially likelier to fire: the path is now one directory deep, so a future reorganisation of `global-instructions/` trips it where a repo-root filename would not have. The stderr `WARNING` also competes for attention with a full `diff -ru` dump on stdout immediately below it.

**Recommendation:** treat a missing `CLAUDE_HOME_SRC` entry as fatal (`exit 1`) rather than a warning — the payload is a security asset and a partial one should not reach a bless. If some entries are genuinely optional, mark them so explicitly in the array rather than making every entry optional by default.

#### `[Dependency change]` `--judge` default moved to an unconfirmed model slug, and the fail-closed pricing guard does not cover the judge

**Severity:** Low
**Location:** `scripts/cross-model-review.py:372-374`, guard at `:437-464`, request at `:255-276`
**Boundary:** B5
**Move:** #10 (review dependency changes — a pinned third-party model is a dependency) · #8 (what if there are a million of these)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

```
    # Pinned on purpose: changing the judge breaks score comparability with earlier runs.
    # Re-baseline deliberately and note the cutover in the run log when you move it.
    ap.add_argument("--judge", default="anthropic/claude-sonnet-5", help="pinned judge model for stage-2 matching")
```

Two gaps compose. First, per the supplied fact-check the slug could not be confirmed against OpenRouter's catalogue (no egress), so the default names an inference destination whose existence and provider routing are unverified — and this script's own `.gitignore` entries designate its outbound payloads a security concern ("whole-repo (or foreign-repo) content shipped to third-party APIs — never commit them (security finding A6)"). Second, the fail-closed cost guard enumerates only `args.models`:

```
        unpriced = [m for m in args.models if pricing.get(m, (0, 0)) == (0, 0)]
```

so `args.judge` is never priced and never counted toward `--max-usd`, while `judge_same` (`:332-343`) is called from a nested loop over finding pairs in `jaccard` (`:346-360`) — an unbounded call count. Each call is small (`"max_tokens": 4`), so the dollar exposure is modest; the exposure that matters is that the guard's stated property ("refusing to send" when a model cannot be priced) does not hold for the judge, and `api()` retries *any* exception three times (`:273-276`, `except Exception`), so a 400/404 on an unknown slug becomes three requests per pair rather than one fast abort.

Not exploitable by an external party — `--judge` is S5, operator-supplied at invocation — which is why this is Low rather than Medium; the harm is an unbudgeted, unverified-destination egress path rather than a crossing an attacker controls. Note the rest of the failure is fail-closed: with no key, `:544` degrades to stage-1-only; with a key and a bad slug, the exception propagates and the run dies rather than producing a silent zero-agreement score.

**Recommendation:** fold the judge into the unpriced check (`unpriced = [m for m in args.models + [args.judge] ...]`) and into the projection. Confirm the slug against `MODELS_URL` from a host with egress before the next run, and narrow `api()`'s retry to transport and 5xx errors so a 4xx aborts on the first attempt.

#### `install.sh` is the rebuild gate but sits outside both mechanical gates that protect the boundary

**Severity:** Informational
**Location:** `devcontainer-config/install.sh` (whole file); gates at `devcontainer-config/cc-isolated.sh:107-130` and `hooks/live-verify-gate.sh:57`
**Boundary:** B1
**Move:** #1 (trace the trust boundaries) · #5 (invert the access control model)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The fact-check confirms `install.sh` appears in neither `enforcement_files()` nor the live-verify gate's enforcement regex:

```
enforcement='^devcontainer-config/(Dockerfile|devcontainer\.json|init-firewall\.sh|cc-sni-proxy\.py|link-claude-home\.sh|cc-isolated\.sh|egress/)'
```

Yet `install.sh` is the script that assembles the manifest-hashed payload, prints the `diff -ru` the human reviews, *and* invokes `--bless` itself at line 114 after that human's `y`. It is S1 — agent-writable, by the deliberate design its own header describes. So the reviewer of a boundary change reads a diff generated by a file that the same class of actor could have edited, and a commit touching it carries no `Live-verified:` trailer requirement. This is pre-existing and I am not claiming a live exploit path; I raise it because **this diff is the first change to `install.sh`'s staging semantics**, which makes the exclusion newly load-bearing rather than dormant. The residual protection is real: `install.sh` runs on the host from the repo, and the human reads `git diff` of the repo before running it.

**Recommendation:** consider adding `install\.sh` to `live-verify-gate.sh`'s enforcement regex so a commit touching it must state its verification status, even though its output (not the script) is what the manifest hashes. Decide deliberately rather than by omission.

---

## Untested bypass candidates

Enumerated against the guards the moved asset sits behind (move #11); the candidates that were traced appear in the Primitive sweep and in Findings 1–2.

- **A sibling file created inside `global-instructions/`** (e.g. `global-instructions/notes.md`). Not traced through Claude Code's own instruction-discovery behavior — I read the repo's guards, not the harness. `guard-trusted-writes.py:62-68` would classify it `none` (no `skills|memories|commands|agents` segment, not a policy filename, no `.claude` segment), so a write to it is unguarded. Not filed as a finding because I did not establish that the harness loads it.
- **`git mv` of the whole `global-instructions/` directory via Bash.** `HARD_FRAG` at `guard-trusted-writes.py:78-80` requires the policy filename to appear in the command text; a directory-level `git mv` contains none, and `WRITE_PRIMITIVE` at `:71-77` has no `git mv` alternative. Not traced to a working end-to-end sequence, so listed rather than filed.
- **A symlink placed at the new path pointing outside the repo.** `cp -r` preserves links (the `enforcement_files()` comment at `cc-isolated.sh:125-127` says so, and the manifest hashes link target text), and `Dockerfile:409`'s `COPY claude-home/ /opt/claude-workflows/` would carry it. Not exercised; the manifest's link-target hashing is the claimed mitigation and I did not run it.

---

## Primitive sweep

Engaged primitive: **path construction feeding a recursive file copy into the image payload** (`cp -r` with a derived destination). Every occurrence in the changed scope plus the consumers it feeds:

```
Primitive: cp -r / cp -f with a constructed destination path
| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `devcontainer-config/install.sh:53` | S2 CLAUDE_HOME_SRC entry (basename-derived) | `[ -e ]` existence check only; content shown by the `diff -ru` at :73-77 | Findings 3 and 4 (silent collision-nesting; fail-open on missing source) |
| `devcontainer-config/install.sh:105` | S2 PAYLOAD array (literal names, no basename) | `rm -rf "${DEST:?}/$item"` first; `${DEST:?}` guards an empty DEST | cleared — destination is the literal array entry, no derivation |
| `devcontainer-config/link-claude-home.sh:68` | S3 `$SRC/.manifest` from the root-owned 0555 image | `[ -f ]`; errors swallowed by `|| true` | cleared — provenance stamp only, read by health-check, not an instruction sink |
```

Adjacent primitive touched by the same flow, disposed for completeness: symlink creation at `link-claude-home.sh:54` and `:60` is guarded by the non-symlink check at `:56-58` and is unchanged by this diff — cleared, not analyzed further.

---

## Endorsement Claims

- **Claim:** `guard-trusted-writes.py` classifies the moved file into the same tiers after the move as before it — `soft` for Edit/Write/MultiEdit, `hard` for Bash.
  **Location:** `hooks/guard-trusted-writes.py:41-68` (file tools), `:78-92` (Bash)
  **Evidence:** executed
  **Verified:** read `classify_path` — line 64's policy-filename test is basename-only, so both the old and new paths return `soft`; line 55's HARD test additionally requires `.claude` in the path or `parent == HOME`, which neither satisfies. For the Bash path, `HARD_FRAG`'s `(^|[\s\"'=~/])CLAUDE\.md` matches the new path via its leading `/`. Verified *live*: two Bash commands of mine in this session (a staging simulation and the attempt to write this report by heredoc) were both denied by this hook with `Bash write to a protected policy file`.
  **Not verified:** whether the corresponding `permissions.deny` rules at `hooks/wiring.json:124-127` (`Edit({{CLAUDE_DIR}}/CLAUDE.md)`, `Edit(~/CLAUDE.md)`) ever covered a repo-path copy — they name `~/.claude` and `~`, not a repo path, so the file-tool HARD tier was likely never the control for either path. I did not run Claude Code's rule matcher.
  **route: code-fact-check**

- **Claim:** `hooks/claude-config-audit.sh`'s PostToolUse policy-file gate still fires for the moved file, so the *write* path of B3 is unchanged.
  **Location:** `hooks/claude-config-audit.sh:75-104`
  **Evidence:** read-static
  **Verified:** read `is_policy_file` — it takes `name=$(basename "$path")` at line 77 and matches the policy filename at line 83 before any directory test, so the enclosing directory is not consulted for this name.
  **Not verified:** the hook's actual invocation with a real PostToolUse payload naming the new path; I read the gate, not a live hook run. `test/hooks/claude-config-audit.bats:107-108` exercises the gate with a bare filename, not a nested one.
  **route: code-fact-check**

- **Claim:** the payload path hashed by `enforcement_files()` is unchanged by this diff, because the walk is over `claude-home` by path and the staged basename is unchanged.
  **Location:** `devcontainer-config/cc-isolated.sh:128`; staging at `devcontainer-config/install.sh:53`
  **Evidence:** executed
  **Verified:** ran the staging loop against a fixture with entries `global-instructions/<the file>` and `hooks`; the resulting stage listed the policy file and `hooks/x.sh` at the stage root, matching `link-claude-home.sh:47`'s `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)`.
  **Not verified:** the real `$DEST` manifest before and after an actual `install.sh` run — no Docker and no installed config dir in this sandbox, so I did not diff a real blessed manifest across the change.
  **route: code-fact-check**

- **Claim:** `scripts/health-check.sh`'s three MD-comparison checks now read the moved path through a single `GLOBAL_MD` variable, with no bare policy filename left in an executable position in that file.
  **Location:** `scripts/health-check.sh:35`, `:203`, `:235`, `:868`, `:944-978`
  **Evidence:** read-static
  **Verified:** grepped the file for `CLAUDE`; every remaining hit is inside a comment (lines 13, 14, 25, 187, 192, 843-847, 922-932, 963) or is the unrelated `CLAUDE_CONFIG_DIR` env var (lines 524, 557, 567).
  **Not verified:** whether the checks *pass* on the moved file — I did not run `health-check.sh`. The fact-check records six pre-existing failures in this suite, which I did not re-derive.

- **Claim (scoped, no rubric weight):** this diff admits no new external input and modifies no sanitizer, matcher, or allowlist. The three orchestrator-skill edits, the code-review SKILL.md split, and the doc/test churn are prose and path-label changes; the `test/skills/*.bats` changes adjust assertion anchors, not guards.
  **Location:** `skills/code-review/SKILL.md`, `skills/draft-review/SKILL.md`, `skills/matrix-analysis/SKILL.md`, `skills/code-review/references/*`, `test/skills/code-review-*.bats`
  **Evidence:** read-static
  **Verified:** read the `--stat` and every security-bearing hunk; the four `.bats` files change 12–16 lines each, consistent with anchor adjustment for the file split.
  **Not verified:** a line-by-line read of the 765-line `SKILL.md` reduction and the three new `references/` files for smuggled instruction content — these are trusted-policy files by this repo's own definition, and I did not run `claude_config_audit.py` over them. Finding 2 is precisely about that sweep's coverage.

---

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Gate 1d no longer protects the moved global instructions file | Medium | B4 | `scripts/self-improvement.sh:1172-1181` | High |
| 2 | Config-audit default sweep no longer reaches the file; guide still claims it does | Medium | B3 | `scripts/claude_config_audit.py:201`, `guides/claude-config-security-checkup.md:61` | Medium |
| 3 | `basename` staging decouples payload layout from the array; silent collision, untested layout | Low | B1 | `devcontainer-config/install.sh:47-57` | High |
| 4 | Missing payload source warns and still blesses | Low | B1 | `devcontainer-config/install.sh:51-57` | High |
| 5 | `[Dependency change]` unconfirmed `--judge` slug outside the fail-closed pricing guard | Low | B5 | `scripts/cross-model-review.py:372-374`, `:437-464` | Medium |
| 6 | `install.sh` is the rebuild gate but outside `enforcement_files()` and the live-verify gate | Informational | B1 | `devcontainer-config/install.sh`, `hooks/live-verify-gate.sh:57` | High |

---

## Overall Assessment

The move itself is sound and the payload identity is preserved — the staged basename is unchanged, `link-claude-home.sh` and the manifest walk are untouched, and the two guards that matter most (the `guard-trusted-writes.py` tiers and the PostToolUse audit gate) classify by basename and therefore follow the file automatically. The security cost of this change is not in what it added but in **what it left pointing at the old path**: two controls classify by repo-relative path or by a hardcoded default root, and both silently stopped covering the repo's single highest-value trusted-policy file. Neither fails loudly — Gate 1d records `critical_files: pass`, and the audit sweep prints a scan count over a set that quietly shrank by one. That is the shape of a control that dies in a rename, and it is the single most important thing to address: two one-line additions (Finding 1's `case` entry, Finding 2's `roots` entry) close both, in place, with no architectural change. The `basename` indirection (Finding 3) is a legibility regression rather than a violated property — the `diff -ru` content gate still holds — but it converts `CLAUDE_HOME_SRC` from a spec of the payload into a source list whose destinations must be inferred, which is a poor property for the one array that determines what lands root-owned at `/opt/claude-workflows`. Findings 4 and 6 are pre-existing shapes the diff makes newly load-bearing rather than defects it introduces.

Because three Endorsement Claims carry `route: code-fact-check` and the Untested bypass candidates section is non-empty: **no findings within the code paths read; endorsement claims pending execution verification.** The review is also explicitly partial in one respect named in the last endorsement — the ~1,400 lines of new and moved skill/reference prose were not audited for instruction-smuggling content, which is exactly the gap Finding 2 identifies in the tooling.

---

## Goal-Alignment Note

**Answered.** All four surfaces the brief prioritised were reached: (1) `install.sh`'s `basename` staging — traced to `$STAGE`, the `diff -ru` gate, the Dockerfile `COPY`, the 0555 hardening, `link-claude-home.sh`'s `ENTRIES`, and `enforcement_files()`'s manifest walk; collision behavior executed against a fixture (Findings 3, 4). (2) Whether the move weakens a control — the named guard-hunt produced the diff's two Medium findings (1, 2) and cleared the two basename-classified guards. (3) `enforcement_files()` / the live-verify gate — nothing this diff changes is hashed or gated, and the fact that `install.sh` itself is in neither is Finding 6. (4) `--judge` fail-closed handling — Finding 5.

**Out of scope (stated, not silently dropped).** I did not audit the ~1,400 lines of new/moved skill and reference prose for smuggled instructions, and I did not run `claude_config_audit.py` over them; that is called out in the final Endorsement Claim. I also did not re-verify anything in the supplied fact-check.

**Escalate:** nothing. No HALT pattern matched.

**Questions I would have asked:**
1. Is Gate 1d's file list meant to be a *path* list or a *name* list? The answer decides whether Finding 1's fix is one more entry or a pattern (`*/CLAUDE.md`), and the same question governs how the next rename behaves.
2. Was `install.sh`'s exclusion from `enforcement_files()` a deliberate call (its output is hashed, so the script need not be) or an omission? Finding 6 is Informational on the assumption it was deliberate.
3. Is `anthropic/claude-sonnet-5` a slug confirmed on a host with egress, or a forward-looking guess? If the latter, the next cross-model run aborts three retries deep rather than at the guard.
