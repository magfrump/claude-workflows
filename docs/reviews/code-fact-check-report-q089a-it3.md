# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q089 (branch feat/q089a2b-cc-push-self-check)
**Commit:** f737ba71
**Replication:** k=1 (loop pass, decision 031)
**Scope:** `git diff b3b37e16 f737ba71 -- devcontainer-config test` (A2's re-stacked 4be0445d, 2cb03f23, cc2640b7 and the joint fix f737ba71, plus A1's files); f737ba71's commit message in full. 2cb03f23/cc2640b7 claims re-verified only where f737ba71 touched them. Everything up to b3b37e16 is committed context; unit B (wt-q089b) is sibling context.
**Checked:** 2026-10-14
**Total claims checked:** 19
**Summary:** 18 verified, 0 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`); no claim below matches a logged pattern, and the one Incorrect is not a fabricated symbol, so nothing is appended.

**Probe environment (all executed claims).** A fresh `mktemp -d` root, `/home/node/.claude/jobs/00bcf178/tmp/fc-it3.CZsD1G`, holding `src/` from `git archive f737ba71`; `HOME`, `TMPDIR`, `CC_PUSH_CLONES_DIR` and `CLAUDE_DEVC_CONFIG_DIR` were all redirected under it, with `LC_ALL=C`, a stub `devcontainer`, and every command under `timeout`. install.sh never ran. The installed layouts were copies with no install.sh, blessed via `CLAUDE_DEVC_CONFIG_DIR=<dir> cc-isolated.sh --bless`. Mutants `m1`..`m7` are copies of `src/` with one edit each, and each log shows its diff. Probe scripts: `docs/reviews/execution-logs/fc-q089a-it3/probe.sh`, `probe2.sh`. The bats processes still running at the end belong to another session (`/workspace/.claude/wt-q089b/test/install-host.bats`), not to this run.

---

# Unit A1: cc-isolated.sh and its tests

## Claim 1: "The no-manifest reason no longer carries a bare `cc-isolated --bless`." (f737ba71, A1)

**Location:** `devcontainer-config/cc-isolated.sh:239`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every reason string `verify_host_tools` can print (no-manifest, malformed, missing/symlink, no-single-entry, changed): none names a bless command. Does not establish what the trailing hint lines (cc-push's `CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless`, the launcher's `bless_cmd`) say; it2 reviewed those.

```sh
# devcontainer-config/cc-isolated.sh:239
    echo "no host-tool manifest at $m (re-run install.sh, or review the tools and bless this dir)"
```
The other four reason echoes in the same function (`:243-269`, read) carry no command. Run with the manifest missing and then as a symlink, the byte-identical cc-push copy printed `no host-tool manifest at …/inst/host-tools.sha256 (re-run install.sh, or review the tools and bless this dir)`, and the only bless command in the output was the dir-qualified hint line.

Provenance: `timeout 600 bash docs/reviews/execution-logs/fc-q089a-it3/probe.sh <root>`, cwd `<root>`, exit 0, 2026-10-15T01:07:17Z (P2).

**Evidence:** `devcontainer-config/cc-isolated.sh:230-270`, `docs/reviews/execution-logs/fc-q089a-it3/03-probes.log`

---

## Claim 2: "An empty manifest counts as malformed." (f737ba71, A1)

**Location:** `devcontainer-config/cc-isolated.sh:244`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a zero-byte host-tools.sha256, in both copies. Does not establish how a manifest made only of blank lines is handled, though that also fails the `grep -v` regex (paraphrased — no quote available because this is inferred from the regex, not executed).

```sh
# devcontainer-config/cc-isolated.sh:244
  if [ ! -r "$m" ] || [ ! -s "$m" ] || grep -qvE '^[0-9a-f]{64}  [A-Za-z0-9._-]+$' "$m"; then
