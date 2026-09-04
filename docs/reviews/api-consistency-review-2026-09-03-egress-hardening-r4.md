# API Consistency Review — egress hardening pass 4, 1434fc9..f313de7

Commit: f313de7

**Scope:** `git diff 1434fc9..f313de7 -- devcontainer-config/` — `init-firewall.sh`, `cc-isolated.sh`, `cc-sni-proxy.py`, `Dockerfile`, `egress/base.txt`. Fourth pass of the review-fix loop, over the pass-3 fix round (`563448a` pass-3 closeout, `f313de7` pass-4 fact-check residuals). `test/init-firewall-rules.bats`, `test/cc-isolated-functions.bats`, `devcontainer-config/install.sh`, `devcontainer-config/devcontainer.json`, `guides/cc-isolated-usage.md`, `docs/working/questions.md` were read as **consumers and baselines**, not as review targets.
**Date:** 2026-09-03
**Based on:** `docs/reviews/api-consistency-review-2026-09-03-egress-hardening-r3.md` (pass 3, at `1434fc9`, findings 1–11); the pass-4 code fact-check (k=1 at `563448a`: 0 Incorrect; comment-prose imprecisions since corrected; sudoers `visudo -c` parse and `""`-means-no-arguments executed).
**Executed in this pass:** the full bats suite at `f313de7` (118/118 pass); `cc-isolated.sh --bless` against a synthetic config dir populated from this repo, in both the empty-`projects/` and one-registered-project states.

---

### Prior findings status

All eleven findings from the r3 report.

| Prior # | Finding | Status | Evidence |
|---|---|---|---|
| 1 | `HOST_LABEL`/`HOST_RE` collide with `HOST_IP`'s sense of "host"; `_RE` suffix on one of two regex constants | **Deferred** | `init-firewall.sh:129-130` unchanged; `HOST_IP` still at `:874`-equivalent. Not touched in this range. |
| 2 | "One hostname grammar … cannot disagree" is scoped to the shell; `cc-sni-proxy.py:48` holds a third label grammar | **Deferred** | `init-firewall.sh:125` still reads "so the two consumers cannot disagree"; `cc-sni-proxy.py`'s only change in range is `READY_TIMEOUT`. |
| 3 | Tightened ≥2-label grammar undocumented for profile authors | **Partly fixed** | `egress/base.txt:15-16` now states "A domain needs two or more labels (a bare label such as `com` would become a whole-TLD resolver zone and is rejected)". The guide half is still open: `guides/cc-isolated-usage.md` has no statement of the rule (`grep -n 'label\|two or more'` → no hits in the profile-authoring section). Line-wrap residue is finding 10 below. |
| 4 | `FIREWALL_LOCK_WAIT` silently repaired a bad value | **Fixed** | `init-firewall.sh:360-363` aborts with `ERROR: CC_FIREWALL_LOCK_WAIT must be a non-negative integer (got '<v>')`, matching the `(got '…')` family at `:484`/`:532`. Pinned by `test/init-firewall-rules.bats:956-961`. |
| 5 | `log()` `CONTRACT:` block sits on the wrong line; one-directional reference | **Deferred** | `cc-sni-proxy.py:160` unchanged. |
| 6 | `CC_EGRESS_DIR` doubled as an off-switch for the R7 ownership assertion; unannotated; untested | **Fixed (mechanism + test); annotation half open** | `init-firewall.sh:311` now keys on the invariant (`[ "$EGRESS_DIR" = "/usr/local/share/cc-egress" ]`) with `CC_EGRESS_OWNER_CHECK` as the explicit opt-in, and `test/init-firewall-rules.bats:986-996` exercises the assertion and asserts no `curl`/`dig`/`iptables -F` was issued. The r3 recommendation's annotation half did not land — see findings 2, 3 and 4 below. |
| 7 | `--print-dnsmasq-conf` diverges from `--print-entries`; the test encodes the divergence by omission | **Deferred** | `init-firewall.sh:221-223` and the hook at `:232-235` unchanged; `test/init-firewall-rules.bats:866` still asserts only the negative `!= *"server=/com/"*` with no status assertion. |
| 8 | Ownership comment claimed "all the way up"; the loop checked two levels | **Fixed** | `init-firewall.sh:302-308` now says "AND its parent … (/usr/local and /usr are root by construction of the base image and are not re-checked.)" — the r3 "scope the sentence" option, taken cleanly. |
| 9 | The IPv6 `WARNING:` labels a state phase A has proven benign | **Deferred** | `init-firewall.sh:606` unchanged. |
| 10 | `IP6_FILTER` is a 0/1 flag with a noun's name | **Deferred** | `init-firewall.sh:545`, `:547`, `:594` unchanged. |
| 11 | The `iptables -t nat -C` probe is the only capability check not suppressing the tool's stderr | **Not fixed — multiplied** | The single site was replaced by a five-iteration loop (`init-firewall.sh:1039-1054`), none of which redirects stderr. Re-raised as finding 5 below with the escalated count. |

Net: 3 fixed, 1 partly fixed, 6 deferred (all carried by rubric row C16), 1 escalated. **This is not a clean pass** — see finding 1, which is new and functional.

---

### Baseline Conventions

Re-confirmed at `f313de7` across `init-firewall.sh` (1063 lines), `cc-isolated.sh`, `cc-sni-proxy.py`, `Dockerfile`, `install.sh`, and the two bats suites. Unchanged from r3 except where noted.

