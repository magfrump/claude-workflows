Commit: afe1ae59

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q089 (branch feat/q089a2b-cc-push-self-check)
**Scope:** `git diff 4ab9a51f afe1ae59 -- devcontainer-config test` (units A1+A2, final confirming pass, replicate r2), plus the commit messages `git log 4ab9a51f..afe1ae59`. Unit B (`/workspace/.claude/wt-q089b`, feat/q089b4-host-tool-gate, stacked on afe1ae59) read as sibling context for row 71 and `Host-tool-tested:`.
**Checked:** 2026-10-14
**Total claims checked:** 36
**Summary:** 30 verified, 3 mostly accurate, 1 stale, 1 incorrect, 1 unverifiable

Hallucination log `docs/reviews/hallucination-patterns.md` read first. No claim here matches a logged pattern. The suite-count claims were checked against the "specific measured value" class of entries, and every count matches.

Execution provenance (applies to every claim marked `executed`):
- Probe root: `/home/node/.claude/jobs/00bcf178/tmp/fcr2.OUcOVA` (mktemp -d). Trees came from `git archive afe1ae59`. HOME, TMPDIR, CC_PUSH_CLONES_DIR and CLAUDE_DEVC_CONFIG_DIR all pointed inside the root, with LC_ALL=C and a stub `devcontainer` first on PATH.
- Run 1: `timeout 1800 bash fcr2-run.sh <root>`, started 2026-10-15T01:32:51Z, exit 0. Script: `docs/reviews/execution-logs/fc-q089a-final-r2/probe.sh.txt`. Output: `run.log`.
- Run 2: `timeout 1000 bash fcr2-run2.sh <root>`, started 2026-10-15T01:34:50Z, exit 0. Script: `probe2.sh.txt`. Output: `run2.log`. Captured TAP: `s1-iso-partial-archive.tap`, `s1b-iso-whole-tree.tap`, `s1-push.tap`. All files are in the same directory.
- I started no long-lived processes. The bats processes still visible in `ps` belong to other sessions' probe roots (`fcr3full.*`, `fcfinal.*`, `fc-it2.*`). I did not touch them.

---

## Claim 1: "it is a host tool (decision log row 71), so the bless hashes it into host-tools.sha256, not the boundary manifest, and cc-isolated.sh checks it against that file before sourcing it."

**Location:** `devcontainer-config/cc-exit-scan.sh:4-6`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which manifest gets the file and the order of check before source in cc-isolated.sh. Does not establish what happens to sourcers other than cc-isolated.sh (there are none; see claim 2).

`enforcement_files` (`cc-isolated.sh:128-151`) no longer lists the file, and `host_tool_files` does: `echo "cc-exit-scan.sh"` (`cc-isolated.sh:200`). The source call sits inside the success branch of the check:
```sh
# devcontainer-config/cc-isolated.sh:715-721
CC_ISOLATED_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
HOST_TOOLS_ERR=""
if HOST_TOOLS_ERR="$(verify_host_tools "$CC_ISOLATED_DIR" cc-exit-scan.sh cc-gitdir.sh)"; then
  # shellcheck source=cc-exit-scan.sh
  source "$CC_ISOLATED_DIR/cc-exit-scan.sh"
else
```
In run 1 P2, the post-bless `manifest.sha256` (16 entries) contains no host tool, and `host-tools.sha256` holds exactly the three. Row 71 exists in unit B (`wt-q089b:docs/decisions/log.md:94`).

**Evidence:** `devcontainer-config/cc-isolated.sh:128-151`, `devcontainer-config/cc-isolated.sh:199-203`, `devcontainer-config/cc-isolated.sh:715-722`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (P2)

---

## Claim 2: "Both entry points check it against that file before it is sourced: cc-push for itself, the launcher for cc-exit-scan.sh."

**Location:** `devcontainer-config/cc-gitdir.sh:5-6`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the only two `source` sites of cc-gitdir.sh (cc-push.sh, cc-exit-scan.sh). Does not establish a TOCTOU-free check (row 71 lists TOCTOU as not covered).

cc-exit-scan.sh sources it at its top level: `source "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/cc-gitdir.sh"` (`cc-exit-scan.sh:12`). The launcher checks `cc-exit-scan.sh cc-gitdir.sh` before sourcing the scan (claim 1). cc-push checks `cc-push.sh cc-gitdir.sh` and then runs `source "$CC_PUSH_DIR/cc-gitdir.sh"` (`cc-push.sh:204-215`). No other `source` of cc-gitdir.sh exists (paraphrased; no quote available because this is a claim about absence, checked by `grep -n cc-gitdir` over devcontainer-config).

**Evidence:** `devcontainer-config/cc-exit-scan.sh:11-12`, `devcontainer-config/cc-push.sh:200-215`, `devcontainer-config/cc-isolated.sh:715-722`

---

## Claim 3: "a bats test now pins PAYLOAD ⊆ this list ∪ host_tool_files, the two disjoint"

