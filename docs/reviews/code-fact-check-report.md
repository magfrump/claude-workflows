# Code Fact-Check Report

**Commit:** 563448a
**Replication:** k=1 (loop pass, decision 031)
**Repository:** claude-workflows (/workspace)
**Scope:** Range `1434fc9..563448a` (HEAD = 563448a, one commit), restricted to `devcontainer-config/` — `init-firewall.sh`, `cc-isolated.sh`, `Dockerfile`, `cc-sni-proxy.py`, `egress/base.txt` — plus the commit message of `563448a` and the "Pass 3" rows (A26–A31, C19, C20) added to `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md`. `test/*.bats`, `docs/working/questions.md` and the four `*-review-2026-09-03-egress-hardening-r3.md` critic reports in the same range are sibling context, consulted as evidence but not themselves under review.
**Checked:** 2026-09-03
**Total claims checked:** 21
**Summary:** 16 Verified, 5 Mostly accurate, 0 Incorrect (behavioral or comment-only), 0 Stale, 0 Unverifiable. The three executable guarantees in the commit body (417/417 bats, 13/13 python, shellcheck clean) all reproduce exactly. The four mechanisms this round is built on — `flock -u` releasing while the fd stays open, `IFS=' ' read -r -a` splitting under the script's `IFS=$'\n\t'`, the sudoers `""` no-arguments grant, and the proxy's `select` readiness timeout — were each **executed**, not reasoned about, and each behaves as the commit says. The five Mostly-accurate findings are all descriptive imprecision in comments and commit prose whose load-bearing conclusion still holds; the most substantive is that the lock-wait sizing parenthetical undercounts its own daemon-start term by ~29 s (the same commit added a 30 s proxy readiness bound), though 300 s still clears the measured worst case of 209 s with 30% margin.

The prior pass's only defect (Claim 18, `Dockerfile:109-110`) was fixed in `1434fc9` itself and reads correctly at HEAD; the rubric's "1 Stale comment fixed" is accurate.

No claim in this pass matched a pattern in `docs/reviews/hallucination-patterns.md`; no new entry is appended (nothing in this range fabricates a symbol, API, or measured value).

---

## Claim 1: "the lock covers BOTH phases: a second invocation waits for the first to finish entirely, then does its own reads against the finished ruleset"
**Location:** `devcontainer-config/init-firewall.sh:339-367`, commit `563448a` body **Type:** ordering / behavior **Verdict:** Verified **Confidence:** High **Verification mode:** executed (suite) + static **Scope:** Covers statement ordering in the file and the bats fixture that pins it; does not establish real-kernel concurrency behaviour. **Legibility-target:** reviewer auditing the concurrency fix

The `flock -w "$FIREWALL_LOCK_WAIT" 9` block now sits at `:355-367`, *before* the `PHASE A` banner at `:369`, and the old phase-B lock site (previously between the banner at `:553` and `iptables-save -t nat`) is gone — the diff removes it verbatim. Everything the phase-A comment enumerates therefore runs inside the lock: the `curl` of `api.github.com/meta` (`:396`), the CIDR loop, the per-domain `dig` loop (`:434`), and the dnsmasq/SNI/IPv6 preconditions.

Three things run *before* the lock and are correctly excluded from the claim: the two traps (`:299-300`), the ownership assertion (`:311-319`), and `compose_domains`/`parse_entry` (`:321-337`) — all local, none a network read. The `--print-*` hooks exit at `:76`, `:108`, `:156`, `:232`, i.e. before the traps, so an inspection hook never touches the lock.

The rewritten bats case "the lock covers both phases: a held lock stops the run before any network read" asserts `grep -cE -- "^(curl|dig|iptables -F)" "$CMD_LOG"` is 0 and that the run still fails closed (`iptables -w 5 -P OUTPUT DROP` present) — the exact inversion of the pass-2 test it replaces.

**Evidence:** `init-firewall.sh:299-367`, `:369`, `:553-556`; `test/init-firewall-rules.bats:942-954`; suite run `docs/reviews/execution-logs/cfc-lp3-bats-563448a.txt` (417 ok, 0 not ok).

---

## Claim 2: "The wait is sized to the longest legitimate hold (a 15 s meta fetch, up to 6 s per allowlisted name, ~10 s of daemon starts) with margin"
**Location:** `devcontainer-config/init-firewall.sh:348-350`, commit body ("default wait 300 s sized to the longest hold") **Type:** quantitative rationale **Verdict:** Mostly accurate **Confidence:** High **Verification mode:** executed **Scope:** Covers the three named terms against the shipped profiles and the bounded waits readable in source; does not establish real resolver latency (a resolv.conf with multiple nameservers can exceed `+time=3 +tries=2` per name). **Legibility-target:** reviewer sizing the lock timeout

The two large terms are right. `--max-time 15` on the meta fetch is exact (`:396`). `dig +time=3 +tries=2` (`:434`) is 6 s per name, and the largest shipped allowlist — `base` plus all seven profiles — is **N = 25** names, executed via `--print-entries`, so the dig term is 150 s.

The third term is the imprecise one. "~10 s of daemon starts" matches the two `for _ in $(seq 1 30); … sleep 0.1` loops (3 s each at `:495` and `:796`) plus the proxy's own `stop_prior` loop (3 s, `cc-sni-proxy.py:232`), but it omits the **30 s `READY_TIMEOUT` this same commit introduced** at `cc-sni-proxy.py:49`, which the parent blocks on at `:260` while the caller holds the lock. The real daemon-start term is 39 s, not ~10 s.

