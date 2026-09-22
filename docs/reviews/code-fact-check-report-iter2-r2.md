**Commit:** 16f2978

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch `answers-2026-09-20`
**Scope:** partial — `git diff f023357..answers-2026-09-20` (fix commits for iteration-1 findings; 23 files) plus the commit messages of those commits. Commits in `main..f023357` read as context only.
**Checked:** 2026-09-21
**Total claims checked:** 27
**Summary:** 17 verified, 6 mostly accurate, 0 stale, 4 incorrect, 0 unverifiable

Hallucination-pattern log read before checking (`docs/reviews/hallucination-patterns.md`). Claim 11 resembles the logged class "a specific measured value quoted from a checked-in artifact set that does not contain it" (the "All 85 tests" entry, first seen 2026-09-12).

Execution provenance: all executed probes ran in `/workspace` (or a scratch temp repo under the scratchpad) between 2026-09-22T03:25Z and 03:31Z (UTC; local date 2026-09-21), with a temp `HOME` where a hook or `questions.sh` was involved. Captured output lives under `/tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/cfc-r2/` (called `$S/` below). Probe scripts: `$S/probe.py` (Bash payloads → repo hook), `$S/probe_old.py` (the same, against the pre-fix hook `git show c5a7c96^:hooks/guard-trusted-writes.py`), `$S/fileprobe.py` (file-tool payloads in an installed-layout fixture), `$S/qprobe.sh.txt` (questions.sh).

---

## Claim 1: "One row kind is machine-written: an `Accepted-immutable` row … it is the only row kind written without a human decision … Older `Accepted-immutable` rows below that lack the `[auto: …]` prefix were written by hand"

**Location:** `docs/reviews/override-log.md:35-47`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between override-log.md, `skills/code-review/references/override-log.md` § Capture format and `skills/code-review/SKILL.md` Step 3.5 on the row kind, its verdict vocabulary and its "only machine-written kind" status; does not establish that the orchestrator actually emits the `[auto: code-review]` prefix at run time.
**Legibility-target:** for-orchestrator-synthesis

The canonical definition exists at the cited anchor: `skills/code-review/references/override-log.md:11` "### Capture format", with `:20` "for an `Accepted-immutable` row only — `Fact-check Incorrect`" and `:29` "the `Reason` cell starts with `[auto: code-review]`". SKILL.md agrees: `skills/code-review/SKILL.md:158` "That is the only row kind a run may write, and it is marked as machine-written per the [capture format]". The two 2026-09-12 `Accepted-immutable` rows (`59ca38f`, `c56be81`) indeed carry no `[auto: …]` prefix, while the new 2026-09-21 row does ("[auto: code-review] merged commit 4c7a2bb message …").

**Evidence:** `docs/reviews/override-log.md:35-47`, `docs/reviews/override-log.md:80-85`, `skills/code-review/references/override-log.md:11-32`, `skills/code-review/SKILL.md:148-158`

---

## Claim 2: "HARD = exactly what permissions.deny covers (hooks/wiring.json): {{CLAUDE_DIR}}/hooks/**, {{CLAUDE_DIR}}/settings*.json, {{CLAUDE_DIR}}/CLAUDE.md, ~/CLAUDE.md" (also `_is_hard` docstring "HARD == exactly what permissions.deny covers")

**Location:** `hooks/guard-trusted-writes.py:10`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the four path families the file-tool HARD tier names versus the eight Edit/Write deny rules in `hooks/wiring.json`; does not establish how Claude Code matches deny patterns (case, symlink resolution, relative-vs-absolute rule syntax), which decides whether the extra HARD paths below are actually denied.
**Legibility-target:** for-author

The four families match the deny block exactly (`hooks/wiring.json:120-127`: `"Edit({{CLAUDE_DIR}}/settings*.json)"`, `"Edit({{CLAUDE_DIR}}/hooks/**)"`, `"Edit({{CLAUDE_DIR}}/CLAUDE.md)"`, `"Edit(~/CLAUDE.md)"` and the Write twins). But HARD is a strict superset of their literal text in two ways:

```python
# hooks/guard-trusted-writes.py:109-117
    rel = _global_rel(cand)
    if rel is not None and rel.parts:
        first = rel.parts[0].lower()
        ...
        if len(rel.parts) == 1 and first.startswith("settings") and first.endswith(".json"):
```
(excerpt ends :115; enclosing `_is_hard()` continues to :119 — read)

— matching is case-folded, so `~/.claude/Settings.JSON` is HARD (probe: `defer` for a tainted session) though the glob text `settings*.json` names only lower case; and `classify_path` makes a resolve() onto a link target HARD (`hooks/guard-trusted-writes.py:133`: `if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS)`), so the payload file `$T/opt/cw/CLAUDE.md` and `$T/opt/cw/hooks/foo.sh` are HARD (probe: `defer` while tainted) though no deny rule names the payload dir. For those paths the hook defers and, unless Claude Code resolves symlinks/case when matching deny rules, nothing gates them. c5a7c96's own Notes acknowledge the link-target case ("its hooks/ and global CLAUDE.md now defer rather than ask"). The precise statement: HARD = the deny rules' paths, case-insensitively, plus any path that resolves onto their targets.

