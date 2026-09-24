Commit: 835f99d

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-guard (branch ans/guard-q048-q050)
**Scope:** diff 970e525..835f99d — hooks/guard-trusted-writes.py, test/hooks/guard-trusted-writes.bats, guides/bare-host-hook-wiring.md, commit messages
**Checked:** 2026-09-23
**Total claims checked:** 10
**Summary:** 5 verified, 0 mostly accurate, 2 stale, 3 incorrect, 0 unverifiable

## Execution provenance

All runs used a temp HOME and a temp `CC_WEB_TAINT_DIR`, with `CLAUDE_CONFIG_DIR` unset. The probes only feed command text or file paths to the hook; no probe command was executed. Scratch dir `S` = `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/gfc-rr-r2`.

| Run | Command | cwd | Exit | Timestamp | Output |
|---|---|---|---|---|---|
| E1 HEAD suite | `bash S/run_bats.sh` (bats test/hooks/guard-trusted-writes.bats) | /workspace/.claude/wt-guard | 0 (78/78 ok) | 2026-09-23T16:42:37-07:00 | `S/bats-head.log` |
| E2 probes | `python3 S/probe.py` (real `git worktree add` fixture, fake-`.git` dir, bare-host linked hook) | temp dir | 0 | 2026-09-23T16:45:52-07:00 | `S/probe-head.log` |
| E3 TOCTOU + red run | `bash S/probe2.sh` | temp dirs | 0 (script); inner bats exit 1 | 2026-09-23T16:46:17-07:00 | `S/probe2.log`, `S/bats-456bded-vs-970e525.log` |

---

## Claim 1a: exemption conditions — the pass-1 bypasses are denied, and real absolute worktree paths are exempt

**Location:** `hooks/guard-trusted-writes.py:251-271`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pass-1 routes (quote-split `..`, `"$HOME"` before `/.claude`, `a=b=<home>`, `ln -s . .claude/wt-q`, a quoted `..` on a real worktree) plus `.claude//wt-foo`, globbing, `X=<wt>; > $X`, and a trailing `/.` followed by a real config write, all denied (E2). Real `wt-foo` and `worktrees/foo` absolute paths defer. Does not establish the same-command replacement route (Claim 1c) or the fake-`.git` behavior (Claim 1b).

E2 output (quoted from `S/probe-head.log`):
```
[deny  ] exp=deny  cd ~ && echo x > .claude/wt-x"/.."/settings.json
[deny  ] exp=deny  echo x > "$HOME"/.claude/wt-x/settings.json
[deny  ] exp=deny  echo x > a=b=/tmp/gfc-probe-mlbq_765/home/.claude/wt-x/settings.json
[deny  ] exp=deny  cd ~ && ln -s . .claude/wt-q && echo x > .claude/wt-q/settings.json
[defer ] exp=allow echo x > /tmp/gfc-probe-mlbq_765/repo/.claude/wt-foo/hooks/x.sh
```
`repo//.claude/wt-foo/...` and `wt-foo/./hooks/...` defer. Both resolve inside the real worktree, so that is consistent with the rule.

**Evidence:** `hooks/guard-trusted-writes.py:303-326`, `S/probe-head.log`

---

## Claim 1b: "holding a `.git` FILE, i.e. a git worktree" / docstring "a real, unsymlinked git worktree (a `.git` file)"

**Location:** `hooks/guard-trusted-writes.py:262-265`, `:52-53`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claimed mechanism, that the root must be a git worktree. Does not show the config dir being reached: the fake root must still be clear of the config dir, `~/.claude` and HOME, and the realpath must stay inside it. So the impact found is limited to writes inside that plain directory.

The code tests only that `.git` exists as a non-symlink regular file:
```python
# hooks/guard-trusted-writes.py:291-293 (excerpt inside _real_worktree_root :283-301 — read)
        git = os.path.join(root, ".git")
        if os.path.islink(git) or not os.path.isfile(git):
            return False
```
In E2, a plain directory `repo/.claude/wt-fake` whose `.git` holds `gitdir: /nonexistent` was exempt:
```
[defer ] exp=deny? echo x > /tmp/gfc-probe-mlbq_765/repo/.claude/wt-fake/settings.json
```
Precise version: "a directory containing a regular `.git` file (contents not checked)".

**Evidence:** `hooks/guard-trusted-writes.py:283-301`, `S/probe-head.log`

---

## Claim 1c: "neither is a worktree the same command creates or symlinks: it does not exist when the hook runs" (and the residual listed only as "a symlink created inside the worktree")

**Location:** `hooks/guard-trusted-writes.py:55-56`, `:264-265`, `:268-270`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the case where the same command replaces an existing, real worktree root with a symlink. Does not cover a worktree that does not exist yet, which is denied as claimed (Claim 2).