- **Test seams** are `CC_<SUBSYSTEM>_<OBJECT>`, each with (a) a `${CC_X:-default}` **expansion at a declaration site**, (b) a comment at that site saying "for the unit tests only; under sudo `env_reset` `node` cannot set them", and (c) a **relocation** meaning — "read this path/port instead". Ten such seams before this range: `CC_FIREWALL_PATH` (`:38`), `CC_EGRESS_DIR`/`CC_EGRESS_PROFILE_FILE` (`:40-41`), `CC_DNSMASQ_CONF`/`CC_DNSMASQ_PIDFILE` (`:474-475`), `CC_SNI_PROXY_BIN`/`CC_SNI_RUN_DIR`/`CC_SNI_PORT`, `CC_FIREWALL_LOCK`/`CC_FIREWALL_LOCK_WAIT` (`:358-359`). `cc-isolated.sh` adds `CLAUDE_DEVC_CONFIG_DIR` and `CC_WORKFLOWS_DIR`/`CLAUDE_CONFIG_DIR`.
- **In-script booleans** are compared to the literal `"1"`, never tested for non-emptiness: `FIREWALL_COMPLETE` (`:270`), `IP6_FILTER` (`:594`). Test *stub* toggles inside the bats fixtures (`NO_IP6_TABLE`, `HAS_GLOBAL_V6`, `NO_REDIRECT`, `FORGED_SNI_LOG`, and now `NO_RULE`) live in the stubs, not in the script under test.
- **Value validation** aborts with an `ERROR:` naming the observed value: `(got '${DNSMASQ_UID:-none}')`, `(got '…')` for `ccproxy` (`:532`), `'$entry' (want domain[:port[,port...]])`.
- **Error vocabulary**: `ERROR:`/`WARNING:` on stderr for preconditions; the terminal verification family on **stdout** with the fixed stems `ERROR: Firewall verification failed - <what>` / `Firewall verification passed - <what>`, printed under the `Verifying firewall rules...` banner.
- **Capability probes suppress the tool's own output** and report in the script's vocabulary — `command -v … >/dev/null 2>&1`, `ip6tables -w 5 -S OUTPUT >/dev/null 2>&1`, `id -u … 2>/dev/null || true`, `grep -q … 2>/dev/null`, `curl … >/dev/null 2>&1` (×5).
- **Duplicated literals are expected to be self-detecting.** `init-firewall.sh:1039-1041` states this as a design property: "drift between the two literals is self-detecting (the run aborts into DROP)". `compose_domains` (`:130-135`) documents the sibling trap — "a `return 1` inside a `for … done | sort` pipeline would run in a subshell and be masked by sort's exit status" — and restructures to avoid it.
- **`cc-isolated.sh` runs under `set -euo pipefail`** (`:31`). Every list-producing helper is a `( … )` subshell whose status the caller discards (`done < <(enforcement_files)`), so a mid-subshell abort is silent by construction.
- **Manifest contract**: `compute_manifest` emits `<sha256>  <path>` lines in `enforcement_files()` order; `check_manifest` compares the whole blob **textually** and diffs on mismatch. Ordering and membership are therefore both part of the contract.
- **Python side**: module constants `UPPER_SNAKE` with a `_TIMEOUT` suffix for durations; failures on the daemonize path write `cc-sni-proxy: failed to start: <reason>` to stderr and `return 1`.
- **Sudo surface**: `node` has exactly one NOPASSWD grant. Both call sites pass no arguments — `devcontainer.json:121` (`postStartCommand`) and `cc-isolated.sh:432` (re-assert path). No guide or decision record documents a `sudo init-firewall.sh --print-*` invocation.

---

### Name-Pattern Audit

