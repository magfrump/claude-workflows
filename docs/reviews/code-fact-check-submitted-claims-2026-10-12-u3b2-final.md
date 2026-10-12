Commit: 4afdd68b

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u3b2, branch feat/build-loop-u3b2)
**Scope:** Stage-2.5 submitted claims only (k=1), from security-reviewer and performance-reviewer, final confirming pass on `main...4afdd68b`; no fresh harvesting
**Checked:** 2026-10-12
**Total claims checked:** 5 (4 submitted; claim 53 split into 53a and 53b)
**Summary:** 3 verified, 1 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Probe scripts and captured output are in the session scratchpad, `/tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/` (p1-p6 `.sh`; output in `p1.out`, `p2.out`, `p5.out`). Every probe made its own temp dir under `/tmp/u3b2rv-sub-`, ran under `timeout` with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` and a fixture identity, and was removed afterwards. The script ran from the worktree path. The two timing probes ran the three versions' `scripts/` trees, taken with `git archive`. The host awk is `/usr/bin/mawk`; gawk and busybox are not installed.

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`): none of these claims matches a logged pattern.

---

## Submitted Claims

## Claim 53a: "A chore-subject merge whose tree is not merge-tree's clean merge reads other, for `-X theirs` [...] and unrelated-history merges"

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:1644-1648`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two-parent chore-subject merges made with `-X theirs` over a conflicting file and with `--allow-unrelated-histories`, each with a valid cycle record. It does not establish that every `-X theirs` merge reads other: a clean `-X theirs` merge has the clean tree and reads chore, as the claim's qualifier allows. It also does not cover gate-subject merges, which were not probed here.

The chore branch calls the tree check before it reads the record:

```bash
# scripts/build-loop.sh:1644-1648
clean_merge() {
  local t
  t="$(gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}")" \
    && [[ "$t" == "$(LC_ALL=C awk '/^tree / { print $2; exit }' "$GATE_TMP/c")" ]]
}
```

```bash
# scripts/build-loop.sh:1665-1667
  elif [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(chore/dev-cycle-[0123456789]{4}-[0123456789]{2}-[0123456789]{2}(-[0123456789]{4})?)\'($|\ into\ |:) ]]; then
    b="${BASH_REMATCH[1]}"
    clean_merge || return 0
```
(excerpt ends :1667; enclosing log_class continues to :1687 — read)

`log_class` starts with `CLASS=other` (`:1651`), so `return 0` leaves the class as other. A conflicting merge-tree exits non-zero. On unrelated histories merge-tree refuses and writes to stderr, and `gate_git` then returns 3 (`[[ ! -s "$GATE_TMP/err" ]] || return 3`, `:946`). Either way `clean_merge` fails.

Probe p1 used fixture `/tmp/u3b2rv-sub-e7m0` at 2026-10-12T23:38:15Z. The command was `timeout 60 bash .../scripts/build-loop.sh --main-log $S`, run in `$T/repo`, and it exited 2. Every cycle record held its own `Branch:` line. The run printed:
- `chore 64902935… Merge branch 'chore/dev-cycle-2026-10-01': control` (control)
- `other f4824153… Merge branch 'chore/dev-cycle-2026-10-02': theirs-conflict`
- `chore e5c36880… Merge branch 'chore/dev-cycle-2026-10-03': theirs-clean` (a clean `-X theirs` merge; the claim's qualifier excludes it)
- `other ed7af3b0… Merge branch 'chore/dev-cycle-2026-10-05': unrelated`

**Evidence:** `scripts/build-loop.sh:1644-1648`, `scripts/build-loop.sh:1651`, `scripts/build-loop.sh:1665-1667`, `scripts/build-loop.sh:942-948`, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p1.out

---

## Claim 53b: "A chore-subject merge whose tree is not merge-tree's clean merge reads other, for [...] octopus [...] merges (`:1644-1648`, `:1666-1667`)"

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:1665-1667`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which line rejects an octopus merge with a chore subject. The outcome (other) is right; the stated mechanism (clean_merge at the cited lines) is wrong. This does not establish anything about gate-subject octopus merges beyond the same parent-count test at `:1657`.

An octopus merge with a chore subject does read other: p1 printed `other 8f5a119d… Merge branch 'chore/dev-cycle-2026-10-04': octopus` for a commit with three parents. The tree check is not what rejects it. The parent-count test on the `elif` comes first:

```bash
# scripts/build-loop.sh:1665
  elif [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(chore/dev-cycle-...
```
(excerpt ends :1665; enclosing log_class continues to :1687 — read)

The one-parent branch (`elif [[ ${#ps[@]} -eq 1 ]]`, `:1674`) does not take it either, so log_class returns with `CLASS=other` and never runs clean_merge. clean_merge could not judge an octopus anyway: it merges only `"${ps[0]}" "${ps[1]}"` (`:1646`). An octopus whose third parent adds nothing could carry exactly that two-parent tree (paraphrased — no quote available because this is an inference from the two-argument call at `:1646`, not a probed case). A reader who trusts clean_merge for octopus merges, and so drops the `-eq 2` guard, would let one through. The precise version: "-X theirs and unrelated-history merges fail clean_merge (`:1644-1648`, `:1667`). An octopus merge fails the two-parent test (`:1665`, and `:1657` for gate)."

**Evidence:** `scripts/build-loop.sh:1646`, `scripts/build-loop.sh:1657`, `scripts/build-loop.sh:1665-1667`, `scripts/build-loop.sh:1674`, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p1.out

---

## Claim 54: "An answers-shaped commit reads other when it adds a NUL-led line, a lone VT line, or a mode change to 100755, even with a valid `Q-001:` line (`:1624-1625`, `:1677`)"

**Submitted by:** security-reviewer
**Location:** `scripts/build-loop.sh:1624-1625`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one-parent commits to docs/working/questions.md that add `Q-001: [1]` together with a `+\0hidden` line, a `+\0` line, a `+ \0` line, a `+\v` line, or a 100644 to 100755 mode change, read by mawk (the only awk on this host). It does not establish gawk's or busybox awk's handling of NUL bytes, which were not installed, or NUL anywhere other than at the start of a line.

The awk's blank test accepts only spaces and tabs, so a line holding NUL or VT falls through to `bad = 1`:

```awk
# scripts/build-loop.sh:1623-1629
  s = substr($0, 1, 1); l = substr($0, 2); sub(/\r$/, "", l)
  if (s != "-" && s != "+") { bad = 1; next }
  if (l ~ /^[ \t]*$/) next
  t = l; sub(/^- /, "", t)
  if (t ~ /^Q-[0123456789]+:/ || tolower(t) ~ /^\*\*answer(:|ed| \()/) { if (s == "+") n++; next }
  if (substr(l, 1, 10) == "**Needs:**") { if (s == "-") r[++nr] = needs(l); else a[++na] = needs(l); next }
  bad = 1
```
(excerpt ends :1629; enclosing ANSWERS_AWK continues to :1631 — read)

The mode is checked on the raw record: `[[ "$meta" =~ ^:100644\ 100644\ [0123456789abcdef]+\ [0123456789abcdef]+\ M$ && ...` (`:1677`), and anything else hits `|| return 0`.

p1 used fixture `/tmp/u3b2rv-sub-e7m0` and the command `timeout 60 bash .../build-loop.sh --main-log $S2` in `$T/repo`, which exited 2. It printed `answers 8b5ea1d2… ctl` for the plain answer, and `other 2740ac38… nul`, `other db7d1257… vt` and `other 24fe3c3c… mode` for the three cases. The mode commit's raw record read `:100644 100755 … M	docs/working/questions.md`. `od -c` showed that diff-tree `--text` passes the bytes through (`+  \0   h   i   d   d   e   n`).

p3 and p4 ran the extracted ANSWERS_AWK under `LC_ALL=C mawk` on that patch:
- `nul.p` (the `+\0hidden` patch): exit 1
- the NUL line removed: exit 0
- `+\0` alone (`nulalone.p`): exit 1
- `+ \0` (`spnul.p`): exit 1

So mawk keeps NUL inside `$0` and does not truncate the line to blank.

**Evidence:** `scripts/build-loop.sh:1612-1631`, `scripts/build-loop.sh:1674-1684`, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p1.out, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p2.out

---

## Claim 55: "E4 (clean_merge after the subject, 4afdd68b) brought the root-SINCE time on a /workspace main clone back to the pre-D1 (1d829fee) level and cut store writes from 87 to 0 vs cca66dc2, with identical output."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:1657-1659`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two root-SINCE runs per version on fresh clones of /workspace main at 34cf382f (1,119 first-parent commits) on this host. Store writes were counted as the change in `git count-objects` loose objects. It does not establish timings on other hosts or under load, or object writes on a history that has gate or chore merges with conflicts.

At HEAD the subject test runs first and clean_merge comes after it: `if [[ ${#ps[@]} -eq 2 && "$SUBJ" =~ ^Merge\ branch\ \'(.+)\'\ \(build-loop\ (self-merge|approved merge)\)$ ]]; then` (`:1657`), followed by `clean_merge || return 0` (`:1659`). The chore branch works the same way (`:1665`, `:1667`).

Probe p5 ran in `/tmp/u3b2rv-sub-perf-Jwpt` from 2026-10-12T23:39:20Z to 23:40:11Z, with load average 0.29-0.66. Each version ran `timeout 120 bash s-<v>/scripts/build-loop.sh --main-log <root>` in its own fresh clone `c-<v>`, and each clone started with 155 loose objects:

| Version | root run 1 | root run 2 | loose after |
|---|---|---|---|
| 1d829fee (pre-D1) | 6,569 ms | 6,526 ms | 155 (+0) |
| cca66dc2 | 7,997 ms | 8,144 ms | 242 (+87) |
| 4afdd68b | 6,468 ms | 6,712 ms | 155 (+0) |

Every run exited 2, printed 1,119 lines and wrote 0 bytes to stderr. `cmp` printed `same-1d-head` and `same-cc-head`, so the outputs are byte-identical. HEAD's output was 1 answers line and 1,117 other lines.

**Evidence:** `scripts/build-loop.sh:1644-1648`, `scripts/build-loop.sh:1657-1667`, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p5.out

---

## Claim 56: "A typical window of 10 commits or fewer costs under 0.45 s, mostly state_start."

**Submitted by:** performance-reviewer
**Location:** `scripts/build-loop.sh:1690-1703`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 10-commit and 0-commit windows at the tip of a /workspace main clone (34cf382f). That window has no gate or chore merges, so no merge-tree ran. It does not establish the cost of windows holding gate or chore merges (each adds a merge-tree and record reads), larger trees, or other hosts. "Mostly state_start" is supported only for the gated startup taken as a whole; state_start was not timed on its own.

`--main-log` runs `state_start` and then `main_log` (`main-log)` / `state_start` / `main_log "${ARGS[0]}" || exit 2`, `:1714-1717`). main_log lists main's whole first-parent history (`gate_git rev-list --first-parent "$MAIN_SHA"`, `:1693`) and runs log_class once per commit above SINCE.

p5 measured HEAD's script:
- N=10: 377, 384 and 373 ms (11 lines, exit 2)
- N=0: 323, 330 and 330 ms

p6 ran `bash s-4afdd68b/scripts/build-loop.sh --state` in `c-4afdd68b`, exit 0: 313, 315 and 318 ms. `--settings` took 33-38 ms. The under-0.45 s figure holds. About 0.31 s of the 0.38 s is the --state path. That path is not state_start alone: it also runs the script's startup and state_gate, and --state adds caller_gate. The roughly 0.06 s left over is main_log's history listing and the 10 log_class calls. The precise version: "a 10-commit window with no gate or chore merge cost about 0.38 s, of which about 0.31 s is the gated startup that --state also runs (state_gate and state_start)."

**Evidence:** `scripts/build-loop.sh:1220-1226`, `scripts/build-loop.sh:1690-1703`, `scripts/build-loop.sh:1714-1717`, /tmp/claude-1000/-workspace/fbda3e17-2975-43f6-8d47-8f94722b03ec/scratchpad/u3b2-sub/p5.out

---

## Claims Requiring Attention

### Incorrect
- **Claim 53b** (`scripts/build-loop.sh:1665`): an octopus merge reads other because of the two-parent test at `:1665` (and `:1657`), not because of clean_merge. clean_merge merges only the first two parents. The outcome is right; cite the parent count for octopus.

### Mostly Accurate
- **Claim 56** (`scripts/build-loop.sh:1690-1703`): about 0.38 s for N=10 holds. "Mostly state_start" should read "mostly the gated startup (state_gate and state_start)", and the measured window had no gate or chore merges.

## Goal-Alignment Note
These verdicts test whether the critics' endorsements of `--main-log`'s fail-closed classification and its per-iteration cost hold. Both security endorsements hold in outcome; one names the wrong guard. Both performance endorsements hold numerically on this host.
