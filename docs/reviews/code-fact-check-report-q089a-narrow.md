# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q089 (branch feat/q089a2b-cc-push-self-check)
**Commit:** 88994fe9
**Replication:** k=1 (narrow check, Q-148 [1])
**Scope:** `git show 88994fe9` only (diff vs 3164f1d5): `devcontainer-config/cc-isolated.sh`, `devcontainer-config/cc-push.sh`, `test/cc-isolated-functions.bats`, and the commit message. Everything before 3164f1d5 is treated as reviewed context.
**Checked:** 2026-10-14
**Total claims checked:** 9
**Summary:** 8 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Probe environment: `git archive 88994fe9` (whole tree) extracted into fresh `mktemp -d` dirs under `/home/node/.claude/jobs/00bcf178/tmp/fcnarrow.RoLC0y/`, with `HOME`, `TMPDIR`, `CC_PUSH_CLONES_DIR`, `CLAUDE_DEVC_CONFIG_DIR` redirected inside it, `LC_ALL=C`, a stub `devcontainer` first on PATH, each suite under `timeout 600`. install.sh was not run, and no real config dir was touched (`/home/node/.config/claude-devcontainer` absent after the run). Script: `docs/reviews/execution-logs/q089a-narrow-probe.sh`; summary: `docs/reviews/execution-logs/q089a-narrow-probe-summary.log`. Run window 2026-10-15T02:56:07Z to 03:01:30Z (UTC; 2026-10-14 local). Nothing was left running (checked with `pgrep -af fcnarrow`).

Hallucination-pattern log read first. The one relevant pattern is a commit message stating a wrong test-count denominator ("85 tests" when there were 97; "mode1-equiv 33" when there were 25). Claim 8 below is checked against it.

---

## Claim 1: "Every file it is given is checked and every mismatch named. (A caller that checks only some host tools does not see the others: the bless prints them.)" (cc-isolated.sh copy)

**Location:** `devcontainer-config/cc-isolated.sh:248-249`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the per-file loop (every argument is visited, and each failing one gets its own line), the subset file lists of all four callers in cc-isolated.sh and the one in cc-push.sh, and what `bless_manifest` prints. It does not establish anything about the early exits before the loop (repo-checkout `return 0`, missing or malformed manifest `return 1`), which name no file. The comment sits after them and does not claim to cover them.

The loop never stops early. Every failure branch sets `bad` and either `continue`s or falls through to the next iteration:

```bash
# devcontainer-config/cc-isolated.sh:250-270
  local bad=0
  for f in "$@"; do
    if [ ! -f "$dir/$f" ] || [ -L "$dir/$f" ]; then
      echo "$dir/$f is missing or a symlink"
      bad=1
      continue
    fi
    want="$(awk -v f="$f" '$2 == f { n++; h = $1 } END { if (n == 1) print h }' "$m")"
    if [ -z "$want" ]; then
      echo "host-tool manifest $m has no entry, or more than one, for $f"
      bad=1
      continue
    fi
    have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"
    if [ "$want" != "$have" ]; then
      echo "$dir/$f changed since the last bless"
      bad=1
    fi
  done
  return "$bad"
```

The callers in cc-isolated.sh do pass subsets: `verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh` and `verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh` (`cc-isolated.sh:502-503`), `verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh` (`:716`), and `verify_host_tools "$CC_ISOLATED_DIR" cc-push.sh` (`:764`, `:777`). So a caller does not see host tools outside its own list. "The bless prints them" holds: `bless_manifest` diffs the old host-tools manifest against the new one before moving it into place, and the new one covers every host tool (`host_tool_files` lists `cc-exit-scan.sh`, `cc-gitdir.sh`, `cc-push.sh`, `cc-isolated.sh:199-203`):

