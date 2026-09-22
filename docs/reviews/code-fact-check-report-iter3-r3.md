Commit: 31f53e8

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows), branch `answers-2026-09-20`
**Scope:** `git diff 2d93589..answers-2026-09-20` (818c568, a577546, 739cbbb, fd0ad24 merge, b951c4f, 31f53e8): claims in changed files plus the commit messages. Replicate r3, iteration 3 (final confirmation pass).
**Checked:** 2026-09-22
**Total claims checked:** 30 (32 sections: Claims 10 and 17 are split into a/b)
**Summary:** 22 verified, 7 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable (counted over the 32 verdicted sections)

Execution provenance. Every executed check ran under uid 1000 in the review sandbox. Scripts and captured output are in the session scratchpad, `/tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/` (abbreviated `$S` below). They are kept there rather than in `docs/reviews/execution-logs/` because the brief forbids touching the tree beyond this report. Hook probes run the **repo** copy `/workspace/hooks/guard-trusted-writes.py` with a fake `HOME`, `CLAUDE_CONFIG_DIR` unset or set per layout, and `CC_WEB_TAINT_DIR` pointed at a scratch dir holding one taint marker, `sess1`. Only `$S/iter3r3-live.log` uses the real layout, and that probe is read-only.

| Log | Command (cwd) | Exit | Timestamp (UTC) |
|---|---|---|---|
| `$S/iter3r3-bats-hooks.log` | `bats test/hooks/` (/workspace) | 0 | 2026-09-22T04:14:45Z |
| `$S/iter3r3-bats-si.log` | `bats test/morning-summary-clusters.bats test/scripts/archive-working-docs.bats` (/workspace) | 0 | 2026-09-22T04:14:45Z |
| `$S/iter3r3-probe.log` | `bash $S/probe3.sh.txt` (hook probes, layouts A–E + Bash shapes) | 0 | 2026-09-22T04:17:15Z |
| `$S/iter3r3-qsym.log` | `bash $S/qsym.sh.txt` (questions.sh ancestor-symlink probes + `questions.sh check`) | 0 | 2026-09-22T04:17:52Z |
| `$S/iter3r3-mig.log` | `bash $S/mig.sh.txt` (`_migrate_hypothesis_log_run_column` exit codes) | 0 | 2026-09-22T04:18:36Z |
| `$S/iter3r3-prefix.log` | `bash $S/prefix.sh.txt` (818c568 tests on a `git archive 818c568^` copy; SI suites on HEAD) | 0 | 2026-09-22T04:19:16Z |
| `$S/iter3r3-live.log` | `bash $S/live.sh.txt` (repo hook, real installed layout, read-only) | 0 | 2026-09-22T04:20:37Z |
| `$S/iter3r3-timing.log` | timed `run-tests.sh --slow`, `health-check.sh`, `bats test/scripts/health-check.bats` (/workspace) | see Claim 5 | from 2026-09-22T04:19:50Z |

---

## Claim 1: override-log N2 row — "Discoverable TODO: `# TODO(N2)` block beside the Bash indicators (a577546) lists each shape and the suggested direction. Revisit trigger: the next change to the Bash tiers, or Q-048's answer."

**Location:** `docs/reviews/override-log.md:80`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the TODO exists, sits beside the Bash indicator rules, and names every shape the row lists, and that the row carries a concrete revisit trigger (a qualifying author note per `skills/code-review/references/rubric.md:160-172`). Does not establish that the TODO's descriptions of those shapes are exact; see Claim 16.
**Legibility-target:** for-orchestrator-synthesis

The block exists directly above `WRITE_PRIMITIVE`:

```python
# hooks/guard-trusted-writes.py:172-184
# TODO(N2): command TEXT that writes a global policy file but carries no
# indicator token the co-occurrence rules below look for, so it gets no
# opinion (pre-existing; code-review 2026-09-21 iteration 2, N2):
#   - a bare `cd; echo x > CLAUDE.md` (cd to home with no `~`);
#   - `/home/$USER/CLAUDE.md`;
...
# Security's suggested direction: write primitive + CFG_INDICATOR -> HARD.
```