**Evidence:** `hooks/guard-trusted-writes.py:10-20`, `hooks/guard-trusted-writes.py:79-94`, `hooks/guard-trusted-writes.py:104-119`, `hooks/guard-trusted-writes.py:121-148`, `hooks/wiring.json:114-128`; executed `python3 $S/fileprobe.py $S` (cwd $S, exit 0, 2026-09-22T03:27Z) → `$S/fileprobe.log`

---

## Claim 3: "SOFT = … a PROJECT's own .claude/ …, and managed-settings.json. No deny rule names these, so deferring would leave them with no gate at all" (commit c5a7c96: "managed-settings.json moves to SOFT for the file tools")

**Location:** `hooks/guard-trusted-writes.py:22-26`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file-tool tier for managed-settings.json and that no deny rule names it, and that Bash writes to it are still HARD; does not establish anything about how Claude Code itself protects `/etc/claude-code/managed-settings.json` (root-owned in normal installs).
**Legibility-target:** for-orchestrator-synthesis

The deny block (`hooks/wiring.json:115-127`) contains no managed-settings rule. `classify_path` now returns soft for it: `hooks/guard-trusted-writes.py:141-143` `if name in ("claude.md", "agents.md", "claude.local.md", "managed-settings.json") … return "soft"`. This is not a regression: before c5a7c96 it was HARD → silent defer with no deny rule (ungated); now it asks when tainted (bats "R3: managed-settings.json is SOFT for file tools" passes on HEAD, fails on the pre-fix hook). The Bash path keeps it HARD: `hooks/guard-trusted-writes.py:185` `HARD_FRAG = re.compile(r"\.claude/hooks(/|\b)|\.claude/settings|managed-settings", re.I)`.

**Evidence:** `hooks/guard-trusted-writes.py:136-148`, `hooks/guard-trusted-writes.py:185`, `hooks/wiring.json:115-127`; executed `bats test/hooks/guard-trusted-writes.bats` (cwd /workspace, exit 0, 2026-09-22T03:25:49Z) → `$S/cur-hook-bats.log`; pre-fix run → `$S/old-hook-bats.log`

---

## Claim 4: "devcontainer-config/link-claude-home.sh uses DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}": an empty value falls back, `~` is NOT expanded, and there is no second dir … A relative value is anchored at the hook's cwd" (commit c5a7c96: "one config_dir() helper computes {{CLAUDE_DIR}} exactly as link-claude-home.sh does")

**Location:** `hooks/guard-trusted-writes.py:63-73`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the empty, unset, `~`-literal and absolute cases against the linker's `DEST` line; does not establish equality for a relative CLAUDE_CONFIG_DIR, where the two anchor at different working directories.
**Legibility-target:** for-author

The linker line is quoted correctly (`devcontainer-config/link-claude-home.sh:36` `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"`) and the hook mirrors it for unset/empty/`~`:

```python
# hooks/guard-trusted-writes.py:72-73
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    return Path(os.path.abspath(cfg)) if cfg else HOME / ".claude"
```

