Commit: 31f53e8

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch `answers-2026-09-20`
**Scope:** Iteration 3, Stage 2.5. This report verdicts only the four claims the critics submitted (S1–S4) about `git diff 2d93589..answers-2026-09-20`. No claims were freshly harvested. Numbering continues from the merged Stage-1 report, `docs/reviews/code-fact-check-report-iter3.md`.
**Checked:** 2026-09-21 (probes ran 2026-09-22T04:39–04:41Z, sandbox UTC clock)
**Total claims checked:** 4
**Summary:** 4 verified, 0 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution logs and the probe scripts are in `docs/reviews/execution-logs/iter3-subm-*` (untracked). Every hook probe ran against the repo copy, `/workspace/hooks/guard-trusted-writes.py`, not the installed hook. Each probe used a fake HOME, a fake `/opt` payload built the way the bats `install_layout` builds it, and a scratch `CC_WEB_TAINT_DIR`. `CLAUDE_CONFIG_DIR` was unset with `env -u` in every layout except L2, which sets it on purpose.

---

## Submitted Claims

## Claim 33: "No file-tool path that the hook classifies as HARD reaches the `ask` branch. The `"hard"` return defers, `"hard-resolved"` emits deny, and both come before the SOFT check."

**Submitted by:** security-reviewer (architecture-review made the same claim)
**Location:** `hooks/guard-trusted-writes.py:146-155,275-286`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every path that `classify_path` returns as `"hard"` or `"hard-resolved"`, for Edit, Write and MultiEdit, through both the `file_path` and `path` keys, tainted and clean, across five layouts. The layouts are: installed; `CLAUDE_CONFIG_DIR` set explicitly; config dir itself a symlink; HOME a symlink; a plain config dir. It does not establish anything about spellings the hook does not classify as HARD. That includes case variants on a case-insensitive filesystem: on Linux ext4 they classify `soft` and do ask when tainted. The probe could not test a case-insensitive filesystem. It also does not cover Bash, which has its own tier logic.

In `classify_path`, both HARD returns come before the SOFT loop:

```python
# hooks/guard-trusted-writes.py:146-159
    for cand in (p, norm):
        if _is_hard(cand, [CONFIG_DIR]):
            return "hard"
    ...
    for cand in cands:
        if _is_hard(cand, GLOBAL_DIRS):
            return "hard-resolved"
    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
        return "hard-resolved"
    # SOFT. ...
    for cand in cands:
(excerpt ends :159; enclosing classify_path continues to :169 and returns only "soft" or "none" — read)
```

In `main()`, both HARD tiers leave the process before the `ask` branch runs:

```python
# hooks/guard-trusted-writes.py:275-289
        if tier == "hard":
            ...
            defer()
        if tier == "hard-resolved":
            ...
            emit("deny", f"This write reaches a protected policy file ...")
        if tier == "soft" and tainted:
            emit("ask", ...)
        defer()
```

Both `defer()` and `emit()` end in `sys.exit(0)`, so neither HARD tier can fall through (`hooks/guard-trusted-writes.py:57-65`: `print(json.dumps(...)); sys.exit(0)` / `def defer(): sys.exit(0)`).

The executed probe covered 296 HARD-classified (path × layout) cases: 240 `hard` and 56 `hard-resolved`. Each case ran 8 times, once per tool, key and taint combination, by driving the real `main()` with the payload on stdin. Zero violations: every `hard` case produced no output (defer), and every `hard-resolved` case produced `deny`. Separate CLI runs (`python3 hook < payload`) confirmed that lexical `settings.json`, `hooks/foo.sh` and `~/CLAUDE.md` give empty output with rc=0, tainted and clean alike.

The case variants (`~/.claude/SETTINGS.json`, `HOOKS/foo.sh`, `claude.md`) classified `soft` and gave `ask` when tainted and defer when clean. They are outside this claim, as the critic's scope says. On a case-insensitive filesystem they would be the real files, so they are the gap the critic flagged, not a counterexample here.

- Command: `bash /tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/subm/probe-s1s2.sh.txt` (cwd `/workspace`, exit 0, 2026-09-22T04:39:17Z)
- Command: `bash .../subm/probe-s2-extra.sh.txt` (cwd `/workspace`, exit 0, 2026-09-22T04:39:40Z)

