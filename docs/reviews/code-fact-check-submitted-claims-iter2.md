# Code Fact-Check Report

**Commit:** 16f2978
**Repository:** /workspace (claude-workflows)
**Scope:** Submitted claims only (Stage 2.5, review-fix loop iteration 2), for `git diff f023357..answers-2026-09-20`. No fresh harvesting. Claims are numbered from 30.
**Checked:** 2026-09-21
**Total claims checked:** 8 (6 submitted; claim 31 split into 31a/31b/31c)
**Summary:** 5 verified, 2 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution notes: every probe ran hermetically. It used a temp `HOME` under
`/tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/fc-submitted/`,
`CLAUDE_CONFIG_DIR` removed from the environment (the sandbox exports it), a temp
`CC_WEB_TAINT_DIR`, and throwaway git repos. The repo hook was invoked by piping JSON to
`python3 /workspace/hooks/guard-trusted-writes.py`. The pre-fix hook is
`git show f023357:hooks/guard-trusted-writes.py`, saved as `hook-f023357.py.txt` in the
same scratch dir. All captured-output files below are in that scratch dir (called `$S`).

---

## Submitted Claims

## Claim 30: "Every R1/A10 spelling listed in commit c5a7c96, plus `cd ~/.claude && cp -r /tmp/p/hooks .`, `echo x > "${HOME}"/.claude/"hooks"/g.py`, `exec 3> ~/.claude/settings.json` and `echo x >| ~/CLAUDE.md`, returns deny from the repo hook."

**Submitted by:** security-reviewer
**Location:** `hooks/guard-trusted-writes.py:190-205`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 13 spellings named in the c5a7c96 message, each wrapped in a write primitive (`echo x > …` where the message gives only the path), plus the 4 added spellings, all with `CLAUDE_CONFIG_DIR` unset. It does not establish behavior when `CLAUDE_CONFIG_DIR` is set, for spellings outside this list (for example `$USER`-based home, `/root`, globbing `.clau*`, or obfuscation of the file name itself, which c5a7c96 names as residual), or for write primitives the hook does not recognise (A8).

All 17 commands returned `permissionDecision: "deny"` with rc 0. Excerpt from `$S/out30.txt`:

```
rc=0 deny               | echo x > "$HOME"/CLAUDE.md
rc=0 deny               | H=~; echo x > $H/CLAUDE.md
rc=0 deny               | cd ~/.claude && mv x CLAUDE.md
rc=0 deny               | cd ~/.claude && cp -r /tmp/p/hooks .
rc=0 deny               | echo x > "${HOME}"/.claude/"hooks"/g.py
rc=0 deny               | exec 3> ~/.claude/settings.json
rc=0 deny               | echo x >| ~/CLAUDE.md
```
(7 of the 17 rows shown; the other 10 in `out30.txt` are also `deny`.)

The deny comes from the co-occurrence branches of `bash_targets`:

```python
# hooks/guard-trusted-writes.py:194-201
    if HARD_FRAG.search(cmd):
        return "hard"
    # R1 / Q-035: CLAUDE.md plus any home/global indicator -> the global file may be meant.
    if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):
        return "hard"
    # A10: settings*.json / hooks plus the config dir named anywhere.
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
```
(the function continues to `:205` with the SOFT_FRAG → "soft" branch and `return None`.)

For comparison, the pre-fix hook (f023357) run through the same probe defers on 15 of the 17 commands. It denies only `exec 3> ~/.claude/settings.json` and `echo x >| ~/CLAUDE.md` (`$S/out30-prefix.txt`). So the fix is what makes the first 15 deny.

**Evidence:** `hooks/guard-trusted-writes.py:190-205`, `hooks/guard-trusted-writes.py:171-185`. Command: `python3 probe30.py /workspace/hooks/guard-trusted-writes.py`, cwd `$S`, exit 0, 2026-09-21T20:47:20-07:00. Output: `$S/out30.txt`. Pre-fix contrast: `python3 probe30.py $S/hook-f023357.py.txt`, exit 0, output `$S/out30-prefix.txt`. Inputs: `$S/probe30.py`, `$S/cmds30.txt`.

---

## Claim 31a: "`replace_with` renames over the target, so a symlink planted at the target is replaced rather than written through."

**Submitted by:** security-reviewer
**Location:** `scripts/questions.sh:115-124`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `index` against a symlink planted at the live file before the run, and `mv -f` semantics over a symlink planted after `replace_with`'s re-check. It does not establish the path for `archive` (which calls `replace_with` twice, once per file), or behavior when the directory is swapped for a symlink inside the check-to-rename window.

The conclusion (no write through a symlink) holds, but the main mechanism is refusal, not replacement. A symlink that already exists at the target never reaches the rename. `assert_write_targets` refuses it first, and `replace_with` checks again just before `mv`:

