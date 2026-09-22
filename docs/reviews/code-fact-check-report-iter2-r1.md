# Code Fact-Check Report

**Commit:** 16f2978

**Repository:** /workspace (claude-workflows)
**Scope:** partial — `git diff f023357..answers-2026-09-20` (fix commits of review-fix iteration 2; 23 files). Commits before f023357 are context only.
**Checked:** 2026-09-21
**Total claims checked:** 27
**Summary:** 15 verified, 8 mostly accurate, 1 stale, 3 incorrect, 0 unverifiable

Execution provenance: all executed probes ran hermetically (temp HOME, temp git repos under the scratchpad) with outputs captured in
`/tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/cfc-r1/` (referred to below as `$S/`). Probe scripts: `$S/probe.py` (Bash tier, command lists `$S/cmds.txt`, `$S/cmds2.txt`), `$S/probe_file.py` (file-tool tier, installed symlink layout), `$S/qs-probe.sh.txt` (questions.sh), `$S/si-probe.sh.txt` (SI helpers). No tracked file other than this report was touched. `docs/reviews/hallucination-patterns.md` was read; no claim matches a logged pattern, and no new fabrication was found.

---

## Claim 1: "`Accepted-immutable` rows (machine-written) … The canonical definition is `skills/code-review/references/override-log.md#capture-format`" (A5)

**Location:** `docs/reviews/override-log.md:35-47`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between the log header's row-kind definition, the canonical capture-format section, the rubric's immutable-history exception and SKILL Step 3.5's one-exception rule; does not establish that any orchestrator run actually suppresses a re-raise via these rows (no run was executed).
**Legibility-target:** for-orchestrator-synthesis

The canonical definition sits inside `### Capture format` (`skills/code-review/references/override-log.md:11`, before `### Capturing new overrides` at `:37`) and says the same thing: `` the `Reason` cell starts with `[auto: code-review]` `` … `Treat an Accepted-immutable row like a settled Won't-Fix in Step 3.5 matching … and never write any other verdict value automatically` (`override-log.md:24-33`). The rubric exception it points to exists under `### Unified Severity Mapping` (`rubric.md:289`): `**Immutable-history exception:** … the orchestrator appends an Accepted-immutable row` (`rubric.md:336-340`). SKILL Step 3.5: `the orchestrator may append an Accepted-immutable row … That is the only row kind a run may write` (`skills/code-review/SKILL.md:158`).

**Evidence:** `docs/reviews/override-log.md:35-47`, `skills/code-review/references/override-log.md:11-37`, `skills/code-review/references/rubric.md:289,336-340`, `skills/code-review/SKILL.md:158`

---

## Claim 2: "Refuted at `hooks/guard-trusted-writes.py:56-132`: the Bash HARD tier for the global CLAUDE.md now matches only literal spellings, and nested/`..`/symlinked global paths moved HARD→SOFT. … Live defects are R1/R4"

**Location:** `docs/reviews/override-log.md:82`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's file:line pointer and its present-tense description of the hook at HEAD; does not dispute the row's core verdict that commit 4c7a2bb's message was Incorrect at the time.
**Legibility-target:** for-author

The row was added in 46ef6b0 (before c5a7c96 merged) and describes the pre-fix hook. At HEAD the cited range no longer holds the refuted code: `:56-132` now spans `HOME = Path.home()` through the new `classify_path`, while the Bash patterns moved to `_HOME_INDICATORS = [...]` (`hooks/guard-trusted-writes.py:171`) and `HARD_FRAG = re.compile(r"\.claude/hooks(/|\b)|\.claude/settings|managed-settings", re.I)` (`:185`). The "now matches only literal spellings" and "Live defects are R1/R4" wording is false at HEAD (c5a7c96 fixed both; Claims 6 and 11). A pinned reference (e.g. `4c7a2bb:hooks/guard-trusted-writes.py:56-132`) and past tense would keep it accurate.

**Evidence:** `docs/reviews/override-log.md:82`, `hooks/guard-trusted-writes.py:56-132,171,185`

---

## Claim 3: "Discoverable TODO: `# TODO(A8)` at WRITE_PRIMITIVE lists every command."

**Location:** `docs/reviews/override-log.md:80`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the TODO's existence at WRITE_PRIMITIVE and that it lists every command the row names; does not establish that the list covers every unrecognised write primitive.
**Legibility-target:** for-orchestrator-synthesis

`# TODO(A8): write primitives not recognised here … ln -sf, curl -o, wget -O, tar -C / tar -x, unzip -d, sponge, python3 script.py …, git checkout / git restore …, and git config --global` sits right above `WRITE_PRIMITIVE = re.compile(` (`hooks/guard-trusted-writes.py:150-156`). Every command in the row is in the TODO. The TODO also adds `tar -x` and `git restore`.

**Evidence:** `hooks/guard-trusted-writes.py:150-156`, `docs/reviews/override-log.md:80`

---

## Claim 4: "Runtime: … `health-check.bats` was 405s because its shared-output cache keyed on `$$` and never hit. It is now keyed on `BATS_FILE_TMPDIR`, so that file takes 42s … with the same coverage (bd07c4e)"

**Location:** `docs/working/questions-archive.md:833` (and bd07c4e subject "405s -> 42s"; `test/scripts/health-check.bats:21-25`)
**Type:** Performance / Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the cache mechanism (per-file shared dir, 3 real script runs, 17 tests, negative tests unchanged) and the order-of-magnitude runtime drop; does not reproduce the 42s figure, which is machine-dependent, or the 405s baseline, which was not re-run.
**Legibility-target:** for-author

