**Commit:** 16f2978

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** `git diff f023357..answers-2026-09-20` (partial: iteration-2 fix commits only; commits in `main..f023357` read as context, not verdicted). Replicate r3.
**Checked:** 2026-09-21
**Total claims checked:** 27
**Summary:** 17 verified, 6 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Execution logs (scratch, untracked): `/tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/cfc-r3/` — `probe.py` (feeds a Bash payload to the repo hook with `HOME=/home/tester`, `CLAUDE_CONFIG_DIR` unset, taint dir nonexistent), `probe_file.py` (file-tool payloads, tainted), `probe1.out`..`probe4.out`, `pre/` (the new bats file run against `hooks/guard-trusted-writes.py` at `c5a7c96^`), `qs/` (questions.sh symlink probe), `health-check-bats.log`. All probes ran 2026-09-21T20:24-20:30-07:00, cwd noted per claim, no network inputs.

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no claim below matches a logged pattern, and no Incorrect verdict below is a fabricated symbol, so no log entry is added.

---

## Claim 1: "HARD = exactly what permissions.deny covers (hooks/wiring.json) … A path is HARD if its lexical form, its normpath (`..` folded), or its resolve() lands there — including a resolve() onto the target of a symlinked global entry"

**Location:** `hooks/guard-trusted-writes.py:10-21` (repeated at `:104-107`, `_is_hard` docstring)
**Type:** Invariant / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the file-tool HARD set versus the eight Edit/Write deny rules in `hooks/wiring.json:120-127`; does not establish whether Claude Code's deny matcher is case-insensitive or resolves symlinks (which would close the gap), nor Bash-tier behaviour.

The deny rules are case-sensitive globs on the unresolved path:

```
// hooks/wiring.json:120-127
"Edit({{CLAUDE_DIR}}/settings*.json)", ... "Edit({{CLAUDE_DIR}}/hooks/**)", ...
"Edit({{CLAUDE_DIR}}/CLAUDE.md)", ... "Edit(~/CLAUDE.md)", "Write(~/CLAUDE.md)"
```

`_is_hard` case-folds every component, and `classify_path` adds the resolved link targets:

```python
# hooks/guard-trusted-writes.py:108-119 (whole function)
    rel = _global_rel(cand)
    if rel is not None and rel.parts:
        first = rel.parts[0].lower()
        if first == "hooks":
            return True
        if len(rel.parts) == 1 and first.startswith("settings") and first.endswith(".json"):
            return True
        if len(rel.parts) == 1 and first == "claude.md":
            return True
    if cand.name.lower() == "claude.md" and cand.parent == HOME:
        return True
    return False
# hooks/guard-trusted-writes.py:133-134
    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
        return "hard"
```