```bash
# devcontainer-config/cc-isolated.sh:297-300
    elif ! cmp -s "${olds[$i]}" "${news[$i]}"; then
      echo "Changed since the last bless ($(basename "${olds[$i]}")):"
      diff "${olds[$i]}" "${news[$i]}" | grep '^[<>]' || true
```

(excerpt ends :300; enclosing bless_manifest() continues to :319 — read)

**Evidence:** `devcontainer-config/cc-isolated.sh:199-203`, `devcontainer-config/cc-isolated.sh:230-270`, `devcontainer-config/cc-isolated.sh:281-319`, `devcontainer-config/cc-isolated.sh:502-503`, `devcontainer-config/cc-isolated.sh:716`, `devcontainer-config/cc-isolated.sh:764`, `devcontainer-config/cc-isolated.sh:777`

---

## Claim 2: the same comment (cc-push.sh copy)

**Location:** `devcontainer-config/cc-push.sh:175-176`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers cc-push's single caller and the bless it points the user to. It does not establish that the user runs that bless rather than some other command.

The function body is byte-identical to the cc-isolated.sh copy (Claim 4). cc-push checks only itself and cc-gitdir.sh, so it never reports cc-exit-scan.sh:

```bash
# devcontainer-config/cc-push.sh:204
if ! host_tools_err="$(verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh)"; then
```

Its refusal names the bless, which prints the full host-tool diff (Claim 1): `echo "  Review the host tools in $CC_PUSH_DIR, then re-bless (it prints what changed):"` followed by `printf '    CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless\n' "$CC_PUSH_DIR"` (`cc-push.sh:208-209`).

**Evidence:** `devcontainer-config/cc-push.sh:157-198`, `devcontainer-config/cc-push.sh:204-212`

---

## Claim 3: "F1a: the 'file the manifest does not list' case now creates the file, so the no-entry branch decides (and its message is asserted)" + "reporting a missing entry as 'changed' ... fail[s] the named test"

**Location:** `test/cc-isolated-functions.bats:909-914`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test now reaching the no-entry branch and failing when that branch prints the "changed" message. It does not establish that the old test was the only guard: test 80 (`:1027`) already pinned the no-entry message for `cc-push.sh` and fails under the same mutation with both the old and the new test file.

```bash
# test/cc-isolated-functions.bats:911-914
  echo 'c' > "$d/cc-exit-scan.sh"   # present, so the no-entry branch decides
  run verify_host_tools "$d" cc-exit-scan.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"has no entry, or more than one, for cc-exit-scan.sh"* ]]
```

Mutation M2 replaced `echo "host-tool manifest $m has no entry, or more than one, for $f"` with `echo "$dir/$f changed since the last bless"` in both copies, so the parity test still holds. Results:
- New test file: `not ok 75` at `line 914` (the new assertion), plus `not ok 80` at `:1027`.
- Old test file (3164f1d5): test 75 passes and only test 80 fails. The old test 75 was unfailable for this mutation.