Every new public name in the range. "Public" = env seam, script-level constant, on-disk path, operator-visible message string, or manifest-contract element.

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `CC_EGRESS_OWNER_CHECK` | env seam | `CC_EGRESS_DIR`, `CC_EGRESS_PROFILE_FILE`, `CC_FIREWALL_LOCK_WAIT` | `devcontainer-config/init-firewall.sh:40-41`, `:358-359` | **Inconsistent — new class** — the family's ten members all *relocate an object* and all have a `${CC_X:-default}` declaration line carrying the family annotation. This one gates a check, has no declaration line at all, and is tested with `-n` rather than `= "1"` (finding 2) |
| `CC_FIREWALL_LOCK_WAIT` default `120` → `600` | env seam default | `HELLO_TIMEOUT`/`CONNECT_TIMEOUT` `10.0`, `READY_TIMEOUT` `30.0`, `--max-time 15` | `cc-sni-proxy.py:46-48`; `init-firewall.sh:344-350` | **Consistent** — the new value is derived in-comment from the components it must cover (15 s meta fetch + ~25 × 6 s + 39 s daemon starts + 4 × 15 s ≈ 270 s, ×2.2 headroom). Its operator-visible consequence is finding 11 |
| `"ERROR: CC_FIREWALL_LOCK_WAIT must be a non-negative integer (got '<v>')"` | stderr error | `ERROR: no unprivileged 'dnsmasq' user (got '…')`, `ERROR: no distinct unprivileged 'ccproxy' user (got …)` | `init-firewall.sh:484`, `:532` | **Consistent** — right prefix, right stream, `(got '…')` shape. The only member of the family that names the *env var* rather than the derived constant, which is correct here: the constant can only be wrong if the env var was set |
| `"ERROR: could not take … within Ns — another init-firewall.sh run is still in progress"` | stderr error | the message it replaces ("… rebuild is still running") | `init-firewall.sh:368` | **Consistent — improved** — "run"/"in progress" now matches the widened scope (the lock spans both phases); the old wording would have misdescribed a wait during phase A |
| `"ERROR: Firewall verification failed - expected rule missing: iptables <rule>"` | stdout verification failure | `… - was able to reach https://example.com`, `… - the SNI proxy did not log a redirected refusal … (see $SNI_LOG)` | `init-firewall.sh:1061`, `:1105` | **Consistent stem/stream** — one wrinkle: the interpolated `<rule>` is the `-C` *query* form, so the operator is handed a command that re-checks rather than one that installs. Acceptable (it is the exact literal that failed) and matched by `test/init-firewall-rules.bats:963-969`, which greps for it |
| `READY_TIMEOUT` (`30.0`) | Python module constant | `HELLO_TIMEOUT`, `CONNECT_TIMEOUT` | `cc-sni-proxy.py:46-47` | **Consistent** — same `UPPER_SNAKE` + `_TIMEOUT` shape, same float type, and the only one carrying an inline comment naming its owner (`daemonize()`), which is an improvement over its two neighbours |
| `"cc-sni-proxy: failed to start: no readiness signal within 30s"` | Python stderr | `cc-sni-proxy: failed to start: {msg}` (same function, `:271`) | `cc-sni-proxy.py:271` | **Consistent** — same stem, same stream, same `return 1`, and `{READY_TIMEOUT:.0f}s` mirrors the shell's `${FIREWALL_LOCK_WAIT}s` |
| `Defaults:node env_reset, !setenv` + `… init-firewall.sh ""` | sudoers grant | the single-line grant it replaces | `Dockerfile:429` | **Consistent — narrowed** — `visudo -c` parses it (pass-4 fact-check, executed) and both callers pass no arguments. See "What Looks Good" |
| `claude-home/<path>` entries in `enforcement_files()` | manifest contract element | `egress/*.txt`, `projects/*.profile`, the six fixed names | `cc-isolated.sh:60-73` | **Inconsistent in mechanism, not in name** — the path shape is right; the walk is placed after a glob loop that aborts the subshell when `projects/` is empty (finding 1), and it collates with `LC_ALL=C sort` where its two siblings use bare `sort` (finding 9) |
| `NO_RULE=<CHAIN>` | bats stub toggle | `NO_IP6_TABLE`, `HAS_GLOBAL_V6`, `NO_REDIRECT`, `FORGED_SNI_LOG` | `test/init-firewall-rules.bats:51-52`, `:132-134` | **Consistent** — bare `UPPER_SNAKE`, no `CC_` prefix (correct: it is a stub toggle, not a script seam), and it carries a *value* (the chain to omit) rather than being a bare flag, which the sibling toggles do not — a deliberate and readable extension |
| `egress/base.txt` "two or more labels" sentence | consumer-facing spec | the surrounding `Format:` block | `devcontainer-config/egress/base.txt:13-21` | **Placement consistent, wrap inconsistent** — the sentence is in the right block; it was spliced mid-line and left a 122-column line in an ~85-column comment block, and the guide half is still missing (finding 10) |

No new routes, exported functions, CLI flags, build args, or config fields. `--print-*` hook names, `/run` layout, and the `<VERB> k=v` proxy log grammar are unchanged.

---

### Findings

#### 1. `enforcement_files()` silently drops the entire `claude-home/` walk when `projects/` is empty — which is the fresh-install state

**Severity:** Breaking
**Location:** `devcontainer-config/cc-isolated.sh:64-73` (the subshell), `:31` (`set -euo pipefail`), `:82-89` (the caller that discards the status)
**Move:** 3 (consumer contract) / 9 (idempotency & state-dependence)
**Confidence:** High — executed at `f313de7`

**Evidence:**
> ```
>   (
>     cd "$cfg" || return 0
>     for f in egress/*.txt; do [ -e "$f" ] && echo "$f"; done | sort
>     for f in projects/*.profile; do [ -e "$f" ] && echo "$f"; done | sort
>     if [ -d claude-home ]; then find claude-home -type f | LC_ALL=C sort; fi
>   )
> ```

Executed against a synthetic config dir holding the real six fixed files, the eight `egress/*.txt`, a 103-file `claude-home/` (staged exactly as `install.sh` stages it) and a `projects/` directory, invoking the real entrypoint `bash devcontainer-config/cc-isolated.sh --bless`:

| `projects/` state | `--bless` output lines | `claude-home/…` lines hashed |
|---|---|---|
| empty (no `.profile`) | 16 | **0** |
| one `.profile` present | 120 | 103 |

The mechanism: with no glob match, `f` holds the literal `projects/*.profile`, `[ -e "$f" ]` is false, and the `&&` list — the last command in the loop body, and so the loop's exit status — returns 1. `set -o pipefail` (`:31`) promotes that over `sort`'s 0, and `set -e` kills the `( … )` subshell **before** the new `claude-home` line runs. The caller reads the helper as `done < <(enforcement_files)`, so the subshell's non-zero status is discarded and neither `compute_manifest`'s missing-file check nor `check_manifest`'s diff can see it: `compute_manifest` verifies that every *listed* file exists, and nothing verifies that the *list* is complete.

Consumer impact. `enforcement_files()`'s contract is "the set of files whose integrity gates a build", and `cc-isolated.sh:47-49` states the invariant it exists to hold: "a file that is installed but not hashed is a boundary artefact nobody blessed (the SNI proxy shipped that way once)". A first install — `install.sh` creates `$DEST/projects` empty, and `cc-isolated.sh:70` documents "An empty `projects/` dir is normal (no project has widened its egress yet)" — blesses a manifest with the entire baked skills/hooks payload absent, and `--bless` prints 16 lines that look exactly like the correct pre-change output. The payload becomes hashed only once some project is registered, so the property this range was added to buy is present or absent depending on unrelated state, silently, in both directions.