```
Before this change an empty file passed, because `grep -qv` matches no line of an empty file, and each tool then fell through to "changed". With the fix, an empty manifest printed `host-tool manifest …/host-tools.sha256 is unreadable or malformed: inspect it before any bless overwrites it` and exited 1, both through cc-push (P2) and through the launcher (P3, "empty+missing-entry"). Mutant m5, with `[ ! -s "$m" ] ||` removed, fails the manifest test at `:1018` (the empty sub-case).

Provenance: probe.sh as Claim 1 (exit 0, 01:07:17Z). For m5: `env HOME=… TMPDIR=… CC_PUSH_CLONES_DIR=… CLAUDE_DEVC_CONFIG_DIR=… LC_ALL=C timeout 300 bats -f 'verify_host_tools: an unreadable, empty' test/cc-isolated-functions.bats`, cwd `<root>/m5`, exit 1, 2026-10-15T01:08:05Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:244`, `docs/reviews/execution-logs/fc-q089a-it3/03-probes.log`, `docs/reviews/execution-logs/fc-q089a-it3/06-mutant-m5.log`

---

## Claim 3: "a missing or duplicated entry is named ('has no single entry for X') rather than 'changed'." (f737ba71, A1)

**Location:** `devcontainer-config/cc-isolated.sh:257-266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers an absent entry and a duplicated entry for a checked file. Does not establish the treatment of extra entries for files nobody checks, which awk's per-name count ignores.

```sh
# devcontainer-config/cc-isolated.sh:257-266
    want="$(awk -v f="$f" '$2 == f { n++; h = $1 } END { if (n == 1) print h }' "$m")"
    if [ -z "$want" ]; then
      echo "host-tool manifest $m has no single entry for $f"
      bad=1
      continue
    fi
    have="$(sha256sum < "$dir/$f" | cut -d' ' -f1)"
    if [ "$want" != "$have" ]; then
```
(excerpt ends :266; enclosing verify_host_tools() continues to :270 — read)

P2 printed `has no single entry for cc-push.sh` when that line was removed, and `has no single entry for cc-gitdir.sh` when that line was duplicated. Neither run printed "changed". Mutant m6, with the block removed, fails the test at `:1022`.

Provenance: probe.sh (exit 0, 01:07:17Z). m6 runs the same bats command, cwd `<root>/m6`, exit 1, 01:08:07Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:257-270`, `docs/reviews/execution-logs/fc-q089a-it3/03-probes.log`, `docs/reviews/execution-logs/fc-q089a-it3/06-mutant-m6.log`

---

## Claim 4: "Every reason line in the refusal is indented under the ERROR line." (f737ba71, A1)

**Location:** `devcontainer-config/cc-isolated.sh:753`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the launcher's refusal block (`:751-767`) under `set -euo pipefail`, with one or several reasons. Does not establish the WARNING path at `:772-775` (it prints one cc-push reason unindented, and at most one line can arise there) or `--list` (it joins reasons with `; `).

```sh
# devcontainer-config/cc-isolated.sh:753
    while IFS= read -r line; do printf '  %s\n' "$line"; done <<< "$HOST_TOOLS_ERR" >&2
```
Edge cases:
- **Under set -e.** P4 ran the loop shape under `bash -euo pipefail`. The terminating `read` failure ends the loop with status 0 ("after loop rc=0").
- **Empty `HOST_TOOLS_ERR`.** The loop would print one bare `  ` line. The case cannot be reached: the block is guarded by `[ -n "$HOST_TOOLS_ERR" ]` (`:751`), and `:718` substitutes `host-tool check failed`.
- **Trailing newline.** It would add an indented empty line (P4, `$'one\ntwo\n'`). The case cannot be reached either, because `HOST_TOOLS_ERR` comes from `$(…)`, which strips trailing newlines (`:714`).

In P3, with three tools changed, every stderr line after `ERROR:` began with two spaces (`cat -A` output). Mutant m4 restores the old `printf '  %s\n' "$HOST_TOOLS_ERR"` and fails the indent assertion at `test/cc-isolated-functions.bats:989`; the unmutated tree passes.

Not a claim, recorded for the reader: `local line` is declared at `:756`, after the loop at `:753` has already assigned `line`. The loop's `line` is therefore the global one. P4 shows a global `line=""` surviving the function. That has no effect here, because the block exits 1.