```bash
# scripts/questions.sh:115-124
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

Executed: with a symlink planted at `docs/working/questions.md` pointing to a victim file, `index` exits 1 with `refusing to write: …/questions.md is a symlink`, and the victim still reads `victim` (`$S/out31.txt`, case C). The rename-over behavior only matters for a symlink planted in the window after the line-120 check. For that case, `mv -f` over a symlink replaced the link itself and left its target alone: `target is symlink after mv? no; content=new; victim2=victim` (case D). So a better wording is: "refused if present, and replaced rather than followed if planted in the race window".

**Evidence:** `scripts/questions.sh:91-124`, `scripts/questions.sh:335`, `scripts/questions.sh:345`. Command: `bash probe31.sh.txt`, cwd `$S`, exit 0, 2026-09-21T20:48:22-07:00. Output: `$S/out31.txt` (cases C, D).

---

## Claim 31b: "`docs/working -> ../other` is refused (default paths)."

**Submitted by:** security-reviewer
**Location:** `scripts/questions.sh:91-103`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `init` in a fresh git repo with default paths and `docs/working` as a relative symlink. It does not establish refusal for a symlinked ancestor that resolves inside the repo (for example `docs -> ./elsewhere`): there `docs/working` is not itself a link and containment passes, so that case was not probed as refused.

`init` exits 1 with `refusing to write: directory …/a/docs/working is a symlink` and creates nothing (`$S/out31.txt`, case A). The related case of an ancestor pointing outside the repo (`docs -> $S/q31/outside`) is also refused, this time by the containment check: `…/questions.md resolves to …/outside/working/questions.md, outside …/b` (case B).

**Evidence:** `scripts/questions.sh:94-100`, `scripts/questions.sh:417-434`. Command: `bash probe31.sh.txt`, cwd `$S`, exit 0, 2026-09-21T20:48:22-07:00. Output: `$S/out31.txt` (cases A, B).

---

## Claim 31c: "…it is the default-path *containment* check that refuses `docs/working -> ../other`."

**Submitted by:** security-reviewer
**Location:** `scripts/questions.sh:96-100`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which check in `assert_write_target` fires for this spelling. It does not establish whether the containment check is sufficient for other ancestor layouts.

The refusal comes from the directory-symlink check on line 95, not from containment:

```bash
# scripts/questions.sh:94-100
    [[ -L "$file" ]] && die "refusing to write: $file is a symlink"
    [[ -L "$dir" ]] && die "refusing to write: directory $dir is a symlink"
    if [[ -z "$overridden" ]]; then
        root="$(realpath -m -- "$PROJECT_ROOT")"
        resolved="$(realpath -m -- "$file")"
        [[ "$resolved" == "$root"/* ]] \
            || die "refusing to write: $file resolves to $resolved, outside $root"
```

`../other` resolves inside the repo, so containment on its own would let it through. `realpath -m -- docs/working/questions.md` in that repo gives `…/q31/a/other/questions.md`, which is under the root `…/q31/a`. The refusal message in case A is also the `directory … is a symlink` text. A reader who takes containment to be the guard could drop the `-L "$dir"` check as redundant and reopen in-repo redirection. The accurate wording: "the dir `-L` check refuses `docs/working -> anything`; containment catches symlinked *ancestors* that leave the repo."

**Evidence:** `scripts/questions.sh:94-100`. Command: `bash probe31.sh.txt` (case A message), then `realpath -m -- docs/working/questions.md; realpath -m -- .` in `$S/q31/a`, exit 0, 2026-09-21T20:48:22-07:00. Output: `$S/out31.txt`, plus the realpath output captured in this report's session log (`…/q31/a/other/questions.md` vs `…/q31/a`).

---

## Claim 32: "The linker (devcontainer-config/link-claude-home.sh), health-check (scripts/health-check.sh ~:575) and hook (config_dir, hooks/guard-trusted-writes.py:63-73) now all compute {{CLAUDE_DIR}} from the same expression."

**Submitted by:** api-consistency-reviewer
**Location:** `hooks/guard-trusted-writes.py:63-73`
**Type:** Architectural / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three computation sites for `CLAUDE_CONFIG_DIR` values unset, empty, absolute, absolute with a trailing slash, relative, and `~/…`. It does not establish that every other consumer of `{{CLAUDE_DIR}}` (for example `health-check.sh:542` or `:585`, which use the same shell expression) agrees on relative values.

The two shell sites use the identical expression:

```bash
# devcontainer-config/link-claude-home.sh:36
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
# scripts/health-check.sh:575
             | sed "s#{{CLAUDE_DIR}}#${CLAUDE_CONFIG_DIR:-$HOME/.claude}#g")
```

The hook matches their fallback semantics but adds anchoring for relative values:

```python
# hooks/guard-trusted-writes.py:72-73
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    return Path(os.path.abspath(cfg)) if cfg else HOME / ".claude"
```

Executed comparison (`$S/out32.txt`): the result is SAME for unset, empty, and `/abs/cfg`. It is DIFF for `/abs/cfg/`, which is only a string difference (pathlib drops the trailing slash, so it is harmless for comparisons). It is also DIFF for `rel/cfg` and `~/cfg`: the hook returns `$PWD/rel/cfg` and `$PWD/~/cfg`, while the shell keeps the relative string. That string is later resolved against whatever cwd the linker, health-check or Claude Code runs in. So "the same expression" is true for the realistic absolute or unset case. For relative values the hook deliberately differs, and its docstring says so ("A relative value is anchored at the hook's cwd"), but it is not the same computation.

**Evidence:** `devcontainer-config/link-claude-home.sh:36`, `devcontainer-config/link-claude-home.sh:133-137`, `scripts/health-check.sh:575`, `scripts/health-check.sh:585`, `hooks/guard-trusted-writes.py:63-73`. Command: `bash probe32.sh.txt`, cwd `$S`, exit 0, 2026-09-21T20:49:04-07:00. Output: `$S/out32.txt`.

---

## Claim 33: "managed-settings.json moving to SOFT for file tools is an improvement: ungated (defer) at f023357, asks when tainted at HEAD."

**Submitted by:** api-consistency-reviewer
**Location:** `hooks/guard-trusted-writes.py:135-144`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Write and Edit on `~/.claude/managed-settings.json`, `/etc/claude-code/managed-settings.json` and a project-level `managed-settings.json`, in clean and tainted sessions, pre-fix and at HEAD. It does not establish the Bash path (still HARD via `HARD_FRAG` at `:185`), untainted sessions (still ungated at HEAD), or the new false-ask surface on any file named `managed-settings.json` in any project.

The factual premise holds. At f023357 the hook classified it `hard` (`if name in ("managed-settings.json",): return "hard"`, `hook-f023357.py.txt:98-99`) and so deferred. No `permissions.deny` rule names it: `hooks/wiring.json` denies only `{{CLAUDE_DIR}}/settings*.json`, `/hooks/**`, `/CLAUDE.md`, `~/CLAUDE.md` and three Read rules. So the old defer meant no gate. At HEAD it is SOFT:

```python
# hooks/guard-trusted-writes.py:142-144
        if name in ("claude.md", "agents.md", "claude.local.md", "managed-settings.json") \
                or cand.suffix.lower() == ".mdc":
            return "soft"
```

Executed (`$S/out33.txt`): f023357 returns `defer` in all 12 tool × path × taint combinations. HEAD returns `ask` in all 6 tainted combinations and `defer` in all 6 clean ones. Because no deny rule applies, the change strictly adds a gate for tainted sessions. Hence "improvement" is supported.

**Evidence:** `hooks/guard-trusted-writes.py:135-147`, `hooks/wiring.json` (`.permissions.deny`), `hook-f023357.py.txt:98-99` (git show f023357:hooks/guard-trusted-writes.py). Command: `python3 probe33.py`, cwd `$S`, exit 0, 2026-09-21T20:49:24-07:00. Output: `$S/out33.txt`.

---

## Claim 34: "The file-tool classifier matches on resolve() targets (_HARD_FILE_TARGETS/_HARD_DIR_TARGETS), not a hard-coded /opt/claude-workflows path; the /opt mentions at :17/:83 are comments only."

**Submitted by:** architecture-review
**Location:** `hooks/guard-trusted-writes.py:79-93`, `hooks/guard-trusted-writes.py:133`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook source's `/opt` references and an installed layout whose payload lives at a non-`/opt` path. It does not establish behavior when the symlink targets are created after the hook process starts (the targets are computed once at import).

`grep -n opt hooks/guard-trusted-writes.py` finds exactly two hits. `:17` is inside the module docstring ("/opt/claude-workflows). Critical: …"), which is a non-executing string rather than a `#` comment, but it has no effect at runtime. `:83` is a `#` comment. The HARD targets are derived only from `CONFIG_DIR`:

```python
# hooks/guard-trusted-writes.py:86,93
_HARD_FILE_TARGETS = {_safe_resolve(CONFIG_DIR / "CLAUDE.md"), _safe_resolve(HOME / "CLAUDE.md")}
_HARD_DIR_TARGETS = {_safe_resolve(CONFIG_DIR / "hooks")}
```
(lines 87-92 add the resolved `settings*.json` names to `_HARD_FILE_TARGETS`.)

Executed with `~/.claude/hooks` and `~/.claude/CLAUDE.md` symlinked into `$S/r34/srv/payload` (not `/opt`), in a tainted session (`$S/out34.txt`): `payload/hooks/x.py` returns `defer` (HARD) and `payload/CLAUDE.md` returns `defer` (HARD). The control, an unrelated `other/CLAUDE.md`, returns `ask` (SOFT). So matching follows the link targets wherever they are.

**Evidence:** `hooks/guard-trusted-writes.py:14-17`, `hooks/guard-trusted-writes.py:79-93`, `hooks/guard-trusted-writes.py:121-134`. Command: `python3 probe34.py`, cwd `$S`, exit 0, 2026-09-21T20:49:45-07:00. Output: `$S/out34.txt`.

---

## Claim 35: "Across Bash-hard, Write-none and Bash-no-write request shapes, the fix adds ≤0.3 ms in-process work per hook call and end-to-end latency stays within ~2 ms of the pre-fix hook (f023357); and WRITE_PRIMITIVE pathological 40 KB input times are unchanged by the fix."

**Submitted by:** performance-reviewer
**Location:** `hooks/guard-trusted-writes.py:79-93`, `hooks/guard-trusted-writes.py:156-205`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one representative input per shape (Bash-hard = `echo x > ~/.claude/settings.json`, which exits at `HARD_FRAG`; Write-none = `/workspace/src/app.py`; Bash-no-write = `git status && ls -la`), with an empty temp `~/.claude`, on this WSL2 machine. It does not establish cost for Bash-hard inputs that reach the co-occurrence branches, a `~/.claude` with many `settings*.json` or a slow filesystem for `resolve()`/`glob()`, or run-to-run variance beyond medians of 30–40 samples.

The in-process delta is module setup plus classification (`$S/out35.txt`). Import median: 0.076 → 0.227 ms (+0.15 ms). Classification: Bash-hard 0.85 → 0.70 µs, Write-none 25.9 → 44.3 µs (+0.018 ms), Bash-no-write 0.89 → 0.86 µs. Total at most about 0.17 ms, within the ≤0.3 ms bound.

End-to-end subprocess medians (40 runs): Bash-hard 16.93 → 17.45 ms, Write-none 20.95 → 18.77 ms, Bash-no-write 15.88 → 16.47 ms. Every difference is within ~2.2 ms, and the largest one is in the faster direction.

WRITE_PRIMITIVE: the compiled pattern text is byte-identical between the two versions (`pattern identical: True`; source `hooks/guard-trusted-writes.py:156-164`). The 40 KB timings match: sed-spaces 1.26/1.27 ms, python-spaces 1.27/1.19 ms, sed-a 1.36/1.37 ms, and `"dd " * 13333` 1417.66/1444.33 ms. That last input is a pre-existing ~1.4 s backtracking case on `\bdd\b[^\n]*\bof=`. It is unchanged by the fix, but worth a separate note since the claim says only "unchanged".

**Evidence:** `hooks/guard-trusted-writes.py:79-93`, `hooks/guard-trusted-writes.py:156-164`, `hooks/guard-trusted-writes.py:190-205`. Command: `timeout 500 python3 probe35.py`, cwd `$S`, exit 0, 2026-09-21T20:50:15-07:00. Output: `$S/out35.txt`.

---

## Claims Requiring Attention

### Incorrect
- **Claim 31c** (`scripts/questions.sh:96-100`): `docs/working -> ../other` is refused by the directory `-L` check (`:95`), not by containment. Containment passes because `../other` resolves inside the repo, so the endorsement should credit the `-L` check.

### Mostly Accurate
- **Claim 31a** (`scripts/questions.sh:115-124`): a pre-planted target symlink is *refused* (by `assert_write_targets` and the `:120` re-check). Rename-over-the-link only covers a link planted in the post-check race window.
- **Claim 32** (`hooks/guard-trusted-writes.py:72-73`): the result is the same for unset, empty and absolute values. The hook `abspath`-anchors relative or `~`-prefixed values, which the shell sites keep literal, so it is not literally the same expression.

---

## Goal-Alignment Note
- **Success criterion (verbatim):** the submitted-claims report saved at the path above with one verdict per submitted claim.
- **Answered:** All 6 submitted claims have a verdict. Claim 31 is split into 31a/31b/31c because its parts diverge. All are executed against the repo copy with hermetic HOME, taint and git fixtures. The report is saved at `docs/reviews/code-fact-check-submitted-claims-iter2.md` with `**Commit:** 16f2978`.
- **Out of scope:** No fresh claim harvesting. Two observations were noted but not filed as claims: the in-repo symlinked-ancestor case (`docs -> ./x` would, by reading `:94-100`, pass both checks; inferred, not probed), and the pre-existing ~1.4 s `dd`-regex backtracking.
- **Escalate:** Claim 31c. If any reviewer's reasoning relies on containment covering in-repo directory symlinks, re-check it. No tracked files were modified and nothing was committed.