The existing suite cannot see it: bats `run` disables errexit for the invoked command, so `test/cc-isolated-functions.bats:519-529` passes against a fixture whose `setup()` never creates `projects/` at all. The failure is reachable only through the real entrypoint.

This is also the exact trap the sibling script documents and defends against — `init-firewall.sh:130-135`: "A `return 1` inside a `for … done | sort` pipeline would run in a subshell and be masked by sort's exit status, so a typo'd profile would silently yield a narrower allowlist that reads as a mysterious network outage rather than an error."

Failure mode: *a new list element appended after a latent early-exit, in a helper whose status the caller discards*.

**Recommendation:** Make each glob loop exit 0 — `for f in projects/*.profile; do [ -e "$f" ] || continue; echo "$f"; done | sort` (and the same for `egress/*.txt`, which survives today only because the glob always matches). Then add a `cc-isolated-functions.bats` case that runs `compute_manifest` through `bash "$CONFIG_SRC/cc-isolated.sh" --bless` (not the sourced function, so `set -e` is live) with `projects/` empty and asserts a `claude-home/` line is present. Consider `set -o pipefail`'s reach over these helpers explicitly while there.

---

#### 2. `CC_EGRESS_OWNER_CHECK` opens a new seam class and adopts none of the family's three conventions

**Severity:** Inconsistent
**Location:** `devcontainer-config/init-firewall.sh:308-311`; consumer `test/init-firewall-rules.bats:986-996`
**Move:** 2 (naming) / 3 (consumer contract)
**Confidence:** High

Precedent: `CC_<SUBSYSTEM>_<OBJECT>` seams with a `${CC_X:-default}` declaration line, a family annotation at that line, and a relocation meaning, used in `devcontainer-config/init-firewall.sh:38` (`CC_FIREWALL_PATH`), `:40-41` (`CC_EGRESS_DIR`, `CC_EGRESS_PROFILE_FILE`), `:474-475` (`CC_DNSMASQ_CONF`, `CC_DNSMASQ_PIDFILE`), `:358-359` (`CC_FIREWALL_LOCK`, `CC_FIREWALL_LOCK_WAIT`).

**Evidence:**
> `if [ "$EGRESS_DIR" = "/usr/local/share/cc-egress" ] || [ -n "${CC_EGRESS_OWNER_CHECK:-}" ]; then`

Splitting the off-switch out of `CC_EGRESS_DIR` was the right call and closes r3 finding 6's substance. What did not come with it is the family's shape, in three respects:

1. **No declaration site.** Every other seam is introduced by a `NAME="${CC_X:-default}"` line; `rg 'CC_EGRESS_OWNER_CHECK' devcontainer-config/` returns only the comment at `:309` and the `if` at `:311`. A test author scanning the seam declarations (which is what `:38`, `:40-41`, `:358-359`, `:474-475` are for) will not find it, and there is no single line to attach the contract to.
2. **No `env_reset` clause.** `:309-310` says only "lets the unit tests exercise it against a relocated directory". Every other seam's annotation ends "under sudo `env_reset` `node` cannot set them" — the sentence that tells a reader why a security-relevant env var is safe to read. Its absence is most conspicuous on the one seam that touches a security assertion.
3. **`-n` truthiness where the script uses `= "1"`.** `FIREWALL_COMPLETE` (`:270`) and `IP6_FILTER` (`:594`) are both compared to the literal `"1"`. Under `-n`, `CC_EGRESS_OWNER_CHECK=0` and `CC_EGRESS_OWNER_CHECK=off` both *enable* the check. Harmless in polarity terms (see "What Looks Good") but it is the first non-empty-string boolean in either script, and the next opt-in seam will copy whichever precedent it finds.

Failure mode: *a new convention class entering through a one-line conditional rather than a declaration*.

**Recommendation:** Give it a declaration line beside its siblings and key the branch on it — `EGRESS_OWNER_CHECK="${CC_EGRESS_OWNER_CHECK:-0}"` with the family annotation plus the second sentence "unlike the other `CC_*` seams this one *adds* a check rather than relocating a path, so the worst a caller can do with it is make the run stricter" — and test it as `[ "$EGRESS_OWNER_CHECK" = "1" ]`. Update `test/init-firewall-rules.bats:988` to pass `1`, which it already does.

---

#### 3. The egress default path is now a duplicated literal with no self-detection, gating the R7 assertion

**Severity:** Inconsistent
**Location:** `devcontainer-config/init-firewall.sh:40` and `:311`
**Move:** 3 (consumer contract) / 7 (asymmetry)
**Confidence:** High

**Evidence:**
> `EGRESS_DIR="${CC_EGRESS_DIR:-/usr/local/share/cc-egress}"`  (`:40`)
> `if [ "$EGRESS_DIR" = "/usr/local/share/cc-egress" ] || …`  (`:311`)

Keying the assertion on the invariant rather than on seam presence is correct, but it spends the fix on a second copy of the default path. The two must agree or the R7 ownership assertion — the check that closed the pass-2 Critical — silently stops running in production, with no error, no warning, and a passing suite: the one test that exercises the assertion (`test/init-firewall-rules.bats:986`) forces it via `CC_EGRESS_OWNER_CHECK`, so it would keep passing while the production branch went dead. The Dockerfile holds a third copy (`chmod 0444 /usr/local/share/cc-egress/*.txt`, `:426`) and `docs/working/questions.md:20` shows the path's ownership is under active discussion, so the literal is not frozen.