`git log` shows a577546 as the commit that added it. The row lists bare `cd`, `/home/$USER`, globbed or quoted `.claude`, `/opt/claude-workflows/hooks`, `cp -r …/.` and `rsync`, and the TODO lists all six. The revisit trigger names an observable event (paraphrased — no quote available because the trigger is the row's own text, quoted in the claim heading).

**Evidence:** `hooks/guard-trusted-writes.py:172-184`, `docs/reviews/override-log.md:80`, `skills/code-review/references/rubric.md:160-172`

---

## Claim 2: override-log N3 row — "Tracked as Q-049 in `docs/working/questions.md` with a paste. Revisit trigger: Q-049's answer."

**Location:** `docs/reviews/override-log.md:81`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that Q-049 exists, is OPEN, carries a paste block, and that `questions.sh check` accepts the file. Does not establish that the paste answers the question it poses; see Claim 10b.
**Legibility-target:** for-orchestrator-synthesis

`docs/working/questions.md` contains `### Q-049 · deny-rule-absolute-path-form` with `**Status:** OPEN` and a fenced `bash` block. `cd /workspace && bash scripts/questions.sh check` printed `✓ questions: structure valid, indexes current` and exited 0 (`$S/iter3r3-qsym.log`, last two lines).

**Evidence:** `docs/working/questions.md:51-70`, `$S/iter3r3-qsym.log`

---

## Claim 3: override-log A6 row — "the run-id charset `^[A-Za-z0-9._-]+$` is copied in `scripts/self-improvement.sh`, `scripts/archive-working-docs.sh` and `scripts/lib/si-morning-summary.sh` … All three copies are identical and tested"

**Location:** `docs/reviews/override-log.md:82`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the number and identity of regex copies at HEAD. Does not establish that every copy is exercised by a test.
**Legibility-target:** for-author

The three files are right and every copy is identical. There are four copies, though, not three: 818c568 added a second one to `archive-working-docs.sh`.

```bash
# scripts/archive-working-docs.sh:45 and :52
  if [[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
if ! [[ "$PREFIX" =~ ^[A-Za-z0-9._-]+$ ]]; then
# scripts/lib/si-morning-summary.sh:1162
    [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
# scripts/self-improvement.sh:460
if [[ ! "$SI_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
```

Precise version: "four identical copies across three files (two in archive-working-docs.sh)". The row's revisit trigger, "a fourth reader of the Run cell", counts readers rather than copies, so it still holds.

**Evidence:** `scripts/archive-working-docs.sh:45,52`, `scripts/lib/si-morning-summary.sh:1162`, `scripts/self-improvement.sh:460`

---

## Claim 4: override-log 4c7a2bb row (re-pinned, N7) — "Refuted at `hooks/guard-trusted-writes.py:56-132` as of `4c7a2bb` … The defects it hid were R1/R4 …, fixed in `c5a7c96`."

**Location:** `docs/reviews/override-log.md:87`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the pin to 4c7a2bb and the fix attribution to c5a7c96. Does not re-verify the 4c7a2bb line range.
**Legibility-target:** for-author

`git log -1 c5a7c96` gives `fix(hooks): close guard-trusted-writes HARD-tier bypasses (review R1, R3, R4, A10)`, so the pin and the attribution resolve. "Fixed" overstates R1, though. The same log records, three rows up, that c5a7c96 left an R1 residue:

> `docs/reviews/override-log.md:84` (row): "commit c5a7c96 understates the residual (bare `cd`, `/home/$USER`, obfuscated `.claude` dir, quoting inside names, `/opt` payload) … Live gap is N2"

That residue is still deferred as N2 (Claim 1) and still reproduces at HEAD (Claim 16). Precise version: "R4 fixed and R1 partly fixed in c5a7c96; the R1 residue is N2."

**Evidence:** `docs/reviews/override-log.md:84,80,87`, `git log -1 c5a7c96`

---

## Claim 5: Q-023 answer timings (N10) — "that file takes 42–60s depending on load and slow ~80–100s … Full health check measured 216s on the merged tip."

**Location:** `docs/working/questions-archive.md:833`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers one re-measurement of each figure on HEAD 31f53e8 in this sandbox. Some runs overlapped other probes from this replicate, so load was not controlled. Does not establish the original measurements or the ranges' bounds under other loads.
**Legibility-target:** for-orchestrator-synthesis

All three figures agree with a fresh measurement (`$S/iter3r3-timing.log`):

- `bash scripts/run-tests.sh --slow`: rc 0, **79s**. The claim is "~80–100s", and 79s is at the bottom edge. This run overlapped this replicate's probes.
- `bash scripts/health-check.sh`: rc 0, **210s**, ending `All checks passed.` (`$S/iter3r3-hc.out`). The claim is "measured 216s".
- `bats test/scripts/health-check.bats`: rc 0, **49s**, 0 `not ok` (`$S/iter3r3-hcbats.out`). The claim is "42–60s".

The log's first line, `health-check.bats rc=1 secs=0`, came from a wrong path (`test/health-check.bats`, which does not exist) and was rerun at the correct path. (paraphrased — no quote available because the evidence is wall-clock timings captured in the log, not code.)

**Evidence:** `docs/working/questions-archive.md:833`, `$S/iter3r3-timing.log`

---

## Claim 6: Q-048 rule description (N6) — "applied only to commands that contain a write (`>`, `tee`, `cp`, `mv`, `install`, an inline interpreter…). If the command names `CLAUDE.md`, it is denied when it also contains, anywhere, `~`, `$HOME`/`${HOME…}`, the home path, `.claude`, `global-instructions` or the config dir. If it names `settings*.json` or `hooks`, it is denied when it also contains `.claude` or the config dir."

**Location:** `docs/working/questions.md:76`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three co-occurrence branches of `bash_targets`. Does not establish the SOFT branch or WRITE_PRIMITIVE's full list.
**Legibility-target:** for-author

The co-occurrence rules match the description. It leaves out three things the code does:

```python
# hooks/guard-trusted-writes.py:206-207, 210, 220, 229-236
_HOME_INDICATORS = [r"~", r"\$HOME\b", r"\$\{[!#]?HOME\b", r"\.claude\b",
                    r"global-instructions", r"CLAUDE_CONFIG_DIR"]
_CFG_INDICATORS = [r"\.claude\b", r"CLAUDE_CONFIG_DIR"]
HARD_FRAG = re.compile(r"\.claude/hooks(/|\b)|\.claude/settings|managed-settings", re.I)
    if HARD_FRAG.search(cmd):
        return "hard"
```

(excerpt of `bash_targets` ends :236; the function continues to :240 with the SOFT and None returns — read.)

1. The literal token `CLAUDE_CONFIG_DIR` is an indicator on both branches. The probe `echo x > $CLAUDE_CONFIG_DIR/settings.json` returns deny (`$S/iter3r3-probe.log`).
2. Any `.claude/hooks`, `.claude/settings` or `managed-settings` fragment is denied with no second indicator. `echo x > managed-settings.json` returns deny.
3. All of these match case-insensitively (`re.I`).

The description reads as the whole rule, so a reader would miss these deny triggers.

**Evidence:** `hooks/guard-trusted-writes.py:206-240`, `$S/iter3r3-probe.log` (bash section)

---

## Claim 7: Q-048 false denies — "a heredoc that writes a message file mentioning `CLAUDE.md` next to `HEAD~1`, and any Bash write into an agent worktree's `hooks/` (`/workspace/.claude/wt-*/hooks/…`)"

**Location:** `docs/working/questions.md:76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named false-deny shapes, plus the removal of the old `git commit` example. Does not establish that the list of false denies is complete.
**Legibility-target:** for-orchestrator-synthesis

Probe results (`$S/iter3r3-probe.log`):
- `cat > /tmp/msg <<EOF … CLAUDE.md since HEAD~1 … EOF` → deny, clean and tainted.
- `echo x > /workspace/.claude/wt-a/hooks/x.sh` → deny.
- `git commit -m "CLAUDE.md HEAD~1"` → defer. There is no write primitive, so the old text's `git commit` example was wrong, and 739cbbb was right to drop it.

**Evidence:** `$S/iter3r3-probe.log`, `hooks/guard-trusted-writes.py:225-240`

---

## Claim 8: Q-049 factual premises — "`link-claude-home.sh` writes them as `Edit(/home/node/.claude/settings*.json)`, with one leading slash"; "`devcontainer-config/link-claude-home.sh:137` (the `{{CLAUDE_DIR}}` substitution)"; Interim: "The devcontainer's `/opt` payload is read-only … `~/.claude/settings*.json` is not bounded that way."

**Location:** `docs/working/questions.md:54-70`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the rendered deny strings in the live `~/.claude/settings.json`, the cited line, and the file modes. Does not establish how Claude Code interprets those strings; see Claim 9.
**Legibility-target:** for-orchestrator-synthesis

```
# devcontainer-config/link-claude-home.sh:137
                  then gsub("\\{\\{CLAUDE_DIR\\}\\}"; $dir)
```

`jq '.permissions.deny' ~/.claude/settings.json` lists `"Edit(/home/node/.claude/settings*.json)"`, `"Edit(/home/node/.claude/hooks/**)"` and the other rules, each with one leading `/`. `ls -ld` shows `dr-xr-xr-x root root /opt/claude-workflows`, `/opt/claude-workflows/hooks` and `-r--r--r-- root root /opt/claude-workflows/CLAUDE.md`, but `-rw-r--r-- node node /home/node/.claude/settings.json`. (paraphrased — no quote available because these are ad-hoc command outputs from this session, run at 2026-09-22T04:20Z and reproducible with the same `jq`/`ls` commands.)

**Evidence:** `devcontainer-config/link-claude-home.sh:36,137`, `~/.claude/settings.json` (live), `hooks/wiring.json` deny block

---

## Claim 9: Q-049 — "If Claude Code reads `/path` as relative to the settings file and needs `//path` for an absolute path … every global-dir deny rule matches nothing."

**Location:** `docs/working/questions.md:54`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about Claude Code's matcher. It does record that the entry discloses the claim as an unverified recollection. Does not establish whether the live rules match.
**Legibility-target:** for-orchestrator-synthesis

This depends on Claude Code's permission-rule path semantics, which live outside the codebase. The sandbox has no egress, so the docs can't be fetched. The entry itself calls this "my recollection … unverified", and the conditional is logically sound. Verifying it needs the host check Q-049 proposes, done with a positive control (see Claim 10b).

**Evidence:** `docs/working/questions.md:54`

---

## Claim 10a: Q-049 entry format — you: terminal entry with "one copy-pasteable block" and an interim line

**Location:** `docs/working/questions.md:51-70`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grammar in the global CLAUDE.md running-questions section (header line, question line, one block, Interim) and the `questions.sh check` pass. Does not establish that the paste works; see 10b.
**Legibility-target:** for-orchestrator-synthesis

The header is `**Needs:** you: terminal · **Opened:** 2026-09-21 · **Status:** OPEN`. There is exactly one fenced `bash` block, a `- **Interim:**` line, and no options table, which is right for a terminal entry. `questions.sh check` exits 0 (`$S/iter3r3-qsym.log`).

**Evidence:** `docs/working/questions.md:51-70`, `$S/iter3r3-qsym.log`

---

## Claim 10b: Q-049 paste — "For each rule form it grants Write, denies the target, asks Claude to write it, and reports whether the file appeared" / "What I do with it: if single-slash is enforced, N3 is closed as a non-issue."

**Location:** `docs/working/questions.md:57-69`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the paste's output can and cannot distinguish. Does not establish Claude Code's actual matching (not runnable here: no `claude` host session, no egress).
**Legibility-target:** for-author

The paste prints "enforced" whenever the file is missing, and it discards every diagnostic:

```bash
# docs/working/questions.md:64-65
  (cd "$d" && claude -p "Use the Write tool to create the file $t containing: hi" --output-format json >/dev/null 2>&1)
  [ -e "$t" ] && echo "$form-slash rule: NOT enforced (file written)" || echo "$form-slash rule: enforced"
```

Both loop iterations install a deny rule, and there is no control run without one. So "enforced" also appears when the write fails for any other reason:
- `claude -p` fails to authenticate or errors out; its output goes to `/dev/null`.
- The model does not call Write.
- The target sits outside the cwd (`$t` is under a second `mktemp -d`, not `$d`), and the bare `Write` allow doesn't cover out-of-project writes.
- Project settings are not loaded.

Any of these gives "single-slash rule: enforced", and the plan in the entry would then close N3 as a non-issue on no evidence. The paste needs a positive control: a run with only `allow: ["Write"]` that must print "NOT enforced". Stderr and the JSON result should also be kept, so a failed run is visible. (Low-stakes: two temp dirs per form are also never removed.)

**Evidence:** `docs/working/questions.md:59-69`

---

## Claim 11: hook docstring — "Matching is case-sensitive, like the deny rules and like Linux paths: ~/.claude/HOOKS/x is not the hooks dir (it falls to SOFT)."

**Location:** `hooks/guard-trusted-writes.py:14-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's case-sensitive HARD match and SOFT routing on Linux. Does not establish that Claude Code's deny matcher is case-sensitive ("like the deny rules" is an assumption about an external system), and does not cover case-insensitive filesystems. There, `~/.claude/SETTINGS.JSON` IS the real settings file, and untainted it gets a defer with no gate.
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:123-131
        first = rel.parts[0]
        if first == "hooks":
...
    if cand.name == "CLAUDE.md" and cand.parent == HOME:
```

(excerpt ends :131; enclosing `_is_hard` continues to :132 `return False` — read.) Probes (`$S/iter3r3-probe.log`, layout A): `~/.claude/HOOKS/x.sh`, `SETTINGS.JSON`, `claude.md` → defer when clean, ask when tainted.

**Evidence:** `hooks/guard-trusted-writes.py:113-132`, `$S/iter3r3-probe.log`

---

## Claim 12: hook docstring — "covered = the path AS GIVEN (lexical, or normpath with `..` folded) names a HARD entry under the config dir as the deny rules spell it. A deny rule names that string, so the hook DEFERS to it. resolved = the path is HARD only after resolve() (or only under the config dir's resolved form) … the hook returns 'deny' itself."

**Location:** `hooks/guard-trusted-writes.py:18-28`
**Type:** Behavioral / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hook's routing on every candidate across layouts A–E. Does not establish that a deny rule "names" normpath-folded or `//` spellings (Claude Code's normalisation is unverified, N3-adjacent and disclosed in a577546 Notes), nor that `Edit(...)` rules cover MultiEdit.
**Legibility-target:** for-author

