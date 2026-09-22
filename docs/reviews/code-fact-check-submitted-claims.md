Commit: 654c0ed

# Code Fact-Check Report — Submitted Claims

**Repository:** /workspace (claude-workflows)
**Scope:** `git -C /workspace diff e8d5fa1..answers-2026-09-20` at HEAD 654c0ed. Only the submitted claims were verdicted; Stage 1 did the harvesting.
**Checked:** 2026-09-21
**Total claims checked:** 3 (numbered 25–27)
**Summary:** 1 verified, 2 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Probe scripts and outputs are in `/tmp/claude-1000/-workspace/104b63ce-e414-465c-a24f-dda1e4116218/scratchpad/sub/`. They were not added to the repo. Every probe used a throwaway HOME, taint dir and project dir under that scratchpad. No real dotfiles were read for writing or touched.

---

## Submitted Claims

## Claim 25: "SI_RUN_ID is validated with the same regex both where it is written (scripts/self-improvement.sh) and where archive-working-docs.sh reads it back, and neither accepts `/`, so archive names cannot escape `archive/`."

**Submitted by:** security-reviewer
**Location:** `scripts/self-improvement.sh:458-463`, `scripts/archive-working-docs.sh:43-49,58`; related reader `scripts/lib/si-morning-summary.sh:1017,1159-1190,1330-1346`
**Type:** Behavioral / security
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex at both sites, the `dest=` construction in archive-working-docs.sh, and the Run-cell read paths in si-morning-summary.sh. It does not cover the explicit CLI `PREFIX` argument of archive-working-docs.sh. That argument is unvalidated and was just as unvalidated at e8d5fa1 (`*) PREFIX="$arg"`), so it is outside this claim.
**Legibility-target:** the security-reviewer's "What Looks Good" endorsement of SI_RUN_ID sanitization

**The part about the write path is correct.** Both sites use the identical literal `^[A-Za-z0-9._-]+$` (self-improvement.sh:459, archive-working-docs.sh:45). The writer exits 1 on a mismatch before `printf '%s\n' "$SI_RUN_ID" > .../si-run-id.txt` (:463). The reader falls back to the date when the id doesn't match, and then builds `dest="$ARCHIVE_DIR/${PREFIX}-${name}"` (:58).

Executed: `bash sub/runid-regex-probe.txt` (cwd scratchpad, bash from the container, locale C/C.UTF-8; en_US.UTF-8 is not installed and falls back to C). Output is in `runid-regex-probe.out.txt`:
- Rejected: `../x`, `a/b`, `a\nb`, `a\r`, `é`, fullwidth `ａ`, `~`, empty, `a b`.
- Accepted: `..`, `.`, `-rf`, `2026-09-21`.

`..` is accepted, but it can't traverse, because the name always gets `-${name}` appended.

Executed: `bash sub/archive-runid-probe.txt`, which runs the real `scripts/archive-working-docs.sh` in throwaway dirs with a planted `si-run-id.txt`. Output is in `archive-runid-probe.out.txt`:
- id `..` → `docs/working/archive/..-plan-foo.md`. The file stays inside `archive/`.
- id `../../evil` → rejected. The script fell back to the date prefix (`2026-09-22-…` under TZ=UTC).
- id `ok-run` → `archive/ok-run-plan-foo.md`.

All three exited 0.

**Why the verdict is only "mostly accurate".** The other reader builds paths from the hypothesis-log **Run cell** without any validation. `row_run=$(_pick_col fields "$run_col")` (si-morning-summary.sh:1017) goes unchanged into:
- `_find_tasks_file` → `"$working_dir/archive/${run}-tasks-round-$round.json"` (:1181)
- `_days_since_round` → `"$working_dir/archive/${run}-round-$round-report.json"` (:1337)

Read `_find_tasks_file` whole (:1170-1190) and `_days_since_round` (:1329-1370). Both use the path only for `[ -f ]` and `jq` reads. Nothing writes to it.

Executed: `bash sub/morning-run-cell-probe.txt`, which sources the real lib and plants `outside/x-tasks-round-3.json` outside `archive/`. Output is in `morning-run-cell-probe.out.txt`. With a Run cell of `../../outside/x`, `_find_tasks_file` returned `.../w/archive/../../outside/x-tasks-round-3.json`, and `_resolve_hypothesis_target` then reported `skill:foo` from that out-of-tree file.

