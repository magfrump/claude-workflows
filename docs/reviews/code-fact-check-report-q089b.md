# Code Fact-Check Report

**Repository:** /workspace (worktree `.claude/wt-q089b`, branch `feat/q089b3-host-tool-gate`)
**Scope:** `git diff cc2640b7 9001bf80` — `hooks/live-verify-gate.sh`, `test/hooks/live-verify-gate.bats`, `docs/decisions/log.md` (row 71), `guides/devcontainer-setup.md`, `guides/cc-isolated-usage.md`, and the messages of 12e149fc, 3f53f503, 9001bf80. A1/A2 behaviour checked against `git show 9001bf80:devcontainer-config/{cc-isolated.sh,cc-push.sh,install.sh,Dockerfile}`.
**Commit:** 9001bf80
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-10-14
**Total claims checked:** 42 (41 numbered, Claim 11 split into 11a/11b)
**Summary:** 29 verified, 8 mostly accurate, 4 stale, 1 incorrect, 0 unverifiable

Execution environment for every `executed` claim: a fresh `mktemp -d` under `/home/node/.claude/jobs/00bcf178/tmp/` (`fc-q089b.fMBZEt`, removed after the run) holding `git archive 9001bf80` (`src/`) and `git archive 12e149fc` (`s12/`), `HOME` redirected into it, `LC_ALL=C`, every command under `timeout`. The fixture install dir was `$HOME/.config/claude-devcontainer` inside the probe dir; `devcontainer` was not on PATH, so no launch could get past the CLI check. The probe scripts are saved beside the logs (`run-bats.sh`, `run-probes.sh`, `run-m3.sh`). Logs: `docs/reviews/execution-logs/fc-q089b/`. Hallucination-pattern log read first. The relevant class is commit-message test tallies (`"All 85 tests"`, `"mode1-equiv 33"`). Claim 37's tally matches that class and is Verified this time.

---

## Claim 1: "`cc-exit-scan.sh`, `cc-gitdir.sh` and `cc-push.sh` leave `enforcement_files()` for `host_tool_files()`."

**Location:** `docs/decisions/log.md:94`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two function bodies in `cc-isolated.sh` at 9001bf80. It does not establish that the gate's regexes match the functions (Claims 27, 28, 36).

`enforcement_files()` echoes `devcontainer.json`, `Dockerfile`, `init-firewall.sh`, `cc-sni-proxy.py`, `link-claude-home.sh` and `cc-isolated.sh`, then the globs (`devcontainer-config/cc-isolated.sh:128-151`). None of the three host tools is in it. `host_tool_files()` is exactly:

```bash
# devcontainer-config/cc-isolated.sh:199-203
host_tool_files() {
  echo "cc-exit-scan.sh"
  echo "cc-gitdir.sh"
  echo "cc-push.sh"
}
```

**Evidence:** `devcontainer-config/cc-isolated.sh:128-151`, `devcontainer-config/cc-isolated.sh:199-203`

---

## Claim 2: "The bless hashes them into `host-tools.sha256` beside `manifest.sha256`, so a change to one leaves `blessed_hash`, the baked image hash and the verified-live receipt alone."

**Location:** `docs/decisions/log.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bless writing both files and `blessed_hash` staying the same across a host-tool edit plus re-bless. It does not establish the baked image hash in a real container (no Docker). That hash is `blessed_hash` by construction (`cc-isolated.sh:84-87` comment).

`blessed_hash` is a hash over `manifest.sha256` alone:

```bash
# devcontainer-config/cc-isolated.sh:88-93
blessed_hash() {
  local m
  m="$(manifest_path)"
  [ -f "$m" ] || return 1
  sha256sum < "$m" | cut -c1-16
}
```

Probe L0→L2: bless (`blessed_hash=8aa508249d3ffc00`), append to `cc-gitdir.sh`, re-bless. The re-bless printed `Changed since the last bless (host-tools.sha256)` with only the `cc-gitdir.sh` line, and `blessed_hash=8aa508249d3ffc00 (was 8aa508249d3ffc00)`. Bats `bless writes host-tools.sha256; a host-tool edit leaves the boundary manifest and blessed hash alone` passed.

Command: `bash run-probes.sh <logdir>` (L0–L2) and `bats -f '…host-tools…' test/cc-isolated-functions.bats`. Cwd: probe dir / `src`. Exit 0. 2026-10-15T00:50:22Z and 00:48:29Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:88-93`, `devcontainer-config/cc-isolated.sh:276-305`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L0–L2), `docs/reviews/execution-logs/fc-q089b/bats-hosttools-src.log`

---

## Claim 3: "Each entry point checks the host tools it executes before sourcing them (`verify_host_tools`, one copy in `cc-isolated.sh` and `cc-push.sh`, pinned byte for byte by a test)."

**Location:** `docs/decisions/log.md:94`
**Type:** Architectural / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the check-then-`source` order at both entry points and the parity test passing. It does not establish that every `source` line is covered (the split-out static guard, Claim 14). The parity test compares the blocks after dropping their first marker line, and that line legitimately differs.

```bash
# devcontainer-config/cc-isolated.sh:709-714
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
  # shellcheck source=cc-exit-scan.sh
  source "$CC_ISOLATED_DIR/cc-exit-scan.sh"
else
  HOST_TOOLS_ERR="${HOST_TOOLS_ERR:-host-tool check failed}"
fi
```

```bash
# devcontainer-config/cc-push.sh:198-208
if ! host_tools_err="$(verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh)"; then
  ...
  exit 1
fi
# shellcheck source=cc-gitdir.sh
source "$CC_PUSH_DIR/cc-gitdir.sh"
```

Bats `verify_host_tools is the same code in cc-isolated.sh and cc-push.sh` passed (ok 4).

**Evidence:** `devcontainer-config/cc-isolated.sh:219-266`, `devcontainer-config/cc-isolated.sh:709-714`, `devcontainer-config/cc-push.sh:145-208`, `test/cc-isolated-functions.bats:928-935`, `docs/reviews/execution-logs/fc-q089b/bats-hosttools-src.log`

