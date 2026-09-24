Commit: 053c0b7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-guard (branch `ans/guard-q048-q050`)
**Scope:** branch diff `970e525..053c0b7` (hooks/guard-trusted-writes.py, test/hooks/guard-trusted-writes.bats, guides/bare-host-hook-wiring.md) and commit messages; pass 3 (terminal) after fixes f518532/053c0b7
**Checked:** 2026-09-24
**Total claims checked:** 9
**Summary:** 7 verified, 0 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Execution note: the executed verdicts rest on the repo's own bats suite, run at HEAD and run again against the 970e525 hook. A second round of bespoke execution probes (end-to-end runs of candidate bypass commands in a temp-HOME fixture) was **not carried out in this pass**. Claim 1 is therefore static, and the brief's item-00 hunt list is reported as partly unexecuted (Claim 9). Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`): no claim matches a logged pattern.

---

## Claim 1: "One the same command REPLACES would pass this time-of-check test, which is why the whole-command gate below voids the exemption for any rm/mv/ln" / "one created by the same command needs ln, which the gate rejects" / docstring "replaces with a symlink (that needs rm/mv and ln, which void the exemption)"

**Location:** `hooks/guard-trusted-writes.py:277-284`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the mechanism claim that creating a symlink or replacing a worktree root in the same command requires the words `ln`/`rm`/`mv`. It does not establish, by execution, an end-to-end write outside the worktree, and it does not establish impact beyond the pre-existing N2/A8 classes.
**Legibility-target:** for-author

The gate's token list is fixed:

```python
# hooks/guard-trusted-writes.py:343-346
_WT_GATE_DOTDOT = re.compile(r"(?<![\w.-])\.\.(?![\w.-])")
_WT_GATE_CMD = re.compile(
    r"(?<![\w.-])(?:cd|pushd|popd|ln|mv|rm|sh|bash|zsh|dash|ksh|eval|exec|source"
    r"|xargs|awk|gawk|python[0-9.]*|node|perl|ruby)(?![\w.-])")
```

The per-word check resolves the path at hook time, using only what exists then:

```python
# hooks/guard-trusted-writes.py:321-327 (complete function)
def _exempt_worktree(word: str, root: str) -> bool:
    if _WT_UNSAFE.search(word) or not word.startswith("/"):
        return False
    root = os.path.normpath(root)
    if not _real_worktree_root(root):
        return False
    return _within(os.path.realpath(word), root)
```

Standard tools other than `ln` can create a symlink, and tools other than `rm`/`mv` can remove a directory. Coreutils `cp` makes links with `-s` and keeps an existing link as a link with `-P`/`-d`/`-a`. Archive extraction and `git checkout` can materialize tracked symlinks. `rmdir`, `find -delete` and `git worktree remove` delete directories. None of these words is in `_WT_GATE_CMD`, and `rmdir` escapes the `rm` match because the trailing `(?![\w.-])` rejects the following `d`. (Paraphrased — no quote available because the claim is about the behavior of external utilities, not code in this repo.) A path component that does not exist when the hook runs resolves "inside the root", so a link that the same command creates later is not visible to `realpath`. So the stated mechanism ("needs ln / rm+mv") is refuted. The listed residual (script, make, git hook; line 288) is also incomplete: it omits the ordinary utilities above.

Mitigating context (not a softening of the verdict): the prior call can already plant a symlink alias to the config dir that names no indicator token, and writing through that alias gets no opinion even at 970e525. That is the N2 "no indicator token" class. The route above is therefore roughly equivalent in capability to a known deferred gap. The defect is that the comment and docstring claim a closure the code does not provide.

**Evidence:** `hooks/guard-trusted-writes.py:59-62`, `hooks/guard-trusted-writes.py:277-289`, `hooks/guard-trusted-writes.py:321-327`, `hooks/guard-trusted-writes.py:343-352`

---

## Claim 2: "Not gated here: Bash writes to a linked hook's CHECKOUT path (e.g. `echo x > <checkout>/hooks/<name>` on a bare host) get no opinion; only Edit/Write are denied there (N12). Pre-existing, alongside N2/A8."

**Location:** `hooks/guard-trusted-writes.py:65-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Bash tier's handling of a checkout path containing `hooks` but no `.claude`/config-dir text. It does not establish behavior when the checkout lives under a path that contains `.claude`.
**Legibility-target:** for-orchestrator-synthesis

`bash_targets` never consults `_HARD_FILE_TARGETS`/`_HARD_DIR_TARGETS`. A `hooks` mention needs a config indicator:

```python
# hooks/guard-trusted-writes.py:395-397 (excerpt ends :397; enclosing bash_targets() continues to :401 — read)
    # A10: settings*.json / hooks plus the config dir named anywhere.
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
```

The remaining branch (`SOFT_FRAG`, :399-400) does not match `hooks/<name>`, so the result is `None`, which means defer. This closes the pass-2 Incorrect ("not stated anywhere"). The guide now says the same thing (`guides/bare-host-hook-wiring.md`, diff lines 17-18).

