Commit: 053c0b7

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-guard (branch `ans/guard-q048-q050`)
**Scope:** branch diff `970e525..053c0b7`: `hooks/guard-trusted-writes.py`, `test/hooks/guard-trusted-writes.bats`, `guides/bare-host-hook-wiring.md`, and the 7 commit messages (terminal pass 3)
**Checked:** 2026-09-23
**Total claims checked:** 15
**Summary:** 9 verified, 3 mostly accurate, 0 stale, 3 incorrect, 0 unverifiable

Execution provenance. All probes ran with a temp `HOME` (fresh `mktemp` dir under the probe directory, holding a fake `~/.claude/settings.json` and `hooks/`), `CLAUDE_CONFIG_DIR` unset, and a real `git worktree add` fixture at `<tmp>/repo/.claude/wt-foo`. The real `~/.claude` was never touched. "Wrote config" means the command was then **executed** under the same temp HOME and the fake config file changed. Probe dir: `$P = /tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/gfc-p3-r1`. Logs:
- `$P/suite-head.log`: `bats test/hooks/guard-trusted-writes.bats`, cwd `/workspace/.claude/wt-guard`, exit 0, 83/83 ok, 2026-09-24T00:0xZ.
- `$P/red-456bded-vs-970e525.log`, `$P/red-456bded-self.log`: `bats test/hooks/g.bats` in `$P/redtree`, exit 1 each.
- `$P/probe.log`: `python3 $P/probe.py`, exit 0.
- `$P/toctou.log`: `python3 $P/toctou.py`, exit 0, 2026-09-24T00:04:46Z.
- `$P/n12.log`: `python3 $P/n12.py`, exit 0, 2026-09-24T00:05:25Z.
- `$P/cost.log`: `python3 $P/cost.py`, exit 0, 2026-09-24T00:05:57Z.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read. No claim matches a logged pattern, and no fabricated symbol was found.

---

## Claim 1: "the guard **denies** Claude's file tools on its checkout copy, in a tainted session or not … No deny rule names the checkout path, so deferring would leave it with no gate at all"

**Location:** `guides/bare-host-hook-wiring.md:59-65`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers Edit/Write/MultiEdit on the checkout `global-instructions/CLAUDE.md` behind a linked `~/.claude/CLAUDE.md` and on a per-file linked hook's checkout target, both tainted and clean. It also covers the fact that the wiring deny rules name only `{{CLAUDE_DIR}}` and `~` paths. It does not establish the "no approve option" behaviour of Claude Code itself (an external product claim), or Bash writes to those paths (see Claim 2).

The deny rules name only config-dir and home spellings:

```
// hooks/wiring.json:120-127
      "Edit({{CLAUDE_DIR}}/settings*.json)",
      "Write({{CLAUDE_DIR}}/settings*.json)",
      "Edit({{CLAUDE_DIR}}/hooks/**)",
      "Write({{CLAUDE_DIR}}/hooks/**)",
      "Edit({{CLAUDE_DIR}}/CLAUDE.md)",
      "Write({{CLAUDE_DIR}}/CLAUDE.md)",
      "Edit(~/CLAUDE.md)",
      "Write(~/CLAUDE.md)"
```

Suite run: `ok 74 Q-050: the checkout CLAUDE.md behind a symlinked ~/.claude/CLAUDE.md is denied` and `ok 75 Q-050 / N12: a per-file symlinked hook's checkout target is denied`. Each test loops over `clean` and `sess1` (tainted), and test 75 also loops over Edit, Write and MultiEdit.

**Evidence:** `hooks/wiring.json:120-127`, `hooks/guard-trusted-writes.py:186-192`, `test/hooks/guard-trusted-writes.bats:790-813`, `$P/suite-head.log`

---

## Claim 2: "Bash writes to that checkout path (`echo x > <checkout>/hooks/<name>`, `cp`) are NOT gated by this hook, only Edit/Write are … Hooks installed as copies are not affected."