---

## Claim 4: "On a mismatch the launcher does not load the scan, names every changed tool, runs the boundary check too and shows its diff, and refuses everything but `--bless` and `--list`."

**Location:** `docs/decisions/log.md:94`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers launch, `--probe-only`, `--help` and `--list` with a changed `cc-gitdir.sh`, with and without a boundary change. It does not establish `--register`, which goes through the same branch statically. Precise version: "refuses everything but `--bless`, `--list` and `--help`; usage errors are answered first".

`--help` and usage errors are parsed before the refusal and exit before it:

```bash
# devcontainer-config/cc-isolated.sh:736-748 (excerpt ends :748; enclosing main() continues to :933 — read)
      --help|-h)    usage; exit 0 ;;
      ...
  if [ -n "$HOST_TOOLS_ERR" ] && [ "$action" != "bless" ] && [ "$action" != "list" ]; then
    echo "ERROR: host tools differ from the bless — refusing to launch, probe or register:" >&2
```

Probe L1: launch and `--probe-only` exited 1 with `…/cc-gitdir.sh changed since the last bless`, and `--help` exited 0 and printed usage. Probe L1b (adding a boundary change) printed `check_manifest`'s `ERROR: installed config changed…`, the `egress/base.txt` diff and "The BOUNDARY config changed too", then exited 1. The loop in `verify_host_tools` uses `continue`, never `break`, so every changed tool is named (`cc-isolated.sh:252-264`). A changed `cc-push.sh` is added as `also changed (cc-push refuses until re-blessed)` (`:756-758`). The function's own comment at `:705-706` already says "--help and usage errors are answered first".

Command: `bash run-probes.sh <logdir>`. Cwd: probe dir. Exit 0 (script). 2026-10-15T00:50:22Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:700-764`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L1, L1b)

---

## Claim 5: "It warns, without refusing, on a changed `cc-push.sh`, which it does not execute. `cc-push` refuses before parsing anything."

**Location:** `docs/decisions/log.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher's warning path and cc-push's pre-argument refusal (`--help` given). It does not establish behaviour after the warning beyond the `devcontainer` CLI check, because no CLI was present. `safe_path` and `unset GIT_*` run before the check, and they parse no arguments.

```bash
# devcontainer-config/cc-isolated.sh:767-771
  local push_err
  if [ "$action" != "bless" ] && [ "$action" != "list" ] \
     && ! push_err="$(verify_host_tools "$CC_ISOLATED_DIR" cc-push.sh)"; then
    echo "WARNING: $push_err — do not run cc-push until you have reviewed it and re-blessed." >&2
  fi
```

Probe L3: launch printed `WARNING: …/cc-push.sh changed since the last bless — do not run cc-push…` and then went on to `ERROR: devcontainer CLI not found` (exit 1 for that reason only). `cc-push.sh --help` printed `ERROR: cc-push refuses to run:` and exited 1 with no usage.

**Evidence:** `devcontainer-config/cc-isolated.sh:764-771`, `devcontainer-config/cc-push.sh:194-206`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L3)

---

## Claim 6: "Only a positively marked repo checkout is left unchecked: `install.sh` beside the script (never installed), no manifest, and not the config dir. Deleting manifests does not opt an installed copy out."

**Location:** `docs/decisions/log.md:94`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the exemption condition and the deleted-manifest case in an install dir with no `install.sh`. It does not establish the planted-`install.sh` case, which row 71 lists as not covered (Claim 13).

```bash
# devcontainer-config/cc-isolated.sh:235-237
  if [ -f "$dir/install.sh" ] && [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
    return 0
  fi
```

`install.sh` is not in `PAYLOAD` (`install.sh:110`). Probe L5: after `rm` of both manifests in the install dir, `cc-push.sh --help` refused with `no host-tool manifest at …`. Probe L6: the repo checkout's `cc-push.sh --help` printed usage (exit 0). Bats `verify_host_tools: repo checkout unchecked; an installed dir must match, and cannot opt out` passed.

**Evidence:** `devcontainer-config/cc-isolated.sh:230-240`, `devcontainer-config/install.sh:110`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L5, L6), `docs/reviews/execution-logs/fc-q089b/bats-hosttools-src.log`

---

## Claim 7: "Bless computes both manifests to temp files, prints what changed, and moves them into place only when both compute."

**Location:** `docs/decisions/log.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers compute-to-temp, the print-then-move order and the both-or-neither compute gate. It does not establish atomicity of the two renames, which the code comment at `:268-275` says can split (row 71 does not claim it; see Claim 41).

```bash
# devcontainer-config/cc-isolated.sh:281-285
  if ! compute_manifest > "$new_m" || ! compute_host_tools_manifest > "$new_h"; then
    rm -f "$new_m" "$new_h"
    echo "ERROR: nothing blessed." >&2
    return 1
  fi
```

The `diff` print loop (`:286-297`) runs before `mv -f` (`:298-299`). Probe L2 printed `Changed since the last bless (host-tools.sha256):` with the old and new `cc-gitdir.sh` lines.

**Evidence:** `devcontainer-config/cc-isolated.sh:276-305`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L2)

---

## Claim 8: "`--list` reports each entry point's host-tool state."

**Location:** `docs/decisions/log.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the clean, gitdir-changed and push-changed states in config_dir(). It does not establish the state of an entry point run from another dir (the comment at `:487-492` says the check runs in config_dir()).

Probe output: clean → `Host tools — match the bless (cc-exit-scan.sh cc-gitdir.sh cc-push.sh)`. `cc-gitdir.sh` changed → `launches refuse: …` and `cc-push refuses: …`. `cc-push.sh` changed → `launches warn (cc-push changed) but run` and `cc-push refuses: …`. The code is at `cc-isolated.sh:497-510` (quoted lines `lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true` / `perr="$(verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh)" || true`).

**Evidence:** `devcontainer-config/cc-isolated.sh:487-510`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L0, L1, L3)

---

