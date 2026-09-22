Commit: 31f53e8

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch `answers-2026-09-20`
**Scope:** `git diff 2d93589..answers-2026-09-20` (818c568, a577546, 739cbbb, fd0ad24 merge, b951c4f, 31f53e8): hooks/guard-trusted-writes.py, test/hooks/guard-trusted-writes.bats, scripts/lib/si-functions.sh, scripts/lib/si-morning-summary.sh, scripts/archive-working-docs.sh, scripts/questions.sh, skills/code-review/references/rubric.md, docs/working/questions.md, docs/working/questions-archive.md, docs/reviews/override-log.md, plus the six commit messages. Replicate r2, iteration 3 (final confirmation pass).
**Checked:** 2026-09-21 (executions timestamped 2026-09-22T04:14Z–04:24Z UTC)
**Total claims checked:** 28
**Summary:** 17 verified, 8 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Hallucination-pattern log read before checking. One resemblance noted (Claim 27b: an "85" passing-test denominator, cf. the logged `59ca38f` "All 85 tests" pattern); here a subset summing to 85 does exist, so it is not a match.

All hook probes ran the repo copy `/workspace/hooks/guard-trusted-writes.py` with a fake HOME, `CLAUDE_CONFIG_DIR` explicitly unset (or set per probe), and `CC_WEB_TAINT_DIR` in the scratchpad. Pre-fix comparisons ran `git show 2d93589:hooks/guard-trusted-writes.py` / a `git archive 818c568^` extract from the scratchpad, never against real paths. Scripts: `/tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/*.sh.txt`, copies under `docs/reviews/execution-logs/`.

---

## Claim 1: "iter2 N2: `hooks/guard-trusted-writes.py:190-205` Bash writes still ungated for bare `cd; echo > CLAUDE.md`, `/home/$USER/CLAUDE.md`, … Discoverable TODO: `# TODO(N2)` block beside the Bash indicators (a577546) …"

**Location:** `docs/reviews/override-log.md:9`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's cited line range, the existence/location of `# TODO(N2)`, and whether the row is a qualifying author note; does not establish the security merits of deferring N2.
**Legibility-target:** for-author

The TODO exists and lists every shape the row names:

```python
# hooks/guard-trusted-writes.py:172-174
# TODO(N2): command TEXT that writes a global policy file but carries no
# indicator token the co-occurrence rules below look for, so it gets no
# opinion (pre-existing; code-review 2026-09-21 iteration 2, N2):
```

It also carries a revisit trigger ("the next change to the Bash tiers, or Q-048's answer"), so the row qualifies under both (a) and (b) of the rubric's qualifying-author-note rule. Imprecision: the cited range `:190-205` is the iteration-2 location of `bash_targets` (at `2d93589`, `git show 2d93589:hooks/guard-trusted-writes.py` lines 190-205 are `def bash_targets` … `return None`). At the row's own commit the same function sits at `:225-240`; `:190-205` now spans the end of the A8 TODO and `WRITE_PRIMITIVE`. The row does not say "as of 2d93589". The TODO sits beside `WRITE_PRIMITIVE` (`:191`), a few lines above the indicator lists (`:206-217`). The row's word "ungated" is also broader than the code, since two of the named shapes get an ask when tainted (see Claim 14).

**Evidence:** `docs/reviews/override-log.md:9`, `hooks/guard-trusted-writes.py:172-184`, `hooks/guard-trusted-writes.py:225-240`, `git show 2d93589:hooks/guard-trusted-writes.py` :190-205

---

## Claim 2: "iter2 N3: deny rules in `hooks/wiring.json:120-127` render as `Edit(/home/node/.claude/…)` … Tracked as Q-049 in `docs/working/questions.md` with a paste. Revisit trigger: Q-049's answer."