**Location:** `guides/bare-host-hook-wiring.md:66-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `echo >` and `cp` to a linked hook's checkout path outside any `.claude`-named directory, and Edit on a copied hook's checkout source. It does not establish the result when the checkout path itself contains `.claude` or a home indicator, which would be denied by co-occurrence.

`$P/probe.log`: with `~/.claude/hooks/linked.sh -> <tmp>/checkout/hooks/linked.sh`, both `echo x > <tmp>/checkout/hooks/linked.sh` and `cp <tmp>/a <tmp>/checkout/hooks/linked.sh` returned `HEAD=defer`. Suite: `ok 76 Q-050: a repo hook file with no link into ~/.claude/hooks is not denied` (it includes Edit on `copied.py`, clean and tainted, which `assert_defer`s). The Bash tier fires on `hooks` only with a config indicator:

```
# hooks/guard-trusted-writes.py:395-397
    # A10: settings*.json / hooks plus the config dir named anywhere.
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
```
(excerpt ends :397; enclosing bash_targets() continues to :401 — read)

**Evidence:** `hooks/guard-trusted-writes.py:385-401`, `test/hooks/guard-trusted-writes.bats:815-825`, `$P/probe.log`, `$P/suite-head.log`

---

## Claim 3: "A regular-file COPY in ~/.claude leaves its source out of the HARD tier: a copied hook's source is ungated, a copied CLAUDE.md's source is SOFT (ask when tainted)."

**Location:** `hooks/guard-trusted-writes.py:30-33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers Edit on a copied hook's source and on a copied CLAUDE.md's source, clean and tainted. It does not establish the result for a copy whose source path contains a SOFT segment (`skills`, `.claude`, …), which would be SOFT for that reason instead.

Suite: `ok 76` (copied hook source defers, tainted too) and `ok 77 Q-050: with a regular-file ~/.claude/CLAUDE.md copy, the checkout file is not denied` (defers clean, `ask` tainted). The copy resolves into the config dir, so the loop adds a config-dir target rather than the checkout file:

```
# hooks/guard-trusted-writes.py:134-139
try:
    for _e in (CONFIG_DIR / "hooks").iterdir():
        _t = _safe_resolve(_e)
        (_HARD_DIR_TARGETS if _t.is_dir() else _HARD_FILE_TARGETS).add(_t)
except Exception:
    pass
```

**Evidence:** `hooks/guard-trusted-writes.py:134-139`, `hooks/guard-trusted-writes.py:196-205`, `test/hooks/guard-trusted-writes.bats:815-837`, `$P/suite-head.log`

---

## Claim 4: The Q-048 exemption conditions (docstring): exempt "ONLY when its whole shell word is an absolute path with no quote, expandable character or `..`, and its worktree root exists at hook time as a real, unsymlinked git worktree … AND the whole command has no `..` component, no `$` or backtick, no cd/pushd/popd, no ln/mv/rm, no program that runs other text … and no policy name outside the exempt worktree words. If any of that fails, no worktree occurrence is exempt."

**Location:** `hooks/guard-trusted-writes.py:49-62`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stated conditions as the code implements them. It also covers every pass-1 route (quote-split `..`, `"$HOME"/.claude/wt-x`, `a=b=`, the symlinked `wt-q`) and every pass-2 route (`cd <wt> && cd ..`, `> ../settings.json`, `rm`/`mv` + `ln -s` swaps, `$(dirname)`, backticks, `xargs`, `sh -c`, `python3 -c`, a policy name outside the exempt words), which are all denied. It also covers `\ln`, `/bin/ln`, `(cd …)` subshells and newline-separated `cd`, all denied. It does not establish that satisfying these conditions keeps the write inside the worktree: Claims 5 and 6 refute that.

The gate implementation:

```
# hooks/guard-trusted-writes.py:348-352
def _whole_command_allows_exemption(cmd: str) -> bool:
    if "$" in cmd or "`" in cmd:
        return False
    flat = re.sub(r"[\"'\\]", "", cmd)
    return not (_WT_GATE_DOTDOT.search(flat) or _WT_GATE_CMD.search(flat))
```

`_neutralize_worktrees` (`:354-383`, read in full) returns `cmd` unchanged when the gate fails or when `SETTINGS_OR_HOOKS`/`CLAUDE_MD` matches the text outside the exempt words. It is called at `:389`, before every indicator check in `bash_targets`. The suite passes 83/83, including the pass-1 bypass tests (`bats:588-650`) and the pass-2 gate tests (`bats:711-757`). `$P/probe.log`: `\ln -s … ; echo PWN > <wt>/c/settings.json` → HEAD=deny; `/bin/ln …` → deny; `(cd <wt>) && echo PWN > <wt>/settings.json` → deny; newline-separated `cd <wt>` → deny. Neutralization cannot create a `HARD_FRAG` match, because it replaces only the `.claude/wt-<name>` span with `AGENT_WORKTREE` and leaves every later `.claude/…` in place (test `bats:682-695` pins `…/wt-foo/.claude/hooks/x` as deny).

**Evidence:** `hooks/guard-trusted-writes.py:290-383`, `hooks/guard-trusted-writes.py:385-401`, `test/hooks/guard-trusted-writes.bats:588-775`, `$P/suite-head.log`, `$P/probe.log`

---

## Claim 5: "nor a worktree the same command creates … or replaces with a symlink (that needs rm/mv and ln, which void the exemption)" and, in the comment block, "One the same command REPLACES would pass this time-of-check test, which is why the whole-command gate below voids the exemption for any rm/mv/ln"

**Location:** `hooks/guard-trusted-writes.py:59-61` (also `:277-279`)
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers replacing an existing, real worktree root with a symlink inside the command being judged, using no `rm`, `mv` or `ln` word. It does not establish that every file-removing or symlink-creating program (for example `rsync --delete`, `unlink`, `git worktree remove`) gets through; only `find -delete` + `cp -P` was run.

Replacing the root does not need rm/mv/ln. `find <wt> -delete` removes it, and `cp -P <symlink> <wt>` recreates it as a symlink. None of those words is in the gate list:

```
# hooks/guard-trusted-writes.py:344-346
_WT_GATE_CMD = re.compile(
    r"(?<![\w.-])(?:cd|pushd|popd|ln|mv|rm|sh|bash|zsh|dash|ksh|eval|exec|source"
    r"|xargs|awk|gawk|python[0-9.]*|node|perl|ruby)(?![\w.-])")
```

`$P/probe.log`, case "root replaced w/o rm/mv/ln": `find <wt> -delete && cp -P <tmp>/lnkdir <wt> && echo PWN > <wt>/settings.json` (where `lnkdir -> $HOME/.claude`, created beforehand; `ln` is not a write primitive, A8) → `HEAD=defer 970e525=deny`, exec_exit=0, **wrote_config=True**. The precise version: "a same-command replacement is voided only when it is spelled with rm/mv/ln; other deleters or symlink creators (`find -delete`, `cp -P`/`cp -s`) are not seen." Context: the same effect was already reachable with no worktree at all (N2/A8), so the new route adds no capability. What changed is that 970e525 denied this command because of the incidental `.claude`, and HEAD does not.

**Evidence:** `hooks/guard-trusted-writes.py:59-61`, `hooks/guard-trusted-writes.py:277-279`, `hooks/guard-trusted-writes.py:343-352`, `$P/probe.log`

---

## Claim 6: "Accepted: any plain directory holding a regular `.git` file passes the root check (its contents are not checked), but writes still stay inside it." and "a symlink inside the worktree that leads out of it is not exempt; one created by the same command needs ln, which the gate rejects"

**Location:** `hooks/guard-trusted-writes.py:63-64` (also `:282-284`)
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers same-command creation of a symlink inside a real, existing worktree by `cp -P`, `cp -rs`, `tar -x` and `git checkout`, each followed by a write through the exempt worktree word. It does not establish routes through hard links (they need a shared filesystem with HOME and were not run), or whether Claude Code actually issues such commands in practice.

Writes through an exempt word do not stay inside the worktree when the same command first puts a symlink there with a program other than `ln`. The realpath check runs at hook time, when the path does not exist yet:

```
# hooks/guard-trusted-writes.py:321-327
def _exempt_worktree(word: str, root: str) -> bool:
    if _WT_UNSAFE.search(word) or not word.startswith("/"):
        return False
    root = os.path.normpath(root)
    if not _real_worktree_root(root):
        return False
    return _within(os.path.realpath(word), root)
