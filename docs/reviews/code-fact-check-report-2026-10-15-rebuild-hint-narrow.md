# Code Fact-Check Report

**Repository:** claude-workflows (worktree /workspace/.claude/wt-rebuild-hint, branch fix/rebuild-hint-recreate)
**Scope:** `git diff 2463017f..756c11f9` excluding the code-fact-check, security-review and api-consistency-review artifacts (one `--help` comment line in `devcontainer-config/cc-isolated.sh`, test comments and assertions in `test/cc-isolated-functions.bats` and `test/init-firewall-rules.bats`, two override-log rows), plus the body of commit 756c11f9
**Checked:** 2026-10-15
**Commit:** 756c11f9
**Replication:** k=1 (narrow check after the final pass)
**Total claims checked:** 20
**Summary:** 19 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Execution: the suites ran on a `git archive 756c11f9` copy at `/home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-narrow/head/` (cwd for every run unless noted), via `bash scripts/run-tests.sh <file>`. `test/cc-isolated-functions.bats` passed 195/195 and `test/init-firewall-rules.bats` passed 95/95, both exit 0, at 2026-10-15T12:04:24Z. Logs: `fc-narrow/logs/cc-head.log`, `fc-narrow/logs/fw-head.log`. For the regression checks, copies of that tree had the older `cc-isolated.sh` swapped in (`fc-narrow/v-980a9db4/`, `fc-narrow/v-cb56299c/`). Hallucination-pattern log read: 8 entries, none related to these claims.

---

## Claim 1: `--help`: "--probe-only [WS] ... record it verified live on a pass"

**Location:** `devcontainer-config/cc-isolated.sh:13-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers when the receipt is written on the `--probe-only` path. Does not cover the wording of the other `--help` lines.

`probe_boundary` returns before writing the receipt when any check fails:

```bash
# devcontainer-config/cc-isolated.sh:708-712
  if [ "$failures" -gt 0 ]; then
    echo "Boundary self-probe FAILED ($failures) — not starting Claude Code." >&2
    return 1
  fi
  record_verified_live
```
(excerpt ends :712; enclosing probe_boundary() continues to :715 with two echoes — read)

The probe branch of main is `devcontainer up --remove-existing-container "${dc[@]}"; probe_boundary "$ws"; exit 0` (`cc-isolated.sh:891-897`). The new wording matches `guides/cc-isolated-usage.md:25-26` ("record the config verified live on a pass").

**Evidence:** `devcontainer-config/cc-isolated.sh:13-15`, `:105-117`, `:708-715`, `:891-897`, `guides/cc-isolated-usage.md:25-26`

---

## Claim 2: rebuild_hint test comment: "the last positional becomes the workspace, so step 2 fails or, if that word names a directory inside a git work tree, launches that tree's repo"

**Location:** `test/cc-isolated-functions.bats:355-359`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers argument parsing (the last positional wins) and how resolve_workspace handles the stray word. Does not cover the later launch-time refusals (launch_gitdir_ok, check_manifest) that could still stop that launch.

Main keeps the last positional: `*)            ws_arg="$1"; shift ;;` (`cc-isolated.sh:759`). resolve_workspace errors on a non-directory, errors on a directory outside git, and otherwise prints `git -C "$start" rev-parse --show-toplevel` (`cc-isolated.sh:357-370`). I sourced the script at 756c11f9 and called it:

- `launches`, a plain subdirectory of a git repo: printed the repo's top level, rc=0.
- `launches` in a non-git directory: `ERROR: launches is not inside a git repository.`

Command: `timeout 60 bash -c 'source .../head/devcontainer-config/cc-isolated.sh; resolve_workspace launches; ...'`. cwd `fc-narrow/rw/repo`. Timestamp 2026-10-15T12:11:18Z. Exit: rc=0 on the first call, then rc=1 under the script's `set -e` on the second.

**Evidence:** `devcontainer-config/cc-isolated.sh:357-370`, `:742-761`, log `/home/node/.claude/jobs/00bcf178/tmp/rebuild-hint/fc-narrow/logs/resolve.log`

---

## Claim 3: bless test: the `Next:` command is alone on its line (new `grep -qx` assertion and comment)

**Location:** `test/cc-isolated-functions.bats:1259-1261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers that the assertion passes on 756c11f9 and fails on the older trailing-comment lines. Does not cover the bless output's other lines.

