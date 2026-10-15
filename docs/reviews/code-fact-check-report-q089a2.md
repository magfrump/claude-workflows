# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q089 (branch feat/q089a2-cc-push-self-check)
**Commit:** 840f39b0
**Replication:** k=1 (loop pass, decision 031)
**Scope:** `git diff f2533b33 840f39b0` (unit A2, stacked on A1 f2533b33): `devcontainer-config/cc-push.sh`, `test/cc-isolated-functions.bats`, `test/cc-push.bats`, plus commit 840f39b0's message. A1 (f2533b33) and unit B (feat/q089b-host-tool-gate, 6e00137b) read as sibling context only.
**Checked:** 2026-10-14
**Total claims checked:** 21
**Summary:** 17 verified, 2 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

Probe environment, used for every `executed` claim: a `git archive 840f39b0` extract at `/home/node/.claude/jobs/00bcf178/tmp/fc-q089a2.1HvdyN/src`, with `HOME`, `CLAUDE_DEVC_CONFIG_DIR`, `TMPDIR` and `CC_PUSH_CLONES_DIR` pointed at subdirectories of that temp dir and `LC_ALL=C`. Everything ran under `timeout`. The logs are in `docs/reviews/execution-logs/fc-q089a2/`, and the probe script is copied there as `probe.sh`. No real config dir was touched and install.sh was not run.

Hallucination-pattern log: read. Claim 20 (a test count in a commit message) is the same kind of claim as the logged "All 85 tests ... pass" and "mode1-equiv 33" patterns. Both of those were found false. Here it was executed and holds.

---

## Claim 1: "when this installed copy or the cc-gitdir.sh beside it differs from what the bless recorded in host-tools.sha256 (or that file is missing or a symlink), cc-push exits 1 before parsing anything, --help included"

**Location:** `devcontainer-config/cc-push.sh:35-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a changed cc-push.sh, a changed cc-gitdir.sh, both changed, a missing manifest, a symlinked manifest and a manifest that lists a file twice, all with `--help` or real arguments: each exits 1 with `ERROR:` before argument parsing. Does not establish that nothing runs before the exit (see Claim 3). Does not cover the repo-checkout exemption, which exits 0 unchecked by design (Claims 7 and 8).

The check sits ahead of all argument handling:

```bash
# devcontainer-config/cc-push.sh:187-193
CC_PUSH_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
if ! host_tools_err="$(verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh)"; then
  echo "ERROR: $host_tools_err — cc-push refuses to run. Review it, then: cc-isolated --bless" >&2
  exit 1