**Location:** `docs/reviews/override-log.md:10`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line citation, the rendered live rule form, and the existence of Q-049; does not establish how Claude Code interprets a single leading `/` (that is Q-049's open question).
**Legibility-target:** for-orchestrator-synthesis

`hooks/wiring.json:120-127` holds the six `{{CLAUDE_DIR}}` rules and the two `~/CLAUDE.md` rules (`"Edit({{CLAUDE_DIR}}/settings*.json)",` at :120 … `"Write(~/CLAUDE.md)"` at :127). The live `~/.claude/settings.json:7` reads `"Edit(/home/node/.claude/settings*.json)",`. Q-049 exists at `docs/working/questions.md:51`. A tracked follow-up entry plus a named trigger makes this a qualifying note.

**Evidence:** `hooks/wiring.json:120-127`, `~/.claude/settings.json:7-14`, `docs/working/questions.md:51-70`

---

## Claim 3: "the run-id charset `^[A-Za-z0-9._-]+$` is copied in `scripts/self-improvement.sh`, `scripts/archive-working-docs.sh` and `scripts/lib/si-morning-summary.sh` … All three copies are identical and tested"

**Location:** `docs/reviews/override-log.md:11`
**Type:** Reference / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count and identity of the regex copies, and the cited commits; does not establish test coverage of each copy beyond the suites run in Claims 19-20 and 27.
**Legibility-target:** for-author

A grep for the literal regex gives four copies in three files:

```
scripts/lib/si-morning-summary.sh:1162:    [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
scripts/archive-working-docs.sh:45:  if [[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
scripts/archive-working-docs.sh:52:if ! [[ "$PREFIX" =~ ^[A-Za-z0-9._-]+$ ]]; then
scripts/self-improvement.sh:460:if [[ ! "$SI_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
```

The fourth (`archive-working-docs.sh:52`) was added by 818c568, one of the commits the row cites. The copies are identical. Commits 14bfbdd, efd66e4 and 818c568 exist with matching subjects. The revisit trigger ("any change to the run-id format, or a fourth reader of the Run cell") is concrete, so the row qualifies. The count should say "three files, four copies".

**Evidence:** `scripts/archive-working-docs.sh:45`, `scripts/archive-working-docs.sh:52`, `scripts/self-improvement.sh:460`, `scripts/lib/si-morning-summary.sh:1162`

---

## Claim 4: "Refuted at `hooks/guard-trusted-writes.py:56-132` as of `4c7a2bb` … The defects it hid were R1/R4 …, fixed in `c5a7c96`."

**Location:** `docs/reviews/override-log.md:17`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pinning to 4c7a2bb and the attribution of the R1/R4 fix to c5a7c96; does not re-verify the original refutation.
**Legibility-target:** for-orchestrator-synthesis

`git log -1 --oneline c5a7c96` gives `fix(hooks): close guard-trusted-writes HARD-tier bypasses (review R1, R3, R4, A10)`. The row now carries "as of `4c7a2bb`", so its line range no longer reads as the current location (N7).

**Evidence:** `docs/reviews/override-log.md:17`, `git log -1 c5a7c96`, `git log -1 4c7a2bb`

---

## Claim 5: "that file takes 42–60s depending on load and slow ~80–100s … Full health check measured 216s on the merged tip."

**Location:** `docs/working/questions-archive.md:833`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Low
**Verification mode:** executed
**Scope:** Covers one re-timing of `test/scripts/health-check.bats` under this session's load; does not re-measure the slow tier (~80–100s) or the 216s full health check, which are historical measurements.
**Legibility-target:** for-author

Command `bats test/scripts/health-check.bats`, cwd `/workspace`, started 2026-09-22T04:21:48Z, exit 0, 17 ok / 0 not ok, **63s** elapsed. That is just above the stated 42–60s upper bound. Other review agents were running at the same time, and "depending on load" allows for that, but one reading of 63s means the range is not established as an upper bound. The 80–100s and 216s figures were not re-run. (The file is at `test/scripts/health-check.bats`. The archive text calls it `health-check.bats` without a path, which is fine.)

**Evidence:** `docs/working/questions-archive.md:833`, `docs/reviews/execution-logs/iter3-r2-health-check-bats.txt`

---

## Claim 6: Q-049 entry: format ("Needs: you: terminal" + one paste + Interim), "`devcontainer-config/link-claude-home.sh:137` (the `{{CLAUDE_DIR}}` substitution)", "`guard-trusted-writes.py` then defers to rules that aren't there, so file-tool edits to global settings, hooks and CLAUDE.md get no gate", and the Interim "The devcontainer's `/opt` payload is read-only …"

**Location:** `docs/working/questions.md:51-70`
**Type:** Reference / Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the entry's structure per `questions.sh check`, the :137 citation, the hook's defer on covered HARD spellings, and the /opt read-only interim; does not establish the paste's soundness (Claim 7) or Claude Code's rule semantics.
**Legibility-target:** for-orchestrator-synthesis

`bash scripts/questions.sh check` (cwd `/workspace`, 2026-09-22T04:19:55Z, exit 0) printed `✓ questions: structure valid, indexes current`. The entry has one fenced `bash` block and an `**Interim:**` line, as the CLAUDE.md `you: terminal` grammar requires. `devcontainer-config/link-claude-home.sh:137` is `then gsub("\\{\\{CLAUDE_DIR\\}\\}"; $dir)`. The hook defers on the covered spellings:

```python
# hooks/guard-trusted-writes.py:275-278
        if tier == "hard":
            # DO NOT "ask": that would override your permissions.deny (#39344).
            # Defer and let the deny rule, which names this path, block it.
            defer()
```

A live-layout probe showed `/home/node/.claude/settings.json -> DEFER`. `/opt/claude-workflows` and its `hooks/` are `dr-xr-xr-x root`, and `CLAUDE.md` there is `root 444`. That bounds `~/.claude/hooks/**` and `~/.claude/CLAUDE.md` (both symlinks into /opt). `~/CLAUDE.md` is not under /opt, but its rule uses the `~/` form that Q-049 does not question.

**Evidence:** `docs/working/questions.md:51-70`, `devcontainer-config/link-claude-home.sh:137`, `hooks/guard-trusted-writes.py:275-278`, `docs/reviews/execution-logs/iter3-r2-questions-check.txt`, `docs/reviews/execution-logs/iter3-r2-real-layout.txt`

---

## Claim 7: "For each rule form it grants Write, denies the target, asks Claude to write it, and reports whether the file appeared" / "if single-slash is enforced, N3 is closed as a non-issue"

**Location:** `docs/working/questions.md:57-69`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the paste prints when the `claude` run fails for reasons unrelated to the deny rule; does not establish Claude Code's real single- vs double-slash semantics.
**Legibility-target:** for-author

The paste prints "enforced" whenever the target file is absent, for any reason. It discards all of Claude's output and has no positive control:

```bash
# docs/working/questions.md:64-65
  (cd "$d" && claude -p "Use the Write tool to create the file $t containing: hi" --output-format json >/dev/null 2>&1)
  [ -e "$t" ] && echo "$form-slash rule: NOT enforced (file written)" || echo "$form-slash rule: enforced"
```

Executed: the paste was extracted verbatim and run with a stub `claude` on PATH that prints "Not logged in" and exits 1 (`TMPDIR` in the scratchpad), 2026-09-22T04:21:31Z, exit 0. Output:

```
single-slash rule: enforced
double-slash rule: enforced
```

So an auth failure, a model refusal, a turn cap, or the working-directory boundary all read as "single-slash rule: enforced". The boundary case applies here because `$t` is under a separate `mktemp -d`, outside the `cd "$d"` project, and whether `allow: ["Write"]` alone permits that headless write is not established (paraphrased — no quote available because this is Claude Code runtime policy the sandbox cannot run). Under "What I do with it", a single "enforced" line closes N3 as a non-issue, so a broken run would close a security finding on no evidence. There are two more gaps. The rules go in a **project** `.claude/settings.json`, while N3 is about **user** settings, and path-anchoring semantics may differ between those scopes. And the "both enforced" outcome has no branch in the plan. A no-deny control run that must write the file, plus a check of the JSON result (e.g. `num_turns`/`is_error`), would make "enforced" mean something.

**Evidence:** `docs/working/questions.md:57-69`, `docs/reviews/execution-logs/iter3-r2-q049-stub.txt`

---

## Claim 8: Q-048: "applied only to commands that contain a write … If the command names `CLAUDE.md`, it is denied when it also contains … `~`, `$HOME`/`${HOME…}`, the home path, `.claude`, `global-instructions` or the config dir. If it names `settings*.json` or `hooks`, it is denied when it also contains `.claude` or the config dir. False denies: a heredoc that writes a message file mentioning `CLAUDE.md` next to `HEAD~1`, and any Bash write into an agent worktree's `hooks/` …"

**Location:** `docs/working/questions.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the co-occurrence rules and both named false denies; does not establish that no other false denies exist, or cover the separate `HARD_FRAG` rule (`.claude/hooks`, `.claude/settings`, `managed-settings`), which Q-048 does not describe.
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:225-240
def bash_targets(cmd: str):
    has_write = bool(WRITE_PRIMITIVE.search(cmd))
    if not has_write:
        return None
    if HARD_FRAG.search(cmd):
        return "hard"
    # R1 / Q-035: CLAUDE.md plus any home/global indicator -> the global file may be meant.
    if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):
        return "hard"
    # A10: settings*.json / hooks plus the config dir named anywhere.
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
    ...  (excerpt ends :236; bash_targets continues to :240 — read: SOFT_FRAG -> "soft", else None)
```

Probes (2026-09-22T04:19:48Z, exit 0): a `cat > /tmp/msg <<'EOF'` heredoc containing `CLAUDE.md … HEAD~1` → deny; `git commit -m "fix CLAUDE.md since HEAD~1"` → defer (the corrected text no longer claims this); `echo x > /workspace/.claude/wt-abc/hooks/pre.sh` → deny; `echo x > proj/hooks/a.sh` → defer. The indicator lists at `:206-217` match the text. Matching is case-insensitive (`re.I`), which Q-048 does not state.

**Evidence:** `hooks/guard-trusted-writes.py:191-240`, `docs/reviews/execution-logs/iter3-r2-bash-probes.txt`

---

## Claim 9: "Matching is case-sensitive, like the deny rules and like Linux paths: ~/.claude/HOOKS/x is not the hooks dir (it falls to SOFT)" (and a577546: "Linux paths and the deny rules are case-sensitive; ~/.claude/HOOKS/x and ~/.claude/SETTINGS.JSON are not the protected entries")

**Location:** `hooks/guard-trusted-writes.py:14-15`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the hook's case-sensitive HARD match and the SOFT routing on Linux (ext4); does not establish behaviour on case-insensitive filesystems (macOS APFS default, WSL `/mnt/c`), where the premise fails, or whether Claude Code's deny matcher is case-sensitive.
**Legibility-target:** for-author

```python
# hooks/guard-trusted-writes.py:121-131
    rel = _rel_under(cand, dirs)
    if rel is not None and rel.parts:
        first = rel.parts[0]
        if first == "hooks":
            return True
        ...
        if len(rel.parts) == 1 and first == "CLAUDE.md":
            return True
    if cand.name == "CLAUDE.md" and cand.parent == HOME:
        return True
    (excerpt ends :131; _is_hard continues to :132 `return False` — read)
```

Probes (fake HOME, 2026-09-22T04:16:03Z): `~/.claude/SETTINGS.JSON`, `~/.claude/HOOKS/x.sh`, `~/.claude/claude.md` and `~/claude.md` → DEFER clean, ask tainted. That is correct on Linux. The docstring's rationale is Linux-specific, but the README documents a macOS bare-host setup (`guides/bare-host-hook-wiring.md:7`: "README's Linux/macOS setup"). On a case-insensitive filesystem `~/.claude/SETTINGS.JSON` **is** the live settings file. Untainted, it now defers (no gate, unless Claude Code's deny matcher folds case). Tainted, it asks, which would override the deny rule if that matcher does fold case (#39344). The commit's "not the protected entries" should say "on a case-sensitive filesystem". Whether the invariant holds there depends on Claude Code's matcher (Unverifiable here: no case-insensitive mount in the sandbox; `/mnt/c` is absent).

**Evidence:** `hooks/guard-trusted-writes.py:14-15`, `hooks/guard-trusted-writes.py:113-132`, `guides/bare-host-hook-wiring.md:7`, `docs/reviews/execution-logs/iter3-r2-hook-probes.txt`

---

## Claim 10: "For the file tools HARD splits in two: covered = the path AS GIVEN (lexical, or normpath with `..` folded) … the hook DEFERS to it. resolved = the path is HARD only after resolve() (or only under the config dir's resolved form) … the hook returns "deny" itself." / classify_path docstring / a577546 "-> the hook returns "deny" itself, tainted or not. Never "ask""

**Location:** `hooks/guard-trusted-writes.py:18-27`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every branch of `classify_path` (:134-169) and the Edit/Write/MultiEdit branch of `main()` (:270-289) across the default, /opt-symlink, symlinked-HOME, symlinked-config-dir, relative-config-dir and symlinked-project-.claude layouts; does not establish that Claude Code's deny matcher names the "covered" strings the hook defers on — normpath-folded `..` (disclosed, N3-adjacent), `//`, `./`, and MultiEdit (the rules name only `Edit`/`Write`) all defer on that assumption.
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:146-155
    for cand in (p, norm):
        if _is_hard(cand, [CONFIG_DIR]):
            return "hard"
    # (b) Only via the config dir's resolved form, only after resolve(), or onto the
    # target of a symlinked global entry (R4): no deny rule names this string.
    for cand in cands:
        if _is_hard(cand, GLOBAL_DIRS):
            return "hard-resolved"
    if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS):
        return "hard-resolved"
    (excerpt ends :155; classify_path continues to :169 with the SOFT checks — read)