**Location:** `devcontainer-config/cc-isolated.sh:118-121`
**Type:** Invariant / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the subset and disjointness assertions. Does not establish that the gate's patterns in unit B stay in step (B has its own pin test).

```sh
# test/cc-isolated-functions.bats:851-859 (excerpt; enclosing test continues to :867 — read)
  [ "$host" = $'cc-exit-scan.sh\ncc-gitdir.sh\ncc-push.sh' ]
  for item in $host; do
    if echo "$enf" | grep -qx "$item"; then echo "in both lists: $item"; return 1; fi
  done
  for item in $items; do
    ...
    printf '%s\n%s\n' "$enf" "$host" | grep -qx "$item" || { echo "PAYLOAD item not hashed: $item"; return 1; }
```
The test passes in run 2 (182/182).

**Evidence:** `test/cc-isolated-functions.bats:835-867`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1b-iso-whole-tree.tap`

---

## Claim 4: host_tool_files header: the image never copies them; a change "leaves blessed_hash (the baked config identity), the verified-live receipt and the container alone"; "Each entry point checks the ones it executes"; "Commits that change them carry `Host-tool-tested:`, not `Live-verified:` (hooks/live-verify-gate.sh)."

**Location:** `devcontainer-config/cc-isolated.sh:191-198`
**Type:** Behavioral / Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the COPY set, blessed_hash independence and which files each entry point checks. The gate sentence is true only once unit B lands: at afe1ae59 the gate still lists them in `enforcement`. Does not establish B's gate behaviour beyond reading its pattern lines.

The Dockerfile COPYs only `egress/`, `init-firewall.sh`, `cc-sni-proxy.py`, `link-claude-home.sh` and `claude-home/` (`Dockerfile:486-500`). `blessed_hash` is `sha256sum < "$m" | cut -c1-16` over manifest.sha256 only (`cc-isolated.sh:88-93`). The test at `test/cc-isolated-functions.bats:869-884` edits cc-push.sh and asserts `check_manifest` returns 0 and `blessed_hash` is unchanged. It passes. In unit B the gate carries `host_tools='^devcontainer-config/(cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh)'` and `need+=("Host-tool-tested")` (`wt-q089b:hooks/live-verify-gate.sh:91,154`). At afe1ae59 the gate's `enforcement=` still names `cc-exit-scan\.sh|cc-gitdir\.sh|cc-push\.sh` (`hooks/live-verify-gate.sh:73`), so the sentence describes the A+B landing.

**Evidence:** `devcontainer-config/Dockerfile:486-500`, `devcontainer-config/cc-isolated.sh:88-93`, `test/cc-isolated-functions.bats:869-884`, `/workspace/.claude/wt-q089b/hooks/live-verify-gate.sh:84-95,154`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1b-iso-whole-tree.tap`

---

## Claim 5: verify_host_tools header: "a test compares the two byte for byte"; "Only a repo checkout is left unchecked … install.sh beside the script (install.sh is never installed, it is not in PAYLOAD), no manifest of either kind, and not the config dir … deleting manifests is not enough to opt an installed copy out. Prints the reason and returns 1 on any mismatch."

**Location:** `devcontainer-config/cc-isolated.sh:219-229` (identical at `devcontainer-config/cc-push.sh:146-156`)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function bodies' identity, the exemption's four conditions and the failure output. The parity test leaves out each block's first marker line, which has to name the other file. Does not establish resistance to a planted install.sh together with deleted manifests in a dir CLAUDE_DEVC_CONFIG_DIR does not name (row 71 lists that as not covered).

```sh
# devcontainer-config/cc-isolated.sh:234-237
  cfg="$(readlink -f -- "${CLAUDE_DEVC_CONFIG_DIR:-$HOME/.config/claude-devcontainer}" 2>/dev/null || true)"
  if [ -f "$dir/install.sh" ] && [ ! -e "$m" ] && [ ! -e "$dir/manifest.sha256" ] && [ "$dir" != "$cfg" ]; then
    return 0
  fi
```
PAYLOAD is `(devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress claude-home)`, with no install.sh (`install.sh:110`). Every failure branch echoes a reason and sets `bad=1` or returns 1 (`cc-isolated.sh:238-268`, read to `return "$bad"`). Run 2 P1b used a dir with install.sh beside it and no manifests: with CLAUDE_DEVC_CONFIG_DIR naming it, `rc=1` and the no-manifest reason; with it not named, `rc=0`. Run 1 P5: the two blocks' first lines differ (`…copy in cc-push.sh` vs `…copy in cc-isolated.sh`), and the test compares from line 2 on (`tail -n +2`, `test/cc-isolated-functions.bats:930-931`).

**Evidence:** `devcontainer-config/cc-isolated.sh:219-270`, `devcontainer-config/cc-push.sh:146-197`, `devcontainer-config/install.sh:110`, `docs/reviews/execution-logs/fc-q089a-final-r2/run2.log` (P1b), `run.log` (P5)

---

## Claim 6: "The two same-directory renames can still split (one fails, or an interrupt lands between them): host-tools.sha256 is then new and manifest.sha256 old, so a launch refuses if the boundary changed too, and otherwise the host tools stand blessed although bless exited 1."

