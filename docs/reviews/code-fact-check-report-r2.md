Commit: 654c0ed

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** `git diff e8d5fa1..answers-2026-09-20` (32 commits, 50 files). Code prioritized: `hooks/guard-trusted-writes.py`, `scripts/questions.sh`, `scripts/self-improvement.sh`, `scripts/archive-working-docs.sh`, `scripts/lib/si-functions.sh`, `scripts/lib/si-morning-summary.sh`, `scripts/health-check.sh`, `scripts/lite-review.py`, `devcontainer-config/*.sh`. Docs: `skills/fact-check`, `skills/performance-reviewer`, `skills/code-review/references/*`, `skills/draft-review`, `skills/self-eval`, `workflows/pr-prep.md`, `workflows/review-fix-loop.md`, `global-instructions/CLAUDE.md`, `README.md`. Commit messages 4c7a2bb, a45f4a9, aa9a5a0, 0ccbdb8, 40f21fc, be30668, 5928c47.
**Checked:** 2026-09-21
**Total claims checked:** 22 (20 numbered; Claims 2 and 3 split into a/b)
**Summary:** 11 verified, 5 mostly accurate, 0 stale, 5 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Its dominant class is
*a specific measured value quoted from a checked-in artifact set that does not contain it*. Every
numeric claim in scope (14 new tests / 40 pass, 794 ok, ~40 suites) was recomputed against that
pattern; all three held. No claim here matches a logged pattern.

