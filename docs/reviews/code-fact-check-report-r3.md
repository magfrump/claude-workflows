Commit: 654c0ed

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** `git -C /workspace diff e8d5fa1..answers-2026-09-20` (32 commits, 50 files) — claims in `hooks/guard-trusted-writes.py`, `scripts/questions.sh`, `scripts/self-improvement.sh`, `scripts/archive-working-docs.sh`, `scripts/lib/si-functions.sh`, `scripts/lib/si-morning-summary.sh`, `scripts/health-check.sh`, `scripts/lite-review.py`, `global-instructions/CLAUDE.md`, `skills/code-review/references/{rubric,override-log}.md`, `skills/fact-check/SKILL.md`, `skills/performance-reviewer/SKILL.md`, `workflows/{pr-prep,review-fix-loop}.md`, and commit messages 4c7a2bb, a45f4a9, 0ccbdb8
**Checked:** 2026-09-21
**Total claims checked:** 34
**Summary:** 23 verified, 5 mostly accurate, 0 stale, 5 incorrect, 1 unverifiable

Pre-run check against `docs/reviews/hallucination-patterns.md`: the logged patterns are of the
class "a specific measured value quoted from an artifact that does not contain it". None of the
claims below matches that class. Claim 20 (a `P1` severity level attributed to `test-strategy`)
is a new fabricated-vocabulary pattern; see the note at the end.

Execution provenance: all executed claims ran on 2026-09-21 between 19:27 and 19:36 -07:00 in
this sandbox, with `HOME=/home/node` and `CLAUDE_CONFIG_DIR=/home/node/.claude` unless the claim
says otherwise. Raw output was captured under the session scratchpad
`/tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/fc3/` (abbreviated
`$FC3/` below). Per the brief, nothing was written to `docs/reviews/execution-logs/`. The probes
import `hooks/guard-trusted-writes.py` from the working tree. They do not use the installed copy
under `/opt/claude-workflows`, which is an older version and still hard-denies bare `CLAUDE.md`.
That older copy blocked three of this reviewer's own read-only greps, which is Q-035's symptom
showing up live.

---

## Claim 1: "`~/.claude/scripts/questions.sh` acts on the `docs/working/` of the repo you run it from. … `check` is a gate only in claude-workflows itself (`scripts/health-check.sh`); elsewhere nothing runs it for you."

**Location:** `global-instructions/CLAUDE.md:281`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers resolution from a subdirectory, a non-git dir, a linked worktree and this repo, and that health-check pins gate 14 to this repo's files. Does not establish behaviour inside a `.git` dir (Claim 16b) or through a dangling symlink (Claim 17).
**Legibility-target:** for-orchestrator-synthesis

The resolution line is:

```bash
# scripts/questions.sh:55
PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"
```

Running `bash /workspace/scripts/questions.sh init` from `r1/a/b` of a fresh repo created
`r1/docs/working/questions.md` and `questions-archive.md` at the toplevel. From a linked
worktree `wt` it created `wt/docs/working/…`. From `/workspace/scripts`, `next-id` printed
`Q-048` against this repo's docs. Gate 14 pins its own files:

```bash
# scripts/health-check.sh:1024-1026
    if out="$(QUESTIONS_LIVE="${QUESTIONS_LIVE:-$REPO_ROOT/docs/working/questions.md}" \
              QUESTIONS_ARCHIVE="${QUESTIONS_ARCHIVE:-$REPO_ROOT/docs/working/questions-archive.md}" \
              "$REPO_ROOT/scripts/questions.sh" check 2>&1)"; then
```
(excerpt ends :1026; enclosing check_questions_doc() continues to its fail branch — read)

Command: a scripted sequence of `bash /workspace/scripts/questions.sh {init,check,next-id}` in temp repos · cwd `$FC3/qs` · exit 0 for every step · 2026-09-21T19:28:55-07:00.

**Evidence:** `scripts/questions.sh:55-57`, `scripts/health-check.sh:1018-1030`, `$FC3/questions-init.out`

---

## Claim 2a: "HARD = the GLOBAL config dir only … (the config dir is $CLAUDE_CONFIG_DIR when set, else ~/.claude — the same {{CLAUDE_DIR}} hooks/wiring.json substitutes)" — when `CLAUDE_CONFIG_DIR` is unset or equals `~/.claude`

**Location:** `hooks/guard-trusted-writes.py:10-12`
**Type:** Configuration / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case where the config dir is `~/.claude`, which is this sandbox's setting. Does not cover a `CLAUDE_CONFIG_DIR` pointing somewhere else (Claim 2b).
**Legibility-target:** for-orchestrator-synthesis

In that case `GLOBAL_DIRS` holds only `~/.claude`. The probe printed `GLOBAL_DIRS [PosixPath('/home/node/.claude'), …×4]`. The linker substitutes the same directory:

```bash
# devcontainer-config/link-claude-home.sh:36
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
```

**Evidence:** `hooks/guard-trusted-writes.py:56-69`, `devcontainer-config/link-claude-home.sh:36,137`, `$FC3/probe1.out`

---

## Claim 2b: the same sentence, when `CLAUDE_CONFIG_DIR` points to a directory other than `~/.claude`

**Location:** `hooks/guard-trusted-writes.py:10-12`
**Type:** Configuration / Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the hook classifies as HARD versus what the merged deny rules cover. Does not establish whether a non-default `~/.claude` is ever read by Claude Code in such a setup, which sets the practical impact (likely small).
**Legibility-target:** for-author

