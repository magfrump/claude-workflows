# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q089 (branch feat/q089a2b-cc-push-self-check)
**Commit:** cc2640b7
**Replication:** k=1 (loop pass, decision 031)
**Scope:** `git diff 4be0445d cc2640b7`, the A2 iteration-1 fixes (2cb03f23, cc2640b7): `devcontainer-config/cc-push.sh` and `test/cc-push.bats`, the messages of 2cb03f23 and cc2640b7, and the "Fixed" statuses A1-A3 in `docs/reviews/code-review-rubric-2026-10-14-feat-q089a2-cc-push-self-check.md`. Committed context, read but not verdicted: A1 at b3b37e16 (`devcontainer-config/cc-isolated.sh`) and A2's original commit 4be0445d. Unit B (feat/q089b3-host-tool-gate) is sibling context.
**Checked:** 2026-10-14
**Total claims checked:** 15
**Summary:** 7 verified, 6 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

**Probe environment** (used for every `executed` claim): a `git archive cc2640b7` extract at `/home/node/.claude/jobs/00bcf178/tmp/fc-q089a2-it2.SlCGpe/src`, plus a `git archive 2cb03f23` extract at `.../src-2cb` for claim 13. `HOME`, `CLAUDE_DEVC_CONFIG_DIR`, `TMPDIR` and `CC_PUSH_CLONES_DIR` pointed at subdirectories of that temp dir, and everything ran with `LC_ALL=C` under `timeout`. The installed layout for the probes is `.../inst dir`: a copy of `devcontainer-config/` without install.sh. The space in the name is deliberate, to exercise `%q`. The logs and probe scripts are in `docs/reviews/execution-logs/fc-q089a2-it2/`. No real config dir was touched, install.sh was not run, and no probe process was left running (checked with `ps` after the last probe).

**Hallucination-pattern log:** read. Claims 13 and 15 are test-count claims in commit messages, the same kind as the logged "All 85 tests ... pass" and "mode1-equiv 33" patterns. Both were executed here and both hold. Neither Incorrect verdict below is a fabricated symbol or API, so no log entry is added.

---

## Claim 1: "when this installed copy or the cc-gitdir.sh beside it differs from what the bless recorded in host-tools.sha256 (or that file is missing or a symlink), cc-push exits 1 before parsing anything, --help included"

**Location:** `devcontainer-config/cc-push.sh:35-38`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exit-1-before-parsing behaviour for a changed file, a missing manifest, an unreadable manifest, a malformed manifest and an empty manifest, all under `--help`. It does not establish that the header's list of conditions is complete: it omits the unreadable or malformed manifest that cc2640b7 added.

The exit-1-before-parsing part holds for every condition probed. The list of conditions is incomplete. Since cc2640b7, a manifest that is unreadable or malformed refuses through its own branch:

```bash
# devcontainer-config/cc-push.sh:170-173
  if [ ! -r "$m" ] || grep -qvE '^[0-9a-f]{64}  [A-Za-z0-9._-]+$' "$m"; then
    echo "host-tool manifest $m is unreadable or malformed: inspect it before any bless overwrites it"
    return 1
  fi
```

The header names only "differs", "missing" and "a symlink". Executed, with `--help` exiting 1 in every case: a changed cc-gitdir.sh (P1), a missing manifest (P3), a CRLF manifest and a chmod-000 manifest (P4), and an empty manifest (log 06). The precise version adds "unreadable or malformed" to the parenthesis.

Command: `timeout 400 bash probe.sh <probe root>`, cwd `/home/node/.claude/jobs/00bcf178/tmp/fc-q089a2-it2.SlCGpe`, exit 0, 2026-10-15T00:48:35Z. The empty-manifest run is in log 06 (00:49:48Z, exit 1 from cc-push).

**Evidence:** `devcontainer-config/cc-push.sh:35-38`, `devcontainer-config/cc-push.sh:164-173`, `docs/reviews/execution-logs/fc-q089a2-it2/03-probes.log`, `docs/reviews/execution-logs/fc-q089a2-it2/06-empty-manifest.log`

---

## Claim 2: "What that guards: cc-gitdir.sh, and every line of this file below the check (all the push logic)."

**Location:** `devcontainer-config/cc-push.sh:38-40`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a tampered cc-gitdir.sh and a tampered line directly below the check, with the check in place. It does not establish protection against the file being rewritten while it runs: bash reads the script incrementally, so a rewrite between the check and a later line is a concurrent race that was not tested.