So HARD is a strict superset of the deny coverage: `~/.claude/HOOKS/x`, `~/.claude/Settings.json`, `~/.claude/claude.md`, and the resolved payload paths `/opt/claude-workflows/CLAUDE.md` and `/opt/claude-workflows/hooks/*` are HARD → defer, but no deny rule literally names them. Executed (tainted session, real HOME `/home/node`): current hook `defer` for all five; pre-fix hook (`c5a7c96^`) returned `ask` for `/opt/claude-workflows/CLAUDE.md` and `~/.claude/HOOKS/x`. In this install `/opt/claude-workflows` is `dr-xr-xr-x root` (so the /opt case is not writable, matching the commit's "installed /opt payload is unaffected"), and the case-variant names are not files Claude Code loads, so the practical exposure is small. The precise statement is "HARD ⊇ permissions.deny coverage (case-folded, plus resolved link targets), and anything HARD-but-not-denied is left ungated".

**Evidence:** `hooks/guard-trusted-writes.py:10-21`, `:86-93`, `:104-134`; `hooks/wiring.json:120-127`; command `python3 probe_file.py <hook> /opt/claude-workflows/CLAUDE.md … /etc/claude-code/managed-settings.json` (cwd scratchpad/cfc-r3, exit 0, 2026-09-21T20:26-07:00; output captured in this report's run transcript, reproduced by re-running `probe_file.py`)

---

## Claim 2: "The global tier is therefore decided by CO-OCCURRENCE in the text: HARD = any `.claude/hooks`, `.claude/settings`, managed-settings fragment; OR a CLAUDE.md mention … together with ANY home/global indicator … OR a settings*.json / hooks mention together with `.claude` / the config dir."

**Location:** `hooks/guard-trusted-writes.py:28-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the regex logic of `bash_targets` once a write primitive has matched; does not establish that every write reaches that logic (WRITE_PRIMITIVE gaps are A8, settled) or that the co-occurrence catches every home spelling (see Claim 8).

```python
# hooks/guard-trusted-writes.py:190-205 (whole function)
def bash_targets(cmd: str):
    has_write = bool(WRITE_PRIMITIVE.search(cmd))
    if not has_write:
        return None
    if HARD_FRAG.search(cmd):
        return "hard"
    if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):
        return "hard"
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
    if SOFT_FRAG.search(cmd):
        return "soft"
    return None
```

The indicator lists at `:171-182` match the docstring (`~`, `$HOME`, `${HOME`, `.claude`, `global-instructions`, `CLAUDE_CONFIG_DIR`, plus escaped literal home/config paths; CFG = `.claude`, `CLAUDE_CONFIG_DIR`, literal config dir). Probe: `echo x > ~/proj/hooks/a.sh` and `echo x > $HOME/proj/settings.json` defer (no CFG indicator), `cp x /workspace/.claude/wt-a/hooks/y` denies — as described.

**Evidence:** `hooks/guard-trusted-writes.py:171-205`; `probe3.out` (command `python3 probe.py cmds3.txt`, cwd scratchpad/cfc-r3, exit 0, 2026-09-21T20:29-07:00)

---

## Claim 3: "The ONE global config dir: exactly what the linker substitutes as {{CLAUDE_DIR}} … an empty value falls back, `~` is NOT expanded, and there is no second dir … A relative value is anchored at the hook's cwd"

**Location:** `hooks/guard-trusted-writes.py:63-73` (and commit `c5a7c96` R3 paragraph)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the absolute, empty, unset and `~`-containing values; does not establish equality for a relative CLAUDE_CONFIG_DIR, where the two sides anchor differently.

```bash
# devcontainer-config/link-claude-home.sh:36
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
```
```python
# hooks/guard-trusted-writes.py:72-73 (whole function body)
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    return Path(os.path.abspath(cfg)) if cfg else HOME / ".claude"
```

Empty → fallback, no `~` expansion, single dir: all match (bats R3 tests 42-44 pass). The one divergence the word "exactly" hides: the linker substitutes the raw string into the deny rules (`gsub("\\{\\{CLAUDE_DIR\\}\\}"; $dir)`, `link-claude-home.sh:137`), so a relative value stays relative there, while the hook anchors it at the hook's cwd. The docstring's own last sentence discloses this, so the mechanism is stated; only "exactly" overreaches.

**Evidence:** `devcontainer-config/link-claude-home.sh:36`, `:137`; `hooks/guard-trusted-writes.py:63-73`; `bats test/hooks/guard-trusted-writes.bats` (cwd /workspace, exit 0, 54/54 ok, 2026-09-21T20:25-07:00)

---

## Claim 4: "In the installed layout ~/.claude/hooks and ~/.claude/CLAUDE.md are symlinks into /opt/claude-workflows" / the bats installed-layout fixture models it

**Location:** `hooks/guard-trusted-writes.py:82-85`; `test/hooks/guard-trusted-writes.bats` `install_layout()`
**Type:** Architectural
**Verification mode:** executed
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers this sandbox's `~/.claude` and the fixture's two symlinks plus a real settings.json; does not establish other install variants (e.g. a checkout as payload).

`ls -la ~/.claude` shows `CLAUDE.md -> /opt/claude-workflows/CLAUDE.md`, `hooks -> /opt/claude-workflows/hooks`, and a regular `settings.json`. The fixture builds the same shape:

```bash
# test/hooks/guard-trusted-writes.bats (install_layout, whole function)
  PAYLOAD="$TEST_TMPDIR/opt/claude-workflows"
  mkdir -p "$PAYLOAD/hooks" "$HOME/.claude"
  echo '# global' > "$PAYLOAD/CLAUDE.md"
  echo 'x' > "$PAYLOAD/hooks/foo.sh"
  ln -s "$PAYLOAD/hooks" "$HOME/.claude/hooks"
  ln -s "$PAYLOAD/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  echo '{}' > "$HOME/.claude/settings.json"
```

**Evidence:** `hooks/guard-trusted-writes.py:82-93`; `test/hooks/guard-trusted-writes.bats` install_layout; `ls -la ~/.claude` (cwd /workspace, exit 0, 2026-09-21T20:24-07:00)

---

## Claim 5: "pathlib already collapses `//` and `/./`; normpath also folds `..` lexically, so `~/.claude/x/../CLAUDE.md` is seen as `~/.claude/CLAUDE.md` (R4)"

**Location:** `hooks/guard-trusted-writes.py:123-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the file-tool candidates for `//`, `/./` and `..`; does not establish behaviour for paths whose `..` crosses a symlink (normpath and resolve() then disagree — both are checked, so HARD wins).

```python
# hooks/guard-trusted-writes.py:122-127
    p = Path(os.path.expanduser(str(fp)))
    norm = Path(os.path.normpath(str(p)))
    rp = _safe_resolve(p)
    cands = (p, norm, rp)
```
Bats R4 tests 46-48 (`$HOME/.claude/x/../CLAUDE.md`, `//CLAUDE.md`, MultiEdit `path` key) pass on the current hook and fail on `c5a7c96^`.

**Evidence:** `hooks/guard-trusted-writes.py:121-134`; `pre/` run (cwd scratchpad/cfc-r3/pre, `bats test/hooks/guard-trusted-writes.bats`, exit 1, 2026-09-21T20:26-07:00)

---

## Claim 6: "managed-settings.json moves to SOFT for the file tools: no deny rule covers it, so deferring left it ungated"

**Location:** `hooks/guard-trusted-writes.py:22-25`, `:135-144`; commit `c5a7c96`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the file-tool and Bash decisions for `/etc/claude-code/managed-settings.json`; does not establish whether Claude Code honours writes to that path at all.

No `managed-settings` string appears in `hooks/wiring.json:115-128`. Executed (tainted): pre-fix hook `defer`, current hook `ask` — no regression, a gate was added. Bash still denies via `HARD_FRAG = re.compile(r"…|managed-settings", re.I)` (`:185`).

**Evidence:** `hooks/guard-trusted-writes.py:135-147`, `:185`; `hooks/wiring.json:115-128`; `probe_file.py` run (cwd scratchpad/cfc-r3, exit 0, 2026-09-21T20:26-07:00)

---

## Claim 7: "Covers "$HOME"/CLAUDE.md, ~//, ~/./, ~/"CLAUDE.md", ${HOME:-}, $HOME/x/.., ~/.claude//, "$HOME/.claude"/CLAUDE.md, H=~; ... $H/CLAUDE.md and cd ~/.claude && mv x CLAUDE.md … (~/.claude//settings.json, ~/".claude"/settings.json, cd ~/.claude && ... > settings.json)"

**Location:** commit `c5a7c96` message (R1, A10); `hooks/guard-trusted-writes.py:166-170`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers exactly the 13 listed spellings (untainted, HOME=/home/tester) plus the bats loops; does not establish the broader "no longer depends on exact path spellings" claim (Claim 8).

All 13 listed spellings return `deny` (`probe1.out` lines 1-13); all 18 bats-loop spellings return `defer` on the pre-fix hook (`probe2-pre.out`).

**Evidence:** `probe1.out`, `probe2-pre.out` (commands `python3 probe.py cmds.txt` / `python3 probe_pre.py cmds2.txt`, cwd scratchpad/cfc-r3, exit 0, 2026-09-21T20:24-20:26-07:00)

---

## Claim 8: "the global CLAUDE.md tier no longer depends on exact path spellings … The residual: shell obfuscation of the file name itself (CLAUDE.m*, C${x}.md) and A8 primitives are still unguarded."

**Location:** commit `c5a7c96` message (R1 paragraph and Notes)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers Bash commands that do match WRITE_PRIMITIVE and name the target file literally; does not establish exploitability in a live session (the installed hook is an older copy) — the claim tested is the completeness of the stated residual.

The residual list names only file-name obfuscation and A8, but these commands, each with a recognised write primitive and a literal `CLAUDE.md`/`settings.json`, return `defer` (untainted: no opinion; and Bash has no deny rule behind it):

```
defer  | cd; echo x > CLAUDE.md            # bare `cd` = home, no indicator
defer  | cd && echo x > CLAUDE.md
defer  | echo x > /home/$USER/CLAUDE.md
defer  | echo x > /home/*/CLAUDE.md
defer  | cd /home && echo x > tester/CLAUDE.md
defer  | echo x > ~/.clau""de/settings.json # obfuscated DIR name, not file name
defer  | cd ~/.cl*e && echo x > settings.json
defer  | cd ~/.cl?ude/hooks && echo x > h.sh
defer  | cp x ~/.clau\de/settings.json
```
(quoted from `probe1.out`; HOME=/home/tester.) Obfuscating the `.claude` directory component, a bare `cd`, and `$USER`/glob/relative home spellings are residual bypasses the message does not name. The code comment at `hooks/guard-trusted-writes.py:166-170` makes no completeness claim; this is a commit-message claim (the commit is merged into `answers-2026-09-20` via `1759fc8`, so the orchestrator may treat it under the immutable-history rule; the live residue then belongs in Q-048 or a TODO).

**Evidence:** `hooks/guard-trusted-writes.py:171-205`; `probe1.out` (command `python3 probe.py cmds.txt`, cwd scratchpad/cfc-r3, exit 0, 2026-09-21T20:24:57-07:00)

---

## Claim 9: "Tests: 18 new bats cases"

**Location:** commit `c5a7c96` message
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Counts `@test` blocks added by c5a7c96; does not count loop iterations inside tests.

`git diff c5a7c96^ c5a7c96 -- test/hooks/guard-trusted-writes.bats | grep -c '^+@test'` → `14` (R1 ×5, A10 ×1, R3 ×4, R4 ×4). No count of 18 is reachable (loops contain 13 + 5 + 6 + 4 iterations).

**Evidence:** `test/hooks/guard-trusted-writes.bats` (R1..R4 sections); command above (cwd /workspace, exit 0, 2026-09-21T20:26-07:00)

---

## Claim 10: "every new R-test fails against the pre-fix hook"

**Location:** commit `c5a7c96` message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the 14 new tests run with the `c5a7c96^` hook substituted; does not judge whether the passing four are useful regression guards (they are).

Running the current bats file against `git show c5a7c96^:hooks/guard-trusted-writes.py`:

```
ok 39 R1: a heredoc whose prose names ~/.claude/CLAUDE.md is denied (accepted cost)
ok 40 R1: a bare CLAUDE.md with no home indicator stays SOFT
ok 43 R3: an empty CLAUDE_CONFIG_DIR falls back to ~/.claude, as the linker does
ok 49 R4: a real (non-symlinked) project .claude still asks when tainted
```
The other ten new tests fail. 4 of 14 pass pre-fix.

**Evidence:** `pre/` (command `bats test/hooks/guard-trusted-writes.bats`, cwd scratchpad/cfc-r3/pre, exit 1, 2026-09-21T20:26-07:00)

---

## Claim 11: "Each of these returned no opinion (untainted) or ask (tainted) at 4c7a2bb."

**Location:** `test/hooks/guard-trusted-writes.bats` (comment heading the R1 section)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the untainted half for all 18 loop spellings on the `c5a7c96^` hook (last hook commit 4c7a2bb); does not separately execute the tainted half.

All 18 spellings from the R1/A10 loops return `defer` on the pre-fix hook (`probe2-pre.out`).

**Evidence:** `probe2-pre.out` (command `python3 probe_pre.py cmds2.txt`, cwd scratchpad/cfc-r3, exit 0, 2026-09-21T20:26-07:00)

---

## Claim 12: "Writes never go through a symlink." / "Refuse a write destination that is, or resolves through, a symlink … An explicit QUESTIONS_LIVE/QUESTIONS_ARCHIVE is … exempt from the containment check but not from the symlink check."

**Location:** `scripts/questions.sh:47-51`, `:84-90`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers `init` with overrides whose path passes through a symlinked ancestor, and the default path with the same ancestor; does not establish exploitability (the override is set by the operator; the planted ancestor comes from the repo).

The "symlink check" inspects only the file and its immediate directory:

```bash
# scripts/questions.sh:92-103 (assert_write_target, whole body)
    local file="$1" overridden="$2" dir root resolved
    dir="$(dirname "$file")"
    [[ -L "$file" ]] && die "refusing to write: $file is a symlink"
    [[ -L "$dir" ]] && die "refusing to write: directory $dir is a symlink"
    if [[ -z "$overridden" ]]; then
        root="$(realpath -m -- "$PROJECT_ROOT")"
        resolved="$(realpath -m -- "$file")"
        [[ "$resolved" == "$root"/* ]] \
            || die "refusing to write: $file resolves to $resolved, outside $root"
    fi
    return 0
```

Executed: repo with `docs -> ../elsewhere`, `QUESTIONS_LIVE=$PWD/docs/working/questions.md` (and archive likewise) → `init` printed `+ created: …/repo/docs/working/questions.md`, exit 0, and both files appeared in `elsewhere/working/`. Without overrides the same layout is refused (`resolves to …/elsewhere/working/questions.md, outside …/repo`, exit 1). So default paths are protected by containment, but an override "resolves through" a symlinked ancestor unrefused, and "Writes never go through a symlink" is false (also for default paths through an in-root symlinked ancestor, which containment allows).

**Evidence:** `scripts/questions.sh:47-51`, `:84-107`; `qs/` probe (cwd scratchpad/cfc-r3/qs/repo, `bash /workspace/scripts/questions.sh init`, exit 0 with overrides / exit 1 without, 2026-09-21T20:26-07:00)

---

## Claim 13: "The temp file comes from mktemp in the target's own directory (O_EXCL …), takes the target's mode, and is renamed over the target only after the symlink checks pass again immediately before the rename."

**Location:** `scripts/questions.sh:109-125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `replace_with` as called from `render_index` and `cmd_archive`; does not establish ancestor-symlink safety (Claim 12) or inode preservation (the rename replaces it by design).

```bash
# scripts/questions.sh:115-125 (replace_with, whole function)
replace_with() {
    local target="$1" tmp; shift
    tmp="$(mktemp "$(dirname "$target")/.questions.XXXXXX")"
    if ! "$@" > "$tmp"; then rm -f "$tmp"; return 1; fi
    chmod --reference="$target" "$tmp" 2>/dev/null || true
    if [[ -L "$target" || -L "$(dirname "$target")" ]]; then
        rm -f "$tmp"; die "refusing to write: $target became a symlink"
    fi
    mv -f -- "$tmp" "$target"
}
```
bats `questions-doc.bats` tests 22, 23, 26 (symlinked archive, planted `.tmp`, mode preserved) pass.

**Evidence:** `scripts/questions.sh:115-125`; `bats test/questions-doc.bats` (cwd /workspace, all 26 ok, 2026-09-21T20:27-07:00)

---

## Claim 14: "Every command except `init` needs both files to exist and fails, pointing at `init`, when they don't"

**Location:** `scripts/questions.sh:40-43`, `:128-135`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the five subcommands in a fresh git repo with no docs; does not cover the no-argument usage path (exits 1 printing usage, not a missing-file error).

In an empty repo: `next-id rc=1`, `index rc=1`, `archive rc=1`, `open rc=1`, `check rc=1`. `check` fails via `[[ -f "$file" ]] || { echo "  ✗ missing: $file" >&2; rc=1; continue; }` (`:233`) and prints the init pointer at `:297-299`; the others via `require_files`.

**Evidence:** `scripts/questions.sh:128-135`, `:229-301`, `:342-409`; loop over subcommands (cwd scratchpad/cfc-r3/qs2, 2026-09-21T20:27-07:00)

---

## Claim 15: "Inside .git/ there is no toplevel, so the $PWD fallback below would create .git/docs/working/"

**Location:** `scripts/questions.sh:74-78`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `init` run with cwd `.git/`; does not cover cwd inside a worktree's gitdir under `.git/worktrees/`.

`init` from `qs2/.git` printed `✗ questions.sh: $PWD (…/qs2/.git) is inside a .git directory; run from the working tree instead`; `qs2/.git/docs` does not exist afterwards.

**Evidence:** `scripts/questions.sh:74-78`; probe (cwd scratchpad/cfc-r3/qs2/.git, 2026-09-21T20:27-07:00)

---

## Claim 16: "First column only: a summary may itself mention another entry's ID."

**Location:** `scripts/questions.sh:289-290` (commit `42bf2fc`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers index rows emitted by `render_index`; does not cover hand-edited index rows with different spacing.

```bash
# scripts/questions.sh:290
have_ids="$(sed -n "/$INDEX_START/,/$INDEX_END/p" "$file" | grep -ao '^| \[Q-[0-9]\{3\}\]' | grep -ao 'Q-[0-9]\{3\}' | sort -u || true)"
```
matches the rows written at `:321-322` (`printf '| [%s](#%s--%s) | …'`). `scripts/questions.sh check` on the repo → `✓ questions: structure valid, indexes current`, rc=0.

**Evidence:** `scripts/questions.sh:285-301`, `:305-340`; `scripts/questions.sh check` (cwd /workspace, exit 0, 2026-09-21T20:25-07:00)

---

## Claim 17: "create with noclobber, whose O_EXCL open fails rather than following anything that appeared at the path in between"

**Location:** `scripts/questions.sh:428-430`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers bash noclobber against a dangling symlink and a symlink to an existing non-regular file; does not assess how reachable the race window is.

Bash noclobber refuses an existing regular file and uses O_EXCL only when `stat` fails; a symlink to an existing non-regular file is opened and followed. Executed: `ln -s /dev/null ncl; bash -c 'set -o noclobber; printf x > ncl'` → rc=0 (followed); dangling link → `cannot overwrite existing file`, rc=1, target not created. Precise version: "fails on a dangling link or anything resolving to a regular file; a link to a device/FIFO is followed".

**Evidence:** `scripts/questions.sh:415-440`; probe (cwd scratchpad/cfc-r3, 2026-09-21T20:30-07:00)

---

## Claim 18: "Date plus time of day (YYYY-MM-DD-HHMMSS) … Zero-padded fields keep ids lexically sortable in start order, which _archived_newest_first relies on."

**Location:** `scripts/lib/si-functions.sh:461-471`; `scripts/self-improvement.sh:43`, `:451-459`; `scripts/archive-working-docs.sh:8`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers ordering among timestamped ids and `self-improvement.sh` sourcing the helper before use (`source` at `:228`, use at `:459`); does not establish ordering between a legacy date-only id and a timestamped id of the same day (`2026-03-25-0…` sorts before `2026-03-25-t…`, so the legacy one reads as newer), nor custom SI_RUN_ID values.

```bash
# scripts/lib/si-functions.sh:469-471
si_default_run_id() {
    date +%F-%H%M%S
}
```
`_archived_newest_first` reverses glob order (`scripts/lib/si-morning-summary.sh:1132-1143`). bats `append-approved-hypotheses.bats` (format, same-day distinct) and `archive-working-docs.bats` (two same-day runs side by side) pass.

**Evidence:** `scripts/lib/si-functions.sh:461-471`; `scripts/lib/si-morning-summary.sh:1125-1143`; `scripts/self-improvement.sh:227-228`, `:451-463`; bats run of four suites (cwd /workspace, 96/96 ok, 2026-09-21T20:27-07:00)

---

## Claim 19: "True no-op (the file is not opened for writing) when the header already has a Run cell or no header is found. A real migration rewrites the file in place (temp file, then `cat tmp > file`), so the log keeps its inode and mode"

**Location:** `scripts/lib/si-functions.sh:558-561` (commit `685030e`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three header states; does not cover interruption mid-`cat` (a truncated log is possible then, unlike `mv`).

```bash
# scripts/lib/si-functions.sh:569-588 (excerpt; function continues to :589 — read)
    local state=0
    awk -F'|' '/^\|/ && / Round / { hdr = 1 ... exit
        } END { if (!hdr) exit 2; exit !found }' "$log_file" || state=$?
    [ "$state" -eq 1 ] || return 0
    ...
    ' "$log_file" > "$tmp" && cat "$tmp" > "$log_file" || rc=$?
    rm -f "$tmp"
    return "$rc"
```
New bats tests (inode+mode preserved, no leftover temp; mtime/inode/mode unchanged in both no-op cases) pass.

**Evidence:** `scripts/lib/si-functions.sh:555-589`; bats `test/append-approved-hypotheses.bats` (cwd /workspace, exit 0, 2026-09-21T20:27-07:00)

---

## Claim 20: "Accept only the charset self-improvement.sh and archive-working-docs.sh enforce on the writer side (no `/`, so the id can never leave archive/ — it is always glued to a "-<name>" suffix)"; applied at the row reader, `_find_tasks_file`, `_days_since_round`

**Location:** `scripts/lib/si-morning-summary.sh:1145-1156`, `:1018`, `:1189`, `:1350`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every grep hit for `run_col`/`row_run`/`_live_run_matches` in `scripts/`; does not cover other future readers of the Run column.

`_valid_run_id` is `[[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]`, identical to `self-improvement.sh:460` and `archive-working-docs.sh:45`. It is called at the only Run-cell reader (`:1018`) and at the top of both path builders (`:1189`, `:1350`); `..` alone yields `archive/..-tasks-round-N.json`, still inside archive/. bats A6(c) tests (`../../outside/x` ignored) pass.

**Evidence:** `scripts/lib/si-morning-summary.sh:1010-1031`, `:1145-1205`, `:1347-1380`; `scripts/archive-working-docs.sh:43-48`; bats `test/precondition-gate.bats` (cwd /workspace, exit 0, 2026-09-21T20:27-07:00)

---

## Claim 21: "When si-run-id.txt is absent or empty … this is false; callers still reach the live files through their newest-first fallback, just not ahead of the row's own archived copy."

**Location:** `scripts/lib/si-morning-summary.sh:1158-1173` (commit `efd66e4`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `_live_run_matches` and its two callers' fallbacks; does not cover a si-run-id.txt with trailing whitespace.

```bash
# scripts/lib/si-morning-summary.sh:1166-1173 (whole function)
    local working_dir="$1" run="$2"
    [ -z "$run" ] && return 0
    [ -f "$working_dir/si-run-id.txt" ] || return 1
    local live
    live=$(head -n1 "$working_dir/si-run-id.txt" 2>/dev/null)
    [ -n "$live" ] && [ "$live" = "$run" ]
```
`_find_tasks_file` still lists `tasks-round-$round.json` after the run-specific candidates (`:1202-1203`); `_days_since_round` falls through to its generic loop. The A6(b) bats cases pass.

**Evidence:** `scripts/lib/si-morning-summary.sh:1158-1205`, `:1347-1380`; bats `test/precondition-gate.bats` (as Claim 20)

---

## Claim 22: "`\|` is swapped for a sentinel before the split and restored afterwards, so the cell keeps its escaped (markdown-safe) text" / "Locals carry a _srf_ prefix so they cannot shadow the caller's array name"

**Location:** `scripts/lib/si-morning-summary.sh:1515-1537` (commit `e6a6a5f`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers rows written by `append_approved_hypotheses` (only the hypothesis is escaped, `si-functions.sh:548`) and caller arrays named `f`/`raw`; does not cover unescaped pipes in Requires/Source cells, which the writer does not escape.

```bash
# scripts/lib/si-morning-summary.sh:1521-1537 (whole function)
    local _srf_line="$1"
    local -n out_ref="$2"
    local -a _srf_raw
    local _srf_sep=$'\x1e'
    _srf_line="${_srf_line//\\|/$_srf_sep}"
    IFS='|' read -ra _srf_raw <<< "$_srf_line"
    out_ref=()
    local _srf_f _srf_t
    for _srf_f in "${_srf_raw[@]}"; do
        _srf_f="${_srf_f//$_srf_sep/\\|}"
        ...
        out_ref+=("$_srf_t")
    done
```
The new `morning-summary-clusters.bats` tests (caller array `f`, cell `a \| b`, Run cell at index 12) pass.

**Evidence:** `scripts/lib/si-morning-summary.sh:1509-1537`; `scripts/lib/si-functions.sh:545-552`; bats `test/morning-summary-clusters.bats` (cwd /workspace, exit 0, 2026-09-21T20:27-07:00)

---

## Claim 23: "ASCII Record Separator: never present in a log row"

**Location:** `scripts/lib/si-morning-summary.sh:1527`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the writer path in `append_approved_hypotheses`; does not establish what task JSON contains in practice.

Nothing enforces it: the hypothesis comes straight from `jq -r` over the tasks file and only `|` is escaped (`hyp="${hyp//|/\\|}"`, `scripts/lib/si-functions.sh:548`); a `\x1e` in hypothesis text would be rewritten to `\|` by the reader. Precise version: "not expected in a log row (not stripped by the writer)".

**Evidence:** `scripts/lib/si-functions.sh:528-552`; `scripts/lib/si-morning-summary.sh:1527-1532`

---

## Claim 24: "make health-check.bats cache hit (405s -> 42s) … Coverage unchanged: same 17 tests, same script runs."

**Location:** `test/scripts/health-check.bats:20-25`; commit `bd07c4e`; Q-023 archive entry (`docs/working/questions-archive.md`)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the cache mechanism, the 17-test count, and one wall-clock run in this sandbox; does not reproduce the 405s baseline or the author's machine load.

Mechanism verified: `_HC_CACHE_DIR="$BATS_FILE_TMPDIR/hc-cache"` is written by `setup_file` and read by `setup()` (`:25-51`); the negative frontmatter tests still run `bash "$SCRIPT"` themselves against an isolated skills copy (`:121-145`), so the cache does not weaken them. Measured: `1..17`, all ok, `59.076 total` — the order-of-magnitude drop holds, the 42s figure did not reproduce here (time-varying).

**Evidence:** `test/scripts/health-check.bats:1-51`, `:100-145`; `health-check-bats.log` (command `time bats test/scripts/health-check.bats`, cwd /workspace, exit 0, 2026-09-21T20:27:49-07:00)

---

## Claim 25: A1/A2/A5/A13 doc fixes — `#qualifying-author-note` anchor resolves; test-strategy mapped by `high` / `medium, low`; override-log.md defines `Accepted-immutable`; hot-path gate text agrees with the Macro × Cold row

**Location:** `skills/code-review/references/rubric.md:156-176`, `:304-308`, `:357`, `:521`; `skills/code-review/SKILL.md:1230`; `docs/reviews/override-log.md:1-47`; `skills/performance-reviewer/SKILL.md:46`, `:283`; `workflows/pr-prep.md:190`; `workflows/review-fix-loop.md:43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the files changed in the diff plus an `rg` over non-review/working `*.md` for the old anchor and P1/P2 mapping; does not re-check docs/reviews or docs/working prose.

`### Qualifying author note` exists (anchor `qualifying-author-note`), both workflow links now target it, and `rg 'rubric\.md#-must-address|test-strategy (P1|P2)'` returns nothing outside reviews/working. test-strategy emits `**Priority:** [high / medium / low]` (`skills/test-strategy/SKILL.md:196`). The override-log's `Accepted-immutable` paragraph matches `skills/code-review/references/override-log.md:20-32` (`#capture-format` exists at `:11`) and the immutable-history exception at `rubric.md:336-341` under `### Unified Severity Mapping` (`:289`); `review-fix-loop.md:157` treats the row as settled. The gate sentence ("or runs over large data (e.g. a nightly batch over a full table), in which case escalate as for a hot path") and the Macro × Cold row ("same exceptions as the hot-path gate") agree.

**Evidence:** files above; `rg` command (cwd /workspace, exit 1 = no matches, 2026-09-21T20:29-07:00)

---

## Claim 26: "a write that names `CLAUDE.md`, `settings*.json` or `hooks` is denied whenever the command also contains `~`, `$HOME`, `.claude`, `global-instructions` or the config dir anywhere. That also denies `git commit` with `HEAD~1` in a CLAUDE.md-mentioning message"

**Location:** `docs/working/questions.md` Q-048 body
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the description of the rule's scope, not the accepted false-deny behaviour itself (settled per brief); does not re-litigate options [1]-[3].

For `settings*.json`/`hooks`, only `.claude` or the config dir counts (`_CFG_INDICATORS = [r"\.claude\b", r"CLAUDE_CONFIG_DIR"]`, `hooks/guard-trusted-writes.py:175`): `echo x > ~/proj/hooks/a.sh` and `echo x > $HOME/proj/settings.json` defer (`probe3.out`). And a `git commit -m "fix CLAUDE.md, revert HEAD~1"` is not denied (no write primitive → defer); it is denied only when the command also carries one, e.g. a `>` in the message (`probe4.out`). The `~`/`$HOME`/`global-instructions` list applies to CLAUDE.md only, as the hook's own docstring (`:30-34`) states correctly.

**Evidence:** `hooks/guard-trusted-writes.py:171-205`; `probe3.out`, `probe4.out` (command `python3 probe.py cmds3.txt|cmds4.txt`, cwd scratchpad/cfc-r3, exit 0, 2026-09-21T20:29-20:30-07:00)

---

## Claim 27: "Discoverable TODO: `# TODO(A8)` at WRITE_PRIMITIVE lists every command."

**Location:** `docs/reviews/override-log.md` (A8 row)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the nine commands named in the row versus the TODO text; does not establish the list is complete against all shell write primitives.

```python
# hooks/guard-trusted-writes.py:150-155
# TODO(A8): write primitives not recognised here (predates Q-035; code-review
# 2026-09-21 A8): `ln -sf`, `curl -o`, `wget -O`, `tar -C` / `tar -x`,
# `unzip -d`, `sponge`, `python3 script.py` (non-inline interpreters),
# `git checkout` / `git restore` over a tracked policy file, and
# `git config --global`. A command that writes only through these gets no
# opinion from this hook.
```

**Evidence:** `hooks/guard-trusted-writes.py:150-164`; `docs/reviews/override-log.md` A8 row

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (commit `c5a7c96`, R1/Notes): stated residual omits live Bash bypasses — bare `cd; … > CLAUDE.md`, `/home/$USER/…`, `/home/*/…`, relative-from-`/home`, and obfuscated `.claude` dir names (`.cla""ude`, `.cl*e`, `.cl?ude`, `.clau\de`) all defer.
- **Claim 9** (commit `c5a7c96`): "18 new bats cases" — 14 were added.
- **Claim 10** (commit `c5a7c96`): "every new R-test fails against the pre-fix hook" — 4 of 14 (tests 39, 40, 43, 49) pass on `c5a7c96^`.
- **Claim 12** (`scripts/questions.sh:47-51`, `:84-90`): "Writes never go through a symlink" / "resolves through a symlink" — with QUESTIONS_LIVE/ARCHIVE set, `init` wrote through a symlinked `docs/` ancestor; the check covers only the file and its immediate dir.

### Stale
- none

### Mostly Accurate
- **Claim 1** (`hooks/guard-trusted-writes.py:10-21`): HARD is a superset of deny coverage (case-folded names, resolved /opt targets), not "exactly" it; `~/.claude/HOOKS/x` went ask→defer.
- **Claim 3** (`hooks/guard-trusted-writes.py:63-73`): "exactly what the linker substitutes" except relative values (disclosed in the same docstring).
- **Claim 17** (`scripts/questions.sh:428-430`): noclobber follows a link to an existing non-regular file (`/dev/null` verified).
- **Claim 23** (`scripts/lib/si-morning-summary.sh:1527`): RS "never present" is unenforced by the writer.
- **Claim 24** (`test/scripts/health-check.bats:20-25`, `bd07c4e`): 42s did not reproduce (59s here); mechanism and coverage verified.
- **Claim 26** (`docs/working/questions.md` Q-048): settings/hooks need `.claude`/config dir, not `~`/`$HOME`; the `git commit … HEAD~1` example is denied only with a write primitive in the command.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/docs/reviews/code-fact-check-report-iter2-r3.md with `**Commit:** 16f2978` at the top, every claim tagged with a Legibility-target (Incorrect/Stale/Mostly Accurate → for-author; Verified/Unverifiable → for-orchestrator-synthesis), ending with a Goal-Alignment Note.
- Answered: brief claims 1-11 (Bash spellings, config_dir/deny parity, R4 fixture and pre-fix test run, questions.sh hardening/missing-file/.git/index parsing, R5 migration, run-id/Run-cell validation, pipe split, health-check caching, A1/A2/A5/A13 docs) plus Q-048 and the A8 override row, each executed where executable.
- Out of scope: commits in `main..f023357`; the accepted Q-048 over-block behaviour and A7/A8 (only their descriptive text was checked); `CLAUDE.m*`/`C${x}.md` file-name obfuscation (accepted residual).
- Escalate: Claims 8-10 are commit-message claims on a commit already merged into the branch — orchestrator decides whether the immutable-history exception applies; Claim 8's residual bypasses (bare `cd`, obfuscated `.claude`) are live code behaviour worth routing to a critic or Q-048. Claim 12 is a live code/comment mismatch in questions.sh.
