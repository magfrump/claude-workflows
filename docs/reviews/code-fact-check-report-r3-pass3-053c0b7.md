Commit: 053c0b7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-guard (branch `ans/guard-q048-q050`)
**Scope:** branch diff `970e525..053c0b7`: `hooks/guard-trusted-writes.py`, `test/hooks/guard-trusted-writes.bats`, `guides/bare-host-hook-wiring.md`, and the 7 commit messages. Third, terminal pass (after 835f99d and 053c0b7).
**Checked:** 2026-09-23
**Total claims checked:** 12
**Summary:** 7 verified, 3 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Execution provenance for every `executed` claim:
- Harness: `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/gfc-p3-r3/h.py`. Each case builds a fresh fixture: temp HOME with `~/.claude/{settings.json,CLAUDE.md,hooks/}` and `~/CLAUDE.md`; a git project `proj/` with its own `.claude/settings.json` and `.claude/hooks/`; two real worktrees made by `git worktree add`: `proj/.claude/wt-a` (`{W}`) and `proj/.claude/worktrees/b` (`{WB}`). The hook runs with `CLAUDE_CONFIG_DIR` unset, a temp `CC_WEB_TAINT_DIR` and a **tainted** session id. With `"run": true` the harness then runs the command in `bash -c` (HOME = the temp home) and lists the files that changed outside the two worktrees. The run step shows what the command writes when no hook stops it. It does not bypass the hook's decision.
- cwd for all runs: `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/gfc-p3-r3` (the harness's own `cwd` column gives the command's cwd). All harness invocations exited 0.
- Captured outputs (bare paths, same directory): `out-c1.txt` (2026-09-24T00:03:38Z UTC), `out-c2.txt` (00:03:54Z), `out-c2-old.txt` (the same cases against `970e525`'s hook, 00:04:12Z), `out-c3.txt` (00:06:16Z), `out-n12.txt` (00:05:52Z), `out-n12b.txt` (00:07:08Z), `bats-*.txt` (00:04:28Z–00:05:14Z). Case files: `c1.json`, `c2.json`, `c3.json`; scripts: `old.sh`, `bats.sh`, `n12.sh`, `n12b.sh`.
- Hallucination-pattern log read. No claim here matches a logged pattern, and no fabrication was found.

---

## Claim 1: "the whole command has no `..` component, no `$` or backtick, no cd/pushd/popd, no ln/mv/rm, no program that runs other text (sh -c, eval, xargs, interpreters) and no policy name outside the exempt worktree words. If any of that fails, no worktree occurrence is exempt." (token-class and over-trip half)

**Location:** `hooks/guard-trusted-writes.py:54-58`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each listed token class voiding the exemption in the spellings tried (`$X`, backtick, `cd`, `pushd`, `popd`, `(cd`, `ln`, `/bin/ln`, `\ln`, `l''n`, `mv`, `rm`, `sh/bash/zsh -c`, `eval`, `exec`, `source`, `xargs`, `awk`, `python3 -c`, `node/perl/ruby -e`, `git -C … mv`, a later `settings.json` or `/tmp/hooks` word including after a newline), the listed look-alikes staying exempt, and plain absolute worktree writes staying exempt. It does not establish that the `..` clause catches every parent-directory spelling (Claim 2 refutes that) or that the command list covers every directory-changing program (`env -C` is absent, also Claim 2).

The gate is:

```python
# hooks/guard-trusted-writes.py:343-352
_WT_GATE_DOTDOT = re.compile(r"(?<![\w.-])\.\.(?![\w.-])")
_WT_GATE_CMD = re.compile(
    r"(?<![\w.-])(?:cd|pushd|popd|ln|mv|rm|sh|bash|zsh|dash|ksh|eval|exec|source"
    r"|xargs|awk|gawk|python[0-9.]*|node|perl|ruby)(?![\w.-])")

def _whole_command_allows_exemption(cmd: str) -> bool:
    if "$" in cmd or "`" in cmd:
        return False
    flat = re.sub(r"[\"'\\]", "", cmd)
    return not (_WT_GATE_DOTDOT.search(flat) or _WT_GATE_CMD.search(flat))
```

In `out-c1.txt` every token-class case is `[deny]`. The baselines `echo x > {W}/settings.json` and `echo x > {WB}/hooks/x.sh` are `[no-opinion]`. So are `cp /x/rmdata …`, `tool --cdn > …` and `cd-tools > …`. The same file shows every pass-1 and pass-2 route as `[deny]`, and the run column shows each one really writes outside the worktree when no hook stops it: `cd {W} && cd .. && echo x > settings.json` and `cd {W} && echo x > ../settings.json` write `proj/.claude/settings.json`; `rm -rf {W} && ln -s {H} {W} && echo x > {W}/CLAUDE.md` writes `home/CLAUDE.md`; `{W}"/.."/settings.json` and `ln -s . …/wt-q && …` write `proj/.claude/settings.json`; `"$HOME"/.claude/wt-x/settings.json` is denied.

**Evidence:** `hooks/guard-trusted-writes.py:343-352`, `hooks/guard-trusted-writes.py:354-356`; `out-c1.txt`; `c1.json`; command `python3 h.py c1.json`, exit 0, 2026-09-24T00:03:38Z.

---

## Claim 2: "A command is disqualified by: a `..` path component anywhere (not `a..b`, which is not a path step)" / 053c0b7: "no worktree occurrence is exempt unless the WHOLE command … has no `..` path component, no cd/pushd/popd"

**Location:** `hooks/guard-trusted-writes.py:335-336` (also docstring `:55`, `:62`, and commit 053c0b7)
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers a `..` attached to a short option (`-t..`) and a brace-built `..` (`.{,.}`), each combined with a worktree cwd (`env -C <wt>`, or a session cwd that is the worktree). It does not establish that the config dir (`~/.claude`) is reachable this way: the reach found is the worktree's parent dir, i.e. the project's own `.claude/`.

The lookbehind `(?<![\w.-])` refuses a `..` preceded by a letter, so a `..` glued to an option letter is not seen. It is still a path step: `cp -t..` means `cp -t ..`. The list also has no `env -C`/`--chdir`, which sets the cwd without `cd`. Brace expansion builds `..` from text with no `..` in it. The per-word check (`:321-327`) sees only the absolute worktree word, and that word does resolve inside the root, so every occurrence is neutralized. No `.claude` is left, and `settings.json` + no indicator falls through:

```python
# hooks/guard-trusted-writes.py:389-401
    cmd = _neutralize_worktrees(cmd)
    if HARD_FRAG.search(cmd):
        return "hard"
    # R1 / Q-035: CLAUDE.md plus any home/global indicator -> the global file may be meant.
    if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):
        return "hard"
    # A10: settings*.json / hooks plus the config dir named anywhere.
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
    # Only a CLAUDE.md with NO home/global indicator anywhere reaches SOFT (Q-035).
    if SOFT_FRAG.search(cmd):
        return "soft"
    return None