The R3 bats cases for empty and `~` values pass on HEAD. The word "exactly" in the commit message is imprecise for one case, which the docstring itself states: a relative value is used as-is by the linker (relative to the linker's cwd at container start) but anchored at the hook process's cwd here, so the two resolve to different dirs unless the cwds coincide. Precise wording: "matches the linker for absolute, empty and `~`-literal values".

**Evidence:** `hooks/guard-trusted-writes.py:63-73`, `devcontainer-config/link-claude-home.sh:36-39`, `test/hooks/guard-trusted-writes.bats` (R3 tests); `$S/cur-hook-bats.log`

---

## Claim 5: "In the installed layout ~/.claude/hooks and ~/.claude/CLAUDE.md are symlinks into /opt/claude-workflows, so resolve() leaves GLOBAL_DIRS; these catch a candidate that resolves onto a link target (R4)"

**Location:** `hooks/guard-trusted-writes.py:82-94`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the real container layout of hooks and CLAUDE.md and that paths resolving onto those targets (direct, via `..`, via a sibling symlinked dir like `scripts/..`, via a project `.claude` symlinked to `~/.claude`) classify HARD; does not establish coverage for a settings*.json that is itself a symlink created after the hook starts (the name set is computed at import).
**Legibility-target:** for-orchestrator-synthesis

The linker links `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)` (`devcontainer-config/link-claude-home.sh:50`) and the live `~/.claude` shows `CLAUDE.md -> /opt/claude-workflows/CLAUDE.md` and `hooks -> /opt/claude-workflows/hooks` (paraphrased — no quote available because this is directory-listing output, captured by `ls -la ~/.claude`). The bats `install_layout` fixture creates the same two links. In the fixture probe every one of `$P/hooks/foo.sh`, `$P/hooks/new.sh`, `$P/CLAUDE.md`, `~/.claude/scripts/../hooks/x`, `~/.claude/scripts/../CLAUDE.md`, `~/.claude/x/../../CLAUDE.md`, `~/./CLAUDE.md` deferred in a tainted session (never ask).

**Evidence:** `hooks/guard-trusted-writes.py:79-94`, `hooks/guard-trusted-writes.py:121-134`, `devcontainer-config/link-claude-home.sh:50-66`, `test/hooks/guard-trusted-writes.bats` `install_layout()`; `$S/fileprobe.log`

---

## Claim 6: "pathlib already collapses `//` and `/./`; normpath also folds `..` lexically, so `~/.claude/x/../CLAUDE.md` is seen as `~/.claude/CLAUDE.md` (R4)"

**Location:** `hooks/guard-trusted-writes.py:123-124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the lexical and normpath candidates for `//`, `/./` and `..`; does not establish behaviour for relative file_path values (resolved against the hook's cwd).
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:125-132
    norm = Path(os.path.normpath(str(p)))
    rp = _safe_resolve(p)
    cands = (p, norm, rp)
    for cand in cands:
        if _is_hard(cand):
            return "hard"
```
(excerpt ends :132; enclosing `classify_path()` continues to :148 — read)

Bats R4 cases `$HOME/.claude/x/../CLAUDE.md` and `$HOME/.claude//CLAUDE.md` defer on HEAD and fail against the pre-fix hook.

**Evidence:** `hooks/guard-trusted-writes.py:121-148`; `$S/cur-hook-bats.log`, `$S/old-hook-bats.log`

---

## Claim 7: "TODO(A8): write primitives not recognised here …: `ln -sf`, `curl -o`, `wget -O`, `tar -C` / `tar -x`, `unzip -d`, `sponge`, `python3 script.py` (non-inline interpreters), `git checkout` / `git restore` …, and `git config --global`. A command that writes only through these gets no opinion from this hook."

**Location:** `hooks/guard-trusted-writes.py:150-155`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that none of the listed commands matches `WRITE_PRIMITIVE`; does not establish that the list is exhaustive.
**Legibility-target:** for-orchestrator-synthesis

`WRITE_PRIMITIVE` (`hooks/guard-trusted-writes.py:156-164`) alternates only redirects, `tee`, `sed -i`, `dd of=`, `truncate`, `cp|mv|install|rsync`, and `python…|node|perl|ruby` followed by `-c`/`-e`; `bash_targets` returns `None` when it does not match (`:191-193` `if not has_write: return None`). No listed command name appears in the pattern.

**Evidence:** `hooks/guard-trusted-writes.py:150-164`, `hooks/guard-trusted-writes.py:190-205`

---

## Claim 8: commit c5a7c96 — the listed R1/A10 spellings ("$HOME"/CLAUDE.md, ~//, ~/./, ~/"CLAUDE.md", ${HOME:-}, $HOME/x/.., ~/.claude//, "$HOME/.claude"/CLAUDE.md, H=~; … $H/CLAUDE.md, cd ~/.claude && mv x CLAUDE.md; ~/.claude//settings.json, ~/".claude"/settings.json, cd ~/.claude && … > settings.json) are denied

**Location:** `hooks/guard-trusted-writes.py:190-205` (claim in commit c5a7c96 message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the 13 listed spellings plus the bats-only extras (`${HOME:-/root}`, `~/.claude/./`, `cd "$CLAUDE_CONFIG_DIR" && cp x claude.md`, `cd ~/.claude && cp x hooks/foo.sh`), all of which escaped the pre-fix hook; does not establish that unlisted spellings are denied (see Claim 9).
**Legibility-target:** for-orchestrator-synthesis

All 13 listed commands return `deny` from the repo hook (HOME=/home/node, CLAUDE_CONFIG_DIR unset) and `defer` from the pre-fix hook, as do the four bats-only extras. The mechanism is the co-occurrence rule:

```python
# hooks/guard-trusted-writes.py:196-201
    if CLAUDE_MD.search(cmd) and HOME_INDICATOR.search(cmd):
        return "hard"
    # A10: settings*.json / hooks plus the config dir named anywhere.
    if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd):
        return "hard"
```
(excerpt ends :201; enclosing `bash_targets()` continues to :205 — read)

**Evidence:** `hooks/guard-trusted-writes.py:166-205`; executed `python3 $S/probe.py /home/node $S/cmds.txt` (cwd /workspace, exit 0, 2026-09-22T03:25Z) → `$S/probe-bash.log`; `python3 $S/probe_old.py /home/node $S/cmds.txt` and `… $S/cmds2.txt` (exit 0, 03:31Z) → `$S/probe-bash-old.log`

---

## Claim 9: commit c5a7c96 Notes — "The residual: shell obfuscation of the file name itself (CLAUDE.m*, C${x}.md) and A8 primitives are still unguarded."

**Location:** `hooks/guard-trusted-writes.py:166-205` (claim in commit c5a7c96 message)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Bash commands that write a HARD target using the recognised write primitives and an unobfuscated file name; does not establish whether any of them is reachable past other layers (permission prompts, the sandbox).
**Legibility-target:** for-author

The stated residual (file-name obfuscation + A8 primitives) is not the whole residual. With plain `>`/`cp` and an unobfuscated file name, these reach HARD targets and get no opinion (`defer`) from the repo hook:

- home reached with no textual indicator: `cd; echo x > CLAUDE.md`, `cd && echo x > CLAUDE.md`, `cd .. && cd .. && echo x > CLAUDE.md`, `cd /; echo x > home/node/CLAUDE.md`, `echo x > /home/$USER/CLAUDE.md` (writes `~/CLAUDE.md`, covered by deny rule `Write(~/CLAUDE.md)`);
- the **directory** name obfuscated rather than the file name: `cd; cd .cla?de; echo {} > settings.json`, `cd; cd .cla?de/hooks; echo x > g.py`, `echo {} > ~/.cla*/settings.json`, `echo x > ~/.cla*/hooks/guard-trusted-writes.py`, `echo x > ~/.clau""de/hooks/g.py`, `echo x > ~/.clau''de/settings.json`;
- quoting/escaping inside `settings`/`hooks`: `cp x ~/.claude/set\tings.json`, `cp x ~/.claude/hook\s/g.py`, `cp x "$HOME"/.claude/hoo"ks"/g.py`, `cp x ~/.claude/"settings".json`.

The cause is that the indicators are literal text (`hooks/guard-trusted-writes.py:171-172` `_HOME_INDICATORS = [r"~", r"\$HOME\b", r"\$\{[!#]?HOME\b", r"\.claude\b", …]`; `:184` `SETTINGS_OR_HOOKS = re.compile(r"settings[\w.-]*\.json|\bhooks\b", re.I)`). A `cd` with no argument, `$USER`-built paths, a split literal home path, and globbed/quoted `.claude` contain none of them. Contrast: `D=.claude; echo {} > ~/$D/settings.json` and `echo x > $HOME/.cla?de/CLAUDE.md` are denied (they still contain `.claude` or `~`/CLAUDE.md). The residual note should name directory/home-path obfuscation and bare `cd`, not only the file name.

**Evidence:** `hooks/guard-trusted-writes.py:171-205`; `$S/probe-bash.log` (rows 14-35)

---

## Claim 10: "Only a CLAUDE.md with NO home/global indicator anywhere reaches SOFT (Q-035)."

**Location:** `hooks/guard-trusted-writes.py:202`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the textual ordering of `bash_targets` (HARD checks run before SOFT_FRAG); does not establish that a SOFT-classified command cannot write the global file (Claim 9 shows it can).
**Legibility-target:** for-orchestrator-synthesis

`hooks/guard-trusted-writes.py:194-204` checks HARD_FRAG, then `CLAUDE_MD` ∧ `HOME_INDICATOR`, then settings/hooks ∧ `CFG_INDICATOR`, and only then `SOFT_FRAG`. Bats "R1: a bare CLAUDE.md with no home indicator stays SOFT" passes (defer untainted, ask tainted).

**Evidence:** `hooks/guard-trusted-writes.py:190-205`; `$S/cur-hook-bats.log`

---

## Claim 11: commit c5a7c96 — "Tests: 18 new bats cases (installed-layout fixture with symlinked hooks and CLAUDE.md)"

**Location:** `test/hooks/guard-trusted-writes.bats:301-457` (claim in commit c5a7c96 message)
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of `@test` blocks the commit adds; does not establish anything about coverage quality.
**Legibility-target:** for-author

`git diff c5a7c96^..c5a7c96 -- test/ | grep -c '^+@test'` → `14` (5 R1, 1 A10, 4 R3, 4 R4). The commit touches only `hooks/guard-trusted-writes.py` and `test/hooks/guard-trusted-writes.bats`, so no other file adds cases. Loop-style tests iterate over several spellings, but those are single bats cases. (Same class as the logged "All 85 tests" count pattern.)

**Evidence:** `test/hooks/guard-trusted-writes.bats:301-457`; executed `git diff c5a7c96^..c5a7c96 -- test/ | grep -c '^+@test'` (cwd /workspace, exit 0, 2026-09-22T03:25Z; output `14`, inline in this report because it is a single integer)

---

## Claim 12: commit c5a7c96 — "every new R-test fails against the pre-fix hook" (and test comment "Each of these returned no opinion (untainted) or ask (tainted) at 4c7a2bb")

**Location:** `test/hooks/guard-trusted-writes.bats:302` (claim in commit c5a7c96 message)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers running HEAD's bats file against the hook at `c5a7c96^` (= `290f913`, byte-identical to 4c7a2bb's hook); the `:302` comment is verified separately for the R1 loop's spellings; does not establish whether the passing cases were intended as characterization tests.
**Legibility-target:** for-author

Against the pre-fix hook, 10 of the 14 new cases fail but 4 pass: `ok 39 R1: a heredoc whose prose names ~/.claude/CLAUDE.md is denied`, `ok 40 R1: a bare CLAUDE.md with no home indicator stays SOFT`, `ok 43 R3: an empty CLAUDE_CONFIG_DIR falls back to ~/.claude`, `ok 49 R4: a real (non-symlinked) project .claude still asks when tainted`. These look like regression guards for behaviour that was already correct, which is legitimate, but the commit's "every" is false. The `:302` comment (about the R1 loop's spellings) holds: each of those spellings returned `defer` from the pre-fix hook.