## Claim 9: "`live-verify-gate.sh` requires `Host-tool-tested:` for them instead of `Live-verified:`, judging each set's comment-only escape separately."

**Location:** `docs/decisions/log.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three host tools' trailer requirement and the per-set escape in both directions. It does not establish that the gate's regexes stay matched to the cc-isolated.sh lists (Claim 11b and Claim 32).

```bash
# hooks/live-verify-gate.sh:138-141
need=()
if [ -n "$boundary_touched" ] && ! comment_only_diff "$boundary_touched"; then need+=("Live-verified"); fi
if [ -n "$host_touched" ] && ! comment_only_diff "$host_touched"; then need+=("Host-tool-tested"); fi
[ "${#need[@]}" -gt 0 ] || exit 0
```

Probes G1b (a cc-push change carrying only Live-verified gives exit 2), G2 (a comment-only boundary edit plus a real host change carrying Host-tool-tested gives exit 0) and G5 (a comment-only host edit gives exit 0). Gate bats 25/25.

**Evidence:** `hooks/live-verify-gate.sh:78-82`, `hooks/live-verify-gate.sh:136-158`, `docs/reviews/execution-logs/fc-q089b/probe-gate.log`, `docs/reviews/execution-logs/fc-q089b/bats-gate-src.log`

---

## Claim 10: "a changed `cc-exit-scan.sh` or `cc-gitdir.sh` still stops a launch, because the launcher executes them, but it now needs only a re-bless, not a rebuild and probe. A `cc-push`-only change no longer stops one."

**Location:** `docs/decisions/log.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal, the unchanged `blessed_hash` after a re-bless (so no rebuild trigger), and a cc-push-only launch getting past the host-tool gate. It does not establish a full launch after the warning (no devcontainer CLI).

Probe L1 shows the refusal, with the note `The boundary config is unchanged: the re-bless changes no boundary state, so it causes no rebuild`. L2 shows the blessed hash unchanged after the re-bless. L3 shows the cc-push-only launch reaching the devcontainer-CLI check. (Paraphrased — no quote available because the three facts are probe outputs already quoted in Claims 2, 4 and 5.)

**Evidence:** `devcontainer-config/cc-isolated.sh:748-771`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L1–L3)

---

## Claim 11a: "Pre-mortem: covered are a category swap (tests pin the host list exactly, keep the lists disjoint, and bar any COPY source)" — for cc-isolated.sh's lists

**Location:** `docs/decisions/log.md:94`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `enforcement_files()`/`host_tool_files()` and the Dockerfile. It does not establish the gate's regexes (11b).

```bash
# test/cc-isolated-functions.bats:848-852
  host="$(host_tool_files)"
  [ "$host" = $'cc-exit-scan.sh\ncc-gitdir.sh\ncc-push.sh' ]
  for item in $host; do
    if echo "$enf" | grep -qx "$item"; then echo "in both lists: $item"; return 1; fi
  done
```

The COPY bar is at `:860-862`. The test passed (ok 1).

**Evidence:** `test/cc-isolated-functions.bats:835-867`, `docs/reviews/execution-logs/fc-q089b/bats-hosttools-src.log`

---

## Claim 11b: "covered are a category swap" — as the gate's half of the category (row 71 lists `hooks/live-verify-gate.sh` and its bats file as evidence)

**Location:** `docs/decisions/log.md:94`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a swap made in the gate's two regexes only. It does not establish what a reviewer would catch by reading. Precise version: "a swap in cc-isolated.sh's lists is covered; a swap in the gate's regexes is not pinned by any test".

Mutation M3 moved `init-firewall\.sh` out of the gate's `enforcement` regex and into `host_tools`, giving `host_tools='^devcontainer-config/(init-firewall\.sh|cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)$'`. Result: all 25 gate tests still passed (exit 0). A real `init-firewall.sh` change committed with only `Host-tool-tested: no - n/a` then exited 0. That means a boundary file loses its `Live-verified:` gate with every test green. The swap gets through because the enforcement-set test asserts only a block, never which trailer is required (Claim 32).

Command: `timeout 400 bash run-m3.sh <logdir>`. Cwd: probe dir `/mut`. Exit 0. 2026-10-15T00:51:07Z.

**Evidence:** `hooks/live-verify-gate.sh:73-78`, `test/hooks/live-verify-gate.bats:110-136`, `docs/reviews/execution-logs/fc-q089b/probe-mutation-m3.log`

---

## Claim 12: "A self-skipping tampered cc-push is caught by the launcher's warning at the next launch and by `--list`."

**Location:** `docs/decisions/log.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers any byte change to `cc-push.sh` surfacing in both places. It does not establish detection when `host-tools.sha256` is rewritten too, which row 71 lists as not covered.

Probe L3 (a `cc-push.sh` edit) printed the launch `WARNING:` line and `--list`'s `launches warn (cc-push changed) but run` / `cc-push refuses: …`. Both come from the launcher's own `verify_host_tools … cc-push.sh` calls (`cc-isolated.sh:769`, `:498`), which never execute cc-push.

**Evidence:** `devcontainer-config/cc-isolated.sh:498`, `devcontainer-config/cc-isolated.sh:767-771`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L3)

---

## Claim 13: Not covered: "a planted `install.sh` together with deleted manifests, in an install dir that `CLAUDE_DEVC_CONFIG_DIR` does not name at run time; a `sha256sum` or `awk` shim on PATH … (both are found by name, as `git` is)"

**Location:** `docs/decisions/log.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the exemption depends on `$cfg` and that both tools are called unqualified. It does not establish whether `safe_path` in cc-push narrows the shim risk (it drops relative and checkout entries only, `cc-push.sh:127-141`).

```bash
# devcontainer-config/cc-isolated.sh:234 and :258-259
  cfg="$(readlink -f -- "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}" 2>/dev/null || true)"
    want="$(awk -v f="$f" '$2 == f { n++; h = $1 } END { if (n == 1) print h }' "$m")"
    have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"
```

**Evidence:** `devcontainer-config/cc-isolated.sh:230-266`

---