**Location:** `devcontainer-config/cc-isolated.sh:276-280`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rename order and the state each failure point leaves. Does not establish the temp-file cleanup on a rename failure (none happens; not claimed).

```sh
# devcontainer-config/cc-isolated.sh:303-304
  mv -f "$new_h" "$(host_tools_path)"
  mv -f "$new_m" "$(manifest_path)"
```
The host-tools rename runs first. If *that* one fails, set -e (`cc-isolated.sh:66`; `bless) bless_manifest; exit 0` at `:785` is not a conditional context) ends the bless with both files old, so nothing splits. A split ("host-tools new, manifest old") comes only from a failure of the second rename or an interrupt between the two. An interrupt also exits with a signal status, not 1. A precise version would read: "if the second rename fails, or an interrupt lands between them, host-tools.sha256 is new and manifest.sha256 old … although bless did not exit 0." The consequences it states for the split are correct: `check_manifest` compares the old manifest against the current files.

**Evidence:** `devcontainer-config/cc-isolated.sh:66`, `devcontainer-config/cc-isolated.sh:273-319`, `devcontainer-config/cc-isolated.sh:783-786`

---

## Claim 7: "What changed since the previous bless is printed first: the bless is the review, and a host-tool refusal that points here must not let a boundary change through unseen."

**Location:** `devcontainer-config/cc-isolated.sh:280-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diff of both manifests before the renames and before the "Blessed" listing. Does not establish that a user reads it.

In run 1 P2, the output shows `Changed since the last bless (manifest.sha256):` with the three removed host-tool lines, then `No previous host-tools.sha256: every entry below is new to this bless.`, then the "Blessed" listings. In P4 both diffs print: the new `projects/….profile` line and the changed `cc-push.sh` hash.

**Evidence:** `devcontainer-config/cc-isolated.sh:290-302`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (P2, P4)

---

## Claim 8: "The bless command for the dir being checked: names CLAUDE_DEVC_CONFIG_DIR when it is set, so a hint printed for a non-default dir does not bless the default one."

**Location:** `devcontainer-config/cc-isolated.sh:321-322`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bless_cmd's output and the refusal's forced dir. Does not establish that `$0` is runnable from the user's cwd when the launcher was invoked by a relative path.

```sh
# devcontainer-config/cc-isolated.sh:323-329
bless_cmd() {
  if [ -n "${CLAUDE_DEVC_CONFIG_DIR:-}" ]; then
    printf 'CLAUDE_DEVC_CONFIG_DIR=%q %s --bless' "$CLAUDE_DEVC_CONFIG_DIR" "$0"
  else
    printf '%s --bless' "$0"
  fi
}
```
The refusal calls it as `CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" bless_cmd` (`:767`). In P2/P3 every hint printed `CLAUDE_DEVC_CONFIG_DIR=<probe dir> <probe dir>/cc-isolated.sh --bless`.

**Evidence:** `devcontainer-config/cc-isolated.sh:323-329`, `devcontainer-config/cc-isolated.sh:767`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (P2, P3)

---

## Claim 9: --list comment and labels: "the launcher refuses on the two files it executes (and only warns on cc-push); cc-push refuses on itself and cc-gitdir.sh. Checked in config_dir() …"; "Not a bare assignment: readlink -f fails when the dir's parent is missing"; "cc-push: CHANGED — do not run it until re-blessed (an intact copy refuses)".

**Location:** `devcontainer-config/cc-isolated.sh:492-517`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file lists, the dir checked and the labels. Does not establish that the launcher actually in use checks the same dir (the comment itself says it may not).

```sh
# devcontainer-config/cc-isolated.sh:500-503
  cfg_real="$(readlink -f -- "$(config_dir)")" || cfg_real="$(config_dir)"
  lerr="$(verify_host_tools "$cfg_real" cc-exit-scan.sh cc-gitdir.sh)" || true
  perr="$(verify_host_tools "$cfg_real" cc-push.sh cc-gitdir.sh)" || true
```
The lists match the launcher (`:717`) and cc-push (`:204`). P4 printed `launches warn (cc-push changed) but run` and `cc-push: CHANGED — do not run it until re-blessed (an intact copy refuses): …cc-push.sh changed since the last bless`. The missing-parent test (`test/cc-isolated-functions.bats:998-1004`) passes.

**Evidence:** `devcontainer-config/cc-isolated.sh:481-518`, `test/cc-isolated-functions.bats:998-1004`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (P4)

---

## Claim 10: "When the check fails the scan is not loaded, and main refuses every action but --bless and --list (--help and usage errors are answered first; neither touches the scan)."

**Location:** `devcontainer-config/cc-isolated.sh:710-714`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers launch, --probe-only and --register when HOST_TOOLS_ERR is set. Does not establish behaviour when the file is sourced by tests (the check also runs at source time).