```

(excerpt ends :401; enclosing `bash_targets()` starts at :385 — read.)

Executed results (tainted session; the `run` column is the real write when no hook stops the command):

| Command | 053c0b7 | 970e525 | Written |
|---|---|---|---|
| `echo EVIL > {W}/settings.json && env -C {W} cp {W}/settings.json -t..` | no-opinion | deny | `proj/.claude/settings.json` |
| `mkdir -p {W}/hooks && echo EVIL > {W}/hooks/x.sh && env -C {W} cp -r {W}/hooks -t..` | no-opinion | deny | `proj/.claude/hooks/x.sh` |
| `echo EVIL > {W}/settings.json && install -t.. {W}/settings.json` (cwd `{W}`) | no-opinion | deny | `proj/.claude/settings.json` |
| `cp {W}/settings.json -t..` (cwd `{W}`) | no-opinion | deny | `proj/.claude/settings.json` |
| `env -C {W} cp {W}/settings.json .{,.}` | no-opinion | — | `proj/.claude/settings.json` (cp exit 1, write done) |
| `env -C {W} cp {W}/settings.json --target-directory=..` (control) | deny | deny | — |

For comparison, the Edit tool on the same target, `proj/.claude/settings.json`, returns `ask` in this tainted session (`out-c3.txt`). So these routes are the pass-2 regression shape (Claim 6b of pass 2): a project `.claude/` write that 970e525 denied and that SOFT would at least ask on now gets no opinion, even when tainted. What limits it: the root check refuses worktrees inside the config dir (`_real_worktree_root`, `:314-317`), so one `..` step never reaches `~/.claude`. `../..` is caught (the second `..` follows `/`). When the session's cwd is already the worktree, `echo x > ../settings.json` had no opinion before this diff too, so the new reach there is only the `env -C` spelling from another cwd.

**Evidence:** `hooks/guard-trusted-writes.py:335-352`, `hooks/guard-trusted-writes.py:385-401`; `out-c2.txt` (cases 1-6), `out-c2-old.txt` (same cases, `PROBE_HOOK=hook-970e525.py`), `out-c3.txt`; commands `python3 h.py c2.json` / `bash old.sh` / `python3 h.py c3.json`, exit 0, 2026-09-24T00:03:54Z / 00:04:12Z / 00:06:16Z.

---

## Claim 3: The 835f99d per-word rule: an occurrence is exempt only when its word is absolute with no quote/expandable/`..`, the root is a real unsymlinked worktree dir with a `.git` file clear of the config dir, ~/.claude and HOME, and the resolved word stays inside the root

**Location:** `hooks/guard-trusted-writes.py:262-327`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers relative, missing-root, no-`.git`, symlinked-root, worktree-inside-config-dir and symlink-leading-out cases (the bats tests 57-64 at HEAD), plus `//`, `/./` and a trailing `/.` inside the word (exempt, and the write stays inside). It does not establish behavior on case-insensitive filesystems, bind mounts or hard-linked roots (not available on this Linux sandbox), or the hook-to-execution window beyond what Claim 1's gate covers.