The root is checked when the hook runs, not when the command runs. The command `rm -rf <wt> && ln -s <link-to-config-dir> <wt> && echo x > <wt>/settings.json` gets no decision as long as the link target's spelling carries no `.claude` or config-dir token (E3):
```
[defer] rm -rf /tmp/tmp.rts57Z1BJD/repo/.claude/wt-foo && ln -s /tmp/tmp.rts57Z1BJD/x /tmp/tmp.rts57Z1BJD/repo/.claude/wt-foo && echo x > /tmp/tmp.rts57Z1BJD/repo/.claude/wt-foo/settings.json
[defer] ... && echo x > /tmp/tmp.rts57Z1BJD/repo/.claude/wt-foo/hooks/evil.sh
```
The staging link `ln -s <home>/.claude /tmp/x` also defers (E3, first line). That is the known, deferred A8 gap (`ln` is not a write primitive). The replacement step is new with this branch: 970e525 had no exemption, so its `.claude` + `settings.json` co-occurrence denies it (paraphrased — no quote available because this is inferred from the 970e525 rules, which Claim 6's run shows deny all non-worktree cases; not probed directly). When the variants spelled the link target as `<home>/.claude` (E2), the literal home-config indicator denied them. The docstring's residual should name the same-command replacement of an existing root, not only a symlink created inside it.

**Evidence:** `hooks/guard-trusted-writes.py:283-309`, `S/probe2.log`, `S/probe-head.log`

---

## Claim 2: "So a relative worktree path (`cd … && … .claude/wt-x/…`) is NOT exempt, and neither is a worktree the same command creates or symlinks"

**Location:** `hooks/guard-trusted-writes.py:49-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers relative paths, plus the same-command creation of a root that did not exist before (`ln -s . .claude/wt-q`), both denied (E1 tests, E2). Does not cover replacing a root that already exists; see Claim 1c, which refutes the broader reading.

The relative case is rejected by `not word.startswith("/")` (`hooks/guard-trusted-writes.py:304`).

**Evidence:** `hooks/guard-trusted-writes.py:304`, `S/bats-head.log`, `S/probe-head.log`

---

## Claim 3: "resolve each entry: a checkout file that IS a live hook is HARD (resolved tier -> deny). A regular-file copy … leaves its checkout original out of the HARD tier"

**Location:** `hooks/guard-trusted-writes.py:117-128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Edit/Write/MultiEdit file tools on per-file links and copies (E1 tests; E2 `Edit <checkout>/hooks/linked.sh` → deny). Does not cover the Bash tier (Claim 8). Also not executed: an entry that links to a directory, which adds the whole resolved directory to `_HARD_DIR_TARGETS` (`:126`) and so denies every file under it.

```python
# hooks/guard-trusted-writes.py:123-128
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass
```

**Evidence:** `hooks/guard-trusted-writes.py:116-128`, `:177-181`, `S/bats-head.log`, `S/probe-head.log`

---

## Claim 4: ccda554 — "An unexpanded relative worktree path (cd ~ && ... .claude/wt-x/...) is exempt, which only reaches ~/.claude/wt-x, not a HARD entry."

**Location:** commit ccda554 message
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the statement describes HEAD. Does not re-examine its truth at ccda554; pass 1 found it false via symlinks.

At HEAD a relative word is never exempt (`hooks/guard-trusted-writes.py:304`: `if _WT_UNSAFE.search(word) or not word.startswith("/"):`).

**Evidence:** `hooks/guard-trusted-writes.py:304`, commits ccda554, 835f99d

---

## Claim 5: ccda554 — "Copies resolve into the config dir and leave their source ungated."

**Location:** commit ccda554 message
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the CLAUDE.md copy at HEAD: its source asks when tainted (E1 test "with a regular-file ~/.claude/CLAUDE.md copy"). A copied hook's source is still ungated, as stated.

Already corrected by 835f99d (`hooks/guard-trusted-writes.py:31-33`: "a copied hook's source is ungated, a copied CLAUDE.md's source is SOFT (ask when tainted)").

**Evidence:** `hooks/guard-trusted-writes.py:31-33`, `S/bats-head.log`

---

## Claim 6: 456bded — "Red against 970e525: tests 54, 55, 56 (worktree allow), 62 (N12) and 65 (N15) fail; the rest are regression pins" / "12 tests"

**Location:** commit 456bded message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 456bded test file run against `970e525:hooks/guard-trusted-writes.py` (E3): 70 tests, with exactly `not ok` 54, 55, 56, 62 and 65; the diff adds 12 `@test` blocks. The numbers refer to the 456bded file; HEAD renumbers them.

Quoted from `S/probe2.log`:
```
not ok 54 Q-048: a Bash write into a .claude/wt-* worktree's hooks/ is not denied
not ok 55 Q-048: a Bash write into a .claude/worktrees/<name> worktree's hooks/ is not denied
not ok 56 Q-048: a worktree CLAUDE.md write is SOFT (defer; ask when tainted), not denied
not ok 62 Q-050 / N12: a per-file symlinked hook's checkout target is denied
not ok 65 N15: the resolved-path deny reason does not send the user to a denied path
12
```

**Evidence:** `S/probe2.log`, `S/bats-456bded-vs-970e525.log`

---

## Claim 7: guide — "No deny rule names the checkout path, so deferring would leave it with no gate at all" / "Hooks installed as copies are not affected"

**Location:** `guides/bare-host-hook-wiring.md:59-67`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the shipped `hooks/wiring.json` deny list, where every Edit/Write rule is anchored at `{{CLAUDE_DIR}}` or `~/CLAUDE.md`, and the copy half (Claim 3). Does not establish what a user's hand-merged settings contain.

Quoted from `hooks/wiring.json` (the deny array):
```
"Edit({{CLAUDE_DIR}}/settings*.json)", "Edit({{CLAUDE_DIR}}/hooks/**)",
"Edit({{CLAUDE_DIR}}/CLAUDE.md)", "Edit(~/CLAUDE.md)"  (and matching Write rules)
```
No rule names `global-instructions/` or a checkout `hooks/` path.

**Evidence:** `hooks/wiring.json` (deny array), `guides/bare-host-hook-wiring.md:59-70`

---

## Claim 8: guide — "the guard denies Claude's file tools on its checkout copy" (the Bash tier on the same path is not stated)

**Location:** `guides/bare-host-hook-wiring.md:59-62`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Bash writes by redirect and by `cp` to a linked hook's checkout path in a temp-HOME bare-host layout. Does not establish behavior when the command also names `.claude` elsewhere, which would be denied by co-occurrence.

The guide's sentence is literally scoped to the file tools. But it follows "No deny rule names the checkout path, so deferring would leave it with no gate at all", and the Bash tier leaves exactly that path with no gate. A reader would conclude the checkout copy is protected. E2:
```
[defer ] exp=?     echo x > /tmp/gfc-probe-mlbq_765/claude-workflows/hooks/linked.sh
[defer ] exp=?     cp /tmp/p /tmp/gfc-probe-mlbq_765/claude-workflows/hooks/linked.sh
[deny  ] exp=deny  Edit /tmp/gfc-probe-mlbq_765/claude-workflows/hooks/linked.sh
```
`bash_targets` never consults `_HARD_FILE_TARGETS`. It ends `return None` when no `.claude`/config-dir token is present (`hooks/guard-trusted-writes.py:339-344`). The same gap exists at 970e525, so this branch did not make it worse, but the new guide paragraph and N12 claim a gate that holds only for the file tools. The docstring's N12 text (`:25-28`) is placed under "For the FILE tools" and is accurate there.

**Evidence:** `guides/bare-host-hook-wiring.md:59-67`, `hooks/guard-trusted-writes.py:328-344`, `S/probe-head.log`

---

## Claim 9: N15 — deny messages do not point at a denied path; the Bash advice ("write that text with the Write tool and pass the file") is allowed

**Location:** `hooks/guard-trusted-writes.py:367-371`, `:389-393`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the message text (E1 N15 test) and the static read that a temp file classifies as `none` (`:195`). Does not establish that other hooks or deny rules permit that Write.

```python
# hooks/guard-trusted-writes.py:390-393
            emit("deny", f"This path is a live protected policy file ({Path(fp).name}: a global "
                         "hook, settings or CLAUDE.md, reached here by its real path or through a "
                         "symlink), so Claude's file tools cannot edit it. Make the change outside "
                         "Claude, in your own editor or shell, and review it there.")
```

**Evidence:** `hooks/guard-trusted-writes.py:160-195`, `:367-371`, `:389-393`, `S/bats-head.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1c** (`hooks/guard-trusted-writes.py:55-56, 264-270`): replacing an existing worktree root with a symlink in the same command is still exempt (check at hook time, use at run time); a write reaches the config dir's `settings.json`/`hooks/` with no decision. This route is new with this branch. Legibility-target: for-author
- **Claim 8** (`guides/bare-host-hook-wiring.md:59-62`): Bash writes (`>`, `cp`) to a linked hook's checkout path get no decision, while the file tools are denied; the guide implies the checkout copy is gated. Pre-existing gap, not stated. Legibility-target: for-author
- **Claim 1b** (`hooks/guard-trusted-writes.py:262-265`): any directory with a regular `.git` file passes as a "git worktree"; contents are not checked. Writes stay inside that directory. Legibility-target: for-author

### Stale
- **Claim 4** (commit ccda554): relative worktree paths are no longer exempt. Legibility-target: for-author
- **Claim 5** (commit ccda554): a copied CLAUDE.md's source is SOFT; already corrected in 835f99d. Legibility-target: for-author

Legibility-target for Verified claims 1a, 2, 3, 6, 7, 9: for-orchestrator-synthesis.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 835f99d` line.
- Answered: yes
- Out of scope: behavior on case-insensitive filesystems and bind-mounted roots (no such filesystem in the sandbox); hand-merged user settings
- Escalate: Claim 1c — a same-command worktree replacement writes the config dir with no decision