`main`'s argument loop (`:732-750`) handles `--help|-h` (`usage; exit 0`) and the usage errors (`exit 2`) before the refusal block `if [ -n "$HOST_TOOLS_ERR" ] && [ "$action" != "bless" ] && [ "$action" != "list" ]` (`:753`), which ends in `exit 1` (`:769`). In P2 a launch refused with rc=1 and `--bless` ran (rc=0). In the tamper test the scan's top-level `touch` never ran through refusal, `--list` or `--bless`, and ran after the re-bless (`test/cc-isolated-functions.bats:937-963`, passing).

**Evidence:** `devcontainer-config/cc-isolated.sh:729-770`, `test/cc-isolated-functions.bats:937-963`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (P2)

---

## Claim 11: Refusal: "run the boundary check too, and show its diff"; notes "The boundary config is unchanged: the re-bless changes no boundary state, so it causes no rebuild …" / "The BOUNDARY config changed too (above)…"

**Location:** `devcontainer-config/cc-isolated.sh:756-761`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both note branches in three states: unchanged, changed, and no manifest.sha256. Does not establish rebuild behaviour in a real container (no Docker).

```sh
# devcontainer-config/cc-isolated.sh:758-761
    local line boundary_note="The boundary config is unchanged: the re-bless changes no boundary state, so it causes no rebuild (a config not yet verified live is still probed at its next launch, as before)."
    if ! CLAUDE_DEVC_CONFIG_DIR="$CC_ISOLATED_DIR" check_manifest; then
      boundary_note="The BOUNDARY config changed too (above). Review that diff as well: the re-bless accepts both, and the next launch then rebuilds and probes."
    fi
```
The diff is shown and the unchanged branch is correct (P2; tests at `:937-996`). However, `check_manifest` also fails when there is **no** manifest.sha256 (`:334-338`). In run 1 P3 that state printed `ERROR: no blessed manifest at …` followed by "The BOUNDARY config changed too (above). Review that diff as well". There is no diff "above", and nothing changed; the boundary was never blessed. More precisely: "The boundary config changed too, or was never blessed (above)."

**Evidence:** `devcontainer-config/cc-isolated.sh:332-352`, `devcontainer-config/cc-isolated.sh:753-770`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (P2, P3)

---

## Claim 12: "Only a cc-push.sh-specific reason: a manifest-level one is already above."

**Location:** `devcontainer-config/cc-isolated.sh:763-766`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the filter `[[ "$push_err" == *cc-push.sh* ]]` against verify_host_tools' messages. Does not establish the filter's behaviour when the install dir's own path contains the string `cc-push.sh` (the manifest-level message would then pass it).

The manifest-level messages name only `$m` (`…/host-tools.sha256`) (`:239-246`). Per-file messages end in `$dir/$f` or `for $f` (`:252-265`). The refusal test asserts the `also changed — do not run cc-push` line for a real cc-push change (`test/cc-isolated-functions.bats:990`). In P2 and P3 (manifest missing) no such line printed.

**Evidence:** `devcontainer-config/cc-isolated.sh:238-268`, `devcontainer-config/cc-isolated.sh:763-766`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (P2, P3)

---

## Claim 13: "cc-push is not executed by the launcher, so a change to it never blocks a launch, but the launcher still says so: cc-push's self-check cannot catch a tampered cc-push that skips it."

**Location:** `devcontainer-config/cc-isolated.sh:772-774`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a cc-push-only change at launch, probe and register. Does not establish that the warning is acted on (see claim 15 for --register).

`HOST_TOOLS_ERR` covers only `cc-exit-scan.sh cc-gitdir.sh` (`:717`). The cc-push check at `:775-779` only echoes `WARNING:`. The launcher never runs cc-push.sh (paraphrased; no quote available because this is a claim about absence, from grepping cc-isolated.sh for `cc-push.sh` invocations). The test at `:1056-1076` asserts the WARNING and no "refusing to launch". In P4, `--register` ran with rc=0 after the WARNING.

**Evidence:** `devcontainer-config/cc-isolated.sh:717`, `devcontainer-config/cc-isolated.sh:772-779`, `test/cc-isolated-functions.bats:1056-1076`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (P4)

---

## Claim 14: "when this installed copy or the cc-gitdir.sh beside it differs from what the bless recorded in host-tools.sha256 (or that file is missing, a symlink, unreadable or malformed), cc-push exits 1 before parsing anything, --help included (decision log row 71)."

**Location:** `devcontainer-config/cc-push.sh:35-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an installed copy (no install.sh beside it). Does not establish behaviour for a repo checkout, which is exempt by design.

The check is top-level code before `main` (`cc-push.sh:204-213`, `exit 1`). Main runs only under the guard at `:592-595`. `test/cc-push.bats:797-828` asserts exit 1 for `--help` on a changed cc-push.sh and on a deleted manifest. It passes 48/48 (run 1). Row 71 is in unit B.

**Evidence:** `devcontainer-config/cc-push.sh:200-215`, `devcontainer-config/cc-push.sh:592-595`, `test/cc-push.bats:797-828`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1-push.tap`

---

