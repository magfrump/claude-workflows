Commit: 31f53e8

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch `answers-2026-09-20`
**Scope:** `git diff 2d93589..answers-2026-09-20` (818c568, a577546, 739cbbb, fd0ad24 merge, b951c4f, 31f53e8): hooks/guard-trusted-writes.py, test/hooks/guard-trusted-writes.bats, scripts/lib/si-functions.sh, scripts/lib/si-morning-summary.sh, scripts/archive-working-docs.sh, scripts/questions.sh, skills/code-review/references/rubric.md, docs/working/questions.md, docs/working/questions-archive.md, docs/reviews/override-log.md, plus the commit messages. Iteration-3 replicate r1.
**Checked:** 2026-09-21
**Total claims checked:** 30
**Summary:** 20 verified, 5 mostly accurate, 0 stale, 3 incorrect, 2 unverifiable

Execution provenance: every executed claim below was run from cwd `/workspace` (unless noted) in the review sandbox between 2026-09-21T21:14:48-07:00 and 21:22:30-07:00. The scripts and captured output are in the session scratchpad `S=/tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad` (untracked; the brief forbids touching other tracked paths). Hook probes use a fake HOME and a scratch `CC_WEB_TAINT_DIR`, with `CLAUDE_CONFIG_DIR` explicitly unset or set per probe, against the repo copy `/workspace/hooks/guard-trusted-writes.py`. Hallucination-pattern log read; no claim below matches a logged pattern.

---

## Claim 1: "Discoverable TODO: `# TODO(N2)` block beside the Bash indicators (a577546) lists each shape … Revisit trigger: the next change to the Bash tiers, or Q-048's answer." (and the N3 and A6 Defer rows)

**Location:** `docs/reviews/override-log.md:80-82`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three Defer rows meeting the rubric's "qualifying author note" rule: the cited TODO exists, the Q-049 entry exists, and each row names a concrete trigger. Does not establish that the TODO(N2) list is complete or exact (see Claim 12), or that the A6 row's "tested" covers each of the three regex copies directly.

The TODO block exists where cited:

```python
# hooks/guard-trusted-writes.py:172-174
# TODO(N2): command TEXT that writes a global policy file but carries no
# indicator token the co-occurrence rules below look for, so it gets no
# opinion (pre-existing; code-review 2026-09-21 iteration 2, N2):
```

The rubric rule accepts "(a) A discoverable TODO … or a tracked follow-up entry (issue, `docs/working/questions.md` entry …)" or "(b) A concrete revisit trigger" (`skills/code-review/references/rubric.md:165-171`). N2 cites the TODO and a trigger; N3 cites Q-049 (`docs/working/questions.md:36`) and "Revisit trigger: Q-049's answer"; A6 cites "any change to the run-id format, or a fourth reader of the Run cell". The three regex copies are identical: `^[A-Za-z0-9._-]+$` at `scripts/self-improvement.sh:460`, `scripts/archive-working-docs.sh:45,52`, `scripts/lib/si-morning-summary.sh:1162`. The commits cited exist (`14bfbdd fix(si): default run id is unique per run…`, `efd66e4 fix(si): validate the Run cell…`).

**Evidence:** `docs/reviews/override-log.md:80-82`, `hooks/guard-trusted-writes.py:172-184`, `skills/code-review/references/rubric.md:159-174`, `docs/working/questions.md:36`, `scripts/self-improvement.sh:460`, `scripts/archive-working-docs.sh:45,52`, `scripts/lib/si-morning-summary.sh:1161-1162`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "Refuted at `hooks/guard-trusted-writes.py:56-132` as of `4c7a2bb` … The defects it hid were R1/R4 … fixed in `c5a7c96`." (N7)

**Location:** `docs/reviews/override-log.md:87`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the N7 edit: the code reference is now pinned to a commit and put in the past tense, and it names the fixing commit. Does not re-verify the original 4c7a2bb refutation (settled in iterations 1–2).

The row now reads "Refuted at `hooks/guard-trusted-writes.py:56-132` as of `4c7a2bb`" and "The defects it hid were R1/R4 … fixed in `c5a7c96`" (`docs/reviews/override-log.md:87`). That is the change iter2 N7 asked for ("Pin the reference to `4c7a2bb:` and put the sentence in the past tense", iter2 rubric `:78`).

**Evidence:** `docs/reviews/override-log.md:87`, `docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20-iter2.md:78`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "that file takes 42–60s depending on load and slow ~80–100s … Full health check measured 216s on the merged tip." (N10)

**Location:** `docs/working/questions-archive.md:833`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the `health-check.bats` and `run-tests.sh --slow` wall-clock ranges, re-measured once each at HEAD under this sandbox's current load. Does not re-measure the 216 s full health check (a historical measurement on "the merged tip"), and one sample per range cannot establish the range's bounds.

Measured `health-check.bats exit=0 wall=56s` (inside 42–60) and `run-tests --slow exit=0 wall=96s` (inside 80–100). Commands: `bats test/scripts/health-check.bats`, then `bash scripts/run-tests.sh --slow`, cwd `/workspace`, started 2026-09-21T21:20:51-07:00, both exit 0, timed with `date +%s` deltas (no `/usr/bin/time` in the sandbox).