Provenance: probe.sh (exit 0, 01:07:17Z). m4 and the control ran `… LC_ALL=C timeout 300 bats -f 'launch: a host-tool refusal still shows a boundary change' test/cc-isolated-functions.bats`, cwd `<root>/m4` (exit 1) and `<root>/src` (exit 0), at 01:08:22Z and 01:08:24Z.

**Evidence:** `devcontainer-config/cc-isolated.sh:713-719`, `devcontainer-config/cc-isolated.sh:751-776`, `docs/reviews/execution-logs/fc-q089a-it3/03-probes.log`, `docs/reviews/execution-logs/fc-q089a-it3/07-indent-test-m4.log`, `docs/reviews/execution-logs/fc-q089a-it3/07-indent-test-src.log`

---

## Claim 5: Test comment "Every reason line is indented under the ERROR line." with its assertion

**Location:** `test/cc-isolated-functions.bats:988-989`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the assertion's ability to catch the pre-fix single `printf`. Does not establish that it would catch an indent lost only on a third or later reason, since only two reasons are asserted.

```sh
# test/cc-isolated-functions.bats:989
  [[ "$output" == *$'\n  '*"cc-exit-scan.sh changed"*$'\n  '*"cc-gitdir.sh changed"* ]]
```
The assertion passes on f737ba71 and fails on m4 at `:989`, as recorded in Claim 4.

**Evidence:** `test/cc-isolated-functions.bats:966-1004`, `docs/reviews/execution-logs/fc-q089a-it3/07-indent-test-m4.log`

---

## Claim 6: "The manifest test covers unreadable (non-root), empty, malformed and missing-entry cases." (f737ba71, A1)

**Location:** `test/cc-isolated-functions.bats:1006-1030`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four named sub-cases and shows the empty, missing-entry and unreadable sub-cases are live (each fails under a mutant). Does not establish coverage of a duplicated entry (no sub-case), the malformed sub-case's mutation sensitivity (iteration 2 established it), or a run as root (the unreadable sub-case is skipped there).

```sh
# test/cc-isolated-functions.bats:1023-1029
  if [ "$(id -u)" -ne 0 ]; then
    cp "$TEST_TMPDIR/h.good" "$h"; chmod 000 "$h"
    run verify_host_tools "$CLAUDE_DEVC_CONFIG_DIR" cc-push.sh
    chmod 644 "$h"
    [ "$status" -eq 1 ]
    [[ "$output" == *"unreadable or malformed"* ]]
  fi
```
The probe ran as uid 1000, so the unreadable branch executed. Mutant m7 removes `[ ! -r "$m" ] ||` and fails at `:1028`, because the file then falls through to a different message. m5 and m6 fail at `:1018` and `:1022` (Claims 2 and 3).

Provenance: m7 ran the same bats command, cwd `<root>/m7`, exit 1, 01:09:37Z.

**Evidence:** `test/cc-isolated-functions.bats:1006-1030`, `docs/reviews/execution-logs/fc-q089a-it3/06-mutant-m5.log`, `docs/reviews/execution-logs/fc-q089a-it3/06-mutant-m6.log`, `docs/reviews/execution-logs/fc-q089a-it3/06-mutant-m7.log`

---

## Claim 7: "Tests under LC_ALL=C: cc-isolated-functions 182/182" (f737ba71)

**Location:** f737ba71 commit message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suite at f737ba71 in this sandbox with redirected dirs. Does not establish a run on a host with Docker.

The log shows `1..182`, 182 `ok` lines, no `not ok`, and `[exit=0]`.

Provenance: `env HOME=<root>/home TMPDIR=<root>/tmp CC_PUSH_CLONES_DIR=<root>/clones CLAUDE_DEVC_CONFIG_DIR=<root>/cfg LC_ALL=C timeout 900 bats test/cc-isolated-functions.bats`, cwd `<root>/src`, exit 0, 2026-10-15T01:03:15Z.

**Evidence:** `docs/reviews/execution-logs/fc-q089a-it3/01-cc-isolated-functions-bats.log`

---