```

`$P/probe.log`. Each command was executed under the temp HOME. HEAD / 970e525 / result:
- `cp -P <tmp>/lnkfile <wt>/settings.json && echo PWN > <wt>/settings.json` → defer / deny / wrote config settings.json
- `git -C <wt> checkout -q evil && echo PWN > <wt>/hooks/evil.sh` (branch `evil` tracks `hooks -> $HOME/.claude/hooks`) → defer / deny / wrote into config `hooks/`
- `git -C <wt> checkout -q evil && echo PWN > <wt>/settings.json` → defer / deny / wrote config settings.json
- `tar -xf <tmp>/e.tar -C <wt> && echo PWN > <wt>/settings.json` (a tar holding a symlink member) → defer / deny / wrote config settings.json
- `cp -rs $HOME/.cla""ude <wt>/c && echo PWN > <wt>/c/settings.json` → defer / deny / wrote config settings.json
- control `echo PWN > <wt>/settings.json` → defer / deny / config untouched

The `git checkout` and `tar -x` routes need no N2 spelling and no earlier A8 step. The symlink target sits in a fetched branch or a downloaded archive, where the command text cannot show it. Context as in Claim 5: the same writes were already reachable with a non-worktree directory at 970e525 (`hooks`/`settings.json` with no config indicator gets no opinion), so this is a loss of an incidental deny, not a new capability. The docstring's "writes still stay inside it" and "needs ln, which the gate rejects" are nonetheless false as stated, and a reader would rely on them.

**Evidence:** `hooks/guard-trusted-writes.py:63-64`, `hooks/guard-trusted-writes.py:282-284`, `hooks/guard-trusted-writes.py:321-327`, `$P/probe.log`, `$P/probe.py`

---

## Claim 7: "Not gated here: Bash writes to a linked hook's CHECKOUT path (e.g. `echo x > <checkout>/hooks/<name>` on a bare host) get no opinion; only Edit/Write are denied there (N12). Pre-existing, alongside N2/A8."

**Location:** `hooks/guard-trusted-writes.py:65-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Same as Claim 2. This answers brief item 0b: the Bash tier does not deny these writes, and both the docstring and the guide now say so. It does not establish the "pre-existing" label for layouts other than the one probed.

`$P/probe.log`: `echo x > <tmp>/checkout/hooks/linked.sh` → `HEAD=defer`; `cp <tmp>/a <tmp>/checkout/hooks/linked.sh` → `HEAD=defer`, with `~/.claude/hooks/linked.sh` linking there.

**Evidence:** `hooks/guard-trusted-writes.py:65-67`, `hooks/guard-trusted-writes.py:385-401`, `$P/probe.log`

---

## Claim 8: "resolve each entry: a checkout file that IS a live hook is HARD (resolved tier -> deny). A regular-file copy resolves into the config dir itself, which leaves its checkout original out of the HARD tier"

**Location:** `hooks/guard-trusted-writes.py:128-133`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers per-file links, a `hooks` dir that is itself a symlink, a dangling entry, and an entry linking to a directory. It does not establish behaviour when an entry links to a very broad directory (for example a checkout root), which would make that whole tree HARD for the file tools. The code would do that, but it was not probed.