**Execution provenance.** The task brief forbids modifying any repo file other than this report,
so captured outputs live in the session scratchpad
`/tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/` (abbreviated
`$SCRATCH` below), not under `docs/reviews/execution-logs/`. They are not durable past this session;
every probe script is listed so it can be re-run. All probes ran with cwd `/workspace` (or the
probe's own temp dirs), HOME=/home/node, on 2026-09-21 between 19:27 and 19:33 -07:00, against
the working tree at `654c0ed` (clean). Note: the *installed* v1 guard hook blocked two heredoc
probe commands that merely contained the string `CLAUDE.md` — the Q-035 symptom, live — so probe
scripts were written with the Write tool instead.

---

## Claim 1: "HARD = the GLOBAL config dir only: ~/.claude/hooks/**, ~/.claude/settings*.json, ~/.claude/CLAUDE.md, ~/CLAUDE.md (the config dir is $CLAUDE_CONFIG_DIR when set, else ~/.claude — the same {{CLAUDE_DIR}} hooks/wiring.json substitutes)."

**Location:** `hooks/guard-trusted-writes.py:10-12`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which directories `_global_dirs()` treats as global and how that compares with the linker's `{{CLAUDE_DIR}}`; does not establish Claude Code's own interpretation of a relative or `~`-prefixed `CLAUDE_CONFIG_DIR`, nor whether CC's deny-rule matcher normalizes `..`/symlinks.
**Legibility-target:** for-author

The code does not use "$CLAUDE_CONFIG_DIR when set, *else* ~/.claude": it always includes `~/.claude` and *adds* the configured dir:

```python
# hooks/guard-trusted-writes.py:56-67
def _global_dirs():
    """The global config dir(s), as given and resolved. HARD applies only here."""
    dirs = [HOME / ".claude"]
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    if cfg:
        dirs.append(Path(os.path.expanduser(cfg)))
    ...
```

The linker substitutes only one dir, un-expanded: `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`devcontainer-config/link-claude-home.sh:36`) and `gsub("\\{\\{CLAUDE_DIR\\}\\}"; $dir)` (`:137`), so the deny rules name only `$CLAUDE_CONFIG_DIR` when it is set (`hooks/wiring.json:120-125`). Consequences: (a) with `CLAUDE_CONFIG_DIR` pointing elsewhere, `~/.claude/hooks/**` is still HARD → file tools *defer* with no deny rule behind them — the same "no gate at all" situation the SOFT paragraph at `:19-21` says it avoids for project dirs; (b) the hook `expanduser`s the value while the linker does not, so `CLAUDE_CONFIG_DIR="~/altcfg"` makes the two disagree (probe: hook treats `/home/node/altcfg/hooks/x` as HARD/defer). The main point — only global dirs are HARD, project `.claude/` is not — holds: `/workspace/.claude/settings.json` and `/workspace/.claude/hooks/a.sh` classify `soft` (`$SCRATCH/probe.py` output).

**Evidence:** `hooks/guard-trusted-writes.py:56-78`, `devcontainer-config/link-claude-home.sh:36,137`, `hooks/wiring.json:114-128`; command `bash $SCRATCH/probe2.sh` (cwd /workspace, exit 0, 2026-09-21T19:27:57-07:00) → `$SCRATCH/probe2.out`; `python3 $SCRATCH/probe.py` (exit 0) output reproduced in session.

---

## Claim 2a: "So this hook must NEVER 'ask' on a HARD path — it DEFERS (lets the deny rule block the file tools)" — as implemented for canonical spellings of HARD paths

**Location:** `hooks/guard-trusted-writes.py:15-17`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers file-tool (Edit/Write/MultiEdit) inputs whose literal path, or `.`/`//`-normalized path, lies under `~/.claude/{hooks/**,settings*.json,CLAUDE.md}` or is `~/CLAUDE.md`; does not establish the invariant for paths containing `..` or reached through symlinks (Claim 2b).
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:176-180
        tier = classify_path(fp)
        if tier == "hard":
            # DO NOT "ask": that would override your permissions.deny (#39344).
            # Defer and let the deny rule block it.
            defer()
```

Tainted-session probe: `~/.claude/hooks/guard-trusted-writes.py`, `~/.claude/CLAUDE.md`, `~/.claude/x/../settings.json`, `~/CLAUDE.md`, `~//CLAUDE.md`, `~/./CLAUDE.md`, `~/.claude//hooks/x` all → `<defer>` / `hard`.

**Evidence:** `hooks/guard-trusted-writes.py:80-99,172-184`; `$SCRATCH/probe2.out`; `python3 $SCRATCH/probe.py` output.

---

## Claim 2b: same invariant ("must NEVER 'ask' on a HARD path") for non-canonical spellings — and 4c7a2bb's "Global paths are unchanged"

**Location:** `hooks/guard-trusted-writes.py:15-17`; commit `4c7a2bb` message ("Global paths are unchanged.")
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tainted-session file-tool writes whose target *is* a global HARD file but whose spelling contains `..` or runs through a symlinked project `.claude/`; does not establish whether Claude Code's `permissions.deny` would still match these spellings once the hook returns `ask` (issue #39344 says the ask wins regardless).
**Legibility-target:** for-author

`classify_path` tests two candidates: the literal path `p` (lexical `relative_to`, which does not collapse `..`) and `rp = p.resolve()`. In this install, `~/.claude/hooks` and `~/.claude/CLAUDE.md` are symlinks into `/opt/claude-workflows/` (`readlink -f` → `/opt/claude-workflows/hooks`, `/opt/claude-workflows/CLAUDE.md`), so `resolve()` leaves the global dir and `_global_rel` returns `None` for both candidates:

```python
# hooks/guard-trusted-writes.py:84-99 (excerpt ends :99; enclosing classify_path() continues to :109 — read)
    for cand in (p, rp):
        name = cand.name.lower()
        rel = _global_rel(cand)
        if rel is not None and rel.parts:
            if rel.parts[0] == "hooks":
                return "hard"
            ...
        if name == "claude.md" and cand.parent == HOME:
            return "hard"
```

The path then falls to `if ".claude" in low: return "soft"` (`:107-108`) and, tainted, the hook returns **ask** on the real global hook/instructions file. Executed results (tainted session):

| Input | old hook (e8d5fa1) | new hook (654c0ed) |
|---|---|---|
| `~/x/../.claude/hooks/guard-trusted-writes.py` | defer | **ask** |
| `~/.claude/x/../CLAUDE.md` | defer | **ask** |
| `<proj>/.claude/hooks/guard-trusted-writes.py`, `<proj>/.claude` → symlink to `~/.claude` | defer | **ask** |
| `<proj>/.claude/CLAUDE.md`, same symlink | defer | **ask** |
| `~/.claude/x/../hooks/guard-trusted-writes.py` | ask | ask (pre-existing) |

So "global paths are unchanged" is false for four of these spellings (old v1 classified them HARD by any `.claude` segment; v2 does not), and the docstring invariant is violated in both versions for the last row. This is the documented #39344 override path: an `ask` on a HARD file silently overrides the deny rule. `settings.json` is unaffected because `~/.claude/settings.json` is a real file, not a symlink (`~/.claude/x/../settings.json` → defer).

**Evidence:** `hooks/guard-trusted-writes.py:80-109`; commit `4c7a2bb`; command `bash $SCRATCH/probe2.sh` (cwd /workspace, exit 0, 2026-09-21T19:27:57-07:00) → `$SCRATCH/probe2.out`; command `bash $SCRATCH/probe3.sh` (old hook from `git show e8d5fa1:hooks/guard-trusted-writes.py`, exit 0, ~19:28 -07:00) → `$SCRATCH/probe3.out`; `ls -la ~/.claude` showing the `hooks` and `CLAUDE.md` symlinks.

---

## Claim 3a: "Bash … HARD = … CLAUDE.md only when qualified as global: `~/`, `$HOME/`, `${HOME}/`, the literal home path, or `global-instructions/CLAUDE.md` … SOFT = a bare/project `CLAUDE.md`"

**Location:** `hooks/guard-trusted-writes.py:24-31`, `:121-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal, unquoted prefix forms the docstring lists and the bare/project forms; does not establish that every shell spelling of the global file is caught (Claim 3b).
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:123-129
_GLOBAL_PREFIXES = [r"~", r"\$HOME", r"\$\{HOME\}", r"global-instructions"]
if str(HOME).rstrip("/"):
    _GLOBAL_PREFIXES.append(re.escape(str(HOME).rstrip("/")))
HARD_FRAG = re.compile(
    r"\.claude/hooks(/|\b)|\.claude/settings|\.claude/CLAUDE\.md|managed-settings"
    r"|(?:" + "|".join(_GLOBAL_PREFIXES) + r")/CLAUDE\.md",
    re.I)
```

Probe with a write primitive: `~/CLAUDE.md`, `$HOME/CLAUDE.md`, `${HOME}/CLAUDE.md`, `/home/node/CLAUDE.md`, `global-instructions/CLAUDE.md`, `/home/node/.claude/CLAUDE.md` → `hard`; `CLAUDE.md`, `/workspace/CLAUDE.md`, `cd ~ && echo x > CLAUDE.md` (the accepted residual) → `soft`. `bats test/hooks/guard-trusted-writes.bats`: 40/40 ok.

**Evidence:** `hooks/guard-trusted-writes.py:121-142`; `python3 $SCRATCH/probe.py` (exit 0); `bats test/hooks/guard-trusted-writes.bats` (cwd /workspace, exit 0, 2026-09-21T19:29:44-07:00) → `$SCRATCH/guard-bats.log`.

---

## Claim 3b: "HARD … for the Bash path that deny rules don't cover, returns 'deny' outright" — for equivalent spellings of the global CLAUDE.md

**Location:** `hooks/guard-trusted-writes.py:16-17`, `:24-29`; commit `4c7a2bb` ("HARD_FRAG now matches CLAUDE.md only when qualified as the global file")
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Bash commands that write the global `~/CLAUDE.md` via quoting, doubled slash, `./`, `..`, or parameter-expansion variants of the listed prefixes; does not cover the known, accepted `cd ~ && … > CLAUDE.md` residual, nor variable indirection (`H=$HOME; … $H/CLAUDE.md`), which no text regex could catch.
**Legibility-target:** for-author

The prefix alternation must be immediately followed by `/CLAUDE\.md`, so any token between the prefix and the filename defeats it. Each of these writes `/home/node/CLAUDE.md` in bash and classifies **soft** (untainted → `<defer>`, tainted → `ask`, never `deny`):

`echo x > "$HOME"/CLAUDE.md` · `echo x > "${HOME}"/CLAUDE.md` · `echo x > ${HOME:-}/CLAUDE.md` · `echo x > ${HOME%/}/CLAUDE.md` · `echo x > ~//CLAUDE.md` · `echo x > ~/./CLAUDE.md` · `echo x > $HOME/.claude/../CLAUDE.md` · `echo x > /home/node//CLAUDE.md` · `echo x > /home/node/./CLAUDE.md` · `echo x > $HOME/"CLAUDE.md"`

The old regex `(^|[\s"'=~/])CLAUDE\.md` (e8d5fa1) denied every one of these (`$SCRATCH/probe3.out`: `tainted bash "$HOME"/CLAUDE.md -> deny`, `untainted bash ~//CLAUDE.md -> deny`). The docstring's listed prefixes are accurate as a description of the regex (Claim 3a), but the mechanism it names — "qualified as global" → HARD → deny — does not hold for trivially equivalent spellings, so the narrowing opened more than the accepted `cd ~` residual.

**Evidence:** `hooks/guard-trusted-writes.py:123-142,159-170`; `python3 $SCRATCH/probe.py` (exit 0); `bash $SCRATCH/probe2.sh` → `$SCRATCH/probe2.out` (lines "tainted bash \"$HOME\"/CLAUDE.md -> ask", "untainted bash ~//CLAUDE.md -> <defer>"); `bash $SCRATCH/probe3.sh` → `$SCRATCH/probe3.out`.

---

## Claim 4: "HOME="/" would make this prefix empty and match any "/CLAUDE.md""

**Location:** `hooks/guard-trusted-writes.py:124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the empty-alternative effect and that the guard prevents it; does not establish behavior for other degenerate HOME values (empty string, relative).
**Legibility-target:** for-orchestrator-synthesis

`str(Path.home()).rstrip("/")` is `""` for `HOME=/`; an empty alternative in `(?:~|\$HOME|)/CLAUDE\.md` matches `echo x > /tmp/CLAUDE.md` (probe: `True`). With the guard, `HOME=/` classifies `/tmp/CLAUDE.md` soft (`ask` when tainted) while `~/CLAUDE.md` stays `deny` (`$SCRATCH/probe2.out`, "HOME=/" lines).

**Evidence:** `hooks/guard-trusted-writes.py:123-129`; `bash $SCRATCH/probe3.sh` → `$SCRATCH/probe3.out` ("with empty prefix, matches /tmp/CLAUDE.md: True"); `$SCRATCH/probe2.out`.

---

## Claim 5: Bash `.claude/hooks` / `.claude/settings` fragments stay HARD "for both global and project paths … a project settings write is an ask via Edit/Write but a deny via Bash" (4c7a2bb Notes; docstring :25-26)

**Location:** `hooks/guard-trusted-writes.py:25-26`; commit `4c7a2bb`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the literal `.claude/settings…` and `.claude/hooks/…` fragments; does not establish coverage of spellings that split the fragment (e.g. `.claude//settings.json`, `.claude/./hooks`), which were not probed.
**Legibility-target:** for-orchestrator-synthesis

`echo x > .claude/settings.local.json` → `hard`; Edit of `/workspace/.claude/settings.json` → `soft` (`$SCRATCH/probe.py` output). The fragment is `r"\.claude/hooks(/|\b)|\.claude/settings"` (`hooks/guard-trusted-writes.py:127`).

**Evidence:** `hooks/guard-trusted-writes.py:126-129`; `python3 $SCRATCH/probe.py`.

---

## Claim 6: "Tests: 14 new cases in test/hooks/guard-trusted-writes.bats (40/40 pass)"

**Location:** commit `4c7a2bb` message
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the @test count before/after 4c7a2bb and a pass at HEAD; does not establish that the 14 cases exercise the bypasses in Claims 2b/3b (they do not).
**Legibility-target:** for-automated-gate

`git show <rev>:test/hooks/guard-trusted-writes.bats | grep -c '^@test'` → 26 at `4c7a2bb~1`, 40 at `4c7a2bb`, 40 at HEAD; the suite run at HEAD ends `ok 40 null tool_input defers`, exit 0.

**Evidence:** `test/hooks/guard-trusted-writes.bats`; `bats test/hooks/guard-trusted-writes.bats` (cwd /workspace, exit 0, 2026-09-21T19:29:44-07:00) → `$SCRATCH/guard-bats.log`.

---

## Claim 7: questions.sh "Which files: the docs/working/ of the git repo you run it FROM (the toplevel of $PWD; $PWD itself outside a git repo) … QUESTIONS_LIVE / QUESTIONS_ARCHIVE override either path."

**Location:** `scripts/questions.sh:35-39`, `:51-57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-git dir, a git subdirectory, a nested repo, and env override; does not establish behaviour inside a git submodule or linked worktree specifically (both resolve via `git rev-parse --show-toplevel`, i.e. to the inner checkout, which the nested-repo case approximates).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/questions.sh:55-57
PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"
LIVE="${QUESTIONS_LIVE:-$PROJECT_ROOT/docs/working/questions.md}"
ARCHIVE="${QUESTIONS_ARCHIVE:-$PROJECT_ROOT/docs/working/questions-archive.md}"
```

Probe: `init` from `repo/a/b` created `repo/docs/working/*` (not under `a/b`); from a non-git dir it created `nogit/docs/working/*`; from a nested repo it created files in the inner repo; env overrides were honoured. `test/questions-doc.bats` 18/18 ok. `scripts/health-check.sh:1021-1026` pins the gate with the same two variables.

**Evidence:** `scripts/questions.sh:51-57`, `scripts/health-check.sh:1016-1032`; `bash $SCRATCH/probe_q.sh` (exit 0, 2026-09-21T19:28:53-07:00) → `$SCRATCH/probe_q.out`; `bats test/questions-doc.bats` (exit 0) → `$SCRATCH/questions-doc.log`.

---

## Claim 8: `cmd_init` "Never touches a file that exists."

**Location:** `scripts/questions.sh:314-316`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers regular existing files and a dangling symlink at the target path; does not establish behaviour under a concurrent writer.
**Legibility-target:** for-author

```bash
# scripts/questions.sh:319-320 (excerpt; enclosing cmd_init() spans :317-332 — read)
    for file in "$LIVE" "$ARCHIVE"; do
        [[ -e "$file" ]] && { echo "  = exists: $file"; continue; }
```

Existing regular files are preserved (probe appended `KEEP`, re-ran `init`, `KEEP` survived). But `-e` follows symlinks: when `docs/working/questions.md` is a dangling symlink, `init` reports `+ created` and writes through it, creating the link's target (`dl/elsewhere.md`, 80 bytes). Precise version: "never overwrites an existing file; a dangling symlink at the path is written through."

**Evidence:** `scripts/questions.sh:314-332`; `$SCRATCH/probe_q.out` ("dangling symlink as LIVE").

---

## Claim 9: README / global-instructions: helpers are called by the installed path `~/.claude/scripts/questions.sh` and `lite-review.py`, which "the devcontainer links this too"

**Location:** `README.md:20-24`, `global-instructions/CLAUDE.md:235,281`, `devcontainer-config/link-claude-home.sh:41-49`, `devcontainer-config/install.sh:39-45`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the linker's ENTRIES, the install.sh staging list, and the README symlink line; does not establish that the live host has re-run install.sh (host state).
**Legibility-target:** for-orchestrator-synthesis

`ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)` (`link-claude-home.sh:50`), `CLAUDE_HOME_SRC=(global-instructions/CLAUDE.md skills workflows guides patterns hooks scripts)` (`install.sh:49`), README `ln -s ~/claude-workflows/scripts   ~/.claude/scripts`. In this container `~/.claude/scripts -> /opt/claude-workflows/scripts`. The link test at `test/link-claude-home-wiring.bats:261-270` asserts both files resolve and greps the README line.

**Evidence:** `devcontainer-config/link-claude-home.sh:41-50`, `devcontainer-config/install.sh:39-49`, `README.md:20-24`, `test/link-claude-home-wiring.bats:255-270`; `ls -la ~/.claude` (session).

---

## Claim 10: SI_RUN_ID "becomes a file-name prefix and a markdown cell, so only [A-Za-z0-9._-] is accepted"; "archive-working-docs.sh reads si-run-id.txt for its default prefix, so the two agree even when the archive happens on a later day"

**Location:** `scripts/self-improvement.sh:451-463`; `scripts/archive-working-docs.sh:39-49`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers validation of the env value, the reader's re-validation, and the fallback; does not establish the ordering relative to a second SI run started before archiving (a later run overwrites the file — acknowledged in a45f4a9's Notes), nor that `si-run-id.txt` survives an archive (it is not in PERMANENT and is itself moved).
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

Regex probe: `a\nb`, `a b`, `a/b`, `a|b`, `é` (also under `C.UTF-8`), `''` rejected; `2026-09-21` and `..` accepted (`..` yields `archive/..-name`, a plain file name, harmless). A user-supplied positional PREFIX is not validated (pre-existing, outside the claim). `test/scripts/archive-working-docs.bats` 11/11 ok.

**Evidence:** `scripts/self-improvement.sh:451-463`, `scripts/archive-working-docs.sh:37-139`; regex probe (session, exit 0); `bats test/scripts/archive-working-docs.bats` (exit 0, ~19:30 -07:00) → `$SCRATCH/archive-working-docs.log`.

---

## Claim 11: `_migrate_hypothesis_log_run_column` — "Data rows are untouched. No-op when the header already has a Run cell … Exact-cell match, so 'Checked at Round' never counts as 'Run'."

**Location:** `scripts/lib/si-functions.sh:542-568`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an 11-column log with plain and escaped-pipe rows, idempotence, and a header with `Checked at Round` but no `Run`; does not establish behaviour for a header without the literal ` Round ` substring (then neither the check nor the rewrite fires — also a no-op).
**Legibility-target:** for-orchestrator-synthesis

Probe: first migration appended ` Run |` / `-----|` to header and separator only; `diff` of data rows before/after empty; second run byte-identical (`cmp`); `| Round | Checked at Round |` header was migrated (not mistaken for having Run). `test/append-approved-hypotheses.bats` 15/15 ok.

**Evidence:** `scripts/lib/si-functions.sh:542-568`; `bash $SCRATCH/probe_mig.sh` (exit 0, ~19:31 -07:00) → `$SCRATCH/probe_mig.out`; `bats test/append-approved-hypotheses.bats` → `$SCRATCH/append-approved-hypotheses.log`.

---

## Claim 12: "old rows keep an absent cell, which readers treat as 'unknown run' and resolve newest-first" / "rows without it resolve their tasks file newest-first"

**Location:** `scripts/lib/si-functions.sh:469-475`; `scripts/lib/si-morning-summary.sh:970-972`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Run-cell read via `_locate_log_col`/`_split_row_fields`/`_pick_col` and the `_find_tasks_file` fallback; does not establish end-to-end morning-summary output for escaped-pipe rows.
**Legibility-target:** for-author

For plain rows the claim holds: an 11-cell row yields `''` for Run, and `_find_tasks_file` always appends the unconditional newest-first scan after any run-specific candidates (`si-morning-summary.sh:1180-1186`). But `_split_row_fields` splits on every `|`, including the `\|` that `append_approved_hypotheses` writes for pipes in hypothesis text (`hyp="${hyp//|/\\|}"`, `si-functions.sh:535`):

```bash
# scripts/lib/si-morning-summary.sh:1497-1501 (excerpt ends :1501; enclosing _split_row_fields() continues to :1509 — read)
_split_row_fields() {
    local line="$1"
    local -n out_ref="$2"
    local -a raw
    IFS='|' read -ra raw <<< "$line"
```

Probe: an old row `… other \| piped … | x |` reads Run = `x` (its Evidence cell), and a new row `… new \| piped row … | 2026-09-21 |` reads Run = `''` (its real run lost). Precise version: "rows with no Run cell — and rows whose hypothesis contains a pipe, whose cells shift — resolve newest-first; a shifted cell can be read as a bogus run id." Impact is bounded: a bogus id finds no `archive/<id>-…` file and falls through.

**Evidence:** `scripts/lib/si-morning-summary.sh:1497-1541,1156-1188`, `scripts/lib/si-functions.sh:535-538`; `bash $SCRATCH/probe_split.sh` (exit 0, ~19:32 -07:00) → `$SCRATCH/probe_split.out`; `bats test/precondition-gate.bats` 36/36 ok → `$SCRATCH/precondition-gate.log`.

---

## Claim 13: `_find_tasks_file` — "With a run id … tries that run's archived copy first, then the live file when the live working dir belongs to that run … In every case the first candidate that actually contains task id $2 wins."

**Location:** `scripts/lib/si-morning-summary.sh:1158-1188`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers candidate order and the task-id filter; does not establish `_days_since_round`'s run branch, which selects a report by existence only, with no task-id check (documented as such at `:1326-1328`).
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

The loop body (paraphrased — no quote available because the grep/jq test body sits between :1173 and :1179 and is unchanged by this diff) returns the first existing candidate containing the id. `_live_run_matches` returns true when the run is empty, the file is absent, or ids match (`:1150-1156`).

**Evidence:** `scripts/lib/si-morning-summary.sh:1144-1188`.

---

## Claim 14: health-check gate 5 — "The fast set is a blocking pre-gate: if it is red, the slow set is not run at all … The gate fails if either set is red"; recursion guard via HEALTH_CHECK_SKIP_BATS, skip "with a warning, never a pass"

**Location:** `scripts/health-check.sh:343-391`; commit `0ccbdb8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering, blocking, skip, and failure accounting of `check_bats` via the stub-runner tests; does not establish the wall-clock cost of a real full run.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/health-check.sh:381-390 (excerpt ends :390; enclosing check_bats() ends :391 — read)
    if ! HEALTH_CHECK_SKIP_BATS=1 "$runner" --fast; then
        fail "Fast BATS suites failed — slow suites not run (fix fast first)"
        return
    fi
    pass "Fast BATS suites passed"

    if HEALTH_CHECK_SKIP_BATS=1 "$runner" --slow; then
        pass "Slow BATS suites passed"
    else
        fail "Slow BATS suites failed"
```

The skip branch calls `warn`, not `pass` (`:369-372`). `test/scripts/health-check.bats` carries `# @category slow` and exports `HEALTH_CHECK_SKIP_BATS=1` (`:19`); its four gate-5 tests assert fast→slow order, red-fast blocks slow, red-slow fails, and skip-is-not-pass. The suite run passed 17/17, exit 0, gate-5 tests 14–17 included. `link-claude-home-wiring.bats` is `# @category slow`, matching the `:535-536` comment. "~40 suites under test/ and test/scripts/" (`:352`): 44 `.bats` files there.

**Evidence:** `scripts/health-check.sh:20-26,343-391,532-536`, `test/scripts/health-check.bats:14-19,144-215`, `scripts/run-tests.sh:43-70,80-115`; `bats test/scripts/health-check.bats` (cwd /workspace, 2026-09-21T19:30:14 → 19:37:42 -07:00, exit 0, 17 ok) → `$SCRATCH/hc-bats.log`.

---

## Claim 15: "Fast test suite green (794 ok)"

**Location:** commit `5928c47` message
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the count of `@test` blocks in fast-tagged, non-report-gated suites at `5928c47` (the set `run-tests.sh --fast` runs without generated reports); does not establish that all 794 passed at that commit (not re-run; would require a checkout).
**Legibility-target:** for-automated-gate

Counting `^@test` over `git ls-tree 5928c47 test` files tagged `# @category fast`, excluding `*-format.bats`/`*-eval.bats` (the gating in `scripts/run-tests.sh:96-104`): 794 at `5928c47`, 826 at HEAD. The stated denominator matches exactly.

**Evidence:** `scripts/run-tests.sh:43-115`; count script (session, exit 0, ~19:33 -07:00).

---

## Claim 16: "Macro × Cold | Low (matches the hot-path gate; escalate when the cold path blocks a latency-sensitive operation or runs over large data, e.g. a nightly batch)"

**Location:** `skills/performance-reviewer/SKILL.md:283`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between the matrix row and the hot-path gate text; does not establish Micro × Hot's consistency with the gate.
**Legibility-target:** for-author

The gate is at `:46`: "Code in cold paths … should default to Low or Informational unless the cold path blocks a latency-sensitive operation." The default (Low) and the latency escalation match. The row's second escalation, "or runs over large data, e.g. a nightly batch", is not in the gate; commit `40f21fc` says it was added deliberately. Precise version: "matches the gate's default, and adds a large-data escalation the gate does not name" — or add that clause to `:46`.

**Evidence:** `skills/performance-reviewer/SKILL.md:46,276-287`; commit `40f21fc`.

---

## Claim 17: fact-check — "a verdict resting only on `[abstract]` reads caps at Medium"; "There is no Medium → Low step for `[abstract]` reads"; all-scrutiny-`[inferred]` keeps the one-tier downgrade

**Location:** `skills/fact-check/SKILL.md:179-181,376-377,414-420`; commit `be30668`
**Type:** Behavioral (spec consistency)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers internal consistency of the step-5 text, the `[abstract]`/`[deep-read]` tag definitions, the aggregation rule, the tension paragraph, and the examples table; does not establish downstream consumers (e.g. draft-review) using the same rule.
**Legibility-target:** for-orchestrator-synthesis

Aggregation rule: "If no cited source is `[deep-read]` and at least one is `[abstract]`, the verdict **caps at Medium** … There is no Medium → Low step for `[abstract]` reads" (`:414-417`), and "If every cited source is scrutiny `[inferred]` … downgrade by one tier" (`:418-420`). A grep for `downgrade|one tier|Medium → Low` finds no remaining contradicting sentence. The examples row now reads `Accurate | Low | [inferred] | [abstract]` (`:461`), a valid verdict. The cross-refs `#scrutiny-and-confidence-aggregation`, `#derivation-rule`, `#code-based-claims`, and the `[load-bearing]`/`[peripheral]` tags (`:111,115`) exist.

**Evidence:** `skills/fact-check/SKILL.md:102-145,176-181,362-461`.

---

## Claim 18: "[qualifying author note](../skills/code-review/references/rubric.md#-must-address)"

**Location:** `workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the anchor exists as a rendered heading; does not establish other links in the two files (all others resolved).
**Legibility-target:** for-author

`## 🟡 Must Address` (`skills/code-review/references/rubric.md:49`) sits inside the template's ```` ```markdown ```` fence, which opens at `:31` and closes at `:158`. Headings inside a fenced code block are not rendered and get no anchor, so `#-must-address` does not resolve on GitHub; the link lands at the top of `rubric.md`. Both links were added in this diff (absent at e8d5fa1). A fence-aware anchor check over every changed `.md` found only these two unresolved; a naive heading scan finds 0, which is why a structural checker would miss it.

**Evidence:** `skills/code-review/references/rubric.md:31,49,158`; `python3 $SCRATCH/anchors_fenced.py <changed .md files>` (cwd /workspace, exit 0, 2026-09-21T19:32:12-07:00) → `$SCRATCH/anchors_fenced.out`.

---

## Claim 19: self-eval "stops with a message when the rubric is missing"; draft-review "dispatches all three automatically"; code-review's `Accepted-immutable` rows cite "the immutable-history exception in rubric.md#unified-severity-mapping"

**Location:** `global-instructions/CLAUDE.md` (Standalone/Repo-only skills), `guides/skill-trigger-guide.md`, `skills/code-review/SKILL.md`, `skills/code-review/references/override-log.md`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the referenced instruction text and sections exist; does not establish agent compliance with them at runtime.
**Legibility-target:** for-orchestrator-synthesis

`skills/self-eval/SKILL.md` now says "If `docs/evaluation-rubric.md` does not exist in the current project, stop before scoring and tell the user …". `skills/draft-review/SKILL.md:92` selects "`business-plan-critique-moat`, `business-plan-critique-unit-economics`, AND `business-plan-critique-market-sizing` (run all three …)". `**Immutable-history exception:**` is at `rubric.md:319`, inside `### Unified Severity Mapping` (`:272-341`, outside the fence).

**Evidence:** `skills/self-eval/SKILL.md`, `skills/draft-review/SKILL.md:10,34,92`, `skills/code-review/references/rubric.md:272,319-321`.

---

## Claim 20: "NOT --bare … a --bare call on a subscription-only machine prints 'Not logged in' and still exits 0, so it fails silently. Verified 2026-08-15"

**Location:** `scripts/lite-review.py:17-23`
**Type:** Behavioral (external)
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the invocation omits `--bare`; does not establish the CLI's `--bare` auth behaviour, which needs a live `claude` run against subscription credentials.
**Legibility-target:** for-orchestrator-synthesis

The call is `["claude", "-p", "--model", model, "--output-format", "json", "--system-prompt", SYSTEM_PROMPT, "--tools", "", "--no-session-persistence"]` (`scripts/lite-review.py:157-163`), with no `--bare`, consistent with the docstring. The "Not logged in, exit 0" behaviour matches `docs/working/crb-direction1-setup.md:107` but was not re-run: execution would spend a subscription call and depends on external CLI/auth state.

**Evidence:** `scripts/lite-review.py:13-25,153-173`, `docs/working/crb-direction1-setup.md:107`.

---

## Claims Requiring Attention

### Incorrect
- **Claim 2b** (`hooks/guard-trusted-writes.py:15-17`, `:84-108`; commit 4c7a2bb "Global paths are unchanged"): with `~/.claude/hooks` and `~/.claude/CLAUDE.md` symlinked into `/opt/claude-workflows`, a tainted Edit of `~/x/../.claude/hooks/*`, `~/.claude/x/../CLAUDE.md`, or those files via a project `.claude` → `~/.claude` symlink now returns **ask** (was defer), which overrides permissions.deny (#39344). Fix: take the HARD test on a `..`-normalized, not symlink-resolved, form (e.g. `os.path.normpath`) and/or resolve `GLOBAL_DIRS` members' children the same way. `~/.claude/x/../hooks/*` → ask predates this diff.
- **Claim 3b** (`hooks/guard-trusted-writes.py:123-129`): `"$HOME"/CLAUDE.md`, `"${HOME}"/`, `${HOME:-}/`, `~//`, `~/./`, `$HOME/.claude/../`, `/home/node//`, `$HOME/"CLAUDE.md"` all write the global file and classify soft (defer/ask, never deny). The old regex denied them. This goes beyond the accepted `cd ~` residual.
- **Claim 18** (`workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`): `rubric.md#-must-address` targets a heading inside a code fence; no rendered anchor exists.

### Mostly Accurate
- **Claim 1** (`hooks/guard-trusted-writes.py:10-12`): HARD covers `~/.claude` *and* `$CLAUDE_CONFIG_DIR`, not one or the other; the linker does not expand `~` in the value while the hook does.
- **Claim 8** (`scripts/questions.sh:314-316`): `init` writes through a dangling symlink at the target path.
- **Claim 12** (`scripts/lib/si-functions.sh:469-475`): rows whose hypothesis contains `\|` read the wrong cell as Run (a bogus id or a lost one).
- **Claim 16** (`skills/performance-reviewer/SKILL.md:283`): the row's large-data escalation is not in the gate it says it matches.

### Unverifiable
- **Claim 20** (`scripts/lite-review.py:17-23`): needs a live `claude -p --bare` run on subscription-only credentials.

### Legibility targets
- Claim 1: for-author
- Claim 2a: for-orchestrator-synthesis
- Claim 2b: for-author
- Claim 3a: for-orchestrator-synthesis
- Claim 3b: for-author
- Claim 4: for-orchestrator-synthesis
- Claim 5: for-orchestrator-synthesis
- Claim 6: for-automated-gate
- Claim 7: for-orchestrator-synthesis
- Claim 8: for-author
- Claim 9: for-orchestrator-synthesis
- Claim 10: for-orchestrator-synthesis
- Claim 11: for-orchestrator-synthesis
- Claim 12: for-author
- Claim 13: for-orchestrator-synthesis
- Claim 14: for-orchestrator-synthesis
- Claim 15: for-automated-gate
- Claim 16: for-author
- Claim 17: for-orchestrator-synthesis
- Claim 18: for-author
- Claim 19: for-orchestrator-synthesis
- Claim 20: for-orchestrator-synthesis

### Routing note
Claim 2b's "Global paths are unchanged" sits in the already-merged-locally commit message `4c7a2bb`. Its code half is fixable in `hooks/guard-trusted-writes.py`, so it is a normal finding. Only the commit-message sentence qualifies for an `Accepted-immutable` row if the orchestrator records one. No hallucination-pattern entry is warranted: all Incorrect verdicts are behavioural or anchor mismatches, not fabricated symbols.

---

## Goal-Alignment Note

- **Answered.** Every item the brief listed was checked: (1) guard tiers and Bash regex, probed end to end with quoting, `//`, `/./`, `..`, `${HOME:-}`, relative and `~` `CLAUDE_CONFIG_DIR`, and a symlinked project `.claude`; (2) the HOME="/" comment; (3) the `{{CLAUDE_DIR}}` sameness claim; (4) questions.sh resolution, `init`, and installed-path docs; (5) SI_RUN_ID validation, the archive reader, the migration, and the absent-Run readers; (6) gate 5 and the commit-message counts; (7) the fact-check, performance-reviewer, code-review references, and pr-prep/review-fix-loop anchors. The two security-relevant results are Claims 2b and 3b. Both are concrete bypasses beyond the accepted `cd ~` residual, and 2b reintroduces the #39344 ask-overrides-deny path the docstring says must never happen.
- **Out of scope.** The DD/Double-Diamond doc rewrites, `questions-archive.md` content, and archive moves were not claim-checked line by line; they are low-risk per the brief. The `.claude//settings` / `.claude/./hooks` Bash fragment variants (Claim 5 residue) were not probed.
- **Escalate.** The captured outputs live in the session scratchpad rather than `docs/reviews/execution-logs/`, because the brief forbids other repo writes. Copy them in if durable provenance is wanted. `bats test/scripts/health-check.bats` finished 17/17 ok (exit 0), so Claim 14 is backed by that run.