fi
# shellcheck source=cc-gitdir.sh
source "$CC_PUSH_DIR/cc-gitdir.sh"
```

In the probes, P1 and P2 (cc-push.sh changed), P6 (cc-gitdir.sh changed), P7 (both), P4 (manifest is a symlink) and P8b (duplicate entry) all printed `ERROR: ... refuses to run` on `--help`. The probes that captured a status show `exit=1`. P8b printed the refusal, but its exit status was not captured because of a PIPESTATUS slip in the probe command. Test 48 of cc-push.bats asserts `[ "$status" -eq 1 ]` on `--help` after a cc-push.sh change, and it passed.

**Evidence:** `devcontainer-config/cc-push.sh:152-193`; command `timeout 300 bash fc-q089a2-probe.sh <W>`, cwd `/home/node/.claude/jobs/00bcf178/tmp/fc-q089a2.1HvdyN`, exit 0, 2026-10-15T00:25:55Z, output in `docs/reviews/execution-logs/fc-q089a2/03-probes.log`; `docs/reviews/execution-logs/fc-q089a2/04-probe-duplicate-entry.log`; `docs/reviews/execution-logs/fc-q089a2/01-cc-push-bats.log`

---

## Claim 2: "(decision log row 71)"

**Location:** `devcontainer-config/cc-push.sh:38` (also `:144`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and subject of row 71 in sibling unit B. Does not establish that the row exists in this unit's own tree: it is absent at 840f39b0, at f2533b33 and on main, so the reference dangles until B lands.

`git grep -n '^| 71 '` over `docs/decisions/log.md` finds nothing at 840f39b0, f2533b33 or main. It does find the row on `feat/q089b-host-tool-gate`:

```
# feat/q089b-host-tool-gate:docs/decisions/log.md:94
| 71 | 2026-10-14 | **Host-only tools are their own trust category, amending row 45's scope (Q-083 [1], Q-089).** ... Each entry point checks the host tools it executes before sourcing them (`verify_host_tools`, one copy in `cc-isolated.sh` and `cc-push.sh`, pinned byte for byte by a test). On a mismatch ... `cc-push` refuses.
```

**Evidence:** `feat/q089b-host-tool-gate:docs/decisions/log.md:94`; `840f39b0:docs/decisions/log.md` (no row 71)

---

## Claim 3: "nothing unchecked runs."

**Location:** `devcontainer-config/cc-push.sh:39-40`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which parts of a changed installed cc-push.sh run before and after the check. Does not establish exploitability under the stated threat model (decision log row 45/71: non-targeted host tampering), which row 71 itself accepts.

Bash reads and runs a script one command at a time. Everything above the check therefore runs before it: `set -euo pipefail`, the `unset`, the `safe_path` definition and call, and the definition of `verify_host_tools` itself (`devcontainer-config/cc-push.sh:117-182`). The check then runs PATH-resolved `readlink`, `dirname`, `awk`, `sha256sum` and `cut`. All of this comes from the very file that is being checked. Everything after the `exit 1` never runs.

- P1 inserted `touch <marker>` at line 118 of an installed copy without re-blessing. `--help` exited 1 with "cc-push.sh changed since the last bless", and the log reads `P1 RESULT: prologue code RAN before the refusal`.
- P2 put the same line just after the check's `fi` (:191) and another at EOF. Neither ran (`post-check line did not run`, `EOF line did not run`).
- P3 changed line 188's `if` into `if false; then` and added a payload after the `source`. The copy exited 0 and the payload ran (`self-skipping tamper ran unrefused`).

So a tampered later part of cc-push.sh does not run, but a tampered earlier part does. A tamper that weakens the check (or `verify_host_tools`, which is also defined above it) disables it altogether. Row 71 on unit B lists "a self-skipping tampered cc-push (caught only at the next bless)" and TOCTOU under "Not covered", which contradicts the header's absolute wording. Static note, not probed: bash keeps reading the same file after the check, so an in-place rewrite between the hash and bash's later reads would run bytes that were never hashed. That is the TOCTOU row 71 names.

An accurate version: "nothing past this check runs from a changed copy; the prologue above it runs first, and a change that removes the check is caught only by the launcher or the next bless."

**Evidence:** `devcontainer-config/cc-push.sh:117-193`; command `timeout 300 bash fc-q089a2-probe.sh <W>`, cwd `/home/node/.claude/jobs/00bcf178/tmp/fc-q089a2.1HvdyN`, exit 0, 2026-10-15T00:25:55Z, output `docs/reviews/execution-logs/fc-q089a2/03-probes.log` (P1, P2, P3); `feat/q089b-host-tool-gate:docs/decisions/log.md:94`

---

## Claim 4: "KEEP IN STEP with the copy in cc-isolated.sh (a test compares the two byte for byte)"

**Location:** `devcontainer-config/cc-push.sh:142-143`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parity test's extraction and comparison and its pass at 840f39b0. Does not cover each block's first marker line, which the test drops and which differs between the two files.

The test compares everything from the second line of the marked block through the end marker:

```bash
# test/cc-isolated-functions.bats:930-931
a="$(sed -n '/^# --- verify_host_tools/,/^# --- end verify_host_tools/p' "$CONFIG_SRC/cc-isolated.sh" | tail -n +2)"
b="$(sed -n '/^# --- verify_host_tools/,/^# --- end verify_host_tools/p' "$CONFIG_SRC/cc-push.sh" | tail -n +2)"
```

The dropped first lines differ: `cc-push.sh:142` says "copy in cc-isolated.sh", and `cc-isolated.sh:219` says "copy in cc-push.sh". The comparison is byte for byte over the function and its comment from the second line on, which is what matters. The test passed as `ok 76`. A precise version would say: "a test compares the two byte for byte, from the line after this one."

**Evidence:** `test/cc-isolated-functions.bats:928-935`; `devcontainer-config/cc-isolated.sh:219-259`; `devcontainer-config/cc-push.sh:142-182`; command `timeout 1500 bats test/cc-isolated-functions.bats`, cwd `.../fc-q089a2.1HvdyN/src`, exit 0, 2026-10-15T00:24:46Z, output `docs/reviews/execution-logs/fc-q089a2/02-cc-isolated-functions-bats.log`

---

## Claim 5: "install.sh's bless hashes them into host-tools.sha256, beside manifest.sha256"

**Location:** `devcontainer-config/cc-push.sh:143-145`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers install.sh invoking the bless and the bless computing a manifest over the three host tools in the config dir. Does not re-verify A1's bless internals (the atomic two-manifest write), which are sibling context.

install.sh ends with `CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless` (`devcontainer-config/install.sh:607`). The bless's host list and hashing are:

```bash
# devcontainer-config/cc-isolated.sh:199-217
host_tool_files() {
  echo "cc-exit-scan.sh"
  echo "cc-gitdir.sh"
  echo "cc-push.sh"
}
host_tools_path() {
  echo "$(config_dir)/host-tools.sha256"
}
...
  (cd "$(config_dir)" && sha256sum "${files[@]}")