## Claim 14: "a static test tying each entry point's `source` lines to its check list was split out as Q-147"

**Location:** `docs/decisions/log.md:94`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of a Q-147 entry in `docs/working/questions.md` / `questions-archive.md` on every ref and in every worktree under `/workspace/.claude/`. It does not establish whether the orchestrator means to file it at landing.

No Q-147 entry exists anywhere. The ID is cited only by row 71, by commit 3f53f503's message, and by the A1 architecture-review and rubric docs that propose it. The highest entry in main's questions doc is Q-146 (`docs/working/questions.md:294: ### Q-146 · si-children-commit-rights`). (Paraphrased — no quote available because the claim covers the absence of code: `git log --all -S'Q-147'` and `rg '### Q-147'` over the worktrees found no entry.) A reader who follows the reference finds nothing. To fix, file Q-147 (with `questions.sh next-id` on fresh main, which may yield a different number) before merging, and make the row cite whatever ID it gets.

**Evidence:** `docs/decisions/log.md:94`, `docs/working/questions.md:31`, `docs/working/questions.md:294`

---

## Claim 15: "`cc-isolated --list  # blessed config hash + verified-live status, host-tool state, registered projects`"

**Location:** `guides/cc-isolated-usage.md:22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three outputs as printed. It does not establish the registered-project listing with projects present (none in the fixture).

Probe L0 `--list` printed `Blessed config 8aa508249d3ffc00 — verified live: NO …`, `Host tools — match the bless (…)` and `No projects registered …`.

**Evidence:** `devcontainer-config/cc-isolated.sh:478-520`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L0)

---

## Claim 16: "when the installed `cc-push.sh` or the `cc-gitdir.sh` beside it differs from the bless (`host-tools.sha256` …), cc-push prints `ERROR: cc-push refuses to run:` and exits 1 before parsing anything, so `--help` exits 1 too and prints no usage."

**Location:** `guides/cc-isolated-usage.md:239-242`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named triggers. It does not establish the other triggers, a missing, malformed or symlinked manifest, which also refuse (probes L4/L5). The sentence does not claim exclusivity, and cc-push's own header names them (`cc-push.sh` usage, "or that file is missing or a symlink").

Probes L1 (`cc-gitdir.sh` changed) and L3 (`cc-push.sh` changed): `cc-push.sh --help` printed `ERROR: cc-push refuses to run:` with no usage text, and exited 1.

**Evidence:** `devcontainer-config/cc-push.sh:198-206`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L1, L3, L4, L5)

---

## Claim 17: "a `git commit` that includes any manifest-hashed file under `devcontainer-config/` is blocked unless … `Live-verified:` … The host-only tools (`cc-exit-scan.sh`, `cc-gitdir.sh`, `cc-push.sh`) carry `Host-tool-tested:` instead."

**Location:** `guides/cc-isolated-usage.md:826-830`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the trailer split. It does not establish the gate's `install.sh` coverage (gated but not hashed; pre-existing text, not in this diff) or the comment-only escape, which the sentence leaves out.

Probes G1/G1b: a `cc-push.sh` change with no trailer, or with only `Live-verified:`, gives exit 2 and `Host-tool-tested:` in the message. Bats T1 shows `Host-tool-tested:` passes.

**Evidence:** `hooks/live-verify-gate.sh:73-82`, `docs/reviews/execution-logs/fc-q089b/probe-gate.log`

---

## Claim 18: "`ERROR: host tools differ from the bless — refusing to launch, probe or register` | A host tool (`cc-exit-scan.sh` or `cc-gitdir.sh`) changed since the last bless; the launcher will not source it. Review the named files, then run the bless command the message prints (it names the dir). If the boundary config changed too, its diff is shown above … `--list` shows which entry points refuse."

**Location:** `guides/cc-isolated-usage.md:927`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message text, the printed bless command and the boundary diff. It does not establish every cause of that header. Precise version: "a host tool changed, or `host-tools.sha256` is missing, unreadable or malformed, or a tool is missing or a symlink".

The header string matches probe L1 exactly, and the bless command printed is `CLAUDE_DEVC_CONFIG_DIR=<dir> <dir>/cc-isolated.sh --bless`. Probe L1b shows the boundary diff. The same header also prints for a malformed manifest (probe L4: `ERROR: host tools differ from the bless …` followed by `host-tool manifest … is unreadable or malformed`), and in that case "a host tool changed" is wrong. Row 3 of the table covers that sub-line, but a reader matching the header lands on row 1. Strictly, the diff is printed between the refusal lines, not "above" the whole message (L1b).

**Evidence:** `devcontainer-config/cc-isolated.sh:748-762`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L1, L1b, L4)

---

## Claim 19: "`WARNING: … cc-push.sh changed since the last bless` at launch | The launch goes on (the launcher does not run cc-push), but do not run `cc-push` until you have reviewed it and re-blessed."

**Location:** `guides/cc-isolated-usage.md:928`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message text and the launch going past it. It does not establish a full session start (no devcontainer CLI).

Probe L3 printed `WARNING: …/cc-push.sh changed since the last bless — do not run cc-push until you have reviewed it and re-blessed.`, and execution reached the CLI check.

**Evidence:** `devcontainer-config/cc-isolated.sh:767-771`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L3)

---

## Claim 20: "`host-tool manifest … is unreadable or malformed` | `host-tools.sha256` itself is the anomaly. Inspect it before any bless overwrites it; re-run `install.sh` to restore it."

**Location:** `guides/cc-isolated-usage.md:929`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the message (executed) and `install.sh` ending in a bless that rewrites the file (static). It does not run `install.sh` (forbidden on real dirs, and interactive).

Probe L4 printed `host-tool manifest …/host-tools.sha256 is unreadable or malformed: inspect it before any bless overwrites it`. `install.sh` ends with:

```bash
# devcontainer-config/install.sh:607
  CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless
```

**Evidence:** `devcontainer-config/cc-isolated.sh:243-247`, `devcontainer-config/install.sh:598-607`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L4)

---

## Claim 21: "Host-only tools get a trailer of their own, `Host-tool-tested:`, so that list holds only debt a probe can pay"

**Location:** `guides/devcontainer-setup.md:250-251`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate no longer accepting `Live-verified:` for host tools. It does not establish history: earlier host-tool commits still carry `Live-verified: no` in `git log`. The installed gate copy also keeps requiring it until `install.sh` runs (Claim 39).

Probe G1b: `Live-verified: no - n/a` on a cc-push change gives exit 2.

**Evidence:** `hooks/live-verify-gate.sh:138-158`, `docs/reviews/execution-logs/fc-q089b/probe-gate.log` (G1b)

---

## Claim 22: "Enforcement files are what `enforcement_files()` in `cc-isolated.sh` hashes: `Dockerfile`, `devcontainer.json`, `init-firewall.sh`, `cc-sni-proxy.py`, `link-claude-home.sh`, `cc-isolated.sh`, everything under `egress/`, and the staged `claude-home/`."

**Location:** `guides/devcontainer-setup.md:264-267`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the list against the function body. It does not establish anything about the gate (which matches all of `egress/` and does not match `projects/`). Precise version: "…`egress/*.txt`, every registered `projects/*.profile`, and the staged `claude-home/`".

The sentence was rewritten in this diff (12e149fc) and still omits the per-project profiles. Its "everything under `egress/`" is also broader than the glob:

```bash
# devcontainer-config/cc-isolated.sh:145-146
    for f in egress/*.txt; do [ ! -e "$f" ] || echo "$f"; done | LC_ALL=C sort
    for f in projects/*.profile; do [ ! -e "$f" ] || echo "$f"; done | LC_ALL=C sort
```

Both imprecisions predate the diff.

**Evidence:** `devcontainer-config/cc-isolated.sh:128-151`

---

## Claim 23: "They run on the host, after or outside the container, and the image never copies them … The bless hashes them into their own file, `host-tools.sha256` … Changing one leaves the blessed config, the container and the verified-live receipt alone: it needs a re-bless after review, not a rebuild or a probe."

**Location:** `guides/devcontainer-setup.md:269-276`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Dockerfile COPY lines, the separate manifest and the unchanged blessed hash. It does not establish container behaviour (no Docker).

The Dockerfile COPYs only `egress/`, `init-firewall.sh`, `cc-sni-proxy.py`, `link-claude-home.sh` and `claude-home/` (`Dockerfile:486-500`, e.g. `COPY init-firewall.sh /usr/local/bin/`). The PAYLOAD/COPY test passed. Probe L2 shows the blessed hash unchanged.

**Evidence:** `devcontainer-config/Dockerfile:486-500`, `docs/reviews/execution-logs/fc-q089b/bats-hosttools-src.log`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log` (L2)

---

## Claim 24: "The launcher checks `cc-exit-scan.sh` and `cc-gitdir.sh`. When either has changed it refuses everything except `--bless` and `--list`, and it still runs the boundary check and shows that diff … A changed `cc-push.sh` gets a warning. `cc-push` checks itself and `cc-gitdir.sh`, and refuses to run, `--help` included. `cc-isolated --list` shows which entry points would refuse, and `--bless` prints what changed before accepting it."

**Location:** `guides/devcontainer-setup.md:276-284`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each sentence by probe. It carries the same exception as Claim 4: the launcher's `--help` (and usage errors) is answered, exit 0, so "everything except `--bless` and `--list`" should add `--help`.

Probes L1 (refusal; `--help` exit 0), L1b (boundary diff), L3 (warning; cc-push `--help` exit 1), L0/L1/L3 (`--list`) and L2 (bless prints the change). (Paraphrased — no quote available because these probe lines are already quoted in Claims 4, 5, 7 and 8.)

**Evidence:** `devcontainer-config/cc-isolated.sh:736-771`, `devcontainer-config/cc-push.sh:198-206`, `docs/reviews/execution-logs/fc-q089b/probe-launcher.log`

---

## Claim 25: "Their commits carry `Host-tool-tested:` (what ran on a host, or `no — <reason>`), not `Live-verified:`."

**Location:** `guides/devcontainer-setup.md:284-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gate's requirement. It does not establish that the gate judges the value (it does not, by design: any `Host-tool-tested:` text passes).

The host-tool block message offers `Host-tool-tested: <what you ran, …>` / `Host-tool-tested: no — <reason>; <what will run it>` (`hooks/live-verify-gate.sh:184-186`). Bats T1 passes with both a free-text value and a `-F` file.

**Evidence:** `hooks/live-verify-gate.sh:152-154`, `hooks/live-verify-gate.sh:177-187`, `docs/reviews/execution-logs/fc-q089b/bats-gate-src.log`

---

## Claim 26: Header: "If the files about to be committed include any enforcement file under devcontainer-config/ (the ones the trust manifest hashes, plus install.sh …), the commit message must carry a `Live-verified:` trailer" and the Behavior table "not a `git commit`, no enforcement file staged, trailer present → exit 0 … enforcement file staged, no trailer → exit 2"

**Location:** `hooks/live-verify-gate.sh:1-3`, `hooks/live-verify-gate.sh:13-21`, `hooks/live-verify-gate.sh:34-39`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file header and the behaviour table, neither of which the diff touched. The new host-tool comment at `:74-77` is correct (Claim 28).

The header still describes a single-trailer gate. Under the new terminology the host tools are not enforcement files (row 71, the guide), so the table's "no enforcement file staged → exit 0" is now false. A host-tool-only commit with no trailer exits 2 (probe G1). "trailer present → exit 0" is false too: a `Live-verified:` trailer on a cc-push change exits 2 (probe G1b). The header's opening, "a commit that changes the cc-isolated boundary must say whether it was verified in a live container", also no longer names what the gate checks for host tools. Precise version: add a host-tool row ("host tool staged, its diff not comment-only, no `Host-tool-tested:` → exit 2") and say the trailer is per set.

**Evidence:** `hooks/live-verify-gate.sh:1-43`, `hooks/live-verify-gate.sh:138-158`, `docs/reviews/execution-logs/fc-q089b/probe-gate.log` (G1, G1b)

---

## Claim 27: "The enforcement set: what cc-isolated.sh's enforcement_files() hashes, as repo paths. Keep in step with that function."

**Location:** `hooks/live-verify-gate.sh:70-73`
**Type:** Architectural / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the regex as a superset of the function's committed files, and whether the keep-in-step note reaches `host_tool_files`. It does not establish a reverse pin. Precise version: "…Keep both regexes in step with `enforcement_files()` and `host_tool_files()`; the bats file pins only that each listed file is blocked."

The regex covers every committed `enforcement_files()` entry (bats `every manifest-hashed file is in the enforcement set` passed). It is a superset (`egress/` vs `egress/*.txt`, plus `install.sh`), which the comment states. The caller's question was whether "Keep in step with that function" now also covers `host_tool_files`. It does not. "That function" refers only to `enforcement_files()`. The host-tools comment at `:74` names `host_tool_files()` as the source:

```bash
# hooks/live-verify-gate.sh:74
# Host-only tools: cc-isolated.sh's host_tool_files() (decision log row 71). No
```

It carries no keep-in-step instruction. The reverse half of that pin is untested (Claims 32 and 36).

**Evidence:** `hooks/live-verify-gate.sh:70-78`, `test/hooks/live-verify-gate.bats:110-136`, `docs/reviews/execution-logs/fc-q089b/bats-gate-src.log`

---

## Claim 28: "Host-only tools: cc-isolated.sh's host_tool_files() … they carry their own trailer, `Host-tool-tested:` … A commit touching both kinds needs both trailers."

**Location:** `hooks/live-verify-gate.sh:74-78`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's equality of the regex and the function (both list exactly the same three names) and the both-trailers rule. It does not establish that the equality is enforced in both directions (Claim 36).

```bash
# hooks/live-verify-gate.sh:78
host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)$'
```

Probe G4: a real boundary change plus a real host change with no trailer printed both BLOCKED messages (exit 2). Bats T2 passed.

**Evidence:** `hooks/live-verify-gate.sh:78`, `devcontainer-config/cc-isolated.sh:199-203`, `docs/reviews/execution-logs/fc-q089b/probe-gate.log` (G4)

---

## Claim 29: "The comment-only escape (Q-009). Read the same diff the commit would carry … restricted to the enforcement files, and let it through only if every added and removed line is blank or a comment."

**Location:** `hooks/live-verify-gate.sh:84-89`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comment block above `comment_only_diff`. The new `$1` line at `:89` is accurate.

The function no longer reads "the enforcement files". It reads whichever set it is given, and it is called once with the boundary set and once with the host-tool set:

```bash
# hooks/live-verify-gate.sh:92
  mapfile -t touched_files <<< "$1"
```

The added line `# $1: the newline-separated files to read (one trailer's set).` makes the block internally inconsistent, not wrong in effect. The rule it states (blank or `#`/`//` lines only) is unchanged. The same applies to `:100-101`'s "an added or deleted enforcement file".

**Evidence:** `hooks/live-verify-gate.sh:84-134`, `hooks/live-verify-gate.sh:139-140`

---

## Claim 30: "Each set is judged on its own diff: a comment-only edit to a host tool needs no trailer even when the same commit changes a boundary file, and vice versa."

**Location:** `hooks/live-verify-gate.sh:136-137`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both directions by execution. It does not establish test coverage of the "vice versa" direction: no bats test stages a comment-only boundary edit beside a real host change. Only probes G2/G3 exercised it.

Bats T3 covers the first direction. Probe G2 (a comment-only `egress/base.txt` edit plus a real `cc-push.sh` change) passed with `Host-tool-tested:` only (exit 0). G3 shows `Live-verified:` alone is refused there (exit 2).

**Evidence:** `hooks/live-verify-gate.sh:136-141`, `test/hooks/live-verify-gate.bats:313-323`, `docs/reviews/execution-logs/fc-q089b/probe-gate.log` (G2, G3)

---

## Claim 31: "The message text: the command itself, plus any -F <file> / --file <file> / --file=<file> it names."

**Location:** `hooks/live-verify-gate.sh:143-150`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `-m` text and `-F` files for both trailers. It does not establish quoted paths with spaces, which the `[^[:space:]]+` extraction cannot read (pre-existing).

```bash
# hooks/live-verify-gate.sh:145-150 (excerpt ends :150; the loop closes on that line — read)
msg="$cmd"
while read -r f; do
  ...
  if [ -r "$f" ]; then msg="$msg"$'\n'"$(cat "$f")"; fi
done < <(printf '%s' "$cmd" | grep -Eo -- '(-F|--file)(=|[[:space:]]+)[^[:space:]]+' | sed -E 's/^(-F|--file)(=|[[:space:]]+)//')
```

Bats `reads the trailer from a -F message file`, `blocks when the -F message file lacks the trailer` and T1's `-F` case passed.

**Evidence:** `hooks/live-verify-gate.sh:143-154`, `docs/reviews/execution-logs/fc-q089b/bats-gate-src.log`

---

## Claim 32: Test name "every manifest-hashed file is in the enforcement set" and its comment "a file added there without widening the hook's regex goes red"

**Location:** `test/hooks/live-verify-gate.bats:110-113`
**Type:** Invariant
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test's assertions establish after the gate split. The test lines are outside the diff, but the diff changed what they mean.

The loop asserts only that a commit with no trailer is blocked:

```bash
# test/hooks/live-verify-gate.bats:128-131 (excerpt ends :131; enclosing @test continues to :136 — read)
    git add "devcontainer-config/$f"
    run bash "$HOOK" <<< "$(payload 'git commit -m "x"')"
    [ "$status" -eq 2 ] || { echo "not gated: $f"; return 1; }
    git reset -q "devcontainer-config/$f"
```

Before 12e149fc a block meant "in the enforcement set". Now a manifest-hashed file matched only by `host_tools` is also blocked, so the test stays green while the file needs only `Host-tool-tested:`. Mutation M3 confirms it: 25/25 green with `init-firewall.sh` moved to the host regex. The precise version would also assert that `Live-verified:` is named, or that `Host-tool-tested:` alone does not pass.

**Evidence:** `test/hooks/live-verify-gate.bats:110-136`, `docs/reviews/execution-logs/fc-q089b/probe-mutation-m3.log`

---

## Claim 33: Test "a host-tool commit needs Host-tool-tested, and Live-verified alone does not do"

**Location:** `test/hooks/live-verify-gate.bats:283-297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `cc-push.sh` only. The other two tools are covered by Claim 36's loop.

It asserts that no trailer gives 2 with `Host-tool-tested:` and the path in the output, that `Live-verified: no — n/a` gives 2, that `Host-tool-tested: no — bats only` gives 0, and that a `-F` file gives 0 (`:286-296`, e.g. `[[ "$output" != *"Live-verified: <hash>"* ]]`). It passed (ok 22).

**Evidence:** `test/hooks/live-verify-gate.bats:283-297`, `docs/reviews/execution-logs/fc-q089b/bats-gate-src.log`

---

## Claim 34: Test "a commit touching a boundary file and a host tool needs both trailers"

**Location:** `test/hooks/live-verify-gate.bats:299-311`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each trailer alone failing with the other set's message and both passing. It does not establish the no-trailer case (probe G4 did: both messages).

```bash
# test/hooks/live-verify-gate.bats:302-310 (excerpt ends :310; @test closes :311 — read)
  run bash "$HOOK" <<< "$(payload 'git commit -m "x" -m "Host-tool-tested: no — bats"')"
  [ "$status" -eq 2 ]
  [[ "$output" == *"live verification"* ]]
  [[ "$output" != *"host-only tool"* ]]
  ...
  run bash "$HOOK" <<< "$(payload 'git commit -m "x" -m "Live-verified: no — sandbox" -m "Host-tool-tested: no — bats"')"
  [ "$status" -eq 0 ]
```

**Evidence:** `test/hooks/live-verify-gate.bats:299-311`, `docs/reviews/execution-logs/fc-q089b/bats-gate-src.log`

---

## Claim 35: Test "a comment-only host-tool edit beside a real boundary change needs only Live-verified" and its comment "Committed first: a NEW file is substantive whatever its text says."

**Location:** `test/hooks/live-verify-gate.bats:313-323`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "only" half (Live-verified suffices). It does not establish the "needs" half inside this test, and it does not cover the reverse direction (Claim 30).

The single assertion is `Live-verified` → 0 (`:321-322`). Nothing asserts that the same staging without a trailer is blocked, so the test also passes if the per-set escape wrongly cleared both sets. The `Live-verified`-is-required property comes from T1-era tests on other fixtures. The comment is accurate: `new file mode` makes `comment_only_diff` return 1 (`hooks/live-verify-gate.sh:103`).

**Evidence:** `test/hooks/live-verify-gate.bats:313-323`, `hooks/live-verify-gate.sh:103`

---

## Claim 36: Test "every host_tool_files entry is gated by the host-tool trailer, none by Live-verified"

**Location:** `test/hooks/live-verify-gate.bats:325-340`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function ⊆ host regex direction (and that no listed tool needs `Live-verified`). It does not establish the reverse direction. No test pins the gate's `host_tools` regex to `host_tool_files` from the regex side.

The test sources the real function and loops over it (`:327-339`). It passed. Mutation results: M1 (an extra name `cc-extra\.sh` added to the gate's `host_tools` regex) kept the gate suite at 25/25. M2 (dropping `cc-gitdir.sh` from `host_tool_files()`) also kept the gate suite at 25/25. M2 would be caught by `test/cc-isolated-functions.bats:849`'s exact-list assertion, not by the gate suite. M3 (Claim 11b) shows a boundary file moved into the regex is not caught anywhere. So the caller's question "is there a test pinning the regex to host_tool_files, both directions?" gets this answer: one direction only (function → regex). The reverse has no test, and moving a boundary file into the host regex is the case that matters.

Command: `bash run-probes.sh <logdir>` (mutation section). Cwd: probe dir `/mut`. Exit 0. 2026-10-15T00:50:05Z.

**Evidence:** `test/hooks/live-verify-gate.bats:325-340`, `docs/reviews/execution-logs/fc-q089b/probe-mutation.log`, `docs/reviews/execution-logs/fc-q089b/probe-mutation-m3.log`

---

## Claim 37: "live-verify-gate.bats 25/25."

**Location:** commit `12e149fc` message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both 12e149fc and 9001bf80 trees under a redirected HOME. The `wired into the live settings.json` test (ok 20) read, and did not write, the settings file resolved through the environment's `CLAUDE_CONFIG_DIR`. This class of claim matches the logged "All 85 tests" / "mode1-equiv 33" tally pattern, and here the count holds.

Command: `timeout 300 bats test/hooks/live-verify-gate.bats` in `<probe>/s12` and `<probe>/src`. Both gave `1..25`, all `ok`, exit 0. Start 2026-10-15T00:48:29Z.

**Evidence:** `docs/reviews/execution-logs/fc-q089b/bats-gate-s12.log`, `docs/reviews/execution-logs/fc-q089b/bats-gate-src.log`

---

## Claim 38: "Stacked on unit A (dce5b039)."

**Location:** commit `12e149fc` message
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit's ancestry. 9001bf80's message records the re-stack, so the branch history as a whole is not misleading.

`git rev-parse 12e149fc^` is `cc2640b7`, and `git merge-base --is-ancestor dce5b039 12e149fc` fails. 12e149fc is an unchanged cherry-pick (`git range-diff`: `66904a84 = 12e149fc`) whose original sat on `840f39b0` (A2). The message came over from before the A1/A2 re-cut. (Paraphrased — no quote available because the claim is about commit ancestry, not file content.)

**Evidence:** commit `12e149fc`, commit `66904a84`, commit `cc2640b7`

---

## Claim 39: "Notes: the installed copy of the gate stays the old one until install.sh runs, so commits still need Live-verified for host tools meanwhile."

**Location:** commit `12e149fc` message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers install.sh copying hooks to `~/.claude` and the old gate's regex including the host tools. It does not inspect the live installed copy (not read, per the brief's constraint on real dirs).

`install.sh`'s header names the second destination: "the global Claude Code files in ~/.claude for bare-host sessions (decision 037): CLAUDE.md, skills, workflows, guides, patterns, hooks, scripts" (`install.sh:7-9`). At cc2640b7 the gate's enforcement regex included `cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh` (the diff's removed line at `hooks/live-verify-gate.sh:73`).

**Evidence:** `devcontainer-config/install.sh:2-9`, `hooks/live-verify-gate.sh:73`

---

## Claim 40: "Re-stacked on A2 cc2640b7 (cherry-picks of 66904a84 and 613c0ade)."

**Location:** commit `9001bf80` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers 12e149fc and 3f53f503 being content-identical picks. 9001bf80 itself is new.

`git range-diff` gives `66904a84 = 12e149fc` and `613c0ade = 3f53f503`, and `12e149fc^` is `cc2640b7`. (Paraphrased — no quote available because the claim is about commit identity.)

**Evidence:** commits `66904a84`, `613c0ade`, `12e149fc`, `3f53f503`

---

## Claim 41: "row 71 and the guide … the positive repo marker, the boundary diff on refusal, the cc-push warning, --list per entry point, the atomic bless. Q-147 (the split-out static source guard) is named."

**Location:** commit `3f53f503` message
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the five behaviours as listed (each checked in Claims 4–8) and the row naming Q-147. It does not make the Q-147 entry exist (Claim 14).

Four of the five are as described. "Atomic bless" overstates it. The code's own comment says the two renames can split:

```bash
# devcontainer-config/cc-isolated.sh:268-271
# Both manifests are computed into temp files first and moved into place only when
# both succeed, so a bless that fails to compute either changes neither. The two
# same-directory renames can still split (one fails, or an interrupt lands between
# them): host-tools.sha256 is then new and manifest.sha256 old, …
```

Row 71 itself says "moves them into place only when both compute", which is accurate. Only the commit message says "atomic".

**Evidence:** `devcontainer-config/cc-isolated.sh:268-305`, `docs/decisions/log.md:94`

---

## Claims Requiring Attention

### Incorrect
- **Claim 14** (`docs/decisions/log.md:94`): Q-147 does not exist on any ref or worktree. File the entry (next-id on fresh main) or drop the ID before merging.

### Stale
- **Claim 26** (`hooks/live-verify-gate.sh:1-3,13-21,34-39`): the header and Behavior table still describe one Live-verified gate. A host-tool-only commit with no trailer exits 2 ("no enforcement file staged → exit 0" is now false), and a Live-verified trailer no longer passes a host tool.
- **Claim 29** (`hooks/live-verify-gate.sh:84-89`): "restricted to the enforcement files". The escape now reads whichever set is passed as `$1`.
- **Claim 32** (`test/hooks/live-verify-gate.bats:110-113`): "every manifest-hashed file is in the enforcement set" asserts only exit 2, so a boundary file moved into the gate's host regex stays green (M3: 25/25, and `init-firewall.sh` commits with only `Host-tool-tested:`).
- **Claim 38** (commit 12e149fc): "Stacked on unit A (dce5b039)". The parent is cc2640b7, and dce5b039 is not an ancestor.

### Mostly Accurate
- **Claim 4** (`docs/decisions/log.md:94`) and **Claim 24** (`guides/devcontainer-setup.md:276-284`): the launcher also answers `--help` (exit 0) and usage errors, not only `--bless`/`--list`.
- **Claim 11b** (`docs/decisions/log.md:94`): "category swap covered" holds for cc-isolated.sh's lists, not for the gate's regexes (M3).
- **Claim 18** (`guides/cc-isolated-usage.md:927`): the same refusal header fires for a missing or malformed `host-tools.sha256`, not only a changed tool.
- **Claim 22** (`guides/devcontainer-setup.md:264-267`): the enforcement list omits `projects/*.profile`, and `egress/` is `egress/*.txt`.
- **Claim 27** (`hooks/live-verify-gate.sh:70-73`): "Keep in step with that function" covers `enforcement_files()` only. The host regex has no keep-in-step note, and neither regex is pinned in reverse.
- **Claim 35** (`test/hooks/live-verify-gate.bats:313`): the test asserts "only", never "needs" (no no-trailer run).
- **Claim 41** (commit 3f53f503): "atomic bless". The two renames can split, per the code's own comment.

### Unverifiable
- (none)

---

## Goal-Alignment Note

The goal is to review unit B's gate split and its docs before merge (iteration 1 of 3, full scope). The code does what the PR says. Every behavioural statement about A1/A2 in row 71 and both guides held when executed against 9001bf80. The written-before-the-fix-rounds risk did not materialize except for the `--help` exception and the troubleshooting row's narrow reading of the refusal header. The suite count (25/25) holds at both commits.

Two findings bear on whether the gate meets its own intent:

1. **The gate's two regexes are not pinned against a category swap from the regex side** (Claims 11b, 32, 36). That swap is exactly what row 71 lists as covered. Moving a boundary file into `host_tools` leaves all 25 gate tests green and lets that file commit with `Host-tool-tested:` alone, which silently drops a `Live-verified:` gate. The existing enforcement-set test checks only "blocked". A one-line strengthening (e.g. assert `Host-tool-tested: no` alone still exits 2 for each `enforcement_files` entry), plus a reverse check for the host regex, would close it. That answers the caller's direct question: only the function → regex direction is pinned.
2. **The Q-147 reference dangles** (Claim 14). It is the only Incorrect verdict, and it was logged to `docs/reviews/hallucination-patterns.md`.

The remaining items are stale comments in the gate's header and escape block, a stale stacking line in 12e149fc, and minor precision gaps. None of them changes behaviour.
