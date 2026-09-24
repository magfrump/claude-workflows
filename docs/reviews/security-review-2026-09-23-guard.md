Commit: 3e9e448

# Security Review — `ans/guard-q048-q050` (net diff `970e525..3e9e448`, confirmation pass)

**Scope:** `hooks/guard-trusted-writes.py` (whole file read, 326 lines), `test/hooks/guard-trusted-writes.bats` (+345), `guides/bare-host-hook-wiring.md` (+14); context: `README.md:10-32`, `hooks/log-usage.sh:10-14`, `hooks/log-usage-post.sh:19-20`, `hooks/wiring.json:49-107`
**Date:** 2026-09-23
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 3e9e448; runs E1-E5), plus one probe run of my own (P1, below)
**Known and deferred, not re-filed:** N2, A8, N3 (`docs/reviews/override-log.md`), except where Finding 2 says this diff makes A8 easier to find.

Execution provenance for P1: `python3 $P/probe.py`, exit 0, 2026-09-24T00:21Z (sandbox clock), temp `HOME` under `$P`, `CLAUDE_CONFIG_DIR` unset, never the real `~/.claude`. `$P` = `/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/secprobe`. Output is in `$P/probe.log`. The probe builds the README bare-host layout: per-file links for `log-usage.sh`, and `~/.claude/scripts` linked to the checkout `scripts/`.

## Trust Boundary Map

```
B1:          [model tool_input (steerable by web-tainted content)] → [guard: classify_path / bash_targets] → [host file write]
B2 (new):    [~/.claude/hooks entries + link targets (filesystem)] → [N12 per-entry resolve loop, :125-130]  → [HARD target sets used by B1]
B3 (moved):  [guard deny-reason text]                                → [returned to the model]                   → [the model's next tool call]
B4:          [checkout files sourced by a linked hook]              → [harness hook runner, every tool call]   → [code execution outside the file tools' gate]
```

| Label | Source | Mutability | Trust classification (per sink) |
|---|---|---|---|
| S1 | `tool_input.command` / `file_path` | request-time | UNTRUSTED for every sink (write, exec). This is the thing the guard gates. |
| S2 | entries of `CONFIG_DIR/hooks`, their link targets, and the permissions of the target dirs | runtime-mutable (`ln -sf` is A8, `chmod` is ungated) | UNTRUSTED when it drives a security decision: it decides what is HARD, so a crafted entry changes the gate. |
| S3 | `HOME`, `CLAUDE_CONFIG_DIR` | deploy-time | trusted |
| S4 | deny-reason string constants (`:291-295`, `:314-317`) | code-constant | trusted as data. It becomes an instruction to a possibly-steered model (B3), so read it as advice to an adversary too. |
| S5 | `hooks/lib/*.sh`, `scripts/lib/*.sh` in the checkout | runtime-mutable (plain repo files) | UNTRUSTED toward exec: a hook the harness runs sources them. |

The diff adds B2. It makes a filesystem listing decide the HARD tier, where before only fixed names under the config dir did. That closes Edit/Write on per-file-linked hooks (N12). It changes the B3 text so it no longer points at a denied path (N15). The worktree exemption is gone and B1's Bash tier is back to 970e525 (fact-check Claims 9a/14/15, E2). The diff assumes that "live hook code" means "the files linked into `~/.claude/hooks/`". B4 shows that assumption is too narrow.

## Findings

#### 1. A tainted session can still edit code that every linked hook sources

**Severity:** Medium
**Location:** `hooks/guard-trusted-writes.py:119-130` (N12 loop), `:162-197` (`classify_path`); `hooks/log-usage.sh:11,14`; `hooks/log-usage-post.sh:20`
**Boundary:** B4, B2
**Move:** 11 (bypass enumeration for the N12 guard), 1
**Confidence:** High (executed, P1 and fact-check E4)
**Legibility-target:** for-author