```

The bare names in the second column are what `verify_host_tools`'s awk `$2 == f` matches (`cc-push.sh:173`).

**Evidence:** `devcontainer-config/install.sh:607`; `devcontainer-config/cc-isolated.sh:199-217`; `devcontainer-config/cc-push.sh:173`

---

## Claim 6: "each entry point checks the files it is about to execute against that file BEFORE sourcing them"

**Location:** `devcontainer-config/cc-push.sh:145-146`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cc-push's own entry point: cc-gitdir.sh is checked before `source`, and cc-push.sh is checked. Does not cover the launcher's entry point (A1 context). Does not establish that cc-push.sh is checked before any of it runs.

cc-gitdir.sh is checked before it is sourced (`cc-push.sh:188` then `:193`, quoted in Claim 1). P6 and test 48 show that a changed cc-gitdir.sh is refused and its appended `touch` never runs. cc-push.sh, however, is not sourced. It is already executing when it checks itself, and lines 117-187 have already run (Claim 3, P1). Tighten to: "checks the files it sources before sourcing them, and its own file before anything past the check."

**Evidence:** `devcontainer-config/cc-push.sh:184-193`; `docs/reviews/execution-logs/fc-q089a2/03-probes.log` (P1, P6); `docs/reviews/execution-logs/fc-q089a2/01-cc-push-bats.log` (ok 48)

---

## Claim 7: "Only a repo checkout is left unchecked, and it must say so positively: install.sh beside the script (install.sh is never installed, it is not in PAYLOAD), no manifest of either kind, and not the config dir."

**Location:** `devcontainer-config/cc-push.sh:147-149`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four-part exemption test and install.sh's absence from PAYLOAD. Does not establish that "positively" means more than a regular file named install.sh: its content is never checked.

```bash
# devcontainer-config/cc-push.sh:157-159
  if [ -f "$dir/install.sh" ] && [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
    return 0
  fi
```

```bash
# devcontainer-config/install.sh:110
PAYLOAD=(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress claude-home)
```

Probe results:

- P5a: install.sh beside the script, no manifests, exit 0, unchecked.
- P5b: adding `manifest.sha256` gives exit 1, "no host-tool manifest".
- P5c: the same dir named as `CLAUDE_DEVC_CONFIG_DIR` gives exit 1.

**Evidence:** `devcontainer-config/cc-push.sh:156-159`; `devcontainer-config/install.sh:110`; `docs/reviews/execution-logs/fc-q089a2/03-probes.log` (P5a-c)

---

## Claim 8: "Anything else is checked, so deleting manifests is not enough to opt an installed copy out."

**Location:** `devcontainer-config/cc-push.sh:149-151`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an installed dir with either manifest deleted, or both. Does not cover an installed dir that also gains a file named install.sh while losing both manifests: that dir is exempt by Claim 7's rule.

Deleting `host-tools.sha256` while `manifest.sha256` remains gives exit 1 (test 48's last step, and P5b). A dir without install.sh is never exempt (`[ -f "$dir/install.sh" ]`, `cc-push.sh:157`). P9 confirms this: without install.sh, the refusal holds even with the manifest clause mutated out.

**Evidence:** `devcontainer-config/cc-push.sh:157-163`; `docs/reviews/execution-logs/fc-q089a2/03-probes.log` (P5b, P9); `docs/reviews/execution-logs/fc-q089a2/01-cc-push-bats.log`

---

## Claim 9: "Prints the reason and returns 1 on any mismatch." / "Every file is checked and every mismatch named"

**Location:** `devcontainer-config/cc-push.sh:151`, `:164-165`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a changed file, a missing or symlinked file, a missing or symlinked manifest, and a duplicate entry. Does not establish where the reason goes. It goes to stdout, which the caller captures into the `ERROR:` line on stderr.

```bash
# devcontainer-config/cc-push.sh:166-180
  local bad=0
  for f in "$@"; do
    if [ ! -f "$dir/$f" ] || [ -L "$dir/$f" ]; then
      echo "$dir/$f is missing or a symlink"
      bad=1
      continue
    fi
    want="$(awk -v f="$f" '$2 == f { n++; h = $1 } END { if (n == 1) print h }' "$m")"
    have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"
    if [ -z "$want" ] || [ "$want" != "$have" ]; then
      echo "$dir/$f changed since the last bless"
      bad=1
    fi
  done
  return "$bad"
```

In P7 (both files changed), a single refusal names both cc-push.sh and cc-gitdir.sh. P8b (cc-push.sh listed twice) is refused as "changed since the last bless".

**Evidence:** `devcontainer-config/cc-push.sh:160-181`; `docs/reviews/execution-logs/fc-q089a2/03-probes.log` (P4, P7); `docs/reviews/execution-logs/fc-q089a2/04-probe-duplicate-entry.log`

---

## Claim 10: "(readlink -f: cc-push on PATH is a symlink to the installed copy). Checked first: a tampered cc-gitdir.sh would run at source time."

**Location:** `devcontainer-config/cc-push.sh:184-186`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the check preceding `source` and symlink resolution to the installed dir. Does not establish protection against a cc-gitdir.sh rewritten between the hash and the `source` (TOCTOU, which row 71 lists as not covered).

install.sh links `ln -sf "$DEST/cc-push.sh" "$BIN_DIR/cc-push"` (`devcontainer-config/install.sh:603`). P6 ran a changed copy through a `bin/cc-push` symlink. The refusal names the installed dir's `cc-gitdir.sh`, so the resolved dir is the one that gets checked. Test 48 appends `touch $M/gitdir-ran` to cc-gitdir.sh and asserts `[ ! -e "$M/gitdir-ran" ]`, and it passed.

**Evidence:** `devcontainer-config/cc-push.sh:187-193`; `devcontainer-config/install.sh:603`; `test/cc-push.bats:803-807`; `docs/reviews/execution-logs/fc-q089a2/03-probes.log` (P6); `docs/reviews/execution-logs/fc-q089a2/01-cc-push-bats.log`

---

## Claim 11: "verify_host_tools is the same code in cc-isolated.sh and cc-push.sh"

**Location:** `test/cc-isolated-functions.bats:928`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function body and all comment lines but the first marker line (see Claim 4). Does not cover whether the two call sites pass the same file lists, and they do not by design.

The test asserts `[ -n "$a" ]`, `[[ "$a" == *"verify_host_tools() {"* ]]` and `[ "$a" = "$b" ]` (`test/cc-isolated-functions.bats:932-934`), and it passed as `ok 76`.

**Evidence:** `test/cc-isolated-functions.bats:928-935`; `docs/reviews/execution-logs/fc-q089a2/02-cc-isolated-functions-bats.log`

---

## Claim 12: "installed copy: cc-push checks itself and cc-gitdir.sh before sourcing, and refuses on a change (row 71)"

**Location:** `test/cc-push.bats:797`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers refusal on a changed cc-gitdir.sh (with a no-run assertion), refusal on a changed cc-push.sh, and refusal on a missing host manifest. Does not establish that a changed cc-push.sh does not run. Its tamper is `printf '\n# edited\n'`, an inert comment, so there is nothing whose running could be observed.

The test passed as `ok 48`. The cc-push.sh step asserts only the status and the message: `[ "$status" -eq 1 ]` and `[[ "$output" == *"cc-push.sh changed since the last bless"* ]]` (`test/cc-push.bats:811-813`).

**Evidence:** `test/cc-push.bats:797-822`; `docs/reviews/execution-logs/fc-q089a2/01-cc-push-bats.log`

---

## Claim 13: "Its own file too: a change to cc-push.sh refuses, --help included (exit 1)."

**Location:** `test/cc-push.bats:809`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an appended change. Does not cover a change above the check, which also refuses but runs first (Claim 3).

`run bash "$d/cc-push.sh" --help` then `[ "$status" -eq 1 ]` (`test/cc-push.bats:811-812`), and it passed. P2 shows the same behaviour.

**Evidence:** `test/cc-push.bats:809-813`; `docs/reviews/execution-logs/fc-q089a2/03-probes.log` (P2)

---

## Claim 14: "Deleting the host manifest does not turn the installed copy into a repo checkout."

**Location:** `test/cc-push.bats:816`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the behaviour stated. Does not establish that this step pins the exemption's `manifest.sha256` clause. `$d` holds no install.sh, so the step passes even with that clause removed (P9). That clause is pinned by A1's `verify_host_tools: repo checkout unchecked...` test on the launcher copy, carried over by the parity test.

P9 mutated `&& [ ! -e "$dir/manifest.sha256" ]` out of the copy (grep count 0), ran the test's final step, and still got exit 1 "no host-tool manifest". A1's test does `touch "$d/manifest.sha256"` with install.sh present and asserts status 1 (`test/cc-isolated-functions.bats:898-902`).

**Evidence:** `test/cc-push.bats:816-821`; `test/cc-isolated-functions.bats:886-927`; `docs/reviews/execution-logs/fc-q089a2/03-probes.log` (P9)

---

## Claim 15: "runs it after its set/unset/safe_path prologue and before sourcing cc-gitdir.sh"

**Location:** commit 840f39b0 message, paragraph 1
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of statements. Does not establish that the prologue is protected by the check: it is not (Claim 3).

`set -euo pipefail` (:117), `unset GIT_DIR ...` (:120-121), `safe_path` (:140), check (:187-191), `source` (:193).

**Evidence:** `devcontainer-config/cc-push.sh:117-193`

---

## Claim 16: "On a mismatch, or with host-tools.sha256 missing or a symlink, it exits 1 with an ERROR: line before parsing anything, --help included."

**Location:** commit 840f39b0 message, paragraph 1
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 1.

The `echo "ERROR: $host_tools_err — cc-push refuses to run..." >&2; exit 1` path is quoted in Claim 1 (`cc-push.sh:188-190`). The probes are P1, P4 and P7, and the test is ok 48.

**Evidence:** `devcontainer-config/cc-push.sh:188-190`; `docs/reviews/execution-logs/fc-q089a2/03-probes.log`

---

## Claim 17: "An installed copy cannot opt out by deleting manifests: only a positively marked repo checkout is unchecked."

**Location:** commit 840f39b0 message, paragraph 1
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claims 7 and 8. The "positive mark" is any regular file named install.sh.

The condition quoted in Claim 7 (`cc-push.sh:157`) is backed by P5a-c and P9.

**Evidence:** `devcontainer-config/cc-push.sh:157-159`; `docs/reviews/execution-logs/fc-q089a2/03-probes.log`

---

## Claim 18a: "Tests: a tampered cc-gitdir.sh ... [is] refused without running"

**Location:** commit 840f39b0 message, paragraph 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an appended tamper to cc-gitdir.sh. Does not cover TOCTOU.

`printf 'touch %q\n' "$M/gitdir-ran" >> "$d/cc-gitdir.sh"` is followed by `[ ! -e "$M/gitdir-ran" ]` (`test/cc-push.bats:803-807`), and it passed.

**Evidence:** `test/cc-push.bats:803-807`; `docs/reviews/execution-logs/fc-q089a2/01-cc-push-bats.log`

---

## Claim 18b: "Tests: ... a tampered cc-push.sh [is] refused without running"

**Location:** commit 840f39b0 message, paragraph 2
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test asserts and what a tampered cc-push.sh runs. Does not judge whether the gap matters under row 45's threat model.

The test's cc-push.sh tamper is `printf '\n# edited\n' >> "$d/cc-push.sh"` (`test/cc-push.bats:810`). That is a comment at EOF, and the step asserts only status 1 and the message, with no no-run marker. The test therefore cannot show "without running". In general the claim is false: a tampered cc-push.sh whose change sits above the check runs that change before refusing (P1: `prologue code RAN before the refusal`). A change that disables the check is not refused at all (P3, exit 0). "Without running" holds only for changes past line 191 (P2). An accurate version: "a tampered cc-gitdir.sh is refused without running; a changed cc-push.sh is refused."

**Evidence:** `test/cc-push.bats:809-813`; `docs/reviews/execution-logs/fc-q089a2/03-probes.log` (P1, P2, P3)

---

## Claim 19: "deleting the host manifest is refused, and the parity test"

**Location:** commit 840f39b0 message, paragraph 2
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tests existing and passing. Does not cover the step's limit described in Claim 14.

`test/cc-push.bats:816-821` asserts `[[ "$output" == *"no host-tool manifest"* ]]`, and the parity test is at `test/cc-isolated-functions.bats:928`. Both passed.

**Evidence:** `test/cc-push.bats:816-821`; `test/cc-isolated-functions.bats:928-935`; logs 01 and 02 in `docs/reviews/execution-logs/fc-q089a2/`

---

## Claim 20: "Tests under LC_ALL=C: cc-push 48/48, cc-isolated-functions all pass."

**Location:** commit 840f39b0 message, paragraph 3
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers these two suites at 840f39b0 under LC_ALL=C, in a redirected environment. Does not cover other suites or the default locale.

Running cc-push.bats printed `1..48`, 48 `ok` lines and no `not ok` (exit 0). Running cc-isolated-functions.bats printed `1..181`, 181 `ok` lines and no `not ok` (exit 0). This is the same kind of test-count claim as two logged hallucination patterns. Here it holds.

**Evidence:** command `timeout 900 bats test/cc-push.bats`, cwd `/home/node/.claude/jobs/00bcf178/tmp/fc-q089a2.1HvdyN/src`, exit 0, 2026-10-15T00:24:33Z, output `docs/reviews/execution-logs/fc-q089a2/01-cc-push-bats.log`; command `timeout 1500 bats test/cc-isolated-functions.bats`, same cwd and env, exit 0, output `docs/reviews/execution-logs/fc-q089a2/02-cc-isolated-functions-bats.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 3** (`devcontainer-config/cc-push.sh:39-40`): "nothing unchecked runs" is false. Lines 117-191 of a changed cc-push.sh run before the check (P1), and a change that disables the check runs unrefused (P3). Only content past the check is held back. Reword to match row 71's own "Not covered" list.
- **Claim 18b** (commit 840f39b0 message): "a tampered cc-push.sh [is] refused without running" is false. The test's tamper is an inert comment with no no-run assertion, and a tamper above the check does run (P1). Say "refused" only.

### Mostly Accurate
- **Claim 4** (`devcontainer-config/cc-push.sh:142-143`): the parity test drops each block's first line (`tail -n +2`), and those lines differ. "Byte for byte" holds from the second line on.
- **Claim 6** (`devcontainer-config/cc-push.sh:145-146`): cc-gitdir.sh is checked before sourcing. cc-push.sh is not sourced, and it is checked only after its own prologue has run.

---

## Goal-Alignment Note

The goal is for cc-push to check itself and cc-gitdir.sh against host-tools.sha256 before sourcing cc-gitdir.sh, to exit 1 before parsing (`--help` included), and to exempt only a positively marked repo checkout. The code does all of this: Claims 1, 7-10 and 16-17 were executed and Verified. The gap is in what the documentation promises. On whether a tampered later part of cc-push.sh runs: it does not, because bash stops at the `exit 1` (P2). A tampered earlier part does run, and a tamper that removes the check is not caught by cc-push at all (P1, P3). Decision log row 71 (unit B) states this as accepted under the non-targeted-tampering threat model. The cc-push.sh header ("nothing unchecked runs") and the commit message ("refused without running") claim more than that. The fix is to reword the comment and the message, not the code. One more point: the "decision log row 71" references in this unit resolve only once sibling unit B lands.