The routing matches the docstring (`$S/iter3r3-probe.log`):
- Covered spellings defer: `~/.claude/settings.json`, `settings.foo.json`, `~/.claude/hooks/new.sh`, `~/.claude/CLAUDE.md`, `~/CLAUDE.md`, and literal `~/…`.
- Resolve-only spellings deny, clean and tainted:
  - `$PAYLOAD/CLAUDE.md` and `$PAYLOAD/hooks/foo.sh` (layout A);
  - `realhome/.claude/settings.json` and `realhome/CLAUDE.md` under a symlinked HOME (layout C);
  - `cfgreal/settings.json` and `cfgreal/hooks/a.sh` with CLAUDE_CONFIG_DIR a symlink (layout E).
- No HARD path produced "ask" in any probe.

The imprecise part is "A deny rule names that string" for the normpath branch. `~/.claude/x/../settings.json`, `~/x/../CLAUDE.md` and `~/.claude//settings.json` all defer, but the deny rule names only the folded string. Whether Claude Code folds before matching is unverified. The commit Notes disclose this; the docstring states it as fact. Precise version: "a deny rule names the folded string; whether Claude Code's matcher folds `..` before matching is unverified (Q-049/N3)". The `MultiEdit` probe on `~/.claude/settings.json` also defers although deny rules name only Edit/Write (pre-existing; relies on Claude Code applying Edit rules to MultiEdit, unverified).