| term | source | worst case |
|---|---|---|
| meta fetch | `init-firewall.sh:396` | 15.0 s |
| 25 digs × 6 s | `:434`, `--print-entries` | 150.0 s |
| `ip6tables -w 5` preconditions | `:543` | 5.0 s |
| `stop_dnsmasq` wait | `:495` | 3.0 s |
| dnsmasq pidfile wait | `:796` | 3.0 s |
| proxy `stop_prior` | `cc-sni-proxy.py:232` | 3.0 s |
| proxy `READY_TIMEOUT` | `cc-sni-proxy.py:49`, `:260` | 30.0 s |
| **total** | | **209.0 s** |

**The conclusion survives:** 300 s ≥ 209 s, margin 91 s (30%). The itemisation is what is wrong, not the number. Two consequences worth naming: the margin is 30%, not the order-of-magnitude the prose suggests, and the default is exhausted at **N ≈ 40 names** — 15 more than today's largest profile set. **Consequence: comment-only**, no behavioral effect.

**Evidence:** `docs/reviews/execution-logs/cfc-lp3-lock-wait-arithmetic-563448a.txt` — `--print-entries` with all seven profiles (rc 0, 25 lines) plus a `python3` term-by-term sum, cwd `/workspace`, `LC_ALL=C`, 2026-09-03T18:53-07:00.

---

## Claim 3: "the verification probes at the end run after the lock is released, so they never extend it" / `flock -u 9`
**Location:** `devcontainer-config/init-firewall.sh:348-350`, `:1036-1038` **Type:** behavior (lock semantics) **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers `flock -u`'s effect on an fd the shell holds and the source ordering; does not establish a concurrent-run race in a live container. **Legibility-target:** reviewer

Three sub-questions, all executed rather than assumed:

1. **Does `flock -u N` release while keeping the fd?** Yes. With `exec 9>"$L"` and `flock -w 5 9` held, an outsider `flock -n "$L" true` returns 1; after `flock -u 9` (rc 0) the same outsider returns 0, and fd 9 is still present in `/proc/$$/fd` and still writable. (util-linux 2.38.1, bash 5.2.15.)
2. **Is fd 9 still open at `:1038`?** Yes. `9>&-` at `:795` and `:1004` is a *per-command* redirection: a child run with `9>&-` does not see fd 9, and the parent still has it immediately afterwards — executed.
3. **Ordering.** `flock -u 9` is line 1038; the first probe `curl … https://example.com` is line 1061. The four probe curls are at `:1061`, `:1069`, `:1078`, `:1094`.

The new bats case pins (3) in source rather than at runtime ("No observable command for `flock -u`"), which is an honest limitation the test states itself.

**Evidence:** `docs/reviews/execution-logs/cfc-lp3-flock-semantics-563448a.txt` (exit 0, A1–A6/B1–B2 all as predicted), cwd `/workspace`, `LC_ALL=C`, 2026-09-03T18:52-07:00. Code: `init-firewall.sh:362`, `:795`, `:1004`, `:1038`, `:1061-1094`; `test/init-firewall-rules.bats:961-969`.

---

## Claim 4: "release the lock so a waiting run proceeds while the probes below (up to four 15 s curls) run against the finished boundary"
**Location:** `devcontainer-config/init-firewall.sh:1036-1037` **Type:** behavior rationale **Verdict:** Mostly accurate **Confidence:** Medium-High **Verification mode:** static **Scope:** Covers the curl count and this run's own ruleset state at the unlock point; does **not** establish that the boundary stays finished for the duration of the probes. **Legibility-target:** reviewer weighing the new unlock point

"Up to four 15 s curls" is exact (`:1061`, `:1069`, `:1078`, `:1094`, each `--connect-timeout 5 --max-time 15`), and at line 1038 this run's ruleset is complete (`:1034` is the terminal `-j REJECT`).

The gap is in "against the finished boundary". Releasing at `:1038` lets a waiting run enter *its* phase A immediately; on a warm cache that run reaches phase B's flush in well under the up-to-60 s the probes can occupy, at which point this run's probes see the other run's blackout and abort into `fail_closed_on_abort`. That is precisely the failure mode A26 was filed for (a run losing its reads to another's rebuild), relocated from phase A to the probe tail rather than eliminated. It is a narrower window than the one A26 closed (probes are ≤60 s; phase A could be 209 s) and the outcome is fail-closed rather than a silent gap, so this is a residual, not a regression — but the comment reads as if the boundary is stable for the probe window, and it is not.

The five `-C` assertions at `:1040-1056` are inside the same post-unlock window and inherit the same exposure.

**Evidence:** `init-firewall.sh:1034-1056`, `:1061-1097`, `:299` (EXIT trap), `:339-347` (the A26 rationale the comment restates). See Escalation 1.

---

## Claim 5: "non-numeric wait aborts" (commit body) / `CC_FIREWALL_LOCK_WAIT must be a non-negative integer`
**Location:** `devcontainer-config/init-firewall.sh:356-360` **Type:** behavior **Verdict:** Verified **Confidence:** High **Verification mode:** executed (suite) **Scope:** Covers the predicate and its abort path. **Legibility-target:** reviewer

`[[ ! "$FIREWALL_LOCK_WAIT" =~ ^[0-9]+$ ]]` now `exit 1`s with the offending value quoted, replacing pass-2's silent `|| FIREWALL_LOCK_WAIT=120` repair. The bats case "a non-numeric lock wait aborts instead of being silently repaired" runs `CC_FIREWALL_LOCK_WAIT=soon` and asserts non-zero status plus the message. The empty case is still caught twice (`:-300` substitutes for empty as well as unset; `^[0-9]+$` rejects the empty string). `0` still passes validation and means non-blocking — unchanged from pass 2 and still unstated.

**Evidence:** `init-firewall.sh:355-360`; `test/init-firewall-rules.bats:955-959`; suite run `docs/reviews/execution-logs/cfc-lp3-bats-563448a.txt`.

