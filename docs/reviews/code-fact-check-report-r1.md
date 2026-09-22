Commit: 654c0ed

# Code Fact-Check Report

**Repository:** /workspace (claude-workflows)
**Scope:** `git diff e8d5fa1..answers-2026-09-20` (HEAD 654c0ed; 32 commits, 50 files). Code first (`hooks/guard-trusted-writes.py`, `scripts/questions.sh`, `scripts/self-improvement.sh`, `scripts/archive-working-docs.sh`, `scripts/lib/si-*.sh`, `scripts/health-check.sh`, `scripts/lite-review.py`, `devcontainer-config/*.sh`), then skill/workflow/global docs and commit messages in range.
**Checked:** 2026-09-21
**Total claims checked:** 33
**Summary:** 21 verified, 4 mostly accurate, 0 stale, 6 incorrect, 2 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read first. Its four entries are all "a specific value quoted from an artifact that does not contain it". Claim 22 matches that class; see "Hallucination-log candidate" at the end.

Execution logs for every `executed` claim are under `docs/reviews/execution-logs/cfc-r1-*` (probe scripts are saved next to their outputs). All probes ran with cwd `/workspace` unless stated, as user `node` with HOME=/home/node. In this container `~/.claude/hooks` → `/opt/claude-workflows/hooks` and `~/.claude/CLAUDE.md` → `/opt/claude-workflows/CLAUDE.md` are symlinks, created by `devcontainer-config/link-claude-home.sh`. That layout is load-bearing for Claim 4.

Every claim carries a **Legibility-target** tag (`for-author` / `for-orchestrator-synthesis` / `for-automated-gate`).

---

## Claim 1: "`archive/failure-analysis/`: it sources `$SCRIPT_DIR/lib/preflight.sh`, which does not exist here … no callers"

**Location:** `archive/failure-analysis/README.md:24-26`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the archived script sources a lib path that is missing under `archive/failure-analysis/scripts/`, and that no live file references `failure-analysis`. Does not cover whether the archived bats suite still passes after being copied back.
**Legibility-target:** for-orchestrator-synthesis

`archive/failure-analysis/scripts/failure-analysis.sh:19,25`: `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` … `source "$SCRIPT_DIR/lib/preflight.sh"`. `archive/failure-analysis/scripts/lib` does not exist, and `scripts/lib/preflight.sh` does. Paraphrased — no quote available because the claim is about absence: a repo-wide `grep -rln failure-analysis` over md/sh/py/bats, excluding `archive/`, `docs/reviews/execution-logs` and the questions docs, returned no hits.

**Evidence:** `archive/failure-analysis/scripts/failure-analysis.sh:19-25`, `scripts/lib/preflight.sh`

---

## Claim 2: "Workflows and the global instructions call helpers by their installed path, ~/.claude/scripts/ — lite-review.py … and questions.sh … so those must resolve in every project"

**Location:** `devcontainer-config/link-claude-home.sh:43-48` (same claim at `devcontainer-config/install.sh:39-43`, `README.md:20-24`)
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the named callers use the installed path, and that the linker makes `$DEST/scripts/{lite-review.py,questions.sh}` resolve. Does not cover a bare host that skips the README `ln -s` line, or a `CLAUDE_CONFIG_DIR` other than `~/.claude`. The docs hard-code `~/.claude/scripts`, while the linker installs to `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` (`link-claude-home.sh:36`).
**Legibility-target:** for-orchestrator-synthesis

The callers use the installed path: `workflows/pr-prep.md:237` `~/.claude/scripts/lite-review.py --repo . --range <last-review-commit>..HEAD --mode fix-drift`, `workflows/review-fix-loop.md:79` (same command), and `global-instructions/CLAUDE.md:235` `Get the next ID from \`~/.claude/scripts/questions.sh next-id\``. The linker's list includes scripts: `ENTRIES=(skills workflows guides patterns hooks scripts CLAUDE.md)` (`link-claude-home.sh:50`). Executed: `bats test/link-claude-home-wiring.bats` exited 0 with 14/14 ok, including `installed ~/.claude/scripts/{lite-review.py,questions.sh} resolve after install`. Run at 2026-09-21T19:30:54-07:00.

**Evidence:** `workflows/pr-prep.md:237`, `workflows/review-fix-loop.md:79`, `global-instructions/CLAUDE.md:235`, `devcontainer-config/link-claude-home.sh:36,50`, `docs/reviews/execution-logs/cfc-r1-bats-link-claude-home-wiring.txt`

---

## Claim 3: "`~/.claude/scripts/questions.sh` acts on the `docs/working/` of the repo you run it from … `check` is a gate only in claude-workflows itself (`scripts/health-check.sh`)"

**Location:** `global-instructions/CLAUDE.md:281`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `$PWD`-toplevel resolution and that health-check pins and gates `check`. Does not cover the edge cases in Claims 18-19: running from inside a `.git` directory, and a dangling symlink during `init`.
**Legibility-target:** for-author

`scripts/questions.sh:55` `PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"`. `scripts/health-check.sh:1024-1026` runs `"$REPO_ROOT/scripts/questions.sh" check` with `QUESTIONS_LIVE`/`QUESTIONS_ARCHIVE` pinned to `$REPO_ROOT/docs/working/...`, and calls `fail` on non-zero. `bats test/questions-doc.bats` exited 0 with 18/18 ok, including `without overrides, files resolve from the git toplevel of $PWD`.

**Evidence:** `scripts/questions.sh:55-57`, `scripts/health-check.sh:1015-1032`, `docs/reviews/execution-logs/cfc-r1-bats-questions-doc.txt`

---

## Claim 4: "HARD = the GLOBAL config dir only … (the config dir is $CLAUDE_CONFIG_DIR when set, else ~/.claude — the same {{CLAUDE_DIR}} hooks/wiring.json substitutes)"

**Location:** `hooks/guard-trusted-writes.py:10-12`
**Type:** Configuration / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which directories `_global_dirs()` treats as HARD and how that compares with the linker's `{{CLAUDE_DIR}}`. Does not establish how Claude Code itself interprets a relative or tilde `CLAUDE_CONFIG_DIR`.
**Legibility-target:** for-author

The code does not pick one dir; `~/.claude` is always HARD:

```python
# hooks/guard-trusted-writes.py:56-67
def _global_dirs():
    """The global config dir(s), as given and resolved. HARD applies only here."""
    dirs = [HOME / ".claude"]
    cfg = os.environ.get("CLAUDE_CONFIG_DIR")
    if cfg:
        dirs.append(Path(os.path.expanduser(cfg)))
    out = []
    for d in dirs:
        out.append(d)
        try: out.append(d.resolve())
        except Exception: pass
    return out
```

The linker substitutes a single dir with no tilde expansion: `DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"` (`link-claude-home.sh:36`) and `gsub("\\{\\{CLAUDE_DIR\\}\\}"; $dir)` with `--arg dir "$DEST"` (`:135-137`). Three consequences, from the executed probe:
- **`~/.claude` stays HARD when the variable is set.** With `CLAUDE_CONFIG_DIR=<abs cfg>`, `classify_path("$HOME/.claude/settings.json")` returns `hard`, so the hook defers. The deny rules are then written for `<cfg>/settings*.json` only (`hooks/wiring.json:120-125`), so that path has no gate at all. This is the situation the docstring's SOFT rationale (`:19-21`) says it avoids.
- **Tilde is handled differently.** The hook `expanduser`s `CLAUDE_CONFIG_DIR='~/cc'`; the linker's `$DEST` would be a literal `~/cc` relative directory.
- **A relative value depends on the hook's cwd.** With `CLAUDE_CONFIG_DIR=cfc_cfg`, the same absolute file is `hard` when the hook runs from the scratch dir and `none` when it runs from `/tmp`.

**Evidence:** `hooks/guard-trusted-writes.py:56-78`, `devcontainer-config/link-claude-home.sh:36,135-137`, `hooks/wiring.json:114-128`, `docs/reviews/execution-logs/cfc-r1-guard-filetools.txt` (cmd `bash cfc-r1-probe3.sh.txt`, cwd scratchpad, exit 0, 2026-09-21T19:28:31-07:00)

---

## Claim 5: "this hook must NEVER "ask" on a HARD path — it DEFERS (lets the deny rule block the file tools)"