So archive **names** can't escape `archive/`, as the claim says. The morning summary, though, can be pointed at files outside `archive/` for **reading** by editing the Run cell in `hypothesis-log.md`. The loop itself fills that cell from the validated `$SI_RUN_ID` (self-improvement.sh:1874). The exposure is read-only and needs the repo-tracked log to be edited. That is low severity. The simple fix is to apply the same regex to `row_run`, or drop it when it doesn't match.

Side note: `si-run-id.txt` is not in archive-working-docs.sh's `PERMANENT` list, so an archive run moves it too (`archive/<id>-si-run-id.txt` in both probe outputs). `_live_run_matches` then treats a missing file as "matches" (:1152). That looks intended, but it isn't written down.

**Evidence:** `scripts/self-improvement.sh:458-463`, `scripts/archive-working-docs.sh:43-49,58`, `scripts/lib/si-morning-summary.sh:1017,1150-1190,1329-1346`, probe outputs `runid-regex-probe.out.txt`, `archive-runid-probe.out.txt`, `morning-run-cell-probe.out.txt`

---

## Claim 26: "Project `.claude/` paths (settings*.json, hooks/**) now get an 'ask' through the file tools in tainted sessions, where before they got no gate."

**Submitted by:** security-reviewer
**Location:** `hooks/guard-trusted-writes.py:80-109` (classify_path), `:172-184` (main file-tool branch); baseline `git show e8d5fa1:hooks/guard-trusted-writes.py:41-68,124-136`
**Type:** Behavioral / security
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Write tool on project and global `.claude/{settings.json, settings.local.json, hooks/x.sh, CLAUDE.md, notes.md}`, in tainted and clean sessions, for both hook versions, with `CLAUDE_CONFIG_DIR` unset. Edit and MultiEdit take the same branch (:172) and were read, not run. "No gate" here means that neither the hook nor the `hooks/wiring.json` deny rules gated these paths. Claude Code's own built-in permission prompts and any user allow rules are outside this claim and were not assessed.
**Legibility-target:** the security-reviewer's endorsement of the Q-026 tier change

**Before (e8d5fa1).** classify_path matched any `.claude` segment followed by `hooks`, any `settings*.json` under a `.claude` segment, and any `claude.md` under `.claude` as **hard**, whether global or project (old :49-56). main then `defer()`ed on hard (old :129-132). That left the path to the deny rules. But `hooks/wiring.json:120-127` names only `{{CLAUDE_DIR}}/…` and `~/CLAUDE.md`, so a project `.claude/settings.json` fell through both the hook and the deny list.

**After.** Hard now applies only to paths relative to `GLOBAL_DIRS` (:56-78, :88-95). A project `.claude/` path falls through to `if ".claude" in low: return "soft"` (:107-108). That returns `ask` when the session is tainted (:181-183).

Executed: `bash sub/guard-project-claude-probe.txt` (fake HOME, `CC_WEB_TAINT_DIR` with session `sess1` marked tainted, `CLAUDE_CONFIG_DIR` unset). Output is in `guard-project-claude-probe.out.txt`:

| path | old tainted | new tainted | new clean |
|---|---|---|---|
| project `.claude/settings.json` | defer (no output) | **ask** | defer |
| project `.claude/settings.local.json` | defer | **ask** | defer |
| project `.claude/hooks/x.sh` | defer | **ask** | defer |
| project `.claude/CLAUDE.md` | defer | **ask** | defer |
| project `.claude/notes.md` | ask | ask | defer |
| global `.claude/settings.json`, `hooks/x.sh`, `CLAUDE.md` | defer | defer | defer |

The claim is accurate, including the qualifier "in tainted sessions". Clean sessions still defer, and global HARD paths still defer to the deny rules and never ask. The old behaviour was therefore "hook defers, and no deny rule matches". It was not an ask or a deny.

**Evidence:** `hooks/guard-trusted-writes.py:56-109,172-184`, `git show e8d5fa1:hooks/guard-trusted-writes.py` lines 41-68 and 124-136, `hooks/wiring.json:120-127`, `guard-project-claude-probe.out.txt`