**Evidence:** `hooks/guard-trusted-writes.py:385-401`, `hooks/guard-trusted-writes.py:65-67`

---

## Claim 3: whole-command gate — each listed token class voids the exemption; `/x/rmdata`, `--cdn`, `cd-tools` do not trip it; plain absolute worktree writes stay exempt (commit 053c0b7, comment :329-342)

**Location:** `hooks/guard-trusted-writes.py:329-352`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exact commands pinned in the four "Q-048 gate" tests: cd/`..`/pushd/`.""./`, tainted cd routes, the rm+ln and mv+ln swaps including `/bin/rm`/`/bin/ln`, `$(dirname)`, backticks, xargs, python -c, `sh -c 'l""n'`, a policy name outside the worktree word, and the look-alike words. It does not establish that the gate catches other directory-changing, linking or deleting programs (see Claims 1 and 9).
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:348-352 (complete function)
def _whole_command_allows_exemption(cmd: str) -> bool:
    if "$" in cmd or "`" in cmd:
        return False
    flat = re.sub(r"[\"'\\]", "", cmd)
    return not (_WT_GATE_DOTDOT.search(flat) or _WT_GATE_CMD.search(flat))
```

Command `bats test/hooks/guard-trusted-writes.bats`, cwd `/workspace/.claude/wt-guard`, 2026-09-24T00:03:23Z, exit 0, 83/83 ok. Tests 70-73 ("Q-048 gate: …") all pass.

**Evidence:** `hooks/guard-trusted-writes.py:343-383`, `test/hooks/guard-trusted-writes.bats` (gate tests, diff lines 459-519), `docs/reviews/execution-logs/gfc-p3-r2-bats-head-053c0b7.log`

---

## Claim 4: pass-1 and pass-2 routes are denied at HEAD (835f99d + 053c0b7 design)

**Location:** `hooks/guard-trusted-writes.py:290-383`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every command pinned in the Q-048 bypass and gate tests: quote-split `..`, quoted home prefix, second `=`, wt-shaped CLAUDE_CONFIG_DIR, symlinked worktree, worktree inside the config dir, an outbound symlink inside a worktree, and the cd/`..`/swap routes. It does not establish denial of unpinned spellings.
**Legibility-target:** for-orchestrator-synthesis

The same 83/83 HEAD run as Claim 3 applies. The same tests were also run against the 970e525 hook (Claim 6): every deny pin passes there too. So on the pinned commands, HEAD restores 970e525's denials.

```python
# hooks/guard-trusted-writes.py:354-356 (excerpt ends :356; enclosing _neutralize_worktrees() continues to :383 — read)
def _neutralize_worktrees(cmd: str) -> str:
    if not _WT_SEG.search(cmd) or not _whole_command_allows_exemption(cmd):
        return cmd
```

**Evidence:** `hooks/guard-trusted-writes.py:354-389`, `docs/reviews/execution-logs/gfc-p3-r2-bats-head-053c0b7.log`, `docs/reviews/execution-logs/gfc-p3-r2-bats-head-tests-vs-970e525-hook.log`

---

## Claim 5: N12 — "resolve each entry: a checkout file that IS a live hook is HARD (resolved tier -> deny). A regular-file copy resolves into the config dir itself, which leaves its checkout original out of the HARD tier"

**Location:** `hooks/guard-trusted-writes.py:128-139`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-file links and copies (tests 75-77 pass). It does not establish the effect of an entry that resolves to a broad directory. Statically, `_t.is_dir()` adds any linked directory's whole tree to `_HARD_DIR_TARGETS`, so an entry resolving to HOME or `/` would deny every Edit/Write under it. A dangling link lands in `_HARD_FILE_TARGETS` harmlessly.
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:134-139
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass
```

**Evidence:** `hooks/guard-trusted-writes.py:127-139`, `hooks/guard-trusted-writes.py:191-192`, `docs/reviews/execution-logs/gfc-p3-r2-bats-head-053c0b7.log`

---

## Claim 6: 456bded — "Red against 970e525: … worktree allow … N12 … N15 fail; the rest are regression pins that already pass"

**Location:** commit 456bded message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the HEAD test file run against the 970e525 hook. Test numbers have shifted since 456bded because later commits added tests. It does not re-establish 456bded's exact "12 tests" count, which pass 2 verified at that commit.
**Legibility-target:** for-orchestrator-synthesis

Command `python3 oldrun.py` ran the HEAD `.bats` file against `970e525:hooks/guard-trusted-writes.py`. It was run from the scratchpad directory `gfc-p3-r2/`, with the tree copied there, at 2026-09-24T00:03:56Z; exit 1. Exactly 6 tests failed: 54, 55, 56 (worktree allow), 73 (plain worktree write still exempt), 75 (N12) and 78 (N15). Every deny pin passed. That matches the claim's split, now including 073's allow case. (Paraphrased — no quote available because the evidence is test output, captured in the log.)

**Evidence:** `docs/reviews/execution-logs/gfc-p3-r2-bats-head-tests-vs-970e525-hook.log`

---