**Evidence:** `test/hooks/guard-trusted-writes.bats:298-457`; executed `bats test/hooks/guard-trusted-writes.bats` with `GUARD` pointing at `git show c5a7c96^:hooks/guard-trusted-writes.py` (cwd `$S/old`, exit 1, 2026-09-22T03:25:39Z) → `$S/old-hook-bats.log`; `$S/probe-bash-old.log`

---

## Claim 13: "Zero-padded fields keep ids lexically sortable in start order, which _archived_newest_first relies on."

**Location:** `scripts/lib/si-functions.sh:466-468`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers ordering among `YYYY-MM-DD-HHMMSS` ids and between new ids and date-only ids from other days; does not establish ordering on the day both formats coexist.
**Legibility-target:** for-author

`si_default_run_id` is `date +%F-%H%M%S` (`scripts/lib/si-functions.sh:469-471`), and `_archived_newest_first` reverses glob order (`scripts/lib/si-morning-summary.sh:1131-1142`, "Glob expansion is lexically sorted (oldest date first), so reverse it"). Among new-format ids this is sound. But archived names are `<id>-<name>`, and a pre-change date-only id from the same day sorts after a timestamped one — `2026-03-25-tasks-round-3.json` vs `2026-03-25-031500-tasks-round-3.json`: `t` (0x74) > `0` (0x30) (paraphrased — no quote available because this is a byte-order comparison, not code) — so on a transition day the older run is listed as newest. Tighten to "sortable in start order among timestamped ids".