## Claim 8: "A1 (fact-check it2, claim 4 Incorrect; 3b, 11, 13 Mostly accurate)" (f737ba71)

**Location:** f737ba71 commit message; `docs/reviews/code-fact-check-report-q089a1.md`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the verdicts the cited report records. Does not establish that the fixes resolve those findings; Claims 1-6 do that.

The it2 report header reads `**Commit:** b3b37e16` / `**Summary:** 12 verified, 4 mostly accurate, 0 stale, 1 incorrect`. Its non-Verified claims are exactly 3b, 11 and 13 (Mostly accurate) and 4 (Incorrect).

**Evidence:** `docs/reviews/code-fact-check-report-q089a1.md`

---

## Claim 9: "One commit for both units, on A2's branch, which contains A1 … The shared verify_host_tools block must change in both copies at once (parity test)." (f737ba71)

**Location:** f737ba71 commit message
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers ancestry and the parity test's coupling of the two blocks. Does not establish the separate landing claim, which is Claims 17a and 17b.

`git merge-base --is-ancestor b3b37e16 f737ba71` succeeds, so A1's last commit is in the branch. `git show --stat f737ba71` lists `cc-isolated.sh`, `cc-push.sh` and both bats files. The parity test is Claim 13.

**Evidence:** `test/cc-isolated-functions.bats:928-935`, `docs/reviews/execution-logs/fc-q089a-it3/03-probes.log`

---

# Unit A2: cc-push.sh, its tests and the parity test

## Claim 10: "when this installed copy or the cc-gitdir.sh beside it differs from what the bless recorded in host-tools.sha256 (or that file is missing, a symlink, unreadable or malformed), cc-push exits 1 before parsing anything, --help included"

**Location:** `devcontainer-config/cc-push.sh:35-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed manifest state plus an empty manifest or a missing or duplicated entry (all exit 1, even for `--help` or a bad flag). Does not establish the repo-checkout exemption (outside "installed copy"; it2 checked it), or that the prologue above the check (`:121-144`, `safe_path`) is unguarded, which `:40` itself says.

```sh
# devcontainer-config/cc-push.sh:203-212
CC_PUSH_DIR="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
if ! host_tools_err="$(verify_host_tools "$CC_PUSH_DIR" cc-push.sh cc-gitdir.sh)"; then
  {
    echo "ERROR: cc-push refuses to run:"
    while IFS= read -r line; do printf '  %s\n' "$line"; done <<< "$host_tools_err"
    echo "Review the host tools in $CC_PUSH_DIR, then re-bless (it prints what changed):"
    printf '    CLAUDE_DEVC_CONFIG_DIR=%q cc-isolated --bless\n' "$CC_PUSH_DIR"
  } >&2
  exit 1
fi
```
- **Manifest states (P2).** `--help` exits 1 for the empty, missing-entry, duplicated-entry, unreadable, missing and symlink states.
- **Bad flag (Q1).** On a refusing copy, `--no-such-flag` exits 1. On a clean copy it prints `ERROR: unknown flag` and exits 2. The check therefore precedes argument parsing.

Provenance: probe.sh (exit 0, 01:07:17Z). `timeout 600 bash docs/reviews/execution-logs/fc-q089a-it3/probe2.sh <root>`, cwd `<root>`, 2026-10-15T01:09:24Z; it ran to its closing timestamp, and the wrapper's `[probe exit=]` is blank because of how PIPESTATUS was captured.

**Evidence:** `devcontainer-config/cc-push.sh:35-43`, `devcontainer-config/cc-push.sh:121-214`, `docs/reviews/execution-logs/fc-q089a-it3/03-probes.log`, `docs/reviews/execution-logs/fc-q089a-it3/08-probe2-header.log`

---

## Claim 11: "It cannot guard the lines above the check, nor an overwrite that drops it: a tampered copy that skips its own check is caught only by cc-isolated's warning at the next launch of the copy installed beside it, and by `cc-isolated --list` for the config dir."

**Location:** `devcontainer-config/cc-push.sh:39-43`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the following:
- a dropped-check copy runs unrefused;
- only the launcher in the same dir warns, and a launcher elsewhere does not, even when `CLAUDE_DEVC_CONFIG_DIR` names the tampered dir;
- `--list` reports the tampered copy for the config dir.

Does not establish that `--list`'s label for that copy is accurate. It says `cc-push refuses:`, but a dropped-check copy does not refuse. That label is committed A1 context (`cc-isolated.sh:515`), outside this diff.

```sh
# devcontainer-config/cc-isolated.sh:773-775
  if [ "$action" != "bless" ] && [ "$action" != "list" ] \
     && ! push_err="$(verify_host_tools "$CC_ISOLATED_DIR" cc-push.sh)"; then
    echo "WARNING: $push_err — do not run cc-push until you have reviewed it and re-blessed." >&2