**Location:** `hooks/guard-trusted-writes.py:15-17` (restated in code at `:177-180`)
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers file-tool (Edit/Write) decisions for paths that name a global HARD file, in the installed layout where `~/.claude/hooks` and `~/.claude/CLAUDE.md` are symlinks. Does not establish whether Claude Code's deny-rule matcher normalises `..` or follows symlinks. If it does, the hook's "ask" overrides that deny (the #39344 premise); if it does not, the file has only the ask gate when tainted, and no gate when untainted.
**Legibility-target:** for-author

`classify_path` tries the unresolved path `p` and then `rp = p.resolve()`, checking each against `GLOBAL_DIRS` (`:80-99`):

```python
# hooks/guard-trusted-writes.py:88-95
        rel = _global_rel(cand)
        if rel is not None and rel.parts:
            if rel.parts[0] == "hooks":
                return "hard"
            if len(rel.parts) == 1 and name.startswith("settings") and cand.suffix == ".json":
                return "hard"
            if len(rel.parts) == 1 and name == "claude.md":
                return "hard"
```

(excerpt ends :95; enclosing `classify_path` continues to :109 — read)

- A `..` segment breaks the unresolved check: `rel.parts` becomes `('x','..','CLAUDE.md')`.
- `resolve()` follows the installed symlinks out of `~/.claude` into `/opt/claude-workflows/`, which is not in `GLOBAL_DIRS`.
- The path then falls through to the `".claude" in low → "soft"` branch (`:107-108`).

Executed decisions (tainted session, NEW = HEAD, OLD = e8d5fa1):
- `Edit ~/.claude/x/../CLAUDE.md` → NEW **ask**, OLD defer (regression)
- `Edit <proj>/.claude/CLAUDE.md` where `<proj>/.claude -> ~/.claude` → NEW **ask**, OLD defer (regression)
- `Edit <proj>/.claude/hooks/guard-trusted-writes.py` (same symlink) → NEW **ask**, OLD defer (regression)
- `Edit ~/.claude/x/../hooks/guard-trusted-writes.py` → **ask** on both versions (pre-existing)

`settings.json` is a real file here, so its `..` and symlink variants still defer. The plain spellings `~/.claude/hooks/...`, `~/.claude/./hooks/...` and `~/.claude//hooks/...` defer correctly.

**Evidence:** `hooks/guard-trusted-writes.py:80-109,172-184`, `docs/reviews/execution-logs/cfc-r1-guard-filetools.txt`, `docs/reviews/execution-logs/cfc-r1-probe3.sh.txt`

---

## Claim 6: "SOFT = … a PROJECT's own .claude/ (settings*.json, hooks/**; Q-026) … Gated to "ask" only when the session is web-tainted."

**Location:** `hooks/guard-trusted-writes.py:18-22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers real (non-symlinked) project `.claude/settings.json` and `.claude/hooks/*` under file tools, tainted and untainted. Does not cover a project `.claude/` that is a symlink to the global dir; see Claim 5.
**Legibility-target:** for-orchestrator-synthesis

`:107-108` `if ".claude" in low: return "soft"`, and `:181-184` asks only `if tier == "soft" and tainted`. Probe results:
- `/workspace/.claude/settings.json` (tainted) → ask; untainted → defer
- `/workspace/.claude/hooks/x.py` (tainted) → ask

`bats test/hooks/guard-trusted-writes.bats` exited 0 with 40/40 ok (2026-09-21T19:29:04-07:00).

**Evidence:** `hooks/guard-trusted-writes.py:100-109,181-184`, `docs/reviews/execution-logs/cfc-r1-guard-filetools.txt`, `docs/reviews/execution-logs/cfc-r1-bats-guard.txt`

---

## Claim 7a: "Bash … HARD = … CLAUDE.md only when qualified as global: `~/`, `$HOME/`, `${HOME}/`, the literal home path, or `global-instructions/CLAUDE.md`"

**Location:** `hooks/guard-trusted-writes.py:24-29`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exactly the five listed textual prefixes followed immediately by `/CLAUDE.md`. Does not establish that every shell spelling of the global file is HARD (Claim 7b).
**Legibility-target:** for-orchestrator-synthesis

```python
# hooks/guard-trusted-writes.py:123-129
_GLOBAL_PREFIXES = [r"~", r"\$HOME", r"\$\{HOME\}", r"global-instructions"]
if str(HOME).rstrip("/"):         # HOME="/" would make this prefix empty and match any "/CLAUDE.md"
    _GLOBAL_PREFIXES.append(re.escape(str(HOME).rstrip("/")))
HARD_FRAG = re.compile(
    r"\.claude/hooks(/|\b)|\.claude/settings|\.claude/CLAUDE\.md|managed-settings"
    r"|(?:" + "|".join(_GLOBAL_PREFIXES) + r")/CLAUDE\.md",
    re.I)
```

These classify `hard`: `~/CLAUDE.md`, `$HOME/CLAUDE.md`, `${HOME}/CLAUDE.md`, `"$HOME/CLAUDE.md"`, `"${HOME}/CLAUDE.md"`, `/home/node/CLAUDE.md`, `global-instructions/CLAUDE.md` and `$HOME/.claude/CLAUDE.md`.

**Evidence:** `hooks/guard-trusted-writes.py:121-142`, `docs/reviews/execution-logs/cfc-r1-guard-bash-probe.txt`

---

## Claim 7b: "SOFT = a bare/project `CLAUDE.md` (Q-035)" / "for the Bash path that deny rules don't cover, returns "deny" outright"

**Location:** `hooks/guard-trusted-writes.py:16-17,30-31`
**Type:** Behavioral / Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Bash classification of shell spellings that name the global `~/CLAUDE.md` or `~/.claude/CLAUDE.md` but not in one of the literal forms from 7a. Does not cover indirection that no text matcher can see (`D=~; … $D/CLAUDE.md`, `cd ~ && … CLAUDE.md`), which is the accepted residual class.
**Legibility-target:** for-author

The docstring splits CLAUDE.md into two cases: global-qualified → HARD (deny), bare/project → SOFT. In practice, many shell-equivalent spellings of the *global* files now land in SOFT. SOFT means ask only when tainted, and when untainted the hook emits nothing, so there is no gate. The regex needs the prefix immediately before `/CLAUDE\.md` (`:128`), so any quote, doubled slash, `./`, `..` or `${HOME:-}` in between defeats it. The SOFT regex then matches the `/CLAUDE.md` tail (`:131-132` `(^|[\s\"'=/])(AGENTS|CLAUDE|CLAUDE\.local)\.md`).

These were HARD at e8d5fa1 and are **soft** at HEAD:
- `"$HOME"/CLAUDE.md`, `'$HOME'/CLAUDE.md`, `${HOME:-}/CLAUDE.md`
- `~//CLAUDE.md`, `~/./CLAUDE.md`, `~"/CLAUDE.md"`, `~/"CLAUDE.md"`
- `$HOME/.claude/../CLAUDE.md`, `$HOME/x/../CLAUDE.md`, `$HOME/''CLAUDE.md`
- `/home/node//CLAUDE.md`, `/home/node/./CLAUDE.md`
- `~/.claude//CLAUDE.md` and `~/.claude/./CLAUDE.md` (the global config's own CLAUDE.md)
- `./global-instructions//CLAUDE.md`, `global-instructions/./CLAUDE.md`
- `$CLAUDE_CONFIG_DIR/CLAUDE.md`

End-to-end hook run: `echo x > ~//CLAUDE.md` gives **ask** when tainted and **defer** (no gate) when untainted. The `.claude/settings` and `.claude/hooks` fragments have the same `//` and `./` gap (`.claude//settings.json` → None), but that gap already existed at e8d5fa1.

**Evidence:** `hooks/guard-trusted-writes.py:121-142,159-170`, `docs/reviews/execution-logs/cfc-r1-guard-bash-probe.txt` (NEW vs OLD columns), `docs/reviews/execution-logs/cfc-r1-probe_guard.py`

---

## Claim 8: "HOME="/" would make this prefix empty and match any "/CLAUDE.md""

**Location:** `hooks/guard-trusted-writes.py:124`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the guard skips the empty literal-home prefix and that an unguarded empty alternative would match any `/CLAUDE.md`. Does not cover what HOME="/" does to the tilde/`$HOME` prefixes, which are textual and unaffected.
**Legibility-target:** for-orchestrator-synthesis

With `HOME=/`, `_GLOBAL_PREFIXES` was `['~', '\\$HOME', '\\$\\{HOME\\}', 'global-instructions']`, with no literal-home entry, and `bash_targets('echo x > /tmp/CLAUDE.md')` returned `soft`. Rebuilding the regex with an empty alternative appended matched the same command (`unguarded match: True`). End-to-end under `HOME=/`, `echo x > ~/CLAUDE.md` is still denied.

**Evidence:** `hooks/guard-trusted-writes.py:123-129`, `docs/reviews/execution-logs/cfc-r1-guard-filetools.txt` (HOME=/ lines; inline python run 2026-09-21T19:27-07:00, exit 0)

---

## Claim 9: "Default prefix: the run id the self-improvement loop recorded at run start (si-run-id.txt, Q-047) … Falls back to today's date when the file is absent or its content is unusable."

**Location:** `scripts/archive-working-docs.sh:7-8,39-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default-prefix branch when no positional PREFIX is given. Does not cover positional PREFIX validation (none exists; pre-existing), or whether `si-run-id.txt` still belongs to the run being archived (see Claim 20).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/archive-working-docs.sh:43-49
if [ -z "$PREFIX" ] && [ -f "$WORKING_DIR/si-run-id.txt" ]; then
  RUN_ID=$(head -n1 "$WORKING_DIR/si-run-id.txt")
  if [[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
    PREFIX="$RUN_ID"
  fi
fi
PREFIX="${PREFIX:-$(date +%Y-%m-%d)}"
```

The prefix is used only as `"$ARCHIVE_DIR/${PREFIX}-${name}"`, so the class excludes `/` and path traversal is not possible. `bats test/scripts/archive-working-docs.bats` exited 0 with 11/11 ok.

**Evidence:** `scripts/archive-working-docs.sh:37-49,127`, `docs/reviews/execution-logs/cfc-r1-bats-archive-working-docs.txt`

---

## Claim 10: "Runs every tagged suite through scripts/run-tests.sh, fast first and slow second (Q-023). The fast set is a blocking pre-gate … Before Q-023 this gate ran only test/skills/ and test/hooks/ … the ~40 suites under test/ and test/scripts/ … Report gating … is owned by run-tests.sh … Recursion guard"

**Location:** `scripts/health-check.sh:344-363` (also header `:20-26`, `:535-536`, commit 0ccbdb8)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's ordering, blocking, skip-guard and seam against a stub runner, plus the static facts: suite count, report gating living in run-tests.sh, and health-check.bats and link-claude-home-wiring.bats being tagged slow. Does not cover a full real-suite run of gate 5 (not executed: too long, and a background bats timing loop is running).
**Legibility-target:** for-orchestrator-synthesis

`:378-390` runs `HEALTH_CHECK_SKIP_BATS=1 "$runner" --fast`; on failure it calls `fail "Fast BATS suites failed — slow suites not run (fix fast first)"` and returns, otherwise it runs `--slow`. `:370-373` skips with a warning when `HEALTH_CHECK_SKIP_BATS == 1`. Supporting static facts:
- 44 `.bats` files sit under `test/*.bats` and `test/scripts/*.bats`, which fits "~40".
- The report-gating block is at `scripts/run-tests.sh:80-116`.
- `test/scripts/health-check.bats` and `test/link-claude-home-wiring.bats` both begin `# @category slow`.
- `test/scripts/health-check.bats:19` `export HEALTH_CHECK_SKIP_BATS=1`.

`bats test/scripts/health-check.bats` exited 0 with 17/17 ok, including the four `gate 5:` tests (fast then slow; red fast blocks slow; red slow fails; SKIP=1 warns and does not pass). Finished 2026-09-21T19:39:04-07:00.

**Evidence:** `scripts/health-check.sh:344-391,535-536`, `scripts/run-tests.sh:80-128`, `test/scripts/health-check.bats:19,176-210`, `docs/reviews/execution-logs/cfc-r1-bats-health-check.txt`

---

## Claim 11: "Run … is the LAST column so positional readers … keep working, and a log whose header predates it is migrated in place (header and separator gain the column; old rows keep an absent cell, which readers treat as "unknown run" and resolve newest-first)."

**Location:** `scripts/lib/si-functions.sh:469-475`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the writer's column order, header migration, and the morning-summary reader's handling of a missing Run cell (`_pick_col` → empty → newest-first scan). Does not cover rows whose hypothesis contains an escaped `\|`. `_split_row_fields` splits on raw `|` (`si-morning-summary.sh:1501`), which shifts every positional pick right; for an old row that has a user-filled Evidence cell, `_pick_col` for Run would read that Evidence text as a run id. That is a pre-existing class, now also reaching Run.
**Legibility-target:** for-orchestrator-synthesis

The writer appends the run id last: `printf '| %s | … | %d | | | | %s |\n' … "$((round + window))" "$run_id"` (`si-functions.sh:537-538`). `_pick_col` returns `"${arr_ref[$((col-1))]:-}"` (`si-morning-summary.sh:1519`), and `_find_tasks_file` with an empty `run` skips the run-specific candidates (`:1180-1186`). Probe: after appending with run `2026-09-21` onto an old-header log, the old rows keep 11 cells and the new row ends `| | | | 2026-09-21 |`. `append-approved-hypotheses.bats` (15/15), `precondition-gate.bats` (36/36) and `morning-summary-clusters.bats` (22/22) all exited 0.

**Evidence:** `scripts/lib/si-functions.sh:469-540`, `scripts/lib/si-morning-summary.sh:968-1017,1497-1541`, `docs/reviews/execution-logs/cfc-r1-si-questions-probe.txt`, `docs/reviews/execution-logs/cfc-r1-bats-append-approved-hypotheses.txt`, `…-precondition-gate.txt`, `…-morning-summary-clusters.txt`

---

## Claim 12: "Data rows are untouched. No-op when the header already has a Run cell or no header is found. … Exact-cell match, so "Checked at Round" never counts as "Run"."

**Location:** `scripts/lib/si-functions.sh:543-550`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the content effect of migration in three cases (old header, already migrated, no header) and the exact-cell check. Does not establish anything about concurrent writers.
**Legibility-target:** for-author

Accurate parts:
- The exact-cell test is `gsub(/^[ \t]+|[ \t]+$/, "", c); if (c == "Run") found = 1` (`:551`), so "Checked at Round" cannot match.
- On an old log, `diff` shows only the header and separator lines changed.
- A second call leaves the file byte-identical (the early `return 0`).

The imprecise part is "no-op … when no header is found". The presence check exits non-zero with no header, so the function goes on to rewrite the file: `tmp=$(mktemp "${log_file}.XXXXXX")` … `> "$tmp" && mv "$tmp" "$log_file"` (`:557-567`). The content comes out identical, but the file is replaced: the inode changes and the mode becomes 0600, the `mktemp` default. The probe shows `mode=600 inode_changed=yes` for the no-header case. A real migration also drops the mode from 644 to 600. Precise version: "content-preserving when no header is found; the file is always rewritten with mode 0600 unless a Run cell already exists."

**Evidence:** `scripts/lib/si-functions.sh:541-568`, `docs/reviews/execution-logs/cfc-r1-si-questions-probe.txt` (cmd `bash cfc-r1-probe4.sh.txt`, cwd scratchpad/cfc4, exit 0, 2026-09-21T19:31:18-07:00)

---

## Claim 13: "True when the run id is empty, the file is absent (runs predating the Run column), or the ids match"

**Location:** `scripts/lib/si-morning-summary.sh:1145-1148`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three listed conditions and one unlisted one. Does not cover callers.
**Legibility-target:** for-author

```bash
# scripts/lib/si-morning-summary.sh:1149-1156
_live_run_matches() {
    local working_dir="$1" run="$2"
    [ -z "$run" ] && return 0
    [ -f "$working_dir/si-run-id.txt" ] || return 0
    local live
    live=$(head -n1 "$working_dir/si-run-id.txt" 2>/dev/null)
    [ -z "$live" ] || [ "$live" = "$run" ]
}
```

It also returns true when the file exists but its first line is empty (`[ -z "$live" ]`). The comment should list that fourth case.

**Evidence:** `scripts/lib/si-morning-summary.sh:1145-1156`

---

## Claim 14: "With a run id … tries that run's archived copy … first, then the live file when the live working dir belongs to that run. Rows without a Run column … or whose run has no copy left, fall back to the newest-first scan … In every case the first candidate that actually contains task id $2 wins"

**Location:** `scripts/lib/si-morning-summary.sh:1158-1169`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers candidate order and the contains-tid filter. Does not establish that the fallback cannot pick another run's file. It can, and the comment says so implicitly: the fallback always includes the live file and newest-first archives.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/lib/si-morning-summary.sh:1180-1186
    done < <(if [ -n "$run" ]; then
                 printf '%s\n' "$working_dir/archive/${run}-tasks-round-$round.json"
                 _live_run_matches "$working_dir" "$run" \
                     && printf '%s\n' "$working_dir/tasks-round-$round.json"
             fi
             printf '%s\n' "$working_dir/tasks-round-$round.json"
             _archived_newest_first "$working_dir/archive" "tasks-round-$round.json")
```

(excerpt ends :1186; enclosing `_find_tasks_file` continues to :1188 — read). The loop body returns the first candidate that `-f` exists and contains the tid. `precondition-gate.bats` covers run-scoped lookups, live-run mismatch and fallback: 36/36 ok.

**Evidence:** `scripts/lib/si-morning-summary.sh:1158-1188`, `docs/reviews/execution-logs/cfc-r1-bats-precondition-gate.txt`

---

## Claim 15: "NOT --bare, although `claude -p --bare` is the obvious spelling … (and the one asked for in Q-025)"

**Location:** `scripts/lite-review.py:17-18`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the user's Q-025 answer asked for `--bare`. Does not cover the runtime claim in Claim 16.
**Legibility-target:** for-orchestrator-synthesis

`git show e8d5fa1` (the user's answers commit) adds: "What I had hoped for was a re-implementation of the lite review using `claude -p --bare`."

**Evidence:** commit `e8d5fa1` (answers diff, line 23 of `git show`), `docs/working/questions-archive.md:464-480`

---

## Claim 16: "Verified 2026-08-15 - a --bare call on a subscription-only machine prints "Not logged in" and still exits 0"

**Location:** `scripts/lite-review.py:19-21` (repeated at `workflows/review-fix-loop.md:93-95`)
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond noting that the claim is consistent with project memory. Does not establish current CLI behaviour.
**Legibility-target:** for-orchestrator-synthesis

This is an executable guarantee about the external `claude` CLI's auth behaviour. It was not run: it would need a subscription-only headless invocation, which would use the user's credentials and quota, and the sandbox has no egress. Paraphrased — no quote available because the evidence lives outside the repo: the user's memory note "CC --bare blocks all subscription auth" says the same thing. Blocker: execution required, blocked by the credentials and network policy.

**Evidence:** `scripts/lite-review.py:17-24`

---

## Claim 17: "Which files: the docs/working/ of the git repo you run it FROM (the toplevel of $PWD; $PWD itself outside a git repo) … QUESTIONS_LIVE / QUESTIONS_ARCHIVE override either path."

**Location:** `scripts/questions.sh:35-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers nested subdirectories of a git repo, non-git dirs, and the overrides. Does not cover a `$PWD` inside a `.git` directory: `rev-parse --show-toplevel` fails there, so the `|| pwd` fallback writes to `.git/docs/working/`, a location git never tracks.
**Legibility-target:** for-author

`:55` `PROJECT_ROOT="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || pwd)"` and `:56-57` `LIVE="${QUESTIONS_LIVE:-$PROJECT_ROOT/docs/working/questions.md}"`. Probe results:
- `init` from `repo/a/b` created `repo/docs/working/*`
- `init` from non-git `nogit/sub` created `nogit/sub/docs/working/*`
- `init` from `repo/.git` created `repo/.git/docs/working/*`

**Evidence:** `scripts/questions.sh:35-57`, `docs/reviews/execution-logs/cfc-r1-si-questions-probe.txt`

---

## Claim 18: "Never touches a file that exists."

**Location:** `scripts/questions.sh:316` (`cmd_init`)
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers regular existing files (not clobbered) and a dangling symlink at the live path. Does not cover races.
**Legibility-target:** for-author

The guard is `[[ -e "$file" ]] && { echo "  = exists: $file"; continue; }` (`:320`), and the write is `printf … > "$file"` (`:328`). `-e` is false for a dangling symlink, so `init` writes *through* it. The probe shows the target outside the project being created: `elsewhere-target.md`, 80 bytes. Regular files are left alone; the bats `never clobbers` test passes. Precise version: "never overwrites an existing file; a dangling symlink is followed and its target created."

**Evidence:** `scripts/questions.sh:314-332`, `docs/reviews/execution-logs/cfc-r1-si-questions-probe.txt`, `docs/reviews/execution-logs/cfc-r1-bats-questions-doc.txt`

---

## Claim 19: "it becomes a file-name prefix and a markdown cell, so only [A-Za-z0-9._-] is accepted."

**Location:** `scripts/self-improvement.sh:456-457`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex's accept/reject behaviour for bash `=~`. Does not establish that every accepted value is sensible: `.`, `..` and leading `-` (e.g. `-rf`) are accepted. That is harmless as a `${PREFIX}-name` file-name prefix, but not what "a date prefix" suggests.
**Legibility-target:** for-orchestrator-synthesis

`:458-462`:

```bash
SI_RUN_ID="${SI_RUN_ID:-$(date +%F)}"
if [[ ! "$SI_RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo "Error: SI_RUN_ID must match [A-Za-z0-9._-]+ (got: $SI_RUN_ID)" >&2
    exit 1
fi
```

- Accepted: `2026-09-21`, `run.2`, `..`, `.`, `-rf`
- Rejected: `a/b`, `a b`, `x;y`, `é`, `a\nb`, the empty string

**Evidence:** `scripts/self-improvement.sh:451-463`, `docs/reviews/execution-logs/cfc-r1-si-questions-probe.txt`

---

## Claim 20: "archive-working-docs.sh reads si-run-id.txt for its default prefix, so the two agree even when the archive happens on a later day."

**Location:** `scripts/self-improvement.sh:453-455`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the reader/writer pairing (same path, same regex). Does not establish agreement when (a) archiving is given an explicit PREFIX, (b) a later SI run has already overwritten `si-run-id.txt`, or (c) archive-working-docs is run from outside the repo root (it uses the relative `docs/working`).
**Legibility-target:** for-orchestrator-synthesis

The writer is `printf '%s\n' "$SI_RUN_ID" > "$WORKING_DIR/si-run-id.txt"` (`self-improvement.sh:463`, with `WORKING_DIR` under `$REPO_DIR/docs/working`). The reader is `archive-working-docs.sh:43-47`, quoted in Claim 9. Both use the same `^[A-Za-z0-9._-]+$` check.

**Evidence:** `scripts/self-improvement.sh:463`, `scripts/archive-working-docs.sh:37-49`

---

## Claim 21: "The corpus is LOCAL-ONLY: docs/working/reviews/round-*/ is gitignored (Q-036 …)"

**Location:** `scripts/self-improvement.sh:1485-1489` (and `.gitignore:11-13`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ignore rule matching the archive path written at `:1490`. Does not cover files already tracked before the rule.
**Legibility-target:** for-orchestrator-synthesis

`git check-ignore -v docs/working/reviews/round-3/x/y.md` → `.gitignore:13:docs/working/reviews/round-*/`. The writer is `CR_ARCHIVE="$WORKING_DIR/reviews/round-$ROUND/$TASK_ID"` (`:1490`).

**Evidence:** `.gitignore:11-13`, `scripts/self-improvement.sh:1485-1490` (command run inline, cwd /workspace, exit 0, 2026-09-21T19:36-07:00; output reproduced above)

---

## Claim 22: "test-strategy … P1 → 🟡 Must Address; P2 and below → 🟢" (contextual-critic row)

**Location:** `skills/code-review/references/rubric.md:288-294` (repeated at `rubric.md:340`, `rubric.md:504`, `skills/code-review/SKILL.md:1230`, commit d659fa9)
**Type:** Reference / Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether test-strategy emits a P1/P2 scale. Does not assess which tier its real values should map to.
**Legibility-target:** for-author

test-strategy has no P-scale. Its recommended-test template is `**Priority:** [high / medium / low]` (`skills/test-strategy/SKILL.md:196`), and `grep '\bP[0-3]\b' skills/test-strategy/` returns nothing. The rubric row reads `| 🟡 Must Address | Major | P1 | any confirmed finding |` (`rubric.md:290`). So a confirmed test-strategy finding with `Priority: high` has no defined tier. The label came from the Q-042 option text (`questions-archive.md`, Q-042 option [1]), and that same question states test-strategy uses "Priority". Fix: key the row on `Priority: high`, and `medium/low` for 🟢.

**Evidence:** `skills/code-review/references/rubric.md:282-294,340,504`, `skills/code-review/SKILL.md:1230`, `skills/test-strategy/SKILL.md:196`, `docs/working/questions-archive.md` (Q-042)

---

## Claim 23: "also record the file's path and its `Commit:` metadata line (security-reviewer writes `Commit: <hash>` at the top)"

**Location:** `skills/architecture-review/SKILL.md:212-213`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what security-reviewer's instructions say it writes. Does not cover whether existing `docs/reviews/security-review-*.md` files carry the line.
**Legibility-target:** for-orchestrator-synthesis

`skills/security-reviewer/SKILL.md:557`: "save your critique as `docs/reviews/security-review-{date}.md` … with a `Commit: <hash>` metadata line at the top". The same instruction appears at `:48`.

**Evidence:** `skills/security-reviewer/SKILL.md:48,557`

---

## Claim 24: "Factual claims rated Disputed … Attributed quotes rated Secondary-only" (new 🟡 rows)

**Location:** `skills/draft-review/SKILL.md:514-515`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that both verdict names exist in fact-check's scale. Does not cover the rest of draft-review's tier table.
**Legibility-target:** for-orchestrator-synthesis

`skills/fact-check/SKILL.md:163` defines `**Disputed** — Evidence exists on both sides…` and `:172` defines `**Secondary-only** — Used for attributed quotes…`.

**Evidence:** `skills/fact-check/SKILL.md:163-175`, `skills/draft-review/SKILL.md:511-518`

---

## Claim 25: "a High confidence verdict requires at least one `[deep-read]` source, and a verdict resting only on `[abstract]` reads caps at Medium"

**Location:** `skills/fact-check/SKILL.md:179-181` (also `:376-377`, `:414-420`, `:448`, `:553`)
**Type:** Invariant (doc-internal consistency)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers consistency across the five restatements and the worked-example table rows. Does not establish anything about the fact-check runtime.
**Legibility-target:** for-orchestrator-synthesis

- `:414-417` "If no cited source is `[deep-read]` and at least one is `[abstract]`, the verdict **caps at Medium** … There is no Medium → Low step for `[abstract]` reads."
- `:376-377` "a verdict whose sources are all `[abstract]` caps at Medium".
- `:418-420` keeps the one-tier downgrade only for all-`[inferred]` scrutiny.
- Every `[abstract]` row in the calibration table (`:459-461`) is Medium or Low.
- A grep for "downgrade" finds no remaining text that applies a Medium→Low step to `[abstract]`.

**Evidence:** `skills/fact-check/SKILL.md:177-181,373-377,410-450,455-462,550-554`

---

## Claim 26: "Macro × Cold | Low (matches the hot-path gate; escalate when the cold path blocks a latency-sensitive operation or runs over large data, e.g. a nightly batch)"

**Location:** `skills/performance-reviewer/SKILL.md:283`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement between the table row and the hot-path gate paragraph. Does not assess whether Low is the right default.
**Legibility-target:** for-author

The gate is `:46`: "Code in cold paths … should default to Low or Informational unless the cold path blocks a latency-sensitive operation." The default (Low) and the latency-sensitive escalation match. The row adds a second escalation trigger that the gate does not have: "or runs over large data, e.g. a nightly batch". Either add that trigger to the gate paragraph or drop "matches" for that clause.

**Evidence:** `skills/performance-reviewer/SKILL.md:46,276,283`

---

## Claim 27: "[qualifying author note](../skills/code-review/references/rubric.md#-must-address)"

**Location:** `workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every relative link and anchor in the 38 non-questions `.md` files the range changed. Only these two failed. Does not cover links inside `docs/working/questions*.md`.
**Legibility-target:** for-automated-gate

In `rubric.md`, the heading `## 🟡 Must Address` (`:49`) sits inside the fenced ```` ```markdown ```` template block that opens at `:31` and closes at `:158`. It renders as code, not a heading, so no `#-must-address` anchor exists. The nearest real anchor for that definition is `#deliverable-2-code-review-rubric` (`:7`), which `chat-synthesis.md` already uses correctly. The anchor checker (`cfc-r1-anchors.py`) reported `broken=2`, exactly these two links, and resolved every other cross-reference named in the brief. That includes `review-fix-loop.md#divergence-detection-stuck-loop-signal`, `#re-flagged-settled-decisions-override-log-filter`, `#hard-cap-3-iterations`, `#fix-commit-drift-check-lite`, `pr-prep.md#3-review-fix-loop`, `override-log.md#capture-format`, `#capturing-new-overrides`, `rubric.md#unified-severity-mapping`, `#executable-defect-channel` and `chat-synthesis.md#next-action-derivation`.

**Evidence:** `skills/code-review/references/rubric.md:7,31,49,158`, `workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`, `docs/reviews/execution-logs/cfc-r1-anchors.txt` (cmd `python3 cfc-r1-anchors.py <changed .md files>`, cwd /workspace, exit 0, 2026-09-21T19:34:32-07:00)

---

## Claim 28: "Chat-synthesis rules 4 and 5 are exhaustive for 0 🔴 … a saved architecture-review skip note … counts as the critic having run"

**Location:** `skills/code-review/references/chat-synthesis.md:130-136,159-165`
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the n>2 / n≤2 partition and that architecture-review defines a saved skip note. Does not cover rules 1-3 firing on 0 🔴 (1(a) still can, by design).
**Legibility-target:** for-orchestrator-synthesis

Rule 4 fires when "0 🔴 but >2 🟡 items are open without a qualifying author note", and rule 5 when "0 🔴 items AND ≤2 🟡 items open without a qualifying author note". Together they cover every count. `skills/architecture-review/SKILL.md:84` says "skip the review and emit a short skip note", and `:142` says "Save the skip note to the same path the full critique would have used."

**Evidence:** `skills/code-review/references/chat-synthesis.md:128-180`, `skills/architecture-review/SKILL.md:84,142`

---

## Commit-message claims

## Claim 29a: "Global paths are unchanged." / "HARD now applies only under the global config dir … matching wiring.json's {{CLAUDE_DIR}}"

**Location:** commit `4c7a2bb` message (Q-026 paragraph)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers file-tool and Bash decisions for global-file spellings, old vs new. The message is immutable history, so per rubric.md's immutable-history exception this is an `Accepted-immutable` candidate, not a tier.
**Legibility-target:** for-orchestrator-synthesis

The probes found these global-path decisions changed at 4c7a2bb:
- File tools: `~/.claude/x/../CLAUDE.md` went from defer to ask (Claim 5), and a symlinked project `.claude` pointing at the global hooks and CLAUDE.md went from defer to ask (Claim 5).
- `~/.claude/sub/settings.json` went from `hard` to `soft`.
- Bash: `~/.claude//CLAUDE.md`, `"$HOME"/CLAUDE.md`, `~//CLAUDE.md` and more went from deny to soft (Claim 7b).
- "Matching wiring.json" is inaccurate (Claim 4).

**Evidence:** `docs/reviews/execution-logs/cfc-r1-guard-filetools.txt`, `docs/reviews/execution-logs/cfc-r1-guard-bash-probe.txt`

---

## Claim 29b: "Tests: 14 new cases in test/hooks/guard-trusted-writes.bats (40/40 pass)"

**Location:** commit `4c7a2bb` message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at 4c7a2bb vs its parent, and passing at HEAD, where the file is identical. Does not cover the claimed `scripts/run-tests.sh --fast passes` at that commit (not re-run).
**Legibility-target:** for-orchestrator-synthesis

`git show 4c7a2bb~1:test/hooks/guard-trusted-writes.bats | grep -c '^@test'` gives 26, and at `4c7a2bb` it gives 40 (14 new, all listed by `git diff`). At HEAD, `bats test/hooks/guard-trusted-writes.bats` gives 40/40 ok, exit 0.

**Evidence:** `test/hooks/guard-trusted-writes.bats`, `docs/reviews/execution-logs/cfc-r1-bats-guard.txt`

---

## Claim 30a: "test/skills: 656/656" (test count)

**Location:** commit `d659fa9` message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test count. The pass status is Claim 30b.
**Legibility-target:** for-orchestrator-synthesis

`bats --count test/skills/*.bats` gives 656. The raw `^@test` grep gives 672 at both d659fa9 and HEAD. The 16 extra lines are `@test` text inside non-test contexts that bats does not count.

**Evidence:** inline command, cwd /workspace, exit 0, 2026-09-21T19:36-07:00, output `656`

---

## Claim 30b: "test/skills: 656/656 pass"

**Location:** commit `d659fa9` message
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Nothing established. Execution is required.
**Legibility-target:** for-orchestrator-synthesis

Not executed. Running all 656 skill tests alongside the user's background bats timing loop would skew that loop and take a long time. Blocker: execution required, deferred to avoid interfering with the running timing loop.

**Evidence:** `test/skills/*.bats`

---

## Claim 31: "Tests: header/row/migration/idempotence, run-scoped lookups, live-run mismatch, fallback, days-since by run, an end-to-end deferred-evaluation row, and the archive default prefix."

**Location:** commit `a45f4a9` message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the named suites exist in the diff and pass at HEAD. Does not cover whether each test would catch a regression (no mutation testing).
**Legibility-target:** for-orchestrator-synthesis

All four suites exited 0 at HEAD:
- `append-approved-hypotheses.bats`: 15/15
- `precondition-gate.bats`: 36/36
- `morning-summary-clusters.bats`: 22/22
- `archive-working-docs.bats`: 11/11

The diff adds 34+59+25+27 lines to these files (per `git show --stat`). Paraphrased — no quote available because the claim spans four test files; the per-suite outputs are in the logs.

**Evidence:** `docs/reviews/execution-logs/cfc-r1-bats-append-approved-hypotheses.txt`, `…-precondition-gate.txt`, `…-morning-summary-clusters.txt`, `…-archive-working-docs.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`hooks/guard-trusted-writes.py:10-12`): the global set is always `~/.claude` **plus** `$CLAUDE_CONFIG_DIR`, not one or the other. With the variable set, `~/.claude/settings*.json` is HARD→defer while the deny rules cover only `$CLAUDE_CONFIG_DIR`, so that path has no gate. Tilde and relative-path handling also differ from the linker.
- **Claim 5** (`hooks/guard-trusted-writes.py:15-17`): the hook *does* ask on HARD targets. In the installed layout, `resolve()` follows the `~/.claude/{hooks,CLAUDE.md}` symlinks into `/opt/claude-workflows`, outside `GLOBAL_DIRS`, so `~/.claude/x/../CLAUDE.md` and a project `.claude` symlinked to `~/.claude` (hooks, CLAUDE.md) now get **ask**. Before this change they deferred.
- **Claim 7b** (`hooks/guard-trusted-writes.py:16-17,30-31`): the global CLAUDE.md files are denied in Bash only in the exact literal forms. `"$HOME"/CLAUDE.md`, `~//CLAUDE.md`, `~/./CLAUDE.md`, `${HOME:-}/CLAUDE.md`, `~/"CLAUDE.md"`, `$HOME/x/../CLAUDE.md`, `~/.claude//CLAUDE.md` and `~/.claude/./CLAUDE.md` are now SOFT (untainted → no gate). All were HARD at e8d5fa1. These are beyond the accepted `cd ~ && … CLAUDE.md` residual.
- **Claim 22** (`skills/code-review/references/rubric.md:290`, plus `:340`, `:504`, `SKILL.md:1230`): the "test-strategy P1/P2" scale does not exist. test-strategy emits `Priority: high/medium/low`.
- **Claim 27** (`workflows/pr-prep.md:190`, `workflows/review-fix-loop.md:43`): the anchor `rubric.md#-must-address` does not exist because the heading is inside a code fence. Use `#deliverable-2-code-review-rubric`.
- **Claim 29a** (commit 4c7a2bb): "Global paths are unchanged" and "matching wiring.json" are refuted by Claims 4, 5 and 7b. The message is immutable history: record it as `Accepted-immutable`.

### Stale
- (none)

### Mostly Accurate
- **Claim 12** (`scripts/lib/si-functions.sh:543-545`): with no header the "no-op" still rewrites the file (new inode, mode 0600), and a real migration also leaves mode 0600.
- **Claim 13** (`scripts/lib/si-morning-summary.sh:1145-1148`): `_live_run_matches` is also true when `si-run-id.txt` exists but its first line is empty.
- **Claim 18** (`scripts/questions.sh:316`): `init` follows a dangling symlink and creates its target, which may be outside the project.
- **Claim 26** (`skills/performance-reviewer/SKILL.md:283`): the "runs over large data / nightly batch" escalation is not part of the hot-path gate it claims to match.
- Scope residues worth a line, not verdicted separately: Claim 17 (`questions.sh` run from inside `.git/` writes `.git/docs/working/`), Claim 19 (`SI_RUN_ID` accepts `.`, `..`, `-rf`) and Claim 11 (escaped `\|` in a hypothesis shifts the Run pick onto Evidence).

### Unverifiable
- **Claim 16** (`scripts/lite-review.py:19-21`): the `--bare` "Not logged in, exit 0" behaviour needs a live subscription-only `claude -p --bare` run. Blocked by credentials and network.
- **Claim 30b** (commit d659fa9): "656/656 pass" needs a full `test/skills` run. Deferred so the background timing loop is not disturbed.

---

## Hallucination-log candidate (not appended)

Claim 22 qualifies under this skill's "After you finish" rule: a scale value is referenced that the named component does not expose. It belongs to the same class as the existing log entries (a value attributed to an artifact that does not contain it). The orchestrator's rules for this run forbid modifying any file other than this report, so it was **not** appended. Proposed entry:

`- **"test-strategy P1/P2" severity claimed in code-review rubric but test-strategy emits Priority high/medium/low** — the Q-042 contextual-critic row keys test-strategy on P1/P2; skills/test-strategy/SKILL.md:196 defines only "Priority: [high / medium / low]" and contains no P-scale. First seen: 2026-09-21, report: docs/reviews/code-fact-check-report-r1.md.`

The only files written besides this report are new captured-output logs and probe scripts under `docs/reviews/execution-logs/cfc-r1-*`, which the skill's executed-provenance rule requires. No existing file was modified.

---

## Goal-Alignment Note

- **Answered:** All seven focus areas in the brief were checked.
  1. The guard-hook tier docstring was checked by importing the module and running old-vs-new probes over about 45 Bash spellings and about 25 file-tool paths, including the symlinked-project, relative/tilde `CLAUDE_CONFIG_DIR` and HOME=/ cases.
  2. The HOME="/" comment was checked (Verified).
  3. The `{{CLAUDE_DIR}}` equivalence was checked (Incorrect).
  4. `questions.sh` resolution and `init` were checked, including the non-git, `.git`-dir and dangling-symlink cases, along with the installed-path claims in the global instructions, README and linker.
  5. `SI_RUN_ID` validation and the archive-prefix pairing, the migration comments, and the morning-summary absent-Run handling were checked.
  6. Gate 5 fast-then-slow was checked, with health-check.bats run end to end (17/17), plus the test-count claims in 4c7a2bb, d659fa9 and a45f4a9.
  7. The fact-check Medium cap, the performance-reviewer "matching the gate" claim, the code-review reference changes, and every pr-prep / review-fix-loop cross-reference were checked by an anchor resolver.
- **Out of scope:** The large `questions.md` → `questions-archive.md` move was not audited line by line, apart from Q-025 and Q-042. The DD / design-space-situating wording edits and `docs/decisions/012` were read but hold no executable claims. I did not run a full real-suite gate 5, or `test/skills` in full, to avoid disturbing the background bats timing loop.
- **Escalate:** Claims 5 and 7b are security-relevant regressions for the security-reviewer. HARD global files now get ask, or no gate, through `..` / symlink paths (file tools) and through quoted or normalised spellings (Bash). Claim 4's "`~/.claude` HARD but ungated when `CLAUDE_CONFIG_DIR` points elsewhere" is a design question for the author. One process note for the orchestrator: the live installed hook (the older copy under `/opt/claude-workflows`) denied several of my probe commands because they contained `.claude/settings` or `CLAUDE.md` next to a redirect. I moved those probes into script files; no probe was lost.