**Evidence:** `scripts/lib/si-functions.sh:461-471`, `scripts/lib/si-morning-summary.sh:1125-1142`

---

## Claim 14: "True no-op (the file is not opened for writing) when the header already has a Run cell or no header is found. A real migration rewrites the file in place (temp file, then `cat tmp > file`), so the log keeps its inode and mode"

**Location:** `scripts/lib/si-functions.sh:558-561`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the found-Run (awk exit 0), no-header (exit 2) and migrate (exit 1) paths and inode/mode/temp-file cleanup on migrate; does not establish atomicity (the in-place `cat >` truncates first, so an interrupted write can leave a partial log).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/si-functions.sh:572-574
        } END { if (!hdr) exit 2; exit !found }' "$log_file" || state=$?
    [ "$state" -eq 1 ] || return 0
```
and the write `' "$log_file" > "$tmp" && cat "$tmp" > "$log_file" || rc=$?` then `rm -f "$tmp"` (`:586-588`). The three new R5 bats cases (inode + mode 644 preserved, no temp left; `%i %Y %a` unchanged for both no-op paths) pass.

**Evidence:** `scripts/lib/si-functions.sh:555-589`, `test/append-approved-hypotheses.bats` (R5 tests); executed `bats test/append-approved-hypotheses.bats` (cwd /workspace, exit 0, 20 ok, 2026-09-22T03:29Z) → `$S/bats-append-approved-hypotheses.log`

---

## Claim 15: "Accept only the charset self-improvement.sh and archive-working-docs.sh enforce on the writer side (no `/`, so the id can never leave archive/ …)"

**Location:** `scripts/lib/si-morning-summary.sh:1145-1156`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reader-side regex and its application at the row reader, `_find_tasks_file` and `_days_since_round`; does not establish that every writer of an archive prefix enforces the charset.
**Legibility-target:** for-author

`_valid_run_id` is `[[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]` (`:1154-1156`) and is applied at all three readers (`:1018`, `:1189`, `:1350`); the two traversal bats cases pass. self-improvement.sh enforces the same regex on SI_RUN_ID. archive-working-docs.sh enforces it only on the si-run-id.txt default (`scripts/archive-working-docs.sh:45` `if [[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then`); an explicit CLI prefix is taken as-is (`:33` `*) PREFIX="$arg" ;;`). Precise version: "the charset self-improvement.sh enforces on SI_RUN_ID and archive-working-docs.sh enforces on the si-run-id.txt default".

**Evidence:** `scripts/lib/si-morning-summary.sh:1015-1018`, `:1145-1156`, `:1187-1190`, `:1347-1351`, `scripts/archive-working-docs.sh:27-49`; `$S/bats-precondition-gate.log`, `$S/bats-morning-summary-clusters.log`

---

## Claim 16: "_live_run_matches: True when the row has no run id … or when the recorded id equals it. When si-run-id.txt is absent or empty … this is false; callers still reach the live files through their newest-first fallback"

**Location:** `scripts/lib/si-morning-summary.sh:1158-1173`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_live_run_matches` and the two callers' fallback lists; does not establish the fallback's ranking when several archived copies exist.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/si-morning-summary.sh:1166-1173
_live_run_matches() {
    local working_dir="$1" run="$2"
    [ -z "$run" ] && return 0
    [ -f "$working_dir/si-run-id.txt" ] || return 1
    local live
    live=$(head -n1 "$working_dir/si-run-id.txt" 2>/dev/null)
    [ -n "$live" ] && [ "$live" = "$run" ]
}
```

Fallbacks: `_find_tasks_file` always emits the live `tasks-round-$round.json` after the run-specific candidates (`:1203`), and `_days_since_round` falls through to `rounds/round-$round-report.json`, `round-$round-report.json` and archived copies (`:1382-1384`). The new `_live_run_matches` and `_days_since_round` bats cases pass.

**Evidence:** `scripts/lib/si-morning-summary.sh:1158-1206`, `:1347-1396`; `$S/bats-precondition-gate.log`

---

## Claim 17a: "Only UNESCAPED pipes delimit cells … `\|` is swapped for a sentinel before the split and restored afterwards, so the cell keeps its escaped (markdown-safe) text." / "Locals carry a _srf_ prefix so they cannot shadow the caller's array name through the nameref"

**Location:** `scripts/lib/si-morning-summary.sh:1515-1538`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers splitting of rows containing `\|` and caller array names `raw`, `f`, `line`; does not establish behaviour for a caller array named `out_ref` (works, with bash circular-nameref warnings) or `_srf_*`.
**Legibility-target:** for-orchestrator-synthesis