N12 treats a checkout file as a live hook only when a `~/.claude/hooks/` entry resolves to it. On the README layout, `log-usage.sh` resolves its own link and `source`s `hooks/lib/usage-common.sh` and `scripts/lib/skill-paths.sh` from the checkout. `wiring.json:49-107` runs it on every PreToolUse and PostToolUse. Those sourced files classify `none` through their checkout paths, so the hook **defers, even in a web-tainted session**. That is weaker than SOFT: there is not even an ask. A prompt-injected session can therefore add code that runs on every later tool call of every session, through the harness hook runner, with no prompt. That is the persistence this guard exists to stop. The linked hook itself is now denied, and the exploit moves one `source` line away. This was pre-existing: at 970e525 the hook file itself was editable. So the diff narrows the hole but does not close it, and it is not covered by N2/A8/N3. Spelling also changes the gate: the same `skill-paths.sh`, reached as `~/.claude/scripts/lib/...`, asks.

**Evidence:**
```
[Edit linked hook (tainted)] deny
[Edit sourced hooks/lib (tainted)] defer
[Edit sourced scripts/lib via checkout (tainted)] defer
[Edit sourced scripts/lib via ~/.claude/scripts (tainted)] ask
```
```bash
# hooks/log-usage.sh:11
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/usage-common.sh"
```

**Recommendation:** Pick one of two fixes. The first: when a linked entry resolves into a checkout `hooks/` dir, add that entry's parent `hooks/` dir and the sibling `scripts/lib` to the targets. Classify them HARD or at least SOFT; SOFT only asks, so over-matching there is safe. The second: record this as a known gap in the docstring and the guide next to the "Not gated here" sentence, and let the planned copy-based install close it. In either case, stop the guide's heading "Symlinked global files can't be edited from Claude" from implying full coverage (fact-check Claim 1).

#### 2. The new Bash deny message suggests script-file indirection, which is the A8 bypass

**Severity:** Medium
**Location:** `hooks/guard-trusted-writes.py:291-295`
**Boundary:** B3, B1
**Move:** 2, 11
**Confidence:** Medium (the bypass is executed; its effect on model behaviour is inferred)
**Legibility-target:** for-author

The deny reason goes back to the model, and the model may be following injected instructions. The new text says: "If the command only mentions such a path in prose (a heredoc or message), write that text with the Write tool and pass the file instead." A steered model can follow that literally. It writes the same `echo x >> ~/.claude/settings.json` into a scratch file with Write (defer: not a policy path), then runs `bash <file>` or `sh < <file>`. Neither has a recognised write primitive, so both defer, even when tainted. The underlying gap is A8 ("`python3 script.py` (non-inline interpreters)"), which is logged and deferred. The diff's contribution is that the guard's own deny message now shows the model the route after the direct attempt is blocked. That makes A8 easier to find. 970e525's text ("Edit it directly with review, not via a shell write") did not describe an indirection.

**Evidence:**
```
[Bash direct write settings (tainted)] deny
[Write script to scratch (tainted)] defer
[Bash run script (tainted)] defer
[Bash sh < file (tainted)] defer
```
```python
# hooks/guard-trusted-writes.py:293-295
                         "editor or shell, and review it there. If the command only mentions such a "
                         "path in prose (a heredoc or message), write that text with the Write tool "
                         "and pass the file instead.")
```

**Recommendation:** Name the non-executing consumers in the hint ("pass it with `git commit -F` / `--body-file`"), so it no longer reads as "put it in a file and hand it to something". Better still, drop the hint from the deny text and document it in the guide, where a human reads it. Separately, fact-check Claim 12b: this same message tells project and worktree `.claude/` writers to go "outside Claude", but those paths are SOFT for Edit/Write. That is a human-factors issue: it trains users to paste denied commands into their own shell.

#### 3. One unreadable hooks entry stops the N12 loop and leaves the linked hooks after it editable

**Severity:** Low
**Location:** `hooks/guard-trusted-writes.py:125-130`
**Boundary:** B2
**Move:** 3 (error path)
**Confidence:** Medium (the fail-open is executed; I could not build an attacker-reachable ordering)
**Legibility-target:** for-author