```

Probe results, each clean and tainted where marked (2026-09-22T04:16Z–04:17Z):
- **Defer, clean and tainted:** `~/.claude/{settings.json, settings.foo.json, /settings.json, ./hooks/x, x/../settings.json, hooks/../CLAUDE.md}`, `~/CLAUDE.md`, `~//CLAUDE.md`, `~/x/../CLAUDE.md`, and literal `~/.claude/settings.json` / `~/CLAUDE.md` (expanduser).
- **Deny, clean and tainted:** payload `/opt…/CLAUDE.md`, `/opt…/hooks/{foo.sh,new.sh}`; MultiEdit on the payload; a project `.claude` symlinked to `~/.claude`, on its settings, hooks and CLAUDE.md.
- **Symlinked HOME** (`HOME=linkhome → realhome`): `realhome/.claude/settings.json` and `realhome/CLAUDE.md` → deny; `linkhome/...` → defer.
- **Symlinked config dir** (`CLAUDE_CONFIG_DIR=cfglink → realcfg`): `realcfg/settings.json` → deny; `cfglink/settings.json` → defer.
- **Never ask:** no HARD-classified path produced "ask" in any probe.

One residue: with a relative `CLAUDE_CONFIG_DIR=relcfg` (cwd T), a *relative* `file_path` `relcfg/settings.json` → deny (hard-resolved via `rp`), while the absolute spelling defers. The linker would render that deny rule as the literal relative string, so which spelling "a deny rule names" is undetermined. This is an edge case, since Claude Code normally sends absolute paths.