## Claim 15: "a tampered copy that skips its own check is caught only by cc-isolated's warning at the next launch of the copy installed beside it, and by `cc-isolated --list` for the config dir."

**Location:** `devcontainer-config/cc-push.sh:41-43`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which observers report a changed cc-push.sh and what clears it. Does not establish anything about a copy that also rewrites host-tools.sha256 (row 71: not covered).

The two observers named are real (claims 9 and 13). But "next launch" also covers `--register`, and `--register` re-blesses in the same command: `register_project` ends in `bless_manifest` (`cc-isolated.sh:477`). In run 1 P4, after a cc-push-only change, `--register` printed `WARNING: …cc-push.sh changed since the last bless — do not run cc-push until you have reviewed it and re-blessed.`, then `Changed since the last bless (host-tools.sha256):` with the new hash, then blessed it (rc=0). A following `--list` printed `Host tools — match the bless`. So the warning can be followed at once by an acceptance the user did not ask for. After that, `--list` no longer reports the copy. More precisely: "…caught by cc-isolated's warning at the next launch, probe or register (a register re-blesses it, printing the diff), by `--list` until then, and by the diff any bless prints."

**Evidence:** `devcontainer-config/cc-isolated.sh:434-479`, `devcontainer-config/cc-isolated.sh:775-779`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (P4)

---

## Claim 16: "Checked first: a tampered cc-gitdir.sh would run at source time."

**Location:** `devcontainer-config/cc-push.sh:201-202`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers order of check and source. Does not establish the lines above the check (the header says they are unguarded).

The check (`:204`) precedes `source "$CC_PUSH_DIR/cc-gitdir.sh"` (`:215`). The cc-push test appends `touch …/gitdir-ran` to cc-gitdir.sh and asserts `[ ! -e "$M/gitdir-ran" ]` (`test/cc-push.bats:804-808`). It passes.

**Evidence:** `devcontainer-config/cc-push.sh:200-215`, `test/cc-push.bats:804-808`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1-push.tap`

---

## Claim 17: "The bless hashes it into host-tools.sha256 (a host tool, decision log row 71), which cc-push checks before sourcing cc-gitdir.sh." (and the upgrade path from an install without host-tools.sha256)

**Location:** `devcontainer-config/install.sh:600-602`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers install.sh's bless line on a dir holding an old-style manifest (host tools inside) and no host-tools.sha256. Does not establish the rest of install.sh (copy/review/unwind) on upgrade; only its final bless line was replayed.

install.sh blesses with `CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless` (`install.sh:607`). In run 1 P2 that exact form ran on such a dir. The launcher's top-level check failed (no host-tools.sha256), but `--bless` is exempt. It printed the manifest diff (three host-tool lines removed) and `No previous host-tools.sha256: every entry below is new to this bless.`, then wrote both files (rc=0). `--list` then printed `Host tools — match the bless`. Before that bless, a launch refused, showing both reasons and the boundary diff.

**Evidence:** `devcontainer-config/install.sh:598-610`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (P2)

---

## Claim 18: Test "every regular file in install.sh's PAYLOAD is hashed by enforcement_files or host_tool_files" and its comment (disjoint, host list exactly the three, no COPY of a host tool)

**Location:** `test/cc-isolated-functions.bats:835-867`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named assertion. Does not establish the comment's rationale ("would drop its Live-verified gate"), which depends on B's gate pin.

Each property has an assertion: the exact host list at `:851`, disjointness at `:852-854`, PAYLOAD coverage at `:859`, and no COPY of a host tool at `:861-863`. The test passes.

**Evidence:** `test/cc-isolated-functions.bats:835-867`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1b-iso-whole-tree.tap`

---

## Claim 19: Test "bless writes host-tools.sha256; a host-tool edit leaves the boundary manifest and blessed hash alone"

**Location:** `test/cc-isolated-functions.bats:869-884`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file's entries, check_manifest status and blessed_hash after a cc-push edit. Does not establish the same for cc-exit-scan.sh or cc-gitdir.sh edits.

The test asserts the three names in host-tools.sha256, none in manifest.sha256, `check_manifest` status 0, `blessed_hash` unchanged, and `verify_host_tools` reporting the change. It passes.

**Evidence:** `test/cc-isolated-functions.bats:869-884`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1b-iso-whole-tree.tap`

---

## Claim 20: "# The config dir itself is never a repo checkout: no manifest there is refused." (in test "verify_host_tools: repo checkout unchecked; an installed dir must match, and cannot opt out")

**Location:** `test/cc-isolated-functions.bats:921-925`
**Type:** Behavioral (test vs what it asserts)
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether this test case exercises the `"$dir" != "$cfg"` clause. Does not establish the clause's behaviour in the code, which is correct (P1b).

```sh
# test/cc-isolated-functions.bats:921-925
  # The config dir itself is never a repo checkout: no manifest there is refused.
  local c="$TEST_TMPDIR/cfg2"
  mkdir -p "$c"; echo 'a' > "$c/cc-push.sh"
  CLAUDE_DEVC_CONFIG_DIR="$c" run verify_host_tools "$c" cc-push.sh
  [ "$status" -eq 1 ]