At HEAD, bless_manifest prints `echo "  Next: cc-isolated --probe-only <repo>"` (`cc-isolated.sh:318`), and the test passes (cc-head.log, `ok 93`). With older scripts swapped in, the full-suite runs fail at exactly this line:

- 980a9db4's script (`:317` `"  Next: cc-isolated --probe-only <repo>   # recreates from it and probes as node"`) gives `not ok 93 ... (line 1261) printf '%s\n' "$output" | grep -qx '  Next: cc-isolated --probe-only <repo>' failed`. It is the only failure in that file.
- cb56299c's script fails at the same line.

Both runs used cwd `fc-narrow/v-<sha>/` and exit 1. Timestamps: 2026-10-15T12:07:18Z (980a9db4) and 12:08:30Z (cb56299c). The earlier `*"--probe-only"*` assertion (`:1258`) passes on both old texts, so the new line is the one that guards against them.

**Evidence:** `devcontainer-config/cc-isolated.sh:315-320`, `test/cc-isolated-functions.bats:1254-1265`, logs `fc-narrow/logs/cc-980a9db4.log`, `fc-narrow/logs/cc-cb56299c.log`, `fc-narrow/logs/cc-head.log`

---

## Claim 4: fail-closed launch test: new assertion that the NOTE says "the container is recreated if it was built"

**Location:** `test/cc-isolated-functions.bats:1412`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers that the assertion passes on 756c11f9 and fails on cb56299c's NOTE when tested on its own. It passes on 980a9db4 by design, because that commit introduced the wording.

The HEAD NOTE is `"      This run is that verification: the container is recreated if it was built"` (`cc-isolated.sh:884`). With cb56299c's script, the existing `!=` assertion fails first (`:1411`). To test the new line on its own, I removed `:1411` from a copy of the test file and ran it against cb56299c's script (cwd `fc-narrow/v-cb56299c/`, 2026-10-15T12:09:57Z, exit 1). Result: `not ok 102 ... (line 1411) [[ "$output" == *"the container is recreated if it was built"* ]] failed` (the line number shifted after the deletion). Before 756c11f9, the test asserted only that the old wording was absent (`git show 980a9db4:test/cc-isolated-functions.bats` :1407 is the `!=` line alone).

**Evidence:** `devcontainer-config/cc-isolated.sh:882-887`, `test/cc-isolated-functions.bats:1392-1416`, logs `fc-narrow/logs/note-isolated-cb56299c.log`, `fc-narrow/logs/cc-head.log`

---

## Claim 5: --probe-only fail-case test comment: "must exit non-zero and write no receipt ... (--probe-only never runs claude at all, so that is not asserted here.)"

**Location:** `test/cc-isolated-functions.bats:1431-1433`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the comment against the test body and main's probe branch. Does not cover real Docker behaviour.

The test asserts `[ "$status" -ne 0 ]`, the PROBE FAIL line, the forced recreate, and `[ ! -f "$(verified_path)" ]` (`:1443-1446`). It does not assert anything about claude. The probe branch exits before the claude exec: `probe_boundary "$ws"` then `exit 0` (`cc-isolated.sh:895-896`), and the only `devcontainer exec "${dc[@]}" claude` is on the launch path (`:938`). The test passed at HEAD (cc-head.log, `ok 104`).

**Evidence:** `test/cc-isolated-functions.bats:1431-1447`, `devcontainer-config/cc-isolated.sh:891-897`, `:938`

---

## Claim 6: init-firewall test comment: "--probe-only recreates the container, the word the guides use"

**Location:** `test/init-firewall-rules.bats:1491-1492`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the comment's wording against main's probe branch and the guides. The unverified "cached image layers" clause has been removed, so nothing is left that would need a Docker host.