---

## Claim 6: "`enforcement_files()` hashes a sorted walk of `claude-home/`"
**Location:** `devcontainer-config/cc-isolated.sh:70`, commit body, rubric A27 **Type:** behavior **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers the walk, its ordering, its dotfile coverage, and the bless/check round-trip against a scratch config dir; does not establish behaviour on a filesystem whose paths contain newlines. **Legibility-target:** reviewer auditing manifest coverage

`[ -d claude-home ] && find claude-home -type f | LC_ALL=C sort` runs inside the existing `( cd "$cfg" … )` subshell, so paths are emitted relative to the config dir like every other entry, and it is appended after the `egress/*.txt` and `projects/*.profile` globs — a fixed, order-stable position. `&&` binds looser than `|`, so the pipeline is correctly guarded as a unit. `find` emits dotfiles, so `claude-home/.manifest` (written by `install.sh:59`) is hashed; executed against a scratch dir it appears in the output.

Executed round-trip: with `claude-home/hooks/h.sh` present, `compute_manifest` includes it, `bless_manifest` then `check_manifest` agree, and the shipped bats case "claude-home files are hashed file by file when present" additionally proves that editing the file afterwards makes `check_manifest` non-zero.

**One exit-status wrinkle, currently harmless.** When `claude-home/` is absent the `[ -d … ]` test is the subshell's last command, so the subshell — and therefore `enforcement_files` — returns **1**. Both call sites tolerate it: `compute_manifest` reads via `< <(enforcement_files)`, which discards the status (executed: `compute_manifest` rc 0, 7 lines), and the bats registry test uses `run`. A future *bare* call under `set -e` would abort — executed and confirmed (rc 1, next line not reached).

**Evidence:** `docs/reviews/execution-logs/cfc-lp3-manifest-walk-563448a.txt` — D1–D5, E1–E3, cwd `/workspace`, `LC_ALL=C`, 2026-09-03T18:52-07:00. Code: `cc-isolated.sh:54-71`; `test/cc-isolated-functions.bats:519-529`. See Escalation 2.

---

## Claim 7: "One sha256sum for the whole list (the claude-home walk is ~100 files; a fork per file made every launch pay for it)"
**Location:** `devcontainer-config/cc-isolated.sh:88-91` **Type:** behavior / measurement **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers the batching change and the file count; does not establish the launch-time saving (not measured here or in the commit). **Legibility-target:** reviewer