---

## Claim 27: "The new hook adds only ~1–2 ms per call over the pre-diff hook on ~20 ms python startup."

**Submitted by:** performance-reviewer
**Location:** `hooks/guard-trusted-writes.py:56-69` (`_global_dirs()` evaluated at import as `GLOBAL_DIRS`)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Per-invocation wall time of the whole hook subprocess. Two payloads: a Write to a project `.claude/settings.json` in a tainted session, and a Bash `echo hi > out.txt`. Tested with `CLAUDE_CONFIG_DIR` unset and set. This is one 16-core WSL2 host with load around 2–3, Python 3.11.2. The fake HOME is shallow, so `resolve()` had no symlinks to follow. Deep or network-mounted HOME paths were not tested.
**Legibility-target:** the performance-reviewer's "What Looks Good" endorsement of hook overhead

Executed: `python3 sub/guard-bench.py.txt 150` (cwd scratchpad). It runs old and new interleaved, N=150 each, with a hermetic HOME and taint dir. Output is in `guard-bench.out.txt`:

| case | old median | new median | delta |
|---|---|---|---|
| no CLAUDE_CONFIG_DIR, Write project settings | 17.62 ms | 17.98 ms | +0.36 ms |
| no CLAUDE_CONFIG_DIR, Bash echo | 17.09 ms | 16.92 ms | −0.17 ms |
| CLAUDE_CONFIG_DIR set, Write project settings | 17.92 ms | 18.16 ms | +0.24 ms |
| CLAUDE_CONFIG_DIR set, Bash echo | 18.64 ms | 18.44 ms | −0.19 ms |

- The `_global_dirs()` body costs about 34 µs per call in-process.
- Bare `python3 -c pass` takes a median of 6.41 ms.
- The p10–p90 spread (about 15–25 ms) is far wider than any delta.

The claim's direction holds: the overhead is negligible. It overstates the size, though. The measured delta is ≤0.4 ms and inside the noise, not about 1–2 ms. A whole hook call is about 17–18 ms, and bare interpreter startup is about 6 ms, not about 20 ms. As an upper bound the claim is safe. The two figures should be corrected to "<0.5 ms, noise-level, on ~17 ms per call".

**Evidence:** `hooks/guard-trusted-writes.py:56-78`, `guard-bench.py.txt`, `guard-bench.out.txt`

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 25** (`scripts/lib/si-morning-summary.sh:1017,1181,1337`): the writer and the archive reader are both correct, but the morning summary builds read paths from the unvalidated hypothesis-log Run cell. A cell like `../../x` makes it read files outside `archive/`. Apply the same `^[A-Za-z0-9._-]+$` check to `row_run`.
- **Claim 27** (`hooks/guard-trusted-writes.py:56-69`): the overhead is overstated. It measures ≤0.4 ms (noise), and a hook call is about 17 ms, not about 20 ms.

---

## Goal-Alignment Note

- **Answered:** all three submitted claims, verdicted with executed hermetic probes (numbered 25–27, one `## Submitted Claims` section, report saved at the requested path, first line `Commit: 654c0ed`). No other repo file was modified. Probe scripts use `.txt` names and live in the scratchpad.
- **Out of scope:**
  - The unvalidated CLI `PREFIX` argument of archive-working-docs.sh. It predates the diff.
  - Claude Code's built-in permission prompts for project `.claude/` edits (Claim 26's "no gate" is judged at the hook and deny-rule layer only).
  - Symlink and `..` variants of the HARD-path classification, which Stage-1 Claim 1 already covers.
- **Escalate (orchestrator):**
  - The **installed** hook `/home/node/.claude/hooks/guard-trusted-writes.py` is byte-identical to the e8d5fa1 (pre-diff) version (`diff -q` silent). This session's own probe command was denied by it: a heredoc that merely contained paths was classified HARD under the old bare-`CLAUDE.md`/`.claude/settings` Bash rules. So the Q-026/Q-035 behaviour verified here is not what is running live until the hook is redeployed. That is worth a line in the review so nobody assumes it already is.
  - For the security-reviewer: the Run-cell read-path finding (Claim 25) is a new, low-severity amber candidate.