**Evidence:** `hooks/guard-trusted-writes.py:134-169`, `hooks/guard-trusted-writes.py:270-289`, `docs/reviews/execution-logs/iter3-r2-hook-probes.txt`, `docs/reviews/execution-logs/iter3-r2-hook-probes-b.txt`, `docs/reviews/execution-logs/iter3-r2-bats-hooks.txt`

---

## Claim 11: "resolved = … e.g. the payload CLAUDE.md addressed by its real /opt path (installed layout …), or a project .claude symlinked to ~/.claude" (a577546: "hard-resolved: … (the /opt payload CLAUDE.md or hooks by their real path; a project .claude symlinked to ~/.claude)")

**Location:** `hooks/guard-trusted-writes.py:22-27`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the hard-resolved set contains under the README bare-host install; does not establish whether denying the repo checkout's global CLAUDE.md is the intended policy.
**Legibility-target:** for-author

The docstring's "e.g." is honest, but the commit's parenthetical reads as the full set, and it omits a layout this repo documents. The README bare-host install links the global instructions into the user's git checkout:

```bash
# README.md:14
ln -s ~/claude-workflows/global-instructions/CLAUDE.md ~/.claude/CLAUDE.md
```

So `_HARD_FILE_TARGETS` (`:95`, `_safe_resolve(CONFIG_DIR / "CLAUDE.md")`) holds the checkout's `global-instructions/CLAUDE.md`. Probe of that layout (2026-09-22T04:17:12Z): `Edit ~/claude-workflows/global-instructions/CLAUDE.md` (clean, untainted) → **deny**. The same probe against the pre-fix hook (`2d93589`) → DEFER. On a bare host, then, a session working in this repo can no longer edit its own `global-instructions/CLAUDE.md` with the file tools, tainted or not. The README symlinks hooks per file into a real `~/.claude/hooks` dir (`README.md:29`), so `_HARD_DIR_TARGETS` is the real dir and repo `hooks/*.py` edits are **not** denied (probe: `claude-workflows/hooks/log-usage.sh` → DEFER). In the devcontainer the target is root-owned /opt, so nothing changes there. The false-positive risk is real but confined to the bare-host global-instructions file, and it is not disclosed.

**Evidence:** `hooks/guard-trusted-writes.py:95`, `README.md:14`, `README.md:29`, `docs/reviews/execution-logs/iter3-r2-hook-probes-b.txt`, `docs/reviews/execution-logs/iter3-r2-hook-probes-b-prefix.txt`

---

## Claim 12: "This matches the linker for an unset, empty or absolute value. It DIFFERS for a relative value …: the linker substitutes the string as written, while this hook anchors it at the hook's own cwd with abspath()"

**Location:** `hooks/guard-trusted-writes.py:76-79`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `config_dir()` against `link-claude-home.sh:36`; does not establish Claude Code's own interpretation of a relative deny-rule string.
**Legibility-target:** for-orchestrator-synthesis