`compute_manifest` now accumulates into `local -a files=()` and ends with a single `(cd "$cfg" && sha256sum "${files[@]}")`, replacing the per-file `(cd "$cfg" && sha256sum "$f")` inside the loop. `rg --files --hidden --no-ignore devcontainer-config/claude-home | wc -l` → **104**, so "~100 files" is accurate (the r3 architecture review's "104" is the same count).

The `set -u` edge the batching introduces is not reachable: `enforcement_files` unconditionally emits six fixed names, and `compute_manifest` `return 1`s if any is missing, so `files[]` cannot be empty at the `sha256sum` call. Executed for completeness: on bash 5.2.15 `sha256sum "${files[@]}"` with an empty array is **not** an unbound-variable error — it degrades to reading stdin (hashing empty input as `-`), which would be a silently wrong manifest rather than a failure. Unreachable today; see Escalation 3.

**Evidence:** `docs/reviews/execution-logs/cfc-lp3-manifest-walk-563448a.txt` (F1, F2); `cc-isolated.sh:73-92`; file count as above.

---

## Claim 8: "claude-home/ — the baked skills/hooks payload, executable at 0555 inside the image"
**Location:** `devcontainer-config/cc-isolated.sh:48-49` **Type:** ownership/permissions description **Verdict:** Mostly accurate **Confidence:** High **Verification mode:** static **Scope:** Covers the Dockerfile source text; no Docker daemon here, so not the built image. **Legibility-target:** future editor of the manifest list

`Dockerfile:420-423` chowns `/opt/claude-workflows` to root and then applies **three** modes, not one: directories 0555, *all* regular files 0444, and only then `\( -name '*.sh' -o -name '*.py' \)` back up to 0555. So the payload is not "executable at 0555" as a whole — the executable subset is the `.sh`/`.py` files, which is what makes the hashing worth doing and is how the r3 architecture review phrased it ("`*.sh`/`*.py` at 0555"). The comment's conclusion (this tree runs in every session and belongs in the manifest) is unaffected. **Consequence: comment-only.**

**Evidence:** `devcontainer-config/Dockerfile:403`, `:420-423`; `docs/reviews/architecture-review-2026-09-03-egress-hardening-r3.md:29`.

---

## Claim 9: "a bats test now pins PAYLOAD ⊆ this list" and "the registry test names its exclusions and checks Dockerfile COPY sources ⊆ PAYLOAD"
**Location:** `devcontainer-config/cc-isolated.sh:47-48`, commit body, rubric A27 **Type:** test-coverage claim **Verdict:** Verified **Confidence:** High **Verification mode:** executed (suite) **Scope:** Covers both directions as the test implements them; does not establish robustness against `COPY` forms the Dockerfile does not currently use. **Legibility-target:** reviewer weighing what the registry test proves

Both directions are present and passing. The forward direction replaces the pass-3 complaint — the old `[ -d "$CONFIG_SRC/$item" ] && continue` (which silently excluded whatever happened to exist as a directory on the runner) is now an explicit `case "$item" in egress|claude-home) continue ;;` naming its two exclusions, plus a `[[ "$payload_line" == *")" ]]` guard against a multi-line `PAYLOAD=(`. The reverse direction greps `^COPY ` out of the Dockerfile and requires each source in `PAYLOAD`.

Scope note on the reverse direction: `awk '{print $2}'` takes the second field, so a `COPY --chown=…` or `COPY --from=…` form would yield the flag rather than the source and the membership test would fail confusingly. All five current `COPY` lines (`Dockerfile:389, 390, 393, 394, 403`) are flag-free, so the test is correct today.

**Evidence:** `test/cc-isolated-functions.bats:496-517`; `devcontainer-config/install.sh:25`; `Dockerfile:389-403`; suite run `docs/reviews/execution-logs/cfc-lp3-bats-563448a.txt`.

---

## Claim 10: "The assertion keys on the INVARIANT — the directory is the image's baked one — not on whether a test override is present" / "`/usr/local` and `/usr` are root by construction of the base image and are not re-checked"
**Location:** `devcontainer-config/init-firewall.sh:302-319` **Type:** security rationale **Verdict:** Mostly accurate **Confidence:** Medium-High **Verification mode:** static **Scope:** Covers the gate's predicate and what it does and does not cover; does not establish the base image's actual ownership of `/usr/local` (no Docker daemon). **Legibility-target:** reviewer auditing the assertion's bypass surface

The change is real and is an improvement: pass 2's `if [ -z "${CC_EGRESS_DIR:-}" ]` meant *setting* `CC_EGRESS_DIR` — even to the baked path — disabled the check; now `[ "$EGRESS_DIR" = "/usr/local/share/cc-egress" ] || [ -n "${CC_EGRESS_OWNER_CHECK:-}" ]` asserts whenever the effective directory *is* the baked one, however it got there.

Two boundaries the "keys on the INVARIANT" phrasing over-promises:

- It is a **literal string comparison**, not a realpath comparison. `CC_EGRESS_DIR=/usr/local/share/cc-egress/` (trailing slash) or a symlink resolving to the same directory skips the assertion, exactly as any other relocation does.
- Relocation still disables the check entirely. The residual protection is unchanged from pass 2 and unchanged in kind: `node` cannot set `CC_EGRESS_DIR` through the one sudo grant. Claim 15 below now makes that argument stronger than it was — `env_reset`/`!setenv` are stated in the sudoers file rather than inherited — which is the substantive half of A28.

The parenthetical about `/usr/local` and `/usr` describes the loop honestly: `for d in "$EGRESS_DIR" "$(dirname "$EGRESS_DIR")"` covers exactly two levels, so `/usr/local` is checked (it *is* the dirname) and `/usr` is not. Reading it as "`/usr/local` … not re-checked" would be wrong; reading it as "we stop climbing at `/usr`" is right. Mildly ambiguous, no behavioral consequence.

**Evidence:** `init-firewall.sh:302-319`; `Dockerfile:429`; Claim 15.

---

## Claim 11: "R7 gains a regression test" / "`CC_EGRESS_OWNER_CHECK=1` lets the unit tests exercise it against a relocated directory"
**Location:** `devcontainer-config/init-firewall.sh:309-311`, rubric A28 **Type:** test-coverage claim **Verdict:** Verified **Confidence:** High **Verification mode:** executed (suite) **Scope:** Covers that the opt-in path is exercised and aborts pre-flush; does not establish the *default* path against a real image. **Legibility-target:** reviewer

The new case "a node-owned or world-writable profile directory aborts before the flush (R7)" sets `CC_EGRESS_OWNER_CHECK=1` against the suite's relocated `CC_EGRESS_DIR` (owned by the test user, not root), asserts non-zero status and the `must be root-owned` message, and — the part that makes it a boundary test rather than a string test — asserts `grep -cE -- "^(curl|dig|iptables -F)"` is 0 while `iptables -w 5 -P OUTPUT DROP` is present, i.e. it aborted before any network read or flush *and* went out through the fail-closed trap. The flag is load-bearing: every other test in the file runs the same relocated directory without it and completes normally.

**Evidence:** `test/init-firewall-rules.bats:980-989`; `init-firewall.sh:311-319`, `:299`; suite run `docs/reviews/execution-logs/cfc-lp3-bats-563448a.txt`.

---

## Claim 12: "Five boundary rules asserted with `-C` before completion (array-split; the string form did not split under IFS — caught by the negative test)"
**Location:** `devcontainer-config/init-firewall.sh:1040-1056`, commit body, rubric A29 **Type:** behavior **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers the splitting mechanics, IFS restoration, and the three rules a negative fixture exercises; does **not** establish that the two filter-table assertions abort when their rule is absent (see Claim 13 and Escalation 4). **Legibility-target:** reviewer

`IFS=' ' read -r -a rule_args <<< "$rule"` was executed under the script's exact conditions (`set -euo pipefail`, global `IFS=$'\n\t'`):

| observation | result |
|---|---|
| `read` exit status | 0 — the here-string supplies the terminating newline, so `set -e` is not tripped |
| element count | 10 — `[-t][nat][-C][OUTPUT][-p][tcp][--dport][443][-j][CC_SNI]` |
| `IFS` after the command | still `\n \t` — the prefix assignment is scoped to the builtin and restored |
| same `read` **without** the `IFS=' '` prefix | 1 element — reproduces the bug the commit says the negative test caught |
| tabs inside any of the five rule literals | none (`cat -A` over `:1043-1048`) |

The `for rule in \ "…" \ "…"` list itself needs no splitting: the items are quoted words, and `for` does not word-split them.

**Evidence:** `docs/reviews/execution-logs/cfc-lp3-ifs-array-split-563448a.txt` (C0–C6, exit 0), cwd `/workspace`, `LC_ALL=C`, 2026-09-03T18:52-07:00. Code: `init-firewall.sh:1043-1056`.

---

## Claim 13: "`-C` queries what `-A` installed; drift between the two literals is self-detecting (the run aborts into DROP)"
**Location:** `devcontainer-config/init-firewall.sh:1041-1042` **Type:** behavior rationale **Verdict:** Mostly accurate **Confidence:** High **Verification mode:** static (+ suite evidence) **Scope:** Covers the five literals against their install sites; does not establish real netfilter `-C` semantics (no privileged container). **Legibility-target:** reviewer

Each of the five `-C` predicates matches an install site character-for-character on the rule body — but **two of the five are installed with `-I`, not `-A`**:

| asserted | installed at |
|---|---|
| `-t nat -C OUTPUT -p tcp --dport 443 -j CC_SNI` | `:1015` `iptables -t nat -A OUTPUT …` |
| `-t nat -C OUTPUT -p udp --dport 53 -j CC_DNS` | `:814` `iptables -t nat -I OUTPUT 1 …` |
| `-t nat -C OUTPUT -p tcp --dport 53 -j CC_DNS` | `:813` `iptables -t nat -I OUTPUT 1 …` |
| `-C OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD` | `:847` `iptables -A OUTPUT …` |
| `-C OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD` | `:1025` `iptables -A OUTPUT …` |

`-C` matches rule *content*, not position, so `-I`-installed rules are found exactly as `-A`-installed ones are and the self-detection property the sentence asserts holds for all five. Only the word "`-A`" is wrong, for 2/5. **Consequence: comment-only**, no behavioral effect; a reader grepping for `-A` to find the install site of the two DNS redirects would come up empty.

**Evidence:** `init-firewall.sh:813-814`, `:847`, `:1015`, `:1025`, `:1043-1048`.

---

## Claim 14: rubric A29 "✅ Fixed — five `-C` assertions … caught by the negative test"
**Location:** rubric Pass 3, row A29 **Type:** status claim **Verdict:** Mostly accurate **Confidence:** High **Verification mode:** executed (suite) **Scope:** Covers the code change fully and the negative evidence for three of five rules; **does not establish** negative coverage for the two filter-table assertions. **Legibility-target:** reviewer weighing how much the new tests prove

The code change is complete (Claim 12). The negative evidence is partial, and in a way that is an improvement on pass 2 but not a closure of it. The bats `iptables` stub gained `if [ -n "${NO_REDIRECT:-}" ] && [ "${1:-}" = "-t" ] && [ "${3:-}" = "-C" ]; then exit 1; fi` — so `NO_REDIRECT=1` makes the **three `-t nat -C`** assertions report absent, and the rewritten case "a missing tcp/443 redirect rule fails verification even with a logged refusal" proves the loop aborts and fails closed. This closes pass 2's Escalation 2 for the nat family, and it is also what would have caught the un-split string form (the stub's `${1:-}` = `-t` guard only matches when the arguments are split).