**Evidence:** `hooks/guard-trusted-writes.py:57-65`, `hooks/guard-trusted-writes.py:134-169`, `hooks/guard-trusted-writes.py:270-289`; `docs/reviews/execution-logs/iter3-subm-probe-s1s2.txt` (summary lines: `class totals (path x layout): {'hard-resolved': 56, 'hard': 240, 'soft': 66, 'none': 23}` / `violations: 0`); `docs/reviews/execution-logs/iter3-subm-probe-s2-extra.txt`; the harness is at `docs/reviews/execution-logs/iter3-subm-harness.py.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 34: "A path that is HARD only after resolve() returns deny whether or not the session is tainted."

**Submitted by:** security-reviewer (backs architecture-review's point that the deny/defer split puts fail-closed where it is cheap)
**Location:** `hooks/guard-trusted-writes.py:151-155,279-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers paths that `classify_path` detects as HARD through resolve(), through the config dir's resolved form, or through `_HARD_FILE_TARGETS`/`_HARD_DIR_TARGETS`. The probed forms are: the payload's real `/opt` paths; a project `.claude` symlinked to `~/.claude`; the resolved form of a symlinked config dir; resolved-HOME spellings under a symlinked HOME, including a `settings.brandnew.json` that did not exist at import; and relative paths from a cwd of HOME. Every one gives `deny`, tainted and clean. It does not establish that every write reaching a protected file is HARD after resolve(). Writing the target of a per-file symlink inside `CONFIG_DIR/hooks/` is not caught: `hooks/linked.sh -> elsewhere/target.sh`, then a write to `elsewhere/target.sh`. That path resolves to itself, so it classifies `none` and defers, tainted or clean. That is the critic's not-verified item, and it is noted here for the orchestrator.

The deny is emitted with no reference to `tainted`:

```python
# hooks/guard-trusted-writes.py:279-285
        if tier == "hard-resolved":
            # No deny rule names this spelling, so a defer would be no gate at all,
            # and an ask is wrong for a HARD target. Deny outright.
            emit("deny", f"This write reaches a protected policy file ({Path(fp).name}: "
                         ".claude hooks/settings or global CLAUDE.md) through a symlink or "
                         "resolved path that permissions.deny does not name. Edit it at its "
                         "~/.claude path, with review.")
```

The `tainted` flag is read only at `:286` (`if tier == "soft" and tainted:`), after this branch exits.

Executed results (`iter3-subm-probe-s1s2.txt`): all 56 `hard-resolved` cases in layouts L1–L5 gave `deny` for both `tainted` and `clean`, across Edit, Write and MultiEdit, and across `file_path` and `path`. Examples:

- `L1 hard-resolved deny .../opt/cw/hooks/new.sh`
- `L3 hard-resolved deny .../home/proj/.claude/settings.new.json`
- `L1 hard-resolved deny CLAUDE.md` (relative, cwd = HOME)

Through the CLI (`iter3-subm-probe-s2-extra.txt`), a symlinked HOME's real-path spellings (`homereal/CLAUDE.md`, `homereal/.claude/settings.brandnew.json`, `homereal/.claude/hooks/foo.sh`) returned `deny` for both taint states.

The per-file-link case returned empty output (defer) for both taint states: `tainted R/L5/elsewhere/target.sh ->  [rc=0]`. The reason is that `_HARD_DIR_TARGETS` holds only the resolved hooks *directory* (`hooks/guard-trusted-writes.py:102`: `_HARD_DIR_TARGETS = {_safe_resolve(CONFIG_DIR / "hooks")}`), so link targets of individual files inside it are not enumerated. By contrast, the settings files and CLAUDE.md are enumerated as resolved file targets (`:95-101`).

- Commands: as in Claim 33 (`probe-s1s2.sh.txt` exit 0 at 04:39:17Z; `probe-s2-extra.sh.txt` exit 0 at 04:39:40Z; cwd `/workspace`)