The probe branch runs `devcontainer up --remove-existing-container "${dc[@]}"` (`cc-isolated.sh:894`). The guide's command reference says `# RECREATE REPO's container from the blessed config` (`guides/cc-isolated-usage.md:25`), and `:841` says "it always recreates". The assertion that follows matches `init-firewall.sh:352` (`"The first command recreates it from the blessed config and re-probes;"`).

**Evidence:** `test/init-firewall-rules.bats:1483-1501`, `devcontainer-config/cc-isolated.sh:891-897`, `devcontainer-config/init-firewall.sh:346-355`, `guides/cc-isolated-usage.md:25`, `:841`

---

## Claim 7: C4 override row: the hint's --probe-only step "just repeats a recreate that already ran ... on a plain launch, which has already recreated on the hash mismatch (`cc-isolated.sh:665-693`, `:904-907`)"

**Location:** `docs/reviews/override-log.md:847`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the cited line ranges, the config-identity case and the usual provenance case. Does not cover a wrong build that bakes the blessed hash, where no recreate ran before the hint.

The line ranges are right. `:665` is `local want_profile=...`, and `:665-693` spans the provenance block and the config-identity block, ending at the identity `fi`. `:904-907` is:

```bash
# devcontainer-config/cc-isolated.sh:904-907
  if ! container_config_matches "${dc[@]}"; then
    echo "Blessed config changed since this container was built — rebuilding it."
    devcontainer up --remove-existing-container "${dc[@]}"
  fi