```
In Q2 the dropped-check copy in `instD` ran `--help` unrefused. The launcher in `instD` printed `WARNING: …/instD/cc-push.sh changed since the last bless — do not run cc-push…`. The launcher in `instE`, run with `CLAUDE_DEVC_CONFIG_DIR=instD`, printed no such warning. `instE --list`, with the config dir set to `instD`, printed `Host tools — CHANGED` and `cc-push refuses: …/instD/cc-push.sh changed since the last bless`. In P5 the dropped-check mutant ran a below-check tamper (`tamper-ran=yes`).

Provenance: probe2.sh (Claim 10, 01:09:24Z) and probe.sh P5 (01:07:17Z).

**Evidence:** `devcontainer-config/cc-isolated.sh:498-516`, `devcontainer-config/cc-isolated.sh:770-776`, `docs/reviews/execution-logs/fc-q089a-it3/08-probe2-header.log`, `docs/reviews/execution-logs/fc-q089a-it3/03-probes.log`

---

## Claim 12: "The same per-line indent in cc-push's refusal." (f737ba71, A2)

**Location:** `devcontainer-config/cc-push.sh:207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one or two reason lines at top level under `set -euo pipefail`. Does not establish test coverage, because no cc-push.bats assertion checks the indent (cc-isolated's `:989` covers only the launcher). It also does not establish the empty case: an empty `host_tools_err` would print one bare `  ` line, since there is no fallback like cc-isolated's `:718`. That case appears unreachable, because every `return 1` path in `verify_host_tools` echoes first (paraphrased — no quote available because this is inferred from reading all five return paths at `:163-197`).

The code is quoted in Claim 10 (`:207`). In P3, with cc-push.sh and cc-gitdir.sh both changed, `cat -A` shows `ERROR: cc-push refuses to run:$` followed by two lines that each start with two spaces.

**Evidence:** `devcontainer-config/cc-push.sh:156-212`, `docs/reviews/execution-logs/fc-q089a-it3/03-probes.log`

---

## Claim 13: "verify_host_tools: KEEP IN STEP with the copy in cc-isolated.sh (a test compares the two byte for byte)"

**Location:** `devcontainer-config/cc-push.sh:146-147`; `test/cc-isolated-functions.bats:928-935`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte identity at f737ba71 of everything after each block's first marker line, and the test enforcing it. Does not establish identity of the first marker line itself (`tail -n +2` drops it by design, since the two name each other; it2's known C4).

```sh
# test/cc-isolated-functions.bats:930-934
  a="$(sed -n '/^# --- verify_host_tools/,/^# --- end verify_host_tools/p' "$CONFIG_SRC/cc-isolated.sh" | tail -n +2)"
  b="$(sed -n '/^# --- verify_host_tools/,/^# --- end verify_host_tools/p' "$CONFIG_SRC/cc-push.sh" | tail -n +2)"
  [ -n "$a" ]
  [[ "$a" == *"verify_host_tools() {"* ]]
  [ "$a" = "$b" ]
```
P1 printed `IDENTICAL (52 lines after the marker)`. The test passes in the 182/182 run.

**Evidence:** `devcontainer-config/cc-isolated.sh:219-271`, `devcontainer-config/cc-push.sh:146-198`, `docs/reviews/execution-logs/fc-q089a-it3/03-probes.log`, `docs/reviews/execution-logs/fc-q089a-it3/01-cc-isolated-functions-bats.log`