This is directly counter to the property the same range asserts 730 lines later, at `:1039-1041`: "`-C` queries what `-A`/`-I` installed; drift between the two literals is self-detecting (the run aborts into DROP)." Here drift is silent in the unsafe direction.

Failure mode: *a security gate keyed on a literal that has no single source of truth*.

**Recommendation:** `EGRESS_DIR_DEFAULT="/usr/local/share/cc-egress"` immediately above `:40`, used at both sites (`EGRESS_DIR="${CC_EGRESS_DIR:-$EGRESS_DIR_DEFAULT}"`, `[ "$EGRESS_DIR" = "$EGRESS_DIR_DEFAULT" ]`). One line, and the assertion then cannot be turned off by editing a path.

---

#### 4. `:471-473` still forwards the reader to an annotation that does not exist, and `:40-41` still has none

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:471-473`; target `:40-41`
**Move:** 3 (consumer contract)
**Confidence:** High

**Evidence:**
> `# The two paths are env-overridable for the unit tests only: this script runs via`
> `# sudo (NOPASSWD, no SETENV), whose env_reset strips them, exactly as for`
> `# CC_EGRESS_DIR above.`

r3 finding 6 asked for two things: remove the off-switch meaning, and annotate `:40-41`. The first landed; the second did not. `:40-41` still carries no comment of any kind, so the cross-reference at `:473` — which is the *only* place in the script that claims a `CC_EGRESS_DIR` annotation exists, and is itself the model other seams were written against — remains dangling. A reader who follows it now lands on a bare assignment and, if they keep looking, finds the discussion 270 lines further down at `:302-310` attached to an ownership check rather than to the seam.

The convention this breaks is stated by the seams that honour it: `:38` and `:358-359` both annotate at the assignment.

Failure mode: *a documentation cross-reference kept alive across two fix rounds while its target stayed empty*.

**Recommendation:** Add the family annotation above `:40`: "`CC_EGRESS_DIR` / `CC_EGRESS_PROFILE_FILE` exist for the unit tests only; under sudo `env_reset` `node` cannot set them. Relocating the directory does not disable the root-ownership assertion below — see `CC_EGRESS_OWNER_CHECK` at `:308`." That closes findings 2, 3 and 4's documentation halves in one edit.

---

#### 5. The `-C` rule probes are now five, and still the only capability checks that let `iptables` speak over the script's diagnosis

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:1039-1054`
**Move:** 4 (error consistency)
**Confidence:** Medium

**Evidence:**
> ```
>     IFS=' ' read -r -a rule_args <<< "$rule"
>     if ! iptables "${rule_args[@]}"; then
>         echo "ERROR: Firewall verification failed - expected rule missing: iptables $rule"
> ```

This is r3 finding 11 unfixed, and the fix round multiplied the site rather than closing it: the one unsuppressed `-C` became a loop of five, each of which runs on every successful invocation. The convention is uniform in this script and unchanged in this range — `command -v ip6tables >/dev/null 2>&1 && ip6tables -w 5 -S OUTPUT >/dev/null 2>&1` (`:546`), `ipset destroy allowed-domains 2>/dev/null || true`, `id -u ccproxy 2>/dev/null || true` (`:531`), `grep -q … "$SNI_LOG" 2>/dev/null` (`:1101`), and all five `curl … >/dev/null 2>&1` probes in the same block.

`route: code-fact-check` — **Not verified by execution:** the bats `iptables` stub writes to `$CMD_LOG` and exits 0 (or 1 under `NO_RULE`) without touching stderr, so the suite cannot show this; the claim rests on documented `iptables -C` behaviour (it prints `iptables: Bad rule (does a matching rule exist in that chain?)` to stderr when the rule is absent). If that holds, a failing run emits iptables' own diagnostic immediately before the script's `ERROR:` line, at the moment a reader is trying to distinguish a missing rule from a broken probe — and now potentially with the loop having printed nothing for the four rules that did pass.

Failure mode: *a probe convention broken once, then replicated by the fix that touched it*.

**Recommendation:** `if ! iptables "${rule_args[@]}" 2>/dev/null; then`. One character-cluster, five sites at once. Verify against a real `iptables` before landing, or fold into the live-container check already carried in `docs/working/questions.md:11`.

---

#### 6. "Every rule the boundary depends on" names five of the rules the boundary depends on

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:1036-1054`
**Move:** 3 (consumer contract) / 4 (error consistency)
**Confidence:** High

**Evidence:**
> `# Every rule the boundary depends on must actually be present — not just the one`
> `# the SNI probe needs.`

The loop asserts the three nat redirects and the two guard jumps. Not asserted: the `-A OUTPUT -m set --match-set allowed-domains dst,dst -j ACCEPT` rule installed four lines above (`:1035`), the terminal `-A OUTPUT -j REJECT --reject-with icmp-admin-prohibited` (`:1038`), and the chain policies. Those are boundary rules by any reading of the sentence — the ACCEPT is the entire allowlist and the REJECT is the default-deny.

This is r3 finding 8's shape recurring at a new site in the same commit that fixed it two hundred lines above: the ownership comment was rescoped from "all the way up" to the two levels the loop checks, and then a new comment stating a universal was written over a five-element list. The script's own convention is to enumerate what it checks — `:529` ("Numeric, non-zero, and distinct from dnsmasq") names exactly the three conditions the next line tests.

Failure mode: *stated invariant broader than the assertion, immediately after the same class of finding was closed*.