```python
# hooks/guard-trusted-writes.py:321-327
def _exempt_worktree(word: str, root: str) -> bool:
    if _WT_UNSAFE.search(word) or not word.startswith("/"):
        return False
    root = os.path.normpath(root)
    if not _real_worktree_root(root):
        return False
    return _within(os.path.realpath(word), root)
```

`bats-head.txt`: all 83 tests pass at 053c0b7 (exit 0), including 57-64. `bats-f480-on-0358.txt` shows those tests fail at 035869c, so they exercise the rule. `out-c2.txt`: `{W}//settings.json`, `{W}/./settings.json`, `{P}//.claude/wt-a/settings.json` and `{W}/. ; echo > {W}/settings.json` are no-opinion. All resolve inside `{W}`. `{W}/sub/../../settings.json` is denied.

**Evidence:** `hooks/guard-trusted-writes.py:296-327`; `bats-head.txt`, `bats-f480-on-0358.txt`, `out-c2.txt`; command `bash bats.sh`, exit 0, 2026-09-24T00:04:28Z.

---

## Claim 4: `_neutralize_worktrees` runs before every indicator check, and neutralization cannot create a HARD_FRAG match

**Location:** `hooks/guard-trusted-writes.py:354-389`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers ordering inside `bash_targets()` and the replacement text. It does not establish that hiding a `.claude/settings` substring (for example a worktree named `wt-x.claude`) is harmless beyond the fact that such a word must resolve inside a real worktree root.

`cmd = _neutralize_worktrees(cmd)` (`:389`) is the first statement after the write check, and every classifier below it (`:390-400`) reads the rewritten `cmd`. Replacement inserts the literal `AGENT_WORKTREE` (`:380`), which contains no `.claude`, `hooks`, `settings` or `CLAUDE.md`, so it cannot create a HARD_FRAG match. `.claude/wt-x/../settings.json` is voided by the `..` gate before any replacement.