---

## Claim 14: "The self-tamper test puts its touch directly below the check, the first line it guards; at the end of the file the main guard exited first and the assertion could not fail." (f737ba71, and test comment `test/cc-push.bats:811-812`)

**Location:** `test/cc-push.bats:811-820`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the placement, the old placement's inability to fail, and the new test failing when the check is removed or when it skips cc-push.sh, including with the status and output assertions deleted. Does not establish that the touch assertion is the first to fail in the unmodified test; the status assertion at `:817` fails first, so the touch assertion is a second line of defence.

```sh
# test/cc-push.bats:813-820
  awk -v t="touch $M/push-tamper-ran" '/^# shellcheck source=cc-gitdir.sh$/ { print t } { print }' \
    "$BATS_TEST_DIRNAME/../devcontainer-config/cc-push.sh" > "$d/cc-push.sh"
  grep -qx "touch $M/push-tamper-ran" "$d/cc-push.sh"
  run bash "$d/cc-push.sh" --help
  [ "$status" -eq 1 ]
  [[ "$output" == *"cc-push.sh changed since the last bless"* ]]
  [[ "$output" == *"CLAUDE_DEVC_CONFIG_DIR=$d cc-isolated --bless"* ]]
  [ ! -e "$M/push-tamper-ran" ]
```
(excerpt ends :820; enclosing @test continues to :828 — read)

`# shellcheck source=cc-gitdir.sh` is `cc-push.sh:213`, directly after the check's `fi` at `:212`, so the touch is the first guarded line.

P5 ran a 2×2 grid, recorded as variant / placement → exit code, tamper ran:

| Variant | Touch placement | Exit code | Tamper ran |
|---|---|---|---|
| orig | below the check | 1 | no |
| orig | end of file | 1 | no |
| check removed | below the check | 0 | yes |
| check removed | end of file | 0 | no |

The last row is the claim: when the touch sits at the end of the file, `exit "$rc"` (`cc-push.sh:598`) ends the run first, so the touch never runs even with the check removed.

Mutation results on the test:
- **m1** (check removed) fails at `:806`.
- **m2** (check drops `cc-push.sh` from its list) fails at `:817`.
- **m3** (m2 source, with `:817-819` deleted from the test) fails at the touch assertion itself, `[ ! -e "$M/push-tamper-ran" ]`.

Provenance: probe.sh P5 (01:07:17Z). m1, m2 and m3 ran `… LC_ALL=C timeout 300 bats -f 'installed copy: cc-push checks itself' test/cc-push.bats`, cwd `<root>/m1`, `<root>/m2` and `<root>/m3`, all exit 1, at 01:07:32Z, 01:07:33Z and 01:07:43Z.

**Evidence:** `test/cc-push.bats:797-828`, `devcontainer-config/cc-push.sh:203-214`, `devcontainer-config/cc-push.sh:589-600`, `docs/reviews/execution-logs/fc-q089a-it3/03-probes.log`, `docs/reviews/execution-logs/fc-q089a-it3/04-mutant-m1.log`, `docs/reviews/execution-logs/fc-q089a-it3/04-mutant-m2.log`, `docs/reviews/execution-logs/fc-q089a-it3/05-mutant-m3-touch-only.log`

---

## Claim 15: "Tests under LC_ALL=C: … cc-push 48/48." (f737ba71)

**Location:** f737ba71 commit message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the suite at f737ba71 in this sandbox. Does not establish a run against real docker or a real remote.

The log shows `1..48`, 48 `ok` lines, no `not ok`, and `[exit=0]`.

Provenance: `env HOME=… TMPDIR=… CC_PUSH_CLONES_DIR=… CLAUDE_DEVC_CONFIG_DIR=… LC_ALL=C timeout 900 bats test/cc-push.bats`, cwd `<root>/src`, exit 0, 2026-10-15T01:06:16Z.

**Evidence:** `docs/reviews/execution-logs/fc-q089a-it3/02-cc-push-bats.log`

---