**Recommendation:** Either add the two `-A OUTPUT` rules to the list (they are `-C`-checkable in the same form and cost nothing), or scope the sentence: "The five rules whose absence the probes below cannot detect — the nat redirects and the two guard jumps. (The ACCEPT and REJECT rules are exercised directly by the curl probes.)" The second is accurate, since the example.com and api.github.com probes do cover those two.

---

#### 7. The rule loop runs above the banner that announces verification, and above "Firewall configuration complete"

**Severity:** Minor
**Location:** `devcontainer-config/init-firewall.sh:1036-1057`
**Move:** 4 (error consistency)
**Confidence:** High

**Evidence:**
> ```
> done                                   # ← the -C loop ends here
>
> echo "Firewall configuration complete"
> echo "Verifying firewall rules..."
> ```

The `ERROR: Firewall verification failed - …` family is, by convention, the block printed under the `Verifying firewall rules...` banner; the six other members of the family all sit below it. The new loop emits that stem from above it, so a rule-missing abort produces a log that goes straight from `Resolved …`/daemon-start chatter to `ERROR: Firewall verification failed - expected rule missing: …` with no verification section ever announced, and without the `Firewall configuration complete` line — which is true (configuration *is* complete at that point; only assertion failed) but reads as though the rebuild died mid-way.

Failure mode: *a message family's stem used outside the section that gives it context*.

**Recommendation:** Move the two `echo` lines above the loop. The loop is verification, so it belongs under the verification banner, and `Firewall configuration complete` is factually earned before it runs.

---

#### 8. `--bless` prints a 120-line hash dump with no summary, and the human review gate has no shape

**Severity:** Minor
**Location:** `devcontainer-config/cc-isolated.sh:91-96`
**Move:** 3 (consumer contract)
**Confidence:** High — measured

**Evidence:**
> ```
> bless_manifest() {
>   mkdir -p "$(config_dir)"
>   compute_manifest > "$(manifest_path)"
>   echo "Blessed $(manifest_path):"
>   cat "$(manifest_path)"
> }
> ```

Measured at `f313de7`: 120 lines with one project registered (16 before this range). `--bless` is documented at `:10` as "re-bless the installed config after YOU reviewed it" — it is the human gate, and `install.sh` calls it at the end of every install. A 120-line unlabelled hash dump is not a regression in correctness but it is a regression in the gate's legibility: the six files that actually execute host-side are now 5% of the output and are visually indistinguishable from 103 markdown files.

It also interacts badly with finding 1: on a fresh install the printout is 16 lines, which is precisely the *old, correct-looking* output — so the operator's only visible signal that the payload went unhashed looks identical to the pre-change baseline.

Note this was a known-and-accepted question at the time (`docs/working/questions.md:16`, still unchecked despite this range answering it; `:21` records the follow-on). It is raised here because the answer landed and the presentation did not follow it.

Failure mode: *an integrity list that grew 7× without its human-facing renderer changing*.

**Recommendation:** Keep the full file on disk, and print a summary plus the non-`claude-home` lines: `echo "Blessed $(manifest_path): N files (6 host-side, E egress profiles, P project profiles, C claude-home payload)"`, then `grep -v '^.*  claude-home/'` for the detail, with a pointer to `cat` the manifest for the rest. Also tick `questions.md:16`.

---

#### 9. The new walk collates with `LC_ALL=C sort`; its two siblings use bare `sort`

**Severity:** Informational
**Location:** `devcontainer-config/cc-isolated.sh:69-71`
**Move:** 3 (consumer contract)
**Confidence:** High

**Evidence:**
> `    for f in egress/*.txt; do [ -e "$f" ] && echo "$f"; done | sort`
> `    for f in projects/*.profile; do [ -e "$f" ] && echo "$f"; done | sort`
> `    if [ -d claude-home ]; then find claude-home -type f | LC_ALL=C sort; fi`

Manifest **order** is part of the contract — `check_manifest` compares the two blobs textually and any reordering reads as tampering — and the file's own comment says so ("Sorted globs so the manifest is order-stable"). Three sorted lists now use two collations. Harmless today (`egress/*.txt` and `projects/*.profile` are lowercase-ASCII, where C and any UTF-8 locale agree, and `project_id` yields hex), so this is not a live bug; it is a divergence a future name — an uppercase or non-ASCII profile filename, or a hyphen/underscore pair — could turn into a locale-dependent manifest.

Pinning C for the walk was the right instinct. The inconsistency is that it stopped at one of three.

**Recommendation:** `LC_ALL=C sort` on all three, or set `LC_ALL=C` once for the subshell (`cd "$cfg" || return 0` line is a natural home) and drop the per-command prefix.

---

#### 10. The `base.txt` grammar sentence landed; the wrap and the guide half did not

**Severity:** Informational
**Location:** `devcontainer-config/egress/base.txt:15-16`; `guides/cc-isolated-usage.md`
**Move:** 3 (consumer contract)
**Confidence:** High

Precedent: `#`-comment blocks wrapped at ~85 columns throughout `devcontainer-config/egress/*.txt` and `devcontainer-config/init-firewall.sh:1-30`.

**Evidence:**
> `# entry is admitted on tcp 443 only. A domain needs two or more labels (a bare`
> `# label such as \`com\` would become a whole-TLD resolver zone and is rejected). The firewall matches destination address AND`