The docstring says the config dir is `$CLAUDE_CONFIG_DIR` *instead of* `~/.claude`. The code always keeps `~/.claude` and only *adds* the env dir:

```python
# hooks/guard-trusted-writes.py:56-61
def _global_dirs():
    """The global config dir(s), as given and resolved. HARD applies only here."""
    dirs = [HOME / ".claude"]
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    if cfg:
        dirs.append(Path(os.path.expanduser(cfg)))
```
(excerpt ends :61; enclosing _global_dirs() continues to :67 — read)

With `CLAUDE_CONFIG_DIR=$FC3/cfgA`, `~/.claude/settings.json -> hard` (so the hook defers). But
`wiring.json`'s deny rules are written against `{{CLAUDE_DIR}}` = `cfgA` only
(`"Edit({{CLAUDE_DIR}}/settings*.json)"`). That leaves `~/.claude/settings.json` deferred with no
deny rule behind it, which is the no-gate state the docstring's own Q-026 rationale (:19-21) says
to avoid. There are two smaller divergences. The hook runs `expanduser` on the env value and the
linker does not. A relative `CLAUDE_CONFIG_DIR` (`cfgrel`) is kept unresolved in `GLOBAL_DIRS`, so
any relative `cfgrel/settings.json` counts as HARD from any cwd (probe: `cfgrel/settings.json -> hard`).

Command: `CLAUDE_CONFIG_DIR=$FC3/cfgA python3 probe2.py cfg` and `(cd wd && CLAUDE_CONFIG_DIR=cfgrel python3 probe2.py cfg)` · cwd `$FC3` · exit 0 · 2026-09-21T19:35:5x-07:00.

**Evidence:** `hooks/guard-trusted-writes.py:56-78`, `hooks/wiring.json` (permissions.deny), `devcontainer-config/link-claude-home.sh:36`, `$FC3/probe2.out`

---

## Claim 3: "this hook must NEVER 'ask' on a HARD path — it DEFERS (lets the deny rule block the file tools) and, for the Bash path that deny rules don't cover, returns 'deny' outright."