The check sits before the `source` and before every function and the main guard below it:

```bash
# devcontainer-config/cc-push.sh:197-208
CC_PUSH_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
if ! host_tools_err="$(verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh)"; then
  {
    ...
  } >&2
  exit 1
fi
# shellcheck source=cc-gitdir.sh
source "$CC_PUSH_DIR/cc-gitdir.sh"
```

(Excerpt elides :199-204, the refusal body, which is quoted in claim 8 — read.)

- **cc-gitdir.sh:** in P1, a `touch` appended to cc-gitdir.sh did not run ("gitdir-ran exists? no"), and cc-push exited 1.
- **A line below the check:** this needs a discriminating placement, because claim 10 shows that a line at EOF is never reached. Log 05 places a `touch` at :198, directly below where the check sits. With the check deleted, it ran (`marker=RAN`). With the check present, P5 and the bats test show any change to cc-push.sh refusing at :198, before line 199 is read.

Commands: `probe.sh` (03, exit 0, 00:48:35Z) and `timeout 120 bash probe8.sh <root>` (05, exit 0, 00:49:34Z), both from cwd `/home/node/.claude/jobs/00bcf178/tmp/fc-q089a2-it2.SlCGpe`.

**Evidence:** `devcontainer-config/cc-push.sh:197-208`, `docs/reviews/execution-logs/fc-q089a2-it2/03-probes.log`, `docs/reviews/execution-logs/fc-q089a2-it2/05-mutation-not-ran.log`

---

## Claim 3: "It cannot guard the lines above the check, nor an overwrite that drops it"

**Location:** `devcontainer-config/cc-push.sh:40-41`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a line inserted above the check (at :121) and an overwrite that replaces the check block (:198-206). It does not establish which other edits above the check could neutralise it, for example an edit inside `verify_host_tools`. None was enumerated.

- **P5:** a `touch` inserted at line 121 ran ("above-ran exists? yes"), and cc-push then still refused with exit 1 and "cc-push.sh changed since the last bless".
- **P6b:** with lines 198-206 replaced by a `touch`, `--help` exited 0 with empty stderr and the touch ran:

```
# docs/reviews/execution-logs/fc-q089a2-it2/04-probe-drop-check.log
[exit=0] stderr:
drop-ran exists? yes
```

Commands: `probe.sh` (03, exit 0, 00:48:35Z) and `timeout 60 bash probe6b.sh <root>` (04, exit 0, 00:48:52Z), cwd as above.

**Evidence:** `devcontainer-config/cc-push.sh:40-41`, `docs/reviews/execution-logs/fc-q089a2-it2/03-probes.log`, `docs/reviews/execution-logs/fc-q089a2-it2/04-probe-drop-check.log`

---

## Claim 4: "a tampered copy that skips its own check is caught only by cc-isolated's warning at the next launch and by `cc-isolated --list`"

**Location:** `devcontainer-config/cc-push.sh:41-42`
**Type:** Architectural / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the installed layout where the launcher and cc-push share a directory and `CLAUDE_DEVC_CONFIG_DIR` names it. It does not establish detection when the launcher run is a different copy (a repo checkout, or a second install), or when `--list`'s config_dir() is not cc-push's directory.

The launcher checks cc-push.sh in its own directory, not cc-push's, and only for actions other than bless and list:

```bash
# devcontainer-config/cc-isolated.sh:768-770 (A1 context, b3b37e16)
  if [ "$action" != "bless" ] && [ "$action" != "list" ] \
     && ! push_err="$(verify_host_tools "$CC_ISOLATED_DIR" cc-push.sh)"; then
    echo "WARNING: $push_err — do not run cc-push until you have reviewed it and re-blessed." >&2
```

`--list` checks `cfg_real`, the resolved config_dir() (`cc-isolated.sh:496-498`).

- **Same directory:** with the check-free copy installed, `--probe-only` printed the WARNING and `--list` printed "Host tools — CHANGED" (P6).
- **Different copy:** the repo-checkout launcher, run against the same workspace, printed no warning, because it checks its own directory (P6, last run).

The precise version: "caught by the warning of a launcher installed beside it, and by `--list` when CLAUDE_DEVC_CONFIG_DIR names this directory."

A side observation, outside A2's diff. For this copy, `--list` says "cc-push refuses: ... changed since the last bless" (`cc-isolated.sh:510`), yet the copy does not refuse: P6b shows it exiting 0. This wording is A1's.