## Claim 7: guide — "No deny rule names the checkout path, so deferring would leave it with no gate at all" / "Hooks installed as copies are not affected" / Bash writes to the checkout path "are NOT gated by this hook"

**Location:** `guides/bare-host-hook-wiring.md:59-72`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the wiring.json deny list and the hook's copy and Bash handling. It does not establish whether a user's hand-merged settings.json adds other rules (Q-049 context: the single-slash rules matched nothing).
**Legibility-target:** for-orchestrator-synthesis

```json
// hooks/wiring.json:120-124
      "Edit({{CLAUDE_DIR}}/settings*.json)",
      "Write({{CLAUDE_DIR}}/settings*.json)",
      "Edit({{CLAUDE_DIR}}/hooks/**)",
      "Write({{CLAUDE_DIR}}/hooks/**)",
      "Edit({{CLAUDE_DIR}}/CLAUDE.md)",
```

Every deny rule is rooted at `{{CLAUDE_DIR}}`, so none names a checkout path. The copies statement is pinned by test 76 (a copied hook's checkout file defers), and the Bash statement matches Claim 2.

**Evidence:** `hooks/wiring.json:115-126`, `guides/bare-host-hook-wiring.md:59-72`

---

## Claim 8: N15 — neither deny message points at a denied path; the Bash advice ("write that text with the Write tool and pass the file") is allowed

**Location:** `hooks/guard-trusted-writes.py:424-428`, `hooks/guard-trusted-writes.py:447-450`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message text and `classify_path` for a prose file at a neutral path. It does not establish the advice for a prose file placed under a `.claude/`, `skills/`… path or named CLAUDE.md, which falls to SOFT or HARD.
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:447-450
            emit("deny", f"This path is a live protected policy file ({Path(fp).name}: a global "
                         "hook, settings or CLAUDE.md, reached here by its real path or through a "
                         "symlink), so Claude's file tools cannot edit it. Make the change outside "
                         "Claude, in your own editor or shell, and review it there.")
```

Only the basename is interpolated. For a neutral path, `classify_path` reaches `return "none"` (:206), so the Write is deferred.

**Evidence:** `hooks/guard-trusted-writes.py:171-206`, `hooks/guard-trusted-writes.py:418-454`

---

## Claim 9: brief item 00 — the gate misses no other directory-changing or file-moving program (install, cp -s/-l, rsync, tar, git -C/mv, find -exec, env -C, subshells, `${`, here-strings, process substitution, newline or `;`/`&&` chaining)

**Location:** `hooks/guard-trusted-writes.py:329-383`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Static reading only. It covers the forms the code handles by construction: `${`, `$(`, backtick and `<(`/`>(` are voided by the `$`/backtick test or leave the word boundary at `(`; `\n`, `;`, `&`, `|` are word delimiters, and the gate regex scans the whole text. It does not establish the executed behavior of the program-name cases.
**Legibility-target:** for-orchestrator-synthesis

Statically: `git mv` and `(cd` trip the gate (`mv`/`cd` bounded by a space or `(`), and `find -exec sh` trips on `sh`. `env -C`, `git -C`, `install`, `rsync`, `tar` and `cp` are not in `_WT_GATE_CMD`. A cwd change alone is backstopped by the rest check, which re-enables every `.claude` when a policy name appears outside the exempt words:

```python
# hooks/guard-trusted-writes.py:374-376 (excerpt ends :376; enclosing _neutralize_worktrees() continues to :383 — read)
    rest = " ".join(outside)
    if SETTINGS_OR_HOOKS.search(rest) or CLAUDE_MD.search(rest):
        return cmd
```

The link-creating and deleting programs are the gap covered in Claim 1. Blocker: the per-program execution probes were not run in this pass. Running them end to end in a temp-HOME fixture would be needed to verify.

**Evidence:** `hooks/guard-trusted-writes.py:290-296`, `hooks/guard-trusted-writes.py:343-383`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`hooks/guard-trusted-writes.py:277-289`, docstring `:59-62`): the comment and docstring say a same-command symlink or root swap "needs ln" / "rm/mv and ln". The code's fixed token list does not cover other standard link-creating and deleting utilities (cp link modes, archive or git checkout of tracked symlinks, rmdir/find -delete/git worktree remove), and a not-yet-existing link resolves "inside" the root at hook time. Either widen the gate or state this as a residual next to the script/make/git-hook one. Capability is roughly on par with the deferred N2 symlink-alias class.

### Unverifiable
- **Claim 9** (`hooks/guard-trusted-writes.py:329-383`): the per-program bypass hunt was not executed this pass. It needs end-to-end probes in a temp-HOME fixture.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 053c0b7` line.
- Answered: partial — doc and commit claims verdicted; pinned routes verified by execution; the bespoke bypass-execution probes were not run.
- Out of scope: N2/A8 routes not made worse by this diff; N11/N13.
- Escalate: Claim 1 (doc claims an ln/rm/mv-only closure that the token list does not provide) and Claim 9 (item-00 hunt unexecuted). The orchestrator should decide whether another reviewer runs the execution probes.