```
`$c` has no install.sh, so the first condition `[ -f "$dir/install.sh" ]` already fails and the dir is refused whatever the config-dir clause does. Run 1 mutant M1 removed `&& [ "$dir" != "$cfg" ]` from both copies (grep count 0 afterwards), and this test still printed `ok 1`. The case would not fail if the behaviour it names regressed. To exercise the clause, it needs an `install.sh` in `$c` (and a resolved `$c`, since `cfg` is `readlink -f`'d). Run 2 P1b shows that the real clause does refuse such a dir.

**Evidence:** `test/cc-isolated-functions.bats:886-926`, `devcontainer-config/cc-isolated.sh:234-237`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (M1), `run2.log` (P1b)

---

## Claim 21: Test "verify_host_tools is the same code in cc-isolated.sh and cc-push.sh"

**Location:** `test/cc-isolated-functions.bats:928-935`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the marked block after its first line. Does not establish that callers pass the same file lists.

The test extracts each block with `sed -n '/^# --- verify_host_tools/,/^# --- end verify_host_tools/p' … | tail -n +2` and compares the two with `[ "$a" = "$b" ]`. It also guards against an empty extraction. It passes.

**Evidence:** `test/cc-isolated-functions.bats:928-935`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1b-iso-whole-tree.tap`

---

## Claim 22: Test "launch: a tampered cc-exit-scan.sh is never sourced; --bless still works and clears it"

**Location:** `test/cc-isolated-functions.bats:937-963`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers refusal, --list, --bless and the post-bless load. Does not establish a tamper placed in cc-gitdir.sh at launch (covered only for cc-push).

The tamper is a top-level `touch`. The test asserts `[ ! -e "$mark" ]` after the refusal, `--list` and `--bless`, and `[ -e "$mark" ]` after the re-bless, so the assertion can fail. It passes.

**Evidence:** `test/cc-isolated-functions.bats:937-963`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1b-iso-whole-tree.tap`

---

## Claim 23: Test "launch: a host-tool refusal still shows a boundary change made alongside it, and bless prints both"

**Location:** `test/cc-isolated-functions.bats:965-996`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the boundary diff in the refusal, both bless diffs, indentation and the cc-push line. Does not establish the no-manifest note (claim 11).

The test asserts `installed config changed since last bless`, `init-firewall.sh`, `BOUNDARY config changed too`, both `Changed since the last bless (…)` headers, the indented reasons, the `also changed — do not run cc-push` line and `No previous host-tools.sha256`. It passes.

**Evidence:** `test/cc-isolated-functions.bats:965-996`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1b-iso-whole-tree.tap`

---

## Claim 24: Test "--list still reports everything when the config dir's parent is missing (set -e)"

**Location:** `test/cc-isolated-functions.bats:998-1004`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the status and the three sections. Does not establish other readlink failures.

The test asserts status 0, `No blessed config`, `No blessed host tools…--bless` and `No projects registered`. It passes.

**Evidence:** `test/cc-isolated-functions.bats:998-1004`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1b-iso-whole-tree.tap`

---

## Claim 25: Test "verify_host_tools: an unreadable, empty or malformed manifest, or a missing entry, is named as the problem"

**Location:** `test/cc-isolated-functions.bats:1006-1030`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named states (unreadable only when not root). Does not establish the duplicated-entry message (covered by status only at `:913-915`).

Each state asserts its own message: `unreadable or malformed` (×3), `!= *"changed since the last bless"*`, and `has no entry, or more than one, for cc-push.sh`. It passes.

**Evidence:** `test/cc-isolated-functions.bats:1006-1030`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1b-iso-whole-tree.tap`

---

## Claim 26: Test "bless: a failure changes neither manifest"

**Location:** `test/cc-isolated-functions.bats:1032-1054`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers compute failures of each manifest. Does not establish rename failures (claim 6).

In each case the other manifest's inputs differ from the blessed state (cc-push edited, Dockerfile replaced), so a rewrite would show. The test asserts both files unchanged and no temp files left. It passes.

**Evidence:** `test/cc-isolated-functions.bats:1032-1054`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1b-iso-whole-tree.tap`

---

## Claim 27: "# A scan-only change: launches refuse, cc-push (which does not run the scan) does not." with `[[ "$output" != *"cc-push refuses"* ]]`

**Location:** `test/cc-isolated-functions.bats:1071-1075`
**Type:** Behavioral (test vs what it asserts) / Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the negative half of the scan-only case in --list. Does not establish anything about the positive half (`launches refuse:`), which is live.

afe1ae59 changed the --list line from `'  cc-push refuses: %s\n'` to `'  cc-push: CHANGED — do not run it until re-blessed (an intact copy refuses): %s\n'` (`cc-isolated.sh:517`). The same commit updated the refusal test's string at `:990`, but this assertion still looks for `cc-push refuses`. --list can no longer print that string, so the assertion cannot fail. Run 1 mutant M2 made `perr` also check `cc-exit-scan.sh`, so --list flags cc-push on a scan-only change, and the test still printed `ok 1`. The current form would be `[[ "$output" != *"cc-push: CHANGED"* ]]`.

**Evidence:** `test/cc-isolated-functions.bats:1056-1076`, `devcontainer-config/cc-isolated.sh:517`, `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (M2)