**Evidence:** `hooks/guard-trusted-writes.py:134-155`, `hooks/wiring.json` deny block, `$S/iter3r3-probe.log`

---

## Claim 13: `config_dir()` docstring — "This matches the linker for an unset, empty or absolute value. It DIFFERS for a relative value (including one that starts with a literal `~`): the linker substitutes the string as written, while this hook anchors it at the hook's own cwd with abspath()"

**Location:** `hooks/guard-trusted-writes.py:76-79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the unset, empty, absolute and relative branches against `link-claude-home.sh:36`. Does not establish exact string equality for absolute values that abspath rewrites (a trailing `/` or embedded `..`), which the linker keeps as written.
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:81-82
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    return Path(os.path.abspath(cfg)) if cfg else HOME / ".claude"
```

```bash
# devcontainer-config/link-claude-home.sh:36
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
```

An empty string is falsy in Python and `:-` falls back in bash, so the empty case matches. Layout D (`CLAUDE_CONFIG_DIR=cfg`, cwd `$T`): `$T/cfg/settings.json` → defer (HARD), and `~/.claude/settings.json` → ask when tainted (not global).

**Evidence:** `hooks/guard-trusted-writes.py:70-82`, `devcontainer-config/link-claude-home.sh:36`, `$S/iter3r3-probe.log` (layout D)

---

## Claim 14: `_is_hard` docstring — "Case-SENSITIVE, like the deny rules (N1): lowercasing here made ~/.claude/HOOKS/x and ~/.claude/SETTINGS.JSON 'HARD', so the hook deferred onto a rule that does not name them and they got no gate at all."

**Location:** `hooks/guard-trusted-writes.py:118-120`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the before/after routing of the two named case variants on Linux. The claim that no rule names them assumes a case-sensitive Claude Code matcher; see Claim 11's residue.
**Legibility-target:** for-orchestrator-synthesis

