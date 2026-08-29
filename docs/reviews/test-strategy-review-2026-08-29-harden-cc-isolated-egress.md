# Test Strategy: `harden/cc-isolated-egress` — init-firewall.sh egress hardening

**Scope:** `devcontainer-config/init-firewall.sh` (branch `harden/cc-isolated-egress`, commits `c44c33a` + `6edaa21` + uncommitted worktree changes), against `test/cc-isolated-functions.bats`
**Reviewed:** 2026-08-29
**Verdict:** the branch changes a security boundary and adds zero tests; every changed line is unreachable from the current suite.

## Test Conventions

- **Framework:** bats. One suite per subject under `test/*.bats`; helper libs in `test/lib/`.
- **Category tag is mandatory:** `scripts/run-tests.sh` reads `# @category fast|slow` from the first matching line and *skips the file with a warning* if absent. A new suite without it silently never runs.
- **Hermeticity (`guides/test-hermeticity.md`, decision 017):** any suite that can spawn `curl`/`dig`/`claude`/`gh` must PATH-shim a file *named after the binary* and point `PATH` at its directory — both halves, or `scripts/hermeticity-lint` flags it. The established shape is `test/round-log-functions.bats:24-27` and `test/cc-isolated-functions.bats:33-36`.
- **Locale pinning:** bats folds stderr into `$output`; an ungenerated `LC_ALL` makes every bash subprocess emit `setlocale` warnings into the value under assertion. I reproduced this in the prototype below. Any suite asserting on exact output must `load test/lib/hermetic-env.bash` and call `pin_hermetic_locale`.
- **Existing style:** `run <cmd>` then `[ "$status" -eq N ]` plus `[[ "$output" == *"substring"* ]]`. Temp dirs via `mktemp -d` in `setup()` with `rm -rf` in `teardown()`, or `$BATS_TEST_TMPDIR`.
- **Existing coverage of this file:** `test/cc-isolated-functions.bats:264-348` — nine tests, all through the `--print-domains` hook, which `exit 0`s at line 58 before a single firewall statement runs. Lines 60–329 of `init-firewall.sh` have no test coverage of any kind. A second class of test in that suite asserts on the *source text* via `grep` (lines 360-490) — useful precedent for pinning "this line must not come back," but it is not behavioural.

## Untested Paths Touched by the Change

Line numbers are against the post-change working-tree file.