## Claim 16: "A2 (fact-check it2, claims 10/12 Incorrect; 1, 4, 8 Mostly accurate)" (f737ba71)

**Location:** f737ba71 commit message; `docs/reviews/code-fact-check-report-q089a2.md`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited verdicts. Does not establish that the list is complete: claims 5, 6 and 7 were also Mostly accurate and are not listed.

The it2 report (`**Commit:** cc2640b7`) records claims 10 and 12 as Incorrect and claims 1, 4, 5, 6, 7 and 8 as Mostly accurate (paraphrased — no quote available because the verdicts are spread across 15 claim sections; extracted with `awk '/^## Claim/{c=$3} /^\*\*Verdict/{print c, $0}'`).

**Evidence:** `docs/reviews/code-fact-check-report-q089a2.md`

---

# Joint (f737ba71 Notes)

## Claim 17a: "decision to land A1 and A2 as one merge … is recorded in both rubrics" — the A1 rubric

**Location:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089a1-host-tool-manifest.md:9`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the A1 rubric's landing statement. Does not establish the "(their review loops stay separate)" half, which neither rubric states.

```
# docs/reviews/code-review-rubric-2026-10-14-feat-q089a1-host-tool-manifest.md:9
**Merge constraint (security F1, architecture F3):** A1 lands only together with A2, its stacked unit, and B. … Merge A2's branch, which contains A1, then B, in one landing.
```

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089a1-host-tool-manifest.md:9`

---

## Claim 17b: same Note — the A2 rubric

**Location:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089a2-cc-push-self-check.md:5,36`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the A2 rubric as committed at f737ba71, last changed in 2cb03f23, with no uncommitted edits in this worktree. Does not establish whether the orchestrator updates it after this commit.

The A2 rubric records no one-merge decision. Its only stacking and landing text is:

```
# docs/reviews/code-review-rubric-2026-10-14-feat-q089a2-cc-push-self-check.md:5
**Scope:** feat/q089a2-cc-push-self-check (`f2533b33..840f39b0`, 1 commit, 93 lines; stacked on A1) | …
# …:36
| C4 | … | 🟢 Won't-Fix (by design; the stack lands in order) |
```
"The stack lands in order" is not the same as "land as one merge". A reader who goes to the A2 rubric for the decision will not find it. Medium confidence because the rubric may be meant to be updated at this iteration's close.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-14-feat-q089a2-cc-push-self-check.md:5`, `docs/reviews/code-review-rubric-2026-10-14-feat-q089a2-cc-push-self-check.md:36`

---

## Claims Requiring Attention

### Incorrect
- **Claim 17b** (`docs/reviews/code-review-rubric-2026-10-14-feat-q089a2-cc-push-self-check.md:5`): f737ba71's Notes say the one-merge decision is "recorded in both rubrics", but the A2 rubric says only "stacked on A1" and "the stack lands in order". Add the landing constraint to the A2 rubric, or narrow the note to the A1 rubric.

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- None.

---

## Goal-Alignment Note

The goal is a security-sensitive trust-manifest change that is safe to merge. Every behavioral claim f737ba71 makes was executed and holds:
- the bare bless hint is gone;
- empty and missing or duplicated-entry manifests are named;
- reasons are indented in both refusals;
- the two copies are byte-identical;
- the suites pass 182/182 and 48/48 under LC_ALL=C.

The it2 blocker is fixed. The self-tamper test can now fail: with the check removed, a below-check tamper runs, and the test catches it even with its status assertions deleted (m3).

The only Incorrect is documentation bookkeeping in the commit Notes (Claim 17b), not code.

Three non-claim residues are worth a reviewer's eye, and none blocks the merge:
1. **`--list` label.** For a copy that dropped its check, `--list` prints `cc-push refuses:` when that copy in fact does not refuse (Claim 11 scope; committed A1 context, `cc-isolated.sh:515`).
2. **Indent test coverage.** cc-push's indent has no test; only the launcher's does (`:989`).
3. **`local line` placement.** In cc-isolated's `main`, `local line` is declared after the loop that assigns `line`, so `line` is global there. This is harmless, because the block exits 1.