The two filter-table assertions (`-C OUTPUT -d 127.0.0.11 -j CC_DNS_GUARD`, `-C OUTPUT -p tcp --dport 443 -j CC_SNI_GUARD`) do not match the stub's `-t`/`-C` shape, so they still always exit 0. The positive test "every boundary rule is asserted present before completion" proves those two commands are *issued*, not that a missing guard aborts.

**Evidence:** `test/init-firewall-rules.bats:51-52` (stub), `:971-978` (positive), `:999-1004` (negative); suite run `docs/reviews/execution-logs/cfc-lp3-bats-563448a.txt`. See Escalation 4.

---

## Claim 15: "Sudoers: `Defaults:node env_reset, !setenv` and a bare-invocation-only grant (the trailing `""` in sudoers means 'no arguments')"
**Location:** `devcontainer-config/Dockerfile:407-411`, `:429`, commit body, rubric A30 **Type:** configuration syntax + semantics **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers syntactic validity under sudo 1.9.13p3 and the documented meaning of `""`; does not establish the built image's effective policy (no Docker daemon) nor the base image's own `/etc/sudoers`. **Legibility-target:** reviewer auditing the sudo grant

Both halves check out, executed rather than asserted:

- **Syntax.** The exact two lines the `printf` at `:429` writes, validated with `visudo -c -f` (sudo 1.9.13p3): `parsed OK`, rc 0. Negative control (`env_reset,, !setenv`) → `syntax error`, rc 1, so the check discriminates. `Defaults:node <list>` is the per-user Defaults form and a comma-separated list is the documented shape.
- **Semantics of `""`.** `sudoers(5)` gives the grammar `command ::= … | command name '""'` and states it twice in prose: "If the command line arguments consist of `""`, the command may only be run with **no** arguments" and, under wildcard exceptions, "the empty string `""` … means that command is not allowed to be run with **any** arguments."

Nothing shipped breaks under the restriction: every invocation of the script in the repo is bare — `devcontainer.json:121` (`postStartCommand`), `cc-isolated.sh:431`, and both troubleshooting recipes in `guides/`. The `--print-*` hooks are invoked only by the bats suite, directly, without sudo. So the Dockerfile comment's "the `--print-*` inspection hooks are not root-runnable" is accurate and costless.

**Evidence:** `docs/reviews/execution-logs/cfc-lp3-sudoers-visudo-563448a.txt` — `visudo -c -f` on a temp file plus `sudoers.5` extracts, cwd `/workspace`, `LC_ALL=C`, 2026-09-03T18:53-07:00. Code: `Dockerfile:407-411`, `:429`; call sites as listed.

---

## Claim 16: "Proxy readiness wait bounded at 30 s" / "a child that hangs before signalling must not park it forever"
**Location:** `devcontainer-config/cc-sni-proxy.py:33`, `:49`, `:255-264`, rubric A31 **Type:** behavior **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers the timeout path end to end in this sandbox (fire, kill, reap, non-zero return, no pidfile); does not establish behaviour under a real `--user` drop as `ccproxy`. **Legibility-target:** reviewer