- **G1** — `devcontainer-config/init-firewall.sh:163-164` — the `|| true` on `dns_resolvers="$(awk … | grep -E … | sort -u || true)"`: when `grep` matches zero resolvers it exits 1 and, without the guard, `set -e` aborts the script *after the flush and before the DROP policies*. This is the shipped bug caught in review — not covered.
- **G2** — `init-firewall.sh:162,164` — the octet alternation rejects out-of-range octets: `999.999.999.999` / `256.1.1.1` / `1.2.3.4.5` must not reach `iptables -d`, because iptables would treat them as hostnames, fail to resolve, and abort in the same wide-open window — not covered.
- **G3** — `init-firewall.sh:163` — the awk extractor takes field 2 of `^[[:space:]]*nameserver` lines only, and must ignore `search`/`options`/`domain` lines and commented-out `#nameserver` entries — not covered.
- **G4** — `init-firewall.sh:165-173` — the populated branch: exactly one UDP + one TCP accept per *unique* resolver (`sort -u` dedup), for a resolv.conf with two or more nameservers — not covered.
- **G5** — `init-firewall.sh:171-172` — `|| echo "WARNING: could not add …"` on each add: a failing `iptables -A` must warn and continue, not abort in the pre-DROP window — not covered.
- **G6** — `init-firewall.sh:174-199` — the `else` branch installs **zero** iptables rules. This block has regressed twice in opposite directions (blanket `0.0.0.0/0` accept → inert `127.0.0.11` accept → nothing). Both the "no `-d 0.0.0.0/0`" and the "no rules at all" halves are — not covered.
- **G7** — `init-firewall.sh:163` — missing or unreadable `/etc/resolv.conf` (the `2>/dev/null` on awk) yields an empty parse and must route to G6's else branch rather than aborting — not covered.
- **G8** — `init-firewall.sh:202-213` — the *removal* of `iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT`. Nothing prevents a future edit (or a bad merge from upstream Anthropic's reference script, which still has it) from restoring the blanket SSH tunnel — not covered.
- **G9** — `init-firewall.sh:89-99` — `fail_closed_on_abort` on a non-zero exit issues `-P OUTPUT DROP`, `-P INPUT DROP`, `-P FORWARD DROP`. This is the single guarantee that an abort in the post-flush/pre-DROP region fails closed — not covered.
- **G10** — `init-firewall.sh:91` — the `rc -ne 0` guard: on the success path the trap must be a no-op (no duplicate `-P` calls, original exit status preserved) — not covered.
- **G11** — `init-firewall.sh:94-96` — `|| true` on the trap's own three `iptables -P` calls: a failure on the first must not abandon the other two, leaving INPUT/FORWARD at ACCEPT — not covered.
- **G12** — `init-firewall.sh:228-232` — `gh_ranges=$(curl … || true)` followed by `if [ -z "$gh_ranges" ]` → `ERROR: Failed to fetch GitHub IP ranges` / `exit 1`. Before the `|| true` this branch was dead code; nothing pins that it is now reachable — not covered.
- **G13** — `init-firewall.sh:234-237` — `jq -e '.web and .api and .git'` rejecting a well-formed-but-incomplete meta response — not covered.
- **G14** — `init-firewall.sh:258-269` — `ips=$(dig … || true)` followed by `if [ -z "$ips" ]` → `WARNING: Failed to resolve … skipping`. Same dead-code-until-now situation as G12; this is the statsig-NXDOMAIN handling — not covered.
- **G15** — `init-firewall.sh:264-267` — the `api.anthropic.com` exception inside G14: a resolution failure for that one domain is a hard `exit 1`, not a skip — not covered.
- **G16** — `devcontainer-config/Dockerfile:398` — the sudoers entry `node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh` carries no `SETENV:` and no `env_keep`. This is the *only* thing that makes the script's env-var seams (`CC_EGRESS_DIR`, `CC_EGRESS_PROFILE_FILE`, and the `CC_RESOLV_CONF` this plan proposes) unreachable by the in-container agent — not covered.
- **G17** — `init-firewall.sh:285-289` — empty `HOST_IP` → `exit 1` (reachable when `ip route` has no default) — not covered.
- **G18** — `init-firewall.sh:315-328` — the two post-configuration verification probes (example.com must fail, api.github.com must succeed) — not covered. *(Pre-existing, not touched by this branch; listed for completeness and deferred below.)*

## The testability seam this plan requires

**Recommended change:** at the top of the DNS block, replace the hardcoded path:

```bash
RESOLV_CONF="${CC_RESOLV_CONF:-/etc/resolv.conf}"
dns_resolvers="$(awk '/^[[:space:]]*nameserver/ {print $2}' "$RESOLV_CONF" 2>/dev/null \
  | grep -E "^${octet}(\.${octet}){3}$" | sort -u || true)"
```

**Why it is needed:** I built and ran the stub harness below against the current script. Everything else works untouched — the full script runs to `exit 0` under non-root with no iptables — but the resolver block read the *host's real* `/etc/resolv.conf` (`192.168.65.7`), so G1–G7 are unaddressable without either this seam or a mount namespace. `scripts/confine-tests.sh` cannot help: decision 017 finding 1 records that `CLONE_NEWUSER` is seccomp-blocked in this very devcontainer, so no bind-mount of a fixture `resolv.conf` is available in CI or the authoring sandbox.

**Why it is safe, stated precisely.** The seam adds *nothing new in kind*: the file already carries two identical seams (`CC_EGRESS_DIR:23`, `CC_EGRESS_PROFILE_FILE:24`) and an inspection hook (`--print-domains:56`) added for exactly this reason, and lines 15-19 already document why they are safe. `node`'s sudo grant is `NOPASSWD:` only — **not** `SETENV:` — so sudo's default `env_reset` strips `CC_RESOLV_CONF` along with everything else, and the script's real invocation path (`postStartCommand` → `sudo init-firewall.sh`) never sees an agent-set value.

**The caveat you must accept with it.** This seam is strictly more dangerous than the existing two if `env_reset` ever lapses. A widened `CC_EGRESS_PROFILE_FILE` only reaches profile files that must exist under `EGRESS_DIR`; a controlled `CC_RESOLV_CONF` lets an agent write `nameserver <attacker_ip>` into a file it owns and receive a *scoped accept to it* — the exact inversion the TRUST ASSUMPTION comment at lines 140-148 warns about, reached through the front door rather than by compromising Docker's resolv.conf. That is why **T9 (G16) is not optional garnish — it is the price of the seam** and should land in the same commit.

**Alternative if you would rather not add the seam:** a second inspection hook, `--print-resolvers <file>`, taking the path as a positional argument and early-exiting like `--print-domains`. It adds no ambient env input at all, so it is strictly safer. It buys G1, G2, G3, G7 (the parse) but **not** G4, G5, G6 (the rule installation), because the full-body harness needs the path settable during a normal run. If you take this route, G4/G5/G6 stay uncovered — and G6 is the block that has regressed twice. I recommend the env seam plus T9.

## The stub harness (prototyped, working)

I built this and ran the real script under it. It is not a sketch.

One recorder script, symlinked under each binary name, appending `basename $*` to `$CMD_LOG` and dispatching stdout/exit on the name and args:

```bash
#!/usr/bin/env bash
n="${0##*/}"
printf '%s %s\n' "$n" "$*" >> "$CMD_LOG"
case "$n" in
  iptables-save) exit 0 ;;                                   # empty => "No Docker DNS rules to restore"
  ip)        [ "${1:-}" = route ] && echo "default via 172.17.0.1 dev eth0"; exit 0 ;;
  aggregate) cat; exit 0 ;;                                  # -q is a pass-through for our purposes
  dig)       printf '%s\n' "${STUB_DIG_OUT-example.test. 60 IN A 93.184.216.34}"; exit "${STUB_DIG_RC:-0}" ;;
  curl)      for a in "$@"; do case "$a" in
               *example.com*)        exit 7 ;;                # verification probe MUST fail
               *api.github.com/zen*) exit 0 ;;                # verification probe MUST succeed
               *api.github.com/meta*) printf '%s' "${STUB_GH_META-$DEFAULT_META}"; exit 0 ;;
             esac; done; exit 0 ;;
  *)         exit 0 ;;                                        # iptables, ipset: record and succeed
esac
```

Symlink `iptables ipset ip dig curl aggregate iptables-save` to it, `PATH="$STUB_BIN:$PATH"`. `jq`, `awk`, `sort`, `grep` stay real (`jq` is present at `/usr/bin/jq`). `iptables-save` returning empty output is what keeps the `xargs -L 1 iptables -t nat` restore path out of the way; a non-empty `DOCKER_DNS_RULES` fixture is a separate, optional case.

Assertions are `grep -c` / `grep -q` over `$CMD_LOG`. Verified working:

| prototype run | result |
|---|---|
| two-nameserver resolv.conf, happy path | script exits **0**; log shows the paired `-p udp`/`-p tcp -d <ns> --dport 53 -j ACCEPT` adds and the three `-P … DROP` |
| `STUB_GH_META=` (empty meta) | script exits **1**; log shows `-P OUTPUT DROP`, `-P INPUT DROP`, `-P FORWARD DROP` **before** the normal policy block — the trap firing |
| `STUB_DIG_RC=9`, empty dig output | `ERROR: Failed to resolve critical domain api.anthropic.com` then the trap's abort message |

Two gotchas the prototype surfaced, both worth a comment in the suite: the script sets `IFS=$'\n\t'`, and the `setlocale` warnings landed in captured output (hence `pin_hermetic_locale`).

## Recommended Tests

New suite: **`test/init-firewall-rules.bats`**, first line `# @category fast`. Everything below lives there unless stated. Keep `test/cc-isolated-functions.bats` as-is — it is the *composition* suite; this is the *rule-installation* suite.

#### T1 — no parseable IPv4 resolver: the script survives, and installs nothing

**Closes gaps:** G1, G6, G7
**Type:** unit (script-level, stubbed)
**Priority:** high
**File:** `test/init-firewall-rules.bats`
**What it verifies:** the else branch is reached rather than aborted into, and adds no `--dport 53` rule of any kind.
**Key cases:**
- resolv.conf containing only `nameserver fe80::1` and `search corp.local` → exit **0**; `grep -c 'dport 53 -j ACCEPT' $CMD_LOG` on OUTPUT rules is `0`; `grep -q 'ERROR: init-firewall.sh aborted' stderr` is false. *This case fails on the pre-`|| true` code by aborting — it is the G1 regression test.*
- same fixture → stderr contains `no parseable IPv4 nameserver`.
- same fixture → log contains **no** `-d 0.0.0.0/0` and **no** `-d 127.0.0.11` on any OUTPUT rule. *This is the two-directions-of-regression assertion; write both, not one.*
- `CC_RESOLV_CONF` pointed at a nonexistent path → identical outcome (G7).

**Setup needed:** the harness above + the `CC_RESOLV_CONF` seam. Fixture files written inline in the test with `printf`, not checked-in files.

#### T2 — parsed resolvers get exactly one scoped UDP+TCP accept each

**Closes gaps:** G4, G3
**Type:** unit
**Priority:** high
**File:** `test/init-firewall-rules.bats`
**What it verifies:** the populated branch emits a paired, `-d`-scoped accept per unique resolver and nothing wider.
**Key cases:**
- `nameserver 192.168.1.1` + `nameserver 10.0.0.53` → log has `iptables -A OUTPUT -p udp -d 192.168.1.1 --dport 53 -j ACCEPT` and the tcp twin, and the same pair for `10.0.0.53`; total OUTPUT `--dport 53` rule count is exactly 4.
- duplicate `nameserver 192.168.1.1` twice → count is 2, not 4 (pins `sort -u`).
- resolv.conf with `search x`, `options ndots:5`, `domain y`, `#nameserver 8.8.8.8`, and one real `nameserver 172.20.0.10` → exactly one pair, for `172.20.0.10` (G3).
- leading-whitespace `  nameserver 1.1.1.1` is honored (the `[[:space:]]*` in the awk pattern is load-bearing and easy to drop in a refactor).

**Setup needed:** as T1.

#### T3 — out-of-range octets never reach iptables

**Closes gaps:** G2
**Type:** unit
**Priority:** high
**File:** `test/init-firewall-rules.bats`
**What it verifies:** the real 0–255 alternation, not a shape check — the distinction the comment at 150-155 justifies.
**Key cases:**
- `nameserver 999.999.999.999` alone → exit 0, zero `--dport 53` OUTPUT rules (falls to the else branch).
- `nameserver 256.1.1.1` alone → same.
- `nameserver 1.2.3.4.5` and `nameserver 1.2.3` → same.
- mixed file: `nameserver 300.1.1.1` + `nameserver 10.0.0.53` → exactly one pair, for `10.0.0.53` only. *This is the strongest case — a partial-rejection assertion is what catches a regex that was loosened to `[0-9]{1,3}`.*
- boundary keepers: `nameserver 0.0.0.0`, `nameserver 255.255.255.255` and `nameserver 9.9.9.9` **are** accepted (guards against over-tightening the alternation).

**Setup needed:** as T1. Table-driven with a helper `run_fw_with_resolv <<<'...'` to keep this from becoming six near-identical blocks.

#### T4 — the trap forces DROP on every abort path

**Closes gaps:** G9, G12
**Type:** unit
**Priority:** high
**File:** `test/init-firewall-rules.bats`
**What it verifies:** any non-zero exit between the flush and the policy block leaves all three chains at DROP, and the original status still propagates.
**Key cases:**
- `STUB_GH_META=` → exit **1**; log contains all three of `-P OUTPUT DROP`, `-P INPUT DROP`, `-P FORWARD DROP`; stderr contains `Failed to fetch GitHub IP ranges` (G12: pins that the `|| true` kept this branch reachable rather than dying two lines earlier) **and** `forcing DROP`.
- `STUB_DIG_RC=9` with empty output → exit 1 with `Failed to resolve critical domain api.anthropic.com` **and** the three DROP policies (G15 rides along here for free).
- stub `ip` to print nothing for `route` → exit 1 with `Failed to detect host IP` and the three DROP policies (G17 rides along).
- assert the abort happened *before* the normal policy block by checking the log has no `-A OUTPUT -m set --match-set allowed-domains` line — i.e. the DROP came from the trap, not from line 299-301.

**Setup needed:** as T1; no seam required for this test.

#### T5 — the blanket SSH accept stays gone

**Closes gaps:** G8
**Type:** unit (behavioural) + source assertion
**Priority:** high
**File:** `test/init-firewall-rules.bats`
**What it verifies:** no OUTPUT rule accepts TCP/22 to an unscoped destination.
**Key cases:**
- happy-path run → `grep -E 'iptables -A OUTPUT.*--dport 22' $CMD_LOG` finds nothing.
- source-text assertion in the style of `cc-isolated-functions.bats:360`: `grep -E '^[^#]*iptables .*--dport 22 -j ACCEPT' init-firewall.sh` exits non-zero. Keep both: the behavioural one is the real check, the textual one survives a future refactor that stops calling `iptables` directly and gives a far clearer failure message on a bad upstream merge.
- the ESTABLISHED,RELATED INPUT/OUTPUT accepts *are* still present (the return path the comment relies on) — this is the "did you delete too much" half.

**Setup needed:** as T1.

#### T6 — the success path leaves the trap inert

**Closes gaps:** G10
**Type:** unit
**Priority:** medium
**File:** `test/init-firewall-rules.bats`
**What it verifies:** on `rc=0` the trap adds nothing, so a green run's rule set is exactly what the script body installed.
**Key cases:**
- happy path → exit 0, and `grep -c '^iptables -P OUTPUT DROP' $CMD_LOG` is exactly **1** (a broken `rc` guard makes it 2).
- happy path → stderr does not contain `forcing DROP`.

**Setup needed:** as T1.

#### T7 — a failing `iptables -A` warns and continues

**Closes gaps:** G5
**Type:** unit
**Priority:** medium
**File:** `test/init-firewall-rules.bats`
**What it verifies:** the `|| echo` guards, i.e. one unusable resolver degrades to "that resolver is blocked," not "the whole run aborts wide open."
**Key cases:**
- extend the `iptables` stub with `STUB_IPTABLES_FAIL_ON` (a substring matched against `$*`); set it to `--dport 53` with two nameservers configured → exit **0**, stderr contains `could not add UDP DNS rule for`, and the run still reaches `-P OUTPUT DROP`.

**Setup needed:** one extra branch in the recorder. Cheap; do it while the harness is fresh.

#### T8 — dig failure on a non-critical domain warns and skips

**Closes gaps:** G14
**Type:** unit
**Priority:** medium
**File:** `test/init-firewall-rules.bats`
**What it verifies:** the statsig-NXDOMAIN handling is reachable — the whole point of the `|| true` at line 258.
**Key cases:**
- `dig` stub returns empty + rc 9 for `statsig.anthropic.com` only, real-looking answers for everything else → exit **0**, stderr has `Failed to resolve statsig.anthropic.com - skipping`, log still reaches `-P OUTPUT DROP`, and the ipset never received an add for that domain.
- pair it with the G15 case already in T4 so the two arms of the same `if` are asserted together.

**Setup needed:** per-domain dispatch in the `dig` stub (match `$*` against the domain name).

#### T9 — the sudo grant does not carry the environment

**Closes gaps:** G16
**Type:** contract (source assertion over the Dockerfile)
**Priority:** high — **required if you take the `CC_RESOLV_CONF` seam**
**File:** `test/cc-isolated-functions.bats`, alongside the existing Dockerfile assertions at lines 384-405
**What it verifies:** the invariant that makes all three env seams unreachable from inside the container.
**Key cases:**
- the sudoers line matches `^node ALL=\(root\) NOPASSWD: /usr/local/bin/init-firewall\.sh$` — no `SETENV:` tag.
- no `env_keep` or `env_reset` override anywhere in `/etc/sudoers.d/node-firewall` as written by the Dockerfile.
- the grant names exactly one binary (a `NOPASSWD: ALL` or a second path is a hard fail).

**Setup needed:** none — pure `grep` over `devcontainer-config/Dockerfile`, same shape as the tests already in that suite.

## What NOT to Test

- **G11 (`|| true` on the trap's own three `iptables -P` calls).** Reaching it means stubbing `iptables` to fail *only* inside the trap, which pins the trap's internal call order — a brittle test of an implementation detail. The three calls are independent and idempotent; the failure mode it guards is real but the guard is two characters and visually obvious. Covered adequately by review.
- **G13 (`jq -e '.web and .api and .git'`).** Pre-existing, unchanged by this branch, and the branch below it is a plain `exit 1` that T4 already proves fails closed. Add the case only if you are already editing the meta-fetch stub for another reason — it costs one line then.
- **G18 (the two verification probes at 315-328).** Under the harness these assert only that the stub returned what the stub was told to return — a tautology. Their real value is in a live container and is covered by the manual procedure in `guides/devcontainer-setup.md`. Testing them here would be theatre.
- **The CIDR/IP shape validators at 241-244 and 273-276.** Pre-existing, untouched, and a `[0-9]{1,3}` shape check is the *known-weaker* form the DNS block deliberately does not use — testing it would pin behaviour the codebase has already decided is second-best.
- **`compose_domains` re-testing.** Nine tests already cover it via `--print-domains`; do not duplicate them in the new suite.
- **Anything asserting the *content* of the composed allowlist in the new suite.** That is the other suite's job. Keep the boundary: `cc-isolated-functions.bats` = "which domains," `init-firewall-rules.bats` = "which rules."

## Coverage Gaps Beyond Current Scope

**1.** **No IPv6 rules at all.** The script installs no `ip6tables` rules, so the entire allowlist — not just DNS — is unenforced over IPv6. The comment at 134-135 acknowledges this as pre-existing. It is the largest live hole in the boundary and dwarfs everything this plan tests; it belongs in `docs/decisions/`, not in a test.

**2.** **The `resolv.conf` trust assumption is documented but not asserted.** Lines 140-148 say "keep resolv.conf root-owned and not agent-writable, or this control inverts," and immediately concede the repo "does NOT enforce or assert [it] anywhere." A runtime assertion (`[ "$(stat -c %U /etc/resolv.conf)" = root ]`, warn-or-fail) would convert a comment into a control. Consider it a follow-up to this branch.

**3.** **The `DOCKER_DNS_RULES` restore path (`init-firewall.sh:111-118`) is untested,** including the `xargs -L 1 iptables -t nat` replay of captured rules. The harness added here makes it cheap to cover later — feed a non-empty `iptables-save` fixture — but it is unchanged by this branch.

**4.** **Nothing tests that the launcher's boundary probe notices a failed firewall run.** The trap deliberately does not `exit`, so the original status propagates; whether `cc-isolated.sh`'s probe acts on it is a separate, unverified link in the chain.

## Summary

The highest-value test is **T1** — it closes the exact regression review already caught once (G1), and simultaneously pins both directions of the twice-regressed else branch (G6). Write it first; if you write only one test from this plan, write that one. **T4** is a close second: it is the only check that the fail-closed trap actually fires, which is the property the whole post-flush window depends on. The plan needs one production change to be implementable — a `CC_RESOLV_CONF` seam — and I verified by running the real script under the prototype harness that nothing else blocks it: the full script executes to `exit 0` with no root and no iptables, and both the trap path and the critical-domain path already reproduce. The seam is consistent with two seams the file already has, but it is the sharpest of the three if `env_reset` ever lapses, which is why T9 should land in the same commit rather than as a follow-up. Residual risk after executing this plan is concentrated in what the harness cannot see: IPv6 is entirely unfiltered, and every test here proves what the script *asked* iptables to do, not what the kernel then did — only the manual live-container procedure closes that last step. The open question the enumeration surfaced is whether you want the env seam at all: the `--print-resolvers` hook alternative is strictly safer and buys G1/G2/G3/G7, but leaves G6 — the block with two regressions on its record — untestable.

---

## Goal-Alignment Note

**The literal request** was a test plan for the branch. **The underlying goal** is confidence that a security boundary with two review-caught regressions in the same block will not regress a third time, silently.

Three places where I served the goal over the literal ask, flagged so you can overrule them:

1. **I recommended a production code change.** You invited this conditionally; I am telling you it is not optional if you want G4/G5/G6 covered, and I ran the script to confirm rather than asserting it. I also flagged that this particular seam is more dangerous than its two siblings and attached a mandatory test (T9) rather than a caveat sentence.
2. **I prototyped instead of specifying.** The brief asked for "implementable, not 'add tests for the DNS logic'." Three of the plan's claims (the harness runs, the trap fires, `pin_hermetic_locale` is needed) are observations from an actual run, not predictions. Where I have *not* run something — T7's `STUB_IPTABLES_FAIL_ON`, T8's per-domain dig dispatch — those are extensions to a harness that works, not new bets.
3. **I declined more than I recommended in one place.** Five items are in *What NOT to Test*, including one gap (G11) inside the changed lines. For a once-per-container-start setup script, a test that pins the trap's internal call order costs more in future refactor friction than the two-character guard is worth. If your priority is regression-proofing over maintainability, G11 and G13 are the two you would add back.

**Residual disagreement worth surfacing:** the strongest test in the plan (T5's source assertion) is a `grep` over source text, which the skill's own guidance mildly discourages as testing implementation rather than behaviour. I kept it anyway because the realistic reintroduction path for the SSH hole is a merge from the upstream Anthropic reference script that still contains that line, and a textual assertion names that failure far more clearly than a missing-log-line assertion would. That is a deliberate deviation, not an oversight.