---

## Claim 28: Test "installed copy: cc-push checks itself and cc-gitdir.sh before sourcing, and refuses on a change (row 71)" and its comments ("A tamper directly below the check (the first line it guards) never runs"; "Deleting the host manifest does not turn the installed copy into a repo checkout")

**Location:** `test/cc-push.bats:797-828`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the gitdir tamper, the self tamper placed just above `# shellcheck source=cc-gitdir.sh`, the hint text and the deleted manifest. Does not re-run a mutant this round (it2/it3 mutant logs under `docs/reviews/execution-logs/fc-q089a-it3/` show the self-tamper assertion failing without the check).

The awk puts `touch …/push-tamper-ran` before `# shellcheck source=cc-gitdir.sh`, which is after the check's `fi` (`cc-push.sh:213-214`). The test asserts the file is absent and the hint is `CLAUDE_DEVC_CONFIG_DIR=$d cc-isolated --bless`. The deleted-manifest case keeps a `manifest.sha256`, so it is not exempt. It passes (48/48).

**Evidence:** `test/cc-push.bats:797-828`, `devcontainer-config/cc-push.sh:200-215`, `docs/reviews/execution-logs/fc-q089a-final-r2/s1-push.tap`

---

## Claim 29: "Tests under LC_ALL=C: cc-isolated-functions 182/182, cc-push 48/48." (afe1ae59, f737ba71)

**Location:** commit afe1ae59 message; commit f737ba71 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers afe1ae59 on a whole-tree archive. Does not establish f737ba71's pass (its counts match; its suite was not re-run).

Run 2 on the whole tree: `plan 1..182 ok 182 notok 0`. Run 1, cc-push: `plan 1..48 ok 48 notok 0`. Run 1's archive held only `devcontainer-config test`, and five "Gate 1h" tests failed there because they read files outside that subset. The whole-tree rerun passes them, so those failures are environmental. `bats --count` at f737ba71 gives iso=182, push=48.

**Evidence:** `docs/reviews/execution-logs/fc-q089a-final-r2/s1b-iso-whole-tree.tap`, `s1-push.tap`, `s1-iso-partial-archive.tap`, `run.log` (S2)

---

## Claim 30: Earlier counts: "cc-isolated-functions 181/181" (b3b37e16); "cc-push 48/48" (4be0445d, 2cb03f23, cc2640b7)

**Location:** commits b3b37e16, 4be0445d, 2cb03f23, cc2640b7
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the test counts at each commit (`bats --count`). Does not establish the pass status at those commits (not re-run).

S2: `b3b37e16 iso=181 push=47`, `4be0445d iso=182 push=48`, `2cb03f23 … push=48`, `cc2640b7 … push=48`.

**Evidence:** `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (S2)

---

## Claim 31a: "A1 is 418 lines after this round (392 when the loop started)." (b3b37e16)

**Location:** commit b3b37e16 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers added+removed lines outside docs/ against 4ab9a51f (decision log 62's counting rule). Does not establish other counting bases.

`git diff --shortstat 4ab9a51f f2533b33 -- . ':!docs'` gives 370 insertions and 22 deletions, which is 392. The same at b3b37e16 gives 396 and 22, which is 418.

**Evidence:** `git diff --shortstat 4ab9a51f b3b37e16 -- . ':!docs'` (run in /workspace/.claude/wt-q089, exit 0, 2026-10-15 before run 1's 01:32:51Z start; read-only git, output quoted above, not captured to a file), `docs/decisions/log.md` row 62

---

## Claim 31b: "After the iteration-4 split, the unit was 485 lines." (f2533b33)

**Location:** commit f2533b33 message
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the existence of the referenced branch commits. Does not establish the 485 figure.

The figure is for an intermediate cut of the pre-recut branch (`dce5b039..548fe6f9`, both present), and its base and file set are not named. I did not reconstruct it. Verifying it needs the exact tree the count was taken on.

**Evidence:** commits `dce5b039`, `548fe6f9` (exist), `docs/reviews/code-review-rubric-2026-10-14-feat-q089-host-tool-trust.md` (exists at afe1ae59)

---

## Claim 32: afe1ae59's itemised changes (security F1 wording; api F1 cc-push-specific line; api F2 neutral header; api F3 indent; api F5 message; 17b rubric; shellcheck disable lines on probe scripts)

**Location:** commit afe1ae59 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each item against `git show afe1ae59`. Does not establish that the test assertions were all updated to match (claim 27: one was not).

The diff shows each item. The --list line becomes `cc-push: CHANGED — … (an intact copy refuses)`. `&& [[ "$push_err" == *cc-push.sh* ]]` is added. `ERROR: host-tool check failed — …` replaces `host tools differ from the bless`. cc-push's `  Review the host tools…` gains the indent. `has no entry, or more than one, for $f` appears in both copies. The A2 rubric gains `**Merge constraint:** A2 lands together with A1 …`. `docs/reviews/execution-logs/fc-q089a1/probe.sh` gains `# shellcheck disable=SC2010 …` after its shebang.