The mechanism checks out: `_HC_CACHE_DIR="$BATS_FILE_TMPDIR/hc-cache"` (`test/scripts/health-check.bats:25`), which `setup_file` fills and `setup()` reads (`:34-51`). The two negative tests still run `HEALTH_CHECK_SKILLS_DIR="$skills_dir" run bash "$SCRIPT"` on their own copies (`:126,:139`), so what they prove is unchanged. The file has 17 `@test` blocks. Executed: `bats test/scripts/health-check.bats`, cwd `/workspace`, 2026-09-21T20:27:54-07:00, exit 0, **60s** wall time (all 17 ok). That is consistent with roughly three ~20s script runs (setup_file plus two negatives), but it is not 42s. The precise version: "~40–60s depending on host".

**Evidence:** `test/scripts/health-check.bats:21-51,121-145`, `$S/bats-hc.out`

---

## Claim 5a: "a write that names `CLAUDE.md`, `settings*.json` or `hooks` is denied whenever the command also contains `~`, `$HOME`, `.claude`, `global-instructions` or the config dir anywhere. That also denies `git commit` with `HEAD~1` in a CLAUDE.md-mentioning message"

**Location:** `docs/working/questions.md:38`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rule's indicator sets per policy name and the `git commit` example; does not dispute that the accepted false denies exist (the brief's Q-048 carve-out). This checks only whether the user is shown an accurate description to answer from.
**Legibility-target:** for-author

The entry merges two separate rules into one. In the code, settings/hooks co-occur only with `.claude` or the config dir: `_CFG_INDICATORS = [r"\.claude\b", r"CLAUDE_CONFIG_DIR"]` (`hooks/guard-trusted-writes.py:176`), used by `if SETTINGS_OR_HOOKS.search(cmd) and CFG_INDICATOR.search(cmd)` (`:200`). Only CLAUDE.md co-occurs with `~`/`$HOME`/`global-instructions` (`:171-172,197`). Separately, `bash_targets` returns `None` unless `WRITE_PRIMITIVE` matches (`:190-193`), and `git commit` is not one. Executed (`python3 $S/probe.py $S/cmds2.txt`, cwd `$S`, 2026-09-21T20:29:44-07:00, exit 0):
```
defer  | git commit -m "fix CLAUDE.md since HEAD~1"
deny   | git commit -F msg.txt && git log HEAD~1 -- CLAUDE.md > out.txt
defer  | echo x > ~/foo/settings.json
defer  | echo x > $HOME/foo/hooks/g.sh
```
Accurate version: "a write command (redirect/cp/mv/tee/…) that names CLAUDE.md is denied when `~`, `$HOME`, `.claude`, `global-instructions` or the config dir appears anywhere; one that names settings*.json or hooks is denied when `.claude` or the config dir appears. A `git commit` is caught only when the same command also writes (e.g. `> file`)." The c5a7c96 Notes line says "any write command that mentions CLAUDE.md and has a `~` anywhere (e.g. HEAD~1)", which is correct. The Q-048 paraphrase dropped the word "write".

**Evidence:** `hooks/guard-trusted-writes.py:156-164,171-176,190-203`, `$S/probe-bash2.out`

## Claim 5b: "and any Bash write into an agent worktree's `hooks/` (`/workspace/.claude/wt-*/hooks/…`)" is denied

**Location:** `docs/working/questions.md:38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `cp` into `.claude/wt-*/hooks/` and `.claude/wt-*/CLAUDE.md`; does not establish behaviour for worktrees stored outside a `.claude` path.
**Legibility-target:** for-orchestrator-synthesis

Same probe run: `deny   | cp x /workspace/.claude/wt-a/hooks/y` and `deny   | cp x /workspace/.claude/wt-a/CLAUDE.md`. The hooks case is caught by `SETTINGS_OR_HOOKS = re.compile(r"settings[\w.-]*\.json|\bhooks\b", re.I)` (`hooks/guard-trusted-writes.py:184`) together with `\.claude\b`.

**Evidence:** `hooks/guard-trusted-writes.py:184,200`, `$S/probe-bash2.out`

---

## Claim 6: c5a7c96 — the Bash tier denies every listed R1/A10 spelling (`"$HOME"/CLAUDE.md`, `~//CLAUDE.md`, `~/./CLAUDE.md`, `~/"CLAUDE.md"`, `${HOME:-}/CLAUDE.md`, `$HOME/x/../CLAUDE.md`, `~/.claude//CLAUDE.md`, `"$HOME/.claude"/CLAUDE.md`, `H=~; … $H/CLAUDE.md`, `cd ~/.claude && mv x CLAUDE.md`, `~/.claude//settings.json`, `~/".claude"/settings.json`, `cd ~/.claude && … > settings.json`)