`$P/n12.log`:
- `hooks` itself a symlink to `<co>/hooks`: Edit `<co>/hooks/a.sh` → deny; Edit `<co>/README.md` → defer.
- Dangling entry `hooks/gone.sh -> <co>/hooks/gone.sh`: Edit that path → deny, and Edit `<co>/hooks/a.sh` → defer. No crash, because `_safe_resolve` is non-strict.
- Entry `hooks/lib -> <co>/hooks/lib`: Edit `<co>/hooks/lib/u.py` → deny and Write `<co>/hooks/lib/new.py` → deny, so the whole linked directory becomes HARD. Edit `<co>/hooks/a.sh` → defer.

The code (quoted in Claim 3, `:134-139`) sends a directory target to `_HARD_DIR_TARGETS`, which `classify_path` matches by `d in rp.parents` (`:191`).

**Evidence:** `hooks/guard-trusted-writes.py:128-139`, `hooks/guard-trusted-writes.py:191-192`, `$P/n12.log`

---

## Claim 9: "Residual: a program the command runs by file (a script, make, a git hook) can swap the root unseen; that is the A8 class of writes this hook can't read."

**Location:** `hooks/guard-trusted-writes.py:287-289`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the stated residual (true as far as it goes) and one residual it leaves out: a swap by an earlier, backgrounded Bash command that runs after this command's hook. It does not establish how wide the hook-to-execution window is in real Claude Code sessions.

The stated residual holds, but it is not the only one. The root check runs once, at hook time (`_real_worktree_root`, `:301-319`), so a job started by an EARLIER command can swap the root after the check. `$P/toctou.log`: command A `(sleep 2; find <wt> -delete && cp -P <tmp>/lnkdir <wt>) >/dev/null 2>&1 &` → HEAD=defer (it has no policy name). Command B `echo PWN > <wt>/settings.json` → `HEAD=defer 970e525=deny`, with the root a real dir at check time. B, executed after the swap, wrote the config settings.json. Pass 2 (r1) noted this cross-call gap in prose, and 053c0b7 did not change it. The in-command non-script routes in Claim 6 (`git checkout`, `tar -x`) are also not "a program the command runs by file". Precise version: "Residual: the root and the path under it are checked only at hook time; a script/make/git hook, a same-command symlink creator other than ln (cp -P/-s, tar, git checkout), or a background job from an earlier command can change them before the write."

**Evidence:** `hooks/guard-trusted-writes.py:287-289`, `hooks/guard-trusted-writes.py:301-319`, `$P/toctou.log`, `$P/toctou.py`, `docs/reviews/code-fact-check-report-r1-pass2-835f99d.md:187`

---

## Claim 10: "Word boundaries exclude letters, digits, `.`, `_` and `-`, so `/x/rmdata`, `--cdn` and `x.sh` do not trip it, while `/bin/rm` and `(cd` do. Over-matching only costs the exemption."

**Location:** `hooks/guard-trusted-writes.py:340-342`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `/x/rmdata`, `--cdn`, `cd-tools`, `/bin/rm`/`/bin/ln`, `\ln` and `(cd`. It does not establish that every program name containing a gate word as a whole path segment is intended (for example `/opt/sh/tool` trips on `sh`, which only costs the exemption).

Suite `ok` for `bats:759-775` (look-alike words stay exempt) and `bats:733-745` (`/bin/rm`, `/bin/ln` denied). `$P/probe.log`: `cp /x/rmdata/a <wt>/hooks/x.sh; echo --cdn cd-tools > <wt>/hooks/y.sh` → HEAD=defer; `\ln` and `/bin/ln` → deny; `(cd <wt>)` → deny. The regex is quoted in Claim 5 (`:344-346`).

**Evidence:** `hooks/guard-trusted-writes.py:340-352`, `test/hooks/guard-trusted-writes.bats:733-775`, `$P/probe.log`, `$P/suite-head.log`