`import select` is added at `:36` and `READY_TIMEOUT = 30.0` at `:49`. The parent's `select.select([r], [], [], READY_TIMEOUT)` takes the pipe read fd — a plain int from `os.pipe()`, which `select` accepts — and on timeout does `os.kill(pid, SIGKILL)` then `os.waitpid(pid, 0)` before returning 1.

Exercised directly with a scratch harness: the module is loaded by path, `READY_TIMEOUT` patched to 2.0 s, and `serve` replaced by a coroutine that sleeps forever so the child never writes `b"ready"`.

| observation | result |
|---|---|
| `daemonize()` return | 1 (the `set -e` abort contract `init-firewall.sh:1004` relies on) |
| elapsed | 2.01 s — the timeout fired, it did not block |
| stderr | `cc-sni-proxy: failed to start: no readiness signal within 2s` |
| pidfile | not written |
| `os.waitpid(-1, WNOHANG)` afterwards | `ChildProcessError` → no zombie |

The comment "the caller holds the firewall lock while we start" is correct at HEAD: the proxy launch is `:1004`, the `flock -u 9` is `:1038`. The 30 s bound is what makes Claim 2's arithmetic hold rather than being unbounded.

**Evidence:** `docs/reviews/execution-logs/cfc-lp3-proxy-ready-timeout-563448a.txt` (exit 0), cwd `/workspace`, `LC_ALL=C`, 2026-09-03T18:53-07:00. Code: `cc-sni-proxy.py:36`, `:49`, `:255-264`; `init-firewall.sh:1000-1007`.

---

## Claim 17: "`base.txt` documents the two-label rule"
**Location:** `devcontainer-config/egress/base.txt:15-16`, commit body, rubric C19 **Type:** documentation accuracy **Verdict:** Verified **Confidence:** High **Verification mode:** static (regex re-verified executed in pass 2) **Scope:** Covers agreement between the header sentence and `HOST_RE`; does not re-establish the regex itself (unchanged in this range). **Legibility-target:** profile author