**Evidence:** `hooks/guard-trusted-writes.py:354-383`, `hooks/guard-trusted-writes.py:385-390`

---

## Claim 5: "resolve each entry: a checkout file that IS a live hook is HARD (resolved tier -> deny). A regular-file copy resolves into the config dir itself, which leaves its checkout original out of the HARD tier"

**Location:** `hooks/guard-trusted-writes.py:128-139`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers per-file links, a directory link, a dangling link, a copy, and a `hooks` dir that is itself a symlink. It does not establish behavior with a `CLAUDE_CONFIG_DIR` whose hooks dir is unreadable (the loop swallows the error).

```python
# hooks/guard-trusted-writes.py:134-139
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass
```

`out-n12.txt`: an Edit on a per-file-linked checkout hook is **deny**; a copied hook's source and an unlinked checkout hook are **no-opinion**; the linked checkout `global-instructions/CLAUDE.md` is **deny**. The comment speaks only of files, but the code does more. A link to a directory (`hooks/lib → co/hooks/lib`) makes the whole checkout subtree HARD, including a not-yet-existing file there (`co/hooks/lib/new-file.sh` → deny). A dangling link (`dangling.sh → co/hooks/gone.sh`) makes its missing target deny. A `hooks` dir that is itself a symlink into an `/opt`-like payload denies files there, including a new one. The precise version: "each entry's resolved target, file or directory tree, including a dangling target, is HARD." Pass 2 (Claim 7) reported the same wording gap. 053c0b7 left the comment as it was.

**Evidence:** `hooks/guard-trusted-writes.py:128-139`, `hooks/guard-trusted-writes.py:191-192`; `out-n12.txt`; command `bash n12.sh`, exit 0, 2026-09-24T00:05:52Z.

---

## Claim 6: ccda554: "Per-file link targets are read at hook load, like the other target sets."

**Location:** commit `ccda554` message; code `hooks/guard-trusted-writes.py:113-139`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Verified for the in-file part: the sets are built at module import, by code at the top level of the file. Not established: that Claude Code starts a new process for every hook call, which is what makes load-time targets fresh on each call. That depends on the harness and cannot be seen from the code.

The loop at `:134-139` (quoted in Claim 5) sits at module level, next to `_HARD_FILE_TARGETS` (`:120`) and `_HARD_DIR_TARGETS` (`:127`), and `main()` runs only under `if __name__ == "__main__":` (`:458-459`). Whether each hook event is a separate `python3` process (paraphrased — no quote available because this is Claude Code harness behavior outside this repo) needs the harness docs or a process trace.

**Evidence:** `hooks/guard-trusted-writes.py:113-139`, `hooks/guard-trusted-writes.py:458-459`

---

## Claim 7: Docstring: "Not gated here: Bash writes to a linked hook's CHECKOUT path (e.g. `echo x > <checkout>/hooks/<name>` on a bare host) get no opinion; only Edit/Write are denied there (N12)."