---

## Claim 11: N15: both deny reasons avoid pointing at a denied path, and the Bash reason's advice "write that text with the Write tool and pass the file instead" is allowed by the hook

**Location:** `hooks/guard-trusted-writes.py:424-428`, `hooks/guard-trusted-writes.py:446-450`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers message text, a Write of such text to a scratch file, and passing it by `git commit -F`. It does not establish that every consumer command which takes the file (for example `cat f > ~/x`) is itself allowed.

```
# hooks/guard-trusted-writes.py:447-450
            emit("deny", f"This path is a live protected policy file ({Path(fp).name}: a global "
                         "hook, settings or CLAUDE.md, reached here by its real path or through a "
                         "symlink), so Claude's file tools cannot edit it. Make the change outside "
                         "Claude, in your own editor or shell, and review it there.")
```

Neither message names a path; only `Path(fp).name` is interpolated. Suite `ok 78 N15: …`. `$P/n12.log`: Write `<tmp>/msg.txt` whose content names `~/.claude/CLAUDE.md` → defer; `git commit -F <tmp>/msg.txt` → defer. The heredoc form it replaces (`cat <<EOF > <tmp>/m.txt … ~/.claude/CLAUDE.md`) → deny.

**Evidence:** `hooks/guard-trusted-writes.py:418-432`, `hooks/guard-trusted-writes.py:443-450`, `test/hooks/guard-trusted-writes.bats:839-852`, `$P/n12.log`

---

## Claim 12: "Red against 970e525: tests 54, 55, 56 (worktree allow), 62 (N12) and 65 (N15) fail; the rest are regression pins that already pass" … "12 tests"

**Location:** commit `456bded` message
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the 456bded test file run against the 970e525 hook and against the (unchanged) 456bded hook. It does not establish the red status of tests added in later commits (f480c24, f518532); their messages were not re-run against their parents here.

`@test` count: 58 at 970e525 and 70 at 456bded, so 12 were added. `$P/red-456bded-vs-970e525.log`: exactly `not ok 54`, `55`, `56`, `62`, `65`, exit 1. The same five fail against the 456bded hook, which is unchanged in that test-only commit (`$P/red-456bded-self.log`).

**Evidence:** `test/hooks/guard-trusted-writes.bats` @ 456bded, `$P/red-456bded-vs-970e525.log`, `$P/red-456bded-self.log`, `$P/red_check.sh`

---

## Claim 13: "An unexpanded relative worktree path (cd ~ && ... .claude/wt-x/...) is exempt, which only reaches ~/.claude/wt-x, not a HARD entry."

**Location:** commit `ccda554` message (Notes)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the claim as it stood at ccda554, and its status at HEAD. No code action remains: 835f99d removed the relative exemption. It does not re-verify pass-1's execution, which is cited.

When written, it was false: a relative `.claude/wt-q` that is a symlink to `.` reached `~/.claude/settings.json`. Pass 1 executed `cd ~ && ln -s . .claude/wt-q && echo PWNED > .claude/wt-q/settings.json` (`docs/reviews/code-fact-check-report-r2-pass1-035869c.md:384`). At HEAD, relative worktree paths are not exempt (`not word.startswith("/")` at `:322`), and the suite's `ok` for `bats:572-577` and `bats:624-633` covers it. Commit-message history only; superseded by 835f99d.

**Evidence:** `hooks/guard-trusted-writes.py:321-323`, `test/hooks/guard-trusted-writes.bats:572-633`, `docs/reviews/code-fact-check-report-r2-pass1-035869c.md:384`, `$P/suite-head.log`

---

## Claim 14: "Copies resolve into the config dir and leave their source ungated." / "Per-file link targets are read at hook load, like the other target sets."

**Location:** commit `ccda554` message
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the copy-source tiers and the fact that the target sets are built at module import time. It does not establish, from this repo, that Claude Code starts a fresh hook process per tool call (standard for command hooks, but external). Treat the load-time read as per call only under that assumption.