The removed lines in the diff are `first = rel.parts[0].lower()` and `if cand.name.lower() == "claude.md"`. The current code compares case-sensitively (Claim 11 quote). The tainted probes now return ask where the old code deferred (`$S/iter3r3-probe.log`).

**Evidence:** `hooks/guard-trusted-writes.py:113-132`, `$S/iter3r3.diff` hunk `@@ -92,33 +101,39 @@`

---

## Claim 15: `classify_path` — "Case-folded on purpose: SOFT only ever asks, so over-matching is safe."

**Location:** `hooks/guard-trusted-writes.py:158`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the fact that SOFT returns ask only when tainted (defer otherwise), and that on Linux no deny-covered spelling in the probe set reaches SOFT, because the HARD checks run first on every candidate. Does not establish safety on a case-insensitive filesystem or matcher. If Claude Code matched `SETTINGS.JSON` against `settings*.json` there, the tainted SOFT ask would override that deny (#39344), which is the invariant the file exists to keep.
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:286-289
        if tier == "soft" and tainted:
            emit("ask", ...)
        defer()
```

(excerpt ends :289; `main()` continues to :291 `defer()` — read.) The HARD loops at :146-155 return before SOFT for every candidate. Probed deny-covered spellings all returned defer or deny, never ask (`$S/iter3r3-probe.log`).

**Evidence:** `hooks/guard-trusted-writes.py:134-169`, `hooks/guard-trusted-writes.py:270-291`, `$S/iter3r3-probe.log`

---

## Claim 16: TODO(N2) — "command TEXT that writes a global policy file but carries no indicator token the co-occurrence rules below look for, so it gets no opinion"

**Location:** `hooks/guard-trusted-writes.py:172-184`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed shape probed clean and tainted. Does not establish that the list is complete.
**Legibility-target:** for-author

Every listed shape still misses HARD at HEAD, so the TODO is live. "Gets no opinion" is exact for the settings, hooks and tree-copy shapes. The two CLAUDE.md shapes are different: they reach SOFT, so they defer when clean but **ask** when tainted (`$S/iter3r3-probe.log`):

| Command | clean | tainted |
|---|---|---|
| `cd; echo x > CLAUDE.md` | defer | ask |
| `echo x > /home/$USER/CLAUDE.md` | defer | ask |
| `~/.clau*/…`, `~/.cl""aude/…`, `${D}aude`, `"settings".json`, `hoo"ks"`, `/opt/claude-workflows/hooks/…`, `cp -r dir/. ~/.claude/`, `rsync -a dir/ ~/.claude/`, `cd ~/.claude && cp /tmp/p/* .` | defer | defer |

Precise version: "…gets no HARD deny: the CLAUDE.md shapes are only SOFT (ask when tainted); the rest get no opinion".

**Evidence:** `hooks/guard-trusted-writes.py:221-240`, `$S/iter3r3-probe.log` (bash section)

---

## Claim 17a: `main()` hard-resolved branch and deny reason — "No deny rule names this spelling, so a defer would be no gate at all" / "reaches a protected policy file … through a symlink or resolved path that permissions.deny does not name"

**Location:** `hooks/guard-trusted-writes.py:279-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the paths that reach "hard-resolved" in layouts A, C and E. Does not cover the bare-host false positive (see 17b).
**Legibility-target:** for-orchestrator-synthesis

Every hard-resolved probe was a spelling outside the rendered `{{CLAUDE_DIR}}`/`~` rule strings (Claim 12). The emit is unconditional on taint:

```python
# hooks/guard-trusted-writes.py:279-285
        if tier == "hard-resolved":
            ...
            emit("deny", f"This write reaches a protected policy file ({Path(fp).name}: "
```

(excerpt ends :282; the message continues to :285 — read.)

**Evidence:** `hooks/guard-trusted-writes.py:274-289`, `$S/iter3r3-probe.log`

---

## Claim 17b: deny reason advice — "Edit it at its ~/.claude path, with review."

**Location:** `hooks/guard-trusted-writes.py:284-285`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers what happens when the agent follows the advice in both N3 outcomes, and the bare-host layout where the message fires on a repo file. Does not establish Claude Code's matcher (N3/Q-049).
**Legibility-target:** for-author

The advice sends the agent to a path it cannot use with review:

- If the deny rules match (the premise the hook's "hard" branch rests on), the `~/.claude` spelling is blocked by `permissions.deny`. A deny rule cannot be approved, so "with review" can't happen. In the devcontainer the target is also root-owned and read-only (Claim 8).
- If they don't match (N3), the hook defers on that spelling (`$S/iter3r3-probe.log`: `~/.claude/CLAUDE.md` → defer, tainted too), so the edit goes through with **no** review.

Neither outcome is "edit it there, with review". A human editing outside Claude Code is the only real route, and the message doesn't say so.

There is also a regression the message fires on. On a bare host set up per `README.md:14` (`ln -s ~/claude-workflows/global-instructions/CLAUDE.md ~/.claude/CLAUDE.md`), editing the repo's own `global-instructions/CLAUDE.md` is now denied, clean and tainted (layout B). Before a577546 it deferred. So routine development of this repo's global instructions is blocked on bare hosts, and the deny message points at a spelling that is denied too. Repo `hooks/*.py` are not affected, because the README copies or links per file into a real `~/.claude/hooks/` dir: `$R/hooks/guard-trusted-writes.py` → defer. The devcontainer's `/workspace` is not affected either (`$S/iter3r3-live.log`: `/workspace/global-instructions/CLAUDE.md` → defer).

**Evidence:** `hooks/guard-trusted-writes.py:95,154-155,279-285`, `README.md:14,29,33-36`, `$S/iter3r3-probe.log` (layout B), `$S/iter3r3-live.log`

---

## Claim 18: a577546 — "Case variants route to SOFT (ask when tainted, defer otherwise), not HARD"

**Location:** `a577546` commit message (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four case variants in the N1 test and the probes on Linux. Does not cover case-insensitive filesystems (see Claim 11).
**Legibility-target:** for-orchestrator-synthesis

Probe log: all four variants → defer when clean, ask when tainted. The bats case `N1: case variants are not HARD …` passes (`$S/iter3r3-bats-hooks.log`). (paraphrased — no quote available because the evidence is probe and test output, not a code line.)

**Evidence:** `test/hooks/guard-trusted-writes.bats:471-486`, `$S/iter3r3-probe.log`, `$S/iter3r3-bats-hooks.log`

---

## Claim 19: a577546 — "'hard-resolved': HARD only after resolve() or only under the config dir's resolved form … -> the hook returns 'deny' itself, tainted or not. Never 'ask' (#39344)."

**Location:** `a577546` commit message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers layouts A, C and E, both taint states. Does not establish that every hard-resolved path deserves a deny; see the bare-host false positive in 17b.
**Legibility-target:** for-orchestrator-synthesis

See Claim 12's probe list. No resolved spelling returned ask or defer.

**Evidence:** `hooks/guard-trusted-writes.py:149-155,279-285`, `$S/iter3r3-probe.log`

---

## Claim 20: a577546 — "bats test/hooks/: 144 ok, 0 not ok."

**Location:** `a577546` commit message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at HEAD 31f53e8 (the later commits don't touch `test/hooks/`). Does not establish the count at a577546 itself.
**Legibility-target:** for-orchestrator-synthesis

`bats test/hooks/` exited 0. `grep -c '^ok'` = 144 and `grep -c '^not ok'` = 0. The last line is `ok 144 via field absent for legacy callers writing without it`.

**Evidence:** `$S/iter3r3-bats-hooks.log`

---

## Claim 21: a577546 — "Probed against this container's installed layout: /opt/claude-workflows/CLAUDE.md -> deny, ~/.claude/CLAUDE.md -> defer, ~/.claude/HOOKS/x -> defer (untainted)."

**Location:** `a577546` commit message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the repo hook against the real layout with `CLAUDE_CONFIG_DIR=/home/node/.claude`, untainted, read-only. Does not cover the installed (older) hook copy.
**Legibility-target:** for-orchestrator-synthesis

`$S/iter3r3-live.log` gives `/opt/claude-workflows/CLAUDE.md -> deny`, `/home/node/.claude/CLAUDE.md` → defer, `/home/node/.claude/HOOKS/x` → defer. It also gives `/opt/claude-workflows/hooks/guard-trusted-writes.py -> deny`.

**Evidence:** `$S/iter3r3-live.log`

---

## Claim 22: archive-working-docs — "hold an explicit prefix to the same charset as the recorded one" (818c568: "an explicit archive prefix must match [A-Za-z0-9._-]+")

**Location:** `scripts/archive-working-docs.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers explicit and fallback prefixes (the check runs after the default is applied, so both are held to it). Does not establish anything about `.` or `..`. Both are accepted, and that is harmless, since the destination is `archive/${PREFIX}-${name}` (e.g. `archive/..-plan.md`), a filename rather than a traversal.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/archive-working-docs.sh:49-55
PREFIX="${PREFIX:-$(date +%Y-%m-%d)}"
...
if ! [[ "$PREFIX" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Error: prefix '$PREFIX' must match [A-Za-z0-9._-]+" >&2
  exit 1
fi
```

The test `an explicit prefix outside … is refused and nothing moves` passes on HEAD and fails on the pre-fix copy (`$S/iter3r3-prefix.log`: `not ok 38`).

**Evidence:** `scripts/archive-working-docs.sh:43-55,133`, `$S/iter3r3-bats-si.log`, `$S/iter3r3-prefix.log`

---

## Claim 23: archive-working-docs — "an existing archive copy is never overwritten" / "must not overwrite the first run's copy"

**Location:** `scripts/archive-working-docs.sh:138-143` (818c568 message)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the only `mv` in the script (:147) and the dry-run path. On a collision the file is skipped with a stderr note, the source stays in place, it is not counted, and the exit is 0. Does not establish atomicity: this is check-then-`mv` with no `-n`, so a copy created between the `-e` test and the `mv` would be overwritten (a race only).
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
```

(excerpt ends :149; the loop continues to :151 with `count` increment and `done` — read.) The second-run test passes on HEAD. The first copy is kept and the source is left in place. The test fails pre-fix (`not ok 39`).

**Evidence:** `scripts/archive-working-docs.sh:124-151`, `$S/iter3r3-prefix.log`, `$S/iter3r3-bats-si.log`

---

## Claim 24: `_migrate_hypothesis_log_run_column` — "Exit 0 = header has a Run cell, 3 = no header row at all, 1 = migrate. 3, not 2: awk itself exits 2 on a runtime error (e.g. an unreadable file), and that must fail the call rather than read as 'no header'."

**Location:** `scripts/lib/si-functions.sh:566-568`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit codes under this sandbox's awk (mawk) and propagation to the call. Does not establish gawk behaviour (not installed). Consequence for callers: the only production caller, `append_approved_hypotheses` (:514), doesn't check the return, so under the `set -euo pipefail` of `scripts/self-improvement.sh:45` an unreadable log now **aborts the SI run** at the hypothesis-logging step, which runs after merges. No test or code expects 2 (grep: none).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/si-functions.sh:572-580
    awk -F'|' '/^\|/ && / Round / {
...
        } END { if (!hdr) exit 3; exit !found }' "$log_file" || state=$?
    case "$state" in
        0|3) return 0 ;;
        1) ;;
        *) return "$state" ;;
    esac
```

(excerpt ends :580; the function continues to :592 with the rewrite — read.) `$S/iter3r3-mig.log` (awk = `/usr/bin/mawk`, uid 1000):
- no header → rc 0;
- Run present → rc 0;
- migrate → rc 0, with the header gaining ` Run |`;
- `chmod 000` file → `awk: cannot open unread.md (Permission denied)`, rc 2;
- `set -euo pipefail` subshell calling `append_approved_hypotheses` on it → rc 2, with "append continued" never printed.

**Evidence:** `scripts/lib/si-functions.sh:499-592`, `scripts/self-improvement.sh:45,1874`, `$S/iter3r3-mig.log`

---

## Claim 25: si-functions header — "Run (Q-047) is the self-improvement run's id (si_default_run_id above, or SI_RUN_ID)"

**Location:** `scripts/lib/si-functions.sh:481`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the relative position of the definition. Nothing else.
**Legibility-target:** for-orchestrator-synthesis

The diff hunk header `@@ -478,7 +478,7 @@ si_default_run_id() {` places `si_default_run_id()` above :481. (paraphrased — no quote available because the evidence is the definition's position, shown by the hunk context rather than a single line.)

**Evidence:** `scripts/lib/si-functions.sh:470-482`

---

## Claim 26: `_project_state_open_hypotheses` — "The writer escapes a pipe inside a cell as `\|`; swap those for \036 before awk splits the row (assigning $0 re-splits it), then restore them as a plain `|` for display. Fields are joined with \037 … not a tab, because `read` collapses runs of whitespace IFS."

**Location:** `scripts/lib/si-morning-summary.sh:402-407`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers count and display for a piped hypothesis under mawk, and consistency with the other two readers. All three mask `\|` before splitting. Display differs: this reader restores a plain `|`, while `flag-removal-candidates.sh` and `_split_row_fields` restore `\|`. Does not establish gawk behaviour.
**Legibility-target:** for-orchestrator-synthesis

```awk
# scripts/lib/si-morning-summary.sh:410-422
            line = $0; gsub(/\\\|/, "\036", line); $0 = line
...
                gsub(/\036/, "|", hyp)
                printf "%s\037%s\037%s\037%s\n", tid, round, hyp, src
```

(excerpt ends :422; the function continues to :452 with the `IFS=$'\037' read` loop — read.) The masking is the same as `scripts/flag-removal-candidates.sh:109-111` and `_split_row_fields` (`si-morning-summary.sh:1540`). The N4 test passes on HEAD and fails on the pre-fix lib (`$S/iter3r3-prefix.log`: `not ok 25`).

**Evidence:** `scripts/lib/si-morning-summary.sh:380-452,1528-1548`, `scripts/flag-removal-candidates.sh:91-116`, `$S/iter3r3-prefix.log`

---

## Claim 27: `_split_row_fields` — "Assumed, not checked, to be absent from log rows: the writer never emits it, and a row that did contain one would have that byte turned into `\|`."

**Location:** `scripts/lib/si-morning-summary.sh:1534-1536`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the reader's handling of a pre-existing \x1e and the writer's escaping. Does not establish whether any real task file carries \x1e.
**Legibility-target:** for-author

The second half is exact: `_srf_f="${_srf_f//$_srf_sep/\\|}"` (`:1543`) turns any \x1e into `\|`. "The writer never emits it" is imprecise. The writer does not add one, but it copies hypothesis text from `jq -r` unfiltered, escaping only `|`:

```bash
# scripts/lib/si-functions.sh:547
        hyp="${hyp//|/\\|}"
```

A task JSON whose hypothesis contains U+001E would reach the log with that byte. Precise version: "the writer never adds it (it passes hypothesis text through, escaping only `|`)".

**Evidence:** `scripts/lib/si-morning-summary.sh:1528-1548`, `scripts/lib/si-functions.sh:520-551`

---

## Claim 28: 818c568 — "N4 test fails on the pre-fix lib; 85/85 SI suites pass."

**Location:** `818c568` commit message (Notes)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the pre-fix failure (on a hermetic `git archive 818c568^` copy with the 818c568 test files) and the pass count at HEAD. The 85 identification is inferred, since the commit doesn't name the suites: `append-approved-hypotheses` (20) + `morning-summary-clusters` (25) + `precondition-gate` (40) = 85. That set excludes `test/scripts/archive-working-docs.bats`, whose A6 tests the same commit adds.
**Legibility-target:** for-orchestrator-synthesis

Pre-fix copy: `not ok 25 open hypotheses: a hypothesis with an escaped pipe …` (plus the two new A6 tests). HEAD, eight SI-related suites together: `1..143`, `ok=143 notok=0`, which includes those three suites, 85 tests (`$S/iter3r3-prefix.log`).

**Evidence:** `$S/iter3r3-prefix.log`, `$S/prefix.sh.txt`

---

## Claim 29: questions.sh header (N5) — "Writes never go through a symlinked questions file or docs/working/ dir, and, for the default paths, never land outside the git toplevel (an ancestor symlink such as a symlinked docs/ is caught by that check, not by the per-file one)."

**Location:** `scripts/questions.sh:47-51`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `init` with three `docs/` symlink targets in scratch repos. Does not re-check `archive` or `index`, which share `assert_write_target`.
**Legibility-target:** for-author

The containment property, "never land outside the git toplevel", holds, and a `docs/` pointing outside is refused. The parenthetical still overstates what gets caught: a `docs/` symlink pointing *inside* the repo passes both checks, and init writes through it (`$S/iter3r3-qsym.log`):

- `docs -> ./x`: init rc 0, files created at `inrepo/x/working/questions.md`.
- `docs -> .git`: init rc 0, files created at `dotgit/.git/working/questions.md`.
- `docs -> /elsewhere`: init rc 1, `refusing to write: … outside …`.

```bash
# scripts/questions.sh:100-104
    if [[ -z "$overridden" ]]; then
        root="$(realpath -m -- "$PROJECT_ROOT")"
        resolved="$(realpath -m -- "$file")"
        [[ "$resolved" == "$root"/* ]] \
```

(excerpt ends :104; `assert_write_target` continues to :107 — read.) Precise version: "an ancestor symlink that resolves outside the toplevel (such as docs/ -> /elsewhere) is caught by that check; one that stays inside the repo, including into .git/, is not".

**Evidence:** `scripts/questions.sh:47-51,95-107`, `$S/iter3r3-qsym.log`

---

## Claim 30: rubric.md (N8) — "carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see 'Qualifying author note' in `skills/code-review/references/rubric.md`)"

**Location:** `skills/code-review/references/rubric.md:155-157`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the named heading exists in the named file and that the gloss matches its two options. Nothing else.
**Legibility-target:** for-orchestrator-synthesis

```markdown
# skills/code-review/references/rubric.md:160, 167, 170
### Qualifying author note
- **(a) A discoverable TODO** — ...
- **(b) A concrete revisit trigger** — ...
```

**Evidence:** `skills/code-review/references/rubric.md:153-172`

---

## Claims Requiring Attention

### Incorrect
- **Claim 10b** (`docs/working/questions.md:57-69`): the Q-049 paste has no positive control and discards `claude -p` output, so any failed run prints "enforced". Add an allow-only control run that must print "NOT enforced", and keep stderr and the JSON output.
- **Claim 17b** (`hooks/guard-trusted-writes.py:284-285`): "Edit it at its ~/.claude path, with review" is impossible either way (deny rules block that path, or under N3 it is ungated). On a README bare host, the new hard-resolved deny also blocks editing the repo's own `global-instructions/CLAUDE.md`.

### Mostly Accurate
- **Claim 3** (`docs/reviews/override-log.md:82`): four identical regex copies, not three (two in archive-working-docs.sh since 818c568).
- **Claim 4** (`docs/reviews/override-log.md:87`): "fixed in c5a7c96" — R1 only partly; the residue is N2.
- **Claim 6** (`docs/working/questions.md:76`): Q-048 omits the `CLAUDE_CONFIG_DIR` token, the indicator-free `.claude/hooks`, `.claude/settings` and `managed-settings` fragment deny, and case-insensitivity.
- **Claim 12** (`hooks/guard-trusted-writes.py:18-21`): "a deny rule names that string" is unverified for normpath-folded and `//` spellings (N3-adjacent, disclosed in commit Notes, not in the docstring).
- **Claim 16** (`hooks/guard-trusted-writes.py:172-174`): the TODO(N2) CLAUDE.md shapes get SOFT (ask when tainted), not "no opinion".
- **Claim 27** (`scripts/lib/si-morning-summary.sh:1534-1536`): the writer passes \x1e through from task JSON; it just doesn't add one.
- **Claim 29** (`scripts/questions.sh:49-50`): an in-repo ancestor symlink (`docs -> ./x`, `docs -> .git`) is not caught.

### Unverifiable
- **Claim 9** (`docs/working/questions.md:54`): Claude Code's `/` vs `//` rule semantics. Needs the Q-049 host check with a control.

---

## Goal-Alignment Note

- **Answered:** All 12 brief items. Hook probes covered every `classify_path` and `main()` branch across five layouts: devcontainer, README bare host, symlinked HOME, relative `CLAUDE_CONFIG_DIR`, and symlinked `CLAUDE_CONFIG_DIR`. Every count and pre-fix claim that could be run was run: 144/0 hooks, 39/39 cluster+archive, 143/143 SI-related, and pre-fix failures confirmed on a `git archive` copy.
- **Invariant check:** No probed path that a deny rule names got "ask". The only "defer on a path no deny rule names" cases are the normpath/`//`/MultiEdit spellings already disclosed under N3. On Linux the case variants now ask when tainted instead of deferring, which is an improvement. New for iteration 3: the bare-host deny on the repo's `global-instructions/CLAUDE.md` (17b) and the Q-049 paste's missing control (10b).
- **Out of scope / not re-raised:** A7, A8, N2 (only its TODO wording checked), N3 (only noted as the residue behind Claims 12 and 17b), A6 regex duplication, Q-048's accepted false denies.
- **Escalate:** Claim 17b's bare-host regression is behavioural, so it's worth a critic's look, not just a wording fix. Claim 24's side effect (an unreadable log now aborts a `set -e` SI run after merges) is intended by the comment, but the caller's handling of it was not designed.
- **Silent guesses:** Claim 28's 85-test suite set is inferred from arithmetic. Claim 10b's failure modes for `claude -p` are reasoned, not run.