**Evidence:** `docs/working/questions-archive.md:833`; captured `$S/iter3-r1-timing.log`, `$S/iter3-r1-hcbats.log`, `$S/iter3-r1-slow.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: Q-049 entry follows the running-questions grammar (you: terminal → one copy-pasteable block plus an interim line) and `questions.sh check` passes

**Location:** `docs/working/questions.md:36-55`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers structure: heading, the Needs/Opened/Status line, one fenced paste, an Interim line, the index row, and `scripts/questions.sh check` passing on the live file. Does not establish that the paste measures what it claims (Claim 5).

The entry has `### Q-049 · deny-rule-absolute-path-form`, `**Needs:** you: terminal · **Opened:** 2026-09-21 · **Status:** OPEN` (`:36-37`), a single ```` ```bash ```` block (`:44-51`), and `- **Interim:** unchanged. …` (`:55`). The index row is at `:31`. `bash scripts/questions.sh check` (cwd `/workspace`, 2026-09-21T21:19:48-07:00) printed `✓ questions: structure valid, indexes current` and exited `rc=0`.

**Evidence:** `docs/working/questions.md:31,36-55`; captured `$S/iter3-r1-qs.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: The Q-049 paste "reports whether the file appeared", and "if single-slash is enforced, N3 is closed as a non-issue"

**Location:** `docs/working/questions.md:42-54`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the paste's decision logic: which outcomes print "enforced". Does not establish Claude Code's actual deny-path semantics (the sandbox has no egress and no `claude` session to run it against), or whether a trusted-folder prompt or an outside-cwd write prompt would fire in `-p` mode.

The paste's verdict is only whether the file exists afterwards:

```bash
# docs/working/questions.md:48-49
  (cd "$d" && claude -p "Use the Write tool to create the file $t containing: hi" --output-format json >/dev/null 2>&1)
  [ -e "$t" ] && echo "$form-slash rule: NOT enforced (file written)" || echo "$form-slash rule: enforced"
```

(excerpt ends :49; the enclosing `for` loop closes at :50 with `done`, and the fence closes at :51 — read.) The run's JSON and stderr go to `/dev/null`, and there is no control run without the deny rule. So "enforced" is printed whenever the write simply did not happen, whatever the reason: a "Not logged in" exit-0 run (the user's own memory note: judge headless runs by JSON `num_turns`, not exit code), the model declining or using a different tool, a permission prompt that `-p` cannot answer (`$t` is in a second `mktemp -d` directory outside the cwd `$d`), or a rate-limit error (paraphrased — no quote available because these failure modes are Claude Code runtime behaviour, not repo code). The "What I do with it" line then closes N3 as a non-issue on exactly that output ("if single-slash is enforced, N3 is closed as a non-issue", `:54`). A false "enforced" would close a security finding without evidence. The precise version needs a positive control (the same call with no deny rule must print "NOT enforced") and should keep the JSON so `num_turns`/`is_error` can be checked.

**Evidence:** `docs/working/questions.md:42-54`

**Legibility-target:** for-author

---

## Claim 6: "`link-claude-home.sh` writes them as `Edit(/home/node/.claude/settings*.json)` … `devcontainer-config/link-claude-home.sh:137` (the `{{CLAUDE_DIR}}` substitution)"

**Location:** `docs/working/questions.md:40-42`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited line and the substituted form when `DEST=/home/node/.claude`. Does not establish how Claude Code interprets a single leading `/` (the open question itself).

```bash
# devcontainer-config/link-claude-home.sh:36
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
# devcontainer-config/link-claude-home.sh:133,137
    if jq --arg dir "$DEST" --slurpfile w "$WIRING" '
                  then gsub("\\{\\{CLAUDE_DIR\\}\\}"; $dir)
```

(excerpt ends :137; the enclosing jq program continues to :157 and the `if` to :164 — read.) With the rule `"Edit({{CLAUDE_DIR}}/settings*.json)"` (`hooks/wiring.json:120`), that yields `Edit(/home/node/.claude/settings*.json)`.

**Evidence:** `devcontainer-config/link-claude-home.sh:36,133-164`, `hooks/wiring.json:120-127`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: Q-048: "If the command names `CLAUDE.md`, it is denied when it also contains … `~`, `$HOME`/`${HOME…}`, the home path, `.claude`, `global-instructions` or the config dir. If it names `settings*.json` or `hooks`, it is denied when it also contains `.claude` or the config dir. False denies: a heredoc … `CLAUDE.md` next to `HEAD~1`, and any Bash write into an agent worktree's `hooks/`" (N6)

**Location:** `docs/working/questions.md:60`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the write-gate, the CLAUDE.md rule, the settings/hooks rule and both false-deny examples, probed through `bash_targets`. Does not establish anything about the HARD_FRAG branch's other triggers beyond what is listed.

Probed via `python3 $S/iter3-r1-n2.py.txt` (2026-09-21T21:17:37, exit 0): `cat > msg.txt <<E … CLAUDE.md HEAD~1 …` -> `hard`; `echo x > /workspace/.claude/wt-a/hooks/x.sh` -> `hard`; `echo x > settings.json # ~` -> `None`; `echo x > settings.json # CLAUDE_CONFIG_DIR` -> `hard`; `git commit -m 'CLAUDE.md HEAD~1'` -> `None` (no write primitive). This matches the text, including the N6 corrections: write-only, and `~` does not count for settings/hooks. The code's rule list is slightly wider than the text:

```python
# hooks/guard-trusted-writes.py:206-207,210,220
_HOME_INDICATORS = [r"~", r"\$HOME\b", r"\$\{[!#]?HOME\b", r"\.claude\b",
                    r"global-instructions", r"CLAUDE_CONFIG_DIR"]
_CFG_INDICATORS = [r"\.claude\b", r"CLAUDE_CONFIG_DIR"]
HARD_FRAG = re.compile(r"\.claude/hooks(/|\b)|\.claude/settings|managed-settings", re.I)
```

The literal token `CLAUDE_CONFIG_DIR` also triggers both rules. The text's "the config dir" can be read as the path only. Any write that mentions `managed-settings` is HARD on its own, and the text does not mention that. The precise version adds "`CLAUDE_CONFIG_DIR` (the variable name)" and "any write naming `managed-settings`".