**Location:** `hooks/guard-trusted-writes.py:190-206` (docstring `:29-38`; commit c5a7c96 body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exactly the 13 listed spellings, untainted, with CLAUDE_CONFIG_DIR unset; does not establish that no other spelling escapes (see Claim 7).
**Legibility-target:** for-orchestrator-synthesis

Executed `python3 $S/probe.py $S/cmds.txt` (cwd `$S`, HOME=temp dir, CLAUDE_CONFIG_DIR unset; 2026-09-21T20:24:32-07:00; exit 0). All 13 print `deny`. For example: `deny   | H=~; echo x > $H/CLAUDE.md` and `deny   | cd ~/.claude && echo {} > settings.json`. The repo's own bats suite also passes at HEAD (`bats test/hooks/guard-trusted-writes.bats`, exit 0, 54 ok).

**Evidence:** `hooks/guard-trusted-writes.py:171-206`, `$S/probe-bash.out`, `$S/bats-new.out`

---

## Claim 7: "R1 (Bash): the global CLAUDE.md tier no longer depends on exact path spellings … The residual: shell obfuscation of the file name itself (CLAUDE.m*, C${x}.md) and A8 primitives are still unguarded."

**Location:** commit c5a7c96 message (body, R1 paragraph and Notes). Code: `hooks/guard-trusted-writes.py:171-203`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the residual statement's completeness. It lists only filename obfuscation and A8, but whole other classes of spelling still escape. Does not cover the accepted filename-obfuscation residual itself or Q-048's false denies.
**Legibility-target:** for-author

The co-occurrence rule still depends on a literal indicator token. Anything that reaches home or the config dir without `~`, `$HOME`, `${HOME`, the literal home path, `.claude` or `CLAUDE_CONFIG_DIR` escapes. Same probe run, all ordinary write primitives:
```
defer  | echo x > /home/$USER/CLAUDE.md
defer  | cd; echo x > CLAUDE.md
defer  | cd && echo x > CLAUDE.md
defer  | echo x > ~/.clau*/settings.json
defer  | cd ~/.cl*e && echo {} > settings.json
defer  | cp y ~/.cl*/hooks/x.sh
defer  | D=.cl; echo x > ~/${D}aude/settings.json
defer  | cd ~/.cl""aude && echo {} > settings.json
defer  | echo x > ~/.clau""de/hooks/g.py
defer  | echo x > /opt/claude-workflows/hooks/g.py
```
Untainted, `defer` means no gate at all. `SOFT_FRAG` would still ask on the CLAUDE.md cases in a tainted session, but the settings/hooks cases match no fragment and get no gate even when tainted. The `.claude` cases obfuscate the *directory* name, not the file name, and `/home/$USER`, bare `cd`, and the `/opt` link target are not obfuscation at all. So the named residual understates what is unguarded. The installed `/opt` payload's writability was not checked; the commit's "installed /opt payload is unaffected" may rest on it being root-owned.

**Evidence:** `hooks/guard-trusted-writes.py:171-203`, `$S/cmds.txt`, `$S/probe-bash.out`

---

## Claim 8: "`config_dir()` … The ONE global config dir: exactly what the linker substitutes as {{CLAUDE_DIR}}. devcontainer-config/link-claude-home.sh uses DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}": an empty value falls back, `~` is NOT expanded, and there is no second dir. … A relative value is anchored at the hook's cwd"

**Location:** `hooks/guard-trusted-writes.py:63-74`
**Type:** Configuration / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unset, empty, absolute and `~`-literal cases against the linker; does not establish how Claude Code itself interprets a relative or `~`-bearing deny-rule path.
**Legibility-target:** for-author

The linker matches: `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`devcontainer-config/link-claude-home.sh:36`) is substituted verbatim with `jq --arg dir "$DEST" … gsub("\\{\\{CLAUDE_DIR\\}\\}"; $dir)` (`:133-137`). The hook matches it for unset, empty (falls back) and `~` (not expanded): `return Path(os.path.abspath(cfg)) if cfg else HOME / ".claude"` (`hooks/guard-trusted-writes.py:73-74`). Executed probe (`python3 $S/probe_file.py`, cwd `$S`, 2026-09-21T20:25:01-07:00, exit 0): `hard | cfg='' | ~/.claude/settings.json`, `soft | cfg=<home>/other | ~/.claude/settings.json`, `none | cfg='~/x' | ~/x/settings.json`. It is not *exactly* the linker for a relative value. The linker writes the relative string verbatim, so it is relative to wherever the deny rule is evaluated, while the hook anchors it at the hook process's cwd (`abspath`) and also normalises `..`/trailing `/`. "Exactly" holds for absolute, unset and empty values.

**Evidence:** `hooks/guard-trusted-writes.py:63-74`, `devcontainer-config/link-claude-home.sh:36,133-137`, `$S/probe-file.out`

---

## Claim 9: "HARD = exactly what permissions.deny covers (hooks/wiring.json): {{CLAUDE_DIR}}/hooks/**, {{CLAUDE_DIR}}/settings*.json, {{CLAUDE_DIR}}/CLAUDE.md, ~/CLAUDE.md"

**Location:** `hooks/guard-trusted-writes.py:10` (repeated in `_is_hard` docstring `:105-107`)
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the path set the hook calls HARD compared with the four deny globs; does not establish whether Claude Code's deny matcher resolves symlinks or matches case-insensitively. That determines whether the extra HARD paths are actually blocked.
**Legibility-target:** for-author

The four deny rules are `Edit/Write({{CLAUDE_DIR}}/settings*.json)`, `…/hooks/**`, `…/CLAUDE.md`, `(~/CLAUDE.md)` (`hooks/wiring.json:120-127`), and `_is_hard` names the same four shapes (`hooks/guard-trusted-writes.py:104-119`). HARD is a strict superset, though. It matches case-insensitively (`first = rel.parts[0].lower()`, `:110`), so the probe gives `hard | ~/.claude/SETTINGS.JSON`, while the deny glob `settings*.json` is presumably case-sensitive. It also calls resolved link targets HARD (`_HARD_FILE_TARGETS` / `_HARD_DIR_TARGETS`, `:86-93,133-134`), so the probe gives `hard | <B>/opt/hooks/g.py` and `hard | <B>/opt/CLAUDE.md`, which no deny glob names lexically. For these extras the hook defers (`main`, `:237-241`), so they are gated only if CC's deny matching resolves or case-folds. Neither case regressed: before c5a7c96, `/opt/...` returned `none` and `SETTINGS.JSON` returned soft. The precise statement is "HARD ⊇ permissions.deny coverage (adds case variants and resolved link targets)".

**Evidence:** `hooks/guard-trusted-writes.py:10,86-93,104-119,133-134,237-241`, `hooks/wiring.json:120-127`, `$S/probe-file.out`

---

## Claim 10: "managed-settings.json moves to SOFT for the file tools: no deny rule covers it, so deferring left it ungated."

**Location:** `hooks/guard-trusted-writes.py:21-24,135-142` (commit c5a7c96 R3)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file-tool tier for managed-settings.json (no deny rule; now asks when tainted) and the unchanged Bash HARD fragment; does not establish that ask-when-tainted is sufficient protection for that file.
**Legibility-target:** for-orchestrator-synthesis

No deny rule names it (`hooks/wiring.json:115-127`). At f023357 it was `if name in ("managed-settings.json",): return "hard"`, meaning defer with no gate. Now: `if name in ("claude.md", "agents.md", "claude.local.md", "managed-settings.json") … return "soft"` (`:139-141`). Probe: `soft | /etc/claude-code/managed-settings.json`, and bats `R3: managed-settings.json is SOFT for file tools` passes. Bash still has `HARD_FRAG … |managed-settings` (`:185`). This strengthens the gate: no path loses a gate it had.

**Evidence:** `hooks/guard-trusted-writes.py:135-142,185`, `hooks/wiring.json:115-127`, `$S/probe-file.out`, `$S/bats-new.out`

---

## Claim 11: "R4: file tools check the lexical path, its normpath and its resolve(); a resolve() that equals the resolved global CLAUDE.md / settings*.json or lies under the resolved global hooks dir is HARD. Fixes ask-on-HARD for ~/.claude/x/../CLAUDE.md, the installed symlink layout …, and a project .claude symlinked to ~/.claude."

**Location:** `hooks/guard-trusted-writes.py:121-134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers classify_path on the listed shapes in a fixture that mirrors the linker's hooks and CLAUDE.md symlinks; does not establish behaviour for `settings*.json` names created after the hook process starts (the glob runs at import, `:87-92`; the two canonical names are always added).
**Legibility-target:** for-orchestrator-synthesis

`cands = (p, norm, rp)`, then `for cand in cands: if _is_hard(cand): return "hard"`, then `if rp in _HARD_FILE_TARGETS or any(rp == d or d in rp.parents for d in _HARD_DIR_TARGETS): return "hard"` (`:128-134`). Probe (`$S/probe_file.py`, fixture with `~/.claude/hooks -> opt/hooks`, `~/.claude/CLAUDE.md -> opt/CLAUDE.md`, and `proj/.claude -> ~/.claude`): `hard` for `~/.claude/x/../CLAUDE.md`, `~/.claude/hooks/g.py`, `<B>/proj/.claude/settings.json` and `<B>/proj/.claude/hooks/g.py`. The four R4 bats tests pass at HEAD.

**Evidence:** `hooks/guard-trusted-writes.py:78-93,121-146`, `$S/probe-file.out`, `$S/bats-new.out`

---

## Claim 12: "Tests: 18 new bats cases (installed-layout fixture with symlinked hooks and CLAUDE.md); every new R-test fails against the pre-fix hook."

**Location:** commit c5a7c96 message (Tests paragraph). Tests at `test/hooks/guard-trusted-writes.bats:301-456`
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of new `@test` blocks and their pass/fail against `c5a7c96^:hooks/guard-trusted-writes.py`; does not assess whether the tests that pass pre-fix are valuable (three are intentional regression guards).
**Legibility-target:** for-author

`git diff f023357..HEAD -- test/hooks/guard-trusted-writes.bats | grep -c '^+@test'` gives **14**, not 18. The branch has no other commit touching that file. Executed: the HEAD bats file against the pre-fix hook copied to `$S/old/hooks/` (`cd $S/old && bats test/hooks/guard-trusted-writes.bats`, 2026-09-21T20:25:27-07:00, exit 1). Four new R-labelled tests **pass** pre-fix:
```
ok 39 R1: a heredoc whose prose names ~/.claude/CLAUDE.md is denied (accepted cost)
ok 40 R1: a bare CLAUDE.md with no home indicator stays SOFT
ok 43 R3: an empty CLAUDE_CONFIG_DIR falls back to ~/.claude, as the linker does
ok 49 R4: a real (non-symlinked) project .claude still asks when tainted
```
The other 10 fail pre-fix as claimed. This is an immutable commit message, so it gets an Accepted-immutable row if the branch is already merged. It is not merged yet, so it can still be reworded at squash time.

**Evidence:** `test/hooks/guard-trusted-writes.bats:301-456`, `$S/bats-old.out`, `$S/old/hooks/guard-trusted-writes.py`

---

## Claim 13: "~/.claude/hooks and ~/.claude/CLAUDE.md are symlinks into a payload dir, as link-claude-home.sh installs them from /opt/claude-workflows." (installed-layout fixture)

**Location:** `test/hooks/guard-trusted-writes.bats:401-413`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hooks and CLAUDE.md links and the real (non-link) settings.json; does not model the linker's other entries (skills, workflows, guides, patterns, scripts), which are irrelevant to the HARD set.
**Legibility-target:** for-orchestrator-synthesis

Fixture: `ln -s "$PAYLOAD/hooks" "$HOME/.claude/hooks"`, `ln -s "$PAYLOAD/CLAUDE.md" "$HOME/.claude/CLAUDE.md"`, `echo '{}' > "$HOME/.claude/settings.json"` (`:405-413`). Linker: `SRC="${CC_WORKFLOWS_DIR:-/opt/claude-workflows}"`, `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)`, `ln -sfn "$SRC/$name" "$target"`, and settings.json is a real merged file (`devcontainer-config/link-claude-home.sh:35,50,57,92`).

**Evidence:** `test/hooks/guard-trusted-writes.bats:401-413`, `devcontainer-config/link-claude-home.sh:35-60,92`

---

## Claim 14: "Writes never go through a symlink. … a planted symlink would otherwise turn `archive`, `index` or `init` into an append/overwrite/create of any file the user can write"

**Location:** `scripts/questions.sh:47-51`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers default-path writes (no escape outside the toplevel) and override-path writes; does not establish TOCTOU safety of ancestor directories between the check and `mv`.
**Legibility-target:** for-author

The security conclusion holds for the default paths, but the blanket "never" does not. `assert_write_target` checks only the file and its immediate directory (`[[ -L "$file" ]]`, `[[ -L "$dir" ]]`, `scripts/questions.sh:94-95`). For defaults it then requires `[[ "$resolved" == "$root"/* ]]` (`:96-101`), so a symlinked ancestor that points *inside* the repo is allowed through. For an explicit override, a symlinked grandparent is not checked at all. Executed (`bash $S/qs-probe.sh.txt`, 2026-09-21T20:26:28-07:00, exit 0), case 7: `QUESTIONS_LIVE=$R/lnk/sub/q.md` with `lnk -> outside7` printed `+ created: …/r7/lnk/sub/q.md` and the files landed in `outside7/sub`. The function comment at `:84-90` accurately says overrides are exempt from containment but not from "the symlink check". The header's "never" should read "never through a symlinked file or its directory, and a default path never resolves outside the toplevel".

**Evidence:** `scripts/questions.sh:47-51,84-110`, `$S/qs-probe.out`

---

## Claim 15: questions.sh refuses symlinked live/archive files or dirs (incl. dangling), and default paths that resolve outside the toplevel; init checks before `mkdir -p`

**Location:** `scripts/questions.sh:84-110,415-440`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a dangling-symlink live file, a symlinked `docs/working`, a symlinked `docs/` pointing outside, and a symlinked live file for `archive`; does not cover overrides (Claim 14) or races.
**Legibility-target:** for-orchestrator-synthesis

Same run (`$S/qs-probe.out`). Case 4 printed `refusing to write: …/docs/working/questions.md is a symlink` and the `outside4` target stayed empty. Case 6 printed `refusing to write: directory …/docs/working is a symlink`. Case 5 printed `… resolves to …/outside5/working/questions.md, outside …/r5`, and `outside5` stayed empty, which shows the check runs before `mkdir -p` (`assert_write_targets` at `:419`). Case 8 (`archive` with a symlinked live file) printed `is a symlink`, exit 1. Read-only commands (`check`, `next-id`, `open`) still follow the link, which the claim does not cover.

**Evidence:** `scripts/questions.sh:84-110,415-440`, `$S/qs-probe.out`

---

## Claim 16: "`replace_with` … temp file from mktemp in the target's own directory (O_EXCL …), takes the target's mode, and is renamed over the target only after the symlink checks pass again"

**Location:** `scripts/questions.sh:110-125`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mode preservation, the re-check before `mv`, and no leftover temp files after `index`; does not claim inode preservation (the inode changes by design).
**Legibility-target:** for-orchestrator-synthesis

`tmp="$(mktemp "$(dirname "$target")/.questions.XXXXXX")"`; `chmod --reference="$target" "$tmp"`; `if [[ -L "$target" || -L "$(dirname "$target")" ]]; then rm -f "$tmp"; die …`; `mv -f -- "$tmp" "$target"` (`:116-124`). Probe case 9: after `chmod 600`, `index` left mode `600`, the inode changed 404418→404424 (rename), and `ls -a` shows no `.questions.*` leftovers.

**Evidence:** `scripts/questions.sh:110-125`, `$S/qs-probe.out`

---

## Claim 17: "Re-check now the directory exists, then create with noclobber, whose O_EXCL open fails rather than following anything that appeared at the path in between."

**Location:** `scripts/questions.sh:428-437`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the order of operations (mkdir, re-check, noclobber create); does not establish the O_EXCL behaviour under a real race, which was not exercised.
**Legibility-target:** for-orchestrator-synthesis

`mkdir -p "$(dirname "$file")"`, then `assert_write_target "$file" "$override"`, then `( set -o noclobber; printf … > "$file" ) || die "could not create $file"` (`:427-437`). Paraphrased — no quote available because the claim is about bash internals, not repo code: with noclobber, bash opens a non-existent target with O_CREAT|O_EXCL, which fails on a symlink planted at the name. The override selection `override="${QUESTIONS_ARCHIVE:-}"; [[ "$file" == "$LIVE" ]] && override="${QUESTIONS_LIVE:-}"` (`:431-432`) matches the pair in `assert_write_targets` (`:105-108`).

**Evidence:** `scripts/questions.sh:105-108,415-440`

---

## Claim 18: "Every command except `init` needs both files to exist and fails, pointing at `init`" and the `.git` refusal ("Inside .git/ there is no toplevel, so the $PWD fallback below would create .git/docs/working/") (A3/A11)

**Location:** `scripts/questions.sh:42-45,73-78,128-134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers next-id, index, archive, open and check on a fresh repo with no docs, plus `init` run from inside `.git`; does not cover `check` with only one file missing.
**Legibility-target:** for-orchestrator-synthesis

Probe case 1: each of `next-id`, `index`, `archive` and `open` printed both `✗ missing:` lines and `no questions doc here — run \`~/.claude/scripts/questions.sh init\` first`, `[exit=1]`. `check` did the same through its own `rc=1` path (`:233`). Case 2: from `$R/.git`, it printed `is inside a .git directory; run from the working tree instead`, `[exit=1]`, and `.git/docs` does not exist.

**Evidence:** `scripts/questions.sh:73-78,128-134,229-300,390-410`, `$S/qs-probe.out`

---

## Claim 19: "First column only: a summary may itself mention another entry's ID." (42bf2fc)

**Location:** `scripts/questions.sh:289-290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers index rows rendered by `render_index` (`| [Q-NNN](…) |`) with a summary that mentions another ID, and a missing row; does not cover hand-edited rows in other formats.
**Legibility-target:** for-orchestrator-synthesis

`grep -ao '^| \[Q-[0-9]\{3\}\]' | grep -ao 'Q-[0-9]\{3\}'` (`:290`) matches the renderer's `printf '| [%s](#%s--%s) | …'` (`render_index`). Probe case 10 checked three states. An entry whose summary says "See Q-777" gives `✓ … indexes current`. The same row with the summary rewritten to "mentions Q-002" gives `✓`. With the row deleted, it gives `✗ questions.md: index is stale`, exit 1.

**Evidence:** `scripts/questions.sh:289-296,305-340`, `$S/qs-probe.out`

---

## Claim 20: "True no-op (the file is not opened for writing) when the header already has a Run cell or no header is found. A real migration rewrites the file in place (temp file, then `cat tmp > file`), so the log keeps its inode and mode" and "the mode and no-header tests fail on the pre-fix code" (R5)

**Location:** `scripts/lib/si-functions.sh:558-589` (commit 685030e)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three detection states, inode/mode/mtime preservation, temp cleanup, and pre-fix failure of the named tests; does not cover the detection awk failing (Claim 21).
**Legibility-target:** for-orchestrator-synthesis

`END { if (!hdr) exit 2; exit !found }' "$log_file" || state=$?` then `[ "$state" -eq 1 ] || return 0` (`:572-574`). The write step is `… > "$tmp" && cat "$tmp" > "$log_file" || rc=$?; rm -f "$tmp"; return "$rc"` (`:586-588`). Executed at HEAD: `bats test/append-approved-hypotheses.bats` (2026-09-21T20:26:48-07:00, exit 0) shows `ok 16 migration preserves the log's file mode and inode`, `ok 17 … already has a Run cell`, `ok 18 … no header row is found`. The same tests against `685030e^:scripts/lib/si-functions.sh` (`$S/old5`, 2026-09-21T20:30:07-07:00, exit 1) gave `not ok 2 … mode and inode`, `ok 3 … Run cell`, `not ok 4 … no header row`. That matches the claim: the mode and no-header tests fail pre-fix, and the has-Run test was never claimed to.

**Evidence:** `scripts/lib/si-functions.sh:558-589`, `test/append-approved-hypotheses.bats:155-186`, `$S/bats-append.out`, `$S/bats-old5.out`

---

## Claim 21: "Awk failure now propagates as the return code instead of being swallowed."

**Location:** commit 685030e message. Code `scripts/lib/si-functions.sh:572-588`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rewrite awk (whose failure does propagate) and the detection awk (whose failure does not); does not establish whether any caller checks the return code.
**Legibility-target:** for-author

It is true for the rewrite awk (`|| rc=$?`, `:586`). The detection awk's own failure exit (awk returns 2 on an unreadable file) collides with the "no header" sentinel `exit 2`, so `[ "$state" -eq 1 ] || return 0` swallows it. Executed (`bash $S/si-probe.sh.txt`, uid 1000, 2026-09-21T20:31:23-07:00, exit 0) on a `chmod 000` log: `awk: cannot open … (Permission denied)`, then `unreadable log -> rc=0`. Precise version: "the rewrite step's awk failure propagates; a detection failure is treated as no-op".

**Evidence:** `scripts/lib/si-functions.sh:572-588`, `$S/si-probe.out`

---

## Claim 22: "Date plus time of day (YYYY-MM-DD-HHMMSS) … Zero-padded fields keep ids lexically sortable in start order, which _archived_newest_first relies on." / "Run (Q-047) is the self-improvement run's id (si_default_run_id below, or SI_RUN_ID)"

**Location:** `scripts/lib/si-functions.sh:461-470,481`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the id format, the charset, uniqueness within a day, and lexical ordering among new-format ids; does not cover ordering between a legacy date-only id and a timed id on the same day.
**Legibility-target:** for-author

`si_default_run_id() { date +%F-%H%M%S; }` (`:469-471`). The bats tests `si_default_run_id is date plus time of day…` and `…differs for two runs started on the same day` pass (`$S/bats-append.out`). `_archived_newest_first` reverses glob order (`for f in "$archive_dir"/*"$name"` … `for (( i = ${#matches[@]} - 1; …`, `si-morning-summary.sh:1132-1143`), so lexical order matters, and zero-padding gives it. The cross-reference at `:481` says "si_default_run_id **below**", but the function is defined *above* it (`:469` vs `:481`). Separately, a same-day legacy `YYYY-MM-DD-` prefix sorts after `YYYY-MM-DD-HHMMSS-` in the C locale (`t` > digits), so in that one mixed case the older run reads as newest. That is a transition edge case, not a claim error.

**Evidence:** `scripts/lib/si-functions.sh:461-471,481`, `scripts/lib/si-morning-summary.sh:1132-1143`, `$S/bats-append.out`

---

## Claim 23: "_live_run_matches … When si-run-id.txt is absent or empty … this is false; callers still reach the live files through their newest-first fallback, just not ahead of the row's own archived copy." and "_valid_run_id … Callers treat an invalid id as absent" (A6b/A6c)

**Location:** `scripts/lib/si-morning-summary.sh:1145-1175`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_live_run_matches` semantics, the candidate order in `_find_tasks_file` and `_days_since_round`, and `_valid_run_id` at all three entry points (row reader `:1018`, `_find_tasks_file` `:1189`, `_days_since_round` `:1350`); does not cover `..`-only ids beyond the observation that they stay inside archive/.
**Legibility-target:** for-orchestrator-synthesis

`[ -f "$working_dir/si-run-id.txt" ] || return 1` … `[ -n "$live" ] && [ "$live" = "$run" ]` (`:1170-1173`). In `_find_tasks_file` the candidates are `archive/${run}-tasks-round-$round.json`, then live (if it matches), then `printf '%s\n' "$working_dir/tasks-round-$round.json"` unconditionally, then archived newest-first (`:1199-1204`). So live is still reached, just after the run's own copy. `_days_since_round` falls back to `rounds/…` and the live report ahead of the archives (`:1379-1385`). These are the only `_live_run_matches` callers, and both validate `run` first. The new tests in `test/precondition-gate.bats` and `test/morning-summary-clusters.bats` pass (`bats … `, 2026-09-21T20:27:22-07:00, exit 0, 102 ok, 0 not ok).

**Evidence:** `scripts/lib/si-morning-summary.sh:1015-1031,1145-1206,1347-1395`, `$S/bats-misc.out`

---

## Claim 24: "`\|` is swapped for a sentinel before the split and restored afterwards, so the cell keeps its escaped (markdown-safe) text." / "Locals carry a _srf_ prefix so they cannot shadow the caller's array name through the nameref"

**Location:** `scripts/lib/si-morning-summary.sh:1515-1538`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the escaped-pipe split and the `_srf_` locals; does not cover rows whose non-hypothesis cells contain raw `|` (the writer escapes only `hyp`, `si-functions.sh:548`).
**Legibility-target:** for-author

The sentinel split works. Executed (`$S/si-probe.sh.txt`): `f=(); _split_row_fields '| a | b \| c | d |' f` gives `f n=4 :: b \| c`, and the new bats test passes. The nameref itself is not prefixed: `local -n out_ref="$2"` (`:1524`). A caller array named `out_ref` triggers `local: warning: out_ref: circular name reference` (7 warnings on stderr) even though the fields still come back. Precise version: "cannot shadow any caller name except `out_ref`".

**Evidence:** `scripts/lib/si-morning-summary.sh:1515-1538`, `scripts/lib/si-functions.sh:548`, `$S/si-probe.out`

---

## Claim 25: A1 — "give 'qualifying author note' a real anchor": `### Qualifying author note` … "this heading is the linkable copy, since headings inside the template's code fence get no anchor"; pr-prep and review-fix-loop link `rubric.md#qualifying-author-note`

**Location:** `skills/code-review/references/rubric.md:156-175`, `workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the anchor's existence outside the fence and the two workflow links; the residue is the in-template link at `:156`.
**Legibility-target:** for-author

The template fence runs `:31` (```` ```markdown ````) to `:157` (```` ``` ````), and the new heading is at `:159`, outside it, so `#qualifying-author-note` resolves for both workflow links. No `rubric.md#-must-address` links remain outside `docs/`. The template's 🟡 heading does repeat the definition (`:49-58`). But the template line itself was changed to `carry a [qualifying author note](#qualifying-author-note).` (`:156`), which is *inside* the fence. It is copied into every emitted `code-review-rubric-*.md`, and those files have no such heading, so the link there is dead. It needs a path such as `../../skills/code-review/references/rubric.md#qualifying-author-note`, or plain text.

**Evidence:** `skills/code-review/references/rubric.md:31,49-58,156-175`, `workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`

---

## Claim 26: A2/A13 — test-strategy mapped "by its real high/medium/low scale" everywhere it was repeated; hot-path gate and the Macro × Cold row agree

**Location:** `skills/code-review/references/rubric.md:307-308,357,521`, `skills/code-review/SKILL.md:1230`, `skills/performance-reviewer/SKILL.md:46,283`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every test-strategy tier mention in skills/, workflows/, patterns/, guides/ and docs/decisions/, and the two perf texts; does not cover historical review artifacts in docs/reviews/.
**Legibility-target:** for-orchestrator-synthesis

test-strategy emits `**Priority:** [high / medium / low]` (`skills/test-strategy/SKILL.md:196`). The mapping rows are `| 🟡 Must Address | Major | high | any confirmed finding |` and `| 🟢 Consider | Minor and below | medium, low | — |` (`rubric.md:307-308`), and `grep -rn "test-strategy P[12]\|P1→\|P2 and below"` over those dirs returns nothing. `bats test/skills/code-review-executable-defect.bats` passes (2026-09-21T20:30:23-07:00, exit 0, 10 ok), and it now asserts no `test-strategy P[12]` survives. For performance-reviewer, the gate ends `or runs over large data (e.g. a nightly batch over a full table), in which case escalate as for a hot path` (`:46`) and the row reads `Low (same exceptions as the hot-path gate: … runs over large data, e.g. a nightly batch)` (`:283`). The two texts agree.

**Evidence:** `skills/test-strategy/SKILL.md:196`, `skills/code-review/references/rubric.md:307-308,357,521`, `skills/performance-reviewer/SKILL.md:46,283`, `$S/bats-ed.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 5a** (`docs/working/questions.md:38`): Q-048 says settings/hooks writes are denied with `~`/`$HOME` anywhere and that `git commit … HEAD~1` is denied. In fact settings/hooks need `.claude` or the config dir, and nothing is denied without a write primitive (`git commit -m` is not one). Reword before the user answers Q-048.
- **Claim 7** (commit c5a7c96, R1/Notes; `hooks/guard-trusted-writes.py:171-203`): the stated residual (filename obfuscation plus A8) is incomplete. `/home/$USER/CLAUDE.md`, a bare `cd;`/`cd &&` before `> CLAUDE.md`, `~/.cl*`/`~/.cl""aude`/`${D}aude` spellings of `.claude` for settings/hooks (ungated even when tainted), and `/opt/claude-workflows/hooks/…` all return no opinion.
- **Claim 12** (commit c5a7c96, Tests): 14 new `@test` blocks, not 18. Four of them (R1 heredoc, R1 bare-SOFT, R3 empty-config-dir, R4 real-project-.claude) pass against the pre-fix hook, so "every new R-test fails against the pre-fix hook" is false.

### Stale
- **Claim 2** (`docs/reviews/override-log.md:82`): the `hooks/guard-trusted-writes.py:56-132` pointer and "now matches only literal spellings / live defects are R1/R4" describe the pre-c5a7c96 file. Pin the reference to `4c7a2bb:` and use past tense.

### Mostly Accurate
- **Claim 4** (`docs/working/questions-archive.md:833`; bd07c4e): the cache mechanism is verified, but the file took 60s here, not 42s. State it as a range.
- **Claim 8** (`hooks/guard-trusted-writes.py:63-74`): "exactly what the linker substitutes" does not hold for a relative CLAUDE_CONFIG_DIR (the hook uses `abspath` at its cwd; the linker substitutes the string verbatim).
- **Claim 9** (`hooks/guard-trusted-writes.py:10,105`): HARD is a superset of the deny coverage (case-insensitive names, resolved `/opt` link targets). Say ⊇, and note these extras rely on CC's deny matching.
- **Claim 14** (`scripts/questions.sh:47`): "Writes never go through a symlink" is broader than the code. Only the file and its immediate dir are checked; overrides with a symlinked grandparent write through it.
- **Claim 21** (commit 685030e): a detection-awk failure is still swallowed (exit 2 equals the no-header sentinel, so it returns 0).
- **Claim 22** (`scripts/lib/si-functions.sh:481`): "si_default_run_id below" should be "above" (defined at `:469`).
- **Claim 24** (`scripts/lib/si-morning-summary.sh:1522`): the nameref `out_ref` is unprefixed, so a caller array named `out_ref` still collides (circular-reference warnings).
- **Claim 25** (`skills/code-review/references/rubric.md:156`): the new `#qualifying-author-note` link sits inside the template fence and is dead in every emitted rubric file. The outside links resolve.

### Unverifiable
- None. The CC deny-matcher semantics behind Claim 9 are noted in its Scope.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/docs/reviews/code-fact-check-report-iter2-r1.md with `**Commit:** 16f2978` at the top, every claim tagged with a Legibility-target (Incorrect/Stale/Mostly Accurate → for-author; Verified/Unverifiable → for-orchestrator-synthesis), ending with a Goal-Alignment Note.
- Answered: brief items 1–11. All 13 listed R1/A10 spellings deny (executed), and the other spellings that escape are listed. config_dir vs linker, HARD vs deny, and managed-settings (no regression) are covered. R4 was checked on an installed-layout fixture, and the "every new R-test fails" claim was refuted by running the tests against the pre-fix hook. questions.sh symlink, containment, missing-file, `.git` and index-column behaviour were all probed hermetically. R5 is a true no-op and keeps inode and mode, with pre-fix failures confirmed. Also checked: run-id format, `_live_run_matches` / `_valid_run_id` sites, the RS-sentinel split, the health-check cache (timed), and the A1/A2/A5/A13 docs.
- Out of scope: commits before f023357 (context only). Q-048's accepted false denies and the A7/A8 Defer rows were not re-flagged as findings; only Q-048's *description* was fact-checked. Claude Code's own deny-matching semantics were not tested (they would need the real CLI). The `/opt/claude-workflows` writability in a real container was not tested.
- Escalate: Claim 7 (ungated Bash spellings of `.claude` for settings/hooks, `/home/$USER`, bare `cd`) is a security-relevant residual that neither the commit nor Q-048 names. It should reach the security critic and the synthesis. Claim 5a should be fixed before the user answers Q-048, because the options table rests on the misdescription.