**Evidence:** `devcontainer-config/cc-isolated.sh:496-510`, `devcontainer-config/cc-isolated.sh:707`, `devcontainer-config/cc-isolated.sh:768-770`, `docs/reviews/execution-logs/fc-q089a2-it2/03-probes.log`

---

## Claim 5: "DIR is the directory to check: an entry point's own resolved directory (`--list` passes config_dir())."

**Location:** `devcontainer-config/cc-push.sh:149-150`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three callers that pass DIR: cc-push, the launcher's top level and `--list`. It does not establish the main()-time calls in the launcher (:756, :769), which pass `CC_ISOLATED_DIR` as well.

The entry points pass their own resolved directories:

- cc-push: `CC_PUSH_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"` (`cc-push.sh:197`).
- The launcher: `CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"` (`cc-isolated.sh:707`).

`--list` passes `cfg_real`, not config_dir() itself:

```bash
# devcontainer-config/cc-isolated.sh:496-498
  cfg_real="$(readlink -f -- "$(config_dir)")" || cfg_real="$(config_dir)"
  lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true
  perr="$(verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh)" || true
```

The precise version: "`--list` passes config_dir(), resolved." The difference matters for the exemption's `[ "$dir" != "$cfg" ]` test (:161), which compares resolved paths.

**Evidence:** `devcontainer-config/cc-push.sh:149-150`, `devcontainer-config/cc-push.sh:161`, `devcontainer-config/cc-push.sh:197`, `devcontainer-config/cc-isolated.sh:496-498`, `devcontainer-config/cc-isolated.sh:707`

---

## Claim 6: Rubric A2 "Fixed": the refusal's bless hint now names the directory, `CLAUDE_DEVC_CONFIG_DIR=<CC_PUSH_DIR> cc-isolated --bless`, so a custom install is not sent to bless the default directory

**Location:** `devcontainer-config/cc-push.sh:165`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every refusal shape cc-push prints: changed, missing, malformed, unreadable and empty. It does not establish whether the launcher's refusals carry the same residue. The reason line comes from the shared, parity-pinned `verify_host_tools`, so they likely do, but they were not probed here.

The hint line names the directory in every refusal. In the missing-manifest case, though, the reason line above it still carries the bare form that A2 was raised against:

```
# docs/reviews/execution-logs/fc-q089a2-it2/03-probes.log (P3)
ERROR: cc-push refuses to run:
  no host-tool manifest at .../inst dir/host-tools.sha256 (re-run install.sh, or cc-isolated --bless after reviewing)
Review the host tools in .../inst dir, then re-bless (it prints what changed):
    CLAUDE_DEVC_CONFIG_DIR=.../inst\ dir cc-isolated --bless
```

The bare form comes from `devcontainer-config/cc-push.sh:165`: `echo "no host-tool manifest at $m (re-run install.sh, or cc-isolated --bless after reviewing)"`.

The refusal now offers two bless commands, and the first, bare one blesses the default directory. The fix is right for the hint line and incomplete for this reason line. The line sits in the parity-pinned block, so changing it means changing A1's copy as well.

Command: `probe.sh`, cwd `/home/node/.claude/jobs/00bcf178/tmp/fc-q089a2-it2.SlCGpe`, exit 0, 2026-10-15T00:48:35Z.

**Evidence:** `devcontainer-config/cc-push.sh:164-167`, `devcontainer-config/cc-push.sh:202-203`, `docs/reviews/execution-logs/fc-q089a2-it2/03-probes.log`

---

## Claim 7: "The manifest itself is the anomaly when it cannot be read or is not sha256sum's own output; say so rather than call every tool changed."

**Location:** `devcontainer-config/cc-push.sh:168-169`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a CRLF manifest, an unreadable (mode 000) manifest and an empty manifest, all under LC_ALL=C. It does not establish the regex's behaviour under other locales, where bracket ranges are locale-dependent, nor a run as root, where `-r` is always true.

- **Malformed and unreadable:** both print "host-tool manifest ... is unreadable or malformed: inspect it before any bless overwrites it" (P4).
- **Empty:** an empty manifest is not output sha256sum would produce for one or more files. `grep -v` on an empty file selects nothing, so the branch at :170 is skipped and every tool is called changed:

```
# docs/reviews/execution-logs/fc-q089a2-it2/06-empty-manifest.log
ERROR: cc-push refuses to run:
  .../inst dir/cc-push.sh changed since the last bless
.../inst dir/cc-gitdir.sh changed since the last bless
```