```

Config identity: the probe fails on `[ "$have_hash" != "$want_hash" ]` (`:687`), and `container_config_matches` tests the same condition (`:580-584`). So on a plain launch, an identity failure always comes after the `:904` recreate. That part is exact.

Provenance: the recreate at `:904` happened only if the image's baked hash differed. paraphrased — no quote available because this follows from two files read together: devcontainer.json passes `"CC_CONFIG_HASH": "${localEnv:CC_CONFIG_HASH}"` as a build arg (`devcontainer.json:54`) to whichever Dockerfile gets built. A shadowing Dockerfile that declares that ARG and writes `/etc/cc-config-hash` therefore passes `:904` and is never recreated, yet still fails provenance (`:669-679`). In that case the hint's `--probe-only` runs a recreate that had *not* already run. It rebuilds the same wrong image, so the row's conclusion still holds: the retry is safe and futile. The mechanism "has already recreated on the hash mismatch" just does not cover that case. A profile mismatch alone cannot trigger it: per-project `.profile` files are hashed into the manifest (`cc-isolated.sh:126-129`, `:146`).

**Evidence:** `docs/reviews/override-log.md:847`, `devcontainer-config/cc-isolated.sh:580-584`, `:663-693`, `:900-907`, `:126-146`, `devcontainer-config/devcontainer.json:52-54`, `devcontainer-config/Dockerfile:484`, `:526`

---

## Claim 8: Accepted-immutable row: 980a9db4's Notes say C4 "is deferred with a revisit trigger in the rubric and override log"; at that commit the rubric showed C4 open and the log had no row; both records were added in 2463017f

**Location:** `docs/reviews/override-log.md:849`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the rubric and override log at 980a9db4 and 2463017f.

980a9db4's body contains "C4 ... is deferred with a revisit trigger in the rubric and override log". At 980a9db4, the rubric's C4 row ends `| 🟢 Open |` (rubric :34), and `override-log.md` has 0 lines matching `rebuild-hint-recreate`. At 2463017f, the C4 row reads `Deferred: revisit trigger "..."; logged in override-log.md` (:37), and the log has 2 such rows.

**Evidence:** `git show 980a9db4:docs/reviews/code-review-rubric-2026-10-15-fix-rebuild-hint-recreate.md` :34, `git show 2463017f:...` :37, `git show {980a9db4,2463017f}:docs/reviews/override-log.md`

---

## Claim 9: body: "the bless "Next:" line was the one fixed copyable line no test pinned; ... now requires it to be the command alone (grep -x)"

**Location:** commit 756c11f9 body, first bullet
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the copyable lines this unit fixed: rebuild_hint, init-firewall's two lines, and the bless Next line. install.sh is deferred and not counted.

`git grep "Next: cc-isolated" 2463017f -- test/` finds nothing. At 756c11f9 it finds `test/cc-isolated-functions.bats:1261` (the `grep -qx`). rebuild_hint's line 1 is pinned at `:360`, and init-firewall's two lines are pinned by `grep -qx` at `init-firewall-rules.bats:1498-1499`.

**Evidence:** `test/cc-isolated-functions.bats:360`, `:1261`, `test/init-firewall-rules.bats:1498-1499`

---

## Claim 10: body, correcting 980a9db4's A2: "that test only checked that the old NOTE wording was absent. It now also requires the new wording."

**Location:** commit 756c11f9 body, second bullet
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Same evidence as Claim 4.

At 980a9db4 the test held only `[[ "$output" != *"the container is rebuilt from it"* ]]` (:1407). The positive assertion was added at `:1412`, and it fails on the earlier NOTE (Claim 4).

**Evidence:** `git show 980a9db4:test/cc-isolated-functions.bats` :1407, `test/cc-isolated-functions.bats:1412`, log `fc-narrow/logs/note-isolated-cb56299c.log`

---

## Claim 11: body claim 5 and its correction of 2463017f's A5: "its 'otherwise step 2 errors out' is false when ./launches is a plain directory inside a git work tree"

**Location:** commit 756c11f9 body, third bullet
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Same execution as Claim 2.

2463017f's body says the retarget happens "only when ./launches is a git repo; otherwise step 2 errors out". resolve_workspace on a plain `launches` directory inside a git repo printed that repo's top level, rc=0 (Claim 2), so the correction holds.

**Evidence:** `devcontainer-config/cc-isolated.sh:357-370`, log `fc-narrow/logs/resolve.log`

---

## Claim 12: body claim 7: the fail-case test comment "no longer promises a 'never start claude' check (the assertion was removed in 2463017f)"

**Location:** commit 756c11f9 body, fourth bullet
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the comment diff and 2463017f's body.

The diff replaces "exit non-zero and never start claude" with "exit non-zero and write no receipt" plus the parenthetical (`:1431-1433`). 2463017f's body says the test "drops its 'no claude' assertion".

**Evidence:** `test/cc-isolated-functions.bats:1431-1433`, `git log -1 --format=%B 2463017f`

---

## Claim 13: body claim 11: "--help's --probe-only line says 'verified live on a pass', like the guide"

**Location:** commit 756c11f9 body, fifth bullet
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Same evidence as Claim 1.

**Evidence:** `devcontainer-config/cc-isolated.sh:15`, `guides/cc-isolated-usage.md:26`

---

## Claim 14: body claim 12: "dropped the unverified '(cached image layers are reused)' from an init-firewall test comment"

**Location:** commit 756c11f9 body, sixth bullet
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the diff hunk in `test/init-firewall-rules.bats`.

The `-` line `# --probe-only recreates the container (cached image layers are reused), the` is replaced by `# --probe-only recreates the container, the word the guides use (override`.

**Evidence:** `test/init-firewall-rules.bats:1491-1492`

---

## Claim 15: body claims 3-4: "the C4 override row now covers the plain-launch case ... and cites :665-693"

**Location:** commit 756c11f9 body, seventh bullet
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the row now says. Whether the row is accurate is Claim 7.

The row at `override-log.md:847` names "on a plain launch, which has already recreated on the hash mismatch" and cites `devcontainer-config/cc-isolated.sh:665-693`, `:904-907`. The old row cited `:670-689`.

**Evidence:** `docs/reviews/override-log.md:847`

---

## Claim 16: body claim 1: 980a9db4's Notes said C4 was already deferred; "both records were added in 2463017f. Logged as an Accepted-immutable override row."

**Location:** commit 756c11f9 body, eighth bullet
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Same evidence as Claim 8.

**Evidence:** `docs/reviews/override-log.md:849`

---