**Evidence:** `docs/working/questions.md:60`, `hooks/guard-trusted-writes.py:206-240`; captured `$S/iter3-r1-n2.log`

**Legibility-target:** for-author

---

## Claim 8: "Matching is case-sensitive, like the deny rules and like Linux paths: ~/.claude/HOOKS/x is not the hooks dir (it falls to SOFT)" / commit: "Case variants route to SOFT (ask when tainted, defer otherwise)"

**Location:** `hooks/guard-trusted-writes.py:14-15,118-120` (and a577546 message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers case-sensitive HARD matching and the SOFT routing of `HOOKS/`, `SETTINGS.JSON`, `Settings.json`, `claude.md` under the config dir and `~/claude.md` on a case-sensitive filesystem. Does not establish that Claude Code's deny matcher is case-sensitive. On a case-insensitive filesystem (macOS bare host, WSL `/mnt/c`), `~/.claude/SETTINGS.JSON` IS the live settings.json, and there an untainted Write defers with no gate if the deny matcher is case-sensitive. That is unchanged from the pre-fix HARD→defer, and the docstring scopes itself to "Linux paths".

```python
# hooks/guard-trusted-writes.py:121-132
    rel = _rel_under(cand, dirs)
    if rel is not None and rel.parts:
        first = rel.parts[0]
        if first == "hooks":
            return True
        if len(rel.parts) == 1 and first.startswith("settings") and first.endswith(".json"):
            return True
        if len(rel.parts) == 1 and first == "CLAUDE.md":
            return True
    if cand.name == "CLAUDE.md" and cand.parent == HOME:
        return True
    return False
```

Probe `bash $S/iter3-r1-probe.sh.txt` (21:16:50, exit 0), Layout A: `SETTINGS.JSON`, `HOOKS/x`, `claude.md`, `~/claude.md` -> `defer` when clean and `ask` when tainted. The bats N1 case-variant test passes (Claim 16).

**Evidence:** `hooks/guard-trusted-writes.py:113-132,159-169`; captured `$S/iter3-r1-probe.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9a: "resolved = the path is HARD only after resolve() (or only under the config dir's resolved form) … the hook returns "deny" itself" / commit: "-> the hook returns "deny" itself, tainted or not. Never "ask""

**Location:** `hooks/guard-trusted-writes.py:22-27,149-155,279-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every "hard-resolved" route: the payload by its real path (including `x/../`), a project `.claude` symlinked to the config dir (bats), a config dir that is itself a symlink addressed by its target, and a symlinked HOME addressed by its target. Each denies clean and tainted, and no HARD route returns ask. Does not establish that this is free of false positives (Claim 9c).

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
```

(excerpt ends :155; `classify_path` continues through the SOFT loop to `return "none"` at :169 — read.) Probe results: `optA/claude-workflows/CLAUDE.md`, `…/hooks/foo.sh`, `…/x/../CLAUDE.md` -> `deny` clean and tainted. Layout D (`CLAUDE_CONFIG_DIR` a symlink): `cfgreal/settings.json` -> `deny` clean and tainted, and `cfglink/settings.json` -> `defer`. Layout C (HOME a symlink): `realhomeC/.claude/settings.json` and `realhomeC/CLAUDE.md` -> `deny`. `main()` maps `"hard-resolved"` to `emit("deny", …)` with no taint condition (`:279-285`).

**Evidence:** `hooks/guard-trusted-writes.py:134-169,270-289`; captured `$S/iter3-r1-probe.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9b: "covered = the path AS GIVEN (lexical, or normpath with `..` folded) names a HARD entry under the config dir as the deny rules spell it. A deny rule names that string, so the hook DEFERS to it."

**Location:** `hooks/guard-trusted-writes.py:19-21,145-148`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what the hook does: it defers on `~/.claude/x/../settings.json`, `~/.claude//settings.json`, `settings.foo.json` and the `hooks` dir itself, clean and tainted. Does not establish the "a deny rule names that string" half for the normpath-folded and `//` spellings. That needs Claude Code's deny matcher, which the sandbox cannot run. The commit Notes disclose it ("Whether Claude Code's deny matcher folds `..` … is unverified"), and it is N3-adjacent. Noted, not re-raised.

Probe Layout A: `…/.claude/x/../settings.json`, `…/.claude//settings.json` -> `defer` both clean and tainted. For the unnormalised string, whether `Write(/…/.claude/settings*.json)` matches `/…/.claude/x/../settings.json` depends on Claude Code normalising before matching (paraphrased — no quote available because the matcher is Claude Code internals, not repo code). The `MultiEdit` deferral (`MultiEdit …/.claude/settings.json` -> `defer`) relies on the `Edit(...)` deny rules also covering MultiEdit. That is pre-existing, and it is unverifiable here too.

**Evidence:** `hooks/guard-trusted-writes.py:137-148,275-278`, `hooks/wiring.json:120-127`; captured `$S/iter3-r1-probe.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9c: The resolved-tier examples ("e.g. the payload CLAUDE.md addressed by its real /opt path … or a project .claude symlinked to ~/.claude") describe what the new deny catches, with no stated effect on normal editing

**Location:** `hooks/guard-trusted-writes.py:22-27` (and a577546 message)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the README bare-host layout (`~/.claude/CLAUDE.md -> ~/claude-workflows/global-instructions/CLAUDE.md`; `~/.claude/hooks` a real dir with per-file symlinks), before and after a577546. Does not establish how common that install is, or whether the deny is the intended policy there. The Bash tier already treats `global-instructions` + CLAUDE.md + a write as HARD (`:206-207`), so the new deny may be consistent with intent, but neither the docstring nor the commit says so.

The README's bare-host setup links the global instructions into the checkout:

```bash
# README.md:14
ln -s ~/claude-workflows/global-instructions/CLAUDE.md ~/.claude/CLAUDE.md
```

So `_HARD_FILE_TARGETS` (`resolve(CONFIG_DIR / "CLAUDE.md")`, `:95`) is the repo's own `global-instructions/CLAUDE.md`. Probe `bash $S/iter3-r1-prefix.sh.txt` (21:17:14, exit 0), Edit of `homeB/claude-workflows/global-instructions/CLAUDE.md`, untainted: pre-fix hook (`a577546^`) -> `rc=0` (defer, allowed); current hook -> `"permissionDecision": "deny"`. The same holds tainted (`$S/iter3-r1-probe.log` Layout B). So on a README-style bare host, every file-tool edit of the repo's global instructions is now refused, even in a clean session, and the refusal points at a path that is also denied (Claim 13). Repo `hooks/*.py` edits are not affected there (`claude-workflows/hooks/log-usage.sh` and `…/guard-trusted-writes.py` -> `defer`), because `~/.claude/hooks` is a real directory. In this devcontainer, `/workspace/global-instructions/CLAUDE.md` -> defer (`$S/iter3-r1-live.log`), because the link targets `/opt`. The precise docstring and commit would add "on a bare host whose ~/.claude/CLAUDE.md links into a checkout, edits to that checkout file are denied".

**Evidence:** `hooks/guard-trusted-writes.py:95,154-155,279-285`, `README.md:11-37`, `guides/bare-host-hook-wiring.md:1-30`; captured `$S/iter3-r1-prefix-compare.log`, `$S/iter3-r1-probe.log`, `$S/iter3-r1-live.log`

**Legibility-target:** for-author

---

## Claim 10: "This matches the linker for an unset, empty or absolute value. It DIFFERS for a relative value … this hook anchors it at the hook's own cwd with abspath()"

**Location:** `hooks/guard-trusted-writes.py:76-79`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unset/absolute cases and one relative value (`.cfg`, cwd `/workspace`) against the code and the linker line. Does not establish how Claude Code resolves a relative deny-rule path.

```python
# hooks/guard-trusted-writes.py:81-82
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    return Path(os.path.abspath(cfg)) if cfg else HOME / ".claude"
```

Linker: `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`devcontainer-config/link-claude-home.sh:36`). An empty value is falsy in Python, so it falls back as `:-` does. Probe Layout D2: with `CLAUDE_CONFIG_DIR=.cfg`, `/workspace/.cfg/settings.json` -> `defer` (HARD). That is anchored at cwd.

**Evidence:** `hooks/guard-trusted-writes.py:70-82`, `devcontainer-config/link-claude-home.sh:36`; captured `$S/iter3-r1-probe.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "Case-folded on purpose: SOFT only ever asks, so over-matching is safe."

**Location:** `hooks/guard-trusted-writes.py:158`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reasoning that the SOFT tier can never yield an ask on a deny-named path: HARD, which is case-sensitive, is checked first, and SOFT maps only to ask or defer. Does not establish safety on a case-insensitive filesystem or with a case-insensitive deny matcher. There, a tainted `SETTINGS.JSON` would be an ask on a path that a deny rule might cover (unverifiable here).

SOFT's outcome is `ask` only `if tier == "soft" and tainted` (`:286-288`), otherwise `defer()` (`:289`). So "only ever asks" is imprecise: SOFT defers untainted (probe: `SETTINGS.JSON` clean -> defer). The safety conclusion holds on Linux because the HARD checks at `:146-155` return before the case-folded loop at `:159-168`. The precise version: "SOFT never does more than ask (and only when tainted), and HARD is matched first, so over-matching here cannot override a deny rule".

**Evidence:** `hooks/guard-trusted-writes.py:146-169,286-289`; captured `$S/iter3-r1-probe.log`

**Legibility-target:** for-author

---

## Claim 12: "TODO(N2): command TEXT that writes a global policy file but carries no indicator token … so it gets no opinion" followed by the listed shapes

**Location:** `hooks/guard-trusted-writes.py:172-184`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eleven listed shapes, each run through `bash_targets`. Does not establish that the list is exhaustive (the A8 primitives are listed separately).

Probe `python3 $S/iter3-r1-n2.py.txt` (21:17:37, exit 0): `~/.clau*/settings.json`, `~/.cl""aude/…`, `D=.cl; ~/${D}aude/…`, `~/.claude/"settings".json`, `hoo"ks"`, `/opt/claude-workflows/hooks/a.sh`, `cp -r dir/. ~/.claude/`, `rsync -a dir/ ~/.claude/`, `cd ~/.claude && cp /tmp/p/* .` -> `None` (no opinion), as stated. Two shapes do not match "no opinion": `cd; echo x > CLAUDE.md` -> `soft` and `echo x > /home/$USER/CLAUDE.md` -> `soft`, because `SOFT_FRAG` matches `(^|[\s"'=/])(AGENTS|CLAUDE|CLAUDE\.local)\.md` (`:221-223`). They get `ask` in a tainted session and defer only in a clean one. So the CLAUDE.md shapes are under-tiered (SOFT, not HARD) rather than given no opinion. The closing line "These replace settings.json … with no gate, even tainted" is correct for the whole-tree copies (all `None`).

**Evidence:** `hooks/guard-trusted-writes.py:172-184,221-240,265-268`; captured `$S/iter3-r1-n2.log`

**Legibility-target:** for-author

---

## Claim 13: Deny message: "…through a symlink or resolved path that permissions.deny does not name. Edit it at its ~/.claude path, with review."

**Location:** `hooks/guard-trusted-writes.py:282-285`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the remediation the message gives the agent. The "permissions.deny does not name" half is accurate (see Claim 9a). Does not establish what a human on the host should do.

```python
# hooks/guard-trusted-writes.py:282-285
            emit("deny", f"This write reaches a protected policy file ({Path(fp).name}: "
                         ".claude hooks/settings or global CLAUDE.md) through a symlink or "
                         "resolved path that permissions.deny does not name. Edit it at its "
                         "~/.claude path, with review.")
```

The "~/.claude path" is exactly what `permissions.deny` blocks for the file tools: `"Edit({{CLAUDE_DIR}}/CLAUDE.md)"`, `"Edit({{CLAUDE_DIR}}/hooks/**)"`, `"Edit({{CLAUDE_DIR}}/settings*.json)"` (`hooks/wiring.json:120-125`). For that spelling the hook itself defers to the deny (probe: `homeA/.claude/CLAUDE.md` -> defer; `$S/iter3-r1-live.log`: `/home/node/.claude/CLAUDE.md -> defer`). In the devcontainer the target is also root-owned `0444` (`stat`: `root 444 /opt/claude-workflows/CLAUDE.md`), and the documented route is "edit the repo, run install.sh, read the diff, bless, rebuild" (`devcontainer-config/link-claude-home.sh:21-23`). An agent that follows the message is refused again. When `CLAUDE_CONFIG_DIR` points elsewhere (Layout D, `cfgreal/settings.json` -> deny), the file is not at a `~/.claude` path at all. For comparison, the Bash message is "Edit it directly with review, not via a shell write" (`:263-264`), which is pre-existing.

**Evidence:** `hooks/guard-trusted-writes.py:263-264,279-285`, `hooks/wiring.json:120-127`, `devcontainer-config/link-claude-home.sh:20-27`; captured `$S/iter3-r1-probe.log`, `$S/iter3-r1-live.log`

**Legibility-target:** for-author

---

## Claim 14: a577546: "bats test/hooks/: 144 ok, 0 not ok."

**Location:** commit `a577546` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at HEAD 31f53e8 (the hook file is unchanged after a577546). Does not establish that each new N1 test fails on the pre-fix hook.

`bats test/hooks/` (cwd `/workspace`, 2026-09-21T21:14:48-07:00) finished `exit=0`, with 144 `^ok` lines and 0 `^not ok` lines. The last line was `ok 144 via field absent for legacy callers writing without it`.

**Evidence:** captured `$S/iter3-r1-bats-hooks.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: a577546: "Probed against this container's installed layout: /opt/claude-workflows/CLAUDE.md -> deny, ~/.claude/CLAUDE.md -> defer, ~/.claude/HOOKS/x -> defer (untainted)."

**Location:** commit `a577546` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo hook against the real installed layout (`CLAUDE_CONFIG_DIR=/home/node/.claude`, scratch taint dir, read-only probe). Does not establish the installed (older) `~/.claude/hooks` copy's behaviour.

`bash $S/iter3-r1-live.sh.txt` (21:21:27, exit 0) printed `/opt/claude-workflows/CLAUDE.md -> deny`, `/home/node/.claude/CLAUDE.md -> defer`, `/home/node/.claude/HOOKS/x -> defer`.

**Evidence:** `hooks/guard-trusted-writes.py:270-289`; captured `$S/iter3-r1-live.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: Test header: "A path that is HARD only after resolve() is named by no deny rule, so the hook denies it itself (N1)", plus the five new N1 tests

**Location:** `test/hooks/guard-trusted-writes.bats:14-16,440-507`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tests passing at HEAD and matching the independent probes. Does not establish pre-fix failure for each test. It is plausible for the deny assertions, since the pre-fix hook deferred on `optA/…/CLAUDE.md` (`$S/iter3-r1-prefix-compare.log`), but the bats files were not run against `a577546^`.

All five N1 tests are among the 144 ok (`$S/iter3-r1-bats-hooks.log`). The independent probe matches every assertion: payload by real path -> deny, symlinked config dir by target -> deny while the lexical spelling defers, case variants defer clean and ask tainted, lexical global paths defer tainted.

**Evidence:** `test/hooks/guard-trusted-writes.bats:440-507`; captured `$S/iter3-r1-bats-hooks.log`, `$S/iter3-r1-probe.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "hold an explicit prefix to the same charset as the recorded one" (A6: "an explicit archive prefix must match [A-Za-z0-9._-]+")

**Location:** `scripts/archive-working-docs.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers rejecting `../../escape` (bats) and accepting `.`, `..`, `...`. Those produce file names like `archive/..-plan-foo.md`: no traversal, because the prefix is joined as `${PREFIX}-${name}`. Does not establish that `_valid_run_id` readers handle a `.`/`..` Run id sensibly (they accept it; same regex).

```bash
# scripts/archive-working-docs.sh:52-55
if ! [[ "$PREFIX" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: prefix '$PREFIX' must match [A-Za-z0-9._-]+" >&2
  exit 1
fi
```

The check runs after the date fallback (`:49`), so it covers explicit, recorded and fallback prefixes. Probe `bash $S/iter3-r1-si.sh.txt` (21:19:04, exit 0): prefix `.` -> `rc=0`, `docs/working/archive/.-plan-foo.md`; `..` -> `docs/working/archive/..-plan-foo.md`. `bats test/morning-summary-clusters.bats test/scripts/archive-working-docs.bats` -> 39 ok, exit 0 (21:15:10).

**Evidence:** `scripts/archive-working-docs.sh:43-56,133`; captured `$S/iter3-r1-si.log`, `$S/iter3-r1-bats-si.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "an existing archive copy is never overwritten" (818c568) / "Two archives under one prefix … must not overwrite the first run's copy."

**Location:** `scripts/archive-working-docs.sh:138-143`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the only `mv` in the script (`:147`), the collision behaviour, and a dangling-symlink destination. Does not establish behaviour under concurrent runs (check-then-move).

```bash
# scripts/archive-working-docs.sh:138-148
  if [ -e "$dest" ]; then
    # Two archives under one prefix (a date-only fallback run twice in a day)
    # must not overwrite the first run's copy.
    echo "  skip  $name: archive/${PREFIX}-${name} already exists" >&2
    continue
  fi
  if $DRY_RUN; then
    echo "  move  $name -> archive/${PREFIX}-${name}"
  else
    mv -- "$f" "$dest"
    echo "  move  $name -> archive/${PREFIX}-${name}"
```

(excerpt ends :148; the loop body continues to `count=$((count + 1))` at :150 and `done` at :151 — read.) On a collision the source stays in place, a stderr "skip" is printed, the exit code stays 0, and the file is not counted. The bats test confirms that "second run" stays at `docs/working/plan-foo.md`. `[ -e ]` follows symlinks, so a dangling symlink at `$dest` reads as absent and `mv` replaces it. Probe `bash $S/iter3-r1-aw.sh.txt` (21:19:25): with `archive/p-plan-foo.md -> nowhere`, the run printed `move plan-foo.md -> archive/p-plan-foo.md`, `rc=0`, and afterwards `p-plan-foo.md` was a regular 4-byte file. Precise version: "never overwritten unless the existing entry is a dangling symlink" (use `[ -e "$dest" ] || [ -L "$dest" ]`).

**Evidence:** `scripts/archive-working-docs.sh:121-158`; captured `$S/iter3-r1-aw.log`

**Legibility-target:** for-author

---

## Claim 19: "Run (Q-047) is the self-improvement run's id (si_default_run_id above, or SI_RUN_ID)"

**Location:** `scripts/lib/si-functions.sh:481`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the "above" pointer. Does not re-verify the rest of the comment.

`si_default_run_id() {` is at `scripts/lib/si-functions.sh:469`, above `:481`.

**Evidence:** `scripts/lib/si-functions.sh:469,481`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: "Exit 0 = header has a Run cell, 3 = no header row at all, 1 = migrate. 3, not 2: awk itself exits 2 on a runtime error (e.g. an unreadable file), and that must fail the call rather than read as "no header"."

**Location:** `scripts/lib/si-functions.sh:566-580`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four return paths and the one production caller. Does not establish that aborting the SI run on an unreadable log is desired. It is what happens: `append_approved_hypotheses` ignores the return, but `scripts/self-improvement.sh:45` is `set -euo pipefail` and calls it as a plain command at `:1874`.

```bash
# scripts/lib/si-functions.sh:576-580
    case "$state" in
        0|3) return 0 ;;
        1) ;;
        *) return "$state" ;;
    esac
```

(excerpt ends :580; the function continues through the rewrite to `return "$rc"` at :595 — read.) Probe `bash $S/iter3-r1-si.sh.txt`: unreadable file -> `awk: cannot open … (Permission denied)`, `unreadable rc=2`; no header -> `rc=0`; has Run -> `rc=0`; migrate -> `rc=0` with `| Round | Task ID | Run |`. `( set -euo pipefail; append_approved_hypotheses … unreadable … ; echo reached )` -> `set -e subshell rc=2`, and "reached" was not printed. So the failure propagates and aborts a `set -e` caller. No test or code expects exit 2: the grep for callers shows only `si-functions.sh:514` and `test/append-approved-hypotheses.bats:162,176,186`, which test the 0/1/no-header paths. The 85 SI tests pass (Claim 25).

**Evidence:** `scripts/lib/si-functions.sh:499-595`, `scripts/self-improvement.sh:45,1874-1875`, `test/append-approved-hypotheses.bats:156-188`; captured `$S/iter3-r1-si.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: "The writer escapes a pipe inside a cell as `\|`; swap those for \036 before awk splits the row (assigning $0 re-splits it), then restore them as a plain `|` for display. Fields are joined with \037 … so a restored pipe cannot split the row again"

**Location:** `scripts/lib/si-morning-summary.sh:402-437`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `_project_state_open_hypotheses` on piped hypotheses and a piped Outcome cell. Also checks that the three readers now agree on cell boundaries: this awk `\036` mask, `_split_row_fields`' `\x1e` mask, and `flag-removal-candidates.sh`, the last by its comment only. Does not establish the Source column being restored (only `hyp` gets `gsub(/\036/, "|")`, so a `\|` in Source would display as a raw `\036` byte).

```awk
# scripts/lib/si-morning-summary.sh:410,421-422
            line = $0; gsub(/\\\|/, "\036", line); $0 = line
                gsub(/\036/, "|", hyp)
                printf "%s\037%s\037%s\037%s\n", tid, round, hyp, src
```

The reader uses `while IFS=$'\037' read -r tid round hyp src` (`:436`). Probe: a row with hypothesis `first \| second \| third. more` and an open Outcome printed `**t-x** (round 2): first | second | third`. A row whose Outcome was `a \| b` was correctly treated as closed (`Open hypotheses: 1`). The pre-fix N4 check is Claim 25.

**Evidence:** `scripts/lib/si-morning-summary.sh:380-445`, `scripts/lib/si-morning-summary.sh:1528-1548`; captured `$S/iter3-r1-si.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: "ASCII Record Separator as a placeholder for `\|`. Assumed, not checked, to be absent from log rows: the writer never emits it, and a row that did contain one would have that byte turned into `\|`."

**Location:** `scripts/lib/si-morning-summary.sh:1532-1535`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the substitution logic and the rename to `_srf_out`. Does not establish that no writer can emit `\x1e`. The comment says as much.

```bash
# scripts/lib/si-morning-summary.sh:1536-1547
    local _srf_sep=$'\x1e'
    _srf_line="${_srf_line//\\|/$_srf_sep}"
    IFS='|' read -ra _srf_raw <<< "$_srf_line"
    _srf_out=()
    local _srf_f _srf_t
    for _srf_f in "${_srf_raw[@]}"; do
        _srf_f="${_srf_f//$_srf_sep/\\|}"
```

(excerpt ends :1542; the loop trims and appends to `_srf_out` through :1547 — read.) Every `\x1e` in a field, original or placeholder, is rewritten to `\|` at `:1542`. So a raw RS byte becomes `\|`, as stated. The executed split `| 2 | t-x | first \| second | user |` -> `<><2><t-x><first \| second><user>` confirms that the escaped-pipe path works.

**Evidence:** `scripts/lib/si-morning-summary.sh:1528-1548`; captured `$S/iter3-r1-si.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23a: "Writes never go through a symlinked questions file or docs/working/ dir, and, for the default paths, never land outside the git toplevel … Explicit QUESTIONS_LIVE/ARCHIVE paths get only the symlink checks."

**Location:** `scripts/questions.sh:47-51`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file and immediate-directory symlink checks, containment for default paths, and the override exemption. Does not establish the parenthetical (Claim 23b).

```bash
# scripts/questions.sh:98-107
    [[ -L "$file" ]] && die "refusing to write: $file is a symlink"
    [[ -L "$dir" ]] && die "refusing to write: directory $dir is a symlink"
    if [[ -z "$overridden" ]]; then
        root="$(realpath -m -- "$PROJECT_ROOT")"
        resolved="$(realpath -m -- "$file")"
        [[ "$resolved" == "$root"/* ]] \
            || die "refusing to write: $file resolves to $resolved, outside $root"
    fi
    return 0
}
```

Probe `bash $S/iter3-r1-qs.sh.txt` (21:19:48): `docs -> /OUTSIDE` -> `init rc=1`, `refusing to write: …/docs/working/questions.md resolves to …/r1qsout…/working/questions.md, outside …`.

**Evidence:** `scripts/questions.sh:88-112`; captured `$S/iter3-r1-qs.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23b: "(an ancestor symlink such as a symlinked docs/ is caught by that check, not by the per-file one)"

**Location:** `scripts/questions.sh:49-50`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers default-path `init` with `docs/` symlinked to an in-repo target (`./x`, `.git`) and to an out-of-repo target. Does not establish whether writing through an in-repo `docs/` symlink is harmful. The comment's own threat model ("docs/working/ and its files are attacker-authored input") treats planted symlinks as the threat.

The containment check compares only the resolved path against the toplevel (Claim 23a quote, `:102-104`), so an ancestor symlink is caught only when it leads outside the toplevel. Probe: `docs -> ./x` -> `init rc=0`, created `./x/working/questions.md` and `./x/working/questions-archive.md`; `docs -> .git` -> `init rc=0`, created `./.git/working/questions.md` and `./.git/working/questions-archive.md`. Only `docs -> /OUTSIDE` was refused. These are the exact counterexamples iter2 N5 listed ("An in-repo ancestor symlink such as `docs -> .git` or `docs -> ./x` passes both checks", iter2 rubric `:76`). The new comment names "a symlinked docs/" as caught without the "outside the toplevel" qualifier. Precise version: "an ancestor symlink that leads outside the toplevel is caught by that check; one that stays inside it (e.g. `docs -> .git`) is not".

**Evidence:** `scripts/questions.sh:47-51,98-107`, `docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20-iter2.md:76`; captured `$S/iter3-r1-qs.log`

**Legibility-target:** for-author

---

## Claim 24: "carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`)" (N8)

**Location:** `skills/code-review/references/rubric.md:156-157`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the pointer is now plain text inside the template fence, and that the named heading exists and matches the summary. Does not address the definition's duplication at `:49-59` (noted in iter2, not claimed fixed).

The line is plain text (no `](#…)` link), and `### Qualifying author note` is at `:159`. Its bullets are "(a) A discoverable TODO" and "(b) A concrete revisit trigger" (`:165-171`), matching the parenthetical.

**Evidence:** `skills/code-review/references/rubric.md:154-174`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: 818c568: "N4 test fails on the pre-fix lib; 85/85 SI suites pass."

**Location:** commit `818c568` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the new N4 test failing on a hermetic `git archive 818c568^` copy (the test file taken from 818c568) and passing at HEAD, plus 85 passing tests across `precondition-gate.bats` (40), `append-approved-hypotheses.bats` (20) and `morning-summary-clusters.bats` (25). Does not establish that this is the suite set the author meant: the commit does not name its suites, and I inferred the set from the exact 85 total.

Pre-fix, in a hermetic copy under `$S/r1si.*/pre`: `not ok 2 open hypotheses: a hypothesis with an escaped pipe is counted and shown whole`, failing at `[[ "$output" == *"Open hypotheses: 2"* ]]` with output `Open hypotheses: 1`, `prefix N4 test rc=1`. At HEAD: `ok 2 …`, `postfix N4 test rc=0`. `bats test/precondition-gate.bats test/append-approved-hypotheses.bats test/morning-summary-clusters.bats` (cwd `/workspace`, 21:18:20) -> `exit=0`, 85 `^ok`, 0 `^not ok`.

**Evidence:** `test/morning-summary-clusters.bats:450-461`; captured `$S/iter3-r1-si.log`, `$S/iter3-r1-bats-si85.log`

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: Q-049 "Interim: unchanged. The devcontainer's `/opt` payload is read-only, which bounds the hooks and CLAUDE.md exposure there. `~/.claude/settings*.json` is not bounded that way."

**Location:** `docs/working/questions.md:55`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the payload's ownership and mode in this container, and settings.json being a merged, node-writable file. Does not establish the bare-host posture, where the checkout is writable.

`ls -ld` printed `dr-xr-xr-x 1 root root … /opt/claude-workflows` and `…/hooks`, and `stat` printed `root 444 /opt/claude-workflows/CLAUDE.md`. The linker comment confirms that settings.json is merged and node-writable: "So this is a default, not a boundary — `node` can still edit the merged result" (`devcontainer-config/link-claude-home.sh:87-88`).

**Evidence:** `devcontainer-config/link-claude-home.sh:84-88`; captured `$S/iter3-r1-opt-perms.log` (`ls -ld /opt/claude-workflows /opt/claude-workflows/hooks; stat -c '%U %a %n' /opt/claude-workflows/CLAUDE.md`, cwd `/workspace`, exit 0)

**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: Q-049 "If Claude Code reads `/path` as relative to the settings file and needs `//path` for an absolute path … every global-dir deny rule matches nothing"

**Location:** `docs/working/questions.md:40`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond noting that the premise is Claude Code documentation or behaviour. Does not establish either reading. The entry itself flags this as unverified ("my recollection of its docs, unverified because the sandbox has no egress").

The premise concerns Claude Code's permission-rule path grammar, which is not in this repo (paraphrased — no quote available because the claim covers external product behaviour, with no matching repo code). Verifying it needs the Q-049 host check, fixed per Claim 5, or the live docs.

**Evidence:** `docs/working/questions.md:40`

**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 5** (`docs/working/questions.md:42-54`): the Q-049 paste prints "enforced" whenever the file is absent, including a failed login, a declined write, or an unanswerable prompt. It has no positive control and discards the JSON, yet an "enforced" result closes N3. Add a no-deny control run and check `num_turns`/`is_error`.
- **Claim 13** (`hooks/guard-trusted-writes.py:282-285`): the new deny tells the agent to "Edit it at its ~/.claude path". That path is denied by `permissions.deny` (and root-owned 0444 in the devcontainer), and it is not `~/.claude` when `CLAUDE_CONFIG_DIR` points elsewhere. Point at the real route (a human edit, or the repo plus install.sh).
- **Claim 23b** (`scripts/questions.sh:49-50`): "a symlinked docs/ is caught" is false for in-repo targets. `docs -> .git` and `docs -> ./x` still write (reproduced). Qualify it with "that leads outside the toplevel".

### Stale
- (none)

### Mostly Accurate
- **Claim 7** (`docs/working/questions.md:60`): Q-048 omits that the literal `CLAUDE_CONFIG_DIR` token counts in both rules, and that any write naming `managed-settings` is HARD.
- **Claim 9c** (`hooks/guard-trusted-writes.py:22-27`, a577546): not disclosed: on the README bare-host layout, file-tool edits of the repo's own `global-instructions/CLAUDE.md` are now denied even untainted (pre-fix: allowed).
- **Claim 11** (`hooks/guard-trusted-writes.py:158`): SOFT asks only when tainted and defers otherwise. The safety comes from HARD being checked first, on a case-sensitive filesystem.
- **Claim 12** (`hooks/guard-trusted-writes.py:172-184`): `cd; echo x > CLAUDE.md` and `/home/$USER/CLAUDE.md` are SOFT (ask when tainted), not "no opinion".
- **Claim 18** (`scripts/archive-working-docs.sh:138-143`): a dangling symlink at the destination is overwritten, because `-e` follows links. Add `|| [ -L "$dest" ]`.

### Unverifiable
- **Claim 9b** (`hooks/guard-trusted-writes.py:19-21`): "a deny rule names that string" for normpath-folded `..`, `//`, and MultiEdit depends on Claude Code's deny matcher (N3-adjacent, disclosed; not re-raised).
- **Claim 27** (`docs/working/questions.md:40`): the `/path` vs `//path` semantics need the host check or the live docs.

---

## Goal-Alignment Note

- **Answered:** All 12 brief items were checked. Every hook branch of `classify_path`/`main()` was probed in four layouts (devcontainer symlink payload, README bare host, symlinked HOME, symlinked or relative `CLAUDE_CONFIG_DIR`), clean and tainted. Test counts were re-run: hooks 144/144, SI 85/85, and the two iter3 SI files 39/39. The N4 pre-fix failure was reproduced hermetically. The exit-3 propagation was executed, including under a `set -e` caller. The archive prefix, collision and dangling-symlink cases were executed. The questions.sh ancestor-symlink cases were executed. `questions.sh check` passes. The Q-023 timings were re-measured (56 s, 96 s). The override-log qualifying notes and the TODO(N2) shapes were checked.
- **Out of scope:** Claude Code's own deny-matcher semantics (`/` vs `//`, `..` folding, case-folding, MultiEdit coverage) were not tested: there is no egress and no live matcher. The 216 s full health check was not re-measured. N2, N3, A7, A8, Q-048 and the three run-id regex copies are settled and were noted, not re-raised; Claim 9b is recorded as the disclosed N3-adjacent residue.
- **Escalate:** Three for-author Incorrects: the Q-049 paste can falsely close N3 (Claim 5); the new deny message sends the agent to a path it cannot edit (Claim 13); the questions.sh comment repeats the iter2 N5 overclaim (Claim 23b). One undisclosed behaviour change: bare-host edits of `global-instructions/CLAUDE.md` are now denied (Claim 9c). Execution logs are in the session scratchpad, not in `docs/reviews/execution-logs/` (the brief forbids other tracked-path writes). Sibling replicate files `iter3-r2-*.txt` already exist there, and I left them untouched.