`return Path(os.path.abspath(cfg)) if cfg else HOME / ".claude"` (`:81-82`) against `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`link-claude-home.sh:36`). Empty falls back in both. Probe with `CLAUDE_CONFIG_DIR=relcfg` (cwd T): absolute `T/relcfg/settings.json` → DEFER ("hard"), so the dir was anchored at cwd.

**Evidence:** `hooks/guard-trusted-writes.py:70-82`, `devcontainer-config/link-claude-home.sh:36`, `docs/reviews/execution-logs/iter3-r2-hook-probes.txt`

---

## Claim 13: "Case-folded on purpose: SOFT only ever asks, so over-matching is safe."

**Location:** `hooks/guard-trusted-writes.py:158`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the SOFT branch's possible outcomes and its ordering after both HARD tiers; does not establish that case-folded SOFT asks cannot override a deny rule on a case-insensitive filesystem (Claim 9 residue).
**Legibility-target:** for-author

```python
# hooks/guard-trusted-writes.py:286-289
        if tier == "soft" and tainted:
            emit("ask", f"This session fetched web content and this write targets a trusted-policy "
                        f"file ({Path(fp).name}). Review it for injected instructions before allowing.")
        defer()
```

SOFT never denies. It asks only when tainted and defers otherwise, so "only ever asks" should read "never denies; asks when tainted". The SOFT loop (`:159-168`) runs after both HARD returns (`:146-155`), so over-matching cannot downgrade a HARD path. The "safe" conclusion holds on Linux.

**Evidence:** `hooks/guard-trusted-writes.py:146-169`, `hooks/guard-trusted-writes.py:286-289`

---

## Claim 14: "TODO(N2): command TEXT that writes a global policy file but carries no indicator token … so it gets no opinion" (shapes: bare `cd; echo x > CLAUDE.md`, `/home/$USER/CLAUDE.md`, globbed/quoted `.claude`, `/opt/claude-workflows/hooks/...`, whole-tree copies)

**Location:** `hooks/guard-trusted-writes.py:172-184`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's decision for each listed shape, clean and tainted; does not establish that the list is complete.
**Legibility-target:** for-author

Probes (2026-09-22T04:24:04Z, exit 0): `cd; echo x > CLAUDE.md` and `echo x > /home/$USER/CLAUDE.md` → DEFER clean, **ask** tainted, because `SOFT_FRAG` (`:221-223`, `(^|[\s\"'=/])(AGENTS|CLAUDE|CLAUDE\.local)\.md`) matches them. Every other listed shape (`~/.clau*/…`, `~/.cl""aude/…`, `~/.claude/"settings".json`, `/opt/claude-workflows/hooks/a.py`, `cp -r dir/. ~/.claude/`, `rsync -a dir/ ~/.claude/`, `cd ~/.claude && cp /tmp/p/* .`) → DEFER even tainted, which matches "no opinion". The first two shapes are really "SOFT instead of HARD", not "no opinion".

**Evidence:** `hooks/guard-trusted-writes.py:172-184`, `hooks/guard-trusted-writes.py:221-240`, `docs/reviews/execution-logs/iter3-r2-n2-todo-probes.txt`

---

## Claim 15: deny reason "… through a symlink or resolved path that permissions.deny does not name. Edit it at its ~/.claude path, with review."

**Location:** `hooks/guard-trusted-writes.py:282-285`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether the advised alternative path is editable in-session; does not establish what happens if the live deny rules fail to match (Q-049), in which case the ~/.claude path is ungated rather than "with review".
**Legibility-target:** for-author

The advice points at exactly the spelling permissions.deny exists to block, and there is no review path for it. On a covered spelling the hook defers so that the deny rule blocks the write:

```python
# hooks/guard-trusted-writes.py:275-285
        if tier == "hard":
            # DO NOT "ask": that would override your permissions.deny (#39344).
            # Defer and let the deny rule, which names this path, block it.
            defer()
        if tier == "hard-resolved":
            ...
            emit("deny", f"This write reaches a protected policy file ({Path(fp).name}: "
                         ".claude hooks/settings or global CLAUDE.md) through a symlink or "
                         "resolved path that permissions.deny does not name. Edit it at its "
                         "~/.claude path, with review.")
```

The live rules are `"Edit(/home/node/.claude/CLAUDE.md)"` and similar (`~/.claude/settings.json:7-14`), and a deny cannot be approved, so "with review" is not reachable. If the rules do match, following the advice ends in a second, hard block. If they don't (Q-049), the advice routes around the gate. In the devcontainer the ~/.claude spelling resolves into root-owned /opt, so the write fails regardless. On the bare-host layout of Claim 11, the user is sent from `global-instructions/CLAUDE.md` to `~/.claude/CLAUDE.md`, which the `Edit(~/.claude/CLAUDE.md)`-form rule denies. The Bash deny text (`:263-264`, "Edit it directly with review") has the same problem but predates this scope. An accurate message would say the edit must be made outside the agent (by a human).

**Evidence:** `hooks/guard-trusted-writes.py:274-285`, `~/.claude/settings.json:7-14`, `docs/reviews/execution-logs/iter3-r2-hook-probes-b.txt`

---

## Claim 16: "The prefix becomes part of a path …; hold an explicit prefix to the same charset as the recorded one." (818c568: "an explicit archive prefix must match [A-Za-z0-9._-]+")

**Location:** `scripts/archive-working-docs.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the validation for explicit, recorded and date-fallback prefixes; does not establish anything beyond charset (`.` and `..` pass, but contain no `/`, so `dest` stays inside `archive/` as a file named `..-name`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/archive-working-docs.sh:52-55
if ! [[ "$PREFIX" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: prefix '$PREFIX' must match [A-Za-z0-9._-]+" >&2
  exit 1
fi
```

The check runs after all three prefix sources are merged (`:43-49`) and before `mkdir`/`mv`. Test "an explicit prefix outside [A-Za-z0-9._-] is refused and nothing moves" passes at HEAD and fails against the pre-fix script (hermetic `git archive 818c568^` extract; the `../../escape` target stayed inside the test's mktemp dir).

**Evidence:** `scripts/archive-working-docs.sh:43-56`, `scripts/archive-working-docs.sh:133`, `docs/reviews/execution-logs/iter3-r2-bats-si.txt`

---

## Claim 17: "Two archives under one prefix (a date-only fallback run twice in a day) must not overwrite the first run's copy." (818c568: "an existing archive copy is never overwritten")

**Location:** `scripts/archive-working-docs.sh:138-143`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sole `mv` (dry-run and real paths) and the collision outcome; does not establish atomicity: `[ -e ]` then a plain `mv --` (no `-n`) is check-then-act, and a dangling symlink at `$dest` (`-e` false) would be replaced by the moved file.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/archive-working-docs.sh:138-149
  if [ -e "$dest" ]; then
    ...
    echo "  skip  $name: archive/${PREFIX}-${name} already exists" >&2
    continue
  fi
  if $DRY_RUN; then
    echo "  move  $name -> archive/${PREFIX}-${name}"
  else
    mv -- "$f" "$dest"
    ...  (excerpt ends :149; loop continues to :151 `count=$((count + 1))` — read)
```

`mv` at `:147` is the only write. On a collision the source stays in `docs/working/`, a `skip` line goes to stderr, it is not counted, and the exit is 0. The test "archiving twice under one prefix does not overwrite the first copy" passes at HEAD and fails pre-fix (`same-day-plan-foo.md` overwritten).

**Evidence:** `scripts/archive-working-docs.sh:124-151`, `docs/reviews/execution-logs/iter3-r2-bats-si.txt`

---

## Claim 18: "Run (Q-047) is the self-improvement run's id (si_default_run_id above, or SI_RUN_ID)"

**Location:** `scripts/lib/si-functions.sh:481`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the relative position of the referenced function; nothing further.
**Legibility-target:** for-orchestrator-synthesis

`si_default_run_id() {` is at `:469`, above the comment block (`:478-490`).

**Evidence:** `scripts/lib/si-functions.sh:469`, `scripts/lib/si-functions.sh:481`

---

## Claim 19: "Exit 0 = header has a Run cell, 3 = no header row at all, 1 = migrate. 3, not 2: awk itself exits 2 on a runtime error (e.g. an unreadable file), and that must fail the call rather than read as "no header"."

**Location:** `scripts/lib/si-functions.sh:566-580`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all four exit states and propagation to the one production caller; does not establish that aborting the whole SI run (the effect under `set -e`) is the desired outcome.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/si-functions.sh:575-580
        } END { if (!hdr) exit 3; exit !found }' "$log_file" || state=$?
    case "$state" in
        0|3) return 0 ;;
        1) ;;
        *) return "$state" ;;
    esac
```

Executed (2026-09-22T04:18:14Z, uid 1000): unreadable (chmod 000) log → `awk: cannot open … (Permission denied)`, rc=2; no-header → 0; has-Run → 0; old header → migrated, rc 0. Under `set -euo pipefail`, `append_approved_hypotheses` on the unreadable log aborted with rc=2 before "reached after append". That caller runs the migration as a bare statement (`:513-514`), and `scripts/self-improvement.sh:45` sets `set -euo pipefail` and calls it at `:1874`, so a genuine awk failure aborts the run. No test or code expects exit 2 (`rg` over the three `test/append-approved-hypotheses.bats` call sites found none).

**Evidence:** `scripts/lib/si-functions.sh:499-553`, `scripts/lib/si-functions.sh:563-592`, `scripts/self-improvement.sh:45`, `scripts/self-improvement.sh:1874`, `docs/reviews/execution-logs/iter3-r2-migrate.txt`

---

## Claim 20: "The writer escapes a pipe inside a cell as `\|`; swap those for \036 before awk splits the row (assigning $0 re-splits it), then restore them as a plain `|` for display. Fields are joined with \037 …"

**Location:** `scripts/lib/si-morning-summary.sh:402-445`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_project_state_open_hypotheses` count and display for piped hypotheses, and consistency with the writer (`si-functions.sh:545`) and the other two readers (`_split_row_fields`, `flag-removal-candidates.sh`); does not establish handling of `\|` in the Task ID or Source cells (only `hyp` is restored, a cosmetic gap).
**Legibility-target:** for-orchestrator-synthesis

```awk
# scripts/lib/si-morning-summary.sh:412-423
            if ($0 ~ /^\|[ \t]*(Round|----)/) next
            line = $0; gsub(/\\\|/, "\036", line); $0 = line
            round = $2; tid = $3; hyp = $4; outcome = $(oc)
            ...
            if (outcome == "" && tid != "") {
                gsub(/\036/, "|", hyp)
                printf "%s\037%s\037%s\037%s\n", tid, round, hyp, src
            }
```

The reader is `while IFS=$'\037' read -r tid round hyp src` (`:436`). The writer escapes with `hyp="${hyp//|/\\|}"` (`si-functions.sh:545`). All three readers mask `\|` before splitting: `_split_row_fields` (`:1541`) and `flag-removal-candidates.sh` (`gsub(/\\\|/, "\036", line)`). Only the display differs: open-hypotheses restores a plain `|`, and the other two restore `\|`. That difference is deliberate. The N4 test passes at HEAD (`iter3-r2-bats-si.txt`) and fails pre-fix with `Open hypotheses: 1`.

**Evidence:** `scripts/lib/si-morning-summary.sh:380-446`, `scripts/lib/si-functions.sh:545`, `scripts/flag-removal-candidates.sh:92-110`, `docs/reviews/execution-logs/iter3-r2-bats-si.txt`

---

## Claim 21: "ASCII Record Separator as a placeholder for `\|`. Assumed, not checked, to be absent from log rows: the writer never emits it, and a row that did contain one would have that byte turned into `\|`."

**Location:** `scripts/lib/si-morning-summary.sh:1532-1535`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `_split_row_fields`'s sentinel round trip and the nameref rename; does not establish that no other writer emits `\x1e`.
**Legibility-target:** for-orchestrator-synthesis

`_srf_line="${_srf_line//\\|/$_srf_sep}"` (`:1537`), then per field `_srf_f="${_srf_f//$_srf_sep/\\|}"` (`:1541`). A raw `\x1e` in the input comes out as `\|`, as stated. The nameref is now `local -n _srf_out="$2"` (`:1531`), which avoids a clash with the callers' array `fields` (`:1016`, `:1613`).

**Evidence:** `scripts/lib/si-morning-summary.sh:1528-1548`

---

## Claim 22: "Writes never go through a symlinked questions file or docs/working/ dir, and, for the default paths, never land outside the git toplevel (an ancestor symlink such as a symlinked docs/ is caught by that check, not by the per-file one). Explicit QUESTIONS_LIVE/ARCHIVE paths get only the symlink checks."

**Location:** `scripts/questions.sh:47-51`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `assert_write_target` for docs/ symlinked inside and outside the repo; does not establish TOCTOU behaviour between the check and `mv`.
**Legibility-target:** for-author

```bash
# scripts/questions.sh:98-104
    [[ -L "$file" ]] && die "refusing to write: $file is a symlink"
    [[ -L "$dir" ]] && die "refusing to write: directory $dir is a symlink"
    if [[ -z "$overridden" ]]; then
        root="$(realpath -m -- "$PROJECT_ROOT")"
        resolved="$(realpath -m -- "$file")"
        [[ "$resolved" == "$root"/* ]] \
            || die "refusing to write: $file resolves to $resolved, outside $root"
    (excerpt ends :104; function continues to :107 `return 0` — read)
```

`questions.sh init` in throwaway git repos (2026-09-22T04:19:26Z): `docs -> /outside` → refused, rc 1. `docs -> x` (in-repo) → rc 0, files created under `x/working/`. `docs -> .git` → rc 0, files created inside `.git/working/`. The main guarantee ("never land outside the git toplevel") holds. The example overreaches: "a symlinked docs/ is caught" is true only when docs/ points outside the toplevel. An in-repo target, including `.git`, passes both checks (the iteration-2 observation still holds). Suggested wording: "…a symlinked docs/ that points outside the toplevel is caught…".

**Evidence:** `scripts/questions.sh:47-55`, `scripts/questions.sh:84-112`, `docs/reviews/execution-logs/iter3-r2-questions-ancestor.txt`

---

## Claim 23: "carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`)"

**Location:** `skills/code-review/references/rubric.md:155-156`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pointer's target and its summary of the definition; nothing further.
**Legibility-target:** for-orchestrator-synthesis

The heading `### Qualifying author note` exists at `:159` and defines "(a) A discoverable TODO" and "(b) A concrete revisit trigger", matching the inline summary. The pointer sits inside the template's code fence (closing ``` at `:157`), where a link would not render, so plain text is correct (N8).

**Evidence:** `skills/code-review/references/rubric.md:153-175`

---

## Claim 24: "bats test/hooks/: 144 ok, 0 not ok."

**Location:** commit `a577546` message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test/hooks/ suite count at HEAD 31f53e8 (a577546's hook and test files are unchanged since); does not establish per-test pre-fix failure.
**Legibility-target:** for-orchestrator-synthesis

`bats test/hooks/`, cwd `/workspace`, 2026-09-22T04:14:53Z, exit 0: 144 `ok`, 0 `not ok`.

**Evidence:** `docs/reviews/execution-logs/iter3-r2-bats-hooks.txt`

---

## Claim 25: "Probed against this container's installed layout: /opt/claude-workflows/CLAUDE.md -> deny, ~/.claude/CLAUDE.md -> defer, ~/.claude/HOOKS/x -> defer (untainted)."

**Location:** commit `a577546` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named probes plus two neighbours on the real installed layout (read-only probe of the repo hook); does not establish tainted behaviour on the real layout.
**Legibility-target:** for-orchestrator-synthesis

`bash real-r2.sh.txt` (cwd `/workspace`, 2026-09-22T04:23:21Z, exit 0; `CLAUDE_CONFIG_DIR=/home/node/.claude`): `/opt/claude-workflows/CLAUDE.md -> deny`, `/home/node/.claude/CLAUDE.md -> DEFER`, `/home/node/.claude/HOOKS/x -> DEFER`, `/opt/claude-workflows/hooks/guard-trusted-writes.py -> deny`, `/home/node/.claude/settings.json -> DEFER`.

**Evidence:** `docs/reviews/execution-logs/iter3-r2-real-layout.txt`

---

## Claim 26: "Case variants route to SOFT (ask when tainted, defer otherwise), not HARD: no deny rule covers them, so asking overrides nothing."

**Location:** commit `a577546` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the routing on a case-sensitive filesystem (the four variants in the N1 test plus `~/claude.md`); does not establish "asking overrides nothing" where Claude Code's deny matcher folds case or the filesystem is case-insensitive (see Claim 9).
**Legibility-target:** for-orchestrator-synthesis

Probes: `SETTINGS.JSON`, `HOOKS/x.sh`, `claude.md` under `~/.claude`, and `~/claude.md` → DEFER clean, ask tainted. The bats test "N1: case variants are not HARD … SOFT, ask when tainted" passes.

**Evidence:** `test/hooks/guard-trusted-writes.bats:471-486`, `docs/reviews/execution-logs/iter3-r2-hook-probes.txt`

---

## Claim 27a: "N4 test fails on the pre-fix lib"

**Location:** commit `818c568` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the one N4 test against `scripts/lib` from `818c568^`; does not cover the other two new tests (checked separately in Claims 16-17, both fail pre-fix).
**Legibility-target:** for-orchestrator-synthesis

`git archive 818c568^ scripts/lib test/lib` extracted to the scratchpad `pre818/`, with the 818c568 test file overlaid. `bats -f "escaped pipe" test/morning-summary-clusters.bats` (cwd `pre818`, 2026-09-22T04:18:47Z) exited 1: `not ok 2 open hypotheses: a hypothesis with an escaped pipe is counted and shown whole`, output `Open hypotheses: 1`.

**Evidence:** `test/morning-summary-clusters.bats:511-520`, `docs/reviews/execution-logs/iter3-r2-pre818-n4.txt`

---

## Claim 27b: "85/85 SI suites pass."

**Location:** commit `818c568` message
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Scope:** Covers the passing status of the SI suites named below; does not establish which set of suites "85" refers to, since the commit names none.
**Legibility-target:** for-orchestrator-synthesis

Test-count arithmetic from the `@test` counts: morning-summary-clusters 25 + archive-working-docs 14 + precondition-gate 40 + flag-removal-candidates 6 = 85. That is one plausible set. Adding append-approved-hypotheses (20) gives 105. `bats` over those five files (2026-09-22T04:20:42Z) exited 0 with 105 ok / 0 not ok. So every candidate set passes, but "85" is tied to no named set. Per the logged pattern (cf. `59ca38f`), a denominator should name its suites.

**Evidence:** `docs/reviews/execution-logs/iter3-r2-bats-si5.txt`, `docs/reviews/execution-logs/iter3-r2-bats-si.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`docs/working/questions.md:57-69`): the Q-049 paste prints "enforced" whenever the file is absent, including when `claude` fails (shown with a stub). It needs a no-deny control run and a check of the JSON result before "single-slash enforced" can close N3. It also tests project, not user, settings.
- **Claim 15** (`hooks/guard-trusted-writes.py:282-285`): "Edit it at its ~/.claude path, with review" sends the user to the spelling permissions.deny blocks outright. There is no in-session review route, so the message should say the edit must be made outside the agent.

### Mostly Accurate
- **Claim 1** (`docs/reviews/override-log.md:9`): `:190-205` is the iteration-2 location; `bash_targets` is now `:225-240`. "Ungated" overstates two shapes that ask when tainted.
- **Claim 3** (`docs/reviews/override-log.md:11`): the regex has four copies in three files (818c568 added a second one in archive-working-docs.sh).
- **Claim 5** (`docs/working/questions-archive.md:833`): re-timed at 63s against the stated 42–60s (under concurrent load). Slow tier and 216s not re-measured.
- **Claim 9** (`hooks/guard-trusted-writes.py:14-15`): "like Linux paths" is right on Linux, but macOS bare hosts are supported. On a case-insensitive filesystem `~/.claude/SETTINGS.JSON` is the live file and now defers untainted.
- **Claim 11** (`hooks/guard-trusted-writes.py:22-27` / a577546): hard-resolved also covers the README bare-host checkout's `global-instructions/CLAUDE.md`, which is now denied where it used to defer (an undisclosed false positive when developing this repo on a bare host).
- **Claim 13** (`hooks/guard-trusted-writes.py:158`): "SOFT only ever asks" should read "SOFT never denies (asks only when tainted)".
- **Claim 14** (`hooks/guard-trusted-writes.py:172-184`): the bare-`cd` and `/home/$USER` shapes get SOFT (ask when tainted), not "no opinion".
- **Claim 22** (`scripts/questions.sh:47-51`): a symlinked docs/ is caught only when it points outside the toplevel; `docs -> x` and `docs -> .git` pass.

### Unverifiable
- **Claim 27b** (commit 818c568): "85/85 SI suites" names no suite set. One set of four suites sums to 85 and all candidate sets pass.

---

## Goal-Alignment Note

- **Answered:** Every one of the 12 brief items was checked. The executable ones were run: `bats test/hooks/` (144/0), the SI suites (39/0 and 105/0), `health-check.bats` timing, `questions.sh check`, file-tool hook probes across seven layouts (default, /opt symlink, symlinked HOME, symlinked or relative CLAUDE_CONFIG_DIR, symlinked project .claude, README bare host), Bash probes for Q-048 and TODO(N2), a hermetic pre-fix run for 818c568's tests and a577546's bare-host delta, the migration exit-code propagation under `set -e`, and the Q-049 paste with a failing `claude` stub. The key invariant held in every Linux layout probed: no HARD path produced "ask", and every resolve-only HARD path produced "deny". The one residue is the undisclosed bare-host false positive (Claim 11).
- **Out of scope:** Claude Code's own deny-matcher semantics (single vs double slash, `..` folding, case folding, whether `Edit(...)` covers MultiEdit). These need a host run (Q-049), so they appear only as Scope residue. N2, N3, A7, A8 and Q-048 were not re-raised; Claims 1 and 14 check only the accuracy of their text. No case-insensitive filesystem was available (`/mnt/c` absent), so Claim 9's macOS residue is static.
- **Escalate:** Claim 7. If the Q-049 paste is run as written and `claude` fails, it reports "enforced" and the plan closes N3. Fix the paste before the user runs it. Claim 11 (bare-host deny on `global-instructions/CLAUDE.md`) is worth the orchestrator's attention as a possible regression.
- **Files written:** this report plus untracked execution logs under `docs/reviews/execution-logs/iter3-r2-*`. No tracked file was modified and nothing was committed.