`_srf_line="${_srf_line//\\|/$_srf_sep}"` before `IFS='|' read -ra _srf_raw`, then `_srf_f="${_srf_f//$_srf_sep/\\|}"` per field (`:1528-1534`). Probe: `_split_row_fields "| 1 | a \| b | c |" <name>` gives 4 fields with field 2 = `a \| b` for names `raw`, `f`, `line`. The writer escapes pipes as `hyp="${hyp//|/\\|}"` (`scripts/lib/si-functions.sh:548`), matching the reader.

**Evidence:** `scripts/lib/si-morning-summary.sh:1510-1538`, `scripts/lib/si-functions.sh:548`; executed inline `bash -c 'source scripts/lib/si-morning-summary.sh; … _split_row_fields …'` (cwd /workspace, exit 0, 2026-09-22T03:30Z; output quoted above); `$S/bats-morning-summary-clusters.log`

---

## Claim 17b: "ASCII Record Separator: never present in a log row"

**Location:** `scripts/lib/si-morning-summary.sh:1527`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the writer enforces; does not establish whether any real log row contains 0x1E.
**Legibility-target:** for-author

Nothing enforces this. The writer escapes only pipes (`scripts/lib/si-functions.sh:548` `hyp="${hyp//|/\\|}"`); a hypothesis text containing 0x1E would be written verbatim and turned into `\|` on read. It is practically true but unenforced; precise wording: "not expected in a log row (unenforced)".

**Evidence:** `scripts/lib/si-functions.sh:540-552`, `scripts/lib/si-morning-summary.sh:1527-1532`

---

## Claim 18: "Every command except `init` needs both files to exist and fails, pointing at `init`, when they don't" / "Inside .git/ there is no toplevel, so the $PWD fallback below would create .git/docs/working/"

**Location:** `scripts/questions.sh:42-45`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `next-id`, `index`, `archive`, `open`, `check` with both files missing, and `init` run from inside `.git`; does not establish behaviour when only one file is missing (code path is the same loop).
**Legibility-target:** for-orchestrator-synthesis

In a fresh temp repo, each of `next-id`, `index`, `archive`, `open`, `check` exits 1 and prints `✗ missing: …` for both files plus "run `~/.claude/scripts/questions.sh init` first". `require_files` does this (`scripts/questions.sh:129-135`); `cmd_check` sets `rc=1` for each missing file (`:233` `[[ -f "$file" ]] || { echo "  ✗ missing: $file" >&2; rc=1; continue; }`). From `.git/`, `init` dies with "is inside a .git directory" and creates nothing (`:76-78`).

**Evidence:** `scripts/questions.sh:42-45`, `:74-78`, `:127-135`, `:229-302`; executed `bash $S/qprobe.sh.txt $S` (cwd $S, exit 0, 2026-09-22T03:28:09Z) → `$S/qprobe.log` (cases 1-2)

---

## Claim 19: "Writes never go through a symlink."

**Location:** `scripts/questions.sh:47`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers default paths with a symlinked ancestor above `docs/working/` and overridden paths with a symlinked grandparent; does not establish any exploit for the default-path case (containment still holds there).
**Legibility-target:** for-author

The checks look only at the file and its immediate directory:

```bash
# scripts/questions.sh:92-94
    dir="$(dirname "$file")"
    [[ -L "$file" ]] && die "refusing to write: $file is a symlink"
    [[ -L "$dir" ]] && die "refusing to write: directory $dir is a symlink"
```
(excerpt ends :94; enclosing `assert_write_target()` continues to :101 — read)

Probe case 3: `docs -> real` (in-repo) and `init` succeeded, creating `real/working/questions.md` through the `docs` link. Case 5: `QUESTIONS_LIVE=$T/r5/lnk/sub/q.md` with `lnk -> $T/out5` and `init` created `$T/out5/sub/q.md` — a write through a symlink to outside the repo, because overrides skip containment (`:95` `if [[ -z "$overridden" ]]`). The detailed comment at `:84-90` states the narrower, correct rule ("Checked for the file itself … and for its directory"); the header's "never" overclaims it.

**Evidence:** `scripts/questions.sh:47-51`, `:84-106`; `$S/qprobe.log` (cases 3, 5)

---

## Claim 20: "A default path must also resolve inside $PROJECT_ROOT, which catches a symlinked ancestor such as docs/ -> /elsewhere" and "-L is true for a dangling link too"

**Location:** `scripts/questions.sh:85-90`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `docs -> outside`, a dangling live-file link, and a symlinked `docs/working`, all with default paths; does not establish containment for overridden paths (exempt by design).
**Legibility-target:** for-orchestrator-synthesis

Case 4 (`docs -> $T/out`): `refusing to write: … resolves to …/out/working/questions.md, outside …/r4`, nothing created. Case 6 (dangling `questions.md -> $T/nowhere`): "is a symlink", target not created. Case 8 (`docs/working -> w2`): "directory … is a symlink". The comparison uses `realpath -m` on both sides (`:96-98`), so `..` and symlinked ancestors are folded before the prefix test.

**Evidence:** `scripts/questions.sh:84-101`; `$S/qprobe.log` (cases 4, 6, 8)

---

## Claim 21: "The temp file comes from mktemp in the target's own directory (O_EXCL …), takes the target's mode, and is renamed over the target only after the symlink checks pass again immediately before the rename."