**Location:** `hooks/guard-trusted-writes.py:65-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `echo >` and `cp` to a per-file-linked hook's checkout path and to a file under a directory-linked hook dir, in a tainted session. It does not establish that the gap is listed in the `TODO(N2)`/`TODO(A8)` block (`:209-227`). It is not listed there; the docstring is the only place in the file that records it.

`out-n12.txt`: `echo x > co/hooks/log-usage.sh` and `cp /tmp/x co/hooks/log-usage.sh` are no-opinion. `out-n12b.txt`: `echo x > co/hooks/lib/util.sh` is no-opinion. The Edit tool on the same paths is deny. This answers brief item 0b: the Bash tier does not deny these writes, and both the docstring and the guide say so.

**Evidence:** `hooks/guard-trusted-writes.py:65-67`; `out-n12.txt`, `out-n12b.txt`; commands `bash n12.sh` / `bash n12b.sh`, exit 0, 2026-09-24T00:05:52Z / 00:07:08Z.

---

## Claim 8: Guide: "Bash writes to that checkout path (`echo x > <checkout>/hooks/<name>`, `cp`) are NOT gated by this hook, only Edit/Write are: a pre-existing gap, alongside the N2/A8 ones in the hook's TODOs. Hooks installed as copies are not affected."

**Location:** `guides/bare-host-hook-wiring.md:66-69`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the hooks half and the copies sentence. It does not establish that the sentence holds for the other file the paragraph names: "that checkout path" also refers to `global-instructions/CLAUDE.md`, and Bash writes there ARE denied.

The paragraph lists two checkout files: "`global-instructions/CLAUDE.md` behind a linked `~/.claude/CLAUDE.md`, and every `hooks/<name>` linked one file at a time" (`:61-63`). For the hook, the sentence holds: `echo`/`cp` to the linked hook's checkout path gets no opinion (`out-n12.txt`), and a copied hook's source gets no opinion from Edit (`out-n12.txt`, "copied.sh"). For the CLAUDE.md, `echo x > <checkout>/global-instructions/CLAUDE.md` is **deny** (`out-n12b.txt`), because `global-instructions` is a home indicator (`:243-244`: `_HOME_INDICATORS = [r"~", r"\$HOME\b", r"\$\{[!#]?HOME\b", r"\.claude\b", r"global-instructions", r"CLAUDE_CONFIG_DIR"]`). Precise version: "Bash writes to a linked hook's checkout path are not gated". Also, "alongside the N2/A8 ones in the hook's TODOs" reads as if the gap is in that TODO block; it is recorded only in the docstring (Claim 7).

**Evidence:** `guides/bare-host-hook-wiring.md:59-69`, `hooks/guard-trusted-writes.py:243-244`; `out-n12.txt`, `out-n12b.txt`.

---

## Claim 9: Guide: "No deny rule names the checkout path, so deferring would leave it with no gate at all."

**Location:** `guides/bare-host-hook-wiring.md:64-65`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the deny rules in `hooks/wiring.json`. It does not establish what a user's hand-merged settings contain. Context: aa21535 (not in this diff) found the single-slash spellings matched nothing. That makes the claim stronger, not weaker.

The `permissions.deny` entries in `hooks/wiring.json` name only `{{CLAUDE_DIR}}/settings*.json`, `{{CLAUDE_DIR}}/hooks/**`, `{{CLAUDE_DIR}}/CLAUDE.md`, `~/CLAUDE.md` (for Edit and Write) and three Read rules (paraphrased — no quote available because the list was extracted by a JSON walk rather than read at fixed lines). None names a checkout path.

**Evidence:** `hooks/wiring.json` (permissions.deny)

---

## Claim 10: 456bded: "Red against 970e525: tests 54, 55, 56 (worktree allow), 62 (N12) and 65 (N15) fail; the rest are regression pins that already pass" and "12 tests"

**Location:** commit `456bded` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the test file at 456bded run against 970e525's hook and against ccda554's hook. It does not establish the numbering at HEAD, where later commits add tests.

`@test` counts: 970e525 58, 456bded 70 (+12). Against 970e525 the 456bded file fails exactly 54, 55, 56, 62 and 65 (`bats-456-on-970.txt`). Against ccda554 all 70 pass (`bats-456-on-ccda.txt`). Also checked: f518532's tests at 835f99d fail 69-72, which matches "failing-first" (`bats-f518-on-835.txt`).

**Evidence:** `bats-456-on-970.txt`, `bats-456-on-ccda.txt`, `bats-f518-on-835.txt`; command `bash bats.sh`, exit 0, 2026-09-24T00:04:42Z–00:05:02Z.

---

## Claim 11: f480c24: "8 of the new tests fail at 035869c (red before the fix)."

**Location:** commit `f480c24` message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the count only. Pass 2 (Claim 15) reported this already; commit messages are immutable, so it is recorded, not new.

`bats-f480-on-0358.txt` shows 7 failures (57, 58, 59, 60, 61, 62, 64), not 8.

**Evidence:** `bats-f480-on-0358.txt`; command `bash bats.sh`, exit 0, 2026-09-24T00:05:14Z.

---

## Claim 12: N15: neither deny message points at a path Claude is blocked from editing, and the Bash advice ("write that text with the Write tool and pass the file") is allowed by the hook

**Location:** `hooks/guard-trusted-writes.py:424-428`, `hooks/guard-trusted-writes.py:447-450`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the message text and a Write to a temp file. It does not establish that "pass the file" works for every CLI a command might use (e.g. a commit message given with `-F <file>` still goes through the Bash tier, and would be denied if that command also names a protected path).

```python
# hooks/guard-trusted-writes.py:447-450
            emit("deny", f"This path is a live protected policy file ({Path(fp).name}: a global "
                         "hook, settings or CLAUDE.md, reached here by its real path or through a "
                         "symlink), so Claude's file tools cannot edit it. Make the change outside "
                         "Claude, in your own editor or shell, and review it there.")
```

Both messages name only a basename (`Path(fp).name`) or a category (`.claude hooks/settings, global CLAUDE.md`), never a path to edit instead (`out-n12.txt` prints both). `Write /tmp/claude-probe-msg.txt` is no-opinion (`out-n12.txt`).

**Evidence:** `hooks/guard-trusted-writes.py:421-428`, `hooks/guard-trusted-writes.py:443-450`; `out-n12.txt`.

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`hooks/guard-trusted-writes.py:335-352`): the `..` gate misses `..` attached to an option (`-t..`, because the lookbehind rejects a preceding letter) and a `..` built by brace expansion (`.{,.}`), and the directory-change list has no `env -C`. `env -C <wt> cp <wt>/settings.json -t..` (also `cp -r <wt>/hooks -t..`, `install -t..`) writes the parent project's `.claude/settings.json`/`hooks/` with no opinion, even when tainted. 970e525 denied these, and the Edit tool asks on the same target. Reach is bounded to the worktree's parent `.claude/` (SOFT tier), not `~/.claude`. Executed end to end.

### Stale
- (none new; pass-2 Claims 11/12 on commit ccda554 are unchanged and immutable)

### Mostly Accurate
- **Claim 5** (`hooks/guard-trusted-writes.py:128-133`): directory-valued and dangling entries also enter the HARD set (a whole checkout subtree, a missing target), not just "a checkout file". Unchanged since pass 2.
- **Claim 8** (`guides/bare-host-hook-wiring.md:66-69`): "Bash writes to that checkout path are NOT gated" is true for linked hooks only. Bash writes to the checkout `global-instructions/CLAUDE.md` are denied. The gap is in the docstring, not in the hook's TODO block.
- **Claim 11** (commit f480c24): 7 of the new tests fail at 035869c, not 8 (already reported in pass 2).

### Unverifiable
- **Claim 6** (commit ccda554): the load-time target sets are fresh on each call only if Claude Code starts a new hook process per event. That is harness behavior; it needs the harness docs or a process trace.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 053c0b7` line.
- Answered: yes. Brief items 00, 0, 0b and 1-6 are verdicted, mostly by execution against a real `git worktree add` fixture, with a 970e525 baseline for the regression.
- Out of scope: N2/A8 residuals are not re-filed. Glob/quote spellings (`.cla?de`, `cp -rs` via a glob) reach the same targets but were already ungated at 970e525, and `tar -C` is not a write primitive (A8). Code-quality judgments are out of scope.
- Escalate: Claim 2. The terminal pass still finds a gate bypass that turns a 970e525 deny (and an Edit-tier ask) into no opinion for the project's own `.claude/settings.json` and `hooks/`. Before merge, it needs either a gate change (a `..` preceded by a letter, brace expansion, `env -C`/`--chdir`) or an explicit accepted-residual decision.