## Claim 17: body claim 9, correcting 980a9db4's Notes: "the 'rebuilding it.' line is pinned by the guide row only; the test pattern stops before 'rebuilding'"

**Location:** commit 756c11f9 body, eighth bullet
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers every grep hit for the line in `test/` and `guides/`. Does not establish that the guide row is checked by a test.

The test reads `[[ "$output" == *"Blessed config changed since this container was built"* ]]` (`test/cc-isolated-functions.bats:1363`), which stops before "rebuilding". The guide row quotes `` `Blessed config changed since this container was built — rebuilding` `` (`guides/cc-isolated-usage.md:956`). No other test or guide hit exists.

**Evidence:** `test/cc-isolated-functions.bats:1363`, `guides/cc-isolated-usage.md:956`

---

## Claim 18: Notes: "no non-comment line of either enforcement script changed"; trailer: "only a comment line of cc-isolated.sh changed here"

**Location:** commit 756c11f9 body, Notes and Live-verified trailer
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the full diff 2463017f..756c11f9. The trailer's "the gate's comment-only escape may apply" is hedged and not verdicted; the escape exists at `hooks/live-verify-gate.sh:97`.

`git diff --stat 2463017f..756c11f9` lists `devcontainer-config/cc-isolated.sh | 2 +-` (the `:15` header comment) and no change to `init-firewall.sh`.

**Evidence:** `devcontainer-config/cc-isolated.sh:15`, `hooks/live-verify-gate.sh:97`

---

## Claim 19: Won't-Fix: "init-firewall prints the recipe as two lines rather than an `&&` line (security final #1; safe, the plain launch re-probes)"

**Location:** commit 756c11f9 body, Notes
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the printed lines and that every plain launch probes before claude. Does not cover a launch that had no failed probe before it.

init-firewall prints `"         cc-isolated --probe-only <repo>"` and `"         cc-isolated <repo>"` on separate lines (`init-firewall.sh:354-355`). On the launch path, `probe_boundary` must pass before claude runs: on failure it re-runs the firewall script, and on that script's failure it returns 1 (`cc-isolated.sh:912-929`, claude at `:938`). Security final #1 is that finding (`security-review-2026-10-15-rebuild-hint-final.md:37`).

**Evidence:** `devcontainer-config/init-firewall.sh:350-355`, `devcontainer-config/cc-isolated.sh:912-938`

---

## Claim 20: Won't-Fix: "a 66-column line in the --help paragraph (api final #3, cosmetic)"

**Location:** commit 756c11f9 body, Notes
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the width of the line as `--help` prints it.

`cc-isolated.sh:64` (`# always recreates), and refuses to start a session unless the baked`) is 68 characters in the source. usage strips `# ?` (`sub(/^# ?/, "")`, `:736`), so `--help` prints it at 66 columns. Its neighbours run 81-85 columns in the source. This matches api final #3 (`api-consistency-review-2026-10-15-rebuild-hint-final.md:64`, `:77`).

**Evidence:** `devcontainer-config/cc-isolated.sh:60-66`, `:735-737`

---

## Claims Requiring Attention

### Mostly Accurate
- **Claim 7** (`docs/reviews/override-log.md:847`): the plain-launch case is right for config identity and for any wrong build whose baked hash differs. A shadowing Dockerfile that bakes the `CC_CONFIG_HASH` build arg (`devcontainer.json:54`) passes `:904` without a recreate, so "already recreated" does not cover it. The conclusion (the retry is safe and futile) still holds. Optional fix: "...which has already recreated if the wrong build's baked hash differs".

## Goal-Alignment Note
- Success criterion (verbatim): "a code-fact-check report at that path verdicting the changes above."
- Answered: yes. Every changed test comment and assertion, the `--help` line, both override-log rows and every factual statement in 756c11f9's body are verdicted. The new assertions were run against 980a9db4's and cb56299c's scripts and fail there.
- Out of scope: real Docker behaviour; the guide rows; earlier commits beyond the corrections that 756c11f9's body makes.
- Escalate: Claim 7 → orchestrator, to tighten the record if wanted. It is low-stakes because the row's conclusion holds.