**Location:** `scripts/questions.sh:110-125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `replace_with` as used by `index` and `archive`; does not establish race-freedom between the re-check and `mv` (not claimed).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/questions.sh:116-124
    tmp="$(mktemp "$(dirname "$target")/.questions.XXXXXX")"
    if ! "$@" > "$tmp"; then rm -f "$tmp"; return 1; fi
    chmod --reference="$target" "$tmp" 2>/dev/null || true
    if [[ -L "$target" || -L "$(dirname "$target")" ]]; then
        rm -f "$tmp"; die "refusing to write: $target became a symlink"
    fi
    mv -f -- "$tmp" "$target"
```
Probe case 7: after `chmod 640` and `index`, the file stayed `640`, no `.questions.*` or `.tmp` left in `docs/working/`, and `check` passed.

**Evidence:** `scripts/questions.sh:110-125`, `:305-341`, `:374-389`; `$S/qprobe.log` (case 7)

---

## Claim 22: "Re-check now the directory exists, then create with noclobber, whose O_EXCL open fails rather than following anything that appeared at the path in between."

**Location:** `scripts/questions.sh:428-437`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers bash noclobber semantics for a path that appears between the re-check and the redirect; does not establish that this race is exploitable in practice.
**Legibility-target:** for-author

For a new regular file or a dangling symlink, noclobber's exclusive create does refuse. But bash's noclobber only refuses existing **regular** files; if a symlink to an existing non-regular file appears in the window, the redirect follows it. Probe 9: `ln -s /dev/null nc; ( set -o noclobber; echo x > nc )` → exit 0. Tighten to "fails for any regular file or dangling link that appeared".

**Evidence:** `scripts/questions.sh:415-440`; `$S/qprobe.log` (case 9)

---

## Claim 23: "First column only: a summary may itself mention another entry's ID." (42bf2fc)