The content is right, in the right block, and closes the substance of r3 finding 3 for anyone reading `base.txt`. Two residues: the splice left a 122-column line in an ~85-column block (the same edit-artifact class as `init-firewall.sh:349-351`, "The wait is … one. The lock lives in a 0700" / "# root directory", and `cc-isolated.sh:50-51`, "…re-blesses by design. Paths are relative to config_dir." — all three are comment reflows this range owes); and `guides/cc-isolated-usage.md`, which is where a profile author is sent to learn the format, still does not state the ≥2-label rule.

**Recommendation:** Reflow the three comment blocks, and add the one-clause rule to the guide's profile section.

---

#### 11. Widening the lock to both phases moved the launcher's silent worst-case wait from ~2 min to ~10 min

**Severity:** Informational
**Location:** `devcontainer-config/init-firewall.sh:344-368`; consumer `devcontainer-config/cc-isolated.sh:432`
**Move:** 3 (consumer contract)
**Confidence:** Medium

Two changes compose here. The lock now spans phase A as well as phase B — correct, and the reasoning at `:337-343` is sound — and the wait went `120` → `600`. Together, a `cc-isolated` launch that races the container's own `postStartCommand` (`devcontainer.json:121`) now blocks at `cc-isolated.sh:432` for up to ten minutes with no output before printing the "may now have DROP policies" error. Previously the ceiling was two minutes, and phase A at least proceeded concurrently.

Both numbers are individually justified — the 600 s is derived component-by-component in the comment, and the phase-A serialisation closes a real interleaving. The consumer-visible artefact is that the launcher has no progress line for a wait that is now long enough to look like a hang, and its error text names the wrong cause for that case (a lock timeout is not a fail-closed rebuild).

**Recommendation:** Have the launcher's re-assert path say what it is doing before it blocks, and consider having `init-firewall.sh` emit `Waiting for another init-firewall.sh run to finish (up to ${FIREWALL_LOCK_WAIT}s)…` on a non-blocking `flock -n` failure before falling back to the blocking wait — one extra line, and the ten-minute silence becomes an explained ten minutes.

---

### What Looks Good

Scoped to what I read and executed in this range.

- **r3 finding 6 was fixed at the seam, not at the symptom, and the untested half was closed too.** Keying on `[ "$EGRESS_DIR" = … ]` rather than on `[ -z "${CC_EGRESS_DIR:-}" ]` is exactly the "assert the invariant, not the absence of a test override" move the recommendation asked for, and `test/init-firewall-rules.bats:986-996` now drives the R7 assertion for real — including the two things that matter more than the message (`grep -cE "^(curl|dig|iptables -F)"` is 0, and `iptables -w 5 -P OUTPUT DROP` is present), so the test pins "aborts *before the flush*, fail-closed", not just "prints a string". `route: code-fact-check` — **Verified:** 118/118 bats pass at `f313de7`.
- **`CC_EGRESS_OWNER_CHECK`'s polarity is the safe one.** Whatever else finding 2 says about its shape, the seam can only *add* a check. An attacker who could somehow set it (they cannot — `Defaults:node env_reset, !setenv`) would make the run stricter. Choosing the opt-in direction rather than an opt-out was the right call, and is worth stating in the comment as a property rather than leaving a reader to derive it.
- **r3 finding 4 was closed with the abort, and the abort is tested.** `:360-363` matches the `(got '…')` family verbatim, and `test/init-firewall-rules.bats:956-961` pins it. The message names the env var rather than the derived constant, which is the more useful of the two for the only caller who can trigger it.
- **The sudoers narrowing is a real reduction with its consumers checked.** `Defaults:node env_reset, !setenv` states rather than inherits the property every `CC_*` seam comment already relied on, and the `""` argument constraint means the `--print-*` inspection hooks are no longer root-runnable. Both call sites pass no arguments (`devcontainer.json:121`, `cc-isolated.sh:432`), and no guide or decision record documents a rooted hook invocation — so this is a narrowing with zero known consumers, and the residual question is recorded rather than assumed (`docs/working/questions.md:22`). `route: code-fact-check` — **Verified upstream:** pass-4 fact-check executed `visudo -c` on the two-line file and confirmed `""` means "no arguments".
- **The Dockerfile comment now explains the grant to the person who has to keep it working.** "every `CC_*` test override in `init-firewall.sh` relies on `node` being unable to pass environment through this grant" is the sentence that makes the ten seam annotations true, and it lives at the line that would break them.
- **`READY_TIMEOUT` closes a real deadlock at the seam that owns it.** The parent could previously block forever on `os.read(r, …)` while holding the firewall lock — the widened lock made that a container-wide stall rather than a single-process one, and the fix landed in the same range as the widening. Message stem, stream, `return 1`, and the `{…:.0f}s` rendering all match the surrounding contract, and `daemonize()`'s docstring already stated the exit-status contract this preserves.
- **`NO_RULE=<CHAIN>` is the best-shaped stub toggle in the suite.** The four existing toggles are bare flags; carrying the chain name as a value lets one test seam cover five rules, and `test/init-firewall-rules.bats:963-969` uses it to assert the exact interpolated message rather than a substring of it.
- **`compute_manifest`'s batching is a genuine, measurable improvement with an unchanged output contract.** One `sha256sum` over the array replaces ~110 forks per launch, and `sha256sum` emits byte-identical `<hash>  <path>` lines either way, so no consumer of the manifest format sees a difference. The comment says why. (The list it batches over is finding 1's problem, not this change's.)
- **`enforcement_files`'s comment carries the reason the reader needs.** "`.manifest` … so re-running `install.sh` re-blesses by design" pre-empts the exact confusion the provenance stamp would otherwise cause, and the modes ("scripts 0555, the rest 0444 inside the image") are stated where a reviewer of the walk will look for them.