"A domain needs two or more labels (a bare label such as `com` would become a whole-TLD resolver zone and is rejected)" matches `HOST_RE="^${HOST_LABEL}(\.${HOST_LABEL})+\$"` (`:124-130`, byte-identical to `1434fc9`), whose `+` requires at least one dot-joined extra label, and it names the actual reason the rule exists (`compose_dnsmasq_conf`'s `server=/<name>/` zone). "Rejected" is precise for `parse_entry` (hard error) and slightly strong for `compose_dnsmasq_conf` (warn-and-omit) — the pre-existing asymmetry already tracked as rubric C16.

Two cosmetic notes: the insertion makes `:16` a 137-column line in a file otherwise wrapped near 88, and it lands in the same paragraph as the pre-existing "#-comments ignored" sentence that rubric A10 records as not true of `parse_entry`. Neither is introduced by this claim.

**Evidence:** `egress/base.txt:13-21`; `init-firewall.sh:124-130`, `:220-224`; `git diff 1434fc9 563448a -- devcontainer-config/init-firewall.sh` shows no change to `HOST_RE`.

---

## Claim 18: "`9>&-`: … Both daemon starts close it; the proxy also closes inherited fds itself, dnsmasq is not assumed to."
**Location:** `devcontainer-config/init-firewall.sh:791-794` **Type:** behavior **Verdict:** Verified **Confidence:** High **Verification mode:** executed (fd scope) + static **Scope:** Covers the count and placement of the redirections and the child's own fd sweep. **Legibility-target:** reviewer

There are exactly two long-lived daemon starts in the script and both carry `9>&-`: `dnsmasq … 9>&-` at `:795` and `"$SNI_PROXY_BIN" --daemon … 9>&-` at `:1004`. The pass-2 wording named only the dnsmasq one; the correction is accurate. The proxy's own sweep is real (`cc-sni-proxy.py:283-289` closes every fd > 2 except the readiness write end), so `9>&-` is belt-and-braces there and load-bearing for dnsmasq. Executed confirmation that `9>&-` is per-command and leaves the parent's fd 9 intact is in Claim 3.

**Evidence:** `init-firewall.sh:791-795`, `:1000-1005`; `cc-sni-proxy.py:274-289`; `docs/reviews/execution-logs/cfc-lp3-flock-semantics-563448a.txt` (B1, B2).

---

## Claim 19: rubric Pass-3 rows A26, A27, A28, A30, A31 — "✅ Fixed"
**Location:** `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md` (Pass 3 table) **Type:** status claims **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers each row's stated remedy against the code and the passing test that pins it; does not establish the original findings' severity ratings. **Legibility-target:** reviewer

| row | stated remedy | check |
|---|---|---|
| A26 | lock covers both phases; wait 300 s; released before probes; non-numeric aborts | Claims 1, 2, 3, 5 — all present; the wait's *itemisation* is imprecise (Claim 2), the number is right |
| A27 | `enforcement_files()` walks `claude-home/`; `compute_manifest` batches; test names exclusions and checks COPY ⊆ PAYLOAD; new test proves an edit trips the manifest | Claims 6, 7, 9 — all four sub-claims present and passing |
| A28 | assertion keys on the baked path with a `CC_EGRESS_OWNER_CHECK` opt-in; R7 regression test | Claims 10, 11 — present; "keys on the invariant" over-promises slightly (literal string compare) |
| A30 | `Defaults:node env_reset, !setenv` + bare-invocation-only grant | Claim 15 — `visudo`-validated, `sudoers(5)`-confirmed, no shipped caller broken |
| A31 | 30 s `select` timeout, child killed | Claim 16 — executed end to end |

A29 is handled separately as Claim 14 (Mostly accurate: complete fix, partial negative evidence). C19's "Grammar rule now documented in `base.txt`; `9>&-` comment fixed; the rest logged" matches Claims 17 and 18. C20's "🟢 Open — accepted; noted in questions.md" is consistent with the code (no `-w` added to the phase-B `ip6tables` calls in this range) — though the two rows C20 points at in `questions.md` are the IPv6 and `/usr/local/share` rows from the previous round, not new ones.

The Pass-3 preamble's own numbers also check out: the prior fact-check was "18 claims, 0 Incorrect, 1 Stale comment", and that Stale item (`Dockerfile:109-110`) reads correctly at HEAD — it was fixed inside `1434fc9` itself, so "fixed" is right.

**Evidence:** rubric Pass-3 table; Claims 1–18 above; `git show 1434fc9:devcontainer-config/Dockerfile` lines 109-110; suite run `docs/reviews/execution-logs/cfc-lp3-bats-563448a.txt`.

---

## Claim 20: rubric header — "0 red open (pass-1 reds, the pass-2 Critical and the pass-3 Structural all fixed …), 8 amber item(s) awaiting resolution or justification"
**Location:** rubric line 5 **Type:** status arithmetic **Verdict:** Verified **Confidence:** Medium-High **Verification mode:** executed (grep census) **Scope:** Covers the counts against the rubric's own status cells; does not establish that the classifications are right. **Legibility-target:** loop operator deciding whether this is a clean pass

Status census across the whole rubric: 27 `✅ Fixed`, 11 `✅ Confirmed`, 1 `✅ Addressed`, 10 `🟡 Open`, 17 `🟢 Open`, 1 `🟢 noted`, 2 `🟢 partly`. No `🔴` row is open — every `🔴` carries a `✅`.

The "8 amber" figure resolves exactly: of the ten `🟡 Open` rows, **A23** is the Structural finding that Pass 3's A27 marks fixed (its own row was not restyled), and **A25** is annotated `🟡 Open (accepted)` with an author note, leaving **A3–A10 — precisely eight** rows genuinely awaiting resolution or justification. That is also the exact delta from the pass-2 header's "9" (which included A23). The count is right; the bookkeeping is fragile, because it depends on a reader knowing that A23's row is stale.

**Evidence:** grep census over `docs/reviews/code-review-rubric-2026-09-03-main-egress-hardening.md`; rows A3–A10 (`:36-43`), A23 (`:152`), A25 (`:154`), A27 (Pass 3 table).

---

## Claim 21: "417/417 bats, 13/13 python, shellcheck clean" (commit body)
**Location:** commit `563448a` body, `Notes:` line **Type:** executable guarantee **Verdict:** Verified **Confidence:** High **Verification mode:** executed **Scope:** Covers reproduction at HEAD in this sandbox; does not establish CI parity. **Legibility-target:** reviewer

All three reproduce exactly, at HEAD = 563448a (clean tree), cwd `/workspace`, `LC_ALL=C`, 2026-09-03T18:4x-07:00:

| command | exit | result | log |
|---|---|---|---|
| `bats test/` | 0 | `1..417`, 417 `ok`, 0 `not ok` | `docs/reviews/execution-logs/cfc-lp3-bats-563448a.txt` |
| `python3 test/test_cc_sni_proxy.py` | 0 | `Ran 13 tests … OK` | `docs/reviews/execution-logs/cfc-lp3-python-563448a.txt` |
| `shellcheck -S warning devcontainer-config/{init-firewall.sh,cc-isolated.sh,install.sh}` | 0 | no output | `docs/reviews/execution-logs/cfc-lp3-shellcheck-563448a.txt` |

The commit's `Confidence: medium` and "Two new questions logged" are also accurate: `docs/working/questions.md` gains exactly two rows in this range (claude-home hashing churn; the bare sudo grant), and both name an interim choice.

**Evidence:** the three log files above; `git show 563448a -- docs/working/questions.md`.

---

## Claims Requiring Attention

### Incorrect
None — behavioral or comment-only.

### Stale
None. The one Stale finding from the previous pass (`Dockerfile:109-110`, the "/usr/local/share chowned to node" parenthetical) was fixed in `1434fc9` and reads correctly at HEAD.

### Mostly Accurate
- **Claim 2** — `init-firewall.sh:348-350` and the commit body. The lock-wait sizing parenthetical says "~10 s of daemon starts"; the real term is 39 s, because the same commit added the proxy's 30 s `READY_TIMEOUT`. The 300 s conclusion still holds (worst case 209 s, margin 30%). Comment-only.
- **Claim 4** — `init-firewall.sh:1036-1037`. "Run against the finished boundary" describes the moment of unlocking, not the probe window: a waiting run admitted at `flock -u 9` can begin its own phase-B flush before the four probes and the five `-C` assertions finish. Fail-closed, narrower than the window A26 closed, but a residual the comment does not name. See Escalation 1.
- **Claim 8** — `cc-isolated.sh:48-49`. "executable at 0555" is true of the `*.sh`/`*.py` subset only; the rest of the payload is 0444. Comment-only.
- **Claim 10** — `init-firewall.sh:302-311`. "Keys on the INVARIANT" is a literal string comparison, so any relocation (trailing slash, symlink) still skips the assertion; the residual protection remains sudo `env_reset`, which Claim 15 now makes explicit. Improvement over pass 2, weaker than the phrasing implies.
- **Claim 13** — `init-firewall.sh:1041`. "`-C` queries what `-A` installed" — two of the five rules are installed with `-I OUTPUT 1`. The self-detection property is unaffected. Comment-only.
- **Claim 14** — rubric A29. Fix complete; negative evidence covers the three `-t nat -C` assertions only.

### Unverifiable
Nothing was verdicted Unverifiable, but three scope boundaries limit this pass and should travel with it: (a) **no Docker daemon** (`command -v docker` → not found), so every Dockerfile claim — ownership, modes, and the effective sudoers policy — is verified against source text and `visudo -c -f` on an identical temp file, not against a built image; (b) **no privileged container**, so no netfilter, dnsmasq, or real proxy behaviour is exercised, as `test/init-firewall-rules.bats:17-18` itself states; (c) **no contended-concurrency run** — the lock's behaviour under two live `init-firewall.sh` processes is argued from executed `flock` primitives plus source ordering, not observed.

---

## Escalations

| # | Entry | path:line | Addressee |
|---|---|---|---|
| 1 | The lock is now released *before* the five `-C` assertions and the four probes, so a waiting run's phase-B blackout can make this run's tail fail and abort into DROP — A26's failure mode relocated to the probe window rather than removed. Fail-closed and narrow, but the comment claims the probes run "against the finished boundary". Options: move `flock -u 9` after the probes (costs a waiting run up to 60 s more) or say the residual out loud | `devcontainer-config/init-firewall.sh:1036-1038`, `:1040-1056`, `:1061-1097` | next critic pass (performance / security) |
| 2 | `enforcement_files()` returns 1 when `claude-home/` is absent (the `[ -d … ] &&` short-circuit is the subshell's last command). Harmless today — both callers discard the status — but a future bare call under `set -e` aborts the launcher; executed and confirmed. One-token fix: `|| true` or a trailing `:` | `devcontainer-config/cc-isolated.sh:64-71` | author (defensive one-liner) |
| 3 | `sha256sum "${files[@]}"` on an empty array does not error under `set -u`; it reads stdin and emits the hash of empty input — a silently wrong manifest rather than a failure. Unreachable today (six fixed names, `return 1` on any missing), so this is guard-rail hardening, not a bug | `devcontainer-config/cc-isolated.sh:88-91` | tech-debt-triage (informational) |
| 4 | Negative coverage for the new `-C` loop is partial: the stub's `NO_REDIRECT` knob only fails `-t nat -C` invocations, so the two filter-table assertions (`CC_DNS_GUARD`, `CC_SNI_GUARD`) are proven *issued*, not *enforcing*. Extending the knob to a rule-name match would close pass 2's Escalation 2 completely | `test/init-firewall-rules.bats:51-52`, `:971-978` | test-strategy / next review pass |
| 5 | The registry test's reverse direction parses `COPY` sources with `awk '{print $2}'`, which breaks on `COPY --chown=…` / `COPY --from=…`. All five current `COPY` lines are flag-free, so the test is correct today and would fail loudly (not silently) if one gained a flag | `test/cc-isolated-functions.bats:513-516` | tech-debt-triage (informational) |
| 6 | The 300 s lock wait is exhausted at N ≈ 40 allowlisted names; today's largest shipped set is 25. Not a defect — noted so the "with margin" phrasing is not later read as unlimited headroom, and so a future profile addition is understood to consume it | `devcontainer-config/init-firewall.sh:348-356` | tech-debt-triage (informational) |
| 7 | `claude-home/.manifest` (written by `install.sh:59` with `commit=` and `dirty=`) is now inside the hashed walk, so a re-run of `install.sh` from a dirty tree changes the manifest and requires a re-bless. This is the intended coupling and is already logged as an open question; named here because the `enforcement_files()` comment does not mention it | `devcontainer-config/install.sh:53-59`, `cc-isolated.sh:70`, `docs/working/questions.md:21` | author (already logged) |

---

## Goal-Alignment Note

- **Answered** — all ten "claims to check with care" were checked, and every one whose mechanics were executable was **executed**, not reasoned about: the wait arithmetic against a real `--print-entries` run with all seven profiles (1); `flock -u` release-with-fd-retained and the per-command scope of `9>&-` (1b, 2); `IFS=' ' read -r -a` splitting, IFS restoration, `set -e` interaction, and the absence of tabs (3); `visudo -c -f` on the exact sudoers text plus the `sudoers(5)` grammar and prose for `""` (4); `enforcement_files`'s exit status with and without `claude-home/` and every caller's tolerance of it (5); the empty-array `sha256sum` edge on this bash (6); the `CC_EGRESS_OWNER_CHECK` test path and the literal-compare bypass surface (7); the proxy timeout path driven to completion with a hanging child (8); all three executable guarantees (9); and the `base.txt` / `9>&-` wording (10).
- **Answered** — rubric Pass-3 rows A26, A27, A28, A30, A31 verify against the code and its tests; A29 verifies with a named evidence limitation (Escalation 4) rather than a downgrade, since the code change itself is correct by inspection and now has a genuine negative fixture for three of its five rules. The header's "0 red / 8 amber" arithmetic also resolves exactly.
- **Out of scope** — whether the pass-3 findings were correctly severity-rated, and whether the remaining amber rows (A3–A10) should block a bless. Those are the critics' and the loop's calls.
- **Out of scope** — real-image and real-kernel confirmation, and contended concurrency. Every Dockerfile, netfilter, and two-process claim here is source-level or primitive-level.
- **Escalate** — nothing in this pass is a behavioral defect, and no Incorrect or Stale verdict was reached. Escalation 1 is the only item that touches the design rather than the prose, and it is a residual the previous design also had (pass-2's `-C` ran outside a phase-B-only lock in the same way); whether a Mostly-accurate comment and an unnamed residual reset the two-consecutive-clean counter is the loop's call, not this report's.