**Evidence:** `git show afe1ae59` (devcontainer-config/cc-isolated.sh, cc-push.sh, docs/reviews/code-review-rubric-2026-10-14-feat-q089a2-cc-push-self-check.md, docs/reviews/execution-logs/fc-q089a1/probe.sh:2)

---

## Claim 33: "Notes: security F2 (an exported shell function standing in for sha256sum) goes to row 71's not-covered list in unit B."

**Location:** commit afe1ae59 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers row 71's text in unit B. Does not establish anything in A.

Row 71 in B reads "Not covered: … a `sha256sum` or `awk` stand-in, on PATH or as an exported shell function, that prints the blessed hash".

**Evidence:** `/workspace/.claude/wt-q089b/docs/decisions/log.md:94`

---

## Claim 34: "Correction to 840f39b0's message: before this, that test's tamper was an inert comment." (2cb03f23)

**Location:** commit 2cb03f23 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the self-tamper in 840f39b0's cc-push test. Does not establish the cherry-pick cleanliness claimed in cc2640b7 (both source commits exist).

At 840f39b0 the tamper was `printf '\n# edited\n' >> "$d/cc-push.sh"` (`test/cc-push.bats:811` at that commit), which is a comment.

**Evidence:** `git show 840f39b0:test/cc-push.bats` lines 809-812

---

## Claim 35: "Live-verified: no — … blessed_hash changes once on the next install.sh" (f2533b33)

**Location:** commit f2533b33 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the manifest's content change on upgrade. Does not establish the live probe that follows (no Docker).

In P2 the upgrade bless dropped three lines from manifest.sha256. blessed_hash hashes that file (claim 4), so it changes once, and later host-tool-only blesses leave it alone.

**Evidence:** `docs/reviews/execution-logs/fc-q089a-final-r2/run.log` (P2), `devcontainer-config/cc-isolated.sh:88-93`

---

## Claims Requiring Attention

### Incorrect
- **Claim 20** (`test/cc-isolated-functions.bats:921-925`): the "config dir is never a repo checkout" case has no install.sh in `$c`, so it passes without the `"$dir" != "$cfg"` clause (mutant M1 survives). Add `install.sh` to `$c` (and use a resolved `$c`).

### Stale
- **Claim 27** (`test/cc-isolated-functions.bats:1075`): `!= *"cc-push refuses"*` was not updated when afe1ae59 renamed the --list line. It is now vacuous (mutant M2 survives). Assert `!= *"cc-push: CHANGED"*`.

### Mostly Accurate
- **Claim 6** (`devcontainer-config/cc-isolated.sh:276-280`): only a failure of the second rename, or an interrupt between the two, splits the pair. A failure of the first leaves both old, and an interrupt does not exit 1.
- **Claim 11** (`devcontainer-config/cc-isolated.sh:760`): "The BOUNDARY config changed too (above). Review that diff" also prints when there is no manifest.sha256 at all, where there is no diff and nothing changed.
- **Claim 15** (`devcontainer-config/cc-push.sh:41-43`): `--register` warns about a changed cc-push and then re-blesses it in the same command, after which `--list` reports a match. The header (and the WARNING's "until you have reviewed it and re-blessed") does not say so.

### Unverifiable
- **Claim 31b** (commit f2533b33): "485 lines after the iteration-4 split" would need the exact intermediate tree and base it was counted on.

---

## Goal-Alignment Note

The PR's goal is that host-only tools leave the boundary manifest, so that editing one costs a re-bless and not a rebuild or probe, while every entry point refuses to source an unblessed copy. The code does this. A host-tool-only change leaves blessed_hash alone. The launcher and cc-push both check before sourcing, and the tamper tests show that sourced code never runs. The repo-checkout exemption needs positive marking and refuses the config dir. Bless shows both diffs before it accepts. install.sh's bless line upgrades an old install cleanly.

Three gaps are worth weighing before the merge:

1. **Two tests cannot fail on the regressions they name (claims 20, 27).** Both are one-line fixes. Both mutants survive today, so the config-dir clause and the "scan-only change does not flag cc-push" behaviour have no regression coverage. The code is correct today: P1b and the visible --list output.
2. **`--register` silently re-blesses a changed cc-push (claim 15).** It is the one path where the launcher's "do not run cc-push until reviewed and re-blessed" warning is followed in the same command by that re-bless. The bless prints the diff, so the change is seen, but it is not chosen. Under row 45's non-targeted threat model this is a review-surface issue, not a bypass. It may deserve either a line in row 71 or a refusal to re-bless host tools from `--register`. That is a design call; it is outside this report's remit.
3. **The no-manifest boundary note (claim 11)** wording is cosmetic.

None of these contradicts the PR's stated threat model or Unit B's row 71.