---

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `enforcement_files()` silently drops the whole `claude-home/` walk when `projects/` is empty — the fresh-install state; measured 0 vs 103 lines | Breaking | `cc-isolated.sh:64-73`, `:31`, `:82-89` | High (executed) |
| 2 | `CC_EGRESS_OWNER_CHECK` opens an opt-in-to-a-check seam class with no declaration site, no `env_reset` clause, and `-n` truthiness | Inconsistent | `init-firewall.sh:308-311` | High |
| 3 | `/usr/local/share/cc-egress` duplicated at `:40` and `:311`; drift silently disables the R7 assertion and the suite would not notice | Inconsistent | `init-firewall.sh:40`, `:311` | High |
| 4 | `:473` still forwards to a `CC_EGRESS_DIR` annotation that does not exist; `:40-41` still unannotated (r3 #6's documentation half) | Minor | `init-firewall.sh:471-473`, `:40-41` | High |
| 5 | r3 #11 unfixed and multiplied: five `-C` probes, none suppressing iptables' own stderr | Minor | `init-firewall.sh:1039-1054` | Medium |
| 6 | "Every rule the boundary depends on" covers 5 rules; the allowlist ACCEPT and the default REJECT are not asserted (r3 #8's shape, new site) | Minor | `init-firewall.sh:1036-1054` | High |
| 7 | The `-C` loop emits the `Firewall verification failed` stem above the `Verifying firewall rules...` banner | Minor | `init-firewall.sh:1036-1057` | High |
| 8 | `--bless` is the human gate and now prints 120 unlabelled hash lines (was 16), with no summary | Minor | `cc-isolated.sh:91-96` | High (measured) |
| 9 | Three sorted manifest lists, two collations (`LC_ALL=C sort` vs bare `sort`) | Informational | `cc-isolated.sh:69-71` | High |
| 10 | `base.txt` grammar sentence landed but left a 122-col line; the guide half of r3 #3 is still open; two other comment reflows owed | Informational | `egress/base.txt:15-16`; `guides/cc-isolated-usage.md` | High |
| 11 | Lock widening + 120→600 moved the launcher's silent worst case to ~10 min with no progress line | Informational | `init-firewall.sh:344-368`; `cc-isolated.sh:432` | Medium |

Carried forward unchanged from r3 (rubric C16, not re-listed above): #1 `HOST_LABEL`/`HOST_RE` prefix collision, #2 the "one grammar" claim's scope, #5 the `log()` `CONTRACT:` placement, #7 `--print-dnsmasq-conf` strictness divergence, #9 the IPv6 `WARNING:` prefix, #10 `IP6_FILTER`'s name.

---

### Overall Assessment

This was intended as a confirming clean pass and it is not one. The three fixes it set out to make all landed and landed well — the ownership assertion is now keyed on the invariant and has a real test, the lock wait aborts instead of self-repairing, and the "all the way up" comment was rescoped rather than hand-waved — but the range also introduced one functional regression in a consumer contract (finding 1: `claude-home/` goes unhashed whenever `projects/` is empty, which is every fresh install, silently, and the suite cannot see it because bats `run` disables errexit). That is not a consistency nit; it is the manifest failing to cover the artefact this range added it to cover, in the state the code's own comment calls "normal". It is a five-character fix (`|| continue`) plus one test that goes through the real entrypoint.

The rest is the familiar late-loop profile: two Inconsistent findings about the *shape* a correct fix took (a new seam class arriving through an `if` rather than a declaration; a security gate keyed on a literal duplicated across two lines), and a tail of Minor/Informational items about comment scope, message placement, and a human-facing printout that grew 7× without its renderer changing. Notably, two of the Minors are the immediately preceding pass's findings recurring: r3 #11 was not fixed and the fix that touched its site replicated it five times, and r3 #8's "stated invariant broader than the assertion" shape reappeared two hundred lines from where it was just closed. That pattern — a class of finding closed at one site and re-committed at another in the same range — is the signal that the loop is fixing instances rather than the class, and it is worth one deliberate sweep (a grep for universals in comments over enumerated lists; a grep for unsuppressed probe invocations) rather than a fifth pass of instance-by-instance review.

Consumer impact: finding 1 affects every fresh `install.sh` → `--bless` → build sequence and should block the pass. Findings 2–4 affect the next person to add a test seam or move the egress directory. Findings 5–11 are legibility and operator-experience, fixable in place, none of them blocking.

---

### Goal-Alignment Note

The stated goal was a confirming clean pass on a local-only solo repo. I read that as: verify the pass-3 fixes actually closed what they claimed, and stop — not hunt for a fifth round of nits. So the deferred r3 findings are statused in one table and not re-argued, and the eleven items here are ordered so the one that matters can be acted on alone.

The honest answer is that the pass is not clean, for one reason: finding 1 is a functional gap, not a consistency observation, and it was found only by running `--bless` through the real entrypoint in both `projects/` states rather than by reading the diff or trusting the (passing) suite. Everything else in this report could reasonably be deferred to a batch cleanup — including the two recurrences of prior findings, which I flagged as a *class* signal precisely so the loop can close them in one sweep instead of a sixth pass. If the goal is to stop looping, the shortest honest path is: fix finding 1 with its test, take the one-line edits in findings 3 and 4 (they are cheap and they protect a Critical-grade assertion), and carry the remaining eight plus the six deferred r3 items into `docs/working/questions.md` as a single documented-debt entry rather than running pass 5. I did not modify any file, and nothing here is committed.