**Location:** `scripts/questions.sh:289-290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the id extraction against the rows `render_index` emits; does not establish handling of a hand-edited index row that doesn't start with `| [Q-`.
**Legibility-target:** for-orchestrator-synthesis

`grep -ao '^| \[Q-[0-9]\{3\}\]' | grep -ao 'Q-[0-9]\{3\}'` (`:290`) matches the row format `printf '| [%s](#%s--%s) | …'` (`:322`, `:329`). `bash scripts/questions.sh check` on the repo prints "✓ questions: structure valid, indexes current" (exit 0) even though Q-048's index summary is prose; the questions-doc bats suite (26 ok) passes.

**Evidence:** `scripts/questions.sh:285-296`, `:313-331`; executed `bash scripts/questions.sh check` (cwd /workspace, exit 0, 2026-09-22T03:30Z, output quoted above); `$S/bats-questions-doc.log`

---

## Claim 24: rubric.md A1 — heading `### Qualifying author note` is "the linkable copy"; "The template above repeats this definition"; pr-prep/review-fix-loop links point at `#qualifying-author-note`

**Location:** `skills/code-review/references/rubric.md:159-175`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the heading being outside the template's code fence, the template's `## 🟡 Must Address` definition, and the two workflow links; does not establish rendering on a specific Markdown host.
**Legibility-target:** for-orchestrator-synthesis

The fence closes at `:157` ("```") before `:159` "### Qualifying author note", so the GitHub-style anchor `#qualifying-author-note` exists. The template definition is at `:52` ("Each must carry a resolution or a **qualifying author note**. A qualifying note…"). `workflows/pr-prep.md:190` and `workflows/review-fix-loop.md:43` both now link `rubric.md#qualifying-author-note`.

**Evidence:** `skills/code-review/references/rubric.md:49-60`, `:153-175`, `workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`

---

## Claim 25: A2 — the contextual-critic row maps test-strategy by "high → 🟡", "medium, low → 🟢", repeated consistently in rubric.md and SKILL.md

**Location:** `skills/code-review/references/rubric.md:304-311`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every test-strategy mapping mention under `skills/code-review/` and `workflows/`; does not establish that test-strategy findings carry exactly one priority each.
**Legibility-target:** for-orchestrator-synthesis

test-strategy's scale is `**Priority:** [high / medium / low]` (`skills/test-strategy/SKILL.md:196`). The table reads `| 🟡 Must Address | Major | high | any confirmed finding |` and `| 🟢 Consider | Minor and below | medium, low | — |`; the three prose restatements (`rubric.md:357`, `rubric.md:521`, `SKILL.md:1230`) say "test-strategy high→🟡". `rg -n 'P1|P2' skills/code-review/ workflows/` finds no test-strategy P-mapping, and `test/skills/code-review-executable-defect.bats` (10 ok) now asserts this.

**Evidence:** `skills/code-review/references/rubric.md:304-311`, `:357`, `:521`, `skills/code-review/SKILL.md:1230`, `skills/test-strategy/SKILL.md:196`; `$S/bats-code-review-executable-defect.log`

---

## Claim 26: A13 — the hot-path gate and the Macro × Cold row give the same escalation exceptions

**Location:** `skills/performance-reviewer/SKILL.md:46`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the text of the gate and the Macro × Cold row; does not establish the other three rows' consistency with the gate.
**Legibility-target:** for-orchestrator-synthesis

Gate: "unless the cold path blocks a latency-sensitive operation or runs over large data (e.g. a nightly batch over a full table), in which case escalate as for a hot path" (`:46`). Row: "Low (same exceptions as the hot-path gate: escalate when the cold path blocks a latency-sensitive operation or runs over large data, e.g. a nightly batch)" (`:283`). The two exception sets are the same.

**Evidence:** `skills/performance-reviewer/SKILL.md:46`, `:280-285`

---

## Claim 27: "bats runs each test in its own process, so `$$` differs between setup_file and every test. The old "/tmp/bats-hc-cache.$$" never hit" (commit bd07c4e: "405s -> 42s … Coverage unchanged: same 17 tests, same script runs"; Q-023 closure repeats the figures)

**Location:** `test/scripts/health-check.bats:21-25`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `$$` mechanism, the cache now hitting, the 17-test count, and that the two negative frontmatter tests still run the script uncached; the wall-clock figure is machine-dependent (54s measured here vs 42s claimed).
**Legibility-target:** for-orchestrator-synthesis

A 2-test probe file logged `sf 1690438`, `t1 1690445`, `t2 1690452` — `$$` differs between setup_file and each test. The cache path is now `_HC_CACHE_DIR="$BATS_FILE_TMPDIR/hc-cache"` (`:25`); `health-check.bats` ran in 54s, 17 ok, exit 0. The negative tests call `HEALTH_CHECK_SKILLS_DIR="$skills_dir" run bash "$SCRIPT"` directly (`:127`, `:140`), so caching does not weaken what they prove. Q-023's cited commit `0ccbdb8` exists and `scripts/health-check.sh:368-380` implements the skip guard and fast-then-slow order.

**Evidence:** `test/scripts/health-check.bats:13-52`, `:121-145`, `scripts/health-check.sh:345-385`, `docs/working/questions-archive.md:830-834`; executed `bats test/scripts/health-check.bats` (cwd /workspace, exit 0, 2026-09-22T03:29:49Z, elapsed 54s) → `$S/bats-health-check.log`; `$S/pid/p.bats` probe → `$S/pid/log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9** (commit c5a7c96 / `hooks/guard-trusted-writes.py:166-205`): the named residual (file-name obfuscation + A8) leaves out bare `cd`/`$USER`/split-home-path writes to `~/CLAUDE.md` and globbed/quoted `.claude`, `settings`, `hooks`. All of these defer.
- **Claim 11** (commit c5a7c96 / `test/hooks/guard-trusted-writes.bats`): "18 new bats cases". The real count is 14.
- **Claim 12** (commit c5a7c96 / `test/hooks/guard-trusted-writes.bats`): "every new R-test fails against the pre-fix hook". 4 of the 14 pass on the pre-fix hook (tests 39, 40, 43, 49).
- **Claim 19** (`scripts/questions.sh:47`): "Writes never go through a symlink". Only the file and its immediate directory are checked. A symlinked `docs/` (in-repo) or an override's symlinked grandparent is written through.

### Stale
- None.

### Mostly Accurate
- **Claim 2** (`hooks/guard-trusted-writes.py:10`): HARD is a superset of the deny text, because of case-folding and link targets such as the `/opt` payload. Either say so, or confirm that Claude Code's deny matching covers those paths.
- **Claim 4** (`hooks/guard-trusted-writes.py:63-73`, commit c5a7c96): the config dir matches the linker "exactly" except when CLAUDE_CONFIG_DIR is relative.
- **Claim 13** (`scripts/lib/si-functions.sh:466`): ids sort lexically in start order only among timestamped ids. On the day old date-only ids and timestamped ids coexist, the order inverts.
- **Claim 15** (`scripts/lib/si-morning-summary.sh:1145-1152`): archive-working-docs.sh enforces the charset only on the si-run-id.txt default. The CLI PREFIX is unvalidated.
- **Claim 17b** (`scripts/lib/si-morning-summary.sh:1527`): "never present in a log row" is unenforced.
- **Claim 22** (`scripts/questions.sh:428-430`): noclobber still follows a symlink to an existing non-regular file.

### Unverifiable
- None.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/docs/reviews/code-fact-check-report-iter2-r2.md with `**Commit:** 16f2978` at the top, every claim tagged with a Legibility-target (Incorrect/Stale/Mostly Accurate → for-author; Verified/Unverifiable → for-orchestrator-synthesis), ending with a Goal-Alignment Note.
- Answered: brief items 1-11. Item 1: listed spellings denied (Claim 8), but more escape than the named residual (Claim 9). Item 2: Claims 2-4. Item 3: Claims 5, 6, 11, 12. Items 4-6: Claims 18-23. Item 7: Claim 14. Items 8-9: Claims 13, 15-17. Item 10: Claim 27. Item 11: Claims 1, 24-26. Every bats suite the diff touches passes on HEAD.
- Out of scope: `hooks/wiring.json` and pre-f023357 commits, which were read only as context. Q-048's accepted over-block was not re-flagged, and neither were A7 or A8.
- Escalate: (1) Claude Code's permission docs may treat a rule path starting with a single `/` as relative to the settings file, and `//` as absolute. If so, the substituted `Edit(/home/node/.claude/…)` deny rules may not match. That would undercut the "deny rules do the blocking" premise behind Claims 2-3. This is unverified here (no egress) and needs a live check. (2) Claim 11 matches the logged hallucination-pattern class, but I did not append to `docs/reviews/hallucination-patterns.md` because the brief forbids editing tracked files other than this report. The orchestrator may add it.