Commands: `cd <tree> && timeout 600 bats test/cc-isolated-functions.bats` (and `test/old-cci.bats` holding 3164f1d5's file), cwd `.../fcnarrow.RoLC0y/m2`, exit 1 for both. Timestamps are in the run window above.

**Evidence:** `test/cc-isolated-functions.bats:909-914`, `test/cc-isolated-functions.bats:1027`, `docs/reviews/execution-logs/q089a-narrow-m2-cci.log`, `docs/reviews/execution-logs/q089a-narrow-m2-old.log`

---

## Claim 4: "Both copies (parity test)" and the parity test still passes

**Location:** `test/cc-isolated-functions.bats:933-940`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte equality of the two `# --- verify_host_tools` … `# --- end` blocks after the first line. It does not establish anything about each block's header comment line (the test drops it with `tail -n +2`, and the two lines differ by design: each names the other file).

The diff makes the same two-line change at `cc-isolated.sh:248-249` and `cc-push.sh:175-176`. In the base run, `ok 76 verify_host_tools is the same code in cc-isolated.sh and cc-push.sh` passed. Command: `timeout 600 bats test/cc-isolated-functions.bats`, cwd `.../fcnarrow.RoLC0y/base`, exit 0.

**Evidence:** `devcontainer-config/cc-isolated.sh:219-271`, `devcontainer-config/cc-push.sh:146-198`, `docs/reviews/execution-logs/q089a-narrow-base-cci.log`

---

## Claim 5: "F1b: the 'config dir is never a repo checkout' case puts install.sh in the (resolved) config dir, so only the config-dir clause can refuse it" + "dropping the config-dir clause ... fail[s] the named test"

**Location:** `test/cc-isolated-functions.bats:923-930`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test case being decided by `[ "$dir" != "$cfg" ]` alone, and its failure when that clause is dropped from both copies. It does not establish that every production caller passes an already-resolved `dir` (that is pre-existing code, out of this commit's scope).

With `install.sh` present and no `host-tools.sha256` or `manifest.sha256`, the other three terms of the condition are true. `c` is resolved to match `cfg`, which goes through `readlink -f`:

```bash
# devcontainer-config/cc-isolated.sh:234-236
  cfg="$(readlink -f -- "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}" 2>/dev/null || true)"
  if [ -f "$dir/install.sh" ] && [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
    return 0
```

Mutation M1 removed ` && [ "$dir" != "$cfg" ]` from both copies (grep count 0 in each afterwards). Results:
- New file: `not ok 75` at `line 929` (`[ "$status" -eq 1 ]`).
- Old file: all 182 tests pass. The old case had no install.sh, so the first term refused it and the clause was never tested.

Commands: as in Claim 3, cwd `.../m1`, exit 1 (new) and exit 0 (old).

**Evidence:** `devcontainer-config/cc-isolated.sh:230-237`, `test/cc-isolated-functions.bats:923-930`, `docs/reviews/execution-logs/q089a-narrow-m1-cci.log`, `docs/reviews/execution-logs/q089a-narrow-m1-old.log`

---

## Claim 6: "F1c: the scan-only --list assertion checks 'cc-push: CHANGED', the label afe1ae59 introduced; 'cc-push refuses' never appears any more" + "--list blaming cc-push on a scan-only change ... fail[s] the named test"

**Location:** `test/cc-isolated-functions.bats:1080`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the label's origin in afe1ae59, its absence from `--list` output, and the mutation result. It does not establish that the string "cc-push refuses" is gone from the codebase. "Never appears any more" is true only of `--list` output.

afe1ae59's diff replaced `printf '  cc-push refuses: %s\n'` with `printf '  cc-push: CHANGED — do not run it until re-blessed (an intact copy refuses): %s\n'` (now `cc-isolated.sh:517`). The phrase does still appear elsewhere: cc-push's own stderr `echo "ERROR: cc-push refuses to run:"` (`cc-push.sh:206`), a comment at `cc-isolated.sh:493`, and several cc-push.bats test names. None of these reach `--list` output. Tighten to: "'cc-push refuses' never appears in --list output any more."

Mutation M3 inserted `perr="${perr:-$lerr}"` before the `cc-push: CHANGED` printf, so a scan-only change is blamed on cc-push. Results:
- New file: `not ok 82` at `line 1080` (`[[ "$output" != *"cc-push: CHANGED"* ]]`).
- Old file: all 182 pass.

Commands: as in Claim 3, cwd `.../m3`, exit 1 (new) and exit 0 (old).

**Evidence:** `devcontainer-config/cc-isolated.sh:493`, `devcontainer-config/cc-isolated.sh:508-518`, `devcontainer-config/cc-push.sh:206`, `test/cc-isolated-functions.bats:1077-1080`, `docs/reviews/execution-logs/q089a-narrow-m3-cci.log`, `docs/reviews/execution-logs/q089a-narrow-m3-old.log`

---

## Claim 7: the new test comment "The config dir itself is never a repo checkout, even with install.sh beside the script and no manifest: only the config-dir clause refuses this one."

**Location:** `test/cc-isolated-functions.bats:923-924`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this test case. It does not establish the property for unresolved config-dir paths passed by other callers.

Same evidence as Claim 5. The refusal message the test asserts, `[[ "$output" == *"no host-tool manifest"* ]]` (`:930`), comes from `echo "no host-tool manifest at $m (re-run install.sh, or review the tools and bless this dir)"` (`cc-isolated.sh:239`), which is reached once the clause stops the early return.

**Evidence:** `test/cc-isolated-functions.bats:923-930`, `devcontainer-config/cc-isolated.sh:238-240`, `docs/reviews/execution-logs/q089a-narrow-m1-cci.log`

---

## Claim 8: "Tests under LC_ALL=C: cc-isolated-functions 182/182, cc-push 48/48."

**Location:** commit 88994fe9 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both suites at 88994fe9 under LC_ALL=C in the redirected sandbox. It does not establish behavior under other locales or on a host with Docker.

Checked against the logged test-count pattern (the "85 tests" and "mode1-equiv 33" entries), and it does not match it. `bats --count` gives 182 and 48. The runs:
- `timeout 600 bats test/cc-isolated-functions.bats`: plan `1..182`, 182 ok, 0 not ok, exit 0.
- `timeout 600 bats test/cc-push.bats`: plan `1..48`, 48 ok, 0 not ok, exit 0.

cwd `.../fcnarrow.RoLC0y/base`, run window 2026-10-15T02:56:07Z onward.

**Evidence:** `docs/reviews/execution-logs/q089a-narrow-base-cci.log`, `docs/reviews/execution-logs/q089a-narrow-base-push.log`, `docs/reviews/execution-logs/q089a-narrow-probe-summary.log`

---

## Claim 9: "Mutation checks: dropping the config-dir clause, reporting a missing entry as 'changed', and --list blaming cc-push on a scan-only change each fail the named test."

**Location:** commit 88994fe9 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three mutations as reconstructed independently here (M1, M2, M3 in Claims 5, 3, 6). It does not establish that the author's own mutations were these exact edits.

Each mutation fails the test the commit names, at the line this commit added or changed:
- M1: test 75, `:929`.
- M2: test 75, `:914`.
- M3: test 82, `:1080`.

Each passes the corresponding old assertion. M2 also fails pre-existing test 80 (see Claim 3's scope).

**Evidence:** `docs/reviews/execution-logs/q089a-narrow-m1-cci.log`, `docs/reviews/execution-logs/q089a-narrow-m2-cci.log`, `docs/reviews/execution-logs/q089a-narrow-m3-cci.log`, `docs/reviews/execution-logs/q089a-narrow-m1-old.log`, `docs/reviews/execution-logs/q089a-narrow-m2-old.log`, `docs/reviews/execution-logs/q089a-narrow-m3-old.log`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 6** (commit message, F1c): "'cc-push refuses' never appears any more" is true of `--list` output only. The phrase remains in cc-push's own refusal (`cc-push.sh:206`). This is wording in the commit message, not the code, so nothing needs to change before merge.

### Unverifiable
(none)

## Goal-Alignment Note

The goal is to land Q-089 per Q-148 [1]: apply the four one-line fixes, run a k=1 narrow check on just those lines, and merge if clean. On that check this commit is clean.
- Each of the three repaired tests now fails on the regression it names, and the pre-fix version of each passed under the same mutation, so the "unfailable" diagnosis is confirmed.
- The new shared comment is true for both callers.
- Parity holds, and both suites pass at the stated counts.
- The one Mostly-accurate item is a scoping imprecision in the commit message, not in shipped code or comments, and needs no fix to merge.
- No hallucination pattern was confirmed, so `docs/reviews/hallucination-patterns.md` is unchanged.
- Live and host-tool verification remain open, as the commit's own trailers state; this check does not cover them.