**Location:** `hooks/guard-trusted-writes.py:13-17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `main()`'s dispatch, plus a probe of every deny-covered path shape (`~/CLAUDE.md`, `~/.claude/{CLAUDE.md,settings*.json,hooks/**}`, including the `//`, `/./` and `..` spellings and a project `.claude` symlinked to the global dir). All of them classify `hard` and so defer. Does not establish that Claude Code's deny matcher itself resolves symlinks or `..`, which decides whether the deferred write is actually blocked.
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:176-181
        tier = classify_path(fp)
        if tier == "hard":
            # DO NOT "ask": that would override your permissions.deny (#39344).
            # Defer and let the deny rule block it.
            defer()
        if tier == "soft" and tainted:
```
(excerpt ends :181; enclosing main() continues to :186 — read)

The probe output includes `~/.claude//settings.json -> hard`, `~/.claude/./hooks/x -> hard` and
`~/.claude/../CLAUDE.md -> hard`. With the project dir `fakehome/proj/.claude` symlinked to
`fakehome/.claude`, the resolved path gave `hard` for settings, hooks and CLAUDE.md. Case
variants (`~/.claude/SETTINGS.JSON`, `~/.claude/Hooks/x`) classify `soft`. On Linux those are
distinct files that no deny glob covers, so an `ask` on them overrides nothing. Bash HARD emits
`deny` (`:162-166`). Command: `python3 probe.py` and `probe2.py symlink` · exit 0 · 2026-09-21T19:36:10-07:00.

**Evidence:** `hooks/guard-trusted-writes.py:80-109,159-186`, `$FC3/probe1.out`, `$FC3/probe2.out`

---

## Claim 4: "SOFT = … and a PROJECT's own .claude/ (settings*.json, hooks/**; Q-026) … Gated to 'ask' only when the session is web-tainted."

**Location:** `hooks/guard-trusted-writes.py:18-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file tools' classification of non-global `.claude/` paths and the tainted→ask branch. Does not establish taint-file creation (outside this diff).
**Legibility-target:** for-orchestrator-synthesis

The probe gave `/workspace/.claude/settings.json -> soft`, `/workspace/.claude/hooks/a.py -> soft`
and `.claude/hooks/a -> soft`. Before this change, `/workspace/.claude/settings.local.json` was
`hard` and is now `soft` (`$FC3/probe3.out`). The fallthrough is:

```python
# hooks/guard-trusted-writes.py:107-108
        if ".claude" in low:
            return "soft"
```

`bats test/hooks/guard-trusted-writes.bats` → 40/40 ok, exit 0, 2026-09-21T19:28:01-07:00.

**Evidence:** `hooks/guard-trusted-writes.py:100-109,181-183`, `$FC3/probe1.out`, `$FC3/probe3.out`, `$FC3/guard-bats.out`

---

## Claim 5a: "and CLAUDE.md only when qualified as global: `~/`, `$HOME/`, `${HOME}/`, the literal home path, or `global-instructions/CLAUDE.md`" — read as a description of the regex's literal spellings

**Location:** `hooks/guard-trusted-writes.py:26-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exactly the five listed literal spellings, directly followed by `/CLAUDE.md`. Does not establish that other shell spellings of the same global file are HARD (Claim 5b).
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:123-129
_GLOBAL_PREFIXES = [r"~", r"\$HOME", r"\$\{HOME\}", r"global-instructions"]
if str(HOME).rstrip("/"):         # HOME="/" would make this prefix empty and match any "/CLAUDE.md"
    _GLOBAL_PREFIXES.append(re.escape(str(HOME).rstrip("/")))
HARD_FRAG = re.compile(
    r"\.claude/hooks(/|\b)|\.claude/settings|\.claude/CLAUDE\.md|managed-settings"
    r"|(?:" + "|".join(_GLOBAL_PREFIXES) + r")/CLAUDE\.md",
    re.I)
```

`echo x > ~/CLAUDE.md`, `$HOME/CLAUDE.md`, `${HOME}/CLAUDE.md`, `"${HOME}/CLAUDE.md"`,
`/home/node/CLAUDE.md` and `global-instructions/CLAUDE.md` all return `hard`.

**Evidence:** `hooks/guard-trusted-writes.py:121-142`, `$FC3/probe1.out`

---

## Claim 5b: the same sentence, read as "a Bash write that names the global CLAUDE.md is HARD"

**Location:** `hooks/guard-trusted-writes.py:24-29` (also commit 4c7a2bb: "HARD_FRAG now matches CLAUDE.md only when qualified as the global file")
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers common shell spellings of `~/CLAUDE.md` and `global-instructions/CLAUDE.md` that the prefix alternation does not match. Each of these was `hard` before this diff (e8d5fa1) and is `soft` now. Soft means `ask` when tainted and no opinion otherwise. These are beyond the accepted `cd ~ && … > CLAUDE.md` residual. Does not establish whether any other layer (sandbox) blocks these writes.
**Legibility-target:** for-author

The alternation requires the prefix to sit immediately before `/CLAUDE.md` with no quote, extra
slash, dot segment or parameter operator in between. Old vs new classification (`$FC3/probe3.out`, `$FC3/probe1.out`):

| Command | old | new |
|---|---|---|
| `echo x > "$HOME"/CLAUDE.md` | hard | soft |
| `echo x > "$HOME/"CLAUDE.md` | — | soft |
| `echo x > ~//CLAUDE.md` / `~/./CLAUDE.md` | hard | soft |
| `echo x > ~/"CLAUDE.md"` | hard | soft |
| `echo x > ${HOME:-}/CLAUDE.md` / `${HOME%/}/CLAUDE.md` | hard | soft |
| `echo x > /home/node//CLAUDE.md` | hard | soft |
| `echo x > $HOME/.claude/../CLAUDE.md` | — | soft |
| `echo x > ~node/CLAUDE.md`, `$(echo ~)/CLAUDE.md`, `H=~; … $H/CLAUDE.md` | — | soft |
| `echo x > ./global-instructions//CLAUDE.md`, `cp f global-instructions/./CLAUDE.md` | — | soft |

`"$HOME"/CLAUDE.md` is the idiomatic quoted spelling, so the tier drops for ordinary commands,
not only for crafted ones. For comparison, `~/CLAUDE".md"` and `~/CLAUDE\.md` return `None` both
before and after this diff.

Command: `python3 $FC3/probe.py` and `python3 $FC3/probe3.py` · cwd `/workspace` · exit 0 · 2026-09-21T19:36:10-07:00.

**Evidence:** `hooks/guard-trusted-writes.py:123-142`, `git show e8d5fa1:hooks/guard-trusted-writes.py` (old `HARD_FRAG`), `$FC3/probe1.out`, `$FC3/probe3.out`

---

## Claim 6: "HARD = any `.claude/hooks`, `.claude/settings`, `.claude/CLAUDE.md` fragment (global or project — the text doesn't say which), managed-settings"

**Location:** `hooks/guard-trusted-writes.py:25-26`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers literal-fragment matching and its normalization gaps. Does not establish whether those gaps existed before this diff for the CLAUDE.md fragment (they did for the settings and hooks fragments, whose regex is unchanged).
**Legibility-target:** for-author

The fragments are matched only as literal text. Spellings of the same targets that don't contain
the literal fragment return `None`, meaning not even SOFT:
`echo x > ~/.claude//settings.json`, `~/.claude/./settings.json`, `~/.claude/.//hooks/x`,
`~/".claude"/settings.json`, `~/.claude/"hooks"/x` and `cd ~/.claude && echo x > settings.json`
all return `None` (`$FC3/probe1.out`). A precise version would say "any command text containing
the literal fragment". The settings and hooks alternatives are unchanged from e8d5fa1, so this
is a pre-existing gap sitting under a rewritten docstring.

**Evidence:** `hooks/guard-trusted-writes.py:126-129`, `$FC3/probe1.out`

---

## Claim 7: "SOFT = a bare/project `CLAUDE.md` (Q-035) — matching the Edit/Write tier, so a heredoc or commit message that merely names the file is no longer denied."

**Location:** `hooks/guard-trusted-writes.py:30-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the heredoc, `rg -n install CLAUDE.md` and `git commit -m "… CLAUDE.md"` cases. They are now `soft` (ask only when tainted) or `None`. Does not establish tainted-session UX.
**Legibility-target:** for-orchestrator-synthesis

`cat > msg.txt <<EOF\nsee CLAUDE.md\nEOF` gave old `hard` → new `soft`. `rg -n install CLAUDE.md`
gave old `hard` → new `soft`. `git commit -m "update CLAUDE.md"` → `None`. The `SOFT_FRAG` alternative is:

```python
# hooks/guard-trusted-writes.py:130-132
SOFT_FRAG = re.compile(
    r"\.claude/(skills|memories|commands|agents)"
    r"|(^|[\s\"'=/])(AGENTS|CLAUDE|CLAUDE\.local)\.md|\.mdc(\b|$)", re.I)
```

**Evidence:** `hooks/guard-trusted-writes.py:130-142`, `$FC3/probe3.out`, `$FC3/probe1.out`

---

## Claim 8: "HOME="/" would make this prefix empty and match any "/CLAUDE.md""

**Location:** `hooks/guard-trusted-writes.py:124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `HOME=/` (the literal-home prefix is skipped, and a counterfactual empty prefix does match `/tmp/proj/CLAUDE.md`). Does not establish `HOME=""`, where `Path.home()` falls back to the passwd entry.
**Legibility-target:** for-orchestrator-synthesis

With `HOME=/`, `_GLOBAL_PREFIXES` printed without a literal-home entry,
`echo x > /tmp/proj/CLAUDE.md -> soft` and `~/CLAUDE.md -> hard`. Rebuilding the regex with an
added `""` alternative gave `counterfactual empty-prefix matches /tmp/proj/CLAUDE.md: True`.
Command: `HOME=/ python3 probe2.py homeroot` · exit 0.

**Evidence:** `hooks/guard-trusted-writes.py:123-125`, `$FC3/probe2.out`

---

## Claim 9: "with an optional prefix (defaults to the run id in docs/working/si-run-id.txt, else today's date …)" and ":39-42 Falls back to today's date when the file is absent or its content is unusable."

**Location:** `scripts/archive-working-docs.sh:7-8,38-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default, the explicit override and the invalid-content fallback (`../../evil`). Does not establish behaviour when run from outside the repo root (`WORKING_DIR` is the relative `docs/working`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/archive-working-docs.sh:43-49
if [ -z "$PREFIX" ] && [ -f "$WORKING_DIR/si-run-id.txt" ]; then
  RUN_ID=$(head -n1 "$WORKING_DIR/si-run-id.txt")
  if [[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
    PREFIX="$RUN_ID"
  fi
fi
PREFIX="${PREFIX:-$(date +%Y-%m-%d)}"
```

`bats test/scripts/archive-working-docs.bats` (with three other SI suites) → 84 ok, exit 0, 2026-09-21T19:3x.

**Evidence:** `scripts/archive-working-docs.sh:37-49,95-125`, `test/scripts/archive-working-docs.bats:164-190`, `$FC3/si-bats.out`

---

## Claim 10: Gate 5 "runs … fast first and slow second … if it is red, the slow set is not run at all … a health-check that sees that variable skips this gate (with a warning, never a pass)."

**Location:** `scripts/health-check.sh:345-367` (also `:20-26` and `:56`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ordering, fast-red blocking, slow-red failing and the skip-warns path (stub runner). Does not establish the real suites' wall-clock time or that the full real suite is green.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/health-check.sh (check_bats, after the skip/bats-present guards)
    if ! HEALTH_CHECK_SKIP_BATS=1 "$runner" --fast; then
        fail "Fast BATS suites failed — slow suites not run (fix fast first)"
        return
    fi
    pass "Fast BATS suites passed"
```
(excerpt ends inside check_bats(); the function continues with the `--slow` branch to its closing brace — read)

`bats -f "gate 5" test/scripts/health-check.bats` → 4/4 ok, exit 0, 2026-09-21T19:29-19:31.

**Evidence:** `scripts/health-check.sh:345-391`, `test/scripts/health-check.bats:147-210`, `$FC3/hc-bats.out`

---

## Claim 11: "a green health-check said nothing about the ~40 suites under test/ and test/scripts/ (link-claude-home-wiring.bats among them). Report gating (*-format/*-eval …) is owned by run-tests.sh" and ":533-536 … link-claude-home-wiring.bats, which check 5 runs (it is a slow suite …)"

**Location:** `scripts/health-check.sh:350-354,533-536`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the suite count, the slow tag and ownership of report gating. Does not establish that every suite passes.
**Legibility-target:** for-orchestrator-synthesis

`ls test/*.bats test/scripts/*.bats | wc -l` → 44. `test/link-claude-home-wiring.bats:2` reads
`# @category slow`. `scripts/run-tests.sh:80-110` holds the `*-format.bats|*-eval.bats` skip,
and `:63` discovers every `*.bats` under `$TEST_DIR`.

**Evidence:** `scripts/run-tests.sh:43-115`, `test/link-claude-home-wiring.bats:2`, `test/scripts/health-check.bats:2`

---

## Claim 12: "old rows keep an absent cell, which readers treat as 'unknown run' and resolve newest-first"

**Location:** `scripts/lib/si-functions.sh:471-475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_summary_deferred_evaluation` → `_pick_col` → `_find_tasks_file`/`_days_since_round` with an empty run. Does not establish other readers of the hypothesis log outside `si-morning-summary.sh`.
**Legibility-target:** for-orchestrator-synthesis

An old row has 11 cells, and `IFS='|' read -ra` drops the trailing empty field, so
`_pick_col fields "$run_col"` returns `""` via `printf '%s' "${arr_ref[$((col-1))]:-}"`
(`si-morning-summary.sh:1519`). With an empty run, `_find_tasks_file` skips the run-scoped block
(`if [ -n "$run" ]`) and uses the newest-first list (`:1180-1186`). The four SI suites pass
(`$FC3/si-bats.out`, 84 ok), including the "old rows fallback" cases.

**Evidence:** `scripts/lib/si-morning-summary.sh:970-1030,1170-1188,1497-1520`, `$FC3/si-bats.out`

---

## Claim 13a: "Appends ' Run |' to the header row … Data rows are untouched. No-op when the header already has a Run cell" and "Exact-cell match, so 'Checked at Round' never counts as 'Run'."

**Location:** `scripts/lib/si-functions.sh:542-552`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers row content, idempotence (identical md5 on a second run) and a header with only `Checked at Round`. Does not establish CRLF logs (`sub(/[ \t]*$/,"")` does not strip `\r`).
**Legibility-target:** for-orchestrator-synthesis

A second migration kept md5 `5c07376f…` unchanged. The data row `| 1 | t1 | the Round is a Run | … | | | |`
came through byte-identical. `| Round | Checked at Round |` gained ` Run |`.
Command: `bash $FC3/mig.sh` · exit 0 · 2026-09-21T19:32:17-07:00.

**Evidence:** `scripts/lib/si-functions.sh:547-568`, `$FC3/migrate.out`

---

## Claim 13b: "No-op when … no header is found."

**Location:** `scripts/lib/si-functions.sh:545`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers file identity and mode when no header exists, and the mode after a real migration. Does not establish whether any reader depends on the log's mode.
**Legibility-target:** for-author

When no header is found, the check awk exits non-zero (`END { exit !found }`), so the rewrite runs:

```bash
# scripts/lib/si-functions.sh (tail of _migrate_hypothesis_log_run_column)
    local tmp
    tmp=$(mktemp "${log_file}.XXXXXX") || return 1
```
(excerpt ends before the awk rewrite and `mv "$tmp" "$log_file"` that close the function — read)

A header-less `nohdr.md` (mode 644, inode 402364) came back with the same content but inode
402298 and mode `-rw-------`. A real migration also leaves `old.md` at `-rw-------`, because
`mktemp` creates 0600 files and `mv` carries that mode over.

**Evidence:** `scripts/lib/si-functions.sh:547-568`, `$FC3/migrate.out`

---

## Claim 14: "_live_run_matches … True when the run id is empty, the file is absent …, or the ids match" and "_find_tasks_file: With a run id … tries that run's archived copy first, then the live file when the live working dir belongs to that run … fall back to the newest-first scan … the first candidate that actually contains task id $2 wins."

**Location:** `scripts/lib/si-morning-summary.sh:1144-1168`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers candidate ordering and the id-containment filter. Does not establish that a fallback pick belongs to the row's run (it may not; the comment says so).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/si-morning-summary.sh:1180-1186
    done < <(if [ -n "$run" ]; then
                 printf '%s\n' "$working_dir/archive/${run}-tasks-round-$round.json"
                 _live_run_matches "$working_dir" "$run" \
                     && printf '%s\n' "$working_dir/tasks-round-$round.json"
             fi
             printf '%s\n' "$working_dir/tasks-round-$round.json"
             _archived_newest_first "$working_dir/archive" "tasks-round-$round.json")
```

**Evidence:** `scripts/lib/si-morning-summary.sh:1149-1188`, `$FC3/si-bats.out`

---

## Claim 15: "Verified 2026-08-15 - a --bare call on a subscription-only machine prints 'Not logged in' and still exits 0, so it fails silently."

**Location:** `scripts/lite-review.py:17-23`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that the script omits `--bare` and parses the JSON envelope rather than the exit code (`:157-173`). Does not establish the CLI's `--bare` auth behaviour.
**Legibility-target:** for-orchestrator-synthesis

Execution was required but blocked: the sandbox has no network egress, and the claim is about
the external `claude` CLI's auth path. The argv is
`"claude", "-p", "--model", model, "--output-format", "json", …` with no `--bare`
(`scripts/lite-review.py:157-164`). The project's memory note "CC --bare blocks all subscription
auth" is consistent with the claim but is not execution evidence.

**Evidence:** `scripts/lite-review.py:13-27,153-173`

---

## Claim 16a: "Which files: the docs/working/ of the git repo you run it FROM (the toplevel of $PWD …) … run from this repo, it resolves to this repo's docs/working/ as before. QUESTIONS_LIVE / QUESTIONS_ARCHIVE override either path."

**Location:** `scripts/questions.sh:35-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers subdirectory, worktree, this-repo and override cases. For submodules, `--show-toplevel` returns the submodule root (inferred, not run).
**Legibility-target:** for-orchestrator-synthesis

Override run: `QUESTIONS_LIVE=$FC3/qs/ov/live.md QUESTIONS_ARCHIVE=… init` created exactly those two
files. Other cases are as in Claim 1. `bats test/questions-doc.bats` → 18/18 ok, exit 0.

**Evidence:** `scripts/questions.sh:55-57`, `$FC3/questions-init.out`, `$FC3/qd-bats.out`

---

## Claim 16b: "($PWD itself outside a git repo)"

**Location:** `scripts/questions.sh:35-36`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `.git`-dir case. Does not establish bare repos.
**Legibility-target:** for-author

The `|| pwd` fallback also fires *inside* a repo's `.git` directory, where `--show-toplevel`
fails. `cd r1/.git && questions.sh init` created `r1/.git/docs/working/questions.md` and
`questions-archive.md`. A precise version would say "`$PWD` itself when it is not inside a work tree".

**Evidence:** `scripts/questions.sh:55`, `$FC3/questions-init.out`

---

## Claim 17: "Never touches a file that exists."

**Location:** `scripts/questions.sh:314-316`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers regular existing files (untouched, `= exists`) and a dangling symlink at the live path. Does not establish races between the check and the write.
**Legibility-target:** for-author

```bash
# scripts/questions.sh (cmd_init loop head)
    for file in "$LIVE" "$ARCHIVE"; do
        [[ -e "$file" ]] && { echo "  = exists: $file"; continue; }
```
(excerpt ends inside cmd_init(); the loop continues through `mkdir -p` and the `printf … > "$file"` write to the function's end — read)

`-e` is false for a dangling symlink, and `> "$file"` follows the link. With
`docs/working/questions.md -> ../../elsewhere.md`, `init` reported `+ created` and wrote
`r2/elsewhere.md` (`# Running questions`) outside `docs/working/`. Existing regular files are
never rewritten.

**Evidence:** `scripts/questions.sh:314-331`, `$FC3/questions-init.out`

---

## Claim 18a: "Override with SI_RUN_ID … it becomes a file-name prefix and a markdown cell, so only [A-Za-z0-9._-] is accepted."

**Location:** `scripts/self-improvement.sh:451-461`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the charset gate. `.`, `..` and `-rf` are accepted. They are harmless as used (`"$ARCHIVE_DIR/${PREFIX}-${name}"`, `mv --`), but that safety comes from the call site, not from this gate. Does not establish UTF-8-locale range semantics (the probe ran with a broken locale that falls back to C, where `é` was rejected).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/self-improvement.sh:458-463
SI_RUN_ID="${SI_RUN_ID:-$(date +%F)}"
if [[ ! "$SI_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Error: SI_RUN_ID must match [A-Za-z0-9._-]+ (got: $SI_RUN_ID)" >&2
    exit 1
fi
printf '%s\n' "$SI_RUN_ID" > "$WORKING_DIR/si-run-id.txt"
```

The probe rejected `a\nb`, `a b`, `a/b`, `é` and the empty string.

**Evidence:** `scripts/self-improvement.sh:451-463`, `scripts/archive-working-docs.sh:108-121`, `$FC3/migrate.out`

---

## Claim 18b: "that script reads si-run-id.txt for its default prefix, so the two agree even when the archive happens on a later day"

**Location:** `scripts/self-improvement.sh:452-455`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the same regex on both sides and the same file. Agreement assumes `archive-working-docs.sh` runs from the repo root (relative `docs/working`), whereas SI writes `$REPO_DIR/docs/working`. `si-run-id.txt` is not in `PERMANENT`, so the archive pass moves it to `archive/<id>-si-run-id.txt`, and after that `_live_run_matches` sees no live file and returns true.
**Legibility-target:** for-orchestrator-synthesis

The two regexes are identical (`^[A-Za-z0-9._-]+$` at `self-improvement.sh:459` and
`archive-working-docs.sh:45`). The bats test asserts `docs/working/archive/2026-01-02-si-run-id.txt`
(`test/scripts/archive-working-docs.bats:170`).

**Evidence:** `scripts/self-improvement.sh:434,458-463`, `scripts/archive-working-docs.sh:37-49,61-94`, `$FC3/si-bats.out`

---

## Claim 19: "`Accepted-immutable` rows (machine-written) … the only row kind a run may write without a human decision … the `Reason` cell starts with `[auto: code-review]`", as cross-referenced from `skills/code-review/SKILL.md:158` and `rubric.md:319-323`

**Location:** `skills/code-review/references/override-log.md:24-33`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the three documents agree and that their anchors resolve. Does not establish that any orchestrator code writes such rows (prose-only skill).
**Legibility-target:** for-orchestrator-synthesis

`rubric.md:319` holds "**Immutable-history exception:**" inside `### Unified Severity Mapping`
(:272). `override-log.md:11` is `### Capture format`. The anchor check over all 33 links added in
this diff resolved `#unified-severity-mapping` and `#capture-format`.

**Evidence:** `skills/code-review/references/override-log.md:11-45`, `skills/code-review/references/rubric.md:272,319-323`, `$FC3/anchors.out`

---

## Claim 20: "| 🟡 Must Address | Major | P1 | any confirmed finding |" / "test-strategy P1→🟡, else 🟢"

**Location:** `skills/code-review/references/rubric.md:288-292` (repeated at `rubric.md:340`, `rubric.md:504`, `skills/code-review/SKILL.md:1230`)
**Type:** Reference / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers test-strategy's published output scale. Does not establish how an orchestrator would actually map a test-strategy finding today.
**Legibility-target:** for-author

test-strategy has no P1/P2 scale. Its output schema uses a three-level priority:

```markdown
# skills/test-strategy/SKILL.md:196
**Priority:** [high / medium / low]
```

`grep -rn "P1\|P2" skills/test-strategy/` returns nothing. A confirmed test-strategy finding
therefore has no row to map through, and the "no 🔴 path … reaches 🟡 at most" rule rests on
labels that critic never emits. Added in d659fa9. (ui-visual-review's Critical/Major/Minor scale
does exist, at `skills/ui-visual-review/SKILL.md:388`.)

**Evidence:** `skills/code-review/references/rubric.md:285-296,340,504`, `skills/code-review/SKILL.md:1230`, `skills/test-strategy/SKILL.md:196,207`

---

## Claim 21: "a verdict whose sources are all `[abstract]` caps at Medium, and High always requires at least one `[deep-read]`" (and the reworked aggregation bullets)

**Location:** `skills/fact-check/SKILL.md:179-181,376-377,414-420`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers internal consistency across the step-5 text, the Scrutiny Tags definition, the aggregation rules and the worked-example table. Does not establish how graders apply it.
**Legibility-target:** for-orchestrator-synthesis

The aggregation rule reads "If no cited source is `[deep-read]` and at least one is `[abstract]`,
the verdict **caps at Medium** … There is no Medium → Low step for `[abstract]` reads"
(`:414-417`). The one-tier downgrade now applies only when every source is `[inferred]`
(`:418-420`). The example rows `Accurate | Medium | [inferred] | [abstract]` and
`Mostly accurate | Medium | [observed] | [abstract]` are consistent with that. The
`[load-bearing]` and `[peripheral]` tags referenced at `:437-445` exist at `:111-117`.

**Evidence:** `skills/fact-check/SKILL.md:102-147,176-181,370-460`

---

## Claim 22a: "Macro × Cold | Low (matches the hot-path gate …"

**Location:** `skills/performance-reviewer/SKILL.md:283`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the default severity against the gate at `:46`. Does not cover the added escalation conditions (Claim 22b).
**Legibility-target:** for-orchestrator-synthesis

```markdown
# skills/performance-reviewer/SKILL.md:46
… Code in cold paths (… migration scripts) should default to Low or Informational unless the cold path blocks a latency-sensitive operation. …
```

No other `Macro × Cold` reference exists in skills/, workflows/, guides/, test/ or patterns/.

**Evidence:** `skills/performance-reviewer/SKILL.md:46,276-287`

---

## Claim 22b: "… escalate when the cold path blocks a latency-sensitive operation or runs over large data, e.g. a nightly batch)"

**Location:** `skills/performance-reviewer/SKILL.md:283`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the parenthetical attributes to "the gate". Does not judge whether the extra condition is desirable.
**Legibility-target:** for-author

The gate at `:46` names only one escalation, "blocks a latency-sensitive operation". "Runs over
large data, e.g. a nightly batch" is a new condition. Because it sits inside the "matches the
hot-path gate" parenthetical, it reads as if the gate said it. Either add the condition to `:46`
or mark it as a matrix-only addition.

**Evidence:** `skills/performance-reviewer/SKILL.md:46,283`

---

## Claim 23: "([qualifying author note](../skills/code-review/references/rubric.md#-must-address))"

**Location:** `workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two links whose anchors failed to resolve. The other 31 links added in this diff resolved. Does not check links that predate the diff.
**Legibility-target:** for-author

The target heading `## 🟡 Must Address` (`rubric.md:49`) sits inside the fenced ```` ```markdown ````
template that runs from `rubric.md:31` to `:158`. GitHub-style renderers generate no anchor for
headings inside a code fence, so `#-must-address` lands at the top of the file. The
definition's text does exist at `rubric.md:51-59`.
Command: `python3 $FC3/anchors.py` · cwd `/workspace` · exit 0 · 2026-09-21T19:33:15-07:00. Output: `checked 33 bad 2`.

**Evidence:** `skills/code-review/references/rubric.md:31,49-59,158`, `$FC3/anchors.out`

---

## Claim 24: "Success is judged from the JSON envelope, not the exit code. … The script is installed at `~/.claude/scripts/` by both install routes (README and the devcontainer linker)."

**Location:** `workflows/review-fix-loop.md:93-98`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the linker route (executed) and the README line (grep-asserted by the same test). Does not establish a real bare-host install.
**Legibility-target:** for-orchestrator-synthesis

`bats -f "installed" test/link-claude-home-wiring.bats` → `ok 1 installed ~/.claude/scripts/{lite-review.py,questions.sh} resolve after install`,
exit 0, 2026-09-21T19:35:20-07:00. The envelope check is `return json.loads(proc.stdout)` with a
`sys.exit` on `JSONDecodeError` (`scripts/lite-review.py:169-173`).

**Evidence:** `test/link-claude-home-wiring.bats:255-269`, `README.md:20-24`, `scripts/lite-review.py:153-173`, `$FC3/link-bats.out`

---

## Claim 25: "Tests: 14 new cases in test/hooks/guard-trusted-writes.bats (40/40 pass)"

**Location:** commit `4c7a2bb` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of added `@test` lines and a 40/40 pass at HEAD 654c0ed. The pass was not re-run at 4c7a2bb itself, whose file also has 40 tests.
**Legibility-target:** for-automated-gate

`git show 4c7a2bb -- test/hooks/guard-trusted-writes.bats | grep -c '^+@test'` → 14.
`git show 4c7a2bb:… | grep -c '^@test'` → 40. At HEAD, `bats` gave 40 ok, exit 0.

**Evidence:** `test/hooks/guard-trusted-writes.bats`, `$FC3/guard-bats.out`

---

## Claim 26: "Global paths are unchanged."

**Location:** commit `4c7a2bb` message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the deny-covered global paths (unchanged) and nested global paths (changed). Does not establish whether Claude Code reads the nested ones.
**Legibility-target:** for-author

Deny-covered paths are unchanged: `~/.claude/settings.json`, `~/.claude/hooks/a`, `~/CLAUDE.md`
and `~/.claude/CLAUDE.md` are `hard` before and after. Nested global paths moved from HARD to
SOFT: `~/.claude/sub/settings.json` and `~/.claude/projects/x/CLAUDE.md` went old `hard` →
new `soft`, because HARD now needs `len(rel.parts) == 1`. The Bash-side global CLAUDE.md
spellings also changed (Claim 5b). This commit message is already merged and cannot be edited.
Precise version: "deny-covered global paths are unchanged".

**Evidence:** `hooks/guard-trusted-writes.py:88-99`, `$FC3/probe3.out`

---

## Claim 27: "self-improvement.sh sets SI_RUN_ID (default: run-start date, overridable, restricted to [A-Za-z0-9._-]) … Run is last so positional readers … are unaffected … Tests: header/row/migration/idempotence, run-scoped lookups …"

**Location:** commit `a45f4a9` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed behaviours through the four SI suites (84 ok). Does not include Claim 13b's mode/no-op defect, which this message does not claim.
**Legibility-target:** for-automated-gate

The suites passed with exit 0 (`$FC3/si-bats.out`). The Run column is the final `%s` in the
`printf '| %s | … | | | | %s |\n'` at `scripts/lib/si-functions.sh:537-538`.

**Evidence:** `scripts/lib/si-functions.sh:485-540`, `$FC3/si-bats.out`

---

## Claim 28: "Gate 5 … now runs run-tests.sh --fast; red blocks without running slow; green runs --slow. A HEALTH_CHECK_SKIP_BATS guard stops health-check.bats recursing."

**Location:** commit `0ccbdb8` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 10.
**Legibility-target:** for-automated-gate

Same execution as Claim 10: 4/4 gate-5 tests pass. `test/scripts/health-check.bats:19` sets
`export HEALTH_CHECK_SKIP_BATS=1`.

**Evidence:** `scripts/health-check.sh:345-391`, `$FC3/hc-bats.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2b** (`hooks/guard-trusted-writes.py:10-12`): when `CLAUDE_CONFIG_DIR` ≠ `~/.claude`, the hook still treats `~/.claude` as HARD and defers, but the deny rules cover only `{{CLAUDE_DIR}}`, so `~/.claude/settings*.json` and `~/.claude/hooks/**` have no gate. Either drop `HOME/.claude` when the env var is set, or fix the docstring.
- **Claim 5b** (`hooks/guard-trusted-writes.py:24-29`, commit 4c7a2bb): these spellings of the global CLAUDE.md are now SOFT in Bash, where they were HARD before: `"$HOME"/CLAUDE.md`, `"$HOME/"CLAUDE.md`, `~//`, `~/./`, `~/"CLAUDE.md"`, `${HOME:-}/`, `${HOME%/}/`, `/home/node//`, `$HOME/.claude/../`, `./global-instructions//`. This goes beyond the accepted `cd ~` residual.
- **Claim 13b** (`scripts/lib/si-functions.sh:545`): "no-op when no header is found" is false. The file is rewritten (new inode, mode 0600), and every migration leaves the log at 0600.
- **Claim 20** (`skills/code-review/references/rubric.md:288-292`, `:340`, `:504`, `SKILL.md:1230`): test-strategy emits `Priority: high/medium/low`, not P1/P2. The contextual-critic row maps a scale that doesn't exist.
- **Claim 23** (`workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`): `rubric.md#-must-address` doesn't resolve, because the heading is inside a code fence.

### Stale
- none

### Mostly Accurate
- **Claim 6** (`hooks/guard-trusted-writes.py:25-26`): Bash `.claude/…` HARD matching is literal-fragment only. `//`, `/./`, quoted-segment and `cd`-relative spellings return None (pre-existing).
- **Claim 16b** (`scripts/questions.sh:35-36`): the fallback also fires inside `.git/`, which creates `.git/docs/working/`.
- **Claim 17** (`scripts/questions.sh:316`): `init` writes through a dangling symlink at the live or archive path.
- **Claim 22b** (`skills/performance-reviewer/SKILL.md:283`): "runs over large data" isn't in the gate it claims to match.
- **Claim 26** (commit 4c7a2bb): nested global paths (`~/.claude/*/settings.json`, `~/.claude/**/CLAUDE.md`) moved from HARD to SOFT. The message can't be edited, so this is `Accepted-immutable` territory.

### Unverifiable
- **Claim 15** (`scripts/lite-review.py:17-23`): the `--bare` "Not logged in / exit 0" behaviour needs a subscription login and network egress to re-run.

### Routing note
Claim 26 is the only finding that lands on immutable history (a merged commit message). Claim 5b
is also stated in 4c7a2bb's message, but its fix belongs in the code and docstring, which can be
edited. The rest are in editable files.

### Hallucination-pattern log
Claim 20 qualifies as a fabrication: a severity vocabulary (`P1`/`P2`) attributed to
`test-strategy`, whose output schema has no such levels. I did **not** append it to
`docs/reviews/hallucination-patterns.md`, because the brief allowed writing only this report.
Suggested entry: `- **test-strategy P1/P2 severity claimed but skill emits high/medium/low** — rubric's contextual-critic row maps a scale test-strategy never produces. First seen: 2026-09-21, report: docs/reviews/code-fact-check-report-r3.md.`

---

## Goal-Alignment Note

- **Answered:** This is the fact-check pass for the review of `answers-2026-09-20` before its local merge to main. All seven claim groups the brief named were checked. The guard's tier docstring was probed with small Python experiments covering quoting, normalization, `CLAUDE_CONFIG_DIR` (unset, other, relative), `HOME=/`, and a symlinked project `.claude`. questions.sh resolution and `init` were exercised in temp repos. The SI_RUN_ID gate, the migration and the morning-summary readers were checked. Gate 5 and six related bats suites were run and all passed. The doc cross-references were anchor-checked mechanically. Five claims are Incorrect. For the user's security focus, the load-bearing one is Claim 5b: the `"$HOME"/CLAUDE.md` family of bypasses beyond the accepted residual.
- **Out of scope:** Whether Claude Code's permission matcher resolves symlinks or `..` in deny rules (Claim 3 scope). Doc-only moves (`questions.md` → `questions-archive.md`, `archive/`). draft-review, DD, design-space-situating and architecture-review doc edits beyond anchor checks. A full `run-tests.sh --slow` run, skipped because a background bats loop is running.
- **Escalate:** Claim 2b and Claim 5b are security-relevant and should reach security-reviewer. The hallucination-log append for Claim 20 was withheld under the brief's write restriction, so the orchestrator should decide whether to add it.