So the empty case does what the comment says the check avoids. This still fails closed.

Commands: `probe.sh` (03, 00:48:35Z) and the log-06 command (00:49:48Z, cc-push exit 1), cwd `/home/node/.claude/jobs/00bcf178/tmp/fc-q089a2-it2.SlCGpe`.

**Evidence:** `devcontainer-config/cc-push.sh:168-173`, `docs/reviews/execution-logs/fc-q089a2-it2/03-probes.log`, `docs/reviews/execution-logs/fc-q089a2-it2/06-empty-manifest.log`

---

## Claim 8: Commit 2cb03f23 and rubric A2: "the refusal puts one reason per line under 'ERROR: cc-push refuses to run:'"

**Location:** `devcontainer-config/cc-push.sh:199-201`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal's layout with one reason and with two. It does not establish the launcher's layout (`cc-isolated.sh:748` uses the same `printf` form), which is A1's.

Each reason is on its own line, but only the first is indented under the ERROR line:

```bash
# devcontainer-config/cc-push.sh:199-201
  {
    echo "ERROR: cc-push refuses to run:"
    printf '  %s\n' "$host_tools_err"
```

`$host_tools_err` is one multi-line string, so `printf` applies its two-space indent once. With both files changed (log 06), the second reason prints flush left, at the same depth as the "Review the host tools" line.

With a single reason, the layout is as described (P1, P3, P4).

**Evidence:** `devcontainer-config/cc-push.sh:199-204`, `docs/reviews/execution-logs/fc-q089a2-it2/06-empty-manifest.log`, `docs/reviews/execution-logs/fc-q089a2-it2/03-probes.log`

---

## Claim 9: "Review the host tools in $CC_PUSH_DIR, then re-bless (it prints what changed): CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless"

**Location:** `devcontainer-config/cc-push.sh:202-203`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hint run verbatim in a full installed layout, with a space in the directory name and the matching launcher as `cc-isolated` on PATH: it blesses CC_PUSH_DIR, prints the diff, and clears the refusal. It does not establish success in a directory that lacks the boundary payload (where `compute_manifest` would fail with "nothing blessed"), nor with a different cc-isolated version first on PATH.

```bash
# devcontainer-config/cc-push.sh:202-203
    echo "Review the host tools in $CC_PUSH_DIR, then re-bless (it prints what changed):"
    printf '    CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless\n' "$CC_PUSH_DIR"
```

In P2, the printed hint (`CLAUDE_DEVC_CONFIG_DIR=.../inst\ dir cc-isolated --bless`) was extracted from cc-push's own stderr and run through `bash -c`. It printed "Changed since the last bless (host-tools.sha256):" with the old and new cc-gitdir.sh lines, and exited 0. The next `cc-push --help` exited 0.

The bless writes to the named directory because `host_tools_path` is `$(config_dir)/host-tools.sha256` (`cc-isolated.sh:205-207`), and config_dir() reads `CLAUDE_DEVC_CONFIG_DIR` (`cc-isolated.sh:68-70`).

Command: `probe.sh`, cwd `/home/node/.claude/jobs/00bcf178/tmp/fc-q089a2-it2.SlCGpe`, exit 0, 2026-10-15T00:48:35Z.

**Evidence:** `devcontainer-config/cc-push.sh:202-203`, `devcontainer-config/cc-isolated.sh:68-70`, `devcontainer-config/cc-isolated.sh:205-207`, `devcontainer-config/cc-isolated.sh:276-314`, `docs/reviews/execution-logs/fc-q089a2-it2/03-probes.log`

---

## Claim 10: "A tamper below the check (where all the push logic is) never runs." with `[ ! -e "$M/push-tamper-ran" ]`

**Location:** `test/cc-push.bats:811-817`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the not-ran assertion can fail, that is, whether it tests the check. It does not dispute the test's other assertions (status 1, the message, the hint), which do fail when the check is removed.

The comment's conclusion holds: the touch never runs. Its mechanism is refuted: the check is not what stops it. The tamper is appended at EOF:

```bash
# test/cc-push.bats:811-812
  # A tamper below the check (where all the push logic is) never runs.
  printf 'touch %q\n' "$M/push-tamper-ran" >> "$d/cc-push.sh"
```

Every path through cc-push exits at the main-execution guard, before EOF:

```bash
# devcontainer-config/cc-push.sh:586-596
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  ...
  case "$rc" in
    0|1|2) exit "$rc" ;;
    130) echo "ERROR: cc-push was interrupted." >&2; exit 1 ;;
    *) echo "ERROR: cc-push stopped on an unexpected failure (status $rc)." >&2; exit 1 ;;
  esac
fi
```

(Excerpt elides :587-590, the trap and subshell — read.)

The mutation probe (log 05) deleted the check block :198-206 and applied the test's exact tamper. The marker stayed absent for `--help` (exit 0), a bad flag (exit 2) and a push invocation (exit 1). With the check gone, line 817 still passes.

The same `touch` placed at :198 instead ran (`marker=RAN`). That is a placement at which the assertion would discriminate.

Command: `timeout 120 bash probe8.sh <root>`, cwd `/home/node/.claude/jobs/00bcf178/tmp/fc-q089a2-it2.SlCGpe`, exit 0, 2026-10-15T00:49:34Z.

**Evidence:** `test/cc-push.bats:811-817`, `devcontainer-config/cc-push.sh:586-596`, `docs/reviews/execution-logs/fc-q089a2-it2/05-mutation-not-ran.log`

---

## Claim 11: `[[ "$output" == *"CLAUDE_DEVC_CONFIG_DIR=$d cc-isolated --bless"* ]]` (the hint names the directory)

**Location:** `test/cc-push.bats:816`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the hint's presence for the bats temp directory. It does not establish `%q` quoting: `$d` holds no shell-special characters, so `%q` leaves it unchanged. P1 and P2 cover the quoted case.

The assertion passes (test 48, log 01). If the line printed a bare `cc-isolated --bless`, the pattern would not match. `%q` with a spaced directory gives `inst\ dir` (P1).

**Evidence:** `test/cc-push.bats:816`, `docs/reviews/execution-logs/fc-q089a2-it2/01-cc-push-bats.log`, `docs/reviews/execution-logs/fc-q089a2-it2/03-probes.log`

---

## Claim 12: Commit 2cb03f23 "A3: the self-tamper test appends a touch below the check and asserts it never ran", and rubric A3 "Fixed" ("A tampered cc-push.sh is refused without running" now tested)

**Location:** `test/cc-push.bats:811-817`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the A3 fix makes the not-running half of "refused without running" tested. It does not dispute that the refusal half is tested: status 1 and the message at :814-815 fail on a check-free copy.

Read literally, the sentence is true: a touch is appended and absence is asserted. The property A3 asked for is still untested. The appended line sits after the exit at cc-push.sh:586-596, so it cannot run with the check or without it. Claim 10 has the quoted code and the mutation probe (log 05: check deleted, marker absent).

A3's stated defect was "the test's tamper was an inert comment". The replacement tamper is also inert, by position rather than content. The rubric's "Fixed" status therefore does not hold for the not-running half.

**Evidence:** `test/cc-push.bats:811-817`, `devcontainer-config/cc-push.sh:586-596`, `docs/reviews/execution-logs/fc-q089a2-it2/05-mutation-not-ran.log`

---

## Claim 13: Commit 2cb03f23 "cc-push 48/48 under LC_ALL=C."

**Location:** `test/cc-push.bats:1`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cc-push suite at 2cb03f23 under LC_ALL=C in this sandbox. It does not establish the cc-isolated-functions suite at that commit, which the message does not claim.

48 `ok` lines and 0 `not ok` lines; the last is "ok 48 installed copy: cc-push checks itself and cc-gitdir.sh before sourcing, and refuses on a change (row 71)".

Command: `timeout 600 bats test/cc-push.bats`, cwd `.../fc-q089a2-it2.SlCGpe/src-2cb` (`git archive 2cb03f23`), exit 0, 2026-10-15 (log 07).

**Evidence:** `docs/reviews/execution-logs/fc-q089a2-it2/07-cc-push-bats-2cb03f23.log`

---

## Claim 14: Commit cc2640b7 "Keeps cc-push's copy byte-identical to the launcher's after A1 iteration 1 (b3b37e16)"

**Location:** `devcontainer-config/cc-push.sh:145-192`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the delimited blocks `# --- verify_host_tools` .. `# --- end verify_host_tools` in both files at cc2640b7, after the first line. It does not establish identity of the first comment line, which differs by design (each names the other file).

Both blocks are 48 lines long. `diff` of the two, with line 1 dropped, exits 0. The full-block diff shows only line 1:

```
# docs/reviews/execution-logs/fc-q089a2-it2/02-parity.log
1c1
< # --- verify_host_tools: KEEP IN STEP with the copy in cc-push.sh (a test
---
> # --- verify_host_tools: KEEP IN STEP with the copy in cc-isolated.sh (a test
```

The pinning test "verify_host_tools is the same code in cc-isolated.sh and cc-push.sh" (`test/cc-isolated-functions.bats:928`) passes.

Command: block extraction and diff, then `timeout 300 bats -f 'byte|parity|step|same' test/cc-isolated-functions.bats`. cwd `.../fc-q089a2-it2.SlCGpe/src`, exit 0, 2026-10-15T00:47:55Z.

**Evidence:** `devcontainer-config/cc-push.sh:145-192`, `devcontainer-config/cc-isolated.sh:219-266`, `test/cc-isolated-functions.bats:928-935`, `docs/reviews/execution-logs/fc-q089a2-it2/02-parity.log`

---

## Claim 15: Commit cc2640b7 "Parity test and cc-push 48/48 under LC_ALL=C."

**Location:** `test/cc-push.bats:1`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cc-push suite and the parity test at cc2640b7 under LC_ALL=C. It does not establish the rest of cc-isolated-functions.bats, which was not run in this pass.

The cc-push suite gave 48 `ok` lines and exit 0 (log 01). The parity test passes (log 02, test 4 of the filtered run).

Command: `timeout 600 bats test/cc-push.bats`, cwd `.../fc-q089a2-it2.SlCGpe/src`, exit 0. Timestamp at the head of log 01.

**Evidence:** `docs/reviews/execution-logs/fc-q089a2-it2/01-cc-push-bats.log`, `docs/reviews/execution-logs/fc-q089a2-it2/02-parity.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`test/cc-push.bats:811-817`): the `push-tamper-ran` touch is appended after cc-push's exiting main guard (:586-596), so the not-ran assertion passes even with the check deleted (log 05). Placing the touch directly below the check, at the `CC_PUSH_DIR=` line or the `source` line, makes it discriminate.
- **Claim 12** (commit 2cb03f23 / rubric A3 "Fixed"): A3's not-running half is still untested. The new tamper is inert by position, as the old one was by content.

### Mostly Accurate
- **Claim 1** (`cc-push.sh:35-38`): the header's list of conditions omits the unreadable or malformed manifest that cc2640b7 added.
- **Claim 4** (`cc-push.sh:41-42`): the launcher's warning and `--list` catch a check-free copy only when the launcher shares cc-push's directory and CLAUDE_DEVC_CONFIG_DIR names it. Side note: `--list` then says "cc-push refuses", which is untrue for that copy (A1's text).
- **Claim 5** (`cc-push.sh:149-150`): `--list` passes the resolved config_dir() (`cfg_real`).
- **Claim 6** (`cc-push.sh:165`): the missing-manifest reason line still prints a bare `cc-isolated --bless`, alongside the dir-naming hint. It is in the parity-pinned block, so the fix is shared with A1.
- **Claim 7** (`cc-push.sh:168-169`): an empty manifest bypasses the malformed branch and every tool is called changed (it still fails closed).
- **Claim 8** (`cc-push.sh:199-201`): with two or more reasons, only the first is indented, because `printf '  %s\n'` gets one multi-line string.

---

## Goal-Alignment Note

The goal is a security-sensitive integrity check on cc-push, reviewed before it merges. The iteration-1 fixes deliver what matters most.

**What works:**
- **The header is honest.** It now says what the check guards and what it cannot, and both halves hold under execution (claims 2 and 3).
- **The bless hint works.** It names the directory and, run verbatim, clears the refusal on a spaced install path (claim 9).
- **The parity copy is exact** (claim 14).

**What is still open:**
- **Test assurance (Incorrect, claims 10 and 12).** The regression test for "a tampered cc-push.sh does not run" still cannot fail on the not-running half, because the tamper sits after an unconditional exit. A future change that moved the check below the push logic, or dropped cc-push.sh from its file list, would be caught only by the status and message assertions, not by the not-ran assertion meant to guard it. Moving the touch directly below the check would restore the assertion's power.
- **Honesty and usability (Mostly accurate, claims 1, 4-8).** None of these is a fail-open: every probed anomaly exits 1. The one closest to A2's original defect is claim 6: a missing manifest still shows a bare bless command, which on a custom install blesses the wrong directory.