`_safe_resolve` catches exceptions, but `_t.is_dir()` raises `PermissionError` when the target's parent dir cannot be traversed. The only `try` is around the whole loop, so the first such entry drops every entry after it from the HARD sets, and the hook fails open (defer) for those links. P1 confirmed this with one entry linked into a mode-000 directory: Edit on the per-file-linked `log-usage.sh` went from deny to defer. `chmod` is ungated (S2), but the only layout I could construct makes the Edit target unreachable as well, because all README links point into one dir. So I rate this Low and not Medium: the fail-open is real, and I have not shown it reachable. `iterdir` order is arbitrary, so the effect is also nondeterministic.

**Evidence:**
```
is_dir raised: PermissionError
[Edit linked hook with an unreadable sibling entry] defer
```
```python
# hooks/guard-trusted-writes.py:125-130
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass
```

**Recommendation:** Put the `try` around each entry, and on error add `_t` to *both* sets, which fails closed. Add a bats case with an unreadable sibling entry.

#### 4. A link inside a real subdirectory of `~/.claude/hooks/` is not resolved

**Severity:** Informational
**Location:** `hooks/guard-trusted-writes.py:125-130`
**Boundary:** B2
**Move:** 11
**Confidence:** High (fact-check E3)
**Legibility-target:** for-author

The resolution goes one level deep, so `~/.claude/hooks/sub/x -> <checkout>/hooks/x` leaves the checkout file defer. No shipped layout creates that shape. I note it so the docstring's "resolve each entry" is not read as recursive.

**Evidence:** `[nested link inside real subdir] defer` (fact-check Claim 11 table, `$S/probe.log`)

**Recommendation:** Say "top-level entries" in the comment, or walk the tree with a depth cap.

## Untested bypass candidates (N12 guard)

- **Replace or add an entry with `ln -sf <x> ~/.claude/hooks/<y>`.** `ln` is not a write primitive (A8), so this defers, and it rewrites S2 itself. Not tested here: it is known and deferred under A8, and this diff does not make it worse.
- **An existing hardlink to a checkout hook, edited through the hardlink path.** Traced statically only: `resolve()` does not follow hardlinks, so `rp` misses the target set and the path defers. Creating the hardlink needs `ln` (A8). Not executed.

Tested candidates: a sourced lib (Finding 1), an unreadable sibling (Finding 3), a nested link (Finding 4), and a Bash write to the checkout hook (fact-check E3: defer, which the docstring `:56-58` documents as pre-existing in the N2 class).

## Endorsement Claims

- **Claim:** The hook at 3e9e448 contains no worktree-specific code path. On every Q-048 test in the HEAD bats file, including all the pass-1/2/3 bypass commands, its Bash-tier decisions equal the 970e525 hook's.
  **Location:** `hooks/guard-trusted-writes.py:219-268`
  **Evidence:** executed (fact-check E1 85/85; E2: the HEAD bats file against the 970e525 hook fails only tests 77 (N12) and 80 (N15))
  **Verified:** the five-hunk diff touches no `bash_targets` logic or regex (fact-check Claim 9a), and the Q-048 tests pass on both hooks.
  **Not verified:** equivalence on Bash inputs outside the bats file, for example new spellings in the N2 class.
  **route: code-fact-check**

- **Claim:** For a per-file-linked hook and for the checkout `global-instructions/CLAUDE.md`, Edit, Write and MultiEdit on the checkout path return `deny`, clean and tainted.
  **Location:** `hooks/guard-trusted-writes.py:182-183,310-317`
  **Evidence:** executed (fact-check E1 test "Q-050 / N12…", E3; P1 `[Edit linked hook (tainted)] deny`)
  **Verified:** the decision for the per-file link and CLAUDE.md cases in a README-shaped temp HOME.
  **Not verified:** files those hooks source (Finding 1), nested links (Finding 4), and the loop's error path (Finding 3).
  **route: code-fact-check**