**Evidence:** `hooks/guard-trusted-writes.py:95-102`, `hooks/guard-trusted-writes.py:149-155`, `hooks/guard-trusted-writes.py:279-289`; `docs/reviews/execution-logs/iter3-subm-probe-s1s2.txt`; `docs/reviews/execution-logs/iter3-subm-probe-s2-extra.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 35: "An explicit archive prefix outside `[A-Za-z0-9._-]+` is rejected before any path is built."

**Submitted by:** security-reviewer
**Location:** `scripts/archive-working-docs.sh:52-55`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-empty explicit prefixes containing `/`, `../`, a space, a newline, a glob, `;`, and a non-ASCII letter. Each exits 1 before `archive/` is created or any file is moved, with or without `--dry-run`. It does not establish four nearby properties:
- The regex accepts `.` and `..`. They are harmless, because the prefix is joined as `${PREFIX}-${name}`, which gives `archive/..-a.md` and cannot traverse.
- An explicit empty argument (`''`) is not rejected. It silently falls back to the run id or the date.
- Behaviour under a UTF-8 locale was not probed: the sandbox runs in the C locale, where `setlocale` fails.
- The run-id-file path (`:43-47`) is gated by its own identical regex, but this claim does not cover it.

The validation runs at `:52`, before `ARCHIVE_DIR` (`:56`) or any `dest` (`:133`) is built:

```bash
# scripts/archive-working-docs.sh:49-56
PREFIX="${PREFIX:-$(date +%Y-%m-%d)}"
# The prefix becomes part of a path, and the morning summary reads it back as a
# Run id; hold an explicit prefix to the same charset as the recorded one.
if ! [[ "$PREFIX" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: prefix '$PREFIX' must match [A-Za-z0-9._-]+" >&2
  exit 1
fi
ARCHIVE_DIR="$WORKING_DIR/archive"
```

Before `:52`, the only file access is reading `si-run-id.txt`, and only when `PREFIX` is empty (`:43`: `if [ -z "$PREFIX" ] && [ -f "$WORKING_DIR/si-run-id.txt" ]; then`). The `mkdir -p "$ARCHIVE_DIR"` is at `:121`, and `dest="$ARCHIVE_DIR/${PREFIX}-${name}"` is at `:133`.

Executed results: the script was copied into a scratch dir that was not a git checkout, with a fake `docs/working/a.md`.
- The prefixes `a/b`, `../x`, `a b`, `a\nb`, `a*`, `a;b` and `é` each gave `rc=1 no-archive-dir files: ./docs/working/a.md`, plus the error line.
- `-n a/b` also gave rc=1.
- `.` gave `archive/.-a.md` and `..` gave `archive/..-a.md`, both rc=0.
- `''` fell back to `archive/2026-09-21-a.md`.
- `run-1` gave `archive/run-1-a.md`.

- Command: `bash .../subm/probe-s3.sh.txt` (cwd the scratchpad `subm/`, exit 0, 2026-09-22T04:40:07Z)

**Evidence:** `scripts/archive-working-docs.sh:29-56`, `scripts/archive-working-docs.sh:121-151`; `docs/reviews/execution-logs/iter3-subm-probe-s3.txt`
**Legibility-target:** for-author

---

## Claim 36: "a577546 adds no resolve(), glob or filesystem call per invocation beyond the single _safe_resolve(p) the pre-fix hook already made."

**Submitted by:** performance-reviewer
**Location:** `hooks/guard-trusted-writes.py:104-169` (classify_path and helpers; compared against `2d93589:hooks/guard-trusted-writes.py`)
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Python-level filesystem entry points, in both the import phase and `main()`, for the L1 installed layout and 77 paths, comparing 2d93589 with a577546 on CPython 3.11.2. The instrumented calls are `os.stat`, `lstat`, `readlink`, `scandir`, `listdir` and `access`, `os.path.realpath`, and `Path.resolve`, `glob` and `exists`. The a577546 copy is byte-identical to the working tree. It does not establish kernel-syscall counts: strace and ltrace are not installed. It also does not cover C-level calls that bypass these wrappers, or other layouts. The code reading below shows that those layouts use the same call sites.

Reading the code: the post-fix `classify_path` still makes exactly one resolve (`hooks/guard-trusted-writes.py:141`: `rp = _safe_resolve(p)`). The new two-pass HARD check uses only pure-path operations. `_rel_under` calls `cand.relative_to(g)` (`:108`). `_is_hard` compares `rel.parts`, `cand.name` and `cand.parent` (`:122-131`). `:154` uses `rp.parents` and set membership. The module-level resolve and glob block (`:88-102`) is unchanged from 2d93589 except for the rename of `_global_rel` to `_rel_under`, which added a `dirs` argument. Paraphrased — no quote available because this is a whole-block equality across two commits; the executed diff below shows it.

The executed results match. The import phase is identical in both versions: `{'Path.glob': 1, 'Path.resolve': 6, 'os.lstat': 86, 'os.readlink': 2, 'os.scandir': 1, 'os.stat': 7, 'posixpath.realpath': 6}`. Per-path `main()` counts were identical for all 77 paths (`paths compared: 77 paths with differing call counts: 0`). Each path makes one `Path.resolve`/`realpath`. The single `Path.exists` is the taint check at `:255`, which both versions have.

- Command: `bash .../subm/probe-s4.sh.txt` (cwd `/workspace`, exit 0, 2026-09-22T04:40:32Z; it depends on the L1 layout built by `probe-s1s2.sh.txt`)

**Evidence:** `hooks/guard-trusted-writes.py:84-155`, `hooks/guard-trusted-writes.py:254-255`; `2d93589:hooks/guard-trusted-writes.py` (`_global_rel`/`_is_hard`/`classify_path`); `docs/reviews/execution-logs/iter3-subm-probe-s4.txt`; the counter is at `docs/reviews/execution-logs/iter3-subm-fscount.py.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
(none)

### Unverifiable
(none)

Advisory for synthesis (not a verdict change): Claim 34 found an adjacent gap. The target of a per-file symlink inside `CONFIG_DIR/hooks/` classifies `none` and is not gated. Its sibling, a symlinked `settings.json` or `CLAUDE.md`, is caught by `_HARD_FILE_TARGETS`. Claim 33's scope also confirms that case variants classify `soft` on Linux, which leaves the case-insensitive-filesystem question the critic flagged open.

---

## Goal-Alignment Note

- **Answered:** I verdicted all four submitted claims (S1–S4 → Claims 33–36), each by execution with provenance and captured logs. The hook probes used the repo copy in hermetic fake layouts with `CLAUDE_CONFIG_DIR` controlled per layout.
- **Out of scope:** I did no fresh claim harvesting. Case-insensitive filesystems could not be probed: there is no such mount in the sandbox. Kernel-level syscall tracing was not possible because strace is absent. I did not edit the Stage-1 merged report.
- **Escalate:** One item for the orchestrator. Writes to the resolve target of a per-file symlink inside `~/.claude/hooks/` get no gate from the hook, and no deny rule names that path (Claim 34 scope). Whether it matters depends on whether any installed layout uses per-file hook links. The documented layout links the whole `hooks` dir.