"Ungated" is right for a copied hook's source and wrong for a copied CLAUDE.md's source, which is SOFT and asks when tainted (Claim 3, suite `ok 77`). 835f99d's message and the docstring (`:30-33`) correct this. The load-time part holds: the loop is module-level code (`:134-139`, quoted in Claim 3), next to the other target sets at `:120-127`.

**Evidence:** `hooks/guard-trusted-writes.py:113-139`, `hooks/guard-trusted-writes.py:30-33`, `$P/suite-head.log`

---

## Claim 15: "Cost: a worktree write that uses $VARS or runs from cd <wt> is now denied (use absolute paths or the Write tool)."

**Location:** commit `053c0b7` message (Notes)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers four probe commands. It does not establish results in a tainted session: a CLAUDE.md-only case would ask instead.

Such a command loses the exemption. It is denied only when it also names a policy file (settings*.json, hooks, or CLAUDE.md with an indicator); otherwise it gets no opinion. `$P/cost.log`: `cd <wt> && echo x > out.txt` → defer; `V=1; echo $V > <wt>/src/a.py` → defer; `cd <wt> && echo x > hooks/a.sh` → deny; `V=1; echo $V > <wt>/settings.json` → deny. Precise version: "…that uses $VARS or cd <wt> is no longer exempt, so it is denied when it touches a hooks/settings/CLAUDE.md name."

**Evidence:** `hooks/guard-trusted-writes.py:354-356`, `hooks/guard-trusted-writes.py:385-401`, `$P/cost.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`hooks/guard-trusted-writes.py:59-61`, `:277-279`): replacing a worktree root in the same command does not need rm/mv/ln. `find <wt> -delete && cp -P <link> <wt> && echo > <wt>/settings.json` defers and wrote the config dir (970e525 denied). Fix the text, or add the programs to the gate.
- **Claim 6** (`hooks/guard-trusted-writes.py:63-64`, `:282-284`): "writes still stay inside it" and "needs ln" are false. `cp -P`, `cp -rs`, `tar -x` and `git checkout` of a tracked symlink, followed by a write through the exempt word, each wrote the config dir under HEAD=defer (970e525 denied). The already-open N2/A8 routes give the same capability, but the docstring must not claim containment.
- **Claim 13** (commit ccda554 Notes): was false when written (symlinked relative `wt-q`, pass 1). Superseded by 835f99d; history only.

### Stale
- none

### Mostly Accurate
- **Claim 9** (`hooks/guard-trusted-writes.py:287-289`): the residual list leaves out cross-command time-of-check swaps (a background job from an earlier command, executed: wrote config) and the non-script in-command routes from Claim 6.
- **Claim 14** (commit ccda554): "source ungated" is wrong for a copied CLAUDE.md, whose source is SOFT (already corrected in 835f99d and the docstring).
- **Claim 15** (commit 053c0b7 Notes): "$VARS / cd <wt> is now denied" means "loses the exemption"; it is denied only when a policy name is also present.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the output path your task names, structured per your skill, beginning with a `Commit: 053c0b7` line.
- Answered: yes. All pass-1/pass-2 routes are confirmed denied by execution. New same-command routes (cp -P, cp -rs, tar -x, git checkout, find -delete + cp -P) and the cross-command time-of-check swap were found, and the docstring's containment claims were refuted.
- Out of scope: hard-link routes (need HOME and the worktree on one filesystem; not run); case-insensitive filesystems (N11); bind-mounted roots; whether Claude Code keeps background jobs alive between Bash calls in practice.
- Escalate: the orchestrator should decide whether Claims 5/6 call for gate additions (cp, tar, git, find) or only a docstring correction. Every route found is also reachable through a non-worktree dir under the deferred N2/A8, so the exemption loses an incidental deny rather than opening a new capability.