- **Claim:** The resolved-tier deny message no longer names a `~/.claude` path (N15).
  **Location:** `hooks/guard-trusted-writes.py:314-317`
  **Evidence:** executed (fact-check E1 N15 test; E2 fails on 970e525)
  **Verified:** the reason string lacks `~/.claude path` and contains `outside Claude`.
  **Not verified:** how the Claude Code UI shows a hook deny (fact-check Claim 4).

## Primitive sweep

Primitive: path resolution / symlink following (`resolve`, `iterdir`, `is_dir`), which decides the HARD tier

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `:101` `_safe_resolve` | S1, S2, S3 | catches all exceptions, returns the input | cleared: failing to resolve returns the literal, which the lexical checks still see |
| `:106` `GLOBAL_DIRS` | S3 | `_safe_resolve` | cleared: deploy-time |
| `:111`, `:117`, `:118` target sets | S3 (+ S2 link targets) | `_safe_resolve` | cleared: unchanged from 970e525 |
| `:126` `iterdir()` (new) | S2 | the loop-level `try` | Finding 3 (one error stops the whole loop) |
| `:127` `_safe_resolve(_e)` (new) | S2 | catches exceptions | Finding 4 (one level only) |
| `:128` `_t.is_dir()` (new) | S2 | none (it can raise) | Finding 3 |
| `:169` `rp = _safe_resolve(p)` | S1 | `_safe_resolve` | cleared: `/proc/self/root/...` and `..` spellings resolve onto the target (traced statically) |

Primitive: exec of checkout code by the hook runner (`source` in linked hooks)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/log-usage.sh:11` | S5 | none for the checkout path | Finding 1 |
| `hooks/log-usage.sh:14` | S5 | SOFT only through `~/.claude/scripts`, none through the checkout path | Finding 1 |
| `hooks/log-usage-post.sh:20` | S5 | none for the checkout path | Finding 1 |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---|---|---|---|---|
| 1 | A tainted session can still edit code that every linked hook sources | Medium | B4, B2 | `hooks/guard-trusted-writes.py:119-130`; `hooks/log-usage.sh:11,14` | High |
| 2 | The new Bash deny message suggests script-file indirection (A8) | Medium | B3, B1 | `hooks/guard-trusted-writes.py:291-295` | Medium |
| 3 | One unreadable hooks entry stops the N12 loop (fails open) | Low | B2 | `hooks/guard-trusted-writes.py:125-130` | Medium |
| 4 | A nested link in a real subdirectory is not resolved | Informational | B2 | `hooks/guard-trusted-writes.py:125-130` | High |

## Overall Assessment

The withdrawal is clean. No worktree neutralization path remains, and the Bash tier behaves as it did at 970e525 on every pinned bypass (executed by the fact-check). N12 is a real improvement: Edit/Write can no longer rewrite a per-file-linked hook through its checkout path. It does not yet reach what it aims at. The code those hooks `source` stays writable by a tainted session with no prompt (Finding 1), and the new deny text points a steered model toward the logged A8 indirection (Finding 2). Both can be fixed in place: widen the target sets or document the gap, and reword one string. Neither points to an architectural problem, and the planned copy-based install removes the Finding 1 class. The most important item is Finding 1, because it is the persistence route the guard exists to close. My verdict: no blocking findings in the code paths read. Findings 1-2 deserve a fix or an override-log row before merge. The endorsement claims are pending execution verification by code-fact-check.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 3e9e448` line."
- **Answered:** Brief items 1-5, looked at for security. On item 2, the exemption is fully gone (endorsement, routed). Items 1 and 3: the N12 resolution works for per-file, dir, dangling and hooks-symlink links, and does not reach sourced code, nested links or the loop's error path. Item 4: the guide heading over-claims (Finding 1). Item 5: the Bash N15 message has the security issue in Finding 2.
- **Out of scope:** re-verifying documented behaviour already executed by the fact-check, and re-filing N2/A8/N3.
- **Escalate:** Finding 1 is not in the override log and is pre-existing. The user should decide between widening the HARD/SOFT targets now and documenting the gap until the copy install lands.
